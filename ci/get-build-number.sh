#! /bin/bash

mydir=$(dirname $BASH_SOURCE)

vn=$(cat $mydir/VERSION)
vn_rev=$(cat $mydir/rev.txt)

an=$(git log --oneline | wc | awk '{ORS=""; print $1}')

let bn=($an - $vn_rev)

printf "%d" $bn
