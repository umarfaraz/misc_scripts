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
exit 0

# Step 2: Update Primary Database Password
log_message "Updating password on primary database..."
PRIMARY_RESPONSE=$(curl -s -X POST "$PRIMARY_DB_API_URL" \
  -H "Authorization: Bearer $BEARER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"account\": \"$DB_ACCOUNT\", \"password\": \"$PASSWORD\"}")

PRIMARY_STATUS=$(echo "$PRIMARY_RESPONSE" | jq -r '.status')
if [ "$PRIMARY_STATUS" != "success" ]; then
  log_message "Error: Failed to update password on primary database. Response: $PRIMARY_RESPONSE"
  exit 1
fi
log_message "Password updated successfully on primary database."

# Step 3: Update Secondary Database Password
log_message "Updating password on secondary database..."
SECONDARY_RESPONSE=$(curl -s -X POST "$SECONDARY_DB_API_URL" \
  -H "Authorization: Bearer $BEARER_TOKEN" \
  -H "Content-Type: application/json" \
  -d "{\"account\": \"$DB_ACCOUNT\", \"password\": \"$PASSWORD\"}")

SECONDARY_STATUS=$(echo "$SECONDARY_RESPONSE" | jq -r '.status')
if [ "$SECONDARY_STATUS" != "success" ]; then
  log_message "Error: Failed to update password on secondary database. Response: $SECONDARY_RESPONSE"
  exit 1
fi
log_message "Password updated successfully on secondary database."

# Step 4: Success Message
log_message "Password sync between primary and secondary databases completed successfully."

