#!/bin/bash
usage() {
    echo "Usage:"
    echo "  ./scripts/generateDocs [releaseDir] [outputDirPrefix]" 
    echo ""
    echo "Example:"
    echo " ./scripts/generateDocs release reference/0.x"
}

if [ $# -ne 2 ]; then
    usage
    exit 1
fi

RELDIR=$1
if [ ! -d ${RELDIR} ]; then
    echo "Not a directory: ${RELDIR}"
    exit 1
fi

OUTDIR_PREFIX="$2"


HAS_SWIFTDOC=`which swift-doc`
if [ $? -ne 0 ]; then
    echo "Fatal: Unable to find swift doc"
    exit 1
fi

if [ -d ${OUTDIR_PREFIX} ]; then
    echo "Error: Directory already exists: ${OUTDIR_PREFIX}"
    exit 1
fi

for todel in `find ${RELDIR} | grep "Models\.swift"`; do
    rm -f ${todel}
done

for sdk in `ls ${RELDIR} | grep -e "^AWS"`; do
    OUTDIR="${OUTDIR_PREFIX}/${sdk}"
    echo "Generating ${sdk}: ${OUTDIR}"
    swift doc generate ${RELDIR}/${sdk} --module-name ${sdk} --base-url "/aws-sdk-swift/${OUTDIR}" --output ${OUTDIR}
    if [ $? -ne 0 ]; then
	echo "Failed on ${sdk}"
	exit 1
    fi
    OUTFILECONFIG=${OUTDIR}/_config.yml
    echo "theme: jekyll-theme-slate" > ${OUTFILECONFIG}
    echo "Generated file ${OUTFILECONFIG}"
done

CHARS=$(python -c 'print u"\u200b".encode("utf8")')
for generatedFile in `find ${OUTDIR_PREFIX} | grep "\.md$"`; do
    TEMPFILE=`mktemp`
    cat ${generatedFile} | sed -r 's/['"${CHARS}"']//g'  > ${TEMPFILE}
    mv ${TEMPFILE} ${generatedFile}
    echo "Stripped ${generatedFile}"
done
