NEW_FILE=${1}
LICENSE=${PWD}/scripts/license.txt
CURRDIR=${PWD}/scripts/currdir.sh
YEAR="2020"
AUTHOR="Tristan Miano"
EMAIL="jacobeus@protonmail.com"
IMPORTS="shFlags/shflags helper_functions.sh default_vars.sh"

function echof() {
	echo "${1}" >> $NEW_FILE
}

touch $NEW_FILE
chmod +x $NEW_FILE

echof "#!/bin/bash"
echof ""

while IFS= read -r line
do
	echof "# $(echo $line | sed -e "s/<year>/$YEAR/g" | sed -e "s/<name of author>/$AUTHOR <$EMAIL>/g")" #<year>  <name of author>
done < $LICENSE

echof ""
echof ""

while IFS= read -r line
do
        echof "$line"
done < $CURRDIR

echof ""
echof ""
echof "# BEGIN IMPORTS #"

for i in $IMPORTS ; do echof ". \${THIS_DIR}/$i" ; done

echof "# END IMPORTS #"
echof ""
echof "# BEGIN $NEW_FILE #"
echof ""
echof ""
echof "# END $NEW_FILE #"








