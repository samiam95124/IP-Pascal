rem cmpr testfile.cmp testfile > cmpr.run
rem dcpr testfile.lst testfile.cmp > dcpr.run

cmpr testfile.cmp testfile
dcpr testfile.lst testfile.cmp

\pascal\misc\diff testfile testfile.lst

rem del testfile.zip
rem pkzip -add testfile testfile