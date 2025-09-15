{******************************************************************************
*                                                                             *
*                                 PASSIM                                      *
*                                                                             *
*                       PASCAL INTERMEDIATE SIMULATOR                         *
*                                                                             *
*                       Copyright (C) 1994 S. A. Moore                        *
*                                                                             *
*                              Written 7/94                                   *
*                                                                             *
* Loads and simulates a Pascal intermediate. The 'input' file to the program  *
* comes from the simulators input, and the output of the program appears on   *
* the output. In this version, only a single coordinated intermediate may be  *
* input, and no monitor or diagnostics are provided.                          *
* Accepts a command line of the form:                                         *
*                                                                             *
*    passim <file>                                                            *
*                                                                             *
* If the given file has no extention, we search first for file.opt, then for  *
* file.int. Otherwise, the file is opened under the extention given.          *
* The simulator works by loading all the type entries in the intermediate to  *
* typing tables in memory. The entries are cross linked as they are loaded.   *
* Symbols are ignored in this version. Intermediate code is translated as     *
* required and loaded into a single large 'memory' array of bytes, with cross *
* reference entries in the type table to resolve branching. Once the entire   *
* program is loaded, the references are resolved, global and local variables  *
* are resolved, and the program is run.                                       *
* The program is stored and run entirely within the memory array. All Pascal  *
* types are translated to storage in terms of bytes within the array.         *
* As running, the program has the following layout, which is very similar to  *
* typical machine language implementations:                                   *
*                                                                             *
*      --------------------                                                   *
*      | Program code     |                                                   *
*      --------------------                                                   *
*      | Constants        |                                                   *
*      --------------------                                                   *
*      | Global variables |                                                   *
*      --------------------                                                   *
*      | Heap             |                                                   *
*      |                  |                                                   *
*      ~                  ~                                                   *
*                                                                             *
*      ~                  ~                                                   *
*      |                  |                                                   *
*      | Stack            |                                                   *
*      --------------------                                                   *
*                                                                             *
* Where the heap grows up, and the stack grows down.                          *
* The code as is resident and fixed in memory is completely independent of    *
* the types table, which is only used to build the it.                        *
*                                                                             *
******************************************************************************}

program passim(output);

uses strlib, { strings }
     extlib, { extentions }
     parlib; { parsing library }

label 99; { abort simulator }

const

   maxmem  = 4000000; { size of simulated memory }
   strmax  = 200;     { maximum characters in string }
   intsiz  = 4;       { size of integer in bytes }
   relsiz  = 8;       { size of real in bytes }
   srlsiz  = 4;       { size of real in bytes }
   stksiz  = 4;       { size of stack element in bytes }
   setsiz  = 32;      { size of set in bytes }
   tgpsiz  = 8;       { size of tagged pointer }
   bolsiz  = 4;       { size of boolean }
   intfld  = 11;      { output width of integer }
   blffld  = 5;       { output width of boolean false }
   bltfld  = 6;       { output width of boolean true }
   chrfld  = 1;       { output width of character }
   rlfld   = 22;      { output width of real }
   maxopn  = 100;     { maximum number of open files }
   stkpad  = 1024;    { padding for expressions on stack }
   maxfil  = 100;     { file name length }
   cmdmax  = 250;     { maximum length of command string for actions }
  
type

   ext    = packed array [1..3] of char; { filename extention }
   meminx = 0..maxmem; { index for memory array }
   { intermediate operator codes. Contains all the codes for markers, types, 
     symbols, operations and other intermediate codes }
   intcod = (ibgnlvl,    { begin new block level }
             iendlvl,    { end current block level }
             iusefil,    { 'uses' file string }
             inil,       { 'nil' universal pointer }
             ilab,       { 'goto' label }
             iicst,      { integer constant }
             iscst,      { string constant }
             iccst,      { character constant }
             ircst,      { real constant }
             istcst,     { set constant }
             istet,      { set constant entry }
             iarrcst,    { array constant entry }
             iarrcel,    { array constant element }
             ireccst,    { record constant entry }
             ireccel,    { record constant element }
             ienum,      { enumerated type }
             ienme,      { enumerated constant }
             isub,       { subrange type }
             iptr,       { pointer type }
             iarray,     { array type }
             igarry,     { general array type }
             ifile,      { file type }
             iset,       { set type }
             irecord,    { record type }
             ifield,     { record field }
             iftag,      { record tag field }
             ifcas,      { record case constant }
             ivar,       { variable }
             ifix,       { fixed }
             iproc,      { procedure }
             ifunc,      { function }
             ipar,       { parameter }
             ivpar,      { variable parameter }
             iwpar,      { view parameter }
             ipproc,     { procedure parameter }
             ipfunc,     { fuction parameter }
             iint,       { integer type }
             ichar,      { character type }
             iboolean,   { output marker }
             ireal,      { real type }
             isreal,     { short real type }
             itext,      { text file type }
             ieset,      { empty set type }
             iglbl,      { global mark type }
             inull,      { placeholder type entry }
             isym,       { symbol entry }
             issym,      { simple symbol entry }
             ibgnpgm,    { program/procedure/function section entry }
             iendpgm,    { program/procedure/function section end }
             ibgnext,    { program exit section entry }
             iendext,    { program exit section end }
             ilodadr,     { load address operator }
             ilodfadr,   { load address function result operator }
             iarrref,    { array reference operator }
             iarfgar,    { general array reference operator }
             irecoff,    { record offset operator }
             ildiint,    { load indirect integer operator }
             ildirel,    { load indirect real operator }
             ildisrl,    { load indirect short real operator }
             ildiset,    { load indirect set operator }
             ildichr,    { load indirect character operator }
             ildibol,    { load indirect boolean operator }
             ildisrc,    { load indirect structure operator }
             ildiptr,    { load indirect pointer }
             ilditgp,    { load indirect tagged pointer }
             ilimint,    { load immediate integer operator }
             ilimrel,    { load immediate real operator }
             ilimns,     { load immediate empty set operator }
             ilodlen,    { load general array tag length }
             inotint,    { integer 'not' operator }
             inotbol,    { boolean 'not' operator }
             isinset,    { set single element operator }
             irngset,    { set range of elements operator }
             icvtitr,    { convert integer to real operator }
             icvtgtf,    { convert general to fixed array }
             icvtftg,    { convert fixed array to general }
             icvtntg,   { convert nil to tagged format }
             iswptop,    { swap top and second stack operator }
             iintset,    { set intersection operator }
             imltrel,    { multiply real operator }
             imltint,    { multiply integer operator }
             idivrel,    { divide real operator }
             idivint,    { divide integer operator }
             imodint,    { modulo integer operator }
             iandint,    { integer 'and' operator }
             inegint,    { negate integer operator }
             inegrel,    { negate real operator }
             iuniset,    { set union operator }
             iaddrel,    { add real operator }
             iaddint,    { add integer operator }
             idifset,    { set difference operator }
             isubrel,    { subtract real operator }
             isubint,    { subtract integer operator }
             iorint,     { 'or' integer operator }
             ixorint,    { 'xor' integer operator }
             iincset,    { set inclusion operator }
             iequset,    { set equal operator }
             iequrel,    { real equal operator }
             iequstr,    { string equal operator }
             iequgst,    { general string equal operator }
             iequint,    { integer equal operator }
             iequtgp,    { tagged pointer equal operator }
             ineqset,    { set not equal operator }
             ineqrel,    { real not equal operator }
             ineqstr,    { string not equal operator }
             ineqgst,    { general string not equal operator }
             ineqint,    { integer not equal operator }
             ineqtgp,    { tagged pointer not equal operator }
             ileqset,    { set less than or equal operator }
             ileqrel,    { real less than or equal operator }
             ileqstr,    { string less than or equal operator }
             ileqgst,    { general string less than or equal operator }
             ileqint,    { integer less than or equal operator }
             igeqset,    { set greater than or equal operator }
             igeqrel,    { real greater than or equal operator }
             igeqstr,    { string greater than or equal operator }
             igeqgst,    { general string greater than or equal operator }
             igeqint,    { integer greater than or equal operator }
             iltnrel,    { real less than operator }
             iltnstr,    { string less than operator }
             iltngst,    { general string less than operator }
             iltnint,    { integer less than operator }
             igtnrel,    { real greater than operator }
             igtnstr,    { string greater than operator }
             igtngst,    { general string greater than operator }
             igtnint,    { integer greater than operator }
             ibgnblk,    { begin statement block operator }
             iendblk,    { end statement block operator }
             iifbgn,     { if begin operator }
             iifend,     { if end operator }
             ielse,      { else operator } 
             icasbgn,    { case begin operator }
             icasend,    { case end operator }
             icassint,   { case select integer }
             icasstb,    { case statement begin }
             icasste,    { case statement end }
             iwhlexp,    { while expression marker }
             iwhlbgn,    { while begin operator }
             iwhlend,    { while end operator }
             irptbgn,    { repeat begin operator }
             irptend,    { repeat end operator }
             ifortint,   { for 'to' integer operator }
             ifortchr,   { for 'to' character operator }
             ifortbol,   { for 'to' boolean operator }
             ifordint,   { for 'downto' integer operator }
             ifordchr,   { for 'downto' character operator }
             ifordbol,   { for 'downto' boolean operator }
             iforend,    { for end operator }
             iwthbgn,    { with begin operator }
             iwthend,    { with end operator }
             igoto,      { goto operator }
             iprcbgn,    { procedure call parameter start operator }
             iprccal,    { procedure call operator }
             iprccali,   { procedure call indirect operator }
             ifncbgn,    { function call parameter start operator }
             ifnccal,    { function call operator }
             ifnccali,   { function call indirect operator }
             iwrtsrc,    { write file operator }
             iwrtintt,   { write integer operator }
             iwrtchrt,   { write character operator }
             iwrtbolt,   { write boolean operator }
             iwrtrelt,   { write real operator }
             iwrtstrt,   { write string operator }
             iwrtgstt,   { write general string operator }
             iwrtintft,  { write integer fielded operator }
             iwrtchrft,  { write character fielded operator }
             iwrtbolft,  { write boolean fielded operator }
             iwrtrelft,  { write real fielded operator }
             iwrtstrft,  { write string fielded operator }
             iwrtgstft,  { write general string fielded operator }
             iwrtrelfft, { write real fielded and fractioned operator }
             iwrtsrl,    { write file short real }
             iwrtrel,    { write file real }
             iwrtset,    { write file set }
             iwrtbol,    { write file boolean }
             iwrtchr,    { write file character }
             iwrtint,    { write file integer }
             iwrteolt,   { write file end of line }
             iredsrc,    { read file operator }
             iredintt,   { read integer operator }
             iredchrt,   { read character operator }
             iredrelt,   { read real operator }
             iredsrlt,   { read short real operator }
             iredeolt,   { read file end of line }
             iabsrel,    { abs of real operator }
             iabsint,    { abs of integer operator }
             isqrrel,    { sqr of real operator }
             isqrint,    { sqr of integer operator }
             iatnrel,    { arctan of real operator }
             icosrel,    { cos of real operator }
             iexprel,    { exp of real operator }
             ilgnrel,    { ln of real operator }
             isinrel,    { sin of real operator }
             isqtrel,    { sqrt of real operator }
             ieolt,      { eoln of file operator }
             ieof,       { eof of file operator }
             iodd,       { odd of integer operator }
             isucint,    { succ of integer operator }
             iprdint,    { pred of integer operator }
             irnd,       { round operator }
             itrc,       { trunc operator }
             iexist,     { file exists operator }
             ilen,       { file length operator }
             iloc,       { file location operator }
             iget,       { file get operator }
             igett,      { text file get operator }
             iput,       { file put operator }
             ilodafbuf,  { load address of file buffer }
             ilodafbuft, { load address of text file buffer }
             ireset,     { file reset operator }
             irewrite,   { file rewrite operator }
             iclose,     { file close operator }
             ipack,      { pack operator }
             iunpack,    { unpack operator }
             ipaget,     { page operator }
             iassign,    { assign file operator }
             ipos,       { position file operator }
             idel,       { delete file operator }
             ichg,       { change file operator }
             istiint,    { store integer operator }
             istisrl,    { store short real operator }
             istirel,    { store real operator }
             istichr,    { store character operator }
             istibol,    { store boolean operator }
             istiset,    { store set operator }
             istisrc,    { store structured operator }
             istigar,    { store general array }
             istitgp,    { store tagged pointer }
             istifint,   { store function result integer operator }
             istiftgp,   { store function result tagged pointer operator }
             istifsrl,   { store function result short real operator }
             istifrel,   { store function result real operator }
             istifchr,   { store function result character operator }
             istifbol,   { store function result boolean operator }
             inew,       { new operator }
             idisp,      { dispose operator }
             itag,       { tagfield constant operator }
             iendtag,    { end of tagfields operator }
             ipoptop,    { remove top stack operator }
             ilabequ,    { 'goto' label equation }
             irngchk,    { range check }
             inewgar,    { allocate tagged array }
             idspgar,    { deallocate tagged array }
             ihalt,      { halt program }
             iendfil,    { end of file }
             icvtrtsr,   { convert real to short real }
             isetlin,    { set current line }
             isetsrc);   { set current source file }
   { machine operation codes. Defines the opcodes for our internal interpreter.
     Each internal instruction begins with an opcode byte, followed by zero or
     more operands }
   opcod = (opstkoff,    { offset stack }
            oplodcloc,   { load from current local area }
            oplodaloc,   { load address local }
            oprngchk,    { check range }
            opindint,    { load indirect integer }
            opindrl,     { load indirect real }
            opindsrl,    { load indirect short real }
            opindset,    { load indirect set }
            opindchr,    { load indirect character }
            opindstr,    { load indirect structure }
            oplodiint,   { load immediate integer operator }
            oplodirl,    { load immediate real operator }
            oplodins,    { load immediate empty set operator }
            opnotint,    { integer 'not' operator }
            opnotbol,    { boolean 'not' operator }
            opsetsin,    { set single element operator }
            opsetrng,    { set range of elements operator }
            opcvtitr,    { convert integer to real operator }
            opcvtfix,    { convert tagged to fixed pointer }
            opcvttag,    { convert fixed pointer to tagged }
            opsetint,    { set intersection operator }
            opmltrl,     { multiply real operator }
            opmltint,    { multiply integer operator }
            opdivrl,     { divide real operator }
            opdivint,    { divide integer operator }
            opmodint,    { modulo integer operator }
            opandint,    { integer 'and' operator }
            opnegint,    { negate integer operator }
            opnegrl,     { negate real operator }
            opsetuni,    { set union operator }
            opaddrl,     { add real operator }
            opaddint,    { add integer operator }
            opsetdif,    { set difference operator }
            opsubrl,     { subtract real operator }
            opsubint,    { subtract integer operator }
            oporint,     { 'or' integer operator }
            opxorint,    { 'xor' integer operator }
            opsetin,     { set inclusion operator }
            opequset,    { set equal operator }
            opequrl,     { real equal operator }
            opequstr,    { string equal operator }
            opequgst,    { string equal operator }
            opequint,    { integer equal operator }
            opequtgp,    { tagged pointer equal operator }
            opltnrl,     { real less than operator }
            opltnstr,    { string less than operator }
            opltngst,    { general string less than operator }
            opltnint,    { integer less than operator }
            opgtnrl,     { real greater than operator }
            opgtnstr,    { string greater than operator }
            opgtngst,    { general string greater than operator }
            opgtnint,    { integer greater than operator }
            opleqset,    { set less than or equal }
            opgeqset,    { set greater than or equal }
            opjmp,       { jump unconditional }
            opjpf,       { jump if false }
            opjpt,       { jump if true }
            opduptop,    { duplicate top of stack }
            oppoptop,    { pop top off stack }
            opswptop,    { swap top and second stack elements }
            opswprr,     { swap real with real }
            opswpri,     { swap real with inetger }
            opswpir,     { swap integer with real }
            opswpii,     { swap integer with integer }
            opswpti,     { swap tagged pointer with integer }
            opsucint,    { succ of integer operator }
            opprdint,    { pred of integer operator }
            opgoto,      { goto location }
            opcall,      { call procedure/function }
            opcalli,     { call procedure/function indirect }
            opret,       { return from procedure/function }
            opretoff,    { return with stack offset }
            opwrtfil,    { write file operator }
            opwrtbol,    { write boolean operator }
            opwrtgst,    { write general string }
            opwrtintf,   { write integer fielded operator }
            opwrtchrf,   { write character fielded operator }
            opwrtbolf,   { write boolean fielded operator }
            opwrtrlf,    { write real fielded operator }
            opwrtstrf,   { write string fielded operator }
            opwrtgstf,   { write general string fielded operator }
            opwrtrlff,   { write real fielded and fractioned operator }
            opwrtfsrl,   { write file short real }
            opwrtfrl,    { write file real }
            opwrtfset,   { write file set }
            opwrtfchr,   { write file character }
            opwrtfint,   { write file integer }
            opwrteoln,   { write file eoln }
            oprdfil,     { read file operator }
            oprdint,     { read integer operator }
            oprdchr,     { read character operator }
            oprdrl,      { read real operator }
            oprdsrl,     { read short real operator }
            oprdeoln,    { read file eoln }
            opabsrl,     { abs of real operator }
            opabsint,    { abs of integer operator }
            opsqrrl,     { sqr of real operator }
            opsqrint,    { sqr of integer operator }
            opatnrl,     { arctan of real operator }
            opcosrl,     { cos of real operator }
            opexprl,     { exp of real operator }
            oplnrl,      { ln of real operator }
            opsinrl,     { sin of real operator }
            opsqtrl,     { sqrt of real operator }
            opeoln,      { eoln of file operator }
            opeof,       { eof of file operator }
            opodd,       { odd of integer operator }
            oprnd,       { round operator }
            optrc,       { trunc operator }
            opexist,     { file exists operator }
            oplen,       { file length operator }
            oploc,       { file location operator }
            opget,       { file get operator }
            opgett,      { text file get operator }
            opput,       { file put operator }
            oplodafbuf,  { load file buffer address }
            oplodafbuft, { load text file buffer address }
            opreset,     { file reset operator }
            opresett,    { file reset text operator }
            oprewrite,   { file rewrite operator }
            oprewritet,  { file rewrite text operator }
            opclose,     { file close operator }
            oppage,      { page operator }
            opassign,    { assign file operator }
            oppos,       { position file operator }
            opdel,       { delete file operator }
            opchg,       { change file operator }
            opstosrl,    { store short real operator }
            opstorl,     { store real operator }
            opstoi,      { store integer operator }
            opstochr,    { store character operator }
            opstoset,    { store set operator }
            opstostr,    { store structured operator }
            opstogar,    { store general array }
            opstotgp,    { store tagged pointer }
            opnew,       { new operator }
            opdisp,      { dispose operator }
            opstostk,    { store stack }
            opnewgar,    { allocate general array }
            opdspgar,    { deallocate general array }
            oparfgar,    { general array reference }
            opexit);     { exit simulation }
   strinx = 1..strmax; { index for string }
   stringt = record { string }

               len: 0..strmax; { string index }
               str: packed array [1..strmax] of char { string data }

            end;
   { mark types }
   mrktyp = (mtsystem,  { system }
             mtprogram, { program }
             mtmodule,  { module }
             mtprocess, { process }
             mtmonitor, { monitor }
             mtshare);  { share }
   { type codes 
     In our system, types are a loose word standing for anything that is 
     predeclared and therefore requires a data structure to represent
     it. Type entries may be indexed by symbols, or may be "anonymous" }
   types  = (tudf,     { no type, used to mark errors }
             tnil,     { 'nil' universal pointer }
             tlab,     { goto label }
             ticst,    { integer constant }
             tscst,    { string constant }
             tccst,    { character constant }
             trcst,    { real constant }
             tstcst,   { set constant }
             tstet,    { set constant entry }
             tarrcst,  { array constant entry }
             tarrcel,  { array constant element }
             treccst,  { record constant entry }
             treccel,  { record constant element }
             tenum,    { enumerated }
             tenme,    { enumerated constant }
             tsub,     { subrange }
             tptr,     { pointer }
             tarray,   { array }
             tgarry,   { general array }
             tfile,    { file }
             tset,     { set }
             trecord,  { record }
             tfield,   { record field }
             tftag,    { record tag field }
             tfcas,    { record variant case }
             tvar,     { variable }
             tfix,     { fixed }
             tproc,    { procedure }
             tfunc,    { function }
             tpar,     { parameter }
             tvpar,    { variable parameter }
             twpar,    { view parameter }
             tpproc,   { procedure parameter }
             tpfunc,   { function parameter }
             tinteger, { integer }
             tchar,    { character }
             tboolean, { boolean }
             treal,    { real }
             tsreal,   { short real }
             ttext,    { text }
             teset,    { empty set }
             tglbl,    { global block }
             tnull,    { placeholder entry }
             tfuncr,   { function result variable }
             tlink);   { linking entry }
   typptr = ^typ; { type pointer }
   typ    = record { type entry }
            
               next:   typptr; { next list entry }
               addr:   meminx; { address of type (if variable) }
               size:   integer; { size of type in bytes }
               local:  boolean; { what address space occupied }
               disp:   meminx;  { display address }
               case t: types of { types }

                  tudf:     ();              { dummy entry to mark errors }
                  tnil:     ();              { 'nil' universal pointer }
                  tlab:     ();              { 'goto' label }
                  ticst:    (ival: integer); { the value of the integer }
                  tscst:    (sval: stringt); { the value of the string }
                  tccst:    (cval: char);    { value of character }
                  trcst:    (rval: real);    { the value of the real }
                  tstcst:   (stct: typptr;   { base type of set }
                             stcc: typptr);  { set constant list }
                  tstet:    (sten: typptr;   { next set element }
                             stes: integer;  { starting value }
                             stee: integer;  { ending value }
                             steh: typptr);  { head entry }
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
                  tsub:     (subt: typptr;   { base type }
                             subl: integer;  { lower bound }
                             subu: integer); { upper bound }
                  tptr:     (ptrt: typptr);  { base type }
                  tarray:   (arrt: typptr;   { base type }
                             arri: typptr);  { index type }
                  tgarry:   (gart: typptr);  { base type }
                  tfile:    (filt: typptr);  { base type }
                  tset:     (sett: typptr);  { base type }
                  trecord:  (recf: typptr);  { field list }
                  tfield:   (fldn: typptr;   { next field pointer }
                             fldh: typptr;   { head entry pointer }
                             fldt: typptr);  { base type }
                  tftag:    (ftgc: typptr;   { case list }
                             ftgh: typptr;   { head entry pointer }
                             ftgt: typptr;   { base type }
                             ftge: boolean); { exists flag }
                  tfcas:    (fcsn: typptr;   { next case entry pointer }
                             fcsf: typptr;   { field list }
                             fcsc: integer); { case constant }
                  tvar:     (vart: typptr;   { base type }
                             vare: boolean); { variable is external }
                  tfix:     (fixt: typptr;   { base type }
                             fixc: typptr;   { constant fill }
                             fixe: boolean); { fixed is external }
                  tproc:    (prcp: typptr;   { parameter list }
                             prcv: integer;  { total locals allocation }
                             prca: integer;  { total parameters allocation }
                             prce: boolean); { procedure is external }
                  tfunc:    (fncp: typptr;   { parameter list }
                             fncr: typptr;   { function result }
                             fncv: integer;  { total locals allocation }
                             fnca: integer;  { total parameters allocation }
                             fnce: boolean); { function is external }
                  tpar:     (parn: typptr;   { next parameter }
                             part: typptr;   { base type }
                             parh: typptr);  { head entry pointer }
                  tvpar:    (vprn: typptr;   { next parameter }
                             vprt: typptr;   { base type }
                             vprh: typptr);  { head entry pointer }
                  twpar:    (wprn: typptr;   { next parameter }
                             wprt: typptr;   { base type }
                             wprh: typptr);  { head entry pointer }
                  tpproc:   (pprp: typptr;   { parameter list }
                             pprn: typptr);  { next parameter }
                  tpfunc:   (pfnp: typptr;   { parameter list }
                             pfnr: typptr;   { function result }           
                             pfnn: typptr);  { next parameter }
                  tinteger: ();              { integer }
                  tchar:    ();              { character }
                  tboolean: (bnc:  typptr);  { list of enumerated constants }
                  treal:    ();              { real }
                  tsreal:   ();              { short real }
                  ttext:    ();              { text file }
                  teset:    ();              { empty set }
                  tglbl:    (mrkt: mrktyp);  { mark type }
                  tnull:    ();              { placeholder }
                  tfuncr:   (fnrt: typptr);  { base type }
                  tlink:    (lnkl: integer;  { linkage level }
                             lnke: integer); { linkage entry }


               { end }

            end;
   typset = set of types; { set of types }
   tpsptr = ^tps; { pointer to type stack entry }
   tps    = record { type stack entry }

               next: tpsptr;  { next entry }
               typ:  typptr;  { type list for block }
               lst:  typptr;  { last entry in type list }
               res:  typptr;  { next resolvable entry }
               typa: typptr;  { alternate types list }
               lsta: typptr;  { last entry in alternate type list }
               resa: typptr;  { next resolvable alternate entry }
               mark: typptr;  { mark for block }
               lvl:  integer; { level number }
               loc:  boolean  { locals allocated for block }

            end;
    { nested structure tracking entrys }
    srtptr = ^struct;
    struct = record { structure entry }

                next:            srtptr;  { next entry }
                lab, lab1, lab2: typptr;  { label pointers }
                ic:              intcod;  { tolken save }
                withm:           boolean; { entry is 'with' block }
                off:             integer  { 'with' stack offset for base
                                            record }

             end;
    { patch insertion types }
    ityp   = (itadr,  { address }
              itdsp); { display address }
    rldptr = ^rld; { relocation entry pointer }
    rld    = record { relocation entry }

                next: rldptr; { next entry }      
                addr: meminx; { address to patch in memory }
                lab:  typptr; { entry to patch with }
                it:   ityp    { insertion type }

             end;
    { file name }
    filinx = 1..maxfil; { index for filenames }
    filnam = packed array [filinx] of char; { filename }
    { file type }
    filtyp = (ftbin,  { binary }
              fttxt); { text }
    filpnt = ^fildat; { pointer to file record }
    fildat = record

                mode: (fmund, fmread, fmwrite); { file open mode }
                com:  boolean; { file is command line }
                rlen: integer; { length of record }
                nam:  filnam; { name of file }
                full: boolean; { buffer full flag }
                buf:  integer; { location of file buffer }
                { we split the file types by text and non-text to allow us to
                  make use of the standard text I/O processing }
                case typ: filtyp of { file type }

                   ftbin: (bfil: bytfil); { binary file }
                   fttxt: (tfil: text)    { text file }

                { end }

             end;
    { source marker control system }
    srcptr = ^srcequ; { pointer to source head }
    linptr = ^linequ; { pointer to line equate entry }
    linequ = record { line equate entry }

                lin:  integer; { original source line number }
                equ:  meminx;  { equivalent in program code }
                src:  srcptr;  { parent source pointer }
                mast: linptr;  { master line list link }
                next: linptr   { next in list }

             end;
    srcequ = record { source equate entry }

                nam:  filnam; { name of soure file }
                lin:  linptr; { list of contained line equates }
                next: srcptr { next in list }

             end;
    { errors }
    errcod = (einvitc,  { invalid intermediate code }
              einvfmt,  { invalid intermediate code format }
              efilnf,   { file does not exist }
              einvfnm,  { file name is invalid }
              einvcmd,  { command line invalid }
              ememovf,  { code memory overflow }
              estkovf,  { stack overflow }
              estkunf,  { stack underflow }
              erngchk,  { range check }
              einvelm,  { invalid set element }
              efilopn,  { file is open }
              efilass,  { file already assigned }
              eftbful,  { file table full }
              efilnop,  { file not open }
              efilmod,  { file not in correct mode }
              eunimp,   { operation not implemented }
              etmpovf,  { temporary files overflow }
              einvpos,  { invalid position }
              esysrdo,  { system file is read only }
              esyslen,  { system file must be character size }
              elenmat,  { array sizes don't match }
              edivzer,  { divide by zero }
              esysflt); { system error }

var

   intfil:  bytfil;    { intermediate file }
   intnam:  filnam;    { intermediate file name }
   crsent:  boolean;   { cr sent in command line }
   lfsent:  boolean;   { lf sent in command line }
   fi:      filinx;    { index for filenames }
   memory:  array [meminx] of byte; { simulator memory }
   typstk:  tpsptr;    { types stack }
   typlst:  tpsptr;    { types list }
   ic:      intcod;    { intermediate code holder }
   blkcnt:  integer;   { block nesting counter }
   pgmcnt:  meminx;    { program sequence counter/load counter }
   stack:   integer;   { stack pointer }
   heap:    meminx;    { heap pointer }
   heaps:   meminx;    { heap start }
   pgmend:  meminx;    { end of code store }
   conend:  meminx;    { end of constants }
   disend:  meminx;    { end of display }
   srtstk:  srtptr;    { structure tracking stack }
   srtfre:  srtptr;    { structure tracking free list }
   rldlst:  rldptr;    { relocation entry list }
   gblint:  typptr;    { global integer type }
   gblchr:  typptr;    { global character type }
   gblreal: typptr;    { global real type }
   oc:      opcod;     { operation code holder }
   opnfil:  array [1..maxopn] of filpnt; { open files table }
   ofi:     1..maxopn; { index for files table }
   tmpcnt:  integer;   { temporary files counter }
   fretyp:  array [types] of typptr; { free types lists }
   fti:     types;     { index for free types lists }
   cmdhan:  parhan;    { handle for command parsing }
   valfch:  chrset;    { valid file characters }
   srclst:  srcptr;    { source equate list }
   cursrc:  srcptr;    { currently active source entry }
   linlst:  linptr;    { master line list }

{******************************************************************************

Abort simulation

Halts the simulation.

******************************************************************************}

procedure abort; 

begin 

   goto 99 { terminate program } 

end;

{******************************************************************************

Process simulator error

Prints the given error code and halts the simulation.

******************************************************************************}

procedure error(e: errcod);

var si: strinx;  { string index }
    sf: text;    { source file for error }
    lc: integer; { source line counter }
    c:  char;

var lp, fp: linptr; { line list pointers }

begin

   { check source is available }
   fp := nil; { set no entry found }
   if linlst <> nil then begin { search line list }

      { Searching the line list is done by finding the line whose program
        address is the closest one to the current location, but below it. }
      lp := linlst; { index top of line list }
      while lp <> nil do begin { traverse }

         if lp^.equ <= pgmcnt then begin { this line is below or at, check }

            if fp = nil then fp := lp { no line to check, set that as found }
            else if lp^.equ > fp^.equ then fp := lp { closer, set }

         end;
         lp := lp^.mast { link next in master list }

      end;
      if fp <> nil then begin { a line was found }

         if exists(fp^.src^.nam) then begin 

            { source file still exists, find and print the line }
            assign(sf, fp^.src^.nam); { open the file }
            reset(sf);
            lc := 1; { set on first line }
            while (lc < fp^.lin) and not eof(sf) do begin { skip lines }

               readln(sf); { skip this line }
               lc := lc+1 { count }

            end;
            if (lc = fp^.lin) and not eof(sf) then begin { print line }

               while not eoln(sf) do begin { print characters }

                  read(sf, c); { get a character }
                  write(c)

               end;
               writeln { terminate line }

            end

         end

      end

   end;
   write('*** ');
   { print source spec if available }
   if fp <> nil then write(fp^.src^.nam:0, ':', fp^.lin:1, ' ');
   case e of { error }

      
      einvitc: writeln('Invalid intermediate code');
      einvfmt: writeln('Invalid intermediate code format');
      efilnf:  writeln('File does not exist');
      einvfnm: writeln('File name is invalid');
      einvcmd: writeln('Command line invalid');
      ememovf: writeln('Code memory overflow');
      estkovf: writeln('Stack overflow');
      estkunf: writeln('Stack underflow');
      erngchk: writeln('Range check');
      einvelm: writeln('Invalid set element');
      efilopn: writeln('File is open');
      efilass: writeln('File already assigned');
      eftbful: writeln('Maximum file limit reached');
      efilnop: writeln('File not open');
      efilmod: writeln('File not in correct mode for operation');
      eunimp:  writeln('Operation not implemented');
      etmpovf: writeln('Temporary files overflow');
      einvpos: writeln('Invalid position');
      esysrdo: writeln('System file is read-only');
      esyslen: writeln('System file must be character size');
      elenmat: writeln('Array sizes do not match');
      edivzer: writeln('Divide by zero');
      esysflt: writeln('System fault: Notify S. A. Moore software')

   end;
   abort { end simulation }

end;

{******************************************************************************

Print intermediate input code

This is for diagnostic purposes. Prints the string for each input intermediate
code.

******************************************************************************}

procedure prtic(ic: intcod);

begin

   case ic of { code }

      ibgnlvl:    write('ibgnlvl');
      iendlvl:    write('iendlvl');
      iusefil:    write('iusefil');
      inil:       write('inil');
      ilab:       write('ilab');
      iicst:      write('iicst');
      iscst:      write('iscst');
      iccst:      write('iccst');
      ircst:      write('ircst');
      istcst:     write('istcst');
      istet:      write('istet');
      iarrcst:    write('iarrcst');
      iarrcel:    write('iarrcel');
      ireccst:    write('ireccst');
      ireccel:    write('ireccel');
      ienum:      write('ienum');
      ienme:      write('ienme');
      isub:       write('isub');
      iptr:       write('iptr');
      iarray:     write('iarray');
      igarry:     write('igarry');
      ifile:      write('ifile');
      iset:       write('iset');
      irecord:    write('irecord');
      ifield:     write('ifield');
      iftag:      write('iftag');
      ifcas:      write('ifcas');
      ivar:       write('ivar');
      ifix:       write('ifix');
      iproc:      write('iproc');
      ifunc:      write('ifunc');
      ipar:       write('ipar');
      ivpar:      write('ivpar');
      iwpar:      write('iwpar');
      ipproc:     write('ipproc');
      ipfunc:     write('ipfunc');
      iint:       write('iint');
      ichar:      write('ichar');
      iboolean:   write('iboolean');
      ireal:      write('ireal');
      isreal:     write('isreal');
      itext:      write('itext');
      ieset:      write('ieset');
      iglbl:      write('iglbl');
      inull:      write('inull');
      isym:       write('isym');
      issym:      write('issym');
      ibgnpgm:    write('ibgnpgm');
      iendpgm:    write('iendpgm');
      ibgnext:    write('ibgnext');
      iendext:    write('iendext');
      ilodadr:    write('ilodadr');
      ilodfadr:   write('ilodfadr');
      iarrref:    write('iarrref');
      iarfgar:    write('iarfgar');
      irecoff:    write('irecoff');
      ildiint:    write('ildiint');
      ildirel:    write('ildirel');
      ildisrl:    write('ildisrl');
      ildiset:    write('ildiset');
      ildichr:    write('ildichr');
      ildibol:    write('ildibol');
      ildisrc:    write('ildisrc');
      ildiptr:    write('ildiptr');
      ilditgp:    write('ilditgp');
      ilimint:    write('ilimint');
      ilimrel:    write('ilimrel');
      ilimns:     write('ilimns');
      ilodlen:    write('ilodlen');
      inotint:    write('inotint');
      inotbol:    write('inotbol');
      isinset:    write('isinset');
      irngset:    write('irngset');
      icvtitr:    write('icvtitr');
      icvtgtf:    write('icvtgtf');
      icvtftg:    write('icvtftg');
      iswptop:    write('iswptop');
      iintset:    write('iintset');
      imltrel:    write('imltrel');
      imltint:    write('imltint');
      idivrel:    write('idivrel');
      idivint:    write('idivint');
      imodint:    write('imodint');
      iandint:    write('iandint');
      inegint:    write('inegint');
      inegrel:    write('inegrel');
      iuniset:    write('iuniset');
      iaddrel:    write('iaddrel');
      iaddint:    write('iaddint');
      idifset:    write('idifset');
      isubrel:    write('isubrel');
      isubint:    write('isubint');
      iorint:     write('iorint');
      ixorint:    write('ixorint');
      iincset:    write('iincset');
      iequset:    write('iequset');
      iequrel:    write('iequrel');
      iequstr:    write('iequstr');
      iequgst:    write('iequgst');
      iequint:    write('iequint');
      iequtgp:    write('iequtgp');
      ineqset:    write('ineqset');
      ineqrel:    write('ineqrel');
      ineqstr:    write('ineqstr');
      ineqgst:    write('ineqgst');
      ineqint:    write('ineqint');
      ineqtgp:    write('ineqtgp');
      ileqset:    write('ileqset');
      ileqrel:    write('ileqrel');
      ileqstr:    write('ileqstr');
      ileqgst:    write('ileqgst');
      ileqint:    write('ileqint');
      igeqset:    write('igeqset');
      igeqrel:    write('igeqrel');
      igeqstr:    write('igeqstr');
      igeqgst:    write('igeqgst');
      igeqint:    write('igeqint');
      iltnrel:    write('iltnrel');
      iltnstr:    write('iltnstr');
      iltngst:    write('iltngst');
      iltnint:    write('iltnint');
      igtnrel:    write('igtnrel');
      igtnstr:    write('igtnstr');
      igtngst:    write('igtngst');
      igtnint:    write('igtnint');
      ibgnblk:    write('ibgnblk');
      iendblk:    write('iendblk');
      iifbgn:     write('iifbgn');
      iifend:     write('iifend');
      ielse:      write('ielse');
      icasbgn:    write('icasbgn');
      icasend:    write('icasend');
      icassint:   write('icassint');
      icasstb:    write('icasstb');
      icasste:    write('icasste');
      iwhlexp:    write('iwhlexp');
      iwhlbgn:    write('iwhlbgn');
      iwhlend:    write('iwhlend');
      irptbgn:    write('irptbgn');
      irptend:    write('irptend');
      ifortint:   write('ifortint');
      ifortchr:   write('ifortchr');
      ifortbol:   write('ifortbol');
      ifordint:   write('ifordint');
      ifordchr:   write('ifordchr');
      ifordbol:   write('ifordbol');
      iforend:    write('iforend');
      iwthbgn:    write('iwthbgn');
      iwthend:    write('iwthend');
      igoto:      write('igoto');
      iprcbgn:    write('iprcbgn');
      iprccal:    write('iprccal');
      iprccali:   write('iprccali');
      ifncbgn:    write('ifncbgn');
      ifnccal:    write('ifnccal');
      ifnccali:   write('ifnccali');
      iwrtsrc:    write('iwrtsrc');
      iwrtintt:   write('iwrtintt');
      iwrtchrt:   write('iwrtchrt');
      iwrtbolt:   write('iwrtbolt');
      iwrtrelt:   write('iwrtrelt');
      iwrtstrt:   write('iwrtstrt');
      iwrtgstt:   write('iwrtgstt');
      iwrtintft:  write('iwrtintft');
      iwrtchrft:  write('iwrtchrft');
      iwrtbolft:  write('iwrtbolft');
      iwrtrelft:  write('iwrtrelft');
      iwrtstrft:  write('iwrtstrft');
      iwrtgstft:  write('iwrtgstft');
      iwrtrelfft: write('iwrtrelfft');
      iwrtsrl:    write('iwrtsrl');
      iwrtrel:    write('iwrtrel');
      iwrtset:    write('iwrtset');
      iwrtbol:    write('iwrtbol');
      iwrtchr:    write('iwrtchr');
      iwrtint:    write('iwrtint');
      iwrteolt:   write('iwrteolt');
      iredsrc:    write('iredsrc');
      iredintt:   write('iredintt');
      iredchrt:   write('iredchrt');
      iredrelt:   write('iredrelt');
      iredsrlt:   write('iredsrlt');
      iredeolt:   write('iredeolt');
      iabsrel:    write('iabsrel');
      iabsint:    write('iabsint');
      isqrrel:    write('isqrrel');
      isqrint:    write('isqrint');
      iatnrel:    write('iatnrel');
      icosrel:    write('icosrel');
      iexprel:    write('iexprel');
      ilgnrel:    write('ilgnrel');
      isinrel:    write('isinrel');
      isqtrel:    write('isqtrel');
      ieolt:      write('ieolt');
      ieof:       write('ieof');
      iodd:       write('iodd');
      isucint:    write('isucint');
      iprdint:    write('iprdint');
      irnd:       write('irnd');
      itrc:       write('itrc');
      iexist:     write('iexist');
      ilen:       write('ilen');
      iloc:       write('iloc');
      iget:       write('iget');
      igett:      write('igett');
      iput:       write('iput');
      ilodafbuf:  write('ilodafbuf');
      ilodafbuft: write('ilodafbuft');
      ireset:     write('ireset');
      irewrite:   write('irewrite');
      iclose:     write('iclose');
      ipack:      write('ipack');
      iunpack:    write('iunpack');
      ipaget:     write('ipaget');
      iassign:    write('iassign');
      ipos:       write('ipos');
      idel:       write('idel');
      ichg:       write('ichg');
      istiint:    write('istiint');
      istisrl:    write('istisrl');
      istirel:    write('istirel');
      istichr:    write('istichr');
      istibol:    write('istibol');
      istiset:    write('istiset');
      istisrc:    write('istisrc');
      istigar:    write('istigar');
      istitgp:    write('istitgp');
      istifint:   write('istifint');
      istiftgp:   write('istiftgp');
      istifsrl:   write('istifsrl');
      istifrel:   write('istifrel');
      istifchr:   write('istifchr');
      istifbol:   write('istifbol');
      inew:       write('inew');
      idisp:      write('idisp');
      itag:       write('itag');
      iendtag:    write('iendtag');
      ipoptop:    write('ipoptop');
      ilabequ:    write('ilabequ');
      irngchk:    write('irngchk');
      inewgar:    write('inewgar');
      idspgar:    write('idspgar');
      ihalt:      write('ihalt');
      iendfil:    write('iendfil');
      icvtrtsr:   write('icvtrtsr');
      isetlin:    write('isetlin');
      isetsrc:    write('isetsrc');

   end

end;

{******************************************************************************

Print type

Prints the given type. This is a diagnostic.

******************************************************************************}

procedure prttyp(t: types);

begin

   case t of { type }

      tudf:     write('tudf');
      tnil:     write('tnil');
      tlab:     write('tlab');
      ticst:    write('ticst');
      tscst:    write('tscst');
      tccst:    write('tccst');
      trcst:    write('trcst');
      tstcst:   write('tstcst');
      tstet:    write('tstet');
      tarrcst:  write('tarrcst');
      tarrcel:  write('tarrcel');
      treccst:  write('treccst');
      treccel:  write('treccel');
      tenum:    write('tenum');
      tenme:    write('tenme');
      tsub:     write('tsub');
      tptr:     write('tptr');
      tarray:   write('tarray');
      tgarry:   write('tgarry');
      tfile:    write('tfile');
      tset:     write('tset');
      trecord:  write('trecord');
      tfield:   write('tfield');
      tftag:    write('tftag');
      tfcas:    write('tfcas');
      tvar:     write('tvar');
      tfix:     write('tfix');
      tproc:    write('tproc');
      tfunc:    write('tfunc');
      tpar:     write('tpar');
      tvpar:    write('tvpar');
      twpar:    write('twpar');
      tpproc:   write('tpproc');
      tpfunc:   write('tpfunc');
      tinteger: write('tinteger');
      tchar:    write('tchar');
      tboolean: write('tboolean');
      treal:    write('treal');
      tsreal:   write('tsreal');
      ttext:    write('ttext');
      teset:    write('teset');
      tglbl:    write('tglbl');
      tnull:    write('tnull');
      tfuncr:   write('tfuncr');
      tlink:    write('tlink')

   end

end;

{******************************************************************************

Find type

Finds the given type in a list. Returns the sequence number of the type in the
list.

******************************************************************************}

function fndtyp(tp: typptr; { type to find }
                lp: typptr) { list of types }
                :integer;   { sequence number }

var ic: integer; { sequence count }

begin

   ic := 0; { set no entry }
   while lp <> nil do begin { search }

      ic := ic+1; { count entries }
      if tp = lp then lp := nil { found the entry }
      else begin { advance to next entry }

         lp := lp^.next; { next entry }
         if lp = nil then ic := 0 { set no entry }

      end

   end;
   fndtyp := ic { return count }

end;

{******************************************************************************

Find type information

Given a type entry, finds the type entry, then returns the block level,
sequence number of the type, and which list, normal or alternate, that it
belongs to.

******************************************************************************}

procedure fndtin(    tp: typptr; { type to find }
                 var l:  integer;  { block level of type }
                 var s:  integer;  { sequence number of type }
                 var a:  boolean); { type is from alternate/normal list }

var tps: tpsptr; { type stack pointer }

begin

   tps := typstk; { set 1st level }
   s := 0; { set no entry found }
   while tps <> nil do begin { traverse block list }

      l := tps^.lvl; { set level we are searching }
      a := false; { set normal list }                                                    
      s := fndtyp(tp, tps^.typ); { search normal list }
      if s = 0 then begin { not found in normal list }

         a := true; { set alternate list }
         s := fndtyp(tp, tps^.typa); { search alternate list }
         if s <> 0 then tps := nil { terminate search }
         else tps := tps^.next { else next entry }

      end else tps := nil { terminate search }

   end;
   if s = 0 then error(esysflt) { should have found entry }

end;

{******************************************************************************

Find number of digits

Finds the number of digits that will be printed in the integer.

******************************************************************************}

function fnddig(i: integer) { integer to tally }
               : integer;   { number of digits in integer }

var c: integer; { number of characters in integer }

begin

   c := 1; { count digits that are printed }
   { check and correct for signed }
   if i < 0 then begin c := c+1; i := abs(i) end;
   if i >= 10 then c := c+1;
   if i >= 100 then c := c+1;
   if i >= 1000 then c := c+1;
   if i >= 10000 then c := c+1;
   if i >= 100000 then c := c+1;
   if i >= 1000000 then c := c+1;
   if i >= 10000000 then c := c+1;
   if i >= 100000000 then c := c+1;
   if i >= 1000000000 then c := c+1;
   fnddig := c { return result }

end;

{******************************************************************************

Print linkage

Prints the linkage specification of a type. The type is printed in the
form:

   (level,sequence)

Right justifies the output in a given field.

******************************************************************************}

procedure prtlnk(tp: typptr; { entry to write }
                 fl: integer); { field to write to }

var s: integer; { sequence count }
    l: integer; { block level }
    a: boolean; { type from alternate list }
    c: integer; { number of characters in output }

begin

   if tp = nil then begin { nil pointer }

      write('<nil>');
      c := 5 { set length }

   end else begin { print as address }

      fndtin(tp, l, s, a); { get entry information }
      c := 1+fnddig(l)+1+fnddig(s)+1; { set length of output }
      write('(', l:1, ',', s:1, ')'); { output }
      if a then begin { from alternate list }

         write('*'); { output alternate list marker }
         c := c+1 { count }

      end

   end;
   { pad to field length with blanks }
   while c < fl do begin write(' '); c := c+1 end

end;

{******************************************************************************

Print hexadecimal

Print a hexadecimal number with field width. Prints right justified with left
hand zeros filling the field. Also allows for the fact that an unsigned 32 bit
number can be read into a 32 bit signed number.
One remaining problem is how to detect and convert the invalid value $80000000.

******************************************************************************}

procedure prthex(f: byte; w: integer);
 
var buff: array [1..10] of char; { buffer for number in ascii }
    i:    integer; { index for same }
    t:    integer; { holding }
 
begin

   { set sign of number and convert }
   if w < 0 then begin

      w := w+1+maxint; { convert number to 31 bit unsigned }
      t := w div $10000000 + 8; { extract high digit }
      writeh(output, t); { ouput that }
	   w := w mod $10000000; { remove that digit }
      f := 7 { force field to full }     

   end;
   hexsp(buff, w); { convert the integer }
   for i := 1 to f-lenp(buff) do write('0'); { pad with leading zeros }
   writesp(output, buff) { output number }

end;

{******************************************************************************

Print type

Prints the type and fields of the given type, on a single line without eoln.

******************************************************************************}

procedure lsttypety(tp: typptr);

begin

   write('addr: $'); prthex(8, tp^.addr); write(' ');
   write('size: $'); prthex(8, tp^.size); write(' (', tp^.size:1, ') ');
   write('local: ', tp^.local:0, ' ');
   write('disp: $'); prthex(8, tp^.disp); write(' ');
   case tp^.t of

      tudf:    write('tudf: undefined');     
      tnil:    write('tnil: NIL pointer'); 
      tlab:    write('tlab: GOTO label'); 
      ticst:   write('ticst: integer constant: Value: ', tp^.ival:1); 
      tscst:   write('tscst: string constant: Value: ''', 
                     tp^.sval.str:tp^.sval.len, ''''); 
      tccst:   write('tccst: character constant: Value: ''', tp^.cval, '''');
      trcst:   write('trcst: real constant: Value: ', tp^.rval);
      tstcst:  begin 

         write('tstcst: set constant');
         write(' Base: '); prtlnk(tp^.stct, 1); 
         write(' Const list: '); prtlnk(tp^.stcc, 1)

      end;
      tstet:   begin

         write('tstet: set constant element: next element: ');
         prtlnk(tp^.sten, 1);
         write(' Starting value: ', tp^.stes:1);
         write(' Ending value: ', tp^.stee:1);
         write(' Head: '); prtlnk(tp^.steh, 1)

      end; 
      tarrcst:  begin

         write('tarrcst: array constant: first list entry: ');
         prtlnk(tp^.arcn, 1)

      end;
      tarrcel:  begin

         write('tarrcel: array constant element: next: ');
         prtlnk(tp^.aren, 1);
         write(' constant link: ');
         prtlnk(tp^.arec, 1)

      end;   
      treccst:  begin

         write('treccst: record constant: first list entry: ');
         prtlnk(tp^.recn, 1)

      end;
      treccel:  begin

         write('treccel: record constant element: next: ');
         prtlnk(tp^.reen, 1);
         write(' constant link: ');
         prtlnk(tp^.reec, 1)

      end;
      tenum:    begin

         write('tenum: enumerated type: first list entry: ');
         prtlnk(tp^.enc, 1)

      end;
      tenme:    begin

         write('tenme: enumerated constant: next: ');
         prtlnk(tp^.enx, 1);
         write(' head: ');
         prtlnk(tp^.enh, 1);
         write(' constant: ', tp^.env:1)

      end;
      tsub:     begin

         write('tsub: subrange type: base type: ');
         prtlnk(tp^.subt, 1);
         write(' lower bound: ', tp^.subl:1, ' upper bound: ', tp^.subu:1)

      end;
      tptr:     begin

         write('tptr: pointer type: base type: ');
         prtlnk(tp^.ptrt, 1)

      end;
      tarray:   begin

         write('tarray: array type: base type: ');
         prtlnk(tp^.arrt, 1);
         write(' index type: ');
         prtlnk(tp^.arri, 1)

      end;
      tgarry:   begin

         write('tgarry: general array type: base type');
         prtlnk(tp^.gart, 1)

      end;
      tfile:    begin

         write('tfile: file type: base type: ');
         prtlnk(tp^.filt, 1)

      end;
      tset:     begin

         write('tset: set type: base type: ');
         prtlnk(tp^.sett, 1)

      end;
      trecord:  begin

         write('trecord: record type: field list: ');
         prtlnk(tp^.recf, 1)

      end;
      tfield:   begin

         write('tfield: record field: next: ');
         prtlnk(tp^.fldn, 1);
         write(' head: ');
         prtlnk(tp^.fldh, 1);
         write(' base: ');
         prtlnk(tp^.fldt, 1)

      end;
      tftag:    begin

         write('tftag: record tag field: case list: ');
         prtlnk(tp^.ftgc, 1);
         write(' head: ');
         prtlnk(tp^.ftgh, 1);
         write(' base: ');
         prtlnk(tp^.ftgt, 1);
         write(' exists: ', tp^.ftge)

      end;
      tfcas:    begin

         write('tfcas: record tag field case: next: ');
         prtlnk(tp^.fcsn, 1);
         write(' field list: ');
         prtlnk(tp^.fcsf, 1);
         write(' case constant: ', tp^.fcsc:1)

      end;
      tvar:     begin

         write('tvar: variable: base type: ');
         prtlnk(tp^.vart, 1);
         write(' external: ', tp^.vare:0)

      end;
      tfix:     begin

         write('tfix: fixed: base type: ');
         prtlnk(tp^.fixt, 1);
         write(' constant fill: ');
         prtlnk(tp^.fixc, 1);
         write(' external: ', tp^.fixe:0)

      end;
      tproc:    begin

         write('tproc: procedure: parameter list: ');
         prtlnk(tp^.prcp, 1);
         write(' locals allocation: ', tp^.prcv:1);
         write(' parameters allocation: ', tp^.prca:1);
         write(' external: ', tp^.prce:0)

      end;
      tfunc:    begin

         write('tfunc: function: parameter list: ');
         prtlnk(tp^.fncp, 1);
         write(' result: ');
         prtlnk(tp^.fncr, 1);
         write(' locals allocation: ', tp^.fncv:1);
         write(' parameters allocation: ', tp^.fnca:1);
         write(' external: ', tp^.fnce:0)

      end;
      tpar:     begin

         write('tpar: value parameter: next: ');
         prtlnk(tp^.parn, 1);
         write(' base type: ');
         prtlnk(tp^.part, 1);
         write(' head: ');
         prtlnk(tp^.parh, 1)

      end;
      tvpar:    begin

         write('tvpar: variable parameter: next: ');
         prtlnk(tp^.vprn, 1);
         write(' base type: ');
         prtlnk(tp^.vprt, 1);
         write(' head: ');
         prtlnk(tp^.vprh, 1)

      end;
      twpar:    begin

         write('twpar: view parameter: next: ');
         prtlnk(tp^.wprn, 1);
         write(' base type: ');
         prtlnk(tp^.wprt, 1);
         write(' head: ');
         prtlnk(tp^.wprh, 1)

      end;
      tpproc:   begin

         write('tpproc: procedure parameter: parameter list: ');
         prtlnk(tp^.pprp, 1);
         write(' next: ');
         prtlnk(tp^.pprn, 1)

      end;
      tpfunc:   begin

         write('tpfunc: function parameter: parameter list: ');
         prtlnk(tp^.pfnp, 1);
         write(' result: ');
         prtlnk(tp^.pfnr, 1);
         write(' next: ');
         prtlnk(tp^.pfnn, 1)

      end;
      tinteger: write('tinteger: integer type');
      tchar:    write('tchar: character type');
      tboolean: begin

         write('tboolean: boolean type: enumeration list: ');
         prtlnk(tp^.bnc, 1)

      end;
      treal:    write('treal: real type');
      tsreal:   write('tsreal: short real type');
      ttext:    write('ttext: text type');
      teset:    write('teset: empty set');
      tglbl:    write('tglbl: global mark');
      tnull:    ;
      tfuncr:   begin

         write('tfuncr: function result holder: type: ');
         prtlnk(tp^.fnrt, 1)

      end;
      tlink:    begin

         write('tlink: delayed link entry: (',
               tp^.lnkl:1, ',', tp^.lnke:1, ')')

      end

   end

end;

{******************************************************************************

Dump current types list

Dumps the given standard types list. For diagnostic purposes.

******************************************************************************}

procedure dmptyp(lvl: integer);

var tp:       typptr;  { pointer for types }
    tps, fps: tpsptr;  { type stack pointers }

procedure dmplst(tp: typptr);

var e: integer; { entry counter }

begin

   e := 1; { set 1st entry }
   while tp <> nil do begin { traverse }

      write('(', tps^.lvl:1, ',', e:1, ') '); { write (level, entry) }
      lsttypety(tp); { write type entry }
      writeln; { next line }
      e := e+1; { count }
      tp := tp^.next { next entry }

   end

end;

begin

   tps := typstk; { index top stack }
   while tps <> nil do begin { traverse }

      if tps^.lvl = lvl then fps := tps; { found }
      tps := tps^.next { next entry }

   end;
   tps := fps; { place found pointer }
   if tps = nil then writeln('*** Diagnostic error: level not found')
   else begin

      writeln;
      writeln('Standard type list:');
      writeln;
      dmplst(tps^.typ);
      writeln;
      writeln('Alternate type list:');
      writeln;
      dmplst(tps^.typa)

   end

end;

{******************************************************************************

Print type with numbers

Prints the type and fields of the given type, on a single line without eoln,
including the block level and sequence number.

******************************************************************************}

procedure lsttypetyi(tp: typptr);

begin

   prtlnk(tp, 1); { output header }
   write(' ');
   lsttypety(tp) { output type }

end;

{******************************************************************************

Parse command line

The structure of a command line is:

     file

The file is parsed into intnam.

******************************************************************************}

procedure parcmd;

var err: boolean; { filename error occured }

begin

   parfil(cmdhan, intnam, false, err); { parse filename }
   if err then error(einvfnm) { bad filename }


end;

{******************************************************************************

Test filename contains an extention

Simply checks if '.' exists in the filename, which would indicate an extention
is present (in a properly parsed filename).

******************************************************************************}

function isext(var f: filnam): boolean; { filename to check }

var p, n, e: filnam; { filename components }

begin

   brknamp(f, p, n, e); { break down filename }

   isext := lenp(e) > 0  { return extention status }

end;

{******************************************************************************

Append file extention

Appends a given extention, in place, to the given file name. The extention is 
usually in the form: 'ext'. The extention is placed within the file name at the
first space or period from the left hand side. This allows extention of either
an unextended filename or an extended one (in which case the new extention
simply overlays the old). The overlay is controlled via flag: if overwrite is
true, the extention will overwrite any existing, if not, any existing extention
will be left in place.
No checking is performed for a new filename that will overflow the allotted
filename length.
In the case of overflow, the filename will simply be truncated to the 8:3 
format.
Note: this routine is MS-DOS dependent.

******************************************************************************}

procedure addext(var fn: filnam; { filename to extend }
                 ex: ext;        { filename extention }
                 ovr: boolean);  { overwrite flag }

var p, n, e: filnam; { filename components }

begin

   brknamp(fn, p, n, e); { break down filename }
   { if no extention, or overwrite set, copy new extention }
   if (lenp(e) = 0) or ovr then copyp(e, ex);
   maknamp(fn, p, n, e) { reconstruct }

end;
{}
{******************************************************************************

Read 32 bit integer from intermediate file

Reads a 32 bit number from the intermediate file. The highest order
byte appears first, and the least order last.
The high byte 7th bit contains the sign.

******************************************************************************}

procedure rdnum(var i: integer); 

var b: byte;    { read byte holder }
    s: integer; { sign of result }
    t: integer; { temp }

begin

   s := 1; { set no sign }
   read(intfil, b);
   if b >= 128 then begin { signed }

      s := -1; { set sign }
      b := b - 128 { remove sign }

   end;
   t := b; { place in large buffer }
   i := t*16777216;
   read(intfil, b);
   t := b; { place in large buffer }
   i := i + t*65536;
   read(intfil, b);
   t := b; { place in large buffer }
   i := i + t*256;
   read(intfil, b);
   i := i + b;
   i := i*s { set sign of result }

end;
{}
{**************************************************************

Read real number from intermediate file

Reads a 64 bit real number to from the intermediate file.

**************************************************************}

procedure rdreal(var r: real);

var rc: record case boolean of { data convertion }

           false: (r: real);
           true:  (b: packed array [1..8] of byte)

        end;
    i:  1..8; { index for byte array }
    b:  byte;

begin

   for i := 1 to 8 do begin { read bytes of real in }

      read(intfil, b);
      rc.b[i] := b

   end;
   r := rc.r { return real }

end;

{******************************************************************************

Make type entry

Either recycles a free type entry, or gets a new one, initalizes and returns
that.

******************************************************************************}

procedure maktyp(var tp: typptr; { type pointer to return type }
                     t:  types); { entry type to get }

begin

   if fretyp[t] <> nil then begin { return existing entry }
  
      tp := fretyp[t]; { index top entry }
      fretyp[t] := tp^.next { gap the list }
      
   end else begin

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
         tglbl:    new(tp, tglbl);   
         tnull:    new(tp, tnull);
         tfuncr:   new(tp, tfuncr);
         tlink:    new(tp, tlink)

      end;
      tp^.t := t { set type of entry }

   end;
   tp^.next := nil; { clear next }
   tp^.addr := 0; { clear address }
   tp^.size := 0; { clear size }
   tp^.local := false { default to global }

end;

{******************************************************************************

Get type entry

Either recycles a free type entry, or gets a new one, and places that into the
current block list. The standard block list is maintained into incoming order,
so that the entry numbers match up.

******************************************************************************}

procedure gettyp(var tp: typptr; { type pointer to return type }
                     t:  types); { entry type to get }

begin

   maktyp(tp, t); { make a type entry }
   if typstk^.lst <> nil then typstk^.lst^.next := tp { insert at end }
   else typstk^.typ := tp; { insert at beginning }
   typstk^.lst := tp; { set new last }
   if typstk^.res = nil then typstk^.res := tp { if resolved empty, set new }

end;

{******************************************************************************

Get alternate type entry

Either recycles a free type entry, or gets a new one, and places that into the
alternate block list.
The alternates list is kept because we want to create occasional types
for internal purposes, and those cannot be created in the normal list, because
those types are carefully metered from the intermediate so that they can be
found. Virtually all operations are performed to both lists, so any type
of entry, including variables and locals, can be created internally.
The alternate list does not maintain entry order, since there will be no
unresolved references to entrys in it.

******************************************************************************}

procedure gettypa(var tp: typptr; { type pointer to return type }
                     t:  types); { entry type to get }

begin

   maktyp(tp, t); { make a type entry }
   if typstk^.lsta <> nil then typstk^.lsta^.next := tp { insert at end }
   else typstk^.typa := tp; { insert at beginning }
   typstk^.lsta := tp; { set new last }
   if typstk^.resa = nil then typstk^.resa := tp { if resolved empty, set new }

end;

{******************************************************************************

Put type entry

Returns a given type entry to the free lists. Because entrys are allocated
for the exact size required for the type, there is a free list for each type,
and each entry is placed back into the indivdual list by type.

******************************************************************************}

procedure puttyp(var tp: typptr); { type pointer to return type }

begin

   tp^.next := fretyp[tp^.t]; { link to appropriate free list }
   fretyp[tp^.t] := tp

end;

{******************************************************************************

Find existing link

Given the level and entry numbers, finds an entry by that link. If none is
found, a nil is returned.

******************************************************************************}

procedure fndlnk(var tp: typptr;   { link to resolve }
                     l:  integer;  { level number }
                     e:  integer); { entry number }

var mc:  integer; { match number }
    tsp: tpsptr;  { types stack pointer }

begin

   tsp := typstk; { index top of stack }
   mc := blkcnt; { set match count }
   while l <> mc do begin { back up to proper level }
   
      if tsp = nil then error(einvfmt); { no corresponding block }
      tsp := tsp^.next; { go deeper in types stack }
      mc := mc-1 { count off }
   
   end;
   if tsp = nil then error(einvfmt); { no corresponding block }
   tp := tsp^.typ; { index 1st type entry at level }
   while (e <> 1) and (tp <> nil) do begin { traverse to entry }
   
      tp := tp^.next; { next entry }
      e := e-1 { count }
   
   end

end;

{******************************************************************************

Get and process link

Gets the complete intermediate address of the given type entry. The logical
address of a type entry consists of it's logical type level number, and it's
logical type entry number. This is converted to a real pointer by reaching
down to the indicated level and finding the specified entry.

******************************************************************************}

procedure getlnk(var tp: typptr);

var l: integer; { level number }
    e: integer; { entry number }

begin

   rdnum(l); { get level number }
   rdnum(e); { get entry number }
   if (l = 0) and (e = 0) then tp := nil { nil linkage }
   else begin

      fndlnk(tp, l, e); { find any type }
      if tp = nil then begin

         { well, we didn't find it, because it has not arrived yet (forward
           reference). so create a linkage entry for it instead }
         gettypa(tp, tlink); { get linkage entry }
         tp^.lnkl := l; { place level }
         tp^.lnke := e { place entry }

      end;

   end

end;

{******************************************************************************

Get string

A string is a length, followed by the string characters. Loads the string from
the intermediate file to the given string entry.

******************************************************************************}

procedure getstr(var s: stringt);

var l: byte;   { string length }
    b: byte;   { character holder }
    i: strinx; { string index }

begin

   read(intfil, l); { get the string length }
   s.len := l; { place }
   i := 1; { set 1st character }
   while l <> 0 do begin { print string characters }

      read(intfil, b); { get a string character }
      s.str[i] := chr(b); { place }
      l := l-1; { count }
      i := i+1 { next character }

   end

end;

{******************************************************************************

Place source entry

Given a source string, finds the matching source entry for it, or creates a
new one.

The found or created source entry is set as the active source entry for line
entry.

If the filename given is blank, it means to set the current source to null.
We do this by clearing the current source pointer.

******************************************************************************}

procedure plcsrc(view fn: filnam);

var sp, fp: srcptr; { found pointer }

begin

   if lenp(fn) = 0 then cursrc := nil { clear current source }
   else begin { lookup }

      sp := srclst; { index the top of the source list }
      fp := nil; { clear found pointer }
      while sp <> nil do begin

         if sp^.nam = fn then fp := sp; { found, set }
         sp := sp^.next

      end;
      cursrc := fp; { set that active if found }
      if fp = nil then begin { no previous entry, create one }

         new(sp); { create new entry }
         sp^.next := srclst; { push onto source list }
         srclst := sp;
         sp^.nam := fn; { place name }
         sp^.lin := nil; { clear line list }
         cursrc := sp { set that active }
        
      end

   end

end;

{******************************************************************************

Place line entry

Places a line entry in the currently active source list. Accepts a line number,
and creates a line entry, which is then pushed onto the currently active source
list. An invalid intermediate error occurs if there is no active source list,
because that would indicate improper intermediate sequencing.

We also check if the line is a duplicate in the given source, which should not
happen, and is an intermediate format error.

We don't sort the line entries here, because the entire line list must be
sorted as a whole.

******************************************************************************}

procedure plclin(l: integer);

var lp: linptr; { pointer to line entry }

begin

   if cursrc = nil then error(einvfmt); { bad format }
   { search previous line entry }
   lp := cursrc^.lin; { index top of line list }
   while lp <> nil do begin { traverse }

      if lp^. lin = l then error(einvfmt); { duplicate, bad format }
      lp := lp^.next { next }

   end;
   { enter new line }
   new(lp); { get a new line entry }
   lp^.next := cursrc^.lin; { push onto current source line list }
   cursrc^.lin := lp;
   lp^.lin := l; { set line number }
   lp^.equ := pgmcnt; { set address }
   lp^.src := cursrc; { link entry to its parent }
   lp^.mast := nil { clear master list link }
   
end;

{******************************************************************************

Sort line list

Sorts the line list into master line order. The line list is sorted as a whole,
not considering the source they come from, on the master line list link,
according to program count order. This master list is then used to lookup
program locations.

******************************************************************************}

procedure srtlin;

var sp:   linptr; { source line list }
    dp:   linptr; { destination line list }
    p, l: linptr; { list pointers }
    srcp: srcptr; { source list pointer }
    

begin

   dp := nil; { clear destination list }
   srcp := srclst; { index source list }
   while srcp <> nil do begin { traverse source entries }

      sp := srcp^.lin; { index line list }
      while sp <> nil do begin { traverse line entries }

         if dp = nil then { destination list is empty }
            begin dp := sp; sp^.mast := nil end { insert at list top }
         else if sp^.equ < dp^.equ then { new < dest }
            begin sp^.mast := dp; dp := sp end { insert at top }
         else begin { in list middle somewhere }

            p := dp; { index top of list }
            while p <> nil do begin

               l := p; { set pointer to last }
               p := p^.mast; { index next }
               if p <> nil then { there is a next entry } 
                  if sp^.equ < p^.equ then
                     p := nil; { entry found, stop }

            end;
            sp^.mast := l^.mast; { link new to next }
            l^.mast := sp { link new to last }

         end;
         sp := sp^.next { next line }
          
      end;
      srcp := srcp^.next { next source file }

   end;
   linlst := dp { place sorted master list }

end;

{******************************************************************************

Make rld entry

Creates and rld entry with the given address, type linkage and insertion type.

******************************************************************************}

procedure makrld(adr: meminx; { address to place }
                 tp:  typptr; { type entry to use }
                 it:  ityp);  { insertion type }

var rp: rldptr; { relocation entry pointer }

begin

   new(rp); { get a new relocation entry }
   rp^.addr := adr; { set address to patch }
   rp^.lab := tp; { set patch entry }
   rp^.it := it; { place insertion type }
   rp^.next := rldlst; { push onto rld list }
   rldlst := rp

end;

{******************************************************************************

Place program integer

Places an integer at the given address. The integer is broken up into bytes,
with big endian format.

******************************************************************************}

procedure plcint(a: meminx;   { address to place integer }
                 i: integer); { integer to place }

var c: record case boolean of { convertion }

          false: (i: integer); { integer form }
          true:  (b: packed array[1..intsiz] of byte); { byte format }

       end;
    bi: 1..intsiz; { index for convertion array }  

begin

   c.i := i; { place integer }
   { place byte equivalent in memory }
   for bi := 1 to intsiz do memory[a+bi-1] := c.b[bi]

end;

{******************************************************************************

Place program real

Places a real at the given address. The real is broken up into bytes.

******************************************************************************}

procedure plcrl(a: meminx; { address to place integer }
                r: real);  { real to place }

var c: record case boolean of { convertion }

          false: (r: real); { real form }
          true:  (b: packed array[1..relsiz] of byte); { byte format }

       end;
    bi: 1..relsiz; { index for convertion array }  

begin

   c.r := r; { place real }
   { place byte equivalent in memory }
   for bi := 1 to relsiz do memory[a+bi-1] := c.b[bi]

end;

{******************************************************************************

Place program short real

Places a short real at the given address. The real is broken up into bytes.

******************************************************************************}

procedure plcsrl(a: meminx; { address to place integer }
                 r: real); { real to place }

var c: record case boolean of { convertion }

          false: (r: sreal); { 32 bit real form }
          true:  (b: packed array[1..srlsiz] of byte); { byte format }

       end;
    bi: 1..srlsiz; { index for convertion array }  

begin

   c.r := r; { place short real }
   { place byte equivalent in memory }
   for bi := 1 to srlsiz do memory[a+bi-1] := c.b[bi]

end;

{******************************************************************************

Get program integer

Gets an integer at the given address. The integer is assembled from bytes,
with big endian format.

******************************************************************************}

function getint(a: meminx) { address }
                : integer; { integer }

var c: record case boolean of { convertion }

          false: (i: integer); { integer form }
          true:  (b: packed array[1..intsiz] of byte); { byte format }

       end;
    bi: 1..intsiz; { index for convertion array }  

begin

   { get bytes }
   for bi := 1 to intsiz do c.b[bi] := memory[a+bi-1];
   getint := c.i { return result }

end;

{******************************************************************************

Get program real

Gets a real from the given address, from byte format.

******************************************************************************}

function getrl(a: meminx) { address to place integer }
               : real;    { real to place }

var c: record case boolean of { convertion }

          false: (r: real); { real form }
          true:  (b: packed array[1..relsiz] of byte); { byte format }

       end;
    bi: 1..relsiz; { index for convertion array }  

begin

   { get bytes }
   for bi := 1 to relsiz do c.b[bi] := memory[a+bi-1];
   getrl := c.r { return result }

end;

{******************************************************************************

Get program short real

Gets a short real from the given address, from byte format.

******************************************************************************}

function getsrl(a: meminx) { address to place integer }
                : real;    { real to place }

var c: record case boolean of { convertion }

          false: (r: sreal); { real form }
          true:  (b: packed array[1..srlsiz] of byte); { byte format }

       end;
    bi: 1..srlsiz; { index for convertion array }  

begin

   { get bytes }
   for bi := 1 to srlsiz do c.b[bi] := memory[a+bi-1];
   getsrl := c.r { return result }

end;

{******************************************************************************

Emit byte

Places a single byte into the memory array at the current program load
address, and advances the address to the next byte. Errors on the program load
being at the end of memory.

******************************************************************************}

procedure emitbyt(b: byte);

begin

   if pgmcnt = maxmem then error(ememovf); { memory is full }
   memory[pgmcnt] := b; { place byte }
   pgmcnt := pgmcnt+1 { next location }

end;

{******************************************************************************

Emit code byte

Places a single code byte into the memory array at the current program load
address, and advances the address to the next byte. Errors on the program load
being at the end of memory.

******************************************************************************}

procedure emit(ic: opcod);

begin

   emitbyt(ord(ic)) { place code byte }

end;

{******************************************************************************

Emit code integer

Places a 32 bit integer into the code memory at the current program load
address, and advances the address to after it. Errors on the program load
being at the end of memory.

******************************************************************************}

procedure emitint(i: integer);

begin

   if pgmcnt >= maxmem-4 then error(ememovf); { memory is full }
   plcint(pgmcnt, i); { place integer in memory }
   pgmcnt := pgmcnt+4 { advance program load count }

end;

{******************************************************************************

Emit code real

Places a 64 bit real into the code memory at the current program load
address, and advances the address to after it. Errors on the program load
being at the end of memory.

******************************************************************************}

procedure emitrl(r: real);

begin

   if pgmcnt >= maxmem-8 then error(ememovf); { memory is full }
   plcrl(pgmcnt, r); { place integer in memory }
   pgmcnt := pgmcnt+8 { advance program load count }

end;

{******************************************************************************

Emit code short real

Places a 32 bit real into the code memory at the current program load
address, and advances the address to after it. Errors on the program load
being at the end of memory.

******************************************************************************}

procedure emitsrl(r: real);

begin

   if pgmcnt >= maxmem-4 then error(ememovf); { memory is full }
   plcsrl(pgmcnt, r); { place integer in memory }
   pgmcnt := pgmcnt+4 { advance program load count }

end;

{******************************************************************************

Emit code string

Places a string constant into the code memory at the current program load
address, and advances the address to after it. Errors on the program load
being at the end of memory.

******************************************************************************}

procedure emitstr(var s: stringt);

var i: strinx; { index for string }

begin

   for i := 1 to s.len do emitbyt(ord(s.str[i])) { place characters }

end;

{******************************************************************************

Emit code address

Accepts a type entry. Emits an address for the entry, and adds a relocation
patch for that location.

******************************************************************************}

procedure emitadr(tp: typptr; { type entry to use }
                  it: ityp);  { insertion type }

begin

   makrld(pgmcnt, tp, it); { make and rld for that }
   case it of { insertion type }

      itadr: emitint(tp^.addr); { output address }
      itdsp: emitint(tp^.disp) { output display address }

   end

end;

{******************************************************************************

Push new structure stack level

Allocates a structure entry from recycled or new storage, and pushes that
onto the structure stack.

******************************************************************************}

procedure pushsrt;

var sp: srtptr; { pointer for structure entry }

begin

   if srtfre <> nil then begin { get a free entry }

      sp := srtfre; { index the top entry }
      srtfre := srtfre^.next { remove from list }

   end else new(sp); { get a new entry }
   sp^.next := srtstk; { push onto stack }
   srtstk := sp;
   sp^.withm := false { set not a 'with' entry }

end;

{******************************************************************************

Pop structure stack level

Removes the top level of the structure stack and recycles the entry.

******************************************************************************}

procedure popsrt;

var sp: srtptr; { pointer for structure entry }

begin

   if srtstk = nil then error(einvfmt); { stack is empty }
   sp := srtstk; { index top entry }
   srtstk := srtstk^.next; { remove from list }
   sp^.next := srtfre; { place on free list }
   srtfre := sp

end;

{******************************************************************************

Load ordinal constant

Loads the constat from the given type entry. Will load as an integer any of
an integer, single character string, or enumerated type.

*******************************************************************************}

function consti(tp: typptr): integer;

var i: integer; { result holder }

begin

   if tp^.t = ticst then i := tp^.ival { integer constant }
   else if tp^.t = tscst then i := ord(tp^.sval.str[1]) { string constant }
   else if tp^.t = tccst then i := ord(tp^.cval) { character constant }
   else if tp^.t = tenme then i := tp^.env { enumerated }
   else error(einvfmt); { invalid format }
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
      tstcst:   ; { must itself be a type }
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
      tpfunc:   ; { already at base type }
      tinteger: ; { already at base type } 
      tchar:    ; { already at base type }
      tboolean: ; { already at base type }
      treal:    ; { already at base type }
      tsreal:   ; { already at base type }
      ttext:    ; { already at base type }
      teset:    ; { already at base type }
      tglbl:    ; { no base type }
      tnull:    ; { no base type }
      tfuncr:   tp := tp^.fnrt; { link type }
      tlink:      { no base type }

   end;
   baset := tp { return type }

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

Check short real type

Checks if the given type is a short real.

*******************************************************************************}

function srealt(tp: typptr): boolean;

begin

   tp := baset(tp); { find base type }
   { result true if it's a short real }
   srealt := tp^.t = tsreal

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
   if tp^.t <> tchar then { check for single character string constant }
      if tp^.t <> tccst then { not a character constant }
         if tp^.t <> tscst then m := false { not a string constant }
         else m := tp^.sval.len = 1; { must be single character }
   chart := m

end;

{******************************************************************************

Check tagged pointer type

Checks if the given type is a tagged pointer. This is either a pointer to a
general array, or a var or view parameter that is a general array.

*******************************************************************************}

function tgpt(tp: typptr): boolean;

var m: boolean; { match result }

begin

   m := false; { set no match }
   if tp^.t = tptr then begin

      m := tp^.ptrt^.t = tgarry { check is a general array base }

   end else if tp^.t = tvpar then begin

      m := tp^.vprt^.t = tgarry { check is a general array base }

   end else if tp^.t = twpar then begin

      { check is a general array base }
      m := (tp^.wprt^.t = tgarry) or tgpt(tp^.wprt)

   end else if tp^.t = tpar then begin

      m := tgpt(tp^.part) { check is a tagged pointer itself }

   end else m := tp^.t = tnil; { allow nils to be tagged as well } 

   tgpt := m { return result }

end;   

{******************************************************************************

Find lower bound of type

Finds the lower bound of an ordinal type.

*******************************************************************************}

function lbound(tp: typptr): integer;

var lb: integer; { result holder }

begin

   if tp^.t = tenum then lb := tp^.enc^.env { return enumerated }
   else if tp^.t = tenme then lb := tp^.enh^.enc^.env { return enumerated }
   else if tp^.t = tsub then lb := tp^.subl { return subrange }
   else if intt(tp) then lb := -maxint { return integer }
   else if chart(tp) then lb := 0 { return character }
   else if tp^.t = tboolean then lb := 0 { return boolean }
   else if tp^.t = tudf then lb := -maxint { undefined, return minimum }
   else error(einvfmt); { else is invalid type }   
   lbound := lb

end;

{******************************************************************************

Find upper bound of type

Finds the upper bound of an ordinal type.

*******************************************************************************}

function ubound(tp: typptr): integer;

var ub: integer; { result holder }

begin

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
   else error(einvfmt); { else is invalid type }   
   ubound := ub

end;

{******************************************************************************

Set size of type entry

Determines the size that an object of the given type will occupy, in bytes,
and sets that variable in the type. If the type already has a size it is
skipped. If it does not, we also recursively verify that all relied on
submembers also have a size. That way, the size tree for the entry is
self-resolved for any undefineds.

******************************************************************************}

procedure sizset(tp: typptr);

{ find the maximum variant record case list size }

function maxcas(tp: typptr): integer;

var max: integer; { maximum length holder }

begin

   max := 0; { set no maximum }
   while tp <> nil do begin { traverse }

      sizset(tp); { set size of element }
      { if this is the largest size, then set new maximum }
      if tp^.size > max then max := tp^.size;
      tp := tp^.fcsn { link next case entry }

   end;
   maxcas := max { return largest case }

end;

{ find the total size of all fields in a field list }

function fields(tp: typptr): integer;

var size: integer; { total size of list }

begin

   size := 0; { clear size }
   while tp <> nil do begin { traverse list }

      sizset(tp); { set size of element }
      size := size+tp^.size; { add in size of field }
      if tp^.t = tfield then tp := tp^.fldn { link next }
      else begin

         { tag field. Now we must "survey" all of the cases, to find
           the largest. That will be the proper size of the variant }
         size := size+maxcas(tp^.ftgc); { find maximum case length }
         tp := nil { flag end of list }

      end

   end;
   fields := size { return size of list }

end;

begin

   if tp^.size = 0 then { if the entry has no size, size it }
      with tp^ do case t of { type }

      tudf:      ; { none }   
      tnil:      size := intsiz; { 32 bit pointer }   
      tlab:      ; { none }
      ticst:     size := intsiz; { 32 bit constant }  
      tscst:     size := sval.len; { same as length }
      tccst:     size := 1; { character }
      trcst:     size := relsiz; { 64 bit real }  
      tstcst:    size := setsiz; { 256 bits of 32 bytes in a set }
      tstet:     ; { no meaning to this }
      { structured constants are not sized, because we use the base type of any
        fixed object to process them }
      tarrcst:   ;
      tarrcel:   ;
      treccst:   ;
      treccel:   ;
      tenum:     size := intsiz; { 32 bit value }
      tenme:     size := intsiz; { 32 bit constant }
      tsub:      begin sizset(subt); size := subt^.size end;
      tptr:      if ptrt^.t = tgarry then size := tgpsiz { general array }
                 else size := intsiz; { 32 bit pointer }   
      { arrays are the number of bytes per element, times the number of
        elements }
      tarray:    begin sizset(arrt); 
                       size := arrt^.size*
                               (ubound(arri)-lbound(arri)+1) end;
      tgarry:    ; { general arrays have no fixed size }
      tfile:     size := 1; { one byte for the file number } 
      tset:      size := setsiz; { 256 bits or 32 bytes in a set }   
      trecord:   begin

         { find total length of fields in record }
         tp := recf; { index top of list }
         size := fields(tp) { find size of list }
            
      end;
      tfield:    begin sizset(fldt); size := fldt^.size end;
      tftag:     begin sizset(ftgt); size := ftgt^.size end;
      tfcas:     begin

         { find total list of fields in case variant }
         tp := fcsf; { index top of list }
         size := fields(tp) { find size of list }
            
      end;
      tvar:      begin sizset(vart); size := vart^.size end;
      tfix:      begin sizset(fixt); size := fixt^.size end;
      tproc:     ; { none }
      tfunc:     ; { none }
      tpar:      begin sizset(part); size := part^.size end;
      tvpar:     if vprt^.t = tgarry then size := 8 { pointer, length }
                 else size := 4; { 32 bit pointer to variable }
      twpar:     begin

         sizset(wprt); { set size of base }
         if wprt^.t in [trecord, tarray] then { structured }
            size := 4 { 32 bit pointer to variable }
         else if wprt^.t = tgarry then size := 8 { pointer, length }
         else size := wprt^.size { else is size of base }

      end;
      tpproc:    size := 4; { 32 bit address of procedure }
      tpfunc:    size := 4; { 32 bit address of function }
      tinteger:  size := 4; { 32 bit integer }
      tchar:     size := 1; { character }
      tboolean:  size := 1; { boolean }
      treal:     size := 8; { 64 bit real }
      tsreal:    size := 4; { 32 bit real }
      ttext:     size := 1; { one for the file number }
      teset:     size := 32; { 256 bits or 32 bytes in a set }
      tglbl:     ; { none }
      tnull:     ; { none }
      tfuncr:    begin sizset(fnrt); size := fnrt^.size end

   end

end;

{******************************************************************************

Set size block

Sets the size of all the type entries in the current block. This should be done
when starting a new block (which might reference types in this block), or the
start of a program code section. Each type entry is set in turn, but if any
entry has undefined subentries, those are resolved first. In this way, the
typing tree is self-resolving.

******************************************************************************}

procedure sizblk;

{ resolve types list }

procedure sizlst(tp: typptr);

begin

   while tp <> nil do begin { traverse }

      sizset(tp); { set size of entry, possibly subentries }
      tp := tp^.next { next entry }

   end

end;

begin

   sizlst(typstk^.res); { resolve standard list }
   sizlst(typstk^.resa) { resolve alternate list }

end;
  

{******************************************************************************

Allocate locals

Assigns addresses to all the locals in the current mark (procedure or 
function). This must be done as soon as the declaration section of a block
has completed. Since there is no specific marker for this (it could be
terminated by either a nested block or the program code block), we keep track
of if the locals have been resolved, and only do that once.
The variables should be sized before this routine is called.
To perform the allocation, we search sequentially through all the types in the
current block, and any variable is allocated up from the bottom of the locals
block on the stack to the bottom of the last procedure/functions stack.
All local addresses are relative, so address 0 is the bottom of the locals, as
referenced via the display.
After this, we skip the return address, then allocate all the parameters,
working from the last (rightmost) to the first (leftmost). Finally, the
function return is allocated at the very top.
Two side parameters are created from this procedure, the total locals size and
the total parameters size. The first is used to allocate and deallocate the
locals. The second is used to strip off the parameters from the stack.
Parameters are special in that they are sized atomically. That is, no simple
operand can be smaller than the size of an atom (an integer), because they are 
loaded by expression operators. This dosen't apply to structures, since they
are loaded specially, and can in fact be smaller than an atom.
There are only to ordinals that fall under the expansion rule, characters and
booleans. Files, even though one byte long, don't apply since they are allways
passed VAR.
Note that parameters of character and boolean type must be accessed specially,
because although loaded as atoms, they are referenced as ordinary memory
operands. This nonsense is required to allow chars and booleans to be packed
in memory.

******************************************************************************}

procedure allloc;

var tp: typptr;  { index for types }
    la: integer; { local address/size }

{ find atomic size of parameter }

function psize(tp: typptr): integer;

var s:   integer;
    tp1: typptr;

begin

   tp1 := baset(tp); { find base type }
   { check is a ordinal subatomic }
   if (tp1^.t = tchar) or (tp1^.t = tboolean) then s := intsiz
   else s := tp^.size; { else just set to actual size }
   psize := s

end;

{ find size of parameters list }

function sizep(tp: typptr): integer;

var ps: integer; { parameters size }

begin

   ps := 0; { clear result }
   while tp <> nil do begin { traverse }

      ps := ps+psize(tp); { add in parameter size }
      case tp^.t of { parameter, find next }

         tpar:   tp := tp^.parn; { parameter }
         tvpar:  tp := tp^.vprn; { variable parameter }
         twpar:  tp := tp^.wprn; { view parameter }
         tpproc: tp := tp^.pprn; { procedure parameter }
         tpfunc: tp := tp^.pfnn  { function parameter }

      end

   end;
   sizep := ps { return result }

end;

{ allocate parameters }

procedure allocate(tp: typptr;   { parameter list }
                   la: integer); { top of locals space }

begin

   while tp <> nil do begin { traverse }

      la := la-psize(tp); { find base of variable }
      { if the parameter is character or boolean, access at the end of the big
        endian word }
      if (tp^.t = tchar) or (tp^.t = tboolean) then tp^.addr := la+3
      else tp^.addr := la; { place normal address }
      case tp^.t of { parameter, find next }

         tpar:   tp := tp^.parn; { parameter }
         tvpar:  tp := tp^.vprn; { variable parameter }
         twpar:  tp := tp^.wprn; { view parameter }
         tpproc: tp := tp^.pprn; { procedure parameter }
         tpfunc: tp := tp^.pfnn  { function parameter }

      end

   end

end;
   
begin

   la := 0; { set local address 0, size 0 }
   { process standard list }
   tp := typstk^.typ; { index top of types list }
   while tp <> nil do begin { traverse list }

      if tp^.t = tvar then begin { it's a variable, allocate }

         tp^.addr := la; { assign the address }
         la := la+tp^.size { step to next }

      end;
      tp := tp^.next { next entry }

   end;
   { process alternate list }
   tp := typstk^.typa; { index top of types list }
   while tp <> nil do begin { traverse list }

      if tp^.t = tvar then begin { it's a variable, allocate }

         tp^.addr := la; { assign the address }
         la := la+tp^.size { step to next }

      end;
      tp := tp^.next { next entry }

   end;
   tp := typstk^.mark; { index the mark }
   if tp^.t = tproc then begin { procedure }

      tp^.prcv := la; { set total locals size }
      tp^.prca := sizep(tp^.prcp); { find total parameters size }
      { allocate parameters down from top of all frame space, locals, return
        address, and parameters }
      allocate(tp^.prcp, la+4+tp^.prca)
      
   end else if tp^.t = tfunc then begin { function }

      tp^.fncv := la; { set total locals size }
      tp^.fnca := sizep(tp^.fncp); { find total parameters size }
      { allocate parameters down from top of all frame space, locals, return
        address, and parameters }
      allocate(tp^.fncp, la+4+tp^.fnca);
      { finally, allocate function return at the top of that same frame }
      tp^.fncr^.addr := la+4+tp^.fnca { other }
      
   end

end;

{******************************************************************************

Resolve type entry

Checks the given type entry for a linkage type. If that is so, the real type
entry corresponding is found, and the type entry pointer is replaced with a
pointer to the real type. If no corresponding type entry is found, this will
cause a format error, as all such entries should be defined when this routine
is called.

******************************************************************************}

procedure resolve(var tp: typptr);

begin

   if tp <> nil then begin { not a null entry }

      if tp^.t = tlink then begin { it's a linkage entry, process }

         fndlnk(tp, tp^.lnkl, tp^.lnke); { find the entry }
         if tp = nil then error(einvfmt) { not found, invalid format }

      end

   end

end;

{******************************************************************************

Resolve forward references in block

Searches through all the type entries in the current block, and finds any
unresolved references, as marked by linkage entries. The corresponding real
entries are found, and the real pointer to them replaces the link entry 
pointer. If there still is no corresponding real entry, this is a format error
(should not happen).
This routine MUST be called before two crucial events occur. The first is
the start of a nested block, because that block could reference entries in the
current block and expect them to be resolved. The second is the start of a
code block, because those entries must be resolved. Because either of these
two events may happen first, and it would create unessary work to do it twice,
a flag indicating if the work has been performed should be kept.
After all entries are resolved, all of the link entries are returned to free
storage, as they are no longer needed.

******************************************************************************}

procedure resblk;

var tp: typptr; { type entry pointer }
    lp: typptr; { last entry pointer }
    np: typptr; { next entry pointer }

{ resolve types list }

procedure dores(tp: typptr); { list to resolve }
   
begin

   while tp <> nil do begin { traverse list }

      { perform resolution on all entries of type }
      case tp^.t of { types }

         tudf:     ;              
         tnil:     ;              
         tlab:     ;              
         ticst:    ; 
         tscst:    ; 
         tccst:    ; 
         trcst:    ;    
         tstcst:   begin resolve(tp^.stct); resolve(tp^.stcc) end;
         tstet:    begin resolve(tp^.sten); resolve(tp^.steh) end;
         tarrcst:  resolve(tp^.arcn);
         tarrcel:  begin resolve(tp^.aren); resolve(tp^.arec) end;
         treccst:  resolve(tp^.recn);
         treccel:  begin resolve(tp^.reen); resolve(tp^.reec) end;
         tenum:    resolve(tp^.enc);
         tenme:    begin resolve(tp^.enx); resolve(tp^.enh) end;
         tsub:     resolve(tp^.subt);
         tptr:     resolve(tp^.ptrt);
         tarray:   begin resolve(tp^.arrt); resolve(tp^.arri) end;
         tgarry:   resolve(tp^.gart);
         tfile:    resolve(tp^.filt);
         tset:     resolve(tp^.sett);
         trecord:  resolve(tp^.recf);
         tfield:   begin resolve(tp^.fldn); resolve(tp^.fldh); 
                         resolve(tp^.fldt) end;
         tftag:    begin resolve(tp^.ftgc); resolve(tp^.ftgh); 
                         resolve(tp^.ftgt) end;
         tfcas:    begin resolve(tp^.fcsn); resolve(tp^.fcsf) end;
         tvar:     resolve(tp^.vart);
         tfix:     begin resolve(tp^.fixt); resolve(tp^.fixc) end;
         tproc:    resolve(tp^.prcp);
         tfunc:    begin resolve(tp^.fncp); resolve(tp^.fncr) end;
         tpar:     begin resolve(tp^.parn); resolve(tp^.part); 
                         resolve(tp^.parh) end;
         tvpar:    begin resolve(tp^.vprn); resolve(tp^.vprt); 
                         resolve(tp^.vprh) end;
         twpar:    begin resolve(tp^.wprn); resolve(tp^.wprt); 
                         resolve(tp^.wprh) end;
         tpproc:   begin resolve(tp^.pprp); resolve(tp^.pprn) end;
         tpfunc:   begin resolve(tp^.pfnp); resolve(tp^.pfnr); 
                         resolve(tp^.pfnn) end;
         tinteger: ;              
         tchar:    ;              
         tboolean: resolve(tp^.bnc);
         treal:    ;              
         tsreal:   ;              
         ttext:    ;              
         teset:    ;              
         tglbl:    ;              
         tnull:    ;              
         tfuncr:   resolve(tp^.fnrt);
         tlink:

      end;
      tp := tp^.next { next entry }

   end

end;

begin

   dores(typstk^.res); { resolve standard list }
   dores(typstk^.resa); { resolve alternates list }
   resolve(typstk^.mark); { resolve the mark linkage }
   { return link entries to free }
   tp := typstk^.typa; { there aren't going to be any in the main list }
   lp := nil; { set no last entry }
   while tp <> nil do begin { traverse }

      if tp^.t = tlink then begin { delete entry }

         if lp = nil then typstk^.typa := tp^.next { gap start of list }
         else lp^.next := tp^.next; { gap list }
         np := tp^.next; { save next entry }
         { if either of the matenience pointers index this entry, move them,
           too }
         if typstk^.lsta = tp then typstk^.lsta := tp^.next; { move last }
         if typstk^.resa = tp then typstk^.resa := tp^.next; { move resolve }
         puttyp(tp); { release current entry }
         tp := np { and resume with next entry }

      end else begin

         lp := tp; { set last entry }
         tp := tp^.next { next entry }

      end

   end

end;

{******************************************************************************

Load intermediate file

Loads a complete intermediate file, including types and object code. The
incoming intermediate is converted to internal object code and loaded into the
memory array at the program count address, with the program count address being
incremented. Addresses to objects in the program have rlds generated for them.
The stack is tracked while the object is being generated, and objects on the
stack can be direct referenced.

******************************************************************************}

procedure loadint;
   
var ic, ic1:   intcod;  { intermediate code holders }
    b, b1, b2: byte;    { file byte holders }
    v:         integer; { integer parameter }
    r:         real;    { real parameter }
    tp, tp1:   typptr;  { type pointers }
    tsp:       tpsptr;  { types stack }
    intcnt:    integer; { intermediate tolken count }
    str:       stringt; { string holder }
    sp, sp1:   srtptr;  { structure tracking entry }
    rsiz:      integer; { record size }
    stack:     integer; { stack (as offset from local base) }
    srcp:      srcptr;  { source tracking entry pointer }
    linp:      linptr;  { line tracking entry pointer }
    fn:        filnam;  { filename }
    fi:        filinx;  { filename index }

{ get next intermediate code }

procedure getcod(var ic: intcod);

var bl, bh: byte;

begin

   read(intfil, bh); { get next code }
   read(intfil, bl);
   if bh*256+bl > ord(isetsrc) then error(einvitc); { invalid code number }
   intcnt := intcnt+1; { count tolken }
   ic := intcod(bh*256+bl) { convert to intermediate code }

end;

begin

   blkcnt := 0; { clear block counter }
   intcnt := 0; { clear tolken counter }
   stack := 0; { clear stack counter }
   assign(intfil, intnam); { open intermediate file }
   reset(intfil);
   { check 'SPI' signature exists on file }
   read(intfil, b);
   read(intfil, b1);
   read(intfil, b2);
   if (b <> ord('S')) or (b1 <> ord('P')) or (b2 <> ord('I')) then
      error(einvfmt); { invalid file signature }
   repeat { read file tolkens }

      getcod(ic); { get next code }
{ uncomment this to get the load codes as they come in }
{ ;write(intcnt:6, ': '); prtic(ic); writeln; }
      case ic of { intermediate code }

         { *** TYPES AND CONTROLS SECTION *** }

         ibgnlvl: begin 

            if typstk <> nil then begin { there are levels present }

               resblk; { resolve forward references }
               sizblk; { size entries in block }
               typstk^.res := nil; { clear resolvables }
               typstk^.resa := nil;
               if not typstk^.loc and (typstk^.lvl >= 3 )then begin
   
                  { locals not allocated }
                  allloc; { allocate any previous block locals }
                  typstk^.loc := true { set locals resolved }

               end

            end;
            blkcnt := blkcnt+1; { increment block counter }
            new(tsp); { get a new type level }
            tsp^.next := typstk; { push onto stack }
            typstk := tsp;
            tsp^.typ := nil; { clear root }
            tsp^.lst := nil; { clear last }
            tsp^.res := nil; { clear next resolable alternate }
            tsp^.typa := nil; { clear alternate types list }
            tsp^.lsta := nil; { clear last alternate }
            tsp^.resa := nil; { clear next resolvable alternate }
            tsp^.lvl := blkcnt; { set level number }
            tsp^.loc := false; { locals not allocated }
            getlnk(tp); { get the block mark linkage }
            tsp^.mark := tp { set corresponding mark }

         end;
         iendlvl: begin

            blkcnt := blkcnt-1; { decrement block counter }
            tsp := typstk; { save top entry }
            typstk := typstk^.next; { pop top of stack }
            { place onto types list, which will contain all of the type entries
              when the program is completely read }
            tsp^.next := typlst; { insert to list }
            typlst := tsp

         end;
         iusefil: ; { this is unimplemented anywhere }
         isetlin: begin

            rdnum(v); { get line number }
            plclin(v) { place in current source list }
            
         end;
         isetsrc: begin

            clears(fn); { clear filename }
            read(intfil, b); { get length of string }
            for fi := 1 to b do begin

               read(intfil, b1); { get string data }
               fn[fi] := chr(b1); { place }

            end;
            plcsrc(fn) { place in source list }

         end;
         inil:    gettyp(tp, tnil); { nil type }
         ilab:    gettyp(tp, tlab); { get the type entry }
         iicst:   begin

            if gblint = nil then error(einvfmt); { must have an integer base }
            gettyp(tp, ticst); { get the type entry }
            rdnum(tp^.ival); { get value }
            { the compiler has a bad habit of interspersing these into the
              code, so we have to set the size now. Fortunately, they are
              shallow entries (no sublevels) }
            sizset(tp) { set size of entry }

         end;
         iscst:   begin

            gettyp(tp, tscst); { get the type entry }
            getstr(tp^.sval); { get string }
            { the compiler has a bad habit of interspersing these into the
              code, so we have to set the size now. Fortunately, they are
              shallow entries (no sublevels) }
            sizset(tp) { set size of entry }

         end;         
         iccst:   begin

            if gblchr = nil then error(einvfmt); { must have a character base }
            gettyp(tp, tccst); { get the type entry }
            read(intfil, b); { get the character constant }
            tp^.cval := chr(b); { place value }
            { the compiler has a bad habit of interspersing these into the
              code, so we have to set the size now. Fortunately, they are
              shallow entries (no sublevels) }
            sizset(tp) { set size of entry }

         end;         
         ircst:   begin

            if gblreal = nil then error(einvfmt); { must have a real base }
            gettyp(tp, trcst); { get the type entry }
            rdreal(tp^.rval); { get value }
            { the compiler has a bad habit of interspersing these into the
              code, so we have to set the size now. Fortunately, they are
              shallow entries (no sublevels) }
            sizset(tp) { set size of entry }

         end;
         istcst:  begin

            gettyp(tp, tstcst); { get the type entry }
            getlnk(tp^.stct); { get the base type }
            getlnk(tp^.stcc) { get the constant list start }

         end;
         istet:   begin

            gettyp(tp, tstet); { get the type entry }
            getlnk(tp^.sten); { get next linkage }
            rdnum(tp^.stes); { get starting value }
            rdnum(tp^.stee); { get ending value }
            getlnk(tp^.steh) { get head linkage }
         
         end;
         iarrcst: begin

            gettyp(tp, tarrcst); { get the type entry }
            getlnk(tp^.arcn) { get the list linkage }

         end;
         iarrcel: begin

            gettyp(tp, tarrcel); { get the type entry }
            getlnk(tp^.aren); { get the next entry link }
            getlnk(tp^.arec) { get the constant link }

         end;
         ireccst: begin

            gettyp(tp, treccst); { get the type entry }
            getlnk(tp^.recn) { get the list linkage }

         end;
         ireccel: begin

            gettyp(tp, treccel); { get the type entry }
            getlnk(tp^.reen); { get the next entry link }
            getlnk(tp^.reec) { get the constant link }

         end;
         ienum:   begin

            gettyp(tp, tenum); { get the type entry }
            getlnk(tp^.enc) { link to start of enumerator list }

         end;
         ienme:   begin
        
            gettyp(tp, tenme); { get the type entry }
            getlnk(tp^.enx); { get next enumerator link }
            getlnk(tp^.enh); { get head link }
            rdnum(tp^.env) { get value }

         end;
         isub:    begin
        
            gettyp(tp, tsub); { get the type entry }
            getlnk(tp^.subt); { get base type link }
            rdnum(tp^.subl); { get lower bound }
            rdnum(tp^.subu) { get upper bound }

         end;
         iptr:    begin

            gettyp(tp, tptr); { get the type entry }
            getlnk(tp^.ptrt) { get base type link }

         end;
         iarray:  begin

            gettyp(tp, tarray); { get the type entry }
            getlnk(tp^.arrt); { get the base type }
            getlnk(tp^.arri) { get the index type }

         end;
         igarry:  begin

            gettyp(tp, tgarry); { get the type entry }
            getlnk(tp^.gart) { get the base type }

         end;
         ifile:   begin

            gettyp(tp, tfile); { get the type entry }
            getlnk(tp^.filt) { get base type }

         end;
         iset:    begin

            gettyp(tp, tset); { get the type entry }
            getlnk(tp^.sett) { get base type }

         end;
         irecord: begin

            gettyp(tp, trecord); { get the type entry }
            getlnk(tp^.recf) { get field list link }

         end;
         ifield:  begin

            gettyp(tp, tfield); { get the type entry }
            getlnk(tp^.fldn); { get next field link }
            getlnk(tp^.fldh); { get head link }
            getlnk(tp^.fldt) { get base link }

         end;
         iftag:   begin

            gettyp(tp, tftag); { get the type entry }
            getlnk(tp^.ftgc); { get case list link }
            getlnk(tp^.ftgh); { get head }
            getlnk(tp^.ftgt); { get base }
            read(intfil, b); { get exists flag }
            tp^.ftge := b <> 0 { place }

         end;
         ifcas:   begin

            gettyp(tp, tfcas); { get the type entry }
            getlnk(tp^.fcsn); { get next case }
            getlnk(tp^.fcsf); { get field list }
            rdnum(tp^.fcsc) { get case constant }

         end;
         ivar:    begin

            gettyp(tp, tvar); { get the type entry }
            { determine where variable will live. If the variable is in the
              system (1) or module/program (2) block, it is global, else
              it is a local }
            tp^.local := blkcnt >= 3;
            getlnk(tp^.vart); { get base }
            read(intfil, b); { get external flag }
            tp^.vare := b <> 0 { set }

         end;
         ifix:    begin

            gettyp(tp, tfix); { get the type entry }
            getlnk(tp^.fixt); { get base type link }
            getlnk(tp^.fixc); { get constant link }
            read(intfil, b); { get external flag }
            tp^.fixe := b <> 0 { set }

         end;
         iproc:   begin

            gettyp(tp, tproc); { get the type entry }
            getlnk(tp^.prcp); { get parameter list }
            read(intfil, b); { get external flag }
            tp^.prce := b <> 0 { set }

         end;
         ifunc:   begin

            gettyp(tp, tfunc); { get the type entry }
            getlnk(tp^.fncp); { get parameter list }
            getlnk(tp^.fncr); { get function result }
            { for functions, we need the function result to look like a stack
              variable. so we make one up, and that takes the place of
              the function result }
            gettypa(tp1, tfuncr); { get a function result type entry }
            tp1^.fnrt := tp^.fncr; { place type }
            tp^.fncr := tp1; { place that as function result }
            read(intfil, b); { get external flag }
            tp^.fnce := b <> 0 { set }

         end;
         ipar:    begin

            gettyp(tp, tpar); { get the type entry }
            tp^.local := true; { set local }
            getlnk(tp^.parn); { get next parameter }
            getlnk(tp^.part); { get base }
            getlnk(tp^.parh) { get head }

         end;
         ivpar:   begin

            gettyp(tp, tvpar); { get the type entry }
            tp^.local := true; { set local }
            getlnk(tp^.vprn); { get next parameter }
            getlnk(tp^.vprt); { get base }
            getlnk(tp^.vprh) { get head }

         end;
         iwpar:   begin

            gettyp(tp, twpar); { get the type entry }
            tp^.local := true; { set local }
            getlnk(tp^.wprn); { get next parameter }
            getlnk(tp^.wprt); { get base }
            getlnk(tp^.wprh) { get head }

         end;
         ipproc:  begin

            gettyp(tp, tpproc); { get the type entry }
            tp^.local := true; { set local }
            getlnk(tp^.pprp); { get parameter list }
            getlnk(tp^.pprn) { get next parameter }

         end;
         ipfunc:  begin

            gettyp(tp, tpfunc); { get the type entry }
            tp^.local := true; { set local }
            getlnk(tp^.pfnp); { get parameter list }
            getlnk(tp^.pfnr); { get function result }
            getlnk(tp^.pfnn); { get next parameter }
            { for functions, we need the function result to look like a stack
              variable. so we make one up, and that takes the place of
              the function result }
            gettypa(tp1, tfuncr); { get a function result type entry }
            tp1^.fnrt := tp^.pfnr; { place type }
            tp^.pfnr := tp1; { place that as function result }

         end;
         iint:    begin { integer type }

            gettyp(tp, tinteger); { get the type entry }
            gblint := tp { place global integer type }

         end;
         ichar:   begin { character type }

            gettyp(tp, tchar); { character type }
            gblchr := tp { place global character type }

         end;
         iboolean: begin { boolean type }

            gettyp(tp, tboolean); { get the type entry }
            getlnk(tp^.bnc) { get enumerated constants }

         end;
         ireal:   begin { real type }

            gettyp(tp, treal); { get the type entry }
            gblreal := tp { place global integer type }

         end;
         isreal:  gettyp(tp, tsreal); { short real type }
         itext:   gettyp(tp, ttext); { text file entry }
         ieset:   gettyp(tp, teset); { empty set }
         iglbl:   begin

            gettyp(tp, tglbl); { get the type entry }
            read(intfil, b); { get module type }
            if b > 5 then error(einvfmt); { invalid format }
            tp^.mrkt := mrktyp(b) { place type }

         end;
         inull:   gettyp(tp, tnull); { get the type entry }
         isym:    begin { symbols not presently supported }

            getstr(str); { skip }
            rdnum(v);
            rdnum(v);
            read(intfil, b)

         end;
         issym:   getstr(str); { not supported, skip }

         { *** OBJECT CODE SECTION *** }

         ibgnpgm:  begin

            resblk; { resolve forward references }
            sizblk; { size entries in block }
            typstk^.res := nil; { clear resolvables }
            typstk^.resa := nil;
            if not typstk^.loc and (typstk^.lvl >= 3 )then begin

               { locals not allocated }
               allloc; { allocate any previous block locals }
               typstk^.loc := true { set locals resolved }

            end;
            typstk^.mark^.addr := pgmcnt; { set address of code }
            { if this is the main block start, link that to the jump
              instruction at the start of memory }
            if blkcnt = 2 then makrld(1, typstk^.mark, itadr);
            { if a procedure or function, it has locals, and so they must
              be allocated }
            if typstk^.mark^.t = tproc then begin

               { we are activating a procedure }
               if typstk^.mark^.prcv <> 0 then begin { there are locals }

                  emit(opstkoff); { generate stack offset }
                  emitint(-typstk^.mark^.prcv) { to allocate variables }

               end

            end else if typstk^.mark^.t = tfunc then begin

               { we are activating a function }
               if typstk^.mark^.fncv <> 0 then begin { there are locals }

                  emit(opstkoff); { generate stack offset }
                  emitint(-typstk^.mark^.fncv) { to allocate variables }

               end

            end;
            { place stack bottom for this block in it's display }
            emit(opstostk); { generate store stack }
            emitadr(typstk^.mark, itdsp) { to display }
            
         end;
         iendpgm:  begin

            { if a procedure or function, it has locals, and so they must
              be deallocated }
            if typstk^.mark^.t = tproc then begin

               { we are deactivating a procedure }
               if typstk^.mark^.prcv <> 0 then begin { deallocate locals }

                  emit(opstkoff); { generate stack offset }
                  emitint(typstk^.mark^.prcv)

               end;
               if typstk^.mark^.prca <> 0 then begin { deallocate parameters }

                  emit(opretoff); { generate stack offset and return }
                  emitint(typstk^.mark^.prca)

               end else emit(opret) { otherwise just return }

            end else if typstk^.mark^.t = tfunc then begin

               if typstk^.mark^.fncv <> 0 then begin { dellocate locals }

                  emit(opstkoff); { generate stack offset }
                  emitint(typstk^.mark^.fncv)

               end;
               if typstk^.mark^.fnca <> 0 then begin { deallocate parameters }

                  emit(opretoff); { generate stack offset and return }
                  emitint(typstk^.mark^.fnca)

               end else emit(opret) { otherwise just return }

            end else emit(opret) { set return to caller }

         end;
         ibgnext:  ; { no action required at present }
         iendext:  ; { no action required at present }
         ilodadr:   begin { load address }

            getlnk(tp); { link object to load }
            if (tp^.t = tfield) or (tp^.t = tftag) then begin

               { access is to a 'with' field, must lookup reference in with
                 stacked structures }
               sp := srtstk; { index 1st on stack }
               sp1 := nil; { set no entry found }
               while sp <> nil do begin { search for 'with' match }

                  if sp^.withm then begin { is 'with' entry, check for match }

                     tp1 := sp^.lab^.recf; { get record field list start }
                     while tp1 <> nil do begin { search fields }

                        if tp1 = tp then begin { found }

                           sp1 := sp; { set this is the entry }
                           tp1 := nil; { signal end of fields }
                           sp := nil { signal end of stack }

                        end else if tp1^.t = tfield then tp1 := tp1^.fldn
                        else tp1 := nil { must be tag,  terminate }

                     end;

                  end;
                  if sp <> nil then sp := sp^.next { index next entry }

               end;
               if sp1 = nil then error(einvfmt); { set invalid intermediate }
               emit(oplodcloc); { load local address current block }
               emitint(sp1^.off-stack); { generate offset }
               { now we have pulled the address to tos. we can now process just
                 as a record offset }
               emit(oplodiint); { generate load immediate of record offset }
               emitadr(tp, itadr);
               emit(opaddint) { add to record base }
            
            end else begin

               if tp^.local then begin { local address }

                  emit(oplodaloc); { load local address }
                  emitadr(tp, itdsp); { place display address }
                  emitint(tp^.addr) { place offset address }

               end else begin

                  emit(oplodiint); { load global address }
                  emitadr(tp, itadr) { place address }

               end

            end;
            stack := stack-stksiz { adds one }

         end;
         ilodfadr:    begin { load function result address }

            getlnk(tp); { get function type }
            tp := tp^.fncr; { index function variable }
            { load address for that onto the stack }
            emit(oplodaloc); { load local address }
            emitadr(tp, itdsp); { place display address }
            emitadr(tp, itadr); { place address }
            stack := stack-stksiz { adds one }

         end;
         iarrref:  begin { array reference }

            getlnk(tp); { get array type }
            emit(oprngchk); { generate range check }
            emitint(lbound(tp^.arri)); { place low bound }
            emitint(ubound(tp^.arri)); { place upper bound }
            emit(oplodiint); { generate load immediate }
            emitint(lbound(tp^.arri)); { find i-lower bound }
            emit(opsubint);
            emit(oplodiint); { generate load immediate }
            emitint(tp^.arrt^.size); { of base type size }
            emit(opmltint); { find i*size }
            emit(opaddint); { finally, add to array base address }
            stack := stack+stksiz { net is less one }

         end;
         iarfgar:  begin { general array reference }

            getlnk(tp); { get array type }
            if tp^.t <> tgarry then error(einvfmt); { bad format }
            emit(oparfgar); { generate general array reference }
            emitint(tp^.gart^.size); { output size of base element }
            stack := stack+intsiz+tgpsiz-intsiz { adjust stack }

         end;
         irecoff:     begin { record element reference }

            getlnk(tp); { get record field type }
            emit(oplodiint); { generate load immediate of record offset }
            emitadr(tp, itadr);
            emit(opaddint) { add to record base }

         end;
         ildiint:  begin

            getlnk(tp); { variable type }
            emit(opindint); { load indirect integer }

         end;
         ildirel:  emit(opindrl); { load indirect real }
         ildisrl:  emit(opindsrl); { load indirect short real }
         ildiset:  emit(opindset); { load indirect set }
         ildichr, 
         ildibol:  emit(opindchr); { load indirect character }
         ildisrc:  begin

            getlnk(tp); { get structure type }
            emit(opindstr); { load indirect structure }
            emitint(tp^.size); { with structure size }
            stack := stack+stksiz-tp^.size { minus pointer, plus structure }

         end;
         ildiptr:  emit(opindint); { load indirect integer }
         ilditgp:   begin

            emit(opindstr); { load indirect structure }
            emitint(tgpsiz); { set size }
            stack := stack+4 { add width of tag }

         end;
         ilimint: begin
 
            rdnum(v); { get integer parameter }
            emit(oplodiint); { load immediate integer }
            emitint(v); { output value in line }
            stack := stack-stksiz { adds one }

         end;
         ilimrel:  begin

            rdreal(r); { get real parameter }
            emit(oplodirl); { load immediate real }
            emitrl(r); { output value in line }
            stack := stack-stksiz { adds one }

         end;
         ilimns:  begin

            emit(oplodins); { load empty set }
            stack := stack-setsiz { adds a set }

         end;
         ilodlen:  begin

            getlnk(tp); { get array type }
            emit(oppoptop); { discard pointer, leave length }
            stack := stack+4 { removes the pointer portion }

         end;
         inotint:  begin

            emit(opnotint); { 'not' integer }
            stack := stack+stksiz { net is less one }

         end;
         inotbol:  begin

            emit(opnotbol); { 'not' boolean }
            stack := stack+stksiz { net is less one }

         end;
         isinset:  begin

            emit(opsetsin); { set single element }
            stack := stack+stksiz { net is less one }

         end;
         irngset:  begin

            emit(opsetrng); { set range }
            stack := stack+(2*stksiz) { net is less two }

         end;
         icvtitr:  emit(opcvtitr); { convert integer to real }
         { convert between real types does nothing to the stack, since all
           reals are the same on the stack }
         icvtrtsr: ;
         icvtgtf:  begin

            getlnk(tp); { get fixed type }
            emit(opcvtfix); { convert general to fixed array pointer }
            emitint(tp^.size); { generate string size }
            stack := stack+4 { pointer becomes simple }
            
         end;
         icvtftg:  begin

            getlnk(tp); { get fixed type }
            emit(opcvttag); { convert fixed pointer to tagged }
            emitint(tp^.size); { generate string size }
            stack := stack-4 { pointer becomes complex }
            
         end;
         icvtntg:  begin

            { to convert nil to tagged nil, just add a zero }
            emit(oplodiint); { load immediate integer }
            emitint(0); { output value in line }
            stack := stack-stksiz { adds one }

         end;
         iswptop:  begin

            getlnk(tp); { get source }
            getlnk(tp1); { get destination }
            { swap is a problem, because one or both of the operands could be
              real, which are allways double length on the stack (even shorts).
              It could also be a tagged pointer over a normal pointer (a 
              special case of write). so we check and generate one of five swap
              types }
            if realt(tp) and realt(tp1) then emit(opswprr) { real with real }
            else if realt(tp) then emit(opswpri) { real with integer }
            else if realt(tp1) then emit(opswpir) { integer with real }
            else if tp^.t = tgarry then emit(opswpti) { tagged with integer }
            else emit(opswpii) { integer with integer }
            
         end;
         iintset:  begin

            emit(opsetint); { find set intersection }
            stack := stack+setsiz { net less one set }

         end;
         imltrel:   begin

            emit(opmltrl); { multiply real }
            stack := stack+stksiz { net is less one }

         end;
         imltint:  begin

            emit(opmltint); { Multiply integer }
            stack := stack+stksiz { net is less one }

         end;
         idivrel:   begin

            emit(opdivrl); { Divide real }
            stack := stack+stksiz { net is less one }

         end;
         idivint:  begin

            emit(opdivint); { Divide integer }
            stack := stack+stksiz { net is less one }
      
         end;
         imodint:  begin

            emit(opmodint); { Modulo integer }
            stack := stack+stksiz { net is less one }

         end;
         iandint:  begin

            emit(opandint); { Integer 'and' }
            stack := stack+stksiz { net is less one }

         end;
         inegint:  emit(opnegint); { Negate integer }
         inegrel:   emit(opnegrl); { Negate real }
         iuniset:  begin

            emit(opsetuni); { Set union }
            stack := stack+setsiz { net less one set }

         end;
         iaddrel:   begin

            emit(opaddrl); { Add real }
            stack := stack+stksiz { net is less one }

         end;
         iaddint:  begin

            emit(opaddint); { Add integer }
            stack := stack+stksiz { net is less one }

         end;
         idifset:  begin

            emit(opsetdif); { Set difference }
            stack := stack+setsiz { net less one set }

         end;
         isubrel:   begin

            emit(opsubrl); { Subtract real }
            stack := stack+stksiz { net is less one }

         end;
         isubint:  begin

            emit(opsubint); { Subtract integer }
            stack := stack+stksiz { net is less one }

         end;
         iorint:   begin

            emit(oporint); { integer 'or' }
            stack := stack+stksiz { net is less one }

         end;
         ixorint:  begin

            emit(opxorint); { integer 'xor' }
            stack := stack+stksiz { net is less one }

         end;
         iincset:   begin

            emit(opsetin); { Set inclusion }
            stack := stack+setsiz { net less one set }

         end;
         iequset:  begin

            emit(opequset); { Set equal }
            stack := stack+(2*setsiz)-stksiz { lost two sets, add boolean }

         end;
         iequrel:   begin

            emit(opequrl); { Real equal }
            stack := stack+stksiz { net is less one }

         end;
         iequstr:  begin

            getlnk(tp); { get string type }
            emit(opequstr); { String equal }
            emitint(tp^.size); { generate string size }
            stack := stack+stksiz { net is less one }

         end;
         iequgst:  begin

            emit(opequgst); { general string equal }
            { set two tagged pointers replaced by boolean }
            stack := stack+tgpsiz+tgpsiz-bolsiz

         end;
         iequint:  begin

            emit(opequint); { Integer equal }
            stack := stack+stksiz { net is less one }

         end;
         iequtgp:  begin

            emit(opequtgp); { tagged pointer equal }
            stack := stack+(2*tgpsiz)-intsiz { adjust stack }

         end;
         ineqset:  begin

            emit(opequset); { Set equal }
            emit(opnotbol); { and invert }
            stack := stack+(2*setsiz)-stksiz { lost two sets, add boolean }

         end;
         ineqrel:   begin

            emit(opequrl); { Real equal }
            emit(opnotbol); { and invert }
            stack := stack+stksiz { net is less one }

         end;
         ineqstr:  begin

            getlnk(tp); { get string type }
            emit(opequstr); { String equal }
            emitint(tp^.size); { generate string size }
            emit(opnotbol); { and invert }
            stack := stack+stksiz { net is less one }

         end;
         ineqgst:  begin

            emit(opequgst); { general string equal }
            emit(opnotbol); { and invert }
            { set two tagged pointers replaced by boolean }
            stack := stack+tgpsiz+tgpsiz-bolsiz

         end;
         ineqint:  begin

            emit(opequint); { Integer equal }
            emit(opnotbol); { and invert }
            stack := stack+stksiz { net is less one }

         end;
         ineqtgp:  begin

            emit(opequtgp); { tagged pointer equal }
            emit(opnotbol); { and invert }
            stack := stack+(2*tgpsiz)-intsiz { adjust stack }

         end;
         ileqset:  begin

            emit(opleqset); { less than or equal }
            stack := stack+(2*setsiz)-stksiz { lost two sets, add boolean }

         end;
         ileqrel:   begin

            emit(opgtnrl); { greater than }
            emit(opnotbol); { and invert }
            stack := stack+stksiz { net is less one }

         end;
         ileqstr:  begin

            getlnk(tp); { get string type }
            emit(opgtnstr); { greater than }
            emitint(tp^.size); { generate string size }
            emit(opnotbol); { and invert }
            stack := stack+stksiz { net is less one }

         end;
         ileqgst:  begin

            emit(opgtngst); { general string greater than }
            emit(opnotbol); { and invert }
            { set two tagged pointers replaced by boolean }
            stack := stack+tgpsiz+tgpsiz-bolsiz

         end;
         ileqint:  begin

            emit(opgtnint); { greater than }
            emit(opnotbol); { and invert }
            stack := stack+stksiz { net is less one }

         end;
         igeqset:  begin

            emit(opgeqset); { Set greater than or equal }
            stack := stack+(2*setsiz)-stksiz { lost two sets, add boolean }

         end;
         igeqrel:   begin

            emit(opltnrl); { Real greater than or equal }
            emit(opnotbol); { and invert }
            stack := stack+stksiz { net is less one }

         end;
         igeqstr:  begin

            getlnk(tp); { get string type }
            emit(opltnstr); { String greater than or equal }
            emitint(tp^.size); { generate string size }
            emit(opnotbol); { and invert }
            stack := stack+stksiz { net is less one }

         end;
         igeqgst:  begin

            emit(opltngst); { general string less than }
            emit(opnotbol); { and invert }
            { set two tagged pointers replaced by boolean }
            stack := stack+tgpsiz+tgpsiz-bolsiz

         end;
         igeqint:  begin

            emit(opltnint); { Integer greater than or equal }
            emit(opnotbol); { and invert }
            stack := stack+stksiz { net is less one }

         end;
         iltnrel:   begin

            emit(opltnrl); { Real less than }
            stack := stack+stksiz { net is less one }

         end;
         iltnstr:  begin

            getlnk(tp); { get string type }
            emit(opltnstr); { String less than }
            emitint(tp^.size); { generate string size }
            stack := stack+stksiz { net is less one }

         end;
         iltngst:  begin

            emit(opltngst); { general string less than }
            { set two tagged pointers replaced by boolean }
            stack := stack+tgpsiz+tgpsiz-bolsiz

         end;
         iltnint:  begin

            emit(opltnint); { Integer less than }
            stack := stack+stksiz { net is less one }

         end;
         igtnrel:   begin

            emit(opgtnrl); { Real greater than }
            stack := stack+stksiz { net is less one }

         end;
         igtnstr:  begin

            getlnk(tp); { get string type }
            emit(opgtnstr); { String greater than }
            emitint(tp^.size); { generate string size }
            stack := stack+stksiz { net is less one }

         end;
         igtngst:  begin

            emit(opgtngst); { general string greater than }
            { set two tagged pointers replaced by boolean }
            stack := stack+tgpsiz+tgpsiz-bolsiz

         end;
         igtnint:  begin

            emit(opgtnint); { Integer greater than }
            stack := stack+stksiz { net is less one }

         end;
         ibgnblk:  ; { begin statement block. not used }
         iendblk:  ; { end statement block. not used }
         iifbgn:   begin { if }

            { 'if' is converted to jumps }
            pushsrt; { add new structure level }
            gettypa(srtstk^.lab, tlab); { get a label type for false destination }
            emit(opjpf); { jump false }
            emitadr(srtstk^.lab, itadr); { place address }
            stack := stack+stksiz { net is less one }

         end;
         ielse:    begin

            tp := srtstk^.lab; { save false destination }
            gettypa(srtstk^.lab, tlab); { get a label type for true destination }
            emit(opjmp); { output jump over for 'if' first part }
            emitadr(srtstk^.lab, itadr);
            tp^.addr := pgmcnt { place address of 'if' skip }

         end;
         iifend:   begin

            srtstk^.lab^.addr := pgmcnt; { place address of 'if' or 'else' skip }
            popsrt { remove structure level }

         end;
         icasbgn:  begin { case begin }

            { 'case' is converted to jumps }
            pushsrt; { add new structure level }
            gettypa(srtstk^.lab, tlab) { get a label for exit }
            
         end;
         icassint:  begin { case select integer }

            emit(opduptop); { duplicate top of stack }
            rdnum(v); { get case selector constant }
            emit(oplodiint); { load immediate selector }
            emitint(v); { place value }
            emit(opequint); { find integer equal }
            if srtstk^.lab1 = nil then { skip label is not already defined }
               gettypa(srtstk^.lab1, tlab); { get a label for skip }
            emit(opjpt); { jump to statement }
            emitadr(srtstk^.lab1, itadr)

         end;
         icasstb:  begin { case statement begin }

            gettypa(srtstk^.lab2, tlab); { get a jump over }
            emit(opjmp); { jump to next case }
            emitadr(srtstk^.lab2, itadr);
            srtstk^.lab1^.addr := pgmcnt; { set location of jump to statment }
            srtstk^.lab1 := nil { release skip label }

         end;
         icasste:  begin { case statement end }

            emit(opjmp); { jump to exit }
            emitadr(srtstk^.lab, itadr);
            srtstk^.lab2^.addr := pgmcnt; { set location of jump over }

         end;
         icasend:  begin { case end }

            srtstk^.lab^.addr := pgmcnt; { place address of case exit }
            emit(oppoptop); { generate pop of case selector }
            popsrt; { remove structure level }
            stack := stack+stksiz { net is less one }

         end;
         iwhlexp:  begin { While expression marker }

            pushsrt; { start new structure level }
            gettypa(srtstk^.lab, tlab); { get label for loop jump }
            srtstk^.lab^.addr := pgmcnt; { set location }
            gettypa(srtstk^.lab1, tlab) { get label for skip }

         end;
         iwhlbgn:  begin { While begin }

            { while is converted to jumps }
            emit(opjpf); { jump if false }
            emitadr(srtstk^.lab1, itadr); { to skip label }
            stack := stack+stksiz { net is less one }

         end;
         iwhlend:  begin { While end }

            emit(opjmp); { jump to loop label }
            emitadr(srtstk^.lab, itadr);
            srtstk^.lab1^.addr := pgmcnt; { place address of skip }
            popsrt { remove structure level }

         end;
         irptbgn:  begin { Repeat begin }

            { repeat is converted to jumps }
            pushsrt; { add new structure level }
            gettypa(srtstk^.lab, tlab); { get label for loop jump }
            srtstk^.lab^.addr := pgmcnt; { set location }

         end;            
         irptend:  begin { Repeat end }

            emit(opjpf); { jump to loop label if false }
            emitadr(srtstk^.lab, itadr);
            popsrt; { remove structure level }
            stack := stack+stksiz { net is less one }

         end;
         ifortint, ifortchr, ifortbol, ifordint, ifordchr,
         ifordbol:  begin { for loop }

            emit(opswpii); { swap end for start expression }
            getlnk(tp); { get variable }
            { load adddress of variable }
            if tp^.local then begin { local address }

               emit(oplodaloc); { load local address }
               emitadr(tp, itdsp) { place display address }

            end else emit(oplodiint); { load global address }
            emitadr(tp, itadr); { place address }
            emit(opswpii); { swap address for start value }
            { store integer to control variable }
            case ic of { variable type }

               ifortint, ifordint:  emit(opstoi); { integer }
               ifortchr, ifordchr, { character }
               ifortbol, ifordbol:  emit(opstochr) { boolean }

            end;
            pushsrt; { start new structure level } 
            srtstk^.ic := ic; { save head type }
            emit(opduptop); { duplicate end value }
            { load adddress of variable }
            if tp^.local then begin { local address }

               emit(oplodaloc); { load local address }
               emitadr(tp, itdsp) { place display address }

            end else emit(oplodiint); { load global address }
            emitadr(tp, itadr); { place address }
            { load variable value }
            case ic of { variable type }

               ifortint, ifordint:  emit(opindint); { integer }
               ifortchr, ifordchr,
               ifortbol, ifordbol:  emit(opindchr) { character }

            end;
            if ic in [ifortint, ifortchr, ifortbol] then { to }
               emit(opltnint) { compare to end value }
            else { downto }
               emit(opgtnint); { compare to end value }
            gettypa(srtstk^.lab1, tlab); { get label for skip }
            emit(opjpt); { jump if true }
            emitadr(srtstk^.lab1, itadr); { to skip label }
            srtstk^.lab2 := tp; { save variable }
            gettypa(srtstk^.lab, tlab); { get label for loop jump }
            srtstk^.lab^.addr := pgmcnt; { set location }
            stack := stack+stksiz { net is less one }

         end;
         iforend:  begin { For end }

            tp := srtstk^.lab2; { get control variable }
            emit(opduptop); { duplicate end value }
            { load adddress of variable }
            if tp^.local then begin { local address }

               emit(oplodaloc); { load local address }
               emitadr(tp, itdsp) { place display address }

            end else emit(oplodiint); { load global address }
            emitadr(tp, itadr); { place address }
            { load variable value }
            case srtstk^.ic of { variable type }

               ifortint, ifordint:  emit(opindint); { integer }
               ifortchr, ifordchr,
               ifortbol, ifordbol:  emit(opindchr) { character }

            end;
            if srtstk^.ic in [ifortint, ifortchr, ifortbol] then { to }
               emit(opgtnint) { compare to end value }
            else { downto }
               emit(opltnint); { compare to end value }
            emit(opjpf); { jump if false }
            emitadr(srtstk^.lab1, itadr); { to skip label }
            { load adddress of variable }
            if tp^.local then begin { local address }

               emit(oplodaloc); { load local address }
               emitadr(tp, itdsp) { place display address }

            end else emit(oplodiint); { load global address }
            emitadr(tp, itadr); { place address }
            emit(opduptop); { save variable address }
            { load variable value }
            case srtstk^.ic of { variable type }

               ifortint, ifordint:  emit(opindint); { integer }
               ifortchr, ifordchr,
               ifortbol, ifordbol:  emit(opindchr) { character }

            end;
            { find "next" value }
            if srtstk^.ic in [ifortint, ifortchr, ifortbol] then
               emit(opsucint) { increment it }
            else emit(opprdint); { decrement it }
            { store variable value }
            case srtstk^.ic of { variable type }

               ifortint, ifordint:  emit(opstoi); { integer }
               ifortchr, ifordchr,
               ifortbol, ifordbol:  emit(opstochr) { boolean }

            end;
            emit(opjmp); { jump to loop label }
            emitadr(srtstk^.lab, itadr);
            srtstk^.lab1^.addr := pgmcnt; { place address of skip }
            emit(oppoptop); { purge end value }
            popsrt; { remove structure level }
            stack := stack+stksiz { net is less one }

         end;
         iwthbgn:  begin { 'with' begin }

            getlnk(tp); { get record type }
            pushsrt; { add new structure level }
            srtstk^.lab := tp; { set record type }
            srtstk^.withm := true; { set marks a 'with' }
            srtstk^.off := stack { place stack offset to access base }

         end;
         iwthend:  begin { 'with' end }

            emit(oppoptop); { remove base address }
            popsrt { remove structure level }

         end;
         igoto:    begin { goto }

            getlnk(tp); { get label to jump to }
            emit(opgoto); { goto label }
            emitadr(tp, itdsp); { generate display for target }
            emitadr(tp, itadr) { generate code address }

         end;
         iprcbgn:   getlnk(tp); { get and discard procedure entry }
         iprccal:   begin

            getlnk(tp); { get procedure entry }
            emit(opcall); { call procedure }
            emitadr(tp, itadr) { generate address }

         end; 
         iprccali:  begin

            getlnk(tp); { get procedure entry }
            emit(opcalli) { call procedure indirect }

         end;
         ifncbgn:   begin

            getlnk(tp); { get function entry }
            { find result by functiont type }
            if tp^.t = tfunc then tp := tp^.fncr
            else if tp^.t = tpfunc then tp := tp^.pfnr
            else error(einvfmt); { bad entry type }
            emit(oplodiint); { place function result }
            emitint(0); { as a dummy variable }
            { if standard real result, allocate double length result }
            if (realt(tp) and not srealt(tp)) or tgpt(tp^.fnrt) then begin

               emit(oplodiint); { load word }
               emitint(0)

            end

         end;
         ifnccal:   begin

            getlnk(tp); { get function entry }
            emit(opcall); { call function }
            emitadr(tp, itadr) { generate address }

         end;
         ifnccali:  begin

            getlnk(tp); { get function entry }
            emit(opcalli) { call indirect }

         end;
         iwrtsrc:   begin

            getlnk(tp); { get variable type }
            emit(opwrtfil); { generate typed file write }
            emitint(tp^.size); { place type length }
            stack := stack+stksiz { net is less one }

         end;
         iwrtintt:   begin

            emit(oplodiint); { stack the field }
            emitint(intfld);
            emit(opwrtintf); { Write integer }
            stack := stack+stksiz { net is less one }

         end;
         iwrtchrt:   begin

            emit(oplodiint); { stack the field }
            emitint(chrfld);
            emit(opwrtchrf); { Write character }
            stack := stack+stksiz { net is less one }

         end;
         iwrtbolt:   begin

            emit(opwrtbol); { Write boolean }
            stack := stack+stksiz { net is less one }

         end;
         iwrtrelt:    begin

            emit(oplodiint); { stack the field }
            emitint(rlfld);
            emit(opwrtrlf); { Write real }
            stack := stack+stksiz { net is less one }

         end;
         iwrtstrt:   begin { write string }

            getlnk(tp); { get string type }
            emit(oplodiint); { stack the field }
            emitint(tp^.size);
            emit(opwrtstrf); { generate string write }
            emitint(tp^.size); { place string length }
            stack := stack+stksiz { net is less one }

         end;
         iwrtgstt:   begin { write string }

            emit(opwrtgst); { generate general string write }
            stack := stack+tgpsiz { net is less one }

         end;
         iwrtintft:  begin

            emit(opwrtintf); { Write integer fielded }
            stack := stack+(2*stksiz) { net is less two }

         end;
         iwrtchrft:  begin

            emit(opwrtchrf); { Write character fielded }
            stack := stack+(2*stksiz) { net is less two }

         end;
         iwrtbolft:  begin

            emit(opwrtbolf); { Write boolean fielded }
            stack := stack+(2*stksiz) { net is less two }

         end;
         iwrtrelft:   begin

            emit(opwrtrlf); { Write real fielded }
            stack := stack+(2*stksiz) { net is less two }

         end;
         iwrtstrft:  begin { write string fielded }

            getlnk(tp); { get string type }
            emit(opwrtstrf); { generate string write fielded }
            emitint(tp^.size); { place string length }
            stack := stack+(2*stksiz) { net is less two }

         end;
         iwrtgstft:  begin { write general string fielded }

            emit(opwrtgstf); { generate string write fielded }
            stack := stack+intsiz+tgpsiz { net is less two }

         end;
         iwrtrelfft:  begin

            emit(opwrtrlff); { Write real fielded and fractioned }
            stack := stack+(2*stksiz) { net is less two }

         end;
         iwrtsrl:  begin

            emit(opwrtfsrl); { Write file short real }
            stack := stack+stksiz { net is less one }

         end;
         iwrtrel:   begin

            emit(opwrtfrl); { Write file real }
            stack := stack+stksiz { net is less one }

         end;
         iwrtset:  begin

            emit(opwrtfset); { Write file set }
            stack := stack+setsiz { net less one set }

         end;
         iwrtchr, iwrtbol:  begin

            emit(opwrtfchr); { write file character }
            stack := stack+stksiz { net is less one }
            
         end;
         iwrtint:  begin

            getlnk(tp); { get type }
            emit(opwrtfint); { Write file integer }
            stack := stack+stksiz { net is less one }

         end;
         iwrteolt:  emit(opwrteoln); { write file end of line }
         iredsrc:    begin { read file }

            getlnk(tp); { get variable type }
            emit(oprdfil); { generate typed file read }
            emitint(tp^.size); { place type length }
            stack := stack+stksiz { net is less one }

         end;
         iredintt:    begin

            getlnk(tp); { get type }
            emit(oprdint); { Read integer }
            stack := stack+stksiz { net is less one }
            
         end;
         iredchrt:    begin

            emit(oprdchr); { Read character }
            stack := stack+stksiz { net is less one }

         end;
         iredrelt:     begin

            emit(oprdrl); { Read real }
            stack := stack+stksiz { net is less one }

         end;
         iredsrlt:    begin

            emit(oprdsrl); { Read short real }
            stack := stack+stksiz { net is less one }

         end;
         iredeolt:   emit(oprdeoln); { read file end of line }
         iabsrel:    emit(opabsrl); { Abs of real }
         iabsint:   emit(opabsint); { Abs of integer }
         isqrrel:    emit(opsqrrl); { Sqr of real }
         isqrint:   emit(opsqrint); { Sqr of integer }
         iatnrel:    emit(opatnrl); { Arctan of real }
         icosrel:    emit(opcosrl); { Cos of real }
         iexprel:    emit(opexprl); { Exp of real }
         ilgnrel:     emit(oplnrl); { ln of real }
         isinrel:    emit(opsinrl); { Sin of real }
         isqtrel:    emit(opsqtrl); { Sqrt of real }
         ieolt:     emit(opeoln); { Eoln of file }
         ieof:      begin

            getlnk(tp); { get file type }
            emit(opeof) { Eof of file }

         end;
         iodd:      emit(opodd); { Odd of integer }
         isucint:   emit(opsucint); { Succ of integer }
         iprdint:   emit(opprdint); { Pred of integer }
         irnd:      emit(oprnd); { Round }
         itrc:      emit(optrc); { Trunc }
         iexist:    begin

            emit(opexist); { File exists }
            stack := stack+stksiz { net is less one }

         end;
         ilen:      emit(oplen); { find file length }
         iloc:      emit(oploc); { File location }
         iget:      emit(opget); { File get }
         igett:     emit(opgett); { Text file get }
         iput:      begin

            emit(opput); { File put }
            stack := stack+stksiz { net is less one }

         end;
         ilodafbuf: emit(oplodafbuf); { load address of file buffer }
         ilodafbuft: emit(oplodafbuft); { load address of text file buffer }
         ireset:    begin

            getlnk(tp); { get file type }
            tp1 := baset(tp); { find base type }
            if tp1^.t = ttext then begin

               emit(opresett); { rewrite text file }
               emitint(1) { place file record length }

            end else if tp1^.t = tfile then begin

               emit(opreset); { File rewrite }
               emitint(tp1^.filt^.size) { place file record length }

            end else error(einvfmt); { invalid format }
            stack := stack+stksiz { net is less one }

         end;
         irewrite:  begin

            getlnk(tp); { get file type }
            tp1 := baset(tp); { find base type }
            if tp1^.t = ttext then begin

               emit(oprewritet); { rewrite text file }
               emitint(1) { place file record length }

            end else if tp1^.t = tfile then begin

               emit(oprewrite); { File rewrite }
               emitint(tp1^.filt^.size) { place file record length }

            end else error(einvfmt); { invalid format }
            stack := stack+stksiz { net is less one }

         end;
         iclose:    begin

            emit(opclose); { File close }
            stack := stack+stksiz { net is less one }

         end;
         ipack:     begin { pack }

            { at this time, pack simply acts as an assign, because
              packing is unimplemented }
            getlnk(tp); { get packed type }
            getlnk(tp1); { get unpacked type }
            emit(opswpii); { swap packed for index }
            emit(oprngchk); { generate range check }
            emitint(lbound(tp1^.arri)); { place low bound }
            emitint(ubound(tp1^.arri)); { place upper bound }
            emit(oplodiint); { generate load immediate }
            emitint(lbound(tp1^.arri)); { find i-lower bound }
            emit(opsubint);
            emit(oplodiint); { generate load immediate }
            emitint(tp1^.arrt^.size); { of base type size }
            emit(opmltint); { find i*size }
            emit(oplodcloc); { pull unpacked to tos }
            emitint(2*stksiz); { which is two operands up }
            emit(opaddint); { finally, add to unpacked array base address }
            emit(opstostr); { generate structure store, unpacked to packed }
            emitint(tp^.size); { place packed array size }
            emit(oppoptop); { remove old unpacked copy }
            stack := stack+(3*stksiz) { net is less three }

         end;
         iunpack:   begin { unpack }

            { at this time, unpack simply acts as an assign, because
              packing is unimplemented }
            getlnk(tp); { get unpacked type }
            getlnk(tp1);  { get packed type }
            emit(oprngchk); { generate range check }
            emitint(lbound(tp^.arri)); { place low bound }
            emitint(ubound(tp^.arri)); { place upper bound }
            emit(oplodiint); { generate load immediate }
            emitint(lbound(tp^.arri)); { find i-lower bound }
            emit(opsubint);
            emit(oplodiint); { generate load immediate }
            emitint(tp^.arrt^.size); { of base type size }
            emit(opmltint); { find i*size }
            emit(opaddint); { finally, add to array base address }
            emit(opswpii); { swap so unpacked is destination }
            emit(opstostr); { generate structure store }
            emitint(tp^.size); { place packed array size }
            stack := stack+(3*stksiz) { net is less three }

         end;
         ipaget:     begin

            emit(oppage); { Page }
            stack := stack+stksiz { net is less one }

         end;
         iassign:     begin

            emit(opassign); { assign file }
            stack := stack+tgpsiz+stksiz { net is tgp and file }

         end;
         ipos:      begin

            emit(oppos); { Position file }
            stack := stack+(2*stksiz) { net is less two }

         end;
         idel:      begin

            emit(opdel); { Delete file }
            stack := stack+tgpsiz { net is less one }

         end;
         ichg:      begin

            emit(opchg); { Change file }
            stack := stack+(2*stksiz) { net is less two }

         end;
         istisrl:   begin { store short real variable }

            getlnk(tp); { get variable (unused) }
            emit(opstosrl); { generate store to address }
            stack := stack+(2*stksiz) { net is less two }

         end;
         istirel:    begin { store real variable }

            getlnk(tp); { get variable (unused) }
            emit(opstorl); { generate store to address }
            stack := stack+(2*stksiz) { net is less two }
               
         end;
         istiint, istichr, istibol:   begin

            getlnk(tp); { get variable type }
            { if the destination is a true integer, don't range check, since
              the destination can contain any result. Also don't check
              pointers }
            if not intt(tp) and (tp^.t <> tptr) and (tp^.t <> tnil) then begin 

               emit(oprngchk); { generate range check }
               emitint(lbound(tp)); { place low bound }
               emitint(ubound(tp)) { place upper bound }

            end;
            case ic of { type }

               istiint:   emit(opstoi); { process store to address }
               istichr,
               istibol: emit(opstochr) { process store to address }

            end;
            stack := stack+(2*stksiz) { net is less two }

         end;
         istiset:   begin

            getlnk(tp); { get variable (unused) }
            emit(opstoset); { generate store to address }
            stack := stack+setsiz+stksiz { net is less two }

         end;
         istisrc:      begin { store structured }

            getlnk(tp); { get object type }
            emit(opstostr); { generate structure store }
            emitint(tp^.size); { place object size }
            stack := stack+(2*stksiz) { net is less two }

         end;
         istigar:   begin { store structured }

            getlnk(tp); { get object type }
            if tp^.t <> tgarry then error(einvfmt); { bad format }
            emit(opstogar); { generate structure store }
            emitint(tp^.gart^.size); { place base object size }
            stack := stack+(2*tgpsiz) { net is less two }

         end;
         istitgp:   begin

            getlnk(tp); { get variable (unused) }
            emit(opstotgp); { generate store to address }
            stack := stack+tgpsiz+stksiz { adjust stack }

         end;
         istifsrl:  begin { store function short real }

            getlnk(tp); { get function type (unused) }
            emit(opstosrl); { process store to address }
            stack := stack+(2*stksiz) { net is less two }

         end;
         istifrel:   begin { store function real }

            getlnk(tp); { get function type (unused) }
            emit(opstorl); { process store to address }
            stack := stack+(2*stksiz) { net is less two }

         end;
         istiftgp:   begin { store function real }

            getlnk(tp); { get variable (unused) }
            emit(opstotgp); { generate store to address }
            stack := stack+tgpsiz+stksiz { adjust stack }

         end;
         istifint, istifchr, istifbol:  begin 

            { store function integer, character, boolean }
            getlnk(tp); { get function type }
            tp := baset(tp^.fncr); { index function variable }
            { if the destination is a true integer, don't range check, since
              the destination can contain any result }
            if not intt(tp) then begin { range check }

               emit(oprngchk); { generate range check }
               emitint(lbound(tp)); { place low bound }
               emitint(ubound(tp)) { place upper bound }

            end;
            case ic of { type }

               istifint: emit(opstoi); { process store to address }
               istifchr,
               istifbol: emit(opstochr) { process store to address }

            end;
            stack := stack+(2*stksiz) { net is less two }

         end;
         inew, idisp:     begin { new, dispose }

            ic1 := ic; { save type }
            getlnk(tp); { get variable type }
            rsiz := 0; { clear complete size specification }
            v := tp^.size; { set whole record size }
            tp := tp^.recf; { index field list }
            { read all tags following }
            getcod(ic);
            while ic = itag do begin { read tags }

               { a more compact form was specified than the whole type
                 contained in v, so we find the new minimum size by finding
                 all the fixed elements, adding that to the total, and
                 then finding a new minimum }
               rdnum(v); { get case constant }
               while tp^.t = tfield do begin { add fixed fields }

                  rsiz := v+tp^.fldt^.size; { add in size }
                  tp := tp^.next; { next entry }
                  if tp = nil then error(einvfmt); { invalid format }

               end;
               { now we should be pointing at the tag }
               if tp^.t <> tftag then error(einvfmt); { invalid format }
               tp := tp^.ftgc; { index case list }
               while tp^.fcsc <> v do begin { find matching case }

                  tp := tp^.next;
                  if tp = nil then error(einvfmt) { invalid format }

               end;
               v := tp^.size; { find new minimum }
               tp := tp^.fcsf { index that case list }

            end;
            if ic <> iendtag then error(einvfmt); { should be terminated }
            rsiz := rsiz+v; { find total record size }
            if ic1 = inew then emit(opnew) { generate new }
            else emit(opdisp); { generate dispose }
            emitint(rsiz); { place size }
            stack := stack+stksiz { net is less one }

         end;
         itag:      error(einvfmt); { should not occur alone }
         iendtag:   error(einvfmt); { should not occur alone }
         ipoptop:   begin

            getlnk(tp); { get operand type }
            emit(oppoptop); { remove top of stack }
            stack := stack+stksiz { net is less one }

         end;
         ilabequ:   begin

            getlnk(tp); { get label type }
            tp^.addr := pgmcnt { set location }

         end;
         irngchk:   begin

            getlnk(tp); { get check type }
            emit(oprngchk); { generate range check }
            emitint(lbound(tp)); { place low bound }
            emitint(ubound(tp)) { place upper bound }

         end;
         inewgar:   begin

            getlnk(tp); { get array type }
            if tp^.t <> tgarry then error(einvfmt); { bad format }
            emit(opnewgar); { allocate new general array }
            emitint(tp^.gart^.size); { of base element size }
            stack := stack+intsiz+stksiz { adjust stack }

         end;
         idspgar:   begin

            getlnk(tp); { get array type }
            if tp^.t <> tgarry then error(einvfmt); { bad format }
            emit(opdspgar); { deallocate general array }
            emitint(tp^.gart^.size); { of base element size }
            stack := stack+tgpsiz { adjust stack }

         end;
         ihalt: emit(opexit); { halt simulation }
         iendfil: ; { do nothing }

      end

   until ic = iendfil; { end of file tolken }
   close(intfil) { close intermediate file }

end;

{******************************************************************************

Place constant

Outputs a constant entry to the current pgmcnt location, and advances pgmcnt
to after the constant. Assigns the base address of the constant to the location
where the constant was output.

******************************************************************************}

procedure plccst(ft: typptr;  { 'form' type }
                 tp: typptr); { constant to place }

var i:      1..setsiz; { index for set bytes }
    setbuf: packed array [1..setsiz] of byte; { set holder }
    v:      integer; { set value }
    ea:     meminx; { ending address }

begin

   if tp^.t = ticst then begin { integer }

      tp^.addr := pgmcnt; { assign base address }
      emitint(tp^.ival) { place integer }

   end else if tp^.t = trcst then begin { real }

      tp^.addr := pgmcnt; { assign base address }
      if ft^.t = treal then emitrl(tp^.rval) { place real }
      else if ft^.t = tsreal then emitsrl(tp^.rval) { place short real }
      else error(einvfmt) { invalid format }

   end else if tp^.t = tscst then begin { found a string entry }

      tp^.addr := pgmcnt; { assign base address }
      emitstr(tp^.sval) { transfer to storage }

   end else if tp^.t = tccst then begin { found a character entry }

      tp^.addr := pgmcnt; { assign base address }
      emitbyt(ord(tp^.cval)) { transfer to storage }

   end else if tp^.t = tstcst then begin { found a set constant }

      tp^.addr := pgmcnt; { assign base address }
      { clear a buffer for the set, then set each specified element of the
        set in the buffer }
      for i := 1 to setsiz do setbuf[i] := 0; { clear buffer }
      tp := tp^.stcc; { index 1st constant }
      while tp <> nil do begin { traverse and set elements }

         if tp^.t <> tstet then error(einvfmt); { invalid format }
         for v := tp^.stes to tp^.stee do begin { set a range of elements }

            i := v div 8+1; { find proper byte address }
            if i > setsiz then error(einvelm); { invalid set element }
            case v mod 8 of { set the bit }

               0: setbuf[i] := setbuf[i] or $01;
               1: setbuf[i] := setbuf[i] or $02;
               2: setbuf[i] := setbuf[i] or $04;
               3: setbuf[i] := setbuf[i] or $08;
               4: setbuf[i] := setbuf[i] or $10;
               5: setbuf[i] := setbuf[i] or $20;
               6: setbuf[i] := setbuf[i] or $40;
               7: setbuf[i] := setbuf[i] or $80

            end

         end;
         tp := tp^.sten { index next element }

      end;
      for i := 1 to setsiz do emitbyt(setbuf[i]) { output set bytes }
   
   end else if tp^.t = tarrcst then begin { array constant }

      if ft^.t <> tarray then error(einvfmt); { format error }
      ft := ft^.arrt; { index base type }
      tp := tp^.arcn; { index 1st entry }
      while tp <> nil do begin { allocate subconstants }

         if tp^.t <> tarrcel then error(einvfmt); { invalid format }
         plccst(ft, tp^.arec); { place constant }
         tp := tp^.aren { link next }

      end

   end else if tp^.t = treccst then begin { record constant }

      ea := pgmcnt+ft^.size; { set ending address }
      if ft^.t <> trecord then error(einvfmt); { format error }
      ft := ft^.recf; { index field list }
      tp := tp^.recn; { index 1st entry }
      while tp <> nil do begin { allocate subconstants }

         if tp^.t <> treccel then error(einvfmt); { invalid format }
         if ft^.t = tfield then begin { standard field }

            plccst(ft^.fldt, tp^.reec); { place constant }
            ft := ft^.fldn { index next field }

         end else if ft^.t = tftag then begin { tagfield }

            if ft^.ftge then { tagfield exists }
               plccst(ft^.ftgt, tp^.reec); { place constant }
            { find case field list by tagfield }
            ft := ft^.ftgc; { index 1st case list }
            v := consti(tp^.reec); { find tagfield value }
            while ft^.fcsc <> v do begin { find case }

               ft := ft^.fcsn; { index next }
               if ft = nil then error(einvfmt) { invalid format }

            end;
            ft := ft^.fcsf { index that field list }

         end else error(einvfmt); { invalid format }
         tp := tp^.reen { link next }

      end;
      { we allocated the requested data, but depending on variants, that may
        not make a full record. so we must finish it if required }
      while pgmcnt < ea do emitbyt(0) { pad to the proper address }

   end else if tp^.t = tenme then begin { enumerated constant }

      tp^.addr := pgmcnt; { assign base address }
      if ft^.t = tboolean then emitbyt(tp^.env) { boolean }
      else emitint(tp^.env) { place integer }

   end

end;

{******************************************************************************

Set constant addresses

First allocates all the fixed objects, then Traverses the entire types
database, and sets the base address of all string and set constants. String and
set constants are unusual in that they are not contained in inline code.
Therefore a table is made of them in program storage, appearing after the main
code. 

******************************************************************************}

procedure setconst;

var sp: tpsptr; { type stack pointer }

{ process fixed object list }

procedure flist(tp: typptr); { list to process }

begin

   while tp <> nil do begin { traverse list }

      if tp^.t = tfix then begin 

         tp^.addr := pgmcnt; { place fixed object }
         plccst(tp^.fixt, tp^.fixc) { allocate fixed }

      end;
      tp := tp^.next { next type entry }

   end

end;

{ process string/set list }

procedure sslist(tp: typptr); { list to process }

begin

   while tp <> nil do begin { traverse list }

      { must be string or set constant, and must not already have an address.
        if there is an address, it has already been allocated as part of a
        fixed object. this is ok }
      if (tp^.addr = 0) and ((tp^.t = tscst) or (tp^.t = tstcst)) then
         { well, this is not pretty, but strings and constants have no set base
           type, and don't require one. they also have no substructure }
         plccst(nil, tp); { allocate possible constant }
      tp := tp^.next { next type entry }

   end

end;

begin

   { allocate fixed objects }
   sp := typlst; { index 1st list entry }
   while sp <> nil do begin { traverse blocks }

      flist(sp^.typ); { process standard list }
      flist(sp^.typa); { process alternate list }
      sp := sp^.next { next block }

   end;
   { allocate loose constants }
   sp := typlst; { index 1st list entry }
   while sp <> nil do begin { traverse blocks }

      sslist(sp^.typ); { process standard list }
      sslist(sp^.typa); { process alternate list }
      sp := sp^.next { next block }

   end

end;

{******************************************************************************

Set display

Allocates the members of the display, and places the display address in all
entries of the block that uses them.

******************************************************************************}

procedure setdisp;

var sp: tpsptr; { type stack pointer }
    tp: typptr; { type entry pointer }

{ set display of all parameters }

procedure prcdisp(tp: typptr);

begin

   while tp <> nil do begin { traverse }

      tp^.disp := pgmcnt; { set display }
      case tp^.t of { parameter, link next }

         tpar:   tp := tp^.parn; 
         tvpar:  tp := tp^.vprn;
         twpar:  tp := tp^.wprn;
         tpproc: tp := tp^.pprn;
         tpfunc: tp := tp^.pfnn

      end

   end

end;

begin

   sp := typlst; { index 1st list entry }
   while sp <> nil do begin { traverse blocks }

      sp^.mark^.disp := pgmcnt; { set the mark's own display }
      if sp^.mark^.t = tproc then { procedure }
         prcdisp(sp^.mark^.prcp) { set parameter's display }
      else if sp^.mark^.t = tfunc then begin { function }

         prcdisp(sp^.mark^.fncp); { set parameter's display }
         sp^.mark^.fncr^.disp := pgmcnt { set function result display }

      end;
      { process standard list }
      tp := sp^.typ; { index 1st type entry }
      while tp <> nil do begin { traverse list }

         { marks, parameters and function results lie in the level above, so
           don't set them }
         if not (tp^.t in [tproc, tfunc, tglbl, tpar, tvpar, twpar, tpproc,
                           tpfunc, tfuncr]) then
            tp^.disp := pgmcnt; { place display address }
         tp := tp^.next { next type entry }

      end;
      { process alternate list }
      tp := sp^.typa; { index 1st type entry }
      while tp <> nil do begin { traverse list }

         { marks, parameters and function results lie in the level above, so
           don't set them }
         if not (tp^.t in [tproc, tfunc, tglbl, tpar, tvpar, twpar, tpproc, 
                           tpfunc, tfuncr]) then
            tp^.disp := pgmcnt; { place display address }
         tp := tp^.next { next type entry }

      end;
      emitint(0); { place display variable }
      sp := sp^.next { next block }

   end

end;

{******************************************************************************

Set type (variable) global addresses

Traverses the entire types database, and sets the base address of all global
types. This could actually be done at the same time as the size set, but we 
break it out into a separate function.
The addresses are based on the entry size, with a running count made of address
space taken. Types are placed according to whether they are global or local.
The 1st and 2nd block levels are allocated as global, and are laid into program
storage like constants and code.
Other levels are treated as relative addresses. A separate counter is created,
starting at zero, and types are allocated logically to that.

******************************************************************************}

procedure setaddr;

var sp: tpsptr; { type stack pointer }
    tp: typptr; { type entry pointer }
    lvl: integer; { level counter }

begin

   sp := typlst; { index 1st list entry }
   lvl := 1; { set 1st level }
   while sp <> nil do begin { traverse blocks }

      if sp^.lvl <= 2 then begin { block 1 and 2 are global }

         { process standard list }
         tp := sp^.typ; { index 1st type entry }
         while tp <> nil do begin { traverse list }

            if tp^.t = tvar then begin { found a variable entry }

               { check memory overflow }
               if pgmcnt+tp^.size > maxmem then error(ememovf);
               tp^.addr := pgmcnt; { assign base address }
               pgmcnt := pgmcnt+tp^.size { allocate variable }

            end;
            tp := tp^.next { next type entry }

         end;
         { process alternate list }
         tp := sp^.typa; { index 1st type entry }
         while tp <> nil do begin { traverse list }

            if tp^.t = tvar then begin { found a variable entry }

               { check memory overflow }
               if pgmcnt+tp^.size > maxmem then error(ememovf);
               tp^.addr := pgmcnt; { assign base address }
               pgmcnt := pgmcnt+tp^.size { allocate variable }

            end;
            tp := tp^.next { next type entry }

         end

      end;
      sp := sp^.next { next block }

   end

end;

{******************************************************************************

Set record offsets

Traverses the entire types database, and sets the address offsets for any 
record types. Variant records are given the usual overlapping address offsets.

******************************************************************************}

procedure setrec;

var sp: tpsptr; { type stack pointer }
    tp: typptr; { type entry pointer }

{ allocate record entry }

procedure recoff(tp: typptr;   { record field list }
                 ba: integer); { base address }

var af: boolean; { allocate/don't allocate flag }

begin

   while tp <> nil do begin { traverse fields }

      tp^.addr := ba; { set base address of entry }
      af := true; { set allocation on }
      { check tag entry does not exist }
      if tp^.t = tftag then if not tp^.ftge then af := false;
      if af then ba := ba+tp^.size; { find next base address }
      if tp^.t = tfield then tp := tp^.fldn { go next field }
      else begin { process variant }

         if tp^.t <> tftag then error(einvfmt); { bad format }
         tp := tp^.ftgc; { index case list }
         while tp <> nil do begin { process variants }

            if tp^.t <> tfcas then error(einvfmt); { bad format }
            recoff(tp^.fcsf, ba); { allocate this variant }
            tp := tp^.fcsn { next case }

         end;
         tp := nil { flag end of field list }

      end

   end

end;

begin

   sp := typlst; { index 1st list entry }
   while sp <> nil do begin { traverse blocks }

      { process standard list }
      tp := sp^.typ; { index 1st type entry }
      while tp <> nil do begin { traverse list }

         if tp^.t = trecord then recoff(tp^.recf, 0); { allocate entry }
         tp := tp^.next { next type entry }

      end;
      { process alternate list }
      tp := sp^.typa; { index 1st type entry }
      while tp <> nil do begin { traverse list }

         if tp^.t = trecord then recoff(tp^.recf, 0); { allocate entry }
         tp := tp^.next { next type entry }

      end;
      sp := sp^.next { next block }

   end

end;

{******************************************************************************

Set rlds

Resolves all rld entries, by finding their type addresses, and placing that
at the indicated program address. Needless to say, the entire types deck should
be address defined at this point.

******************************************************************************}

procedure setrlds;

var rp: rldptr; { relocation pointer }

begin

   rp := rldlst; { index 1st rld }
   while rp <> nil do begin { traverse list }

      case rp^.it of { insertion type }

         itadr: plcint(rp^.addr, rp^.lab^.addr); { place address }
         itdsp: plcint(rp^.addr, rp^.lab^.disp) { place address of display }

      end;

      { uncomment for relocation diagnostic }

      {

      case rp^.it of

         itadr: writeln('addr: ', rp^.addr:10, ' value: ', rp^.lab^.addr:10);
         itdsp: writeln('addr: ', rp^.addr:10, ' value: ', rp^.lab^.disp:10)

      end;

      }

      rp := rp^.next { next rld entry }

   end

end;

{******************************************************************************

List instruction

Lists the internal code instruction at the given address.

******************************************************************************}

procedure listins(var addr: meminx);

var c: opcod; { opcode holder }

{ print encoded integer and advance }

procedure prtint;

var i: integer;

begin

   i := getint(addr); { get the integer }
   addr := addr+4; { advance to next }
   write(i:1) { output }

end;

{ print encoded real and advance }

procedure prtrl;

var r: real;

begin

   r := getrl(addr); { get the integer }
   addr := addr+relsiz; { advance to next }
   write(r:1:1) { output }

end;

{ print immediate string }

procedure prtstr;

var sl: byte;
    si: byte;

begin

   write('''');
   sl := memory[addr]; { get length }
   addr := addr+1; { next }
   { print string }
   for si := 1 to sl do begin

      write(chr(memory[addr]));
      addr := addr+1 { next }

   end;
   write('''')

end;

begin

   write(addr:6, ': ');
   c := opcod(memory[addr]); { get opcode }
   addr := addr+1; { next }
   case c of { opcode }

      opstkoff:    begin write('stkoff    '); prtint end;
      oplodcloc:   begin write('lodcloc   '); prtint end;
      oplodaloc:   begin write('lodaloc   '); prtint; write(','); prtint end;
      oprngchk:    begin write('rngchk    '); prtint; write(','); prtint end;
      opindint:    write('indint    ');
      opindrl:     write('indrl     ');
      opindsrl:    write('indsrl    ');
      opindset:    write('indset    ');
      opindchr:    write('indchr    ');
      opindstr:    begin write('indstr    '); prtint end;
      oplodiint:   begin write('lodiint   '); prtint end;
      oplodirl:    begin write('lodirl    '); prtrl end;
      oplodins:    write('lodins    ');
      opnotint:    write('notint    ');
      opnotbol:    write('notbol    ');
      opsetsin:    write('setsin    ');
      opsetrng:    write('setrng    ');
      opcvtitr:    write('cvtitr    ');
      opcvtfix:    begin write('cvtfix    '); prtint end;
      opcvttag:    begin write('cvttag    '); prtint end;
      opsetint:    write('setint    ');
      opmltrl:     write('mltrl     ');
      opmltint:    write('mltint    ');
      opdivrl:     write('divrl     ');
      opdivint:    write('divint    ');
      opmodint:    write('modint    ');
      opandint:    write('andint    ');
      opnegint:    write('negint    ');
      opnegrl:     write('negrl     ');
      opsetuni:    write('setuni    ');
      opaddrl:     write('addrl     ');
      opaddint:    write('addint    ');
      opsetdif:    write('setdif    ');
      opsubrl:     write('subrl     ');
      opsubint:    write('subint    ');
      oporint:     write('orint     ');
      opxorint:    write('xorint    ');
      opsetin:     write('setin     ');
      opequset:    write('equset    ');
      opequrl:     write('equrl     ');
      opequstr:    begin write('equstr    '); prtint end;
      opequgst:    write('equgst    ');
      opequint:    write('equint    ');
      opequtgp:    write('equtgp    ');
      opltnrl:     write('ltnrl     ');
      opltnstr:    begin write('ltnstr    '); prtint end;
      opltngst:    write('ltngst    ');
      opltnint:    write('ltnint    ');
      opgtnrl:     write('gtnrl     ');
      opgtnstr:    begin write('gtnstr    '); prtint end;
      opgtngst:    write('gtngst    ');
      opgtnint:    write('gtnint    ');
      opleqset:    write('leqset    ');
      opgeqset:    write('geqset    ');
      opjmp:       begin write('jmp       '); prtint end;
      opjpf:       begin write('jpf       '); prtint end;
      opjpt:       begin write('jpt       '); prtint end;
      opduptop:    write('duptop    ');
      oppoptop:    write('poptop    ');
      opswprr:     write('swprr     ');
      opswpri:     write('swpri     ');
      opswpir:     write('swpir     ');
      opswpii:     write('swpii     ');
      opswpti:     write('swpti     ');
      opsucint:    write('sucint    ');
      opprdint:    write('prdint    ');
      opgoto:      begin write('goto      '); prtint; write(','); prtint end;
      opcall:      begin write('call      '); prtint end;
      opcalli:     write('calli     ');
      opret:       write('ret       ');
      opretoff:    begin write('retoff    '); prtint end;
      opwrtfil:    begin write('wrtfil    '); prtint end;
      opwrtbol:    write('wrtbol    ');
      opwrtgst:    write('wrtgst    ');
      opwrtintf:   write('wrtintf   ');
      opwrtchrf:   write('wrtchrf   ');
      opwrtbolf:   write('wrtbolf   ');
      opwrtrlf:    write('wrtrlf    ');
      opwrtstrf:   begin write('wrtstrf   '); prtint end;
      opwrtgstf:   write('wrtgstf   ');
      opwrtrlff:   write('wrtrlff   ');
      opwrtfsrl:   write('wrtfsrl   ');
      opwrtfrl:    write('wrtfrl    ');
      opwrtfset:   write('wrtfset   ');
      opwrtfchr:   write('wrtfchr   ');
      opwrtfint:   write('wrtfint   ');
      opwrteoln:   write('wrteoln   ');
      oprdfil:     begin write('rdfil     '); prtint end;
      oprdint:     write('rdint     ');
      oprdchr:     write('rdchr     ');
      oprdrl:      write('rdrl      ');
      oprdsrl:     write('rdsrl     ');
      oprdeoln:    write('rdeoln    ');
      opabsrl:     write('absrl     ');
      opabsint:    write('absint    ');
      opsqrrl:     write('sqrrl     ');
      opsqrint:    write('sqrint    ');
      opatnrl:     write('atnrl     ');
      opcosrl:     write('cosrl     ');
      opexprl:     write('exprl     ');
      oplnrl:      write('lnrl      ');
      opsinrl:     write('sinrl     ');
      opsqtrl:     write('sqtrl     ');
      opeoln:      write('eoln      ');
      opeof:       write('eof       ');
      opodd:       write('odd       ');
      oprnd:       write('rnd       ');
      optrc:       write('trc       ');
      opexist:     write('exist     ');
      oplen:       write('len       ');
      oploc:       write('loc       ');
      opget:       write('get       ');
      opgett:      write('gett      ');
      opput:       write('put       ');
      oplodafbuf:  write('lodafbuf  ');
      oplodafbuft: write('lodafbuft ');
      opreset:     begin write('reset     '); prtint end;
      opresett:    begin write('resett    '); prtint end;
      oprewrite:   begin write('rewrite   '); prtint end;
      oprewritet:  begin write('rewritet  '); prtint end;
      opclose:     write('close     ');
      oppage:      write('page      ');
      opassign:    write('assign    ');
      oppos:       write('pos       ');
      opdel:       write('del       ');
      opchg:       write('chg       ');
      opstosrl:    write('stosrl    ');
      opstorl:     write('storl     ');
      opstoi:      write('stoi      ');
      opstochr:    write('stochr    ');
      opstoset:    write('stoset    ');
      opstostr:    begin write('stostr    '); prtint end;
      opstogar:    begin write('stogar    '); prtint end;
      opstotgp:    write('stotgp    ');
      opnew:       begin write('new       '); prtint end;
      opdisp:      begin write('disp      '); prtint end;
      opstostk:    begin write('stostk    '); prtint end;
      opnewgar:    begin write('newgar    '); prtint end;
      opdspgar:    begin write('dspgar    '); prtint end;
      oparfgar:    begin write('arfgar    '); prtint end;
      opexit:      write('exit      ');

   end;
   writeln

end;

{******************************************************************************

List program code

Lists the program internal code in symbolic form. Takes a begin and end range.

******************************************************************************}

procedure listcode(sa, ea: meminx); { range }

begin

   while sa <= ea do listins(sa) { list code }

end;

{******************************************************************************

List constant space

Dumps the characters in the constant space.

******************************************************************************}

procedure dumpcon;

var i:      meminx;
    bytcnt: 0..60;

begin

   i := pgmend+1; { index start of constants }
   bytcnt := 0; { clear byte count }
   while i <= conend do begin { print }

      if bytcnt = 0 then write(i:6, ': '); { print line header }
      { if control, print '\', else print character }
      if memory[i] < ord(' ') then write('\\') else write(chr(memory[i]));
      bytcnt := bytcnt+1; { next character }
      i := i+1;
      if bytcnt = 60 then begin { end of line }

         writeln; { next line }
         bytcnt := 0 { clear count }

      end

   end;
   if bytcnt <> 0 then writeln { terminate last line }

end;

{******************************************************************************

Check stack valid

Checks if either the stack of heap has overflowed or underflowed. Since the
stack and the heap grown towards each other, we simply check to see if they
have met, including a "pad" that gives room to process expressions on the
stack.

******************************************************************************}

procedure stkchk;

begin

   if stack > maxmem+1 then error(estkovf); { stack underflow }
   if stack < heap+stkpad then error(estkovf) { stack overflow }

end;

{******************************************************************************

Make file entry

Indexes a present file entry or creates a new one. If the file number passed
is 0, then a new file entry is created, and the parameters cleared. Otherwise,
the matching entry for the file is returned, and the file number set to the
associated logical file number.

******************************************************************************}

procedure makfil(var fp: filpnt; { file entry }
                 var fn: byte); { memory pointer to file }

var fi: 1..maxopn; { index for files table }
    ff: 0..maxopn; { found file entry }
    ni: filinx;    { index for filename }
    
begin

   if fn = 0 then begin { there is no file, make one }

      { find empty file slot }
      ff := 0; { clear found file }
      for fi := 1 to maxopn do if opnfil[fi] = nil then ff := fi;
      if ff = 0 then error(eftbful); { file table full }
      new(opnfil[ff]); { create a new file entry }
      { note that file entries are never removed in this version }
      fp := opnfil[ff]; { index that }
      { clear the entries }
      fp^.mode := fmund; { set undefined }
      fp^.com := false; { set not command line file }
      fp^.rlen := 0; { record size unknown }
      for ni := 1 to maxfil do fp^.nam[ni] := ' '; { clear filename }
      fp^.buf := 0; { set no file buffer defined }
      fp^.full := false; { set nothing in buffer }
      fp^.typ := ftbin; { we don't know, just set }
      fn := ff { set file id number }

   end else fp := opnfil[fn] { return existing file record }

end;

{******************************************************************************

Reset file

Processes a reset on a file. If the file is already open, it is simply reset,
and the mode changed to read. Otherwise, the file is opened by name, set to
read, and a buffer allocated for it as required. If the file has no assigned
name, it is given a temp name.

******************************************************************************}

procedure resfil(fp: filpnt); { file record }

begin

   if fp^.mode <> fmund then begin { file is already open, just reset }

      if fp^.typ = ftbin then reset(fp^.bfil) { reset binary file }
      else reset(fp^.tfil); { reset text file }
      fp^.mode := fmread { place in read mode }

   end else begin { file not open }

      { check and flag if its the command file }
      if compp(fp^.nam, '_command') then fp^.com := true;
      { check file is command line file, and not single byte elements }
      if fp^.com and (fp^.rlen <> 1) then error(esyslen); { invalid length }
      if not fp^.com then begin { standard file }

         if fp^.typ = ftbin then begin { open binary }

            assign(fp^.bfil, fp^.nam); { set name }
            reset(fp^.bfil) { reset it }

         end else begin { open text }

            assign(fp^.tfil, fp^.nam); { set name }
            reset(fp^.tfil) { reset it }

         end;
         fp^.mode := fmread; { set in read mode }
         if fp^.buf = 0 then begin { no buffer, allocate }

            fp^.buf := heap; { place on heap }
            heap := heap+fp^.rlen; { allocate }
            stkchk { check heap overflow }

         end

      end else fp^.mode := fmread { set in read mode }

   end;
   fp^.full := false { set no data in buffer }

end;

{******************************************************************************

Rewrite file

Processes a rewrite on a file. If the file is already open, it is simply
rewritten, and the mode changed to write. Otherwise, the file is opened by name,
set to write, and a buffer allocated for it as required. If the file has no
assigned name, it is given a temp name.

******************************************************************************}

procedure rewfil(fp: filpnt); { file record }

begin

   if fp^.mode <> fmund then begin { file is already open, just rewrite }

      if fp^.typ = ftbin then rewrite(fp^.bfil) { rewrite binary }
      else rewrite(fp^.tfil); { rewrite text }
      fp^.mode := fmwrite { place in write mode }

   end else begin { file not open }

      { check and flag if its the command file }
      if compp(fp^.nam, '_command') then fp^.com := true;
      if fp^.com then error(esysrdo); { file is read only }
      if fp^.typ = ftbin then begin

         assign(fp^.bfil, fp^.nam); { set name }
         rewrite(fp^.bfil) { rewrite it }

      end else begin

         assign(fp^.tfil, fp^.nam); { set name }
         rewrite(fp^.tfil) { rewrite it }

      end;
      fp^.mode := fmwrite; { set in read mode }
      if fp^.buf = 0 then begin { no buffer, allocate }

         fp^.buf := heap; { place on heap }
         heap := heap+fp^.rlen; { allocate }
         stkchk { check heap overflow }

      end

   end

end;

{******************************************************************************

Close file

Processes a close on the file. It is an error to close an unopened file. The
file is closed. For now, the file is simply set back to undefined and it's name
cleared again, which is identical to it's status as originally created.
Close could also remove the entry and return it's storage. This would force it
to be reallocated if opened again, but would keep resources cleaner.

******************************************************************************}

procedure clsfil(fp: filpnt); { file to close }

var ni: filinx;    { index for filename }

begin

   if fp^.mode = fmund then error(efilnop); { file not open }
   { close the file }
   if fp^.typ = ftbin then close(fp^.bfil) else close(fp^.tfil);
   { for now, we leave the entry set up and undefined, with no name. Another
     behavior is to remove the file entry completely, and reset it back to
     an undefined id. This would force it to reallocate if opened again,
     but would keep resources cleaner }
   fp^.mode := fmund; { set file now undefined }
   fp^.com := false; { set not command line file }
   for ni := 1 to maxfil do fp^.nam[ni] := ' '; { clear filename }
   fp^.full := false { clear buffer }

end;

{******************************************************************************

Write real

Writes a real, in binary form, to the binary file.

******************************************************************************}

procedure wrtrl(var f: bytfil; { file to write }
                    r: real);  { real to write }

var c: record case boolean of { convertion }

          false: (r: real); { real form }
          true:  (b: packed array[1..relsiz] of byte); { byte format }

       end;
    bi: 1..relsiz; { index for convertion array }  

begin

   c.r := r; { place real }
   { write byte equivalent }
   for bi := 1 to relsiz do write(f, c.b[bi])

end;

{******************************************************************************

Write short real

Writes a short real, in binary form, to the binary file.

******************************************************************************}

procedure wrtsrl(var f: bytfil; { file to write }
                     r: real);  { real to write }

var c: record case boolean of { convertion }

          false: (r: sreal); { 32 bit real form }
          true:  (b: packed array[1..srlsiz] of byte); { byte format }

       end;
    bi: 1..srlsiz; { index for convertion array }  

begin

   c.r := r; { place short real }
   { write byte equivalent }
   for bi := 1 to srlsiz do write(f, c.b[bi])

end;

{******************************************************************************

Write integer

Writes an integer, in binary form, to the binary file.

******************************************************************************}

procedure wrtint(var f: bytfil;   { file to write }
                     i: integer); { real to write }

var c: record case boolean of { convertion }

          false: (i: integer); { 32 bit integer form }
          true:  (b: packed array[1..intsiz] of byte); { byte format }

       end;
    bi: 1..intsiz; { index for convertion array }  

begin

   c.i := i; { place short real }
   { write byte equivalent }
   for bi := 1 to intsiz do write(f, c.b[bi])

end;

{******************************************************************************

Check next command line character

Returns the next command line character in file mode. If the end of the command
line is reached, a cr and lf are output.

******************************************************************************}

function chkcom: char;

var c: char;

begin

   if not endlin(cmdhan) then c := chkchr(cmdhan) { return next character }
   else if not crsent then c := chr(13) { return cr }
   else if not lfsent then c := chr(10) { return lf }
   else c := ' '; { return blank (actually undefined) }

   chkcom := c { return character }

end;

{******************************************************************************

Check command line eoln

Checks if the end of line is reached in the command file.

******************************************************************************}

function eolcom: boolean;

begin

   eolcom := endlin(cmdhan) { set eol status }

end;

{******************************************************************************

Check command line eof

Checks if the end of file is reached in the command file.

******************************************************************************}

function eofcom: boolean;

begin

   eofcom := lfsent { true if the line feed was sent (single line) }

end;

{******************************************************************************

Get next command line character

Advances the command line state to the next character.

******************************************************************************}

procedure getcom;

begin

   if not eolcom then getchr(cmdhan) { if not end, advance pointer }
   else if not crsent then crsent := true { if not cr sent, flag that }
   else if not lfsent then lfsent := true { if not lf sent, flag that }

end;

{******************************************************************************

Execute program

This is the interpreter loop. The program is interpreted at the pgmcnt address.
It will not terminate until an end or error condition occurs.

******************************************************************************}

procedure execute;

var a, b, c, d, e, i: integer;
    ra, rb:           real;
    fn, fnb:          filnam;
    ca:               char;
    bt:               byte;
    oc:               opcod;
    fp:               filpnt;
    ins:              meminx;

{ get immediate integer }

procedure getiint(var i: integer);

begin

   i := getint(pgmcnt); { get the integer }
   pgmcnt := pgmcnt+intsiz { next }

end;

{ get immediate real }

procedure getirl(var r: real);

begin

   r := getrl(pgmcnt); { get the integer }
   pgmcnt := pgmcnt+relsiz { next }

end;

{ push integer to stack }

procedure push(i: integer);

begin

   stack := stack-intsiz; { allocate integer }
   plcint(stack, i) { place integer }

end;

{ push real to stack }

procedure pushr(r: real);

begin

   stack := stack-relsiz; { allocate real }
   plcrl(stack, r) { place real }

end;

{ pop integer from stack }

procedure pop(var i: integer);

begin

   i := getint(stack); { get top integer }
   stack := stack+intsiz { remove operand from stack }

end;

{ pop real from stack }

procedure popr(var r: real);

begin

   r := getrl(stack); { get top integer }
   stack := stack+relsiz { remove operand from stack }

end;

{ set element. Set on stack }

procedure setelm(e: integer);

var a: integer;

begin

   if (e < 0) or (e > 255) then error(einvelm); { invalid set element }
   a := stack+e div 8; { find byte address }
   case e mod 8 of { bit }

      0: memory[a] := memory[a]+$01;
      1: memory[a] := memory[a]+$02;
      2: memory[a] := memory[a]+$04;
      3: memory[a] := memory[a]+$08;
      4: memory[a] := memory[a]+$10;
      5: memory[a] := memory[a]+$20;
      6: memory[a] := memory[a]+$40;
      7: memory[a] := memory[a]+$80

   end

end;

{ set inclusion. Set on stack }

function setinc(e: integer): boolean;   

var a: integer;
    t: boolean;

begin

   if (e < 0) or (e > 255) then error(einvelm); { invalid set element }
   a := stack+e div 8; { find byte address }
   case e mod 8 of { bit }

      0: t := memory[a] and $01 <> 0;
      1: t := memory[a] and $02 <> 0;
      2: t := memory[a] and $04 <> 0;
      3: t := memory[a] and $08 <> 0;
      4: t := memory[a] and $10 <> 0;
      5: t := memory[a] and $20 <> 0;
      6: t := memory[a] and $40 <> 0;
      7: t := memory[a] and $80 <> 0

   end;
   setinc := t { return result }

end;

begin

   repeat { execute instructions }

{ uncomment this to get a program trace }
{ write(pgmcnt:6, ':', stack:6, ':'); ins := pgmcnt; listins(ins); }

      oc := opcod(memory[pgmcnt]); { get opcode }
      pgmcnt := pgmcnt+1; { next }
      case oc of { opcode }

         opstkoff:   begin getiint(a); stack := stack+a; stkchk end;
         oplodcloc:  begin getiint(a); push(getint(stack+a)) end;
         oplodaloc:  begin getiint(a); getiint(b); push(getint(a)+b) end;
         oprngchk:   begin getiint(a); getiint(b); c := getint(stack);
                           if (c < a) or (c > b) then error(erngchk) end; 
         opindint:   begin pop(a); push(getint(a)) end; 
         opindrl:    begin pop(a); pushr(getrl(a)) end; 
         opindsrl:   begin pop(a); pushr(getsrl(a)) end; 
         opindset:   begin pop(a); stack := stack-setsiz;
                           for i := 1 to setsiz do 
                              memory[stack+i-1] := memory[a+i-1] end;
         opindchr:   begin pop(a); push(memory[a]) end; 
         opindstr:   begin getiint(a); pop(b); stack := stack-a; stkchk;
                           for i := 1 to a do 
                              memory[stack+i-1] := memory[b+i-1] end;
         oplodiint:  begin getiint(a); push(a) end; 
         oplodirl:   begin getirl(ra); pushr(ra) end;
         oplodins:   begin stack := stack-setsiz; stkchk;
                           for i := 1 to setsiz do memory[stack+i-1] := 0 end;
         opnotint:   begin pop(a); push(not a) end; 
         opnotbol:   begin pop(a); push(ord(a = 0)) end;
         opsetsin:   begin pop(a); setelm(a) end;
         opsetrng:   begin pop(a); pop(b); for i := b to a do setelm(i) end; 
         opcvtitr:   begin pop(a); pushr(a) end;
         opcvtfix:   begin getiint(a); pop(b); pop(c); 
                           if a <> c then error(elenmat); push(b) end;
         opcvttag:   begin getiint(a); pop(b); push(a); push(b) end;
         opsetint:   begin for i := 1 to setsiz do 
                              memory[stack+setsiz+i-1] := 
                                 memory[stack+setsiz+i-1] and 
                                 memory[stack+i-1];
                           stack := stack+setsiz end;
         opmltrl:    begin popr(ra); popr(rb); pushr(ra*rb) end; 
         opmltint:   begin pop(a); pop(b); push(a*b) end; 
         opdivrl:    begin popr(ra); popr(rb); pushr(rb/ra) end; 
         opdivint:   begin pop(a); pop(b); if a = 0 then error(edivzer); 
                           push(b div a) end; 
         opmodint:   begin pop(a); pop(b); push(b mod a) end; 
         opandint:   begin pop(a); pop(b); push(a and b) end; 
         opnegint:   begin pop(a); push(-a) end; 
         opnegrl:    begin popr(ra); pushr(-ra) end; 
         opsetuni:   begin for i := 1 to setsiz do 
                              memory[stack+setsiz+i-1] := 
                                 memory[stack+setsiz+i-1] or memory[stack+i-1];
                           stack := stack+setsiz end;
         opaddrl:    begin popr(ra); popr(rb); pushr(ra+rb) end; 
         opaddint:   begin pop(a); pop(b); push(a+b) end; 
         opsetdif:   begin for i := 1 to setsiz do 
                              begin a := memory[stack+setsiz+i-1]; 
                                    b := memory[stack+i-1]; 
                                    memory[stack+setsiz+i-1] := 
                                       ((a or b) and not (a and b)) and a end;
                           stack := stack+setsiz end;
         opsubrl:    begin popr(ra); popr(rb); pushr(rb-ra) end; 
         opsubint:   begin pop(a); pop(b); push(b-a) end;
         oporint:    begin pop(a); pop(b); push(b or a) end;
         opxorint:   begin pop(a); pop(b); 
                           push((b or a) and not (b and a)) end;
         opsetin:    begin a := getint(stack+setsiz); 
                           if setinc(a) then a := 1 else a := 0;
                           stack := stack+setsiz+intsiz; push(a) end;
         opequset:   begin a := 1; for i := 1 to setsiz do 
                              if memory[stack+setsiz+i-1] <> 
                                 memory[stack+i-1] then a := 0;
                           stack := stack+(setsiz*2); push(a) end;
         opequrl:    begin popr(ra); popr(rb); push(ord(ra = rb)) end;
         opequstr:   begin getiint(a); pop(b); pop(c); d := 1;
                           for i := 1 to a do 
                              if memory[b+i-1] <> memory[c+i-1] then d := 0;
                           push(d) end;
         opequgst:   begin pop(a); pop(b); pop(c); pop(d); e := 1;
                           if b <> d then error(elenmat);
                           for i := 1 to b do 
                              if memory[a+i-1] <> memory[c+i-1] then e := 0;
                           push(e) end;
         opequint:   begin pop(a); pop(b); push(ord(a = b)) end; 
         opequtgp:   begin pop(a); pop(b); pop(c); pop(d);
                           push(ord(a = c)) end;
         opltnrl:    begin popr(ra); popr(rb); push(ord(rb < ra)) end;
         opltnstr:   begin getiint(a); pop(b); pop(c); d := 0;
                           for i := 1 to a do 
                              if (memory[b+i-1] <> memory[c+i-1]) and 
                                 (d = 0) then d := i; 
                           if d <> 0 then 
                              d := ord(memory[c+d-1] < memory[b+d-1]); 
                           push(d) end;
         opltngst:   begin pop(a); pop(b); pop(c); pop(d); e := 0;
                           if b <> d then error(elenmat);
                           for i := 1 to b do 
                              if (memory[a+i-1] <> memory[c+i-1]) and
                                 (e = 0) then e := i; 
                           if e <> 0 then 
                              e := ord(memory[c+e-1] < memory[a+e-1]); 
                           push(e) end;
         opltnint:   begin pop(a); pop(b); push(ord(b < a)) end;
         opgtnrl:    begin popr(ra); popr(rb); push(ord(rb > ra)) end;
         opgtnstr:   begin getiint(a); pop(b); pop(c); d := 0;
                           for i := 1 to a do 
                              if (memory[b+i-1] <> memory[c+i-1]) and
                                 (d = 0) then d := i; 
                           if d <> 0 then 
                              d := ord(memory[c+d-1] > memory[b+d-1]); 
                           push(d) end;
         opgtngst:   begin pop(a); pop(b); pop(c); pop(d); e := 0;
                           if b <> d then error(elenmat);
                           for i := 1 to b do 
                              if (memory[a+i-1] <> memory[c+i-1]) and
                                 (e = 0) then e := i; 
                           if e <> 0 then 
                              e := ord(memory[c+e-1] > memory[a+e-1]); 
                           push(e) end;
         opgtnint:   begin pop(a); pop(b); push(ord(b > a)) end;
         opleqset:   begin a := 1; for i := 1 to setsiz do 
                              if memory[stack+setsiz+i-1] <> 
                                 (memory[stack+i-1] and 
                                  memory[stack+setsiz+i-1]) then a := 0;
                           stack := stack+(setsiz*2); push(a) end;
         opgeqset:   begin a := 1; for i := 1 to setsiz do 
                              if memory[stack+i-1] <> 
                                 (memory[stack+i-1] and 
                                  memory[stack+setsiz+i-1]) then a := 0;
                           stack := stack+(setsiz*2); push(a) end;
         opjmp:      begin getiint(a); pgmcnt := a end;
         opjpf:      begin getiint(a); pop(b); if b = 0 then pgmcnt := a end; 
         opjpt:      begin getiint(a); pop(b); if b <> 0 then pgmcnt := a end; 
         opduptop:   begin pop(a); push(a); push(a) end; 
         oppoptop:   stack := stack+stksiz; 
         opswprr:    begin popr(ra); popr(rb); pushr(ra); pushr(rb) end;
         opswpri:    begin pop(a); popr(rb); push(a); pushr(rb) end;
         opswpir:    begin popr(ra); pop(b); pushr(ra); push(b) end;
         opswpii:    begin pop(a); pop(b); push(a); push(b) end;
         opswpti:    begin pop(a); pop(b); pop(c); push(a); push(c); push(b) end;
         opsucint:   begin pop(a); push(succ(a)) end; 
         opprdint:   begin pop(a); push(pred(a)) end; 
         opgoto:     begin getiint(a); getiint(b); stack := getint(a);
                           pgmcnt := b end;
         opcall:     begin getiint(a); push(pgmcnt); pgmcnt := a end; 
         opcalli:    begin pop(a); push(pgmcnt); pgmcnt := a end; 
         opret:      begin pop(a); pgmcnt := a end;
         opretoff:   begin getiint(a); pop(b); stack := stack+a; 
                           pgmcnt := b end;
         opwrtfil:   begin getiint(a); pop(b); pop(c); push(c); 
                           makfil(fp, memory[c]); 
                           if fp^.mode <> fmwrite then error(efilmod);
                           for i := 1 to a do write(fp^.bfil, memory[b+i-1]) 
                     end;
         opwrtbol:   begin pop(a); pop(b); push(b); makfil(fp, memory[b]); 
                           if fp^.mode <> fmwrite then error(efilmod);
                           write(fp^.tfil, a <> 0) end; 
         opwrtgst:   begin pop(a); pop(b); pop(c); push(c);
                           makfil(fp, memory[c]);
                           if fp^.mode <> fmwrite then error(efilmod);
                           for i := 1 to b do 
                              write(fp^.tfil, chr(memory[a+i-1])) end;
         opwrtintf:  begin pop(a); pop(b); pop(c); push(c); 
                           makfil(fp, memory[c]);
                           if fp^.mode <> fmwrite then error(efilmod);
                           write(fp^.tfil, b:a) end;
         opwrtchrf:  begin pop(a); pop(b); pop(c); push(c); 
                           makfil(fp, memory[c]);
                           if fp^.mode <> fmwrite then error(efilmod);
                           write(fp^.tfil, chr(b):a) end;
         opwrtbolf:  begin pop(a); pop(b); pop(c); push(c); 
                           makfil(fp, memory[c]);
                           if fp^.mode <> fmwrite then error(efilmod);
                           write(fp^.tfil, b <> 0:a) end;
         opwrtrlf:   begin pop(a); popr(rb); pop(c); push(c); 
                           makfil(fp, memory[c]);
                           if fp^.mode <> fmwrite then error(efilmod);
                           write(fp^.tfil, rb:a) end;
         { nothing is for free. Ya gotta do string outputs yourself }
         opwrtstrf:  begin getiint(a); pop(b); pop(c); pop(d); push(d);
                           makfil(fp, memory[d]);
                           if fp^.mode <> fmwrite then error(efilmod);
                           if b > a then { pad }
                              for i := 1 to b-a do write(fp^.tfil, ' ');
                           if b < a then a := b; { truncate }
                           for i := 1 to a do 
                              write(fp^.tfil, chr(memory[c+i-1])) end;
         opwrtgstf:  begin pop(a); pop(b); pop(c); pop(d); push(d);
                           makfil(fp, memory[d]);
                           if fp^.mode <> fmwrite then error(efilmod);
                           if a > c then { pad }
                              for i := 1 to a-c do write(fp^.tfil, ' ');
                           if a < c then c := a; { truncate }
                           for i := 1 to c do 
                              write(fp^.tfil, chr(memory[b+i-1])) end;
         opwrtrlff:  begin pop(a); pop(b); popr(ra); pop(d); push(d);
                           makfil(fp, memory[d]);
                           if fp^.mode <> fmwrite then error(efilmod);
                           write(fp^.tfil, ra:b:a) end; 
         opwrtfsrl:  begin popr(ra); pop(b); push(b); makfil(fp, memory[b]);
                           if fp^.mode <> fmwrite then error(efilmod);
                           wrtsrl(fp^.bfil, ra) end;
         opwrtfrl:   begin popr(ra); pop(b); push(b); makfil(fp, memory[b]);
                           if fp^.mode <> fmwrite then error(efilmod);
                           wrtrl(fp^.bfil, ra) end;
         opwrtfset:  begin pop(a); pop(b); push(b); makfil(fp, memory[b]);
                           if fp^.mode <> fmwrite then error(efilmod);
                           for i := 1 to setsiz do 
                              write(fp^.bfil, memory[a+i-1]) end;
         opwrtfchr:  begin pop(a); pop(b); push(b); makfil(fp, memory[b]);
                           if fp^.mode <> fmwrite then error(efilmod);
                           write(fp^.bfil, a) end;
         opwrtfint:  begin pop(a); pop(b); push(b); makfil(fp, memory[b]);
                           if fp^.mode <> fmwrite then error(efilmod);
                           wrtint(fp^.bfil, a) end;
         opwrteoln:  begin pop(a); push(a); makfil(fp, memory[a]);
                           if fp^.mode <> fmwrite then error(efilmod);
                           writeln(fp^.tfil) end;
         oprdfil:    begin getiint(a); pop(b); pop(c); push(c); 
                           makfil(fp, memory[c]);
                           if fp^.mode <> fmread then error(efilmod);
                           if fp^.com then { command file }
                              begin memory[b] := ord(chkcom); getcom end
                           else begin

                              if fp^.full then begin { there is buffer data }

                                 for i := 1 to a do { copy from buffer }
                                    memory[b+i-1] := memory[fp^.buf+i-1];
                                 fp^.full := false { set buffer empty }

                              end else for i := 1 to a do 
                                 read(fp^.bfil, memory[b+i-1])

                           end
                     end;
         oprdint:    begin pop(a); pop(b); push(b); makfil(fp, memory[b]);
                           if fp^.mode <> fmread then error(efilmod);
                           read(fp^.tfil, c); plcint(a, c) end;
         oprdchr:    begin pop(a); pop(b); push(b); makfil(fp, memory[b]);
                           if fp^.mode <> fmread then error(efilmod);
                           if fp^.com then { command file }
                              begin memory[a] := ord(chkcom); getcom end
                           else begin read(fp^.tfil, ca); 
                                      memory[a] := ord(ca) end
                     end;
         oprdrl:     begin pop(a); pop(b); push(b); makfil(fp, memory[b]);
                           if fp^.mode <> fmread then error(efilmod);
                           read(fp^.tfil, ra); plcrl(a, ra) end;
         oprdsrl:    begin pop(a); pop(b); push(b); makfil(fp, memory[b]);
                           if fp^.mode <> fmread then error(efilmod);
                           read(fp^.tfil, ra); plcsrl(a, ra) end;
         oprdeoln:   begin pop(a); push(a); makfil(fp, memory[a]);
                           if fp^.mode <> fmread then error(efilmod);
                           if fp^.com then while not eolcom do getcom
                           else readln(fp^.tfil) 
                     end;
         opabsrl:    begin popr(ra); pushr(abs(ra)) end; 
         opabsint:   begin pop(a); push(abs(a)) end; 
         opsqrrl:    begin popr(ra); pushr(sqr(ra)) end; 
         opsqrint:   begin pop(a); push(sqr(a)) end; 
         opatnrl:    begin popr(ra); pushr(arctan(ra)) end; 
         opcosrl:    begin popr(ra); pushr(cos(ra)) end; 
         opexprl:    begin popr(ra); pushr(exp(ra)) end; 
         oplnrl:     begin popr(ra); pushr(ln(ra)) end; 
         opsinrl:    begin popr(ra); pushr(sin(ra)) end; 
         opsqtrl:    begin popr(ra); pushr(sqrt(ra)) end; 
         opeoln:     begin pop(a); makfil(fp, memory[a]);
                           if fp^.mode <> fmread then error(efilmod);
                           if fp^.com then push(ord(eolcom)) 
                           else push(ord(eoln(fp^.tfil)))
                     end;
         opeof:      begin pop(a); makfil(fp, memory[a]);
                           if fp^.mode = fmund then error(efilnop);
                           if fp^.com then push(ord(eofcom)) else begin

                              if fp^.typ = ftbin then push(ord(eof(fp^.bfil)))
                              else push(ord(eof(fp^.tfil)))

                           end
                     end;
         opodd:      begin pop(a); push(ord(odd(a))) end;
         oprnd:      begin popr(ra); push(round(ra)) end; 
         optrc:      begin popr(ra); push(trunc(ra)) end; 
         opexist:    begin pop(a); pop(b); 
                           for i := 1 to maxfil do fn[i] := ' ';
                           for i := 1 to b do fn[i] := chr(memory[a+i-1]);
                           push(ord(exists(fn))) end;
         oplen:      begin pop(a); makfil(fp, memory[a]); 
                           push(length(fp^.bfil))
                     end;
         oploc:      begin pop(a); makfil(fp, memory[a]); 
                           push(location(fp^.bfil))
                     end;
         opget:      begin pop(a); makfil(fp, memory[a]);
                           if fp^.mode <> fmread then error(efilmod);
                           if fp^.com then getcom
                           else begin

                              if fp^.full then 
                                 fp^.full := false { dump the buffer }
                              { otherwise just discard data }
                              else for i := 1 to fp^.rlen do 
                                 read(fp^.bfil, bt)

                           end
                     end;
         opgett:     begin pop(a); makfil(fp, memory[a]);
                           if fp^.mode <> fmread then error(efilmod); 
                           if fp^.com then getcom
                           else get(fp^.tfil) { let pascal handle it }

                     end;
         opput:      begin pop(a); makfil(fp, memory[a]);
                           if fp^.mode <> fmwrite then error(efilmod);
                           for i := 1 to fp^.rlen do 
                              write(fp^.bfil, memory[fp^.buf+i-1]) end;
         oplodafbuf: begin pop(a); makfil(fp, memory[a]); push(fp^.buf);
                           if fp^.mode = fmread then { load the buffer }
                           if fp^.com then memory[fp^.buf] := ord(chkcom)
                           else if not fp^.full then begin { no buffer data }

                              for i := 1 to a do { load buffer }
                                 read(fp^.bfil, memory[b+i-1]);
                              fp^.full := true { set buffer full }

                           end
                     end;
         { load buffer address for text is strange. We let Pascal do the work,
           but we still use the buffer to give the program something to point
           to }
         oplodafbuft: begin pop(a); makfil(fp, memory[a]); push(fp^.buf);
                           if fp^.mode = fmread then begin { load the buffer }

                              if fp^.com then memory[fp^.buf] := ord(chkcom)
                              else memory[fp^.buf] := ord(fp^.tfil^)

                           end
                     end;
         opreset:    begin getiint(a); pop(b); makfil(fp, memory[b]); 
                           fp^.rlen := a; 
                           if fp^.typ <> ftbin then fp^.typ := ftbin;
                           resfil(fp) end;
         opresett:   begin getiint(a); pop(b); makfil(fp, memory[b]);
                           fp^.rlen := a;
                           if fp^.typ <> fttxt then fp^.typ := fttxt;
                           resfil(fp) end;
         oprewrite:  begin getiint(a); pop(b); makfil(fp, memory[b]);
                           fp^.rlen := a;
                           if fp^.typ <> ftbin then fp^.typ := ftbin;
                           rewfil(fp) end;
         oprewritet: begin getiint(a); pop(b); makfil(fp, memory[b]);
                           fp^.rlen := a;
                           if fp^.typ <> fttxt then fp^.typ := fttxt;
                           rewfil(fp) end;
         opclose:    begin pop(a); makfil(fp, memory[a]); clsfil(fp) end;
         oppage:     begin pop(a); makfil(fp, memory[a]); 
                           if fp^.mode <> fmwrite then error(efilmod);
                           page(fp^.tfil) end;
         opassign:   begin pop(a); pop(b); pop(c); makfil(fp, memory[c]);
                           if fp^.mode <> fmund then error(efilopn);
                           if fp^.nam[1] <> ' ' then error(efilass);
                           for i := 1 to b do fp^.nam[i] := chr(memory[a+i-1])
                     end;
         oppos:      begin pop(a); pop(b); if a = 0 then error(einvpos);
                           makfil(fp, memory[b]); position(fp^.bfil, a); 
                           fp^.full := false end;
         opdel:      begin pop(a); pop(b); 
                           for i := 1 to maxfil do fn[i] := ' ';
                           for i := 1 to b do fn[i] := chr(memory[a+i-1]);
                           delete(fn) end;
         opchg:      begin pop(a); pop(b); pop(c); pop(d);
                           for i := 1 to maxfil do fn[i] := ' ';
                           for i := 1 to b do fn[i] := chr(memory[a+i-1]);
                           for i := 1 to maxfil do fnb[i] := ' ';
                           for i := 1 to d do fnb[i] := chr(memory[c+i-1]);
                           change(fnb, fn) end;
         opstosrl:   begin popr(ra); pop(a); plcsrl(a, ra) end;
         opstorl:    begin popr(ra); pop(a); plcrl(a, ra) end;
         opstoi:     begin pop(a); pop(b); plcint(b, a) end;
         opstochr:   begin pop(a); pop(b); memory[b] := a end;
         opstoset:   begin a := getint(stack+setsiz); 
                           for i := 1 to setsiz do 
                              memory[a+i-1] := memory[stack+i-1]; 
                           stack := stack+setsiz+intsiz end;
         opstostr:   begin getiint(a); pop(b); pop(c); 
                           for i := 1 to a do 
                              memory[c+i-1] := memory[b+i-1] end;
         opstogar:   begin getiint(a); pop(b); pop(c); pop(d); pop(e);
                           if c <> e then error(elenmat);
                           for i := 1 to c*a do 
                              memory[d+i-1] := memory[b+i-1] end;
         opstotgp:   begin pop(a); pop(b); pop(c); plcint(c, a);
                           plcint(c+intsiz, b) end;
         { The heap system uses an allocate only, no dispose model for 
           testing }
         opnew:      begin getiint(a); pop(b); plcint(b, heap); 
                           heap := heap+a; stkchk end;
         opdisp:     begin getiint(a); pop(b) end;
         opstostk:   begin getiint(a); plcint(a, stack) end;
         opnewgar:   begin getiint(a); pop(b); pop(c); plcint(c, heap);
                           if b < 1 then error(erngchk);
                           plcint(c+intsiz, b); heap := heap+a*b; stkchk end;
         opdspgar:   begin getiint(a); stack := stack+tgpsiz end;
         oparfgar:   begin getiint(a); pop(b); pop(c); pop(d);
                           if (b < 1) or (b > d) then error(erngchk);
                           push((b-1)*a+c) end;
         opexit:     { do nothing }

      end

   until oc = opexit { until terminator executed }

end;

begin

   writeln;
   write('IP intermediate simulator vs. 0.2 Copyright (C) 2004 ');
   writeln('Moore/CAD');
   writeln;

   { clear memory }
   for pgmcnt := 0 to maxmem do memory[pgmcnt] := 0;
   { clear files table }
   for ofi := 1 to maxopn do opnfil[ofi] := nil;
   { clear free types list }
   for fti := tudf to tlink do fretyp[fti] := nil;
   typstk := nil; { clear types stack }
   typlst := nil; { clear types list }
   pgmcnt := 0; { set program counter to start of memory }
   srtstk := nil; { clear structure tracking stack }
   srtfre := nil; { clear structure free entries list }
   rldlst := nil; { clear relocation entries list }
   gblint := nil; { global integer entry }
   gblchr := nil; { global character entry }
   gblreal := nil; { global real entry }
   tmpcnt := 1; { clear temporary files counter }
   crsent := false; { set no command line cr sent }
   lfsent := false; { set no command line lf sent }
   srclst := nil; { clear source equate list }
   cursrc := nil; { clear active source entry }
   linlst := nil; { clear the master line list }

   openpar(cmdhan); { open parser }
   openfil(cmdhan, '_command', cmdmax); { open command line level }
   filchr(valfch); { get the filename valid characters }
   setfch(cmdhan, valfch); { set that for active parsing }
   parcmd; { parse command line }
   { now the rest of the command line after the file and debugging options
     is available for the program to read }
   if isext(intnam) then begin { extention exists }

      if not exists(intnam) then error(efilnf) { no file }

   end else begin { no extention, try our own }

      addext(intnam, 'opt', true); { search for file.opt first }
      if not exists(intnam) then begin { not found }

         addext(intnam, 'int', true); { search for file.int }
         if not exists(intnam) then error(efilnf) { no such file }

      end

   end;
   write('Loading intermediate file: ');
   for fi := 1 to maxfil do if intnam[fi] <> ' ' then write(intnam[fi]);
   writeln;
   writeln;
   emit(opcall); { place program main call at the start of memory }
   emitint(0); { set 0, to be filled in when the program block is read }
   emit(opexit); { place simulator exit }
   loadint; { load intermediate file }
   srtlin; { sort the line equivalence table }
   pgmend := pgmcnt-1; { set end of program code }
   setconst; { place constants to memory }
   conend := pgmcnt-1; { set end of constants }
   setdisp; { place display }
   disend := pgmcnt-1; { set end of display }
   setrec; { locate record fields }
   setaddr; { locate variable types }
   setrlds; { activate rld deck }
   stack := maxmem; { set inital stack }
   heaps := pgmcnt; { set base of heap to end of all allocations }
   heap := heaps; { set inital heap to empty }
   pgmcnt := 0; { set program counter to start at 0 }

   { list internal form (diagnostic) }
{   writeln('Internal code:');
   writeln;
   listcode(0, pgmend);}

   { list constant space (diagnostic) }
{   writeln;
   writeln('Constant space:');
   writeln;
   dumpcon;}

   writeln;
   writeln('Program:   ', 0:8, '..', pgmend:8, ' ', pgmend+1:8);
   writeln('Constants: ', pgmend+1:8, '..', conend:8, ' ', conend-pgmend:8);
   writeln('Display:   ', conend+1:8, '..', disend:8, ' ', disend-conend:8);
   writeln('Globals:   ', disend+1:8, '..', heaps-1:8, ' ', (heaps-1)-disend:8);
   writeln('Heap:      ', heaps:8);
   writeln('stack:     ', stack:8);
   writeln;
   execute; { execute program at 0 }
   writeln;
   writeln('Function complete');

   99: { abort program }

end.
