@echo off
rem
rem Update file
rem

rem
rem Update internal copy, which gets reverse engineering counter-measure features
rem
copy encode.exe \ip\windows\i80386\bin\ec80686.exe
copy encode.exe \ip\windows\i80386\bin\ec.exe

rem
rem Update release copy, which has reverse engineering counter-measures disabled
rem
rem copy encodencm.exe \iprel\windows\i80386\bin\ec80686.exe
rem copy encodencm.exe \iprel\windows\i80386\bin\ec.exe

rem
rem Update demo copy, which has reverse engineering counter-measures disabled
rem
rem copy encodencm.exe \ipdemo\windows\i80386\bin\ec80686.exe
rem copy encodencm.exe \ipdemo\windows\i80386\bin\ec.exe
