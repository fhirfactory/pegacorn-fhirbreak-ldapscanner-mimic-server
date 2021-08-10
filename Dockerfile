FROM fhirfactory/pegacorn-base-docker-apacheds:1.0.0

# Define ApacheDS version
ENV APACHEDS_VERSION=2.0.0-M24
ENV APACHEDS_SERVICE_NAME=apacheds-${APACHEDS_VERSION}-default

# Add schema
COPY ldap/schema/ms-user.ldif /tmp/
COPY ldap/schema/ms-userproxy.ldif /tmp/
COPY ldap/schema/partition.ldif /tmp/

RUN \
    service ${APACHEDS_SERVICE_NAME} start && \
    timeout 30 sh -c "while ! nc -z localhost 10389; do sleep 1; done" && \
    service ${APACHEDS_SERVICE_NAME} status && \
    ldapmodify -v -x -h localhost -p 10389 -D uid=admin,ou=system -w secret -a -f /tmp/ms-user.ldif && \
    ldapmodify -v -x -h localhost -p 10389 -D uid=admin,ou=system -w secret -a -f /tmp/ms-userproxy.ldif && \
    ldapmodify -v -x -h localhost -p 10389 -D uid=admin,ou=system -w secret -a -f /tmp/partition.ldif && \
    service ${APACHEDS_SERVICE_NAME} stop

# TLS configuration
RUN mkdir -p /usr/local/apacheds
COPY run-apacheds.sh /usr/local/apacheds
RUN chmod -R 777 /usr/local/apacheds/run-apacheds.sh

ARG IMAGE_BUILD_TIMESTAMP
ENV IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}
RUN echo IMAGE_BUILD_TIMESTAMP=${IMAGE_BUILD_TIMESTAMP}

CMD ["/usr/local/apacheds/run-apacheds.sh"]

