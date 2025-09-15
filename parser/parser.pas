{*******************************************************************************
*                                                                              *
*                               PARSER MODULE                                  *
*                                                                              *
*                             9/89 S. A. Moore                                 *
*                                                                              *
* Contains all of the parsing routines for Pascal. The entire syntax is        *
* traversed, and intermediates are constructed and generated at syntactically  *
* relivant points. The symbol table construction is directed here. Errors      *
* are handled by either assuming the existance of a missing tolken (tolken     *
* insertion), or skipping ahead in the stream (tolken deletion).               *
*                                                                              *
*******************************************************************************}

module parser(output);

uses strlib,   { string functions }
     extlib,   { operating extentions }
     xltlib,   { transliteration }
     sepsgn,   { separated sign support }
     demo,     { demo mode enable/disable }
     parsedef, { global defines }
     common,   { global variables }
     parsesvs, { support procedures }
     scanner,  { scanner }
     symbol;   { symbol management }

procedure parmod(ss: tolkset); forward;

private

procedure parstat(ss: tolkset); forward;
procedure parexpr(varref: typptr; ss: tolkset; var tp: typptr); forward;
procedure partype(ss: tolkset; var tp: typptr); forward;
procedure pardec(ss: tolkset; inuses: boolean); forward;
procedure parprcfnci(proc: boolean; ss: tolkset; inhatt: boolean; 
                     methld: boolean;pp: typptr; var tp: typptr); forward;
procedure parconst(ss: tolkset; var tp: typptr); forward;
procedure parusesjoins(ss: tolkset; isjoins: boolean); forward;
procedure parclass(ss: tolkset); forward;

{*******************************************************************************

Parse qualident

   qualident = identifier [ '.' identifier ] ...

Processes a qualified identifier, which is an identifier with any number of
'qualifications' after it. The resulting symbol is returned, and the qualident
sequence is skipped. If no identifier is present, nil is returned.

Note that even though this routine can parse a series of nested classes, 
realistically, there will be one module and one class at maximum.

If the reference grace flag is on, will allow reference graces. This means that
a reference is treated just as if it represents its base class.

If the undefined flag is on, then any undefines trigger respell and default
defines. This allows a fully classed identifier, but does not define it. In this
case, nil is returned for the symbol.

If the parse forward false references bit is on, then we will parse forward
over '.' even if the first identifier is not a class, module or reference. This
is used for cases where the '.' is used for referencing, as in var. Note that
continuing to parse where the left side is not a proper qualifying reference
is an error, so that is effectively error recovery behavior.

If a head identifier is provided, it means that the leading label was parsed
and skipped, and the qualident is to start with that. This is required in
certain places in the syntax because the type of identifier that follows is not
known.

*******************************************************************************}

procedure parqualident(     ss:  tolkset; { skip set }
                            rg:  boolean; { allow reference grace }
                            ud:  boolean; { default define undefined }
                            ffr: boolean; { parse forward false references }
                       view hl:  string;  { head label already parsed }
                       var  sp:  symptr;  { resulting symbol or nil }
                       var  rl:  string); { undefined label }

var mp:  mltptr;  { module pointer }
    sp1: symptr;  { symbol pointer }
    tp:  typptr;  { type pointer }
    lab: labl;    { label save }
    qr:  boolean; { the left side is a qualifying reference }

begin

   if fparse then writeln(':qualident');
   sp := nil; { set no identifier }
   mp := nil; { set no module }
   if (nxttlk <> cidentifier) and (len(hl) = 0) then { missing id }
      perror(eidnexp, [cidentifier, cperiod]+ss, []);
   { check next is identifier, or a missing head id is provided }
   if (nxttlk = cidentifier) or (len(hl) <> 0) then begin

      if len(hl) = 0 then copy(lab, nxtlab) { copy the next identifier }
      else copy(lab, hl); { copy the missing head id }
      sp := gblsym(lab); { find symbol without qualident }
      copy(rl, lab); { copy that to undefined label }
      if sp = nil then begin { not found }

         mp := fndqual(lab); { check if name is module }
         if mp = nil then begin

            { no, the symbol is completely undefined }
            if ud then begin { perform undefined processing }
            
               perror(esymnf, [], [], lab); { output symbol not found error }
               symudf(lab, sp) { process symbol undefined }
               
            end

         end

      end else newsym(lab, sp); { perform new scope symbol processing }
      if len(hl) = 0 then gettlk; { skip id }
      { See if left side is a qualified reference, a module, class, or reference
        with references allowed. }
      qr := mp <> nil; { module }
      if sp <> nil then begin { symbol exists }

        if classt(sp^.typ) then qr := true; { class }
        if reft(sp^.typ) and rg then qr := true { reference }

      end;
      { Now symbol contains a regular symbol, a class, or the module qual is
        represented by the mp. A class can be returned as a symbol, a module
        qual cannot. We parse the qualification if either the left side 
        qualifies, or contains a module, class or reference with grace enabled,
        or we are to parse even false forward references. }
      while (nxttlk = cperiod) and (qr or ffr) do begin { process qualifiers }
     
         gettlk; { skip '.' }
         if nxttlk <> cidentifier then { missing id }
            perror(eidnexp, [cidentifier, cperiod]+ss, []);
         if nxttlk = cidentifier then begin { found qualified identifier }

            if mp <> nil then begin { process module qualification }

               { search for the symbol in that module }
               sp := fndmodsym(mp^.modp, nxtlab);
               { check not found }
               if sp = nil then begin

                  { output symbol not found in module error }
                  perror(esnfim, [], [], nxtlab, mp^.modp^.modn^);
                  { we have to be careful here. If the id exists in common 
                    symbols, we can't treat it as a missed, but must
                    return that. }
                  sp := gblsym(nxtlab); { find existing symbol }
                  if (sp = nil) and ud then { not found }
                     symudf(nxtlab, sp) { process symbol undefined }

               end;
               mp := nil { clear the module link now }

            end else begin { process class qualification }

               if sp <> nil then begin { there is a possible class symbol }

                  tp := baset(sp^.typ); { get base type }
                  { Check is a class, or is a reference with reference grace 
                    allowed. }
                  if (tp^.t in [tclass, tatom, tthread]) or 
                     rg and (tp^.t = treference) then begin

                     { link to the base class if it is a reference }
                     if tp^.t = treference then tp := tp^.reft;
                     sp1 := sp; { save class symbol }
                     { now search for the symbol in that class }
                     sp := clsbas(tp, nxtlab);
                     { reject attempts to access private class members }
                     if sp <> nil then if sp^.prv then sp := nil;
                     { class reference should always be found }
                     if sp = nil then begin
                    
                        { identifier not found in class }
                        perror(eclsnf, [], [], nxtlab, sp1^.lab^);
                        { we have to be careful here. If the id exists in common 
                          symbols, we can't treat it as a missed, but must
                          return that. }
                        sp := gblsym(nxtlab); { find existing symbol }
                        if (sp = nil) and ud then { not found }
                           symudf(nxtlab, sp) { process symbol undefined }
                    
                     end

                  end

               end

            end;
            gettlk { skip id }

         end;
         { See if left side is a qualified reference, a module, class, or 
           reference with references allowed. }
         qr := false; { set not qualified }
         if sp <> nil then begin { symbol exists }
         
           if classt(sp^.typ) then qr := true; { class }
           if reft(sp^.typ) and rg then qr := true { reference }
         
         end
         
      end;
      if mp <> nil then { module qual was unfinished }
         { unfinished module qualifier }
         perror(eunfmql, [], [], mp^.modp^.modn^)

   end

end;

{*******************************************************************************

Parse constant factor

   factconst = '(' const ')' | 'not' factconst | string | const-ident | integer

Parse and generate constant factor. Accepts a tolken skip set.
Returns the type entry for the constant, which will be a string
constant, integer constant, or a skeleton key if nothing found.
Error recovery:

1. No id or integer for constant, skip to follow on 
missing constant.

*******************************************************************************}

procedure parfaccon(ss: tolkset; var tp: typptr);

var sp:   symptr;  { symbol pointer }
    ti:   integer; { integer temp }
    tp1:  typptr;  { type pointer }
    last: tolken;  { parsing aid }
    si:   labinx;  { index for string }
	stct: typptr;  { set constant base type holder }
    stcc: typptr;  { set constant list holder }
	lab:  labl;    { label for undefines }

begin

   if fparse then writeln(':factconst');
   if not (nxttlk in [clparen, cnot, cstring, cinteger, creal, cidentifier, 
                      clbrkt]) or
      ((nxttlk in [clparen, cnot]) and fansi) then { no constant tolken }
         perror(einvcst, [cstring, cinteger, creal, cidentifier, cnot, 
                          clparen]+ss, []);
   if nxttlk = clparen then begin { (const) }

      gettlk; { next }
      parconst([crparen]+ss, tp); { parse constant }
      expect(crparen, erpexp, [crparen]+ss, []) { expect ')' }

   end else if nxttlk = cnot then begin { not factconst }

      gettlk; { next }
      parfaccon(ss, tp); { parse constant factor }
      { check boolean or integer type }
      if not (boolt(tp) or intt(tp) or (tp^.t = tudf)) then 
         perror(etmbboi, [], []); { must be boolean or integer }
      if boolt(tp) then begin { resolve boolean constant }

         { find opposite of truth }
         if consti(tp) = 0 then tp := gbltrue else tp := gblfalse;

      end else begin { resolve integer constant }

         if tp^.ival.s then perror(ebolneg, [], []) { boolean on negative }
         else begin { solve }

            { perform constant integer not }
            ti := not tp^.ival.v; { find 'not' result }
            lsttyp(tp, ticst); { get a new integer entry }
            tp^.ival.v := ti { place result }

         end

      end

   end else if nxttlk = cstring then begin { string }

      lsttyp(tp, tscst); { get a string constant type entry }
      new(tp^.sval, nxtlen); { create a string to hold }
      { copy string into that }
      for si := 1 to nxtlen do tp^.sval^[si] := nxtlab[si];
      gettlk { skip string }

   end else if nxttlk = cinteger then begin { integer constant }

         lsttyp(tp, ticst); { get a string constant type entry }
         tp^.ival.v := nxtint; { place integer }
         tp^.ival.s := false; { input integers always unsigned }
         gettlk { skip integer }

   end else if nxttlk = creal then begin { real constant }

         lsttyp(tp, trcst); { get a string constant type entry }
         tp^.rval := nxtflt; { place real }
         gettlk { skip real }

   end else if nxttlk = cidentifier then begin { id }
 
      parqualident(ss, true, true, true, '', sp, lab); { parse qualified identifier }
      if sp^.typ = nil then error(esflt1, true); { fault on null type }
      tp := actt(sp^.typ); { find actual type }
      if not (tp^.t in [ticst, trcst, tenme, tscst, tccst, tstcst]) then begin

         if tp^.t <> tudf then perror(esymtyp, [], [], sp^.lab^); { wrong type }
         tp := gbludf { set result undefined }

      end

   end else if nxttlk = clbrkt then begin { set constant }

      gettlk;
      stct := nil; { set no base type found }
      stcc := nil; { set constant list nil }
      if nxttlk <> crbrkt then repeat { set elements }

         parconst([crbrkt, crange, ccma]+ss, tp); { parse constant expression }
         tp1 := baset(tp); { get base type }
         if chart(tp1) then tp1 := gblchr; { convert character type }
         if not (tp1^.t in [tudf, tinteger, tlinteger, tcardinal, tlcardinal, 
                            tenum, tboolean, tchar]) then begin

            perror(einvstb, [], []); { not a valid set builder }
            tp := gbludf; { set undefined }
            stct := gbludf; { and the whole set is undefined as well }
            stcc := nil { and discard constant list }

         end;
         if stct <> nil then begin { base type of set defined }

            { check types of contructors match }
            if not typcmp(tp, stct) then begin { no match }

               perror(escncmp, [], []); { type mismatch }
               tp := gbludf; { set undefined }
               stct := gbludf; { and the whole set is undefined as well }
               stcc := nil { and discard constant list }

            end

         end else stct := tp1; { set base type of set }
         if stct^.t <> tudf then begin

            { if the set is still defined, add new constant to list. if not, we
              are just parsing and skipping elements }
            lsttyp(tp1, tstet); { get set element entry }
            tp1^.sten := stcc; { link into constant list }
            stcc := tp1;
            { set first element, and also the last, which would default to a single
              element }
            tp1^.stes.v := consti(tp);
            tp1^.stes.s := constis(tp);
            tp1^.stee.v := tp1^.stes.v;
            tp1^.stee.s := tp1^.stes.s

         end;
         if nxttlk = crange then begin

            gettlk; { next }
            parconst([ccma, crbrkt, crange]+ss, tp); { parexpr }
            if tp^.t = tudf then
               stct := gbludf; { undefined, set base undefined }
            tp1 := baset(tp); { get base type }
            if chart(tp1) then tp1 := gblchr; { convert character type }
            if not (tp1^.t in [tudf, tinteger, tlinteger, tcardinal, tlcardinal,
                               tenum, tboolean, tchar]) then
               perror(einvstb, [], []); { not a valid set builder }
            { check types of contructors match }
            if not typcmp(tp1, stct) then begin { no match }

               perror(escncmp, [], []); { type mismatch }
               tp := gbludf; { set undefined }
               stct := gbludf; { and the whole set is undefined as well }
               stcc := nil { and discard constant list }

            end;
            { set the ending value on the last range }
            if stcc <> nil then begin

               stcc^.stee.v := consti(tp);
               stcc^.stee.s := constis(tp);
               { check valid range specification }
               if ssgtn(stcc^.stes, stcc^.stee) then 
                  { start > end }
                  perror(einvsub, [], [])

            end

         end;
         if (nxttlk <> ccma) and (nxttlk <> crbrkt) then
            { we don't have an exit tolken }
            perror(erbcmexp, [ccma, crbrkt, crange]+exprset+ss, []);
         last := nxttlk; { save tolken }
         if nxttlk = ccma then gettlk { next }

      { until not ',', and no expression set }
      until not (last in [ccma, crange]+exprset);
      if nxttlk = crbrkt then gettlk; { next }
      { if no members defined, set to the empty set }
      if stcc = nil then tp := gbleset
      { if the set base is undefined, just make the whole result undefined }
      else if stct^.t = tudf then tp := gbludf
	  else begin { set valid, set up entry }

         lsttyp(tp, tstcst); { get set constant entry }
         tp^.stct := stct; { set base type }
         tp^.stcc := stcc; { set constant list }
		 { fix head pointers }
		 while stcc <> nil do begin { traverse }

            if stcc^.t <> tstet then error(esflt29, true); { fault }
            stcc^.steh := tp; { set head }
			stcc := stcc^.sten { link next }

         end

      end

   end else tp := gbludf { else return result undefined }

end;

{*******************************************************************************

Parse constant term

   termconst = factconst ['*' factconst | '/' factconst | 'div' factconst | 
               'mod' factconst | 'and' factcont]..

Parse and generate constant term. Accepts a tolken skip set.
Returns the type entry for the constant, which will be a string
constant, integer constant, or a skeleton key if nothing found.
Error recovery:

1. No id or integer for constant, skip to follow on 
missing constant.

*******************************************************************************}

procedure partrmcon(ss: tolkset; var tp: typptr);

var tp1:      typptr;  { type pointer }
    tk:       tolken;  { tolken save }
    trl, trr: real;    { real temps }
    ti:       integer; { integer temp value }
    ts:       boolean; { integer temp sign }

{ determine type correct for operator }

procedure rgttyp(    tk: tolken;  { operator tolken }
                 var tp: typptr); { type to check }

var m: boolean; { type correct flag }

begin

   case tk of { operator }

      { integer, real or set }
      ctimes:     m := intt(tp) or realt(tp); { integer or real }
      crdiv:      m := intt(tp) or realt(tp); { integer or real }
      cdiv, cmod: m := intt(tp); { integer }
      cand:       m := boolt(tp) or intt(tp) { boolean or integer }

   end;
   if not m and (tp^.t <> tudf) then begin { bad type }

      perror(etypcon, [], []); { type in wrong context }
      tp := gbludf { set result undefined }

   end

end;

begin

   if fparse then writeln(':termconst');
   { parse left constant factor }
   parfaccon([ctimes, crdiv, cdiv, cmod, cand]+ss, tp);
   chktkm([cdiv, cmod, cand]); { check possible misspelled tolken }
   while (nxttlk in [ctimes, crdiv, cdiv, cmod, cand]) and not fansi do begin

      tk := nxttlk; { save operator tolken }
      rgttyp(tk, tp); { check proper type for operator }
      gettlk; { next }
      { parse right constant factor }
      parfaccon([ctimes, crdiv, cdiv, cmod, cand]+ss, tp1);
      rgttyp(tk, tp1); { check proper type for operator }
      if boolt(tp) or boolt(tp1) then if not typcmp(tp, tp1) then begin

         { if one is boolean, both must be }
         perror(etypcmp, [], []); { types not compatible }
         tp := gbludf { set result undefined }

      end;
      { perform real valued operations }
      if (tk = crdiv) or realt(tp) or realt(tp1) then begin { result is real }

         trr := 1; { set default results }
         trl := 1;
         { find real left }
         if tp^.t = ticst then begin

            trl := tp^.ival.v;
            if tp^.ival.s then trl := trl*(-1)

         end else if tp^.t = trcst then trl := tp^.rval;
         { find real right }
         if tp1^.t = ticst then begin

            trr := tp1^.ival.v;
            if tp^.ival.s then trr := trr*(-1)
            
         end else if tp1^.t = trcst then trr := tp1^.rval;
         lsttyp(tp, trcst); { get a new real entry }
         { perform operation }
         case tk of { operator }

            ctimes: trl := trl*trr;
            crdiv:  trl := trl/trr;
            cdiv:   ; { not valid }
            cmod:   ;
            cand:

         end;
         lsttyp(tp, trcst); { get a new real entry }
         tp^.rval := trl { place result }

      end else if (boolt(tp) and (tp^.t = tenme)) and
                  (boolt(tp1) and (tp1^.t = tenme)) and (tk = cand) then begin

         { process boolean and }
         if (consti(tp) <> 0) and (consti(tp1) <> 0) then 
            tp := gbltrue else tp := gblfalse { set result value }
         
      end else if (tp^.t = ticst) and (tp1^.t = ticst) then begin

         { perform integer operations }
         case tk of { operator }

            ctimes: begin { find multiply }

               { check for overflow }
               if tp^.ival.v > maxint div tp1^.ival.v then begin

                  perror(ecstopv, [], []); { constant operation overflow }
                  ti := 0 { replace with zero }

               end else begin { perform multiply }

                  ti := tp^.ival.v*tp1^.ival.v; { find value part }
                  ts := tp^.ival.s xor tp1^.ival.s { find 'xor' of signs }

               end

            end;
            crdiv:  ; { not valid }
            cdiv:   begin { perform division }

               ti := tp^.ival.v div tp1^.ival.v; { find value part }
               ts := tp^.ival.s xor tp1^.ival.s { find 'xor' of signs }

            end;
            cmod:   begin

               ti := tp^.ival.v mod tp1^.ival.v; { find value part }
               ts := tp^.ival.s xor tp1^.ival.s { find 'xor' of signs }

            end;
            cand:   if tp^.ival.s or tp1^.ival.s then
                       { cannot 'and' negative operands }
                       perror(ebolneg, [], []) { boolean negative }
                    else ti := tp^.ival.v and tp1^.ival.v

         end;
         lsttyp(tp, ticst); { get a new integer entry }
         tp^.ival.v := ti; { place result }
         tp^.ival.s := ts

      end;
      { if either operand is undefined, then the result is undefined }
      if (tp^.t = tudf) or (tp1^.t = tudf) then tp := gbludf

   end

end;

{*******************************************************************************

Parse constant

   const = ['+' | '-'] termconst ['+' factconst | '-' factconst | 
                                 | 'xor' factconst | 'or' factconst]..

Parse and generate constant expression. Accepts a tolken skip set. Returns the
type entry for the constant, which will be a string constant, integer constant,
or a skeleton key if nothing found.

Error recovery:

1. No id or integer for constant, skip to follow on 
missing constant.

*******************************************************************************}

procedure parconst(ss: tolkset; var tp: typptr);

var tp1:      typptr;  { type pointer }
    tk:       tolken;  { tolken save }
    trl, trr: real;    { real temps }
    ti:       integer; { integer temp value }
    ts:       boolean; { integer temp sign }

{ determine type correct for operator }

procedure rgttyp(    tk: tolken;  { operator tolken }
                 var tp: typptr); { type to check }

var m: boolean; { type correct flag }

begin

   case tk of { operator }

      { integer, real or set }
      cplus:  m := intt(tp) or realt(tp); { integer, real or set }
      cminus: m := intt(tp) or realt(tp); { integer, real or set }
      cor:    m := boolt(tp) or intt(tp); { boolean or integer }
      cxor:   m := boolt(tp) or intt(tp) { boolean or integer }

   end;
   if not m and (tp^.t <> tudf) then begin { bad type }

      perror(etypcon, [], []); { type in wrong context }
      tp := gbludf { set result undefined }

   end

end;

begin

   if fparse then writeln(':constant');
   tk := nxttlk; { save sign tolken }
   if (nxttlk = cplus) or (nxttlk = cminus) then { sign }
      gettlk; { skip '+'/'-' }
   { parse left constant factor }
   partrmcon([cplus, cminus, cor, cxor]+ss, tp);
   if (tk = cplus) or (tk = cminus) then begin

      if not (intt(tp) or realt(tp) or (tp^.t = tudf)) then begin

         { wrong type }
         perror(etypcon, [], []); { type in wrong context }
         tp := gbludf { set result undefined }

      end;
      if tk = cminus then begin { operation is negate }

         if tp^.t = ticst then begin 

            { perform constant integer negate }
            ti := tp^.ival.v; { find negated result }
            ts := not tp^.ival.s;
            lsttyp(tp, ticst); { get a new integer entry }
            tp^.ival.v := ti; { place result }
            tp^.ival.s := ts

         end else if tp^.t = trcst then begin 

            { perform constant real negate }
            trl := -tp^.rval; { find negated result }
            lsttyp(tp, trcst); { get a new integer entry }
            tp^.rval := trl { place result }

         end

      end

   end;
   chktkm([cor, cxor]); { check possible misspelled tolken }
   while (nxttlk in [cplus, cminus, cor, cxor]) and not fansi do begin

      tk := nxttlk; { save operator tolken }
      rgttyp(tk, tp); { check proper type for operator }
      gettlk; { next }
      { parse right constant factor }
      partrmcon([ctimes, crdiv, cdiv, cmod, cand]+ss, tp1);
      rgttyp(tk, tp1); { check proper type for operator }
      if boolt(tp) or boolt(tp1) then if not typcmp(tp, tp1) then begin

         { if one is boolean, both must be }
         perror(etypcmp, [], []); { types not compatible }
         tp := gbludf { set result undefined }

      end;
      { perform real valued operations }
      if realt(tp) or realt(tp1) then begin { result is real }

         trr := 1; { set default results }
         trl := 1;
         { find real left }
         if tp^.t = ticst then begin

            trl := tp^.ival.v; { find value }
            if tp^.ival.s then trl := trl*(-1) { find sign }

         end else if tp^.t = trcst then trl := tp^.rval;
         { find real right }
         if tp1^.t = ticst then begin

            trr := tp1^.ival.v; { find value }
            if tp^.ival.s then trr := trr*(-1) { find sign }

         end else if tp1^.t = trcst then trr := tp1^.rval;
         lsttyp(tp, trcst); { get a new real entry }
         { perform operation }
         case tk of { operator }

            cplus:  trl := trl+trr;
            cminus: trl := trl-trr;
            cor:    ; { not valid }
            cxor:

         end;
         lsttyp(tp, trcst); { get a new real entry }
         tp^.rval := trl { place result }

      end else if (boolt(tp) and (tp^.t = tenme)) and
                  (boolt(tp1) and (tp1^.t = tenme)) and 
                  ((tk = cor) or (tk = cxor)) then begin

         if tk = cor then begin { process boolean 'or' }

            if (consti(tp) <> 0) or (consti(tp1) <> 0) then 
               tp := gbltrue else tp := gblfalse { set result value }

         end else { process boolean 'xor' }
            if consti(tp) xor consti(tp1) <> 0 then
               tp := gbltrue else tp := gblfalse { set result value }
         
      end else if (tp^.t = ticst) and (tp1^.t = ticst) then begin

         { perform integer operations }
         case tk of { operator }

            cplus:  begin { find add }
            
               { perform overflow check. overflow will only occur if the
                 operands are the same sign }
               if tp^.ival.s = tp1^.ival.s then begin

                  if maxint-tp^.ival.v < tp1^.ival.v then begin

                     { operation overflows }
                     perror(ecstopv, [], []); { constant operation overflow }
                     ti := 0 { force result to zero }

                  end else begin { find add }

                     ti := ssadd(tp^.ival.s, tp^.ival.v, 
                                 tp1^.ival.s, tp1^.ival.v); { value }
                     ts := ssadds(tp^.ival.s, tp^.ival.v, 
                                  tp1^.ival.s, tp1^.ival.v) { sign }

                  end

               end else begin

                  { value }
                  ti := ssadd(tp^.ival.s, tp^.ival.v, tp1^.ival.s, tp1^.ival.v);
                  { sign }
                  ts := ssadds(tp^.ival.s, tp^.ival.v, tp1^.ival.s, tp1^.ival.v)

               end

            end;
            cminus: begin { find subtract }

               { perform overflow check. overflow will only occur if the
                 operands are the opposite sign }
               if tp^.ival.s <> tp1^.ival.s then begin

                  if maxint-tp^.ival.v < tp1^.ival.v then begin

                     { operation overflows }
                     perror(ecstopv, [], []); { constant operation overflow }
                     ti := 0 { force result to zero }

                  end else begin

                     ti := ssadd(tp^.ival.s, tp^.ival.v, 
                                 not tp1^.ival.s, tp1^.ival.v); { value }
                     ts := ssadds(tp^.ival.s, tp^.ival.v, 
                                  not tp1^.ival.s, tp1^.ival.v) { sign }

                  end

               end else begin
 
                  ti := ssadd(tp^.ival.s, tp^.ival.v, 
                              not tp1^.ival.s, tp1^.ival.v); { value }
                  ts := ssadds(tp^.ival.s, tp^.ival.v, 
                               not tp1^.ival.s, tp1^.ival.v) { sign }

               end

            end;
            cor:    if tp^.ival.s or tp1^.ival.s then
                       { cannot 'or' negative operands }
                       perror(ebolneg, [], []) { boolean negative }
                    else ti := tp^.ival.v or tp1^.ival.v;
            cxor:   if tp^.ival.s or tp1^.ival.s then
                       { cannot 'xor' negative operands }
                       perror(ebolneg, [], []) { boolean negative }
                    else ti := tp^.ival.v xor tp1^.ival.v { find integer 'xor' }

         end;
         lsttyp(tp, ticst); { get a new integer entry }
         tp^.ival.v := ti; { place result value }
         tp^.ival.s := ts { place result sign }

      end;
      { if either operand is undefined, then the result is undefined }
      if (tp^.t = tudf) or (tp1^.t = tudf) then tp := gbludf

   end

end;

{*******************************************************************************

Parse structured constant

   stconst = arrconst | recconst | const

   arrconst = 'array' const [',' const].. 'end'

   recconst = 'record' const [',' const].. 'end'

Parse and generate a structured constant. Accepts a tolken skip set, and the
type of the constant, which can be structured. Returns the type entry for the
constant, which can be a simple or structured entry constant. The constant
being built is matched against the target type as it is being built, so that
we can output errors in their context.

*******************************************************************************}

procedure parstconst(    ss: tolkset; { skip set }
                         mt: typptr;  { match type }
                     var tp: typptr); { return type }

var tp1, tp2: typptr;  { type pointers }
    tl:       typptr;  { last entry pointer }
    last:     tolken;  { parse aid }
    bt:       typptr;  { base type }
    elc:      integer; { array element count }
    sle:      boolean; { structure length error registered }
    fl, fl1:  typptr;  { field list pointers }
    tv:       integer; { tagfield value holder }
    ts:       boolean; { tagfield sign holder }

begin

   if fparse then writeln(':structured constant');
   sle := false; { set no structure length error }
   elc := 0; { clear element length }
   chktkmp(nxtlab, [carray, crecord]); { check possible tolken misspell }
   if nxttlk = carray then begin { parse array..end structure }

      gettlk; { skip 'array' }
      { check type compares with form }
      if (mt^.t <> tarray) and (mt^.t <> tudf) then perror(estccmp, [], []);
      { check array type }
      if mt^.t = tarray then begin 

         bt := mt^.arrt; { set base type } 
         elc := ubound(mt^.arri)-lbound(mt^.arri)+1 { set element count }

      end else begin

         bt := gbludf; { set undefined }
         { well, it isn't an array. therefore is isn't going to have a known
           length either. suppress length errors }
         sle := true { set error occurred }

      end;
      lsttyp(tp, tarrcst); { get an array constant head }
      tp^.arcn := nil; { clear list }
      tl := nil; { clear last }
      repeat { parse elements }

         if elc = 0 then begin { out of elements }

            if not sle then { no previous error }
               perror(estelen, [], []); { structured length does not match }
            sle := true { set error occured }

         end;
         parstconst([ccma, cend]+ss, bt, tp1); { parse element }
         { if an error occured in the last element, leave the rest unmatched }
         if tp1^.t = tudf then bt := gbludf;
         lsttyp(tp2, tarrcel); { get an element entry }
         tp2^.aren := nil; { clear next }
         tp2^.arec := tp1; { link to subconstant }
         if tl <> nil then tl^.aren := tp2 { if last exists, place in list }
         else tp^.arcn := tp2; { else place as head entry }
         tl := tp2; { set new last }
         if elc <> 0 then elc := elc-1; { count elements }
         if (nxttlk <> ccma) and (nxttlk <> cend) then
            { we don't have an exit tolken }
            perror(ecmedexp, [ccma, cend]+constset+ss, [cend]);
         last := nxttlk; { save tolken }
         if last = ccma then gettlk { skip ',' }
         
      { until not ',' or likely constant type }
      until not (last in [ccma, carray, crecord]+constset);
      if nxttlk = cend then gettlk; { skip 'end' }
      if elc <> 0 then { elements left over }
         if not sle then { no previous error }
            perror(estelen, [], []) { structured length does not match }
      
   end else if nxttlk = crecord then begin { parse record..end structure }

      gettlk; { skip 'record' }
      { check type compares with form }
      if (mt^.t <> trecord) and (mt^.t <> tudf) then perror(estccmp, [], []);
      { set base type }
      if mt^.t = trecord then fl := mt^.recf 
      else begin

         fl := nil; { set no list defined }
         { well, it isn't a record. therefore is isn't going to have a known
           length either. suppress length errors }
         sle := true { set error occurred }

      end;
      lsttyp(tp, treccst); { get a record constant head }
      tp^.recn := nil; { clear list }
      tl := nil; { clear last }
      repeat { parse elements }

         if fl = nil then begin { out of elements }

            if not sle then { no previous error }
               perror(estelen, [], []); { structured length does not match }
            sle := true { set error occured }

         end;
         if fl <> nil then { field exists }
            parstconst([ccma, cend]+ss, fl^.fldt, tp1) { parse element }
         else { no field exists }
            parstconst([ccma, cend]+ss, gbludf, tp1); { parse element }
         { if an error occured in the last element, leave the rest unmatched }
         if tp1^.t = tudf then fl := nil;
         lsttyp(tp2, treccel); { get an element entry }
         tp2^.reen := nil; { clear next }
         tp2^.reec := tp1; { link to subconstant }
         if tl <> nil then tl^.reen := tp2 { if last exists, place in list }
         else tp^.recn := tp2; { else place as head entry }
         tl := tp2; { set new last }
         if fl <> nil then { find next }
            if fl^.t = tfield then fl := fl^.fldn
            else if fl^.t = tftag then begin { tagfield }

            { it's a tagfield. Now we must find the proper case field list
              based on the tagfield constant }
            if not (tp1^.t in [ticst, tscst, tccst, tenme, tsub, tudf]) or
               ((tp1^.t = tscst) and not chart(tp1)) then begin

               perror(etagord, [], []); { tag must be ordinal }
               tp1 := gbludf { set undefined }

            end;
            if tp1^.t <> tudf then begin { tag defined, look it up }

               tv := consti(tp1); { find tagfield value }
               ts := constis(tp1); { find tagfield sign }
               fl := fl^.ftgc; { index 1st case }
               fl1 := nil; { set no found case }
               while fl <> nil do begin { search }

                  if ssleq(fl^.fcss, ts, tv) and ssgeq(fl^.fcse, ts, tv) then
                     begin

                     { found }
                     fl1 := fl; { set found pointer }
                     fl := nil { terminate search }

                  end else fl := fl^.fcsn { index next case entry }
                  
               end;
               fl := fl1; { set found case }
               if fl <> nil then { a case was found }
                  fl := fl^.fcsf { index 1st entry in cased field list }
               else begin { process match error }

                  perror(ecasmat, [], []);
                  sle := true { set error occurred }

               end

            end else begin

               { the tagfield is undefined. now we have nowhere to go, because
                 the list length is also unknown. so we drop the list and
                 suppress errors }
               fl := nil; { clear list }
               sle := true { set supress }

            end

         end;
         if (nxttlk <> ccma) and (nxttlk <> cend) then
            { we don't have an exit tolken }
            perror(ecmedexp, [ccma, cend]+constset+ss, []);
         last := nxttlk; { save tolken }
         if last = ccma then gettlk { skip ',' }
         
      { until not ',' or likely constant type }
      until not (last in [ccma, carray, crecord]+constset);
      if nxttlk = cend then gettlk; { skip 'end' }
      if fl <> nil then { elements left over }
         if not sle then { no previous error }
            perror(estelen, [], []) { structured length does not match }

   end else begin

      parconst(ss, tp); { parse ordinary constant }
      if not typcmpa(mt, tp) then begin

         perror(estccmp, [], []); { types not compatible }
         tp := gbludf { set undefined }

      end

   end

end;

{*******************************************************************************

Parse variable

   variable = ident [ '['expr [,expr].. ']' | '.'ident | '^' ]..

Parse and generate variable reference. Accepts a tolken skip set. Expects the
leading identifier to have already been parsed. This is to allow the caller to
look ahead by a symbol, which is required to parse parts of the syntax
unambiguously (like x := y (assignment) vs. x (procedure)). 

Error recovery:

1. Missing ',' in array series, based on the next tolken being
and expression begin.

2. Exteraneous before following ',', ']', '[', '.', '^'. 

3. Missing ']' (by fall through).

4. Missing ident after '.'.

Generates intermediate to place an address as top of stack that indexes the
variable or part thereof (if a structure or pointer). An address indirect
load must be generated to get the actual value.

*******************************************************************************}

procedure parvar(    ss:  tolkset; { skip set }
                     sp:  symptr;  { head symbol entry (used for errors only) }
                     vp:  boolean; { process as variable parameter }
                 var tp:  typptr;  { head type and resulting type }
                 var err: errcod); { last var mode error }
                 

var fs:  symptr;  { found symbol in record search }
    tp1: typptr;  { type pointer }
    ti:  integer; { temp integer holder }
    ts:  boolean; { temp sign holder }
    vt:  typptr;  { variable entry holder }
    csr: boolean; { is a class self reference }
    wtr: boolean; { is a 'with' class reference }

begin

   if fparse then writeln(':variable');
   { first, perform processing on the head identifier }
   err := enull; { set no var mode error }
   tp := actt(tp); { find actual type }
   if not (tp^.t in [tudf, tvar, tfix, tpar, tvpar, twpar, tfield, tftag]) and
      (sp <> nil) then begin

      { wrong type of head }
      perror(evartex, [], [], sp^.lab^); { variable type expected }
      tp := gbludf { if the head is wrong, it follows the rest will be wrong
                     also, so set undefined }

   end;
   { check access to class member outside current }
   wtr := chkwth(tp); { save 'with' class reference status }
   if tp^.classt <> nil then
      if not chkbas(tp, curcls) and not wtr then perror(edircls, [], []);
   vt := tp; { save variable entry }
   { link type of variable }
   case tp^.t of { type }

      tudf:   ; { undefined }
      tvar:   tp := actt(tp^.vart); { common variable }
      tfix:   tp := actt(tp^.fixt); { common variable }
      tpar:   tp := actt(tp^.part); { value parameter }
      tvpar:  tp := actt(tp^.vprt); { variable parameter }
      twpar:  tp := actt(tp^.wprt); { view parameter }
      tfield: tp := actt(tp^.fldt); { record field }
      tftag:  tp := actt(tp^.ftgt)  { tag field }
 
   end;
   if vt^.t = tvar then begin { is a variable }

      if vt^.varm then begin { is an object member }

         if wtr then begin

            { its a class member via a 'with', output an address load that 
              implicates the 'with' }
            wrtcod(ilodawc); { load address of 'with' class member }
            wrtlnk(vt^.classt); { output class type }
            wrtlnk(vt) { output member }

         end else begin { common class member reference }

            { For automatic class variables, we need to generate a load of self
              reference, followed by a object member offset. This means every
              class member reference that is implied is made explicit, like:
           
                 a := b
              
              becomes:
           
                 self.a := self.b
           
            }
            wrtcod(ilodasr); { load class self reference }
            case curcls^.t of { class }
           
               { pick up self reference variable }
               tclass:  wrtlnk(curcls^.clsr); { class }
               tatom:   wrtlnk(curcls^.atmr); { atom }
               tthread: wrtlnk(curcls^.thdr); { thread }
           
            end;
            wrtcod(iobjmem); { output object member offset }
            wrtlnk(curcls); { output class type }
            wrtlnk(vt) { output member }

         end
      
      end else begin { common references }
      
         { check class self reference }
         csr := false; { set not }
         if curcls <> nil then case curcls^.t of { class }
        
            { pick up self reference variable }
            tclass:  csr := vt = curcls^.clsr; { class }
            tatom:   csr := vt = curcls^.atmr; { atom }
            tthread: csr := vt = curcls^.thdr; { thread }
        
         end;
         { load variable address }
         if csr then wrtcod(ilodasr) { its a class self reference, use special load
                                       to mark }
         else wrtcod(ilodadr); { output address load operator }
         wrtlnk(vt) { output entry to load }

      end

   end else begin { non-variable references like record field }   
   
      wrtcod(ilodadr); { output address load operator }
      wrtlnk(vt) { output entry to load }

   end;
   { if it is a variable parameter, must pick up the address itself }
   if vt^.t = tvpar then begin

      if tp^.t = tgarry then begin { general array }

         if tp^.gart^.t = tgarry then { is complex }
            wrtcod(ildimgp) { load indirect complex tagged pointer }
         else 
            wrtcod(ilditgp) { load indirect simple tagged pointer }

      end else wrtcod(ildiptr); { load indirect pointer }

   end else if vt^.t = twpar then begin { view parameter }

      { view parameters will be addressed if structured, else stacked }
      if tp^.t in [trecord, tarray] then
         wrtcod(ildiptr) { load indirect pointer }
      else if tp^.t = tgarry then begin

         if tp^.gart^.t = tgarry then { is complex }
            wrtcod(ildimgp) { load indirect complex tagged pointer }
         else 
            wrtcod(ilditgp) { load indirect simple tagged pointer }

      end

   end else if vt^.t = tpar then begin

      { If it is a value parameter, and its a general array, it is treated as
        a variable parameter. This is because it was copied to the stack and is
        represented on the parameter list as a pointer. }
      if tp^.t = tgarry then begin { general array }

         if tp^.gart^.t = tgarry then { is complex }
            wrtcod(ildimgp) { load indirect complex tagged pointer }
         else 
            wrtcod(ilditgp) { load indirect simple tagged pointer }

      end

   end;
   { now, process following qualifiers and operators, '[', '.', and '^' }
   while nxttlk in [clbrkt, cperiod, ccmf] do begin
   
      if nxttlk = clbrkt then begin { array index }
   
         { cannot pass packed component as variable parameter }
         if tp^.pack then begin

            err := epakvar; { set last var mode error }
            if vp then perror(epakvar, [], [])

         end;
         repeat { indecies }
   
            if not (tp^.t in [tarray, tgarry, tudf]) then begin { wrong type }
   
               perror(earrtex, [], []);  { must be array type }
               tp := gbludf { set result undefined }
   
            end;
            { don't skip over the start of a recovered expression }
            if (nxttlk = clbrkt) or (nxttlk = ccma) then 
               gettlk; { skip '[' or ',' }
            parexpr(nil, [ccma, crbrkt]+ss, tp1); { parse expression }
            { check index type compatible }
            if tp^.t = tarray then begin { is an array }
   
               if not typcmpa(tp^.arri, tp1) then begin
   
                  perror(eidxtyp, [], []); { index type not compatible }
                  tp := gbludf { set result undefined }
   
               end else begin
   
                  if tp1^.t in [ticst, tscst, tccst, tenme] then begin
   
                     { index is constant, check for bounds }
                     ti := consti(tp1); { get index value }
                     ts := constis(tp1); { get index sign }
                     if ssgtn(lbounds(tp^.arri), lbound(tp^.arri), ts, ti) or 
                        ssgtn(ts, ti, ubounds(tp^.arri), ubound(tp^.arri)) then
                        perror(earrbnd, [], []) { array reference bounds }
   
                  end;  
                  { if the index is a single character string constant, then it
                    must be loaded from the address }
                  if tp1^.t = tscst then wrtcod(ildichr);
                  wrtcod(iarrref); { output array offset operator }
                  wrtlnk(tp); { output address of array entry }
                  tp := actt(tp^.arrt) { index array component type }
   
               end
   
            end else if tp^.t = tgarry then begin { is a general array }

               if not intt(tp1) and (tp1^.t <> tudf) then begin

                  perror(eidxtyp, [], []); { index type not compatible }
                  tp := gbludf { set result undefined }
      
               end else begin { process index }

                  { if index is constant, check valid }
                  if tp1^.t = ticst then 
                     if ssgtn(false, 1, constis(tp1), consti(tp1)) then
                        perror(earrbnd, [], []); { array reference bounds }
                  if tp^.gart^.t = tgarry then begin { is complex }

                     wrtcod(iarfmar); { output complex array offset operator }
                     wrtlnk(tp); { output address of array entry }
                     { if indexing into the complex array is going to yeild a
                       simple general array, we need to convert to a standard
                       tagged index. }
                     if tp^.gart^.gart^.t <> tgarry then { going to be simple }
                        wrtcod(icvtmtg) { convert complex to simple pointer }

                  end else begin

                     wrtcod(iarfgar); { output simple array offset operator }
                     wrtlnk(tp) { output address of array entry }

                  end;
                  tp := actt(tp^.gart) { index array component type }

               end

            end;
            if (nxttlk <> ccma) and (nxttlk <> crbrkt) then
               { we don't have an exit tolken }
               perror(erbcmexp, [ccma, crbrkt, clbrkt, cperiod, 
                      ccmf]+exprset+ss, [])
   
         { until not ',', and no expression set }
         until not (nxttlk in [ccma]+exprset);
         if nxttlk = crbrkt then gettlk { skip ']' }
   
      end else if nxttlk = cperiod then begin { record offset }
   
         { cannot pass packed component as variable parameter }
         if tp^.pack then begin

            err := epakvar; { set last var mode error }
            if vp then perror(epakvar, [], [])

         end;
         if not (tp^.t in [trecord, treference, tudf]) then
            begin { wrong type }
   
            if fansi then perror(erectex, [], []) { must be record type }
            else perror(ercrftex, [], []); { must be record or reference type }
            tp := gbludf { set result undefined }
   
         end;
         gettlk; { next }
         if nxttlk <> cidentifier then begin { missing id }

            perror(eidnexp, [clbrkt, cperiod, ccmf]+ss, []);
            tp := gbludf { set the result undefined }

         end else if tp^.t = trecord then begin 

            { search for record scoped symbol }
            sp := tp^.recl; { index top of list }
            fs := nil; { set no entry found }
            while sp <> nil do begin { traverse }
   
               if compp(sp^.lab^, nxtlab) then fs := sp; { if found, place }
               sp := sp^.rnxt { next symbol }
   
            end;
            if fs = nil then begin { not found }
   
               perror(ensftr, [], [], nxtlab); { no such field }
               tp := gbludf { set the result undefined }
   
            end else begin { found }
   
               tp := actt(fs^.typ); { set to field type }
               if (tp^.t <> tfield) and (tp^.t <> tftag) then 
                  error(esflt16, true); { fault on wrong type }
               wrtcod(irecoff); { output record offset operator }
               wrtlnk(tp); { with field or tag field }
               if tp^.t = tfield then tp := actt(tp^.fldt) { link type }
               else begin { tag field }
   
                  { tag cannot be variable parameter }
                  err := etagvar; { set last var mode error }
                  if vp then perror(etagvar, [], []);
                  tp := actt(tp^.ftgt)
   
               end
   
            end
              
         end else if tp^.t = treference then begin

            { its an object reference }
            tp1 := tp; { save base class }
            sp := clsbas(tp1^.reft, nxtlab); { find member in class }
            { reject attempts to access private class members }
            if sp <> nil then if sp^.prv then sp := nil;
            if sp = nil then begin

               perror(ensmtc, [], [], nxtlab); { no such member this class }
               tp := gbludf { set result undefined }

            end else begin { found }

               tp := sp^.typ; { get type }
               { check is a class member at all }
               if tp^.classt = nil then begin

                  perror(enacmem, [], [], nxtlab); { not a class member }
                  tp := gbludf { set result undefined }
                
               end else if not chkbas(tp, tp1^.reft) then begin

                  perror(enmemtc, [], [], nxtlab); { not a member of this class }
                  tp := gbludf { set result undefined }

               end else if not (tp^.t in [tvar, tudf, tproc, tfunc]) then begin

                  perror(ememvar, [], [], nxtlab); { member is not variable access }
                  tp := gbludf { set result undefined }

               end;
               wrtcod(iobjmem); { output record offset operator }
               wrtlnk(tp1); { with class }
               wrtlnk(tp) { with member }

            end

         end;
         if nxttlk = cidentifier then gettlk { next }
   
      end else begin { pointer indirection }
   
         if (tp^.t <> tptr) and not filet(tp) and (tp^.t <> tudf) then begin

            { wrong type }
            perror(eptrtex, [], []); { must be pointer type }
            tp := gbludf { set result undefined }
   
         end;
         gettlk; { skip '^' }
         if tp^.t = tptr then begin { pointer type }

            tp1 := actt(tp^.ptrt); { get base type }
            if tp1^.t = tgarry then begin

               if tp1^.gart^.t = tgarry then { is complex }
                  wrtcod(ildimgp) { load indirect complex tagged pointer }
               else 
                  wrtcod(ilditgp) { load indirect simple tagged pointer }

            end else wrtcod(ildiptr); { load indirect pointer }
            tp := tp1 { index type pointed to }

         end else if filet(tp) then begin { file type }

            { output load address of buffer }
            if tp^.t = ttext then wrtcod(ilodafbuft)
            else wrtcod(ilodafbuf);
            if tp^.t = tfile then tp := tp^.filt { index buffer type }
            else tp := gblchr

         end
   
      end
   
   end

end;

{*******************************************************************************

Parse variable leader

Parses a variable leader tolken. This can be either an identifier, or a 'self'
class reference. Returns the symbol and the type. If it's a 'self' reference,
then the symbol is returned using the special 'self' symbol, which is used for
error printouts.

*******************************************************************************}

procedure parvarlead(    ss: tolkset; { skip set }
                     var sp: symptr;  { return symbol }
                     var tp: typptr); { return type }

var lab: labl;    { label for undefines }

begin

   if fparse then writeln(':variable leader');
   tp := gbludf; { set result undefined }
   sp := nil; { set no head symbol }
   if nxttlk = cidentifier then begin { id found }

      { Parse qualified identifier WITHOUT reference grace, which we will
        process as a true reference. }
      parqualident(ss, false, true, false, '', sp, lab);
      tp := sp^.typ; { set head type }

   end else if nxttlk = cself then begin { class self reference }

      if curcls = nil then perror(eclsact, [], [])
      else begin

         case curcls^.t of { class }

            { pick up self reference variable }
            tclass:  tp := curcls^.clsr; { class }
            tatom:   tp := curcls^.atmr; { atom }
            tthread: tp := curcls^.thdr; { thread }

         end;
         sp := selflab { set label for errors }

      end;
      gettlk { skip 'self' }
   
   end

end;   

{*******************************************************************************

Parse variable with head

Parses a variable, with the head. This is used only in the case where we know
a variable is to be parsed beforehand.

*******************************************************************************}

procedure parvarh(    ss:     tolkset; { skip set }
                      threat: boolean; { "threat" access status }
                      vp:     boolean; { process as variable parameter }
                  var tp:     typptr;  { return type }
                  var verr:   errcod); { last var mode error }

var sp: symptr; { symbol pointer }

begin

   if fparse then writeln(':variable with head');
   tp := gbludf; { set result undefined }
   sp := nil; { set no head symbol }
   { parse variable head }
   if (nxttlk <> cidentifier) and (nxttlk <> cself) then 
      { id or 'self' expected }
      if fansi then 
         perror(evidexp, [cidentifier, cperiod, ccmf, clbrkt]+ss, [])
      else
         perror(evidsexp, [cidentifier, cperiod, ccmf, clbrkt]+ss, []);
   if nxttlk in [cidentifier, cself, cperiod, ccmf, clbrkt] then begin 

      { found, or likely start found }
      parvarlead(ss, sp, tp); { parse leader }
      { check access is threatening, and variable is threat candidate }
      if threat and (sp <> nil) then threaten(sp, tp);
      parvar(ss, sp, vp, tp, verr) { parse variable reference }

   end

end;   

{*******************************************************************************

Parse factor

   factor = unsigned constant | variable | procedure/function |
            '(' expr ')' | 'not' factor | '[]' |
            '[' srange [ , srange ].. ']'

   srange = expr | expr '..' expr   

Parse and generate a factor. Accepts a tolken skip set.
Error recovery:

1. Missing ')' on expression, skips to whatever follows.

2. Missign ',' on set elements, based on the next tolken being
and expression start.

3. Missing ']' on set elements.

4. '..' in set element without a leading expr.

5. No factor at all, skip to whatever follows.

Generates intermediate to place a single value as top of stack. Simple atoms
are loaded as integers, reals as reals, and any structures are passed as
addresses.

Accepts a variable reference leader. This is a parsed result type from parvarh.
If it is not nil, then the left hand part of expressions is skipped, and the
variable reference substitutes for it. This is because of a requirement in the
parsing of overload parameters that we must be able to continue after parsing
only the variable reference leader.
             
*******************************************************************************}

procedure parfactor(    varref: typptr;  { variable reference leader }
                        ss:     tolkset; { skip set }
                    var tp:     typptr); { return type }

var last:   tolken;  { parsing aid }
    sp:     symptr;  { symbol pointer } 
    tp1:    typptr;  { type pointers }
    lt:     typptr;  { last type }
    lts:    boolean; { last type exists flag }
    bt:     typptr;  { base type }
    ti:     integer; { temp integer result }
    si:     labinx;  { string index }
    err:    errcod;  { last var mode error (unused) }
    inhatt: boolean; { inherited attribute }

begin

   if fparse then writeln(':factor');
   tp := gbludf; { default to undefined result }
   if varref <> nil then begin { a variable reference leader exists }

      tp := varref; { start with previous reference }
      bt := baset(tp); { find base type }
      { check is simple, or loadable quanta }
      if bt^.t in [tinteger, tlinteger, tcardinal, tlcardinal, treal, tsreal,
                   tchar, tboolean, tptr, tsub, tenum, tset, treference] then 
         { perform load }
         if bt^.t = treal then 
            wrtcod(ildirel) { load indirect real }
         else if bt^.t = tsreal then 
            wrtcod(ildisrl) { load indirect short real }
         else if bt^.t = tset then wrtcod(ildiset) { load set }
         else if bt^.t = tchar then wrtcod(ildichr) { load character }
         else if bt^.t = tboolean then wrtcod(ildibol) { load boolean }
         else if bt^.t = tptr then begin { pointer types }

            if bt^.ptrt^.t = tgarry then { general array pointer }
               wrtcod(ilditgp) { load tagged pointer }
            else wrtcod(ildiptr) { load indirect pointer }

         end else if bt^.t = treference then wrtcod(ildiref) { load reference }
         else begin { must be ordinal }

            wrtcod(ildiint); { load indirect integer }
            wrtlnk(tp) { output variable type }

         end

   end else begin { process normal factor }

      { see if we have any head tolken }
      if not (nxttlk in [cidentifier, cinherited, cself, cinteger, creal, cnil,
                         cstring, clparen, cnot, clbrkt]) then 
         perror(einvfact, [cidentifier, cinherited, cinteger, creal, cnil,
                cstring, clparen, cnot, clbrkt]+ss, []);
      chktkmp(nxtlab, [cnil, cnot]); { check possible tolken misspell }
      if nxttlk in [cidentifier, cinherited, cself] then begin
      
         inhatt := false; { set no inherited attribute }
         if nxttlk = cinherited then begin { inherited attribute }

            gettlk; { skip "inherited" }
            inhatt := true;
            if nxttlk <> cidentifier then 
               perror(eidnexp, [cidentifier, cinteger, creal, cnil,
                                cstring, clparen, cnot, clbrkt]+ss, [])

         end;
         parvarlead([cidentifier, cinteger, creal, cnil, cstring, clparen, cnot,
                     clbrkt]+ss, sp, tp1); { parse variable leader }
         { check any possible sign of function, '(', function type, type 
           converter, or even a procedure type, which may have been mistakenly
           used here }
         if (nxttlk = clparen) or 
            { check procedure, function, overload or method }
            (tp1^.t in [tfunc, tpfunc, tproc, tpproc]) or chkovld(tp1) or
            ((tp1^.t in [tenum, tsub]) and not fansi) then begin
   
            { check function label }
            if (tp1^.t <> tfunc) and (tp1^.t <> tpfunc) and not chkovld(tp1) and
               not ((tp1^.t in [tenum, tsub]) and not fansi) and (sp <> nil) then
               begin
   
               if fansi then 
                  perror(embfunc, [], [], sp^.lab^) { must be function }
               else perror(embfnty, [], [], sp^.lab^) { must be function }
   
            end;
            if (tp1^.t in [tenum, tsub]) and not fansi then begin 
   
               { enumerated type converter }
               if inhatt then 
                  perror(einhmbpfc, [], []); { bad use of 'inherited' }
               expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
               parexpr(nil, [crparen]+ss, tp); { parse parameter }
               { check integer }
               if not (intt(tp) or (tp^.t = tudf)) then 
                  perror(embint, [], []); { must be integer }
               expect(crparen, erpexp, ss, []); { expect ')' }
               if tp^.t = ticst then begin { operand is integer constant }
   
                  { it's constant, we can find the corresponding enumerated
                    value right here }
                  if ssgtn(lbounds(tp1), lbound(tp1), tp^.ival) or
                     ssgtn(tp^.ival, ubounds(tp1), ubound(tp1)) then
                     perror(erange, [], []); { range check }
                  if tp1^.t = tenum then begin { enumerated }
   
                     tp1 := tp1^.enc; { find matching entry }
                     { Note that the value must be unsigned here, since we 
                       validated it to be in the range of an unsigned 
                       enumeration }
                     while (tp1^.env <> tp^.ival.v) and (tp1 <> nil) do 
                        tp1 := tp1^.enx; { next entry }
                     if tp1 = nil then 
                        tp1 := gbludf { not found, set undefined }
   
                  end
             
               end;
               tp := tp1; { set type now is enumerated }
               wrtcod(irngchk); { output range check }
               wrtlnk(tp); { output check type }
   
            end else
               { parse function call }
               parprcfnci(false, ss, inhatt, true, sp^.typ, tp)
   
         end else if tp1^.t in [ticst, tscst, tccst, trcst, tstcst, tenme] then
            begin
   
            { it's a predefined constant }
            if inhatt then perror(einhmbpfc, [], []); { bad use of 'inherited' }
            tp := tp1; { set return type to same }
            if tp^.t = tscst then begin
   
               { multiple character, output as address load }
               wrtcod(ilodadr); { output load address operator }
               wrtlnk(tp) { output entry to load }
   
            end else if tp^.t = tstcst then begin
   
               { constant set }
               wrtcod(ilodadr); { output load address operator }
               wrtlnk(tp); { output entry to load }
               wrtcod(ildiset) { load set }
   
            end else if tp^.t = trcst then begin { real constant }
   
               wrtcod(ilimrel); { output load immediate real operator }
               wrtreal(tp^.rval) { output value }
   
            end else begin { output as value load }
   
               wrtcod(ilimint); { output load immediate integer operator }
               wrtnum(constis(tp), consti(tp)) { output value }
   
            end
   
         end else begin { parse variable }
   
            tp := tp1; { set head type }
            parvar(ss, sp, false, tp, err); { parse variable }
            if tp^.t = tfunc then
               { its a method, parse procedure call }
               parprcfnci(false, ss, inhatt, false, tp, tp)
            else begin

               { check inherited attribute is set }
               if inhatt then 
                  perror(einhmbpfc, [], []); { bad use of 'inherited' }
               bt := baset(tp); { find base type }
               { check is simple, or loadable quanta }
               if bt^.t in [tinteger, tlinteger, tcardinal, tlcardinal, treal,
                            tsreal, tchar, tboolean, tptr, tsub, tenum, tset,
                            treference] then
                  { perform load }
                  if bt^.t = treal then 
                     wrtcod(ildirel) { load indirect real }
                  else if bt^.t = tsreal then 
                     wrtcod(ildisrl) { load indirect short real }
                  else if bt^.t = tset then wrtcod(ildiset) { load set }
                  else if bt^.t = tchar then wrtcod(ildichr) { load character }
                  else if bt^.t = tboolean then wrtcod(ildibol) { load boolean }
                  else if bt^.t = tptr then begin { pointer types }
              
                     if bt^.ptrt^.t = tgarry then begin 

                        { general array pointer }
                        if bt^.ptrt^.gart^.t = tgarry then { is complex }
                           { load indirect complex tagged pointer }
                           wrtcod(ildimgp)
                        else 
                           { load indirect simple tagged pointer }
                           wrtcod(ilditgp)

                     end else wrtcod(ildiptr) { load indirect pointer }
              
                  end else if bt^.t = treference then 
                     wrtcod(ildiref) { load reference }
                  else begin { must be ordinal }
              
                     wrtcod(ildiint); { load indirect integer }
                     wrtlnk(tp) { output variable type }
              
                  end

            end
   
         end
   
      end else if nxttlk = cinteger then begin { unsigned number }
   
         lsttyp(tp, ticst); { get an integer constant type entry }
         tp^.ival.v := nxtint; { place integer }
         tp^.ival.s := false; { set unsigned }
         gettlk; { skip integer }
         wrtcod(ilimint); { output load immediate integer operator }
         wrtnum(tp^.ival.s, tp^.ival.v) { output value }
   
      end else if nxttlk = creal then begin { unsigned real }
   
         lsttyp(tp, trcst); { get a real constant type entry }
         tp^.rval := nxtflt; { place real }
         gettlk; { skip real }
         wrtcod(ilimrel); { output load immediate real operator }
         wrtreal(tp^.rval) { output value }
   
      end else if nxttlk = cnil then begin { 'nil' }
   
         tp := gblnil; { set to universal nil entry }
         gettlk; { skip 'nil' }
         wrtcod(ilimint); { output load immediate integer operator }
         wrtnum(false, 0) { of zero }
         
      end else if nxttlk = cstring then begin { string }
   
         lsttyp(tp, tscst); { get a string constant type entry }
         new(tp^.sval, nxtlen); { create string entry }
         { copy contents into place }
         for si := 1 to nxtlen do tp^.sval^[si] := nxtlab[si];
         if uselvl = 0 then { not in uses file }
            wrttyp; { make sure that is written immediately }
         gettlk; { skip string }
         wrtcod(ilodadr); { output load address operator }
         wrtlnk(tp) { output entry to load }
   
      end else if nxttlk = clparen then begin { (expr) }
   
         gettlk; { next }
         parexpr(nil, [crparen]+ss, tp); { parse expression }
         expect(crparen, erpexp, [crparen]+ss, []) { expect ')' }
   
      end else if nxttlk = cnot then begin { 'not' }
   
         gettlk; { next }
         parfactor(nil, ss, tp); { parse factor }
         { check boolean or integer type }
         if not (boolt(tp) or (intt(tp) and not fansi) or (tp^.t = tudf)) then 
            if fansi then perror(etmbbol, [], []) { output ansi message }
            else perror(etmbboi, [], []); { output extended message }
         if boolt(tp) and (tp^.t = tenme) then 
            begin { resolve boolean constant }
   
            { find opposite of truth }
            if consti(tp) = 0 then tp := gbltrue else tp := gblfalse;
   
         end else if tp^.t = ticst then begin { resolve integer constant }
   
            if tp^.ival.s then perror(ebolneg, [], []) { boolean on negative }
            else begin { solve }
   
               { perform constant integer not }
               ti := not tp^.ival.v; { find 'not' result }
               lsttyp(tp, ticst); { get a new integer entry }
               tp^.ival.v := ti; { place result }
               tp^.ival.s := false { set unsigned }
   
            end
   
         end;
         if boolt(tp) then wrtcod(inotbol) { output boolean 'not' operator }
         else wrtcod(inotint) { output integer 'not' operator }
   
      end else if nxttlk = clbrkt then begin { set construction }
   
         gettlk; { next }
         lt := gbludf; { set last type parsed null }
         lts := false; { set no last type parsed }
         { to build a set, we start by loading a nil set onto the stack,
           which will be all that is used if there are no set builders.
           Then, set elements are added to the empty set by setting
           individual values or ranges onto the set }
         wrtcod(ilimns); { output load nil set operator }
         if nxttlk <> crbrkt then repeat { set elements }
   
            parexpr(nil, [crbrkt, crange, ccma]+ss, tp); { parse expression }
            { if the object is a string constant, this must be a character, so
              load it from the address }
            if tp^.t = tscst then wrtcod(ildichr);
            tp1 := baset(tp); { get base type }
            if chart(tp1) then tp1 := gblchr; { convert character type }
            if not (tp1^.t in [tudf, tinteger, tlinteger, tcardinal, tlcardinal,
                               tenum, tboolean, tchar]) then begin
   
               perror(einvstb, [], []); { not a valid set builder }
               tp1 := gbludf { set undefined }
   
            end;
            { check types of contructors match }
            if not typcmp(tp1, lt) then begin { no match }
   
               perror(escncmp, [], []); { type mismatch }
               tp1 := gbludf { set undefined }
   
            end;
            { if the last type was not undefined, which would cause the entire
              result to be undefined }
            if not (lts and (lt^.t = tudf)) then lt := tp1; { set last type }
            lts := true; { set last type exists }
            if nxttlk = crange then begin
   
               gettlk; { next }
               parexpr(nil, [ccma, crbrkt, crange]+ss, tp); { parexpr }
               { if the object is a string constant, this must be a character, 
                 so load it from the address }
               if tp^.t = tscst then wrtcod(ildichr);
               tp1 := baset(tp); { get base type }
               if chart(tp1) then tp1 := gblchr; { convert character type }
               if not (tp1^.t in [tudf, tinteger, tlinteger, tcardinal,
                                  tlcardinal, tenum, tboolean, tchar]) then
                  perror(einvstb, [], []); { not a valid set builder }
               { check types of contructors match }
               if not typcmp(tp1, lt) then begin { no match }
   
                  perror(escncmp, [], []); { type mismatch }
                  tp1 := gbludf { set undefined }
   
               end;
               wrtcod(irngset); { output set range operator }
               { if last type was not undefined }
               if lt^.t <> tudf then lt := tp1 { set last type }
   
            end else wrtcod(isinset); { output set single element operator }
            if (nxttlk <> ccma) and (nxttlk <> crbrkt) then
               { we don't have an exit tolken }
               perror(erbcmexp, [ccma, crbrkt, crange]+exprset+ss, []);
            last := nxttlk; { save tolken }
            if nxttlk = ccma then gettlk { next }
   
         { until not ',', and no expression set }
         until not (last in [ccma, crange]+exprset);
         if nxttlk = crbrkt then gettlk; { next }
         if not lts then 
            tp := gbleset { no set members defined, it is the empty set }
         { if constructor(s) undefined, set result undefined }
         else if lt^.t = tudf then tp := gbludf
         else begin { defined }
   
            lsttyp(tp, tset); { get a set type entry }
            tp^.sett := baset(lt); { set base type }
            { built sets are marked specially, because they can become packed
              or unpacked types dependent on context }
            tp^.setc := true; { set is 'in context' }
            if uselvl = 0 then { not in uses file }
               wrttyp { make sure that is written immediately }
   
         end
   
      end else if (nxttlk = cperiod) or (nxttlk = ccmf) then begin
   
         { guesstimate that it could be a variable with missing
           head }
         parvar(ss, nil, false, tp, err); { parse }
         { check is simple, or loadable quanta }
         if tp^.t in [tinteger, tlinteger, tcardinal, tlcardinal, treal, tsreal,
                      tchar, tboolean, tptr, tsub, tenum, tset] then begin
   
            if realt(tp) then wrtcod(ildirel) { load indirect real }
            else if tp^.t = tset then wrtcod(ildiset) { load set }
            else if tp^.t = tptr then wrtcod(ildiptr) { load pointer }
            else begin { ordinal }
   
               wrtcod(ildiint); { load indirect integer }
               wrtlnk(tp) { output variable type }
   
            end
   
         end

      end
   
   end

end;

{*******************************************************************************

Parse term

   term = factor [ '*' factor | '/' factor | 'div' factor |
          'mod' factor | 'and' factor ]..

Parses and generates a term. Accepts a tolken skip set.
Error recovery:

1. Resyncs to any of the middle tolkens. 

Accepts a variable reference leader. This is a parsed result type from parvarh.
If it is not nil, then the left hand part of expressions is skipped, and the
variable reference substitutes for it. This is because of a requirement in the
parsing of overload parameters that we must be able to continue after parsing
only the variable reference leader.

*******************************************************************************}

procedure parterm(    varref: typptr;  { variable reference leader }
                      ss:     tolkset; { skip set }
                  var tp:     typptr); { return type }

var tp1:   typptr;  { type pointer }
    tk:    tolken;  { tolken save }
    ti:    integer; { temp integer result value }
    ts:    boolean; { temp integer result sign }
    tr:    real;    { temp real result }
    trl:   real;    { temp left real holder }
    trr:   real;    { temp right real holder }
    solve: boolean; { solved constant flag }

{ determine type correct for operator }

procedure rgttyp(    tk: tolken;  { operator tolken }
                 var tp: typptr); { type to check }

var m: boolean; { type correct flag }

begin

   case tk of { operator }

      { integer, real or set }
      ctimes:     m := intt(tp) or realt(tp) or sett(tp);
      crdiv:      m := intt(tp) or realt(tp); { integer or real }
      cdiv, cmod: m := intt(tp); { integer }
      cand:       m := boolt(tp) or 
                       (intt(tp) and not fansi) { boolean or integer }

   end;
   if not m and (tp^.t <> tudf) then begin { bad type }

      perror(etypcon, [], []); { type in wrong context }
      tp := gbludf { set result undefined }

   end

end;
   
begin

   parfactor(varref, [ctimes, crdiv, cdiv, cmod, cand]+ss, tp); { parse factor }
   chktkm([cdiv, cmod, cand]); { check possible misspelled tolken }
   while nxttlk in [ctimes, crdiv, cdiv, cmod, cand] do begin

      tk := nxttlk; { save operator tolken }
      rgttyp(tk, tp); { check proper type for operator }
      gettlk; { next }
      parfactor(nil, [ctimes, crdiv, cdiv, cmod, cand]+ss, tp1); { parse factor }
      rgttyp(tk, tp1); { check proper type for operator }
      if sett(tp) or sett(tp1) then if not typcmp(tp, tp1) then begin

         { sets, but not compatible }
         perror(etypcmp, [], []); { types not compatible }
         tp := gbludf { set result undefined }

      end;
      if boolt(tp) or boolt(tp1) then if not typcmp(tp, tp1) then begin

         { if one is boolean, both must be }
         perror(etypcmp, [], []); { types not compatible }
         tp := gbludf { set result undefined }

      end;
      { output any integer to real conversion required }
      if (tk = crdiv) or realt(tp) or realt(tp1) then begin { result is real }

         { if top is integer, convert to real }
         if intt(tp1) then wrtcod(icvtitr);
         if intt(tp) then begin 

            { the second to top is harder, because we must swap to get access }
            wrtcod(iswptop); { output swap first and second operator }
            wrtlnk(baset(tp)); { output sos type }
            wrtlnk(gblreal); { output tos type }
            wrtcod(icvtitr); { convert to real }
            wrtcod(iswptop); { output swap first and second operator }
            wrtlnk(gblreal); { output sos type }
            wrtlnk(gblreal) { output tos type }

         end

      end;
      { output operator by operation type }
      case tk of { operator }

         ctimes: if sett(tp) then wrtcod(iintset) { set intersection }
                 else if realt(tp) or realt(tp1) then 
                    wrtcod(imltrel) { multiply real }
                 else wrtcod(imltint); { multiply integer }
         crdiv:  wrtcod(idivrel); { divide real }
         cdiv:   wrtcod(idivint); { divide integer } 
         cmod:   wrtcod(imodint); { modulo integer }
         cand:   wrtcod(iandint) { 'and' integer }

      end;
      solve := true; { set solved constant }
      if (tp^.t = ticst) and (tp1^.t = ticst) and (tk <> crdiv) then begin 

         { constant integer operation, solve }
         case tk of { operator }

            ctimes: begin { find multiply }

               { check for overflow }
               if tp^.ival.v > maxint div tp1^.ival.v then begin

                  perror(eintovf, [], []); { constant operation overflow }
                  solve := false { so will just become type }

               end else begin { perform multiply }

                  ti := tp^.ival.v*tp1^.ival.v; { value }
                  ts := tp^.ival.s xor tp1^.ival.s { sign }

               end

            end;
            cdiv:   begin { find integer divide }

               if tp1^.ival.v = 0 then begin { flag zero divide }

                  perror(edivzer, [], []); { zero divide }
                  solve := false { so will just become type }

               end else begin { find integer divide }

                  ti := tp^.ival.v div tp1^.ival.v; { value }
                  ts := tp^.ival.s xor tp1^.ival.s { sign }

               end

            end;
            cmod:   begin { find integer modulo }

               if tp1^.ival.v = 0 then begin { flag zero divide }

                  perror(edivzer, [], []); { zero divide }
                  solve := false { so will just become type }

               end else if tp1^.ival.v < 0 then begin { flag negative mod }

                  perror(emodneg, [], []); { modulo by negative }
                  solve := false { so will just become type }

               end else begin { find integer modulo }

                  ti := tp^.ival.v mod tp1^.ival.v; { value }
                  ts := tp^.ival.s xor tp1^.ival.s { sign }

               end

            end;
            cand:   begin { 'and' integers }

               if tp^.ival.s or tp1^.ival.s then begin

                  { cannot 'and' negative operands }
                  perror(ebolneg, [], []); { boolean negative }
                  solve := false { so will just become type }

               end else ti := tp^.ival.v and tp1^.ival.v { find integer 'and' }

            end

         end;
         if solve then begin { was solved }

            lsttyp(tp, ticst); { get a new integer entry }
            tp^.ival.v := ti; { place result value }
            tp^.ival.s := ts { place result sign }

         end
         
      end else if ((tp^.t = ticst) or (tp^.t = trcst)) and 
                  ((tp1^.t = ticst) or (tp1^.t = trcst)) then begin

         { convert left to real }
         if tp^.t = ticst then begin { integer }

            trl := tp^.ival.v; { value }
            if tp^.ival.s then trl := trl*(-1) { sign }

         end else trl := tp^.rval; { real }
         { convert right to real }
         if tp1^.t = ticst then begin { integer }

            trr := tp1^.ival.v; { value }
            if tp1^.ival.s then trr := trr*(-1) { sign }

         end else trr := tp1^.rval; { real }
         { constant real operation, solve }
         case tk of { operator }

            ctimes: tr := trl*trr; { find multiply }
            crdiv:  begin { find real divide }

               if trr = 0.0 then begin { flag zero divide }

                  perror(edivzer, [], []); { zero divide }
                  solve := false { so will just become type }

               end else tr := trl/trr; { find real divide }

            end;
            cdiv, 
            cmod,
            cand:   solve := false; { not valid for real }

         end;
         if solve then begin { was solved }

            lsttyp(tp, trcst); { get a new real entry }
            tp^.rval := tr { place result }

         end
      
      end else if (boolt(tp) and (tp^.t = tenme)) and
                  (boolt(tp1) and (tp1^.t = tenme)) and (tk = cand) then begin

         { process boolean and }
         if (consti(tp) <> 0) and (consti(tp1) <> 0) then 
            tp := gbltrue else tp := gblfalse { set result value }

      end else solve := false; { set not solved constant }
      if not solve then begin { not a solved constant, find result type }
   
         { pick result type }
         if (tp^.t = tudf) or (tp1^.t = tudf) then tp := gbludf { undefined }
         else if realt(tp) or realt(tp1) or (tk = crdiv) then 
            { either is real, or is '/' }
            tp := gblreal { result is real }
         else if intt(tp) then tp := gblint { result is integer }

      end

   end

end;

{*******************************************************************************

Parse simple expression

   sexpr = sterm [ '+' term | '-' term | 'or' term ]..

   sterm = '+' term | '-' term

Parses and generates a term. Accepts a tolken skip set.
Error recovery:

1. Resyncs to any of the middle tolkens. 

Accepts a variable reference leader. This is a parsed result type from parvarh.
If it is not nil, then the left hand part of expressions is skipped, and the
variable reference substitutes for it. This is because of a requirement in the
parsing of overload parameters that we must be able to continue after parsing
only the variable reference leader.

*******************************************************************************}

procedure parsexpr(    varref: typptr;  { variable reference leader }
                       ss:     tolkset; { skip set }
                   var tp:     typptr); { return type }

var tp1:   typptr;  { type pointer }
    tk:    tolken;  { tolken save }
    ti:    integer; { temp integer result value }
    ts:    boolean; { temp integer result sign }
    tr:    real;    { temp real result }
    trl:   real;    { temp left real holder }
    trr:   real;    { temp right real holder }
    solve: boolean; { solved constant flag }

{ determine type correct for operator }

procedure rgttyp(    tk: tolken;  { operator tolken }
                 var tp: typptr); { type to check }

var m: boolean; { type correct flag }

begin

   case tk of { operator }

      { integer, real or set }
      cplus:  m := intt(tp) or realt(tp) or sett(tp); { integer, real or set }
      cminus: m := intt(tp) or realt(tp) or sett(tp); { integer, real or set }
      cor:    m := boolt(tp) or 
                   (intt(tp) and not fansi); { boolean or integer }
      cxor:   m := boolt(tp) or intt(tp) { boolean or integer }

   end;
   if not m and (tp^.t <> tudf) then begin { bad type }

      perror(etypcon, [], []); { type in wrong context }
      tp := gbludf { set result undefined }

   end

end;

begin

   if fparse then writeln(':simple expression');
   tk := nxttlk; { save sign tolken }
   if ((nxttlk = cplus) or (nxttlk = cminus)) and (varref = nil) then { sign }
      gettlk; { skip '+'/'-' }
   parterm(varref, [cplus, cminus, cor, cxor]+ss, tp); { parse term }
   if ((tk = cplus) or (tk = cminus)) and (varref = nil) then begin

      if not (intt(tp) or realt(tp) or (tp^.t = tudf)) then begin

         { wrong type }
         perror(etypcon, [], []); { type in wrong context }
         tp := gbludf { set result undefined }

      end;
      if tk = cminus then begin { operation is negate }

         if intt(tp) then wrtcod(inegint) { negate integer }
         else wrtcod(inegrel); { negate real }
         if tp^.t = ticst then begin 

            { perform constant integer negate }
            ti := tp^.ival.v; { find negated result value }
            ts := not tp^.ival.s; { find negated result sign }
            lsttyp(tp, ticst); { get a new integer entry }
            tp^.ival.v := ti; { place result value }
            tp^.ival.s := ts { place result }

         end else if tp^.t = trcst then begin 

            { perform constant real negate }
            trl := -tp^.rval; { find negated result }
            lsttyp(tp, trcst); { get a new integer entry }
            tp^.rval := trl { place result }

         end

      end

   end;
   chktkm([cor, cxor]); { check possible misspelled tolken }
   while nxttlk in [cplus, cminus, cor, cxor] do begin

      tk := nxttlk; { save operator tolken }
      rgttyp(tk, tp); { check proper type for operator }
      gettlk; { next }
      parterm(nil, [cplus, cminus, cor]+ss, tp1); { parse term }
      rgttyp(tk, tp1); { check proper type for operator }
      if sett(tp) or sett(tp1) then if not typcmp(tp, tp1) then begin

         { sets, but not compatible }
         perror(etypcmp, [], []); { types not compatible }
         tp := gbludf { set result undefined }

      end;
      if boolt(tp) or boolt(tp1) then if not typcmp(tp, tp1) then begin

         { if one is boolean, both must be }
         perror(etypcmp, [], []); { types not compatible }
         tp := gbludf { set result undefined }

      end;
      { output any integer to real conversion required }
      if realt(tp) or realt(tp1) then begin { result is real }

         { if top is integer, convert to real }
         if intt(tp1) then wrtcod(icvtitr); { else default to real }
         if intt(tp) then begin 

            { the second to top is harder, because we must swap to get access }
            wrtcod(iswptop); { output swap first and second operator }
            wrtlnk(baset(tp)); { output sos type }
            wrtlnk(gblreal); { output tos type }
            wrtcod(icvtitr); { convert to real }
            wrtcod(iswptop); { output swap first and second operator }
            wrtlnk(gblreal); { output sos type }
            wrtlnk(gblreal) { output tos type }

         end

      end;
      { output operator by operation type }
      case tk of { operator }

         cplus:  if sett(tp) then wrtcod(iuniset) { set union }
                 else if realt(tp) or realt(tp1) then
                    wrtcod(iaddrel) { add real }
                 else wrtcod(iaddint); { add integer }
         cminus: if sett(tp) then wrtcod(idifset) { set difference }
                 else if realt(tp) or realt(tp1) then
                    wrtcod(isubrel) { subtract real }
                 else wrtcod(isubint); { subtract integer }
         cor:    wrtcod(iorint); { 'or' integer }
         cxor:   wrtcod(ixorint) { 'xor' integer }

      end;
      solve := true; { set solved constant }
      if (tp^.t = ticst) and (tp1^.t = ticst) then begin 

         { constant integer operation, solve }
         case tk of { operator }

            cplus:  begin { find add }
            
               { perform overflow check. overflow will only occur if the
                 operands are the same sign }
               if tp^.ival.s = tp1^.ival.s then begin

                  if maxint-tp^.ival.v < tp1^.ival.v then begin

                     { operation overflows }
                     perror(eintovf, [], []); { constant operation overflow }
                     solve := false { so will just become type }

                  end else begin { find add }

                     ti := ssadd(tp^.ival.s, tp^.ival.v, 
                                 tp1^.ival.s, tp1^.ival.v); { value }
                     ts := ssadds(tp^.ival.s, tp^.ival.v, 
                                 tp1^.ival.s, tp1^.ival.v); { sign }

                  end

               end else begin { find add }

                  { value }
                  ti := ssadd(tp^.ival.s, tp^.ival.v, tp1^.ival.s, tp1^.ival.v);
                  { sign }
                  ts := ssadds(tp^.ival.s, tp^.ival.v, tp1^.ival.s, tp1^.ival.v)

               end

            end;
            cminus: begin { find subtract }

               { perform overflow check. overflow will only occur if the
                 operands are of different signs }
               if tp^.ival.s <> tp1^.ival.s then begin

                  if maxint-tp^.ival.v < tp1^.ival.v then begin

                     { operation overflows }
                     perror(eintovf, [], []); { constant operation overflow }
                     solve := false { so will just become type }

                  end else begin

                     ti := ssadd(tp^.ival.s, tp^.ival.v, 
                                not tp1^.ival.s, tp1^.ival.v); { value }
                     ts := ssadds(tp^.ival.s, tp^.ival.v, 
                                not tp1^.ival.s, tp1^.ival.v); { sign }

                  end

               end else begin

                  ti := ssadd(tp^.ival.s, tp^.ival.v, 
                             not tp1^.ival.s, tp1^.ival.v); { value }
                  ts := ssadds(tp^.ival.s, tp^.ival.v, 
                                not tp1^.ival.s, tp1^.ival.v); { sign }

               end

            end;
            cor:    begin

               if tp^.ival.s or tp1^.ival.s then begin

                  { cannot 'or' negative operands }
                  perror(ebolneg, [], []); { boolean negative }
                  solve := false { so will just become type }

               end else ti := tp^.ival.v or tp1^.ival.v { find integer 'or' }

            end;
            cxor:    begin

               if tp^.ival.s or tp1^.ival.s then begin

                  { cannot 'xor' negative operands }
                  perror(ebolneg, [], []); { boolean negative }
                  solve := false { so will just become type }

               end else 
                  ti := tp^.ival.v xor tp1^.ival.v { find integer 'xor' }

            end

         end;
         if solve then begin { was solved }

            lsttyp(tp, ticst); { get a new integer entry }
            tp^.ival.v := ti; { place result value }
            tp^.ival.s := ts { place result sign }

         end

      end else if ((tp^.t = ticst) or (tp^.t = trcst)) and 
                  ((tp1^.t = ticst) or (tp1^.t = trcst)) then begin

         { convert left to real }
         if tp^.t = ticst then begin { integer }

            trl := tp^.ival.v; { value }
            if tp^.ival.s then trl := trl*(-1) { sign }

         end else trl := tp^.rval; { real }
         { convert right to real }
         if tp1^.t = ticst then begin

            trr := tp1^.ival.v; { value }
            if tp1^.ival.s then trr := trr*(-1) { sign }

         end else trr := tp1^.rval; { real }
         { constant real operation, solve }
         case tk of { operator }

            cplus:  tr := trl+trr; { find add }
            cminus: tr := trl-trr; { find subtract }
            cor:    solve := false { so will just become type }

         end;
         if solve then begin { was solved }

            lsttyp(tp, trcst); { get a new real entry }
            tp^.rval := tr { place result }

         end

      end else if (boolt(tp) and (tp^.t = tenme)) and
                  (boolt(tp1) and (tp1^.t = tenme)) and (tk = cor) then begin

         { process boolean or }
         if (consti(tp) <> 0) or (consti(tp1) <> 0) then 
            tp := gbltrue else tp := gblfalse { set result value }

      end else solve := false; { set not solved constant }
      if not solve then begin { not a solved constant, find result type }

         { set result }
         if (tp^.t = tudf) or (tp1^.t = tudf) then tp := gbludf { undefined }
         { if either is real, then result is real }
         else if realt(tp1) then tp := tp1
         else if intt(tp) then tp := gblint { result is integer }

      end

   end

end;

{*******************************************************************************

Parse expression

   expr = sexpr | '=' expr | '<' expr | '>' expr | '<>' expr | 
          '<=' expr | '>=' expr> | 'in' expr> | 'is' class

Parses and generates an expression. Accepts a tolken skip set.
Error recovery:

1. Resyncs to any of the middle tolkens.

Accepts a variable reference leader. This is a parsed result type from parvarh.
If it is not nil, then the left hand part of expressions is skipped, and the
variable reference substitutes for it. This is because of a requirement in the
parsing of overload parameters that we must be able to continue after parsing
only the variable reference leader.

*******************************************************************************}

procedure parexpr(    varref: typptr;  { variable reference leader }
                      ss:     tolkset; { skip set }
                  var tp:     typptr); { return type }

var tp1:   typptr;  { type pointer }
    tk:    tolken;  { tolken save }
    solve: boolean; { solved constant flag }
    sp:    symptr;  { symbol entry pointer }
    lab:   labl;    { label for undefines }

{ determine type correct for operator }

procedure rgttyp(    tk:  tolken;   { operator tolken }
                 var tp:  typptr;   { type to check }
                     lft: boolean); { left/right operand }

var m:   boolean; { type correct flag }
    tp1: typptr;  { type holder }

begin

   tp1 := baset(tp); { find the base type }
   case tk of { operator }
  
      cis: m := tp1^.t = treference; { must be reference }
      cin: if lft then m := (tp1^.t in [tinteger, tlinteger, tcardinal,
                                        tlcardinal, tchar, tboolean, tenum]) or
                            chart(tp1) { left side }
           else m := sett(tp1); { must be set }

      cequ, cnequ, cnequa:
         m := (tp1^.t in [tinteger, tlinteger, tcardinal, tlcardinal, tchar,
                          tboolean, tenum, treal, tsreal, tptr, tnil, 
                          treference]) or
                        sett(tp1) or chart(tp1) or strt(tp1);

      clequ, clequa, cgequ, cgequa:
         m := (tp1^.t in [tinteger, tlinteger, tcardinal, tlcardinal, tchar,
                          tboolean, tenum, treal, tsreal]) or
              sett(tp1) or chart(tp1) or strt(tp1);

      cltn, cgtn: m := (tp1^.t in [tinteger, tlinteger, tcardinal, tlcardinal, 
                                   tchar, tboolean, tenum, treal, tsreal]) or
                       chart(tp1) or strt(tp1)

   end;
   if not m and (tp1^.t <> tudf) then begin { bad type }

      perror(etypcon, [], []); { type in wrong context }
      tp := gbludf { set result undefined }

   end

end;

procedure prcgen;

begin

   { parse simple expression }
   parsexpr(nil, [cequ, cltn, cgtn, cnequ, clequ, cgequ, cin, cis]+ss, tp1);
   { fetch indirect any string characters }
   if strt(tp1) and chart(tp1) then wrtcod(ildichr);
   rgttyp(tk, tp1, false); { check proper type }
   { check types of operands are compatible }
   if tk = cin then begin { 'in' operator }

      { right side is set or undefined. If set, we compare the non-set
        left with the base type of the right. If the set is the empty
        set, or the right side is undefined, we do nothing, since
        the empty set is compatible with anything }
      if tp1^.t = tset then if not typcmp(tp, tp1^.sett) then begin

         { left side not compatible with set base }
         perror(etypcmp, [], []);
         tp := gbludf { set result undefined }

      end else if tp1^.t = tstcst then if not typcmp(tp, tp1^.stct) then 
         begin

         { left side not compatible with set base }
         perror(etypcmp, [], []);
         tp := gbludf { set result undefined }

      end

   end else if not ((realt(tp) and intt(tp1)) or 
                    (intt(tp) and realt(tp1))) then { not real and integer }
      if not typcmp(tp, tp1) then begin

      perror(etypcmp, [], []);
      tp := gbludf { set result undefined }

   end;
   { output any integer to real conversion required }
   if realt(tp) or realt(tp1) then begin { result is real }

      { if top is integer, convert to real }
      if intt(tp1) then wrtcod(icvtitr); { else default to real }
      if intt(tp) then begin 

         { the second to top is harder, because we must swap to get access }
         wrtcod(iswptop); { output swap first and second operator }
         wrtlnk(baset(tp)); { output sos type }
         wrtlnk(gblreal); { output tos type }
         wrtcod(icvtitr); { convert to real }
         wrtcod(iswptop); { output swap first and second operator }
         wrtlnk(gblreal); { output sos type }
         wrtlnk(gblreal) { output tos type }

      end

   end;
   { output any general to fixed array convertion required }
   if ((tp^.t = tgarry) or (tp1^.t = tgarry)) and
      not ((tp^.t = tgarry) and (tp1^.t = tgarry)) then begin

      { one, but not both, are general arrays }
      if tp1^.t = tgarry then begin { convert tos }

         wrtcod(icvtgtf); { convert general array to fixed }
         wrtlnk(tp) { output fixed type }
         
      end else if tp^.t = tgarry then begin { convert sos }

         wrtcod(iswptop); { swap operands }
         wrtlnk(tp); { output sos type }
         wrtlnk(tp1); { output tos type }
         wrtcod(icvtgtf); { convert general array to fixed }
         wrtlnk(tp1); { output fixed type }
         { now both are fixed pointers }
         wrtcod(iswptop); { swap operands }
         wrtlnk(tp1); { output sos type }
         wrtlnk(tp1); { output tos type }
         tp := tp1 { set reference as fixed }

      end

   end;
   { check tagged pointer compared with nil }
   if tp^.t = tptr then { pointer }
      if (tp^.ptrt^.t = tgarry) and (tp1^.t = tnil) then
         { general array with nil }
         wrtcod(icvtntg); { convert nil to tagged format }
   if tp1^.t = tptr then { pointer }
      if (tp1^.ptrt^.t = tgarry) and (tp^.t = tnil) then begin

         { nil with general array }
         wrtcod(iswptop); { swap operands }
         wrtlnk(tp); { output sos type }
         wrtlnk(tp1); { output tos type }
         wrtcod(icvtntg); { convert nil to tagged format }
         wrtcod(iswptop); { swap operands }
         wrtlnk(tp1); { output sos type }
         wrtlnk(tp1) { output tos type }

   end;
   { check reference compared with nil }
   if (tp^.t = treference) and (tp1^.t = tnil) then { reference }
         { reference with nil }
         wrtcod(icvtntr); { convert nil to reference format }
   if (tp1^.t = treference) and (tp^.t = tnil) then begin { reference }

         { nil with reference }
         wrtcod(iswptop); { swap operands }
         wrtlnk(tp); { output sos type }
         wrtlnk(tp1); { output tos type }
         wrtcod(icvtntr); { convert nil to reference format }
         wrtcod(iswptop); { swap operands }
         wrtlnk(tp1); { output sos type }
         wrtlnk(tp1) { output tos type }

   end;
   { output operator by operation type }
   case tk of { operator }

      cin:   wrtcod(iincset); { set inclusion }
      cequ:  if sett(tp) then wrtcod(iequset) { set equal }
             else if realt(tp) or realt(tp1) then
                wrtcod(iequrel) { real equal }
             else if strt(tp) and not chart(tp) then begin

                if (tp^.t = tgarry) and (tp1^.t = tgarry) then
                   wrtcod(iequgst) { general string equal }
                else begin { fixed }

                   wrtcod(iequstr); { string equal }
                   wrtlnk(tp) { generate type }

                end

             end else if tp^.t in [tptr, treference, tnil] then begin

               { pointer equation }
               if tp^.t = tptr then begin { left is pointer }

                  if tp^.ptrt^.t = tgarry then { general array }
                     wrtcod(iequtgp) { tagged pointer equal }
                  else wrtcod(iequint) { integer equal }

               end else if tp1^.t = tptr then begin { right is pointer }

                  if tp1^.ptrt^.t = tgarry then { general array }
                     wrtcod(iequtgp) { tagged pointer equal }
                  else wrtcod(iequint) { integer equal }

               end else if (tp^.t = treference) or (tp1^.t = treference) then
                  wrtcod(iequref) { reference equal }
               else { normal pointer }
                  wrtcod(iequint) { integer equal }

             end else wrtcod(iequint); { integer equal }
      cnequ, cnequa: if sett(tp) then wrtcod(ineqset) { set not equal }
             else if realt(tp) or realt(tp1) then
                wrtcod(ineqrel) { real not equal }
             else if strt(tp) and not chart(tp) then begin

                if (tp^.t = tgarry) and (tp1^.t = tgarry) then
                   wrtcod(ineqgst) { general string not equal }
                else begin { fixed }

                   wrtcod(ineqstr); { string not equal }
                   wrtlnk(tp) { generate type }

                end

             end else if tp^.t in [tptr, tnil] then begin

               { pointer equation }
               if tp^.t = tptr then begin { left is pointer }

                  if tp^.ptrt^.t = tgarry then { general array }
                     wrtcod(ineqtgp) { tagged pointer equal }
                  else wrtcod(ineqint) { integer equal }

               end else if tp1^.t = tptr then begin { right is pointer }

                  if tp1^.ptrt^.t = tgarry then { general array }
                     wrtcod(ineqtgp) { tagged pointer equal }
                  else wrtcod(ineqint) { integer equal }

               end else if (tp^.t = treference) or (tp1^.t = treference) then
                  wrtcod(ineqref) { reference not equal }
               else { normal pointer }
                  wrtcod(ineqint) { integer not equal }

             end else wrtcod(ineqint); { integer not equal }
      clequ, clequa: if sett(tp) then 
                wrtcod(ileqset) { set less than or equal }
             else if realt(tp) or realt(tp1) then
                wrtcod(ileqrel) { real less than or equal }
             else if strt(tp) and not chart(tp) then begin

                if (tp^.t = tgarry) and (tp1^.t = tgarry) then
                   wrtcod(ileqgst) { general string less than or equal }
                else begin { fixed }

                   wrtcod(ileqstr); { string less than or equal }
                   wrtlnk(tp) { generate type }

                end

             end else wrtcod(ileqint); { integer less than or equal }
      cgequ, cgequa: if sett(tp) then 
                wrtcod(igeqset) { set greater than or equal }
             else if realt(tp) or realt(tp1) then
                wrtcod(igeqrel) { real greater than or equal }
             else if strt(tp) and not chart(tp) then begin
 
                if (tp^.t = tgarry) and (tp1^.t = tgarry) then
                   { general string greater than or equal }
                   wrtcod(igeqgst)
                else begin { fixed }

                   wrtcod(igeqstr); { string greater than or equal }
                   wrtlnk(tp) { generate type }

                end

             end else wrtcod(igeqint); { integer greater than or equal }
      cltn:  if realt(tp) or realt(tp1) then
                wrtcod(iltnrel) { real less than }
             else if strt(tp) and not chart(tp) then begin
 
                if (tp^.t = tgarry) and (tp1^.t = tgarry) then
                   wrtcod(iltngst) { general string less than }
                else begin { fixed }

                   wrtcod(iltnstr); { string less than }
                   wrtlnk(tp) { generate type }

                end

             end else wrtcod(iltnint); { integer less than }
      cgtn:  if realt(tp) or realt(tp1) then
                wrtcod(igtnrel) { real greater than }
             else if strt(tp) and not chart(tp) then begin

                if (tp^.t = tgarry) and (tp1^.t = tgarry) then
                   wrtcod(igtngst) { general string less than }
                else begin { fixed }

                   wrtcod(igtnstr); { string greater than }
                   wrtlnk(tp) { generate type }

                end

             end else wrtcod(igtnint) { integer greater than }

   end;
   solve := true; { set solved constant }
   { we are not presently including string operations in the list of solved
     operations }
   if ((tp^.t in [ticst, tenme, tccst]) or 
       ((tp^.t = tscst) and chart(tp))) and
      ((tp1^.t in [ticst, tenme, tccst]) or
       ((tp1^.t = tscst) and chart(tp1))) then
      begin

      { resolve constant operation }
      case tk of { operation }

         cin:   solve := false; { not appropriate operation }
         cequ:  if (constis(tp) = constis(tp1)) and 
                   (consti(tp) = consti(tp1)) then
                   tp := gbltrue else tp := gblfalse;
         cnequ: if (constis(tp) <> constis(tp1)) or
                   (consti(tp) <> consti(tp1)) then
                   tp := gbltrue else tp := gblfalse;
         clequ: if ssleq(constis(tp),  consti(tp), 
                         constis(tp1), consti(tp1)) then
                   tp := gbltrue else tp := gblfalse;
         cgequ: if ssgeq(constis(tp),  consti(tp), 
                         constis(tp1), consti(tp1)) then
                   tp := gbltrue else tp := gblfalse;
         cltn:  if ssltn(constis(tp),  consti(tp), 
                         constis(tp1), consti(tp1)) then
                   tp := gbltrue else tp := gblfalse;
         cgtn:  if ssgtn(constis(tp), consti(tp), 
                         constis(tp1), consti(tp1)) then
                   tp := gbltrue else tp := gblfalse

      end

   end else solve := false;
   if not solve then begin { not a solved constant, find result type }

      if (tp^.t = tudf) or (tp1^.t = tudf) then tp := gbludf { undefined }
      else tp := gblbool { set result to boolean type }

   end

end;

begin

   if fparse then writeln(':expression');
   { parse simple expression }
   parsexpr(varref, [cequ, cltn, cgtn, cnequ, clequ, cgequ, cin, cis]+ss, tp);
   chktkm([cin]); { check possible misspelled tolken }
   if nxttlk in [cequ, cltn, cgtn, cnequ, cnequa, clequ, clequa, cgequ, cgequa, 
                 cin, cis] then begin

      { fetch indirect any string characters }
      if strt(tp) and chart(tp) then wrtcod(ildichr);
      tk := nxttlk; { save the operator tolken }
      rgttyp(tk, tp, true); { check proper type }
      { output errors (scold) for use of alternatives }
      if nxttlk = cnequa then perror(eneqalt, [], []) 
      else if nxttlk = clequa then perror(eleqalt, [], [])
      else if nxttlk = cgequa then perror(egeqalt, [], []);
      gettlk; { next }
      if tk = cis then begin { <expr> is <class> }

         { perform special parse for class }
         if nxttlk <> cidentifier then { missing id }
            perror(eidnexp, typeset+ss, []) { flag error }
         else begin { process class symbol }

            parqualident(ss, false, true, true, '', sp, lab); { find class }
            if sp = nil then error(esflt46, true);
            wrtcod(iis); { reference is class }
            wrtlnk(sp^.typ) { output class }

         end;
         tp := gblbool { set result to boolean type }

      end else prcgen { process the general case }

   end

end;

{*******************************************************************************

Statement block

   statb = 'begin' statement [ ';' statement ].. 'end'

Parses and generates a statement block. Accepts a tolken skip set.
We also perform uses eliding here. There are two reasons. First,
all encoded blocks are contained within a statement block, so this
is a natural place to process removal. Second, block nesting can
be handled simply via recursion.
Error recovery:

1. No 'begin', respell id or skip to 'begin', 'end' or
likely statement.

1. Will skip trailing garbage from a statement parse to find
';', 'end', or a likely statement begin.

2. Missing ';' will be allowed as the next likely statement is
parsed.

3. Missing 'end', respell id or skip to 'end', ';' or likely 
statement.

*******************************************************************************}

procedure parstatb(ss: tolkset);

var last:    tolken;  { parsing aid }
    bl:      integer; { block nesting level }
    stalabs: typptr;  { statement label list save }
    stagtos: gtoptr;  { statement goto list save }
    bt:      typptr;  { base type pointer }
    tp:      typptr;  { expression result }
    mt:      typptr;  { mark type }

begin

   if fparse then writeln(':statement block');
   stalvl := stalvl+1; { count statment level }
   stalabs := stalab; { save current label list }
   stagtos := stagto; { save current label list }
   stagto := nil; { clear list for enclosed blocks }
   bl := 1; { set nesting level }
   { expect 'begin' }
   expect(cbegin, ebgnexp, [cbegin, cend]+statuset+ss, [cbegin]);
   if uselvl = 0 then begin { not in uses file }

      wrtcod(ibgnblk); { begin statement block }
      repeat

         if nxttlk = cresult then begin { parse anonymous function result }

            gettlk; { skip 'result' }
            { check at outter statement level }
            if stalvl > 1 then perror(ersltlvl, [], []);
            { check is enclosed in block }
            mt := blkstk^.mark; { get the mark }
            if mt^.t <> tfunc then perror(ersltfnc, [], [])
            else begin { load the function result address }

               wrtcod(ilodfadr); { load function result address }
               wrtlnk(mt) { output function type }

            end;
            parexpr(nil, [cscn, cend]+statuset+ss, tp); { parse expression }
            if mt^.t = tfunc then begin 

               { There is an enclosing function. Check assignment compatible
                 with function result }
               if not typcmpa(mt^.fncr, tp) then perror(easscmp, [], []);
               { Check any other assigns to this function. Since this statement
                 by definition closes out the function, this is all that is 
                 needed to check for illegal result assignment combinations. }
               if mt^.fncc > 0 then perror(ersltmix, [], []);
               mt^.fncc := mt^.fncc+1; { count function references }
               bt := baset(tp); { find base of expression }
               if bt^.t = tptr then begin { store pointer }

                  if bt^.ptrt^.t = tgarry then { general array pointer }
                     wrtcod(istiftgp) { store tagged pointer }
                  else { normal pointer }
                     wrtcod(istifint) { store integer }

               end else if bt^.t in [tinteger, tlinteger, tcardinal, tlcardinal,
                                     tenum, tnil] then
                  wrtcod(istifint) { store integer }
               else if bt^.t = tsreal then 
                  wrtcod(istifsrl) { store short real }
               else if bt^.t = treal then wrtcod(istifrel) { store short real }
               else if chart(bt) then wrtcod(istifchr) { store character }
               else wrtcod(istifbol); { store boolean }
               wrtlnk(mt) { output function type }

            end;
            if nxttlk <> cend then 
               perror(ersltend, [cscn, cend]+statuset+ss, [cend]);

         end else parstat([cscn, cend]+statuset+ss); { parse statement }
         if (nxttlk <> cscn) and (nxttlk <> cend) then
            { no exit tolken }
            perror(eedscexp, [cscn, cend]+statuset+ss, [cend]);
         last := nxttlk; { save last tolken }
         if nxttlk = cscn then gettlk { skip ';' }

      { until not ';' and no statement possible }
      until not (last in [cbcms, cscn]+statset);
      wrtcod(iendblk) { end statement block }

   end else { in uses file }
      while (nxttlk <> cprivate) and (nxttlk <> ceof) and (bl <> 0) do begin

         { until we see a private marker or eof (for safety) }
         { keep track of nesting level }
         if nxttlk in [cbegin, ccase] then bl := bl+1
         else if nxttlk = cend then bl := bl-1;
         gettlk { skip tolkens }
      
      end;
   if nxttlk = cend then gettlk; { next }
   stalvl := stalvl-1; { remove statement level }
   stalab := stalabs; { restore old label list }
   mrggto(stagto, stagtos) { merge saved and new goto list }

end;

{*******************************************************************************

If statement

   ifstat = 'if' expr 'then' statement [ 'else' statement ]

Parses and generates a statement. Accepts a tolken skip set.
Error recovery:

1. Missing expression or trash on expression is recovered by
'then', 'else' or likely statement resync.

2. Missing 'then' is resynced by likely statement.

3. Missing 'else', respell or leave to upper level to become
a sequential statement (since all statements are ultimately 
contained within a block).

*******************************************************************************}

procedure parif(ss: tolkset);

var tp:      typptr; { type pointer }
    stalabs: typptr; { statement label list save }
    stagtos: gtoptr; { statement goto list save }

begin

   if fparse then writeln(':if statement');
   gettlk; { skip 'if' }
   parexpr(nil, [cthen, celse]+statuset+ss, tp); { parse expression }
   if not boolt(tp) and (tp^.t <> tudf) then 
      perror(etmbbol, [], []); { must be boolean type }
   wrtcod(iifbgn); { if begin }
   { expect 'then' }
   expect(cthen, ethnexp, [cthen, celse]+statuset+ss, [cthen]);
   if boolt(tp) and (tp^.t = tenme) then { constant condition }
      if consti(tp) = 0 then concon := concon+1; { increment delete level }
   stalvl := stalvl+1; { count statment level }
   stalabs := stalab; { save current label list }
   stagtos := stagto; { save current label list }
   stagto := nil; { clear list for enclosed blocks }
   parstat(ss); { parse statement }
   stalvl := stalvl-1; { remove statement level }
   stalab := stalabs; { restore old label list }
   mrggto(stagto, stagtos); { merge saved and new goto list }
   if boolt(tp) and (tp^.t = tenme) then { constant condition }
      if consti(tp) = 0 then concon := concon-1; { decrement delete level }
   { check if we have a candidate for an 'else' misspell }
   chktkm([celse]); { check possible misspelled tolken }
   if nxttlk = celse then begin { 'else' clause }

      gettlk; { next }
      wrtcod(ielse); { else }
      if boolt(tp) and (tp^.t = tenme) then { constant condition }
         if consti(tp) <> 0 then concon := concon+1; { increment delete level }
      stalvl := stalvl+1; { count statment level }
      stalabs := stalab; { save current label list }
      stagtos := stagto; { save current label list }
      stagto := nil; { clear list for enclosed blocks }
      parstat(ss); { parse statment }
      stalvl := stalvl-1; { remove statement level }
      stalab := stalabs; { restore old label list }
      mrggto(stagto, stagtos); { merge saved and new goto list }
      if boolt(tp) and (tp^.t = tenme) then { constant condition }
         if consti(tp) <> 0 then concon := concon-1; { decrement delete level }

   end;
   wrtcod(iifend) { if end }

end;

{*******************************************************************************

Case statement

   casestat = 'case' expr 'of' [ const [, const].. ':' 
              statement ].. 'end'

Parses and generates a case statment. Accepts a tolken skip set.
Error recovery:

1. badly formed case expression by skip to 'of', likely case 
constant, likely statement.

2. Missing 'of' by resync at likely case constant, likely 
statement.

3. Garbage before 'of' by skip to 'of', likely case constant, 
likely statement.

4. Missing ',' on case constant by skip to likely case constant.

5. Missing ':' on case constant by skip to 'end', ';', likely
statement.

6. Missing ';' on case statement by skip to 'end', likely case
constant, likely statement.

*******************************************************************************}

procedure parcase(ss: tolkset);

var last:    tolken;  { parser aid }
    tp, tp1: typptr;  { pointer to type entry }
    bt:      typptr;  { base type }
    match:   boolean; { case match flag }
    csvlst:  csvptr;  { list of case values }
    cp:      csvptr;  { case value entry pointer }
    cv:      integer; { case value }
    cvs:     boolean; { case value sign }
    stalabs: typptr;  { statement label list save }
    stagtos: gtoptr;  { statement goto list save }

{ find case value overlap in case list }

function fndcasval(scvs: boolean; scv: integer; 
                   ecvs: boolean; ecv: integer): boolean;

var cp: csvptr;  { case value entry pointer }
    f:  boolean; { value found }

begin

   cp := csvlst; { index top of case value list }
   f := false; { set no case value found }   
   while cp <> nil do begin { traverse case value list }

      { check defined, and sv <= end and ev >= start }
      if cp^.def and ssleq(scvs, scv, cp^.evals, cp^.eval) and 
                     ssgeq(ecvs, ecv, cp^.svals, cp^.sval) then
         f := true; { found }
      cp := cp^.next { next entry }

   end;

   fndcasval := f { return result }

end;
   
begin

   if fparse then writeln(':case statement');
   gettlk; { next }
   { parse expression }
   parexpr(nil, [cof, cinteger, cidentifier]+statuset+ss, tp); 
   { if the object is a string constant, this must be a character, so
     load it from the address }
   if tp^.t = tscst then wrtcod(ildichr);
   bt := baset(tp); { get base type of expression }
   if not ((bt^.t in [tinteger, tlinteger, tcardinal, tlcardinal, tchar,
                      tboolean, tenum, tudf]) or 
           chart(bt)) then begin

      perror(etmbord, [], []); { type must be ordinal }
      bt := gbludf { set undefined }

   end;
   wrtcod(icasbgn); { case begin }
   { expect 'of' }
   expect(cof, eofexp, [cof]+constset+statuset+ss, [cof]);
   csvlst := nil; { clear case value list }
   repeat { section }

      match := false; { set no case matches }
      repeat { case label }

         { parse case constant }
         parconst([cend, ccln, cscn]+statuset+ss, tp1);
         { place the case value into the collected list for this case }
         getcsv(cp); { get a new case value entry }
         if tp1^.t in [ticst, tscst, tccst, tenme] then begin

            { define case value }
            chkschr(tp1); { check string is single character }
            if tp1^.t <> tudf then begin { defined }

               cv := consti(tp1); { get value }
               cvs := constis(tp1);
               cp^.sval := cv; { place value as a range n-n }
               cp^.svals := cvs;
               cp^.eval := cv;
               cp^.evals := cvs;
               cp^.def := true { set defined }

            end

         end else cp^.def := false; { set not defined }
         { check is an ordinal constant }
         if not (tp1^.t in [ticst, tscst, tccst, tenme, tudf]) then begin

            perror(ecmborc, [], []); { must be ordinal }
            tp := gbludf { set undefined }

         end;
         { check is compatible with original case selector }
         if not typcmp(tp1, bt) then perror(ecascmp, [], []);
         { check range specification }
         if nxttlk = crange then begin

            gettlk; { skip '..' }
            { parse case constant }
            parconst([cend, ccln, cscn]+statuset+ss, tp1);
            { place the case value into the collected list for this case }
            if tp1^.t in [ticst, tscst, tccst, tenme] then begin
            
               { define case value }
               chkschr(tp1); { check string is single character }
               { if undefined, set case entry undefined }
               if tp1^.t = tudf then cp^.def := false;
               if cp^.def then begin { defined }

                  cv := consti(tp1); { get value }
                  cvs := constis(tp1);
                  cp^.eval := cv; { place ending value }
                  cp^.evals := cvs

               end
            
            end else cp^.def := false; { set not defined }
            { check is an ordinal constant }
            if not (tp1^.t in [ticst, tscst, tccst, tenme, tudf]) then begin
            
               perror(ecmborc, [], []); { must be ordinal }
               tp := gbludf { set undefined }
            
            end;
            { check is compatible with original case selector }
            if not typcmp(tp1, bt) then perror(ecascmp, [], []);
            wrtcod(icassrng); { case select range }
            wrtnum(cp^.svals, cp^.sval); { output range of values }
            wrtnum(cp^.evals, cp^.eval) { output range of values }

         end else begin { normal case select }

            wrtcod(icassint); { case select integer }
            if tp1^.t in [ticst, tscst, tccst, tenme] then
               wrtnum(constis(tp1), consti(tp1)) { value of selector }

         end;
         { If case entry is defined, check for duplications (before we enter it
           onto the list. }
         if cp^.def then begin

            { check for duplications before we enter it onto the list }
            if fndcasval(cp^.svals, cp^.sval, cp^.evals, cp^.eval) then 
               perror(ecasdup, [], []);
            { check selector is constant }
            if tp^.t in [ticst, tscst, tccst, tenme] then
               { if the selector matches the case, set case match. Then, the
                 match status becomes an 'or' of all cases attached to this
                 statement }
               if ssgeq(constis(tp), consti(tp), cp^.svals, cp^.sval) and 
                  ssleq(constis(tp), consti(tp), cp^.evals, cp^.eval) then
                  match := true

         end;
         cp^.next := csvlst; { push onto case value list }
         csvlst := cp;
         if (nxttlk <> ccma) and (nxttlk <> ccln) then
            { we don't have an exit tolken }
            perror(ecncmexp, [cend, ccln, ccma, cscn]+statuset+ss, []);
         last := nxttlk; { save current tolken }
         if nxttlk = ccma then gettlk { skip ',' }

      { until not ',', or not likely label }
      until not (last in [ccma]+constset);
      if nxttlk = ccln then gettlk; { skip ':' }
      if not (nxttlk in [cend, cscn]+statset) then { nowhere to go }
         perror(eedscexp, [cend, ccln, cscn]+constset+statuset+ss, []);
      if (tp^.t in [ticst, tscst, tccst, tenme]) and not match then 
         { selector constant, and not match, constant delete }
         concon := concon+1; { increment delete level }
      wrtcod(icasstb); { mark case statement begins }
      stalvl := stalvl+1; { count statment level }
      stalabs := stalab; { save current label list }
      stagtos := stagto; { save current label list }
      stagto := nil; { clear list for enclosed blocks }
      parstat([cend, ccln, cscn]+statuset+ss); { parse statement }
      stalvl := stalvl-1; { remove statement level }
      stalab := stalabs; { restore old label list }
      mrggto(stagto, stagtos); { merge saved and new goto list }
      wrtcod(icasste); { mark case statement ends }
      if (tp^.t in [ticst, tscst, tccst, tenme]) and not match then 
         { selector constant, and not match, constant delete }
         concon := concon-1; { decrement delete level }
      if not (nxttlk in [cend, cscn]) and ((nxttlk <> celse) or fansi) then 
         { 'end' or ';' expected }
         perror(eedscexp, [cend, ccln, cscn, celse]+constset+ss, 
                [cend, celse]);
      if nxttlk = cscn then gettlk; { skip ';' }
      if not (nxttlk in [cend]+constset) and 
         ((nxttlk <> celse) or fansi) then { nowhere to go } 
         perror(eendexp, [cend, ccln, celse]+constset+ss, [cend, celse])

   { until no possible label or statement }
   until not (nxttlk in [ccln]+constset);
   if nxttlk = celse then begin { there is a 'else' construct }

      gettlk; { next }
      wrtcod(icasels); { mark case 'else' begins }
      stalvl := stalvl+1; { count statment level }
      stalabs := stalab; { save current label list }
      stagtos := stagto; { save current label list }
      stagto := nil; { clear list for enclosed blocks }
      parstat([cend]+statuset+ss); { parse statement }
      stalvl := stalvl-1; { remove statement level }
      stalab := stalabs; { restore old label list }
      mrggto(stagto, stagtos); { merge saved and new goto list }
      { check terminated by 'end' }
      if nxttlk <> cend then perror(eendexp, [cend]+ss, [cend])

   end;
   if nxttlk = cend then gettlk; { skip 'end' }
   wrtcod(icasend); { case end }
   putcsvs(csvlst) { free case value list }

end;

{*******************************************************************************

While statement

   whilestat = 'while' expr 'do' statement

Parses and generates a while statement. Accepts a tolken skip set.
Error recovery:

1. Crud before 'do' with skip to do.

2. Missing 'do' with skip to likely statement.

*******************************************************************************}

procedure parwhile(ss: tolkset);

var tp:      typptr; { type pointer }
    stalabs: typptr; { statement label list save }
    stagtos: gtoptr; { statement goto list save }

begin

   if fparse then writeln(':while statement');
   stalvl := stalvl+1; { count statment level }
   stalabs := stalab; { save current label list }
   stagtos := stagto; { save current label list }
   stagto := nil; { clear list for enclosed blocks }
   gettlk; { next }
   wrtcod(iwhlexp); { mark top of while loop }
   parexpr(nil, [cdo]+ss, tp); { parse expression }
   if not boolt(tp) and (tp^.t <> tudf) then 
      perror(etmbbol, [], []); { must be boolean type }
   wrtcod(iwhlbgn); { while begin }
   if nxttlk <> cdo then { 'do' expected }
      perror(edoexp, [cdo]+statuset+ss, [cdo]);
   if nxttlk = cdo then gettlk; { skip 'do' }
   if boolt(tp) and (tp^.t = tenme) then { constant condition }
      if consti(tp) = 0 then concon := concon+1; { increment delete level }
   parstat(ss); { parse statement }
   if boolt(tp) and (tp^.t = tenme) then { constant condition }
      if consti(tp) = 0 then concon := concon-1; { decrement delete level }
   wrtcod(iwhlend); { while end }
   stalvl := stalvl-1; { remove statement level }
   stalab := stalabs; { restore old label list }
   mrggto(stagto, stagtos) { merge saved and new goto list }

end;

{*******************************************************************************

Repeat statement

   repeatstat = 'repeat' statement [ ; statement ].. 'until' expr

Parses and generates a repeat statement. Accepts a tolken skip 
set.
Error recovery:

1. Missing ';' between statements, skip to 'until' or next
likely statement.

2. Missing 'until', skip to ';', next likely statement.

*******************************************************************************}

procedure parrepeat(ss: tolkset);

var last:    tolken; { parser aid }
    tp:      typptr; { type pointer }
    stalabs: typptr; { statement label list save }
    stagtos: gtoptr; { statement goto list save }

begin

   if fparse then writeln(':repeat statement');
   stalvl := stalvl+1; { count statment level }
   stalabs := stalab; { save current label list }
   stagtos := stagto; { save current label list }
   stagto := nil; { clear list for enclosed blocks }
   gettlk; { skip 'repeat' }
   wrtcod(irptbgn); { repeat begin }
   repeat { statements }

      parstat([cscn, cuntil]+statuset+ss); { parse statement }
      if (nxttlk <> cscn) and (nxttlk <> cuntil) then
         { 'until' or ';' expected }
         perror(eutscexp, [cscn, cuntil]+statuset+ss, [cuntil]);
      last := nxttlk; { save last tolken }
      if nxttlk = cscn then gettlk { skip ';' }

   { until not ';' or likely statement }
   until not (last in [cscn]+statuset);
   if nxttlk = cuntil then begin 

      { we were properly terminated }
      gettlk; { skip 'until' }
      parexpr(nil, ss, tp); { parse expression }
      if not boolt(tp) and (tp^.t <> tudf) then 
         perror(etmbbol, [], []); { must be boolean type }

   end;
   wrtcod(irptend); { repeat end }
   stalvl := stalvl-1; { remove statement level }
   stalab := stalabs; { restore old label list }
   mrggto(stagto, stagtos) { merge saved and new goto list }

end;

{*******************************************************************************

For statement

   forstat = 'for' identifier ':=' expr 'to' expr 'do' 
             statement |
             'for' identifier ':=' expr 'downto' expr 'do'
             statement

Parses and generates the for statement. Accepts a tolken skip set.
Error recovery:

1. Missing variable identifier, skip to ':=', 'to'/'downto',
'do', likely expression, likely statement.

2. Missing ':=', skip to 'to'/'downto', 'do', likely expression,
likely statement.

3. Missing 'to'/'downto', skip to 'do', likely expression, likely 
statement. 

4. Missing 'do', skip to likely statement.

*******************************************************************************}

procedure parfor(ss: tolkset);

var sp:           symptr;  { symbol pointer }
    tp, tp1, tp2: typptr;  { type pointers }
    bt:           typptr;  { base type }
    tk:           tolken;  { tolken save }
    cdel:         boolean; { constant operation delete }
    stalabs:      typptr;  { statement label list save }
    stagtos:      gtoptr;  { statement goto list save }
    lab:          labl;    { label for undefines }

begin

   if fparse then writeln(':for statement');
   stalvl := stalvl+1; { count statment level }
   stalabs := stalab; { save current label list }
   stagtos := stagto; { save current label list }
   stagto := nil; { clear list for enclosed blocks }
   gettlk; { next }
   if nxttlk <> cidentifier then { id expected }
      perror(eidnexp, [cbcms, cto, cdownto, cdo]+exprset+statuset+ss, []);
   tp := gbludf; { set defaults for variable type }
   bt := gbludf;
   if nxttlk = cidentifier then begin

      parqualident(ss, true, true, true, '', sp, lab); { parse qualified identifier }
      tp := actt(sp^.typ); { index type of symbol }
      if (tp^.t <> tvar) and (tp^.t <> tudf) then { not simple variable }
         perror(elvarexp, [], [], sp^.lab^); { must be a local variable }
      if tp^.t = tvar then begin { simple variable }

         { check variable is a local, without "with" levels }
         if sp^.lvl <> level-wthlvl then perror(evarmbl, [], [], sp^.lab^);
         { check variable is external }
         if tp^.vare then perror(evarext, [], [], sp^.lab^);
         bt := baset(tp); { get base type }
         if not (bt^.t in [tenum, tinteger, tlinteger, tcardinal, tlcardinal, 
                           tchar, tboolean, tudf]) then begin
  
            { not ordinal }
            perror(etmbord, [], []); { type must be ordinal }
            tp := gbludf { set undefined }

         end else begin { ok }

            if tp^.varf <> 0 then { in use by 'for' }
               perror(eforviu, [], [], sp^.lab^); { variable in use }
            if tp^.varp then { process subroutine threat }
               { variable has a subroutine threat }
               perror(eforvst, [], [], sp^.lab^);
            tp^.varr := tp^.varr + 1; { increment threat count }
            tp^.varf := tp^.varf + 1 { increment 'for' use count }

         end

      end

   end;
   { expect ':=' }
   expect(cbcms, ebcmexp, [cto, cdownto, cdo]+exprset+statuset+ss, []);
   { parse starting expression }
   parexpr(nil, [cto, cdownto, cdo]+statuset+ss, tp1);
   { if the object is a string constant, this must be a character, so
     load it from the address }
   if tp1^.t = tscst then wrtcod(ildichr);
   { check compatible with control variable }
   if not typcmp(tp, tp1) then perror(etypcmp, [], []);
   if (nxttlk <> cto) and (nxttlk <> cdownto) then 
      { 'to'/'downto' expected }
      perror(etdtexp, [cto, cdownto, cdo]+exprset+statuset+ss, [cto, cdownto]);
   tk := nxttlk; { save 'to'/'downto' tolken }
   if (nxttlk = cto) or (nxttlk = cdownto) then gettlk; { skip 'to'/'downto' }
   parexpr(nil, [cdo]+statuset+ss, tp2); { parse ending expression }
   { if the object is a string constant, this must be a character, so
     load it from the address }
   if tp2^.t = tscst then wrtcod(ildichr);
   { check compatible with control variable }
   if not typcmp(tp, tp2) then perror(etypcmp, [], []);
   if tk = cto then begin { output begin 'to's }

      if bt^.t = tchar then wrtcod(ifortchr) { character 'to' for }
      else if bt^.t = tboolean then wrtcod(ifortbol) { boolean 'to' for }
      else wrtcod(ifortint) { integer 'to' for }

   end else begin { output begin 'downto's }

      if bt^.t = tchar then wrtcod(ifordchr) { character 'downto' for }
      else if bt^.t = tboolean then 
         wrtcod(ifordbol) { boolean 'downto' for }
      else wrtcod(ifordint) { integer 'downto' for }

   end;
   wrtlnk(tp); { output for variable }
   expect(cdo, edoexp, statuset+ss, [cdo]); { expect 'do' }
   cdel := false; { set no delete }
   if (tp1^.t in [ticst, tscst, tccst, tenme]) and 
      (tp2^.t in [ticst, tscst, tccst, tenme]) then
      { start and end are constants, check constant condition of delete }
      if tk = cto then 
         cdel := ssgtn(constis(tp1), consti(tp1), constis(tp2), consti(tp2))
      else if tk = cdownto then 
         cdel := ssltn(constis(tp1), consti(tp1), constis(tp2), consti(tp2));
   if cdel then concon := concon+1; { increment delete level }
   parstat(ss); { parse statement }
   if cdel then concon := concon-1; { decrement delete level }
   if tp^.t = tvar then tp^.varf := tp^.varf - 1; { decrement 'for' use count }
   wrtcod(iforend); { for end }
   stalvl := stalvl-1; { remove statement level }
   stalab := stalabs; { restore old label list }
   mrggto(stagto, stagtos) { merge saved and new goto list }

end;

{*******************************************************************************

With statement

   with = 'with' variable [',' variable].. 'do' statement

Parses the with statement.
Error recovery:

1. No id, skip to ',', 'do' or likely statement. Short circuits
variable parse if head id not found.

2. No 'do', skip to ',' 'do', or likely statement.

*******************************************************************************}

procedure parwith(ss: tolkset);

var last:    tolken;  { parsing aid }
    tp:      typptr;  { variable type pointer }
    levels:  integer; { scoping level save }
    sp, sp1: symptr;  { pointers for symbols }
    i:       syminx;  { index for symbol table }
    verr:    errcod;  { last var mode error (unused) }
    stalabs: typptr;  { statement label list save }
    stagtos: gtoptr;  { statement goto list save }
    modsav:  mltptr;  { old module save mark }
    mlp:     mltptr;  { module list pointer }
    wthsav:  wthptr;  { old 'with' entries save }
    wp:      wthptr;  { pointer for 'with' tracking entries }

begin

   if fparse then writeln(':with statement');
   stalvl := stalvl+1; { count statment level }
   stalabs := stalab; { save current label list }
   stagtos := stagto; { save current label list }
   stagto := nil; { clear list for enclosed blocks }
   levels := level; { save old scoping level }
   modsav := uselst; { save uses list mark }
   wthsav := wthlst; { save 'with' entries list mark }
   gettlk; { skip 'with' }
   repeat { variables }

      { parse with variable with threat }
      parvarh([ccma, cdo]+ss, true, false, tp, verr);
      tp := baset(tp); { index base type }
      if not (tp^.t in [trecord, treference]) then
         if fansi then perror(evarmbr, [], [])
         else perror(evarmbrr, [], []);
      level := level + 1; { increase scoping level }
      wthlvl := wthlvl+1; { count "with" level }
      getwth(wp); { push new 'with' level }
      wp^.next := wthlst;
      wthlst := wp;
      wp^.varp := tp; { set base variable }
      if tp^.t = trecord then begin { dump the labels into the new scope }

         sp := tp^.recl; { index top of field label list }
         while sp <> nil do begin { place a label in symbol table }

            { because this symbol list may be placed into the symbol table
              multiple times, we use copies of the symbols to place in table,
              using the original list as a "prototype" }
            getsym(sp1); { get a new symbol }
            sp1^ := sp^; { copy contents }
            sp1^.lvl := level; { set the scope for label }
            i := hash(sp1^.lab^, 0, symmax); { find the top entry }
            sp1^.next := uselst^.modp^.symtbl[i]; { place the next entry link }
            uselst^.modp^.symtbl[i] := sp1; { plant our symbol }
            sp := sp^.rnxt { index next symbol in record list }

         end

      end else if tp^.t = treference then 
         pshbas(tp^.reft); { push classes into scope }
      wrtcod(iwthbgn); { generate with begin }
      wrtlnk(tp); { output record or reference type }
      if (nxttlk <> ccma) and (nxttlk <> cdo) then
         { 'do' or ',' expected }
         perror(edocmexp, [ccma, cdo]+statuset+ss, [cdo]);
      last := nxttlk; { save last tolken }
      if nxttlk = ccma then gettlk { skip ',' }
         
   { until no more possible }
   until not (last in [ccma, cidentifier]);
   if nxttlk = cdo then gettlk; { skip 'do' }
   parstat(ss); { parse statement }
   while level <> levels do begin { back out 'with' levels }

      level := level-1; { back out a level }
      wthlvl := wthlvl-1; { remove "with" level }
      wrtcod(iwthend) { generate with end }
      
   end;
   if tp^.t = trecord then
      { purge all record labels from symbol table, don't cross modules }
      for i := 1 to symmax do begin { traverse the symbols head }
      
         sp := uselst^.modp^.symtbl[i]; { index the chain head }
         while sp <> nil do { flush up top symbols }
            if sp^.lvl > level then begin { symbol scope greater than present }
          
               sp1 := uselst^.modp^.symtbl[i]; { index top symbol }
               uselst^.modp^.symtbl[i] := sp^.next; { gap chain head }
               { because our symbols contain just a copy of the real symbol base
                 pointer, we have to kill the reference. otherwise, this would
                 be returned (incorrectly) to free storage }
               sp1^.lab := nil; { kill symbol reference }
               putsym(sp1); { release entry }
               sp := uselst^.modp^.symtbl[i] { load the new top }
        
            end else sp := nil; { stop the search }

      end
   else if tp^.t = treference then 
      { remove classes from uses stack and dispose }
      while uselst <> modsav do begin
     
         mlp := uselst; { index top of uses list }
         uselst := uselst^.next; { remove symbols module from uses stack }
         putmlt(mlp) { dispose of entry }
     
      end;
   { remove all 'with' levels added }
   while wthlst <> wthsav do begin { remove entries }

      wp := wthlst; { index top of list }
      wthlst := wthlst^.next; { gap top of list }
      putwth(wp) { release entry }

   end;
   stalvl := stalvl-1; { remove statement level }
   stalab := stalabs; { restore old label list }
   mrggto(stagto, stagtos) { merge saved and new goto list }

end;

{*******************************************************************************

Goto statement

   gotostat = 'goto' integer | 'goto' identifier

Parses and generates a goto statement. Accepts a tolken skip set.
Error recovery:

1. If the label is missing or the wrong type, skips to the
next likey statement.

*******************************************************************************}

procedure pargoto(ss: tolkset); 

var sp:      symptr; { symbol pointer }
    gp:      gtoptr; { goto pointer }

{ find previous label }

function fndlab(lt: typptr): typptr;

var tp: typptr; { type entry pointer }

begin

   tp := stalab; { index top of label list }
   while (tp <> nil) and (tp <> lt) do tp := tp^.lnxt; { next label }

   fndlab := tp { return result }

end;

begin

   if fparse then writeln(':goto statement');
   gettlk; { skip 'goto' }
   if (nxttlk = cinteger) or ((nxttlk = cidentifier) and not fansi) then begin

      if nxttlk = cinteger then begin { process numeric label }

         numlab(nxtint, nxtlab); { convert and normalize label number }
         if nxtint > 9999 then { greater than ansi max ? }
            perror(einvgln, [], [], nxtlab); { invalid label number }

      end;
      find(nxtlab, sp); { lookup symbol }
      if (sp^.typ^.t <> tlab) and (sp^.typ^.t <> tudf) then { not a label }
         perror(esymtyp, [], [], nxtlab);
      if sp^.typ^.t = tlab then begin { is a label }

         sp^.typ^.lref := sp^.typ^.lref + 1; { count 'goto' references }
         { check 'goto' target statment level is valid }
         if sp^.typ^.slvl > stalvl then perror(egtolvl, [], []); { invalid }
         { set minimum reference statement level for errors }
         if stalvl < sp^.typ^.mlvl then sp^.typ^.mlvl := stalvl;
         { check if the label appears in a different block level than the
           goto statement. If so, we flag the label as referenced by an
           external block }
         if sp^.lvl <> level-wthlvl then sp^.typ^.extr := true;
         if sp^.typ^.ldef and not sp^.typ^.extr then 
            { Label is defined, but not external block. Check label is enclosed
              in statements. }
            if fndlab(sp^.typ) = nil then perror(egtoenc, [], []);
         getgto(gp); { get a new goto entry }
         gp^.lab := sp^.typ; { point to label entry }
         gp^.next := stagto; { push onto goto list }
         stagto := gp

      end;
      gettlk; { skip label }
      wrtcod(igoto); { goto }
      wrtlnk(sp^.typ) { output label }

   end else { process error }
      if fansi then perror(eintexp, statuset+ss, []) { no integer }
      else perror(eilexp, statuset+ss, []) { no integer/label }

end;

{*******************************************************************************

Try statement

   trystat = 'try' expr 'except' statement [ 'else' statement ]

Parses and generates a statement. Accepts a tolken skip set.
Error recovery:

1. Missing expression or trash on expression is recovered by
'except', 'else' or likely statement resync.

2. Missing 'except' is resynced by likely statement.

3. Missing 'else', respell or leave to upper level to become
a sequential statement (since all statements are ultimately 
contained within a block).

*******************************************************************************}

procedure partry(ss: tolkset);

var last:    tolken; { parser aid }
    stalabs: typptr; { statement label list save }
    stagtos: gtoptr; { statement goto list save }
    verr:    errcod; { last var mode error (unused) }
    tp:      typptr; { type pointer }

begin

   if fparse then writeln(':try statement');
   stalvl := stalvl+1; { count statment level }
   stalabs := stalab; { save current label list }
   stagtos := stagto; { save current label list }
   stagto := nil; { clear list for enclosed blocks }
   gettlk; { skip 'try' }
   wrtcod(itrybgn); { try begin }
   repeat { statements }

      parstat([cscn, cexcept]+statuset+ss); { parse statement }
      if (nxttlk <> cscn) and (nxttlk <> cexcept) and (nxttlk <> con) then
         { 'except' or 'on' or ';' expected }
         perror(eexsconexp, [cscn, cexcept, con, celse]+statuset+ss, [cexcept]);
      last := nxttlk; { save last tolken }
      if nxttlk = cscn then gettlk { skip ';' }

   { until not ';' or likely statement }
   until not (last in [cscn]+statuset);
   stalvl := stalvl-1; { remove statement level }
   stalab := stalabs; { restore old label list }
   mrggto(stagto, stagtos); { merge saved and new goto list }
   while nxttlk = con do begin { process any specific exceptions }

      gettlk; { skip 'on' }
      wrtcod(itryexpspc); { try exception specific statement }
      parvarh([crparen]+ss, false, false, tp, verr); { parse parameter }
      if tp^.t <> texception then 
         perror(embexp, [], []); { must be exception variable }
      { expect 'except' }
      expect(cexcept, eexexp, [cexcept, celse]+statuset+ss, [cexcept]);
      wrtcod(itryexpspcbgn); { try exception specific statement }
      stalvl := stalvl+1; { count statment level }
      stalabs := stalab; { save current label list }
      stagtos := stagto; { save current label list }
      stagto := nil; { clear list for enclosed blocks }
      parstat([celse]+ss); { parse statment }
      stalvl := stalvl-1; { remove statement level }
      stalab := stalabs; { restore old label list }
      mrggto(stagto, stagtos); { merge saved and new goto list }
      if (nxttlk <> cscn) and (nxttlk <> cexcept) and (nxttlk <> con) then
         { 'except' or 'on' or ';' expected }
         perror(eexsconexp, [cscn, cexcept, con, celse]+statuset+ss, [cexcept]);
      last := nxttlk; { save last tolken }
      if nxttlk = cscn then gettlk { skip ';' }
      
   end;
   if nxttlk = cexcept then begin 

      { we were properly terminated }
      gettlk; { skip 'except' }
      wrtcod(itryexp); { try exception statement }
      stalvl := stalvl+1; { count statment level }
      stalabs := stalab; { save current label list }
      stagtos := stagto; { save current label list }
      stagto := nil; { clear list for enclosed blocks }
      parstat([celse]+ss); { parse statment }
      stalvl := stalvl-1; { remove statement level }
      stalab := stalabs; { restore old label list }
      mrggto(stagto, stagtos) { merge saved and new goto list }

   end;
   { check if we have a candidate for an 'else' misspell }
   chktkm([celse]); { check possible misspelled tolken }
   if nxttlk = celse then begin { 'else' clause }

      gettlk; { skip 'else' }
      wrtcod(ielse); { else }
      stalvl := stalvl+1; { count statment level }
      stalabs := stalab; { save current label list }
      stagtos := stagto; { save current label list }
      stagto := nil; { clear list for enclosed blocks }
      parstat(ss); { parse statment }
      stalvl := stalvl-1; { remove statement level }
      stalab := stalabs; { restore old label list }
      mrggto(stagto, stagtos) { merge saved and new goto list }

   end;
   wrtcod(itryend) { try end }

end;

{*******************************************************************************

Parse procedure/function call

   procfncstat = identifier [ '(' expr [ ',' expr ].. ')' ]

Parses and generates a procedure or function call. Accepts a 
tolken skip set. Expects the identifier to already have been 
parsed.
Error recovery:

1. Missing ',', skip to likely expression, ')', or input set.

2. Missing ')', skip to input set.

*******************************************************************************}

procedure parprcfnc(    proc:   boolean; { is a procedure/function }
                        ss:     tolkset; { skip set }
                        inhatt: boolean; { inherited attribute }
                        methld: boolean; { generate a method leader }
                        pp:     typptr;  { procedure/function pointer }
                    var tp:     typptr); { return type }

var pl:     typptr;  { parameter list pointer }
    sp:     symptr;  { symbol pointer }
    tp1:    typptr;  { pointer for types }
    bt:     typptr;  { base type }
    npe:    boolean; { no parameter error registered }
    over:   boolean; { parsing an overload procedure or function }
    pn:     integer; { parameter logical number }
    pvar:   boolean; { parameter was parsed as variable reference }
    verr:   errcod;  { last var mode error }
    winlst: winptr;  { procedure/function winnow list }
    winnil: boolean; { winnow list ran dry }
    wp:     winptr;  { pointer for winnow entries }
    lab:    labl;    { label for undefines }

{ index the logical parameter }

procedure fndpar(    tp: typptr;  { procedure or function entry }
                     pn: integer; { logical parameter to index }
                 var pl: typptr); { returns parameter entry }

var pc: integer; { parameter counter }

begin

   { if we have been called without a proper head, this means that we were
     called because of what looked like a parameter list. An error has already
     been output, so just parse parameters only }
   if not (tp^.t in [tproc, tfunc, tpproc, tpfunc]) then begin

      pl := nil; { set no parameter list }
      npe := true { set error already occurred }

   end else begin { index }

      pc := 1; { set 1st parameter }
      case tp^.t of { index top of parameter list }

         tproc:  pl := tp^.prcp;
         tfunc:  pl := tp^.fncp;
         tpproc: pl := tp^.pprp;
         tpfunc: pl := tp^.pfnp 

      end;
      while (pc <> pn) and (pl <> nil) do begin

         case pl^.t of { find next entry }

            tpar:   pl := pl^.parn;
            tvpar:  pl := pl^.vprn;
            twpar:  pl := pl^.wprn;
            tpproc: pl := pl^.pprn;
            tpfunc: pl := pl^.pfnn

         end;
         pc := pc+1 { count }

      end
      { if we run off the end, pl will be null, which will cause errors elsewhere }

   end

end;

{ print procedure/function entry, a diagnostic }

{

procedure prtfproc(tp: typptr);

var pp: typptr;

begin

   if tp^.t = tproc then begin

      write('procedure ');
      if tp^.prch <> nil then listlab(tp^.prch) else listlab(tp);
      pp := tp^.prcp

   end else if tp^.t = tfunc then begin

      write('function ');
      if tp^.fnch <> nil then listlab(tp^.fnch) else listlab(tp);
      pp := tp^.fncp

   end else error(esflt36, true);
   while pp <> nil do begin

      case pp^.t of

         tpar: begin listlab(pp^.part); pp := pp^.parn end;
         tvpar: begin listlab(pp^.vprt); pp := pp^.vprn end;
         twpar: begin listlab(pp^.wprt); pp := pp^.wprn end;
         tpproc: begin write('procedure param'); pp := pp^.pprn end;
         tpfunc: begin write('function param'); pp := pp^.pfnn end

      end;
      if pp <> nil then write(',')

   end;
   if tp^.t = tfunc then listlab(tp^.fncr);
   writeln

end;

}

{ print procedures and functions in winnow list, a diagnostic }

{

procedure prtwin;

var wp: winptr;

begin

   writeln('Winnow list');
   wp := winlst;
   while wp <> nil do begin

      prtfproc(wp^.prcfnc);
      wp := wp^.next

   end

end;

}

{ process the winnow list by type }

type wincod = (wend,    { list must end }
               wmore,   { list must have more }
               wproc,   { is a procedure }
               wfunc,   { is a function }
               wpproc,  { next must be procedure parameter }
               wnpproc, { not procedure parameter }
               wpfunc,  { next must be function parameter }
               wnpfunc, { not function parameter }
               wpval,   { must be value parameter }
               wpview,  { must be view parameter }
               wpvar,   { must be var parameter }
               wtype);  { next must be type }

procedure winnow(wt: wincod;  { winnow mode }
                 mp: typptr); { type match entry }

var wp, wp1, lp:  winptr; { winnow entry pointers }

{ check parameter matches }

function match(tp: typptr): boolean;

var pp: typptr; { parameter pointer }
    f:  boolean; { match flag }
                                 
begin

   fndpar(tp, pn, pp); { index parameter to check }
   case wt of { match type }

      wend:   f := pp = nil;        { end of list }
      wmore:  f := pp <> nil;       { not end of list }
      wproc:  f := (tp^.t = tproc) or (tp^.t = tpproc); { is a procedure }
      wfunc:  f := (tp^.t = tfunc) or (tp^.t = tpfunc); { is a function }
      wpproc:  begin { procedure parameter }

         if pp^.t = tpproc then begin { is procedure parameter }

            f := fndcon(pp^.pprp, mp) { match parameter lists }

         end else f := false { no match }

      end;
      wnpproc: f := pp^.t <> tpproc; { not procedure parameter }
      wpfunc:  f := pp^.t = tpfunc;  { function parameter }
      wnpfunc: f := pp^.t <> tpfunc; { function parameter }
      wpval:   f := pp^.t = tpar;    { value parameter }
      wpview:  f := pp^.t = twpar;   { view parameter }
      wpvar:   f := pp^.t = tvpar;   { var parameter }
      { For type matching, we use the broadest type match. Our purpose here is
        not to verify typing, but winnow down to minimum. Since types of
        overloads are to be unique, this works. }
      wtype:   f := typcmp(pp, mp) or typcmpa(pp, mp); { type match }

   end;

   match := f { return result }

end;
   
begin

   { skip leading unmatched entries, but leave one in list }
   while not match(winlst^.prcfnc) and not winnil do begin { discard }

      if winlst^.next <> nil then begin { more than one entry on list }

         wp := winlst; { index top entry }
         winlst := winlst^.next; { gap out }
         putwin(wp) { free entry }

      end else winnil := true { set list ran empty }

   end;
   wp := winlst^.next; { index next entry }
   lp := winlst; { set last }
   while wp <> nil do begin { traverse remaining list }

      if not match(wp^.prcfnc) then begin { list entry does not match, delete }

         lp^.next := wp^.next; { gap out of list }
         wp1 := wp; { save entry }
         wp := wp^.next; { index next }
         putwin(wp1) { release entry }

      end else begin { advance in list }

         lp := wp; { set new last }
         wp := wp^.next { index next }

      end

   end;
   pp := winlst^.prcfnc { reset top procedure pointer }

end;

{ process standard value parameter }

procedure prcpar;

begin

   if (tp^.t in [tscst, trecord, tarray, tgarry]) then begin

      { it's a structured value parameter. parexpr left that as
        an address, as it should do. so we must trully load it
        onto the stack as a copy }
      if (tp^.t = tgarry) and (pl^.part^.t <> tgarry) then 
         begin { its a general array passed to a fixed array }

         { a value parameter accepting a general array, the array
           must be converted to fixed. then it can be loaded as
           a fixed }
         wrtcod(icvtgtf); { convert tagged to fixed pointer }
         wrtlnk(pl^.part) { output fixed type }

      end;
      { if a string constant is being passed to a non-array
        parameter, then this has to be a character constant. so
        that must be fetched from it's address }
      if (pl^.part^.t <> tgarry) and (pl^.part^.t <> tarray) and
         (tp^.t = tscst) then wrtcod(ildichr)
      else if pl^.part^.t = tgarry then begin { general array parameter }

         if tp^.t <> tgarry then begin 
 
            { a fixed array is passed to a general array parameter,
              we must convert the simple pointer on stack to a tagged
              one }
            if pl^.part^.gart^.t = tgarry then { complex }
               wrtcod(icvtftm) { convert fixed to complex tagged pointer }
            else { simple }
               wrtcod(icvtftg); { convert fixed to tagged pointer }
            wrtlnk(tp) { write fixed type }
     
         end;
         { Now we must create a copy to create a "virtual" value parameter. This
           allows it to appear as a var parameter to the procedure, but only the
           copy is modified. }       
         if pl^.part^.gart^.t = tgarry then { complex }
            wrtcod(icpymgp) { copy out complex tagged structure }
         else { simple }
            wrtcod(icpytgp); { copy out simple tagged structure }
         wrtlnk(tp) { write type }

      end else begin { other structure }

         wrtcod(ildisrc); { load indirect structure }
         wrtlnk(tp) { write type }

      end

   end;
   { check for real from int cases }
   bt := baset(pl^.part); { get base type }
   if intt(tp) then begin { parameter value is integer }

      { convert to real }
      if bt^.t = treal then wrtcod(icvtitr)
      else if bt^.t = tsreal then begin { short real }

         wrtcod(icvtitr); { convert to real }
         wrtcod(icvtrtsr) { convert to short real }

      end

   end else if (bt^.t = tsreal) and realt(tp) then
      wrtcod(icvtrtsr) { convert to short real }

end;

{ process view parameter }

procedure prcwpar;

begin

   if (pl^.wprt^.t = tgarry) and (tp^.t <> tgarry) then begin

      { a fixed array is passed to a general array parameter,
        we must convert the simple pointer on stack to a tagged
        one }
      if pl^.wprt^.gart^.t = tgarry then { complex }
         wrtcod(icvtftm) { convert fixed to complex tagged pointer }
      else { simple }
         wrtcod(icvtftg); { convert fixed to tagged pointer }
      wrtlnk(tp) { write fixed type }

   end else if (pl^.wprt^.t <> tgarry) and (tp^.t = tgarry) then
      begin

      { a general array passed to a fixed view, convert pointer
        to fixed }
      wrtcod(icvtgtf); { convert tagged to fixed pointer }
      wrtlnk(pl^.wprt) { output fixed type }

   end;
   { if a string constant is being passed to a non-array 
     parameter, then this has to be a character constant. so
     that must be fetched from it's address }
   if (pl^.wprt^.t <> tgarry) and (pl^.wprt^.t <> tarray) and
      (tp^.t = tscst) then wrtcod(ildichr);
   { check for real from int cases }
   bt := baset(pl^.part); { get base type }
   if intt(tp) then begin { parameter value is integer }

      { convert to real }
      if bt^.t = treal then wrtcod(icvtitr)
      else if bt^.t = tsreal then begin { short real }

         wrtcod(icvtitr); { convert to real }
         wrtcod(icvtrtsr) { convert to short real }

      end

   end else if (bt^.t = tsreal) and realt(tp) then
      wrtcod(icvtrtsr) { convert to short real }

end;

{ process procedure parameter }

procedure prcppar;

begin

   { check types are congruous }
   if tp1^.t = tproc then begin { procedure type }

      if tp1^.prcd <> pfnil then perror(esfnprp, [], [])
      else { check types congruous }
         chkcon(pl^.pprp, tp1^.prcp)

   end else { procedure parameter type }
      chkcon(pl^.pprp, tp1^.pprp); { check types congruous }
   { load procedure address }
   wrtcod(ilodadr); { output address load operator }
   wrtlnk(tp1); { output entry to load }
   { if the procedure is itself a parameter, load it's address }
   if tp1^.t = tpproc then wrtcod(ildiptr) { load pointer }

end;

{ process function parameter }

procedure prcfpar;

begin

   if tp1^.t = tfunc then begin { function }

      { check attempt to pass system function as parameter }
      if tp1^.fncd <> pfnil then perror(esfnprp, [], [])
      else begin { not system function }

         { check types are congruous }
         chkcon(pl^.pfnp, tp1^.fncp);
         { check result types are not equal, and not
           undefined }
         if (actt(pl^.pfnr) <> actt(tp1^.fncr)) and 
            (pl^.pfnr^.t <> tudf) and 
            (tp1^.fncr^.t <> tudf) then 
               perror(efnncon, [], [])

      end

   end else begin { function parameter }

      { check types are congruous }
      chkcon(pl^.pfnp, tp1^.pfnp);
      { check result types are not equal, and not undefined }
      if (actt(pl^.pfnr) <> actt(tp1^.pfnr)) and 
         (pl^.pfnr^.t <> tudf) and 
         (tp1^.pfnr^.t <> tudf) then 
            perror(efnncon, [], [])

   end;
   { load function address }
   wrtcod(ilodadr); { output address load operator }
   wrtlnk(tp1); { output entry to load }
   { if the function is itself a parameter, load it's address }
   if tp1^.t = tpfunc then wrtcod(ildiptr) { load pointer }
   
end;

{ process VAR parameter }

procedure prcvpar;

begin

   { check type exact match for parameter }
   if (pl^.vprt <> tp) and (tp^.t <> tudf) and 
      (pl^.vprt^.t <> tudf) and
      not (typcmp(pl^.vprt, tp) and 
           ((pl^.vprt^.t = tgarry) or (tp^.t = tgarry))) then
      perror(evarcmp, [], []); { no match }
   if (pl^.vprt^.t = tgarry) and (tp^.t <> tgarry) then begin
   
      { a fixed array is passed to a general array parameter,
        we must convert the simple pointer on stack to a tagged
        one }
      if pl^.wprt^.gart^.t = tgarry then { complex }
         wrtcod(icvtftm) { convert fixed to complex tagged pointer }
      else { simple }
         wrtcod(icvtftg); { convert fixed to tagged pointer }
      wrtlnk(tp) { write fixed type }
   
   end else if (pl^.vprt^.t <> tgarry) and (tp^.t = tgarry) then
      begin
   
      { a general array passed to a fixed view, convert pointer
        to fixed }
      wrtcod(icvtgtf); { convert tagged to fixed pointer }
      wrtlnk(pl^.vprt) { output fixed type }
   
   end

end;

begin

   if fparse then writeln(':procedure/function call');
   winlst := nil; { clear winnow list }
   over := chkovld(pp); { check and flag overload }
   if over then begin

      { If its an overload procedure or function, then we collect all of the
        listed procedure or function overload types for it into a "winnow list".
        The purpose of this is to successively winnow the list, using parameter
        type matching, until only one is left. }
      if pp^.t = tfunc then tp1 := pp^.fnco else tp1 := pp^.prco; { index 1st }
      tp1 := pp; { index 1st procedure/function }
      while tp1 <> nil do begin { traverse list }

         getwin(wp); { get a new winnow entry }
         wp^.prcfnc := tp1; { place }
         wp^.next := winlst; { push onto list }
         winlst := wp;
         { advance in overload list }
         if tp1^.t = tfunc then tp1 := tp1^.fnco else tp1 := tp1^.prco

      end

   end;
   winnil := false; { set winnow list not empty }
   npe := false; { set no parameter error registered }
   { check is a method }
   if chkmtd(pp) then begin

      if methld then begin { method leader was not already generated }

         { if it is a method, and was not accessed via object reference, we need
           to generate a self reference load and offset }
         wrtcod(ilodasr); { load class self reference }
         case curcls^.t of { class }
         
            { pick up self reference variable }
            tclass:  wrtlnk(curcls^.clsr); { class }
            tatom:   wrtlnk(curcls^.atmr); { atom }
            tthread: wrtlnk(curcls^.thdr); { thread }
         
         end;
         wrtcod(iobjmem); { output object member offset }
         wrtlnk(curcls); { output class type }
         wrtlnk(pp) { output member }

      end else if inhatt then perror(einhuse, [], []) { bad use of 'inherited' }

   end;
   { Output procedure/function parameter start mark. Note that at the start of
     the parameter list build, we don't actually know which procedure or 
     function we will execute, because of overloads. }
   if (pp^.t = tproc) or (pp^.t = tpproc) then
         wrtcod(iprcbgn) { generate procedure parameter begin }
   else if (pp^.t = tfunc) or (pp^.t = tpfunc) then
         wrtcod(ifncbgn); { generate function parameter begin }
   pn := 1; { set logical parameter number }
   if over then begin { overload }

      if proc then winnow(wproc, nil) { winnow for procedure }
      else winnow(wfunc, nil); { winnow for function }

   end;
   if nxttlk = clparen then begin { parameter list }

      repeat

         { skip only '(' or ',' in case of headless expression }
         if (nxttlk = clparen) or (nxttlk = ccma) then
            gettlk; { skip '(' or ',' }
         { if its an overload, winnow list for headers that have no more
           parameters }
         if over then winnow(wmore, nil);
         fndpar(pp, pn, pl); { find parameter link by logical number }
         if pl = nil then begin { parameter does not exist }

            if not npe then begin { no error registered }

               if over then perror(enfncmat, [], []) { no overload match }
               else perror(etmpar, [], []); { too many parameters }
               npe := true { set error registered }

            end;
            { we don't have a prototype, but try parsing an expression
              just to keep the parser moving }
            parexpr(nil, [ccma, crparen]+exprset+ss, tp)

         end else begin { parameter exists }

            if over then begin { we are in an overload }

               { Overload parameters are processed differently. Since we must
                 use the resulting type of the expression or var that comes
                 from evaluating the expression, we can't process it differently
                 depending on the parameter type, as per a normal parameter.
                 Instead, we sucessively evaluate the head, and use that to find
                 our way forward.

                 This kind of processesing is reserved for overloads because
                 it may change error processing and recovery. }
               if (nxttlk = cidentifier) or (nxttlk = cself) then 
                  begin { we have a variable tip }

                  { parse variable leader }
                  parvarlead([ccma, crparen]+exprset+ss, sp, tp1);
                  tp1 := actt(tp1); { index type }
                  { check procedure label }
                  if (tp1^.t in [tproc, tpproc]) and not chkovld(tp1) then begin

                     { its a procedure parameter }
                     if tp1^.t = tproc then winnow(wpproc, tp1^.prcp)
                     else winnow(wpproc, tp1^.pprp);
                     { check no procedure matches }
                     if winnil then begin

                        if not npe then perror(enfncmat, [], []);
                        npe := true { set error registered }

                     end;
                     { check procedure to be passed is itself an overload }
                     if chkovld(tp1) then perror(epfparov, [], []);
                     fndpar(pp, pn, pl); { index parameter }
                     prcppar { process procedure parameter }
                     
                  end else if (tp1^.t in [tfunc, tpfunc]) and 
                              not chkovld(tp1) then begin

                     { must check if the function is a system special }
                     if sysspc(tp1) then begin

                        { Its a system special function. The bad news is that
                          there is really no type until it is evaluated. For
                          example, pred/succ is the same as the operand type, 
                          as are abs and sqr. The good news is that it must be
                          and expression. So we go ahead and evaluate that. }
                        winnow(wnpproc, nil);
                        winnow(wnpfunc, nil);
                        { process qualident as var }
                        parvar([ccma, crparen]+exprset+ss, sp, false, tp1, 
                               verr);
                        { parse as expression using existing leader }
                        parexpr(tp1, [ccma, crparen]+exprset+ss, tp);
                        winnow(wtype, tp); { match for assignment type }
                        { check no function matches }
                        if winnil then begin
                        
                           if not npe then perror(enfncmat, [], []);
                           npe := true { set error registered }
                        
                        end;
                        fndpar(pp, pn, pl); { index parameter }
                        { check VAR was specified }
                        if pl^.t = tvpar then perror(embvarpar, [], []);
                        { now atoms are on stack, structures addressed. The net 
                          difference between view and value parameters are that
                          view parameters leave structures addressed }
                        if pl^.t = tpar then prcpar { handle value cases }
                        else if pl^.t = twpar then prcwpar { handle view cases }

                     end else begin

                        { this could be a function parameter or the start of an
                          expression. Winnowing for type will reduce this, since
                          the same position parameter with a function parameter
                          of that type and another overload with a non-function
                          parameter of that type are not both allowed to 
                          exist. }
                        winnow(wtype, tp1); { match for assignment type }
                        { check no function matches }
                        if winnil then begin
                        
                           if not npe then perror(enfncmat, [], []);
                           npe := true { set error registered }
                        
                        end;
                        fndpar(pp, pn, pl); { index parameter }
                        { We are down to one routine, handle it by direction from
                          the parameter list }
                        if pl^.t = tpfunc then begin
                        
                           { check function to be passed is itself an overload }
                           if chkovld(tp1) then perror(epfparov, [], []);
                           gettlk; { next }
                           prcfpar { process function parameter }
                        
                        end else if (pl^.t = tpar) or (pl^.t = twpar) then begin 
                     
                           { process qualident as var }
                           parvar([ccma, crparen]+exprset+ss, sp, false, tp1, verr);
                           { Value parameter or view parameter, parse 
                             expression. }
                           parexpr(tp1, [ccma, crparen]+exprset+ss, tp);
                           { check parameter assignment compatible with value
                             parameter }
                           if not typcmpa(pl, tp) then perror(eparcmp, [], []);
                           { Now atoms are on stack, structures addressed. The
                             net difference between view and value parameters
                             are that view parameters leave structures
                             addressed }
                           if pl^.t = tpar then prcpar { handle value cases }
                           else if pl^.t = twpar then prcwpar { handle view
                                                                cases }
                     
                        end else begin { VAR parameter. Should always be an
                                         error, because that was an expression
                                         leader. But we let standard parsing
                                         handle it. }
                        
                           { process qualident as var }
                           parvar([ccma, crparen]+exprset+ss, sp, false, tp1, verr);
                           prcvpar { process variable parameter }

                        end
                     
                     end

                  end else begin { var, view or value parameter }

                     pvar := true; { set default to variable reference }
                     if tp1^.t in [tvar, tfix, tpar, tvpar, twpar, tfield, 
                                   tftag] then begin { variable reference }

                        { process qualident as var }
                        parvar([ccma, crparen]+exprset+ss, sp, false, tp, verr);
                        { If that didn't end the parameter, then we guessed
                          wrong, and its an expression. We parse as an
                          expression with the leader already provided. }
                        if not (nxttlk in [ccma, crparen]) then begin

                           { parse expression }
                           parexpr(tp, [ccma, crparen]+exprset+ss, tp);
                           pvar := false { set not variable reference }

                        end

                     end else begin { expression }

                        { process qualident as var }
                        parvar([ccma, crparen]+exprset+ss, sp, false, tp, verr);
                        { parse expression }
                        parexpr(tp, [ccma, crparen]+exprset+ss, tp);
                        pvar := false { set not variable reference }

                     end;
                     { now we have the complete actual parameter type }
                     winnow(wtype, tp); { match for assignment type }
                     { check no function matches }
                     if winnil then begin

                        if not npe then perror(enfncmat, [], []);
                        npe := true { set error registered }

                     end;
                     fndpar(pp, pn, pl); { index parameter }
                     { Now, we absolutely must know what mode the parameter is,
                       value, var, or view. So the list is winnowed for mode 
                       agreement }
                     if pl^.t = tpar then winnow(wpval, nil)
                     else if pl^.t = twpar then winnow(wpview, nil)
                     else winnow(wpvar, nil);
                     if (pl^.t = tpar) or (pl^.t = twpar) then 
                        begin { value or view parameter }
                     
                        { if it was parsed as a var, we need to expand to a full
                          expression }
                        if pvar then 
                           parexpr(tp, [ccma, crparen]+exprset+ss, tp);
                        { check parameter assignment compatible with value 
                          parameter }
                        if not typcmpa(pl, tp) then perror(eparcmp, [], []);
                        { now atoms are on stack, structures addressed. The net 
                          difference between view and value parameters are that
                          view parameters leave structures addressed }
                        if pl^.t = tpar then prcpar { handle value cases }
                        else if pl^.t = twpar then prcwpar { handle view cases }
                     
                     end else begin { VAR parameter }

                        { error for variable parameter not conforming to var
                          rules }
                        if not pvar then perror(embvarpar, [], []);
                        { if there is a delayed var mode error, print that }
                        if verr <> enull then perror(verr, [], []);
                        threaten(sp, tp1); { process threat to variable }
                        prcvpar { process variable parameter }

                     end

                  end
                  
               end else begin { no variable leader }

                  { since it was not a function or procedure id, we eliminate 
                    these forms }
                  winnow(wnpproc, nil);
                  winnow(wnpfunc, nil);
                  { parse as expression }
                  parexpr(nil, [ccma, crparen]+exprset+ss, tp);
                  winnow(wtype, tp); { match for assignment type }
                  { check no function matches }
                  if winnil then begin

                     if not npe then perror(enfncmat, [], []);
                     npe := true { set error registered }

                  end;
                  fndpar(pp, pn, pl); { index parameter }
                  { check VAR was specified }
                  if pl^.t = tvpar then perror(embvarpar, [], []);
                  { now atoms are on stack, structures addressed. The net 
                    difference between view and value parameters are that view
                    parameters leave structures addressed }
                  if pl^.t = tpar then prcpar { handle value cases }
                  else if pl^.t = twpar then prcwpar { handle view cases }
               
               end   
           
            end 
            { normal (non overload) cases }
                else if pl^.t = tpproc then begin { procedure parameter }

               if nxttlk <> cidentifier then { id expected }
                  perror(eidnexp, [ccma, crparen]+exprset+ss, []);
               if nxttlk = cidentifier then begin { found }

                  { parse procedure name as qualified identifier }
                  parqualident([ccma, crparen]+exprset+ss, true, true, true, '',
                               sp, lab);
                  tp1 := sp^.typ; { index type }
                  if chkovld(tp1) then perror(epfpovl, [], [])
                  else begin { not overload }

                     { check procedure label }
                     if (tp1^.t <> tproc) and (tp1^.t <> tpproc) then
                        perror(embproc, [], [], sp^.lab^) { must be procedure }
                     else prcppar { type ok }

                  end

               end

            end else if pl^.t = tpfunc then begin { function parameter }

               if nxttlk <> cidentifier then { id expected }
                  perror(eidnexp, [ccma, crparen]+exprset+ss, []);
               if nxttlk = cidentifier then begin { found }

                  { parse funciton name as qualified identifier }
                  parqualident([ccma, crparen]+exprset+ss, true, true, true, '',
                               sp, lab);
                  tp1 := sp^.typ; { index type }
                  if chkovld(tp1) then perror(epfpovl, [], [])
                  else begin { not overload }

                     { check function label }
                     if (tp1^.t <> tfunc) and (tp1^.t <> tpfunc) then
                        perror(embfunc, [], [], sp^.lab^) { must be procedure }
                     else prcfpar { type ok }

                  end

               end

            end else if (pl^.t = tpar) or (pl^.t = twpar) then begin 

               { value parameter or view parameter, parse expression }
               parexpr(nil, [ccma, crparen]+exprset+ss, tp);
               { check parameter assignment compatible with value parameter }
               if not typcmpa(pl, tp) then perror(eparcmp, [], []);
               { now atoms are on stack, structures addressed. The net 
                 difference between view and value parameters are that view
                 parameters leave structures addressed }
               if pl^.t = tpar then prcpar { handle value cases }
               else if pl^.t = twpar then prcwpar { handle view cases }

            end else begin { VAR parameter }

               { parse with variable with threat and parameter flags }
               parvarh([ccma, crparen]+exprset+ss, true, true, tp, verr);
               prcvpar { process variable parameter }

            end

         end;
         pn := pn+1; { advance to next parameter }
         fndpar(pp, pn, pl); { find parameter link by logical number }
         if (nxttlk <> ccma) and (nxttlk <> crparen) then
            { process error }
            perror(erpcmexp, [ccma, crparen]+exprset+ss, [])

      { until not ',' or likely expression }
      until not (nxttlk in [ccma]+exprset);
      if nxttlk = crparen then gettlk { skip ')' }

   end;
   { if its an overload, winnow list for headers that have no more 
     parameters }
   if over then begin

      winnow(wend, nil);
      { check down to only one header now }
      if (winlst^.next <> nil) and not pp^.prcx then begin

         { uncomment next for a winnow list printout }

         { prtwin(pp); }

         error(esflt30, true)

      end

   end;
   fndpar(pp, pn, pl); { find parameter link by logical number }
   if pl <> nil then { more parameters remain }
      if over then begin

         if not npe then perror(enfncmat, [], []); { no overload match }
         npe := true { set error registered }

      end else perror(etlpar, [], []); { too few parameters }
   { set return type for function, undefined if procedure or unknown }
   if pp^.t = tfunc then tp := pp^.fncr
   else if pp^.t = tpfunc then tp := pp^.pfnr
   else tp := gbludf;
   { check inherited refers to overriden function }
   if inhatt and ((pp^.t = tproc) or (pp^.t = tfunc)) then begin

      if pp^.t = tproc then begin { procedure }

         { check any override }
         if pp^.prcz = nil then perror(ecalmbor, [], [])
         { check override exists in current class }
         else if ovrcntcls(pp, curcls) = 0 then perror(eovrnic, [], [])

      end else begin { function }

         { check any override }
         if pp^.fncz = nil then perror(ecalmbor, [], [])
         { check override exists in current class }
         else if ovrcntcls(pp, curcls) = 0 then perror(eovrnic, [], [])

      end

   end;
   { check inherited refers to procedure or function parameter }
   if inhatt and ((pp^.t = tpproc) or (pp^.t = tpfunc)) then
      perror(einhpfp, [], []);
   { check procedure/function parameter }
   if (pp^.t = tpproc) or (pp^.t = tpfunc) then begin

      { procedure/function parameter, must load address }
      wrtcod(ilodadr); { output address load operator }
      wrtlnk(pp); { output entry to load }
      wrtcod(ildiptr) { load the parameter }

   end;
   { generate call code }
   if pp^.t in [tproc, tfunc, tpproc, tpfunc] then begin

      case pp^.t of { type }

         { For procedure/function fixed call, encode according to inherited 
           mode. }
         tproc:  begin

            if pp^.classt <> nil then begin { method call }

               if inhatt then wrtcod(iprcmcalo) else wrtcod(iprcmcal)

            end else begin

               if inhatt then wrtcod(iprccalo) else wrtcod(iprccal)

            end

         end;
         tfunc:  begin

            if pp^.classt <> nil then begin { method call }

               if inhatt then wrtcod(ifncmcalo) else wrtcod(ifncmcal)

            end else begin

               if inhatt then wrtcod(ifnccalo) else wrtcod(ifnccal)

            end

         end;
         { objects don't have an equivalent to procedure/function parameters }
         tpproc: wrtcod(iprccali);
         tpfunc: wrtcod(ifnccali)
      
      end;
      wrtlnk(pp) { output procedure/function entry }

   end

end;

{*******************************************************************************

Parse write procedure

   writeproc = write [ parlist ] | writeln [ parlist ]

   parlist   = '(' item [ ',' item ].. ')'

   item      = expr [ ':' expr [ ':' expr ] ]

Parses and generates a write or writeln procedure. Accepts a 
tolken skip set. The procedure identifier is expected to already
be parsed.
Error recovery:

1. Missing ',', skip to likely expression, ')', or input set.

2. Missing ')', skip to input set.

*******************************************************************************}

procedure parwrite(ss: tolkset; { skip set }
                   dc: prcfnc); { writeln type }

var last:    tolken;  { parsing aid }
    tp, tp1: typptr;  { type pointers }
    bt:      typptr;  { base type }
    fstpar:  boolean; { first parameter flag }
    fs:      typptr;  { output file specification }
    ft:      boolean; { output filetype is text }
    parp:    boolean; { parameter parsed flag }

begin

   if fparse then writeln(':write procedure');
   fstpar := true; { set 1st parameter }
   parp := false; { set no parameters parsed }
   fs := gblout; { default to 'output' file }
   ft := true; { set text type output }
   if not (nxttlk in [clparen, cend, cuntil, cscn, celse]) then
      { no valid next tolken, output same error as next
        level up and attempt to find '(' }
      perror(eedutscelexp, [clparen, cscn, cend, celse]+ss, []);
   if (nxttlk <> clparen) and (dc = pfwrite) then { '(' expected for write }
      perror(elpexp, [clparen]+exprset+ss, []); { '(' expected }
   if nxttlk = clparen then begin { parameter list }

      gettlk; { skip '(' }
      repeat { elements }

         { parse expression (or file variable) }
         parexpr(nil, [ccma, ccln, crparen]+exprset+ss, tp);
         { if the object is a string constant, and a single character, go ahead
           and load this for treatment as a character }
         if (tp^.t = tscst) and chart(tp) then wrtcod(ildichr);
         if filet(tp) then begin { file appears }

            { define output file }
            if not fstpar then perror(efmbfp, [], []); { must be 1st param }
            { check only "text" filetype applied to writeln }
            if (tp^.t = tfile) and (dc = pfwriteln) then 
               perror(embtext, [], []); { must be text file }
            fs := tp; { set output file }
            ft := fs^.t = ttext { set file text status }

         end else begin { write parameter }

            if fstpar and (fs <> nil) then begin

               { 1st parameter, and no file appears, not nil output file }
               { mode is default to 'output' file. Now we must load the output
                 file, and swap the stack so it ends up on the bottom where it
                 belongs }
               wrtcod(ilodadr); { output address load operator }
               wrtlnk(fs); { output entry to load }
               bt := baset(tp); { find base type }
               wrtcod(iswptop); { swap top with second }
               wrtlnk(bt); { output sos type }
               wrtlnk(baset(fs)) { output tos type }
               
            end;
            if ft then begin { validate for text file output }

               bt := baset(tp); { get base type }
               if not ((bt^.t in [tudf, tinteger, tlinteger, tcardinal,
                                  tlcardinal, tchar, tboolean, treal, 
                                  tsreal]) or strt(bt)) then
                  perror(ewrtpar, [], []); { type incorrect for write/writeln }
               { check if the 'output' file has been declared }
               if fs = nil then begin { no 'output' file }
            
                  perror(enohdf, [], []); { no 'output' file }
                  gblout := gbludf; { prevent further default errors }
                  fs := gblout
            
               end else
                  { if we have just used the global output file, count that as a
                    default reference }
                  if fs = gblout then 
                     if gblots <> nil then { there is a symbol for it }
                        gblots^.ref := gblots^.ref + 1; { count refs }
               parp := true { set parameter parsed }
            
            end else begin { validate for typed file output }
            
                if not typcmpa(fs^.filt, tp) then perror(efilcmp, [], []);
                parp := true { set parameter parsed }
            
            end;
            if nxttlk = ccln then begin { field parameter }

               gettlk; { next }
               { check applied to text file }
               if not ft then perror(efldtxt, [], []); { must be applied to text }
               { parse expression }
               parexpr(nil, [ccma, ccln, crparen]+exprset+ss, tp1);
               bt := baset(tp1); { get base type }
               if not (bt^.t in [tudf, tinteger, tlinteger, tcardinal,
                                 tlcardinal]) then { wrong type }
                  perror(efldpar, [], []); { invalid field spec }
               if nxttlk = ccln then begin { fraction parameter }
            
                  gettlk; { next }
                  { check is applied to real parameter }
                  if not (realt(tp) or (tp^.t = tudf)) then 
                     perror(eapreal, [], []); { must be applied to real }
                  { parse expression }
                  parexpr(nil, [ccma, ccln, crparen]+exprset+ss, tp1);
                  bt := baset(tp1); { get base type }
                  if not (bt^.t in [tudf, tinteger, tlinteger, tcardinal,
                                    tlcardinal]) then { wrong type }
                     perror(efrcpar, [], []); { invalid field spec }
                  { write real with field and fraction }
                  wrtcod(iwrtrelfft)
            
               end else begin { fielded parameter }
            
                  bt := baset(tp); { find base type }
                  if bt^.t in [tinteger, tlinteger, tcardinal, tlcardinal] then
                     wrtcod(iwrtintft) { write integer fielded }
                  else if chart(bt) then
                     wrtcod(iwrtchrft) { write character fielded }
                  else if bt^.t = tboolean then
                     wrtcod(iwrtbolft) { write boolean fielded }
                  else if realt(bt) then
                     wrtcod(iwrtrelft) { write real fielded }
                  else if tp^.t = tgarry then
                     wrtcod(iwrtgstft) { write general string fielded }
                  else begin { must be string }

                     wrtcod(iwrtstrft); { write string fielded }
                     wrtlnk(tp) { output type }
            
                  end
            
               end
            
            end else if ft then begin { text file output }
            
               bt := baset(tp); { find base type }
               if bt^.t in [tinteger, tlinteger, tcardinal, tlcardinal] then 
                  wrtcod(iwrtintt) { write integer }
               else if chart(bt) then
                  wrtcod(iwrtchrt) { write character }
               else if bt^.t = tboolean then
                  wrtcod(iwrtbolt) { write boolean }
               else if realt(bt) then
                  wrtcod(iwrtrelt) { write real }
               else if tp^.t = tgarry then
                  wrtcod(iwrtgstt) { write general string }
               else begin { must be string }
            
                  wrtcod(iwrtstrt); { write string }
                  wrtlnk(tp) { output type }

               end
            
            end else begin { write typed file }
            
               bt := baset(tp); { find base type }
               if bt^.t = tsreal then
                  wrtcod(iwrtsrl) { write file short real }
               else if bt^.t = treal then
                  wrtcod(iwrtrel) { write file real }
               else if sett(bt) then wrtcod(iwrtset) { write file set }
               else if boolt(bt) then wrtcod(iwrtbol) { write file boolean }
               else if chart(bt) then 
                  wrtcod(iwrtchr) { write file character }
               else if bt^.t in [tinteger, tlinteger, tcardinal, tlcardinal, tenum, tptr] then
                  begin

                  wrtcod(iwrtint); { write file integer }
                  wrtlnk(fs^.filt) { output type }

               end else begin { must be structured type }
            
                  wrtcod(iwrtsrc); { write file }
                  wrtlnk(tp) { output type }
            
               end

            end

         end;
         fstpar := false; { set not 1st parameter }
         if (nxttlk <> ccma) and (nxttlk <> crparen) then
            { process error }
            perror(erpcmexp, [ccma, ccln, crparen]+exprset+ss, []);
         last := nxttlk; { save last tolken }
         if nxttlk = ccma then gettlk { skip ',' }

      { until not ',' or likely expression }
      until not (last in [ccma, ccln]+exprset);
      if nxttlk = crparen then gettlk { skip ')' }

   end else { parameterless }
      if (fs = nil) and (dc = pfwriteln) then begin { no 'output' for writeln }

         perror(enohdf, [], []); { no 'output' file }
         gblout := gbludf { prevent further default errors }

      end else begin { 'output' specified }

         { mode is default to 'output' file. Now we must load the output file }
         wrtcod(ilodadr); { output address load operator }
         wrtlnk(fs); { output entry to load }
         { count default references }
         if gblots <> nil then { there is a symbol for it }
            gblots^.ref := gblots^.ref + 1 { count refs }

      end;
   if not parp and (dc <> pfwriteln) then { no parameters processed }
      perror(eplicp, [], []);
   if dc = pfwriteln then wrtcod(iwrteolt); { writeln, write eoln }
   wrtcod(ipoptop); { remove file from stack }
   wrtlnk(fs) { output type }

end;

{*******************************************************************************

Parse read/readln procedure

*******************************************************************************}

procedure parreadln(ss: tolkset; { skip set }
                    dc: prcfnc); { function dispatch code }

var tp:     typptr; { type pointer }
    fstpar: boolean; { first parameter flag }
    fs:     typptr;  { output file specification }
    ft:     boolean; { output filetype is text }
    last:   tolken;  { parsing aid }
    bt:     typptr;  { base type }
    parp:   boolean; { parameter parsed flag }
    verr:   errcod;  { last var mode error (unused) }

begin

   if fparse then writeln(':read/readln procedure');
   fstpar := true; { set 1st parameter }
   parp := false; { set no parameters parsed }
   fs := gblinp; { default to 'input' file }
   ft := true; { set text type input }
   if (nxttlk <> clparen) and (dc = pfread) then { '(' expected for read }
      perror(elpexp, [clparen]+exprset+ss, []); { '(' expected }
   if nxttlk = clparen then begin { parameter list }

      gettlk; { skip '(' }
      repeat { parameters }

         { parse variable (or file variable) with threat }
         parvarh([ccma, crparen]+exprset+ss, true, false, tp, verr);
         if filet(tp) then begin 

            { define input file }
            if not fstpar then perror(efmbfp, [], []); { must be 1st param }
            { check only "text" filetype applied to readln }
            if (tp^.t = tfile) and (dc = pfreadln) then 
               perror(embtext, [], []); { must be text file }
            fs := tp; { set input file }
            ft := fs^.t = ttext { set file text status }

         end else begin

            if fstpar and (fs <> nil) then begin
   
               { mode is default to 'input' file. Now we must load the input
                 file, and swap the stack so it ends up on the bottom where it
                 belongs }
               wrtcod(ilodadr); { load address of variable }
               wrtlnk(fs); { output entry to load }
               wrtcod(iswptop); { swap top with second }
               wrtlnk(gblnil); { output sos type (pointer) }
               wrtlnk(baset(fs)) { output tos type }
               
            end;
            if ft then begin 
   
               { validate for text file input }
               bt := baset(tp); { get base type }
               if not (bt^.t in [tudf, tinteger, tlinteger, tcardinal,
                                 tlcardinal, tchar, treal, tsreal]) then
                  perror(erdpar, [], []); { type incorrect for read/readln }
               { check if the 'input' file has been declared }
               if fs = nil then begin { no 'input' file }
   
                  perror(enihdf, [], []); { no 'input' file }
                  gblinp := gbludf; { prevent further default errors }
                  fs := gblinp
   
               end else
                  { if we have just used the global input file, count that as a
                    default reference }
                  if fs = gblinp then 
                     if gblins <> nil then { there is a symbol for it }
                        gblins^.ref := gblins^.ref + 1; { count refs }
               parp := true { set parameter parsed }
   
            end else begin { check type exact match for parameter }
   
                if (fs^.filt <> tp) and (tp^.t <> tudf) then { bad match }
                  perror(evarcmp, [], []); { must be same as VAR definition }
                parp := true { set parameter parsed }
   
            end;
            if ft then begin { text file input }
   
               bt := baset(tp); { find base }
               if bt^.t in [tinteger, tlinteger, tcardinal, tlcardinal] then
                  begin

                  wrtcod(iredintt); { read integer }
                  wrtlnk(tp) { output type }

               end else if bt^.t = tchar then wrtcod(iredchrt) { read character }
               else if bt^.t = tsreal then wrtcod(iredsrlt) { read short real }
               else wrtcod(iredrelt) { read real }
   
            end else begin
   
               wrtcod(iredsrc); { read typed file }
               wrtlnk(tp) { output type }
    
            end

         end;
         fstpar := false; { set not 1st parameter }
         if (nxttlk <> ccma) and (nxttlk <> crparen) then
            { process error }
            perror(erpcmexp, [ccma, crparen]+
                             [cidentifier, cperiod, ccmf, clbrkt]+ss, []);
         last := nxttlk; { save last tolken }
         if nxttlk = ccma then gettlk { skip ',' }

      { until not ',' or likely expression }
      until not (last in [ccma, ccln]+exprset);
      if nxttlk = crparen then gettlk { skip ')' }

   end else { parameterless }
      if (fs = nil) and (dc = pfreadln) then begin { no 'input' for readln }

         perror(enihdf, [], []); { no 'input' file }
         gblinp := gbludf { prevent further default errors }

      end else begin { 'input' specified }

         { mode is default to 'input' file. Now we must load the input file }
         wrtcod(ilodadr); { load address of variable }
         wrtlnk(fs); { output entry to load }
         { count default reference to input }
         if gblins <> nil then { there is a symbol for it }
            gblins^.ref := gblins^.ref + 1 { count refs }

      end;
   if not parp and (dc <> pfreadln) then { no parameters processed }
      perror(eplicp, [], []);
   if dc = pfreadln then wrtcod(iredeolt); { read eoln }
   wrtcod(ipoptop); { remove file from stack }
   wrtlnk(fs) { output type }
         
end;

{*******************************************************************************

Parse arithmetic function

*******************************************************************************}

procedure pararthfnc(    ss: tolkset; { skip set }
                         dc: prcfnc;  { function dispatch code }
                     var tp: typptr); { return type }

var ti:    integer; { temp integer }
    ts:    boolean; { temp sign }
    tr:    real;    { temp real }
    solve: boolean; { solved constant flag }
    bt:    typptr;  { base type }

begin

   if fparse then writeln(':arithmetic function');
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   parexpr(nil, [crparen]+ss, tp); { parse parameter }
   { check integer or real }
   if not (intt(tp) or realt(tp) or (tp^.t = tudf)) then begin

      perror(embroi, [], []); { must be real or integer }
      tp := gbludf { set undefined }
   
   end;
   expect(crparen, erpexp, ss, []); { expect ')' }
   { convert integer to real for real function }
   if intt(tp) and (dc in [pfsqrt, pfsin, pfarctan, pfexp, pfln, pfcos]) then
      wrtcod(icvtitr); { convert integer to real }
   bt := baset(tp); { find base type }
   case dc of { function type }

      pfabs:    if realt(bt) then wrtcod(iabsrel) { abs of real }
                else wrtcod(iabsint); { abs of integer }
      pfsqr:    if realt(bt) then wrtcod(isqrrel) { sqr of real }
                else wrtcod(isqrint); { sqr of integer }
      pfarctan: wrtcod(iatnrel); { arctan of real }
      pfcos:    wrtcod(icosrel); { cos of real }
      pfexp:    wrtcod(iexprel); { exp of real }
      pfln:     wrtcod(ilgnrel); { ln of real }
      pfsin:    wrtcod(isinrel); { sin of real }
      pfsqrt:   wrtcod(isqtrel) { sqrt of real }

   end; 
   solve := true; { set solved constant }
   if (tp^.t = trcst) or 
      ((tp^.t = ticst) and 
       (dc in [pfsqrt, pfsin, pfarctan, pfexp, pfln, pfcos])) then begin

      { process real constant }
      if tp^.t = trcst then tr := tp^.rval else begin { get integer }

         tr := tp^.ival.v; { value }
         if tp^.ival.s then tr := tr*(-1) { sign }

      end;
      case dc of { operation }

         pfabs:    tr := abs(tr); { abs }
         pfarctan: tr := arctan(tr); { arctan }  
         pfcos:    tr := cos(tr); { cos }    
         pfexp:    tr := exp(tr); { exp }     
         pfln:     begin { ln }

            if tr <= 0 then begin { flag error }

               perror(elnlez, [], []); { ln less than or equal to zero }
               solve := false { so will just become type }

            end else tr := ln(tr) { find value }

         end;    
         pfsin:    tr := sin(tr); { sin }    
         pfsqr:    tr := sqr(tr); { sqr }   
         pfsqrt:   begin { sqrt }

            if tr < 0 then begin { flag error }

               perror(esqrtneg, [], []); { sqrt negative }
               solve := false { so will just become type }

            end else tr := sqrt(tr) { find value }

         end

      end;
      if solve then begin { was solved }

         lsttyp(tp, trcst); { get a new real entry }
         tp^.rval := tr { place result }

      end

   end else if tp^.t = ticst then begin

      { process integer constant }
      case dc of { operation }

         pfabs: begin { abs }

            ti := tp^.ival.v; { value }
            ts := false { sign }

         end;
         pfsqr: begin { sqr }

            ti := sqr(tp^.ival.v); { value }   
            ts := false { sign }

         end

      end;
      lsttyp(tp, ticst); { get a new integer entry }
      tp^.ival.v := ti; { place result value }
      tp^.ival.s := ts { place result sign }

   end else solve := false; { set not solved constant }
   if not solve then begin { not a solved constant, find result type }

      tp := baset(tp); { set same type result as input }
      { check real result functions }
      if dc in [pfsqrt, pfsin, pfarctan, pfexp, pfln, pfcos] then tp := gblreal

   end

end;

{*******************************************************************************

Parse chr function

*******************************************************************************}

procedure parchr(    ss: tolkset; { skip set }
                 var tp: typptr); { return type }

var tp1: typptr; { type pointer }

begin

   if fparse then writeln(':chr function');
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   parexpr(nil, [crparen]+ss, tp); { parse parameter }
   { check integer }
   if not (intt(tp) or (tp^.t = tudf)) then 
      perror(embint, [], []); { must be integer }
   expect(crparen, erpexp, ss, []); { expect ')' }
   if tp^.t = ticst then begin { resolve constant }

      if ssltn(tp^.ival, lbounds(gblchr), lbound(gblchr)) or
         ssgtn(tp^.ival, ubounds(gblchr), ubound(gblchr)) then 
         begin

         { value out of range for character }
         perror(erange, [], []);
         tp := gblchr { set result type char }

      end else begin { form constant }

         lsttyp(tp1, tccst); { get a character constant type entry }
         tp1^.cval := chr(tp^.ival.v); { place value }
         tp := tp1 { place result }

      end

   end else tp := gblchr { set result type char }

end;

{*******************************************************************************

Parse eof/eoln function

*******************************************************************************}

procedure pareofeoln(    ss: tolkset; { skip set }
                         dc: prcfnc;  { function dispatch code }
                     var tp: typptr); { return type }

var it: typptr; { input file type holder }

begin

   if fparse then writeln(':eof/eoln function');
   it := gblinp; { default input file type to input }
   if nxttlk = clparen then begin { file parameter exists }

      expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
      parexpr(nil, [crparen]+ss, it); { parse parameter }
      { check what function }
      if dc = pfeof then begin { eof }

         if not (filet(it) or (it^.t = tudf)) then 
            perror(embfil, [], []) { must be file }

      { else eoln gets text only }
      end else if not ((it^.t = ttext) or (it^.t = tudf)) then
         perror(embtxt, [], []); { must be text }
      expect(crparen, erpexp, ss, []) { expect ')' }

   end else { parameterless }
      if gblinp = nil then perror(enihdf, [], []) { no 'input' file }
      else begin
      
         if gblins <> nil then { there is a symbol for it }
            gblins^.ref := gblins^.ref + 1; { count refs }
         { mode is default to 'input' file. Now we must load the input file }
         wrtcod(ilodadr); { load address of variable }
         wrtlnk(gblinp) { output entry to load }

      end;
   if dc = pfeoln then wrtcod(ieolt) { eoln }
   else begin

      wrtcod(ieof); { eof }
      wrtlnk(it)

   end;
   tp := gblbool { set result type boolean }

end;

{*******************************************************************************

Parse odd function

*******************************************************************************}

procedure parodd(    ss: tolkset; { skip set }
                 var tp: typptr); { return type }

begin

   if fparse then writeln(':odd function');
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   parexpr(nil, [crparen]+ss, tp); { parse parameter }
   { check integer }
   if not (intt(tp) or (tp^.t = tudf)) then 
      perror(embint, [], []); { must be integer }
   expect(crparen, erpexp, ss, []); { expect ')' }
   wrtcod(iodd); { odd }
   if tp^.t = ticst then begin { resolve constant }

      { assign true or false entry value }
      if odd(tp^.ival.v) then tp := gbltrue else tp := gblfalse

   end else tp := gblbool { set result type boolean }

end;

{*******************************************************************************

Parse ord, succ and pred function

*******************************************************************************}

procedure parordprsc(    ss: tolkset; { skip set }
                         dc: prcfnc;  { function dispatch code }
                     var tp: typptr); { return type }

var tp1, tp2: typptr;  { type pointer }
    ti:       integer; { temp integer }
    ts:       boolean; { temp sign }
    solve:    boolean; { constant solved flag }

begin

   if fparse then writeln(':ord/succ/pred function');
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   parexpr(nil, [crparen]+ss, tp); { parse parameter }
   { if it is a constant character, this must be loaded }
   if tp^.t = tscst then wrtcod(ildichr);
   { check ordinal }
   tp1 := baset(tp); { get base type }
   if not (chart(tp1) or boolt(tp1) or intt(tp1) or (tp1^.t = tenum) or 
           (tp1^.t = tudf)) then begin

      perror(embord, [], []); { must be ordinal }
      tp := gbludf { set undefined }

   end;
   expect(crparen, erpexp, ss, []); { expect ')' }
   case dc of { function }

      pford:  ; { no action is required, as all are integer }
      pfsucc: wrtcod(isucint); { succ of integer or enumerated }
      pfpred: wrtcod(iprdint) { ord of integer or enumerated }

   end;
   { resolve constant }
   if tp^.t in [ticst, tscst, tccst, tenme] then begin

      if dc = pford then begin { ord }

         lsttyp(tp1, ticst); { get an integer constant type entry }
         tp1^.ival.v := consti(tp); { get the constant value }
         tp1^.ival.s := constis(tp); { get the constant sign }
        

      end else begin { succ, pred }

         solve := true; { set constant solved }
         ti := consti(tp); { get the value }
         ts := constis(tp); { get the sign }
         { validate for overflow. Note we avoid actually performing
           the overflowing operation, since that could trip a compiler
           error }
         if dc = pfsucc then begin { succ }
  
            if (ts = ubounds(tp)) and (ti = ubound(tp)) then begin { overflow }

               perror(erange, [], []); { out of range }
               solve := false { set not solved }

            end else begin

               ts := ssadds(ts, ti, false, 1); { find succ sign }
               ti := ssadd(ts, ti, false, 1) { find succ value }

            end

         end else begin { pred }

            if (ts = lbounds(tp)) and (ti = lbound(tp)) then begin { overflow }

               perror(erange, [], []);
               solve := false { set not solved }

            end else begin

               ts := ssadds(ts, ti, true, 1); { find pred sign }
               ti := ssadd(ts, ti, true, 1) { find pred value }

            end
  
         end;
         if solve then { constant was solved }
            if tp^.t = ticst then begin { result is integer }
  
               lsttyp(tp1, ticst); { get an integer constant type entry }
               tp1^.ival.v := ti; { place value }
               tp1^.ival.s := ts { place sign }

            end else if (tp^.t = tscst) or (tp^.t = tccst) then begin 

               { result is character }
               lsttyp(tp1, tccst); { get a character constant type entry }
               tp1^.cval := chr(ti) { place value }

            end else begin { result is enumerated }

               tp1 := nil; { set no entry found }
               tp2 := tp^.enh^.enx; { index 1st enum entry }
               while tp2 <> nil do begin { find the correct entry }

                  if tp2^.env = ti then tp1 := tp2; { found entry, set }
                  tp2 := tp2^.enx { index next entry }

               end;
               { trap out on no list entry corresponding }
               if tp1 = nil then error(esflt14, true)

            end

      end;
      tp := tp1 { place result, or base type (above) }
         
   end else begin

      tp := tp1; { set type as base }
      if dc = pford then tp := gblint { set result type integer }

   end

end;

{*******************************************************************************

Parse round/trunc function

*******************************************************************************}

procedure parrndtrc(    ss: tolkset; { skip set }
                        dc: prcfnc;  { function dispatch code }
                    var tp: typptr); { return type }

var tp1: typptr; { type pointer }

begin

   if fparse then writeln(':round/trunc function');
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   parexpr(nil, [crparen]+ss, tp); { parse parameter }
   { check real }
   if not (realt(tp) or (tp^.t = tudf)) then perror(embrl, [], []);
   expect(crparen, erpexp, ss, []); { expect ')' }
   if dc = pfround then wrtcod(irnd) { round }
   else wrtcod(itrc); { trunc }
   if tp^.t = trcst then begin { resolve constant }

      lsttyp(tp1, ticst); { get an integer constant type entry }
      { resolve constant }
      if dc = pftrunc then begin { trunc }

         tp1^.ival.v := abs(trunc(tp^.rval)); { value }
         tp1^.ival.s := tp^.rval < 0 { sign }

      end else begin { round }

         tp1^.ival.v := abs(round(tp^.rval)); { value }
         tp1^.ival.s := tp^.rval < 0 { sign }

      end;
      tp := tp1 { place result }
      
   end else tp := gblint { set integer result }

end;

{*******************************************************************************

Parse exists function

*******************************************************************************}

procedure parexists(    ss: tolkset; { skip set }
                    var tp: typptr); { return type }

begin

   if fparse then writeln(':exists function');
   if fansi then perror(efncprcs, [], []); { not standard }
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   parexpr(nil, [crparen]+ss, tp); { parse parameter }
   { check string }
   if not (strt(tp) or (tp^.t = tudf)) then perror(embstr, [], []);
   expect(crparen, erpexp, ss, []); { expect ')' }
   if tp^.t <> tgarry then begin { convert fixed to general array }

      wrtcod(icvtftg); { convert fixed to tagged pointer }
      wrtlnk(tp) { write fixed type }
      
   end;
   wrtcod(iexist); { exists }
   tp := gblbool { set boolean result }

end;

{*******************************************************************************

Parse location/length functions

*******************************************************************************}

procedure parloclen(    ss: tolkset; { skip set }
                        dc: prcfnc;  { function dispatch code }
                    var tp: typptr); { return type }

var tp1: typptr; { type pointer }
    sp:  symptr; { symbol pointer }
    err: errcod; { last var mode error (unused) }

begin

   if fparse then writeln(':location/length function');
   if fansi then perror(efncprcs, [], []); { not standard }
   expect(clparen, elpexp, [clparen, cidentifier]+ss, []); { expect '(' }
   tp := gbludf; { set result undefined }
   sp := nil; { set no head symbol }
   { parse variable head }
   if nxttlk <> cidentifier then { id expected }
      perror(evidexp, [cidentifier, cperiod, ccmf, crparen]+ss, []);
   if nxttlk in [cidentifier, cperiod, ccmf] then begin 

      { found, or likely start found }
      parvarlead([crparen]+ss, sp, tp); { parse variable leader }
      { check operating on special file }
      if tp^.t = tvar then { variable }
         if (tp^.vars <> fsnone) and (tp^.vars <> fsherr) then
            perror(eoivspf, [], []);
      parvar([crparen]+ss, sp, false, tp, err)

   end;
   { check file }
   tp1 := baset(tp); { link base type }
   { check is a file }
   if not (filet(tp1) or (tp1^.t = tudf)) then perror(embfil, [], []);
   { check not text file }
   if tp1^.t = ttext then perror(emnbtxt, [], []);
   expect(crparen, erpexp, ss, []); { expect ')' }
   if dc = pflength then wrtcod(ilen) { length }
   else wrtcod(iloc); { location }
   tp := gblint { set integer result }

end;

{*******************************************************************************

Parse max function

*******************************************************************************}

procedure parmax(    ss: tolkset; { skip set }
                 var tp: typptr); { return type }

var verr:   errcod;  { last var mode error (unused) }
    lvlext: boolean; { level argument exists }
    tp1:    typptr;  { type pointer }

begin

   if fparse then writeln(':max function');
   if fansi then perror(efncprcs, [], []); { not standard }
   lvlext := false; { set no level argument }
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   parvarh([crparen]+ss, false, false, tp, verr); { parse parameter }
   { check general array }
   if not (tp^.t in [tgarry, tudf]) then perror(embgar, [], []);
   { check next is ',' or ')' }
   if (nxttlk <> ccma) and (nxttlk <> crparen) then
      { process error }
      perror(erpcmexp, [ccma, crparen, cinteger]+ss, []);
   if nxttlk = ccma then begin { there is a level specification }

      gettlk; { get ',' }
      lvlext := true; { set level exists }
      parexpr(nil, [crparen]+exprset+ss, tp1); { parse level expression }
      if not intt(tp1) and (tp1^.t <> tudf) then 
         perror(embint, [], []) { must be integer }

   end;
   expect(crparen, erpexp, ss, []); { expect ')' }
   if lvlext then wrtcod(ilodlen) { find length }
   else wrtcod(ilodlenl); { find length at level }
   wrtlnk(tp); { output array type }
   tp := gblint { set integer result }

end;

{*******************************************************************************

Parse new/dispose procedure procedure

*******************************************************************************}

procedure pardispnew(ss: tolkset; { skip set }
                     dc: prcfnc); { function dispatch code }

var tp, tp1, tp2: typptr;  { type pointers }
    last:         tolken;  { parsing aid }
    n:            integer; { case value holder }
    s:            boolean; { case value holder sign }
    verr:         errcod;  { last var mode error (unused) }

begin

   if fparse then writeln(':new/dispose procedure');
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   { parse pointer to operate on }
   if dc = pfnew then { 'new' }
      { parse variable }
      parvarh([ccma, crparen]+exprset+ss, true, false, tp, verr)
   else
      parexpr(nil, [ccma, crparen]+exprset+ss, tp); { parse expression }
   { check pointer or reference }
   if (tp^.t <> tptr) and (tp^.t <> treference) and (tp^.t <> tudf) then
      if fansi then perror(embptr, [], [])
      else perror(embpor, [], []);
   if tp^.t = tptr then begin { pointer }

      if tp^.ptrt^.t = tgarry then begin

         { it's a general array }
         if dc = pfnew then begin { 'new' }

            { we accept as many length specifiers as there are general arrays }
            tp2 := tp^.ptrt; { index base type }
            repeat { process general array bases }

               expect(ccma, ecmaexp, [ccma, crparen]+exprset+ss, []); { expect ',' }
               parexpr(nil, [crparen]+exprset+ss, tp1); { parse length expression }
               if not intt(tp1) and (tp1^.t <> tudf) then 
                  perror(embint, [], []); { must be integer }
               tp2 := tp2^.gart { link next base }

            until tp2^.t <> tgarry; { no more general arrays }
            wrtcod(inewgar) { allocate general array }

         end else wrtcod(idspgar); { dispose of tagged object }
         wrtlnk(tp^.ptrt) { output array type }

      end else begin { normal pointer }

         if dc = pfnew then begin { 'new' }

            wrtcod(inew); { new }
            wrtlnk(tp) { generate type }

         end else begin 

            wrtcod(idisp); { dispose }
            wrtlnk(tp) { generate type }

         end;
         if nxttlk = ccma then begin { tags exist }

            gettlk; { skip ',' }
            if tp^.t = tptr then tp := actt(tp^.ptrt); { dereference pointer }
            if (tp^.t <> trecord) and (tp^.t <> tudf) then begin

               perror(embrec, [], []); { must be record }
               tp := gbludf { set result undefined }

            end;
            if tp^.t = trecord then { is a record }
               tp := tp^.recf; { index the top of the field list }
            repeat { tags }

               if tp^.t <> tudf then begin { field list exists }

                  { if there is a tag specified, there must be a record variant
                    defined to match it, so we find that }
                  tp1 := nil; { clear found pointer }
                  while tp <> nil do begin { traverse }

                     { if tag found, place result and terminate search }
                     if tp^.t = tftag then begin tp1 := tp; tp := nil end
                     else tp := tp^.fldn { else must be field, next }

                  end;
                  tp := tp1; { place result }
                  if tp1 = nil then begin { no tagfield found }

                     perror(entagf, [], []); { no tagfield found }
                     tp := gbludf { set result undefined }

                  end

               end;
               parconst([ccma, crparen]+exprset+ss, tp1);
               { check value is constant }
               if not (tp1^.t in [ticst, tscst, tccst, tenme, tudf]) then begin

                  perror(embcst, [], []); { must be constant }
                  tp := gbludf { set result undefined }

               end;
               chkschr(tp1); { if string, check is single character }
               { check compatible with tagfield }
               if tp^.t = tftag then { we have a tag }
                  if not typcmpa(tp^.ftgt, tp1) then perror(ercvcmp, [], []);
               wrtcod(itag); { tagfield constant }
               if tp1^.t <> tudf then
                  wrtnum(constis(tp1), consti(tp1)); { output tagfield constant }
               if (nxttlk <> ccma) and (nxttlk <> crparen) then
                  { process error }
                  perror(erpcmexp, [ccma, ccln, crparen]+exprset+ss, []);
               { check we have a valid access }
               if (tp^.t = tftag) and (tp1^.t <> tudf) then begin

                  { access valid, find the case selected }
                  n := consti(tp1); { get the case select constant value }
                  s := constis(tp1); { get the case select constant sign }
                  tp := tp^.ftgc; { index top of case constant list }
                  tp1 := nil; { clear found }
                  while tp <> nil do begin { traverse }

                     { check matches, terminate if so }
                     if ssleq(tp^.fcss, s, n) and ssgeq(tp^.fcse, s, n) then
                        begin tp1 := tp; tp := nil end
                     else tp := tp^.fcsn { else next entry }

                  end;
                  tp := tp1; { place result }
                  if tp = nil then begin

                     perror(ercvnf, [], []); { case not found }
                     tp := gbludf { set result undefined }

                  end else tp := tp^.fcsf { index top of field list }

               end else tp := gbludf; { else set result undefined }
               last := nxttlk; { save last tolken }
               if nxttlk = ccma then gettlk { skip ',' }

            { until not ',' or likely expression }
            until not (last in [ccma, ccln]+exprset)
             
         end;
         wrtcod(iendtag) { end of tagfields }

      end
 
   end else if tp^.t = treference then begin { reference }

      if dc = pfnew then wrtcod(inewobj) { allocate new object }
      else wrtcod(idspobj); { dispose of object }
      wrtlnk(tp^.reft) { output reference type }

   end;
   expect(crparen, erpexp, ss, []); { expect ')' }

end;

{*******************************************************************************

Parse get/put/reset/rewrite/close/update/append procedure

*******************************************************************************}

procedure pargetputresrewclsupdapp(ss: tolkset; { skip set }
                                   dc: prcfnc); { function dispatch code }

var tp:  typptr; { type pointer }
    sp:  symptr; { symbol pointer }
    err: errcod; { last var mode error (unused) }

begin

   if fparse then writeln(':get/put/reset/rewrite/close/update procedure'); 
   if fansi and (dc in [pfclose, pfupdate, pfappend]) then 
      perror(efncprcs, [], []); { not standard }
   expect(clparen, elpexp, [clparen, cidentifier]+ss, []); { expect '(' }
   tp := gbludf; { set result undefined }
   sp := nil; { set no head symbol }
   { parse variable head }
   if nxttlk <> cidentifier then { id expected }
      perror(evidexp, [cidentifier, cperiod, ccmf, crparen]+ss, []);
   if nxttlk in [cidentifier, cperiod, ccmf] then begin 

      { found, or likely start found }
      parvarlead([crparen]+ss, sp, tp); { parse variable leader }
      { check operating on special file }
      if tp^.t = tvar then { variable }
         if (tp^.vars <> fsnone) and (tp^.vars <> fsherr) and
            (dc in [pfreset, pfrewrite, pfclose]) then
            perror(eoivspf, [], []);
      threaten(sp, tp); { process a threat }
      parvar([crparen]+ss, sp, false, tp, err)

   end;
   { check file }
   if not (filet(tp) or (tp^.t = tudf)) then perror(embfil, [], []);
   if (dc = pfupdate) and (tp^.t = ttext) then perror(eupdtxt, [], []);
   expect(crparen, erpexp, ss, []); { expect ')' }
   case dc of { procedure }

      pfget:     if tp^.t = ttext then wrtcod(igett) { get }
                 else wrtcod(iget);
      pfput:     wrtcod(iput);     { put }
      pfreset:   begin wrtcod(ireset); wrtlnk(tp) end; { reset }
      pfrewrite: begin wrtcod(irewrite); wrtlnk(tp) end; { rewrite }
      pfupdate:  begin wrtcod(iupdate); wrtlnk(tp) end; { update }
      pfappend:  begin wrtcod(iappend); wrtlnk(tp) end; { append }
      pfclose:   wrtcod(iclose)    { close }

   end

end;

{*******************************************************************************

Parse pack procedure

*******************************************************************************}

procedure parpack(ss: tolkset); { skip set }

var tp, tp1, tp2, ttp, ttp2: typptr;  { type pointers }
    ti, t1i:                 integer; { constant holding value }
    ts, t1s:                 boolean; { constant holding sign }
    verr:                    errcod;  { last var mode error (unused) }

begin

   if fparse then writeln(':pack procedure');
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   { parse unpacked variable }
   parvarh([ccma, crparen]+exprset+ss, false, false, tp, verr);
   if not (tp^.t in [tarray, tgarry, tudf]) then 
      perror(embarr, [], []); { must be array }
   if tp^.t in [tarray, tgarry] then if tp^.pack then 
      perror(embupk, [], []); { must be unpacked }
   expect(ccma, ecmaexp, [ccma, crparen]+exprset+ss, []); { expect ',' }
   parexpr(nil, [ccma, crparen]+ss, tp1); { parse starting index }
   { if the object is a string constant, this must be a character, so
     load it from the address }
   if tp1^.t = tscst then wrtcod(ildichr);
   if tp^.t = tarray then { check index compatible }
      if not typcmpa(tp^.arri, tp1) then perror(eidxcmp, [], [])
      else if tp1^.t in [ticst, tscst, tccst, tenme] then begin 

      { index is constant, check for bounds }
      ti := consti(tp1); { get index value }
      ts := constis(tp1); { get index sign }
      if ssltn(ts, ti, lbounds(tp^.arri), lbound(tp^.arri)) or 
         ssgtn(ts, ti, ubounds(tp^.arri), ubound(tp^.arri)) then
         perror(epupbnd, [], []) { array reference bounds }

   end else if tp^.t = tgarry then { check index compatible }
      if not intt(tp1) then perror(eidxcmp, [], []);
   expect(ccma, ecmaexp, [ccma, crparen]+exprset+ss, []); { expect ',' }
   { parse packed variable with threat }
   parvarh([crparen]+ss, true, false, tp2, verr);
   if not (tp^.t in [tarray, tgarry, tudf]) then 
      perror(embarr, [], []); { must be array }
   if tp2^.t in [tarray, tgarry] then { array }
      if not tp2^.pack then perror(embpk, [], []); { must be packed }
   expect(crparen, erpexp, ss, []); { expect ')' }
   if (tp^.t in [tarray, tgarry]) and (tp2^.t in [tarray, tgarry]) then begin

      { check components equal }
      if tp^.t = tarray then ttp := tp^.arrt else ttp := tp^.gart;
      if tp2^.t = tarray then ttp2 := tp2^.arrt else ttp2 := tp2^.gart;
      if ttp <> ttp2 then perror(embscmp, [], [])
      else if (tp1^.t in [ticst, tscst, tccst, tenme]) and 
              (tp^.t <> tgarry) and (tp2^.t <> tgarry) then begin

         { find if the starting index plus the span of the operation would
           result in an access beyond the end of the source array.
           this operation could theoretically overflow in the compiler }
         ti := ssadd(ubounds(tp2^.arri), ubound(tp2^.arri), 
                      not lbounds(tp2^.arri), lbound(tp2^.arri)); { find span }
         ts := ssadds(ubounds(tp2^.arri), ubound(tp2^.arri), 
                       not lbounds(tp2^.arri), lbound(tp2^.arri));
         { find index value+span-1 }
         t1i := ssadd(constis(tp1), consti(tp1), ts, ti);
         t1s := ssadds(constis(tp1), consti(tp1), ts, ti);
         { check that is greater than the upper bound of array }
         if ssgtn(t1s, t1i, ubounds(tp^.arri), ubound(tp^.arri)) then
            perror(epupbnd, [], []) { yes, out of bounds index }

      end

   end;
   wrtcod(ipack); { pack }
   wrtlnk(tp2); { output packed type }
   wrtlnk(tp) { output unpacked type }

end;

{*******************************************************************************

Parse unpack procedure

*******************************************************************************}

procedure parunpack(ss: tolkset); { skip set }

var tp, tp1, tp2, ttp, ttp2: typptr;  { type pointers }
    ti, t1i:                 integer; { constant holding value }
    ts, t1s:                 boolean; { constant holding sign }

    verr:                    errcod;  { last var mode error (unused) }

begin

   if fparse then writeln(':unpack procedure');
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   { parse packed variable }
   parvarh([ccma, crparen]+exprset+ss, false, false, tp, verr);
   if not (tp^.t in [tarray, tgarry, tudf]) then 
      perror(embarr, [], []); { must be array }
   if tp^.t in [tarray, tgarry] then if not tp^.pack then 
      perror(embpk, [], []); { must be packed }
   expect(ccma, ecmaexp, [ccma, crparen]+exprset+ss, []); { expect ',' }
   { parse unpacked variable with threat }
   parvarh([ccma, crparen]+exprset+ss, true, false, tp2, verr);
   if not (tp^.t in [tarray, tgarry, tudf]) then 
      perror(embarr, [], []); { must be array }
   if tp2^.t in [tarray, tgarry] then if tp2^.pack then 
      perror(embupk, [], []); { must be unpacked }
   expect(ccma, ecmaexp, [ccma, crparen]+exprset+ss, []); { expect ',' }
   parexpr(nil, [crparen]+ss, tp1); { parse starting index }
   { if the object is a string constant, this must be a character, so
     load it from the address }
   if tp1^.t = tscst then wrtcod(ildichr);
   if tp2^.t = tarray then { check index compatible }
      if not typcmpa(tp2^.arri, tp1) then perror(eidxcmp, [], [])
      else if (tp1^.t in [ticst, tscst, tccst, tenme]) and 
              (tp^.t <> tgarry) then begin

      { index is constant, check for bounds }
      ti := consti(tp1); { get index value }
      ts := constis(tp1); { get index sign }

      if ssltn(ts, ti, lbounds(tp2^.arri), lbound(tp2^.arri)) or
         ssgtn(ts, ti, ubounds(tp2^.arri), ubound(tp2^.arri)) then
         perror(epupbnd, [], []) { array reference bounds }
      else begin { check the "span" of the operation is correct }

         { find if the starting index plus the span of the operation would
           result in an access beyond the end of the source array.
           this operation could theoretically overflow in the compiler }
         ti := ssadd(ubounds(tp^.arri), ubound(tp^.arri), 
                      not lbounds(tp^.arri), lbound(tp^.arri)); { find span }
         ts := ssadds(ubounds(tp^.arri), ubound(tp^.arri), 
                       not lbounds(tp^.arri), lbound(tp^.arri));
         { find index value+span-1 }
         t1i := ssadd(constis(tp1), consti(tp1), ts, ti);
         t1s := ssadds(constis(tp1), consti(tp1), ts, ti);
         { check that is greater than the upper bound of array }
         if ssgtn(t1s, t1i, ubounds(tp2^.arri), ubound(tp2^.arri)) then
            perror(epupbnd, [], []) { yes, out of bounds index }

      end

   end else if tp2^.t = tgarry then { check index compatible }
      if not intt(tp1) then perror(eidxcmp, [], []);
   expect(crparen, erpexp, ss, []); { expect ')' }
   if (tp^.t in [tarray, tgarry]) and (tp2^.t in [tarray, tgarry]) then begin

      { check components equal }
      if tp^.t = tarray then ttp := tp^.arrt else ttp := tp^.gart;
      if tp2^.t = tarray then ttp2 := tp2^.arrt else ttp2 := tp2^.gart;
      if ttp <> ttp2 then perror(embscmp, [], [])

   end;
   wrtcod(iunpack); { unpack }
   wrtlnk(tp2); { output unpacked type }
   wrtlnk(tp) { output packed type }

end;

{*******************************************************************************

Parse page procedure

*******************************************************************************}

procedure parpage(ss: tolkset); { skip set }

var tp: typptr; { type pointer }

begin

   if fparse then writeln(':page procedure');
   if nxttlk = clparen then begin { file parameter exists }

      gettlk; { skip '(' }
      parexpr(nil, [crparen]+ss, tp); { parse parameter }
      { check text file }
      tp := baset(tp); { get base type }
      { check text type }
      if (tp^.t <> ttext) and (tp^.t <> tudf) then perror(embtxt, [], []);
      expect(crparen, erpexp, ss, []) { expect ')' }

   end else { parameterless }
      if gblout = nil then perror(enohdf, [], []) { no 'output' file }
      else begin
      
         { mode is default to 'output' file. Now we must load the output file }
         wrtcod(ilodadr); { load address of variable }
         wrtlnk(gblout); { output entry to load }
         { count default references }
         if gblots <> nil then { there is a symbol for it }
            gblots^.ref := gblots^.ref + 1 { count refs }

      end;
   wrtcod(ipaget) { page }

end;

{*******************************************************************************

Parse assign procedure 

*******************************************************************************}

procedure parassign(ss: tolkset); { skip set }

var tp, tp1: typptr; { type pointer }
    sp:      symptr; { symbol pointer }
    err:     errcod; { last var mode error (unused) }

begin

   if fparse then writeln(':assign procedure');
   if fansi then perror(efncprcs, [], []); { not standard }
   expect(clparen, elpexp, [clparen, cidentifier]+ss, []); { expect '(' }
   tp := gbludf; { set result undefined }
   sp := nil; { set no head symbol }
   { parse variable head }
   if nxttlk <> cidentifier then { id expected }
      perror(evidexp, [cidentifier, cperiod, ccmf, crparen, ccma]+ss, []);
   if nxttlk in [cidentifier, cperiod, ccmf] then begin 

      { found, or likely start found }
      parvarlead([crparen, ccma]+ss, sp, tp); { parse variable leader }
      { check operating on special file }
      if tp^.t = tvar then { variable }
         if (tp^.vars <> fsnone) and (tp^.vars <> fsherr) then
            perror(eoivspf, [], []);
      threaten(sp, tp); { threaten the variable }
      parvar([crparen, ccma]+ss, sp, false, tp, err)

   end;
   { check file }
   if not (filet(tp) or (tp^.t = tudf)) then perror(embfil, [], []);
   expect(ccma, ecmaexp, ss, []); { expect ',' }
   parexpr(nil, [crparen]+ss, tp1); { parse parameter }
   { check string }
   if not (strt(tp1) or (tp1^.t = tudf)) then perror(embstr, [], []);
   expect(crparen, erpexp, ss, []); { expect ')' }
   if tp1^.t <> tgarry then begin { convert fixed to general array }

      wrtcod(icvtftg); { convert fixed to tagged pointer }
      wrtlnk(tp1) { write fixed type }
      
   end;
   wrtcod(iassign) { open }

end;

{*******************************************************************************

Parse position procedure

*******************************************************************************}

procedure parposition(ss: tolkset); { skip set }

var tp:  typptr; { type pointer }
    sp:  symptr; { symbol pointer }
    err: errcod; { last var mode error (unused) }

begin

   if fparse then writeln(':position procedure');
   if fansi then perror(efncprcs, [], []); { not standard }
   expect(clparen, elpexp, [clparen, cidentifier]+ss, []); { expect '(' }
   tp := gbludf; { set result undefined }
   sp := nil; { set no head symbol }
   { parse variable head }
   if nxttlk <> cidentifier then { id expected }
      perror(evidexp, [cidentifier, cperiod, ccmf, crparen]+ss, []);
   if nxttlk in [cidentifier, cperiod, ccmf] then begin 

      { found, or likely start found }
      parvarlead([crparen]+ss, sp, tp); { parse variable leader }
      { check operating on special file }
      if tp^.t = tvar then { variable }
         if (tp^.vars <> fsnone) and (tp^.vars <> fsherr) then
            perror(eoivspf, [], []);
      parvar([crparen]+ss, sp, false, tp, err)

   end;
   { check file }
   if not (filet(tp) or (tp^.t = tudf)) then perror(embfil, [], []);
   expect(ccma, ecmaexp, ss, []); { expect ',' }
   parexpr(nil, [crparen]+ss, tp); { parse parameter }
   { check integer }
   if not (intt(tp) or (tp^.t = tudf)) then perror(embint, [], []);
   expect(crparen, erpexp, ss, []); { expect ')' }
   wrtcod(ipos) { position }

end;

{*******************************************************************************

Parse delete procedure

*******************************************************************************}

procedure pardelete(ss: tolkset); { skip set }

var tp: typptr; { type pointer }

begin

   if fparse then writeln(':delete procedure');
   if fansi then perror(efncprcs, [], []); { not standard }
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   parexpr(nil, [crparen]+ss, tp); { parse parameter }
   { check string }
   if not (strt(tp) or (tp^.t = tudf)) then perror(embstr, [], []);
   expect(crparen, erpexp, ss, []); { expect ')' }
   if tp^.t <> tgarry then begin { convert fixed to general array }

      wrtcod(icvtftg); { convert fixed to tagged pointer }
      wrtlnk(tp) { write fixed type }
      
   end;
   wrtcod(idel) { delete }

end;

{*******************************************************************************

Parse change procedure

*******************************************************************************}

procedure parchange(ss: tolkset); { skip set }

var tp, tp1: typptr; { type pointers }

begin

   if fparse then writeln(':change procedure');
   if fansi then perror(efncprcs, [], []); { not standard }
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   parexpr(nil, [crparen]+ss, tp); { parse destination parameter }
   { check string }
   if not (strt(tp) or (tp^.t = tudf)) then perror(embstr, [], []);
   if tp^.t <> tgarry then begin { convert fixed to general array }

      wrtcod(icvtftg); { convert fixed to tagged pointer }
      wrtlnk(tp) { write fixed type }
      
   end;
   expect(ccma, ecmaexp, ss, []); { expect ',' }
   parexpr(nil, [crparen]+ss, tp1); { parse source parameter }
   { check string }
   if not (strt(tp1) or (tp1^.t = tudf)) then perror(embstr, [], []);
   if tp1^.t <> tgarry then begin { convert fixed to general array }

      wrtcod(icvtftg); { convert fixed to tagged pointer }
      wrtlnk(tp1) { write fixed type }
      
   end;
   expect(crparen, erpexp, ss, []); { expect ')' }
   wrtcod(ichg) { change }

end;

{*******************************************************************************

Parse halt procedure

*******************************************************************************}

procedure parhalt;

begin

   if fparse then writeln(':halt procedure');
   if fansi then perror(efncprcs, [], []); { not standard }
   wrtcod(ihalt) { halt }

end;

{*******************************************************************************

Parse refer procedure

The reference procedure is very different in that it takes a symbol as a
parameter. Then, that symbol gets its reference counter bumped.

*******************************************************************************}

procedure parrefer(ss: tolkset); { skip set }

var sp:   symptr; { symbol pointer }
    last: tolken; { parsing aid }
    lab:  labl;   { label for undefines }

begin

   if fparse then writeln(':halt procedure');
   if fansi then perror(efncprcs, [], []); { not standard }
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   repeat { parameters }

      if nxttlk <> cidentifier then { id expected }
         perror(eidnexp, [cidentifier, crparen]+exprset+ss, []);
      if nxttlk = cidentifier then { id found }
         { parse qualified identifier, which also advances the reference count }
         parqualident(ss, true, true, true, '', sp, lab);
      { check proper next tolken }
      if (nxttlk <> ccma) and (nxttlk <> crparen) then
         { process error }
         perror(erpcmexp, [ccma, ccln, crparen]+exprset+ss, []);
      last := nxttlk; { save last tolken }
      if nxttlk = ccma then gettlk { skip ',' }

   until not (last in [ccma, cidentifier]); { until no more possible parameters }
   expect(crparen, erpexp, ss, []) { expect ')' }

end;

{*******************************************************************************

Parse signal/signalone/wait procedures

*******************************************************************************}

procedure parsigwait(ss: tolkset; { skip set }
                     dc: prcfnc); { function dispatch code }

var verr: errcod; { last var mode error (unused) }
    tp:   typptr; { type pointer }

begin

   if fparse then writeln(':signal/signalone/wait procedure');
   if fansi then perror(efncprcs, [], []); { not standard }
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   parvarh([crparen]+ss, false, false, tp, verr); { parse parameter }
   if tp^.t <> tsemaphore then perror(embsema, [], []); { must be semaphore }
   expect(crparen, erpexp, ss, []); { expect ')' }
   case dc of { procedure }

      pfsignal:    wrtcod(isignal);    { signal }
      pfsignalone: wrtcod(isignalone); { signalone }
      pfwait:      wrtcod(iwait)       { wait }

   end;
   if modhead <> cmonitor then perror(esigwatmon, [], [])

end;

{*******************************************************************************

Parse throw procedure

*******************************************************************************}

procedure parthrow;

begin

   if fparse then writeln(':throw procedure');
   if fansi then perror(efncprcs, [], []); { not standard }
   wrtcod(ithrow) { throw }

end;

{*******************************************************************************

Parse assert procedure

*******************************************************************************}

procedure parassert(ss: tolkset); { skip set }

var tp: typptr; { type pointer }

begin

   if fparse then writeln(':assert procedure');
   if fansi then perror(efncprcs, [], []); { not standard }
   expect(clparen, elpexp, [ccma, clparen, cidentifier]+ss, []); { expect '(' }
   parexpr(nil, [crparen]+ss, tp); { parse parameter }
   { check boolean }
   if not (boolt(tp) or (tp^.t = tudf)) then perror(embbol, [], []);
   if nxttlk = ccma then begin { message parameter exists }

      gettlk; { skip ',' }
      parexpr(nil, [crparen]+ss, tp); { parse parameter }
      { check string }
      if not (strt(tp) or (tp^.t = tudf)) then perror(embstr, [], []);
      if tp^.t <> tgarry then begin { convert fixed to general array }

         wrtcod(icvtftg); { convert fixed to tagged pointer }
         wrtlnk(tp) { write fixed type }
         
      end

   end else begin

      { If there is no message parameter, we pass an empty string. There is
        one such type per module, and it occupies no space. }
      if gblestr = nil then begin

         { the empty string was never created, create it now }
         lsttyp(gblestr, tscst); { get a string constant type entry }
         new(gblestr^.sval, 0); { create an empty string }
         if uselvl = 0 then { not in uses file }
            wrttyp; { make sure that is written immediately }

      end;
      { Loaded as a container, the empty string is loaded as a real address,
        converted to a tagged pointer. Since it occupies no space, it does not
        take room in the final object, but has an address. }
      wrtcod(ilodadr); { output load address operator }
      wrtlnk(gblestr); { output entry to load }
      wrtcod(icvtftg); { convert fixed to tagged pointer }
      wrtlnk(gblestr) { write fixed type }
         
   end;
   expect(crparen, erpexp, ss, []); { expect ')' }
   wrtcod(iassert) { assert }

end;

{*******************************************************************************

Parse procedure or function internal

Given a procedure/function entry, separates out built - in
procedures/functions, and executes the parser for those.

*******************************************************************************}
 
procedure parprcfnci(    proc:   boolean; { is a procedure/function }
                         ss:     tolkset; { skip set }
                         inhatt: boolean; { inherited attribute }
                         methld: boolean; { generate a method leader }
                         pp:     typptr;  { procedure/function entry }
                     var tp:     typptr); { return type }

var dc: prcfnc; { procedure/function dispatch code }

begin

   if fparse then writeln(':parse procedure or function internal'); 
   { get dispatch code }
   if pp^.t = tfunc then dc := pp^.fncd 
   else if pp^.t = tproc then dc := pp^.prcd
   else dc := pfnil; { else default to general (it's a parameter) }
   case dc of { procedure/function }

      pfnil:       parprcfnc(proc, ss, inhatt, methld, pp, tp); 
                                                        { p/f: general 
                                                               procedure/
                                                               function }
      pfabs:       pararthfnc(ss, dc, tp);              { f: abs }
      pfarctan:    pararthfnc(ss, dc, tp);              { f: arctan }  
      pfchr:       parchr(ss, tp);                      { f: chr }    
      pfcos:       pararthfnc(ss, dc, tp);              { f: cos }    
      pfeof:       pareofeoln(ss, dc, tp);              { f: eof }   
      pfeoln:      pareofeoln(ss, dc, tp);              { f: eoln }    
      pfexp:       pararthfnc(ss, dc, tp);              { f: exp }     
      pfln:        pararthfnc(ss, dc, tp);              { f: ln }    
      pfodd:       parodd(ss, tp);                      { f: odd }    
      pford:       parordprsc(ss, dc, tp);              { f: ord }   
      pfpred:      parordprsc(ss, dc, tp);              { f: pred }  
      pfround:     parrndtrc(ss, dc, tp);               { f: round }   
      pfsin:       pararthfnc(ss, dc, tp);              { f: sin }    
      pfsqr:       pararthfnc(ss, dc, tp);              { f: sqr }   
      pfsqrt:      pararthfnc(ss, dc, tp);              { f: sqrt }   
      pfsucc:      parordprsc(ss, dc, tp);              { f: succ }  
      pftrunc:     parrndtrc(ss, dc, tp);               { f: trunc } 
      pfexists:    parexists(ss, tp);                   { f: exists }
      pflocation:  parloclen(ss, dc, tp);               { f: location }
      pflength:    parloclen(ss, dc, tp);               { f: length }
      pfmax:       parmax(ss, tp);                      { f: max }
      pfdispose:   pardispnew(ss, dc);                  { p: dispose }
      pfget:       pargetputresrewclsupdapp(ss, dc);    { p: get }    
      pfnew:       pardispnew(ss, dc);                  { p: new }   
      pfpack:      parpack(ss);                         { p: pack }   
      pfpage:      parpage(ss);                         { p: page }    
      pfput:       pargetputresrewclsupdapp(ss, dc);    { p: put }   
      pfread:      parreadln(ss, dc);                   { p: read } 
      pfreadln:    parreadln(ss, dc);                   { p: readln }  
      pfreset:     pargetputresrewclsupdapp(ss, dc);    { p: reset }
      pfrewrite:   pargetputresrewclsupdapp(ss, dc);    { p: rewrite } 
      pfunpack:    parunpack(ss);                       { p: unpack } 
      pfwrite:     parwrite(ss, dc);                    { p: write } 
      pfwriteln:   parwrite(ss, dc);                    { p: writeln } 
      pfassign:    parassign(ss);                       { p: assign }  
      pfclose:     pargetputresrewclsupdapp(ss, dc);    { p: close }  
      pfposition:  parposition(ss);                     { p: position }
      pfdelete:    pardelete(ss);                       { p: delete }  
      pfchange:    parchange(ss);                       { p: change }  
      pfhalt:      parhalt;                             { p: halt }  
      pfrefer:     parrefer(ss);                        { p: refer }
      pfupdate:    pargetputresrewclsupdapp(ss, dc);    { p: update }  
      pfappend:    pargetputresrewclsupdapp(ss, dc);    { p: append }  
      pfsignal:    parsigwait(ss, dc);                  { p: signal }
      pfsignalone: parsigwait(ss, dc);                  { p: signalone }
      pfwait:      parsigwait(ss, dc);                  { p: wait }
      pfthrow:     parthrow;                            { p: throw }
      pfassert:    parassert(ss);                       { p: assert }
   
   end;
   { if procedure, then result is undefined }
   if proc then tp := gbludf

end;

{*******************************************************************************

Parse assignment

   assstat    = variable ':=' expr
  
Parses and generates an assignment. Accepts a tolken skip set.
The left side is already parsed, and the type is passed.

*******************************************************************************}

procedure parass(ss: tolkset; { skip set }
                 tp: typptr); { head symbol }

var tp1, tp2: typptr;  { type pointer }
    ti:       integer; { temp integer holder value }
    ts:       boolean; { temp integer holder sign }
    bt:       typptr;  { base type }

begin

   if fparse then writeln(':assignment');
   parexpr(nil, ss, tp1); { parse expression }
   { check assignment compatible with destination }
   if not typcmpa(tp, tp1) then begin

      perror(easscmp, [], []); { not assignment compatible }
      tp := gbludf; { set both types undefined }
      tp1 := gbludf

   end;
   bt := baset(tp); { find base of variable }
   if bt^.t in [tinteger, tlinteger, tcardinal, tlcardinal, tenum] then 
      wrtcod(istiint) { store integer }
   else if bt^.t = tsreal then begin
 
      { if assigning from integer, convert to real }
      if intt(tp1) then wrtcod(icvtitr);
      wrtcod(istisrl) { store short real }

   end else if bt^.t = treal then begin

      { if assigning from integer, convert to real }
      if intt(tp1) then wrtcod(icvtitr);
      wrtcod(istirel) { store real }

   end else if chart(bt) then begin

      { if the object is a string constant, this must be a character, so
        load it from the address. this is of course reliant on function
        results being unstructured }
      if tp1^.t = tscst then wrtcod(ildichr);
      wrtcod(istichr) { store character }

   end else if bt^.t = tboolean then 
      wrtcod(istibol) { store boolean }
   else if sett(bt) then wrtcod(istiset) { store set }
   else if (tp^.t = tgarry) and (tp1^.t = tgarry) then
      { both are general arrays }
      wrtcod(istigar) { store general array }
   else if bt^.t = tptr then begin

      tp2 := actt(bt^.ptrt); { find actual type for pointer }
      if tp2^.t = tgarry then begin { general array pointer }

         { if being assigned from nil, convert to wide }
         if tp1^.t = tnil then wrtcod(icvtntg);
         wrtcod(istitgp) { store tagged pointer }

      end else { normal pointer }
         wrtcod(istiint) { store integer }

   end else if bt^.t = treference then begin { object reference }

      if tp1^.t = tnil then begin { process converting operation for nil }

         wrtcod(icvtntr); { convert nil to reference }
         wrtcod(istiref); { store object reference pointer }
         wrtlnk(tp) { output source variable type as same }

      end else begin { normal reference assign }

         wrtcod(istiref); { store object reference pointer }
         wrtlnk(tp1) { output source variable type }

      end

   end else begin { structures }

      { if either side is general array, we must convert to fixed }
      if tp1^.t = tgarry then begin { convert tos }

         wrtcod(icvtgtf); { convert general array to fixed }
         wrtlnk(tp) { output fixed type }
         
      end else if tp^.t = tgarry then begin { convert sos }

         wrtcod(iswptop); { swap operands }
         wrtlnk(tp); { output sos type }
         wrtlnk(tp1); { output tos type }
         wrtcod(icvtgtf); { convert general array to fixed }
         wrtlnk(tp1); { output fixed type }
         { now both are fixed pointers }
         wrtcod(iswptop); { swap operands }
         wrtlnk(tp1); { output sos type (fixed) }
         wrtlnk(tp1); { output tos type (fixed) }
         tp := tp1 { set destination type as fixed, too }

      end;
      wrtcod(istisrc) { structured store }

   end;
   wrtlnk(tp); { output variable type }
   { check source is constant, and destination is not real, then
     check range of assignment if so. We except real because it
     may take an integer source even though it has no bounds itself }
   if (tp1^.t in [ticst, tscst, tccst, tenme]) and frange and 
      not realt(tp) and not strt(tp) then begin

      { get constant only if its not a string with length > 1 }
      if tp1^.t = tscst then begin

         if max(tp1^.sval^) > 1 then begin { > 1, just skip check }

            ti := lbound(tp);
            ts := lbounds(tp)

         end else begin { get value of single char constant }

            ti := consti(tp1);
            ts := constis(tp1)

         end

      end else begin { get constant }

         ti := consti(tp1);
         ts := constis(tp1)

      end;
      if ssltn(ts, ti, lbounds(tp), lbound(tp)) or 
         ssgtn(ts, ti, ubounds(tp), ubound(tp)) then
         perror(eassrng, [], []) { out of range }

   end

end;

{*******************************************************************************

Process label define

Processes a label location define on the passed symbol.

*******************************************************************************}

procedure deflab(sp: symptr); { label to define }

{ count referencing gotos in goto tracking list }

function cntgto(lp: typptr): integer;

var c:  integer; { count }
    gp: gtoptr;  { pointer for goto tracking list }

begin

   gp := stagto; { index top of goto list }
   c := 0; { clear count }
   while gp <> nil do begin { traverse }

      if gp^.lab = lp then c := c+1; { count referencing goto }
      gp := gp^.next { next entry }

   end;

   cntgto := c { return count }

end;

begin

   if fparse then writeln(':label define');
   if (sp^.typ^.t <> tlab) and (sp^.typ^.t <> tudf) then
      perror(esymtyp, [], [], sp^.lab^) { not a label }
   else if sp^.typ^.t = tlab then begin { is a valid label }

      { check label already defined }
      if sp^.typ^.ldef then perror(elabdef, [], [], nxtlab);
      { check definition is in same block as declared, disregarding 'with'
        levels }
      if sp^.lvl <> level-wthlvl then
         perror(elabblk, [], [], nxtlab); { not same block }
      { check block external references exist, and the label does not
        appear in the statement sequence of the defining block, as
        required by the standard. If the statement level is 1, or no
        block external references exists, then the check for lesser
        references is valid }
      if sp^.typ^.extr and (stalvl <> 1) then perror(elabext, [], [], nxtlab)
      else { check any references have occurred at lesser statement level }
         if sp^.typ^.mlvl < stalvl then 
            perror(elabrlv, [], [], nxtlab); { invalid }
      { Check number of references by gotos match number in goto list. If not,
        there is a referencing goto that is not in a block that can reach
        this label. If the statement level is 1, we don't do this check.
        Level 1 statements can be reached from anywhere, and could be
        from an external block. }
      if stalvl > 1 then 
         if cntgto(sp^.typ) < sp^.typ^.lref then 
            perror(elabrds, [], [], nxtlab);
      sp^.typ^.ldef := true; { set label has been defined }
      sp^.typ^.slvl := stalvl; { set statement level of label }
      { push label onto statement label list so we can find it for
        block scope checks }
      sp^.typ^.lnxt := stalab;
      stalab := sp^.typ;
      wrtcod(ilabequ); { output label equation }
      wrtlnk(sp^.typ) { output label type }

   end

end;

{*******************************************************************************

Parse simple statement

   selfass    = 'self' := expr

   procstat   = identifier ['(' plist ')']

   assstat    = variable ':=' expr
  
   funassstat = indentifier ':=' expr
                    
Parses and generates a simple statement. Accepts a tolken skip set.

*******************************************************************************}

procedure parsstat(ss:     tolkset; { skip set }
                   inhatt: boolean; { inherited attribute }
                   sp:     symptr;  { head symbol }
                   tp:     typptr); { head type }


var tp1, tp2: typptr;  { type pointers }
    bt:       typptr;  { base type pointer }
    over:     boolean; { is an overload }
    err:      errcod;  { last var mode error (unused) }

{ find function in block stack }

function fndfncblk(var tp: typptr): boolean;

var bp, fp: blkptr; { pointers to block }

begin

   bp := blkstk; { index top of block stack }
   fp := nil; { clear found pointer }
   while bp <> nil do begin

      if bp^.mark = tp then fp := bp; { found }
      bp := bp^.next { next block entry }

   end;

   fndfncblk := fp <> nil { return result }

end;

{ find matching function in overload list or override }

function fndfncovl: typptr;

var pp, fp: typptr; { procedure pointer }

begin

   fp := nil; { set no function found }
   if sp <> nil then begin { there is a symbol }

      pp := sp^.typ; { set 1st entry }
      if (pp^.t = tproc) or (pp^.t = tfunc) then { is a procedure or function }
         while pp <> nil do begin

         { find which overload is outside our level }
         if fndfncblk(pp) and (pp^.t = tfunc) then fp := pp; { found }
         { index next overload, if any }
         if pp^.t = tproc then pp := pp^.prco
         else if pp^.t = tfunc then pp := pp^.fnco
         else error(esflt40, true) { should be one of those }

      end;
      if fp = nil then begin { not found, try override }

         pp := sp^.typ; { set 1st entry }
         { match procedure }
         if pp^.t = tproc then begin

            if fndfncblk(pp^.prcz) then fp := pp^.prcz

         end else if pp^.t = tfunc then begin

            if fndfncblk(pp^.fncz) then fp := pp^.fncz

         end

      end

   end;

   fndfncovl := fp { return result }

end;

{ find if is function, or function in overload list }

function ovlfnc(tp: typptr): boolean;

var f: boolean;

begin

   f := false; { set not found }
   while tp <> nil do begin { traverse }

      if tp^.t = tproc then tp := tp^.prco
      else if tp^.t = tfunc then begin { found }

         f := true; { set found }
         tp := nil { stop }

      end else tp := nil { should be one of those, terminate }

   end;

   ovlfnc := f { return result }

end;

begin

   if fparse then writeln(':simple statement');
   if nxttlk = cbcms then begin { function or variable := .. assign }

      { check is a function, including on any overload list }
      if ovlfnc(tp) then begin { function result assign }

         { The symbol is a function, and at least one entry in the overload list
           is a function. Now find if any of the overload functions are
           currently activated as blocks, and use that if possible. Otherwise,
           its an error, as none of the overloads are active. }
         tp2 := fndfncovl; { get nested function }
         if tp2 = nil then 
            perror(efaslvl, [], []); { function assign not this level }
         if tp2 <> nil then tp := tp2; { set the correct overload }
         wrtcod(ilodfadr); { load function result address }
         wrtlnk(tp); { output function type }
         gettlk; { skip ':=' }
         parexpr(nil, ss, tp1); { parse expression }
         { if the object is a string constant, this must be a character, so
           load it from the address. this is of course reliant on function
           results being unstructured }
         if tp1^.t = tscst then wrtcod(ildichr);
         { we need to bypass this section if the function is not the correct
           one, because this messes with the wrong function, or even a system
           function ! }
         if tp2 <> nil then begin { assignment is correct }

            { check is a function, and not a procedure }
            if tp^.t <> tfunc then perror(easprc, [], [])
            else begin { is a function }

               { check assignment compatible with function result }
               if not typcmpa(tp^.fncr, tp1) then perror(easscmp, [], []);
               sp^.ref := sp^.ref - 1; { back out superfluous reference }
               tp^.fncc := tp^.fncc+1; { count function references }
               { check if integer result to real function }
               if (realt(tp^.fncr)) and intt(tp1) then begin

                  wrtcod(icvtitr); { convert to real }
                  tp1 := gblreal { set real }

               end;
               bt := baset(tp1); { find base of expression }
               if bt^.t = tptr then begin { store pointer }

                  if bt^.ptrt^.t = tgarry then { general array pointer }
                     wrtcod(istiftgp) { store tagged pointer }
                  else { normal pointer }
                     wrtcod(istifint) { store integer }

               end else if bt^.t in [tinteger, tlinteger, tcardinal, tlcardinal,
                                     tenum, tnil] then
                  wrtcod(istifint) { store integer }
               else if bt^.t = tsreal then 
                  wrtcod(istifsrl) { store short real }
               else if bt^.t = treal then wrtcod(istifrel) { store short real }
               else if chart(bt) then wrtcod(istifchr) { store character }
               else wrtcod(istifbol); { store boolean }
               wrtlnk(tp) { output function type }

            end

         end

      end else begin { variable assign }

         { we have established by context that the label is a variable
           reference, so we process it as a variable }
         threaten(sp, tp); { process threat }
         parvar(ss, sp, false, tp, err); { parse variable }
         gettlk; { skip ':=' }
         parass(ss, tp) { process assignment }

      end

   end else if nxttlk in [clparen, cend, cscn, cuntil, celse] then
      begin

      over := chkovld(tp); { check its an overload }
      { check procedure label }
      if (tp^.t <> tproc) and (tp^.t <> tpproc) and
         (tp^.t <> tudf) and not over then
         perror(embproc, [], [], sp^.lab^); { must be procedure }
      if sp^.typ^.t <> tudf then { not undefined }
         { parse procedure call }
         parprcfnci(true, ss, inhatt, true, sp^.typ, tp)

   end else begin { process complex left side, or missing ':=' }

      threaten(sp, tp); { process threat to variable }
      parvar(ss, sp, false, tp, err); { parse variable }
      if tp^.t = tproc then begin

         { its a method }
         over := chkovld(tp); { check its an overload }
         if sp^.typ^.t <> tudf then { not undefined }
            parprcfnci(true, ss, inhatt, false, tp, tp) { parse procedure call }

      end else begin
 
         { its an assignment }
         expect(cbcms, ebcmexp, [cbcms]+exprset+ss, []); { expect ':=' }
         parass(ss, tp) { process assignment }

      end

   end

end;

{*******************************************************************************

Parse statement

   statement  = [label':'] kstatement

   label      = integer | identifier
  
   kstatement = assstat |  funasstat | procfncstat |
                blockstat | ifstat | casestat |
                while | repeat | for | with |
                goto | null

   assstat    = variable ':=' expr
  
   funassstat = indentifier ':=' expr
                    
Parses and generates a statement. Accepts a tolken skip set.
Error recovery:

1. Missing ':' after label, skips to likely statement.

2. Missing indentifier before ':=', accepted as assignment.

3. Missing ':=' in assignment, skip to likely expression.

4. ':=' mistaken as '=', skip to likey expression (actually
rule 3).

*******************************************************************************}

procedure parstat(ss: tolkset);

var waslab:  boolean; { label was parsed }
    sp:      symptr;  { symbol pointer }
    inhatt:  boolean; { inherited attribute }
    tp:      typptr;  { type pointer }

{ parse non-assign statement }

procedure parnastat(ss: tolkset);

begin

   { check possible tolken misspell }
   chktkmp(nxtlab, [cbegin, cif, ccase, cwhile, crepeat, cfor, cwith, cgoto]);
   if nxttlk in [cbegin, cif, ccase, cwhile, crepeat, cfor, cwith,
                       cgoto, ctry] then case nxttlk of

      { statement }
      cbegin:  parstatb(ss);  { statement block }
      cif:     parif(ss);     { 'if' statement }
      ccase:   parcase(ss);   { 'case' statement }
      cwhile:  parwhile(ss);  { while }
      crepeat: parrepeat(ss); { repeat }
      cfor:    parfor(ss);    { for }
      cwith:   parwith(ss);   { with }
      cgoto:   pargoto(ss);   { goto }
      ctry:    partry(ss)     { try }

   end

end;

{ parse full assignment leader. Processes a construct of:

     'inherited' identifier |
     'self' |
     identifier

  if the 'inheritied' construct is seen, the following symbol is verified as
  being a procedure or function, since that is all this attribute can be
  applied to.

}

procedure parasslead(    ss:     tolkset; { skip set }
                     var inhatt: boolean; { 'inherited' attribute }
                     var sp:     symptr;  { symbol seen }
                     var tp:     typptr); { type of symbol }

begin

   sp := nil; { set no symbol }
   tp := gbludf; { set no type }
   inhatt := false; { set no inherited attribute }
   if nxttlk = cinherited then begin { inherited attribute }

      gettlk; { skip "inherited" }
      inhatt := true;
      if nxttlk <> cidentifier then 
         perror(eidnexp, [], []) { identifier expected }
      else parvarlead(ss, sp, tp); { parse variable leader }
      if sp <> nil then { there is a symbol }
         if not (sp^.typ^.t in [tfunc, tpfunc, tproc, tpproc]) then
            perror(einhmbpfc, [], []) { invalid use of inherited }

   end else if nxttlk in [cself, cidentifier] then 
      parvarlead(ss, sp, tp) { process 'self' reference or identifier }
   else begin { nothing found }

      if fansi then perror(eidnexp, [], []) { identifier expected }
      else perror(eidsexp, [], []); { 'self'/identifier expected }

   end

end;

begin

   if fparse then writeln(':statement');
   waslab := false; { set last wasn't label }
   if nxttlk = cinteger then begin { standard label }

      numlab(nxtint, nxtlab); { convert and normalize label number }
      if nxtint > 9999 then { greater than ansi max ? }
         perror(einvgln, [], [], nxtlab); { invalid label number }
      find(nxtlab, sp); { lookup symbol }
      deflab(sp); { define that label }
      gettlk; { next }
      expect(ccln, eclnexp, [ccln]+statuset+ss, []); { expect ':' }
      if nxttlk = ccln then gettlk; { skip ':' }
      waslab := true { set label encountered }

   end;
   { check possible tolken misspell }
   chktkmp(nxtlab, [cbegin, cif, ccase, cwhile, crepeat, cfor, cwith, cgoto,
                    ctry, cinherited]);
   if nxttlk in [cidentifier, cbcms, cinherited, cself] then begin

      { procedure, function, assignment or extended label }
      parasslead(ss, inhatt, sp, tp); { parse assignment leader }
      { if the next is ':', and there is a symbol, and not 'self', and a integer
        label was not already parsed, it is an extended line label. }
      if (nxttlk = ccln) and (sp <> nil) and (sp <> selflab) and not waslab and 
         not fansi then begin

         { it's an extended label }
         if sp <> nil then deflab(sp); { define extended label }
         sp := nil; { set label is resolved }
         gettlk; { skip ':' }
         { we processed an extended label. now we must parse a statement from
           the top of the syntax, but without the ability to define a label }
         if nxttlk in [cidentifier, cbcms, cinherited, cself] then begin

            { procedure, function or assignment }
            parasslead(ss, inhatt, sp, tp); { parse assignment leader }
            parsstat(ss, inhatt, sp, tp) { parse simple statement }

         end else parnastat(ss) { parse non-assign statement }

      end else parsstat(ss, inhatt, sp, tp) { parse simple statement }

   end else parnastat(ss) { parse non-assign statement }

end;

{*******************************************************************************

Parse ordinal type

   ordinal = typeid | constant '..' constant | 
             '(' identifier [',' identifier].. ')'

Parses the ordinal type. Accepts a skip tolken set.
Error recovery:

1. Missing id in enumeration, skip to ',', ')' or id.

2. Missing ')' in enumeration, skip to ',', ')' or id.

3. Missing '..' after obvious head tolken, skip to likely 
constant, or '..'.

*******************************************************************************}

procedure parord(ss: tolkset; var tp: typptr);

var sp:           symptr;  { pointer for symbol }
    tp1, tp2, lp: typptr;  { pointers for type }
    c:            integer; { enumeration count }
    lab:          labl;    { label for undefines }

begin

   if fparse then writeln(':ordinal type');
   if not (nxttlk in ordset) then 
      { we just don't have any valid leader, so we produce a reasonable error
        message here and attempt a restart }
      perror(eordexp, [cidentifier, clparen, crange]+constset+ss, []);
   if nxttlk = cidentifier then begin 

      { type id or subrange }
      parqualident(ss, true, true, true, '', sp, lab); { parse qualified identifier }
      if nxttlk = crange then begin { subrange }

         tp1 := actt(sp^.typ); { get type of 1st }
         typcon(tp1, [ticst, tscst, tccst, tenme, tudf]); { check proper type }
         chkschr(tp1); { if string, check is single character }
         gettlk; { skip '..' }
         parconst(ss, tp2); { parse end constant }
         typcon(tp2, [ticst, tscst, tccst, tenme, tudf]); { check proper type }
         chkschr(tp2); { if string, check is single character }
         if not typcmp(tp1, tp2) then { types don't match }
            begin perror(etypcmp, [], []); tp1 := gbludf end;
         if (tp1^.t <> tudf) and (tp2^.t <> tudf) then begin { operands valid }

            lsttyp(tp, tsub); { get subrange entry }
            tp^.subl.v := consti(tp1); { place lower bound value }
            tp^.subl.s := constis(tp1); { place lower bound sign }
            tp^.subu.v := consti(tp2); { place upper bound value }
            tp^.subu.s := constis(tp2); { place upper bound sign }
            if tp1^.t = ticst then tp^.subt := gblint { set type is integer }
            else if (tp1^.t = tscst) or (tp1^.t = tccst) then
               tp^.subt := gblchr { set type is char }
            else tp^.subt := tp1^.enh; { set same type as enumerated }
            { check lower >= upper }
            if ssgtn(tp^.subl.s, tp^.subl.v, tp^.subu.s, tp^.subu.v) then 
               perror(einvsub, [], [])

         end else tp := gbludf

      end else begin { type id }

         tp := actt(sp^.typ); { get type }
         { check proper type }
         typcon(tp, [tenum, tsub, tptr, tarray, tgarry, tfile, tset, trecord,
                     tinteger, tlinteger, tcardinal, tlcardinal, tchar,
                     tboolean, treal, tsreal, ttext, tsemaphore, treference,
                     texception, tudf]);
         if (tp^.t = tsemaphore) and (modhead <> cmonitor) then perror(esemmod, [], [])

      end

   end else if nxttlk = clparen then begin { enumerative }

      lsttyp(tp, tenum); { get enumerated type entry }
      lp := nil; { set no last entry }
      c := 0; { clear enumeration count }
      repeat { fields }

         if (nxttlk = clparen) or (nxttlk = ccma) then 
            gettlk; { skip '(' or ',' }
         if nxttlk <> cidentifier then
            { no identifier found }
            perror(eidnexp, [ccma, crparen, cidentifier]+ss, []);
         sp := nil; { set no symbol exists }
         if nxttlk = cidentifier then begin { id found }

            define(nxtlab, sp); { define symbol }
            lsttyp(tp1, tenme); { get enumeration entry }
            sp^.typ := tp1; { link to symbol }
            tp1^.enh := tp; { link to head }
            tp1^.env := c; { place value }
            tp1^.enx := nil; { set end of list }
            if lp = nil then tp^.enc := tp1 { first entry, set link to head }
            else lp^.enx := tp1; { link to last }
            lp := tp1; { set new last entry }
            c := c + 1; { count enumerators }
            gettlk; { skip id }
   
         end;
         if (nxttlk <> ccma) and (nxttlk <> crparen) then
            { we don't have an exit tolken }
            perror(erpcmexp, [ccma, crparen, cidentifier]+ss, [])

      { until not ',' and no more identifiers }
      until (nxttlk <> ccma) and (nxttlk <> cidentifier);
      if nxttlk = crparen then gettlk; { skip ')' }
      if tp^.enc = nil then tp := gbludf { if null list, set undefined }

   end else begin { subrange }

      { the overall error check would have reported a missing
        head check. See if we have anything to work with }
      if nxttlk in [crange]+constset then begin

         { possible subrange construct, we can skip a missing
           head here because of the preceding error report }
         tp1 := gbludf; { default operands to undefined }
         tp2 := gbludf;
         if nxttlk <> crange then { not already at '..' }
            parconst(ss+[crange], tp1); { parse start constant }
         typcon(tp1, [ticst, tscst, tccst, tenme, tudf]); { check proper type }
         chkschr(tp1); { if string, check is single character }
         if nxttlk <> crange then
            { we got here by '..' after missing head, or
              head found by resync. Either way the double
              error seems justified }
            perror(erngexp, constset+[crange]+ss, []);
         if nxttlk = crange then gettlk; { next }
         parconst(ss, tp2); { parse end constant }
         typcon(tp2, [ticst, tscst, tccst, tenme, tudf]); { check proper type }
         chkschr(tp2); { if string, check is single character }
         if not typcmp(tp1, tp2) then { types don't match }
            begin perror(etypcmp, [], []); tp1 := gbludf end;
         if (tp1^.t <> tudf) and (tp2^.t <> tudf) then begin { operands valid }

            lsttyp(tp, tsub); { get subrange entry }
            tp^.subl.v := consti(tp1); { place lower bound value }
            tp^.subl.s := constis(tp1); { place lower bound sign }
            tp^.subu.v := consti(tp2); { place upper bound value }
            tp^.subu.s := constis(tp2); { place upper bound sign }
            if tp1^.t = ticst then tp^.subt := gblint { set type is integer }
            else if (tp1^.t = tscst) or (tp1^.t = tccst) then
               tp^.subt := gblchr { set type is char }
            else tp^.subt := tp1^.enh; { set same type as enumerated }
            { check lower >= upper }
            if ssgtn(tp^.subl.s, tp^.subl.v, tp^.subu.s, tp^.subu.v) then 
               perror(einvsub, [], [])

         end else tp := gbludf { set undefined }

      end else tp := gbludf { set undefined }

   end

end;

{*******************************************************************************

Parse field list

   field list = identifier [',' identifier].. ':' 
                type [';'] [casefield] | [casefield]
   casefield  = 'case' [identifier ':'] identifier
                'of' sublist continue
   sublist    = constant [',' constant] ':' '(' 
                fieldlist ')' 
   continue   = [';'] | [';' sublist]..

Parses the field list. Accepts a skip tolken set.
Error recovery:

1. Missing id on head. We take something of a leap and assume
that ':' or ',' is a missing id. This assumes that the likelyhood
missing id is unlikely. So we break the rule about minding 
our own syntactical business.

2. Missing id on head (with distinct precident), skip to ':',
',' or id

3. Missing ':', skip to ':', ',' or id.

4. Missing id after 'case', skip to ':', 'of', id.

5. Missing id after ':', skip to 'of', id.

6. Missing 'of', skip to 'of', ',', ':', '(', likely constant.

7. Missing ':' after case selector, skip to ',', ':', likely
constant.

8. Missing '(',  skip to '(', or 'case', ':', ',', id, based on
entry set for field list (see 1).

9. Missing ')', skip to ')', ';'.

*******************************************************************************}

procedure parfield(ss: tolkset;     { skip set }
                   var tp: typptr;  { return type }
                   var sp: symptr;  { symbols list }
                   var ls: symptr); { last symbol in list }

var last:         tolken; { parse aid }
    lt:           typptr; { last type entry }
    ts:           symptr; { symbol pointer }
    tl:           typptr; { type sublist pointer }
    tt, tt1, tt2: typptr; { type pointer }
    tg:           typptr; { tag field pointer }
    lab, lab1:    labl;   { label save }

{ sort variant case list for order }

procedure srttag(var tp: typptr);

var tl:      typptr; { sort destination list }
    tt, tt1: typptr; { type entry pointers }
    lt:      typptr; { last type entry }

begin

   { sort case list for order, so that we may check for gaps and limits }
   tl := nil; { clear destination list }
   while tp <> nil do begin { remove entries from source list }
  
      tt := tp; { index top type entry }
      tp := tp^.fcsn; { gap from source list }
      if tl = nil then { destination list is empty }
         begin tl := tt; tt^.fcsn := nil end { insert at list top }
      else if ssgtn(tl^.fcss, tt^.fcss) then 
         { new < dest }
         begin tt^.fcsn := tl; tl := tt end { insert at top }
      else begin { in list middle somewhere }

         tt1 := tl; { index top of list }
         while tt1 <> nil do begin

            lt := tt1; { set pointer to last }
            tt1 := tt1^.fcsn; { index next }
            if tt1 <> nil then { there is a next entry } 
               if ssgtn(tt1^.fcss, tt^.fcss) then 
                  tt1 := nil; { entry found, stop }

         end;
         tt^.fcsn := lt^.fcsn; { link new to next }
         lt^.fcsn := tt { link new to last }

      end

   end;
   tp := tl { place sorted list }

end;

{ check case list for gaps and limits.
  The list must be sorted in acending order }

procedure chkgap(tp: typptr;               { case list to check }
                 sl: boolean; l: integer;  { lower bound of tag }
                 su: boolean; u: integer); { upper bound of tag }

var ti: integer; { temp value }
    ts: boolean; { temp sign }
    lp: typptr;  { last in list }

begin

   if tp <> nil then begin { not empty list }

      if ssnequ(sl, l, tp^.fcss) then
         perror(emcasv, [], []); { lower constant missing }
      l := tp^.fcse.v; { set start to end }
      sl := tp^.fcse.s;
      lp := tp; { save last }
      tp := tp^.fcsn; { next entry }
      while tp <> nil do begin { traverse list }

         { find last constant+1 }
         ti := ssadd(sl, l, false, 1);
         ts := ssadds(sl, l, false, 1);
         { check this constant equal to last + 1, else error and terminate }
         if ssnequ(tp^.fcss, ts, ti) then begin

            { case constants not in order }
            if ssleq(lp^.fcss, tp^.fcse) and ssgeq(lp^.fcse, tp^.fcss) then
               perror(edcasv, [], []) { case duplicate }
            else 
               perror(emcasv, [], []); { case missing }
            tp := nil { terminate }

         end else begin { entry ok }
   
            l := tp^.fcse.v; { place new last constant }
            sl := tp^.fcse.s;
            lp := tp; { save last }
            tp := tp^.fcsn { next entry }
   
         end

      end;
      if (l <> u) or (sl <> su) then 
         perror(emcasv, [], []) { upper constant missing }

   end

end;

{ search for matching label in the record.
  Record fields have their own scope outside of the normal symbol table system,
  so they have their own search and placement procedures }

function recsym(var lab: labl): symptr; { returns the matching symbol }

var ts, fs: symptr; { pointer for symbols }

begin

   ts := sp; { index the top of the list }
   fs := nil; { set no symbol found }
   while ts <> nil do begin { traverse symbols }

      if compp(lab, ts^.lab^) then begin { entry found }

         fs := ts; { place result symbol pointer }
         ts := nil { terminate search }

      end else ts  := ts^.rnxt { index next entry }

   end;

   recsym := fs { return result }

end;

{ define new label in record }

procedure definer(var syp:  symptr; { returned symbol entry }
                  var lab: labl);   { label to place }

begin

   syp := recsym(lab); { find previous symbol }
   if syp <> nil then begin { duplicate symbol }

      perror(edupsym, [], [], lab);
      syp^.dup := true { set symbol is duplicate }

   end else begin { define new symbol }

      getsym(syp); { get symbol entry }
      new(syp^.lab, len(lab)); { get a label entry }
      copy(syp^.lab^, lab); { place the label }
      if sp = nil then sp := syp; { if label list empty, set 1st }
      if ls <> nil then ls^.rnxt := syp; { link to last if exists }
      ls := syp { set new last entry }

   end

end;
  
begin

   if fparse then writeln(':field list');
   tp := nil; { set no type result }
   lt := nil; { set no last type }
   { parse fixed part }
   if not (nxttlk in [cidentifier, ccase, crparen, cend]) then 
      { there is no leader }
      perror(einvfld, [cidentifier, ccase, crparen, cend, ccln, ccma]+ss, []);
   if (nxttlk = cidentifier) or (nxttlk = ccln) or (nxttlk = ccma) then 
      begin { standard field }

      { identifier head found, or ':', which we assume is a missing id }
      repeat { sections }

         tl := nil; { set no types sublist }
         repeat { fields }

            if nxttlk <> cidentifier then { no indentifier found }
               perror(eidnexp, [ccma, ccln, cidentifier]+ss, []);
            if nxttlk = cidentifier then begin { id found }

               definer(ts, nxtlab); { define record symbol }
               lsttyp(tt, tfield); { get a field entry }
               ts^.typ := tt; { link to symbol }
               tt^.fldn := nil; { terminate }
               if tp = nil then tp := tt; { if type list empty, set 1st }
               if tl = nil then tl := tt; { if type sublist empty, set 1st }
               if lt <> nil then lt^.fldn := tt; { link to last if exists }
               lt := tt; { set new last entry }
               gettlk; { skip id }

            end;
            if (nxttlk <> ccma) and (nxttlk <> ccln) then
               { we don't have an exit tolken }
                  perror(ecncmexp, [ccma, ccln, cidentifier]+ss, []);
            last := nxttlk; { save next }
            if last = ccma then gettlk { next }

         { until not ',' and no more identifiers }
         until (last <> ccma) and (nxttlk <> cidentifier);
         if nxttlk = ccln then gettlk; { skip ':' }
         partype([cscn]+ss, tt); { parse type }
         { check attempt to allocate general array }
         if tt^.t = tgarry then perror(ealcgar, [], []); 
         while tl <> nil do begin { apply that type to all fields in section }

            tl^.fldt := tt; { place type }
            tl := tl^.fldn { next entry }

         end;
         if not (nxttlk in [cscn, cend, crparen]) then 
            { we don't have a follow tolken }
            perror(escrpedexp, [cscn, crparen, cend, ccase, cidentifier]+ss, 
                   []);
         if nxttlk = cscn then gettlk; { next }
         if not (nxttlk in [cidentifier, ccase, crparen, cend]) then 
            { there is no leader }
            perror(einvfld, [cidentifier, ccase, crparen, cend, ccln, ccma]+ss, 
                   [])

      { until not likely next field }
      until not (nxttlk in [cidentifier, ccln, ccma]);
      { if no fields found, set result undefined }
      if tp = nil then tp := gbludf

   end;
   { parse variant-part }
   if nxttlk = ccase then begin { variant section }

      gettlk; { next }
      if nxttlk <> cidentifier then { no identifier found }
         perror(eidnexp, [ccln, cof, cidentifier]+ss, []);
      lab[1] := ' '; { clear label }
      if nxttlk = cidentifier then begin { tag field or type exists }

         { save the label for later use, since we don't know which kind it is 
           yet }
         lab := nxtlab;
         gettlk { skip id }

      end;
      if (nxttlk <> ccln) and (nxttlk <> cof) then { no follow tolken }
         perror(eofcnexp, [ccln, cof, ccma, clparen]+constset+ss, []);
      lsttyp(tg, tftag); { get a tag entry }
      if tp = nil then tp := tg; { if type list empty, set 1st }
      if lt <> nil then lt^.fldn := tg; { link to last if exists }
      lt := tg; { set new last entry }
      tg^.ftgc := nil; { clear case list }
      tg^.ftge := false; { set tagfield does not exist }
      tg^.ftgt := gbludf; { set undefined type }
      if nxttlk = ccln then begin { tag field type }

         gettlk; { next }
         if lab[1] <> ' ' then begin { there was a label }

            { we know now that the last id was the label for the tag, so we
              complete it's processing here }
            definer(ts, lab); { define record symbol }
            ts^.typ := tg { link type entry to symbol }

         end;
         tg^.ftge := true; { set tagfield exists }
         lab[1] := ' '; { clear label }
         if nxttlk <> cidentifier then { no identifier found }
            perror(eidnexp, [cof, cidentifier]+ss, []);
         if nxttlk = cidentifier then begin { id found }

            lab := nxtlab; { and now the type label gets saved so that we look
                             just as the free union case }
            gettlk { skip id }

         end

      end;
      if lab[1] <> ' ' then begin { there is a type label }

         { The saved label contains the start of a qualident for the type. We
           have already passed that in the parse, so we perform a qualident
           parse with the head label already defined. }
         parqualident(ss, true, true, true, lab, ts, lab1);
         tt := ts^.typ; { get type }
         if tt = nil then error(esflt8, true); { fault on no type }
         { check proper type }
         typcon(tt, [tenum, tsub, tinteger, tlinteger, tcardinal, tlcardinal,
                     tchar, tboolean]);
         tg^.ftgt := tt { place base type }

      end;
      { expect 'of' }
      expect(cof, eofexp, [cof, ccma, ccln, clparen]+constset+ss, 
             [cof]);
      lt := nil; { set no last type }
      repeat { case fields }

         tl := nil; { set no types sublist }
         repeat { case selectors }

            parconst([ccma, ccln, crange]+ss, tt); { parse constant }
            chkschr(tt); { if string, check is single character }
            { check proper type }
            typcon(tt, [ticst, tscst, tccst, tenme, tudf]);
            { compare type with type of tag field }
            if not typcmp(tt, tg^.ftgt) then perror(etypcmp, [], []);
            tt2 := tt; { set high tag constant equal to low }
            { check range of tag constants }
            if nxttlk = crange then begin

               gettlk; { skip '..' }
               parconst([ccma, ccln, crange]+ss, tt2); { parse constant }
               chkschr(tt2); { if string, check is single character }
               { check proper type }
               typcon(tt2, [ticst, tscst, tccst, tenme, tudf]);
               { compare type with type of tag field }
               if not typcmp(tt2, tg^.ftgt) then perror(etypcmp, [], []);

            end;
            if tt^.t <> tudf then begin { if defined, start case entry }

               lsttyp(tt1, tfcas); { get case type entry }
               tt1^.fcsn := nil; { terminate }
               tt1^.fcss.v := consti(tt); { place low case constant value }
               tt1^.fcss.s := constis(tt); { place low case constant sign }
               tt1^.fcse.v := consti(tt2); { place high case constant value }
               tt1^.fcse.s := constis(tt2); { place high case constant sign }
               if not ssleq(tt1^.fcss, tt1^.fcse) then perror(einvtrng, [], []); 
               { if tag constant list is empty, set 1st entry }
               if tg^.ftgc = nil then tg^.ftgc := tt1;
               if lt <> nil then lt^.fcsn := tt1; { link to last if exists }
               if tl = nil then tl := tt1; { if type sublist empty, set 1st }
               lt := tt1 { set new last entry }

            end;
            if (nxttlk <> ccma) and (nxttlk <> ccln) then
               { we don't have an exit tolken }
               perror(ecncmexp, [ccma, ccln, clparen]+constset+ss, 
                        [cof]);
            last := nxttlk; { save next }
            if nxttlk = ccma then gettlk { next }

         { until not ',' or likely constant }
         until (last <> ccma) and not (last in constset);
         if nxttlk = ccln then gettlk; { skip ':' }
         expect(clparen, elpexp, [clparen, ccase, ccln, ccma, cidentifier]+ss, 
                []);
         parfield([crparen, cscn]+ss, tt, sp, ls); { parse field list }
         { copy field list, perhaps multiply, to all the variant case entries
           so attached }
         while tl <> nil do begin 

            { apply that field list to all case entries in section.
              note that the same field list can exist on more than
              one case entry }
            tl^.fcsf := tt; { place field list }
            tl := tl^.fcsn { next entry }

         end;
         { ')' expected }
         expect(crparen, erpexp, [crparen, cscn]+constset+ss, []);
         if not (nxttlk in [cscn, cend, crparen]) then 
            { we don't have a follow tolken }
            perror(escrpedexp, [cscn, crparen, cend, ccma, ccln]+constset+ss,
                   []);
         if nxttlk = cscn then gettlk { next }

      { until not concevable leader for next case }
      until not (nxttlk in [ccma, ccln]+constset);
      if tg^.ftgc <> nil then begin { there is a case list }

         { sort case list for order, so that we may check for gaps and limits }
         srttag(tg^.ftgc);
         { check gaps and limits }
         if tg^.ftgt^.t <> tudf then { tagfield is not undefined }
            chkgap(tg^.ftgc, lbounds(tg^.ftgt), lbound(tg^.ftgt), 
                             ubounds(tg^.ftgt), ubound(tg^.ftgt))

      end else tp := gbludf { else set undefined }

   end

end;

{*******************************************************************************

Parse type

   type      = ordinal | '^' identifier | ['packed'] composite
   composite = 'array' '[' ordinal [',' ordinal ']' 'of' type |
               'file' 'of' type | 'set' 'of' type |
               'record' field list 'end'

Parses a type. Accepts a skip tolken set.
Error recovery:

1. Missing type id after '^', skip to next.

2. Missing '[' after 'array', skip to '[', ',', id or
likely ordinal type.

3. Missing index type, skip to ',', ']' or likely ordinal type.

4. Missing 'of', skip to 'of' or likely type.

5. Missing 'of' after 'file', skip to 'of' or likely type.

6. Missing 'of' after 'set', skip to 'of' or likely type.   

7. Missing 'end' after record construct, skip to next.

8. No apparent type, skip to type leader.

9. No proper type following 'packed', skip to packable type.

*******************************************************************************}

procedure partype(ss: tolkset; var tp: typptr);

var pack:         boolean; { 'packed' applied }
    last:         tolken;  { parse aid }
    sp, sp1, ts:  symptr;  { pointer to symbol }
    tp1, tp2, lp: typptr;  { type entry pointers }
    valid:        boolean; { type valid flag }
    lab:          labl;    { label for undefines }

{ place record head entries in field list }

procedure plchead(tp, hd: typptr);

begin

   while tp <> nil do begin { place head linkages }

      if tp^.t = tfield then begin { standard field }

         tp^.fldh := hd; { link to head }
         tp := tp^.fldn { next entry }

      end else if tp^.t = tftag then begin { tag field }

         tp^.ftgh := hd; { place head linkage }
         tp := tp^.ftgc { index first constant entry }

      end else if tp^.t = tfcas then begin { variant case }

         plchead(tp^.fcsf, hd); { place head for sublist }
         tp := tp^.fcsn { next entry }

      end else error(esflt9, true) { no valid entry }

   end

end; 

begin

   if fparse then writeln(':type');
   tp := gbludf; { set result undefined }
   if not (nxttlk in typeset) then { no type leader }
      perror(etypexp, [clbrkt]+typeset+ss, []);
   if nxttlk = ccmf then begin { pointer }

      gettlk; { next }
      if nxttlk <> cidentifier then { no id }
         perror(eidnexp, [cidentifier]+ss, []);
      if nxttlk = cidentifier then begin

         { Pointers get special processing. If the pointer target is undefined,
           we assume it is forward declared and create "to be defined" entry.
           This entry will invoke the same errors as if the symbol was totally
           undefined, until it is truly defined, except that other pointer
           references can also be made. Unfortunately, this bypasses our 
           misspell checks, since we MUST assume that an undefined pointed
           to will be defined later (even if it is really a mistake) }
         parqualident([], true, false, true, '', sp, lab); { parse qualident 
                                                             with no default 
                                                             define }
         if sp = nil then begin 

            { base type is undefined, create delayed definition }
            plcsym(lab, sp); { place new symbol }
            sp^.ddf := true; { flag as delayed definition }
            lsttyp(tp, tddf); { get delayed definition entry }
            sp^.typ := tp; { link symbol to entry }
            tp^.ddfs := sp; { link entry to symbol for error processing }
            tp^.ddft := gbludf; { set as undefined until definition point }
            tp^.ddfd := false; { set no definition }
            tp^.ddfe := false; { set no error processed }
            tp^.ddfr := nil { clear downreference symbol }

         end else if sp^.hld then begin { symbol is in holding }

            { we will essentially just convert the held symbol to a delayed
              definition. This basically just changes the types of messages
              output for errors }
            sp^.ddf := true; { flag as delayed definition }
            sp^.hld := false; { remove holding }
            lsttyp(tp, tddf); { get delayed definition entry }
            sp^.typ := tp; { link symbol to entry }
            tp^.ddfs := sp; { link entry to symbol for error processing }
            tp^.ddft := gbludf; { set as undefined until definition point }
            tp^.ddfd := false; { set no definition }
            tp^.ddfe := false; { set no error processed }
            tp^.ddfr := nil { clear downreference symbol }

         end else if sp^.lvl <> level then begin

            { For downreferences, we create an alias at this level that has a
              delyed definition pointing to the downreference. This can be
              redefined by a defining point in this scope. }
            plcsym(lab, sp1); { place new symbol }
            sp1^.dra := true; { set is a downreference alias }
            lsttyp(tp, tddf); { get delayed definition entry }
            sp1^.typ := tp; { link symbol to entry }
            tp^.ddfs := sp1; { link entry to symbol for error processing }
            tp^.ddft := sp^.typ; { attach to downreference type }
            tp^.ddfd := true; { set defined }
            tp^.ddfe := false; { set no error processed }
            tp^.ddfr := sp; { set downreference symbol for processing }
            sp := sp1 { now reference that symbol }

         end;
         sp^.ref := sp^.ref + 1; { increment reference counter }
         { check proper type }
         tp1 := sp^.typ; { copy so we don't trash it }
         typcon(tp1, [tenum, tsub, tptr, tarray, tgarry, tfile, tset, trecord,
                      tinteger, tlinteger, tcardinal, tlcardinal, tchar,
                      tboolean, treal, tsreal, ttext, tsemaphore, treference, 
                      texception, tudf, tddf]);
         if tp1^.t <> tudf then begin { type valid }

            lsttyp(tp, tptr); { get pointer type entry }
            tp^.ptrt := tp1 { place type linkage }

         end else tp := gbludf { set result undefined }

      end

   end else begin { composite type }

      { check possible misspelled tolken }
      chktkmp(nxtlab, [cpacked, carray, cfile, cset, crecord, creference]);
      pack := false; { set not packed }
      { check 'packed' option }
      if nxttlk = cpacked then begin 

         pack := true; { set packed }
         gettlk; { skip 'packed' }
         if not (nxttlk in [carray, cfile, cset, crecord]) then
            { no packed applicable object }
            perror(einvpob, [carray, cfile, cset, crecord, clbrkt]+ordset+ss, 
                   [carray, cfile, cset, crecord]);

      end;
      if (nxttlk = carray) or (nxttlk = clbrkt) then begin { array }

         expect(carray, earrexp, [], []); { 'array' expected }
         if (nxttlk = cof) and not fansi then begin 

            { no indecies, its a general array }
            gettlk; { skip 'of' }
            lsttyp(tp, tgarry); { get general array type }
            tp^.pack := pack; { place packed status }
            partype(ss, tp1); { parse type }
            tp^.gart := tp1; { place type linkage }
            { if base type undefined, then so is the whole type }
            if tp1^.t = tudf then tp := gbludf

         end else if (nxttlk in constset) and not fansi then begin

            { constant instead of index spec, its a lengthed array }
            tp := nil; { set no type entry }
            lp := nil; { set no last type entry }
            repeat { parse lengths }

               parconst([ccma, cof]+ss, tp1); { parse length constant }
               { verify is the proper type }
               if not intt(tp1) and not (tp1^.t = tudf) then begin

                  { not integer, flag error and set undefined }
                  perror(earrlen, [], []);
                  tp1 := gbludf

               end;
               { see if we have a valid array length to make an index from }
               if intt(tp1) then begin { create index type }

                  lsttyp(tp2, tsub); { get a subrange entry }
                  tp2^.subt := gblint; { set base integer }
                  tp2^.subl.v := 1; { set default base value }
                  tp2^.subl.s := false; { set default base sign }
                  tp2^.subu.v := consti(tp1); { set upper limit value }
                  tp2^.subu.s := constis(tp1); { set upper limit sign }
                  tp1 := tp2 { place back in original entry }

               end;
               { if index is undefined, then so is the whole type }
               if tp1^.t = tudf then tp := gbludf;
               lsttyp(tp2, tarray); { get array type entry }
               if tp = nil then tp := tp2; { place head entry }
               tp2^.arri := tp1; { place index linkage }
               tp2^.pack := pack; { place packed status }
               if lp <> nil then lp^.arrt := tp2; { link last entry to this }
               lp := tp2; { place as last }
               if (nxttlk <> ccma) and (nxttlk <> cof) then
                  { we don't have an exit tolken }
                  perror(erbcmexp, [ccma, cof]+ordset+ss, []);
               last := nxttlk; { save tolken }
               if last = ccma then gettlk { skip ',' }

            { until not ',' or likely ordinal type }
            until not (last in [ccma]+constset);
            expect(cof, eofexp, [cof]+typeset+ss, [cof]); { expect 'of' }
            partype(ss, tp1); { parse type }
            { check attempt to allocate general array }
            if tp1^.t = tgarry then perror(ealcgar, [], []); 
            tp2^.arrt := tp1; { place type linkage }
            { if base type undefined, then so is the whole type }
            if tp1^.t = tudf then tp := gbludf

         end else begin { indexed array }

            tp := nil; { set no type entry }
            { expect '[' }
            expect(clbrkt, elbkexp, [clbrkt, ccma, cidentifier]+ordset+ss, []);
            lp := nil; { set no last type entry }
            repeat { parse indecies }

               parord([ccma, crbrkt, cof]+ss, tp1); { parse ordinal type }
               { verify is the proper type }
               typcon(tp1, [tenum, tsub, tinteger, tlinteger, tcardinal,
                            tlcardinal, tchar, tboolean, tudf]);
               { if index is undefined, then so is the whole type }
               if tp1^.t = tudf then tp := gbludf;
               lsttyp(tp2, tarray); { get array type entry }
               if tp = nil then tp := tp2; { place head entry }
               tp2^.arri := tp1; { place index linkage }
               tp2^.pack := pack; { place packed status }
               if lp <> nil then lp^.arrt := tp2; { link last entry to this }
               lp := tp2; { place as last }
               if (nxttlk <> ccma) and (nxttlk <> crbrkt) then
                  { we don't have an exit tolken }
                  perror(erbcmexp, [ccma, crbrkt, cof]+ordset+ss, []);
               last := nxttlk; { save tolken }
               if last = ccma then gettlk { skip ',' }

            { until not ',' or likely ordinal type }
            until not (last in [ccma, clparen, cidentifier]+constset);
            if nxttlk = crbrkt then gettlk; { skip ']' }
            expect(cof, eofexp, [cof]+typeset+ss, [cof]); { expect 'of' }
            partype(ss, tp1); { parse type }
            { check attempt to allocate general array }
            if tp1^.t = tgarry then perror(ealcgar, [], []); 
            tp2^.arrt := tp1; { place type linkage }
            { if base type undefined, then so is the whole type }
            if tp1^.t = tudf then tp := gbludf

         end

      end else if nxttlk = cfile then begin { file }

         gettlk; { next }
         expect(cof, eofexp, [cof]+typeset+ss, [cof]); { expect 'of' }
         partype(ss, tp1); { parse type }
         { if file or contains file, set undefined }
         if filect(tp1) then begin { has a file component }

            perror(efilcom, [], []); { file component }
            tp1 := gbludf { set undefined }

         end;
         { check attempt to allocate general array }
         if tp1^.t = tgarry then perror(ealcgar, [], []); 
         if tp1^.t <> tudf then begin { not undefined }

            lsttyp(tp, tfile); { get file type entry }
            tp^.filt := tp1; { place type linkage }
            tp^.pack := pack { place packed status }

         end else tp := gbludf { set result undefined }

      end else if nxttlk = cset then begin { set }

         gettlk; { next }
         expect(cof, eofexp, [cof]+typeset+ss, [cof]); { expect 'of' }
         parord(ss, tp1); { parse ordinal type }
         { check proper type }
         typcon(tp1, [tenum, tsub, tinteger, tlinteger, tcardinal, tlcardinal,
                      tchar, tboolean, tudf]);
         if tp1^.t <> tudf then begin

            lsttyp(tp, tset); { get set type entry }
            tp^.sett := tp1; { place type linkage }
            tp^.setc := false; { disallow set contexting }
            tp^.pack := pack { place packed status }

         end else tp := gbludf { set result undefined }

      end else if nxttlk = crecord then begin { record }

         gettlk; { next }
         { here we clear the symbols list that we give the field parser. This
           is a quirk that allows the field parser to call itself to construct
           a global label list for the record. We only need to call it with 
           empty symbol and last entry pointers }
         sp := nil;
         ts := nil;
         parfield([cend]+ss, tp1, sp, ts); { parse field list }
         { set type valid for field or empty list }
         if tp1 = nil then valid := true else valid := tp1^.t <> tudf;
         if valid then begin { type is valid }

            lsttyp(tp, trecord); { get set type entry }
            tp^.recf := tp1; { place field list linkage }
            tp^.recl := sp; { place label list linkage }
            plchead(tp1, tp); { place head linkages }
            tp^.pack := pack { place packed status }

         end else tp := gbludf; { set result undefined }
         expect(cend, eendexp, ss, [cend]) { expect 'end' }

      end else if nxttlk = creference then begin { class reference }

         gettlk; { next }
         expect(cto, etoexp, [cto]+typeset+ss, [cto]); { expect 'to' }
         if nxttlk <> cidentifier then begin { missing id }

            perror(eidnexp, typeset+ss, []); { flag error }
            tp := gbludf { set result undefined }

         end else begin { process class symbol }

            { parse qualident, no reference grace, with default define }
            parqualident(typeset+ss, false, true, true, '', sp, lab);
            if sp = nil then error(esflt50, true);
            tp1 := sp^.typ; { set base type }
            { check is a class }
            if not (tp1^.t in [tclass, tatom, tthread]) then begin

               perror(eclsexp, [], []); { class expected }
               tp1 := gbludf { set result undefined }

            end;
            { construct the reference type }
            lsttyp(tp, treference); { get set type entry }
            tp^.reft := tp1 { place type linkage }

         end

      end else begin

         { here we parse an ordinal only if it has a head.
           the error would have been taken care of on entry }
         if nxttlk in [cidentifier, clparen]+constset then 
            { we may have found it }
            parord(ss, tp) { parse ordinal type }

      end

   end

end;

{*******************************************************************************

Parse procedure/function header

   procedure = 'procedure' identifer |
               'procedure' identifer paramlist |
               'function' identifier |
               'function identifier [paramlist] ':' typeid

Parses a procedure/function and it's body. Accepts a tolken skip set.

Error recovery:

1. No identifier for procedure/function, skip to '(', 'var', 'procedure',
'function', ':', ';' or id (any tolken symbolizing the parameter list parts).

2. No identifier for parameter, skip to id, ',', ':', ';', ')'.

3. No ':' or ',' following parameter id, skip to ',', ':', id, ';', ')'. Loops
as long as last tolken was a likely next parameter id.

4. No id after ':' in parameter, skip to id, ';', ')'.

5. No ')' or ';' after parameter spec, skip to ';', 'var', 'procedure',
'function', id, ',', ':', ')' (any parameter list parts or end). Loops as long
as last tolken was a likely next parameter spec.

6. No id after ':' in function result type, skip to id, ';', 'forward', or
block start tolken.
                   
*******************************************************************************}

procedure parfphead(    ovlatt: boolean; { declaration is overload }
                        staatt: boolean; { static attribute flag }
                        viratt: boolean; { virtual attribute flag }
                        ovratt: boolean; { override attribute flag }
                        ss:     tolkset; { skip set }
                    var hsp:    symptr;  { returns head symbol }
                    var tp:     typptr); { returns procedure entry }

var last:     tolken;  { parser aid }
    head:     tolken;  { type of head tolken ('procedure'/'function') }
    sp:       symptr;  { symbol pointer }
    tl:       typptr;  { parameter type list }
    ts:       typptr;  { parameter sublist }
    tp1, tp2: typptr;  { type entry pointer }
    lt:       typptr;  { last type entry }
    part:     (valp, varp, viewp); { type of parameter }
    clnp:     boolean; { ':' processed }
    lab:      labl;    { label for undefines }

begin

   if fparse then writeln(':procedure/function heading');
   head := nxttlk; { save head tolken for error check }
   hsp := nil; { set no head symbol }
   tp := nil; { set no type }
   gettlk; { skip 'procedure' or 'function' }
   { Check for forwards and overrides. This means any procedure or function that
     is previously defined. These are then loaded into the head symbol (hsp),
     and type (tp), and used further on. }
   if nxttlk <> cidentifier then { id expected }
      perror(eidnexp, [cidentifier, clparen, cvar, cview, cprocedure, 
                       cfunction, ccln, cscn]+ss, [])
   else begin { id found }
   
      hsp := lclsym(nxtlab); { see if we can find a forwarded symbol }
      if hsp <> nil then begin { found symbol }
   
         tp := hsp^.typ; { index type }
         if tp^.t = tproc then begin { procedure }
   
            if tp^.prcv and (tp^.prcz <> nil) then begin 

               { Its virtual, and the pair is present. Check the pair is a 
                 pending forward. }
               tp1 := ovrfwd(tp); { get any any pending forward }
               if tp1 <> nil then 
                  { yes, index the type as the forwarded entry }
                  tp := tp1
               else begin

                  { no, kill the symbol }
                  hsp := nil;
                  tp := nil

               end
               
            end else if not tp^.prcf or ovlatt then begin

               { Not forwarded, or is an overload. Kill the forwarding.
                 Note overload will not complete forward. }
               hsp := nil;
               tp := nil

            end else if head <> cprocedure then
               perror(efwdmat, [], []) { does not match orginal sense }
   
         end else if tp^.t = tfunc then begin { function }
   
            if tp^.fncv and (tp^.fncz <> nil) then begin 

               { Its virtual, and the pair is present. Check the pair is a 
                 pending forward. }
               tp1 := ovrfwd(tp); { get any any pending forward }
               if tp1 <> nil then 
                  { yes, index the type as the forwarded entry }
                  tp := tp1
               else begin

                  { no, kill the symbol }
                  hsp := nil;
                  tp := nil

               end
               
            end else if not hsp^.typ^.fncf or ovlatt then begin

                  { Not forwarded, or is an overload. Kill the forwarding.
                    Note overload will not complete forward. }
                  hsp := nil;
                  tp := nil

            end else if head <> cfunction then
               perror(efwdmat, [], []) { does not match orginal sense }
   
         end else begin

            hsp := nil; { flag no entry }
            tp := nil

         end
   
      end
      { Now if the last procedure/function was a forward, hsp contains the 
        symbol for it, and tp contains the type entry for the forward. If an
        override, the symbol references the virtual entry, and the type the
        override entry, which has no symbol. }

   end;
   { perform attribute matching for forwarded procedure/function }
   if tp <> nil then begin

      if tp^.t = tproc then begin { procedure }

         if tp^.prcf then begin { forwarded }

            { check static attribute matches }
            if tp^.prcg <> staatt then perror(efwdatt, [], []);
            { check virtual attrbiute matches }
            if tp^.prcv <> viratt then perror(efwdatt, [], [])

         end

      end else if tp^.t = tfunc then begin { function }

         if tp^.fncf then begin { forwarded }

            { check static attribute matches }
            if tp^.fncg <> staatt then perror(efwdatt, [], []);
            { check virtual attrbiute matches }
            if tp^.fncv <> viratt then perror(efwdatt, [], [])

         end

      end

   end;
   { Process setup on new procedure/function entries, i.e., no forwarding or
     overrides. }
   if tp = nil then begin { no forwarded entry found }

      if head = cprocedure then begin { procedure }

         lsttyp(tp, tproc); { get procedure entry }
         tp^.prcd := pfnil; { set null dispatch code }
         tp^.prcf := false; { set not forwarded }
         tp^.prcs := nil; { clear save lists }
         tp^.prct := nil;
         tp^.prcp := nil; { set no parameter list }
         tp^.prce := uselvl <> 0; { set external status }
         tp^.prcmd := modlst^.inx; { set associated module index }
         tp^.prca := false; { set not assembly }
         tp^.prco := nil; { clear overload specs }
         tp^.prch := nil;
         tp^.prcx := false;
         tp^.prcq := false;
         tp^.prcg := staatt; { set static attribute }
         tp^.prcv := viratt; { set virtual attribute }
         tp^.prcz := nil; { set no override group }
         tp^.prcu := nil;
         if viratt then tp^.prcu := tp; { link virtual to itself as head }
         tp^.prcm := curcls <> nil; { member if in a class }

      end else begin { function }

         lsttyp(tp, tfunc); { get function entry }
         tp^.fncr := nil; { set result type nil }
         tp^.fncd := pfnil; { set null dispatch code }
         tp^.fncc := 0; { clear reference counter (function assign) }
         tp^.fncf := false; { set not forwarded }
         tp^.fncs := nil; { clear save lists }
         tp^.fnct := nil;
         tp^.fncp := nil; { set no parameter list }
         tp^.fnce := uselvl <> 0; { set external status }
         tp^.prcmd := modlst^.inx; { set associated module index }
         tp^.fnca := false; { set not assembly }
         tp^.fnco := nil; { clear overload specs }
         tp^.fnch := nil;
         tp^.fncx := false;
         tp^.fncq := false;
         tp^.fncg := staatt; { set static attribute }
         tp^.fncv := viratt; { set virtual attribute }
         tp^.fncz := nil; { set no override group }
         tp^.fncu := nil;
         if viratt then tp^.fncu := tp; { link virtual to itself as head }
         tp^.fncm := curcls <> nil; { member if in a class }

      end;
      if nxttlk = cidentifier then begin { id found }

         if ovlatt then begin { process overload }

            hsp := lclsym(nxtlab); { find existing symbol }
            { process error if not found }
            if hsp = nil then perror(enfnctoo, [], [])
            else begin { place on overload list }

               { place new function or procedure on a linked list of all
                 overloads for the given symbol }
               if hsp^.typ^.t = tproc then begin { original was procedure }

                  if tp^.t = tproc then begin { new is procedure }

                     tp^.prco := hsp^.typ^.prco; { push onto overload list }
                     hsp^.typ^.prco := tp;
                     tp^.prch := hsp^.typ; { link to head }
                     hsp^.typ^.prch := hsp^.typ { link head back to itself }

                  end else begin { new is function }

                     tp^.fnco := hsp^.typ^.prco; { push onto overload list }
                     hsp^.typ^.prco := tp;
                     tp^.fnch := hsp^.typ; { link to head }
                     hsp^.typ^.prch := hsp^.typ { link head back to itself }

                  end

               end else if hsp^.typ^.t = tfunc then begin { original was function }

                  if tp^.t = tproc then begin { new is procedure }

                     tp^.prco := hsp^.typ^.fnco; { push onto overload list }
                     hsp^.typ^.fnco := tp;
                     tp^.prch := hsp^.typ; { link to head }
                     hsp^.typ^.fnch := hsp^.typ { link head back to itself }

                  end else begin { new is function }

                     tp^.fnco := hsp^.typ^.fnco; { push onto overload list }
                     hsp^.typ^.fnco := tp;
                     tp^.fnch := hsp^.typ; { link to head }
                     hsp^.typ^.fnch := hsp^.typ { link head back to itself }

                  end

               end else if (hsp^.typ^.t = tpproc) or (hsp^.typ^.t = tpfunc) then
                  { Original definition was a procedure or function parameter,
                    which cannot be overloaded. }
                  perror(eofncisp, [], []) { is a parameter }
               else 
                  { original is not a procedure or function }
                  perror(eovlnpf, [], [])

            end

         end else if ovratt then begin { its an override }

            hsp := gblsym(nxtlab); { find existing symbol }
            { process error if not found }
            if hsp = nil then perror(envirtoo, [], [])
            else begin { found original }

               { check procedure/function type matches }
               if not (hsp^.typ^.t in [tproc, tfunc]) then 
                  perror(eovrnpf, [], [])
               else if hsp^.typ^.t <> tp^.t then 
                  perror(evirmat, [], []);
               { check procedure/function specific flags }
               if hsp^.typ^.t = tproc then begin { procedure }

                  { check has virtual attribute }
                  if not hsp^.typ^.prcv then perror(envirpf, [], []);
                  { check is class or module virtual }
                  if hsp^.typ^.classt = nil then begin { module }

                     { Check is external. Module overrides must be external. }
                     if not hsp^.typ^.prce then perror(evirmbe, [], []);
                     { Check already has an override. Modules only allow one
                       override per module. }
                     if ovrcnt(hsp^.typ) > 0 then perror(eovrdup, [], []);
                     { check declared in global module }
                     if blkstk^.mark^.t <> tglbl then perror(eovrmod, [], [])

                  end else begin { class }

                     { check in the same class as the virtual method }
                     if hsp^.typ^.classt = tp^.classt then perror(eovrscls, [], []);
                     { check already an override for this class }
                     if ovrcntcls(hsp^.typ, curcls) > 0 then 
                        perror(eovrcdup, [], [])

                  end;
                  { push new entry to override list }
                  tp^.prcz := hsp^.typ^.prcz;
                  hsp^.typ^.prcz := tp;
                  { link new entry to head }
                  tp^.prcu := hsp^.typ
                  
               end else if hsp^.typ^.t = tfunc then begin { function }

                  { check has virtual attribute }
                  if not hsp^.typ^.fncv then perror(envirpf, [], []);
                  { check is class or module virtual }
                  if hsp^.typ^.classt = nil then begin

                     { Check is external. Module overrides must be external. }
                     if not hsp^.typ^.fnce then perror(evirmbe, [], []);
                     { Check already has an override. Modules only allow one
                       override per module. }
                     if ovrcnt(hsp^.typ) > 0 then perror(eovrdup, [], []);
                     { check declared in global module }
                     if blkstk^.mark^.t <> tglbl then perror(eovrmod, [], [])

                  end else begin { class }

                     if hsp^.typ^.classt = tp^.classt then perror(eovrscls, [], []);
                     { check already an override for this class }
                     if ovrcntcls(hsp^.typ, curcls) > 0 then 
                        perror(eovrcdup, [], [])

                  end;
                  { push new entry to override list }
                  tp^.fncz := hsp^.typ^.fncz;
                  hsp^.typ^.fncz := tp;
                  { link new entry to head }
                  tp^.fncu := hsp^.typ

               end

            end
         
         end else begin { normal new definition }

            define(nxtlab, hsp); { define symbol }
            hsp^.typ := tp { link procedure/function to symbol }

         end
   
      end

   end;
   { Perform header parse and process }
   if nxttlk = cidentifier then gettlk; { skip id }
   if uselvl = 0 then { not in uses file }
      wrtsyms; { output symbols section incremental }
   level := level+1; { add new scoping level }
   sequen := sequen+1; { count scope sequence }
   curseq := sequen; { set current sequence }
   export := false; { set no procedure/function contents exportable }
   if not (nxttlk in [clparen, cscn, ccln, crparen]) then { no follow tolken }
      perror(elpsccnrpexp, [clparen, cscn, cidentifier, ccln, cvar, cview, 
                            cprocedure, cfunction]+ss, []);
   if (nxttlk in [clparen, cidentifier, cvar, cview, cprocedure, 
                  cfunction]) then begin 

      tl := nil; { clear parameter list }
      lt := nil;
      { parameter list }
      { check forwarded entry, in which case there should be no parameter
        list (ansi mode only) }
      if (tp^.t = tproc) and fansi then { procedure, and ansi mode }
         if tp^.prcf then perror(eparrep, [], []);
      if (tp^.t = tfunc) and fansi then { function, and ansi mode }
         if tp^.fncf then perror(eparrep, [], []);
      if nxttlk = clparen then gettlk; { skip '(' }
      repeat

         if (nxttlk = cprocedure) or
            (nxttlk = cfunction) then begin { procedure/function parameter }

            { parse header parameter }
            parfphead(false, false, false, false, ss, sp, tp1);
            { because a true procedure start is done, we must purge all the
              symbols associated with the 'procedure' and dump the symbol
              level }
            listsym(sp); { output symbols listing and purge }
            level := level-1; { remove scoping level }
            { we must reconstruct the header as a parameter.
              The old top entry is thrown away }
            if tp1^.t = tproc then begin { procedure }

               gettyp(tp2, tpproc); { get procedure parameter entry }
               tp2^.pprp := tp1^.prcp; { copy parameter list }
               tp2^.pprn := nil { terminate }

            end else begin { function }

               gettyp(tp2, tpfunc); { get procedure parameter entry }
               tp2^.pfnp := tp1^.fncp; { copy parameter list }
               tp2^.pfnr := tp1^.fncr; { copy result type }
               tp2^.pfnn := nil { terminate }

            end;
            chgtyp(tp1, tp2); { change type reference to new }
            reptyp(tp1, tp2); { replace type entry }
            { if parameter list is empty, place 1st entry }
            if tl = nil then tl := tp2;
            if lt <> nil then { place last entry linkage }
               if lt^.t = tpar then lt^.parn := tp2
               else if lt^.t = tvpar then lt^.vprn := tp2
               else if lt^.t = twpar then lt^.wprn := tp2
               else if lt^.t = tpproc then lt^.pprn := tp2
               else lt^.pfnn := tp2;
            lt := tp2 { place new last entry }

         end else begin

            part := valp; { set value parameter }
            if nxttlk = cvar then part := varp { set VAR parameter }
            else if nxttlk = cview then part := viewp; { set VIEW parameter }
            if part <> valp then gettlk; { skip modifier if present }
            ts := nil; { clear type sublist }
            repeat { parameters }

               if nxttlk <> cidentifier then { no id }
                  perror(eidnexp, [cidentifier, ccma, ccln, cscn, crparen]+ss,
                         []);
               if nxttlk = cidentifier then begin { id found }

                  define(nxtlab, sp); { define symbol }
                  { define parameter entry in appropriate mode }
                  if part = varp then begin { variable mode }

                     lsttyp(tp1, tvpar); { get variable parameter entry }
                     tp1^.vprh := tp; { set head } 
                     tp1^.vprn := nil; { terminate }
                     tp1^.vprr := 0 { clear threat count }

                  end else if part = viewp then begin { view mode }

                     lsttyp(tp1, twpar); { get variable parameter entry }
                     tp1^.wprh := tp; { set head } 
                     tp1^.wprn := nil { terminate }

                  end else begin { value mode }

                     lsttyp(tp1, tpar); { get value parameter entry }
                     tp1^.parh := tp; { set head }
                     tp1^.parn := nil; { terminate }
                     tp1^.parr := 0 { clear threat count }

                  end;
                  sp^.typ := tp1; { link to symbol }
                  { if parameter list is empty, place 1st entry }
                  if tl = nil then tl := tp1;
                  { if parameter sublist is empty, place 1st entry }
                  if ts = nil then ts := tp1;
                  if lt <> nil then { place last entry linkage }
                     if lt^.t = tpar then lt^.parn := tp1
                     else if lt^.t = tvpar then lt^.vprn := tp1
                     else if lt^.t = twpar then lt^.wprn := tp1
                     else if lt^.t = tpproc then lt^.pprn := tp1
                     else lt^.pfnn := tp1;
                  lt := tp1; { place new last entry }
                  gettlk; { skip id }
   
               end;
               if (nxttlk <> ccma) and (nxttlk <> ccln) then
                  { we don't have an exit tolken }
                  perror(ecncmexp, [ccma, ccln, cidentifier, cscn, 
                         crparen]+ss, []);
               last := nxttlk; { save next }
               if nxttlk = ccma then gettlk { next }

            { until not ',' or id }
            until not (last in [ccma, cidentifier]);
            if nxttlk = ccln then gettlk; { skip ':' }
            if nxttlk <> cidentifier then { no type id }
               perror(eidnexp, [cidentifier, cscn, crparen]+ss, []);
            if nxttlk = cidentifier then begin { id found }

               { parse qualified identifier }
               parqualident(ss, true, true, true, '', sp, lab);
               tp1 := actt(sp^.typ); { get type }
               { check parameter is a proper type }
               typcon(tp1, [tenum, tsub, tptr, tarray, tgarry, tfile, tset, 
                            trecord, tinteger, tlinteger, tcardinal, tlcardinal,
                            tchar, tboolean, treal, tsreal, ttext, tudf, tddf]);
               { check file component as anything but VAR parameter }
               if filect(tp1) and not (part = varp) then
                  { We are going to leave the type alone for this. We have 
                    already output an error, and the rest may parse fine. }
                  perror(efmbvar, [], [], sp^.lab^); { file parameter must be
                                                       VAR }
               { check monitor entry procedure with pointer or pointer
                 containing parameter }
               if (modhead = cmonitor) and (hsp <> nil) then
                  { in a monitor module, and head symbol exists }
                  if hsp^.exp then ptrcmp(tp1); { in exportable routine }
               while ts <> nil do begin { place type to all list entries }

                  if ts^.t = tpar then begin { parameter }

                     ts^.part := tp1; { place type }
                     ts := ts^.parn { next entry }

                  end else if ts^.t = tvpar then begin { variable parameter }

                     ts^.vprt := tp1; { place type }
                     ts := ts^.vprn { next entry }
                  
                  end else begin { view parameter }
 
                     ts^.wprt := tp1; { place type }
                     ts := ts^.wprn { next entry }

                  end

               end
           
            end else begin { no type id }

               while ts <> nil do begin { place undefined to all list entries }

                  if ts^.t = tpar then begin { parameter }

                     ts^.part := gbludf; { place type }
                     ts := ts^.parn { next entry }

                  end else if ts^.t = tvpar then begin { variable parameter }
 
                     ts^.vprt := gbludf; { place type }
                     ts := ts^.vprn { next entry }

                  end else begin { view parameter }
 
                     ts^.wprt := gbludf; { place type }
                     ts := ts^.wprn { next entry }

                  end

               end;

            end

         end;
         if (nxttlk <> cscn) and (nxttlk <> crparen) then
            { we don't have an exit tolken }
            perror(erpscexp, [cscn, cvar, cprocedure, cfunction, cidentifier, 
                   ccma, ccln, crparen]+ss, []);
         last := nxttlk; { save next }
         if last = cscn then gettlk { skip ';' }

      until not (last in [cscn, cvar, cprocedure, cfunction, cidentifier, 
                          ccma, ccln]);
      if nxttlk = crparen then gettlk; { skip ')' }
      if ovratt and (hsp <> nil) then begin { override }

         { its an override, and the overridden procedure function is available,
           compare the two parameter lists }
         if (hsp^.typ^.t = tproc) and (tp^.t = tproc) then 
            chkcon(hsp^.typ^.prcp, tl);
         if (hsp^.typ^.t = tfunc) and (tp^.t = tfunc) then 
            chkcon(hsp^.typ^.fncp, tl)

      end else begin { normal/forwarded }

         { now we have the parameter list. if the procedure function is forward,
           we also will have a parameter list from the first declaration. if so,
           we can compare them }
         if tp^.t = tproc then if tp^.prcf then chkcon(tp^.prcp, tl);
         if tp^.t = tfunc then if tp^.fncf then chkcon(tp^.fncp, tl)

      end;
      { place parameter list. The parameter list may overwrite the original
        parameter list if this is an (invalid) duplicate or a repeated forward.
        We take the last occurance as gospel }
      if tp^.t = tproc then tp^.prcp := tl else tp^.fncp := tl

   end;
   { check result type specification exists, or is a function }
   if (nxttlk = ccln) or (tp^.t = tfunc) then begin

      clnp := false; { set no ':' processed }
      if nxttlk <> ccln then begin { should have a ':' }

         if tp^.t = tfunc then begin { function }

            if not tp^.fncf then { not forwarded }
               perror(eclnexp, [cidentifier, cscn, cforward]+blockset+ss, [])

         end else perror(eclnexp, [cidentifier, cscn, cforward]+blockset+ss, [])

      end else begin

         gettlk; { next }
         clnp := true; { set ':' processed }
         { check forwarded entry, in which case there should be no result.
           we don't bother checking the procedure case, since that already
           has an error (ansi mode only) }
         if (tp^.t = tfunc) and fansi then { function, and ansi mode }
            if tp^.fncf then perror(eresrep, [], [])

      end;
      if (nxttlk <> cidentifier) and clnp then { no id }
         perror(eidnexp, [cidentifier, cscn, cforward]+blockset+ss, []);
      if nxttlk = cidentifier then begin 

         { parse qualified identifier }
         parqualident(ss, true, true, true, '', sp, lab);
         if tp^.t = tfunc then begin { building a function }

            tp1 := sp^.typ; { get result type }
            { check proper type for function result }
            typcon(tp1, [tenum, tsub, tptr, tinteger, tlinteger, tcardinal,
                         tlcardinal, tchar, tboolean, treal, tsreal, tsemaphore,
                         treference, texception, tudf]);
            if ovratt and (hsp <> nil) then begin { override }

               if (hsp^.typ^.fncr <> sp^.typ) and 
                  (hsp^.typ^.fncr^.t <> tudf) and
                  (sp^.typ^.t <> tudf) then { not equal, and none undefined }
                  perror(efnncon, [], []) { function results not congruous }

            end else 
               { if the function is forwarded, then we check this result is
                 EXACTLY the same as the last one }
               if tp^.fncf then begin { it's forwarded }

               if (tp^.fncr <> sp^.typ) and (tp^.fncr^.t <> tudf) and
                  (sp^.typ^.t <> tudf) then { not equal, and none undefined }
                  perror(efnncon, [], []) { function results not congruous }

            end;
            { if there is no result type, set it }
            if tp^.fncr = nil then tp^.fncr := sp^.typ { place result type }

         end

      end;
      if head <> cfunction then
         perror(eprctyp, [], []) { procedure has result }

   end

end;

{*******************************************************************************

Parse procedure/function specification

   procedure = 'procedure' identifer |
               'procedure' identifer paramlist |
               'function' identifier |
               'function identifier [paramlist] ':' typeid

Parses a procedure/function and it's body. Accepts a tolken
skip set.
Error recovery:

1. No ';' after declaration, skip to ';', 'forward', or
block start tolken.

2. Unrecognized directive, skip to ';' or block start tolken.

3. No final ';', skip to ';'.

*******************************************************************************}

procedure parfproc(ovlatt: boolean; { overload attribute flag }
                   staatt: boolean; { static attribute flag }
                   viratt: boolean; { virtual attribute flag }
                   ovratt: boolean; { override attribute flag }
                   ss:     tolkset);

var sp:      symptr;  { pointer to symbol }
    tp:      typptr;  { procedure entry pointer }
    cps:     typptr;  { current procedure/function save }
    fwd:     boolean; { 'forward' flag }
    expsav:  boolean; { export status save flag }
    cp:      typptr;  { possible congruous overload }
    curseqs: integer; { current sequence save }

{ delete overload }

procedure delovl(tp: typptr);

var p, lp: typptr; { list pointers }

begin

   { index head of overload list }
   if tp^.t = tproc then p := tp^.prch else p := tp^.fnch;
   { find last pointer to entry }
   lp := nil; { clear last }
   while p <> tp do begin { traverse }

      if p = nil then error(esflt32, true); { not found }
      lp := p; { set new last }
      if p^.t = tproc then p := p^.prco else p := p^.fnco
         
   end;
   { this would indicate we are deleting the prime, not valid }
   if lp = nil then error(esflt33, true);
   { gap out of list }
   if p^.t = tproc then p := p^.prco else p := p^.fnco; { get next }
   if lp^.t = tproc then lp^.prco := p else lp^.fnco := p;
   { flag deleted forward entry }
   if tp^.t = tproc then tp^.prcq := true else tp^.fncq := true

end;

begin

   if fparse then writeln(':procedure/function specification'); 
   expsav := export; { save status of export zone }
   curseqs := curseq; { save sequence }
   { parse procedure/function head }
   parfphead(ovlatt, staatt, viratt, ovratt, [cscn, cforward]+blockset+ss, sp,
             tp);
   if ovlatt then begin { its an overload }

      { We need to check uniqueness of the overload. First, we check if there
        is a congruent forwarded overload. If there is, then we skip the
        uniqueness test, since it will match its own definition. }
      fndovlcon(tp, cp); { check congruous overload }
      if (cp <> nil) and (cp <> sp^.typ) then begin { found a non-prime entry }

         if cp^.t = tproc then begin { procedure }

            if not cp^.prcf then valovl(tp) { validate overload uniqueness }
            else begin { forwarded overload }

               { The forwarded overload was placed into the overload list. We
                 must remove it, then use the original forward. The new 
                 parameters replace the old parameters. }
               cp^.prcp := tp^.prcp; { replace old parameters with new }
               delovl(tp); { remove from overload list }
               tp := cp { use forwarded entry now }

            end

         end else begin { function }

            if not cp^.fncf then valovl(tp) { validate overload uniqueness }
            else begin { forwarded overload }

               { The forwarded overload was placed into the overload list. We
                 must remove it, then use the original forward. The new 
                 parameters replace the old parameters. }
               cp^.fncp := tp^.fncp; { replace old parameters with new }
               delovl(tp); { remove from overload list }
               tp := cp { use forwarded entry now }

            end

         end

      end else valovl(tp); { validate overload uniqueness }

   end;
   expect(cscn, escnexp, [cscn, cforward]+blockset+ss, []); { expect ';' }
   fwd := false; { set no 'forward' found }
   if nxttlk = cidentifier then begin { check for 'forward' }

      if compp(nxtlab, 'forward') then 
         fwd := true { set 'forward' found }
      else { this directive not recognized }
         perror(ebgnexp, [cscn, cforward, cexternal]+blockset+ss, []);

   end;
   if nxttlk = cforward then fwd := true; { set 'forward' found }
   if fwd then begin { process 'forward' }

      { 'forward' is a keyword only in our extended language }
      gettlk; { 'forward' }
      if uselvl = 0 then { not in uses file }
         wrttyp; { output types section incremental }
      cps := curprc; { save the current block head }
      curprc := tp; { place new block head }
      pshblk(sp, tp); { start new block level }
      if tp^.t = tproc then begin { procedure }

         if tp^.prcf then perror(eardfwd, [], []); { already forwarded }
         tp^.prcf := true; { flag forwarded }
         formlist(tp^.prcs); { form symbols list and remove from table }
         tp^.prct := blkstk^.typ { save types of parameters }

      end else begin { function }

         if tp^.fncf then perror(eardfwd, [], []) { already forwarded }
         else if tp^.fncr = nil then begin

            { no function result }
            perror(enfncr, [], []); { function result not defined }
            tp^.fncr := gbludf { set result type undefined }

         end;
         tp^.fncf := true; { flag forwarded }
         formlist(tp^.fncs); { form symbols list and remove from table }
         tp^.fnct := blkstk^.typ { save types of parameters }

      end

   end else if nxttlk = cexternal then begin { process 'external' }

      gettlk; { skip 'external' }
      { Flag type entry as external assembly. 'external' used to be the main way
        to interface external routines. Now, it serves only as a way to access
        plain, uncoined names in external modules. The capability is 'locked 
        off' here, but can be reactivated if there is a need. }
      perror(eextinv, [], []); { flag error for external }
      if tp^.t = tproc then begin

         tp^.prce := true; { flag external }
         tp^.prcmd := 0; { set no module ordinal }
         tp^.prca := true { flag assembly language }

      end else begin 

         tp^.fnce := true; { flag external }
         tp^.fncmd := 0; { set no module ordinal }
         tp^.fnca := true { flag assembly language }

      end;
      { externals are forced to be exportable no matter which section they
        appear in }
      sp^.exp := true;
      if uselvl = 0 then { not in uses file }
         wrttyp; { output types section incremental }
      cps := curprc; { save the current block head }
      curprc := tp; { place new block head }
      pshblk(sp, tp); { start new typing level }
      if tp^.t = tfunc then if tp^.fncr = nil then begin

         { no function result }
         perror(enfncr, [], []); { function result not defined }
         tp^.fncr := gbludf { set result type undefined }

      end;
      listtyp; { output types listing }
      listsym(sp); { output symbols listing and purge }
      purget { remove all type list entries }

   end else begin { procedure has a body }

      if uselvl = 0 then { not in uses file }
         wrttyp; { output types section incremental }
      cps := curprc; { save the current block head }
      curprc := tp; { place new block head }
      pshblk(sp, tp); { start new typing level }
      if tp^.t = tfunc then if (tp^.fncr = nil) and not tp^.fncf then begin

         { no function result }
         perror(enfncr, [], []); { function result not defined }
         tp^.fncr := gbludf { set result type undefined }

      end;
      if tp^.t = tproc then begin { procedure }

         if tp^.prcf then begin { procedure was forwarded }

            { remove any header defined symbols and types (which would be
              present if the header was redundantly defined) }
            purge; { purge symbols }
            purget; { purge types }
            { if completing a forwarded procedure, replace the parameter
              symbols and types defined earlier }
            plcsyms(tp^.prcs); { replace symbols }
            addtyp(tp^.prct) { replace types }

         end;
         tp^.prcs := nil; { clear save lists }
         tp^.prct := nil;
         tp^.prcf := false { flag not forwarded }

      end else begin { function }

         if tp^.fncf then begin { function was forwarded }

            { remove any header defined symbols and types (which would be
              present if the header was redundantly defined) }
            purge; { purge symbols }
            purget; { purge types }
            { if completing a forwarded function, replace the parameter
              symbols and types defined earlier }
            plcsyms(tp^.fncs); { replace symbols }
            addtyp(tp^.fnct) { replace types }

         end;
         tp^.fncs := nil; { clear save lists }
         tp^.fnct := nil;
         tp^.fncf := false { flag not forwarded }

      end;
      if uselvl = 0 then begin { not in uses file, ok to generate code }

         wrtcod(ibgnlvl); { output start new level marker }
         wrtlnk(tp); { output address of mark }

      end;
      pardec([cbegin]+ss, false); { parse declarations }
      stalvl := 0; { set statement level 0 }
      stalab := nil; { clear label list }
      stagto := nil; { clear goto list }
      if uselvl = 0 then begin { not in uses file }

         wrttyp; { output types section }
         wrtsyms; { output symbols section }
         wrtcod(ibgnpgm) { output procedure/function section marker }

      end;
      parstatb(ss); { parse statement block }
      if uselvl = 0 then begin { not in uses file }

         wrtcod(iendpgm); { output procedure/function section end marker }
         wrtcod(iendlvl); { output end of level marker }
         chkref; { check symbol references }
         chktyp { check type definitions }

      end;
      listtyp; { output types listing }
      listsym(sp); { output symbols listing and purge }
      purget; { remove all type list entries }

   end;
   poptyp; { restore surrounding block typelist }
   level := level-1; { remove scoping level }
   curprc := cps; { restore old block head }
   curseq := curseqs; { restore sequence }
   export := expsav; { restore status of export zone }
   expect(cscn, escnexp, [cscn]+ss, []) { expect ';' }

end;

{*******************************************************************************

Parse declarations

   declarations = 'label' label [',' label].. ';' |
                  'const' identifier '=' const ';' 
                  [identifier '=' const ';' ].. |
                  'type' identifier '=' type ';'
                  [identifier '=' type].. ';' |
                  'var' identifier [',' identifier] ':' type ';'
                  [identifier [',' identifier] ':' type ';'].. |
                  'procedure' procedure |
                  'function' function
   label        = integer | identifier

Parses declarations. Accepts a skip tolken set.
Error recovery:

1. No id or integer after 'label', skip to id, integer, ',',
';' or declaration start.

2. No ',' or ';' after label declare, skip to id, integer, 
',', ';' or declaration start.

3. No id after 'const', skip to id, '=', ';', likely constant
or declaration start.

4. No '=' in constant, skip to '=', ';', likely constant
or declaration start.

5. No ';' after constant, skip to id, '=', ';', likely
constant or declaration start. Loop on any likely start
with the idea that lack of a declaration start would
indicate next constant.

6. No id after 'type', skip to id, '=', ';', likely type
start or declaration start.

7. No '=' in type, skip to '=', ';', likely type start or
declaration start.

8. No ';' after type, skip to id, '=', ';', likely type
start or declaration start. Loop on any likely start.

9. No id after 'var', skip to id, ':' ';', likely type start
or declaration start.

10. No ',' or ':' after id in var, skip id, ':', ';', likely
type start or declaration start. Loop on ',' or id, assuming
that id is likely to be another synonym.

11. No ';' after type, skip to id, ':', ccma, cscn, likely
type start or declaration start. Loop for id, ',', ':' or
likely type start.

*******************************************************************************}

procedure pardec(ss: tolkset; inuses: boolean);

var last:    tolken; { tolken save }
    save:    tolken; { tolken save }
    sp:      symptr; { symbol entry pointer }
    tp, tp1: typptr; { type entry pointers }
    tl:      typptr; { type list }
    conset:  set of tolken; { continuation set }
    corset:  set of tolken; { correction set (follow tolkens) }
    ovlatt:  boolean; { overload is active }
    staatt:  boolean; { static attribute is set }
    viratt:  boolean; { virtual attribute is set }
    ovratt:  boolean; { override attribute is set }

begin

   if fparse then writeln(':declarations');
   last := cundefined; { set no last tolken }
   if fansi then begin

      if not (nxttlk in blockset) then { no follow tolken }
         perror(einvblk, blockset+ss, [clabel, cconst, ctype, cvar, cprocedure, 
                cfunction]);
      conset := decset { set continuation }

   end else begin

      if not (nxttlk in blockset+[cfixed, coverload, cstatic, cvirtual, 
                                  coverride, cclass, catom, cthread, 
                                  cperiod]) then
         { no follow tolken }
         perror(einvblk, blockset+ss, [clabel, cconst, ctype, cvar, cprocedure, 
                                       cfunction, cfixed, coverload, cstatic, 
                                       cvirtual, coverride, cclass, catom, 
                                       cthread]);
      { set continuation }
      conset := decset+[cfixed, coverload, cstatic, cvirtual, coverride, cclass,
                        catom, cthread]

   end;
   { set correction set continuation set plus block start and private }
   corset := conset+blockset;
   while nxttlk in conset do case nxttlk of { tolken }

      clabel: begin { label list }

         { check and flag out of order }
         if fansi and (last <> cundefined) then perror(edecor, [], [], nxtlab);
         last := nxttlk; { save that tolken }
         repeat { parse label list }

            if (nxttlk = clabel) or (nxttlk = ccma) then
               gettlk; { skip 'label' or ',' }
            if (nxttlk <> cidentifier) and (nxttlk <> cinteger) then begin

               { process error according to standard type }
               if fansi then perror(eintexp, [cidentifier, cinteger, ccma, 
                                    cscn]+decset+ss, []) { no integer }
               else perror(eilexp, [cidentifier, cinteger, ccma, 
                           cscn]+decset+ss, []) { no integer/label }
            
            end else if (nxttlk <> cinteger) and fansi then { not standard }
               perror(eintexp, [], []); { no integer }
            { skip goto label }
            if (nxttlk = cidentifier) or (nxttlk = cinteger) then begin 

               { id found }
               if nxttlk = cinteger then begin { it's an integer label }

                  numlab(nxtint, nxtlab); { convert and normalize label number }
                  if nxtint > 9999 then { greater than ansi max ? }
                     perror(einvgln, [], [], nxtlab) { invalid label number }

               end;
               { 'uses' declared labels are parsed, but otherwise ignored, as
                 no labels are exported, and are allways private }
               if not inuses then begin { if not in 'uses' section }

                  define(nxtlab, sp); { define symbol }
                  sp^.exp := false; { labels are never exportable }
                  lsttyp(tp, tlab); { get a goto label type }
                  sp^.typ := tp; { place link to symbol }
                  tp^.ldef := false; { set label not defined }
                  tp^.lref := 0; { clear 'goto' reference count }
                  tp^.slvl := 0; { clear statement nesting level }
                  tp^.mlvl := maxint; { set no minimum reference level }
                  tp^.extr := false; { set no block external references exist }
                  tp^.lnxt := nil { clear next in block list }

               end;
               gettlk; { skip id }
            
            end;
            if (nxttlk = cinteger) or (nxttlk = cidentifier) then gettlk;
            if (nxttlk <> ccma) and (nxttlk <> cscn) then
               { we have no exit tolken }
               perror(esccmexp, [cidentifier, cinteger, ccma, cscn]+
                                corset+[cperiod]+ss, corset)

         { until not ',' or likely label }   
         until not (nxttlk in [ccma, cidentifier, cinteger]);
         if nxttlk = cscn then gettlk { skip ';' }
     
      end;
   
      cconst: begin { constants }
   
         { check and flag out of order }
         if fansi and (last <> clabel) and (last <> cundefined) then 
            perror(edecor, [], [], nxtlab);
         last := nxttlk; { save that tolken }
         gettlk; { next }
         repeat
   
            if nxttlk <> cidentifier then { no id }
               perror(eidnexp, [cidentifier, cequ, cscn]+constset+decset+ss, 
                      []);
            sp := nil; { set no symbol exists }
            if nxttlk = cidentifier then begin { id found }

               define(nxtlab, sp); { define symbol }
               sp^.hld := true; { set in "holding" in case of sub-access }
               sp^.typ := gbludf; { and set undefined for same }
               gettlk; { skip id }
            
            end;
            { expect '=' }
            expect(cequ, eequexp, [cequ, cscn]+constset+decset+ss, []);
            parconst([cscn]+decset+ss, tp); { parse constant }
            { check proper type }
            typcon(tp, [ticst, tscst, tccst, trcst, tstcst, tenme, tudf]);
            if sp <> nil then begin { symbol exists }

               sp^.typ := tp; { if symbol exists, plant type }
               sp^.hld := false { remove holding }

            end;
            { expect ';' }
            expect(cscn, escnexp, [cidentifier, cequ, cscn]+
                                  conset+[cbegin, cprivate, cperiod]+ss, []);
            if not (nxttlk in [cidentifier]+conset+
                              [cbegin, cprivate, cperiod]) then 
               { no follow tolken }
               perror(einvblk, [cidentifier, cequ]+corset+
                               [cprivate, cperiod]+ss, corset)

         { until not likely constant }   
         until not (nxttlk in [cidentifier, cequ])
   
      end;

      ctype: begin { types }

         { check and flag out of order }
         if fansi and not (last in [cconst, clabel, cundefined]) then 
            perror(edecor, [], [], nxtlab);
         last := nxttlk; { save that tolken }
         gettlk; { next }
         repeat
   
            if nxttlk <> cidentifier then { no id }
               perror(eidnexp, [cidentifier, cequ, cscn]+typeset+decset+ss, []);
            sp := nil; { set no symbol exists }
            if nxttlk = cidentifier then begin { id found }

               { we must process the define specially, as it may allready exist
                 as a delayed definition }
               sp := lclsym(nxtlab); { find previous symbol }
               if sp <> nil then begin { already exists }

                  if sp^.typ^.t <> tddf then begin { output duplicate error }

                     perror(edupsym, [], [], nxtlab);
                     sp^.dup := true { set symbol is duplicate }
                 
                  end

               end else begin { new symbol }

                  plcsym(nxtlab, sp); { place symbol }
                  sp^.hld := true; { set symbol holding }
                  sp^.typ := gbludf { set undefined }

               end;
               gettlk; { skip id }
            
            end;
            { expect '=' }
            expect(cequ, eequexp, [cequ, cscn]+typeset+decset+ss, []);
            partype([cscn]+decset+ss, tp); { parse type }
            if sp <> nil then begin { there is a symbol }
               if not sp^.ddf and (sp^.typ^.t = tddf) then begin 

                  { Special delayed define. This is an alias to a downrefernce.
                    It should have the downreference alias set if it has not
                    already been defined for this level, otherwise its an
                    error. }
                  if not sp^.dra then begin

                     perror(edradef, [], [], sp^.lab^); { duplicate error }
                     sp^.dup := true { set symbol is duplicate }

                  end;
                  sp^.dra := false; { set no longer downreference alias }
                  sp^.typ^.ddft := tp; { place delayed type }
                  sp^.typ^.ddfd := true; { set type now defined }
                  sp^.typ^.ddfr := nil { clear downreference symbol }

               end else if not sp^.ddf then begin { not delayed define }

                  sp^.typ := tp; { place type }
                  sp^.hld := false { remove holding }

               end else begin { standard delayed define }

                  sp^.typ^.ddft := tp; { place delayed type }
                  sp^.typ^.ddfd := true; { set type now defined }
                  sp^.ddf := false { remove delayed define flag }

               end

            end;
            { expect ';' }
            expect(cscn, escnexp, [cidentifier, cequ, cscn]+typeset+conset+
                                  [cbegin, cprivate, cperiod]+ss, []);
            if not (nxttlk in [cidentifier]+conset+
                              [cbegin, cprivate, cperiod]) then
               { no follow tolken }
               perror(einvblk, [cidentifier, cequ]+corset+[cperiod]+ss, corset);
   
         { until not likely next type }
         until not (nxttlk in [cidentifier, cequ]);
         { if standard, check for unresolved delayed pointer definitions }
         if fansi then chkddf
      end;

      cvar: begin { variables }
   
         { check and flag out of order }
         if fansi and not (last in [ctype, cconst, clabel, cundefined]) then 
            perror(edecor, [], [], nxtlab);
         { check variables appear in 'share' module }
         if modhead = cshare then perror(eshrvar, [], []); { no share variables }
         { check variables appear in 'monitor' export section }
         if (modhead = cmonitor) and export then perror(emonvar, [], []);
         last := nxttlk; { save that tolken }
         gettlk; { next }
         repeat
   
            tl := nil; { set entries list nil }
            repeat

               if nxttlk <> cidentifier then { id expected }
                  perror(eidnexp, [cidentifier, ccln, cscn]+typeset+decset+ss,
                         []);
               if nxttlk = cidentifier then begin { id found }

                  { first, we attempt to find a previous default declaration
                    for a header file }
                  sp := lclsym(nxtlab);
                  if sp <> nil then begin { found an entry }

                     tp := sp^.typ; { get type pointer }
                     if tp^.t = tvar then begin { it's a variable }

                        { now, if it's an unresolved header, we will go ahead
                          and accept the entry for further processing }
                        if tp^.vars in [fshparm, fsherr] then
                           tp^.vars := fsnone
                        else sp := nil { set normal processing }

                     end else sp := nil { set normal processing }

                  end;
                  if sp = nil then begin { process the standard way }

                     define(nxtlab, sp); { define symbol }
                     lsttyp(tp, tvar); { get variable type entry }
                     sp^.typ := tp; { place symbol linkage }
                     tp^.varr := 0; { clear threat count }
                     tp^.varf := 0; { clear 'for' use count }
                     tp^.vars := fsnone; { set no special file handling }
                     tp^.vare := uselvl <> 0; { set external status }
                     tp^.varp := false; { set no subroutine threat }
                     tp^.varmd := modlst^.inx; { set associated module index }
                     { Variable member status is in a class, but not in a method
                       that class. }
                     tp^.varm := (curcls <> nil) and 
                                 not (blkstk^.mark^.t in [tproc, tfunc]);

                  end;
                  tp^.list := tl; { insert to list }
                  tl := tp;
                  gettlk { skip id }
            
               end;
               if (nxttlk <> ccma) and (nxttlk <> ccln) then
                  { we don't have an exit tolken }
                  perror(ecncmexp, [cidentifier, ccln, cscn]+typeset+decset+ss,
                         []);
               save := nxttlk; { save next tolken }
               if nxttlk = ccma then gettlk { skip ',' }
            
            { until no possible next id }
            until not (save in [ccma, cidentifier]);
            if nxttlk = ccln then gettlk; { skip ':' }
            partype([cscn]+decset+ss, tp); { parse type }
            { check attempt to allocate general array }
            if tp^.t = tgarry then perror(ealcgar, [], []); 
            while tl <> nil do begin { type all entries in holding list }

               tl^.vart := tp; { place entry type }
               tl := tl^.list { next entry }

            end;
            { expect ';' }
            expect(cscn, escnexp, [cidentifier, ccln, ccma, cscn]+typeset+
                   conset+[cbegin, cprivate]+ss, []);
            if not (nxttlk in [cidentifier]+conset+
                              [cbegin, cprivate, cperiod]) then
               { no follow tolken }
               perror(einvblk, [cidentifier, ccma, ccln]+corset+[cperiod]+ss, 
                               corset)

         { until not likely next variable }   
         until not (nxttlk in [cidentifier, ccma, ccln])
   
      end;

      cfixed: begin { fixed }
   
         last := nxttlk; { save that tolken }
         gettlk; { next }
         repeat
   
            if nxttlk <> cidentifier then { id expected }
               perror(eidnexp, [cidentifier, ccln, cscn]+typeset+decset+ss,
                      []);
            if nxttlk = cidentifier then begin { id found }

               define(nxtlab, sp); { define symbol }
               lsttyp(tp, tfix); { get variable type entry }
               sp^.typ := tp; { place symbol linkage }
               tp^.fixe := uselvl <> 0; { set external status }
               tp^.fixmd := modlst^.inx; { set associated module index }
               gettlk { skip id }
            
            end;
            expect(ccln, ecmaexp, [ccln]+typeset+ss, []); { expect ':' }
            partype([cscn, cequ]+decset+ss, tp1); { parse type }
            tp^.fixt := tp1; { place type }
            expect(cequ, eequexp, [cequ]+constset+ss, []); { expect '=' }
            { parse structured constant as filler }
            parstconst([cscn]+decset+ss, tp^.fixt, tp^.fixc);
            { expect ';' }
            expect(cscn, escnexp, [cidentifier, ccln, cscn]+typeset+
                   conset+[cbegin, cprivate, cperiod]+ss, []);
            if not (nxttlk in [cidentifier]+conset+
                              [cbegin, cprivate, cperiod]) then
               { no follow tolken }
               perror(einvblk, [cidentifier, ccln]+corset+[cperiod]+ss, corset)

         { until not likely next fixed }   
         until not (nxttlk in [cidentifier, ccln])
   
      end;
 
      cprocedure, cfunction, coverload, cstatic, cvirtual, coverride: begin

         { procedure/function }
         staatt := false; { set no static attribute }
         ovlatt := false; { set no overload attribute }
         viratt := false; { set no virtual attribute }
         ovratt := false; { set no override attrbute }
         { parse attributes in any order }
         while nxttlk in [cstatic, coverload, cvirtual, coverride] do begin

            { check override attribute }
            if nxttlk = coverride then begin
           
               { check duplicated override attribute }
               if viratt then perror(edupovr, [], []);
               { check conficting attribute }
               if viratt or ovlatt then perror(eattcon, [], []);
               ovratt := true; { set attribute }
               gettlk; { skip 'override' }
               if not (nxttlk in [cprocedure, cfunction, coverload, cstatic, 
                                  cvirtual, coverride]) then 
                  { error }
                  perror(efprcexp, blockset+ss, 
                         [clabel, cconst, ctype, cvar, cprocedure, cfunction, 
                          cfixed, coverload, cstatic, cvirtual, coverride])
           
            end;
            { check virtual attribute }
            if nxttlk = cvirtual then begin
          
               { check duplicated virtual attribute }
               if viratt then perror(edupvir, [], []);
               { check conficting attribute }
               if ovratt or ovlatt then perror(eattcon, [], []);
               viratt := true; { set attribute }
               gettlk; { skip 'virtual' }
               if not (nxttlk in [cprocedure, cfunction, coverload, cstatic, 
                                  cvirtual, coverride]) then 
                  { error }
                  perror(efprcexp, blockset+ss, 
                         [clabel, cconst, ctype, cvar, cprocedure, cfunction, 
                          cfixed, coverload, cstatic, cvirtual, coverride])
           
            end;
            { check static attribute }
            if nxttlk = cstatic then begin
           
               { check duplicated static attribute }
               if staatt then perror(edupsta, [], []);
               staatt := true; { set attribute }
               gettlk; { skip 'static' }
               if not (nxttlk in [cprocedure, cfunction, coverload, cstatic, 
                                  cvirtual, coverride]) then 
                  { error }
                  perror(efprcexp, blockset+ss, 
                         [clabel, cconst, ctype, cvar, cprocedure, cfunction, 
                          cfixed, coverload, cstatic, cvirtual, coverride])
           
            end;
            { check overload attribute }
            if nxttlk = coverload then begin { overload specified }
           
               { check duplicated overload attribute }
               if staatt then perror(edupovl, [], []);
               { check conficting attribute }
               if viratt or ovratt then perror(eattcon, [], []);
               ovlatt := true; { set overload active }
               gettlk; { skip 'overload' }
               if not (nxttlk in [cprocedure, cfunction]) then { error }
                  perror(efprcexp, blockset+ss, 
                         [clabel, cconst, ctype, cvar, cprocedure, cfunction, 
                          cfixed, coverload, cstatic, cvirtual, coverride])
           
            end

         end;
         { check and flag out of order }
         if fansi and not (last in [cprocedure, cfunction, cvar, ctype, 
                                    cconst, clabel, cundefined]) then 
            perror(edecor, [], [], nxtlab);
         last := nxttlk; { save that tolken }
         chkdhf; { check dangling header file }
         { parse function/procedure }
         parfproc(ovlatt, staatt, viratt, ovratt, conset+[cbegin, cprivate]+ss);
         if not (nxttlk in [cidentifier]+conset+
                           [cbegin, cprivate, cperiod]) then
            { no follow tolken }
            perror(einvblk, [cidentifier, cequ]+corset+[cperiod]+ss, corset)

      end;

      cclass, catom, cthread: begin

         { class description, validate is under module }
         if blkstk = nil then error(esflt44, true)
         else if blkstk^.mark = nil then error(esflt45, true)
         else if (blkstk^.mark^.t <> tglbl) or (curcls <> nil) then 
            perror(eclsgbl, [], []);
         parclass(conset+[cbegin, cprivate]+ss); { parse class }
         if not (nxttlk in [cidentifier]+conset+
                           [cbegin, cprivate, cperiod]) then
            { no follow tolken }
            perror(einvblk, [cidentifier, cequ]+corset+[cperiod]+ss, corset)

      end

   end;
   chkddf { check for unresolved delayed pointer definitions }

end;

{*******************************************************************************

Process class specification

*******************************************************************************}

procedure parclass(ss: tolkset); { skip set }

var cps:     typptr;  { current procedure/function save }
    psp:     symptr;  { class name symbol pointer }
    btp:     typptr;  { block type entry pointer }
    curseqs: integer; { current sequence save }
    classt:  tolken;  { class type tolken }
    mp:      modptr;  { module pointer }
    mlp:     mltptr;  { module list pointer }
    modsav:  mltptr;  { old module save mark }
    curclss: typptr;  { current class type save }
    tp, tp1: typptr;  { type pointers }
    sp:      symptr;  { symbol pointer }
    privsav: boolean; { save for private section flag }
    lab:     labl;    { label for undefines }

begin

   if fparse then writeln(':class');
   
   curclss := curcls; { save current class type }
   privsav := privat; { save private status }
   modsav := uselst; { old uses list mark }
   classt := nxttlk; { save class type }
   gettlk; { skip 'class'/'atom'/'thread' }
   psp := nil; { set no symbol exists }
   if nxttlk = cidentifier then begin { id found }

      define(nxtlab, psp); { lookup symbol }
      gettlk; { skip id }

   end;
   { get a class block entry according to type }
   btp := nil; { set no block entry }
   if classt in [cclass, catom, cthread] then case classt of

      cclass:  lsttyp(btp, tclass); { place class block }
      catom:   lsttyp(btp, tatom);  { place atom block }
      cthread: lsttyp(btp, tthread) { place thread block }

   end;
   if psp <> nil then psp^.typ := btp; { link to symbol }
   curcls := btp; { place as current active class }

   { start a new symbols enclosure }
   getmod(mp); { get a new module entry }
   if psp <> nil then mp^.modn := psp^.lab; { place module name as symbol }
   if classt in [cclass, catom, cthread] then case classt of

      cclass:  btp^.clss := mp; { place class symbols module }
      catom:   btp^.atms := mp; { place atom symbols module }
      cthread: btp^.thds := mp  { place thread symbols module }

   end;
   getmlt(mlp); { get a new module list entry }
   mlp^.next := uselst; { push onto uses list }
   uselst := mlp;
   mlp^.modp := mp; { link to module }

   { create self pseudovariable }
   if btp <> nil then begin { there is a class type }

      lsttyp(tp, tvar); { get variable entry }
      lsttyp(tp1, treference); { get reference type }
      tp^.vart := tp1; { set type of variable }
      tp^.varr := 0; { clear threat count }
      tp^.varf := 0; { clear 'for' use count }
      tp^.vars := fsnone; { set no special file handling }
      tp^.vare := uselvl <> 0; { set external status }
      tp^.varp := false; { set no subroutine threat }
      tp^.varm := true; { set is a member }
      tp1^.reft := btp; { link reference to class }
      { place self link in class }
      case btp^.t of { class }

         tclass:  btp^.clsr := tp; { class }
         tatom:   btp^.atmr := tp; { atom }
         tthread: btp^.thdr := tp; { thread }

      end

   end;

   { establish new symbols level }
   wrtsyms; { output symbols section incremental }
   level := level+1; { add new scoping level }
   sequen := sequen+1; { count scope sequence }
   curseqs := curseq; { save sequence }
   curseq := sequen; { set current sequence }

   { find and skip ';' }
   expect(cscn, escnexp, [cscn, cuses, cbegin, cperiod]+decset+ss, []);

   { parse base class if exists }
   if nxttlk = cextends then begin 

      gettlk; { skip 'extends' }
      if nxttlk <> cidentifier then 
         { no identifier found }
         perror(eidnexp, [cidentifier, cbegin, cperiod, cscn]+decset+ss, []);
      if nxttlk = cidentifier then begin { inherited class exists }

         { parse qualident, no reference grace, with default define }
         parqualident(typeset+ss, false, true, true, '', sp, lab);
         if sp = nil then error(esflt51, true);
         tp := sp^.typ; { set class type }
         { check is a class }
         if not (tp^.t in [tclass, tatom, tthread]) then begin

            perror(eclsexp, [], []); { class expected }
            tp := gbludf { set result undefined }

         end;
         if classt in [cclass, catom, cthread] then begin

            { place base class }
            case classt of
            
               cclass:  btp^.clsi := tp; { place class base }
               catom:   btp^.atmi := tp; { place atom base }
               cthread: btp^.thdi := tp  { place thread base }

            end;
            { add inherited classes to uses stack }
            pshbas(tp)

         end

      end;
      { find and skip ';' }
      expect(cscn, escnexp, [cscn, cuses, cbegin, cperiod]+decset+ss, [])

   end;

   { parse declarations }
   pardec([cbegin]+ss, false);
   if nxttlk = cprivate then begin { also has a 'private' section }

      gettlk; { get next }
      export := false; { set not exportable }
      privat := true; { set private section }
      pardec([cbegin]+ss, false) { parse private declarations }

   end;

   { Start new block. A class is transparent to its enclosing block, requiring
     only qualidents for access, so it does not need a block. However, the
     constructor and destructor must be in a block so that we know which class
     they belong to. }
   wrtsyms; { output symbols section }
   wrttyp; { output types section incremental }
   cps := curprc; { save the current block head }
   curprc := btp; { set new block head }
   pshblk(psp, btp); { start a new typing level }

   wrtcod(ibgnlvl); { output start new level marker }
   wrtlnk(btp); { output address of mark }

   stalvl := 0; { set statement level 0 }
   stalab := nil; { clear label list }
   stagto := nil; { clear goto list }

   wrtcod(ibgnpgm); { output constructor marker }
   { check constructor exists }
   if nxttlk = cbegin then parstatb(ss); { parse statement block }
   wrtcod(iendpgm); { output program main section end marker }
   if nxttlk = cscn then begin { there is an exit section }

      gettlk; { skip ';' }
      wrtcod(ibgnext); { output destructor marker }
      parstatb(ss); { parse statement block }
      wrtcod(iendext) { output program exit section end marker }

   end;

   wrtcod(iendlvl); { output end of level marker }
   chkref; { check symbol references }
   chktyp; { check type definitions }
   listtyp; { output types listing }
   listsyms(psp); { output symbols listing without purge }
   { remove inherited and current module from stack and dispose }
   while uselst <> modsav do begin

      mlp := uselst; { index top of uses list }
      uselst := uselst^.next; { remove symbols module from uses stack }
      putmlt(mlp) { dispose of entry }

   end;
   { move the class type list to its entry }
   if classt in [cclass, catom, cthread] then case classt of

      cclass:  btp^.clst := blkstk^.typ; { place class symbols types }
      catom:   btp^.atmt := blkstk^.typ; { place atom symbols types }
      cthread: btp^.thdt := blkstk^.typ  { place thread symbols types }

   end;
   purget; { remove all type list entries }
   poptyp; { restore surrounding block typelist }
   level := level-1; { remove scoping level }
   curseq := curseqs; { restore old sequence }
   curprc := cps; { restore old block head }

   expect(cperiod, eperexp, [cperiod]+ss, []); { check '.' end tolken }

   privat := privsav; { restore private status }
   curcls := curclss; { restore current class type }

end;

{*******************************************************************************

Process submodule

Processes a used or joined submodule. The name of the module is passed, and this
is converted to a filename, and the uses path is checked for the existence of
the associated module file. Then, a special abbreviated parse is done of the 
module that only parses global declarations.

A big difference between parsing regular code and parsing a module is that we
don't perform most of the error checking and recovery that we perform in normal
parsing. The logical behind this is that external modules are properly checked
when they are compiled, and any errors we could produce here would be beside
the point, or even annoying, because they don't pertain to the current module.
So we just attempt to get the proper information from the module and quit back
the the current module.

???? Seems to be a compiler bug in passing fn to opnsrc.

*******************************************************************************}

procedure prcmod(view mn:      string;   { module name }
                 view fn:      string;   { module filename }
                      isjoins: boolean); { is a joins module }

var bl:        integer; { block nesting level }
    mp:        modptr;  { module tracking entry pointer }
    mlp, mlp1: mltptr;  { module list entry pointer }
    uselsts:   mltptr;  { uses list save }
    joinlsts:  mltptr;  { join list save }
fns: filnam;

begin

   if fparse then writeln(':process submodule');
   { Save uses and joins lists, and clear them. The new module will have its own
     private copies of these lists. }
   uselsts := uselst;
   joinlsts := joinlst;
   uselst := sysmlt; { uses list always contains the system block }
   joinlst := nil;
   getfll; { get a new file list level }
   modcnt := modcnt+1; { count this module }
   getmod(mp); { get new module }
   mp^.next := modlst; { push onto list }
   modlst := mp;
   mp^.inx := modcnt; { set index for module }
   mp^.modn := copy(mn); { place module name }
   mp^.modf := copy(fn); { place pathed filename }
   { establish external module entry }
   wrtcod(iextmod);
   wrtstrp(mp^.modn^); { output just the module name }
   wrtstrp(mp^.modf^); { output the complete module name }
   { ???? should not need this copy, compiler bug }
   copy(fns, fn);
   opnsrc(fns, maxint, maxint); { open the uses file }
   getlin; { get 1st source line }
   gettlk; { load first tolken }
   { if we encounter errors attempting to parse the subheader, we just
     abort after the error and fall through. This works because the
     whole idea of parsing it is to check errors, and after the first
     error is found, we can fall back on to simple scanning }
   if not (nxttlk in [cmodule, cprogram, cprocess, cmonitor,
                      cshare]) then perror(euseukn, [], [])
   else begin { validate header }

      { validate used modules against user modules }
      if modhead = cprogram then begin

         if not (nxttlk in [cmodule, cmonitor, cshare]) then
            perror(emoduse, [], [])

      end else if modhead = cmodule then begin

         if not (nxttlk in [cprogram, cmodule, cmonitor, cshare]) then
            perror(emoduse, [], [])

      end else if modhead in [cprocess, cmonitor, cshare] then begin

         if not (nxttlk in [cmonitor, cshare]) then
            perror(emoduse, [], [])

      end;
      gettlk; { skip module tolken }
      if nxttlk <> cidentifier then { no program/module id found }
         perror(eidnexp, [], [])
      else begin { module id found }

         if not comp(mn, nxtlab) then perror(emodmat, [], []);
         { now look for uses/joins specifications }
         while not (nxttlk in [cprivate, clabel, cconst, ctype, cvar, cfixed,
                               cprocedure, cfunction, coverload, cstatic, 
                               cvirtual, coverride, cbegin, ceof]) do begin

            if nxttlk = cjoins then { parse nested joins } 
               parusesjoins([cbegin, cperiod, cprivate, ceof]+decset, true)
            else if nxttlk = cuses then { parse nested uses } 
               parusesjoins([cbegin, cperiod, cprivate, ceof]+decset, false)
            else gettlk { next }

         end

      end

   end;
   { now place the new module in the uses stack }
   getmlt(mlp); { get a new module list entry }
   mlp^.next := uselst; { push onto uses stack }
   uselst := mlp;
   mlp^.modp := mp; { index the module }
   { now we process a truncated parse of the uses file }
   bl := 0; { set nesting level }
   while (nxttlk <> cprivate) and (nxttlk <> ceof) do begin

      { until we see a private marker or eof (for safety) }
      { keep track of nesting level }
      if nxttlk in [cbegin, crecord, ccase] then bl := bl+1
      else if nxttlk = cend then bl := bl-1;
      { check 0 level declaration }
      if (nxttlk in [clabel, cconst, ctype, cvar, cfixed, cprocedure, 
                     cfunction, coverload, cstatic, cvirtual, coverride]) and
         (bl = 0) then pardec([cbegin, cperiod, cprivate, ceof], true)
      else gettlk { next }
   
   end;
   putfll; { pop current files list level }
   uselst := mlp^.next; { remove our entry from uses list }
   { Clear all added uses modules from the uses stack. The uses stack should 
     never run dry, since it contains at least the system block, but we guard 
     this case anyway. } 
   while (uselst <> sysmlt) and (uselst <> nil) do begin

      mlp1 := uselst; { index top entry }
      uselst := mlp1^.next; { gap from list }
      putmlt(mlp1) { release entry }

   end;
   { restore previous uses and joins lists }
   uselst := uselsts;
   joinlst := joinlsts;
   { if this module is used, put it back into the uses list for the caller }
   if not isjoins then begin { is a uses module }

      mlp^.next := uselst; { push onto uses list }
      uselst := mlp

   end else begin { is a joins module }

      mlp^.next := joinlst; { push onto joins list }
      joinlst := mlp

   end

end;

{*******************************************************************************

Parse 'uses'/'joins' statement

   uses = 'uses' identifier [',' identifier].. ';'

Parses the uses statement. The uses statement may open N many nested uses files
in order to parse declarations contained within.
Error recovery:

1. No file id, skip to id, ',', or ';'.

2. No ';' after statement, skip to id, ',', or ';'.

*******************************************************************************}

procedure parusesjoins(ss:      tolkset;  { skip tolkens }
                       isjoins: boolean); { is a joins module vs. uses  module }

var fn:     filnam;  { filename holder }
    last:   tolken;  { parsing aid }
    uselab: labl;    { uses file label }
    mp:     modptr;  { module tracking entry pointer }
    mlp:    mltptr;  { module list entry pointer }

begin

   if fparse then writeln(':uses/joins statement');
   uselvl := uselvl+1; { add uses nesting level }
   gettlk; { skip uses }
   repeat { process uses files }

      if nxttlk <> cidentifier then { no id }
         perror(eidnexp, [cidentifier, ccma, cscn]+ss, []);
      if nxttlk = cidentifier then begin { have found an id }

         uselab := nxtlab; { save uses file label }
         { load the indentifier as a truncated filename }
         maknam(fn, '', uselab, 'pas'); { with  extention }
         errfn := fn; { place name for error processing }
         { search for previous use of this module }
         mlp := fndqual(uselab);
         if mlp <> nil then 
            perror(edupqual, [], [], nxtlab) { already in joins/uses }
         else begin { not already in list }

            { find if there is an existing module already }
            mp := fndmod(uselab);
            if mp <> nil then begin { there is an existing module }
           
               getmlt(mlp); { get a new list entry }
               mlp^.next := uselst; { push onto uses list }
               uselst := mlp;
               mlp^.modp := mp; { link to module }
               { Search for duplicated symbols between this and any other
                 modules in the current uses stack. Note that we can save search
                 time by keeping track of modules we have already checked
                 against each other. }
               chkconflt
           
            end else begin { we haven't processed this module already }
           
               search(usepth, fn); { search for uses file }         
               if fn[1] = ' ' then 
                  perror(efnfn, [], [], errfn) { not found in path }
               else begin { process file }
           
                  fulnam(fn); { normalize filename }
                  { check file exists }
                  errfn := fn; { place name for error processing }
                  if not exists(fn) then 
                     error(efnfn, true, errfn) { not found on disk }
                  else prcmod(uselab, fn, isjoins) { process submodule }
           
               end
           
            end

         end;
         gettlk { skip file id }

      end;
      if (nxttlk <> ccma) and (nxttlk <> cscn) then
         perror(esccmexp, [cidentifier, ccma, cscn]+ss, []);
      last := nxttlk; { save last tolken }
      if nxttlk = ccma then gettlk { skip ',' }

   until not (last in [ccma, cidentifier]); { not ',' or id }
   if nxttlk = cscn then gettlk; { skip ';' }
   uselvl := uselvl-1 { back out a uses level }

end;

{*******************************************************************************

Process header file initialization

Accepts a list of header files, joined by the general list chain. Each header
file is converted to a string with '_' in front, and possibly '@' in back.
The '_' indicates that it is a system file, and the '@' indicates that it
is to preexist. The file is assigned with the name. Then, if the file is one
of the special files, we perform either a reset or rewrite on it to prepare
it for use.

*******************************************************************************}

procedure inihdf(hdt: typptr; { header files type list }
                 hds: typptr); { header files string list }

begin

   while hdt <> nil do begin { for all header files }

      if hds = nil then error(esflt19, true); { fault on lists out of sync }
      { load variable address }
      wrtcod(ilodadr); { output address load operator }
      wrtlnk(hdt); { output entry to load }
      { load string address }
      wrtcod(ilodadr); { output load address operator }
      wrtlnk(hds); { output entry to load }
      wrtcod(icvtftg); { convert fixed to tagged pointer }
      wrtlnk(hds); { write fixed type }
      wrtcod(iassign); { output assign }
      hdt^.varr := hdt^.varr+1; { set threat to variable }
      { check if the file is special, and needs reset or rewrite }
      if hdt^.vars = fsreset then begin { input special file }
   
         wrtcod(ilodadr); { load file }
         wrtlnk(hdt); { output file type }
         wrtcod(ireset); { reset file }
         wrtlnk(hdt) { output file type }
   
      end else if hdt^.vars = fsrewrite then begin { output special file }

         wrtcod(ilodadr); { load file }
         wrtlnk(hdt); { output file type }
         wrtcod(irewrite); { rewrite file }
         wrtlnk(hdt) { output file type }
   
      end; { otherwise, it is left to the user }
      hdt := hdt^.varh; { next entry }
      hds := hds^.list

   end;
   if hds <> nil then error(esflt20, true); { fault on lists out of sync }

end;

{*******************************************************************************

Parse module/program

*******************************************************************************}

procedure parmod;

var last:    tolken;  { tolken save }
    psp:     symptr;  { program/module name symbol pointer }
    sp:      symptr;  { symbol pointer }
    tp, tp1: typptr;  { type entry pointer }
    hft:     typptr;  { header files type list }
    hftl:    typptr;  { header files type list last }
    hfs:     typptr;  { header files symbol list }
    hfsl:    typptr;  { header files symbol list last}
    btp:     typptr;  { block type entry pointer }
    cps:     typptr;  { current procedure/function save }
    i:       labinx;  { index for symbol }
    curseqs: integer; { current sequence save }
    fn:      filnam;  { filename for current module }
    p, f, e: filnam;  { filename components }
    mp:      modptr;  { module pointer }
    mlp:     mltptr;  { module list entry pointer }

begin

   if fparse then writeln(':module/program');
   { place main block module entry }
   getmod(mp); { get a new module entry }
   mp^.next := modlst; { push to general list }
   modlst := mp;
   mp^.inx := modcnt; { set module index }
   modcnt := modcnt+1;
   copy(fn, fllstk^.stk^.nam); { our filename }
   fulnam(fn); { create full path }
   mp^.modf := copy(fn); { set pathed filename for module }
   brknam(fn, p, f, e); { break down filename }
   mp^.modn := copy(f); { set module name }
   { establish external module entry }
   wrtcod(iextmod);
   wrtstrp(mp^.modn^); { output just the module name }
   wrtstrp(mp^.modf^); { output the complete module name }
   getmlt(mlp); { get a new module list entry }
   mlp^.next := uselst; { push onto uses stack }
   uselst := mlp;
   mlp^.modp := mp; { index the module }
   { validate module start tolken }
   if not (nxttlk in [cmodule, cprogram, cprocess, cmonitor, cshare]) then
      begin

      { no lead tolken }
      if fansi then { 'program' expected }
         perror(eprgexp, [cmodule, cprogram, cprocess, cmonitor, cshare,
                cidentifier, clparen, cbegin, cperiod]+decset+ss,
                [cprogram, cmodule])
      else { 'module'/'program' expected }                  
         perror(empexp, [cmodule, cprogram, cprocess, cmonitor, cshare,
                cidentifier, clparen, cbegin, cperiod]+decset+ss,
                [cprogram, cmodule])

   end else if (nxttlk in [cmodule, cprocess, cmonitor, cshare]) and
               fansi then perror(eprgexp, [], []);  { wrong type of header }
   if demo_mode then begin { demo mode restrict }

      { don't allow demo mode to compile anything but a program }
      if (nxttlk in [cmodule, cprocess, cmonitor, cshare]) and
         demo_mode then error(edempgm, true)  { wrong type of header }

   end;
   modhead := nxttlk; { save head tolken }
   if nxttlk in [cmodule, cprogram, cprocess, cmonitor, cshare] then
      gettlk; { skip module tolken }
   if nxttlk <> cidentifier then
      { no program/module id found }
      perror(eidnexp, [cidentifier, clparen, cscn, cbegin, 
             cperiod]+decset+ss, []);
   psp := nil; { set no symbol exists }
   if nxttlk = cidentifier then begin { id found }

      { the block symbol goes into the system level. It is only used to name
        the block }
      define(nxtlab, psp); { lookup symbol }
      { count appearance as self reference }
      psp^.ref := psp^.ref+1;
      { Enforce that the module name must match its filename. In the main 
        module, this can be a gray area, because the user can chop it up using
        multiple command line files and/or includes. }
      if not compp(mp^.modn^, nxtlab) then perror(emodmat, [], []);
      gettlk; { skip id }

   end;
   lsttyp(btp, tglbl); { place global block }
   if modhead in [cprogram, cmodule, cprocess, cmonitor, cshare] then
      case modhead of { module type }

      cprogram: btp^.mm := mmprogram; { program }
      cmodule:  btp^.mm := mmmodule;  { module }
      cprocess: btp^.mm := mmprocess; { process }
      cmonitor: btp^.mm := mmmonitor; { monitor }
      cshare:   btp^.mm := mmshare    { share }

   end else btp^.mm := mmprogram; { default to program }
   if psp <> nil then psp^.typ := btp; { link to symbol }

   wrtsyms; { output symbols section incremental }
   level := level+1; { add new scoping level }
   sequen := sequen+1; { count scope sequence }
   curseqs := curseq; { save sequence }
   curseq := sequen; { set current sequence }

   wrttyp; { output types section incremental }
   cps := curprc; { save the current block head }
   curprc := btp; { set new block head }
   pshblk(psp, btp); { start a new typing level }

   if (nxttlk <> clparen) and (nxttlk <> cscn) then { no follow tolken }
      perror(elpscexp, [clparen, cscn, cidentifier]+blockset+ss, []);
   hft := nil; { clear header files list }
   hftl := nil;
   hfs := nil;
   hfsl := nil;
   if (nxttlk = clparen) or (nxttlk = cidentifier) then begin { header exists }

      if nxttlk = clparen then gettlk; { get next }
      repeat

         if nxttlk <> cidentifier then 
            { no identifier found }
            perror(eidnexp, [cuses, cidentifier, crparen, cbegin, 
                   cperiod, cscn]+decset+ss, []);
         if nxttlk = cidentifier then begin { id found }

            define(nxtlab, sp); { lookup symbol }
            gettlk; { skip id }
            { create file variable }
            lsttyp(tp, tvar); { get type }
            sp^.typ := tp; { link to symbol }
            tp^.vart := gbltxt; { set type text }
            tp^.varr := 0; { clear threat count }
            tp^.varf := 0; { clear 'for' use count }
            tp^.vars := fshparm; { set unresolved header file }
            tp^.vare := false; { set not external }
            tp^.varh := nil; { clear next }
            tp^.varp := false; { set no subroutine threat }
            tp^.varm := false; { set not a member }
            { insert to header files list at list end }
            if hftl = nil then hft := tp { insert to top }
            else hftl^.varh := tp; { insert to last }
            hftl := tp; { set as new last }
            { input and output files appear in default references elsewhere,
              so we must save where to find them }
            if compp(sp^.lab^, 'input') then begin 

               { special file 'input' }
               gblinp := tp; { place global root }
               gblins := sp { and symbol }

            end else if compp(sp^.lab^, 'output') then begin

               { special file 'output' }
               gblout := tp; { place global root }
               gblots := sp { and symbol }

            end;
            { set handling required on special files. this both sets what
              handling needs to be generated, and disallows user manipulation }
            if compp(sp^.lab^, 'input') or 
               compp(sp^.lab^, 'command') then 
               tp^.vars := fsreset { apply reset special handling }
            else if compp(sp^.lab^, 'output') or 
                    compp(sp^.lab^, 'error') or 
                    compp(sp^.lab^, 'list') then 
               tp^.vars := fsrewrite; { apply rewrite special handling }
            { place the label in a string with '_' prepended, to prepare for
              opening under that name }
            lsttyp(tp1, tscst); { get a string constant type entry }
            { get a string with space for leading '_' }
            new(tp1^.sval, max(sp^.lab^)+1);
            tp1^.sval^[1] := '_';
            for i := 1 to max(sp^.lab^) do
               { place label characters in string }
               tp1^.sval^[i+1] := sp^.lab^[i]; { place character }
            { insert to header files list at list end }
            if hfsl = nil then hfs := tp1 { insert to top }
            else hfsl^.list := tp1; { insert to last }
            hfsl := tp1 { set as new last }

         end;
         if (nxttlk <> ccma) and (nxttlk <> crparen) then
            { we don't have an exit tolken }
            perror(erpcmexp, [cidentifier, crparen, cuses, cbegin, 
                   cperiod, cscn]+decset+ss, []);
         last := nxttlk; { save last tolken }
         if nxttlk = ccma then gettlk { skip ',' }

      { until not likely next }
      until not (last in [ccma, cidentifier]);
      if nxttlk = crparen then gettlk { skip ')' }

   end;
   expect(cscn, escnexp, [cscn, cuses, cbegin, cperiod]+decset+ss, []);
   if not fansi then { not in ANSI mode }
      { flag in exportable section for all modules except for process modules,
        which never have importable contents }
      export := modhead <> cprocess;

   wrtcod(ibgnlvl); { output start new level marker }
   wrtlnk(btp); { output address of mark }

   { pull our module off the uses stack while processing uses/joins }
   uselst := mlp^.next; { gap }
   if nxttlk = cjoins then 
      parusesjoins([cbegin]+decset+ss, true); { parse 'joins' statement }
   if nxttlk = cuses then 
      parusesjoins([cbegin]+decset+ss, false); { parse 'uses' statement }
   { Now put our module back on the top of the uses stack. The net uses stack
     will appear as:

                1. System module.
                2. Any number of uses modules.
      uselst -> 3. This module.

   }
   mlp^.next := uselst;
   uselst := mlp;
   pardec([cbegin]+ss, false); { parse declarations }
   if nxttlk = cprivate then begin { also has a 'private' section }

      gettlk; { get next }
      export := false; { set not exportable }
      pardec([cbegin]+ss, false) { parse private declarations }

   end;

   stalvl := 0; { set statement level 0 }
   stalab := nil; { clear label list }
   stagto := nil; { clear goto list }
   chkdhf; { check dangling header files }

   wrttyp; { output types section }
   wrtsyms; { output symbols section }

   wrtcod(ibgnpgm); { output program main section marker }
   inihdf(hft, hfs); { initalize header files }
   if not fansi and (nxttlk = cbegin) and (modhead = cshare) then
      perror(eshrent, [], []); { share should not have entry section }
   { check we have defacto block or if not in share module }
   if (nxttlk = cbegin) or not (modhead = cshare) then
      parstatb(ss); { parse statement block }
   wrtcod(iendpgm); { output program main section end marker }
   if nxttlk = cscn then begin { there is an exit section }

      { flag error for a program, process or share containing an exit section }
      if modhead in [cprogram, cprocess, cshare] then 
         if fansi then perror(epgmext, [], []) { ansi mode error }
         else perror(eppsext, [], []); { general mode error }
      gettlk; { get next }
      wrtcod(ibgnext); { output program exit section marker }
      parstatb(ss); { parse statement block }
      wrtcod(iendext) { output program exit section end marker }

   end;
   wrtcod(iendlvl); { output end of level marker }
   chkref; { check symbol references }
   chktyp; { check type definitions }
   listtyp; { output types listing }
   listsym(psp); { output symbols listing and purge }
   purget; { remove all type list entries }
   poptyp; { restore surrounding block typelist }
   level := level-1; { remove scoping level }
   curseq := curseqs; { restore old sequence }
   curprc := cps; { restore old block head }
   { remove module from uses list }
   uselst := mlp^.next; { gap }
   putmlt(mlp); { release entry }
   expect(cperiod, eperexp, [cperiod]+ss, []) { check '.' end tolken }

end;

begin
end.
