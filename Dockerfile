FROM quay.io/keycloak/keycloak:19.0.1@sha256:b8dd5185ed3856488d127fe419a2593c675f1dc6c7e1e0977234f3b0cc13598f as builder

ENV KC_DB=mysql
ENV KC_HEALTH_ENABLED=true
#JDBC-PING cluster setup
ENV KC_CACHE_CONFIG_FILE=cache-ispn-jdbc-ping.xml
COPY ./cache-ispn-jdbc-ping.xml /opt/keycloak/conf/cache-ispn-jdbc-ping.xml
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:19.0.1@sha256:b8dd5185ed3856488d127fe419a2593c675f1dc6c7e1e0977234f3b0cc13598f
COPY --from=builder /opt/keycloak/lib/quarkus/ /opt/keycloak/lib/quarkus/
COPY --from=builder /opt/keycloak/conf/cache-ispn-jdbc-ping.xml /opt/keycloak/conf
WORKDIR /opt/keycloak
USER keycloak

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]