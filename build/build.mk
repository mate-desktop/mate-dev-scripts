#!/usr/bin/make -f
#
# Build and install a project and its dependencies in a prefix directory.
#
# Project options
# ---------------
#
# To customize the options for MATE projects, create a file named
# build-options.mk.  In it, add a variable with the name of the project prefixed
# by OPTIONS_.
#
# Eg, for add the option --enable-debug to mate-desktop create the variable
#
#     OPTIONS_mate-desktop := --enable-debug
#
# in the file build-options.mk.
#
# Common options
# --------------
#
# To add common options to all projects add the variable COMMON_OPTIONS in the
# build-options.mk file.
#
# Prefix directory
# ----------------
#
# The directory of the --prefix option can be modified adding the variable
# PREFIX in the build-options.mk file.
#

# Default prefix directory
PREFIX := $(CURDIR)/PREFIX

# Load user options (if available)
-include build-options.mk

# Set environment variables.
# References: https://wiki.mate-desktop.org/building#troubleshooting
PATH := $(PREFIX)/bin:$(PATH)
export ACLOCAL_FLAGS := -I $(PREFIX)/share/aclocal
export PKG_CONFIG_PATH := $(PREFIX)/lib/pkgconfig

all:

PROJECTS = atril \
    caja \
    caja-dropbox \
    caja-extensions \
    caja-xattrs \
    engrampa \
    eom \
    libmatekbd \
    libmatemixer \
    libmateweather \
    marco \
    mate-applets \
    mate-backgrounds \
    mate-calc \
    mate-common \
    mate-control-center \
    mate-desktop \
    mate-icon-theme \
    mate-icon-theme-faenza \
    mate-indicator-applet \
    mate-media \
    mate-menus \
    mate-netbook \
    mate-notification-daemon \
    mate-panel \
    mate-polkit \
    mate-power-manager \
    mate-screensaver \
    mate-sensors-applet \
    mate-session-manager \
    mate-settings-daemon \
    mate-system-monitor \
    mate-terminal \
    mate-themes \
    mate-university \
    mate-user-guide \
    mate-user-share \
    mate-utils \
    mozo \
    pluma \
    python-caja

# dependencies
atril: mate-common caja
caja: mate-common mate-desktop
caja-dropbox: mate-common caja
caja-extensions: mate-common caja
caja-xattrs: mate-common caja
engrampa: mate-common caja
eom: mate-common mate-desktop
libmatekbd: mate-common
libmatemixer: mate-common
libmateweather: mate-common
marco: mate-common
mate-applets: mate-common mate-panel
mate-backgrounds: mate-common
mate-calc: mate-common
mate-common:
mate-control-center: mate-common mate-desktop mate-menus marco mate-settings-daemon
mate-desktop: mate-common
mate-icon-theme: mate-common
mate-icon-theme-faenza: mate-common
mate-indicator-applet: mate-common mate-panel
mate-media: mate-common mate-desktop libmatemixer mate-panel
mate-menus: mate-common
mate-netbook: mate-common mate-panel
mate-notification-daemon: mate-common
mate-panel: mate-common mate-desktop mate-menus libmateweather
mate-polkit: mate-common
mate-power-manager: mate-common mate-panel
mate-screensaver: mate-common mate-desktop mate-menus
mate-sensors-applet: mate-common mate-panel
mate-session-manager: mate-common
mate-settings-daemon: mate-common mate-desktop libmatekbd
mate-system-monitor: mate-common
mate-terminal: mate-common
mate-themes: mate-common
mate-university: mate-common mate-panel
mate-user-guide: mate-common
mate-user-share: mate-common caja
mate-utils: mate-common mate-panel
mozo: mate-common mate-menus
pluma: mate-common
python-caja: mate-common caja

# build rules (same rule for all projects)
$(PROJECTS):
	cd $@ && ./autogen.sh --prefix="$(PREFIX)" $(COMMON_OPTIONS) $(OPTIONS_$@) && make -j && make install

.PHONY: $(PROJECTS)
