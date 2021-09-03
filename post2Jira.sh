#!/bin/bash

# This script will post a message to a Jira project via a web hook
#
#   Argument 1: Jira Project ID (RFDPRF, DEVINFRA, etc) This is the short id from jira project
#   Argument 2: A subject/summary
#   Argument 3: A detailed description
#   Argument 4: Issue Type (Task, Subtask, Issue...)
#   Argument 5(optional): A component value (Dynatrace, Other, etc.)

# Ex execution: export ext_root=$HOME/dynatrace;${ext_root}/lib/post2Jira.sh RFDPRF 'This is a test summary' 'This is a test description' 'Task'

###
# Start Function Area

cleanupFiles() {
	rm -rf $TMPFILE > /dev/null 2>&1
}

buildBody() {
	if [[ -z ${component} || ${component} = '' ]]; then
		# No component value provided
		TEMPLATE="./jira_body_template.json"
	else
		# We have a component value passed in
		TEMPLATE="./jira_body_with_component_template.json"
	fi

	TMPFILE=$(mktemp --tmpdir=/tmp --suffix=.json ${jira_project}_XXXXXXXX)

	cp $TEMPLATE $TMPFILE > /dev/null 2>&1

	sed -i  "s/_PROJECT_/$jira_project/g" $TMPFILE > /dev/null 2>&1
	sed -i  "s/_SUMMARY_/$summary/g" $TMPFILE > /dev/null 2>&1
	sed -i  "s/_DESCRIPTION_/$description/g" $TMPFILE > /dev/null 2>&1
	sed -i  "s/_ISSUE_TYPE_/$issuetype/g" $TMPFILE > /dev/null 2>&1

	cat $TMPFILE | jq '.'

}

checkForComponent() {
	if [[ -z $component ]]; then
		echo -e "Component value is required for this jira project...."
		exit 1
	else
		sed -i  "s/_COMPONENT_/$component/g" $TMPFILE > /dev/null 2>&1
	fi
}
# End function area

# Assumed that this variable is exported prior to calling script
if [ -z ${ext_root+x} ]; then
	echo -e "Extension Root Directory not set...exiting..."
	exit 1
fi

# Load parameters passed in and script variables
customer=RFD
environment=PRD

jira_project=$1
summary=$2
description=$3
issuetype=$4
component=$5

webhookURL="https://<your_id>.atlassian.net/rest/api/latest/issue/"

# Using "one" RFD Operations account as the reporter
user=<your_user>
token=<your_token>

# Build Jira json body
buildBody

# Call jira with formatted body
response=
curl -u ${user}:${token} -H 'Content-Type: application/json' -X POST -d @$TMPFILE "$webhookURL" > $response

echo $response

# Delete temporary files
cleanupFiles
