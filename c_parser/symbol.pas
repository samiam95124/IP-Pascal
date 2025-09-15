{*******************************************************************************
*                                                                              *
*                                 SYMBOLS                                      *
*                                                                              *
* Provides a symbol table, management for that, and a type structure system    *
* with management for that.
*                                                                              *
*******************************************************************************}

module symbol(output);

uses stddef,  { standard defines }
     strlib,  { strings }
     macro,   { macro functions }
     scanner; { scanner }

const

symmax = 1000; { symbol chain head maximum }
lsmmax  = 10;  { maximum number of characters in label to output in
                 symbols listing (should not be greater than labmax) }
prtmax  = 80;  { maximum number of characters in an output line }

type 

syminx = 1..symmax; { index for symbol head table }
typptr = ^typ; { type pointer }
symptr = ^sym; { symbol pointer }
sym    = record { symbol entry }
  
   next: symptr;  { next list entry }
   lvl:  integer; { block level }
   typ:  typptr;  { pointer to symbol type }
   lab:  pstring; { symbol label }
   str:  boolean  { is a structure }

end;
{ storage class specifier }
strclass = (scnone, scauto, scregister, scstatic, scextern, sctypedef);
{ type qualifier }
typqual = (tqconst, tqvolatile);
{ integer specifiers }
intspec = (ischar, isshort, isint, islong, issigned, isunsigned);
{ type codes 
  In our system, types are a loose word standing for anything that is 
  predeclared and therefore requires a data structure to represent
  it. Type entries may be indexed by symbols, or may be "anonymous" }
types  = (tudf,     { undefined entry, for use with undef pointers }
          tvoid,    { universal pointer }
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
          tpar,     { parameter }
          tinteger, { integer }
          tfloat,   { floating point }
          tdouble,  { double floating point }
          tddf,     { delayed definition }
          tglbl);   { global block }
typ = record { type entry }
         
   next: typptr; { next list entry }
   sc:   strclass; { storage class }
   tq:   set of typqual; { type qualifier }
   size: integer; { size of type, in bytes }
   case t: types of { types }

      tudf:     ();              { dummy entry for undefined pointers }
      tvoid:    ();              { universal type }
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
      tptr:     (ptrt: typptr);  { base type }
      tarray:   (arrt: typptr;   { base type }
                 arre: integer); { number of array elements }
      tstruct:  (strf: typptr;   { field list }
                 strl: symptr);  { list of field labels }
      tunion:   (unif: typptr;   { field list }
                 unil: symptr);  { list of field labels }
      tfield:   (fldn: typptr;   { next field pointer }
                 fldh: typptr;   { head entry pointer }
                 fldb: integer;  { number of bits to fit into }
                 fldt: typptr);  { base type }
      tvar:     (vart: typptr;   { base type }
                 varc: typptr);  { constant fill }
      tfunc:    (fncp: typptr;   { parameter list }
                 fncr: typptr;   { function result }
                 fncl: symptr;   { list of parameter labels }
                 fncv: boolean); { function has variable arguments }
      tfunci:   (fnit: typptr);  { function instantiation }
      tpar:     (parn: typptr;   { next parameter }
                 part: typptr;   { base type }
                 parh: typptr);  { head entry pointer }
      tinteger: (ints: set of intspec); { integer }
      tfloat:   ();              { float }
      tdouble:  (dbll: boolean); { long double }
      tddf:     (ddfs: symptr;   { undefined symbol }
                 ddft: typptr;   { base type }
                 ddfd: boolean); { type has been defined }
      tglbl:    ()               { module type }

   { end }

end;
typset = set of types; { set of types }
tpsptr = ^tps; { pointer to type stack entry }
tps = record { type stack entry }

   next: tpsptr; { next entry }
   typ:  typptr; { type list for block }
   lst:  typptr  { last entry in type list }

end;

var

level:  integer; { scope nesting level }
fsym:   boolean; { symbols print flag (diagnostic) }
ftype:  boolean; { output types table (diagnostic) }

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

private

var

symtbl: array [syminx] of symptr; { symbol chain table }
symfre: symptr; { free symbol entry list }
si:     syminx; { symbol table index }
typstk: tpsptr; { type list stack }
tpsfre: tpsptr; { type list entry free stack }
typfre: array[types] of typptr; { free type entries arrayed by type }
ti:     types;  { index for types entry table }

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
   sp^.typ := nil; { clear type pointer }
   sp^.str := false; { set not a structure id }
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

      if compcp(nxtlab, p^.lab^) and (p^.str = sf) then begin { entry found }

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
   new(sp^.lab, lenp(nxtlab)); { get a label string }
   copyp(sp^.lab^, nxtlab) { place the label }

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

   if sp = nil then error(esys); { should not be nil }
   sp1 := lclsym(sp^.lab^, sf); { find previous symbol }
   if sp1 <> nil then error(edupsym); { symbol is duplicate }
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
   if sp <> nil then error(edupsym); { symbol is duplicate }
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
      else if gtrp(dp^.lab^, tp^.lab^) then { new < dest }
         begin tp^.next := dp; dp := tp end { insert at top }
      else begin { in list middle somewhere }

         p := dp; { index top of list }
         while p <> nil do begin

            l := p; { set pointer to last }
            p := p^.next; { index next }
            if p <> nil then { there is a next entry } 
               if gtrp(p^.lab^, tp^.lab^) then
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

List current scope symbols and purge

This diagnostic lists all the symbols for the current scope. Typically used to
produce a listing of procedure/function/program/module symbols at the start
or end of the block.
The symbols are purged.

******************************************************************************}

procedure listsym;

var p, d: symptr;  { pointers for symbols }
    li:   integer;  { index for labels }
    cl:   integer; { number of collumns output }

begin

   if fsym then begin { list symbols }

      formlist(p); { create symbols list from scope }
      alpsym(p); { alphabetize the list }
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
         tinteger: new(tp, tinteger);
         tfloat:   new(tp, tfloat);
         tdouble:  new(tp, tdouble);
         tddf:     new(tp, tddf);
         tglbl:    new(tp, tglbl)

      end;
      tp^.t := t { set type of entry }

   end;
   tp^.next := nil { set no next }

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

var m: boolean; { match flag }

begin

   m := true; { set matches by default }
   if (tp1 = nil) <> (tp2 = nil) then m := false;
   if (tp1 <> nil) and (tp2 <> nil) then begin

      if (tp1^.t <> tp2^.t) or 
         ((tp1^.sc <> tp2^.sc) and 
          (tp1^.sc <> sctypedef) and (tp2^.sc <> sctypedef)) or 
         (tp1^.tq <> tp2^.tq) then
         m := false; { no type match }
      if m then case tp1^.t of { match individual fields }

         tudf:     ; 
         tvoid:    ; 
         tlab:     ; 
         ticst:    if tp1^.ival <> tp2^.ival then m := false;
         tscst:    if not compc(tp1^.sval^, tp2^.sval^) then m := false;
         tccst:    if tp1^.cval <> tp2^.cval then m := false; 
         tfcst:    if tp1^.fval <> tp2^.fval then m := false;
         tarrcst:  if not comptype(tp1^.arcn, tp2^.arcn) then m := false;
         tarrcel:  begin

            if not comptype(tp1^.aren, tp2^.aren) then m := false;
            if not comptype(tp1^.arec, tp2^.arec) then m := false

         end;
         treccst:  if not comptype(tp1^.recn, tp2^.recn) then m := false;
         treccel:  begin

            if not comptype(tp1^.reen, tp2^.reen) then m := false;
            if not comptype(tp1^.reec, tp2^.reec) then m := false

         end;
         tenum:    if not comptype(tp1^.enc, tp2^.enc) then m := false;    
         tenme:    begin

            if not comptype(tp1^.enx, tp2^.enx) then m := false;
            if not comptype(tp1^.enh, tp2^.enh) then m := false;
            if tp1^.env <> tp2^.env then m := false

         end;
         tptr:     if not comptype(tp1^.ptrt, tp2^.ptrt) then m := false;    
         tarray:   begin

            if not comptype(tp1^.arrt, tp2^.arrt) then m := false;
            if tp1^.arre <> tp2^.arre then m := false

         end;
         tstruct:  if not comptype(tp1^.strf, tp2^.strf) then m := false; 
         tunion:   if not comptype(tp1^.unif, tp2^.unif) then m := false; 
         tfield:   begin

            if not comptype(tp1^.fldn, tp2^.fldn) then m := false;
            if tp1^.fldb <> tp2^.fldb then m := false;
            if not comptype(tp1^.fldt, tp2^.fldt) then m := false

         end;
         tvar:     begin

            if not comptype(tp1^.vart, tp2^.vart) then m := false;
            if not comptype(tp1^.varc, tp2^.varc) then m := false;

         end;
         tfunc:    begin

            if not comptype(tp1^.fncp, tp2^.fncp) then m := false;
            if not comptype(tp1^.fncr, tp2^.fncr) then m := false;
            if tp1^.fncv <> tp2^.fncv then m := false
      
         end;
         tfunci:   if not comptype(tp1^.fnit, tp2^.fnit) then m := false;
         tpar:     begin

            if not comptype(tp1^.parn, tp2^.parn) then m := false;
            if not comptype(tp1^.part, tp2^.part) then m := false;

         end;
         tinteger: if tp1^.ints <> tp2^.ints then m := false;
         tfloat:   ;
         tdouble:  if tp1^.dbll <> tp2^.dbll then m := false;
         tddf:     if tp1^.ddft <> tp2^.ddft then m := false;
         tglbl:    ;

      end

   end;

   comptype := m { return match status }

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
            writesp(output, p^.lab^); { print label }
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

         writesp(output, sp^.lab^); { print label }
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
      write('class: ');
      case tp^.sc of { storage class }

         scnone:     write('none');
         scauto:     write('auto');
         scregister: write('register');
         scstatic:   write('static');
         scextern:   write('extern');
         sctypedef:  write('typedef')

      end;
      write(' ');
      if tqconst in tp^.tq then write('qualifier: const ');
      if tqvolatile in tp^.tq then write('qualifier: volatile ');
      write('size: ', tp^.size:1, ' ');
      case tp^.t of { type }
      
         tudf: writeln('undefined');           
         tvoid: writeln('void'); 
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
         tinteger: begin

            write('integer');
            if ischar in tp^.ints then write(' char');
            if isshort in tp^.ints then write(' short');
            if isint in tp^.ints then write(' int');
            if islong in tp^.ints then write(' long');
            if issigned in tp^.ints then write(' signed');
            if isunsigned in tp^.ints then write(' unsigned');
            writeln

         end; 
         tfloat: writeln('float'); 
         tdouble: begin 

            if tp^.dbll then write('long ');
            writeln('double float')

         end;
         tddf: begin

            write('delayed definition: ');
            listety(tp^.ddft, true);
            writeln(' defined: ', tp^.ddfd)

         end;
         tglbl: writeln('global block')
      
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
         writeln;
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

   if typstk = nil then error(esys); { stack empty }   
   ts := typstk; { index top entry }
   typstk := typstk^.next; { remove top entry }
   ts^.next := tpsfre; { link into free list }
   tpsfre := ts;
   level := level-1; { back out label level }
   if level < 0 then error(esys) { underflow }

end;

begin

   typstk := nil; { clear types list }
   tpsfre := nil; { clear free types list stack }
   for si := 1 to symmax do symtbl[si] := nil; { clear symbols table }
   symfre := nil; { clear free symbols list }
   for ti := tudf to tglbl do typfre[ti] := nil; { clear free type entry table }
   level := 0; { clear scope nest count }
   fsym := false; { set no list symbols }
   ftype := false; { no print types table }
   level := 0; { clear scope nest count }

end.

