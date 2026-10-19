# AppImage Installer

A small user-local installer for Linux AppImages. It copies an AppImage into
`~/.local/opt/appimages` and creates a desktop launcher in
`~/.local/share/applications`, so the application can be started from your
desktop environment's app menu.

## Open the graphical installer

On KDE Plasma, open `install-appimage.sh` from Dolphin and choose **Execute**
if prompted. The installer opens a file picker; select an AppImage to install.
The first launch also adds **AppImage Installer** to your app menu, so later
you can launch it there without opening a terminal. Other desktops can use
`zenity` as the graphical dialog provider.

The installer copies the AppImage into `~/.local/opt/appimages` and creates a
desktop launcher. No root access is required. It does not download AppImages;
obtain them from a source you trust.

To launch with an AppImage path from a terminal, you can also run:

```sh
./install-appimage.sh ~/Downloads/MyApp.AppImage
```

## Remove an installed app

Delete the installed AppImage from `~/.local/opt/appimages` and its matching
`.desktop` file from `~/.local/share/applications`.
