{******************************************************************************
*                                                                             *
*                                    CE80386                                  *
*                                                                             *
*                       CHECK ENCODER FOR I80386 AND UP CPUS                  *
*                                                                             *
*                       Copyright (C) 1995 S. A. Moore                        *
*                                                                             *
*                              Written 10/95                                  *
*                                                                             *
* Encodes a Pascal intermediate. This is an extremely simple encode, and is   *
* in fact the machine analog of the passim portable simulator.                *
* The output is encoded in 80386 because that is the first 32 bit instruction *
* model processor in the series. There is no point in adding higher level     *
* instructions to this elementary encoder. This encoder will serve for all    *
* processors after the 80386.                                                 *
* Accepts a command line of the form:                                         *
*                                                                             *
*    ce80386 file=file [file]..                                               *
*                                                                             *
* If the given file has no extention, we search first for file.opt, then for  *
* file.int. Otherwise, the file is opened under the extention given.          *
* The encoder works by loading all the type entries in the intermediate to    *
* typing tables in memory. The entries are cross linked as they are loaded.   *
* Symbols are ignored in this version. Intermediate code is translated and    *
* output.                                                                     *
* As running, the program has the following layout:                           *
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
* The code works by using the stack to sequence all results. All operands are *
* loaded onto the stack, then for each intermediate, the operands are loaded  *
* from the stack to registers, the operation performed, and the result placed *
* back on the stack. Just as for passim, this allows a procedure/function     *
* call frame to be contructed automatically. It also means that each          *
* intemediate can have full use of the register set.                          *
* Bounds checking is provided for in many situations. Since this is not a     *
* speed oriented appliance, it generally cannot be turned off. It is,         *
* allowed off for stores and in-line bounds checks. The reason is that these  *
* operations will not crash the program if overflow occurs.                   *
*                                                                             *
******************************************************************************}

program ec80386(command, output);

uses stddef,
     strlib,
     extlib;

label 99; { abort simulator }

const

   maxfil  = 100;      { number of characters in a file name }
   maxlin  = 200;      { number of characters in a text line }
   intsiz  = 4;        { size of integer in bytes }
   rlsiz   = 8;        { size of real in bytes }
   srlsiz  = 4;        { size of short real in bytes }
   stksiz  = 4;        { size of stack element in bytes }
   setsiz  = 32;       { size of set in bytes }
   tgpsiz  = 8;        { size of tagged pointer }
   bolsiz  = 4;        { size of boolean (on stack) }
   intfld  = 11;       { output width of integer }
   blffld  = 5;        { output width of boolean false }
   bltfld  = 6;        { output width of boolean true }
   chrfld  = 1;        { output width of character }
   rlfld   = 22;       { output width of real }
   bytes   = 4;        { number of bytes in an integer }
   toppow  = 16777216; { maximum $01 byte in integer }
   maxlab  = 10;       { number of characters in label }
  
type

   filinx  = 1..maxfil; { index for file names }
   filnam  = packed array [filinx] of char; { a file name }
   lininx  = 1..maxlin;  { index for text line }
   linbuf  = packed array [lininx] of char; { a text line }
   labl    = packed array [1..maxlab] of char; { a standard label }
   ext     = packed array [1..3] of char; { filename extention }
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
             ilodadr,    { load address operator }
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
             icvtntg,    { convert nil to tagged format }
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
             ipage,      { page operator }
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
             ilodint,    { load direct integer }
             ilodrel,    { load direct real }
             ilodsrl,    { load direct short real }
             ilodset,    { load direct set }
             ilodchr,    { load direct character }
             ilodbol,    { load direct boolean }
             ilodsrc,    { load direct structure }
             ilodptr,    { load direct pointer }
             ilodtgp,    { load direct tagged pointer }
             igotot,     { goto on true }
             igotof,     { goto on false }
             istoint,    { store direct integer }
             istosrl,    { store direct short real }
             istorel,    { store direct real }
             istochr,    { store direct character }
             istobol,    { store direct boolean }
             istoset,    { store direct set }
             istosrc,    { store direct structure }
             istogar,    { store direct general array }
             istotgp,    { store direct tagged pointer }
             istofint,   { store direct function result integer }
             istoftgp,   { store direct function result tagged pointer }
             istofsrl,   { store direct function result short real }
             istofrel,   { store direct function result real }
             istofchr,   { store direct function result character }
             istofbol,   { store driect function result boolean }
             icvtrtsr);  { convert real to short real }
   { module marker codes }
   modmrk = (mmsystem,  { system }
             mmprogram, { program }
             mmmodule,  { module }
             mmprocess, { process }
             mmmonitor, { monitor }
             mmshare);  { share }
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
             tlink,    { linking entry }
             trot,     { pascal support routine }
             tpgm,     { program space marker entry }
             tvrs);    { variable space marker entry }
   typptr = ^typ; { type pointer }
   typ    = record { type entry }
            
               next:   typptr;  { next list entry }
               addr:   integer; { address of type }
               size:   integer; { size of type in bytes }
               local:  boolean; { what address space occupied }
               level:  integer; { block level }
               case t: types of { types }

                  tudf:     ();              { dummy entry to mark errors }
                  tnil:     ();              { 'nil' universal pointer }
                  tlab:     (lmrk: typptr);  { 'goto' label }
                  ticst:    (ival: integer); { the value of the integer }
                  tscst:    (sval: pstring); { the value of the string }
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
                             vare: boolean;  { variable is external }
                             varr: boolean); { variable was referenced }
                  tfix:     (fixt: typptr;   { base type }
                             fixc: typptr;   { constant fill }
                             fixe: boolean;  { fixed is external }
                             fixr: boolean); { fixed was referenced }
                  tproc:    (prcp: typptr;   { parameter list }
                             prcv: integer;  { total locals allocation }
                             prca: integer;  { total parameters allocation }
                             prce: boolean;  { procedure is external }
                             prcr: boolean); { procedure was referenced }
                  tfunc:    (fncp: typptr;   { parameter list }
                             fncr: typptr;   { function result }
                             fncv: integer;  { total locals allocation }
                             fnca: integer;  { total parameters allocation }
                             fnce: boolean;  { function is external }
                             fnct: boolean); { function was referenced }
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
                             ppra: integer;  { parameter allocation }
                             pprn: typptr);  { next parameter }
                  tpfunc:   (pfnp: typptr;   { parameter list }
                             pfnr: typptr;   { function result }     
                             pfna: integer;  { parameter allocation }      
                             pfnn: typptr);  { next parameter }
                  tinteger: ();              { integer }
                  tchar:    ();              { character }
                  tboolean: (bnc:  typptr);  { list of enumerated constants }
                  treal:    ();              { real }
                  tsreal:   ();              { short real }
                  ttext:    ();              { text file }
                  teset:    ();              { empty set }
                  tglbl:    (mm: modmrk;     { module type }
                             ds: typptr);    { display save }
                  tnull:    ();              { placeholder }
                  tfuncr:   (fnrt: typptr);  { base type }
                  tlink:    (lnkl: integer;  { linkage level }
                             lnke: integer); { linkage entry }
                  trot:     (rotr: boolean); { routine was referenced }
                  tpgm:     ();              { program space marker }
                  tvrs:     ();              { variable space marker }


               { end }

            end;
   typset = set of types; { set of types }
   { label type }
   labptr = ^labtyp;{ pointer to label } 
   labtyp = record { label entry }
   
      next: labptr;  { next label in list }
      lab:  pstring; { label string }
      exp:  boolean; { exportable flag }
      typ:  typptr   { associated type entry }

   end;
   tpsptr = ^tps; { pointer to type stack entry }
   tps    = record { type stack entry }

               next:  tpsptr;  { next entry }
               typ:   typptr;  { type list for block }
               lst:   typptr;  { last entry in type list }
               res:   typptr;  { next resolvable entry }
               typa:  typptr;  { alternate types list }
               lsta:  typptr;  { last entry in alternate type list }
               resa:  typptr;  { next resolvable alternate entry }
               mark:  typptr;  { mark for block }
               marks: labptr;  { mark symbol }
               prnt:  tpsptr;  { parent block }
               lvl:   integer; { level number }
               loc:   boolean; { locals allocated for block }
               sym:   labptr   { symbols list }

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
   ityp   = (itadr,    { address }
             itradr,   { relative address }
             itbradr); { byte relative address }
   rldptr = ^rld; { relocation entry pointer }
   rld    = record { relocation entry }

               next: rldptr;  { next entry }      
               addr: integer; { address to patch in memory }
               lab:  typptr;  { entry to patch with }
               it:   ityp ;   { insertion type }
               out:  boolean  { entry has been output }

            end;
   { runtime errors }
   rerrcod = (renull,    { no error }
              rerngchk,  { range check }
              relenmat,  { array sizes don't match }
              recasvnf,  { case value not found }
              renilpdr); { nil pointer dereferenced }
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
             eequexp,  { '=' expected }
             elabovf,  { label too long }
             eoptnf,   { option not found }
             elvlovf,  { too many nesting levels }
             esettl,   { set type too large }
             esetneg,  { set has negative elements }
             ecstrng,  { constant out of range }
             esysflt1, { system errors }
             esysflt2,
             esysflt3,
             esysflt4,
             esysflt5,
             esysflt6,
             esysflt7);

var

   intfil:  bytfil;    { intermediate file }
   objfil:  bytfil;    { output object file }
   symfil:  bytfil;    { output symbol file }
   intnam:  filnam;    { intermediate file name }
   outnam:  filnam;    { output file name }
   cmdlin:  linbuf;    { command line buffer }
   cmdptr:  lininx;    { command line index }
   cmdend:  lininx;    { end of command line }
   typstk:  tpsptr;    { types stack }
   typlst:  tpsptr;    { types list }
   ic:      intcod;    { intermediate code holder }
   blkcnt:  integer;   { block nesting counter }
   pgmcnt:  integer;   { program sequence counter/load counter }
   pgmend:  integer;   { end of code store }
   conend:  integer;   { end of constants }
   gblend:  integer;   { end of globals }
   srtstk:  srtptr;    { structure tracking stack }
   srtfre:  srtptr;    { structure tracking free list }
   rldlst:  rldptr;    { relocation entry list }
   gblint:  typptr;    { global integer type }
   gblreal: typptr;    { global real type }
   gblchr:  typptr;    { global character type }
   fretyp:  array [types] of typptr; { free types lists }
   fti:     types;     { index for free types lists }
   frelab:  labptr;    { free symbols list }
   tp:      typptr;    { type entry pointer }
   pgmstr:  typptr;    { program start linker symbol }
   pgsend:  typptr;    { program end linker symbol }
   varstr:  typptr;    { variable start linker symbol }
   varend:  typptr;    { variable end linker symbol }
   iniblk:  typptr;    { module initalizer block }
   modend:  typptr;    { module end }
   cmdovf:  boolean;   { command line overflow }
   fcodel:  boolean;   { code list flag }
   fverb:   boolean;   { verbose flag }
   fbnd:    boolean;   { check bounds }
   fdmpt:   boolean;   { dump types on block }
   fi:      filinx;    { index for filenames }
   final:   boolean;   { finalization block has appeared }
   fopnout: boolean;   { output files are open flag }

   { support library procedures }

   psabort:     typptr; { abort program }
   psaborts:    labptr;
   pserror:     typptr; { process program error }
   pserrors:    labptr;
   pswrtfil:    typptr; { write typed file }
   pswrtfils:   labptr;
   pswrtint:    typptr; { write integer to text file }
   pswrtints:   labptr;
   pswrtchr:    typptr; { write character to text file }
   pswrtchrs:   labptr;
   pswrtbol:    typptr; { write boolean to text file (unfielded) }
   pswrtbols:   labptr;
   pswrtblf:    typptr; { write boolean to text file (fielded) }
   pswrtblfs:   labptr;
   pswrtreal:   typptr; { write real to text file }
   pswrtreals:  labptr;
   pswrtrlf:    typptr; { write real to text file }
   pswrtrlfs:   labptr;
   pswrtstr:    typptr; { write string to text file }
   pswrtstrs:   labptr;
   pswrtstrf:   typptr; { write string to text file fielded }
   pswrtstrfs:  labptr;
   pswrteol:    typptr; { write eoln to text file }
   pswrteols:   labptr;
   pspagtxt:    typptr; { output next page to text file }
   pspagtxts:   labptr;
   psrdfil:     typptr; { read typed file }
   psrdfils:    labptr;
   psrdint:     typptr; { read integer from text file }
   psrdints:    labptr;
   psrdchr:     typptr; { read character from text file }  
   psrdchrs:    labptr;
   psrdreal:    typptr; { read real from text file }
   psrdreals:   labptr;
   psrdeol:     typptr; { read eoln from text file }
   psrdeols:    labptr;
   pseoftxt:    typptr; { check eol true on text file }
   pseoftxts:   labptr;
   pschkeol:    typptr; { check eol true on text file }
   pschkeols:   labptr;
   pseoffil:    typptr; { check eof true on file }
   pseoffils:   labptr;
   psfillen:    typptr; { find file length }
   psfillens:   labptr;
   psfilloc:    typptr; { find file location }
   psfillocs:   labptr;
   psgetfil:    typptr; { get next file buffer }
   psgetfils:   labptr;
   psgettxt:    typptr; { get next text file buffer }
   psgettxts:   labptr;
   psputfil:    typptr; { put next file buffer }
   psputfils:   labptr;
   pslbafil:    typptr; { load address of file buffer }
   pslbafils:   labptr;
   pslbatxt:    typptr; { load address of text file buffer }
   pslbatxts:   labptr;
   psrestxt:    typptr; { reset text file }
   psrestxts:   labptr;
   psresfil:    typptr; { reset file }
   psresfils:   labptr;
   psrwttxt:    typptr; { rewrite text file }
   psrwttxts:   labptr;
   psrwtfil:    typptr; { rewrite file }
   psrwtfils:   labptr;
   psclose:     typptr; { close file }
   pscloses:    labptr;
   psassign:    typptr; { assign name to file }
   psassigns:   labptr;
   psposfil:    typptr; { position file }
   psposfils:   labptr;
   ssexists:    typptr; { check file exists }
   ssexistss:   labptr;
   ssdelete:    typptr; { delete file }
   ssdeletes:   labptr;
   sschange:    typptr; { change filename }
   sschanges:   labptr;
   ssgetspace:  typptr; { allocate dynamic variable }
   ssgetspaces: labptr;
   ssputspace:  typptr; { deallocate dynamic variable }
   ssputspaces: labptr;

{******************************************************************************

Abort program

Exits the current program.

******************************************************************************}

procedure abort; 

begin 

   goto 99 { terminate program } 

end;

{******************************************************************************

Append file extention

Places a new extention to the given filename. If the ovr flag is true, then
any existing extention is overwritten, otherwise the new extention is only
added if the existing name has none.

******************************************************************************}

procedure addext(var fn: filnam; { filename to extend }
                 ex: ext;         { filename extention }
                 ovr: boolean);  { overwrite flag }

var p, n, e: filnam; { path components }

begin

   brknamp(fn, p, n, e);
   { if the extention is missing, or we overwrite it, place extention }
   if (lenp(e) = 0) or ovr then maknamp(fn, p, n, ex)

end;

{******************************************************************************

Process encoder error

Prints the given error code and halts the encode.

******************************************************************************}

procedure error(e: errcod);

begin

   write('*** ');
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
      eequexp: writeln('''='' expected');
      elabovf: writeln('Label too long');
      eoptnf:  writeln('Option not found');
      elvlovf: writeln('Too many nesting levels');
      esettl:  writeln('Set type too large');
      esetneg: writeln('Set has negative elements');
      ecstrng: writeln('Constant out of range');
      esysflt1,
      esysflt2,
      esysflt3,
      esysflt4,
      esysflt5,
      esysflt6,
      esysflt7: writeln('System fault #', ord(e)-ord(esysflt1)+1:1,
                        ': Notify S. A. Moore software')

   end;
   if fopnout then begin { output files are open, delete them }

      { close output files }
      close(objfil);
      close(symfil);
      addext(outnam, 'obj', true); { set object extention }
      delete(outnam); { delete object }
      addext(outnam, 'sym', true); { set symbols extention }
      delete(outnam) { delete symbols }

   end;
   abort { end program }

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
      icvtntg:    write('icvtntg');
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
      ipage:      write('ipage');
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
      ilodint:    write('ilodint');
      ilodrel:    write('ilodrel');
      ilodsrl:    write('ilodsrl');
      ilodset:    write('ilodset');
      ilodchr:    write('ilodchr');
      ilodbol:    write('ilodbol');
      ilodsrc:    write('ilodsrc');
      ilodptr:    write('ilodptr');
      ilodtgp:    write('ilodtgp');
      igotot:     write('igotot');
      igotof:     write('igotof');
      istoint:    write('istoint');
      istosrl:    write('istosrl');
      istorel:    write('istorel');
      istochr:    write('istochr');
      istobol:    write('istobol');
      istoset:    write('istoset');
      istosrc:    write('istosrc');
      istogar:    write('istogar');
      istotgp:    write('istotgp');
      istofint:   write('istofint');
      istoftgp:   write('istoftgp');
      istofsrl:   write('istofsrl');
      istofrel:   write('istofrel');
      istofchr:   write('istofchr');
      istofbol:   write('istofbol');
      icvtrtsr:   write('icvtrtsr');

   end

end;

{******************************************************************************

Print type

Prints the given type code. A diagnostic.

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
      tlink:    write('tlink');
      trot:     write('trot');
      tpgm:     write('tpgm');
      tvrs:     write('tvrs');

   end

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

Find symbol for type

Given a type pointer, finds the symbol referencing that. If no symbol is found,
then nil is returned.

******************************************************************************}

function fndsym(tp: typptr) { type entry to reference }
                : labptr;   { symbol pointer }

var sp, fsp: labptr; { symbol pointers }
    tsp:     tpsptr; { type stack pointer }

begin

   fsp := nil; { clear found pointer }
   tsp := typstk; { index top of block stack }
   while tsp <> nil do begin { search blocks }

      sp := tsp^.sym; { index top of symbols }
      while sp <> nil do begin { traverse symbols }

         if sp^.typ = tp then begin { found the symbol }

            fsp := sp; { place found symbol }
            sp := nil; { stop search }
            tsp := nil

         end else sp := sp^.next { next symbol }

      end;
      if tsp <> nil then tsp := tsp^.next { next level }

   end;
   fndsym := fsp { return found symbol or nil }

end;      

{******************************************************************************

Dump current types list

Dumps the given standard types list. For diagnostic purposes.

******************************************************************************}

procedure dmptyp(lvl: integer);

var tp:       typptr;  { pointer for types }
    tps, fps: tpsptr;  { type stack pointers }
    e:        integer; { entry counter }

begin

   tps := typstk; { index top stack }
   while tps <> nil do begin { traverse }

      if tps^.lvl = lvl then fps := tps; { found }
      tps := tps^.next { next entry }

   end;
   tps := fps; { place found pointer }
   if tps = nil then writeln('*** Diagnostic error: level not found')
   else begin

      tp := tps^.typ; { index top of list }
      e := 1; { set 1st entry }
      while tp <> nil do begin { traverse }

         write('(', tps^.lvl:1, ',', e:1, ') '); { write (level, entry) }
         prttyp(tp^.t); { write type }
         writeln; { next line }
         e := e+1; { count }
         tp := tp^.next { next entry }

      end

   end

end;

{******************************************************************************

Check end of line

Checks whether the input line position is at the end. This is indicated by 
cmdptr being at the extreme end of the input line.
Note that in order to ensure that this is true, a skip space to line end
should be done.

******************************************************************************}

function endlin: boolean;

begin

   endlin := cmdptr = maxlin { true if at line maximum }

end;

{******************************************************************************

Check next input character

The next character in the input buffer is returned. No advance
is made from the current position (succesive calls to this
procedure will yeild the same character).

******************************************************************************}

function chkchr: char; { current input character }

var c: char; { result }

begin

   if endlin then c := ' ' { buffer end, just simulate spaces }
   else c := cmdlin[cmdptr]; { not at buffer end, return character }
   chkchr := c { return result }

end;

{******************************************************************************

Skip input character

Causes the current input character to be skipped, so that the next chkchr call
will return the next character. If endlin is true, no action will take place
(will not advance beyond end of line).

******************************************************************************}

procedure getchr;

begin

   if not endlin then { process advance }
      cmdptr := cmdptr+1 { advance one character }

end;

{******************************************************************************

Skip input spaces or controls

Skips the input position past any spaces or controls. Will
skip the end of line, loading the next line from the input.
The view of the input is for each line to be terminated by
an infinite series of blanks, which only this routine will
cross.

******************************************************************************}

procedure skpspc;

begin

   { skip any spaces }
   while (chkchr = ' ') and not endlin do getchr

end;

{******************************************************************************

Get command word

Gets a series of characters in the given range.

******************************************************************************}

procedure getwrd(var w:   string;  { word to load }
                     val: chrset); { valid characters }

var i: integer;

begin

   clears(w); { clear string }
   i := 1; { set 1st character }
   while chkchr in val do begin { load characters }

      if i > max(w) then begin { overflow }

         writeln('*** Error: filename too long');
         goto 99

      end;
      w[i] := chkchr; { place character }
      getchr; { next character }
      i := i+1

   end

end;

{******************************************************************************

Parse file name

Parses a filename.

******************************************************************************}

procedure parnam(var fn: filnam); { file name return }

var filchrs: chrset; { filename valid characters }

begin

   filchr(filchrs); { get the valid file character set }
   filchrs := filchrs-['=']; { take out our parsing characters }
   getwrd(fn, filchrs); { get filename }
   if not valid(fn) then error(einvfnm) { filename invalid }

end;

{******************************************************************************

Parse label

Parses a label, which is:

    '_'/'a'..'z' ['_', '0'..'9', 'a'..'z']...

The label is returned in the general label buffer labbuf.

******************************************************************************}

procedure parlab(var l: labl);

var i: 0..maxlab; { index for label }

begin

   for i := 1 to maxlab do l[i] := ' '; { clear label buffer }
   i := 0; { clear index }
   while chkchr in ['_', '0'..'9', 'a'..'z', 'A'..'Z'] do begin

      { parse label characters }
      if i >= maxlab then error(elabovf);
      i := i + 1; { next character }
      l[i] := chkchr; { place character }
      getchr { skip }

   end

end;

{******************************************************************************

Check options

Checks if a sequence of options is present in the input, and if
so, parses and processes them. An option is a '#', followed by
the option identifier. The identifier must be one of the valid
options. Further processing may occur, on input after the
option, depending on the option specified (see the handlers).
Consult the operator's manual for full option details.

******************************************************************************}

procedure paropt;

var l: labl; { label holder }

begin

   skpspc; { skip spaces }
   while (chkchr = '#') or (chkchr = '/') do begin { parse option }

      getchr; { skip '#' }
      parlab(l); { get option }
      { check options }
      if compp(l, 'cl        ') or
         compp(l, 'codelist  ') then 
            fcodel := true { set list intermediate code }
      else if compp(l, 'ncl       ') or
              compp(l, 'nocodelist') then 
         fcodel := false { set no list intermediate code }
      else if compp(l, 'verbose   ') or
              compp(l, 'v         ') then 
         fverb := true { set verbose }
      else if compp(l, 'noverbose ') or
              compp(l, 'nv        ') then 
         fverb := false { set no verbose }
      else if compp(l, 'bounds    ') or
              compp(l, 'b         ') then 
         fbnd := true { set bounds checking on }
      else if compp(l, 'nobounds  ') or
              compp(l, 'nb        ') then 
         fbnd := false { set bounds checking off }
      else if compp(l, 'dt        ') or
              compp(l, 'dumptype  ') then 
         fdmpt := true { set type dumping on }
      else if compp(l, 'ndt       ') or
              compp(l, 'nodumptype') then 
         fdmpt := false { set type dumping false }
      else error(eoptnf); { option not found }
      skpspc { skip spaces }

   end

end;

{******************************************************************************

Parse command line

The structure of a command line is:

     file

The file is parsed into intnam.

******************************************************************************}

procedure parcmd;

begin

   cmdptr := 1; { set 1st character in command line }
   paropt; { parse any options }
   parnam(outnam); { parse output file }
   skpspc; { skip spaces }
   if chkchr <> '=' then error(eequexp); { '=' expected }
   getchr; { skip '=' }
   parnam(intnam); { parse input file }
   paropt { parse any options }

end;

{******************************************************************************

Test filename contains an extention

Simply checks if '.' exists in the filename, which would indicate an extention
is present (in a properly parsed filename).

******************************************************************************}

function isext(var f: filnam): boolean; { filename to check }

var p, n, e: filnam; { path components }

begin

   brknamp(f, p, n, e); { break name down }
   isext := lenp(e) > 0 { check extention exists }

end;
{}
{******************************************************************************

Read 32 bit integer from intermediate file

Reads a 32 bit number from the intermediate file. The highest order
byte appears first, and the least order last.
The high byte 7th bit contains the sign.
NOTE: on SVS pascal, subrange types are not expanded to 
integer on read (a violation of the standard). The fix for this
is still compatible with ISO.

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
{******************************************************************************

Read real number from intermediate file

Reads a 64 bit real number to from the intermediate file.

******************************************************************************}

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
         tlink:    new(tp, tlink);
         trot:     new(tp, trot);
         tpgm:     new(tp, tpgm);
         tvrs:     new(tp, tvrs);

      end;
      tp^.t := t { set type of entry }

   end;
   tp^.next := nil; { clear next }
   tp^.addr := 0; { clear address }
   tp^.size := 0; { clear size }
   tp^.local := false; { default to global }
   tp^.level := blkcnt { set block level }

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

procedure puttyp(tp: typptr); { type pointer to return type }

begin

   tp^.next := fretyp[tp^.t]; { link to appropriate free list }
   fretyp[tp^.t] := tp

end;

{******************************************************************************

Get symbol entry

Gets a symbol. Either returns one from the free list, or allocates a new one.

******************************************************************************}

procedure getsym(var lp: labptr); { label to return }

begin

   if frelab <> nil then begin { return free label entry }

      lp := frelab; { index that }
      frelab := frelab^.next { gap the list }

   end else new(lp); { else get a new one }
   lp^.next := nil; { clear next entry }
   lp^.lab := nil; { clear label }
   lp^.typ := nil; { clear type }
   lp^.exp := false { set not exportable }

end;

{******************************************************************************

Put symbol entry

Returns the given symbol to free storage.

******************************************************************************}

procedure fresym(lp: labptr); { label to return }

begin

   lp^.next := frelab; { insert to free list }
   frelab := lp

end;

{******************************************************************************

Get symbol entry into list

Gets a symbol and places it into the current block list.

******************************************************************************}

procedure lstsym(var lp: labptr); { label to return }

begin

   getsym(lp); { get a symbol }
   lp^.next := typstk^.sym; { insert to symbols list }
   typstk^.sym := lp

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

procedure getstr(var s: pstring);

var l: byte; { string length }
    b: byte; { character holder }
    i: byte; { string index }

begin

   read(intfil, l); { get the string length }
   new(s, l); { create a new string }
   for i := 1 to l do begin { get string characters }

      read(intfil, b); { get a string character }
      s^[i] := chr(b) { place }

   end

end;

{******************************************************************************

Find length of string

Finds the length of a space padded string.

******************************************************************************}

function strlen(view s: string): integer;

var l: integer; { length holder }

begin

   l := max(s); { index end of string }
   if l <> 0 then begin { not null string }

      { find the end of the string }
      while (l > 1) and (s[l] = ' ') do l := l-1;
      if s[l] = ' ' then l := 0 { set zero length case }

   end;
   strlen := l { return string length }

end;

{******************************************************************************

Copy string

Copies the source string into the destination. If the destination string is
longer than the source string, the destination is padded with blanks.

******************************************************************************}

procedure strcpy(var  d: string; { destination }
                 view s: string); { source }

var i: integer; { index for string }
    l: integer; { length of string }

begin

   l := strlen(s); { find length of source string }
   if l > max(d) then error(esysflt1); { should not happen }
   for i := 1 to l do d[i] := s[i]; { copy string into place }
   for i := l+1 to max(d) do d[i] := ' ' { pad end }

end;

{******************************************************************************

Place storage string

Places the source string into storage, as indexed by the destination.

******************************************************************************}

procedure strplc(var  d: pstring; { destination }
                 view s: string); { source }

begin

   new(d, strlen(s)); { allocate a new string with the source length }
   strcpy(d^, s) { place contents of string there }

end;

{******************************************************************************

Make rld entry

Creates and rld entry with the given address, type linkage and insertion type.

******************************************************************************}

procedure makrld(adr: integer; { address to place }
                 tp:  typptr; { type entry to use }
                 it:  ityp);  { insertion type }

var rp: rldptr; { relocation entry pointer }

begin

   new(rp); { get a new relocation entry }
   rp^.addr := adr; { set address to patch }
   rp^.lab := tp; { set patch entry }
   rp^.it := it; { place insertion type }
   rp^.out := false; { set not output }
   rp^.next := rldlst; { push onto rld list }
   rldlst := rp

end;

{******************************************************************************

Emit byte

Outputs a single byte to the object deck, and advances the program address.

******************************************************************************}

procedure emitbyt(i: integer);

var c: record case boolean of { convertion }

          false: (i: integer); { integer form }
          true:  (b: packed array[1..intsiz] of byte); { byte format }

       end;

begin

   c.i := i; { place integer }
   write(objfil, c.b[1]); { output byte }
   pgmcnt := pgmcnt+1 { next location }

end;

{******************************************************************************

Emit word

Outputs a 16 bit word to the object deck, and advances the program address.

******************************************************************************}

procedure emitwrd(i: integer);

var c: record case boolean of { convertion }

          false: (i: integer); { integer form }
          true:  (b: packed array[1..intsiz] of byte); { byte format }

       end;
    bi: 1..intsiz; { index for convertion array }  

begin

   c.i := i; { place integer }
   { place byte equivalent in memory }
   for bi := 1 to 2 do begin write(objfil, c.b[bi]); pgmcnt := pgmcnt+1 end

end;

{******************************************************************************

Emit code integer

Outputs a 32 bit integer to the object.

******************************************************************************}

procedure emitint(i: integer);

var c: record case boolean of { convertion }

          false: (i: integer); { integer form }
          true:  (b: packed array[1..intsiz] of byte); { byte format }

       end;
    bi: 1..intsiz; { index for convertion array }  

begin

   c.i := i; { place integer }
   { place byte equivalent in memory }
   for bi := 1 to intsiz do begin
      write(objfil, c.b[bi]); pgmcnt := pgmcnt+1 end

end;

{******************************************************************************

Emit code real

Outputs a 64 bit real to the object.

******************************************************************************}

procedure emitrl(r: real);

var c: record case boolean of { convertion }

          false: (r: real); { real form }
          true:  (b: packed array[1..rlsiz] of byte); { byte format }

       end;
    bi: 1..rlsiz; { index for convertion array }  

begin

   c.r := r; { place real }
   { place byte equivalent in memory }
   for bi := 1 to rlsiz do
      begin write(objfil, c.b[bi]); pgmcnt := pgmcnt+1 end

end;

{******************************************************************************

Emit code short real

Places a 32 bit real into the code memory at the current program load
address, and advances the address to after it. Errors on the program load
being at the end of memory.

******************************************************************************}

procedure emitsrl(r: real);

var c: record case boolean of { convertion }

          false: (r: sreal); { 32 bit real form }
          true:  (b: packed array[1..srlsiz] of byte); { byte format }

       end;
    bi: 1..srlsiz; { index for convertion array }  

begin

   c.r := r; { place short real }
   { place byte equivalent in memory }
   for bi := 1 to srlsiz do 
      begin write(objfil, c.b[bi]); pgmcnt := pgmcnt+1 end

end;

{******************************************************************************

Emit code string

Places a string constant into the code memory at the current program load
address, and advances the address to after it. Errors on the program load
being at the end of memory.

******************************************************************************}

procedure emitstr(view s: string);

var i: integer; { index for string }

begin

   for i := 1 to max(s) do { place characters }
      begin write(objfil, ord(s[i])); pgmcnt := pgmcnt+1 end

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

      itadr:   emitint(tp^.addr); { output address }
      itradr:  emitint(tp^.addr-(pgmcnt+2)); { output relative address }
      itbradr: emitbyt(tp^.addr-(pgmcnt+1)) { output relative address }

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
   sp^.withm := false; { set not a 'with' entry }
   sp^.off := 0 { clear offset }

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

Push new block level

Creates a new block level entry, and pushes that onto the block stack.

*******************************************************************************}

procedure pshblk;

var tsp: tpsptr;  { types stack pointer }

begin

   new(tsp); { get a new type level }
   tsp^.next  := typstk; { push onto stack }
   typstk     := tsp;
   { the parent link looks redundant now, but will keep the nesting structure
     as the block list is unwound into the master list }
   tsp^.prnt  := tsp^.next; { place parent entry }
   tsp^.typ   := nil;    { clear root }
   tsp^.lst   := nil;    { clear last }
   tsp^.res   := nil;    { clear next resolable alternate }
   tsp^.typa  := nil;    { clear alternate types list }
   tsp^.lsta  := nil;    { clear last alternate }
   tsp^.resa  := nil;    { clear next resolvable alternate }
   tsp^.lvl   := blkcnt; { set level number }
   tsp^.loc   := false;  { locals not allocated }
   tsp^.mark  := nil;    { clear mark entry }
   tsp^.marks := nil;    { clear mark symbol }
   tsp^.sym   := nil     { clear symbols list }

end;

{******************************************************************************

Pop block level

Removes the top block level, and transfers the entry onto the types list.

*******************************************************************************}

procedure popblk;

var tsp: tpsptr;  { types stack pointer }

begin

   tsp := typstk; { save top entry }
   typstk := typstk^.next; { pop top of stack }
   { place onto types list, which will contain all of the type entries
     when the program is completely read }
   tsp^.next := typlst; { insert to list }
   typlst := tsp

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
   else if tp^.t = tscst then begin { string constant }

      if max(tp^.sval^) = 1 then { single character }
         i := ord(tp^.sval^[1]) { load character }
      else error(einvfmt) { must be single character }

   end else if tp^.t = tccst then i := ord(tp^.cval) { string constant }
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
      tlink:    ; { no base type }
      trot:     ; { no base type }
      tpgm:     ; { no base type }
      tvrs:     ; { no base type }

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
      if tp^.t <> tscst then m := false { not a string constant }
      else m := max(tp^.sval^) = 1; { must be single character }
   chart := m

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

Round to words

Rounds the given size to an even number of words. Anything pushed onto the
stack is rounded up to words to keep the stack aligned to 32 bits. This is
necessary for good performance on the I80386.

******************************************************************************}

function wrdsiz(s: integer) { size to round }
                :integer;   { return size }

var r: integer; { result holder }

begin

   r := s div stksiz*stksiz; { find even words }
   if s mod stksiz <> 0 then r := r+stksiz; { round up to words }
   wrdsiz := r { return result }

end;

{******************************************************************************

Set size of type entry

Determines the size that an object of the given type will occupy, in bytes,
and sets that variable in the type. If the type already has a size it is
skipped. If it does not, we also recursively verify that all relied on
submembers also have a size. That way, the size tree for the entry is
self-resolved for any undefineds.
Also sets the signed status of the type.
Also checks sets for > 256 elements, and sets with negative elements.

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
      if tp^.t = tftag then begin { check tag field exists }

         { don't add in this element if it does not exist }
         if tp^.ftge then size := size+tp^.size { add in size of field }

      end else size := size+tp^.size; { add in size of field }
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

{ find size of parameters list }

function sizep(tp: typptr): integer;

var ps: integer; { parameters size }

begin

   ps := 0; { clear result }
   while tp <> nil do begin { traverse }

      sizset(tp); { set size of parameter }
      ps := ps+wrdsiz(tp^.size); { add in parameter size }
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

{ find value size in bytes }

function valsiz(s, e: integer) { value range }
                : integer;  { byte size of values }

var b: integer; { number of bytes }

begin

   if s > e then error(einvfmt); { bad range }
   if ((s >= -128) and (e <= 127)) or ((s >= 0) and (e <= 255)) then
      b := 1 { byte }
   else if ((s >= -32768) and (e <= 32767)) or ((s >= 0) and (e <= 65535)) then
      b := 2 { word }
   else b := 4; { dword }
   valsiz := b { return byte size }

end;

{ find size of emumerated in bytes }

function enmsiz(tp: typptr) { list to check }
                : integer;  { byte size of type }

var m: integer; { maximum list value }

begin

   m := -1; { set no maximum }
   while tp <> nil do begin { traverse list }

      if tp^.t <> tenme then error(einvfmt); { bad format }
      if tp^.env > m then m := tp^.env; { set new maximum }
      tp := tp^.enx { link next entry }

   end;
   if m = -1 then error(einvfmt); { must have some size }
   enmsiz := valsiz(0, m) { return byte size }

end;

begin

   if tp^.size = 0 then { if the entry has no size, size it }
      with tp^ do case t of { type }

      tudf:      ; { none }   
      tnil:      size := intsiz; { 32 bit pointer }   
      tlab:      ; { none }
      ticst:     size := intsiz; { 32 bit constant }  
      tscst:     size := max(sval^); { same as length }
      tccst:     size := 1; { single character }
      trcst:     size := rlsiz; { 64 bit real }  
      tstcst:    begin sizset(stct); { find base type size }
                       size := setsiz; { 256 bits of 32 bytes in a set }
                       { flag error on set greater than 256 elements }
                       if stct^.size > 1 then error(esettl);
                       { flag error on negative base }
                       if lbound(stct) < 0 then error(esetneg) end;
      tstet:     ; { no meaning to this }
      { structured constants are not sized, because we use the base type of any
        fixed object to process them }
      tarrcst:   ;
      tarrcel:   ;
      treccst:   ;
      treccel:   ;
      tenum:     size := enmsiz(enc); { find size by enumerated list }
      tenme:     begin sizset(enh); size := enh^.size end; { enumerated const }
      tsub:      size := valsiz(subl, subu); { subrange of values size }
      tptr:      if ptrt^.t = tgarry then size := tgpsiz { general array }
                 else size := intsiz; { 32 bit pointer }   
      { arrays are the number of bytes per element, times the number of
        elements }
      tarray:    begin sizset(arrt); 
                       size := arrt^.size*
                               (ubound(arri)-lbound(arri)+1) end;
      tgarry:    ; { general arrays have no fixed size }
      tfile:     size := 1; { file number } 
      tset:      begin sizset(sett); { find base type size }
                       size := setsiz; { 256 bits or 32 bytes in a set }
                       { flag error on set greater than 256 elements }
                       if sett^.size > 1 then error(esettl);
                       { flag error on negative base }
                       if lbound(sett) < 0 then error(esetneg) end;
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
      tproc:     prca := sizep(prcp); { set size of parameters }
      tfunc:     fnca := sizep(fncp); { set size of parameters }
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
      tpproc:    begin

         size := 4; { 32 bit address of procedure }
         ppra := sizep(pprp) { set size of parameters }

      end;
      tpfunc:    begin

         size := 4; { 32 bit address of function }
         pfna := sizep(pfnp) { set size of parameters }

      end;
      tinteger:  size := 4; { 32 bit signed integer }
      tchar:     size := 1; { character }
      tboolean:  size := 1; { boolean }
      treal:     size := 8; { 64 bit real }
      tsreal:    size := 4; { 32 bit real }
      ttext:     size := 1; { file number }
      teset:     size := 32; { 256 bits or 32 bytes in a set }
      tglbl:     ; { none }
      tnull:     ; { none }
      tfuncr:    begin sizset(fnrt); size := wrdsiz(fnrt^.size) end;
      tlink:     ; { none }
      trot:      ; { none }
      tpgm:      ; { none }
      tvrs:      ; { none }

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
All local addresses are relative, so address 0 is the top of the locals, as
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
There are only two ordinals that fall under the expansion rule, characters and
booleans. Files, even though one byte long, don't apply since they are allways
passed VAR.
Note that parameters of character and boolean type must be accessed specially,
because although loaded as atoms, they are referenced as ordinary memory
operands. This nonsense is required to allow chars and booleans to be packed
in memory.

******************************************************************************}

procedure allloc;

var tp:   typptr;  { index for types }
    la:   integer; { local address }
    size: integer; { locals size }

{ allocate parameters }

procedure allocate(tp: typptr;   { parameter list }
                   la: integer); { top of locals space }

begin

   while tp <> nil do begin { traverse }

      la := la-wrdsiz(tp^.size); { find base of variable }
      tp^.addr := la; { place address }
      case tp^.t of { parameter, find next }

         tpar:   tp := tp^.parn; { parameter }
         tvpar:  tp := tp^.vprn; { variable parameter }
         twpar:  tp := tp^.wprn; { view parameter }
         tpproc: tp := tp^.pprn; { procedure parameter }
         tpfunc: tp := tp^.pfnn  { function parameter }

      end

   end

end;

{ find variable sizes in list }

function fndsiz(tp: typptr): integer;

var size: integer; { size total }

begin

   size := 0; { clear size }
   while tp <> nil do begin { traverse list }

      { check entry is local variable }
      if tp^.t = tvar then size := size+tp^.size; { add in this entry }
      tp := tp^.next { next entry }

   end;
   fndsiz := size { return result }

end;

{ allocate variables in list }

procedure setloc(tp: typptr);

begin

   while tp <> nil do begin { traverse list }

      if tp^.t = tvar then begin { it's a variable, allocate }

         tp^.addr := la; { assign the address }
         la := la+tp^.size { step to next }

      end;
      tp := tp^.next { next entry }

   end

end;

begin

   { perform sizing pass }
   size := fndsiz(typstk^.typ); { find standard size }
   size := size+fndsiz(typstk^.typa); { add alternate sizes }
   la := -((blkcnt-1)*4)-size; { set local address to bottom of frame }
   setloc(typstk^.typ); { process standard list }
   setloc(typstk^.typa); { process alternate list }
   tp := typstk^.mark; { index the mark }
   if tp^.t = tproc then begin { procedure }

      tp^.prcv := wrdsiz(size); { set total locals size }
      { allocate parameters down from top of all frame space, locals, return
        address, display save, and parameters }
      allocate(tp^.prcp, stksiz+stksiz+tp^.prca)
      
   end else if tp^.t = tfunc then begin { function }

      tp^.fncv := wrdsiz(size); { set total locals size }
      { allocate parameters down from top of all frame space, locals, return
        address, display save, and parameters }
      allocate(tp^.fncp, stksiz+stksiz+tp^.fnca);
      { allocate function return at the top of that same frame }
      tp^.fncr^.addr := stksiz+stksiz+tp^.fnca
      
   end

end;

{******************************************************************************

Adjust parameter list levels

Adjusts the parameter list block levels to equal the current block level. The
parameters and function return lives in the caller, not the callee level,
because the compiler needs them for prototyping. But they are accessed just as
locals in the callee level. So we move them into the current level before
coding starts.

******************************************************************************}

procedure adjpar;

{ adjust type list }

procedure adjust(tp: typptr);

begin

   while tp <> nil do begin { traverse }

      tp^.level := blkcnt; { set level to current }
      case tp^.t of { parameter, find next }

         tpar:   tp := tp^.parn; { parameter }
         tvpar:  tp := tp^.vprn; { variable parameter }
         twpar:  tp := tp^.wprn; { view parameter }
         tpproc: tp := tp^.pprn; { procedure parameter }
         tpfunc: tp := tp^.pfnn  { function parameter }

      end

   end;

end;

begin

   if typstk^.mark^.t = tproc then adjust(typstk^.mark^.prcp) { procedure }
   else if typstk^.mark^.t = tfunc then adjust(typstk^.mark^.fncp) { function }

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
    sp: labptr; { symbol list pointer }

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
         tlink:    ;
         trot:     ;
         tpgm:     ;
         tvrs:     ;

      end;
      tp := tp^.next { next entry }

   end

end;

begin

   dores(typstk^.res); { resolve standard list }
   dores(typstk^.resa); { resolve alternates list }
   resolve(typstk^.mark); { resolve the mark linkage }
   { resolve symbols list }
   sp := typstk^.sym; { index top of list }
   while sp <> nil do begin { traverse }

      resolve(sp^.typ); { resolve this entry }
      sp := sp^.next { find next entry }

   end;
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

Check signed type

Checks if the given type is signed. There are only two such types, integer, and
subranges of integer with negative lower bounds.

******************************************************************************}

function chksgn(tp: typptr) { type to check }
                : boolean; { signed status }

var s: boolean; { signed type flag }

begin

   s := false; { set not signed }
   if tp^.t = tinteger then s := true { integer is signed }
   else if tp^.t = tsub then { subrange }
      s := tp^.subl < 0; { set signed status }
   chksgn := s { return result }

end;   

{******************************************************************************

Find record field

Finds a field in the given record scope, and returns true if the field exists
in the scope. All of the variants are searched.

******************************************************************************}

function inscope(tp: typptr; { record scope to search }
                 sp: typptr) { field to search for }
                : boolean;   { found status }

var m: boolean; { found flag }

begin

   m := false; { set no match found }
   while tp <> nil do begin { traverse field list }

      if tp = sp then m := true; { set field found }
      if tp^.t = tfield then tp := tp^.fldn { index next field entry }
      else begin { must be tagfield }

         if tp^.t <> tftag then error(einvfmt); { bad format }
         tp := tp^.ftgc; { index case constant list }
         while tp <> nil do begin { traverse cases }

            if tp^.t <> tfcas then error(einvfmt); { bad format }
            if inscope(tp^.fcsf, sp) then m := true; { found }
            tp := tp^.fcsn { link next }

         end

      end

   end;
   inscope := m { return match status }

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
   
var ic, ic1:     intcod;  { intermediate code holders }
    b, b1, b2:   byte;    { file byte holders }
    v:           integer; { integer parameter }
    r:           real;    { real parameter }
    tp, tp1:     typptr;  { type pointers }
    intcnt:      integer; { intermediate tolken count }
    sp, sp1:     srtptr;  { structure tracking entry }
    rsiz, rsiz1: integer; { record sizes }
    stack:       integer; { stack (as offset from local base) }
    lp:          labptr;  { label entry pointer }

{ get next intermediate code }

procedure getcod(var ic: intcod);

var b: byte;
    c: integer;

begin

      read(intfil, b); { get next code }
      c := b; { place }
      if b = 255 then begin { extended code }

         read(intfil, b); { get extended code }
         c := 255+b

      end;
      if c > ord(icvtrtsr) then error(einvitc); { invalid code number }
      intcnt := intcnt+1; { count tolken }
      ic := intcod(c) { convert to intermediate code }

end;

begin

   blkcnt := 0; { clear block counter }
   intcnt := 0; { clear tolken counter }
   tp := nil; { clear last type }
   { note that since the real stack is unknown, we should only use the pseudo
     stack for relative calculations }
   stack := maxint; { set maximum stack }
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
      if fcodel then begin { list intermediate code }

         prthex(8, pgmcnt);
         write('->');
         prthex(8, stack);
         write(' ', intcnt:6, ': ');
         prtic(ic); 
         writeln

      end;
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
                  adjpar; { adjust parameter levels }
                  allloc; { allocate any previous block locals }
                  typstk^.loc := true { set locals resolved }

               end

            end;
            blkcnt := blkcnt+1; { increment block counter }
            if blkcnt > 31 then error(elvlovf); { too many levels }
            pshblk; { allocate new block level }
            getlnk(typstk^.mark) { place block mark linkage }

         end;
         iendlvl: begin

            typstk^.marks := fndsym(typstk^.mark); { place block mark symbol }
            blkcnt := blkcnt-1; { decrement block counter }
            if blkcnt < 0 then error(einvfmt); { bad format }
            if fdmpt then dmptyp(typstk^.lvl); { dump types if diagnostic on }
            popblk { remove block level }

         end;
         iusefil: ; { this is unimplemented anywhere }
         inil:    gettyp(tp, tnil); { nil type }
         ilab:    begin

            gettyp(tp, tlab); { get the type entry }
            tp^.lmrk := typstk^.mark { place mark }

         end;
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

            gettyp(tp, tccst); { get the type entry }
            read(intfil, b); { get the character constant }
            tp^.cval := chr(b); { place value }
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
            tp^.vare := b <> 0; { set }
            tp^.varr := false { set no references }

         end;
         ifix:    begin

            gettyp(tp, tfix); { get the type entry }
            getlnk(tp^.fixt); { get base type link }
            getlnk(tp^.fixc); { get constant link }
            read(intfil, b); { get external flag }
            tp^.fixe := b <> 0; { set }
            tp^.fixr := false { set no references }

         end;
         iproc:   begin

            gettyp(tp, tproc); { get the type entry }
            getlnk(tp^.prcp); { get parameter list }
            read(intfil, b); { get external flag }
            tp^.prce := b <> 0; { set }
            tp^.prcr := false { set no references }

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
            tp^.fnce := b <> 0; { set }
            tp^.fnct := false { set no references }

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
            getlnk(tp^.pfnn) { get next parameter }

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
            if b > 5 then error(einvfmt); { bad format }
            case b of { module type }
            
               0: tp^.mm := mmsystem; { system module }
               1: tp^.mm := mmprogram; { program module }
               2: tp^.mm := mmmodule;  { module module }
               3: tp^.mm := mmprocess; { process module }
               4: tp^.mm := mmmonitor; { monitor module }
               5: tp^.mm := mmshare    { share module }

            end;
            gettypa(tp^.ds, tvar); { make a display save for this block }
            tp^.ds^.local := false; { set not a local }
            tp^.ds^.vare := false; { set not external }
            gettypa(tp^.ds^.vart, tnil) { set base type pointer }

         end;
         inull:   gettyp(tp, tnull); { get the type entry }
         isym:    begin { symbol }

            lstsym(lp); { get a new symbol entry }
            getstr(lp^.lab); { read in symbol }
            getlnk(lp^.typ); { get the type linkage }
            read(intfil, b); { get exportable flag }
            lp^.exp := b <> 0 { set flag }

         end;
         issym:   begin { simple symbol }

            { simple symbols get attached to the last type entry }
            if tp = nil then error(einvfmt); { invalid format }
            lstsym(lp); { get a new symbol entry }
            getstr(lp^.lab); { read in symbol }
            lp^.typ := tp { set type linkage }

         end;

         { *** OBJECT CODE SECTION *** }

         ibgnpgm:  begin { main section start }

            if stack <> maxint then error(esysflt2); { check stack at 0 }
            resblk; { resolve forward references }
            sizblk; { size entries in block }
            typstk^.res := nil; { clear resolvables }
            typstk^.resa := nil;
            if not typstk^.loc and (typstk^.lvl >= 3) then begin

               { locals not allocated }
               adjpar; { adjust parameter levels }
               allloc; { allocate any previous block locals }
               typstk^.loc := true { set locals resolved }

            end;
            typstk^.mark^.addr := pgmcnt; { set address of code }
            { if this is the main block start, equate the initalize jump }
            if blkcnt = 2 then iniblk^.addr := pgmcnt;
            { place current frame on stack, and set new frame from esp }
            emitbyt($c8); { enter 0,level }
            emitbyt($00);
            emitbyt($00);
            emitbyt(blkcnt-1); { with current level }
            { if a procedure or function, it has locals, and so they must
              be allocated. We use a general allocation because link only
              does 64kb }
            if typstk^.mark^.t = tproc then begin

               { we are activating a procedure }
               if typstk^.mark^.prcv <> 0 then begin { there are locals }

                  emitbyt($81); { add esp,offset }
                  emitbyt($c4);
                  emitint(-typstk^.mark^.prcv); { to allocate variables }
                  { clear local area. this is mainly done to allow files
                    to work in a local area, but also helps for other
                    variables }
                  emitbyt($8b); { mov edi,esp }
                  emitbyt($fc);
                  emitbyt($8b); { mov esi,edi }
                  emitbyt($f7);
                  emitbyt($47); { inc edi }
                  emitbyt($c6); { movb [esi],0 }
                  emitbyt($06);
                  emitbyt($00);
                  emitbyt($b9); { mov ecx,size }
                  emitint(typstk^.mark^.prcv-1);
                  emitbyt($f2); { repnz }
                  emitbyt($a4) { movsb }

               end

            end else if typstk^.mark^.t = tfunc then begin

               { we are activating a function }
               if typstk^.mark^.fncv <> 0 then begin { there are locals }

                  emitbyt($81); { add esp,offset }
                  emitbyt($c4);
                  emitint(-typstk^.mark^.fncv); { to allocate variables }
                  { clear local area. this is mainly done to allow files
                    to work in a local area, but also helps for other
                    variables }
                  emitbyt($8b); { mov edi,esp }
                  emitbyt($fc);
                  emitbyt($8b); { mov esi,edi }
                  emitbyt($f7);
                  emitbyt($47); { inc edi }
                  emitbyt($c6); { movb [esi],0 }
                  emitbyt($06);
                  emitbyt($00);
                  emitbyt($b9); { mov ecx,size }
                  emitint(typstk^.mark^.fncv-1);
                  emitbyt($f2); { repnz }
                  emitbyt($a4) { movsb }

               end

            end else begin

               { Major modules are expected to run once to completion. Because
                 nesting problems, we must save the display for each such
                 to allow a goto a path back to that level. This does not need
                 be reentrant, since major modules aren't }
               emitbyt($89); { mov [dispsav],ebp }
               emitbyt($2d);
               emitadr(typstk^.mark^.ds, itadr) { place display save address }

            end
            
         end;
         iendpgm:  begin { main section end }

            { if a procedure or function, it has locals, and so they must
              be deallocated }
            if typstk^.mark^.t = tproc then begin

               { we are deactivating a procedure }
               emitbyt($c9); { leave }
               if typstk^.mark^.prca <> 0 then begin { deallocate parameters }

                  emitbyt($58); { pop eax }
                  emitbyt($81); { add esp,offset }
                  emitbyt($c4);
                  emitint(typstk^.mark^.prca);
                  emitbyt($ff); { jmp eax }
                  emitbyt($e0)

               end else emitbyt($c3) { ret }

            end else if typstk^.mark^.t = tfunc then begin

               { we are deactivating a function }
               emitbyt($c9); { leave }
               if typstk^.mark^.fnca <> 0 then begin { deallocate parameters }

                  emitbyt($58); { pop eax }
                  emitbyt($81); { add esp,offset }
                  emitbyt($c4);
                  emitint(typstk^.mark^.fnca);
                  emitbyt($ff); { jmp eax }
                  emitbyt($e0)

               end else emitbyt($c3) { ret }

            end else begin { main exit }

               { generate call to next module in series }
               emitbyt($e8); { call modend }
               emitadr(modend, itradr) { output address }

            end;
            if stack <> maxint then error(esysflt3) { check stack at 0 }

         end;
         ibgnext:  if stack <> maxint then error(esysflt4); { check stack at 0 }
         iendext:  begin { end finalizer section }

            emitbyt($c9); { leave }
            emitbyt($c3); { set return to caller }
            if stack <> maxint then error(esysflt5); { check stack at 0 }
            final := true { set finalization block has appeared }

         end;
         ilodadr:   begin { load address }

            getlnk(tp); { link object to load }
            { process reference on object }
            if tp^.t = tvar then tp^.varr := true
            else if tp^.t = tfix then tp^.fixr := true
            else if tp^.t = tproc then tp^.prcr := true
            else if tp^.t = tfunc then tp^.fnct := true;
            if (tp^.t = tfield) or (tp^.t = tftag) then begin

               { access is to a 'with' field, must lookup reference in with
                 stacked structures }
               sp := srtstk; { index 1st on stack }
               sp1 := nil; { set no entry found }
               while sp <> nil do begin { search for 'with' match }

                  if sp^.withm then begin { is 'with' entry, check for match }

                     { check field exists in scope }
                     if inscope(sp^.lab^.recf, tp) then begin { found }

                        sp1 := sp; { set location }
                        sp := nil { flag search complete }

                     end

                  end;
                  if sp <> nil then sp := sp^.next { index next entry }

               end;
               if sp1 = nil then error(einvfmt); { set invalid intermediate }
               { load local address current block }
               emitbyt($8b); { mov eax,esp }
               emitbyt($c4);
               emitbyt($8b); { mov eax,off[eax] }
               emitbyt($80);
               emitint(sp1^.off-stack); { generate offset }
               { now we have pulled the address to tos. we can now process just
                 as a record offset }
               emitbyt($05); { add eax,off }
               emitadr(tp, itadr);
               emitbyt($50) { push eax }
            
            end else begin

               if tp^.local then begin { local address }

                  { get display for target level }
                  emitbyt($8b); { mov eax,[ebp-lvl] }
                  emitbyt($85);
                  emitint(-((tp^.level-1)*4)); { offset to proper display level }
                  { offset to local }
                  emitbyt($05); { add eax,imm }
                  emitint(tp^.addr); { place offset address }
                  { place on stack }
                  emitbyt($50) { push eax }

               end else begin

                  { load global address }
                  emitbyt($68); { push imm }
                  emitadr(tp, itadr) { place address }

               end

            end;
            stack := stack-stksiz { adds one }

         end;
         ilodfadr:    begin { load function result address }

            getlnk(tp); { get function type }
            tp := tp^.fncr; { index function variable }
            { get the display }
            emitbyt($8b); { mov eax,ebp }
            emitbyt($c5);
            { offset to local }
            emitbyt($05); { add eax,imm }
            emitadr(tp, itadr); { place address }
            { place on stack }
            emitbyt($50); { push eax }
            stack := stack-stksiz { adds one }

         end;
         iarrref:  begin { array reference }

            getlnk(tp); { get array type }
            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump to error label }
            gettypa(srtstk^.lab1, tlab); { set jump over error label }
            { load index }
            emitbyt($58); { pop eax }
            { generate range check }
            emitbyt($3d); { cmp eax,imm }
            emitint(lbound(tp^.arri)); { place low bound }
            emitbyt($0f); { jl goerror }
            emitbyt($8c);
            emitadr(srtstk^.lab, itradr); { place error jump address }
            emitbyt($3d); { cmp eax,imm }
            emitint(ubound(tp^.arri)); { place upper bound }
            emitbyt($0f); { jle noerror }
            emitbyt($8e);
            emitadr(srtstk^.lab1, itradr); { place no error address }
            { generate error routine call }
            srtstk^.lab^.addr := pgmcnt; { set jump to error location }
            emitbyt($68); { push rerngchk }
            emitint(ord(rerngchk)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab1^.addr := pgmcnt; { set jump over error location }
            { adjust index for lower bound }
            emitbyt($2d); { sub eax,lbound }
            emitint(lbound(tp^.arri)); { place lower bound }
            emitbyt($bb); { mov ebx,size }
            emitint(tp^.arrt^.size); { place base type size }
            emitbyt($f7); { mul eax,ebx }
            emitbyt($e3);
            { load array base }
            emitbyt($5b); { pop ebx }
            { add processed index to that }
            emitbyt($03); { add eax,ebx }
            emitbyt($c3);
            emitbyt($50); { push eax }
            popsrt; { remove structure level }
            stack := stack+stksiz { net is less one }

         end;
         iarfgar:  begin { general array reference }

            getlnk(tp); { get array type }
            if tp^.t <> tgarry then error(einvfmt); { bad format }
            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            { load index }
            emitbyt($58); { pop eax }
            { load tagged pointer }
            emitbyt($5b); { pop ebx }
            emitbyt($59); { pop ecx }
            { zero adjust }
            emitbyt($48); { dec eax }
            { generate range check }
            emitbyt($3b); { cmp eax,ecx }
            emitbyt($c1);
            emitbyt($0f); { jb over }
            emitbyt($82);
            emitadr(srtstk^.lab, itradr); { place no error address }
            { generate error routine call }
            emitbyt($68); { push rerngchk }
            emitint(ord(rerngchk)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab^.addr := pgmcnt; { set jump over error location }
            emitbyt($b9); { mov ecx,size }
            emitint(tp^.gart^.size); { output size of base element }
            emitbyt($f7); { mul eax,ecx }
            emitbyt($e1);
            { add processed index to array base }
            emitbyt($03); { add eax,ebx }
            emitbyt($c3);
            emitbyt($50); { push eax }
            popsrt; { remove structure level }
            stack := stack+intsiz+tgpsiz-intsiz { adjust stack }

         end;
         irecoff:     begin { record element reference }

            getlnk(tp); { get record field type }
            { get base address }
            emitbyt($58); { pop eax }
            emitbyt($05); { add eax,imm }
            emitadr(tp, itadr); { place record offset }
            emitbyt($50) { push eax }

         end;
         ildiint:  begin { load indirect integer }

            getlnk(tp); { variable type }
            { get address }
            emitbyt($58); { pop eax }
            { load operand }
            if tp^.size = 4 then begin { integer }

               emitbyt($8b); { mov eax,[eax] }
               emitbyt($00)

            end else if tp^.size = 2 then begin { word }

               if chksgn(tp) then begin { signed }

                  emitbyt($0f); { movsxw eax,[eax] }
                  emitbyt($bf);
                  emitbyt($00)

               end else begin { unsigned }

                  emitbyt($0f); { movzxw eax,[eax] }
                  emitbyt($b7);
                  emitbyt($00)

               end

            end else if tp^.size = 1 then begin { byte }

               if chksgn(tp) then begin { signed }

                  emitbyt($0f); { movsxb eax,[eax] }
                  emitbyt($be);
                  emitbyt($00)

               end else begin { unsigned }

                  emitbyt($0f); { movzxb eax,[eax] }
                  emitbyt($b6);
                  emitbyt($00)

               end

            end else error(einvfmt); { invalid format }
            { place on stack }
            emitbyt($50) { push eax }

         end;
         ildirel:   begin { load indirect real }

            { get address }
            emitbyt($5e); { pop si }
            { load real }
            emitbyt($ad); { lodsd }
            emitbyt($8b); { mov ebx,eax }
            emitbyt($d8);
            emitbyt($ad); { lodsd }
            emitbyt($50); { push eax }
            emitbyt($53); { push ebx }
            stack := stack+stksiz-rlsiz { adjust stack }
            
         end;
         ildisrl:  begin { load indirect short real }

            { get address }
            emitbyt($58); { pop eax }
            { load to fpu }
            emitbyt($d9); { fld [eax] }
            emitbyt($00);
            { create stack space }
            emitbyt($50); { push eax }
            emitbyt($50); { push eax }
            { place fpu result }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            emitbyt($dd); { fstp [eax] }
            emitbyt($18);
            { sync stored operand }
            emitbyt($9b); { fwait }
            stack := stack+stksiz-rlsiz { adjust stack }

         end;
         ildiset:  begin { load indirect set }

            { get address }
            emitbyt($5e); { pop si }
            { create space on stack }
            emitbyt($81); { add esp,offset }
            emitbyt($c4);
            emitint(-setsiz);
            { place destination address }
            emitbyt($8b); { mov edi,esp }
            emitbyt($fc);
            { place size }
            emitbyt($c7); { mov ecx,setsiz }
            emitbyt($c1);
            emitint(setsiz div 4);
            { place operand }
            emitbyt($f3); { rep }
            emitbyt($a5); { movsd }
            stack := stack+stksiz-setsiz { adjust stack }

         end;
         ildichr, 
         ildibol:  begin { load indirect character }

            { get address }
            emitbyt($58); { pop eax }
            { load operand }
            emitbyt($0f); { movzxb eax,[eax] }
            emitbyt($b6);
            emitbyt($00);
            { place on stack }
            emitbyt($50) { push eax }
            
         end;
         ildisrc:  begin { load indirect structure }

            getlnk(tp); { get structure type }
            { get address }
            emitbyt($5e); { pop si }
            { create space on stack }
            emitbyt($81); { add esp,offset }
            emitbyt($c4);
            emitint(-wrdsiz(tp^.size));
            { place destination address }
            emitbyt($8b); { mov edi,esp }
            emitbyt($fc);
            { place size }
            emitbyt($c7); { mov ecx,setsiz }
            emitbyt($c1);
            emitint(tp^.size);
            { place operand }
            emitbyt($f3); { rep }
            emitbyt($a4); { movsb }
            stack := stack+stksiz-wrdsiz(tp^.size) { adjust stack }

         end;
         ildiptr:  begin { load indirect pointer }

            { get address }
            emitbyt($58); { pop eax }
            { load operand }
            emitbyt($8b); { mov eax,[eax] }
            emitbyt($00);
            { replace on stack }
            emitbyt($50); { push eax }

         end;
         ilditgp:   begin

            { get address }
            emitbyt($5e); { pop si }
            { load tagged pointer }
            emitbyt($ad); { lodsd }
            emitbyt($8b); { mov ebx,eax }
            emitbyt($d8);
            emitbyt($ad); { lodsd }
            emitbyt($50); { push eax }
            emitbyt($53); { push ebx }
            stack := stack+stksiz-tgpsiz { adjust stack }

         end;
         ilimint: begin
 
            rdnum(v); { get integer parameter }
            emitbyt($b8); { mov eax,imm }
            emitint(v); { output value in line }
            { place on stack }
            emitbyt($50); { push eax }
            stack := stack-intsiz { adjust stack }

         end;
         ilimrel:  begin

            rdreal(r); { get real parameter }
            { the I80386 has no real immediate instructions. we load the real
              into a constant entry, then that will be placed in the constants
              area }
            gettypa(tp, trcst); { get constant entry }
            tp^.rval := r; { place constant }
            { load constant }
            emitbyt($dd); { fld [rconst] }
            emitbyt($05);
            emitadr(tp, itadr); { place address }
            { create stack space }
            emitbyt($50); { push eax }
            emitbyt($50); { push eax }
            { place fpu result }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            emitbyt($dd); { fstp [eax] }
            emitbyt($18);
            { sync stored operand }
            emitbyt($9b); { fwait }
            stack := stack-rlsiz { adust stack }

         end;
         ilimns:  begin

            { create space on stack }
            emitbyt($81); { add esp,offset }
            emitbyt($c4);
            emitint(-setsiz);
            emitbyt($8b); { mov esi,esp }
            emitbyt($f4);
            emitbyt($8b); { mov edi,esi }
            emitbyt($fe);
            emitbyt($47); { inc edi }
            emitbyt($c6); { movb [esi],0 }
            emitbyt($06);
            emitbyt($00);
            emitbyt($c7); { mov ecx,setsiz-1 }
            emitbyt($c1);
            emitint(setsiz-1);
            emitbyt($f3); { rep }
            emitbyt($a4); { movsb }
            stack := stack-setsiz { adds a set }

         end;
         ilodlen:  begin

            getlnk(tp); { get array type }
            if tp^.t <> tgarry then error(einvfmt); { bad format }
            { discard pointer }
            emitbyt($58); { pop eax }
            { get length of string }
            emitbyt($58); { pop eax }
            { load base object size }
            emitbyt($b9); { mov ecx,size }
            emitint(tp^.gart^.size); { output base element size }
            { divide to find number of elements }
            emitbyt($33); { xor edx,edx }
            emitbyt($d2);
            emitbyt($f7); { div eax,ecx }
            emitbyt($f1);
            { place on stack }
            emitbyt($50); { push eax }
            stack := stack+4 { removes the pointer portion }

         end;
         inotint:  begin

            { get operand }
            emitbyt($58); { pop eax }
            { 'not' the bits }
            emitbyt($f7); { not eax }
            emitbyt($d0);
            { replace }
            emitbyt($50) { push eax }

         end;
         inotbol:  begin

            { get operand }
            emitbyt($58); { pop eax }
            { flip the first bit }
            emitbyt($35); { xor eax,1 }
            emitint(1);
            { replace }
            emitbyt($50) { push eax }

         end;
         isinset:  begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            { get operand }
            emitbyt($58); { pop eax }
            { check < 256 }
            emitbyt($3d); { cmp eax,256 }
            emitint(256);
            emitbyt($0f); { jb noerror }
            emitbyt($82);
            emitadr(srtstk^.lab, itradr); { place no error address }
            { generate error routine call }
            emitbyt($68); { push rerngchk }
            emitint(ord(rerngchk)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab^.addr := pgmcnt; { set jump over error location }
            { find set dword address }
            emitbyt($8b); { mov ebx,esp }
            emitbyt($dc);
            { set element }
            emitbyt($0f); { bts [ebx],eax }
            emitbyt($ab);
            emitbyt($03);
            popsrt; { remove structure level }
            stack := stack+stksiz { net is less one }

         end;
         irngset:  begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            gettypa(srtstk^.lab1, tlab); { set jump to error label }
            { get operands }
            emitbyt($59); { pop ecx }
            emitbyt($58); { pop eax }
            { check < 256 }
            emitbyt($3d); { cmp eax,256 }
            emitint(256);
            emitbyt($0f); { jae error }
            emitbyt($83);
            emitadr(srtstk^.lab1, itradr); { place error address }
            emitbyt($81); { cmp ecx,256 }
            emitbyt($f9);
            emitint(256);
            emitbyt($0f); { jb no error }
            emitbyt($82);
            emitadr(srtstk^.lab, itradr); { place no error address }
            { generate error routine call }
            srtstk^.lab1^.addr := pgmcnt; { set jump to error location }
            emitbyt($68); { push rerngchk }
            emitint(ord(rerngchk)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab^.addr := pgmcnt; { set jump over error location }
            { find bit set length }
            emitbyt($2b); { sub ecx,eax }
            emitbyt($c8);
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            { check 1st lower than 2nd, in which case the range is null }
            emitbyt($0f); { js over }
            emitbyt($88);
            emitadr(srtstk^.lab, itradr); { place jump over address }
            { adjust count }
            emitbyt($41); { inc ecx }
            { save starting bit }
            emitbyt($8b); { mov ebx,eax }
            emitbyt($d8);
            gettypa(srtstk^.lab1, tlab); { get loop label }
            srtstk^.lab1^.addr := pgmcnt; { set loop location }
            { find set dword address }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { set element }
            emitbyt($0f); { bts [eax],ebx }
            emitbyt($ab);
            emitbyt($18);
            { increment bit number }
            emitbyt($43); { inc ebx }
            { count off bits }
            emitbyt($49); { dec ecx }
            { loop next bit }
            emitbyt($0f); { jnz loop }
            emitbyt($85);
            emitadr(srtstk^.lab1, itradr); { place loop address }
            srtstk^.lab^.addr := pgmcnt; { set jump over location }
            popsrt; { remove structure level }
            stack := stack+(2*stksiz) { net is less two }

         end;
         icvtitr:  begin { convert integer to real }

            { get address of int on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load and convert to real }
            emitbyt($db); { fildd [eax] }
            emitbyt($00);
            { add space for real }
            emitbyt($83); { add esp,-4 }
            emitbyt($c4);
            emitbyt($ff-4+1);
            { index that }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { store real }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync the fpu store }
            emitbyt($9b); { fwait }
            stack := stack+intsiz-rlsiz { adjust stack }

         end; 
         icvtrtsr: begin { convert real to short real }

            { get address of real on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load to fpu }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { adjust back to short real }
            emitbyt($83); { add esp,4 }
            emitbyt($c4);
            emitbyt(4);
            { index that }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { store to destination short }
            emitbyt($d9); { fstps [eax] }
            emitbyt($18);
            { sync the fpu store }
            emitbyt($9b); { fwait }
            stack := stack+rlsiz-srlsiz { adjust stack }

         end; 
         icvtgtf:  begin

            getlnk(tp); { get fixed type }
            if (tp^.t <> tarray) and (tp^.t <> tscst) then
               error(einvfmt); { bad format }
            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            { get address }
            emitbyt($5b); { pop ebx }
            { get length }
            emitbyt($58); { pop eax }
            emitbyt($3d); { cmp eax,size }
            if tp^.t = tarray then emitint(tp^.size div tp^.arrt^.size) { general array }
            else emitint(tp^.size); { generate string size }
            emitbyt($0f); { je over }
            emitbyt($84);
            emitadr(srtstk^.lab, itradr); { place jump over address }
            { generate error routine call }
            emitbyt($68); { push relenmat }
            emitint(ord(relenmat)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab^.addr := pgmcnt; { set jump over error location }
            emitbyt($53); { push ebx }
            popsrt; { remove structure level }
            stack := stack+4 { pointer becomes simple }
            
         end;
         icvtftg:  begin

            getlnk(tp); { get fixed type }
            if (tp^.t <> tarray) and (tp^.t <> tscst) then
               error(einvfmt); { bad format }
            { get address }
            emitbyt($58); { pop eax }
            { place length on stack }
            emitbyt($68); { push size }
            if tp^.t = tarray then emitint(tp^.size div tp^.arrt^.size) { general array }
            else emitint(tp^.size); { generate string size }
            { replace address on stack }
            emitbyt($50); { push eax }
            stack := stack-4 { pointer becomes complex }
            
         end;
         icvtntg:  begin

            { just expand the nil to tagged pointer size }
            emitbyt($68); { push 0 }
            emitint(0);
            stack := stack-4 { pointer becomes complex }

         end;
         iswptop:  begin

            getlnk(tp); { get source }
            getlnk(tp1); { get destination }
            { swap is a problem, because one or both of the operands could be
              real, which are allways double length on the stack (even shorts).
              It could also be a tagged pointer over a normal pointer (a 
              special case of write). so we check and generate one of five swap
              types }
            if realt(tp) and realt(tp1) then begin { real with real }

               { get both operands }
               emitbyt($58); { pop eax }
               emitbyt($5b); { pop ebx }
               emitbyt($59); { pop ecx }
               emitbyt($5a); { pop edx }
               { push back in opposite order }
               emitbyt($53); { push ebx }
               emitbyt($50); { push eax }
               emitbyt($52); { push edx }
               emitbyt($51) { push ecx }

            end else if realt(tp) then begin { real with integer }

               { get both operands }
               emitbyt($58); { pop eax }
               emitbyt($5b); { pop ebx }
               emitbyt($59); { pop ecx }
               { push back in opposite order }
               emitbyt($50); { push eax }
               emitbyt($51); { push ecx }
               emitbyt($53) { push ebx }

            end else if realt(tp1) then begin { integer with real }

               { get both operands }
               emitbyt($58); { pop eax }
               emitbyt($5b); { pop ebx }
               emitbyt($59); { pop ecx }
               { push back in opposite order }
               emitbyt($53); { push ebx }
               emitbyt($50); { push eax }
               emitbyt($51) { push ecx }

            end else if tp^.t = tgarry then begin { tagged with integer }

               { get both operands }
               emitbyt($58); { pop eax }
               emitbyt($5b); { pop ebx }
               emitbyt($59); { pop ecx }
               { push back in opposite order }
               emitbyt($50); { push eax }
               emitbyt($51); { push ecx }
               emitbyt($53) { push ebx }

            end else begin

               { get both operands }
               emitbyt($58); { pop eax }
               emitbyt($5b); { pop ebx }
               { push back in opposite order }
               emitbyt($50); { push eax }
               emitbyt($53) { push ebx }

            end
            
         end;
         iintset:  begin { find set intersection }

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set loop label }
            { load 1st set address }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load 2nd set address }
            emitbyt($8b); { move ebx,esp }
            emitbyt($dc);
            emitbyt($83); { add ebx,setsiz }
            emitbyt($c3);
            emitbyt(setsiz);
            { set size of set in dwords }
            emitbyt($b9); { mov ecx,setsiz div 4 }
            emitint(setsiz div 4);
            srtstk^.lab^.addr := pgmcnt; { set loop location }
            { 'and' two dwords of the set together }
            emitbyt($8b); { mov edx,[eax] }
            emitbyt($10);
            emitbyt($21); { andd [ebx],edx }
            emitbyt($13);
            emitbyt($83); { add eax,4 }
            emitbyt($c0);
            emitbyt($04);
            emitbyt($83); { add ebx,4 }
            emitbyt($c3);
            emitbyt($04);
            emitbyt($49); { dec ecx }
            emitbyt($0f); { jnz loop }
            emitbyt($85);
            emitadr(srtstk^.lab, itradr); { place loop jump address }
            { remove tos from stack }
            emitbyt($83); { add esp,setsiz }
            emitbyt($c4);
            emitbyt(setsiz);
            popsrt; { remove structure level }
            stack := stack+setsiz { net less one set }

         end;
         imltrel:   begin

            { get address tos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load to fpu }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { get address sos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { multiply }
            emitbyt($dc); { fmuld [eax] }
            emitbyt($08);
            { store result }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync fpu }
            emitbyt($9b); { fwait }
            stack := stack+rlsiz { net is less one }

         end;
         imltint:  begin

            { load operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { multiply }
            emitbyt($f7); { imul ebx }
            emitbyt($eb);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+intsiz { net is less one }

         end;
         idivrel:   begin

            { get address tos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load to fpu }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { get address sos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { divide }
            emitbyt($dc); { fdivrd [eax] }
            emitbyt($38);
            { store result }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync fpu }
            emitbyt($9b); { fwait }
            stack := stack+rlsiz { net is less one }

         end;
         idivint:  begin

            { load operands }
            emitbyt($5b); { pop ebx }
            emitbyt($58); { pop eax }
            { extend divident to 64 bits }
            emitbyt($99); { cdq }
            { divide }
            emitbyt($f7); { idiv eax,ebx }
            emitbyt($fb);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+intsiz { net is less one }
      
         end;
         imodint:  begin

            { load operands }
            emitbyt($5b); { pop ebx }
            emitbyt($58); { pop eax }
            { extend divident to 64 bits }
            emitbyt($99); { cdq }
            { divide }
            emitbyt($f7); { idiv eax,ebx }
            emitbyt($fb);
            { place result }
            emitbyt($52); { push edx }
            stack := stack+intsiz { net is less one }

         end;
         iandint:  begin

            { load operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { and }
            emitbyt($23); { and eax,ebx }
            emitbyt($c3);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+intsiz { net is less one }

         end;
         inegint:  begin { Negate integer }

            { load operand }
            emitbyt($58); { pop eax }
            { negate }
            emitbyt($f7); { neg eax }
            emitbyt($d8);
            { place result }
            emitbyt($50) { push eax }
               
         end;
         inegrel:   begin { Negate real }

            { get address tos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load to fpu }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { negate }
            emitbyt($d9); { fchs }
            emitbyt($e0);
            { store result }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync fpu }
            emitbyt($9b) { fwait }

         end;
         iuniset:  begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set loop label }
            { load 1st set address }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load 2nd set address }
            emitbyt($8b); { move ebx,esp }
            emitbyt($dc);
            emitbyt($83); { add ebx,setsiz }
            emitbyt($c3);
            emitbyt(setsiz);
            { set size of set in dwords }
            emitbyt($b9); { mov ecx,setsiz div 4 }
            emitint(setsiz div 4);
            srtstk^.lab^.addr := pgmcnt; { set loop location }
            { 'or' two dwords of the set together }
            emitbyt($8b); { mov edx,[eax] }
            emitbyt($10);
            emitbyt($09); { ord [ebx],edx }
            emitbyt($13);
            emitbyt($83); { add eax,4 }
            emitbyt($c0);
            emitbyt($04);
            emitbyt($83); { add ebx,4 }
            emitbyt($c3);
            emitbyt($04);
            emitbyt($49); { dec ecx }
            emitbyt($0f); { jnz loop }
            emitbyt($85);
            emitadr(srtstk^.lab, itradr); { place loop jump address }
            { remove tos from stack }
            emitbyt($83); { add esp,setsiz }
            emitbyt($c4);
            emitbyt(setsiz);
            popsrt; { remove structure level }
            stack := stack+setsiz { net less one set }

         end;
         iaddrel:   begin { add real }

            { get address tos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load to fpu }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { get address sos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { add }
            emitbyt($dc); { faddd [eax] }
            emitbyt($00);
            { store result }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync fpu }
            emitbyt($9b); { fwait }
            stack := stack+rlsiz { net is less one }

         end;
         iaddint:  begin

            { load operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { multiply }
            emitbyt($03); { add eax,ebx }
            emitbyt($c3);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+intsiz { net is less one }

         end;
         idifset:  begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set loop label }
            { load 1st set address }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load 2nd set address }
            emitbyt($8b); { move ebx,esp }
            emitbyt($dc);
            emitbyt($83); { add ebx,setsiz }
            emitbyt($c3);
            emitbyt(setsiz);
            { set size of set in dwords }
            emitbyt($b9); { mov ecx,setsiz div 4 }
            emitint(setsiz div 4);
            srtstk^.lab^.addr := pgmcnt; { set loop location }
            { 'xor' two dwords of the set together }
            emitbyt($8b); { mov edx,[eax] }
            emitbyt($10);
            emitbyt($33); { xord edx,[ebx] }
            emitbyt($13);
            emitbyt($21); { andd [ebx],edx }
            emitbyt($13);
            emitbyt($83); { add eax,4 }
            emitbyt($c0);
            emitbyt($04);
            emitbyt($83); { add ebx,4 }
            emitbyt($c3);
            emitbyt($04);
            emitbyt($49); { dec ecx }
            emitbyt($0f); { jnz loop }
            emitbyt($85);
            emitadr(srtstk^.lab, itradr); { place loop jump address }
            { remove tos from stack }
            emitbyt($83); { add esp,setsiz }
            emitbyt($c4);
            emitbyt(setsiz);
            popsrt; { remove structure level }
            stack := stack+setsiz { net less one set }

         end;
         isubrel:   begin

            { get address tos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load to fpu }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { get address sos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { subtract }
            emitbyt($dc); { fsubrd [eax] }
            emitbyt($28);
            { store result }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync fpu }
            emitbyt($9b); { fwait }
            stack := stack+rlsiz { net is less one }

         end;
         isubint:  begin

            { load operands }
            emitbyt($5b); { pop ebx }
            emitbyt($58); { pop eax }
            { subtract }
            emitbyt($2b); { sub eax,ebx }
            emitbyt($c3);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+intsiz { net is less one }

         end;
         iorint:   begin

            { load operands }
            emitbyt($5b); { pop ebx }
            emitbyt($58); { pop eax }
            { 'or' }
            emitbyt($0b); { or eax,ebx }
            emitbyt($c3);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+intsiz { net is less one }

         end;
         ixorint:  begin

            { load operands }
            emitbyt($5b); { pop ebx }
            emitbyt($58); { pop eax }
            { 'xor' }
            emitbyt($33); { xor eax,ebx }
            emitbyt($c3);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+intsiz { net is less one }

         end;
         iincset:   begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            gettypa(srtstk^.lab1, tlab); { set exit label }
            { get operand from over set }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            emitbyt($83); { add eax,setsiz }
            emitbyt($c0);
            emitbyt(setsiz);
            emitbyt($8b); { mov eax,[eax] }
            emitbyt($00);
            { check < 256 }
            emitbyt($3d); { cmp eax,256 }
            emitint(256);
            emitbyt($0f); { jb noerror }
            emitbyt($82);
            emitadr(srtstk^.lab, itradr); { place no error address }
            { set false for out of range }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($e9); { jmp addr }
            emitadr(srtstk^.lab1, itradr);
            srtstk^.lab^.addr := pgmcnt; { set jump over error location }
            { find set dword address }
            emitbyt($8b); { mov ebx,esp }
            emitbyt($dc);
            { test element }
            emitbyt($0f); { bt [ebx],eax }
            emitbyt($a3);
            emitbyt($03);
            { convert carry flag to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setc al }
            emitbyt($92);
            emitbyt($c0);
            srtstk^.lab1^.addr := pgmcnt; { set jump over error location }
            { remove tos from stack }
            emitbyt($83); { add esp,setsiz+intsiz }
            emitbyt($c4);
            emitbyt(setsiz+intsiz);
            { place result }
            emitbyt($50); { push eax }
            popsrt; { remove structure level }
            stack := stack+setsiz { net is less one }

         end;
         iequset:  begin

            { load 1st set address }
            emitbyt($8b); { move edi,esp }
            emitbyt($fc);
            { load 2nd set address }
            emitbyt($8b); { move esi,esp }
            emitbyt($f4);
            emitbyt($83); { add esi,setsiz }
            emitbyt($c6);
            emitbyt(setsiz);
            { get size of set }
            emitbyt($b9); { mov ecx,setsiz }
            emitint(setsiz);
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { sete al }
            emitbyt($94);
            emitbyt($c0);
            { remove both from stack }
            emitbyt($83); { add esp,setsiz*2 }
            emitbyt($c4);
            emitbyt(setsiz*2);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+(2*setsiz)-bolsiz { adjust stack }

         end;
         iequrel:   begin

            { get address tos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load to fpu }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { get address sos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { compare }
            emitbyt($dc); { fcompd [eax] }
            emitbyt($18);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { transfer fpu flags to integer unit flags }
            emitbyt($df); { fnstsw ax }
            emitbyt($e0);
            emitbyt($9e); { sahf }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { sete al }
            emitbyt($94);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+(2*rlsiz)-bolsiz { net is less one }

         end;
         iequstr:  begin

            getlnk(tp); { get string type }
            { load operands }
            emitbyt($5f); { pop edi }
            emitbyt($5e); { pop esi }
            emitbyt($b9); { mov ecx,size }
            emitint(tp^.size); { generate string size }
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { sete al }
            emitbyt($94);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+stksiz { net is less one }

         end;
         iequgst:  begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            { load both operands }
            emitbyt($5f); { pop edi }
            emitbyt($58); { pop eax }
            emitbyt($5e); { pop esi }
            emitbyt($59); { pop ecx }
            { check lengths equal }
            emitbyt($3b); { cmp eax,ecx }
            emitbyt($c1);
            emitbyt($0f); { je noerror }
            emitbyt($84);
            emitadr(srtstk^.lab, itradr); { place no error address }
            { generate error routine call }
            emitbyt($68); { push rerngchk }
            emitint(ord(relenmat)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab^.addr := pgmcnt; { set jump over error location }
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { sete al }
            emitbyt($94);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            popsrt; { remove structure level }
            { set two tagged pointers replaced by boolean }
            stack := stack+tgpsiz+tgpsiz-bolsiz

         end;
         iequint:  begin

            { load operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { compare }
            emitbyt($3b); { cmp eax,ebx }
            emitbyt($c3);
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { sete al }
            emitbyt($94);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+stksiz { net is less one }

         end;
         iequtgp:  begin

            { load operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            emitbyt($59); { pop ecx }
            emitbyt($5a); { pop edx }
            { compare }
            emitbyt($3b); { cmp eax,ecx }
            emitbyt($c1);
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { sete al }
            emitbyt($94);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+(2*tgpsiz)-bolsiz { adjust stack }

         end;
         ineqset:  begin

            { load 1st set address }
            emitbyt($8b); { move edi,esp }
            emitbyt($fc);
            { load 2nd set address }
            emitbyt($8b); { move esi,esp }
            emitbyt($f4);
            emitbyt($83); { add esi,setsiz }
            emitbyt($c6);
            emitbyt(setsiz);
            { get size of set }
            emitbyt($b9); { mov ecx,setsiz }
            emitint(setsiz);
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setne al }
            emitbyt($95);
            emitbyt($c0);
            { remove both from stack }
            emitbyt($83); { add esp,setsiz*2 }
            emitbyt($c4);
            emitbyt(setsiz*2);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+(2*setsiz)-bolsiz { adjust stack }

         end;
         ineqrel:   begin

            { get address tos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load to fpu }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { get address sos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { compare }
            emitbyt($dc); { fcompd [eax] }
            emitbyt($18);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { transfer fpu flags to integer unit flags }
            emitbyt($df); { fnstsw ax }
            emitbyt($e0);
            emitbyt($9e); { sahf }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setne al }
            emitbyt($95);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+(2*rlsiz)-bolsiz { net is less one }

         end;
         ineqstr:  begin

            getlnk(tp); { get string type }
            { load operands }
            emitbyt($5f); { pop edi }
            emitbyt($5e); { pop esi }
            emitbyt($b9); { mov ecx,size }
            emitint(tp^.size); { generate string size }
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setne al }
            emitbyt($95);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+stksiz { net is less one }

         end;
         ineqgst:  begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            { load both operands }
            emitbyt($5f); { pop edi }
            emitbyt($58); { pop eax }
            emitbyt($5e); { pop esi }
            emitbyt($59); { pop ecx }
            { check lengths equal }
            emitbyt($3b); { cmp eax,ecx }
            emitbyt($c1);
            emitbyt($0f); { je noerror }
            emitbyt($84);
            emitadr(srtstk^.lab, itradr); { place no error address }
            { generate error routine call }
            emitbyt($68); { push rerngchk }
            emitint(ord(relenmat)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab^.addr := pgmcnt; { set jump over error location }
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setne al }
            emitbyt($95);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            popsrt; { remove structure level }
            { set two tagged pointers replaced by boolean }
            stack := stack+tgpsiz+tgpsiz-bolsiz

         end;
         ineqint:  begin

            { load operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { compare }
            emitbyt($3b); { cmp eax,ebx }
            emitbyt($c3);
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setne al }
            emitbyt($95);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+stksiz { net is less one }

         end;
         ineqtgp:  begin

            { load operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            emitbyt($59); { pop ecx }
            emitbyt($5a); { pop edx }
            { compare }
            emitbyt($3b); { cmp eax,ecx }
            emitbyt($c1);
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setne al }
            emitbyt($95);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+(2*tgpsiz)-bolsiz { adjust stack }

         end;
         ileqset:  begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set loop label }
            { load 1st set address }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load 2nd set address }
            emitbyt($8b); { move ebx,esp }
            emitbyt($dc);
            emitbyt($83); { add ebx,setsiz }
            emitbyt($c3);
            emitbyt(setsiz);
            { set size of set in dwords }
            emitbyt($b9); { mov ecx,setsiz div 4 }
            emitint(setsiz div 4);
            { clear flag }
            emitbyt($33); { xor edi,edi } 
            emitbyt($ff);
            srtstk^.lab^.addr := pgmcnt; { set loop location }
            { 'xor' two dwords of the set together }
            emitbyt($8b); { mov edx,[eax] }
            emitbyt($10);
            emitbyt($23); { and edx,[ebx] }
            emitbyt($13);
            emitbyt($33); { xor edx,[ebx] }
            emitbyt($13);
            emitbyt($0b); { or edi,edx }
            emitbyt($fa);
            emitbyt($83); { add eax,4 }
            emitbyt($c0);
            emitbyt($04);
            emitbyt($83); { add ebx,4 }
            emitbyt($c3);
            emitbyt($04);
            emitbyt($49); { dec ecx }
            emitbyt($0f); { jnz loop }
            emitbyt($85);
            emitadr(srtstk^.lab, itradr); { place loop jump address }
            { remove both from stack }
            emitbyt($83); { add esp,setsiz*2 }
            emitbyt($c4);
            emitbyt(setsiz*2);
            { test result }
            emitbyt($0b); { or edi,edi }
            emitbyt($ff);
            { convert status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { sete al }
            emitbyt($94);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            popsrt; { remove structure level }
            stack := stack+(2*setsiz)-stksiz { lost two sets, add boolean }

         end;
         ileqrel:   begin

            { get address tos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load to fpu }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { get address sos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { compare }
            emitbyt($dc); { fcompd [eax] }
            emitbyt($18);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { transfer fpu flags to integer unit flags }
            emitbyt($df); { fnstsw ax }
            emitbyt($e0);
            emitbyt($9e); { sahf }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setnb al }
            emitbyt($93);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+(2*rlsiz)-bolsiz { net is less one }

         end;
         ileqstr:  begin

            getlnk(tp); { get string type }
            { load operands }
            emitbyt($5f); { pop edi }
            emitbyt($5e); { pop esi }
            emitbyt($b9); { mov ecx,size }
            emitint(tp^.size); { generate string size }
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setbe al }
            emitbyt($96);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+stksiz { net is less one }

         end;
         ileqgst:  begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            { load both operands }
            emitbyt($5f); { pop edi }
            emitbyt($58); { pop eax }
            emitbyt($5e); { pop esi }
            emitbyt($59); { pop ecx }
            { check lengths equal }
            emitbyt($3b); { cmp eax,ecx }
            emitbyt($c1);
            emitbyt($0f); { je noerror }
            emitbyt($84);
            emitadr(srtstk^.lab, itradr); { place no error address }
            { generate error routine call }
            emitbyt($68); { push rerngchk }
            emitint(ord(relenmat)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab^.addr := pgmcnt; { set jump over error location }
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setbe al }
            emitbyt($96);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            popsrt; { remove structure level }
            { set two tagged pointers replaced by boolean }
            stack := stack+tgpsiz+tgpsiz-bolsiz

         end;
         ileqint:  begin

            { load operands }
            emitbyt($5b); { pop ebx }
            emitbyt($58); { pop eax }
            { compare }
            emitbyt($3b); { cmp eax,ebx }
            emitbyt($c3);
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setle al }
            emitbyt($9e);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+stksiz { net is less one }

         end;
         igeqset:  begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set loop label }
            { load 1st set address }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load 2nd set address }
            emitbyt($8b); { move ebx,esp }
            emitbyt($dc);
            emitbyt($83); { add ebx,setsiz }
            emitbyt($c3);
            emitbyt(setsiz);
            { set size of set in dwords }
            emitbyt($b9); { mov ecx,setsiz div 4 }
            emitint(setsiz div 4);
            { clear flag }
            emitbyt($33); { xor edi,edi } 
            emitbyt($ff);
            srtstk^.lab^.addr := pgmcnt; { set loop location }
            { 'xor' two dwords of the set together }
            emitbyt($8b); { mov edx,[eax] }
            emitbyt($10);
            emitbyt($23); { and edx,[ebx] }
            emitbyt($13);
            emitbyt($33); { xor edx,[eax] }
            emitbyt($10);
            emitbyt($0b); { or edi,edx }
            emitbyt($fa);
            emitbyt($83); { add eax,4 }
            emitbyt($c0);
            emitbyt($04);
            emitbyt($83); { add ebx,4 }
            emitbyt($c3);
            emitbyt($04);
            emitbyt($49); { dec ecx }
            emitbyt($0f); { jnz loop }
            emitbyt($85);
            emitadr(srtstk^.lab, itradr); { place loop jump address }
            { remove both from stack }
            emitbyt($83); { add esp,setsiz*2 }
            emitbyt($c4);
            emitbyt(setsiz*2);
            { test result }
            emitbyt($0b); { or edi,edi }
            emitbyt($ff);
            { convert status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { sete al }
            emitbyt($94);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            popsrt; { remove structure level }
            stack := stack+(2*setsiz)-stksiz { lost two sets, add boolean }

         end;
         igeqrel:   begin

            { get address tos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load to fpu }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { get address sos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { compare }
            emitbyt($dc); { fcompd [eax] }
            emitbyt($18);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { transfer fpu flags to integer unit flags }
            emitbyt($df); { fnstsw ax }
            emitbyt($e0);
            emitbyt($9e); { sahf }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setna al }
            emitbyt($96);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+(2*rlsiz)-bolsiz { net is less one }

         end;
         igeqstr:  begin

            getlnk(tp); { get string type }
            { load operands }
            emitbyt($5f); { pop edi }
            emitbyt($5e); { pop esi }
            emitbyt($b9); { mov ecx,size }
            emitint(tp^.size); { generate string size }
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setae al }
            emitbyt($93);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+stksiz { net is less one }

         end;
         igeqgst:  begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            { load both operands }
            emitbyt($5f); { pop edi }
            emitbyt($58); { pop eax }
            emitbyt($5e); { pop esi }
            emitbyt($59); { pop ecx }
            { check lengths equal }
            emitbyt($3b); { cmp eax,ecx }
            emitbyt($c1);
            emitbyt($0f); { je noerror }
            emitbyt($84);
            emitadr(srtstk^.lab, itradr); { place no error address }
            { generate error routine call }
            emitbyt($68); { push rerngchk }
            emitint(ord(relenmat)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab^.addr := pgmcnt; { set jump over error location }
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setae al }
            emitbyt($93);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            popsrt; { remove structure level }
            { set two tagged pointers replaced by boolean }
            stack := stack+tgpsiz+tgpsiz-bolsiz

         end;
         igeqint:  begin

            { load operands }
            emitbyt($5b); { pop ebx }
            emitbyt($58); { pop eax }
            { compare }
            emitbyt($3b); { cmp eax,ebx }
            emitbyt($c3);
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setle al }
            emitbyt($9d);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+stksiz { net is less one }

         end;
         iltnrel:   begin

            { get address tos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load to fpu }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { get address sos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { compare }
            emitbyt($dc); { fcompd [eax] }
            emitbyt($18);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { transfer fpu flags to integer unit flags }
            emitbyt($df); { fnstsw ax }
            emitbyt($e0);
            emitbyt($9e); { sahf }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { seta al }
            emitbyt($97);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+(2*rlsiz)-bolsiz { net is less one }

         end;
         iltnstr:  begin

            getlnk(tp); { get string type }
            { load operands }
            emitbyt($5f); { pop edi }
            emitbyt($5e); { pop esi }
            emitbyt($b9); { mov ecx,size }
            emitint(tp^.size); { generate string size }
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setb al }
            emitbyt($92);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+stksiz { net is less one }

         end;
         iltngst:  begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            { load both operands }
            emitbyt($5f); { pop edi }
            emitbyt($58); { pop eax }
            emitbyt($5e); { pop esi }
            emitbyt($59); { pop ecx }
            { check lengths equal }
            emitbyt($3b); { cmp eax,ecx }
            emitbyt($c1);
            emitbyt($0f); { je noerror }
            emitbyt($84);
            emitadr(srtstk^.lab, itradr); { place no error address }
            { generate error routine call }
            emitbyt($68); { push rerngchk }
            emitint(ord(relenmat)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab^.addr := pgmcnt; { set jump over error location }
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setb al }
            emitbyt($92);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            popsrt; { remove structure level }
            { set two tagged pointers replaced by boolean }
            stack := stack+tgpsiz+tgpsiz-bolsiz

         end;
         iltnint:  begin

            { load operands }
            emitbyt($5b); { pop ebx }
            emitbyt($58); { pop eax }
            { compare }
            emitbyt($3b); { cmp eax,ebx }
            emitbyt($c3);
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setl al }
            emitbyt($9c);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+stksiz { net is less one }

         end;
         igtnrel:   begin

            { get address tos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load to fpu }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { get address sos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { compare }
            emitbyt($dc); { fcompd [eax] }
            emitbyt($18);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { transfer fpu flags to integer unit flags }
            emitbyt($df); { fnstsw ax }
            emitbyt($e0);
            emitbyt($9e); { sahf }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setb al }
            emitbyt($92);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+(2*rlsiz)-bolsiz { net is less one }

         end;
         igtnstr:  begin

            getlnk(tp); { get string type }
            { load operands }
            emitbyt($5f); { pop edi }
            emitbyt($5e); { pop esi }
            emitbyt($b9); { mov ecx,size }
            emitint(tp^.size); { generate string size }
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { seta al }
            emitbyt($97);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+stksiz { net is less one }

         end;
         igtngst:  begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            { load both operands }
            emitbyt($5f); { pop edi }
            emitbyt($58); { pop eax }
            emitbyt($5e); { pop esi }
            emitbyt($59); { pop ecx }
            { check lengths equal }
            emitbyt($3b); { cmp eax,ecx }
            emitbyt($c1);
            emitbyt($0f); { je noerror }
            emitbyt($84);
            emitadr(srtstk^.lab, itradr); { place no error address }
            { generate error routine call }
            emitbyt($68); { push rerngchk }
            emitint(ord(relenmat)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab^.addr := pgmcnt; { set jump over error location }
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setb al }
            emitbyt($97);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            popsrt; { remove structure level }
            { set two tagged pointers replaced by boolean }
            stack := stack+tgpsiz+tgpsiz-bolsiz

         end;
         igtnint:  begin

            { load operands }
            emitbyt($5b); { pop ebx }
            emitbyt($58); { pop eax }
            { compare }
            emitbyt($3b); { cmp eax,ebx }
            emitbyt($c3);
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setg al }
            emitbyt($9f);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+stksiz { net is less one }

         end;
         ibgnblk:  ; { begin statement block. not used }
         iendblk:  ; { end statement block. not used }
         iifbgn:   begin { if }

            { 'if' is converted to jumps }
            pushsrt; { add new structure level }
            gettypa(srtstk^.lab, tlab); { get a label type for false destination }
            { load boolean }
            emitbyt($58); { pop eax }
            { place in flags }
            emitbyt($0b); { or eax,eax }
            emitbyt($c0);
            { jump false }
            emitbyt($0f); { jz addr }
            emitbyt($84);
            emitadr(srtstk^.lab, itradr); { place address }
            stack := stack+stksiz { net is less one }

         end;
         ielse:    begin

            tp := srtstk^.lab; { save false destination }
            gettypa(srtstk^.lab, tlab); { get a label type for true destination }
            { output jump over for 'if' first part }
            emitbyt($e9); { jmp addr }
            emitadr(srtstk^.lab, itradr);
            tp^.addr := pgmcnt { place address of 'if' skip }

         end;
         iifend:   begin

            srtstk^.lab^.addr := pgmcnt; { place address of 'if' or 'else' skip }
            popsrt { remove structure level }

         end;
         icasbgn:  begin { case begin }

            { 'case' is converted to jumps }
            pushsrt; { add new structure level }
            gettypa(srtstk^.lab, tlab); { get a label for exit }
            srtstk^.lab1 := nil { clear skip label }
            
         end;
         icassint:  begin { case select integer }

            rdnum(v); { get case selector constant }
            { load selector, but leave on stack }
            emitbyt($58); { pop eax }
            emitbyt($50); { push eax }
            { compare to case label }
            emitbyt($3d); { cmp eax,imm }
            emitint(v); { place value }
            if srtstk^.lab1 = nil then { skip label is not already defined }
               gettypa(srtstk^.lab1, tlab); { get a label for skip }
            { jump to statement if equal }
            emitbyt($0f); { je addr }
            emitbyt($84);
            emitadr(srtstk^.lab1, itradr)

         end;
         icasstb:  begin { case statement begin }

            gettypa(srtstk^.lab2, tlab); { get a jump over }
            { jump to next case }
            emitbyt($e9); { jmp addr }
            emitadr(srtstk^.lab2, itradr); { generate address }
            srtstk^.lab1^.addr := pgmcnt; { set location of jump to statment }
            srtstk^.lab1 := nil { release skip label }

         end;
         icasste:  begin { case statement end }

            { jump to exit }
            emitbyt($e9); { jmp addr }
            emitadr(srtstk^.lab, itradr); { generate address }
            srtstk^.lab2^.addr := pgmcnt { set location of jump over }

         end;
         icasend:  begin { case end }

            { generate error routine call for missed case }
            emitbyt($68); { push rerngchk }
            emitint(ord(recasvnf)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab^.addr := pgmcnt; { place address of case exit }
            { generate pop of case selector }
            emitbyt($58); { pop eax }
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
            emitbyt($58); { pop eax }
            { jump if false }
            emitbyt($0b); { or eax,eax }
            emitbyt($c0);
            emitbyt($0f); { jz addr }
            emitbyt($84);
            emitadr(srtstk^.lab1, itradr); { to skip label }
            stack := stack+stksiz { net is less one }

         end;
         iwhlend:  begin { While end }

            { jump to loop label }
            emitbyt($e9); { jmp addr }
            emitadr(srtstk^.lab, itradr); { generate address }
            srtstk^.lab1^.addr := pgmcnt; { place address of skip }
            popsrt { remove structure level }

         end;
         irptbgn:  begin { Repeat begin }

            { repeat is converted to jumps }
            pushsrt; { add new structure level }
            gettypa(srtstk^.lab, tlab); { get label for loop jump }
            srtstk^.lab^.addr := pgmcnt { set location }

         end;            
         irptend:  begin { Repeat end }

            emitbyt($58); { pop eax }
            { jump to loop label if false }
            emitbyt($0b); { or eax,eax }
            emitbyt($c0);
            emitbyt($0f); { jz addr }
            emitbyt($84);
            emitadr(srtstk^.lab, itradr); { generate address }
            popsrt; { remove structure level }
            stack := stack+stksiz { net is less one }

         end;
         ifortint, ifortchr, ifortbol, ifordint, ifordchr,
         ifordbol:  begin { for loop }

            pushsrt; { start new structure level } 
            srtstk^.ic := ic; { save head type }
            getlnk(tp); { get variable }
            { get start and end }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { save end on stack }
            emitbyt($50); { push eax }
            { load address of variable }
            if tp^.local then begin { local address }

               { get the display }
               emitbyt($8b); { mov ecx,ebp }
               emitbyt($cd);
               { offset to local }
               emitbyt($81); { add ecx,imm }
               emitbyt($c1);
               emitint(tp^.addr) { place offset address }

            end else begin { load global address }

               { load global address }
               emitbyt($b9); { mov ecx,imm }
               emitadr(tp, itadr) { place address }

            end;
            { store integer to control variable }
            if tp^.size = 4 then begin { full integer }

               emitbyt($89); { mov [ecx],ebx }
               emitbyt($19)

            end else if tp^.size = 2 then begin

               emitbyt($66); { mov [ecx],bx }
               emitbyt($89);
               emitbyt($19)

            end else if tp^.size = 1 then begin

               emitbyt($88); { mov [ecx],al }
               emitbyt($19)

            end else error(einvfmt); { bad size }
            gettypa(srtstk^.lab1, tlab); { get label for skip }
            { compare to end value }
            emitbyt($3b); { cmp eax,ebx }
            emitbyt($c3);
            if ic in [ifortint, ifortchr, ifortbol] then begin { to }

               emitbyt($0f); { jl end }
               emitbyt($8c)
            
            end else begin { downto }

               emitbyt($0f); { jg end }
               emitbyt($8f)

            end;
            emitadr(srtstk^.lab1, itradr); { to skip label }
            srtstk^.lab2 := tp; { save variable }
            gettypa(srtstk^.lab, tlab); { get label for loop jump }
            srtstk^.lab^.addr := pgmcnt; { set location }
            stack := stack+stksiz { net is less one }

         end;
         iforend:  begin { For end }

            tp := srtstk^.lab2; { get control variable }
            { get end value and leave on stack }
            emitbyt($5b); { pop ebx }
            emitbyt($53); { push ebx }
            { load address of variable }
            if tp^.local then begin { local address }

               { get the display }
               emitbyt($8b); { mov ecx,ebp }
               emitbyt($cd);
               { offset to local }
               emitbyt($81); { add ecx,imm }
               emitbyt($c1);
               emitint(tp^.addr) { place offset address }

            end else begin { load global address }

               { load global address }
               emitbyt($b9); { mov ecx,imm }
               emitadr(tp, itadr) { place address }

            end;
            { load variable value }
            if tp^.size = 4 then begin { integer }

               emitbyt($8b); { mov eax,[ecx] }
               emitbyt($01)

            end else if tp^.size = 2 then begin { word }

               if chksgn(tp) then begin { signed }

                  emitbyt($0f); { movsxw eax,[ecx] }
                  emitbyt($bf);
                  emitbyt($01)

               end else begin { unsigned }

                  emitbyt($0f); { movzxw eax,[ecx] }
                  emitbyt($b7);
                  emitbyt($01)

               end

            end else if tp^.size = 1 then begin { byte }

               if chksgn(tp) then begin { signed }

                  emitbyt($0f); { movsxb eax,[ecx] }
                  emitbyt($be);
                  emitbyt($01)

               end else begin { unsigned }

                  emitbyt($0f); { movzxb eax,[ecx] }
                  emitbyt($b6);
                  emitbyt($01)

               end

            end else error(einvfmt); { invalid format }
            { compare to end value }
            emitbyt($3b); { cmp eax,ebx }
            emitbyt($c3);
            if srtstk^.ic in [ifortint, ifortchr, ifortbol] then begin { to }

               emitbyt($0f); { jnl end }
               emitbyt($8d)
            
            end else begin { downto }

               emitbyt($0f); { jng end }
               emitbyt($8e)

            end;
            emitadr(srtstk^.lab1, itradr); { to skip label }
            { find next value }
            if tp^.size = 4 then begin { integer }

               if srtstk^.ic in [ifortint, ifortchr, ifortbol] then begin

                  { to }
                  emitbyt($ff); { incd [ecx] }
                  emitbyt($01)

               end else begin { downto }

                  emitbyt($ff); { decd [ecx] }
                  emitbyt($09)

               end

            end else if tp^.size = 2 then begin { word }

               if srtstk^.ic in [ifortint, ifortchr, ifortbol] then begin

                  { to }
                  emitbyt($66); { incw [ecx] }
                  emitbyt($ff);
                  emitbyt($01)

               end else begin { downto }

                  emitbyt($66); { decw [ecx] }
                  emitbyt($ff);
                  emitbyt($09)

               end

            end else if tp^.size = 1 then begin { byte }

               if srtstk^.ic in [ifortint, ifortchr, ifortbol] then begin

                  { to }
                  emitbyt($fe); { incb [ecx] }
                  emitbyt($01)

               end else begin { downto }

                  emitbyt($fe); { decb [ecx] }
                  emitbyt($09)

               end

            end else error(einvfmt); { bad size }
            { jump to loop label }
            emitbyt($e9); { jmp loop }
            emitadr(srtstk^.lab, itradr);
            srtstk^.lab1^.addr := pgmcnt; { place address of skip }
            { purge end value }
            emitbyt($58); { pop eax }
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
            
            { remove base address }
            emitbyt($58); { pop eax }
            popsrt; { remove structure level }
            stack := stack+stksiz { adjust stack }

         end;
         igoto:    begin { goto }

            getlnk(tp); { get label to jump to }
            { load stack from target display }
            { get display for target level }
            if tp^.lmrk^.t = tglbl then begin

               { on main blocks, we use the saved display, since there is no
                 way to find the original display for that block }
               emitbyt($8b); { mov eax,[dispsav] }
               emitbyt($05);
               emitadr(tp^.lmrk^.ds, itadr) { place display save address }

            end else begin { normal block }

               emitbyt($8b); { mov eax,[ebp-lvl] }
               emitbyt($85);
               emitint(-((tp^.level-1)*4)); { offset to proper display level }

            end;
            { load target ebp from display }
            emitbyt($8b); { move ebp,eax }
            emitbyt($e8);
            { offset to local }
            emitbyt($05); { add eax,imm }
            { offset by mark type }
            if tp^.lmrk^.t = tglbl then emitint(-((tp^.level-1)*4))
            else if tp^.lmrk^.t = tproc then emitint(-((tp^.level-1)*4+tp^.lmrk^.prcv))
            else if tp^.lmrk^.t = tfunc then emitint(-((tp^.level-1)*4+tp^.lmrk^.fncv))
            else error(esysflt6); { bad }
            emitbyt($8b); { mov esp,eax }
            emitbyt($e0);
            emitbyt($e9); { jmp label }
            emitadr(tp, itradr) { generate code address }

         end;
         iprcbgn:   getlnk(tp); { get and discard procedure entry }
         iprccal:   begin

            getlnk(tp); { get procedure entry }
            if tp^.t <> tproc then error(einvfmt); { bad format }
            tp^.prcr := true; { set referenced }
            { call procedure }
            emitbyt($e8); { call addr }
            emitadr(tp, itradr); { generate address }
            stack := stack+tp^.prca { remove parameters from stack }

         end;
         iprccali:  begin

            getlnk(tp); { get procedure entry }
            if tp^.t <> tpproc then error(einvfmt); { bad format }
            { call procedure indirect }
            emitbyt($58); { pop eax }
            emitbyt($ff); { call eax }
            emitbyt($d0);
            stack := stack+tp^.ppra+stksiz { remove parameters from stack }

         end;
         ifncbgn:   begin

            getlnk(tp); { get function entry }
            { link function result }
            if tp^.t = tfunc then tp := tp^.fncr
            else if tp^.t = tpfunc then tp := tp^.pfnr
            else error(einvfmt); { bad entry type }
            { place dummy function result }
            emitbyt($68); { push 0 }
            emitint(0);
            stack := stack-stksiz; { add result to stack }
            if tp^.size > stksiz then begin { real or complex pointer }

               emitbyt($68); { push 0 }
               emitint(0);
               stack := stack-stksiz { add result to stack }

            end;

         end;
         ifnccal:   begin

            getlnk(tp); { get function entry }
            if tp^.t <> tfunc then error(einvfmt); { bad format }
            tp^.fnct := true; { set referenced }
            { call function }
            emitbyt($e8); { call addr }
            emitadr(tp, itradr); { generate address }
            stack := stack+tp^.fnca { remove parameters from stack }

         end;
         ifnccali:  begin

            getlnk(tp); { get function entry }
            if tp^.t <> tpfunc then error(einvfmt); { bad format }
            { call function indirect }
            emitbyt($58); { pop eax }
            emitbyt($ff); { call eax }
            emitbyt($d0);
            stack := stack+tp^.pfna+stksiz { remove parameters from stack }

         end;
         iwrtsrc:   begin

            getlnk(tp); { get variable type }
            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { place copy of the file on stack }
            emitbyt($53); { push ebx }
            { place file }
            emitbyt($53); { push ebx }
            { place length on stack }
            emitbyt($68); { push size }
            emitint(tp^.size);
            { place address }
            emitbyt($50); { push eax }
            { call file write routine }
            emitbyt($e8); { call ps_wrtfil }
            emitadr(pswrtfil, itradr); { output routine address }
            pswrtfil^.rotr := true; { set referenced }
            stack := stack+stksiz { net is less one }

         end;
         iwrtintt:   begin

            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { place copy of the file on stack }
            emitbyt($53); { push ebx }
            { replace operands }
            emitbyt($53); { push ebx }
            { place standard integer field }
            emitbyt($68); { push intfld }
            emitint(intfld);
            emitbyt($50); { push eax }
            { call integer write routine }
            emitbyt($e8); { call ps_wrtint }
            emitadr(pswrtint, itradr); { output routine address }
            pswrtint^.rotr := true; { set referenced }
            stack := stack+stksiz { net is less one }

         end;
         iwrtchrt:   begin

            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { place copy of the file on stack }
            emitbyt($53); { push ebx }
            { replace operands }
            emitbyt($53); { push ebx }
            { place standard character field }
            emitbyt($68); { push chrfld }
            emitint(chrfld);
            emitbyt($50); { push eax }
            { call character write routine }
            emitbyt($e8); { call ps_wrtchr }
            emitadr(pswrtchr, itradr); { output routine address }
            pswrtchr^.rotr := true; { set referenced }
            stack := stack+stksiz { net is less one }

         end;
         iwrtbolt:   begin

            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { place copy of the file on stack }
            emitbyt($53); { push ebx }
            { replace operands }
            emitbyt($53); { push ebx }
            emitbyt($50); { push eax }
            { call boolean write routine }
            emitbyt($e8); { call ps_wrtbol }
            emitadr(pswrtbol, itradr); { output routine address }
            pswrtbol^.rotr := true; { set referenced }
            stack := stack+stksiz { net is less one }

         end;
         iwrtrelt:    begin

            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            emitbyt($59); { pop ecx }
            { place copy of the file on stack }
            emitbyt($51); { push ecx }
            { replace operands }
            emitbyt($51); { push ecx }
            { place standard real field }
            emitbyt($68); { push rlfld }
            emitint(rlfld);
            emitbyt($53); { push ebx }
            emitbyt($50); { push eax }
            { call real write routine }
            emitbyt($e8); { call ps_wrtreal }
            emitadr(pswrtreal, itradr); { output routine address }
            pswrtreal^.rotr := true; { set referenced }
            stack := stack+rlsiz { net is less one }

         end;
         iwrtstrt:   begin { write string }

            getlnk(tp); { get string type }
            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { place copy of the file on stack }
            emitbyt($53); { push ebx }
            { replace operands }
            emitbyt($53); { push ebx }
            { place length of string as tag length }
            emitbyt($68); { push len }
            emitint(tp^.size);
            emitbyt($50); { push eax }
            { call string write routine }
            emitbyt($e8); { call ps_wrtstr }
            emitadr(pswrtstr, itradr); { output routine address }
            pswrtstr^.rotr := true; { set referenced }
            stack := stack+stksiz { net is less one }

         end;
         iwrtgstt:   begin { write string }

            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            emitbyt($59); { pop ecx }
            { place copy of the file on stack }
            emitbyt($51); { push ecx }
            { replace operands }
            emitbyt($51); { push ecx } 
            emitbyt($53); { push ebx }
            emitbyt($50); { push eax }
            { call string write routine }
            emitbyt($e8); { call ps_wrtstr }
            emitadr(pswrtstr, itradr); { output routine address }
            pswrtstr^.rotr := true; { set referenced }
            stack := stack+tgpsiz { net is less one }

         end;
         iwrtintft:  begin

            { load operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            emitbyt($59); { pop ecx }
            { place copy of the file on stack }
            emitbyt($51); { push ecx }
            { replace operands, reversing field and integer }
            emitbyt($51); { push ecx }
            emitbyt($50); { push eax }
            emitbyt($53); { push ebx }
            { call integer write routine }
            emitbyt($e8); { call ps_wrtreal }
            emitadr(pswrtint, itradr); { output routine address }
            pswrtint^.rotr := true; { set referenced }
            stack := stack+(2*stksiz) { net is less two }

         end;
         iwrtchrft:  begin

            { load operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            emitbyt($59); { pop ecx }
            { place copy of the file on stack }
            emitbyt($51); { push ecx }
            { replace operands, reversing field and character }
            emitbyt($51); { push ecx }
            emitbyt($50); { push eax }
            emitbyt($53); { push ebx }
            { call character write routine }
            emitbyt($e8); { call ps_wrtchr }
            emitadr(pswrtchr, itradr); { output routine address }
            pswrtchr^.rotr := true; { set referenced }
            stack := stack+(2*stksiz) { net is less two }

         end;
         iwrtbolft:  begin

            { load operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            emitbyt($59); { pop ecx }
            { place copy of the file on stack }
            emitbyt($51); { push ecx }
            { replace operands, reversing field and boolean }
            emitbyt($51); { push ecx }
            emitbyt($50); { push eax }
            emitbyt($53); { push ebx }
            { call boolean write fielded routine }
            emitbyt($e8); { call ps_wrtbol }
            emitadr(pswrtblf, itradr); { output routine address }
            pswrtblf^.rotr := true; { set referenced }
            stack := stack+(2*stksiz) { net is less two }

         end;
         iwrtrelft:   begin

            { load operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            emitbyt($59); { pop ecx }
            emitbyt($5a); { pop edx }
            { place copy of the file on stack }
            emitbyt($52); { push edx }
            { replace operands, reversing field and real }
            emitbyt($52); { push edx }
            emitbyt($50); { push eax }
            emitbyt($51); { push ecx }
            emitbyt($53); { push ebx }
            { call real write routine }
            emitbyt($e8); { call ps_wrtreal }
            emitadr(pswrtreal, itradr); { output routine address }
            pswrtreal^.rotr := true; { set referenced }
            stack := stack+stksiz+rlsiz { net is less two }

         end;
         iwrtstrft:  begin { write string fielded }

            getlnk(tp); { get string type }
            { get field }
            emitbyt($58); { pop eax }
            { get string }
            emitbyt($5b); { pop ebx }
            { get file }
            emitbyt($59); { pop ecx }
            { place copy of the file on stack }
            emitbyt($51); { push ecx }
            { place file }
            emitbyt($51); { push ecx }
            { place field }
            emitbyt($50); { push eax }
            { place length of string as tag length }
            emitbyt($68); { push len }
            emitint(tp^.size);
            { place string }
            emitbyt($53); { push ebx }
            { call string write routine }
            emitbyt($e8); { call ps_wrtstr }
            emitadr(pswrtstrf, itradr); { output routine address }
            pswrtstrf^.rotr := true; { set referenced }
            stack := stack+(2*stksiz) { net is less two }

         end;
         iwrtgstft:  begin { write general string fielded }

            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            emitbyt($59); { pop ecx }
            emitbyt($5a); { pop edx }
            { place copy of the file on stack }
            emitbyt($52); { push edx }
            { replace operands }
            emitbyt($52); { push edx }
            emitbyt($51); { push ecx }
            emitbyt($53); { push ebx }
            emitbyt($50); { push eax }
            { call string write routine }
            emitbyt($e8); { call ps_wrtstr }
            emitadr(pswrtstrf, itradr); { output routine address }
            pswrtstrf^.rotr := true; { set referenced }
            stack := stack+intsiz+tgpsiz { net is less two }

         end;
         iwrtrelfft:  begin

            { load operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            emitbyt($59); { pop ecx }
            emitbyt($5a); { pop edx }
            emitbyt($5f); { pop edi }
            { place copy of the file on stack }
            emitbyt($57); { push edi }
            { replace operands, reversing field/fraction and real }
            emitbyt($57); { push edi }
            emitbyt($53); { push ebx }
            emitbyt($50); { push eax }
            emitbyt($52); { push edx }
            emitbyt($51); { push ecx }
            { call real write fixed routine }
            emitbyt($e8); { call ps_wrtrlf }
            emitadr(pswrtrlf, itradr); { output routine address }
            pswrtrlf^.rotr := true; { set referenced }
            stack := stack+(2*stksiz)+rlsiz { net is less three }

         end;
         iwrtsrl:  begin

            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { place copy of the file on stack }
            emitbyt($53); { push ebx }
            { place real on stack }
            emitbyt($50); { push eax }
            { index that }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { place file on stack }
            emitbyt($53); { push ebx }
            { place length on stack }
            emitbyt($6a); { push size }
            emitbyt(srlsiz);
            { place pointer to real on stack }
            emitbyt($50); { push eax }
            { call file write routine }
            emitbyt($e8); { call ps_wrtfil }
            emitadr(pswrtfil, itradr); { output routine address }
            pswrtfil^.rotr := true; { set referenced }
            { remove stacked real }
            emitbyt($58); { pop eax }
            stack := stack+stksiz { net is less one }

         end;
         iwrtrel:   begin

            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            emitbyt($59); { pop ecx }
            { place copy of the file on stack }
            emitbyt($51); { push ecx }
            { place real on stack }
            emitbyt($53); { push ebx }
            emitbyt($50); { push eax }
            { index that }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { place file on stack }
            emitbyt($51); { push ecx }
            { place length on stack }
            emitbyt($6a); { push size }
            emitbyt(rlsiz);
            { place pointer to real on stack }
            emitbyt($50); { push eax }
            { call file write routine }
            emitbyt($e8); { call ps_wrtfil }
            emitadr(pswrtfil, itradr); { output routine address }
            pswrtfil^.rotr := true; { set referenced }
            { remove stacked real }
            emitbyt($58); { pop eax }
            emitbyt($58); { pop eax }
            stack := stack+rlsiz { net is less one }

         end;
         iwrtset:  begin

            { we cannot "pop" a set, so we must get the file pointer we need
              from under the set }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            emitbyt($83); { add eax,setsiz }
            emitbyt($c0);
            { get the file pointer }
            emitbyt($8b); { mov ebx,[eax] }
            emitbyt($18);
            { index the set }
            emitbyt($83); { add eax,setsiz }
            emitbyt($c0);
            emitbyt(setsiz);
            { place file }
            emitbyt($53); { push ebx }
            { place length on stack }
            emitbyt($6a); { push size }
            emitbyt(setsiz);
            { place set address }
            emitbyt($50); { push eax }
            { call file write routine }
            emitbyt($e8); { call ps_wrtfil }
            emitadr(pswrtfil, itradr); { output routine address }
            pswrtfil^.rotr := true; { set referenced }
            { remove set from stack }
            emitbyt($83); { add esp,setsiz }
            emitbyt($c4);
            emitbyt(setsiz);
            stack := stack+setsiz { net less one set }

         end;
         iwrtchr, iwrtbol:  begin

            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { place copy of the file on stack }
            emitbyt($53); { push ebx }
            { place character/boolean on stack }
            emitbyt($50); { push eax }
            { index that }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { place file on stack }
            emitbyt($53); { push ebx }
            { place length on stack }
            emitbyt($6a); { push size }
            emitbyt(1);
            { place pointer to character/boolean on stack }
            emitbyt($50); { push eax }
            { call file write routine }
            emitbyt($e8); { call ps_wrtfil }
            emitadr(pswrtfil, itradr); { output routine address }
            pswrtfil^.rotr := true; { set referenced }
            { remove stacked character/boolean }
            emitbyt($58); { pop eax }
            stack := stack+stksiz { net is less one }
            
         end;
         iwrtint:  begin

            getlnk(tp); { get type }
            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { place copy of the file on stack }
            emitbyt($53); { push ebx }
            { place integer on stack }
            emitbyt($50); { push eax }
            { index that }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { place file on stack }
            emitbyt($53); { push ebx }
            { place length on stack }
            emitbyt($6a); { push size }
            emitbyt(tp^.size);
            { place pointer to integer on stack }
            emitbyt($50); { push eax }
            { call file write routine }
            emitbyt($e8); { call ps_wrtfil }
            emitadr(pswrtfil, itradr); { output routine address }
            pswrtfil^.rotr := true; { set referenced }
            { remove stacked integer }
            emitbyt($58); { pop eax }
            stack := stack+stksiz { net is less one }

         end;
         iwrteolt:  begin { write file end of line }

            { duplicate the file }
            emitbyt($58); { pop eax }
            emitbyt($50); { push eax }
            emitbyt($50); { push eax }
            { call file write eoln routine }
            emitbyt($e8); { call ps_wrteol }
            emitadr(pswrteol, itradr); { output routine address }
            pswrteol^.rotr := true { set referenced }

         end;
         iredsrc:    begin { read file }

            getlnk(tp); { get variable type }
            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { place copy of the file on stack }
            emitbyt($53); { push ebx }
            { place file }
            emitbyt($53); { push ebx }
            { place length on stack }
            emitbyt($68); { push size }
            emitint(tp^.size);
            { place variable address }
            emitbyt($50); { push eax }
            { call file read routine }
            emitbyt($e8); { call ps_rdfil }
            emitadr(psrdfil, itradr); { output routine address }
            psrdfil^.rotr := true; { set referenced }
            stack := stack+stksiz { net is less one }

         end;
         iredintt:    begin

            getlnk(tp); { get type }
            if tp^.size = 4 then begin { full integer, go ahead with standard }

               { load both operands }
               emitbyt($58); { pop eax }
               emitbyt($5b); { pop ebx }
               { place copy of the file on stack }
               emitbyt($53); { push ebx }
               { place file }
               emitbyt($53); { push ebx }
               { place variable address }
               emitbyt($50); { push eax }
               { call integer read routine }
               emitbyt($e8); { call ps_rdint }
               emitadr(psrdint, itradr) { output routine address }

            end else begin

               { load both operands }
               emitbyt($58); { pop eax }
               emitbyt($5b); { pop ebx }
               { place copy of the file on stack }
               emitbyt($53); { push ebx }
               { place copy of variable address on stack }
               emitbyt($50); { push eax }
               { place dummy stack variable }
               emitbyt($50);
               { index that }
               emitbyt($8b); { mov eax,esp }
               emitbyt($c4);
               { place file }
               emitbyt($53); { push ebx }
               { place variable address }
               emitbyt($50); { push eax }
               { call integer read routine }
               emitbyt($e8); { call ps_rdint }
               emitadr(psrdint, itradr); { output routine address }
               { get result }
               emitbyt($58); { pop eax }
               { get variable address }
               emitbyt($5b); { pop ebx }
               { process range check }
               pushsrt; { establish label for jumps }
               gettypa(srtstk^.lab, tlab); { set jump to error label }
               gettypa(srtstk^.lab1, tlab); { set jump over error label }
               { generate range check }
               emitbyt($3d); { cmp eax,imm }
               emitint(lbound(tp)); { place low bound }
               emitbyt($0f); { jl goerror }
               emitbyt($8c);
               emitadr(srtstk^.lab, itradr); { place error jump address }
               emitbyt($3d); { cmp eax,imm }
               emitint(ubound(tp)); { place upper bound }
               emitbyt($0f); { jle noerror }
               emitbyt($8e);
               emitadr(srtstk^.lab1, itradr); { place no error address }
               { generate error routine call }
               srtstk^.lab^.addr := pgmcnt; { set jump to error location }
               emitbyt($68); { push rerngchk }
               emitint(ord(rerngchk)); { place error code }
               emitbyt($e8); { call error }
               emitadr(pserror, itradr); { output error routine address }
               pserror^.rotr := true; { set referneced }
               srtstk^.lab1^.addr := pgmcnt; { set jump over error location }
               popsrt; { remove structure level }
               if tp^.size = 2 then begin

                  emitbyt($66); { mov [ebx],ax }
                  emitbyt($89);
                  emitbyt($03)

               end else begin

                  emitbyt($88); { mov [ebx],al }
                  emitbyt($03)

               end

            end;
            psrdint^.rotr := true; { set referenced }
            stack := stack+stksiz { net is less one }
            
         end;
         iredchrt:    begin

            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { place copy of the file on stack }
            emitbyt($53); { push ebx }
            { place file }
            emitbyt($53); { push ebx }
            { place variable address }
            emitbyt($50); { push eax }
            { call character read routine }
            emitbyt($e8); { call ps_rdchr }
            emitadr(psrdchr, itradr); { output routine address }
            psrdchr^.rotr := true; { set referenced }
            stack := stack+stksiz { net is less one }

         end;
         iredrelt:     begin

            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { place copy of the file on stack }
            emitbyt($53); { push ebx }
            { place file }
            emitbyt($53); { push ebx }
            { place variable address }
            emitbyt($50); { push eax }
            { call real read routine }
            emitbyt($e8); { call ps_rdreal }
            emitadr(psrdreal, itradr); { output routine address }
            psrdreal^.rotr := true; { set referenced }
            stack := stack+stksiz { net is less one }

         end;
         iredsrlt:    begin

            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { place copy of the file on stack }
            emitbyt($53); { push ebx }
            { save destination }
            emitbyt($50); { push eax }
            { place file }
            emitbyt($53); { push ebx }
            { establish buffer on stack }
            emitbyt($83); { add esp,-rlsiz }
            emitbyt($c4);
            emitbyt(256-rlsiz);
            { index that }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { call real read routine }
            emitbyt($e8); { call ps_rdreal }
            emitadr(psrdreal, itradr); { output routine address }
            psrdreal^.rotr := true; { set referenced }
            { index result }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load real }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { remove real buffer }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { get destination address }
            emitbyt($58); { pop eax }
            { store short real }
            emitbyt($d9); { fstps [eax] }
            emitbyt($18);
            { sync store }
            emitbyt($9b); { fwait }
            stack := stack+stksiz { net is less one }

         end;
         iredeolt:   begin { read file end of line }

            { duplicate file parameter }
            emitbyt($58); { pop eax }
            emitbyt($50); { push eax }
            emitbyt($50); { push eax }
            { call real eoln routine }
            emitbyt($e8); { call ps_rdeol }
            emitadr(psrdeol, itradr); { output routine address }
            psrdeol^.rotr := true { set referenced }

         end;
         iabsrel:    begin { Abs of real }

            { index real on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load real }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { find abs }
            emitbyt($d9); { fabs }
            emitbyt($e1);
            { store real }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync store }
            emitbyt($9b) { fwait }

         end;
         iabsint:   begin { Abs of integer }

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set skip label }
            { get operand }
            emitbyt($58); { pop eax }
            { find sign }
            emitbyt($0b); { or eax,eax }
            emitbyt($c0);
            { skip not signed }
            emitbyt($0f); { jns over }
            emitbyt($89);
            emitadr(srtstk^.lab, itradr); { place skip address }
            { remove sign }
            emitbyt($f7); { neg eax }
            emitbyt($d8);
            srtstk^.lab^.addr := pgmcnt; { set skip location }
            { replace on stack }
            emitbyt($50); { push eax }
            popsrt; { remove structure level }
            
         end;
         isqrrel:    begin { Sqr of real }

            { index real on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load real }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { multiply by itself for sqr }
            emitbyt($d8); { fmul st,st }
            emitbyt($c8);
            { store short real }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync store }
            emitbyt($9b) { fwait }

         end;
         isqrint:   begin { Sqr of integer }

            { load operand }
            emitbyt($58); { pop eax }
            { mutiply by itself to find sqr }
            emitbyt($f7); { imul eax }
            emitbyt($e8);
            { replace on stack }
            emitbyt($50); { push eax }
            
         end;
         iatnrel:    begin { Arctan of real }

            { index real on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load real }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { load 1.0 }
            emitbyt($d9); { fld1 }
            emitbyt($e8);
            { find arctan }
            emitbyt($d9); { fpatan }
            emitbyt($f3);
            { store real }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync store }
            emitbyt($9b) { fwait }
            
         end;
         icosrel:    begin { Cos of real }

            { index real on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load real }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { find cosine }
            emitbyt($d9); { fcos }
            emitbyt($ff);
            { store real }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync store }
            emitbyt($9b) { fwait }
            
         end;
         iexprel:    begin { Exp of real }

            { load round to 0 control word }
            emitbyt($68); { push $00000f3f }
            emitint($00000f3f);
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            emitbyt($d9); { fldcw [eax] }
            emitbyt($28);
            emitbyt($58); { pop eax }
            { index real on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load real }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { calculate exp(x) = 2**(x * ln(e)) }
            emitbyt($d9); { fldl2e }
            emitbyt($ea);
            emitbyt($de); { fmulp }
            emitbyt($c9);
            emitbyt($d9); { fld st(0) }
            emitbyt($c0);
            emitbyt($d9); { fld st(0) }
            emitbyt($c0);
            emitbyt($d9); { frndint }
            emitbyt($fc);
            emitbyt($d9); { fxch }
            emitbyt($c9);
            emitbyt($de); { fsubrp }
            emitbyt($e1);
            emitbyt($d9); { f2xm1 }
            emitbyt($f0);
            emitbyt($d9); { fld1 }
            emitbyt($e8);
            emitbyt($de); { faddp }
            emitbyt($c1);
            emitbyt($d9); { fxch }
            emitbyt($c9);
            emitbyt($d9); { fld1 }
            emitbyt($e8);
            emitbyt($d9); { fscale }
            emitbyt($fd);
            emitbyt($dd); { fstp st(1) }
            emitbyt($d9);
            emitbyt($de); { fmulp }
            emitbyt($c9);
            { store real }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync store }
            emitbyt($9b) { fwait }

         end;
         ilgnrel:     begin { ln of real }

            { index real on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load real }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            emitbyt($d9); { fld1 }
            emitbyt($e8);
            emitbyt($d9); { fxch }
            emitbyt($c9);
            emitbyt($d9); { fyl2x }
            emitbyt($f1);
            emitbyt($d9); { fldl2e }
            emitbyt($ea);
            emitbyt($de); { fdivp }
            emitbyt($f9);
            { store real }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync store }
            emitbyt($9b) { fwait }

         end;
         isinrel:    begin { Sin of real }

            { index real on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load real }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { find sine }
            emitbyt($d9); { fsin }
            emitbyt($fe);
            { store real }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync store }
            emitbyt($9b) { fwait }
            
         end;
         isqtrel:    begin { Sqrt of real }

            { index real on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load real }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { find sqrt }
            emitbyt($d9); { fsqrt }
            emitbyt($fa);
            { store real }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync store }
            emitbyt($9b) { fwait }

         end;
         ieolt:     begin { Eoln of file }

            { get file }
            emitbyt($58); { pop eax }
            { allocate return value }
            emitbyt($50); { push eax }
            { place file on stack }
            emitbyt($50); { push eax }
            { call eoln check routine }
            emitbyt($e8); { call ps_chkeol }
            emitadr(pschkeol, itradr); { output routine address }
            pschkeol^.rotr := true { set referenced }

         end;
         ieof:      begin { Eof of file }

            getlnk(tp); { get file type }
            tp1 := baset(tp); { find base type }
            { get file }
            emitbyt($58); { pop eax }
            { allocate return value }
            emitbyt($50); { push eax }
            { place file on stack }
            emitbyt($50); { push eax }
            { call eof check routine }
            emitbyt($e8); { call routine }
            if tp1^.t = ttext then begin

               emitadr(pseoftxt, itradr); { output routine address }
               pseoftxt^.rotr := true { set referenced }

            end else begin

               emitadr(pseoffil, itradr); { output routine address }
               pseoffil^.rotr := true { set referenced }

            end
         
         end;
         iodd:      begin { Odd of integer }

            { get integer }
            emitbyt($58); { pop eax }
            { mask all but 1st bit }
            emitbyt($83); { and eax,1 }
            emitbyt($e0);
            emitbyt(1);
            { replace on stack }
            emitbyt($50) { push eax }

         end;
         isucint:   begin { Succ of integer }

            { get integer }
            emitbyt($58); { pop eax }
            { increment }
            emitbyt($40); { inc eax }
            { replace on stack }
            emitbyt($50) { push eax }

         end;
         iprdint:   begin { Pred of integer }

            { get integer }
            emitbyt($58); { pop eax }
            { decrement }
            emitbyt($48); { dec eax }
            { replace on stack }
            emitbyt($50) { push eax }

         end;
         irnd:      begin { Round }

            { load round to nearest control word }
            emitbyt($68); { push $0000033f }
            emitint($0000033f);
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            emitbyt($d9); { fldcw [eax] }
            emitbyt($28);
            emitbyt($58); { pop eax }
            { index real on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load real }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { adjust stack space }
            emitbyt($5b); { pop ebx }
            { index destination on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { store integer with rounding }
            emitbyt($db); { fistpd [eax] }
            emitbyt($18);
            { sync store }
            emitbyt($9b); { fwait }
            stack := stack+intsiz { change from 64 bits to 32 bits }

         end;
         itrc:      begin { Trunc }

            { load round to 0 control word }
            emitbyt($68); { push $00000f3f }
            emitint($00000f3f);
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            emitbyt($d9); { fldcw [eax] }
            emitbyt($28);
            emitbyt($58); { pop eax }
            { index real on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load real }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { adjust stack space }
            emitbyt($5b); { pop ebx }
            { index destination on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { store integer with rounding }
            emitbyt($db); { fistpd [eax] }
            emitbyt($18);
            { sync store }
            emitbyt($9b); { fwait }
            stack := stack+intsiz { change from 64 bits to 32 bits }

         end;
         iexist:    begin

            { get address }
            emitbyt($58); { pop eax }
            { get length }
            emitbyt($5b); { pop ebx }
            { allocate return value }
            emitbyt($50); { push eax }
            { replace length }
            emitbyt($53); { push ebx }
            { replace address }
            emitbyt($50); { push eax }
            { call exists check routine }
            emitbyt($e8); { call ss_exists }
            emitadr(ssexists, itradr); { output routine address }
            ssexists^.rotr := true; { set referenced }
            stack := stack+tgpsiz-bolsiz { adjust stack }

         end;
         ilen:      begin { find file length }

            { get file }
            emitbyt($58); { pop eax }
            { allocate return value }
            emitbyt($50); { push eax }
            { place file }
            emitbyt($50); { push eax }
            { call file length routine }
            emitbyt($e8); { call ps_fillen }
            emitadr(psfillen, itradr); { output routine address }
            psfillen^.rotr := true { set referenced }
            
         end;
         iloc:      begin { File location }

            { get file }
            emitbyt($58); { pop eax }
            { allocate return value }
            emitbyt($50); { push eax }
            { place file }
            emitbyt($50); { push eax }
            { call file location routine }
            emitbyt($e8); { call ps_filloc }
            emitadr(psfilloc, itradr); { output routine address }
            psfilloc^.rotr := true { set referenced }

         end;
         iget:      begin { File get }

            { call file get routine }
            emitbyt($e8); { call ps_getfil }
            emitadr(psgetfil, itradr); { output routine address }
            psgetfil^.rotr := true; { set referenced }
            stack := stack+stksiz { removes the file }

         end;
         igett:     begin { Text file get }

            { call text file get routine }
            emitbyt($e8); { call ps_gettxt }
            emitadr(psgettxt, itradr); { output routine address }
            psgettxt^.rotr := true; { set referenced }
            stack := stack+stksiz { removes the file }

         end;
         iput:      begin

            { call file put routine }
            emitbyt($e8); { call ps_putfil }
            emitadr(psputfil, itradr); { output routine address }
            psputfil^.rotr := true; { set referenced }
            stack := stack+stksiz { removes the file }

         end;
         ilodafbuf: begin { load address of file buffer }

            { get file }
            emitbyt($58); { pop eax }
            { allocate return value }
            emitbyt($50); { push eax }
            emitbyt($50); { push eax }
            { place file on stack }
            emitbyt($50); { push eax }
            { call buffer address routine }
            emitbyt($e8); { call ps_lbafil }
            emitadr(pslbafil, itradr); { output routine address }
            { get buffer address }
            emitbyt($58); { pop eax }
            { dispose of buffer length }
            emitbyt($5b); { pop ebx }
            { replace buffer address }
            emitbyt($50); { push eax }
            pslbafil^.rotr := true { set referenced }

         end;
         ilodafbuft: begin { load address of text file buffer }

            { get file }
            emitbyt($58); { pop eax }
            { allocate return value }
            emitbyt($50); { push eax }
            emitbyt($50); { push eax }
            { place file on stack }
            emitbyt($50); { push eax }
            { call text buffer address routine }
            emitbyt($e8); { call ps_lbatxt }
            emitadr(pslbatxt, itradr); { output routine address }
            { get buffer address }
            emitbyt($58); { pop eax }
            { dispose of buffer length }
            emitbyt($5b); { pop ebx }
            { replace buffer address }
            emitbyt($50); { push eax }
            pslbatxt^.rotr := true { set referenced }

         end;
         ireset:    begin

            getlnk(tp); { get file type }
            tp1 := baset(tp); { find base type }
            if tp1^.t = ttext then begin

               { place file buffer length }
               emitbyt($6a); { push size }
               emitbyt(1); { place file record length }
               { call text file reset routine }
               emitbyt($e8); { call ps_restxt }
               emitadr(psrestxt, itradr); { output routine address }
               psrestxt^.rotr := true { set referenced }

            end else if tp1^.t = tfile then begin

               { place file buffer length }
               emitbyt($68); { push size }
               emitint(tp1^.filt^.size); { place file record length }
               { call file reset routine }
               emitbyt($e8); { call ps_resfil }
               emitadr(psresfil, itradr); { output routine address }
               psresfil^.rotr := true { set referenced }

            end else error(einvfmt); { invalid format }
            stack := stack+stksiz { net is less one }

         end;
         irewrite:  begin

            getlnk(tp); { get file type }
            tp1 := baset(tp); { find base type }
            if tp1^.t = ttext then begin

               { place file buffer length }
               emitbyt($6a); { push size }
               emitbyt(1); { place file record length }
               { call text file rewrite routine }
               emitbyt($e8); { call ps_rwttxt }
               emitadr(psrwttxt, itradr); { output routine address }
               psrwttxt^.rotr := true { set referenced }

            end else if tp1^.t = tfile then begin

               { place file buffer length }
               emitbyt($68); { push size }
               emitint(tp1^.filt^.size); { place file record length }
               { call file rewrite routine }
               emitbyt($e8); { call ps_rwtfil }
               emitadr(psrwtfil, itradr); { output routine address }
               psrwtfil^.rotr := true { set referenced }

            end else error(einvfmt); { invalid format }
            stack := stack+stksiz { net is less one }

         end;
         iclose:    begin

            { call close file routine }
            emitbyt($e8); { call ps_close }
            emitadr(psclose, itradr); { output routine address }
            psclose^.rotr := true; { set referenced }
            stack := stack+stksiz { net is less one }

         end;
         ipack:     begin { pack }

            { at this time, pack simply acts as an assign, because
              packing is unimplemented }
            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump to error label }
            gettypa(srtstk^.lab1, tlab); { set jump over error label }
            getlnk(tp); { get packed type }
            getlnk(tp1); { get unpacked type }
            { get packed array pointer }
            emitbyt($5f); { pop edi }
            { get starting index }
            emitbyt($58); { pop eax }
            { get unpacked array pointer }
            emitbyt($5e); { pop esi }
            { generate range check }
            emitbyt($3d); { cmp eax,imm }
            emitint(lbound(tp1^.arri)); { place low bound }
            emitbyt($0f); { jl goerror }
            emitbyt($8c);
            emitadr(srtstk^.lab, itradr); { place error jump address }
            emitbyt($3d); { cmp eax,imm }
            emitint(ubound(tp1^.arri)); { place upper bound }
            emitbyt($0f); { jle noerror }
            emitbyt($8e);
            emitadr(srtstk^.lab1, itradr); { place no error address }
            { generate error routine call }
            srtstk^.lab^.addr := pgmcnt; { set jump to error location }
            emitbyt($68); { push rerngchk }
            emitint(ord(rerngchk)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab1^.addr := pgmcnt; { set jump over error location }
            { adjust index for lower bound }
            emitbyt($2d); { sub eax,lbound }
            emitint(lbound(tp1^.arri)); { place lower bound }
            { scale to base type }
            emitbyt($bb); { mov ebx,size }
            emitint(tp1^.arrt^.size); { place base type size }
            emitbyt($f7); { mul eax,ebx }
            emitbyt($e3);
            { offset from base address }
            emitbyt($03); { add esi,eax }
            emitbyt($f0);
            { load packed array length as count }
            emitbyt($b9); { mov ecx,size }
            emitint(tp^.size); { place packed array size }
            { move data into place }
            emitbyt($f3); { rep }
            emitbyt($a4); { movsb }
            popsrt; { remove structure level }
            stack := stack+(3*stksiz) { net is less three }

         end;
         iunpack:   begin { unpack }

            { at this time, unpack simply acts as an assign, because
              packing is unimplemented }
            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump to error label }
            gettypa(srtstk^.lab1, tlab); { set jump over error label }
            getlnk(tp); { get unpacked type }
            getlnk(tp1);  { get packed type }
            { get starting index }
            emitbyt($58); { pop eax }
            { get unpacked array pointer }
            emitbyt($5f); { pop edi }
            { get packed array pointer }
            emitbyt($5e); { pop esi }
            { generate range check }
            emitbyt($3d); { cmp eax,imm }
            emitint(lbound(tp^.arri)); { place low bound }
            emitbyt($0f); { jl goerror }
            emitbyt($8c);
            emitadr(srtstk^.lab, itradr); { place error jump address }
            emitbyt($3d); { cmp eax,imm }
            emitint(ubound(tp^.arri)); { place upper bound }
            emitbyt($0f); { jle noerror }
            emitbyt($8e);
            emitadr(srtstk^.lab1, itradr); { place no error address }
            { generate error routine call }
            srtstk^.lab^.addr := pgmcnt; { set jump to error location }
            emitbyt($68); { push rerngchk }
            emitint(ord(rerngchk)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab1^.addr := pgmcnt; { set jump over error location }
            { adjust index for lower bound }
            emitbyt($2d); { sub eax,lbound }
            emitint(lbound(tp^.arri)); { place lower bound }
            { scale to base type }
            emitbyt($bb); { mov ebx,size }
            emitint(tp^.arrt^.size); { place base type size }
            emitbyt($f7); { mul eax,ebx }
            emitbyt($e3);
            { offset from base address }
            emitbyt($03); { add edi,eax }
            emitbyt($f8);
            { load packed array length as count }
            emitbyt($b9); { mov ecx,size }
            emitint(tp1^.size); { place packed array size }
            { move data into place }
            emitbyt($f3); { rep }
            emitbyt($a4); { movsb }
            popsrt; { remove structure level }
            stack := stack+(3*stksiz) { net is less three }

         end;
         ipage:     begin

            { call text file page routine }
            emitbyt($e8); { call ps_pagtxt }
            emitadr(pspagtxt, itradr); { output routine address }
            pspagtxt^.rotr := true; { set referenced }
            stack := stack+stksiz { net is less one }

         end;
         iassign:     begin { assign file name }

            { call file assign routine }
            emitbyt($e8); { call ps_assign }
            emitadr(psassign, itradr); { output routine address }
            psassign^.rotr := true; { set referenced }
            stack := stack+tgpsiz+stksiz { net is less two }

         end;
         ipos:      begin { set file position }

            { call file position routine }
            emitbyt($e8); { call ps_posfil }
            emitadr(psposfil, itradr); { output routine address }
            psposfil^.rotr := true; { set referenced }
            stack := stack+(2*stksiz) { net is less two }

         end;
         idel:      begin

            { call file delete routine }
            emitbyt($e8); { call ss_delete }
            emitadr(ssdelete, itradr); { output routine address }
            ssdelete^.rotr := true; { set referenced }
            stack := stack+tgpsiz { net is less one }

         end;
         ichg:      begin

            { call file change routine }
            emitbyt($e8); { call ss_change }
            emitadr(sschange, itradr); { output routine address }
            sschange^.rotr := true; { set referenced }
            stack := stack+(2*tgpsiz) { net is less two }

         end;
         istisrl:   begin { store short real variable }

            getlnk(tp); { get variable (unused) }
            { index real on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load long real }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { dispose of stack real }
            emitbyt($58); { pop eax }
            emitbyt($58); { pop eax }
            { get destination address }
            emitbyt($58); { pop eax }
            { store to destination short }
            emitbyt($d9); { fstps [eax] }
            emitbyt($18);
            { sync store }
            emitbyt($9b); { fwait }
            stack := stack+rlsiz+stksiz { net is less two }

         end;
         istirel:    begin { store real variable }

            getlnk(tp); { get variable (unused) }
            { get real }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { index destination }
            emitbyt($5f); { pop edi }
            { transfer }
            emitbyt($ab); { stosd }
            emitbyt($8b); { mov eax,ebx }
            emitbyt($c3);
            emitbyt($ab); { stosd }
            stack := stack+stksiz+rlsiz { net is less two }
               
         end;
         istiint, istichr, istibol:   begin

            getlnk(tp); { get variable type }
            { get operand }
            emitbyt($58); { pop eax }
            { get destination address }
            emitbyt($5b); { pop ebx }
            { if the destination is a true integer, don't range check, since
              the destination can contain any result. Also don't check
              pointers. also obey range check flag }
            if not intt(tp) and (tp^.t <> tptr) and (tp^.t <> tnil) and
               fbnd then begin 

               { process range check }
               pushsrt; { establish label for jumps }
               gettypa(srtstk^.lab, tlab); { set jump to error label }
               gettypa(srtstk^.lab1, tlab); { set jump over error label }
               { generate range check }
               emitbyt($3d); { cmp eax,imm }
               emitint(lbound(tp)); { place low bound }
               emitbyt($0f); { jl goerror }
               emitbyt($8c);
               emitadr(srtstk^.lab, itradr); { place error jump address }
               emitbyt($3d); { cmp eax,imm }
               emitint(ubound(tp)); { place upper bound }
               emitbyt($0f); { jle noerror }
               emitbyt($8e);
               emitadr(srtstk^.lab1, itradr); { place no error address }
               { generate error routine call }
               srtstk^.lab^.addr := pgmcnt; { set jump to error location }
               emitbyt($68); { push rerngchk }
               emitint(ord(rerngchk)); { place error code }
               emitbyt($e8); { call error }
               emitadr(pserror, itradr); { output error routine address }
               pserror^.rotr := true; { set referenced }
               srtstk^.lab1^.addr := pgmcnt; { set jump over error location }
               popsrt; { remove structure level }

            end;
            { process by size of destination }
            if tp^.size = 4 then begin { full integer }

               emitbyt($89); { mov [ebx],eax }
               emitbyt($03)

            end else if tp^.size = 2 then begin

               emitbyt($66); { mov [ebx],ax }
               emitbyt($89);
               emitbyt($03)

            end else if tp^.size = 1 then begin

               emitbyt($88); { mov [ebx],al }
               emitbyt($03)

            end else error(einvfmt); { bad size }
            stack := stack+(2*stksiz) { net is less two }

         end;
         istiset:   begin

            getlnk(tp); { get variable (unused) }
            { get the destination address above the set }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            emitbyt($83); { add eax,setsiz }
            emitbyt($c0);
            emitbyt(setsiz);
            emitbyt($8b); { mov edi,[eax] }
            emitbyt($38);
            { index source on stack }
            emitbyt($8b); { mov esi,esp }
            emitbyt($f4);
            { load count }
            emitbyt($b9); { mov ecx,setsiz div 4 }
            emitint(setsiz div 4);
            { store data to destination }
            emitbyt($f3); { rep }
            emitbyt($a5); { movsd } 
            { remove operands from stack }
            emitbyt($83); { add esp,setsiz+stksiz }
            emitbyt($c4);
            emitbyt(setsiz+stksiz);
            stack := stack+setsiz+stksiz { net is less two }

         end;
         istisrc:      begin { store structured }

            getlnk(tp); { get object type }
            { get struture address }
            emitbyt($5e); { pop esi }
            { get destination address }
            emitbyt($5f); { pop edi }
            { set size }
            emitbyt($b9); { mov ecx,size }
            emitint(tp^.size); { place object size }
            { store structure }
            emitbyt($f3); { rep }
            emitbyt($a4); { movsb } 
            stack := stack+(2*stksiz) { net is less two }

         end;
         istigar:   begin { store general array }

            getlnk(tp); { get object type }
            if tp^.t <> tgarry then error(einvfmt); { bad format }
            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            { get source address }
            emitbyt($5e); { pop esi }
            { get source length }
            emitbyt($58); { pop eax }
            { get destination address }
            emitbyt($5f); { pop edi }
            { get destination length }
            emitbyt($59); { pop ecx }
            { check lengths equal }
            emitbyt($3b); { cmp eax,ecx }
            emitbyt($c1);
            { skip error if so }
            emitbyt($0f); { je over }
            emitbyt($84);
            emitadr(srtstk^.lab, itradr); { place error jump over address }
            { generate error routine call }
            emitbyt($68); { push rlenmat }
            emitint(ord(relenmat)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab^.addr := pgmcnt; { set jump over error location }
            { move data to destination }
            emitbyt($f3); { rep }
            emitbyt($a4); { movsb } 
            popsrt; { remove structure level }
            stack := stack+(2*tgpsiz) { net is less two }

         end;
         istitgp:   begin

            getlnk(tp); { get variable (unused) }
            { get tagged pointer }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { index destination }
            emitbyt($5f); { pop edi }
            { transfer }
            emitbyt($ab); { stosd }
            emitbyt($8b); { mov eax,ebx }
            emitbyt($c3);
            emitbyt($ab); { stosd }
            stack := stack+tgpsiz+stksiz { adjust stack }

         end;
         istifsrl:  begin { store function short real }

            getlnk(tp); { get variable (unused) }
            { index real on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load long real }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { dispose of stack real }
            emitbyt($58); { pop eax }
            emitbyt($58); { pop eax }
            { get destination address }
            emitbyt($58); { pop eax }
            { store to destination short }
            emitbyt($d9); { fstps [eax] }
            emitbyt($18);
            { sync store }
            emitbyt($9b); { fwait }
            stack := stack+(2*stksiz) { net is less two }

         end;
         istifrel:   begin { store function real }

            getlnk(tp); { get variable (unused) }
            { get real }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { index destination }
            emitbyt($5f); { pop edi }
            { transfer }
            emitbyt($ab); { stosd }
            emitbyt($8b); { mov eax,ebx }
            emitbyt($c3);
            emitbyt($ab); { stosd }
            stack := stack+stksiz+rlsiz { net is less two }

         end;
         istiftgp:  begin { store function tagged pointer }

            getlnk(tp); { get variable (unused) }
            { get tagged pointer }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { index destination }
            emitbyt($5f); { pop edi }
            { transfer }
            emitbyt($ab); { stosd }
            emitbyt($8b); { mov eax,ebx }
            emitbyt($c3);
            emitbyt($ab); { stosd }
            stack := stack+stksiz+tgpsiz { net is less two }

         end;
         istifint, istifchr, istifbol:  begin 

            { store function integer, character, boolean }
            getlnk(tp); { get function type }
            tp1 := tp^.fncr; { index function result }
            tp := baset(tp^.fncr); { index function variable }
            { get operand }
            emitbyt($58); { pop eax }
            { get destination address }
            emitbyt($5b); { pop ebx }
            { if the destination is a true integer, don't range check, since
              the destination can contain any result. Also don't check
              pointers }
            if not intt(tp) and (tp^.t <> tptr) and (tp^.t <> tnil) then begin 

               { process range check }
               pushsrt; { establish label for jumps }
               gettypa(srtstk^.lab, tlab); { set jump to error label }
               gettypa(srtstk^.lab1, tlab); { set jump over error label }
               { generate range check }
               emitbyt($3d); { cmp eax,imm }
               emitint(lbound(tp)); { place low bound }
               emitbyt($0f); { jl goerror }
               emitbyt($8c);
               emitadr(srtstk^.lab, itradr); { place error jump address }
               emitbyt($3d); { cmp eax,imm }
               emitint(ubound(tp)); { place upper bound }
               emitbyt($0f); { jle noerror }
               emitbyt($8e);
               emitadr(srtstk^.lab1, itradr); { place no error address }
               { generate error routine call }
               srtstk^.lab^.addr := pgmcnt; { set jump to error location }
               emitbyt($68); { push rerngchk }
               emitint(ord(rerngchk)); { place error code }
               emitbyt($e8); { call error }
               emitadr(pserror, itradr); { output error routine address }
               pserror^.rotr := true; { set referneced }
               srtstk^.lab1^.addr := pgmcnt; { set jump over error location }
               popsrt; { remove structure level }

            end;
            { process by size of destination }
            if tp1^.size = 4 then begin { full integer }

               emitbyt($89); { mov [ebx],eax }
               emitbyt($03)

            end else if tp1^.size = 2 then begin

               emitbyt($66); { mov [ebx],ax }
               emitbyt($89);
               emitbyt($03)

            end else if tp1^.size = 1 then begin

               emitbyt($88); { mov [ebx],al }
               emitbyt($03)

            end else error(einvfmt); { bad size }
            stack := stack+(2*stksiz) { net is less two }

         end;
         inew, idisp:     begin { new, dispose }

            ic1 := ic; { save type }
            getlnk(tp); { get variable type }
            if tp^.t <> tptr then error(einvfmt); { must be pointer }
            tp := tp^.ptrt; { link base type }
            rsiz := tp^.size; { set whole size }
            getcod(ic); { read the next tag }
            if tp^.t = trecord then begin { it's a record, process tagging }

               rsiz1 := tp^.size; { clear tag size }
               tp := tp^.recf; { index field list }
               rsiz := 0; { clear total size }
               while ic = itag do begin { read tags }

                  { a more compact form was specified than the whole type,
                    so we find the new minimum size by finding
                    all the fixed elements, adding that to the total, and
                    then finding a new minimum }
                  rdnum(v); { get case constant }
                  while tp^.t = tfield do begin { add fixed fields }

                     rsiz := rsiz+tp^.fldt^.size; { add in size }
                     tp := tp^.fldn; { next entry }
                     if tp = nil then error(einvfmt); { invalid format }

                  end;
                  { now we should be pointing at the tag }
                  if tp^.t <> tftag then error(einvfmt); { invalid format }
                  if tp^.ftge then { tag field exists }
                     rsiz := rsiz+tp^.size; { add in tag size }
                  tp := tp^.ftgc; { index case list }
                  while tp^.fcsc <> v do begin { find matching case }

                     tp := tp^.fcsn;
                     if tp = nil then error(einvfmt) { invalid format }

                  end;
                  rsiz1 := tp^.size; { find new minimum }
                  tp := tp^.fcsf; { index that case list }
                  getcod(ic) { read the next tag }

               end;
               rsiz := rsiz+rsiz1 { add any tag size }

            end;
            if ic <> iendtag then error(einvfmt); { should be terminated }
            if ic1 = inew then begin

               { place dummy tagged pointer on stack }
               emitbyt($50); { push eax }
               emitbyt($50); { push eax }
               { index that }
               emitbyt($8b); { mov eax,esp }
               emitbyt($c4);
               { place address on stack }
               emitbyt($50); { push eax }
               { place size on stack }
               emitbyt($68); { push size }
               emitint(rsiz); { place size }
               { call new routine }
               emitbyt($e8);
               emitadr(ssgetspace, itradr);
               { get address of allocation }
               emitbyt($58); { pop eax }
               { dispose of length }
               emitbyt($5b); { pop ebx }
               { get address of pointer }
               emitbyt($5b); { pop ebx }
               { place address }
               emitbyt($89); { mov [ebx],eax }
               emitbyt($03);
               ssgetspace^.rotr := true { set referenced }

            end else begin
                              
               { get address of pointer }
               emitbyt($58); { pop eax }
               { place size on stack }
               emitbyt($68); { push size }
               emitint(rsiz); { place size }
               { place variable address }
               emitbyt($50); { push eax }
               { call dispose routine }
               emitbyt($e8);
               { output routine address }
               emitadr(ssputspace, itradr);
               ssputspace^.rotr := true { set referenced }

            end;
            stack := stack+stksiz { net is less one }

         end;
         itag:      error(einvfmt); { should not occur alone }
         iendtag:   error(einvfmt); { should not occur alone }
         ipoptop:   begin

            getlnk(tp); { get operand type }
            { remove top of stack }
            emitbyt($58); { pop eax }
            stack := stack+stksiz { net is less one }

         end;
         ilabequ:   begin

            getlnk(tp); { get label type }
            tp^.addr := pgmcnt { set location }

         end;
         irngchk:   begin

            getlnk(tp); { get check type }
            if fbnd then begin { process range check if allowed }

               pushsrt; { establish label for jumps }
               gettypa(srtstk^.lab, tlab); { set jump to error label }
               gettypa(srtstk^.lab1, tlab); { set jump over error label }
               { get ordinal to check }
               emitbyt($58); { pop eax }
               { replace on stack }
               emitbyt($50); { push eax }
               { generate range check }
               emitbyt($3d); { cmp eax,imm }
               emitint(lbound(tp)); { place low bound }
               emitbyt($0f); { jl goerror }
               emitbyt($8c);
               emitadr(srtstk^.lab, itradr); { place error jump address }
               emitbyt($3d); { cmp eax,imm }
               emitint(ubound(tp)); { place upper bound }
               emitbyt($0f); { jle noerror }
               emitbyt($8e);
               emitadr(srtstk^.lab1, itradr); { place no error address }
               { generate error routine call }
               srtstk^.lab^.addr := pgmcnt; { set jump to error location }
               emitbyt($68); { push rerngchk }
               emitint(ord(rerngchk)); { place error code }
               emitbyt($e8); { call error }
               emitadr(pserror, itradr); { output error routine address }
               pserror^.rotr := true; { set referenced }
               srtstk^.lab1^.addr := pgmcnt; { set jump over error location }
               popsrt { remove structure level }

            end

         end;
         inewgar:   begin

            getlnk(tp); { get array type }
            if tp^.t <> tgarry then error(einvfmt); { bad format }
            { save length and address of pointer }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            emitbyt($53); { push ebx }
            emitbyt($50); { push eax }
            emitbyt($53); { push ebx }
            { load base object size }
            emitbyt($b9); { mov ecx,size }
            emitint(tp^.gart^.size); { output base element size }
            { multiply to find total allocation }
            emitbyt($f7); { mul eax,ecx }
            emitbyt($e1);
            { place on stack }
            emitbyt($50); { push eax }
            { call new routine }
            emitbyt($e8); { call ss_getspace }
            emitadr(ssgetspace, itradr); { output routine address }
            ssgetspace^.rotr := true; { set referenced }
            { now replace byte length with element based length }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            emitbyt($83); { add ebx,4 }
            emitbyt($c3);
            emitbyt($04);
            emitbyt($89); { mov [ebx],eax }
            emitbyt($03);
            stack := stack+intsiz+stksiz { adjust stack }

         end;
         idspgar:   begin

            getlnk(tp); { get array type }
            if tp^.t <> tgarry then error(einvfmt); { bad format }
            { create byte length }
            emitbyt($5b); { pop ebx }
            emitbyt($58); { pop eax }
            { load base object size }
            emitbyt($b9); { mov ecx,size }
            emitint(tp^.gart^.size); { output base element size }
            { multiply to find total allocation }
            emitbyt($f7); { mul eax,ecx }
            emitbyt($e1);
            { place on stack }
            emitbyt($50); { push eax }
            emitbyt($53); { push ebx }
            { call dispose routine }
            emitbyt($e8); { call ss_putspace }
            emitadr(ssputspace, itradr); { output routine address }
            ssputspace^.rotr := true; { set referenced }
            stack := stack+tgpsiz { adjust stack }

         end;
         ihalt:     begin

            emitbyt($e8); { call abort }
            emitadr(psabort, itradr); { output abort routine address }
            psabort^.rotr := true { set referenced }

         end;
         { the optimizer intermediates are unimplemented for now, because the
           optimizer does not exist ! Seriously, these codes are only used
           internal to the new encoder for now. }
         ilodint,  
         ilodrel,  
         ilodsrl,  
         ilodset,  
         ilodchr,  
         ilodbol,  
         ilodsrc,  
         ilodptr,  
         ilodtgp,  
         igotot,   
         igotof,   
         istoint,  
         istosrl,  
         istorel,  
         istochr,  
         istobol,  
         istoset,  
         istosrc,  
         istogar,  
         istotgp,  
         istofint, 
         istoftgp, 
         istofsrl, 
         istofrel, 
         istofchr, 
         istofbol: error(eunimp); 
         iendfil:   { do nothing }

      end

   until ic = iendfil; { end of file tolken }
   close(intfil); { close intermediate file }
   if stack <> maxint then error(esysflt7) { check stack at 0 }

end;

{******************************************************************************

Place integer constant value

Given a constant value and size, validates that the given constant will
actually fit in the required size, then outputs it in the proper size.
Supports bytes, words, and double words in intel format.
Note that the original constant should have been checked against the
original type, but we check it again here for safety.

******************************************************************************}

procedure plcint(s: integer; { size of constant, 1, 2 or 4 }
                 i: integer); { value to output }

begin

   if s = 1 then begin { evaluate byte }

      if (i < -128) or (i > 255) then error(ecstrng); { constant out of range }
      emitbyt(i) { output the byte } 

   end else if s = 2 then begin { evaluate word }

      if (i < -36768) or (i > 65535) then
         error(ecstrng); { constant out of range }
      emitwrd(i) { output the word }

   end else emitint(i) { output double word }

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
    ea:     integer; { ending address }

begin

   if tp^.t = ticst then begin { integer }

      tp^.addr := pgmcnt; { assign base address }
      plcint(ft^.size, tp^.ival) { place integer }

   end else if tp^.t = trcst then begin { real }

      tp^.addr := pgmcnt; { assign base address }
      if ft = nil then emitrl(tp^.rval) { place real }
      else if ft^.t = treal then emitrl(tp^.rval) { place real }
      else if ft^.t = tsreal then emitsrl(tp^.rval) { place short real }
      else error(einvfmt) { invalid format }

   end else if tp^.t = tscst then begin { found a string entry }

      tp^.addr := pgmcnt; { assign base address }
      emitstr(tp^.sval^) { transfer to storage }

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
      plcint(ft^.size, tp^.env) { place integer }

   end


end;

{******************************************************************************

Set constant addresses

First allocates all the fixed objects, then Traverses the entire types
database, and sets the base address of all string and set constants. String,
set and real constants are unusual in that they are not contained in inline
code.
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

{ process string/set/real list }

procedure sslist(tp: typptr); { list to process }

begin

   while tp <> nil do begin { traverse list }

      { must be string or set constant, and must not already have an address.
        if there is an address, it has already been allocated as part of a
        fixed object. this is ok }
      if (tp^.addr = 0) and (tp^.t in [tscst, tccst, tstcst, trcst]) then
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

            if tp^.t = tvar then if not tp^.vare then begin

               { found a variable entry }
               tp^.addr := pgmcnt; { assign base address }
               pgmcnt := pgmcnt+tp^.size { allocate variable }

            end;
            tp := tp^.next { next type entry }

         end;
         { process alternate list }
         tp := sp^.typa; { index 1st type entry }
         while tp <> nil do begin { traverse list }

            if tp^.t = tvar then if not tp^.vare then begin
               
               { found a variable entry }
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

Output variger

Outputs the given integer to the byte file as a variger.
Varigers are of the following format:

   1. (byte) the tag byte.
   2-N. The variger value.

The tag byte values are:

   bit 7 - Low for integer number, high for float.
   bit 6 - Contains the sign of the integer. 
   bit 5 - Unused.
   bit 4 - Length of integer in bytes, 1-32, in -1 format.
   bit 3 -      ""              ""
   bit 2 -      ""              ""
   bit 1 -      ""              ""
   bit 0 -      ""              ""

The integer is converted by removing the sign bit and converting
to signed magnitude, then determining the byte size, then
outputting the tag and number.

******************************************************************************}

procedure wrtvar(var f: bytfil; n: integer); { integer to output}

var t: integer; { tag byte }
    p: integer; { power holder }

begin

   { handle 0 as special case }
   if n = 0 then begin write(f, 0); write(f, 0) end else begin

      { value is non-zero }
      t := bytes-1; { initalize tag field to max bytes }
      if n < 0 then begin { remove sign and convert to signed magnitude }
      
         t := t + $40; { place sign in tag }
         n := abs(n) { find absolute value of integer }
      
      end;
      p := toppow; { get top power }
      { find 1st non-zero digit in integer }
      while (n div p) = 0 do begin p := p div 256; t := t - 1 end;
      write(f, t); { output finalized tagfield }
      while p <> 0 do begin { output bytes }
      
         write(f, n div p); { output that byte }
         n := n mod p; { remove the byte }
         p := p div 256 { next lower power }      
      
      end

   end

end;

{******************************************************************************

Output unattached rlds

Outputs all rld entries unattached to symbols.

******************************************************************************}

procedure outrlds;

var rp: rldptr; { relocation pointer }
    b:  byte;   { output byte holder }

begin

   rp := rldlst; { index 1st rld }
   while rp <> nil do begin { traverse list }

      if not rp^.out then begin { not already output }

         write(symfil, 4); { output type code, output stand alone rld }
         if rp^.it = itadr then
            { for straight address, little endian, normal insert }
            write(symfil, $00)
         else 
            { for relative address, little endian, offset insert }
            write(symfil, $08);
         { output insert length }
         if rp^.it = itbradr then write(symfil, 7) { 8 bits (-1) }
         else write(symfil, 31); { 32 bits (-1) }
         wrtvar(symfil, rp^.addr); { output patch address }
         b := $01; { set flags: defined }
         { set program variable space by type. check all program space 
           entries }
         if rp^.lab^.t in [tfix, tproc, tfunc, trot, tpgm, tscst, tccst, trcst,
                           tlab, tstcst] then
            b := b+$02 { set program space flag }
         { check all variable space entries }
         else if rp^.lab^.t in [tvar, tvrs] then
            b := b+$10; { set variable space flag }
         write(symfil, b); { output flag byte }
         { output target address }
         wrtvar(symfil, rp^.lab^.addr);
         rp^.out := true { set this rld is output }

      end;
      rp := rp^.next { next rld entry }

   end

end;

{******************************************************************************

Output symbol

Outputs a symbol with length. The length is output first, in -1 format.
Processes coining, which means to place all of the encompassing block labels
before the output label. Coining, at this stage of the compilers development,
is optional, because the intermodule communication labels don't currently
get coined.
Coining stops at the program/module level, and does not include the
system block, simply because every block belongs to that.

******************************************************************************}

procedure outsym(view l:    string;  { label to output }
                      coin: boolean; { label is to be coined }
                      blk:  tpsptr); { block to use for coining }

var i:   integer; { index for label }
    len: integer; { length of label }
    p:   tpsptr;  { pointer to blocks }

procedure outmarks(p: tpsptr); { block pointer }

var i: integer; { index for label }

begin

   if p <> nil then begin { not end }

      outmarks(p^.prnt); { output mark below us }
      if (p^.lvl >= 2) and (p^.marks <> nil) then begin

         { level is 2 or more, and label exists }
         for i := 1 to max(p^.marks^.lab^) do { add in label }
            write(symfil, ord(p^.marks^.lab^[i]));
         write(symfil, ord('_')) { output separator }

      end

   end

end;

begin

   { determine total length of label }
   len := max(l); { place length of tail }
   if coin then begin { label is to be coined }

      p := blk; { index block head }
      { add in all the block coins }
      while p <> nil do begin

         if p^.lvl >= 2 then { level is 2 or more }
            if p^.marks <> nil then { label exists }
               { add in the label with separator }
               len := len+max(p^.marks^.lab^)+1;
         p := p^.prnt { up to parent block }

      end

   end;
   if len > 256 then error(elabovf); { label too long to output }
   write(symfil, len-1); { output length in -1 format }
   if coin then { label is to be coined }
      outmarks(blk); { traverse all of the output sections }
   for i := 1 to max(l) do write(symfil, ord(l[i])) { output symbol string }

end;

{******************************************************************************

Output rlds attached to type

Outputs all rld entries referencing the given symbol. In order for this to
happen, the rld must be derived from the address of the symbol. If it
references another type (display), it must remain to be output in the general
rlds later.

******************************************************************************}

procedure wrtrlds(tp: typptr); { type to output rlds for }

var rp: rldptr; { relocation pointer }

begin

   rp := rldlst; { index 1st rld }
   while rp <> nil do begin { traverse list }

      if (rp^.lab = tp) and
         (rp^.it in [itadr, itradr, itbradr]) then begin { its a candidate }

         write(symfil, 3); { output type code, output attached rld }
         if rp^.it = itadr then
            { for straight address, little endian, normal insert }
            write(symfil, $00)
         else 
            { for relative address, little endian, offset insert }
            write(symfil, $08);
         { output insert length }
         if rp^.it = itbradr then write(symfil, 7) { 8 bits (-1) }
         else write(symfil, 31); { 32 bits (-1) }
         wrtvar(symfil, rp^.addr); { output patch address }
         rp^.out := true { set this rld is output }

      end;
      rp := rp^.next { next rld entry }

   end

end;

{******************************************************************************

Write symbol

Writes the given symbol to the linker file. Since this is only done after
the module is completely processed, all symbols should be resolved. The
program/variable status of the symbol is given. After the symbol, any rlds
referencing the symbol are output, and flagged as output in the rld list.
For the purposes of this routine, the symbol and the type it points to are
considered one. It is, of course, possible for more than one symbol to
reference a single type entry, but this only happens with logical references,
such as constants, types, etc. Each physical object is allways unique.
The automatic attachment of rlds to symbols serves two purposes. First, it
produces a simpler symbols deck. Second, it coordinates external references.

******************************************************************************}

procedure wrtsym(s:    labptr;  { symbol to output }
                 p:    boolean; { program/variable status }
                 ext:  boolean; { external status }
                 coin: boolean; { label is to be coined }
                 blk:  tpsptr);	{ block to use for coining }

var b: byte; { output byte holder }

begin

   write(symfil, 1); { output entry type symbol }
   write(symfil, 0); { output operation, none }
   outsym(s^.lab^, coin, blk); { output the label }
   b := $01; { set defined flag }
   if ext then b := $08; { external, set external }
   { if exportable, but not external, set global }
   if s^.exp  and not ext then b := b+$04;
   if p then b := b+$02 { set program space flag }
   { else if the variable lives in the main block, set variable space.
     If at a higher level, it is a local, and has meaning only as a constant }
   else if blk^.lvl <= 2 then b := b+$10; { set variable space flag }
   write(symfil, b); { output flags }
   { check entry is defined }
   if (b and $01) <> 0 then wrtvar(symfil, s^.typ^.addr); { output address }
   wrtrlds(s^.typ) { output related rlds }

end;

{******************************************************************************

Write global symbols


All the symbols eligible for export in the following blocks are output
without coining:

   0: Our link layer support symbols.
   1: The system level (which probally does not contain any objects).
   2: the global block (outer block of the program).

Not everything is elegible for output. The following types are:

   1. Procedures.
   2. Functions.
   3. Variables (simple).
   4. Fixed objects.
   5. Routines.
   6. program/variable space markers.

If the object is global or external, it is output plain. If not, the object
is coined and output.

******************************************************************************}

procedure wrtsyms;

var tsp: tpsptr;  { type stack pointer }
    sp:  labptr;  { symbol pointer }
    ext: boolean; { external flag }
    ref: boolean; { references exist }

begin

   tsp := typlst; { index 1st list entry }
   while tsp <> nil do begin { traverse blocks }

      { process standard list }
      sp := tsp^.sym; { index 1st symbol entry }
      while sp <> nil do begin { traverse list }

         if sp^.typ^.t in [tvar, tfix, tproc, tfunc, trot, tpgm, tvrs] then
            begin
            { determine if it's an external, and load reference flag }
            with sp^.typ^ do
               case t of { type, get external status from entry }

               tvar:  begin ext := vare; ref := varr end;
               tfix:  begin ext := fixe; ref := fixr end;
               tproc: begin ext := prce; ref := prcr end;
               tfunc: begin ext := fnce; ref := fnct end;
               trot:  begin ext := true; ref := rotr end;
               tpgm:  begin ext := false; ref := false end;
               tvrs:  begin ext := false; ref := false end

            end;
            { if unreferenced external, it can be output. The idea of 
              rejecting unreferenced externals is to prevent pulling in
              library code that is referenced but not used. }
            if not (ext and not ref) then
               { if not exportable, and not external, coin the name }
               wrtsym(sp, sp^.typ^.t in [tfix, tproc, tfunc, trot, tpgm], ext,
                      not sp^.exp and not ext, tsp)

         end;
         sp := sp^.next { next type entry }

      end;
      tsp := tsp^.next { next block }

   end

end;

{******************************************************************************

Make system symbols

Places the _pstr, _pend, vstr and vend symbols into the current (0) block.

******************************************************************************}

procedure maksys;

var lp: labptr; { label pointer }

begin

   { place _pstr symbol }
   gettyp(pgmstr, tpgm); { get a program index entry }
   lstsym(lp); { get the symbol }
   strplc(lp^.lab, '_pstr'); { place label }
   lp^.typ := pgmstr; { place type linkage }
   lp^.exp := true; { set exportable }

   { place _pend symbol }
   gettyp(pgsend, tpgm); { get a program index entry }
   lstsym(lp); { get the symbol }
   strplc(lp^.lab, '_pend'); { place label }
   lp^.typ := pgsend; { place type linkage }
   lp^.exp := true; { set exportable }

   { place _vstr symbol }
   gettyp(varstr, tvrs); { get a variable index entry }
   lstsym(lp); { get the symbol }
   strplc(lp^.lab, '_vstr'); { place label }
   lp^.typ := varstr; { place type linkage }
   lp^.exp := true; { set exportable }

   { place _vend symbol }
   gettyp(varend, tvrs); { get a variable index entry }
   lstsym(lp); { get the symbol }
   strplc(lp^.lab, '_vend'); { place label }
   lp^.typ := varend; { place type linkage }
   lp^.exp := true; { set exportable }

end;

{******************************************************************************

Make support routine symbols

Places the symbols for the support routines in the current block (0).

******************************************************************************}

procedure makrot;

begin

   gettyp(psabort, trot); { get a routine entry }
   psabort^.rotr := false; { set not referenced }
   lstsym(psaborts); { get the symbol }
   strplc(psaborts^.lab,  'ps_abort'); { place label }
   psaborts^.typ := psabort; { place type linkage }

   gettyp(pserror, trot); { get a routine entry }
   pserror^.rotr := false; { set not referenced }
   lstsym(pserrors); { get the symbol }
   strplc(pserrors^.lab, 'ps_error'); { place label }
   pserrors^.typ := pserror; { place type linkage }

   gettyp(pswrtfil, trot); { get a routine entry }
   pswrtfil^.rotr := false; { set not referenced }
   lstsym(pswrtfils); { get the symbol }
   strplc(pswrtfils^.lab, 'ps_wrtfil'); { place label }
   pswrtfils^.typ := pswrtfil; { place type linkage }

   gettyp(pswrtint, trot); { get a routine entry }
   pswrtint^.rotr := false; { set not referenced }
   lstsym(pswrtints); { get the symbol }
   strplc(pswrtints^.lab, 'ps_wrtint'); { place label }
   pswrtints^.typ := pswrtint; { place type linkage }

   gettyp(pswrtchr, trot); { get a routine entry }
   pswrtchr^.rotr := false; { set not referenced }
   lstsym(pswrtchrs); { get the symbol }
   strplc(pswrtchrs^.lab, 'ps_wrtchr'); { place label }
   pswrtchrs^.typ := pswrtchr; { place type linkage }

   gettyp(pswrtbol, trot); { get a routine entry }
   pswrtbol^.rotr := false; { set not referenced }
   lstsym(pswrtbols); { get the symbol }
   strplc(pswrtbols^.lab, 'ps_wrtbol'); { place label }
   pswrtbols^.typ := pswrtbol; { place type linkage }

   gettyp(pswrtblf, trot); { get a routine entry }
   pswrtblf^.rotr := false; { set not referenced }
   lstsym(pswrtblfs); { get the symbol }
   strplc(pswrtblfs^.lab, 'ps_wrtblf'); { place label }
   pswrtblfs^.typ := pswrtblf; { place type linkage }

   gettyp(pswrtreal, trot); { get a routine entry }
   pswrtreal^.rotr := false; { set not referenced }
   lstsym(pswrtreals); { get the symbol }
   strplc(pswrtreals^.lab, 'ps_wrtreal'); { place label }
   pswrtreals^.typ := pswrtreal; { place type linkage }

   gettyp(pswrtrlf, trot); { get a routine entry }
   pswrtrlf^.rotr := false; { set not referenced }
   lstsym(pswrtrlfs); { get the symbol }
   strplc(pswrtrlfs^.lab, 'ps_wrtrlf'); { place label }
   pswrtrlfs^.typ := pswrtrlf; { place type linkage }

   gettyp(pswrtstr, trot); { get a routine entry }
   pswrtstr^.rotr := false; { set not referenced }
   lstsym(pswrtstrs); { get the symbol }
   strplc(pswrtstrs^.lab, 'ps_wrtstr'); { place label }
   pswrtstrs^.typ := pswrtstr; { place type linkage }

   gettyp(pswrtstrf, trot); { get a routine entry }
   pswrtstrf^.rotr := false; { set not referenced }
   lstsym(pswrtstrfs); { get the symbol }
   strplc(pswrtstrfs^.lab, 'ps_wrtstrf'); { place label }
   pswrtstrfs^.typ := pswrtstrf; { place type linkage }

   gettyp(pswrteol, trot); { get a routine entry }
   pswrteol^.rotr := false; { set not referenced }
   lstsym(pswrteols); { get the symbol }
   strplc(pswrteols^.lab, 'ps_wrteol'); { place label }
   pswrteols^.typ := pswrteol; { place type linkage }

   gettyp(pspagtxt, trot); { get a routine entry }
   pspagtxt^.rotr := false; { set not referenced }
   lstsym(pspagtxts); { get the symbol }
   strplc(pspagtxts^.lab, 'ps_pagtxt'); { place label }
   pspagtxts^.typ := pspagtxt; { place type linkage }

   gettyp(psrdfil, trot); { get a routine entry }
   psrdfil^.rotr := false; { set not referenced }
   lstsym(psrdfils); { get the symbol }
   strplc(psrdfils^.lab, 'ps_rdfil'); { place label }
   psrdfils^.typ := psrdfil; { place type linkage }

   gettyp(psrdint, trot); { get a routine entry }
   psrdint^.rotr := false; { set not referenced }
   lstsym(psrdints); { get the symbol }
   strplc(psrdints^.lab, 'ps_rdint'); { place label }
   psrdints^.typ := psrdint; { place type linkage }

   gettyp(psrdchr, trot); { get a routine entry }
   psrdchr^.rotr := false; { set not referenced }
   lstsym(psrdchrs); { get the symbol }
   strplc(psrdchrs^.lab, 'ps_rdchr'); { place label }
   psrdchrs^.typ := psrdchr; { place type linkage }

   gettyp(psrdreal, trot); { get a routine entry }
   psrdreal^.rotr := false; { set not referenced }
   lstsym(psrdreals); { get the symbol }
   strplc(psrdreals^.lab, 'ps_rdreal'); { place label }
   psrdreals^.typ := psrdreal; { place type linkage }

   gettyp(psrdeol, trot); { get a routine entry }
   psrdeol^.rotr := false; { set not referenced }
   lstsym(psrdeols); { get the symbol }
   strplc(psrdeols^.lab, 'ps_rdeol'); { place label }
   psrdeols^.typ := psrdeol; { place type linkage }

   gettyp(pseoftxt, trot); { get a routine entry }
   pseoftxt^.rotr := false; { set not referenced }
   lstsym(pseoftxts); { get the symbol }
   strplc(pseoftxts^.lab, 'ps_eoftxt'); { place label }
   pseoftxts^.typ := pseoftxt; { place type linkage }

   gettyp(pschkeol, trot); { get a routine entry }
   pschkeol^.rotr := false; { set not referenced }
   lstsym(pschkeols); { get the symbol }
   strplc(pschkeols^.lab, 'ps_chkeol'); { place label }
   pschkeols^.typ := pschkeol; { place type linkage }

   gettyp(pseoffil, trot); { get a routine entry }
   pseoffil^.rotr := false; { set not referenced }
   lstsym(pseoffils); { get the symbol }
   strplc(pseoffils^.lab, 'ps_eoffil'); { place label }
   pseoffils^.typ := pseoffil; { place type linkage }

   gettyp(ssexists, trot); { get a routine entry }
   ssexists^.rotr := false; { set not referenced }
   lstsym(ssexistss); { get the symbol }
   strplc(ssexistss^.lab, 'ss_exists'); { place label }
   ssexistss^.typ := ssexists; { place type linkage }

   gettyp(psfillen, trot); { get a routine entry }
   psfillen^.rotr := false; { set not referenced }
   lstsym(psfillens); { get the symbol }
   strplc(psfillens^.lab, 'ps_fillen'); { place label }
   psfillens^.typ := psfillen; { place type linkage }

   gettyp(psfilloc, trot); { get a routine entry }
   psfilloc^.rotr := false; { set not referenced }
   lstsym(psfillocs); { get the symbol }
   strplc(psfillocs^.lab, 'ps_filloc'); { place label }
   psfillocs^.typ := psfilloc; { place type linkage }

   gettyp(psgetfil, trot); { get a routine entry }
   psgetfil^.rotr := false; { set not referenced }
   lstsym(psgetfils); { get the symbol }
   strplc(psgetfils^.lab, 'ps_getfil'); { place label }
   psgetfils^.typ := psgetfil; { place type linkage }

   gettyp(psgettxt, trot); { get a routine entry }
   psgettxt^.rotr := false; { set not referenced }
   lstsym(psgettxts); { get the symbol }
   strplc(psgettxts^.lab, 'ps_gettxt'); { place label }
   psgettxts^.typ := psgettxt; { place type linkage }

   gettyp(psputfil, trot); { get a routine entry }
   psputfil^.rotr := false; { set not referenced }
   lstsym(psputfils); { get the symbol }
   strplc(psputfils^.lab, 'ps_putfil'); { place label }
   psputfils^.typ := psputfil; { place type linkage }

   gettyp(pslbafil, trot); { get a routine entry }
   pslbafil^.rotr := false; { set not referenced }
   lstsym(pslbafils); { get the symbol }
   strplc(pslbafils^.lab, 'ps_lbafil'); { place label }
   pslbafils^.typ := pslbafil; { place type linkage }

   gettyp(pslbatxt, trot); { get a routine entry }
   pslbatxt^.rotr := false; { set not referenced }
   lstsym(pslbatxts); { get the symbol }
   strplc(pslbatxts^.lab, 'ps_lbatxt'); { place label }
   pslbatxts^.typ := pslbatxt; { place type linkage }

   gettyp(psrestxt, trot); { get a routine entry }
   psrestxt^.rotr := false; { set not referenced }
   lstsym(psrestxts); { get the symbol }
   strplc(psrestxts^.lab, 'ps_restxt'); { place label }
   psrestxts^.typ := psrestxt; { place type linkage }

   gettyp(psresfil, trot); { get a routine entry }
   psresfil^.rotr := false; { set not referenced }
   lstsym(psresfils); { get the symbol }
   strplc(psresfils^.lab, 'ps_resfil'); { place label }
   psresfils^.typ := psresfil; { place type linkage }

   gettyp(psrwttxt, trot); { get a routine entry }
   psrwttxt^.rotr := false; { set not referenced }
   lstsym(psrwttxts); { get the symbol }
   strplc(psrwttxts^.lab, 'ps_rwttxt'); { place label }
   psrwttxts^.typ := psrwttxt; { place type linkage }

   gettyp(psrwtfil, trot); { get a routine entry }
   psrwtfil^.rotr := false; { set not referenced }
   lstsym(psrwtfils); { get the symbol }
   strplc(psrwtfils^.lab, 'ps_rwtfil'); { place label }
   psrwtfils^.typ := psrwtfil; { place type linkage }

   gettyp(psclose, trot); { get a routine entry }
   psclose^.rotr := false; { set not referenced }
   lstsym(pscloses); { get the symbol }
   strplc(pscloses^.lab, 'ps_close'); { place label }
   pscloses^.typ := psclose; { place type linkage }

   gettyp(psassign, trot); { get a routine entry }
   psassign^.rotr := false; { set not referenced }
   lstsym(psassigns); { get the symbol }
   strplc(psassigns^.lab, 'ps_assign'); { place label }
   psassigns^.typ := psassign; { place type linkage }

   gettyp(psposfil, trot); { get a routine entry }
   psposfil^.rotr := false; { set not referenced }
   lstsym(psposfils); { get the symbol }
   strplc(psposfils^.lab, 'ps_posfil'); { place label }
   psposfils^.typ := psposfil; { place type linkage }

   gettyp(ssdelete, trot); { get a routine entry }
   ssdelete^.rotr := false; { set not referenced }
   lstsym(ssdeletes); { get the symbol }
   strplc(ssdeletes^.lab, 'ss_delete'); { place label }
   ssdeletes^.typ := ssdelete; { place type linkage }

   gettyp(sschange, trot); { get a routine entry }
   sschange^.rotr := false; { set not referenced }
   lstsym(sschanges); { get the symbol }
   strplc(sschanges^.lab, 'ss_change'); { place label }
   sschanges^.typ := sschange; { place type linkage }

   gettyp(ssgetspace, trot); { get a routine entry }
   ssgetspace^.rotr := false; { set not referenced }
   lstsym(ssgetspaces); { get the symbol }
   strplc(ssgetspaces^.lab, 'ss_getspace'); { place label }
   ssgetspaces^.typ := ssgetspace; { place type linkage }

   gettyp(ssputspace, trot); { get a routine entry }
   ssputspace^.rotr := false; { set not referenced }
   lstsym(ssputspaces); { get the symbol }
   strplc(ssputspaces^.lab, 'ss_putspace'); { place label }
   ssputspaces^.typ := ssputspace; { place type linkage }

end;

begin

   writeln;
   write('I80386 Check Encoder vs. 0.2 Copyright (C) 2003 ');
   writeln('S. A. Moore');
   writeln;

   { clear free types list }
   for fti := tudf to tvrs do fretyp[fti] := nil;
   typstk := nil; { clear types stack }
   typlst := nil; { clear types list }
   pgmcnt := 0; { set program counter to start of memory }
   srtstk := nil; { clear structure tracking stack }
   srtfre := nil; { clear structure free entries list }
   rldlst := nil; { clear relocation entries list }
   gblint := nil; { global integer entry }
   gblreal := nil; { global real entry }
   gblchr := nil; { global character entry }
   frelab := nil; { clear free labels list }
   fcodel := false; { list intermediate code }
   fverb := true; { list code statistics }
   fbnd := true; { set bounds checking on }
   fdmpt := false; { set no type dump }
   final := false; { set no finalization block }
   fopnout := false; { set no output files open }

   { get command line }
   readsp(command, cmdlin, cmdovf);
   if cmdovf then error(einvcmd); { too long }
   cmdend := maxlin; { find end of command line }
   while (cmdend > 1) and (cmdlin[cmdend] = ' ') do cmdend := cmdend-1;
   parcmd; { parse command line }
   { delete any existing output files }
   addext(outnam, 'obj', true); { set object extention }
   if exists(outnam) then delete(outnam);   
   addext(outnam, 'sym', true); { set symbol extention }
   if exists(outnam) then delete(outnam);   
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
   write('Processing ');
   for fi := 1 to maxfil do if intnam[fi] <> ' ' then write(intnam[fi]);
   writeln;
   addext(outnam, 'obj', true); { set object extention }
   assign(objfil, outnam); { open object file }
   rewrite(objfil);
   addext(outnam, 'sym', true); { set symbols extention }
   assign(symfil, outnam); { open symbol file }
   rewrite(symfil);
   fopnout := true; { set output files open }
   { create the "zero" block. we use a single block just to place various
     system definitions into. these include the linker control symbols,
     and the support routine symbols }
   pshblk; { allocate 0 block level }
   gettyp(tp, tglbl); { since all blocks must have marks, create one }
   typstk^.mark := tp; { place linkage }
   maksys; { make system symbols }
   makrot; { make support routines }
   { create the module block markers }
   gettyp(iniblk, tpgm); { get a marker entry }
   gettyp(modend, tpgm); { get a marker entry }
   { jump to main entry }
   emitbyt($e9); { jmp init }
   emitadr(iniblk, itradr); { output address }
   loadint; { load intermediate file }
   { finalization blocks are optional. so we check if such a block appeared.
     if not, we'll just plant a return here to terminate the finalize call,
     and equate the label }
   if not final then begin { no finalizer has appeared }

      emitbyt($c9); { leave }
      emitbyt($c3) { ret }      

   end;
   pgmstr^.addr := 0; { set beginning of program }
   pgmend := pgmcnt-1; { set end of program code }
   setconst; { place constants to memory }
   conend := pgmcnt-1; { set end of constants }
   pgsend^.addr := pgmcnt; { set end of program area }
   modend^.addr := pgmcnt; { set end of module }
   varstr^.addr := pgmcnt; { set start of variable area }
   setrec; { locate record fields }
   setaddr; { locate variable types }
   gblend := pgmcnt-1; { set end of globals }
   varend^.addr := pgmcnt; { set end of variable area }
   popblk; { remove the 0 block level }
   wrtsyms; { output symbols deck }
   outrlds; { output unattached rlds }
   write(symfil, 0); { output symbol file termination }
   { close output files }
   close(objfil);
   close(symfil);

   if fverb then begin

      writeln;
      write('Program:   '); prthex(8, 0); write('..'); prthex(8, pgmend);
      writeln(' ', pgmend+1:6);
      write('Constants: '); prthex(8, pgmend+1); write('..');
      prthex(8, conend); writeln(' ', conend-pgmend:6);
      write('Globals:   '); prthex(8, conend+1); write('..');
      prthex(8, gblend); writeln(' ', gblend-conend:6)

   end;

   99: { abort vector }

   writeln;
   writeln('Function complete');

end.
