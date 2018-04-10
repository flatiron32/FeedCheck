#!/usr/bin/env bash

getValues() {
  delim=$1

  if [ "$delim" == "<" ]; then
    xmllint $4 --shell <<< `echo "cat //$3/text()"` 2>/dev/null | grep -v " -" | grep -v "/ >" | grep -v "^\s*$" || echo "empty" 
  elif [ "$delim" == "[" ]; then
    elName=$(echo $3 | sed s/"\(.*\)"/\\1/g)
    jq ".[]|..|.$elName?" $4 | grep -v null | grep -v "\[\|\]" | sort | uniq
  elif [ "$delim" == "\t" ]; then
    csvcut -e $encoding -t -c "$2" $4 | tail -n +2
  else
    csvcut -e $encoding -d "$delim" -c "$2" $4 | tail -n +2
  fi
}

echo "h1. $(basename $1)"
echo "h2. File Stats"
echo " * File evaluated: $(basename $1)"
encoding="UTF-8"
csvcut -e "$encoding" -c 1 -u3 $1 2>/dev/null 1>&2

if [ $? -ne 0 ]; then
  encoding="cp1252"
  csvcut -e "$encoding" -c 1 -u3 $1 2>/dev/null 1>&2
  if [ $? -ne 0 ]; then
    echo "Unknown encoding. Tried UTF-8 and cp1252"
    exit -1
  fi
fi

headerRow=$(head -n1 $1)
commas="${headerRow//[^,]}"
pipes="${headerRow//[^|]}"
tabs="$(echo  "$headerRow" | awk '{print gsub(/\t/,"")}')"
if [ ${headerRow:0:1} == "<" ]; then
  echo "* XML File"
  sep='<'

  echo "* File Encoding $encoding"
  echo "* $(tail -n +2 $1 | wc -l) elements"
  columns="$(echo "du" | xmllint --shell $1 | sort -r |uniq | grep -v ">" | awk '{$1=$1};1')"
  echo "* $(echo -e "$columns" | wc -l) fields"
  #echo -e "Columns:\n$columns"
elif [ ${headerRow:0:1} == "[" ]; then
  echo "* JSON File"
  sep='['

  echo "* File Encoding $encoding"
  echo "* $(grep -c ":" $1) elements"
  columns="$(grep "\":" $1 | cut -d: -f1 | sort | uniq )"
#  echo -e "Columns:\n$columns"
  echo "* $(echo -en "$columns" | wc -l) fields"
else
  if [ $tabs -gt 0 ]; then
    echo "* Tab Delimited File"
    sep='\t'
  elif [ ${#commas} -gt ${#pipes} ]; then
    echo "* Comma Delimited File"
    sep=','
  elif [ ${#pipes} -gt 0 ]; then
    echo "* Pipe Delimited File"
    sep='|'
  else
    echo "* Unknown file delimiter"
    exit -1
  fi

  echo "* File Encoding $encoding"
  cnt=$(tail -n +2 $1 | wc -l)
  echo "* $cnt rows"
  columns="$(echo "$headerRow" | tr $sep '\n')"
  echo "* $(echo -e "$columns" | wc -l) columns"
  #echo -e "Columns:\n$columns"
fi

IFS=$'\n\r'

echo
echo "h2. Data Stats"
echo "||Field||Count||Blank Count||Diff Count||Most Common (Count)||"

count=0
for col in $columns
do
  (( count++ ))

  values=$(getValues "$sep" "$count" $col $1)
  #echo -n "$(getValues "$sep" "$count" $col $1)"
  #echo
  if [ "$sep" == "<" ]; then
    blankCnt=$(xmllint $1 --xpath " count(//$col[not(text())])")
    cnt=$(grep -c "<$col" $1)
  elif [ "$sep" == "[" ]; then
    blankCnt=$(grep -c "$col: \"\"" $1)
    cnt=$(grep -c "$col:" $1)
  else
    blankCnt=$(echo -n "$values" | grep -cs "^$")
  fi
  diffCnt=$(echo -n "$values" | sort | uniq | wc -l)
  mostCommon=$(echo -n "$values" | sort | uniq -c | sort -n | tail -n1 | awk 'BEGIN{FS=OFS=" "} {a=$1; for (i=1;i<NF; i++) $i=$(i+1); $NF="("a")"}1' | tr '|' '>' )
  printf "| %s| %s | %s| %s| %s|\n" $col $cnt $blankCnt $diffCnt $mostCommon
done

echo
