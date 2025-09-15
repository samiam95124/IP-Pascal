                     THE WHAT AND WHY OF INSTALLATION

The installer is a collection of programs and data files:

install.pas/.exe setup.exe

This is the user side installer. It uses the install.dat file, which is in the
same directory, to install IP Pascal. The installer is placed in the top of
the release CD, along with install.dat. Because many users expect "setup.exe"
to exist, a copy of install.exe exists as setup.exe on the disk.

autoexec.inf

Contains the instructions for Windows to execute the install.exe program on
disk insertion, and directs windows to change the disc drive icon to an
install icon.

createrel.pas/.exe

Creates a release in the file install.dat. The release is constructed by taking
the entire file tree from c:\iprel, and compressing and encoding that. The
parameters of the release are stored as a new record appended to the
file release.dat.

activate.pas/.exe

The manual activation server. This program loops taking an LN32 activation
number from the user, and giving an activation result. In normal use, the
user sends an activation code via email, then this program is used to form
a reply, then this is sent back to the user. The data for the release is
recorded to release.dat.

listrel.pas/.exe

This program dumps all of the data in the release.dat file to the console.

install.dat

This is the data for an individual release. It contains all of the programs
in the c:\iprel tree, plus various parameters of the release.

release.dat

Contains a series of activation records, one per release.

serial.txt

Contains the current serial number to generate. The number in this file is
incremented and rewritten to the file on each release.

reldemo.bat

Creates a demo version, no cd-rom restriction, demo flag on.

relbeta.bat

Creates a beta version, cd-rom only, time limit.

relint.bat

Creates an internal version, no cd-rom.

