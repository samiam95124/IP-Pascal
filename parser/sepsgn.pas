{******************************************************************************
*                                                                             *
*                       SEPARATED SIGN MATEMATICS                             *
*                                                                             *
*                       Copyright (C) 1996 S. A. Moore                        *
*                                                                             *
*                              Written 2006/8/27                              *
*                                                                             *
* Separated sign means keeping the sign and the number separate. We implement *
* these number types as a record, but also allow operations using a boolean   *
* for the sign, and integer value. Separated sign values form a supertype     *
* that can contain both the largest unsigned type, and also have a sign. This *
* means that one type can represent all integer objects in the compiler, and  *
* yet have a fairly simple method of performing operations with them.         *
*                                                                             *
* The main functions contained here are ssgtr and ssadd. The other functions  *
* are rearrangements of those. Mainly there use "neatens" the code, and they  *
* should be reduced by inlining.                                              *
*                                                                             *
* Multiply and divide are present, but don't actually do much, since the      *
* result can be found by a normal multiply or divide followed by an xor of    *
* the signs. Mainly the functions just encapsulate the method itself.         *
*                                                                             *
******************************************************************************}

module sepsgn(output);

type

   { Because we have full size unsigned integer, we handle values as "separated
     sign" integers, which have the sign as a separated element. }
   ssint = record

      s: boolean; { sign }
      v: integer  { unsigned value }

   end;

function ssgtn(sa: boolean; va: integer; sb: boolean; vb: integer): boolean; 
   forward;
overload function ssgtn(a, b: ssint): boolean; forward;
overload function ssgtn(sa: boolean; va: integer; b: ssint): boolean; forward;
overload function ssgtn(a: ssint; sb: boolean; vb: integer): boolean; forward;
function ssltn(sa: boolean; va: integer; sb: boolean; vb: integer): boolean; 
   forward;
overload function ssltn(a, b: ssint): boolean; forward;
overload function ssltn(sa: boolean; va: integer; b: ssint): boolean; forward;
overload function ssltn(a: ssint; sb: boolean; vb: integer): boolean; forward;
function ssgeq(sa: boolean; va: integer; sb: boolean; vb: integer): boolean; 
   forward;
overload function ssgeq(a, b: ssint): boolean; forward;
overload function ssgeq(sa: boolean; va: integer; b: ssint): boolean; forward;
overload function ssgeq(a: ssint; sb: boolean; vb: integer): boolean; forward;
function ssleq(sa: boolean; va: integer; sb: boolean; vb: integer): boolean; 
   forward;
overload function ssleq(a, b: ssint): boolean; forward;
overload function ssleq(sa: boolean; va: integer; b: ssint): boolean; forward;
overload function ssleq(a: ssint; sb: boolean; vb: integer): boolean; forward;
function ssequ(sa: boolean; va: integer; sb: boolean; vb: integer): boolean; 
   forward;
overload function ssequ(a, b: ssint): boolean; forward;
overload function ssequ(sa: boolean; va: integer; b: ssint): boolean; forward;
overload function ssequ(a: ssint; sb: boolean; vb: integer): boolean; forward;
function ssnequ(sa: boolean; va: integer; sb: boolean; vb: integer): boolean; 
   forward;
overload function ssnequ(a, b: ssint): boolean; forward;
overload function ssnequ(sa: boolean; va: integer; b: ssint): boolean; forward;
overload function ssnequ(a: ssint; sb: boolean; vb: integer): boolean; forward;
function ssadd(sa: boolean; va: integer; sb: boolean; vb: integer): integer; 
   forward;
overload function ssadd(a, b: ssint): integer; forward;
overload function ssadd(sa: boolean; va: integer; b: ssint): integer; forward;
overload function ssadd(a: ssint; sb: boolean; vb: integer): integer; forward;
function ssadds(sa: boolean; va: integer; sb: boolean; vb: integer): boolean; 
   forward;
overload function ssadds(a, b: ssint): boolean; forward;
overload function ssadds(sa: boolean; va: integer; b: ssint): boolean; forward;
overload function ssadds(a: ssint; sb: boolean; vb: integer): boolean; forward;
function sssub(sa: boolean; va: integer; sb: boolean; vb: integer): integer; 
   forward;
overload function sssub(a, b: ssint): integer; forward;
overload function sssub(sa: boolean; va: integer; b: ssint): integer; forward;
overload function sssub(a: ssint; sb: boolean; vb: integer): integer; forward;
function sssubs(sa: boolean; va: integer; sb: boolean; vb: integer): boolean; 
   forward;
overload function sssubs(a, b: ssint): boolean; forward;
overload function sssubs(sa: boolean; va: integer; b: ssint): boolean; forward;
overload function sssubs(a: ssint; sb: boolean; vb: integer): boolean; forward;
function ssmult(sa: boolean; va: integer; sb: boolean; vb: integer): integer; 
   forward;
overload function ssmult(a, b: ssint): integer; forward;
overload function ssmult(sa: boolean; va: integer; b: ssint): integer; forward;
overload function ssmult(a: ssint; sb: boolean; vb: integer): integer; forward;
function ssmults(sa: boolean; va: integer; sb: boolean; vb: integer): boolean; 
   forward;
overload function ssmults(a, b: ssint): boolean; forward;
overload function ssmults(sa: boolean; va: integer; b: ssint): boolean; forward;
overload function ssmults(a: ssint; sb: boolean; vb: integer): boolean; forward;
function ssdiv(sa: boolean; va: integer; sb: boolean; vb: integer): integer; 
   forward;
overload function ssdiv(a, b: ssint): integer; forward;
overload function ssdiv(sa: boolean; va: integer; b: ssint): integer; forward;
overload function ssdiv(a: ssint; sb: boolean; vb: integer): integer; forward;
function ssdivs(sa: boolean; va: integer; sb: boolean; vb: integer): boolean; 
   forward;
overload function ssdivs(a, b: ssint): boolean; forward;
overload function ssdivs(sa: boolean; va: integer; b: ssint): boolean; forward;
overload function ssdivs(a: ssint; sb: boolean; vb: integer): boolean; forward;
function ssmod(sa: boolean; va: integer; sb: boolean; vb: integer): integer; 
   forward;
overload function ssmod(a, b: ssint): integer; forward;
overload function ssmod(sa: boolean; va: integer; b: ssint): integer; forward;
overload function ssmod(a: ssint; sb: boolean; vb: integer): integer; forward;
function ssmods(sa: boolean; va: integer; sb: boolean; vb: integer): boolean; 
   forward;
overload function ssmods(a, b: ssint): boolean; forward;
overload function ssmods(sa: boolean; va: integer; b: ssint): boolean; forward;
overload function ssmods(a: ssint; sb: boolean; vb: integer): boolean; forward;
procedure wrtssint(n: ssint); forward;
function ss2int(n: ssint): integer; forward;

private

{******************************************************************************

Find separated sign less than

Finds a < b. Checks the 1st operand is less than the second, using separated
sign math.

******************************************************************************}

function ssltn(sa: boolean; va: integer; sb: boolean; vb: integer): boolean;

var ltn: boolean;

begin

   ltn := false; { set not greater }
   { check signs are different, and determine with signs if so }
   if sa <> sb then ltn := sa { a is negative }
   else if sa then ltn := va > vb { check value a less than value b negative }
   else ltn := va < vb; { check value a less than value b positive }

   ssltn := ltn { return result }

end;

overload function ssltn(a, b: ssint): boolean;

begin

   ssltn := ssltn(a.s, a.v, b.s, b.v)

end;

overload function ssltn(sa: boolean; va: integer; b: ssint): boolean;

begin

   ssltn := ssltn(sa, va, b.s, b.v)

end;

overload function ssltn(a: ssint; sb: boolean; vb: integer): boolean;

begin

   ssltn := ssltn(a.s, a.v, sb, vb)

end;

{******************************************************************************

Find separated sign greater than

Finds a > b. Checks the 1st operand greater than the second, using separated
sign math.

******************************************************************************}

function ssgtn(sa: boolean; va: integer; sb: boolean; vb: integer): boolean;

begin

   ssgtn := ssltn(sb, vb, sa, va) { return result }

end;

overload function ssgtn(a, b: ssint): boolean;

begin

   ssgtn := ssgtn(a.s, a.v, b.s, b.v)

end;

overload function ssgtn(sa: boolean; va: integer; b: ssint): boolean;

begin

   ssgtn := ssgtn(sa, va, b.s, b.v)

end;

overload function ssgtn(a: ssint; sb: boolean; vb: integer): boolean;

begin

   ssgtn := ssgtn(a.s, a.v, sb, vb)

end;

{******************************************************************************

Find separated sign less than or equal to

Find a <= b. Checks the 1st operand is less than or equal to the the second, 
using separated sign math.

******************************************************************************}

function ssleq(sa: boolean; va: integer; sb: boolean; vb: integer): boolean;

begin

   ssleq := not ssltn(sb, vb, sa, va) { return result }

end;

overload function ssleq(a, b: ssint): boolean;

begin

   ssleq := ssleq(a.s, a.v, b.s, b.v)

end;

overload function ssleq(sa: boolean; va: integer; b: ssint): boolean;

begin

   ssleq := ssleq(sa, va, b.s, b.v)

end;

overload function ssleq(a: ssint; sb: boolean; vb: integer): boolean;

begin

   ssleq := ssleq(a.s, a.v, sb, vb)

end;

{******************************************************************************

Find separated sign greater than or equal to

Find a >= b. Checks the 1st operand is greater than or equal to the the second, 
using separated sign math.

******************************************************************************}

function ssgeq(sa: boolean; va: integer; sb: boolean; vb: integer): boolean;

begin

   ssgeq := not ssltn(sa, va, sb, vb) { return result }

end;

overload function ssgeq(a, b: ssint): boolean;

begin

   ssgeq := ssgeq(a.s, a.v, b.s, b.v)

end;

overload function ssgeq(sa: boolean; va: integer; b: ssint): boolean;

begin

   ssgeq := ssgeq(sa, va, b.s, b.v)

end;

overload function ssgeq(a: ssint; sb: boolean; vb: integer): boolean;

begin

   ssgeq := ssgeq(a.s, a.v, sb, vb)

end;

{******************************************************************************

Find separated sign equal

Find a = b. Checks separated sign values are equal. Has all forms of ssint and
separated sign values.

******************************************************************************}

function ssequ(sa: boolean; va: integer; sb: boolean; vb: integer): boolean;

begin

   ssequ := (sa = sb) and (va = vb)

end;

overload function ssequ(a, b: ssint): boolean;

begin

   ssequ := ssequ(a.s, a.v, b.s, b.v)

end;

overload function ssequ(sa: boolean; va: integer; b: ssint): boolean;

begin

   ssequ := ssequ(sa, va, b.s, b.v)

end;

overload function ssequ(a: ssint; sb: boolean; vb: integer): boolean;

begin

   ssequ := ssequ(a.s, a.v, sb, vb)

end;

{******************************************************************************

Find separated sign not equal

Find a <> b. Checks separated sign values are not equal. Has all forms of ssint
and separated sign values.

******************************************************************************}

function ssnequ(sa: boolean; va: integer; sb: boolean; vb: integer): boolean;

begin

   ssnequ := not ssequ(sa, va, sb, vb)

end;

overload function ssnequ(a, b: ssint): boolean;

begin

   ssnequ := not ssequ(a, b)

end;

overload function ssnequ(sa: boolean; va: integer; b: ssint): boolean;

begin

   ssnequ := not ssequ(sa, va, b.s, b.v)

end;

overload function ssnequ(a: ssint; sb: boolean; vb: integer): boolean;

begin

   ssnequ := not ssequ(a.s, a.v, sb, vb)

end;

{******************************************************************************

Find addition of separated sign for value

Finds a+b with separated signs. Returns the value part only. Does no overflow
checking.

******************************************************************************}

function ssadd(sa: boolean; va: integer; sb: boolean; vb: integer): integer;

var r: integer;

begin

   if sa = sb then r := va+vb { add same sign }
   else if va < vb then r := vb-va { subtract smaller from greater }
   else r := va-vb;

   ssadd := r { return result }

end;

overload function ssadd(a, b: ssint): integer;

begin

   ssadd := ssadd(a.s, a.v, b.s, b.v)

end;

overload function ssadd(sa: boolean; va: integer; b: ssint): integer;

begin

   ssadd := ssadd(sa, va, b.s, b.v)

end;

overload function ssadd(a: ssint; sb: boolean; vb: integer): integer;

begin

   ssadd := ssadd(a.s, a.v, sb, vb)

end;

{******************************************************************************

Find addition of separated sign for sign

Finds a+b with separated signs. Returns the sign part only.

******************************************************************************}

function ssadds(sa: boolean; va: integer; sb: boolean; vb: integer): boolean;

var s: boolean;

begin

   if sa = sb then s := sa { signs agree, return that }
   else if va < vb then s := sb { return sign of greater }
   else if va > vb then s := sa
   else s := false; { return +0 }

   ssadds := s { return result }

end;

overload function ssadds(a, b: ssint): boolean;

begin

   ssadds := ssadds(a.s, a.v, b.s, b.v)

end;

overload function ssadds(sa: boolean; va: integer; b: ssint): boolean;

begin

   ssadds := ssadds(sa, va, b.s, b.v)

end;

overload function ssadds(a: ssint; sb: boolean; vb: integer): boolean;

begin

   ssadds := ssadds(a.s, a.v, sb, vb)

end;

{******************************************************************************

Find subtraction of separated sign for value

Finds a-b with separated signs. Returns the value part only. Does no overflow
checking.

******************************************************************************}

function sssub(sa: boolean; va: integer; sb: boolean; vb: integer): integer;

begin

   sssub := ssadd(sa, va, not sb, vb)

end;

overload function sssub(a, b: ssint): integer;

begin

   sssub := sssub(a.s, a.v, b.s, b.v)

end;

overload function sssub(sa: boolean; va: integer; b: ssint): integer;

begin

   sssub := sssub(sa, va, b.s, b.v)

end;

overload function sssub(a: ssint; sb: boolean; vb: integer): integer;

begin

   sssub := sssub(a.s, a.v, sb, vb)

end;

{******************************************************************************

Find subtraction of separated sign for sign

Finds a-b with separated signs. Returns the sign part only.

******************************************************************************}

function sssubs(sa: boolean; va: integer; sb: boolean; vb: integer): boolean;

begin

   sssubs := ssadds(sa, va, not sb, vb)

end;

overload function sssubs(a, b: ssint): boolean;

begin

   sssubs := sssubs(a.s, a.v, b.s, b.v)

end;

overload function sssubs(sa: boolean; va: integer; b: ssint): boolean;

begin

   sssubs := sssubs(sa, va, b.s, b.v)

end;

overload function sssubs(a: ssint; sb: boolean; vb: integer): boolean;

begin

   sssubs := sssubs(a.s, a.v, sb, vb)

end;

{******************************************************************************

Find multiplication of separated sign for value

Finds a*b with separated signs. Returns the value part only. Does no overflow
checking.

******************************************************************************}

function ssmult(sa: boolean; va: integer; sb: boolean; vb: integer): integer;

begin

   refer(sa, sb); { not used }

   ssmult := va*vb { return result }

end;

overload function ssmult(a, b: ssint): integer;

begin

   ssmult := ssmult(a.s, a.v, b.s, b.v)

end;

overload function ssmult(sa: boolean; va: integer; b: ssint): integer;

begin

   ssmult := ssmult(sa, va, b.s, b.v)

end;

overload function ssmult(a: ssint; sb: boolean; vb: integer): integer;

begin

   ssmult := ssmult(a.s, a.v, sb, vb)

end;

{******************************************************************************

Find multiplication of separated sign for sign

Finds a*b with separated signs. Returns the sign part only.

******************************************************************************}

function ssmults(sa: boolean; va: integer; sb: boolean; vb: integer): boolean;

begin

   refer(va, vb); { not used }

   ssmults := sa xor sb { return result }

end;

overload function ssmults(a, b: ssint): boolean;

begin

   ssmults := ssmults(a.s, a.v, b.s, b.v)

end;

overload function ssmults(sa: boolean; va: integer; b: ssint): boolean;

begin

   ssmults := ssmults(sa, va, b.s, b.v)

end;

overload function ssmults(a: ssint; sb: boolean; vb: integer): boolean;

begin

   ssmults := ssmults(a.s, a.v, sb, vb)

end;

{******************************************************************************

Find division of separated sign for value

Finds a div b with separated signs. Returns the value part only.

******************************************************************************}

function ssdiv(sa: boolean; va: integer; sb: boolean; vb: integer): integer;

begin

   refer(sa, sb); { not used }

   ssdiv := va div vb { return result }

end;

overload function ssdiv(a, b: ssint): integer;

begin

   ssdiv := ssdiv(a.s, a.v, b.s, b.v)

end;

overload function ssdiv(sa: boolean; va: integer; b: ssint): integer;

begin

   ssdiv := ssdiv(sa, va, b.s, b.v)

end;

overload function ssdiv(a: ssint; sb: boolean; vb: integer): integer;

begin

   ssdiv := ssdiv(a.s, a.v, sb, vb)

end;

{******************************************************************************

Find division of separated sign for sign

Finds a div b with separated signs. Returns the sign part only.

******************************************************************************}

function ssdivs(sa: boolean; va: integer; sb: boolean; vb: integer): boolean;

begin

   refer(va, vb); { not used }

   ssdivs := sa xor sb { return result }

end;

overload function ssdivs(a, b: ssint): boolean;

begin

   ssdivs := ssdivs(a.s, a.v, b.s, b.v)

end;

overload function ssdivs(sa: boolean; va: integer; b: ssint): boolean;

begin

   ssdivs := ssdivs(sa, va, b.s, b.v)

end;

overload function ssdivs(a: ssint; sb: boolean; vb: integer): boolean;

begin

   ssdivs := ssdivs(a.s, a.v, sb, vb)

end;

{******************************************************************************

Find mod of separated sign for value

Finds a mod b with separated signs. Returns the value part only.

******************************************************************************}

function ssmod(sa: boolean; va: integer; sb: boolean; vb: integer): integer;

begin

   refer(sa, sb); { not used }

   ssmod := va mod vb { return result }

end;

overload function ssmod(a, b: ssint): integer;

begin

   ssmod := ssmod(a.s, a.v, b.s, b.v)

end;

overload function ssmod(sa: boolean; va: integer; b: ssint): integer;

begin

   ssmod := ssmod(sa, va, b.s, b.v)

end;

overload function ssmod(a: ssint; sb: boolean; vb: integer): integer;

begin

   ssmod := ssmod(a.s, a.v, sb, vb)

end;

{******************************************************************************

Find modulo of separated sign for sign

Finds a mod b with separated signs. Returns the sign part only.

******************************************************************************}

function ssmods(sa: boolean; va: integer; sb: boolean; vb: integer): boolean;

begin

   refer(va, vb); { not used }

   ssmods := sa xor sb { return result }

end;

overload function ssmods(a, b: ssint): boolean;

begin

   ssmods := ssmods(a.s, a.v, b.s, b.v)

end;

overload function ssmods(sa: boolean; va: integer; b: ssint): boolean;

begin

   ssmods := ssmods(sa, va, b.s, b.v)

end;

overload function ssmods(a: ssint; sb: boolean; vb: integer): boolean;

begin

   ssmods := ssmods(a.s, a.v, sb, vb)

end;

{******************************************************************************

Write separated sign value

Writes a separated sign integer with negative suppression and a field length
of 1. This routine is for diagnostics.
Writes out a separated sign value. For diagnostics.

******************************************************************************}

procedure wrtssint(n: ssint);

begin

   if n.s then write('-'); { write sign if appears }
   write(n.v:1) { write value }

end;

{******************************************************************************

Convert separated sign to integer

Converts a separated sign value to a standard integer.

******************************************************************************}

function ss2int(n: ssint);

var i: integer; { integer holding }

begin

   if n.s then i := -n.v { set as signed }
   else i := n.v; { set as unsigned }

   ss2int := i { return }

end;

begin
end.