#! /usr/bin/bash

# Author: Steve Zesch

import urllib2
import sys

# URLs to open and get deprecated symbols from.
urls = ['http://developer.gnome.org/gdk/stable/api-index-deprecated.html',
        'http://developer.gnome.org/gtk/stable/api-index-deprecated.html',
        'http://developer.gnome.org/gdk-pixbuf/stable/api-index-deprecated.html']

# Try to open a url
for u in urls:
    try:
        response = urllib2.urlopen(u)
    except urllib2.HTTPError, e:
        print 'The server couldn\'t fufill the request.'
        print 'Error code: ', e.code
        sys.exit()
    except urllib2.URLError, e:
        print 'We failed to reach the server.'
        print 'Reason: ', e.reason
        sys.exit()

    html_line = response.readline()

    while html_line: 
       print html_line
       html_line = response.readline()
