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

COMPANY_ADDRESS="123 Main St"
COMPANY_CITY="Portland"
COMPANY_STATE="Oregon"
COMPANY_ZIP="97201"

AUTHOR="Shane Witbeck"
AUTHOR_CITY="Kalama"
AUTHOR_STATE="Washington"
AUTHOR_EMAIL="shane.witbeck@gmail.com"
AUTHOR_PHONE="+1 (503) 956-0782"
DATA_FILE="$COMPANY_NAME-data.json"
TEMPLATE_FILE="letter.md.mustache"
MARKDOWN_OUTPUT_FILE="letter.md"
PDF_OUTPUT_FILE="output.pdf"
FONT="Hoefler Text"
ALT_FONT="Helvetica Neue"
MONO_FONT="Courier"
FONT_SIZE="9pt"
GEOMETRY="a4paper, left=35mm, right=35mm, top=25mm, bottom=25mm"
LANG="en-US"

# create a json file with the company name, role and location
cat > $DATA_FILE <<EOF
{
    "author": "$AUTHOR",
    "author_city": "$AUTHOR_CITY",
    "author_state": "$AUTHOR_STATE",
    "author_email": "$AUTHOR_EMAIL",
    "author_phone": "$AUTHOR_PHONE",
    "language": "$LANG",
    "geometry": "$GEOMETRY",
    "font": "$FONT",
    "alt_font": "$ALT_FONT",
    "mono_font": "$MONO_FONT",
    "font_size": "$FONT_SIZE",
    "line_stretch": "$LINE_STRETCH",
    "paper_size": "$PAPER_SIZE",
    "company": "$COMPANY_NAME",
    "company_focus": "$FOCUS",
    "company_address": "$COMPANY_ADDRESS",
    "company_city": "$COMPANY_CITY",
    "company_state": "$COMPANY_STATE",
    "company_zip": "$COMPANY_ZIP",
    "position_title": "$ROLE"
}
EOF

pbl -d $DATA_FILE -t $TEMPLATE_FILE > $MARKDOWN_OUTPUT_FILE

# pandoc --template=default.latex --pdf-engine=xelatex -s $MARKDOWN_OUTPUT_FILE -o $PDF_OUTPUT_FILE

make

open $PDF_OUTPUT_FILE

