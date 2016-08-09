# OpenUnisonS2IDocker

This image is the base "builder" image for OpenUnison.  Its a hardened version of Tomcat 8 with TLS configured and the extra web applications removed.  This provides an easy mechanism for deploying OpenUnison into a generic Docker environment or OpenShift.

## What is OpenUnison?

OpenUnison is an open source identity management solution from Tremolo Security (https://www.tremolosecurity.com/) that provides:

* Web Access Management (WAM)
* SSO (Single Sign-On/Simplified Sign-On)
* Workflow based user provisioning
* User self service portal
* Reporting
* Identity Provider

Documentation is available at https://www.tremolosecurity.com/documentation/

## Deployment Options

Since this image is assumed to work with S2I there are three inputs that can be given to the s2i script:

1. A directory containing the OpenUnison war file
2. A directory containing a maven project to build an OpenUnison deployment
3. A git URL to a repository containing a maven project to build an OpenUnison deployment

Some assumptions are made about the deployment, each of which is covered in detail in the next section:

1. The OpenUnison keystore is stored OUTSIDE of the final image in a volume (or secret for Kubernetes or OpenShift)
2. Environment variables are used for passwords, server names, connections strings, etc

## Configuring OpenUnison

### Quick Starts

There are a number of quick starts available in the Tremolo Security guthub repositories - https://github.com/tremolosecurity?utf8=%E2%9C%93&query=openunison-qs.  Each one has its own set of environment variables and pre-requisites.  The rest of this tutorial assumes using the openunison-qs-s2i project.  

### Setup Your Project

First, fork the quick start you are planning to work off of then clone it locally:

```bash
$ git clone https://github.com/myusername/openunison-qs-s2i.git
$ mkdir local
```

### Create the OpenUnison Keystore

Make sure not to create your keystore inside of the git repository.  From the top directory in your project
```bash
$ cd local
$ keytool -genseckey -alias session-unison -keyalg AES -keysize 256 -storetype JCEKS -keystore ./unisonKeyStore.jks
$ keytool -genkeypair -storetype JCEKS -alias unison-tls -keyalg RSA -keysize 2048 -sigalg SHA256withRSA -keystore ./unisonKeyStore.jks
```

## Deploy OpenUnison with s2i

1.  Download the S2I binary for your platform and add it to your path - https://github.com/openshift/source-to-image/releases
2.  Pull the S2I scripts from GitHub - "git clone https://github.com/TremoloSecurity/OpenUnisonS2I.git"
3.  Go into the cloned repo, and build the image

```bash
$ s2i  build /path/to/my/root/myproject tremolosecurity/openunisons2idocker  local/openunison
```

This will create an image in your local Docker service called local/openunison with your OpenUnison configuration.  Finally, launch the image.

```bash
$ docker run -ti -p 443:8443 -p 80:8080 -e OU_HOST=ou.myapp.com -e TEST_USER_NAME=testuser -e TEST_USER_PASSWORD=secret -e JAVA_OPTS='-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom -DunisonKeystorePassword=PasswordForTheKeystore' -v /path/to/project/local:/etc/openunison --name openunison local/openunison
```

If everything goes as planned, OpenUnison will be running.  You'll be able to access OpenUnison by visiting https://ou.myapp.com/ with the username testuser and the password secret.
