#! /usr/bin/python

import os

# TODO: add options to include debian, arch, and/or fedora packages and remove them from PKGS.

# MATE repos
PKGS = ["mate-user-share", "debian-packages", "mate-bluetooth", "mate-panel", "mate-notification",
        "mate-keyring", "mate-indicator-applet", "libmatekeyring", "mate-window-manager",
        "mate-session-manager", "libmatecomponent", "mate-themes", "mate-file-manager", 
        "mate-system-tools", "fedora-packages", "archlinux-packages", "mate-common",
        "mate-character-map", "Mate-Extra", "mate-control-center", "mate-settings-daemon",
        "caja-dropbox", "mate-file-archiver", "mate-utils", "mate-applets", "mate-media",
        "mate-desktop", "mate-calc", "mate-image-viewer", "mate-file-manager-open-terminal",
        "libmatekbd", "mate-power-manager", "mate-system-monitor", "mate-text-editor", 
        "mate-terminal", "mate-document-viewer", "mate-file-manager-gksu", "mate-mime-data",
        "mate-vfs", "libmate", "mate-backgrounds", "mate-corba", "mate-file-manager-image-converter",
        "mate-file-manager-sendto", "mate-menu-editor", "python-caja", "mate-conf-editor",
        "ffmpegthumbnailer-caja", "mate-sensors-applet", "mate-netspeed", "python-mate", 
        "python-corba", "mate-doc-utils", "mate-screensaver", "mate-polkit", "mate-menus",
        "mate-dialogs", "mate-icon-theme", "libmateweather", "libmateui", "mate-conf",
        "libmatecomponentui", "libmatecanvas", "mate-file-manager-share", "python-mate-desktop"]
      
GIT_SSH = "git clone git@github.com:mate-desktop/"

# will prompt for the users ssh key on the first git clone 
for p in PKGS:
    os.system(GIT_SSH + p)
