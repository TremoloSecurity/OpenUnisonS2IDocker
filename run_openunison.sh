#!/bin/bash

export OPENUNISON_DIR=/usr/local/openunison
export OPENUNISON_WORK=$OPENUNISON_DIR/work

#OpenShift really doesn't like writing outside of tmp
mkdir /tmp/quartz
mkdir /tmp/amq
export CLASSPATH="$OPENUNISON_WORK/lib/*:$OPENUNISON_WORK/classes:/tmp/quartz"
echo $CLASSPATH
java -classpath $CLASSPATH $JAVA_OPTS com.tremolosecurity.openunison.undertow.OpenUnisonOnUndertow /etc/openunison/openunison.yaml
