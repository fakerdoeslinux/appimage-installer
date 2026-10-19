#!/bin/sh
set -eu

usage() {
    echo "Usage: $0 /path/to/application.AppImage" >&2
    exit 2
}

[ "$#" -eq 1 ] || usage
source_path=$1

if [ ! -f "$source_path" ] || [ ! -r "$source_path" ]; then
    echo "Error: AppImage is not a readable file: $source_path" >&2
    exit 1
fi

source_dir=$(CDPATH= cd -- "$(dirname -- "$source_path")" && pwd -P)
source_file=$(basename -- "$source_path")
source_path=$source_dir/$source_file

app_name=${source_file%.[Aa][Pp][Pp][Ii][Mm][Aa][Gg][Ee]}
if [ "$app_name" = "$source_file" ]; then
    app_name=$source_file
fi
app_name=$(printf '%s' "$app_name" | tr '\r\n' '  ')

desktop_id=$(printf '%s' "$app_name" | LC_ALL=C tr -cs 'A-Za-z0-9_.-' '-')
desktop_id=$(printf '%s' "$desktop_id" | sed 's/^-*//; s/-*$//')
[ -n "$desktop_id" ] || desktop_id=appimage

app_dir=$HOME/.local/opt/appimages
app_dir=$(mkdir -p "$app_dir" && CDPATH= cd -- "$app_dir" && pwd -P)
applications_dir=${XDG_DATA_HOME:-"$HOME/.local/share"}/applications
mkdir -p "$applications_dir"

installed_path=$app_dir/$source_file
if [ "$source_path" != "$installed_path" ]; then
    cp -- "$source_path" "$installed_path"
fi
chmod 755 "$installed_path"

desktop_file=$applications_dir/$desktop_id.desktop
desktop_tmp=$(mktemp "$applications_dir/.${desktop_id}.XXXXXX")
trap 'rm -f "$desktop_tmp"' 0 HUP INT TERM

# Escape characters that have special meaning in Desktop Entry Exec values.
exec_path=$(printf '%s' "$installed_path" |
    sed 's/[\\"]/\\&/g; s/[$`]/\\&/g; s/%/%%/g')

{
    printf '[Desktop Entry]\n'
    printf 'Type=Application\n'
    printf 'Name=%s\n' "$app_name"
    printf 'Exec="%s"\n' "$exec_path"
    printf 'Icon=application-x-executable\n'
    printf 'Terminal=false\n'
    printf 'Categories=Utility;\n'
} > "$desktop_tmp"

mv -f -- "$desktop_tmp" "$desktop_file"
trap - 0 HUP INT TERM

printf 'Installed %s\nLauncher: %s\n' "$installed_path" "$desktop_file"
