{******************************************************************************
*                                                                             *
* SCANNER MODULE                                                              *
*                                                                             *
* Scans IP Pascal tolkens from a file and returns them. Does nothing with     *
* "uses" files, and has no error recovery.                                    *
* The scanner module is a general purpose version of the scanner built in to  *
* the general compiler. It is usefull for program analisis tasks, such as     *
* symbols/crossreference generators, and convertion tasks, such as a          *
* prettyprinter.                                                              *
* The scanner buffers up its input in terms of lines. This is required        *
* because some of the tolkens require backtracking to recognise.              *
* No ANSI status is recognized. The scanner allways works in full IP mode.    *
*                                                                             *
* There are two calls for the scanner module:                                 *
*                                                                             *
* iniscn(var f: text);                                                        *
*                                                                             *
* Initalizes the scanner and reads the first line from the input file. The    *
* caller may check if the file is null (eof) before the call.                 *
*                                                                             *
* gettlk(var f: text);                                                        *
*                                                                             *
* Gets the next tolken from the input, and places that in the next tolken     *
* buffers, as follows:                                                        *
*                                                                             *
* nxttlk                                                                      *
*                                                                             *
* Returns the next tolken code. This is one of the tolkens from the "tolken"  *
* type.                                                                       *
*                                                                             *
* nxtlab                                                                      *
*                                                                             *
* Returns the next label, if the tolken is a symbol, or the next string,      *
* if the next tolken is a string. Strings have their enclosing quotes         *
* removed.                                                                    *
* Other tolkens will also have their equivalent forms placed in the nxtlab    *
* buffer, including integers and reals.                                       *
*                                                                             *
* nxtlen                                                                      *
*                                                                             *
* Returns the length of a string for a string tolken.                         *
*                                                                             *
* nxtint                                                                      *
*                                                                             *
* Returns an integer if the next tolken is an integer.                        *
*                                                                             *
* nxtflt                                                                      *
*                                                                             *
* Returns a floating point if the next tolken is a real.                      *
*                                                                             *
******************************************************************************}

module scanner(output);

uses stddef,
     strlib;

const

maxstr = 200; { maximum length of string/symbol }

type

{ scanner input tolkens }
tolken = (cundefined,  { undefined (must be first tolken) }
          cplus,       { + }
          cminus,      { - }
          ctimes,      { * }
          crdiv,       { / }
          cequ,        { = }
          cnequ,       { <> }
          cnequa,      { >< }
          cltn,        { < }
          cgtn,        { > }
          clequ,       { <= }
          clequa,      { =< }
          cgequ,       { >= }
          cgequa,      { => }
          clparen,     { ( }
          crparen,     { ) }
          clbrkt,      { [ }
          crbrkt,      { ] }
          clct,        { left comment }
          crct,        { right comment }
          cbcms,       { := }
          cperiod,     { . }
          ccma,        { , }
          cscn,        { ; }
          ccln,        { : }
          ccmf,        { ^ }
          crange,      { .. }
          cdiv,        { div }
          cmod,        { mod }
          cnil,        { nil }
          cin,         { in }
          cor,         { or }
          cand,        { and }
          cxor,        { xor }
          cnot,        { not }
          cif,         { if }
          cthen,       { then }
          celse,       { else }
          ccase,       { case }
          cof,         { of }
          crepeat,     { repeat }
          cuntil,      { until }
          cwhile,      { while }
          cdo,         { do }
          cfor,        { for }
          cto,         { to }
          cdownto,     { downto }
          cbegin,      { begin }
          cend,        { end }
          cwith,       { with }
          cgoto,       { goto }
          cconst,      { const }
          cvar,        { var }
          ctype,       { type }
          carray,      { array }
          crecord,     { record }
          cset,        { set }
          cfile,       { file }
          cfunction,   { function }
          cprocedure,  { procedure }
          clabel,      { label }
          cpacked,     { packed }
          cprogram,    { program }
          cforward,    { forward }
          cmodule,     { module }
          cuses,       { uses }
          cprivate,    { private }
          cexternal,   { external }
          cview,       { view }
          cfixed,      { fixed }
          cprocess,    { process }
          cmonitor,    { monitor }
          cshare,      { share }
          cclass,      { class }
          cconstruct,  { construct }
          cdestruct,   { destruct }
          cis,         { is }
          catom,       { atom }
          cinteger,    { unsigned integer constant }
          cidentifier, { identifier }
          cstring,     { string constant }
          creal,       { real constant }
          ceof);       { end of file (must be last tolken) }

procedure iniscn(var f: text); forward;
procedure gettlk(var f: text); forward;

var

{ this block of variables gives the results from the scanner. nxttlk returns
  the classification code, and the other buffers give the actual contents of
  the tolkens }
   nxttlk: tolken;  { next tolken }
   nxtlab: packed array [1..maxstr] of char; { next label/string }
   nxtlen: integer; { next length of string }
   nxtint: integer; { next integer }
   nxtflt: real;    { next real }

private

const

maxlin  = 200; { maximum size of input line }
chrmax  = 37;  { number of special character sequences
                 (plus padding) }
resmax  = 61;  { number of reserved words (plus padding) }
spcmax  = 2;   { special character string length }
maxexp  = 308; { maximum exponent of real }
hashoff = 3;   { hash function offset }
chroff  = 20;  { special character hash offset }

type

chrinx = 1..chrmax; { special character index }
chrstr = packed array [1..spcmax] of char; { special character string }
chrequ = record { special character table entry }

            lab:  chrstr;   { characters }
            tolk: tolken;   { equivalent tolken }
            chn:  0..chrmax { next entry chain }

         end;
resinx = 1..resmax; { index for reserved table }
resequ = record { reserved word table entry }

            lab:  pstring;     { reserved word }
            tolk: tolken;   { equivalent tolken }
            chn:  0..resmax { chain to next entry }

         end;
labinx = 1..maxstr; { index for label }

var

linbuf: packed array [1..maxlin] of char; { input line buffer }
linptr: integer; { index for line }
spctbl: array [chrinx] of chrequ; { special character table }
restbl: array [resinx] of resequ; { reserved words table }
deftbl: array [tolken] of pstring; { tolken definition strings }

{******************************************************************************

Find label hash function

Finds a hash function for the given label. The maximum specifies the maximum
value desired from the hash generator. The return value will be between
1 and the max. The "add" parameter is a "stirring" parameter that just changes
the hash value to a different set of values. This is used to optimize fixed
tables, done using an external generator program. See the program for details,
but the basic idea is that we will find an add that gives the optimum set of
hash values for a fixed set of labels.
Note that for dynamic tables, the add parameter can be left to 0.

******************************************************************************}

function hash(view s:    string;  { label to find hash for }
                   add:  integer; { stirring parameter }
                   maxv: integer) { maximum value returned }
             : integer;          { return hash }

var i, r : integer;

begin

   r := 0;
   for i := 1 to max(s) do
      if s[i] <> ' ' then r := r + ord(lcase(s[i])) + add;
   hash := r mod maxv + 1

end;

{******************************************************************************

Get next input line

Gets a single line from the given file.

******************************************************************************}

procedure getlin(var f: text); { file to read from }

var ovf: boolean; { overflow flag }

begin

   if not eof(f) then begin { not at file end }

      readsp(f, linbuf, ovf); { get next line }
      readln(f);
      if ovf then begin { overflow }

         writeln('*** Error: input line too large');
         halt

      end;
      linptr := 1 { reset line pointer }

   end;
{;if not eof(f) then begin
;writesp(output, linbuf);
;writeln;
;end;}

end;

{******************************************************************************

Check end of line

Simply checks if the input position is beyond the current end of line.

******************************************************************************}

function endlin: boolean;

begin

   endlin := linptr > maxlin

end;

{******************************************************************************

Check eof

Checks if the end of the input buffer and the source file has been reached.

******************************************************************************}

function seof(var f: text): boolean;

begin

  { true eof is the end of line, and end of file } 
  seof := endlin and eof(f)

end;

{******************************************************************************

Check next input character

The next character in the input buffer is returned. No advance is made from the
current position (succesive calls to this procedure will yeild the same
character).

******************************************************************************}

function chkchr: char; { current input character }

var c: char; { result }

begin

   if endlin then c := ' ' { just return endless spaces }
   { else return the next character at the input pointer }
   else c := linbuf[linptr];
   chkchr := c { return result }

end;

{******************************************************************************

Skip input character

Causes the current input character to be skipped, so that the next chkchr call
will return the next character. If we are at the end of the line, no action
will take place (will not advance beyond end of line).

******************************************************************************}

procedure getchr;

begin

   if linptr <= maxlin then { process advance }
      linptr := linptr+1 { advance one character }

end;

{******************************************************************************

Skip input spaces or controls

Skips the input position past any spaces or controls. Will skip the end of
line, loading the next line from the input. The view of the input is for each
line to be terminated by an infinite series of blanks, which only this routine
will cross.

******************************************************************************}

procedure skpspc(var f: text); { file to pull lines from }

begin

  repeat

     { skip any spaces }
     while (chkchr <= ' ') and not endlin do getchr;
     if endlin then getlin(f) { get a new line }

   until seof(f) or (chkchr <> ' ') { eof or non-space }

end;                  

{******************************************************************************

Recognize control memnonic

Attempts to recognize a control memnonic at the present position. If found, the
equivalent control character is returned, else just returns space. The input
position is left past the sequence.

******************************************************************************}

procedure conchr(var c: char);

var s:   packed array [1..4] of char;  { holding cell }
    r:   0..1020;                      { hash calculator holding (4*c) }
    chn: 0..34;                        { index of control characters }
    i:   1..4;                         { index for cell }
    ips: array [1..4] of integer;   { line pointer saves }

procedure lookup; { attempt lookup of memnonic }

var i: 1..4; { index for cell }

begin

   { find hash }
   r := 0;
   for i := 1 to 4 do r := r + ord(s[i]);
   chn := r mod 35 + 1;
   c := ' '; { set none found }
   while (c = ' ') and (chn <> 0) do case chn of { hash index }

      21: begin if s = 'nul\00'   then c := chr(0);   chn := 0  end;
      16: begin if s = 'soh\00'   then c := chr(1);   chn := 15 end;
      2:  begin if s = 'stx\00'   then c := chr(2);   chn := 0  end;
      23: begin if s = 'etx\00'   then c := chr(3);   chn := 33 end;
      14: begin if s = 'eot\00'   then c := chr(4);   chn := 0  end;
      10: begin if s = 'enq\00'   then c := chr(5);   chn := 0  end;
      24: begin if s = 'ack\00'   then c := chr(6);   chn := 0  end;
      28: begin if s = 'bel\00'   then c := chr(7);   chn := 0  end;
      4:  begin if s = 'bs\00\00' then c := chr(8);   chn := 3  end;
      11: begin if s = 'ht\00\00' then c := chr(9);   chn := 12 end;
      1:  begin if s = 'lf\00\00' then c := chr(10);  chn := 18 end;
      25: begin if s = 'vt\00\00' then c := chr(11);  chn := 0  end;
      30: begin if s = 'ff\00\00' then c := chr(12);  chn := 29 end;
      3:  begin if s = 'cr\00\00' then c := chr(13);  chn := 13 end;
      17: begin if s = 'so\00\00' then c := chr(14);  chn := 0  end;
      12: begin if s = 'si\00\00' then c := chr(15);  chn := 0  end;
      29: begin if s = 'dle\00'   then c := chr(16);  chn := 34 end;
      13: begin if s = 'dc1\00'   then c := chr(17);  chn := 0  end;
      27: begin if s = 'xon\00'   then c := chr(17);  chn := 26 end;
      5:  begin if s = 'dc2\00'   then c := chr(18);  chn := 0  end;
      6:  begin if s = 'dc3\00'   then c := chr(19);  chn := 0  end;
      15: begin if s = 'xoff'     then c := chr(19);  chn := 31 end;
      7:  begin if s = 'dc4\00'   then c := chr(20);  chn := 0  end;
      35: begin if s = 'nak\00'   then c := chr(21);  chn := 0  end;
      32: begin if s = 'syn\00'   then c := chr(22);  chn := 0  end;
      18: begin if s = 'etb\00'   then c := chr(23);  chn := 19 end;
      26: begin if s = 'can\00'   then c := chr(24);  chn := 0  end;
      22: begin if s = 'em\00\00' then c := chr(25);  chn := 0  end;
      31: begin if s = 'sub\00'   then c := chr(26);  chn := 0  end;
      19: begin if s = 'esc\00'   then c := chr(27);  chn := 22 end;
      8:  begin if s = 'fs\00\00' then c := chr(28);  chn := 0  end;
      9:  begin if s = 'gs\00\00' then c := chr(29);  chn := 0  end;
      20: begin if s = 'rs\00\00' then c := chr(30);  chn := 0  end;
      33: begin if s = 'us\00\00' then c := chr(31);  chn := 0  end;
      34: begin if s = 'del\00'   then c := chr(127); chn := 0  end

   end

end;

begin

   { load cell }
   for i := 1 to 4 do begin

      ips[i] := linptr; { save input at that }
      { insure we aren't fooled by \00 }
      if chkchr = '\00' then s[i] := '?'
      else s[i] := chkchr;
      getchr

   end;
   lookup; { try 4 characters }
   if c = ' ' then begin

      s[4] := '\00'; { knock out character }
      lookup; { try 3 characters }
      if c = ' ' then begin

         s[3] := '\00'; { knock out character }
         lookup; { try 2 characters }
         if c <> ' ' then linptr := ips[3] { restore to that }

      end else linptr := ips[4] { restore to that }

   end;
   if c = ' ' then linptr := ips[1] { if not found, restore position }

end;

{******************************************************************************

Parse and convert numeric

Parses and converts the following:

     [radix specification] ['0'..'9', 'a'..'z', 'A'..'Z']...

Where the radix specifier is:

     % - Binary
     & - Octal
     $ - hexadecimal
     none - Decimal

Using the given radix, any digits are processed to yeild a word unsigned
result. Leading spaces are skipped. Overflow is checked and flagged as an
error. Overflowing exponents is also checked. No spaces are allowed anywhere in
the format. If the real flag is set, when a '.' or 'e' is encountered, the
integer will be promoted to a floating point value. Whether or not any further
indicator characters are to be looked for is required since this routine can be
used inside a string.
Note that in case of a parsing error, the rest of the number is skipped (as
possible), and a zero is returned.
Note that the overflow check can be bypassed by the 'nooverflow' option. The
purpose of this is to allow bootstrapping to a larger word size. For instance,
if we design a back end coder that generates a larger word size for integer,
then we may recode all compiler modules to use that new size. We must then
compile a parser without overflow checks, so that a new parser can be compiled
with larger overflow checking.

******************************************************************************}

procedure parnum(var f:          text;     { file to read from }
                     searchreal: boolean); { real number search flag }

var cs:   integer;  { save for command line pointer }
    c:    char;
    r:    1..16;   { radix }
    v:    0..36;   { integer value holder, enough for 10+(a-z) }
    rm:   boolean; { radix mark encountered flag }
    exp:  integer; { exponent of real }
    sgn:  integer; { sign holder }
    zero: boolean; { number consists of zeros }
    p:    real;    { power }
    outb: packed array [1..maxstr] of char; { output buffer }
    outi: integer; { output buffer index }

{ find power of ten effciently }

function pwrten(e: integer): real;

var t: real; { accumulator }
    p: real; { current power }

begin

   p := 1.0e+1; { set 1st power }
   t := 1.0; { initalize result }
   repeat 

      if odd(e) then t := t*p; { if bit set, add this power }
      e := e div 2; { index next bit }
      p := sqr(p) { find next power }

   until e = 0;
   pwrten := t

end;

{ move character to output buffer }

procedure getchrb;

begin

   outb[outi] := chkchr; { place character in buffer }
   outi := outi+1; { next character }
   getchr { and get that }

end;

begin

   outi := 1; { index 1st output character }
   clears(outb); { clear buffer }
   skpspc(f); { skip spaces }
   rm := false; { set no radix mark }
   r := 10; { set default radix decimal}
   exp := 0; { clear real exponent }
   nxtint := 0; { initalize result }
   { check binary }
   if chkchr = '%' then { binary }
      begin r := 2; rm := true; getchrb end
   { check octal }
   else if chkchr = '&' then { octal }
      begin r := 8; rm := true; getchrb end
   { check hexadecimal }
   else if chkchr = '$' then { hexadecimal }
      begin r := 16; rm := true; getchrb end;
   if not (((chkchr in ['0'..'9', 'a'..'z', 'A'..'Z']) and (r = 16)) or
           (chkchr in ['0'..'9'])) then begin

      writeln('*** Error: invalid digit');
      halt

   end;
   while (((chkchr in ['a'..'z', 'A'..'Z']) and (r = 16)) or
      (chkchr in ['0'..'9'])) do begin { parse digits }

         { count significant digits to exponent (used on real only) }
         if (chkchr <> '0') or (exp <> 0) then exp := exp+1;
         { convert '0'..'9' }
         if (chkchr in ['0'..'9']) then v := ord(chkchr) - ord('0')
         else v := ord(lcase(chkchr)) - ord('a') + 10; { convert 'a'..'z' }
         if v >= r then begin { does not fit radix }

            writeln('*** Error: digit beyond radix');
            halt

         end else begin { ok }

            { check for overflow }
            if ((nxtint > maxint div r) or 
               ((nxtint = maxint div r) and (v > maxint mod r))) then begin

               writeln('*** Error: numeric overflow');
               halt

            end else nxtint := nxtint * r + v { scale and add in }

         end;
         getchrb { next }

   end;
   if exp <> 0 then exp := exp - 1; { adjust exponent }
   nxttlk := cinteger; { place type }
   if searchreal then begin { search for real specification }

      nxtflt := nxtint; { move integer to real }
      if chkchr = '.' then begin { decimal point }

         { the '.' could be a '..', in which case it's really
           <integer>.. we must back up in this case }
         cs := linptr; { save command pointer }
         getchrb; { skip '.' }
         if chkchr = '.' then linptr := cs { back up }
         else begin { is a decimal point }

            zero := nxtint = 0; { check number is zero (so far) }
            if rm then begin

               writeln('*** Error: invalid real format');
               halt

            end;
            if not (chkchr in ['0'..'9']) then begin

               writeln('*** Error: invalid real format');
               halt

            end;
            p := 1.0; { initalize power }
            while chkchr in ['0'..'9']  do begin { parse digits }

               if zero then exp := exp-1; { adjust the 'virtual exponent' }
               if chkchr <> '0' then zero := false; { set leading digit found }
               p := p / 10.0; { find next scale }
               { add and scale new digit }
               nxtflt := nxtflt + (p * (ord(chkchr) - ord('0')));
               getchrb { next }

            end;
            nxttlk := creal { place tolken }

         end

      end;
      if lcase(chkchr) = 'e' then begin { exponent }

         getchrb; { skip 'e' }
         sgn := 1; { set sign of exponent }
         c := chkchr; { check next }
         if c = '-' then sgn := -sgn; { set negative }
         if (c = '+') or (c = '-') then getchrb; { skip sign }
         if not (chkchr in ['0'..'9']) then begin

            writeln('*** Error: invalid real format');
            halt

         end else begin

            parnum(f, false); { parse integer only }
            if (nxtint > maxexp) or (abs(sgn*nxtint+exp) > maxexp) then begin

               { exponent too large }
               writeln('*** Error: exponent too large');
               halt

            end;
            { find with exponent }
            if c = '-' then nxtflt := nxtflt / pwrten(nxtint)
            else nxtflt := nxtflt * pwrten(nxtint)

         end;
         nxttlk := creal { place tolken }

      end

   end;
   copyp(nxtlab, outb) { place number as parsed }

end;

{******************************************************************************

Parse string

Parses and returns an input string. A string is any characters between single
quotes on a line. A double quote sequence within a string denotes a single
quote character. A '\' character introduces a force sequence as:

   \<memnonic>  - an ascii memonic denoting the control
                  character desired (as '\cr', etc.).

   \<number>    - the ascii value of the character
                  desired (with prefixes '$', '&' and
                  '%' possible).

   \<character> - all others just force the given character,
                  including '\'' for quote.

Since a string is as big as the input line, no overflow errors are required.
The one error consists of a missing quote.

******************************************************************************}

procedure parstr(var f: text); { file to read from }

label 1; { exit label }

var c: char;

begin

   nxtlen := 0; { null string }
   skpspc(f); { skip leading spaces }
   { the following will never happen }
   if chkchr <> '''' then begin

      writeln('*** Error: no leading quote');
      halt

   end;
   getchr; { skip }
   while linptr < maxlin do begin { process string }

      c := chkchr; { check next }
      if c = '\\'  then begin { control sequence }

         getchr; { skip }
         c := chkchr; { next }
         if c in ['$', '&', '%', '0'..'9'] then begin

            { process numeric force }
            parnum(f, false); { parse numeric (rejecting reals) }
            if nxtint > 255 then begin

               writeln('*** Error: string force number greater than 255');
               halt

            end else c := chr(nxtint) { place character }

         end else begin

            conchr(c); { get possible control character }
            if c = ' ' then begin

               c := chkchr; { not found, is a force }
               getchr { skip }

            end

         end

      end else if c = '''' then begin { found a quote }

         getchr; { skip }
         c := chkchr;
         if c <> '''' then goto 1; { was an exit quote }
         getchr { skip }

      end else getchr; { skip }
      nxtlen := nxtlen + 1; { add to length }
      nxtlab[nxtlen] := c { place character }

   end;
   writeln('*** Unterminated string');
   halt;
   1: { terminate }
   nxttlk := cstring { place tolken }

end;

{******************************************************************************

Parse label/reserved word

Parses a label, which is:

    '_'/'a'..'z' ['_', '0'..'9', 'a'..'z']...

After parsing, the label is checked against the reserved list, and returned as
a reserved tolken if so.

******************************************************************************}

procedure parlabr;

var i:  0..maxstr; { index for label }
    ri: 0..resmax; { index for reserved table }

begin

   for i := 1 to maxstr do nxtlab[i] := ' '; { clear label buffer }
   i := 0; { clear index }
   while chkchr in ['_', '0'..'9', 'a'..'z', 'A'..'Z'] do begin

      { parse label characters }
      if i <> maxstr then begin { label not full }

         i := i + 1; { next character }
         nxtlab[i] := chkchr { place character }

      end;
      getchr { skip }

   end;
   ri := hash(nxtlab, hashoff, resmax); { find initial hash function }
   if compp(nxtlab, restbl[ri].lab^) then { found 1st try }
      nxttlk := restbl[ri].tolk
   else begin { search chained }

      { traverse chains searching }
      while (restbl[ri].chn <> 0) and 
            not compp(nxtlab, restbl[ri].lab^) do ri := restbl[ri].chn;
      if compp(nxtlab, restbl[ri].lab^) then { found }
         nxttlk := restbl[ri].tolk
      else nxttlk := cidentifier { place tolken is identifier }

   end

end;

{******************************************************************************

Parse special character sequence

Parses a 1 or 2 character special sequence. These are arbitrary characters,
with any kind of termination.

******************************************************************************}

procedure parchr;

var hold: chrstr; { holding cell }
    i:    labinx; { index for label }

{ Find hash function }

function hash(s: chrstr; add: integer; max: integer): integer;

var i, r : integer;

begin

   r := 0;
   for i := 1 to spcmax do
      if s[i] <> ' ' then r := r + ord(s[i]) + add;
   hash := r mod max + 1

end;

{ search label }

procedure search;

var ci: chrinx; { index for special character table }

begin

   ci := hash(hold, chroff, chrmax); { find initial hash function }
   if hold = spctbl[ci].lab then { found 1st try }
      nxttlk := spctbl[ci].tolk
   else begin { search chained }

      { traverse chains searching }
      while (spctbl[ci].chn <> 0) and 
            not (hold = spctbl[ci].lab) do ci := spctbl[ci].chn;
      if hold = spctbl[ci].lab then { found }
         nxttlk := spctbl[ci].tolk
      else nxttlk := cundefined { set not found }

   end

end;

begin

   hold[1] := chkchr; { place 1st character }
   getchr; { skip }
   hold[2] := chkchr; { place 2nd character }
   for i := 1 to maxstr do nxtlab[i] := ' '; { set up label for errors }
   nxtlab[1] := hold[1];
   nxtlab[2] := hold[2];
   search; { try that }
   if nxttlk <> cundefined then begin { found }

      { found 2 character sequence, or perhaps single with
        a trailing space. It really makes no difference,
        but we don't skip the space to give more accurate
        error pointers. }
      if hold[2] <> ' ' then getchr

   end else begin { search single characters }

      hold[2] := ' '; { knock out 2nd character }
      nxtlab[2] := ' ';
      search; { try that }
      if nxttlk = cundefined then begin

         writeln('*** Error: invalid symbol/character');
         halt

      end

   end

end;

{******************************************************************************

Parse tolken

Parses the following tolken types:

   1. String constants.
   2. Numeric constants.
   3. Reserved words.
   4. Specical character sequences.
   5. Indentifiers.
   6. Option lines.

******************************************************************************}

procedure partlk(var f: text); { file to read from }

begin

   skpspc(f); { skip spaces }
   if seof(f) then nxttlk := ceof { eof }
   else begin

      if chkchr = '''' then
         parstr(f) { string }
      else if chkchr in ['_', 'A'..'Z', 'a'..'z'] then
         parlabr { label }
      else if chkchr in ['0'..'9', '&', '%', '$'] then
         parnum(f, true) { numeric }
      else
         parchr { special character sequence }

   end

end;

{******************************************************************************

Get next tolken

Parses the next tolken in line, and places the tolken code and any data in the
next buffers. Removes the error suppression on the parser.

******************************************************************************}

procedure gettlk(var f: text); { file to read from }

var ts: tolken; { tolken save }
    c:  char;   { holding }
    i:  labinx; { index for string }

begin

   repeat

      partlk(f); { parse tolken }
      ts := nxttlk; { save tolken }
      if nxttlk = clct then begin { comment }

         repeat

            c := chkchr; { check next }
            while (c <> '}') and (c <> '*') and not seof(f) do begin

               getchr; { skip characters }
               c := chkchr { check next }

            end;
            getchr { skip comment char }

         until (c = '}') or ((c = '*') and (chkchr = ')')) or seof(f);
         if c = '*' then getchr; { skip ')' }
         if seof(f) then begin
  
            writeln('*** Error: unterminated comment');
            halt

         end

      end

   until ts <> clct; { not comment }

   { the following is a diagnostic to print the next tolken }

   if true then begin

      write('*');	
      if nxttlk in [clct, crct, cinteger, cidentifier, cstring, 
                    creal, cundefined, ceof] then
         case nxttlk of { special tolken }
   
         clct:        write('left comment');
         crct:        write('right comment');
         cinteger:    write('unsigned integer constant: ', nxtint);
         cidentifier: begin write('identifier: '); 
                            writesp(output, nxtlab) end;
         cstring:     begin write('string constant: '); 
                            for i := 1 to nxtlen do write(nxtlab[i]) end;
         creal:       write('real constant: ', nxtflt);
         cundefined:  write('undefined');
         ceof:        write('end of file');
   
      end else write(output, deftbl[nxttlk]^);
      writeln('*')

   end

end;

{******************************************************************************

Initalize scanner

Initalizes the special character and reserved word tables, then loads the first
line from the input file.

******************************************************************************}

procedure iniscn(var f: text);

var ci: chrinx;
    ri: resinx;
    li: labinx;

begin

   { initalize special character sequence table }

   for ci := 1 to chrmax do 
     with spctbl[ci] do begin { initalize all table }
  
      lab := '  ';
      tolk := cundefined;
      chn := 0

   end;

   spctbl[  1].lab  := '[ ';
   spctbl[  1].tolk := clbrkt;
   spctbl[  2].lab  := '><';
   spctbl[  2].tolk := cnequa;
   spctbl[  3].lab  := '] ';
   spctbl[  3].tolk := crbrkt;
   spctbl[  4].lab  := '^ ';
   spctbl[  4].tolk := ccmf;
   spctbl[  5].lab  := ': ';
   spctbl[  5].tolk := ccln;
   spctbl[  6].lab  := '; ';
   spctbl[  6].tolk := cscn;
   spctbl[  7].lab  := '< ';
   spctbl[  7].tolk := cltn;
   spctbl[  8].lab  := '= ';
   spctbl[  8].tolk := cequ;
   spctbl[  9].lab  := '> ';
   spctbl[  9].tolk := cgtn;
   spctbl[ 10].lab  := '=<';
   spctbl[ 10].tolk := clequa;
   spctbl[ 11].lab  := '@ ';
   spctbl[ 11].tolk := ccmf;
   spctbl[ 12].lab  := '(*'; spctbl[ 12].chn :=  20;
   spctbl[ 12].tolk := clct;
   spctbl[ 13].lab  := '*)';
   spctbl[ 13].tolk := crct;
   spctbl[ 14].lab  := '<='; spctbl[ 14].chn :=  10;
   spctbl[ 14].tolk := clequ;
   spctbl[ 15].lab  := '<>'; spctbl[ 15].chn :=   2;
   spctbl[ 15].tolk := cnequ;
   spctbl[ 16].lab  := '>='; spctbl[ 16].chn :=  18;
   spctbl[ 16].tolk := cgequ;
   spctbl[ 17].lab  := '.)';
   spctbl[ 17].tolk := crbrkt;
   spctbl[ 18].lab  := '=>'; spctbl[ 18].chn :=  19;
   spctbl[ 18].tolk := cgequa;
   spctbl[ 19].lab  := '(.';
   spctbl[ 19].tolk := clbrkt;
   spctbl[ 20].lab  := ':=';
   spctbl[ 20].tolk := cbcms;
   spctbl[ 22].lab  := '..';
   spctbl[ 22].tolk := crange;
   spctbl[ 24].lab  := '( ';
   spctbl[ 24].tolk := clparen;
   spctbl[ 25].lab  := ') ';
   spctbl[ 25].tolk := crparen;
   spctbl[ 26].lab  := '* ';
   spctbl[ 26].tolk := ctimes;
   spctbl[ 27].lab  := '+ ';
   spctbl[ 27].tolk := cplus;
   spctbl[ 28].lab  := ', ';
   spctbl[ 28].tolk := ccma;
   spctbl[ 29].lab  := '- ';
   spctbl[ 29].tolk := cminus;
   spctbl[ 30].lab  := '. ';
   spctbl[ 30].tolk := cperiod;
   spctbl[ 31].lab  := '/ ';
   spctbl[ 31].tolk := crdiv;
   spctbl[ 33].lab  := '{ ';
   spctbl[ 33].tolk := clct;
   spctbl[ 35].lab  := '} ';
   spctbl[ 35].tolk := crct;

   { initalize reserved word table. This table is automatically
     generated, see the "hashtab" program. }

   for ri := 1 to resmax do
     with restbl[ri] do begin { initalize all table }
  
      for li := 1 to maxstr do lab := nil;
      tolk := cundefined;
      chn := 0

   end;
   copysp(restbl[  1].lab,  'class');
   restbl[  1].tolk := cclass;
   copysp(restbl[  2].lab,  'file');
   restbl[  2].tolk := cfile;
   copysp(restbl[  3].lab,  'nil');
   restbl[  3].tolk := cnil;
   copysp(restbl[  4].lab,  'while');
   restbl[  4].tolk := cwhile;
   copysp(restbl[  5].lab,  'monitor');
   restbl[  5].tolk := cmonitor;
   copysp(restbl[  6].lab,  'repeat');    restbl[  6].chn :=   9;
   restbl[  6].tolk := crepeat;
   copysp(restbl[  7].lab,  'set');
   restbl[  7].tolk := cset;
   copysp(restbl[  8].lab,  'packed');
   restbl[  8].tolk := cpacked;
   copysp(restbl[  9].lab,  'program');
   restbl[  9].tolk := cprogram;
   copysp(restbl[ 10].lab,  'array');
   restbl[ 10].tolk := carray;
   copysp(restbl[ 11].lab,  'else');
   restbl[ 11].tolk := celse;
   copysp(restbl[ 12].lab,  'and');
   restbl[ 12].tolk := cand;
   copysp(restbl[ 13].lab,  'uses');
   restbl[ 13].tolk := cuses;
   copysp(restbl[ 14].lab,  'share');
   restbl[ 14].tolk := cshare;
   copysp(restbl[ 15].lab,  'downto');
   restbl[ 15].tolk := cdownto;
   copysp(restbl[ 16].lab,  'end');
   restbl[ 16].tolk := cend;
   copysp(restbl[ 17].lab,  'then');
   restbl[ 17].tolk := cthen;
   copysp(restbl[ 18].lab,  'const');
   restbl[ 18].tolk := cconst;
   copysp(restbl[ 19].lab,  'atom');
   restbl[ 19].tolk := catom;
   copysp(restbl[ 20].lab,  'construct'); restbl[ 20].chn :=  22;
   restbl[ 20].tolk := cconstruct;
   copysp(restbl[ 21].lab,  'procedure');
   restbl[ 21].tolk := cprocedure;
   copysp(restbl[ 22].lab,  'destruct');
   restbl[ 22].tolk := cdestruct;
   copysp(restbl[ 23].lab,  'until');
   restbl[ 23].tolk := cuntil;
   copysp(restbl[ 25].lab,  'mod');       restbl[ 25].chn :=   8;
   restbl[ 25].tolk := cmod;
   copysp(restbl[ 27].lab,  'goto');
   restbl[ 27].tolk := cgoto;
   copysp(restbl[ 28].lab,  'div');       restbl[ 28].chn :=   3;
   restbl[ 28].tolk := cdiv;
   copysp(restbl[ 29].lab,  'view');
   restbl[ 29].tolk := cview;
   copysp(restbl[ 30].lab,  'with');
   restbl[ 30].tolk := cwith;
   copysp(restbl[ 31].lab,  'if');
   restbl[ 31].tolk := cif;
   copysp(restbl[ 32].lab,  'for');
   restbl[ 32].tolk := cfor;
   copysp(restbl[ 34].lab,  'var');       restbl[ 34].chn :=  13;
   restbl[ 34].tolk := cvar;
   copysp(restbl[ 35].lab,  'do');
   restbl[ 35].tolk := cdo;
   copysp(restbl[ 36].lab,  'type');
   restbl[ 36].tolk := ctype;
   copysp(restbl[ 37].lab,  'of');        restbl[ 37].chn :=   7;
   restbl[ 37].tolk := cof;
   copysp(restbl[ 38].lab,  'external');
   restbl[ 38].tolk := cexternal;
   copysp(restbl[ 39].lab,  'in');
   restbl[ 39].tolk := cin;
   copysp(restbl[ 40].lab,  'label');
   restbl[ 40].tolk := clabel;
   copysp(restbl[ 41].lab,  'function');
   restbl[ 41].tolk := cfunction;
   copysp(restbl[ 42].lab,  'not');
   restbl[ 42].tolk := cnot;
   copysp(restbl[ 44].lab,  'is');
   restbl[ 44].tolk := cis;
   copysp(restbl[ 45].lab,  'begin');
   restbl[ 45].tolk := cbegin;
   copysp(restbl[ 47].lab,  'forward');
   restbl[ 47].tolk := cforward;
   copysp(restbl[ 48].lab,  'record');
   restbl[ 48].tolk := crecord;
   copysp(restbl[ 49].lab,  'or');        restbl[ 49].chn :=  20;
   restbl[ 49].tolk := cor;
   copysp(restbl[ 50].lab,  'xor');       restbl[ 50].chn :=   6;
   restbl[ 50].tolk := cxor;
   copysp(restbl[ 51].lab,  'to');
   restbl[ 51].tolk := cto;
   copysp(restbl[ 53].lab,  'private');
   restbl[ 53].tolk := cprivate;
   copysp(restbl[ 55].lab,  'module');
   restbl[ 55].tolk := cmodule;
   copysp(restbl[ 56].lab,  'fixed');
   restbl[ 56].tolk := cfixed;
   copysp(restbl[ 57].lab,  'process');
   restbl[ 57].tolk := cprocess;
   copysp(restbl[ 59].lab,  'case');      restbl[ 59].chn :=  14;
   restbl[ 59].tolk := ccase;

   { definitions table.
     This table is used to translate tolkens back to 
     ASCII. It is used for diagnostics and spelling correction }

   copysp(deftbl[cplus],       '+');
   copysp(deftbl[cminus],      '-');
   copysp(deftbl[ctimes],      '*');
   copysp(deftbl[crdiv],       '/');
   copysp(deftbl[cequ],        '=');
   copysp(deftbl[cnequ],       '<>');
   copysp(deftbl[cnequa],      '><');
   copysp(deftbl[cltn],        '<');
   copysp(deftbl[cgtn],        '>');
   copysp(deftbl[clequ],       '<=');
   copysp(deftbl[clequa],      '=<');
   copysp(deftbl[cgequ],       '>=');
   copysp(deftbl[cgequa],      '=>');
   copysp(deftbl[clparen],     '(');
   copysp(deftbl[crparen],     ')');
   copysp(deftbl[clbrkt],      '[');
   copysp(deftbl[crbrkt],      ']');
   copysp(deftbl[clct],        '{');
   copysp(deftbl[crct],        '}');
   copysp(deftbl[cbcms],       ':=');
   copysp(deftbl[cperiod],     '.');
   copysp(deftbl[ccma],        ',');
   copysp(deftbl[cscn],        ';');
   copysp(deftbl[ccln],        ':');
   copysp(deftbl[ccmf],        '^');
   copysp(deftbl[crange],      '..');
   copysp(deftbl[cdiv],        'div');
   copysp(deftbl[cmod],        'mod');
   copysp(deftbl[cnil],        'nil');
   copysp(deftbl[cin],         'in');
   copysp(deftbl[cor],         'or');
   copysp(deftbl[cand],        'and');
   copysp(deftbl[cxor],        'xor');
   copysp(deftbl[cnot],        'not');
   copysp(deftbl[cif],         'if');
   copysp(deftbl[cthen],       'then');
   copysp(deftbl[celse],       'else');
   copysp(deftbl[ccase],       'case');
   copysp(deftbl[cof],         'of');
   copysp(deftbl[crepeat],     'repeat');
   copysp(deftbl[cuntil],      'until');
   copysp(deftbl[cwhile],      'while');
   copysp(deftbl[cdo],         'do');
   copysp(deftbl[cfor],        'for');
   copysp(deftbl[cto],         'to');
   copysp(deftbl[cdownto],     'downto');
   copysp(deftbl[cbegin],      'begin');
   copysp(deftbl[cend],        'end');
   copysp(deftbl[cwith],       'with');
   copysp(deftbl[cgoto],       'goto');
   copysp(deftbl[cconst],      'const');
   copysp(deftbl[cvar],        'var');
   copysp(deftbl[ctype],       'type');
   copysp(deftbl[carray],      'array');
   copysp(deftbl[crecord],     'record');
   copysp(deftbl[cset],        'set');
   copysp(deftbl[cfile],       'file');
   copysp(deftbl[cfunction],   'function');
   copysp(deftbl[cprocedure],  'procedure');
   copysp(deftbl[clabel],      'label');
   copysp(deftbl[cpacked],     'packed');
   copysp(deftbl[cprogram],    'program');
   copysp(deftbl[cforward],    'forward');
   copysp(deftbl[cmodule],     'module');
   copysp(deftbl[cuses],       'uses');
   copysp(deftbl[cprivate],    'private');
   copysp(deftbl[cexternal],   'external');
   copysp(deftbl[cview],       'view');
   copysp(deftbl[cfixed],      'fixed');
   copysp(deftbl[cprocess],    'process');
   copysp(deftbl[cmonitor],    'monitor');
   copysp(deftbl[cshare],      'share');
   copysp(deftbl[cclass],      'class');
   copysp(deftbl[cconstruct],  'construct');
   copysp(deftbl[cdestruct],   'destruct');
   copysp(deftbl[cis],         'is');
   copysp(deftbl[catom],       'atom');
   copysp(deftbl[cinteger],    '');
   copysp(deftbl[cidentifier], '');
   copysp(deftbl[cstring],     '');
   copysp(deftbl[creal],       '');
   copysp(deftbl[cundefined],  '');
   copysp(deftbl[ceof],        '');

   { get 1st line }

   getlin(f)

end;

begin
end.
