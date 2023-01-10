#!/usr/bin/env bash

KEYCLOAK_URL=${KC_HOSTNAME}
KEYCLOAK_USER=${KEYCLOAK_ADMIN}
KEYCLOAK_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD}
KEYCLOAK_CLIENT_ID=${KEYCLOAK_CLIENT_ID}
KEYCLOAK_CLIENT_SECRET=${KEYCLOAK_CLIENT_SECRET}

echo "Creating initial terraform client"

accessToken=$(
    curl -s --fail \
        -d "username=${KEYCLOAK_USER}" \
        -d "password=${KEYCLOAK_PASSWORD}" \
        -d "client_id=admin-cli" \
        -d "grant_type=password" \
        "${KEYCLOAK_URL}/realms/master/protocol/openid-connect/token" \
        | jq -r '.access_token'
)

function post() {
    curl --fail \
        -H "Authorization: bearer ${accessToken}" \
        -H "Content-Type: application/json" \
        -d "${2}" \
        "${KEYCLOAK_URL}/admin${1}"
}

function put() {
    curl --fail \
        -X PUT \
        -H "Authorization: bearer ${accessToken}" \
        -H "Content-Type: application/json" \
        -d "${2}" \
        "${KEYCLOAK_URL}/admin${1}"
}

function get() {
    curl --fail --silent \
        -H "Authorization: bearer ${accessToken}" \
        -H "Content-Type: application/json" \
        "${KEYCLOAK_URL}/admin${1}"
}

terraformClient=$(jq -n "{
    id: \"${KEYCLOAK_CLIENT_ID}\",
    name: \"${KEYCLOAK_CLIENT_ID}\",
    secret: \"${KEYCLOAK_CLIENT_SECRET}\",
    clientAuthenticatorType: \"client-secret\",
    enabled: true,
    serviceAccountsEnabled: true,
    directAccessGrantsEnabled: true,
    standardFlowEnabled: false
}")

post "/realms/master/clients" "${terraformClient}"

masterRealmAdminRole=$(get "/realms/master/roles" | jq -r '
    .
    | map(
        select(.name == "admin")
    )
    | .[0]
')
masterRealmAdminRoleId=$(echo ${masterRealmAdminRole} | jq -r '.id')

terraformClientServiceAccount=$(get "/realms/master/clients/${KEYCLOAK_CLIENT_ID}/service-account-user")
terraformClientServiceAccountId=$(echo ${terraformClientServiceAccount} | jq -r '.id')

serviceAccountAdminRoleMapping=$(jq -n "[{
    clientRole: false,
    composite: true,
    containerId: \"master\",
    description: \"\${role_admin}\",
    id: \"${masterRealmAdminRoleId}\",
    name: \"admin\",
}]")

post "/realms/master/users/${terraformClientServiceAccountId}/role-mappings/realm" "${serviceAccountAdminRoleMapping}"

masterRealmExtendAccessToken=$(jq -n "{
    accessTokenLifespan: 86400,
    accessTokenLifespanForImplicitFlow: 86400,
    ssoSessionIdleTimeout: 86400,
    ssoSessionMaxLifespan: 86400,
    offlineSessionIdleTimeout: 86400,
    offlineSessionMaxLifespan: 5184000,
    accessCodeLifespan: 86400,
    accessCodeLifespanUserAction: 86400,
    accessCodeLifespanLogin: 86400,
    actionTokenGeneratedByAdminLifespan: 86400,
    actionTokenGeneratedByUserLifespan: 86400,
    oauth2DeviceCodeLifespan: 86400
}")

put "/realms/master" "${masterRealmExtendAccessToken}"

echo "Done"