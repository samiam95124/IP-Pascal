{*******************************************************************************
*                                                                              *
*                                 C SCANNER                                    *
*                                                                              *
* Performs scanning for C language code.                                       *
*                                                                              *
*******************************************************************************}

module scanner(output);

uses stddef, { standard defines }
     strlib, { strings }
     macro;  { macro/source processing }

const

maxstr = 200; { maximum length of string/symbol }

type

{ scanner input tolkens }
tolken = (cundefined,  { undefined (must be first tolken) }
          cplus,       { + }
          cminus,      { - }
          ctimes,      { * }
          cdiv,        { / }
          cmod,        { % }
          cnequ,       { != }
          cltn,        { < }
          cgtn,        { > }
          clequ,       { <= }
          cgequ,       { >= }
          clparen,     { ( }
          crparen,     { ) }
          clbrkt,      { [ }
          crbrkt,      { ] }
          clct,        { /* }
          crct,        { */ }
          clnct,       { // }
          cperiod,     { . }
          ccma,        { , }
          cscn,        { ; }
          ccln,        { : }
          cxor,        { ^ }
          cprec,       { -> }
          cand,        { & }
          cland,       { && }
          clnot,       { ! }
          ccomp,       { ~ }
          cinc,        { ++ }
          cdec,        { -- }
          cshl,        { << }
          cshr,        { >> }
          cequ,        { == }
          cor,         { | }
          clor,        { || }
          ccond,       { ? }
          cas,         { = }
          casadd,      { += }
          cassub,      { -= }
          casmlt,      { *= }
          casdiv,      { /= }
          casmod,      { %= }
          casshl,      { <<= }
          casshr,      { >>= }
          casand,      { &= }
          casxor,      { ^= }
          casor,       { |= }
          cconts,      { ... }
          cbegin,      { left curly bracket }
          cend,        { right curly bracket }
          cauto,       { auto }
          cbreak,      { break }
          ccase,       { case }
          cchar,       { char }
          cconst,      { const }
          ccontinue,   { continue }
          cdefault,    { default }
          cdo,         { do }
          cdouble,     { double }
          celse,       { celse }
          cenum,       { enum }
          cextern,     { extern }
          cfloat,      { float }
          cfor,        { for }
          cgoto,       { goto }
          cif,         { if }
          cint,        { int }
          clong,       { long }
          cregister,   { register }
          creturn,     { return }
          cshort,      { short }
          csigned,     { signed }
          csizeof,     { sizeof }
          cstatic,     { static }
          cstruct,     { struct }
          cswitch,     { switch }
          ctypedef,    { typedef }
          cunion,      { union }
          cunsigned,   { unsigned }
          cvoid,       { void }
          cvolatile,   { volatile }
          cwhile,      { while }
          ccint,       { integer constant }
          cclong,      { long integer constant }
          cclonglong,  { long long integer constant }
          ccuint,      { unsigned integer constant }
          cculong,     { unsigned long constant }
          cculonglong, { unsigned long long constant }
          cidentifier, { identifier }
          cstring,     { string constant }
          creal,       { real constant }
          ceof);       { end of file (must be last tolken) }

var

{ scanner block variables }
nxttlk: tolken;  { next tolken }
nxtlab: packed array [1..maxstr] of char; { next label/string }
nxtlen: integer; { next length of string }
nxtint: integer; { next integer }
nxtflt: real;    { next real }
fprttlk: boolean; { print tolkens }

procedure gettlk; forward;
procedure pshtlk; forward;

private

const

chrmax  = 59;   { number of special character sequences
                  (plus padding) }
resmax  = 40;   { number of reserved words (plus padding) }
spcmax  = 3;    { special character string length }
maxexp  = 308;  { maximum exponent of real }
hashoff = 26;   { hash function offset }
chroff  = 8;    { special character hash offset }

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

{ pushback variables }
nxttlkpb: tolken;  { next tolken }
nxtlabpb: packed array [1..maxstr] of char; { next label/string }
nxtlenpb: integer; { next length of string }
nxtintpb: integer; { next integer }
nxtfltpb: real;    { next real }
pushback: boolean; { there is a pushback tolken }
{ old tolken for pushback use }
nxttlkold: tolken;  { next tolken }
nxtlabold: packed array [1..maxstr] of char; { next label/string }
nxtlenold: integer; { next length of string }
nxtintold: integer; { next integer }
nxtfltold: real;    { next real }

spctbl:  array [chrinx] of chrequ; { special character table }
restbl:  array [resinx] of resequ; { reserved words table }
deftbl:  array [tolken] of pstring; { tolken definition strings }
ci:      chrinx;
ri:      resinx;
li:      labinx;

{******************************************************************************

Parse and convert numeric

Parses and converts the following:

     [radix specification] ['0'..'9', 'a'..'z', 'A'..'Z']...

Where the radix specifier is:

     0    - Octal
     0x   - hexadecimal
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

procedure sparnum(searchreal: boolean); { real number search flag }

label skipzero; { short circuit C syntax mistakes }

var c:    char;
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

procedure sgetchrb;

begin

   outb[outi] := schkchr; { place character in buffer }
   outi := outi+1; { next character }
   sgetchr { and get that }

end;

begin

   outi := 1; { index 1st output character }
   clears(outb); { clear buffer }
   sskpspc; { skip spaces }
   rm := false; { set no radix mark }
   r := 10; { set default radix decimal}
   exp := 0; { clear real exponent }
   nxtint := 0; { initalize result }
   if schkchr = '0' then begin { octal or hex }

      r := 8; { set octal radix }
      rm := true; { set radix mark encountered }
      sgetchrb; { skip }
      if lcase(schkchr) = 'x' then begin { radix is hexadecimal }

         r := 16; { set hexadecimal radix }
         sgetchrb { skip }

      end

   end;
   if not (((schkchr in ['0'..'9', 'a'..'z', 'A'..'Z']) and (r = 16)) or
           ((schkchr in ['0'..'7']) and (r = 8)) or
           (schkchr in ['0'..'9'])) then begin

      { check octal. C considers 0 to be both digit and radix specifier }
      if r = 8 then goto skipzero; { go zero }
      error(einvdig) { error }

   end;
   while (((schkchr in ['a'..'f', 'A'..'F']) and (r = 16)) or
      (schkchr in ['0'..'9'])) do begin { parse digits }

         { count significant digits to exponent (used on real only) }
         if (schkchr <> '0') or (exp <> 0) then exp := exp+1;
         { convert '0'..'9' }
         if (schkchr in ['0'..'9']) then v := ord(schkchr) - ord('0')
         else v := ord(lcase(schkchr)) - ord('a') + 10; { convert 'a'..'f' }
         if v >= r then error(edigbrd) { does not fit radix }
         else begin { ok }

            { check for overflow }
            {if ((nxtint > maxint div r) or 
               ((nxtint = maxint div r) and (v > maxint mod r))) then
               error(enumovf)
            else } nxtint := nxtint * r + v { scale and add in }

         end;
         sgetchrb { next }

   end;
   skipzero: { here for zero bypass }
   if exp <> 0 then exp := exp - 1; { adjust exponent }
   nxttlk := ccint; { place type }
   if searchreal then begin { search for real specification }

      nxtflt := nxtint; { move integer to real }
      if schkchr = '.' then begin { decimal point }

         { the '.' could be a '..', in which case it's really
           <integer>.. we must back up in this case }
         ssavpos; { save command pointer }
         sgetchrb; { skip '.' }
         if schkchr = '.' then srstpos { back up }
         else begin { is a decimal point }

            zero := nxtint = 0; { check number is zero (so far) }
            if rm then error(einvrft);
            if not (schkchr in ['0'..'9']) then error(einvrft);
            p := 1.0; { initalize power }
            while schkchr in ['0'..'9']  do begin { parse digits }

               if zero then exp := exp-1; { adjust the 'virtual exponent' }
               if schkchr <> '0' then zero := false; { set leading digit found }
               p := p / 10.0; { find next scale }
               { add and scale new digit }
               nxtflt := nxtflt + (p * (ord(schkchr) - ord('0')));
               sgetchrb { next }

            end;
            nxttlk := creal { place tolken }

         end

      end;
      if lcase(schkchr) = 'e' then begin { exponent }

         sgetchrb; { skip 'e' }
         sgn := 1; { set sign of exponent }
         c := schkchr; { check next }
         if c = '-' then sgn := -sgn; { set negative }
         if (c = '+') or (c = '-') then sgetchrb; { skip sign }
         if not (schkchr in ['0'..'9']) then error(einvrft)
         else begin

            sparnum(false); { parse integer only }
            if (nxtint > maxexp) or (abs(sgn*nxtint+exp) > maxexp) then
               error(eexptl);
            { find with exponent }
            if c = '-' then nxtflt := nxtflt / pwrten(nxtint)
            else nxtflt := nxtflt * pwrten(nxtint)

         end;
         nxttlk := creal { place tolken }

      end

   end;
   if nxttlk = ccint then begin

      { parse various annoying suffixes }
      if lcase(schkchr) = 'l' then begin { long }

         nxttlk := cclong; { set type }
         sgetchrb; { skip }
         if lcase(schkchr) = 'l' then begin { long long }

            nxttlk := cclonglong; { set type }
            sgetchrb; { skip }
            if lcase(schkchr) = 'u' then begin { unsigned }

               nxttlk := cculong; { set type }
               sgetchrb { skip }

            end

         end else if lcase(schkchr) = 'u' then begin { unsigned }

            nxttlk := cculong; { set type }
            sgetchrb { skip }

         end

      end else if lcase(schkchr) = 'u' then begin { unsigned }

         nxttlk := ccuint; { set type }
         sgetchrb; { skip }
         if lcase(schkchr) = 'l' then begin { long }

            nxttlk := cculong; { set type }
            sgetchrb; { skip }
            if lcase(schkchr) = 'l' then begin { long long }

               nxttlk := cculonglong; { set type }
               sgetchrb { skip }
              
            end

         end

      end

   end;
   copyp(nxtlab, outb) { place number as parsed }

end;

{******************************************************************************

Parse string/character constant

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

procedure sparstr; { file to read from }

var c: char; { holding character }
    v: integer; { force value }
    q: char; { quote character }

begin

   nxtlen := 0; { null string }
   sskpspc; { skip leading spaces }
   { the following will never happen }
   if (schkchr <> '''') and (schkchr <> '"') then error(emisstr);
   q := schkchr; { save the quote character }
   sgetchr; { skip }
   while not (schkchr = q) and not sendlin do begin { process string }

      c := schkchr; { check next }
      sgetchr; { skip }
      if c = '\\' then begin { control sequence }

         sgetchr; { skip }
         c := schkchr; { next }
         if c in ['0'..'7'] then begin

            v := ord(c)-ord('0'); { find value }
            sgetchr; { skip }
            c := schkchr; { next }
            if c in ['0'..'7'] then begin { 2nd digit }

               v := v*8+ord(c)-ord('0'); { find value }
               sgetchr; { skip }
               c := schkchr; { next }
               if c in ['0'..'7'] then begin { 3rd digit }

                  v := v*8+ord(c)-ord('0'); { find value }
                  sgetchr { skip }

               end

            end;
            c := chr(v) { place value }

         end else if lcase(c) in ['n', 't', 'b', 'r', 'f'] then
            case lcase(c) of { force sequence }

            'n':  c := '\lf'; { new line }
            't':  c := '\ht'; { tab }
            'b':  c := '\bs'; { back space }
            'r':  c := '\cr'; { carriage return }
            'f':  c := '\ff' { form feed }

         end

      end;
      nxtlen := nxtlen+1; { add to length }
      nxtlab[nxtlen] := c { place character }

   end;
   if schkchr <> q then error(eutmstr); { no ending quote }
   sgetchr; { skip }
   if (q = '''') and (nxtlen = 1) then begin { convert to integer }

      nxtint := ord(nxtlab[1]); { get character value }
      nxttlk := ccint { set integer }

   end else nxttlk := cstring { place tolken }

end;

{******************************************************************************

Parse label/reserved word

Parses a label, which is:

    '_'/'a'..'z' ['_', '0'..'9', 'a'..'z']...

After parsing, the label is checked against the reserved list, and returned as
a reserved tolken if so.

******************************************************************************}

procedure sparlabr;

var ri: 0..resmax; { index for reserved table }
    i:  0..maxstr; { index for label }

begin

   clears(nxtlab); { clear label buffer }
   i := 0; { clear index }
   while schkchr in ['_', '0'..'9', 'a'..'z', 'A'..'Z'] do begin

      { parse label characters }
      if i <> maxstr then begin { label not full }

         i := i + 1; { next character }
         nxtlab[i] := schkchr { place character }

      end;
      sgetchr { skip }

   end;
   ri := hashc(nxtlab, hashoff, resmax); { find initial hash function }
   if compcp(nxtlab, restbl[ri].lab^) then { found 1st try }
      nxttlk := restbl[ri].tolk
   else begin { search chained }

      { traverse chains searching }
      while (restbl[ri].chn <> 0) and 
            not compcp(nxtlab, restbl[ri].lab^) do ri := restbl[ri].chn;
      if compcp(nxtlab, restbl[ri].lab^) then { found }
         nxttlk := restbl[ri].tolk
      else nxttlk := cidentifier { place tolken is identifier }

   end

end;

{******************************************************************************

Parse special character sequence

Parses a 1 or 2 character special sequence. These are arbitrary characters,
with any kind of termination.

******************************************************************************}

procedure sparchr;

var hold: chrstr; { holding cell }
    i:    labinx; { index for label }

{ Find hash function }

function hashc(s: chrstr; add: integer; max: integer): integer;

var i, r : integer;

begin

   r := 0;
   for i := 1 to spcmax do if s[i] <> ' ' then r := r + ord(s[i]) + add;
   hashc := r mod max + 1

end;

{ search label }

procedure search;

var ci: chrinx; { index for special character table }

begin

   ci := hashc(hold, chroff, chrmax); { find initial hash function }
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

   ssavpos; { save current line position }
   for i := 1 to spcmax do begin { fill up holding buffer }

      hold[i] := schkchr; { place character }
      sgetchr { next }

   end;
   srstpos; { restore line position }
   copyp(nxtlab, hold); { set up label for errors }
   search; { search triple characters }
   if nxttlk = cundefined then begin { search double characters }

      hold[3] := ' '; { knock out 3rd character }
      nxtlab[3] := ' ';
      search { try that }

   end;
   if nxttlk = cundefined then begin { search single characters }

      hold[2] := ' '; { knock out 2nd character }
      nxtlab[2] := ' ';
      search; { try that }
      if nxttlk = cundefined then error(einvsch) { invalid }

   end;
   { skip forward the length of the found sequence }
   if nxttlk <> cundefined then { there was a tolken found }
      for i := 1 to spcmax do if hold[i] <> ' ' then sgetchr { skip }

end;

{******************************************************************************

Get next tolken

Parses the next tolken in line, and places the tolken code and any data in the
next buffers.

Parses the following tolken types:

   1. String constants.
   2. Numeric constants.
   3. Reserved words.
   4. Specical character sequences.
   5. Indentifiers.

******************************************************************************}

procedure gettlk;

var i:      labinx;  { index for string }
    t:      tolken;  { tolken save }
    ismult: boolean; { end of loop flag }

begin

   if pushback then begin { process pushed back tolken }

      { copy pushback tolken block to current }
      nxttlk := nxttlkpb;
      nxtlab := nxtlabpb;
      nxtlen := nxtlenpb;
      nxtint := nxtintpb;
      nxtflt := nxtfltpb;
      pushback := false { remove pushback status }

   end else begin   

      { copy current tolken to old tolken save, for pushback use }
      nxttlkold := nxttlk;
      nxtlabold := nxtlab;
      nxtlenold := nxtlen;
      nxtintold := nxtint;
      nxtfltold := nxtflt;
      repeat

         sskpspc; { skip spaces }
         if seof then nxttlk := ceof { eof }
         else begin

            if (schkchr = '''') or (schkchr = '"') then
               sparstr { string }
            else if schkchr in ['_', 'A'..'Z', 'a'..'z'] then
               sparlabr { label/macro }
            else if schkchr in ['0'..'9'] then
               sparnum(true) { numeric }
            else
               sparchr { special character sequence }

         end;
         t := nxttlk; { save next tolken }
         if t = clnct then while not sendlin do sgetchr { skip line comment }
         else if t = clct then begin { multiline comment }

            repeat { skip multiline }

               sskpspc; { skip spaces and lines }
               if seof then error(eutmcmt); { no termination for comment }
               ismult := schkchr = '*'; { check for comment start }
               sgetchr; { next }
               if seof then error(eutmcmt); { no termination for comment }

            until ismult and (schkchr = '/'); { until comment end }
            sgetchr { skip '/' }

         end

      until not (t in [clnct, clct]); { no comment leader }

      { the following is a diagnostic to print the next tolken }

      if fprttlk then begin

         write('*');	
         if nxttlk in [clct, crct, ccint, cclong, cclonglong, ccuint, cculong,
                          cculonglong, cidentifier, cstring, creal, cundefined,
                          ceof] then
            case nxttlk of { special tolken }
      
            clct:        write('left comment');
            crct:        write('right comment');
            ccint:       write('integer constant: ', nxtint);
            ccuint:      write('unsigned integer constant: ', nxtint);
            cclong:      write('long integer constant: ', nxtint);
            cclonglong:  write('long long integer constant: ', nxtint);
            cculong:     write('unsigned long integer constant: ', nxtint);
            cculonglong: write('unsigned long long integer constant: ', nxtint);
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

   end

end;

{******************************************************************************

Pushback old tolken

C needs two lookahead tolkens to parse, because of the 'goto' label ambiguity.
We keep the last tolken in store on a running basis. To pushback, we take the
current tolken, place that in save, then restore the current tolken to be
the old tolken and flag a pushback. That effectively puts us one step back in
the tolken stream.

******************************************************************************}

procedure pshtlk;

begin

   { copy current to save }
   nxttlkpb := nxttlk;
   nxtlabpb := nxtlab;
   nxtlenpb := nxtlen;
   nxtintpb := nxtint;
   nxtfltpb := nxtflt;
   { copy old to current }
   nxttlk := nxttlkold;
   nxtlab := nxtlabold;
   nxtlen := nxtlenold;
   nxtint := nxtintold;
   nxtflt := nxtfltold;
   pushback := true { set pushback active }

end;

{******************************************************************************

Initalize scanner

Initalizes the special character and reserved word tables, then loads the first
line from the input file.

******************************************************************************}

begin

   { initalize special character sequence table }

   for ci := 1 to chrmax do 
     with spctbl[ci] do begin { initalize all table }
  
      lab := '   ';
      tolk := cundefined;
      chn := 0

   end;

   spctbl[  1].lab  := '!= '; spctbl[  1].chn :=  18;
   spctbl[  1].tolk := cnequ;
   spctbl[  2].lab  := '*= ';
   spctbl[  2].tolk := casmlt;
   spctbl[  3].lab  := '+= ';
   spctbl[  3].tolk := casadd;
   spctbl[  4].lab  := '*/ '; spctbl[  4].chn :=  24;
   spctbl[  4].tolk := crct;
   spctbl[  5].lab  := '-= ';
   spctbl[  5].tolk := cassub;
   spctbl[  6].lab  := '-> ';
   spctbl[  6].tolk := cprec;
   spctbl[  7].lab  := '/= ';
   spctbl[  7].tolk := casdiv;
   spctbl[  8].lab  := ':  ';
   spctbl[  8].tolk := ccln;
   spctbl[  9].lab  := ';  ';
   spctbl[  9].tolk := cscn;
   spctbl[ 10].lab  := '<  ';
   spctbl[ 10].tolk := cltn;
   spctbl[ 11].lab  := '=  ';
   spctbl[ 11].tolk := cas;
   spctbl[ 12].lab  := '>  ';
   spctbl[ 12].tolk := cgtn;
   spctbl[ 13].lab  := '?  ';
   spctbl[ 13].tolk := ccond;
   spctbl[ 14].lab  := '{  ';
   spctbl[ 14].tolk := cbegin;
   spctbl[ 15].lab  := '|  ';
   spctbl[ 15].tolk := cor;
   spctbl[ 16].lab  := '}  ';
   spctbl[ 16].tolk := cend;
   spctbl[ 17].lab  := '~  ';
   spctbl[ 17].tolk := ccomp;
   spctbl[ 18].lab  := '// ';
   spctbl[ 18].tolk := clnct;
   spctbl[ 19].lab  := '<< ';
   spctbl[ 19].tolk := cshl;
   spctbl[ 20].lab  := '<= ';
   spctbl[ 20].tolk := clequ;
   spctbl[ 21].lab  := '== ';
   spctbl[ 21].tolk := cequ;
   spctbl[ 22].lab  := '>= ';
   spctbl[ 22].tolk := cgequ;
   spctbl[ 23].lab  := '>> ';
   spctbl[ 23].tolk := cshr;
   spctbl[ 24].lab  := '&  ';
   spctbl[ 24].tolk := cand;
   spctbl[ 25].lab  := '|= ';
   spctbl[ 25].tolk := casor;
   spctbl[ 26].lab  := '++ ';
   spctbl[ 26].tolk := cinc;
   spctbl[ 27].lab  := '%= ';
   spctbl[ 27].tolk := casmod;
   spctbl[ 28].lab  := '<<=';
   spctbl[ 28].tolk := casshl;
   spctbl[ 29].lab  := '|| '; spctbl[ 29].chn :=  28;
   spctbl[ 29].tolk := clor;
   spctbl[ 30].lab  := '^= ';
   spctbl[ 30].tolk := casxor;
   spctbl[ 33].lab  := '>>=';
   spctbl[ 33].tolk := casshr;
   spctbl[ 34].lab  := '&& ';
   spctbl[ 34].tolk := cland;
   spctbl[ 41].lab  := '[  ';
   spctbl[ 41].tolk := clbrkt;
   spctbl[ 42].lab  := '!  ';
   spctbl[ 42].tolk := clnot;
   spctbl[ 43].lab  := ']  ';
   spctbl[ 43].tolk := crbrkt;
   spctbl[ 44].lab  := '^  '; spctbl[ 44].chn :=  26;
   spctbl[ 44].tolk := cxor;
   spctbl[ 45].lab  := '...';
   spctbl[ 45].tolk := cconts;
   spctbl[ 46].lab  := '%  ';
   spctbl[ 46].tolk := cmod;
   spctbl[ 47].lab  := '/* '; spctbl[ 47].chn :=   4;
   spctbl[ 47].tolk := clct;
   spctbl[ 48].lab  := '-- ';
   spctbl[ 48].tolk := cdec;
   spctbl[ 49].lab  := '(  ';
   spctbl[ 49].tolk := clparen;
   spctbl[ 50].lab  := ')  ';
   spctbl[ 50].tolk := crparen;
   spctbl[ 51].lab  := '*  ';
   spctbl[ 51].tolk := ctimes;
   spctbl[ 52].lab  := '+  '; spctbl[ 52].chn :=   1;
   spctbl[ 52].tolk := cplus;
   spctbl[ 53].lab  := ',  ';
   spctbl[ 53].tolk := ccma;
   spctbl[ 54].lab  := '-  '; spctbl[ 54].chn :=  30;
   spctbl[ 54].tolk := cminus;
   spctbl[ 55].lab  := '.  ';
   spctbl[ 55].tolk := cperiod;
   spctbl[ 56].lab  := '/  '; spctbl[ 56].chn :=  27;
   spctbl[ 56].tolk := cdiv;
   spctbl[ 57].lab  := '&= ';
   spctbl[ 57].tolk := casand;

   { initalize reserved word table. This table is automatically
     generated, see the "hashtab" program. }

   for ri := 1 to resmax do
     with restbl[ri] do begin { initalize all table }
  
      for li := 1 to maxstr do lab := nil;
      tolk := cundefined;
      chn := 0

   end;

   copysp(restbl[  1].lab,  'goto');
   restbl[  1].tolk := cgoto;
   copysp(restbl[  2].lab,  'const');
   restbl[  2].tolk := cconst;
   copysp(restbl[  3].lab,  'int');
   restbl[  3].tolk := cint;
   copysp(restbl[  4].lab,  'default'); restbl[  4].chn :=   9;
   restbl[  4].tolk := cdefault;
   copysp(restbl[  5].lab,  'static');
   restbl[  5].tolk := cstatic;
   copysp(restbl[  6].lab,  'for');
   restbl[  6].tolk := cfor;
   copysp(restbl[  7].lab,  'register');
   restbl[  7].tolk := cregister;
   copysp(restbl[  8].lab,  'break');
   restbl[  8].tolk := cbreak;
   copysp(restbl[  9].lab,  'union');
   restbl[  9].tolk := cunion;
   copysp(restbl[ 10].lab,  'else'); restbl[ 10].chn :=   3;
   restbl[ 10].tolk := celse;
   copysp(restbl[ 11].lab,  'short');
   restbl[ 11].tolk := cshort;
   copysp(restbl[ 12].lab,  'void');
   restbl[ 12].tolk := cvoid;
   copysp(restbl[ 13].lab,  'sizeof');
   restbl[ 13].tolk := csizeof;
   copysp(restbl[ 15].lab,  'switch');
   restbl[ 15].tolk := cswitch;
   copysp(restbl[ 16].lab,  'typedef');
   restbl[ 16].tolk := ctypedef;
   copysp(restbl[ 17].lab,  'long');
   restbl[ 17].tolk := clong;
   copysp(restbl[ 19].lab,  'extern'); restbl[ 19].chn :=  12;
   restbl[ 19].tolk := cextern;
   copysp(restbl[ 20].lab,  'if');
   restbl[ 20].tolk := cif;
   copysp(restbl[ 22].lab,  'enum');
   restbl[ 22].tolk := cenum;
   copysp(restbl[ 24].lab,  'do');
   restbl[ 24].tolk := cdo;
   copysp(restbl[ 25].lab,  'float');
   restbl[ 25].tolk := cfloat;
   copysp(restbl[ 26].lab,  'auto'); restbl[ 26].chn :=   1;
   restbl[ 26].tolk := cauto;
   copysp(restbl[ 28].lab,  'while');
   restbl[ 28].tolk := cwhile;
   copysp(restbl[ 29].lab,  'return');
   restbl[ 29].tolk := creturn;
   copysp(restbl[ 30].lab,  'unsigned');
   restbl[ 30].tolk := cunsigned;
   copysp(restbl[ 31].lab,  'signed');
   restbl[ 31].tolk := csigned;
   copysp(restbl[ 32].lab,  'double');
   restbl[ 32].tolk := cdouble;
   copysp(restbl[ 33].lab,  'volatile');
   restbl[ 33].tolk := cvolatile;
   copysp(restbl[ 34].lab,  'struct');
   restbl[ 34].tolk := cstruct;
   copysp(restbl[ 37].lab,  'case');
   restbl[ 37].tolk := ccase;
   copysp(restbl[ 38].lab,  'continue'); restbl[ 38].chn :=   7;
   restbl[ 38].tolk := ccontinue;
   copysp(restbl[ 39].lab,  'char');
   restbl[ 39].tolk := cchar;

   { definitions table.
     This table is used to translate tolkens back to 
     ASCII. It is used for diagnostics and spelling correction }

   copysp(deftbl[cnequ], '!=');
   copysp(deftbl[casmlt], '*=');
   copysp(deftbl[casadd], '+=');
   copysp(deftbl[crct], '*/');
   copysp(deftbl[cassub], '-=');
   copysp(deftbl[cprec], '->');
   copysp(deftbl[casdiv], '/=');
   copysp(deftbl[ccln], ':');
   copysp(deftbl[cscn], ';');
   copysp(deftbl[cltn], '<');
   copysp(deftbl[cas], '=');
   copysp(deftbl[cgtn], '>');
   copysp(deftbl[ccond], '?');
   copysp(deftbl[cbegin], '{');
   copysp(deftbl[cor], '|');
   copysp(deftbl[cend], '}');
   copysp(deftbl[ccomp], '~');
   copysp(deftbl[clnct], '//');
   copysp(deftbl[cshl], '<<');
   copysp(deftbl[clequ], '<=');
   copysp(deftbl[cequ], '==');
   copysp(deftbl[cgequ], '>=');
   copysp(deftbl[cshr], '>>');
   copysp(deftbl[cand], '&');
   copysp(deftbl[casor], '|=');
   copysp(deftbl[cinc], '++');
   copysp(deftbl[casmod], '%=');
   copysp(deftbl[casshl], '<<=');
   copysp(deftbl[clor], '||');
   copysp(deftbl[casxor], '^=');
   copysp(deftbl[casshr], '>>=');
   copysp(deftbl[cland], '&&');
   copysp(deftbl[clbrkt], '[');
   copysp(deftbl[clnot], '!');
   copysp(deftbl[crbrkt], ']');
   copysp(deftbl[cxor], '^');
   copysp(deftbl[cconts], '...');
   copysp(deftbl[cmod], '%');
   copysp(deftbl[clct], '/*');
   copysp(deftbl[cdec], '--');
   copysp(deftbl[clparen], '(');
   copysp(deftbl[crparen], ')');
   copysp(deftbl[ctimes], '*');
   copysp(deftbl[cplus], '+');
   copysp(deftbl[ccma], ',');
   copysp(deftbl[cminus], '-');
   copysp(deftbl[cperiod], '.');
   copysp(deftbl[cdiv], '/');
   copysp(deftbl[casand], '&=');

   copysp(deftbl[cgoto],  'goto');
   copysp(deftbl[cconst],  'const');
   copysp(deftbl[cint],  'int');
   copysp(deftbl[cdefault],  'default');
   copysp(deftbl[cstatic],  'static');
   copysp(deftbl[cfor],  'for');
   copysp(deftbl[cregister],  'register');
   copysp(deftbl[cbreak],  'break');
   copysp(deftbl[cunion],  'union');
   copysp(deftbl[celse],  'else');
   copysp(deftbl[cshort],  'short');
   copysp(deftbl[cvoid],  'void');
   copysp(deftbl[csizeof],  'sizeof');
   copysp(deftbl[cswitch],  'switch');
   copysp(deftbl[ctypedef],  'typedef');
   copysp(deftbl[clong],  'long');
   copysp(deftbl[cextern],  'extern');
   copysp(deftbl[cif],  'if');
   copysp(deftbl[cenum],  'enum');
   copysp(deftbl[cdo],  'do');
   copysp(deftbl[cfloat],  'float');
   copysp(deftbl[cauto],  'auto');
   copysp(deftbl[cwhile],  'while');
   copysp(deftbl[creturn],  'return');
   copysp(deftbl[cunsigned],  'unsigned');
   copysp(deftbl[csigned],  'signed');
   copysp(deftbl[cdouble],  'double');
   copysp(deftbl[cvolatile],  'volatile');
   copysp(deftbl[cstruct],  'struct');
   copysp(deftbl[ccase],  'case');
   copysp(deftbl[ccontinue],  'continue');
   copysp(deftbl[cchar],  'char');

   pushback := false; { set no pushback active }
   fprttlk := false { do not print tolkens }

end.
