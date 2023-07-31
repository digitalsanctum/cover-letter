#!/bin/bash

set -e

# accept a single argument, the name of the company
if [ $# -ne 3 ]; then
    echo "Usage: $0 <company-name> <focus> <role>"
    exit 1
fi

COMPANY_NAME=$1
FOCUS=$2
ROLE=$3

ENCODED_COMPANY_NAME=$(printf %s "$COMPANY_NAME" |jq -sRr @uri)
echo "Encoded company name: $ENCODED_COMPANY_NAME"

# convert company_name to valid file name with json suffix
DATA_FILE=$(printf %s "$COMPANY_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -d '[:punct:]').json
echo "Data file: $DATA_FILE"

# given the company name, curl the local service to get the address
CA_URL="http://localhost:8000/companies/$ENCODED_COMPANY_NAME/address"
echo "Getting company address from $CA_URL"
COMPANY_MAILING_ADDRESS=$(curl -s "http://localhost:8000/companies/$ENCODED_COMPANY_NAME/address" | jq -r .mailing_address)
if [ $? -ne 0 ]; then
    echo "Error: could not get mailing address for $COMPANY_NAME"
    exit 1
fi
echo $COMPANY_MAILING_ADDRESS | jq .
COMPANY_ADDRESS=$(echo $COMPANY_MAILING_ADDRESS | jq -r '.street')
COMPANY_CITY=$(echo $COMPANY_MAILING_ADDRESS | jq -r '.city')
COMPANY_STATE=$(echo $COMPANY_MAILING_ADDRESS | jq -r '.state_or_province')
COMPANY_ZIP=$(echo $COMPANY_MAILING_ADDRESS | jq -r '.postal_code')
COMPANY_COUNTRY=$(echo $COMPANY_MAILING_ADDRESS | jq -r '.country')

AUTHOR="Shane Witbeck"
AUTHOR_CITY="Kalama"
AUTHOR_STATE="Washington"
AUTHOR_EMAIL="shane.witbeck@gmail.com"
AUTHOR_PHONE="+1 (503) 956-0782"
TEMPLATE_FILE="letter.md.mustache"
MARKDOWN_OUTPUT_FILE="letter.md"
PDF_OUTPUT_FILE="output.pdf"
FONT="Hoefler Text"
ALT_FONT="Helvetica Neue"
MONO_FONT="Courier"
FONT_SIZE="11pt"
GEOMETRY="a4paper, left=35mm, right=35mm, top=25mm, bottom=25mm"
LANG="en-US"

rm -rf $DATA_FILE

# create a json file with the company name, role and location
cat > $DATA_FILE <<EOF
{
    "geometry": "$GEOMETRY",
    "font": "$FONT",
    "alt_font": "$ALT_FONT",
    "mono_font": "$MONO_FONT",
    "font_size": "$FONT_SIZE",
    "company": "$COMPANY_NAME",
    "company_focus": "$FOCUS",
    "company_address": "$COMPANY_ADDRESS",
    "company_city": "$COMPANY_CITY",
    "company_state": "$COMPANY_STATE",
    "company_zip": "$COMPANY_ZIP",
    "company_country": "$COMPANY_COUNTRY",
    "position_title": "$ROLE"
}
EOF

rm -rf combined.json

FINAL_DATA_FILE="combined.json"

# combine data_file and author.json file
cat author.json $DATA_FILE | jq -s add | tee -a $FINAL_DATA_FILE
cat $FINAL_DATA_FILE | jq .

# check if data file exists
if [ ! -f "$FINAL_DATA_FILE" ]; then
    echo "Error: data file combined.json does not exist"
    exit 1
fi

cat $FINAL_DATA_FILE | jq .

pbl -d $FINAL_DATA_FILE -t $TEMPLATE_FILE > $MARKDOWN_OUTPUT_FILE

# pandoc --template=default.latex --pdf-engine=xelatex -s $MARKDOWN_OUTPUT_FILE -o $PDF_OUTPUT_FILE

make

open $PDF_OUTPUT_FILE

