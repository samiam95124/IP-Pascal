rem
rem Assemble floppy bootstrap
rem
rem Assemble and locate at PCDOS standard sector boot location of $7c00,
rem then pad it to a full sector with the boot signature.
rem
as fpyboot=fpyboot
ln fpybooti=fpyboot/ps=$600/lv > fpyboot.lst
creatfpy fpybooti.obj fpyboot.bin
