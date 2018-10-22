#!/bin/bash
#
# @author: AK Sarav - www.middlewareinventory.com
# License: GPL 3.0 License
# Name: JavaThreadTop.sh
# Purpose : To Inspect and Find what Threads are consuming more CPU in any Given JVM
#			Weblogic, Websphere, Tomcat, Jboss etc.
# Version: 1
# Date: 22 October 2018 
#
#

# Variable Declaration Section
BASEDIR=`dirname $0`
WHOAMI=`whoami`
JVMPID=''
alias say='echo -e'

# Mask the echo -e
function say()
{
	echo -e $1;
}

# Validate The Startup Arguments
re='^[0-9]+$'

if [ $# -ne 1 ]
then
	say "\nERROR: The Script needs Exactly One argument at the startup which must be the PID of the JVM"
        say "Example:\n--------\n./JavaThreadTop.sh <PID OF THE JVM>\n"
        exit 3
elif ! [[ $1 =~ $re ]]; then
	say "\nERROR: Input is not a Number\n"	
	exit 4
else
	JVMPID=$1
fi

# Make Sure the JCMD is available or ask for the JAVA_HOME
command -v jcmd >/dev/null 2>&1
if [ $? -eq 0 ]
then
	say "\nINFO: JCMD is found. All Good"
	JCMDLOC=`command -v jcmd`
else
	say "\nERROR: JCMD is not found, Need Manual Input\n"
	say "\nEnter the JAVA/JDK BIN Directory ( The Directory under which java is present )"
	read JDKBIN
        command -v $JDKBIN/jcmd >/dev/null 2>&1	
	if [ $? -eq 0 ]
	then
		say "\nINFO: JCMD is found in the Path Specified. All Good\n"
        	JCMDLOC=`command -v $JDKBIN/jcmd`
	else
		say "\nERROR: SORRY. We need JCMD command to be present. Can you Make sure it is available"
		say "\nIf you think we are wrong, Here are few things you could do. Before RETRYING"
		say "\n1) Set JAVA_HOME and PATH with proper JAVA Locations in ~/.bash_profile file"
		say "2) Export JAVA_HOME and PATH variables manually using export command and make sure it works"
		say "3) Make sure the Version of JAVA you are using comes with JCMD"
		say "4) Make Sure it is Java Development Kit you are using not Java Runtime Environment"
		say "5) Google... "
		say ""
	fi
		
fi 

# Making Sure the JCMD is able to connect to the JVM
$JCMDLOC $JVMPID help >/dev/null 2>&1
if [ $? -eq 0 ]
then
	say "INFO: jcmd is able to connect to the JVM. All Good\n"
else
	say "\nERROR: jcmd is not able to connect to the JVM. Sorry"
	say "Is the JVM really up and running. jcmd cannot connect to the stale/OOM JVMs\n"
fi


# Making sure the top command supports Batch mode 
say "\nINFO: Checking if top command in the system support batch mode"
top -H -b -n 1 -o +%CPU >/dev/null 2>&1

if [ $? -eq 0 ]
then
	say "INFO: Voila! top command in your system supports the batch mode"
fi

# Making sure Less command is available or switch to cat
command -v less >/dev/null 2>&1

if [ $? -eq 0 ]
then
	editor='less'
else
	editor='cat'
fi


# Magic
say "INFO: Finding the Threads which are taking lot of your CPU\n"
say "INFO: Patience Please"
sleep 2

say "=============================================================="
say "\t FIRST 10 CPU CONSUMING THREADS AS OF NOW, ARE \t"
say "=============================================================="
top -H -b -n 1 -o +%CPU -p $JVMPID|head -n 17
say ""
sleep 2
say "=============================================================="
say "\t SUSPECIOUS THREADS WITH NAMES AND STACK TRACES "
say "=============================================================="
say "INFO: We present the thread info with less(or)cat command for your for better readability\n"
$JCMDLOC $JVMPID Thread.print|egrep -A 15 -i `top -H -b -n 1 -o +%CPU -p $JVMPID|head -n 17|awk '{print $1}'|grep ^[0-9]|xargs printf "|%X" $1|tr A-Z a-z|sed 's/^|//'` > JavaThreadTop-Output.log

$editor JavaThreadTop-Output.log

say "INFO: We have saved the Output into a file named *JavaThreadTop-Output.log* in the Current Directory for your future reference"
say "\n\nHOPE YOU LIKED THIS TOOL. THANKS and GOODBYE\n"
