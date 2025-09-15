@echo off
rem
rem Construct test using new encoder
rem

..\parser\parse test=test/nrf
..\parser\parse test1=test1/nrf
rem encode test=test/noc/sls
rem encode test=test/noc/nac/sls
rem encode test=test/noc/nac/sls/nounroll
rem encode test=test/nsls
rem encode test=test/noc/nurl/nfco/ndce/nb2j/nrur/nsls
rem ec test=test
encode test=test
encode test1=test1
rem encode test=test/cl/srcl/rl/gl
rem encode test=test/noc/nac/sls/nounroll/nnpc

rem as maclib=maclib
c:\projects\assm\i80586\as /nl libthunk=libthunk

rem
rem perform link for windows
rem

c:\projects\assm\ln\ln runfile=maclib c:\projects\pascomp\windows_platform\serlib libthunk c:\ip\windows\i80386\lib\main test1 test c:\ip\windows\i80386\lib\cap /ps=$401000 /vs=$418000 /lv /ll /lm > test.loc
rem ln runfile=maclib c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\main test c:\ip\windows\i80386\lib\cap/nu
rem ln runfile=c:\ip\windows\i80386\lib\serlibx c:\ip\windows\i80386\lib\main test c:\ip\windows\i80386\lib\cap/nu
rem ln runfile=c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\main test c:\ip\windows\i80386\lib\cap #ps=$401000 #vs=$419000 #lv #ll #lm > test.loc
c:\projects\assm\windows\genpe test=runfile/v/sc
del runfile.*
