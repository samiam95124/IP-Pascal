rem
rem Compile Pascal support library
rem

rem
rem Compile character translation library
rem
parse xltlib=xltlib /u=.,\ip\windows\i80386\lib
ec xltlib=xltlib

rem
rem Compile paslib with character translation off
rem
copy xltmod_off.pas xltmod.pas
parse paslib=paslib /u=.,\ip\windows\i80386\lib
ec paslib=paslib

rem
rem Compile paslib with character translation on
rem
copy xltmod_on.pas xltmod.pas
parse paslibx=paslib /u=.,\ip\windows\i80386\lib
ec paslibx=paslibx/scxt

