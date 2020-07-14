#! /bin/bash

id=out-$1

page=http://localhost:8010/main/ajax_counter

rm -rf $id
mkdir -p $id
rm -f $id/cookies.txt

curl -o $id/out1.html -sS -c $id/cookies.txt -b $id/cookies.txt $page?path=t2/c1.xml
csrf=$(awk '/csrftoken/ { print $7 }' $id/cookies.txt)

echo "$i: csrf=$csrf"

for i in {1..10}; do
    curl -o $id/out2-$i.html -sS -c $id/cookies.txt -b $id/cookies.txt \
         $page -F path=t2/c1.xml -F incr=on -F csrfmiddlewaretoken=$csrf
    grep -E "error|xcontent>" $id/out2-$i.html
done
