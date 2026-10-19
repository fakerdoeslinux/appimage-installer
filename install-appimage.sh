#!/bin/sh
set -eu

usage() {
    echo "Usage: $0 [path/to/application.AppImage]" >&2
}

error_dialog() {
    if [ "$dialog_tool" = kdialog ]; then
        kdialog --title "AppImage Installer" --error "$1"
    elif [ "$dialog_tool" = zenity ]; then
        zenity --error --title="AppImage Installer" --text="$1"
    else
        echo "Error: $1" >&2
    fi
}

info_dialog() {
    if [ "$dialog_tool" = kdialog ]; then
        kdialog --title "AppImage Installer" --msgbox "$1"
    elif [ "$dialog_tool" = zenity ]; then
        zenity --info --title="AppImage Installer" --text="$1"
    else
        echo "$1"
    fi
}

choose_appimage() {
    if [ "$dialog_tool" = kdialog ]; then
        kdialog --title "Choose an AppImage" --getopenfilename "$HOME/Downloads" \
            "AppImage (*.AppImage *.appimage)"
    else
        zenity --file-selection --title="Choose an AppImage" \
            --file-filter="AppImage (*.AppImage) | *.AppImage" \
            --file-filter="All files | *"
    fi
}

escape_exec_value() {
    printf '%s' "$1" | sed 's/[\\"]/\\&/g; s/[$`]/\\&/g; s/%/%%/g'
}

install_menu_launcher() {
    launcher_dir=${XDG_DATA_HOME:-"$HOME/.local/share"}/applications
    installer_dir=$HOME/.local/opt/appimage-installer
    installed_script=$installer_dir/install-appimage.sh
    mkdir -p "$launcher_dir" "$installer_dir" || return 1

    if [ "$script_path" != "$installed_script" ]; then
        cp -- "$script_path" "$installed_script" || return 1
        chmod 755 "$installed_script" || return 1
    fi

    launcher_tmp=$(mktemp "$launcher_dir/.appimage-installer.XXXXXX") || return 1
    trap 'rm -f "$launcher_tmp"' 0 HUP INT TERM
    exec_path=$(escape_exec_value "$installed_script")
    if ! {
        printf '[Desktop Entry]\n'
        printf 'Type=Application\n'
        printf 'Name=AppImage Installer\n'
        printf 'Comment=Install AppImages and add them to the app menu\n'
        printf 'Exec="%s"\n' "$exec_path"
        printf 'Icon=application-x-executable\n'
        printf 'Terminal=false\n'
        printf 'Categories=Utility;\n'
    } > "$launcher_tmp"; then
        return 1
    fi
    mv -f -- "$launcher_tmp" "$launcher_dir/appimage-installer.desktop" || return 1
    trap - 0 HUP INT TERM
}

if [ "$#" -gt 1 ]; then
    usage
    exit 2
fi

if [ "$#" -eq 1 ]; then
    source_path=$1
    dialog_tool=
else
    if command -v kdialog >/dev/null 2>&1; then
        dialog_tool=kdialog
    elif command -v zenity >/dev/null 2>&1; then
        dialog_tool=zenity
    else
        echo "Error: install kdialog or zenity to use the graphical installer." >&2
        exit 1
    fi

    script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd -P)
    script_path=$script_dir/$(basename -- "$0")
    if ! install_menu_launcher; then
        error_dialog "Could not add AppImage Installer to your app menu."
        exit 1
    fi

    if ! source_path=$(choose_appimage); then
        exit 0
    fi
    if [ -z "$source_path" ]; then
        exit 0
    fi
fi

if [ ! -f "$source_path" ] || [ ! -r "$source_path" ]; then
    if [ -n "$dialog_tool" ]; then
        error_dialog "AppImage is not a readable file:\n$source_path"
    else
        echo "Error: AppImage is not a readable file: $source_path" >&2
    fi
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
if ! mkdir -p "$app_dir"; then
    if [ -n "$dialog_tool" ]; then
        error_dialog "Could not create the AppImage install directory:\n$app_dir"
    fi
    exit 1
fi
if ! app_dir=$(CDPATH= cd -- "$app_dir" && pwd -P); then
    if [ -n "$dialog_tool" ]; then
        error_dialog "Could not access the AppImage install directory."
    fi
    exit 1
fi
applications_dir=${XDG_DATA_HOME:-"$HOME/.local/share"}/applications
if ! mkdir -p "$applications_dir"; then
    if [ -n "$dialog_tool" ]; then
        error_dialog "Could not create the application menu directory:\n$applications_dir"
    fi
    exit 1
fi

installed_path=$app_dir/$source_file
if [ "$source_path" != "$installed_path" ]; then
    if ! cp -- "$source_path" "$installed_path"; then
        if [ -n "$dialog_tool" ]; then
            error_dialog "Could not copy the AppImage to:\n$installed_path"
        fi
        exit 1
    fi
fi
if ! chmod 755 "$installed_path"; then
    if [ -n "$dialog_tool" ]; then
        error_dialog "Could not make the AppImage executable:\n$installed_path"
    fi
    exit 1
fi

desktop_file=$applications_dir/$desktop_id.desktop
if ! desktop_tmp=$(mktemp "$applications_dir/.${desktop_id}.XXXXXX"); then
    if [ -n "$dialog_tool" ]; then
        error_dialog "Could not create a desktop launcher."
    fi
    exit 1
fi
trap 'rm -f "$desktop_tmp"' 0 HUP INT TERM

exec_path=$(escape_exec_value "$installed_path")

if ! {
    printf '[Desktop Entry]\n'
    printf 'Type=Application\n'
    printf 'Name=%s\n' "$app_name"
    printf 'Exec="%s"\n' "$exec_path"
    printf 'Icon=application-x-executable\n'
    printf 'Terminal=false\n'
    printf 'Categories=Utility;\n'
} > "$desktop_tmp"; then
    if [ -n "$dialog_tool" ]; then
        error_dialog "Could not write the desktop launcher."
    fi
    exit 1
fi

if ! mv -f -- "$desktop_tmp" "$desktop_file"; then
    if [ -n "$dialog_tool" ]; then
        error_dialog "Could not add the app to your application menu."
    fi
    exit 1
fi
trap - 0 HUP INT TERM

if [ -n "$dialog_tool" ]; then
    info_dialog "Installed $app_name successfully.\nYou can now find it in your app menu."
else
    printf 'Installed %s\nLauncher: %s\n' "$installed_path" "$desktop_file"
fi
