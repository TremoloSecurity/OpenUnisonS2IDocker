# openunison-centos7
FROM centos:7

MAINTAINER Tremolo Security, Inc. - Docker <docker@tremolosecurity.com>

ENV BUILDER_VERSION=1.0 \
    JDK_VERSION=1.8.0 \
    TOMCAT_VERSION=8.0.35 \
    MAVEN_VERSION=3.3.9 \
    CATALINA_OPTS="-Xms512M -Xmx1024M -server -XX:+UseParallelGC" \
    JAVA_OPTS="-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom" \
    MYSQL_JDBC_VERSION=5.1.38

LABEL io.k8s.description="Platform for building Tremolo Security OpenUnison" \
      io.k8s.display-name="builder x.y.z" \
      io.openshift.expose-services="8080:8443:9090:9093" \
      io.openshift.tags="builder,x.y.z,etc." \
      io.openshift.s2i.scripts-url="file://.s2i/bin"

RUN yum install -y which tar java-${JDK_VERSION}-openjdk-devel.x86_64 net-tools.x86_64 && \
    yum clean all -y && \
    echo -e "\nInstalling Tomcat $TOMCAT_VERSION" && \
    curl -v http://www.apache.org/dist/tomcat/tomcat-8/v${TOMCAT_VERSION}/bin/apache-tomcat-${TOMCAT_VERSION}.tar.gz | tar -zx -C /usr/local && \
    ln -s /usr/local/apache-tomcat-${TOMCAT_VERSION} /usr/local/tomcat && \
    echo -e "\nInstalling Maven $MAVEN_VERSION" && \
    curl -v http://www.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz | tar -zx -C /usr/local && \
    ln -s /usr/local/apache-maven-${MAVEN_VERSION}/bin/mvn /usr/local/bin/mvn && \
    echo -e "\nGetting MySQL JDBC driver..." && \
    curl -L --create-dirs http://search.maven.org/remotecontent?filepath=mysql/mysql-connector-java/${MYSQL_JDBC_VERSION}/mysql-connector-java-${MYSQL_JDBC_VERSION}.jar -o /tmp/drivers/mysql-connector-java-${MYSQL_JDBC_VERSION}.jar && \
    mkdir -p /etc/openunison && \
    groupadd -r tremoloadmin -g 433 && \
    mkdir -p /usr/local/tremolo/tremolo-service && \
    useradd -u 431 -r -g tremoloadmin -d /usr/local/tremolo/tremolo-service -s /sbin/nologin -c "OpenUnison Docker image user" tremoloadmin

#COPY ./tomcat-conf/context.xml /usr/local/apache-tomcat-${TOMCAT_VERSION}/context.xml
ADD server.xml /usr/local/apache-tomcat-${TOMCAT_VERSION}/conf/

# TODO (optional): Copy the builder files into /opt/app-root
#COPY ./etc /etc/openunison

# TODO: Copy the S2I scripts to /usr/libexec/s2i, since openshift/base-centos7 image sets io.openshift.s2i.scripts-url label that way, or update that label
# COPY ./.s2i/bin/ /usr/libexec/s2i
COPY ./.s2i/bin/ /usr/local/bin/s2i

RUN chown -R tremoloadmin:tremoloadmin /usr/local/tremolo /etc/openunison /tmp/drivers /usr/local/apache-maven-$MAVEN_VERSION /usr/local/apache-tomcat-$TOMCAT_VERSION /usr/local/tomcat /usr/local/bin/mvn

USER 431

EXPOSE 8080
EXPOSE 8443

CMD ["usage"]
