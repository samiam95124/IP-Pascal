@echo off
rem
rem Compile parser
rem

echo Compiling, linking and generating executable for IP Pascal parser

rem 
rem Compile with demo limits on
rem

rem echo Enabling demo limits
rem copy demo_enable.pas demo.pas

rem 
rem Compile with demo limits off
rem

echo Disabling demo limits
copy demo_disable.pas demo.pas

rem
rem Use this parser for self checking
rem

rem echo Checking self compile using parser from this directory
rem parse xltlib=xltlib
rem parse sepsgn=sepsgn
rem parse common=common
rem parse parsesvs=parsesvs
rem parse scanner=scanner
rem parse symbol=symbol
rem parse parser=parser
rem parse parse=parse

rem
rem Use the main parser
rem

echo Using main parser in c:\ip\windows\i80386\bin\parse
c:\ip\windows\i80386\bin\parse xltlib=xltlib
c:\ip\windows\i80386\bin\parse sepsgn=sepsgn
c:\ip\windows\i80386\bin\parse common=common
c:\ip\windows\i80386\bin\parse parsesvs=parsesvs
c:\ip\windows\i80386\bin\parse scanner=scanner
c:\ip\windows\i80386\bin\parse symbol=symbol
c:\ip\windows\i80386\bin\parse parser=parser
c:\ip\windows\i80386\bin\parse parse=parse

rem
rem Compile with countermeasures
rem

rem echo Compile with countermeasures
rem ec xltlib=xltlib/noc/nrc/nac/nclcl/scxt/discm
rem ec sepsgn=sepsgn/noc/nrc/nac/nclcl/scxt/discm
rem ec common=common/noc/nrc/nac/nclcl/scxt/discm
rem ec parsesvs=parsesvs/noc/nrc/nac/nclcl/scxt/discm
rem ec scanner=scanner/noc/nrc/nac/nclcl/scxt/discm
rem ec symbol=symbol/noc/nrc/nac/nclcl/scxt/discm
rem ec parser=parser/noc/nrc/nac/nclcl/scxt/discm
rem ec parse=parse/noc/nrc/nac/nclcl/scxt/discm

rem
rem Compile normal with no checks
rem

rem echo Compile with overflow, range, array and local clearing OFF
rem ec xltlib=xltlib/noc/nrc/nac/nclcl
rem ec sepsgn=sepsgn/noc/nrc/nac/nclcl
rem ec common=common/noc/nrc/nac/nclcl
rem ec parsesvs=parsesvs/noc/nrc/nac/nclcl
rem ec scanner=scanner/noc/nrc/nac/nclcl
rem ec symbol=symbol/noc/nrc/nac/nclcl
rem ec parser=parser/noc/nrc/nac/nclcl
rem ec parse=parse/noc/nrc/nac/nclcl

rem
rem Compile normal with checks
rem

echo Compile with only overflow checking OFF
ec xltlib=xltlib/noc
ec sepsgn=sepsgn/noc
ec common=common/noc
ec parsesvs=parsesvs/noc
ec scanner=scanner/noc
ec symbol=symbol/noc
ec parser=parser/noc
ec parse=parse/noc

rem
rem perform link for windows
rem

echo Link and generate executable for Windows
rem ln runfile=c:\ip\windows\i80386\lib\blotter c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\strlib c:\ip\windows\i80386\lib\extlib xltlib sepsgn common parsesvs scanner symbol parser c:\ip\windows\i80386\lib\main c:\ip\windows\i80386\lib\reglock c:\ip\windows\i80386\lib\timelock parse c:\ip\windows\i80386\lib\cap/nu/ll/lv/lm/lx/ps=$401000/vs=$46c000 > parse.lst
ln runfile=c:\ip\windows\i80386\lib\blotter c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\strlib c:\ip\windows\i80386\lib\extlib sepsgn common parsesvs scanner symbol parser c:\ip\windows\i80386\lib\main c:\ip\windows\i80386\lib\reglock c:\ip\windows\i80386\lib\timelock parse c:\ip\windows\i80386\lib\cap/nu
rem ln runfile=c:\ip\windows\i80386\lib\blotter c:\ip\windows\i80386\lib\serlibx c:\ip\windows\i80386\lib\strlibx c:\ip\windows\i80386\lib\extlibx sepsgn common parsesvs scanner symbol parser c:\ip\windows\i80386\lib\main c:\ip\windows\i80386\lib\reglockx c:\ip\windows\i80386\lib\timelockx parse c:\ip\windows\i80386\lib\cap/nu
rem ln runfile=c:\ip\windows\i80386\lib\serlibx c:\ip\windows\i80386\lib\strlibx c:\ip\windows\i80386\lib\extlibx sepsgn common parsesvs scanner symbol parser c:\ip\windows\i80386\lib\main parse c:\ip\windows\i80386\lib\cap/nu
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

echo Enabling demo limits
copy demo_enable.pas demo.pas

rem 
rem Compile with demo limits off
rem

rem echo Disabling demo limits
rem copy demo_disable.pas demo.pas

rem
rem Use this parser for self checking
rem

rem echo Checking self compile using parser from this directory
rem parse xltlib=xltlib
rem parse sepsgn=sepsgn
rem parse common=common
rem parse parsesvs=parsesvs
rem parse scanner=scanner
rem parse symbol=symbol
rem parse parser=parser
rem parse parse=parse

rem
rem Use the main parser
rem

echo Using main parser in c:\ip\windows\i80386\bin\parse
c:\ip\windows\i80386\bin\parse xltlib=xltlib
c:\ip\windows\i80386\bin\parse sepsgn=sepsgn
c:\ip\windows\i80386\bin\parse common=common
c:\ip\windows\i80386\bin\parse parsesvs=parsesvs
c:\ip\windows\i80386\bin\parse scanner=scanner
c:\ip\windows\i80386\bin\parse symbol=symbol
c:\ip\windows\i80386\bin\parse parser=parser
c:\ip\windows\i80386\bin\parse parse=parse

rem
rem Compile with countermeasures
rem

echo Compile with countermeasures
ec xltlib=xltlib/noc/nrc/nac/nclcl/scxt/discm
ec sepsgn=sepsgn/noc/nrc/nac/nclcl/scxt/discm
ec common=common/noc/nrc/nac/nclcl/scxt/discm
ec parsesvs=parsesvs/noc/nrc/nac/nclcl/scxt/discm
ec scanner=scanner/noc/nrc/nac/nclcl/scxt/discm
ec symbol=symbol/noc/nrc/nac/nclcl/scxt/discm
ec parser=parser/noc/nrc/nac/nclcl/scxt/discm
ec parse=parse/noc/nrc/nac/nclcl/scxt/discm

rem
rem Compile normal
rem

rem echo Compile with overflow, range, array and local clearing OFF
rem ec xltlib=xltlib/noc/nrc/nac/nclcl
rem ec sepsgn=sepsgn/noc/nrc/nac/nclcl
rem ec common=common/noc/nrc/nac/nclcl
rem ec parsesvs=parsesvs/noc/nrc/nac/nclcl
rem ec scanner=scanner/noc/nrc/nac/nclcl
rem ec symbol=symbol/noc/nrc/nac/nclcl
rem ec parser=parser/noc/nrc/nac/nclcl
rem ec parse=parse/noc/nrc/nac/nclcl

rem
rem perform link for windows
rem

echo Link and generate executable for Windows
rem ln runfile=c:\ip\windows\i80386\lib\blotter c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\strlib c:\ip\windows\i80386\lib\extlib xltlib sepsgn common parsesvs scanner symbol parser c:\ip\windows\i80386\lib\main c:\ip\windows\i80386\lib\reglock c:\ip\windows\i80386\lib\timelock parse c:\ip\windows\i80386\lib\cap/nu/ll/lv/lm/lx/ps=$401000/vs=$46c000 > parse.lst
rem ln runfile=c:\ip\windows\i80386\lib\blotter c:\ip\windows\i80386\lib\serlib c:\ip\windows\i80386\lib\strlib c:\ip\windows\i80386\lib\extlib sepsgn common parsesvs scanner symbol parser c:\ip\windows\i80386\lib\main c:\ip\windows\i80386\lib\reglock c:\ip\windows\i80386\lib\timelock parse c:\ip\windows\i80386\lib\cap/nu
ln runfile=c:\ip\windows\i80386\lib\blotter c:\ip\windows\i80386\lib\serlibx c:\ip\windows\i80386\lib\strlibx c:\ip\windows\i80386\lib\extlibx sepsgn common parsesvs scanner symbol parser c:\ip\windows\i80386\lib\main c:\ip\windows\i80386\lib\reglockx c:\ip\windows\i80386\lib\timelockx parse c:\ip\windows\i80386\lib\cap/nu
rem
rem Symbols version
rem
rem genpe parse=runfile/v/sc
genpe parsedlm=runfile/v
rem del runfile.*

rem
rem perform link for linux
rem

rem echo Link and generate executable for Linux
rem ln runfile=c:\ip\linux\i80386\lib\serlib c:\ip\linux\i80386\lib\strlib c:\ip\linux\i80386\lib\extlib xltlib sepsgn common parsesvs scanner symbol parser parse c:\ip\linux\i80386\lib\cap
rem genelf parse=runfile/v
rem del runfile.*
