FROM quay.io/keycloak/keycloak:20.0.1 as builder

#JDBC-PING cluster setup
ENV KC_CACHE_CONFIG_FILE=cache-ispn-jdbc-ping.xml
COPY ./cache-ispn-jdbc-ping.xml /opt/keycloak/conf/cache-ispn-jdbc-ping.xml
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:20.0.1
COPY --from=builder /opt/keycloak/lib/quarkus/ /opt/keycloak/lib/quarkus/
COPY --from=builder /opt/keycloak/conf/cache-ispn-jdbc-ping.xml /opt/keycloak/conf
WORKDIR /opt/keycloak

RUN export JGROUPS_DISCOVERY_EXTERNAL_IP=$(curl -fs "${ECS_CONTAINER_METADATA_URI_V4}" | jq -r '.Networks[0].IPv4Addresses[0]')

EXPOSE 8080 7600

ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]