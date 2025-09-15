{*******************************************************************************
*                                                                              *
*                          BINARY FILE COMPRESSOR PROGRAM                      *
*                                                                              *
*                              2006/01/04 S. A. Moore                          *
*                                                                              *
* A file is compressed and placed into another file. Uses a dictionary free    *
* sliding buffer technique that works as follows. A 4kb buffer is kept, which  *
* is arranged as a queue, and has input and output, and cache pointers. The    *
* input position indicates where data is coming from the input file. The       *
* output pointer indicates where the data has been output to the output file.  *
* The cache pointer indicates data that has been output, but is being saved    *
* for compression matching, but is always ahead of the input pointer.          *
*                                                                              *
* The input data is converted to one of two output tolkens, a match tolken or  *
* a run tolken. A match tolken indicates that previously seen data is to be    *
* repeated. A run tolken indicates that the next N bytes of data are to be     *
* copied to the output without convertion. Run bytes are output when no        *
* previous data can be matched.                                                *
*                                                                              *
* The algorithim works by indicating new data as a repeat of previous data,    *
* expressed as a distance from the output point, which would be the input      *
* point of a decompressor. This allows working without a dictionary. Because   *
* the buffer is 64kb, the pointers can never be longer than 16 bits.           *
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
* The logical algorithim of buffer searching is accelerated by hashing. The    *
* number of hashes would seem to be 4kb squared, but this is actually limited  *
* by the 15 byte maximum match length. We further reduce the size of the       *
* hash requirement by storing only every 8th byte group hash, which yeilds     *
* a maximum number of hash entries of 64k * 16 or 1meg of hash entries. When   *
* an input string is hashed, it is attempted in each modulo 8 of the length,   *
* starting with the longest, working down. This gives the longest peice that   *
* matches within the string, and simple comparision is used to find the last   *
* 0-7 characters.                                                              *
*                                                                              *
*******************************************************************************}

program cmpr(output);

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
      { Output index for buffer, marks what data was output to final file. }
      outinx:       bufinx;
      chcinx:       bufinx; { limit of all saved data }
      inplen:       integer; { length of input file }
      outlen:       integer; { length of output file }
      runcnt:       integer; { number of runs }
      runtot:       integer; { total run length }
      matcnt:       integer; { number of matches }
      mattot:       integer; { total match length }
      crctab:       array 256 of integer; { CRC remainder table }
      filcrc:       integer; { current CRC accumulator }
      runtime:      integer; { total run time }

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
                  write(output, fn:0);
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

Write character/control character to output

A diagnostic, writes a character to the output. If the character is an ASCII
control (less than space), it is output as '\'.

*******************************************************************************}

procedure wrtchr(c: char);

begin

   if (c < ' ') or (ord(c) >= 128) then begin { output control }

      write('\\$');
      prthex(1, ord(c))

   end else write(c) { character }

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

Last buffer index

decrements a buffer index. Handles wrapping around the buffer end.

*******************************************************************************}

function last(i: bufinx): bufinx;

begin

   { increment or wrap }
   if i > 1 then i := i-1 else i := bufmax;

   last := i { return result }

end;

{*******************************************************************************

Find distance between indexes

Finds the distance between any two indexes, considering wrap-around. The
pointers are "in order", meaning that the distance is measured from a to b.

*******************************************************************************}

function dist(a, b: bufinx): bufdst;

var d: bufdst;

begin

   if a <= b then d := b-a { find a to b distance without wrap }
   else d := bufmax-a+b; { find wraparound distance to b }

   dist := d { return result }

end;

{*******************************************************************************

Add to buffer pointer

Adds a length to a buffer pointer, with wraparound.

*******************************************************************************}

procedure add(var i: bufinx; l: runlen);

begin

   if i+l <= bufmax then i := i+l { add for no-wraparound case }
   else i := l-(bufmax-i) { add for wraparound case }

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

Load next buffer character(s)

Loads up to 128 input characters into the buffer. To enable the best matching,
we try to keep at least 128 bytes of future data in the buffer, the maximum
length of any match or run.

If the caching limit is not reached, then as much data as possible is loaded
until the caching is full. This allows for maximum range of matches.

*******************************************************************************}

procedure nxtinp;

{ add byte to CRC calculation }

procedure addcrc(b: byte);

var i: integer;

begin

   { calculate CRC this byte }
   i := (filcrc div $1000000 xor b) and $ff;
   filcrc := filcrc*256 xor crctab[i+1]

end;

begin

   { while not end of input, not buffer full (as evidenced by input pointer
     wrapping to output pointer), not input at 128 byte maximum match }
   while not eof(fb) and (next(inpinx) <> outinx) and 
         (dist(outinx, inpinx) < runmax) do begin

      { Not end of input file, buffer isn't full, and not overruning
        cache, or run length not satisfied. }
      read(fb, b); { get next byte }
      inplen := inplen+1; { count input bytes }
      buff[inpinx] := b; { place in buffer }
      inpinx := next(inpinx); { find next index }
      { if we have wrapped around to the bottom of caching data, we need to move
        the cache bottom ahead of the new data }
      if chcinx = inpinx then chcinx := next(chcinx);
      addcrc(b) { calculate CRC this byte }

   end

end;

{*******************************************************************************

Find match between positions

Finds the maximum length match between two buffer positions. Given two buffer
positions, will look for the maximum number of matching characters between these
two locations. Disregards wrapping, so that a match can wrap around the buffer.
Does not match a beyond the output index. Does not match b beyond the input
index. Does not return matches longer than the run length.

*******************************************************************************}

function match(a, b: bufinx): runlen;

var rl: runlen; { match length }

begin

   rl := 0; { clear run length }
   { check strings equal, a index within cache to output pointers, b index
     within output to input pointers }
   while (buff[a] = buff[b]) and (a <> outinx) and (b <> inpinx) and 
         (rl < runmax) do begin

      a := next(a); { find next indexes }
      b := next(b);
      rl := rl+1 { count }

   end;

   match := rl { return match length }

end;

{*******************************************************************************

Find maximum buffer match

Finds the maximum match between the current output position and the caching
data.

*******************************************************************************}

procedure maxmat(var a: bufinx; var l: runlen);

var maxlen: runlen; { maximum run length }
    maxloc: bufinx; { maximum run location }
    i:      bufinx; { buffer index }
    rl:     runlen; { run length }

begin

   maxlen := 0; { clear maximum run length }
   maxloc := 1;
   i := chcinx; { index start of cache }
   rl := 0; { clear match length }
   while i <> outinx do begin { check match with this location }

      rl := match(i, outinx); { check match with future data }
      if (rl > 0) and (rl > maxlen) then begin { found a longer match }

         maxloc := i; { set new longest match }
         maxlen := rl

      end;
      i := next(i) { find next byte position in queue }

   end;

   a := maxloc; { place maximum length match found }
   l := maxlen

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
   for i := 1 to bufmax do 
      if i = inpinx then write('I')
      else if i = outinx then write('O')
      else if i = chcinx then write('C')
      else write(' ');
   writeln

end;

{*******************************************************************************

Compression loop

Performs the basic compression loop. The most input data possible is read,
then each byte of input is processed to the output. First, we try to find a
match with previous data stored to the cache limit. If a match is found that is
greater than 3 bytes, then we output a match tolken. The match tolken is 3
bytes, so the match must be greater than 3 bytes for that to be worthwhile.
If no match is found, then we output a run length tolken. The run length tolken
is a length from 1 to 128 that indicates the next data is simply copied from
the input to the output. It is limited to 128 because the high bit of the tolken
indicates a match tolken. When runs are processed, they are actually saved
in a buffer. Any new unmatched bytes are added to the existing run tolken. The
tolken is output if either the length reaches 128, or a match tolken is to be
output.

*******************************************************************************}

procedure compress;

var i:      bufinx; { buffer index }
    rl:     runlen; { run length }
    crlen:  runlen; { cached run length }
    crbuf:  array [runinx] of byte; { buffered run bytes }
    d:      bufinx; { distance to match point }
    x:      runlen;
    tlknum: integer; { tolken sequence number }

{ check and output any previous run tolken }

procedure outrun;

var i: runinx; { index for cached run buffer }

begin

   if crlen > 0 then begin { there is a cached run tolken }

      if diag then begin { output a diagnostic }

         write(tlknum:1, ': ');
         write('Run tolken, length: ', crlen:1, ' Data: ''');
         for i := 1 to crlen do wrtchr(chr(crbuf[i]));
         writeln('''')

      end;
      write(fa, crlen); { output run length }
      outlen := outlen+1; { count output bytes }
      for i := 1 to crlen do begin

         write(fa, crbuf[i]); { output run bytes }
         outlen := outlen+1 { count output bytes }

      end;
      runcnt := runcnt+1; { count run tolkens }
      runtot := runtot+crlen; { find total length in runs }
      crlen := 0; { clear run cache }
      tlknum := tlknum+1 { count tolkens }

   end

end;

{ enter byte as run }

procedure entrun(b: byte);

begin

   crlen := crlen+1; { add into run tolken }
   crbuf[crlen] := b; { place into buffer }
   if crlen = runmax then outrun { run tolken full, output it }

end; 
      
begin

   inplen := 0; { clear lengths }
   outlen := 0;
   runcnt := 0;
   runtot := 0;
   matcnt := 0;
   mattot := 0;
   write(fa, ord('C')); { place file signature, "CMPR" }
   write(fa, ord('M'));
   write(fa, ord('P'));
   write(fa, ord('R'));
   outlen := outlen+4; { count output bytes }
   inpinx := 1; { set initial buffer indexes }
   outinx := 1;
   chcinx := 1;
   crlen := 0; { set run tolken inactive }
   tlknum := 1; { set 1st tolken }
   filcrc := 0; { clear CRC accumulator }
   repeat { compress loop }

      nxtinp; { keep input full }
      maxmat(i, rl); { find any matches }
      if rl > 3 then begin { output as match tolken }

         outrun; { output any cached run tolken }
         d := dist(i, outinx); { find distance from output index }
         { Output match tolken length, in -1 format, with bit 7 low to indicate
           a match tolken. }
         if diag then begin { output a diagnostic }

;outbuf;
            write(tlknum:1, ': ');
            write('Pointer: ', outinx:1, ' ');
            write('Match tolken, length: ', rl:1, ' offset: ', d:1, 
                  ' data: ''');
            { find buffer location with wrap distance }
            i := outinx;
            sub(i, d);
            { print data }
            for x := 1 to rl do begin

               wrtchr(chr(buff[i]));
               i := next(i)

            end;
            writeln('''')

         end;
         { Output match length in upper 4 bits, upper 4 bits of offset in lower
           4 bits of tolken byte. }
         write(fa, rl*16+d div 256);
         outlen := outlen+1; { count output bytes }
         write(fa, d mod 256);  { output low distance }
         outlen := outlen+1; { count output bytes }
         add(outinx, rl); { advance output index }
         matcnt := matcnt+1; { count match tolkens }
         mattot := mattot+rl; { count total length in matches }
         tlknum := tlknum+1 { count tolkens }

      end else begin { output as run length }

         entrun(buff[outinx]); { place next run byte }
         outinx := next(outinx) { advance output index }

      end

   { until buffer is empty and end of input }
   until (outinx = inpinx) and eof(fb);
   outrun; { output any cached run tolken }
   if diag then writeln('End of file');
   { output the CRC }
   if true {diag} then begin

      write('CRC for file: ');
      prthex(8, filcrc);
      writeln

   end;
   write(fa, 0); { output specials code }
   write(fa, ord(sccrc)); { CRC follows }
   write(fa, filcrc div $1000000 and $ff); { output the CRC in big endian order }
   write(fa, filcrc div $10000 and $ff);
   write(fa, filcrc div $100 and $ff);
   write(fa, filcrc and $ff);        
   { output the end of file tolken }
   write(fa, 0);
   write(fa, ord(sceof));
   outlen := outlen+2; { count output bytes }
   write('Input file: ');
   { *** humm, format image does not seem to work here }
   write(inplen:1);
   write(' Output file: ');
   write(outlen:1);
   writeln(' %', outlen*100 div inplen:1, ' of original file');
   write('Runs: ', runcnt:1, ' Total data in runs: ', runtot:1);
   if runcnt > 0 then write(' Average run length: ', runtot div runcnt:1);
   writeln;
   write('Matches: ', matcnt:1, ' Total data in matches: ', mattot:1);
   if matcnt > 0 then write(' Average match length: ', mattot div matcnt:1);
   writeln

end;

begin

   runtime := clock; { mark time }
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
   compress; { run compression }
   writeln('Time to run: ', elapsed(runtime) div 10000:1, ' seconds');

   99: { abort program }

   if aopn then close(fa); { close files }
   if bopn then close(fb)

end.

