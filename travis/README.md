# README

`docker-build` is a generic script that using the Docker container to build for
the different distributions. It requires a configuration file to work with.
By default, a YAML file called `.docker-build.yml` is used.

# Usage

## Command line usage

```
usage: docker-build [-h] [-c FILE] [-n IMAGE] [-l N] [-s] [-v] [-i]
                    [-b autotools|meson|scripts] [-r github|scripts] [-t TAG]
                    [--version] [-C]

Compile the software in a Docker container

optional arguments:
  -h, --help            show this help message and exit
  -c FILE, --config FILE
                        The config file (default is ".docker-build.yml")
  -n IMAGE, --name IMAGE
                        Docker image name (default is "fedora")
  -l N, --limit N       Limit the number of output lines (default is 100)
  -s, --shell           Run interactive bash in the docker container.
  -v, --verbose         Verbose output, the number of output lines is not
                        limited
  -i, --install         Install dependent packages in docker container.
  -b autotools|meson|scripts, --build autotools|meson|scripts
                        Compile the software in docker container.
  -r github|scripts, --release github|scripts
                        Release the tarballs.
  -t TAG, --tag TAG     Release based on which tag.(default to use
                        "TRAVIS_TAG" envirment variable)
  --version             Show the version
  -C, --clean           Clean up the docker container.
```

## Steps by Step

Make sure the docker works in the system and don't see the error output by
running the `docker images` command.

1. Go to the source directory, for example `mate-menus`.

2. Create a `.docker-build.yml` file with the following content:

```
requires:
  ubuntu:
    - mate-common
    - intltool
    - python
```

If there are more dependencies, you need to add them.

3. Install the dependency package in the Docker container of `ubuntu 18.10`.

Run the command:

```
  docker-build --name ubuntu:18.10 --install
```

It will download the ubuntu 18.10 docker image, run it and install the
dependencies in the container.

The dependency package is written in the configuration file in the 2nd step.

**Note: **

If you find that the distro packages download is too slow when local debugging,
you can write `~/.distro_hook` script in source directory to modify OS repo url.

Here is an example file:

```
#!/bin/bash
if [ $# -ne 1 ];then
        exit 0
else
        distro=$1
fi

case $distro in
        archlinux)
                echo 'Server = http://mirrors.163.com/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist
                ;;
        debian)
                sed -i -s 's/deb.debian.org/mirrors.163.com/g' /etc/apt/sources.list
                ;;
        ubuntu)
                sed -i -s 's/archive.ubuntu.com/mirrors.163.com/g' /etc/apt/sources.list
                ;;
        *)
                true
                ;;
esac
```

4. Start building with autotools by running the follow command:

```
  docker-build --name ubuntu:18.10 --verbose --build autotools
```

You may see an error, usually because of a lack of dependencies, you can try
adding it in `.docker-build.yml` and run it again.

If you want to delete the container, run the follow command:
```
  docker-build --name ubuntu:18.10 --clean
```

# Configuration file format

`docker-build` requires a configuration file to run, which can be saved in JSON
or YAML formats with similar structures, default use YAML format, called
`.docker-build.yml`.

If you want to use a different configuration file name, please use the
`docker-build --config another_config_file`.

In the configuration file, the following configuration items are included:
1. `requires`: The compile dependency packages for different Linux distro,
create sub-key `ubuntu` for ubuntu distro.
2. `configures`: The compilation parameters to be used for `./configure` and
`meson`, create sub-key `autotools` for autotools, sub-key `meson` for meson.
3. `before_scripts`: The commands to be executed before build.
4. `after_scripts`: The commands to be executed after build.
5. `variables`: The environment variables to be used when building.

In the configuration file, only `requires` is required, others are optional.

## Environmental variable

The following environment variables can be used in before/after scripts:

- **BUILD_TYPE** : Compile type, autotools or meson
- **DISTRO_NAME** : The distro name, such as *debian* or *fedora*
- **DISTRO_VERSION** : The distro version
- **LIMIT** - : Maximum number of output lines
- **START_DIR** : The source code directory
- **BUILD_DIR** : The compile directory
- **VERBOSE** : Whether the detailed output is set
- **CONTAINER_NAME** : Container name

For example:

```
requires:
  ubuntu:
    - mate-common
    - intltool
    - python
  fedora:
    - dbus-glib-devel
    - desktop-file-utils
    - git
    - libcanberra-devel
    - libnotify-devel
    - libwnck3-devel
    - mate-common
    - mate-desktop-devel
  centos:
    - dbus-glib-devel
    - desktop-file-utils
    - libcanberra-devel
    - libnotify-devel
    - libwnck3-devel
    - mate-common
    - mate-desktop-devel
before_scripts:
  - pwd
  - env
variables:
  - CFLAGS="-Wall"
configures:
  autotools:
    - --prefix=/usr
    - --enable-gtk-doc
  meson:
    - --prefix /usr
    - -Denable-gtk-doc=true
after_scripts:
  - if [ "$BUILD_TYPE" = "meson" ]; then meson test; else make test; fi
  - if [ "$BUILD_TYPE" = "meson" ]; then ninja dist; else make distcheck; fi
```

# Travis CI

Travis CI provides Continuous Integration (CI). It binds the project on Github
and will automatically fetch as long as there is new code. Then, provide a
runtime environment, perform tests, complete the build, and deploy to the server.

Travis CI only supports Github and does not support other code hosting services.
This means that you must meet the following conditions in order to use Travis CI.

- Have a GitHub account
- There is a project below this account
- There are runnable code in the project.
- The project also includes build or test scripts

## Start Travis CI

1. First, visit the official website travis-ci.org, click on the profile picture
in the upper right corner, and log in to Travis CI using your Github account.

Travis will list all of your warehouses on Github and the organizations you
belong to. At this point, select the warehouse you need Travis to build for you,
and open the switch next to the warehouse. Once a repository is activated,
Travis will listen for all changes to the repository.


2. Write `.travis.yml`

Travis requires a `.travis.yml` file under the root of the project. This is a
configuration file that specifies the behavior of Travis. The file must be saved
in the Github repository. Once the code repository has a new Commit, Travis will
go to the file and execute the commands.

This file is in YAML format. Below is a `.travis.yml` file for the simplest
Python project.

```
language: python
script: true
```

See the documentation for more details: https://docs.travis-ci.com/

# Run docker-build on Travis CI

1. First need Travis CI to work in your repo.

2. Create a `.travis.yml` file with the following content:

```
dist: xenial
sudo: required
language: bash
services:
  - docker

before_install:
  - curl -L -o docker-build https://github.com/yetist/mate-dev-scripts/raw/travis/travis/docker-build
  - chmod +x docker-build

install:
  - sudo apt-get install -y python3-pip python3-setuptools
  - sudo pip3 install --upgrade pip
  - sudo pip install PyGithub
  - ./docker-build --name ${DISTRO} --install

script:
  - ./docker-build --name ${DISTRO} --verbose --build autotools

env:
  - DISTRO="ubuntu:18.10"
```

If the project is built using `meson`, modify the command in the `script` like this:
```
  - ./docker-build --name ${DISTRO} --verbose --build meson 
```

If you want to support more distro, add a similar line to env :

```
env:
  - DISTRO="archlinux/base"
  - DISTRO="debian:sid"
  - DISTRO="fedora:29"
  - DISTRO="ubuntu:18.10"
```

3. Create a `.docker-build.yml`

Please refer to the above description for the content.

If you don't want to add this file to your git repo, you can merge the contents
of this file into a `.travis.yml` file and modify the `.travis.yml` file to add
the `--config .travis.yml` parameter to the `docker-build` command.
