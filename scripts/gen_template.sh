#!/bin/bash

LICENSE=${PWD}/scripts/license.txt
CURRDIR=${PWD}/scripts/currdir.sh
YEAR="2020"
AUTHOR="Tristan Miano"
EMAIL="jacobeus@protonmail.com"
SUBJECT="gen_template.sh"

. ${PWD}/shFlags/shflags
. ${PWD}/helper_functions.sh

DEFINE_string "filename" "" "Required. Name of BASH script to create." f
DEFINE_string "imports" "shFlags/shflags default_vars.sh" "List of BASH scripts containing functions/variables you would like to import. Starting at root directory." i
DEFINE_string "args" "verbose,boolean" "List of command line arguments to add to the script, using [name,type] separated by spaces. E.g., verbose,boolean output_directory,string etc." a
DEFINE_string "version" "" "Version number, optional." v

# parse command line
FLAGS "$@" || exit 1
eval set -- "${FLAGS_ARGV}"

if [ -z "${FLAGS_filename}" ] ; then
	_echo_err "Error: Missing filename argument."
	exit 1;
else
	NEW_FILE="${FLAGS_filename}"
	if [ -f "${NEW_FILE}" ] ; then
		_echo_err "Error: file already exists."
		exit 1;
	fi
	touch $NEW_FILE
	chmod +rwx $NEW_FILE
fi

IMPORTS=""
for i in "${FLAGS_imports}" ; do
	if [ -z "${IMPORTS}" ] ; then
		IMPORTS="${i}"
	else
		IMPORTS="${IMPORTS} $i"
	fi
done

function echof() {
	echo "${1}" >> $NEW_FILE
}

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
echof "SUBJECT=\"${NEW_FILE}\""
if [ ! -z "${FLAGS_version}" ] ; then
	echof ""
	echof "VERSION=\"${FLAGS_version}\""
fi

echof ""
echof ""
echof "# BEGIN IMPORTS #"

for i in $IMPORTS ; do echof ". \${THIS_DIR}/$i" ; done

echof "# END IMPORTS #"
echof ""
echof "# BEGIN CMDLINE ARGS #"
for i in ${FLAGS_args} ; do
	ARG_NAME=$(echo "$i" | sed -e "s/,.*//g")
	ARG_TYPE=$(echo "$i" | sed -e "s/.*,//g")
	if [ "${ARG_TYPE}" == "boolean" ] ; then
		echof "DEFINE_${ARG_TYPE} \"${ARG_NAME}\" \"1\" \"[description]\" "
	else
		echof "DEFINE_${ARG_TYPE} \"${ARG_NAME}\" \"[default value]\" \"[description]\" "
	fi
done
echof ""
echof "# parse command line"
echof "FLAGS \"\$@\" || exit 1"
echof "eval set -- \"\${FLAGS_ARGV}\""
echof ""

for i in ${FLAGS_args} ; do
        ARG_NAME=$(echo "$i" | sed -e "s/,.*//g")
        ARG_TYPE=$(echo "$i" | sed -e "s/.*,//g")
	if [ "${ARG_TYPE}" == "boolean" ] ; then
		#In shFlags, strangely, 0 means true and 1 means false. So we parse it into true/false once at the beginning.
                echof "if [ \"\${FLAGS_${ARG_NAME}}\" == \"0\" ] ; then"
		echof "		${ARG_NAME}=\"true\""
		echof "else"
		echof "		${ARG_NAME}=\"false\""
		echof "fi"
		echof ""
        else
                echof "${ARG_NAME}=\"\${FLAGS_${ARG_NAME}}\""
		echof ""
        fi
done

echof "# END CMDLINE ARGS #"
echof ""
echof "# BEGIN $NEW_FILE #"
echof ""
echof ""
echof "# END $NEW_FILE #"








