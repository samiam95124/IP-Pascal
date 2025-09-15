                            IP PASCAL BETA RELEASE README

Welcome to the beta distribution of IP Pascal.

You were provided with a pre-experience beta copy of IP Pascal so that you can
evaluate it for your use. Please note:

* As with any beta software, you are not receiving finished, fully tested 
software.

* If you are writing about IP Pascal, it is ok to mention beta features and
even bugs. However, you should always specify that you are evaluating the
beta version, not the full release.

* Your release has a date and time limit. See later in this document for how
to view that.

* This release is NOT as stable as the demo. You are "with us", the developers
now. You are obtaining a release that is close to, or identical to the one
we use every day.

* Beta is an ongoing program. When we have an improved version, we will send
that to you. You may expect to receive several releases before the beta
program ends.

INSTALLATION ===================================================================

If your copy of IP Pascal didn't start installing when you inserted the disk,
you probably have autorun for the disk disabled. Open the disk and execute
"install.exe" from the top directory.

YOU MUST INSTALL DIRECTLY FROM THE CD-ROM.

The installer is straightforward. Keep hitting the NEXT button to accept the
defaults. You will be asked for the install path for IP Pascal, followed by
the search path, then you will activate your software.

Activation is mandatory for IP Pascal, but there is no personal information
exchanged during the process. The installer will tell the activation server
what copy of IP Pascal you have, and information that is non-personal, but
unique to your computer, such as the CPU type, serial number of Windows, etc.
This information is only required when you install the software, not when you
run it.

Don't worry, the activation server will allow you to reinstall your software
as many times as you need to, within reason. It is designed only to stop
the same copy of IP Pascal from being installed 100's of times from an
"escaped" internet distributed illegal copy.

The ability to manually activate the software allows you to install it on a
machine that has no connection to the internet, such as a laptop computer.

After activating the software, it will be installed using the options you
specified. That's all there is to it.

For those wanting to know more about the installation options, let's go
through them, one by one.

INSTALL LOCATION

The standard location for Windows XP is "C:\PROGRAM FILES\MOORECAD IP PASCAL".
The only data that will be stored there is installation and system wide
configuration data. No user files, such as source programs or edited material
is stored there.

If you want to install IP Pascal on a different drive or directory, then simply
edit the location in the dialog provided. For example, here is the path you
would enter to install on drive D:, under the root:

D:\MOORECAD IP PASCAL

You will be warned if the install directory already exists. If the install 
directory name is occupied by a file, then the installation will stop.
There is no problem with installing over a previous directory, but you will
be asked if this is what you want to do. All files of the same name as the
install files will be overwritten, but other files will be left alone. If
you have modified some of the .ins files in the IP Pascal directory to match
you particular needs, you will want to save those files before the install,
and replace them when done, as needed.

SEARCH PATH

If you will be using the command line tools, instead of, or in addition to the
IDE, you will want to let the installer modify the search path for you. The
IP Pascal binary directory will be added to the end of the search path for
you.

If you wish, you can perform this step manually, after the installation is
complete.

If you are using command line tools, you need to reboot after performing the
installation. This will allow the Windows command shell to pick up the
change.

ACTIVATION

The activation process involves the installer sending a 39 digit activation
code to the server, and receiving a reply. This can be done completely
automatically for you, or you can do it manually. The same information is
sent using the automatic method as when using the manual method, the installer
simply saves you the work of entering the code to the server manually.

If for any reason you wish to perform this step manually, simply email the
activation code to the server at activation@moorecad.com. The code can
appear in the body of the email, and the subject can be anything, or left
blank.

BETA USERS NOTE: Your version is not enabled for automatic activation.
If you leave the activation at the default "automatic", it will always fail.
Please select "manual activation" instead.

REMOVING IP PASCAL =============================================================

Once IP Pascal is installed, please use the Windows "Add or remove programs"
dialog to remove it. From the START button in the lower left, press:

Start->Control Panel

Then the "add or remove programs" icon, then select IP Pascal from the list.

MANUALLY UNINSTALLING IP PASCAL

If you have problems using the automated uninstall method, you can use several
alternative methods to remove it.

Method #1

Open an "explore" view of the drive IP Pascal is installed on. Find the
installation directory, and press the "launch.exe" icon. This will bring up
the uninstaller dialog. Do not execute the "uninstall.exe" icon. The
uninstaller program cannot delete the directory it sits in, so "launch.exe"
moves the uninstaller to a temp directory and executes it there.

Method #2

Open a command shell, and execute:

"c:\program files\moorecad ip pascal\launch"

You MUST NOT BE in the IP Pascal install directory when executing this. This
will cause the directory to be locked if you do this, and the uninstallation
will fail.

Method #3

If you simply delete the entire install directory for IP Pascal, you will
effectively remove IP Pascal from your system. IP Pascal deliberately keeps
information placed outside of the installation directory to a minimum.

If desired, you can also clean up your system by editing IP Pascal out of
your search path by executing:

Start->Control Panel

Then select:

Sytem->Advanced->Environment Variables

And double click the "Path" variable under "System Variables" to edit it.
You can then remove IP Pascal from your path.

To remove the registry key for IP Pascal, enter:

Start->Run

Enter "\windows\regedit.exe" into the run dialog box. When the registry editor
comes up, expand (press the "+" button next to) each of:

HKEY_LOCAL_MACHINE->SOFTWARE->Microsoft->Windows->CurrentVersion->Uninstall

Under that key, find the "IP Pascal" subkey, and delete it.

BETA RELEASE TIME LIMIT ========================================================

Your beta release copy is time limited. Check the status of your software by:

Start->Control Panel->Add or Remove Programs

Then select IP Pascal from the list of installed programs. You will see the
expiration date and time in the title.

Past the expiration date and time, the software will give an error about being
past the release time. Any attempts to activate the software past this date and
time will result in an error.

SUPPORT ========================================================================

For any support questions, please email:

support@moorecad.com

Please indicate the product, IP Pascal, and the version number.

BETA USERS NOTE:

You have a special support email:

beta@moorecad.com

STATUS OF IP PASCAL 2006-02-15 =================================================

The current run version of IP Pascal programs is 1.12.xx. The sections of the
version number mean:

1.12.00

First number: The major revision number. This indicates a major change in
functionality of the product.

Second number: The minor revision number. This indicates bug fixes or cleanups
in an existing version.

Third number: This is the build number. This number is incremented for every
change made in individual executables within the IP family. It is the only
number that differs between executables.

You should never see anything but "00" in the build number, because the build
numbers are "rolled" into the minor revision number each time a release of
any kind is done.

WHAT'S NEW

* The Window management call API is complete. Using this API, you can create,
size and manipulate windows.
 
* Installer. The old .zip method of installation is over, as well as manually
setting your path, etc. The new installer automatically installs, changes your
path, and establishes "uninstall" registry keys so that the "add or remove
programs" Windows dialog will control the IP Pascal program installation.

WHAT'S LEFT TO DO

IP Pascal is moving towards completion of the complete feature set required for
WIndows/XP and later system programming. There are still several sections in the
toolset that are not complete.

* IDE. The Integrated Development Environment, named IPIDE, is still in
development. The new IPIDE is a refit of the old IP programming editor, which
was and character screen based editor originating in 1985 (yes, really!). We
expect to release a demo version of this shortly, likely by the end of march.
Until then, the workaround is to use the command line toolset, or use a 3rd
party IDE.

* Widgets. The widget libary is fairly complete, and is actually in use. 
However, the API content and naming is not yet finalized, nor is the 
documentation complete. This is expected to be finished shortly.

* Parallel tasking. The parallel modules system described in the IP Pascal
language manual is not implemented. We actually do have several multithreaded
programs (for example, gralib uses a separate thread to manage the graphical
interface). These are programmed directly using the Windows GDI API.

* TCP/IP networking. This module is planned, but not implemented.

* Full "windows.pas" API. The Windows API in Pascal callable form was manually
created, and does not include the full Windows API. Nevertheless, the currently
implemented Windows GDI API translations are extensive, and can be found in the
file "windows.pas". The plan is to move this to an automated translator, which
takes Windows C/H files and translates them to Pascal callable headers. This
translator actually is functioning, but does not yet correctly translate %100
of the Windows API. Instead, we have been using the automatically translated
header file to "pick and choose" the API calls we need. This is expected to
be solved shortly. The linker issue (below) also affects this issue, because
the full Windows API would create too many wrapper functions, and would take
excessive program space.

* Unused section linker elimination. A fairly short upgrade for the linker is
planned that removes unused sections (routines) from the final link phase. This
originally was a "nice to have" option, but has become imperative, because the
full Windows API wrapper file has too much data in it to include with every
program.

* N-Length sets. Sets are currently limited to 256 elements. This a fairly
normal limit for Pascal sets. However, there are times when you need more than
256 different set elements.

* Critical packing. As with many compilers, IP Pascal packs data to the byte
level only (sometimes byte oriented processors are said to be "inherently
packed"). This is a limitation with only a few applications that need to
directly access data from other programs or the operating system.

* Precompiled headers. This is a minor speed enhancement only, and has no
direct functionality effect.

* Unsigned number handling. Handling numbers that are greater than $7fffffff
is common in Windows API interfacing, because Windows uses these numbers. It is
possible to operate on unsigned numbers using the signed operations implemented
in IP Pascal, by turning OFF numeric overflow detection in programs where 
unsigned numbers are to be used. Addition and division in this case are
identical between signed and unsigned numbers. Multiplication and division,
and output and input of numbers requires tricks to make it work, since the
basic compiled operations are still signed. email support@moorecad.com if
you need to perform this immediately, or else wait for the unsigned extention
for IP Pascal, which should be ready soon.

KNOWN SOFTWARE ISSUES ==========================================================

What follows is a list of known issues with various IP Pascal components. Please
note this is not a complete dump of our buglist. Because of the beta software
state, the developer's buglist contains many "to do" items that don't directly
affect users. What follows is a list of bugs that cause real issues with the
current version of IP Pascal.

PARSER

1. When an identifier is found to be misspelled, the message appears:

   unlock { end exclusive access }
         ^
*** C:\PASCOMP\windows\gralib.pas [3550:10] 'unlock' assumed to be misspelled 
    'unlock' ***

It should output the correct spelling of the ID.

2. Two form feed characters back to back generate an error. Parser should ignore
all control characters.

ENCODER

1. Pointer dereference checks are not always generated (checks of attempting to
access a 0 or nil valued pointer). This does not affect functionality, but does
affect program safety.

2. Range checks are not always generated on stores.

3. When dynamically allocating general arrays whose elements are not 1 byte in
length, the function "max()" returns the byte length of the allocated array, not
the element length (number of elements).

ASSEMBLER

The up arrow in an error message (which indicates the character in the line
containing the error) does not always indicate the correct character position.

EXTLIB

1. The dates and times functions should format the time according to the
current settings on the system. For example, if 24 hour time is used on the
current system, it should print time in that format.

GRALIB

1. Foreground and background xor modes don't work with text.

2. Encountering a paslib error while gralib is coupled presents the paslib error
dialog, but then locks up instead of exiting properly.

3. The widget section is incomplete, some of the functions don't work, and it
should be considered experimental for this release. The section on widgets in
the manual is also incomplete.

4. Arcs that end on 90 degree quads have rounded ends on only ONE side, with the
normal squared ends on the other. There is no way this should even be possible
with the Windows API, it is not possible to have two different line endings on
the same line. It is a Windows bug, which will have to have a gralib workaround.

5. Turning on a menu with a buffered surface should change the size of the
window to keep the client area over the full buffer. It currently does not.

6. The "winclient" call should return the minimum window size if the requested
client size is too small. It instead returns a size that Windows will not
accept, and so would be invalid.

7. When the sizing of a window is turned off (size bars turned off), it is still
possible to maximize the window, which defeats the purpose of disabling sizing,
since the result is a window larger than required.

8. If a gralib coupled program runs, but does no window I/O, a "zombie" task is
created. gralib runs a background task for the display, and this is likely not
getting terminated at the end of the program.

SUBMITTING A BUG ===============================================================

You can submit a bug for our attention via email at support@moorecad.com. Please
include the following items:

1. Your name.

2. Your customer number.

3. What component of IP Pascal is having a problem.

4. What your operating system type is (Windows NT, Windows 2000, Windows XP).

5. What type of CPU you are running on (AMD or Intel, what CPU series, etc.).

6. What were the events leading up to the fault?

7. Is the problem repeatable (if you run it multiple times, does it fail each
   time)?

7. A "cut and paste" of the run that caused the problem, including error
messages.

8. Do you have source code that causes the problem? The quickest way to solve
the problem is to include it as an attachment. If your file is too large or
you do not wish to reveal your private source code, that's ok. Please take some
time to cut it down to only what is needed to cause the issue. We would have
to do this in any case.

USE OF IP PASCAL COMMAND LINE TOOLS ============================================

The best way to use the command line tools is via the command tool integrator,
PC. The pc (Pascal Compile) program reads from an instruction file, pc.ins, to
configure various items such as where to find libraries, what is in the
libraries, etc.

pc is getting smarter, but it does not cover all contingencies, and probally
never will. That's why IP Pascal is a toolset. Typical situations you are going
to want to handle via batch or make files are the construction of individual
libraries, embedded programming, and programing for custom operating systems
and environments.

Before the .ins file system, environment variables were used to pass persistent
data, such as where the libraries were kept. PC paves over this fact by using
the .ins file to fully path everything passed to lower level tools. However,
if you directly execute command like the parser, you are going to want to
define at least your uses path.

To define the uses path, perform the following procedure:

Start (button)->Control Panel (icon)->System (icon)->Advanced (tab)->
   environment Variables (button)

Under "User variables for ...", press New, and enter:

Variable Name:  usespath
Variable Value: .,c:\program files\Moorecad IP Pascal\windows\i80386\lib

This means to search for libraries at the current directory, then search in the
central library. If you installed IP Pascal in a diferent directory or disk than
the default, use that in place of "c:\program files\Moorecad IP Pascal".

Hint: If you are going to do a lot of command line compiling, it pays to get
familiar with batch files, a good "make" facillity, or a more advanced shell
than Windows cmd.exe.

OTHER QUESTIONS/ISSUES =========================================================

Q. Exactly what information is exchanged with activation?

A. Encoded in the "signature" you send to the server is specific identification
for the software version you are installing, and what is known as a "hardware
hash" of different system parameters. The hardware parameters that make up the
"hash" are items like the CPU type and stepping, the Windows serial number,
and other parameters. None of this information is personal data. In addition,
because it is a hash, it is not possible to work out the original hardware
information from your computer by use of this hash. For a good overview of
the process, see:

http://www.microsoft.com/piracy/activation_faq.mspx

This page covers Microsoft's (tm) method of hardware verification, which is
very similar.

Q. Is my copy of IP Pascal serialized?

A. Yes. In addition, each copy of IP Pascal is unique. Because there are an
infinite number of ways to compile a given section of code that are equivalent
in speed and code size, it is possible to generate any number of versions of
the same product that differ substantially from each other in object code,
but function identically. The advantage of this system, as opposed to simple
serial number schemes, is that it is not possible to randomly alter the program
to arrive at another user's combination. Contrast this with serial numbers,
where substituting a random number for the serial number could have a reasonable
chance to arrive at another customer's serial number. It also means that,
given any non-trivial part of the IP Pascal system, it can be determined which
copy it originated from.

Q. If my copy of the software is found to be released illegally (on the 
internet, or "cracked"), do I lose rights to the software?

A. No. We are only interested in denying an illegally released IP Pascal
(in "cracked" or other form) activation or support due a paying customer.
We may ship you another copy and ask you to use that instead of the original,
so that you will be using a new "clean" version and activation, so that we
can get the illegally released version shut down. We are not a large company
with large anti-piracy resources. At the same time, we don't wish to deny
our paying customers service, or even inconvenience you. At the same time,
please realize that if your copy of IP Pascal is widely released, it is
your copy. There is no way that anyone can "forge" a copy of IP Pascal
with your "signature" on it. We believe that no reasonable paying customer
deliberately releases any software to be distributed on the internet. Instead,
it is lent to a friend, and perhaps a friend of a friend, until it escapes
anyone's control. Please read the licence for IP Pascal, and instead of
lending your friends a full licensed copy of IP Pascal, tell them where to
find the evaluation/student version instead. It's free, has all the functions
of full IP Pascal aside from being able to construct large programs, and should
be enough for anyone to wants to see what IP Pascal is about.

Q. Is there a limit to the number of activations of IP Pascal software?

A. Yes, at this writing, the limit is 25. However, this is just the automated
limit. If you exceed that for any reason, please contact us at 
support@moorecad.com, and we will see about getting you more activations, or
alternately a new copy of the software.

Q. Will IP Pascal run on any version of Windows?

A. IP Pascal is interlocked to deliver an error message if run on any version of
Windows outside the Windows NT family, which includes Windows 2000, Windows XP,
and the server versions. Specifically, Windows 3.x, Windows 95, Windows 98 or
Windows ME will NOT be usable with IP Pascal. The reason is that IP Pascal is
inherently a multithreaded system, and the non-NT versions of Windows had 
serious problems with handling of threads that could not be reasonably worked
around.

Q. Will IP Pascal run on any CPU?

A. IP Pascal requires a I80586 or better CPU.

Q. What system areas, registry keys, or other data does IP Pascal modify?

A. We believe in keeping as much data possible in the directory assigned by
you for IP Pascal. IP Pascal does not plant Dynamic Link Library files into the
Windows system folders as many applications do. IP Pascal will modify your 
search path if you so request. It will also make the minimum required additions
to the registry that Windows requires to register IP Pascal with windows as a
formal application (the exact keys are detailed above in "Removing IP Pascal".












