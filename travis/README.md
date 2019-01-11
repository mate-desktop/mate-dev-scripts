# README

`docker-build`: This is the common build script for mate-desktop to use travis-ci.

# Howto use

Every mate-desktop project should create `.travis.yml` and `.docker.json` files in that top directry.


## `.travis.yml`

This file used to setup travis.

In `before_install` section, it downloads the `docker-build` file, and sets executable permissions.

In `install` section, download the docker image of the linux distro, create the docker container, update the system and install the dependency packages according to the settings of `.docker.json` file.

In `env` section, multiple different linux distributions can be set up for compille testing.

Here is an example:

```
sudo: required
services:
  - docker

before_install:
  - curl -L https://raw.githubusercontent.com/mate-desktop/mate-dev-scripts/travis/travis/docker-build > docker-build
  - chmod +x docker-build

install:
  - ./docker-build --name ${DISTRO} --install

script:
  - 'if [ "$TRAVIS_PULL_REQUEST" != "false" ]; then ./docker-build --name ${DISTRO} --build pr; fi'
  - 'if [ "$TRAVIS_PULL_REQUEST" = "false" ];  then ./docker-build --name ${DISTRO} --build test; fi'

env:
  - DISTRO="fedora:29"
#  - DISTRO="centos:7"
#  - DISTRO="ubuntu:18.10"

#deploy:
#  provider: releases
#  api_key: "GITHUB OAUTH TOKEN"
#  file_glob: true
#  file: mate-notification-daemon-1.*.tar.xz
#  skip_cleanup: true
#  on:
#    tags: true
```

## `.docker.json`

In `.docker.json` file, we can set the compile dependency packages for different Linux distro,
set compile parameters, set whether to run `make distcheck`.

In `requires` key, set the compile dependency packages for different Linux distro.

The `configure`, `prebuild` and `distcheck` keys are optional.

If no `configure`, will use `--prefix=/usr` for compile.

If no `prebuild`, ignored it. The `prebuild` is not very useful, just used for some project's api changed, and the distro dose not released the packages.
so, before build the current repo, that project should be build and install to the system first.

If no `distcheck`, or `distcheck` is false, ignored it, if `distcheck` is true, run `make distcheck` after `make` finished.

```
{
  "requires" : {
    "ubuntu" : [
          "mate-common",
          "intltool",
          "python"
    ],
    "fedora" : [
          "dbus-glib-devel",
          "desktop-file-utils",
          "git",
          "libcanberra-devel",
          "libnotify-devel",
          "libwnck3-devel",
          "mate-common",
          "mate-desktop-devel"
    ],
    "centos" : [
          "dbus-glib-devel",
          "desktop-file-utils",
          "libcanberra-devel",
          "libnotify-devel",
          "libwnck3-devel",
          "mate-common",
          "mate-desktop-devel"
    ],
    "prebuild" : [
          "git clone https://github.com/mate-desktop/mate-menus.git mate-menus",
          "cd mate-menus",
          "./autogen.sh --prefix=/usr",
          "make",
          "make install"
    ],
    "configure" : [
          "--prefix=/usr",
          "--enable-gtk-doc",
          "..."
  },
    "distcheck" : true
}
```
