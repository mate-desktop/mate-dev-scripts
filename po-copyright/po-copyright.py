#!/usr/bin/python

import os
import sys

HEADER_FORMAT = "========== {} ==========\n"

# Make sure the correct number of args were given.
if len(sys.argv) < 2:
    print "Please specify the path to po/"
    sys.exit(1)
    
os.chdir(sys.argv[1])

copyright = open("gnome-copyrights.txt", "w")

files = [f for f in sorted(os.listdir(os.curdir)) if f[-3:] == ".po"]

for f in files:
    po = open(f, "r")
        
    copyright.write(HEADER_FORMAT.format(f))
    
    line = po.readline()
    while line.startswith("#"):
        copyright.write(line)
        line = po.readline()

    po.close()        

    copyright.write("\n\n\n\n")

copyright.close()



 
    
