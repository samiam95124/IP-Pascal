parse event=event
ec event=event
ln runfile=conlib c:\ip\windows\i80386\lib\main event c:\ip\windows\i80386\lib\cap #ps=$401000 #ll #lv #lm > event.lst
rem ln runfile=conlib event c:\pascomp\lib\cap
genpe event=runfile/sc /v
del runfile.*
