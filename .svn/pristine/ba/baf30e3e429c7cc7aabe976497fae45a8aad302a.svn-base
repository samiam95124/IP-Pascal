{*******************************************************************************
*                                                                              *
*                 PASCAL COMPILER PARSER                                       *
*                                                                              *
*                 9/89 S. A. Moore                                             *
*                                                                              *
* General description: We implement a ANSI - Standard pascal compiler in       *
* Pascal. The compiler is designed to break down into at least three modules:  *
*                                                                              *
*     Parser - Accepts source code modules and generates intermediate code     *
*     output. This module is entirely processor independent.                   *
*                                                                              *
*     Optimizer - Performs various optimization on the intermediate code.      *
*     Optional module.                                                         *
*                                                                              *
*     Code generator - Generates a ln compatible code module. This is the      *
*     processor specific module.                                               *
*                                                                              *
* This is the only module that need be complete for any given system. For a    *
* minimum system, a rudamentary code generator for a given processor may be    *
* constructed, and the system bootstrapped.                                    *
*                                                                              *
* Data typing: This processor implements the same data types for all           *
* processors:                                                                  *
*                                                                              *
*     integer - a 64 bit signed integer format. Type may contain all of a      *
*     real mantissa.                                                           *
*                                                                              *
*     real - a 64 bit ANSI real.                                               *
*                                                                              *
*     char - ASCII 8 bits (8th bit parity is preserved).                       *
*                                                                              *
*     set  - N elements.                                                       *
*                                                                              *
* Any subseting of the data types is left entirely to the code module. This    *
* would be typicaly integers and sets. The code module must prove that a       *
* given operation may be performed with less than whole precision by           *
* examination of use. The net result is emulation of the above types.          *
* The output of the processor is intermediate code, consisting of procedure    *
* start/stops, jumps, special and general procedure calls, and expression      *
* trees. Each procedure contains real storage references that are referenced   *
* to the procedure itself.                                                     *
*                                                                              *
* Structure                                                                    *
*                                                                              *
* The modular structure is fairly straightforward:                             *
*                                                                              *
*   parse.pas                                                                  *
*                                                                              *
*   Contains the top level of the program only.                                *
*                                                                              *
*   parser.pas                                                                 *
*                                                                              *
*   Contains the complete syntax analisis.                                     *
*                                                                              *
*   symbol.pas                                                                 *
*                                                                              *
*   Contains symbol and type processing.                                       *
*                                                                              *
*   scanner.pas                                                                *
*                                                                              *
*   Contains the full lexical analisis.                                        *
*                                                                              *
*   parsesvs.pas                                                               *
*                                                                              *
*   Contains the basic file open/close stacker, command line parsing, the      *
*   options parsing, and the error printout.                                   *
*                                                                              *            
*******************************************************************************}

module parsedef;

uses stddef, { standard pascal defines }
     sepsgn, { separated sign library }
     intfrm; { intermediate form }

const

   maxexp  = 308;   { maximum exponent of real }
   labmax  = 250;   { maximum characters in label }
   resmax  = 69;    { number of reserved words (plus padding) }
   chrmax  = 37;    { number of special character sequences
                      (plus padding) }
   filmax  = 100;   { number of characters in filename }
   linmax  = 250;   { number of characters in command line }
   symmax  = 1000;  { symbol chain head maximum }
   hashoff = 10;    { hash function offset }
   chroff  = 20;    { special character hash offset }
   spcmax  = 2;     { special character string length }
   lsmmax  = 10;    { maximum number of characters in label to output in
                      symbols listing (should not be greater than labmax) }
   prtmax  = 80;    { maximum number of characters in an output line }
   digmax  = 10000; { maximum number of digit places in integer }
   usemax  = 200;   { maximum length of uses path }
   { characters allowable in filename. this is DOS dependent }
   filchrs  = ['0'..'9', 'a'..'z', 'A'..'Z', '_', '\\', ':', '.'];
   usestr  = 'usespath'; { name of 'uses' path }
  
type

   { scanner input tolkens }
   tolken = (cundefined,  { undefined (must be first tolken) }
             cplus,       { + }
             cminus,      { - }
             ctimes,      { * }
             crdiv,       { / }
             cequ,        { = }
             cnequ,       { <> }
             cnequa,      { >< }
             cltn,        { < }
             cgtn,        { > }
             clequ,       { <= }
             clequa,      { =< }
             cgequ,       { >= }
             cgequa,      { => }
             clparen,     { ( }
             crparen,     { ) }
             clbrkt,      { [ }
             crbrkt,      { ] }
             clct,        { left comment }
             crct,        { right comment }
             cbcms,       { := }
             cperiod,     { . }
             ccma,        { , }
             cscn,        { ; }
             ccln,        { : }
             ccmf,        { ^ }
             crange,      { .. }
             cdiv,        { div }
             cmod,        { mod }
             cnil,        { nil }
             cin,         { in }
             cor,         { or }
             cand,        { and }
             cxor,        { xor }
             cnot,        { not }
             cif,         { if }
             cthen,       { then }
             celse,       { else }
             ccase,       { case }
             cof,         { of }
             crepeat,     { repeat }
             cuntil,      { until }
             cwhile,      { while }
             cdo,         { do }
             cfor,        { for }
             cto,         { to }
             cdownto,     { downto }
             cbegin,      { begin }
             cend,        { end }
             cwith,       { with }
             cgoto,       { goto }
             cconst,      { const }
             cvar,        { var }
             ctype,       { type }
             carray,      { array }
             crecord,     { record }
             cset,        { set }
             cfile,       { file }
             cfunction,   { function }
             cprocedure,  { procedure }
             clabel,      { label }
             cpacked,     { packed }
             cprogram,    { program }
             cforward,    { forward }
             cmodule,     { module }
             cuses,       { uses }
             cprivate,    { private }
             cexternal,   { external }
             cview,       { view }
             cfixed,      { fixed }
             cprocess,    { process }
             cmonitor,    { monitor }
             cshare,      { share }
             cclass,      { class }
             cis,         { is }
             catom,       { atom }
             coverload,   { overload }
             coverride,   { override }
             creference,  { creference }
             cthread,     { cthread }
             cjoins,      { cjoins }
             cstatic,     { cstatic }
             cinherited,  { cinherited }
             cself,       { cself }
             cvirtual,    { virtual }
             ctry,        { try }
             cexcept,     { except }
             cextends,    { extends }
             cresult,     { result }
             con,         { on }
             cinteger,    { unsigned integer constant }
             cidentifier, { identifier }
             cstring,     { string constant }
             creal,       { real constant }
             ceof);       { end of file (must be last tolken) }
   tolkset = set of tolken; { set of tolkens }
   labinx = 1..labmax; { index for label }
   labl   = packed array [labinx] of char; { label }
   chrinx = 1..chrmax; { special character index }
   chrstr = packed array [1..spcmax] of char; { special character string }
   chrequ = record { special character table entry }

               lab:  chrstr;   { characters }
               tolk: tolken;   { equivalent tolken }
               chn:  0..chrmax { next entry chain }

            end;
   resinx = 1..resmax; { index for reserved table }
   resequ = record { reserved word table entry }

               lab:  pstring;     { reserved word }
               tolk: tolken;   { equivalent tolken }
               chn:  0..resmax { chain to next entry }

            end;
   filinx = 1..filmax; { index for filename }
   filnam = packed array [filinx] of char;
   cmdinx = 1..linmax; { command line index }
   cmdbuf = packed array [cmdinx] of char; { command line buffer }
   srcptr = ^srcrec; { source file entry pointer }
   srcrec = record

               fil:    text;    { file }
               nam:    filnam;  { filename }
               lincnt: integer; { line count within file }
               chrcnt: integer; { character count within file }
               linmax: integer; { demo line limit }
               chrmax: integer; { demo character limit }
               line:   cmdbuf;  { buffered line }
               lptr:   cmdinx;  { pointer for buffered line }
               next:   srcptr   { next entry linkage }

            end;
   filept = ^filety; { file name entry pointer }
   filety = record

               nam:    filnam;  { filename }
               next:   filept   { next entry linkage }

            end;
   fllptr = ^fllrec; { file list entry pointer }
   fllrec = record

               fst:  filept; { source file linear list }
               lst:  filept; { last file in list }
               cur:  filept; { current file processing }
               stk:  srcptr; { open files stack }
               next: fllptr  { next entry linkage }

            end;
   ext    = packed array [1..3] of char; { file extention }
   typptr = ^typ; { type pointer }
   modptr = ^modtrk; { module tracking entry pointer }
   symptr = ^sym; { symbol pointer }
   sym    = record { symbol entry }
     
               next: symptr;  { next list entry }
               rnxt: symptr;  { next field label entry (for records),
                                also used for general listing }
               lvl:  integer; { block level }
               seq:  integer; { last reference scope sequence tag }
               dup:  boolean; { symbol is duplicated (2-N times) }
               mis:  boolean; { symbol is the target of a mispell }
               udf:  boolean; { symbol is missing definition }
               ddf:  boolean; { symbol undergoing delayed definition }
               hld:  boolean; { symbol is being 'held' pending definition }
               exp:  boolean; { symbol is exportable }
               out:  boolean; { symbol has been output to intermediate }
               ref:  integer; { reference count }
               typ:  typptr;  { pointer to symbol type }
               lab:  pstring; { symbol label }
               dra:  boolean; { is a downreference alias symbol }
               modp: modptr;  { module this symbol belongs to }
               prv:  boolean; { symbol is private/public }

            end;
   syminx = 1..symmax; { index for symbol head table }
   { built in procedure/function dispatch codes }
   prcfnc = (pfnil,       { none, general procedure/function }
             pfabs,       { f: abs }
             pfarctan,    { f: arctan }  
             pfchr,       { f: chr }    
             pfcos,       { f: cos }    
             pfeof,       { f: eof }   
             pfeoln,      { f: eoln }    
             pfexp,       { f: exp }     
             pfln,        { f: ln }    
             pfodd,       { f: odd }    
             pford,       { f: ord }   
             pfpred,      { f: pred }  
             pfround,     { f: round }   
             pfsin,       { f: sin }    
             pfsqr,       { f: sqr }   
             pfsqrt,      { f: sqrt }   
             pfsucc,      { f: succ }  
             pftrunc,     { f: trunc } 
             pfexists,    { f: exists }
             pflocation,  { f: location }
             pflength,    { f: length }
             pfmax,       { f: max }
             pfdispose,   { p: dispose }
             pfget,       { p: get }    
             pfnew,       { p: new }   
             pfpack,      { p: pack }   
             pfpage,      { p: page }    
             pfput,       { p: put }   
             pfread,      { p: read } 
             pfreadln,    { p: readln }  
             pfreset,     { p: reset }
             pfrewrite,   { p: rewrite } 
             pfunpack,    { p: unpack } 
             pfwrite,     { p: write } 
             pfwriteln,   { p: writeln } 
             pfassign,    { p: assign }  
             pfclose,     { p: close }  
             pfposition,  { p: position }
             pfdelete,    { p: delete }  
             pfchange,    { p: change }  
             pfhalt,      { p: halt }
             pfrefer,     { p: refer }
             pfupdate,    { p: update }
             pfappend,    { p: append }
             pfsignal,    { p: signal }
             pfsignalone, { p: signalone }
             pfwait,      { p: wait }
             pfthrow,     { p: throw }
             pfassert);   { p: assert }
   { file variable special handling codes }
   fshan = (fsnone,     { no special handling }
            fsreset,    { apply reset }
            fsrewrite,  { apply rewrite }
            fshparm,    { is unresolved header parameter }
            fsherr);    { is errored header parameter }
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
   types  = (tudf,        { no type, used to mark errors }
             tnil,        { 'nil' universal pointer }
             tlab,        { goto label }
             ticst,       { integer constant }
             tscst,       { string constant }
             tccst,       { character constant }
             trcst,       { real constant }
             tstcst,      { set constant }
             tstet,       { set constant entry }
             tarrcst,     { array constant entry }
             tarrcel,     { array constant element }
             treccst,     { record constant entry }
             treccel,     { record constant element }
             tenum,       { enumerated }
             tenme,       { enumerated constant }
             tsub,        { subrange }
             tptr,        { pointer }
             tarray,      { array }
             tgarry,      { general array }
             tfile,       { file }
             tset,        { set }
             trecord,     { record }
             tfield,      { record field }
             tftag,       { record tag field }
             tfcas,       { record variant case }
             tvar,        { variable }
             tfix,        { fixed }
             tproc,       { procedure }
             tfunc,       { function }
             tpar,        { parameter }
             tvpar,       { variable parameter }
             twpar,       { view parameter }
             tpproc,      { procedure parameter }
             tpfunc,      { function parameter }
             tinteger,    { integer }
             tlinteger,   { long integer }
             tcardinal,   { cardinal }
             tlcardinal,  { long cardinal }
             tchar,       { character }
             tboolean,    { boolean }
             treal,       { real }
             tsreal,      { short real }
             ttext,       { text }
             teset,       { empty set }
             tddf,        { delayed definition }
             tglbl,       { global block }
             tsemaphore,  { semaphore }
             tclass,      { class }
             tatom,       { atom }
             tthread,     { thread }
             treference,  { reference }
             texception); { exception }
   typ    = record { type entry }
            
               next: typptr; { next list entry }
               list: typptr; { general list maker link }
               pack: boolean; { packed type flag }
               lvl:  integer; { level number of type entry }
               num:  integer; { sequence number of type entry }
               classt: typptr; { class type, if any }
               case t: types of { types }

                  tudf:       ();              { dummy entry to mark errors }
                  tnil:       ();              { 'nil' universal pointer }
                  tlab:       (ldef: boolean;  { label has been defined }
                               lref: integer;  { number of 'goto' references }
                               slvl: integer;  { statement level at definition }
                               mlvl: integer;  { mimumum reference level }
                               extr: boolean;  { block external references 
                                                 exist }
                               lnxt: typptr);  { next label in block list }
                  ticst:      (ival: ssint);   { the value of the integer }
                  tscst:      (sval: pstring); { the value of the string }
                  tccst:      (cval: char);    { character constant }
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
                               arri: typptr);  { index type }
                  tgarry:     (gart: typptr);  { base type }
                  tfile:      (filt: typptr);  { base type }
                  tset:       (sett: typptr;   { base type }
                               setc: boolean); { set is 'in context' }
                  trecord:    (recf: typptr;   { field list }
                               recl: symptr);  { list of field labels }
                  tfield:     (fldn: typptr;   { next field pointer }
                               fldh: typptr;   { head entry pointer }
                               fldt: typptr);  { base type }
                  tftag:      (ftgc: typptr;   { case list }
                               ftgh: typptr;   { head entry pointer }
                               ftgt: typptr;   { base type }
                               ftge: boolean); { exists flag }
                  tfcas:      (fcsn: typptr;   { next case entry pointer }
                               fcsf: typptr;   { field list }
                               fcss: ssint;    { case constant start }
                               fcse: ssint);   { case constant end }
                  tvar:       (vart: typptr;   { base type }
                               varr: integer;  { threat count }
                               varf: integer;  { 'for' use count }
                               vars: fshan;    { file special handling }
                               vare: boolean;  { variable is external }
                               varmd: integer; { module ordinal number }
                               varh: typptr;   { used to form header file lists }
                               varp: boolean;  { was threatened by subroutine }
                               varm: boolean); { is a member of an object }
                  tfix:       (fixt: typptr;   { base type }
                               fixc: typptr;   { constant fill }
                               fixe: boolean;  { fixed is external }
                               fixmd: integer); { module ordinal number }
                  tproc:      (prcp:  typptr;  { parameter list }
                               prcd:  prcfnc;  { dispatch code }
                               prcf:  boolean; { procedure is forwarded }
                               prcs:  symptr;  { parameter symbols save for fwd }
                               prct:  typptr;  { parameter types save for fwd }
                               prce:  boolean; { procedure is external }
                               prcmd: integer; { procedure module ordinal number }
                               prca:  boolean; { procedure is assembly ('external') }
                               prco:  typptr;  { overload list link }
                               prch:  typptr;  { overload list head }
                               prcx:  boolean; { overload collide flag }
                               prcq:  boolean; { procedure is a deleted forward
                                                 overload }
                               prcg:  boolean; { procedure is static (global) }
                               prcv:  boolean; { procedure is virtual }
                               prcz:  typptr;  { override list }
                               prcu:  typptr;  { override head }
                               prcm:  boolean); { is a member of an object }
                  tfunc:      (fncp:  typptr;   { parameter list }
                               fncr:  typptr;   { function result }
                               fncd:  prcfnc;   { dispatch code }
                               fncc:  integer;  { reference counter }
                               fncf:  boolean;  { function is forwarded }
                               fncs:  symptr;   { parameter symbols save for  
                                                 fwd }
                               fnct:  typptr;   { parameter types save for fwd }
                               fnce:  boolean;  { function is external }
                               fncmd: integer; { procedure module ordinal number }
                               fnca:  boolean;  { function is assembly ('external') }
                               fnco:  typptr;   { overload list link }
                               fnch:  typptr;   { overload list head }
                               fncx:  boolean;  { overload collide flag }
                               fncq:  boolean;  { function is a deleted forward
                                                 overload }
                               fncg: boolean;  { function is static (global) }
                               fncv: boolean;  { function is virtual }
                               fncz: typptr;   { override pair }
                               fncu: typptr;   { override head }
                               fncm: boolean); { is a member of an object }
                  tpar:       (parn: typptr;   { next parameter }
                               part: typptr;   { base type }
                               parh: typptr;   { head entry pointer }
                               parr: integer); { threat count }
                  tvpar:      (vprn: typptr;   { next parameter }
                               vprt: typptr;   { base type }
                               vprh: typptr;   { head entry pointer }
                               vprr: integer); { threat count }
                  twpar:      (wprn: typptr;   { next parameter }
                               wprt: typptr;   { base type }
                               wprh: typptr);  { head entry pointer }
                  tpproc:     (pprp: typptr;   { parameter list }
                               pprn: typptr);  { next parameter }
                  tpfunc:     (pfnp: typptr;   { parameter list }
                               pfnr: typptr;   { function result }           
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
                  tddf:       (ddfs: symptr;   { undefined symbol }
                               ddft: typptr;   { base type }
                               ddfd: boolean;  { type has been defined }
                               ddfe: boolean;  { error has been processed }
                               ddfr: symptr);  { downreference symbol }
                  tglbl:      (mm: modmrk);    { module type }
                  tsemaphore: ();              { semaphore type }
                  tclass:     (clsi: typptr;   { base class }
                               clss: modptr;   { symbols module }
                               clst: typptr;   { types contained in class }
                               clsr: typptr);  { class self reference variable }
                  tatom:      (atmi: typptr;   { base class }
                               atms: modptr;   { symbols module }
                               atmt: typptr;   { types contained in atom }
                               atmr: typptr);  { class self reference variable }
                  tthread:    (thdi: typptr;   { base class }
                               thds: modptr;   { symbols module }
                               thdt: typptr;   { types contained in thread }
                               thdr: typptr);  { class self reference variable }
                  treference: (reft: typptr);  { reference type }
                  texception: ();              { exception type }

               { end }

            end;
   typset = set of types; { set of types }
   blkptr = ^blkrec; { pointer to block stack entry }
   blkrec    = record { type stack entry }

               next:  blkptr;  { next entry }
               typ:   typptr;  { type list for block }
               lst:   typptr;  { last entry in type list }
               upd:   typptr;  { sequential update pointer, indexes the first
                                 entry not yet output }
               blk:   pstring; { block id }
               seq:   integer; { sequence number }
               lvl:   integer; { level number of this block }
               mark:  typptr;  { mark entry for block }
               marks: symptr   { symbol for mark }

            end;
   { Case value chain entry. Keeps track of case select values so that 
     duplicates can be checked. }
   csvptr = ^casval; { pointer to }
   casval = record { entry }

      svals: boolean; { sign of starting selector }
      sval: integer; { starting value of selector }
      evals: boolean; { sign of ending selector }
      eval: integer; { ending value of selector }
      def:  boolean; { value is defined }
      next: csvptr { next entry }

   end;
   { procedure/function "winnow" list, gives enties for a list of candidate
     procedures or functions that are removed from the list as parameters are
     parsed. }
   winptr = ^winety; { pointer to entry }
   winety = record { entry }

      prcfnc: typptr; { procedure or function candidate }
      next:   winptr { next entry }

   end; 
   { goto tracking entry }
   gtoptr = ^gtotrk; { pointer to entry }
   gtotrk = record { entry }

      next: gtoptr; { next entry in list }
      lab:  typptr { label that goto indexes }
      
   end;
   { symbol table hash table }
   symhsh = array [syminx] of symptr;
   { module tracking entry }
   modtrk = record { entry }

      next:    modptr;  { next entry (for all modules) }
      inx:     integer; { number of entry, 1-n }
      modn:    pstring; { module name }
      modf:    pstring; { module filename, fully pathed }
      symtbl:  symhsh   { symbol chain table }

   end;
   { Module listing entries. These are entries that form lists of modules for
     uses or joins purposes. }
   mltptr = ^mltety;
   mltety = record

      next: mltptr; { next entry }
      modp: modptr { module entry }
      
   end;
   { 'with' nesting entries }
   wthptr = ^wthety;
   wthety = record

      next: wthptr; { next entry }
      varp: typptr  { pointer to base entry }

   end;
   { languages (not all currently supported) }
   lang = (lang_english,     { english }
           lang_french,      { french }
           lang_spanish,     { spanish }
           lang_german,      { german }
           lang_italian,     { italian }
           lang_portuguese); { portuguese }
   { errors }
   errcod = (enull,        { No error }
             efnfn,        { File not found }
             enfmt,        { Invalid numeric format }
             enfmtnz,      { Invalid numeric format (without zero) }
             erfmt,        { Invalid real format }
             edbr,         { Digit beyond radix }
             enovf,        { Input numeric overflow }
             eexpovf,      { Exponent overflow }
             emquo,        { Quote expected }
             echrrng,      { Character value out of range }
             eivsym,       { Invalid symbol/character }
             eifil,        { Invalid file specification }
             eioptp,       { Invalid option position }
             eterm,        { 'include' option must be alone on line }
             eopt,         { Invalid option }
             ecmdsyn,      { Command line syntax invalid }
             eiovf,        { Input line too long }
             eefns,        { Error file not specified }
             ecmtfe,       { Comment terminated by file end }
             elpexp,       { '(' expected }
             erpexp,       { ')' expected }
             elbkexp,      { '[' expected }
             erbkexp,      { ']' expected }
             escnexp,      { ';' expected }
             eperexp,      { '.' expected }
             eequexp,      { '=' expected }
             eclnexp,      { ':' expected }
             ebcmexp,      { ':=' expected }
             erngexp,      { '..' expected }
             empexp,       { 'module'/'program' expected }
             eprgexp,      { 'program' expected }
             ebgnexp,      { 'begin' expected }
             eendexp,      { 'end' expected }
             ethnexp,      { 'then' expected }
             eofexp,       { 'of' expected }
             edoexp,       { 'do' expected }
             eutlexp,      { 'until' expected }
             etdtexp,      { 'to'/'downto' expected }
             eidnexp,      { Identifier expected }
             eintexp,      { Integer expected }
             eilexp,       { Integer/label expected }
             eeofexp,      { End of file expected }
             einvfact,     { Invalid factor }
             einvcst,      { Invalid constant }
             einvpob,      { Invalid packed object }
             edecor,       { Declarations out of order }
             erbcmexp,     { ']' or ',' expected }
             erpcmexp,     { ')' or ',' expected }
             ecncmexp,     { ':' or ',' expected }
             escrpedexp,   { ';', ')' or 'end' expected }
             etypexp,      { Type expected }
             ecstexp,      { Constant expected }
             eordexp,      { Ordinal type expected }
             erpscexp,     { ')' or ';' expected }
             eprctyp,      { Procedure should not have result type }
             esccmexp,     { ';' or ',' expected }
             emspell,      { 'x' assumed to be a misspelled 'y' }
             eedscexp,     { 'end' or ';' expected }
             eutscexp,     { 'until' or ';' expected }
             eedutscelexp, { 'end', 'until' or ';' expected }
             edocmexp,     { 'do' or ',' expected }
             einvexp,      { Invalid expression }
             earrexp,      { 'array' expected }
             einvfld,      { Invalid field specification }
             eofcnexp,     { 'of' or ':' expected }
             einvblk,      { Invalid declaration }
             elpscexp,     { '(' or ';' expected }
             elpsccnrpexp, { '(', ';', ':' or ')' expected }
             einvgln,      { Invalid goto label number }
             edupsym,      { Duplicate symbol }
             esymnf,       { Symbol not found }
             esymnr,       { Symbol defined but not referenced }
             esymtyp,      { Symbol not appropriate type }
             etypcon,      { Type invalid for context }
             embschr,      { String must be single character }
             etypcmp,      { Types are not compatible }
             einvsub,      { Invalid subrange }
             eneqalt,      { Use of '><' alternative }
             eleqalt,      { Use of '=<' alternative }
             egeqalt,      { Use of '=>' alternative }
             emcasv,       { Missing variant case label }
             edcasv,       { Duplicated variant case label }
             efilcom,      { File component not allowed }
             elabdef,      { Label aready defined }
             elabndf,      { Label not defined }
             elabref,      { Label not referenced }
             evartex,      { Variable type expected }
             earrtex,      { Array type expected }
             erectex,      { Record type expected }
             eptrtex,      { Pointer or file type expected }
             ensftr,       { No such field this record }
             eidxtyp,      { Index not compatile with index type }
             etmbbol,      { Type must be boolean }
             einvstb,      { Invalid set builder element type }
             etmbord,      { Type must be ordinal }
             ecmborc,      { Case label must be ordinal constant }
             evarmbl,      { Variable must be local }
             evarext,      { 'for' index variable cannot be external }
             etmpar,       { Too many parameters }
             etlpar,       { Too few parameters }
             eparcmp,      { Not compatible with parameter type }
             evarcmp,      { Variable parameter must be same type }
             ewrtpar,      { Parameter of write/writeln incorrect type }
             efldpar,      { Type of field width specification must be 
                             integer }
             efrcpar,      { Type of fractional digits spec must be integer }
             embfunc,      { Must be function label }
             embfnty,      { Must be function or type label }
             embproc,      { Must be procedure label }
             embtext,      { Writeln may output to textfile only }
             efldtxt,      { Field specifications can only be applied to text
                             file output }
             efmbfp,       { File must be first parameter of write }
             efilcmp,      { Not compatible with output file }
             efaslvl,      { Assignment of result to function not current }
             embroi,       { Parameter must be real or integer }
             embint,       { Parameter must be integer }
             embfil,       { Parameter must be file }
             embtxt,       { Parameter must be text file }
             embord,       { Parameter must be ordinal }
             embrl,        { Parameter must be real }
             embstr,       { Parameter must be string type }
             emnbtxt,      { Parameter cannot be text file type }
             ecmaexp,      { ',' expected }
             erdpar,       { Parameter of read/readln incorrect type }
             embarr,       { Parameter must be array }
             embupk,       { Parameter must be unpacked array }
             embpk,        { Parameter must be packed array }
             embscmp,      { Packed and unpacked arrays must have same 
                             component type }
             eidxcmp,      { Starting index not compatible with unpacked array
                             Index type }
             embptr,       { Parameter must be pointer }
             embrec,       { Tagfield definition parameters can only be applied
                             to variant records }
             entagf,       { Not a variant record }
             ercvcmp,      { Tagfield value not compatible with record variant 
                             tagfield type }
             ercvnf,       { No variant case found for specified tagfield }
             embcst,       { Parameter must be constant }
             enfncr,       { Function must have result type }
             escncmp,      { Set constructors do not match }
             easscmp,      { Type not assignment compatible }
             enihdf,       { 'input' header file not defined }
             enohdf,       { 'output' header file not defined }
             ecascmp,      { Case label not compatible with case selector }
             evidexp,      { Variable identifier expected }
             eplicp,       { Parameter list incomplete }
             eapreal,      { Fraction applicatable to real only }
             efwddef,      { Bad forward definition }
             emfwddef,     { Missing forward definition }
             efwdnptr,     { Forward referenced symbol not ref by pointer }
             eslfref,      { Invalid self reference }
             enfncra,      { No function result given }
             evarass,      { Variable never assigned }
             eforviu,      { 'for' variable in use }
             eforvst,      { 'for' variable subject to subprocedure or
                             subfunction threat }
             efmbvar,      { Parameter with file component must be passed VAR }
             evarmbr,      { Variable access must be record }
             efwdmat,      { Forwarded declaration does not match }
             efwdpar,      { Forwarded declaration should not have 
                             Parameters/result }
             eparrep,      { Repetition of parameter list not allowed }
             eresrep,      { Repetition of function result not allowed }
             eardfwd,      { Procedure/function already forwarded }
             efwdndf,      { Forwarded procedure/function never defined }
             etagvar,      { Tagfield cannot appear as variable parameter }
             epakvar,      { Packed component cannot appear as variable param }
             edivzer,      { Divide by zero }
             emodneg,      { Modulo by negative }
             earrbnd,      { Array reference out of bounds }
             elnlez,       { Parameter of 'ln' less than or equal to zero }
             esqrtneg,     { Parameter of 'sqrt' negative }
             erange,       { Value out of range for type }
             epupbnd,      { Pack/unpack operation specs elements beyond 
                             bounds }
             eassrng,      { Value out of range for destination of assignment }
             elabblk,      { Label must be defined in same block as declared }
             egtolvl,      { Goto target at invalid statement level }
             egtoenc,      { Goto label is not in enclosing statements }
             elabrlv,      { Goto label was referenced by lesser level }
             elabrds,      { Goto label was referenced by different nested 
                             statement }
             elabext,      { Label referenced external, but is not at level 1 }
             epgmext,      { Program cannot have exit section }
             etmbboi,      { Type must be boolean or integer }
             ebolneg,      { Cannot perform boolean operation on negative }
             eoivspf,      { Operation invalid on special file }
             eprncon,      { Parameter lists not congruous }
             efnncon,      { Function result not congruous }
             eplslen,      { Parameter list lengths not equal }
             eviewth,      { View parameter threatened }
             ealcgar,      { Attempt to allocate general array }
             embgar,       { Parameter must be general array }
             ecmedexp,     { ',' or 'end' expected }
             efixth,       { Fixed threatened }
             estelen,      { Structured constant length does not match type }
             einvcse,      { Invalid elements for constant structure }
             estccmp,      { Constant does not match structure }
             ecasmat,      { No case match for selector }
             etagord,      { Tag type must be ordinal }
             elvarexp,     { Must be local variable }
             eshrent,      { Share must not have entry section }
             eppsext,      { Program, process or share cannot have exit sect }
             euseukn,      { Used module type is unknown }
             eprgmat,      { Program name does not match filename }
             emodmat,      { Module name does not match filename }
             emoduse,      { Server module is incorrect type for client }
             eshrvar,      { Variables not allowed in 'share' module }
             emonptr,      { Monitor procedure/function parameter is pointer }
             emonvar,      { Variables appear in monitor export section }
             ecstopv,      { Constant operation overflows }
             eintovf,      { Integer overflow }
             ehfudf,       { Undefined header file on block }
             esfnprp,      { Attempt to pass system func/proc as param }
             ecasdup,      { Case constant was duplicated }
             efprcexp,     { 'procedure' or 'function' expected }
             enfnctoo,     { No procedure or function exists to overload }
             eofncisp,     { Procedure or function overloaded is parameter }
             enfncmat,     { No function or procedure matches parameter }
             embvarpar,    { Parameter must be variable reference }
             epfparov,     { Procedure/function param cannot be overloaded }
             einvovl,      { Procedure/function overload is not unique enough }
             efwdondf,     { Forwarded overload procedure/function never defined }
             econovl,      { Convergent overload parameter modes do not match }
             epfpovl,      { Procedure/function parameter must not be overloaded }
             easprc,       { Cannot assign function result to procedure }
             edemlim,      { Demo limit exceeded }
             edempgm,      { Demo version cannot compile non-program module }
             edemmlf,      { Demo version cannot compile multiple files }
             edeminc,      { Demo version cannot have include files }
             estrnul,      { String/character must have at least one character }
             efncprcs,     { Procedure/function not allowed in standard mode }
             erefdec,      { Symbol referenced before declaration }
             edradef,      { Forward type reference already defined }
             eupdtxt,      { Cannot 'update' text file }
             earrlen,      { Array length must be integer }
             euseovf,      { Uses path overflow }
             edupsta,      { Duplicated static attribute }
             edupovl,      { Duplicated overload attribute }
             embsema,      { Parameter must be semaphore }
             eexsconexp,   { ';' or 'on', 'except' expected }
             embbol,       { Parameter must be boolean type }
             edupmod,      { Current module conflicts with previous }
             ejnsnf,       { 'joins' symbol reference not found }
             edupqual,     { Module already a joins or uses module }
             esyslab,      { System label not allowed }
             edupvir,      { Duplicated virtual attribute }
             edupovr,      { Duplicated override attribute }
             eattcon,      { Conflicting attributes }
             envirtoo,     { No procedure or function exists to override }
             evirmat,      { Virtual procedure/function type must match it's
                             overrider }
             evirmbe,      { Virtual procedure/function must be external }
             envirpf,      { Original procedure/function is not virtual }
             eovrdup,      { Override already exists in this module }
             einhmbpfc,    { 'inherited' attribute must be used on procedure or 
                             function call }
             einhpfp,      { 'inherited' attribute cannot be used on procedure
                             or function parameter }
             ecalmbor,     { Inherited procedure or function call must be 
                             override }
             efwdatt,      { Forwarded procedure or function attributes do not 
                             match }
             efwdorndf,    { Forwarded override procedure/function never defined }
             eclsexp,      { Class expected }
             eclsnf,       { Identifier not found in class }
             edircls,      { Must access class member via reference }
             etoexp,       { 'to' expected }
             ercrftex,     { Record or reference type expected }
             ensmtc,       { No such member this class }
             enacmem,      { Not a class member }
             enmemtc,      { Not a member of this class }
             ememvar,      { Member must be variable here }
             eidsexp,      { Identifier or 'self' expected }
             eclsact,      { No class is currently active for 'self' reference }
             eclsgbl,      { Class must be declared in global module }
             eovlnpf,      { Overload must be to procedure or function }
             eovrnpf,      { Override must be to procedure or function }
             embpor,       { Parameter must be pointer or reference }
             einhuse,      { Cannot access inherited method here }
             eovrmod,      { Override to module procedure/function must be
                             Global }
             eovrscls,     { Override to same class as virtual }
             eovrcdup,     { Override already exists in this class }
             eovrnic,      { No override exists in current class }
             evarmbrr,     { Variable access must be record or reference }
             esnfim,       { Symbol not found in module }
             eunfmql,      { Unfinished module qualifier }
             evidsexp,     { Variable identifier or 'self' expected }
             earrdpt,      { Array depth exceeds actual depth }
             einvtrng,     { invalid variant case label range }
             ersltlvl,     { anonymous function result must be at outter level }
             ersltend,     { missing 'end' after anonymous function result }
             ersltfnc,     { anonymous function result not directly enclosed in
                             function }
             ersltmix,     { anonymous and named function result assignments 
                             were mixed }
             eextinv,      { external assembly routines not allowed (use a module) }
             esemmod,      { cannot use semaphore outside of monitor }
             esigwatmon,   { cannot use signal or wait outside of monitor }
             embexp,       { Parameter must be exception }
             eexexp,       { 'except' expected }

             { system errors, * = available }
             esflt1,       { system fault 1: Notify Moore/CAD }
             esflt2,       { system fault 2: Notify Moore/CAD }
             esflt3,       { system fault 3: Notify Moore/CAD }
             esflt4,       { system fault 4: Notify Moore/CAD }
             esflt5,       { system fault 5: Notify Moore/CAD }
             esflt6,       { system fault 6: Notify Moore/CAD }
             esflt7,       { system fault 7: Notify Moore/CAD }
             esflt8,       { system fault 8: Notify Moore/CAD }
             esflt9,       { system fault 9: Notify Moore/CAD }
             esflt10,      { system fault 10: Notify Moore/CAD }
             esflt11,      { system fault 11: Notify Moore/CAD }
             esflt12,      { system fault 12: Notify Moore/CAD }
             esflt13,      { system fault 13: Notify Moore/CAD }
             esflt14,      { system fault 14: Notify Moore/CAD }
             esflt15,      { system fault 15: Notify Moore/CAD }
             esflt16,      { system fault 16: Notify Moore/CAD }
             esflt17,      { system fault 17: Notify Moore/CAD }
             esflt18,      { system fault 18: Notify Moore/CAD }
             esflt19,      { system fault 19: Notify Moore/CAD }
             esflt20,      { system fault 20: Notify Moore/CAD }
             esflt21,      { system fault 21: Notify Moore/CAD }
             esflt22,      { system fault 22: Notify Moore/CAD }
             esflt23,      { system fault 23: Notify Moore/CAD }
             esflt24,      { system fault 24: Notify Moore/CAD }
             esflt25,      { system fault 25: Notify Moore/CAD }
             esflt26,      { system fault 26: Notify Moore/CAD }
             esflt27,      { system fault 27: Notify Moore/CAD }
             esflt28,      { system fault 28: Notify Moore/CAD }
             esflt29,      { system fault 29: Notify Moore/CAD }
             esflt30,      { system fault 30: Notify Moore/CAD }
             esflt31,      { system fault 31: Notify Moore/CAD }
             esflt32,      { system fault 32: Notify Moore/CAD }
             esflt33,      { system fault 33: Notify Moore/CAD }
             esflt34,      { system fault 34: Notify Moore/CAD }
             esflt35,      { system fault 35: Notify Moore/CAD }
             esflt36,      { system fault 36: Notify Moore/CAD }
             esflt37,      { system fault 37: Notify Moore/CAD }
             esflt38,      { system fault 38: Notify Moore/CAD }
             esflt39,      { system fault 39: Notify Moore/CAD }
             esflt40,      { system fault 40: Notify Moore/CAD }
             esflt41,      { system fault 41: Notify Moore/CAD }
             esflt42,      { system fault 42: Notify Moore/CAD }
             esflt43,      { system fault 43: Notify Moore/CAD }
             esflt44,      { system fault 44: Notify Moore/CAD }
             esflt45,      { system fault 45: Notify Moore/CAD }
             esflt46,      { system fault 46: Notify Moore/CAD }
             esflt47,      { system fault 47: Notify Moore/CAD }
             esflt48,      { system fault 48: Notify Moore/CAD }
             esflt49,      { system fault 49: Notify Moore/CAD }
             esflt50,      { system fault 50: Notify Moore/CAD }
             esflt51,      { *system fault 51: Notify Moore/CAD }
             esflt52,      { *system fault 52: Notify Moore/CAD }
             esflt53,      { *system fault 53: Notify Moore/CAD }
             esflt54,      { *system fault 54: Notify Moore/CAD }
             esflt55,      { *system fault 55: Notify Moore/CAD }
             esflt56,      { *system fault 56: Notify Moore/CAD }
             esflt57,      { *system fault 57: Notify Moore/CAD }
             esflt58,      { *system fault 58: Notify Moore/CAD }
             esflt59);     { *system fault 59: Notify Moore/CAD }

begin
end.
