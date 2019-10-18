#!/usr/bin/python3
# -*- encoding:utf-8 -*-
# vim: set filetype=python

__copyright__= "Copyright (C) 2019 Wu Xiaotian <yetist@gmail.com>"
__license__  = """
This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License along
with this program; if not, write to the Free Software Foundation, Inc.,
51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
"""

import os
import sys
import shlex
import stat
import json
import yaml
import argparse
import subprocess
import shutil
import re
import glob
import requests
import hmac
import hashlib
import uuid
import multiprocessing
import datetime

try:
    import github
except:
    if bool(os.getenv("TRAVIS")):
        print("Please make sure your .travis.yml has the follow lines:")
        print("""
install:
  - sudo apt-get install -y python3-pip python3-setuptools
  - sudo pip3 install --upgrade pip
  - sudo pip install PyGithub
  - ./docker-build --name ${DISTRO} --config .travis.yml --install
""")
    else:
        print('Please install "python3-github" package on youre system.')
    sys.exit(1)

MESON_BUILD_DIRNAME = '_build'
ROOT_DIR = '/rootdir'
HOOK_NAME = 'distro_hook'
DIGITS = re.compile(r'(\d+)')
VERSION = '0.1.2'
ISSUE_URL = 'https://github.com/mate-desktop/mate-dev-scripts/issues/new'

class Result:
    pass

class ShortIO(object):
    def __init__ (self, limit=0):
        if limit == 1:
            self.head_lines = 1
            self.tail_lines = 0
        else:
            self.head_lines = int(limit/2)
            self.tail_lines = int(limit - self.head_lines)
        if (self.head_lines + self.tail_lines) > limit:
            self.tail_lines = 0
        self.line_count = 0
        self.tail_list = []
        self.dot_count = 0

    def print(self, msg):
        if self.head_lines <= 0:
            print(msg, end='', flush=True)
            return
        if self.line_count < self.head_lines:
            print(msg, end='', flush=True)
        else:
            print('.', end='', flush=True)
            self.dot_count += 1
            self.tail_list.append(msg)
            if len(self.tail_list) > self.tail_lines:
                self.tail_list = self.tail_list[-self.tail_lines:]
        self.line_count += 1

    def end(self):
        if self.head_lines <= 0:
            return
        result = self.line_count - self.head_lines - self.tail_lines
        if self.dot_count > 0:
            print('\b'* self.dot_count, end='', flush=False)
        if result > 0:
            print('........................... Omit %d lines of output ...........................' % result)
        if self.tail_lines > 0:
            for line in self.tail_list:
                print(line, end='', flush=True)

class Version(object):
    def __init__(self, version='1.0', max_minor=99, max_micro=99):
        self.max_minor = max_minor
        self.max_micro = max_micro
        self.parse_version(version)

    def __str__(self):
        _version = '.'.join(str(num) for num in self.vlist[:])
        return self.prefix + _version + self.suffix

    def tag(self):
        _version = '.'.join(str(num) for num in self.vlist[:])
        return 'v' + _version

    def version(self):
        _version = '.'.join(str(num) for num in self.vlist[:])
        return _version

    def parse_version(self, version):
        self.vlist = [int(num,10) for num in DIGITS.findall(version)]
        _version = '.'.join(str(num) for num in self.vlist[:])
        self.prefix, self.suffix = version.split(_version, 1)
        length = len(self.vlist)
        if len(self.vlist) < 3:
            self.vlist.extend([0]*(3-length))
        self.vlist = self.vlist[:3]

    def next(self):
        if self.vlist[2] < self.max_micro:
            self.vlist[2] += 1
        elif self.vlist[1] < self.max_minor:
            self.vlist[1] += 1
            self.vlist[2] = 0
        else:
            self.vlist[0] += 1
            self.vlist[1] = 0
            self.vlist[2] = 0
        return self.__str__()

    def prev(self):
        if self.vlist[2] > 0:
            self.vlist[2] -= 1
        elif self.vlist[1] > 0:
            self.vlist[1] -= 1
            self.vlist[2] = self.max_micro
        elif self.vlist[0] > 0:
            self.vlist[0] -= 1
            self.vlist[1] = self.max_minor
            self.vlist[2] = self.max_micro
        if (self.vlist[0] + self.vlist[1] + self.vlist[2]) == 0:
            self.vlist[2] = 1
        return self.__str__()

    def compare(self, version):
        vlist = [int(num,10) for num in DIGITS.findall(version)]
        length = len(vlist)
        if len(vlist) < 3:
            vlist.extend([0]*(3-length))
        result = 0
        for i in range(3):
            result = self.vlist[i] - vlist[i]
            if result != 0:
                break
        return result

class Github(object):
    def __init__(self, opts, token=None):
        self.opts = opts
        self.token = os.getenv('GITHUB_TOKEN', '')
        self.verbose = opts['verbose']
        self.new_tag = ''
        self.init_opts()

    def init_opts(self):
        self.base_version = '1.0'
        self.overwrite = False
        self.tags = True
        self.notify_servers = []
        self.custom_http_headers = []

        if 'releases' in self.opts['config'].keys() and 'github_release' in self.opts['config']['releases'].keys():
            if 'tags' in self.opts['config']['releases']['github_release'].keys():
                self.tags = str(self.opts['config']['releases']['github_release']['tags'])

            if 'base_version' in self.opts['config']['releases']['github_release'].keys():
                self.base_version = str(self.opts['config']['releases']['github_release']['base_version'])

            if 'custom_http_headers' in self.opts['config']['releases']['github_release'].keys():
                if type(self.opts['config']['releases']['github_release']['custom_http_headers']) == str:
                    self.custom_http_headers.append(self.opts['config']['releases']['github_release']['custom_http_headers'])
                elif type(self.opts['config']['releases']['github_release']['custom_http_headers']) == list:
                    self.custom_http_headers.extend(self.opts['config']['releases']['github_release']['custom_http_headers'])

            if 'overwrite' in self.opts['config']['releases']['github_release'].keys():
                self.overwrite = bool(self.opts['config']['releases']['github_release']['overwrite'])

            if 'notify_servers' in self.opts['config']['releases']['github_release'].keys():
                server = self.opts['config']['releases']['github_release']['notify_servers']
                if type(server) == str:
                    self.notify_servers.append(server)
                elif type(server) == list:
                    self.notify_servers.extend(server)

        self.base_tag = Version(self.base_version).tag()

    def calc_version(self):
        self.all_tags = [tag.name for tag in self.repo.get_tags()]
        if self.opts['new_tag']:
            self.new_tag = self.opts['new_tag']
            self.new_version = Version(self.new_tag).version()
        else:
            next_new_tag = False
            new_version = Version(self.base_version)
            for i in range(100):
                new_version.next()
                if new_version.tag() not in self.all_tags:
                    next_new_tag = True
                    break
            if next_new_tag:
                self.new_tag = new_version.tag()
                self.new_version = new_version.version()

        # Find old tag name
        found_old_tag = False
        found_version = Version(self.new_tag)
        for i in range(1000):
            found_version.prev()
            if found_version.tag() in self.all_tags:
                found_old_tag = True
                break
        if found_old_tag:
            self.base_tag = found_version.tag()
            self.base_version = found_version.version()

    def check_scopes(self):
        repo_ok = False
        email_ok = False

        if self.hub.oauth_scopes is None:
            print_error('Your personal access token seems have no scope.')
            return False

        if not bool(''.join(self.hub.oauth_scopes)):
            print_error('Your personal access token seems have no scope.')
            return False

        if 'repo' in self.hub.oauth_scopes or 'public_repo' in self.hub.oauth_scopes:
            repo_ok = True
        else:
            print_error('Your personal access token without the "public_repo" or "repo" scope.')

        if 'user' in self.hub.oauth_scopes or 'user:email' in self.hub.oauth_scopes:
            email_ok = True
        else:
            print_error('Your personal access token without the "user" or "user:email" scope.')

        return repo_ok and email_ok

    def Login(self):
        if not self.token:
            print_error('Please setup "GITHUB_TOKEN" envirment varable')
            return False

        self.hub = github.Github(self.token)
        try:
            user = self.hub.get_user()
            username = user.name
        except github.GithubException:
            print_error('Maybe the "GITHUB_TOKEN" envirment varable is invalid.')
            return False

        if self.verbose > 2:
            print("Login as %s" % username)

        if not self.check_scopes():
            print_error('Please setup "GITHUB_TOKEN" envirment varable')
            return False

        self.repo = self.hub.get_repo(self.opts['owner_name'] + '/' + self.opts['repo_name'])
        self.calc_version()

        return True

    def get_git_log(self):
        lines = []
        for commit in self.repo.compare(self.base_tag, self.new_tag).commits:
            lines.append('- ' + commit.commit.message)
        return lines

    def get_news_log(self):
        lines = []
        news_path = os.path.join(self.opts['host_dir'], 'NEWS')
        if not os.path.isfile(news_path):
            print_error('"NEWS" file lost.')
            return lines
        old = '{} {}'.format(self.opts['repo_name'], self.base_version)
        new = '{} {}'.format(self.opts['repo_name'], self.new_version)

        found = False
        data = open(news_path).read().splitlines()
        for i in data:
            line = i.strip()
            if line.startswith('##') and line.endswith(new):
                found = True
        if not found:
            print_error('forgot to update the "NEWS" file for %s-%s?' % (self.opts['repo_name'], new))
            return lines

        found = False
        for i in data:
            line = i.strip()
            if line.startswith('##') and line.endswith(new):
                found = True
            if line.startswith('##') and line.endswith(old):
                found = False
            if found:
                lines.append(line)
        return lines

    def create_tag(self):
        if self.verbose > 1:
            print("Create new tag: %s" % self.new_tag)

        account = Result()
        user = self.hub.get_user()
        if not user.email:
            account.name = user.name
            for email in user.get_emails():
                if email['primary']:
                    account.email = email['email']

        author = github.InputGitAuthor(account.name, account.email)
        master = self.repo.get_branch("master")
        tag = self.repo.create_git_tag(self.new_tag, 'version %s' % self.new_version, master.commit.commit.sha, 'commit', tagger=author)
        self.repo.create_git_ref('refs/tags/%s' % tag.tag, tag.sha)

    def check_release(self):
        ok = True

        is_tag_stage = bool(self.opts['new_tag'])
        if self.tags and not is_tag_stage:
            print_info('No tags are created, ignore github release.')
            return False

        releases = self.repo.get_releases()
        for release in releases:
            if release.tag_name == self.new_tag:
                if self.overwrite:
                    release.delete_release()
                else:
                    ok = False
                    print_error("The release already exists.")
                break
        return ok

    def Release(self):
        if not self.check_release():
            return

        info = '1. Create github'
        if self.opts['prerelease']:
            info += ' prerelease'
        else:
            info += ' release'
        if self.opts['draft']:
            info += '[DRAFT]'
        info += ' for %s-%s' % (self.opts['repo_name'], self.new_version)
        print_info(info)

        #if new tag not exist, create it first.
        if self.new_tag not in self.all_tags:
            self.create_tag()

        logs = self.get_news_log()
        if not logs:
            logs = self.get_git_log()

        logs.insert(0, 'Changes since the last release: ' + self.repo.html_url + '/compare/' + self.base_tag + '...' + self.new_tag)
        body = '\n'.join(logs)

        title = "%s %s release" % (self.opts['repo_name'], self.new_version)
        if self.verbose > 1:
            print(title)
            print('='*80)
            print(body)
            print('='*80)

        self.release = self.repo.create_git_release(self.new_tag, name=title, message=body, draft=self.opts['draft'], prerelease=self.opts['prerelease'])
        self.upload()
        self.notify()

    def upload(self):
        for i in self.opts['file_lists']:
            if self.verbose > 0:
                print('Uploading %s ...' % os.path.basename(i))
            self.release.upload_asset(i)
        self.release = self.repo.get_release(self.release.id)
        print('Please visit: %s\n' % (self.release.html_url))

    def gen_http_headers(self):
        headers = {}
        for line in self.custom_http_headers:
            if line.find('=') < 0:
                continue
            (name, value) = line.split('=', 1)
            name = name.strip(" \t\n\'\"")
            value = value.strip(" \t\n\'\"")
            if value.startswith('$'):
                varname = value[1:]
                value = os.getenv(varname, 'Undefined')
            headers[name] = value
        if 'user-agent' not in [ i.lower() for i in headers.keys()]:
            if opts['travis']:
                headers['User-Agent'] = 'docker-build/%s (Travis CI)' % VERSION
            else:
                headers['User-Agent'] = 'docker-build/%s' % VERSION
        return headers

    def notify(self):
        if len(self.notify_servers) > 0:
            print_info('2. Notify the server that a new version is released')
        data = {}
        data['name'] = self.opts['repo_name']
        data['version'] = self.new_version
        data['tag'] = self.release.tag_name
        data['repo'] = get_repo_name('/')
        data['draft'] = self.release.draft
        data['news'] = self.release.body
        data['prerelease'] = self.release.prerelease
        data['created_at'] = self.release.created_at.replace(tzinfo=datetime.timezone.utc).isoformat()
        data['published_at'] = self.release.published_at.replace(tzinfo=datetime.timezone.utc).isoformat()
        data['files'] = []
        for i in self.release.get_assets():
            file = {}
            file['name'] = i.name
            file['size'] = i.size
            file['url'] = i.browser_download_url
            data['files'].append(file)
        payload = json.dumps(data, indent=2, default=str)
        headers = self.gen_http_headers()
        result = 0
        for url in self.notify_servers:
            if self.verbose > 0:
                print('Notification website: %s' % url)
            if self.verbose > 1:
                print('The POST data is: \n%s' % payload)
            result += send_post_to_url(url, payload, headers)
        if result > 0:
            print_error('We can not send post to all urls')
            sys.exit(1)

def send_post_to_url(url, payload, headers={}):
    nonce = str(uuid.uuid4()).replace('-','').upper()
    if type(payload) == str:
        body = payload
    else:
        body = json.dumps(payload, indent=2, default=str)

    secret = os.getenv('API_SECRET', '')
    if not secret:
        print_info('Please set the "API_SECRET" environment variable for secure transfer.')
    else:
        data = nonce + body
        signature = hmac.new(bytes(secret, 'utf8'), msg = bytes(data, 'utf8'), digestmod = hashlib.sha256)
        sign = signature.hexdigest().upper()
        headers['X-Build-Signature'] = sign

    headers['X-Build-Nonce'] = nonce
    try:
        r = requests.post(url, data=body, headers=headers)
        if r.status_code != 200:
            print_error('Visit {} : {} {}'.format(url, r.status_code, r.reason))
            return 1
        else:
            print('%s has been notified' % url)
            return 0
    except requests.exceptions.ConnectionError as error:
        print_error('Connect Error {} : {}'.format(url, error))
        return 1

class bcolors:
    CEND    = '\33[0m'
    CRED    = '\33[31m'
    CBOLD   = '\33[1m'
    CGREEN  = '\33[32m'
    CBLUE   = '\33[34m'

def _color_print(color, msg):
    print(color + msg + bcolors.CEND)

def print_info(msg):
    _color_print(bcolors.CGREEN, msg)

def print_cmdline(msg):
    _color_print(bcolors.CBLUE, ">>> [%s] <<<" % msg)

def print_error(msg):
    _color_print(bcolors.CRED, '!!! ERROR: %s' % msg)

def gen_checksum(path):
   fobj = open(path, 'rb')
   fobj.seek(0)
   sha256sum = hashlib.sha256(fobj.read()).hexdigest()
   fobj.close()

   base_name = os.path.basename(path)
   sum_path = os.path.join('{}.sha256sum'.format(base_name))
   sobj = open(sum_path, 'w+')
   sobj.write('{}  {}\n'.format(sha256sum, base_name))
   sobj.close()
   return sum_path

def parse_args():
    parser = argparse.ArgumentParser(description='Compile the software in a Docker container')
    parser.add_argument('-c', '--config',  dest='config', metavar='FILE', action='store', default='.docker-build.yml', help='The config file (default is ".docker-build.yml")')
    parser.add_argument('-n', '--name',  dest='name', metavar='IMAGE', action='store', default='fedora', help='Docker image name (default is "fedora")')
    parser.add_argument('-l', '--limit',  dest='limit', metavar='N', action='store', type=int, default=100, help='Limit the number of output lines (default is 100)')
    parser.add_argument('-s', '--shell', dest='shell', action='store_true', help='Run interactive bash in the docker container.')
    parser.add_argument('-v', '--verbose', dest='verbose', action='count', default=0, help='Verbose output, the number of output lines is not limited')
    parser.add_argument('-i', '--install', dest='install', action='store_true', help='Install dependent packages in docker container.')
    parser.add_argument('-b', '--build', dest='build', metavar='autotools|meson|scripts', action='append', help='Compile the software in docker container.')
    parser.add_argument('-r', '--release', dest='release', metavar='github|scripts', action='append', help='Release the tarballs.')
    parser.add_argument('-t', '--tag', dest='tag', action='store', help='Release based on which tag.(default to use "TRAVIS_TAG" envirment variable)')
    parser.add_argument('--version', dest='version', action='store_true', help='Show the version')
    parser.add_argument('-C', '--clean', dest='clean', action='store_true', help='Clean up the docker container.')

    return parser.parse_args()

def load_config (cfgfile):
    cfg = {}
    if os.path.isfile(cfgfile):
        fp = open(cfgfile)
        if cfgfile.endswith(".yml") or cfgfile.endswith(".yaml"):
            cfg = yaml.load(fp)
        elif cfgfile.endswith(".js") or cfgfile.endswith(".json"):
            cfg = json.load(fp)
        fp.close()
    return cfg

def run_cmd(command, opts):
    print_cmdline(command)
    if command.startswith('docker exec') or command.startswith(opts['host_dir']):
        sh = command.split()[-1].strip()
        shpath = os.path.join(opts['host_dir'], os.path.basename(sh))
        if os.path.isfile(shpath):
            if os.getuid() == 0:
                prompt = '#'
            else:
                prompt = '$'
            print('%s cat %s' % (prompt, sh))
            print(open(shpath).read())
            print('%s %s' % (prompt, sh))

    result = Result()
    io = ShortIO(opts['limit'])
    if opts['stage'] == 'source_build' or opts['stage'] == 'build_scripts':
        if opts['verbose'] > 0:
            io = ShortIO()
    elif opts['stage'] == 'after_scripts':
        if opts['verbose'] > 1:
            io = ShortIO()
    elif opts['stage'] == 'before_scripts':
        if opts['verbose'] > 2:
            io = ShortIO()
    elif opts['stage'] == 'system_install':
        if opts['verbose'] > 3:
            io = ShortIO()
    p = subprocess.Popen(shlex.split(command), stdout=subprocess.PIPE, bufsize=1)
    for line in iter(p.stdout.readline, b''):
        io.print(line.decode('utf-8'))
    io.end()
    p.stdout.close()
    p.wait()

    result.exit_code = p.returncode
    if opts['verbose'] > 0 and p.returncode != 0:
        print_error('run command [%s].' % command)
    result.command = command

    return result

def docker_pull (opts):
    image_name = opts['image_name']
    opts['stage'] = 'docker_pull'
    cmd = "docker pull %s" % image_name
    result = run_cmd (cmd, opts)
    if result.exit_code != 0:
        sys.exit(1)

def docker_run_daemon (command, opts):
    container_name = opts['container_name']
    host_dir = opts['host_dir']
    image_name = opts['image_name']
    opts['stage'] = 'docker_run_daemon'

    cmd = "docker run --name %s --volume %s:%s -t -d %s %s" % (container_name, host_dir, ROOT_DIR, image_name, command)
    result = run_cmd (cmd, opts)
    if result.exit_code != 0:
        sys.exit(1)

def docker_exec (command, opts):
    container_name = opts['container_name']
    cmd = "docker exec -t %s %s" % (container_name, command)
    result = run_cmd (cmd, opts)
    if result.exit_code != 0:
        sys.exit(1)

def docker_is_running (opts):
    opts['stage'] = 'docker_is_running'
    cmd = "docker inspect -f '{{.State.Running}}' %s" % opts['container_name']
    result = run_cmd (cmd, opts)
    return result.exit_code == 0

def docker_kill (opts):
    opts['stage'] = 'docker_kill'
    cmd = "docker container kill %s" % opts['container_name']
    result = run_cmd (cmd, opts)
    if result.exit_code != 0:
        sys.exit(1)

def docker_rm (opts):
    opts['stage'] = 'docker_rm'
    cmd = "docker container rm %s" % opts['container_name']
    result = run_cmd (cmd, opts)
    if result.exit_code != 0:
        sys.exit(1)

# The follow commands running in the docker.
def system_shell(opts):
    opts['stage'] = 'system_shell'
    if docker_is_running (opts):
        cmd = "docker exec -it %s /bin/bash" % opts['container_name']
        os.system(cmd)
    else:
        print_error('The docker container "%s" is not running.' % opts['container_name'])

def system_update (opts):
    if not opts['travis']:
        host_hook_path = os.path.join(opts['host_dir'], HOOK_NAME)
        user_hook_path = os.path.expanduser('~/.%s' % HOOK_NAME)
        if not os.path.isfile(host_hook_path) and os.path.isfile(user_hook_path):
            shutil.copy(user_hook_path, host_hook_path)
        if os.path.isfile(host_hook_path):
            os.chmod(host_hook_path, stat.S_IRWXU |stat.S_IRGRP | stat.S_IXGRP | stat.S_IROTH | stat.S_IXOTH)
            cmd = '%s %s' % (os.path.join(ROOT_DIR, HOOK_NAME), opts['distro_name'])
            opts['stage'] = HOOK_NAME
            docker_exec (cmd, opts)
    opts['stage'] = 'system_update'
    docker_exec (opts['distro_upgrade'], opts)

def system_install (opts):
    if 'requires' not in opts['config'].keys():
        return

    opts['stage'] = 'system_install'
    distro_name = opts['distro_name']
    if distro_name in opts['config']['requires'].keys():
        distro_requires = opts['config']['requires'][distro_name]
        if distro_requires:
            requires = ' '.join(distro_requires)
        else:
            requires = 'gcc git make'
        cmd = '%s %s' % (opts['install_command'], requires)
        docker_exec (cmd, opts)
        # list versions of the required packages installed
        if distro_name == 'debian' or distro_name == 'ubuntu':
            docker_exec ("apt list --installed %s" % requires, opts)
        if distro_name == 'archlinux':
            docker_exec ("pacman -Q %s" % requires, opts)
        if distro_name == 'fedora':
            docker_exec ("dnf list installed %s" % requires, opts)

def get_repo_name(join_char=None):
    cmd = 'git remote get-url origin'
    output = subprocess.check_output(cmd, shell=True)
    output = output.decode("utf-8").strip()

    output_slice = output.split('/')
    repo = output_slice[-1]
    owner = output_slice[-2]

    if repo.endswith('.git'):
        repo = repo[:-4]
    if owner.find(':') >=0:
        owner = owner.split(':')[-1]
    if join_char is None:
        return (owner, repo)
    else:
        return join_char.join([owner, repo])

def create_script(script, cmdline, opts):
    opts['stage'] = script
    shpath = os.path.join(opts['host_dir'], script)
    fp = open(shpath, 'w+')
    fp.write('#!/bin/bash\n')
    fp.write('set -e\n')
    if not opts['travis']:
        fp.write('set -o pipefail\n')
    if opts['verbose']:
        fp.write('set -x\n\n')

    # Import TRAVIS_* envirment variables
    travis_envs = (
            'TRAVIS_BRANCH',
            'TRAVIS_BUILD_ID',
            'TRAVIS_BUILD_NUMBER',
            'TRAVIS_BUILD_WEB_URL',
            'TRAVIS_COMMIT',
            'TRAVIS_COMMIT_MESSAGE',
            'TRAVIS_COMMIT_RANGE',
            'TRAVIS_EVENT_TYPE',
            'TRAVIS_JOB_ID',
            'TRAVIS_JOB_NAME',
            'TRAVIS_JOB_NUMBER',
            'TRAVIS_JOB_WEB_URL',
            'TRAVIS_PULL_REQUEST',
            'TRAVIS_PULL_REQUEST_BRANCH',
            'TRAVIS_PULL_REQUEST_SHA',
            'TRAVIS_PULL_REQUEST_SLUG',
            'TRAVIS_REPO_SLUG',
            'TRAVIS_SECURE_ENV_VARS',
            'TRAVIS_TAG',
            'TRAVIS_UID',
            )
    for var in travis_envs:
        if var in os.environ.keys():
            if var == 'TRAVIS_COMMIT_MESSAGE':
                raw_msg = os.environ[var]
                new_msg = raw_msg.replace("'", "\'\\\'\'")
                fp.write ("export %s='%s'\n" % (var, new_msg))
            elif var in ['TRAVIS_BUILD_ID', 'TRAVIS_BUILD_NUMBER', 'TRAVIS_JOB_ID', 'TRAVIS_UID']:
                fp.write ("export %s=%s\n" % (var, os.environ[var]))
            else:
                fp.write ("export %s='%s'\n" % (var, os.environ[var]))

    # Setup envirment variables
    if 'variables' in opts['config'].keys():
        if type(opts['config']['variables']) == list:
            for var in opts['config']['variables']:
                if var.find('=') > 0:
                    fp.write ("export %s\n" % var)

    # export option setup as envirment variables
    for k, v in opts.items():
        if k in ['config', 'distro_upgrade', 'install_command', 'host_dir', 'image_name', 'stage', 'new_tag', 'verbose', 'stage', 'image_name', 'limit']:
            continue
        if isinstance(v, list):
            fp.write ("export %s=\"%s\"\n" % (k.upper(), ' '.join(v)))
        else:
            fp.write ("export %s=%s\n" % (k.upper(), str(v).lower()))

    # export cpu count as envirment variables
    cpu_count = multiprocessing.cpu_count()
    fp.write ("export CPU_COUNT=%d\n" % cpu_count)
    fp.write('\n')

    if isinstance(cmdline, str):
        fp.write('%s\n' % cmdline)
    elif isinstance(cmdline, list):
        for line in cmdline:
            if line is not None:
                fp.write('%s\n' % line)

    uid = os.getenv("TRAVIS_UID")
    if uid is not None:
        travis_uid = int(uid)
        fp.write('if [ $UID -eq 0 -a -d %s ];then\n' % opts['start_dir'])
        fp.write('    chown -R %d %s\n' % (travis_uid, opts['start_dir']))
        fp.write('fi\n')
    fp.close()
    os.chmod(shpath, stat.S_IRWXU |stat.S_IRGRP | stat.S_IXGRP | stat.S_IROTH | stat.S_IXOTH)

def setup_options(args, config):
    option = {
            'build_type' : 'autotools',
            'distro_name' : 'fedora',
            'distro_version' : 'latest',
            'stage' : 'default',
            'image_name' : args.name,
            'limit' : args.limit,
            'host_dir' : os.getcwd(),
            'start_dir' : ROOT_DIR,
            'build_dir' : ROOT_DIR,
            'verbose' : args.verbose,
            'config' : config,
            'new_tag' : '',
            'travis' : bool(os.getenv("TRAVIS")),
            }

    if option['travis']:
        option['host_dir'] = os.path.dirname(os.path.abspath(__file__))

    # Remove duplicate elements from args.build
    if args.build:
        args.build = sorted(set(args.build), key=args.build.index)

    if args.release:
        if args.tag:
            option['new_tag'] = args.tag
        else:
            option['new_tag'] = os.getenv('TRAVIS_TAG', '')

    # parse distro
    distro = args.name.split(':')
    distro_name = distro[0]
    if distro_name.find('archlinux') >= 0:
        distro_name = 'archlinux'
    elif distro_name.find('/') > 0:
        distro_name = distro_name.rsplit('/',1)[-1]

    option['distro_name'] = distro_name
    option['owner_name'] = get_repo_name()[0]
    option['repo_name'] = get_repo_name()[1]
    option['container_name'] = "%s-%s-build" % (option['repo_name'], option['distro_name'])
    if distro_name == 'archlinux':
        option['distro_upgrade'] = 'pacman -Syu --noconfirm'
        option['install_command'] = 'pacman -Sy --noconfirm'
    elif distro_name == 'centos':
        option['distro_upgrade'] = 'yum update -y'
        option['install_command'] = 'yum install -y'
    elif distro_name == 'fedora':
        option['distro_upgrade'] = 'dnf update -y'
        option['install_command'] = 'dnf install -y'
    elif distro_name == 'debian' or distro_name == 'ubuntu':
        option['distro_upgrade'] = 'apt-get update -y'
        option['install_command'] = 'env DEBIAN_FRONTEND=noninteractive apt-get install -y'
    else:
        msg = 'The "%s" distro is not supported, please visit "%s" to create a new issue.' % (distro_name, ISSUE_URL)
        print_error(msg)
        sys.exit(1)

    if len(distro) > 1:
        option['distro_version'] = distro[-1]

    return option

# Run in docker
def run_scripts(opts, stage = 'before'):
    script_name = stage + '_scripts'
    if script_name not in opts['config'].keys():
        return
    if type(opts['config'][script_name]) == list:
        cmdlines = opts['config'][script_name]
        cmdlines.insert(0, 'cd %s' % ROOT_DIR)
        create_script(script_name, cmdlines, opts)
        docker_exec(os.path.join(ROOT_DIR, script_name), opts)

def autotools_build (opts):
    configures = '--prefix=/usr'
    if 'configures' in opts['config'].keys() and 'autotools' in opts['config']['configures'].keys():
        if type(opts['config']['configures']['autotools']) == list:
            configures = ' '.join(opts['config']['configures']['autotools'])

    cmdlines = ['cd %s' % ROOT_DIR]
    if os.path.isfile('./autogen.sh') or os.path.isfile('./configure'):
        cpu_count = multiprocessing.cpu_count()
        if opts['travis']:
            if os.path.isfile('./autogen.sh'):
                cmdlines.append('./autogen.sh ' + configures)
            elif os.path.isfile('./configure'):
                cmdlines.append('./configure ' + configures)
            if cpu_count > 1:
                cmdlines.append('make -j {}'.format(cpu_count))
            else:
                cmdlines.append('make')
        else:
            cmdlines.append('if which tee;then')
            if os.path.isfile('./autogen.sh'):
                cmdlines.append('./autogen.sh {} 2>&1 | tee {}-autogen.logs'.format(configures, opts['repo_name']))
            elif os.path.isfile('./configure'):
                cmdlines.append('./configure {} 2>&1 | tee {}-configure.logs'.format(configures, opts['repo_name']))
            cmdlines.append('make clean > /dev/null')
            if cpu_count > 1:
                cmdlines.append('make -j {} 2>&1 | tee {}-make.logs'.format(cpu_count, opts['repo_name']))
            else:
                cmdlines.append('make 2>&1 | tee {}-make.logs'.format(opts['repo_name']))
            cmdlines.append('else')
            if os.path.isfile('./autogen.sh'):
                cmdlines.append('./autogen.sh {}'.format(configures))
            elif os.path.isfile('./configure'):
                cmdlines.append('./configure {}'.format(configures))
            cmdlines.append('make clean > /dev/null')
            if cpu_count > 1:
                cmdlines.append('make -j {}'.format(cpu_count))
            else:
                cmdlines.append('make')
            cmdlines.append('fi')
        create_script ('source_build', cmdlines, opts)
        docker_exec(os.path.join(ROOT_DIR, 'source_build'), opts)

def meson_build (opts):
    configures = '--prefix /usr'
    if 'configures' in opts['config'].keys() and 'meson' in opts['config']['configures'].keys():
        if type(opts['config']['configures']['meson']) == list:
            configures = ' '.join(opts['config']['configures']['meson'])

    cmdlines = ['cd %s' % ROOT_DIR]
    if os.path.isfile('./meson.build'):
        if opts['travis']:
            cmdlines.append('meson {} {}'.format(MESON_BUILD_DIRNAME, configures))
            cmdlines.append('cd {}'.format(MESON_BUILD_DIRNAME))
            cmdlines.append('ninja')
        else:
            cmdlines.append('[ -d {} ] && rm -rf {}'.format(MESON_BUILD_DIRNAME, MESON_BUILD_DIRNAME))
            cmdlines.append('meson {} {} 2>&1 | tee {}-meson.logs'.format(MESON_BUILD_DIRNAME, configures, opts['repo_name']))
            cmdlines.append('cd {}'.format(MESON_BUILD_DIRNAME))
            cmdlines.append('ninja 2>&1 | tee {}-ninja.logs'.format(opts['repo_name']))
        create_script ('source_build', cmdlines, opts)
        docker_exec(os.path.join(ROOT_DIR, 'source_build'), opts)

def source_build(build_type, opts):
    opts['build_type'] = build_type
    if build_type == 'meson':
        opts['build_dir'] = os.path.join(opts['start_dir'], MESON_BUILD_DIRNAME)
    else:
        opts['build_dir'] = opts['start_dir']

    run_scripts(opts, 'before')
    if build_type == 'autotools':
        autotools_build (opts)
    elif opts['build_type'] == 'meson':
        meson_build (opts)
    elif opts['build_type'] == 'scripts':
        run_scripts(opts, 'build')
    else:
        print_info ('Build system "%s" is not supported.' % build_type)
    run_scripts(opts, 'after')

def gen_release_file_lists(opts):
    checksum = False
    file_glob = False
    file_list = []
    if 'releases' in opts['config'].keys():
        if 'checksum' in opts['config']['releases'].keys():
            checksum = bool(opts['config']['releases']['checksum'])
        if 'file_glob' in opts['config']['releases'].keys():
            file_glob = bool(opts['config']['releases']['file_glob'])
        if 'files' in opts['config']['releases'].keys():
            files = opts['config']['releases']['files']
            if type(files) == str:
                if file_glob:
                    file_list.extend(glob.glob(files))
                else:
                    file_list.append(files)
            elif type(files) == list:
                if file_glob:
                    for i in files:
                        file_list.extend(glob.glob(i))
                else:
                    file_list.extend(files)
    for i in file_list:
        if not os.path.isfile(i):
            print_error('The file "%s" does not exists! Ignore it.'.format(i))
            file_list.remove(i)
    if checksum:
        checksum_list = []
        for i in file_list:
            checksum_list.append(gen_checksum(i))
        file_list.extend(checksum_list)
    return file_list

def init_release_config(opts):
    opts['draft'] = False
    opts['prerelease'] = False
    opts['file_lists'] = gen_release_file_lists(opts)
    if 'releases' in opts['config'].keys():
        if 'draft' in opts['config']['releases'].keys():
            opts['draft'] = bool(opts['config']['releases']['draft'])

        if 'prerelease' in opts['config']['releases'].keys():
            opts['prerelease'] = bool(opts['config']['releases']['prerelease'])

def scripts_release(opts):
    script_name = 'scripts_release'
    cmd = os.path.join(opts['host_dir'], script_name)
    if 'releases' in opts['config'].keys() and 'scripts_release' in opts['config']['releases'].keys():
        if type(opts['config']['releases']['scripts_release']) == list:
            cmdlines = opts['config']['releases']['scripts_release']
            cmdlines.insert(0, 'cd %s' % opts['host_dir'])
            create_script(script_name, cmdlines, opts)
            result = run_cmd (cmd, opts)
            if result.exit_code != 0:
                sys.exit(1)

def release(release_type, opts):
    if release_type == 'github':
        opts['stage'] = 'github_release'
        hub = Github(opts)
        if hub.Login():
            hub.Release()
        else:
            print_error('Github release failed.')
            sys.exit(1)
    elif release_type == 'scripts':
        scripts_release(opts)
    else:
        msg = 'The "%s" release is not supported, please visit "%s" to create a new issue.' % (release_type, ISSUE_URL)
        print_error(msg)
        sys.exit(1)

if __name__=="__main__":
    args = parse_args()
    config = load_config(args.config)
    opts = setup_options(args, config)

    if args.version:
        print(os.path.basename(sys.argv[0]), VERSION)
        sys.exit(0)

    if opts['verbose'] > 0:
        print(os.path.basename(sys.argv[0]), VERSION)

    if args.shell:
        system_shell(opts)
        sys.exit(0)

    if args.install:
        docker_pull(opts)
        if not docker_is_running (opts):
            docker_run_daemon('/bin/bash', opts)
        system_update(opts)
        system_install(opts)

    if args.build:
        for i in args.build:
            source_build(i, opts)

    if args.release:
        init_release_config(opts)
        for i in args.release:
            release(i, opts)

    if args.clean:
        if docker_is_running (opts):
            docker_kill (opts)
        docker_rm (opts)
