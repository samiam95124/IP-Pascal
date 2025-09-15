rem
rem Construct extention library
rem
parse extlib=extlib /nrf /u=.,\ip\windows\i80386\lib
ec extlibt=extlib
as cvttim=cvttim
ln extlib=cvttim extlibt
rem del temp.*

parse extlib=extlib /nrf /u=.,\ip\windows\i80386\lib
ec extlibt=extlib/scxt
as cvttim=cvttim
ln extlibx=cvttim extlibt
rem del temp.*
