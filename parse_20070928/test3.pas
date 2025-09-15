module symbol(output);

uses parsedef,
     common,
     parserot,
     scanner;

function gblsym: symptr; forward;
function mgblsym: symptr; forward;
function lclsym: symptr; forward;
procedure plcsym(var sp: symptr); forward;
procedure plcsyms(sl: symptr); forward;
procedure purge; forward;
procedure listsym(sp: symptr); forward;
procedure numlab; forward;
procedure define(var sp: symptr); forward;
procedure find(var sp: symptr); forward;
procedure chkref; forward;
procedure purget; forward;
procedure lsttyp(var tp: typptr; t:  types); forward;
procedure listtyp; forward;
procedure chkschr(var tp: typptr); forward;
function consti(tp: typptr): integer; forward;
function typcmp(tp1, tp2: typptr): boolean; forward;
function typcmpa(dtp, stp: typptr): boolean; forward;
procedure pshtyp(sp: symptr); forward;
procedure poptyp; forward;
procedure getsym(var sp: symptr); forward;
procedure putsym(sp: symptr); forward;
function lbound(tp: typptr): integer; forward;
function ubound(tp: typptr): integer; forward;
procedure typcon(var tp: typptr; ts: typset); forward;
function filect(tp: typptr): boolean; forward;
procedure chktyp; forward;
function boolt(tp: typptr): boolean; forward;
function baset(tp: typptr): typptr; forward;
function chart(tp: typptr): boolean; forward;
function intt(tp: typptr): boolean; forward;
function realt(tp: typptr): boolean; forward;
function strt(tp: typptr): boolean; forward;
function filet(tp: typptr): boolean; forward;
function sett(tp: typptr): boolean; forward;
function actt(tp: typptr): typptr; forward;
procedure formlist(var sp: symptr); forward;
procedure addtyp(tl: typptr); forward;
procedure chktkmp(c: tolkset); forward;
procedure wrttyp; forward;
procedure wrtlnk(tp: typptr); forward;
procedure wrtsyms; forward;
procedure chkddf; forward;
procedure chkcon(pla, plb: typptr); forward;
procedure chgtyp(s, d: typptr); forward;
procedure threaten(sp: symptr; tp: typptr); forward;
procedure chkcst(tp: typptr); forward;
procedure ptrcmp(tp: typptr); forward;
procedure chkdhf; forward;
procedure getcsv(var cp: csvptr); forward;
procedure putcsv(cp: csvptr); forward;
procedure putcsvs(cl: csvptr); forward;
procedure listtype(tp: typptr); forward;
function chkovld(tp: typptr): boolean; forward;
procedure valovl(pp: typptr); forward;
function fndcon(pla, plb: typptr): boolean; forward;
procedure fndovlcon(pp: typptr; var fp: typptr); forward;
procedure listlab(tp: typptr); forward;

private

{******************************************************************************

Get a case value entry

Gets a new case value entry, either from the free list, or from new store.

******************************************************************************}

procedure getcsv(var cp: csvptr);

begin

   if (casfre <> nil) and frecir then begin { return existing symbol entry }
   
      cp := casfre; { index top entry }
      casfre := casfre^.next; { gap the list }
      casfct := casfct - 1 { remove free symbol }

   end else begin 

      new(cp); { get an entirely new entry }
      cascct := cascct + 1 { and count it }

   end;
   cp^.next := nil; { clear next }
   cp^.val := 0; { clear value }
   cp^.def := false; { clear defined }
   casact := casact+1 { count active case entries }

end;

{******************************************************************************

Put case value entry

Places a case value entry to the free list.

******************************************************************************}

procedure putcsv(cp: csvptr);

begin

   cp^.next := casfre; { link to head }
   casfre := cp; { and place new head }
   casfct := casfct + 1; { count free casbols }
   casact := casact - 1 { and remove an active casbol }

end;

{******************************************************************************

Put case value entry list

Frees a list of case values.

******************************************************************************}

procedure putcsvs(cl: csvptr);

var cp: csvptr; { case value pointer }

begin

   while cl <> nil do begin { empty case values list }

      cp := cl; { index top entry }
      cl := cl^.next; { gap out top entry }
      putcsv(cp) { free that }

   end

end;

{******************************************************************************

Get new symbol entry

Consults the free list, and if a free entry is available, returns that. 
Otherwise returns a brand new entry.
Clears relevant fields.

******************************************************************************}

procedure getsym(var sp: symptr);

begin

   if (symfre <> nil) and frecir then begin { return existing symbol entry }
   
      sp := symfre; { index top entry }
      symfre := symfre^.next; { gap the list }
      symfct := symfct - 1 { remove free symbol }

   end else begin 

      new(sp); { get an entirely new entry }
      symcct := symcct + 1 { and count it }

   end;
   sp^.next := nil; { terminate entry }
   sp^.rnxt := nil; { terminate record field list }
   sp^.lvl := maxint; { set the scope for it (diagnostic) }
   sp^.dup := false; { set not duplicate }
   sp^.mis := false; { set not misspell target }
   sp^.udf := false; { set not undefined }
   sp^.ddf := false; { set not delayed definition }
   sp^.hld := false; { set not in holding }
   sp^.exp := export; { set export status }
   sp^.out := false; { set not output to intermediate }
   sp^.ref := 0; { clear reference counter }
   sp^.typ := nil; { clear type pointer }
   sp^.lab := nil; { clear symbol }
   symact := symact + 1 { count active symbols }

end;

{******************************************************************************

Put symbol entry

Places a used symbol on the free list to await later reuse.

******************************************************************************}

procedure putsym(sp: symptr);

begin

   if sp^.lab <> nil then dispose(sp^.lab); { release label if it exists }
   sp^.next := symfre; { link to head }
   symfre := sp; { and place new head }
   symfct := symfct + 1; { count free symbols }
   symact := symact - 1 { and remove an active symbol }

end;

{******************************************************************************

Find global symbol

Finds a symbol that matches nxtlab regardless of the block it belongs
to. Returns a pointer to the matching symbol entry, or nil if none is found.

******************************************************************************}

function gblsym: symptr;

var p, r: symptr; { pointers for symbol table }

begin
   
   r := nil; { clear result pointer }
   p := symtbl[hash(nxtlab, 0, symmax)]; { index the top entry }
   while p <> nil do begin { traverse chain }

      if compp(nxtlab, p^.lab^) then begin { entry found }

         r := p; { place result pointer }
         p := nil { nix search pointer }

      end else p := p^.next { index next entry }

   end;
   gblsym := r { return result pointer }

end;

{******************************************************************************

Find misspelled global symbol

Finds a symbol that matches nxtlab regardless of the block it belongs
to. Returns a pointer to the matching symbol entry, or nil if none is found.
The match is done using the misspell matcher. The result is that the symbol
found can be a misspelling of the given symbol.

******************************************************************************}

function mgblsym: symptr;

var p, r: symptr; { pointers for symbol table }
    i:    syminx; { index for symbol table }

begin

   r := nil; { clear result pointer }
   for i := 1 to symmax do begin { traverse the symbols head }

      p := symtbl[i]; { index the chain head }
      while p <> nil do begin { traverse chain }

         if match(nxtlab, p^.lab^) then r := p; { entry found }
         p := p^.next { index next entry }

      end

   end;
   mgblsym := r { return result pointer }

end;

{******************************************************************************

Find local symbol

Finds a symbol that matches the given label, but only if it exists with the
same level number. Returns a pointer to the matching symbol entry, or nil if 
none is found.

******************************************************************************}

function lclsym: symptr;

var r: symptr; { pointer for symbol table }

begin

   r := gblsym; { find matching symbol }
   if r <> nil then { yes, we have a match }
      if r^.lvl <> level then r := nil; { but sadly not our level, kill it }
   lclsym := r { return result pointer }

end;   

{******************************************************************************

Place symbol in symbol table

A wonderously (and deliberately) stupid routine, just finds the hash slot for
the given symbol and places it into that chain. Because of search order, it
then takes precidence over other duplicate definitions. If the label must be
unique for the current scope, or concevably the entire program, it should be
checked for duplicates first.

******************************************************************************}

procedure plcsym(var sp: symptr);

var i: syminx; { index for symbol table }

begin

   getsym(sp); { get a new symbol entry }
   sp^.lvl := level; { set the scope for it }
   new(sp^.lab, lenp(nxtlab)); { get a label string }
   copyp(sp^.lab^, nxtlab); { place the label }
   i := hash(nxtlab, 0, symmax); { find the top entry }
   sp^.next := symtbl[i]; { place the next entry link }
   symtbl[i] := sp { plant our symbol }

end;

{******************************************************************************

Place symbols in symbol table

Places a whole list of symbols in the symbol table. The level for the symbols
is changed to match the current. Used to restore a number of labels after a
forward operation.

******************************************************************************}

procedure plcsyms(sl: symptr); { symbols list }

var i:  syminx; { index for symbol table }
    sp: symptr; { pointer for symbol }

begin

   while sl <> nil do begin { place symbols }

      sp := sl; { get top entry }
      sl := sl^.next; { gap from list }
      sp^.lvl := level; { set the scope for it }
      i := hash(sp^.lab^, 0, symmax); { find the top entry }
      sp^.next := symtbl[i]; { place the next entry link }
      symtbl[i] := sp { plant our symbol }

   end

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

Change symbol reference

Walks the symbol table, and changes all references to the first type to the
second type. Used to redefine the object that a symbol points to.

******************************************************************************}

procedure chgtyp(s, d: typptr);

var i: syminx; { index for symbol table }
    p: symptr; { pointer for symbols }

begin

   for i := 1 to symmax do begin { traverse the symbols head }

      p := symtbl[i]; { index the chain head }
      while p <> nil do begin { traverse }
   
         if p^.typ = s then p^.typ := d; { if match found, replace }
         p := p^.next { index next entry }

      end    

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

procedure listsym(sp: symptr);

var p, d: symptr;  { pointers for symbols }
    li:   labinx;  { index for labels }
    cl:   integer; { number of collumns output }

begin

   if fsym then begin { list symbols }

      formlist(p); { create symbols list from scope }
      alpsym(p); { alphabetize the list }
      writeln; { space off }
      { output header }
      write('Name:  '); 
      if sp <> nil then writesp(output, sp^.lab^) else write('<missing>');
      writeln;
      writeln('Depth: ', level:1);
      writeln; { space off }
      cl := 0; { clear collumn count }
      while p <> nil do begin { print labels }
   
         { print label with trailing spaces }
         for li := 1 to lsmmax do if li > max(p^.lab^) then write(' ')
                                  else write(p^.lab^[li]);
         write(' '); { separate }
         write(p^.ref:4); { output reference count }
         write(' '); { separate }
         if p^.dup then write('d') else write('-'); { print duplicate status }
         if p^.mis then write('m') else write('-'); { print misspell status }
         { print missing definition status }
         if p^.udf then write('u') else write('-');
         if p^.exp then write('e') else write('-'); { print exportable status }
         if p^.typ = nil then write('*') { output nil for type }
         else write(chr(ord('a')+ord(p^.typ^.t))); { output types as letters }
         write('   '); { separate }
         cl := cl+1; { count collumns }
         if cl >= prtmax div (lsmmax+1+4+1+4+3) then { check overflow }
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

Create numeric label

Creates a label in the scanner buffer nxtlab based on the scanner label nxtint.
This is done to allow Pascal's numeric labels to be handled just as normal
labels (which our extended mode labels are), and also to "normalize" the 
label so that, for instance, "0001" is the same label as "1".

******************************************************************************}

procedure numlab;

var i: labinx;  { index for label }
    p: integer; { power holder }
    n: integer; { number holder }

begin

   for i := 1 to labmax do nxtlab[i] := ' '; { clear the result buffer }
   i := 1; { set the 1st digit }
   p := digmax; { index the maximum digit }
   n := nxtint; { get the number to process }
   while p <> 0 do begin { process power }

      nxtlab[i] := chr((n div p) + ord('0')); { place digit }
      { move to the next digit, but only if not leading zero }
      if (i > 1) or (nxtlab[i] <> '0') then i := i+1;
      n := n mod p; { mask off high digit }
      p := p div 10

   end

end;

{******************************************************************************

Define new symbol

Checks to see if a local symbol by that name has already been defined, and if
so, outputs an error and flags the symbol as having been duplicated. This flag
is used to suppress typing errors, since we may now expect the object to be
treated as two different entities.

******************************************************************************}

procedure define(var sp: symptr);

begin

   sp := lclsym; { find previous symbol }
   if sp <> nil then begin { duplicate symbol }

      extlab := nxtlab; { copy label to error label }
      if sp^.ddf then perror(efwddef, [], []) { bad forward definition }
      else if sp^.hld then perror(eslfref, [], []) { self reference }
      else perror(edupsym, [], []); { symbol is duplicate }
      sp^.dup := true; { set symbol is duplicate }
      sp^.ddf := false; { change status to normal }
      sp^.hld := false; { set no holding }
      sp^.exp := export { set export status }

   end else plcsym(sp) { place as new symbol }

end;

{******************************************************************************

Lookup existing symbol

Checks to see if a global symbol with the name of the scanner tolken exists.
If so, this is returned. If not, we attempt to respell the symbol and find a
match. If this succeeds, we return that symbol and mark the symbol as the 
object of a respell. 
Lastly, if none of that works, we enter the symbol anyways as an undefined
entry with a single reference.

******************************************************************************}

procedure find(var sp: symptr);

begin

   sp := gblsym; { find global symbol }
   if sp = nil then begin { symbol not found }

      error(esymnf, false); { output symbol not found error }
      sp := mgblsym; { find misspelled global symbol }
      if sp <> nil then begin 

         copyp(extlab, sp^.lab^); { place proper spelling }
         error(emspell, false); { output misspelling message }
         { because respell is not really an error, but an information message,
           we back out this error count }
         errcnt := errcnt-1;
         sp^.mis := true { set symbol is target of misspell }

      end else begin { still not found, enter as undefined symbol }

         plcsym(sp); { place new symbol }
         sp^.udf := true; { set symbol undefined }
         sp^.typ := gbludf { attach to skeleton key } 

      end

   end else if sp^.ddf then begin { symbol is a delayed definition }

      error(efwdnptr, false); { inappropriate reference error }
      sp^.ddf := false { change status to normal }

   end else if sp^.hld then begin { symbol is in "holding" }

      error(eslfref, false); { self reference error }
      sp^.hld := false { change status to normal }

   end;
   sp^.ref := sp^.ref + 1 { increment reference counter }

end;

{******************************************************************************

Find symbol by type

Finds the first symbol in the symbol table that references the given type.
Only the first such symbol is found, even though there could be multiple
symbols. If there is NO corresponding symbol, a nil is returned.
Since this kind of reverse lookup is slow, and there is not garanteed to
be only one such symbol, this routine should be restricted to diagnostic
and error use.

******************************************************************************}

function labtyp(tp: typptr): symptr; 

var i: syminx; { index for symbol table }
    p: symptr; { pointer for symbols }
    r: symptr; { result pointer }

begin

   r := nil; { set no symbol }
   for i := 1 to symmax do begin { traverse the symbols head }

      p := symtbl[i]; { index the chain head }
      while p <> nil do begin { tranverse chain }

         { check symbol indexes the type entry }
         if (p^.typ = tp) then r := p; { symbol found } 
         p := p^.next { next symbol }

      end

   end;
   labtyp := r { return result }

end;

{******************************************************************************

Check references in current scope

Checks if any symbols in the current scope have a zero reference counter,
and if the option for this is set, output complaints about such symbols.

******************************************************************************}

procedure chkref;

var i: syminx; { index for symbol table }
    p: symptr; { pointer for symbols }

begin

   if fref then begin { in reference check mode }

      for i := 1 to symmax do begin { traverse the symbols head }
   
         p := symtbl[i]; { index the chain head }
         while p <> nil do begin { tranverse chain }
   
            { check symbol matches current scope, is not exportable, and has no
              references }
            if (p^.lvl = level) and (p^.ref = 0) and not p^.exp then begin
   
               copyp(extlab, p^.lab^); { place symbol name for error }
               error(esymnr, false) { no references }
   
            end;
            p := p^.next { next symbol }
   
         end
   
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

   if (typfre[t] <> nil) and frecir then begin { return existing entry }
  
      tp := typfre[t]; { index top entry }
      typfre[t] := tp^.next; { gap the list }
      typfct := typfct - 1 { remove free type }
      
   end else begin

      { get a new entry with the proper type. It must be allocated with
        a constant, so we have to decode the type given }
      case t of { type }

         tudf:     new(tp, tudf);
         tnil:     new(tp, tnil);
         tlab:     new(tp, tlab);
         ticst:    new(tp, ticst);
         tscst:    new(tp, tscst);
         tccst:    new(tp, tccst);
         trcst:    new(tp, trcst);
         tstcst:   new(tp, tstcst);
         tstet:    new(tp, tstet);
         tarrcst:  new(tp, tarrcst);
         tarrcel:  new(tp, tarrcel);
         treccst:  new(tp, treccst);
         treccel:  new(tp, treccel);
         tenum:    new(tp, tenum);
         tenme:    new(tp, tenme);
         tsub:     new(tp, tsub);
         tptr:     new(tp, tptr);
         tarray:   new(tp, tarray);
         tgarry:   new(tp, tgarry);
         tfile:    new(tp, tfile);
         tset:     new(tp, tset);
         trecord:  new(tp, trecord);
         tfield:   new(tp, tfield);
         tftag:    new(tp, tftag);
         tfcas:    new(tp, tfcas);
         tvar:     new(tp, tvar);
         tfix:     new(tp, tfix);
         tproc:    new(tp, tproc);
         tfunc:    new(tp, tfunc);
         tpar:     new(tp, tpar);
         tvpar:    new(tp, tvpar);
         twpar:    new(tp, twpar);
         tpproc:   new(tp, tpproc);
         tpfunc:   new(tp, tpfunc);
         tinteger: new(tp, tinteger);
         tchar:    new(tp, tchar);
         tboolean: new(tp, tboolean);
         treal:    new(tp, treal);
         tsreal:   new(tp, tsreal);
         ttext:    new(tp, ttext);
         teset:    new(tp, teset);
         tddf:     new(tp, tddf);
         tglbl:    new(tp, tglbl)

      end;
      tp^.t := t; { set type of entry }
      typcct := typcct + 1 { count created entries }

   end;
   tp^.next := nil; { set no next }
   tp^.pack := false; { set not packed }
   typact := typact + 1 { count active types }

end;

{******************************************************************************

Put type entry

Inserts the given type entry into the free type list appropriate to that type.

******************************************************************************}

procedure puttyp(tp: typptr); { entry to place }

begin

   tp^.next := typfre[tp^.t]; { link to head }
   typfre[tp^.t] := tp; { and place new head }
   typfct := typfct + 1; { count free symbols }
   typact := typact - 1 { and remove an active symbol }

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
   typstk^.lst := tp; { set new last }
   { if no bottom of update entry exists, set this as the start of the next
     update }
   if typstk^.upd = nil then typstk^.upd := tp;
   tp^.lvl := typlvl; { set level number }
   tp^.num := typstk^.seq; { set sequential type number }
   typstk^.seq := typstk^.seq+1 { next number }

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

Add types list

Adds the given type list to the top of the types stack. Used to restore type
entries after a forward operation.

******************************************************************************}

procedure addtyp(tl: typptr); { type list to add }

var tp: typptr; { pointer for type entries }

begin

   while tl <> nil do begin { while entries left in types list }

      tp := tl; { index top entry }
      tl := tl^.next; { gap top of list }
      tp^.next := typstk^.typ; { insert into type list }
      typstk^.typ := tp

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

            writesp(output, p^.lab^); { print label }
            write(': ') { space off }

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
   
{ print the entry number for a reference }

procedure listety(tp: typptr);

var p:        typptr;  { type entry pointer }
    c, m:     integer; { entry counts }
    sp:       tpsptr;  { type lists pointer }
    sm:       labl;    { block marker }

begin

   sp := typstk; { index top of stack }
   m := 0; { set no match }
   if tp = nil then write('nil') { write marker for nil }
   else while sp <> nil do begin { traverse the type level stack }

      p := sp^.typ; { index top of list }
      c := 1; { set 1st entry }
      m := 0; { set no match }
      while p <> nil do begin { traverse list }
      
         { if this is the entry, save the list count and stack count }
         if p = tp then begin m := c; copyp(sm, sp^.blk^) end;
         p := p^.next; { next entry }
         c := c + 1 { count entries }
      
      end;
      { if matched, print block number and entry number }
      if m <> 0 then begin

         write('['); writesp(output, sm); write(']'); { output block label }
         listlab(tp); { output label(s), if present }
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

   listlab(tp); { output any labels attached }
   if tp^.pack then write('packed: '); { output packed status }
   case tp^.t of { type }
   
      tudf: writeln('undefined');           
      tnil: writeln('nil (pointer value)'); 
      tlab: begin 

         write('goto label, defined: ', tp^.ldef);
         write(' references: ', tp^.lref:1);
         writeln(' statement level: ', tp^.slvl:1)

      end;
      ticst: writeln('integer constant: ', tp^.ival:1);
      tscst: begin 

         write('string constant: '''); 
         for si := 1 to max(tp^.sval^) do write(tp^.sval^[si]);
         writeln('''') 

      end; 
      tccst: writeln('Character constant: ''', tp^.cval, '''');
      trcst: writeln('real constant: ', tp^.rval);
      tstcst: begin

         write('set constant, base: ');
         listety(tp^.stct);
         write(' start: ');
         listety(tp^.stcc);
         writeln

      end;
      tstet: begin

         write('set constant, next: ');
         listety(tp^.sten);
         write(' starting value: ', tp^.stes:1, ' ending value: ', 
               tp^.stee, ' head: ');
         listety(tp^.steh);
         writeln

      end;
      tarrcst: begin

         write('Array constant, start: ');
         listety(tp^.arcn);
         writeln

      end;
      tarrcel: begin

         write('Array constant element, next: ');
         listety(tp^.aren);
         write(' constant: ');
         listety(tp^.arec);
         writeln

      end;
      treccst: begin

         write('Record constant, start: ');
         listety(tp^.recn);
         writeln

      end;
      treccel: begin

         write('Record constant element, next: ');
         listety(tp^.reen);
         write(' constant: ');
         listety(tp^.reec);
         writeln

      end;
      tenum: begin 

         write('enumerated head, start: '); 
         listety(tp^.enc); 
         writeln 

      end;
      tenme: begin 

         write('enumerated value: ', tp^.env:1, ' next: ');
         listety(tp^.enx); 
         write(' head: '); 
         listety(tp^.enh); 
         writeln 

      end;
      tsub: begin 

         write('subrange: ', tp^.subl:1, '..', tp^.subu:1);
         write(' base: '); 
         listety(tp^.subt); 
         writeln 

      end;
      tptr: begin 

         write('pointer: '); 
         listety(tp^.ptrt); 
         writeln 

      end;
      tarray: begin 

         write('array, base: '); 
         listety(tp^.arrt); 
         write(' index: '); 
         listety(tp^.arri); 
         writeln 

      end;
      tgarry: begin 

         write('general array, base: '); 
         listety(tp^.arrt); 
         writeln 

      end;
      tfile: begin 

         write('file: '); 
         listety(tp^.filt); 
         writeln 

      end;
      tset: begin 

         write('set: '); 
         listety(tp^.sett); 
         writeln 

      end;
      trecord: begin 
 
         write('record: '); 
         listety(tp^.recf); 
         writeln 

      end;
      tfield: begin 

         listrec(tp, tp^.fldh^.recl);
         write('record field, base: '); 
         listety(tp^.fldt); 
         write(' next: '); 
         listety(tp^.fldn); 
         write(' head: '); 
         listety(tp^.fldh); 
         writeln 

      end;
      tftag: begin

         listrec(tp, tp^.ftgh^.recl);
         write('variant record tag, base: ');
         listety(tp^.ftgt);
         write(' first case: ');
         listety(tp^.ftgc);
         write(' head: ');
         listety(tp^.ftgh);
         write(' exists: ', tp^.ftge);
         writeln

      end;
      tfcas: begin

         write('variant record case, constant: ', tp^.fcsc:1);
         write(' field start: ');
         listety(tp^.fcsf);
         write(' next: ');
         listety(tp^.fcsn);
         writeln

      end;          
      tvar: begin 

         write('variable, base: '); 
         listety(tp^.vart); 
         writeln 

      end;
      tfix: begin 

         write('fixed, base: '); 
         listety(tp^.fixt); 
         write(' constant fill: ');
         listety(tp^.fixc);
         writeln 

      end;
      tproc: begin 

         write('procedure, parameter start: '); listety(tp^.prcp); 
         if tp^.prco <> nil then 
            begin write(' ovl link: '); listety(tp^.prco) end;
         if tp^.prch <> nil then 
            begin write(' ovl head: '); listety(tp^.prch) end;
         if tp^.prcw <> nil then 
            begin write(' ovl win: '); listety(tp^.prcw) end;
         if tp^.prcf then write(' fwd ');
         if tp^.prce then write(' ext ');
         if tp^.prcx then write(' collide ');
         writeln 

      end;
      tfunc: begin 

         write('function, parameter start: '); 
         listety(tp^.fncp); 
         write(' result: '); 
         listety(tp^.fncr); 
         if tp^.fnco <> nil then 
            begin write(' ovl link: '); listety(tp^.fnco) end;
         if tp^.fnch <> nil then 
            begin write(' ovl head: '); listety(tp^.fnch) end;
         if tp^.fncw <> nil then 
            begin write(' ovl win: '); listety(tp^.fncw) end;
         if tp^.fncf then write(' fwd ');
         if tp^.fnce then write(' ext ');
         if tp^.fncx then write(' collide ');
         writeln 

      end;
      tpar: begin 

         write('value parameter, base: '); 
         listety(tp^.part);
         write(' next: '); 
         listety(tp^.parn); 
         write(' head: ');
         listety(tp^.parh);
         writeln 

      end;
      tvpar: begin 

         write('variable parameter, base: '); 
         listety(tp^.vprt);
         write(' next: '); 
         listety(tp^.vprn); 
         write(' head: ');
         listety(tp^.vprh);
         writeln 

      end;
      twpar: begin 

         write('view parameter, base: '); 
         listety(tp^.wprt);
         write(' next: '); 
         listety(tp^.wprn); 
         write(' head: ');
         listety(tp^.wprh);
         writeln 

      end;
      tpproc: begin 

         write('procedure parameter, parameter start: '); 
         listety(tp^.pprp); 
         write(' next: '); 
         listety(tp^.pprn); 
         writeln 

      end;
      tpfunc: begin 

         write('function parameter, parameter start: '); 
         listety(tp^.pfnp); 
         write(' result: '); 
         listety(tp^.pfnr); 
         write(' next: '); 
         listety(tp^.pfnn); 
         writeln 

      end;
      tinteger: writeln('integer'); 
      tchar: writeln('character'); 
      tboolean: writeln('boolean'); 
      treal: writeln('real'); 
      tsreal: writeln('short real'); 
      ttext: writeln('text');
      teset: writeln('empty set');
      tddf: begin

         write('delayed definition: ');
         listety(tp^.ddft);
         writeln(' defined: ', tp^.ddfd)

      end;
      tglbl: writeln('global block')
   
   end;

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

Check delayed defines

Checks the current block type entries for delayed pointer definitions that have
no resolution. Delayed pointer definitions MUST be resolved within the same
"type" section as started them, because they may be used in
procedures/functions where their types are checked.
This checking is "incremental", since any number of "type" sections can appear
in a block. So we flag and do not produce multiple errors when encountering
the same missing definition more than once.

******************************************************************************}

procedure chkddf;

var tp: typptr; { pointer for type entries }

begin

   tp := typstk^.typ; { index top of list }
   while tp <> nil do begin { traverse list }

      if tp^.t = tddf then if not tp^.ddfd and not tp^.ddfe then begin

         { entry was never defined, and no error has been flagged }
         { If the head symbol has been redefined, the association between
           symbol and entry is broken. Therefore, we have kept a private
           copy of the symbol pointer, and get the symbol from that }
         copyp(extlab, tp^.ddfs^.lab^); { place label for error }
         error(emfwddef, false); { missing forward definition }
         tp^.ddfe := true { set error was processed }

      end;
      tp := tp^.next { next entry }

   end

end; 

{******************************************************************************

Check dangling header files

Checks the current block type entries for header files that have not been
given a definition. This should be done before any block start, because those
header files may be used there.
Any header files so errored are changed to defined entries, with "text"
types. This keeps them from being flagged multiple times.
This check is disabled during 'uses' files.

******************************************************************************}

procedure chkdhf;

var tp: typptr; { pointer for type entries }
    sp: symptr; { pointer for symbol entry }

begin

   if uselvl = 0 then begin { not in a 'uses' file }

      tp := typstk^.typ; { index top of list }
      while tp <> nil do begin { traverse list }

         if tp^.t = tvar then if tp^.vars = fshparm then begin

            sp := labtyp(tp); { find corresponding symbol }
            if sp = nil then error(esflt28, true); { must be symbol }
            copyp(extlab, sp^.lab^); { place as error label }
            perror(ehfudf, [], []); { undefined header file }
            tp^.vars := fsherr { revert to ordinary text file }

         end;
         tp := tp^.next { next entry }

      end

   end

end; 

{******************************************************************************

Check types in current block

Performs checks on the current block type entries. The checks performed
include:

   1. Goto labels that have never been given targets.

   2. Goto labels that have not been used as goto targets.

   3. Functions that have no results specified (no assignment to function
      result).

   4. Forwarded procedures/functions that never have the main body defined.

Note that delayed pointer definitions are checked separately.

******************************************************************************}

procedure chktyp;

var tp, tp1: typptr; { pointer for type entries }
    s:       symptr; { pointer for symbol }

begin

   tp := typstk^.typ; { index top of list }
   while tp <> nil do begin { traverse list }

      if tp^.t in [tlab, tvar, tproc, tfunc] then case tp^.t of { type }

         tlab: if not tp^.ldef or (tp^.lref = 0) then begin 

            { no target defined or no 'goto' references }
            s := labtyp(tp); { find the symbol for the label }
            { must check symbol exists. The only reason that it wouldn't is
              if an error such as duplicate symbol occurred, so an error has
              already been output }
            if s <> nil then begin { there is a symbol }

               { check label exists in current block }
               if s^.lvl <> level then error(esflt15, true);
               if s^.ref <> 0 then begin 
   
                  { if the reference count for the symbol is non-zero, we 
                    output an error. If it is, we don't output, because the 
                    error message would be redundant with the unreferenced 
                    symbol check done elsewhere }
                  copyp(extlab, s^.lab^); { place for error }
                  if fref then begin { reference checks on }
   
                     if not tp^.ldef then error(elabndf, false) { no target }
                     else error(elabref, false) { no 'goto' references }
   
                  end else { reference checks off }
                     if not tp^.ldef and (tp^.lref <> 0) then
                        { there have been references, and no target is defined.
                          we remain quiet about no target with no refernces
                          (label not used at all), and target present with no
                          references }
                        error(elabndf, false) { no target }
   
               end

            end

         end;   

         tvar: if (tp^.varr = 0) and fass and not tp^.vare then begin

            { no threats to variable }
            s := labtyp(tp); { find the symbol for the entry }
            if s <> nil then begin { symbol exists }

               if (s^.ref <> 0) and fref then begin 
   
                  { we didn't already flag this undefined }
                  copyp(extlab, s^.lab^); { place for error }
                  error(evarass, false) { variable assignment }
   
               end

            end

         end;

         tproc: if tp^.prcf and not tp^.prce then begin { no body defined }

            { link head entry if an overload }
            tp1 := tp; { copy head }
            if tp1^.prch <> nil then tp1 := tp1^.prch; { link head }
            s := labtyp(tp1); { find the symbol for the entry }
            if s <> nil then begin { symbol exists }

               { we didn't already flag this undefined }
               copyp(extlab, s^.lab^); { place for error }
               if chkovld(tp) then { overload } 
                  error(efwdondf, false) { forward never defined }
               else { normal }
                  error(efwdndf, false) { forward never defined }

            end

         end;

         tfunc: if tp^.fncf and not tp^.fnce then begin { no body defined }

            { link head entry if an overload }
            tp1 := tp; { copy head }
            if tp1^.fnch <> nil then tp1 := tp1^.fnch; { link head }
            s := labtyp(tp1); { find the symbol for the entry }
            if s <> nil then begin { symbol exists }

               { we didn't already flag this undefined }
               copyp(extlab, s^.lab^); { place for error }
               if chkovld(tp) then { overload } 
                  error(efwdndf, false) { forward never defined }
               else { normal }
                  error(efwdndf, false) { forward never defined }

            end

         end;

      end;
      tp := tp^.next { next entry }

   end;
   if curprc <> nil then begin { there is a procedure/function active }

      if curprc^.t = tfunc then { it is a function }
         if curprc^.fncc = 0 then begin { no assignents were done }

         s := labtyp(curprc); { find the symbol for the entry }
         if s <> nil then begin { symbol exists }

            copyp(extlab, s^.lab^); { place for error }
            error(enfncra, false) { no function result }

         end

      end

   end

end; 

{******************************************************************************

Find actual type

Returns the "actual" type for a given type entry. This is simply the type with
any delayed definitions removed.

*******************************************************************************}

function actt(tp: typptr): typptr;

begin

   { remove delayed definitions }
   while tp^.t = tddf do tp := tp^.ddft;
   actt := tp { return result }

end;

{******************************************************************************

Verify string is single character

Checks if the type is a string type, and if the string type is a single 
character, and if not found, outputs an error and changes the type to 
undefined.

*******************************************************************************}

procedure chkschr(var tp: typptr);

begin

   tp := actt(tp); { find actual type }
   if tp^.t = tscst then begin { it's a string }

      { string must be single character }
      if max(tp^.sval^) <> 1 then begin
       
         perror(embschr, [], []); { output error } 
         tp := gbludf { set to undefined }

      end

   end

end;

{******************************************************************************

Check type is overload

Checks if the given type is an overloaded function or procedure.

*******************************************************************************}

function chkovld(tp: typptr): boolean;

var f: boolean; { flag }

begin

   { Check either overload list or head is active. This is necessary because
     the original, overloaded function or procedure will have no head, and the
     last in list will have no next. }
   if tp^.t = tfunc then f := (tp^.fnch <> nil) or (tp^.fnco <> nil)
   else if tp^.t = tproc then f := (tp^.prch <> nil) or (tp^.prco <> nil)
   else f := false; { not a overloadable type }

   chkovld := f { return result }

end;

{******************************************************************************

Check overload parameter lists unique

Checks two procedures or functions, or mix, against each other to determine
if they are unique to each other. The following criteria determine uniqueness
as far as overloads are concerned:

1. Whether a function or a procedure.

2. Number of parameters.

3. Type compatibility of parameters. This includes function results, if a
parameter is a function parameter.

4. "single character" mode of parameter. String types, either a single character
packed array of char, or a packed general array of char, are unique in that
they can accept a single character constant. This means they are ambiguous with
other parameters of type char.

5. "left side mode" rule. This rule states that if two procedures or functions
that match up to, and including parameter n, the modes on parameter n must
match. This is because for parameters to be processed sequentially, their
mode (var, view or value) must be known in order to process them correctly.

Type compatibility is determined via the standard ISO 7185 criteria for type
compatibility, with one extention. A function parameter has a type, which is
determined by its result.

If the procedure/functions are not unique, an error results.

*******************************************************************************}

procedure chkovlunq(pa, pb: typptr); { procedure/functions to compare }

var pan, pbn: integer; { number of parameters }
    ppa, ppb: typptr;  { parameter list pointers }
    m:        boolean; { match flag }

{ index next parameter in list }

procedure nxtpar(var pp: typptr);

begin

   case pp^.t of { parameter type }

      tpar:   pp := pp^.parn;
      tvpar:  pp := pp^.vprn;
      twpar:  pp := pp^.wprn;
      tpproc: pp := pp^.pprn;
      tpfunc: pp := pp^.pfnn

   end

end;

function parno(tp: typptr): integer; { find number of parameters }

var pp: typptr;  { parameter pointer }
    pn: integer; { parameter counter }

begin

   { index top of parameter list }
   if tp^.t = tproc then pp := tp^.prcp else pp := tp^.fncp;
   pn := 0; { clear parameter counter }
   while pp <> nil do begin { count parameters }

      pn := pn+1; { count this parameter }
      nxtpar(pp) { link next parameter }

   end;

   parno := pn { return result }

end;

{ check type is, or can be, a single character }

function sinchr(tp: typptr): boolean;

var f: boolean;

begin

   f := false; { set not single character }
   tp := actt(tp); { find actual type }
   if tp = tscst then begin { string constant }

      f := max(tp^.sval^) = 1 { true if single character }

   end else if t = tarray then begin { array }

      if not tp^.pack then f := false { not packed }
      else if not chart(tp^.arrt) then f := false { not base char }
      else (lbound(tp^.arri) <> 1) or (ubound(tp^.arri) <> 1) then 
         f := false { not a 1..1 array }

   end else if t = tgarry then begin { general array }

      if not tp^.pack then f := false { not packed }
      else if not chart(tp^.gart) then f := false { not base char }

   end;

   issinchr := f { return result }

end;

begin

;writeln('chkovlunq: begin');
;write('pa: '); listtype(pa);
;write('pb: '); listtype(pb);
   { validate input parameters }
   if (pa^.t <> tproc) and (pa^.t <> tfunc) then error(esflt31, true);
   if (pb^.t <> tproc) and (pb^.t <> tfunc) then error(esflt31, true);
   if pa^.t = pb^.t then begin { procedure/function status is the same }

      pan := parno(pa); { set parameter count a }
      pbn := parno(pb); { set parameter count b }
      { index the top of both parameter lists }
      if pa^.t = tproc then ppa := pa^.prcp else ppa := pa^.fncp;
      if pb^.t = tproc then ppb := pb^.prcp else ppb := pb^.fncp;
      m := true; { default to matches }
      while (ppa <> nil) and (ppb <> nil) do begin { compare parameters }

         if not typcmp(ppa, ppb) and not (sinchr(ppa) and sinchr(ppb)) then
            m := false { set does not match }
         else { check for mode matching }
            if (ppa^.t in [tpar, tvpar, twpar]) and 
               (ppb^.t in [tpar, tvpar, twpar]) and (ppa^.t <> ppb^.t) and
               m then 
                  { Parameters match in type, differ in mode, and have
                    convergent left sides. This is an error. }
                  perror(econovl, [], []);
         nxtpar(ppa); { next in lists }
         nxtpar(ppb)

      end;
      { if the lists match under overload rules, then the overload is invalid }
      if m and (pan = pbn) then begin

         perror(einvovl, [], []); { output error }
         { set collision occurred in both }
         if pa^.t = tproc then pa^.prcx := true;
         if pb^.t = tproc then pb^.prcx := true

      end

   end
;writeln('chkovlunq: end');

end;

{******************************************************************************

Check overload

Checks the indicated overload qualifies as unique. The given overload procedure
or function is checked against all other procedures and functions in the
overload group.

*******************************************************************************}

procedure valovl(pp: typptr);

var pp1: typptr; { procedure pointer }

begin

   { index head of overload group list }
   if pp^.t = tproc then pp1 := pp^.prch else pp1 := pp^.fnch;
   while pp1 <> nil do begin { traverse list }

      { check not the same routine, then compare }
      if pp <> pp1 then chkovlunq(pp, pp1); { compare routines }
      { next routine }
      if pp1^.t = tproc then pp1 := pp1^.prco else pp1 := pp1^.fnco

   end

end;

{******************************************************************************

Find congruous overload

Searches the overload group for the given procedure or function, and returns
the first one that is congruous with it. This information is used to look for
forwarded overloads.

Note that the prime entry could be returned. The returned entry should be 
checked against the symbol's prime entry to determine this.

*******************************************************************************}

procedure fndovlcon(pp: typptr; var fp: typptr);

var pp1: typptr; { procedure pointer }

begin

   fp := nil; { clear found }
   { index head of overload group list }
   if pp^.t = tproc then pp1 := pp^.prch else pp1 := pp^.fnch;
   while pp1 <> nil do begin { traverse list }

      if (pp^.t = pp1^.t) and (pp <> pp1) then 
         { same type, but not same entry }
         if pp^.t = tproc then begin { compare procedures }

            if fndcon(pp^.prcp, pp1^.prcp) then fp := pp1 { compares }

         end else begin { compare functions }

            if fndcon(pp^.fncp, pp1^.fncp) then fp := pp1 { compares }

         end;
      { next routine }
      if pp1^.t = tproc then pp1 := pp1^.prco else pp1 := pp1^.fnco

   end

end;

{******************************************************************************

Load ordinal constant

Loads the constat from the given type entry. Will load as an integer any of
an integer, single character string, or enumerated type.

*******************************************************************************}

function consti(tp: typptr): integer;

var i: integer; { result holder }

begin

   tp := actt(tp); { find actual type }
   if tp^.t = ticst then i := tp^.ival { integer constant }
   else if tp^.t = tscst then begin { string constant }

      if max(tp^.sval^) = 1 then { single character }
         i := ord(tp^.sval^[1]) { load character }
      else error(esflt26, true) { must be single character }

   end else if tp^.t = tccst then i := ord(tp^.cval) { character constant }
   else if tp^.t = tenme then i := tp^.env { enumerated }
   else error(esflt3, true); { none ? }
   consti := i { return result }

end;

{******************************************************************************

Find base type

Returns the base type for the given type. The base type is the given type
with subranges and delayed define entrys removed, and components such as 
enumerated entries and record fields linked back to the head type.
Basically the base type in this context is the type at which two different
types may be compared.

*******************************************************************************}

function baset(tp: typptr): typptr;

begin

   tp := actt(tp); { find actual type }
   { remove any subranges }
   while tp^.t = tsub do tp := tp^.subt;
   case tp^.t of { type }

      tudf:     ; { already at base type }
      tnil:     ; { no base type exists }
      tlab:     ; { no base type }
      ticst:    tp := gblint; { integer }
      tscst:    ; { not possible base for strings, since it depends on length }
      tccst:    tp := gblchr; { character }
      trcst:    tp := gblreal; { real }
      tstcst:   ; { must serve as it's own base type }
      tstet:    tp := tp^.steh; { link head }
      tarrcst:  ; { already at base type }
      tarrcel:  tp := tp^.arec; { link constant }
      treccst:  ; { already at base type }
      treccel:  tp := tp^.reec; { link constant }
      tenum:    ; { already at base type }
      tenme:    tp := tp^.enh; { link enumerated head }
      tsub:     ; { not possible because of above removal }
      tptr:     ; { already at base type }
      tarray:   ; { already at base type }
      tgarry:   ; { already at base type }
      tfile:    ; { already at base type }
      tset:     ; { already at base type }
      trecord:  ; { already at base type }
      tfield:   tp := tp^.fldh; { link record head }
      tftag:    tp := tp^.ftgh; { link record head }
      tfcas:    ; { no base type (would actually be it's tag entry) }
      tvar:     tp := tp^.vart; { link type }
      tfix:     tp := tp^.fixt; { link type }
      tproc:    ; { no base type }
      tfunc:    tp := tp^.fncr; { link return type for function }
      tpar:     tp := tp^.part; { link type }
      tvpar:    tp := tp^.vprt; { link type }
      twpar:    tp := tp^.wprt; { link type }
      tpproc:   ; { already at base type }
      tpfunc:   tp := tp^.pfnr; { link return type for function }
      tinteger: ; { already at base type } 
      tchar:    ; { already at base type }
      tboolean: ; { already at base type }
      treal:    ; { already at base type }
      tsreal:   ; { already at base type }
      ttext:    ; { already at base type }
      teset:    ; { already at base type }
      tddf:     ; { not possible because of above removal }
      tglbl:      { no base type }

   end;
   { remove any subranges }
   while tp^.t = tsub do tp := tp^.subt;
   tp := actt(tp); { find actual type }
   { remove any subranges }
   while tp^.t = tsub do tp := tp^.subt;
   baset := tp { return type }

end;

{******************************************************************************

Check string type

Checks if the given type is a string. This can be either a string constant, or
an array of characters with a starting index of 1, which includes general 
arrays.

*******************************************************************************}

function strt(tp: typptr): boolean;

var m:   boolean; { result }
    tp1: typptr; { type pointer }

begin

   tp := actt(tp); { find actual type }
   m := true; { set is a string }
   if tp^.t <> tscst then begin { check array type }

      if ((tp^.t <> tarray) and (tp^.t <> tgarry)) 
         or not tp^.pack then { must be packed array }
         m := false { must be packed array }
      else begin { is a packed array }

         if tp^.t = tarray then tp1 := actt(tp^.arrt) { index base type }
         else tp1 := actt(tp^.gart);
         if tp1^.t <> tchar then m := false { must be character }
         else if tp^.t <> tgarry then begin 

            { if array, validate subrange. general arrays automatically
              start with one }
            tp1 := actt(tp^.arri); { index index type :}
            if tp1^.t <> tsub then error(esflt4, true); { should be subrange }
            if tp1^.subl <> 1 then m := false { must be 1 based }

         end

      end

   end;
   strt := m { return result }

end;

{******************************************************************************

Check char type

Checks if the given type is a char. This can be either a string constant with
one character, or a char type.

*******************************************************************************}

function chart(tp: typptr): boolean;

var m: boolean; { match result }

begin

   tp := baset(tp); { find the base type }
   m := true; { set char type }
   if (tp^.t <> tchar) and (tp^.t <> tccst) then
      { check for single character string constant }
      if tp^.t <> tscst then m := false { not a string constant }
      else m := max(tp^.sval^) = 1; { must be single character }
   chart := m

end;

{******************************************************************************

Check integer type

Checks if the given type is an integer. This can be either an integer constant, 
or the integer type.

*******************************************************************************}

function intt(tp: typptr): boolean;

begin

   tp := baset(tp); { find the base type }
   { result true if it's integer constant or integer type }
   intt := (tp^.t = tinteger) or (tp^.t = ticst)

end;

{******************************************************************************

Check real type

Checks if the given type is a real. This can be a short real, a long real, or
a real constant.

*******************************************************************************}

function realt(tp: typptr): boolean;

begin

   tp := baset(tp); { find base type }
   { result true if it's a short or a long real }
   realt := (tp^.t = treal) or (tp^.t = tsreal)

end;

{******************************************************************************

Check boolean type

Checks if the given type is a boolean. 

*******************************************************************************}

function boolt(tp: typptr): boolean;

begin

   tp := baset(tp); { find base type }
   { result true if it's a boolean }
   boolt := tp^.t = tboolean

end;

{******************************************************************************

Check file type

Checks if the given type is a file. 

*******************************************************************************}

function filet(tp: typptr): boolean;

begin

   tp := baset(tp); { find base type }
   { result true if it's a file }
   filet := (tp^.t = tfile) or (tp^.t = ttext)

end;

{******************************************************************************

Check set type

Checks if the given type is a set. 

*******************************************************************************}

function sett(tp: typptr): boolean;

begin

   tp := baset(tp); { find base type }
   { result true if it's a set }
   sett := (tp^.t = tset) or (tp^.t = teset) or (tp^.t = tstcst)

end;

{******************************************************************************

Get array length from type

Loads the length of an array from the type. Note that this will not return
the length of a general array, which has no length.

*******************************************************************************}

function arrlent(tp: typptr): integer;

var len: integer;

begin

   tp := actt(tp); { find actual type }
   if tp^.t = tscst then len := max(tp^.sval^) { string constant }
   else if tp^.t = tarray then begin { array }

      tp := actt(tp^.arri); { index index type :}
      if tp^.t <> tsub then error(esflt5, true); { should be subrange }
      len := tp^.subu-tp^.subl+1 { find length }

   end else error(esflt6, true); { should be array or string }
   arrlent := len { return result }

end;

{******************************************************************************

Check file component

Checks if the given type is a file, or contains a file component. 

******************************************************************************}

function filect(tp: typptr): boolean;

var m: boolean; { match }

{ check field list for file components }

function filetf(tp: typptr): boolean; { head of field list }

var m: boolean; { match }

begin

   m := false; { set no file component }
   while tp <> nil do begin { traverse }

      tp := actt(tp); { find actual type }
      if tp^.t = tfield then begin { field list }

         if filect(tp^.fldt) then m := true; { set file type }
         tp := tp^.fldn { next entry }

      end else if tp^.t = tftag then begin { tagfield }

         { note that the tag field itself cannot be a file }
         tp := tp^.ftgc; { index top of case list }
         while tp <> nil do begin { traverse }

            tp := actt(tp); { find actual type }
            if tp^.t <> tfcas then error(esflt12, true); { verify }
            if filetf(tp^.fcsf) then m := true; { set file type }
            tp := tp^.fcsn { next entry }

         end

      end else error(esflt13, true) { verify entry type }

   end;
   filetf := m { return result }

end;

begin

   tp := actt(tp); { find actual type }
   m := true; { set is a file type }
   if (tp^.t <> tfile) and (tp^.t <> ttext) then begin { not direct file type }

      if tp^.t = tarray then { array }
         m := filect(tp^.arrt) { check status of base type }
      else if tp^.t = tgarry then { array }
         m := filect(tp^.gart) { check status of base type }
      else if tp^.t = trecord then { record }
         m := filetf(tp^.recf) { check status of fields }
      else m := false { set not file type or component }

   end;   
   filect := m { return result }

end;

{******************************************************************************

Compare types

Checks if the two given types are compatible with each other.

*******************************************************************************}

function typcmp(tp1, tp2: typptr): boolean;   

var m: boolean; { result }

begin

;writeln;
;write('typcmp: tp1: '); listtype(tp1);
;write('typcmp: tp2: '); listtype(tp2);
   m := true; { set types compatible }
   tp1 := baset(tp1); { find base types }
   tp2 := baset(tp2);
   if (tp1 <> tp2) and (tp1^.t <> tudf) and (tp2^.t <> tudf) then begin 

      m := false; { set no match }
      { not the same type, and not undefined }
      if strt(tp1) and strt(tp2) then begin { both are strings }

;writeln('both are strings');
         { check either is a general array, which moves the length check to
           runtime }
         if (tp1^.t <> tgarry) and (tp2^.t <> tgarry) then
            { check strings have equal length }
            m := arrlent(tp1) = arrlent(tp2)
         else m := true { set matches }

      end else if sett(tp1) and sett(tp2) then begin { both are sets }

         { if either set or both are the empty set, they are allways
           compatible, because empty sets are universal }
         if (tp1^.t = teset) or (tp2^.t = teset) then m := true
         else begin

            { check same packing status }
            if (tp1^.t = tset) and (tp2^.t = tset) then begin

               { both are formal sets. set types must have then same packing 
                 status, or one set is 'contextable' (may change it's 
                 packed/unpacked status according to context) }
               if (tp1^.pack = tp2^.pack) or tp1^.setc or tp2^.setc then 
                  m := true

            end else m := true; { one must be constant set, set passes }
            { check they have the same base type }
            if tp1^.t = tset then tp1 := tp1^.sett
            else tp1 := tp1^.stct;
            if tp2^.t = tset then tp2 := tp2^.sett
            else tp2 := tp2^.stct;
            { base types must be equal now }
            if baset(tp1) <> baset(tp2) then m := false

         end

      end else if (tp1^.t in [tarray, tgarry]) and 
                  (tp2^.t in [tarray, tgarry]) then begin { both are arrays }

         if tp1^.t = tarray then tp1 := tp1^.arrt { get base types }
         else tp1 := tp1^.gart;
         if tp2^.t = tarray then tp2 := tp2^.arrt
         else tp2 := tp2^.gart;
         m := tp1 = tp2 { base types must be equal now }

      end else if chart(tp1) and chart(tp2) then m := true { if both chars }
      else if ((tp1^.t = tptr) and (tp2^.t = tnil)) or
              ((tp1^.t = tnil) and (tp2^.t = tptr)) then
         m := true { one is pointer, and the other is 'nil' key }
      else m := realt(tp1) and realt(tp2) { both are variants of real }

   end;

   typcmp := m { return match status }
;writeln('match: ', m:0);

end; 

{******************************************************************************

Compare assignment types

Checks if the two given types are assignment compatible with each other.

*******************************************************************************}

function typcmpa(dtp, stp: typptr): boolean;

var m: boolean; { result }

begin

   m := true; { set types compatible }
   dtp := baset(dtp); { find base types }
   stp := baset(stp);
   if (dtp^.t <> tudf) and (stp^.t <> tudf) then begin { both are defined }

      { check if file type or file component, which are not compatible }
      if filect(dtp) or filect(stp) then m := false
      else if not typcmp(dtp, stp) then { types not compatible }
         { check destination is real and source is integer }
         m := realt(dtp) and intt(stp)

   end;
   typcmpa := m { return match status }

end;     

{******************************************************************************

Find procedure/function parameter lists are congruous

Checks if the procedure or function parameter list given is "congruous" with a
given actual procedure or function list, that is, all of the parameters are the
same type. This includes recursively checking through any procedure/function
parameters contained in the list, etc. Returns true if so.

*******************************************************************************}

function fndcon(pla, plb: typptr): boolean;

var f: boolean;

begin

   f := true; { set default is congruous }
   while (pla <> nil) and (plb <> nil) and f do begin { traverse }

      { check parameter modes are equal }
      if pla^.t <> plb^.t then f := false
      else case pla^.t of { parameter }

         tpar:   begin

            { check types not equal, and neither is undefined }
            if (pla^.part <> plb^.part) and (pla^.part^.t <> tudf) and
               (plb^.part^.t <> tudf) then f := false;
            pla := pla^.parn; { find next }
            plb := plb^.parn

         end;
         tvpar:  begin

            { check types not equal, and neither is undefined }
            if (pla^.vprt <> plb^.vprt) and (pla^.vprt^.t <> tudf) and
               (plb^.vprt^.t <> tudf) then f := false;
            pla := pla^.vprn; { find next }
            plb := plb^.vprn

         end;
         twpar:  begin

            { check types not equal, and neither is undefined }
            if (pla^.wprt <> plb^.wprt) and (pla^.wprt^.t <> tudf) and
               (plb^.wprt^.t <> tudf) then f := false;
            pla := pla^.wprn; { find next }
            plb := plb^.wprn

         end;
         tpproc: begin

            { check those lists equal }
            if not fndcon(pla^.pprp, plb^.pprp) then f := false;
            pla := pla^.pprn; { find next }
            plb := plb^.pprn

         end;
         tpfunc: begin

            { check those lists equal }
            if not fndcon(pla^.pfnp, plb^.pfnp) then f := false;
            { check function results are equal, and neither undefined }
            if (pla^.pfnr <> plb^.pfnr) and (pla^.pfnr^.t <> tudf) and
               (plb^.pfnr^.t <> tudf) then f := false;
            pla := pla^.pfnn; { find next }
            plb := plb^.pfnn

         end

      end

   end;
   { check parameter lists are the same length }
   if (pla <> nil) or (plb <> nil) then f := false;

   fndcon := f { return result }

end;

{******************************************************************************

Check procedure/function types are congruous

Checks if the procedure or function parameter given is "congruous" with a given
actual procedure or function, that is, all of the parameters are the same type.
This includes recursively checking through any procedure/function parameters
contained in the list, etc.

If the lists are not congruous, an error results.

*******************************************************************************}

procedure chkcon(pla, plb: typptr); { type lists to compare }

begin

   if not fndcon(pla, plb) then perror(eprncon, [], []);

end;

{******************************************************************************

Stack new types list

Adds a new level to the types list, corresponding to a new block.

*******************************************************************************}

procedure pshtyp(sp: symptr);

var ts: tpsptr; { stack list pointer }

begin

   if (tpsfre <> nil) and frecir then begin { recover entry from free list }

      ts := tpsfre; { index top entry }
      tpsfre := tpsfre^.next { gap list }
      
   end else new(ts); { get new list entry }
   ts^.next := typstk; { link to top of stack }
   typstk := ts; { place new top }
   ts^.typ := nil; { clear new list }
   ts^.lst := nil; { set no last entry }
   ts^.upd := nil; { set no update entry }
   ts^.blk := nil; { clear block id }
   if sp <> nil then copysp(ts^.blk, sp^.lab^); { place block id }
   ts^.seq := 1; { set 1st sequence number }
   typlvl := typlvl+1 { add typing level }

end;

{******************************************************************************

Pop types list

Removes the top types list. It is a system error if the stack is empty.

*******************************************************************************}

procedure poptyp;

var ts: tpsptr; { type list entry pointer }

begin

   if typstk = nil then error(esflt7, true); { fatal error on stack empty }   
   ts := typstk; { index top entry }
   typstk := typstk^.next; { remove top entry }
   ts^.next := tpsfre; { link into free list }
   tpsfre := ts;
   typlvl := typlvl-1 { subtract typing level }

end;

{******************************************************************************

Find lower bound of type

Finds the lower bound of an ordinal type.

*******************************************************************************}

function lbound(tp: typptr): integer;

var lb: integer; { result holder }

begin

   tp := actt(tp); { find actual type }
   if tp^.t = tenum then lb := tp^.enc^.env { return enumerated }
   else if tp^.t = tenme then lb := tp^.enh^.enc^.env { return enumerated }
   else if tp^.t = tsub then lb := tp^.subl { return subrange }
   else if intt(tp) then lb := -maxint { return integer }
   else if chart(tp) then lb := 0 { return character }
   else if tp^.t = tboolean then lb := 0 { return boolean }
   else if tp^.t = tudf then lb := -maxint { undefined, return minimum }
   else error(esflt10, true); { else is invalid type }   
   lbound := lb

end;

{******************************************************************************

Find upper bound of type

Finds the upper bound of an ordinal type.

*******************************************************************************}

function ubound(tp: typptr): integer;

var ub: integer; { result holder }

begin

   tp := actt(tp); { find actual type }
   if (tp^.t = tenum) or (tp^.t = tenme) then begin

        if tp^.t = tenme then tp := tp^.enh; { find head of type }
        tp := tp^.enx; { index 1st enum entry }
        while tp^.enx <> nil do tp := tp^.enx; { find ending entry }
        ub := tp^.env { return enumerated }

   end else if tp^.t = tsub then ub := tp^.subu { return subrange }
   else if intt(tp) then ub := maxint { return integer }
   else if chart(tp) then ub := 255 { return character }
   else if tp^.t = tboolean then ub := 1 { return boolean }
   else if tp^.t = tudf then ub := maxint { undefined, return maximum }
   else error(esflt11, true); { else is invalid type }   
   ubound := ub

end;

{******************************************************************************

Process threat to object

Given a variable, parameter or fixed, processes a "theat" or attempt to modify
the object. In most cases this simply increments the threat count for the
object. However, some objects, such as fixed objects or view parameters, cannot
be threatened at all.

*******************************************************************************}

procedure threaten(sp: symptr; tp: typptr); { object to threaten }

begin

   if tp^.t in [tvar, tfix, tpar, tvpar, twpar] then begin

      copyp(extlab, sp^.lab^); { place error label }
      case tp^.t of
   
         { variable, increment threat count }
         tvar:  begin

            tp^.varr := tp^.varr + 1;
            { check in use by 'for' }
            if tp^.varf <> 0 then perror(eforviu, [], []) { variable in use }

         end;
         tfix: 
            { threats to fixed are allways an error }
            perror(efixth, [], []);
         tpar:  tp^.parr := tp^.parr + 1;
         tvpar: tp^.vprr := tp^.vprr + 1;
         twpar: 
            { threats to view parameters are allways an error }
            perror(eviewth, [], [])

      end
   
   end

end;

{******************************************************************************

Check admissable constant structure type

Given a simple or complex type, we check if it is suitable for use as a
structured constant. In order for this to occur, the following rules must
be obeyed:

   1. The type must not be file, or contain a file type.
   2. The type must not be pointer, or contain a pointer type.
   3. The type must not be a general array (the case where a general array is
      contained is already flagged as an error in context).

If one of the rules are broken, an error is output. The entire type tree is
examined recursively.

*******************************************************************************}

procedure chkcst(tp: typptr);

var err: boolean; { error has been output }

{ check field list }

procedure chklst(tp: typptr);

begin

   while tp <> nil do begin { traverse field list }

      if tp^.t = tfield then begin { normal field }

         chkcst(tp^.fldt); { check base type of field }
         tp := tp^.fldn { index next entry }

      end else begin { must be tagfield }

         if tp^.t <> tftag then 
            error(esflt22, true); { fault not tagfield }
         tp := tp^.ftgc; { index 1st case list }
         while tp <> nil do begin { traverse case list }

            if tp^.t <> tfcas then
               error(esflt22, true); { fault not case entry }
            chklst(tp^.fcsf); { check sublist }
            tp := tp^.fcsn { link next }

         end

      end

   end

end;

begin

   err := false; { set no error output }
   tp := baset(tp);
   if filet(tp) or (tp^.t = tptr) or (tp^.t = tgarry) then begin

      { bad component }
      { output error if none output before }
      if not err then perror(einvcse, [], []);
      err := true { set error output }

   end;
   if tp^.t = tarray then chkcst(tp^.arrt) { check array substructure }
   else if tp^.t = trecord then chklst(tp^.recf) { check record substructure }

end;

{******************************************************************************

Check type in proper context

Given a set of valid types for the context, will validate that the given type
is in the set. If not, an error occurs, and the type entry is reset to the
undefined type.

*******************************************************************************}

procedure typcon(var tp: typptr;  { type entry to check }
                     ts: typset); { set of valid types }

var tpt: typptr; { type entry holder }

begin

   tpt := actt(tp); { find actual type }
   if not (tpt^.t in ts) then begin { type is not found in proper set }

      perror(etypcon, [], []); { output type context error }
      tp := gbludf { set type undefined }

   end

end;

{******************************************************************************

Check pointer component

Checks if the given type is a pointer, or contains a pointer component.
If there is a pointer component, an error is processed.
This routine is used to reject pointer parameters to monitors.

******************************************************************************}

procedure ptrcmp(tp: typptr);

var err: boolean; { error output flag }

{ check field list for pointer components }

procedure chkfld(tp: typptr); { head of field list }

begin

   while tp <> nil do begin { traverse }

      tp := actt(tp); { find actual type }
      if tp^.t = tfield then begin { field list }

         ptrcmp(tp^.fldt); { check type }
         tp := tp^.fldn { next entry }

      end else if tp^.t = tftag then begin { tagfield }

         { note that the tag field itself cannot be a pointer }
         tp := tp^.ftgc; { index top of case list }
         while tp <> nil do begin { traverse }

            tp := actt(tp); { find actual type }
            if tp^.t <> tfcas then error(esflt21, true); { verify }
            chkfld(tp^.fcsf); { check type }
            tp := tp^.fcsn { next entry }

         end

      end else error(esflt24, true) { verify entry type }

   end

end;

begin

   err := false; { set no error output }
   tp := actt(tp); { find actual type }
   if tp^.t = tptr then begin { pointer found }

      { if we have not already output an error }
      if not err then perror(emonptr, [], []); { process pointer error }
      err := true { set error output }

   end else begin { not direct pointer type }

      if tp^.t = tarray then { array }
         ptrcmp(tp^.arrt) { check status of base type }
      else if tp^.t = tgarry then { array }
         ptrcmp(tp^.gart) { check status of base type }
      else if tp^.t = trecord then { record }
         chkfld(tp^.recf) { check status of fields }

   end   

end;

{******************************************************************************

Check misspelled tolken with predjuce

Checks if the next symbol is an id, and if it is, checks if it is either a
user id, or even a misspelling of a user id. If neither, then we may attempt to
respell it to a tolken.
This is done in the syntax when either a tolken or an id is the correct next
symbol. In order to make sure that we don't "grab" a valid id that happens
to look like a tolken, or even a misspelling of a valid id, all this must be
checked first.
Actually part of the "scanner" module family tree, the need to deal with the
symbol table promotes this routine.

******************************************************************************}

procedure chktkmp(c: tolkset); { correction set }

var sp:   symptr; { symbol pointer } 
    cort: tolken; { corrected tolken }

begin

   if nxttlk = cidentifier then begin { if the next is an id }

      { lookup to see if we might have an id that is actually
        a misspelled tolken. In order to do this, we must make
        sure that it is not a valid or even misspelled symbol first }
      sp := gblsym; { check symbol exists }
      if sp = nil then begin { symbol does not exist }

         sp := mgblsym; { check symbol is not a possible misspell of 
                          existing symbol }
         if sp = nil then begin { not found }
   
            { attempt spelling correction }
            cort := mattlk(c);
            if cort <> cundefined then begin { correct the spelling }

               perror(esymnf, [], []); { symbol not found }
               corspell(cort) { correct }

            end

         end
   
      end
      { at this point, we exit with either the id repaired as a common tolken,
        or have left the id alone }

   end

end;

{******************************************************************************

Check type entry is valid for output

Checks if the given type entry is a system procedure/function, a delayed
definition, or an undefined entry marker. System procedures/functions are not
output because they are handled entirely in the intermediate code. Delayed
define entrys exist only as placeholders in the parser, and are simply skipped
over. Finally, no error free block should contain undefined entries. The
exception is the system area, where the one undefined entry lives.

******************************************************************************}

function valtyp(tp: typptr): boolean;

var o: boolean; { output flag }

begin

   o := true; { set type valid }
   { if the entry is procedure or function, check system, and set invalid
     if so. This is because system procedures/functions are handled by
     special intermediate codes }
   if tp^.t = tproc then begin if tp^.prcd <> pfnil then o := false end
   else if tp^.t = tfunc then begin if tp^.fncd <> pfnil then o := false end
   else if tp^.t = tddf then o := false { set skip }
   else if tp^.t = tudf then begin { undefined entry }

      o := false; { set skip }
      { the error marker entry should never appear in any level but system
        when the output is error free }
      if typlvl <> 1 then error(esflt17, true)

   end;
   valtyp := o { return result }

end;

{******************************************************************************

Write type entry linkage

Writes the complete intermediate address of the given type entry. The logical
address of a type entry consists of it's logical type level number, and it's
logical type entry number.
If the link passed is null, then both addresses parts are passed as 0, an
invalid number for both.

******************************************************************************}

procedure wrtlnk(tp: typptr); { type entry pointer }

begin

   if tp <> nil then tp := actt(tp); { find the actual type }
   if tp = nil then 
      begin wrtnum(0); wrtnum(0) end { link is nil, output 0 for that }
   else begin 
 
      wrtnum(tp^.lvl); { output level }
      wrtnum(tp^.num) { output entry number }

   end

end;

{******************************************************************************

Output types section

Outputs the current types section to the intermediate file. Each type is output
in its intermediate equivalent form, with sequence numbers used to represent
branches in types.
Suppresses output if the intermediate file is not open, which will happen if
either no output is specified, or there has been an error.
All block levels are output. The system level (0) is also output, but is
only used by the parser to establish links to it's own system entries. Many of
the system entries, like that for predefined functions, are simply output as
placeholders, which serve to keep the type entry sequence numbers correct.
In fact, the only really usefull types in the system are the predefined
types, which mark references to such types, and 'maxint', which appears as a
constant. However, the system remains flexible, and in fact anything that
can be described in pascal terms, such as variables, procedures, etc., can
appear predefined in the system area.
The output of types is incremental. This routine can be called multiple times
for the same block. Only the last types added are output. This allows types
to be interspersed with other blocks. However, no forward references should be
active across such calls. For example, a pointer forward resolution should
not be waiting.

******************************************************************************}

procedure wrttyp;

var tp:  typptr;  { pointers to type entries }
    si:  integer; { index for string }
    sp:  symptr;  { symbol pointer }

{ output simple symbol. this is a symbol with the symbol string only }

procedure wrtssym(sp: symptr);

var i: labinx; { index for symbol label }

begin

   wrtcod(issym); { output simple symbol marker }
   wrtint(max(sp^.lab^)); { output label length }
   for i := 1 to max(sp^.lab^) do
      wrtint(ord(sp^.lab^[i])) { output label characters }

end;

begin

   if fintopn and (typstk^.upd <> nil) then begin 

      { the intermediate file is open, and there are type entrys to be updated.
        index beginning of types list for current block, first entry not
        updated }
      tp := typstk^.upd;
      while tp <> nil do begin { traverse list }

         { if not a valid entry, just output a placeholder }
         if not valtyp(tp) then wrtcod(inull)
         { otherwise perform output according to type }
         else case tp^.t of { type }

            tudf:     ; { should not appear }
            tnil:     wrtcod(inil); { 'nil' universal pointer }
            tlab:     wrtcod(ilab); { 'goto' label }
            ticst:    begin { integer constant }

               wrtcod(iicst); { output marker }
               wrtnum(tp^.ival) { output value }

            end;
            tscst:    begin { string constant }

               wrtcod(iscst); { output marker }
               wrtint(max(tp^.sval^)); { output string length }
               { output string characters }
               for si := 1 to max(tp^.sval^) do wrtint(ord(tp^.sval^[si]))

            end;
            tccst:    begin { character constant }

              wrtcod(iccst); { output marker }
              wrtint(ord(tp^.cval)) { ouptut character value }

            end;
            trcst:    begin { real constant }

               wrtcod(ircst); { output marker }
               wrtreal(tp^.rval) { output value }

            end;
            tstcst:   begin { constant set }

               wrtcod(istcst); { output marker }
               wrtlnk(tp^.stct); { output base type }
               wrtlnk(tp^.stcc) { output constant list start }

            end;
            tstet:    begin { constant set entry }

               wrtcod(istet); { output marker }
               wrtlnk(tp^.sten); { output next entry link }
               wrtnum(tp^.stes); { output starting value }
               wrtnum(tp^.stee); { output ending value }
               wrtlnk(tp^.steh) { output head entry link }

            end;
            tarrcst:  begin { array constant entry }

               wrtcod(iarrcst); { output marker }
               wrtlnk(tp^.arcn) { output list link }
               
            end;
            tarrcel:  begin { array constant element }

               wrtcod(iarrcel); { output marker }
               wrtlnk(tp^.aren); { output next link }
               wrtlnk(tp^.arec) { output constant link }

            end;
            treccst:  begin { record constant entry }

               wrtcod(ireccst); { output marker }
               wrtlnk(tp^.recn) { output list link }
               
            end;
            treccel:  begin { record constant element }

               wrtcod(ireccel); { output marker }
               wrtlnk(tp^.reen); { output next link }
               wrtlnk(tp^.reec) { output constant link }

            end;
            tenum:    begin { enumerated type }

               wrtcod(ienum); { output marker }
               wrtlnk(tp^.enc) { output link }

            end;
            tenme:    begin { enumerator constant entry }

               wrtcod(ienme); { output marker }
               wrtlnk(tp^.enx); { output next entry link }
               wrtlnk(tp^.enh); { output head link }
               wrtnum(tp^.env) { output enumerated constant }

            end;
            tsub:     begin { subrange type }

               wrtcod(isub); { output marker }
               wrtlnk(tp^.subt); { output base type link }
               wrtnum(tp^.subl); { output lower bound }
               wrtnum(tp^.subu) { output upper bound }

            end;
            tptr:     begin { pointer type }

               wrtcod(iptr); { output marker }
               wrtlnk(tp^.ptrt) { output base type link }
            
            end;
            tarray:   begin { array type }

               wrtcod(iarray); { output marker }
               wrtlnk(tp^.arrt); { output base type link }
               wrtlnk(tp^.arri) { output index type link }
            
            end;
            tgarry:   begin { array type }

               wrtcod(igarry); { output marker }
               wrtlnk(tp^.gart) { output base type link }
            
            end;
            tfile:   begin { file type }

               wrtcod(ifile); { output marker }
               wrtlnk(tp^.filt) { output base type link }
            
            end;
            tset:    begin { set type }

               wrtcod(iset); { output marker }
               wrtlnk(tp^.sett) { output base type link }
            
            end;
            trecord: begin { record type }

               wrtcod(irecord); { output marker }
               wrtlnk(tp^.recf); { output field list link }
               { output record field symbols }
               sp := tp^.recl; { index top of list }
               { output all symbols in field list }
               while sp <> nil do begin wrtssym(sp); sp := sp^.rnxt end
            
            end;
            tfield:  begin { record field type }

               wrtcod(ifield); { output marker }
               wrtlnk(tp^.fldn); { output next field link }
               wrtlnk(tp^.fldh); { output head link }
               wrtlnk(tp^.fldt) { output base type link }
            
            end;
            tftag:   begin { record tag field type }

               wrtcod(iftag); { output marker }
               wrtlnk(tp^.ftgc); { output case list link }
               wrtlnk(tp^.ftgh); { output head link }
               wrtlnk(tp^.fldt); { output base type link }
               wrtint(ord(tp^.ftge)) { output exists flag }
            
            end;
            tfcas:   begin { record case constant type }

               wrtcod(ifcas); { output marker }
               wrtlnk(tp^.fcsn); { output next case entry link }
               wrtlnk(tp^.fcsf); { output field list link }
               wrtnum(tp^.fcsc) { output case constant }
            
            end;
            tvar:    begin { variable type }

               wrtcod(ivar); { output marker }
               wrtlnk(tp^.vart); { output base type link }
               wrtint(ord(tp^.vare)) { output external flag }
            
            end;
            tfix:    begin { fixed type }

               wrtcod(ifix); { output marker }
               wrtlnk(tp^.fixt); { output base type link }
               wrtlnk(tp^.fixc); { output constant fill }
               wrtint(ord(tp^.fixe)) { output external flag }
            
            end;
            tproc:   if not tp^.prcq then begin { procedure type }

               { entry is not marked as deleted forward overload }
               wrtcod(iproc); { output marker }
               wrtlnk(tp^.prcp); { output parameter list link }
               wrtint(ord(tp^.prce)); { output external flag }
               wrtlnk(tp^.prch) { output overload list head link }
            
            end else wrtcod(inil); { output placeholder }
            tfunc:   if not tp^.fncq then begin { function type }

               { entry is not marked as deleted forward overload }
               wrtcod(ifunc); { output marker }
               wrtlnk(tp^.fncp); { output parameter list link }
               wrtlnk(tp^.fncr); { output function result link }
               wrtint(ord(tp^.fnce)); { output external flag }
               wrtlnk(tp^.fnch) { output overload list head link }
            
            end else wrtcod(inil); { output placeholder }
            tpar:    begin { parameter type }

               wrtcod(ipar); { output marker }
               wrtlnk(tp^.parn); { output next parameter link }
               wrtlnk(tp^.part); { output base type link }
               wrtlnk(tp^.parh) { output head link }
            
            end;
            tvpar:    begin { variable parameter type }

               wrtcod(ivpar); { output marker }
               wrtlnk(tp^.vprn); { output next parameter link }
               wrtlnk(tp^.vprt); { output base type link }
               wrtlnk(tp^.vprh) { output head link }
            
            end;
            twpar:    begin { variable parameter type }

               wrtcod(iwpar); { output marker }
               wrtlnk(tp^.wprn); { output next parameter link }
               wrtlnk(tp^.wprt); { output base type link }
               wrtlnk(tp^.wprh) { output head link }
            
            end;
            tpproc:   begin { procedure parameter type }

               wrtcod(ipproc); { output marker }
               wrtlnk(tp^.pprp); { output parameter list link }
               wrtlnk(tp^.pprn) { output next parameter link }
            
            end;
            tpfunc:   begin { function parameter type }

               wrtcod(ipfunc); { output marker }
               wrtlnk(tp^.pfnp); { output parameter list link }
               wrtlnk(tp^.pfnr); { output function result link }
               wrtlnk(tp^.pfnn) { output next parameter link }
            
            end;
            tinteger: wrtcod(iint); { integer type }
            tchar:    wrtcod(ichar); { character type }
            tboolean: begin { boolean type }

               wrtcod(iboolean); { output marker }
               wrtlnk(tp^.bnc) { output enumerated constants link }
            
            end;
            treal:    wrtcod(ireal); { real type }
            tsreal:   wrtcod(isreal); { short real type }
            ttext:    wrtcod(itext); { text file type }
            teset:    wrtcod(ieset); { empty set type }
            tddf:     ; { should not appear }
            tglbl:    begin { global mark type }

               wrtcod(iglbl); { output marker }
               wrtint(ord(tp^.mm)) { output type }

            end

         end;
         tp := tp^.next { index next type entry }

      end;
      typstk^.upd := nil { clear next update entry }

   end

end;

{******************************************************************************

Output current symbols

Outputs all symbols in the current scope to the intermediate file.
Pointers to type entries are output as a sequence number, and these numbers
should have already been set up in the types list.
Suppresses output if the intermediate file is not open, which will happen if
either no output is specified, or there has been an error.

******************************************************************************}

procedure wrtsyms;

var i: syminx;  { index for symbol table }
    p: symptr;  { pointer for symbols }

{ output symbol. this is a symbol with the symbol string only }

procedure wrtsym(sp: symptr);

var i: labinx; { index for symbol label }

begin

   if valtyp(sp^.typ) then begin { type is valid for output }

      wrtcod(isym); { output simple symbol marker }
      wrtint(max(sp^.lab^)); { output label length }
      for i := 1 to max(sp^.lab^) do
         wrtint(ord(sp^.lab^[i])); { output label characters }
      if sp^.typ = nil then error(esflt18, true); { fault on no linkage }
      wrtlnk(sp^.typ); { output logical address }
      wrtint(ord(sp^.exp)) { output exportable status }

   end

end;

begin

   if fintopn then begin { the intermediate file is open }

      for i := 1 to symmax do begin { traverse the symbols head }

         p := symtbl[i]; { index the chain head }
         while p <> nil do { traverse symbols chain }
            if (p^.lvl = level) and not p^.out then begin

               wrtsym(p); { output symbol }
               p^.out := true; { set this symbol was output }
               p := p^.next { index next symbol }

            end else p := nil; { stop the search }

      end

   end

end;

begin
end.

