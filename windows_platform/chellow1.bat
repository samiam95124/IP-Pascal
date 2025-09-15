parse hellow1=hellow1
ce hellow1=hellow1
as winhan=winhan
ln runfile=serlib c:\ip\windows\i80386\lib\main hellow1 c:\pascomp\lib\cap #ps=$401000 #ll #lv #lm > hellow1.lst
genpe hellow1=runfile c:\windows\system32\kernel32 c:\windows\system32\user32 c:\windows\system32\gdi32 c:\windows\system32\winmm/wg /v
del runfile.*
