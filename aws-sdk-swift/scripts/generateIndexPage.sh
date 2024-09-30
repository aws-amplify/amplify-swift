#!/bin/bash
usage() {
    echo "Usage:"
    echo "  ./scripts/generateIndexPage.sh [outputDirPrefix]" 
    echo ""
    echo "Example:"
    echo " ./scripts/generateIndexPage.sh reference/0.x"
}

if [ $# -ne 1 ]; then
    usage
    exit 1
fi

OUTDIR_PREFIX="$1"

if [ ! -d ${OUTDIR_PREFIX} ]; then
    echo "Error: Directory not found: ${OUTDIR_PREFIX}"
    exit 1
fi

NUMSERVICES=`ls ${OUTDIR_PREFIX} |grep -e "^AWS" |wc -l | awk '{print $1}'`
if [ $NUMSERVICES -eq 0 ]; then
    echo "Error: No services found in : ${OUTDIR_PREFIX}"
    exit 1
fi

OUTFILE=${OUTDIR_PREFIX}/index.md


createFileWithLine() {
    echo "$1" > ${OUTFILE}
}
appendLine() {
    echo "$1" >> ${OUTFILE}
}

createFileWithLine "# AWS SDK Swift API Reference"
for sdk in `ls ${OUTDIR_PREFIX} | grep -e "^AWS"`; do
    appendLine "- [${sdk}](${sdk}/Home)"
done
echo "Generated file ${OUTFILE}"

OUTFILECONFIG=${OUTDIR_PREFIX}/_config.yml
echo "theme: jekyll-theme-slate" > ${OUTFILECONFIG}
echo "Generated file ${OUTFILECONFIG}"
