{*******************************************************************************
*                                                                              *
*                               SCANNER MODULE                                 *
*                                                                              *
*                              9/89 S. A. Moore                                *
*                                                                              *
* Handles scanning, or creation of a tolken stream, from the input files. Also *
* handles parser errors, and error recovery.                                   *
*                                                                              *
*******************************************************************************}

module scanner(output);

uses strings,  { string handling }
     xltlib,   { character transliteration }
     parsedef, { global definitions }
     common,   { global variables }
     parsesvs; { support module }

procedure gettlk; forward;
procedure skptlk(ss: tolkset); forward;
function mattlk(ts: tolkset): tolken; forward;
procedure corspell(t: tolken); forward;
procedure perror(e: errcod; s: tolkset; c: tolkset; view sp, sp2: string); 
   forward;
overload procedure perror(e: errcod; s: tolkset; c: tolkset; view sp: string); 
   forward;
overload procedure perror(e: errcod; s: tolkset; c: tolkset); forward;
procedure expect(t: tolken; e: errcod; s: tolkset; c: tolkset); forward;
function match(view a: string; view b: string): boolean; forward;
procedure chktkm(c: tolkset); forward;
procedure prttlk; forward;

private

{*******************************************************************************

Recognize control memnonic

Attempts to recognize a control memnonic at the present position. If found, the
equivalent control character is returned, else just returns space. The input
position is left past the sequence.

*******************************************************************************}

procedure conchr(var c: char);

var s:   packed array [1..4] of char;  { holding cell }
    se:  packed array [1..4] of char;  { holding cell encoded version }
    r:   0..1020;                      { hash calculator holding (4*c) }
    chn: 0..34;                        { index of control characters }
    i:   1..4;                         { index for cell }
    ips: array [1..4] of 0..linmax;    { pointer saves }

procedure lookup; { attempt lookup of memnonic }

var i: 1..4; { index for cell }

begin

   { find hash }
   r := 0;
   for i := 1 to 4 do r := r + chr2ascii(s[i]);
   chn := r mod 35 + 1;
   c := ' '; { set none found }
   while (c = ' ') and (chn <> 0) do case chn of { hash index }

      21: begin if se = 'nul\00'   then c := chr(0);   chn := 0  end;
      16: begin if se = 'soh\00'   then c := chr(1);   chn := 15 end;
      2:  begin if se = 'stx\00'   then c := chr(2);   chn := 0  end;
      23: begin if se = 'etx\00'   then c := chr(3);   chn := 33 end;
      14: begin if se = 'eot\00'   then c := chr(4);   chn := 0  end;
      10: begin if se = 'enq\00'   then c := chr(5);   chn := 0  end;
      24: begin if se = 'ack\00'   then c := chr(6);   chn := 0  end;
      28: begin if se = 'bel\00'   then c := chr(7);   chn := 0  end;
      4:  begin if se = 'bs\00\00' then c := chr(8);   chn := 3  end;
      11: begin if se = 'ht\00\00' then c := chr(9);   chn := 12 end;
      1:  begin if se = 'lf\00\00' then c := chr(10);  chn := 18 end;
      25: begin if se = 'vt\00\00' then c := chr(11);  chn := 0  end;
      30: begin if se = 'ff\00\00' then c := chr(12);  chn := 29 end;
      3:  begin if se = 'cr\00\00' then c := chr(13);  chn := 13 end;
      17: begin if se = 'so\00\00' then c := chr(14);  chn := 0  end;
      12: begin if se = 'si\00\00' then c := chr(15);  chn := 0  end;
      29: begin if se = 'dle\00'   then c := chr(16);  chn := 34 end;
      13: begin if se = 'dc1\00'   then c := chr(17);  chn := 0  end;
      27: begin if se = 'xon\00'   then c := chr(17);  chn := 26 end;
      5:  begin if se = 'dc2\00'   then c := chr(18);  chn := 0  end;
      6:  begin if se = 'dc3\00'   then c := chr(19);  chn := 0  end;
      15: begin if se = 'xoff'     then c := chr(19);  chn := 31 end;
      7:  begin if se = 'dc4\00'   then c := chr(20);  chn := 0  end;
      35: begin if se = 'nak\00'   then c := chr(21);  chn := 0  end;
      32: begin if se = 'syn\00'   then c := chr(22);  chn := 0  end;
      18: begin if se = 'etb\00'   then c := chr(23);  chn := 19 end;
      26: begin if se = 'can\00'   then c := chr(24);  chn := 0  end;
      22: begin if se = 'em\00\00' then c := chr(25);  chn := 0  end;
      31: begin if se = 'sub\00'   then c := chr(26);  chn := 0  end;
      19: begin if se = 'esc\00'   then c := chr(27);  chn := 22 end;
      8:  begin if se = 'fs\00\00' then c := chr(28);  chn := 0  end;
      9:  begin if se = 'gs\00\00' then c := chr(29);  chn := 0  end;
      20: begin if se = 'rs\00\00' then c := chr(30);  chn := 0  end;
      33: begin if se = 'us\00\00' then c := chr(31);  chn := 0  end;
      34: begin if se = 'del\00'   then c := chr(127); chn := 0  end

   end

end;

begin

   { load cell }
   for i := 1 to 4 do begin

      ips[i] := fllstk^.stk^.lptr; { save input at that }
      { insure we aren't fooled by \00 }
      if chkchr = '\00' then s[i] := '?'
      else s[i] := chkchr;
      getchr

   end;
   copy(se, s); { form encoded version }
   lcases(se); { find lower case }
   lookup; { try 4 characters }
   if c = ' ' then begin

      s[4] := '\00'; { knock out character }
      se[4] := '\00';
      lookup; { try 3 characters }
      if c = ' ' then begin

         s[3] := '\00'; { knock out character }
         se[3] := '\00';
         lookup; { try 2 characters }
         if c <> ' ' then fllstk^.stk^.lptr := ips[3] { restore to that }

      end else fllstk^.stk^.lptr := ips[4] { restore to that }

   end;
   if c = ' ' then fllstk^.stk^.lptr := ips[1] { if not found, restore position }

end;

{*******************************************************************************

Parse and convert numeric

Parses and converts the following:

     [radix specification] ['0'..'9', 'a'..'z', 'A'..'Z'. '_']...

Where the radix specifier is:

     % - Binary
     & - Octal
     $ - hexadecimal
     none - Decimal

Accepts a "break" character for separating digits, the '_' character.

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

*******************************************************************************}

procedure parnum(searchreal: boolean); { real number search flag }

var cs:   cmdinx;  { save for command line pointer }
    c:    char;
    r:    1..16;   { radix }
    v:    0..36;   { integer value holder, enough for 10+(a-z) }
    rm:   boolean; { radix mark encountered flag }
    e:    boolean; { error encounter flag }
    exp:  integer; { exponent of real }
    sgn:  integer; { sign holder }
    zero: boolean; { number consists of zeros }
    p:    real;    { power }

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

   pwrten := t { return result }

end;

begin

   skpspc; { skip spaces }
   e := false; { set no error encountered }
   rm := false; { set no radix mark }
   r := 10; { set default radix decimal}
   exp := 0; { clear real exponent }
   nxtint := 0; { initalize result }
   { check binary }
   if chkchr = '%' then { binary }
      begin r := 2; rm := true; getchr end
   { check octal }
   else if chkchr = '&' then { octal }
      begin r := 8; rm := true; getchr end
   { check hexadecimal }
   else if chkchr = '$' then { hexadecimal }
      begin r := 16; rm := true; getchr end;
   if not (((chkchr in ['0'..'9', 'a'..'z', 'A'..'Z']) and (r = 16)) or
           (chkchr in ['0'..'9'])) then
      begin error(enfmt, false); e := true end; { invalid digit }
   while ((chkchr in ['a'..'z', 'A'..'Z', '_']) and (r = 16)) or
         (chkchr in ['0'..'9', '_']) or
         (not fansi and (chkchr = '_')) do begin { parse digits }

      if chkchr <> '_' then begin { not break character }

         { count significant digits to exponent (used on real only) }
         if (chkchr <> '0') or (exp <> 0) then exp := exp+1;
         { convert '0'..'9' }
         if (chkchr in ['0'..'9']) then v := ord(chkchr) - ord('0')
         else v := ord(lcase(chkchr)) - ord('a') + 10; { convert 'a'..'z' }
         if v >= r then begin { does not fit radix }
        
            if not e then error(edbr, false); { output error }
            e := true { set error occured }
        
         end else begin { ok }
        
            { check for overflow }
            if ((nxtint > maxint div r) or 
               ((nxtint = maxint div r) and (v > maxint mod r))) and
               not fnovf then begin { overflows }
        
               if not e then error(enovf, false); { output error }
               e := true { set error occured }
        
            end else nxtint := nxtint * r + v { scale and add in }
        
         end

      end;
      getchr { next }

   end;
   if exp <> 0 then exp := exp - 1; { adjust exponent }
   nxttlk := cinteger; { place type }
   if searchreal then begin { search for real specification }

      nxtflt := nxtint; { move integer to real }
      if chkchr = '.' then begin { decimal point }

         { the '.' could be a '..' or '.)', in which case it's really
           <integer>.. or a alternate ']'. We must back up in this case }
         cs := fllstk^.stk^.lptr; { save command pointer }
         getchr; { skip '.' }
         if (chkchr = '.') or (chkchr = ')') then 
            fllstk^.stk^.lptr := cs { back up }
         else begin { is a decimal point }

            zero := nxtint = 0; { check number is zero (so far) }
            if rm then
               begin error(erfmt, false); e := true end; { error }
            if not (chkchr in ['0'..'9', '_']) then
               begin error(erfmt, false); e := true end; { error }
            p := 1.0; { initalize power }
            while (chkchr in ['0'..'9', '_']) and not e do begin 

               { parse digits }
               if chkchr <> '_' then begin { not a break character }

                  if zero then exp := exp-1; { adjust the 'virtual exponent' }
                  if chkchr <> '0' then 
                     zero := false; { set leading digit found }
                  p := p / 10.0; { find next scale }
                  { add and scale new digit }
                  nxtflt := nxtflt + (p * (ord(chkchr) - ord('0')))

               end;
               getchr { next }

            end;
            nxttlk := creal { place tolken }

         end

      end;
      if lcase(chkchr) = 'e' then begin { exponent }

         getchr; { skip 'e' }
         sgn := 1; { set sign of exponent }
         c := chkchr; { check next }
         if c = '-' then sgn := -sgn; { set negative }
         if (c = '+') or (c = '-') then getchr; { skip sign }
         if not (chkchr in ['0'..'9']) then
            begin error(erfmt, false); e := true end { error }
         else begin

            parnum(false); { parse integer only }
            if (nxtint > maxexp) or (abs(sgn*nxtint+exp) > maxexp) then begin

               { exponent too large }
               if not e then error(eexpovf, false); { output error }
               e := true

            end;
            { find with exponent }
            if c = '-' then nxtflt := nxtflt / pwrten(nxtint)
            else nxtflt := nxtflt * pwrten(nxtint)

         end;
         nxttlk := creal { place tolken }

      end

   end;
   { if there was an error, flush }
   if e then begin nxtint := 0; nxtflt := 0.0 end;
   { check label characters follow number, which is invalid }
   if chkchr in ['a'..'z', 'A'..'Z', '_'] then error(enfmtnz, false)

end;

{*******************************************************************************

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

The numeric forces are limited to a number of digits according to their radix:

Base      Digits
====================
decimal       3
hexadecimal   2
Octal         3
Binary        8

For ASCII/ISO 646. This will have to change for Unicode characters.

Note that only the digits that fit the radix are accepted. Any number is
terminated by a digit outside its radix.

Since a string is as big as the input line, no overflow errors are required.
The one error consists of a missing quote.

*******************************************************************************}

procedure parstr;

label 1; { exit label }

var i:  cmdinx;  { command index }
    cv: integer; { character value }
    c:  char;

procedure parnumlim;

var r:  1..16;   { radix }
    v:  0..36;   { integer value holder, enough for 10+(a-z) }
    e:  boolean; { error encounter flag }
    dl: integer; { digit limit }
    dc: integer; { digit counter }

begin

   skpspc; { skip spaces }
   e := false; { set no error encountered }
   r := 10; { set default radix decimal}
   dl := 3; { set digit limit }
   cv := 0; { initalize result }
   { check binary }
   if chkchr = '%' then begin r := 2; dl := 8; getchr end
   { check octal }
   else if chkchr = '&' then begin r := 8; dl := 3; getchr end
   { check hexadecimal }
   else if chkchr = '$' then begin r := 16; dl := 2; getchr end;
   if not (((chkchr in ['0'..'9', 'a'..'z', 'A'..'Z']) and (r = 16)) or
           (chkchr in ['0'..'9'])) then
      begin error(enfmt, false); e := true end; { invalid digit }
   dc := 1; { set on first digit }
   { Parse digits only as long as they fit the radix, and remain within the 
     number of digits. }
   while (((chkchr in ['0'..'9', 'a'..'f', 'A'..'F']) and (r = 16)) or
          ((chkchr in ['0'..'9']) and (r = 10)) or
          ((chkchr in ['0'..'7']) and (r = 8)) or
          ((chkchr in ['0'..'1']) and (r = 2))) and
          (dc <= dl) do begin { parse digits }

      { convert '0'..'9' }
      if (chkchr in ['0'..'9']) then v := ord(chkchr) - ord('0')
      else v := ord(lcase(chkchr)) - ord('a') + 10; { convert 'a'..'z' }
      if v >= r then begin { does not fit radix }

         if not e then error(edbr, false); { output error }
         e := true { set error occured }

      end else begin { ok }

         { check for overflow }
         if ((cv > maxint div r) or 
            ((cv = maxint div r) and (v > maxint mod r))) and
            not fnovf then begin { overflows }

            if not e then error(enovf, false); { output error }
            e := true { set error occured }

         end else cv := cv * r + v { scale and add in }

      end;
      getchr; { next }
      dc := dc+1 { count digits }

   end;
   { if there was an error, flush }
   if e then cv := 0

end;

begin

   nxtlen := 0; { null string }
   skpspc; { skip leading spaces }
   { the following will never happen }
   if chkchr <> '''' then error(emquo, false); { no leading quote }
   getchr; { skip }
   while not endlin do begin { process string }

      c := chkchr; { check next }
      if (c = '\\') and not fansi then begin { control sequence }

         getchr; { skip }
         c := chkchr; { next }
         if c in ['$', '&', '%', '0'..'9'] then begin

            { process numeric force }
            parnumlim; { parse numeric in limited digits }
            if cv > 255 then begin

               error(echrrng, false); { range error }
               c := chr(0) { replace with null }

            end else c := ascii2chr(cv) { place character }

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
   error(emquo, false); { no trailing quote (assume end) }
   i := fllstk^.stk^.lptr; { index position }
   while (i > 1) and (fllstk^.stk^.line[i] = ' ') do begin

      { strip trailing spaces off unterminated string }
      nxtlen := nxtlen - 1;
      i := i - 1

   end;
   1: { terminate }
   nxttlk := cstring; { place tolken }
   if (nxtlen = 0) and fansi then error(estrnul, false)

end;

{*******************************************************************************

Parse label/reserved word

Parses a label, which is:

    '_'/'a'..'z' ['_', '0'..'9', 'a'..'z']...

After parsing, the label is checked against the reserved list, and returned as
a reserved tolken if so.

*******************************************************************************}

procedure parlabr;

const ansichar  = ['0'..'9', 'a'..'z', 'A'..'Z'];
      { extended characters include the ISO 8859-1 characters }
      eansichar = ['_', '0'..'9', 'a'..'z', 'A'..'Z', 'À'..'Ö', 'Ø'..'ö', 
                   'ø'..'ÿ'];
      
var i:  0..labmax; { index for label }
    ri: 0..resmax; { index for reserved table }

begin

   for i := 1 to labmax do nxtlab[i] := ' '; { clear label buffer }
   i := 0; { clear index }
   if fansi then while chkchr in ansichar do begin

      { parse label characters }
      if i <> labmax then begin { label not full }

         i := i + 1; { next character }
         nxtlab[i] := chkchr { place character }

      end;
      getchr { skip }

   end else while chkchr in eansichar do begin

      { parse label characters }
      if i <> labmax then begin { label not full }

         { check system label (starting with "_") }
         if (chkchr = '_') and not fsyslab and (i = 0) then 
            error(esyslab, false);
         i := i+1; { next character }
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

   end;
   { if ansi mode, serveral tolkens are invalid }
   if fansi and (nxttlk in [cxor, cforward, cmodule, cuses, cprivate, 
                            cextern, cview, cfixed, cprocess, cmonitor,
                            cshare, cclass, cis, catom, coverload, coverride,
                            creference, cthread, cjoins, cstatic, cinherited,
                            cself, cvirtual, ctry, cexcept, cextends, 
                            cresult]) then
            nxttlk := cidentifier { not tolkens }

end;

{*******************************************************************************

Parse special character sequence

Parses a 1 or 2 character special sequence. These are arbitrary characters,
with any kind of termination.

*******************************************************************************}

procedure parchr;

var hold: chrstr; { holding cell }
    i:    labinx; { index for label }

{ Find hash function }

function hash(s: chrstr; add: integer; max: integer): integer;

var i, r : integer;

begin

   r := 0;
   for i := 1 to spcmax do
      if s[i] <> ' ' then r := r + chr2ascii(s[i]) + add;

   hash := r mod max + 1 { return result }

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
   for i := 1 to labmax do nxtlab[i] := ' '; { set up label for errors }
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
      hold[2] := ' ';
      nxtlab[2] := ' ';
      search; { try that }
      if nxttlk = cundefined then error(eivsym, false, nxtlab); { error }

   end

end;

{*******************************************************************************

Check option line

Skips spaces, and checks for an option line.

*******************************************************************************}

procedure chkopt;

begin

   skpspc; { skip spaces }
   while startlin and not fansi and (chkchr = '#') do begin

      { parse option lines }
      chkbrk; { check user break }
      paropt('#'); { parse option line }
      skpspc  { skip spaces }

   end

end;

{*******************************************************************************

Parse tolken

Parses the following tolken types:

   1. String constants.
   2. Numeric constants.
   3. Reserved words.
   4. Specical character sequences.
   5. Indentifiers.
   6. Option lines.

*******************************************************************************}

procedure partlk;

begin

   skpspc; { skip spaces }
   if seof then nxttlk := ceof { eof }
   else begin

      if chkchr = '''' then
         parstr { string }
      else if fansi and (chkchr in ['A'..'Z', 'a'..'z']) then
         parlabr { label }
      else if not fansi and (chkchr in ['_', 'A'..'Z', 'a'..'z']) then
         parlabr { label }
      else if fansi and (chkchr in ['0'..'9']) then
         parnum(true) { ansi numeric }
      else if not fansi and (chkchr in ['0'..'9', '&', '%', '$']) then
         parnum(true) { numeric }
      else
         parchr { special character sequence }

   end

end;

{*******************************************************************************

Print tolken

A diagnostic, prints the current tolken in the nxttlk buffer.

*******************************************************************************}

procedure prttlk;

var i: labinx; { index for string }

begin

   if nxttlk in [clct, crct, cinteger, cidentifier, cstring, 
                 creal, cundefined, ceof] then
      case nxttlk of { special tolken }
   
      clct:        write('left comment');
      crct:        write('right comment');
      cinteger:    begin write('unsigned integer constant: ');
                         write(nxtint) end;
      cidentifier: begin write('identifier: '); 
                         write(nxtlab:0) end;
      cstring:     begin write('string constant: '); 
                         for i := 1 to nxtlen do write(nxtlab[i]) end;
      creal:       begin write('real constant: ');
                         write(nxtflt) end;
      cundefined:  write('undefined');
      ceof:        write('end of file');
   
   end else write(deftbl[nxttlk]^);

end;

{*******************************************************************************

Get next tolken

Parses the next tolken in line, and places the tolken code and any data in the
next buffers. Removes the error suppression on the parser.

*******************************************************************************}

procedure gettlk;

var ts: tolken; { tolken save }
    c:  char;   { holding }

begin

   ferrsup := false; { remove error suppression }
   chkbrk; { check input break }
   repeat

      chkopt; { check option line }
      partlk; { parse tolken }
      ts := nxttlk; { save tolken }
      if nxttlk = clct then begin { comment }

         scncmt := true; { set in comment }
         repeat

            c := chkchr; { check next }
            while (c <> '}') and (c <> '*') and not seof do begin

               chkbrk; { check input break }
               { if the next is a space, we use a space skip and
                 option check, as that is the only way to get from
                 line to line }
               if c = ' ' then chkopt
               else getchr; { skip characters }
               c := chkchr

            end;
            getchr { skip comment char }

         until (c = '}') or ((c = '*') and (chkchr = ')')) or seof;
         if c = '*' then getchr; { skip ')' }
         scncmt := false; { set not in comment }
         if seof then error(ecmtfe, false); { end of file }

      end

   until ts <> clct; { not comment }
   tlkcnt := tlkcnt + 1; { count tolkens }

   { the following is a diagnostic to print the next tolken }

   if ftolken then begin

      write('*');	
      prttlk; { print the tolken }
      writeln('*')

   end

end;

{*******************************************************************************

Skip to set tolken

Given a set of tolkens, will skip to the first tolken in the given set.

*******************************************************************************}

procedure skptlk;

begin

   scnskp := true; { set in skipping mode }
   { skip to first tolken in set }
   while not (nxttlk in ss) do begin

      if nxttlk = ceof then error(esflt23, true); { fault on eof }
      gettlk { skip tolken }

   end;
   scnskp := false { set not in skipping mode }

end;

{*******************************************************************************

Match misspelled labels

Here we try to discover if a label might concevably be another label
misspelled. We consider it possible if it is any of the following cases:

   1. One letter wrong.
   2. One letter missing.
   3. One extra character inserted.
   4. Two adjacent characters transposed.

These cases account for 80 percent of spelling errors (Gries[1971]).
Returns true if a misspell is possible. The strings should be space padded.

*******************************************************************************}

function match(view a: string; { 'good' label }
               view b: string) { 'bad' label }
              : boolean;       { match status }

var m:      boolean; { match flag }
    mc:     integer; { match count }
    i:      integer; { index for labels }
    la, lb: integer; { length of labels }

{ find if 'gapping' a character from list a will give b }

function gap(view a, b:   string;  { strings to match }
                  la, lb: integer) { lengths of strings }
            : boolean;

var i:  integer; { index for strings }
    m:  boolean; { match flag }
    fi: integer;

begin

   m := false; { set no match }
   if la = lb+1 then begin { gapping is possible }

      { find non-matching character }
      i := 1;
      fi := la; { set last character }
      while i < la do begin

         { check characters equal }
         if a[i] <> b[i] then { found not equal }
            begin fi := i; i := la end
         else i := i+1 { next } 

      end;
      m := true; { set matches }
      for i := fi+1 to la do { check the rest matches }
         if a[i] <> b[i-1] then m := false { set no match }
 
   end;

   gap := m { return result }

end;

begin

   la := len(a); { find lengths of strings }
   lb := len(b);
   m := false; { set no match }
   { try one letter wrong }
   if la = lb then begin { size matches }

      mc := 0; { clear match count }
      for i := 1 to la do if lcase(a[i]) = lcase(b[i]) then
         mc := mc+1; { count matching characters }
      { match status is all matching but one, with no matches on a single
        character since that is a complete label change }
      m := (mc >= la-1) and (mc > 1); { find good status }
      if not m and (mc >= la-2) then begin { try character transposition }

         m := false; { set no match }
         for i := 1 to la-1 do begin { try an exchange }

            { check next is not the same as this, and this matches other next,
              and next matches other this }
            if (a[i] <> a[i+1]) and (a[i] = b[i+1]) and (a[i+1] = b[i]) then 
               m := true { set match }

         end

      end

   end;
   if not m then begin { nope, didn't get it }

      { extra discrimination: we don't allow the case where a single letter
        matches up with a double letter by insertion, because this causes
        too many false positives when an undeclared single character label
        is found }
      m := gap(a, b, la, lb) and (lb > 1); { try one letter missing }
      if not m then begin { still negatory }

         m := gap(b, a, lb, la) and (la > 1) { try extra character inserted }
         
      end

   end;

   match := m { return match status }

end;

{*******************************************************************************

Match misspelled labels from tolken set

Accepts a set of tolkens to match, and trys to match the label buffer to it.
Returns tolken that matches, or undefined if none do.

*******************************************************************************}

function mattlk(ts: tolkset) { set of tolkens to match }
                : tolken;    { matching tolken }

var t: tolken; { tolken index }
    r: tolken; { result tolken }

begin

   t := cundefined; { index 1st tolken }
   r := cundefined; { set result undefined }
   repeat { for all tolkens, try match }

      if t in ts then { tolken is to be matched }
          { if matches, set result }
          if match(deftbl[t]^, nxtlab) then r := t;
      t := succ(t) { next tolken }

   { until end of tolkens or match found }
   until (t = ceof) or (r <> cundefined);

   mattlk := r { return result }

end;

{*******************************************************************************

Process spelling correction

Outputs a spelling correction information message, then 'repairs' the current
tolken by replacing both the next tolken value and label with the given tolken.
This makes the tolken virtually as if that had been parsed.

*******************************************************************************}

procedure corspell(t: tolken); { correct tolken }

begin

   error(emspell, false, nxtlab, deftbl[t]^); { output misspell message }
   { because respell is not really an error, but an information message,
     we back out this error count }
   errcnt := errcnt-1;
   nxttlk := t; { 'repair' current tolken }
   copy(nxtlab, deftbl[t]^) { and it's label }

end;         

{*******************************************************************************

Process parser error

If the error suppress flag is not active, outputs the error message specified. 
Then attempts the error recovery/correction specified. If a skip set is
present, a skip to that set is performed. If a correction set is present, and
the next symbol is an identifier, then the correction is attempted. If no
correction is possible, and the skip set is not null, a skip to the set is
performed. After the error, the parser error suppress flag is set active. This
flag prevents the output of any more errors unless the next tolken is read.
This prevents the output of multiple errors on a single tolken. The rationale
is that if a parser routine skips forward to a tolken, it will be able to use
that tolken, but cannot garantee that it will not generate more errors
attempting to sync to that tolken. This will suppress some important errors,
for instance, missing "end"s on the final '.' in the program. But on the
ballance will clean up the output. Parser errors are allways assumed to not be
fatal. This is basically a 'full service' routine for error handling in the
parser.

*******************************************************************************}

procedure perror(           e: errcod;  { error code }
                            s: tolkset; { skip set }
                            c: tolkset; { correction set }
                 view sp, sp2: string); { string parameter }

var cort: tolken; { corrected tolken }

begin

   if not ferrsup then error(e, false, sp, sp2); { output error message }
   { attempt spelling correction }
   cort := cundefined;
   if (nxttlk = cidentifier) and (c <> []) then cort := mattlk(c);
   if cort <> cundefined then { correct the spelling }
      corspell(cort)
   else if s <> [] then { skip set is not null }
      skptlk(s); { skip to tolken of interest }
   ferrsup := true { set error suppression on }

end; 

{ default empty parameters }

overload procedure perror(      e: errcod;  { error code }
                                s: tolkset; { skip set }
                                c: tolkset; { correction set }
                          view sp: string); { string parameter }

begin

   perror(e, s, c, sp, '')

end;

overload procedure perror(e: errcod;   { error code }
                          s: tolkset;  { skip set }
                          c: tolkset); { correction set }

begin

   perror(e, s, c, '', '')

end;

{*******************************************************************************

Expect single tolken

This is a full service parse for a single tolken. We accept a tolken to look
for, an error code to output if not seen, a skip set and a correction set.
If the tolken is not the next tolken, the error will be output and a skip or
spelling correction processed. If that succeeds in finding the original tolken,
it is then skipped. The expected tolken is skipped in any case, Generally for
the case where a single tolken is to be found and skipped. Not good for
multiple tolkens or where the tolken must be processed further (ie.,
identifiers).

*******************************************************************************}

procedure expect(t: tolken;   { tolken to expect }
                 e: errcod;   { error code }
                 s: tolkset;  { skip set }
                 c: tolkset); { correction set }

begin

   if nxttlk <> t then { expected tolken not found }
      perror(e, s, c); { process error }
   { we could have recovered the tolken by either skip
     set or spelling correction. If the next tolken is
     correct, chances are good we have recovered }
   if nxttlk = t then gettlk

end;

{*******************************************************************************

Check misspelled tolken

Checks if the next symbol is an id, and if it is, attempts to respell it as a
tolken.
This is done whenever the next tolken is optional, but a next id is definately
in error.

*******************************************************************************}

procedure chktkm(c: tolkset); { correction set }

begin

   if nxttlk = cidentifier then begin

      { the next tolken is id, and therefore invalid.
        We check if this may be a misspell, and so recover it }
      if mattlk(c) <> cundefined then
         { it respells. We output a symbol not found error and
           perform the respell }
         perror(esymnf, [], c, nxtlab)

   end

end;

begin
end.
