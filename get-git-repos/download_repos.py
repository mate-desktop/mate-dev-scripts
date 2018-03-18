#!/usr/bin/env python3

import os

# from manual: https://docs.python.org/3.6/howto/argparse.html#introducing-optional-arguments
import argparse
parser = argparse.ArgumentParser()
parser.add_argument("--ssh", help="use ssh for the git clone commands", action="store_true")
args = parser.parse_args()

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

# use ssh
if args.ssh:
    GIT_CLONE_CMD = "git clone git@github.com:mate-desktop/"
# use https
else:
    GIT_CLONE_CMD = "git clone https://github.com/mate-desktop/"

# clone all repositories one by one
for p in PKGS:
    os.system(GIT_CLONE_CMD + p + ".git")
