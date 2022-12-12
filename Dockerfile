FROM quay.io/keycloak/keycloak:20.0.1 as builder

ENV KC_CACHE_CONFIG_FILE=cache-ispn-jdbc-ping.xml
COPY ./cache-ispn-jdbc-ping.xml /opt/keycloak/conf/cache-ispn-jdbc-ping.xml
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:20.0.1
COPY --from=builder /opt/keycloak/ /opt/keycloak/

WORKDIR /opt/keycloak

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]