# OpenUnisonS2IDocker

This image is the base "builder" image for OpenUnison.  Its a hardened version of Tomcat 8 with TLS configured and the extra web applications removed.  This provides an easy mechanism for deploying OpenUnison into a generic Docker environment or OpenShift.

## Deployment Options

Since this image is asusmed to work with S2I there are three inputs that can be given to the s2i script:

1. A directory containing the OpenUnison war file
2. A directory containing a maven project to build an OpenUnison deployment
3. A git URL to a repository containing a maven project to build an OpenUnison deployment

Some assumptions are made about the deployment, each of which is covered in detail in the next section:

1. The OpenUnison keystore is stored OUTSIDE of the final image in a volume (or secret for Kubernetes or OpenShift)
2. Environment variables are used for passwords, server names, connections strings, etc

## Configuring OpenUnison

When building your OpenUnison environment, there's a couple of variations between the standard maven based build process and the process for using the S2I image:

### Initialize the Maven Repository

First, create your base directory:

```bash
$ mkdir myproject
$ mkdir local
```

Next, create the maven project.  This is the same process as the OpenUnison documentation:

```bash
$ cd myproject
$ mvn archetype:generate -DgroupId=com.mycompany.openunison -DartifactId=openunison -DinteractiveMode=false -DarchetypeArtifactId=maven-archetype-webapp
$ rm openunison/src/main/webapp/index.jsp
$ rm openunison/src/main/webapp/WEB-INF/web.xml
```

Update the pom.xml file:

Add the Tremolo Security Nexus repository
```xml
<repositories>
  <repository>
    <id>Tremolo Security</id>
    <url>https://www.tremolosecurity.com/nexus/content/repositories/releases/</url>
  </repository>
</repositories>
```

Add the OpenUnison dependencies and remove the junit dependencies:
```xml
<dependencies>
  <dependency>
    <groupId>com.tremolosecurity.unison</groupId>
    <artifactId>open-unison-webapp</artifactId>
    <version>1.0.7</version>
    <type>war</type>
    <scope>runtime</scope>
  </dependency>
  <dependency>
    <groupId>com.tremolosecurity.unison</groupId>
    <artifactId>open-unison-webapp</artifactId>
    <version>1.0.7</version>
    <type>pom</type>
  </dependency>
</dependencies>
```

Finally, set the build section:
```xml
<build>
  <plugins>
    <plugin>
      <artifactId>maven-compiler-plugin</artifactId>
      <version>3.1</version>
      <configuration>
        <source>1.7</source>
        <target>1.7</target>
      </configuration>
    </plugin>
    <plugin>
      <groupId>org.apache.maven.plugins</groupId>
      <artifactId>maven-war-plugin</artifactId>
      <version>2.6</version>
      <configuration>
        <overlays>
          <overlay>
            <groupId>com.tremolosecurity.unison</groupId>
            <artifactId>open-unison-webapp</artifactId>
          </overlay>
        </overlays>
      </configuration>
    </plugin>
  </plugins>
</build>
```

### OpenUnison Configuration Files

Create myproject/src/main/META-INF/context.xml
```xml
<Context>
  <Environment name="unisonConfigPath" value="WEB-INF/unison.xml" type="java.lang.String"/>
  <Environment name="unisonServiceConfigPath" value="WEB-INF/unisonService.props" type="java.lang.String"/>
</Context>
```

Create myproject/src/main/WEB-INF/unisonService.props
```properties
# Redirect from http to https
com.tremolosecurity.openunison.forceToSSL=true

# The port on which Tomcat is configured to listen for http requests
com.tremolosecurity.openunison.openPort=8080

# The port on which Tomcat is configured to listen for https requests
com.tremolosecurity.openunison.securePort=8443

# The external port on which OpenUnison should listen for incoming requests
com.tremolosecurity.openunison.externalOpenPort=80

# The secured/encrypted external port on which OpenUnison should listen for incoming requests
com.tremolosecurity.openunison.externalSecurePort=443

#Uncomment and set for production deployments
#com.tremolosecurity.openunison.activemqdir=/var/lib/unison-activemq
```
Create the myproject/src/main/webapp/WEB-INF/unison.xml file using the below template.  Note that external environment variables are being referenced with a #[] around them.
```xml
<?xml version="1.0" encoding="UTF-8"?>
<tremoloConfig xmlns="http://www.tremolosecurity.com/tremoloConfig" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.tremolosecurity.com/tremoloConfig tremoloConfig.xsd">
  <applications openSessionCookieName="openSession" openSessionTimeout="9000">
    <application name="LoginTest" azTimeoutMillis="30000" >
      <urls>
        <!-- The regex attribute defines if the proxyTo tag should be interpreted with a regex or not -->
        <!-- The authChain attribute should be the name of an authChain -->
        <url regex="false" authChain="formloginFilter" overrideHost="true" overrideReferer="true">
          <!-- Any number of host tags may be specified to allow for an application to work on multiple hosts.  Additionally an asterick (*) can be specified to make this URL available for ALL hosts -->
          <host>#[OU_HOST]</host>
          <!-- The filterChain allows for transformations of the request such as manipulating attributes and injecting headers -->
          <filterChain>
            <filter class="com.tremolosecurity.prelude.filters.LoginTest">
              <!-- The path of the logout URI           -->
              <param name="logoutURI" value="/logout"/>
            </filter>
          </filterChain>
          <!-- The URI (aka path) of this URL -->
          <uri>/</uri>
          <!-- Tells OpenUnison how to reach the downstream application.  The ${} lets you set any request variable into the URI, but most of the time ${fullURI} is sufficient -->
          <proxyTo>http://dnm${fullURI}</proxyTo>
          <!-- List the various results that should happen -->
          <results>
            <azSuccess>
            </azSuccess>
          </results>
          <!-- Determine if the currently logged in user may access the resource.  If ANY rule succeeds, the authorization succeeds.
          The scope may be one of group, dn, filter, dynamicGroup or custom
          The constraint identifies what needs to be satisfied for the authorization to pass and is dependent on the scope:
            * group - The DN of the group in OpenUnison's virtual directory (must be an instance of groupOfUniqueNames)
            * dn - The base DN of the user or users in OpenUnison's virtual directory
            * dynamicGroup - The DN of the dynamic group in OpenUnison's virtual directory (must be an instance of groupOfUrls)
            * custom - An implementation of com.tremolosecurity.proxy.az.CustomAuthorization -->
          <azRules>
            <rule scope="dn" constraint="o=Tremolo" />
          </azRules>
        </url>
        <url regex="false" authChain="formloginFilter" overrideHost="true" overrideReferer="true">
          <!-- Any number of host tags may be specified to allow for an application to work on multiple hosts.  Additionally an asterick (*) can be specified to make this URL available for ALL hosts -->
          <host>#[OU_HOST]</host>
          <!-- The filterChain allows for transformations of the request such as manipulating attributes and injecting headers -->
          <filterChain>
            <filter class="com.tremolosecurity.prelude.filters.StopProcessing" />
          </filterChain>
          <!-- The URI (aka path) of this URL -->
          <uri>/logout</uri>
          <!-- Tells OpenUnison how to reach the downstream application.  The ${} lets you set any request variable into the URI, but most of the time ${fullURI} is sufficient -->
          <proxyTo>http://dnm${fullURI}</proxyTo>
          <!-- List the various results that should happen -->
          <results>
            <azSuccess>Logout</azSuccess>
          </results>
          <!-- Determine if the currently logged in user may access the resource.  If ANY rule succeeds, the authorization succeeds.
                    The scope may be one of group, dn, filter, dynamicGroup or custom
                    The constraint identifies what needs to be satisfied for the authorization to pass and is dependent on the scope:
                      * group - The DN of the group in OpenUnison's virtual directory (must be an instance of groupOfUniqueNames)
                      * dn - The base DN of the user or users in OpenUnison's virtual directory
                      * dynamicGroup - The DN of the dynamic group in OpenUnison's virtual directory (must be an instance of groupOfUrls)
                      * custom - An implementation of com.tremolosecurity.proxy.az.CustomAuthorization -->
          <azRules>
            <rule scope="dn" constraint="o=Tremolo" />
          </azRules>
        </url>
      </urls>
      <!-- The cookie configuration determines how sessions are managed for this application -->
      <cookieConfig>
        <!-- The name of the session cookie for this application.  Applications that want SSO between them should have the same cookie name -->
        <sessionCookieName>tremolosession</sessionCookieName>
        <!-- The domain of component of the cookie -->
        <domain>#[OU_HOST]</domain>
        <!-- The URL that OpenUnison will interpret as the URL to end the session -->
        <logoutURI>/logout</logoutURI>
        <!-- The name of the AES-256 key in the keystore to use to encrypt this session -->
        <keyAlias>session-unison</keyAlias>
        <!-- If set to true, the cookie's secure flag is set to true and the browser will only send this cookie over https connections -->
        <secure>false</secure>
        <!-- The number of secconds that the session should be allowed to be idle before no longer being valid -->
        <timeout>900</timeout>
        <!-- required but ignored -->
        <scope>-1</scope>
      </cookieConfig>
    </application>
  </applications>
  <myvdConfig>WEB-INF/myvd.conf</myvdConfig>
  <authMechs>
    <mechanism name="loginForm">
      <uri>/auth/formLogin</uri>
      <className>com.tremolosecurity.proxy.auth.FormLoginAuthMech</className>
      <init>
      </init>
      <params>
        <param>FORMLOGIN_JSP</param>
      </params>
    </mechanism>
    <mechanism name="anonymous">
      <uri>/auth/anon</uri>
      <className>com.tremolosecurity.proxy.auth.AnonAuth</className>
      <init>
        <!-- The RDN of unauthenticated users -->
        <param name="userName" value="uid=Anonymous"/>
        <!-- Any number of attributes can be added to the anonymous user -->
        <param name="role" value="Users" />
      </init>
      <params>
      </params>
    </mechanism>
  </authMechs>
  <authChains>
    <!-- An anonymous authentication chain MUST be level 0 -->
    <chain name="anon" level="0">
      <authMech>
        <name>anonymous</name>
        <required>required</required>
        <params>
        </params>
      </authMech>
    </chain>
    <chain name="formloginFilter" level="1">
      <authMech>
        <name>loginForm</name>
        <required>required</required>
        <params>
          <!-- Path to the login form -->
          <param name="FORMLOGIN_JSP" value="/auth/forms/defaultForm.jsp"/>
          <!-- Either an attribute name OR an ldap filter mapping the form parameters. If this is an ldap filter, form parameters are identified by ${parameter} -->
          <param name="uidAttr" value="uid"/>
          <!-- If true, the user is determined based on an LDAP filter rather than a simple user lookup -->
          <param name="uidIsFilter" value="false"/>
        </params>
      </authMech>
    </chain>
  </authChains>
  <resultGroups>
    <!-- The name attribute is how the resultGroup is referenced in the URL -->
    <resultGroup name="Logout">
      <!-- Each result should be listed -->
      <result>
        <!-- The type of result, one of cookie, header or redirect -->
        <type>redirect</type>
        <!-- The source of the result value, one of user, static, custom -->
        <source>static</source>
        <!-- Name of the resuler (in this case a cookie) and the value -->
        <value>/auth/forms/logout.jsp</value>
      </result>
    </resultGroup>
  </resultGroups>
  <keyStorePath>/etc/openunison/unisonKeyStore.jks</keyStorePath>
  <keyStorePassword>#[unisonKeystorePassword]</keyStorePassword>
  </tremoloConfig>
```
Finally, create myproject/src/main/webapps/WEB-INF/myvd.conf.  Just as with the unison.xml file, environment variables can be put into #[] to be referenced.

```properties
#Global AuthMechConfig
server.globalChain=

server.nameSpaces=rootdse,myvdroot,testuser
server.rootdse.chain=dse
server.rootdse.nameSpace=
server.rootdse.weight=0
server.rootdse.dse.className=net.sourceforge.myvd.inserts.RootDSE
server.rootdse.dse.config.namingContexts=o=Tremolo
server.myvdroot.chain=root
server.myvdroot.nameSpace=o=Tremolo
server.myvdroot.weight=0
server.myvdroot.root.className=net.sourceforge.myvd.inserts.RootObject

server.testuser.chain=admin
server.testuser.nameSpace=ou=testuser,o=Tremolo
server.testuser.weight=0
server.testuser.admin.className=com.tremolosecurity.proxy.myvd.inserts.admin.AdminInsert
server.testuser.admin.config.uid=#[TEST_USER_NAME]
server.testuser.admin.config.password=#[TEST_USER_PASSWORD]
```

### Create the OpenUnison Keystore

From the top directory in your project
```bash
$ cd local
$ keytool -genseckey -alias session-unison -keyalg AES -keysize 256 -storetype JCEKS -keystore ./unisonKeyStore.jks
$ keytool -genkeypair -storetype JCEKS -alias unison-tls -keyalg RSA -keysize 2048 -sigalg SHA256withRSA -keystore ./unisonKeyStore.jks
```

## Deploy OpenUnison with s2i

1.  Download the S2I brinary for your platform and add it to your path - 
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
