rem
rem Set up a bootstrap test
rem

rem
rem assemble the floppy bootstrap to fpyboot.bin
rem
call cfpyboot
rem
rem Create a numbered test load file of 256kb, which
rem will span $9000 to $49000
rem
genblk 500 512
rem
rem Create bochs suitable 1.44kb floppy boot image at a.img
rem
creatimg