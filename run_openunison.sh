#!/bin/bash

export OPENUNISON_DIR=/usr/local/openunison
export OPENUNISON_WORK=$OPENUNISON_DIR/work

echo "Creating $OPENUNISON_WORK"
mkdir -p $OPENUNISON_WORK/webapp
cp $OPENUNISON_DIR/war/openunison.war $OPENUNISON_WORK/webapp/
cd $OPENUNISON_WORK/webapp
unzip $(ls *.war) > /dev/null

rm -f $OPENUNISON_WORK/webapp/*.war
mv $OPENUNISON_WORK/webapp/WEB-INF/lib $OPENUNISON_WORK/
mv $OPENUNISON_WORK/webapp/WEB-INF/classes $OPENUNISON_WORK/
mkdir $OPENUNISON_WORK/logs

export CLASSPATH="$OPENUNISON_WORK/lib/*:$OPENUNISON_WORK/classes:$OPENUNISON_DIR/quartz"
echo $CLASSPATH
java -classpath $CLASSPATH $JAVA_OPTS com.tremolosecurity.openunison.undertow.OpenUnisonOnUndertow /etc/openunison/openunison.yaml
