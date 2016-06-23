#!/bin/bash

if [ $OPENUNISON_KEYSTORE_PASSWORD ]; then
  export CATALINA_OPTS="$CATALINA_OPTS -DunisonKeystorePassword=$OPENUNISON_KEYSTORE_PASSWORD"
fi
/usr/local/tomcat/bin/catalina.sh run
