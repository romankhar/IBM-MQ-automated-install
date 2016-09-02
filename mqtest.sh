#!/bin/bash
# NAME:      	mqtest
# VERSION:	1.0
# DATE:	January 22, 2014
# AUTHOR:    	Roman Kharkovski (http://whywebsphere.com/resources-links)
#
# DESCRIPTION:
# 	This script tests the operation of the queue manager by putting and getting messages from the queue using IBM's Performanced Harness tool
#
#   	http://WhyWebSphere.com
#
# RETURNED VALUES:
#   	0  - Test completed successfully
#   	1  - Something went wrong


# This prevents running the script if any of the variables have not been set
set -o nounset
# This automatically exits the script if any error occurs while running it
set -o errexit
	
source setenv.sh

#############################################
# RunTestMessages
#
# Parameters
# 1 - Queue Manager name
# 2 - Request Queue name
# 3 - Reply Queue name
# 4 - Host name of the MQ server
# 5 - Port number of the MQ listener
#############################################
RunTestMessages() {
echo " Starting requestor and responder background processes in parallel..."

# test messages using default WMQ test programs - need to setup some edditional environment properties for this to work and can't run real performance test
#$WMQ_INSTALL_DIR/samp/bin/amqsputc $2 $1 << EOF
#	Hello world. Are you subscribed to http://WhyWebSphere.com blog?
#EOF
#
#$WMQ_INSTALL_DIR/samp/bin/amqsputc $3 $1 << EOF
#	Hi there. Yes, I am indeed subscribed to http://WhyWebSphere.com
#EOF

# IBM's PerformanceHarness for JMS can run very sophisticated performance tests. Read more here: http://ibm.co/LGAWLt

# This will start the responder client - it needs to run longer than the requester and its  performance numbers can be ignored since it will be sitting idle half of the time
java -cp perfharness12.jar:$WMQ_INSTALL_DIR/java/lib/* -Xms1024M -Xmx1024M -Xmn800M JMSPerfHarness -su -id 1 -tc jms.r11.Responder -jb $1 -jp $5 -jh $4 -jc SYSTEM.DEF.SVRCONN -pc WebSphereMQ -jt mqb -jq SYSTEM.BROKER.DEFAULT.STREAM -ja 100 -oq $3 -iq $2 -to 50 -co false -mt text -mf payload.txt -wi 0 -rl 15 -ss 1 -nt 5 -pp false -tx false -sc BasicStats &

# This starts the requestor client (put message in $2 and wait for reply from the $3 - these are the real performance numbers
java -cp perfharness12.jar:$WMQ_INSTALL_DIR/java/lib/* -Xms1024M -Xmx1024M -Xmn800M JMSPerfHarness -su -id 1 -tc jms.r11.Requestor -jb $1 -jp $5 -jh $4 -jc SYSTEM.DEF.SVRCONN -pc WebSphereMQ -jt mqb -jq SYSTEM.BROKER.DEFAULT.STREAM -ja 100 -oq $3 -iq $2 -to 50 -co false -mt text -mf payload.txt -wi 0 -rl 10 -ss 1 -nt 5 -pp false -tx false -sc BasicStats &

}

#############################################
# MAIN BODY starts here
#############################################
HOST=`hostname`

echo "------------------------------------------------------------------------------"
echo " This script will run few test messages in and out of WebSphere MQ"
echo " Read more about this script here: http://WhyWebSphere.com"
echo " Today's date: `date`"
echo " Here are the default values used in the script (feel free to change these):"
echo "   WebSphere MQ Install Path: '$WMQ_INSTALL_DIR'"
echo "   Queue Manager Host:        '$HOST'"
echo "   Queue Manager Name:        '$QM'"
echo "   Queue Mgr Listener Port:   '$PORT'"
echo "   Test Queue #1:             '$REQUESTQ'"
echo "   Test Queue #2:             '$REPLYQ'"
echo ""

# Lets run some messages to see if our new queue manager works
RunTestMessages $QM $REQUESTQ $REPLYQ $HOST $PORT

echo " "
echo " SUCCESS. Please wait for REQUESTOR background process to finish the work..."
echo " RESPONDER process will keep running for few seconds longer - just ignore it."
echo "------------------------------------------------------------------------------"

