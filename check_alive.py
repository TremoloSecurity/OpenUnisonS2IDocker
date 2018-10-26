#!/usr/bin/python

import urllib2
import ssl
import sys
ctx = ssl.create_default_context()
ctx.check_hostname = False
ctx.verify_mode = ssl.CERT_NONE

url_to_test = "https://127.0.0.1:8443/check_alive";
text_to_find = 'Anonymous'

if len(sys.argv) > 1:
    url_to_test = sys.argv[1];
    text_to_find = sys.argv[2];


res = urllib2.urlopen(url_to_test,context=ctx).read()

if res.find(text_to_find) > 0:
    print "ok"
    exit(0)
else:
    print "failed"
    exit(1)
