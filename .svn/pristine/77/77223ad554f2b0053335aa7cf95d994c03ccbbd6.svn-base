{*******************************************************************************
*                                                                              *
*                                 C PARSER                                     *
*                                                                              *
* Performs parsing for C language code. Based on grammar from "The C           *
* programming language (ANSI edition) [K&R].                                   *
*                                                                              *
*******************************************************************************}

module parser(output);

uses stddef,  { standard defines }
     strlib,  { strings }
     scanner, { scanner }
     symbol;  { symbols and types processing }

procedure partrans; forward; { parse translation unit }

var fprtrle: boolean; { print parsing rules }
    fuse:    boolean; { allow unnamed struct/union elements }
    fmsasm:  boolean; { allow Microsoft asm constructs }
    fenecma: boolean; { allow extra enumerator comment }
    fduptyp: boolean; { allow type duplication }

private

const

{ sizing constants. because C allows access to the size of objects at compile
  time via the sizeof construct, we have to know what the sizes of various C
  types are. These values are the values for 32 bit intel and similar
  processors. }
charlen     = 1; { length of char }
charalgn    = 1; { length of char }
intlen      = 4; { length of int }
intalgn     = 4; { length of int }
shortlen    = 2; { length of short int }
shortalgn   = 2; { length of short int }
longlen     = 4; { length of long int }
longalgn    = 4; { length of long int }
floatlen    = 8; { length of float (all floats are "real" }
floatalgn   = 4; { length of float (all floats are "real" }
doublelen   = 8; { length of double }
doublealgn  = 4; { length of double }
ldoublelen  = 8; { length of long double }
ldoublealgn = 4; { length of long double }
ptrlen      = 4; { length of pointer }
ptralgn     = 4; { length of pointer }
voidlen     = 4; { length of "void" }
voidalgn    = 4; { length of "void" }

{ type-specifier lead tolkens }
typespecld = [cvoid, cchar, cshort, cint, clong, cfloat, cdouble, csigned,
              cunsigned, cstruct, cunion, cenum, cidentifier];
{ declaration-specifiers lead tolkens }
decspecld = [cauto, cregister, cstatic, cextern, ctypedef, cconst, cvolatile,
             cvoid, cchar, cshort, cint, clong, cfloat, cdouble, csigned,
             cunsigned, cstruct, cunion, cenum, cidentifier];
{ storage class type bits }
sctypflg = [tfauto, tfregister, tfstatic, tfextern, tftypedef];

var

{ we define a series of global types to reduce thrashing }
gtudf:     typptr; { global undefined }
gtvoid:    typptr; { global void }
gtint:     typptr; { global int }
gtsint:    typptr; { global signed int }
gtuint:    typptr; { global unsigned int }
gtshint:   typptr; { global short int }
gtssint:   typptr; { global signed short int }
gtusint:   typptr; { global unsigned short int }
gtlint:    typptr; { global long int }
gtslint:   typptr; { global signed long int }
gtulint:   typptr; { global unsigned long int }
gtchr:     typptr; { global char }
gtschr:    typptr; { global signed char }
gtuchr:    typptr; { global unsigned char }
gtflt:     typptr; { global float }
gtdbl:     typptr; { global double }
gtldbl:    typptr; { global long double }

gtcvoid:   typptr; { global const void }
gtcint:    typptr; { global const int }
gtcsint:   typptr; { global const signed int }
gtcuint:   typptr; { global const unsigned int }
gtcshint:  typptr; { global const short int }
gtcssint:  typptr; { global const signed short int }
gtcusint:  typptr; { global const unsigned short int }
gtclint:   typptr; { global const long int }
gtcslint:  typptr; { global const signed long int }
gtculint:  typptr; { global const unsigned long int }
gtcchr:    typptr; { global const char }
gtcschr:   typptr; { global const signed char }
gtcuchr:   typptr; { global const unsigned char }
gtcflt:    typptr; { global const float }
gtcdbl:    typptr; { global const double }
gtcldbl:   typptr; { global const long double }

gtvvoid:   typptr; { global volatile void }
gtvint:    typptr; { global volatile int }
gtvsint:   typptr; { global volatile signed int }
gtvuint:   typptr; { global volatile unsigned int }
gtvshint:  typptr; { global volatile short int }
gtvssint:  typptr; { global volatile signed short int }
gtvusint:  typptr; { global volatile unsigned short int }
gtvlint:   typptr; { global volatile long int }
gtvslint:  typptr; { global volatile signed long int }
gtvulint:  typptr; { global volatile unsigned long int }
gtvchr:    typptr; { global volatile char }
gtvschr:   typptr; { global volatile signed char }
gtvuchr:   typptr; { global volatile unsigned char }
gtvflt:    typptr; { global volatile float }
gtvdbl:    typptr; { global volatile double }
gtvldbl:   typptr; { global volatile long double }

gtcvvoid:  typptr; { global const volatile void }
gtcvint:   typptr; { global const volatile int }
gtcvsint:  typptr; { global const volatile signed int }
gtcvuint:  typptr; { global const volatile unsigned int }
gtcvshint: typptr; { global const volatile short int }
gtcvssint: typptr; { global const volatile signed short int }
gtcvusint: typptr; { global const volatile unsigned short int }
gtcvlint:  typptr; { global const volatile long int }
gtcvslint: typptr; { global const volatile signed long int }
gtcvulint: typptr; { global const volatile unsigned long int }
gtcvchr:   typptr; { global const volatile char }
gtcvschr:  typptr; { global const volatile signed char }
gtcvuchr:  typptr; { global const volatile unsigned char }
gtcvflt:   typptr; { global const volatile float }
gtcvdbl:   typptr; { global const volatile double }
gtcvldbl:  typptr; { global const volatile long double }

procedure pardecl; forward;
procedure parexpr; forward;
procedure parassexpr; forward;
procedure parcastexpr(cst: boolean; var val: integer; var wasunary: boolean);
   forward;
procedure parcondexpr(cst: boolean; var val: integer; var wasunary: boolean);
   forward;
procedure pardect(var sp: symptr; var head, tail: typptr; abs, cabs: boolean);
   forward;
procedure parstrunienum(var tp: typptr); forward;
procedure pardecspec(var tp: typptr; stcl: boolean; var sc: typflg; 
                     var sp: symptr); forward;

{******************************************************************************

Place base type

Places the given base type in a type entry. Exactly where the base type pointer
gets placed depends on the entry.
If there is a preferred base symbol present, will place that.

******************************************************************************}

procedure plcbase(var tp: typptr; base: typptr; sp: symptr);

begin

   if not (tp^.t in [tptr, tarray, tfield, tvar, tfunc, tpar]) then
      error(esys1, ''); { no base for this entry }
   case tp^.t of { entry type }


      tptr:    begin

         tp^.ptrt := base;
         tp^.ptrts := sp

      end;
      tarray:  begin

         tp^.arrt := base;
         tp^.arrts := sp;
         { if element count is defined, set size of array }
         if tp^.arre > 0 then tp^.size := tp^.arrt^.size*tp^.arre;
         tp^.algn := tp^.arrt^.algn { set alignment }

      end;
      tfield:  begin

         tp^.fldt := base;
         tp^.fldts := sp;
         tp^.size := tp^.fldt^.size; { set to base size }
         tp^.algn := tp^.fldt^.algn { set to base alignment }

      end;
      tvar:    begin

         tp^.vart := base;
         tp^.size := tp^.vart^.size; { set to base size }
         tp^.algn := tp^.vart^.algn { set to base alignment }

      end;
      tfunc:   begin

         tp^.fncr := base;
         tp^.fncrs := sp

      end;
      tfunci:  tp^.fnit := base;
      tpar:    begin

         tp^.part := base;
         tp^.parts := sp;
         tp^.size := tp^.part^.size; { set to base size }
         tp^.algn := tp^.part^.algn

      end

   end

end;

{******************************************************************************

Join type lists

Joins two type lists end for end. The new list is returned in the destination.
Handles the case where one or more lists are nil.
Note that a complete destination can be joined to another type without a tail,
but the destination must have a tail to be joined.
Takes a preferred symbol.

******************************************************************************}

procedure jointype(var dhead, dtail: typptr; shead, stail: typptr; sp: symptr);

begin

   if dhead = nil then begin { the destination is nil, set to source }

      dhead := shead;
      dtail := stail

   end else if shead <> nil then begin { the source list is not nil }

      if dtail = nil then error(esys2, ''); { should not be nil }
      plcbase(dtail, shead, sp); { place the source list in last desination }
      { storage classes ripple upwards }
      if (dhead^.tfs*sctypflg <> []) and (shead^.tfs*sctypflg <> [])
         then error(escldup, ''); { both have valid storage classes }
      { check tail has a class }
      if shead^.tfs*sctypflg <> [] then begin 

         dhead^.tfs := dhead^.tfs+shead^.tfs*sctypflg; { transfer }
         shead^.tfs := shead^.tfs-sctypflg { clear old }

      end;
      dtail := stail { set tail to new end }

   end

end;

{******************************************************************************

Check declaration leader

Checks if a declaration leader is present at the next tolken. A declaration
leader is one of the decspecld set lead tolkens, which comprise the
storage-class-specifiers, the type-qualifiers, and any typing tolkens, but
without the identifier. If there is an identifier, it must exist and evaluate
to a type id to be considered a declaration leader.

******************************************************************************}

function declead: boolean;

var decfnd: boolean; { declaration found flag }
    sp:     symptr;  { symbol pointer }

begin

   decfnd := false; { set no declaration found }
   if nxttlk = cidentifier then begin

      sp := gblsym(nxtlab, false); { find symbol }
      if sp <> nil then begin

         if sp^.typ = nil then error(esys3, ''); { should have a type }
         if sp^.typ^.t in [tvoid, tint, tfloat, tptr, tenum, tarray, tstruct,
                           tunion, tfunc] then
            decfnd := true; { set declaration found }

      end

   end else if nxttlk in decspecld then
      decfnd := true; { set declaration found }
   declead := decfnd { return result }

end;

{******************************************************************************

Check type name leader

Checks if a declaration leader is present at the next tolken. A declaration
leader is one of the decspecld set lead tolkens, which comprise the
storage-class-specifiers, the type-qualifiers, and any typing tolkens, but
without the identifier. If there is an identifier, it must exist and evaluate
to a type id to be considered a declaration leader.

******************************************************************************}

function typnlead: boolean;

var typfnd: boolean; { declaration found flag }
    sp:     symptr;  { symbol pointer }

begin

   typfnd := false; { set no typespec found }
   if nxttlk = cidentifier then begin

      sp := gblsym(nxtlab, false); { find symbol }
      if sp <> nil then begin

         if sp^.typ = nil then error(esys4, ''); { should have a type }
         if sp^.typ^.t in [tvoid, tint, tfloat, tptr, tenum, tarray, tstruct,
                           tunion, tfunc] then
            typfnd := true; { set typespec found }

      end

   end else if nxttlk in typespecld+[cconst, cvolatile] then
      typfnd := true; { set typespec found }
   typnlead := typfnd { return result }

end;

{******************************************************************************

Parse primary-expression

Parses the primary-expression construct.

******************************************************************************}

procedure parprimexpr(cst: boolean; var val: integer);

var dummy: boolean;
    sp:    symptr;  { symbol pointer }
    cstf:  boolean; { constant found flag }

begin

   if fprtrle then writeln('parprimexpr:');
   if nxttlk = cidentifier then begin { id }

      if cst then begin

         cstf := false; { set no constant found }
         sp := gblsym(nxtlab, false); { find constant id }
         if sp <> nil then { there is a symbol }
            if sp^.typ <> nil then { is has a type }
               if sp^.typ^.t = tenme then begin { enumerated constant }

            val := sp^.typ^.env; { set value }
            cstf := true { set found }

         end;
         if not cstf then error(eicstexp, '') { must be integer constant }

      end;
      gettlk { skip id }

   end else if nxttlk in [ccint, cclong, cclonglong, ccuint, cculong,
                     cculonglong] then begin { integer constant }

      val := nxtint; { set constant return }
      gettlk { skip }

   end else if nxttlk = cstring then begin { string constant }

      if cst then begin { perform constant processing }

         if nxtlen <> 1 then error(eicstexp, ''); { must be constant }
         val := ord(nxtlab[1]) { get the value of the character }

      end;
      gettlk { skip }

   end else if nxttlk = creal then begin { real }

      if cst then error(eicstexp, ''); { must be constant }
      gettlk { skip }

   end else if nxttlk = clparen then begin { ( expression ) }

      gettlk; { skip '(' }
      { check constant or full expression }
      if cst then parcondexpr(cst, val, dummy) { parse constant expression }
      else parexpr; { parse expression }
      if nxttlk <> crparen then error(erpexp, ''); { ')' expected }
      gettlk { skip ']' }

   end else error(eprmexp, '') { nothing found }

end;

{******************************************************************************

Parse postfix-expression

Parses the postfix-expression construct.
Accepts a constant flag, and a constant return value. If the constant flag
is true, the operation will be performed as a constant operation, with
non-constant elements being flagged in error. The value will then be returned.

******************************************************************************}

procedure parpostexpr(cst: boolean; var val: integer);

begin

   if fprtrle then writeln('parpostexpr:');
   parprimexpr(cst, val); { parse primary-expression }
   while nxttlk in [clbrkt, clparen, cperiod, cprec, cinc, cdec] do begin

      if cst then error(ecstopr, ''); { operation not permitted for constant }
      case nxttlk of { operator }

         clbrkt: begin { [ expression ] }

            gettlk; { skip '[' }
            parexpr; { parse expression }
            if nxttlk <> crbrkt then error(erbktexp, '');
            gettlk { skip ']' }

         end;
         clparen: begin { ( assignment-expression ) }

            gettlk; { skip '(' }
            while nxttlk <> crparen do begin { parse assignment-expressions }

               parassexpr; { parse assignment-expression }
               { check ',' or ')' }
               if not (nxttlk in [ccma, crparen]) then error(erpexp, '');
               if nxttlk = ccma then gettlk { skip ',' }

           end;
           if nxttlk <> crparen then error(erpexp, ''); { ')' expected }
           gettlk { skip ')' }

         end;
         cperiod: begin { .identifier }

            gettlk; { skip '.' }
            if nxttlk <> cidentifier then error(eidexp, ''); { must be id }
            gettlk { skip id }

         end;
         cprec: begin { ->identifier }

            gettlk; { skip '->' }
            if nxttlk <> cidentifier then error(eidexp, ''); { must be id }
            gettlk { skip id }

         end;
         cinc: gettlk; { ++ }
         cdec: gettlk { -- }

      end

   end

end;

{******************************************************************************

Parse unary-expression

Parses the unary-expression construct.
Accepts a constant flag, and a constant return value. If the constant flag
is true, the operation will be performed as a constant operation, with
non-constant elements being flagged in error. The value will then be returned.

******************************************************************************}

procedure parunaexpr(cst: boolean; var val: integer);

var dummy:      boolean;
    sp, csp:    symptr;  { symbol pointer }
    tp:         typptr;  { type pointer }
    head, tail: typptr;  { list of types }
    sc:         typflg;  { storage class }

begin

   if fprtrle then writeln('parunaexpr:');
   if nxttlk in [cinc, cdec, csizeof, cand, ctimes, cplus, cminus, ccomp,
                 clnot] then begin

      { check valid operation for constant }
      if cst and (nxttlk in [cinc, cdec, cand, ctimes]) then error(ecstopr, '');
      case nxttlk of { tolken }

         cinc: begin gettlk; parunaexpr(cst, val) end; { ++ unary-expression }
         cdec: begin gettlk; parunaexpr(cst, val) end; { -- unary-exrression }
         csizeof: begin { sizeof }

            gettlk; { skip 'sizeof' }
            if nxttlk = clparen then begin { sizeof(type-name) }

               gettlk; { skip '(' }
               { parse type-name construct, here because we need a terminator }
               pardecspec(tp, false, sc, csp); { parse specifier-qualifier-list }
               if sc <> tfnone then error(enostcl, ''); { no storage class }
               if nxttlk <> crparen then begin { declarator present }
             
                  { parse abstract declarator }
                  pardect(sp, head, tail, true, false);
                  jointype(head, tail, tp, nil, csp); { place base type }
                  tp := head { place net type }
             
               end;
               val := tp^.size; { return size of type }
               if nxttlk <> crparen then error(erpexp, ''); { ')' expected }
               gettlk { skip ')' }

            end else begin { size of unary-expression }

               { have not implemented sizeof unary-expression, because this
                 would involve completely tracking the types in an expression}
               parunaexpr(cst, val); { parse unary-expression }
               val := 0 { set no length }

            end

         end;
         cand: begin { & cast-expression }
  
            gettlk;
            parcastexpr(cst, val, dummy)

         end;
         ctimes: begin  { * cast-expression }

            gettlk;
            parcastexpr(cst, val, dummy)
  
         end;
         cplus: begin { + cast-expression }

            gettlk;
            parcastexpr(cst, val, dummy)

         end;
         cminus: begin { - cast-expression }

            gettlk;
            parcastexpr(cst, val, dummy);
            if cst then val := -val { perform if constant }

         end;
         ccomp: begin { ~ cast-expression }

            gettlk;
            parcastexpr(cst, val, dummy);
            if cst then val := not val { perform if constant }

         end;
         clnot: begin { ! cast-expression }

            gettlk;
            parcastexpr(cst, val, dummy);
            if cst then val := ord(val = 0) { perform if constant }

         end 

      end

   end else parpostexpr(cst, val) { parse postfix-expression }

end;

{******************************************************************************

Parse cast-expression

Parses the cast-expression construct.
Accepts a constant flag, and a constant return value. If the constant flag
is true, the operation will be performed as a constant operation, with
non-constant elements being flagged in error. The value will then be returned.

******************************************************************************}

procedure parcastexpr(cst: boolean; var val: integer; var wasunary: boolean);

var dummy:      boolean;
    tp:         typptr;  { type pointer }
    sp, csp:    symptr;  { symbol pointer }
    head, tail: typptr;  { list pointers }
    sc:         typflg;  { storage class }

begin

   if fprtrle then writeln('parcastexpr:');
   if nxttlk = clparen then begin { ( type-name ) }

      gettlk; { skip '(' }
      if typnlead then begin { type name leader found }

         wasunary := false; { implicate unary }
         { parse type-name construct, here because we need a terminator }
         pardecspec(tp, false, sc, csp); { parse specifier-qualifier-list }
         if sc <> tfnone then error(enostcl, ''); { no storage class }
         if nxttlk <> crparen then begin { declarator present }

            pardect(sp, head, tail, true, false); { parse abstract declarator }
            jointype(head, tail, tp, nil, csp); { place base type }
            tp := head { place net type }

         end;
         if nxttlk <> crparen then error(erpexp, ''); { ')' expected }
         gettlk; { skip ')' }
         if cst and (tp^.t <> tint) then error(ecstcas, '');
         parcastexpr(cst, val, dummy) { parse cast-expression }

      end else begin { its a primary-expression, back out }

         pshtlk; { push back current tolken }
         parunaexpr(cst, val) { parse unary-expression }

      end
      
   end else parunaexpr(cst, val) { parse unary-expression }

end;

{******************************************************************************

Parse multiplicative-expression

Parses the multiplicative-expression construct.
Accepts a constant flag, and a constant return value. If the constant flag
is true, the operation will be performed as a constant operation, with
non-constant elements being flagged in error. The value will then be returned.

******************************************************************************}

procedure parmultexpr(cst: boolean; var val: integer; var wasunary: boolean);

var t:    tolken;
    rval: integer;

begin

   if fprtrle then writeln('parmultexpr:');
   parcastexpr(cst, val, wasunary); { parse cast-expression }
   while nxttlk in [ctimes, cdiv, cmod] do begin { operator }

      wasunary := false; { implicate unary }
      t := nxttlk; { save next tolken }
      gettlk; { skip operator }
      parcastexpr(cst, rval, wasunary); { parse cast-expression }
      if cst then case t of { operator }

         ctimes: val := val*rval;
         cdiv:   val := val div rval;
         cmod:   val := val mod rval

      end

   end

end;

{******************************************************************************

Parse additive-expression

Parses the additive-expression construct.
Accepts a constant flag, and a constant return value. If the constant flag
is true, the operation will be performed as a constant operation, with
non-constant elements being flagged in error. The value will then be returned.

******************************************************************************}

procedure paraddexpr(cst: boolean; var val: integer; var wasunary: boolean);

var t:    tolken;
    rval: integer;

begin

   if fprtrle then writeln('paraddexpr:');
   parmultexpr(cst, val, wasunary); { parse multiplicative-expression }
   while nxttlk in [cplus, cminus] do begin

      wasunary := false; { implicate unary }
      t := nxttlk; { save next tolken }
      gettlk; { skip operator }
      parmultexpr(cst, rval, wasunary); { parse multiplicative-expression }
      if cst then case t of { operator }
      
         cplus:  val := val+rval;
         cminus: val := val-rval

      end

   end

end;

{******************************************************************************

Parse shift-expression

Parses the shift-expression construct.
Accepts a constant flag, and a constant return value. If the constant flag
is true, the operation will be performed as a constant operation, with
non-constant elements being flagged in error. The value will then be returned.

******************************************************************************}

procedure parshftexpr(cst: boolean; var val: integer; var wasunary: boolean);

var t:    tolken;
    rval: integer;

begin

   if fprtrle then writeln('parshftexpr:');
   paraddexpr(cst, val, wasunary); { parse additive-expression }
   while nxttlk in [cshl, cshr] do begin

      wasunary := false; { implicate unary }
      t := nxttlk; { save next tolken }
      gettlk; { skip operator }
      paraddexpr(cst, rval, wasunary); { parse additive-expression }
      if cst then case t of { operator }

         cshl: begin { shift left }

            if rval < 0 then error(eshftno, ''); { cannot be minus }
            if rval >= 31 then val := 0 { full shiftout }
            else while rval > 0 do begin { perform shift }

               { remove high bit if present }
               if val > maxint div 2 then val := val-maxint div 2;
               val := val*2; { shift }
               rval := rval-1 { count }

            end

         end;
         cshr: begin { shift right }

            if rval < 0 then error(eshftno, ''); { cannot be minus }
            if rval >= 31 then val := 0 { full shiftout }
            else while rval > 0 do begin { perform shift }

               val := val div 2; { shift }
               rval := rval-1 { count }

            end

         end

      end

   end

end;

{******************************************************************************

Parse relational-expression

Parses the relational-expression construct.
Accepts a constant flag, and a constant return value. If the constant flag
is true, the operation will be performed as a constant operation, with
non-constant elements being flagged in error. The value will then be returned.

******************************************************************************}

procedure parrelexpr(cst: boolean; var val: integer; var wasunary: boolean);

var t:    tolken;
    rval: integer;

begin

   if fprtrle then writeln('parrelexpr:');
   parshftexpr(cst, val, wasunary); { parse shift-expression }
   while nxttlk in [cltn, cgtn, clequ, cgequ] do begin

      wasunary := false; { implicate unary }
      t := nxttlk; { save next tolken }
      gettlk; { skip operator }
      parshftexpr(cst, rval, wasunary); { parse shift-expression }
      if cst then case t of { operator }

         cltn:  val := ord(val < rval); 
         cgtn:  val := ord(val > rval);
         clequ: val := ord(val <= rval);
         cgequ: val := ord(val >= rval)

      end

   end

end;

{******************************************************************************

Parse equality-expression

Parses the equality-expression construct.
Accepts a constant flag, and a constant return value. If the constant flag
is true, the operation will be performed as a constant operation, with
non-constant elements being flagged in error. The value will then be returned.

******************************************************************************}

procedure parequexpr(cst: boolean; var val: integer; var wasunary: boolean);

var t:    tolken;
    rval: integer;

begin

   if fprtrle then writeln('parequexpr:');
   parrelexpr(cst, val, wasunary); { parse relational-expression }
   while nxttlk in [cequ, cnequ] do begin

      wasunary := false; { implicate unary }
      t := nxttlk; { save next tolken }
      gettlk; { skip operator }
      parrelexpr(cst, rval, wasunary); { parse relational-expression }
      if cst then case t of { operator }

         cequ:  val := ord(val = rval);
         cnequ: val := ord(val <> rval)

      end

   end

end;

{******************************************************************************

Parse and-expression

Parses the and-expression construct.
Accepts a constant flag, and a constant return value. If the constant flag
is true, the operation will be performed as a constant operation, with
non-constant elements being flagged in error. The value will then be returned.

******************************************************************************}

procedure parandexpr(cst: boolean; var val: integer; var wasunary: boolean);

var rval: integer;

begin

   if fprtrle then writeln('parandexpr:');
   parequexpr(cst, val, wasunary); { parse equality-expression }
   while nxttlk = cand do begin

      wasunary := false; { implicate unary }
      gettlk; { skip operator }
      parequexpr(cst, rval, wasunary); { parse equality-expression }
      if cst then val := val and rval

   end

end;

{******************************************************************************

Parse exclusive-or-expression

Parses the exclusive-or-expression construct.
Accepts a constant flag, and a constant return value. If the constant flag
is true, the operation will be performed as a constant operation, with
non-constant elements being flagged in error. The value will then be returned.

******************************************************************************}

procedure parxorexpr(cst: boolean; var val: integer; var wasunary: boolean);

var rval: integer;

begin

   if fprtrle then writeln('parxorexpr:');
   parandexpr(cst, val, wasunary); { parse and-expression }
   while nxttlk = cxor do begin

      wasunary := false; { implicate unary }
      gettlk; { skip operator }
      parandexpr(cst, rval, wasunary); { parse and-expression }
      if cst then val := val xor rval

   end

end;

{******************************************************************************

Parse inclusive-or-expression

Parses the inclusive-or-expression construct.
Accepts a constant flag, and a constant return value. If the constant flag
is true, the operation will be performed as a constant operation, with
non-constant elements being flagged in error. The value will then be returned.

******************************************************************************}

procedure parorexpr(cst: boolean; var val: integer; var wasunary: boolean);

var rval: integer;

begin

   if fprtrle then writeln('parorexpr:');
   parxorexpr(cst, val, wasunary); { parse exclusive-or-expression }
   while nxttlk = cor do begin

      wasunary := false; { implicate unary }
      gettlk; { skip operator }
      parxorexpr(cst, rval, wasunary); { parse exclusive-or-expression }
      if cst then val := val or rval

   end

end;

{******************************************************************************

Parse logical-and-expression

Parses the logical-and-expression construct.
Accepts a constant flag, and a constant return value. If the constant flag
is true, the operation will be performed as a constant operation, with
non-constant elements being flagged in error. The value will then be returned.

******************************************************************************}

procedure parlandexpr(cst: boolean; var val: integer; var wasunary: boolean);

var rval: integer;

begin

   if fprtrle then writeln('parlandexpr:');
   parorexpr(cst, val, wasunary); { parse inclusive-or-expression }
   while nxttlk = cland do begin

      wasunary := false; { implicate unary }
      gettlk; { skip operator }
      parorexpr(cst, rval, wasunary); { parse inclusive-or-expression }
      if cst then val := ord((val <> 0) and (rval <> 0))

   end

end;

{******************************************************************************

Parse logical-or-expression

Parses the logical-or-expression construct.
Accepts a constant flag, and a constant return value. If the constant flag
is true, the operation will be performed as a constant operation, with
non-constant elements being flagged in error. The value will then be returned.

******************************************************************************}

procedure parlorexpr(cst: boolean; var val: integer; var wasunary: boolean);

var rval: integer;

begin

   if fprtrle then writeln('parlorexpr:');
   parlandexpr(cst, val, wasunary); { parse logical-and-expression }
   while nxttlk = clor do begin

      wasunary := false; { implicate unary }
      gettlk; { skip operator }
      parlandexpr(cst, rval, wasunary); { parse logical-and-expression }
      if cst then val := ord((val <> 0) or (rval <> 0))

   end

end;

{******************************************************************************

Parse conditional-expression

Parses the conditional-expression construct. conditional-expression is a
synonoym for constant expression, so this routine is also used to form
constant-expressions.
Accepts a constant flag, and a constant return value. If the constant flag
is true, the operation will be performed as a constant operation, with
non-constant elements being flagged in error. The value will then be returned.

******************************************************************************}

procedure parcondexpr(cst: boolean; var val: integer; var wasunary: boolean);

var rval1, rval2: integer;

begin

   if fprtrle then writeln('parcondexpr:');
   wasunary := true; { set unary true until implicated }
   parlorexpr(cst, val, wasunary); { parse logical-or-expression }
   if nxttlk = ccond then begin

      wasunary := false; { implicate unary }
      gettlk; { skip '?' }
      if cst then parcondexpr(cst, rval1, wasunary) { parse constant }
      else parexpr; { parse expression }
      if nxttlk <> ccln then error(eclnexp, ''); { ':' expected }
      gettlk; { skip ':' }
      parcondexpr(cst, rval2, wasunary); { parse conditional-expression }
      if cst then begin { process for constant }

         if val <> 0 then val := rval1 else val := rval2

      end
   
   end

end;

{******************************************************************************

Parse assignment-expression

Parses the assignment-expression construct.

******************************************************************************}

procedure parassexpr;

var wasunary: boolean;
    val:      integer;

begin

   if fprtrle then writeln('parassexpr:');
   parcondexpr(false, val, wasunary); { parse conditional-expression }
   if wasunary and (nxttlk in [cas, casadd, cassub, casmlt, casdiv, casmod,
                               casshl, casshr, casand, casxor, casor]) then
      begin

      gettlk; { skip operator }
      parassexpr { parse assignment-expression }

   end

end;

{******************************************************************************

Parse expression

Parses the expression construct.

******************************************************************************}

procedure parexpr;

var t: tolken;

begin

   if fprtrle then writeln('parexpr:');
   repeat

      parassexpr; { parse assignment-expression }
      t := nxttlk; { save next tolken }
      if nxttlk = ccma then gettlk { skip ',' }

   until t <> ccma

end;

{******************************************************************************

Parse statement

Parses the statment construct.

******************************************************************************}

procedure parstat;

var dummy: boolean;
    val:   integer;
                              
begin

   if fprtrle then writeln('parstat:');
   { check statement leader }
   if nxttlk in [cidentifier, ccase, cdefault, cbegin, cif, cswitch, cwhile,
                 cdo, cfor, cgoto, ccontinue, cbreak, creturn] then
      case nxttlk of { leader }

      cidentifier: begin { id leader }

         if compcp(nxtlab, '_asm') or compcp(nxtlab, '__asm') and fmsasm then
            begin

            { microsoft __asm construct, we just skip this }
            gettlk; { skip id }
            if nxttlk <> cbegin then begin { use single line form }

               while not (nxttlk in [cend, ceof]) do gettlk; { skip contents }
               if nxttlk <> cend then error(eendexp, '') { should be end }

            end else begin { multiple line form }

               while not (nxttlk in [cend, ceof]) do gettlk; { skip contents }
               if nxttlk <> cend then error(eendexp, ''); { should be end }
               gettlk { skip end }

            end

         end else begin { label: statement }

            gettlk; { skip id }
            if nxttlk = ccln then begin { its a label }

               gettlk; { skip ':' }
               parstat { parse statement }

            end else begin { its an expression }

               pshtlk; { pushback one tolken }
               parexpr; { parse expression }
               if nxttlk <> cscn then error(escnexp, ''); { ';' expected }
               gettlk { skip ';' }

            end

         end

      end;
      ccase: begin { case conditional-expression: statement }

         gettlk; { skip 'case' }
         { parse conditional expression (don't care unary) }
         parcondexpr(true, val, dummy);
         if nxttlk <> ccln then error(eclnexp, ''); { ':' expected }
         gettlk; { skip ':' }
         parstat { parse statement }

      end;
      cdefault: begin { default: statement }

         gettlk; { skip 'default' }
         if nxttlk <> ccln then error(eclnexp, ''); { ':' expected }
         gettlk; { skip ':' }
         parstat { parse statement }
     
      end;
      cbegin: begin { begin declaration statement end }

         gettlk; { skip left bracket }
         while declead do pardecl; { parse any declarations }
         while nxttlk <> cend do parstat; { parse statements }
         gettlk { skip end }

      end;
      cif: begin { if (expression) statement else statement }

         gettlk; { skip 'if' }
         if nxttlk <> clparen then error(elpexp, ''); { '(' expected }
         gettlk; { skip '(' }
         parexpr; { parse expression }
         if nxttlk <> crparen then error(erpexp, ''); { ')' expected }
         gettlk; { skip '(' }
         parstat; { parse statement }
         if nxttlk = celse then begin { there is an else }

            gettlk; { skip 'else' }
            parstat { parse statement }

         end

      end;
      cswitch: begin { switch (expression) statement }

         gettlk; { skip 'switch' }
         if nxttlk <> clparen then error(elpexp, ''); { '(' expected }
         gettlk; { skip '(' }
         parexpr; { parse expression }
         if nxttlk <> crparen then error(erpexp, ''); { ')' expected }
         gettlk; { skip '(' }
         parstat { parse statement }

      end;
      cwhile: begin { while (expression) statement }

         gettlk; { skip 'while' }
         if nxttlk <> clparen then error(elpexp, ''); { '(' expected }
         gettlk; { skip '(' }
         parexpr; { parse expression }
         if nxttlk <> crparen then error(erpexp, ''); { ')' expected }
         gettlk; { skip '(' }
         parstat { parse statement }

      end;
      cdo: begin { do statement while (expression); }

         gettlk; { skip 'do' }
         parstat; { parse statement }
         if nxttlk <> cwhile then error(ewhlexp, ''); { 'while' expected }
         gettlk; { skip 'while' }
         if nxttlk <> clparen then error(elpexp, ''); { '(' expected }
         gettlk; { skip '(' }
         parexpr; { parse expression }
         if nxttlk <> crparen then error(erpexp, ''); { ')' expected }
         gettlk; { skip '(' }
         if nxttlk <> cscn then error(escnexp, ''); { ';' expected }
         gettlk { skip ';' }

      end;
      cfor: begin { for (expression; expression; expression) statement }

         gettlk; { skip 'for' }
         if nxttlk <> clparen then error(elpexp, ''); { '(' expected }
         gettlk; { skip '(' }
         parexpr; { parse expression }
         if nxttlk <> cscn then error(escnexp, ''); { ';' expected }
         gettlk; { skip ';' }
         parexpr; { parse expression }
         if nxttlk <> cscn then error(escnexp, ''); { ';' expected }
         gettlk; { skip ';' }
         parexpr; { parse expression }
         if nxttlk <> crparen then error(erpexp, ''); { ')' expected }
         gettlk; { skip '(' }
         parstat { parse statement }

      end;
      cgoto: begin { goto identifier; }

         gettlk; { skip 'goto' }
         if nxttlk <> cidentifier then error(eidexp, ''); { identifier expected }
         gettlk; { skip id }
         if nxttlk <> cscn then error(escnexp, ''); { ';' expected }
         gettlk { skip ';' }

      end;
      ccontinue: begin { continue; }

         gettlk; { skip 'continue' }
         if nxttlk <> cscn then error(escnexp, ''); { ';' expected }
         gettlk { skip ';' }

      end;
      cbreak: begin { break; }

         gettlk; { skip 'break' }
         if nxttlk <> cscn then error(escnexp, ''); { ';' expected }
         gettlk { skip ';' }

      end;
      creturn: begin { return expression; }

         gettlk; { skip 'return' }
         if nxttlk <> cscn then parexpr; { parse return expression }
         if nxttlk <> cscn then error(escnexp, ''); { ';' expected }
         gettlk { skip ';' }

      end

   end else begin { default is expression; }

      if nxttlk <> cscn then parexpr; { parse expression }
      if nxttlk <> cscn then error(escnexp, ''); { ';' expected }
      gettlk { skip ';' }

   end

end;

{******************************************************************************

Parse struct, union or enum

Parses structures, unions and enum type constructs. Returns a type entry for
that construct.

******************************************************************************}

procedure parstrunienum(var tp: typptr);

var t:            tolken;
    sp, csp:      symptr;  { symbol pointer }
    enumc:        integer; { enumeration counter }
    tp1, tp2, lp: typptr;
    head, tail:   typptr;  { declarator list }
    dummy:        boolean;
    val:          integer; { expression return value }
    sc:           typflg;  { storage class }
    off:          integer; { record offset addressing }
    fldc:         integer; { field counter }
    moff:         integer; { maximum offset for union }
    malgn:        integer; { maximum align }

{ check padding required and add if so }

procedure genpad(rt, ft: typptr; var lp: typptr);

procedure padit(rt: typptr; var lp: typptr);

var fe: typptr; { field entry }
    sp: symptr; { symbol pointer }

{ coin symbol based on field counter }

procedure coinsym(var p: symptr);

var coinn: packed array [1..maxstr] of char; { coined name holder }
    tmp:   packed array [1..maxstr] of char; { holder for coined number }

begin

   copy(coinn, 'rf_pad_'); { place base of coined name }
   ints(tmp, fldc); { convert field number }
   cat(coinn, tmp); { add that to the end }
   getsym(p); { get a new symbol }
   copyp(p^.lab, coinn); { place symbol }
   p^.gen := true { set generated }

end;

begin

      lsttyp(fe, tfield); { get a field entry }
      if lp = nil then begin { place as root }

         if rt^.t = tstruct then rt^.strf := fe
         else rt^.unif := fe

      end else lp^.fldn := fe; { place as next }
      lp := fe; { set as new last }
      fe^.fldh := rt; { place head link }
      fe^.fldb := -1; { set number of bits }
      fe^.fldt := gtuchr; { set base type }
      fe^.fldts := nil; { clear preferred base type symbol }
      fe^.fldn := nil; { set no next }
      fe^.tfs := []; { set no storage class }
      fe^.size := gtuchr^.size; { set as base size }
      fe^.algn := gtuchr^.algn; { set alignment }
      coinsym(sp); { get an id for that }
      sp^.typ := fe; { link symbol to entry }
      if rt^.t = tstruct then begin { place to structure id list }

         sp^.next := rt^.strl; { push onto list }
         rt^.strl := sp

      end else begin { place to union id list }

         sp^.next := rt^.unil; { push onto list }
         rt^.unil := sp

      end;
      off := off+gtuchr^.size; { calculate running address }
      fldc := fldc+1 { count }

end;

begin

   { perform padding check and generate }
   while off mod ft^.algn <> 0 do padit(rt, lp)

end;

begin

   if fprtrle then writeln('parstrunienum:');
   tp := nil; { clear result } 
   t := nxttlk; { save tolken as type of object }
   gettlk; { skip 'struct'/'union'/'enum' }
   sp := nil; { clear symbol }
   if nxttlk = cidentifier then begin { there is an id }

      sp := gblsym(nxtlab, true); { find previous symbol }
      if sp = nil then begin { no previous, create symbol }

         plcsym(sp, true); { place as new symbol }
         sp^.typ := nil { set no type }

      end else tp := sp^.typ; { place type }
      gettlk { skip id }

   end;
   if tp = nil then begin

      { no previous definition, we set up an "abstract" entry with the
        final information not filled in. this information can be filled
        out in this routine, or another call. abstracts are why we have
        to be careful with type processing }
      case t of { type }

         cstruct: begin

            lsttyp(tp, tstruct); { get entry }
            tp^.strf := gtudf; { set leaves undefined }
            tp^.strl := nil;
            tp^.tfs := []; { set no storage class }
            tp^.size := 0 { set no size }

         end;
         cunion: begin

            lsttyp(tp, tunion); { get entry }
            tp^.unif := gtudf; { set leaves undefined }
            tp^.unil := nil;
            tp^.unit := nil;
            tp^.tfs := []; { set no storage class }
            tp^.size := 0 { set no size }
  
         end;
         cenum: begin

            lsttyp(tp, tenum); { get entry }
            tp^.enc := gtudf; { set leaves undefined }
            tp^.tfs := []; { set no storage class }
            tp^.size := intlen; { set size }
            tp^.algn := intalgn { set alignment }

         end

      end;
      if sp <> nil then sp^.typ := tp { link back to symbol }

   end;
   if nxttlk = cbegin then begin { sructure specification }

      gettlk; { skip begin }
      { now we are defining a type, so if there is not abstract, then
        it is a duplicate }
      case t of { type }

         cstruct: if tp^.strf <> gtudf then error(etyprdf, '');
         cunion:  if tp^.unif <> gtudf then error(etyprdf, '');
         cenum: if tp^.enc <> gtudf then error(etyprdf, '')

      end;
      if t = cenum then begin { enumerator }

         enumc := 0; { clear enumeration constant }
         lp := nil; { set no last enumerator }
         repeat

            { must be identifier }
            if nxttlk <> cidentifier then error(eidexp, '');
            define(sp, false); { define that symbol }
            lsttyp(tp1, tenme); { get next constant entry }
            if lp = nil then tp^.enc := tp1 { place as root }
            else lp^.enx := tp1; { place as link to last }
            sp^.typ := tp1; { link to symbol }
            tp1^.tfs := []; { clear storage class }
            tp1^.enh := tp; { set head entry }
            tp1^.env := enumc; { set constant }
            tp1^.enx := nil; { clear next }
            tp1^.size := intlen; { set size as int }
            tp1^.size := intalgn; { set alignment }
            lp := tp1; { set new last }
            enumc := enumc+1; { next constant }
            gettlk; { skip id }
            if nxttlk = cas then begin { = constant-expression }

               gettlk; { skip '=' }
               parcondexpr(true, val, dummy); { parse conditional-expression }
               enumc := val; { set assigned value }
               tp1^.env := enumc; { set constant }
               enumc := enumc+1 { next constant }

            end;
            t := nxttlk; { save next tolken }
            if nxttlk = ccma then gettlk { skip ',' }

         { allow nonstandard extra ',' on flag }
         until (t <> ccma) or ((nxttlk = cend) and fenecma)  { no more }

      end else begin { must be structure list }

         off := 0; { clear record offset }
         moff := 0; { clear maximum offset }
         malgn := 0; { clear maximum align }
         fldc := 1; { clear field count }
         lp := nil; { clear last field entry }
         repeat

            pardecspec(tp1, false, sc, csp); { parse specifier-qualifier-list }
            if sc <> tfnone then error(enostcl, ''); { no storage class }
            repeat

               if tp^.t = tunion then off := 0; { clear offset }
               if nxttlk = ccln then begin

                  { there is a bit spec only, this entry becomes an anonymous
                    bit pad. because it has no name, we coin an entry now }
                  gettlk; { skip ':' }
                  parcondexpr(true, val, dummy); { parse bit spec only }
                  if tp^.t = tstruct then { structure }
                     genpad(tp, tp1, lp); { perform padding check and generate }
                  lsttyp(tp2, tfield); { get a field entry }
                  if lp = nil then begin { place as root }

                     if tp^.t = tstruct then tp^.strf := tp2
                     else tp^.unif := tp2

                  end else lp^.fldn := tp2; { place as next }
                  lp := tp2; { set as new last }
                  tp2^.fldh := tp; { place head link }
                  tp2^.fldb := val; { set number of bits }
                  tp2^.fldt := tp1; { set base type }
                  tp2^.fldts := nil; { clear preferred base type symbol }
                  tp2^.fldn := nil; { set no next }
                  tp2^.tfs := []; { set no storage class }
                  tp2^.size := val div 8; { set number of bytes }
                  if val mod 8 > 0 then tp2^.size := tp2^.size+1; { round up }
                  off := off+tp2^.size; { calculate running address }
                  tp2^.algn := 1; { set byte alignment }
                  if off > moff then moff := off; { find maximum offset }
                  if tp2^.algn > malgn then 
                     malgn := tp2^.algn; { find maximum alignment }
                  fldc := fldc+1 { count }

               end else if (nxttlk  = cscn) and fuse then begin

                  { unnamed struct/union field, enter anonymous field.
                    this is a non-standard feature }
                  if tp^.t = tstruct then { structure }
                     genpad(tp, tp1, lp); { perform padding check and generate }
                  lsttyp(tp2, tfield); { get a field entry }
                  if lp = nil then begin { place as root }

                     if tp^.t = tstruct then tp^.strf := tp2
                     else tp^.unif := tp2

                  end else lp^.fldn := tp2; { place as next }
                  lp := tp2; { set as new last }
                  tp2^.fldh := tp; { place head link }
                  tp2^.fldb := -1; { flag no bitfield }
                  tp2^.fldt := tp1; { set base type }
                  tp2^.fldts := nil; { clear preferred base type symbol }
                  tp2^.fldn := nil; { set no next }
                  tp2^.tfs := []; { set no storage class }
                  tp2^.size := tp1^.size; { set number of bytes }
                  tp2^.algn := tp1^.algn; { set alignment }
                  off := off+tp2^.size; { calculate running address }
                  if off > moff then moff := off; { find maximum offset }
                  if tp2^.algn > malgn then 
                     malgn := tp2^.algn; { find maximum alignment }
                  fldc := fldc+1 { count }

               end else begin { declarator }

                  pardect(sp, head, tail, false, false); { parse declarator }
                  { if pardect has further type information, eliminate candiate
                    type name }
                  if head <> nil then csp := nil; 
                  jointype(head, tail, tp1, nil, nil); { place base type }
                  tp1 := head; { place head of list as new base type }
                  val := -1; { flag no bit width }
                  if nxttlk = ccln then begin

                     gettlk; { skip ':' }
                     parcondexpr(true, val, dummy) { parse bit spec only }

                  end;
                  if tp^.t = tstruct then { structure }
                     genpad(tp, tp1, lp); { perform padding check and generate }
                  lsttyp(tp2, tfield); { get a field entry }
                  if lp = nil then begin { place as root }

                     if tp^.t = tstruct then tp^.strf := tp2
                     else tp^.unif := tp2

                  end else lp^.fldn := tp2; { place as next }
                  lp := tp2; { set as new last }
                  tp2^.fldh := tp; { place head link }
                  tp2^.fldb := val; { set number of bits }
                  tp2^.fldt := tp1; { set base type }
                  tp2^.fldts := csp; { clear preferred base type symbol }
                  tp2^.fldn := nil; { set no next }
                  tp2^.tfs := []; { set no storage class }
                  tp2^.size := tp1^.size; { set as base size }
                  tp2^.algn := tp1^.algn; { set alignment }
                  sp^.typ := tp2; { link symbol to field entry }
                  if tp^.t = tstruct then begin { place to structure id list }

                     sp^.next := tp^.strl; { push onto list }
                     tp^.strl := sp

                  end else begin { place to union id list }

                     sp^.next := tp^.unil; { push onto list }
                     tp^.unil := sp

                  end;
                  off := off+tp2^.size; { calculate running address }
                  if off > moff then moff := off; { find maximum offset }
                  if tp2^.algn > malgn then 
                     malgn := tp2^.algn; { find maximum alignment }
                  fldc := fldc+1 { count }

               end;
               t := nxttlk; { save next tolken }
               if t = ccma then gettlk { skip ',' }

            until t <> ccma; { until not ',' }
            if nxttlk = cscn then gettlk { skip ';' }

         until nxttlk = cend; { until end }
         tp^.size := moff; { set size of record overall }
         tp^.algn := malgn; { set alignment of record overall }
         { the record gets rounded up to its alignment. I have no idea why this
           occurs, and needs to be verified that vc++ does this }
         if moff mod tp^.algn > 0 then 
            tp^.size := tp^.size-tp^.size mod tp^.algn+tp^.algn

      end;
      if nxttlk <> cend then error(eendexp, ''); { end expected }
      gettlk; { skip end }
      fixdrv(tp) { fixed derived types }

   end

end;

{******************************************************************************

Parse declaration-specifiers or specifier-qualifier list

Parses the delcaration-specifiers construct. Returns the base type as modified
by storage specifiers and type qualifiers.
If the storage specifier flag is on, parses the declaration-specifier
construct. If not, parses a specifier-qualifier list, which is the same thing
but without storage-class-specifiers.
Uses the rule that if an identifier is seen that has a complete type, and
we are already working on a complete type, the identifier is left alone.
Returns the storage class, which should only be used at top level defines.

******************************************************************************}

procedure pardecspec(var tp: typptr; stcl: boolean; var sc: typflg; 
                     var sp: symptr);

{ invalid combinations of types }

fixed invtyp: array [typflg] of typfst = array

{*** This set should not need anything in it, its a compiler bug !!! }
   { none     } [tfauto],
   { auto     } [tfauto, tfregister, tfstatic, tfextern, tftypedef],
   { register } [tfauto, tfregister, tfstatic, tfextern, tftypedef],
   { static   } [tfauto, tfregister, tfstatic, tfextern, tftypedef],
   { extern   } [tfauto, tfregister, tfstatic, tfextern, tftypedef],
   { typedef  } [tfauto, tfregister, tfstatic, tfextern, tftypedef],
   { const    } [tfconst],
   { volatile } [tfvolatile],
   { void     } [tfvoid, tfchar, tfshort, tfint, tflong, tffloat, tfdouble,
                 tfsigned, tfunsigned],
   { char     } [tfvoid, tfchar, tfshort, tfint, tflong, tffloat, tfdouble],
   { short    } [tfvoid, tfchar, tfshort, tflong, tffloat, tfdouble],
   { int      } [tfvoid, tfchar, tfint, tffloat, tfdouble],
   { long     } [tfvoid, tfchar, tfshort, tflong, tffloat],
   { float    } [tfvoid, tfchar, tfshort, tfint, tflong, tffloat, tfdouble,
                 tfsigned, tfunsigned],
   { double   } [tfvoid, tfchar, tfshort, tfint, tffloat, tfdouble, tfsigned,
                 tfunsigned],
   { signed   } [tfvoid, tffloat, tfdouble, tfsigned, tfunsigned],
   { unsigned } [tfvoid, tffloat, tfdouble, tfsigned, tfunsigned]

end;

var cont: boolean; { continue flag }
    tp1:  typptr;  { type pointer }
    tfs:  typfst;  { type flags }
    tf:   typflg;  { type flag holder }

{
procedure setout(tfs: typfst);

var tf: typflg;

begin

   for tf := tfauto to tfunsigned do if tf in tfs then write('1') else write('0')

end;
}

begin

   if fprtrle then writeln('pardecspec:');
   tfs := []; { clear all type flags }
   tp := nil; { clear type }
   sp := nil; { clear candidate name }
   repeat { type leader }

      { register simple type flags }
      if (nxttlk in [cconst, cvolatile, cvoid, cchar, cshort, cint, clong,
                    cfloat, cdouble, csigned, cunsigned]) or
         (nxttlk in [cauto, cregister, cstatic, cextern, ctypedef]) and stcl then
         begin

         { convert tolken to type flag }
         case nxttlk of { tolken }
        
            cauto:     tf := tfauto;    
            cregister: tf := tfregister;
            cstatic:   tf := tfstatic;  
            cextern:   tf := tfextern;  
            ctypedef:  tf := tftypedef; 
            cconst:    tf := tfconst;   
            cvolatile: tf := tfvolatile;
            cvoid:     tf := tfvoid;    
            cchar:     tf := tfchar;    
            cshort:    tf := tfshort;   
            cint:      tf := tfint;     
            clong:     tf := tflong;    
            cfloat:    tf := tffloat;   
            cdouble:   tf := tfdouble;  
            csigned:   tf := tfsigned;  
            cunsigned: tf := tfunsigned

         end;
         gettlk; { skip tolken }
         { check invalid type combination }
         if invtyp[tf]*tfs <> [] then error(einvtpc, '');
         { also check type entry if it exists }
         if tp <> nil then if invtyp[tf]*tfs <> [] then error(einvtpc, '');
         tfs := tfs+[tf] { place new type flag }
  
      end else if nxttlk in [cstruct, cunion, cenum] then begin

         { structured type }
         if tp <> nil then error(etypdup, ''); { already have a structured type }
         parstrunienum(tp); { structure, union or enum }

      end else if nxttlk = cidentifier then begin { type id }

         if tp <> nil then error(etypdup, ''); { already have a structured type }
         sp := gblsym(nxtlab, false); { find symbol }
         if sp = nil then error(esymnf, ''); { not found }
         gettlk; { skip id }
         tp := sp^.typ; { get type }
         if tp = nil then error(esys5, ''); { should have a type }
         { check is a type id }
         if not (tp^.t in [tvoid, tint, tfloat, tptr, tenum, tarray, tstruct,
                           tunion, tfunc]) then error(etidexp, ''); { not type id }
         { check conflicts with existing type flags }
         for tf := tfauto to tfunsigned do if tf in tp^.tfs then
            if invtyp[tf]*tfs <> [] then error(einvtpc, '')

      end else error(einvtyp, ''); { no type element found }
      { find if another declaration-specifier follows }
      cont := false; { set no continue }
      { check tolken indicators, all but identifier }
      if nxttlk in decspecld-[cidentifier] then cont := true;
      { check identifier, and not already working with a full type }
      if (nxttlk = cidentifier) and (tp = nil) then begin

         { now we have to be careful. not only must the follow id be a valid
           type id, but it must not conflict with our type information gathered
           so far. If it does, we don't continue, but leave the id to be parsed
           later. this rule is important because type ids can be redefined }
         sp := gblsym(nxtlab, false); { find symbol }
         if sp <> nil then begin { there is a symbol }

            if sp^.typ = nil then error(esys6, ''); { should have a type }
            { check is a type id }
            if (sp^.typ^.t in [tvoid, tint, tfloat, tptr, tenum, tarray, tstruct,
                              tunion]) or
               { functions are used like types, but only in a typedef }
               ((sp^.typ^.t = tfunc) and (tftypedef in tfs)) then begin 

               { its a type }
               tp1 := sp^.typ; { get type }
               if tp1 = nil then error(esys7, ''); { should have a type }
               cont := true; { lets assume we can do it }
               { check flags indicate full type, since this is a type entry }
               if tfs*[tfvoid, tfchar, tfint, tffloat, tfdouble] <> [] then 
                  cont := false;
               { check conflicts with existing type flags }
               for tf := tfauto to tfunsigned do if tf in tp1^.tfs then
                  if invtyp[tf]*tfs <> [] then cont := false

            end

         end;
         sp := nil { clear candidate }

      end

   until not cont;
   if tp = nil then begin

      { set default integer if no type }
      if [tfvoid, tfchar, tfint, tffloat, tfdouble]*tfs = [] then 
         tfs := tfs+[tfint];                  
      { classify entry into one of several predefined slot types }
      if [tfconst, tfvolatile, tfvoid] <= tfs then tp := gtcvvoid
      else if [tfconst, tfvoid] <= tfs then tp := gtcvoid
      else if [tfvolatile, tfvoid] <= tfs then tp := gtvvoid
      else if [tfvoid] <= tfs then tp := gtvoid

      else if [tfconst, tfvolatile, tffloat] <= tfs then tp := gtcvflt
      else if [tfconst, tffloat] <= tfs then tp := gtcflt
      else if [tfvolatile, tffloat] <= tfs then tp := gtvflt
      else if [tffloat] <= tfs then tp := gtflt

      else if [tfconst, tfvolatile, tfdouble, tflong] <= tfs then tp := gtcvldbl
      else if [tfconst, tfdouble, tflong] <= tfs then tp := gtcldbl
      else if [tfvolatile, tfdouble, tflong] <= tfs then tp := gtvldbl
      else if [tfdouble, tflong] <= tfs then tp := gtldbl

      else if [tfconst, tfvolatile, tfdouble] <= tfs then tp := gtcvdbl
      else if [tfconst, tfdouble] <= tfs then tp := gtcdbl
      else if [tfvolatile, tfdouble] <= tfs then tp := gtvdbl
      else if [tfdouble] <= tfs then tp := gtdbl

      else if [tfconst, tfvolatile, tfsigned, tfshort, tfint] <= tfs then 
         tp := gtcvssint
      else if [tfconst, tfsigned, tfshort, tfint] <= tfs then tp := gtcssint
      else if [tfvolatile, tfsigned, tfshort, tfint] <= tfs then tp := gtvssint
      else if [tfsigned, tfshort, tfint] <= tfs then tp := gtssint

      else if [tfconst, tfvolatile, tfunsigned, tfshort, tfint] <= tfs then 
         tp := gtcvusint
      else if [tfconst, tfunsigned, tfshort, tfint] <= tfs then tp := gtcusint
      else if [tfvolatile, tfunsigned, tfshort, tfint] <= tfs then 
         tp := gtvusint
      else if [tfunsigned, tfshort, tfint] <= tfs then tp := gtusint

      else if [tfconst, tfvolatile, tfshort, tfint] <= tfs then tp := gtcvshint
      else if [tfconst, tfshort, tfint] <= tfs then tp := gtcshint
      else if [tfvolatile, tfshort, tfint] <= tfs then tp := gtvshint
      else if [tfshort, tfint] <= tfs then tp := gtshint

      else if [tfconst, tfvolatile, tfsigned, tflong, tfint] <= tfs then 
         tp := gtcvslint
      else if [tfconst, tfsigned, tflong, tfint] <= tfs then tp := gtcslint
      else if [tfvolatile, tfsigned, tflong, tfint] <= tfs then tp := gtvslint
      else if [tfsigned, tflong, tfint] <= tfs then tp := gtslint

      else if [tfconst, tfvolatile, tfunsigned, tflong, tfint] <= tfs then 
         tp := gtcvulint
      else if [tfconst, tfunsigned, tflong, tfint] <= tfs then tp := gtculint
      else if [tfvolatile, tfunsigned, tflong, tfint] <= tfs then tp := gtvulint
      else if [tfunsigned, tflong, tfint] <= tfs then tp := gtulint

      else if [tfconst, tfvolatile, tflong, tfint] <= tfs then tp := gtcvlint
      else if [tfconst, tflong, tfint] <= tfs then tp := gtclint
      else if [tfvolatile, tflong, tfint] <= tfs then tp := gtvlint
      else if [tflong, tfint] <= tfs then tp := gtlint

      else if [tfconst, tfvolatile, tfsigned, tfchar] <= tfs then tp := gtcvschr
      else if [tfconst, tfsigned, tfchar] <= tfs then tp := gtcschr
      else if [tfvolatile, tfsigned, tfchar] <= tfs then tp := gtvschr
      else if [tfsigned, tfchar] <= tfs then tp := gtschr

      else if [tfconst, tfvolatile, tfunsigned, tfchar] <= tfs then 
         tp := gtcvuchr
      else if [tfconst, tfunsigned, tfchar] <= tfs then tp := gtcuchr
      else if [tfvolatile, tfunsigned, tfchar] <= tfs then tp := gtvuchr
      else if [tfunsigned, tfchar] <= tfs then tp := gtuchr

      else if [tfconst, tfvolatile, tfchar] <= tfs then tp := gtcvchr
      else if [tfconst, tfchar] <= tfs then tp := gtcchr
      else if [tfvolatile, tfchar] <= tfs then tp := gtvchr
      else if [tfchar] <= tfs then tp := gtchr

      else if [tfconst, tfvolatile, tfsigned, tfint] <= tfs then tp := gtcvsint
      else if [tfconst, tfsigned, tfint] <= tfs then tp := gtcsint
      else if [tfvolatile, tfsigned, tfint] <= tfs then tp := gtvsint
      else if [tfsigned, tfint] <= tfs then tp := gtsint

      else if [tfconst, tfvolatile, tfunsigned, tfint] <= tfs then tp := gtcvuint
      else if [tfconst, tfunsigned, tfint] <= tfs then tp := gtcuint
      else if [tfvolatile, tfunsigned, tfint] <= tfs then tp := gtvuint
      else if [tfunsigned, tfint] <= tfs then tp := gtuint

      else if [tfconst, tfvolatile, tfint] <= tfs then tp := gtcvint
      else if [tfconst, tfint] <= tfs then tp := gtcint
      else if [tfvolatile, tfint] <= tfs then tp := gtvint
      else if [tfint] <= tfs then tp := gtint
      else error(esys8, '') { should have been one of those }

   end else begin { combining types and flags }

      { if anything but a const or volatile attribute is being added to
        an existing type, flag an error }
      if tfs-(sctypflg+[tfconst, tfvolatile]) <> [] then error(einvtpc, '');
      { flag const or volatile duplicates }
      if (tfconst in tfs) and (tfconst in tp^.tfs) then error(ecstdup, '');
      if (tfvolatile in tfs) and (tfvolatile in tp^.tfs) then 
         error(evoldup, '');
      { check const or volatile being added, duplicate type }
      if [tfconst, tfvolatile]*tfs <> [] then begin

         { there was a type entry, but the flags gathered here extend that.
           so we make a new type entry that is a copy of the existing entry, and
           add the flags to that. }
         copytype(tp1, tp); { copy }
         tp1^.tfs := tp1^.tfs+tfs; { add in discrete flags }
         { set the type we copied from as the derived from type. if that type
           was itself derived, then link to the original deriver. that keeps the
           level only one deep. the derived type is used to fix dangling struct
           references }
         if tp^.drv = nil then tp1^.drv := tp else tp1^.drv := tp^.drv;
         tp := tp1; { return that }
         sp := nil { clear candidate }

      end

   end;
   { extract the storage class }
   sc := tfnone; { set no storage class }
   if tfauto in tfs then sc := tfauto
   else if tfregister in tfs then sc := tfregister
   else if tfstatic in tfs then sc := tfstatic
   else if tfextern in tfs then sc := tfextern
   else if tftypedef in tfs then sc := tftypedef;
   tp^.tfs := tp^.tfs-sctypflg { remove storage class flags from entry }
   
end;

{******************************************************************************

Parse function/array declare list

Parses a series of [] and () declaration lists. Returns a head of the list,
and a tail of the list. The list is processed to the right, that is, the
leftmost type is the head of the list, and the rightmost is the bottom of the
list. The list is processed recursively to do this.

******************************************************************************}

procedure parfuncarr(var head, tail: typptr; abs: boolean);

var nhead, ntail:     typptr;  { side list pointers }
    val:              integer; { expression return value }
    tp, tp1, tp2, lp: typptr;  { type pointers }
    sp, lsp, csp:     symptr;  { symbol pointer }
    fndnam:           boolean; { found parameter name flag }
    t:                tolken;  { next tolken save }
    voidl:            boolean; { parameter list is void }
    dummy:            boolean;
    sc:               typflg;  { storage class }

begin

   if fprtrle then writeln('parfuncarr:');
   head := nil; { clear list head and tail }
   tail := nil;
   if nxttlk = clbrkt then begin { [ conditional-expression ] }

      val := -1; { flag no length on array }
      gettlk; { skip '[' }
      if nxttlk <> crbrkt then
         parcondexpr(true, val, dummy); { parse conditional-expression }
      if nxttlk <> crbrkt then error(erbktexp, ''); { ']' expected }
      gettlk; { skip ']' }
      lsttyp(tp, tarray); { get an array entry }
      tp^.tfs := []; { set no storage class specifier }
      tp^.arrt := nil; { clear base type }
      tp^.arrts := nil; { clear preferrred base type symbol }
      tp^.arre := val; { set number of elements }
      head := tp; { set as single element list }
      tail := tp;
      tp^.size := 0; { set no length by default (unsized array) }
      { recursively join any additional lists to the end of this }
      if nxttlk in [clparen, clbrkt] then begin { theres more }

         parfuncarr(nhead, ntail, abs); { get the rest of list }
         if nhead = nil then error(esys9, ''); { should be at least one element }
         { check attempt to form array of functions }
         if nhead^.t = tfunc then error(earrfnc, '');
         jointype(head, tail, nhead, ntail, nil) { add to the end of our list }

      end

   end else if nxttlk = clparen then begin { ( id or function params ) }

      gettlk; { skip '(' }
      { it is possible to define named types during a parameter list. Such
        symbols have no real scope, and are purged }
      level := level+1; { start a new scope }
      lsttyp(tp, tfunc); { get an array entry }
      tp^.tfs := []; { set no storage class specifier }
      tp^.fncp := nil; { clear parameter list }
      tp^.fncv := false; { set not variable length }
      tp^.fncr := nil; { clear result type }
      tp^.fncrs := nil; { clear preferred result symbol }
      tp^.fncrps := nil; { clear replacement strings }
      tp^.fncras := nil;
      tp^.fncrno := nil; { clear reference override }
      tp^.size := 0; { set no size on function }
      lp := nil; { set no last parameter }
      lsp := nil; { set no last symbol }
      if nxttlk <> crparen then begin { parameters }

         { there are two completely different list types. the first is a formal
           declared list, ANSI style. the second is a typeless name list, which
           has the types appearing later, original C style. The old style can
           be determined here by an id that is either undeclared, or is global
           as other than a typedef, and locally undeclared. the list types
           mutually exclusive }
         fndnam := false; { set no parameter name sequence found }
         if nxttlk = cidentifier then begin { check for parameter id }

            sp := gblsym(nxtlab, false); { find any symbol }
            if sp = nil then fndnam := true { is a non-type id }
            else if sp^.typ^.t in [tvar, tfunci] then fndnam := true

         end;
         if fndnam then repeat { process as name list }

            if nxttlk <> cidentifier then error(eidexp, ''); { must be id }
            lodsym(sp); { load that into a symbol }
            gettlk; { skip id }
            if lsp = nil then tp^.fncl := sp { link symbol as head }
            else lsp^.next := sp; { link symbol as next }
            lsp := sp; { set new last }
            lsttyp(tp2, tpar); { get a parameter entry }
            tp2^.tfs := []; { set no storage class specifier }
            tp2^.part := nil; { set no base type }
            tp2^.parts := nil; { clear possible base symbol }
            tp2^.parh := tp; { set head }
            tp2^.parps := nil; { set strings to nil }
            tp2^.paras := nil;
            tp2^.partps := nil;
            tp2^.partas := nil;
            tp2^.pareld := false;
            tp2^.pareas := nil;
            tp2^.size := 0; { set no size }
            tp2^.next := nil; { clear next }
            sp^.typ := tp2; { link to symbol }
            if lp = nil then tp^.fncp := tp2 { set 1st parameter }
            else lp^.parn := tp2; { else link to this }
            lp := tp2; { set new last }
            t := nxttlk; { save next }
            if nxttlk = ccma then begin { there is a ',' }

               gettlk; { skip ',' }
               if nxttlk = cconts then begin { its '...' }

                  gettlk; { skip '...' }
                  tp^.fncv := true; { set variable length }
                  t := cundefined { kill ',' }

               end

            end
            
         until t <> ccma { until not ',' }
         else repeat

            pardecspec(tp1, true, sc, csp); { parse declaration-specifiers }
            if sc <> tfnone then error(enostcl, ''); { no storage class }
            { check is comletely void parameter list }
            voidl := (tp1^.t = tvoid) and (nxttlk = crparen);
            if nxttlk in [ccma, crparen] then begin { no declarator  }

               sp := nil; { set no symbol }
               nhead := tp1 { set type is base type }

            end else begin { declarator exists }

               { parse delcarator with no preference }
               pardect(sp, nhead, ntail, false, true);
               { if pardect has further type information, eliminate candiate
                 type name }
               if nhead <> nil then csp := nil; 
               jointype(nhead, ntail, tp1, nil, nil); { merge entry to list end }
               if lsp = nil then tp^.fncl := sp { link symbol as head }
               else lsp^.next := sp; { link symbol as next }
               lsp := sp { set new last }

            end;
            if not voidl then begin { create a parameter }

               lsttyp(tp2, tpar); { get a parameter entry }
               tp2^.tfs := []; { set no storage class specifier }
               tp2^.part := nhead; { set base type }
               tp2^.parts := csp; { set possible base symbol }
               tp2^.parh := tp; { set head }
               tp2^.parps := nil; { set strings to nil }
               tp2^.paras := nil;
               tp2^.partps := nil;
               tp2^.partas := nil;
               tp2^.pareld := false;
               tp2^.pareas := nil;
               tp2^.size := nhead^.size; { set size as base }
               tp2^.algn := nhead^.algn; { set alignment }
               if sp <> nil then sp^.typ := tp2; { link to symbol }
               if lp = nil then tp^.fncp := tp2 { set 1st parameter }
               else lp^.parn := tp2; { else link to this }
               lp := tp2 { set new last }

            end;
            t := nxttlk; { save next }
            if nxttlk = ccma then begin { there is a ',' }

               gettlk; { skip ',' }
               if nxttlk = cconts then begin { its '...' }

                  gettlk; { skip '...' }
                  tp^.fncv := true; { set variable length }
                  t := cundefined { kill ',' }

               end

            end

         until t <> ccma; { until not ',' }

      end;
      if nxttlk <> crparen then error(erpexp, ''); { ')' expected }
      gettlk; { skip ')' }
      purge; { remove any symbols entered }
      level := level-1; { back out that level }
      head := tp; { set as single element list }
      tail := tp;
      { recursively join any additional lists to the end of this }
      if nxttlk in [clparen, clbrkt] then begin { theres more }

         parfuncarr(nhead, ntail, abs); { get the rest of list }
         if nhead = nil then error(esys10, ''); { should be at least one element }
         { check attempt to form array of functions }
         if nhead^.t = tfunc then error(efncfnc, '');
         jointype(head, tail, nhead, ntail, nil) { add to the end of our list }

      end

   end

end;

{******************************************************************************

Parse declarator

Parse the declarator construct. Declarators can be direct or abstract. In the
abstract case, no type name appears. A abs flag is passed that restricts the
routine to abstract declaration only.
Returns a symbol pointer, and a type list represented by its head and tail.
A nil list is possible, if only an id was declared with no supporting type.
The general procedure to create a declaration is as follows. The type list is
first built with any pointer references at the left of the declaration id.
These appear leftmost at the bottom of the list, with the declaration closest
to the id at the head. Next, if an id appears, any array or function specifiers
to the right are parsed into a new list with the rightmost appearing at the
tail of the list (the opposite of pointer specifications), and the topmost
being the element closest to the id. That list is then merged with any pointer
references at the bottom of the array/function list.
If a (declarator) appears instead of the id, it is recursively parsed for its
sublist and symbol, and the array or function specifiers yet another list after
that. These lists are joined with the (declarator) list at the top, followed
by the array/function list. Finally, the pointer list is added to the bottom
of the array/function list.

Pardect does not return a complete type. The base must be determined and
placed, typically from a partypespec call, into the tail entry before the type
is complete.

******************************************************************************}

procedure pardect(var sp: symptr; var head, tail: typptr; abs, cabs: boolean);

var tp:    typptr;
    nhead, ntail, nhead2, ntail2: typptr;

begin

   if fprtrle then writeln('pardect:');
   head := nil; { clear list head and tail }
   tail := nil;
   sp := nil; { clear symbol }
   while nxttlk = ctimes do begin { pointer declaration }

      gettlk; { skip '*' }
      lsttyp(tp, tptr); { get a pointer entry }
      tp^.tfs := []; { set no storage class specifier }
      tp^.size := ptrlen; { set size }
      tp^.algn := ptralgn; { set alignment }
      tp^.ptrt := head; { set base }
      tp^.ptrts := nil; { set no preferred symbol }
      while nxttlk in [cconst, cvolatile] do begin

         if nxttlk = cconst then begin

            if tfconst in tp^.tfs then error(ecstdup, '')

         end else begin

            if tfvolatile in tp^.tfs then error(evoldup, '');

         end;
         gettlk { skip type-qualifiers } 

      end;
      if tail = nil then tail := tp; { set tail if none }
      head := tp { set head }

   end;
   if nxttlk = cidentifier then begin { id }

      if abs then error(eabsdec, ''); { bad abstract declarator }
      if nxttlk <> cidentifier then error(eidexp, ''); { id expected }
      lodsym(sp); { load that into a symbol }
      gettlk; { skip id }
      parfuncarr(nhead, ntail, abs); { parse function/array declarator list }
      jointype(nhead, ntail, head, tail, nil); { join the lists }
      head := nhead; { index that as new list }
      tail := ntail

   end else if (nxttlk = clparen) or (not abs and not cabs) then begin

      { must be (declarator) }
      if nxttlk <> clparen then error(elpidexp, ''); { '(' or id expected }
      gettlk; { skip '(' }
      pardect(sp, nhead, ntail, abs, true); { parse subdeclarator }
      if nxttlk <> crparen then error(erpexp, ''); { ')' expected }
      gettlk; { ')' }
      parfuncarr(nhead2, ntail2, abs); { parse function/array declarator list }
      { place that list on end of declarator list }
      jointype(nhead, ntail, nhead2, ntail2, nil);
      jointype(nhead, ntail, head, tail, nil); { join base list to end of all that }
      head := nhead; { index that as new list }
      tail := ntail

   end

end;

{******************************************************************************

Parse initalizer

Parse the initalizer construct.

******************************************************************************}

procedure parinit;

var t: tolken;

begin

   if fprtrle then writeln('parinit:');
   if nxttlk = cbegin then begin { begin init end }

      gettlk; { skip begin }
      repeat { initalizers }

         parinit; { parse initalizer }
         t := nxttlk; { save next tolken }
         if nxttlk = ccma then gettlk { skip }

      until (t <> ccma) or (nxttlk = cend);
      if nxttlk <> cend then error(eendexp, ''); { should be end }
      gettlk { skip end }

   end else parassexpr { parse assignment expression }

end;

{******************************************************************************

Parse delcaration

Parse the declaration construct.

******************************************************************************}

procedure pardecl;

var t:          tolken; { next tolken save }
    tp, tp1:    typptr; { type pointer }
    head, tail: typptr; { type list }
    sp, csp:    symptr; { symbol pointer }
    sc:         typflg; { storage class }

begin

   if fprtrle then writeln('pardecl:');
   pardecspec(tp, true, sc, csp); { parse declaration-specifiers }
   repeat { declarators }

      pardect(sp, head, tail, false, false); { parse standard declarator }
      newsym(sp, false); { place label in symbol table }
      jointype(head, tail, tp, nil, csp); { merge entry to list end }
      { check if simple typedef, and pin the symbol to it if so }
      if sc = tftypedef then sp^.typ := head { link to symbol }
      else begin { variable at top level, must be static or extern }

         lsttyp(tp1, tvar); { get entry }
         tp1^.tfs := head^.tfs; { set storage class }
         tp1^.vart := head; { set base type }
         tp1^.size := head^.size; { set size }
         tp1^.algn := head^.algn; { set alignment }
         tp1^.varc := nil; { set no initalization }
         sp^.typ := tp1; { place symbol linkage }

      end;
      if nxttlk = cas then begin { there is initalization }

         gettlk; { skip '=' }
         parinit { parse initalizer }

      end;
      t := nxttlk; { save next }
      if nxttlk = ccma then gettlk { get next }

   until t <> ccma; { no more declarations }
   if nxttlk <> cscn then error(escnexp, ''); { ';' expected }
   gettlk { skip ';' }

end;

{******************************************************************************

Parse parameter declarations

Parses parameter declarations. These are declarations in old style C designed
to assign types to existing parameters. Accepts the head pointer to the
function. As each declaration is processed, the matching declaration from the
list is found, and that is then typed.

******************************************************************************}

procedure pardecp(fp: typptr);

var t:                  tolken; { next tolken save }
    tp, tp1:            typptr; { type pointer }
    head, tail:         typptr; { type list }
    sp, sp1, csp, csp1: symptr; { symbol pointers }
    sc:                 typflg; { storage class }

{ find function parameter by name }

procedure fndlab(view s: string; var fs: symptr);

var p: symptr; { pointer for symbols }

begin

   p := fp^.fncl; { index top of parameter list }
   fs := nil; { clear found symbol }
   while p <> nil do begin { traverse }

      if compcp(p^.lab^, s) then fs := p; { found, set }
      p := p^.next { next symbol }

   end

end;

begin

   if fprtrle then writeln('pardecp:');
   pardecspec(tp, true, sc, csp); { parse declaration-specifiers }
   if sc <> tfnone then error(enostcl, ''); { no storage class }
   repeat { declarators }

      csp1 := csp; { set original candidate name }
      pardect(sp, head, tail, false, false); { parse standard declarator }
      { if pardect has further type information, eliminate candiate
        type name }
      if head <> nil then csp1 := nil; 
      fndlab(sp^.lab^, sp1); { find matching parameter label }
      if sp1 = nil then error(eparsnf, ''); { no matching parameter symbol }
      if sp1^.typ = nil then error(esys11, ''); { should have tpar entry }
      if sp1^.typ^.t <> tpar then error(esys12, '');
      if sp1^.typ^.part <> nil then error(epardtp, ''); { parameter has duplicate type }
      jointype(head, tail, tp, nil, nil); { merge entry to list end }
      lsttyp(tp1, tpar); { get entry }
      tp1^.tfs := head^.tfs; { set storage class }
      tp1^.part := head; { set base type }
      tp1^.parts := csp1; { set possible base symbol }
      tp1^.size := head^.size; { set size }
      tp1^.algn := head^.algn; { set alignment }
      sp1^.typ := head; { place symbol linkage }
      if nxttlk = cas then error(eparini, ''); { cannot initalize parameter }
      t := nxttlk; { save next }
      if nxttlk = ccma then gettlk { get next }

   until t <> ccma; { no more declarations }
   if nxttlk <> cscn then error(escnexp, ''); { ';' expected }
   gettlk { skip ';' }

end;

{******************************************************************************

Parse translation unit

Parse the translation-unit construct.

******************************************************************************}

procedure partrans;

var t:            tolken;
    tp:           typptr; { type pointer }
    head, tail:   typptr; { type list }
    sp, csp, asp: symptr; { symbol pointer }
    psp:          symptr; { previous symbol pointer }
    sc:           typflg; { storage class }

begin

   if fprtrle then writeln('partrans:');
   repeat

      tp := nil; { set no declaration type }
      csp := nil; { set no candidate symbol }
      { parse declaration specifier }
      if declead then pardecspec(tp, true, sc, csp);
      if nxttlk = cscn then gettlk { there is no declaration }
      else begin { declaration }

         asp := csp; { set alias symbol }
         { parse delcarator with no preference }
         pardect(sp, head, tail, false, false);
         if head <> nil then asp := nil; { set no alias symbol }
         { the leaders of a standard declaration and a function declaration are
           identical to this point. now we rely on the next tolkens of a
           standard declaration to break them apart }
         if nxttlk in [cas, ccma, cscn] then begin { its a standard declaration }

            if tp = nil then error(edattyp, ''); { must have type for this }
            jointype(head, tail, tp, nil, csp); { merge entry to list end }
            { check is already defined }
            psp := gblsym(sp^.lab^, false); { search for previous }
            if psp <> nil then begin

               { check it is var redefine, I am not going to do that just yet }
               if psp^.typ^.t = tvar then error(edupsym, psp^.lab^);
               { already a symbol, now it has to match the other definition in
                 in type exactly }
               if not comptype(head, psp^.typ) then error(etypmch, psp^.lab^);
               head := psp^.typ { dump new list and use old (labeled) list }
               
            end else newsym(sp, false); { place label in symbol table }
            { check 'auto' or 'register' used on top level declaration }
            if [tfauto, tfregister]*head^.tfs <> [] then error(einvcls, '');
            { check extern function declaration }
            if (head^.t = tfunc) and (sc <> tftypedef) then begin

               if nxttlk <> cscn then error(escnexp, ''); { must be ';' }
               head^.tfs := head^.tfs+[tfextern]; { set as extern }
               sp^.typ := head { link to symbol }

            end else
               { check if simple typedef, and pin the symbol to it if so }
               if sc = tftypedef then begin

                  sp^.typ := head; { link to symbol }
                  sp^.asym := asp { place possible alias symbol }

            end else begin { variable at top level, must be static or extern }

               lsttyp(tp, tvar); { get entry }
               tp^.tfs := head^.tfs; { set storage class }
               tp^.vart := head; { set base type }
               tp^.size := head^.size; { set size }
               tp^.algn := head^.algn; { set alignment }
               tp^.varc := nil; { set no initalization }
               sp^.typ := tp { place symbol linkage }

            end;
            repeat

               if nxttlk = cas then begin { there is initalization }

                  gettlk; { skip '=' }
                  parinit { parse initalizer }

               end;
               t := nxttlk; { save next }
               if nxttlk = ccma then begin

                  gettlk; { get next }
                  asp := csp; { set alias symbol }
                  { parse delcarator with no preference }
                  pardect(sp, head, tail, false, false);
                  if head <> nil then asp := nil; { set no alias symbol }
                  jointype(head, tail, tp, nil, csp); { merge entry to list end }
                  { check is already defined }
                  psp := gblsym(sp^.lab^, false); { search for previous }
                  if psp <> nil then begin
                  
                     { check it is var redefine, I am not going to do that just yet }
                     if psp^.typ^.t = tvar then error(edupsym, psp^.lab^);
                     { already a symbol, now it has to match the other definition in
                       in type exactly }
                     if not comptype(head, psp^.typ) then error(etypmch, psp^.lab^);
                     head := psp^.typ { dump new list and use old (labeled) list }
                     
                  end else newsym(sp, false); { place label in symbol table }
                  { check 'auto' or 'register' used on top level declaration }
                  if [tfauto, tfregister]*head^.tfs <> [] then
                     error(einvcls, '');
                  { check if simple typedef, and pin the symbol to it if so }
                  if sc = tftypedef then begin

                     sp^.typ := head; { link to symbol }
                     sp^.asym := asp { place possible alias symbol }

                  end else begin 

                     { variable at top level, must be static or extern }
                     lsttyp(tp, tvar); { get entry }
                     tp^.tfs := head^.tfs; { set storage class }
                     tp^.vart := head; { set base type }
                     tp^.size := head^.size; { set size }
                     tp^.algn := head^.algn; { set alignment }
                     tp^.varc := nil; { set no initalization }
                     sp^.typ := tp { place symbol linkage }
                  
                  end

               end

            until t <> ccma; { no more declarations }
            if nxttlk <> cscn then error(escnexp, ''); { ';' expected }
            gettlk { skip ';' }

         end else begin { function declaration }

            if tp = nil then tp := gtint; { if typeless, default to 'int' }
            jointype(head, tail, tp, nil, csp); { merge entry to list end }
            { check is a function instance of an earlier definition }
            psp := gblsym(sp^.lab^, false); { search for previous }
            if psp <> nil then begin { check for function }

               if psp^.typ = nil then error(esys44, ''); { should have a type }
               if psp^.typ^.t <> tfunc then error(edupsym, sp^.lab^);
               { remove extern }
               psp^.typ^.tfs := psp^.typ^.tfs-[tfextern];
               { check functions are congruent }
               if not comptype(head, psp^.typ) then error(etypmch, psp^.lab^);
               head := psp^.typ { dump new list and use old (labeled) list }
            
            end else newsym(sp, false); { place label in symbol table }
            if head^.t <> tfunc then error(efncexp, ''); { function expected }
            lsttyp(tp, tfunci); { get entry }
            tp^.tfs := head^.tfs; { set storage class }
            tp^.fnit := head; { set base type }
            tp^.size := head^.size; { set size }
            tp^.algn := head^.algn; { set alignment }
            sp^.typ := tp; { place symbol linkage }
            while nxttlk <> cbegin do pardecp(head); { parse declarations }
            gettlk; { skip begin }
            { check all parameters have types assigned, and default to integer
              if none }
            tp := head^.fncp; { index start of parameter list }
            while tp <> nil do begin { traverse }

               if tp^.t <> tpar then error(esys13, ''); { bad type }
               if tp^.part = nil then tp^.part := gtint; { place integer type }
               tp := tp^.parn { link next }

            end;
            bgnblk; { start block }
            while declead do pardecl; { parse any declarations }
            while nxttlk <> cend do parstat; { parse statements }
            gettlk; { skip end }
            alphasym; { rip and form alpha list }
            listtyp; { list types in block }
            listsym; { list and remove symbols }
            endblk { remove block }

         end

      end

   until nxttlk = ceof { until end of file } 

end;

begin

   fprtrle := false; { set no print parsing rules }
   fuse := false; { allow unnamed structure elements }
   fmsasm := false; { allow Microsoft asm constructs }
   fenecma := false; { allow extra enumerator comment }
   fduptyp := false; { allow type duplication }

   bgnblk; { start new block }

   { create global entries to lessen type traffic }

   { standard }

   lsttyp(gtudf, tudf);
   gtudf^.tfs := [];
   gtudf^.size := 0;

   lsttyp(gtvoid, tvoid);
   gtvoid^.tfs := [tfvoid];
   gtvoid^.size := voidlen;
   gtvoid^.algn := voidalgn;

   lsttyp(gtint, tint);
   gtint^.tfs := [tfint];
   gtint^.size := intlen;
   gtint^.algn := intalgn;

   lsttyp(gtsint, tint);
   gtsint^.tfs := [tfsigned, tfint];
   gtsint^.size := intlen;
   gtsint^.algn := intalgn;

   lsttyp(gtuint, tint);
   gtuint^.tfs := [tfunsigned, tfint];
   gtuint^.size := intlen;
   gtuint^.algn := intalgn;

   lsttyp(gtshint, tint);
   gtshint^.tfs := [tfshort, tfint];
   gtshint^.size := shortlen;
   gtshint^.algn := shortalgn;

   lsttyp(gtssint, tint);
   gtssint^.tfs := [tfsigned, tfshort, tfint];
   gtshint^.size := shortlen;
   gtssint^.algn := shortalgn;

   lsttyp(gtusint, tint);
   gtusint^.tfs := [tfunsigned, tfshort, tfint];
   gtusint^.size := shortlen;
   gtusint^.algn := shortalgn;

   lsttyp(gtlint, tint);
   gtlint^.tfs := [tflong, tfint];
   gtlint^.size := longlen;
   gtlint^.algn := longalgn;

   lsttyp(gtslint, tint);
   gtslint^.tfs := [tfsigned, tflong, tfint];
   gtslint^.size := longlen;
   gtslint^.algn := longalgn;

   lsttyp(gtulint, tint);
   gtulint^.tfs := [tfunsigned, tflong, tfint];
   gtulint^.size := longlen;
   gtulint^.algn := longalgn;

   lsttyp(gtchr, tint);
   gtchr^.tfs := [tfchar];
   gtchr^.size := charlen;
   gtchr^.algn := charalgn;

   lsttyp(gtschr, tint);
   gtschr^.tfs := [tfsigned, tfchar];
   gtschr^.size := charlen;
   gtschr^.algn := charalgn;

   lsttyp(gtuchr, tint);
   gtuchr^.tfs := [tfunsigned, tfchar];
   gtuchr^.size := charlen;
   gtuchr^.algn := charalgn;

   lsttyp(gtflt, tfloat);
   gtflt^.tfs := [tffloat];
   gtflt^.size := floatlen;
   gtflt^.algn := floatalgn;

   lsttyp(gtdbl, tfloat);
   gtdbl^.tfs := [tfdouble];
   gtdbl^.size := doublelen;
   gtdbl^.algn := doublealgn;

   lsttyp(gtldbl, tfloat);
   gtldbl^.tfs := [tflong, tfdouble];
   gtldbl^.size := ldoublelen;
   gtldbl^.algn := ldoublealgn;

   { const }

   lsttyp(gtcvoid, tvoid);
   gtcvoid^.tfs := [tfconst, tfvoid];
   gtcvoid^.size := voidlen;
   gtcvoid^.algn := voidalgn;

   lsttyp(gtcint, tint);
   gtcint^.tfs := [tfconst, tfint];
   gtcint^.size := shortlen;
   gtcint^.algn := shortalgn;

   lsttyp(gtcsint, tint);
   gtcsint^.tfs := [tfconst, tfsigned, tfint];
   gtcsint^.size := shortlen;
   gtcsint^.algn := shortalgn;

   lsttyp(gtcuint, tint);
   gtcuint^.tfs := [tfconst, tfunsigned, tfint];
   gtcuint^.size := shortlen;
   gtcuint^.algn := shortalgn;

   lsttyp(gtcshint, tint);
   gtcshint^.tfs := [tfconst, tfshort, tfint];
   gtcshint^.size := shortlen;
   gtcshint^.algn := shortalgn;

   lsttyp(gtcssint, tint); 
   gtcssint^.tfs := [tfconst, tfsigned, tfshort, tfint];
   gtcssint^.size := shortlen; 
   gtcssint^.algn := shortalgn; 

   lsttyp(gtcusint, tint); 
   gtcusint^.tfs := [tfconst, tfunsigned, tfshort, tfint];
   gtcusint^.size := shortlen;
   gtcusint^.algn := shortalgn;

   lsttyp(gtclint, tint);
   gtclint^.tfs := [tfconst, tflong, tfint];
   gtclint^.size := longlen;
   gtclint^.algn := longalgn;

   lsttyp(gtcslint, tint);
   gtcslint^.tfs := [tfconst, tfsigned, tflong, tfint];
   gtcslint^.size := longlen;
   gtcslint^.algn := longalgn;

   lsttyp(gtculint, tint);
   gtculint^.tfs := [tfconst, tfunsigned, tflong, tfint];
   gtculint^.size := longlen;
   gtculint^.algn := longalgn;

   lsttyp(gtcchr, tint);
   gtcchr^.tfs := [tfconst, tfchar];
   gtcchr^.size := charlen;
   gtcchr^.algn := charalgn;

   lsttyp(gtcschr, tint);
   gtcschr^.tfs := [tfconst, tfsigned, tfchar];
   gtcschr^.size := charlen;
   gtcschr^.algn := charalgn;

   lsttyp(gtcuchr, tint);
   gtcuchr^.tfs := [tfconst, tfunsigned, tfchar];
   gtcuchr^.size := charlen;
   gtcuchr^.algn := charalgn;

   lsttyp(gtcflt, tfloat);
   gtcflt^.tfs := [tfconst, tffloat];
   gtcflt^.size := floatlen;
   gtcflt^.algn := floatalgn;

   lsttyp(gtcdbl, tfloat);
   gtcdbl^.tfs := [tfconst, tfdouble];
   gtcdbl^.size := doublelen;
   gtcdbl^.algn := doublealgn;

   lsttyp(gtcldbl, tfloat); 
   gtcldbl^.tfs := [tfconst, tflong, tfdouble];
   gtcldbl^.size := ldoublelen;
   gtcldbl^.algn := ldoublealgn;

   { volatile }

   lsttyp(gtvvoid, tvoid);
   gtvvoid^.tfs := [tfvolatile, tfvoid];
   gtvvoid^.size := voidlen; 
   gtvvoid^.algn := voidalgn; 

   lsttyp(gtvint, tint);
   gtvint^.tfs := [tfvolatile, tfint];
   gtvint^.size := shortlen;
   gtvint^.algn := shortalgn;

   lsttyp(gtvsint, tint);
   gtvsint^.tfs := [tfvolatile, tfsigned, tfint];
   gtvsint^.size := shortlen;
   gtvsint^.algn := shortalgn;

   lsttyp(gtvuint, tint);
   gtvuint^.tfs := [tfvolatile, tfunsigned, tfint];
   gtvuint^.size := shortlen;
   gtvuint^.algn := shortalgn;

   lsttyp(gtvshint, tint);
   gtvshint^.tfs := [tfvolatile, tfshort, tfint];
   gtvshint^.size := shortlen;
   gtvshint^.algn := shortalgn;

   lsttyp(gtvssint, tint);
   gtvssint^.tfs := [tfvolatile, tfsigned, tfshort, tfint];
   gtvssint^.size := shortlen;
   gtvssint^.algn := shortalgn;

   lsttyp(gtvusint, tint);
   gtvusint^.tfs := [tfvolatile, tfunsigned, tfshort, tfint];
   gtvusint^.size := shortlen;
   gtvusint^.algn := shortalgn;

   lsttyp(gtvlint, tint);
   gtvlint^.tfs := [tfvolatile, tflong, tfint];
   gtvlint^.size := longlen;
   gtvlint^.algn := longalgn;

   lsttyp(gtvslint, tint); 
   gtvslint^.tfs := [tfvolatile, tfsigned, tflong, tfint]; 
   gtvslint^.size := longlen;
   gtvslint^.algn := longalgn;

   lsttyp(gtvulint, tint);
   gtvulint^.tfs := [tfvolatile, tfunsigned, tflong, tfint];
   gtvulint^.size := longlen;
   gtvulint^.algn := longalgn;

   lsttyp(gtvchr, tint);
   gtvchr^.tfs := [tfvolatile, tfchar];
   gtvchr^.size := charlen;
   gtvchr^.algn := charalgn;

   lsttyp(gtvschr, tint);
   gtvschr^.tfs := [tfvolatile, tfsigned, tfchar];
   gtvschr^.size := charlen;
   gtvschr^.algn := charalgn;

   lsttyp(gtvuchr, tint); 
   gtvuchr^.tfs := [tfvolatile, tfunsigned, tfchar];
   gtvuchr^.size := charlen;
   gtvuchr^.algn := charalgn;

   lsttyp(gtvflt, tfloat); 
   gtvflt^.tfs := [tfvolatile, tffloat]; 
   gtvflt^.size := floatlen;
   gtvflt^.algn := floatalgn;

   lsttyp(gtvdbl, tfloat);
   gtvdbl^.tfs := [tfvolatile, tfdouble];
   gtvdbl^.size := doublelen;
   gtvdbl^.algn := doublealgn;

   lsttyp(gtvldbl, tfloat);
   gtvldbl^.tfs := [tfvolatile, tflong, tfdouble];
   gtvldbl^.size := ldoublelen;
   gtvldbl^.algn := ldoublealgn;

   { const volatile }

   lsttyp(gtcvvoid, tvoid);
   gtcvvoid^.tfs := [tfconst, tfvolatile, tfvoid];
   gtcvvoid^.size := voidlen;
   gtcvvoid^.algn := voidalgn;

   lsttyp(gtcvint, tint);
   gtcvint^.tfs := [tfconst, tfvolatile, tfint];
   gtcvint^.size := shortlen;
   gtcvint^.algn := shortalgn;

   lsttyp(gtcvsint, tint);
   gtcvsint^.tfs := [tfconst, tfvolatile, tfsigned, tfint];
   gtcvsint^.size := shortlen;
   gtcvsint^.algn := shortalgn;

   lsttyp(gtcvuint, tint);
   gtcvuint^.tfs := [tfconst, tfvolatile, tfunsigned, tfint];
   gtcvuint^.size := shortlen;
   gtcvuint^.algn := shortalgn;

   lsttyp(gtcvshint, tint);
   gtcvshint^.tfs := [tfconst, tfvolatile, tfshort, tfint];
   gtcshint^.size := shortlen;
   gtcshint^.algn := shortalgn;

   lsttyp(gtcvssint, tint);
   gtcvssint^.tfs := [tfconst, tfvolatile, tfsigned, tfshort, tfint];
   gtcvssint^.size := shortlen;
   gtcvssint^.algn := shortalgn;

   lsttyp(gtcvusint, tint);
   gtcvusint^.tfs := [tfconst, tfvolatile, tfunsigned, tfshort, tfint];
   gtcvusint^.size := shortlen;
   gtcvusint^.algn := shortalgn;

   lsttyp(gtcvlint, tint);
   gtcvlint^.tfs := [tfconst, tfvolatile, tflong, tfint];
   gtcvlint^.size := longlen;
   gtcvlint^.algn := longalgn;

   lsttyp(gtcvslint, tint);
   gtcvslint^.tfs := [tfconst, tfvolatile, tfsigned, tflong, tfint];
   gtcvslint^.size := longlen;
   gtcvslint^.algn := longalgn;

   lsttyp(gtcvulint, tint);
   gtcvulint^.tfs := [tfconst, tfvolatile, tfunsigned, tflong, tfint];
   gtcvulint^.size := longlen;
   gtcvulint^.algn := longalgn;

   lsttyp(gtcvchr, tint);
   gtcvchr^.tfs := [tfconst, tfvolatile, tfchar];
   gtcvchr^.size := charlen;
   gtcvchr^.algn := charalgn;

   lsttyp(gtcvschr, tint);
   gtcvschr^.tfs := [tfconst, tfvolatile, tfsigned, tfchar];
   gtcvschr^.size := charlen;
   gtcvschr^.algn := charalgn;

   lsttyp(gtcvuchr, tint);
   gtcvuchr^.tfs := [tfconst, tfvolatile, tfunsigned, tfchar];
   gtcvuchr^.size := charlen;
   gtcvuchr^.algn := charalgn;

   lsttyp(gtcvflt, tfloat);
   gtcvflt^.tfs := [tfconst, tfvolatile, tffloat];
   gtcvflt^.size := floatlen;
   gtcvflt^.algn := floatalgn;

   lsttyp(gtcvdbl, tfloat);
   gtcvdbl^.tfs := [tfconst, tfvolatile, tfdouble];
   gtcvdbl^.size := doublelen;
   gtcvdbl^.algn := doublealgn;

   lsttyp(gtcvldbl, tfloat);
   gtcvldbl^.tfs := [tfconst, tfvolatile, tflong, tfdouble];
   gtcvldbl^.size := ldoublelen;
   gtcvldbl^.algn := ldoublealgn;

end;

begin

   listtyp; { list types in block }
   listsym; { list and remove symbols }
   endblk { remove top level types }

end.
