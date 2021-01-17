#!/bin/bash

FILENAME=$2
HEADING=$1

echo "Linsting: $1"
echo ""
printf '%-20s\t%-20s\n' "Field" "Value"
echo "--------------------------------"

#sed -n -e "/${HEADING}/,/^>>>/p" ${FILENAME}
awk "/>>>${HEADING}/{flag=1; next} />>>/{flag=0} flag" ${FILENAME} | sed '/^$/d' | \
awk -F[=] '{printf "%-20s=  %s\n", $1 , $2}'
echo ""

=======================================

#!/bin/bash
#Version: 0.1
if [ $# -ne 2 ]; then
  echo "Usage: readmyfile.sh scsvalue myexampleconfig.txt";
  exit 1;
fi

HEADING="${1}"
FILENAME="${2}"

FIELDS=$(sed -n "/^>>>${HEADING}\$/,/^$/p" "${FILENAME}" | grep '=' | sed 's/[ \t]\+//g')
while read LINE; do
  name=$(echo ${LINE} | cut -f1 -d=)

  #this version preserves ' and "
  #value=$(echo ${LINE} | cut -f2 -d=)

  #this version removes the quotes
  value=$(echo ${LINE} | cut -f2 -d= | sed "s/['\"]//g")

  export $name=$value
done <<< "${FIELDS}"
