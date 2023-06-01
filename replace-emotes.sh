#!/usr/bin/env bash
set -euo pipefail

folder="${1:-}"

if ! test -d "$folder"; then
    echo "Usage: $0 <folder>" >&2
    echo "Where <folder> should have a 'todo' subfolder containing the emotes" >&2
    exit 1
fi

mkdir -p "$folder/uploaded"

function api {
    local path="$1"
    shift
    curl --silent --fail --header "Authorization: Bot $DISCORD_TOKEN" --header 'Content-Type: application/json' "$@" "https://discord.com/api/v10/$path"
}

emotes="$(api "guilds/$DISCORD_GUILD/emojis")"

while read -r filename; do
    ext="${filename##*.}"
    name="$(basename "$filename" ".$ext")"
    echo "$(date) $name" >&2

    image="data:image/$ext;base64,$(base64 "$filename")"
    jq --null-input --arg name "$name" --arg image "$image" '{ $name, $image }' |\
        api "guilds/$DISCORD_GUILD/emojis" -X POST --data-binary @- >/dev/null
    
    while read -r id; do
        api "guilds/$DISCORD_GUILD/emojis/$id" -X DELETE >/dev/null
    done < <(jq --raw-output --arg name "$name" '.[] | select(.name == $name) | .id' <<<"$emotes")

    mv "$filename" "$folder/uploaded/"

    sleep 10
done < <(find "$folder/todo/" -type f -name '*.png' -o -name '*.gif' -o -name '*.jpeg')
