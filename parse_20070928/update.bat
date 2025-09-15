rem
rem Update file
rem

rem
rem Update local copy without demo limits
rem
copy parse.exe \ip\windows\i80386\bin

rem
rem Update release copy without demo limits
rem
copy parse.exe \iprel\windows\i80386\bin

rem
rem Update demo copy with demo limits
rem
copy parsedlm.exe \ipdemo\windows\i80386\bin

rem
rem Update linux copy
rem
copy parse \ip\linux\i80386\bin
