{*******************************************************************************
*                                                                              *
*                        BINARY FILE DECOMPRESSOR PROGRAM                      *
*                                                                              *
*                              2006/01 S. A. Moore                             *
*                                                                              *
* Decompresses a file compressed by the cmpr program. See that program for     *
* further file format notes.                                                   *
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
* The file begins with the ASCII tolken "CMPR", the name of the program.       *
*                                                                              *
*******************************************************************************}

program dcpr(output);

uses strlib,
     extlib,
     parlib;

label 99; { abort program }

const filmax     = 100;       { number of characters in a filename }
      bufmax     = 4096;      { size of compression sliding buffer }
      runmax     = 15;        { maximum size of run or match }
      polynomial = $04c11db7; { Ethernet CRC 32 polynomial }

      diag   = false; { output diagnostics }

type  filinx = 1..filmax; { index for filename }
      filnam = packed array [filinx] of char; { a filename }
      bufinx = 1..bufmax; { index for input buffer }
      bufdst = 0..bufmax; { distance in buffer }
      runinx = 1..runmax; { index for runs }
      runlen = 0..runmax; { length of a run }
      { Special command codes. When the first byte of a tolken is zero, the
        following byte will contain one of these special codes. }
      spccod = (sceof,  { end of file }
                sccrc); { 32 bit CRC follows for last file }
      errcod = (eifnm,   { invalid filename }
                efnexst, { file does not exist }
                esig,    { bad signature }
                einvcod, { invalid special code }
                esys);   { system error }

var   fn, fna, fnb: filnam;  { filename }
      fa, fb:       bytfil;  { files to compare }
      aopn, bopn:   boolean; { file open flags }
      valfch:       chrset;  { valid file characters }
      cmdhan:       parhan;  { handle for command parsing }
      b:            byte;    { byte holders }
      err:          boolean; { error return }
      buff:         array bufmax of byte; { sliding compression buffer }
      { Input index for buffer, limit of all input from input file. }
      inpinx:       bufinx;
      crctab:       array 256 of integer; { CRC remainder table }
      filcrc:       integer; { current CRC accumulator }
      cmpcrc:       integer; { comparision CRC }

{*******************************************************************************

Process error

Prints out the given error and aborts the program.

*******************************************************************************}

procedure error(e: errcod);

begin

   write('*** Error: dcpr: ');
   case e of { error }

      eifnm:   writeln('Invalid filename');
      efnexst: begin

                  write('File "');
                  write(output, fn:0);
                  writeln('" not found')

               end;
      esig:    writeln('Invalid file signature');
      einvcod: writeln('Invalid special code in file');
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
   if c < ' ' then write('\\') { control }
   else write(c) { character }

end;

{*******************************************************************************

Output buffer

A diagnostic, outputs the entire buffer.

*******************************************************************************}

procedure outbuf;

var i: bufinx;

begin

   writeln('Buffer: ');
   for i := 1 to bufmax do wrtchr(chr(buff[i]));
   writeln;
   for i := 1 to bufmax do if i = inpinx then write('I') else write(' ');
   writeln

end;

{*******************************************************************************

Compression loop

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

{ add byte to CRC calculation }

procedure addcrc(b: byte);

var i: integer;

begin

   { calculate CRC this byte }
   i := (filcrc div $1000000 xor b) and $ff;
   filcrc := filcrc*256 xor crctab[i+1]

end;

begin

   filend := false; { set not file end }
   { check proper signature, "CMPR" }
   read(fb, b);
   if b <> ord('C') then error(esig);
   read(fb, b);
   if b <> ord('M') then error(esig);
   read(fb, b);
   if b <> ord('P') then error(esig);
   read(fb, b);
   if b <> ord('R') then error(esig);
   inpinx := 1; { set initial buffer indexes }
   tlknum := 1; { set 1st tolken }
   filcrc := 0; { clear CRC accumulator }
   cmpcrc := 0; { clear comparision CRC }
   repeat { decompress loop }

      read(fb, b); { get a tolken byte }
      if b = 0 then begin { its a special tolken }

         read(fb, b1); { get extended code }
         if b1 = ord(sceof) then filend := true { set end of file }
         else if b1 = ord(sccrc) then begin { its the CRC }
            
            read(fb, b); { get and assemble the CRC value }
            cmpcrc := b*$1000000;
            read(fb, b);
            cmpcrc := cmpcrc+b*$10000;
            read(fb, b);
            cmpcrc := cmpcrc+b*$100;
            read(fb, b);
            cmpcrc := cmpcrc+b
   
         end else error(einvcod) { invalid special code }

      end else if b >= 16 then begin { its a match tolken }

         read(fb, b1); { get displacement }
         x := inpinx; { get current input index }
         sub(x, b and $f*256+b1); { find displacement location }
         if diag then begin
 
{;outbuf;}
            write(tlknum:1, ': ');
            write('Pointer: ', inpinx:1, ' ');
            write('Match tolken, length: ', b div 16:1, ' offset: ', 
                  b and $f*256+b1:1, ' data: ''')

         end;
         for i := 1 to b div 16 do begin { transfer match to output }

            b := buff[x]; { get match byte }
            x := next(x); { find next }
            if diag then wrtchr(chr(b)); { write diagnostic output }
            buff[inpinx] := b; { place byte in queue }
            inpinx := next(inpinx); { advance queue pointer }
            write(fa, b); { output to file }
            addcrc(b) { add to CRC }
         
         end;
         if diag then writeln(''''); { terminate diagnostic line }
         tlknum := tlknum+1 { count tolkens }

      end else begin { its a run tolken }

         if diag then begin

            write(tlknum:1, ': ');
            write('Run tolken, length: ', b:1, ' data: ''')

         end;
         for i := 1 to b do begin { transfer from input to output }

            read(fb, b); { get next byte }
            if diag then wrtchr(chr(b)); { write diagnostic output }
            buff[inpinx] := b; { place byte in queue }
            inpinx := next(inpinx); { advance queue pointer }
            write(fa, b); { output to file }
            addcrc(b) { add to CRC }

         end;
         if diag then writeln(''''); { terminate diagnostic line }
         tlknum := tlknum+1 { count tolkens }

      end

   until filend; { until end of file tolken is seen }
   if diag then writeln('End of file');
   if true {diag} then begin

      write('CRC for file: ');
      prthex(8, filcrc);
      writeln;
      write('Comparision CRC: ');
      prthex(8, cmpcrc);
      writeln

   end;
   if cmpcrc <> filcrc then { CRC does not match }
      writeln('*** Error: CRC does not match original')

end;

begin

   aopn := false; { set no files open }
   bopn := false;
   openpar(cmdhan); { open parser }
   openfil(cmdhan, '_command', 250); { open command line level }
   filchr(valfch); { get the filename valid characters }
   valfch := valfch-['=']; { remove parsing characters }
   setfch(cmdhan, valfch); { set that for active parsing }
   { get file A }
   if chkstr(cmdhan) then parstr(cmdhan, fna, err) { parse string }
   else parfil(cmdhan, fna, false, err); { get a file }
   if err then error(eifnm); { filename too long }
   { get file B }
   if chkstr(cmdhan) then parstr(cmdhan, fnb, err) { parse string }
   else parfil(cmdhan, fnb, false, err); { get a file }
   closepar(cmdhan); { close parser }
   if err then error(eifnm); { filename too long }
   copy(fn, fnb); { place error string }
   if not exists(fnb) then error(efnexst); { no file B }
   assign(fa, fna); { open file A }
   rewrite(fa);
   aopn := true; { set open }
   assign(fb, fnb); { open file B }
   reset(fb);
   bopn := true; { set open }
   gencrc; { generate the CRC remainder table }
   decompress; { run decompression }

   99: { abort program }

   if aopn then close(fa); { close files }
   if bopn then close(fb)

end.
