{*******************************************************************************
*                                                                              *
*                            IP INSTALLER PROGRAM                              *
*                                                                              *
*                             2006/01 S. A. Moore                              *
*                                                                              *
* Decompresses and places the files in an install.dat program. See the install *
* program for further program notes.                                           *
*                                                                              *
* File format:                                                                 *
*                                                                              *
* There are only two different kinds of tolkens output:                        *
*                                                                              *
* Match tolken:                                                                *
*                                                                              *
* 00: Match length/upper offset                                                *
*   bits 4-7: Match length, 1 to 15                                            *
*   bits 0-3: upper 4 bits of offset                                           *
* 01: Match offset, lower 8 bits of match offset.                              *
*                                                                              *
* Run tolken:                                                                  *
*                                                                              *
* 00: Run length                                                               *
*   bits 4-7: 0 to indicate run                                                *
*   bits 0-3: 1 to 15                                                          *
* 01: 1st byte of run data                                                     *
* ...                                                                          *
* XX: Nth byte of run data                                                     *
*                                                                              *
* For each tolken read, the upper 4 bits indicates if the tolken is a run or   *
* match tolken. If the bits are 0, then it is a run tolken. Otherwise, the     *
* bits contain a count of bytes in the match.                                  *
*                                                                              *
* When a run is indicated, the lower 4 bits indicate the run length. The bytes *
* in the run, from 1 to 15 bytes, follow.                                      *
*                                                                              *
* When the tolken is a match, the lower 4 bits of the first byte give the      *
* upper 4 bits of the 12 bits of the 4096 offset backwards into the sliding    *
* window. An offset of 0 is not valid.                                         *
*                                                                              *
* When the tolken byte is entirely 0, this indicates an extended code tolken.  *
* Such tolkens have an extended code in the following byte. The only extended  *
* tolken presently defined is 0, for "end of file". All other codes are        *
* reserved for future use, and generate an error in the decompressor.          *
*                                                                              *
* The file begins with the ASCII tolken "INST".                                *
*                                                                              *
*******************************************************************************}

program install(input, output, error);

uses windows, 
     cpuid,
     gralib,
     strlib,
     extlib,
     parlib;

label 99, { abort program }
      { display page jumpbacks }
      page1,
      page1b,
      page2,
      page3;

const filmax     = 500;       { number of characters in a filename }
      bufmax     = 4096;      { size of compression sliding buffer }
      runmax     = 15;        { maximum size of run or match }
      polynomial = $04c11db7; { Ethernet CRC 32 polynomial }
      { default path and drive to install under }
      defpath    ='c:\\Program Files\\MooreCAD IP Pascal'; 
      definst    = 'install.dat'; { default install data file name }
      licnam     = 'license.txt'; { name of license file }
      { switches }
      diag    = false; { output diagnostics }
      tolken  = false; { output decompression tolkens (diag must be on) }
      encode  = true;  { encode install.dat file }
      actnum  = 6;     { number of activation words }
      clientx = 640; { size of client area }
      clienty = 375;
      lmargin = 120; { left margin (includes logo) }
      rmargin = 640-20; { right margin }
      fntsiz  = 20;  { size of font }
      buthgh  = 30;  { bottom button heights }
      butbmg  = 20;  { bottom button margin to edge }
      butbak  = 350; { placement x of back button }
      butnxt  = 450; { placement x of next button }
      butcan  = 550; { placement x of cancel button }
      butext  = 550; { placement x of exit button }
      butwdt  = 70;  { width of buttons }
      etylin  = 270; { x of entry line or checkbox }
      { widget ids }
      bidbak = 1; { back }
      bidnxt = 2; { next }
      bidcan = 3; { cancel }
      bidext = 4; { exit }
      widedt = 5; { edit box }
      widchk = 6; { check box }
      widprg = 7; { progress bar }
      bidacc = 8; { accept license button }
      biddac = 9; { don't accept license button }
      bidup  = 10; { up button in license }
      biddwn = 11; { down button in license }
      { pictures }
      piclog = 1; { logo }
      picstp = 2; { stop sign }
      { subwindows }
      winlic = 2; { license window id }
      windbg = 3; { debug window }

type  filinx = 1..filmax; { index for filename }
      filnam = packed array [filinx] of char; { a filename }
      bufinx = 1..bufmax; { index for input buffer }
      bufdst = 0..bufmax; { distance in buffer }
      runinx = 1..runmax; { index for runs }
      runlen = 0..runmax; { length of a run }
      macety = array [1..6] of byte; { ethernet mac address }
      { Patch entries are used to insert various values into the output files. }
      pattyp = (ptnone,  { none }
                ptmaca,  { mac address table }
                ptcpui,  { cpu id data }
                ptwinv, { windows version data }
                pttimi); { release date/time limit }
      patptr = ^patch; { pointer to patch entry }
      patch = record { patch entry }

         typ:  pattyp;  { type of this patch }
         sadr: integer; { starting address }
         eadr: integer; { ending address }
         next: patptr   { next entry pointer }

      end;
      actarr = array actnum of integer; { activation number array }
      { string list structure for license file }
      strlpt = ^strety; { pointer to string entry }
      strety = record { string entry }

         str: pstring; { pointer to string }
         next: strlpt  { next entry }

      end;
      { Special command codes. When the first byte of a tolken is zero, the
        following byte will contain one of these special codes. }
      spccod = (sceof,   { end of file (end of all) }
                sccrc,   { 32 bit CRC follows for last file }
                scnam,   { name of file follows }
                scpth,   { path follows }
                scstr,   { start of file data }
                scend,   { end of file data }
                scmaca,  { insert mac address table }
                sccpui,  { insert cpu id }
                scwinv,  { insert windows version number }
                sctimi,  { insert release time limit }
                scser,   { serial number for install data }
                sctim,   { release date and time }
                sccdol,  { CD-ROM only release }
                scdemo,  { release is a demo }
                scbeta,  { release is a beta }
                sctiml,  { time limit }
                scver,   { software version }
                scsend); { end of system data area }
      { active button tracking }
      actbut = (acbbak,  { back }
                acbnxt,  { next }
                acbcan,  { cancel }
                acbext); { exit }
      actbuts = set of actbut;
      errcod = (enoinsfl,  { no install.dat file is found }
                enolicfil, { no license file is found }
                einvifl,   { install.dat file is corrupted }
                edirfil,   { directory is a file }
                ecdrom,    { CD-ROM check }
                ereg,      { cannot register }
                esys);     { system error }

fixed ln32: packed array 32 of char = '0123456789ABCDEFGHJKMNPQRSTUWXYZ';

var   errnam:          filnam;  { error filename }
      inpfil:          bytfil;  { input file }
      inpopn:          boolean; { input file is open }
      insnam:          filnam; { install data filename }
      aopn, bopn:      boolean; { file open flags }
      b, b1, b2, b3:   byte;    { byte holders }
      err:             boolean; { error return }
      buff:            array bufmax of byte; { sliding compression buffer }
      { Input index for buffer, limit of all input from input file. }
      inpinx:          bufinx;
      crctab:          array 256 of integer; { CRC remainder table }
      filcrc:          integer; { current CRC accumulator }
      cmpcrc:          integer; { comparision CRC }
      prgpth:          filnam; { main program path }
      tmpstr, tmpstr1: filnam; { holding string }
      ovf:             boolean; { input overflow flag }
      ans:             boolean; { user answer flag }
      path:            filnam;  { program path }
      datcrc, datcrc1,
      datcrc2, datcrc3, 
      datcrc4:         integer; { full data file crc }
      enccrc:          integer; { encoder CRC }
      p, n, e:         filnam; { filename components }
      cpucmp:          array 4 of integer; { cpu id compare array }
      maccmp:          array 10 of macety; { mac compare array }
      vercmp:          integer; { windows version compare }
      outfil:          bytfil;  { output file }
      outadr:          integer; { element address of output file }
      patlst:          patptr;  { active patch list }
      frepat:          patptr;  { free patch list }
      hwrcrc:          integer; { hardware digest }
      sernum:          integer; { serial number for this release }
      reltim:          integer; { release time and date }
      instim:          integer; { install time }
      actcrc:          integer; { activation code CRC }
      actdat:          actarr;  { activation data }
      actrpl:          actarr;  { activation data reply }
      rndseq:          integer; { random number seed }
      ac:              boolean; { activation code compares }
      xltarr:          array actnum*32 of 0..actnum*32; { translation array }
      fcdonly:         boolean; { install from CD-ROM only }
      fdemo:           boolean; { release is a demo }
      fbeta:           boolean; { release is a beta }
      timlim:          integer; { time limit on this release }
      sx, sy:          integer; { screen size }
      bcr, bcg, bcb:   integer; { background color rgb }
      runy:            integer; { runnning text placement }
      bakprs:          boolean; { back button pressed }
      editstr:         pstring; { exit box text }
      chksts:          boolean; { checkbox status }
      buttrk:          actbuts; { onscreen button active tracking }
      diagout:         text;    { diagnostic output window }
      licfil:          text;    { license file }
      licstr:          strlpt;  { license string list }
      licptr:          strlpt;  { license strings pointer }
      licwin:          text;    { license output window }
      prgact:          boolean; { progress bar is active }
      rplcrc:          integer; { reply CRC }
      insfil:          boolean; { processing .ins file }
      insmac:          boolean; { last was macro leader ('$') }
      version:         integer; { software version }
      { character to ascii translation array }
      trnchr:          array [char] of byte;
      i, x, y:         integer;

{ ASCII value to internal character set convertion array }

fixed chrtrn: array [0..127] of char = array

   '\nul',  { 0   } '\soh',  { 1   } '\stx',  { 2   } '\etx',  { 3   }
   '\eot',  { 4   } '\enq',  { 5   } '\ack',  { 6   } '\bel',  { 7   }
   '\bs',   { 8   } '\ht',   { 9   } '\lf',   { 10  } '\vt',   { 11  }
   '\ff',   { 12  } '\cr',   { 13  } '\so',   { 14  } '\si',   { 15  }
   '\dle',  { 16  } '\dc1',  { 17  } '\dc2',  { 18  } '\dc3',  { 19  }
   '\dc4',  { 20  } '\nak',  { 21  } '\syn',  { 22  } '\etb',  { 23  }
   '\can',  { 24  } '\em',   { 25  } '\sub',  { 26  } '\esc',  { 27  }
   '\fs',   { 28  } '\gs',   { 29  } '\rs',   { 30  } '\us',   { 31  }
   ' ',     { 32  } '!',     { 33  } '"',     { 34  } '#',     { 35  }
   '$',     { 36  } '%',     { 37  } '&',     { 38  } '''',    { 39  }
   '(',     { 40  } ')',     { 41  } '*',     { 42  } '+',     { 43  }
   ',',     { 44  } '-',     { 45  } '.',     { 46  } '/',     { 47  }
   '0',     { 48  } '1',     { 49  } '2',     { 50  } '3',     { 51  }
   '4',     { 52  } '5',     { 53  } '6',     { 54  } '7',     { 55  }
   '8',     { 56  } '9',     { 57  } ':',     { 58  } ';',     { 59  }
   '<',     { 60  } '=',     { 61  } '>',     { 62  } '?',     { 63  }
   '@',     { 64  } 'A',     { 65  } 'B',     { 66  } 'C',     { 67  }
   'D',     { 68  } 'E',     { 69  } 'F',     { 70  } 'G',     { 71  }
   'H',     { 72  } 'I',     { 73  } 'J',     { 74  } 'K',     { 75  }
   'L',     { 76  } 'M',     { 77  } 'N',     { 78  } 'O',     { 79  }
   'P',     { 80  } 'Q',     { 81  } 'R',     { 82  } 'S',     { 83  }
   'T',     { 84  } 'U',     { 85  } 'V',     { 86  } 'W',     { 87  }
   'X',     { 88  } 'Y',     { 89  } 'Z',     { 90  } '[',     { 91  }
   '\\',    { 92  } ']',     { 93  } '^',     { 94  } '_',     { 95  }
   '`',     { 96  } 'a',     { 97  } 'b',     { 98  } 'c',     { 99  }
   'd',     { 100 } 'e',     { 101 } 'f',     { 102 } 'g',     { 103 }
   'h',     { 104 } 'i',     { 105 } 'j',     { 106 } 'k',     { 107 }
   'l',     { 108 } 'm',     { 109 } 'n',     { 110 } 'o',     { 111 }
   'p',     { 112 } 'q',     { 113 } 'r',     { 114 } 's',     { 115 }
   't',     { 116 } 'u',     { 117 } 'v',     { 118 } 'w',     { 119 }
   'x',     { 120 } 'y',     { 121 } 'z',     { 122 } '{',     { 123 }
   '|',     { 124 } '}',     { 125 } '~',     { 126 } '\del'   { 127 }

end;

{******************************************************************************

Convert ASCII to character

Converts an ASCII 8 bit character to local character equivalents. This is
needed when the internal characters are not ASCII. If the internal characters
are ASCII, the translation will be a no-op. Note that we don't handle ISO 646
or ISO 8859-1, which are the ISO version of ASCII, and the Western European
character sets (same as Windows) respectively.

These kinds of convertions are required because the string fields in .sym files
are stored in ASCII.

Note that characters with values 128 or over are simply returned untranslated.

******************************************************************************}

function ascii2chr(b: byte): char;

var c: char; { character holder }

begin

   if b >= 128 then c := chr(b) { out of ASCII range, just return raw }
   else c := chrtrn[b]; { translate }

   ascii2chr := c { return result }

end;

{******************************************************************************

Convert character to ASCII

Converts a character to an ASCII value. This is needed when the internal
characters are not ASCII. If the internal characters are ASCII, the translation
will be a no-op. Note that we don't handle ISO 646 or ISO 8859-1, which are the
ISO version of ASCII, and the Western European character sets (same as Windows)
respectively.

These kinds of convertions are required because the string fields in .sym files
are stored in ASCII.

Note that characters with values 128 or over are simply returned untranslated.

******************************************************************************}

function chr2ascii(c: char): byte;

begin

   chr2ascii := trnchr[c] { return translated character }

end;

{******************************************************************************

Clear message area

Clears the message area, the area at the top right used for explanitory text,
to the background color.

******************************************************************************}

procedure clrmsg;

begin

   fcolor(backcolor); { set erase color }
   frect(lmargin, 1, clientx, clienty-butbmg-buthgh-17-2); { clear it }
   fcolor(black); { restore color }

end;

{******************************************************************************

Display buttons

Displays a series of buttons in the button area. A set of buttons to be made
active is accepted, then that is compared with the button active set, and any
buttons not active are made active, and vice versa.

The button tracking keeps the buttons from being removed, and then immediately
replaced, which would potentially flash them.

******************************************************************************}

procedure butdis(view buttons: actbuts);

begin

   { process removals }
   if not (acbbak in buttons) and (acbbak in buttrk) then killwidget(bidbak);
   if not (acbnxt in buttons) and (acbnxt in buttrk) then killwidget(bidnxt);
   if not (acbcan in buttons) and (acbcan in buttrk) then killwidget(bidcan);
   if not (acbext in buttons) and (acbext in buttrk) then killwidget(bidext);

   if (acbbak in buttons) and not (acbbak in buttrk) then
      button(butbak, clienty-butbmg-buthgh, butbak+butwdt, clienty-butbmg, 
             'Back', bidbak);
   if (acbnxt in buttons) and not (acbnxt in buttrk) then
      button(butnxt, clienty-butbmg-buthgh, butnxt+butwdt, clienty-butbmg, 
             'Next', bidnxt);
   if (acbcan in buttons) and not (acbcan in buttrk) then
      button(butcan, clienty-butbmg-buthgh, butcan+butwdt, clienty-butbmg, 
             'Cancel', bidcan);

   if (acbext in buttons) and not (acbext in buttrk) then
      button(butext, clienty-butbmg-buthgh, butext+butwdt, clienty-butbmg, 
             'Exit', bidext);

   buttrk := buttons { set new active mask }

end;

{******************************************************************************

Wait button

Waits for a back, next or cancel button press. If the cancel button is pressed,
the program ends. If the next button is pressed, a normal return is done. If
the back button is pressed, we return with the "back" flag set.

******************************************************************************}

procedure waitnext(var back: boolean);

var er:   evtrec;  { event record }
    done: boolean; { done with loop button }
    p:    strlpt;  { pointer to string list }

{ draw license }

procedure drwlic;

var p:  strlpt; { pointer to string list }
    lc: integer; { line counter }

begin

   page(licwin); { clear screen }
   p := licptr; { index current position }
   lc := 1; { set line counter }
   while (p <> nil) and (lc <= 15) do begin { draw strings }

      writeln(licwin, p^.str^); { display string }
      p := p^.next; { next line }
      lc := lc+1 { count }

   end

end;

begin

   back := false; { set back not pressed }
   done := false; { set not done }
   repeat

      event(er); { get the next event }
      if er.etype = etterm then goto 99 { terminate program }
      else if er.etype = etbutton then begin { its a button assert }

         if er.butid = bidbak then back := true { signal back button }
         else if (er.butid = bidcan) or (er.butid = bidext) then 
            goto 99 { terminate }
         else if er.butid = bidnxt then done := true { stop loop }
         else if er.butid = bidup then begin { up in license }

            if (licptr <> nil) and (licptr <> licstr) then begin 

               { there is text, and not start of list }
               p := licstr; { index top of list }
               while p^.next <> licptr do p := p^.next; { find last entry }
               licptr := p; { back up one }
               drwlic { draw that }
         
            end

         end else if er.butid = biddwn then begin { down in license }

            if licptr <> nil then { there is text }
               if licptr^.next <> nil then begin { don't run off the end }

               licptr := licptr^.next; { next line }
               drwlic { draw new screen }

            end

         end

      end else if er.etype = etchkbox then begin { checkbox }

         if er.ckbxid = widchk then begin

            chksts := not chksts; { flip checkbox status }
            enablewidget(widchk, chksts) { set status on box }

         end

      end else if er.etype = etradbut then begin { radio button }

         { enable appropriate button }
         if er.radbid = bidacc then begin

            enablewidget(bidacc, true);
            enablewidget(biddac, false);
            { enable next button on license acceptance }
            butdis(buttrk+[acbnxt])

         end else if er.radbid = biddac then begin
 
            enablewidget(biddac, true);
            enablewidget(bidacc, false);
            { disable next button on license acceptance }
            butdis(buttrk-[acbnxt])

         end

      end else if er.etype = ettim then begin { repeat timer }

      end

   until done or back { done with loop, or back button pressed }

end;

{*******************************************************************************

Write text to location

Writes text to the given location in x, y.

*******************************************************************************}

procedure writerun(view s: string);

begin

   cursorg(lmargin, runy); { position }
   write(s:0); { write string }
   runy := runy+fntsiz { next position }

end;

overload procedure writerun;

begin

   writerun('')

end;

{*******************************************************************************

Process error

Prints out the given error and aborts the program.

*******************************************************************************}

procedure prcerr(e: errcod);

begin

   clrmsg; { clear message area }
   butdis([acbcan]); { activate cancel button }
   if prgact then killwidget(widprg); { remove progress bar }
   loadpict(picstp, 'stop'); { get stop sign }
   picture(picstp, lmargin, 10, lmargin+64, 10+64);
   runy := 10+64+10;
   case e of { error }

      enoinsfl: begin

         writerun('Cannot find the file:'); 
         writerun;
         writerun(insnam); 
         writerun;
         writerun('Please verify the CD-ROM is in the drive, please execute');
         writerun('this program from the top directory of the IP Pascal');
         writerun('CD-ROM.')

      end;
      enolicfil: begin

         writerun('Cannot find the file:'); 
         writerun;
         writerun(licnam); 
         writerun;
         writerun('Please verify the CD-ROM is in the drive, please execute');
         writerun('this program from the top directory of the IP Pascal');
         writerun('CD-ROM.')

      end;
      einvifl: begin

         writerun('The installation data file: '); 
         writerun;
         writerun(insnam);
         writerun;
         writerun('Is corrupted. Please verify the IP Pascal CD-ROM is in the');
         writerun('drive and undamaged. Try ejecting and reinserting the disc.');
         writerun('If the problem persists, please contact Moore/CAD customer');
         writerun('support at "support@moorecad.com".')

      end;
      edirfil: begin

         writerun('The directory name needed:');
         writerun;
         writerun(errnam);
         writerun;
         writerun('Is in use as a filename. Please check the the name, or use');
         writerun('a different installation location as required.')

      end;
      ecdrom: begin

         writerun('Media type mismatch.');
         writerun;
         writerun('The media the installer is being run from is not correct.');
         writerun('Please check the CD-ROM is in the drive, and that it');
         writerun('contains a valid copy of IP Pascal.')

      end;
      ereg: begin

         writerun('Cannot register IP Pascal as a Windows application. This');
         writerun('probally indicates a problem with your registry. You can');
         writerun('retry the installation. If the problem persists, please');
         writerun('contact Moore/CAD customer support at');
         writerun('"support@moorecad.com".')

      end;
      esys: begin

         writerun('System error');
         writerun;
         writerun('The installer has failed an internal consistency check.');
         writerun('This could mean that you have a corrupted copy of the');
         writerun('installer program. If the problem persists, please contact');
         writerun('Moore/CAD customer support at "support@moorecad.com".')

      end

   end;
   writerun;
   writerun('The installation is aborted. Any part of the installation that');
   writerun('might exist is incomplete and will not function.');
   waitnext(bakprs); { wait for button }

   goto 99 { terminate }

end;

{******************************************************************************

Print hexadecimal

Print a hexadecimal number with field width. Prints right justified with left
hand zeros filling the field. Also allows for the fact that an unsigned 32 bit
number can be read into a 32 bit signed number.

******************************************************************************}

procedure prthex(f: byte; w: integer);
 
var buff: packed array [1..10] of char; { buffer for number in ascii }
    i:    integer; { index for same }
    t:    integer; { holding }
 
begin

   { set sign of number and convert }
   if w < 0 then begin

      w := w+1+maxint; { convert number to 31 bit unsigned }
      t := w div $10000000 + 8; { extract high digit }
      writeh(diagout, t); { ouput that }
	   w := w mod $10000000; { remove that digit }
      f := 7 { force field to full }     

   end;
   hexs(buff, w); { convert the integer }
   for i := 1 to f-len(buff) do write(diagout, '0'); { pad with leading zeros }
   write(diagout, buff:0) { output number }

end;

{*******************************************************************************

Generate random number

Generates a number between 1 and maxint.

*******************************************************************************}

function rand: integer;

const a = 16807;
      m = 2147483647;

var gamma: integer;

begin

   gamma := a*(rndseq mod (m div a))-(m mod a)*(rndseq div (m div a));
   if gamma > 0 then rndseq := gamma else rndseq := gamma+m;
   rand := rndseq

end;

{*******************************************************************************

Get patch entry

Gets a patch entry, and returns a pointer to it. If there is an entry in the
free list, that is returned, otherwise, a new entry is allocated.

*******************************************************************************}

procedure getpat(var p: patptr);

begin

   if frepat <> nil then begin { there is a free entry }

      p := frepat; { index top entry }
      frepat := frepat^.next { gap top entry }

   end else new(p); { otherwise get a new one }
   p^.typ := ptnone; { clear entries }
   p^.sadr := 0;
   p^.eadr := 0;
   p^.next := nil

end;

{*******************************************************************************

Put patch entry

Places the given patch entry onto the free list.

*******************************************************************************}

procedure putpat(p: patptr);

begin

   p^.next := frepat; { push onto list }
   frepat := p

end;

{*******************************************************************************

Put patch entrys

Releases all patch entries in the active list.

*******************************************************************************}

procedure putpats;

var p: patptr; { delete patch pointer }

begin

   while patlst <> nil do begin

      p := patlst; { save delete entry }
      patlst := patlst^.next; { gap top entry }
      putpat(p) { release entry }

   end

end;

{*******************************************************************************

Enter patch entry

Starts a new patch entry. Accepts the type, start address, and end address.
The entry is placed onto the patch list.

*******************************************************************************}

procedure entpat(pt: pattyp; sadr, eadr: integer);

var p: patptr; { patch address }

begin

   getpat(p); { get new patch entry }
   p^.next := patlst; { push onto patch list }
   patlst := p;
   p^.typ := pt; { place type }
   p^.sadr := sadr; { place start }
   p^.eadr := eadr { place end }

end;

{*******************************************************************************

Calculate CRC table

Form a CRC remainder lookup table.

*******************************************************************************}

procedure gencrc;

var crcacc: integer;
    i, j:   integer;

begin

   for i := 1 to 256 do begin { for each entry }

      crcacc := (i-1) * $1000000;
      for j := 1 to 8 do { for each bit }
         { this calculation will overflow a signed integer }
         if crcacc < 0 then crcacc := crcacc+crcacc xor polynomial
         else crcacc := crcacc+crcacc;
      crctab[i] := crcacc

   end

end;

{*******************************************************************************

Add byte to CRC calculation

Adds a byte into a CRC calculation.

*******************************************************************************}

procedure addcrc(var crc: integer; b: byte);

var i: integer;

begin

   { calculate CRC this byte }
   i := (crc div $1000000 xor b) and $ff;
   crc := crc*256 xor crctab[i+1]

end;

{*******************************************************************************

Get next input file byte

Gets a byte from the input file. Calculates encoding CRC. If encoding is on,
the byte will be decoded.

*******************************************************************************}

procedure readinp(var b: byte);

begin

   read(inpfil, b); { get next byte }
   if encode then b := (b xor enccrc) and $ff; { place decoded byte }
   addcrc(enccrc, b); { add in plaintext byte to crc }

end;

{*******************************************************************************

Get next input file integer

Gets a 32 integer from the input data file. The integer is in big endian format.

*******************************************************************************}

procedure readint(var i: integer);

var b1, b2, b3, b4: byte;

begin

   readinp(b4); { get bytes in integer }
   readinp(b3);
   readinp(b2);
   readinp(b1);
   i := b4*$1000000+b3*$10000+b2*$100+b1

end;   

{*******************************************************************************

Get byte of integer

Gets a byte from an integer, numbered as follows:

0: bits 0-7
1: bits 8-15
2: bits 16-23
3: bits 24-31

This tends to be a little endian method, but it can be reversed.

*******************************************************************************}

function bytint(s: integer; i: integer): byte;

var b:    byte;
    sign: boolean;

begin

   sign := false; { set not signed by default }
   if i < 0 then begin { signed }

      sign := true; { set signed }
      i := i+1+maxint; { convert number to 31 bit unsigned }
      
   end;
   case s of { byte }

      0: b := i and $ff;
      1: b := i div $100 and $ff;
      2: b := i div $10000 and $ff;
      3: b := i div $1000000 and $ff+(ord(sign)*8)
      else prcerr(esys)

   end;

   bytint := b { return result }

end;

{*******************************************************************************

Write byte to output file

Writes a single byte to the output file, and adds that to the CRC. If the .ins
mode is active, '$' macro parameters in the file are expanded.

*******************************************************************************}

procedure wrtout(b: byte);

var p:  patptr; { patch pointer }
    b1: byte;
    i:  integer;

begin

   { check within patch area }
   p := patlst; { index top of patch list }
   b1 := b; { save output copy }
   while p <> nil do begin { traverse }

      if (outadr >= p^.sadr) and (outadr <= p^.eadr) then begin

         case p^.typ of { patch type }

            ptnone: prcerr(esys); { should not occur }
            ptmaca: { mac address table }
               b1 := maccmp[(outadr-p^.sadr) div 6+1][(outadr-p^.sadr) mod 6+1];
            ptcpui: { cpu id }
               b1 := bytint((outadr-p^.sadr) mod 4, 
                            cpucmp[(outadr-p^.sadr) div 4+1]);
            ptwinv: { windows version }
               b1 := bytint(outadr-p^.sadr, vercmp);
            pttimi: { release time }
               b1 := bytint(outadr-p^.sadr, timlim)

         end

      end;
      p := p^.next { next entry }

   end;
   { check for macro processing }
   if insfil and insmac then begin { process macro expansions }

      if b1 = chr2ascii('p') then { its the IP install path macro }
         for i := 1 to len(prgpth) do write(outfil, chr2ascii(prgpth[i]))
      else 
         { Not a macro specifier. We just output the character as normal. This
           allows '$$' to represent a single '$'. }
         write(outfil, b1); { output to file }
      insmac := false { turn off macro leader }

   end else begin

      if insfil and (b1 = chr2ascii('$')) then insmac := true { set on macro leader }
      else write(outfil, b1); { output to file }

   end;
   addcrc(filcrc, b); { add to CRC }
   outadr := outadr+1 { next byte }

end;

{*******************************************************************************

Next buffer index

Increments a buffer index. Handles wrapping around the buffer end.

*******************************************************************************}

function next(i: bufinx): bufinx;

begin

   { increment or wrap }
   if i < bufmax then i := i+1 else i := 1;

   next := i { return result }

end;

{*******************************************************************************

Subtract from buffer pointer

Subtracts an offset from a buffer pointer, with wraparound.

*******************************************************************************}

procedure sub(var i: bufinx; l: bufdst);

begin

   if i-l >= 1 then i := i-l { subtract for no-wraparound case }
   else i := bufmax-(l-i) { subtract for wraparound case }

end;

{*******************************************************************************

Write character/control character to output

A diagnostic, writes a character to the output. If the character is an ASCII
control (less than space), it is output as '\'.

*******************************************************************************}

procedure wrtchr(c: char);

begin

   if ord(c) >= 128 then c := chr(ord(c)-128); { remove any parity }
   if c < ' ' then write(diagout, '\\') { control }
   else write(diagout, c) { character }

end;

{*******************************************************************************

Output buffer

A diagnostic, outputs the entire buffer.

*******************************************************************************}

procedure outbuf;

var i: bufinx;

begin

   writeln(diagout, 'Buffer: ');
   for i := 1 to bufmax do wrtchr(chr(buff[i]));
   writeln(diagout);
   for i := 1 to bufmax do if i = inpinx then 
      write(diagout, 'I') else write(diagout, ' ');
   writeln(diagout)

end;

{*******************************************************************************

Decompression loop

Performs the basic decompression loop. The file signature is verified and
skipped, then each tolken in the file is interpreted. For run tolkens, the
input is simply copied to the output and placed into the caching queue. For
match tolkens, we use the displacement to copy old cache data back to the top
of the queue and output that as well.

The algoritim only needs a queue input pointer, and does not need to check
overflow, since the queue will be continually overwritten, and supposedly the
input data won't give us an invalid offset.

*******************************************************************************}

procedure decompress;

var b, b1:     byte;    { byte buffers }
    filend:    boolean; { end of file flag }
    i:         runlen;  { length index }
    x:         bufinx;  { index for buffer }
    tlknum:    integer; { tolken sequence number }

begin

   filend := false; { set not file end }
   inpinx := 1; { set initial buffer indexes }
   tlknum := 1; { set 1st tolken }
   filcrc := 0; { clear CRC accumulator }
   cmpcrc := 0; { clear comparision CRC }
   repeat { decompress loop }

      readinp(b); { get a tolken byte }
      if b = 0 then begin { its a special tolken }

         readinp(b1); { get extended code }
         if b1 = ord(scend) then filend := true { set end of file section }
         else if b1 = ord(sccrc) then begin { its the CRC }
            
            readinp(b); { get and assemble the CRC value }
            cmpcrc := b*$1000000;
            readinp(b);
            cmpcrc := cmpcrc+b*$10000;
            readinp(b);
            cmpcrc := cmpcrc+b*$100;
            readinp(b);
            cmpcrc := cmpcrc+b
   
         end else prcerr(einvifl) { invalid special code }

      end else if b >= 16 then begin { its a match tolken }

         readinp(b1); { get displacement }
         x := inpinx; { get current input index }
         sub(x, b and $f*256+b1); { find displacement location }
         if diag and tolken then begin
 
            write(diagout, tlknum:1, ': ');
            write(diagout, 'Pointer: ', inpinx:1, ' ');
            write(diagout, 'Match tolken, length: ', b div 16:1, ' offset: ', 
                  b and $f*256+b1:1, ' data: ''')

         end;
         for i := 1 to b div 16 do begin { transfer match to output }

            b := buff[x]; { get match byte }
            x := next(x); { find next }
            if diag and tolken then wrtchr(chr(b)); { write diagnostic output }
            buff[inpinx] := b; { place byte in queue }
            inpinx := next(inpinx); { advance queue pointer }
            wrtout(b) { output to file }
         
         end;
         { terminate diagnostic line }
         if diag and tolken then writeln(diagout, '''');
         tlknum := tlknum+1 { count tolkens }

      end else begin { its a run tolken }

         if diag and tolken then begin

            write(diagout, tlknum:1, ': ');
            write(diagout, 'Run tolken, length: ', b:1, ' data: ''')

         end;
         for i := 1 to b do begin { transfer from input to output }

            readinp(b); { get next byte }
            if diag and tolken then wrtchr(chr(b)); { write diagnostic output }
            buff[inpinx] := b; { place byte in queue }
            inpinx := next(inpinx); { advance queue pointer }
            wrtout(b) { output to file }

         end;
         { terminate diagnostic line }
         if diag and tolken then writeln(diagout, '''');
         tlknum := tlknum+1 { count tolkens }

      end

   until filend; { until end of file tolken is seen }
   if diag then writeln(diagout, 'End of file');
   if diag then begin

      write(diagout, 'CRC for file: ');
      prthex(8, filcrc);
      writeln(diagout);
      write(diagout, 'Comparision CRC: ');
      prthex(8, cmpcrc);
      writeln(diagout)

   end;
   if cmpcrc <> filcrc then prcerr(einvifl) { CRC does not match }

end;

{*******************************************************************************

Check directory exists

Checks if the given path name exists, and corresponds to a directory. Returns
true if so.

*******************************************************************************}

function existsdir(view s: string): boolean;

var fp: filptr;  { file entry pointer }
    e:  boolean; { exists flag }

begin

   e := false; { default to does not exist }
   list(s, fp); { get list of files }
   if fp <> nil then begin { found one }

      if atdir in fp^.attr then e := true; { found a directory }
      dispose(fp) { release entry }

   end;

   existsdir := e { return result }

end;

{*******************************************************************************

Get path

Gets the program path directly from the registry. Places it in the given string.
If an error results, the err variable will be set, otherwise reset.

Windows dependent.

*******************************************************************************}

procedure getpath(var s: string; var err: boolean);

var r, k, v, l, i, t: integer;
    kv:               packed array 250 of char;

begin

   err := false; { set no error }
   v := $8000000;
   v := v*16;
   r := sc_regopenkey(sc_hkey_local_machine or v, 
           'system\\controlset001\\control\\session manager\\environment', k);
   if r <> 0 then err := true { set error }
   else begin

      l := 250;
      r := sc_regqueryvalueex(k, 'path', t, s, l);
      if r <> 0 then err := true
      else begin

         r := sc_regclosekey(k);
         if r <> 0 then err := true

      end

   end

end;

{*******************************************************************************

Set path

Sets the program path directly from to registry. Places it from the given
string. If an error results, the err variable will be set, otherwise reset.

Windows dependent.

*******************************************************************************}

procedure setpath(view s: string; var err: boolean);

var r, k, v, l: integer;
    kv:               packed array 250 of char;

begin

   err := false; { set no error }
   v := $8000000;
   v := v*16;
   r := sc_regopenkey(sc_hkey_local_machine or v, 
           'system\\controlset001\\control\\session manager\\environment', k);
   if r <> 0 then err := true { set error }
   else begin

      r := sc_regsetvalueex(k, 'path', 2, s, len(s)+1);
      if r <> 0 then err := true
      else begin

         r := sc_regclosekey(k);
         if r <> 0 then err := true

      end

   end

end;

{*******************************************************************************

Set key value

Sets the given value under a key. The root key value is specified, along with
the subkey, then the string value of the key.

*******************************************************************************}

procedure setkeyvalue(rk: integer; view sk, vn, vs: string);

var r, k, v: integer;

begin

   err := false; { set no error }
   v := $8000000;
   v := v*16;
   r := sc_regopenkey(rk or v, sk, k);
   if r <> 0 then prcerr(ereg); { error }
   r := sc_regsetvalueex(k, vn, 2, vs, len(vs)+1);
   if r <> 0 then prcerr(ereg); { error }
   r := sc_regclosekey(k);
   if r <> 0 then prcerr(ereg) { error }

end;

{*******************************************************************************

Create key

Creates a regstry key, in the specified root key, with the specified subkey.
Does not leave the key open.

*******************************************************************************}

procedure createkey(rk: integer; view sk: string);

var r, ki, v: integer;

begin

   v := $8000000;
   v := v*16;
   r := sc_regcreatekey(rk or v, sk, ki); { create the key }
   if r <> 0 then prcerr(ereg); { cannot register }
   r := sc_regclosekey(ki); { close the key }
   if r <> 0 then prcerr(ereg); { can't close it  }

end;

{*******************************************************************************

Create registration database

Creates a registration entry in the "uninstall" key section of the Windows
registry.

*******************************************************************************}

procedure register;

const 

   { root key, and uninstall key }
   root = sc_hkey_local_machine;
   key = 'software\\microsoft\\windows\\currentversion\\uninstall\\IP Pascal';

var tmpstr: filnam;
    dspnam: filnam; { display name }
    verstr: filnam;

begin

   { construct version number }
   ints(verstr, version div 1000000, 1); { place major number }
   cat(verstr, '.');
   ints(tmpstr, version div 10000 mod 100, 1); { place minor number }
   cat(verstr, tmpstr);
   if version mod 10000 <> 0 then begin

      { If a build number is present, then include that. Normally, releases
        should not have build numbers. }
      cat(verstr, '.');
      ints(tmpstr, version mod 10000, 1); { place minor number }
      cat(verstr, tmpstr)

   end;
   { form display name }
   copy(dspnam, 'IP Pascal');
   if fdemo then cat(dspnam, ' evaluation/student')
   else if fbeta then cat(dspnam, ' beta');
   insert(dspnam, verstr, len(dspnam)+2);
   if timlim <> maxint then begin { add date/time limit }

      cat(dspnam, ' (license expires');
      dates(tmpstr, local(timlim)); { add date }
      insert(dspnam, tmpstr, len(dspnam)+2);
      times(tmpstr, local(timlim)); { add time }
      insert(dspnam, tmpstr, len(dspnam)+2);
      cat(dspnam, ')')

   end;
   createkey(root, key);
   setkeyvalue(root, key, 'displayname', dspnam);
   setkeyvalue(root, key, 'displayversion', verstr);
   setkeyvalue(root, key, 'installlocation', prgpth);
   copy(tmpstr, prgpth); { construct fully pathed uninstall }
   cat(tmpstr, '\\launch.exe');
   setkeyvalue(root, key, 'uninstallstring', tmpstr);
   setkeyvalue(root, key, 'publisher', 'Moore/CAD');
   setkeyvalue(root, key, 'contact', 'support@moorecad.com');
   copy(tmpstr, prgpth); { construct fully pathed readme.txt }
   cat(tmpstr, '\\readme.txt');
   setkeyvalue(root, key, 'readme', tmpstr);
   setkeyvalue(root, key, 'urlinfoabout', 'www.moorecad.com/ippas');

end;

{*******************************************************************************

Check path is CD-ROM

Checks if the program path (the path this program was loaded from) is a CD-ROM.

Windows dependent.

*******************************************************************************}

procedure chkcdrom;

var s: filnam;  { path string }
    r: integer; { function result }
    i: integer; { index for string }

begin

   if fcdonly then begin { perform CD-ROM check }

      getpgm(s); { get program path }
      { we need to isolate the drive letter and following '\' }
      i := 1;
      while (s[i] <> '\\') and (i < filmax) do i := i+1;
      if s[i] = '\\' then i := i+1; { index after '\' }
      { blank out the rest }
      while i < filmax do begin s[i] := ' '; i := i+1 end;
      r := sc_getdrivetype(s);
      if r <> sc_drive_cdrom then prcerr(ecdrom) { must run from CD-ROM }

   end

end;

{*******************************************************************************

Check on path

Checks if the given string is part of a path. The path is divided up into
sections delimited by ';', space trimmed and each section compared to the
compare string. Returns true if there is a match.

*******************************************************************************}

function chkpth(view p, s: string): boolean;

var m:       boolean; { match flag }
    ts, ts1: filnam; { holding strings }

begin

   m := false; { set no match by default }
   copy(ts, p); { copy path to temp }
   while index(ts, ';') > 0 do begin { while path is divisible }

      extract(ts1, ts, 1, index(ts, ';')-1); { get left side }
      if compp(ts1, s) then m := true; { set match }
      extract(ts1, ts, index(ts, ';')+1, len(ts)); { get right side }
      copy(ts, ts1) { place as original }

   end;
   if len(ts) > 0 then begin { try last, whole path match }

      trim(ts1, ts); { trim off spaces }
      if compp(ts1, s) then m := true { set match }

   end;

   chkpth := m { return result }

end;

{*******************************************************************************

Installation loop

Performs the installation of files. Each tolken is read in, and the following
actions performed:

Code    Action
================================================================================
scpth   Reads the path name for the upcoming files, and verifies the path 
        exists. If not, then it is created.
scnam   Sets the name for the upcoming file.
scstr   Start decoding the file. The filename and path are used to create a
        file, then the file section is decoded and placed there.
sccrc   Gives the original CRC for the file. The CRC for the actual file is
        is checked against this.
scend   Marks the end of a file section.
sceof   Marks the end of the install.

*******************************************************************************}

procedure runinstall;

var b, b1:   byte;    { input byte holder }
    path:    filnam;  { path name holder }
    name:    filnam;  { temp name holder }
    outnam:  filnam;  { output file name }
    p, n, e: filnam;  { filename components }
    endall:  boolean; { end of input file flag }
    pa:      integer; { patch address }
    i:       integer;

{ read string from input file }

procedure readstr(var s: string);

var l: byte; { length holder }
    i: byte; { string index }

begin

   clears(s); { clear result string }
   readinp(l); { get length of string }
   for i := 1 to l do begin { get string }

      readinp(b); { get next string character }
      s[i] := ascii2chr(b) { place in string }

   end

end;

begin

   { create the program directory, and set that as the default path }
   copy(path, prgpth);
   { check in use as filename }
   if exists(path) then begin

      copy(errnam, prgpth); { place error name }
      prcerr(edirfil) { directory is a file }

   end;
   if not existsdir(path) then makpth(path);
   clears(name); { clear destination filename }
   { check proper signature, "INSL" }
   readinp(b);
   if b <> chr2ascii('I') then prcerr(einvifl);
   readinp(b);
   if b <> chr2ascii('N') then prcerr(einvifl);
   readinp(b);
   if b <> chr2ascii('S') then prcerr(einvifl);
   readinp(b);
   if b <> chr2ascii('T') then prcerr(einvifl);
   repeat { install loop }

      readinp(b); { get tolken byte }
      { At this level in the protocol, we should see only extended tolken 
        bytes. }
      if b <> 0 then prcerr(einvifl); { invalid file format }
      readinp(b); { get code byte }
      if (b <> ord(scpth)) and (b <> ord(scnam)) and (b <> ord(scstr)) and
         (b <> ord(scmaca)) and (b <> ord(sccpui)) and (b <> ord(scwinv)) and
         (b <> ord(sctimi)) and (b <> ord(scser)) and (b <> ord(sctim)) and 
         (b <> ord(sccdol)) and (b <> ord(scdemo)) and (b <> ord(scbeta)) and
         (b <> ord(sctiml)) and (b <> ord(scver)) and (b <> ord(scsend)) and 
         (b <> ord(sceof)) then
         prcerr(einvifl); { should be one of these leaders }
      if b = ord(scpth) then begin { process path name }

         readstr(name); { get path string }
         { construct a full path based on that }
         maknam(path, prgpth, name, '');
         { check in use as filename }
         if exists(path) then begin

            copy(errnam, prgpth); { place error name }
            prcerr(edirfil) { directory is a file }

         end;
         { create that path if it doesn't already exist }
         if not existsdir(path) then makpth(path)

      end else if b = ord(scnam) then begin { process filename }

         if len(path) = 0 then prcerr(einvifl); { should have defined a path }
         readstr(name); { get output filename }
         brknam(name, p, n, e); { break down to components }
         maknam(outnam, path, n, e) { create full name }

      end else if b = ord(scstr) then begin { decompress single file }

         { if we are at decompression, and we haven't received all of the
           proper system parameters, its an error }
         if (sernum = 0) or (reltim = -maxint) then prcerr(einvifl);
         progbarpos(widprg, 
                    trunc(location(inpfil)*(maxint * 1.0)/length(inpfil)));
         { should have defined a filename }
         if len(outnam) = 0 then prcerr(einvifl);
         if diag then writeln(diagout, 'Installing: ', outnam:0);
         brknam(outnam, p, n, e); { find extention }
         insfil := compp(e, 'ins'); { set .ins status }
         assign(outfil, outnam); { open output file }
         rewrite(outfil);
         outadr := 1; { set on 1st address of output }
         decompress; { run decompression }
         close(outfil); { close file }
         putpats { release all patches }
         
      end else if b = ord(scmaca) then begin { mac address table }

         readint(pa); { get the mac table address }
         entpat(ptmaca, pa, pa+10*6-1) { enter the patch }

      end else if b = ord(sccpui) then begin { cpu id }

         readint(pa); { get the cpu id address }
         entpat(ptcpui, pa, pa+4*4-1) { enter the patch }

      end else if b = ord(scwinv) then begin { windows version }

         readint(pa); { get the windows version address }
         entpat(ptwinv, pa, pa+1*4-1) { enter the patch }

      end else if b = ord(sctimi) then begin { release time }

         readint(pa); { get the windows version address }
         entpat(pttimi, pa, pa+1*4-1) { enter the patch }

      end 
      { the system area parameters were already read, but must be
        properly skipped }
      else if b = ord(scser) then readint(i) { discard serial number }
      else if b = ord(sctim) then readint(i) { discard release time }
      else if b = ord(sccdol) then readinp(b1) { discard CD only flag }
      else if b = ord(scdemo) then readinp(b1) { discard demo flag }
      else if b = ord(scbeta) then readinp(b1) { discard beta flag }
      else if b = ord(sctiml) then readint(i) { discard time limit }
      else if b = ord(scver) then readint(i) { discard version }
      { end of system area, change decoding value to match reply }
      else if (b = ord(scsend)) and not fdemo then 
         enccrc := enccrc xor (actrpl[4] xor datcrc)
      else if b = ord(sceof) then endall := true { end of input file }

   until endall { until all done } 

end;

{*******************************************************************************

Get windows registation parameters

Loads the current Windows registration parameters. The parameters loaded are:

1. The cpu id.
2. The MAC address(es) for the current network card(s).
3. The windows version number and build.

*******************************************************************************}

procedure getreg;

var eax, ebx, ecx, edx: integer; { registers to the cpuid instruction }
    r:                  integer; { return value }
    ifn:                integer; { interface number }
    ifd:                sc_mib_ifrow; { interface info structure }
    mi:                 integer; { mac address table index }
    i, x:               integer;

procedure digest(var seq: integer);
 
const a = 16807;
      m = 2147483647;

var gamma: integer;

begin

   gamma := a*(seq mod (m div a))-(m mod a)*(seq div (m div a));
   if gamma > 0 then seq := gamma else seq := gamma+m;

end;

begin

   { get cpu id }

   eax := 0; { set function 0, find cpu id string }
   cpuid(eax, ebx, ecx, edx);
   if (eax <> 0) or (ebx <> 0) or (ecx <> 0) or (edx <> 0) then begin

      { cpu id valid, place parts of cpu id }
      cpucmp[1] := ebx;
      cpucmp[2] := edx;
      cpucmp[3] := ecx;
      eax := 1; { set function 1, get cpu parameters }
      cpuid(eax, ebx, ecx, edx);
      { place family, model and stepping }
      cpucmp[4] := eax

   end;
   { get any mac components }
   ifn := 1; { set interface #1 }
   mi := 1; { set mac table entry 1 }
   repeat

      ifd.dwindex := ifn; { set interface number to look for }
      r := sc_getifentry(ifd); { get interface info }
      if r = 0 then { possible mac address }
         if (ifd.dwtype = sc_mib_if_type_ethernet) and 
            (ifd.dwphysaddrlen = 6) and (mi <= 10) then begin

         { Its an ethernet if, it was 6 byte mac entries, and the mac table
           isn't full, copy to mac table. }
         for i := 1 to 6 do maccmp[mi][i] := ifd.bphysaddr[i-1];
         mi := mi+1 { next mac table entry }

      end;
      ifn := ifn+1 { next logical interface number }

   until r <> 0;
   vercmp := sc_getversion; { get windows version }

   { form hardware digest }

   hwrcrc := $6989342; { form seed }
   { add in cpuid }
   for i := 1 to 4 do
      for x := 0 to 3 do
         addcrc(hwrcrc, bytint(x, cpucmp[i])); 
   { add in mac }
   for i := 1 to 10 do
      for x := 1 to 6 do
         addcrc(hwrcrc, maccmp[i][x]);
   { add in windows version }
   for i := 0 to 3 do addcrc(hwrcrc, bytint(i, vercmp));
   
end;

{*******************************************************************************

Write number in LN32 format

Writes a 32 bit number in 7 digit LN32 format. LN32 is a character that consists
of the 26 alpha characters, the 10 digits, and leaves a few out to eliminate
look alikes (such as 0 and O), to arrive at 32 values or 5 bits per digit. This
uses 7 digits to encode a 32 bit value.

Converts all 32 bits as an unsigned number. Note that the 7th (most significant)
ln has only 2 bits in it.

*******************************************************************************}
                                            
procedure wrtln32(v: integer);
                                                                
var s:    packed array 7 of char;
    i:    integer;
    sign: boolean;
 
begin

   { set sign of number and convert }
   sign := false; { set not signed }
   if v < 0 then begin

      v := v+1+maxint; { convert number to 31 bit unsigned }
      sign := true { and move sign to flag }

   end;
   for i := 7 downto 1 do begin { extract digits }

      { put the sign back as a value }
      if i <> 1 then s[i] := ln32[v mod 32+1] { find encoded digit }
      else s[i] := ln32[v mod 32+2+1]; { find encoded digit }
      v := v div 32 { next digit }

   end;
   write(s)
   
end;

{*******************************************************************************

Calculate activation code CRC

Calculates a CRC against the activation code. Each of the activation code
parts is fed, a byte at a time, into the CRC generator.

*******************************************************************************}

procedure crcact;

{ enter integer to CRC }

procedure crcint(v: integer);

var i: integer;

begin

   for i := 0 to 3 do addcrc(actcrc, bytint(i, v)) { add each byte into CRC }

end;

begin

   actcrc := $56939047; { set initial CRC code }
   crcint(hwrcrc); { calculate with hardware hash }
   crcint(sernum); { calculate with serial number }
   crcint(reltim); { calculate with release time }
   crcint(datcrc); { calculate with data CRC }
   crcint(instim)  { calculate with install time }

end;

{*******************************************************************************

Calculate reply code CRC

Calculates a CRC against the reply code. Each of the reply code
parts is fed, a byte at a time, into the CRC generator.

*******************************************************************************}

procedure crcrpl;

var i: integer;

{ enter integer to CRC }

procedure crcint(v: integer);

var i: integer;

begin

   for i := 0 to 3 do addcrc(rplcrc, bytint(i, v)) { add each byte into CRC }

end;

begin

   rplcrc := $19746335; { set initial CRC code }
   for i := 1 to actnum-1 do crcint(actrpl[i])

end;

{*******************************************************************************

Initalize translation array

Initialize random bit translator array. The bits in the activation message,
both going to and from the installer, are randomly scrambled to the bit level.
The xlrarr data controls which bit it mapped to which location in the message.
We initialize the array to random, but non-repeating values.

*******************************************************************************}

procedure inixlt(s: integer);

var i: integer; { index for translation array }
    r: integer; { random number pick }

function match(r: integer): boolean;

var x: integer; { index for translation array }
    m: boolean; { match found }

begin

   m := false; { set no match found by default }
   { search for any matches behind fill index }
   for x := 1 to i-1 do if xltarr[x] = r then m := true;

   match := m { return result }

end;

begin

   rndseq := s; { set initial seed }
   for i := 1 to actnum*32 do begin

      repeat { get random contents for array }
  
        r := rand mod (actnum*32); { get candidate }
       
      until not match(r); { until it does not duplicate previous }
      xltarr[i] := r { place new translation key }

   end

end;

{*******************************************************************************

Write activation code

Writes out the activation code block in ln32 numbers. Because ln32 numbers are
5 bits, and don't divide evenly into the 32 bit integers we use, the code block
is treated as a long stream of bits so that it has no gaps.

We translate the outbound codes so that the bits don't line up next to each
other. This creates extra security for the code.

*******************************************************************************}

procedure wrtact;

var i:      integer; { bit index }
    lnc:    integer; { ln32 bit count }
    acc:    integer; { ln32 accumulator }
    s:      packed array actnum*32 div 5+1 of char; { digit holding buffer }
    si:     integer; { index for holding buffer }

{ get single bit of integer }

function bit(s, i: integer): boolean;

var t: boolean; { true/false bit }
    x: integer;

begin

   if s = 31 then begin { it's the sign bit }

      if i < 0 then t := true else t := false { set according to sign }
   
   end else begin { non-sign bits }

      if i < 0 then i := i+1+maxint; { remove sign bit }
      for x := 1 to s do i := i div 2; { shift bit into place }
      t := odd(i) { test bit 0 }

   end;

   bit := t { return the bit }

end;

{ get bit from entire activation data }

function actbit(s: integer): boolean;

begin

   s := xltarr[s+1]; { translate outbound }
   actbit := bit(s mod 32, actdat[s div 32+1])

end;

begin

   si := 1; { index 1st output digit }
   lnc := 0; { clear ln32 bit counter }
   acc := 0; { clear accumulator }
   for i := 0 to actnum*32-1 do begin { for all bits of activation data }

      { add new bit to accumulator, with bit ordering to word }
      acc := acc*2+ord(actbit((i div 32)*32+(31-i mod 32)));
      lnc := lnc+1; { next bit }
      if lnc > 4 then begin { output digit }

         s[si] := ln32[acc+1]; { place digit }
         si := si+1; { next digit position }
         acc := 0; { clear accumulator }
         lnc := 0 { clear ln32 bit count }

      end

   end;
   if lnc > 0 then begin { output remainder digit }

      while lnc <= 4 do begin { place last digit in the correct position }

         acc := acc*2; { move left }
         lnc := lnc+1 { next bit }

      end;
      s[si] := ln32[acc+1]; { place digit }
      si := si+1 { next digit position }

   end;
   { output digits }
   for si := 1 to si-1 do begin

      if ((si-1) mod 6 = 0) and (si <> 1) then write(' ');
      write(s[si]) { write digit }

   end

end;

{*******************************************************************************

Convert activation code

Converts an activation code from ln32 form to a binary block. Expects the
activation code string. An error variable is set if the string contains invalid
characters, or is too long. String should be converted to upper case before
calling this routine.

We translate the outbound codes so that the bits don't line up next to each
other. This creates extra security for the code.

*******************************************************************************}

procedure rdact(view s: string; var err: boolean);

var t:          filnam;  { temp string }
    ai:         integer; { index for activation data }
    actdig:     integer; { number of ln32 digits in activation data }
    bi, cbi:    integer; { index for activation bits }
    i, x, c, p: integer;

{ validate and normalize the string }

procedure cvtact;

var i:      integer; { index }
    t1, t2: filnam; { string temps }

begin

   copy(t, s); { make a temp copy }
   ucases(t); { convert to upper case }
   err := false; { set no error }
   { check any bad characters, which includes all punctuation besides space,
     and the letters 'I' and 'L' }
   for i := 1 to filmax do 
      if not (t[i] in ['0'..'9', 'A'..'H', 'J'..'K', 'M'..'Z', ' ']) then 
         err := true;
   if not err then begin { continue }

      { remove all spaces from format }
      while (index(t, ' ') > 0) and (index(t, ' ') < len(t)) do begin 

         extract(t1, t, 1, index(t, ' ')-1); { get left }
         extract(t2, t, index(t, ' ')+1, len(t)); { get right }
         copy(t, t1); { construct result }
         cat(t, t2)

      end;
      { convert all O's to 0's, all V's to U's }
      for i := 1 to filmax do begin

         if t[i] = 'O' then t[i] := '0'; { convert O to 0 }
         if t[i] = 'V' then t[i] := 'U'; { convert O to 0 }

      end;
      if len(t) <> actdig then err := true { incorrect digit count }
         
   end
   
end;

{ set single bit of integer }

procedure setbit(s: integer; var i: integer);

var t, x: integer;

begin

   if s = 31 then begin { sign bit }

      t := maxint; { set maxint+1 }
      t := t+1

   end else begin

      t := 1; { set initial bit }
      for x := 1 to s do t := t*2 { move to position }

   end;

   i := i or t { set the bit }

end;

procedure setact(s: integer);

begin

   s := xltarr[s+1]; { translate inbound }
   setbit(s mod 32, actrpl[s div 32+1]) { set bit in word }

end;

begin

   { find total digits in activation string }
   actdig := actnum*32 div 5; { set number of activation digits }
   if actnum*32 mod 5 > 0 then actdig := actdig+1; { round up }
   for ai := 1 to actnum do actrpl[ai] := 0; { clear activation reply data }
   cvtact; { convert and validate string }
   if not err then begin { convert to bits }

      bi := 0; { set index in activation bits }
      for i := 1 to actdig do begin { process digits }
      
         c := 0; { clear ln32 code }
         for x := 1 to 32 do if t[i] = ln32[x] then c := x; { match ln32 codes }
         if c = 0 then prcerr(esys); { should have found it }
         c := c-1; { zero adjust }
         p := 16; { set highest power in ln32 code (0-31) }
         while p <> 0 do begin { move those bits into the activation data }

            { if the bit is set, move it into activation }
            if p and c > 0 then begin
             
               cbi := (bi div 32)*32+(31-bi mod 32); { find convolution }
               { Because the number of digits in the activation record is
                 rounded up, the last digit will contain null bits. If one of
                 these is set, the code is invalid. }
               if cbi >= actnum*32 then err := true
               else setact(cbi)

            end;
            p := p div 2; { next power }
            bi := bi+1 { next bit }
         
         end

      end

   end

end;

{*******************************************************************************

Encode outbound activation code

Performs encoding (encyphering) on the outbound activation code. We use a simple
xor with pseudorandom sequence for now.

*******************************************************************************}

procedure outenc;

var i: integer; { index }

begin

   rndseq := $48998375; { start random number sequence }
   for i := 1 to actnum do actdat[i] := actdat[i] xor rand

end;

{*******************************************************************************

Decode inbound activation code

Performs decoding (encyphering) on the inbound activation code. We use a simple
xor with pseudorandom sequence for now.

*******************************************************************************}

procedure inpdec;

var i: integer; { index }

begin

   rndseq := $69384707; { start random number sequence }
   for i := 1 to actnum do actrpl[i] := actrpl[i] xor rand

end;

{*******************************************************************************

Check installer data file

Checks if the installer file exists, and if it is, the file is CRCed. The
installer file is specifically given the program path so that it will be
found at the same location as the install program. That fully pathed name is
left in insnam.

*******************************************************************************}

procedure chkinst;

begin

   getpgm(tmpstr); { get program path }
   brknam(definst, p, n, e); { break apart install data file name }
   maknam(insnam, tmpstr, n, e); { construct with program path }
   if not exists(insnam) then begin { can't find the file }

      copy(errnam, insnam); { set error file }
      prcerr(enoinsfl) { process not found error }

   end;
   assign(inpfil, insnam); { open installer data file }
   reset(inpfil);
   inpopn := true; { set file is open }
   { check the file passes CRC }
   datcrc := $75629948; { set data CRC to arbitrary starting value }
   datcrc1 := 0; { clear the rest }
   datcrc2 := 0;
   datcrc3 := 0;
   b := 0; { clear input bytes }
   b1 := 0;
   b2 := 0;
   b3 := 0;
   while not eof(inpfil) do begin { calculate CRC }

      datcrc4 := datcrc3; { shift crcs }
      datcrc3 := datcrc2;
      datcrc2 := datcrc1;
      datcrc1 := datcrc;
      b3 := b2; { shift input bytes }
      b2 := b1;
      b1 := b;
      read(inpfil, b); { get next byte }
      addcrc(datcrc, b) { add to crc }

   end;
   datcrc := datcrc4; { back up data crc }
   { now we have the CRC check value in b3b2b1b0, the correct CRC in datcrc3 }
   if b3*$1000000+b2*$10000+b1*$100+b <> datcrc then prcerr(einvifl);
   close(inpfil); { close data file }
   inpopn := false { set file is closed }

end;

{*******************************************************************************

Read install file system data area

Reads the system area at the start of the install.dat file. The system 
parameters are needed prior to many of the setup operations, so we read it 
first.

*******************************************************************************}

procedure readsys;

var b, b1: byte; { byte input holders }

begin

   enccrc := $65823792; { set encoder CRC to arbitrary starting value }
   assign(inpfil, insnam); { open installer data file }
   reset(inpfil); { rewind to beginning }
   inpopn := true; { set file is open }
   { check proper signature, "INSL" }
   readinp(b);
   if b <> chr2ascii('I') then prcerr(einvifl);
   readinp(b);
   if b <> chr2ascii('N') then prcerr(einvifl);
   readinp(b);
   if b <> chr2ascii('S') then prcerr(einvifl);
   readinp(b);
   if b <> chr2ascii('T') then prcerr(einvifl);
   repeat { get system parameters from file }

      readinp(b); { get tolken byte }
      { At this level in the protocol, we should see only extended tolken 
        bytes. }
      if b <> 0 then prcerr(einvifl); { invalid file format }
      readinp(b); { get code byte }
      if (b <> ord(scser)) and (b <> ord(sctim)) and (b <> ord(sccdol)) and
         (b <> ord(scdemo)) and (b <> ord(scbeta)) and (b <> ord(sctiml)) and
         (b <> ord(scver)) and (b <> ord(scsend)) then
         prcerr(einvifl); { should be one of these leaders }
      if b = ord(scser) then readint(sernum) { get the serial number }
      else if b = ord(sctim) then readint(reltim) { get the release time }
      else if b = ord(sccdol) then begin { get CD-ROM only flag }

         readinp(b1); { get flag }
         fcdonly := b1 <> 0 { set flag }

      end else if b = ord(scdemo) then begin { get demo flag }

         readinp(b1); { get flag }
         fdemo := b1 <> 0 { set flag }

      end else if b = ord(scbeta) then begin { get beta flag }

         readinp(b1); { get flag }
         fbeta := b1 <> 0 { set flag }

      end else if b = ord(sctiml) then readint(timlim) { get the release time }
      else if b = ord(scver) then readint(version) { get the version }

   until b = ord(scsend);
   close(inpfil); { close file }
   inpopn := false { set file is closed }

end;

{******************************************************************************

Translate windows color to rgb color

Translates a windows integer color to our ratioed maxint rgb color.

******************************************************************************}

procedure win2rgb(wc: integer; var r, g, b: integer);

begin

   r := wc and $ff * $800000; { get red value }
   g := wc div 256 and $ff * $800000; { get greeen value }
   b := wc div 65536 and $ff * $800000 { get blue value }

end;

{*******************************************************************************

Run activation

Runs the server exchange sequence to register the product.

*******************************************************************************}

procedure activate;

label page1, { pages }
      page2,
      page3,
      exit;

var tmpstr: filnam;  { holding string }
    err:    boolean; { error return }

begin

   { ************************** Present activation page ********************** }

   page1:

   butdis([acbbak, acbnxt, acbcan]); { activate back, next and cancel buttons }
   clrmsg; { clear message area }
   runy := 10; { set the runner to the top }
   writerun('Your IP Pascal release must be activated during this');
   writerun('installation. The software is activated by transmitting an');
   writerun('identification number for this program, and the computer it is');
   writerun('being installed on, to a server, and receiving a reply back');
   writerun('which will activate the software. No personal information is');
   writerun('sent during this process. Alternately, you can choose to');
   writerun('manually enter the activation code. This may be required if');
   writerun('you are installing this software to a computer not connected');
   writerun('to the internet.');
   checkbox(lmargin, etylin, clientx-20, etylin+20, 
            'Automatically activate IP Pascal', widchk);
   enablewidget(widchk, true); { enable it by default }
   chksts := true;
   waitnext(bakprs); { wait for button }
   killwidget(widchk); { remove checkbox }
   if bakprs then goto exit; { go back }

   { ********************* Present negative contact page ********************* }

   if chksts then begin

      butdis([acbbak, acbcan]); { activate back, next and cancel buttons }
      clrmsg; { clear message area }
      runy := 10; { set the runner to the top }
      writerun('The registration server cannot be contacted. This may be');
      writerun('because this computer has no internet connection, or the');
      writerun('connection is being blocked by a firewall or anti-spyware');
      writerun('product. If this problem has no immediate solution, you');
      writerun('can perform the activation manually, or you can contact');
      writerun('Moore/CAD customer support at "support@moorecad.com".');
      waitnext(bakprs); { wait for button }
      if bakprs then goto page1; { go back }

   end;
   crcact; { find activation code CRC }
   inixlt($73934363); { initialize translator array }
   { enter data points to activation array }
   actdat[1] := hwrcrc; { hardware hash }
   actdat[2] := sernum; { serial number }
   actdat[3] := reltim; { release time }
   actdat[4] := datcrc; { data file crc }
   actdat[5] := instim; { install time }
   actdat[6] := actcrc; { activation code CRC }
   outenc; { encode outbound }

   { ******************** Present manual activation page ********************* }

   page2:

   butdis([acbbak, acbnxt, acbcan]); { activate back, next and cancel buttons }
   clrmsg; { clear message area }
   runy := 10; { set the runner to the top }
   writerun('You have choosen to perform product activation manually.');
   writerun('This consists of this program printing a "product signature",');
   writerun('which has 39 characters in it. Please email this number to');
   writerun('activation@moorecad.com with any subject line, and the');
   writerun('signature in the message body. You will receive a reply from');
   writerun('the activation server within a minute or so. Please enter the');
   writerun('characters you receive back into this program, and the');
   writerun('product activation will be complete.');
   writerun;
   writerun('Here is your product signature.');
   writerun;
   cursorg(lmargin, etylin); { position to entry line }
   wrtact; { write out activation code }
   waitnext(bakprs); { wait for button }
   if bakprs then goto page1; { go back }

   { ******************** Present activation reply page ********************* }

   page3:

   butdis([acbbak, acbnxt, acbcan]); { activate back, next and cancel buttons }
   clrmsg; { clear message area }
   runy := 10; { set the runner to the top }
   writerun('Please enter reply from activation@moorecad.com.');
   editbox(lmargin, etylin, clientx-20, etylin+20, widedt);
   waitnext(bakprs); { wait for button }
   geteditboxtext(widedt, editstr); { get modified text }
   copy(tmpstr, editstr^); { place }
   dispose(editstr); { release that }
   killwidget(widedt); { remove edit box }
   if bakprs then goto page1; { go back }
   inixlt($28377593); { initialize translator array }
   rdact(tmpstr, err); { process answer }

   { ******************** Present activation error page ********************* }

   if err then begin { answer wasn't valid }

      butdis([acbbak, acbcan]); { activate back and cancel buttons }
      clrmsg; { clear message area }
      runy := 10; { set the runner to the top }
      writerun('The answer wasn''t valid. Please check that the reply was the');
      writerun('same number of characters as the original activation code');
      writerun('received from activation@mooorecad.com. Please check that');
      writerun('each character contains only a digit or a letter, and that');
      writerun('no punctuation characters are present. Please use only');
      writerun('spaces to separate each group of characters. If you still');
      writerun('find you cannnot get the reply code to work, please contact');
      writerun('Moore/CAD customer support at "support@moorecad.com".');
      waitnext(bakprs); { wait for button }
      if bakprs then goto page3 { go back }

   end;
   inpdec; { decode inbound }
   crcrpl; { calculate new crc inbound }
   { compare sent and received activation codes }
   ac := true; { set compares by default }
   { compare all words }
   if actrpl[1] <> hwrcrc then ac := false; { hardware hash }
   if actrpl[2] <> sernum then ac := false; { serial number }
   if actrpl[3] <> reltim then ac := false; { release time }
   { [4] contains the reply encoder value }
   if actrpl[5] <> instim then ac := false; { install time }
   if actrpl[6] <> rplcrc then ac := false; { activation code crc }

   { **************** Present activation receive error page ***************** }

   if not ac then begin { answer didn't compare }

      butdis([acbbak, acbcan]); { activate back and cancel buttons }
      clrmsg; { clear message area }
      runy := 10; { set the runner to the top }
      writerun('The activation code recieved wasn''t valid. Please');
      writerun('check all characters of the activation code and');
      writerun('re-enter. If you still cannot get activation to pass,');
      writerun('please constact Moore/CAD customer support at');
      writerun('"support@moorecad.com".');
      waitnext(bakprs); { wait for button }
      if bakprs then goto page3 { go back }

   end;

   { activate back, next and cancel buttons }
   butdis([acbbak, acbnxt, acbcan]); { activate back and cancel buttons }
   clrmsg; { clear message area }
   runy := 10; { set the runner to the top }
   writerun('The activation code is correct, thank you.');
   waitnext(bakprs); { wait for button }
   if bakprs then goto page3; { go back }

   exit: { leave for next/last page }

end;

{*******************************************************************************

Read license file

Reads the license file text into a series of strings in a list.

*******************************************************************************}

procedure readlic;

var tmpstr: filnam;  { holding string }
    ovf:    boolean; { overflow flag }
    p, l:   strlpt;  { string entry pointer }

begin

   if licptr = nil then begin { license not already read }

      if not exists(licnam) then prcerr(enolicfil); { no license file }
      assign(licfil, licnam); { open the file }
      reset(licfil);
      l := nil; { clear last pointer }
      while not eof(licfil) do begin { read in license file }

         reads(licfil, tmpstr, ovf); { get next line }
         if ovf then prcerr(esys); { line too long, should not happen }
         readln(licfil); { get next line }
         new(p); { get a new string entry }
         copy(p^.str, tmpstr); { place new string there }
         if l = nil then licstr := p { place root }
         else l^.next := p; { place last }
         p^.next := nil; { clear next }
         l := p { set new last }

      end;
      close(licfil) { close the license file }

   end

end;

{*******************************************************************************

Main program

The program is divided into a series of "pages", each of which contains
information or action for the user. The left side of the window contains the
logo area, which contains our advertising logo. The right top area is reserved
for messages to the user, and we have a system that writes text, with next
line control, into that area. Below that is a single line reserved for special
messages, such as input dialogs or checkboxes. Finally, the bottom right of the
screen, divided by a line, a series of pushbuttons exist, such as BACK, NEXT
and CANCEL, that allow the user to control the behavior and navigation of the
program.

*******************************************************************************}

begin

   { If diagnostics are on, open a separate window for them. }
   if diag then begin

      openwin(input, diagout, windbg); { open the window }
      writeln(diagout, 'Install program diagnostics window is active');
      writeln(diagout)

   end;
   for i := 1 to 4 do cpucmp[i] := 0; { clear cpu id }
   for i := 1 to 10 do { clear mac id table }
      for x := 1 to 6 do maccmp[i][x] := 0;
   vercmp := 0; { clear windows version }
   patlst := nil; { clear active patch list }
   frepat := nil; { clear free patch list }
   hwrcrc := 0; { clear hardware hash }
   sernum := 0; { clear serial number }
   reltim := -maxint; { set invalid release number }
   fcdonly := true; { set CD-ROM install only }
   fdemo := false; { set not a demo }
   fbeta := false; { set not a beta }
   timlim := maxint; { set no time limit }
   { Form character to ASCII value translation array from ASCII value to 
     character translation array. }
   for i := 1 to 255 do trnchr[chr(i)] := 0; { null out array }
   for i := 1 to 127 do trnchr[chrtrn[i]] := i; { form translation }

   gencrc; { generate the CRC remainder table }
   { set default installation path in the program files folder }
   copy(prgpth, defpath);
   fulnam(prgpth); { form full name from that }
   inpopn := false; { set input file not open }
   getreg; { get registration parameters }
   instim := time; { get the install time }
   buttrk := []; { set no buttons active }
   licstr := nil; { clear license string list }
   prgact := false; { set progress bar not active }
   insfil := false; { set not processing .ins file }
   insmac := false; { set not in macro leader }
   version := 0; { clear version number }
   autohold(false); { signal we will perform our own exits }
   scnsizg(sx, sy); { find size of screen }
   setposg(sx div 2-clientx div 2, sy div 2-clienty div 2); { position to center }
   bcolor(backcolor); { set that }
   page; { clear to that }
   title('IP Pascal Installer');
   curvis(output, false); { remove drawing cursor }
   auto(output, false); { turn off scrolling }
   sizable(false); { turn off sizing }
   font(output, font_sign); { sign font }
   bold(true); { use bold font }
   fontsiz(fntsiz); { turn up size }
   binvis; { foreground overwrite }
   loadpict(1, 'logo'); { get the Moore/CAD logo }
   picture(1, 1, 1, 100, clienty); { draw left }
   { draw bottom button dividing line }
   linewidth(3);
   fcolor(black);
   line(lmargin, clienty-butbmg-buthgh-17, rmargin, clienty-butbmg-buthgh-17);
   linewidth(1);
   { present wait message }
   runy := 10; { set top of message area }
   writerun('Loading, please wait...');
   chkinst; { prepare install data file }
   readsys; { read system parameters from install file }
   chkcdrom; { perform CD-ROM run check }
   readlic; { read license file into strings }

   { ************************* Present initial splash page ******************* }
   
   page1: 

   if diag then writeln(diagout, 'Presenting page1: splash page');
   butdis([acbnxt, acbcan]); { activate next and cancel buttons }
   clrmsg; { clear message area }
   fontsiz(40); { set large font }
   cursorg(lmargin, 10); { position to banner }
   write('IP Pascal vs. ', version div 1000000:1, '.', 
                           version div 10000 mod 100:1);
   write(' Installation'); { present banner }
   fontsiz(fntsiz); { restore size }
   runy := 70; { position running text below banner }
   writerun('This program installs IP Pascal to your system. You will be');
   writerun('asked to select from a short series of installation options on');
   writerun('the following pages. You can choose to accept the settings by');
   writerun('pressing the NEXT button. Alternately, you may cancel the');
   writerun('installation at any time, or you may back up to previous');
   writerun('pages by pressing the BACK button.');
   writerun;
   writerun('The most common selections are the default. If you wish only');
   writerun('the default behavior, please enter NEXT through the upcoming');
   writerun('pages.');
   { Prepare install data file, path it, validate it, and read the system
     parameters from it. }
   waitnext(bakprs); { wait for button }

   { *************************** Present license page ************************ }
   
   page1b: 

   if diag then writeln(diagout, 'Presenting page1b: license page');
   butdis([acbbak, acbcan]); { activate next and cancel buttons }
   clrmsg; { clear message area }
   runy := 10; { position running text }
   writerun('License agreement, please read and indicate acceptance.');
   openwin(input, licwin, output, winlic); { open subwindow }
   curvis(licwin, false); { remove drawing cursor }
   auto(licwin, false); { turn off scrolling }
   frame(licwin, false); { turn off the frame }
   { size to message area }
   setsizg(licwin, clientx-lmargin-20, clienty-butbmg-buthgh-17-2-20-20-45);
   setposg(licwin, lmargin, 40); { place over message area }
   radiobutton(lmargin, clienty-butbmg-buthgh-17-2-40, 
               clientx-100, clienty-butbmg-buthgh-17-2-20, 
               'I agree', bidacc);
   radiobutton(lmargin, clienty-butbmg-buthgh-17-2-20, 
               clientx-100, clienty-butbmg-buthgh-17-2, 
               'I don''t agree', biddac);
   { place scroll up/down buttons }
   button(clientx-100, clienty-butbmg-buthgh-17-2-40, 
          clientx-100+20, clienty-butbmg-buthgh-17-2-40+20, 'up', bidup);
   button(clientx-70, clienty-butbmg-buthgh-17-2-40, 
          clientx-70+40, clienty-butbmg-buthgh-17-2-40+20, 'down', biddwn);
   enablewidget(biddac, true); { turn on the "no" choice }
   licptr := licstr; { index top of license strings }
   { display license }
   while licptr <> nil do begin

      writeln(licwin, licptr^.str^); { display string }
      licptr := licptr^.next
 
   end;
   licptr := licstr; { index top of license strings }
   waitnext(bakprs); { wait for button }
   close(licwin); { close subwindow }
   killwidget(bidacc); { remove buttons }
   killwidget(biddac);
   killwidget(bidup);
   killwidget(biddwn);
   if bakprs then goto page1; { go back }

   { ************************ Present install path page ***********************}

   page2:

   if diag then writeln(diagout, 'Presenting page2: install page');
   butdis([acbbak, acbnxt, acbcan]); { activate back, next and cancel buttons }
   clrmsg; { clear message area }
   runy := 10; { set the runner to the top }
   writerun('Below is the default location to install IP Pascal.');
   writerun('Please edit the location, as required, and press');
   writerun('the NEXT button to continue.');
   editbox(lmargin, etylin, clientx-20, etylin+20, widedt);
   copy(editstr, prgpth); { copy to dynamic string }
   puteditboxtext(widedt, editstr^); { place default text }
   dispose(editstr); { release the temp }
   waitnext(bakprs); { wait for button }
   if bakprs then begin { go back }

      killwidget(widedt); { remove edit box }
      goto page1b { go to last page }

   end;
   geteditboxtext(widedt, editstr); { get modified text }
   copy(prgpth, editstr^); { place }
   dispose(editstr); { release that }
   killwidget(widedt); { remove edit box }
   { check target directory is in use as a filename }
   if exists(prgpth) then begin

      copy(errnam, prgpth); { place error name }
      prcerr(edirfil) { directory is a file }

   end;

   { ************************** Present preinstall page ********************** }

   if existsdir(prgpth) then begin

      if diag then writeln(diagout, 'Presenting preinstall page');
      { activate back, next and cancel buttons }
      butdis([acbbak, acbnxt, acbcan]);
      clrmsg; { clear message area }
      runy := 10; { set the runner to the top }
      writerun('The installation directory already exists. If you wish to');
      writerun('install IP Pascal in the same directory, press the NEXT');
      writerun('button, or else press the BACK button and change the');
      writerun('installation location.');
      waitnext(bakprs); { wait for button }
      if bakprs then goto page2 { go back }

   end;

   { ************************* Present search path page ********************** }

   page3:

   if diag then writeln(diagout, 'Presenting page3: search path page');
   butdis([acbbak, acbnxt, acbcan]); { activate back, next and cancel buttons }
   clrmsg; { clear message area }
   runy := 10; { set the runner to the top }
   writerun('In order to run the IP Pascal compiler tools from the command');
   writerun('line, you will need to modify your program search path. This');
   writerun('is not necessary if you only plan to run IP Pascal from the IDE.');
   writerun('You can also perform this step yourself later by following');
   writerun('instructions in the readme.txt file.');
   checkbox(lmargin, etylin, clientx-20, etylin+20, 'Modify search path', widchk);
   enablewidget(widchk, true); { enable it by default }
   chksts := true;
   waitnext(bakprs); { wait for button }
   killwidget(widchk); { remove checkbox }
   if bakprs then goto page2; { go back }

   { **************** Present search path modification page ****************** }

   clears(path); { signal path is not to be set }
   if chksts then begin

      if diag then writeln(diagout, 'Presenting search modification path page');
      butdis([acbbak, acbnxt, acbcan]); { activate back, next and cancel buttons }
      clrmsg; { clear message area }
      runy := 10; { set the runner to the top }
      getpath(path, err); { get the current path }
      if err then begin

         writerun('Cannot get your program path. Please modify your program');
         writerun('path manually using the instructions in the "readme.txt"');
         writerun('file. If you still have problems, contact Moore/CAD');
         writerun('customer support at "support@moorecad.com".');
         clears(path)

      end else begin { set up path }

         { check path already in place }
         copy(tmpstr, prgpth); { assemble new path }
         cat(tmpstr, '\\windows\\i80386\\bin');
         if chkpth(path, tmpstr) then begin { it's already on the path }

            writerun('The required program path is already part of your existing');
            writerun('program path. Nothing was added.');
            writerun

         end else begin

            if len(path) > 0 then cat(path, ';'); { add IP path }
            cat(path, prgpth);
            cat(path, '\\windows\\i80386\\bin')

         end;
         writerun('Below is the proposed new program path. Please edit the');
         writerun('path as required, and press the NEXT button to continue.');
         editbox(lmargin, etylin, clientx-20, etylin+20, widedt);
         copy(editstr, path); { copy to dynamic string }
         puteditboxtext(widedt, editstr^); { place default text }
         dispose(editstr); { release the temp }
         waitnext(bakprs); { wait for button }
         if bakprs then begin { go back }

            killwidget(widedt); { remove edit box }
            goto page3 { go to last page }

         end;
         geteditboxtext(widedt, editstr); { get modified text }
         copy(path, editstr^); { place }
         dispose(editstr); { release that }
         killwidget(widedt) { remove edit box }

      end

   end;

   { perform product activation }
   if not fdemo then begin

      activate; { activate product }
      if bakprs then goto page3 { go back }

   end;

   { begin installation }
   if diag then writeln(diagout, 'Presenting ready to install page');
   butdis([acbbak, acbnxt, acbcan]); { activate back, next and cancel buttons }
   clrmsg; { clear message area }
   runy := 10; { set the runner to the top }
   writerun('Ready to install IP Pascal.');
   writerun;
   writerun('Press NEXT to begin installation');
   waitnext(bakprs); { wait for button }
   if bakprs then goto page3; { go back }
   { perform installation }
   enccrc := $65823792; { set encoder CRC to arbitrary starting value }
   assign(inpfil, insnam); { open installer data file }
   reset(inpfil); { rewind to beginning }
   if diag then writeln(diagout, 'Presenting installation progress page');
   butdis([]); { turn off buttons }
   clrmsg; { clear message area }
   runy := 10; { set the runner to the top }
   writerun('Installing files');
   cursorg(lmargin, etylin-20-5);
   write('%0');
   cursorg(clientx-70, etylin-20-5);
   write('%100');
   progbar(lmargin, etylin, clientx-20, etylin+20, widprg);
   progbarpos(widprg, 0);
   prgact := true; { set progress bar active }
   runinstall; { run installation }
   progbarpos(widprg, maxint);
   if len(path) > 0 then begin { a program path was selected }

      butdis([]); { turn off buttons }
      clrmsg; { clear message area }
      cursorg(lmargin, etylin-20-5);
      write('%0');
      cursorg(clientx-70, etylin-20-5);
      write('%100');
      runy := 10; { set the runner to the top }
      writerun('Setting new program path to:');
      writerun;
      writerun(path);
      setpath(path, err);
      if err then begin

         writerun;
         writerun('Cannot set your program path. Please modify your program');
         writerun('manually using the instructions in the readme.txt file.');
         writerun('If you still have problems, contact Moore/CAD customer');
         writerun('support at "support@moorecad.com".');
         clears(path);
         butdis([acbnxt, acbcan]); { activate back, next and cancel buttons }
         waitnext(bakprs) { wait for button }

      end else begin

         writerun;
         writerun('Your program path is set. You will need to restart your');
         writerun('computer for this to take effect.')

      end

   end;
   { enter the add/remove dialog registration parameters }
   register;

   if diag then writeln(diagout, 'Presenting install complete page');
   butdis([acbext]); { activate exit button }
   clrmsg; { clear message area }
   cursorg(lmargin, etylin-20-5);
   write('%0');
   cursorg(clientx-70, etylin-20-5);
   write('%100');
   runy := 10; { set the runner to the top }
   writerun('Installation is complete. Please read the readme.txt file for the');
   writerun('latest notes on this release of IP Pascal. To use command line');
   writerun('tools, you will need to reboot your computer.');
   writerun;
   writerun('To uninstall IP Pascal, press the CHANGE/REMOVE button');
   writerun('under the Add or Remove Programs dialog in the');
   writerun('Windows Control Panel, under the entry for IP Pascal.');
   writerun;
   waitnext(bakprs); { wait for button }
   killwidget(widprg); { remove progress bar }
   prgact := false;

   99: { abort program }

   if inpopn then close(inpfil) { close files }

end.
