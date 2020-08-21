#!/bin/bash

function getindent() {
	INDENT=$((${1}))
	IND=$((0))
	RET=""
	while [ $IND -lt $INDENT ] ; do
		RET="\t$RET"
		IND=$(($IND+1))
	done
	echo "$RET"
}

function curlylen() {
	LEN=0
	while [[ "${1}" != "curly" && ! -z "${1}" ]] ; do
		LEN=$(($LEN+1))
		shift 1
	done
	echo $(($LEN))
}

function listshift() {
	SHIFT=2
	shift 1
	LEN=$((${1}))
	IND=0
	shift 1
	while [ $IND -lt $LEN ]; do
		case ${1} in
			curly)
				shift 1
				ADD=$(curlylen ${@})
			;;
			list)
				shift 1
				ADD=$(listlen ${@})
			;;
			*)
				shift 1
				ADD=1
			;;
		esac
		shift $ADD
		SHIFT=$(($SHIFT+1+$ADD))
		IND=$(($IND+1))
	done
	echo $(($SHIFT))
}

function curly() {
	IND=$(($1))
	INDENT=$(getindent ${IND})
	LENGTH=$(curlylen ${@})
	shift 1
	SHIFT=1
	IND=$(($IND+1))
	if [ $LENGTH -le 1 ] ; then
		printf "{}\n"
	elif [ $LENGTH -eq 2 ] ; then
		printf "${INDENT}\"${1}\""
	else
		FIRST="${1}"
		if [ "$FIRST" == "curly" ] ; then
			shift 1
			SHIFT=$(($(curlylen ${@})+$SHIFT))
			_REPL_=$(curly $IND ${@})
			shift $SHIFT
		elif [ "${FIRST}" == "list" ] ; then
			shift 1
			ID="\"${1}\""
			LEN=$((${2}))
			SHIFT=$(($(listshift ${@})+$SHIFT))
			shift 2
			_REPL_="${INDENT}${ID}: [\n"
			INDEX=$((0))
			while [ $INDEX -lt $LEN ] ; do
				if [ $INDEX -eq 0 ] ; then
					_REPL_="${_REPL_}\n$(curly $IND ${@})"
				else
					_REPL_="${_REPL_},\n$(curly $IND ${@})"
				fi
				INDEX=$(($INDEX+1))
				shift 1
				case ${1} in
					curly)
					shift 2
					while [ "${1}" != "curly" ] ; do
						if [ "${1}" == "list" ] ; then
							shift $((${2}+2))
						else
							shift 1
						fi
					done
					;;
					list)
					shift $((${2}+2))
					;;
					*)
					shift 1
					;;
				esac
			done
			_REPL_="${_REPL_}\n${INDENT}]\n"
		else
			_REPL_="${INDENT}\"${1}\": "
			shift 1
			_REPL_="${_REPL_}$(curly $IND ${@})"
		fi
		shift $SHIFT
		printf "${INDENT}{\n${_REPL_}\n${INDENT}},\n$(curly $IND ${@})"
	fi
}

curly 0 ${@}
