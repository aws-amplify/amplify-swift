FROM swift:5.9.2-amazonlinux2

# Install Open SSL -- dependency of CRT
RUN yum -y install openssl-devel

## The rest of this file is from https://github.com/aws/aws-codebuild-docker-images/blob/master/al2/x86_64/standard/4.0/Dockerfile

# Install other utilities
RUN yum install -y -q \
  wget unzip

## Install Java

#****************      JAVA     ****************************************************

ENV JAVA_17_HOME="/usr/lib/jvm/java-17-amazon-corretto.x86_64" \
    JDK_17_HOME="/usr/lib/jvm/java-17-amazon-corretto.x86_64" \
    JRE_17_HOME="/usr/lib/jvm/java-17-amazon-corretto.x86_64" \
    ANT_VERSION=1.10.13 \
    MAVEN_HOME="/opt/maven" \
    MAVEN_VERSION=3.9.2 \
    INSTALLED_GRADLE_VERSIONS="7.6.1" \
    GRADLE_VERSION=7.6.1 \
    SBT_VERSION=1.8.3 \
    GRADLE_PATH="$SRC_DIR/gradle" \
    ANT_DOWNLOAD_SHA512="de4ac604629e39a86a306f0541adb3775596909ad92feb8b7de759b1b286417db24f557228737c8b902d6abf722d2ce5bb0c3baa3640cbeec3481e15ab1958c9" \
    MAVEN_DOWNLOAD_SHA512="900bdeeeae550d2d2b3920fe0e00e41b0069f32c019d566465015bdd1b3866395cbe016e22d95d25d51d3a5e614af2c83ec9b282d73309f644859bbad08b63db" \
    GRADLE_DOWNLOADS_SHA256="518a863631feb7452b8f1b3dc2aaee5f388355cc3421bbd0275fbeadd77e84b2 7.6.1" \
    SBT_DOWNLOAD_SHA256="21F4210786FD68FD15DCA3F4C8EE9CAE0DB249C54E1B0EF6E829E9FA4936423A" \
    LOG4J_UNSAFE_VERSIONS="2.11.1 1.2.8"

ARG MAVEN_CONFIG_HOME="/root/.m2"
ENV JAVA_HOME="$JAVA_17_HOME" \
    JDK_HOME="$JDK_17_HOME" \
    JRE_HOME="$JRE_17_HOME"

RUN set -x \
    # Install Amazon Corretto 17
    && rpm --import https://yum.corretto.aws/corretto.key \
    && curl -L -o /etc/yum.repos.d/corretto.repo https://yum.corretto.aws/corretto.repo \
    && yum install -y -q java-17-amazon-corretto java-17-amazon-corretto-devel \
    && update-ca-trust \
    && for tool_path in $JAVA_HOME/bin/*; do \
          tool=`basename $tool_path`; \
          update-alternatives --install /usr/bin/$tool $tool $tool_path 10000; \
          update-alternatives --set $tool $tool_path; \
        done \
    && rm $JAVA_HOME/lib/security/cacerts && ln -s /etc/pki/java/cacerts $JAVA_HOME/lib/security/cacerts \
    # Install Ant
    && curl -LSso /var/tmp/apache-ant-$ANT_VERSION-bin.tar.gz https://archive.apache.org/dist/ant/binaries/apache-ant-$ANT_VERSION-bin.tar.gz  \
    && echo "$ANT_DOWNLOAD_SHA512 /var/tmp/apache-ant-$ANT_VERSION-bin.tar.gz" | sha512sum -c - \
    && tar -xzf /var/tmp/apache-ant-$ANT_VERSION-bin.tar.gz -C /opt \
    && rm /var/tmp/apache-ant-$ANT_VERSION-bin.tar.gz \
    && update-alternatives --install /usr/bin/ant ant /opt/apache-ant-$ANT_VERSION/bin/ant 10000

RUN set -ex \
    # Install Maven
    && mkdir -p $MAVEN_HOME \
    && curl -LSso /var/tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz https://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    && echo "$MAVEN_DOWNLOAD_SHA512 /var/tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz" | sha512sum -c - \
    && tar xzf /var/tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz -C $MAVEN_HOME --strip-components=1 \
    && rm /var/tmp/apache-maven-$MAVEN_VERSION-bin.tar.gz \
    && update-alternatives --install /usr/bin/mvn mvn /opt/maven/bin/mvn 10000 \
    && mkdir -p $MAVEN_CONFIG_HOME \
    # Install Gradle
    && mkdir -p $GRADLE_PATH \
    && for version in $INSTALLED_GRADLE_VERSIONS; do { \
       wget -q "https://services.gradle.org/distributions/gradle-$version-all.zip" -O "$GRADLE_PATH/gradle-$version-all.zip" \
       && unzip -q "$GRADLE_PATH/gradle-$version-all.zip" -d /usr/local \
       && echo -e "$GRADLE_DOWNLOADS_SHA256" | grep "$version" | sed "s|$version|$GRADLE_PATH/gradle-$version-all.zip|" | sha256sum -c - \
       && rm "$GRADLE_PATH/gradle-$version-all.zip" \
       && mkdir "/tmp/gradle-$version" \
       && "/usr/local/gradle-$version/bin/gradle" -p "/tmp/gradle-$version" init \
       && "/usr/local/gradle-$version/bin/gradle" -p "/tmp/gradle-$version" wrapper \
       # Android Studio uses the "-all" distribution for it's wrapper script.
       && perl -pi -e "s/gradle-$version-bin.zip/gradle-$version-all.zip/" "/tmp/gradle-$version/gradle/wrapper/gradle-wrapper.properties" \
       && "/tmp/gradle-$version/gradlew" -p "/tmp/gradle-$version" init \
       && rm -rf "/tmp/gradle-$version" \
       && if [ "$version" != "$GRADLE_VERSION" ]; then rm -rf "/usr/local/gradle-$version"; fi; \
     }; done \
    # Install default GRADLE_VERSION to path
    && ln -s /usr/local/gradle-$GRADLE_VERSION/bin/gradle /usr/bin/gradle \
    && rm -rf $GRADLE_PATH \
    # Install SBT
    && curl -fSL "https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.tgz" -o sbt.tgz \
    && echo "${SBT_DOWNLOAD_SHA256} *sbt.tgz" | sha256sum -c - \
    && tar xzf sbt.tgz -C /usr/local/bin/ \
    && rm sbt.tgz \
    && for version in $LOG4J_UNSAFE_VERSIONS; do find / -name log4j*-$version.jar | xargs rm -f; done

ENV PATH "/usr/local/bin/sbt/bin:$PATH"
RUN sbt version -Dsbt.rootdir=true
# Cleanup
RUN rm -fr /tmp/* /var/tmp/*
#****************     END JAVA     ****************************************************

