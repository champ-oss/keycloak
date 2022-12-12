FROM public.ecr.aws/docker/library/maven:3.8.4-openjdk-17-slim as maven-builder

COPY native-s3-ping/pom.xml ./

RUN mvn package

FROM quay.io/keycloak/keycloak:20.0.1 as build

COPY --from=build --chown=keycloak target/s3-native-ping-bundle-*-jar-with-dependencies.jar /opt/keycloak/providers/

ENV KC_METRICS_ENABLED=true \
    KC_DB=mysql \
    KC_CACHE=ispn \
    KC_CACHE_STACK=ec2

RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:20.0.1
COPY --from=keycloak-builder /opt/keycloak/lib/quarkus/ /opt/keycloak/lib/quarkus/
COPY --from=keycloak-builder /opt/keycloak/providers/* /opt/keycloak/providers/


ENTRYPOINT ["/opt/keycloak/bin/kc.sh"]