{******************************************************************************
*                                                                             *
*                                  DPINT                                      *
*                                                                             *
*                     COMPILER INTERMEDIATE FILE DUMPER                       *
*                                                                             *
*                       Copyright (C) 1994 S. A. Moore                        *
*                                                                             *
*                              Written 7/94                                   *
*                                                                             *
* This program dumps intermediate files, which are output by the front end    *
* parse of a compiler, or a pipeline processor such as an optimizer           *
*                                                                             *
* A relitively simple dump is provided, with each entry construct output on   *
* it's own line. The printout may get unmanageable for large files.           *
* Accepts a command line of the form:                                         *
*                                                                             *
*    dpint <file>                                                             *
*                                                                             *
* If the given file has no extention, we search first for file.opt, then for  *
* file.int. Otherwise, the file is opened under the extention given.          *
*                                                                             *
******************************************************************************}

program dpint(command, output);

uses strlib, { strings }
     extlib, { OS interface }
     intfrm; { intermediate form }

label 99; { abort program }

const

   maxlin = 255; { number of characters in a text line }
   maxfil = 255; { number of characters in a file name }

type

   lininx = 1..maxlin;  { index for text line }
   linbuf = packed array [lininx] of char; { a text line }
   filinx  = 1..maxfil; { index for file names }
   filnam  = packed array [filinx] of char; { a file name }
   ext    = packed array [1..3] of char; { filename extention }
   blkptr = ^block; { pointer to block }
   block  = record { block tracking entry }

               cnt: integer; { entry count }
               next: blkptr { next entry link }

            end;

var

   intfil:  bytfil;  { intermediate file }
   intnam:  filnam;  { intermediate file name }
   cmdlin:  linbuf;  { command line buffer }
   cmdptr:  lininx;  { command line index }
   b:       byte;    { file byte holder }
   ib:      integer; { full code holder }
   ic:      intcod;  { intermediate code holder }
   v:       integer; { integer value holder }
   r:       real;    { real value holder }
   blkcnt:  integer; { block level counter }
   blkstk:  blkptr;  { block entry stack }
   bp:      blkptr;  { pointer for block stack }
   i:       integer; { counter }
   spccnt:  integer; { space counter }
   fi:      filinx;  { index for filenames }
   intcnt:  integer; { intermediate tolken count }
   codprt:  boolean; { print this intermediate }
   cursrc:  filnam;  { current source filename }
   srcfil:  text;    { source file }
   srcopn:  boolean; { source file is open }
   srclin:  integer; { source line number that is current }
   srcbuf:  linbuf;  { buffer for next source line }
   srcmod:  filnam;  { source file primary name only }
   p, e:    filnam;  { source file name components }
   { option flags }
   fsrclin: boolean; { list source lines }
   fsrcsup: boolean; { suppress source line markers }

{ abort compilation vector }

procedure abort;

begin

   goto 99 { terminate program }

end;

{******************************************************************************

Get command line

The command line is loaded to the given buffer. In SVS, this is reconstructed
from the command line arguments with spaces between.

******************************************************************************}

procedure getcmd(var lin: linbuf);

var i:  lininx;  { command line index }

begin

   for i := 1 to maxlin do lin[i] := ' '; { clear input line }
   i := 1; { set 1st line position }
   while not eoln(command) do begin { load command line }

     read(command, lin[i]); { get next character }
     if i = maxlin then begin { overflow }

        writeln('*** Command input line overflow');
        abort

     end;
     i := i + 1 { next character position }

   end

end;

{******************************************************************************

Check end of line

Checks whether the input line position is at the end. This is indicated by
cmdptr being at the extreme end of the input line.
Note that in order to ensure that this is true, a skip space to line end
should be done.

******************************************************************************}

function endlin: boolean;

begin

   endlin := cmdptr = maxlin { true if at line maximum }

end;

{******************************************************************************

Check next input character

The next character in the input buffer is returned. No advance
is made from the current position (succesive calls to this
procedure will yeild the same character).

******************************************************************************}

function chkchr: char; { current input character }

var c: char; { result }

begin

   if endlin then c := ' ' { buffer end, just simulate spaces }
   else c := cmdlin[cmdptr]; { not at buffer end, return character }
   chkchr := c { return result }

end;

{******************************************************************************

Skip input character

Causes the current input character to be skipped, so that the next chkchr call
will return the next character. If endlin is true, no action will take place
(will not advance beyond end of line).

******************************************************************************}

procedure getchr;

begin

   if not endlin then { process advance }
      cmdptr := cmdptr+1 { advance one character }

end;

{******************************************************************************

Skip input spaces or controls

Skips the input position past any spaces or controls. Will skip the end of
line, loading the next line from the input. The view of the input is for each
line to be terminated by an infinite series of blanks, which only this routine
will cross.

******************************************************************************}

procedure skpspc;

begin

   { skip any spaces }
   while (chkchr = ' ') and not endlin do getchr

end;

{******************************************************************************

Parse file name

Parses a filename in the format:

     <filename> ::= [<letter>:]<letter>[<letter>/<digit>/'.']...
     <letter>   ::= 'a'..'z'/'A'..'Z'
     <digit>    ::= '0'..'9'

At present, this routine is dependent on DOS filename formats.

******************************************************************************}

procedure parnam(var fn: filnam); { file name return }

var fi, i: filinx;    { file name index }
    p:  0..maxfil; { primary length }

procedure getncr; { get name character }

begin

   if i > maxfil then begin

      writeln('*** Filename too long');
      abort

   end;
   fn[i] := chkchr; { place file character }
   getchr; { skip that }
   i := i + 1 { next }

end;

procedure getseq(max: filinx); { read name sequence }

var l : 0..maxfil; { length of filename }

begin

   l := 0; { initalize count }
   while chkchr in ['_', 'a'..'z', 'A'..'Z', '0'..'9'] do begin

      { filename }
      getncr; { get character }
      l := l + 1 { count }

   end;
   if l > max then begin

      writeln('*** Filename too long');
      abort

   end

end;

begin

   skpspc; { skip spaces }
   for fi := 1 to maxfil do fn[fi] := ' '; { clear filename }
   i := 1; { initalize index }
   p := 1; { initalize primary count for first character }
   if not (chkchr in ['_', 'a'..'z', 'A'..'Z']) then begin

      writeln('*** Invalid filename');
      abort

   end;
   getncr; { get character }
   if chkchr = ':' then begin { process drive specification }

      getncr; { get character }
      if not (chkchr in ['_', 'a'..'z', 'A'..'Z']) then begin

         writeln('*** Invalid filename');
         abort

      end;
      p := 0 { re - initalize primary }

   end;
   getseq(100 - maxfil); { get rest of primary }
   if chkchr = '.' then begin { secondary }

      getncr; { get character }
      if not (chkchr in ['_', 'a'..'z', 'A'..'Z', '0'..'9']) then begin

         writeln('*** Invalid filename');
         abort

      end;
      getseq(100) { get secondary }

   end

end;

{******************************************************************************

Parse options

Parses options from the command line.

******************************************************************************}

procedure paropt;

var n: filnam;    { option name holder }
    i: 0..maxfil; { index for that }
begin

   skpspc; { skip leading spaces }
   while chkchr = optchr do begin { process options }

      getchr; { skip option character }
      clears(n); { clear options label }
      { get the option label }
      i := 0; { set null }
      while chkchr in ['A'..'Z', 'a'..'z', '0'..'9', '_'] do begin

         i := i+1; { next character }
         if i > maxfil then begin { overflow }

            writeln('*** Option label overflow');
            abort

         end;
         n[i] := chkchr; { get next character }
         getchr { skip }

      end;
      if compp(n, 'sl') or compp(n, 'sourceline') then fsrclin := true
      else if compp(n, 'nsl') or compp(n, 'nosourceline') then fsrclin := false
      else if compp(n, 'ss') or compp(n, 'sourcesupress') then fsrcsup := true
      else if compp(n, 'nss') or compp(n, 'nosourcesupress') then
         fsrcsup := false
      else begin { no label found }

         writeln('*** Option not found');
         abort

      end;
      skpspc { skip spaces }

   end

end;

{******************************************************************************

Parse command line

The structure of a command line is:

     file

The file is parsed into intnam.

******************************************************************************}

procedure parcmd;

begin

   cmdptr := 1; { set 1st character in command line }
   paropt; { parse any options }
   parnam(intnam); { parse file }
   paropt; { parse any options }
   skpspc; { skip to line end }
   if not endlin then begin { no end of line }

      writeln('*** Invalid command syntax');
      abort

   end

end;

{******************************************************************************

Test filename contains an extention

Simply checks if '.' exists in the filename, which would indicate an extention
is present (in a properly parsed filename).

******************************************************************************}

function isext(var f: filnam): boolean; { filename to check }

var i: filinx;  { index for filename }
    m: boolean; { match flag }

begin

   m := false; { set no extention found }
   for i := 1 to maxfil do if f[i] = '.' then m := true; { set found }
   isext := m { return match status }

end;

{******************************************************************************

Append file extention

Appends a given extention, in place, to the given file name. The extention is
usually in the form: 'ext'. The extention is placed within the file name at the
first space or period from the left hand side. This allows extention of either
an unextended filename or an extended one (in which case the new extention
simply overlays the old). The overlay is controlled via flag: if overwrite is
true, the extention will overwrite any existing, if not, any existing extention
will be left in place.
No checking is performed for a new filename that will overflow the allotted
filename length.
In the case of overflow, the filename will simply be truncated.
Note: this routine is MS-DOS dependent.

******************************************************************************}

procedure addext(var fn: filnam; { filename to extend }
                 e: ext;         { filename extention }
                 ovr: boolean);  { overwrite flag }

var i : 1..maxfil; { filename index }
    x : 1..3; { extention index }

begin

   i := 1; { initalize index }
   { skip to first character ' ' or '.' }
   while (fn[i] <> ' ') and (fn[i] <> '.') and
         (i < maxfil-3) do i := i + 1;
   if ovr or (fn[i] = ' ') then begin { plant extention }

      fn[i] := '.'; { place '.' }
      i := i + 1; { next }
      for x := 1 to 3 do begin { append file extention }

         fn[i] := e[x]; { transfer extention character }
         i := i + 1 { count }

      end

   end

end;
{}
{******************************************************************************

Input variger

Inputs a variger to the given integer.
Varigers are of the following format:

   1. (byte) the tag byte.
   2-N. The variger value.

The tag byte values are:

   bit 7 - Low for integer number, high for float.
   bit 6 - Contains the sign of the integer.
   bit 5 - Unused.
   bit 4 - Length of integer in bytes, 1-32, in -1 format.
   bit 3 -      ""              ""
   bit 2 -      ""              ""
   bit 1 -      ""              ""
   bit 0 -      ""              ""

The integer is converted by removing the sign bit and converting
to signed magnitude, then determining the byte size, then
outputting the tag and number.

******************************************************************************}

procedure rdnum(var n: integer); { integer to input }

const usedirect = true;

var t: byte;     { tag byte }
    s: integer;  { sign }
    b: byte;     { read byte holder }

{ workaround for signed/unsigned words }

procedure rdraw(var n: integer; l: integer);

var r: record case boolean of

          true:  (i: integer);
          false: (b: packed array [1..4] of byte);

       end;
    i: integer;
    
begin

    r.i := 0;
    for i := l downto 1 do read(intfil, r.b[i]);
    n := r.i 

end;
    
begin

   read(intfil, t); { get tag byte }
   if (t and $80) <> 0 then begin

      writeln('*** Invalid intermediate format');
      abort

   end;
   if (t and $40) <> 0 then s := -1 else s := 1; { set sign of value }
   if (t and $20) <> 0 then begin

      writeln('*** Invalid intermediate format');
      abort

   end;
   t := (t and $1f)+1; { mask byte length and adjust }
   if usedirect then rdraw(n, t)
   else begin
    
      n := 0; { clear result }
      while t <> 0 do begin { read in bytes of value }

         n := n*256; { scale up bytes for big endian format }
         read(intfil, b); { get the next byte }
         n := n+b; { add in }
         t := t-1 { count bytes read }

      end
      
   end;
   n := n*s { set sign of result }

end;
{}
{******************************************************************************

Read real number from intermediate file

Reads a 64 bit real number to from the intermediate file.

******************************************************************************}

procedure rdreal(var r: real);

var rc: record case boolean of { data convertion }

           false: (r: real);
           true:  (b: packed array [1..8] of byte)

        end;
    rcs: record case boolean of { data convertion, short real }

           false: (r: sreal);
           true:  (b: packed array [1..4] of byte)

        end;
    i:  1..8; { index for byte array }
    b:  byte;
    s: integer; { size }

begin

   read(intfil, b); { get tag byte }
   if (b and $80) = 0 then begin

      writeln('*** Invalid intermediate format');
      abort

   end;
   s := b and $1f+1; { get size }
   if (s <> 4) and (s <> 8) then begin { not a size we support }

      writeln('*** Invalid intermediate format');
      abort

   end;
   if s = 8 then begin { standard real format }

      for i := 1 to 8 do begin { read bytes of real in }

         read(intfil, b);
         rc.b[i] := b

      end;
      r := rc.r { return real }

   end else begin { short real format }

      for i := 1 to 4 do begin { read bytes of real in }

         read(intfil, b);
         rcs.b[i] := b

      end;
      r := rcs.r { return real }

   end

end;

{******************************************************************************

Get and print link

Gets the complete intermediate address of the given type entry. The logical
address of a type entry consists of it's logical type level number, and it's
logical type entry number.
The address is printed as (level, entry).

******************************************************************************}

procedure getlnk;

var v: integer; { value to read }

begin

   rdnum(v); { get level number }
   write('(', v:1, ',');
   rdnum(v); { get entry number }
   write(v:1, ')')

end;

{******************************************************************************

Print unicode character or quivalent

Given a unicode character, prints either the character or a memonic preceeded
by a slash '\' that indicates what the character is. If the character is greater
than 255, it is printed as \uc. If it is 128-255, it is printed as \ec (which
stands for european character). If it is less than space or is 127-159, the
control memonic is printed. Otherwise, the character is simply printed.

******************************************************************************}

procedure wrtchr(uc: integer); { 16 bit unicode character }

begin

   if uc > 255 then write('\\uc:', uc:1)
   else if uc > 159 then write('\\ec:', uc:1)
   else if (uc < ord(' ')) or (uc = 127) then
      case uc of { control character }

      0:   write('\\nul');
      1:   write('\\soh');
      2:   write('\\stx');
      3:   write('\\etx');
      4:   write('\\eot');
      5:   write('\\enq');
      6:   write('\\ack');
      7:   write('\\bel');
      8:   write('\\bs');
      9:   write('\\ht');
      10:  write('\\lf');
      11:  write('\\vt');
      12:  write('\\ff');
      13:  write('\\cr');
      14:  write('\\so');
      15:  write('\\si');
      16:  write('\\dle');
      17:  write('\\xon');
      18:  write('\\dc2');
      19:  write('\\xoff');
      20:  write('\\dc4');
      21:  write('\\nak');
      22:  write('\\syn');
      23:  write('\\etb');
      24:  write('\\can');
      25:  write('\\em');
      26:  write('\\sub');
      27:  write('\\esc');
      28:  write('\\fs');
      29:  write('\\gs');
      30:  write('\\rs');
      31:  write('\\us');
      127: write('\\del');
      128:  write('\\pad');
      129:  write('\\hop');
      130:  write('\\bph');
      131:  write('\\nbh');
      132:  write('\\ind');
      133:  write('\\nel');
      134:  write('\\ssa');
      135:  write('\\esa');
      136:  write('\\hts');
      137:  write('\\htj');
      138:  write('\\vts');
      139:  write('\\pld');
      140:  write('\\plu');
      141:  write('\\ri');
      142:  write('\\ss2');
      143:  write('\\ss3');
      144:  write('\\dcs');
      145:  write('\\pu1');
      146:  write('\\pu2');
      147:  write('\\sts');
      148:  write('\\cch');
      149:  write('\\mw');
      150:  write('\\spa');
      151:  write('\\epa');
      152:  write('\\sos');
      153:  write('\\sgci');
      154:  write('\\sci');
      155:  write('\\csi');
      156:  write('\\st');
      157:  write('\\osc');
      158:  write('\\pm');
      159:  write('\\apc');

   end else write(chr(uc)) { output printable character }

end;

{******************************************************************************

Get and print string

A string is a length, followed by the string characters. Prints the string.

******************************************************************************}

procedure getstr;

var l:      byte;    { string length }
    bl, bh: byte;    { character holder (unicode) }
    uc:     integer; { unicode character }

begin

   if codprt then write('''');
   read(intfil, l); { get the string length }
   while l <> 0 do begin { print string characters }

      read(intfil, bh); { get a string character }
      read(intfil, bl);
      uc := bh*256+bl; { construct character }
      if codprt then wrtchr(uc); { write unicode character }
      l := l-1 { count }

   end;
   if codprt then write('''')

end;

overload procedure getstr(var s: string);

var l: byte; { string length }
    b: byte; { character holder }
    i: byte; { length of string }

begin

   clears(s); { clear the result string }
   read(intfil, l); { get the string length }
   i := 1; { set string index }
   while l <> 0 do begin { print string characters }

      read(intfil, b); { get upper half of ucs16 }
      if b <> 0 then begin { unicode character out of range }

         writeln('*** Unicode character handling not implemented');
         abort

      end;
      read(intfil, b); { get a string character }
      s[i] := chr(b);
      i := i+1; { next string character }
      l := l-1 { count }

   end

end;

{******************************************************************************

Print intermediate code

Prints the ascii memonic for the given intermediate code.

******************************************************************************}

procedure prtcod(c: intcod);

begin

   case c of { code }

      ibgnlvl:       write('bgnlvl     ');
      iendlvl:       write('endlvl     ');
      iusefil:       write('usefil     ');
      inil:          write('nil        ');
      ilab:          write('lab        ');
      iicst:         write('icst       ');
      iscst:         write('scst       ');
      iccst:         write('ccst       ');
      ircst:         write('rcst       ');
      istcst:        write('stcst      ');
      istet:         write('stet       ');
      iarrcst:       write('arrcst     ');
      iarrcel:       write('arrcel     ');
      ireccst:       write('reccst     ');
      ireccel:       write('reccel     ');
      ienum:         write('enum       ');
      ienme:         write('enme       ');
      isub:          write('sub        ');
      iptr:          write('ptr        ');
      iarray:        write('array      ');
      igarry:        write('garry      ');
      ifile:         write('file       ');
      iset:          write('set        ');
      irecord:       write('record     ');
      ifield:        write('field      ');
      iftag:         write('ftag       ');
      ifcas:         write('fcas       ');
      ivar:          write('var        ');
      ifix:          write('fix        ');
      iproc:         write('proc       ');
      ifunc:         write('func       ');
      ipar:          write('par        ');
      ivpar:         write('vpar       ');
      iwpar:         write('wpar       ');
      ipproc:        write('pproc      ');
      ipfunc:        write('pfunc      ');
      iint:          write('int        ');
      ichar:         write('char       ');
      iboolean:      write('boolean    ');
      ireal:         write('real       ');
      isreal:        write('sreal      ');
      itext:         write('text       ');
      ieset:         write('eset       ');
      iglbl:         write('glbl       ');
      inull:         write('null       ');
      isym:          write('sym        ');
      issym:         write('ssym       ');
      ibgnpgm:       write('bgnpgm     ');
      iendpgm:       write('endpgm     ');
      ibgnext:       write('bgnext     ');
      iendext:       write('endext     ');
      ilodadr:       write('lodadr     ');
      ilodfadr:      write('lodfadr    ');
      iarrref:       write('arrref     ');
      iarfgar:       write('arfgar     ');
      irecoff:       write('recoff     ');
      ildiint:       write('ldiint     ');
      ildirel:       write('ldirel     ');
      ildisrl:       write('ldisrl     ');
      ildiset:       write('ldiset     ');
      ildichr:       write('ldichr     ');
      ildibol:       write('ldibol     ');
      ildisrc:       write('ldisrc     ');
      ildiptr:       write('ldiptr     ');
      ilditgp:       write('lditgp     ');
      ilimint:       write('limint     ');
      ilimrel:       write('limrel     ');
      ilimns:        write('limns      ');
      ilodlen:       write('lodlen     ');
      ilodlenl:      write('lodlenl    ');
      inotint:       write('notint     ');
      inotbol:       write('notbol     ');
      isinset:       write('sinset     ');
      irngset:       write('rngset     ');
      icvtitr:       write('cvtitr     ');
      icvtgtf:       write('cvtgtf     ');
      icvtftg:       write('cvtftg     ');
      icvtntg:       write('cvtntg     ');
      iswptop:       write('swptop     ');
      iintset:       write('intset     ');
      imltrel:       write('mltrel     ');
      imltint:       write('mltint     ');
      idivrel:       write('divrel     ');
      idivint:       write('divint     ');
      imodint:       write('modint     ');
      iandint:       write('andint     ');
      inegint:       write('negint     ');
      inegrel:       write('negrel     ');
      iuniset:       write('uniset     ');
      iaddrel:       write('addrel     ');
      iaddint:       write('addint     ');
      idifset:       write('difset     ');
      isubrel:       write('subrel     ');
      isubint:       write('subint     ');
      iorint:        write('orint      ');
      ixorint:       write('xorint     ');
      iincset:       write('incset     ');
      iequset:       write('equset     ');
      iequrel:       write('equrel     ');
      iequstr:       write('equstr     ');
      iequgst:       write('equgst     ');
      iequint:       write('equint     ');
      iequtgp:       write('equtgp     ');
      ineqset:       write('neqset     ');
      ineqrel:       write('neqrel     ');
      ineqstr:       write('neqstr     ');
      ineqgst:       write('neqgst     ');
      ineqint:       write('neqint     ');
      ineqtgp:       write('neqtgp     ');
      ileqset:       write('leqset     ');
      ileqrel:       write('leqrel     ');
      ileqstr:       write('leqstr     ');
      ileqgst:       write('leqgst     ');
      ileqint:       write('leqint     ');
      igeqset:       write('geqset     ');
      igeqrel:       write('geqrel     ');
      igeqstr:       write('geqstr     ');
      igeqgst:       write('geqgst     ');
      igeqint:       write('geqint     ');
      iltnrel:       write('ltnrel     ');
      iltnstr:       write('ltnstr     ');
      iltngst:       write('ltngst     ');
      iltnint:       write('ltnint     ');
      igtnrel:       write('gtnrel     ');
      igtnstr:       write('gtnstr     ');
      igtngst:       write('gtngst     ');
      igtnint:       write('gtnint     ');
      ibgnblk:       write('bgnblk     ');
      iendblk:       write('endblk     ');
      iifbgn:        write('ifbgn      ');
      iifend:        write('ifend      ');
      ielse:         write('else       ');
      icasbgn:       write('casbgn     ');
      icasend:       write('casend     ');
      icassint:      write('cassint    ');
      icasstb:       write('casstb     ');
      icasste:       write('casste     ');
      iwhlexp:       write('whlexp     ');
      iwhlbgn:       write('whlbgn     ');
      iwhlend:       write('whlend     ');
      irptbgn:       write('rptbgn     ');
      irptend:       write('rptend     ');
      ifortint:      write('fortint    ');
      ifortchr:      write('fortchr    ');
      ifortbol:      write('fortbol    ');
      ifordint:      write('fordint    ');
      ifordchr:      write('fordchr    ');
      ifordbol:      write('fordbol    ');
      iforend:       write('forend     ');
      iwthbgn:       write('wthbgn     ');
      iwthend:       write('wthend     ');
      igoto:         write('goto       ');
      iprcbgn:       write('prcbgn     ');
      iprccal:       write('prccal     ');
      iprccali:      write('prccali    ');
      ifncbgn:       write('fncbgn     ');
      ifnccal:       write('fnccal     ');
      ifnccali:      write('fnccali    ');
      iwrtsrc:       write('wrtsrc     ');
      iwrtintt:      write('wrtintt    ');
      iwrtchrt:      write('wrtchrt    ');
      iwrtbolt:      write('wrtbolt    ');
      iwrtrelt:      write('wrtrelt    ');
      iwrtstrt:      write('wrtstrt    ');
      iwrtgstt:      write('wrtgstt    ');
      iwrtintft:     write('wrtintft   ');
      iwrtchrft:     write('wrtchrft   ');
      iwrtbolft:     write('wrtbolft   ');
      iwrtrelft:     write('wrtrelft   ');
      iwrtstrft:     write('wrtstrft   ');
      iwrtgstft:     write('wrtgstft   ');
      iwrtrelfft:    write('wrtrelfft  ');
      iwrtsrl:       write('wrtsrl     ');
      iwrtrel:       write('wrtrel     ');
      iwrtset:       write('wrtset     ');
      iwrtbol:       write('wrtbol     ');
      iwrtchr:       write('wrtchr     ');
      iwrtint:       write('wrtint     ');
      iwrteolt:      write('wrteolt    ');
      iredsrc:       write('redsrc     ');
      iredintt:      write('redintt    ');
      iredchrt:      write('redchrt    ');
      iredrelt:      write('redrelt    ');
      iredsrlt:      write('redsrlt    ');
      iredeolt:      write('redeolt    ');
      iabsrel:       write('absrel     ');
      iabsint:       write('absint     ');
      isqrrel:       write('sqrrl      ');
      isqrint:       write('sqrint     ');
      iatnrel:       write('atnrel     ');
      icosrel:       write('cosrel     ');
      iexprel:       write('exprel     ');
      ilgnrel:       write('lgnrel     ');
      isinrel:       write('sinrel     ');
      isqtrel:       write('sqtrel     ');
      ieolt:         write('eolt       ');
      ieof:          write('eof        ');
      iodd:          write('odd        ');
      isucint:       write('sucint     ');
      iprdint:       write('prdint     ');
      irnd:          write('rnd        ');
      itrc:          write('trc        ');
      iexist:        write('exist      ');
      ilen:          write('len        ');
      iloc:          write('loc        ');
      iget:          write('get        ');
      igett:         write('gett       ');
      iput:          write('put        ');
      ilodafbuf:     write('lodafbuf   ');
      ilodafbuft:    write('lodafbuft  ');
      ireset:        write('reset      ');
      irewrite:      write('rewrite    ');
      iclose:        write('close      ');
      ipack:         write('pack       ');
      iunpack:       write('unpack     ');
      ipaget:        write('paget      ');
      iassign:       write('assign     ');
      ipos:          write('pos        ');
      idel:          write('del        ');
      ichg:          write('chg        ');
      istiint:       write('stiint     ');
      istisrl:       write('stisrl     ');
      istirel:       write('stirel     ');
      istichr:       write('stichr     ');
      istibol:       write('stibol     ');
      istiset:       write('stiset     ');
      istisrc:       write('stisrc     ');
      istigar:       write('stigar     ');
      istitgp:       write('stitgp     ');
      istifint:      write('stifint    ');
      istiftgp:      write('stiftgp    ');
      istifsrl:      write('stifsrl    ');
      istifrel:      write('stifrel    ');
      istifchr:      write('stifchr    ');
      istifbol:      write('stifbol    ');
      inew:          write('new        ');
      idisp:         write('disp       ');
      itag:          write('tag        ');
      iendtag:       write('endtag     ');
      ipoptop:       write('poptop     ');
      ilabequ:       write('labequ     ');
      irngchk:       write('rngchk     ');
      inewgar:       write('newgar     ');
      idspgar:       write('dspgar     ');
      ihalt:         write('halt       ');
      iendfil:       write('endfil     ');
      icvtrtsr:      write('cvtrtsr    ');
      isetlin:       write('setlin     ');
      isetsrc:       write('setsrc     ');
      iupdate:       write('update     ');
      icasels:       write('casels     ');
      ilint:         write('lint       ');
      icard:         write('card       ');
      ilcard:        write('lcard      ');
      iappend:       write('append     ');
      isemaphore:    write('semaphore  ');
      isignal:       write('signal     ');
      isignalone:    write('signalone  ');
      iwait:         write('wait       ');
      itrybgn:       write('trybgn     ');
      itryexp:       write('tryexp     ');
      itryexpspc:    write('tryexpspc  ');
      itryexpspcbgn: write('tryexpspcbgn');
      itryend:       write('tryend     ');
      ithrow:        write('throw      ');
      iassert:       write('assert     ');
      icassrng:      write('cassrng    ');
      iextmod:       write('extmod     ');
      iprccalo:      write('prccalo    ');
      ifnccalo:      write('fnccalo    ');
      iclass:        write('class      ');
      iatom:         write('atom       ');
      ithread:       write('thread     ');
      ireference:    write('reference  ');
      iexception:    write('exception  ');
      iobjmem:       write('objmem     ');
      iis:           write('is         ');
      istiref:       write('stiref     ');
      icvtntr:       write('cvtntr     ');
      iequref:       write('equref     ');
      ineqref:       write('newref     ');
      ildiref:       write('ldiref     ');
      ilodasr:       write('lodasr     ');
      inewobj:       write('newobj     ');
      idspobj:       write('dspobj     ');
      iprcmcal:      write('prcmcal    ');
      ifncmcal:      write('fncmcal    ');
      iprcmcalo:     write('prcmcalo   ');
      ifncmcalo:     write('fncmcalo   ');
      ilodawc:       write('lodawc     ');
      ildimgp:       write('ldimgp     ');
      iarfmar:       write('arfmar     ');
      icvtmtg:       write('cvtmtg     ');
      icvtftm:       write('cvtftm     ');
      icpymgp:       write('cpymgp     ');
      icpytgp:       write('cpytgp     ');

   end

end;

{******************************************************************************

Print intermediate entry

Prints a full intermediate entry. Expects the intermediate code, and expects
the intermerdiate code file to be positioned just after that.

******************************************************************************}

procedure prtimm(ic: intcod);

var b, bh, bl: byte;    { file byte holder }
    v:         integer; { integer value holder }
    uc:        integer; { unicode characters }

begin

   case ic of { intermediate code }

      ibgnlvl: begin

         write('Begin block, mark: ');
         getlnk;
         writeln;
         blkcnt := blkcnt+1; { count blocks }
         new(bp); { get a new block entry }
         bp^.cnt := 1; { set 1st entry number }
         bp^.next := blkstk; { push onto block stack }
         blkstk := bp

      end;
      iendlvl: begin

         writeln('End block');
         if blkcnt <= 0 then begin

            writeln('*** Block underflow');
            abort

         end;
         blkcnt := blkcnt-1; { remove block count }
         blkstk := blkstk^.next { pop top entry }

      end;
      ibgnpgm:  writeln('Program/procedure/function code block');
      iendpgm:  writeln('Program/procedure/function code block end');
      ibgnext:  writeln('Module exit code block');
      iendext:  writeln('Module exit code block end');
      iusefil: writeln('Uses file string (undefined)');
      inil:    writeln('''nil'' universal pointer type');
      ilab:    writeln('''goto'' label type');
      iicst:   begin

         rdnum(v); { get integer parameter }
         writeln('Integer constant type, value: ', v:1)

      end;
      iscst:   begin

         write('String constant type, value: ');
         getstr; { get string }
         writeln

      end;
      iccst:   begin

         read(intfil, bh); { get unicode character constant }
         read(intfil, bl);
         uc := bh*256+bl;
         write('Character constant type, value: ''');
         wrtchr(uc);
         writeln('''')

      end;
      ircst:   begin

         rdreal(r); { get real parameter }
         writeln('Real constant type, value: ', r)

      end;
      istcst:  begin

         write('Set constant, base type: ');
         getlnk;
         write(' list: ');
         getlnk;
         writeln

      end;
      istet:   begin

         write('Set constant entry, next: ');
         getlnk;
         rdnum(v);
         write(' start value: ', v:1);
         rdnum(v);
         write(' end value: ', v:1, ' head: ');
         getlnk;
         writeln

      end;
      iarrcst: begin

         write('Array constant, list: ');
         getlnk;
         writeln

      end;
      iarrcel: begin

         write('Array constant element, next: ');
         getlnk;
         write(' constant link: ');
         getlnk;
         writeln

      end;
      ireccst: begin

         write('Record constant, list: ');
         getlnk;
         writeln

      end;
      ireccel: begin

         write('Record constant element, next: ');
         getlnk;
         write(' constant link: ');
         getlnk;
         writeln

      end;
      ienum:   begin

         write('Enumerated type, list: ');
         getlnk;
         writeln

      end;
      ienme:   begin

         write('Enumerated constant type, next entry: ');
         getlnk;
         write(' head: ');
         getlnk;
         rdnum(v); { get value }
         writeln(' value: ', v:1)

      end;
      isub:    begin

         write('Subrange type, base type: ');
         getlnk;
         rdnum(v); { get lower bound }
         write(' lower bound: ', v:1);
         rdnum(v); { get upper bound }
         writeln(' upper bound: ', v:1)

      end;
      iptr:    begin

         write('Pointer type, base: ');
         getlnk;
         writeln

      end;
      iarray:  begin

         write('Array type, base: ');
         getlnk;
         write(' index: ');
         getlnk;
         writeln

      end;
      igarry:  begin

         write('General array type, base: ');
         getlnk;
         writeln

      end;
      ifile:   begin

         write('File type, base: ');
         getlnk;
         writeln

      end;
      iset:    begin

         write('Set type, base: ');
         getlnk;
         writeln

      end;
      irecord: begin

         write('Record type, field list: ');
         getlnk;
         writeln

      end;
      ifield:  begin

         write('Record field type, next: ');
         getlnk;
         write(' head: ');
         getlnk;
         write(' base: ');
         getlnk;
         writeln

      end;
      iftag:   begin

         write('Record tag field type, case list: ');
         getlnk;
         write(' head: ');
         getlnk;
         write(' base: ');
         getlnk;
         read(intfil, b); { get exists flag }
         writeln(' exists: ', b <> 0:0)

      end;
      ifcas:   begin

         write('Record case constant type, next case: ');
         getlnk;
         write(' field list: ');
         getlnk;
         rdnum(v); { get case constant low }
         write(' case constant low: ', v:1);
         rdnum(v); { get case constant high }
         writeln(' case constant high: ', v:1)

      end;
      ivar:    begin

         write('Variable type, base: ');
         getlnk;
         read(intfil, b); { get external flag }
         write(' external: ', b <> 0:0);
         rdnum(v); { get module ordinal }
         write(' module ordinal number: ', v:1);
         write(' class type: ');
         getlnk;
         writeln

      end;
      ifix:    begin

         write('fixed type, base: ');
         getlnk;
         write(' constant fill: ');
         getlnk;
         read(intfil, b); { get external flag }
         writeln(' external: ', b <> 0:0);
         rdnum(v); { get module ordinal }
         write(' module ordinal number: ', v:1)

      end;
      iproc:   begin

         write('Procedure type, parameter list: ');
         getlnk;
         read(intfil, b); { get external flag }
         write(' external: ', b <> 0:0);
         rdnum(v); { get module ordinal }
         write(' module ordinal number: ', v:1);
         read(intfil, b); { get assembly flag }
         write(' assembly: ', b <> 0:0);
         write(' overload head: ');
         getlnk;
         read(intfil, b); { get static flag }
         write(' static: ', b <> 0:0);
         read(intfil, b); { get virtual flag }
         write(' virtual: ', b <> 0:0);
         write(' overrider link: ');
         getlnk;
         write(' override head: ');
         getlnk;
         write(' class type: ');
         getlnk;
         writeln

      end;
      ifunc:   begin

         write('Function type, parameter list: ');
         getlnk;
         write(' function result: ');
         getlnk;
         read(intfil, b); { get external flag }
         write(' external: ', b <> 0:0);
         rdnum(v); { get module ordinal }
         write(' module ordinal number: ', v:1);
         read(intfil, b); { get assembly flag }
         write(' assembly: ', b <> 0:0);
         write(' overload head: ');
         getlnk;
         read(intfil, b); { get static flag }
         write(' static: ', b <> 0:0);
         read(intfil, b); { get virtual flag }
         write(' virtual: ', b <> 0:0);
         write(' overrider link: ');
         getlnk;
         write(' override head: ');
         getlnk;
         write(' class type: ');
         getlnk;
         writeln

      end;
      ipar:    begin

         write('Parameter type, next parameter: ');
         getlnk;
         write(' base: ');
         getlnk;
         write(' head: ');
         getlnk;
         writeln

      end;
      ivpar:   begin

         write('Variable parameter type, next parameter: ');
         getlnk;
         write(' base: ');
         getlnk;
         write(' head: ');
         getlnk;
         writeln

      end;
      iwpar:   begin

         write('View parameter type, next parameter: ');
         getlnk;
         write(' base: ');
         getlnk;
         write(' head: ');
         getlnk;
         writeln

      end;
      ipproc:  begin

         write('Procedure parameter type, parameter list: ');
         getlnk;
         write(' next parameter: ');
         getlnk;
         writeln

      end;
      ipfunc:  begin

         write('Function parameter type, parameter list: ');
         getlnk;
         write(' function result: ');
         getlnk;
         write(' next parameter: ');
         getlnk;
         writeln

      end;
      iint:    writeln('Integer type');
      ilint:   writeln('long Integer type');
      icard:   writeln('cardinal type');
      ilcard:  writeln('long cardinal type');
      ichar:   writeln('Character type');
      iboolean: begin

         write('Boolean type, enumerated constants: ');
         getlnk;
         writeln

      end;
      ireal:   writeln('Real type');
      isreal:  writeln('Short real type');
      itext:   writeln('Text file type');
      isemaphore: writeln('Semaphore type');
      iexception: writeln('Exception type');
      ieset:   writeln('Empty set type');
      iglbl:   begin

         write('Global mark, type: ');
         read(intfil, b);
         if b > 5 then begin { invalid code }

            writeln('*** Invalid intermediate file');
            abort

         end;
         case b of { type }

            0: write('System');
            1: write('Program');
            2: write('Module');
            3: write('Process');
            4: write('Monitor');
            5: write('Share')

         end;
         writeln

      end;
      inull:   ; { we don't print placeholders, to keep listing clean }
      isym:    begin

         write('Symbol: ');
         getstr;
         write(' type: ');
         getlnk;
         read(intfil, b);
         write(' export: ', b <> 0:0);
         writeln

      end;
      issym:    begin

         write('Simple symbol: ');
         getstr;
         writeln

      end;
      ilodadr:   begin

         write('Load address operator, type: ');
         getlnk;
         writeln

      end;
      ilodfadr:  begin

         write('Load address function result operator, type: ');
         getlnk;
         writeln

      end;
      iarrref:  begin

         write('Array reference operator, array type: ');
         getlnk;
         writeln

      end;
      iarfgar:  begin

         write('General array reference operator, array type: ');
         getlnk;
         writeln

      end;
      irecoff:     begin

         write('Record offset operator, field type: ');
         getlnk;
         writeln

      end;
      ildiint:  begin

         write('Load indirect integer operator, type: ');
         getlnk;
         writeln

      end;
      ildirel:   writeln('Load indirect real operator');
      ildisrl:  writeln('Load indirect short real operator');
      ildiset:  writeln('Load indirect set operator');
      ildichr:  writeln('Load indirect character operator');
      ildibol:  writeln('Load indirect boolean operator');
      ildisrc:  begin

         write('Load indirect structure operator, type: ');
         getlnk;
         writeln

      end;
      ildiptr:  writeln('Load indirect pointer');
      ilditgp:  writeln('Load indirect tagged pointer');
      ilimint: begin

         rdnum(v); { get integer parameter }
         writeln('Load immediate integer operator, value: ', v:1)

      end;
      ilimrel:    begin

         rdreal(r); { get real parameter }
         writeln('Load immediate real operator, value: ', r)

      end;
      ilimns:  writeln('Load immediate empty set operator');
      ilodlen:  begin

         write('Load general array length, array type: ');
         getlnk;
         writeln

      end;
      ilodlenl:  begin

         write('Load general array length at level, array type: ');
         getlnk;
         writeln

      end;
      inotint:  writeln('Integer ''not'' operator');
      inotbol:  writeln('Boolean ''not'' operator');
      isinset:  writeln('Set single element operator');
      irngset:  writeln('Set range operator');
      icvtitr:  writeln('Convert integer to real operator');
      icvtrtsr: writeln('Convert real to short real');
      icvtgtf:  begin

         write('Convert tagged pointer to fixed, fixed type: ');
         getlnk;
         writeln

      end;
      icvtftg:  begin

         write('Convert fixed pointer to tagged, fixed type: ');
         getlnk;
         writeln

      end;
      icvtntg:  writeln('Convert nil to tagged format operator');
      iswptop:  begin

         write('Swap top and second stack operator, source: ');
         getlnk;
         write(' destination: ');
         getlnk;
         writeln

      end;
      iintset:  writeln('Set intersection operator');
      imltrel:   writeln('Multiply real operator');
      imltint:  writeln('Multiply integer operator');
      idivrel:   writeln('Divide real operator');
      idivint:  writeln('Divide integer operator');
      imodint:  writeln('Modulo integer operator');
      iandint:  writeln('Integer ''and'' operator');
      inegint:  writeln('Negate integer');
      inegrel:   writeln('Negate real');
      iuniset:  writeln('Set union operator');
      iaddrel:   writeln('Add real operator');
      iaddint:  writeln('Add integer operator');
      idifset:  writeln('Set difference');
      isubrel:   writeln('Subtract real operator');
      isubint:  writeln('Subtract integer operator');
      iorint:   writeln('Integer ''or'' operator');
      ixorint:  writeln('Integer ''xor'' operator');
      iincset:   writeln('Set inclusion operator');
      iequset:  writeln('Set equal operator');
      iequrel:   writeln('Real equal operator');
      iequstr:  begin

         write('String equal operator, type: ');
         getlnk;
         writeln

      end;
      iequgst:  writeln('General string equal operator');
      iequint:  writeln('Integer equal operator');
      iequtgp:  writeln('Tagged pointer equal operator');
      ineqset:  writeln('Set not equal operator');
      ineqrel:   writeln('Real not equal operator');
      ineqstr:  begin

         write('String not equal operator, type: ');
         getlnk;
         writeln

      end;
      ineqgst:  writeln('General string not equal operator');
      ineqint:  writeln('Integer not equal operator');
      ineqtgp:  writeln('Tagged pointer not equal operator');
      ileqset:  writeln('Set less than or equal operator');
      ileqrel:   writeln('Real less than or equal operator');
      ileqstr:  begin

         write('String less than or equal operator, type: ');
         getlnk;
         writeln

      end;
      ileqgst:  writeln('General string less than or equal operator');
      ileqint:  writeln('Integer less than or equal operator');
      igeqset:  writeln('Set greater than or equal operator');
      igeqrel:   writeln('Real greater than or equal operator');
      igeqstr:  begin

         write('String greater than or equal operator, type: ');
         getlnk;
         writeln

      end;
      igeqgst:  writeln('General string greater than or equal operator');
      igeqint:  writeln('Integer greater than or equal operator');
      iltnrel:   writeln('Real less than operator');
      iltnstr:  begin

         write('String less than operator, type: ');
         getlnk;
         writeln

      end;
      iltngst:  writeln('General string less than operator');
      iltnint:  writeln('Integer less than operator');
      igtnrel:   writeln('Real greater than operator');
      igtnstr:  begin

         write('String greater than operator, type: ');
         getlnk;
         writeln

      end;
      igtngst:  writeln('General string greater than operator');
      igtnint:  writeln('Integer greater than operator');
      ibgnblk:  writeln('begin statement block operator');
      iendblk:  writeln('end statement block operator');
      iifbgn:   writeln('If begin operator');
      iifend:   writeln('If end operator');
      ielse:    writeln('Else operator');
      icasbgn:  writeln('Case begin operator');
      icasend:  writeln('Case end operator');
      icassint: begin

         rdnum(v); { get integer parameter }
         writeln('Case integer selector operator, value: ', v:1)

      end;
      icassrng: begin

         rdnum(v); { get start parameter }
         write('Case range selector operator, start: ', v:1);
         rdnum(v); { get end parameter }
         writeln(' end: ', v:1)

      end;
      icasstb:  writeln('Case statement begin');
      icasste:  writeln('Case statement end');
      icasels:  writeln('Case statement else');
      iwhlexp:  writeln('While expression marker operator');
      iwhlbgn:  writeln('While begin operator');
      iwhlend:  writeln('While end operator');
      irptbgn:  writeln('Repeat begin operator');
      irptend:  writeln('Repeat end operator');
      ifortint: begin

         write('For begin ''to'' integer operator, variable type: ');
         getlnk; { print variable }
         writeln

      end;
      ifortchr: begin

         write('For begin ''to'' character operator, variable type: ');
         getlnk; { print variable }
         writeln

      end;
      ifortbol: begin

         write('For begin ''to'' boolean operator, variable type: ');
         getlnk; { print variable }
         writeln

      end;
      ifordint: begin

         write('For begin ''downto'' integer operator, variable type: ');
         getlnk; { print variable }
         writeln

      end;
      ifordchr: begin

         write('For begin ''downto'' character operator, variable type: ');
         getlnk; { print variable }
         writeln

      end;
      ifordbol: begin

         write('For begin ''downto'' boolean operator, variable type: ');
         getlnk; { print variable }
         writeln

      end;
      iforend:  writeln('For end operator');
      iwthbgn:  begin

         write('With begin operator, record type: ');
         getlnk;
         writeln

      end;
      iwthend:  writeln('With end operator');
      igoto:    begin

         write('Goto operator, label type: ');
         getlnk;
         writeln

      end;
      itrybgn:  writeln('Try begin operator');
      itryexp:  writeln('Try except operator');
      itryexpspc: writeln('Try except specific operator');
      itryexpspcbgn: writeln('Try except specific begin operator');
      itryend:  writeln('Try end operator');
      iprcbgn:  writeln('Procedure parameter begin operator');
      iprccal:   begin

         write('Procedure call operator, head type: ');
         getlnk;
         writeln

      end;
      iprccali:  begin

         write('Procedure call indirect operator, head type: ');
         getlnk;
         writeln

      end;
      ifncbgn:   writeln('Function parameter begin operator');
      ifnccal:   begin

         write('Function call operator, head type: ');
         getlnk;
         writeln

      end;
      ifnccali:  begin

         write('Function call indirect operator, head type: ');
         getlnk;
         writeln

      end;
      iwrtsrc:   begin

         write('Write structure operator, type: ');
         getlnk;
         writeln

      end;
      iwrtintt:   writeln('Write text integer operator');
      iwrtchrt:   writeln('Write text character operator');
      iwrtbolt:   writeln('Write text boolean operator');
      iwrtrelt:   writeln('Write text real operator');
      iwrtstrt:   begin

         write('Write text string operator, type: ');
         getlnk;
         writeln

      end;
      iwrtgstt:   writeln('Write text general string operator');
      iwrtintft:  writeln('Write text integer fielded operator');
      iwrtchrft:  writeln('Write text character fielded operator');
      iwrtbolft:  writeln('Write text boolean fielded operator');
      iwrtrelft:  writeln('Write text real fielded operator');
      iwrtstrft:  begin

         write('Write text string fielded operator');
         getlnk;
         writeln

      end;
      iwrtgstft:  writeln('Write text general string fielded operator');
      iwrtrelfft: writeln('Write real fielded and fractioned operator');
      iwrtsrl:  writeln('Write file short real');
      iwrtrel:  writeln('Write file real');
      iwrtset:  writeln('Write file set');
      iwrtbol:  writeln('Write file boolean operator');
      iwrtchr:  writeln('Write file character operator');
      iwrtint:  begin

         write('Write file integer: ');
         getlnk; { get type }
         writeln

      end;
      iwrteolt:  writeln('Write text end of line');
      iredsrc:   begin

         write('Read structure operator, type: ');
         getlnk; { get type }
         writeln

      end;
      iredintt:  begin

         write('Read text integer operator, type: ');
         getlnk;
         writeln

      end;
      iredchrt:  writeln('Read text character operator');
      iredsrlt:  writeln('Read text short real operator');
      iredrelt:  writeln('Read text real operator');
      iredeolt:  writeln('Read text end of line');
      iabsrel:   writeln('Abs of real operator');
      iabsint:   writeln('Abs of integer operator');
      isqrrel:   writeln('Sqr of real operator');
      isqrint:   writeln('Sqr of integer operator');
      iatnrel:   writeln('Arctan of real operator');
      icosrel:   writeln('Cos of real operator');
      iexprel:   writeln('Exp of real operator');
      ilgnrel:   writeln('ln of real operator');
      isinrel:   writeln('Sin of real operator');
      isqtrel:   writeln('Sqrt of real operator');
      ieolt:     writeln('Eoln of file operator');
      ieof:      begin

         write('Eof of file operator, file type: ');
         getlnk;
         writeln

      end;
      iodd:      writeln('Odd of integer operator');
      isucint:   writeln('Succ of integer operator');
      iprdint:   writeln('Pred of integer operator');
      irnd:      writeln('Round operator');
      itrc:      writeln('Trunc operator');
      iexist:    writeln('File exists operator');
      ilen:      writeln('File length operator');
      iloc:      writeln('File location operator');
      iget:      writeln('File get operator');
      igett:     writeln('Text file get operator');
      iput:      writeln('File put operator');
      ilodafbuf: writeln('load address of file buffer');
      ilodafbuft: writeln('load address of text file buffer');
      ireset:    begin

         write('File reset operator, file type: ');
         getlnk;
         writeln

      end;
      irewrite:  begin

         write('File rewrite operator, file type: ');
         getlnk;
         writeln

      end;
      iupdate:   begin

         write('File update operator, file type: ');
         getlnk;
         writeln

      end;
      iappend:   begin

         write('File append operator, file type: ');
         getlnk;
         writeln

      end;
      iclose:    writeln('File close operator');
      ipack:     begin

         write('Pack operator, packed type: ');
         getlnk;
         write(' unpacked type: ');
         getlnk;
         writeln

      end;
      iunpack:   begin

         write('Unpack operator, unpacked type: ');
         getlnk;
         write(' packed type: ');
         getlnk;
         writeln

      end;
      ipaget:    writeln('Page text operator');
      iassign:   writeln('Assign file operator');
      ipos:      writeln('Position file operator');
      idel:      writeln('Delete file operator');
      ichg:      writeln('Change file operator');
      isignal:    writeln('Signal operator');
      isignalone: writeln('Signal one operator');
      iwait:      writeln('Wait operator');
      ithrow:     writeln('Throw operator');
      iassert:     writeln('Assert operator');
      istiint:     begin

         write('Store indirect integer operator, variable type: ');
         getlnk;
         writeln

      end;
      istisrl:   begin

         write('Store indirect short real operator, variable type: ');
         getlnk;
         writeln

      end;
      istirel:    begin

         write('Store indirect real operator, variable type: ');
         getlnk;
         writeln

      end;
      istichr:   begin

         write('Store indirect character operator, variable type: ');
         getlnk;
         writeln

      end;
      istibol:   begin

         write('Store indirect boolean operator, variable type: ');
         getlnk;
         writeln

      end;
      istiset:   begin

         write('Store indirect set operator, variable type: ');
         getlnk;
         writeln

      end;
      istisrc:      begin

         write('Store indirect structure operator, variable type: ');
         getlnk;
         writeln

      end;
      istigar:   begin

         write('Store indirect general array operator, variable type: ');
         getlnk;
         writeln

      end;
      istitgp:   begin

         write('Store indirect tagged pointer operator, variable type: ');
         getlnk;
         writeln

      end;
      istifint:    begin

         write('Store indirect function result integer operator, function type: ');
         getlnk;
         writeln

      end;
      istiftgp:  begin

         write('Store indirect function result tagged pointer operator, function type: ');
         getlnk;
         writeln

      end;
      istifsrl:  begin

         write('Store indirect function result short real operator, function ');
         write('type: ');
         getlnk;
         writeln

      end;
      istifrel:   begin

         write('Store indirect function result real operator, function type: ');
         getlnk;
         writeln

      end;
      istifchr:  begin

         write('Store indirect function result character operator, function type: ');
         getlnk;
         writeln

      end;
      istifbol:  begin

         write('Store indirect function result boolean operator, function type: ');
         getlnk;
         writeln

      end;
      inew:      begin

         write('New operator, type: ');
         getlnk;
         writeln

      end;
      idisp:     begin

         write('Dispose operator, type: ');
         getlnk;
         writeln

      end;
      itag:      begin

         rdnum(v); { get integer parameter }
         writeln('Tagfield constant operator, value: ', v:1)

      end;
      iendtag:   writeln('End of tagfields operator');
      ipoptop:   begin

         write('Remove top of stack, operand: ');
         getlnk;
         writeln

      end;
      ilabequ:   begin

         write('''goto'' label equation marker, entry: ');
         getlnk;
         writeln

      end;
      irngchk:   begin

         write('Range check, type: ');
         getlnk;
         writeln

      end;
      inewgar:   begin

         write('Allocate general array, type: ');
         getlnk;
         writeln

      end;
      idspgar:   begin

         write('Dispose general array, type: ');
         getlnk;
         writeln

      end;
      ihalt:     writeln('Halt operator');
      isetlin:   begin

         rdnum(v); { get integer parameter }
         if fsrclin then begin { print out source lines }

            { read forward till we find the current line }
            while srclin < v do begin

               reads(srcfil, srcbuf); { get next line }
               readln(srcfil);
               srclin := srclin+1 { count lines }

            end;
            { print the source line }
            writeln(srcbuf:0)

         end else writeln('Set current line: ', v:1);

      end;
      isetsrc:   begin

         getstr(cursrc); { get the current source file name }
         if fsrclin then begin { open new source file }

            if srcopn then begin

               close(srcfil); { if open, close the last file }
               srcopn := false { set source file not open }

            end;
            if len(cursrc) > 0 then begin

               { not a null source marker }
               assign(srcfil, cursrc); { open new file }
               reset(srcfil);
               srcopn := true; { set source file open }
               srclin := 0; { current source line }
               { find file module name }
               brknam(cursrc, p, srcmod, e)

            end

         end else writeln('Set current source file: ''', cursrc:0, '''')

      end;
      iextmod:   begin

         write('Module definition, module name: ');
         getstr;
         write(' file: ');
         getstr;
         writeln

      end;
      iprccalo:   begin

         write('Inherited procedure call operator, head type: ');
         getlnk;
         writeln

      end;
      ifnccalo:   begin

         write('Inherited function call operator, head type: ');
         getlnk;
         writeln

      end;
      iclass:     begin

         write('Class type, base class: ');
         getlnk;
         writeln

      end;
      iatom:      begin

         writeln('Atom type');
         getlnk;
         writeln

      end;
      ithread:    begin

         writeln('Thread type');
         getlnk;
         writeln

      end;
      ireference: begin

         write('Reference type, base: ');
         getlnk;
         writeln

      end;
      iobjmem:    begin

         write('Object member selection, class type: ');
         getlnk;
         write(' member: ');
         getlnk;
         writeln

      end;
      iis:        begin

         write('''is'' operator, class type: ');
         getlnk;
         writeln

      end;
      istiref:   begin

         write('Store indirect reference operator, source variable type: ');
         getlnk;
         write(' destination variable type: ');
         getlnk;
         writeln

      end;
      icvtntr:  writeln('Convert nil to reference operator');
      iequref:  writeln('Reference equal operator');
      ineqref:  writeln('Reference not equal operator');
      ildiref:  writeln('Load indirect reference');
      ilodasr:   begin

         write('Load address of class self reference operator, type: ');
         getlnk;
         writeln

      end;
      inewobj:   begin

         write('Create new object, reference type: ');
         getlnk;
         writeln

      end;
      idspobj:   begin

         write('Dispose of object, reference type: ');
         getlnk;
         writeln

      end;
      iprcmcal:   begin

         write('Procedure method call operator, head type: ');
         getlnk;
         writeln

      end;
      ifncmcal:   begin

         write('Function method call operator, head type: ');
         getlnk;
         writeln

      end;
      iprcmcalo:   begin

         write('Inherited method procedure call operator, head type: ');
         getlnk;
         writeln

      end;
      ifncmcalo:   begin

         write('Inherited method function call operator, head type: ');
         getlnk;
         writeln

      end;
      ilodawc:   begin

         write('Load address of ''with'' class member, class type: ');
         getlnk;
         write(' member: ');
         getlnk;
         writeln

      end;
      ildimgp:  writeln('Load indirect complex tagged pointer');
      iarfmar:  begin

         write('Complex general array reference operator, array type: ');
         getlnk;
         writeln

      end;
      icvtmtg:  writeln('Convert complex to simple tagged format operator');
      icvtftm:  begin

         write('Convert fixed pointer to complex tagged, fixed type: ');
         getlnk;
         writeln

      end;
      icpymgp:  begin

         write('Copy complex general array and replace pointer, base type: ');
         getlnk;
         writeln

      end;
      icpytgp:  begin

         write('Copy simple general array and replace pointer, base type: ');
         getlnk;
         writeln

      end;

      iendfil: ; { do nothing }

   end

end;

begin

   writeln;
   write('Compiler intermediate file dumper vs. 1.14.0001 Copyright (C) 1994 ');
   writeln('S. A. Moore');
   writeln;

   blkcnt := 0; { clear block counter }
   blkstk := nil; { clear block entry stack }
   spccnt := 0; { set no indentation }
   intcnt := 0; { clear intermediate tolken counter }
   fsrclin := false; { list source lines }
   fsrcsup := false; { suppress source line markers }
   srcopn := false; { set source file not open }
   clears(srcmod); { clear source filename }

   getcmd(cmdlin); { load command line }
   parcmd; { parse command line }
   if isext(intnam) then begin { extention exists }

      if not exists(intnam) then begin { no file }

         writeln('*** File does not exist');
         abort

      end

   end else begin { no extention, try our own }

      addext(intnam, 'opt', true); { search for file.opt first }
      if not exists(intnam) then begin { not found }

         addext(intnam, 'int', true); { search for file.int }
         if not exists(intnam) then begin { no such file }

            writeln('*** File does not exist!!!');
            abort

         end

      end

   end;
   assign(intfil, intnam); { open intermediate file }
   reset(intfil);
   write('Dump of intermediate file: ');
   for fi := 1 to maxfil do if intnam[fi] <> ' ' then write(intnam[fi]);
   writeln;
   writeln;
   writeln('Filename   Line  Intc   lvl Code/Source');
   writeln('---------------------------------------');
   { check signature exists on file }
   read(intfil, b);
   if b <> ord('S') then begin

      writeln('*** Invalid intermediate file signature');
      abort

   end;
   read(intfil, b);
   if b <> ord('P') then begin

      writeln('*** Invalid intermediate file signature');
      abort

   end;
   read(intfil, b);
   if b <> ord('K') then begin

      writeln('*** Invalid intermediate file signature');
      abort

   end;
   read(intfil, b);
   if b <> ord('A') then begin

      writeln('*** Invalid intermediate file signature');
      abort

   end;
   repeat { read file tolkens }

      { get 16 bit tolken as big endian }
      read(intfil, b); { get next code }
      ib := b*256; { set intermediate code byte high }
      read(intfil, b);
      ib := ib+b; { set intermediate code byte low }
      if ib >= ord(iendcod) then begin { invalid code }

         writeln;
         writeln('*** Invalid intermediate code encountered: ', ib);
         abort

      end;
      intcnt := intcnt+1; { count tolken }
      ic := intcod(ib); { convert to intermediate code }
      { check is a printing code }
      codprt := (ic <> inull) and ((ic <> isetsrc) or not fsrclin); { don't print placeholders }
      { if supress source line markers is on, turn them off }
      { handle things that decrement the indentation }
      if (ic = iendlvl) or (ic = iendpgm) or (ic = iendext) or (ic = iendblk) or
         (ic = iifend) or (ic = icasend) or (ic = iwhlend) or (ic = irptend) or
         (ic = iforend) or (ic = iwthend) or (ic = itryend) then
         spccnt := spccnt-1;
      { process indentation }
      if codprt then begin { process line header }

         write(srcmod: 10, ' ', srclin:5, ' ', intcnt:6, ' ', blkcnt:2, ': '); { output block level count }
         if (ic <> isetlin) or not fsrclin then 
            for i := 1 to spccnt do write(' '); { indent }

      end;
      { handle things that increment the indentation }
      if (ic = ibgnlvl) or (ic = ibgnpgm) or (ic = ibgnext) or (ic = ibgnblk) or
         (ic = iifbgn) or (ic = icasbgn) or (ic = iwhlbgn) or (ic = irptbgn) or
         (ic = ifortint) or (ic = ifortchr) or (ic = ifortbol) or
         (ic = ifordint) or (ic = ifordchr) or (ic = ifordbol) or
         (ic = iwthbgn) or (ic = itrybgn) then
         spccnt := spccnt+1;
      if (ic = isetlin) and fsrclin then write('S: ')
      else if codprt then prtcod(ic); { print the intermediate code }
      { check it is a type entry }
      if ((ic >= inil) and (ic <= inull)) or (ic = issym) or
         ((ic >= ilint) and (ic <= ilcard)) or (ic = isemaphore) or
         (ic = iclass) or (ic = iatom) or (ic = ithread) or
         (ic = ireference) then begin

         { if it's an embedded record symbol, this is just a follow on to the
           last entry, so we blank the address and don't count it }
         if ic = issym then write('^^^^^^^^ ')
         else begin

            { in types section, at not at end marker, print block relative
              address of coming entry }
            if ic <> inull then { not at a placeholder }
               write('(', blkcnt:2, ',', blkstk^.cnt:3, ') ');
            blkstk^.cnt := blkstk^.cnt+1 { count type entries }

         end

      end;
      { print the intermediate }
      prtimm(ic)

   until ic = iendfil; { end of file tolken }
   close(intfil); { close intermediate file }
   writeln;
   writeln('Function complete');

   99: { terminate program }

end.
