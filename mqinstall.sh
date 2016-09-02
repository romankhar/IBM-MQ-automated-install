#!/bin/bash
# NAME:      	mqinstall
# VERSION:	1.0
# DATE:	January 22, 2014
# AUTHOR:    	Roman Kharkovski (http://whywebsphere.com/resources-links)
#
# DESCRIPTION:
# 	This script unpacks pre-existing downloaded version of WebSphereMQ on RHEL OS,
# 	modifies OS kernel settings, installs WMQ and creates one Queue Manager and test Queues
#
#   	http://WhyWebSphere.com
#
# CAVEATS/WARNINGS:
# 	This script assumes that you already have downloaded tar of the WMQ.
# 	You can read more about the use of this script in this blog post: <<<<<<<<.................>>>>>>>>>>>>
#
# RETURNED VALUES:
#   	0  - Install completed successfully
#   	1  - Something went wrong

##################################################
# Check that the current shell is running as sudo root, and exit if not.
##################################################
if [ $EUID != "0" -o -z "$SUDO_USER" ] ; then
	echo "" >&2
	echo "ERROR: This script must be run from non-root account with a sudo root command." >&2
	echo "       To learn how to add your user to the sudoers file, visit http://red.ht/1dRpB5C" >&2
	echo "" >&2
	exit 1
fi

if [ $SUDO_USER = "root" ] ; then
	echo "" >&2
	echo "ERROR: The sudo user must be a non-root." >&2
	echo "       Log in as a non-root user and run this script again using the sudo command." >&2
	echo "" >&2
	exit 1
fi

# Some useful tips about error checking in bash found here: http://www.davidpashley.com/articles/writing-robust-shell-scripts/
# This prevents running the script if any of the variables have not been set
set -o nounset
# This automatically exits the script if any error occurs while running it
set -o errexit

source setenv.sh	

# Some decent tuning parameters for WMQ Queue Managers. Read more in the docs: http://ibm.co/1jksAHC
QUEUE_BUFFER_SIZE=1048576
LOG_BUFFER_PAGES=512
LOG_PRIMARY_FILES=16
LOG_FILE_PAGES=16384
MAX_HANDLES=50000
FDMAX=1048576

# Feel free to change these as you see fit
DOWNLOAD_PATH=/home/$SUDO_USER/Downloads
WMQ_ARCHIVE=MQ_7.5.0.2_TRIAL_LNX_ON_X86_64_ML.tar.gz

# For best performance your queque file and your log file really should point to two separate physical disks, but for this test we don't care
QM_DATA_PATH=/var/mqm/${QM}_DATA
QM_LOG_PATH=/var/mqm/${QM}_LOG

source functions.sh

#############################################
# AddMQMuser
#############################################
AddMQMuser() {
	echo "------> This function configures Linux kernel so that we can later install WMQ rpms"

	# Add mqm group and ignore the error if the group already exists
	groupadd mqm | true

	# Add mqm user and ignore the error if the user already exists
	useradd mqm -g mqm | true

	# Update ulimits for mqm
	UpdateUserLimits mqm

	# Update ulimits for current user
	UpdateUserLimits $SUDO_USER

	# Add current user to the mqm group, so that the current user can call mq commands
	usermod --groups mqm $SUDO_USER

	echo "<------"
}

#############################################
# UpdateUserLimits
#	This function updates user limits for the given user $1
# Params
# 1 - username
#############################################
UpdateUserLimits() {
	echo "------> Configuring user limits for the user $1"

	backupFile /etc/security/limits.d/$1.conf | true
	cat <<-EOF > /etc/security/limits.d/$1.conf
		# Security limits for members of the mqm group
		mqm soft nofile $FDMAX
		mqm hard nofile $FDMAX
		mqm soft nproc  $FDMAX
		mqm hard nproc  $FDMAX
EOF

	echo "<------ new file [/etc/security/limits.d/$1.conf] created."
}
#############################################
# CreateQueueManagerIniFile
#
# Parameters
# 1 - Queue Manager temporary file name
# 2 - Queue Manager log file path
# 3 - Queue Manager name
#############################################
CreateQueueManagerIniFile() {
	echo "------> This function creates queue manager $QM qm.ini file in local directory"
	rm -f $1
	cat << EOF > $1
#*******************************************************************#
#* Module Name: qm.ini                                             *#
#* Type       : WebSphere MQ queue manager configuration file      *#
#  Function   : Define the configuration of a single queue manager *#
#*******************************************************************#
ExitPath:
   ExitsDefaultPath=/var/mqm/exits
   ExitsDefaultPath64=/var/mqm/exits64
Log:
   LogPrimaryFiles=16
   LogSecondaryFiles=16
   LogFilePages=16384
   LogType=CIRCULAR
   LogBufferPages=512
   LogPath=$2/$3/
   LogWriteIntegrity=TripleWrite
Service:
   Name=AuthorizationService
   EntryPoints=14
ServiceComponent:
   Service=AuthorizationService
   Name=MQSeries.UNIX.auth.service
   Module=amqzfu
   ComponentDataSize=0
Channels:
   MQIBindType=FASTPATH
   MaxActiveChannels=5000
   MaxChannels=5000
TuningParameters:
   DefaultPQBufferSize=10485760
   DefaultQBufferSize=10485760
EOF
   
	echo "<------"
}

#############################################
# CreateQueueManager
#
# Parameters
# 1 - Queue Manager name
# 2 - Queue Manager listener port
# 3 - Queue Manager data file path
# 4 - Queue Manager log file path
#############################################
CreateQueueManager() {
	echo "------> This function creates queue manager $1 and all queues"
	MY_SUDO="sudo -u $SUDO_USER"

	echo "--- Stopping existing queue manager first: $1"
	# if this returns error we ignore this as QM may not even exist
	$MY_SUDO endmqm -i $1 | true

	echo "--- Deleting existing queue manager: $1"
	# if this returns error we ignore this as QM may not even exist
	$MY_SUDO dltmqm $1 | true

	echo "--- Creating directories for the new queue manager: $1"
	# will ignore the case if those directories already exist
	$MY_SUDO mkdir $3 | true
	$MY_SUDO chmod -R g+rwx $3
	$MY_SUDO mkdir $4 | true
	$MY_SUDO chmod -R g+rwx $4

	echo "--- Creating new queue manager: $1"
	CREATE_COMMAND="$MY_SUDO crtmqm -q -u SYSTEM.DEAD.LETTER.QUEUE -h $MAX_HANDLES -lc -ld $4 -lf $LOG_FILE_PAGES -lp $LOG_PRIMARY_FILES -md $3 $1"

	echo $CREATE_COMMAND
	$CREATE_COMMAND

	echo "--- Reset default values for the queue manager: $1"
	$MY_SUDO strmqm -c $1

	echo "--- Generating qm.ini file"
	INI_TMP=qm.ini.tmp
	CreateQueueManagerIniFile $INI_TMP $4 $1

	echo "--- Copy new configuration over the one that was created by defaults"
	$MY_SUDO cp $INI_TMP $3/$1/qm.ini
	rm $INI_TMP

	echo "--- Starting queue manager: $1"
	$MY_SUDO strmqm $1

	echo "--- Create queues and configure queue manager: $1"
	# read more about security settings here: http://www-01.ibm.com/support/docview.wss?uid=swg21577137
	# and here: http://stackoverflow.com/questions/8886627/websphere-mq-7-1-help-need-access-or-security/8886813#8886813

	$MY_SUDO runmqsc $1 <<-EOF
		define qlocal($REQUESTQ) maxdepth(5000)
		define qlocal($REPLYQ) maxdepth(5000)
		alter qmgr chlauth(disabled) 
		alter qmgr maxmsgl(104857600)
		alter channel(system.def.svrconn) chltype(svrconn) mcauser($SUDO_USER) maxmsgl(104857600)
		alter qlocal(system.default.local.queue) maxmsgl(104857600)
		alter qmodel(system.default.model.queue) maxmsgl(104857600)
		define listener(L1) trptype(tcp) port($2) control(qmgr)
		start listener(L1)
		alter channel(SYSTEM.DEF.SVRCONN) chltype(SVRCONN) sharecnv(1)
		define channel(system.admin.svrconn) chltype(svrconn) mcauser('mqm') replace
EOF

	echo "--- Restart queue manager: $1"
	$MY_SUDO endmqm -i $1
	$MY_SUDO strmqm $1

	echo "<------ DONE with SUCCESS - creation of queue manager went well: $1"
}

#############################################
# CheckExistingWMQinstall
# This function tests if there is existing WMQ install in the $1
#
# Parameters
# 1 - path to the presumed WMQ install
#############################################
CheckExistingWMQinstall() {
	# First we check for existing WMQ directory
	if [ -d "$WMQ_INSTALL_DIR" ]; then
		echo "ERROR: There is already an '$WMQ_INSTALL_DIR' directory on your file system. If you want to install new copy of WMQ you have these choices:"
		echo "       (1) Rename that directory or (2) Edit *setenv.sh* file to point variable *WMQ_INSTALL_DIR* to a different location."
		echo ""
		exit 1
	fi
	
	# Second we check if WMQ rpms are already on the system.
	# TODO - we could allow to install multiple WMQ rpms on the system, but that would be future item. 
	# For now just abort if we have any existing WMQ rpms
	# grep returns code 0 if string was found at least once
		
	echo "Checking for existing WMQ rpms on this machine..."
	echo ""
	
	# 0 means found, 1 not found, 2 - file does not exist
	if rpm -qa | grep MQSeries 
	then
		echo ""
		echo "ERROR: There is already an WMQ install on this system."
		echo "       At present time this script does not handle multiple installations of WMQ on the same host."
		echo "       However you can easily add this function yourself. Exiting now."
		echo ""
		exit 1
	else
		echo "No existing installation of WMQ found on the system. Proceeding with the installation..."
	fi

	# TODO - may want to do some more check, other than simply checking for existing directory
}

#############################################
# InstallWMQ
#############################################
InstallWMQ() {
	echo "------> This function installs WMQ "
	mkdir $DOWNLOAD_PATH/wmq_install_unzipped | true
	cd $DOWNLOAD_PATH/wmq_install_unzipped
	tar xvf $DOWNLOAD_PATH/$WMQ_ARCHIVE
	
	# Accept IBM license
	./mqlicense.sh -accept

	# Now we can install WMQ	
	sudo rpm --prefix $WMQ_INSTALL_DIR -ivh MQSeriesRuntime-*.rpm MQSeriesServer-*.rpm MQSeriesClient-*.rpm MQSeriesSDK-*.rpm  MQSeriesMan-*.rpm MQSeriesSamples-*.rpm MQSeriesJRE-*.rpm MQSeriesExplorer-*.rpm MQSeriesJava-*.rpm
			   
	# Define this as a primary installation
	$WMQ_INSTALL_DIR/bin/setmqinst -i -p $WMQ_INSTALL_DIR

	# Show the version of WMQ that we just installed
	$WMQ_INSTALL_DIR/bin/dspmqver

	# Finally need to run check of prerequisites and see if any of the checks fail (Warnings exit=1, Errors exit=2)
	#su mqm -c "$WMQ_INSTALL_DIR/bin/mqconfig"
	#su $SUDO_USER -c "$WMQ_INSTALL_DIR/bin/mqconfig"

	echo "<------ DONE with SUCCESS - installation of WMQ is complete at the following path: $WMQ_INSTALL_DIR"
}

#############################################
# MAIN BODY starts here
#############################################
echo ""
echo "------------------------------------------------------------------------------"
echo " This script will install WebSphere MQ on your Linux OS"
echo " Read more about this script here: http://WhyWebSphere.com"
echo " Today's date: `date`"
echo " Here are the default values used in the script (feel free to change these):"
echo "   Insalling user:            '$SUDO_USER'"
echo "   WebSphere MQ Install Path: '$WMQ_INSTALL_DIR'"
echo "   Queue Manager Name:        '$QM'"
echo "   Queue Mgr Listener Port:   '$PORT'"
echo "   Queue Mgr Data Path:       '$QM_DATA_PATH'"
echo "   Queue Mgr Log Path:        '$QM_LOG_PATH'"
echo "   Test Queue #1:             '$REQUESTQ'"
echo "   Test Queue #2:             '$REPLYQ'"
echo "   WMQ installation image:    '$DOWNLOAD_PATH/$WMQ_ARCHIVE'"
echo "------------------------------------------------------------------------------"
echo ""

# Make sure there is not already existing WMQ install in the install directory
CheckExistingWMQinstall

# Define Linux kernel parameters before installing WMQ
UpdateSysctl

# Add mqm user and set ulimits
AddMQMuser
	
# Install WMQ
InstallWMQ

# Define first instance of queue manager (repeat these lines if you need multiple QMs)
CreateQueueManager $QM $PORT $QM_DATA_PATH $QM_LOG_PATH

# Start WMQ Explorer to manage the installation
$WMQ_INSTALL_DIR/bin/strmqcfg &

echo "-------------------------------------------------------------------------------"
echo " SUCCESS: WMQ installation, setup and test are complete."
echo " To test your message queues you may want to run this script: ./mqtest.sh"
echo "-------------------------------------------------------------------------------"

