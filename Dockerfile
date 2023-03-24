ARG BASE_REGISTRY
ARG BASE_REPO="arkcase/base"
ARG BASE_TAG="8.7.0"
ARG ARCH="amd64"
ARG OS="linux"
ARG VER="5.17.1"
ARG PKG="alfresco-activemq"
ARG AMQ_VER="${VER}-jre11-rockylinux8"
ARG ALFRESCO_SRC="alfresco/alfresco-activemq"
ARG APP_USER="amq"
ARG APP_UID="33031"
ARG APP_GROUP="alfresco"
ARG APP_GID="1000"

# Used to copy artifacts
FROM "${ALFRESCO_SRC}:${AMQ_VER}" AS alfresco-src

ARG BASE_REGISTRY
ARG BASE_REPO
ARG BASE_TAG

# Final Image
FROM "${BASE_REGISTRY}/${BASE_REPO}:${BASE_TAG}"

ARG ARCH
ARG OS
ARG VER
ARG PKG
ARG ALFRESCO_SRC
ARG APP_USER
ARG APP_UID
ARG APP_GROUP
ARG APP_GID
ARG AMQ_HOME="/opt/activemq"

# Root's Environment
ENV JAVA_HOME="/usr/lib/jvm/jre-11-openjdk" \
    JAVA_MAJOR="11" \
    CATALINA_HOME="/usr/local/tomcat" \
    TOMCAT_NATIVE_LIBDIR="${CATALINA_HOME}/native-jni-lib" \
    LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}$TOMCAT_NATIVE_LIBDIR" \
    PATH="${CATALINA_HOME}/bin:${PATH}" \
    AMQ_HOME="${AMQ_HOME}" \
    ACTIVEMQ_BASE="${AMQ_HOME}" \
    ACTIVEMQ_CONF="${AMQ_HOME}/conf "\
    ACTIVEMQ_DATA="${AMQ_HOME}/data" \
    LC_ALL="C" \
    VER="${VER}"

ARG DOWNLOAD_URL="https://archive.apache.org/dist/activemq/${VER}/apache-activemq-${VER}-bin.tar.gz" \
    DOWNLOAD_ASC_URL="https://archive.apache.org/dist/activemq/${VER}/apache-activemq-${VER}-bin.tar.gz.asc" \
    DOWNLOAD_KEYS_URL="https://downloads.apache.org/activemq/KEYS"

RUN yum -y update && \
    yum -y install \
        java-${JAVA_MAJOR}-openjdk-devel && \
    yum -y clean all && \
    curl "${DOWNLOAD_URL}" -so "/tmp/activemq.tar.gz" && \
    curl "${DOWNLOAD_ASC_URL}" -so "/tmp/activemq.tar.gz.asc" && \
    curl "${DOWNLOAD_KEYS_URL}" -so "/tmp/KEYS" && \
    gpg --import "/tmp/KEYS" && \
    gpg --verify "/tmp/activemq.tar.gz.asc" "/tmp/activemq.tar.gz" && \
    tar -xzf "/tmp/activemq.tar.gz" -C /tmp && \
    mv "/tmp/apache-activemq-${VER}" "${AMQ_HOME}" && \
    rm -rf "/tmp/activemq.tar.gz" "/tmp/activemq.tar.gz.asc" "/tmp/KEYS" && \
    mkdir -p "${AMQ_HOME}/data" "/var/log/activemq" && \
    groupadd -g "${APP_GID}" "${APP_GROUP}" && \
    useradd -u "${APP_UID}" -g "${APP_GROUP}" "${APP_USER}" && \
    chown -R "${APP_USER}:${APP_GROUP}" "${AMQ_HOME}" && \
    chown "${APP_USER}:${APP_GROUP}" "${ACTIVEMQ_DATA}/activemq.log" && \
    chmod g+rwx "${ACTIVEMQ_DATA}"

WORKDIR "${AMQ_HOME}"
COPY --from=alfresco-src "${AMQ_HOME}/init.sh" "${AMQ_HOME}/init.sh"
COPY entrypoint /entrypoint
RUN chmod 0755 "${AMQ_HOME}/init.sh" "/entrypoint"

USER "${APP_USER}"

# ${APP_USER}'s Environment
ENV JAVA_HOME="/usr/lib/jvm/jre-11-openjdk" \
    JAVA_MAJOR="11" \
    CATALINA_HOME="/usr/local/tomcat" \
    TOMCAT_NATIVE_LIBDIR="${CATALINA_HOME}/native-jni-lib" \
    LD_LIBRARY_PATH="${LD_LIBRARY_PATH:+${LD_LIBRARY_PATH}:}${TOMCAT_NATIVE_LIBDIR}" \
    PATH="${CATALINA_HOME}/bin:${PATH}" \
    AMQ_HOME="${AMQ_HOME}" \
    ACTIVEMQ_BASE="${AMQ_HOME}" \
    ACTIVEMQ_CONF="${AMQ_HOME}/conf" \
    ACTIVEMQ_DATA="${AMQ_HOME}/data" \
    LC_ALL="C" \
    VER="${VER}"

VOLUME [ "${AMQ_HOME}/conf" ]
VOLUME [ "${AMQ_HOME}/data" ]
VOLUME [ "/var/log/activemq" ]

EXPOSE 8161/tcp 61616/tcp 5672/tcp 61613/tcp
ENTRYPOINT [ "/entrypoint" ]
