parse hello=hello
ce hello=hello
ln temp=c:\ip\lib\serlib c:\ip\lib\main hello c:\ip\lib\cap #ps=$00401000 #vs=$00418000 #ll #lv #lm > hello.lst
genpe hello=temp c:\windows\system\kernel32 c:\windows\system\user32 c:\windows\system\gdi32 c:\windows\system\winmm/v/sc
del temp.*
