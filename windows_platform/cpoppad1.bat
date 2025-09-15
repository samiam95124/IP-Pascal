parse poppad1=poppad1
ec poppad1=poppad1/noc
ln runfile=serlib poppad1 c:\ip\windows\i80386\lib\cap #ps=$401000 #ll #lv #lm > poppad1.lst
genpe poppad1=runfile/sc/v
del runfile.*
