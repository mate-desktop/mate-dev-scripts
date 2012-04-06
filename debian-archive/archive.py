#!/usr/bin/env python
import optparse
import os
import sys

parser = optparse.OptionParser()
parser.add_option("-v", "--version", dest="version", help="set upstream version")
parser.add_option("-o", "--orig", dest="orig", action="store_true", help="rename file to use with debuild")
(options, args) = parser.parse_args()

if len(args) == 0:
    print "E: No package given!"
    sys.exit(1)
elif len(args) > 1:
    print "E: Too many packages given!"
    sys.exit(1)

package = args[0]

if package[-1] == "/":
    print "E: Package name is a directory!"
    sys.exit(1)

if not os.path.exists(package + "/"):
    print "E: Package not found!"
    sys.exit(1)

if options.version is None:
    print "E: Package version not set!"
    sys.exit(1)

version = options.version

print "I:", package, options.version

os.system("cp %(package)s/ %(package)s-%(version)s/ -R" % {"package": package, "version": version})
os.system("rm -rf %(package)s-%(version)s/.git" % {"package": package, "version": version})
os.system("rm -rf %(package)s-%(version)s/.tx" % {"package": package, "version": version})
os.system("rm -rf %(package)s-%(version)s/distro" % {"package": package, "version": version})
os.system("tar cf %(package)s-%(version)s.tar %(package)s-%(version)s/" % {"package": package, "version": version})
#os.system("bzip2 %(package)s-%(version)s.tar" % {"package": package, "version": version})
os.system("xz --compress %(package)s-%(version)s.tar" % {"package": package, "version": version})
os.system("rm -rf %(package)s-%(version)s/" % {"package": package, "version": version})
if options.orig:
    #os.system("mv %(package)s-%(version)s.tar.bz2 %(package)s_%(version)s.orig.tar.bz2" % {"package": package, "version": version})
    os.system("mv %(package)s-%(version)s.tar.xz %(package)s_%(version)s.orig.tar.xz" % {"package": package, "version": version})
