% OpenUnison Builder (1) Container Image Pages
% Tremolo Security, Inc.
% June 25, 2017

# NAME
OpenUnison \- OpenUnison RHEL Builder Container

# DESCRIPTION

Tremolo Security's OpenUnison combines the identity management functions most needed by applications including:

* User Provisioning
* SSO
* Reporting
* Workflow

This image is a builder image, used to create OpenUnison from a war file or git repository.  

# USAGE

## Deployment

See https://github.com/TremoloSecurity/OpenUnisonS2IDocker/blob/master/README.md for details on how to deploy using this builder image

## Logging

The standard for Docker images is to send all output to standard out.  The default log4j2.xml file is updated to push all output to standard out.


# SECURITY IMPLICATIONS

OpenUnison runs unprivileged and without any ports below 1024.

# AUTHORS
Tremolo Security, Inc.
