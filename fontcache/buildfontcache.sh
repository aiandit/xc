#! /bin/zsh

res=0
set -x

mydir=$(dirname ${(%):-%N})

fdir=${1:-/usr/share/fonts}

otfinfo --info $fdir/**/*.ttf $fdir/**/*.otf | \
    grep -E 'Family:|Subfamily:' | \
    p2x -mX -b 'NEWLINE' -b COLON -i SPACE -b 'DIV' -b JUXTA -o out.xml

xsltproc -o fontcache-tmp.xml $mydir/generate-fontcache.xsl out.xml
xsltproc -o fontcache-tmp2.xml $mydir/generate-fontcache2.xsl fontcache-tmp.xml
xsltproc -o fontcache-tmp3.xml $mydir/normalize-fontcache.xsl fontcache-tmp2.xml
xsltproc -o fontcache.xml $mydir/strip-duplicates.xsl fontcache-tmp3.xml
xsltproc -o fontcache.csv $mydir/fontcache-csv.xsl fontcache.xml
zip fontcache.zip fontcache.csv fontcache.xml

rm -f fontcache-tmp*.xml out.xml

exit $res
