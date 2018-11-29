#!/bin/bash

# Slack incoming web-hook URL and user name
url='CHANGEME'		# example: https://hooks.slack.com/services/QW3R7Y/D34DC0D3/BCADFGabcDEF123
username='Zabbix'

## Values received by this script:
# To = $1 (Slack channel or user to send the message to, specified in the Zabbix web interface; "@username" or "#channel")
# Subject = $2 (usually either PROBLEM or RECOVERY/OK)
# Message = $3 (whatever message the Zabbix action sends, preferably something like "Zabbix server is unreachable for 5 minutes - Zabbix server (127.0.0.1)")
# url = $4 (optional url to replace the hardcoded one. useful when multiple groups have seperate slack environments)
# proxy = $5 (optional proxy, including port)

# Get the Slack channel or user ($1) and Zabbix subject ($2 - hopefully either PROBLEM or RECOVERY/OK)
to="$1"
subject="$2"
subject_status=`echo $subject | cut -d ' ' -f1`
severity=`echo $subject | cut -d ' ' -f3`

recoversub='^RECOVER(Y|ED)?$'
if [[ "$subject_status" =~ ${recoversub} ]]; then
	color='#20E020' # green text
elif [ "$subject_status" == 'PROBLEM' ]; then
	color='FFF333'    # yellow text - warning
	if [[ "$severity" == 'Average' ]]; then
		color='FFA233' # orange text
	elif [[ "$severity" == 'High' ]]; then
		color='FF3333' # red text
	elif [[ "$severity" == 'Disaster' ]]; then
                color='D80000' # dark red text
	fi
fi

# The message that we want to send to Slack is the "subject" value ($2 / $subject - that we got earlier)
#  followed by the message that Zabbix actually sent us ($3)
message="$3"

# in case a 4th parameter is set, we will use it for the url
url=${4-$url}
# in case a 5th parameter is set, we will us it for the proxy settings
proxy=${5-""}
if [[ "$proxy" != "" ]] ; then
  proxy=" -x $proxy "
fi

# Build our JSON payload and send it as a POST request to the Slack incoming web-hook URL
payload="payload={
        \"channel\": \"${to}\",
	\"username\": \"${username}\",
        \"icon_emoji\": \":zabbix:\",
	\"attachments\": [
           {
		\"title\": \"${subject}\",
                \"text\": \"${message}\",
	        \"fallback\": \"${message}\",
                \"color\": \"${color}\",
                \"mrkdwn_in\": [ \"text\" ]
           }
        ] }"
/usr/bin/curl $proxy -m 5 --data-urlencode "${payload}" $url -A 'zabbix-slack-alertscript / https://github.com/ericoc/zabbix-slack-alertscript'
