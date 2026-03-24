#!/usr/bin/env bash

set -exEuo pipefail

# Trap -e errors
trap 'echo "Exit status $? at line $LINENO from: $BASH_COMMAND"' ERR

admin_jwt=$(./tools/gen-edgehog-jwt ./tools/gen-edgehog-jwt -k ./backend/priv/repo/seeds/keys/admin_private.pem -t admin)
public_key=$(cat ./acme_public.pem | jq -Rs)
astarte_priv=$(cat ../astarte-wrapped/astarte/test_private.pem | jq -Rs)

payload=$(
    printf '{
           "data": {
             "type": "tenant",
             "attributes": {
               "name": "Test",
               "slug": "test", 
               "default_locale": "en-US",
               "public_key": %s,
               "astarte_config": {
                 "base_api_url": "http://api.astarte.localhost",
                 "realm_name": "test",
                 "realm_private_key": %s
               }
             }
           }
         }' "$public_key" "$astarte_priv" | jq
)

echo "$payload"

curl -v -X POST --fail-with-body -sf "http://api.edgehog.localhost/admin-api/v1/tenants" \
    -H "Authorization: Bearer $admin_jwt" \
    -H "Content-Type: application/vnd.api+json" \
    -H "Accept: application/vnd.api+json" \
    --data "$payload"
