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
charlen     = 1;  { length of char }
intlen      = 4;  { length of int }
shortlen    = 2;  { length of short int }
longlen     = 4;  { length of long int }
floatlen    = 4;  { length of float }
doublelen   = 8;  { length of double }
ldoublelen  = 12; { length of long double }
ptrlen      = 4;  { length of pointer }

{ type-specifier lead tolkens }
typespecld = [cvoid, cchar, cshort, cint, clong, cfloat, cdouble, csigned,
              cunsigned, cstruct, cunion, cenum, cidentifier];
{ declaration-specifiers lead tolkens }
decspecld = [cauto, cregister, cstatic, cextern, ctypedef, cconst, cvolatile,
             cvoid, cchar, cshort, cint, clong, cfloat, cdouble, csigned,
             cunsigned, cstruct, cunion, cenum, cidentifier];

var

{ we define a series of global types to reduce thrashing }
gtudf:      typptr; { global undefined }
gtvoid:     typptr; { global void }
gtchar:     typptr; { global character }
gtshort:    typptr; { global short }
gtint:      typptr; { global int }
gtlong:     typptr; { global long }
gtfloat:    typptr; { global float }
gtdouble:   typptr; { global double }
gtsigned:   typptr; { global signed }
gtunsigned: typptr; { global unsigned }
gtconst:    typptr; { global const }
gtvolatile: typptr; { global volatile }
gtauto:     typptr; { global auto }
gtregister: typptr; { global register }
gtstatic:   typptr; { global static }
gtextern:   typptr; { global extern }
gttypedef:  typptr; { global typedef }

procedure pardecl; forward;
procedure parexpr; forward;
procedure parassexpr; forward;
procedure parcastexpr(cst: boolean; var val: integer; var wasunary: boolean);
   forward;
procedure parcondexpr(cst: boolean; var val: integer; var wasunary: boolean);
   forward;
procedure parspecqual(var tp: typptr); forward;
procedure pardect(var sp: symptr; var head, tail: typptr; abs, cabs: boolean);
   forward;
procedure partypespec(var tp: typptr); forward;

{******************************************************************************

Place base type

Places the given base type in a type entry. Exactly where the base type pointer
gets placed depends on the entry.

******************************************************************************}

procedure plcbase(var tp: typptr; base: typptr);

begin

   if not (tp^.t in [tptr, tarray, tfield, tvar, tfunc, tpar, tddf]) then
      error(esys); { no base for this entry }
   case tp^.t of { entry type }


      tptr:    tp^.ptrt := base;
      tarray:  begin

         tp^.arrt := base;
         { if element count is defined, set size of array }
         if tp^.arre > 0 then tp^.size := tp^.arrt^.size*tp^.arre

      end;
      tfield:  begin

         tp^.fldt := base;
         tp^.size := tp^.fldt^.size { set to base size }

      end;
      tvar:    begin

         tp^.vart := base;
         tp^.size := tp^.vart^.size { set to base size }

      end;
      tfunc:   tp^.fncr := base;
      tfunci:  tp^.fnit := base;
      tpar:    begin

         tp^.part := base;
         tp^.size := tp^.vart^.size { set to base size }

      end;
      tddf:    tp^.ddft := base;

   end

end;

{******************************************************************************

Join type lists

Joins two type lists end for end. The new list is returned in the destination.
Handles the case where one or more lists are nil.
Note that a complete destination can be joined to another type without a tail,
but the destination must have a tail to be joined.

******************************************************************************}

procedure jointype(var dhead, dtail: typptr; shead, stail: typptr);

begin

   if dhead = nil then begin { the destination is nil, set to source }

      dhead := shead;
      dtail := stail

   end else if shead <> nil then begin { the source list is not nil }

      if dtail = nil then error(esys); { should not be nil }
      plcbase(dtail, shead); { place the source list in last desination }
      { storage classes ripple upwards }
      if (dhead^.sc <> scnone) and (shead^.sc <> scnone) then error(escldup);
      if dhead^.sc = scnone then begin 

         dhead^.sc := shead^.sc; { transfer }
         shead^.sc := scnone { clear old }

      end

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

         if sp^.typ = nil then error(esys); { should have a type }
         if sp^.typ^.t in [tvoid, tptr, tenum, tarray, tstruct, tunion,
                           tfunc, tinteger, tfloat, tdouble, tddf] then
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

         if sp^.typ = nil then error(esys); { should have a type }
         if sp^.typ^.t in [tvoid, tptr, tenum, tarray, tstruct, tunion,
                           tfunc, tinteger, tfloat, tdouble,
                           tddf] then
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
         if not cstf then error(eicstexp) { must be integer constant }

      end;
      gettlk { skip id }

   end else if nxttlk in [ccint, cclong, cclonglong, ccuint, cculong,
                     cculonglong] then begin { integer constant }

      val := nxtint; { set constant return }
      gettlk { skip }

   end else if nxttlk = cstring then begin { string constant }

      if cst then begin { perform constant processing }

         if nxtlen <> 1 then error(eicstexp); { must be constant }
         val := ord(nxtlab[1]) { get the value of the character }

      end;
      gettlk { skip }

   end else if nxttlk = creal then begin { real }

      if cst then error(eicstexp); { must be constant }
      gettlk { skip }

   end else if nxttlk = clparen then begin { ( expression ) }

      gettlk; { skip '(' }
      { check constant or full expression }
      if cst then parcondexpr(cst, val, dummy) { parse constant expression }
      else parexpr; { parse expression }
      if nxttlk <> crparen then error(erpexp); { ')' expected }
      gettlk { skip ']' }

   end else error(eprmexp) { nothing found }

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

      if cst then error(ecstopr); { operation not permitted for constant }
      case nxttlk of { operator }

         clbrkt: begin { [ expression ] }

            gettlk; { skip '[' }
            parexpr; { parse expression }
            if nxttlk <> crbrkt then error(erbktexp);
            gettlk { skip ']' }

         end;
         clparen: begin { ( assignment-expression ) }

            gettlk; { skip '(' }
            while nxttlk <> crparen do begin { parse assignment-expressions }

               parassexpr; { parse assignment-expression }
               { check ',' or ')' }
               if not (nxttlk in [ccma, crparen]) then error(erpexp);
               if nxttlk = ccma then gettlk { skip ',' }

           end;
           if nxttlk <> crparen then error(erpexp); { ')' expected }
           gettlk { skip ')' }

         end;
         cperiod: begin { .identifier }

            gettlk; { skip '.' }
            if nxttlk <> cidentifier then error(eidexp); { must be id }
            gettlk { skip id }

         end;
         cprec: begin { ->identifier }

            gettlk; { skip '->' }
            if nxttlk <> cidentifier then error(eidexp); { must be id }
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

var dummy: boolean;
    sp:    symptr;      { symbol pointer }
    tp:    typptr;      { type pointer }
    head, tail: typptr; { list of types }

begin

   if fprtrle then writeln('parunaexpr:');
   if nxttlk in [cinc, cdec, csizeof, cand, ctimes, cplus, cminus, ccomp,
                 clnot] then begin

      { check valid operation for constant }
      if cst and (nxttlk in [cinc, cdec, cand, ctimes]) then error(ecstopr);
      case nxttlk of { tolken }

         cinc: begin gettlk; parunaexpr(cst, val) end; { ++ unary-expression }
         cdec: begin gettlk; parunaexpr(cst, val) end; { -- unary-exrression }
         csizeof: begin { sizeof }

            gettlk; { skip 'sizeof' }
            if nxttlk = clparen then begin { sizeof(type-name) }

               gettlk; { skip '(' }
               { parse type-name construct, here because we need a terminator }
               parspecqual(tp); { parse specifier-qualifier-list }
               if nxttlk <> crparen then begin { declarator present }
             
                  { parse abstract declarator }
                  pardect(sp, head, tail, true, false);
                  jointype(head, tail, tp, nil); { place base type }
                  tp := head { place net type }
             
               end;
               val := tp^.size; { return size of type }
               if nxttlk <> crparen then error(erpexp); { ')' expected }
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

var dummy: boolean;
    tp:    typptr; { type pointer }
    sp:    symptr; { symbol pointer }
    head, tail: typptr; { list pointers }

begin

   if fprtrle then writeln('parcastexpr:');
   if nxttlk = clparen then begin { ( type-name ) }

      gettlk; { skip '(' }
      if typnlead then begin { type name leader found }

         wasunary := false; { implicate unary }
         { parse type-name construct, here because we need a terminator }
         parspecqual(tp); { parse specifier-qualifier-list }
         if nxttlk <> crparen then begin { declarator present }

            pardect(sp, head, tail, true, false); { parse abstract declarator }
            jointype(head, tail, tp, nil); { place base type }
            tp := head { place net type }

         end;
         if nxttlk <> crparen then error(erpexp); { ')' expected }
         gettlk; { skip ')' }
         if cst and (tp^.t <> tinteger) then error(ecstcas);
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

            if rval < 0 then error(eshftno); { cannot be minus }
            if rval >= 31 then val := 0 { full shiftout }
            else while rval > 0 do begin { perform shift }

               { remove high bit if present }
               if val > maxint div 2 then val := val-maxint div 2;
               val := val*2; { shift }
               rval := rval-1 { count }

            end

         end;
         cshr: begin { shift right }

            if rval < 0 then error(eshftno); { cannot be minus }
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
      if nxttlk <> ccln then error(eclnexp); { ':' expected }
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
               if nxttlk <> cend then error(eendexp) { should be end }

            end else begin { multiple line form }

               while not (nxttlk in [cend, ceof]) do gettlk; { skip contents }
               if nxttlk <> cend then error(eendexp); { should be end }
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
               if nxttlk <> cscn then error(escnexp); { ';' expected }
               gettlk { skip ';' }

            end

         end

      end;
      ccase: begin { case conditional-expression: statement }

         gettlk; { skip 'case' }
         { parse conditional expression (don't care unary) }
         parcondexpr(true, val, dummy);
         if nxttlk <> ccln then error(eclnexp); { ':' expected }
         gettlk; { skip ':' }
         parstat { parse statement }

      end;
      cdefault: begin { default: statement }

         gettlk; { skip 'default' }
         if nxttlk <> ccln then error(eclnexp); { ':' expected }
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
         if nxttlk <> clparen then error(elpexp); { '(' expected }
         gettlk; { skip '(' }
         parexpr; { parse expression }
         if nxttlk <> crparen then error(erpexp); { ')' expected }
         gettlk; { skip '(' }
         parstat; { parse statement }
         if nxttlk = celse then begin { there is an else }

            gettlk; { skip 'else' }
            parstat { parse statement }

         end

      end;
      cswitch: begin { switch (expression) statement }

         gettlk; { skip 'switch' }
         if nxttlk <> clparen then error(elpexp); { '(' expected }
         gettlk; { skip '(' }
         parexpr; { parse expression }
         if nxttlk <> crparen then error(erpexp); { ')' expected }
         gettlk; { skip '(' }
         parstat { parse statement }

      end;
      cwhile: begin { while (expression) statement }

         gettlk; { skip 'while' }
         if nxttlk <> clparen then error(elpexp); { '(' expected }
         gettlk; { skip '(' }
         parexpr; { parse expression }
         if nxttlk <> crparen then error(erpexp); { ')' expected }
         gettlk; { skip '(' }
         parstat { parse statement }

      end;
      cdo: begin { do statement while (expression); }

         gettlk; { skip 'do' }
         parstat; { parse statement }
         if nxttlk <> cwhile then error(ewhlexp); { 'while' expected }
         gettlk; { skip 'while' }
         if nxttlk <> clparen then error(elpexp); { '(' expected }
         gettlk; { skip '(' }
         parexpr; { parse expression }
         if nxttlk <> crparen then error(erpexp); { ')' expected }
         gettlk; { skip '(' }
         if nxttlk <> cscn then error(escnexp); { ';' expected }
         gettlk { skip ';' }

      end;
      cfor: begin { for (expression; expression; expression) statement }

         gettlk; { skip 'for' }
         if nxttlk <> clparen then error(elpexp); { '(' expected }
         gettlk; { skip '(' }
         parexpr; { parse expression }
         if nxttlk <> cscn then error(escnexp); { ';' expected }
         gettlk; { skip ';' }
         parexpr; { parse expression }
         if nxttlk <> cscn then error(escnexp); { ';' expected }
         gettlk; { skip ';' }
         parexpr; { parse expression }
         if nxttlk <> crparen then error(erpexp); { ')' expected }
         gettlk; { skip '(' }
         parstat { parse statement }

      end;
      cgoto: begin { goto identifier; }

         gettlk; { skip 'goto' }
         if nxttlk <> cidentifier then error(eidexp); { identifier expected }
         gettlk; { skip id }
         if nxttlk <> cscn then error(escnexp); { ';' expected }
         gettlk { skip ';' }

      end;
      ccontinue: begin { continue; }

         gettlk; { skip 'continue' }
         if nxttlk <> cscn then error(escnexp); { ';' expected }
         gettlk { skip ';' }

      end;
      cbreak: begin { break; }

         gettlk; { skip 'break' }
         if nxttlk <> cscn then error(escnexp); { ';' expected }
         gettlk { skip ';' }

      end;
      creturn: begin { return expression; }

         gettlk; { skip 'return' }
         if nxttlk <> cscn then parexpr; { parse return expression }
         if nxttlk <> cscn then error(escnexp); { ';' expected }
         gettlk { skip ';' }

      end

   end else begin { default is expression; }

      if nxttlk <> cscn then parexpr; { parse expression }
      if nxttlk <> cscn then error(escnexp); { ';' expected }
      gettlk { skip ';' }

   end

end;

{******************************************************************************

Merge types

Merges two type entries into a new type based on both types. Basically, this
amounts to seeing if the two types are compatible with each other and none of
the flags conflict, then unifying all the information into one new entry.

******************************************************************************}

procedure mrgtyp(var dtp: typptr; stp: typptr);

var ltp: typptr; { 2nd source }

procedure swap; { swap types }

var ttp: typptr; { temp type }

begin

   ttp := stp;
   stp := ltp;
   ltp := ttp

end;

procedure copyfield(var dtp: typptr; stp: typptr); { copy all fields }

begin

   case dtp^.t of { type }

      tudf:     ;
      tvoid:    ;
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
      tptr:     dtp^.ptrt := stp^.ptrt;
      tarray:   begin

         dtp^.arrt := stp^.arrt;
         dtp^.arre := stp^.arre

      end;
      tstruct:  begin

         dtp^.strf := stp^.strf;
         dtp^.strl := stp^.strl

      end;
      tunion:   begin

         dtp^.unif := stp^.unif;
         dtp^.unil := stp^.unil

      end;
      tfield:   begin

         dtp^.fldn := stp^.fldn;
         dtp^.fldh := stp^.fldh;
         dtp^.fldb := stp^.fldb;
         dtp^.fldt := stp^.fldt

      end;
      tvar:     begin

         dtp^.vart := stp^.vart;
         dtp^.varc := stp^.varc

      end;
      tfunc:    begin

         dtp^.fncp := stp^.fncp;
         dtp^.fncr := stp^.fncr;
         dtp^.fncl := stp^.fncl;
         dtp^.fncv := stp^.fncv
         

      end;
      tfunci:   dtp^.fnit := stp^.fnit;
      tpar:     begin

         dtp^.parn := stp^.parn;
         dtp^.part := stp^.part;
         dtp^.parh := stp^.parh

     end;
      tinteger: dtp^.ints := stp^.ints;
      tfloat:   ;
      tdouble:  dtp^.dbll := stp^.dbll;
      tddf:     begin

         dtp^.ddfs := stp^.ddfs;
         dtp^.ddft := stp^.ddft;
         dtp^.ddfd := dtp^.ddfd

      end;
      tglbl:    ;

   end

end;

begin

   { check if Microsoft duplicate type flag is on, and types are identical.
     if that case, just leave the destination alone }
   if not fduptyp or not comptype(dtp, stp) then begin

      ltp := dtp; { save desintation type }
      { check neither operand is undefined type, and both not integer }
      if ((ltp^.t <> tudf) and (stp^.t <> tudf)) and
         not ((ltp^.t = tinteger) and (stp^.t = tinteger)) and
         not ((ltp^.t = tstruct) and (stp^.t = tstruct)) and
         not ((ltp^.t = tunion) and (stp^.t = tunion)) and
         not ((ltp^.t = tenum) and (stp^.t = tenum)) and
         not ((ltp^.t = tinteger) and (stp^.t = tdouble)) and
         not ((ltp^.t = tdouble) and (stp^.t = tinteger)) then error(etypdup);
      { check multiple storage classes }
      if (ltp^.sc <> scnone) and (stp^.sc <> scnone) then error(escldup);
      { check const specified more than once }
      if (tqconst in ltp^.tq) and (tqconst in stp^.tq) then error(ecstdup);
      { check volatile specified more than once }
      if (tqvolatile in ltp^.tq) and (tqvolatile in stp^.tq) then error(evoldup);
      { handle integer to integer merge errors }
      if (ltp^.t = tinteger) and (stp^.t = tinteger) then begin

         { check any duplicates }
         if (ischar in ltp^.ints*stp^.ints) or
            (isshort in ltp^.ints*stp^.ints) or
            (isint in ltp^.ints*stp^.ints) or
            (islong in ltp^.ints*stp^.ints) or
            (issigned in ltp^.ints*stp^.ints) or
            (isunsigned in ltp^.ints*stp^.ints) then error(etypdup);
         { check char and int specified together }
         if ((ischar in ltp^.ints) and (isint in stp^.ints)) or
            ((isint in ltp^.ints) and (ischar in stp^.ints)) then error(etypdup);
         if ischar in stp^.ints then swap; { swap so that char is left }
         if ischar in ltp^.ints then { left is char }
            if (isshort in stp^.ints) or (islong in stp^.ints) then error(echratt)

      end;
      if stp^.t = tdouble then swap; { make sure double is on left }
      if ltp^.t = tdouble then { double case }
         if ltp^.dbll and (ltp^.ints <> [islong]) then error(etypdup);
      { check abstract enums }
      if (ltp^.t = tenum) and (stp^.t = tenum) then begin

         if (ltp^.enc <> nil) and (stp^.enc <> nil) then error(eredef)

      end;
      { check abstract struct }
      if (ltp^.t = tstruct) and (stp^.t = tstruct) then begin

         if (ltp^.strf <> nil) and (stp^.strf <> nil) then error(eredef)

      end;
      { check abstract union }
      if (ltp^.t = tunion) and (stp^.t = tunion) then begin

         if (ltp^.unif <> nil) and (stp^.unif <> nil) then error(eredef)

      end;
      { error checking taken care of, merge the various components }
      if ltp^.t = tudf then swap; { make sure undef is on the right }
      lsttyp(dtp, ltp^.t); { get result entry }
      copyfield(dtp, ltp); { copy the entry }
      dtp^.sc := ltp^.sc; { find new class specifier }
      if dtp^.sc = scnone then dtp^.sc := stp^.sc; { get other if undefined }
      dtp^.tq := ltp^.tq+stp^.tq; { find total of type qualifiers }
      { do integer merging }
      if (ltp^.t = tinteger) and (stp^.t in [tinteger, tudf]) then
         dtp^.ints := ltp^.ints+stp^.ints; { set total of integer attributes }
      if stp^.t = tdouble then swap; { make sure double is on left }
      if ltp^.t = tdouble then begin { double cases }
               
         dtp^.dbll := false; { set no long }
         if islong in stp^.ints then ltp^.dbll := true { place long status }

      end;
      { merge abstract enums }
      if (ltp^.t = tenum) and (stp^.t = tenum) then begin

         { place defined list, which could be neither }
         dtp^.enc := ltp^.enc;
         if ltp^.enc = nil then dtp^.enc := stp^.enc

      end;
      { merge abstract struct }
      if (ltp^.t = tstruct) and (stp^.t = tstruct) then begin

         { place defined list, which could be neither }
         dtp^.strf := ltp^.strf;
         dtp^.strl := ltp^.strl;
         if ltp^.strf = nil then begin

            dtp^.strf := stp^.strf;
            dtp^.strl := stp^.strl

         end

      end;
      { merge abstract union }
      if (ltp^.t = tunion) and (stp^.t = tunion) then begin

         { place defined list, which could be neither }
         dtp^.unif := ltp^.unif;
         dtp^.unil := ltp^.unil;
         if ltp^.unif = nil then begin

            dtp^.unif := stp^.unif;
            dtp^.unil := stp^.unil

         end

      end;
      { merge sizes }
      dtp^.size := ltp^.size; { place left size }
      if ltp^.size = 0 then dtp^.size := stp^.size; { place defined size }
      { special case, short added to integer resizes it }
      if dtp^.t = tinteger then if isshort in dtp^.ints then dtp^.size := shortlen;
      { special case, double with long resizes it }
      if dtp^.t = tdouble then if dtp^.dbll then dtp^.size := ldoublelen

   end

end;

{******************************************************************************

Check completed type

Checks if the given type pointer is not nil, and represents a completed type.
There is no way to know all of the completed types, which is a problem.

******************************************************************************}

function whltyp(tp: typptr): boolean;

var istype: boolean;

begin

   istype := false; { set not type }
   if tp <> nil then begin

      if tp^.t in [tenum, tptr, tarray, tfunc, tfloat] then
         istype := true { found whole type }
      else if tp^.t = tstruct then begin { check structure cases }

         if tp^.strf <> nil then istype := true { if not abstract, set true }

      end

   end;

   whltyp := istype { return result }

end;

{******************************************************************************

Parse specifier-qualifier-list

Parses a specifier-qualifier-list. Returns the base type as modified by type
qualifiers.
Uses the rule that if an identifier is seen that has a complete type, and
we are already working on a complete type, the identifier is left alone.

******************************************************************************}

procedure parspecqual(var tp: typptr);

var cont: boolean; { continue flag }
    tp1:  typptr;  { type pointer }
    sp:   symptr;  { symbol pointer }

begin

   if fprtrle then writeln('parspecqual:');
   tp := nil; { clear type }
   repeat { type leader }

      cont := true; { continue }
      if nxttlk = cidentifier then begin

         sp := gblsym(nxtlab, false); { find symbol }
         if sp <> nil then { there is a symbol }
            if whltyp(sp^.typ) and whltyp(tp) then cont := false

      end;
      if cont then begin { regular processing }

         { check type-qualifier }
         if nxttlk in [cconst, cvolatile] then begin { yes, process }

            case nxttlk of { specifier/qualifier }

               cconst:    tp1 := gtconst;
               cvolatile: tp1 := gtvolatile

            end;
            { merge with previous or set as type }
            if tp <> nil then mrgtyp(tp, tp1) else tp := tp1;
            gettlk { skip }

         end else begin { full type }

            partypespec(tp1); { type-specifier }
            { combine multiple type specs }
            if tp <> nil then mrgtyp(tp, tp1) { merge separate types }
            else tp := tp1; { else just use that }

         end;
         { check for more type-specifier or type-qualifier }
         cont := false; { set no continue }
         { check common leaders }
         if nxttlk in typespecld+[cconst, cvolatile]-[cidentifier] then
            cont := true;
         if nxttlk = cidentifier then begin { id }

            sp := gblsym(nxtlab, false); { find symbol }
            if sp <> nil then begin { there is a symbol }

               if sp^.typ = nil then error(esys); { should have a type }
               { check is a type id }
               if sp^.typ^.t in [tvoid, tptr, tenum, tarray, tstruct,
                                 tunion, tfunc, tinteger, tfloat,
                                 tdouble, tddf] then cont := true

            end

         end

      end

   until not cont;

end;

{******************************************************************************

Parse type-specifier

Parses the type-specifier construct. Returns a type entry that is the resulting
type, either preexisting or newly created.

******************************************************************************}

procedure partypespec(var tp: typptr);

var t:            tolken;
    sp:           symptr;  { symbol pointer }
    enumc:        integer; { enumeration counter }
    tp1, tp2, lp: typptr;
    head, tail:   typptr; { declarator list }
    dummy:        boolean;
    val:          integer; { expression return value }

begin

   if fprtrle then writeln('partypespec:');
   tp := nil; { clear result } 
   if not (nxttlk in [cvoid, cchar, cshort, cint, clong, cfloat, cdouble,
                      csigned, cunsigned, cstruct, cunion, cenum,
                      cidentifier]) then error(einvtyp); { invalid type }
   if nxttlk in [cstruct, cunion, cenum] then begin { structured type }

      t := nxttlk; { save tolken as type of object }
      gettlk; { skip }
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
               tp^.sc := scnone; { set no storage class }
               tp^.tq := []; { set no qualification }
               tp^.size := 0 { set no size }

            end;
            cunion: begin

               lsttyp(tp, tunion); { get entry }
               tp^.unif := gtudf; { set leaves undefined }
               tp^.unil := nil;
               tp^.sc := scnone; { set no storage class }
               tp^.tq := []; { set no qualification }
               tp^.size := 0 { set no size }
  
            end;
            cenum: begin

               lsttyp(tp, tenum); { get entry }
               tp^.enc := gtudf; { set leaves undefined }
               tp^.sc := scnone; { set no storage class }
               tp^.tq := []; { set no qualification }
               tp^.size := 0 { set no size }

            end

         end;
         if sp <> nil then sp^.typ := tp { link back to symbol }

      end;
      if nxttlk = cbegin then begin { sructure specification }

         gettlk; { skip begin }
         { now we are defining a type, so if there is not abstract, then
           it is a duplicate }
         case t of { type }

            cstruct: if tp^.strf <> gtudf then error(etyprdf);
            cunion:  if tp^.unif <> gtudf then error(etyprdf);
            cenum: if tp^.enc <> gtudf then error(etyprdf)

         end;
         if t = cenum then begin { enumerator }

            enumc := 0; { clear enumeration constant }
            lp := nil; { set no last enumerator }
            repeat

               { must be identifier }
               if nxttlk <> cidentifier then error(eidexp);
               define(sp, false); { define that symbol }
               lsttyp(tp1, tenme); { get next constant entry }
               if lp = nil then tp^.enc := tp1 { place as root }
               else lp^.enx := tp1; { place as link to last }
               sp^.typ := tp1; { link to symbol }
               tp1^.sc := scnone; { clear storage class }
               tp1^.tq := []; { clear type qualifier }
               tp1^.enh := tp; { set head entry }
               tp1^.env := enumc; { set constant }
               tp1^.enx := nil; { clear next }
               tp1^.size := intlen; { set size as int }
               lp := tp1; { set new last }
               enumc := enumc+1; { next constant }
               gettlk; { skip id }
               if nxttlk = cas then begin { = constant-expression }

                  gettlk; { skip '=' }
                  parcondexpr(true, val, dummy) { parse conditional-expression }

               end;
               t := nxttlk; { save next tolken }
               if nxttlk = ccma then gettlk { skip ',' }

            { allow nonstandard extra ',' on flag }
            until (t <> ccma) or ((nxttlk = cend) and fenecma)  { no more }

         end else begin { must be structure list }

            lp := nil; { clear last field entry }
            repeat

               parspecqual(tp1); { parse specifier-qualifier-list }
               repeat

                  if nxttlk = ccln then begin

                     { there is a bit spec only, this entry becomes an anonymous
                       bit pad. because it has no name, we coin an entry now }
                     gettlk; { skip ':' }
                     parcondexpr(true, val, dummy); { parse bit spec only }
                     lsttyp(tp2, tfield); { get a field entry }
                     if lp = nil then begin { place as root }

                        if tp^.t = tstruct then tp^.strf := tp2
                        else tp^.unif := tp2

                     end else lp^.fldn := tp2; { place as next }
                     lp := tp2; { set as new last }
                     tp2^.fldh := tp; { place head link }
                     tp2^.fldb := val; { set number of bits }
                     tp2^.fldt := tp1; { set base type }
                     tp2^.fldn := nil; { set no next }
                     tp2^.sc := scnone; { set no storage class }
                     tp2^.tq := []; { set no qualification }
                     tp2^.size := val div 8; { set number of bytes }
                     if val mod 8 > 0 then tp2^.size := tp2^.size+1 { round up }

                  end else if (nxttlk  = cscn) and fuse then begin

                     { unnamed struct/union field, enter anonymous field.
                       this is a non-standard feature }
                     lsttyp(tp2, tfield); { get a field entry }
                     if lp = nil then begin { place as root }

                        if tp^.t = tstruct then tp^.strf := tp2
                        else tp^.unif := tp2

                     end else lp^.fldn := tp2; { place as next }
                     lp := tp2; { set as new last }
                     tp2^.fldh := tp; { place head link }
                     tp2^.fldb := -1; { flag no bitfield }
                     tp2^.fldt := tp1; { set base type }
                     tp2^.fldn := nil; { set no next }
                     tp2^.sc := scnone; { set no storage class }
                     tp2^.tq := []; { set no qualification }
                     tp2^.size := tp1^.size { set number of bytes }

                  end else begin { declarator }

                     pardect(sp, head, tail, false, false); { parse declarator }
                     jointype(head, tail, tp1, nil); { place base type }
                     tp1 := head; { place head of list as new base type }
                     val := -1; { flag no bit width }
                     if nxttlk = ccln then begin

                        gettlk; { skip ':' }
                        parcondexpr(true, val, dummy) { parse bit spec only }

                     end;
                     lsttyp(tp2, tfield); { get a field entry }
                     if lp = nil then begin { place as root }

                        if tp^.t = tstruct then tp^.strf := tp2
                        else tp^.unif := tp2

                     end else lp^.fldn := tp2; { place as next }
                     lp := tp2; { set as new last }
                     tp2^.fldh := tp; { place head link }
                     tp2^.fldb := val; { set number of bits }
                     tp2^.fldt := tp1; { set base type }
                     tp2^.fldn := nil; { set no next }
                     tp2^.sc := scnone; { set no storage class }
                     tp2^.tq := []; { set no qualification }
                     tp2^.size := tp1^.size; { set as base size }
                     sp^.typ := tp2; { link symbol to field entry }
                     if tp^.t = tstruct then begin { place to structure id list }

                        sp^.next := tp^.strl; { push onto list }
                        tp^.strl := sp

                     end else begin { place to union id list }

                        sp^.next := tp^.unil; { push onto list }
                        tp^.unil := sp

                     end

                  end;
                  t := nxttlk; { save next tolken }
                  if t = ccma then gettlk { skip ',' }

               until t <> ccma; { until not ',' }
               if nxttlk = cscn then gettlk { skip ';' }

            until nxttlk = cend { until end }

         end;
         if nxttlk <> cend then error(eendexp); { end expected }
         gettlk { skip end }

      end

   end else begin { standard type }

      if nxttlk = cidentifier then begin { its a type identifier }

         sp := gblsym(nxtlab, false); { find symbol }
         if sp = nil then error(esymnf); { not found }
         if sp^.typ = nil then error(esys); { must have a type }
         { check is valid type }
         if not (sp^.typ^.t in [tvoid, tenum, tptr, tarray, tstruct, tunion,
                                tfunc, tinteger, tfloat, tdouble]) then
            error(einvtnm);
         tp := sp^.typ { place resulting type }

      end else begin { standard type }

         { get a base type. each type specifier is either an end type or a
           modifier to a type. all modifiers describe only one type, so it is
           allways possible to generate a type based on such a specifier.
           so we return a complete type, but that may be combined with other
           types to form the final type }
         case nxttlk of { type }

            cvoid:     tp := gtvoid;
            cchar:     tp := gtchar;
            cshort:    tp := gtshort;
            cint:      tp := gtint;
            clong:     tp := gtlong;
            cfloat:    tp := gtfloat;
            cdouble:   tp := gtdouble;
            csigned:   tp := gtsigned;
            cunsigned: tp := gtunsigned

         end

      end;
      gettlk { skip leader tolken }

   end

end;

{******************************************************************************

Parse declaration-specifiers

Parses the delcaration-specifiers construct. Returns the base type as modified
by storage specifiers and type qualifiers.
Uses the rule that if we are working on a structure type, and an id comes
along that is also a structure type, then the id is not parsed here.

******************************************************************************}

procedure pardecspec(var tp: typptr);

var cont: boolean; { continue flag }
    tp1:  typptr;  { type pointer }
    sp:   symptr;  { symbol pointer }

begin

   if fprtrle then writeln('pardecspec:');
   tp := nil; { clear type }
   repeat { type leader }

      cont := true; { continue }
      if nxttlk = cidentifier then begin

         sp := gblsym(nxtlab, false); { find symbol }
         if sp <> nil then { there is a symbol }
            if whltyp(sp^.typ) and whltyp(tp) then cont := false

      end;
      if cont then begin { regular processing }

         { check type-qualifier, or type specifier }
         if nxttlk in [cauto, cregister, cstatic, cextern, ctypedef, cconst,
                       cvolatile] then begin { yes, process }

            case nxttlk of { specifier/qualifier }

               cauto:     tp1 := gtauto;
               cregister: tp1 := gtregister;
               cstatic:   tp1 := gtstatic;
               cextern:   tp1 := gtextern;
               ctypedef:  tp1 := gttypedef;
               cconst:    tp1 := gtconst;
               cvolatile: tp1 := gtvolatile

            end;
            { merge with previous or set as type }
            if tp <> nil then mrgtyp(tp, tp1) else tp := tp1;
            gettlk { skip }

         end else begin { full type }

            partypespec(tp1); { type-specifier }
            { combine multiple type specs }
            if tp <> nil then mrgtyp(tp, tp1) { merge separate types }
            else tp := tp1; { else just use that }

         end;
         { check for more type-specifier or type-qualifier }
         cont := false; { set no continue }
         { check common leaders }
         if nxttlk in decspecld-[cidentifier] then cont := true;
         if nxttlk = cidentifier then begin { id }

            sp := gblsym(nxtlab, false); { find symbol }
            if sp <> nil then begin { there is a symbol }

               if sp^.typ = nil then error(esys); { should have a type }
               { check is a type id }
               if sp^.typ^.t in [tvoid, tptr, tenum, tarray, tstruct,
                                 tunion, tfunc, tinteger, tfloat,
                                 tdouble, tddf] then cont := true

            end

         end

      end

   until not cont

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
    sp, lsp:          symptr;  { symbol pointer }
    fndnam:           boolean; { found parameter name flag }
    t:                tolken;  { next tolken save }
    dummy:            boolean;

begin

   if fprtrle then writeln('parfuncarr:');
   head := nil; { clear list head and tail }
   tail := nil;
   if nxttlk = clbrkt then begin { [ conditional-expression ] }

      val := -1; { flag no length on array }
      gettlk; { skip '[' }
      if nxttlk <> crbrkt then
         parcondexpr(true, val, dummy); { parse conditional-expression }
      if nxttlk <> crbrkt then error(erbktexp); { ']' expected }
      gettlk; { skip ']' }
      lsttyp(tp, tarray); { get an array entry }
      tp^.sc := scnone; { set no storage class specifier }
      tp^.tq := []; { set no type qualifier }
      tp^.arre := val; { set number of elements }
      head := tp; { set as single element list }
      tail := tp;
      tp^.size := 0; { set no length by default (unsized array) }
      { recursively join any additional lists to the end of this }
      if nxttlk in [clparen, clbrkt] then begin { theres more }

         parfuncarr(nhead, ntail, abs); { get the rest of list }
         if nhead = nil then error(esys); { should be at least one element }
         { check attempt to form array of functions }
         if nhead^.t = tfunc then error(earrfnc);
         jointype(head, tail, nhead, ntail) { add to the end of our list }

      end

   end else if nxttlk = clparen then begin { ( id or function params ) }

      gettlk; { skip '(' }
      { it is possible to define named types during a parameter list. Such
        symbols have no real scope, and are purged }
      level := level+1; { start a new scope }
      lsttyp(tp, tfunc); { get an array entry }
      tp^.sc := scnone; { set no storage class specifier }
      tp^.tq := []; { set no type qualifier }
      tp^.fncp := nil; { clear parameter list }
      tp^.fncv := false; { set not variable length }
      tp^.fncr := nil; { clear result type }
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

            if nxttlk <> cidentifier then error(eidexp); { must be id }
            lodsym(sp); { load that into a symbol }
            gettlk; { skip id }
            if lsp = nil then tp^.fncl := sp { link symbol as head }
            else lsp^.next := sp; { link symbol as next }
            lsp := sp; { set new last }
            lsttyp(tp2, tpar); { get a parameter entry }
            tp2^.sc := scnone; { set no storage class specifier }
            tp2^.tq := []; { set no type qualifier }
            tp2^.part := nil; { set no base type }
            tp2^.parh := tp; { set head }
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

            pardecspec(tp1); { parse declaration-specifiers }
            if nxttlk in [ccma, crparen] then begin { no declarator  }

               sp := nil; { set no symbol }
               nhead := tp1 { set type is base type }

            end else begin { declarator exists }

               { parse delcarator with no preference }
               pardect(sp, nhead, ntail, false, true);
               jointype(nhead, ntail, tp1, nil); { merge entry to list end }
               if lsp = nil then tp^.fncl := sp { link symbol as head }
               else lsp^.next := sp; { link symbol as next }
               lsp := sp { set new last }

            end;
            lsttyp(tp2, tpar); { get a parameter entry }
            tp2^.sc := scnone; { set no storage class specifier }
            tp2^.tq := []; { set no type qualifier }
            tp2^.part := nhead; { set base type }
            tp2^.parh := tp; { set head }
            tp2^.size := nhead^.size; { set size as base }
            if sp <> nil then sp^.typ := tp2; { link to symbol }
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

         until t <> ccma; { until not ',' }

      end;
      if nxttlk <> crparen then error(erpexp); { ')' expected }
      gettlk; { skip ')' }
      purge; { remove any symbols entered }
      level := level-1; { back out that level }
      head := tp; { set as single element list }
      tail := tp;
      { recursively join any additional lists to the end of this }
      if nxttlk in [clparen, clbrkt] then begin { theres more }

         parfuncarr(nhead, ntail, abs); { get the rest of list }
         if nhead = nil then error(esys); { should be at least one element }
         { check attempt to form array of functions }
         if nhead^.t = tfunc then error(efncfnc);
         jointype(head, tail, nhead, ntail) { add to the end of our list }

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
      tp^.sc := scnone; { set no storage class specifier }
      tp^.tq := []; { set no type qualifier }
      tp^.size := ptrlen; { set size }
      tp^.ptrt := nil; { clear base }
      while nxttlk in [cconst, cvolatile] do begin

         if nxttlk = cconst then begin

            if tqconst in tp^.tq then error(ecstdup)

         end else begin

            if tqvolatile in tp^.tq then error(evoldup);

         end;
         gettlk { skip type-qualifiers } 

      end;
      if tail = nil then tail := tp; { set tail if none }
      head := tp { set head }

   end;
   if nxttlk = cidentifier then begin { id }

      if abs then error(eabsdec); { bad abstract declarator }
      if nxttlk <> cidentifier then error(eidexp); { id expected }
      lodsym(sp); { load that into a symbol }
      gettlk; { skip id }
      parfuncarr(nhead, ntail, abs); { parse function/array declarator list }
      jointype(nhead, ntail, head, tail); { join the lists }
      head := nhead; { index that as new list }
      tail := ntail

   end else if (nxttlk = clparen) or (not abs and not cabs) then begin

      { must be (declarator) }
      if nxttlk <> clparen then error(elpidexp); { '(' or id expected }
      gettlk; { skip '(' }
      pardect(sp, nhead, ntail, abs, true); { parse subdeclarator }
      if nxttlk <> crparen then error(erpexp); { ')' expected }
      gettlk; { ')' }
      parfuncarr(nhead2, ntail2, abs); { parse function/array declarator list }
      { place that list on end of declarator list }
      jointype(nhead, ntail, nhead2, ntail2);
      jointype(nhead, ntail, head, tail); { join base list to end of all that }
      head := nhead; { index that as new list }
      tail := ntail

   end;

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
      if nxttlk <> cend then error(eendexp); { should be end }
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
    sp:         symptr; { symbol pointer }

begin

   if fprtrle then writeln('pardecl:');
   pardecspec(tp); { parse declaration-specifiers }
   repeat { declarators }

      pardect(sp, head, tail, false, false); { parse standard declarator }
      newsym(sp, false); { place label in symbol table }
      jointype(head, tail, tp, nil); { merge entry to list end }
      { check if simple typedef, and pin the symbol to it if so }
      if head^.sc = sctypedef then begin

         { we consider the typedef to be an indicator that only carries
           the type to this point. it must be removed so that it will not
           indicate another definition }
         head^.sc := scnone; { demote the entry }
         sp^.typ := head { link to symbol }

      end else begin { variable at top level, must be static or extern }

         lsttyp(tp1, tvar); { get entry }
         tp1^.sc := head^.sc; { set storage class }
         tp1^.tq := []; { set no qualification }
         tp1^.vart := head; { set base type }
         tp1^.size := head^.size; { set no size }
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
   if nxttlk <> cscn then error(escnexp); { ';' expected }
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

var t:          tolken; { next tolken save }
    tp, tp1:    typptr; { type pointer }
    head, tail: typptr; { type list }
    sp, sp1:    symptr; { symbol pointer }

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
   pardecspec(tp); { parse declaration-specifiers }
   repeat { declarators }

      pardect(sp, head, tail, false, false); { parse standard declarator }
      fndlab(sp^.lab^, sp1); { find matching parameter label }
      if sp1 = nil then error(eparsnf); { no matching parameter symbol }
      if sp1^.typ = nil then error(esys); { should have tpar entry }
      if sp1^.typ^.t <> tpar then error(esys);
      if sp1^.typ^.part <> nil then error(epardtp); { parameter has duplicate type }
      jointype(head, tail, tp, nil); { merge entry to list end }
      lsttyp(tp1, tpar); { get entry }
      tp1^.sc := head^.sc; { set storage class }
      tp1^.tq := []; { set no qualification }
      tp1^.part := head; { set base type }
      tp1^.size := head^.size; { set no size }
      sp1^.typ := head; { place symbol linkage }
      if nxttlk = cas then error(eparini); { cannot initalize parameter }
      t := nxttlk; { save next }
      if nxttlk = ccma then gettlk { get next }

   until t <> ccma; { no more declarations }
   if nxttlk <> cscn then error(escnexp); { ';' expected }
   gettlk { skip ';' }

end;

{******************************************************************************

Parse translation unit

Parse the translation-unit construct.

******************************************************************************}

procedure partrans;

var t:          tolken;
    tp:         typptr; { type pointer }
    head, tail: typptr; { type list }
    sp:         symptr; { symbol pointer }
    td:         boolean; { typedef indicated flag }

begin

   if fprtrle then writeln('partrans:');
   repeat

      tp := nil; { set no declaration type }
      td := false; { set not in typedef }
      if declead then pardecspec(tp); { parse declaration specifier }
      if nxttlk = cscn then gettlk { there is no declaration }
      else begin { declaration }

         { parse delcarator with no preference }
         pardect(sp, head, tail, false, false);
         newsym(sp, false); { place label in symbol table }
         { the leaders of a standard declaration and a function declaration are
           identical to this point. now we rely on the next tolkens of a standard
           declaration to break them apart }
         if nxttlk in [cas, ccma, cscn] then begin { its a standard declaration }

            if tp = nil then error(edattyp); { must have type for this }
            jointype(head, tail, tp, nil); { merge entry to list end }
            { check 'auto' or 'register' used on top level declaration }
            if head^.sc in [scauto, scregister] then error(einvcls);
            { check if simple typedef, and pin the symbol to it if so }
            if head^.sc = sctypedef then begin

               { we consider the typedef to be an indicator that only carries
                 the type to this point. it must be removed so that it will not
                 indicate another definition }
               head^.sc := scnone; { demote the entry }
               sp^.typ := head; { link to symbol }
               { because we remove the typedef flag, we must save that
                 indication for further defintitions using it }
               td := true { set is a typedef }

            end else begin { variable at top level, must be static or extern }

               lsttyp(tp, tvar); { get entry }
               tp^.sc := head^.sc; { set storage class }
               tp^.tq := []; { set no qualification }
               tp^.vart := head; { set base type }
               tp^.size := head^.size; { set size }
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
                  { parse delcarator with no preference }
                  pardect(sp, head, tail, false, false);
                  newsym(sp, false); { place label in symbol table }
                  jointype(head, tail, tp, nil); { merge entry to list end }
                  { check 'auto' or 'register' used on top level declaration }
                  if head^.sc in [scauto, scregister] then error(einvcls);
                  { check if simple typedef, and pin the symbol to it if so }
                  if td then begin
                  
                     { we consider the typedef to be an indicator that only
                       carries the type to this point. it must be removed so
                       that it will not indicate another definition }
                     head^.sc := scnone; { demote the entry }
                     sp^.typ := head { link to symbol }
                  
                  end else begin { variable at top level, must be static or extern }
                  
                     lsttyp(tp, tvar); { get entry }
                     tp^.sc := head^.sc; { set storage class }
                     tp^.tq := []; { set no qualification }
                     tp^.vart := head; { set base type }
                     tp^.size := head^.size; { set size }
                     tp^.varc := nil; { set no initalization }
                     sp^.typ := tp { place symbol linkage }
                  
                  end

               end

            until t <> ccma; { no more declarations }
            if nxttlk <> cscn then error(escnexp); { ';' expected }
            gettlk { skip ';' }

         end else begin { function declaration }

            if tp = nil then tp := gtint; { if typeless, default to 'int' }
            jointype(head, tail, tp, nil); { merge entry to list end }
            if head^.t <> tfunc then error(efncexp); { function expected }
            lsttyp(tp, tfunci); { get entry }
            tp^.sc := head^.sc; { set storage class }
            tp^.tq := []; { set no qualification }
            tp^.fnit := head; { set base type }
            tp^.size := head^.size; { set size }
            sp^.typ := tp; { place symbol linkage }
            while nxttlk <> cbegin do pardecp(head); { parse declarations }
            gettlk; { skip begin }
            { check all parameters have types assigned, and default to integer if
              none }
            tp := head^.fncp; { index start of parameter list }
            while tp <> nil do begin { traverse }

               if tp^.t <> tpar then error(esys); { bad type }
               if tp^.part = nil then tp^.part := gtint; { place integer type }
               tp := tp^.parn { link next }

            end;
            bgnblk; { start block }
            while declead do pardecl; { parse any declarations }
            while nxttlk <> cend do parstat; { parse statements }
            gettlk; { skip end }
            listtyp; { list types in block }
            listsym; { list and remove symbols }
            endblk { remove block }

         end

      end

   until nxttlk = ceof { until end of file } 

end;

begin

   fprtrle := false; { set no print parsing rules }
   fuse := true; { allow unnamed structure elements }
   fmsasm := true; { allow Microsoft asm constructs }
   fenecma := true; { allow extra enumerator comment }
   fduptyp := true; { allow type duplication }

   bgnblk; { start new block }

   { create global entries to lessen type traffic }

   { integer specifiers }
   lsttyp(gtvoid, tvoid); { get a void type }
   gtvoid^.sc := scnone; { clear storage class }
   gtvoid^.tq := []; { clear type qualifier }
   gtvoid^.size := 0; { no length }

   lsttyp(gtchar, tinteger); { get an integer type }
   gtchar^.sc := scnone; { clear storage class }
   gtchar^.tq := []; { clear type qualifier }
   gtchar^.ints := [ischar]; { set is character }
   gtchar^.size := charlen; { set length }

   lsttyp(gtshort, tinteger); { get an integer type }
   gtshort^.sc := scnone; { clear storage class }
   gtshort^.tq := []; { clear type qualifier }
   gtshort^.ints := [isshort]; { set is short }
   gtshort^.size := shortlen; { set length }

   lsttyp(gtint, tinteger); { get an integer type }
   gtint^.sc := scnone; { clear storage class }
   gtint^.tq := []; { clear type qualifier }
   gtint^.ints := [isint]; { set is int }
   gtint^.size := intlen; { set length }

   lsttyp(gtlong, tinteger); { get an integer type }
   gtlong^.sc := scnone; { clear storage class }
   gtlong^.tq := []; { clear type qualifier }
   gtlong^.ints := [islong]; { set is long }
   gtlong^.size := longlen; { set length }

   lsttyp(gtsigned, tinteger); { get an integer type }
   gtsigned^.sc := scnone; { clear storage class }
   gtsigned^.tq := []; { set is short }
   gtsigned^.ints := [issigned]; { set is signed }
   gtsigned^.size := intlen; { set length }

   lsttyp(gtunsigned, tinteger); { get an integer type }
   gtunsigned^.sc := scnone; { clear storage class }
   gtunsigned^.tq := []; { set is short }
   gtunsigned^.ints := [isunsigned]; { set is unsigned }
   gtunsigned^.size := intlen; { set length }

   { floats }
   lsttyp(gtfloat, tfloat); { get a float type }
   gtfloat^.sc := scnone; { clear storage class }
   gtfloat^.tq := []; { clear type qualifier }
   gtfloat^.size := floatlen; { set length }

   lsttyp(gtdouble, tdouble); { get a double type }
   gtdouble^.sc := scnone; { clear storage class }
   gtdouble^.tq := []; { clear type qualifier }
   gtdouble^.dbll := false; { set no long double }
   gtdouble^.size := doublelen; { set length }

   { type qualifiers and storage classes have no specific type associated, so
     we place them in an undefined type entry for merging }

   { type qualifier }  
   lsttyp(gtconst, tudf); { get an undef type }
   gtconst^.sc := scnone; { clear storage class }
   gtconst^.tq := [tqvolatile]; { set is volatile }
   gtconst^.size := 0; { no length }

   lsttyp(gtvolatile, tudf); { get an undef type }
   gtvolatile^.sc := scnone; { clear storage class }
   gtvolatile^.tq := [tqvolatile]; { set is volatile }
   gtvolatile^.size := 0; { no length }

   { storage class specifier }
   lsttyp(gtauto, tudf); { get an undef type }
   gtauto^.sc := scauto; { clear storage class }
   gtauto^.tq := []; { set is volatile }
   gtauto^.size := 0; { no length }

   lsttyp(gtregister, tudf); { get an undef type }
   gtregister^.sc := scregister; { clear storage class }
   gtregister^.tq := []; { set is volatile }
   gtregister^.size := 0; { no length }

   lsttyp(gtstatic, tudf); { get an undef type }
   gtstatic^.sc := scstatic; { clear storage class }
   gtstatic^.tq := []; { set is volatile }
   gtstatic^.size := 0; { no length }

   lsttyp(gtextern, tudf); { get an undef type }
   gtextern^.sc := scextern; { clear storage class }
   gtextern^.tq := []; { set is volatile }
   gtextern^.size := 0; { no length }

   lsttyp(gttypedef, tudf); { get an undef type }
   gttypedef^.sc := sctypedef; { clear storage class }
   gttypedef^.tq := []; { set is volatile }
   gttypedef^.size := 0; { no length }

   { set up the global undefined type }

   lsttyp(gtudf, tudf); { get an undef type }
   gtudf^.sc := scnone; { clear storage class }
   gtudf^.tq := []; { set is volatile }
   gtudf^.size := 0 { no length }

end;

begin

   listtyp; { list types in block }
   listsym; { list and remove symbols }
   endblk { remove top level types }

end.
