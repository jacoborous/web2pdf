while :
do
	curl -s 'https://api.ipify.org?format=json' | sed -e 's/{\"ip\":\"//g' | sed -e 's/\"}//g'
	echo ""
	sleep 1
done
