{*******************************************************************************
*                                                                              *
*                            CRC 32 CALCULATOR PROGRAM                         *
*                                                                              *
*                              2006/01 S. A. Moore                             *
*                                                                              *
* Finds and prints the CRC 32 bit check for the given file. The Ethernet       *
* polynomial is used.                                                          *
*                                                                              *
* This program needs to be compiled with overflow checking off.                *
*                                                                              *
*******************************************************************************}

program cmpr(output);

uses gralib, strlib,
     extlib,
     parlib;

label 99; { abort program }

const filmax = 100;  { number of characters in a filename }
      polynomial = $04c11db7; { Ethernet CRC 32 polynomial }

      diag   = true{false}; { output diagnostics }

type  filinx = 1..filmax; { index for filename }
      filnam = packed array [filinx] of char; { a filename }
      errcod = (eifnm,   { invalid filename }
                efnexst, { file does not exist }
                esys);   { system error }

var   errnam: filnam;  { error filename }
      srcnam: filnam;  { filename }
      srcfil: bytfil;  { file to calculate }
      srcopn: boolean; { file open flag }
      valfch: chrset;  { valid file characters }
      cmdhan: parhan;  { handle for command parsing }
      err:    boolean; { error return }
      crctab: array 256 of integer; { CRC remainder table }

{*******************************************************************************

Process error

Prints out the given error and aborts the program.

*******************************************************************************}

procedure error(e: errcod);

begin

   write('*** Error: cmpr: ');
   case e of { error }

      eifnm:   writeln('Invalid filename');
      efnexst: begin

                  write('File "');
                  write(output, srcnam:0);
                  writeln('" not found')

               end;
      esys:    writeln('System error: notify S. A. Moore software');

   end;
   goto 99 { terminate }

end;

{******************************************************************************

Print hexadecimal

Print a hexadecimal number with field width. Prints right justified with left
hand zeros filling the field. Also allows for the fact that an unsigned 32 bit
number can be read into a 32 bit signed number.
One remaining problem is how to detect and convert the invalid value $80000000.

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

{*******************************************************************************

Calculate CRC table

Form a CRC remainder lookup table.

*******************************************************************************}

procedure gencrc;

var crcacc:  integer;
    i, j, a: integer;

begin

;writeln('gencrc: begin');
   for i := 1 to 256 do begin { for each entry }

      crcacc := (i-1) * $1000000;
      for j := 1 to 8 do { for each bit }
         { this calculation will overflow a signed integer }
         if crcacc < 0 then crcacc := crcacc+crcacc xor polynomial
         else crcacc := crcacc+crcacc;
      crctab[i] := crcacc

   end;
   if diag then begin { print diagnostic }

      writeln('CRC remainder table');
      writeln;
      writeln('    0        1        2        3');
      writeln('---------------------------------------');
      a := 0;
      for i := 1 to 64 do begin

         write(a:-4);
         for j := 1 to 4 do begin

            prthex(8, crctab[a+1]);
            write(' ');
            a := a+1

         end;
         writeln

      end;
      writeln

   end

end;

{*******************************************************************************

Calculate CRC on file

Finds the CRC value for the given file and prints it.

*******************************************************************************}

procedure runcrc;

var crcacc: integer; { CRC accumulator }
    b:      byte;    { input file byte holder }
    i:      integer;

begin

   gencrc; { generate CRC remainder table }
   crcacc := 0; { clear initial CRC }
   while not eof(srcfil) do begin { calculate each file byte }

      read(srcfil, b); { get next file byte }
      i := (crcacc div $1000000 xor b) and $ff;
      crcacc := crcacc*256 xor crctab[i+1]

   end;
   write('CRC 32 for file is: ');
   prthex(8, crcacc);
   writeln

end;

begin

   srcopn := false; { set file not open }
   openpar(cmdhan); { open parser }
   openfil(cmdhan, '_command', 250); { open command line level }
   filchr(valfch); { get the filename valid characters }
   valfch := valfch-['=']; { remove parsing characters }
   setfch(cmdhan, valfch); { set that for active parsing }
   { get file }
   if chkstr(cmdhan) then parstr(cmdhan, srcnam, err) { parse string }
   else parfil(cmdhan, srcnam, false, err); { get a file }
   if err then error(eifnm); { filename too long }
   copy(errnam, srcnam); { place error string }
   if not exists(srcnam) then error(efnexst); { no file B }
   assign(srcfil, srcnam); { open file }
   reset(srcfil);
   srcopn := true; { set open }
   runcrc; { run crc check }

   99: { abort program }

   if srcopn then close(srcfil) { if source file is open, close it }

end.

