parse envlst=envlst
ec envlst=envlst/noc
ln runfile=serlib c:\ip\windows\i80386\lib\strlib envlst c:\ip\windows\i80386\lib\cap #ps=$401000 #ll #lv #lm > envlst.lst
genpe envlst=runfile/sc/v
del runfile.*
