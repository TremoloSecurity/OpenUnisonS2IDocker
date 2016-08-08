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
Create the unison.xml file using the below template:

```xml

```
