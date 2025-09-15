{*******************************************************************************
*                                                                              *
*                            RELEASE DATA LIST PROGRAM                         *
*                                                                              *
*                              2006/01 S. A. Moore                             *
*                                                                              *
* Lists the releases, and data accompanying them, from the 'release.dat' file. *
*                                                                              *
*******************************************************************************}

program listrel(output);

uses strlib,
     extlib;

label 99; { abort program }

type
      { release tracking entry }
      reltrk = record

         serial: integer; { serial number of release }
         crc:    integer; { data CRC }
         reltim: integer;  { time release was created }
         actnum: integer; { number of times release was activated }
         actfst: integer; { first time release was activated }
         actlst: integer; { last time release was activated }
         timlim: integer; { time limit for this release (-maxint for none) }
         demo:   boolean; { release is a demo. Typically unused, since demos
                            don't need registration. }
         beta:   boolean; { release is a beta }
         ver:    integer; { master version number for release }
         black:  boolean; { this release is blacklisted (no registration 
                            allowed) }
         spoof:  integer; { number of spoofing attempts (CRC checks, but not
                            a valid date, etc. }
         actlim: integer; { activation limit }
         cdonly: boolean; { installation can occur from CD-ROM only }
         rplcrc: integer; { reply crc encoding value }
         pad1, pad2, pad3: integer { padding for future fields }

      end;

var   relfil:     file of reltrk; { release tracking file }
      relnum:     integer; { counter for releases in file }

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
      writeh(output, t); { ouput that }
	   w := w mod $10000000; { remove that digit }
      f := 7 { force field to full }     

   end;
   hexs(buff, w); { convert the integer }
   for i := 1 to f-len(buff) do write('0'); { pad with leading zeros }
   write(output, buff:0) { output number }

end;

{******************************************************************************

Print date and time

Prints a date and time, or "none" if the date/time is not set.

******************************************************************************}

procedure datetime(t: integer);

begin

   if (t = -maxint) or (t = maxint) then write('None')
   else begin

      writedate(local(t));
      write(' ');
      writetime(local(t))

   end

end;

begin

   writeln('Release data lister vs. 1.0');
   writeln;
   if not exists('release.dat') then begin { no release data }

      writeln('*** No release data found');
      goto 99

   end;
   writeln('Release records: ');
   writeln;
   assign(relfil, 'release.dat'); { open data file }
   reset(relfil);
   relnum := 1; { set 1st release number }
   while not eof(relfil) do begin { list all records }

      writeln('Release record: ', relnum:1);
      writeln;
      writeln('Serial number:            ', relfil^.serial:1);
      write('Data CRC:                 '); prthex(8, relfil^.crc); writeln;
      write('Release date and time:    ');
      writedate(local(relfil^.reltim));
      write(' ');
      writetime(local(relfil^.reltim));
      writeln;
      writeln('Install from CD-ROM only: ', relfil^.cdonly:0);
      writeln('Activation count:         ', relfil^.actnum:1);
      writeln('Actiation limit:          ', relfil^.actlim:1);
      write('First activation:         '); datetime(relfil^.actfst); writeln;
      write('Last activation:          '); datetime(relfil^.actlst); writeln;
      write('Time limit:               '); datetime(relfil^.timlim); writeln;
      writeln('Demo:                     ', relfil^.demo:0);
      writeln('Beta:                     ', relfil^.beta:0);
      write('Master version:           '); writed(relfil^.ver,    '0.00.0000'); 
      writeln;
      writeln('Blacklisted:              ', relfil^.black:0);
      writeln('Spoof attempts:           ', relfil^.spoof:1);
      write('Reply CRC:                '); prthex(8, relfil^.rplcrc); writeln;
      writeln;
      get(relfil); { get next release entry }
      relnum := relnum+1 { count releases }

   end;
   close(relfil); { close data file }

   99: { abort program }

end.

