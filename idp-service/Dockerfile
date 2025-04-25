FROM quay.io/keycloak/keycloak:23.0.2 AS builder

# Configure a database vendor
ENV KC_DB=mysql

WORKDIR /opt/keycloak
RUN /opt/keycloak/bin/kc.sh build

FROM quay.io/keycloak/keycloak:23.0.2 AS runner

USER root
WORKDIR /
COPY --from=builder /opt/keycloak/ /opt/keycloak/

ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start", "--import-realm"]
