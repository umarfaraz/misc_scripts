#!/bin/bash

# Function to display usage information
usage() {
  echo "Usage: $0 -t <access_token> -p <primary_db_server> -s <secondary_db_server> -r <requestor_email> -a <db_account>"
  echo "Options:"
  echo "  -t   DB Access token to sync the passwords"
  echo "  -p   Primary Database Server Name"
  echo "  -s   Secondary Database Server Name"
  echo "  -r   Requestor Email"
  echo "  -a   Service Account Name"
  echo "  -h   Show this help message"
  exit 1
}

# Parse arguments using getopts
while getopts ":t:p:s:r:a:h" opt; do
  case $opt in
    t) ACCESS_TOKEN="$OPTARG" ;;
    p) PRIMARY_DB_SERVER="$OPTARG" ;;
    s) SECONDARY_DB_SERVER="$OPTARG" ;;
    r) REQUESTOR_EMAIL="$OPTARG" ;;
    a) DB_ACCOUNT="$OPTARG" ;;
    h) usage ;;
    :) echo "Error: Option -$OPTARG requires an argument." >&2; usage ;;
    \?) echo "Error: Invalid option -$OPTARG" >&2; usage ;;
  esac
done

# Check if all required arguments are provided
if [ -z "$ACCESS_TOKEN" ] || [ -z "$PRIMARY_DB_SERVER" ] || [ -z "$SECONDARY_DB_SERVER" ] || [ -z "$REQUESTOR_EMAIL" ] || [ -z "$DB_ACCOUNT" ]; then
  echo "Error: All arguments are required."
  usage
fi

# Log Function
log_message() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Step 1: Retrieve Password from Enterprise Vault
log_message "Retrieving password for account '$DB_ACCOUNT' from Enterprise Vault..."
CURL_COMMAND="curl -s -X POST \"https://vault.example.com/get-password\" \
  -H \"Authorization: Bearer $ACCESS_TOKEN\" \
  -H \"Content-Type: application/json\" \
  -d \"{\"account\": \"$DB_ACCOUNT\"}\" | jq -r '.password'"

log_message "Curl command: ${CURL_COMMAND}"

if [ -z "$PASSWORD" ] || [ "$PASSWORD" == "null" ]; then
  log_message "Error: Failed to retrieve password from Enterprise Vault."
  exit 1
fi
log_message "Password retrieved successfully."

# Variables
bodyString=""
baseUrl="https://cirruspl-datake.com/api/v1/"
accessToken="$accesstoken"

# Convert bodyString to JSON (assuming it's already valid JSON)
bodyJson=$(echo "$bodyString" | jq '.')

# Prepare the POST request URL
uri="${baseUrl}TriggerPipelineWithUserToken"

# Send POST request
buildResponse=$(curl -s -X POST -H "Content-Type: application/json" -H "Authorization: Bearer $accessToken" -d "$bodyJson" "$uri")

# Extract buildId from the response
buildId=$(echo "$buildResponse" | jq -r '.buildId')

# Prepare URLs for status and task log
statusUrl="${baseUrl}GetBuildStatus?buildId=${buildId}"
taskLogUrl="${baseUrl}GetBuildTaskLog?buildId=${buildId}"

done=false

# Loop to check status
while [ "$done" = false ]; do
    # Get build status
    resp=$(curl -s -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $accessToken" "$statusUrl")

    # Get task logs
    jobLogs=$(curl -s -X GET -H "Content-Type: application/json" -H "Authorization: Bearer $accessToken" "$taskLogUrl")

    # Check if jobLogs contains records
    recordId=$(echo "$jobLogs" | jq -r '.record.id')
    if [ -n "$recordId" ]; then
        echo "Outputting progress"
        echo "$resp" | jq '.status'
        echo "$jobLogs" | jq -r '.records[] | select(.type == "job" or .type == "task" and .state != "pending") | "\(.type) \(.name) \(.result) \(.state) \(.starttime) \(.finishtime)"'
    else
        echo "$resp" | jq '.status'
    fi

    # Check if the build is completed, failed, or canceled
    status=$(echo "$resp" | jq -r '.status')
    if [[ "$status" == "completed" || "$status" == "failed" || "$status" == "canceled" ]]; then
        echo "$resp" | jq '.result'
        echo "$jobLogs" | jq -r '.records[] | select(.type == "job" or .type == "task" and .state != "pending") | "\(.type) \(.name) \(.result) \(.state) \(.starttime) \(.finishtime)"'
        done=true
    fi

    # Wait for 30 seconds before the next check
    sleep 30
done

