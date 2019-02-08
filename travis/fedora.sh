#!/bin/bash

cat > /tmp/clang_with_python_fix.patch  <<EOF
diff -u os/usr/lib64/python3.7/_sysconfigdata_m_linux_x86_64-linux-gnu.py os/usr/lib64/python3.7/_sysconfigdata_m_linux_x86_64-linux-gnu.py
--- os.orig/usr/lib64/python3.7/_sysconfigdata_m_linux_x86_64-linux-gnu.py	2019-02-23 09:59:04.103230256 +0000
+++ os/usr/lib64/python3.7/_sysconfigdata_m_linux_x86_64-linux-gnu.py	2019-02-23 09:59:29.133695204 +0000
@@ -612,7 +612,7 @@
         '-Wp,-D_GLIBCXX_ASSERTIONS -fexceptions -fstack-protector-strong '
         '-grecord-gcc-switches -specs=/usr/lib/rpm/redhat/redhat-hardened-cc1 '
         '-specs=/usr/lib/rpm/redhat/redhat-annobin-cc1 -m64 -mtune=generic '
-        '-fasynchronous-unwind-tables -fstack-clash-protection -fcf-protection '
+        '-fasynchronous-unwind-tables -fcf-protection '
         '-D_GNU_SOURCE -fPIC -fwrapv',
  'OTHER_LIBTOOL_OPT': '',
  'PACKAGE_BUGREPORT': 0,
EOF

cd /
patch -p1 -ti /tmp/clang_with_python_fix.patch
