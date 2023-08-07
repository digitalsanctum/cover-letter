#!/bin/bash

set -e

# accept a single argument, the name of the company
if [ $# -ne 2 ]; then
    echo "Usage: $0 <company-name> <role>"
    exit 1
fi

COMPANY=$1
ROLE=$2

ENCODED_COMPANY_NAME=$(printf %s "$COMPANY" |jq -sRr @uri)
echo "Encoded company name: $ENCODED_COMPANY_NAME"

# convert company_name to valid file name with json suffix
COMPANY_PREFIX=$(printf %s "$COMPANY" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -d '[:punct:]')

mkdir -p $COMPANY_PREFIX

COMPANY_FILE="$COMPANY_PREFIX/company.json"
echo "Company file: $COMPANY_FILE"

TEMPLATE_FILE="letter.md.mustache"

AUTHOR_FILE="author.json"
CONFIG_FILE="config.json"
MARKDOWN_OUTPUT_FILE="${COMPANY_PREFIX}/letter.md"
POSITION_FILE="${COMPANY_PREFIX}/position.json"
FINAL_DATA_FILE="${COMPANY_PREFIX}/data.json"
FINAL_PDF_FILE="${COMPANY_PREFIX}/final.pdf"

function get_company_address() {
  # given the company name, curl the local service to get the address
      CA_URL="http://localhost:8000/companies/$ENCODED_COMPANY_NAME/address"
      echo "Getting company address from $CA_URL"
      COMPANY_RESPONSE=$(curl -s "$CA_URL")
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
}

function get_company_focus() {
    CF_URL="http://localhost:8000/companies/$ENCODED_COMPANY_NAME/focus"
          echo "Getting company focus from $CF_URL"
          COMPANY_FOCUS_RESPONSE=$(curl -s "$CF_URL")
          if [ $? -ne 0 ]; then
              echo "Error: could not get company focus for $COMPANY"
              exit 1
          fi

          echo $COMPANY_FOCUS_RESPONSE | jq .
          COMPANY_FOCUS="$(echo $COMPANY_FOCUS_RESPONSE | jq -r '.focus')"

cat > ${POSITION_FILE} <<EOF
{
    "company_focus": "$COMPANY_FOCUS",
    "position_title": "$ROLE"
}
EOF
}

# check if company file exists
if [ -f "$COMPANY_FILE" ]; then
    echo "Company file $COMPANY_FILE already exists; skipping lookup"
else
    get_company_address
fi

# check if position file exists
if [ -f "$POSITION_FILE" ]; then
    echo "Position file $POSITION_FILE already exists; skipping lookup"
else
    get_company_focus
fi

rm -rf $FINAL_DATA_FILE

# combine data files
cat $AUTHOR_FILE $CONFIG_FILE $POSITION_FILE $COMPANY_FILE | jq -s add | tee $FINAL_DATA_FILE

# verify data file exists
if [ ! -f "$FINAL_DATA_FILE" ]; then
    echo "Error: data file $FINAL_DATA_FILE does not exist"
    exit 1
fi

# first, use mustache to generate the letter.md file
pbl -d $FINAL_DATA_FILE -t $TEMPLATE_FILE > $MARKDOWN_OUTPUT_FILE

# second, use pandoc to generate the final PDF
pandoc $MARKDOWN_OUTPUT_FILE -o $FINAL_PDF_FILE --template=template.tex --pdf-engine=xelatex

open $FINAL_PDF_FILE

