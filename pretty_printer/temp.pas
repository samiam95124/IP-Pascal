module parser(output);

uses parsedef,
     common,
     strlib,
     parserot,
     scanner,
     symbol;

procedure parmod(ss: tolkset); forward;

private

procedure parstat(ss: tolkset); forward;
procedure parexpr(ss: tolkset; var tp: typptr); forward;
procedure partype(ss: tolkset; var tp: typptr); forward;
procedure pardec(ss: tolkset; inuses: boolean); forward;
procedure parprcfnci(ss: tolkset; pp: typptr; var tp: typptr); forward;
procedure parconst(ss: tolkset; var tp: typptr); forward;

{******************************************************************************

Parse constant factor

   factconst = '(' const ')' | 'not' factconst | string | const-ident | integer

Parse and generate constant factor. Accepts a tolken skip set.
Returns the type entry for the constant, which will be a string
constant, integer constant, or a skeleton key if nothing found.
Error recovery:

1. No id or integer for constant, skip to follow on 
missing constant.

******************************************************************************}

procedure parfaccon(ss: tolkset; var tp: typptr);

var sp:   symptr;  { symbol pointer }
    ti:   integer; { integer temp }
    tp1:  typptr;  { type pointer }
    last: tolken;  { parsing aid }
    si:   labinx;  { index for string }
	stct: typptr;  { set constant base type holder }
	stcc: typptr;  { set constant list holder }

begin

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
      parfaccon(ss, tp) { parse constant factor }

   end else if nxttlk = cstring then begin { string }

      gettlk { skip string }

   end else if nxttlk = cinteger then begin { integer constant }

         gettlk { skip integer }

   end else if nxttlk = creal then begin { real constant }

         gettlk { skip real }

   end else if nxttlk = cidentifier then begin { id }
 
      gettlk { integer or id }

   end else if nxttlk = clbrkt then begin { set constant }

      gettlk;
      if nxttlk <> crbrkt then repeat { set elements }

         parconst([crbrkt, crange, ccma]+ss, tp); { parse constant expression }
         if nxttlk = crange then begin

            gettlk; { next }
            parconst([ccma, crbrkt, crange]+ss, tp); { parexpr }

         end;
         if (nxttlk <> ccma) and (nxttlk <> crbrkt) then
            { we don't have an exit tolken }
            perror(erbcmexp, [ccma, crbrkt, crange]+exprset+ss, []);
         last := nxttlk; { save tolken }
         if nxttlk = ccma then gettlk { next }

      { until not ',', and no expression set }
      until not (last in [ccma, crange]+exprset);
      if nxttlk = crbrkt then gettlk; { next }

   end

end;

{******************************************************************************

Parse constant term

   termconst = factconst ['*' factconst | '/' factconst | 'div' factconst | 
               'mod' factconst | 'and' factcont]..

Parse and generate constant term. Accepts a tolken skip set.
Returns the type entry for the constant, which will be a string
constant, integer constant, or a skeleton key if nothing found.
Error recovery:

1. No id or integer for constant, skip to follow on 
missing constant.

******************************************************************************}

procedure partrmcon(ss: tolkset; var tp: typptr);

var tp1:      typptr;  { type pointer }
    tk:       tolken;  { tolken save }
    trl, trr: real;    { real temps }
    ti:       integer; { integer temp }

begin

   { parse left constant factor }
   parfaccon([ctimes, crdiv, cdiv, cmod, cand]+ss, tp);
   while nxttlk in [ctimes, crdiv, cdiv, cmod, cand] do begin

      gettlk; { next }
      { parse right constant factor }
      parfaccon([ctimes, crdiv, cdiv, cmod, cand]+ss, tp1);

   end

end;

{******************************************************************************

Parse constant

   const = ['+' | '-'] termconst ['+' factconst | '-' factconst | 
                                  'or' factconst]..

Parse and generate constant term. Accepts a tolken skip set.
Returns the type entry for the constant, which will be a string
constant, integer constant, or a skeleton key if nothing found.
Error recovery:

1. No id or integer for constant, skip to follow on 
missing constant.

******************************************************************************}

procedure parconst(ss: tolkset; var tp: typptr);

var tp1:      typptr;  { type pointer }
    tk:       tolken;  { tolken save }
    trl, trr: real;    { real temps }
    ti:       integer; { integer temp }

begin

   if (nxttlk = cplus) or (nxttlk = cminus) then { sign }
      gettlk; { skip '+'/'-' }
   { parse left constant factor }
   partrmcon([cplus, cminus, cor, cxor]+ss, tp);
   while (nxttlk in [cplus, cminus, cor, cxor]) and not fansi do begin

      gettlk; { next }
      { parse right constant factor }
      partrmcon([ctimes, crdiv, cdiv, cmod, cand]+ss, tp1);

   end

end;

{******************************************************************************

Parse structured constant

   stconst = arrconst | recconst | const

   arrconst = 'array' const [',' const].. 'end'

   recconst = 'record' const [',' const].. 'end'

Parse and generate a structured constant. Accepts a tolken skip set, and the
type of the constant, which can be structured. Returns the type entry for the
constant, which can be a simple or structured entry constant. The constant
being built is matched against the target type as it is being built, so that
we can output errors in their context.

******************************************************************************}

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
    tv:       integer; { tag field value holder }

begin

   if nxttlk = carray then begin { parse array..end structure }

      gettlk; { skip 'array' }
      repeat { parse elements }

         parstconst([ccma, cend]+ss, bt, tp1); { parse element }
         if (nxttlk <> ccma) and (nxttlk <> cend) then
            { we don't have an exit tolken }
            perror(ecmedexp, [ccma, cend]+constset+ss, [cend]);
         last := nxttlk; { save tolken }
         if last = ccma then gettlk { skip ',' }
         
      { until not ',' or likely constant type }
      until not (last in [ccma, carray, crecord]+constset);
      if nxttlk = cend then gettlk; { skip 'end' }
      
   end else if nxttlk = crecord then begin { parse record..end structure }

      gettlk; { skip 'record' }
      repeat { parse elements }

         parstconst([ccma, cend]+ss, fl^.fldt, tp1) { parse element }
         if (nxttlk <> ccma) and (nxttlk <> cend) then
            { we don't have an exit tolken }
            perror(ecmedexp, [ccma, cend]+constset+ss, []);
         last := nxttlk; { save tolken }
         if last = ccma then gettlk { skip ',' }
         
      { until not ',' or likely constant type }
      until not (last in [ccma, carray, crecord]+constset);
      if nxttlk = cend then gettlk; { skip 'end' }

   end else begin

      parconst(ss, tp); { parse ordinary constant }

   end

end;

{******************************************************************************

Parse variable

   variable = ident [ '['expr [,expr].. ']' | '.'ident | '^' ]..

Parse and generate variable reference. Accepts a tolken skip set.
Expects the leading identifier to have already been parsed.
This is to allow the caller to look ahead by a symbol, which is
required to parse parts of the syntax unambiguously (like
x := y (assignment) vs. x (procedure)). 
Error recovery:

1. Missing ',' in array series, based on the next tolken being
and expression begin.

2. Exteraneous before following ',', ']', '[', '.', '^'. 

3. Missing ']' (by fall through).

4. Missing ident after '.'.

Generates intermediate to place an address as top of stack that indexes the
variable or part thereof (if a structure or pointer). An address indirect
load must be generated to get the actual value.

******************************************************************************}

procedure parvar(    ss: tolkset; { skip set }
                     sp: symptr;  { head symbol entry }
                     vp: boolean; { process as variable parameter }
                 var tp: typptr); { head type and resulting type }
                 

var fs:  symptr;  { found symbol in record search }
    tp1: typptr;  { type pointer }
    ti:  integer; { temp integer holder }
    vt:  typptr;  { variable entry holder }

begin

   while nxttlk in [clbrkt, cperiod, ccmf] do begin
   
      if nxttlk = clbrkt then begin { array index }
   
         repeat { indecies }
   
            { don't skip over the start of a recovered expression }
            if (nxttlk = clbrkt) or (nxttlk = ccma) then 
               gettlk; { skip '[' or ',' }
            parexpr([ccma, crbrkt]+ss, tp1); { parse expression }
            if (nxttlk <> ccma) and (nxttlk <> crbrkt) then
               { we don't have an exit tolken }
               perror(erbcmexp, [ccma, crbrkt, clbrkt, cperiod, 
                      ccmf]+exprset+ss, [])
   
         { until not ',', and no expression set }
         until not (nxttlk in [ccma]+exprset);
         if nxttlk = crbrkt then gettlk { skip ']' }
   
      end else if nxttlk = cperiod then begin { record offset }
   
         gettlk; { next }
         if nxttlk <> cidentifier then { missing id }
            perror(eidnexp, [clbrkt, cperiod, ccmf]+ss, []);
         if nxttlk = cidentifier then gettlk { next }
   
      end else begin { pointer indirection }
   
         gettlk; { skip '^' }
   
      end
   
   end

end;

{******************************************************************************

Parse variable with head

Parses a variable, with the head. This is used only in the case where we know
a variable is to be parsed beforehand.

******************************************************************************}

procedure parvarh(    ss:     tolkset; { skip set }
                      threat: boolean; { "threat" access status }
                  var tp:     typptr); { return type }

var sp: symptr; { symbol pointer }

begin

   { parse variable head }
   if nxttlk <> cidentifier then { id expected }
      perror(evidexp, [cidentifier, cperiod, ccmf]+ss, []);
   if nxttlk in [cidentifier, cperiod, ccmf] then begin 

      parvar(ss, sp, false, tp) { parse variable reference }

   end

end;   

{******************************************************************************

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
             
******************************************************************************}

procedure parfactor(    ss: tolkset;  { skip set }
                    var tp: typptr);  { return type }

var last: tolken;  { parsing aid }
    sp:   symptr;  { symbol pointer } 
    tp1:  typptr;  { type pointers }
    lt:   typptr;  { last type }
    lts:  boolean; { last type exists flag }
    bt:   typptr;  { base type }
    ti:   integer; { temp integer result }
    si:   labinx;  { string index }

begin

   { see if we have any head tolken }
   if not (nxttlk in [cidentifier, cinteger, creal, cnil, cstring,
                      clparen, cnot, clbrkt]) then 
      perror(einvfact, [cidentifier, cinteger, creal, cnil, 
             cstring, clparen, cnot, clbrkt]+ss, []);
   if nxttlk = cidentifier then begin
   
      gettlk; { next }
      if nxttlk = clparen then begin

         parprcfnci(ss, sp^.typ, tp) { parse function call }

      end else begin { parse variable }

         parvar(ss, sp, false, tp); { parse variable }

      end

   end else if nxttlk = cinteger then begin { unsigned number }

      gettlk; { skip integer }

   end else if nxttlk = creal then begin { unsigned real }

      gettlk; { skip real }

   end else if nxttlk = cnil then begin { 'nil' }

      gettlk; { skip 'nil' }
      
   end else if nxttlk = cstring then begin { string }

      gettlk; { skip string }

   end else if nxttlk = clparen then begin { (expr) }

      gettlk; { next }
      parexpr([crparen]+ss, tp); { parse expression }
      expect(crparen, erpexp, [crparen]+ss, []) { expect ')' }

   end else if nxttlk = cnot then begin { 'not' }

      gettlk; { next }
      parfactor(ss, tp); { parse factor }

   end else if nxttlk = clbrkt then begin { set construction }

      gettlk; { next }
      if nxttlk <> crbrkt then repeat { set elements }

         parexpr([crbrkt, crange, ccma]+ss, tp); { parse expression }
         if nxttlk = crange then begin

            gettlk; { next }
            parexpr([ccma, crbrkt, crange]+ss, tp); { parexpr }

         end;
         if (nxttlk <> ccma) and (nxttlk <> crbrkt) then
            { we don't have an exit tolken }
            perror(erbcmexp, [ccma, crbrkt, crange]+exprset+ss, []);
         last := nxttlk; { save tolken }
         if nxttlk = ccma then gettlk { next }

      { until not ',', and no expression set }
      until not (last in [ccma, crange]+exprset);
      if nxttlk = crbrkt then gettlk; { next }

   end else if (nxttlk = cperiod) or (nxttlk = ccmf) then begin

      { guesstimate that it could be a variable with missing
        head }
      parvar(ss, nil, false, tp); { parse }

   end

end;

{******************************************************************************

Parse term

   term = factor [ '*' factor | '/' factor | 'div' factor |
          'mod' factor | 'and' factor ]..

Parses and generates a term. Accepts a tolken skip set.
Error recovery:

1. Resyncs to any of the middle tolkens. 

******************************************************************************}

procedure parterm(    ss: tolkset; { skip set }
                  var tp: typptr); { return type }

var tp1:   typptr;  { type pointer }
    tk:    tolken;  { tolken save }
    ti:    integer; { temp integer result }
    tr:    real;    { temp real result }
    trl:   real;    { temp left real holder }
    trr:   real;    { temp right real holder }
    solve: boolean; { solved constant flag }

begin

   parfactor([ctimes, crdiv, cdiv, cmod, cand]+ss, tp); { parse factor }
   while nxttlk in [ctimes, crdiv, cdiv, cmod, cand] do begin

      gettlk; { next }
      parfactor([ctimes, crdiv, cdiv, cmod, cand]+ss, tp1); { parse factor }

   end

end;

{******************************************************************************

Parse simple expression

   sexpr = sterm [ '+' term | '-' term | 'or' term ]..

   sterm = '+' term | '-' term

Parses and generates a term. Accepts a tolken skip set.
Error recovery:

1. Resyncs to any of the middle tolkens. 

******************************************************************************}

procedure parsexpr(    ss: tolkset; { skip set }
                   var tp: typptr); { return type }

var tp1:   typptr;  { type pointer }
    tk:    tolken;  { tolken save }
    ti:    integer; { temp integer result }
    tr:    real;    { temp real result }
    trl:   real;    { temp left real holder }
    trr:   real;    { temp right real holder }
    solve: boolean; { solved constant flag }

begin

   if (nxttlk = cplus) or (nxttlk = cminus) then { sign }
      gettlk; { skip '+'/'-' }
   parterm([cplus, cminus, cor, cxor]+ss, tp); { parse term }
   while nxttlk in [cplus, cminus, cor, cxor] do begin

      gettlk; { next }
      parterm([cplus, cminus, cor]+ss, tp1); { parse term }

   end

end;

{******************************************************************************

Parse expression

   expr = sexpr | '=' expr | '<' expr | '>' expr | '<>' expr | 
          '<=' expr | '>=' expr> | 'in' expr>

Parses and generates an expression. Accepts a tolken skip set.
Error recovery:

1. Resyncs to any of the middle tolkens.

******************************************************************************}

procedure parexpr(    ss: tolkset; { skip set }
                  var tp: typptr); { return type }

var tp1:   typptr;  { type pointer }
    tk:    tolken;  { tolken save }
    solve: boolean; { solved constant flag }

begin

   { parse simple expression }
   parsexpr([cequ, cltn, cgtn, cnequ, clequ, cgequ, cin]+ss, tp);
   if nxttlk in [cequ, cltn, cgtn, cnequ, cnequa, clequ, clequa, cgequ, cgequa, 
                 cin] then begin

      gettlk; { next }
      { parse simple expression }
      parsexpr([cequ, cltn, cgtn, cnequ, clequ, cgequ, cin]+ss, tp1);

   end

end;

{******************************************************************************

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

******************************************************************************}

procedure parstatb(ss: tolkset);

var last: tolken;  { parsing aid }
    bl:   integer; { block nesting level }

begin

   if fparse then writeln(':statement block');
   stalvl := stalvl+1; { count statment level }
   bl := 1; { set nesting level }
   { expect 'begin' }
   expect(cbegin, ebgnexp, [cbegin, cend]+statuset+ss, [cbegin]);
   if uselvl = 0 then begin { not in uses file }

      wrtcod(ibgnblk); { begin statement block }
      repeat

         parstat([cscn, cend]+statuset+ss); { parse statement }
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
   stalvl := stalvl-1 { remove statement level }

end;

{******************************************************************************

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

******************************************************************************}

procedure parif(ss: tolkset);

var tp: typptr; { type pointer }

begin

   if fparse then writeln(':if statement');
   stalvl := stalvl+1; { count statment level }
   gettlk; { skip 'if' }
   parexpr([cthen, celse]+statuset+ss, tp); { parse expression }
   if not boolt(tp) and (tp^.t <> tudf) then 
      perror(etmbbol, [], []); { must be boolean type }
   wrtcod(iifbgn); { if begin }
   { expect 'then' }
   expect(cthen, ethnexp, [cthen, celse]+statuset+ss, [cthen]);
   if boolt(tp) and (tp^.t = tenme) then { constant condition }
      if consti(tp) = 0 then concon := concon+1; { increment delete level }
   parstat(ss); { parse statement }
   if boolt(tp) and (tp^.t = tenme) then { constant condition }
      if consti(tp) = 0 then concon := concon-1; { decrement delete level }
   { check if we have a candidate for an 'else' misspell }
   chktkm([celse]); { check possible misspelled tolken }
   if nxttlk = celse then begin { 'else' clause }

      gettlk; { next }
      wrtcod(ielse); { else }
      if boolt(tp) and (tp^.t = tenme) then { constant condition }
         if consti(tp) <> 0 then concon := concon+1; { increment delete level }
      parstat(ss); { parse statment }
      if boolt(tp) and (tp^.t = tenme) then { constant condition }
         if consti(tp) <> 0 then concon := concon-1; { decrement delete level }

   end;
   stalvl := stalvl-1; { remove statement level }
   wrtcod(iifend) { if end }

end;

{******************************************************************************

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

******************************************************************************}

procedure parcase(ss: tolkset);

var last:    tolken;  { parser aid }
    tp, tp1: typptr;  { pointer to type entry }
    bt:      typptr;  { base type }
    match:   boolean; { case match flag }

begin

   if fparse then writeln(':case statement');
   stalvl := stalvl+1; { count statment level }
   gettlk; { next }
   { parse expression }
   parexpr([cof, cinteger, cidentifier]+statuset+ss, tp); 
   { if the object is a string constant, this must be a character, so
     load it from the address }
   if tp^.t = tscst then wrtcod(ildichr);
   bt := baset(tp); { get base type of expression }
   if not ((bt^.t in [tinteger, tchar, tboolean, tenum, tudf]) or 
           chart(bt)) then begin

      perror(etmbord, [], []); { type must be ordinal }
      bt := gbludf { set undefined }

   end;
   wrtcod(icasbgn); { case begin }
   { expect 'of' }
   expect(cof, eofexp, [cof]+constset+statuset+ss, [cof]);
   repeat { section }

      match := false; { set no case matches }
      repeat { case label }

         { parse case constant }
         parconst([cend, ccln, cscn]+statuset+ss, tp1);
         { check is an ordinal constant }
         if not (tp1^.t in [ticst, tscst, tccst, tenme, tudf]) then begin

            perror(ecmborc, [], []); { must be ordinal }
            tp := gbludf { set undefined }

         end;
         { check is compatible with original case selector }
         if not typcmp(tp1, bt) then perror(ecascmp, [], []);
         { check selector and case label are both constants }
         if (tp^.t in [ticst, tscst, tccst, tenme]) and 
            (tp1^.t in [ticst, tscst, tccst, tenme]) then
            { if the selector matches the case, set case match. Then, the
              match status becomes an 'or' of all cases attached to this
              statement }
            if consti(tp) = consti(tp1) then match := true;
         wrtcod(icassint); { case select integer }
         if tp1^.t <> tudf then wrtnum(consti(tp1)); { value of selector }
         if (nxttlk <> ccma) and (nxttlk <> ccln) then
            { we don't have an exit tolken }
            perror(ecncmexp, [cend, ccln, ccma, cscn]+statuset+ss, 
                   []);
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
      parstat([cend, ccln, cscn]+statuset+ss); { parse statement }
      wrtcod(icasste); { mark case statement ends }
      if (tp^.t in [ticst, tscst, tccst, tenme]) and not match then 
         { selector constant, and not match, constant delete }
         concon := concon-1; { decrement delete level }
      if (nxttlk <> cend) and (nxttlk <> cscn) then 
         { 'end' or ';' expected }
         perror(eedscexp, [cend, ccln, cscn]+constset+ss, 
                [cend]);
      if nxttlk = cscn then gettlk; { skip ';' }
      if not (nxttlk in [cend]+constset) then { nowhere to go } 
         perror(eendexp, [cend, ccln]+constset+ss, [cend])

   { until no possible label or statement }
   until not (nxttlk in [ccln]+constset);
   if nxttlk = cend then gettlk; { skip 'end' }
   stalvl := stalvl-1; { remove statement level }
   wrtcod(icasend) { case end }

end;

{******************************************************************************

While statement

   whilestat = 'while' expr 'do' statement

Parses and generates a while statement. Accepts a tolken skip set.
Error recovery:

1. Crud before 'do' with skip to do.

2. Missing 'do' with skip to likely statement.

******************************************************************************}

procedure parwhile(ss: tolkset);

var tp: typptr;  { type pointer }

begin

   if fparse then writeln(':while statement');
   stalvl := stalvl+1; { count statment level }
   gettlk; { next }
   wrtcod(iwhlexp); { mark top of while loop }
   parexpr([cdo]+ss, tp); { parse expression }
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
   stalvl := stalvl-1; { remove statement level }
   wrtcod(iwhlend) { while end }

end;

{******************************************************************************

Repeat statement

   repeatstat = 'repeat' statement [ ; statement ].. 'until' expr

Parses and generates a repeat statement. Accepts a tolken skip 
set.
Error recovery:

1. Missing ';' between statements, skip to 'until' or next
likely statement.

2. Missing 'until', skip to ';', next likely statement.

******************************************************************************}

procedure parrepeat(ss: tolkset);

var last: tolken; { parser aid }
    tp:   typptr; { type pointer }

begin

   if fparse then writeln(':repeat statement');
   stalvl := stalvl+1; { count statment level }
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
      parexpr(ss, tp); { parse expression }
      if not boolt(tp) and (tp^.t <> tudf) then 
         perror(etmbbol, [], []); { must be boolean type }

   end;
   stalvl := stalvl-1; { remove statement level }
   wrtcod(irptend) { repeat end }

end;

{******************************************************************************

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

******************************************************************************}

procedure parfor(ss: tolkset);

var sp:           symptr;  { symbol pointer }
    tp, tp1, tp2: typptr;  { type pointers }
    bt:           typptr;  { base type }
    tk:           tolken;  { tolken save }
    cdel:         boolean; { constant operation delete }

begin

   if fparse then writeln(':for statement');
   stalvl := stalvl+1; { count statment level }
   gettlk; { next }
   if nxttlk <> cidentifier then { id expected }
      perror(eidnexp, [cbcms, cto, cdownto, cdo]+exprset+statuset+ss, []);
   tp := gbludf; { set defaults for variable type }
   bt := gbludf;
   if nxttlk = cidentifier then begin

      find(sp); { lookup symbol }
      tp := actt(sp^.typ); { index type of symbol }
      if (tp^.t <> tvar) and (tp^.t <> tudf) then begin { not simple variable }

         extlab := nxtlab; { place label for error }
         perror(elvarexp, [], []) { must be a local variable }
         
      end;
      if tp^.t = tvar then begin { simple variable }

         { check variable is a local, without "with" levels }
         if sp^.lvl <> level-wthlvl then perror(evarmbl, [], []);
         { check variable is external }
         if tp^.vare then perror(evarext, [], []);
         bt := baset(tp); { get base type }
         if not (bt^.t in [tenum, tinteger, tchar, tboolean, tudf]) then begin
  
            { not ordinal }
            perror(etmbord, [], []); { type must be ordinal }
            tp := gbludf { set undefined }

         end else begin { ok }

            if tp^.varf <> 0 then begin { in use by 'for' }

               copyp(extlab, sp^.lab^); { place error label }
               perror(eforviu, [], []) { variable in use }

            end;
            tp^.varr := tp^.varr + 1; { increment threat count }
            tp^.varf := tp^.varf + 1 { increment 'for' use count }

         end

      end;
      gettlk { skip ident }

   end;
   { expect ':=' }
   expect(cbcms, ebcmexp, [cto, cdownto, cdo]+exprset+statuset+ss, []);
   { parse starting expression }
   parexpr([cto, cdownto, cdo]+statuset+ss, tp1);
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
   parexpr([cdo]+statuset+ss, tp2); { parse ending expression }
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
      if tk = cto then cdel := consti(tp1) > consti(tp2)
      else if tk = cdownto then cdel := consti(tp1) < consti(tp2);
   if cdel then concon := concon+1; { increment delete level }
   parstat(ss); { parse statement }
   if cdel then concon := concon-1; { decrement delete level }
   if tp^.t = tvar then tp^.varf := tp^.varf - 1; { decrement 'for' use count }
   stalvl := stalvl-1; { remove statement level }
   wrtcod(iforend) { for end }

end;

{******************************************************************************

With statement

   with = 'with' variable [',' variable].. 'do' statement

Parses the with statement.
Error recovery:

1. No id, skip to ',', 'do' or likely statement. Short circuits
variable parse if head id not found.

2. No 'do', skip to ',' 'do', or likely statement.

******************************************************************************}

procedure parwith(ss: tolkset);

var last:    tolken;  { parsing aid }
    tp:      typptr;  { variable type pointer }
    levels:  integer; { scoping level save }
    sp, sp1: symptr;  { pointers for symbols }
    i:       syminx;  { index for symbol table }

begin

   if fparse then writeln(':with statement');
   stalvl := stalvl+1; { count statment level }
   wthlvl := wthlvl+1; { count "with" level }
   levels := level; { save old scoping level }
   gettlk; { skip 'with' }
   repeat { variables }

      parvarh([ccma, cdo]+ss, true, tp); { parse with variable with threat }
      tp := baset(tp); { index base type }
      if tp^.t <> trecord then perror(evarmbr, [], []);
      level := level + 1; { increase scoping level }
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
            sp1^.next := symtbl[i]; { place the next entry link }
            symtbl[i] := sp1; { plant our symbol }
            sp := sp^.rnxt { index next symbol in record list }

         end

      end;
      wrtcod(iwthbgn); { generate with begin }
      wrtlnk(tp); { output record type }
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
      wrtcod(iwthend) { generate with end }
      
   end;
   { purge all record labels from symbol table }
   for i := 1 to symmax do begin { traverse the symbols head }
      
      sp := symtbl[i]; { index the chain head }
      while sp <> nil do { flush up top symbols }
         if sp^.lvl > level then begin { symbol scope greater than present }
       
            sp1 := symtbl[i]; { index top symbol }
            symtbl[i] := sp^.next; { gap chain head }
            { because our symbols contain just a copy of the real symbol base
              pointer, we have to kill the reference. otherwise, this would
              be returned (incorrectly) to free storage }
            sp1^.lab := nil; { kill symbol reference }
            putsym(sp1); { release entry }
            sp := symtbl[i] { load the new top }

         end else sp := nil; { stop the search }

   end;
   wthlvl := wthlvl-1; { remove "with" level }
   stalvl := stalvl-1 { remove statement level }

end;

{******************************************************************************

Goto statement

   gotostat = 'goto' integer | 'goto' identifier

Parses and generates a goto statement. Accepts a tolken skip set.
Error recovery:

1. If the label is missing or the wrong type, skips to the
next likey statement.

******************************************************************************}

procedure pargoto(ss: tolkset); 

var sp: symptr; { symbol pointer }

begin

   if fparse then writeln(':goto statement');
   gettlk; { skip 'goto' }
   if (nxttlk = cinteger) or ((nxttlk = cidentifier) and not fansi) then begin

      if nxttlk = cinteger then begin { process numeric label }

         numlab; { convert and normalize label number }
         if nxtint > 9999 then { greater than ansi max ? }
            perror(einvgln, [], []); { invalid label number }

      end;
      find(sp); { lookup symbol }
      if (sp^.typ^.t <> tlab) and (sp^.typ^.t <> tudf) then { not a label }
         perror(esymtyp, [], []);
      if sp^.typ^.t = tlab then begin { is a label }

         sp^.typ^.lref := sp^.typ^.lref + 1; { count 'goto' references }
         { check 'goto' target statment level is valid }
         if sp^.typ^.slvl > stalvl then perror(egtolvl, [], []); { invalid }
         { set minimum reference statement level for errors }
         if stalvl < sp^.typ^.mlvl then sp^.typ^.mlvl := stalvl;
         { check if the label appears in a different block level than the
           goto statement. If so, we flag the label as referenced by an
           external block }
         if sp^.lvl <> level-wthlvl then sp^.typ^.extr := true

      end;
      gettlk; { skip label }
      wrtcod(igoto); { goto }
      wrtlnk(sp^.typ) { output label }

   end else { process error }
      if fansi then perror(eintexp, statuset+ss, []) { no integer }
      else perror(eilexp, statuset+ss, []); { no integer/label }

end;

{******************************************************************************

Parse procedure/function call

   procfncstat = identifier [ '(' expr [ ',' expr ].. ')' ]

Parses and generates a procedure or function call. Accepts a 
tolken skip set. Expects the identifier to already have been 
parsed.
Error recovery:

1. Missing ',', skip to likely expression, ')', or input set.

2. Missing ')', skip to input set.

******************************************************************************}

procedure parprcfnc(    ss: tolkset; { skip set }
                        pp: typptr;  { procedure/function pointer }
                    var tp: typptr); { return type }

var pl:  typptr;  { parameter list pointer }
    sp:  symptr;  { symbol pointer }
    tp1: typptr;  { pointer for types }
    bt:  typptr;  { base type }
    npe: boolean; { no parameter error registered }

begin

   if fparse then writeln(':procedure/function call');
   npe := false; { set no parameter error registered }
   { if we have been called without a proper head, this means that we were
     called because of what looked like a parameter list. An error has already
     been output, so just parse parameters only }
   if not (pp^.t in [tproc, tfunc, tpproc, tpfunc]) then begin

      pl := nil; { set no parameter list }
      npe := true { set error already occurred }

   end else case pp^.t of { index top of parameter list }

      tproc:  pl := pp^.prcp;
      tfunc:  pl := pp^.fncp;
      tpproc: pl := pp^.pprp;
      tpfunc: pl := pp^.pfnp 

   end;
   if (pp^.t = tproc) or (pp^.t = tpproc) then begin

         wrtcod(iprcbgn); { generate procedure parameter begin }
         wrtlnk(pp) { generate procedure entry }

   end else if (pp^.t = tfunc) or (pp^.t = tpfunc) then begin

         wrtcod(ifncbgn); { generate function parameter begin }
         wrtlnk(pp) { generate function entry }

   end;
   if nxttlk = clparen then begin { parameter list }

      repeat

         { skip only '(' or ',' in case of headless expression }
         if (nxttlk = clparen) or (nxttlk = ccma) then
            gettlk; { skip '(' or ',' }
         if pl = nil then begin { parameter does not exist }

            if not npe then begin { no error registered }

               perror(etmpar, [], []); { too many parameters }
               npe := true { set error registered }

            end;
            { we don't have a prototype, but try parsing an expression
              just to keep the parser moving }
            parexpr([ccma, crparen]+exprset+ss, tp)

         end else begin { parameter exists }

            if pl^.t = tpproc then begin { procedure parameter }

               if nxttlk <> cidentifier then { id expected }
                  perror(eidnexp, [ccma, crparen]+exprset+ss, []);
               if nxttlk = cidentifier then begin { found }

                  find(sp); { lookup symbol }
                  gettlk; { next }
                  tp1 := sp^.typ; { index type }
                  { check procedure label }
                  if (tp1^.t <> tproc) and (tp1^.t <> tpproc) then begin

                     copyp(extlab, sp^.lab^); { place error label }
                     perror(embproc, [], []) { must be procedure }

                  end else begin { type ok }

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

                  end

               end

            end else if pl^.t = tpfunc then begin { function parameter }

               if nxttlk <> cidentifier then { id expected }
                  perror(eidnexp, [ccma, crparen]+exprset+ss, []);
               if nxttlk = cidentifier then begin { found }

                  find(sp); { lookup symbol }
                  gettlk; { next }
                  tp1 := sp^.typ; { index type }
                  { check function label }
                  if (tp1^.t <> tfunc) and (tp1^.t <> tpfunc) then begin

                     copyp(extlab, sp^.lab^); { place error label }
                     perror(embfunc, [], []) { must be procedure }

                  end else begin { type ok }

                     if tp1^.t = tfunc then begin { function }

                        { check attempt to pass system function as parameter }
                        if tp1^.fncd <> pfnil then perror(esfnprp, [], [])
                        else begin { not system function }

                           { check types are congruous }
                           chkcon(pl^.pfnp, tp1^.fncp);
                           { check result types are not equal, and not
                             undefined }
                           if (pl^.pfnr <> tp1^.fncr) and 
                              (pl^.pfnr^.t <> tudf) and 
                              (tp1^.fncr^.t <> tudf) then 
                                 perror(efnncon, [], [])

                        end

                     end else begin { function parameter }

                        { check types are congruous }
                        chkcon(pl^.pfnp, tp1^.pfnp);
                        { check result types are not equal, and not undefined }
                        if (pl^.pfnr <> tp1^.pfnr) and 
                           (pl^.pfnr^.t <> tudf) and 
                           (tp1^.pfnr^.t <> tudf) then 
                              perror(efnncon, [], [])

                     end;
                     { load function address }
                     wrtcod(ilodadr); { output address load operator }
                     wrtlnk(tp1); { output entry to load }
                     { if the function is itself a parameter, load it's address }
                     if tp1^.t = tpfunc then wrtcod(ildiptr) { load pointer }

                  end

               end

            end else if (pl^.t = tpar) or (pl^.t = twpar) then begin 

               { value parameter or view parameter, parse expression }
               parexpr([ccma, crparen]+exprset+ss, tp);
               { check parameter assignment compatible with value parameter }
               if not typcmpa(pl, tp) then perror(eparcmp, [], []);
               { now atoms are on stack, structures addressed. The net 
                 difference between view and value parameters are that view
                 parameters leave structures addressed }
               if pl^.t = tpar then begin { handle value cases }
 
                  if (tp^.t in [tscst, trecord, tarray, tgarry]) then begin

                     { it's a structured value parameter. parexpr left that as
                       an address, as it should do. so we must trully load it
                       onto the stack as a copy }
                     if tp^.t = tgarry then begin { its a general array }

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
                     else begin { other structure }

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

               end else if pl^.t = twpar then begin { handle view cases }

                  if (pl^.wprt^.t = tgarry) and (tp^.t <> tgarry) then begin

                     { a fixed array is passed to a general array parameter,
                       we must convert the simple pointer on stack to a tagged
                       one }
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

               end

            end else begin { VAR parameter }

               { parse with variable with threat }
               parvarh([ccma, crparen]+exprset+ss, true, tp);
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
                  wrtcod(icvtftg); { convert fixed to tagged pointer }
                  wrtlnk(tp) { write fixed type }

               end else if (pl^.vprt^.t <> tgarry) and (tp^.t = tgarry) then
                  begin

                  { a general array passed to a fixed view, convert pointer
                    to fixed }
                  wrtcod(icvtgtf); { convert tagged to fixed pointer }
                  wrtlnk(pl^.vprt) { output fixed type }

               end

            end

         end;
         { advance to next parameter }
         if pl <> nil then { not at end of parameter list }
            case pl^.t of { parameter, find next entry }

            tpar:   pl := pl^.parn;
            tvpar:  pl := pl^.vprn;
            twpar:  pl := pl^.wprn;
            tpproc: pl := pl^.pprn;
            tpfunc: pl := pl^.pfnn

         end;
         if (nxttlk <> ccma) and (nxttlk <> crparen) then
            { process error }
            perror(erpcmexp, [ccma, crparen]+exprset+ss, [])

      { until not ',' or likely expression }
      until not (nxttlk in [ccma]+exprset);
      if nxttlk = crparen then gettlk { skip ')' }

   end;
   if pl <> nil then perror(etlpar, [], []); { too few parameters }
   { set return type for function, undefined if procedure or unknown }
   if pp^.t = tfunc then tp := pp^.fncr
   else if pp^.t = tpfunc then tp := pp^.pfnr
   else tp := gbludf;
   if (pp^.t = tpproc) or (pp^.t = tpfunc) then begin

      { procedure/function parameter, must load address }
      wrtcod(ilodadr); { output address load operator }
      wrtlnk(pp); { output entry to load }
      wrtcod(ildiptr) { load the parameter }

   end;
   { generate call code }
   if pp^.t in [tproc, tfunc, tpproc, tpfunc] then begin

      case pp^.t of { type }

         tproc:  wrtcod(iprccal);
         tfunc:  wrtcod(ifnccal);
         tpproc: wrtcod(iprccali);
         tpfunc: wrtcod(ifnccali)
      
      end;
      wrtlnk(pp) { output procedure/function entry }

   end

end;

{******************************************************************************

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

******************************************************************************}

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
         parexpr([ccma, ccln, crparen]+exprset+ss, tp);
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
               if not ((bt^.t in [tudf, tinteger, tchar, tboolean, treal, 
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
               parexpr([ccma, ccln, crparen]+exprset+ss, tp1);
               bt := baset(tp1); { get base type }
               if not (bt^.t in [tudf, tinteger]) then { wrong type }
                  perror(efldpar, [], []); { invalid field spec }
               if nxttlk = ccln then begin { fraction parameter }
            
                  gettlk; { next }
                  { check is applied to real parameter }
                  if not (realt(tp) or (tp^.t = tudf)) then 
                     perror(eapreal, [], []); { must be applied to real }
                  { parse expression }
                  parexpr([ccma, ccln, crparen]+exprset+ss, tp1);
                  bt := baset(tp1); { get base type }
                  if not (bt^.t in [tudf, tinteger]) then { wrong type }
                     perror(efrcpar, [], []); { invalid field spec }
                  { write real with field and fraction }
                  wrtcod(iwrtrelfft)
            
               end else begin { fielded parameter }
            
                  bt := baset(tp); { find base type }
                  if bt^.t = tinteger then 
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
               if bt^.t = tinteger then 
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
               else if (bt^.t in [tinteger, tenum, tptr]) or chart(bt) then
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

{******************************************************************************

Parse read/readln procedure

******************************************************************************}

procedure parreadln(ss: tolkset; { skip set }
                    dc: prcfnc); { function dispatch code }

var tp:     typptr; { type pointer }
    fstpar: boolean; { first parameter flag }
    fs:     typptr;  { output file specification }
    ft:     boolean; { output filetype is text }
    last:   tolken;  { parsing aid }
    bt:     typptr;  { base type }
    parp:   boolean; { parameter parsed flag }

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
         parvarh([ccma, crparen]+exprset+ss, true, tp);
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
               if not (bt^.t in [tudf, tinteger, tchar, treal, tsreal]) then
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
               if bt^.t = tinteger then wrtcod(iredintt) { read integer }
               else if bt^.t = tchar then wrtcod(iredchrt) { read character }
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
            perror(erpcmexp, [ccma, ccln, crparen]+exprset+ss, []);
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

{******************************************************************************

Parse arithmetic function

******************************************************************************}

procedure pararthfnc(    ss: tolkset; { skip set }
                         dc: prcfnc;  { function dispatch code }
                     var tp: typptr); { return type }

var ti:    integer; { temp integer }
    tr:    real;    { temp real }
    solve: boolean; { solved constant flag }
    bt:    typptr;  { base type }

begin

   if fparse then writeln(':arithmetic function');
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   parexpr([crparen]+ss, tp); { parse parameter }
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
      if tp^.t = trcst then tr := tp^.rval else tr := tp^.ival; { get value }
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

         pfabs: ti := abs(tp^.ival); { abs }
         pfsqr: ti := sqr(tp^.ival)  { sqr }   

      end;
      lsttyp(tp, ticst); { get a new integer entry }
      tp^.ival := ti { place result }

   end else solve := false; { set not solved constant }
   if not solve then begin { not a solved constant, find result type }

      tp := baset(tp); { set same type result as input }
      { check real result functions }
      if dc in [pfsqrt, pfsin, pfarctan, pfexp, pfln, pfcos] then tp := gblreal

   end

end;

{******************************************************************************

Parse chr function

******************************************************************************}

procedure parchr(    ss: tolkset; { skip set }
                 var tp: typptr); { return type }

var tp1: typptr; { type pointer }

begin

   if fparse then writeln(':chr function');
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   parexpr([crparen]+ss, tp); { parse parameter }
   { check integer }
   if not (intt(tp) or (tp^.t = tudf)) then 
      perror(embint, [], []); { must be integer }
   expect(crparen, erpexp, ss, []); { expect ')' }
   if tp^.t = ticst then begin { resolve constant }

      if (tp^.ival < lbound(gblchr)) or (tp^.ival > ubound(gblchr)) then begin

         { value out of range for character }
         perror(erange, [], []);
         tp := gblchr { set result type char }

      end else begin { form constant }

         lsttyp(tp1, tccst); { get a character constant type entry }
         tp1^.cval := chr(tp^.ival); { place value }
         tp := tp1 { place result }

      end

   end else tp := gblchr { set result type char }

end;

{******************************************************************************

Parse eof/eoln function

******************************************************************************}

procedure pareofeoln(    ss: tolkset; { skip set }
                         dc: prcfnc;  { function dispatch code }
                     var tp: typptr); { return type }

var it: typptr; { input file type holder }

begin

   if fparse then writeln(':eof/eoln function');
   it := gblinp; { default input file type to input }
   if nxttlk = clparen then begin { file parameter exists }

      expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
      parexpr([crparen]+ss, it); { parse parameter }
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

{******************************************************************************

Parse odd function

******************************************************************************}

procedure parodd(    ss: tolkset; { skip set }
                 var tp: typptr); { return type }

begin

   if fparse then writeln(':odd function');
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   parexpr([crparen]+ss, tp); { parse parameter }
   { check integer }
   if not (intt(tp) or (tp^.t = tudf)) then 
      perror(embint, [], []); { must be integer }
   expect(crparen, erpexp, ss, []); { expect ')' }
   wrtcod(iodd); { odd }
   if tp^.t = ticst then begin { resolve constant }

      { assign true or false entry value }
      if odd(tp^.ival) then tp := gbltrue else tp := gblfalse

   end else tp := gblbool { set result type boolean }

end;

{******************************************************************************

Parse ord, succ and pred function

******************************************************************************}

procedure parordprsc(    ss: tolkset; { skip set }
                         dc: prcfnc;  { function dispatch code }
                     var tp: typptr); { return type }

var tp1, tp2: typptr;  { type pointer }
    ti:       integer; { temp integer }
    solve:    boolean; { constant solved flag }

begin

   if fparse then writeln(':ord/succ/pred function');
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   parexpr([crparen]+ss, tp); { parse parameter }
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
         tp1^.ival := consti(tp) { get the constant value }

      end else begin { succ, pred }

         solve := true; { set constant solved }
         ti := consti(tp); { get the value }
         { validate for overflow. Note we avoid actually performing
           the overflowing operation, since that could trip a compiler
           error }
         if dc = pfsucc then begin { succ }
  
            if ti = ubound(tp) then begin { overflow }

               perror(erange, [], []); { out of range }
               solve := false { set not solved }

            end else ti := ti+1 { find succ }

         end else begin { pred }

            if ti = lbound(tp) then begin { overflow }

               perror(erange, [], []);
               solve := false { set not solved }

            end else ti := ti-1 { find pred }
  
         end;
         if solve then { constant was solved }
            if tp^.t = ticst then begin { result is integer }
  
               lsttyp(tp1, ticst); { get an integer constant type entry }
               tp1^.ival := ti { place value }

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

{******************************************************************************

Parse round/trunc function

******************************************************************************}

procedure parrndtrc(    ss: tolkset; { skip set }
                        dc: prcfnc;  { function dispatch code }
                    var tp: typptr); { return type }

var tp1: typptr; { type pointer }

begin

   if fparse then writeln(':round/trunc function');
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   parexpr([crparen]+ss, tp); { parse parameter }
   { check real }
   if not (realt(tp) or (tp^.t = tudf)) then perror(embrl, [], []);
   expect(crparen, erpexp, ss, []); { expect ')' }
   if dc = pfround then wrtcod(irnd) { round }
   else wrtcod(itrc); { trunc }
   if tp^.t = trcst then begin { resolve constant }

      lsttyp(tp1, ticst); { get an integer constant type entry }
      { resolve constant }
      if dc = pftrunc then tp1^.ival := trunc(tp^.rval) { trunc }
      else tp1^.ival := round(tp^.rval); { round }
      tp := tp1 { place result }
      
   end else tp := gblint { set integer result }

end;

{******************************************************************************

Parse exists function

******************************************************************************}

procedure parexists(    ss: tolkset; { skip set }
                    var tp: typptr); { return type }

begin

   if fparse then writeln(':exists function');
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   parexpr([crparen]+ss, tp); { parse parameter }
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

{******************************************************************************

Parse location/length functions

******************************************************************************}

procedure parloclen(    ss: tolkset; { skip set }
                        dc: prcfnc;  { function dispatch code }
                    var tp: typptr); { return type }

var tp1: typptr; { type pointer }
    sp:  symptr; { symbol pointer }

begin

   if fparse then writeln(':location/length function');
   expect(clparen, elpexp, [clparen, cidentifier]+ss, []); { expect '(' }
   tp := gbludf; { set result undefined }
   sp := nil; { set no head symbol }
   { parse variable head }
   if nxttlk <> cidentifier then { id expected }
      perror(evidexp, [cidentifier, cperiod, ccmf, crparen]+ss, []);
   if nxttlk in [cidentifier, cperiod, ccmf] then begin 

      { found, or likely start found }
      if nxttlk = cidentifier then begin { id found }

         find(sp); { lookup symbol }
         gettlk; { next }
         tp := sp^.typ; { set head type }

      end;
      { check operating on special file }
      if tp^.t = tvar then { variable }
         if (tp^.vars <> fsnone) and (tp^.vars <> fsherr) then
            perror(eoivspf, [], []);
      parvar([crparen]+ss, sp, false, tp)

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

{******************************************************************************

Parse max function

******************************************************************************}

procedure parmax(    ss: tolkset; { skip set }
                 var tp: typptr); { return type }

begin

   if fparse then writeln(':max function');
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   parvarh([crparen]+ss, false, tp); { parse parameter }
   { check general array }
   if not (tp^.t in [tgarry, tudf]) then perror(embgar, [], []);
   expect(crparen, erpexp, ss, []); { expect ')' }
   wrtcod(ilodlen); { find length }
   wrtlnk(tp); { output array type }
   tp := gblint { set integer result }

end;

{******************************************************************************

Parse new/dispose procedure procedure

******************************************************************************}

procedure pardispnew(ss: tolkset; { skip set }
                     dc: prcfnc); { function dispatch code }

var tp, tp1: typptr;  { type pointers }
    last:    tolken;  { parsing aid }
    n:       integer; { case value holder }

begin

   if fparse then writeln(':new/dispose procedure');
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   { parse pointer to operate on }
   if dc = pfnew then { 'new' }
      parvarh([ccma, crparen]+exprset+ss, true, tp) { parse variable }
   else
      parexpr([ccma, crparen]+exprset+ss, tp); { parse expression }
   { check pointer }
   if (tp^.t <> tptr) and (tp^.t <> tudf) then perror(embptr, [], []);
   if (tp^.t = tptr) then if tp^.ptrt^.t = tgarry then begin

      { it's a general array }
      if dc = pfnew then begin { 'new' }

         expect(ccma, ecmaexp, [ccma, crparen]+exprset+ss, []); { expect ',' }
         parexpr([crparen]+exprset+ss, tp1); { parse length expression }
         if not intt(tp1) then perror(embint, [], []); { must be integer }
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
               wrtnum(consti(tp1)); { output tagfield constant }
            if (nxttlk <> ccma) and (nxttlk <> crparen) then
               { process error }
               perror(erpcmexp, [ccma, ccln, crparen]+exprset+ss, []);
            { check we have a valid access }
            if (tp^.t = tftag) and (tp1^.t <> tudf) then begin

               { access valid, find the case selected }
               n := consti(tp1); { get the case select constant }
               tp := tp^.ftgc; { index top of case constant list }
               tp1 := nil; { clear found }
               while tp <> nil do begin { traverse }

                  { check matches, terminate if so }
                  if tp^.fcsc = n then begin tp1 := tp; tp := nil end
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

   end;
   expect(crparen, erpexp, ss, []); { expect ')' }

end;

{******************************************************************************

Parse get/put/reset/rewrite/close procedure

******************************************************************************}

procedure pargetputresrewcls(ss: tolkset; { skip set }
                             dc: prcfnc); { function dispatch code }

var tp: typptr; { type pointer }
    sp: symptr; { symbol pointer }

begin

   if fparse then writeln(':get/put/reset/rewrite/close procedure');
   expect(clparen, elpexp, [clparen, cidentifier]+ss, []); { expect '(' }
   tp := gbludf; { set result undefined }
   sp := nil; { set no head symbol }
   { parse variable head }
   if nxttlk <> cidentifier then { id expected }
      perror(evidexp, [cidentifier, cperiod, ccmf, crparen]+ss, []);
   if nxttlk in [cidentifier, cperiod, ccmf] then begin 

      { found, or likely start found }
      if nxttlk = cidentifier then begin { id found }

         find(sp); { lookup symbol }
         gettlk; { next }
         tp := sp^.typ; { set head type }

      end;
      { check operating on special file }
      if tp^.t = tvar then { variable }
         if (tp^.vars <> fsnone) and (tp^.vars <> fsherr) and
            (dc in [pfreset, pfrewrite, pfclose]) then
            perror(eoivspf, [], []);
      parvar([crparen]+ss, sp, false, tp)

   end;
   { check file }
   if not (filet(tp) or (tp^.t = tudf)) then perror(embfil, [], []);
   expect(crparen, erpexp, ss, []); { expect ')' }
   case dc of { procedure }

      pfget:     if tp^.t = ttext then wrtcod(igett) { get }
                 else wrtcod(iget);
      pfput:     wrtcod(iput);     { put }
      pfreset:   begin wrtcod(ireset); wrtlnk(tp) end; { reset }
      pfrewrite: begin wrtcod(irewrite); wrtlnk(tp) end; { rewrite }
      pfclose:   wrtcod(iclose)    { close }

   end

end;

{******************************************************************************

Parse pack procedure

******************************************************************************}

procedure parpack(ss: tolkset); { skip set }

var tp, tp1, tp2, ttp, ttp2: typptr;  { type pointers }
    ti:                      integer; { constant holding }

begin

   if fparse then writeln(':pack procedure');
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   { parse unpacked variable }
   parvarh([ccma, crparen]+exprset+ss, false, tp);
   if not (tp^.t in [tarray, tgarry, tudf]) then 
      perror(embarr, [], []); { must be array }
   if tp^.t in [tarray, tgarry] then if tp^.pack then 
      perror(embupk, [], []); { must be unpacked }
   expect(ccma, ecmaexp, [ccma, crparen]+exprset+ss, []); { expect ',' }
   parexpr([ccma, crparen]+ss, tp1); { parse starting index }
   { if the object is a string constant, this must be a character, so
     load it from the address }
   if tp1^.t = tscst then wrtcod(ildichr);
   if tp^.t = tarray then { check index compatible }
      if not typcmpa(tp^.arri, tp1) then perror(eidxcmp, [], [])
      else if tp1^.t in [ticst, tscst, tccst, tenme] then begin 

      { index is constant, check for bounds }
      ti := consti(tp1); { get index value }
      if (ti < lbound(tp^.arri)) or (ti > ubound(tp^.arri)) then
         perror(epupbnd, [], []) { array reference bounds }

   end else if tp^.t = tgarry then { check index compatible }
      if not intt(tp1) then perror(eidxcmp, [], []);
   expect(ccma, ecmaexp, [ccma, crparen]+exprset+ss, []); { expect ',' }
   { parse packed variable with threat }
   parvarh([crparen]+ss, true, tp2); { parse with variable with threat }
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

         { check the "span" of the operation is correct }
         ti := consti(tp1); { get the index value }
         { find if the starting index plus the span of the operation would
           result in an access beyond the end of the source array.
           this operation could theoretically overflow in the compiler }
         if ti+(ubound(tp2^.arri)-lbound(tp2^.arri)) > 
            ubound(tp^.arri) then perror(epupbnd, [], [])

      end

   end;
   wrtcod(ipack); { pack }
   wrtlnk(tp2); { output packed type }
   wrtlnk(tp) { output unpacked type }

end;

{******************************************************************************

Parse unpack procedure

******************************************************************************}

procedure parunpack(ss: tolkset); { skip set }

var tp, tp1, tp2, ttp, ttp2: typptr; { type pointers }
    ti:                      integer; { constant holding }

begin

   if fparse then writeln(':unpack procedure');
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   { parse packed variable }
   parvarh([ccma, crparen]+exprset+ss, false, tp);
   if not (tp^.t in [tarray, tgarry, tudf]) then 
      perror(embarr, [], []); { must be array }
   if tp^.t in [tarray, tgarry] then if not tp^.pack then 
      perror(embpk, [], []); { must be packed }
   expect(ccma, ecmaexp, [ccma, crparen]+exprset+ss, []); { expect ',' }
   { parse unpacked variable with threat }
   parvarh([ccma, crparen]+exprset+ss, true, tp2);
   if not (tp^.t in [tarray, tgarry, tudf]) then 
      perror(embarr, [], []); { must be array }
   if tp2^.t in [tarray, tgarry] then if tp2^.pack then 
      perror(embupk, [], []); { must be unpacked }
   expect(ccma, ecmaexp, [ccma, crparen]+exprset+ss, []); { expect ',' }
   parexpr([crparen]+ss, tp1); { parse starting index }
   { if the object is a string constant, this must be a character, so
     load it from the address }
   if tp1^.t = tscst then wrtcod(ildichr);
   if tp2^.t = tarray then { check index compatible }
      if not typcmpa(tp2^.arri, tp1) then perror(eidxcmp, [], [])
      else if (tp1^.t in [ticst, tscst, tccst, tenme]) and 
              (tp^.t <> tgarry) then begin

      { index is constant, check for bounds }
      ti := consti(tp1); { get index value }
      if (ti < lbound(tp2^.arri)) or (ti > ubound(tp2^.arri)) then
         perror(epupbnd, [], []) { array reference bounds }
      else begin { check the "span" of the operation is correct }

         { find if the starting index plus the span of the operation would
           result in an access beyond the end of the source array.
           this operation could theoretically overflow in the compiler }
         if ti+(ubound(tp^.arri)-lbound(tp^.arri)) > 
            ubound(tp2^.arri) then perror(epupbnd, [], [])

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

{******************************************************************************

Parse page procedure

******************************************************************************}

procedure parpage(ss: tolkset); { skip set }

var tp: typptr; { type pointer }

begin

   if fparse then writeln(':page procedure');
   if nxttlk = clparen then begin { file parameter exists }

      gettlk; { skip '(' }
      parexpr([crparen]+ss, tp); { parse parameter }
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

{******************************************************************************

Parse assign procedure 

******************************************************************************}

procedure parassign(ss: tolkset); { skip set }

var tp, tp1: typptr; { type pointer }
    sp:      symptr; { symbol pointer }

begin

   if fparse then writeln(':assign procedure');
   expect(clparen, elpexp, [clparen, cidentifier]+ss, []); { expect '(' }
   tp := gbludf; { set result undefined }
   sp := nil; { set no head symbol }
   { parse variable head }
   if nxttlk <> cidentifier then { id expected }
      perror(evidexp, [cidentifier, cperiod, ccmf, crparen, ccma]+ss, []);
   if nxttlk in [cidentifier, cperiod, ccmf] then begin 

      { found, or likely start found }
      if nxttlk = cidentifier then begin { id found }

         find(sp); { lookup symbol }
         gettlk; { next }
         tp := sp^.typ; { set head type }

      end;
      { check operating on special file }
      if tp^.t = tvar then { variable }
         if (tp^.vars <> fsnone) and (tp^.vars <> fsherr) then
            perror(eoivspf, [], []);
      threaten(sp, tp); { threaten the variable }
      parvar([crparen, ccma]+ss, sp, false, tp)

   end;
   { check file }
   if not (filet(tp) or (tp^.t = tudf)) then perror(embfil, [], []);
   expect(ccma, ecmaexp, ss, []); { expect ',' }
   parexpr([crparen]+ss, tp1); { parse parameter }
   { check string }
   if not (strt(tp1) or (tp1^.t = tudf)) then perror(embstr, [], []);
   expect(crparen, erpexp, ss, []); { expect ')' }
   if tp1^.t <> tgarry then begin { convert fixed to general array }

      wrtcod(icvtftg); { convert fixed to tagged pointer }
      wrtlnk(tp1) { write fixed type }
      
   end;
   wrtcod(iassign) { open }

end;

{******************************************************************************

Parse position procedure

******************************************************************************}

procedure parposition(ss: tolkset); { skip set }

var tp: typptr; { type pointer }
    sp: symptr; { symbol pointer }

begin

   if fparse then writeln(':position procedure');
   expect(clparen, elpexp, [clparen, cidentifier]+ss, []); { expect '(' }
   tp := gbludf; { set result undefined }
   sp := nil; { set no head symbol }
   { parse variable head }
   if nxttlk <> cidentifier then { id expected }
      perror(evidexp, [cidentifier, cperiod, ccmf, crparen]+ss, []);
   if nxttlk in [cidentifier, cperiod, ccmf] then begin 

      { found, or likely start found }
      if nxttlk = cidentifier then begin { id found }

         find(sp); { lookup symbol }
         gettlk; { next }
         tp := sp^.typ; { set head type }

      end;
      { check operating on special file }
      if tp^.t = tvar then { variable }
         if (tp^.vars <> fsnone) and (tp^.vars <> fsherr) then
            perror(eoivspf, [], []);
      parvar([crparen]+ss, sp, false, tp)

   end;
   { check file }
   if not (filet(tp) or (tp^.t = tudf)) then perror(embfil, [], []);
   expect(ccma, ecmaexp, ss, []); { expect ',' }
   parexpr([crparen]+ss, tp); { parse parameter }
   { check integer }
   if not (intt(tp) or (tp^.t = tudf)) then perror(embint, [], []);
   expect(crparen, erpexp, ss, []); { expect ')' }
   wrtcod(ipos) { position }

end;

{******************************************************************************

Parse delete procedure

******************************************************************************}

procedure pardelete(ss: tolkset); { skip set }

var tp: typptr; { type pointer }

begin

   if fparse then writeln(':delete procedure');
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   parexpr([crparen]+ss, tp); { parse parameter }
   { check string }
   if not (strt(tp) or (tp^.t = tudf)) then perror(embstr, [], []);
   expect(crparen, erpexp, ss, []); { expect ')' }
   if tp^.t <> tgarry then begin { convert fixed to general array }

      wrtcod(icvtftg); { convert fixed to tagged pointer }
      wrtlnk(tp) { write fixed type }
      
   end;
   wrtcod(idel) { delete }

end;

{******************************************************************************

Parse change procedure

******************************************************************************}

procedure parchange(ss: tolkset); { skip set }

var tp, tp1: typptr; { type pointers }

begin

   if fparse then writeln(':change procedure');
   expect(clparen, elpexp, [clparen]+exprset+ss, []); { expect '(' }
   parexpr([crparen]+ss, tp); { parse destination parameter }
   { check string }
   if not (strt(tp) or (tp^.t = tudf)) then perror(embstr, [], []);
   if tp^.t <> tgarry then begin { convert fixed to general array }

      wrtcod(icvtftg); { convert fixed to tagged pointer }
      wrtlnk(tp) { write fixed type }
      
   end;
   expect(ccma, ecmaexp, ss, []); { expect ',' }
   parexpr([crparen]+ss, tp1); { parse source parameter }
   { check string }
   if not (strt(tp1) or (tp1^.t = tudf)) then perror(embstr, [], []);
   if tp1^.t <> tgarry then begin { convert fixed to general array }

      wrtcod(icvtftg); { convert fixed to tagged pointer }
      wrtlnk(tp1) { write fixed type }
      
   end;
   expect(crparen, erpexp, ss, []); { expect ')' }
   wrtcod(ichg) { change }

end;

{******************************************************************************

Parse halt procedure

******************************************************************************}

procedure parhalt;

begin

   if fparse then writeln(':halt procedure');
   wrtcod(ihalt) { halt }

end;

{******************************************************************************

Parse procedure or function internal

Given a procedure/function entry, separates out built - in
procedures/functions, and executes the parser for those.

******************************************************************************}
 
procedure parprcfnci(    ss: tolkset; { skip set }
                         pp: typptr;  { procedure/function entry }
                     var tp: typptr); { return type }

var dc: prcfnc; { procedure/function dispatch code }

begin

   if fparse then writeln(':parse procedure or function internal');
   { get dispatch code }
   if pp^.t = tfunc then dc := pp^.fncd 
   else if pp^.t = tproc then dc := pp^.prcd
   else dc := pfnil; { else default to general (it's a parameter) }
   case dc of { procedure/function }

      pfnil:      parprcfnc(ss, pp, tp);      { p/f: general 
                                                     procedure/function }
      pfabs:      pararthfnc(ss, dc, tp);     { f: abs }
      pfarctan:   pararthfnc(ss, dc, tp);     { f: arctan }  
      pfchr:      parchr(ss, tp);             { f: chr }    
      pfcos:      pararthfnc(ss, dc, tp);     { f: cos }    
      pfeof:      pareofeoln(ss, dc, tp);     { f: eof }   
      pfeoln:     pareofeoln(ss, dc, tp);     { f: eoln }    
      pfexp:      pararthfnc(ss, dc, tp);     { f: exp }     
      pfln:       pararthfnc(ss, dc, tp);     { f: ln }    
      pfodd:      parodd(ss, tp);             { f: odd }    
      pford:      parordprsc(ss, dc, tp);     { f: ord }   
      pfpred:     parordprsc(ss, dc, tp);     { f: pred }  
      pfround:    parrndtrc(ss, dc, tp);      { f: round }   
      pfsin:      pararthfnc(ss, dc, tp);     { f: sin }    
      pfsqr:      pararthfnc(ss, dc, tp);     { f: sqr }   
      pfsqrt:     pararthfnc(ss, dc, tp);     { f: sqrt }   
      pfsucc:     parordprsc(ss, dc, tp);     { f: succ }  
      pftrunc:    parrndtrc(ss, dc, tp);      { f: trunc } 
      pfexists:   parexists(ss, tp);          { f: exists }
      pflocation: parloclen(ss, dc, tp);      { f: location }
      pflength:   parloclen(ss, dc, tp);      { f: length }
      pfmax:      parmax(ss, tp);             { f: max }
      pfdispose:  pardispnew(ss, dc);         { p: dispose }
      pfget:      pargetputresrewcls(ss, dc); { p: get }    
      pfnew:      pardispnew(ss, dc);         { p: new }   
      pfpack:     parpack(ss);                { p: pack }   
      pfpage:     parpage(ss);                { p: page }    
      pfput:      pargetputresrewcls(ss, dc); { p: put }   
      pfread:     parreadln(ss, dc);          { p: read } 
      pfreadln:   parreadln(ss, dc);          { p: readln }  
      pfreset:    pargetputresrewcls(ss, dc); { p: reset }
      pfrewrite:  pargetputresrewcls(ss, dc); { p: rewrite } 
      pfunpack:   parunpack(ss);              { p: unpack } 
      pfwrite:    parwrite(ss, dc);           { p: write } 
      pfwriteln:  parwrite(ss, dc);           { p: writeln } 
      pfassign:   parassign(ss);              { p: assign }  
      pfclose:    pargetputresrewcls(ss, dc); { p: close }  
      pfposition: parposition(ss);            { p: position }
      pfdelete:   pardelete(ss);              { p: delete }  
      pfchange:   parchange(ss);              { p: change }  
      pfhalt:     parhalt;                    { p: change }  
   
   end;
   { if procedure, then result is undefined }
   if pp^.t = tproc then tp := gbludf

end;

{******************************************************************************

Parse assignment

   assstat    = variable ':=' expr
  
Parses and generates an assignment. Accepts a tolken skip set.
The left side is already parsed, and the type is passed.

******************************************************************************}

procedure parass(ss: tolkset; { skip set }
                 tp: typptr); { head symbol }

var tp1: typptr;  { type pointer }
    ti:  integer; { temp integer holder }
    bt:  typptr;  { base type }

begin

   if fparse then writeln(':assignment');
   parexpr(ss, tp1); { parse expression }
   { check assignment compatible with destination }
   if not typcmpa(tp, tp1) then begin

      perror(easscmp, [], []); { not assignment compatible }
      tp := gbludf; { set both types undefined }
      tp1 := gbludf

   end;
   bt := baset(tp); { find base of variable }
   if bt^.t in [tinteger, tenum] then wrtcod(istiint) { store integer }
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

      if bt^.ptrt^.t = tgarry then begin { general array pointer }

         { if being assigned from nil, convert to wide }
         if tp1^.t = tnil then wrtcod(icvtntg);
         wrtcod(istitgp) { store tagged pointer }

      end else { normal pointer }
         wrtcod(istiint) { store integer }

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

      { check constant fits range of destination }
      ti := consti(tp1); { get index value }
      if (ti < lbound(tp)) or (ti > ubound(tp)) then
         perror(eassrng, [], []) { out of range }

   end

end;

{******************************************************************************

Process label define

Processes a label location define on the passed symbol.

******************************************************************************}

procedure deflab(sp: symptr); { label to define }

var labsav: labl; { label save }

begin

   if fparse then writeln(':label define');
   if (sp^.typ^.t <> tlab) and (sp^.typ^.t <> tudf) then begin 

      { not a label }
      labsav := nxtlab; { save current label }
      copyp(nxtlab, sp^.lab^); { place errant label }
      perror(esymtyp, [], []);
      nxtlab := labsav { restore label }

   end else if sp^.typ^.t = tlab then begin { is a valid label }

      { check label already defined }
      if sp^.typ^.ldef then perror(elabdef, [], []);
      { check definition is in same block as declared }
      if sp^.lvl <> level then perror(elabblk, [], []); { not same block }
      { check block external references exist, and the label does not
        appear in the statement sequence of the defining block, as
        required by the standard. If the statement level is 1, or no
        block external references exists, then the check for lesser
        references is valid }
      if sp^.typ^.extr and (stalvl <> 1) then perror(elabext, [], [])
      else { check any references have occurred at lesser statement level }
         if sp^.typ^.mlvl < stalvl then perror(elabrlv, [], []); { invalid }
      sp^.typ^.ldef := true; { set label has been defined }
      sp^.typ^.slvl := stalvl; { set statement level of label }
      wrtcod(ilabequ); { output label equation }
      wrtlnk(sp^.typ) { output label type }

   end

end;

{******************************************************************************

Parse simple statement

   label      = integer | identifier
  
   kstatement = assstat |  funasstat | procfncstat |
                blockstat | ifstat | casestat |
                while | repeat | for | with |
                goto | null

   assstat    = variable ':=' expr
  
   funassstat = indentifier ':=' expr
                    
Parses and generates a simple statement. Accepts a tolken skip set.

******************************************************************************}

procedure parsstat(ss: tolkset; { skip set }
                   sp: symptr); { head symbol }


var tp, tp1: typptr; { type pointers }
    bt:      typptr; { base type pointer }

begin

   if fparse then writeln(':simple statement');
   if nxttlk = cbcms then begin { function or variable assign }

      tp := gbludf; { set default for no symbol }
      if sp <> nil then tp := sp^.typ; { set type if present }
      if tp^.t = tfunc then begin { function result assign }

         { check the function label is the current function }
         if sp^.typ <> curprc then begin { no }

            copyp(extlab, sp^.lab^); { place error label }
            perror(efaslvl, [], []) { function assign not this level }

         end;
         wrtcod(ilodfadr); { load function result address }
         wrtlnk(tp); { output function type }
         gettlk; { skip ':=' }
         parexpr(ss, tp1); { parse expression }
         { if the object is a string constant, this must be a character, so
           load it from the address. this is of course reliant on function
           results being unstructured }
         if tp1^.t = tscst then wrtcod(ildichr);
         { we need to bypass this section if the function is not the correct
           one, because this messes with the wrong function, or even a system
           function ! }
         if sp^.typ = curprc then begin { assignment is correct }

               { check assignment compatible with function result }
               if not typcmpa(sp^.typ^.fncr, tp1) then perror(easscmp, [], []);
               sp^.ref := sp^.ref - 1; { back out superfluous reference }
               sp^.typ^.fncc := sp^.typ^.fncc + 1; { count function references }
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

            end else if bt^.t in [tinteger, tenum, tnil] then
               wrtcod(istifint) { store integer }
            else if bt^.t = tsreal then 
               wrtcod(istifsrl) { store short real }
            else if bt^.t = treal then wrtcod(istifrel) { store short real }
            else if chart(bt) then wrtcod(istifchr) { store character }
            else wrtcod(istifbol); { store boolean }
            wrtlnk(tp) { output function type }

         end

      end else begin { variable assign }

         { we have established by context that the label is a variable
           reference, so we process it as a variable }
         threaten(sp, tp); { process threat }
         parvar(ss, sp, false, tp); { parse variable }
         gettlk; { skip ':=' }
         parass(ss, tp) { process assignment }

      end

   end else if nxttlk in [clparen, cend, cscn, cuntil, celse] then begin

      { check procedure label }
      if (sp^.typ^.t <> tproc) and (sp^.typ^.t <> tpproc) and
         (sp^.typ^.t <> tudf) then begin

         copyp(extlab, sp^.lab^); { place error label }
         perror(embproc, [], []) { must be procedure }

      end;
      if sp^.typ^.t <> tudf then { not undefined }
         parprcfnci(ss, sp^.typ, tp) { parse procedure call }

   end else begin { process complex left side, or missing ':=' }

      if sp <> nil then tp := sp^.typ { set head type }
      else tp := gbludf;
      threaten(sp, tp); { process threat to variable }
      parvar(ss, sp, false, tp); { parse variable }
      expect(cbcms, ebcmexp, [cbcms]+exprset+ss, []); { expect ':=' }
      parass(ss, tp) { process assignment }

   end

end;

{******************************************************************************

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

******************************************************************************}

procedure parstat;

var waslab: boolean; { label was parsed }
    sp:     symptr;  { symbol pointer }

begin

   if fparse then writeln(':statement');
   if nxttlk = cinteger then begin { standard label }

      numlab; { convert and normalize label number }
      if nxtint > 9999 then { greater than ansi max ? }
         perror(einvgln, [], []); { invalid label number }
      find(sp); { lookup symbol }
      deflab(sp); { define that label }
      gettlk; { next }
      expect(ccln, eclnexp, [ccln]+statuset+ss, []); { expect ':' }
      if nxttlk = ccln then gettlk; { skip ':' }
      waslab := true { set label encountered }

   end;
   { check possible tolken misspell }
   chktkmp([cbegin, cif, ccase, cwhile, crepeat, cfor, cwith, cgoto]);
   waslab := false; { set last wasn't label }
   if (nxttlk = cidentifier) or (nxttlk = cbcms) then begin

      { procedure, function, assignment or extended label }
      sp := nil; { set no label }
      { note that the next creates an error for ':=' alone at
        statement head. No skip is required, as the rest
        is parsed just as a normal assign. This also serves
        as help for general sync to statement, as ':=' is
        a distinct statement start (as opposed to <ident> ':='). }
      if nxttlk = cbcms then perror(eidnexp, [], []) { identifier expected }
      else begin { it's an id }

         find(sp); { lookup symbol }
         gettlk { skip id }

      end;
      if (nxttlk = ccln) and (sp <> nil) and not fansi then begin

         { it's an extended label }
         if sp <> nil then deflab(sp); { define extended label }
         gettlk; { next }
         sp := nil; { set label is resolved }
         { we processed an extended label. now we must parse a statement from
           the top of the syntax, but without the ability to define a label }
         if (nxttlk = cidentifier) or (nxttlk = cbcms) then begin

            { procedure, function, assignment or extended label }
            sp := nil; { set no label }
            { note that the next creates an error for ':=' alone at
              statement head. No skip is required, as the rest
              is parsed just as a normal assign. This also serves
              as help for general sync to statement, as ':=' is
              a distinct statement start (as opposed to <ident> ':='). }
            if nxttlk = cbcms then perror(eidnexp, [], []) { identifier expected }
            else begin { it's an id }

               find(sp); { lookup symbol }
               gettlk { skip id }

            end;
            parsstat(ss, sp) { parse simple statement }

         end else begin { parse statement }

            { check possible tolken misspell }
            chktkmp([cbegin, cif, ccase, cwhile, crepeat, cfor, cwith, cgoto]);
            if nxttlk in [cbegin, cif, ccase, cwhile, crepeat, cfor, cwith,
                                cgoto] then case nxttlk of

               { statement }
               cbegin:  parstatb(ss);  { statement block }
               cif:     parif(ss);     { 'if' statement }
               ccase:   parcase(ss);   { 'case' statement }
               cwhile:  parwhile(ss);  { while }
               crepeat: parrepeat(ss); { repeat }
               cfor:    parfor(ss);    { for }
               cwith:   parwith(ss);   { with }
               cgoto:   pargoto(ss)    { goto }

            end

         end

      end else parsstat(ss, sp) { parse simple statement }

   end else begin { parse statement }

      { check possible tolken misspell }
      chktkmp([cbegin, cif, ccase, cwhile, crepeat, cfor, cwith, cgoto]);
      if nxttlk in [cbegin, cif, ccase, cwhile, crepeat, cfor, cwith,
                          cgoto] then case nxttlk of

         { statement }
         cbegin:  parstatb(ss);  { statement block }
         cif:     parif(ss);     { 'if' statement }
         ccase:   parcase(ss);   { 'case' statement }
         cwhile:  parwhile(ss);  { while }
         crepeat: parrepeat(ss); { repeat }
         cfor:    parfor(ss);    { for }
         cwith:   parwith(ss);   { with }
         cgoto:   pargoto(ss)    { goto }

      end

   end

end;

{******************************************************************************

Parse ordinal type

   ordinal = typeid | constant '..' constant | 
             '(' identifier [',' identifier].. ')'

Parses the ordinal type. Accepts a skip tolken set.
Error recovery:

1. Missing id in enumeration, skip to ',', ')' or id.

2. Missing ')' in enumeration, skip to ',', ')' or id.

3. Missing '..' after obvious head tolken, skip to likely 
constant, or '..'.

******************************************************************************}

procedure parord(ss: tolkset; var tp: typptr);

var sp:           symptr;  { pointer for symbol }
    tp1, tp2, lp: typptr;  { pointers for type }
    c:            integer; { enumeration count }

begin

   if fparse then writeln(':ordinal type');
   if not (nxttlk in ordset) then 
      { we just don't have any valid leader, so we produce a reasonable error
        message here and attempt a restart }
      perror(eordexp, [cidentifier, clparen, crange]+constset+ss, []);
   if nxttlk = cidentifier then begin 

      { type id or subrange }
      find(sp); { lookup symbol }
      gettlk; { skip id }
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
            tp^.subl := consti(tp1); { place lower bound }
            tp^.subu := consti(tp2); { place upper bound }
            if tp1^.t = ticst then tp^.subt := gblint { set type is integer }
            else if (tp1^.t = tscst) or (tp1^.t = tccst) then
               tp^.subt := gblchr { set type is char }
            else tp^.subt := tp1^.enh; { set same type as enumerated }
            { check lower <= upper }
            if tp^.subl > tp^.subu then perror(einvsub, [], [])

         end else tp := gbludf

      end else begin { type id }

         tp := actt(sp^.typ); { get type }
         { check proper type }
         typcon(tp, [tenum, tsub, tptr, tarray, tgarry, tfile, tset, trecord,
                     tinteger, tchar, tboolean, treal, tsreal, ttext, tudf])

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

            define(sp); { define symbol }
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
            tp^.subl := consti(tp1); { place lower bound }
            tp^.subu := consti(tp2); { place upper bound }
            if tp1^.t = ticst then tp^.subt := gblint { set type is integer }
            else if (tp1^.t = tscst) or (tp1^.t = tccst) then
               tp^.subt := gblchr { set type is char }
            else tp^.subt := tp1^.enh; { set same type as enumerated }
            { check lower <= upper }
            if tp^.subl > tp^.subu then perror(einvsub, [], [])

         end else tp := gbludf { set undefined }

      end else tp := gbludf { set undefined }

   end

end;

{******************************************************************************

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

******************************************************************************}

procedure parfield(ss: tolkset;     { skip set }
                   var tp: typptr;  { return type }
                   var sp: symptr;  { symbols list }
                   var ls: symptr); { last symbol in list }

var last:      tolken; { parse aid }
    lt:        typptr; { last type entry }
    ts:        symptr; { symbol pointer }
    tl:        typptr; { type sublist pointer }
    tt, tt1:   typptr; { type pointer }
    tg:        typptr; { tag field pointer }
    lab, lab1: labl;   { label save }

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
      else if tt^.fcsc < tl^.fcsc then { new < dest }
         begin tt^.fcsn := tl; tl := tt end { insert at top }
      else begin { in list middle somewhere }

         tt1 := tl; { index top of list }
         while tt1 <> nil do begin

            lt := tt1; { set pointer to last }
            tt1 := tt1^.fcsn; { index next }
            if tt1 <> nil then { there is a next entry } 
               if tt^.fcsc < tt1^.fcsc then tt1 := nil; { entry found, stop }

         end;
         tt^.fcsn := lt^.fcsn; { link new to next }
         lt^.fcsn := tt { link new to last }

      end

   end;
   tp := tl { place sorted list }

end;

{ check case list for gaps and limits.
  The list must be sorted in acending order }

procedure chkgap(tp: typptr; l, u: integer);

begin

   if tp <> nil then begin { not empty list }

      if l <> tp^.fcsc then perror(emcasv, [], []); { lower constant missing }
      tp := tp^.fcsn; { next entry }
      while tp <> nil do { traverse list }
         { check this constant equal to last + 1, else error and terminate }
         if tp^.fcsc <> l+1 then begin { case constants not in order }

            if tp^.fcsc = l then perror(edcasv, [], []) { case duplicate }
            else perror(emcasv, [], []); { case missing }
            tp := nil { terminate }

         end else begin { entry ok }
   
            l := tp^.fcsc; { place new last constant }
            tp := tp^.fcsn { next entry }
   
         end;
      if l <> u then perror(emcasv, [], []) { upper constant missing }

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

      extlab := lab; { copy label to error label }
      perror(edupsym, [], []);
      syp^.dup := true { set symbol is duplicate }

   end else begin { define new symbol }

      getsym(syp); { get symbol entry }
      new(syp^.lab, lenp(lab)); { get a label entry }
      copyp(syp^.lab^, lab); { place the label }
      if sp = nil then sp := syp; { if label list empty, set 1st }
      if ls <> nil then ls^.rnxt := syp; { link to last if exists }
      ls := syp { set new last entry }

   end

end;
  
begin

   if fparse then writeln(':field list');
   tp := nil; { set no type result }
   lt := nil; { set no last type }
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
   if nxttlk = ccase then begin { variant section }

      gettlk; { next }
      if nxttlk <> cidentifier then { no identifier found }
         perror(eidnexp, [ccln, cof, cidentifier]+ss, []);
      lab[1] := ' '; { clear label }
      if nxttlk = cidentifier then begin { tag field or type exists }

         { save the label for later use, since we don't know which kind it is 
           yet }
         lab := nxtlab;
         gettlk; { skip id }

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

         { the type label of the tag field is saved. We must save the present
           label, if one exists, and replace it with the saved one. Then we
           lookup the type as usual }
         lab1 := nxtlab; { save the present label }
         nxtlab := lab; { replace with saved label }
         find(ts); { lookup symbol }
         nxtlab := lab1; { restore tolken label }
         tt := ts^.typ; { get type }
         if tt = nil then error(esflt8, true); { fault on no type }
         { check proper type }
         typcon(tt, [tenum, tsub, tinteger, tchar, tboolean]);
         tg^.ftgt := tt { place base type }

      end;
      { expect 'of' }
      expect(cof, eofexp, [cof, ccma, ccln, clparen]+constset+ss, 
             [cof]);
      lt := nil; { set no last type }
      repeat { case fields }

         tl := nil; { set no types sublist }
         repeat { case selectors }

            parconst([ccma, ccln]+ss, tt); { parse constant }
            chkschr(tt); { if string, check is single character }
            { check proper type }
            typcon(tt, [ticst, tscst, tccst, tenme, tudf]);
            { compare type with type of tag field }
            if not typcmp(tt, tg^.ftgt) then perror(etypcmp, [], []);
            if tt^.t <> tudf then begin { if defined, start case entry }

               lsttyp(tt1, tfcas); { get case type entry }
               tt1^.fcsn := nil; { terminate }
               tt1^.fcsc := consti(tt); { place case constant }
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
            chkgap(tg^.ftgc, lbound(tg^.ftgt), ubound(tg^.ftgt))

      end else tp := gbludf { else set undefined }

   end

end;

{******************************************************************************

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

******************************************************************************}

procedure partype;

var pack:         boolean; { 'packed' applied }
    last:         tolken;  { parse aid }
    sp, ts:       symptr;  { pointer to symbol }
    tp1, tp2, lp: typptr;  { type entry pointers }
    valid:        boolean; { type valid flag }

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

         { pointers get special processing. If the pointer target is undefined,
           we assume it is forward declared and create "to be defined" entry.
           This entry will invoke the same errors as if the symbol was totally
           undefined, until it is truly defined, except that other pointer
           references can also be made. Unfortunately, this bypasses our 
           misspell checks, since we MUST assume that an undefined pointed
           to will be defined later (even if it is really a mistake) }
         sp := gblsym; { lookup symbol }
         if sp = nil then begin 

            { base type is undefined, create delayed definition }
            plcsym(sp); { place new symbol }
            sp^.ddf := true; { flag as delayed definition }
            lsttyp(tp, tddf); { get delayed definition entry }
            sp^.typ := tp; { link symbol to entry }
            tp^.ddfs := sp; { link entry to symbol for error processing }
            tp^.ddft := gbludf; { set as undefined until definition point }
            tp^.ddfd := false; { set no definition }
            tp^.ddfe := false { set no error processed }

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
            tp^.ddfe := false { set no error processed }

         end;
         sp^.ref := sp^.ref + 1; { increment reference counter }
         { check proper type }
         tp1 := sp^.typ; { copy so we don't trash it }
         typcon(tp1, [tenum, tsub, tptr, tarray, tgarry, tfile, tset, trecord,
                      tinteger, tchar, tboolean, treal, tsreal, ttext, tudf, 
                      tddf]);
         if tp1^.t <> tudf then begin { type valid }

            lsttyp(tp, tptr); { get pointer type entry }
            tp^.ptrt := tp1 { place type linkage }

         end else tp := gbludf; { set result undefined }
         gettlk { skip id }

      end

   end else begin { composite type }

      { check possible misspelled tolken }
      chktkmp([cpacked, carray, cfile, cset, crecord]);
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
            { check attempt to allocate general array }
            if tp1^.t = tgarry then perror(ealcgar, [], []); 
            tp^.gart := tp1; { place type linkage }
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
               typcon(tp1, [tenum, tsub, tinteger, tchar, tboolean, tudf]);
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
         typcon(tp1, [tenum, tsub, tinteger, tchar, tboolean, tudf]);
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

      end else begin

         { here we parse an ordinal only if it has a head.
           the error would have been taken care of on entry }
         if nxttlk in [cidentifier, clparen]+constset then 
            { we may have found it }
            parord(ss, tp) { parse ordinal type }

      end

   end

end;

{******************************************************************************

Parse procedure/function header

   procedure = 'procedure' identifer |
               'procedure' identifer paramlist |
               'function' identifier |
               'function identifier [paramlist] ':' typeid

Parses a procedure/function and it's body. Accepts a tolken
skip set.
Error recovery:

1. No identifier for procedure/function, skip to '(', 'var',
'procedure', 'function', ':', ';' or id (any tolken symbolizing
the parameter list parts).

2. No identifier for parameter, skip to id, ',', ':', ';',
')'.

3. No ':' or ',' following parameter id, skip to ',', ':', id, 
';', ')'. Loops as long as last tolken was a likely next 
parameter id.

4. No id after ':' in parameter, skip to id, ';', ')'.

5. No ')' or ';' after parameter spec, skip to ';', 'var', 
'procedure', 'function', id, ',', ':', ')' (any parameter
list parts or end). Loops as long as last tolken was a likely
next parameter spec.

6. No id after ':' in function result type, skip to id, ';', 
'forward', or block start tolken.
                   
******************************************************************************}

procedure parfphead(    ss:  tolkset; { skip set }
                    var hsp: symptr;  { returns head symbol }
                    var tp:  typptr); { returns procedure entry }

var last:     tolken;  { parser aid }
    head:     tolken;  { type of head tolken ('procedure'/'function') }
    sp:       symptr;  { symbol pointer }
    tl:       typptr;  { parameter type list }
    ts:       typptr;  { parameter sublist }
    tp1, tp2: typptr;  { type entry pointer }
    lt:       typptr;  { last type entry }
    part:     (valp, varp, viewp); { type of parameter }

begin

   if fparse then writeln(':procedure/function heading');
   head := nxttlk; { save head tolken for error check }
   hsp := nil; { set no head symbol }
   gettlk; { skip 'procedure' or 'function' }
   if nxttlk <> cidentifier then { id expected }
      perror(eidnexp, [cidentifier, clparen, cvar, cview, cprocedure, 
                       cfunction, ccln, cscn]+ss, [])
   else begin { id found }
   
      hsp := lclsym; { see if we can find a forwarded symbol }
      if hsp <> nil then begin { found symbol }
   
         if hsp^.typ^.t = tproc then begin { procedure }
   
            { flag no entry if not forwarded, which will end up as a 
              duplicate }
            if not hsp^.typ^.prcf then hsp := nil
            else if head <> cprocedure then
               perror(efwdmat, [], []) { does not match orginal sense }
   
         end else if hsp^.typ^.t = tfunc then begin { function }
   
            { flag no entry if not forwarded, which will end up as a 
              duplicate }
            if not hsp^.typ^.fncf then hsp := nil
            else if head <> cfunction then
               perror(efwdmat, [], []) { does not match orginal sense }
   
         end else hsp := nil; { flag no entry }
         if hsp <> nil then tp := hsp^.typ { index type entry if exists }
   
      end

   end;
   if hsp = nil then begin { no forwarded entry found }

      if head = cprocedure then begin { procedure }

         lsttyp(tp, tproc); { get procedure entry }
         tp^.prcd := pfnil; { set null dispatch code }
         tp^.prcf := false; { set not forwarded }
         tp^.prcs := nil; { clear save lists }
         tp^.prct := nil;
         tp^.prcp := nil; { set no parameter list }
         tp^.prce := uselvl <> 0 { set external status }

      end else begin { function }

         lsttyp(tp, tfunc); { get function entry }
         tp^.fncr := nil; { set result type nil }
         tp^.fncd := pfnil; { set null dispatch code }
         tp^.fncc := 0; { clear reference counter (function assign) }
         tp^.fncf := false; { set not forwarded }
         tp^.fncs := nil; { clear save lists }
         tp^.fnct := nil;
         tp^.fncp := nil; { set no parameter list }
         tp^.fnce := uselvl <> 0 { set external status }

      end;
      if nxttlk = cidentifier then begin { id found }

         define(hsp); { define symbol }
         hsp^.typ := tp { link procedure/function to symbol }
   
      end

   end;
   if nxttlk = cidentifier then gettlk; { skip id }
   if uselvl = 0 then { not in uses file }
      wrtsyms; { output symbols section incremental }
   level := level+1; { add new scoping level }
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

            parfphead(ss, sp, tp1); { parse header parameter }
            { because a true procedure start is done, we must purge all the
              symbols associated with the 'procedure' and dump the symbol
              level }
            listsym(sp); { output symbols listing and purge }
            level := level-1; { remove scoping level }
            { we must reconstruct the header as a parameter.
              The old top entry is thrown away }
            if tp1^.t = tproc then begin { procedure }

               lsttyp(tp2, tpproc); { get procedure parameter entry }
               tp2^.pprp := tp1^.prcp; { copy parameter list }
               tp2^.pprn := nil { terminate }

            end else begin { function }

               lsttyp(tp2, tpfunc); { get procedure parameter entry }
               tp2^.pfnp := tp1^.fncp; { copy parameter list }
               tp2^.pfnr := tp1^.fncr; { copy result type }
               tp2^.pfnn := nil { terminate }

            end;
            chgtyp(tp1, tp2); { change type reference to new }
            { if parameter list is empty, place 1st entry }
            if tl = nil then tl := tp2;
            if lt <> nil then { place last entry linkage }
               if lt^.t = tpar then lt^.parn := tp2
               else if lt^.t = tvpar then lt^.vprn := tp2
               else if lt^.t = twpar then lt^.wprn := tp2
               else if lt^.t = tpproc then lt^.pprn := tp2
               else lt^.pfnn := tp2;
            lt := tp2; { place new last entry }

         end else begin

            part := valp; { set value parameter }
            if nxttlk = cvar then part := varp { set VAR parameter }
            else if nxttlk = cview then part := viewp; { set VIEW parameter }
            if part <> valp then gettlk; { skip modifier if present }
            ts := nil; { clear type sublist }
            repeat { parameters }

               if nxttlk <> cidentifier then { no id }
                  perror(eidnexp, [cidentifier, ccma, ccln, cscn, 
                         crparen]+ss, []);
               if nxttlk = cidentifier then begin { id found }

                  define(sp); { define symbol }
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

               find(sp); { lookup symbol }
               tp1 := actt(sp^.typ); { get type }
               { check parameter is a proper type }
               typcon(tp1, [tenum, tsub, tptr, tarray, tgarry, tfile, tset, trecord,
                            tinteger, tchar, tboolean, treal, tsreal, ttext, tudf, 
                            tddf]);
               { check file component as anything but VAR parameter }
               if filect(tp1) and not (part = varp) then begin

                  perror(efmbvar, [], []); { file parameter must be VAR }
                  tp1 := gbludf { set undefined }

               end;
               { check general array as value parameter }
               if (tp1^.t = tgarry) and (part = valp) then begin

                  perror(ealcgar, [], []); { cannot allocate }
                  tp1 := gbludf { set undefined }

               end;
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

               end;
               gettlk { skip type id }
           
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
      { now we have the parameter list. if the procedure function is forward,
        we also will have a parameter list from the first declaration. if so,
        we can compare them }
      if tp^.t = tproc then if tp^.prcf then chkcon(tp^.prcp, tl);
      if tp^.t = tfunc then if tp^.fncf then chkcon(tp^.fncp, tl);
      { place parameter list. The parameter list may overwrite the original
        parameter list if this is an (invalid) duplicate or a repeated forward.
        We take the last occurance as gospel }
      if tp^.t = tproc then tp^.prcp := tl else tp^.fncp := tl

   end;
   if nxttlk = ccln then begin { result type specification }

      { check forwarded entry, in which case there should be no result.
        we don't bother checking the procedure case, since that already
        has an error (ansi mode only) }
      if (tp^.t = tfunc) and fansi then { function, and ansi mode }
         if tp^.fncf then perror(eresrep, [], []);
      gettlk; { next }
      if nxttlk <> cidentifier then { no id }
         perror(eidnexp, [cidentifier, cscn, cforward]+blockset+ss, []);
      if nxttlk = cidentifier then begin 

         find(sp); { lookup symbol }
         if tp^.t = tfunc then begin { building a function }

            tp1 := sp^.typ; { get result type }
            { check proper type for function result }
            typcon(tp1, [tenum, tsub, tptr, tinteger, tchar, tboolean, treal,
                         tsreal, tudf]);
            { if the function is forwarded, then we check this result is
              EXACTLY the same as the last one }
            if tp^.fncf then begin { it's forwarded }

               if (tp^.fncr <> sp^.typ) and (tp^.fncr^.t <> tudf) and
                  (sp^.typ^.t <> tudf) then { not equal, and none undefined }
               perror(efnncon, [], []) { function results not congrous }

            end;
            { if there is no result type, set it }
            if tp^.fncr = nil then tp^.fncr := sp^.typ { place result type }

         end;
         gettlk { skip id }

      end;
      if head <> cfunction then
         perror(eprctyp, [], []) { procedure has result }

   end

end;

{******************************************************************************

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

******************************************************************************}

procedure parfproc(ss: tolkset);

var sp:     symptr;  { pointer to symbol }
    tp:     typptr;  { procedure entry pointer }
    cps:    typptr;  { current procedure/function save }
    fwd:    boolean; { 'forward' flag }
    expsav: boolean; { export status save flag }

begin

   if fparse then writeln(':procedure/function specification');
   expsav := export; { save status of export zone }
   { parse procedure/function head }
   parfphead([cscn, cforward]+blockset+ss, sp, tp);
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
      pshtyp(sp); { start new typing level }
      if tp^.t = tproc then begin { procedure }

         if tp^.prcf then perror(eardfwd, [], []); { already forwarded }
         tp^.prcf := true; { flag forwarded }
         formlist(tp^.prcs); { form symbols list and remove from table }
         tp^.prct := typstk^.typ { save types of parameters }

      end else begin { function }

         if tp^.fncf then perror(eardfwd, [], []) { already forwarded }
         else if tp^.fncr = nil then begin

            { no function result }
            perror(enfncr, [], []); { function result not defined }
            tp^.fncr := gbludf { set result type undefined }

         end;
         tp^.fncf := true; { flag forwarded }
         formlist(tp^.fncs); { form symbols list and remove from table }
         tp^.fnct := typstk^.typ { save types of parameters }

      end;

   end else if nxttlk = cexternal then begin { process 'external' }

      gettlk; { skip 'external' }
      { flag type entry as external }
      if tp^.t = tproc then tp^.prce := true else tp^.fnce := true;
      { externals are forced to be exportable no matter which section they
        appear in }
      sp^.exp := true;
      if uselvl = 0 then { not in uses file }
         wrttyp; { output types section incremental }
      cps := curprc; { save the current block head }
      curprc := tp; { place new block head }
      pshtyp(sp); { start new typing level }
      listtyp; { output types listing }
      listsym(sp); { output symbols listing and purge }
      purget { remove all type list entries }

   end else begin { procedure has a body }

      if uselvl = 0 then { not in uses file }
         wrttyp; { output types section incremental }
      cps := curprc; { save the current block head }
      curprc := tp; { place new block head }
      pshtyp(sp); { start new typing level }
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
   export := expsav; { restore status of export zone }
   expect(cscn, escnexp, [cscn]+ss, []) { expect ';' }

end;

{******************************************************************************

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

******************************************************************************}

procedure pardec;

var last:    tolken; { tolken save }
    save:    tolken; { tolken save }
    sp:      symptr; { symbol entry pointer }
    tp, tp1: typptr; { type entry pointers }
    tl:      typptr; { type list }
    conset:  set of tolken; { continuation set }

begin

   if fparse then writeln(':declarations');
   last := cundefined; { set no last tolken }
   if fansi then begin

      if not (nxttlk in blockset) then { no follow tolken }
         perror(einvblk, blockset+ss, [clabel, cconst, ctype, cvar, cprocedure, 
                cfunction, cfixed]);
      conset := decset { set continuation }

   end else begin

      if not (nxttlk in blockset+[cfixed, cperiod]) then { no follow tolken }
         perror(einvblk, blockset+ss, [clabel, cconst, ctype, cvar, cprocedure, 
                cfunction, cfixed]);
      conset := decset+[cfixed] { set continuation }

   end;
   while nxttlk in conset do case nxttlk of { tolken }

      clabel: begin { label list }

         { check and flag out of order }
         if fansi and (last <> cundefined) then perror(edecor, [], []);
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

                  numlab; { convert and normalize label number }
                  if nxtint > 9999 then { greater than ansi max ? }
                     perror(einvgln, [], []) { invalid label number }

               end;
               { 'uses' declared labels are parsed, but otherwise ignored, as
                 no labels are exported, and are allways private }
               if not inuses then begin { if not in 'uses' section }

                  define(sp); { define symbol }
                  sp^.exp := false; { labels are never exportable }
                  lsttyp(tp, tlab); { get a goto label type }
                  sp^.typ := tp; { place link to symbol }
                  tp^.ldef := false; { set label not defined }
                  tp^.lref := 0; { clear 'goto' reference count }
                  tp^.slvl := 0; { clear statement nesting level }
                  tp^.mlvl := maxint; { set no minimum reference level }
                  tp^.extr := false { set no block external references exist }

               end;
               gettlk; { skip id }
            
            end;
            if (nxttlk = cinteger) or (nxttlk = cidentifier) then gettlk;
            if (nxttlk <> ccma) and (nxttlk <> cscn) then
               { we have no exit tolken }
               perror(esccmexp, [cidentifier, cinteger, ccma, cscn]+
                                conset+[cbegin, cprivate, cperiod]+ss, [])

         { until not ',' or likely label }   
         until not (nxttlk in [ccma, cidentifier, cinteger]);
         if nxttlk = cscn then gettlk { skip ';' }
     
      end;
   
      cconst: begin { constants }
   
         { check and flag out of order }
         if fansi and (last <> clabel) and (last <> cundefined) then 
            perror(edecor, [], []);
         last := nxttlk; { save that tolken }
         gettlk; { next }
         repeat
   
            if nxttlk <> cidentifier then { no id }
               perror(eidnexp, [cidentifier, cequ, cscn]+constset+decset+ss, 
                      []);
            sp := nil; { set no symbol exists }
            if nxttlk = cidentifier then begin { id found }

               define(sp); { define symbol }
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
               perror(einvblk, [cidentifier, cequ]+conset+
                               [cbegin, cprivate, cperiod]+ss,
                      [clabel, cconst, ctype, cvar, cfixed, cprocedure, 
                      cfunction])

         { until not likely constant }   
         until not (nxttlk in [cidentifier, cequ])
   
      end;

      ctype: begin { types }

         { check and flag out of order }
         if fansi and not (last in [cconst, clabel, cundefined]) then 
            perror(edecor, [], []);
         last := nxttlk; { save that tolken }
         gettlk; { next }
         repeat
   
            if nxttlk <> cidentifier then { no id }
               perror(eidnexp, [cidentifier, cequ, cscn]+typeset+decset+ss, []);
            sp := nil; { set no symbol exists }
            if nxttlk = cidentifier then begin { id found }

               { we must process the define specially, as it may allready exist
                 as a delayed definition }
               sp := lclsym; { find previous symbol }
               if sp <> nil then begin { already exists }

                  if sp^.typ^.t <> tddf then begin { output duplicate error }

                     extlab := nxtlab; { copy label to error label }
                     perror(edupsym, [], []);
                     sp^.dup := true { set symbol is duplicate }
                 
                  end

               end else begin { new symbol }

                  plcsym(sp); { place symbol }
                  sp^.hld := true; { set symbol holding }
                  sp^.typ := gbludf { set undefined }

               end;
               gettlk; { skip id }
            
            end;
            { expect '=' }
            expect(cequ, eequexp, [cequ, cscn]+typeset+decset+ss, []);
            partype([cscn]+decset+ss, tp); { parse type }
            if sp <> nil then begin { there is a symbol }

               if not sp^.ddf then begin { not delayed define }

                  sp^.typ := tp; { place type }
                  sp^.hld := false { remove holding }

               end else begin { delayed define }

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
               perror(einvblk, [cidentifier, cequ]+conset+
                               [cbegin, cprivate, cperiod]+ss,
                      [clabel, cconst, ctype, cvar, cfixed, cprocedure, 
                      cfunction])
   
         { until not likely next type }
         until not (nxttlk in [cidentifier, cequ]);
         chkddf { check for unresolved delayed pointer definitions }
   
      end;

      cvar: begin { variables }
   
         { check and flag out of order }
         if fansi and not (last in [ctype, cconst, clabel, cundefined]) then 
            perror(edecor, [], []);
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
                  sp := lclsym;
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

                     define(sp); { define symbol }
                     lsttyp(tp, tvar); { get variable type entry }
                     sp^.typ := tp; { place symbol linkage }
                     tp^.varr := 0; { clear threat count }
                     tp^.varf := 0; { clear 'for' use count }
                     tp^.vars := fsnone; { set no special file handling }
                     tp^.vare := uselvl <> 0 { set external status }

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
               perror(einvblk, [cidentifier, ccma, ccln]+conset+
                               [cbegin, cprivate, cperiod]+ss,
                      [clabel, cconst, ctype, cvar, cfixed, cprocedure, 
                      cfunction])

         { until not likely next variable }   
         until not (nxttlk in [cidentifier, ccma, ccln]);
         { we must check for unresolved definitions here as well as type.
           actually, if they appear here, they will never be defined, and
           are immediately in error. but we only flag them at the end of
           the 'var' block }
         chkddf { check for unresolved delayed pointer definitions }
   
      end;

      cfixed: begin { fixed }
   
         last := nxttlk; { save that tolken }
         gettlk; { next }
         repeat
   
            if nxttlk <> cidentifier then { id expected }
               perror(eidnexp, [cidentifier, ccln, cscn]+typeset+decset+ss,
                      []);
            if nxttlk = cidentifier then begin { id found }

               define(sp); { define symbol }
               lsttyp(tp, tfix); { get variable type entry }
               sp^.typ := tp; { place symbol linkage }
               tp^.fixe := uselvl <> 0; { set external status }
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
               perror(einvblk, [cidentifier, ccln]+conset+
                               [cbegin, cprivate, cperiod]+ss,
                      [clabel, cconst, ctype, cvar, cfixed, cprocedure, 
                       cfunction])

         { until not likely next fixed }   
         until not (nxttlk in [cidentifier, ccln])
   
      end;
 
      cprocedure, cfunction: begin { procedure/function }
      
         { check and flag out of order }
         if fansi and not (last in [cprocedure, cfunction, cvar, ctype, 
                                    cconst, clabel, cundefined]) then 
            perror(edecor, [], []);
         last := nxttlk; { save that tolken }
         chkdhf; { check dangling header file }
         parfproc(conset+[cbegin, cprivate]+ss); { parse function/procedure }
         if not (nxttlk in [cidentifier]+conset+
                           [cbegin, cprivate, cperiod]) then
            { no follow tolken }
            perror(einvblk, [cidentifier, cequ]+conset+
                            [cbegin, cprivate, cperiod]+ss,
                   [clabel, cconst, ctype, cvar, cfixed, cprocedure, 
                    cfunction])

      end

   end

end;

{******************************************************************************

Parse 'uses' statement

   uses = 'uses' identifier [',' identifier].. ';'

Parses the uses statement. The uses statement may open N many nested uses files
in order to parse declarations contained within.
Error recovery:

1. No file id, skip to id, ',', or ';'.

2. No ';' after statement, skip to id, ',', or ';'.

******************************************************************************}

procedure paruses(ss: tolkset);

var fn:     filnam;  { filename holder }
    tn:     filnam;  { temp filename holder }
    fi:     filinx;  { index for same }
    bl:     integer; { block nesting level }
    last:   tolken;  { parsing aid }
    fl:     fllptr;  { file list pointer }
    sp:     srcptr;  { open file pointer }
    dup:    boolean; { duplicate filename flag }
    uselab: labl;    { uses file label }

{ Check filenames equal, regardless of case }

function filequ(a, b: filnam): boolean;

var i: filinx; { index for labels }
    m: boolean; { match flag }

begin

   m := true; { set matches by default }
   for i := 1 to filmax do { match }
      if lcase(a[i]) <> lcase(b[i]) then m := false; { no match }
   filequ := m { return result }

end;

begin

   if fparse then writeln(':uses statement');
   uselvl := uselvl+1; { add uses nesting level }
   gettlk; { skip uses }
   repeat { process uses files }

      if nxttlk <> cidentifier then { no id }
         perror(eidnexp, [cidentifier, ccma, cscn]+ss, []);
      if nxttlk = cidentifier then begin { have found an id }

         uselab := nxtlab; { save uses file label }
         { load the indentifier as a truncated filename }
         for fi := 1 to filmax do if fi <= labmax then fn[fi] := nxtlab[fi]
                                  else fn[fi] := ' '; { pad }
         addext(fn, '.pas', true); { add file extention }
         errfn := fn; { place name for error processing }
         { search for previous use of this module }
         dup := false; { set no duplicate }
         fl := fllstk; { index 1st file list entry }
         while fl <> nil do begin { search file levels }

            sp := fl^.stk; { index 1st source list entry }
            while sp <> nil do begin { search open files }
   
               tn := sp^.nam; { find name without path }
               rempth(tn);
               if filequ(tn, fn) then dup := true; { found duplicate }
               sp := sp^.next { next source entry }

            end;
            fl := fl^.next { next file list entry }

         end;            
         { now search the used file entries }
         sp := srcusd; { index top of list }
         while sp <> nil do begin { traverse }

            tn := sp^.nam; { find name without path }
            rempth(tn);
            if filequ(tn, fn) then dup := true; { found duplicate }
            sp := sp^.next { next source entry }
            
         end;  
         search(usepth, fn); { search for uses file }         
         if fn[1] = ' ' then perror(efnfn, [], []) 
         else if not dup then begin { not a duplicate use of file }

            { file exists }
            getfll; { get a new file list level }
            { check file exists }
            errfn := fn; { place name for error processing }
            if not exists(fn) then error(efnfn, true);
            opnsrc(fn); { open the uses file }
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
               else { module id found }
                  if uselab <> nxtlab then perror(emodmat, [], [])

            end;
            { now we process a truncated parse of the uses file }
            bl := 0; { set nesting level }
            while (nxttlk <> cprivate) and (nxttlk <> ceof) do begin

               { until we see a private marker or eof (for safety) }
               { keep track of nesting level }
               if nxttlk in [cbegin, crecord, ccase] then bl := bl+1
               else if nxttlk = cend then bl := bl-1;
               { check 0 level declaration }
               if (nxttlk in [clabel, cconst, ctype, cvar, cprocedure, 
                              cfunction]) and
                  (bl = 0) then pardec([cbegin, cperiod, cprivate, ceof], true)
               else if nxttlk = cuses then { parse nested uses } 
                  paruses([cbegin, cperiod, cprivate, ceof]+decset)
               else gettlk { next }
         
            end;
            putfll { pop current files list level }

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

{******************************************************************************

Process header file initialization

Accepts a list of header files, joined by the general list chain. Each header
file is converted to a string with '_' in front, and possibly '@' in back.
The '_' indicates that it is a system file, and the '@' indicates that it
is to preexist. The file is assigned with the name. Then, if the file is one
of the special files, we preform either a reset or rewrite on it to prepare
it for use.

******************************************************************************}

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

{******************************************************************************

Parse module/program

******************************************************************************}

procedure parmod;

var last:    tolken; { tolken save }
    psp:     symptr; { program name symbol pointer }
    sp:      symptr; { symbol pointer }
    tp, tp1: typptr; { type entry pointer }
    hft:     typptr; { header files type list }
    hfs:     typptr; { header files symbol list }
    btp:     typptr; { block type entry pointer }
    cps:     typptr; { current procedure/function save }
    i:       labinx; { index for symbol }

begin

   if fparse then writeln(':module/program');
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

   end else if (nxttlk in [cmodule, cprogram, cprocess, cmonitor, cshare]) and
               fansi then perror(eprgexp, [], []);  { wrong type of header }
   modhead := nxttlk; { save head tolken }
   if nxttlk in [cmodule, cprogram, cprocess, cmonitor, cshare] then
      gettlk; { skip module tolken }
   if nxttlk <> cidentifier then
      { no program/module id found }
      perror(eidnexp, [cidentifier, clparen, cscn, cbegin, 
             cperiod]+decset+ss, []);
   wrtsyms; { output symbols section incremental }
   level := level+1; { add new scoping level }
   psp := nil; { set no symbol exists }
   if nxttlk = cidentifier then begin { id found }

      { the block symbol goes into the system level. It is only used to name
        the block }
      define(psp); { lookup symbol }
      { count appearance as self reference }
      psp^.ref := psp^.ref+1;
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
   wrttyp; { output types section incremental }
   cps := curprc; { save the current block head }
   curprc := btp; { set new block head }
   pshtyp(psp); { start a new typing level }
   if (nxttlk <> clparen) and (nxttlk <> cscn) then { no follow tolken }
      perror(elpscexp, [clparen, cscn, cidentifier]+blockset+ss, []);
   hft := nil; { clear header files list }
   hfs := nil;
   if (nxttlk = clparen) or (nxttlk = cidentifier) then begin { header exists }

      if nxttlk = clparen then gettlk; { get next }
      repeat

         if nxttlk <> cidentifier then 
            { no identifier found }
            perror(eidnexp, [cuses, cidentifier, crparen, cbegin, 
                   cperiod, cscn]+decset+ss, []);
         if nxttlk = cidentifier then begin { id found }

            define(sp); { lookup symbol }
            gettlk; { skip id }
            { create file variable }
            lsttyp(tp, tvar); { get type }
            sp^.typ := tp; { link to symbol }
            tp^.vart := gbltxt; { set type text }
            tp^.varr := 0; { clear threat count }
            tp^.varf := 0; { clear 'for' use count }
            tp^.vars := fshparm; { set unresolved header file }
            tp^.vare := false; { set not external }
            tp^.varh := hft; { place in header files type list }
            hft := tp;
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
            tp1^.list := hfs; { place in header files symbol list }
            hfs := tp1

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
   if nxttlk = cuses then 
      paruses([cbegin]+decset+ss); { parse 'uses' statement }
   pardec([cbegin]+ss, false); { parse declarations }
   if nxttlk = cprivate then begin { also has a 'private' section }

      gettlk; { get next }
      export := false; { set not exportable }
      pardec([cbegin]+ss, false) { parse private declarations }

   end;
   stalvl := 0; { set statement level 0 }
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
   curprc := cps; { restore old block head }
   expect(cperiod, eperexp, [cperiod]+ss, []) { check '.' end tolken }

end;

begin
end.
