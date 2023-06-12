#!/usr/bin/env bash
set -euo pipefail

channel="${1:-}"

if test -z "$channel"; then
    echo "Usage: $0 <channel>" >&2
    echo "Where <channel> is the ID of a channel for which to dump logs" >&2
    exit 1
fi

rm -rf "data/logs/$channel/"
mkdir -p "data/logs/$channel/"

function api {
    local path="$1"
    shift
    curl --silent --fail --header "Authorization: Bot $DISCORD_TOKEN" --header 'Content-Type: application/json' --header 'X-Audit-Log-Reason: discord-utils/replace-emotes.sh' "$@" "https://discord.com/api/v10/$path"
}

messages="$(api "channels/$channel/messages?limit=100")"
before="$(jq --raw-output '.[-1].id' <<<"$messages")"
echo "$messages" >"data/logs/$channel/$before.json"

while [ "$before" != "null" ]; do
    sleep 1
    messages="$(api "channels/$channel/messages?limit=100&before=$before")"
    before="$(jq --raw-output '.[-1].id' <<<"$messages")"
    echo "$messages" >"data/logs/$channel/$before.json"
done
