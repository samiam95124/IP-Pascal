parse tim=tim
ce tim=tim
ln runfile=serlib cvttim extlib tim cap
genpe tim=runfile c:\windows\system\kernel32 c:\windows\system\user32 c:\windows\system\gdi32 c:\windows\system\winmm /wg /v
del runfile.*
