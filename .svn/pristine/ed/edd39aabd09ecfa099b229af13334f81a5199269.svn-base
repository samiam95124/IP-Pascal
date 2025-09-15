{*******************************************************************************
*                                                                              *
*                           RELEASE CREATOR PROGRAM                            *
*                                                                              *
*                              2006/01 S. A. Moore                             *
*                                                                              *
* Creates a release from the c:\ip release tree. The entire contents of the    *
* c:\ip tree is compressed, and their relative paths stored into the file,     *
* which becomes the "install.dat" file. The installer is built onto the        *
* format for a file compressor.                                                *
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

program createrel(output);

uses strlib,
     extlib,
     parlib,
     dirlib;

label 99; { abort program }

const filmax     = 1000;          { number of characters in a filename }
      bufmax     = 4096;          { size of compression sliding buffer }
      runmax     = 15;            { maximum size of run or match }
      polynomial = $04c11db7;     { Ethernet CRC 32 polynomial }
      maxhash    = 1000;          { number of entries in hash table }
      { Root directory of release image. This must be fully pathed, since we
        remove its length in characters to remove the root path. }
      { rootname   = 'c:\\pascomp\\install\\iptest\\*';}
      rootname   = 'c:\\iprel\\*';
      dataname   = 'install.dat'; { installer data file name }
      { switches }
      diag   = false; { output diagnostics }
      encode = true; { encode install.dat file }
      maxact = 25; { default maximum activations }

type  filinx = 1..filmax; { index for filename }
      filnam = packed array [filinx] of char; { a filename }
      bufinx = 1..bufmax; { index for input buffer }
      bufdst = 0..bufmax; { distance in buffer }
      runinx = 1..runmax; { index for runs }
      runlen = 0..runmax; { length of a run }
      { hash table entries }
      hshptr = ^hshety; { pointer to hash entry }
      hshety = record

         inx:  bufinx; { location of matching string }
         len:  runlen; { length of matching string }
         rip:  hshptr; { delete link, links all entries to same index }
         last: hshptr; { last entry }
         next: hshptr  { next entry }

      end;
      hshinx = 1..maxhash; { index for hashing table }
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
      { blotter codes }
      bltcod = (bdt_end,     { end of blotter data }
                bdt_macadr,  { table of 10 mac addresses }
                bdt_cpustr,  { table of 4 32 bit cpuid return words }
                bdt_winver,  { 32 bit windows version number }
                bdt_timlim); { 32 bit release time/date limit }
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
      errcod = (eifnm,   { invalid filename }
                efnexst, { file does not exist }
                einvexe, { .exe file error }
                ecntfil, { serial number file not found }
                einvopt, { invalid option }
                eoptnf,  { option not found }
                easexp,  { '=' expected }
                einvnum, { invalid number }
                edshexp, { '-' expected }
                eclnexp, { ':' expected }
                einvver, { Invalid version number }
                esys);   { system error }

var   errnam:     filnam;  { filename }
      datnam:     filnam;  { output data file name }
      datfil:     bytfil;  { output data file }
      aopn, bopn: boolean; { file open flags }
      valfch:     chrset;  { valid file characters }
      cmdhan:     parhan;  { handle for command parsing }
      b, b1:      byte;    { byte holders }
      err:        boolean; { error return }
      buff:       array bufmax of byte; { sliding compression buffer }
      { Input index for buffer, limit of all input from input file. }
      inpinx:     bufinx;
      { Output index for buffer, marks what data was output to final file. }
      outinx:     bufinx;
      chcinx:     bufinx; { limit of all saved data }
      crctab:     array 256 of integer; { CRC remainder table }
      filcrc:     integer; { current CRC accumulator }
      frehsh:     hshptr;  { free hash entries list }
      hshtbl:     array maxhash of hshptr; { hash table }
      riptbl:     array bufmax of hshptr; { ripping table }
      rotnam:     filnam;  { path/file of ip root }
      dirlst:     dirptr;  { release directory list }
      fp:         filptr;  { pointer for file entries }
      datcrc:     integer; { full data file crc }
      enccrc:     integer; { encoder CRC }
      serfil:     text;    { serial number file }
      sernum:     integer; { serial number for this release }
      reltim:     integer; { release time and date }
      relfil:     file of reltrk; { release tracking file }
      bltstr:     integer; { blotter start address }
      bltlen:     integer; { blotter length, or 0 if none }
      rndseq:     integer; { random number seed }
      fcdonly:    boolean; { install from CD-ROM only }
      fdemo:      boolean; { release is a demo }
      fbeta:      boolean; { release is a beta }
      actmax:     integer; { maximum number of activations for release }
      timlim:     integer; { time limit on this release }
      serman:     integer; { manual set serial number }
      rplcrc:     integer; { reply CRC encoding value }
      version:    integer; { software version }

{*******************************************************************************

Process error

Prints out the given error and aborts the program.

*******************************************************************************}

procedure error(e: errcod);

begin

   write('*** Error: createrel: ');
   case e of { error }

      eifnm:   writeln('Invalid filename');
      efnexst: begin

         write('File "');
         write(output, errnam:0);
         writeln('" not found')

      end;
      einvexe: begin

         write('PE File "');
         write(output, errnam:0);
         writeln('" is invalid')

      end;
      ecntfil: writeln('Missing serial number file');
      einvopt: writeln('Invalid option');
      eoptnf:  writeln('Option not found');
      easexp:  writeln('''='' expected');
      einvnum: writeln('Invalid number');
      edshexp: writeln('''-'' expected');
      eclnexp: writeln(''':'' expected');
      einvver: writeln('Invalid version number');
      esys: writeln('System error: notify S. A. Moore software');

   end;
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
      writeh(output, t); { ouput that }
	   w := w mod $10000000; { remove that digit }
      f := 7 { force field to full }     

   end;
   hexs(buff, w); { convert the integer }
   for i := 1 to f-len(buff) do write('0'); { pad with leading zeros }
   write(output, buff:0) { output number }

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

Output byte to install.dat file

Outputs a single byte to the install.dat file. Also calculates the whole file
CRC.

*******************************************************************************}

procedure wrtdat(b: byte);

var b1: byte;

begin

{;write('enccrc: '); prthex(8, enccrc); writeln;
;write('Byte output: '); prthex(2, b); writeln;}
   { check we are to encode it }
   if encode then begin

      b1 := (b xor enccrc) and $ff; { place encoded byte }
      addcrc(enccrc, b); { add in plaintext byte to crc }
      b := b1 { place back in byte }

   end;
{;write('Byte encoded: '); prthex(2, b); writeln;}
   { output and CRC the byte }
   write(datfil, b); { output to file }
   addcrc(datcrc, b) { add into CRC }

end;

{*******************************************************************************

Output integer install.dat file

Outputs a 32 bit integer in big endian mode to the install.dat file.

*******************************************************************************}

procedure wrtint(i: integer);

begin

   { output the entire file CRC to the end }
   wrtdat(i div $1000000 and $ff);
   wrtdat(i div $10000 and $ff);
   wrtdat(i div $100 and $ff);
   wrtdat(i and $ff);

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

Get hash entry

Gets a hash entry, and returns a pointer to it. If there is an entry in the
free list, that is returned, otherwise, a new entry is allocated.

*******************************************************************************}

procedure gethsh(var p: hshptr);

begin

   if frehsh <> nil then begin { there is a free entry }

      p := frehsh; { index top entry }
      frehsh := frehsh^.next { gap top entry }

   end else new(p); { otherwise get a new one }
   p^.inx := 1; { clear entries }
   p^.len := 0;
   p^.rip := nil;
   p^.last := nil;
   p^.next := nil

end;

{*******************************************************************************

Put hash entry

Places the given hash entry onto the free list.

*******************************************************************************}

procedure puthsh(p: hshptr);

begin

   p^.next := frehsh; { push onto list }
   frehsh := p

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

Subtract from buffer pointer

Subtracts an offset from a buffer pointer, with wraparound.

*******************************************************************************}

procedure sub(var i: bufinx; l: bufdst);

begin

   if i-l >= 1 then i := i-l { subtract for no-wraparound case }
   else i := bufmax-(l-i) { subtract for wraparound case }

end;

{*******************************************************************************

Dump hash table

Dumps out the complete hash table. A diagnostic.

*******************************************************************************}

procedure prthsh;

var i: hshinx; { index for hash table }
    p: hshptr; { pointer to hash list }
    x: bufinx; { buffer index }
    y: runlen; { length counter }

begin

   writeln('Hash table: ');
   writeln;
   for i := 1 to maxhash do begin { traverse table }

      p := hshtbl[i]; { index top of list }
      while p <> nil do begin { traverse list }

         write('Hash index: ', i:1, ' Buffer index: ', p^.inx:1, 
                 ' Length: ', p^.len:1, ' Data: ''');
         x := p^.inx; { index start of string }
         for y := 1 to p^.len do begin { print string data }
 
            wrtchr(chr(buff[x])); { print character }
            x := next(x) { next index }

         end;
         writeln('''');
         p := p^.next; { next entry }
         if p = hshtbl[i] then p := nil { terminate if we have circled }

      end

   end

end;

{*******************************************************************************

Find hash for buffer data

Find a hash function for the given buffer position and length. Does not check
if the position or length is valid. Wraparound is handled.

*******************************************************************************}

function hash(i: bufinx; l: bufdst): hshinx;

var h: integer;
    x: runinx;

begin

   h := 0;
   for x := 1 to l do begin { cross hash data } 

      h := (h+buff[i]) mod maxhash; { add in and truncate }
      i := next(i) { next buffer index }

   end;
 
   hash := h+1 { offset to 1..n and return result }

end; 

{*******************************************************************************

Remove hash entries

Searches through the hash table for entries to remove, using the provided buffer
index.

For this fairly large hash table, the time taken to remove dead entries will
be large. A future improvement will be to keep a list of entries by index for
quick removal.

*******************************************************************************}

procedure killhash(i: bufinx);

var p:    hshptr; { hash entries pointer }
    n:    hshptr; { next entry holder }
    h:    hshinx; { index for hashing table }

{ delete hash entry }

procedure delete(var h: hshptr; p: hshptr);

begin

   if p^.next = p then begin 

      h := nil; { clear top entry }
      puthsh(p); { release entry }
 
   end else begin

      p^.next^.last := p^.last; { link next to last }
      p^.last^.next := p^.next; { link last to next }
      { if head points to us, then move it to the next entry }
      if h = p then h := p^.next;
      puthsh(p) { release entry }

   end

end;

begin

   p := riptbl[i]; { index the rip table root for that entry }
   while p <> nil do begin { remove all entries }

      h := hash(p^.inx, p^.len); { find hash for entry }
      n := p^.rip; { index next before we dispose of it }
      delete(hshtbl[h], p); { remove the entry }
      p := n { set new next }

   end;
   riptbl[i] := nil { clear rip table head }

end;

{*******************************************************************************

Kill hash table complete

Removes all entries from the hash table, and places them into the free hash
entries list. This routine is used to clear out the hash table between files.

*******************************************************************************}

procedure killhashall;

var h: hshinx;

begin

   for h := 1 to maxhash do killhash(h) { kill all table entries }

end;

{*******************************************************************************

Find match between positions

Checks the two buffer strings match. The buffer indexes of the strings are
given, with the length. Returns true if the data in the buffer matches. No
attempt is made to validate the buffer indexes. Wraparound is allowed for.

*******************************************************************************}

function match(a, b: bufinx; l: runlen): boolean;

begin

   while (buff[a] = buff[b]) and (l > 0) do begin { match }

      a := next(a); { find next indexes }
      b := next(b);
      l := l-1 { count down }

   end;

   match := l = 0 { if we examined all characters, match }

end;

{*******************************************************************************

Find hash match

Finds a matching entry for the given index and length in the buffer. Returns
the matching hash entry, or nil if not found.

*******************************************************************************}

function fndhsh(i: bufinx; l: runlen): hshptr;

var p, f: hshptr; { hash pointer }
    h:    hshinx; { hash index }

begin

   h := hash(i, l); { get hash for entry }
   p := hshtbl[h]; { index top of matching list }
   f := nil; { clear found pointer }
   while p <> nil do begin { traverse that list }

      if p^.len = l then begin { length matches }

         if match(i, p^.inx, l) then begin { found }

            f := p; { place found pointer }
            p := nil { clear list pointer }

         end else p := p^.next { next entry }

      end else p := p^.next; { next entry }
      if p = hshtbl[h] then p := nil { terminate if we have circled }

   end;

   fndhsh := f { return result }

end;

{*******************************************************************************

Add new hash entries

Adds new hash entries for a new input byte. The current output index has been
advanced, and a new byte exists, so we need to add new hash entries for that.
This is done by walking backwards from the current output index, and adding a
new entry for each data string back to either the match maximum length or the
end of the cache.

*******************************************************************************}

procedure newhash;

var i: bufinx; { index for buffer }
    l: runlen; { run length }
    h: hshinx; { hash index }
    p: hshptr; { hash entry pointer }

begin

   l := 1;
   i := last(outinx); { start at new location }
   while (i <> last(chcinx)) and (l <= runmax) do begin { add entries }

      p := fndhsh(i, l); { find existing entry }
      if p = nil then begin { enter new }

         h := hash(i, l); { find hash }
         gethsh(p); { get a new hash entry }
         p^.inx := i; { place buffer index }
         p^.len := l; { place length }
         if hshtbl[h] = nil then begin { list is empty }
    
            p^.next := p; { cross link the entry }
            p^.last := p

         end else begin { list not empty }

            p^.next := hshtbl[h]; { link to next entry }
            p^.last := hshtbl[h]^.last; { link to last entry }
            hshtbl[h]^.last^.next := p; { link last to this }
            hshtbl[h]^.last := p { link next to this }

         end;
         hshtbl[h] := p; { place as first entry }
         p^.rip := riptbl[i]; { push onto ripper table }
         riptbl[i] := p

      end;
      i := last(i); { back up one }
      l := l+1 { count up }

   end

end;

{*******************************************************************************

Load next buffer character(s)

Loads up to 128 input characters into the buffer. To enable the best matching,
we try to keep at least 128 bytes of future data in the buffer, the maximum
length of any match or run.

If the caching limit is not reached, then as much data as possible is loaded
until the caching is full. This allows for maximum range of matches.

*******************************************************************************}

procedure nxtinp(var f: bytfil; var p: integer);

begin

   { while not end of input, not buffer full (as evidenced by input pointer
     wrapping to output pointer), not input at 128 byte maximum match }
   while not eof(f) and (next(inpinx) <> outinx) and 
         (dist(outinx, inpinx) < runmax) do begin

      { Not end of input file, buffer isn't full, and not overruning
        cache, or run length not satisfied. }
      read(f, b); { get next byte }
      { see if we are in the blotter section }
      if bltlen <> 0 then { blotter is active }
         { if we are in the blotter area, mask it out }
         if (p >= bltstr) and (p <= bltstr+bltlen-1) then b := rand and $ff;
      p := p+1; { next file position }
      buff[inpinx] := b; { place in buffer }
      inpinx := next(inpinx); { find next index }
      { if we have wrapped around to the bottom of caching data, we need to move
        the cache bottom ahead of the new data }
      if chcinx = inpinx then begin

         killhash(chcinx); { kill existing hash entries on that index }
         chcinx := next(chcinx) { next cache index }

      end;
      addcrc(filcrc, b); { calculate CRC this byte }
      newhash { find new hash entries }

   end

end;

{*******************************************************************************

Find maximum buffer match

Finds the maximum match between the current output position and the caching
data.

*******************************************************************************}

procedure maxmat(var a: bufinx; var l: runlen);

var rl:   runlen; { run length }
    p:    hshptr; { hash entry found }
    time: integer; { time holder }

begin

   time := clock; { save start time }
   rl := dist(outinx, inpinx); { find maximum possible length }
   p := nil; { set no hash found }
   while (p = nil) and (rl > 0) do begin { try matches }

      p := fndhsh(outinx, rl); { find a matching entry }
      rl := rl-1 { try smaller }

   end;
   if p <> nil then begin { set largest match we found }

      a := p^.inx; { set index }
      l := p^.len { set length }

   end else begin { set no match found }

      a := 1; { clear index }
      l := 0 { clear maximum run length }

   end

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

procedure compress(var inpnam: filnam);

var i:      bufinx; { buffer index }
    rl:     runlen; { run length }
    crlen:  runlen; { cached run length }
    crbuf:  array [runinx] of byte; { buffered run bytes }
    d:      bufinx; { distance to match point }
    x:      runlen;
    tlknum: integer; { tolken sequence number }
    inpfil: bytfil;  { input file }
    inppos: integer; { position in input file }
    hi:     hshinx;  { index for hash table }
    ri:     bufinx;  { rip table index }

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
      wrtdat(crlen); { output run length }
      for i := 1 to crlen do wrtdat(crbuf[i]); { output run bytes }
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

   if not exists(inpnam) then error(esys); { source file should exist }
   assign(inpfil, inpnam); { open file to read }
   reset(inpfil);
   inppos := 1; { set input file position }
   inpinx := 1; { set initial buffer indexes }
   outinx := 1;
   chcinx := 1;
   crlen := 0; { set run tolken inactive }
   tlknum := 1; { set 1st tolken }
   filcrc := 0; { clear CRC accumulator }
   for hi := 1 to maxhash do hshtbl[hi] := nil; { clear hash table }
   for ri := 1 to bufmax do riptbl[ri] := nil; { clear ripper table }
   { output start of data tolken }
   wrtdat(0);
   wrtdat(ord(scstr));
   repeat { compress loop }

      nxtinp(inpfil, inppos); { keep input full }
      maxmat(i, rl); { find any matches }
      if rl > 3 then begin { output as match tolken }

         outrun; { output any cached run tolken }
         d := dist(i, outinx); { find distance from output index }
         { Output match tolken length, in -1 format, with bit 7 low to indicate
           a match tolken. }
         if diag then begin { output a diagnostic }

{;outbuf;}
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
         wrtdat(rl*16+d div 256);
         wrtdat(d mod 256);  { output low distance }
         for x := 1 to rl do begin { advance output index }

            outinx := next(outinx); { advance index }
            newhash { find new hash entries }

         end;
         tlknum := tlknum+1 { count tolkens }

      end else begin { output as run length }

         entrun(buff[outinx]); { place next run byte }
         outinx := next(outinx); { advance output index }
         newhash { find new hash entries }

      end

   { until buffer is empty and end of input }
   until (outinx = inpinx) and eof(inpfil);
   outrun; { output any cached run tolken }
   if diag then writeln('End of file');
   { output the CRC }
   if diag then begin

      write('CRC for file: ');
      prthex(8, filcrc);
      writeln

   end;
   wrtdat(0); { output specials code }
   wrtdat(ord(sccrc)); { CRC follows }
   wrtdat(filcrc div $1000000 and $ff); { output the CRC in big endian order }
   wrtdat(filcrc div $10000 and $ff);
   wrtdat(filcrc div $100 and $ff);
   wrtdat(filcrc and $ff);        
   { output the end of data tolken }
   wrtdat(0);
   wrtdat(ord(scend));
   close(inpfil); { close the input }
   killhashall { remove and free all hash entries }

end;

{*******************************************************************************

Perform special processing on Windows .exe (PE) file

Checks if the given file is a portable executable file. If so, the start of the
program, located in the '.text' segment is found, then we check for a blotter
data structure at the front of the file. If this is found, this indicates a
series of security structures that need to be modified within the program.

*******************************************************************************}

procedure prcexe(view exenam: string);

const hdrfix = 176; { number of bytes in the fixed portion of the header }

var exefil:  bytfil;  { .exe file }
    objects: integer; { number of objects in object directory }
    hdrsiz:  integer; { header size }
    txtsiz:  integer; { size of .text segment }
    txtoff:  integer; { offset of .text in file }
    codbas:  integer; { code base address }
    datbas:  integer; { data base address }
    imgbas:  integer; { image base address }
    w:       integer;
    i:       integer;

{ read a 16 bit word from file }

procedure readwrd(var f: bytfil; var w: integer);

var b1, b2: byte;
    i1, i2: integer;

begin

   read(f, b1); { get low byte }
   read(f, b2); { get high byte }
   i1 := b1; { expand the value }
   i2 := b2;
   w := i2*256+i1 { place result }

end;
    
{ read a 32 bit word from file }

procedure readdwd(var f: bytfil; var w: integer);

var b1, b2, b3, b4: byte;
    i1, i2, i3, i4: integer;

begin

   read(f, b1); { get low byte }
   read(f, b2); { get mid low byte }
   read(f, b3); { get mid high byte }
   read(f, b4); { get high byte }
   i1 := b1; { expand the value }
   i2 := b2;
   i3 := b3;
   i4 := b4;
   w := i4*16777216+i3*65536+i2*256+i1 { place result }

end;

{ process object object table }

procedure prcobj(objects: integer);

var i, x: integer;
    b:    byte;
    name: packed array 8 of char; { name of object }
    w:    integer;
    psiz: integer; { physical size in file }
    poff: integer; { physical offset in file }

begin

   for i := 1 to objects do begin { objects }
    
      for x := 1 to 8 do begin { read object name }

         read(exefil, b); { get character }
         name[x] := chr(b and $7f); { place character }
         if b = 0 then name[x] := ' ' { replace zero padding }

      end;
      readdwd(exefil, w); { get virtual size }
      readdwd(exefil, w); { get RVA }
      readdwd(exefil, psiz); { get physical size }
      readdwd(exefil, poff); { get physical offset }
      readdwd(exefil, w); { get relocations }
      readdwd(exefil, w); { get lines }
      readwrd(exefil, w); { get reloc count }
      readwrd(exefil, w); { get line count }
      readdwd(exefil, w); { get object flags }
      if compp(name, '.text') then begin { found the text segment }

         txtsiz := psiz; { set .text segment size }
         txtoff := poff  { set .text segment offset }

      end

   end

end;

{ Process blotter section }

procedure prcblt;

var bltnam: packed array 8 of char;
    i:      1..8;
    b:      byte;
    l:      integer;
    w:      integer;

{ find net offset address }

function offset(a: integer): integer;

begin

   { Remove whole image base plus code offset, add back the .text section
     offset, then adjust for 1..n format. }
   offset := a-(imgbas+codbas)+txtoff+1

end;

begin

   position(exefil, txtoff+1+5); { position to blotter }
   for i := 1 to 8 do begin { read blotter id }

      read(exefil, b); { get next byte }
      bltnam[i] := chr(b) { place as character }

   end;
   if comp(bltnam, 'blotter!') then begin { found the blotter }

      bltstr := txtoff+1+5; { set start of blotter }
      readdwd(exefil, bltlen); { get length of blotter }
      bltlen := bltlen+8; { add the 'blotter!' signature }
      repeat { get blotter data items }

         read(exefil, b); { get next blotter command }
         if b = ord(bdt_macadr) then begin { mac address table }

            wrtdat(0); { write mac address table tolken }
            wrtdat(ord(scmaca));
            readdwd(exefil, w); { get address }
            wrtint(offset(w))
            
         end else if b = ord(bdt_cpustr) then begin { cpu id table }

            wrtdat(0); { write cpu id tolken }
            wrtdat(ord(sccpui));
            readdwd(exefil, w); { get address }
            wrtint(offset(w))

         end else if b = ord(bdt_winver) then begin { windows version }

            wrtdat(0); { write windows version tolken }
            wrtdat(ord(scwinv));
            readdwd(exefil, w); { get address }
            wrtint(offset(w))

         end else if b = ord(bdt_timlim) then begin { time limit }

            wrtdat(0); { write time limit tolken }
            wrtdat(ord(sctimi));
            readdwd(exefil, w); { get address }
            wrtint(offset(w))

         end else if b <> ord(bdt_end) then begin

            copy(errnam, exenam); { set error name }
            error(einvexe) { invalid .exe file }

         end
      
      until b = ord(bdt_end) { end of blotter data area }

   end   

end;

begin

   txtsiz := 0; { clear .text parameters }
   txtoff := 0;
   assign(exefil, exenam); { open the file }
   reset(exefil);
   readwrd(exefil, w); { get MSDOS signature }
   if w <> $5a4d then begin

      copy(errnam, exenam); { set error filename }
      error(einvexe) { must be 'MZ' (.exe magic number) }

   end;
   for i := 1 to (15+4+10)*2 do read(exefil, b); { index new .exe header offset }
   readdwd(exefil, w); { get offset }
   position(exefil, w+1); { go to it }
   readdwd(exefil, w); { check 'PE<0><0>' signiture }
   if w <> $00004550 then begin

      copy(errnam, exenam); { set error filename }
      error(einvexe) { invalid file format }

   end;
   readwrd(exefil, w); { get the machine type }
   readwrd(exefil, objects); { get the number of objects }
   for i := 1 to 3 do readdwd(exefil, w); { skip }
   readwrd(exefil, hdrsiz); { get NT header size }
   readwrd(exefil, w); { get flags }
   readwrd(exefil, w); { get nt header magic }
   if w <> $10b then begin

      copy(errnam, exenam); { set error filename }
      error(einvexe) { invalid file format }

   end;
   readwrd(exefil, w); { get DB ver }
   for i := 1 to 4 do readdwd(exefil, w); { skip }
   readdwd(exefil, codbas); { get base of code }
   readdwd(exefil, datbas); { get base of data }
   readdwd(exefil, imgbas); { get image base }
   for i := 1 to 36 do readdwd(exefil, w); { skip }
   { skip the remaining bytes in the header }
   for i := 1 to hdrsiz-hdrfix do read(exefil, b);
   prcobj(objects); { process the object directory }
   if (txtsiz = 0) or (txtoff = 0) then begin

      copy(errnam, exenam); { set error filename }
      error(einvexe); { should have a .text }

   end;
   prcblt; { process any blotter }
   close(exefil) { close file }

end;

{*******************************************************************************

Process files

Given a release tree to process, each file of the release tree is labeled and
transferred to the output file, in compressed form.

*******************************************************************************}

procedure prcrel(dp: dirptr);

var fp:      filptr; { pointer for file entries }
    p, n, e: filnam; { filename components }
    name:    filnam; { filename buffer }

procedure wrtstr(view s: string; o: integer);

var l, ls, i: integer;

begin

   l := len(s); { find length of string }
   ls := l-o+1; { find length of string minus offset }
   if (ls < 0) or (ls > 255) then error(esys); { negative or too long }
   wrtdat(ls); { write length of string }
   for i := o to l do wrtdat(ord(s[i])) { write string }

end;

begin

   while dp <> nil do begin

      { The directories will include the root, which we remove, so that is null.
        We suppress that. }
      if len(rotnam) <= len(dp^.name^) then begin

         { write path for the next files (which could be empty) }
         wrtdat(0); { write path tolken }
         wrtdat(ord(scpth));
         { This is a fairly nasty trick, we need to chop off the original path.
           We do this by subtracting the length of the original root name from
           it. This relies on the root path being identical to the expanded form
           of the path. }
         wrtstr(dp^.name^, len(rotnam)); { write path }

      end;
      fp := dp^.files; { index top of files list }
      while fp <> nil do begin

         if not (atdir in fp^.attr) then begin

            brknam(fp^.name^, p, n, e); { break filename into components }
            maknam(name, dp^.name^, n, e); { construct full name }
            if true {diag} then writeln('Adding: ', name:0);
            wrtdat(0); { write file name tolken }
            wrtdat(ord(scnam));
            wrtstr(fp^.name^, 1); { write filename }
            { set no blotter section is active }
            bltstr := 0;
            bltlen := 0;
            { perform special PE processing }
            if compp(e, 'exe') then prcexe(name);
            compress(name) { compress file into install database }

         end;
         fp := fp^.next

      end;
      dp := dp^.next { next directory }

   end

end;

{*******************************************************************************
             
Parse options

Any number of <option> forms are parsed.

*******************************************************************************}

procedure paropt;

var err:                  boolean; { error flag }
    optfnd:               boolean; { option found }
    w:                    filnam;  { option word }
    year, month, day:     integer; { date }
    hour, minute, second: integer; { time }
    tim:                  integer; { time calculator }
    majv, minv, bldv:     integer; { version number components }
    i:                    integer;

{ set true/false flag }

procedure setflg(view a, n: string; var f: boolean);

var ts: packed array [1..40] of char; { string holder }

begin

   if compp(w, n) or compp(w, a) then begin

      f := true; { perform true }
      optfnd := true { set option found }

   end else begin { try false cases }

      copy(ts, 'n'); { form negative }
      cat(ts, n);
      if compp(w, ts) then begin

         f := false; { perform false }
         optfnd := true { set option found }

      end else begin

         copy(ts, 'n'); { form negative }
         cat(ts, a);
         if compp(w, ts) then begin

            f := false; { perform false }
            optfnd := true { set option found }

         end

      end

   end

end;
   
{ convert time and date to S2000 time }

function time2secs(year, month, day, hour, minute, second: integer): integer;

const secsperday = 24*60*60; { seconds in a day }

fixed 

    { compiler bug: this declaration should have worked }
    days: array [1..12] of {1..31} integer = array { days in months }

             31, { january }
             28, { february-leap day }
             31, { march }
             30, { april }
             31, { may }
             30, { june }
             31, { july }
             31, { august }
             30, { september }
             31, { october }
             30, { november }
             31  { december }

          end;

var time: integer; { time holder }
    dm:   integer; { days in month }
    y, m: integer;
    i:    integer;

function leapyear(y: integer): boolean;

begin

   leapyear := (y mod 4 = 0) and (y mod 100 <> 0) or (y mod 400 = 0)

end;

begin

   time := 0; { clear time }
   { add years }
   if year >= 2000 then begin 

      { add years }
      y := 2000; { set initial year }
      while y < year do begin { loop positive offset }

         time := time+(365+ord(leapyear(y)))*secsperday;
         y := y+1

      end;
      { add months }
      m := 1; { set initial month }
      while m < month do begin

         time := time+(days[m]+ord(leapyear(year))*ord(m = 2))*secsperday;
         m := m+1

      end;
      { add days }
      time := time+(day-1)*secsperday;
      time := time+hour*60*60; { add hours }
      time := time+minute*60; { add minutes }
      time := time+second { add seconds }

   end else begin 

      { subtract years }
      y := 1999; { set initial year }
      while y > year do begin { loop negative offset }

         time := time-(365+ord(leapyear(y)))*secsperday;
         y := y-1

      end;
      { subtract months }
      m := 12; { set initial month }
      while m > month do begin

         time := time-(days[m]+ord(leapyear(year))*ord(m = 2))*secsperday;
         m := m-1

      end;
      { subtract days }
      time := time-(days[month]+ord(leapyear(year))*ord(m = 2)-day)*secsperday;
      time := time-(24-hour-1)*60*60; { subtract hours }
      time := time-(60-minute-1)*60; { subtract minutes }
      time := time-(60-second) { subtract seconds }

   end;

   time2secs := time { return total seconds }

end;

{ convert local to gmt time }

function gmt(t: integer): integer;

var ct: integer;

begin

   ct := time; { get current time } 
   gmt := t+(ct-local(ct))

end;

begin

   skpspc(cmdhan); { skip spaces }
   while chkchr(cmdhan) = optchr do begin { parse options }

      optfnd := false; { set no option found }
      getchr(cmdhan); { skip option character }
      parlab(cmdhan, w, err); { parse option label }
      if err then error(einvopt); { invalid option }
      setflg('cdo',  'cdromonly', fcdonly); { install from CD-ROM only }
      setflg('dm',  'demo',       fdemo); { release is a demo }
      setflg('bt',  'beta',       fbeta); { release is a beta }
      if not optfnd then begin { option not found }

         if compp(w, 'actmax') then begin { set activation maximum }

            skpspc(cmdhan); { skip spaces }
            if chkchr(cmdhan) <> '=' then error(easexp); { '=' expected }
            getchr(cmdhan); { skip }
            parnum(cmdhan, i, 10, err); { parse number }
            if err then error(einvnum); { invalid number }
            actmax := i { place maximum }

         end else if compp(w, 'serial') then begin { set serial number }

            skpspc(cmdhan); { skip spaces }
            if chkchr(cmdhan) <> '=' then error(easexp); { '=' expected }
            getchr(cmdhan); { skip }
            parnum(cmdhan, i, 10, err); { parse number }
            if err then error(einvnum); { invalid number }
            serman := i { place serial number manual set }

         end else if compp(w, 'timelimit') then begin { set time limit }

            skpspc(cmdhan); { skip spaces }
            if chkchr(cmdhan) <> '=' then error(easexp); { '=' expected }
            getchr(cmdhan); { skip }
            { parse date/time in ISO 8601 format. No spaces are allowed between
              sections of the date or time. }
            parnum(cmdhan, year, 10, err); { parse year }
            if err then error(einvnum); { invalid number }
            if chkchr(cmdhan) <> '-' then error(edshexp); { '-' expected }
            getchr(cmdhan); { skip }
            parnum(cmdhan, month, 10, err); { parse month }
            if err then error(einvnum); { invalid number }
            if chkchr(cmdhan) <> '-' then error(edshexp); { '-' expected }
            getchr(cmdhan); { skip }
            parnum(cmdhan, day, 10, err); { parse day }
            if err then error(einvnum); { invalid number }
            skpspc(cmdhan); { skip spaces }
            parnum(cmdhan, hour, 10, err); { parse hour }
            if err then error(einvnum); { invalid number }
            if chkchr(cmdhan) <> ':' then error(eclnexp); { ':' expected }
            getchr(cmdhan); { skip }
            parnum(cmdhan, minute, 10, err); { parse minute }
            if err then error(einvnum); { invalid number }
            if chkchr(cmdhan) <> ':' then error(eclnexp); { ':' expected }
            getchr(cmdhan); { skip }
            parnum(cmdhan, second, 10, err); { parse second }
            if err then error(einvnum); { invalid number }
            { find resulting S2000 time }
            timlim := gmt(time2secs(year, month, day, hour, minute, second));

         end else if compp(w, 'v') or compp(w, 'version') then begin

            { set version number }
            skpspc(cmdhan); { skip spaces }
            if chkchr(cmdhan) <> '=' then error(easexp); { '=' expected }
            getchr(cmdhan); { skip }
            { Parse version as maj.min.build }
            parnum(cmdhan, majv, 10, err); { parse major }
            if err then error(einvnum); { invalid number }
            if chkchr(cmdhan) <> '.' then error(edshexp); { '.' expected }
            getchr(cmdhan); { skip }
            parnum(cmdhan, minv, 10, err); { parse minor }
            if err then error(einvnum); { invalid number }
            if chkchr(cmdhan) <> '.' then error(edshexp); { '.' expected }
            getchr(cmdhan); { skip }
            parnum(cmdhan, bldv, 10, err); { parse build }
            if err then error(einvnum); { invalid number }
            { now validate it }
            if (majv < 0) or (majv > 999) then error(einvver);
            if (minv < 0) or (minv > 99) then error(einvver);
            if (bldv < 0) or (majv > 9999) then error(einvver);
            { construct combined version number }
            version := majv*1000000+minv*10000+bldv
         
         end else error(eoptnf); { option not found }

      end;
      skpspc(cmdhan) { skip spaces }

   end

end;

begin

   writeln;
   writeln('Release creator 1.00.0001');
   writeln;
   frehsh := nil; { clear free hash entries list }
   aopn := false; { set no files open }
   bopn := false;
   datcrc := $75629948; { set data CRC to arbitrary starting value }
   enccrc := $65823792; { set encoder CRC to arbitrary starting value }
   rndseq := 314159; { initalize random number generator }
   fcdonly := true; { install from CD-ROM only }
   fdemo := false; { set not a demo }
   fbeta := false; { set not a beta }
   actmax := maxact; { set maximum activation count }
   timlim := maxint; { set no time limit }
   serman := 0; { set no manual serial number set }
   version := 0; { set no version number }
   openpar(cmdhan); { open parser }
   openfil(cmdhan, '_command', 250); { open command line level }
   filchr(valfch); { get the filename valid characters }
   valfch := valfch-['=']; { remove parsing characters }
   setfch(cmdhan, valfch); { set that for active parsing }
   paropt; { parse options }
   gencrc; { generate the CRC remainder table }
   { get release date and time }
   reltim := time;
   if serman = 0 then begin { no manual serial number set }

      { aquire and increment the serial number file }
      if not exists('serial.txt') then error(ecntfil); { missing count file }
      assign(serfil, 'serial.txt'); { open serial number file }
      reset(serfil);
      read(serfil, sernum); { get the current serial number }
      close(serfil); { close the file }

   end else sernum := serman; { else use the manual serial number }
   copy(rotnam, rootname); { set default ip release root }
   copy(datnam, dataname); { set default ip installer data file }
   { make a copy of the tree to be placed into the release data }
   treelist(rotnam, maxint, 0, false, [], [], [], [], [], [], [], [], dirlst);
   { create output data file }
   assign(datfil, datnam);
   rewrite(datfil);
   wrtdat(ord('I')); { place file signature, "INST" (installer) }
   wrtdat(ord('N'));
   wrtdat(ord('S'));
   wrtdat(ord('T'));
   writeln('Creating release in install.dat');
   writeln;

   { output the system data area }
   wrtdat(0); { output serial number }
   wrtdat(ord(scser));
   wrtint(sernum);
   wrtdat(0); { output release time }
   wrtdat(ord(sctim));
   wrtint(reltim);
   wrtdat(0); { output CD-ROM only status }
   wrtdat(ord(sccdol));
   wrtdat(ord(fcdonly));
   wrtdat(0); { output demo status }
   wrtdat(ord(scdemo));
   wrtdat(ord(fdemo));
   wrtdat(0); { output beta status }
   wrtdat(ord(scbeta));
   wrtdat(ord(fbeta));
   wrtdat(0); { output time limit }
   wrtdat(ord(sctiml));
   wrtint(timlim);
   wrtdat(0); { output software version number }
   wrtdat(ord(scver));
   wrtint(version);
   wrtdat(0); { output end of system data area }
   wrtdat(ord(scsend));

   if not fdemo then begin { not a demo, which does not activate }

      { after the system area, we switch to encoding using a value that only the
        activation server will know. }
      rplcrc := time xor $58973083; { use time with obfuscation }
      enccrc := enccrc xor rplcrc; { mix that with existing crc }

   end;

   { perform encoding of data files }
   prcrel(dirlst); { process release tree }
   { output the end of file tolken }
   wrtdat(0);
   wrtdat(ord(sceof));
   { output the entire file CRC to the end }
   write(datfil, datcrc div $1000000 and $ff);
   write(datfil, datcrc div $10000 and $ff);
   write(datfil, datcrc div $100 and $ff);
   write(datfil, datcrc and $ff);
   close(datfil); { close the data file }
   if serman = 0 then begin { update the serial number file }

      assign(serfil, 'serial.txt'); { open serial number file }
      rewrite(serfil); { rewrite the serial number file }
      writeln(serfil, sernum+1); { output the next serial number to that }
      close(serfil) { close }

   end;
   writeln;
   writeln('Serial number for this release is: ', sernum:1);
   write('CRC for this release is:           '); prthex(8, datcrc); writeln;
   write('Date and time for this release is: '); 
   writedate(local(reltim)); 
   write(' ');
   writetime(local(reltim));
   writeln;
   writeln;
   writeln('The file ', datnam:0, ' contains the created IP release');
   { open the recording file }
   if not exists('release.dat') then begin { create release tracking file }

      assign(relfil, 'release.dat'); { create an empty file }
      rewrite(relfil);
      close(relfil)

   end;
   assign(relfil, 'release.dat'); { open file }
   update(relfil); { open for updating }
   position(relfil, length(relfil)+1); { position to end of file }
   relfil^.serial := sernum; { place serial number }
   relfil^.crc := datcrc; { place data crc }
   relfil^.reltim := reltim; { place release time }
   relfil^.actnum := 0; { clear activation count }
   relfil^.actfst := -maxint; { set no first activation }
   relfil^.actlst := -maxint; { set no last activation }
   relfil^.timlim := timlim; { set no time limit }
   relfil^.demo := fdemo; { set demo status }
   relfil^.beta := fbeta; { set beta status }
   relfil^.ver := version; { set no version number }
   relfil^.black := false; { set not blacklisted }
   relfil^.spoof := 0; { set no spoof attempts }
   relfil^.actlim := actmax; { set maximum number of activations }
   relfil^.cdonly := fcdonly; { set install from CD-ROM only }
   relfil^.rplcrc := rplcrc; { set reply CRC }
   relfil^.pad1 := 0; { clear padding }
   relfil^.pad2 := 0;
   relfil^.pad3 := 0;
   put(relfil); { write to end of file }
   writeln;
   writeln('The release data file release.dat now contains: ', 
           length(relfil):1, ' release records');
   close(relfil); { close release data }

   99: { abort program }

end.

