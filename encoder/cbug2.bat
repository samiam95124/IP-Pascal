rem
rem Construct bug2 using new encoder
rem

..\parser\parse bug2=bug2/nrf
encode bug2=bug2

rem
rem perform link for windows
rem

rem ln runfile=c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\main bug2 c:\ip\windows\i80386\lib\cap/nu
rem genpe bug2=runfile/v/sc
rem del runfile.*
