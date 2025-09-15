{*******************************************************************************
*                                                                              *
*                           RELEASE ACTIVATION PROGRAM                         *
*                                                                              *
*                              2006/01 S. A. Moore                             *
*                                                                              *
* Runs activation for releases. When a release is activated, it will produce   *
* an activation code that is sent to this program. The activation code will be *
* decoded, the software registered, and a reply code is constructed to be sent *
* back to the registering computer. At present, this is all manual, but in the *
* future this will become an automated process.                                *
*                                                                              *
*******************************************************************************}

program activate(input, output);

uses strlib,
     extlib;

label 99, { abort program }
      88; { abort activation loop (restart) }

const maxstr     = 250;         { maximum length of string }
      actnum     = 6;           { number of activation words }
      polynomial = $04c11db7;   { Ethernet CRC 32 polynomial }
      audnam     = 'audit.txt'; { activation audit file }
      audtmp     = 'audit.bak'; { activation audit file temp holding }

type padstr = packed array maxstr of char; { padded string }
     actarr = array actnum of integer; { activation number array }
     { release tracking entry }
     reltrk = record

        serial: integer; { serial number of release }
        crc:    integer; { data CRC }
        reltim: integer; { time release was created }
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

fixed ln32: packed array 32 of char = '0123456789ABCDEFGHJKMNPQRSTUWXYZ';

var tmpstr, tmpstr1: padstr; { string temps }
    xltarr:          array actnum*32 of 0..actnum*32; { translation array }
    rndseq:          integer; { random number seed }
    actdat:          actarr;  { activation data }
    actrpl:          actarr;  { activation data reply }
    ovf:             boolean; { read string overflow flag }
    err:             boolean; { error flag }
    actcrc:          integer; { activation code CRC }
    crctab:          array 256 of integer; { CRC remainder table }
    consist:         boolean; { activation passes/fails consistency checks }
    relnum:          integer; { location of matching release record }
    relbuf:          reltrk;  { saved release data record }
    acttim:          integer; { activation time }
    audit:           text;    { audit file }
    tim:             integer; { current time }
    rplcrc:          integer; { reply crc to installer }
    i:               integer;

{******************************************************************************

Print hexadecimal

Print a hexadecimal number with field width. Prints right justified with left
hand zeros filling the field. Also allows for the fact that an unsigned 32 bit
number can be read into a 32 bit signed number.

******************************************************************************}

procedure prthex(var tf: text; f: byte; w: integer);
 
var buff: packed array [1..10] of char; { buffer for number in ascii }
    i:    integer; { index for same }
    t:    integer; { holding }
 
begin

   { set sign of number and convert }
   if w < 0 then begin

      w := w+1+maxint; { convert number to 31 bit unsigned }
      t := w div $10000000 + 8; { extract high digit }
      writeh(tf, t); { ouput that }
	   w := w mod $10000000; { remove that digit }
      f := 7 { force field to full }     

   end;
   hexs(buff, w); { convert the integer }
   for i := 1 to f-len(buff) do write(tf, '0'); { pad with leading zeros }
   write(tf, buff:0) { output number }

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
      else begin

         writeln('*** System error');
         goto 99

      end

   end;

   bytint := b { return result }

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

Convert activation code

Converts an activation code from ln32 form to a binary block. Expects the
activation code string. An error variable is set if the string contains invalid
characters, or is too long. String should be converted to upper case before
calling this routine.

We translate the outbound codes so that the bits don't line up next to each
other. This creates extra security for the code.

*******************************************************************************}

procedure rdact(view s: string; var err: boolean);

var t:          padstr;  { temp string }
    ai:         integer; { index for activation data }
    actdig:     integer; { number of ln32 digits in activation data }
    bi, cbi:    integer; { index for activation bits }
    i, x, c, p: integer;

{ validate and normalize the string }

procedure cvtact;

var i:      integer; { index }
    t1, t2: padstr; { string temps }

begin

   copy(t, s);
   err := false; { set no error }
   { check any bad characters, which includes all punctuation besides space,
     and the letters 'I' and 'L' }
   for i := 1 to maxstr do 
      if not (t[i] in ['0'..'9', 'A'..'H', 'J'..'K', 'M'..'Z', ' ']) then begin

         if not err then write(audit, 'Incorrect characters in string: ')
         else write(audit, ','); { separate }
         write(audit, '''', t[i], '''');
         err := true;

   end;
   if err then writeln(audit); { complete audit line }
   if not err then begin { continue }

      { remove all spaces from format }
      while (index(t, ' ') > 0) and (index(t, ' ') < len(t)) do begin 

         extract(t1, t, 1, index(t, ' ')-1); { get left }
         extract(t2, t, index(t, ' ')+1, len(t)); { get right }
         copy(t, t1); { construct result }
         cat(t, t2)

      end;
      { convert all O's to 0's, all V's to U's }
      for i := 1 to maxstr do begin

         if t[i] = 'O' then t[i] := '0'; { convert O to 0 }
         if t[i] = 'V' then t[i] := 'U'; { convert O to 0 }

      end;
      if len(t) <> actdig then begin

         writeln(audit, 'Digit count was incorrect');
         err := true { incorrect digit count }

      end
         
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
         if c = 0 then begin

            writeln('*** System error');
            goto 99

         end;
         c := c-1; { zero adjust }
         p := 16; { set highest power in ln32 code (0-31) }
         while p <> 0 do begin { move those bits into the activation data }

            { if the bit is set, move it into activation }
            if p and c > 0 then begin
             
               cbi := (bi div 32)*32+(31-bi mod 32); { find convolution }
               { Because the number of digits in the activation record is
                 rounded up, the last digit will contain null bits. If one of
                 these is set, the code is invalid. }
               if cbi >= actnum*32 then begin

                  writeln(audit, 'Code contained set bits in the null padding');
                  err := true

               end else setact(cbi)

            end;
            p := p div 2; { next power }
            bi := bi+1 { next bit }
         
         end

      end

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

procedure wrtact(var f: text);

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

      if ((si-1) mod 6 = 0) and (si <> 1) then write(f, ' ');
      write(f, s[si]) { write digit }

   end

end;

{*******************************************************************************

Decode inbound activation code

Performs decoding (encyphering) on the inbound activation code. We use a simple
xor with pseudorandom sequence for now.

*******************************************************************************}

procedure inpdec;

var i: integer; { index }

begin

   rndseq := $48998375; { start random number sequence }
   for i := 1 to actnum do actrpl[i] := actrpl[i] xor rand

end;

{*******************************************************************************

Encode outbound activation code

Performs encoding (encyphering) on the outbound activation code. We use a simple
xor with pseudorandom sequence for now.

*******************************************************************************}

procedure outenc;

var i: integer; { index }

begin

   rndseq := $69384707; { start random number sequence }
   for i := 1 to actnum do actdat[i] := actdat[i] xor rand

end;

{*******************************************************************************

Calculate activation code CRC

Calculates a CRC against the activation code. Each of the activation code
parts is fed, a byte at a time, into the CRC generator.

*******************************************************************************}

procedure crcact;

var i: integer;

{ enter integer to CRC }

procedure crcint(v: integer);

var i: integer;

begin

   for i := 0 to 3 do addcrc(actcrc, bytint(i, v)) { add each byte into CRC }

end;

begin

   actcrc := $56939047; { set initial CRC code }
   for i := 1 to actnum-1 do crcint(actrpl[i])

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
   for i := 1 to actnum-1 do crcint(actdat[i])

end;

{*******************************************************************************

Get release record

Finds a match for the given serial number in the release records file. The
information in the file is loaded to a local buffer, and the location it was
found is recorded. If the serial number does not match any in the file, the
error variable is set.

*******************************************************************************}

procedure getrel(serial: integer; var err: boolean);

var relfil: file of reltrk; { release tracking file }

begin

   { open the recording file }
   if not exists('release.dat') then begin { create release tracking file }

      writeln('*** Error: the release data file "release.dat" is not found');
      goto 99

   end;
   assign(relfil, 'release.dat'); { open file }
   reset(relfil);
   err := true; { set not found }
   relnum := 1; { set 1st record in file }
   while not eof(relfil) and err do begin { traverse the file }

      if relfil^.serial = serial then begin { found matching record }

         relbuf := relfil^; { save matching record }
         err := false { set record was found }

      end else begin

         get(relfil); { get next record }
         relnum := relnum+1 { count records }

      end

   end;
   close(relfil) { close the file }
   
end;

{*******************************************************************************

Put release record

Places the release record back in the release.dat file at the relnum specified
position.

*******************************************************************************}

procedure putrel;

var relfil: file of reltrk; { release tracking file }

begin

   { open the recording file }
   if not exists('release.dat') then begin { create release tracking file }

      writeln('*** Error: System error');
      goto 99

   end;
   assign(relfil, 'release.dat'); { open file }
   update(relfil);
   position(relfil, relnum); { position to element }
   write(relfil, relbuf); { place buffered element }
   close(relfil) { close the file }
   
end;

{******************************************************************************

Print date and time

Prints a date and time, or "none" if the date/time is not set.

******************************************************************************}

procedure datetime(var f: text; t: integer);

begin

   if t = -maxint then write(f, 'None')
   else begin

      writedate(f, local(t));
      write(f, ' ');
      writetime(f, local(t))

   end

end;

{******************************************************************************

Open audit file

Opens the audit file and prepares it for appending. If there is previous
content in the audit file, it is moved to a temp file, then copied to the new
file, and writing will resume at the end.

******************************************************************************}

procedure openaudit;

var c:      char; { character buffer }
    auditt: text; { audit file temp }

begin

   { open audit file }
   if exists(audnam) then begin

      { append contents of old file to new file }
      change(audtmp, audnam); { move old file to temp }
      assign(audit, audnam); { open new file }
      rewrite(audit);
      assign(auditt, audtmp); { open old file }
      reset(auditt);
      while not eof(auditt) do begin { copy old to new }

         while not eoln(auditt) do begin { copy lines }

            read(auditt, c); { copy single character }
            write(audit, c)

         end;
         readln(auditt); { copy eoln }
         writeln(audit)

      end;
      close(auditt) { close the temp file }

   end else begin { just open the audit file }

      assign(audit, audnam); { open new file }
      rewrite(audit)

   end
      
end;

{******************************************************************************

Output activation code data to file

Outputs the various fields in the activation code send by the user to a file.

******************************************************************************}

procedure wrtactd(var f: text);

begin

   writeln(f);
   writeln(f, 'Details on this release:');
   writeln(f);
   writeln(f, 'Serial number:         ', actrpl[2]:1);
   write(f, 'Hardware hash:         '); prthex(f, 8, actrpl[1]); writeln(f);
   write(f, 'Release date and time: ');
   writedate(f, actrpl[3]);
   write(f, ' ');
   writetime(f, actrpl[3]);
   writeln(f);
   write(f, 'Data CRC:              '); prthex(f, 8, actrpl[4]); writeln(f);
   write(f, 'Install date and time: ');
   writedate(f, actrpl[5]);
   write(f, ' ');
   writetime(f, actrpl[5]);
   writeln(f);
   write(f, 'Activation CRC:        '); prthex(f, 8, actrpl[6]); writeln(f);
   writeln(f);

end;

{******************************************************************************

Output release data to file

Outpts the contents of the current release record to a file.

******************************************************************************}

procedure wrtrel(var f: text);

begin

   writeln(f);
   writeln(f, 'Release record: ', relnum:1);
   writeln(f);
   writeln(f, 'Serial number:            ', relbuf.serial:1);
   write(f, 'Data CRC:                 '); prthex(f, 8, relbuf.crc); writeln(f);
   write(f, 'Release date and time:    ');
   writedate(f, local(relbuf.reltim));
   write(f, ' ');
   writetime(f, local(relbuf.reltim));
   writeln(f);
   writeln(f, 'Install from CD-ROM only: ', relbuf.cdonly:0);
   writeln(f, 'Activation count:         ', relbuf.actnum:1);
   writeln(f, 'Activation limit:         ', relbuf.actlim:1);
   write(f, 'First activation:         '); datetime(f, relbuf.actfst); writeln(f);
   write(f, 'Last activation:          '); datetime(f, relbuf.actlst); writeln(f);
   write(f, 'Time limit:               '); datetime(f, relbuf.timlim); writeln(f);
   writeln(f, 'Demo:                     ', relbuf.demo:0);
   writeln(f, 'Beta:                     ', relbuf.beta:0);
   write(f, 'Master version:           '); writed(f, relbuf.ver,    '0.00.0000'); 
   writeln(f);
   writeln(f, 'Blacklisted:              ', relbuf.black:0);
   writeln(f, 'Spoof attempts:           ', relbuf.spoof:1);
   write(f, 'Reply CRC:                '); prthex(f, 8, relbuf.rplcrc); writeln;
   writeln(f)

end;

begin

   writeln;
   writeln('Activation server vs. 1.0');
   writeln;
   gencrc; { generate the CRC remainder table }
   { generate our sign on to audit file }
   openaudit;
   tim := time; { get current time }
   writeln(audit); { space off }
   write(audit, 'Activate program started at: ');
   writedate(audit, local(tim));
   write(audit, ' ');
   writetime(audit, local(tim));
   writeln(audit);
   writeln(audit);
   close(audit);
   { start activation loop }
   while true do begin { forever }

      clears(tmpstr); { clear response string }
      writeln('Please enter activation signature from user:');
      writeln;
      write('> ');
      reads(input, tmpstr, ovf); { get user string }
      readln;
      { mark activation time }
      acttim := time;
      openaudit; { open the audit file }
      writeln(audit); { space off }
      write(audit, 'New activation at: ');
      writedate(audit, local(acttim));
      write(audit, ' ');
      writetime(audit, local(acttim));
      writeln(audit);
      writeln(audit);
      writeln(audit, 'Signature string: ', tmpstr:0);
      trim(tmpstr1, tmpstr); { remove leading and trailing spaces }
      copy(tmpstr, tmpstr1);
      ucases(tmpstr); { insure case matches }
      if len(tmpstr) = 0 then begin { empty string }

         writeln;
         writeln('Reply empty.');
         writeln;
         writeln(audit, 'Reply empty');
         writeln(audit, 'Terminating due bad reply');
         goto 88 { abort loop }

      end;
      inixlt($73934363); { initialize translator array }
      rdact(tmpstr, err); { process answer }
      if err then begin { didn't check }

         writeln;
         writeln('The activation code does not check as valid. This can');
         writeln('occur because the code contains invalid characters, or');
         writeln('or because it is to many characters, or because it');
         writeln('contains bits set where there is no data (which would');
         writeln('typically indicate a bad code).');
         writeln;
         writeln(audit, 'Terminating due to activation code errors');
         goto 88 { abort loop }

      end;
      inpdec; { decode inbound }
      crcact; { calculate CRC }
      if actrpl[6] <> actcrc then begin

         writeln;
         writeln('Inbound data fails CRC check.');
         writeln;
         writeln(audit, 'Inbound data contains CRC error');
         writeln(audit, 'Terminating due to CRC error');
         goto 88 { abort loop }

      end;
      writeln;
      writeln('Activation code CRC checks.');
      writeln(audit, 'CRC check passes');
      wrtactd(output); { write activation data to console }
      wrtactd(audit); { write activation data to audit file }
      consist := true; { set passes consistency checks by default }
      { basic check for valid install and release time }
      if actrpl[3] >= actrpl[5] then begin

         writeln;
         writeln('Activation code fails consistency check.');
         writeln('The release date/time is later than the install');
         writeln('date/time.');
         writeln;
         writeln(audit, 'Release date/time later than install date/time');
         consist := false { set fails consistency check }

      end;
      getrel(actrpl[2], err); { retrieve release record by serial number }
      if err then begin

         writeln;
         writeln('A release record that matches the serial number in');
         writeln('This activation record wasn''t found.');
         writeln;
         write(audit, 'Matching record for this serial number: ', actrpl[2]:1);
         writeln(audit, ' is not found');
         writeln(audit, 'Terminating due to missing activation record');
         { if we don't find a record, the only way out is to abort. } 
         goto 88 { abort loop }

      end;
      writeln;
      writeln('A release record was found.');
      wrtrel(output); { output release data to console }
      wrtrel(audit); { output release data to audit }
      { check release times match }
      if actrpl[3] <> relbuf.reltim then begin

         writeln;
         writeln('The release time fails consistency check.');
         writeln('The release time returned does not match the original');
         writeln('release time of record.');
         writeln;
         writeln(audit, 'Release time does not match original time');
         consist := false { fails }

      end;
      { check data CRCs match }
      if actrpl[4] <> relbuf.crc then begin

         writeln;
         writeln('The data CRC fails consistency check.');
         writeln('The data CRC returned does not match the original data CRC');
         writeln('of record.');
         writeln;
         writeln(audit, 'Data CRC does not match the original');
         consist := false { fails }

      end;
      { check install time differs significantly from present (30 minutes or 
        more) }
      if abs(actrpl[5]-acttim) > 30*60 then begin

         writeln;
         writeln('Time of install differs from present time by: ',
                 abs(actrpl[5]-time) div 60:1, ' minutes.');
         writeln('There is a limit of 30 minutes +/- from the start of the');
         writeln('install program to activation.');
         writeln;
         writeln(audit, 'Install time is not within 30 minutes of current time');
         writeln(audit, 'Terminating due to install time difference');
         goto 88 { abort loop }

      end;
      if relbuf.actnum >= relbuf.actlim then begin

         writeln;
         writeln('Activation count at maximum activations allowed.');
         writeln;
         writeln(audit, 'Activation count exceeds maximum');
         writeln(audit, 'Terminating due to activation count overage');
         goto 88 { abort loop }

      end;
      if acttim >= relbuf.timlim then begin

         writeln;
         writeln('The time limit on this release has passed.');
         writeln;
         writeln(audit, 'Release has passed its time limit');
         writeln(audit, 'Terminating due to time limit');
         goto 88 { abort loop }

      end;
      if not consist then begin { fails consistency checks }

         writeln;
         writeln('Activation fails consistency check(s), so activation will');
         writeln('not proceed.');
         writeln;
         writeln(audit, 'Will not activate due to consistency check(s)')

      end else begin

         { copy inbound data to outbound buffer }
         actdat := actrpl;
         { add reply crc into outbound data crc }
         actdat[4] := actdat[4] xor relbuf.rplcrc;
         crcrpl; { calculate crc on outbound data }
         actdat[6] := rplcrc; { place new crc }
         outenc; { encode outbound }
         inixlt($28377593); { initialize translator array }
         writeln;
         writeln('Activation is complete, here is the activation reply:');
         writeln;
         wrtact(output); { write out activation code }
         writeln;
         writeln;
         writeln(audit, 'Activation was sucessful');
         write(audit, 'Activation code: ');
         wrtact(audit); { write activation code to audit }
         writeln(audit)

      end;
      { now update the data in release.dat }
      if consist = false then 
         relbuf.spoof := relbuf.spoof+1 { add spoof attempt }
      else begin { valid activation }
 
         relbuf.actnum := relbuf.actnum+1; { add this activation }
         relbuf.actlst := acttim; { place last activation time }
         if relbuf.actfst = -maxint then { no first time set }
            relbuf.actfst := acttim; { place first activation time }

      end;
      putrel; { replace record in release.dat }

      88: { abort to next activation }

      close(audit); { close the audit file }

   end;

   99: { abort program }

end.

