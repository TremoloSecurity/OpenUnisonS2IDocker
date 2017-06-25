#!/usr/bin/python

import sys

env_vars = {}
content = ''

with open(sys.argv[1]) as f:
    for line in f:
        line = line[0:-1]
        name = line[0:line.find('=')]
        val = line[line.find('=') + 1:]
        env_vars[name] = val

with open(sys.argv[2]) as f:
    content = f.read()

#if not specified, we don't need TLS auth
if not 'TOMCAT_TLS_CLIENT_AUTH' in env_vars:
    env_vars['TOMCAT_TLS_CLIENT_AUTH'] = 'none'

done = False
start = 0
new_content = ''



while not done:
    next_var = content.find('#[',start)
    if next_var == -1:
        new_content += content[start:]
        done = True
    else:
        end_var = content.find(']',next_var)
        var_name = content[next_var+2:end_var]
        new_content = new_content + content[start:next_var] + env_vars[var_name]
        start = end_var + 1

print new_content
