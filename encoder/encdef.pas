{******************************************************************************
*                                                                             *
*                         MACHINE ENCODER DEFINITIONS                         *
*                                                                             *
*                       Copyright (C) 1996 S. A. Moore                        *
*                                                                             *
*                              Written 12/96                                  *
*                                                                             *
* Contains definitions for the encoder.                                       *
*                                                                             *
******************************************************************************}

module encdef;

uses sepsgn, { separated sign }
     stddef, { standard definitions }
     macdef; { machine definitions }

const

   labmax  = 10;  { number of characters in label }
   filmax  = 100; { number of characters in a filename }
   linmax  = 250; { number of characters in command line }
   tmpmax  = 1000; { maximum number of temps }

type

   intarr    = array of integer; { integer array }
   pintarr   = ^intarr; { pointer to integer array }
   ssintarr  = array of ssint; { separated sign array }
   pssintarr = ^ssintarr; { pointer to separated sign array }
   filinx    = 1..filmax; { index for filename }
   filnam    = packed array [filinx] of char; { filename holder }
   labl      = packed array [1..labmax] of char; { a standard label }
   lininx    = 1..linmax; { index for command line }
   linbuf    = packed array [1..linmax] of char; { command line buffer }
   ext       = packed array [1..3] of char; { filename extention }

   { Internal tree intermediate operator codes. Contains codes used to represent
     operations in intermediate trees. }
   tintcod = (tilodadr,    { load address operator }
              tilodfadr,   { load address function result operator }
              tiarrref,    { array reference operator }
              tiarfgar,    { general array reference operator }
              tirecoff,    { record offset operator }
              tildiint,    { load indirect integer operator }
              tildirel,    { load indirect real operator }
              tildisrl,    { load indirect short real operator }
              tildiset,    { load indirect set operator }
              tildichr,    { load indirect character operator }
              tildibol,    { load indirect boolean operator }
              tildisrc,    { load indirect structure operator }
              tildiptr,    { load indirect pointer }
              tilditgp,    { load indirect tagged pointer }
              tilimint,    { load immediate integer operator }
              tilimrel,    { load immediate real operator }
              tilimns,     { load immediate empty set operator }
              tilodlen,    { load general array tag length }
              tinotint,    { integer 'not' operator }
              tinotbol,    { boolean 'not' operator }
              tisinset,    { set single element operator }
              tirngset,    { set range of elements operator }
              ticvtitr,    { convert integer to real operator }
              ticvtgtf,    { convert general to fixed array }
              ticvtftg,    { convert fixed array to general }
              ticvtntg,    { convert nil to tagged format }
              tiintset,    { set intersection operator }
              timltrel,    { multiply real operator }
              timltint,    { multiply integer operator }
              tidivrel,    { divide real operator }
              tidivint,    { divide integer operator }
              timodint,    { modulo integer operator }
              tiandint,    { integer 'and' operator }
              tinegint,    { negate integer operator }
              tinegrel,    { negate real operator }
              tiuniset,    { set union operator }
              tiaddrel,    { add real operator }
              tiaddint,    { add integer operator }
              tidifset,    { set difference operator }
              tisubrel,    { subtract real operator }
              tisubint,    { subtract integer operator }
              tiorint,     { 'or' integer operator }
              tixorint,    { 'xor' integer operator }
              tiincset,    { set inclusion operator }
              tiequset,    { set equal operator }
              tiequrel,    { real equal operator }
              tiequstr,    { string equal operator }
              tiequgst,    { general string equal operator }
              tiequint,    { integer equal operator }
              tiequtgp,    { tagged pointer equal operator }
              tineqset,    { set not equal operator }
              tineqrel,    { real not equal operator }
              tineqstr,    { string not equal operator }
              tineqgst,    { general string not equal operator }
              tineqint,    { integer not equal operator }
              tineqtgp,    { tagged pointer not equal operator }
              tileqset,    { set less than or equal operator }
              tileqrel,    { real less than or equal operator }
              tileqstr,    { string less than or equal operator }
              tileqgst,    { general string less than or equal operator }
              tileqint,    { integer less than or equal operator }
              tigeqset,    { set greater than or equal operator }
              tigeqrel,    { real greater than or equal operator }
              tigeqstr,    { string greater than or equal operator }
              tigeqgst,    { general string greater than or equal operator }
              tigeqint,    { integer greater than or equal operator }
              tiltnrel,    { real less than operator }
              tiltnstr,    { string less than operator }
              tiltngst,    { general string less than operator }
              tiltnint,    { integer less than operator }
              tigtnrel,    { real greater than operator }
              tigtnstr,    { string greater than operator }
              tigtngst,    { general string greater than operator }
              tigtnint,    { integer greater than operator }
              tiifbgn,     { if begin operator }
              ticasbgn,    { case begin operator }
              ticasstb,    { case statement begin }
              tiwhlbgn,    { while begin operator }
              tirptbgn,    { repeat begin operator }
              tifortint,   { for 'to' integer operator }
              tifortchr,   { for 'to' character operator }
              tifortbol,   { for 'to' boolean operator }
              tifordint,   { for 'downto' integer operator }
              tifordchr,   { for 'downto' character operator }
              tifordbol,   { for 'downto' boolean operator }
              tiwthbgn,    { with begin operator }
              titrybgn,    { try begin operator }
              titryexp,    { try exception clause }
              titryels,    { try else clause }
              tigoto,      { goto operator }
              tiprccal,    { procedure call operator }
              tiprccali,   { procedure call indirect operator }
              tiprccalo,   { procedure call override operator }
              tifnccal,    { function call operator }
              tifnccali,   { function call indirect operator }
              tifnccalo,   { function call override operator }
              tiwrtsrc,    { write file operator }
              tiwrtintt,   { write integer operator }
              tiwrtchrt,   { write character operator }
              tiwrtbolt,   { write boolean operator }
              tiwrtrelt,   { write real operator }
              tiwrtstrt,   { write string operator }
              tiwrtgstt,   { write general string operator }
              tiwrtintft,  { write integer fielded operator }
              tiwrtchrft,  { write character fielded operator }
              tiwrtbolft,  { write boolean fielded operator }
              tiwrtrelft,  { write real fielded operator }
              tiwrtstrft,  { write string fielded operator }
              tiwrtgstft,  { write general string fielded operator }
              tiwrtrelfft, { write real fielded and fractioned operator }
              tiwrtsrl,    { write file short real }
              tiwrtrel,    { write file real }
              tiwrtset,    { write file set }
              tiwrtbol,    { write file boolean }
              tiwrtchr,    { write file character }
              tiwrtint,    { write file integer }
              tiwrteolt,   { write file end of line }
              tiredsrc,    { read file operator }
              tiredintt,   { read integer operator }
              tiredchrt,   { read character operator }
              tiredrelt,   { read real operator }
              tiredsrlt,   { read short real operator }
              tiredeolt,   { read file end of line }
              tiabsrel,    { abs of real operator }
              tiabsint,    { abs of integer operator }
              tisqrrel,    { sqr of real operator }
              tisqrint,    { sqr of integer operator }
              tiatnrel,    { arctan of real operator }
              ticosrel,    { cos of real operator }
              tiexprel,    { exp of real operator }
              tilgnrel,    { ln of real operator }
              tisinrel,    { sin of real operator }
              tisqtrel,    { sqrt of real operator }
              tieolt,      { eoln of file operator }
              tieof,       { eof of file operator }
              tiodd,       { odd of integer operator }
              tisucint,    { succ of integer operator }
              tiprdint,    { pred of integer operator }
              tirnd,       { round operator }
              titrc,       { trunc operator }
              tiexist,     { file exists operator }
              tilen,       { file length operator }
              tiloc,       { file location operator }
              tiget,       { file get operator }
              tigett,      { text file get operator }
              tiput,       { file put operator }
              tilodafbuf,  { load address of file buffer }
              tilodafbuft, { load address of text file buffer }
              tireset,     { file reset operator }
              tirewrite,   { file rewrite operator }
              ticlose,     { file close operator }
              tipack,      { pack operator }
              tiunpack,    { unpack operator }
              tipaget,     { page operator }
              tiassign,    { assign file operator }
              tipos,       { position file operator }
              tidel,       { delete file operator }
              tichg,       { change file operator }
              tistiint,    { store integer operator }
              tistisrl,    { store short real operator }
              tistirel,    { store real operator }
              tistichr,    { store character operator }
              tistibol,    { store boolean operator }
              tistiset,    { store set operator }
              tistisrc,    { store structured operator }
              tistigar,    { store general array }
              tistitgp,    { store tagged pointer }
              tistifint,   { store function result integer operator }
              tistiftgp,   { store function result tagged pointer operator }
              tistifsrl,   { store function result short real operator }
              tistifrel,   { store function result real operator }
              tistifchr,   { store function result character operator }
              tistifbol,   { store function result boolean operator }
              tinew,       { new operator }
              tidisp,      { dispose operator }
              titag,       { tagfield constant operator }
              tilabequ,    { 'goto' label equation }
              tirngchk,    { range check }
              tinewgar,    { allocate tagged array }
              tidspgar,    { deallocate tagged array }
              tihalt,      { halt program }
              ticvtrtsr,   { convert real to short real }
              tisetlin,    { set current line }
              tisetsrc,    { set current source file }
              tiupdate,    { update file }
              tiappend,    { append file }
              ticasels,    { case else }
              ticalpar,    { procedure/function call parameter }
              tiassert,    { assert procedure }
              tisignal,    { signal procedure }
              tisignalone, { signalone procedure }
              tiwait,      { wait procedure }

              { simplified load/stores }

              tilodint,    { load direct integer }
              tilodrel,    { load direct real }
              tilodsrl,    { load direct short real }
              tilodset,    { load direct set }
              tilodchr,    { load direct character }
              tilodbol,    { load direct boolean }
              tilodsrc,    { load direct structure }
              tilodptr,    { load direct pointer }
              tilodtgp,    { load direct tagged pointer }
              tigotot,     { goto on true }
              tigotof,     { goto on false }
              tistoint,    { store direct integer }
              tistosrl,    { store direct short real }
              tistorel,    { store direct real }
              tistochr,    { store direct character }
              tistobol,    { store direct boolean }
              tistoset,    { store direct set }
              tistosrc,    { store direct structure }
              tistogar,    { store direct general array }
              tistotgp,    { store direct tagged pointer }
              tistofint,   { store direct function result integer }
              tistoftgp,   { store direct function result tagged pointer }
              tistofsrl,   { store direct function result short real }
              tistofrel,   { store direct function result real }
              tistofchr,   { store direct function result character }
              tistofbol,   { store direct function result boolean }

              { breakdown products }

              tiaddintimm,  { add integer immediate operator }
              timltintimm,  { multiply integer immediate operator }
              tiandintimm,  { and integer immediate operator }
              tiequintimm,  { integer equal immediate operator }
              tiequtgpimm,  { tagged pointer equal immediate operator }
              tineqintimm,  { integer not equal immediate operator }
              tineqtgpimm,  { tagged pointer not equal immediate operator }
              tiorintimm,   { or integer immediate operator }
              tixorintimm,  { xor integer immediate operator }
              tileqintimm,  { integer less or equal immediate operator }
              tigeqintimm,  { integer greater or equal immediate operator }
              tiltnintimm,  { integer less immediate operator }
              tigtnintimm,  { integer greater immediate operator }
              tisubintimm,  { integer subtract immediate operator }
              tiaddintlod,  { add integer direct address operator }
              timltintlod,  { multiply integer direct address operator }
              tiandintlod,  { and integer direct address operator }
              tiequintlod,  { integer equal direct address operator }
              tiequtgplod,  { tagged pointer equal direct address operator }
              tineqintlod,  { integer not equal direct address operator }
              tineqtgplod,  { tagged pointer not equal direct address operator }
              tiorintlod,   { or integer direct address operator }
              tixorintlod,  { xor integer direct address operator }
              tileqintlod,  { integer less or equal direct address operator }
              tigeqintlod,  { integer greater or equal direct address operator }
              tiltnintlod,  { integer less direct address operator }
              tigtnintlod,  { integer greater direct address operator }
              tisubintlod,  { integer subtract direct address operator }
              tiaddintldi,  { add integer indirect address operator }
              timltintldi,  { multiply integer indirect address operator }
              tiandintldi,  { and integer indirect address operator }
              tiequintldi,  { integer equal indirect address operator }
              tiequtgpldi,  { tagged pointer equal indirect address operator }
              tineqintldi,  { integer not equal indirect address operator }
              tineqtgpldi,  { tagged pointer not equal indirect address operator }
              tiorintldi,   { or integer indirect address operator }
              tixorintldi,  { xor integer indirect address operator }
              tileqintldi,  { integer less or equal indirect address operator }
              tigeqintldi,  { integer greater or equal indirect address operator }
              tiltnintldi,  { integer less indirect address operator }
              tigtnintldi,  { integer greater indirect address operator }
              tisubintldi); { integer subtract indirect address operator }

   blkptr = ^blk; { pointer to block stack entry }
   typptr = ^typ; { type pointer }
   { register contents tracking }
   regcon = record

      con: typptr; { current contents of register, or nil }
      age: integer { age of load, in "ticks" }

   end;
   regcxt = array [regt] of regcon;
   cxtptr = ^regcxt; { context block pointer }
   { Internal intermediate representation as a tree. Each procedure and whole
     block is represented by tree without cycles. To do this, each loop or
     conditional is formed by a side branch to the main flow which is a
     terminal line. Each intermediate node contains the information on its
     operation, the register(s) needed to encode it, the type pointers that
     form its operations, and other information. The program flow is represented
     as a graph, with expressions forming trees under that. }
   intptr = ^int; { pointer to intermediate record }
   int    = record { intermediate code structure }

               { the next entry threads all of the intermediates for a
                 block, and is used to form an unabiguous listing }
               next: intptr;
               { the up link indexes the parent entry in expression trees.
                 If the entry is terminal, then the up link points to
                 this entry. }
               up: intptr;
               { note that many of the intermediates have no function as
                 internal structures, and many are represented elsewhere as
                 types or symbols }
               i: tintcod;
               { the flow link gives the default next operator that will
                 execute after the current one. the second and third flows are
                 for branches. the entire program flow can be followed from
                 the flow links }
               flow, flow2, flow3: intptr;
               { operator branches. these entries contain operands to the
                 current operator. the convention for useage order is
                 left, right, xtra, and xtra2 }
               left, right, xtra, xtra2: intptr;
               { Many intermediates need "helper" type references. Also, we
                 input and output helper types, so storing them internally
                 speeds things along }
               base, base2, base3: typptr;
               { The result type gives a universal description of the result
                 type of the operator, and is usefull for general handler
                 routines and cases where ranges need to be verified. }
               rbase: typptr;
               { the result register keeps the result (if any) of the operator.
                 it also has a flag, reflecting results that are returned as
                 flags }
               rsreg, rsregx: regt;
               rsflg: flag;
               { the final register is where results get passed up to the
                 parent entry }
               freg, fregx: regt;
               fflg: flag;
               { each of the operator branches potentially has a register }
               lreg, lregx, rreg, rregx, xreg, xregx, x2reg, x2regx: regt;
               lflg, rflg, xflg, x2flg: flag;
               { temp registers used during operators }
               t1reg, t1regx, t2reg, t2regx, t3reg, t3regx: regt;
               { the "push" register set keeps track of which registers need
                 to be saved on the stack before processing suboperands }
               push: regset;
               { the "allocated" register set keeps track of registers in
                 use at this level }
               alc: regset;
               { the skip flag disables the low level coding of an operator. It
                 is used in register content reuse. }
               skip: boolean;
               { stored context is used by labels to express concentrator
                 context }
               rcxt: cxtptr;

            end;
   { Intermediate constructor stack entries. We need these to form the
     construction stack on input. Since the stack is fairly temporary,
     this allows us to avoid wasting a link per intermediate tolken,
     without imposing a fixed stack limit }
   istptr = ^istp; { pointer to stack entry }
   istp   = record { stack entry }

               next: istptr; { next entry }
               ent:  intptr  { intermediate entry }

            end;
   { mark types }
   mrktyp = (mtsystem,  { system }
             mtprogram, { program }
             mtmodule,  { module }
             mtprocess, { process }
             mtmonitor, { monitor }
             mtshare);  { share }
   labptr = ^labtyp;{ pointer to label }
   typarr = array of typptr; { type pointer array }
   ptyparr = ^typarr; { pointer to type array }
   { module tracking entry }
   modptr = ^modtrk; { module tracking entry pointer }
   modtrk = record { entry }

      next:    modptr;  { next entry (for all modules) }
      inx:     integer; { number of entry, 1-n }
      modn:    pstring; { module name }
      modf:    pstring { module filename, fully pathed }

   end;
   { type codes
     In our system, types are a loose word standing for anything that is
     predeclared and therefore requires a data structure to represent
     it. Type entries may be indexed by symbols, or may be "anonymous" }
   types  = (tudf,       { no type, used to mark errors }
             tnil,       { 'nil' universal pointer }
             tlab,       { goto label }
             ticst,      { integer constant }
             tscst,      { string constant }
             tccst,      { character constant }
             trcst,      { real constant }
             tstcst,     { set constant }
             tstet,      { set constant entry }
             tarrcst,    { array constant entry }
             tarrcel,    { array constant element }
             treccst,    { record constant entry }
             treccel,    { record constant element }
             tenum,      { enumerated }
             tenme,      { enumerated constant }
             tsub,       { subrange }
             tptr,       { pointer }
             tarray,     { array }
             tgarry,     { general array }
             tfile,      { file }
             tset,       { set }
             trecord,    { record }
             tfield,     { record field }
             tftag,      { record tag field }
             tfcas,      { record variant case }
             tvar,       { variable }
             tfix,       { fixed }
             tproc,      { procedure }
             tfunc,      { function }
             tpar,       { parameter }
             tvpar,      { variable parameter }
             twpar,      { view parameter }
             tpproc,     { procedure parameter }
             tpfunc,     { function parameter }
             tinteger,   { integer }
             tlinteger,  { long integer }
             tcardinal,  { cardinal }
             tlcardinal, { long cardinal }
             tchar,      { character }
             tboolean,   { boolean }
             treal,      { real }
             tsreal,     { short real }
             ttext,      { text }
             teset,      { empty set }
             tglbl,      { global block }
             tsemaphore, { semaphore }
             tclass,     { class }
             tatom,      { atom }
             tthread,    { thread }
             treference, { reference }
             texception, { exception }
             tnull,      { placeholder entry }
             tfuncr,     { function result variable }
             tlink,      { linking entry }
             tcastbl,    { case table }
             thshtbl,    { hash table }
             tcassel,    { case table entry }
             trot,       { pascal support routine }
             tpgm,       { program space marker entry }
             tvrs);      { variable space marker entry }
   typ    = record { type entry }

               next:   typptr;  { next list entry }
               { the address carries the address of the final object, in the
                 case of tvar, tfix, etc. In the case of some types, like tset
                 and tarray, it contains the address of the "decriptor" used
                 bounds checking }
               addr:   integer; { address of type }
               size:   integer; { size of type in bytes }
               local:  boolean; { what address space occupied }
               level:  integer; { block level }
               blk:    blkptr;  { enclosing block }
               classt: typptr;  { class type, if any }
               case t: types of { types }

                  tudf:       ();              { dummy entry to mark errors }
                  tnil:       ();              { 'nil' universal pointer }
                  tlab:       (lmrk: typptr);  { 'goto' label }
                  ticst:      (ival: ssint);   { the value of the integer }
                  tscst:      (sval: pstring); { the value of the string }
                  tccst:      (cval: char);    { value of character }
                  trcst:      (rval: real);    { the value of the real }
                  tstcst:     (stct: typptr;   { base type of set }
                               stcc: typptr);  { set constant list }
                  tstet:      (sten: typptr;   { next set element }
                               stes: ssint;    { starting value }
                               stee: ssint;    { ending value }
                               steh: typptr);  { head entry }
                  tarrcst:    (arcn: typptr);  { first list entry }
                  tarrcel:    (aren: typptr;   { next list entry }
                               arec: typptr);  { constant link }
                  treccst:    (recn: typptr);  { first list entry }
                  treccel:    (reen: typptr;   { next list entry }
                               reec: typptr);  { constant link }
                  tenum:      (enc:  typptr);  { list of enumerated constants }
                  tenme:      (enx:  typptr;   { next enumeration entry }
                               enh:  typptr;   { head entry pointer }
                               env:  integer); { enumerated constant }
                  tsub:       (subt: typptr;   { base type }
                               subl: ssint;    { lower bound }
                               subu: ssint);   { upper bound }
                  tptr:       (ptrt: typptr);  { base type }
                  tarray:     (arrt: typptr;   { base type }
                               arri: typptr;   { index type }
                               arrb: integer;  { array base constant }
                               arrc: integer); { array bounds check record }
                  tgarry:     (gart: typptr);  { base type }
                  tfile:      (filt: typptr);  { base type }
                  tset:       (sett: typptr);  { base type }
                  trecord:    (recf: typptr;   { field list }
                               recs: labptr;   { symbols list }
                               recl: labptr);  { last symbol in list }
                  tfield:     (fldn: typptr;   { next field pointer }
                               fldh: typptr;   { head entry pointer }
                               fldt: typptr);  { base type }
                  tftag:      (ftgc: typptr;   { case list }
                               ftgh: typptr;   { head entry pointer }
                               ftgt: typptr;   { base type }
                               ftge: boolean); { exists flag }
                  tfcas:      (fcsn: typptr;   { next case entry pointer }
                               fcsf: typptr;   { field list }
                               fcss: ssint;    { case constant }
                               fcse: ssint);   { case constant }
                  tvar:       (vart: typptr;   { base type }
                               vare: boolean;  { variable is external }
                               varmd: modptr;  { owning module }
                               varr: boolean); { variable was referenced }
                  tfix:       (fixt: typptr;   { base type }
                               fixc: typptr;   { constant fill }
                               fixe: boolean;  { fixed is external }
                               fixmd: modptr;  { owning module }
                               fixr: boolean); { fixed was referenced }
                  tproc:      (prcp:  typptr;  { parameter list }
                               prcv:  integer; { total locals allocation }
                               prca:  integer; { total parameters allocation }
                               prcg:  integer; { offset for goto entry }
                               prce:  boolean; { procedure is external }
                               prcmd: modptr;  { owning module }
                               prcas: boolean; { procedure is assembly }
                               prch:  typptr;  { overload head link }
                               prcr:  boolean; { procedure was referenced }
                               prcx:  boolean; { procedure is globally accessable }
                               prcst: boolean; { procedure is static (global) }
                               prcvt: boolean; { procedure is virtual }
                               prcol: typptr;  { overrider link }
                               prcoh: typptr;  { override head link }
                               prccl: typptr;  { class type link }
                               prcvv: typptr); { procedure virtual vector }
                  tfunc:      (fncp:  typptr;  { parameter list }
                               fncr:  typptr;  { function result }
                               fncv:  integer; { total locals allocation }
                               fnca:  integer; { total parameters allocation }
                               fncg:  integer; { offset for goto entry }
                               fnce:  boolean; { function is external }
                               fncmd: modptr;  { owning module }
                               fncas: boolean; { function is assembly }
                               fnch:  typptr;  { overload head link }
                               fnct:  boolean; { function was referenced }
                               fncx:  boolean; { function is globally accessable }
                               fncst: boolean; { procedure is static (global) }
                               fncvt: boolean; { procedure is virtual }
                               fncol: typptr;  { overrider link }
                               fncoh: typptr;  { override head link }
                               fnccl: typptr;  { class type link }
                               fncvv: typptr); { procedure virtual vector }
                  tpar:       (parn: typptr;   { next parameter }
                               part: typptr;   { base type }
                               parh: typptr);  { head entry pointer }
                  tvpar:      (vprn: typptr;   { next parameter }
                               vprt: typptr;   { base type }
                               vprh: typptr);  { head entry pointer }
                  twpar:      (wprn: typptr;   { next parameter }
                               wprt: typptr;   { base type }
                               wprh: typptr);  { head entry pointer }
                  tpproc:     (pprp: typptr;   { parameter list }
                               ppra: integer;  { parameter allocation }
                               pprn: typptr);  { next parameter }
                  tpfunc:     (pfnp: typptr;   { parameter list }
                               pfnr: typptr;   { function result }
                               pfna: integer;  { parameter allocation }
                               pfnn: typptr);  { next parameter }
                  tinteger:   ();              { integer }
                  tlinteger:  ();              { long integer }
                  tcardinal:  ();              { cardinal }
                  tlcardinal: ();              { long cardinal }
                  tchar:      ();              { character }
                  tboolean:   (bnc:  typptr);  { list of enumerated constants }
                  treal:      ();              { real }
                  tsreal:     ();              { short real }
                  ttext:      ();              { text file }
                  teset:      ();              { empty set }
                  tglbl:      (mrkt: mrktyp;   { mark type }
                               ds: typptr);    { display save }
                  tsemaphore: ();              { semaphore type }
                  tclass:     (clsi: typptr);  { base class }
                  tatom:      (atmi: typptr);  { base class }
                  tthread:    (thdi: typptr);  { base class }
                  treference: (reft: typptr);  { reference type }
                  texception: ();              { semaphore type }
                  tnull:      ();              { placeholder }
                  tfuncr:     (fnrt: typptr);  { base type }
                  tlink:      (lnkl: integer;  { linkage level }
                               lnke: integer); { linkage entry }
                  tcastbl:    (ctn: typptr;    { first case selector }
                               ctc: integer;   { number of entries }
                               ctl: ssint;     { lowest select }
                               cth: ssint);    { highest select }
                  thshtbl:    (htn: typptr;    { first case selector }
                               htc: integer;   { number of entries }
                               htl: ssint;     { lowest select }
                               hth: ssint);    { highest select }
                  tcassel:    (csv: ssint;    { case selector entry }
                               csn: typptr;    { next selector in series }
                               csm: typptr;    { missed hash chain }
                               csi: integer;   { missed table index }
                               css: typptr;    { statement chain }
                               csp: boolean);  { entry is padding }
                  trot:       (rotr: boolean); { routine was referenced }
                  tpgm:       ();              { program space marker }
                  tvrs:       ();              { variable space marker }

               { end }

            end;
   labtyp = record { label entry }

      next: labptr;  { next label in list }
      lab:  pstring; { label string }
      exp:  boolean; { exportable flag }
      typ:  typptr   { associated type entry }

   end;
   { The block stack contains a directory for all information that
     is kept on a block. These are stacked and appear just as blocks
     are nested. When discarded, they are placed into the discard
     list in order of appearance }
   blk    = record { block stack entry }

               next:   blkptr;  { next entry }
               typ:    typptr;  { type list for block }
               lst:    typptr;  { last entry in type list }
               res:    typptr;  { next resolvable entry }
               typa:   typptr;  { alternate types list }
               lsta:   typptr;  { last entry in alternate type list }
               resa:   typptr;  { next resolvable alternate entry }
               mark:   typptr;  { mark for block }
               marks:  labptr;  { mark symbol }
               prnt:   blkptr;  { parent block }
               lvl:    integer; { level number }
               sym:    labptr;  { symbols list }
               entry:  intptr;  { entry code begin list }
               exit:   intptr;  { exit code list }
               entreg: regset;  { entry block registers used }
               extreg: regset;  { exit block registers used }
               fvar:   boolean; { block contains file variables }
               rlop:   boolean; { block contains real operations }

            end;
   { patch insertion types }
   ityp   = (itadr,   { address }
             itradr,  { relative address }
             itbradr, { byte relative address }
             itgto);  { goto offset }
   rldptr = ^rld; { relocation entry pointer }
   rld    = record { relocation entry }

               next: rldptr;  { next entry }
               addr: integer; { address to patch in memory }
               off:  integer; { offset of address }
               lab:  typptr;  { entry to patch with }
               it:   ityp ;   { insertion type }
               out:  boolean  { entry has been output }

            end;
   { 'with' records are a linked list stack that gives the information needed
     to process 'with' references, in nested scope order }
   wthptr = ^wthrec; { 'with' record entry }
   wthrec = record { 'with' information record }

      next: wthptr; { next list entry }
      rect: typptr; { record type }
      vart: typptr  { variable containing 'with' base pointer }

   end;
   { temp entries track allocation and deallocation of temps by type }
   tmpptr = ^tmprec;
   tmprec = record

      typ: typptr; { type of temp }
      inuse: boolean { temp is in use }

   end;
   { runtime errors }
   rerrcod = (renull,    { no error }
              rerngchk,  { range check }
              relenmat,  { array sizes don't match }
              recasvnf,  { case value not found }
              rezdiv,    { zero divide }
              reivop,    { invalid operands }
              renpdref,  { nil pointer dereference }
              rerelovf,  { real overflow }
              rerelunf,  { real underflow }
              rerelflt,  { real processing fault }
              retagact); { tag value for enclosing variant not active }
   { errors }
   errcod = (einvitc,  { invalid intermediate code }
             einvfmt,  { invalid intermediate code format }
             efilnf,   { file does not exist }
             einvfnm,  { file name is invalid }
             einvcmd,  { command line invalid }
             ememovf,  { code memory overflow }
             estkovf,  { stack overflow }
             estkunf,  { stack underflow }
             einvelm,  { invalid set element }
             efilopn,  { file is open }
             efilass,  { file already assigned }
             eftbful,  { file table full }
             efilnop,  { file not open }
             efilmod,  { file not in correct mode }
             eunimp1,
             eunimp2,
             eunimp3,
             eunimp4,
             eunimp5,
             eunimp6,
             eunimp7,
             eunimp8,
             eunimp9,
             eunimp10,
             eunimp11,
             eunimp12,
             eunimp13,
             eunimp14,
             eunimp15,
             eunimp16,
             eunimp17,
             eunimp18,
             eunimp19,
             eunimp20,
             eunimp21, { operation not implemented }
             etmpovf,  { temporary files overflow }
             einvpos,  { invalid position }
             esysrdo,  { system file is read only }
             esyslen,  { system file must be character size }
             elenmat,  { array sizes don't match }
             eequexp,  { '=' expected }
             elabovf,  { label too long }
             eoptnf,   { option not found }
             eoptpar,  { bad option parameter }
             ecstrng,  { constant out of range }
             esettl,   { set size too large }
             esetneg,  { set base is negative }
             ecasdup,  { case select was duplicated }
             ecasrng,  { case range start greater than end }
             { the register allocation errors should not go to a user, and
               need to be changed to system faults for the final release }
             eregful,  { registers are full }
             eregfre,  { register already free }
             ereglft,  { register left allocated }
             eregdup,  { register already allocated }
             elvlovf,  { too many nesting levels }
             estmpovf, { too many set temporaries (expression too complex) }
             estmpunf, { set temporary allocation underflow }
             estmplft, { set temporary left after expression }
             { The floating point stack overflow error covers the fact that
               we don't implement FPU spilling right now. It will be removed
               later. Underflow is still considered a system error. }
             efstkovf, { floating point stack overflow }
             edivzer,  { divide by zero in folded expression }
             einvopr,  { invalid operand }
             erngchk,  { value out of range for type }
             enumovf,  { numeric overflow in operator }
             ebolneg,  { negative number operand for boolean operator }
             ecasvnf,  { case selector value not found }
             echtnf,   { character transliteration file not found }
             etagdbl,  { tag field cannot be a double }
             { System errors for main module, "*" marks unused entries. }
             esysflt1,
             esysflt2,
             esysflt3,
             esysflt4,
             esysflt5,
             esysflt6,
             esysflt7,
             esysflt8,
             esysflt9,
             esysflt10,
             esysflt11,
             esysflt12,
             esysflt13,
             esysflt14,
             esysflt15,
             esysflt16,
             esysflt17,
             esysflt18,
             esysflt19,
             esysflt20,
             esysflt21,
             esysflt22,
             esysflt23,
             esysflt24,
             esysflt25,
             esysflt26,
             esysflt27,
             esysflt28,
             esysflt29,
             esysflt30,
             esysflt31,
             esysflt32,
             esysflt33,
             esysflt34,
             esysflt35,
             esysflt36,
             esysflt37,
             esysflt38,
             esysflt39,
             esysflt40,
             esysflt41,
             esysflt42,
             esysflt43,
             esysflt44,
             esysflt45,
             esysflt46,
             esysflt47,
             esysflt48,
             esysflt49,
             esysflt50,
             esysflt51,
             esysflt52,
             esysflt53,
             esysflt54,
             esysflt55,
             esysflt56,
             esysflt57,
             esysflt58,
             esysflt59,
             esysflt60,
             esysflt61,
             esysflt62,
             esysflt63,
             esysflt64,
             esysflt65,
             esysflt66,
             esysflt67,
             esysflt68,
             esysflt69,
             esysflt70,
             esysflt71,
             esysflt72,
             esysflt73,
             esysflt74,
             esysflt75,
             esysflt76,
             esysflt77,
             esysflt78,
             esysflt79,
             esysflt80,
             esysflt81,
             esysflt82,
             esysflt83,
             esysflt84,
             esysflt85,
             esysflt86,
             esysflt87,
             esysflt88,
             esysflt89,
             esysflt90,
             esysflt91,
             esysflt92,
             esysflt93,
             esysflt94,
             esysflt95,
             esysflt96,
             { system errors for machine module, "*" marks unused entries. }
             esysflt101,
             esysflt102,
             esysflt103,
             esysflt104,
             esysflt105,
             esysflt106,
             esysflt107,
             esysflt108,
             esysflt109,
             esysflt110,
             esysflt111,
             esysflt112,
             esysflt113,
             esysflt114,
             esysflt115,
             esysflt116,
             esysflt117,
             esysflt118,
             esysflt119,
             esysflt120,
             esysflt121,
             esysflt122,
             esysflt123,
             esysflt124,
             esysflt125,
             esysflt126,
             esysflt127,
             esysflt128,
             esysflt129,
             esysflt130,
             esysflt131,
             esysflt132,
             esysflt133,
             esysflt134,
             esysflt135,
             esysflt136,
             esysflt137,
             esysflt138,
             esysflt139,
             esysflt140,
             esysflt141,
             esysflt142,
             esysflt143,
             esysflt144,
             esysflt145,
             esysflt146,
             esysflt147,
             esysflt148,
             esysflt149,
             esysflt150,
             esysflt151,
             esysflt152,
             esysflt153,
             esysflt154,
             esysflt155,
             esysflt156,
             esysflt157,
             esysflt158,
             esysflt159,
             esysflt160,
             esysflt161,
             esysflt162,
             esysflt163,
             esysflt164,
             esysflt165,
             esysflt166,
             esysflt167,
             esysflt168,
             esysflt169,
             esysflt170,
             esysflt171,
             esysflt172,
             esysflt173,
             esysflt174,
             esysflt175,
             esysflt176,
             esysflt177,
             esysflt178,
             esysflt179,
             esysflt180,
             esysflt181,
             esysflt182,
             esysflt183,
             esysflt184,
             esysflt185,
             esysflt186,
             esysflt187,
             esysflt188,
             esysflt189,
             esysflt190,
             esysflt191,
             esysflt192,
             esysflt193,
             esysflt194,
             esysflt195,
             esysflt196,
             esysflt197,
             esysflt198,
             esysflt199,
             esysflt200,
             esysflt201,
             esysflt202,
             esysflt203,
             esysflt204,
             esysflt205,
             esysflt206,
             esysflt207,
             esysflt208,
             esysflt209,
             esysflt210,
             esysflt211,
             esysflt212,
             esysflt213,
             esysflt214,
             esysflt215,
             esysflt216,
             esysflt217,
             esysflt218,
             esysflt219,
             esysflt220,
             esysflt221,
             esysflt222,
             esysflt223,
             esysflt224,
             esysflt225,
             esysflt226,
             esysflt227,
             esysflt228,
             esysflt229,
             esysflt230,
             esysflt231,
             esysflt232,
             esysflt233,
             esysflt234,
             esysflt235,
             esysflt236,
             esysflt237,
             esysflt238,
             esysflt239, { * }
             esysflt240, { * }
             esysflt241, { * }
             esysflt242, { * }
             esysflt243, { * }
             esysflt244, { * }
             esysflt245, { * }
             esysflt246, { * }
             esysflt247, { * }
             esysflt248, { * }
             esysflt249, { * }
             esysflt250, { * }
             esysflt251, { * }
             esysflt252, { * }
             esysflt253, { * }
             esysflt254, { * }
             esysflt255,
             esysflt256,
             esysflt257,
             esysflt258,
             esysflt259, { * }
             esysflt260,
             esysflt261,
             esysflt262);

begin
end.
