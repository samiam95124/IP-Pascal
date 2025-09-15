{*******************************************************************************
*                                                                              *
*                                 SYMBOLS                                      *
*                                                                              *
* Provides a symbol table, management for that, and a type structure system    *
* with management for that.                                                    *
*                                                                              *
*******************************************************************************}

module symbol(output);

uses stddef,  { standard defines }
     strlib,  { strings }
     macro,   { macro functions }
     scanner; { scanner }

const

symmax = 1000; { symbol chain head maximum }
prtmax  = 80;  { maximum number of characters in an output line }
nestmax = 1000; { comparitor error stop }

type 

syminx = 1..symmax; { index for symbol head table }
typptr = ^typ; { type pointer }
symptr = ^sym; { symbol pointer }
sym    = record { symbol entry }
  
   next: symptr;  { next list entry }
   inst: integer; { instance of same caseless spelling }
   lvl:  integer; { block level }
   typ:  typptr;  { pointer to symbol type }
   lab:  pstring; { symbol label }
   str:  boolean; { is a structure }
   gen:  boolean; { is a generated label }
   rem:  boolean; { remove from output deck }
   rma:  boolean; { remove from assembly output deck }
   tlst: symptr;  { list of symbols on type }
   asym: symptr;  { preferred alias symbol }
   out:  boolean  { output flag }

end;
{ C type flags }
typflg = (tfnone, tfauto, tfregister, tfstatic, tfextern, tftypedef, tfconst,
          tfvolatile, tfvoid, tfchar, tfshort, tfint, tflong, tffloat,
          tfdouble, tfsigned, tfunsigned);
typfst = set of typflg;
{ type codes 
  In C, all types besides structured types and functions end up being flags,
  and it gets programmatically inconvienent not to process C that way.
  Here, types are used both to build the structures and functions, and also,
  the different, incompatible type classifications are broken out into types.
  This is redundant with the C type flags, but indicates more readily if two
  types are compatible }
types  = (tudf,     { undefined entry, for use with undef pointers }
          tvoid,    { void type }
          tint,     { integer }
          tfloat,   { floating point }
          tlab,     { goto label }
          ticst,    { integer constant }
          tscst,    { string constant }
          tccst,    { character constant }
          tfcst,    { floating constant }
          tarrcst,  { array constant entry }
          tarrcel,  { array constant element }
          treccst,  { record constant entry }
          treccel,  { record constant element }
          tenum,    { enumerated }
          tenme,    { enumerated constant }
          tptr,     { pointer }
          tarray,   { array }
          tstruct,  { structure }
          tunion,   { union }
          tfield,   { structure field }
          tvar,     { variable }
          tfunc,    { function }
          tfunci,   { function instantiation }
          tpar);    { parameter }
typ = record { type entry }
         
   next: typptr;  { next list entry }
   tfs:  typfst;  { typing flags }
   size: integer; { size of type, in bytes }
   algn: integer; { alignment of type, 1, 2 or 4 }
   drv:  typptr;  { derived from type }
   sym:  symptr;  { associated symbol }
   out:  boolean; { this entry has been output to header file }
   rem:  boolean; { remove from output deck }
   rma:  boolean; { remove from assembly output deck }
   case t: types of { types }

      tudf:     ();              { dummy entry for undefined pointers }
      tvoid:    ();              { void type }
      tint:     ();              { integer }
      tfloat:   ();              { floating point }
      tlab:     ();              { label }
      ticst:    (ival: integer); { the value of the integer }
      tscst:    (sval: pstring); { the value of the string }
      tccst:    (cval: char);    { character constant }
      tfcst:    (fval: real);    { the value of the float }
      tarrcst:  (arcn: typptr);  { first list entry }
      tarrcel:  (aren: typptr;   { next list entry }
                 arec: typptr);  { constant link }
      treccst:  (recn: typptr);  { first list entry }
      treccel:  (reen: typptr;   { next list entry }
                 reec: typptr);  { constant link }
      tenum:    (enc:  typptr);  { list of enumerated constants }
      tenme:    (enx:  typptr;   { next enumeration entry }
                 enh:  typptr;   { head entry pointer }
                 env:  integer); { enumerated constant }
      tptr:     (ptrt: typptr;   { base type }
                 ptrts: symptr); { base type preferred symbol }
      tarray:   (arrt: typptr;   { base type }
                 arrts: symptr;  { base type preferred symbol }
                 arre: integer); { number of array elements }
      tstruct:  (strf: typptr;   { field list }
                 strl: symptr);  { list of field labels }
      tunion:   (unif: typptr;   { field list }
                 unil: symptr;   { list of field labels }
                 unit: symptr);  { tagfield label }
      tfield:   (fldn: typptr;   { next field pointer }
                 fldh: typptr;   { head entry pointer }
                 fldb: integer;  { number of bits to fit into }
                 fldt: typptr;   { base type }
                 fldts: symptr); { preferred base type symbol }
      tvar:     (vart: typptr;   { base type }
                 varc: typptr);  { constant fill }
      tfunc:    (fncp: typptr;   { parameter list }
                 fncr: typptr;   { function result }
                 fncrs: symptr;  { function result preferred symbol }
                 fncl: symptr;   { list of parameter labels }
                 fncv: boolean;  { function has variable arguments }
                 fncrps: pstring; { result pascal side replacement string }
                 fncras: pstring; { result assembler side replacement string }
                 fncrno: symptr); { function reference name override }
      tfunci:   (fnit: typptr);  { function instantiation }
      tpar:     (parn: typptr;   { next parameter }
                 part: typptr;   { base type }
                 parts: symptr;  { preferred base type symbol }
                 parh: typptr;   { head entry pointer }
                 parps: pstring; { pascal side replacement string }
                 paras: pstring; { assembler side replacement string }
                 partps: pstring; { pascal side replacement string }
                 partas: pstring; { assembler side replacement string }
                 pareld: boolean; { parameter can be elided }
                 pareas: pstring); { elided assembler side replacement }

   { end }

end;
typset = set of types; { set of types }
tpsptr = ^tps; { pointer to type stack entry }
tps = record { type stack entry }

   next: tpsptr; { next entry }
   typ:  typptr; { type list for block }
   als:  symptr; { alphabetically sorted symbols }
   lst:  typptr  { last entry in type list }

end;

{ defines for module name hash structure }

const modmax = 1000;

type

modinx = 1..modmax; { index for name head table }
modptr = ^modnam; { pointer to entry }
modnam = record { module name entry }

   name:  pstring; { module export name }
   mname: pstring; { name of containing module }
   dup:   boolean; { is a duplicate }
   ref:   boolean; { was referenced by a symbol }
   next:  modptr   { next entry in chain }

end;

var

level:   integer; { scope nesting level }
fsym:    boolean; { symbols print flag (diagnostic) }
ftype:   boolean; { output types table (diagnostic) }
fptrvar: boolean; { change anonymous pointer parameters to VAR }
fccpstr: boolean; { change constant character pointers to string }
fchpstr: boolean; { change character pointer to string }

procedure getsym(var sp: symptr); forward;
procedure putsym(sp: symptr); forward;
function gblsym(view s: string; sf: boolean): symptr; forward;
function lclsym(view s: string; sf: boolean): symptr; forward;
procedure plcsym(var sp: symptr; sf: boolean); forward;
procedure purge; forward;
procedure alpsym(var sp: symptr); forward;
procedure formlist(var sp: symptr); forward;
procedure listsym; forward;
procedure define(var sp: symptr; sf: boolean); forward;
procedure gettyp(var tp: typptr; t: types); forward;
procedure puttyp(tp: typptr); forward;
procedure lsttyp(var tp: typptr; t:  types); forward;
procedure purget; forward;
procedure listlab(tp: typptr); forward;
procedure listtype(tp: typptr); forward;
procedure listtyp; forward;
procedure bgnblk; forward;
procedure endblk; forward;
procedure lodsym(var sp: symptr); forward;
procedure diagsym; forward;
procedure newsym(sp: symptr; sf: boolean); forward;
function comptype(tp1, tp2: typptr): boolean; forward;
procedure cointypes; forward;
procedure namtyp; forward;
procedure outtypes(var f: text); forward;
procedure chktypes; forward;
procedure copytype(var dtp: typptr; stp: typptr); forward;
procedure fixdrv(dtp: typptr); forward;
procedure regsym; forward;
procedure outfuncs(var f: text); forward;
procedure outasms(var f: text); forward;
procedure outenums(var f: text); forward;
procedure setparrep(sp: symptr; view pas, asm: pstring); forward;
procedure setresrep(sp: symptr; view pas, asm: pstring); forward;
procedure repcsym(var f: text); forward;
procedure clonefunc(fp: typptr; sp: symptr); forward;
procedure newmod(view n: string; mn: pstring; var cnt: integer); forward;
procedure repdexp(var f: text); forward;
procedure repuexp(var f: text); forward;
procedure alphasym; forward;
function eldcnt(fp: typptr): integer; forward;

private

var

symtbl: array [syminx] of symptr; { symbol chain table }
symfre: symptr; { free symbol entry list }
si:     syminx; { symbol table index }
typstk: tpsptr; { type list stack }
tpsfre: tpsptr; { type list entry free stack }
typfre: array[types] of typptr; { free type entries arrayed by type }
ti:     types;  { index for types entry table }
typnum: integer; { generates coined type numbers }
lincnt: integer; { output line count }
modtbl: array [modinx] of modptr; { module chain table }
mi:     modinx; { module name table index }

{******************************************************************************

Get new symbol entry

Consults the free list, and if a free entry is available, returns that. 
Otherwise returns a brand new entry.
Clears relevant fields.

******************************************************************************}

procedure getsym(var sp: symptr);

begin

   if symfre <> nil then begin { return existing symbol entry }
   
      sp := symfre; { index top entry }
      symfre := symfre^.next { gap the list }

   end else new(sp); { get an entirely new entry }
   sp^.next := nil; { terminate entry }
   sp^.inst := 1; { set 1st instance by default }
   sp^.typ := nil; { clear type pointer }
   sp^.str := false; { set not a structure id }
   sp^.gen := false; { set not generated id }
   sp^.rem := false; { set no remove }
   sp^.rma := false; { set no remove from assembler }
   sp^.tlst := nil; { set not in type list }
   sp^.asym := nil; { set no alias symbol }
   sp^.out := false; { clear output flag }
   sp^.lab := nil { clear symbol }

end;

{******************************************************************************

Put symbol entry

Places a used symbol on the free list to await later reuse.

******************************************************************************}

procedure putsym(sp: symptr);

begin

   if sp^.lab <> nil then dispose(sp^.lab); { release label if it exists }
   sp^.next := symfre; { link to head }
   symfre := sp { and place new head }

end;

{******************************************************************************

Find global symbol

Finds a symbol that matches nxtlab regardless of the block it belongs
to. Returns a pointer to the matching symbol entry, or nil if none is found.
Accepts a structure flag, which matches what type of symbol to look at,
structure tag or regular.

******************************************************************************}

function gblsym(view s: string; sf: boolean): symptr;

var p, r: symptr; { pointers for symbol table }

begin
   
   r := nil; { clear result pointer }
   p := symtbl[hashc(s, 0, symmax)]; { index the top entry }
   while p <> nil do begin { traverse chain }

      if compcp(s, p^.lab^) and (p^.str = sf) then begin { entry found }

         r := p; { place result pointer }
         p := nil { nix search pointer }

      end else p := p^.next { index next entry }

   end;
   gblsym := r { return result pointer }

end;

{******************************************************************************

Find local symbol

Finds a symbol that matches the given label, but only if it exists with the
same level number. Returns a pointer to the matching symbol entry, or nil if 
none is found.
Accepts a structure flag, which matches what type of symbol to look at,
structure tag or regular.

******************************************************************************}

function lclsym(view s: string; sf: boolean): symptr;

var r: symptr; { pointer for symbol table }

begin

   r := gblsym(s, sf); { find matching symbol }
   if r <> nil then { yes, we have a match }
      if r^.lvl <> level then r := nil; { but sadly not our level, kill it }
   lclsym := r { return result pointer }

end;   

{******************************************************************************

Load symbol entry

Loads a symbol entry from the current symbol buffer. Gets a new symbol entry,
and loads that from the nxtlab buffer.

******************************************************************************}

procedure lodsym(var sp: symptr);

begin

   getsym(sp); { get a new symbol entry }
   sp^.lvl := 0; { clear scope }
   new(sp^.lab, len(nxtlab)); { get a label string }
   copy(sp^.lab^, nxtlab) { place the label }

end;

{******************************************************************************

Enter new symbol

Accepts a full symbol entry (as in 'lodsym'). Checks to see if a local symbol
by that name has already been defined, and if so, outputs an error.
Then, the symbol is then placed into the symbol table at the current level.
Accepts a structure flag, which matches what type of symbol to look at,
structure tag or regular.

******************************************************************************}

procedure newsym(sp: symptr; sf: boolean);

var sp1: symptr; { symbol pointer }
    i:   syminx; { index for symbol table }

begin

   if sp = nil then error(esys14, ''); { should not be nil }
   sp1 := lclsym(sp^.lab^, sf); { find previous symbol }
   if sp1 <> nil then error(edupsym, sp^.lab^); { symbol is duplicate }
   sp^.lvl := level; { set the scope for it }
   sp^.str := sf; { set struct/regular status }
   i := hashc(sp^.lab^, 0, symmax); { find the top entry }
   sp^.next := symtbl[i]; { place the next entry link }
   symtbl[i] := sp { plant our symbol }

end;   

{******************************************************************************

Place symbol in symbol table

A wonderously (and deliberately) stupid routine, just finds the hash slot for
the given symbol and places it into that chain. Because of search order, it
then takes precidence over other duplicate definitions. If the label must be
unique for the current scope, or concevably the entire program, it should be
checked for duplicates first.

******************************************************************************}

procedure plcsym(var sp: symptr; sf: boolean);

var i: syminx; { index for symbol table }

begin

   lodsym(sp); { get the symbol with string }
   sp^.lvl := level; { set the scope for it }
   sp^.str := sf; { set structure status }
   i := hashc(sp^.lab^, 0, symmax); { find the top entry }
   sp^.next := symtbl[i]; { place the next entry link }
   symtbl[i] := sp { plant our symbol }

end;

{******************************************************************************

Define new symbol

Checks to see if a local symbol by that name has already been defined, and if
so, outputs an error.
Accepts a structure flag, which matches what type of symbol to look at,
structure tag or regular.

******************************************************************************}

procedure define(var sp: symptr; sf: boolean);

begin

   sp := lclsym(nxtlab, sf); { find previous symbol }
   if sp <> nil then error(edupsym, nxtlab); { symbol is duplicate }
   plcsym(sp, sf) { place as new symbol }

end;

{******************************************************************************

Purge current scope

Walks the symbol table, and removes all entries that match the current level
number. We of course assume that these symbols will be first on the chains.

******************************************************************************}

procedure purge;

var i: syminx; { index for symbol table }
    p: symptr; { pointer for symbols }

begin

   for i := 1 to symmax do begin { traverse the symbols head }

      p := symtbl[i]; { index the chain head }
      while p <> nil do { flush up top symbols }
         if p^.lvl = level then begin { this symbol matches the current scope }
       
            symtbl[i] := p^.next; { gap chain head }
            putsym(p); { dispose of the symbol }
            p := symtbl[i] { load the new top }

         end else p := nil; { stop the search }

   end

end;

{******************************************************************************

Alphabetize a symbols list

Given a list of symbols, will arrange it into alphabetical order.

******************************************************************************}

procedure alpsym(var sp: symptr);

var dp:   symptr; { destination list }
    tp:   symptr; { holding pointer }
    p, l: symptr; { list pointers }

begin

   dp := nil; { clear destination list }
   while sp <> nil do begin { remove entries from source list }

      tp := sp; { index top symbol }
      sp := sp^.next; { gap from source list }
      if dp = nil then { destination list is empty }
         begin dp := tp; tp^.next := nil end { insert at list top }
      else if gtrp(tp^.lab^, dp^.lab^) then { new < dest }
         begin tp^.next := dp; dp := tp end { insert at top }
      else begin { in list middle somewhere }

         p := dp; { index top of list }
         while p <> nil do begin

            l := p; { set pointer to last }
            p := p^.next; { index next }
            if p <> nil then { there is a next entry } 
               if gtrp(tp^.lab^, p^.lab^) then
                  p := nil; { entry found, stop }

         end;
         tp^.next := l^.next; { link new to next }
         l^.next := tp { link new to last }

      end
       
   end;
   sp := dp { return new list }

end;   

{******************************************************************************

Form rip symbols list

Forms a list of the current scope level symbols, removing them from the symbols
table.

******************************************************************************}

procedure formlist(var sp: symptr);

var i: syminx; { index for symbol table }
    p: symptr; { pointer for symbols }

begin

   sp := nil; { clear result list }
   for i := 1 to symmax do begin { traverse the symbols head }

      p := symtbl[i]; { index the chain head }
      while p <> nil do { traverse }
         if p^.lvl = level then begin { this symbol matches the current scope }
       
            symtbl[i] := p^.next; { gap chain head }
            p^.next := sp; { link into list }
            sp := p;
            p := symtbl[i] { load the new top }

         end else p := nil { terminate search }

   end

end;

{******************************************************************************

Alphabetize symbols data

Alphabetizes the symbols deck, and moves it from the hash symbols table to
a linear list at the current blocks alpha list.

******************************************************************************}

procedure alphasym;

begin

   formlist(typstk^.als); { create symbols list from scope }
   alpsym(typstk^.als) { alphabetize the list }

end;

{******************************************************************************

List current scope symbols

This diagnostic lists all the symbols for the current scope. Typically used to
produce a listing of procedure/function/program/module symbols at the start
or end of the block.

Expects the symbols to be in the alpha list.

******************************************************************************}

procedure listsym;

var p, d, l: symptr;  { pointers for symbols }
    li:      integer; { index for labels }
    cl:      integer; { number of collumns output }
    lsmmax:  integer; { maximum list label length }

begin

   if fsym then begin { list symbols }

      p := typstk^.als; { index top of alpha list }
      l := p; { index top of list }
      lsmmax := 0; { set zero max }
      while l <> nil do begin { traverse list }

         { find label maximum }
         if len(l^.lab^) > lsmmax then lsmmax := len(l^.lab^);
         l := l^.next { link next }

      end;
      writeln; { space off }
      { output header }
      writeln('Symbols for block:'); 
      writeln;
      writeln('Depth: ', level:1);
      writeln; { space off }
      cl := 0; { clear collumn count }
      while p <> nil do begin { print labels }
   
         { print label with trailing spaces }
         for li := 1 to lsmmax do if li > max(p^.lab^) then write(' ')
                                  else write(p^.lab^[li]);
         write(' '); { separate }
         if p^.typ = nil then write('*') { output nil for type }
         else write(chr(ord('a')+ord(p^.typ^.t))); { output types as letters }
         { output structure/label status }
         if p^.str then write('s') else write('l');
         write('   '); { separate }
         cl := cl+1; { count collumns }
         if cl >= prtmax div (lsmmax+1+4+1+4+3+1) then { check overflow }
            begin writeln; cl := 0 end; { yes, start new line }
         d := p; { save symbol for disposal }
         p := p^.next; { index next symbol }
         putsym(d) { dispose of symbol }
   
      end;
      if cl <> 0 then writeln; { finish last line }
      writeln { space off }

   end else begin { purge with no list }

      formlist(p); { create symbols list from scope }
      while p <> nil do begin { purge }

         d := p; { save symbol for disposal }
         p := p^.next; { index next symbol }
         putsym(d) { dispose of symbol }

      end

   end  
   
end;

{******************************************************************************

Get new module name entry

Gets a new module name entry.

******************************************************************************}

procedure getmod(var mp: modptr);

begin

   new(mp); { get a new entry }
   mp^.next := nil; { terminate entry }
   mp^.name := nil; { set no name }
   mp^.mname := nil; { set module name empty }
   mp^.dup := false; { set not duplicated }
   mp^.ref := false { set not referenced }

end;

{******************************************************************************

Find module name entry

Finds a module name entry matching the given module name.

******************************************************************************}

function fndmod(view s: string): modptr;

var p, r: modptr; { pointers for symbol table }

begin
   
   r := nil; { clear result pointer }
   p := modtbl[hash(s, 0, modmax)]; { index the top entry }
   while p <> nil do begin { traverse chain }

      if compp(s, p^.name^) then begin { entry found }

         r := p; { place result pointer }
         p := nil { nix search pointer }

      end else p := p^.next { index next entry }

   end;
   fndmod := r { return result pointer }

end;

{******************************************************************************

Place module symbol

Places a new module name entry. Any previous module name is found, and if there
is one, it is flagged as a duplicate and no further action takes place. If not,
then the name is placed in a new module name entry.

Also counts module duplicates found.

******************************************************************************}

procedure newmod(view n: string; mn: pstring; var cnt: integer);

var p: modptr; { module name pointer }
    i: modinx; { index for module name table }

begin

   p := fndmod(n); { find any previous module export by that name }
   if p <> nil then begin

      p^.dup := true; { flag as duplicate }
      cnt := cnt+1 { count duplicates }

   end else begin { enter new module name }

      getmod(p); { get a new entry }
      copyp(p^.name, n); { place name }
      p^.mname := mn; { place module name }
      i := hash(n, 0, modmax); { find the top entry }
      p^.next := modtbl[i]; { place the next entry link }
      modtbl[i] := p { plant our symbol }

   end

end;   

{******************************************************************************

Get type entry

Gets a new type entry. First, checks if a type entry is available in the free
list with the same type as given. To accomplish this, a different free list
is kept for each type of entry. This is required since each type entry can
be a different length.
If no free entrys of that type are available, a new entry is allocated, with
the size appropriate for the given type.

******************************************************************************}

procedure gettyp(var tp: typptr;  { returns the type entry }
                      t:  types); { type of entry }

begin

   if typfre[t] <> nil then begin { return existing entry }
  
      tp := typfre[t]; { index top entry }
      typfre[t] := tp^.next { gap the list }
      
   end else begin

      { get a new entry with the proper type. It must be allocated with
        a constant, so we have to decode the type given }
      case t of { type }

         tudf:     new(tp, tudf);
         tvoid:    new(tp, tvoid);
         tint:     new(tp, tint);
         tfloat:   new(tp, tfloat);
         tlab:     new(tp, tlab);
         ticst:    new(tp, ticst);
         tscst:    new(tp, tscst);
         tccst:    new(tp, tccst);
         tfcst:    new(tp, tfcst);
         tarrcst:  new(tp, tarrcst);
         tarrcel:  new(tp, tarrcel);
         treccst:  new(tp, treccst);
         treccel:  new(tp, treccel);
         tenum:    new(tp, tenum);
         tenme:    new(tp, tenme);
         tptr:     new(tp, tptr);
         tarray:   new(tp, tarray);
         tstruct:  new(tp, tstruct);
         tfield:   new(tp, tfield);
         tunion:   new(tp, tunion);
         tvar:     new(tp, tvar);
         tfunc:    new(tp, tfunc);
         tfunci:   new(tp, tfunci);
         tpar:     new(tp, tpar);

      end;
      tp^.t := t { set type of entry }

   end;
   tp^.next := nil; { set no next }
   tp^.tfs := []; { set no typing flags }
   tp^.size := 0; { clear size }
   tp^.algn := 1; { set byte align }
   tp^.drv := nil; { set no derivation }
   tp^.sym := nil; { set no symbol }
   tp^.out := false; { set not output }
   tp^.rem := false; { no remove from output }
   tp^.rma := false { no remove from assembler output }

end;

{******************************************************************************

Put type entry

Inserts the given type entry into the free type list appropriate to that type.

******************************************************************************}

procedure puttyp(tp: typptr); { entry to place }

begin

   tp^.next := typfre[tp^.t]; { link to head }
   typfre[tp^.t] := tp { and place new head }

end;

{******************************************************************************

Get list type

Same as gettyp, but automatically inserts the entry into the current scope 
type list.
The entry is also assigned a type sequence number, and the next sequence number
set active.

******************************************************************************}

procedure lsttyp(var tp: typptr; { returns the type entry }
                     t:  types); { type of entry }

begin

   gettyp(tp, t); { get a type entry }
   tp^.next := nil; { set no next entry }
   if typstk^.lst <> nil then typstk^.lst^.next := tp { insert at end }
   else typstk^.typ := tp; { insert at beginning }
   typstk^.lst := tp { set new last }

end;

{******************************************************************************

Purge types list

Purges the current scope type list, moving all the entries there to the free
list.

******************************************************************************}

procedure purget;

var tp: typptr; { pointer for type entries }

begin

   while typstk^.typ <> nil do begin { while entries left in types list }

      tp := typstk^.typ; { index top entry }
      typstk^.typ := typstk^.typ^.next; { gap top of list }
      puttyp(tp) { free entry }

   end

end;   

{******************************************************************************

Compare types

Compares two type entries to each other, and returns true if they match. All
fields and subtrees are matched.

******************************************************************************}

function comptype(tp1, tp2: typptr): boolean;

function comptypec(tp1, tp2: typptr; nc: integer): boolean;

var m: boolean; { match flag }

begin

   nc := nc+1; { increment nesting count }
   if nc > nestmax then error(ecmpnst, ''); { flag nesting error }
   m := true; { set matches by default }
   if tp1 <> tp2 then begin { not the same type }

      if (tp1 = nil) <> (tp2 = nil) then m := false;
      if (tp1 <> nil) and (tp2 <> nil) then begin

         if (tp1^.t <> tp2^.t) or 
            (tp1^.tfs-[tftypedef, tfextern] <> 
             tp2^.tfs-[tftypedef, tfextern]) then
            m := false; { no type match }
         if m then case tp1^.t of { match individual fields }

            tudf:     ; 
            tvoid:    ;
            tint:     ;
            tfloat:   ; 
            tlab:     ; 
            ticst:    if tp1^.ival <> tp2^.ival then m := false;
            tscst:    if not compc(tp1^.sval^, tp2^.sval^) then m := false;
            tccst:    if tp1^.cval <> tp2^.cval then m := false; 
            tfcst:    if tp1^.fval <> tp2^.fval then m := false;
            tarrcst:  if not comptypec(tp1^.arcn, tp2^.arcn, nc) then m := false;
            tarrcel:  begin
   
               if not comptypec(tp1^.aren, tp2^.aren, nc) then m := false;
               if not comptypec(tp1^.arec, tp2^.arec, nc) then m := false
   
            end;
            treccst:  if not comptypec(tp1^.recn, tp2^.recn, nc) then m := false;
            treccel:  begin
   
               if not comptypec(tp1^.reen, tp2^.reen, nc) then m := false;
               if not comptypec(tp1^.reec, tp2^.reec, nc) then m := false
   
            end;
            tenum:    if not comptypec(tp1^.enc, tp2^.enc, nc) then m := false;
            tenme:    begin
   
               if not comptypec(tp1^.enx, tp2^.enx, nc) then m := false;
               if not comptypec(tp1^.enh, tp2^.enh, nc) then m := false;
               if tp1^.env <> tp2^.env then m := false
   
            end;
            { if we tour pointer types, we will get into loops, so, 
              unfortunately, we must use strict equivalence for pointer types }
            tptr:     if tp1^.ptrt <> tp2^.ptrt then begin

               if tp1^.ptrt = nil then m := false { nowhere to go }
               else begin

                  if (tp1^.ptrt^.t <> tstruct) and (tp1^.ptrt^.t <> tunion) then
                     begin

                     if not comptypec(tp1^.ptrt, tp2^.ptrt, nc) then m := false

                  end else m := false

               end

            end;
            tarray:   begin
   
               if not comptypec(tp1^.arrt, tp2^.arrt, nc) then m := false;
               if tp1^.arre <> tp2^.arre then m := false
   
            end;
            tstruct:  if not comptypec(tp1^.strf, tp2^.strf, nc) then m := false;
            tunion:   if not comptypec(tp1^.unif, tp2^.unif, nc) then m := false;
            tfield:   begin
   
               if not comptypec(tp1^.fldn, tp2^.fldn, nc) then m := false;
               if tp1^.fldb <> tp2^.fldb then m := false;
               if not comptypec(tp1^.fldt, tp2^.fldt, nc) then m := false
   
            end;
            tvar:     begin
   
               if not comptypec(tp1^.vart, tp2^.vart, nc) then m := false;
               if not comptypec(tp1^.varc, tp2^.varc, nc) then m := false;
   
            end;
            tfunc:    begin
   
               if not comptypec(tp1^.fncp, tp2^.fncp, nc) then m := false;
               if not comptypec(tp1^.fncr, tp2^.fncr, nc) then m := false;
               if tp1^.fncv <> tp2^.fncv then m := false
         
            end;
            tfunci:   if not comptypec(tp1^.fnit, tp2^.fnit, nc) then m := false;
            tpar:     begin
   
               if not comptypec(tp1^.parn, tp2^.parn, nc) then m := false;
               if not comptypec(tp1^.part, tp2^.part, nc) then m := false;
   
            end;
   
         end

      end

   end;

   comptypec := m { return match status }

end;

begin

   comptype := comptypec(tp1, tp2, 1)

end;

{******************************************************************************

Copy type

Make a copy of the type entry to a new entry.

******************************************************************************}

procedure copytype(var dtp: typptr; stp: typptr);

begin

   lsttyp(dtp, stp^.t); { get result entry }
   dtp^.tfs := stp^.tfs; { copy type flags }
   dtp^.size := stp^.size; { copy size }
   dtp^.algn := stp^.algn; { copy alignment }
   dtp^.drv := stp^.drv; { derived from type }
   dtp^.sym := stp^.sym; { associated symbol }
   dtp^.out := stp^.out; { this entry has been output to header file }
   dtp^.rem := stp^.rem; { remove from output deck }
   dtp^.rma := stp^.rma; { remove from assembly output deck }
   case dtp^.t of { type }

      tudf:     ;
      tvoid:    ;
      tint:     ;
      tfloat:   ;
      tlab:     ;
      ticst:    dtp^.ival := stp^.ival;
      tscst:    dtp^.sval := stp^.sval;
      tccst:    dtp^.cval := stp^.cval;
      tfcst:    dtp^.fval := stp^.fval;
      tarrcst:  dtp^.arcn := stp^.arcn;
      tarrcel:  begin

         dtp^.aren := stp^.aren;
         dtp^.arec := stp^.arec

      end;
      treccst:  dtp^.recn := stp^.recn;
      treccel:  begin

         dtp^.reen := stp^.reen;
         dtp^.reec := stp^.reec

      end;
      tenum:    dtp^.enc := stp^.enc;
      tenme:    begin

         dtp^.enx := stp^.enx;
         dtp^.enh := stp^.enh;
         dtp^.env := stp^.env

      end;
      tptr:     begin

         dtp^.ptrt := stp^.ptrt;
         dtp^.ptrts := stp^.ptrts

      end;
      tarray:   begin

         dtp^.arrt := stp^.arrt;
         dtp^.arrts := stp^.arrts;
         dtp^.arre := stp^.arre

      end;
      tstruct:  begin

         dtp^.strf := stp^.strf;
         dtp^.strl := stp^.strl

      end;
      tunion:   begin

         dtp^.unif := stp^.unif;
         dtp^.unil := stp^.unil;
         dtp^.unit := stp^.unit

      end;
      tfield:   begin

         dtp^.fldn := stp^.fldn;
         dtp^.fldh := stp^.fldh;
         dtp^.fldb := stp^.fldb;
         dtp^.fldt := stp^.fldt;
         dtp^.fldts := stp^.fldts

      end;
      tvar:     begin

         dtp^.vart := stp^.vart;
         dtp^.varc := stp^.varc

      end;
      tfunc:    begin

         dtp^.fncp   := stp^.fncp;
         dtp^.fncr   := stp^.fncr;
         dtp^.fncrs  := stp^.fncrs;
         dtp^.fncl   := stp^.fncl;
         dtp^.fncv   := stp^.fncv;
         dtp^.fncrps := stp^.fncrps;
         dtp^.fncras := stp^.fncras;
         dtp^.fncrno := stp^.fncrno

      end;
      tfunci:   dtp^.fnit := stp^.fnit;
      tpar:     begin

         dtp^.parn   := stp^.parn;
         dtp^.part   := stp^.part;
         dtp^.parts  := stp^.parts;
         dtp^.parh   := stp^.parh;
         dtp^.parps  := stp^.parps;
         dtp^.paras  := stp^.paras;
         dtp^.partps := stp^.partps;
         dtp^.partas := stp^.partas;
         dtp^.pareld := stp^.pareld;
         dtp^.pareas := stp^.pareas

      end;

   end

end;

{******************************************************************************

Fixup derived types in types list

Its possible to create dangling structs, enums or unions, by deriving from
their types while they are abstract. This routine fixes those by following
the derived type linkages.

******************************************************************************}

procedure fixdrv(dtp: typptr);

var tp: typptr; { type pointer }

begin

   tp := typstk^.typ; { index top of type list }
   while tp <> nil do begin { traverse list }

      if tp^.drv = dtp then begin { this type is derived }

         if not (tp^.t in [tstruct, tunion, tenum]) then error(esys45, '');
         if tp^.t <> dtp^.t then error(esys46, '');
         case tp^.t of { type }

            tstruct: begin

               tp^.strf := dtp^.strf; { copy field list }
               tp^.strl := dtp^.strl { copy field labels } 

            end;
            tunion: begin
 
               tp^.unif := dtp^.unif; { copy field list }
               tp^.unil := dtp^.unil { copy field labels } 

            end;
            tenum: tp^.enc := dtp^.enc { copy enumerated list }

         end

      end;
      tp := tp^.next { next entry }

   end

end;

{******************************************************************************

List all labels indexing type

Lists all of the labels found indexing the given type.

******************************************************************************}

procedure listlab(tp: typptr); 

var i: syminx; { index for symbol table }
    p: symptr; { pointer for symbols }

begin

   for i := 1 to symmax do begin { traverse the symbols head }

      p := symtbl[i]; { index the chain head }
      while p <> nil do begin { tranverse chain }

         { check symbol indexes the type entry }
         if (p^.typ = tp) then begin 

            write('[');
            write(output, p^.lab^:0); { print label }
            write('] ') { space off }

         end;
         p := p^.next { next symbol }

      end

   end

end;

{******************************************************************************

List all recortd labels indexing type

Lists all of the record labels found indexing the given type. The record labels
are found in the provided record symbols list.

******************************************************************************}

procedure listrec(tp: typptr; sp: symptr);

begin

   while sp <> nil do begin

      if sp^.typ = tp then begin

         write(output, sp^.lab^:0); { print label }
         write(': ') { space off }

      end;
      sp := sp^.next { next symbol }

   end

end;

{******************************************************************************

List number and label for type.

Lists the entry number and label for the given type.

******************************************************************************}
   
procedure listety(tp: typptr; ll: boolean);

var p:    typptr;  { type entry pointer }
    c, m: integer; { entry counts }
    sp:   tpsptr;  { type lists pointer }

begin

   sp := typstk; { index top of stack }
   m := 0; { set no match }
   if tp = nil then write('<nil>') { write marker for nil }
   else while sp <> nil do begin { traverse the type level stack }

      p := sp^.typ; { index top of list }
      c := 1; { set 1st entry }
      m := 0; { set no match }
      while p <> nil do begin { traverse list }
      
         { if this is the entry, save the list count and stack count }
         if p = tp then m := c;
         p := p^.next; { next entry }
         c := c + 1 { count entries }
      
      end;
      { if matched, print block number and entry number }
      if m <> 0 then begin

         if ll then listlab(tp); { output label(s), if present }
         write(m:1)

      end;
      sp := sp^.next

   end

end;

{******************************************************************************

List type entry

Outputs the labels for the given type, then dumps a diagnostic for that type.

******************************************************************************}

procedure listtype(tp: typptr);

var si: integer; { index for string }

begin

   { do nil check, makes it more convient as a diagnostic routine }
   if tp = nil then writeln('<nil>')
   else begin

      listlab(tp); { output any labels attached }
      if [tfauto, tfregister, tfstatic, tfextern, tftypedef]*tp^.tfs <> [] then
         begin

         write('c: [');
         if tfauto in tp^.tfs then write('auto ');
         if tfregister in tp^.tfs then write('register ');
         if tfstatic in tp^.tfs then write('static ');
         if tfextern in tp^.tfs then write('extern ');
         if tftypedef in tp^.tfs then write('typedef ');
         write('] ')

      end;
      if [tfconst, tfvolatile]*tp^.tfs <> [] then begin

         write('q: [');
         if tfconst in tp^.tfs then write('const ');
         if tfvolatile in tp^.tfs then write('volatile ');
         write('] ')

      end;
      if [tfvoid, tfchar, tfshort, tfint, tflong, tffloat, tfdouble, tfsigned,
          tfunsigned]*tp^.tfs <> [] then begin

         write('t: [');
         if tfvoid in tp^.tfs then write('void ');
         if tfchar in tp^.tfs then write('char ');
         if tfshort in tp^.tfs then write('short ');
         if tfint in tp^.tfs then write('int ');
         if tflong in tp^.tfs then write('long ');
         if tffloat in tp^.tfs then write('float ');
         if tfdouble in tp^.tfs then write('double ');
         if tfsigned in tp^.tfs then write('signed ');
         if tfunsigned in tp^.tfs then write('unsigned ');
         write('] ')

      end;
      write('size: ', tp^.size:1);
      write(' align: ', tp^.algn:1);
      write(' drv: ');
      listety(tp^.drv, true);
      write(' type: ');
      case tp^.t of { type }
      
         tudf: writeln('undefined');           
         tvoid: writeln('void'); 
         tint: writeln('int');
         tfloat: writeln('float');
         tlab: write('goto label');
         ticst: writeln('integer constant: ', tp^.ival:1);
         tscst: begin 

            write('string constant: '''); 
            for si := 1 to max(tp^.sval^) do write(tp^.sval^[si]);
            writeln('''') 

         end; 
         tccst: writeln('Character constant: ''', tp^.cval, '''');
         tfcst: writeln('floating point constant: ', tp^.fval);
         tarrcst: begin

            write('Array constant, start: ');
            listety(tp^.arcn, true);
            writeln

         end;
         tarrcel: begin

            write('Array constant element, next: ');
            listety(tp^.aren, true);
            write(' constant: ');
            listety(tp^.arec, true);
            writeln

         end;
         treccst: begin

            write('Record constant, start: ');
            listety(tp^.recn, true);
            writeln

         end;
         treccel: begin

            write('Record constant element, next: ');
            listety(tp^.reen, true);
            write(' constant: ');
            listety(tp^.reec, true);
            writeln

         end;
         tenum: begin 

            write('enumerated head, start: '); 
            listety(tp^.enc, true); 
            writeln 

         end;
         tenme: begin 

            write('enumerated value: ', tp^.env:1, ' next: ');
            listety(tp^.enx, true); 
            write(' head: '); 
            listety(tp^.enh, true); 
            writeln 

         end;
         tptr: begin 

            write('pointer, base: '); 
            listety(tp^.ptrt, true); 
            writeln 

         end;
         tarray: begin 

            write('array, base: '); 
            listety(tp^.arrt, true); 
            writeln(' number of elements: ', tp^.arre:1) 

         end;
         tstruct: begin 
  
            write('structure, field list: '); 
            listety(tp^.strf, true); 
            writeln 

         end;
         tunion: begin 
  
            write('union, field list: '); 
            listety(tp^.unif, true); 
            writeln 

         end;
         tfield: begin 

            if tp^.fldh^.t = tstruct then listrec(tp, tp^.fldh^.strl)
            else listrec(tp, tp^.fldh^.unil);
            write('structure field, base: '); 
            listety(tp^.fldt, true); 
            write(' next: '); 
            listety(tp^.fldn, true); 
            write(' head: '); 
            listety(tp^.fldh, true); 
            writeln 

         end;
         tvar: begin 

            write('variable, base: '); 
            listety(tp^.vart, true); 
            write(' constant fill: '); 
            listety(tp^.varc, true); 
            writeln 

         end;
         tfunc: begin 

            write('function, parameter start: '); 
            listety(tp^.fncp, true); 
            write(' result: '); 
            listety(tp^.fncr, true); 
            if tp^.fncv then write(' variable param');
            writeln 

         end;
         tfunci: begin 

            write('function instantiation, base: '); 
            listety(tp^.fnit, true); 
            writeln 

         end;
         tpar: begin 

            write('parameter, base: '); 
            listety(tp^.part, true);
            write(' next: '); 
            listety(tp^.parn, true); 
            write(' head: ');
            listety(tp^.parh, true);
            writeln 

         end;
      
      end

   end

end;   

{******************************************************************************

List all types in current block

A diagnostic, prints a list of all the types in the current block, with 
fields. Also prints any symbols in existence that reference the type.
This is not a particularly fast routine, as it uses a stupid search to find the
symbols and types.

******************************************************************************}

procedure listtyp;

var tp: typptr;  { pointer for type entries }
    c:  integer; { entry counts }


begin

   if ftype then begin { types output mode on }

      writeln; { space off }
      tp := typstk^.typ; { index top of list }
      c := 1; { set 1st entry }
      while tp <> nil do begin { traverse list }
   
         write(c:6, ': '); { output entry number }
         listtype(tp); { output type entry }
         c := c + 1; { count entries }
         tp := tp^.next { next entry }
   
      end

   end
   
end;   

{******************************************************************************

Diagnostic list symbols

Lists all symbols, in place, in the symbols table.

******************************************************************************}

procedure diagsym;

var i: syminx; { index for symbol table }
    p: symptr; { pointer for symbols }

begin

   writeln;
   writeln('Symbols:');
   writeln;
   for i := 1 to symmax do begin { traverse the symbols head }

      p := symtbl[i]; { index the chain head }
      while p <> nil do begin { traverse }

         { print entry }
         write(p^.lvl:1, ': ', p^.lab^, ' type: ');
         listety(p^.typ, false);
         writeln(' str: ', p^.str);
         p := p^.next { link next }

      end

   end

end;

{******************************************************************************

Stack new types list

Adds a new level to the types list, corresponding to a new block.

*******************************************************************************}

procedure bgnblk;

var ts: tpsptr; { stack list pointer }

begin

   if tpsfre <> nil then begin { recover entry from free list }

      ts := tpsfre; { index top entry }
      tpsfre := tpsfre^.next { gap list }
      
   end else new(ts); { get new list entry }
   ts^.next := typstk; { link to top of stack }
   typstk := ts; { place new top }
   ts^.typ := nil; { clear new list }
   ts^.als := nil; { clear alpha list }
   ts^.lst := nil; { set no last entry }
   level := level+1 { start new label level }

end;

{******************************************************************************

Pop types list

Removes the top types list. It is a system error if the stack is empty.

*******************************************************************************}

procedure endblk;

var ts: tpsptr; { type list entry pointer }

begin

   if typstk = nil then error(esys15, ''); { stack empty }   
   ts := typstk; { index top entry }
   typstk := typstk^.next; { remove top entry }
   ts^.next := tpsfre; { link into free list }
   tpsfre := ts;
   level := level-1; { back out label level }
   if level < 0 then error(esys16, '') { underflow }

end;

{******************************************************************************

Register symbols

Register symbols in the caseless/keyword database. Each symbol is placed in
the global names table, which keeps track of both caseless duplicates and
keyword duplicates. The result is an instance number, that is given to the
symbol. Instances > 1 are coined.

******************************************************************************}

procedure regsym;

var i: syminx; { index for symbol table }
    p: symptr; { pointer for symbols }

begin

   for i := 1 to symmax do begin { traverse the symbols head }

      p := symtbl[i]; { index the chain head }
      while p <> nil do begin { traverse }

         newnam(p^.lab^, p^.inst); { place name and get instance }
         p := p^.next { link next }

      end

   end

end;

{******************************************************************************

Output coined symbol definitions

Outputs a table of symbols that had to be coined in _2 form because of case
duplication.

The symbols must be in the alpha list.

******************************************************************************}

procedure repcsym(var f: text);

var p: symptr;    { pointer for symbols }
    cnt: integer; { count of unresolved }

begin

   cnt := 0; { clear counter }
   p := typstk^.als; { index the top of the alpha list }
   while p <> nil do begin { traverse }

      if p^.inst > 1 then begin { symbol is duplicate instance }

         if cnt = 0 then begin { first unresolved, output header }

            writeln(f);
            writeln(f, '{ *** Report *** Symbols whose names were case ',
                       'sensitive }');
            writeln(f);
            writeln(f, '{');
            writeln(f)

         end;
         writeln(f, p^.lab^, ' -> ', p^.lab^, '_', p^.inst:1);
         cnt := cnt+1 { count }

      end;
      p := p^.next { link next }

   end;
   if cnt > 0 then begin { output ending }

      writeln(f);
      writeln(f, '}')

   end;
   if cnt > 0 then begin { output tally }

      writeln(f);
      writeln(f, '{ ', cnt:1, ' Total coined symbols }');
      writeln(f)

   end

end;

{******************************************************************************

Output duplicate module exports report

Outputs a report on all export references that were also duplicates.

******************************************************************************}

procedure repdexp(var f: text);

var i:   modinx;  { index for symbol table }
    p:   modptr;  { pointer for symbols }
    cnt: integer; { count of unresolved }

begin

   cnt := 0; { clear counter }
   for i := 1 to modmax do begin { traverse the module name head }

      p := modtbl[i]; { index the chain head }
      while p <> nil do begin { traverse }

         if p^.dup and p^.ref then begin { its a referenced duplicate }

            if cnt = 0 then begin { first unresolved, output header }

               writeln(f);
               writeln(f, '!');
               writeln(f, '! *** Report *** Module exports that are referenced',
                          ' and are duplicates }');
               writeln(f, '!');
               writeln(f)

            end;
            writeln(f, '! Module: ', p^.mname^, ' Export: ', p^.name^);
            cnt := cnt+1 { count }

         end;
         p := p^.next { link next }

      end

   end;
   if cnt > 0 then begin { output ending and tally }

      writeln(f);
      writeln(f, '!');
      writeln(f, '! ', cnt:1, ' Total referenced duplicate exports');
      writeln(f, '!');
      writeln(f);
      writeln('There were ', cnt:1, ' total referenced duplicate exports')

   end

end;

{******************************************************************************

Output unconnected module exports report

This report gives all of the external functions that did not connect up to a
module export in the catalog.

*******************************************************************************}

procedure repuexp(var f: text);

var tp:  typptr;  { pointers for types list }
    mp:  modptr;  { module name entry pointer }
    cnt: integer; { count of unresolved }

begin

   cnt := 0; { clear counter }
   tp := typstk^.typ; { index top of type list }
   while tp <> nil do begin { traverse list }

      if (tp^.t = tfunc) and (tfextern in tp^.tfs) and not tp^.rma and 
         not tp^.rem then begin

         { find the module export }
         if tp^.fncrno <> nil then mp := fndmod(tp^.fncrno^.lab^)
         else mp := fndmod(tp^.sym^.lab^);
         { if there is no associated export, we just skip this entry. it will
           show up in the report }
         if mp = nil then begin { there is an export }

            if cnt = 0 then begin { first unresolved, output header }

               writeln(f, '!');
               writeln(f, '! Functions that did not have matching module exports in the');
               writeln(f, '! catalog');
               writeln(f, '!');
               writeln(f)

            end;
            write(f, '! Function: ');
            if tp^.fncrno <> nil then write(f, tp^.fncrno^.lab^:0)
            else write(f, tp^.sym^.lab^:0);
            writeln(f);
            cnt := cnt+1 { count }

         end
      
      end;
      tp := tp^.next { next entry }

   end;
   if cnt > 0 then begin { output ending and tally }

      writeln(f);
      writeln(f, '!');
      writeln(f, '! ', cnt:1, ' Total unmatched exports');
      writeln(f, '!');
      writeln(f);
      writeln('There were ', cnt:1, ' total unmatched exports')

   end

end;

{******************************************************************************

Place symbol links in types

Tours the symbol table and places links to symbols into the types list.
Symbols are redundant, with more than one symbol indexing each type. However,
all such symbols are equivalent in type, so one symbol is as good as another
to refer to that type.
Each symbol that references a type is pushed onto its referencing list.

*******************************************************************************}

procedure namtyp;

var i:  syminx; { index for symbol table }
    tp: typptr; { pointers for types list }

procedure plclnk(p: symptr); { place symbol links }

begin

   while p <> nil do begin { tranverse chain }

      { if a type exists, tie that back to the symbol }
      if p^.typ <> nil then begin

         p^.tlst := p^.typ^.sym; { push onto list }
         p^.typ^.sym := p

      end;
      p := p^.next { next symbol }

   end

end;

begin

   { names in symbols table }
   for i := 1 to symmax do { traverse the symbols head }
      plclnk(symtbl[i]); { process that chain }
   { names imbedded in type structures (like records) }
   tp := typstk^.typ; { index top of type list }
   while tp <> nil do begin { traverse list }
   
      { structure, union or function }
      if tp^.t = tstruct then plclnk(tp^.strl) { struct }
      else if tp^.t = tunion then plclnk(tp^.unil) { union }
      else if tp^.t = tfunc then plclnk(tp^.fncl); { function }
      tp := tp^.next { next entry }
   
   end

end;

{******************************************************************************

Coin type id

Coins a new type id, and returns the symbol pointer. Note that coined names
don't have to be part of the symbol table.

*******************************************************************************}

procedure coinsym(var p: symptr);

var coinn: packed array [1..maxstr] of char; { coined name holder }
    tmp:   packed array [1..maxstr] of char; { holder for coined number }

begin

   copy(coinn, 'c_lang_type_'); { place base of coined name }
   ints(tmp, typnum); { find current type instance }
   typnum := typnum+1; { next type }
   cat(coinn, tmp); { add that to the end }
   getsym(p); { get a new symbol }
   copyp(p^.lab, coinn); { place symbol }
   p^.gen := true { set generated }

end;

{******************************************************************************

Clear output flags

Clears all of the tree pruning flags in type entries.

*******************************************************************************}

procedure clrout;

var tp: typptr; { pointer for types list }

begin

   tp := typstk^.typ; { index top of type list }
   while tp <> nil do begin { traverse list }

      tp^.out := false; { clear flag }
      tp := tp^.next { next entry }

   end

end;

{******************************************************************************

Check incomplete type

Checks if the given type, or any type under it, is incomplete, that is,
contains nil subtypes.

*******************************************************************************}

procedure chktype(tp: typptr; var inc: boolean);

var tp1: typptr; { pointer for types list }
    fout: boolean; { output flag }

begin

   { to stop recursion back to this entry, we set it processed even before we
     do anything. the flag means "I have it handled" }
   fout := tp^.out; { get the flag }
   tp^.out := true; { set processed }
   inc := false; { set not incomplete }
   if not fout then case tp^.t of { type }

      tudf:     ;
      tvoid:    ;
      tlab:     ;
      tint:     ;
      tfloat:   ;
      ticst:    ;
      tscst:    ;
      tccst:    ;
      tfcst:    ;
      tarrcst:  ;
      tarrcel:  ;
      treccst:  ;
      treccel:  ;
      tenum:    ;
      tenme:    ;
      tptr:     begin

         if tp^.ptrt = nil then inc := true { no subtype }
         else chktype(tp^.ptrt, inc) { check subtype }

      end;
      tarray:   begin

         if tp^.arrt = nil then inc := true { no subtype }
         else chktype(tp^.arrt, inc) { go subtype }

      end;
      tstruct,
      tunion:   begin

         { structure or union }
         if tp^.t = tstruct then tp1 := tp^.strf { index field list }
         else tp1 := tp^.unif;
         if tp1 = nil then inc := true { no subtype }
         else begin

            if tp1^.t = tudf then inc := true { undefined leaf }
            else while (tp1 <> nil) and not inc do begin { traverse }

               if tp1^.t <> tfield then error(esys17, ''); { should be field }
               if tp1^.fldt = nil then inc := true { no subtype }
               else chktype(tp1^.fldt, inc); { go subtype }
               tp1 := tp1^.fldn { link next }

            end

         end

      end;
      tfield:   ;
      tvar:     ;
      tfunc:    begin

         if tp^.fncr = nil then inc := true { no subtype }
         else chktype(tp^.fncr, inc); { go subtype }
         if tp^.fncp <> nil then begin { there is a parameter list }

            tp1 := tp^.fncp; { index }
            while (tp1 <> nil) and not inc do begin { traverse }

               if tp1^.t <> tpar then error(esys18, ''); { should be parameter }
               if tp1^.part = nil then inc := true { no subtype }
               else chktype(tp1^.part, inc); { go subtype }
               tp1 := tp1^.parn { next }
               
            end

         end

      end;
      tfunci:   ;
      tpar:     begin

         if tp^.part = nil then inc := true { no subtype }
         else chktype(tp^.part, inc) { go subtype }

      end

   end

end;

{******************************************************************************

Check incomplete types

Checks all named types for incomplete subtypes. We use the flag touring method.
Each named type is checked to depth N, with any flagged branch indicating a
good one. This is true because we stop and reset all flags on an error.
The idea is to find all the incomplete named types on the first pass, and not
have some errors hiding others.

*******************************************************************************}

procedure chktypes;

var tp:  typptr;   { pointer for types list }
    inc: boolean;  { incomplete flag }
    incs: integer; { incomplete type counter }

begin

   incs := 0; { clear incomplete types list }
   clrout; { clear process flags }
   tp := typstk^.typ; { index top of type list }
   while tp <> nil do begin { traverse list }

      if tp^.sym <> nil then begin

         { type is named, and not already processed }
         chktype(tp, inc); { this type is named and not flagged, process }
         { flag incomplete type }
         if inc then begin

            writeln('Incomplete type: ', tp^.sym^.lab^);
            incs := incs+1; { count }
            { now we clear to cause recheck on the next label }
            clrout { clear process flags }

         end

      end;
      tp := tp^.next { next entry }

   end;
   if incs > 0 then begin

      writeln('There were ', incs:1, ' incomplete types');
      writeln('Halting');
      terminate

   end;

end;

{******************************************************************************

Coin anonymous types

Looks in the types deck for anonymous types that need naming. Pascal requires
type names for several situations where C takes a general type. The solution is
to name such types, which are then output as formal, named types.
Further, to simplify processing of types in general, the types are "flattened",
that is, each type that is used to construct another type (a complex type) is
given a coined name. This dramatically simplifies processing of heyarchal types,
and essentially leaves that work to the Pascal compiler.

*******************************************************************************}

procedure cointype(tp: typptr);

var tp1:  typptr; { pointer for types list }
    sp:   symptr; { pointer for symbols }
    fout: boolean; { output flag }

begin

   { to stop recursion back to this entry, we set it processed even before we
     do anything. the flag means "I have it handled" }
   fout := tp^.out; { get the flag }
   tp^.out := true; { set processed }
   if not fout then case tp^.t of { type }

      tudf:     ;
      tvoid:    ;
      tint:     ;
      tfloat:   ;
      tlab:     ;
      ticst:    ;
      tscst:    ;
      tccst:    ;
      tfcst:    ;
      tarrcst:  ;
      tarrcel:  ;
      treccst:  ;
      treccel:  ;
      tenum:    ;
      tenme:    ;
      tptr:     begin

         if tp^.ptrt <> nil then begin { pointer exists }

            if tp^.ptrt^.sym = nil then begin { base type is anonymous }

               coinsym(sp); { get a coined symbol }
               sp^.typ := tp^.ptrt; { link symbol to base type }
               tp^.ptrt^.sym := sp { link type to symbol }

            end;
            cointype(tp^.ptrt) { coin base }

         end

      end;
      tarray:   begin

         if tp^.arrt = nil then error(esys19, ''); { must not be nil }
         if tp^.arrt^.sym = nil then begin { no symbol }

            coinsym(sp); { get a coined symbol }
            sp^.typ := tp^.arrt; { link symbol to base type }
            tp^.arrt^.sym := sp { link type to symbol }

         end;
         cointype(tp^.arrt) { coin base }

      end;
      tstruct,
      tunion:   begin

         { structure or union }
         if tp^.t = tstruct then tp1 := tp^.strf { index field list }
         else tp1 := tp^.unif;
         if tp1^.t = tudf then error(esys64, ''); { undefined field list }
         while tp1 <> nil do begin { traverse }

            if tp1^.t <> tfield then error(esys20, ''); { should be field }
            if tp1^.sym = nil then begin { field should have name }

               coinsym(sp); { get a coined symbol }
               sp^.typ := tp1; { link symbol to base type }
               tp1^.sym := sp { link type to symbol }

            end;
            if tp1^.fldt^.sym = nil then begin { coin type name }

               coinsym(sp); { get a coined symbol }
               sp^.typ := tp1^.fldt; { link symbol to base type }
               tp1^.fldt^.sym := sp { link type to symbol }

            end;
            cointype(tp1^.fldt); { coin base }
            tp1 := tp1^.fldn { link next }

         end

      end;
      tfield:   ;
      tvar:     ;
      tfunc:    begin

         if tp^.fncr <> nil then { base type exists }
            if tp^.fncr^.sym = nil then begin { base type is anonymous }

            coinsym(sp); { get a coined symbol }
            sp^.typ := tp^.fncr; { link symbol to base type }
            tp^.fncr^.sym := sp { link type to symbol }

         end;
         cointype(tp^.fncr); { coin base }
         tp1 := tp^.fncp; { index parameters }
         while tp1 <> nil do begin { traverse parameter list }
         
            if tp1^.t <> tpar then error(esys58, ''); { must be param }
            if tp1^.sym = nil then begin

               coinsym(sp); { get a coined symbol }
               sp^.typ := tp1; { link symbol to base type }
               tp1^.sym := sp { link type to symbol }

            end;
            { must have type }
            if tp1^.part = nil then error(esys59, '');
            { type must have label }
            if tp1^.part^.sym = nil then begin

               coinsym(sp); { get a coined symbol }
               sp^.typ := tp1^.part; { link symbol to base type }
               tp1^.part^.sym := sp { link type to symbol }

            end;
            tp1 := tp1^.parn { link next }

         end

      end;
      tfunci:   ;
      tpar:     begin

         { coin the parameter itself }
         if tp^.sym = nil then begin

            coinsym(sp); { get a coined symbol }
            sp^.typ := tp; { link symbol to type }
            tp^.sym := sp { link type to symbol }

         end;
         if tp^.part <> nil then { base type exists }
            if tp^.part^.sym = nil then begin { base type is anonymous }

            coinsym(sp); { get a coined symbol }
            sp^.typ := tp^.part; { link symbol to base type }
            tp^.part^.sym := sp { link type to symbol }

         end;
         cointype(tp^.part) { coin base }

      end

   end

end;

{******************************************************************************

Coin types

Coins all subtypes of named types.

*******************************************************************************}

procedure cointypes;

var tp: typptr; { pointer for types list }

begin

   clrout; { clear process flags }
   tp := typstk^.typ; { index top of type list }
   while tp <> nil do begin { traverse list }

      if tp^.sym <> nil then
         cointype(tp); { this type is named and not flagged, process }
      tp := tp^.next { next entry }

   end

end;

{******************************************************************************

Set replacement parameter type

Accepts the symbol to be replaced, the Pascal side string and the assembler
side string. Parameters are looked for that directly implicate that type
(using the preferred symbol field), and those parameters get the replacement
data.

*******************************************************************************}

procedure setparrep(sp: symptr; view pas, asm: pstring);

var tp, tp1: typptr; { pointers for types list }

begin

   tp := typstk^.typ; { index top of type list }
   while tp <> nil do begin { traverse list }

      if tp^.t = tfunc then begin

         tp1 := tp^.fncp; { index 1st parameter }
         while tp1 <> nil do begin { traverse parameter list }
         
            if tp1^.parts = sp then begin { entry matches }

               tp1^.partps := pas; { place Pascal side }
               tp1^.partas := asm { place assembler side }

            end;
            tp1 := tp1^.parn { link next }

         end
      
      end;
      tp := tp^.next { next entry }

   end

end;

{******************************************************************************

Set replacement result type

Accepts the symbol to be replaced, the Pascal side string and the assembler
side string. Function results are looked for that directly implicate that type
(using the preferred symbol field), and those parameters get the replacement
data.

*******************************************************************************}

procedure setresrep(sp: symptr; view pas, asm: pstring);

var tp: typptr; { pointers for types list }

begin

   tp := typstk^.typ; { index top of type list }
   while tp <> nil do begin { traverse list }

      if tp^.t = tfunc then begin

         if tp^.fncrs = sp then begin { entry matches }

            tp^.fncrps := pas; { place Pascal side }
            tp^.fncras := asm { place assembler side }

         end

      end;
      tp := tp^.next { next entry }

   end

end;

{******************************************************************************

Clone function

Creates a complete alias of a function. Accepts a function type, and the
symbol for the new function. The reference level name will be the same as the
old function. The function type head and all parameters will be copied, meaning
that the parameters and function can be the subject of instructions without
modifying the original function.
The symbol must be in the symbols table, checked for duplication.

*******************************************************************************}

procedure clonefunc(fp: typptr; sp: symptr);

var nfp: typptr; { new function pointer }
    pp, npp, lpp: typptr; { parameter pointers }

begin

   copytype(nfp, fp); { copy the function head }
   sp^.typ := nfp; { link to type }
   nfp^.sym := sp; { link back to symbol }
   nfp^.fncrno := fp^.sym; { link reference to original }
   { if the original itself is a clone, then link back to the original root }
   if fp^.fncrno <> nil then nfp^.fncrno := fp^.fncrno;
   nfp^.fncp := nil; { clear result parameter list }
   lpp := nil; { set no last entry }
   pp := fp^.fncp; { index old parameters list }
   while pp <> nil do begin { traverse }

      copytype(npp, pp); { copy this parameter }
      if lpp = nil then nfp^.fncp := npp { place 1st parameter }
      else lpp^.parn := npp; { link to last }
      lpp := npp; { set new last }
      pp := pp^.parn { link next }

   end

end;

{******************************************************************************

Find elided parameter count

Counts the number of elided parameters in a function.

*******************************************************************************}

function eldcnt(fp: typptr) { function to count }
                : integer;  { result }

var cnt: integer; { counter }
    pp:  typptr;  { parameter pointer }

begin

   cnt := 0; { clear elide count }
   if fp^.t <> tfunc then error(esys93, ''); { must be function }
   pp := fp^.fncp; { index parameter list }
   while pp <> nil do begin
           
      if pp^.pareld then cnt := cnt+1; { count elide }
      pp := pp^.parn { next parameter }
   
   end;

   eldcnt := cnt { return }

end; 

{******************************************************************************

Output string to line

Outputs a string and increments the line counter.

*******************************************************************************}

procedure outstr(var f: text; view s: string);

begin

   write(f, s);
   lincnt := lincnt+max(s)

end;

{******************************************************************************

Break line

Process logical line break. The output line is checked for > 70, and a line
output if so. This routine is called at logical line breaks, such as between
symbols. Each new line is started off with a 3 space indentation.

*******************************************************************************}

procedure brklin(var f: text);

begin

   if lincnt > 70 then begin { wrap }

      writeln(f);
      write(f, '   ');
      lincnt := 0

   end

end;

{******************************************************************************

Terminate line

Terminates the present line, without indenting it. Used to finish a construct.

*******************************************************************************}

procedure trmlin(var f: text);

begin

   writeln(f); { terminate }
   lincnt := 1 { reset to line start }

end;

{******************************************************************************

Output symbol with prefixing and coining

Outputs a symbol, with "sc_" prefix, and adds a "_N" number for any
instance > 1.

*******************************************************************************}

procedure outsym(var f: text; sp: symptr);

begin

   outstr(f, 'sc_'); { output prefix }
   outstr(f, sp^.lab^); { output label }
   if sp^.inst > 1 then write(f, '_', sp^.inst:1)

end;

{******************************************************************************

Output enum type

Tours and outputs enumeration types. Because enum types in C are not
required to be consequtive, and are interchangeable with integers, it makes
more sense to declare them as integers than an enum type. Because they are
output as constants, this separate pass outputs them before all other types.

*******************************************************************************}

procedure outenum(var f: text; tp: typptr; var ef: boolean);

var tp1:  typptr;  { pointer for types }
    fout: boolean; { output flag }

begin

   { to stop recursion back to this entry, we set it processed even before we
     do anything. the flag means "I have it handled" }
   fout := tp^.out; { get the flag }
   tp^.out := true; { set processed }
   if not fout then begin { not already output }

      if tp^.t in [tenum, tptr, tarray, tstruct, tunion,
                   tfunc] then begin { is a type we output }

         if tp^.sym = nil then error(esys80, ''); { should have label }
         case tp^.t of { type }

            tenum:    begin

               if not ef then begin { output header }

                  writeln(f);
                  writeln(f, '{ enumerations changed to constants }');
                  writeln(f);
                  writeln(f, 'const');
                  writeln(f);
                  ef := true { set found }

               end;
               write(f, '{ ');
               outsym(f, tp^.sym); { output symbol }
               writeln(f, ' }');
               tp1 := tp^.enc; { index 1st enumeration entry }
               while tp1 <> nil do begin { output list entries }

                  if tp1^.t <> tenme then error(esys81, ''); { should be enum }
                  if tp1^.sym = nil then error(esys82, ''); { should have a name }
                  outsym(f, tp1^.sym); { write symbol }
                  writeln(f, ' = ', tp1^.env:1, ';');
                  tp1 := tp1^.enx { link next }

               end

            end;
            tptr: if tp^.ptrt^.sym^.gen then outenum(f, tp^.ptrt, ef);
            tarray: outenum(f, tp^.arrt, ef); { process base type }
            tstruct, tunion: begin

               { process base types }
               if tp^.t = tstruct then tp1 := tp^.strf { index field list }
               else tp1 := tp^.unif; { index field list }
               while tp1 <> nil do begin { output field entries }

                  if tp1^.t <> tfield then error(esys83, ''); { should be field }
                  outenum(f, tp1^.fldt, ef); { output }
                  tp1 := tp1^.fldn { next }

               end

            end;
            tfunc: begin

               if tfextern in tp^.tfs then begin { external function }

                  tp1 := tp^.fncp; { index parameters }
                  while tp1 <> nil do begin { traverse parameter list }
         
                     if tp1^.t <> tpar then error(esys84, ''); { must be param }
                     { must have type }
                     if tp1^.part = nil then error(esys85, '');
                     { type must have label }
                     if tp1^.part^.sym = nil then error(esys86, '');
                     outenum(f, tp1^.part, ef); { output parameter type }
                     tp1 := tp1^.parn { link next }

                  end;
                  { must have result }
                  if tp^.fncr = nil then error(esys87, '');
                  { that must have symbol }
                  if tp^.fncr^.sym = nil then error(esys88, '');
                  outenum(f, tp^.fncr, ef) { output result type }

               end

            end

         end

      end

   end

end;

{******************************************************************************

Output enum types

Outputs all the enumerated types as constants. Each type is later declared to
be an integer.

The symbols must be in the alpha list.

*******************************************************************************}

procedure outenums(var f: text);

var sp: symptr; { pointer for symbol table } 
    ef: boolean; { enumeration found flag }

begin

   ef := false; { set no enumeration found }
   clrout; { clear process flags }
   sp := typstk^.als; { index the top of the alpha list }
   { perform prime entry pass }
   while sp <> nil do begin { traverse that }

      if sp^.typ = nil then error(esys89, ''); { must have type }
      { must be backlinked to symbol }
      if sp^.typ^.sym = nil then error(esys90, '');
      { if the entry is prime, output it }
      if sp^.typ^.sym = sp then outenum(f, sp^.typ, ef); { output type }
      sp := sp^.next { next in list }

   end;
   if ef then writeln(f)

end;

{******************************************************************************

Check type is int

Checks if the given type is an int.

*******************************************************************************}

function chkint(tp: typptr): boolean;

var f: boolean;

begin

   f := (tp^.t = tint) and (tfint in tp^.tfs);

   chkint := f

end;

{******************************************************************************

Check type is a character pointer

Checks if the given type is a character pointer.

*******************************************************************************}

function chkchp(tp: typptr): boolean;

var f: boolean;

begin

   f := false;
   if tp^.t = tptr then { type is pointer }
      f := (tp^.ptrt^.t = tint) and (tfchar in tp^.ptrt^.tfs);

   chkchp := f

end;

{******************************************************************************

Check type is a constant character pointer

Checks if the given type is a constant character pointer.

*******************************************************************************}

function chkccp(tp: typptr): boolean;

var f: boolean;

begin

   f := false;
   if chkchp(tp) then begin

      { a pointer to a character, signed or unsigned, check const status }
      f := (tfconst in tp^.tfs) or (tfconst in tp^.ptrt^.tfs) 

   end;

   chkccp := f

end;

{******************************************************************************

Output common type

Given a type entry, checks and outputs common types, which are types that
evaluate to a single symbol.

*******************************************************************************}

procedure outcmt(var f: text; tp: typptr);

begin

   if tp^.sym^.gen then begin { no symbol represents this type }

      if tp^.t in [tvoid, tint, tfloat, tfunc] then case tp^.t of { type }

         tvoid: outstr(f, 'sc_c_lang_void');
         tint: begin

            if tfchar in tp^.tfs then begin { is character }

               outstr(f, 'sc_c_lang_');
               if tfsigned in tp^.tfs then outstr(f, 'signed_')
               else if tfunsigned in tp^.tfs then outstr(f, 'unsigned_');
               outstr(f, 'char')

            end else if tfint in tp^.tfs then begin { is integer }

               outstr(f, 'sc_c_lang_');
               if tfsigned in tp^.tfs then outstr(f, 'signed_')
               else if tfunsigned in tp^.tfs then outstr(f, 'unsigned_');
               if tfshort in tp^.tfs then outstr(f, 'short_')
               else if tflong in tp^.tfs then outstr(f, 'long_');
               outstr(f, 'int')

            end else if tfshort in tp^.tfs then begin

               outstr(f, 'sc_c_lang_');
               if tfsigned in tp^.tfs then outstr(f, 'signed_')
               else if tfunsigned in tp^.tfs then outstr(f, 'unsigned_');
               outstr(f, 'short_int')

            end else if tflong in tp^.tfs then begin

               outstr(f, 'sc_c_lang_');
               if tfsigned in tp^.tfs then outstr(f, 'signed_')
               else if tfunsigned in tp^.tfs then outstr(f, 'unsigned_');
               outstr(f, 'long_int')

            end else if tfsigned in tp^.tfs then
               outstr(f, 'sc_c_lang_signed_int')
            else if tfunsigned in tp^.tfs then
               outstr(f, 'sc_c_lang_unsigned_int')
            else error(esys22, '') { should have been one of those }

         end;
         tfloat: begin

            if tflong in tp^.tfs then outstr(f, 'sc_c_lang_long_double')
            else if tfdouble in tp^.tfs then outstr(f, 'sc_c_lang_double')
            else outstr(f, 'sc_c_lang_float')

         end;
         tfunc: write(f, 'sc_c_lang_function')

      end else outsym(f, tp^.sym)

   end else outsym(f, tp^.sym)

end;

{******************************************************************************

Check common type

Given a type entry, checks if it is a common type, which are types that
evaluate to a single symbol.

*******************************************************************************}

function chkcmt(tp: typptr): boolean;

begin

   chkcmt := tp^.sym^.gen and (tp^.t in [tvoid, tint, tfloat, tfunc])

end;

{******************************************************************************

Check if name is keyword

Checks if the supplied name is a keyword in Pascal. This is required because
names that are generated cannot duplicate keywords.

******************************************************************************}

function paskey(view n: string): boolean;

var f: boolean;

begin

   f := false; { set no match }
   if compp('div',       n) then f := true;
   if compp('mod',       n) then f := true;
   if compp('nil',       n) then f := true;
   if compp('in',        n) then f := true;
   if compp('or',        n) then f := true;
   if compp('and',       n) then f := true;
   if compp('xor',       n) then f := true;
   if compp('not',       n) then f := true;
   if compp('if',        n) then f := true;
   if compp('then',      n) then f := true;
   if compp('else',      n) then f := true;
   if compp('case',      n) then f := true;
   if compp('of',        n) then f := true;
   if compp('repeat',    n) then f := true;
   if compp('until',     n) then f := true;
   if compp('while',     n) then f := true;
   if compp('do',        n) then f := true;
   if compp('for',       n) then f := true;
   if compp('to',        n) then f := true;
   if compp('downto',    n) then f := true;
   if compp('begin',     n) then f := true;
   if compp('end',       n) then f := true;
   if compp('with',      n) then f := true;
   if compp('goto',      n) then f := true;
   if compp('const',     n) then f := true;
   if compp('var',       n) then f := true;
   if compp('type',      n) then f := true;
   if compp('array',     n) then f := true;
   if compp('record',    n) then f := true;
   if compp('set',       n) then f := true;
   if compp('file',      n) then f := true;
   if compp('function',  n) then f := true;
   if compp('procedure', n) then f := true;
   if compp('label',     n) then f := true;
   if compp('packed',    n) then f := true;
   if compp('program',   n) then f := true;
   if compp('forward',   n) then f := true;
   if compp('module',    n) then f := true;
   if compp('uses',      n) then f := true;
   if compp('private',   n) then f := true;
   if compp('external',  n) then f := true;
   if compp('view',      n) then f := true;
   if compp('fixed',     n) then f := true;
   if compp('process',   n) then f := true;
   if compp('monitor',   n) then f := true;
   if compp('share',     n) then f := true;
   if compp('class',     n) then f := true;
   if compp('construct', n) then f := true;
   if compp('destruct',  n) then f := true;
   if compp('is',        n) then f := true;
   if compp('atom',      n) then f := true;

   paskey := f { return result }
   
end;

{******************************************************************************

Check eligible pointer parameter

Checks if the pointer to var flag is on, if the passed type is a parameter
that has a pointer base, and that the base of that has a non-generated label.
Also checks of the base of the pointer is NOT a void nor function.

Returns true if all conditions are satisfied.

*******************************************************************************}

function chkptrvar(tp: typptr): boolean;

var f: boolean;

begin

   f := false; { set not eligible }
   if fptrvar and (tp^.t = tpar) then begin 

      { pointer to var flag is on, and is a parameter }
      if tp^.part^.t = tptr then begin

         tp := tp^.part^.ptrt; { link to base type of pointer }
         if (tp^.sym <> nil) and (tp^.t <> tvoid) and (tp^.t <> tfunc) then
            f := true { has symbol, is not void nor function }

      end

   end;

   chkptrvar := f { return result }

end;

{******************************************************************************

Output type

Outputs a complete type. Outputs the type in name = type form. Note that only
one level of typing need be output, because all of the subtypes will be labeled
here.

Note: need to take care of bit specified record fields.

*******************************************************************************}

procedure outtyp(var f: text; tp: typptr);

var tp1:  typptr;  { pointer for types }
    fc:   integer; { field counter }
    fout: boolean; { output flag }
    ph:   boolean; { parameter handled flag }

{ function check simplified structure of common type, pointer or array,
  or common type }

function chkssc(tp: typptr): boolean;

var f: boolean;

begin

   if tp^.sym^.gen then begin { no symbol represents this type }
   
      f := chkcmt(tp); { check is simple common }
      if tp^.t = tptr then begin

         f := chkcmt(tp^.ptrt) { check base is common }

      end else if tp^.t = tarray then 
         f := chkcmt(tp^.arrt); { check base is common }

   end else f := false; { has a symbol }

   chkssc := f { return result }

end;

{ output simplified structure type, meaning it evaluates to a single symbol }

procedure outssc(tp: typptr);

begin

   if tp^.sym^.gen then begin { no symbol represents this type }

      if tp^.t = tptr then begin

         write(f, '^');
         outcmt(f, tp^.ptrt) { output common type }

      end else if tp^.t = tarray then begin

         if tp^.arre = -1 then write(f, '^') { its a pointer }
         else write(f, 'array [0..', tp^.arre:1, '-1] of ');
         outcmt(f, tp^.arrt) { output common types }

      end else outcmt(f, tp)

   end else outcmt(f, tp)

end;

{ output prime symbol }

procedure outprime(tp: typptr);

var sp:  symptr; { symbol list pointer }
    out: boolean; { prime output symbol }

begin

   out := false; { set not output }
   sp := tp^.sym; { index top of list }
   while (sp <> nil) and not out do begin { find prime symbol }

      if not sp^.rem and (sp^.asym = nil) then begin 

         { symbol is active and prime }
         outsym(f, sp); { output symbol }
         out := true { flag output }
         
      end;
      sp := sp^.tlst { link next type list symbol }

   end;
   if not out then error(etypsnf, '') { symbol for type not found }

end;

{ output alias symbols list }

procedure outalias(tp: typptr);

var sp:    symptr; { symbol list pointer }
    keysp: symptr; { key symbol }
    fnd:   boolean; { entry found to output }

begin

   { clear output flags }
   sp := tp^.sym; { index top of list }
   while sp <> nil do begin { traverse }

      sp^.out := false; { clear it }
      sp := sp^.tlst { link next type list symbol }

   end;
   { find the key symbol. this is the symbol without any alias root, meaning
     it directly defines the type }
   keysp := nil; { clear the key symbol }
   sp := tp^.sym; { index top of list }
   while (sp <> nil) and (keysp = nil) do begin { traverse }

      if sp^.asym = nil then keysp := sp; { found key, set }
      sp := sp^.tlst { link next type list symbol }

   end;
   if keysp = nil then error(esys91, '');
   keysp^.out := true; { set that was output elsewhere }
   repeat { output symbols }

      fnd := false; { set no entry output }
      sp := tp^.sym; { index top of list }
      while sp <> nil do begin { output all symbols for type }

         if not sp^.rem and not sp^.out then begin { symbol is active }

            if sp^.asym <> nil then begin { output preferred alias }

               if sp^.asym^.out then begin { it was output }

                  { output alias }
                  outsym(f, sp);
                  write(f, ' = ');
                  outsym(f, sp^.asym);
                  writeln(f, ';');
                  sp^.out := true; { set output }
                  fnd := true { set found }

               end

            end else begin { output common alias }

               { output alias }
               outsym(f, sp);
               write(f, ' = ');
               if sp^.asym <> nil then outsym(f, sp^.asym)
               else outsym(f, keysp);
               writeln(f, ';');
               sp^.out := true; { set output }
               fnd := true { set found }

            end
         
         end;
         sp := sp^.tlst { link next type list symbol }

      end

    until not fnd

end;

begin

   { to stop recursion back to this entry, we set it processed even before we
     do anything. the flag means "I have it handled" }
   fout := tp^.out; { get the flag }
   tp^.out := true; { set processed }
   if not fout then begin { not already output }

      if tp^.t in [tvoid, tint, tfloat, tenum, tptr, tarray, tstruct, tunion,
                   tfunc] then begin { is a type we output }

         if tp^.sym = nil then error(esys21, ''); { should have label }
         if tp^.drv <> nil then begin

            { this type is "derived" from another. the only reason this happens
              is because of the const and volatile flags, both of which we
              preserve, but don't translate. so the derivation ends up being a
              simple alias }
            outtyp(f, tp^.drv); { output base derivation first }
            outprime(tp); { output symbol }
            write(f, ' = ');
            if tp^.drv^.sym = nil then error(esys92, ''); 
            outsym(f, tp^.drv^.sym); { output derived base }
            writeln(f, ';');
            outalias(tp) { output any aliases for this type }
        
         end else case tp^.t of { type }

            tvoid: begin

               outprime(tp); { output symbol }
               write(f, ' = ');
               write(f, 'sc_c_lang_void');
               writeln(f, ';');
               outalias(tp) { output any aliases for this type }

            end;
            tint: begin

               outprime(tp); { output symbol }
               write(f, ' = ');
               if tfchar in tp^.tfs then begin { is character }

                  write(f, 'sc_c_lang_');
                  if tfsigned in tp^.tfs then write(f, 'signed_')
                  else if tfunsigned in tp^.tfs then write(f, 'unsigned_');
                  write(f, 'char')

               end else if tfint in tp^.tfs then begin { is integer }

                  write(f, 'sc_c_lang_');
                  if tfsigned in tp^.tfs then write(f, 'signed_')
                  else if tfunsigned in tp^.tfs then write(f, 'unsigned_');
                  if tfshort in tp^.tfs then write(f, 'short_')
                  else if tflong in tp^.tfs then write(f, 'long_');
                  write(f, 'int')

               end else if tfshort in tp^.tfs then begin

                  write(f, 'sc_c_lang_');
                  if tfsigned in tp^.tfs then write(f, 'signed_')
                  else if tfunsigned in tp^.tfs then write(f, 'unsigned_');
                  write(f, 'short_int')

               end else if tflong in tp^.tfs then begin

                  write(f, 'sc_c_lang_');
                  if tfsigned in tp^.tfs then write(f, 'signed_')
                  else if tfunsigned in tp^.tfs then write(f, 'unsigned_');
                  write(f, 'long_int')

               end else if tfsigned in tp^.tfs then
                  write(f, 'sc_c_lang_signed_int')
               else if tfunsigned in tp^.tfs then
                  write(f, 'sc_c_lang_unsigned_int')
               else error(esys22, ''); { should have been one of those }
               writeln(f, ';');
               outalias(tp) { output any aliases for this type }

            end;
            tfloat: begin

               outprime(tp); { output symbol }
               write(f, ' = ');
               if tflong in tp^.tfs then write(f, 'sc_c_lang_long_double')
               else if tfdouble in tp^.tfs then write(f, 'sc_c_lang_double')
               else write(f, 'sc_c_lang_float');
               writeln(f, ';');
               outalias(tp) { output any aliases for this type }

            end;
            tenum:    begin

               { simply equate to integer, we already output the body }
               outprime(tp); { output symbol }
               writeln(f, ' = sc_c_lang_int;');
               outalias(tp) { output any aliases for this type }

            end;
            tptr:     begin

               if tp^.ptrt^.sym = nil then
                  error(esys25, ''); { base type must have label }
               { if base is generated, we need to explore it, since it could be
                 orphaned otherwise }
               if tp^.ptrt^.sym^.gen and not chkcmt(tp^.ptrt) then 
                  outtyp(f, tp^.ptrt);
               outprime(tp); { output symbol }
               write(f, ' = ');
               write(f, '^');
               if tp^.ptrts <> nil then outsym(f, tp^.ptrts) { output preferred }
               else outcmt(f, tp^.ptrt); { output common types }
               writeln(f, ';');
               outalias(tp) { output any aliases for this type }

            end;
            tarray: begin

               if not chkcmt(tp^.arrt) then 
                  outtyp(f, tp^.arrt); { output base type first }
               outprime(tp); { output symbol }
               write(f, ' = ');
               if tp^.arre = -1 then write(f, '^') { its a pointer }
               else write(f, 'array [0..', tp^.arre:1, '-1] of ');
               if tp^.arrt = nil then error(esys26, ''); { undefined base }
               if tp^.arrt^.sym = nil then error(esys27, ''); { must have label }
               if tp^.arrts <> nil then outsym(f, tp^.arrts) { output preferred }
               else outcmt(f, tp^.arrt); { output common types }
               writeln(f, ';');
               outalias(tp) { output any aliases for this type }

            end;  
            tstruct: begin

               { output all base types first }
               tp1 := tp^.strf; { index field list }
               while tp1 <> nil do begin { output field entries }

                  if tp1^.t <> tfield then error(esys28, ''); { should be field }
                  if not chkssc(tp1^.fldt) then 
                     outtyp(f, tp1^.fldt); { output }
                  tp1 := tp1^.fldn { next }

               end;
               outprime(tp); { output symbol }
               write(f, ' = ');
               writeln(f, 'record');
               tp1 := tp^.strf; { index field list }
               while tp1 <> nil do begin { output field entries }

                  if tp1^.t <> tfield then error(esys29, ''); { should be field }
                  if tp1^.sym = nil then error(esys30, ''); { should have label }
                  if tp1^.fldt^.sym = nil then
                     error(esys31, ''); { base should have label }
                  write(f, '   ');
                  { if the record field is a Pascal key, output with "rf_"
                    coining }
                  if paskey(tp1^.sym^.lab^) then write(f, 'rf_');
                  write(f, tp1^.sym^.lab^);
                  write(f, ': '); 
                  if tp1^.fldts <> nil then outsym(f, tp1^.fldts) { output preferred }
                  else outssc(tp1^.fldt); { output common types }
                  writeln(f, ';');
                  tp1 := tp1^.fldn { next }

               end;
               writeln(f, 'end;');
               outalias(tp) { output any aliases for this type }

            end;
            tunion:  begin

               { must manufacture tagfield type, count fields }
               tp1 := tp^.unif; { index field list }
               fc := 0; { start field counter }
               while tp1 <> nil do begin { output field entries }

                  if tp1^.t <> tfield then error(esys72, ''); { should be field }
                  tp1 := tp1^.fldn; { next }
                  fc := fc+1 { count }

               end;
               coinsym(tp^.unit); { coin a type }
               outsym(f, tp^.unit); { output symbol }
               writeln(f, ' = 0..', fc:1, '-1;'); { output }
               { output all base types first }
               tp1 := tp^.unif; { index field list }
               while tp1 <> nil do begin { output field entries }

                  if tp1^.t <> tfield then error(esys33, ''); { should be field }
                  if not chkssc(tp1^.fldt) then 
                     outtyp(f, tp1^.fldt); { output }
                  tp1 := tp1^.fldn { next }

               end;
               if tp^.unit = nil then error(esys69, ''); { should have tag defined }
               outprime(tp); { output symbol }
               write(f, ' = ');
               write(f, 'record case ');
               outsym(f, tp^.unit); 
               writeln(f, ' of');
               tp1 := tp^.unif; { index field list }
               fc := 0; { start field counter }
               while tp1 <> nil do begin { output field entries }

                  if tp1^.t <> tfield then error(esys34, ''); { should be field }
                  if tp1^.sym = nil then error(esys35, ''); { should have label }
                  if tp1^.fldt^.sym = nil then
                     error(esys36, ''); { base should have label }
                  write(f, '   ', fc:1, ': ('); 
                  { if the record field is a Pascal key, output with "rf_"
                    coining }
                  if paskey(tp1^.sym^.lab^) then write(f, 'rf_');
                  write(f, tp1^.sym^.lab^);
                  write(f, ':');
                  if tp1^.fldts <> nil then outsym(f, tp1^.fldts) { output preferred }
                  else outssc(tp1^.fldt); { output common types }
                  writeln(f, ');');
                  tp1 := tp1^.fldn; { next }
                  fc := fc+1 { count }

               end;
               writeln(f, 'end;');
               outalias(tp) { output any aliases for this type }

            end; 
            tfunc: begin

               if tfextern in tp^.tfs then begin { external function }

                  tp1 := tp^.fncp; { index parameters }
                  while tp1 <> nil do begin { traverse parameter list }
         
                     if tp1^.t <> tpar then error(esys48, ''); { must be param }
                     { must have type }
                     if tp1^.part = nil then error(esys50, '');
                     { type must have label }
                     if tp1^.part^.sym = nil then error(esys51, '');
                     ph := false; { set parameter not handled }
                     if tp1^.parps <> nil then ph := true
                     { check constant character pointer case }
                     else if chkccp(tp1^.part) and fccpstr then ph := true
                     { check character pointer with length case }
                     else if chkchp(tp1^.part) and fchpstr then begin 

                        if tp1^.parn <> nil then
                           if chkint(tp1^.parn^.part) then begin

                           ph := true; { set handled }
                           tp1 := tp1^.parn { eat the length parameter }

                        end

                     end;
                     { if not otherwise handled }
                     if not ph then begin

                        { see if qualifies for pointer to var compression }
                        if chkptrvar(tp1) then 
                           { handle pointer to var convert }
                           outtyp(f, tp1^.part^.ptrt) { output parameter type }
                        else if not chkcmt(tp1^.part) then outtyp(f, tp1^.part)

                     end;
                     tp1 := tp1^.parn { link next }

                  end;
                  { must have result }
                  if tp^.fncr = nil then error(esys52, '');
                  { that must have symbol }
                  if tp^.fncr^.sym = nil then error(esys53, '');
                  if not chkcmt(tp^.fncr) then { not a common type }
                     outtyp(f, tp^.fncr) { output result type }

               end else begin { function as type }

                  outprime(tp); { output symbol }
                  write(f, ' = ');
                  writeln(f, 'sc_c_lang_function;');
                  outalias(tp) { output any aliases for this type }

               end

            end

         end

      end

   end

end;

{******************************************************************************

Output types

Outputs all types except for function instances to the output header file.
To prevent out of order declarations, we use a graph tour technique. Each type
entry is examined in turn, listwise, then all of the named bases of that type
are recursively processed. The "out" flag on each type keeps types from being
output redundantly. Then, the anonymous sections of the original type are
output.

The symbols must be in the alpha list.

*******************************************************************************}

procedure outtypes(var f: text);

var sp: symptr; { pointer for symbol table } 

begin

   clrout; { clear process flags }
   writeln(f, 'type');
   writeln(f);
   sp := typstk^.als; { index the top of the alpha list }
   { perform prime entry pass }
   while sp <> nil do begin { traverse that }

      if sp^.typ = nil then error(esys65, ''); { must have type }
      { must be backlinked to symbol }
      if sp^.typ^.sym = nil then error(esys66, '');
      { if symbol is not removed, output it }
      if not sp^.rem then outtyp(f, sp^.typ);
      sp := sp^.next { next in list }

   end

end;

{******************************************************************************

Output function

Outputs a single function
Outputs external functions. These are functions that have been declared in
the "func;" form, and not functions that appeared in whole later, or were
typedefs.

*******************************************************************************}

procedure outfunc(var f:    text;     { output file }
                      tp:   typptr;   { function type entry }
                      elide: boolean; { process elide pass }
                      ecnt: integer); { elide count }

var tp1:  typptr;  { pointers for types list }
    ph:   boolean; { parameter handled flag }
    pcnt: integer; { output parameter count }
    pow:  integer; { elide sweep power }

{ output parameter symbol with prefixing and coining }

procedure outpsym(sp: symptr);

begin

   if paskey(sp^.lab^) then { conflicts with keyword }
      outstr(f, 'p_'); { output prefix }
   outstr(f, sp^.lab^); { output label }
   if sp^.inst > 1 then write(f, '_', sp^.inst:1)

end;

{ output result symbol with prefixing and coining }

procedure outrsym(sp: symptr);

begin

   outstr(f, 'sc_r_'); { output prefix }
   outstr(f, sp^.lab^); { output label }
   if sp^.inst > 1 then write(f, '_', sp^.inst:1)

end;

begin

   { output }
   if tp^.sym = nil then error(esys47, ''); { check no symbol }
   if tp^.fncr = nil then error(esys54, ''); { check result }
   { if this is an overload, output that }
   if elide then outstr(f, 'overload ');
   if tp^.fncr^.t = tvoid then outstr(f, 'procedure ')
   else outstr(f, 'function ');
   outsym(f, tp^.sym);  { output label }
   pcnt := 0; { clear parameter output count }
   pow := 1; { set 1st elide power position }
   if tp^.fncp <> nil then begin { output parameters }

      tp1 := tp^.fncp; { index 1st parameter }
      while tp1 <> nil do begin { traverse parameter list }
   
         if tp1^.t <> tpar then error(esys48, ''); { must be param }
         if tp1^.sym = nil then error(esys49, ''); { must be labeled }
         if tp1^.part = nil then error(esys56, ''); { must have type }
         { type must have label }
         if tp1^.part^.sym = nil then error(esys55, '');
         ph := false; { set parameter not processed }
         { check will elide this parameter }
         if elide and tp1^.pareld then begin

            if pow and ecnt = 0 then ph := true; { set processed }
            pow := pow*2; { move to next power }

         end else if tp1^.parps <> nil then begin { custom string }

            if max(tp1^.parps^) > 0 then begin { not null }

               if pcnt = 0 then outstr(f, '(') else outstr(f, '; ');
               brklin(f); { conditional break }
               outstr(f, tp1^.parps^); { output custom string }
               pcnt := pcnt+1 { next }

            end;
            ph := true { set processed }
           
         end else if chkccp(tp1^.part) and fccpstr then begin

            if pcnt = 0 then outstr(f, '(') else outstr(f, '; ');
            brklin(f); { conditional break }
            { convert constant character pointer to string }
            outstr(f, 'view ');
            outpsym(tp1^.sym); 
            outstr(f, ': string');
            pcnt := pcnt+1; { next }
            ph := true { set processed }
       
         end else if chkchp(tp1^.part) and fchpstr then begin 

            { character pointer }
            if tp1^.parn <> nil then { there is a next }
               if chkint(tp1^.parn^.part) then begin 

               if pcnt = 0 then outstr(f, '(') else outstr(f, '; ');
               brklin(f); { conditional break }
               { convert to string }
               outstr(f, 'var ');
               outpsym(tp1^.sym);
               outstr(f, ': string');
               tp1 := tp1^.parn; { eat the length parameter }
               pcnt := pcnt+1; { next }
               ph := true { set processed }

            end

         end;
         if not ph and chkptrvar(tp1) then 
            begin { handle pointer to var convert }

            if pcnt = 0 then outstr(f, '(') else outstr(f, '; ');
            brklin(f); { conditional break }
            { must have symbol }
            if tp1^.part^.ptrt^.sym = nil then error(esys81, '');
            outstr(f, 'var ');
            outpsym(tp1^.sym); 
            outstr(f, ': '); 
            if tp1^.partps <> nil then outstr(f, tp1^.partps^)
            else outcmt(f, tp1^.part^.ptrt);
            pcnt := pcnt+1; { next }
            ph := true { set processed }

         end;
         if not ph then begin { perform processing for all else }

            if pcnt = 0 then outstr(f, '(') else outstr(f, '; ');
            brklin(f); { conditional break }
            if tfconst in tp1^.part^.tfs then outstr(f, 'view ');
            outpsym(tp1^.sym); 
            outstr(f, ': '); 
            if tp1^.partps <> nil then outstr(f, tp1^.partps^)
            else if tp1^.parts <> nil then outsym(f, tp1^.parts)
            else outcmt(f, tp1^.part);
            pcnt := pcnt+1 { next }

         end;
         tp1 := tp1^.parn { link next }

      end;
      if pcnt > 0 then outstr(f, ')'); { terminate parameter list }

   end;
   if tp^.fncr^.t <> tvoid then begin { output result type }

      brklin(f); { conditional break }
      { result must have symbol }
      if tp^.fncr^.sym = nil then error(esys57, '');
      write(f, ': ');
      { check function type is replaced }
      if tp^.fncrps <> nil then outstr(f, tp^.fncrps^)
      else if (tp^.fncr^.t = tstruct) or 
         (tp^.fncr^.t = tunion) then outrsym(tp^.fncr^.sym)
      else if tp^.fncrs <> nil then outsym(f, tp^.fncrs)
      else outcmt(f, tp^.fncr)

   end;
   outstr(f, '; ');
   brklin(f); { conditional break }
   outstr(f, 'begin end;'); { terminate function/procedure }
   trmlin(f); { terminate }

end;

{******************************************************************************

Output functions

Outputs external functions. These are functions that have been declared in
the "func;" form, and not functions that appeared in whole later, or were
typedefs.

*******************************************************************************}

procedure outfuncs(var f: text);

var tp:   typptr;  { pointers for types list }
    mp:   modptr;  { module name entry pointer }
    fcnt: integer; { found output count }
    sp:   symptr;  { symbols pointer }
    ecnt: integer; { elide count }
    pow2: integer; { power of 2 }
    i:    integer; { index }

begin

   lincnt := 1; { clear line position }
   fcnt := 0; { clear function output counter }
   clrout; { clear process flags }
   sp := typstk^.als; { index the top of the alpha list }
   while sp <> nil do begin { traverse that }

      tp := sp^.typ; { index type }
      if (tp^.t = tfunc) and (tfextern in tp^.tfs) and not tp^.rem then begin

         { find the module export }
         if tp^.fncrno <> nil then mp := fndmod(tp^.fncrno^.lab^)
         else mp := fndmod(tp^.sym^.lab^);
         { if there is no associated export, we just skip this entry. it will
           show up in the report }
         if mp <> nil then { there is an export }
             if not mp^.dup then begin { and not a duplicate }

            if fcnt = 0 then begin { preamble }

               writeln(f);
               writeln(f, ' { Function definitions }');
               writeln(f)

            end;
            outfunc(f, tp, false, 0); { output function without elide }
            ecnt := eldcnt(tp); { find number of elides }
            if ecnt > 0 then begin

               pow2 := 1; { find ecnt**2 }
               while ecnt > 0 do begin pow2 := pow2*2; ecnt := ecnt-1 end

            end else pow2 := 0; { clear power }
            { iterate through all the elide combinations }
            for i := 0 to pow2-2 do outfunc(f, tp, true, i);
            fcnt := fcnt+1 { count functions }

         end
      
      end;
      sp := sp^.next { next entry }

   end;
   if fcnt > 0 then begin { epilog }

      writeln(f);
      writeln(f, '{ ', fcnt:1, ' function definitions output }');
      writeln(f)

   end

end;

{******************************************************************************

Output function macro

Outputs the macro equivalence for a function.

*******************************************************************************}

procedure outasm(var f:     text;     { output file }
                     mp:    modptr;   { module pointer }
                     tp:    typptr;   { function type pointer }
                     elide: boolean;  { process elide pass }
                     ecnt:  integer); { elide count }

var p, n, e: packed array [1..100] of char; { path components }
    tp1:     typptr;  { pointers for types list }
    pnull:   boolean; { parameter was null flag }
    pow:     integer; { elide sweep power }
    ph:      boolean; { parameter handled flag }

procedure ce;

begin

   if lincnt > 70 then begin { wrap }

      writeln(f, '\\');
      write(f, '   ');
      lincnt := 0

   end

end;

begin

   if tp^.sym = nil then error(esys60, ''); { check no symbol }
   if tp^.fncr = nil then error(esys61, ''); { check result }
   outstr(f, 'ptocf ');
   outstr(f, tp^.sym^.lab^);
   outstr(f, ', ');
   ce;
   { output module name }
{ *** Now need to coin name with types for overloads }
   brknam(mp^.mname^, p, n, e);
   write(f, n:0);
   lincnt := lincnt+len(n);
   outstr(f, '_');
   mp^.ref := true; { set was referenced }
   { if a reference override exists, use that }
   if tp^.fncrno <> nil then outstr(f, tp^.fncrno^.lab^)
   else outstr(f, tp^.sym^.lab^); { just use the name }
   outstr(f, ', ');
   { check and output custom result type }
   if tp^.fncras <> nil then outstr(f, tp^.fncras^)
   else if tp^.fncr^.t = tvoid then outstr(f, 'void')
   else if tp^.fncr^.t = tptr then outstr(f, 'ptr')
   else outstr(f, 'int');
   pow := 1; { set 1st elide power position }
   if tp^.fncp <> nil then begin { output parameters }

      outstr(f, ', ');
      ce;
      tp1 := tp^.fncp; { index 1st parameter }
      while tp1 <> nil do begin { traverse parameter list }
   
         if tp1^.t <> tpar then error(esys62, ''); { must be param }
         if tp1^.part = nil then 
            error(esys63, ''); { must have type }
         pnull := false; { set parameter not null }
         ph := false; { set parameter not processed }
         { check will elide this parameter }
         if elide and tp1^.pareld then begin

            if pow and ecnt = 0 then begin

               outstr(f, tp1^.pareas^); { output zero default }
               ph := true { set processed }

            end;
            pow := pow*2; { move to next power }

         end;
         if not ph then begin { not elided }

            { output parameter type }
            if tp1^.paras <> nil then begin { custom string }

               outstr(f, tp1^.paras^); { output custom string }
               pnull := max(tp1^.paras^) = 0 { check null status }

            end else if tp1^.partas <> nil then begin { custom type }

               outstr(f, tp1^.partas^); { output custom string }
               pnull := max(tp1^.partas^) = 0 { check null status }

            end else if chkccp(tp1^.part) and fccpstr then 
               outstr(f, 'pstrz')
            else if chkchp(tp1^.part) and fchpstr then begin 

               { character pointer }
               if tp1^.parn <> nil then begin { there is a next }

                  if chkint(tp1^.parn^.part) then begin

                     outstr(f, 'zstrp');
                     tp1 := tp1^.parn { eat the length parameter }

                  end else outstr(f, 'ptr')

               end else outstr(f, 'ptr')

            end else if tp1^.part^.t = tptr then outstr(f, 'ptr')
            else outstr(f, 'int')

         end;
         tp1 := tp1^.parn; { link next }
         if (tp1 <> nil) and not pnull then begin

            { theres more parameters, and the last was not a null 
              parameter }
            outstr(f, ', '); { theres more }
            ce { conditional break }

         end

      end

   end;
   trmlin(f) { terminate }

end;

{******************************************************************************

Output function macros

Outputs the macro equivalence for each function.

*******************************************************************************}

procedure outasms(var f: text);

var tp:   typptr;  { pointers for types list }
    mp:   modptr;  { module name entry pointer }
    ecnt: integer; { elide count }
    pow2: integer; { power of 2 }
    i:    integer; { index }
    fcnt: integer; { found output count }

begin

   writeln(f);
   writeln(f, '! Function definitions');
   writeln(f);
   lincnt := 1; { clear line length }
   clrout; { clear process flags }
   tp := typstk^.typ; { index top of type list }
   while tp <> nil do begin { traverse list }

      if (tp^.t = tfunc) and (tfextern in tp^.tfs) and not tp^.rma and 
         not tp^.rem then begin

         { find the module export }
         if tp^.fncrno <> nil then mp := fndmod(tp^.fncrno^.lab^)
         else mp := fndmod(tp^.sym^.lab^);
         { if there is no associated export, we just skip this entry. it will
           show up in the report }
         if mp <> nil then begin { there is an export }

            mp^.ref := true; { set was referenced }
            if not mp^.dup then begin { not a duplicate }

               outasm(f, mp, tp, false, 0); { output function without elide }
               ecnt := eldcnt(tp); { find number of elides }
               if ecnt > 0 then begin
               
                  pow2 := 1; { find ecnt**2 }
                  while ecnt > 0 do begin pow2 := pow2*2; ecnt := ecnt-1 end
               
               end else pow2 := 0; { clear power }
               { iterate through all the elide combinations }
               for i := 0 to pow2-2 do outasm(f, mp, tp, true, i);
               fcnt := fcnt+1 { count functions }

            end

         end
      
      end;
      tp := tp^.next { next entry }

   end;
   writeln(f)

end;

begin

   typstk := nil; { clear types list }
   tpsfre := nil; { clear free types list stack }
   for si := 1 to symmax do symtbl[si] := nil; { clear symbols table }
   symfre := nil; { clear free symbols list }
   for ti := tudf to tpar do typfre[ti] := nil; { clear free type entry table }
   for mi := 1 to modmax do modtbl[mi] := nil; { clear module name table }
   level := 0; { clear scope nest count }
   fsym := false; { set no list symbols }
   ftype := false; { no print types table }
   fptrvar := false; { no change anonymous pointers to var }
   fccpstr := false; { no change constant strings to string }
   fchpstr := false; { no change character pointer to string }
   level := 0; { clear scope nest count }
   typnum := 1; { coined type number }
   lincnt := 1; { clear line counter }

end.

