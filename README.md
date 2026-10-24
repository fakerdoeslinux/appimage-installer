# AppImage Installer

Install AppImages for your user without root access. The installer copies each
app to `~/.local/opt/appimages` and adds it to your desktop app menu. It does
not download apps; use AppImages from sources you trust.

## Install an AppImage

On KDE Plasma, open `install-appimage.sh` and choose **Execute** if prompted.
Select an AppImage in the file picker. The first graphical launch also adds
**AppImage Installer** to your app menu. Other desktops need `zenity`.

To install from a terminal, pass the AppImage path:

```sh
./install-appimage.sh ~/Downloads/MyApp.AppImage
```

## Remove an app

Delete its AppImage from `~/.local/opt/appimages` and its matching `.desktop`
file from `~/.local/share/applications`.
