@echo off
rem
rem Compile and run iso7185pat.pas with an option
rem
rem

@echo *** Compiling with /%1 option ***
call cstandard /%1
iso7185pat > iso7185pat.out
diff iso7185pat.out iso7185pat.ref > iso7185pat.%1.dif
del iso7185pat.out
