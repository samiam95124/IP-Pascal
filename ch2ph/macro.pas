{*******************************************************************************
*                                                                              *
*                                 C MACRO LEVEL                                *
*                                                                              *
* Contains low level line by line processing, including line force expansion   *
* and macro processing. Handles opening, closing and management of stacked     *
* source files, reading of source lines, and provides a series of character    *
* level calls to sequence through the file.                                    *
*                                                                              *
* procedure error(e: errcod);                                                  *
*                                                                              *
* Outputs an error message by code.                                            *
*                                                                              *
* procedure opnsrc(view n: string);                                            *
*                                                                              *
* Opens the given source file for reading. Will stack any number of nested     *
* files.                                                                       *
*                                                                              *
* procedure clssrc;                                                            *
*                                                                              *
* Closes the topmost source file in the stack. It is an error if the source    *
* stack is empty.                                                              *
*                                                                              *
* function seof: boolean;                                                      *
*                                                                              *
* Checks if the end of all files has been reached.                             *
*                                                                              *
* function sendlin: boolean;                                                   *
*                                                                              *
* Checks if the end of current line has been reached.                          *
*                                                                              *
* function schkchr: char;                                                      *
*                                                                              *
* Returns the next character.                                                  *
*                                                                              *
* procedure sgetchr;                                                           *
*                                                                              *
* Advances to the next character position. Will skip lines and stacked files.  *
*                                                                              *
* procedure sskpspc;                                                           *
*                                                                              *
* Skips spaces or control characters (any character less than or equal to ' '. *
* Will skip lines and stacked files.                                           *
*                                                                              *
* procedure ssavpos;                                                           *
*                                                                              *
* Saves the current line position, one level deep.                             *
*                                                                              *
* procedure srstpos;                                                           *
*                                                                              *
* Restores previously saved line position.                                     *
*                                                                              *
* function hashc(view s: string; add: integer; maxv: integer): integer;        *
*                                                                              *
* Finds the hash function for a label, respecting case.                        *
*                                                                              *
*******************************************************************************}

module macro(output);

uses stddef, { standard defines }
     strlib, { strings }
     extlib, { extention library }
     symbol, { for symbols routines }
     ch2ph;  { for program terminate }

type

{ errors }
errcod = (einltl,   { input line too large }
          einvdig,  { invalid digit }
          edigbrd,  { digit beyond radix }
          einvrft,  { invalid real format }
          eexptl,   { exponent too large }
          emisstr,  { missing string }
          eutmstr,  { unterminated string }
          eccnsgl,  { character constant not single character }
          eutmcmt,  { unterminated comment }
          einctl,   { include filename too long }
          eincnf,   { include file not found }
          einvsch,  { invalid symbol/character }
          enumovf,  { numeric overflow }
          edeftbf,  { define table full }
          erecmac,  { recursive macro invoked }
          edirmis,  { no directive present }
          edirnf,   { directive not found }
          elabtl,   { label too long }
          emacexp,  { macro name expected }
          eparnf,   { parameter id expected }
          emacbm,   { macro duplicate define body does not match original }
          emacpm,   { macro duplicate define paramters do not match original }
          erpexp,   { ')' expected }
          emendq,   { missing end quote }
          enegshc,  { negative shift count }
          eclnexp,  { ':' expected }
          emisif,   { matching 'if' missing }
          emacpem,  { macro replacement parameter is empty }
          eparext,  { too many replacement parameters for macro }
          eidexp,   { identifier expected }
          einvfac,  { invalid factor }
          eifnst,   { unmatched '#endif' }
          eprmexp,  { primary-expression not found }
          erbktexp, { ']' expected }
          escnexp,  { ';' expected }
          elpexp,   { '(' expected }
          ewhlexp,  { 'while' expected }
          einvtyp,  { invalid type-specifier }
          esymnf,   { symbol not found }
          easexp,   { '=' expected }
          eendexp,  { end expected }
          einvdec,  { invalid declarator }
          eabsdec,  { invalid abstract declarator }
          einvdcl,  { invalid declaration }
          edupsym,  { duplicate symbol }
          einvtnm,  { identifier does not designate type }
          etyprdf,  { attempt to redefine type }
          ecstdup,  { 'const' already appears }
          etypdup,  { two or more data types in declaration }
          escldup,  { multiple storage classes in declaration }
          evoldup,  { 'volatile' in declaration more than once }
          echratt,  { char used with short or long }
          elngdup,  { 'long' specified twice on double }
          eredef,   { redefinition of type }
          elpidexp, { '(' or identifier expected }
          earrfnc,  { cannot declare array of functions }
          efncfnc,  { cannot declare function returning function }
          eicstexp, { expression must be constant integer }
          ecstopr,  { operation not permitted for constant }
          ecstcas,  { constant must be cast to integer }
          eshftno,  { bad shift number }
          einvcls,  { 'auto' or 'register' used on top level declaration }
          eparini,  { parameter has initalization }
          eparsnf,  { parameter symbol not found }
          epardtp,  { parameter type was duplicated }
          efncexp,  { function declaration was expected }
          einvopt,  { invalid command line option }
          eoptnf,   { command line option not found }
          efilnf,   { source file not found }
          einvfil,  { invalid filename }
          efilexp,  { filename expected }
          einvexp,  { invalid expression }
          edattyp,  { no type specified for data }
          ebgnexp,  { begin expected }
          eempmac,  { macro list is empty for parametered macro }
          etidexp,  { type id expected }
          einvtpc,  { type combination invalid }
          etypmch,  { type does not match original definition }
          enostcl,  { no storage class allowed here }
          ecmpnst,  { type comparision nesting }
          einvmod,  { invalid module name }
          einscmd,  { invalid instruction file command }
          einscnf,  { instruction file command not found }
          etypsnf,  { symbol for type not found }
          ecatnf,   { catalog file not found }
          emodnnf,  { module name not found }
          esys1,    { system error }
          esys2, 
          esys3, 
          esys4, 
          esys5, 
          esys6, 
          esys7, 
          esys8, 
          esys9, 
          esys10, 
          esys11,
          esys12,
          esys13,
          esys14,
          esys15,
          esys16,
          esys17,
          esys18,
          esys19,
          esys20,
          esys21,
          esys22,
          esys23,
          esys24,
          esys25,
          esys26,
          esys27,
          esys28,
          esys29,
          esys30,
          esys31,
          esys32,
          esys33,
          esys34,
          esys35,
          esys36,
          esys37,
          esys38, 
          esys39, 
          esys40, 
          esys41, 
          esys42, 
          esys43, 
          esys44,
          esys45, 
          esys46, 
          esys47, 
          esys48, 
          esys49, 
          esys50, 
          esys51, 
          esys52, 
          esys53, 
          esys54, 
          esys55, 
          esys56, 
          esys57, 
          esys58, 
          esys59, 
          esys60, 
          esys61, 
          esys62, 
          esys63, 
          esys64, 
          esys65, 
          esys66, 
          esys67, 
          esys68, 
          esys69, 
          esys70, 
          esys71, 
          esys72, 
          esys73, 
          esys74, 
          esys75, 
          esys76, 
          esys77, 
          esys78, 
          esys79, 
          esys80, 
          esys81, 
          esys82, 
          esys83, 
          esys84, 
          esys85, 
          esys86, 
          esys87, 
          esys88, 
          esys89, 
          esys90, 
          esys91, 
          esys92, 
          esys93);

{ variables this module }

var

fprtlin: boolean; { print incoming lines }
fprtexp: boolean; { print macro expansions }
fprtmac: boolean; { print macro being expanded }
fprtdef: boolean; { print definitions table }
fprtpln: boolean; { print processed lines }
fcppcmt: boolean; { allow C++ style comments }

{ functions this module }

procedure error(e: errcod; view s: string); forward;
procedure opnsrc(view n: string); forward;
function seof: boolean; forward;
function sendlin: boolean; forward;
function schkchr: char; forward;
procedure sgetchr; forward;
procedure sskpspc; forward;
procedure ssavpos; forward;
procedure srstpos; forward;
function hashc(view s: string; add: integer; maxv: integer): integer; forward;
function hash(view s: string; add: integer; maxv: integer): integer; forward;
procedure prtdef; forward;
procedure hdrdef(var f: text); forward;
procedure caldefs; forward;
procedure srtdef; forward;
procedure unrdef(var f: text); forward;
procedure regdef; forward;
procedure coindef(var f: text); forward;
procedure newnam(view s: string; var i: integer); forward;
procedure macalias; forward;
procedure outparmac(var f: text); forward;

private

const

maxlin  = 1000; { maximum size of input line }
maxfil  = 200;  { number of characters in a file name }
maxdef  = 1000; { number of define slots }
maxnam  = 1000; { number of name slots }
maxdir  = 200;  { maximum length of directive label }
deffld  = 30;   { field for defines in define table }

type

filinx  = 1..maxfil; { index for file names }
filnam  = packed array [filinx] of char; { a file name }
lininx = 1..maxlin;  { index for text line }
linbuf = packed array [lininx] of char; { a text line }
ifptr = ^ifrec; { pointer to if nesting record }
ifrec = record { if tracking record }

   val: integer; { value of if, 1 is active, 0 is not }
   next: ifptr   { next }

end;
fcbptr = ^fcbrec; { file control block pointer }
fcbrec = record { file control block }

   inpnam: filnam;  { name of file being processed }
   inpfil: text;    { input file }
   lininp: linbuf;  { input line buffer }
   linptr: integer; { index for line }
   linnum: integer; { line number }
   incmt:  boolean; { intraline comment }
   iftrk:  ifptr;   { if tracking stack }
   next:   fcbptr   { next entry in list }

end;
defppt = ^defpar; { pointer to definition parameter }
defpar = record { definition parameter }

   name: pstring; { name of parameter }
   next: defppt   { next entry }

end;
{ the definition database tracks all names in their original case }
defptr = ^defrec; { definition record pointer }
defrec = record { define value record }

   name:  pstring; { name of define variable }
   inst:  integer; { instance of same caseless spelling }
   sval:  pstring; { string  value of define (replacement text) }
   par:   defppt;  { parameters list }
   parf:  boolean; { has parameters (including zero) }
   equf:  boolean; { was able to calculate integer value error free }
   equv:  integer; { calculated equavalent value as integer }
   equs:  pstring; { calculated equivalent value as string }
   als:   boolean; { was an alias }
   next:  defptr   { next entry }

end;
{ the caseless names table tracks collisions between names based on case, or
  any other reason }
namptr = ^namrec; { name table record pointer }
namrec = record { name table record }

   name: pstring; { name (caseless) }
   inst: integer; { number of duplicates of this name }
   next: namptr   { next entry }

end;
  
{ operator types }
optype = (opnone,  { no operator }
          opplus,  { + }
          opminus, { - }
          optimes, { * }
          opdiv,   { / }
          opmod,   { % }
          opnequ,  { != }
          opltn,   { < }
          opgtn,   { > }
          oplequ,  { <= }
          opgequ,  { >= }
          opcln,   { : }
          opxor,   { ^ }
          opand,   { & }
          opland,  { && }
          oplnot,  { ! }
          opcomp,  { ~ }
          opshl,   { << }
          opshr,   { >> }
          opequ,   { == }
          opor,    { | }
          oplor,   { || }
          opcond); { ? }
opstr = packed array [1..2] of char; { string for operators }

fixed

oprtbl: packed array [optype] of opstr = array

   '  ',  { opnone   }    
   '+ ',  { opplus   }    
   '- ',  { opminus  }    
   '* ',  { optimes  }    
   '/ ',  { opdiv    }    
   '% ',  { opmod    }    
   '!=',  { opnequ   }    
   '< ',  { opltn    }    
   '> ',  { opgtn    }    
   '<=',  { oplequ   }    
   '>=',  { opgequ   }    
   ': ',  { opcln    }    
   '^ ',  { opxor    }    
   '& ',  { opand    }    
   '&&',  { opland   }    
   '! ',  { oplnot   }    
   '~ ',  { opcomp   }    
   '<<',  { opshl    }    
   '>>',  { opshr    }    
   '==',  { opequ    }    
   '| ',  { opor     }    
   '||',  { oplor    }    
   '? '   { opcond   }

end;       

var

srclst:  fcbptr;  { source fcb stack }
deftab:  array [1..maxdef] of defptr; { definitions table }
di:      1..maxdef; { index for that }
deflst:  defptr; { sorted define list }
namtab:  array [1..maxnam] of namptr; { names table }
ni:      1..maxnam; { index for that }
maxdnm:  integer; { maximum define name }
linptrs: integer; { save for line index }
c:       char;

procedure directive; forward; { process directive }
procedure clssrc; forward; { close current file }

{******************************************************************************

Process error

Prints the given error code and halts the encode.

******************************************************************************}

procedure error(e: errcod; view s: string);

begin

   write('*** Error: ');
   if srclst <> nil then begin

      write('[');
      write(output, srclst^.inpnam:0);
      write(':', srclst^.linnum:1, '] ')

   end;
   case e of { error }

      einltl:   writeln('Input line too large');
      einvdig:  writeln('Invalid digit');
      edigbrd:  writeln('Digit beyond radix');
      einvrft:  writeln('Invalid real format');
      eexptl:   writeln('Exponent too large');
      emisstr:  writeln('Missing string');
      eutmstr:  writeln('Unterminated string');
      eccnsgl:  writeln('Character constant not single character');
      eutmcmt:  writeln('Unterminated comment');
      einctl:   writeln('Include filename too long');
      eincnf:   writeln('Include file not found');
      einvsch:  writeln('Invalid symbol/character');
      enumovf:  writeln('Numeric overflow');
      edeftbf:  writeln('Define table full');
      erecmac:  writeln('Recursive macro invoked');
      edirmis:  writeln('No directive present');
      edirnf:   writeln('Directive not found');
      elabtl:   writeln('Label too long');
      emacexp:  writeln('Macro name expected');
      eparnf:   writeln('Parameter id expected');
      emacbm:   writeln('Macro duplicate define body does not match original');
      emacpm:   writeln('Macro duplicate define paramters do not match original');
      erpexp:   writeln(''')'' Expected');
      emendq:   writeln('Missing end quote');
      enegshc:  writeln('Negative shift count');
      eclnexp:  writeln(''':'' expected');
      emisif:   writeln('Matching ''if'' missing');
      emacpem:  writeln('Macro replacement parameter is empty');
      eparext:  writeln('Too many replacement parameters for macro');
      eidexp:   writeln('Identifier expected');
      einvfac:  writeln('Invalid factor');
      eifnst:   writeln('Unmatched ''#endif''');
      eprmexp:  writeln('Primary-expression not found');
      erbktexp: writeln(''']'' expected');
      escnexp:  writeln(''';'' expected');
      elpexp:   writeln('''('' expected');
      ewhlexp:  writeln('''while'' expected');
      einvtyp:  writeln('Invalid type-specifier');
      esymnf:   writeln('Symbol not found');
      easexp:   writeln('''='' expected');
      eendexp:  writeln('''}'' expected');
      einvdec:  writeln('Invalid declarator');
      eabsdec:  writeln('Invalid abstract declarator');
      einvdcl:  writeln('Invalid declaration');
      edupsym:  begin 

         write('Duplicate symbol ''');
         write(output, s:0);
         writeln('''')

      end;
      einvtnm:  writeln('Identifier does not designate type');
      etyprdf:  writeln('Attempt to redefine type');
      ecstdup:  writeln('''const'' in declaration more than once');
      etypdup:  writeln('Two or more data types in declaration');
      escldup:  writeln('Multiple storage classes in declaration');
      evoldup:  writeln('''volatile'' in declaration more than once');
      echratt:  writeln('Char used with short or long');
      elngdup:  writeln('''long'' specified twice on double');
      eredef:   writeln('Redefinition of type');
      elpidexp: writeln('''('' or identifier expected');
      earrfnc:  writeln('Cannot declare array of functions');
      efncfnc:  writeln('Cannot declare function returning function');
      eicstexp: writeln('Expression must be constant integer');
      ecstopr:  writeln('Operation not permitted for constant');
      ecstcas:  writeln('Constant must be cast to integer');
      eshftno:  writeln('Bad shift number');
      einvcls:  writeln('''auto'' or ''register'' used on top level declaration');
      eparsnf:  writeln('Parameter symbol not found');
      eparini:  writeln('Parameter has initalization');
      epardtp:  writeln('Parameter type was duplicated');
      efncexp:  writeln('Function declaration was expected');
      einvopt:  writeln('Invalid command line option');
      eoptnf:   writeln('Command line option not found');
      efilnf:   writeln('Source file not found');
      einvfil:  writeln('Invalid filename');
      efilexp:  writeln('Filename expected');
      einvexp:  writeln('Invalid expression');
      edattyp:  writeln('No type specified for data');
      ebgnexp:  writeln('''{'' expected');
      eempmac:  writeln('Macro list is empty for parametered macro');
      etidexp:  writeln('Type id expected');
      einvtpc:  writeln('Type combination invalid');
      etypmch:  begin

         write('Type does not match original definition ''');
         write(output, s:0);
         writeln('''')

      end;
      enostcl:  writeln('No storage class allowed here');
      ecmpnst:  writeln('Types nested to deep (or loop exists)');
      einvmod:  writeln('Invalid module name');
      einscmd:  writeln('Invalid instruction file command');
      einscnf:  begin

         write('Instruction file command ''');
         write(output, s:0);
         writeln(''' not found')

      end;
      etypsnf:  writeln('Symbol for type not found');
      ecatnf:   writeln('''catalog'' file not found');
      emodnnf:  begin

         write('No module export name found to match symbol ''');
         write(output, s:0);
         writeln('''')

      end;
      esys1, esys2, esys3, esys4, esys5, esys6, esys7, esys8, esys9, esys10,
      esys11, esys12, esys13, esys14, esys15, esys16, esys17, esys18, esys19,
      esys20, esys21, esys22, esys23, esys24, esys25, esys26, esys27, esys28,   
      esys29, esys30, esys31, esys32, esys33, esys34, esys35, esys36, esys37,   
      esys38, esys39, esys40, esys41, esys42, esys43, esys44, esys45, esys46,
      esys47, esys48, esys49, esys50, esys51, esys52, esys53, esys54, esys55,
      esys56, esys57, esys58, esys59, esys60, esys61, esys62, esys63, esys64,
      esys65, esys66, esys67, esys68, esys69, esys70, esys71, esys72, esys73,
      esys74, esys75, esys76, esys77, esys78, esys79, esys80, esys81, esys82,
      esys83, esys84, esys85, esys86, esys87, esys88, esys89, esys90, esys91,
      esys92,
      esys93: writeln('System fault #', ord(e)-ord(esys1)+1:1, 
                      ' notify software vendor');

   end;
   terminate { end program }

end;

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

function hashc(view s:    string;  { label to find hash for }
                   add:  integer; { stirring parameter }
                   maxv: integer) { maximum value returned }
             : integer;          { return hash }

var i, r : integer;

begin

   r := 0;
   for i := 1 to max(s) do if s[i] <> ' ' then r := r + ord(s[i]) + add;
   hashc := r mod maxv + 1

end;

{******************************************************************************

Find label hash function without case

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
   for i := 1 to max(s) do if lcase(s[i]) <> ' ' then
      r := r + ord(lcase(s[i])) + add;
   hash := r mod maxv + 1

end;

{*******************************************************************************

Place new define entry

Places a new define entry into the table, and returns a pointer to it.
The define entry is placed onto the list for which it hashes to.

*******************************************************************************}

procedure newdef(view s: string; var p: defptr);

var di: 1..maxdef; { index for table }

begin

   new(p); { get a new definition entry }
   copyp(p^.name, s); { place label }
   { set if new maxium length }
   if max(p^.name^) > maxdnm then maxdnm := max(p^.name^);
   di := hashc(s, 0, maxdef); { get chain index }
   p^.next := deftab[di]; { push to that list }
   deftab[di] := p;
   p^.sval := nil; { clear replacement text }
   p^.par := nil; { set no parameters list }
   p^.parf := false;
   p^.inst := 1; { set 1st instance }
   p^.equf := false; { set no calculated integer value }
   p^.equv := 0; { clear just to be neat }
   p^.equs := nil; { set no calculated string }
   p^.als := false { set not alias }

end;

{*******************************************************************************

Find define entry

Finds a define entry by name. Returns zero if the entry is not found.

*******************************************************************************}

function fnddef(view s: string): defptr;

var p, r: defptr; { pointers for definitons table }

begin
   
   r := nil; { clear result pointer }
   p := deftab[hashc(s, 0, maxdef)]; { index the top entry }
   while p <> nil do begin { traverse chain }

      if compcp(s, p^.name^) then begin { entry found }

         r := p; { place result pointer }
         p := nil { nix search pointer }

      end else p := p^.next { index next entry }

   end;
   fnddef := r { return result pointer }

end;

{*******************************************************************************

Delete define entry

Removes the given define entry from the definition table.

*******************************************************************************}

procedure deldef(p: defptr);

var di: 1..maxdef; { index for table }
    dp: defptr;    { entry pointer }
    pp: defppt;    { parameter pointer }

begin

   di := hashc(p^.name^, 0, maxdef); { get chain index }
   if deftab[di] = p then deftab[di] := p^.next { gap from top }
   else begin { search midlist }

      { find uplist entry }
      dp := deftab[di]; { index top }
      while (dp^.next <> p) and (dp^.next <> nil) do dp := dp^.next;
      if dp^.next = nil then error(esys37, ''); { should not happen }
      dp^.next := p^.next { gap out of list }

   end;
   dispose(p^.sval); { release macro string }
   dispose(p^.name); { release name string }
   while p^.par <> nil do begin { release parameters }

      pp := p^.par; { index entry }
      p^.par := pp^.next; { gap out }
      dispose(pp^.name); { release name }
      dispose(pp) { release entry }

   end;
   dispose(p) { release entry }

end;

{*******************************************************************************

Find names entry

Returns a pointer to a matching names entry, or nil.
Find define entry

Finds a define entry by name. Returns zero if the entry is not found.

*******************************************************************************}

function fndnam(view s: string): namptr;

var p, r: namptr; { pointers for definitons table }

begin
   
   r := nil; { clear result pointer }
   p := namtab[hash(s, 0, maxnam)]; { index the top entry }
   while p <> nil do begin { traverse chain }

      if compp(s, p^.name^) then begin { entry found }

         r := p; { place result pointer }
         p := nil { nix search pointer }

      end else p := p^.next { index next entry }

   end;
   fndnam := r { return result pointer }

end;

{*******************************************************************************

Place new names entry

Searches for an existing name in the names table, and if one is not found, then
it is created and given instance 1. If it IS found, then the instance number is
incremented. Returns the instance number in a passed variable.
The names entries are used to find collisions between names, and case is not
used to differentiate names. However, the names can collide for any reason.

*******************************************************************************}

procedure newnam(view s: string; var i: integer);

var ni: 1..maxnam; { index for table }
    p:  namptr;    { pointer for name entries }

begin

   p := fndnam(s); { find previous name }
   if p = nil then begin { no name, enter new one }

      new(p); { get a new definition entry }
      copyp(p^.name, s); { place label }
      ni := hash(s, 0, maxnam); { get chain index }
      p^.next := namtab[ni]; { push to that list }
      namtab[ni] := p;
      p^.inst := 1 { set 1st instance }

   end else p^.inst := p^.inst+1; { increment previous instance }
   i := p^.inst { place instance }

end;

{******************************************************************************

Replace trigraph sequences

Replaces '??' trigraph sequences in the input buffer.

******************************************************************************}

procedure trigraph(var s: string);

var i, x: integer;
    qcnt: integer; { '?' count }
    c:    char;

begin

   qcnt := 0; { clear '?' count }
   i := 1; { index 1st character }
   while i <= max(s) do begin { traverse line }

      c := s[i]; { get next character }
      if qcnt = 2 then begin { possible trigraph }

         if c in ['=', '/', '''', '(', ')', '!', '<', '>','-'] then begin

            { trigraph }
            i := i-2; { back up to start }
            case c of { trigraph character }

               '=':  s[i] := '#';
               '/':  s[i] := '\\';
               '''': s[i] := '^';
               '(':  s[i] := '[';
               ')':  s[i] := ']';
               '!':  s[i] := '|';
               '<':  s[i] := '{';
               '>':  s[i] := '}';   
               '-':  s[i] := '~'

            end;
            { move remaining characters down to cover the trigraph }
            for x := i+1 to max(s)-2 do s[x] := s[x+2]
            
         end;
         qcnt := 0 { clear count }

      end else begin
 
         if c = '?' then qcnt := qcnt+1 { count '?' characters }
         else qcnt := 0 { clear count }

      end;
      i := i+1 { next }

   end

end;

{******************************************************************************

Remove start of comment in line

Removes a comment or comment starting sequence in the source line. Flags if the
comment was unterminated on the line. If this occurs, input lines should be
skipped until the termination of the comment is found.

******************************************************************************}

procedure remscmt;

var i:      integer; { index for string }
    lasts:  boolean; { last was '/' }
    endcmt: boolean; { end of comment flag }
    endstr: boolean; { end of string flag }
    force:  boolean; { force flag }
    lastt:  boolean; { last was '*' }

begin

   lasts := false; { set no '/' }
   i := 1; { index 1st character }
   while i <= maxlin do begin { traverse }

      if srclst^.lininp[i] = '"' then begin { quote, skip }

         endstr := false; { set not end of string }
         force := false; { set no force active }
         repeat

            i := i+1; { next }
            if i < maxlin then begin { not past end }

               { check end of string without a force }
               if (srclst^.lininp[i] = '"') and not force then endcmt := true;
               force := srclst^.lininp[i] = '\\' { set force status }

            end

         { until end of string or comment stops }
         until (i > maxlin) or endcmt

      end else if srclst^.lininp[i] = '''' then begin { quote, skip }

         endstr := false; { set not end of string }
         force := false; { set no force active }
         repeat

            i := i+1; { next }
            if i < maxlin then begin { not past end }

               { check end of string without a force }
               if (srclst^.lininp[i] = '''') and not force then endcmt := true;
               force := srclst^.lininp[i] = '\\' { set force status }

            end

         { until end of string or comment stops }
         until (i > maxlin) or endcmt
     
      end else if (srclst^.lininp[i] = '/') and lasts and fcppcmt then
         begin { // comment }

         { clear the remainder of the line }
         for i := i-1 to maxlin do srclst^.lininp[i] := ' ';
         i := maxlin { terminate }

      end else if (srclst^.lininp[i] = '*') and lasts then begin { /* comment }

         srclst^.incmt := true; { set unterminated by default }
         endcmt := false; { no comment termination }
         lastt := false; { set no '*' }
         srclst^.lininp[i-1] := ' '; { blank out comment }
         srclst^.lininp[i] := ' '; { blank out comment }
         repeat

            i := i+1; { next }
            if i < maxlin then begin { not past end }

               if (srclst^.lininp[i] = '/') and lastt then begin

                  { end comment found }
                  endcmt := true; { set found }
                  srclst^.incmt := false { set is terminated }

               end;
               lastt := srclst^.lininp[i] = '*'; { set last '*' status }
               srclst^.lininp[i] := ' ' { blank out comment }

            end

         { until end of string or comment stops }
         until (i > maxlin) or endcmt

      end else begin

         if srclst^.lininp[i] = '/' then lasts := true { set '/' found }
         else lasts := false; { set no '/' found }

      end;
      i := i+1 { next }

   end

end;

{******************************************************************************

Remove end of comment in line

Searches for the end of a comment in the given line. Returns a flag variable
true if it is found, and removes all the text in the line up to and including
the comment termination. Note that quotes are not obeyed in comments.

******************************************************************************}

procedure remecmt;

var i, x:  integer; { index for string }
    lastt: boolean; { last was '*' }

begin

   i := 1; { set 1st character }
   lastt := false; { set '*' not last}
   while i < maxlin do begin

      if (srclst^.lininp[i] = '/') and lastt then begin { end found }

         x := 1; { set 1st location on line }
         for i := i+1 to maxlin do begin { move line down }

            srclst^.lininp[x] := srclst^.lininp[i]; { move character }
            x := x+1 { next }

         end;
         srclst^.incmt := false; { set not in comment }
         i := maxlin { flag end }

      end else begin

         lastt := srclst^.lininp[i] = '*'; { set last '*' status }
         i := i+1

      end

   end

end;

{******************************************************************************

Remove '##' characters from macro replacement line

Processes the '##' removal step for macros. We find each instance of '##' in
the given line. When found, the spaces to the left and the spaces to the right,
along with the '##' itself, are eliminated. This results in the effective
concatenation of arguments.

******************************************************************************}

procedure rempnd(var mr: string);

var tmp:  linbuf; { label holder }
    i, j: lininx; { index for that }
    lpnd: boolean; { last was pound }

begin

   clears(tmp); { clear result }
   i := 1; { index start of both strings }
   j := 1;
   lpnd := false; { set no last '#' }
   while i < max(mr) do begin { transfer characters }

      if mr[i] <> '#' then begin { place }

         tmp[j] := mr[i]; { move character }
         j := j+1; { next }
         i := i+1

      end else begin

         if lpnd then begin { '##' }

            i := i+1; { skip '#' }
            { remove spaces left }
            while (j > 1) and (tmp[j-1] = ' ') do j := j-1;
            { remove spaces right }
            while (i < max(mr)) and (mr[i] = ' ') do i := i+1;
            lpnd := false { set no last '#' }

         end else begin

            lpnd := true; { set last was '#' }
            i := i+1

         end

      end

   end;
   copy(mr, tmp) { copy back result }

end;

{******************************************************************************

Force quotes

Places '\' forces before quotes. Each quote ('"') found in the given string
has a '\' placed before it.

******************************************************************************}

procedure frcqut(var s: string);

var buf: linbuf; { destination buffer }
    x, i: lininx; { indexes for line }

begin

   if max(s) > maxlin then error(einltl, ''); { line too long }
   clears(buf); { clear result buffer }
   x := 1; { set 1st character of result }
   for i := 1 to len(s) do begin { process }

      if x > maxlin then error(einltl, ''); { line too long }
      if s[i] = '"' then begin

         buf[x] := '\\'; { place escape }
         x := x+1; { next }
         if x > maxlin then error(einltl, '') { line too long }

      end;
      buf[x] := s[i]; { transfer character to result }
      x := x+1 { next }

   end;
   copy(s, buf) { copy back to result }

end; 

{******************************************************************************

Replace macro parameters

Accepts the macro define entry, the caller string, caller position just before
the '(', and the replacement macro string. Each of the parameters for the macro
are parsed from the caller string for form a list of parameter replacements.
Then, each parameter is found in the replacement text and the substitution
made.

******************************************************************************}

procedure reppar(mp: defptr; var cs: string; ci: integer; var mv: string;
                 var macend: integer);

var pl, pp, pp1, lp: defppt;  { parameter pointers }
    par:             linbuf;  { label holder }
    i, s:            lininx;  { index for that }
    parenc:          integer; { paren nesting count }

{ check next character }

function chkchr: char;

var c: char;

begin

   c := ' ';
   if ci < max(cs) then c := cs[ci];
   chkchr := c

end;

{ skip spaces }

procedure skpspc;

begin

   while (chkchr = ' ') and (ci < max(cs)) do ci := ci+1 { skip spaces }

end;

{ load next label in substitute text }

procedure getlab;

var j: lininx; { index for parameter label }

begin

   clears(par); { clear result }
   while not (mv[i] in ['_', '0'..'9', 'a'..'z', 'A'..'Z']) and
         (i < maxlin) do i := i+1;
   s := i; { save starting position }
   j := 1; { set 1st position of label }
   while (mv[i] in ['_', '0'..'9', 'a'..'z', 'A'..'Z']) and
         (i < maxlin) do begin

      par[j] := mv[i]; { place character }
      i := i+1; { next }
      j := j+1

   end

end;

{ check parameter and replace text }

procedure replab;

var pp, fp, frp, rp: defppt;    { parameter pointers }
    tmp, tmp1:       linbuf;    { temp line buffers }
    lpar:            0..maxlin; { length of parameter }
    quote:           boolean;   { quote flag }

begin

   { search for matching parameter }
   pp := mp^.par; { index top of parameter list }
   fp := nil; { clear found }
   rp := pl; { index top of replacements }
   while pp <> nil do begin { traverse }

      if compcp(pp^.name^, par) then begin

         fp := pp; { found matching parameter }
         frp := rp

      end;
      pp := pp^.next; { next }
      if rp <> nil then rp := rp^.next { next in replacements if exists }

   end;
   if (fp <> nil) and (frp <> nil) then begin { found match }

      quote := false; { set no quoting }
      if s > 1 then begin { label not at start }

         quote := mv[s-1] = '#'; { set quote status }
         { remove '##' case }
         if s > 2 then if mv[s-2] = '#' then quote := false

      end;
      if s+max(fp^.name^) <= len(mv) then { get all after }
         extract(tmp, mv, s+max(fp^.name^), len(mv))
      else clears(tmp);
      copy(tmp1, frp^.name^); { make copy of parameter }
      if quote then frcqut(tmp1); { if quoted, place forces for embedded quotes }
      lpar := len(tmp1); { get length for that }
      extract(mv, mv, 1, s-1); { get all before }
      if quote then insert(mv, '"', s); { place leading quote }
      insert(mv, tmp1, s+ord(quote)); { add macro contents }
      { place trailing quote }
      if quote then insert(mv, '"', s+lpar+1);
      insert(mv, tmp, s+lpar+2*ord(quote)); { add all after }
      i := s { restore position to start of parameter }

   end

end;

begin

   { parse macro parameters from line }
   skpspc; { skip leading spaces }
   if chkchr <> '(' then error(esys38, ''); { no parameters }
   { gather parameters list }
   ci := ci+1; { skip '(' }
   pl := nil; { clear output parameters list }
   pp := mp^.par; { index top of parameters list }
   skpspc; { skip spaces }
   if chkchr = ')' then begin { empty list }

      if pp <> nil then error(eempmac, ''); { empty macro list }
      ci := ci+1; { skip ')' }
      macend := ci { set new macro end }

   end else begin { parameters present }

      repeat { parse parameters }

         if pp = nil then error(eparext, ''); { no more parameters }
         skpspc; { skip spaces }
         { check any macro parameter content }
         if (chkchr in [',', ')']) or (ci > max(cs)) then error(emacpem, '');
         clears(par); { clear result }
         i := 1; { set 1st character }
         parenc := 0; { clear paren nesting count }
         while not ((chkchr in [',', ')']) and not (parenc > 0)) and
               (ci <= max(cs)) do begin

            { process paren nesting }
            if chkchr = '(' then parenc := parenc+1;
            if chkchr = ')' then parenc := parenc-1;
            par[i] := chkchr; { place character }
            i := i+1; { next }
            ci := ci+1 { next character }

         end;
         { place parameter string }
         new(pp1); { get a new parameter }
         copyp(pp1^.name, par); { place as name }
         pp1^.next := nil; { set no next }
         if pl = nil then pl := pp1 { place as list head }
         else lp^.next := pp1; { insert to list end }
         lp := pp1; { set new last entry }
         pp := pp^.next; { next parameter }
         c := chkchr; { get next }
         if c = ',' then ci := ci+1 { skip ',' }
            
      until (ci > max(cs)) or (c <> ',');
      if chkchr <> ')' then error(erpexp, ''); { should be ')' }
      ci := ci+1; { skip ')' }
      macend := ci; { set new macro end }
      { now perform replacements }
      i := 1; { index 1st character of replacement text }
      while i < maxlin do begin { parse substitute text }

         getlab; { get next label }
         if par[1] <> ' ' then replab

      end

   end

end;

{******************************************************************************

Process macro replacement

Replaces a macro in the given line. The macro define entry is given, and the
string to replace it in, then the position of the macro start. The string must
be large enough to contain the complete macro.

******************************************************************************}

procedure prcmac(mp: defptr; var s: string; i: integer);

var x:                     integer; { index }
    linend, mcont, linsav: linbuf;  { temp line buffer }
    macend:                integer; { end of macro call }

begin

   x := i+max(mp^.name^); { index after macro name }
   while (x < max(s)) and (s[x] = ' ') do x := x+1; { skip spaces }
   { check if macro parameter/no parameter state matches }
   if mp^.parf and (s[x] <> '(') then mp := nil;
   { a macro with parameters will not match a macro name without parameters,
     but a macro with no parameters will match any }
   if mp <> nil then begin { state matches }

      if fprtmac then { print macro being expanded }
         writeln('Expanding macro: ', mp^.name^);
      copy(linsav, s); { save copy of line }
      copy(mcont, mp^.sval^); { copy substitute line to temp }
      macend := i+max(mp^.name^); { set macro end for no parameters }
      if mp^.parf then { replace macro parameters }
         reppar(mp, s, x, mcont, macend);
      rempnd(mcont); { remove '#' characters from replacement }
      if macend <= len(s) then { get all after }
         extract(linend, s, macend, len(s))
      else clears(linend);
      extract(s, s, 1, i-1); { get all before }
      insert(s, mcont, i); { add macro contents }
      insert(s, linend, i+len(mcont)); { add all after }
      { if the line ends up being the same, this macro will get expanded
        forever }
      if compcp(linsav, s) then error(erecmac, ''); { recursive macro }

   end

end;

{******************************************************************************

Process "defined" macro replacement

Replaces macros of the form:

defined id
defined (id)

The macro is replaced with 1L if the id is defined, otherwise 0L.

******************************************************************************}

procedure prcdef(var s: string; i: integer; var fi: integer);

var val:                   boolean; { defined val }
    lab:                   linbuf;  { label holder }
    mp:                    defptr;  { definition entry pointer }
    linend, mcont, linsav: linbuf;  { temp line buffer }
    ps:                    integer; { position save }

{ check next character }

function chkchr: char;

var c: char;

begin

   c := ' ';
   if i < max(s) then c := s[i];
   chkchr := c

end;

{ skip spaces }

procedure skpspc;

begin

   while (chkchr = ' ') and (i < max(s)) do i := i+1 { skip spaces }

end;

{ get label }

procedure getlab;

var j: lininx; { index for parameter label }

begin

   clears(lab); { clear result }
   j := 1; { set 1st position of label }
   if chkchr in ['_', 'a'..'z', 'A'..'Z'] then { found }
      while chkchr in ['_', '0'..'9', 'a'..'z', 'A'..'Z'] do begin { found }

      lab[j] := chkchr; { place character }
      i := i+1; { next }
      j := j+1

   end

end;

begin

   ps := i; { set position at "define" }
   { skip label }
   while chkchr in ['_', 'a'..'z', 'A'..'Z', '0'..'9'] do i := i+1;
   skpspc; { skip spaces }
   if chkchr = '(' then begin { (id) }

      i := i+1; { skip '(' }
      skpspc; { skip spaces }
      getlab;
      if len(lab) = 0 then error(eidexp, '');
      skpspc; { skip spaces }
      if chkchr <> ')' then error(erpexp, '');
      i := i+1 { skip '(' }

   end else begin { id }

      skpspc; { skip spaces }
      getlab;
      if len(lab) = 0 then error(eidexp, '')

   end;
   mp := fnddef(lab); { find possible macro }
   val := mp <> nil; { set defined status }
   { set macro value }
   if val then copy(mcont, '1L') else copy(mcont, '0L');
   { expand macro }
   copy(linsav, s); { save copy of line }
   if i <= len(s) then { get all after }
      extract(linend, s, i, len(s))
   else clears(linend);
   extract(s, s, 1, ps-1); { get all before }
   insert(s, mcont, ps); { add macro contents }
   insert(s, linend, ps+2); { add all after }
   fi := ps+2; { set follow index }
   if compcp(linsav, s) then error(erecmac, '') { recursive macro }

end;

{******************************************************************************

Process replacement string macro

A general purpose macro replacer, takes the given string and replaces the id
in the given string and position with the replacement string provided.

******************************************************************************}

procedure prcrstr(var s: string; i: integer; view rs: string; var fi: integer);

var linend, linsav: linbuf;  { temp line buffer }
    ps:             integer; { position save }
    lrs:            integer; { length of replacement string }

{ check next character }

function chkchr: char;

var c: char;

begin

   c := ' ';
   if i < max(s) then c := s[i];
   chkchr := c

end;

begin

   lrs := len(rs); { find length of replacement string }
   ps := i; { set position at "define" }
   { skip label }
   while chkchr in ['_', 'a'..'z', 'A'..'Z', '0'..'9'] do i := i+1;
   { expand macro }
   copy(linsav, s); { save copy of line }
   if i <= len(s) then { get all after }
      extract(linend, s, i, len(s))
   else clears(linend);
   extract(s, s, 1, ps-1); { get all before }
   insert(s, rs, ps); { add macro contents }
   insert(s, linend, ps+lrs); { add all after }
   fi := ps+lrs; { place follow index }
   if compcp(linsav, s) then error(erecmac, '') { recursive macro }

end;

{******************************************************************************

Replace identifier in "if" mode

Directive "if" processing requires all unmatched identifiers be replaced with
"0L". This routine replaces each incidence of an unmatched id with 0L. Expects
the string to replace within, and the index at the start of the id.

******************************************************************************}

procedure repidn(var s: string; i: integer; var fi: integer);

var linend: linbuf;  { temp line buffer }
    ps:     integer; { position save }

begin

   ps := i; { set position at "define" }
   { skip over id }
   while (i < max(s)) and (s[i] in ['_', 'a'..'z', 'A'..'Z', '0'..'9']) do
      i := i+1;
   { expand macro }
   if i <= len(s) then { get all after }
      extract(linend, s, i, len(s))
   else clears(linend);
   extract(s, s, 1, ps-1); { get all before }
   insert(s, '0L', ps); { place "0L" id replacement }
   insert(s, linend, ps+2); { add all after }
   fi := ps+2 { set follow index }

end;

{******************************************************************************

Scan for macros

Scans and replaces macros in the given string. The string is scanned for labels
which are not in quoted sequences, and if there is a macro coresponding to the
label, a macro replacement occurs.
Accepts a special flag for "if" macro processing. This flag enables the special
macro "defined", and makes identifiers that fail to match as macros become
0L. These are the standard rules for "if" macro special processing (ANSI).

******************************************************************************}

procedure macscn(var s: string; ifp: boolean);

var macn:        linbuf;    { macro name }
    macl:        0..maxlin; { size of macro label }
    lmacn:       linbuf;    { last macro name }
    i:           integer;   { index }
    dp:          defptr;    { entry pointer }
    sp:          0..maxlin; { starting position of macro }
    lsp:         0..maxlin; { starting position of last macro }
    inquote,
    inquotes:    boolean;   { in quoted sequence }
    tmps, tmps1: packed array [1..100] of char; { temp string }

{ check macro candidate }

procedure chkmac;

begin

   if macl > 0 then begin { buffer has contents }

      if macn[1] in ['_', 'a'..'z', 'A'..'Z'] then begin

         { check for a repeat of last macro, and ignore if so }
         if not (compcp(lmacn, macn) and (sp = lsp)) then begin
        
            { check if is the "defined" macro, and process if so }
            if compcp(macn, 'defined') and ifp then 
               prcdef(s, sp, i) { process replacement }
            else if compcp(macn, '__LINE__') then begin

               ints(tmps, srclst^.linnum); { convert line number to string }
               prcrstr(s, sp, tmps, i) { place }

            end else if compcp(macn, '__FILE__') then begin

               copy(tmps, '"'); { set starting quote }
               cat(tmps, srclst^.inpnam); { add filename }
               cat(tmps, '"'); { set ending quote }
               prcrstr(s, sp, tmps, i) { set file being processed }

            end else if compcp(macn, '__DATE__') then begin

               { date, note that this definition is not perfectly standard
                 in format }
               dates(tmps1, local(time)); { find string for local date }
               copy(tmps, '"'); { set starting quote }
               cat(tmps, tmps1); { add date }
               cat(tmps, '"'); { set ending quote }
               prcrstr(s, sp, tmps, i) { place }

            end else if compcp(macn, '__TIME__') then begin

               { time, note that this definition is not perfectly standard
                 in format }
               times(tmps1, local(time)); { find string for local date }
               copy(tmps, '"'); { set starting quote }
               cat(tmps, tmps1); { add time }
               cat(tmps, '"'); { set ending quote }
               prcrstr(s, sp, tmps, i) { place }

            end else if compcp(macn, '__STDC__') then
               prcrstr(s, sp, '1', i) { indicate standard conforming }
            else begin { other macros }

               dp := fnddef(macn); { find possible macro }
               if dp <> nil then begin

                  prcmac(dp, s, sp); { process macro expansion }
                  i := sp-1 { reset to start of macro for rescan (-1) }

               end else if ifp then repidn(s, sp, i) { in "if" mode, replace id }

            end

         end;
         copy(lmacn, macn); { set last macro processed }
         lsp := sp

      end;
      macl := 0; { clear macro }
      clears(macn);
      sp := 0 { set no start position }

   end

end;

begin

   clears(lmacn); { clear last macro name }
   lsp := 0;
   i := 1; { set 1st position }
   macl := 0; { clear macro length }
   clears(macn); { clear macro candidate }
   sp := 0; { set no start position }
   inquote := false; { set not in quote }
   inquotes := false;
   while i < max(s) do begin { look for ids }

      if (s[i] in ['_', 'a'..'z', 'A'..'Z', '0'..'9']) and 
         not (inquote or inquotes) then begin

         { is a possible macro label character }
         macl := macl+1; { count characters }
         macn[macl] := s[i]; { place character }
         if sp = 0 then sp := i { set starting position of macro name }

      end else begin

         if s[i] = '"' then inquote := not inquote; { flip quoting status }
         if s[i] = '''' then inquotes := not inquotes; { flip quoting status }
         if s[i] = '\\' then i := i+1; { force, skip further character }
         chkmac { check macro candidate }

      end;
      i := i+1 { next }

   end;
   chkmac { check macro candidate }

end;

{******************************************************************************

Load input line

Loads the next line to the input buffer. Loads and concatenates multiple force
lines. Then, a macro expansion is performed on the line. Resets the line
position.

******************************************************************************}

procedure loadlin; { file control block }

var ovf:       boolean; { overflow flag }
    tmpin:     linbuf;  { temp line buffer }
    il:        integer; { line length }
    lineforce: boolean; { line forcing flag }

begin


   clears(srclst^.lininp); { clear input line }
   if not eof(srclst^.inpfil) then repeat { force lines }

      lineforce := false; { set no line force active }
      reads(srclst^.inpfil, tmpin, ovf); { get next line }
      if ovf then error(einltl, ''); { overflow }
      readln(srclst^.inpfil);
      srclst^.linnum := srclst^.linnum+1; { count lines }
      if fprtlin then begin { list incoming lines }

         write(srclst^.linnum:1, ': ');
         write(output, tmpin:0);
         writeln

      end;
      trigraph(tmpin); { replace trigraphs }
      il := len(tmpin); { get line length }
      if il > 0 then begin { line not empty }

         if tmpin[il] = '\\' then begin

            { force line ending }
            tmpin[il] := ' '; { knock out ending }
            lineforce := true { set line was forced }

         end

      end;
      { check overflows }
      if il+len(srclst^.lininp) > maxlin then error(einltl, '');
      { concatenate to result }
      insert(srclst^.lininp, tmpin, len(srclst^.lininp)+1)

   until not lineforce or eof(srclst^.inpfil); { until no line force ending }
   srclst^.linptr := 1; { reset line pointer }

end;

{******************************************************************************

Check directive line

Checks if the line in the buffer contains a directive. Returns true if so.
A directive line is a line that contains a '#' with zero or more spaces in
front of it.

******************************************************************************}

function hasdir: boolean;

var i, x: integer;  { line indexes }
    df:   boolean ; { directive found flag }

begin

   df := false; { set no directive found }
   { check directive line }
   x := 0; { find first non-space }
   for i := 1 to maxlin do if (x = 0) and (srclst^.lininp[i] <> ' ') then
      x := i; { found }
   if x > 0 then if srclst^.lininp[x] = '#' then df := true; { found }
   hasdir := df { return result }

end;

{******************************************************************************

Get next input line

Gets a single line from the input. Processes directives by looking for any
line with "#" as the first character. That is sent to the directive handler,
and then the line is skipped.
Macros are expanded in lines that are to be returned (not directives).

******************************************************************************}

procedure sgetlin;

var direct: boolean; { directive encountered flag }
    eoffil: boolean; { eof in file }
    cmpbuf: linbuf;  { compare save for line }

begin

   { unstack any terminated files }
   repeat

      eoffil := eof(srclst^.inpfil); { get eof status on input file }
      if eoffil then clssrc; { close terminated file }

   until (srclst = nil) or not eoffil; { not end this file, or all files end }
   if srclst <> nil then begin { not at files end }

      repeat { read lines possibly containing directives }

         direct := false; { set not a directive }
         repeat

            loadlin; { load possible extended line }
            if srclst^.incmt then remecmt

         { keep reading until clear line or eof is found }
         until not srclst^.incmt or eof(srclst^.inpfil); 
         { remove comment or comment leader }
         remscmt;
         { check directive line }
         if hasdir then begin { process directive }

            direct := true; { set directive processed }
            directive { perform up call for directive }

         end

      until not direct or eof(srclst^.inpfil); { not a directive line, or eof }
      { process macros on line }
      if not eof(srclst^.inpfil) then begin

         copy(cmpbuf, srclst^.lininp); { save a copy of the line }
         macscn(srclst^.lininp, false); { perform replacement }
         if not compc(cmpbuf, srclst^.lininp) and fprtexp then begin

            { line has changed, and expansions are to be printed }
            write(srclst^.linnum:1, '> ');
            write(output, srclst^.lininp:0);
            writeln

         end
         

      end

   end;
   { check print processed lines }
   if fprtpln and (srclst <> nil) and not eoffil then begin

      write(srclst^.linnum:1, '+ ');
      write(output, srclst^.lininp:0);
      writeln

   end

end;

{******************************************************************************

Check end of line

Simply checks if the input position is beyond the current end of line.

******************************************************************************}

function sendlin: boolean; { end of line status }

var el: boolean; { end of line flag }

begin

   if srclst = nil then el := true { set end of line if end of files }
   else el := srclst^.linptr > maxlin; { else set if line pointer past end }
   sendlin := el

end;

{******************************************************************************

Check eof

Checks if the end of the input buffer and the source file has been reached.

******************************************************************************}

function seof: boolean;

var ef: boolean;

begin

  ef := true; { default eof true }
  { get eof status }
  if srclst <> nil then ef := eof(srclst^.inpfil);
  { true eof is the end of line, and end of file, and no more files } 
  seof := sendlin and ef and (srclst = nil)

end;

{******************************************************************************

Check next input character

The next character in the input buffer is returned. No advance is made from the
current position (succesive calls to this procedure will yeild the same
character).

******************************************************************************}

function schkchr: char;    { current input character }

var c: char; { result }

begin

   if sendlin then c := ' ' { just return endless spaces }
   { else return the next character at the input pointer }
   else c := srclst^.lininp[srclst^.linptr];
   schkchr := c { return result }

end;

{******************************************************************************

Skip input character

Causes the current input character to be skipped, so that the next schkchr call
will return the next character. If we are at the end of the line, no action
will take place (will not advance beyond end of line).

******************************************************************************}

procedure sgetchr;

begin

   if srclst <> nil then begin { source stack not nil }

      if srclst^.linptr <= maxlin then { process advance }
         srclst^.linptr := srclst^.linptr+1 { advance one character }

   end

end;

{******************************************************************************

Skip input spaces or controls

Skips the input position past any spaces or controls. Will skip the end of
line, loading the next line from the input. The view of the input is for each
line to be terminated by an infinite series of blanks, which only this routine
will cross.

******************************************************************************}

procedure sskpspc;

begin

  repeat

     { skip any spaces }
     while ((schkchr <= ' ') or (schkchr = '#')) and not sendlin do
        sgetchr;
     if sendlin then sgetlin { get a new line }

   until seof or (schkchr > ' ') { eof or non-space/control }

end;                  

{******************************************************************************

Skip input spaces or controls on single line

As sskpspc, but does not pass the line end.

******************************************************************************}

procedure sskpspcl;

begin

   { skip any spaces }
   while (schkchr <= ' ') and not sendlin do sgetchr;

end;                  

{******************************************************************************

Save current line position

Saves the current line position. The current line position is only valid as
long as the current line is not removed from the buffer. The sendlin function
must be used to ensure this.

******************************************************************************}

procedure ssavpos;

begin

   linptrs := srclst^.linptr { save position }

end;

{******************************************************************************

Restore current line position

Restores the previously saved line position. The line position must have been
previously saved by ssavpos.  The current line position is only valid as
long as the current line is not removed from the buffer. The sendlin function
must be used to ensure this.

******************************************************************************}

procedure srstpos;

begin

   srclst^.linptr := linptrs { restore position }

end;

{******************************************************************************

Internal open source file

Allocates the file control block, opens the file, then loads the first tolken.
This is the same as the external version, but does not perform a sgetlin on the
file.

******************************************************************************}

procedure iopnsrc(view n: string);

var f: fcbptr; { fcb entry }

begin

   new(f); { get a new fcb }
   f^.next := srclst; { push onto source list }
   srclst := f;
   assign(srclst^.inpfil, n); { place filename }
   reset(srclst^.inpfil); { open file }
   srclst^.linnum := 0; { clear line number }
   srclst^.incmt := false; { set no intraline comment }
   srclst^.iftrk := nil; { clear if tracking stack }
   copy(srclst^.inpnam, n) { place filename }

end;

{******************************************************************************

Open source file

Allocates the file control block, opens the file, then loads the first tolken.

******************************************************************************}

procedure opnsrc(view n: string);

begin

   iopnsrc(n); { open the file }
   sgetlin { get 1st line in file }

end;

{******************************************************************************

Close source file

Closes the source file.

******************************************************************************}

procedure clssrc;

var p: ifptr; { pointer for if structures }
    f: fcbptr; { pointer for fcb }

begin

   if srclst = nil then error(esys39, ''); { stack underflow should not occur }
   close(srclst^.inpfil); { close file }
   while srclst^.iftrk <> nil do begin { dump any remaining if stacks }

      p := srclst^.iftrk; { index top entry }
      srclst^.iftrk := p^.next; { gap out }
      dispose(p) { release that }

   end;
   f := srclst; { index top fcb }
   srclst := srclst^.next; { gap }
   dispose(f) { free fcb }

end;

{******************************************************************************

Open string for scanning

Accepts a string, and opens that for scanning instead of a file.
Note that no errors can be allowed using this mode, since the error print
information is invalid.

******************************************************************************}

procedure opnlin(view s: string);

var f: fcbptr; { fcb entry }

begin

   new(f); { get a new fcb }
   f^.next := srclst; { push onto source list }
   srclst := f;
   srclst^.linnum := 0; { clear line number }
   srclst^.incmt := false; { set no intraline comment }
   srclst^.iftrk := nil; { clear if tracking stack }
   copy(srclst^.lininp, s); { place line to be parsed }
   srclst^.linptr := 1 { set 1st line position }

end;

{******************************************************************************

Close string for scanning

Closes out the string.

******************************************************************************}

procedure clslin;

var p: ifptr; { pointer for if structures }
    f: fcbptr; { pointer for fcb }

begin

   if srclst = nil then error(esys40, ''); { stack underflow should not occur }
   while srclst^.iftrk <> nil do begin { dump any remaining if stacks }

      p := srclst^.iftrk; { index top entry }
      srclst^.iftrk := p^.next; { gap out }
      dispose(p) { release that }

   end;
   f := srclst; { index top fcb }
   srclst := srclst^.next; { gap }
   dispose(f) { free fcb }

end;

{*******************************************************************************

Find operator

Checks if any of the constant expression operators exist at the current
character position. Returns the character sequence code, or none if nothing is
found. If a sequence is found, and the "skip" flag is set, the parsing position
is moved to after it.

*******************************************************************************}

procedure fndopr(var op: optype; skip: boolean);

var linptrs: integer; { index for line save }
    opbuf:   opstr;   { comparision buffer for operators }
    i:       optype;  { operator type index }

begin

   sskpspcl; { skip leading spaces }
   linptrs := srclst^.linptr; { save current index }
   op := opnone; { set no operator found }
   opbuf[1] := schkchr; { place next 2 characters in buffer }
   sgetchr;
   opbuf[2] := schkchr;
   for i := opplus to opcond do { search for operator }
      if opbuf = oprtbl[i] then op := i; { set found }
   if op = opnone then begin { not found }

      opbuf[2] := ' '; { knock out last character }
      for i := opplus to opcond do { search for operator }
         if opbuf = oprtbl[i] then op := i { set found }

   end;
   if (op = opnone) or not skip then
      srclst^.linptr := linptrs { not found or not in skip mode, back up }
   else if op in [opnequ, oplequ, opgequ, opland, opshl, opshr, opequ, oplor]
      then sgetchr { move to 2 characters }

end;

{*******************************************************************************

Get C label

A C label is:

clab <= '_', 'a'..'z', 'A'..'Z' ['_', 'a'..'z', 'A'..'Z', '0'..9']...

Returns that in the given string. An error is processed if the string is too
long for the string buffer provided. If no label is found, the string is
returned empty.

*******************************************************************************}

procedure getlab(var s: string);

var i: integer;

begin

   clears(s); { clear result }
   i := 1; { set 1st character }
   sskpspcl; { skip leading spaces }
   if schkchr in ['_', 'a'..'z', 'A'..'Z'] then 
      while schkchr in ['_', 'a'..'z', 'A'..'Z', '0'..'9'] do begin

      if i > max(s) then error(elabtl, ''); { too long }
      s[i] := schkchr; { place next character }
      sgetchr; { get next }
      i := i+1 { next character position }

   end

end; 


{*******************************************************************************

Evaluate constant expression

Evaluates a C expression and returns the value. An error flag is also kept that
indicates true if the expression did not parse correctly. No assignments or
structure references are allowed. Only integers are parsed.

Accepts a "fault" flag, and a returned "err" flag. If the fault flag is set,
causes an error to be processed if an error is found. Otherwise, cexpr returns
to the caller with err set. The location of the line position after an error
is undefined. 

Accepts and discards type casts in the limited form:

scast <= '(' typename ['*']... ')'
cast <= cast...

The theory of casts is that, since we are processing integer expressions, the
result is an integer with a "type", which is a useless construct in Pascal. We
leave it to the programmer to do something with the resulting integer.

Casts are limited because a full C cast is a very complex piece of syntax. In
the future, we may include all of the cast syntax, but in the meantime, the
above syntax catches most common casts used on constants.

*******************************************************************************}

procedure cexpr(var r: integer; fault: boolean; var err: boolean);

procedure expr13(var r: integer; fault: boolean; var err: boolean);

label stop;

var c:  char;
    fn: filnam;
    sp: symptr;

begin

   sskpspcl; { skip spaces }
   if schkchr = '(' then begin

      sgetchr; { skip }
      cexpr(r, fault, err); { parse constant subexpression }
      sskpspcl; { skip spaces }
      if schkchr <> ')' then { error }
         if fault then error(erpexp, '') 
         else begin err := true; goto stop end;
      sgetchr { skip }

   end else begin { factor }

      if schkchr = '''' then begin { single character }

         sgetchr; { skip }
         if schkchr = '\\' then begin { force sequence }

            sgetchr; { skip }
            c := schkchr; { next }
            if c in ['0'..'7'] then begin

               r := ord(c)-ord('0'); { find value }
               sgetchr; { skip }
               c := schkchr; { next }
               if c in ['0'..'7'] then begin { 2nd digit }

                  r := r*8+ord(c)-ord('0'); { find value }
                  sgetchr; { skip }
                  c := schkchr; { next }
                  if c in ['0'..'7'] then begin { 3rd digit }

                     r := r*8+ord(c)-ord('0'); { find value }
                     sgetchr { skip }

                  end

               end

            end else if lcase(c) in ['n', 't', 'b', 'r', 'f'] then
               case lcase(c) of { force sequence }

               'n':  r := ord('\lf'); { new line }
               't':  r := ord('\ht'); { tab }
               'b':  r := ord('\bs'); { back space }
               'r':  r := ord('\cr'); { carriage return }
               'f':  r := ord('\ff') { form feed }

            end

         end else begin { standard character }

            r := ord(schkchr); { get value character }
            sgetchr { skip }

         end;
         if schkchr <> '''' then { error }
            if fault then error(emendq, '')
            else begin err := true; goto stop end;
         sgetchr { skip quote }
         
      end else if schkchr in ['0'..'9'] then begin { numeric constant }

         { this version only handles integer, not floating point, values. Also,
           overflow is not checked }
         r := 0; { clear result }
         if schkchr = '0' then begin { handle octal and hex }
 
            sgetchr; { skip }
            if lcase(schkchr) = 'x' then begin { hexadecimal }

               sgetchr; { skip }
               while schkchr in ['0'..'9', 'a'..'f', 'A'..'F'] do begin

                  { construct hexadecimal number }
                  if schkchr in ['0'..'9'] then r := r*16+ord(schkchr)-ord('0')
                  else r := r*16+ord(lcase(schkchr))-ord('a')+10;
                  sgetchr

               end
           
            end else while schkchr in ['0'..'9'] do begin

               { construct decimal number }
               r := r*10+ord(schkchr)-ord('0');
               sgetchr

            end

         end else while schkchr in ['0'..'9'] do begin

            { construct decimal number }
            r := r*10+ord(schkchr)-ord('0');
            sgetchr

         end;
         while lcase(schkchr) in ['u', 'l'] do sgetchr { skip any type modifiers }

      end else if schkchr in ['_', 'a'..'z', 'A'..'Z'] then begin { label }

         { No unresolved labels should make it to this level, since all macros
           have been expanded. However, it could be that the label is actually
           an enumerated value from the program itself (the only way other than
           #defines to create a C constant). So we reach into the top level
           symbols to see if we can find it. }
         getlab(fn); { get label }
         sp := gblsym(fn, false); { lookup symbol}
         if sp <> nil then begin { symbol exists }

            if sp^.typ^.t = tenme then r := sp^.typ^.env { get constant }
            else { error }
               if fault then error(einvfac, '') { invalid factor }
               else begin err := true; goto stop end

         end else { error }
            if fault then error(einvfac, '') { invalid factor }
            else begin err := true; goto stop end
         
      end else { error }
         if fault then error(einvfac, '') { invalid factor }
         else begin err := true; goto stop end

   end;

   stop: { abort with error }

end;

procedure expr12(var r: integer; fault: boolean; var err: boolean);

var op: optype; { operator type index }

begin

   fndopr(op, false); { find operator }
   if op in  [oplnot, opcomp, opplus, opminus] then begin
   
      fndopr(op, true); { skip operator }      
      expr13(r, fault, err); { parse downlevel }
      if not err then case op of { operator }

         oplnot:  r := ord(not (r <> 0));
         opcomp:  r := not r;
         opplus:  ;
         opminus: r := -r

      end

   end else expr13(r, fault, err) { parse downlevel }

end;

procedure expr11c(var r: integer; fault: boolean; var err: boolean);

var slinptr: integer; { line position save }
    valid:   boolean; { cast terminator was valid }

begin

   { look for (cast) expression }
   slinptr := srclst^.linptr; { save line position }
   sskpspcl; { skip spaces }
   if schkchr = '(' then begin

      valid := true; { set valid terminator }
      while (schkchr = '(') and valid do begin

         sgetchr; { skip '(' }
         sskpspcl; { skip spaces }
         if schkchr in ['_', 'a'..'z', 'A'..'Z'] then begin

            { possible cast }
            while (schkchr in ['_', 'a'..'z', 'A'..'Z']) and valid do begin

               while schkchr in ['_', 'a'..'z', 'A'..'Z'] do sgetchr;
               sskpspcl; { skip spaces }
               { discard any '*' abstractions }
               while schkchr = '*' do begin sgetchr; sskpspcl end

            end;
            { check correct termination }
            if schkchr = ')' then begin

               sgetchr; { skip ')' }
               slinptr := srclst^.linptr { save line position }

            end else valid := false { flag invalid }

         end else valid := false; { flag invalid }
         sskpspcl { skip spaces }

      end;
      if valid then { cast was valid, now process expression }
         expr12(r, fault, err)
      else begin

         srclst^.linptr := slinptr; { restore position }
         expr12(r, fault, err) { parse }

      end

   end else expr12(r, fault, err) { parse }

end;

procedure expr11(var r: integer; fault: boolean; var err: boolean);

var r1: integer;
    op: optype; { operator type index }

begin

   expr11c(r, fault, err); { parse downlevel }
   if not err then begin

      fndopr(op, false); { find operator }
      while (op in [optimes, opdiv, opmod]) and not err do begin

         { there is a operator }
         fndopr(op, true); { skip operator }      
         expr11c(r1, fault, err); { parse downlevel }
         if not err then begin

            case op of { operator }

               optimes: r := r*r1;
               opdiv:   r := r div r1;
               opmod:   r := r mod r1

            end;
            fndopr(op, false) { find operator }

         end

      end

   end

end;

procedure expr10(var r: integer; fault: boolean; var err: boolean);

var r1: integer;
    op: optype; { operator type index }

begin

   expr11(r, fault, err); { parse downlevel }
   if not err then begin

      fndopr(op, false); { find operator }
      while (op in [opplus, opminus]) and not err do begin

         { there is a operator }
         fndopr(op, true); { skip operator }      
         expr11(r1, fault, err); { parse downlevel }
         if not err then begin

            if op = opplus then r := r+r1 { calculate }
                           else r := r-r1;
            fndopr(op, false) { find operator }

         end

      end

   end

end;

procedure expr9(var r: integer; fault: boolean; var err: boolean);

var r1: integer;
    op: optype; { operator type index }

begin

   expr10(r, fault, err); { parse downlevel }
   if not err then begin

      fndopr(op, false); { find operator }
      if op in [opshl, opshr] then begin

         { there is a operator }
         fndopr(op, true); { skip operator }      
         expr10(r1, fault, err); { parse downlevel }
         if not err then begin

            if r1 < 0 then error(enegshc, ''); { bad shift count }
            if r1 > 32 then r := 0 { shift would clear result }
            else if op = opshl then while r1 > 0 do begin { shift left }

               r := r*2; { shift left }
               r1 := r1-1 { count }

            end else while r1 > 0 do begin { shift right }

               r := r div 2; { shift right }
               r1 := r1-1 { count }
            
            end;
            fndopr(op, false) { find operator }

         end

      end

   end

end;

procedure expr8(var r: integer; fault: boolean; var err: boolean);

var r1: integer;
    op: optype; { operator type index }

begin

   expr9(r, fault, err); { parse downlevel }
   if not err then begin

      fndopr(op, false); { find operator }
      while (op in [opltn, oplequ, opgtn, opgequ]) and not err do begin

         { there is a operator }
         fndopr(op, true); { skip operator }      
         expr9(r1, fault, err); { parse downlevel }
         if not err then begin

            case op of { operator }

               opltn:  r := ord(r < r1);
               oplequ: r := ord(r <= r1);
               opgtn:  r := ord(r > r1);
               opgequ: r := ord(r >= r1)

            end;
            fndopr(op, false) { find operator }

         end

      end

   end

end;

procedure expr7(var r: integer; fault: boolean; var err: boolean);

var r1: integer;
    op: optype; { operator type index }

begin

   expr8(r, fault, err); { parse downlevel }
   if not err then begin

      fndopr(op, false); { find operator }
      while (op in [opequ, opnequ]) and not err do begin

         { there is a operator }
         fndopr(op, true); { skip operator }      
         expr8(r1, fault, err); { parse downlevel }
         if not err then begin
           
            if op = opequ then r := ord(r = r1) { calculate }
                          else r := ord(r <> r1);
            fndopr(op, false) { find operator }

         end

      end

   end

end;

procedure expr6(var r: integer; fault: boolean; var err: boolean);

var r1: integer;
    op: optype; { operator type index }

begin

   expr7(r, fault, err); { parse downlevel }
   if not err then begin

      fndopr(op, false); { find operator }
      while (op = opand) and not err do begin { there is a operator }

         fndopr(op, true); { skip operator }      
         expr7(r1, fault, err); { parse downlevel }
         if not err then begin

            r := r and r1; { calculate }
            fndopr(op, false) { find operator }

         end

      end

   end

end;

procedure expr5(var r: integer; fault: boolean; var err: boolean);

var r1: integer;
    op: optype; { operator type index }

begin

   expr6(r, fault, err); { parse downlevel }
   if not err then begin

      fndopr(op, false); { find operator }
      while (op = opxor) and not err do begin { there is a operator }

         fndopr(op, true); { skip operator }      
         expr6(r1, fault, err); { parse downlevel }
         if not err then begin

            r := r xor r1; { calculate }
            fndopr(op, false) { find operator }

         end

      end

   end

end;

procedure expr4(var r: integer; fault: boolean; var err: boolean);

var r1: integer;
    op: optype; { operator type index }

begin

   expr5(r, fault, err); { parse downlevel }
   if not err then begin

      fndopr(op, false); { find operator }
      while (op = opor) and not err do begin { there is a operator }

         fndopr(op, true); { skip operator }      
         expr5(r1, fault, err); { parse downlevel }
         if not err then begin

            r := r or r1; { calculate }
            fndopr(op, false) { find operator }

         end

      end

   end

end;

procedure expr3(var r: integer; fault: boolean; var err: boolean);

var r1: integer;
    op: optype; { operator type index }

begin

   expr4(r, fault, err); { parse downlevel }
   if not err then begin

      fndopr(op, false); { find operator }
      while (op = opland) and not err do begin { there is a operator }

         fndopr(op, true); { skip operator }      
         expr4(r1, fault, err); { parse downlevel }
         if not err then begin

            r := ord((r <> 0) and (r1 <> 0)); { calculate }
            fndopr(op, false) { find operator }

         end

      end

   end

end;

procedure expr2(var r: integer; fault: boolean; var err: boolean);

var r1: integer;
    op: optype; { operator type index }

begin

   expr3(r, fault, err); { parse downlevel }
   if not err then begin

      fndopr(op, false); { find operator }
      while (op = oplor) and not err do begin { there is a operator }

         fndopr(op, true); { skip operator }      
         expr3(r1, fault, err); { parse downlevel }
         if not err then begin

            r := ord((r <> 0) or (r1 <> 0)); { calculate }
            fndopr(op, false) { find operator }

         end

      end

   end

end;

procedure expr1(var r: integer; fault: boolean; var err: boolean);

var r1, r2: integer;
    op: optype; { operator type index }

begin

   expr2(r, fault, err); { parse downlevel }
   if not err then begin

      fndopr(op, false); { find operator }
      if op = opcond then begin { there is a conditional }

         fndopr(op, true); { skip operator }      
         expr2(r1, fault, err); { parse downlevel }
         if not err then begin
      
            fndopr(op, true); { find operator }
            if op <> opcln then error(eclnexp, ''); { must be ':' }
            expr1(r2, fault, err); { parse this level }
            if not err then
               { pick expression }
               if r <> 0 then r := r1 else r := r2

         end

      end

   end

end;

begin

   err := false; { set no error }
   expr1(r, fault, err) { parse downlevel }

end;

{*******************************************************************************

Process directive

Called when a directive line is in the buffer. We look for define and include.
Note that the error handling for directives is to abort parsing it and continue
without error. This is how we handle constructs to complex to handle here.
The exceptions to this rule are includes and ifs, which need to be tracked or
the parse falls out of sync.

*******************************************************************************}

procedure directive;

var 

   fn:      filnam;    { filename holder }
   fi:      filinx;    { filename index }
   val:     integer;   { definition value }
   dp:      defptr;    { definition pointer }
   fterm:   boolean;   { terminate if }
   ip:      ifptr;     { pointer for if structure }
   pp, lp:  defppt;    { parameter pointer for macro }
   sav:     linbuf;    { line save }
   si:      lininx;    { index for that }
   dirn:    packed array [1..maxdir] of char; { directive label }
   macn:    packed array [1..maxdir] of char; { macro name }
   parn:    packed array [1..maxdir] of char; { macro name }
   defbuf:  linbuf;    { define body }
   c:       char;

{ get macro definition body }

procedure getdef(var defbuf: string);

var i:       lininx;  { index for that }
    linptrs: integer; { save for line position }
    comment: boolean; { comment flag }

begin

   clears(defbuf); { clear output string }
   { load the rest of the line before any comments into buffer }
   i := 1; { set 1st character in buffer }
   comment := false; { set no comment encounter }
   sskpspcl; { skip leading spaces }
   repeat { place characters in buffer }

      if schkchr <= ' ' then begin { space/control }

         { outside of strings, we replace all control characters with space,
           and normalize all runs of spaces to a single space }
         defbuf[i] := ' '; { place }
         sgetchr; { next character }
         i := i+1;
         sskpspcl { skip intertolken/trailing spaces }

      end else if schkchr = '"' then begin { quote }

         defbuf[i] := schkchr; { place }
         sgetchr; { next character }
         i := i+1;
         while schkchr <> '"' do begin { gather quoted characters }

            if schkchr = '\\' then begin { force character }

               defbuf[i] := schkchr; { place }
               sgetchr; { next character }
               i := i+1

            end;
            defbuf[i] := schkchr; { place }
            sgetchr; { next character }
            i := i+1

         end;
         defbuf[i] := schkchr; { place }
         sgetchr; { next character }
         i := i+1
 
      end else if schkchr = '/' then begin { possible comment }

         linptrs := srclst^.linptr; { save current line position }
         sgetchr; { skip }
         if (schkchr = '*') or (schkchr = '/') then begin

            comment := true; { set in comment }
            srclst^.linptr := linptrs { back up before comment }

         end else begin { not a comment, continue as character }

            defbuf[i] := '/'; { place }
            i := i+1

         end

      end else if not sendlin then begin { place next character }

         defbuf[i] := schkchr; { place }
         sgetchr; { next character }
         i := i+1

      end

   until comment or sendlin { comment or end of line encountered }

end;

{ push if level }

procedure pshlvl;

var ip: ifptr; { pointer to if entry }

begin

   new(ip); { get a new entry }
   ip^.next := srclst^.iftrk; { push onto list }
   srclst^.iftrk := ip;
   ip^.val := 1 { set true by default }   

end;

{ pop if level }

procedure poplvl;

var ip: ifptr; { pointer to if entry }

begin

   { check there is any level active }
   if srclst^.iftrk = nil then error(eifnst, '') else begin

      ip := srclst^.iftrk; { remove top entry }
      srclst^.iftrk := ip^.next; { gap }
      dispose(ip) { release that }

   end

end;

{ evauate constant expression. as cexpr, but removes the source line up to the
  present index, runs a special macro expansion on it }

procedure mcexpr(var r: integer);

var dummy: boolean; { dummy error flag value }

begin

   { extract the rest of line (remove left hand parsed data }
   extract(srclst^.lininp, srclst^.lininp, srclst^.linptr, len(srclst^.lininp));
   srclst^.linptr := 1; { set starting character }
   { expand macros on rest using "if" special rules }
   macscn(srclst^.lininp, true);
   cexpr(r, true, dummy) { process expression }

end;

{ get label }

procedure getlab(var s: string);

var i: integer;

begin

   clears(s); { clear result }
   i := 1; { set 1st character }
   sskpspcl; { skip leading spaces }
   if schkchr in ['_', 'a'..'z', 'A'..'Z'] then 
      while schkchr in ['_', 'a'..'z', 'A'..'Z', '0'..'9'] do begin

      if i > max(s) then error(elabtl, ''); { too long }
      s[i] := schkchr; { place next character }
      sgetchr; { get next }
      i := i+1 { next character position }

   end

end; 

{ skip if }

procedure skipif;

var ip:    ifptr;   { pointer to if entry }
    fterm: boolean; { terminate if }
    dirn:  packed array [1..maxdir] of char; { directive label }

begin

   fterm := false; { set no terminate }
   ip := srclst^.iftrk; { save current tracking level }
   repeat { look for termination }
   
      if not eof(srclst^.inpfil) then begin

         loadlin; { get next line }
         if hasdir then begin { contains a directive }

            sskpspcl; { skip leading spaces }
            if schkchr <> '#' then error(esys41, ''); { should be '#' }
            sgetchr; { skip '#' }
            getlab(dirn); { get label }
            if len(dirn) = 0 then error(edirmis, ''); { no directive label present }
            { there is a directive }
            if compp(dirn, 'if') or 
               compp(dirn, 'ifdef') or
               compp(dirn, 'ifndef') then
               pshlvl { start a new level }
            else if compp(dirn, 'else') then begin

               { else, if its our level we can resume }
               if ip = srclst^.iftrk then fterm := true { terminate }

            end else if compp(dirn, 'elif') then begin

               { elif, if its our level we check it }
               if ip = srclst^.iftrk then begin

                   mcexpr(val); { evaluate expression for it }
                   sskpspcl; { skip to end of line }
                   if not sendlin then error(einvexp, ''); { invalid expression }
                   fterm := val <> 0 { skip if code }

               end

            end else if compp(dirn, 'endif') then begin

               if ip = srclst^.iftrk then fterm := true; { terminate }
               poplvl { remove level }

            end

         end

      end

   { will not carry an if beyond the current file }
   until fterm or eof(srclst^.inpfil)

end;

begin

   sskpspcl; { skip leading spaces }
   if schkchr <> '#' then error(esys42, ''); { should be '#' }
   sgetchr; { skip '#' }
   getlab(dirn); { get label }
   if compcp(dirn, 'include') then begin

      sskpspcl; { skip spaces }
      if (schkchr = '<') or (schkchr = '"') then begin

         sgetchr; { skip }
         { there is a filename string }
         clears(fn); { clear filename }
         fi := 1; { set 1st character }
         while (schkchr <> '>') and (schkchr <> '"') and
               not sendlin do begin

            fn[fi] := schkchr; { place next filename character }
            sgetchr; { next }
            fi := fi+1; { next character }
            if fi >= maxfil then error(einctl, '') { too long }

         end;
         if not exists(fn) then error(eincnf, ''); { include file not found }
         write('Including file: '); write(output, fn:0); writeln;
         iopnsrc(fn) { process subfile }

      end

   end else if compcp(dirn, 'define') then begin

      getlab(macn); { get macro name }
      if len(macn) = 0 then error(emacexp, ''); { no macro name }
      dp := fnddef(macn); { find preexisting def }
      if dp = nil then begin { no previous definition }

         newdef(macn, dp); { create definition }
         { check id immediately followed by '(' }
         if schkchr = '(' then begin

            { note that we indicate parameters even if none are found. this is
              the rule that zero parameter macros can exist, which simply
              creates a no-parameter macro of a different class than normal }
            dp^.parf := true; { set there are parameters }
            { define complex macro (with parameters) }
            sgetchr; { skip '(' }
            repeat { parse parameters }

               getlab(parn); { get parameter id }
               if len(parn) = 0 then begin

                 if schkchr <> ')' then error(eparnf, ''); { missing parameter }
                 c := schkchr { set termination character }

               end else begin { there is a parameter }

                  new(pp); { get a new parameter entry }
                  copyp(pp^.name, parn); { place the name }
                  pp^.next := nil; { set no next }
                  if dp^.par = nil then dp^.par := pp { place as list head }
                  else lp^.next := pp; { insert to list end }
                  lp := pp; { set new last entry }
                  sskpspcl; { skip spaces }
                  c := schkchr; { save next character }
                  if c = ',' then sgetchr { skip ',' }

               end

            until c <> ','; { until no more parameters }
            if schkchr <> ')' then error(erpexp, ''); { ')' expected }
            sgetchr { skip ')' }

         end;
         getdef(defbuf); { get macro body }
         copyp(dp^.sval, defbuf) { place definition string }

      end else begin { validate against previous definition }

         { check id immediately followed by '(' }
         if schkchr = '(' then begin

            { define complex macro (with parameters) }
            sgetchr; { skip '(' }
            pp := dp^.par; { index top of existing parameters list }
            repeat { parse parameters }

               getlab(parn); { get parameter id }
               if len(parn) = 0 then error(eparnf, ''); { missing parameter }
               if pp = nil then error(emacpm, ''); { no matching parameter }
               if not compcp(parn, pp^.name^) then error(emacpm, '');
               pp := pp^.next; { next parameter }
               sskpspcl; { skip spaces }
               c := schkchr; { save next character }
               if c = ',' then sgetchr { skip ',' }

            until c <> ','; { until no more parameters }
            if schkchr <> ')' then error(erpexp, ''); { ')' expected }
            sgetchr { skip ')' }

         end;
         getdef(defbuf); { get macro body }
         if not compcp(defbuf, dp^.sval^) then error(emacbm, '') { no match }

      end

   end else if compcp(dirn, 'undef') then begin

      getlab(macn); { get macro name }
      if len(macn) = 0 then error(emacexp, ''); { no macro name }
      dp := fnddef(macn); { find preexisting def }
      if dp <> nil then deldef(dp) { identifier exists, delete }

   end else if compcp(dirn, 'if') then begin

      pshlvl; { start new level }
      mcexpr(val); { parse expression for it }
      sskpspcl; { skip to end of line }
      if not sendlin then error(einvexp, ''); { invalid expression }
      srclst^.iftrk^.val := val; { place if value }
      if val = 0 then skipif; { skip if code }

   end else if compcp(dirn, 'ifdef') then begin

      pshlvl; { start new level }
      getlab(macn); { get macro name }
      if len(macn) = 0 then error(emacexp, ''); { no macro name }
      dp := fnddef(macn); { find definition }
      srclst^.iftrk^.val := ord(dp <> nil); { place if value }
      if srclst^.iftrk^.val = 0 then skipif { skip if code }

   end else if compcp(dirn, 'ifndef') then begin

      pshlvl; { start new level }
      getlab(macn); { get macro name }
      if len(macn) = 0 then error(emacexp, ''); { no macro name }
      dp := fnddef(macn); { find definition }
      srclst^.iftrk^.val := ord(dp = nil); { place if value }
      if srclst^.iftrk^.val = 0 then skipif { skip if code }

   end else if compcp(dirn, 'else') or
               compcp(dirn, 'elif') then begin

      { else/elif will be encountered during true if block, so it means to
        skip forward to end by default. check there is any level active }
      if srclst^.iftrk = nil then error(emisif, ''); { no 'if' found }
      fterm := false; { set no terminate }
      ip := srclst^.iftrk; { save current tracking level }
      repeat { look for termination }
   
         if not eof(srclst^.inpfil) then begin

            loadlin; { get next line }
            if hasdir then begin { contains a directive }

               sskpspcl; { skip leading spaces }
               if schkchr <> '#' then error(esys43, ''); { should be '#' }
               sgetchr; { skip '#' }
               getlab(dirn); { get label }
               if len(dirn) = 0 then error(edirmis, ''); { no directive label present }
               { there is a directive }
               if compp(dirn, 'if') or 
                  compp(dirn, 'ifdef') or
                  compp(dirn, 'ifndef') then
                  pshlvl { start a new level }
               else if compp(dirn, 'endif') then begin

                  if ip = srclst^.iftrk then fterm := true; { terminate }
                  poplvl { remove level }

               end

            end

         end

      { will not carry an if beyond the current file }
      until fterm or eof(srclst^.inpfil);

   end else if compcp(dirn, 'endif') then
      { endif will be encountered during true if or else blocks }
      poplvl { remove level }
   else if compp(dirn, 'error') then begin { output error }

      { place message in buffer }
      clears(sav); { clear result }
      si := 1; { index 1st character }
      while not sendlin do begin { output line }

         sav[si] := schkchr;
         sgetchr;
         si := si+1

      end;
      write('*** Preprocessor error: [');
      write(output, srclst^.inpnam:0);
      write(':', srclst^.linnum:1, '] ');
      write(output, sav:0);
      writeln
   
   end else if compcp(dirn, 'line') then begin

      { no action performed for "line". the net effect of the "line" directive
        is to correct line numbers/filenames for error printouts, which was
        mostly usefull for correcting error line indications when the macro
        processor was separate from the compiler, which no longer applies }

   end else if compcp(dirn, 'pragma') then begin

      { no action performed for "pragma", we don't implement any pragmas }

   end else if len(dirn) > 0 then error(edirnf, '') { no directive found }

end;

{*******************************************************************************

Alphabetize definitions

Since the defintions are in hash order, there is nothing lost by sorting into
alphabetical order. Definitions are not order dependent, but would be if we
decide to output expressions into the definitions.

*******************************************************************************}

procedure srtdef;

var dp: defptr;    { define entry pointer }
    di: 1..maxdef; { index for defines }

{ insert to ordered list }

procedure insert(dp: defptr);

var p, lp: defptr; { pointers for list }

begin

   dp^.next := nil; { clear next }
   if deflst = nil then deflst := dp { set as root }
   else if not gtrcp(deflst^.name^, dp^.name^) then begin { set as root }

      dp^.next := deflst;
      deflst := dp

   end else begin { insert mid or end }

      p := deflst; { index top of list }
      { search for slot }
      while gtrcp(p^.name^, dp^.name^) and (p^.next <> nil) do begin

         lp := p; { set last }
         p := p^.next { set next }

      end;
      if gtrcp(p^.name^, dp^.name^) then p^.next := dp { insert at end }
      else begin { insert middle }

         lp^.next := dp; { link last to this }
         dp^.next := p { this to next }

      end

   end

end;

begin

   deflst := nil; { clear result list }
   for di := 1 to maxdef do
      while deftab[di] <> nil do begin { clear out list }

      dp := deftab[di]; { index top of alpha list }
      deftab[di] := dp^.next; { gap out }
      insert(dp) { insert to final list }

   end

end;

{*******************************************************************************

Calculate definition values

The definition list is traversed, and a trial constant expression calculation
is made for each macro value. Based on this, either a valid integer or string
value is extracted, or else the entry is just left alone, in which case it
will not be output into the final header file.

*******************************************************************************}

procedure caldefs;

var dp: defptr;    { define entry pointer }
    di: 1..maxdef; { index for defines }

{ calculate define on entry }

procedure caldef(dp: defptr);

var err:      boolean;   { expression error }
    c:        char;      { character holder }
    s:        linbuf;    { buffer for string }
    l:        0..maxlin; { length of buffer }
    i:        lininx;    { index for string }
    quotec:   char;      { starting quote character }

{ get string character, with forces }

procedure getschr(var c: char);

var v: integer; { force value }

begin

   c := schkchr; { check next }
   sgetchr; { skip }
   if c = '\\' then begin { quoted cases }

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

   end

end;

{ parse string }

procedure parstr;

begin

   sskpspcl; { try for string cases }
   if schkchr = '(' then begin { handle (str) case }

      sgetchr; { skip '(' }
      parstr; { parse possible string }
      sskpspcl; { skip spaces }
      { check properly terminated }
      if schkchr = ')' then sgetchr { skip ')' }
      else l := 0 { kill string }
      
   end else begin

      clears(s); { clear string buffer (for neatness) }
      l := 0; { set no string }
      err := false; { set no error }
      { check if it is a wide character constant, and treat same as constant
        string if so }
      if schkchr = 'L' then begin { check wide character constant }

         sgetchr; { skip 'L' }
         if (schkchr <> '"') and (schkchr <> '''') then
            srclst^.linptr := 1 { set 1st line position }

      end;
      if (schkchr = '''') or (schkchr = '"') then begin { possible string }

         quotec := schkchr; { get starting quote }
         sgetchr; { skip quote }
         while (schkchr <> quotec) and not sendlin do begin { process string }

            getschr(c); { get character with force }
            l := l+1; { next and count characters }
            s[l] := c { place }

         end;
         { check ending quote }
         if schkchr = quotec then sgetchr { skip }
         else l := 0 { kill string }

      end

   end

end;

begin

   opnlin(dp^.sval^); { open string value as a line }
   macscn(srclst^.lininp, false); { expand macros in line }
   parstr; { attempt to parse string }
   if l = 0 then begin { try for numeric interpretation }

      srclst^.linptr := 1; { set 1st line position }
      cexpr(dp^.equv, false, err) { attempt expression parse }

   end;
   sskpspcl; { check remaining line is empty }
   if not sendlin then err := true;
   if not err then begin { the value or string is good }

      if l > 0 then begin { string }

         new(dp^.equs, l); { get the string }
         for i := 1 to l do dp^.equs^[i] := s[i] { copy string }

      end else dp^.equf := true { set integer value }

   end;
   clslin { close it }

end;

begin

   for di := 1 to maxdef do begin
 
      dp := deftab[di];
      while dp <> nil do begin { traverse definitions table }

         { macro must have no parameters }
         if dp^.par = nil then caldef(dp); { calculate defines on entry }
         dp := dp^.next { next entry }

      end

   end

end;

{*******************************************************************************

Place alias symbols

Some macros may be used simply to define aliases to existing symbols. This only
makes sense for functions, because types already have the "typedef" alias
technique, and variables don't (or shouldn't) appear in the file.
However, we also create aliases for types, because I have seen this technique
used in actual files.

We lookup all macro definitions as symbols, then place any aliases found.
Because aliases only make sense for functions, that is all we process right now.

*******************************************************************************}

procedure macalias;

var dp: defptr;      { pointer for names table }
    sp, sp1: symptr; { pointer for symbols table }

begin

   dp := deflst; { index top of definitions list }
   while dp <> nil do begin

      { find expanded value of macro }
      opnlin(dp^.sval^); { open string value as a line }
      macscn(srclst^.lininp, false); { expand macros in line }
      { although we lookup what may be totally random data as a symbol,
        hashing and matching the contents of a macro body is more efficient
        than trying to determine if the contents is a symbol, and just as
        secure }
      sp := gblsym(srclst^.lininp, false); { lookup symbol}
      if sp <> nil then { found }
         if sp^.typ <> nil then begin { has a type to duplicate }

         if sp^.typ^.t = tfunc then begin { is a function }

            sp1 := gblsym(dp^.name^, false); { check for duplicate }
            { if alias is a duplicate, we just drop it. We could flag an error,
              but it would only be a real error if used in context, which means
              we could be flagging a false error }
            if sp1 = nil then begin

               getsym(sp1); { get a new symbol entry }
               sp1^.lvl := 0; { clear scope }
               new(sp1^.lab, len(dp^.name^)); { get a label string }
               copy(sp1^.lab^, dp^.name^); { place the label }
               copytype(sp1^.typ, sp^.typ); { make a copy }
               newsym(sp1, false); { place as symbol }
               sp1^.typ^.fncrno := sp; { link assembly alias to original }
               dp^.als := true { set was used as alias }

            end

         end else if sp^.typ^.t in [tudf, tvoid, tint, tfloat, tenum, tptr,
                                    tarray, tstruct, tunion] then begin

            { check for duplicate }
            sp1 := gblsym(dp^.name^, sp^.typ^.t in [tstruct, tunion]);
            { if alias is a duplicate, we just drop it. We could flag an error,
              but it would only be a real error if used in context, which means
              we could be flagging a false error }
            if sp1 = nil then begin

               getsym(sp1); { get a new symbol entry }
               sp1^.lvl := 0; { clear scope }
               new(sp1^.lab, len(dp^.name^)); { get a label string }
               copy(sp1^.lab^, dp^.name^); { place the label }
               sp1^.typ := sp^.typ; { just link to existing type }
               newsym(sp1, sp^.typ^.t in [tstruct, tunion]); { place as symbol }
               dp^.als := true { set was used as alias }

            end

         end

      end;
      sp := gblsym(srclst^.lininp, false); { lookup symbol}
      if sp <> nil then { found }
         if sp^.typ <> nil then begin { has a type to duplicate }

         if sp^.typ^.t in [tudf, tvoid, tint, tfloat, tenum, tptr,
                                    tarray, tstruct, tunion] then begin

            { check for duplicate }
            sp1 := gblsym(dp^.name^, sp^.typ^.t in [tstruct, tunion]);
            { if alias is a duplicate, we just drop it. We could flag an error,
              but it would only be a real error if used in context, which means
              we could be flagging a false error }
            if sp1 = nil then begin

               getsym(sp1); { get a new symbol entry }
               sp1^.lvl := 0; { clear scope }
               new(sp1^.lab, len(dp^.name^)); { get a label string }
               copy(sp1^.lab^, dp^.name^); { place the label }
               sp1^.typ := sp^.typ; { just link to existing type }
               newsym(sp1, sp^.typ^.t in [tstruct, tunion]); { place as symbol }
               dp^.als := true { set was used as alias }

            end

         end

      end;
      clslin; { close the line }
      dp := dp^.next

   end

end;

{*******************************************************************************

Register definitions

Places all definitions into the names table, and registers their instances.

*******************************************************************************}

procedure regdef;

var dp: defptr; { pointer for names table }

begin

   dp := deflst; { index top of definitions list }
   while dp <> nil do begin

      if not dp^.als then { was not an alias }
         newnam(dp^.name^, dp^.inst); { place name and get instance }
      dp := dp^.next

   end

end;

{*******************************************************************************

Output definitions

If the output definitions flag is set, outputs the definition tables.
The output format is:

name svalue parameters

Each definition is output with its name, followed by the string value.

The string value is the replacement text for the macro. This is allways the
text used to replace the macro in source. It may be null, in which case the
macro is a "hit" macro.

*******************************************************************************}

procedure prtdef;

var dp: defptr;    { define entry pointer }
    i:  integer;   { index }
    pp: defppt;    { parameter pointer }

begin

   if fprtdef then begin { defines are to be printed }

      writeln;
      writeln('Definitions:');
      writeln;
      dp := deflst; { index top of definitions list }
      while dp <> nil do begin { traverse definitions table }

         write(dp^.name^);
         for i := 1 to deffld-max(dp^.name^) do write(' ');
         writeln(dp^.sval^);
         if dp^.par <> nil then begin { there are parameters }

            write('   '); { space off }
            pp := dp^.par; { index top parameter }
            while pp <> nil do begin { output parameter names }

               write(pp^.name^, ' '); { output name }
               pp := pp^.next { next entry }

            end;
            writeln
            
         end;
         dp := dp^.next { next entry }

      end

   end

end;

{******************************************************************************

Print hexadecimal

Print a hexadecimal number with field width. Prints right justified with left
hand zeros filling the field. Also allows for the fact that an unsigned 32 bit
number can be read into a 32 bit signed number.
One remaining problem is how to detect and convert the invalid value $80000000.

******************************************************************************}

procedure prthex(var fo: text; f: byte; w: integer);
 
var buff: packed array [1..10] of char; { buffer for number in ascii }
    i:    integer; { index for same }
    t:    integer; { holding }
 
begin

   { set sign of number and convert }
   if w < 0 then begin

      w := w+1+maxint; { convert number to 31 bit unsigned }
      t := w div $10000000 + 8; { extract high digit }
      writeh(fo, t); { ouput that }
	   w := w mod $10000000; { remove that digit }
      f := 7 { force field to full }     

   end;
   hexs(buff, w); { convert the integer }
   for i := 1 to f-len(buff) do write(fo, '0'); { pad with leading zeros }
   write(fo, buff:0) { output number }

end;

{*******************************************************************************

Output definitions to header file

Outputs the definitions in Pascal header format.

*******************************************************************************}

procedure hdrdef(var f: text);

var dp: defptr;  { define entry pointer }
    i:  integer; { index }
    cnt: integer; { count of defined symbols }

begin

   cnt := 0; { clear counter }
   dp := deflst; { index top of list }
   while dp <> nil do begin { traverse definitions table }

      if (dp^.equf or (dp^.equs <> nil)) and (cnt = 0) then begin

         writeln(f);
         writeln(f, '{ Constants defined as macros by #define }');
         writeln(f);
         writeln(f, 'const');
         writeln(f)

      end;
      if dp^.equf then begin { integer }

         if dp^.inst = 1 then write(f, 'sc_', dp^.name^, ' = $')
         else write(f, 'sc_', dp^.name^, '_', dp^.inst:1, ' = $');
         prthex(f, 1, dp^.equv);
         writeln(f, ';');
         cnt := cnt+1 { count }

      end else if dp^.equs <> nil then begin { string }

         write(f, 'sc_', dp^.name^, ' = ''');
         for i := 1 to max(dp^.equs^) do begin { output string characters }

            { output a quote image for a quote }
            if dp^.equs^[i] = '''' then write(f, '''''')
            else write(f, dp^.equs^[i])

         end;
         writeln(f, ''';');
         cnt := cnt+1 { count }

      end;
      dp := dp^.next { next entry }

   end;
   if cnt > 0 then begin { output tally }

      writeln(f);
      writeln(f, '{ ', cnt:1, ' Total resolved constants }');
      writeln(f)

   end;

end;

{*******************************************************************************

Output coined macro definitions

Outputs a table of definitions that had to be coined because of case
duplication.

*******************************************************************************}

procedure coindef(var f: text);

var dp:  defptr;  { define entry pointer }
    cnt: integer; { count of unresolved }

begin

   cnt := 0; { clear counter }
   dp := deflst; { index top of list }
   while dp <> nil do begin { traverse definitions table }

      if dp^.inst > 1 then begin { instance was multiple }

         if cnt = 0 then begin { first unresolved, output header }

            writeln(f);
            writeln(f, '{ *** Report *** #define macros whose names were case ',
                       'sensitive }');
            writeln(f);
            writeln(f, '{');
            writeln(f)

         end;
         writeln(f, dp^.name^, ' -> ', dp^.name^, '_', dp^.inst:1);
         cnt := cnt+1 { count }

      end;
      dp := dp^.next { next entry }

   end;
   if cnt > 0 then begin { output ending }

      writeln(f);
      writeln(f, '}')

   end;
   if cnt > 0 then begin { output tally }

      writeln(f);
      writeln(f, '{ ', cnt:1, ' Total coined constants }');
      writeln(f)

   end

end;

{*******************************************************************************

Output string with quoted curly brackets

Curly brackets in a Pascal program cause problems, so this routine exists to
output the contents of a string while using a special quote sequence:

<lbrkt>
<rbrkt>

Also finds left paren start and right paren star sequences and adds a space 
between the paren and the star. This prevents their being interpreted as
comments.

Accepts a line length, and adds all characters that will be output to that.

*******************************************************************************}

procedure outmacval(var f: text; view s: string; var llen: integer);

var i: integer; { index for string }
    lstar: boolean; { last was '*' }

begin

   lstar := false; { set no last '*' }
   for i := 1 to max(s) do begin

      if s[i] = '{' then begin write(f, '<lbrkt>'); llen := llen+7 end
      else if s[i] = '}' then begin write(f, '<rbrkt>'); llen := llen+7 end
      { if its '*'<nospace>')' then output as '* )', which prevents it from
        being misinterpreted as a comment }
      else if (s[i] = ')') and lstar then 
         begin write(f, ' ', s[i]); llen := llen+2 end
      else begin write(f, s[i]); llen := llen+1 end;
      lstar := s[i] = '*'; { set last is '*' status }
      if (llen > 70) and (i < max(s)) then begin  { line overflow }

         writeln(f); { terminate }
         write(f, '   '); { start new line }
         llen := 0 { clear count }

      end

   end

end;

{*******************************************************************************

Output unresolved definitions

Outputs a table of defintions that have no evaluation, and therefore no output
header definitions.

*******************************************************************************}

procedure unrdef(var f: text);

var dp:   defptr;  { define entry pointer }
    cnt:  integer; { count of unresolved }
    llen: integer; { line length }
    maxl: integer; { maximum length of qualified labels }
    lc:   integer; { items on line count }
    lic:  integer; { item count }

begin

   { find maximum length of label }
   dp := deflst; { index top of list }
   maxl := 0; { clear max }
   while dp <> nil do begin { traverse definitions table }

      if not dp^.equf and (dp^.equs = nil) and not dp^.als and 
         (dp^.par = nil) then { unresolved found }
         if len(dp^.sval^) > 0 then { not a hit macro }
            { set new maximum }
            if max(dp^.name^) > maxl then maxl := max(dp^.name^); 
      dp := dp^.next { next entry }

   end;
   { find number of symbols that will fit on a line }
   lc := prtmax div (maxl+1);
   { output compressed list }
   cnt := 0; { clear counter }
   lic := 0; { clear line item counter }
   dp := deflst; { index top of list }
   while dp <> nil do begin { traverse definitions table }

      if not dp^.equf and (dp^.equs = nil) and not dp^.als and 
         (dp^.par = nil) then begin { unresolved found }

         if len(dp^.sval^) > 0 then begin { not a hit macro }

            if cnt = 0 then begin { first unresolved, output header }

               writeln(f);
               writeln(f, '{ *** Report *** #define macros whose values could ',
                          'not be calculated short list }');
               writeln(f);
               writeln(f, '{');
               writeln(f)

            end;
            write(f, dp^.name^, ' ':maxl-max(dp^.name^)+1);
            llen := max(dp^.name^)+1; { set line length }
            lic := lic+1; { count items }
            if lic = lc then begin { end of line, return }

               writeln(f); { next line }
               lic := 0 { clear line item counter }

            end;
            cnt := cnt+1 { count }

         end

      end;
      dp := dp^.next { next entry }

   end;
   if cnt > 0 then begin { output ending }

      if lic > 0 then writeln(f); { terminate unfinished line }
      writeln(f);
      writeln(f, '}')

   end;
   { output long list }
   cnt := 0; { clear counter }
   dp := deflst; { index top of list }
   while dp <> nil do begin { traverse definitions table }

      if not dp^.equf and (dp^.equs = nil) and not dp^.als and 
         (dp^.par = nil) then begin { unresolved found }

         if len(dp^.sval^) > 0 then begin { not a hit macro }

            if cnt = 0 then begin { first unresolved, output header }

               writeln(f);
               writeln(f, '{ *** Report *** #define macros whose values could ',
                          'not be calculated }');
               writeln(f);
               writeln(f, '{');
               writeln(f)

            end;
            write(f, dp^.name^, ' = ');
            llen := max(dp^.name^)+3; { set line length }
            outmacval(f, dp^.sval^, llen);
            writeln(f);
            cnt := cnt+1 { count }

         end

      end;
      dp := dp^.next { next entry }

   end;
   if cnt > 0 then begin { output ending }

      writeln(f);
      writeln(f, '}')

   end;
   if cnt > 0 then begin { output tally }

      writeln(f);
      writeln(f, '{ ', cnt:1, ' Total unresolved constants }');
      writeln(f)

   end

end;

{*******************************************************************************

Output parameterized macros

Outputs a table of parameterized macros. Macros with parameters cannot be
resolved to simple definitions, so are listed separately.

*******************************************************************************}

procedure outparmac(var f: text);

var dp:   defptr;  { define entry pointer }
    cnt:  integer; { count of unresolved }
    llen: integer; { line length }
    pp:   defppt;  { parameter pointer }
    maxl: integer; { maximum length of qualified labels }
    lc:   integer; { items on line count }
    lic:  integer; { item count }

begin

   { find maximum length of label }
   dp := deflst; { index top of list }
   maxl := 0; { clear max }
   while dp <> nil do begin { traverse definitions table }

      if dp^.par <> nil then { parameterized macro }
         { set new maximum }
         if max(dp^.name^) > maxl then maxl := max(dp^.name^); 
      dp := dp^.next { next entry }

   end;
   { find number of symbols that will fit on a line }
   lc := prtmax div (maxl+1);
   { output compressed list }
   cnt := 0; { clear counter }
   lic := 0; { clear line item counter }
   dp := deflst; { index top of list }
   while dp <> nil do begin { traverse definitions table }

      if dp^.par <> nil then begin { parameterized macro }

         if cnt = 0 then begin { first unresolved, output header }

            writeln(f);
            writeln(f, '{ *** Report *** Parameterized macros short list }');
            writeln(f);
            writeln(f, '{');
            writeln(f)

         end;
         write(f, dp^.name^, ' ':maxl-max(dp^.name^)+1);
         llen := max(dp^.name^)+1; { set line length }
         lic := lic+1; { count items }
         if lic = lc then begin { end of line, return }

            writeln(f); { next line }
            lic := 0 { clear line item counter }

         end;
         cnt := cnt+1 { count }

      end;
      dp := dp^.next { next entry }

   end;
   if cnt > 0 then begin { output ending }

      if lic > 0 then writeln(f); { terminate unfinished line }
      writeln(f);
      writeln(f, '}')

   end;
   { output long list }
   cnt := 0; { clear counter }
   dp := deflst; { index top of list }
   while dp <> nil do begin { traverse definitions table }

      if dp^.par <> nil then begin { parameterized macro }

         if cnt = 0 then begin { first unresolved, output header }

            writeln(f);
            writeln(f, '{ *** Report *** Parameterized macros long list }');
            writeln(f);
            writeln(f, '{');
            writeln(f)

         end;
         write(f, dp^.name^, '(');
         pp := dp^.par; { index top of parameters list }
         while pp <> nil do begin { print parameters }

            write(f, pp^.name^); { print parameter }
            if pp^.next <> nil then write(f, ','); { separate }
            pp := pp^.next { link next }

         end;
         write(f, ') = ');
         llen := max(dp^.name^)+3; { set line length }
         outmacval(f, dp^.sval^, llen);
         writeln(f);
         cnt := cnt+1 { count }

      end;
      dp := dp^.next { next entry }

   end;
   if cnt > 0 then begin { output ending }

      writeln(f);
      writeln(f, '}')

   end;
   if cnt > 0 then begin { output tally }

      writeln(f);
      writeln(f, '{ ', cnt:1, ' Total parameterized macros }');
      writeln(f)

   end

end;

{******************************************************************************

Initalize macro module

******************************************************************************}

begin

   for di := 1 to maxdef do deftab[di] := nil; { clear definitions table }
   for ni := 1 to maxnam do namtab[ni] := nil; { clear names table }
   srclst := nil; { clear source stack }
   fprtlin := false; { set no print incoming lines }
   fprtexp := false; { set no print macro expansions }
   fprtmac := false; { set no print macro being expanded }
   fprtdef := false; { set no print definitions table }
   fprtpln := false; { set no print processed lines }
   fcppcmt := false; { allow C++ comments }

end.
