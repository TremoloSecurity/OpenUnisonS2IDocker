#!/bin/python

import urllib2
import ssl

ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE


res = urllib2.urlopen("https://127.0.0.1:8443/check_alive",context=ctx).read()

if res.find('Anonymous') > 0:
    print "ok"
    exit(0)
else:
    print "failed"
    exit(1)
