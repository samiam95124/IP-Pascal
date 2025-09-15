parse testw1=testw1
ec testw1=testw1/noc
ln runfile=serlib testw1 c:\ip\windows\i80386\lib\cap #ps=$401000 #ll #lv #lm > testw1.lst
genpe testw1=runfile/sc/v
del runfile.*
