rem
rem Construct bug1 using new encoder
rem

..\pparse\parse bug1=bug1/nrf
encode bug1=bug1/nfpuc

as maclib=maclib

rem
rem perform link for windows
rem

rem ln runfile=c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\main bug1 c:\ip\windows\i80386\lib\cap/nu
ln runfile=maclib c:\projects\pascomp\windows\serlib c:\ip\windows\i80386\lib\main bug1 c:\ip\windows\i80386\lib\cap/nu
genpe bug1=runfile/v/sc
del runfile.*
