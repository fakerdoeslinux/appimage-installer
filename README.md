# AppImage Installer

A small user-local installer for Linux AppImages. It copies an AppImage into
`~/.local/opt/appimages` and creates a desktop launcher in
`~/.local/share/applications`, so the application can be started from your
desktop environment's app menu.

## Install an AppImage

```sh
chmod +x install-appimage.sh
./install-appimage.sh ~/Downloads/MyApp.AppImage
```

No root access is required. The script does not download AppImages; obtain them
from a source you trust.

## Remove an installed app

Delete the installed AppImage from `~/.local/opt/appimages` and its matching
`.desktop` file from `~/.local/share/applications`.
