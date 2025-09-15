rem
rem Construct bug3 using new encoder
rem

..\parser\parse bug3=bug3/nrf
encode bug3=bug3

rem
rem perform link for windows
rem

rem ln runfile=c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\main bug3 c:\ip\windows\i80386\lib\cap/nu
rem genpe bug3=runfile/v/sc
rem del runfile.*
