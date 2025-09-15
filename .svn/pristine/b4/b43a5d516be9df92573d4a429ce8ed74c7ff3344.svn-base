@echo off
rem @echo off
rem
rem Compile a program for use with the serial level library
rem
parse hello=hello #u=.,\ip\windows\i80386\lib\
ce hello=hello
ln runfile=serlib c:\ip\linux\i80386\lib\strlib extlib hello cap #ps=$8048074 #vs=$8054678 #ll #lv #lm > hello.lst
genelf hello=runfile /v
