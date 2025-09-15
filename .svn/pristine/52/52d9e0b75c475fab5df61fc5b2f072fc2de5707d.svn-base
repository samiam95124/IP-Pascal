@echo off
rem
rem Compile the test, and produce a blonde image binary
rem
parse test=test
ec test=test /nnpc/nclcl/noc/nrc/nurl
ln testi=serlib test c:\ip\windows\i80386\lib\cap /ps=$1000/lv > test.lst
rem
rem Copy the test object, which is completely linked, into a binary
rem
copy testi.obj test.bin
rem
rem construct VO disk image
rem
call cboot