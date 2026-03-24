#!/usr/bin/env bash

set -exEuo pipefail

podman compose down -v -t0
podman compose up -d --build

# podman-compose exec edgehog-backend bin/edgehog eval Edgehog.Release.seed

curl -s --retry 10 --retry-all-errors --retry-connrefused --retry-delay 5 --fail-with-body http://api.edgehog.localhost/health

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

echo
echo "==="
echo

./tools/gen-edgehog-jwt -k ./acme_private.pem -t tenant | wl-copy

xdg-open http://edgehog.localhost
