ARG KEYCLOAK_VERSION=19.0.1

FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION} as build

# Configure a database vendor
ENV DB_VENDOR=mysql

# specify the custom cache config file here
ENV KC_CACHE_CONFIG_FILE=cache-ispn-jdbc-ping.xml

# copy the custom cache config file into the keycloak conf dir
COPY ./cache-ispn-jdbc-ping.xml /opt/keycloak/conf/cache-ispn-jdbc-ping.xml

RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION}
COPY --from=build /opt/keycloak/lib/quarkus/ /opt/keycloak/lib/quarkus/
COPY --from=build /opt/keycloak/conf/cache-ispn-jdbc-ping.xml /opt/keycloak/conf
WORKDIR /opt/keycloak

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]