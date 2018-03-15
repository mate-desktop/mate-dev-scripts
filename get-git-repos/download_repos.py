#!/usr/bin/env python3

import os

# MATE repos
PKGS = ["atril",
        "caja",
        "caja-dropbox",
        "caja-extensions",
        "caja-xattrs",
        "debian-packages",
        "engrampa",
        "eom",
        "libmatekbd",
        "libmatemixer",
        "libmateweather",
        "marco",
        "mate-applets",
        "mate-backgrounds",
        "mate-calc",
        "mate-common",
        "mate-control-center",
        "mate-desktop",
        "mate-desktop.org",
        "mate-dev-scripts",
        "mate-icon-theme",
        "mate-icon-theme-faenza",
        "mate-indicator-applet",
        "mate-media",
        "mate-menus",
        "mate-netbook",
        "mate-notification-daemon",
        "mate-panel",
        "mate-polkit",
        "mate-power-manager",
        "mate-screensaver",
        "mate-sensors-applet",
        "mate-session-manager",
        "mate-settings-daemon",
        "mate-system-monitor",
        "mate-terminal",
        "mate-themes",
        "mate-university",
        "mate-user-guide",
        "mate-user-share",
        "mate-utils",
        "mozo",
        "pluma",
        "python-caja"]

GIT_SSH = "git clone https://github.com/mate-desktop/"

# clone all repositories one by one
for p in PKGS:
    os.system(GIT_SSH + p + ".git")
