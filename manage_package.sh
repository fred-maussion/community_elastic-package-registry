#!/bin/bash

# Function to upload package to Kibana using installPackageByUpload API
upload_to_kibana() {
  local package_file="$1"
  local insecure_flag="$2"

  # Read Kibana URL and API Key from environment variables
  local kibana_url="${KIBANA_URL}"
  local kibana_api_key="${KIBANA_API_KEY}"

  if [ -z "$kibana_url" ] || [ -z "$kibana_api_key" ]; then
    echo "Kibana URL and API key are required for uploading the package."
    echo "Ensure the environment variables KIBANA_URL and KIBANA_API_KEY are set."
    exit 5
  fi

  echo "Uploading package '$package_file' to Kibana at $kibana_url$UPLOAD_URL..."

  # Perform the upload and capture the response
  response=$(curl -s $insecure_flag -w "\nHTTP_CODE:%{http_code}" -X POST "$kibana_url$UPLOAD_URL" \
    -H "Content-Type: application/zip" \
    -H "Authorization: ApiKey $kibana_api_key" \
    -H "kbn-xsrf: true" \
    --data-binary @"$package_file")

  # Extract the HTTP status code
  http_code=$(echo "$response" | grep "HTTP_CODE:" | sed 's/HTTP_CODE://')

  # Extract the response body
  response_body=$(echo "$response" | sed '/HTTP_CODE:/d')

  if [ "$http_code" -eq 200 ]; then
    echo "Package uploaded successfully to Kibana."
  else
    echo "Failed to upload package to Kibana. HTTP status code: $http_code"
    echo "Response body: $response_body"
    exit 6
  fi
}

# Check if Kibana version and package name are provided
if [ -z "$1" ] || [ -z "$2" ]; then
  echo "Usage: $0 <kibana_version> <package_name> [--debug] [--insecure]"
  echo "Environment variables KIBANA_URL and KIBANA_API_KEY must be set."
  exit 1
fi

KIBANA_VERSION=$1
PACKAGE_NAME=$2
BASE_URL="https://epr.elastic.co"
SEARCH_URL="$BASE_URL/search?package=$PACKAGE_NAME&kibana.version=$KIBANA_VERSION"
UPLOAD_URL="api/fleet/epm/packages"
DEBUG=false
INSECURE_FLAG=""

# Check for additional flags
for arg in "$@"; do
  case $arg in
    --debug)
      DEBUG=true
      ;;
    --insecure)
      INSECURE_FLAG="--insecure"
      ;;
  esac
done

# Ensure Kibana URL and API key are set in the environment
if [ -z "$KIBANA_URL" ] || [ -z "$KIBANA_API_KEY" ]; then
  echo "KIBANA_URL or KIBANA_API_KEY environment variable is not set. Exiting."
  exit 5
fi

# Fetch data from the Elastic Package Registry
echo "Searching for package '$PACKAGE_NAME' for Kibana version '$KIBANA_VERSION' on Elastic Package Registry..."
RESPONSE=$(curl -s $INSECURE_FLAG "$SEARCH_URL")

# Output debug information if debug flag is set
if $DEBUG; then
  echo "DEBUG: Response from Elastic Package Registry:"
  echo "$RESPONSE"
fi

# Check if response is empty
if [ -z "$RESPONSE" ]; then
  echo "No response from Elastic Package Registry. Exiting."
  exit 2
fi

# Extract the download path from the JSON response
DOWNLOAD_PATH=$(echo "$RESPONSE" | jq -r '.[0].download')

# Check if download path was found
if [ -z "$DOWNLOAD_PATH" ] || [ "$DOWNLOAD_PATH" == "null" ]; then
  echo "No download path found for package '$PACKAGE_NAME'. Exiting."
  exit 3
fi

# Construct the full download URL
DOWNLOAD_URL="$BASE_URL$DOWNLOAD_PATH"

# Download the package
PACKAGE_FILE=$(basename "$DOWNLOAD_PATH")
echo "Downloading package from $DOWNLOAD_URL..."
curl -O $INSECURE_FLAG "$DOWNLOAD_URL"

# Check if download succeeded
if [ $? -eq 0 ]; then
  echo "Package downloaded successfully: $PACKAGE_FILE"
else
  echo "Failed to download package. Exiting."
  exit 4
fi

# Upload to Kibana using environment variables
upload_to_kibana "$PACKAGE_FILE" "$INSECURE_FLAG"
