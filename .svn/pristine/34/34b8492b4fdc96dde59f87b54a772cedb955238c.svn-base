@echo off
rem ****************************************************************************
rem
rem                          Compiler and link serlib
rem
rem We turn off several checking options to make the code
rem reasonable to debug
rem
rem Assemble assembly level files
rem
as startup=startup
as memman=memman
as devcal=devcal
rem
rem Parse Pascal level files
rem
parse devreg=devreg
parse devmda=devmda
parse devlog=devlog
parse syslib=syslib
rem
rem Encode the files for i80386
rem
ec devreg=devreg /nnpc/nclcl/noc/nrc/nurl
ec devmda=devmda /nnpc/nclcl/noc/nrc/nurl
ec devlog=devlog /nnpc/nclcl/noc/nrc/nurl
ec syslib=syslib /nnpc/nclcl/noc/nrc/nurl
rem
rem put serlib together
rem
ln serlib=startup memman devcal devreg devmda devlog syslib \projects\pascomp\comlib\paslib
