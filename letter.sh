#!/bin/bash

set -e

# accept a single argument, the name of the company
if [ $# -ne 3 ]; then
    echo "Usage: $0 <company-name> <focus> <role>"
    exit 1
fi

COMPANY=$1
FOCUS=$2
ROLE=$3

ENCODED_COMPANY_NAME=$(printf %s "$COMPANY" |jq -sRr @uri)
echo "Encoded company name: $ENCODED_COMPANY_NAME"

# convert company_name to valid file name with json suffix
COMPANY_PREFIX=$(printf %s "$COMPANY" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -d '[:punct:]')
COMPANY_FILE="$COMPANY_PREFIX.json"
echo "Company file: $COMPANY_FILE"

# given the company name, curl the local service to get the address
CA_URL="http://localhost:8000/companies/$ENCODED_COMPANY_NAME/address"
echo "Getting company address from $CA_URL"
COMPANY_RESPONSE=$(curl -s "http://localhost:8000/companies/$ENCODED_COMPANY_NAME/address" | jq -r .)
if [ $? -ne 0 ]; then
    echo "Error: could not get mailing address for $COMPANY"
    exit 1
fi

COMPANY_NAME=$(echo $COMPANY_RESPONSE | jq -r '.company_name')
COMPANY_ADDRESS=$(echo $COMPANY_RESPONSE | jq -r '.mailing_address.street')
COMPANY_CITY=$(echo $COMPANY_RESPONSE | jq -r '.mailing_address.city')
COMPANY_STATE=$(echo $COMPANY_RESPONSE | jq -r '.mailing_address.state_or_province')
COMPANY_ZIP=$(echo $COMPANY_RESPONSE | jq -r '.mailing_address.postal_code')
COMPANY_COUNTRY=$(echo $COMPANY_RESPONSE | jq -r '.mailing_address.country')

# create a json file with the company name, role and location
cat > $COMPANY_FILE <<EOF
{
    "company_name": "$COMPANY_NAME",
    "company_address": "$COMPANY_ADDRESS",
    "company_city": "$COMPANY_CITY",
    "company_state": "$COMPANY_STATE",
    "company_zip": "$COMPANY_ZIP",
    "company_country": "$COMPANY_COUNTRY"
}
EOF

TEMPLATE_FILE="letter.md.mustache"
MARKDOWN_OUTPUT_FILE="letter.md"
PDF_OUTPUT_FILE="output.pdf"
FONT="Hoefler Text"
ALT_FONT="Helvetica Neue"
MONO_FONT="Courier"
FONT_SIZE="11pt"
GEOMETRY="a4paper, left=35mm, right=35mm, top=25mm, bottom=25mm"
LANG="en-US"


cat > position.json <<EOF
{
    "company_focus": "$FOCUS",
    "position_title": "$ROLE"
}
EOF

rm -rf combined.json

FINAL_DATA_FILE="combined.json"

# combine data_file and author.json file
cat author.json config.json position.json $COMPANY_FILE | jq -s add | tee -a $FINAL_DATA_FILE

# check if data file exists
if [ ! -f "$FINAL_DATA_FILE" ]; then
    echo "Error: data file $FINAL_DATA_FILE does not exist"
    exit 1
fi

cat $FINAL_DATA_FILE | jq .

pbl -d $FINAL_DATA_FILE -t $TEMPLATE_FILE > $MARKDOWN_OUTPUT_FILE

make

open $PDF_OUTPUT_FILE

