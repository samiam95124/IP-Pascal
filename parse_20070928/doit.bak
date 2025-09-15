rem
rem Compile parser
rem

rem 
rem Compile with demo limits off
rem
copy demo_disable.pas demo.pas

rem
rem Use this parser for self checking
rem

rem parse xltlib=xltlib /u=.,\ip\windows\i80386\lib
rem parse common=common /u=.,\ip\windows\i80386\lib
rem parse parsesvs=parsesvs /u=.,\ip\windows\i80386\lib
rem parse scanner=scanner /u=.,\ip\windows\i80386\lib
rem parse symbol=symbol /u=.,\ip\windows\i80386\lib
rem parse parser=parser /u=.,\ip\windows\i80386\lib
rem parse parse=parse /u=.,\ip\windows\i80386\lib

rem
rem Use the main parser
rem

c:\ip\windows\i80386\bin\parse xltlib=xltlib /u=.,\ip\windows\i80386\lib
c:\ip\windows\i80386\bin\parse common=common /u=.,\ip\windows\i80386\lib
c:\ip\windows\i80386\bin\parse parsesvs=parsesvs /u=.,\ip\windows\i80386\lib
c:\ip\windows\i80386\bin\parse scanner=scanner /u=.,\ip\windows\i80386\lib
c:\ip\windows\i80386\bin\parse symbol=symbol /u=.,\ip\windows\i80386\lib
c:\ip\windows\i80386\bin\parse parser=parser /u=.,\ip\windows\i80386\lib
c:\ip\windows\i80386\bin\parse parse=parse /u=.,\ip\windows\i80386\lib

rem
rem Compile with countermeasures
rem

ec xltlib=xltlib/noc/nrc/nac/nclcl/scxt/discm
ec common=common/noc/nrc/nac/nclcl/scxt/discm
ec parsesvs=parsesvs/noc/nrc/nac/nclcl/scxt/discm
ec scanner=scanner/noc/nrc/nac/nclcl/scxt/discm
ec symbol=symbol/noc/nrc/nac/nclcl/scxt/discm
ec parser=parser/noc/nrc/nac/nclcl/scxt/discm
ec parse=parse/noc/nrc/nac/nclcl/scxt/discm

rem
rem Compile normal
rem

rem ec xltlib=xltlib/noc/nrc/nac/nclcl
rem ec common=common/noc/nrc/nac/nclcl
rem ec parsesvs=parsesvs/noc/nrc/nac/nclcl
rem ec scanner=scanner/noc/nrc/nac/nclcl
rem ec symbol=symbol/noc/nrc/nac/nclcl
rem ec parser=parser/noc/nrc/nac/nclcl
rem ec parse=parse/noc/nrc/nac/nclcl

rem
rem perform link for windows
rem

rem ln runfile=c:\ip\windows\i80386\lib\blotter c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\strlib c:\ip\windows\i80386\lib\extlib xltlib common parsesvs scanner symbol parser c:\ip\windows\i80386\lib\main c:\ip\windows\i80386\lib\reglock c:\ip\windows\i80386\lib\timelock parse c:\ip\windows\i80386\lib\cap/nu/ll/lv/lm/lx/ps=$401000/vs=$46c000 > parse.lst
rem ln runfile=c:\ip\windows\i80386\lib\blotter c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\strlib c:\ip\windows\i80386\lib\extlib common parsesvs scanner symbol parser c:\ip\windows\i80386\lib\main c:\ip\windows\i80386\lib\reglock c:\ip\windows\i80386\lib\timelock parse c:\ip\windows\i80386\lib\cap/nu
rem ln runfile=c:\ip\windows\i80386\lib\blotter c:\ip\windows\i80386\lib\serlibx c:\ip\windows\i80386\lib\strlibx c:\ip\windows\i80386\lib\extlibx common parsesvs scanner symbol parser c:\ip\windows\i80386\lib\main c:\ip\windows\i80386\lib\reglockx c:\ip\windows\i80386\lib\timelockx parse c:\ip\windows\i80386\lib\cap/nu
ln runfile=c:\ip\windows\i80386\lib\serlibx c:\ip\windows\i80386\lib\strlibx c:\ip\windows\i80386\lib\extlibx common parsesvs scanner symbol parser c:\ip\windows\i80386\lib\main parse c:\ip\windows\i80386\lib\cap/nu
rem
rem Symbols version
rem
rem genpe parse=runfile/v/sc
genpe parse=runfile/v
rem del runfile.*

rem
rem perform link for linux
rem

rem ln runfile=c:\ip\linux\i80386\lib\serlib c:\ip\linux\i80386\lib\strlib c:\ip\linux\i80386\lib\extlib xltlib common parsesvs scanner symbol parser parse c:\ip\linux\i80386\lib\cap
rem genelf parse=runfile/v
rem del runfile.*

rem 
rem Compile with demo limits on
rem
copy demo_enable.pas demo.pas

rem
rem Use this parser for self checking
rem

rem parse xltlib=xltlib /u=.,\ip\windows\i80386\lib
rem parse common=common /u=.,\ip\windows\i80386\lib
rem parse parsesvs=parsesvs /u=.,\ip\windows\i80386\lib
rem parse scanner=scanner /u=.,\ip\windows\i80386\lib
rem parse symbol=symbol /u=.,\ip\windows\i80386\lib
rem parse parser=parser /u=.,\ip\windows\i80386\lib
rem parse parse=parse /u=.,\ip\windows\i80386\lib

rem
rem Use the main parser
rem

c:\ip\windows\i80386\bin\parse xltlib=xltlib /u=.,\ip\windows\i80386\lib
c:\ip\windows\i80386\bin\parse common=common /u=.,\ip\windows\i80386\lib
c:\ip\windows\i80386\bin\parse parsesvs=parsesvs /u=.,\ip\windows\i80386\lib
c:\ip\windows\i80386\bin\parse scanner=scanner /u=.,\ip\windows\i80386\lib
c:\ip\windows\i80386\bin\parse symbol=symbol /u=.,\ip\windows\i80386\lib
c:\ip\windows\i80386\bin\parse parser=parser /u=.,\ip\windows\i80386\lib
c:\ip\windows\i80386\bin\parse parse=parse /u=.,\ip\windows\i80386\lib

rem
rem Compile with countermeasures
rem

ec xltlib=xltlib/noc/nrc/nac/nclcl/scxt/discm
ec common=common/noc/nrc/nac/nclcl/scxt/discm
ec parsesvs=parsesvs/noc/nrc/nac/nclcl/scxt/discm
ec scanner=scanner/noc/nrc/nac/nclcl/scxt/discm
ec symbol=symbol/noc/nrc/nac/nclcl/scxt/discm
ec parser=parser/noc/nrc/nac/nclcl/scxt/discm
ec parse=parse/noc/nrc/nac/nclcl/scxt/discm

rem
rem Compile normal
rem

rem ec xltlib=xltlib/noc/nrc/nac/nclcl
rem ec common=common/noc/nrc/nac/nclcl
rem ec parsesvs=parsesvs/noc/nrc/nac/nclcl
rem ec scanner=scanner/noc/nrc/nac/nclcl
rem ec symbol=symbol/noc/nrc/nac/nclcl
rem ec parser=parser/noc/nrc/nac/nclcl
rem ec parse=parse/noc/nrc/nac/nclcl

rem
rem perform link for windows
rem

rem ln runfile=c:\ip\windows\i80386\lib\blotter c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\strlib c:\ip\windows\i80386\lib\extlib xltlib common parsesvs scanner symbol parser c:\ip\windows\i80386\lib\main c:\ip\windows\i80386\lib\reglock c:\ip\windows\i80386\lib\timelock parse c:\ip\windows\i80386\lib\cap/nu/ll/lv/lm/lx/ps=$401000/vs=$46c000 > parse.lst
rem ln runfile=c:\ip\windows\i80386\lib\blotter c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\strlib c:\ip\windows\i80386\lib\extlib common parsesvs scanner symbol parser c:\ip\windows\i80386\lib\main c:\ip\windows\i80386\lib\reglock c:\ip\windows\i80386\lib\timelock parse c:\ip\windows\i80386\lib\cap/nu
ln runfile=c:\ip\windows\i80386\lib\blotter c:\ip\windows\i80386\lib\serlibx c:\ip\windows\i80386\lib\strlibx c:\ip\windows\i80386\lib\extlibx common parsesvs scanner symbol parser c:\ip\windows\i80386\lib\main c:\ip\windows\i80386\lib\reglockx c:\ip\windows\i80386\lib\timelockx parse c:\ip\windows\i80386\lib\cap/nu
rem
rem Symbols version
rem
rem genpe parse=runfile/v/sc
genpe parsedlm=runfile/v
rem del runfile.*

rem
rem perform link for linux
rem

rem ln runfile=c:\ip\linux\i80386\lib\serlib c:\ip\linux\i80386\lib\strlib c:\ip\linux\i80386\lib\extlib xltlib common parsesvs scanner symbol parser parse c:\ip\linux\i80386\lib\cap
rem genelf parse=runfile/v
rem del runfile.*
