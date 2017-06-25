#!/bin/bash

if [ $OPENUNISON_KEYSTORE_PASSWORD ]; then
  export CATALINA_OPTS="$CATALINA_OPTS -DunisonKeystorePassword=$OPENUNISON_KEYSTORE_PASSWORD"
fi

mkdir -p /tmp/quartz

#create server.xml
/usr/local/tomcat/bin/eval_secrets.py /etc/openunison/ou.env /usr/local/tomcat/conf/server_template.xml > /usr/local/tomcat/conf/server.xml


/usr/local/tomcat/bin/catalina.sh run
