#!/bin/bash

old_ifs="$IFS"
IFS=";"
exit_code=0

function print() {
  echo -e "$3 The configuration '$1' is $2"
}

while read property expected message
do
  if [[ $(echo $1 | jq $property) == $expected ]]; then
    print $message OK '\033[0;32m'
  else
    print $message WRONG '\033[0;31m'
    exit_code=1
  fi
done < $2

IFS=$old_ifs
exit $exit_code
