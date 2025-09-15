del parse.olp
ren parse.exe parse.olp
parse %1=%1
ce %1=%1
ln runfile=conlib common parserot scanner symbol parser parse cap #ps=$401000 #vs=$40c000 #lv #ll #lm > parse.loc
genpe parse=runfile kernel32 /v
rem del runfile.*
rem copy parse.exe \pascomp
