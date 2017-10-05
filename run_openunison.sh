#!/bin/bash

export OPENUNISON_DIR=/usr/local/openunison
export OPENUNISON_WORK=$OPENUNISON_DIR/work

export CLASSPATH="$OPENUNISON_WORK/lib/*:$OPENUNISON_WORK/classes:$OPENUNISON_DIR/quartz"
echo $CLASSPATH
java -classpath $CLASSPATH $JAVA_OPTS com.tremolosecurity.openunison.undertow.OpenUnisonOnUndertow /etc/openunison/openunison.yaml
