#!/bin/bash
export WMQ_INSTALL_DIR=/opt/mqm
export LD_LIBRARY_PATH=$WMQ_INSTALL_DIR/java/lib64
export JAVA_HOME=$WMQ_INSTALL_DIR/java/jre64/jre
export PATH=$PATH:$WMQ_INSTALL_DIR/bin:$JAVA_HOME/bin
export QM=QM1
export PORT=1420
export REQUESTQ=REQUEST_Q
export REPLYQ=REPLY_Q

