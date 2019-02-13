#!/bin/bash

cat > /tmp/intltool_debian_fix.patch  <<EOF
Based on the patch https://src.fedoraproject.org/rpms/intltool/raw/master/f/intltool_distcheck-fix.patch
diff -upr os/usr/bin/intltool-update os/usr/bin/intltool-update
--- os-orig/usr/bin/intltool-update	2016-07-29 14:08:06.276987000 +0200
+++ os/usr/bin/intltool-update	2016-07-29 14:11:09.562126918 +0200
@@ -620,6 +620,14 @@ sub FindLeftoutFiles
 
     my @result;
 
+    # If the builddir is a subdir of srcdir, the list of files found will be prefixed with
+    # an additional prefix (e.g. "_build/sub" for automake 1.15 make distcheck). Try to
+    # handle that, by removing those matches as well.
+    my \$absbuilddir = Cwd::abs_path("..\/");
+    my \$abssrcdir = Cwd::abs_path("\$SRCDIR/..");
+    # Check if builddir is a subdir of srcdir
+    my (\$abspath,\$relpath) = split /\s*\$abssrcdir\/\s*/, \$absbuilddir, 2;
+
     foreach (@buf_allfiles_sorted)
     {
         my \$dummy = \$_;
@@ -628,7 +636,10 @@ sub FindLeftoutFiles
         \$srcdir =~ s#^../##;
         \$dummy =~ s#^\$srcdir/../##;
         \$dummy =~ s#^\$srcdir/##;
-        \$dummy =~ s#_build/##;
+        if (\$relpath)
+        {
+            \$dummy =~ s#^\$relpath/##;
+        }
 	if (!exists(\$in2{\$dummy}))
 	{
 	    push @result, \$dummy
EOF

cd /
patch -p1 -ti /tmp/intltool_debian_fix.patch
