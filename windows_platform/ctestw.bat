parse testw=testw
ec testw=testw/noc
ln runfile=serlib testw c:\ip\windows\i80386\lib\cap #ps=$401000 #ll #lv #lm > testw.lst
genpe testw=runfile/sc/v
del runfile.*
