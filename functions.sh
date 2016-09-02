#!/bin/bash

# Shell functions for unix. This file is intended to be sourced by other scripts.
# Courtesy of the IBM Hursley Lab.

ECHON=${ECHON-echo}
me=$(basename $0)

##############################################################################
# regexify
##############################################################################
# Convert a string to a regular expression that matches only the given string.
#
# Parameters
# 1 - The string to convert
##############################################################################
regexify() {
	# Won't work on HPUX
	echo $1 | sed -r 's/([][\.\-\+\$\^\\\?\*\{\}\(\)\:])/\\\1/g'
}

###############################################
# delAndAppend
###############################################
# Delete a line containing a REGEX from a file,
# then append a new line.
#
# Parameters
# 1 - The REGEX to search for and delete
# 2 - The line to append
# 3 - The file to edit
###############################################
delAndAppend() {
	echo "Updating entry in $3: $2"
	awk '{if($0!~/^[[:space:]]*'$1'/) print $0}' $3 > $3.new
	mv $3.new $3
	echo "$2" >> $3
}

###################################################
# backupFile
###################################################
# Copy the given file to a file with the same path,
# but a timestamp appended to the name.
#
# Parameters
# 1 - The name of the file to backup
###################################################
backupFile() {
	cp $1 $1.`date +%Y-%m-%d.%H%M`
}

#############################################
# updateSysctl
# Update values in the /etc/sysctl.conf file.
#
# Parameters
# 1 - The value to update
# 2 - The new value
#############################################
updateSysctl() {
	delAndAppend `regexify $1` "$1 = $2" /etc/sysctl.conf
}

#############################################
# UpdateSysctl
# Update values in the /etc/sysctl.conf file.
#
# Parameters
# 	none
#############################################
UpdateSysctl() {
# First we need to make a backup of existing kernel settings before we change anything
backupFile /etc/sysctl.conf

# Now can set some new values
# System tuning (sysctl)
echo "" >> /etc/sysctl.conf
echo "# The following values were changed by $me [`date`]." >> /etc/sysctl.conf

# The maximum number of file-handles that can be held concurrently
updateSysctl fs.file-max $FDMAX

# The maximum and minimum port numbers that can be allocated to outgoing connections
updateSysctl net.ipv4.ip_local_port_range '1024 65535'

# From what I can gather, this is the maximum number of disjoint (non-contiguous),
# sections of memory a single process can hold (i.e. through calls to malloc).
# This doesn't mean that a process can have no more variables than this,
# but performance may become degraded if this the number of variables exceeds this value,
# as the OS has to search for memory space adjacent to an existing malloc.
# This is my best interpretation of stuff written on the internet; it could be completely wrong!
#   - Rowan (10/10/2013)
updateSysctl vm.max_map_count 1966080

# The maximum PID value. When the PID counter exceeds this, it wraps back to zero.
updateSysctl kernel.pid_max 4194303

# Tunes IPC semaphores. Values are:
#  1 - The maximum number of semaphores per set
#  2 - The system-wide maximum number of semaphores
#  3 - The maximum number of operations that may be specified in a call to semop(2)
#  4 - The system-wide maximum number of semaphore identifiers 
updateSysctl kernel.sem '1000 1024000 500 8192'

# The maximum size (in bytes) of an IPC message queue
updateSysctl kernel.msgmnb  131072

# The maximum size (in bytes) of a single message on an IPC message queue
updateSysctl kernel.msgmax  131072

# The maximum number of IPC message queues
updateSysctl kernel.msgmni  2048

# The maximum number of shared memory segments that can be created
updateSysctl kernel.shmmni  8192

# The maximum number of pages of shared memory
updateSysctl kernel.shmall  536870912

# The maximum size of a single shared memory segment
updateSysctl kernel.shmmax  137438953472

# TCP keep alive setting
updateSysctl net.ipv4.tcp_keepalive_time 300

echo "" >> /etc/sysctl.conf

# there is a bug in RHEL where bridge settings are set by default and they should not be, so we have to pass '-e' option here
# read more: https://bugzilla.redhat.com/show_bug.cgi?id=639821
sysctl -e -p
}
