{*******************************************************************************
*                                                                              *
*                           PARSER COMMON MODULE                               *
*                                                                              *
*                             9/89 S. A. Moore                                 *
*                                                                              *
* Contains common (global) variables for the parser.                           *
*                                                                              *
*******************************************************************************}

module common;

uses parsedef;

var

   { Parameters of the processor we are running on }

   bits:   integer; { number of bits in integer }
   bytes:  integer; { number of bytes in integer }
   digits: integer; { number of digits in integer }
   toppow: integer; { top byte power, precalculated for speed }

   { This block of variables communicates with the scanner }

   nxttlk:   tolken;  { next tolken }
   nxtlab:   labl;    { next label/string }
   nxtlen:   integer; { next length of string }
   nxtint:   integer; { next integer }
   nxtflt:   real;    { next real }

   spctbl:   array [chrinx] of chrequ; { special character table }
   restbl:   array [resinx] of resequ; { reserved words table }
   console:  text;    { console file }
   errnam:   filnam;  { error file name }
   errfil:   text;    { error output file }
   srcusd:   srcptr;  { source file used entries }
   fllstk:   fllptr;  { file lists stack }
   fllfre:   fllptr;  { file lists entry free list }
   fverb:    boolean; { verbose flag }
   ferrf:    boolean; { no error output file }
   ferro:    boolean; { not open }
   fansi:    boolean; { ansi standard flag }
   fsupp:    boolean; { output file supressed }
   fsrc:     boolean; { source line present }
   ftolken:  boolean; { output tolkens (diagnostic) }
   flist:    boolean; { output source lines as read (diagnostic) }
   fparse:   boolean; { output parsing rules (diagnostic) }
   ferrsup:  boolean; { parser error suppression flag }
   fsym:     boolean; { symbols print flag (diagnostic) }
   fref:     boolean; { complain about never refernces }
   ffncrs:   boolean; { check function result assigned }
   ftype:    boolean; { output types table (diagnostic) }
   fnovf:    boolean; { bypass overflow checks }
   fllct:    boolean; { output line count }
   fllvl:    boolean; { output block level count }
   flslv:    boolean; { output statement level count }
   flsymt:   boolean; { output symbol entry telemetry }
   fltypt:   boolean; { output type entry telemetry }
   fltlk:    boolean; { output tolken count }
   fllst:    boolean; { output line status }
   frecir:   boolean; { enable used memory recirculation (diagnostic) }
   fass:     boolean; { process assignment checks }
   frange:   boolean; { process range checks }
   fsyslab:  boolean; { allow leading "_" in labels }
   fintopn:  boolean; { the output intermediate file is open }
   errcnt:   integer; { total errors found }
   errlim:   integer; { maximum allowable errors }
   errfn:    filnam;  { filename in errors }
   exprset:  tolkset; { expression start tolkens }
   statset:  tolkset; { statement start tolkens }
   statuset: tolkset; { statement start tolkens unambiguous }
   constset: tolkset; { constant start tolkens }
   typeset:  tolkset; { type start tolkens }
   ordset:   tolkset; { ordinal type start tolkens }
   blockset: tolkset; { block start tolkens }
   decset:   tolkset; { declaration start tolkens }
   deftbl:   array [tolken] of pstring; { tolken definition strings }
   symfre:   symptr; { free symbol entry list }
   symact:   integer; { active symbols counter }
   symfct:   integer; { free symbols counter }
   symcct:   integer; { created symbols counter }
   level:    integer; { scope nesting level }
   sequen:   integer; { scope sequence number }
   curseq:   integer; { current level sequence number }
   typlvl:   integer; { type nesting level }
   stalvl:   integer; { statement nesting level }
   stalab:   typptr;  { statement label list ("forward gotos") }
   stagto:   gtoptr;  { statement goto list ("backward gotos") }
   wthlvl:   integer; { 'with' nesting level }
   scncmt:   boolean; { scanner in comment }
   scnskp:   boolean; { scanner in skip }
   tlkcnt:   integer; { tolkens count }
   blkstk:   blkptr; { block list stack }
   blkfre:   blkptr; { block list entry free stack }
   typfre:   array[types] of typptr; { free type entries arrayed by type }
   typact:   integer; { active types entry counter }
   typfct:   integer; { free types entry counter }
   typcct:   integer; { types created counter }
   gblnil:   typptr; { holds the global 'nil' pointer type }
   gbludf:   typptr; { holds the global 'skeleton key', or a type entry that 
                       matches all other types, passed when an error in type
                       occurs }
   gbleset:  typptr; { holds the global 'empty' set type }
   gblreal:  typptr; { holds the global real type }
   gblsrl:   typptr; { holds the global short real type }
   gblint:   typptr; { holds the global integer type }
   gbllint:  typptr; { holds the global long integer type }
   gblcard:  typptr; { holds the global cardinal type }
   gbllcard: typptr; { holds the global long cardinal type }
   gblchr:   typptr; { holds the global char type }
   gblbool:  typptr; { holds the global boolean type }
   gbltrue:  typptr; { holds the global 'true' type }
   gblfalse: typptr; { holds the global 'false' type }
   gbltxt:   typptr; { holds the global text type }
   gblinp:   typptr; { holds the global 'input' file }
   gblout:   typptr; { holds the global 'output' file }
   gblins:   symptr; { holds the symbol for 'input' file }
   gblots:   symptr; { holds the symbol for 'output' file }
   gblestr:  typptr; { holds the global empty string type (for asserts) }
   curprc:   typptr; { currently active procedure }
   export:   boolean; { in exportable section }
   concon:   integer; { constant delete nesting count }
   intout:   fbyte;   { intermediate output file }
   uselvl:   integer; { uses file nesting level }
   modhead:  tolken; { module type save }
   usepth:   packed array [1..usemax] of char; { uses path }
   valfch:   schar;  { valid file characters }
   casfre:   csvptr; { free case value entry list }
   casact:   integer; { active case values counter }
   casfct:   integer; { free case values counter }
   cascct:   integer; { created case values counter }
   winfre:   winptr; { free winnow entry list }
   winact:   integer; { active winnow counter }
   winfct:   integer; { free winnow counter }
   wincct:   integer; { created winnow counter }
   gtofre:   gtoptr; { free goto entry list }
   gtoact:   integer; { active goto entry counter }
   gtofct:   integer; { free goto counter }
   gtocct:   integer; { created goto counter }
   modlst:   modptr; { complete module list }
   modcnt:   integer; { count of uses/joins modules }   
   uselst:   mltptr; { uses module stack }
   joinlst:  mltptr; { joins module stack }
   mltfre:   mltptr; { free module listing entry }
   sysmlt:   mltptr; { system block list entry }
   curcls:   typptr; { current class entry (if there is one) }
   privat:   boolean; { in private/public declaration section }
   selflab:  symptr; { error label for 'self' }
   decpow:   integer; { decimal top power (digit) }
   wthfre:   wthptr; { 'with' free list }
   wthlst:   wthptr; { active 'with' entries list }

begin       
end.
