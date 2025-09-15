parse hellow=hellow
ec hellow=hellow/noc
ln runfile=serlib c:\ip\windows\i80386\lib\strlib hellow c:\ip\windows\i80386\lib\cap #ps=$401000 #ll #lv #lm > hellow.lst
genpe hellow=runfile/sc/v/wg
del runfile.*
