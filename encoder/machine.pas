{*******************************************************************************
*                                                                              *
*               I80386-I80786 MACHINE SPECIFIC ENCODER MOODULE                 *
*                                                                              *
*                       Copyright (C) 2004 S. A. Moore                         *
*                                                                              *
*                              Written 2/2004                                  *
*                                                                              *
* Contains all the machine specific information and rotines for Intel series   *
* I80386, I80486, I80586, I80686, and I80786 CPUs. This module encodes 32 bit  *
* mode instructions only. See also the I8088/I8086/I8086/I80286 module, and    *
* and the I8086-64 modules, which also generate code for the x86 series.       *
*                                                                              *
* Besides the list of main section routines this module uses, the interface    *
* to this module consist of the following calls:                               *
*                                                                              *
* sysblk - Allows the mac module to allocate machine specific types into the   *
*          system block 0.                                                     *
*                                                                              *
* paropt - Parses and checks for various options. This gives our module a      *
* chance to set machine specific options.                                      *
*                                                                              *
* sizblk - Sets the variable and other object sizes for the current block.     *
* because nested blocks can be processed before data in the surrounding block  *
* is complete, this may be called multiple times for the same block.           *
*                                                                              *
* allloc - Allocates the locals in the current block. This includes the        *
* parameters. Because nested blocks can be processed before data in the        *
* surrounding block is complete, this may be called multiple times for the     *
* same block.                                                                  *
*                                                                              *
* alnadr - align a given address using a type. Finds the native alignment      *
* of the type, then aligns the address to that.                                *
*                                                                              *
* makvv - Allocate virtual vectors for virtual and override procedures and     *
* functions that don't already have one.                                       *
*                                                                              *
* genblk - Generates the code for the current block, both entry and exit       *
* sections. The registers are assigned, and the block internal graph is fully  *
* traversed and encoded.                                                       *
*                                                                              *
* prtreg - Prints a machine specific register.                                 *
*                                                                              *
* prtflg - Prints a machine flag.                                              *
*                                                                              *
* As much code as possible is kept in the top encoder level, since this is     *
* the per machine level.                                                       *
*                                                                              *
* General workings:                                                            *
*                                                                              *
* The machine section of the encoder uses the concept of the "top block", that *
* is, the top of the block scoping stack. Several operations are carried out   *
* with the implication of operating on that.                                   *
*                                                                              *
* All operations that directly generate code are called "genxxx". These        *
* routines also operate at the intermediate level. The form "genxxxr" is used  *
* to differentiate those from the routines that take registers directly. The   *
* direct register routines are generally simplier and easier to understand,    *
* whereas the intermediate level routines perform some exloration of the       *
* intermediate tree. In general, we try to do as much to the register level as *
* possible because of this.                                                    *
*                                                                              *
*******************************************************************************}

module machine(output);

uses strlib,   { string functions }
     macdef,   { machine definitions }
     encdef,   { encoder defines }
     version,  { version numbers }
     encode;   { encoder top module (for aborts) }

{*******************************************************************************

                            INTERFACE CALLS

                  Contains inbound calls to this module

*******************************************************************************}

procedure sysblk; forward; { allocate machine specifics into system block }
procedure paropt; forward; { parse options }
procedure sizblk; forward; { set block sizes }
procedure allloc; forward; { allocate locals }
procedure genblk; forward;
procedure prtreg(r: regt); forward; { print register string }
procedure prtflg(f: flag); forward; { print flag }
{ align address by type }
procedure alnadr(var addr: integer; tp: typptr); forward;
procedure makvv; forward;

{*******************************************************************************

                            MODULE SPECIFIC

*******************************************************************************}

private

{ this type define is here because it creates a dependency loop }

type

{ Bounds check descriptors are fixed records that are used in the 'bound'
  instruction that contain high and low bounds values. They are allocated
  per block, but exist globally, and we try to reduce their duplication. }
bndptr = ^bndrec; { bounds check descriptor pointer }
bndrec = record { bounds check descriptor tracking record }

   next:   bndptr; { next bound entry }
   low:    ssint;  { lower bound }
   high:   ssint;  { upper bound }
   bnddes: typptr  { the fixed record structure for the check }

end;


{ Multiply powers table -- Generated by powtab.pas.

  The power table is designed to take up to a maximum multiplier such that
  the equivalent adds will take less CPU time than the equivalent multiply
  instruction, without regard for "early out" CPU multiply implementations.
  It is not optimum for size of code, the equivalent sequence can take more
  code space. }

fixed powtab: packed array [1..maxmlt, 1..10] of char = array

   '          ', {  1 }
   'd         ', {  2 }
   'da        ', {  3 }
   'dd        ', {  4 }
   'dda       ', {  5 }
   'dad       ', {  6 }
   'dada      ', {  7 }
   'ddd       ', {  8 }
   'ddda      ', {  9 }
   'ddad      ', { 10 }
   'ddada     ', { 11 }
   'dadd      ', { 12 }
   'dadda     ', { 13 }
   'dadad     ', { 14 }
   'dadada    ', { 15 }
   'dddd      ', { 16 }
   'dddda     ', { 17 }
   'dddad     ', { 18 }
   'dddada    ', { 19 }
   'ddadd     ', { 20 }
   'ddadda    ', { 21 }
   'ddadad    ', { 22 }
   'ddadada   ', { 23 }
   'daddd     ', { 24 }
   'daddda    ', { 25 }
   'daddad    ', { 26 }
   'daddada   ', { 27 }
   'dadadd    ', { 28 }
   'dadadda   ', { 29 }
   'dadadad   ', { 30 }
   'dadadada  ', { 31 }
   'ddddd     ', { 32 }
   'ddddda    ', { 33 }
   'ddddad    ', { 34 }
   'ddddada   ', { 35 }
   'dddadd    ', { 36 }
   'dddadda   ', { 37 }
   'dddadad   ', { 38 }
   'dddadada  ', { 39 }
   'ddaddd    ', { 40 }
   'ddaddda   ', { 41 }
   'ddaddad   ', { 42 }
   'ddaddada  ', { 43 }
   'ddadadd   ', { 44 }
   'ddadadda  ', { 45 }
   'ddadadad  ', { 46 }
   'ddadadada ', { 47 }
   'dadddd    ', { 48 }
   'dadddda   ', { 49 }
   'dadddad   ', { 50 }
   'dadddada  ', { 51 }
   'daddadd   ', { 52 }
   'daddadda  ', { 53 }
   'daddadad  ', { 54 }
   'daddadada ', { 55 }
   'dadaddd   ', { 56 }
   'dadaddda  ', { 57 }
   'dadaddad  ', { 58 }
   'dadaddada ', { 59 }
   'dadadadd  ', { 60 }
   'dadadadda ', { 61 }
   'dadadadad ', { 62 }
   'dadadadada', { 63 }
   'dddddd    ', { 64 }
   'dddddda   ', { 65 }
   'dddddad   ', { 66 }
   'dddddada  ', { 67 }
   'ddddadd   ', { 68 }
   'ddddadda  ', { 69 }
   'ddddadad  ', { 70 }
   'ddddadada ', { 71 }
   'dddaddd   ', { 72 }
   'dddaddda  ', { 73 }
   'dddaddad  ', { 74 }
   'dddaddada ', { 75 }
   'dddadadd  ', { 76 }
   'dddadadda ', { 77 }
   'dddadadad ', { 78 }
   'dddadadada', { 79 }
   'ddadddd   ', { 80 }
   'ddadddda  ', { 81 }
   'ddadddad  ', { 82 }
   'ddadddada ', { 83 }
   'ddaddadd  ', { 84 }
   'ddaddadda ', { 85 }
   'ddaddadad ', { 86 }
   'ddaddadada', { 87 }
   'ddadaddd  ', { 88 }
   'ddadaddda ', { 89 }
   'ddadaddad ', { 90 }
   'ddadaddada', { 91 }
   'ddadadadd ', { 92 }
   'ddadadadda', { 93 }
   'ddadadadad'  { 94 }

end;

var

   fcustrp:  boolean; { use custom trap instructions }
   fpakvar:  boolean; { pack variables }
   fm386:    boolean; { I80386 machine specific }
   fm486:    boolean; { I80486 machine specific }
   fm586:    boolean; { I80586 machine specific }
   flibflt:  boolean; { use library for floating point }
   fspeed:   boolean; { use speed oriented optimizations }
   frngchk:  boolean; { check subranges }
   farrchk:  boolean; { check array bounds }
   fovfchk:  boolean; { check overflow in operations }
   fzdvchk:  boolean; { check zero divide programatically }
   fivochk:  boolean; { check invalid operands }
   fcaschk:  boolean; { check missing case selects }
   fbndins:  boolean; { use bounds instruction }
   fclrlcl:  boolean; { clear locals that are not files }
   flstgen:  boolean; { list generation intermediates }
   funrol:   boolean; { unroll constant for loops }
   fregcon:  boolean; { reuse register contents }
   flstreg:  boolean; { list register allocation rules }
   fdiscm:   boolean; { disassembly countermeasures }
   fnilptr:  boolean; { perform nil pointer checks }
   ffputrp:  boolean; { trap FPU exceptions in code }
   ftagchk:  boolean; { check tagged record field access }
   flstara:  boolean; { list associative arrangements }
   flsttmp:  boolean; { list temp tracking }
   rolnum:   integer; { number of unroll cycles to perform }
   forlen:   integer; { threshold number for unroll loops in intermediate count }
   wthvar:   typptr;  { currently active 'with' variable }
   bndlst:   bndptr;  { list of bound descriptors }
   bnddes:   typptr;  { general type for bounds descriptors (record type) }
   fpusct:   integer; { fpu stacking count }
   gbltgp:   typptr;  { global tagged pointer }
   genind:   integer; { generation list indentation }
   curage:   integer; { current age of context entries }
   rndseq:   integer; { random number seed }
   threadid: typptr;  { thread id variable }
   lockid:   typptr;  { lock id variable }
   regtrk:   regcxt;  { register context block }

   { Internal constants. These become block constants. }

   rndnear: typptr; { round to nearest control word constant }
   rndzero: typptr; { round to zero control word constant }

   r: regt; { index for registers }


{ forwards }

procedure regblk(ip: intptr; var tr: regset); forward; { assign registers }
procedure gennod(ip: intptr); forward; { generate node }
procedure genlst(ip: intptr); forward; { generate list }
procedure gensar(ip: intptr; dr:regt; tr: byte; trx: byte; quad: boolean;
                 order: boolean; ins1: byte; insv1: boolean; ins2: byte;
                 dins1: byte; dinsv1: boolean; dins2: byte; scale: integer;
                 imms: integer; imm: ssint);
                 forward;
procedure regexp(rr, rrx: regt; ip: intptr; var tr: regset); forward;
procedure dmpcxt; forward; { dump register context block }
procedure genrotcal(rp: typptr); forward; { generate routine call }

{*******************************************************************************

Check options

Checks if a sequence of options is present in the input, and if
so, parses and processes them. An option is a '#', followed by
the option identifier. The identifier must be one of the valid
options. Further processing may occur, on input after the
option, depending on the option specified (see the handlers).
Consult the operator's manual for full option details.

*******************************************************************************}

procedure paropt;

var l:   labl;    { label holder }
    err: boolean; { error holder }
    oh:  boolean; { option handled flag }

{ check and set option }

procedure setopt(view yess, yes, nos, no: string; { assertion and negation }
                 var  flg: boolean); { flag to set }

begin

   { perform assertion }
   if compp(l, yess) or compp(l, yes) then begin flg := true; oh := true end
   { perform negation }
   else if compp(l, nos) or compp(l, no) then begin flg := false; oh := true end

end;

begin

   skpspc(cmdhan); { skip spaces }
   while chkchr(cmdhan) = optchr do begin { parse option }

      getchr(cmdhan); { skip option character }
      parlab(cmdhan, l, err); { get option }
      if err then error(eoptpar); { error }
      oh := false; { set option not handled }
      { list intermediate code }
      setopt('cl', 'codelist', 'ncl', 'nocodelist', fcodel);
      { list stack levels with intermediate }
      setopt('sl', 'stacklevellist', 'nsl', 'nostacklevellist', fstklvl);
      { verbosity }
      setopt('v', 'verbose', 'nv', 'noverbose', fverb);
      { list intermediate graph }
      setopt('ilf', 'intermediatelistflow', 'nilf',
             'nointermediatelistflow', fintlf);
      { list types }
      setopt('tl', 'typelist', 'ntl', 'notypelist', ftypl);
      { list symbols }
      setopt('syl', 'symbolslist', 'nsyl', 'nosymbolslist', fsyml);
      { list input source line tracking }
      setopt('srcl', 'sourcelinelist',  'nsrcl', 'nosourcelinelist', fprtlin);
      { array bounds checking }
      setopt('ac', 'arraycheck', 'nac', 'noarraycheck', farrchk);
      { use custom trap instructions }
      setopt('t', 'trap', 'nt', 'notrap', fcustrp);
      { pack global/local variables }
      setopt('pv', 'packvariables', 'npv', 'nopackvariables', fpakvar);
      { align unpacked record variables }
      setopt('arv', 'alignrecordvariables', 'narv', 'noalignrecordvariables',
             frecaln);
      { align local variables }
      setopt('alv', 'alignlocalvariables', 'nalv', 'noalignlocalvariables',
             flocaln);
      { align global variables }
      setopt('agv', 'alignglobalvariables', 'nagv', 'noalignglobalvariables',
             flocaln);
      { set machine type 80386 }
      setopt('i80386', '', '', '', fm386);
      { set machine type 80486 }
      setopt('i80486', '', '', '', fm486);
      { set machine type 80586 }
      setopt('i80586', '', '', '', fm586);
      { use floating point hardware }
      setopt('sf', 'softwarefloat', 'hf', 'hardwarefloat', flibflt);
      { go for high speed over code size }
      setopt('sp', 'speed', 'sz', 'size', fspeed);
      { perform range checking }
      setopt('rc', 'rangecheck', 'nrc', 'norangecheck', frngchk);
      { perform arithmetic overflow checking }
      setopt('oc', 'overflowcheck', 'noc', 'noverflowcheck', fovfchk);
      { check zero divide programmaticaly }
      setopt('zd', 'zerodivide', 'nzd', 'nozerodivide', fzdvchk);
      { check invalid operands }
      setopt('ivo', 'invalidoperands', 'nivo', 'noinvalidoperands', fivochk);
      { missing case check }
      setopt('cc', 'casecheck', 'ncc', 'nocasecheck', fcaschk);
      { clear locals }
      setopt('clcl', 'clearlocals', 'nclcl', 'noclearlocals', fclrlcl);
      { clear globals }
      setopt('cgbl', 'clearglobals', 'ncgbl', 'noclearglobals', fclrlcl);
      { use "bounds" instruction }
      setopt('bi', 'boundins', 'nbi', 'noboundins', fbndins);
      { list intermediates in generation }
      setopt('gl', 'generationlist', 'ngl', 'nogenerationlist', flstgen);
      { list output codes }
      setopt('ol', 'outputlist', 'nol', 'nooutputlist', foutlst);
      { list associative arrangement tracking }
      setopt('arasl', 'arrasslist', 'narasl', 'noarrasslist', flstara);
      { list temp tracking }
      setopt('tmpl', 'templist', 'ntmpl', 'notemplist', flsttmp);
      { simplify load/store indirects }
      setopt('sls', 'simplifyloadstore', 'nsls',
             'nosimplifyloadstore', fsmplsi);
      { unroll constant for loops }
      setopt('url', 'unroll', 'nurl', 'nounroll', funrol);
      { fold constant operators }
      setopt('fco', 'foldconstantoperators',
             'nfco', 'nofoldconstantoperators', ffldcst);
      { check folded constant operations }
      setopt('cfc', 'checkfoldedconstants',
             'ncfc', 'nocheckfoldedconstants', fchkcst);
      { eliminate dead code }
      setopt('dce', 'deadcodeeliminate',
             'ndce', 'nodeadcodeeliminate', fdeadce);
      { change boolean operations to jumps }
      setopt('b2j', 'booleantojump',
             'nb2j', 'nobooleantojump', fbol2jmp);
      { reuse register contents }
      setopt('rur', 'reuseregisters',
             'nrur', 'noreuseregisters', fregcon);
      { list register allocation rules }
      setopt('rl', 'registerlist',
             'nrl', 'noregisterlist', flstreg);
      { translate single characters }
      setopt('scxt', 'singlecharactertransliterate',
             'nscxt', 'nosinglecharactertransliterate', fxltchr);
      { check for nil pointer dereference }
      setopt('npc', 'nilpointercheck',
             'nnpc', 'nonilpointercheck', fnilptr);
      { select 8859-1 or 16 bit unicode mode }
      setopt('uc', 'unicode',
             'iso8', 'ISO_8859_1', funicode);
      { trap FPU errors }
      setopt('fpuc', 'fpucheck',
             'nfpuc', 'nofpucheck', ffputrp);
      { check tagged record field access }
      setopt('tagc', 'tagcheck',
             'ntagc', 'notagcheck', ftagchk);
      { include assertion checks }
      setopt('incast', 'includeassertchecks',
             'nincast', 'noincludeassertchecks', fincast);
      if frevengcm then begin { enable reverse engineering counter-measures }

         { disassembly countermeasures }
         setopt('discm', 'disassemblycountermeasures',
                'ndiscm', 'nodisassemblycountermeasures', fdiscm)

      end;
      { case occupancy }
      if compp(l, 'co') or compp(l, 'caseoccupancy') then begin

         { set case occupancy command }
         skpspc(cmdhan); { skip spaces }
         if chkchr(cmdhan) <> '=' then error(eequexp); { '=' expected }
         parnum(cmdhan, minocc, 10, err); { get the occupancy }
         if err then error(eoptpar); { error }
         { check valid range, 0-100 percent }
         if (minocc < 0) or (minocc > 100) then error(eoptpar)

      { unroll order }
      end else if compp(l, 'uro') or compp(l, 'unrollorder') then begin

         { set case occupancy command }
         skpspc(cmdhan); { skip spaces }
         if chkchr(cmdhan) <> '=' then error(eequexp); { '=' expected }
         parnum(cmdhan, rolnum, 10, err); { get the unroll order }
         if err then error(eoptpar); { error }
         { check valid range }
         if rolnum < 0 then error(eoptpar)

      end else if compp(l, 'chk0') then begin

         { Shorthand: turn all code checks off. This is the "completely unsafe"
           mode, but may not be as much of a issue on memory protected
           processors.}
         farrchk := false; { array checks off }
         ftagchk := false; { tagged record field access checks off }
         frngchk := false; { set range checks off }
         fovfchk := false; { set overflow checks off }
         fzdvchk := false; { set zero divide checks off }
         fivochk := false; { set invalid operands checks off }
         fcaschk := false; { set missing case check off }
         fnilptr := false; { set nil pointer checks off }
         ffputrp := false  { set FPU trpa checks off }

      end else if compp(l, 'chk1') then begin

         { Shorthand: turn all checks off that won't cause control loss, such as
           bad array accesses or wild pointers. This mode makes the program safe
           against crashes, but not against functional errors. }
         farrchk := true;  { array checks on }
         ftagchk := true;  { tagged record field access checks on }
         frngchk := false; { set range checks off }
         fovfchk := false; { set overflow checks off }
         fzdvchk := false; { set zero divide checks off }
         fivochk := false; { set invalid operands checks off }
         fcaschk := false; { set missing case check off }
         fnilptr := true;  { set nil pointer checks on }
         ffputrp := false  { set FPU trpa checks off }

      end else if compp(l, 'chk2') then begin

         { Shorthand: turn all checks off that won't cause control loss, such
           as bad array accesses. This mode makes the program safe against
           crashes, but not against functional errors. This is the same as
           "chk1", but allows for the fact that many operating systems reserve
           page zero to trap nil pointers. }
         farrchk := true; { array checks on }
         ftagchk := true;  { tagged record field access checks on }
         frngchk := false; { set range checks off }
         fovfchk := false; { set overflow checks off }
         fzdvchk := false; { set zero divide checks off }
         fivochk := false; { set invalid operands checks off }
         fcaschk := false; { set missing case check off }
         fnilptr := false; { set nil pointer checks on }
         ffputrp := false  { set FPU trpa checks off }

      end else if compp(l, 'chk3') then begin

         { Shorthand: turn all checks on. This is the "safe" mode, }
         farrchk := true; { array checks on }
         ftagchk := true; { tagged record field access checks on }
         frngchk := true; { set range checks on }
         fovfchk := true; { set overflow checks on }
         fzdvchk := true; { set zero divide checks on }
         fivochk := true; { set invalid operands checks on }
         fcaschk := true; { set missing case check on }
         fnilptr := true; { set nil pointer checks on }
         ffputrp := true  { set FPU trpa checks on }

      end else if not oh then error(eoptnf); { option not found }
      skpspc(cmdhan) { skip spaces }

   end

end;

{*******************************************************************************

Set reference flag for entry

Accepts a variable, fixed, function or procedure type, and sets the reference
flag for that.

*******************************************************************************}

procedure setref(tp: typptr);

begin

   if tp^.t = tvar then tp^.varr := true
   else if tp^.t = tfix then tp^.fixr := true
   else if tp^.t = tproc then tp^.prcr := true
   else if tp^.t = tfunc then tp^.fnct := true

end;

{*******************************************************************************

Find if power of 2

Returns the simple power of 2 in the integer, ie.,

0 -> no simple power of 2 or i = 1
1 -> i = 2
2 -> i = 4
3 -> i = 8

Which also happens to be the shift count needed for constant multiplies and
divides.

*******************************************************************************}

function pow2(i: ssint) { integer to check }
             : integer; { power }

var bitc:  integer; { bit count }
    shftc: integer; { shift count }

begin

   bitc := 0; { clear bit count }
   shftc := 0; { clear shift count }
   if not i.s then { not negative }
      while i.v <> 0 do begin { find powers }

      if odd(i.v) then bitc := bitc+1; { count bits }
      shftc := shftc+1; { count shifts }
      i.v := i.v div 2 { perform the shift }

   end;
   if bitc > 1 then shftc := 0; { was not a simple power, set no power }
   if shftc <> 0 then shftc := shftc-1; { ajust out 1st power }
   pow2 := shftc { return result }

end;

{*******************************************************************************

Round to dwords

Rounds the given size to an even number of words. Anything pushed onto the
stack is rounded up to words to keep the stack aligned to 32 bits. This is
necessary for good performance on the I80386.

*******************************************************************************}

function wrdsizr(s: integer) { size to round }
                 :integer;   { return size }

var r: integer; { result holder }

begin

   r := s div stksiz*stksiz; { find even words }
   if s mod stksiz <> 0 then r := r+stksiz; { round up to words }
   wrdsizr := r { return result }

end;

{*******************************************************************************

Determine alignment

Determines the natural alignment for a type. Each type is aligned on its
"natural base", which means every 4th address for dword types, every 2nd address
for word types, and any address for all others. Anything larger then dword is
simply aligned to dword in a 32 bit machine. Structured types are tricky in that
the overall size of the type is irrelivant. For these types the alignment is the
same as the alignment of the first element. To determine that, we have to
recursively open sucessive structure definitions.

*******************************************************************************}

function align(tp: typptr): integer;

var aln: integer; { alignment figure }
    max: integer; { maximum alignment figure }
    p:   typptr;  { pointer to type entries }

begin

   aln := 1; { set no alignment required }
   if tp <> nil then
      with tp^ do case t of { type }

      tudf:       ; { none }
      tnil:       aln := size; { 32 bit pointer }
      tlab:       ; { none }
      ticst:      aln := size; { 32 bit constant }
      tscst:      ; { byte }
      tccst:      aln := size; { single character }
      trcst:      aln := intsiz; { 64 bit real, only needs 32 bit align }
      tstcst:     ; { sets have no alignment requirement }
      tstet:      ; { sets have no alignment requirement }
      tarrcst:    aln := align(arcn); { use first list entry }
      tarrcel:    aln := align(arec); { use constant }
      treccst:    aln := align(recn); { use first list entry }
      treccel:    aln := align(reec); { use constant }
      tenum:      aln := size; { same as size }
      tenme:      aln := size; { same as size }
      tsub:       aln := size; { same as size }
      tptr:       aln := ptrsiz; { align for pointer }
      { arrays are the number of bytes per element, times the number of
        elements }
      tarray:     aln := align(arrt); { use alignment of base type }
      tgarry:     aln := align(gart); { use alignment of base type }
      tfile:      size := bytsiz; { file number }
      tset:       ; { sets have no alignment requirement }
      trecord:    begin

         { To find the aligment of a record, we must examine each of the field
           elements and find the maximum alignment requirement of all of them. }

         aln := align(recf); { use first field list entry }
         p := recf; { index top of case list }
         max := 1; { maximum alignment }
         while p <> nil do begin { traverse }

            if (p^.t <> tfield) and (p^.t <> tftag) then
                error(esysflt117); { should be a case entry }
            aln := align(p); { find alignment of this field }
            { check if this is a new maximum, and use it if so }
            if aln > max then max := aln;
            if p^.t = tfield then p := p^.fldn { link next field }
            else p := nil { no next field }

         end;
         aln := max { set maximum alignment requirement }

      end;
      tfield:     aln := align(fldt); { use base type }
      tftag:      begin

         { To find the alignment of a variant part, we examine each of the
           variants and use the largest alignment requirement we find, since
           it is not a problem if an item has an alignment larger than it
           needs. }
         p := ftgc; { index top of case list }
         max := 1; { maximum alignment }
         while p <> nil do begin { traverse }

            if p^.t <> tfcas then error(esysflt115); { should be a case entry }
            aln := align(p); { find alignment of this case }
            { check if this is a new maximum, and use it if so }
            if aln > max then max := aln;
            p := p^.fcsn { link next case }

         end;
         aln := max { set maximum alignment requirement }

      end;
      tfcas:      aln := align(fcsf); { set first field list entry }
      tvar:       aln := align(vart); { use underlying type }
      tfix:       aln := align(fixt); { use underlying type }
      tproc:      ; { none }
      tfunc:      ; { none }
      tpar:       aln := align(part); { use underlying type }
      tvpar:      aln := align(vprt); { use underlying type }
      twpar:      aln := align(wprt); { use underlying type }
      tpproc:     aln := ptrsiz; { 32 bit address of procedure }
      tpfunc:     aln := ptrsiz; { 32 bit address of function }
      tinteger:   aln := size; { same as size }
      tlinteger:  aln := size; { same as size }
      tcardinal:  aln := size; { same as size }
      tlcardinal: aln := size; { same as size }
      tchar:      aln := size; { character }
      tboolean:   aln := size; { boolean }
      treal:      aln := intsiz; { 64 bit real, only needs 32 bit align }
      tsreal:     aln := size; { 32 bit real }
      ttext:      aln := bytsiz; { file number }
      teset:      ; { sets have no alignment requirement }
      tglbl:      ; { none }
      tsemaphore: aln := intsiz; { 32 bit }
      { because objects start with a template pointer, they allways align as 32
        bit }
      tclass:     aln := intsiz; { 32 bit }
      tatom:      aln := intsiz; { 32 bit }
      tthread:    aln := intsiz; { 32 bit }
      treference: aln := ptrsiz; { align for pointer }
      texception: aln := ptrsiz; { align for pointer }
      tnull:      ; { none }
      tfuncr:     aln := size; { same as simple type }
      tlink:      ; { none }
      tcastbl:    ; { none }
      thshtbl:    ; { none }
      tcassel:    ; { none }
      trot:       ; { none }
      tpgm:       ; { none }
      tvrs:       ; { none }

   end;

   align := aln { return alignment value }

end;

{*******************************************************************************

Align address by type

Given an address and a type to align to, finds the native alignment value of the
type, then aligns the address with that.

*******************************************************************************}

procedure alnadr(var addr: integer; { address to align }
                     tp:   typptr); { type to align with }

var aln: integer; { alignment value }

begin

   aln := align(tp); { find alignment }
   if addr mod aln <> 0 then addr := addr+(aln-addr mod aln);

end;

{*******************************************************************************

Set size of type entry

Determines the size that an object of the given type will occupy, in bytes,
and sets that variable in the type. If the type already has a size it is
skipped. If it does not, we also recursively verify that all relied on
submembers also have a size. That way, the size tree for the entry is
self-resolved for any undefineds.
Also sets the signed status of the type.
Also checks sets for > 256 elements, and sets with negative elements.

*******************************************************************************}

procedure sizset(tp: typptr);

var i, i2: ssint;

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
      { find alignment requirement for records }
      if frecaln then alnadr(size, tp);
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

{ find value size in bytes }

function valsiz(s, e: ssint) { value range }
                : integer;   { byte size of values }

var b: integer; { number of bytes }

begin

   if ssgtn(s, e) then error(einvfmt); { bad range }
   if (ssgeq(s, true, 128) and ssleq(e, false, 127)) or
      (ssgeq(s, false, 0) and ssleq(e, false, 255)) then
      b := bytsiz { byte }
   else if (ssgeq(s, true, 32768) and ssleq(e, false, 32767)) or
           (ssgeq(s, false, 0) and ssleq(e, false, 65535)) then
      b := wrdsiz { word }
   else b := dwdsiz; { dword }
   valsiz := b { return byte size }

end;

{ find size of emumerated in bytes }

function enmsiz(tp: typptr) { list to check }
                : integer;  { byte size of type }

var m: integer; { maximum list value }
    b: integer; { size in bytes }

begin

   m := -1; { set no maximum }
   while tp <> nil do begin { traverse list }

      if tp^.t <> tenme then error(einvfmt); { bad format }
      if tp^.env > m then m := tp^.env; { set new maximum }
      tp := tp^.enx { link next entry }

   end;
   if m = -1 then error(einvfmt); { must have some size }
   if b <= 255 then b := bytsiz { byte }
   else if b <= 32767 then b := wrdsiz { word }
   else b := dwdsiz; { double word }

   enmsiz := b { return byte size }

end;

begin

   if tp^.size = 0 then { if the entry has no size, size it }
      with tp^ do case t of { type }

      tudf:       ; { none }
      tnil:       size := intsiz; { 32 bit pointer }
      tlab:       ; { none }
      ticst:      size := intsiz; { 32 bit constant }
      tscst:      if funicode then size := max(sval^)*wrdsiz { unicode }
                  else size := max(sval^)*bytsiz; { ISO 8859-1 }
      tccst:      if funicode then size := wrdsiz { 16 bit unicode character }
                  else size := bytsiz; { 8 bit ISO 8859-1 character }
      trcst:      size := relsiz; { 64 bit real }
      tstcst:     begin

         sizset(stct); { find base type size }
         size := setsiz; { 256 bits of 32 bytes in a set }
         { These checks should be valid. However, the parser is sending us
           anonymous sets of "set of integer" type. Until this is changed,
           We cannot perform these checks. }
         if false then begin
         
            { flag error on set greater than 256 elements }
            if stct^.size > 1 then error(esettl);
            { flag error on negative base }
            if lbounds(stct) then error(esetneg)
            
         end

      end;
      tstet:      ; { no meaning to this }
      { structured constants are not sized, because we use the base type of any
        fixed object to process them }
      tarrcst:    ;
      tarrcel:    ;
      treccst:    ;
      treccel:    ;
      tenum:      size := enmsiz(enc); { find size by enumerated list }
      tenme:      begin sizset(enh); size := enh^.size end; { enumerated const }
      tsub:       size := valsiz(subl, subu); { subrange of values size }
      tptr:       if ptrt^.t = tgarry then size := tgpsiz { general array }
                  else size := ptrsiz; { 32 bit pointer }
      { arrays are the number of bytes per element, times the number of
        elements }
      tarray:     begin
                     sizset(arrt);
                     i.v := sssub(ubounds(arri), ubound(arri),
                                  lbounds(arri), lbound(arri));
                     i.s := sssubs(ubounds(arri), ubound(arri),
                                   lbounds(arri), lbound(arri));
                     i2.v := ssadd(i, false, 1);
                     i2.s := ssadds(i, false, 1);
                     if i2.s then error(esysflt230);
                     size := arrt^.size*i2.v
                  end;
      tgarry:     ; { general arrays have no fixed size }
      tfile:      size := bytsiz; { file number }
      tset:       begin

         sizset(sett); { find base type size }
         size := setsiz; { 256 bits or 32 bytes in a set }
         { These checks should be valid. However, the parser is sending us
           anonymous sets of "set of integer" type. Until this is changed,
           We cannot perform these checks. }
         if false then begin

            { flag error on set greater than 256 elements }
            if sett^.size > 1 then error(esettl);
            { flag error on negative base }
            if lbounds(sett) then error(esetneg)

         end

      end;
      trecord:    begin

         { find total length of fields in record }
         tp := recf; { index top of list }
         size := fields(tp) { find size of list }

      end;
      tfield:     begin sizset(fldt); size := fldt^.size end;
      tftag:      begin sizset(ftgt); size := ftgt^.size end;
      tfcas:      begin

         { find total list of fields in case variant }
         tp := fcsf; { index top of list }
         size := fields(tp) { find size of list }

      end;
      tvar:       begin sizset(vart); size := vart^.size end;
      tfix:       begin sizset(fixt); size := fixt^.size end;
      tproc:      ; { none }
      tfunc:      ; { none }
      tpar:       begin

         sizset(part);
         { if parameter is greater than register size, and not a tagged
           pointer, then it becomes a pointer to a temp. }
         if (part^.size > regsiz) and tgpt(part) then size := ptrsiz
         else size := part^.size

      end;
      tvpar:      if vprt^.t = tgarry then size := tgpsiz { pointer, length }
                  else size := ptrsiz; { 32 bit pointer to variable }
      twpar:      begin

         sizset(wprt); { set size of base }
         if wprt^.t in [trecord, tarray] then { structured }
            size := ptrsiz { 32 bit pointer to variable }
         else if wprt^.t = tgarry then size := tgpsiz { pointer, length }
         else begin

            size := wprt^.size; { else is size of base }
            if (size > regsiz) and not tgpt(wprt) then
               size := regsiz { if > register, set as reg }

         end

      end;
      tpproc:     size := pfpsiz; { 32 bit address of procedure+frame pointer }
      tpfunc:     size := pfpsiz; { 32 bit address of function+frame pointer }
      tinteger:   size := intsiz; { 32 bit signed integer }
      tlinteger:  size := lntsiz; { 64 bit signed integer }
      tcardinal:  size := crdsiz; { 32 bit unsigned integer }
      tlcardinal: size := lcrsiz; { 64 bit unsigned integer }
      tchar:      if funicode then size := wrdsiz { 16 bit unicode character }
                  else size := bytsiz; { ISO 8859-1 character }
      tboolean:   size := bytsiz; { boolean }
      treal:      size := relsiz; { 64 bit real }
      tsreal:     size := srlsiz; { 32 bit real }
      ttext:      size := bytsiz; { file number }
      teset:      size := setsiz; { 256 bits or 32 bytes in a set }
      tglbl:      ; { none }
      tsemaphore: size := intsiz; { 32 bit }
      tclass:     ; { ?? don't know yet }
      tatom:      ; { ?? don't know yet }
      tthread:    ; { ?? don't know yet }
      treference: size := ptrsiz; { pointer }
      texception: size := bytsiz; { only need to de-alias these, the contents is
                            unused }
      tnull:      ; { none }
      tfuncr:     begin sizset(fnrt); size := wrdsizr(fnrt^.size) end;
      tlink:      ; { none }
      tcastbl:    ; { none }
      thshtbl:    ; { none }
      tcassel:    ; { none }
      trot:       ; { none }
      tpgm:       ; { none }
      tvrs:       ; { none }

   end

end;

{*******************************************************************************

Set size block

Sets the size of all the type entries in the current block. This should be done
when starting a new block (which might reference types in this block), or the
start of a program code section. Each type entry is set in turn, but if any
entry has undefined subentries, those are resolved first. In this way, the
typing tree is self-resolving.

*******************************************************************************}

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

   sizlst(blkstk^.res); { resolve standard list }
   sizlst(blkstk^.resa) { resolve alternate list }

end;

{*******************************************************************************

Iterate in parameter type list

Moves a pointer forward in a parameter type list. Used to traverse such a list.

*******************************************************************************}

procedure itrpar(var tp: typptr);

begin

   case tp^.t of { parameter, find next }

      tpar:   tp := tp^.parn; { parameter }
      tvpar:  tp := tp^.vprn; { variable parameter }
      twpar:  tp := tp^.wprn; { view parameter }
      tpproc: tp := tp^.pprn; { procedure parameter }
      tpfunc: tp := tp^.pfnn  { function parameter }

   end

end;

{*******************************************************************************

Perform procedure parameter metering in types

Establishes the number of parameters, the number of each type of parameter,
and the total register allocation of the parameters, for a standard procedure
or function call.

This information is used both to form the parameters for each call, as well as
to determine the layout of the parameters to the present block.

This is a stripped down version of regfit that works on the type linked
parameter list, instead of the intermediate code representation. The calls
could probally be unified if the type list were used in both cases.

*******************************************************************************}

procedure regfit(    tp:      typptr;   { parameter list to process }
                 var allptot: integer;  { total number of parameters }
                 var relptot: integer;  { number of real parameters }
                 var tgpptot: integer;  { number of tagged pointers }
                 var stdptot: integer;  { number of standard parameters }
                 var tgprtot: integer;  { number of registered tagged pointers }
                 var stdrtot: integer;  { number of registered standard parameters }
                 var allreg:  regset;   { total register allocation mask }
                 var tgpreg:  regset;   { tagged pointer allocated registers }
                 var stdreg:  regset);  { standard allocated registers }

var p: typptr; { pointer to parameter list }
    r: regt;   { allocation register }

procedure parcnt(tp: typptr); { parameter list }

begin

   allptot := 0; { clear result }
   relptot := 0;
   tgpptot := 0;
   stdptot := 0;
   while tp <> nil do begin { traverse }

      if realt(tp) and (tp^.t <> tvpar) then
         relptot := relptot+1 { found a real }
      else begin

         if tgpt(tp) or pfpt(tp) then tgpptot := tgpptot+1 { tagged pointer }
         else stdptot := stdptot+1 { standard }

      end;
      allptot := allptot+1; { count all parameters }
      itrpar(tp) { next parameter }

   end

end;

{ set next register in use }

procedure usereg;

begin

   allreg := allreg+[r]; { add register to total allocation }
   if r <> rgedi then r := succ(r) { advance register }
   else r := rgnull

end;

begin { regfit }

   allreg := []; { clear all register allocation }
   tgpreg := []; { tagged pointer allocated registers }
   stdreg := []; { standard allocated registers }
   parcnt(tp); { count parameter totals }

   { place tagged pointers and procedure/function parameters }

   p := tp; { index top of list }
   r := rgeax; { set 1st register to place }
   tgprtot := 0; { clear registered total }
   while (p <> nil) and (r <> rgnull) do begin

      if tgpt(p) or pfpt(p) then begin { found }

         tgpreg := tgpreg+[r]; { add register to allocation }
         usereg; { add register }
         tgpreg := tgpreg+[r]; { add register to allocation }
         usereg; { add register }
         tgprtot := tgprtot+1 { count }

      end;
      itrpar(p) { link next }

   end;

   { place standard parameters }

   p := tp; { index top of list }
   stdrtot := 0; { clear registered total }
   while (p <> nil) and (r <> rgnull) do begin

      if not (realt(p) and (p^.t <> tvpar)) and not tgpt(p) and
         not pfpt(p) then begin { found }

         stdreg := stdreg+[r]; { add register to allocation }
         usereg; { add register }
         stdrtot := stdrtot+1 { count }

      end;
      itrpar(p) { link next }

   end

end;

{*******************************************************************************

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

*******************************************************************************}

procedure allloc; { block to process }

var tp:     typptr;  { index for types }
    la:     integer; { local address }
    lsize:  integer; { locals size }
    posize: integer; { parameter overflow size }
    rsiz:   integer; { result size }
    pp:     typptr;  { parameter list pointer }
    { Registers that are in use, either in block or for parameters (only
      applies to procedures and functions) }
    usereg: regset;
    rgsiz:  integer; { size of stack space in registers }
    r:      regt;    { register index }

    { Parameter information block. }

    allptot: integer; { number of total parameters }
    relptot: integer; { number of real parameters }
    tgpptot: integer; { number of tagged pointers }
    stdptot: integer; { number of standard parameters }
    tgprtot: integer; { number of registered tagged pointers }
    stdrtot: integer; { number of registered standard parameters }
    allreg:  regset;  { total register allocation mask }
    tgpreg:  regset;  { tagged pointer allocated registers }
    stdreg:  regset;  { standard allocated registers }

{ allocate parameters }

procedure allocate(tp:  typptr;   { parameter list }
                   rsa: integer;  { register save area }
                   opa: integer;  { parameter overflow area }
                   fsa: integer); { floating point register save area }

var p:  typptr;  { parameter list pointer }
    pc: integer; { parameter count }
    r:  regt;    { allocation register }

{ iterate parameter list pointer }

procedure itrpar(var tp: typptr);

begin

   case tp^.t of { parameter, find next }

      tpar:   tp := tp^.parn; { parameter }
      tvpar:  tp := tp^.vprn; { variable parameter }
      twpar:  tp := tp^.wprn; { view parameter }
      tpproc: tp := tp^.pprn; { procedure parameter }
      tpfunc: tp := tp^.pfnn  { function parameter }

   end

end;

{ next register }

procedure nxtreg;

begin

   if r <> rgedi then r := succ(r)

end;

begin

   r := rgeax; { set 1st allocation register }

   { perform tagged pointer register address assignment }

   p := tp; { index top of list }
   pc := 1; { clear parameter count }
   while p <> nil do begin { traverse }

      if tgpt(p) or pfpt(p) then begin { found }

         if pc <= tgprtot then begin

            p^.addr := rsa; { allocate as register }
            rsa := rsa+stksiz*2; { move up }
            nxtreg; { next register }
            nxtreg

         end;
         pc := pc+1 { count this parameter }

      end;
      itrpar(p) { link next }

   end;

   { perform standard parameters register address assignment }

   p := tp; { index top of list }
   pc := 1; { clear registered total }
   while p <> nil do begin

      if not (realt(p) and (p^.t <> tvpar)) and not tgpt(p) and
         not pfpt(p) then begin { found }

         if pc <= stdrtot then begin

            p^.addr := rsa; { allocate as register }
            rsa := rsa+stksiz; { move up }
            nxtreg { next register }

         end;
         pc := pc+1 { count this parameter }

      end;
      itrpar(p) { link next }

   end;

   { perform real register address assignment }

   p := tp; { index top of list }
   pc := 1; { clear parameter count }
   while p <> nil do begin { traverse }

      if realt(p) and (p^.t <> tvpar) then begin { found }

         if pc <= maxfst then begin

            p^.addr := fsa; { allocate as register }
            fsa := fsa-relsiz { move down }

         end;
         pc := pc+1 { count this parameter }

      end;
      itrpar(p) { link next }

   end;

   { perform standard parameters overflow address assignment }

   p := tp; { index top of list }
   pc := 1; { clear registered total }
   while p <> nil do begin

      if not (realt(p) and (p^.t <> tvpar)) and not tgpt(p) and
         not pfpt(p) then begin

         { standard parameter }
         if pc > stdrtot then begin { found }

            p^.addr := opa; { allocate as overflow }
            opa := opa+stksiz { move up }

         end;
         pc := pc+1 { count this parameter }

      end;
      itrpar(p) { link next }

   end;

   { perform tagged pointer overflow address assignment }

   p := tp; { index top of list }
   pc := 1; { clear parameter count }
   while p <> nil do begin { traverse }

      if tgpt(p) or pfpt(p) then begin { found }

         if pc > tgprtot then begin

            p^.addr := opa; { allocate as overflow }
            opa := opa+stksiz*2 { move up }

         end;
         pc := pc+1 { count this parameter }

      end;
      itrpar(p) { link next }

   end;

   { perform real overflow address assignment }

   p := tp; { index top of list }
   pc := 1; { clear parameter count }
   while p <> nil do begin { traverse }

      if realt(p) and (p^.t <> tvpar) then begin { found }

         if pc > maxfst then begin

            { Note that a real in the overflow area is either a 32 bit real,
              or a pointer to a 64 bit temp. }
            p^.addr := opa; { allocate as overflow }
            opa := opa+stksiz { move up }

         end;
         pc := pc+1; { count this parameter }

      end;
      itrpar(p) { link next }

   end

end;

{ find variable sizes in list }

function fndsiz(tp: typptr): integer;

var size: integer; { size total }

begin

   size := 0; { clear size }
   while tp <> nil do begin { traverse list }

      { check entry is local variable }
      if tp^.t = tvar then begin

         { perform any required type alignment first }
         if flocaln then alnadr(size, tp);
         size := size+tp^.size; { add in this entry }

      end;
      tp := tp^.next { next entry }

   end;
   fndsiz := size { return result }

end;

{ allocate variables in list }

procedure setloc(tp: typptr);

begin

   while tp <> nil do begin { traverse list }

      if tp^.t = tvar then begin { it's a variable, allocate }

         { perform any required type alignment first }
         if flocaln then alnadr(la, tp);
         tp^.addr := la; { assign the address }
         la := la+tp^.size { step to next }

      end;
      tp := tp^.next { next entry }

   end

end;

begin

   { set registers in use }

   usereg := blkstk^.entreg; { set equal to entry block usage }

   { Meter our block parameters. }

   pp := nil; { set no parameter list }
   allreg := []; { clear parameter registers }
   if blkstk^.mark^.t = tproc then pp := blkstk^.mark^.prcp
   else if blkstk^.mark^.t = tfunc then pp := blkstk^.mark^.fncp;
   allreg := []; { clear parameter registers }
   if pp <> nil then { there is a parameter list }
      regfit(pp, allptot, relptot, tgpptot, stdptot, tgprtot, stdrtot, allreg,
              tgpreg, stdreg);

   { Now set parameter registers as "in use". These are "in use" because
     their contents must be preserved by saving on stack }

   usereg := usereg+allreg;

   { Find register space in use }

   rgsiz := 0; { set no register space in use }
   for r := rgeax to rgedi do if r in usereg then rgsiz := rgsiz+regsiz;

   { find overflow space, space in overflow parameters on stack }
   if relptot > maxfst then
      posize := (relptot-maxfst)*regsiz; { real parameters }
   posize := posize+(tgpptot-tgprtot)*tgpsiz; { tgp parameters }
   posize := posize+(stdptot-stdrtot)*regsiz; { standard parameters }

   rsiz := 0; { set default result size (none) }
   { perform sizing pass }
   lsize := fndsiz(blkstk^.typ); { find standard size }
   lsize := lsize+fndsiz(blkstk^.typa); { add alternate sizes }
   lsize := wrdsizr(lsize); { find rounded up size }
   la := -((blkstk^.lvl-1)*4)-lsize; { set local address to bottom of frame }
   setloc(blkstk^.typ); { process standard list }
   setloc(blkstk^.typa); { process alternate list }
   tp := blkstk^.mark; { index the mark }
   if tp^.t = tproc then begin { procedure }

      tp^.prcv := wrdsizr(lsize); { set total locals size }
      { if locals exist, and either the local clear flag is selected, or the
        locals contain a file, then the registers in use must be recalculated
        to consider the use of registers for the clear }
      if (tp^.prcv <> 0) and (fclrlcl or blkstk^.fvar) then begin

         usereg := usereg+[rgeax, rgecx, rgedi];
         rgsiz := 0; { set no register space in use }
         for r := rgeax to rgedi do if r in usereg then rgsiz := rgsiz+regsiz

      end;
      { Normally, the parameter size indicates the total parameter space. In
        our case, it is the size of overflow parameters, since the register
        based parameters are accounted for differently. }
      tp^.prca := posize; { set parameter overflow size }
      { set intraprocedure goto offset }
      tp^.prcg := -((blkstk^.lvl-1)*4)-lsize-stksiz-rgsiz-relsiz*relptot;
      { allocate parameters in registers and overflow area }
      allocate(tp^.prcp, { parameter list }
               { Register save below display saves, locals, eflags, register
                 saves. }
               -((blkstk^.lvl-1)*4)-lsize-stksiz-rgsiz,
               { overflow area above EBP save and return address }
               stksiz+stksiz,
               { Floating point register save area below rsa base. }
               -((blkstk^.lvl-1)*4)-lsize-stksiz-rgsiz-relsiz)

   end else if tp^.t = tfunc then begin { function }

      rsiz := stksiz; { set default function result size }
      { check is 8 byte real }
      if realt(tp^.fncr) and not srealt(tp^.fncr) then rsiz := relsiz;
      { check is tgp }
      if tgpt(tp^.fncr^.fnrt) then rsiz := tgpsiz;
      tp^.fncv := wrdsizr(lsize); { set total locals size }
      { if locals exist, and either the local clear flag is selected, or the
        locals contain a file, then the registers in use must be recalculated
        to consider the use of registers for the clear }
      if (tp^.fncv <> 0) and (fclrlcl or blkstk^.fvar) then begin

         usereg := usereg+[rgeax, rgecx, rgedi];
         rgsiz := 0; { set no register space in use }
         for r := rgeax to rgedi do if r in usereg then rgsiz := rgsiz+regsiz

      end;
      { set intraprocedure goto offset }
      { Normally, the parameter size indicates the total parameter space. In
        our case, it is the size of overflow parameters, since the register
        based parameters are accounted for differently. }
      tp^.fnca := posize; { set parameter overflow size }
      tp^.fncg := -((blkstk^.lvl-1)*4)-lsize-stksiz-rsiz-rgsiz-relsiz*relptot;
      { allocate parameters in registers and overflow area }
      allocate(tp^.fncp, { parameter list }
               { Register save below display saves, locals, eflags, result,
                 register saves. }
               -((blkstk^.lvl-1)*4)-lsize-stksiz-rsiz-rgsiz,
               { overflow area above EBP save and return address }
               stksiz+stksiz,
               { Floating point register save area below rsa base. }
               -((blkstk^.lvl-1)*4)-lsize-stksiz-rsiz-rgsiz-relsiz);
      { allocate function return at the top of that same frame }
      tp^.fncr^.addr := -((blkstk^.lvl-1)*4)-lsize-rsiz

   end

end;

{******************************************************************************

Create local temps

Creates the temps needed in expressions. Temps are needed for sets so they can
be represented as addresses in the program.

******************************************************************************}

procedure maktmp(ip: intptr);

var tmpnum: 0..tmpmax;                   { number of temps allocated }
    ti:     0{1}..tmpmax;                   { index for temps }
    tmpstk: array [1..tmpmax] of typptr; { temp types holder stack for sets }
    tmptrk: array [1..tmpmax] of tmpptr; { temp tracking for checkin/checkout }

{ allocate new single temp }

procedure pshtmp(var tp: typptr); { new type to allocate }

begin

   if tmpnum = tmpmax then error(estmpovf); { temps overflow }
   tmpnum := tmpnum+1; { add a temp level }
   tp := tmpstk[tmpnum]; { get that type }
   if tmpstk[tmpnum] = nil then begin

      { no previous temp here, create it }
      gettypa(tp, tvar); { get the type entry }
      tp^.vart := gblset; { set type }
      tp^.vare := false; { set not external }
      tp^.local := blkstk^.lvl >= 3;
      tmpstk[tmpnum] := tp; { place type }

   end

end;

{ remove temp level }

procedure poptmp;

begin

   if tmpnum = 0 then error(estmpunf); { temps underflow }
   tmpnum := tmpnum-1 { remove temp level }

end;

{ get new or used temp }

procedure gettmp(tp:     typptr;  { type of requested temp }
                 var vt: typptr); { resulting temp entry }

var i: 1..tmpmax; { temps index }

begin

   vt := nil; { set no temp found }
   for i := 1 to tmpmax do { search }
      if tmptrk[i] <> nil then{ search }
         { check not in use, and matches base type }
         if not tmptrk[i]^.inuse and (tmptrk[i]^.typ^.vart = tp) then begin

      vt := tmptrk[i]^.typ; { found }
      tmptrk[i]^.inuse := true { flag now in use }

   end;
   if vt = nil then begin { nothing existing, create a new one }

      { search for first null entry }
      i := 1; { set 1st }
      { search forward }
      while (tmptrk[i] <> nil) and (i < tmpmax) do i := i+1;
      if tmptrk[i] <> nil then error(etmpovf); { flag overflow }
      new(tmptrk[i]); { create a new temps entry }
      gettypa(vt, tvar); { get the type entry }
      vt^.vart := tp; { set type }
      vt^.vare := false; { set not external }
      vt^.local := blkstk^.lvl >= 3;
      tmptrk[i]^.typ := vt; { place temp type }
      tmptrk[i]^.inuse := true { set in use }

   end

end;

{ release temp in use }

procedure puttmp(vt: typptr); { temp entry }

var i: 1..tmpmax; { temps index }
    f: boolean;   { found flag }

begin

   f := false; { set not found }
   for i := 1 to tmpmax do if tmptrk[i] <> nil then { search }
      if tmptrk[i]^.typ = vt then begin

      if not tmptrk[i]^.inuse then error(esysflt153); { not in use, bad }
      tmptrk[i]^.inuse := false; { set not in use }
      f := true { set was found }

   end;
   if not f then error(esysflt154) { cannot find it, bad }

end;

{ make temps for list }

procedure maktmplst(ip: intptr); forward;

{ create expression temps }

procedure maktmpexp(ip: intptr); { operator to process }

var ip1: intptr; { pointer for intermediates }

begin

   if flsttmp then begin

      write('maktmpexp: intermediate: ');
      prttic(ip^.i, 1);
      writeln

   end;

   case ip^.i of { intermediate }

      tifnccal, tifnccalo: begin

         { process parameters }
         ip1 := ip^.flow2; { index top of parameter list }
         while ip1 <> nil do begin { traverse }

            maktmpexp(ip1^.left); { evaluate parameter }
            { Check real, and allocate temp if so. }
            if realt(ip1^.base) then gettmp(ip1^.base, ip1^.base2);
            ip1 := ip1^.flow { next parameter }

         end;
         { now free up all temps allocated }
         ip1 := ip^.flow2; { index top of parameter list }
         while ip1 <> nil do begin { traverse }

            if realt(ip1^.base) then puttmp(ip1^.base2); { real, free it }
            if (ip1^.left^.i = tilodsrc) or (ip1^.left^.i = tildisrc) then
               puttmp(ip1^.left^.base2); { free structure temp }
            { determine if an operator returning a set. note that this is too big
              for a set operation to check }
            if (ip1^.left^.i = tilodset) or (ip1^.left^.i = tildiset) or
               (ip1^.left^.i = tiintset) or (ip1^.left^.i = tiuniset) or
               (ip1^.left^.i = tidifset) or (ip1^.left^.i = tisinset) or
               (ip1^.left^.i = tirngset) or (ip1^.left^.i = tilimns) then poptmp;
            ip1 := ip1^.flow { next parameter }

         end

      end;

      tifnccali: begin

         maktmpexp(ip^.left); { address of function }
         { process parameters }
         ip1 := ip^.flow2; { index top of parameter list }
         while ip1 <> nil do begin { traverse }

            maktmpexp(ip1^.left); { evaluate parameter }
            { Check real, and allocate temp if so. }
            if realt(ip^.base) then gettmp(ip1^.base, ip1^.base2);
            ip1 := ip1^.flow { next parameter }

         end;
         { now free up all temps allocated }
         ip1 := ip^.flow2; { index top of parameter list }
         while ip1 <> nil do begin { traverse }

            if realt(ip1^.base) then puttmp(ip1^.base2); { real, free it }
            if (ip1^.left^.i = tilodsrc) or (ip1^.left^.i = tildisrc) then
               puttmp(ip1^.left^.base2); { free structure temp }
            { determine if an operator returning a set. note that this is too big
              for a set operation to check }
            if (ip1^.left^.i = tilodset) or (ip1^.left^.i = tildiset) or
               (ip1^.left^.i = tiintset) or (ip1^.left^.i = tiuniset) or
               (ip1^.left^.i = tidifset) or (ip1^.left^.i = tisinset) or
               (ip1^.left^.i = tirngset) or (ip1^.left^.i = tilimns) then poptmp;
            ip1 := ip1^.flow { next parameter }

         end

      end;

      tildiset: begin

         maktmpexp(ip^.left);
         pshtmp(ip^.base2)

      end;

      tilodset, tilimns: begin

         pshtmp(ip^.base2)

      end;

      tiintset, tiuniset, tidifset: begin

         maktmpexp(ip^.left);
         maktmpexp(ip^.right);
         poptmp { remove one of the sets }

      end;

      tiequset, tineqset, tileqset, tigeqset: begin

         maktmpexp(ip^.left);
         maktmpexp(ip^.right);
         poptmp; { remove sets }
         poptmp

      end;

      tisinset: begin

         maktmpexp(ip^.left);
         maktmpexp(ip^.right);

      end;

      tiincset: begin

         maktmpexp(ip^.left);
         maktmpexp(ip^.right);
         poptmp { remove set }

      end;

      tirngset: begin

         maktmpexp(ip^.left);
         maktmpexp(ip^.right);
         maktmpexp(ip^.xtra)

      end;

      tilodsrc: begin

         { Structure loads are only used in value passing, since there are no
           operations that can be done with a structure on the stack. The set
           temporaries method cannot be used, so we allocate a custom variable
           for the operation. }
         gettmp(ip^.base, ip^.base2)

      end;

      tildisrc: begin

         maktmpexp(ip^.left);
         { Structure loads are only used in value passing, since there are no
           operations that can be done with a structure on the stack. The set
           temporaries method cannot be used, so we allocate a custom variable
           for the operation. }
         gettmp(ip^.base, ip^.base2)

      end;

      tirnd, titrc: begin

         maktmpexp(ip^.left);
         { We need an integer temp to unload the fpu to and pick back up. The
           FPU is not capable of loading or storing direct to a register. }
         gettmp(baset(gblint), ip^.base2)

      end;

      tilodadr, tilodint, tilodrel, tilodsrl, tilodchr,
      tilodbol, tilodptr, tilimint, tilimrel, tilodfadr, tilodtgp: ;

      tieolt, tieof, tiloc, tilen, tilodafbuf, tilodafbuft, tiexist,
      ticvtntg, tildiint, tildichr, tildibol, tildiptr, tildirel, tildisrl, tinotint,
      tinotbol, tilodlen, ticvtgtf, tinegint, tiabsint, tisqrint, tiodd, tisucint,
      tiprdint, tirngchk, tilditgp, ticvtftg, ticvtitr, tinegrel, tiabsrel, tisqrrel,
      tiatnrel, ticosrel, tiexprel, tilgnrel, tisinrel, tisqtrel,
      tirecoff, ticvtrtsr, tiaddintimm,  timltintimm, tiandintimm, tiequintimm,
      tiequtgpimm, tineqintimm, tineqtgpimm, tiorintimm, tixorintimm,
      tileqintimm, tigeqintimm, tiltnintimm, tigtnintimm,
      tisubintimm, tiaddintlod, timltintlod, tiandintlod, tiequintlod,
      tiequtgplod, tineqintlod, tineqtgplod, tiorintlod, tixorintlod, tileqintlod,
      tigeqintlod, tiltnintlod, tigtnintlod, tisubintlod: maktmpexp(ip^.left);

      tidivint, timodint, tiarfgar, timltint, tiaddint, tisubint, tiandint, tiorint,
      tixorint, tiarrref, timltrel, tidivrel, tiaddrel, tisubrel, tiequrel, tineqrel,
      tileqrel, tigeqrel, tiltnrel, tigtnrel, tiequgst, tineqgst, tigeqgst, tiltngst,
      tigtngst, tiequtgp, tineqtgp, tiequint, tineqint, tileqint, tigeqint, tiltnint,
      tigtnint, tiequstr, tineqstr, tileqstr, tigeqstr, tiltnstr, tigtnstr,
      tileqgst, tiaddintldi, timltintldi, tiandintldi, tiequintldi, tiequtgpldi,
      tineqintldi, tineqtgpldi, tiorintldi, tixorintldi, tileqintldi, tigeqintldi,
      tiltnintldi, tigtnintldi, tisubintldi: begin

         maktmpexp(ip^.left);
         maktmpexp(ip^.right)

      end

      { trap other entries }

      else error(esysflt173) { should not occur }

   end;
   if flsttmp then begin

      write('maktmpexp: intermediate: -');
      prttic(ip^.i, 1);
      writeln

   end

end;

{ make temps for single operand }

procedure maktmpop(ip: intptr);

var ip1: intptr; { pointer for intermediates }

begin

   if flsttmp then begin

      write('maktmpop: intermediate: ');
      prttic(ip^.i, 1);
      writeln

   end;

   case ip^.i of { intermediate }

      tigoto, tilabequ, tihalt: ; { no action }

      tigotot, tigotof: maktmpexp(ip^.left); { condition }

      tiprccal, tiprccalo: begin

         { process parameters }
         ip1 := ip^.flow2; { index top of parameter list }
         while ip1 <> nil do begin { traverse }

            maktmpexp(ip1^.left); { evaluate parameter }
            { Check real, and allocate temp if so. }
            if realt(ip1^.base) then gettmp(ip1^.base, ip1^.base2);
            ip1 := ip1^.flow { next parameter }

         end;
         { now free up all temps allocated }
         ip1 := ip^.flow2; { index top of parameter list }
         while ip1 <> nil do begin { traverse }

            if realt(ip1^.base) then puttmp(ip1^.base2); { real, free it }
            if (ip1^.left^.i = tilodsrc) or (ip1^.left^.i = tildisrc) then
               puttmp(ip1^.left^.base2); { free structure temp }
            { determine if an operator returning a set. note that this is too big
              for a set operation to check }
            if (ip1^.left^.i = tilodset) or (ip1^.left^.i = tildiset) or
               (ip1^.left^.i = tiintset) or (ip1^.left^.i = tiuniset) or
               (ip1^.left^.i = tidifset) or (ip1^.left^.i = tisinset) or
               (ip1^.left^.i = tirngset) or (ip1^.left^.i = tilimns) then poptmp;
            ip1 := ip1^.flow { next parameter }

         end

      end;

      tiprccali: begin { procedure/function call }

         maktmpexp(ip^.left); { address }
         { process parameters }
         ip1 := ip^.flow2; { index top of parameter list }
         while ip1 <> nil do begin { traverse }

            maktmpexp(ip1^.left); { evaluate parameter }
            { Check real, and allocate temp if so. }
            if realt(ip1^.base) then gettmp(ip1^.base, ip1^.base2);
            ip1 := ip1^.flow { next parameter }

         end;
         { now free up all temps allocated }
         ip1 := ip^.flow2; { index top of parameter list }
         while ip1 <> nil do begin { traverse }

            if realt(ip1^.base) then puttmp(ip1^.base2); { real, free it }
            if (ip1^.left^.i = tilodsrc) or (ip1^.left^.i = tildisrc) then
               puttmp(ip1^.left^.base2); { free structure temp }
            { determine if an operator returning a set. note that this is too big
              for a set operation to check }
            if (ip1^.left^.i = tilodset) or (ip1^.left^.i = tildiset) or
               (ip1^.left^.i = tiintset) or (ip1^.left^.i = tiuniset) or
               (ip1^.left^.i = tidifset) or (ip1^.left^.i = tisinset) or
               (ip1^.left^.i = tirngset) or (ip1^.left^.i = tilimns) then poptmp;
            ip1 := ip1^.flow { next parameter }

         end

      end;

      tistoset: begin

         maktmpexp(ip^.left);
         poptmp { remove set }

      end;

      tistiset: begin

         maktmpexp(ip^.left);
         maktmpexp(ip^.right);
         poptmp { remove set }

      end;

      tiwrtset: begin

         maktmpexp(ip^.left);
         maktmpexp(ip^.right);
         poptmp { remove set }

      end;

      tinew: begin

         maktmpexp(ip^.left); { evaluate address }
         { Dispose returns a tagged pointer, but we only need the pointer. So
           we use a temp to do the convertion. }
         gettmp(gbltgp, ip^.base2)

      end;

      tiwrteolt, tiredeolt, tiget, tigett, tiput, tireset, tirewrite, ticlose,
      tiupdate, tiappend, tipaget, tidel, tidisp, tistoint, tistosrl, tistorel,
      tistochr, tistobol, tistosrc, tistofint, tistofsrl, tistofrel, tistofchr,
      tistofbol, tidspgar, tistogar, tistotgp, tistoftgp, tisignal, tisignalone,
      tiwait: maktmpexp(ip^.left);

      tiwrtsrc, tiwrtintt, tiwrtchrt, tiwrtbolt, tiwrtrelt, tiwrtstrt,
      tistiint, tistisrl, tistirel, tistichr, tistibol, tistisrc,
      tistifint, tistifsrl, tistifrel, tistifchr, tistifbol, tiwrtsrl,
      tiwrtrel, tiwrtbol, tiwrtchr, tiwrtint, tiredsrc, tiredchrt, tiredrelt, tiredsrlt,
      tipos, tichg, tiwrtgstt, tistigar, tistitgp, tistiftgp, tiassign,
      tinewgar: begin

         maktmpexp(ip^.left);
         maktmpexp(ip^.right);

      end;
      tiassert: if fincast then begin { include asserts enabled }

         maktmpexp(ip^.left);
         maktmpexp(ip^.right);

      end;
      tiredintt: begin

         maktmpexp(ip^.left);
         maktmpexp(ip^.right);
         { if we need an odd size, must pass through temp }
         if ip^.base^.size <> regsiz then gettmp(gblint, ip^.base2)

      end;
      tiwrtintft, tiwrtchrft, tiwrtbolft, tiwrtrelft, tiwrtstrft, tipack,
      tiunpack, tiwrtgstft: begin

         maktmpexp(ip^.left);
         maktmpexp(ip^.right);
         maktmpexp(ip^.xtra);

      end;
      tiwrtrelfft: begin

         maktmpexp(ip^.left);
         maktmpexp(ip^.right);
         maktmpexp(ip^.xtra);
         maktmpexp(ip^.xtra2);

      end;

      { structured entries }

      tiifbgn: begin { if statement }

         maktmpexp(ip^.left);
         maktmplst(ip^.flow2); { process true flow }
         maktmplst(ip^.flow3) { process false flow }

      end;

      tiwhlbgn, tirptbgn, ticasbgn: begin

         maktmpexp(ip^.left);
         maktmplst(ip^.flow2) { process enclosed flow }

      end;

      tiwthbgn: begin

         maktmpexp(ip^.left); { record base address }
         maktmplst(ip^.flow2) { process enclosed flow }

      end;

      tifortint, tifortchr, tifortbol, tifordint, tifordchr,
      tifordbol: begin

         maktmpexp(ip^.left); { start }
         maktmpexp(ip^.right); { end }
         maktmplst(ip^.flow2); { for loop }
         gettmp(baset(ip^.base), ip^.base2); { get temp for end expression }
         { check possible side effects in start or end expressions }
         if chkfncexp(ip^.left) or chkfncexp(ip^.right) then
            gettmp(baset(ip^.base), ip^.base3) { get temp for start expression }

      end;

      ticasstb, ticasels: maktmplst(ip^.flow2); { case entry }

      titrybgn: begin

         maktmplst(ip^.flow2); { protected block }
         maktmplst(ip^.flow3) { exception clause list }

      end;

      titryexp: begin

         maktmpexp(ip^.left); { exception variable }
         maktmplst(ip^.flow2) { exception statement block }

      end;

      titryels: maktmplst(ip^.flow2) { else statement block }

      { trap other cases }
      else error(esysflt132) { bad case error }

   end;
   if tmpnum > 0 then error(estmplft); { should not be a temp allocated }
   if flsttmp then begin

      write('maktmpop: intermediate: -');
      prttic(ip^.i, 1);
      writeln

   end

end;

procedure maktmplst(ip: intptr);

begin

   while ip <> nil do begin { traverse this forward flow }

      maktmpop(ip); { follow secondary flows single node }
      ip := ip^.flow { next in flow }

   end

end;

begin

   { clear temp stack }
   for ti := 1 to tmpmax do tmpstk[ti] := nil;
   for ti := 1 to tmpmax do tmptrk[ti] := nil;
   tmpnum := 0; { set no temps allocated }
   maktmplst(ip) { process list }

end;

{*******************************************************************************

Check operand references same base type

Checks operand of load references same base type.

*******************************************************************************}

function basequ(t: typptr; { object type to match }
                ip: intptr) { intermediate to match }
                : boolean; { result }

var f: boolean;

begin

   f := false; { set no match }
   if (ip^.i = tilodint) or (ip^.i = tilodchr) or (ip^.i = tilodbol) then
      { direct load cases }
      f := t = ip^.base; { set status of match }

   basequ := f { return result }

end;

{*******************************************************************************

Arrange associative operands

Associative operands don't care which side is on the left or the right. For the
80x86 series, placing immediates, direct loads, and indirect loads on the right
hand side enables the use of special instruction formats. We pass over the
intermediate tree looking for such associative intermediates, and if found, they
are swapped. If both sides qualify, then the swap is not done. The reason for
this is simply that if there is no reason to reorder the code, it is not done.

To determine the swap, we rate each associative operand left and right according
to:

Priority  Mode
===================================================================
4         Immediate integer load
3         Direct address load
2         Indirect address load (load from calculated address)
1         Array reference

There are other reasons to flip associative pairs. For example, the 80x86
instruction set allows a := a+b combinations to be reduced to a single
instruction, and we move all such equal destination/source operands that
associate to the left side such that they are normalized, and always found on
the left.

*******************************************************************************}

procedure arrass(ip: intptr);

var tip: intptr;

{ process possible exchange }

procedure exgopr(ip: intptr);

var tip: intptr;

{ Find priority level of operand, immediate -> 4, direct load -> 3,
  indirect load -> 2, array reference -> 1 other -> 0 }

function chkexg(ip: intptr): integer;

var pri: integer;

begin

   pri := 0; { set no priority }
   if ip^.i = tilimint then pri := 4
   else if (ip^.i = tilodint) or (ip^.i = tilodchr) or
           (ip^.i = tilodbol) then pri := 3
   else if (ip^.i = tildiint) or (ip^.i = tildichr) or
           (ip^.i = tildibol) then pri := 2
   else if ip^.i = tiarrref then pri := 1;

   chkexg := pri { return priority }

end;

begin

   if chkexg(ip^.left) > chkexg(ip^.right) then begin

      { left side is higher priority than right, swap }
      tip := ip^.left;
      ip^.left := ip^.right;
      ip^.right := tip

   end

end;

{ process list }

procedure arrasslst(ip: intptr); forward;

{ process expression }

procedure arrassexp(ip: intptr); { operator to process }

var ip1: intptr; { pointer for intermediates }

begin

   if flstara then begin

      write('arrassexp: intermediate: ');
      prttic(ip^.i, 1);
      writeln

   end;

   case ip^.i of { intermediate }

      tifnccal, tifnccalo: begin

         { process parameters }
         ip1 := ip^.flow2; { index top of parameter list }
         while ip1 <> nil do begin { traverse }

            arrassexp(ip1^.left); { evaluate parameter }
            ip1 := ip1^.flow { next parameter }

         end

      end;

      tifnccali: begin

         arrassexp(ip^.left); { address of function }
         { process parameters }
         ip1 := ip^.flow2; { index top of parameter list }
         while ip1 <> nil do begin { traverse }

            arrassexp(ip1^.left); { evaluate parameter }
            ip1 := ip1^.flow { next parameter }

         end

      end;

      { no operands }
      tilodset, tilimns, tilodsrc, tilodadr, tilodint, tilodrel, tilodsrl,
      tilodchr, tilodbol, tilodptr, tilimint, tilimrel, tilodfadr, tilodtgp: ;

      { one operand }
      tildiset, tirnd, titrc, tildisrc, tieolt, tieof, tiloc, tilen, tilodafbuf, tilodafbuft, tiexist,
      ticvtntg, tildiint, tildichr, tildibol, tildiptr, tildirel, tildisrl, tinotint,
      tinotbol, tilodlen, ticvtgtf, tinegint, tiabsint, tisqrint, tiodd, tisucint,
      tiprdint, tirngchk, tilditgp, ticvtftg, ticvtitr, tinegrel, tiabsrel, tisqrrel,
      tiatnrel, ticosrel, tiexprel, tilgnrel, tisinrel, tisqtrel,
      tirecoff, ticvtrtsr, tiaddintimm, timltintimm, tiandintimm, tiequintimm,
      tiequtgpimm, tineqintimm, tineqtgpimm, tiorintimm, tixorintimm,
      tileqintimm, tigeqintimm, tiltnintimm, tigtnintimm,
      tisubintimm, tiaddintlod, timltintlod, tiandintlod, tiequintlod,
      tiequtgplod, tineqintlod, tineqtgplod, tiorintlod, tixorintlod, tileqintlod,
      tigeqintlod, tiltnintlod, tigtnintlod, tisubintlod: arrassexp(ip^.left);

      { two operands }
      tiincset, tisinset, tiintset, tiuniset, tidifset, tiequset, tineqset,
      tileqset, tigeqset, tidivint, timodint, tiarfgar, tisubint, tiarrref,
      timltrel, tidivrel, tiaddrel, tisubrel, tiequrel, tineqrel, tileqrel,
      tigeqrel, tiltnrel, tigtnrel, tiequgst, tineqgst, tigeqgst, tiltngst,
      tigtngst, tileqint, tigeqint, tiltnint, tigtnint, tiequstr, tineqstr,
      tileqstr, tigeqstr, tiltnstr, tigtnstr, tileqgst, tiaddintldi,
      timltintldi, tiandintldi, tiequintldi, tiequtgpldi, tineqintldi,
      tineqtgpldi, tiorintldi, tixorintldi, tileqintldi, tigeqintldi,
      tiltnintldi, tigtnintldi, tisubintldi: begin

         arrassexp(ip^.left);
         arrassexp(ip^.right)

      end;

      { three operands }
      tirngset: begin

         arrassexp(ip^.left);
         arrassexp(ip^.right);
         arrassexp(ip^.xtra)

      end;

      { associative dual operand }
      tiaddint, tiandint, tiorint, tixorint, timltint, tiequint,
      tineqint, tiequtgp, tineqtgp: begin

         arrassexp(ip^.left);
         arrassexp(ip^.right);
         exgopr(ip) { process possible exchange }

      end

      { trap other entries }
      else error(esysflt173) { should not occur }

   end;
   if flstara then begin

      write('arrassexp: intermediate: -');
      prttic(ip^.i, 1);
      writeln

   end

end;

{ process single operand }

procedure arrassop(ip: intptr);

var ip1: intptr; { pointer for intermediates }

begin

   if flstara then begin

      write('arrassop: intermediate: ');
      prttic(ip^.i, 1);
      writeln

   end;

   case ip^.i of { intermediate }

      tigoto, tilabequ, tihalt: ; { no action }

      tigotot, tigotof: arrassexp(ip^.left); { condition }

      tiprccal, tiprccalo: begin

         { process parameters }
         ip1 := ip^.flow2; { index top of parameter list }
         while ip1 <> nil do begin { traverse }

            arrassexp(ip1^.left); { evaluate parameter }
            ip1 := ip1^.flow { next parameter }

         end;
         { now free up all temps allocated }
         ip1 := ip^.flow2; { index top of parameter list }
         while ip1 <> nil do begin { traverse }

            ip1 := ip1^.flow { next parameter }

         end

      end;

      tiprccali: begin { procedure/function call }

         arrassexp(ip^.left); { address }
         { process parameters }
         ip1 := ip^.flow2; { index top of parameter list }
         while ip1 <> nil do begin { traverse }

            arrassexp(ip1^.left); { evaluate parameter }
            ip1 := ip1^.flow { next parameter }

         end;
         { now free up all temps allocated }
         ip1 := ip^.flow2; { index top of parameter list }
         while ip1 <> nil do begin { traverse }

            ip1 := ip1^.flow { next parameter }

         end

      end;

      tistoset: arrassexp(ip^.left);

      tistiset: begin

         arrassexp(ip^.left);
         arrassexp(ip^.right)

      end;

      tiwrtset: begin

         arrassexp(ip^.left);
         arrassexp(ip^.right)

      end;

      tinew: arrassexp(ip^.left); { evaluate address }

      tiwrteolt, tiredeolt, tiget, tigett, tiput, tireset, tirewrite, ticlose,
      tiupdate, tiappend, tipaget, tidel, tidisp, tistosrl, tistorel, tistosrc,
      tistofsrl, tistofrel, tidspgar, tistogar, tistotgp,
      tistoftgp, tisignal, tisignalone, tiwait: arrassexp(ip^.left);

      tiwrtsrc, tiwrtintt, tiwrtchrt, tiwrtbolt, tiwrtrelt, tiwrtstrt,
      tistiint, tistisrl, tistirel, tistichr, tistibol, tistisrc,
      tistifint, tistifsrl, tistifrel, tistifchr, tistifbol, tiwrtsrl,
      tiwrtrel, tiwrtbol, tiwrtchr, tiwrtint, tiredsrc, tiredchrt, tiredrelt, tiredsrlt,
      tipos, tichg, tiwrtgstt, tistigar, tistitgp, tistiftgp, tiassign,
      tinewgar, tiassert: begin

         arrassexp(ip^.left);
         arrassexp(ip^.right);

      end;
      tiredintt: begin

         arrassexp(ip^.left);
         arrassexp(ip^.right)

      end;
      tiwrtintft, tiwrtchrft, tiwrtbolft, tiwrtrelft, tiwrtstrft, tipack,
      tiunpack, tiwrtgstft: begin

         arrassexp(ip^.left);
         arrassexp(ip^.right);
         arrassexp(ip^.xtra);

      end;
      tiwrtrelfft: begin

         arrassexp(ip^.left);
         arrassexp(ip^.right);
         arrassexp(ip^.xtra);
         arrassexp(ip^.xtra2);

      end;

      tistoint, tistochr, tistobol, tistofint, tistofchr,
      tistofbol: begin

         arrassexp(ip^.left);
         { Check left side is add, and, or or xor, and the right side of that is
           the is the same as the result. This allows the use of a two address
           instruction, so we flip operands so that it is left. }
         if (ip^.left^.i = tiaddint) or (ip^.left^.i = tiandint) or
            (ip^.left^.i = tiorint) or (ip^.left^.i = tixorint) then begin

            { Check right side of that operator is same as the destination, and
              swap to left if so. We suppress this if the left is also the same,
              but this just suppresses meaningless swaps of a := a+a, for
              example. }
            if basequ(ip^.base, ip^.left^.right) and
               not basequ(ip^.base, ip^.left^.left) then with ip^.left^ do begin

               { swap operands }
               tip := left;
               left := right;
               right := tip

            end

         end

      end;

      { structured entries }

      tiifbgn: begin { if statement }

         arrassexp(ip^.left);
         arrasslst(ip^.flow2); { process true flow }
         arrasslst(ip^.flow3) { process false flow }

      end;

      tiwhlbgn, tirptbgn, ticasbgn: begin

         arrassexp(ip^.left);
         arrasslst(ip^.flow2) { process enclosed flow }

      end;

      tiwthbgn: begin

         arrassexp(ip^.left); { record base address }
         arrasslst(ip^.flow2) { process enclosed flow }

      end;

      tifortint, tifortchr, tifortbol, tifordint, tifordchr,
      tifordbol: begin

         arrassexp(ip^.left); { start }
         arrassexp(ip^.right); { end }
         arrasslst(ip^.flow2) { for loop }

      end;

      ticasstb, ticasels: arrasslst(ip^.flow2); { case entry }

      titrybgn: begin

         arrasslst(ip^.flow2); { protected block }
         arrasslst(ip^.flow3) { exception clause list }

      end;

      titryexp: begin

         arrassexp(ip^.left); { exception variable }
         arrasslst(ip^.flow2) { exception statement block }

      end;

      titryels: arrasslst(ip^.flow2) { else statement block }

      { trap other cases }
      else error(esysflt132) { should not occur }

   end;
   if flstara then begin

      write('arrassop: intermediate: -');
      prttic(ip^.i, 1);
      writeln

   end

end;

procedure arrasslst(ip: intptr);

begin

   while ip <> nil do begin { traverse this forward flow }

      arrassop(ip); { follow secondary flows single node }
      ip := ip^.flow { next in flow }

   end

end;

begin

   arrasslst(ip) { process list }

end;

{******************************************************************************

Resolve breakdown products

Tours the intermediate tree, and changes several intermediates to simpler
operations based on the availablity of instructions for specific cases.

Load and store simplification are a form of breakdown products formation. The
difference in this routine is that the breakdown products can be choosen for
processor specific reasons, such as the availablity of a certain instruction
in a certain size, whereas load/store simplification is not processor
specific.

The breakdown products method is used both to simplify and break out special
cases, as well as to prevent the register allocation from having to know too
much about generator semantics.

******************************************************************************}

procedure breakdown(var mip: intptr);

var ip, ip1: intptr;

{ load/store expression }

procedure breakdownexp(var ip: intptr);

var ip2, ip3: intptr;
    sgnchk:   boolean; { mixed sign operation requires checking }
    quad:     boolean; { operation is performed in double }

begin

   case ip^.i of { intermediate }

      { no action required entries }
      tilodset, tilimns, tilodint, tilimint, tilodrel, tilimrel, tilodsrl, tilodchr,
      tilodbol, tilodsrc, tilodptr, tilodtgp, tilodadr, tilodfadr: ;

      { unary }
      tieolt, tieof, tinotbol, tiodd, tiexist, tiloc, tilen, tinotint, tilodlen, tinegint,
      tiabsint, tisqrint, tirnd, titrc, ticvtitr, tinegrel, tiabsrel, tisqrrel, tiatnrel,
      ticosrel, tiexprel, tilgnrel, tisinrel, tisqtrel, tirngchk, tilodafbuft,
      tilodafbuf, tirecoff, tisucint, tiprdint, ticvtgtf, ticvtftg, ticvtntg,
      ticvtrtsr, tildiint, tildibol, tildirel, tildiset, tildichr, tildisrl,
      tildisrc, tildiptr, tilditgp, tiaddintimm, timltintimm, tiandintimm,
      tiequintimm, tiequtgpimm, tineqintimm, tineqtgpimm, tiorintimm,
      tixorintimm, tileqintimm, tigeqintimm, tiltnintimm, tigtnintimm,
      tisubintimm, tiaddintlod, timltintlod, tiandintlod, tiequintlod,
      tiequtgplod, tineqintlod, tineqtgplod, tiorintlod, tixorintlod, tileqintlod,
      tigeqintlod, tiltnintlod, tigtnintlod, tisubintlod: breakdownexp(ip^.left);

      { binary }
      tidivint, timodint, tiintset, tiuniset, tidifset, tiequset, tineqset,
      tileqset, tigeqset, tiequrel, tineqrel, tileqrel, tigeqrel, tiltnrel,
      tigtnrel, tiequgst, tineqgst, tigeqgst, tiltngst, tigtngst, tiequstr,
      tineqstr, tileqstr, tigeqstr, tiltnstr, tigtnstr, tiincset, timltrel,
      tidivrel, tiaddrel, tisubrel, tisinset, tiarrref, tiarfgar, tileqgst,
      tiaddintldi, timltintldi, tiandintldi, tiequintldi, tiequtgpldi,
      tineqintldi, tineqtgpldi, tiorintldi, tixorintldi, tileqintldi,
      tigeqintldi, tiltnintldi, tigtnintldi, tisubintldi: begin

         breakdownexp(ip^.left);
         breakdownexp(ip^.right);

      end;

      { trinary }
      tirngset: begin

         breakdownexp(ip^.left);
         breakdownexp(ip^.right);
         breakdownexp(ip^.xtra)

      end;

      tifnccal, tifnccalo: breakdown(ip^.flow2); { parameter list }

      tifnccali: begin

         breakdownexp(ip^.left); { address of function }
         breakdown(ip^.flow2) { parameter list }

      end;

      { associative binary operator with one side immediate }
      tiaddint, tiandint, tiequint, tiequtgp, tineqint, tineqtgp, tiorint,
      tixorint, timltint: begin

         breakdownexp(ip^.left);
         breakdownexp(ip^.right);
         { find if either operand needs to be checked for sign }
         sgnchk := chksgn(ip^.left^.rbase) <> chksgn(ip^.right^.rbase);
         { find if operation must be performed in quad precision math }
         quad := (ip^.left^.rbase^.size > regsiz) or
                 (ip^.right^.rbase^.size > regsiz);
         { either side immediate can be used }
         if (ip^.right^.i = tilimint) or (ip^.left^.i = tilimint) then begin

            { process immediate form }
            case ip^.i of { get a operator immediate form by type }

               tiaddint: getint(ip2, tiaddintimm);
               tiandint: getint(ip2, tiandintimm);
               tiequint: getint(ip2, tiequintimm);
               tiequtgp: getint(ip2, tiequtgpimm);
               tineqint: getint(ip2, tineqintimm);
               tineqtgp: getint(ip2, tineqtgpimm);
               tiorint:  getint(ip2, tiorintimm);
               tixorint: getint(ip2, tixorintimm);
               timltint: getint(ip2, timltintimm);

            end;
            { set base constant the same as immediate }
            if ip^.right^.i = tilimint then begin

               ip2^.base := ip^.right^.base;
               ip2^.left := ip^.left

            end else begin

               ip2^.base := ip^.left^.base;
               ip2^.left := ip^.right

            end;
            ip2^.rbase := ip^.rbase; { set result the same }
            ip2^.up := ip^.up; { set up links the same }
            ip2^.left^.up := ip2;
            ip3 := ip; { exchange for old entry }
            ip := ip2; { set new entry }
            putint(ip3^.left); { free it }
            putint(ip3) { free it }

         end else if (ip^.right^.i = tilodint) and not sgnchk and
                      not ((ip^.i = timltint) and quad) and
                     (ip^.right^.base^.size >= regsiz) and
                     (ip^.left^.rbase^.size = ip^.right^.base^.size) then begin

            { If the right side is a direct load, and sign checking is not
              required, is not a quad multiply, and both operands are register
              or quad size and equal. }

            { process immediate form }
            case ip^.i of { get a operator immediate form by type }

               tiaddint: getint(ip2, tiaddintlod);
               tiandint: getint(ip2, tiandintlod);
               tiequint: getint(ip2, tiequintlod);
               tiequtgp: getint(ip2, tiequtgplod);
               tineqint: getint(ip2, tineqintlod);
               tineqtgp: getint(ip2, tineqtgplod);
               tiorint:  getint(ip2, tiorintlod);
               tixorint: getint(ip2, tixorintlod);
               timltint: getint(ip2, timltintlod);

            end;
            { set base address the same as the direct load }
            ip2^.base := ip^.right^.base;
            ip2^.left := ip^.left;
            ip2^.rbase := ip^.rbase; { set result the same }
            ip2^.up := ip^.up; { set up links the same }
            ip2^.left^.up := ip2;
            ip3 := ip; { exchange for old entry }
            ip := ip2; { set new entry }
            putint(ip3^.left); { free it }
            putint(ip3) { free it }

         end else if (ip^.left^.i = tilodint) and not sgnchk and
                     not ((ip^.i = timltint) and quad) and
                     (ip^.left^.base^.size >= regsiz) and
                     (ip^.right^.rbase^.size = ip^.left^.base^.size) then begin

            { If the left side is a direct load, and sign checking is not
              required, is not a quad multiply, and both operands are register
              or quad size and equal. }

            { process immediate form }
            case ip^.i of { get a operator immediate form by type }

               tiaddint: getint(ip2, tiaddintlod);
               tiandint: getint(ip2, tiandintlod);
               tiequint: getint(ip2, tiequintlod);
               tiequtgp: getint(ip2, tiequtgplod);
               tineqint: getint(ip2, tineqintlod);
               tineqtgp: getint(ip2, tineqtgplod);
               tiorint:  getint(ip2, tiorintlod);
               tixorint: getint(ip2, tixorintlod);
               timltint: getint(ip2, timltintlod);

            end;
            { set base address the same as the direct load }
            ip2^.base := ip^.left^.base;
            ip2^.left := ip^.right;
            ip2^.rbase := ip^.rbase; { set result the same }
            ip2^.up := ip^.up; { set up links the same }
            ip2^.left^.up := ip2;
            ip3 := ip; { exchange for old entry }
            ip := ip2; { set new entry }
            putint(ip3^.left); { free it }
            putint(ip3) { free it }

         end else if (ip^.right^.i = tildiint) and not sgnchk and
                      not ((ip^.i = timltint) and quad) and
                     (ip^.right^.base^.size >= regsiz) and
                     (ip^.left^.rbase^.size = ip^.right^.base^.size) then begin

            { If the right side is an indirect load, and sign checking is not
              required, is not a quad multiply, and both operands are register
              or quad size and equal. }

            { process indirect form }
            case ip^.i of { get a operator immediate form by type }

               tiaddint: getint(ip2, tiaddintldi);
               tiandint: getint(ip2, tiandintldi);
               tiequint: getint(ip2, tiequintldi);
               tiequtgp: getint(ip2, tiequtgpldi);
               tineqint: getint(ip2, tineqintldi);
               tineqtgp: getint(ip2, tineqtgpldi);
               tiorint:  getint(ip2, tiorintldi);
               tixorint: getint(ip2, tixorintldi);
               timltint: getint(ip2, timltintldi);

            end;
            ip2^.left := ip^.left; { set left same }
            ip2^.right := ip^.right^.left; { reach down for address on right }
            ip2^.rbase := ip^.rbase; { set result the same }
            ip2^.up := ip^.up; { set up links the same }
            ip2^.left^.up := ip2;
            ip2^.right^.up := ip2;
            ip3 := ip; { exchange for old entry }
            ip := ip2; { set new entry }
            putint(ip3^.left); { free it }
            putint(ip3) { free it }

         end else if (ip^.left^.i = tildiint) and not sgnchk and
                     not ((ip^.i = timltint) and quad) and
                     (ip^.left^.base^.size >= regsiz) and
                     (ip^.right^.rbase^.size = ip^.left^.base^.size) then begin

            { If the left side is an indirect load, and sign checking is not
              required, is not a quad multiply, and both operands are register
              or quad size and equal. }

            { process immediate form }
            case ip^.i of { get a operator immediate form by type }

               tiaddint: getint(ip2, tiaddintldi);
               tiandint: getint(ip2, tiandintldi);
               tiequint: getint(ip2, tiequintldi);
               tiequtgp: getint(ip2, tiequtgpldi);
               tineqint: getint(ip2, tineqintldi);
               tineqtgp: getint(ip2, tineqtgpldi);
               tiorint:  getint(ip2, tiorintldi);
               tixorint: getint(ip2, tixorintldi);
               timltint: getint(ip2, timltintldi);

            end;
            ip2^.left := ip^.right; { set left to right }
            ip2^.right := ip^.left^.left; { reach down for address on left }
            ip2^.rbase := ip^.rbase; { set result the same }
            ip2^.up := ip^.up; { set up links the same }
            ip2^.left^.up := ip2;
            ip2^.right^.up := ip2;
            ip3 := ip; { exchange for old entry }
            ip := ip2; { set new entry }
            putint(ip3^.left); { free it }
            putint(ip3) { free it }

         end

      end;

      { non-associative binary operator with right side immediate }
      tileqint, tigeqint, tiltnint, tigtnint, tisubint: begin

         breakdownexp(ip^.left);
         breakdownexp(ip^.right);
         { find if either operand needs to be checked for sign }
         sgnchk := chksgn(ip^.left^.rbase) <> chksgn(ip^.right^.rbase);
         { find if operation must be performed in quad precision math }
         quad := (ip^.left^.rbase^.size > regsiz) or
                 (ip^.right^.rbase^.size > regsiz);
         if ip^.right^.i = tilimint then begin

            { process immediate form }
            case ip^.i of { get a operator immediate form by type }

               tileqint: getint(ip2, tileqintimm);
               tigeqint: getint(ip2, tigeqintimm);
               tiltnint: getint(ip2, tiltnintimm);
               tigtnint: getint(ip2, tigtnintimm);
               tisubint: getint(ip2, tisubintimm);

            end;
            { set base constant the same as immediate }
            ip2^.base := ip^.right^.base;
            { set operand the same }
            ip2^.left := ip^.left;
            ip2^.rbase := ip^.rbase; { set result the same }
            ip2^.up := ip^.up; { set up links the same }
            ip2^.left^.up := ip2;
            ip3 := ip; { exchange for old entry }
            ip := ip2; { set new entry }
            putint(ip3^.left); { free it }
            putint(ip3) { free it }

         end else if (ip^.right^.i = tilodint) and not sgnchk and
                         not ((ip^.i = timltint) and quad) and
                         (ip^.right^.base^.size >= regsiz) and
                         (ip^.left^.rbase^.size = ip^.right^.base^.size) then begin

            { If the right side is a direct load, and sign checking is not
              required, is not a quad multiply, and both operands are register
              or quad size and equal. }

            { process immediate form }
            case ip^.i of { get a operator immediate form by type }

               tileqint: getint(ip2, tileqintlod);
               tigeqint: getint(ip2, tigeqintlod);
               tiltnint: getint(ip2, tiltnintlod);
               tigtnint: getint(ip2, tigtnintlod);
               tisubint: getint(ip2, tisubintlod);

            end;
            { set base address the same as the direct load }
            ip2^.base := ip^.right^.base;
            ip2^.left := ip^.left;
            ip2^.rbase := ip^.rbase; { set result the same }
            ip2^.up := ip^.up; { set up links the same }
            ip2^.left^.up := ip2;
            ip3 := ip; { exchange for old entry }
            ip := ip2; { set new entry }
            putint(ip3^.left); { free it }
            putint(ip3) { free it }

         end else if (ip^.right^.i = tildiint) and not sgnchk and
                         not ((ip^.i = timltint) and quad) and
                         (ip^.right^.base^.size >= regsiz) and
                         (ip^.left^.rbase^.size = ip^.right^.base^.size) then begin

            { If the right side is an indirect load, and sign checking is not
              required, is not a quad multiply, and both operands are register
              or quad size and equal. }

            { process immediate form }
            case ip^.i of { get a operator immediate form by type }

               tileqint: getint(ip2, tileqintldi);
               tigeqint: getint(ip2, tigeqintldi);
               tiltnint: getint(ip2, tiltnintldi);
               tigtnint: getint(ip2, tigtnintldi);
               tisubint: getint(ip2, tisubintldi);

            end;
            ip2^.left := ip^.left; { set left same }
            ip2^.right := ip^.right^.left; { reach down for address on right }
            ip2^.rbase := ip^.rbase; { set result the same }
            ip2^.up := ip^.up; { set up links the same }
            ip2^.left^.up := ip2;
            ip2^.right^.up := ip2;
            ip3 := ip; { exchange for old entry }
            ip := ip2; { set new entry }
            putint(ip3^.left); { free it }
            putint(ip3) { free it }

         end

      end

      { trap other cases }
      else error(esysflt75) { should not occur }

   end

end;

{ load/store operator }

procedure breakdownop(ip: intptr);

begin

   case ip^.i of { intermediate }

      tigoto, tilabequ, tihalt: ; { no action }

      tiprccal, tiprccalo: breakdown(ip^.flow2); { parameter list }

      tiprccali: begin { procedure/function call }

         breakdownexp(ip^.left); { address }
         breakdown(ip^.flow2) { parameter list }

      end;

      { unary }
      tigotot, tigotof, tiwrteolt, tiredeolt, tiget, tigett, tiput, tireset, tirewrite,
      ticlose, tiupdate, tiappend, tipaget, tidel, tinew, tidisp, tistoint,
      tistosrl, tistorel, tistochr, tistobol, tistoset, tistosrc, tistofint,
      tistofsrl, tistofrel, tistofchr, tistofbol, tidspgar, tistogar, tistotgp,
      tistoftgp, ticalpar, tisignal, tisignalone, tiwait: breakdownexp(ip^.left);

      { binary }
      tiwrtsrc, tiwrtintt, tiwrtchrt, tiwrtbolt, tiwrtrelt, tiwrtstrt,
      tiwrtsrl, tiwrtrel, tiwrtset, tiwrtbol, tiwrtchr, tiwrtint, tiredsrc, tiredintt,
      tiredchrt, tiredrelt, tiredsrlt, tipos, tichg, tiwrtgstt, tiassign,
      tinewgar, tistiint, tistisrl, tistirel, tistichr, tistibol, tistiset, tistisrc,
      tistifint, tistifsrl, tistifrel, tistifchr, tistifbol, tistigar, tistitgp,
      tistiftgp: begin

         breakdownexp(ip^.left);
         breakdownexp(ip^.right);

      end;

      tiassert: if fincast then begin { include asserts enabled }

         breakdownexp(ip^.left);
         breakdownexp(ip^.right);

      end;

      { trinary }
      tiwrtintft, tiwrtchrft, tiwrtbolft, tiwrtrelft, tiwrtstrft, tipack,
      tiunpack, tiwrtgstft: begin

         breakdownexp(ip^.left);
         breakdownexp(ip^.right);
         breakdownexp(ip^.xtra);

      end;

      { quad }
      tiwrtrelfft: begin

         breakdownexp(ip^.left);
         breakdownexp(ip^.right);
         breakdownexp(ip^.xtra);
         breakdownexp(ip^.xtra2);

      end;

      { structured entries }

      tiifbgn: begin { if statement }

         breakdownexp(ip^.left);
         breakdown(ip^.flow2); { process true flow }
         breakdown(ip^.flow3) { process false flow }

      end;

      tiwhlbgn, tirptbgn, ticasbgn: begin

         breakdownexp(ip^.left);
         breakdown(ip^.flow2) { process enclosed flow }

      end;

      tiwthbgn: begin

         breakdownexp(ip^.left); { record base address }
         breakdown(ip^.flow2) { process enclosed flow }

      end;

      tifortint, tifortchr, tifortbol, tifordint, tifordchr,
      tifordbol: begin

         breakdownexp(ip^.left); { start }
         breakdownexp(ip^.right); { end }
         breakdown(ip^.flow2) { for loop }

      end;

      ticasstb, ticasels: breakdown(ip^.flow2); { case entry }

      titrybgn: begin

         breakdown(ip^.flow2); { protected block }
         breakdown(ip^.flow3) { exception clause list }

      end;

      titryexp: begin

         breakdownexp(ip^.left); { exception variable }
         breakdown(ip^.flow2) { exception statement block }

      end;

      titryels: breakdown(ip^.flow2) { else statement block }

      { trap other cases }
      else error(esysflt65) { should not occur }

   end

end;

begin

   ip := mip; { index root }
   while ip <> nil do begin { traverse this forward flow }

      ip1 := ip^.flow; { save next in case this entry gets deleted }
      breakdownop(ip); { follow secondary flows single node }
      ip := ip1 { next in flow }

   end

end;

{*******************************************************************************

Find real parameter is registerable

Finds if the given real parameter is registerable, that is, it will go onto the
FPU stack and not the CPU stack.

*******************************************************************************}

function relreg(tp: typptr): boolean;

var rc: integer;
    hp: typptr;

begin

   { find head of parameter list }
   if tp^.t = tpar then hp := tp^.parh
   else if tp^.t = twpar then hp := tp^.wprh
   else error(esysflt229);
   case hp^.t of { find parameter list start }

      tproc:  hp := hp^.prcp;
      tfunc:  hp := hp^.fncp;
      tpproc: hp := hp^.pprp;
      tpfunc: hp := hp^.pfnp

   end;
   rc := 1; { set reals count for our parameter }
   { count reals before our parameter }
   while (hp <> nil) and (hp <> tp) do begin

      { check is registerable real }
      if realt(hp) and ((hp^.t = tpar) or (hp^.t = twpar)) then
         rc := rc+1; { count reals }
      case hp^.t of { find next parameter }

         tpar:   hp := hp^.parn;
         tvpar:  hp := hp^.vprn;
         twpar:  hp := hp^.wprn;
         tpproc: hp := hp^.pprn;
         tpfunc: hp := hp^.pfnn

      end

   end;
   if hp = nil then error(esysflt227); { parameter not found }

   relreg := rc <= maxfst { set result }

end;

{*******************************************************************************

Find opposite flag

When a boolean in a flag is negated, it can be done for zero cost by just taking
the opposite value of the flag. This function returns the opposite value flag.

*******************************************************************************}

function flginv(f: flag): flag;

begin

   case f of { flag }

      flnull: error(esysflt104); { should not happen }
      fla:    f := flna;
      flae:   f := flnae;
      flb:    f := flnb;
      flbe:   f := flnbe;
      flc:    f := flnc;
      fle:    f := flne;
      flg:    f := flng;
      flge:   f := flnge;
      fll:    f := flnl;
      flle:   f := flnle;
      flna:   f := fla;
      flnae:  f := flae;
      flnb:   f := flb;
      flnbe:  f := flbe;
      flnc:   f := flc;
      flne:   f := fle;
      flng:   f := flg;
      flnge:  f := flge;
      flnl:   f := fll;
      flnle:  f := flle;
      flno:   f := flo;
      flnp:   f := flp;
      flns:   f := fls;
      flnz:   f := flz;
      flo:    f := flno;
      flp:    f := flnp;
      flpe:   f := flpo;
      flpo:   f := flpe;
      fls:    f := flns;
      flz:    f := flnz

   end;

   flginv := f { return result }

end;

{*******************************************************************************

Check extended parameter

Extended parameters are value parameters that get placed into a temp and
replaced by an address. This will basically be any value parameter that is
is structured.

*******************************************************************************}

function chkext(tp: typptr): boolean;

var f: boolean; { check flag }

begin

   f := false; { set not extended }
   if tp^.t = tpar then begin

      { if its a long real, and not registerable, then its extended }
      if realt(tp^.part) and not srealt(tp^.part) then f := not relreg(tp)
      { not tgp, larger than a register or structured }
      else f := not tgpt(tp^.part) and
                ((tp^.size > regsiz) or
                 (tp^.part^.t in [tarrcst, treccst, tarray, trecord]))

   end else if tp^.t = twpar then begin

      { if its a long real, and not registerable, then its extended }
      if realt(tp^.wprt) and not srealt(tp^.wprt) then f := not relreg(tp)
      { not tgp, larger than a register or structured }
      else f := not tgpt(tp^.wprt) and
                ((tp^.wprt^.size > regsiz) and not
                 (tp^.wprt^.t in [tarrcst, treccst, tarray, trecord]))

   end;

   chkext := f { return result }

end;

{*******************************************************************************

Check pointer load

Checks if the intermediate is a pointer load.

*******************************************************************************}

function chkptl(ip: intptr): boolean;

var m: boolean; { match }

begin

   m := false; { set no match }
   if ip^.i = tilodint then if ip^.rbase^.t = tptr then m := true; { found }
   if ip^.i = tildiptr then m := true; { found }

   chkptl := m { return result }

end;

{*******************************************************************************

Find free dword register

Finds a dword register that is not allocated at the given level. If none is
found, rgull is returned.

*******************************************************************************}

function frereg(ip: intptr): regt;

var ri, r: regt;    { register index }
    age:   integer; { age of entry }

begin

   r := rgnull; { set no register found }
   { search for registers in order eax, ebx, ecx, edx, esi, edi }
   for ri := rgedi downto rgeax do
      { search registers free and those not having contents }
      if not (ri in ip^.alc) and (regtrk[ri].con = nil) then r := ri;
   if r = rgnull then begin { not found, now use oldest contents }

      age := maxint; { set no age current }
      for ri := rgedi downto rgeax do if not (ri in ip^.alc) then
         if regtrk[ri].age < age then begin

            r := ri; { set register }
            age := regtrk[ri].age { set age of that }

         end

   end;

   frereg := r { return result }

end;

{*******************************************************************************

Find free byte storable dword register

As frereg, but only allocates a register from the set eax, ebx, ecx, and edx.
This is required as the edi and esi registers, usable in all other respects,
cannot store to byte memory operands.

*******************************************************************************}

function freregbs(ip: intptr): regt;

var ri, r: regt;    { register index }
    age:   integer; { age of entry }

begin

   r := rgnull; { set no register found }
   { search for registers in order eax, ebx, ecx, edx, esi, edi }
   for ri := rgedx downto rgeax do
      { search registers free and those not having contents }
      if not (ri in ip^.alc) and (regtrk[r].con = nil) then r := ri;
   if r = rgnull then begin { not found, now use oldest contents }

      age := maxint; { set no age current }
      for ri := rgedx downto rgeax do if not (ri in ip^.alc) then
         if regtrk[ri].age < age then begin

            r := ri; { set register }
            age := regtrk[ri].age { set age of that }

         end

   end;

   freregbs := r { return result }

end;

{*******************************************************************************

Get new register

Allocates a dword register and returns that. If no register is available,
we look for a register that was allocated above us, but not yet pushed. If that
is so, we can place it into the push mask and remove it from the current
context. If we cannot find that, then an error results.

The error will not happen, since all of the intermediates that exist won't
use more than the existing registers, so there should allways be a register
to be found.

*******************************************************************************}

procedure getreg(var r: regt; ip: intptr; var tr: regset);

var ri: regt; { register index }

begin

   r := frereg(ip); { find free register }
   if r <> rgnull then begin

      ip^.alc := ip^.alc+[r]; { set allocated }
      tr := tr+[r] { set total allocation }

   end else begin { dword registers are full }

      { check we are at a terminal, nothing to do }
      if ip^.up = ip then error(eregful)
      else begin { there is hope }

         { search for registers in order eax, ebx, ecx, edx, esi, edi,
           allocated in the top level mask, but not already pushed }
         for ri := rgedi downto rgeax do
            if (ri in ip^.up^.alc) and not (ri in ip^.push) then
               r := ri;
         { if found, leave allocated and add to push mask }
         if r <> rgnull then ip^.push := ip^.push+[r];
         { otherwise we are still full }
         if ip^.up = ip then error(eregful)

      end

   end

end;

{*******************************************************************************

Get new byte storable dword register

As getreg, but only allocates a register from the set eax, ebx, ecx, and edx.
This is required as the edi and esi registers, usable in all other respects,
cannot store to byte memory operands.

*******************************************************************************}

procedure getregbs(var r: regt; ip: intptr; var tr: regset);

var ri: regt; { register index }

begin

   r := freregbs(ip); { find free register }
   if r <> rgnull then begin

      ip^.alc := ip^.alc+[r]; { set allocated }
      tr := tr+[r] { set total allocation }

   end else begin { dword registers are full }

      { check we are at a terminal, nothing to do }
      if ip^.up = ip then error(eregful)
      else begin { there is hope }

         { search for registers in order eax, ebx, ecx, edx,
           allocated in the top level mask, but not already pushed }
         for ri := rgedx downto rgeax do
            if (ri in ip^.up^.alc) and not (ri in ip^.push) then
               r := ri;
         { if found, leave allocated and add to push mask }
         if r <> rgnull then ip^.push := ip^.push+[r];
         { otherwise we are still full }
         if ip^.up = ip then error(eregful)

      end

   end

end;

{*******************************************************************************

Place register

Allocates a given register. If the indicated register is not occupied, it is
allocated. If it is allocated on an upper level, it is pushed and allocated.
If it is allocated on the current level, then an error results, since that means
it is double allocated.

Any dword, byte or flag register can be placed. If a flag operand is placed,
the flag sense needs to be set as well.

*******************************************************************************}

procedure plcreg(r: regt; ip: intptr; var tr: regset);

begin

   { check allocated this level }
   if not (r in ip^.alc) then begin { no, we can allocate it here }

      ip^.alc := ip^.alc+[r]; { yes, allocate and exit }
      tr := tr+[r] { set total allocation }

   end else begin

      { Check only allocated this level, or already pushed, or we are at the
        top. }
      if not (r in ip^.up^.alc) or (r in ip^.push) or (ip^.up = ip) then
         error(eregdup);
      ip^.alc := ip^.alc+[r]; { allocate register }
      tr := tr+[r]; { set total allocation }
      ip^.push := ip^.push+[r] { and push }

   end

end;

{*******************************************************************************

Get new register with preference

Allocates a register with a preference. As getreg, but if the preffered register
is clear, then that is allocated first. This routine is used when it would save
code to have the given register, but its not worth the push/pop required to
demand the register, usually because a register move is all that would be
required to fix it.

If the preference is null (rgnull), then it is processed without the preference.

If the preference register is a flag, then it is ignored. Flags must be
specifically set, since they cannot replace normal registers.

*******************************************************************************}

procedure prfreg(var r: regt; pr: regt; ip: intptr; var tr: regset);

var ri: regt; { register index }

begin

   { try preference register first }
   if not (pr in ip^.alc) and (pr <> rgnull) and (pr <> rgflg) then begin

      { register is free }
      ip^.alc := ip^.alc+[pr]; { set allocated }
      tr := tr+[pr]; { set total allocation }
      r := pr { set the register result }

   end else begin

      ri := frereg(ip); { check registers are full }
      { Check no free, and there is a preference, and the preference can be
        pushed. }
      if (ri = rgnull) and (pr <> rgnull) and
         (not (pr in ip^.push) and (pr in ip^.up^.alc) and
          not (ip^.up = ip)) then begin

         { if registers are full, a preference exists, and the preference
           register not already pushed, and exists in the upper allocation
           (meaning not locally allocated), then we might as well use the
           preference, since we would have to pay for a push/pop in any case }
         plcreg(pr, ip, tr);
         r := pr { set the register result }

      end else getreg(r, ip, tr) { else get any register }

   end

end;

{*******************************************************************************

Perform result register process

Processes forming the final result register with a possible demand.
If the demand register is not rgnull, the result register is placed as a
demand. Otherwise, the register is allocated with a preference to the
operation result.

*******************************************************************************}

procedure prcres(dr, drx: regt; ip: intptr; var tr: regset);

begin

   if dr = rgnull then begin { no demand specified }

      prfreg(ip^.freg, ip^.rsreg, ip^.up, tr); { get transfer register }
      if ip^.rsregx <> rgnull then { get extended register }
         prfreg(ip^.fregx, ip^.rsregx, ip^.up, tr) { get transfer register }

   end else begin

      plcreg(dr, ip^.up, tr); { allocate the demand register }
      ip^.freg := dr; { place register }
      if drx <> rgnull then begin { place xtra register }

         plcreg(drx, ip^.up, tr); { allocate the demand register }
         ip^.fregx := drx { place register }

      end else if ip^.rsregx <> rgnull then { get extended register }
         prfreg(ip^.fregx, ip^.rsregx, ip^.up, tr); { get transfer register }
      if ip^.freg = rgflg then begin { perform special handling for flag case }

         { There are to cases for a demanded flag result. If the result is
           not a flag, it will be converted from a boolean. If the result is
           a flag, it gets passed as a flag }
         ip^.fflg := flnz; { default to not zero }
         if ip^.rsreg = rgflg then ip^.fflg := ip^.rsflg { set same }

      end

   end;
   { During allocations, a push might have been specified for the transfer
     register to protect higher level register contents. However, now that
     the result has been established, that protection will have moved up
     to the higher level, so it should not also be here. We remove the
     transfer registers from the push mask, if they exist. }
   ip^.push := ip^.push-[ip^.freg, ip^.fregx]

end;

{*******************************************************************************

Process procedure/function parameter list

Assigns registers for a procedure or function parameter list. Each parameter
is prepared with a register and possible temps. The context of the allocation
is done in the procedure or function entry given.

Parameters are divided into two classes, overflow and registered parameters.
Overflow parameters are evaluated and pushed into the stack before the
registered parameters are processed. Because the result register for an
overflow parameter are simply pushed, they are removed from the allocation
when evaluation is complete.

Registered parameters are given registers according to type and placement, in
the standard calling convention.

Note that it is currently possible to have an evaluated parameter in a
register "bounce", or get pushed and poped multiple times because later
parameter evaluations require that register. This remains as a further research
item.

*******************************************************************************}

procedure pfpar(ip:     intptr;  { procedure/function entry }
                var tr: regset); { total register allocation }

var plst:   typptr; { parameter list head }
    relcnt: integer; { real parameter counter }
    tgpcnt: integer; { tagged pointer counter }
    stdcnt: integer; { standard parameter counter }

    { Parameter information block. }

    allptot: integer; { number of total parameters }
    relptot: integer; { number of real parameters }
    tgpptot: integer; { number of tagged pointers }
    stdptot: integer; { number of standard parameters }
    tgprtot: integer; { number of registered tagged pointers }
    stdrtot: integer; { number of registered standard parameters }
    allreg:  regset;  { total register allocation mask }
    tgpreg:  regset;  { tagged pointer allocated registers }
    stdreg:  regset;  { standard allocated registers }

{ process real overflow parameters }

procedure relovf(ip: intptr); { list of stackable real parameters }

begin

   if ip <> nil then begin { there is a parameter }

      if ip^.i <> ticalpar then error(esysflt260);
      relovf(ip^.flow); { go to the depth of list first (right) }
      if realt(ip^.base) and (ip^.base^.t <> tvpar) then begin { found a real }

         if relcnt > maxfst then begin { in overflow counts }

            if not srealt(ip^.base) then { real }
               getreg(ip^.t1reg, ip, tr); { get register for address }
            { process to any register }
            regexp(rgnull, rgnull, ip, tr);

         end;
         relcnt := relcnt-1 { count off reals }

      end

   end

end;

{ process tagged overflow pointer parameters }

procedure tgpovf(ip: intptr); { list of  parameters }

begin

   if ip <> nil then begin { there is a parameter }

      if ip^.i <> ticalpar then error(esysflt255);
      tgpovf(ip^.flow); { go to the depth of list first (right) }
      if tgpt(ip^.base) or pfpt(ip^.base) then begin { its tagged }

         if tgpcnt > tgprtot then begin { in overflow counts }

            { process to any register }
            regexp(rgnull, rgnull, ip, tr);
            { Remove allocated registers from set. Each register gets pushed
              as it is evaluated, so this register will be clear in the
              code. }
            ip^.up^.alc := ip^.up^.alc-[ip^.freg];
            ip^.up^.alc := ip^.up^.alc-[ip^.fregx]

         end;
         tgpcnt := tgpcnt-1 { count off }

      end

   end

end;

{ process standard overflow parameters }

procedure stdovf(ip: intptr); { list of parameters }

begin

   if ip <> nil then begin { there is a parameter }

      if ip^.i <> ticalpar then error(esysflt256);
      stdovf(ip^.flow); { go to the depth of list first (right) }
      if not (realt(ip^.base) and (ip^.base^.t <> tvpar)) and
         not tgpt(ip^.base) and
         not pfpt(ip^.base) then begin { is a standard type }

         if stdcnt > stdrtot then begin { in overflow counts }

            { process to any register }
            regexp(rgnull, rgnull, ip, tr);
            { Remove allocated register from set. Each register gets pushed
              as it is evaluated, so this register will be clear in the
              code. }
            ip^.up^.alc := ip^.up^.alc-[ip^.freg]

         end;
         stdcnt := stdcnt-1 { count off }

      end

   end

end;

{ place real parameters in registers }

procedure relplc(ip: intptr); { list of stackable real parameters }

begin

   if ip <> nil then begin { there is a parameter }

      relplc(ip^.flow); { go to the depth of list first (right) }
      if realt(ip^.base) and (ip^.base^.t <> tvpar) then begin { its a real }

         if ip^.i <> ticalpar then error(esysflt261);
         if relcnt <= maxfst then { in register counts }
            regexp(rgnull, rgnull, ip, tr); { place into assigned registers }
         relcnt := relcnt-1 { count off reals }

      end

   end

end;

{ place tagged parameters and procedure/function parameters in registers }

procedure tgpplc(ip: intptr); { list of parameters }

var pc:      integer; { tagged parameter number }
    r:       regt;    { placement register }
    rr, rrx: regt; { result registers }

{ find next register allocated us }

procedure fndreg;

begin

   repeat { search }

      if r = rgedi then error(esysflt155); { should have found a register }
      r := succ(r) { find next register }

   until r in tgpreg

end;

begin

   pc := 1; { set what unreal we are processing }
   r := rgnull; { clear current register }
   while (ip <> nil) and (pc <= tgprtot) do begin

      if ip^.i <> ticalpar then error(esysflt257);
      { a parameter exists, and not out of registerable parameters }
      if tgpt(ip^.base) or pfpt(ip^.base) then begin { found }

         { restore this parameter to the proper register }
         fndreg; { find next register }
         rr := r; { place }
         fndreg; { find next register }
         rrx := r; { place }
         regexp(rr, rrx, ip, tr); { Place to assigned registers. }
         pc := pc+1 { count }

      end;
      ip := ip^.flow { next parameter }

   end

end;

{ place standard parameters in registers }

procedure stdplc(ip: intptr); { list of  parameters }

var pc:    integer; { tagged parameter number }
    r, rx: regt;    { placement register }

{ find next register allocated us }

procedure fndreg;

begin

   repeat { search }

      if r = rgedi then error(esysflt156); { should have found a register }
      r := succ(r) { find next register }

   until r in stdreg

end;

begin

   pc := 1; { set what unreal we are processing }
   r := rgnull; { clear current register }
   while (ip <> nil) and (pc <= stdrtot) do begin

      if ip^.i <> ticalpar then error(esysflt258);
      { a parameter exists, and not out of registerable parameters }
      if not (realt(ip^.base) and (ip^.base^.t <> tvpar)) and
         not tgpt(ip^.base) and not pfpt(ip^.base) then begin { found }

         fndreg; { find next register }
         regexp(r, rx, ip, tr); { place into assigned register }
         pc := pc+1 { count }

      end;
      ip := ip^.flow { next parameter }

   end

end;

begin

   case ip^.i of { index parameter list by type }

      tiprccal, tiprccalo:  plst := ip^.base^.prcp;
      tiprccali: plst := ip^.base^.pprp;
      tifnccal, tifnccalo:  plst := ip^.base^.fncp;
      tifnccali: plst := ip^.base^.pfnp

   end;

   { meter parameters }

   regfit(plst, allptot, relptot, tgpptot, stdptot, tgprtot, stdrtot, allreg,
          tgpreg, stdreg);

{

;writeln('allptot: ', allptot:1, ' relptot: ', relptot:1, ' tgpptot: ', tgpptot:1,
         ' stdptot: ', stdptot:1, ' tgprtot: ', tgprtot:1, ' stdrtot: ', stdrtot:1);
;write('allreg: '); lstregs(allreg); writeln;
;write('tgpreg: '); lstregs(tgpreg); writeln;
;write('stdreg: '); lstregs(stdreg); writeln;

}

   { process overflow parameters }

   relcnt := relptot; { reset counter }
   relovf(ip^.flow2); { process real overflow parameters to stack }
   tgpcnt := tgpptot; { reset counter }
   tgpovf(ip^.flow2); { process tagged pointer overflow parmeters to stack }
   stdcnt := stdptot; { reset counter }
   stdovf(ip^.flow2); { process standard overflow parmeters to stack }

   { process and assign registered parameters }

   relcnt := relptot; { reset counter }
   relplc(ip^.flow2); { process floating point parameters to registers }
   tgpplc(ip^.flow2); { process tagged pointer parmeters to registers }
   stdplc(ip^.flow2); { process standard parmeters to registers }

end;

{*******************************************************************************

Set register contents

Sets the type entry for the variable a register contains the contents of.

*******************************************************************************}

procedure setcxt(r: regt; { register to set }
                 t: typptr); { type to set to }

begin

   if fregcon then begin { register contents are to be reused }

      regtrk[r].con := t; { set contents }
      regtrk[r].age := curage; { set starting age of entry }
      curage := curage+1 { count off age ticks }

   end

end;

{*******************************************************************************

Remove register contents

Kills the contents of a given register. Essentially sets the register contents
as undefined.

*******************************************************************************}

procedure remcxt(r: regt); { register to clear }

begin

   regtrk[r].con := nil; { kill contents }
   regtrk[r].age := 0; { clear age }
   curage := curage+1 { count off age ticks }

end;

{*******************************************************************************

Copy register context

Copies the context from one register to another. Used to reflect a copy of one
register to another.

*******************************************************************************}

procedure cpycxt(dr, sr: regt); { destination and source registers }

begin

   regtrk[dr] := regtrk[sr] { copy }

end;

{*******************************************************************************

Copy register context pair

Copies the context from one register pair to another. Used to reflect a copy of
one register pair to another.

Copying a pair of registers is special because the source and destinations
might conflict (an exchange).

*******************************************************************************}

procedure cpycxtp(dr1, dr2, sr1, sr2: regt);

var rcs: regcon; { single context save }

begin

   rcs := regtrk[sr2]; { save second context against overwrite }
   regtrk[dr1] := regtrk[sr1]; { copy 1st }
   regtrk[dr2] := rcs { copy 2nd }

end;

{*******************************************************************************

Find context entry

Finds a register that contains the context of the given type. Returns rgnull
if none is found.

*******************************************************************************}

function fndcxt(t: typptr): regt;

var r, f: regt; { registers }

begin

   f := rgnull; { set not found }
   { search for matching contexts }
   for r := rgeax to rgedi do if regtrk[r].con = t then f := r;

   fndcxt := f { return that }

end;

{*******************************************************************************

Merge register contexts

Merges the given register context with the present context. All entries that are
not common to both contexts are nulled.

*******************************************************************************}

procedure mrgcxt(view rc: regcxt);

var r: regt; { registers }

begin

   { for each context }
   for r := rgnull to rgflg do begin

      if regtrk[r].con <> rc[r].con then remcxt(r) { does not match, remove }
      else if regtrk[r].age < rc[r].age then
         { matches, set age to newest of both }
         regtrk[r].age := rc[r].age

   end

end;

{*******************************************************************************

Clear register context

Clears all entries out of the current register context.

*******************************************************************************}

procedure clrcxt;

var r: regt; { registers }

begin

   for r := rgnull to rgflg do remcxt(r) { clear }

end;

{*******************************************************************************

Clear stored context

Clears a specific context.

*******************************************************************************}

procedure rescxt(var rc: regcxt);

var r: regt; { registers }

begin

   for r := rgnull to rgflg do with rc[r] do begin

      con := nil; { kill contents }
      age := 0 { clear age }

   end

end;

{*******************************************************************************

Match and remove context entries

Matches the given type against all active register contexts. If found, the
context is removed. This routine is used to remove stale contexts on a store.

*******************************************************************************}

procedure matcxt(t: typptr); { type to match }

var r: regt;

begin

   { remove matching contexts }
   for r := rgnull to rgflg do if regtrk[r].con = t then remcxt(r)

end;

{*******************************************************************************

Dump register context

A diagnostic, dumps the current status of the register contexts.

*******************************************************************************}

procedure dmpcxt;

var r: regt;

begin

   writeln;
   writeln('Register context');
   writeln;
   for r := rgnull to rgflg do with regtrk[r] do begin

      write('Reg: ');
      prtreg(r);
      write(' Age: ', age:1, ' ');
      if con = nil then write('<nil>')
      else lsttypetyi(con);
      writeln

   end

end;

{*******************************************************************************

Output register allocation diagnostic

Outputs register allocation information for the given intermediate. Used to
produce the register allocation rule listing.

*******************************************************************************}

procedure regdiag(ip: intptr; start: boolean);

procedure regprt(r, rx: regt; f: flag; view s: string);

begin

   if r <> rgnull then begin

      write(' ', s, ': ');
      prtreg(r);
      if r = rgflg then begin

         write('(');
         prtflg(f);
         write(')')

      end;
      if rx <> rgnull then begin

         write(',');
         prtreg(rx);

      end;

   end

end;

begin

   if flstreg then begin { list register allocation rules }

      { mark start or end of process }
      if start then write('+') else write('-');
      prttic(ip^.i, 1);
      if ip^.alc <> [] then begin

         write(' alc: ');
         lstregs(ip^.alc)

      end;
      if ip^.push <> [] then begin

         write(' push: ');
         lstregs(ip^.push)

      end;
      regprt(ip^.rsreg, ip^.rsregx, ip^.rsflg, 'res');
      regprt(ip^.freg,  ip^.fregx,  ip^.fflg,  'xfr');
      regprt(ip^.lreg,  ip^.lregx,  ip^.lflg,  'lft');
      regprt(ip^.rreg,  ip^.rregx,  ip^.rflg,  'rgt');
      regprt(ip^.xreg,  ip^.xregx,  ip^.xflg,  'xtra');
      regprt(ip^.x2reg, ip^.x2regx, ip^.x2flg, 'xtra2');
      regprt(ip^.t1reg, ip^.t1regx, flnull,    't1');
      regprt(ip^.t2reg, ip^.t2regx, flnull,    't2');
      regprt(ip^.t3reg, ip^.t3regx, flnull,    't3');
      if ip^.skip then write(' skip');
      writeln

   end

end;

{*******************************************************************************

Perform register allocation for expression

Allocates registers for the given expression tree. The result of the expression
is left allocated, and is left in the operator entry.

*******************************************************************************}

procedure regexp(    rr, rrx: regt;    { demand for result register }
                     ip:      intptr;  { this operand }
                 var tr:      regset); { total register allocation }

var i:      integer;
    f:      boolean;
    r:      regt;
    rcn:    regcxt;  { register context save }
    ptrind: boolean; { pointer is being indirected }
    signed: boolean; { signed operation flag }
    sgnchk: boolean; { mixed sign operation requires checking }
    quad:   boolean; { operation is quad precision }
    tagp:   typptr;  { tag field pointer }
    casp:   typptr;  { case pointer }
    frp:    typptr;  { function result type pointer }
    ti:     ssint;

{

Do standard left side allocation

Given an operator node, a standard no-preference register allocation is done on
the left side. If a quad operation is specified, and the left side is not
already a quad operand, an extended register is also allocated.

}

procedure doleft(ip: intptr; { intermediate to process }
                 quad: boolean); { quad/single precision operation }

begin

   { allocate single register for left }
   regexp(rgnull, rgnull, ip^.left, tr);
   ip^.lreg := ip^.left^.freg; { place left from result }
   ip^.lregx := ip^.left^.fregx;
   { check left side needs to be expanded }
   if quad and (ip^.left^.rbase^.size <= regsiz) then begin

      getreg(ip^.lregx, ip, tr); { get high half register }
      remcxt(ip^.lregx) { clear from context }

   end

end;

{

Do standard right side allocation

Given an operator node, a standard no-preference register allocation is done on
the right side. If a quad operation is specified, and the right side is not
already a quad operand, an extended register is also allocated.

}

procedure doright(ip: intptr; { intermediate to process }
                 quad: boolean); { quad/single precision operation }

begin

   { allocate single register for right }
   regexp(rgnull, rgnull, ip^.right, tr);
   ip^.rreg := ip^.right^.freg; { place right from result }
   ip^.rregx := ip^.right^.fregx;
   { check right side needs to be expanded }
   if quad and (ip^.right^.rbase^.size <= regsiz) then begin

      getreg(ip^.rregx, ip, tr); { get high half register }
      remcxt(ip^.rregx) { clear from context }

   end

end;

{ Do standard left and right allocate with "bridging". This makes any
  suboperator, no matter how deep, appear to be allocated as a branch of
  the current operator. Used to defacto move where subtrees are rooted. }

procedure dobothb(sip: intptr);

begin

   { copy allocations down to suboperator }
   sip^.alc := ip^.alc;
   sip^.push := ip^.push;
   regexp(rgnull, rgnull, sip^.left, tr); { alocate }
   sip^.lreg := sip^.left^.freg; { place left from result }
   sip^.lregx := sip^.left^.fregx;
   regexp(rgnull, rgnull, sip^.right, tr); { alocate }
   sip^.rreg := sip^.right^.freg; { place right from result }
   sip^.rregx := sip^.right^.fregx;
   { copy allocations back to main operator }
   ip^.alc := sip^.alc;
   ip^.push := sip^.push

end;

{ do standard left allocate with bridging }

procedure doleftb(sip: intptr);

begin

   { copy allocations down to suboperator }
   sip^.alc := ip^.alc;
   sip^.push := ip^.push;
   regexp(rgnull, rgnull, sip^.left, tr); { alocate }
   sip^.lreg := sip^.left^.freg; { place right from result }
   sip^.lregx := sip^.left^.fregx;
   { copy allocations back to main operator }
   ip^.alc := sip^.alc;
   ip^.push := sip^.push

end;

{ do standard right allocate with bridging }

procedure dorightb(sip: intptr);

begin

   { copy allocations down to suboperator }
   sip^.alc := ip^.alc;
   sip^.push := ip^.push;
   regexp(rgnull, rgnull, sip^.right, tr); { alocate }
   sip^.rreg := sip^.right^.freg; { place right from result }
   sip^.rregx := sip^.right^.fregx;
   { copy allocations back to main operator }
   ip^.alc := sip^.alc;
   ip^.push := sip^.push

end;

{ allocate temp for operand }

procedure gettmpreg(quad: boolean);

begin

   getreg(ip^.t1reg, ip, tr); { get sequence register }
   remcxt(ip^.t1reg); { clear }
   if quad then begin { double }

      getreg(ip^.t1regx, ip, tr); { get sequence register }
      remcxt(ip^.t1regx) { clear }

   end

end;

{ allocate registers for multiply immediate }

procedure domltimm(ip: intptr;     { operator to generate for }
                   quad: boolean); { quad/single precision operation }

var ti:   ssint;
    shft: 0..31;   { shift count }

begin

   { if it is a multiply, special immediate rules are invoked }
   ti.v := consti(ip^.base); { get constant }
   ti.s := constis(ip^.base);
   { First, reject the *0 and *1 case, which are clear and nop
     respectively. }
   if ssnequ(ti, false, 0) and ssnequ(ti, false, 1) then begin

      shft := pow2(ti); { find if shift power exists }
      if (shft <> 0) and not fovfchk then begin

         if quad then begin { double, must provide counter register }

            getreg(ip^.t1reg, ip, tr); { get sequence register }
            remcxt(ip^.t1reg) { clear }

         end

      end else begin { no shift }

         { check can use power series multiply }
         if not ti.s and ssleq(ti, false, maxmlt) and fspeed and
            not fovfchk then gettmpreg(quad) { needs a temp }
         else begin { conventional multiply with immediate }

            if quad then begin { must use external routine }

               { get fixed temp for immediate load }
               plcreg(rgecx, ip, tr); { get low half }
               remcxt(rgecx);
               ip^.t1reg := rgecx;
               plcreg(rgedx, ip, tr); { get high half }
               remcxt(rgedx);
               ip^.t1regx := rgedx

            end else if not signed then
               { Unsigned multiply has no immediate mode, so a temp must
                 be allocated to load the immediate. }
               gettmpreg(quad); { get a temp to load the immediate to }

         end

      end

   end

end;

{ process right target of gendoi for indirect load cases }

procedure dogendoildir(signed: boolean; { operation is signed }
                       sgnchk: boolean; { perform sign check }
                       quad:   boolean; { operation is quad precision }
                       ip:     intptr); { operator node }

var siz:  integer; { size of operand }
    shft: 0..31;   { shift count }
    ti:   ssint;

begin

   if ip^.right^.i = tiarrref then begin { its an array reference }

      if ip^.right^.base^.t <> tarray then error(einvfmt);
      i := ip^.right^.base^.arrt^.size; { get base type size }
      if i in [1, 2, 4, 8] then begin { proper base size }

         { check constant address }
         if ip^.right^.left^.i = tilodadr then begin

            { check not extended parameter }
            if not chkext(ip^.right^.left^.base) then begin

               dorightb(ip^.right); { allocate index }
               { check will need a display or 'with' temp register }
               if (ip^.right^.left^.base^.t = tfield) or
                  (ip^.right^.left^.base^.t = tftag) or
                  ip^.right^.left^.base^.local then begin

                     getreg(ip^.t1reg, ip, tr); { get display register }
                     remcxt(ip^.t1reg) { clear it }

               end

            end else
               { allocate array access components }
               dobothb(ip^.right)

         end else
            { allocate array access components }
            dobothb(ip^.right)

      end else doright(ip, quad) { process address }

   end else doright(ip, quad) { process address }

end;

{ process right target of gendoi }

procedure dogendoir(signed: boolean; { operation is signed }
                    sgnchk: boolean; { perform sign check }
                    quad:   boolean; { operation is quad precision }
                    ip:     intptr); { operator node }

var siz:  integer; { size of operand }
    shft: 0..31;   { shift count }
    ti:   ssint;

begin

   if (ip^.i = timltint) and quad then begin { allocate for routine call }

      if ip^.right^.rbase^.size <= regsiz then { single }
         regexp(rgecx, rgnull, ip^.right, tr)
      else { double }
         regexp(rgecx, rgedx, ip^.right, tr);
      ip^.rreg := ip^.right^.freg; { place right from result }
      ip^.rregx := ip^.right^.fregx; { place right from result }
      { check right side needs to be expanded }
      if quad and (ip^.right^.rbase^.size <= regsiz) then begin

         plcreg(rgedx, ip, tr); { get high half register }
         remcxt(rgedx); { clear from context }
         ip^.rregx := rgedx { set }

      end

   end else doright(ip, quad) { process standard right }

end; { dogendoir }

{ process targets of gendoi }

procedure dogendoi(ip: intptr);

var signed: boolean; { operation is signed }
    sgnchk: boolean; { operand(s) need to be checked for sign }
    quad:   boolean; { operation is quad precision }

begin

   { find signed or unsigned status of operation }
   signed := chksgn(ip^.left^.rbase) or chksgn(ip^.right^.rbase);
   { find if either operand needs to be checked for sign }
   sgnchk := chksgn(ip^.left^.rbase) <> chksgn(ip^.right^.rbase);
   { find if operation must be performed in quad precision math }
   quad := (ip^.left^.rbase^.size > regsiz) or
             (ip^.right^.rbase^.size > regsiz);
   { allocate left side }
   doleft(ip, quad); { allocate any left }
   dogendoir(signed, sgnchk, quad, ip) { allocate right }

end; { dogendoi }

{ get temps for operator }

procedure gettreg;

begin

   getreg(ip^.t1reg, ip, tr); { get adder register }
   remcxt(ip^.t1reg); { clear }
   if quad then begin { get high register }

      getreg(ip^.t1regx, ip, tr); { get adder register }
      remcxt(ip^.t1regx) { clear }

   end

end;

begin { regexp }

   regdiag(ip, true); { output diagnostic }
   { we do a case here because of the 256 element set limit }
   if ip^.up = nil then error(esysflt131); { must have valid up link }
   ip^.alc := ip^.up^.alc; { copy parent to current register allocation }
   rcn := regtrk; { save current register context }
   case ip^.i of { intermediate }

      tifnccal, tifnccalo, tifnccali: begin

         { To make sure there is nothing in the return register, we allocate,
           then release it. It must be clear to process in paramters, since
           all registers are valid for input. }
         plcreg(rgeax, ip, tr);
         if ip^.base^.t = tfunc then begin

            { standard function }
            frp := ip^.base^.fncr; { set result type pointer }
            if frp^.t <> tfuncr then error(esysflt121);
            if tgpt(frp^.fnrt) then plcreg(rgebx, ip, tr);

         end else begin

            { parameter function }
            if ip^.base^.t <> tpfunc then error(esysflt122);
            frp := ip^.base^.pfnr; { set result type pointer }
            if frp^.t <> tfuncr then error(esysflt123);
            if tgpt(frp^.fnrt) then plcreg(rgebx, ip, tr);

         end;
         ip^.alc := ip^.alc-[rgeax]; { remove }
         if tgpt(frp^.fnrt) then ip^.alc := ip^.alc-[rgebx];
         pfpar(ip, tr); { process parameters }

         { process result }

         if not realt(frp) then begin { result must have register }

            { result to eax, but not officially allocated }
            ip^.rsreg := rgeax;
            remcxt(ip^.rsreg); { clear result }
            if tgpt(frp^.fnrt) then begin { place length reg }

               { result to ebx, but not officially allocated }
               ip^.rsregx := rgebx;
               remcxt(ip^.rsregx) { clear result }

            end;
            remcxt(ip^.rsreg); { clear result context }
            remcxt(ip^.rsregx);
            prcres(rr, rrx, ip, tr); { process result }
            remcxt(ip^.freg); { clear result }
            remcxt(ip^.fregx)

         end;
         clrcxt { clear context out after call }

      end;
      ticalpar: begin

         { Pass on the register request from above. Note that procedure/function
           parameters don't pass on the extra register, because that is used at
           call time. }
         if tgpt(ip^.base) or (ip^.base^.size > regsiz) then
            regexp(rr, rrx, ip^.left, tr) { get left }
         else regexp(rr, rgnull, ip^.left, tr); { get left }
         ip^.lreg := ip^.left^.freg; { place left from result }
         ip^.lregx := ip^.left^.fregx;
         { check parameter is qword extention of dword register, and is not a
           procedure or function parameter }
         if (ip^.left^.base^.size <= regsiz) and
            (ip^.base^.size > regsiz) and
            (ip^.base^.t <> tpproc) and
            (ip^.base^.t <> tpfunc) then begin

            getreg(ip^.lregx, ip, tr); { get high half register }
            remcxt(ip^.lregx) { clear from context }

         end;
         ip^.rsreg := ip^.lreg; { place result from left }
         ip^.rsregx := ip^.lregx;
         if not realt(ip^.left^.rbase) then { not real }
            prcres(rr, rrx, ip, tr); { get transfer register(s) }
         { copy context to new registers }
         cpycxtp(ip^.freg, ip^.fregx, ip^.rsreg, ip^.rsregx)

      end;
      tieolt, tieof, tiloc, tilen: begin

         regexp(rgeax, rgnull, ip^.left, tr); { allocate file }
         ip^.lreg := ip^.left^.freg; { place left from result }
         ip^.rsreg := rgeax; { result must be eax }
         remcxt(ip^.rsreg); { clear result context }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg); { clear transfer }
         clrcxt { clear context after external call }

      end;
      tilodafbuf, tilodafbuft: begin

         regexp(rgeax, rgnull, ip^.left, tr); { allocate file }
         ip^.lreg := ip^.left^.freg; { place left from result }
         plcreg(rgebx, ip, tr); { allocate ebx to return length }
         remcxt(rgebx); { clear that }
         ip^.rsreg := rgeax; { result must be eax }
         remcxt(ip^.rsreg); { clear result context }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg); { clear transfer }
         clrcxt { clear context after external call }

      end;
      tiexist: begin

         regexp(rgeax, rgebx, ip^.left, tr); { allocate string }
         ip^.lreg := ip^.left^.freg; { place left from result }
         ip^.lregx := ip^.left^.fregx; { place left from result }
         ip^.rsreg := rgeax; { result must be eax }
         remcxt(ip^.rsreg); { clear result context }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg); { clear transfer }
         clrcxt { clear context after external call }

      end;
      tilodset, tilodsrc: begin

         plcreg(rgesi, ip, tr); { allocate esi for source }
         remcxt(rgesi); { clear that }
         plcreg(rgedi, ip, tr); { allocate edi for destination }
         remcxt(rgedi); { clear that }
         plcreg(rgecx, ip, tr); { allocate ecx for count }
         remcxt(rgecx); { clear that }
         prfreg(ip^.rsreg, rr, ip, tr); { get result }
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear transfer }

      end;
      tilimns: begin

         plcreg(rgedi, ip, tr); { allocate edi for destination }
         remcxt(rgedi); { clear that }
         plcreg(rgecx, ip, tr); { allocate ecx for count }
         remcxt(rgecx); { clear that }
         plcreg(rgeax, ip, tr); { allocate ecx for zero }
         remcxt(rgeax); { clear that }
         prfreg(ip^.rsreg, rr, ip, tr); { get result }
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear transfer }

      end;
      tilodrel, tilodsrl, tilimrel: begin

         getreg(ip^.t1reg, ip, tr); { get register for display or with }
         remcxt(ip^.t1reg) { clear }

      end;
      tilodint, tilodchr, tilodbol, tilodptr: begin

         if pfpt(ip^.base) or
            ((ip^.i = tilodint) and
             ((ip^.base^.size = lntsiz) or (ip^.base^.size = lcrsiz))) then
            begin { load procedure/function address }

            { We handle procedure/function loads and doubles differently because
              they  don't fit into the context system. }
            prfreg(ip^.rsreg, rr, ip, tr); { get address result }
            remcxt(ip^.rsreg); { clear }
            prfreg(ip^.rsregx, rrx, ip, tr); { get length result }
            remcxt(ip^.rsregx); { clear }
            prcres(rr, rrx, ip, tr); { get transfer register }
            remcxt(ip^.freg); { clear result }
            remcxt(ip^.fregx)

         end else begin

            r := fndcxt(ip^.base); { check previously loaded }
            { use previously loaded context register if it exists }
            if r <> rgnull then begin { previous context exists }

               ip^.rsreg := r; { set register }
               ip^.skip := true { set to skip load }

            end else begin

              if rr <> rgflg then { value }
                 prfreg(ip^.rsreg, rr, ip, tr) { get result }
              else begin { flag }

                 ip^.rsreg := rgflg; { set flag }
                 ip^.rsflg := flnz; { set not zero true }
                 getreg(ip^.t1reg, ip, tr); { get display register }
                 remcxt(ip^.t1reg) { clear }

              end;
              setcxt(ip^.rsreg, ip^.base) { set context for result }

            end;
            prcres(rr, rrx, ip, tr); { get transfer register }
            setcxt(ip^.freg, ip^.base) { set context for transfer }

         end

      end;
      tilodadr, tilimint, tilodfadr: begin

         prfreg(ip^.rsreg, rr, ip, tr); { get result }
         remcxt(ip^.rsreg); { clear result }
         { check addressing a procedure or function }
         if (ip^.base^.t = tproc) or (ip^.base^.t = tfunc) then begin

            prfreg(ip^.rsregx, rrx, ip, tr); { get length result }
            remcxt(ip^.rsregx) { clear }

         end;
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg); { clear transfer }
         { check addressing a procedure or function }
         if (ip^.base^.t = tproc) or (ip^.base^.t = tfunc) then
            remcxt(ip^.fregx) { clear extra as well }

      end;
      tidivint, timodint: begin

         { find signed or unsigned status of operation }
         signed := chksgn(ip^.left^.rbase) or chksgn(ip^.right^.rbase);
         { find if operation must be performed in quad precision math }
         quad := (ip^.left^.rbase^.size > regsiz) or
                   (ip^.right^.rbase^.size > regsiz);
         { If divisor is a power of two, any register will do for left,
           otherwise we need eax. }
         f := false; { set not found }
         if ip^.right^.i = tilimint then begin

            ti.v := consti(ip^.right^.base); { get constant }
            ti.s := constis(ip^.right^.base);
            f := pow2(ti) <> 0

         end;
         { check right immediate, is a power of 2 shift, and is positive }
         if f and ssgeq(ti, false, 0) then begin { constant divide }

            if quad then begin { quad precision }

               getreg(ip^.t1reg, ip, tr); { reserve loop register }
               remcxt(ip^.t1reg); { clear }
               if signed then begin

                  { signed needs sign correction register }
                  getreg(ip^.t2reg, ip, tr); { reserve process register }
                  remcxt(ip^.t2reg); { clear }

               end

            end else { single precision }
               if signed then begin { signed needs correction register }

                  getreg(ip^.t1reg, ip, tr); { reserve process register }
                  remcxt(ip^.t1reg); { clear }

               end;
            regexp(rgnull, rgnull, ip^.left, tr); { allocate left }
            ip^.lreg := ip^.left^.freg; { place left from result }
            ip^.lregx := ip^.left^.fregx;
            ip^.rsreg := ip^.lreg; { set result to same }
            ip^.rsregx := ip^.lregx { set result to same }

         end else begin { other divide }

            if quad then begin { quad precision }

               regexp(rgeax, rgebx, ip^.left, tr); { allocate left }
               ip^.lreg := ip^.left^.freg; { place left from result }
               ip^.lregx := ip^.left^.fregx;
               regexp(rgecx, rgedx, ip^.right, tr); { allocate right }
               ip^.rreg := ip^.right^.freg; { place right from result }
               ip^.rregx := ip^.right^.fregx;
               ip^.rsreg := ip^.lreg; { set result to same }
               ip^.rsregx := ip^.lregx

            end else begin { single precision }

               plcreg(rgedx, ip, tr); { reserve high quotient }
               remcxt(rgedx); { clear }
               regexp(rgeax, rgnull, ip^.left, tr); { allocate left }
               ip^.lreg := ip^.left^.freg; { place left from result }
               regexp(rgnull, rgnull, ip^.right, tr); { allocate right }
               ip^.rreg := ip^.right^.freg; { place right from result }
               if ip^.i = tidivint then begin

                  ip^.rsreg := rgeax; { set result divide }
                  remcxt(rgedx) { other register is distroyed }

               end else begin

                  ip^.rsreg := rgedx; { set result mod }
                  remcxt(rgeax) { other register is distoryed }

               end

            end

         end;
         remcxt(ip^.rsreg); { clear result }
         remcxt(ip^.rsregx);
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear transfer }

      end;
      tiintset, tiuniset, tidifset: begin

         { allocate left }
         regexp(rgnull, rgnull, ip^.left, tr);
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgnull, rgnull, ip^.right, tr); { allocate right }
         ip^.rreg := ip^.right^.freg; { place right from result }
         getreg(ip^.t1reg, ip, tr); { get count register }
         remcxt(ip^.t1reg); { clear }
         getreg(ip^.t2reg, ip, tr); { get an accumulator }
         remcxt(ip^.t2reg); { clear }
         ip^.rsreg := ip^.lreg; { and result is same as left }
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg); { clear transfer }
         remcxt(ip^.lreg); { left gets distroyed }
         remcxt(ip^.rreg) { right gets distroyed }

      end;
      tildiset, tildisrc: begin

         regexp(rgesi, rgnull, ip^.left, tr); { allocate left }
         ip^.lreg := ip^.left^.freg; { place left from result }
         plcreg(rgedi, ip, tr); { allocate destination pointer }
         remcxt(rgedi); { clear }
         plcreg(rgecx, ip, tr); { allocate counter }
         remcxt(rgecx); { clear }
         prfreg(ip^.rsreg, rr, ip, tr); { get result }
         remcxt(ip^.rsreg); { clear }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg); { clear }
         remcxt(ip^.lreg) { left gets distroyed }

      end;
      tilodtgp: begin

         prfreg(ip^.rsreg, rr, ip, tr); { get address result }
         remcxt(ip^.rsreg); { clear }
         prfreg(ip^.rsregx, rrx, ip, tr); { get length result }
         remcxt(ip^.rsregx); { clear }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg); { clear result }
         remcxt(ip^.fregx)

      end;
      ticvtntg: begin

         regexp(rgnull, rgnull, ip^.left, tr); { allocate left }
         ip^.lreg := ip^.left^.freg; { place left from result }
         ip^.rsreg := ip^.lreg; { and result is same as left }
         remcxt(ip^.rsreg); { clear result }
         prfreg(ip^.rsregx, rrx, ip, tr); { get length result }
         remcxt(ip^.rsregx); { clear }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg); { clear result }
         remcxt(ip^.fregx)

      end;
      tildirel,
      tildisrl: begin

         regexp(rgnull, rgnull, ip^.left, tr); { allocate address }
         ip^.lreg := ip^.left^.freg { place left }

      end;
      tildiint, tildichr, tildibol, tildiptr: begin

         { check if a pointer is being indirected, and we are to check }
         ptrind := chkptl(ip^.left);
         if (ip^.left^.i = tiarrref) and not ptrind then
            begin { its an array reference, and not checking pointer deref }

            if ip^.left^.base^.t <> tarray then error(einvfmt);
            i := ip^.left^.base^.arrt^.size; { get base type size }
            if i in [1, 2, 4, 8] then begin { proper base size }

               { check constant address }
               if ip^.left^.left^.i = tilodadr then begin

                  { check extended parameter }
                  if not chkext(ip^.left^.left^.base) then
                     dorightb(ip^.left) { allocate index }
                  else
                     { allocate array access components }
                     dobothb(ip^.left)

               end else
                  { allocate array access components }
                  dobothb(ip^.left);
               { since index is always evaluated, we use that register for the
                 result }
               ip^.lreg := ip^.left^.rreg; { place result }
               if i = qwdsiz then begin

                  { quad precision, allocate high register }
                  prfreg(ip^.lregx, rrx, ip, tr); { get high half register }
                  remcxt(ip^.lregx) { clear from context }

               end;
               getreg(ip^.t1reg, ip, tr) { get display register }

            end else begin

               regexp(rgnull, rgnull, ip^.left, tr); { allocate operand }
               ip^.lreg := ip^.left^.freg; { place left from result }

               { check quad precision }
               if ip^.i = tildiint then { load indirect integer }
                  if ip^.base^.size > regsiz then begin

                  prfreg(ip^.lregx, rrx, ip, tr); { but add a length }
                  remcxt(ip^.lregx) { clear }

               end

            end

         end else begin { default }

            regexp(rgnull, rgnull, ip^.left, tr); { allocate operand }
            ip^.lreg := ip^.left^.freg; { place left from result }
            { check quad precision }
            if ip^.i = tildiint then { load indirect integer }
               if ip^.base^.size > regsiz then begin

               prfreg(ip^.lregx, rrx, ip, tr); { but add a length }
               remcxt(ip^.lregx) { clear }

            end

         end;
         if rr <> rgflg then begin

            ip^.rsreg := ip^.lreg; { and result is same as left }
            ip^.rsregx := ip^.lregx

         end else begin { set up flag result }

            ip^.rsreg := rgflg; { set flag }
            ip^.rsflg := flnz { set not zero true }

         end;
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear }

      end;
      tinotint, tinotbol: begin

         { check operand is a natural conditional, and deliver to a flag
           if so }
         if (ip^.left^.i = tiequrel) or (ip^.left^.i = tineqrel) or
            (ip^.left^.i = tileqrel) or (ip^.left^.i = tigeqrel) or
            (ip^.left^.i = tiltnrel) or (ip^.left^.i = tigtnrel) or
            (ip^.left^.i = tiequset) or (ip^.left^.i = tineqset) or
            (ip^.left^.i = tileqset) or (ip^.left^.i = tigeqset) or
            (ip^.left^.i = tiequgst) or (ip^.left^.i = tineqgst) or
            (ip^.left^.i = tigeqgst) or (ip^.left^.i = tiltngst) or
            (ip^.left^.i = tigtngst) or (ip^.left^.i = tiequtgp) or
            (ip^.left^.i = tineqtgp) or (ip^.left^.i = tiequint) or
            (ip^.left^.i = tineqint) or (ip^.left^.i = tiltnint) or
            (ip^.left^.i = tigtnint) or (ip^.left^.i = tileqint) or
            (ip^.left^.i = tigeqint) or (ip^.left^.i = tiequstr) or
            (ip^.left^.i = tineqstr) or (ip^.left^.i = tileqstr) or
            (ip^.left^.i = tigeqstr) or (ip^.left^.i = tiltnstr) or
            (ip^.left^.i = tigtnstr) or (ip^.left^.i = tiincset) or
            (ip^.left^.i = tileqgst) then
            regexp(rgflg, rgnull, ip^.left, tr) { allocate operand }
         else regexp(rgnull, rgnull, ip^.left, tr); { allocate operand }
         ip^.lreg := ip^.left^.freg; { place left from result }
         ip^.lregx := ip^.left^.fregx;
         ip^.lflg := ip^.left^.fflg;
         ip^.rsreg := ip^.lreg; { and result is same as left }
         ip^.rsregx := ip^.lregx;
         ip^.rsflg := ip^.lflg;
         if ip^.lreg = rgflg then
            { we are inverting a flag result, invert the condition }
            ip^.rsflg := flginv(ip^.lflg);
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear }

      end;
      tilodlen: begin

         regexp(rgnull, rgnull, ip^.left, tr); { allocate operand }
         ip^.lreg := ip^.left^.freg; { place left from result }
         ip^.lregx := ip^.left^.fregx;
         ip^.rsreg := ip^.lregx; { place result from left length }
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear }

      end;
      ticvtgtf: begin

         regexp(rgnull, rgnull, ip^.left, tr); { allocate operand }
         ip^.lreg := ip^.left^.freg; { place left from result }
         ip^.lregx := ip^.left^.fregx;
         ip^.rsreg := ip^.lreg; { return address }
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear }

      end;
      tinegint, tiabsint, tiodd, tisucint, tiprdint, tirngchk: begin

         regexp(rgnull, rgnull, ip^.left, tr); { allocate operand }
         ip^.lreg := ip^.left^.freg; { place left from result }
         ip^.rsreg := ip^.lreg; { and result is same as left }
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear }

      end;
      tisqrint: begin

         regexp(rgeax, rgnull, ip^.left, tr); { allocate operand }
         ip^.lreg := ip^.left^.freg; { place left from result }
         ip^.rsreg := ip^.lreg; { and result is same as left }
         remcxt(ip^.rsreg); { clear result }
         plcreg(rgedx, ip, tr); { allocate high part of result }
         remcxt(rgedx); { clear }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear }

      end;
      tilditgp, ticvtftg: begin

         regexp(rgnull, rgnull, ip^.left, tr); { allocate operand }
         ip^.lreg := ip^.left^.freg; { place left from result }
         ip^.rsreg := ip^.lreg; { and result is same as left }
         remcxt(ip^.rsreg); { clear result }
         prfreg(ip^.rsregx, rr, ip, tr); { but add a length }
         remcxt(ip^.rsregx); { clear }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear }

      end;
      tiarfgar: begin

         regexp(rgnull, rgnull, ip^.left, tr); { allocate operand }
         ip^.lreg := ip^.left^.freg; { place left from result }
         ip^.lregx := ip^.left^.fregx;
         regexp(rgnull, rgnull, ip^.right, tr); { allocate operand }
         ip^.rreg := ip^.right^.freg; { place right from result }
         ip^.rregx := ip^.right^.fregx;
         { determine if we need an adder register }
         if ip^.base^.t <> tgarry then error(einvfmt);
         ti.v := ip^.base^.gart^.size; { get array element size }
         ti.s := false;
         if not (ti.v in [1, 2, 4, 8]) and (pow2(ti) = 0) and (i <= maxmlt) and
            fspeed then begin

            getreg(ip^.t1reg, ip, tr); { get adder register }
            remcxt(ip^.t1reg) { clear }

         end;
         ip^.rsreg := ip^.lreg; { and result is same as left }
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg); { clear }
         remcxt(ip^.lreg); { left distroyed }
         remcxt(ip^.rreg) { right distroyed }

      end;
      timltint: begin

         { find signed or unsigned status of operation }
         signed := chksgn(ip^.left^.rbase) or chksgn(ip^.right^.rbase);
         { find if either operand needs to be checked for sign }
         sgnchk := chksgn(ip^.left^.rbase) <> chksgn(ip^.right^.rbase);
         { find if operation must be performed in quad precision math }
         quad := (ip^.left^.rbase^.size > regsiz) or
                   (ip^.right^.rbase^.size > regsiz);
         if signed then begin

            { Signed operation, these are allocated to any right and left
              register combination. }
            dogendoi(ip);
            ip^.rsreg := ip^.lreg; { result is same as left }
            ip^.rsregx := ip^.lregx

         end else begin

            { Unsigned, the left side must be in eax, with edx being
              destroyed. }
            if not quad then begin { not double }

               plcreg(rgedx, ip, tr); { reserve high result }
               remcxt(rgedx) { clear }

            end;
            { allocate left }
            if ip^.left^.rbase^.size <= regsiz then { single }
               regexp(rgeax, rgnull, ip^.left, tr)
            else { double }
               regexp(rgeax, rgebx, ip^.left, tr);
            ip^.lreg := ip^.left^.freg; { place left from result }
            ip^.lregx := ip^.left^.fregx;
            { check left side needs to be expanded }
            if quad and (ip^.left^.rbase^.size <= regsiz) then begin

               plcreg(rgebx, ip, tr); { get high half register }
               remcxt(rgebx); { clear from context }
               ip^.lregx := rgebx { set }

            end;
            { allocate right }
            dogendoir(signed, sgnchk, quad, ip);
            ip^.rsreg := rgeax; { set result of multiply }
            if quad then ip^.rsregx := rgebx;
            remcxt(rgedx) { top register is distroyed }

         end;
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear }

      end;
      timltintimm: begin

         { find signed or unsigned status of operation }
         signed := chksgn(ip^.left^.rbase) or constis(ip^.base);
         { find if either operand needs to be checked for sign }
         sgnchk := chksgn(ip^.left^.rbase) <> constis(ip^.base);
         { find if operation must be performed in quad precision math }
         quad := (ip^.left^.rbase^.size > regsiz) or (ip^.base^.size > regsiz);
         if signed then begin

            { Signed operation, these are allocated to any right and left
              register combination. }
            if quad then begin { allocate for routine call }

               if ip^.left^.rbase^.size <= regsiz then { single }
                  regexp(rgeax, rgnull, ip^.left, tr)
               else { double }
                  regexp(rgeax, rgebx, ip^.left, tr);
               ip^.lreg := ip^.left^.freg; { place left from result }
               ip^.lregx := ip^.left^.fregx;
               { check left side needs to be expanded }
               if quad and (ip^.left^.rbase^.size <= regsiz) then begin

                  plcreg(rgebx, ip, tr); { get high half register }
                  remcxt(rgebx); { clear from context }
                  ip^.lregx := rgebx { set }

               end

            end else doleft(ip, quad); { allocate any left }
            { allocate right }
            domltimm(ip, quad); { allocate for multiply immediate }
            ip^.rsreg := ip^.lreg; { result is same as left }
            ip^.rsregx := ip^.lregx

         end else begin

            { Unsigned, the left side must be in eax, with edx being
              destroyed. }
            if not quad then begin { not double }

               plcreg(rgedx, ip, tr); { reserve high result }
               remcxt(rgedx) { clear }

            end;
            { allocate left }
            if ip^.left^.rbase^.size <= regsiz then { single }
               regexp(rgeax, rgnull, ip^.left, tr)
            else { double }
               regexp(rgeax, rgebx, ip^.left, tr);
            ip^.lreg := ip^.left^.freg; { place left from result }
            ip^.lregx := ip^.left^.fregx;
            { check left side needs to be expanded }
            if quad and (ip^.left^.rbase^.size <= regsiz) then begin

               plcreg(rgebx, ip, tr); { get high half register }
               remcxt(rgebx); { clear from context }
               ip^.lregx := rgebx { set }

            end;
            { allocate right }
            domltimm(ip, quad); { allocate for multiply immediate }
            ip^.rsreg := rgeax; { set result of multiply }
            if quad then ip^.rsregx := rgebx;
            remcxt(rgedx) { top register is distroyed }

         end;
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear }

      end;
      timltintlod: begin

         { find signed or unsigned status of operation }
         signed := chksgn(ip^.left^.rbase) or chksgn(ip^.base);
         { find if either operand needs to be checked for sign }
         sgnchk := chksgn(ip^.left^.rbase) <> chksgn(ip^.base);
         { find if operation must be performed in quad precision math }
         quad := (ip^.left^.rbase^.size > regsiz) or (ip^.base^.size > regsiz);
         if signed then begin

            { Signed operation, these are allocated to any right and left
              register combination. }
            doleft(ip, quad); { allocate any left }
            getreg(ip^.t1reg, ip, tr); { get display temp }
            remcxt(ip^.t1reg); { clear }
            ip^.rsreg := ip^.lreg; { result is same as left }
            ip^.rsregx := ip^.lregx

         end else begin

            { Unsigned, the left side must be in eax, with edx being
              destroyed. }
            if not quad then begin { not double }

               plcreg(rgedx, ip, tr); { reserve high result }
               remcxt(rgedx) { clear }

            end;
            { allocate left }
            if ip^.left^.rbase^.size <= regsiz then { single }
               regexp(rgeax, rgnull, ip^.left, tr)
            else { double }
               regexp(rgeax, rgebx, ip^.left, tr);
            ip^.lreg := ip^.left^.freg; { place left from result }
            ip^.lregx := ip^.left^.fregx;
            { check left side needs to be expanded }
            if quad and (ip^.left^.rbase^.size <= regsiz) then begin

               plcreg(rgebx, ip, tr); { get high half register }
               remcxt(rgebx); { clear from context }
               ip^.lregx := rgebx { set }

            end;
            { allocate right }
            getreg(ip^.t1reg, ip, tr); { get display temp }
            remcxt(ip^.t1reg); { clear }
            ip^.rsreg := rgeax; { set result of multiply }
            if quad then ip^.rsregx := rgebx;
            remcxt(rgedx) { top register is distroyed }

         end;
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear }

      end;
      timltintldi: begin

         { find signed or unsigned status of operation }
         signed := chksgn(ip^.left^.rbase) or chksgn(ip^.right^.rbase);
         { find if either operand needs to be checked for sign }
         sgnchk := chksgn(ip^.left^.rbase) <> chksgn(ip^.right^.rbase);
         { find if operation must be performed in quad precision math }
         quad := (ip^.left^.rbase^.size > regsiz) or
                   (ip^.right^.rbase^.size > regsiz);
         if signed then begin

            { Signed operation, these are allocated to any right and left
              register combination. }
            doleft(ip, quad); { allocate any left }
            dogendoildir(signed, sgnchk, quad, ip); { allocate right }
            ip^.rsreg := ip^.lreg; { result is same as left }
            ip^.rsregx := ip^.lregx

         end else begin

            { Unsigned, the left side must be in eax, with edx being
              destroyed. }
            if not quad then begin { not double }

               plcreg(rgedx, ip, tr); { reserve high result }
               remcxt(rgedx) { clear }

            end;
            { allocate left }
            if ip^.left^.rbase^.size <= regsiz then { single }
               regexp(rgeax, rgnull, ip^.left, tr)
            else { double }
               regexp(rgeax, rgebx, ip^.left, tr);
            ip^.lreg := ip^.left^.freg; { place left from result }
            ip^.lregx := ip^.left^.fregx;
            { check left side needs to be expanded }
            if quad and (ip^.left^.rbase^.size <= regsiz) then begin

               plcreg(rgebx, ip, tr); { get high half register }
               remcxt(rgebx); { clear from context }
               ip^.lregx := rgebx { set }

            end;
            { allocate right }
            dogendoildir(signed, sgnchk, quad, ip);
            ip^.rsreg := rgeax; { set result of multiply }
            if quad then ip^.rsregx := rgebx;
            remcxt(rgedx) { top register is distroyed }

         end;
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear }

      end;
      tiaddint, tisubint, tiandint, tiorint, tixorint: begin

         dogendoi(ip);
         ip^.rsreg := ip^.lreg; { result is same as left }
         ip^.rsregx := ip^.lregx;
         remcxt(ip^.rsreg); { clear result context }
         remcxt(ip^.rsregx);
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg); { clear final context }
         remcxt(ip^.fregx)

      end;
      tiaddintimm, tisubintimm, tiandintimm, tiorintimm, tixorintimm: begin

         { find if operation must be performed in quad precision math }
         quad := (ip^.left^.rbase^.size > regsiz) or (ip^.base^.size > regsiz);
         doleft(ip, quad); { process left side allocate }
         ip^.rsreg := ip^.lreg; { result is same as left }
         ip^.rsregx := ip^.lregx;
         remcxt(ip^.rsreg); { clear result context }
         remcxt(ip^.rsregx);
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg); { clear final context }
         remcxt(ip^.fregx)

      end;
      tiaddintlod, tisubintlod, tiandintlod, tiorintlod, tixorintlod: begin

         { find if operation must be performed in quad precision math }
         quad := (ip^.left^.rbase^.size > regsiz) or (ip^.base^.size > regsiz);
         { allocate left side }
         doleft(ip, quad); { allocate any left }
         getreg(ip^.t1reg, ip, tr); { get display temp }
         remcxt(ip^.t1reg); { clear }
         ip^.rsreg := ip^.lreg; { result is same as left }
         ip^.rsregx := ip^.lregx;
         remcxt(ip^.rsreg); { clear result context }
         remcxt(ip^.rsregx);
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg); { clear final context }
         remcxt(ip^.fregx)

      end;
      tiaddintldi, tisubintldi, tiandintldi, tiorintldi, tixorintldi: begin

         { find signed or unsigned status of operation }
         signed := chksgn(ip^.left^.rbase) or chksgn(ip^.right^.rbase);
         { find if either operand needs to be checked for sign }
         sgnchk := chksgn(ip^.left^.rbase) <> chksgn(ip^.right^.rbase);
         { find if operation must be performed in quad precision math }
         quad := (ip^.left^.rbase^.size > regsiz) or
                   (ip^.right^.rbase^.size > regsiz);
         { allocate left side }
         doleft(ip, quad); { allocate any left }
         dogendoildir(signed, sgnchk, quad, ip); { allocate right }
         ip^.rsreg := ip^.lreg; { result is same as left }
         ip^.rsregx := ip^.lregx;
         remcxt(ip^.rsreg); { clear result context }
         remcxt(ip^.rsregx);
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg); { clear final context }
         remcxt(ip^.fregx)

      end;
      tisinset: begin

         regexp(rgnull, rgnull, ip^.left, tr); { allocate operand }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgnull, rgnull, ip^.right, tr); { allocate operand }
         ip^.rreg := ip^.right^.freg; { place right from result }
         ip^.rsreg := ip^.lreg; { and result is same as left }
         remcxt(ip^.rsreg); { clear result context }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear }

      end;
      tiarrref: begin

         regexp(rgnull, rgnull, ip^.left, tr); { allocate base }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgnull, rgnull, ip^.right, tr); { allocate index }
         ip^.rreg := ip^.right^.freg; { place right from result }
         ip^.rregx := ip^.right^.fregx;
         { determine if we need an adder register }
         if ip^.base^.t <> tarray then error(einvfmt);
         ti.v := ip^.base^.arrt^.size; { get array element size }
         ti.s := false;
         quad := ip^.right^.rbase^.size > regsiz; { set quadword status }
         if not (ti.v in [1, 2, 4, 8]) then begin { not scaled array reference }

            { now we allocate according to genmltir }
            if ssnequ(ti, false, 1) then begin { not 0 or 1 }

               if (pow2(ti) <> 0) and not err then begin { shift }

                  if quad then begin { count register needed }

                     getreg(ip^.t1reg, ip, tr); { get adder register }
                     remcxt(ip^.t1reg) { clear }

                  end

               end else begin

                  if not ti.s and ssleq(ti, false, maxmlt) and fspeed and
                     not err then gettreg { perform factor multiply }
                  else begin { perform conventional multiply immediate }

                     if signed then begin { perform signed version }

                        if not (sbyte(i) and not quad) then { long version }
                           if quad then gettreg { get temp for routine }

                     end else gettreg { perform unsigned version }

                  end

               end

            end

         end;
         ip^.rsreg := ip^.lreg; { and result is same as left }
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg); { clear }
         remcxt(ip^.lreg); { left is distroyed }
         remcxt(ip^.rreg) { right is distroyed }

      end;
      timltrel, tidivrel, tiaddrel, tisubrel: begin

         regexp(rgnull, rgnull, ip^.left, tr); { allocate operand }
         regexp(rgnull, rgnull, ip^.right, tr) { allocate operand }

      end;
      tiincset: begin

         regexp(rgnull, rgnull, ip^.left, tr); { allocate operand }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgnull, rgnull, ip^.right, tr); { allocate operand }
         ip^.rreg := ip^.right^.freg; { place right from result }
         plcreg(rgflg, ip, tr); { place result in flags }
         ip^.rsreg := rgflg;
         ip^.rsflg := flc; { set flag sense }
         remcxt(ip^.rsreg); { clear }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear }

      end;
      tiequrel, tineqrel, tileqrel, tigeqrel, tiltnrel, tigtnrel: begin

         plcreg(rgeax, ip, tr); { set trashes eax (flags) }
         remcxt(rgeax); { clear }
         regexp(rgnull, rgnull, ip^.left, tr); { allocate operand }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgnull, rgnull, ip^.right, tr); { allocate operand }
         ip^.rreg := ip^.right^.freg; { place right from result }
         plcreg(rgflg, ip, tr); { place result in flags }
         ip^.rsreg := rgflg;
         { set flag sense }
         case ip^.i of { compare }

            tiequrel: ip^.rsflg := fle;
            tineqrel: ip^.rsflg := flne;
            tileqrel: ip^.rsflg := flna;
            tigeqrel: ip^.rsflg := flnb;
            tiltnrel: ip^.rsflg := flb;
            tigtnrel: ip^.rsflg := fla

         end;
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear }

      end;
      tiequset, tineqset: begin

         regexp(rgesi, rgnull, ip^.left, tr); { allocate operand }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgedi, rgnull, ip^.right, tr); { allocate operand }
         ip^.rreg := ip^.right^.freg; { place right from result }
         plcreg(rgecx, ip, tr); { allocate counter }
         ip^.t1reg := rgecx;
         remcxt(rgecx); { clear }
         plcreg(rgflg, ip, tr); { place result in flags }
         ip^.rsreg := rgflg;
         remcxt(rgflg); { clear }
         { set flag sense }
         if ip^.i = tiequset then ip^.rsflg := fle
         else ip^.rsflg := flne;
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg); { clear }
         remcxt(ip^.lreg); { left gets distroyed }
         remcxt(ip^.rreg) { right gets distroyed }

      end;
      tileqset, tigeqset: begin

         regexp(rgnull, rgnull, ip^.left, tr); { allocate operand }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgnull, rgnull, ip^.right, tr); { allocate operand }
         ip^.rreg := ip^.right^.freg; { place right from result }
         getreg(ip^.t1reg, ip, tr); { allocate counter }
         remcxt(ip^.t1reg); { clear }
         getreg(ip^.t2reg, ip, tr); { allocate "and" variable }
         remcxt(ip^.t2reg); { clear }
         getreg(ip^.t3reg, ip, tr); { allocate "or" variable }
         remcxt(ip^.t3reg); { clear }
         plcreg(rgflg, ip, tr); { place result in flags }
         ip^.rsreg := rgflg;
         remcxt(rgflg); { clear }
         { set flag sense }
         ip^.rsflg := fle;
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg); { clear }
         remcxt(ip^.lreg); { left gets distroyed }
         remcxt(ip^.rreg) { right gets distroyed }

      end;
      tiequgst, tineqgst, tigeqgst, tileqgst, tiltngst, tigtngst: begin

         regexp(rgesi, rgecx, ip^.left, tr); { allocate operand }
         ip^.lreg := ip^.left^.freg; { place left from result }
         ip^.lregx := ip^.left^.fregx;
         regexp(rgedi, rgnull, ip^.right, tr); { allocate operand }
         ip^.rreg := ip^.right^.freg; { place left from result }
         ip^.rregx := ip^.right^.fregx;
         plcreg(rgflg, ip, tr); { place result in flags }
         ip^.rsreg := rgflg;
         remcxt(rgflg); { clear }
         { set flag sense }
         case ip^.i of { compare }

            tiequgst: ip^.rsflg := fle;
            tineqgst: ip^.rsflg := flne;
            tigeqgst: ip^.rsflg := flge;
            tileqgst: ip^.rsflg := flle;
            tiltngst: ip^.rsflg := fll;
            tigtngst: ip^.rsflg := flg

         end;
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg); { clear }
         { because ecx, esi and edi get modified by operation, they aren't
           valid }
         remcxt(ip^.lreg); { left gets distroyed }
         remcxt(ip^.lregx);
         remcxt(ip^.rreg) { right gets distroyed }

      end;
      tirngset: begin

         regexp(rgnull, rgnull, ip^.left, tr); { allocate operand }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgnull, rgnull, ip^.right, tr); { allocate operand }
         ip^.rreg := ip^.right^.freg; { place right from result }
         regexp(rgnull, rgnull, ip^.xtra, tr); { allocate operand }
         ip^.xreg := ip^.xtra^.freg; { place right from result }
         ip^.rsreg := ip^.lreg; { and result is same as left }
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg); { clear }
         remcxt(ip^.rreg) { right gets distroyed by operation }

      end;
      tiequtgp, tineqtgp, tiequint, tineqint: begin

         dogendoi(ip);
         ip^.rsreg := ip^.lreg; { result is same as left }
         plcreg(rgflg, ip, tr); { place result in flags }
         ip^.rsreg := rgflg;
         remcxt(rgflg); { clear }
         { set flag sense }
         if (ip^.i = tiequtgp) or (ip^.i = tiequint) then ip^.rsflg := fle
         else ip^.rsflg := flne;
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear }

      end;
      tiequtgpimm, tineqtgpimm, tiequintimm, tineqintimm: begin

         { find if operation must be performed in quad precision math }
         quad := (ip^.left^.rbase^.size > regsiz) or (ip^.base^.size > regsiz);
         doleft(ip, quad); { process left side allocate }
         ip^.rsreg := ip^.lreg; { result is same as left }
         plcreg(rgflg, ip, tr); { place result in flags }
         ip^.rsreg := rgflg;
         remcxt(rgflg); { clear }
         { set flag sense }
         if (ip^.i = tiequtgpimm) or (ip^.i = tiequintimm) then ip^.rsflg := fle
         else ip^.rsflg := flne;
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear }

      end;
      tiequtgplod, tineqtgplod, tiequintlod, tineqintlod: begin

         { find if operation must be performed in quad precision math }
         quad := (ip^.left^.rbase^.size > regsiz) or (ip^.base^.size > regsiz);
         { allocate left side }
         doleft(ip, quad); { allocate any left }
         getreg(ip^.t1reg, ip, tr); { get display temp }
         remcxt(ip^.t1reg); { clear }
         ip^.rsreg := ip^.lreg; { result is same as left }
         plcreg(rgflg, ip, tr); { place result in flags }
         ip^.rsreg := rgflg;
         remcxt(rgflg); { clear }
         { set flag sense }
         if (ip^.i = tiequtgplod) or (ip^.i = tiequintlod) then ip^.rsflg := fle
         else ip^.rsflg := flne;
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear }

      end;
      tiequtgpldi, tineqtgpldi, tiequintldi, tineqintldi: begin

         { find signed or unsigned status of operation }
         signed := chksgn(ip^.left^.rbase) or chksgn(ip^.right^.rbase);
         { find if either operand needs to be checked for sign }
         sgnchk := chksgn(ip^.left^.rbase) <> chksgn(ip^.right^.rbase);
         { find if operation must be performed in quad precision math }
         quad := (ip^.left^.rbase^.size > regsiz) or
                   (ip^.right^.rbase^.size > regsiz);
         { allocate left side }
         doleft(ip, quad); { allocate any left }
         dogendoildir(signed, sgnchk, quad, ip); { allocate right }
         ip^.rsreg := ip^.lreg; { result is same as left }
         plcreg(rgflg, ip, tr); { place result in flags }
         ip^.rsreg := rgflg;
         remcxt(rgflg); { clear }
         { set flag sense }
         if (ip^.i = tiequtgpldi) or (ip^.i = tiequintldi) then ip^.rsflg := fle
         else ip^.rsflg := flne;
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear }

      end;
      tiltnint, tigtnint, tileqint, tigeqint: begin

         { find signed or unsigned status of operation }
         signed := chksgn(ip^.left^.rbase) or chksgn(ip^.right^.rbase);
         dogendoi(ip);
         ip^.rsreg := ip^.lreg; { result is same as left }
         plcreg(rgflg, ip, tr); { place result in flags }
         ip^.rsreg := rgflg;
         remcxt(rgflg); { clear }
         { Set flag sense according to signed operation status }
         case ip^.i of { compare }

            tiltnint: if signed then ip^.rsflg := fll  else  ip^.rsflg := flb;
            tigtnint: if signed then ip^.rsflg := flg  else  ip^.rsflg := fla;
            tileqint: if signed then ip^.rsflg := flle else  ip^.rsflg := flbe;
            tigeqint: if signed then ip^.rsflg := flge else  ip^.rsflg := flae

         end;
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear }

      end;
      tiltnintimm, tigtnintimm, tileqintimm, tigeqintimm: begin

         { find signed or unsigned status of operation }
         signed := chksgn(ip^.left^.rbase) or constis(ip^.base);
         { find if operation must be performed in quad precision math }
         quad := (ip^.left^.rbase^.size > regsiz) or (ip^.base^.size > regsiz);
         doleft(ip, quad); { process left side allocate }
         ip^.rsreg := ip^.lreg; { result is same as left }
         plcreg(rgflg, ip, tr); { place result in flags }
         ip^.rsreg := rgflg;
         remcxt(rgflg); { clear }
         { Set flag sense according to signed operation status }
         case ip^.i of { compare }

            tiltnintimm: if signed then ip^.rsflg := fll  else  ip^.rsflg := flb;
            tigtnintimm: if signed then ip^.rsflg := flg  else  ip^.rsflg := fla;
            tileqintimm: if signed then ip^.rsflg := flle else  ip^.rsflg := flbe;
            tigeqintimm: if signed then ip^.rsflg := flge else  ip^.rsflg := flae

         end;
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear }

      end;
      tiltnintlod, tigtnintlod, tileqintlod, tigeqintlod: begin

         { find signed or unsigned status of operation }
         signed := chksgn(ip^.left^.rbase) or chksgn(ip^.base);
         { find if operation must be performed in quad precision math }
         quad := (ip^.left^.rbase^.size > regsiz) or (ip^.base^.size > regsiz);
         doleft(ip, quad); { allocate any left }
         getreg(ip^.t1reg, ip, tr); { get display temp }
         remcxt(ip^.t1reg); { clear }
         ip^.rsreg := ip^.lreg; { result is same as left }
         plcreg(rgflg, ip, tr); { place result in flags }
         ip^.rsreg := rgflg;
         remcxt(rgflg); { clear }
         { Set flag sense according to signed operation status }
         case ip^.i of { compare }

            tiltnintlod: if signed then ip^.rsflg := fll  else  ip^.rsflg := flb;
            tigtnintlod: if signed then ip^.rsflg := flg  else  ip^.rsflg := fla;
            tileqintlod: if signed then ip^.rsflg := flle else  ip^.rsflg := flbe;
            tigeqintlod: if signed then ip^.rsflg := flge else  ip^.rsflg := flae

         end;
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear }

      end;
      tiltnintldi, tigtnintldi, tileqintldi, tigeqintldi: begin

         { find signed or unsigned status of operation }
         signed := chksgn(ip^.left^.rbase) or chksgn(ip^.right^.rbase);
         { find if either operand needs to be checked for sign }
         sgnchk := chksgn(ip^.left^.rbase) <> chksgn(ip^.right^.rbase);
         { find if operation must be performed in quad precision math }
         quad := (ip^.left^.rbase^.size > regsiz) or
                   (ip^.right^.rbase^.size > regsiz);
         { allocate left side }
         doleft(ip, quad); { allocate any left }
         dogendoildir(signed, sgnchk, quad, ip); { allocate right }
         ip^.rsreg := ip^.lreg; { result is same as left }
         plcreg(rgflg, ip, tr); { place result in flags }
         ip^.rsreg := rgflg;
         remcxt(rgflg); { clear }
         { Set flag sense according to signed operation status }
         case ip^.i of { compare }

            tiltnintldi: if signed then ip^.rsflg := fll  else  ip^.rsflg := flb;
            tigtnintldi: if signed then ip^.rsflg := flg  else  ip^.rsflg := fla;
            tileqintldi: if signed then ip^.rsflg := flle else  ip^.rsflg := flbe;
            tigeqintldi: if signed then ip^.rsflg := flge else  ip^.rsflg := flae

         end;
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear }

      end;
      tiequstr, tineqstr, tileqstr, tigeqstr, tiltnstr, tigtnstr: begin

         regexp(rgesi, rgnull, ip^.left, tr); { allocate operand }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgedi, rgnull, ip^.right, tr); { allocate operand }
         ip^.rreg := ip^.right^.freg; { place right from result }
         plcreg(rgecx, ip, tr); { place count }
         ip^.t1reg := rgecx;
         remcxt(rgecx); { clear }
         plcreg(rgflg, ip, tr); { place result in flags }
         ip^.rsreg := rgflg;
         remcxt(rgflg); { clear }
         { set flag sense }
         case ip^.i of { compare }

            tiequstr: ip^.rsflg := fle;
            tineqstr: ip^.rsflg := flne;
            tileqstr: ip^.rsflg := flle;
            tigeqstr: ip^.rsflg := flge;
            tiltnstr: ip^.rsflg := fll;
            tigtnstr: ip^.rsflg := flg

         end;
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg); { clear }
         remcxt(ip^.lreg); { left gets distroyed }
         remcxt(ip^.rreg) { right gets distroyed }

      end;
      ticvtitr: begin

         regexp(rgnull, rgnull, ip^.left, tr); { allocate operand }
         ip^.lreg := ip^.left^.freg { place left from result }

      end;
      ticvtrtsr: regexp(rgnull, rgnull, ip^.left, tr); { allocate operand }
      tiexprel, tinegrel, tiabsrel, tisqrrel, tiatnrel, ticosrel, tilgnrel,
      tisinrel, tisqtrel: begin

         regexp(rgnull, rgnull, ip^.left, tr); { allocate operand }
         ip^.lreg := ip^.left^.freg { place left from result }

      end;
      tirnd, titrc: begin

         regexp(rgnull, rgnull, ip^.left, tr); { allocate operand }
         ip^.lreg := ip^.left^.freg; { place left from result }
         prfreg(ip^.rsreg, rr, ip, tr); { allocate result }
         remcxt(ip^.rsreg); { clear }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear }

      end;
      tirecoff: begin

         regexp(rgnull, rgnull, ip^.left, tr); { allocate operand }
         ip^.lreg := ip^.left^.freg; { place left from result }
         ip^.rsreg := ip^.lreg; { and result is same as left }
         if ftagchk then begin { tag checking is on }

            { see if there is any tag associated with the field }
            fndtag(ip^.base, tagp, casp); { find tag and case for entry }
            if tagp <> nil then { found }
               { check if tag field exists }
               if tagp^.ftge then begin

               { tag checking is active, get an offset register to allow that }
               getreg(ip^.t1reg, ip, tr); { get tag offset register }
               remcxt(ip^.t1reg) { clear }

            end

         end;
         remcxt(ip^.rsreg); { clear result }
         prcres(rr, rrx, ip, tr); { get transfer register }
         remcxt(ip^.freg) { clear }

      end

      { trap other cases }
      else error(esysflt101) { should not occur }

   end;
   { restore context for any pushed registers }
   for r := rgnull to rgflg do if r in ip^.push then regtrk[r] := rcn[r];
   regdiag(ip, false) { output diagnostic }

end; { regexp }

{*******************************************************************************

Perform register allocation for block

All operator entries that require registers in the given block have registers
allocated. The graph is toured by recursively exploring each branch, and each
"terminal operator" entry allocates registers.

Accepts the intermediate, which is processed as a list, and a set reference
in which is returned the total allocation mask of all registers used. This is
used to determine what regisers need to be saved in a routine.

*******************************************************************************}

procedure regblk(    ip: intptr;  { graph root to allocate for }
                 var tr: regset); { total register allocation }

var i: integer;

procedure regopr(ip: intptr); forward;

{ process operator list }

procedure reglst(ip: intptr);

begin

   while ip <> nil do begin { traverse this forward flow }

      regopr(ip); { follow secondary flows single node }
      ip := ip^.flow { next in flow }

   end

end;

{ process individual operator }

procedure regopr(ip: intptr);

var ip2:        intptr;
    rip, lip:   intptr;
    rcn1, rcn2: regcxt;  { register context saves }
    quad:       boolean; { operation is quad precision }

{ do standard left allocate }

procedure doleft;

begin

   regexp(rgnull, rgnull, ip^.left, tr); { alocate }
   ip^.lreg := ip^.left^.freg; { place left from result }
   ip^.lregx := ip^.left^.fregx

end;

{ do standard right allocate }

procedure doright;

begin

   regexp(rgnull, rgnull, ip^.right, tr); { alocate }
   ip^.rreg := ip^.right^.freg; { place right from result }
   ip^.rregx := ip^.right^.fregx

end;

{ do standard left and right allocate }

procedure doboth;

begin

   regexp(rgnull, rgnull, ip^.left, tr); { alocate }
   ip^.lreg := ip^.left^.freg; { place left from result }
   ip^.lregx := ip^.left^.fregx;
   regexp(rgnull, rgnull, ip^.right, tr); { alocate }
   ip^.rreg := ip^.right^.freg; { place right from result }
   ip^.rregx := ip^.right^.fregx

end;

{ Do standard left and right allocate with "bridging". This makes any
  suboperator, no matter how deep, appear to be allocated as a branch of
  the current operator. Used to defacto move where subtrees are rooted. }

procedure dobothb(sip: intptr);

begin

   { copy allocations down to suboperator }
   sip^.alc := ip^.alc;
   sip^.push := ip^.push;
   regexp(rgnull, rgnull, sip^.left, tr); { alocate }
   sip^.lreg := sip^.left^.freg; { place left from result }
   sip^.lregx := sip^.left^.fregx;
   regexp(rgnull, rgnull, sip^.right, tr); { alocate }
   sip^.rreg := sip^.right^.freg; { place right from result }
   sip^.rregx := sip^.right^.fregx;
   { copy allocations back to main operator }
   ip^.alc := sip^.alc;
   ip^.push := sip^.push

end;

{ do standard right allocate with bridging }

procedure dorightb(sip: intptr);

begin

   { copy allocations down to suboperator }
   sip^.alc := ip^.alc;
   sip^.push := ip^.push;
   regexp(rgnull, rgnull, sip^.right, tr); { alocate }
   sip^.rreg := sip^.right^.freg; { place right from result }
   sip^.rregx := sip^.right^.fregx;
   { copy allocations back to main operator }
   ip^.alc := sip^.alc;
   ip^.push := sip^.push

end;

{ do store }

procedure dosto;

procedure default;

begin

   regexp(rgnull, rgnull, ip^.left, tr); { get left }
   ip^.lreg := ip^.left^.freg; { place left from result }
   ip^.lregx := ip^.left^.fregx;
   getreg(ip^.t1reg, ip, tr); { get display register }
   remcxt(ip^.t1reg) { clear }

end;

procedure prcopr;

var signed: boolean; { signed status of operation }

begin

   if ip^.base^.size >= regsiz then begin { must be double }

      { find signed or unsigned status of operation }
      signed := chksgn(ip^.left^.left^.base) or chksgn(ip^.left^.right^.base);
      { check signed status of operation matches destination, or overflow
        checking is off. If checking of the unregistered destination is
        required, then this optimization becomes too expensive, since we would
        have to pull it to a register or generate a separate instruction. }
      if signed = chksgn(ip^.left^.left^.base) or not fovfchk then begin

         regexp(rgnull, rgnull, rip, tr); { assign right }
         getreg(rip^.t1reg, rip, tr); { get display register }
         remcxt(rip^.t1reg) { clear }

      end else default { process as normal }

   end else default { process as normal }

end;

begin { dosto }

   if ip^.left^.i = tilimint then begin { default }

      getreg(ip^.t1reg, ip, tr); { get display register }
      remcxt(ip^.t1reg) { clear }

   end else if (ip^.left^.i = tiaddint) or (ip^.left^.i = tiandint) or
               (ip^.left^.i = tiorint) or (ip^.left^.i= tisubint) or
               (ip^.left^.i = tixorint) then begin

      { check if one side is the same as the result }
      if basequ(ip^.base, ip^.left^.left) or
         (basequ(ip^.base, ip^.left^.right) and
          (ip^.i <> tisubint)) then begin

         { one side same, perform as folded operation }
         lip := ip^.left^.left; { get the left and right operators }
         rip := ip^.left^.right;
         if basequ(ip^.base, ip^.left^.right) and
            (ip^.i <> tisubint) then begin

            { reverse so that store object is left }
            lip := ip^.left^.right;
            rip := ip^.left^.left

         end;
         { check add or subtract can be reduced down to inc/dec }
         if (rip^.i = tilimint) and
            ((ip^.left^.i = tiaddint) or (ip^.left^.i = tisubint)) then begin

            { check can be handled by a single inc or dec }
            if (ssequ(constis(rip^.base), consti(rip^.base), false, 1) or
                ssequ(constis(rip^.base), consti(rip^.base), true, 1)) and
               not fovfchk then begin

               getreg(ip^.t1reg, ip, tr); { get display register }
               remcxt(ip^.t1reg) { clear }

            end else prcopr { process operator }

         end else prcopr { process operator }

      end else default { default }

   end else default; { default }
   { if the store operand ends up in edi or esi, and the target is byte or word,
     then we need another temp reg to move it to from the set
     eax, ebx, ecx, edx. This is because we can't store from edi or esi. }
   if (ip^.base^.size < regsiz) and
      ((ip^.lreg = rgedi) or (ip^.lreg = rgesi)) then begin

      getregbs(ip^.t2reg, ip, tr); { get byte storeable register }
      remcxt(ip^.t2reg) { clear }

   end else if (ip^.base^.size > regsiz) and
            (ip^.left^.rbase^.size <= regsiz) then begin

      { its a double result, and operand is not, must expand the left }
      getreg(ip^.lregx, ip, tr); { get high half register }
      remcxt(ip^.lregx) { clear from context }

   end;
   matcxt(ip^.base); { match any context for target }
   setcxt(ip^.lreg, ip^.base) { set context target }

end; { dosto }

begin { regopr }

   regdiag(ip, true); { output diagnostic }
   ip^.alc := []; { clear registers }
   { we do a case here because of the 256 element set limit }
   case ip^.i of { intermediate }

      tihalt: ; { no action }

      tilabequ: begin

         { if there is a context for the jump, we can merge with it. Otherwise
           we have to assume that registers are completely unknown, and
           clear out the context }
         if ip^.rcxt <> nil then mrgcxt(ip^.rcxt^) { merge context }
         else clrcxt { otherwise, context is unknown }

      end;

      tigoto: begin

         getreg(ip^.t1reg, ip, tr); { get display register }
         new(ip^.rcxt); { get a new context block }
         ip^.rcxt^ := regtrk { save the branch context }

      end;

      tigotot, tigotof: begin

         regexp(rgflg, rgnull, ip^.left, tr); { allocate left }
         ip^.lreg := ip^.left^.freg; { place left from result }
         ip^.lflg := ip^.left^.fflg;
         getreg(ip^.t1reg, ip, tr); { get display register }
         new(ip^.rcxt); { get a new context block }
         ip^.rcxt^ := regtrk { save the branch context }

      end;

      tiprccal, tiprccalo, tiprccali: begin

         pfpar(ip, tr); { parameter list }
         clrcxt { clear context out after call }

      end;

      tiwrtbol, tiwrtchr, tiwrtint: begin

         regexp(rgecx, rgnull, ip^.left, tr); { allocate file }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgeax, rgnull, ip^.right, tr); { allocate data }
         ip^.rreg := ip^.right^.freg; { place right from result }
         plcreg(rgebx, ip, tr); { get length register }
         remcxt(rgebx); { clear }
         clrcxt { clear context for external call }

      end;
      tiwrtsrc: begin

         regexp(rgecx, rgnull, ip^.left, tr); { allocate file }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgeax, rgnull, ip^.right, tr); { allocate pointer }
         ip^.rreg := ip^.right^.freg; { place right from result }
         plcreg(rgebx, ip, tr); { get length register }
         remcxt(rgebx); { clear }
         clrcxt { clear context for external call }

      end;
      tiwrtbolt: begin

         regexp(rgeax, rgnull, ip^.left, tr); { allocate file }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgebx, rgnull, ip^.right, tr); { allocate boolean }
         ip^.rreg := ip^.right^.freg; { place right from result }
         clrcxt { clear context for external call }

      end;
      tiwrtintt, tiwrtchrt: begin

         regexp(rgeax, rgnull, ip^.left, tr); { allocate file }
         ip^.lreg := ip^.left^.freg; { place left from result }
         { The data could be 64 bit, which we can't use. Specify the upper 32
           bits into a register we don't need. }
         regexp(rgecx, rgedx, ip^.right, tr); { allocate data }
         ip^.rreg := ip^.right^.freg; { place right from result }
         plcreg(rgebx, ip, tr); { get field register }
         remcxt(rgebx); { clear }
         clrcxt { clear context for external call }

      end;
      tiwrtrelt: begin

         regexp(rgeax, rgnull, ip^.left, tr); { allocate left }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgnull, rgnull, ip^.right, tr); { allocate right }
         ip^.rreg := ip^.right^.freg; { place right from result }
         plcreg(rgebx, ip, tr); { get field register }
         remcxt(rgebx); { clear }
         clrcxt { clear context for external call }

      end;
      tiwrtstrt: begin

         regexp(rgecx, rgnull, ip^.left, tr); { allocate file }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgeax, rgnull, ip^.right, tr); { allocate right }
         ip^.rreg := ip^.right^.freg; { place right from result }
         plcreg(rgebx, ip, tr); { get length register }
         remcxt(rgebx); { clear }
         clrcxt { clear context for external call }

      end;
      tiwrtset: begin

         regexp(rgecx, rgnull, ip^.left, tr); { allocate file }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgeax, rgnull, ip^.right, tr); { allocate set pointer }
         ip^.rreg := ip^.right^.freg; { place right from result }
         plcreg(rgebx, ip, tr); { get length register }
         remcxt(rgebx); { clear }
         clrcxt { clear context for external call }

      end;
      tiredsrc: begin

         regexp(rgecx, rgnull, ip^.left, tr); { allocate file }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgeax, rgnull, ip^.right, tr); { allocate data pointer }
         ip^.rreg := ip^.right^.freg; { place right from result }
         plcreg(rgebx, ip, tr); { get length register }
         remcxt(rgebx); { clear }
         clrcxt { clear context for external call }

      end;
      tistiint, tistichr, tistibol, tistifint, tistifchr,
      tistifbol: if ip^.right^.i = tilimint then begin

         { constant operand case }
         if ip^.left^.i = tiarrref then begin { array }

            if ip^.left^.base^.t <> tarray then error(einvfmt);
            i := ip^.left^.base^.arrt^.size; { get base type size }
            if i in [1, 2, 4, 8] then begin { reachable by scalable access }

               { check constant address }
               if ip^.left^.left^.i = tilodadr then begin

                  { check extended parameter }
                  if not chkext(ip^.left^.left^.base) then begin

                     dorightb(ip^.left); { allocate array access components }
                     { check will need a display or 'with' temp register }
                     if (ip^.left^.left^.base^.t = tfield) or
                        (ip^.left^.left^.base^.t = tftag) or
                        ip^.left^.left^.base^.local then begin

                        getreg(ip^.t1reg, ip, tr); { get display register }
                        remcxt(ip^.t1reg) { clear }

                     end

                  end else
                     dobothb(ip^.left) { allocate array access components }

               end else dobothb(ip^.left) { allocate array access components }

            end else doleft { just allocate address }

         end else doleft { just allocate address }

      end else begin { non-constant operand }

         if ip^.left^.i = tiarrref then begin { array }

            if ip^.left^.base^.t <> tarray then error(einvfmt);
            i := ip^.left^.base^.arrt^.size; { get base type size }
            if i in [1, 2, 4, 8] then begin { reachable by scalable access }

               doright; { allocate operand }
               { check constant address }
               if ip^.left^.left^.i = tilodadr then begin

                  { check extended parameter }
                  if not chkext(ip^.left^.left^.base) then begin

                     dorightb(ip^.left);
                     { check will need a display or 'with' temp register }
                     if (ip^.left^.left^.base^.t = tfield) or
                        (ip^.left^.left^.base^.t = tftag) or
                        ip^.left^.left^.base^.local then begin

                        getreg(ip^.t1reg, ip, tr); { get display register }
                        remcxt(ip^.t1reg) { clear }

                     end

                  end else
                     dobothb(ip^.left) { allocate array access components }

               end else dobothb(ip^.left) { allocate array access components }

            end else doboth { perform default }

         end else doboth; { perform default }
         { if the store operand ends up in edi or esi, and the target is byte,
           then we need another temp reg to move it to from the set
           eax, ebx, ecx, edx. This is because we can't store from edi or esi. }
         if (ip^.base^.size <> 4) and
            ((ip^.rreg = rgedi) or (ip^.rreg = rgesi)) then begin

            getregbs(ip^.t2reg, ip, tr); { get byte storeable register }
            remcxt(ip^.t2reg) { clear }

         end

      end;
      tistisrl, tistirel, tistifsrl, tistifrel: begin

         regexp(rgnull, rgnull, ip^.left, tr); { allocate address }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgnull, rgnull, ip^.right, tr); { allocate data }
         ip^.rreg := ip^.right^.freg { place right from result }

      end;
      tiwrtsrl, tiwrtrel: begin

         regexp(rgecx, rgnull, ip^.left, tr); { allocate file }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgeax, rgnull, ip^.right, tr); { allocate data pointer }
         ip^.rreg := ip^.right^.freg; { place right from result }
         plcreg(rgebx, ip, tr); { get length register }
         remcxt(rgebx); { clear }
         getreg(ip^.t1reg, ip, tr); { get address register }
         remcxt(ip^.t1reg); { clear }
         clrcxt { clear context for external call }

      end;
      tiredchrt, tiredrelt, tipos: begin

         regexp(rgeax, rgnull, ip^.left, tr); { allocate file }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgebx, rgnull, ip^.right, tr); { allocate data pointer }
         ip^.rreg := ip^.right^.freg; { place right from result }
         clrcxt { clear context for external call }

      end;
      tiredintt: begin

         regexp(rgeax, rgnull, ip^.left, tr); { allocate file }
         ip^.lreg := ip^.left^.freg; { place left from result }
         if ip^.base^.size = regsiz then begin { normal read }

            regexp(rgebx, rgnull, ip^.right, tr); { allocate data pointer }
            ip^.rreg := ip^.right^.freg; { place right from result }

         end else begin { convertion read }

            plcreg(rgebx, ip, tr); { get address register }
            remcxt(rgebx); { clear }
            regexp(rgnull, rgnull, ip^.right, tr); { allocate data pointer }
            ip^.rreg := ip^.right^.freg { place right from result }

         end;
         clrcxt { clear context for external call }

      end;
      tiredsrlt: begin

         plcreg(rgebx, ip, tr); { get temp address register }
         remcxt(rgebx); { clear }
         regexp(rgeax, rgnull, ip^.left, tr); { allocate file }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgnull, rgnull, ip^.right, tr); { allocate short real }
         ip^.rreg := ip^.right^.freg; { place right from result }
         getreg(ip^.t1reg, ip, tr); { get display register }
         remcxt(ip^.t1reg); { clear }
         clrcxt { clear context for external call }

      end;
      tistiset, tistisrc: begin

         regexp(rgedi, rgnull, ip^.left, tr); { allocate left }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgesi, rgnull, ip^.right, tr); { allocate right }
         ip^.rreg := ip^.right^.freg; { place right from result }
         plcreg(rgecx, ip, tr); { get count register }
         remcxt(rgecx); { clear }
         { because esi and edi get modified by operation, they aren't valid }
         remcxt(ip^.lreg); { distroys left }
         remcxt(ip^.rreg) { distorys right }

      end;
      tichg: begin

         regexp(rgeax, rgebx, ip^.left, tr); { allocate dest string }
         ip^.lreg := ip^.left^.freg; { place left from result }
         ip^.lregx := ip^.left^.fregx;
         regexp(rgecx, rgedx, ip^.right, tr); { allocate src string }
         ip^.rreg := ip^.right^.freg; { place right from result }
         ip^.rregx := ip^.right^.fregx;
         clrcxt { clear context for external call }

      end;
      tiassign, tiwrtgstt: begin

         regexp(rgecx, rgnull, ip^.left, tr); { allocate file }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgeax, rgebx, ip^.right, tr); { allocate string }
         ip^.rreg := ip^.right^.freg; { place right from result }
         ip^.rregx := ip^.right^.fregx;
         clrcxt { clear context for external call }

      end;
      tistigar: begin

         regexp(rgedi, rgecx, ip^.left, tr); { allocate left }
         ip^.lreg := ip^.left^.freg; { place left from result }
         ip^.lregx := ip^.left^.fregx;
         regexp(rgesi, rgnull, ip^.right, tr); { allocate right }
         ip^.rreg := ip^.right^.freg; { place right from result }
         ip^.rregx := ip^.right^.fregx;
         remcxt(ip^.lreg); { distroys left }
         remcxt(ip^.lregx);
         remcxt(ip^.rreg) { distroys right }

      end;
      tistitgp, tistiftgp: begin

         regexp(rgnull, rgnull, ip^.left, tr); { allocate left }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgnull, rgnull, ip^.right, tr); { allocate right }
         ip^.rreg := ip^.right^.freg; { place right from result }
         ip^.rregx := ip^.right^.fregx

      end;
      tiwrtchrft, tiwrtbolft: begin

         regexp(rgeax, rgnull, ip^.left, tr); { allocate file }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgecx, rgnull, ip^.right, tr); { allocate data }
         ip^.rreg := ip^.right^.freg; { place right from result }
         regexp(rgebx, rgnull, ip^.xtra, tr); { allocate field }
         ip^.xreg := ip^.xtra^.freg; { place right from result }
         clrcxt { clear context for external call }

      end;
      tiwrtstrft: begin

         regexp(rgecx, rgnull, ip^.left, tr); { allocate file }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgeax, rgnull, ip^.right, tr); { allocate string }
         ip^.rreg := ip^.right^.freg; { place right from result }
         regexp(rgedx, rgnull, ip^.xtra, tr); { allocate field }
         ip^.xreg := ip^.xtra^.freg; { place xtra from result }
         plcreg(rgebx, ip, tr); { get length register }
         remcxt(rgebx); { clear }
         clrcxt { clear context for external call }

      end;
      tiwrtintft: begin

         regexp(rgeax, rgnull, ip^.left, tr); { allocate file }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgecx, rgnull, ip^.right, tr); { allocate integer }
         ip^.rreg := ip^.right^.freg; { place right from result }
         regexp(rgebx, rgnull, ip^.xtra, tr); { allocate field }
         ip^.xreg := ip^.xtra^.freg; { place right from result }
         clrcxt { clear context for external call }

      end;
      tiwrtrelft: begin

         regexp(rgeax, rgnull, ip^.left, tr); { allocate file }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgnull, rgnull, ip^.right, tr); { allocate real }
         ip^.rreg := ip^.right^.freg; { place right from result }
         regexp(rgebx, rgnull, ip^.xtra, tr); { allocate field }
         ip^.xreg := ip^.xtra^.freg; { place right from result }
         clrcxt { clear context for external call }

      end;
      tiunpack: begin

         regexp(rgesi, rgnull, ip^.left, tr); { allocate packed array }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgedi, rgnull, ip^.right, tr); { allocate unpacked array }
         ip^.rreg := ip^.right^.freg; { place right from result }
         regexp(rgeax, rgnull, ip^.xtra, tr); { allocate starting index }
         ip^.xreg := ip^.xtra^.freg; { place xtra from result }
         plcreg(rgedx, ip, tr); { edx gets cleared by mul }
         remcxt(rgedx); { clear }
         plcreg(rgecx, ip, tr); { get count }
         ip^.t1reg := rgecx;
         remcxt(rgecx); { clear }
         { all that is left is ebx }
         plcreg(rgebx, ip, tr); { get multiplier register }
         ip^.t2reg := rgebx;
         remcxt(rgebx); { clear }
         remcxt(ip^.lreg); { distroys left }
         remcxt(ip^.rreg) { distroys right }

      end;
      tipack: begin

         regexp(rgesi, rgnull, ip^.left, tr); { allocate unpacked }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgeax, rgnull, ip^.right, tr); { allocate index }
         ip^.rreg := ip^.right^.freg; { place right from result }
         regexp(rgedi, rgnull, ip^.xtra, tr); { allocate packed array }
         ip^.xreg := ip^.xtra^.freg; { place xtra from result }
         plcreg(rgedx, ip, tr); { edx gets cleared by mul }
         remcxt(rgedx); { clear }
         plcreg(rgecx, ip, tr); { get count }
         ip^.t1reg := rgecx;
         remcxt(rgecx); { clear }
         { all that is left is ebx }
         plcreg(rgebx, ip, tr); { get multiplier register }
         ip^.t2reg := rgebx;
         remcxt(rgebx); { clear }
         remcxt(ip^.lreg); { distroys left }
         remcxt(ip^.xreg) { distroys extra }

      end;
      tiwrtgstft: begin

         regexp(rgecx, rgnull, ip^.left, tr); { allocate file }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgeax, rgebx, ip^.right, tr); { allocate tagged pointer }
         ip^.rreg := ip^.right^.freg; { place right from result }
         ip^.rregx := ip^.right^.fregx;
         regexp(rgedx, rgnull, ip^.xtra, tr); { allocate field }
         ip^.xreg := ip^.xtra^.freg; { place right from result }
         clrcxt { clear context for external call }

      end;
      tiwrtrelfft: begin

         regexp(rgeax, rgnull, ip^.left, tr); { allocate file }
         ip^.lreg := ip^.left^.freg; { place left from result }
         regexp(rgnull, rgnull, ip^.right, tr); { allocate real }
         ip^.rreg := ip^.right^.freg; { place right from result }
         regexp(rgebx, rgnull, ip^.xtra, tr); { allocate field }
         ip^.xreg := ip^.xtra^.freg; { place right from result }
         regexp(rgecx, rgnull, ip^.xtra2, tr); { allocate fraction }
         ip^.x2reg := ip^.xtra2^.freg; { place right from result }
         clrcxt { clear context for external call }

      end;
      tistosrl, tistorel, tistofsrl, tistofrel: begin

         regexp(rgnull, rgnull, ip^.left, tr); { get left }
         ip^.lreg := ip^.left^.freg; { place left from result }
         getreg(ip^.t1reg, ip, tr); { get register for display or with }
         remcxt(ip^.t1reg) { clear }

      end;
      tistoset, tistosrc: begin

         regexp(rgesi, rgnull, ip^.left, tr); { get left }
         ip^.lreg := ip^.left^.freg; { place left from result }
         plcreg(rgedi, ip, tr); { allocate edi }
         remcxt(rgedi); { clear }
         plcreg(rgecx, ip, tr); { allocate ecx for count }
         remcxt(rgecx); { clear }
         { because esi gets modified by operation, it isn't valid }
         remcxt(rgesi)

      end;
      tinew: begin

         plcreg(rgebx, ip, tr); { allocate ebx for length }
         remcxt(rgebx); { clear }
         plcreg(rgeax, ip, tr); { get temp for tag to fix convert }
         ip^.t1reg := rgeax; { set temp reg }
         remcxt(rgeax); { clear }
         regexp(rgnull, rgnull, ip^.left, tr); { get left }
         ip^.lreg := ip^.left^.freg; { place left from result }
         clrcxt { clear context for external call }

      end;
      tidisp: begin

         regexp(rgeax, rgnull, ip^.left, tr); { get left }
         ip^.lreg := ip^.left^.freg; { place left from result }
         plcreg(rgebx, ip, tr); { allocate ecx for count }
         remcxt(rgebx); { clear }
         clrcxt { clear context for external call }

      end;
      tireset, tirewrite, tiupdate, tiappend: begin

         regexp(rgeax, rgnull, ip^.left, tr); { get left }
         ip^.lreg := ip^.left^.freg; { place left from result }
         plcreg(rgebx, ip, tr); { allocate ebx for buffer length }
         remcxt(rgebx); { clear }
         clrcxt { clear context for external call }

      end;
      tiwrteolt: begin

         regexp(rgeax, rgnull, ip^.left, tr); { get left }
         ip^.lreg := ip^.left^.freg; { place left from result }
         clrcxt { clear context for external call }

      end;
      tiredeolt, tiget, tigett, tiput, ticlose, tipaget, tisignal,
      tisignalone: begin

         regexp(rgeax, rgnull, ip^.left, tr); { get single reg param }
         ip^.lreg := ip^.left^.freg; { place left from result }
         clrcxt { clear context for external call }

      end;
      tiwait: begin

         plcreg(rgeax, ip, tr); { reserve eax for the lock id }
         remcxt(rgeax); { clear }
         regexp(rgebx, rgnull, ip^.left, tr); { get single reg param }
         ip^.lreg := ip^.left^.freg; { place left from result }
         clrcxt { clear context for external call }

      end;
      tidel: begin

         regexp(rgeax, rgebx, ip^.left, tr); { get string }
         ip^.lreg := ip^.left^.freg; { place left from result }
         clrcxt { clear context for external call }

      end;
      tistoint, tistochr, tistobol: dosto;
      tistofint, tistofchr, tistofbol: begin

         regexp(rgnull, rgnull, ip^.left, tr); { get left }
         ip^.lreg := ip^.left^.freg; { place left from result }
         ip^.lregx := ip^.left^.fregx;
         { if the store operand ends up in edi or esi, and the target is byte or
           word, then we need another temp reg to move it to from the set
           eax, ebx, ecx, edx. This is because we can't store from edi or esi. }
         if (ip^.base^.size < regsiz) and
            ((ip^.lreg = rgedi) or (ip^.lreg = rgesi)) then begin

            getregbs(ip^.t2reg, ip, tr); { get byte storeable register }
            remcxt(ip^.t2reg) { clear }

         end else if (ip^.base^.size > regsiz) and
                  (ip^.left^.rbase^.size <= regsiz) then begin

            { its a double result, and operand is not, must expand the left }
            getreg(ip^.lregx, ip, tr); { get high half register }
            remcxt(ip^.lregx) { clear from context }

         end;
         getreg(ip^.t1reg, ip, tr); { get display register }
         remcxt(ip^.t1reg) { clear }

      end;
      ticalpar: error(esysflt119); { should not happen }
      tinewgar: begin

         { nonstandard ordering }
         regexp(rgebx, rgnull, ip^.right, tr); { length }
         ip^.rreg := ip^.right^.freg; { place right from result }
         plcreg(rgedx, ip, tr); { edx gets trashed by mul instruction }
         remcxt(rgedx); { clear }
         regexp(rgeax, rgnull, ip^.left, tr); { pointer }
         ip^.lreg := ip^.left^.freg; { place left from result }
         clrcxt { clear context for external call }

      end;
      tistogar: begin

         regexp(rgesi, rgecx, ip^.left, tr); { tagged pointer }
         ip^.lreg := ip^.left^.freg; { place left from result }
         ip^.lregx := ip^.left^.fregx;
         plcreg(rgedi, ip, tr); { get destination pointer reg }
         remcxt(rgedi); { clear }
         getreg(ip^.t1reg, ip, tr); { get length compare register }
         remcxt(ip^.t1reg) { clear }

      end;
      tidspgar: begin

         regexp(rgeax, rgebx, ip^.left, tr); { tagged pointer }
         ip^.lreg := ip^.left^.freg; { place left from result }
         ip^.lregx := ip^.left^.fregx;
         clrcxt { clear context for external call }

      end;
      tistotgp, tistoftgp: begin

         regexp(rgnull, rgnull, ip^.left, tr); { tagged pointer }
         ip^.lreg := ip^.left^.freg; { place left from result }
         ip^.lregx := ip^.left^.fregx;
         getreg(ip^.t1reg, ip, tr); { get display register }
         remcxt(ip^.t1reg) { clear }

      end;
      tiassert: if fincast then begin { include asserts enabled }

         { ok, assert is semi-structural }
         if ip^.left^.i = tinotbol then begin { not, bring this operator up }

            regexp(rgflg, rgnull, ip^.left^.left, tr);
            ip^.lreg := ip^.left^.left^.freg; { place left from result }
            ip^.lflg := ip^.left^.left^.fflg

         end else begin { standard }

            regexp(rgflg, rgnull, ip^.left, tr);
            ip^.lreg := ip^.left^.freg; { place left from result }
            ip^.lflg := ip^.left^.fflg

         end;
         regexp(rgeax, rgebx, ip^.right, tr); { get string }
         ip^.rreg := ip^.right^.freg; { place right from result }
         clrcxt { clear context for external call }

      end;

      { structured entries }

      tiifbgn: begin { if statement }

         if ip^.left^.i = tinotbol then begin { not, bring this operator up }

            regexp(rgflg, rgnull, ip^.left^.left, tr);
            ip^.lreg := ip^.left^.left^.freg; { place left from result }
            ip^.lflg := ip^.left^.left^.fflg

         end else begin { standard }

            regexp(rgflg, rgnull, ip^.left, tr);
            ip^.lreg := ip^.left^.freg; { place left from result }
            ip^.lflg := ip^.left^.fflg

         end;
         rcn1 := regtrk; { save starting register context }
         reglst(ip^.flow2); { process true flow }
         rcn2 := regtrk; { save context after that }
         regtrk := rcn1; { restore starting register context }
         reglst(ip^.flow3); { process false flow }
         mrgcxt(rcn2) { merge with other flow to find common context }

      end;

      ticasbgn: begin

         if ip^.base^.t = thshtbl then begin

            { fix left result to eax }
            regexp(rgeax, rgnull, ip^.left, tr);
            { reserve edx for modulo }
            plcreg(rgedx, ip, tr);
            remcxt(rgedx); { clear }
            { For hash table processing, we need two temp registers. }
            getreg(ip^.t1reg, ip, tr);
            remcxt(ip^.t1reg); { clear }
            getreg(ip^.t2reg, ip, tr);
            remcxt(ip^.t2reg) { clear }

         end else regexp(rgnull, rgnull, ip^.left, tr);
         ip^.lreg := ip^.left^.freg; { place left from result }
         remcxt(ip^.lreg); { left gets distroyed }
         rcn1 := regtrk; { save input register context }
         rescxt(rcn2); { clear output context }
         ip2 := ip^.flow2; { index top of statement list }
         while ip2 <> nil do begin { traverse case entries }

            regtrk := rcn1; { restore to input context }
            regopr(ip2); { follow secondary flows single node }
            mrgcxt(rcn2); { merge with output contexts }
            rcn2 := regtrk; { save }
            ip2 := ip2^.flow { next in flow }

         end

      end;

      tiwhlbgn: begin

         clrcxt; { clear starting context }
         if ip^.left^.i = tinotbol then begin { not, bring this operator up }

            regexp(rgflg, rgnull, ip^.left^.left, tr);
            ip^.lreg := ip^.left^.left^.freg; { place left from result }
            ip^.lflg := ip^.left^.left^.fflg

         end else begin { standard }

            regexp(rgflg, rgnull, ip^.left, tr);
            ip^.lreg := ip^.left^.freg; { place left from result }
            ip^.lflg := ip^.left^.fflg

         end;
         reglst(ip^.flow2); { process enclosed flow }
         clrcxt { clear ending context }

      end;

      tirptbgn: begin

         clrcxt; { clear starting context }
         reglst(ip^.flow2); { process enclosed flow }
         if ip^.left^.i = tinotbol then begin { not, bring this operator up }

            regexp(rgflg, rgnull, ip^.left^.left, tr);
            ip^.lreg := ip^.left^.left^.freg; { place left from result }
            ip^.lflg := ip^.left^.left^.fflg

         end else begin { standard }

            regexp(rgflg, rgnull, ip^.left, tr);
            ip^.lreg := ip^.left^.freg; { place left from result }
            ip^.lflg := ip^.left^.fflg

         end

      end;

      tiwthbgn: begin

         regexp(rgnull, rgnull, ip^.left, tr); { record base address }
         ip^.lreg := ip^.left^.freg; { place left from result }
         getreg(ip^.t1reg, ip, tr); { get display register }
         remcxt(ip^.t1reg); { clear }
         { Placing a new with level could invalidate the record we were
           accessing. }
         remcxt(ip^.lreg);
         reglst(ip^.flow2) { process enclosed flow }

      end;

      tifortint, tifortchr, tifortbol, tifordint, tifordchr,
      tifordbol: begin

         quad := ip^.base^.size > regsiz; { set quad word index }
         if not (chkfncexp(ip^.left) or chkfncexp(ip^.right)) then begin

            regexp(rgnull, rgnull, ip^.right, tr); { end }
            ip^.rreg := ip^.right^.freg; { place right from result }
            ip^.rregx := ip^.right^.fregx;
            { check need to expand dword to qword }
            if quad and (ip^.right^.rbase^.size <= regsiz) then begin

               getreg(ip^.rregx, ip, tr); { get high half register }
               remcxt(ip^.rregx) { clear from context }

            end;
            regexp(rgnull, rgnull, ip^.left, tr); { start }
            ip^.lreg := ip^.left^.freg; { place left from result }
            ip^.lregx := ip^.left^.fregx;
            { check need to expand dword to qword }
            if quad and (ip^.left^.rbase^.size <= regsiz) then begin

               getreg(ip^.lregx, ip, tr); { get high half register }
               remcxt(ip^.lregx) { clear from context }

            end

         end else begin

            { possible side effects, process start and end in strict order }
            regexp(rgnull, rgnull, ip^.left, tr); { start }
            ip^.lreg := ip^.left^.freg; { place left from result }
            ip^.lregx := ip^.left^.fregx;
            { check need to expand dword to qword }
            if quad and (ip^.left^.rbase^.size <= regsiz) then begin

               getreg(ip^.lregx, ip, tr); { get high half register }
               remcxt(ip^.lregx) { clear from context }

            end;
            regexp(rgnull, rgnull, ip^.right, tr); { end }
            ip^.rreg := ip^.right^.freg; { place right from result }
            ip^.rregx := ip^.right^.fregx;
            { check need to expand dword to qword }
            if quad and (ip^.right^.rbase^.size <= regsiz) then begin

               getreg(ip^.rregx, ip, tr); { get high half register }
               remcxt(ip^.rregx) { clear from context }

            end

         end;
         { if the store operand ends up in edi or esi, and the target is byte,
           then we need another temp reg to move it to from the set
           eax, ebx, ecx, edx. This is because we can't store from edi or esi. }
         if (ip^.base^.size <> 4) and
            ((ip^.lreg = rgedi) or (ip^.lreg = rgesi)) then begin

            getregbs(ip^.t2reg, ip, tr); { get byte storeable register }
            remcxt(ip^.t2reg) { clear }

         end;
         getreg(ip^.t1reg, ip, tr); { get display register }
         remcxt(ip^.t1reg); { clear }
         clrcxt; { clear starting context }
         reglst(ip^.flow2); { for loop }
         clrcxt { clear ending context }

      end;

      ticasstb, ticasels: reglst(ip^.flow2); { case entry }

      titrybgn: begin

         reglst(ip^.flow2); { process protected block }
         clrcxt; { clear context for reentry from exception }
         reglst(ip^.flow3) { process exception clause list }

      end;

      titryexp: begin

         { place register where exception that was thrown goes }
         plcreg(rgeax, ip, tr);
         { get register for exception variable (used for compare only) }
         regexp(rgnull, rgnull, ip^.left, tr);
         ip^.lreg := ip^.left^.freg; { place left from result }
         reglst(ip^.flow2) { exception statement block }

      end;

      titryels: reglst(ip^.flow2) { process else statement block }

      { trap other cases }
      else error(esysflt102) { should not occur }

   end;
   regdiag(ip, false) { output diagnostic }

end; { regopr }

begin { regblk }

   curage := 1; { set starting context age }
   clrcxt; { clear register context }
   reglst(ip) { process operator list }

end; { regblk }

{*******************************************************************************

Create or find bounds check descriptor

A bounds descriptor is a fixed record with a 32 bit low and high entry, used by
the 'bound' instruction to provide bounds checking service. Given a low and high
bound, we search through the bounds check descriptor list, looking for a
compatible bound descriptor. If one is found, that is returned, otherwise a
new bounds check entry is created, and the fixed record type for it is created
in the current block.

Like all fixed types, the descriptor created can exist in any block, and be
deferrred to the constants section. This is why the descriptor can go into
any block, but be referenced from anywhere else.

Bounds descriptors need not be pinned to a specific type. Any bound descriptor
with the same bounds is usable.

Note: This routine uses the block stack, and so pretty much relies on the idea
that the block stack top is the block being encoded.

*******************************************************************************}

procedure getbnddes(var dp:   typptr; { returns bounds descriptor }
                        low:  ssint;  { low bound }
                        high: ssint); { high bound }

var bp, fp:            bndptr; { pointers to bounds entries }
    tp, tp1, tp2, tp3: typptr; { type builders }

begin

   { search for existing, compatible bounds descriptor }
   fp := nil; { set not found }
   bp := bndlst; { index top of list }
   while (bp <> nil) and (fp = nil) do begin { traverse }

      if ssequ(bp^.low, low) and ssequ(bp^.high, high) then fp := bp; { found }
      bp := bp^.next { next entry }

   end;
   bp := fp; { set entry found }
   if fp = nil then begin { not found, start a new entry }

      new(bp); { get a new bound entry }
      bp^.next := bndlst; { push onto list }
      bndlst := bp;
      bp^.low := low; { set bounds }
      bp^.high := high;
      { if the bounds base type does not exist, we need to create it }
      if bnddes = nil then begin

         { Form the bounds descriptor base type, a record with low and high
           integers. }
         gettypsys(tp, tinteger); { form the base integer }
         gettypsys(bnddes, trecord); { form the record }
         gettypsys(tp1, tfield); { get low field }
         bnddes^.recf := tp1; { link record to field }
         tp1^.fldh := bnddes; { link field to record }
         tp1^.fldt := tp; { link field to integer type }
         gettypsys(tp2, tfield); { get high field }
         tp1^.fldn := tp2; { link low to this }
         tp2^.fldn := nil; { clear high next }
         tp2^.fldh := bnddes; { link to head }
         tp2^.fldt := tp { link to integer }

      end;
      gettypsys(tp, treccst); { get record constant entry }
      gettypsys(tp1, treccel); { get low constant }
      gettypsys(tp2, ticst);
      tp2^.ival := low;
      tp1^.reec := tp2;
      tp^.recn := tp1; { link record constant to that }
      gettypsys(tp3, treccel); { get high constant }
      gettypsys(tp2, ticst);
      tp2^.ival := high;
      tp3^.reec := tp2;
      tp1^.reen := tp3; { link last constant to this }
      tp3^.reen := nil; { and terminate list }
      gettypsys(tp1, tfix); { get fixed type }
      tp1^.fixt := bnddes; { set base type }
      tp1^.fixc := tp; { set constant fill }
      tp1^.fixe := false; { set not external }
      tp1^.fixr := true; { set fixed was referenced }
      bp^.bnddes := tp1 { set fixed record for bounds descriptor }

   end;
   dp := bp^.bnddes { return bound we found }

end;

{*******************************************************************************

Print register name

Prints the name of a register. For listings.

*******************************************************************************}

procedure prtreg(r: regt);

begin

   case r of { register }

      rgnull: write('<none>');
      rgeax:  write('eax');
      rgebx:  write('ebx');
      rgecx:  write('ecx');
      rgedx:  write('edx');
      rgesi:  write('esi');
      rgedi:  write('edi');
      rgflg:  write('eflag');

   end

end;

{*******************************************************************************

Print flag name

Prints the name of a flag. For listings.

*******************************************************************************}

procedure prtflg(f: flag);

begin

   case f of { flag }

      flnull: ;
      fla:    write('a');
      flae:   write('ae');
      flb:    write('b');
      flbe:   write('be');
      flc:    write('c');
      fle:    write('e');
      flg:    write('g');
      flge:   write('ge');
      fll:    write('l');
      flle:   write('le');
      flna:   write('na');
      flnae:  write('nae');
      flnb:   write('nb');
      flnbe:  write('nbe');
      flnc:   write('nc');
      flne:   write('ne');
      flng:   write('ng');
      flnge:  write('nge');
      flnl:   write('nl');
      flnle:  write('nle');
      flno:   write('no');
      flnp:   write('np');
      flns:   write('ns');
      flnz:   write('nz');
      flo:    write('o');
      flp:    write('p');
      flpe:   write('pe');
      flpo:   write('po');
      fls:    write('s');
      flz:    write('z')

   end

end;

{*******************************************************************************

Find condition code for flag

Finds the 4 bit condition code corresponding to the given flag. This byte is
ored with the high 4 bits of the instruction code to find a conditional
instruction, as follows:

7x    - Jcc rel8
0f 8x - Jcc rel16/32
0f 9x - SETcc

*******************************************************************************}

function ccode(f: flag): byte;

var b: byte; { returns the code }

begin

   case f of { flag }

      flnull: error(esysflt103); { should not happen }
      fla:    b := $07;
      flae:   b := $03;
      flb:    b := $02;
      flbe:   b := $06;
      flc:    b := $02;
      fle:    b := $04;
      flg:    b := $0f;
      flge:   b := $0d;
      fll:    b := $0c;
      flle:   b := $0e;
      flna:   b := $06;
      flnae:  b := $02;
      flnb:   b := $03;
      flnbe:  b := $07;
      flnc:   b := $03;
      flne:   b := $05;
      flng:   b := $0e;
      flnge:  b := $0c;
      flnl:   b := $0d;
      flnle:  b := $0f;
      flno:   b := $01;
      flnp:   b := $0b;
      flns:   b := $09;
      flnz:   b := $05;
      flo:    b := $00;
      flp:    b := $0a;
      flpe:   b := $0a;
      flpo:   b := $0b;
      fls:    b := $08;
      flz:    b := $04

   end;
   ccode := b { return result }

end;

{*******************************************************************************

Convert dword register

Converts a dword register to a 3 bit code. Accepts a 32 bit general register.

*******************************************************************************}

function dreg(p: regt): byte;

var r: byte;

begin

   case p of

      rgnull: error(esysflt170); { should not happen }
      rgflg:  error(esysflt262); { should not happen }
      rgeax:  r := 0; { eax }
      rgebx:  r := 3; { ebx }
      rgecx:  r := 1; { ecx }
      rgedx:  r := 2; { edx }
      rgesi:  r := 6; { esi }
      rgedi:  r := 7  { edi }

   end;
   dreg := r

end;

{*******************************************************************************

Find signed index multiplier

Gives the ss code for a SIB modifier, based on the scaling number given. The
scaler must be 1, 2, 4, or 8.

*******************************************************************************}

function sib(i: integer): byte;

var b: byte;

begin

   if not (i in [1, 2, 4, 8]) then error(esysflt134); { bad scaling value }
   case i of { multiplier }

      1: b := $00; { * 1 }
      2: b := $40; { * 2 }
      4: b := $80; { * 4 }
      8: b := $c0  { * 8 }

   end;
   sib := b { return result }

end;

{*******************************************************************************

Generate random number

Generates a number between 1 and maxint. Random numbers are used for reverse
engineering counter-measure generation.

*******************************************************************************}

function rand: integer;

const a = 16807;
      m = 2147483647;

var gamma: integer;

begin

   gamma := a*(rndseq mod (m div a))-(m mod a)*(rndseq div (m div a));
   if gamma > 0 then rndseq := gamma else rndseq := gamma+m;
   rand := rndseq

end;

{*******************************************************************************

Create lock id for monitor

Checks if the monitor lock variable exists, and if not, it is created.

*******************************************************************************}

procedure creatlock;

begin

   if lockid = nil then begin

      { create a lock id variable in case this is a monitor }
      gettypsys(lockid, tvar); { get the type entry }
      lockid^.vart := gblint; { set integer }
      lockid^.vare := false; { set not external }
      lockid^.varr := true; { set referenced }
      lockid^.local := false; { set not local }
      lockid^.size := intsiz; { set size (sizing was already done) }

   end

end;

{*******************************************************************************

Generate task lock

Checks if the current block is a monitor, and generates a locking sequence if
so. The registers are saved.

*******************************************************************************}

procedure genlock;

begin

   if inmonitor then begin { generate lock sequence }

      creatlock; { make sure monitor lock exists }
      emitbyt($50+dreg(rgeax)); { push eax }
      emitbyt($8b); { mov eax,[lockid] }
      emitbyt($00+dreg(rgeax)*8+$05);
      emitadr(lockid, itadr); { output location of lock id }
      genrotcal(syslib_lock); { lock the variables }
      emitbyt($58+dreg(rgeax)) { pop eax }

   end

end;

{*******************************************************************************

Generate task unlock

Checks if the current block is a monitor, and generates a unlocking sequence if
so. The registers are saved.

*******************************************************************************}

procedure genunlock;

begin

   if inmonitor then begin { generate lock sequence }

      creatlock; { make sure monitor lock exists }
      emitbyt($50+dreg(rgeax)); { push eax }
      emitbyt($8b); { mov eax,[lockid] }
      emitbyt($00+dreg(rgeax)*8+$05);
      emitadr(lockid, itadr); { output location of lock id }
      genrotcal(syslib_unlock); { unlock the variables }
      emitbyt($58+dreg(rgeax)) { pop eax }

   end

end;

{*******************************************************************************

Generate routine call

Generates a call to the given routine.

*******************************************************************************}

procedure genrotcal(rp: typptr);

begin

   { if the target routine is not one of the lock excepted routines, generate
     an unlock sequence for monitors }
   if (rp <> syslib_lock) and (rp <> syslib_unlock) and (rp <> syslib_wait) and
      (tp <> syslib_newlock) and (rp <> syslib_displock) and
      (rp <> syslib_signal) and (rp <> syslib_signalone) then
      genunlock;
   emitbyt($e8); { call routine }
   emitadr(rp, itradr); { output routine address }
   rp^.rotr := true; { set referenced }
   { if the target routine is not one of the lock excepted routines, generate
     a lock sequence for monitors }
   if (rp <> syslib_lock) and (rp <> syslib_unlock) and (rp <> syslib_wait) and
      (tp <> syslib_newlock) and (rp <> syslib_displock) and
      (rp <> syslib_signal) and (rp <> syslib_signalone) then
      genlock

end;

{*******************************************************************************

Generate FPU error check

Loads the FPU status word into eax, then checks if any of the exception bits are
on. If they are, a call is made to maclib_fpuerr, which sorts out the different
error bits.

*******************************************************************************}

procedure genfpuchk;

begin

   if ffputrp then begin { perform FPU error check }

      emitbyt($50+dreg(rgeax)); { push eax }
      { load the current FPU status into eax }
      emitbyt($df); { fnstsw ax }
      emitbyt($e0);
      { check any exception flag is on but precision, which can happen during
        normal operations }
      emitbyt($66); { test ax,fpuexe }
      emitbyt($a9);
      emitwrd(fpuexe);
      emitbyt($74); { jz over }
      emitbyt(5); { relative jump over error call }
      genrotcal(maclib_fpuerr); { call error }
      emitbyt($58+dreg(rgeax)) { pop eax }

   end

end;

{*******************************************************************************

Generate disassembly trip

Generates a disassembly "tripper", which is a random sequence that corresponds
to a long instruction. Only the first part of the instruction is output, which
will cause disassemblers to "trip", or misinterpret one or more instructions
after that.

Disassembly trips can be used whenever the generated code is not actually
executed, such as just after any unconditional jumps or a return.

*******************************************************************************}

procedure gendistrp;

begin

   if frevengcm then begin { enable counter-measures }

      if fdiscm then begin { generate the trip }

         { generate the head of a mov r/32,imm32, a very long instruction }
         case rand mod 10 of { different prefixes }

            0: begin emitbyt($c7); emitbyt($80+0*8+$04) end; { mov }
            1: begin emitbyt($81); emitbyt($80+0*8+$04) end; { add }
            2: begin emitbyt($81); emitbyt($80+4*8+$04) end; { and }
            3: begin emitbyt($81); emitbyt($80+2*8+$04) end; { adc }
            4: begin emitbyt($81); emitbyt($80+7*8+$04) end; { cmp }
            5: begin emitbyt($81); emitbyt($80+1*8+$04) end; { or }
            6: begin emitbyt($81); emitbyt($80+3*8+$04) end; { sbb }
            7: begin emitbyt($81); emitbyt($80+5*8+$04) end; { sub }
            8: begin emitbyt($f7); emitbyt($80+0*8+$04) end; { test }
            9: begin emitbyt($81); emitbyt($80+6*8+$04) end; { xor }

         end
         { now the sib, the displacement, and the imm32, 9 bytes of crud, will
           all be parsed by the disassembler }

      end

   end

end;

{*******************************************************************************

Generate "skippy" disassembly trip

To create more disassembly trips, we jump over a disassembly trip. This is
a non-destructive operation that can be placed anywhere.

Note that we assume a 2 byte disassembly trip.

*******************************************************************************}

procedure gendisskp;

begin

   if frevengcm then begin { enable counter-measures }

      if fdiscm then begin { generate the trip }

         emitbyt($eb); { jmp over }
         emitbyt(2); { relative jump over error call }
         gendistrp { generate disassembly trip }

      end

   end

end;

{*******************************************************************************

Generate 'with' base load

A 'with' base is a variable that holds the partially resolved base address of
a record, which is used to finish 'with' offset calculations. Given a field
type, the nearest encompassing 'with' active with a field that matches is
found, then the 'with' base is fetched to the given register.

*******************************************************************************}

procedure lodwth(ft: typptr; { field type }
                 r:  regt);  { register to load to }

var wthvar: typptr; { 'with' variable base pointer }

begin

   fndwth(ft, wthvar); { get 'with' base address variable }
   { Process load of base variable. Note that we only have to worry about
     a base variable local to this routine, because thats where with stores
     it. }
   if wthvar^.local then begin { local var }

      emitbyt($8b); { mov r,addr[ebp] }
      emitbyt($80+dreg(r)*8+$05);
      emitadr(wthvar, itadr) { place address }

   end else begin { global var }

      { get the temp var holding with }
      emitbyt($8b); { mov r,[addr] }
      emitbyt($00+dreg(r)*8+$05);
      emitadr(wthvar, itadr) { place address }

   end;

end;

{*******************************************************************************

Generate display load

Generates a display load for the local given in the passed operator node.
The display is loaded into the node register. Will do nothing in the case of
a local in the current frame. A return parameter gives the code for the base
register so formed, which for a current block local, is the ebp register.
The displacement to get the display value is optimized for byte. Since 64
display levels can be reached this way, this is the most common display load.

The register won't be required if the reference is to the current block, but
if it is required, and it is not defined (rgnull), a system fault results.

*******************************************************************************}

procedure gendslr(    bp: typptr;   { base type }
                      r:  regt;     { register to load to }
                  var sr: integer); { returns base register code }

begin

   sr := $05; { set ebp as offset register }
   if bp^.level <> blkcnt then begin

      if r = rgnull then error(esysflt152); { must have a register }
      { must get a stored ebp from the display }
      emitbyt($8b); { mov x,[ebp-lvl] }
      { offset to proper display level }
      if sbyte(-((bp^.level-1)*4)) then begin

         emitbyt($40+dreg(r)*8+$05);
         emitbyt(-((bp^.level-1)*4))

      end else begin

         emitbyt($80+dreg(r)*8+$05);
         emitint(-((bp^.level-1)*4))

      end;
      sr := dreg(r) { now set that as base register }

   end

end;

{*******************************************************************************

Generate direct address instruction

Generates a one or two byte instruction with a direct address, either a local
or global. Takes the base of the address type, the instruction bytes, the valid
flags for the bytes, and an offset.

*******************************************************************************}

procedure gendirr(bp:  typptr;   { base type }
                  dr:  regt;     { display/address working register }
                  tr:  byte;     { target register (base code) }
                  i1:  byte;     { instruction byte 1 }
                  v1:  boolean;  { valid flag 1 }
                  i2:  byte;     { instruction byte 2 }
                  v2:  boolean;  { valid flag 2 }
                  off: integer); { offset from address }

var sr: integer; { register code save }

begin

   if (bp^.t = tfield) or (bp^.t = tftag) then begin { 'with' field reference }

      lodwth(bp, dr); { load the 'with' base variable to the reg }
      { now we have an offset left to perform, but this can be placed into the
        offset of an r/m }
      if v1 then emitbyt(i1); { emit instruction bytes as applicable }
      if v2 then emitbyt(i2);
      emitbyt($80+tr*8+dreg(dr)); { generate r/m byte }
      emitadro(bp, itadr, off) { place offset }

   end else if bp^.local then begin { local address }

      gendslr(bp, dr, sr); { generate display load }
      if v1 then emitbyt(i1); { emit instruction bytes as applicable }
      if v2 then emitbyt(i2);
      emitbyt($80+tr*8+sr);
      emitadro(bp, itadr, off) { place address dword }

   end else begin { global address }

      if v1 then emitbyt(i1); { emit instruction bytes as applicable }
      if v2 then emitbyt(i2);
      emitbyt($00+tr*8+$05); { generate r/m byte }
      if off = 0 then emitadr(bp, itadr) { place address }
      else emitadro(bp, itadr, off) { place address with offset }

   end

end;

{*******************************************************************************

Generate direct address instruction for single byte instruction

This is gendir for a single byte instruction.

*******************************************************************************}

procedure gendir1r(bp:  typptr;   { base type }
                   dr:  regt;     { display/address working register }
                   tr:  byte;     { target register (base code) }
                   ins: byte;     { instruction byte }
                   off: integer); { offset from address }

begin

   { generate single byte instruction }
   gendirr(bp, dr, tr, $00, false, ins, true, off)

end;

{*******************************************************************************

Generate direct address instruction for double byte instruction

This is gendir for a double byte instruction.

*******************************************************************************}

procedure gendir2r(bp:   typptr;   { base type }
                   dr:   regt;     { display/address working register }
                   tr:   byte;     { target register (base code) }
                   ins1: byte;     { instruction byte 1 }
                   ins2: byte;     { instruction byte 2 }
                   off:  integer); { offset from address }

begin

   { generate double byte instruction }
   gendirr(bp, dr, tr, ins1, true, ins2, true, off)

end;

{*******************************************************************************

Generate address load

Generates an address load given an operand node. If the operand is a local,
it is either directly offset from ebp, or a stored ebp from the frame's
display is fetched and offset. If it is global, the address is loaded directly.

*******************************************************************************}

procedure genladr(r:  regt; { register to load to }
                  vt: typptr); { varible to load }

begin

   { check pointer to temp }
   if ((vt^.t = tpar) or (vt^.t = twpar)) and not tgpt(vt) then begin

      { parameter, and not tgp }

      if chkext(vt) then
         { its an extended parameter, address to temp }
         gendir1r(vt, r, dreg(r), $8b, 0) { mov x,[addr] }
      else
         { otherwise, get the address of }
         gendir1r(vt, r, dreg(r), $8d, 0) { lea x,[addr] }

   end else { is direct addressed object }
      gendir1r(vt, r, dreg(r), $8d, 0) { lea x,[addr] }

end;

{*******************************************************************************

Generate variable load with size and offset

Generates an variable load given an operand node. If the operand is a local,
it is either directly offset from ebp, or a stored ebp from the frame's
display is fetched and offset. If it is global, it is loaded directly.
The size, byte, word or dword is specified, as is an offset from the base to
load from. This is used to pick apart sets and perhaps packed structures.

*******************************************************************************}

procedure genlodsor(r:   regt;     { register to process }
                    vt:  typptr;   { variable type }
                    sz:  integer;  { size to load }
                    off: integer); { offset }

var ins1, ins2: byte; { instruction bytes }

{ make instruction code }

procedure makins;

begin

   if sz = regsiz then begin { use standard load }

      ins1 := $00; { set no 1st byte }
      ins2 := $8b { mov r,[addr] }

   end else begin { extended load }

      { movsx or movzx }
      ins1 := $0f; { set 1st byte }
      if sz = 2 then ins2 := $b7 { word }
      else if sz = 1 then ins2 := $b6 { byte }
      else error(einvfmt); { invalid format }
      { set movsx for signed }
      if chksgn(vt) then ins2 := ins2+$08

   end

end;

begin

   makins; { create instruction code }
   if ins1 = $00 then gendir1r(vt, r, dreg(r), ins2, off) { generate single }
   else gendir2r(vt, r, dreg(r), ins1, ins2, off) { generate double }

end;

{*******************************************************************************

Generate tagged pointer load direct

Generates a load of a tagged pointer from local or global store. r gives the
base addres, and rx gives the length.

*******************************************************************************}

procedure genlodtpr(r, rx: regt; { register to load to }
                       vt: typptr); { variable type }

begin

   gendir1r(vt, r, dreg(r), $8b, 0); { load address }
   gendir1r(vt, rx, dreg(rx), $8b, ptrsiz) { load length }

end;

{*******************************************************************************

Generate tagged pointer store direct

Generates a store of a tagged pointer to local or global store. r gives the
base address, and rx gives the length.

*******************************************************************************}

procedure genstotpr(dr:      regt;    { display working register }
                    tr, trx: regt;    { register to load to }
                    vt:      typptr); { variable type }

begin

   gendir1r(vt, dr, dreg(tr), $89, 0); { store address }
   gendir1r(vt, dr, dreg(trx), $89, ptrsiz) { store length }

end;

{*******************************************************************************

Generate variable store with size and offset

Generates an variable store given an operand node for the source, a base for the
destination, a size and an offset. If the operand is a local, it is either
directly offset from ebp, or a stored ebp from the frame's display is fetched
and offset. If it is global, it is stored directly.
The size, byte, word or dword is specified, as is an offset from the base to
store to.

*******************************************************************************}

procedure genstosor(dr:  regt;     { display working register }
                    tr:  byte;     { register to store (base code) }
                    vt:  typptr;   { variable type }
                    sz:  integer;  { size to store }
                    off: integer); { offset }

begin

   if sz = dwdsiz then { dword }
      gendir1r(vt, dr, tr, $89, off) { mov [addr],dr }
   else if sz = wrdsiz then { word }
      gendir2r(vt, dr, tr, $66, $89, off) { mov [addr],wr }
   else { byte }
      gendir1r(vt, dr, tr, $88, off) { mov [addr],br }

end;

{*******************************************************************************

Generate direct store immediate

Stores an immediate value to the variable. Handles byte, word, dword and qword
sizes.

*******************************************************************************}

procedure genstoimmr(dr:  regt;     { display working register }
                     vt:  typptr;   { variable type }
                     sz:  integer;  { size to store }
                     i:   ssint);   { immediate }

begin

   if sz = qwdsiz then begin { qword }

      gendir1r(vt, dr, $00, $c7, 0); { mov [addr],dr }
      emitint(i);
      gendir1r(vt, dr, $00, $c7, regsiz); { mov [addr],dr }
      { we can't emit a true 64 bit constant, so just sign extend the 32 bit
        constant. }
      if i.s then emitint(-1) else emitint(0)

   end else begin

      if sz = dwdsiz then { dword }
         gendir1r(vt, dr, $00, $c7, 0) { mov [addr],dr }
      else if sz = wrdsiz then { word }
         gendir2r(vt, dr, $00, $66, $c7, 0) { mov [addr],wr }
      else { byte }
         gendir1r(vt, dr, $00, $c6, 0); { mov [addr],br }
      if sz = bytsiz then emitbyt(i) { output single byte constant }
      else if sz = wrdsiz then emitwrd(i) { output word constant }
      else emitint(i) { output dword constant }

   end

end;

{*******************************************************************************

Generate real load/short real load

Generates a real or short real load from the local or global address.
A local is offset from ebp, with a displacement optimized to byte. A global is
just loaded indirect.

If the reference is not a 'with' offset, or a local referring to another block,
the register is not used. Otherwise it must be present to load 'with' base
addresses or display pointers into. If a register is required, and none is
provided (rgnull), then a system fault will result.

*******************************************************************************}

procedure genlodrel(r:  regt;    { register for display loads }
                    vt: typptr); { variable type }

var sr:  integer; { base register code }
    ins: byte;    { instruction byte }

begin

   if vt^.size = srlsiz then ins := $d9 { flds x }
   else ins := $dd; { fldd x }
   if (vt^.t = tfield) or (vt^.t = tftag) then begin { 'with' field reference }

      if r = rgnull then error(esysflt150); { must have a register }
      lodwth(vt, r); { load the 'with' base variable to the reg }
      emitbyt(ins); { output 1st instruction byte }
      emitbyt($80+$00*8+sr); { output r/m byte }
      emitadr(vt, itadr) { place address dword }

   end else if vt^.local then begin { local address }

      if chkext(vt) then begin { extended real load }

         gendslr(vt, r, sr); { generate display load }
         emitbyt($8b); { mov r,addr }
         emitbyt($80+dreg(r)*8+sr); { generate r/m byte }
         emitadr(vt, itadr); { place address dword }
         emitbyt(ins); { output 1st instruction byte }
         emitbyt($00+$00*8+dreg(r)) { output r/m byte }

      end else begin

         gendslr(vt, r, sr); { generate display load }
         emitbyt(ins); { output 1st instruction byte }
         emitbyt($80+$00*8+sr); { output r/m byte }
         emitadr(vt, itadr) { place address dword }

      end

   end else begin { global address }

      emitbyt(ins); { output 1st instruction byte }
      emitbyt($00+$00*8+$05); { generate r/m byte }
      emitadr(vt, itadr) { place address }

   end;
   genfpuchk { perform fpu check }

end;

{*******************************************************************************

Generate real/short real store

Generates a real or short real store from the local or global address.
A local is offset from ebp, with a displacement optimized to byte. A global is
just loaded indirect.

If the reference is not a 'with' offset, or a local referring to another block,
the register is not used. Otherwise it must be present to load 'with' base
addresses or display pointers into. If a register is required, and none is
provided (rgnull), then a system fault will result.

*******************************************************************************}

procedure genstorel(r:  regt;    { register for display loads }
                    vt: typptr); { variable type }

var ins: byte;    { instruction code }
    sr:  integer;

begin

   if vt^.size = srlsiz then ins := $d9 { fstps x }
   else ins := $dd; { fstpd x }
   if (vt^.t = tfield) or (vt^.t = tftag) then begin { 'with' field reference }

      if r = rgnull then error(esysflt151); { must have a register }
      lodwth(vt, r); { load the 'with' base variable to the reg }
      emitbyt(ins); { output 1st instruction byte }
      emitbyt($80+$03*8+sr); { output r/m byte }
      emitadr(vt, itadr) { place address dword }

   end else if vt^.local then begin { local address }

      gendslr(vt, r, sr); { generate display load }
      if chkext(vt) then begin { extended real load }

         emitbyt($8b); { mov r,addr }
         emitbyt($00+dreg(r)*8+dreg(r)) { generate r/m byte }

      end;
      emitbyt(ins); { output 1st instruction byte }
      emitbyt($80+$03*8+sr); { output r/m byte }
      emitadr(vt, itadr) { place address dword }

   end else begin { global address }

      emitbyt(ins); { output 1st instruction byte }
      emitbyt($00+$03*8+$05); { generate r/m byte }
      emitadr(vt, itadr) { place address }

   end;
   genfpuchk { perform fpu check }

end;

{*******************************************************************************

Generate compare immediate

Generates an efficient compare immediate for the given register.

*******************************************************************************}

procedure gencmpi(r: regt;   { register to process }
                  i: ssint); { immediate compare value }

begin

   { if the register is eax, and not a single byte, we use a special
     instruction for that }
   if (r = rgeax) and not sbyte(i) then begin

      emitbyt($3d); { cmp eax,imm32 }
      emitint(ss2int(i))

   end else begin { not eax }

      { cmp x,n }
      if sbyte(i) then begin

         emitbyt($83); { cmp x,imm8 }
         emitbyt($c0+$07*8+dreg(r));
         emitbyt(ss2int(i))

      end else begin

         emitbyt($81); { cmp x,imm32 }
         emitbyt($c0+$07*8+dreg(r));
         emitint(ss2int(i))

      end

   end

end;

{*******************************************************************************

Generate error call

Generates a call to the error routine. Accepts the error code to use as a
parameter.

*******************************************************************************}

procedure generr(errcod: rerrcod); { error code }

begin

   { generate error routine call }
   emitbyt($b8); { mov eax,errcod }
   emitint(ord(errcod));
   genrotcal(paslib_error) { call error }

end;

{*******************************************************************************

Generate skip error call

Generates a skip over jump, followed by a call to the error routine.
The jump instruction is a 2 byte relative.

*******************************************************************************}

procedure genske(jmpins: byte;     { jump instruction byte }
                 errcod: rerrcod); { error code }

var lab: typptr;

begin

   gettypa(lab, tlab); { get a loop label }
   emitbyt(jmpins); { jxx over }
   emitadr(lab, itbradr); { place jump over address }
   generr(errcod); { generate error routine call }
   lab^.addr := pgmcnt { set skip address }

end;

{*******************************************************************************

Generate overflow check

Generates a check if the overflow bit is set. Either routes this to int trap, or
generates an error routine call depending on fcustrp. Overflow checks are used
for signed integer handling.

If fovfchk is not true, this routine is a no op.

*******************************************************************************}

procedure genovf;

begin

   if fovfchk then begin { overflow checking is on }

      if fcustrp then { generate a custom trap }
         emitbyt($ce) { into }
      else genske($71, rerngchk) { generate error call }

   end

end;

{*******************************************************************************

Generate carry check

Generates a check if the carry bit is set. Either routes this to int trap, or
generates an error routine call depending on fcustrp. Carry checks are used for
unsigned integer handling.

If fovfchk is not true, this routine is a no op.

*******************************************************************************}

procedure gencar;

begin

   if fovfchk then begin { overflow checking is on }

      if fcustrp then begin { generate a custom trap }

         { The x86 trap is designed for signed overflows only. We generate a
           custom sequence to trip it on carry. This is another good reason
           not to use the CPU built in trap. }
         emitbyt($73); { jnc over - skip if no trap }
         emitbyt(2);
         emitbyt($cd); { int 4 }
         emitbyt($04)

      end else genske($73, rerngchk) { generate error call }

   end

end;

{*******************************************************************************

Generate sign check

Generates a check if the sign bit is set. Either routes this to int trap, or
generates an error routine call depending on fcustrp. Sign checks are used for
unsigned integer handling.

If fovfchk is not true, this routine is a no op.

*******************************************************************************}

procedure gensgn;

begin

   if fovfchk then begin { overflow checking is on }

      if fcustrp then begin { generate a custom trap }

         { The x86 trap is designed for signed overflows only. We generate a
           custom sequence to trip it on carry. This is another good reason
           not to use the CPU built in trap. }
         emitbyt($79); { jns over - skip if no trap }
         emitbyt(2);
         emitbyt($cd); { int 4 }
         emitbyt($04)

      end else genske($79, rerngchk) { generate error call }

   end

end;

{*******************************************************************************

Generate sign check in register

Checks if the sign is set in the indicated register, then generates a sign
check error. This routine is used to verify both signed->unsigned and
unsigned->signed moves, because the sign bit should be zero in either case.

*******************************************************************************}

procedure gensgnchk(r: regt);

begin

   { get sign of operand }
   emitbyt($0b); { orl x,y }
   emitbyt($c0+dreg(r)*8+dreg(r));
   gensgn { generate sign check }

end;

{*******************************************************************************

Generate bounds check

Given a register, generates a bounds check for the value in the register. There
are two bounds check modes. First, we can use the bounds check instruction
provided in the CPU. This is done if custom trapping is on. The second method
is to use two compares and a call to the error routine.

A third method, not done here, is to first subtract the base, then compare to
the high limit only. That works because any value range can be bounded against
zero (it essentially folds the base adjust and compare together).

The bounds instruction is rapidly being depreciated in the x86 instruction
set, and is limited to signed mode only checking.

We accept quad precision arguments. In this case, the quad precision flag
must be set.

Note that we can also drop the first (base) check of a handrolled bounds
compare if the base is in fact zero. This is not done on the trap version.

Note also that the bounds instruction requires templetes be placed in constant
store for it to reference.

Note finally that the value must already be processed into a register.

Note that the base of the node must address the descriptor for the type.

*******************************************************************************}

procedure genbndr(signed:    boolean; { signed/unsigned status }
                  r, rx:     regt;    { register to check }
                  quad:      boolean; { quad precision }
                  low, high: ssint);  { bounds to check against }

var bd:          typptr; { bounds descriptor }
    lowx, highx: ssint;  { high half of bounds }

{ find length of compare immediate for index }

function lencmp(r: regt; i: ssint): integer;

var l: integer;

begin

   if (r = rgeax) and not sbyte(i) then l := 5
   else if sbyte(i) then l := 3
                    else l := 6;

   lencmp := l { return result }

end;

{ find upper half of signed constant }

procedure upsgn(var dc, sc: ssint);

begin

   if sc.s then begin

      dc.v := 1; { set -1 }
      dc.s := true

   end else begin

      dc.v := 0; { set 0 }
      dc.s := false

   end

end;

begin

   if fbndins and signed and not quad then begin { use bounds instruction }

      { find or create bounds descriptor }
      getbnddes(bd, low, high);
      { generate bounds check instruction }
      emitbyt($62); { bound x,[arrbnd] }
      emitbyt($00+dreg(r)*8+$05);
      emitadr(bd, itadr) { place address }

   end else begin { use normal (handrolled) bounds check }

      if signed then begin { perform signed mode check }

         if ssnequ(low, false, 0) then begin { generate low/high check }

            if ssnequ(high, false, mmaxint) then begin

               if quad then begin { quadword precision }

                  upsgn(lowx, low); { create upper half low value }
                  upsgn(highx, high); { create upper half high value }

                  { check high half of low first }
                  gencmpi(rx, lowx); { check upper half is lower }
                  emitbyt($7c); { jl error }
                  { relative jump to error call }
                  emitbyt(2+lencmp(r, low)+2+lencmp(rx, highx)+2+2+lencmp(r, high)+2);
                  { if upper half not equal }
                  emitbyt($75); { jne next }
                  emitbyt(lencmp(r, low)+2);
                  gencmpi(r, low); { generate low bound check }
                  emitbyt($7c); { jl error }
                  { relative jump to error call }
                  emitbyt(lencmp(rx, highx)+2+2+lencmp(r, high)+2);

                  { check high half of high first }
                  gencmpi(rx, highx); { check upper half is higher }
                  emitbyt($7f); { jg error }
                  { relative jump to error call }
                  emitbyt(2+lencmp(r, high)+2);
                  { if upper half not equal }
                  emitbyt($75); { jne no error }
                  emitbyt(lencmp(r, high)+12); { compare immediate plus jump }
                  gencmpi(r, high); { generate high bound check }
                  genske($7e, rerngchk) { generate error call }

               end else begin { dword precision }

                  gencmpi(r, low); { generate low bound check }
                  emitbyt($7c); { jl error }
                  { relative jump to error call }
                  emitbyt(lencmp(r, high)+2); { compare immediate plus jump }
                  gencmpi(r, high); { generate high bound check }
                  genske($7e, rerngchk) { generate error call }

               end

            end else begin

               { Just compare against the single low limit. Note that
                 2's complement can have values lower than -maxint,
                 so we check regardless. }
               if quad then begin { quad precision }

                  upsgn(lowx, low); { create upper half low value }
                  { check high half first }
                  gencmpi(rx, lowx); { check upper half is lower }
                  emitbyt($7c); { jl error }
                  { relative jump to error call }
                  emitbyt(lencmp(r, low)+2+2); { compare immediate plus 2 jumps }
                  { if upper half not equal }
                  emitbyt($75); { jne over }
                  emitbyt(lencmp(r, low)+12); { compare immediate plus genske }
                  gencmpi(r, low); { generate high bound check }
                  genske($7d, rerngchk) { generate error call }

               end else begin { dword precision }

                  gencmpi(r, low); { generate high bound check }
                  genske($7d, rerngchk) { generate error call }

               end

            end

         end else begin { bound against 0 }

            { Note that the range 0..maxint is not a no-op, since it checks
              negative values. }
            if quad then begin { quad precision }

               upsgn(highx, high); { create upper half high value }
               { check high half first }
               gencmpi(rx, highx); { check above upper half }
               emitbyt($77); { ja error }
               { relative jump to error call }
               emitbyt(lencmp(r, high)+2+2); { compare immediate plus 2 jumps }
               { if upper half not equal }
               emitbyt($75); { jne over }
               emitbyt(lencmp(r, high)+12); { compare immediate plus genske }
               gencmpi(r, high); { generate high bound check }
               genske($76, rerngchk) { generate error call }

            end else begin { dword precision }

               gencmpi(r, high); { generate high bound check }
               genske($76, rerngchk) { generate error call }

            end

         end

      end else begin { perform unsigned mode check }

         { check low <> 0 }
         if ssnequ(low, false, 0) then begin { generate low/high check }

            { check is max cardinal }
            if ssnequ(high, false, mmaxcard) then begin

               { no, use high/low check }
               if quad then begin { quadword precision }

                  upsgn(lowx, low); { create upper half low value }
                  upsgn(highx, high); { create upper half high value }

                  { check high half of low first }
                  gencmpi(rx, lowx); { check upper half is lower }
                  emitbyt($72); { jb error }
                  { relative jump to error call }
                  emitbyt(2+lencmp(r, low)+2+lencmp(rx, highx)+2+2+lencmp(r, high)+2);
                  { if upper half not equal }
                  emitbyt($75); { jne next }
                  emitbyt(lencmp(r, low)+2);
                  gencmpi(r, low); { generate low bound check }
                  emitbyt($72); { jb error }
                  { relative jump to error call }
                  emitbyt(lencmp(rx, highx)+2+2+lencmp(r, high)+2);

                  { check high half of high first }
                  gencmpi(rx, highx); { check upper half is higher }
                  emitbyt($77); { ja error }
                  { relative jump to error call }
                  emitbyt(2+lencmp(r, high)+2);
                  { if upper half not equal }
                  emitbyt($75); { jne no error }
                  emitbyt(lencmp(r, high)+12); { compare immediate plus jump }
                  gencmpi(r, high); { generate high bound check }
                  genske($76, rerngchk) { generate error call }

               end else begin { dword precision }

                  gencmpi(r, low); { generate low bound check }
                  emitbyt($72); { jc error }
                  { relative jump to error call }
                  emitbyt(lencmp(r, high)+2);
                  gencmpi(r, high); { generate high bound check }
                  genske($76, rerngchk) { generate error call }

               end

            end else begin

               { yes, just check against 0 }
               if quad then begin { quadword precision }

                  upsgn(lowx, low); { create upper half low value }
                  { check high half first }
                  gencmpi(rx, lowx); { check upper half is lower }
                  emitbyt($72); { jb error }
                  { relative jump to error call }
                  emitbyt(lencmp(r, low)+2+2); { compare immediate plus 2 jumps }
                  { if upper half not equal }
                  emitbyt($75); { jne over }
                  emitbyt(lencmp(r, low)+12); { compare immediate plus genske }
                  gencmpi(r, low); { generate high bound check }
                  genske($73, rerngchk) { generate error call }

               end else begin { dword precision }

                  gencmpi(r, low); { generate high bound check }
                  genske($73, rerngchk) { generate error call }

               end

            end

         end else if ssnequ(high, false, mmaxcard) then begin

            { bound against 0 }
            if quad then begin { quadword precision }

               upsgn(highx, high); { create upper half high value }
               { check high half first }
               gencmpi(rx, highx); { check above upper half }
               emitbyt($77); { ja error }
               { relative jump to error call }
               emitbyt(lencmp(r, high)+2+2); { compare immediate plus 2 jumps }
               { if upper half not equal }
               emitbyt($75); { jne over }
               emitbyt(lencmp(r, high)+12); { compare immediate plus genske }
               gencmpi(r, high); { generate high bound check }
               genske($76, rerngchk) { generate error call }

            end else begin { dword precision }

               gencmpi(r, high); { generate high bound check }
               genske($76, rerngchk) { generate error call }

            end

         end
         { Otherwise the bound is 0..maxcard on an unsigned, which is a no-op. }

      end

   end

end;

{*******************************************************************************

Generate transfer bounds check

Generates a general purpose transfer bounds check. Accepts the source and
destination types and the register to check, and generates an optimized bounds
check based on that.

The bounds check is the same as a normal bounds check, except that the sign
matching status is considered. First, if the range is negative only, then the
entire check is replaced with an error, since either signed -> unsigned or
signed -> unsigned would fail if the range is negative.

Second, if the lower bound is negative, then the bound straddles 0, as in
-..+. In either signed -> unsigned or unsigned -> signed, the negative part of
the bound is excluded. In this case, the lower bound is replaced with 0.

There is no case where a bounds check does not have to consider both the type
it is being checked against, as well as the type of the result to be placed
placed there. The separation of genbndxfr is a leftover from the days when
only integer types existed.

*******************************************************************************}

procedure genbndxfr(dp:     typptr; { destination type }
                    sp:     typptr; { source type }
                    r, rx:  regt);  { register to check }

var ss: boolean; { signed status of source }
    ds: boolean; { signed status of destination }
    bc: boolean; { perform bounds check }
    lb: ssint;   { lower bound holding }
    ub: ssint;   { upper bound holding }
    tp: typptr;  { type holding }

begin

   { Perform check if range checking is on }
   if frngchk then begin

      { get sign statuses }
      ss := chksgn(sp);
      ds := chksgn(dp);
      bc := true; { set perform bounds check }
      { generate bounds check }
      tp := basest(dp); { get base type of parameter w/subs }
      lb.v := lbound(tp); { load the bounds }
      lb.s := lbounds(tp);
      ub.v := ubound(tp);
      ub.s := ubounds(tp);
      { Now check signs of source and destination are different. If they aren't
        different, we don't need to modify the bounds. }
      if ss <> ds then begin

         { The code following won't work if the bounds are not rational, so
           push a fault if not. }
         if ssltn(ub, lb) then error(esysflt118);
         { If the signs are different, it means transferring an unsigned
           to signed or signed to unsigned. In either case, it is bad if the
           source has a sign. }
         if ub.s then begin

            { The destination is a negative only type. This is effectively a
              compile time error, but we pass it on to the code to fault
              there. }
            generr(rerngchk); { generate error routine call }
            bc := false { don't generate the bounds check (inflates code) }

         end else
            { check lower bound is negative }
            if lb.s then begin

               { If the lower bound is negative, the destination type straddles
                 a negative to positive range. If the source is unsigned, then
                 negative values are actually > maxint. If the source is signed,
                 negative values should be rejected. In any case, the right
                 answer is to truncate the negative bound to 0 so that the bound
                 becomes 0..N. }
               lb.v := 0;
               lb.s := false

            end

      end;
      { if bound check was not already done, generate it }
      if bc then genbndr(ds, r, rx, sp^.size > regsiz, lb, ub)

   end

end;

{*******************************************************************************

Generate pointer nil check

If the pointer dereference check flag is on, generates a pointer check on the
given register.

*******************************************************************************}

procedure genpchk(r: regt);

begin

   if fnilptr then begin { perform zero pointer check }

      emitbyt($0b); { or r,r }
      emitbyt($c0+dreg(r)*8+dreg(r));
      genske($75, renpdref) { generate nil deref fault }

   end

end;

{*******************************************************************************

Generate dword to qword extend

Extends a 32 bit value in a single dword register to a 64 bit value in two
registers. Expects the low order register, the high order register, and the
signed or unsigned status of the value. According to the signed status, the
value in the low register is either zero extended or sign extended into the high
register.

*******************************************************************************}

procedure genext(sgn:   boolean; { signed type }
                 r, rx: regt);   { lower and upper registers }

begin

   if sgn then begin { signed extention }

      { copy low half to high }
      emitbyt($8b); { mov rx,r }
      emitbyt($c0+dreg(rx)*8+dreg(r));
      { shift high bit (sign bit) to cover all bits of high, and
        effectively sign extend the result. }
      emitbyt($c1); { shr r,imm }
      emitbyt($c0+7*8+dreg(rx));
      emitbyt(31) { 31 steps to clear or set register }

   end else begin { unsigned extention }

      { clear high bits }
      emitbyt($33); { xor r,r }
      emitbyt($c0+dreg(rx)*8+dreg(rx))

   end

end;

{*******************************************************************************

Perform doi instruction with immediate

Performs one of the following instructions with an immediate operand:

Opr   1st ins   2nd ins     Notes
==========================================================================
add   $00 (add) $10 (adc)
and   $20 (and) $20 (and)
cmp   $38 (cmp) $18 (sbc)   Destructive to the high order dword for double
or    $08 (or)  $08 (or)
sub   $28 (sub) $18 (sbc)
xor   $30 (xor) $30 (xor)

You must pass in the above instruction codes, give the registers used for both
the source and the destination of the operation, if the operation is double
precision, what constant is to be used at the right side, if the operation
is to be checked for overflow, and if the operation is to be carried out as
signed or unsigned.

The operation is performed differently depending on if the right operand is
in eax, and if the constant fits in a signed byte. Also, adds and subs are
performed with inc/decs to save code if appropriate.

Note that the zero immediate case is supposed to have been eliminated from the
intermediate, but we do it here anyways because of the other uses for this
routine.

Handles quad precision. The high register is passed, along with the high
side instruction, and a quad precision flag. For the most part, the high side
is just performed using the second instruction byte, the high side register,
and the high half of the immediate. However, being a double also bypasses the
inc/dec optimization, since that cannot be done with doubles.

*******************************************************************************}

procedure gendoiir(signed: boolean;  { signed/unsigned operation }
                   ins:    integer;  { instruction type }
                   ins2:   integer;  { high instruction }
                   r, rx:  regt;     { register to add to }
                   quad:   boolean;  { quad precision }
                   i:      ssint;    { immediate operand }
                   err:    boolean); { generate overflow error }

{ generate overflow check }

procedure doovf;

begin

   if err then begin { error checking is active }

      { generate overflow check }
      if ins in [$00, $10, $28, $18] then begin

         { Check signed or unsigned overflow. If either operand is signed, then
           the operation is treated as signed because of sign preservation
           rules. }
         if signed then genovf { signed }
         else gencar { unsigned }

      end

   end

end;

procedure doopr;

var ti: ssint; { holder for sign extended high half of double }

procedure dooprs(ins: integer; { instruction code }
                 r:   regt;    { register to use }
                 i:   ssint);  { constant }

begin

   { a special form exists for op eax,n, but it can be shorter to use
     the "long" form if the immediate fits in a signed byte }
   if (r = rgeax) and (not sbyte(i) or not signed) then begin { op eax,n }

      emitbyt(ins+$05); { op eax,n }
      emitint(i) { output constant }

   end else begin { op x,n }

      { Use short or long immediate constant according to constant size,
        op imm8 or op imm32. imm8 is always sign extended, so this does not work
        for unsigned math. }
      if sbyte(i) and signed then emitbyt($83) else emitbyt($81);
      emitbyt($c0+ins+dreg(r));
      if sbyte(i) and signed then emitbyt(i) else emitint(i)

   end

end;

begin

   dooprs(ins, r, i); { perform low half }
   if quad then begin { perform high half }

      if ti.s then begin { set sign extend }

         ti.s := true;
         ti.v := 1

      end else begin { set zero extend }

         ti.s := false; { set 0 }
         ti.v := 0

      end;
      dooprs(ins2, rx, ti) { perform high half }

   end;
   { if error is selected and the operation can overflow, generate
     check }
   doovf

end;

begin

   { If global overflow checking is off, then default to checking off. }
   if not fovfchk then err := false;
   { Is the operation even required? Any operation except and and cmp with
     0 is assumed to be a no-op. }
   if ssnequ(i, false, 0) or (ins = $20) or (ins = $38) or (ins = $10) or
      (ins = $28) then begin

      { If the operation is unsigned, and error checking is on, use the long
        mode since increments and decrements don't set carry. }
      if (not signed and err) or quad then doopr
      { perform immediate add and subtract cases }
      else if (ins = $00) and ssequ(i, false, 1) then begin

         emitbyt($40+dreg(r)); { inc r }
         doovf { generate error check }

      end else if (ins = $00) and ssequ(i, false, 2) and not err then begin

         { Double increment is more efficent than add, but not if overflow
           checking is on, since we would have to check each increment. }
         emitbyt($40+dreg(r)); { inc r }
         emitbyt($40+dreg(r)) { inc r }

      end else if (ins = $00) and ssequ(i, true, 1) then begin

         emitbyt($48+dreg(r)); { dec r }
         doovf { generate error check }

      end else if (ins = $00) and ssequ(i, true, 2) and not err then begin

         { Double decrement is more efficent than subtract, but not if overflow
           checking is on, since we would have to check each decrement. }
         emitbyt($48+dreg(r)); { dec r }
         emitbyt($48+dreg(r)) { dec r }

      end else if (ins = $28) and ssequ(i, false, 1) then begin

         emitbyt($48+dreg(r)); { dec r }
         doovf { generate error check }

      end else if (ins = $28) and ssequ(i, false, 2) then begin

         { Double decrement is more efficent than subtract, but not if overflow
           checking is on, since we would have to check each decrement. }
         emitbyt($48+dreg(r)); { dec r }
         emitbyt($48+dreg(r)) { dec r }

      end else if (ins = $28) and ssequ(i, true, 1) then begin

         emitbyt($40+dreg(r)); { inc r }
         doovf { generate error check }

      end else if (ins = $28) and ssequ(i, true, 2) then begin

         { Double increment is more efficent than subtract, but not if overflow
           checking is on, since we would have to check each decrement. }
         emitbyt($40+dreg(r)); { inc r }
         emitbyt($40+dreg(r)) { inc r }

      end else doopr { perform with add }

   end

end;

{*******************************************************************************

Perform multiply with immediate

Generates a multiply of the given register by the constant. The source,
destination and a temporary register is given. The source and destination is
given so that the "three operand" forms of multiply can be used to reduce
register thrashing. If a 2 operand instruction must be used, and the source
and destination are not equal, then a move will be generated. If this feature
is not needed, the source and destination should be set equal.

Several optimizations are performed. First, we determine if a simple shift can
give the result. Next, we see if a power sequence can cover it. This is a
series of add ones and doubles to give the same result. Because an add is the
same code size as a multiply, we only do this if the speed flag is set, since
an add takes 1/30th of a multiply time. Lastly, we perform a three address
multiply immediate, which can be used by the register layer to fold a move
into the multiply.

If a power sequence is used, a temp register must be provided. The caller
must either allways provide a temp register, or determine if a temp will be
required. This can be determined by the constant not being 0, or 1, and not
a power of two, with the speed flag on, and no overflow check mode. If
a temp is required, but not provided, a system error results.

Handles a quad precision multiply. However, this involves special register
placement if the operation does not qualify as a *0, *1, shift or power series
multiply. See below.

*******************************************************************************}

procedure genmltir(signed:  boolean;  { signed/unsigned mode }
                   rd, rdx: regt;     { destination register }
                   rs, rsx: regt;     { optional source register }
                   rt, rtx: regt;     { temp used for power series }
                   i:       ssint;    { constant }
                   err:     boolean;  { generate error checks }
                   quad:    boolean); { perform in quad precision }

var shft:    0..31;   { shift count }
    ti:      1..10;   { index for multiply table }
    pgmcnts: integer; { save for program counter }

begin

   { If global overflow checking is off, then default to checking off. }
   if not fovfchk then err := false;
   if ssequ(i, false, 0) then begin { handle the *0 case }

      emitbyt($31); { xor rd,rd }
      emitbyt($c0+dreg(rd)*8+dreg(rd));
      if quad then begin { do high half }

         emitbyt($31); { xor rd,rd }
         emitbyt($c0+dreg(rdx)*8+dreg(rdx))

      end

   end else if ssnequ(i, false, 1) then begin { not *1, which would be a no-op }

      { Check *powers of 2 }
      shft := pow2(i); { find shift power }
      if (shft <> 0) and not err then begin

         { perform move to destination if required }
         if rd <> rs then begin

            emitbyt($8b); { mov rd,rs }
            emitbyt($c0+dreg(rd)*8+dreg(rs));

         end;
         if quad and (rdx <> rsx) then begin

            emitbyt($8b); { mov rd,rs }
            emitbyt($c0+dreg(rdx)*8+dreg(rsx));

         end;
         { shift value found, perform it }
         if quad then begin { double }

            { for quad precision shift, the operation must turn into a loop }
            emitbyt($c7); { mov r,imm32 }
            emitbyt($c0+$00*8+dreg(rt));
            emitint(shft);
            pgmcnts := pgmcnt; { save program counter for jump calculation }
            emitbyt($d1); { sal rd,1 }
            emitbyt($c0+$04*8+dreg(rd));
            emitbyt($d1); { rcl rdx,1 }
            emitbyt($c0+$02*8+dreg(rdx));
            emitbyt($48+dreg(rt)); { dec rt }
            emitbyt($75); { jnz back }
            emitbyt(-(pgmcnt-pgmcnts+1)) { relative jump to start }

         end else begin { single }

            emitbyt($c1); { sal rl,imm8 }
            emitbyt($c0+$04*8+dreg(rd));
            emitbyt(shft)

         end

      end else begin { shift not found, or error check }

         if not i.s and ssleq(i, false, maxmlt) and fspeed and
            not err then begin

            { We can generate a power sequence to cover small multiplies, but
              why do it when an add takes as many bytes as one imul ? Because
              adds are a lot faster. We perform up to 10 of these, although
              we could do more and stay within a fairly stunning 30 to 1
              timing advantage. Note that Intel could flush this by
              coming up with an efficient multiply. The copy register is
              reserved in the register pass. }
            if (rt = rgnull) or (quad and (rtx = rgnull)) then
               error(esysflt133); { no temp reg }
            { perform move to destination if required }
            if rd <> rs then begin

               emitbyt($8b); { mov rd,rs }
               emitbyt($c0+dreg(rd)*8+dreg(rs));

            end;
            if quad and (rd <> rs) then begin { high half double }

               emitbyt($8b); { mov rd,rs }
               emitbyt($c0+dreg(rdx)*8+dreg(rsx));

            end;
            emitbyt($8b); { mov rt,rd }
            emitbyt($c0+dreg(rt)*8+dreg(rd));
            if quad then begin { double }

               emitbyt($8b); { mov rt,rd }
               emitbyt($c0+dreg(rtx)*8+dreg(rdx))

            end;
            for ti := 1 to 10 do begin { perform +1, *2 }

               if powtab[i.v, ti] = 'a' then begin { +1 }

                  emitbyt($03); { add rl,rs }
                  emitbyt($c0+dreg(rd)*8+dreg(rt));
                  if quad then begin { double }

                     emitbyt($13); { adc rlx,rsx }
                     emitbyt($c0+dreg(rdx)*8+dreg(rtx));

                  end

               end else if powtab[i.v, ti] = 'd' then begin { *2 }

                  emitbyt($03); { add rl,rl }
                  emitbyt($c0+dreg(rd)*8+dreg(rd));
                  if quad then begin { double }

                     emitbyt($13); { adc rlx,rlx }
                     emitbyt($c0+dreg(rdx)*8+dreg(rdx));

                  end

               end

            end

         end else begin { perform conventional multiply immediate }

            if signed then begin { perform signed version }

               { The three operand form does not cost any more than the two
                 operand form here. This allows any result register to be used,
                 and can be taken advantage of in the registers pass. }
               if sbyte(i) and not quad then begin { perform short version }

                  emitbyt($6b); { imul rl,imm8 }
                  emitbyt($c0+dreg(rd)*8+dreg(rs));
                  emitbyt(i);
                  if err then genovf { generate overflow check }

               end else begin { perform long version }

                  if quad then begin { double }

                     { Double must be performed by routine, so we have to load
                       the immediate to a register. }
                     emitbyt($c7); { mov r,imm32 }
                     emitbyt($c0+$00*8+dreg(rt));
                     emitint(i);
                     { zero extend constant to 64 bits }
                     emitbyt($31); { xor rtx,rtx }
                     emitbyt($c0+dreg(rtx)*8+dreg(rtx));
                     if i.s then { change 0 to -1 }
                        emitbyt($48+dreg(rtx)); { dec rtx }
                     { signed quad precision multiply }
                     genrotcal(maclib_mults64)

                  end else begin { single }

                     emitbyt($69); { imul rl,imm32 }
                     emitbyt($c0+dreg(rd)*8+dreg(rs));
                     emitint(i);
                     if err then genovf { generate overflow check }

                  end

               end

            end else begin

               if quad then begin { double }

                  { Double must be performed by routine, so we have to load
                    the immediate to a register. }
                  emitbyt($c7); { mov r,imm32 }
                  emitbyt($c0+$00*8+dreg(rt));
                  emitint(i);
                  { zero extend constant to 64 bits }
                  emitbyt($31); { xor rtx,rtx }
                  emitbyt($c0+dreg(rtx)*8+dreg(rtx));
                  if i.s then { change 0 to -1 }
                     emitbyt($48+dreg(rtx)); { dec rtx }
                  { signed quad precision multiply }
                  genrotcal(maclib_multu64)

               end else begin { single }

                  { Unsigned multiply does not have an immediate form, load the
                    immediate to a register. The destination is placed in eax
                    from the register pass. }
                  emitbyt($c7); { mov r,imm32 }
                  emitbyt($c0+$00*8+dreg(rt));
                  emitint(i);
                  { perform unsigned multiply }
                  emitbyt($f7); { mul eax,imm32 }
                  emitbyt($c0+4*8+dreg(rt));
                  if err then gencar { generate unsigned error check }

               end

            end

         end

      end

   end

end;

{*******************************************************************************

Check within range constant

Accepts an intermediate node. Checks if the intermediate is a constant, and if
so, if it is within the range of a standard integer, or <= maxint. Returns true
if so.

This routine is used to determine if an operand needs to be sign checked.

*******************************************************************************}

function wthrng(ip: intptr): boolean;

var s: boolean;

begin

   s := false; { default not within range }
   { if the operand is not immediate, assume it could be overrange }
   if ip^.i = tilimint then
      { constant, now set according to within range }
      s := consti(ip^.base) <= maxint;

   wthrng := s { return within range status }

end;

{*******************************************************************************

Get instruction codes for binary operand operations

Finds the instruction code and extended code for the following operators:

   tiaddint/tiaddintimm
   tiandint/tiandintimm
   tiequint/tiequintimm
   tiequtgp/tiequtgpimm
   tineqint/tineqintimm
   tineqtgp/tineqtgpimm
   tileqint/tileqintimm
   tigeqint/tigeqintimm
   tiltnint/tiltnintimm
   tigtnint/tigtnintimm
   tiorint /tiorintimm
   tisubint/tisubintimm
   tixorint/tixorintimm

The instruction code is used for single precision operations. The extended code
is used for quad precision operations.

*******************************************************************************}

procedure binins(    i:         tintcod; { operator instruction code to find }
                     signed:    boolean; { operation is signed/unsigned }
                 var ins, ins2: byte);   { instruction codes }

begin

   { Find instruction code for operand. This should be done by a set, but
     the I codes are too large for a set ( > 256 ). }
   if (i <> tiaddint)    and (i <> tiaddintimm) and (i <> tiaddintlod) and
      (i <> tiaddintldi) and (i <> tiandint)    and (i <> tiandintimm) and
      (i <> tiandintlod) and (i <> tiandintldi) and (i <> tiequint)    and
      (i <> tiequintimm) and (i <> tiequintlod) and (i <> tiequintldi) and
      (i <> tiequtgp)    and (i <> tiequtgpimm) and (i <> tiequtgplod) and
      (i <> tiequtgpldi) and (i <> tineqint)    and (i <> tineqintimm) and
      (i <> tineqintlod) and (i <> tineqintldi) and (i <> tineqtgp)    and
      (i <> tineqtgpimm) and (i <> tineqtgplod) and (i <> tineqtgpldi) and
      (i <> tileqint)    and (i <> tileqintimm) and (i <> tileqintlod) and
      (i <> tileqintldi) and (i <> tigeqint)    and (i <> tigeqintimm) and
      (i <> tigeqintlod) and (i <> tigeqintldi) and (i <> tiltnint)    and
      (i <> tiltnintimm) and (i <> tiltnintlod) and (i <> tiltnintldi) and
      (i <> tigtnint)    and (i <> tigtnintimm) and (i <> tigtnintlod) and
      (i <> tigtnintldi) and (i <> tiorint)     and (i <> tiorintimm)  and
      (i <> tiorintlod)  and (i <> tiorintldi)  and (i <> tisubint)    and
      (i <> tisubintimm) and (i <> tisubintlod) and (i <> tisubintldi) and
      (i <> tixorint)    and (i <> tixorintimm) and (i <> tixorintlod) and
      (i <> tixorintldi) and (i <> timltint)    and (i <> timltintimm) and
      (i <> timltintlod) and (i <> timltintldi) then error(esysflt135);
   case i of

      { The second instruction byte is the second instruction of a double
        precision pair. In two cases, add and substract, a different instruction
        using carry occurs. In the case of the logical instructions, there is no
        difference. In case of compare, the operation turns into a destructive
        subtract. In the case of multiply, a special procedure must be used. }
      tiaddint, tiaddintimm, tiaddintlod, tiaddintldi: begin ins := $00; ins2 := $10 end;
      tiandint, tiandintimm, tiandintlod, tiandintldi: begin ins := $20; ins2 := $20 end;
      tiequint, tiequintimm, tiequintlod, tiequintldi: begin ins := $38; ins2 := $18 end;
      tiequtgp, tiequtgpimm, tiequtgplod, tiequtgpldi: begin ins := $38; ins2 := $18 end;
      tineqint, tineqintimm, tineqintlod, tineqintldi: begin ins := $38; ins2 := $18 end;
      tineqtgp, tineqtgpimm, tineqtgplod, tineqtgpldi: begin ins := $38; ins2 := $18 end;
      tileqint, tileqintimm, tileqintlod, tileqintldi: begin ins := $38; ins2 := $18 end;
      tigeqint, tigeqintimm, tigeqintlod, tigeqintldi: begin ins := $38; ins2 := $18 end;
      tiltnint, tiltnintimm, tiltnintlod, tiltnintldi: begin ins := $38; ins2 := $18 end;
      tigtnint, tigtnintimm, tigtnintlod, tigtnintldi: begin ins := $38; ins2 := $18 end;
      tiorint,  tiorintimm,  tiorintlod,  tiorintldi:  begin ins := $08; ins2 := $08 end;
      tisubint, tisubintimm, tisubintlod, tisubintldi: begin ins := $28; ins2 := $18 end;
      tixorint, tixorintimm, tixorintlod, tixorintldi: begin ins := $30; ins2 := $30 end;
      { Multiply is the only operation where the opcode depends on the signed/
        unsigned status. }
      timltint, timltintimm, timltintlod: if signed then ins := $0f else ins := $f7

   end

end;

{*******************************************************************************

Generate overflow check for gendoi

Generates an overflow check depending on instruction. The instruction code is
checked if it contains an add, subtract, or multiply instruction. All of the
other instructions, logical or compare, do not need an overflow check.

*******************************************************************************}

procedure doovf(ins:    byte;     { x386 instruction code }
                signed: boolean); { signed/unsigned operation }

begin

   { generate overflow check }
   if ins in [$00, $28, $0f, $f7] then begin

      { Check signed or unsigned overflow. If either operand is signed, then the
        operation is treated as signed because of sign preservation rules. }
      if signed then genovf { signed }
      else gencar { unsigned }

   end

end;

{*******************************************************************************

Process double operand instruction for tree

Given a node that will perform an instruction, it it generated with several
special cases. The instruction is encoded as:

Int     Opr  Code
=================
iaddint add  $00
iandint and  $20
iequint cmp  $38
iequtgp cmp  $38
ineqint cmp  $38
ineqtgp cmp  $38
ileqint cmp  $38
igeqint cmp  $38
iltnint cmp  $38
igtnint cmp  $38
iorint  or   $08
isubint sub  $28
ixorint xor  $30
imltint imul $0f (signed)
        mul  $f7 (unsigned)

Mixed sign operations introduce the need to check the sign of operands prior to
the operation. In this case, the optimized versions are replaced with loads to
registers, because the need to perform the check overrides the savings of the
optimized access.

*******************************************************************************}

procedure gendoi(ip: intptr); { intermediate node }

var i:         integer; { integer holding }
    ins, ins2: byte;    { instruction code }
    siz:       integer; { size of operand }
    ti:        ssint;   { signed integer holding }
    signed:    boolean; { signed status of operation }
    sgnchk:    boolean; { mixed sign operation requires checking }
    quad:    boolean; { operation is performed in double }

begin

   { find signed or unsigned status of operation }
   signed := chksgn(ip^.left^.rbase) or chksgn(ip^.right^.rbase);
   { find if either operand needs to be checked for sign }
   sgnchk := chksgn(ip^.left^.rbase) <> chksgn(ip^.right^.rbase);
   { find if operation must be performed in quad precision math }
   quad := (ip^.left^.rbase^.size > regsiz) or
             (ip^.right^.rbase^.size > regsiz);
   { find instruction codes }
   binins(ip^.i, signed, ins, ins2);
   gennod(ip^.left); { resolve the left one }
   gennod(ip^.right); { resolve right }
   { see if either operand needs sign checking }
   if fovfchk then begin

      { Note that if the operand is constant, and we know it is overrange and
        will give an error, we let it fall into a runtime error. }
      if (chksgn(ip^.left^.rbase) <> signed) and not wthrng(ip^.left) then begin

         { check sign left }
         if ip^.left^.rbase^.size <= regsiz then gensgnchk(ip^.lreg) { dword }
         else gensgnchk(ip^.lregx) { qword }

      end;
      if (chksgn(ip^.right^.rbase) <> signed) and not wthrng(ip^.right) then begin

         { check sign right }
         if ip^.right^.rbase^.size <= regsiz then gensgnchk(ip^.rreg) { dword }
         else gensgnchk(ip^.rregx) { qword }

      end

   end;
   { see if either operand needs dword to qword extention }
   if quad then begin

      { check and expand left }
      if ip^.left^.rbase^.size <= regsiz then
         genext(chksgn(ip^.left^.rbase), ip^.lreg, ip^.lregx);
      { check and expand right }
      if ip^.right^.rbase^.size <= regsiz then
         genext(chksgn(ip^.right^.rbase), ip^.rreg, ip^.rregx)

   end;
   if ins = $f7 then begin { unsigned multiply }

      if quad then { process quad precision }
         genrotcal(maclib_multu64) { unsigned quad precision multiply }
      else begin { single precision }

         emitbyt(ins); { op eax,y }
         emitbyt($c0+$04*8+dreg(ip^.rreg))

      end

   end else begin { unsigned multiply or other operation }

      if ins = $0f then begin { signed multiply }

         if quad then { process quad precision }
            genrotcal(maclib_mults64) { signed quad precision multiply }
         else begin { single precision }

            emitbyt($0f); { imul }
            emitbyt($af);
            emitbyt($c0+dreg(ip^.lreg)*8+dreg(ip^.rreg));

         end

      end else begin { non-multiply operation }

         emitbyt(ins+$03); { op x,y }
         emitbyt($c0+dreg(ip^.lreg)*8+dreg(ip^.rreg));
         if quad then begin

            { perform high order operation }
            emitbyt(ins2+$03); { op x,y }
            emitbyt($c0+dreg(ip^.lregx)*8+dreg(ip^.rregx));

         end

      end

   end;

   { If error is selected and the operation can overflow, and not double
     precision multiply, generate check. Note that the quad precision multiply
     routine does its own overflow check. }
   if (ip^.i <> timltint) or not quad then doovf(ins, signed);
   { If the signed status of the operation and the result are different, it is
     an error if the sign is set in any case. }
   if (ins <> $38) and (signed <> chksgn(ip^.rbase)) then
      { If multiply, the sign flag is undefined, so must generate an 'or'
        operation to check it. Otherwise, we can just check the sign. }
      if ip^.i = timltint then gensgnchk(ip^.rreg) else gensgn

end;

{*******************************************************************************

Process double operand instruction for tree with immediate

Given a node that will perform an instruction, it it generated with an immediate
constant instruction. The instruction is encoded as:

Int     Opr  Code
=================
iaddintimm add  $00
iandintimm and  $20
iequintimm cmp  $38
iequtgpimm cmp  $38
ineqintimm cmp  $38
ineqtgpimm cmp  $38
ileqintimm cmp  $38
igeqintimm cmp  $38
iltnintimm cmp  $38
igtnintimm cmp  $38
iorintimm  or   $08
isubintimm sub  $28
ixorintimm xor  $30
imltintimm imul $0f (signed)
           mul  $f7 (unsigned)

*******************************************************************************}

procedure gendoiimm(ip: intptr); { intermediate node }

var i:         integer; { integer holding }
    ins, ins2: byte;    { instruction code }
    siz:       integer; { size of operand }
    ti:        ssint;   { signed integer holding }
    signed:    boolean; { signed status of operation }
    sgnchk:    boolean; { mixed sign operation requires checking }
    quad:    boolean; { operation is performed in double }

begin

   ti.v := consti(ip^.base); { get immediate value }
   ti.s := constis(ip^.base);
   { find signed or unsigned status of operation }
   signed := chksgn(ip^.left^.rbase) or ti.s;
   { find if operation must be performed in quad precision math }
   quad := (ip^.left^.rbase^.size > regsiz) or (ip^.base^.size > regsiz);
   { find instruction codes }
   binins(ip^.i, signed, ins, ins2);
   gennod(ip^.left); { resolve the left one }
   { If the left side is unsigned, and the number is also unsigned, we
     change the operation type to unsigned to preserve value. }
   if not chksgn(ip^.left^.rbase) and not ti.s then signed := false;
   { check and expand left if operation is double, but left is a single }
   if (ip^.left^.rbase^.size <= regsiz) and quad then
      genext(chksgn(ip^.left^.rbase), ip^.lreg, ip^.lregx);
   if ip^.i = timltintimm then { it's a multiply }
      { generate multiply immediate }
      genmltir(signed, ip^.lreg, ip^.lregx, ip^.lreg, ip^.lregx,
               ip^.t1reg, ip^.t1regx, ti, true, quad)
   else { other operator }
      { perform }
      gendoiir(signed, ins, ins2, ip^.lreg, ip^.lregx, quad, ti, true)

end;

{*******************************************************************************

Process double operand instruction for tree with direct address

Given a node that will perform an instruction, it it generated with several
special cases. The instruction is encoded as:

Int     Opr  Code
=================
iaddintlod add  $00
iandintlod and  $20
iequintlod cmp  $38
iequtgplod cmp  $38
ineqintlod cmp  $38
ineqtgplod cmp  $38
ileqintlod cmp  $38
igeqintlod cmp  $38
iltnintlod cmp  $38
igtnintlod cmp  $38
iorintlod  or   $08
isubintlod sub  $28
ixorintlod xor  $30

imltintlod imul $0f (signed)
           mul  $f7 (unsigned)

The left side of the operator is an arbitrary expression tree. The right side
is a direct address.

Mixed sign operations introduce the need to check the sign of operands prior to
the operation. In this case, the optimized versions are replaced with loads to
registers, because the need to perform the check overrides the savings of the
optimized access.

*******************************************************************************}

procedure gendoilod(ip: intptr); { intermediate node }

var ins, ins2: byte;    { instruction code }
    signed:    boolean; { signed status of operation }
    quad:    boolean; { operation is performed in double }

begin

   { find signed or unsigned status of operation }
   signed := chksgn(ip^.left^.rbase) or chksgn(ip^.base);
   { find if operation must be performed in quad precision math }
   quad := (ip^.left^.rbase^.size > regsiz) or (ip^.base^.size > regsiz);
   { find instruction codes }
   binins(ip^.i, signed, ins, ins2);
   gennod(ip^.left); { resolve the left one }
   setref(ip^.base); { set address is referenced }
   { generate direct address instruction }
   if ins = $0f then { signed multiply uses double byte opcode }
      gendir2r(ip^.base, ip^.t1reg, dreg(ip^.left^.freg), $0f, $af,
               0)
   else if ins = $f7 then { unsigned multiply }
      gendir1r(ip^.base, ip^.t1reg, $04, ins, 0)
   else begin

      gendir1r(ip^.base, ip^.t1reg, dreg(ip^.left^.freg), ins+$03,
               0);
      if quad then { quad precision }
         gendir1r(ip^.base, ip^.t1reg, dreg(ip^.left^.freg),
                  ins2+$03, regsiz);

   end;
   doovf(ins, signed) { generate overflow check }

end;

{*******************************************************************************

Process double operand instruction for tree with indirect address

Given a node that will perform an instruction, it it generated with several
special cases. The instruction is encoded as:

Int     Opr  Code
=================
iaddintldi add  $00
iandintldi and  $20
iequintldi cmp  $38
iequtgpldi cmp  $38
ineqintldi cmp  $38
ineqtgpldi cmp  $38
ileqintldi cmp  $38
igeqintldi cmp  $38
iltnintldi cmp  $38
igtnintldi cmp  $38
iorintldi  or   $08
isubintldi sub  $28
ixorintldi xor  $30
imltintldi imul $0f (signed)
           mul  $f7 (unsigned)

Mixed sign operations introduce the need to check the sign of operands prior to
the operation. In this case, the optimized versions are replaced with loads to
registers, because the need to perform the check overrides the savings of the
optimized access.

*******************************************************************************}

procedure gendoildi(ip: intptr); { intermediate node }

var i:         integer; { integer holding }
    ins, ins2: byte;    { instruction code }
    siz:       integer; { size of operand }
    ti:        ssint;   { signed integer holding }
    signed:    boolean; { signed status of operation }
    sgnchk:    boolean; { mixed sign operation requires checking }
    quad:      boolean; { operation is performed in double }
    tr, trx:   byte;    { register holders for gensar }

{ Perform indirect address operation for right side }

procedure indrgt;

begin

   gennod(ip^.right); { resolve right address }
   if ins = $f7 then begin { unsigned multiply }

      { should not be quad here }
      if quad then error(esysflt124);
      emitbyt(ins); { op eax,y }
      emitbyt($04*8+dreg(ip^.rreg))

   end else begin

      if ins = $0f then begin { multiply }

         { should not be quad here }
         if quad then error(esysflt125);
         emitbyt($0f); { imul }
         emitbyt($af)

      end else emitbyt(ins+$03); { add x,[addr] }
      emitbyt(dreg(ip^.lreg)*8+dreg(ip^.rreg));
      if quad then begin

         { perform high order operation }
         emitbyt(ins2+$03); { add x,[addr] }
         emitbyt(dreg(ip^.lregx)*8+dreg(ip^.rregx))

      end

   end;
   { if error is selected and the operation can overflow, generate check }
   doovf(ins, signed)

end;

begin

   { find signed or unsigned status of operation }
   signed := chksgn(ip^.left^.rbase) or chksgn(ip^.right^.rbase);
   { find if either operand needs to be checked for sign }
   sgnchk := chksgn(ip^.left^.rbase) <> chksgn(ip^.right^.rbase);
   { find if operation must be performed in quad precision math }
   quad := (ip^.left^.rbase^.size > regsiz) or
             (ip^.right^.rbase^.size > regsiz);
   { find instruction codes }
   binins(ip^.i, signed, ins, ins2);
   gennod(ip^.left); { resolve the left one }
   { must be double or quad, and must match }
   if ip^.right^.i = tiarrref then begin { its an array reference }

      { There are some limited array cases that can fit into the SIB
        format. If array checks are off, and the base type size is 1, 2,
        4 or 8, then we can do it. The base value is done by adding it
        into the displacement. Globals or locals can be processed }
      if ip^.right^.base^.t <> tarray then error(einvfmt);
      i := ip^.right^.base^.arrt^.size; { get base type size }
      if i in [1, 2, 4, 8] then begin { proper base size }

         { Generate scaled array reference. }
         tr := dreg(ip^.lreg); { load the target registers from left }
         trx := $00; { clear extended }
         { load extended if defined }
         if ip^.lregx <> rgnull then trx := dreg(ip^.lregx);
         if ins = $0f then { signed multiply }
            gensar(ip^.right, ip^.t1reg, tr,
                   $00, false, false, $0f, true, $af, $00, false, $00, i, 0, ti)
         else if ins = $f7 then { unsigned multiply }
            gensar(ip^.right, ip^.t1reg, $04, 0, false, false,
                   $00, false, ins+$03, $00, false, $00, i, 0, ti)
         else
            gensar(ip^.right, ip^.t1reg, tr, trx, quad, false,
                   $00, false, ins+$03, $00, false, ins2+03, i, 0, ti);
         { if error is selected and the operation can overflow, generate
           check }
         doovf(ins, signed)

      end else indrgt { treat as address }

   end else indrgt { treat as address }

end;

{*******************************************************************************

Generate bounds check and base remove

Checks the given node for bounds, and removes the lower bound from the index.
If no array checking is active, we just subtract the lower bound.

The reason this operation is combined is that the check against the lower
bound and the base adjustment can be folded together. The node must already
be processed to a register.

*******************************************************************************}

procedure genbndremchkr(r, rx: regt;    { node to process }
                        quad:  boolean; { quadword operand }
                        tp:    typptr;  { index type }
                        fp:    typptr); { actual type }

var lb, ub, ti, ti1: ssint;

{ find length of compare immediate for index }

function lencmp(r: regt; i: ssint): integer;

var l: integer;

begin

   if (r = rgeax) and not sbyte(i) then l := 5
   else if sbyte(i) then l := 3
                    else l := 6;

   lencmp := l { return result }

end;

begin

   lb.v := lbound(tp); { get lower bound }
   lb.s := lbounds(tp);
   ub.v := ubound(tp); { get upper bound }
   ub.s := ubounds(tp);
   if (fbndins or not farrchk) and not quad then begin

      { use bounds instruction }
      if farrchk then
         genbndxfr(tp, fp, r, rgnull); { generate bounds check }
      { remove lower bound }
      gendoiir(false, $28, $18, r, rx, false, lb, false)

   end else begin { fold bounds check into offset normalize }

      { For this, we can just remove the base, then do a high
        limit check, since it will then bound against 0 }
      gendoiir(chksgn(tp), $28, $18, r, rx, quad, lb, true);
      { Find "span" of type }
      ti.s := sssubs(ub, lb);
      ti.v := sssub(ub, lb);
      if quad then begin { quadword }

         { find upper half of span }
         if ti.s then begin

            ti1.v := 1; { set -1 }
            ti1.s := true

         end else begin

            ti1.v := 0; { set 0 }
            ti1.s := false

         end;
         gencmpi(rx, ti1); { check upper half is higher }
         emitbyt($7f); { jg error }
         { relative jump to error call }
         emitbyt(2+lencmp(r, ti)+2);
         { if upper half not equal }
         emitbyt($75); { jne no error }
         emitbyt(lencmp(r, ti)+12); { compare immediate plus jump }
         gencmpi(r, ti); { generate high bound check }
         genske($7e, rerngchk) { generate error call }

      end else begin { double word }

         { where compare is "span" of type }
         ti.s := sssubs(ub, lb);
         ti.v := sssub(ub, lb);
         gencmpi(r, ti); { generate high bound check }
         genske($7e, rerngchk) { generate error skip }

      end

   end

end;

{*******************************************************************************

Generate scaled array reference

Expects an array reference node. The code to access the array is generated,
and if the bounds checks are on, that is generated as well.

The access is performed in either single precision (one register), or double.
quad precision means that the access is performed twice with a different
target register, at the next register offset.

For doubles, a flag that indicates the order to perform is given, low to high
or high then low.

A future optimization is to determine if bounds checks are unecessary because
of index type.

*******************************************************************************}

procedure gensar(ip:      intptr;  { node to generate }
                 dr:      regt;    { display load register }
                 tr, trx: byte;    { target register (in direct code) }
                 quad:    boolean; { quardword precision }
                 order:   boolean; { order to perform doubles, false = low/high,
                                     true = high/low }
                 ins1:    byte;    { 1st instruction byte }
                 insv1:   boolean; { 1st instruction byte valid }
                 ins2:    byte;    { 2nd instruction byte (always valid) }
                 dins1:   byte;    { 1st quad instruction byte }
                 dinsv1:  boolean; { 1st quad instruction byte valid }
                 dins2:   byte;    { 2nd quad instruction byte (always valid) }
                 scale:   integer; { scaling factor, 1, 2, 4 or 8 }
                 imms:    integer; { size of immediate, 0 = none }
                 imm:     ssint);  { immediate value to output }

var sr:      integer; { register code save }
    disp:    ssint;   { net displacement save }
    lb, ub:  ssint;   { bounds holding }
    dc:      0..2;    { doubles count }
    high:    ssint;   { high half of constant }
    ti, ti2: ssint;

procedure complex;

var disp: ssint;   { displacement }
    ti:   ssint;   { temp }
    mode: integer; { mod code for instructions }

begin

   gennod(ip^.left); { resolve the array base }
   gennod(ip^.right); { resolve index }
   { generate bounds check }
   if farrchk then
      genbndxfr(ip^.base^.arri, ip^.right^.rbase, ip^.rreg, ip^.rregx);
   while dc > 0 do begin { perform operations }

      if order then begin { perform high half }

         { find net displacement, - space to first element }
         ti.v := ssmult(lb, false, scale);
         ti.s := not ssmults(lb, false, scale);
         disp.v := ssadd(ti, false, regsiz);
         disp.s := ssadds(ti, false, regsiz);
         { determine mode of displacement by lower bound }
         if disp.v = 0 then
            mode := $00 { [base+index*n }
         else if sbyte(disp) then
            mode := $40 { disp8[base+index*n] }
         else
            mode := $80; { disp32[base+index*n] }
         if dinsv1 then emitbyt(dins1); { if 1st instruction exists, output }
         emitbyt(dins2); { op x,disp[base+index*n] }
         emitbyt(mode+trx*8+$04);
         emitbyt(sib(scale)+dreg(ip^.rreg)*8+dreg(ip^.lreg));
         if mode = $40 then emitbyt(disp)
         else if mode = $80 then emitint(disp);
         if imms >= 4 then emitint(high) { output dword constant }

      end else begin { perform low half }

         { generate normal version }
         { find net displacement, - space to first element }
         disp.v := ssmult(lb, false, scale);
         disp.s := not ssmults(lb, false, scale);
         { determine mode of displacement by lower bound }
         if disp.v = 0 then
            mode := $00 { [base+index*n }
         else if sbyte(disp) then
            mode := $40 { disp8[base+index*n] }
         else
            mode := $80; { disp32[base+index*n] }
         if insv1 then emitbyt(ins1); { if 1st instruction exists, output }
         emitbyt(ins2); { op x,disp[base+index*n] }
         emitbyt(mode+tr*8+$04);
         emitbyt(sib(scale)+dreg(ip^.rreg)*8+dreg(ip^.lreg));
         if mode = $40 then emitbyt(disp)
         else if mode = $80 then emitint(disp);
         if imms = 1 then emitbyt(imm) { output single byte constant }
         else if imms = 2 then emitwrd(imm) { output word constant }
         else if imms >= 4 then emitint(imm) { output dword constant }

      end;
      dc := dc-1; { count operations }
      order := not order { flip the order }

   end

end;

begin

   if quad then dc := 2 else dc := 1; { set doubles count }
   lb.v := lbound(ip^.base^.arri); { get lower bound }
   lb.s := lbounds(ip^.base^.arri);
   ub.v := ubound(ip^.base^.arri); { get upper bound }
   ub.s := ubounds(ip^.base^.arri);
   { get high half of constant }
   if imm.s then begin { set sign extend }

      high.s := true;
      high.v := 1

   end else begin { set zero extend }

      high.s := false; { set 0 }
      high.v := 0

   end;
   { the base size is one that can be reached by scaling }
   if ip^.left^.i = tilodadr then begin

      if not chkext(ip^.left^.base) then begin { not an extended parameter }

         setref(ip^.left^.base); { set that is referenced }
         { array is simple, addressed }
         if (ip^.left^.base^.t = tfield) or
            (ip^.left^.base^.t = tftag) then begin { 'with' field reference }

            gennod(ip^.right); { resolve index }
            if farrchk then { generate bounds check }
               genbndxfr(ip^.base^.arri, ip^.right^.rbase, ip^.rreg, ip^.rregx);
            { load the 'with' base variable to the reg }
            lodwth(ip^.left^.base, dr);
            while dc > 0 do begin { perform operations }

               if order then begin { perform high half of double }

                  { find net displacement, address - space to 1st element }
                  ti.v := ssmult(lb, false, scale);
                  ti.s := ssmults(lb, false, scale);
                  ti2.v := sssub(false, ip^.base^.addr, ti);
                  ti2.s := sssubs(false, ip^.base^.addr, ti);
                  disp.v := ssadd(ti2, false, regsiz);
                  disp.s := ssadds(ti2, false, regsiz);
                  { check in signed bounds for now }
                  if disp.v > maxint then error(esysflt232);
                  { now we have an offset left to perform, but this can be placed into
                    the offset of an r/m }
                  if dinsv1 then emitbyt(dins1); { if 1st instruction exists, output }
                  emitbyt(dins2); { op x,disp[ebp+index*n] }
                  emitbyt($80+trx*8+$04);
                  emitbyt(sib(scale)+dreg(ip^.rreg)*8+dreg(dr));
                  emitadro(ip^.left^.base, itadr, ss2int(disp));
                  if imms >= 4 then emitint(high) { output dword constant }

               end else begin { perform low half of double }

                  { find net displacement, address - space to 1st element }
                  ti.v := ssmult(lb, false, scale);
                  ti.s := ssmults(lb, false, scale);
                  disp.v := sssub(false, ip^.base^.addr, ti);
                  disp.s := sssubs(false, ip^.base^.addr, ti);
                  { check in signed bounds for now }
                  if disp.v > maxint then error(esysflt232);
                  { now we have an offset left to perform, but this can be placed into
                    the offset of an r/m }
                  if insv1 then emitbyt(ins1); { if 1st instruction exists, output }
                  emitbyt(ins2); { op x,disp[ebp+index*n] }
                  emitbyt($80+tr*8+$04);
                  emitbyt(sib(scale)+dreg(ip^.rreg)*8+dreg(dr));
                  emitadro(ip^.left^.base, itadr, ss2int(disp));
                  if imms = 1 then emitbyt(imm) { output single byte constant }
                  else if imms = 2 then emitwrd(imm) { output word constant }
                  else if imms >= 4 then emitint(imm) { output dword constant }

               end;
               dc := dc-1; { count operations }
               order := not order { flip the order }

            end

         end else  if ip^.left^.base^.local then begin { its a local }

            gennod(ip^.right); { resolve index }
            if farrchk then { generate bounds check }
               genbndxfr(ip^.base^.arri, ip^.right^.rbase, ip^.rreg, ip^.rregx);
            gendslr(ip^.left^.base, dr, sr); { generate display load }
            while dc > 0 do begin { perform operations }

               if order then begin { perform high half of double }

                  { find net displacement, address - space to 1st element }
                  ti.v := ssmult(lb, false, scale);
                  ti.s := not ssmults(lb, false, scale);
                  disp.v := ssadd(ti, false, regsiz);
                  disp.s := ssadds(ti, false, regsiz);
                  { check in signed bounds for now }
                  if disp.v > maxint then error(esysflt233);
                  if dinsv1 then emitbyt(dins1); { if 1st instruction exists, output }
                  emitbyt(dins2); { op x,disp[ebp+index*n] }
                  emitbyt($80+trx*8+$04);
                  emitbyt(sib(scale)+dreg(ip^.rreg)*8+sr);
                  emitadro(ip^.left^.base, itadr, ss2int(disp));
                  if imms >= 4 then emitint(high) { output dword constant }

               end else begin { perform low half of double }

                  { find net displacement, address - space to 1st element }
                  disp.v := ssmult(lb, false, scale);
                  disp.s := not ssmults(lb, false, scale);
                  { check in signed bounds for now }
                  if disp.v > maxint then error(esysflt233);
                  if insv1 then emitbyt(ins1); { if 1st instruction exists, output }
                  emitbyt(ins2); { op x,disp[ebp+index*n] }
                  emitbyt($80+tr*8+$04);
                  emitbyt(sib(scale)+dreg(ip^.rreg)*8+sr);
                  emitadro(ip^.left^.base, itadr, ss2int(disp));
                  if imms = 1 then emitbyt(imm) { output single byte constant }
                  else if imms = 2 then emitwrd(imm) { output word constant }
                  else if imms >= 4 then emitint(imm) { output dword constant }

               end;
               dc := dc-1; { count operations }
               order := not order { flip the order }

            end

         end else begin { its a global }

            gennod(ip^.right); { resolve index }
            if farrchk then { generate bounds check }
               genbndxfr(ip^.base^.arri, ip^.right^.rbase, ip^.rreg, ip^.rregx);
            while dc > 0 do begin { perform operations }

               if order then begin { perform high half of double }

                  if dinsv1 then emitbyt(dins1); { if 1st instruction exists, output }
                  emitbyt(dins2); { op x,addr[index*n] }
                  emitbyt($00+trx*8+$04);
                  emitbyt(sib(scale)+dreg(ip^.rreg)*8+$05);
                  { use unmodified or offset address if there is a base }
                  if lbound(ip^.base^.arri) = 0 then emitadr(ip^.left^.base, itadr)
                  else begin

                     ti.v := ssmult(lb, false, scale);
                     ti.s := not ssmults(lb, false, scale);
                     disp.v := ssadd(ti, false, regsiz);
                     disp.s := ssadds(ti, false, regsiz);
                     { check simple signed offset for now }
                     if disp.v > maxint then error(esysflt239);
                     emitadro(ip^.left^.base, itadr, ss2int(disp))

                  end;
                  if imms >= 4 then emitint(high) { output dword constant }

               end else begin { perform low half of double }

                  if insv1 then emitbyt(ins1); { if 1st instruction exists, output }
                  emitbyt(ins2); { op x,addr[index*n] }
                  emitbyt($00+tr*8+$04);
                  emitbyt(sib(scale)+dreg(ip^.rreg)*8+$05);
                  { use unmodified or offset address if there is a base }
                  if lbound(ip^.base^.arri) = 0 then emitadr(ip^.left^.base, itadr)
                  else begin

                     ti.v := ssmult(lb, false, scale);
                     ti.s := not ssmults(lb, false, scale);
                     { check simple signed offset for now }
                     if ti.v > maxint then error(esysflt239);
                     emitadro(ip^.left^.base, itadr, ss2int(ti))

                  end;
                  if imms = 1 then emitbyt(imm) { output single byte constant }
                  else if imms = 2 then emitwrd(imm) { output word constant }
                  else if imms >= 4 then emitint(imm) { output dword constant }

               end;
               dc := dc-1; { count operations }
               order := not order { flip the order }

            end

         end

      end else complex { array is complex }

   end else complex { array is complex }

end;

{*******************************************************************************

Generate array reference

Expects an array reference node. The code to access the array is generated,
and if the bounds checks are on, that is generated as well.
A future optimization is to determine if bounds checks are unecessary because
of index type.

*******************************************************************************}

procedure genarr(ip: intptr); { node to generate }

var i: ssint;

begin

   i.s := false; { set unsigned }
   if ip^.base^.t <> tarray then error(einvfmt);
   i.v := ip^.base^.arrt^.size; { get base type size }
   if i.v in [1, 2, 4, 8] then { generate scaled array reference }
      gensar(ip, ip^.rsreg, dreg(ip^.rsreg), 0, false, false, $00, false, $8d,
             $00, false, $00, i.v, 0, i)
   else begin { array index is not scalable }

      gennod(ip^.left); { resolve the array base }
      gennod(ip^.right); { resolve index }
      { perform lower bound remove and bounds check }
      genbndremchkr(ip^.rreg, ip^.rregx, ip^.right^.rbase^.size > regsiz,
                    ip^.base^.arri, ip^.right^.rbase);
      { Generate index scale. Note that the bounds removal above creates an
        unsigned effective index. }
      genmltir(false, ip^.rreg, ip^.rregx, ip^.rreg, ip^.rregx,
               ip^.t1reg, ip^.t1regx, i, false, ip^.right^.rbase^.size > regsiz);
      { The index, as resolved, should not be beyond the address capability of
        machine, so we generate an unsigned overflow check here. }
      if farrchk and (ip^.right^.rbase^.size > regsiz) then begin

         emitbyt($0b); { or rx,rx }
         emitbyt($c0+dreg(ip^.rregx)*8+dreg(ip^.rregx));
         genske($74, rerngchk) { generate error skip }

      end;
      { generate offset to address }
      emitbyt($03); { add rd, rs }
      emitbyt($c0+dreg(ip^.lreg)*8+dreg(ip^.rreg))

   end

end;

{*******************************************************************************

Generate general array reference

Expects a general array reference node. The code to access the array is
generated, and if the bounds checks are on, that is generated as well.

*******************************************************************************}

procedure gengar(ip: intptr); { node to generate }

var i:       ssint;
    ti, ti1: ssint;

{ find length of compare immediate for index }

function lencmp(r: regt; i: ssint): integer;

var l: integer;

begin

   if (r = rgeax) and not sbyte(i) then l := 5
   else if sbyte(i) then l := 3
                    else l := 6;

   lencmp := l { return result }

end;

begin

   if ip^.base^.t <> tgarry then error(einvfmt);
   i.v := ip^.base^.arrt^.size; { get base type size }
   i.s := false;
   if i.v in [1, 2, 4, 8] then begin

      { the base size is one that can be reached by scaling }
      gennod(ip^.left); { resolve the array base }
      gennod(ip^.right); { resolve index }
      if farrchk then begin

         { set up low bound constants }
         ti.s := false; { set 1 }
         ti.v := 1;
         ti1.s := false; { set 0 }
         ti1.v := 0;
         if ip^.right^.rbase^.size > regsiz then begin { quadword index }

            if chksgn(ip^.right^.rbase) then begin { signed index }

               { check high half of low first }
               gencmpi(ip^.rregx, ti1); { check upper half is lower }
               emitbyt($7c); { jl error }
               { relative jump to error call }
               emitbyt(2+lencmp(ip^.rreg, ti)+2+lencmp(ip^.rregx, ti1)+6+2);
               { if upper half not equal }
               emitbyt($75); { jne next }
               emitbyt(lencmp(ip^.rreg, ti)+2);
               gencmpi(ip^.rreg, ti); { generate low bound check }
               emitbyt($7c); { jl error }
               { relative jump to error call }
               emitbyt(lencmp(ip^.rregx, ti1)+6+2);

               { check high half of high first }
               gencmpi(ip^.rregx, ti1); { check upper half is higher }
               emitbyt($7f); { jg error }
               { relative jump to error call }
               emitbyt(4+2);
               { if upper half not equal }
               emitbyt($75); { jne no error }
               emitbyt(2+12);
               emitbyt($3b); { cmp rb,rlen }
               emitbyt($c0+dreg(ip^.rreg)*8+dreg(ip^.lregx));
               genske($7e, rerngchk) { generate error call }

            end else begin { unsigned index }

               { check high half of low first }
               gencmpi(ip^.rregx, ti1); { check upper half is lower }
               emitbyt($72); { jb error }
               { relative jump to error call }
               emitbyt(2+lencmp(ip^.rreg, ti)+2+lencmp(ip^.rregx, ti1)+6+2);
               { if upper half not equal }
               emitbyt($75); { jne next }
               emitbyt(lencmp(ip^.rreg, ti)+2);
               gencmpi(ip^.rreg, ti); { generate low bound check }
               emitbyt($72); { jb error }
               { relative jump to error call }
               emitbyt(lencmp(ip^.rregx, ti1)+6+2);

               { check high half of high first }
               gencmpi(ip^.rregx, ti1); { check upper half is higher }
               emitbyt($77); { ja error }
               { relative jump to error call }
               emitbyt(4+2);
               { if upper half not equal }
               emitbyt($75); { jne no error }
               emitbyt(2+12);
               emitbyt($3b); { cmp rb,rlen }
               emitbyt($c0+dreg(ip^.rreg)*8+dreg(ip^.lregx));
               genske($76, rerngchk) { generate error call }

            end

         end else begin { dword index }

            gencmpi(ip^.rreg, ti); { generate low bound check }
            if chksgn(ip^.right^.rbase) then emitbyt($7c) { jl error }
            else emitbyt($72); { jb error }
            { relative jump to error call }
            emitbyt(2+2);
            { generate high bound check from tag }
            emitbyt($3b); { cmp rb,rlen }
            emitbyt($c0+dreg(ip^.rreg)*8+dreg(ip^.lregx));
            { generate error call }
            if chksgn(ip^.right^.rbase) then genske($7e, rerngchk)
            else genske($76, rerngchk)

         end

      end;
      { Note: it is up for question if a scaled access is valid for unsigned
        calculations greater than 2147483647, the Intel manuals are completely
        vague on the matter. The scaling is probally unsigned, but it needs to
        be verified. }
      emitbyt($8d); { lea x,disp[base+index*n] }
      emitbyt($40+dreg(ip^.rsreg)*8+$04);
      emitbyt(sib(i.v)+dreg(ip^.rreg)*8+dreg(ip^.lreg));
      emitbyt(-i.v) { displace by single element }

   end else begin { array index is not scalable }

      gennod(ip^.left); { resolve the array base }
      gennod(ip^.right); { resolve index }
      { perform lower bound remove and bounds check }
      if ip^.right^.rbase^.size > regsiz then begin { quadword index }

         emitbyt($81); { sub r,1 }
         emitbyt($c0+5*8+dreg(ip^.rreg));
         emitint(1);
         emitbyt($81); { sbb r,0 }
         emitbyt($c0+3*8+dreg(ip^.rregx));
         emitint(0);
         if farrchk then begin { check overflow according to sign }

            if chksgn(ip^.right^.rbase) then genovf
            else gencar

         end

      end else begin { dword index }

         if chksgn(ip^.right^.rbase) then begin { do signed version }

            emitbyt($48+dreg(ip^.rreg)); { dec ri }
            if farrchk then genovf { perform error check }

         end else begin { do unsigned version }

            { dec won't set the carry flag, so we need a sub immediate to do
              that. }
            emitbyt($81); { sub r,1 }
            emitbyt($c0+5*8+dreg(ip^.rreg));
            emitint(1);
            if farrchk then gencar { perform error check }

         end

      end;
      if farrchk then begin

         if ip^.right^.rbase^.size > regsiz then begin { quadword index }

            { If the index is quad, it should be <= dword with the lower bound
              removed. So now we just check for upper half zero. }
            emitbyt($0b); { or rx,rx }
            emitbyt($c0+dreg(ip^.rregx)*8+dreg(ip^.rregx));
            emitbyt($75); { jnz error }
            emitbyt(4)

         end;
         { generate high bound check from tag }
         emitbyt($3b); { cmp rb,rlen }
         emitbyt($c0+dreg(ip^.rreg)*8+dreg(ip^.lregx));
         genske($72, rerngchk) { generate error call }

      end;
      { Generate index scale. Note that the bounds removal above creates an
        unsigned calculation. }
      genmltir(false, ip^.rreg, rgnull, ip^.rreg, rgnull,
               ip^.t1reg, rgnull, i, false, false);
      { generate offset to address }
      emitbyt($03); { add rd, rs }
      emitbyt($c0+dreg(ip^.lreg)*8+dreg(ip^.rreg))

   end

end;

{*******************************************************************************

Generate indirect load

Generates a load indirect from address. Takes into account both the size and
the signed status of the loaded element. If the size is not double, then the
element is either zero or sign extended, for unsigned or signed, respectively.

Doubles can be loaded with this routine. In this case, the high half of the
pair is loaded first. This allows the load to register to be the same as the
pointer register.

*******************************************************************************}

procedure genlodindr(rd, rdx: regt;     { register to load to }
                     rs:      regt;     { register containing address }
                     sz:      integer;  { size of operand }
                     sn:      boolean); { operand is signed }

begin

   if sz = qwdsiz then begin { quad word }

      { get high half }
      emitbyt($8b); { mov rdx,regsiz[rs] }
      emitbyt($40+dreg(rdx)*8+dreg(rs));
      emitbyt(regsiz); { offset to high half }
      { get low half }
      emitbyt($8b); { mov rd,[rs] }
      emitbyt($00+dreg(rd)*8+dreg(rs))

   end else if sz = dwdsiz then begin { integer }

      emitbyt($8b); { mov rr,[rl] }
      emitbyt($00+dreg(rd)*8+dreg(rs))

   end else if sz = wrdsiz then begin { word }

      if sn then begin { signed }

         emitbyt($0f); { movsxw eax,[eax] }
         emitbyt($bf);
         emitbyt($00+dreg(rd)*8+dreg(rs))

      end else begin { unsigned }

         emitbyt($0f); { movzxw eax,[eax] }
         emitbyt($b7);
         emitbyt($00+dreg(rd)*8+dreg(rs))

      end

   end else if sz = bytsiz then begin { byte }

      if sn then begin { signed }

         emitbyt($0f); { movsxb eax,[eax] }
         emitbyt($be);
         emitbyt($00+dreg(rd)*8+dreg(rs))

      end else begin { unsigned }

         emitbyt($0f); { movzxb eax,[eax] }
         emitbyt($b6);
         emitbyt($00+dreg(rd)*8+dreg(rs))

      end

   end else error(einvfmt) { invalid format }

end;

{*******************************************************************************

Generate indirect store

Generates a store indirect to address. Takes into account both the size and
the signed status of the stored element. If the size is not double, then the
element is either zero or sign extended, for unsigned or signed, respectively.

*******************************************************************************}

procedure genstoindr(rs, rsx: regt;     { register to store from }
                     rd:      regt;     { register containing address }
                     sz:      integer); { size of operand }

begin

   if sz = qwdsiz then begin { quad word }

      { place high half }
      emitbyt($89); { movd [rd],rs }
      emitbyt($40+dreg(rsx)*8+dreg(rd));
      emitbyt(regsiz); { offset to high half }
      { place low half }
      emitbyt($89); { movd [rd],rs }
      emitbyt($00+dreg(rs)*8+dreg(rd))

   end else if sz = dwdsiz then begin { double word }

      emitbyt($89); { movd [rd],rs }
      emitbyt($00+dreg(rs)*8+dreg(rd))

   end else if sz = wrdsiz then begin { word }

      emitbyt($66); { movw [rd],rs }
      emitbyt($89);
      emitbyt($00+dreg(rs)*8+dreg(rd))

   end else if sz = bytsiz then begin { byte }

      emitbyt($88); { movb [rd],rs }
      emitbyt($00+dreg(rs)*8+dreg(rd))

   end else error(einvfmt); { invalid format }

end;

{*******************************************************************************

Generate divide integer

Generates an integer divide. If the divisor is constant, and is a single bit,
Then a shift can be done. Otherwise a simple register divide is done.
The register allocation level must give eax and edx for this operation. The
remainder in edx is discarded.

Divides have a fixed error mode, a trap to int 0.

*******************************************************************************}

procedure gendiv(ip: intptr); { node to process }

var shft:    integer; { shift count }
    signed:  boolean; { signed status of operation }
    quad:  boolean; { operation is performed in double }
    pgmcnts: integer; { program counter save }
    i:       ssint;

{ perform register based divide }

procedure rdiv;

{ check within range constant }

function wthrng(ip: intptr): boolean;

var s: boolean;

begin

   s := false; { default not within range }
   { if the operand is not immediate, assume it could be overrange }
   if ip^.i = tilimint then
      { constant, now set according to within range }
      s := consti(ip^.base) <= maxint;

   wthrng := s { return within range status }

end;

begin

   { do register divide }
   gennod(ip^.right); { generate right }
   { see if either operand needs sign checking }
   if fovfchk then begin

      { Note that if the operand is constant, and we know it is overrange and
        will give an error, we let it fall into a runtime error. }
      if (chksgn(ip^.left^.rbase) <> signed) and not wthrng(ip^.left) then begin

         { check sign left }
         if ip^.left^.rbase^.size <= regsiz then gensgnchk(ip^.lreg) { dword }
         else gensgnchk(ip^.lregx) { qword }

      end;
      if (chksgn(ip^.right^.rbase) <> signed) and not wthrng(ip^.right) then begin

         { check sign right }
         if ip^.right^.rbase^.size <= regsiz then gensgnchk(ip^.rreg) { dword }
         else gensgnchk(ip^.rregx) { qword }

      end

   end;
   { check zero divide check is on }
   if fzdvchk then begin { perform programmatic zero divide check }

      if ip^.right^.rbase^.size > regsiz then begin { double }

         emitbyt($0b); { or r,r }
         emitbyt($c0+dreg(ip^.rreg)*8+dreg(ip^.rreg));
         emitbyt($75); { jnz over }
         { warning, the next calculation assumes that genske generates 7 bytes }
         emitbyt(14); { relative jump over next instructions }
         emitbyt($0b); { or rx,rx }
         emitbyt($c0+dreg(ip^.rregx)*8+dreg(ip^.rregx));
         genske($75, rezdiv) { generate zero divide fault }

      end else begin { single }

         emitbyt($0b); { or r,r }
         emitbyt($c0+dreg(ip^.rreg)*8+dreg(ip^.rreg));
         genske($75, rezdiv) { generate zero divide fault }

      end

   end;
   { see if either operand needs dword to qword extention }
   if quad then begin

      { check and expand left }
      if ip^.left^.rbase^.size <= regsiz then
         genext(chksgn(ip^.left^.rbase), ip^.lreg, ip^.lregx);
      { check and expand right }
      if ip^.right^.rbase^.size <= regsiz then
         genext(chksgn(ip^.right^.rbase), ip^.rreg, ip^.rregx)

   end;
   { perform division }
   if quad then begin { double, perform with external routine }

      if signed then genrotcal(maclib_divs64) { use signed version }
      else genrotcal(maclib_divu64) { use unsigned version }

   end else begin { perform in direct code }

      if signed then begin { signed operation }

         emitbyt($99); { cdq }
         emitbyt($f7); { idiv eax,rr }
         emitbyt($c0+$07*8+dreg(ip^.rreg))

      end else begin

         { clear high half of qword }
         emitbyt($33); { xor edx,edx }
         emitbyt($c0+dreg(rgedx)*8+dreg(rgedx));
         emitbyt($f7); { idiv eax,rr }
         emitbyt($c0+$06*8+dreg(ip^.rreg))

      end

   end

end;

begin

   { find signed or unsigned status of operation }
   signed := chksgn(ip^.left^.rbase) or chksgn(ip^.right^.rbase);
   { find if operation must be performed in quad precision math }
   quad := (ip^.left^.rbase^.size > regsiz) or
             (ip^.right^.rbase^.size > regsiz);
   gennod(ip^.left); { generate dividend }
   if ip^.right^.i = tilimint then begin { divide immediate }

      i.v := consti(ip^.right^.base); { get the constant }
      i.s := constis(ip^.right^.base);
      { 0 and 1 are eliminated in the above pass. Now we take all of the powers
        of 2 out. Find simple power. }
      shft := pow2(i); { find power }
      if (shft <> 0) and ssgeq(i, false, 0) then
         begin { shift value found, and not negative, perform it }

         if quad then begin

            if signed then begin { signed shift, use sign correction }

               { Perform unsigned shift. For quad precision shift, the
                 operation must turn into a loop. }
               emitbyt($c7); { mov r,imm32 }
               emitbyt($c0+$00*8+dreg(ip^.t1reg));
               emitint(shft);
               { make copy }
               emitbyt($8b); { mov rt,rs }
               emitbyt($c0+dreg(ip^.t2reg)*8+dreg(ip^.rsreg));
               { fill dword with sign bit }
               emitbyt($c1); { sar rt,imm8 }
               emitbyt($c0+$07*8+dreg(ip^.t2reg));
               emitbyt(31);
               { add 1 to dividend if negative }
               emitbyt($2b); { sub rs,rt }
               emitbyt($c0+dreg(ip^.rsreg)*8+dreg(ip^.t2reg));
               emitbyt($1b); { sbb rsx,rt }
               emitbyt($c0+dreg(ip^.rsregx)*8+dreg(ip^.t2reg));

               pgmcnts := pgmcnt; { save program counter for jump calculation }

               { perform shift }
               emitbyt($d1); { sar rs,1 }
               emitbyt($c0+$07*8+dreg(ip^.rsreg));
               emitbyt($d1); { rcr rs,1 }
               emitbyt($c0+$03*8+dreg(ip^.rsregx));

               emitbyt($48+dreg(ip^.t1reg)); { dec rt }
               emitbyt($75); { jnz back }
               emitbyt(-(pgmcnt-pgmcnts+1)) { relative jump to start }

            end else begin { unsigned shift }

               { Perform unsigned shift. For quad precision shift, the
                 operation must turn into a loop. }
               emitbyt($c7); { mov r,imm32 }
               emitbyt($c0+$00*8+dreg(ip^.t1reg));
               emitint(shft);

               pgmcnts := pgmcnt; { save program counter for jump calculation }

               emitbyt($d1); { shr rs,1 }
               emitbyt($c0+$05*8+dreg(ip^.rsreg));
               emitbyt($d1); { rcr rs,1 }
               emitbyt($c0+$03*8+dreg(ip^.rsreg));

               emitbyt($48+dreg(ip^.t1reg)); { dec rt }
               emitbyt($75); { jnz back }
               emitbyt(-(pgmcnt-pgmcnts+1)) { relative jump to start }

            end

         end else begin { single precision }

            if signed then begin { sign corrected shift }

               { make copy }
               emitbyt($8b); { mov rt,rs }
               emitbyt($c0+dreg(ip^.t1reg)*8+dreg(ip^.rsreg));
               { fill dword with sign bit }
               emitbyt($c1); { sar rt,imm8 }
               emitbyt($c0+$07*8+dreg(ip^.t1reg));
               emitbyt(31);
               { add 1 to dividend if negative }
               emitbyt($2b); { sub rs,rt }
               emitbyt($c0+dreg(ip^.rsreg)*8+dreg(ip^.t1reg));
               { perform shift }
               emitbyt($c1); { sar rs,imm8 }
               emitbyt($c0+$07*8+dreg(ip^.rsreg));
               emitbyt(shft)

            end else begin { unsigned shift }

               { perform shift }
               emitbyt($c1); { shr rs,imm8 }
               emitbyt($c0+$05*8+dreg(ip^.rsreg));
               emitbyt(shft)

            end

         end

      end else rdiv { not found, do standard divide }

   end else rdiv { standard divide }

end;

{*******************************************************************************

Generate modulo integer

Generates the modulo of integer. If the divisor is constant, and is a single
bit, then the mod can be accomplished by "anding" with a mask of all the bits
under it. Otherwise a simple register divide is done.

The register allocation level must give eax and edx for this operation. The
quotient in eax is discarded.

Divides have a fixed error mode, a trap to int 0.

*******************************************************************************}

procedure genmod(ip: intptr); { node to process }

var shft:    integer; { shift count }
    mask:    ssint;   { modulo mask }
    signed:  boolean; { signed status of operation }
    quad:  boolean; { operation is performed in double }
    i:       ssint;

{ perform register based modulo }

procedure rmod;

{ check within range constant }

function wthrng(ip: intptr): boolean;

var s: boolean;

begin

   s := false; { default not within range }
   { if the operand is not immediate, assume it could be overrange }
   if ip^.i = tilimint then
      { constant, now set according to within range }
      s := consti(ip^.base) <= maxint;

   wthrng := s { return within range status }

end;

begin

   { do register divide }
   gennod(ip^.right); { generate right }
   { see if either operand needs sign checking }
   if fovfchk then begin

      { Note that if the operand is constant, and we know it is overrange and
        will give an error, we let it fall into a runtime error. }
      if (chksgn(ip^.left^.rbase) <> signed) and not wthrng(ip^.left) then begin

         { check sign left }
         if ip^.left^.rbase^.size <= regsiz then gensgnchk(ip^.lreg) { dword }
         else gensgnchk(ip^.lregx) { qword }

      end;
      if (chksgn(ip^.right^.rbase) <> signed) and not wthrng(ip^.right) then begin

         { check sign right }
         if ip^.right^.rbase^.size <= regsiz then gensgnchk(ip^.rreg) { dword }
         else gensgnchk(ip^.rregx) { qword }

      end

   end;
   { see if either operand needs dword to qword extention }
   if quad then begin

      { check and expand left }
      if ip^.left^.rbase^.size <= regsiz then
         genext(chksgn(ip^.left^.rbase), ip^.lreg, ip^.lregx);
      { check and expand right }
      if ip^.right^.rbase^.size <= regsiz then
         genext(chksgn(ip^.right^.rbase), ip^.rreg, ip^.rregx)

   end;
   { check divide by negative check is on and divisor is signed }
   if fivochk and chksgn(ip^.right^.rbase) then begin

      if quad then begin

         { check divisor is signed, which is invalid }
         emitbyt($0b); { or r,r }
         emitbyt($c0+dreg(ip^.rregx)*8+dreg(ip^.rregx));
         genske($79, reivop) { generate invalid operand fault on signed }

      end else begin { single precision }

         { check divisor is signed, which is invalid }
         emitbyt($0b); { or r,r }
         emitbyt($c0+dreg(ip^.rreg)*8+dreg(ip^.rreg));
         genske($79, reivop) { generate invalid operand fault on signed }

      end

   end;
   { check zero divide check is on }
   if fzdvchk then begin { perform programmatic zero divide check }

      if quad then begin { double }

         { check right is zero }
         emitbyt($0b); { or r,r }
         emitbyt($c0+dreg(ip^.rreg)*8+dreg(ip^.rreg));
         emitbyt($75); { jnz over }
         { warning, the next calculation assumes that genske generates 7 bytes }
         emitbyt(9); { relative jump over next instructions }
         emitbyt($0b); { or rx,rx }
         emitbyt($c0+dreg(ip^.rregx)*8+dreg(ip^.rregx));
         genske($75, rezdiv) { generate zero divide fault }

      end else begin { single }

         { check right is zero }
         emitbyt($0b); { or r,r }
         emitbyt($c0+dreg(ip^.rreg)*8+dreg(ip^.rreg));
         genske($75, rezdiv) { generate zero divide fault }

      end

   end;
   { perform division }
   if quad then begin { double, perform with external routine }

      if signed then genrotcal(maclib_mods64) { use signed version }
      else genrotcal(maclib_modu64) { use unsigned version }

   end else begin { perform in direct code }

      if signed then begin { signed operation }

         emitbyt($99); { cdq }
         emitbyt($f7); { idiv eax,rr }
         emitbyt($c0+$07*8+dreg(ip^.rreg));
         { correct for signed result }
         emitbyt($0b); { or r,r }
         emitbyt($c0+dreg(ip^.rsreg)*8+dreg(ip^.rsreg));
         { skip if not signed }
         emitbyt($79); { jns over }
         emitbyt(2);
         emitbyt($03); { add r,r }
         emitbyt($c0+dreg(ip^.rsreg)*8+dreg(ip^.rreg))

      end else begin

         { clear high half of qword }
         emitbyt($33); { xor edx,edx }
         emitbyt($c0+dreg(rgedx)*8+dreg(rgedx));
         emitbyt($f7); { idiv eax,rr }
         emitbyt($c0+$06*8+dreg(ip^.rreg))

      end

   end

end;

begin

   { find signed or unsigned status of operation }
   signed := chksgn(ip^.left^.rbase) or chksgn(ip^.right^.rbase);
   { find if operation must be performed in quad precision math }
   quad := (ip^.left^.rbase^.size > regsiz) or
             (ip^.right^.rbase^.size > regsiz);
   gennod(ip^.left); { generate dividend }
   if ip^.right^.i = tilimint then begin { divide immediate }

      i.v := consti(ip^.right^.base); { get the constant }
      i.s := constis(ip^.right^.base);
      { 0 and 1 are eliminated in the above pass. Now we take all of the powers
        of 2 out. Check simple power. }
      shft := pow2(i); { find power }
      if (shft <> 0) and ssgeq(i, false, 0) then
         begin { shift value found, and not negative, perform it }

         { check and expand left }
         if (ip^.left^.rbase^.size <= regsiz) and quad then
            genext(chksgn(ip^.left^.rbase), ip^.lreg, ip^.lregx);
         { now find the mask by shifting up bits until not less than }
         mask.v := 1; { place starting mask }
         mask.s := false;
         while ssltn(mask, i) do mask.v := mask.v*2+1; { shift up }
         mask.v := mask.v div 2; { back one to be under bit }
         { generate "and" }
         gendoiir(true, $20, $20, ip^.lreg, ip^.lregx, quad, mask, true)

      end else rmod { not found, do standard }

   end else rmod { do standard }

end;

{*******************************************************************************

Generate optimized direct store

Accepts a intermediate node of the following type:

tistoint
tistochr
tistobol
tistofint
tistofchr
tistofbol

Generates several optimizations. If the right side is a constant, then a mov
constant to memory instruction is generated. If the right side is one of the
following operators:

tiaddint
tiandint
tiorint
tisubint
tixorint
timulint

And one of the operands matches the store object, then a special version of
the instruction is used. isubint only matches if the left side is equal to the
store operand.

*******************************************************************************}

procedure gensto(ip: intptr);

var i:         ssint;   { operand value }
    ins, ins2: byte;    { instruction codes }
    mode:      byte;    { instruction mode }
    size:      integer; { size of store }
    sgnsto:    boolean; { signed/unsigned status of store }
    quad:    boolean; { operation is performed in double }

procedure default;

var r, rx: regt;   { register holding }

begin

   gennod(ip^.left); { generate left }
   r := ip^.lreg; { set default source register }
   rx := ip^.lregx;
   { Check byte or word store operation from non-byte storable register edi or
     esi. If so, move to one or eax, ebx, edx, ecx. }
   if (size < regsiz) and
      ((ip^.lreg = rgedi) or (ip^.lreg = rgesi)) then begin

      emitbyt($8b); { mov ra, rb }
      emitbyt($c0+dreg(ip^.t2reg)*8+dreg(ip^.lreg));
      r := ip^.t2reg { set source now in storable register }

   end;
   { check is a pointer type }
   tp := basest(ip^.base);
   if tp^.t <> tptr then { not a pointer type }
      genbndxfr(ip^.base, ip^.left^.rbase, r, rx); { generate store bounds check }
   { see if either operand needs dword to qword extention }
   if quad and (ip^.left^.rbase^.size <= regsiz) then
      { extend sign only if both operands are signed }
      genext(chksgn(ip^.left^.rbase) and sgnsto, ip^.lreg, ip^.lregx);
   if ip^.base^.t = tfunc then begin { function result }

      if quad then begin { quad precision store }

         genstosor(ip^.t1reg, dreg(r), ip^.base^.fncr, regsiz, 0);
         genstosor(ip^.t1reg, dreg(rx), ip^.base^.fncr, regsiz, regsiz);

      end else { single precision }
         genstosor(ip^.t1reg, dreg(r), ip^.base^.fncr, size, 0)

   end else begin { other }

      if quad then begin { quad precision store }

         genstosor(ip^.t1reg, dreg(r), ip^.base, regsiz, 0);
         genstosor(ip^.t1reg, dreg(rx), ip^.base, regsiz, regsiz)

      end else { single precision }
         genstosor(ip^.t1reg, dreg(r), ip^.base, size, 0)

   end

end;

{ process operator to store object }

procedure prcopr;

var signed: boolean; { signed status of operation }

begin

   if size >= regsiz then begin { must be dword or qword }

      { find signed or unsigned status of operation }
      signed := chksgn(ip^.left^.left^.rbase) or chksgn(ip^.left^.right^.rbase);
      { check signed status of operation matches destination, or overflow
        checking is off. If checking of the unregistered destination is
        required, then this optimization becomes too expensive, since we would
        have to pull it to a register or generate a separate instruction. }
      if (signed = chksgn(ip^.left^.left^.rbase)) or not fovfchk then begin

         gennod(ip^.left^.right); { resolve the right one }
         { See if we need to check the sign of the registered operand. This
           to occur if the signed status does not match the operation, and
           is enabled. }
         if (signed <> chksgn(ip^.left^.right^.rbase)) and fovfchk then begin

            { sign check highest bit }
            if quad then gensgnchk(ip^.left^.right^.fregx)
            else gensgnchk(ip^.left^.right^.freg)

         end;
         { generate direct address instruction }
         gendir1r(ip^.base, ip^.left^.right^.t1reg, dreg(ip^.left^.right^.freg),
                  ins+$01, 0);
         if quad then { perform high half of double }
            gendir1r(ip^.base, ip^.left^.right^.t1reg,
                     dreg(ip^.left^.right^.fregx), ins2+$01, regsiz);
         { generate overflow check }
         if ins in [$00, $28] then begin

            if signed then genovf { signed }
            else gencar { unsigned }

         end
         { Note that we don't need the store sign check, because the destination
           and operation sign mode were in agreement. }

      end else default { use normal method }

   end else default { process as normal }

end;

begin

   setref(ip^.base); { set that is referenced }
   { Find size of store. Stores can be 1, 2, 4 or 8 bytes long. }
   if ip^.base^.t = tfunc then begin

      size := ip^.base^.fncr^.size; { find size }
      sgnsto := chksgn(ip^.base^.fncr) { find sign }

   end else begin

      size := ip^.base^.size; { find size }
      sgnsto := chksgn(ip^.base) { find sign }

   end;
   quad := size > regsiz; { find if double precision }
   if ip^.left^.i = tilimint then begin

      { operand is a constant }
      i.v := consti(ip^.left^.base); { get the constant }
      i.s := constis(ip^.left^.base);
      { check unsigned overrange value to signed }
      if sgnsto and (i.v > maxint) then generr(rerngchk) else begin

         { check negative value to unsigned }
         if not sgnsto and i.s then generr(rerngchk) else begin

            if ip^.base^.t = tfunc then { function result }
               genstoimmr(ip^.t1reg, ip^.base^.fncr, size, i)
            else
               genstoimmr(ip^.t1reg, ip^.base, size, i)

         end

      end

   end else if (ip^.left^.i = tiaddint) or (ip^.left^.i = tiandint) or
               (ip^.left^.i = tiorint) or (ip^.left^.i= tisubint) or
               (ip^.left^.i = tixorint) then begin { simple operator }

      { find instruction code for operator }
      case ip^.left^.i of

         tiaddint: begin ins := $00 { add }; ins2 := $10 { adc } end;
         tiandint: begin ins := $20 { and }; ins2 := $20 { and } end;
         tiorint:  begin ins := $08 { or  }; ins2 := $08 { or  } end;
         tisubint: begin ins := $28 { sub }; ins2 := $18 { sbc } end;
         tixorint: begin ins := $30 { xor }; ins2 := $30 { xor } end;

      end;
      { Check if the left side is the same as the result. This allows special
        instruction forms to be used. The case of right operand same is also
        possible with associative operators, but these are fipped to the left
        side by upper level code. }
      if basequ(ip^.base, ip^.left^.left) then begin

         { Check same left with immediate right, for which there are special
           instruction forms. }
         if (ip^.left^.right^.i = tilimint)  then begin { a := a op imm case }

            i.v := consti(ip^.left^.right^.base); { get constant value }
            i.s := constis(ip^.left^.right^.base);
            mode := $01; { set word mode }
            if size = 1 then mode := $00; { set byte mode }
            { check can be handled by a single inc or dec }
            if ((ip^.left^.i = tiaddint) or (ip^.left^.i = tisubint)) and
               ((ssequ(i, false, 1) or ssequ(i, true, 1))) and not quad then
               begin

               { check increment candidate }
               if (ssequ(i, false, 1) and (ip^.left^.i = tiaddint)) or
                  (ssequ(i, true, 1) and (ip^.left^.i = tisubint)) then begin

                  if size = 2 then { 16 bits }
                     gendir2r(ip^.base, ip^.t1reg, $00, $66, $fe+mode, $0)
                  else { 32 bits or 8 bits }
                     gendir1r(ip^.base, ip^.t1reg, $00, $fe+mode, $0)

               end else begin { decrement }

                  if size = 2 then { 16 bits }
                     gendir2r(ip^.base, ip^.t1reg, $01, $66, $fe+mode, $0)
                  else { 32 bits or 8 bits }
                     gendir1r(ip^.base, ip^.t1reg, $01, $fe+mode, $0)

               end;
               { perform overflow check }
               if chksgn(ip^.base) then genovf { signed }
               else gencar { unsigned }

            end else if sgnsto or (size >= regsiz) then begin

               { check unsigned overrange value to signed }
               if sgnsto and (i.v > maxint) then generr(rerngchk) else begin

                  { check negative value to unsigned }
                  if not sgnsto and i.s then generr(rerngchk) else begin

                     { Encode immediate to operator, which will always sign extend the
                       constant. }
                     if size = 2 then { 16 bits }
                        gendir2r(ip^.base, ip^.t1reg, ins div 8, $66, $80+mode, $0)
                     else { 64 bits, 32 bits or 8 bits }
                        gendir1r(ip^.base, ip^.t1reg, ins div 8, $80+mode, $0);
                     { generate appropriate size immediate }
                     if size = 1 then emitbyt(ss2int(i))
                     else if size = 2 then emitwrd(ss2int(i))
                     else emitint(ss2int(i));
                     if quad then begin { perform high half }

                        { get high half of constant }
                        if i.s then begin { set sign extend }

                           i.s := true;
                           i.v := 1

                        end else begin { set zero extend }

                           i.s := false; { set 0 }
                           i.v := 0

                        end;
                        gendir1r(ip^.base, ip^.t1regx, ins2 div 8, $80+mode, $0);
                        emitint(ss2int(i))

                     end;
                     { perform overflow check }
                     if ins in [$00, $28] then begin

                        if chksgn(ip^.base) then genovf { signed }
                        else gencar { unsigned }

                     end

                  end

               end

            end else prcopr { process operator }

         end else prcopr { process operator }

      end else default { default handling }

   end else default; { default handling }
   if fpusct <> 0 then error(esysflt200) { FPU stack should be empty }

end;

{*******************************************************************************

Generate optimized indirect store

Accepts a intermediate node of the following type:

istiint
istichr
istibol
istifint
istifchr
istifbol

Generates several optimizations. If the right side is a constant, then a mov
constant to memory instruction is generated. If the right side is one of the
following operators:

iaddint
iandint
iorint
isubint
ixorint
imulint

And one of the operands matches the store object, then a special version of
the instruction is used.

*******************************************************************************}

procedure genstoind(ip: intptr);

var i:       integer; { operand value }
    ins:     byte;    { instruction holder }
    size:    integer; { size of store }
    sr, srx: regt;    { source register }
    sgnsto:  boolean; { signed/unsigned status of store }
    quad:    boolean; { operation is performed in double }
    ti:      ssint;

{ perform constant store to address }

procedure stocst;

var i: ssint;

begin

   { operand is a constant }
   i.v := consti(ip^.right^.base); { get the constant }
   i.s := constis(ip^.right^.base);
   { check unsigned overrange value to signed }
   if sgnsto and (i.v > maxint) then generr(rerngchk)
   else begin

      { check negative value to unsigned }
      if not sgnsto and i.s then generr(rerngchk)
      else begin { skip to reduce code }

         gennod(ip^.left); { resolve address }
         if ip^.base^.size = 1 then ins := $c6 { mov [ra],imm8 }
         else ins := $c7; { move [ra],imm16/32 }
         if ip^.base^.size = 2 then emitbyt($66); { output 16 bit prefix }
         emitbyt(ins); { mov [ra],imm }
         emitbyt($00+$00*8+dreg(ip^.lreg)); { generate r/m byte }
         if ip^.base^.size = 1 then emitbyt(i) { output single byte constant }
         else if ip^.base^.size = 2 then emitwrd(i) { output word constant }
         else emitint(i); { output dword constant }
         if quad then begin { perform high half of quadword }

            { get high half of constant }
            if i.s then begin { set sign extend }

               i.s := true;
               i.v := 1

            end else begin { set zero extend }

               i.s := false; { set 0 }
               i.v := 0

            end;
            emitbyt(ins); { mov [ra],imm }
            emitbyt($40+$00*8+dreg(ip^.lreg)); { generate r/m byte }
            emitbyt(regsiz); { offset to high }
            emitint(i) { output dword constant }

         end

      end

   end

end;

{ perform default handling }

procedure dodef;

begin

   gennod(ip^.left); { resolve address }
   gennod(ip^.right); { resolve operand }
   { check byte store operation from non-byte storable register edi or esi }
   if (size = 1) and
      ((ip^.rreg = rgedi) or (ip^.rreg = rgesi)) then begin

      emitbyt($8b); { mov ra, rb }
      emitbyt($c0+dreg(ip^.t2reg)*8+dreg(ip^.rreg));
      sr := ip^.t2reg { set source now in storable register }

   end;
   { generate store bounds check }
   genbndxfr(ip^.base, ip^.right^.rbase, sr, srx);
   { perform indirect store }
   genstoindr(sr, srx, ip^.lreg, size)

end;

begin

   { find size of store }
   if ip^.base^.t = tfunc then begin

      size := ip^.base^.fncr^.size; { find size }
      sgnsto := chksgn(ip^.base^.fncr) { find sign }

   end else begin

      size := ip^.base^.size; { find size }
      sgnsto := chksgn(ip^.base) { find sign }

   end;
   quad := size > regsiz; { find if quad precision }
   if ip^.right^.i = tilimint then begin { constant }

      { check if we have an array on the left side }
      if ip^.left^.i = tiarrref then begin { array }

            if ip^.left^.base^.t <> tarray then error(einvfmt);
            i := ip^.left^.base^.arrt^.size; { get base type size }
            if i in [1, 2, 4, 8] then begin { proper base size }

               ti.v := consti(ip^.right^.base); { get the constant }
               ti.s := constis(ip^.right^.base);
               { check unsigned overrange value to signed }
               if sgnsto and (ti.v > maxint) then generr(rerngchk)
               else begin { skip the rest to reduce code }

                  { check negative value to unsigned }
                  if not sgnsto and ti.s then generr(rerngchk)
                  else begin { skip the rest to reduce code }

                     if ip^.left^.base^.arrt^.size = 1 then
                        ins := $c6 { mov [ra],imm8 }
                     else
                        ins := $c7; { mov [ra],imm16/32/64 }
                     { generate scaled array reference }
                     if ip^.left^.base^.arrt^.size = 2 then { prefix }
                        gensar(ip^.left, ip^.t1reg, $00, $00, quad, false,
                               $66, true, ins, $66, true, ins, i,
                               ip^.left^.base^.arrt^.size, ti)
                     else { no prefix }
                        gensar(ip^.left, ip^.t1reg, $00, $00, quad, false,
                               $00, false, ins, $00, false, ins, i,
                               ip^.left^.base^.arrt^.size, ti)

                  end

               end

            end else stocst { perform standard indirect store }

      end else stocst { perform standard indirect store }

   end else begin { nonconstant }

      sr := ip^.rreg; { set default source register }
      srx := ip^.rregx;
      { check if we have an array on the left side }
      if ip^.left^.i = tiarrref then begin { array }

         if ip^.left^.base^.t <> tarray then error(einvfmt);
         i := ip^.left^.base^.arrt^.size; { get base type size }
         if i in [1, 2, 4, 8] then begin { proper base size }

            gennod(ip^.right); { resolve operand }
            { check byte store operation from non-byte storable register edi or
              esi }
            if (size = 1) and
               ((ip^.rreg = rgedi) or (ip^.rreg = rgesi)) then begin

               emitbyt($8b); { mov ra, rb }
               emitbyt($c0+dreg(ip^.t2reg)*8+dreg(ip^.rreg));
               sr := ip^.t2reg { set source now in storable register }

            end;
            { generate store bounds check }
            genbndxfr(ip^.base, ip^.right^.rbase, sr, srx);
            if ip^.left^.base^.arrt^.size = 1 then ins := $88 { mov [ra],rl }
            else ins := $89; { move [ra],r }
            { generate scaled array reference }
            if quad then { quad precision }
               gensar(ip^.left, ip^.t1reg, dreg(sr), dreg(srx), quad, false,
                      $00, false, ins, $00, false, ins, i, 0, ti)
            else if ip^.left^.base^.arrt^.size = 2 then { word }
               gensar(ip^.left, ip^.t1reg, dreg(sr), 0, quad, false,
                      $66, true, ins, $00, true, ins, i, 0, ti)
            else { byte or dword }
               gensar(ip^.left, ip^.t1reg, dreg(sr), 0, quad, false,
                      $00, false, ins, $00, false, ins, i, 0, ti)

         end else dodef { perform default handling }

      end else dodef { perform default handling }

   end;
   if fpusct <> 0 then error(esysflt205) { FPU stack should be empty }

end;

{*******************************************************************************

Check routine parameter

Performs a check and precision adjustment of a parameter. Accepts a parameter
intermediate tree, and a prototype for the parameter. If the prototype is a
scalar type, it is bounded with reference to both the source and destination
types (see genbndxfr). Then, if the source is dword, and the destination is
qword, the source is extended according to the signed or unsigned status of the
parameter. To do that, the source must have had an extended register allocated
to it by the register pass.

*******************************************************************************}

procedure chkpar(tp: typptr;  { parameter prototype }
                 ip: intptr); { parameter }

begin

   tp := basest(tp); { get base type of parameter w/subs }
   { check is a boundable type }
   if tp^.t in [tenum, tenme, tsub, tcardinal, tinteger, tlcardinal, tlinteger,
                tboolean] then
      genbndxfr(tp, ip^.rbase, ip^.freg, ip^.fregx); { perform bounds check }
   { check if the operand needs dword to qword extention }
   if (ip^.rbase^.size <= regsiz) and (tp^.size > regsiz) then
      genext(chksgn(tp), ip^.freg, ip^.fregx)

end;

{*******************************************************************************

Generate routine call

Built in routines are almost identical to "transient" routines at this level.
The registers are allocated above us, and no real work is required here.
We generate subtrees for all the leaves below us, then perform the routine
call.

Accepts from 1 to 4 "parameter type forms", these are types (not ticalpar
entries) that represent the formal type of the parameter. The form types are
needed to process type conversions to the value parameters. The parameters that
don't exist are passed as nil, and are ignored.

Only types with bounds are presently checked for type, which include enumerated,
subrange, cardinal, integer, long integer, long cardinal, and boolean types. The
other types can be supplied or left nil to skip checking.

*******************************************************************************}

procedure genrot(ip:  intptr;  { node to generate }
                 pfp: typptr;  { routine to reference }
                 lp:  typptr;  { left prototype }
                 rp:  typptr;  { right prototype }
                 xp:  typptr;  { xtra prototype }
                 x2p: typptr); { xtra2 prototype }

begin

   { evaluate parameters }

   if ip^.left <> nil then gennod(ip^.left); { generate left }
   if lp <> nil then chkpar(lp, ip^.left); { check range }
   if ip^.right <> nil then gennod(ip^.right); { generate right }
   if rp <> nil then chkpar(rp, ip^.right); { check range }
   if ip^.xtra <> nil then gennod(ip^.xtra); { generate xtra }
   if xp <> nil then chkpar(xp, ip^.xtra); { check range }
   if ip^.xtra2 <> nil then gennod(ip^.xtra2); { generate xtra2 }
   if x2p <> nil then chkpar(x2p, ip^.xtra2); { check range }

   { generate routine call }

   genrotcal(pfp)

end;

{*******************************************************************************

Generate string compare

Compares two strings. A string compare stops after the first mismatching
character, and the sense of the flags is the same as left-right.

One of the operands must be in the esi register, and the other in the edi
register. Typically this is left->esi, right->edi, but the operands can be
reversed if the flags are also understood in reverse.
ecx and the flags are modified.

*******************************************************************************}

procedure gencmps(ip: intptr); { node to process }

begin

   gennod(ip^.left); { generate trees }
   gennod(ip^.right);
   emitbyt($c7); { mov ecx,len }
   emitbyt($c1);
   emitint(ip^.base^.size);
   emitbyt($f3); { repe }
   emitbyt($a6) { cmpsb }

end;

{*******************************************************************************

Convert conditional to boolean

If the node given is a flag, then a convertion to a boolean is generated for
it. Otherwise, no operation is performed. Accepts the node to process, and
the register it is to be placed in.

This routine accepts a flag to determine if the destination is cleared before
the boolean byte is set. Some applications require the entire register have the
boolean, such as parameter passing, and others, like store, are only going to
use the lower byte of the register.

*******************************************************************************}

procedure conflg(ip:  intptr;   { node to process }
                 r:   regt;     { register to place in }
                 clr: boolean); { clear destination register }

begin

   if ip^.rsreg = rgflg then begin { its a flag, convert it }

      if clr then begin { clear destination register }

         emitbyt($33); { xor r,r }
         emitbyt($c0+dreg(r)*8+dreg(r))

      end;
      { set register to boolean }
      emitbyt($0f); { setcc }
      emitbyt($90+ccode(ip^.rsflg));
      emitbyt($c0+$00*8+dreg(r));
      ip^.rsreg := r { set new register }

   end;

end;

{*******************************************************************************

Generate general string compare

Compares two general strings. A string compare stops after the first
mismatching character, and the sense of the flags is the same as left-right.
One of the operands must be in the esi register, and the other in the edi
register. Typically this is left->esi, right->edi, but the operands can be
reversed if the flags are also understood in reverse.

One of the length tags must be in ecx. The lengths are compared for equal, an
error processed if not, then the length in ecx is used to walk the string.

*******************************************************************************}

procedure gencmpg(ip: intptr); { node to process }

begin

   gennod(ip^.left); { generate trees }
   gennod(ip^.right);
   emitbyt($3b); { cmp ltr,rtr }
   emitbyt($c0+dreg(ip^.lregx)*8+dreg(ip^.rregx));
   genske($74, relenmat); { generate error }
   emitbyt($f3); { repe }
   emitbyt($a6) { cmpsb }

end;

{*******************************************************************************

Make hash table

Expects an unfinished hash table. First, we allocate a construction array of
case values, and an array of links. The links are set to 0 to indicate unfilled
entries (any value is ok for a case selector). Then, all the case values are
hashed and an attempt made to place them in the table. If there is already a
case occupying the slot, it is skipped. Each entry thus occupied has its link
set to -1. These are the "prime" entries, which we place first to avoid having
an entry occupy a slot that could have matched.

Next, the non-prime entries are laid in "chains". If an entry has -1, it means
"terminal" (all primes are terminal). If 0, it means "free". Other numbers
indicate a valid link. The entries are followed until a terminal is reached,
then the first free entry in the table is found and the case placed there, and
the link changed to terminal (-1). This is done until the values run out, which
they will by definition (since the table is the size of the case list).

The resulting table will have chains of case values, starting from the prime,
with -1 link indicating the terminal entry (which could be the prime).

Finally, the case list is saved, and replaced back into the same order as the
constructed hash table, then the links are placed into the list.

Note that although we construct the list with 1..n table format, it is output
adjusted to 0..n, which is more efficient for assembly language.

*******************************************************************************}

procedure makhst(tp: typptr); { hash table head }

var casval: pssintarr; { case values array }
    caslnk: pintarr;   { link pointers array }
    castyp: ptyparr;   { case selector entries }
    p:      typptr;    { pointer to case entries }
    len:    integer;   { number of cases in table }
    hold:   typptr;    { holding list }
    i:      integer;   { index for table }
    h:      integer;

{ find first free entry }

function free: integer;

var f: integer; { found free entry }
    i: integer; { index for table }

begin

   f := 0; { clear found }
   for i := 1 to len do if caslnk^[i] = 0 then f := i; { find free entry }
   free := f { return that }

end;

{ remove entry from case list }

procedure remove(    v: ssint; { case value to remove }
                 var p: typptr); { case entry pointer }

var lp: typptr; { last entry pointer }

begin

   lp := nil; { set no last entry }
   p := tp^.htn; { index top of case list }
   while ssnequ(p^.csv, v) do begin { find matching case }

      lp := p; { set new last }
      p := p^.csn; { link next }
      if p = nil then error(esysflt106) { no match, should not happen }

   end;
   if lp = nil then{ gap head of list }
     tp^.htn := tp^.htn^.csn
   else { gap mid list }
     lp^.csn := p^.csn

end;

begin

   if tp^.t <> thshtbl then error(esysflt107); { should not happen }
   len := tp^.htc; { get the entry count }
   { allocate holding tables }
   new(casval, len);
   new(caslnk, len);
   new(castyp, len);
   for i := 1 to len do begin { initalize tables }

      casval^[i].v := 0; { clear case value }
      casval^[i].s := false;
      caslnk^[i] := 0; { set unoccupied }
      castyp^[i] := nil { set no case entry type }

   end;
   { lay prime entries in table }
   p := tp^.htn; { index 1st case }
   while p <> nil do begin { set prime entries }

      h := p^.csv.v mod len+1; { find hash value }
      if caslnk^[h] = 0 then begin { lay down prime }

         casval^[h] := p^.csv; { place value }
         caslnk^[h] := -1; { set occupied }
         castyp^[h] := p { place type }

      end;
      p := p^.csn { link next case }

   end;
   { lay non-primes }
   p := tp^.htn; { index 1st case }
   while p <> nil do begin { set non-primes }

      h := p^.csv.v mod len+1; { find hash value }
      if ssnequ(casval^[h], p^.csv) then begin { not a prime entry }

         { find terminal entry }
         while caslnk^[h] > 0 do h := caslnk^[h];
         caslnk^[h] := free; { link to first free entry }
         h := caslnk^[h];
         if h = 0 then error(esysflt108); { table full, should not happen }
         casval^[h] := p^.csv; { place value }
         caslnk^[h] := -1;
         castyp^[h] := p { place type }

      end;
      p := p^.csn { link next case }

   end;
   if free <> 0 then error(esysflt109); { should have filled table }
   hold := nil; { clear holding list }
   for i := len downto 1 do begin { place list backwards }

      remove(casval^[i], p); { remove from case list }
      p^.csn := hold; { insert to holding list }
      hold := p;
      { place link }
      if caslnk^[i] > -1 then begin { there is a link }

         p^.csm := castyp^[caslnk^[i]]; { place type it links to }
         p^.csi := caslnk^[i]-1 { place chain }

      end else begin { no link }

         p^.csm := nil;
         p^.csi := -1

      end

   end;
   tp^.htn := hold { replace list with proper table }

end;

{******************************************************************************

Generate tag check series

Given a case list and a field within the case list, generates a series of
compares for the case values that reference the field. This is used to validate
that the tag field is active.

The tag field is expected to be loaded in a register, and that register is
passed.

Note that this could also be done by constructing a bitset with the valid
values, then checking against that. This would need a metric to see if there are
enough matching case values to be worth it. The constant set entry would have
to be added to the case entries.

******************************************************************************}

procedure gentagchk(fp: typptr; { field pointer }
                    cp: typptr; { case list pointer }
                    r:  regt);  { register containing tag field value }

var f:    boolean; { found field }
    mp:   typptr;  { pointer to match field }
    cnt:  integer; { count of case references that exist }
    lab:  typptr;  { branch label tracking entry }
    ctag: ssint;  { current tag value }

{ find field in field list }

function fndtaglst(p: typptr): boolean;  { field pointer }

var f: boolean; { found entry flag }

begin

   while p <> nil do begin { search for field }

      if p^.t <> tfield then error(einvfmt); { should be record }
      if p = fp then f := true; { found field }
      p := p^.fldn { link next field }

   end;

   fndtaglst := f { return result }

end;

begin

   gettypa(lab, tlab); { get label for skip }
   { traverse the case list looking for matching cases }
   while cp <> nil do begin

      if cp^.t <> tfcas then error(einvfmt); { bad format }
      if fndtaglst(cp^.fcsf) then begin { generate case check }

         ctag := cp^.fcss; { get start value }
         while ssleq(cp^.fcss, ctag) and ssgeq(cp^.fcse, ctag) do begin

            { generate compare for this value }
            gencmpi(r, ctag);
            { if found, jump over sequence }
            emitbyt($0f); { jz found }
            emitbyt($84);
            emitadr(lab, itradr); { output jump location }
            ctag.v := ssadd(ctag, false, 1) { increment tag value }

         end

      end;
      cp := cp^.fcsn { link next }

   end;
   { place error call at end of sequence }
   generr(retagact); { generate error call }
   gendistrp; { generate disassembly trip }
   lab^.addr := pgmcnt; { set error call location }

end;

{*******************************************************************************

Generate procedure/function call

Expects a procedure/function call node. Generates the prolog and elilog
sequences for a procedure or function call.

Performs the following actions:

1. Any in-use FPU registers are saved out to the stack. We know what is in use
   by the floating point stack depth counter.

2. The parameter types, known as real and "unreal" (or "all that is not real")
   are counted.

3. All of the real parameters are processed from right to left, and if they
   are registerable parameters, go to temps to unload the stack. If they are
   not registerable, they go to the stack. If they are short reals, they go
   directly to the stack, otherwise, they go to temps, then the address of
   that is stacked.

4. The real parameters are processed from left to right, and all of the
   registerable reals are brought back from their temps to their proper
   position on the FPU stack.

5. The unreal parameters are processed from right to left, and they are pushed
   onto the stack.

6. The unreal parameters are processed from left to right, and registerable
   unreals are brought back to their proper registers.

7. The call, direct or indirect, is made.

8. The contents of the FPU are restored from the stack.

For both the FPU and the standard register space, we perform a sequence that
involves clearing out all registers and FPU stack contents, essentially giving
a clean sheet of paper to the evaluation of each parameter expression.

In future inproments we will get better information on if the results
accumulated can coexist with the next parameters to be processed. This will
eliminate the need to always flush the register and FPU space while processing
parameters.

The requirement to save and restore the FPU comes from the calling convention.
We can accomplish better efficiency by placing the FPU contents in temps
instead, and then using the temps instead of the FPU stack contents.

*******************************************************************************}

procedure genprc(ip: intptr); { procedure entry }

var fstk:    integer; { FPU stacking counter }
    fpuscts: integer; { FPU stacking counter save }
    relcnt:  integer; { real counter }
    tgpcnt:  integer; { tagged pointer counter }
    stdcnt:  integer; { standard parameter counter }
    lab:     typptr;  { jump labels }
    plst:    typptr;  { parameter list }

    { Parameter information block. }

    allptot: integer; { number of total parameters }
    relptot: integer; { number of real parameters }
    tgpptot: integer; { number of tagged pointers }
    stdptot: integer; { number of standard parameters }
    tgprtot: integer; { number of registered tagged pointers }
    stdrtot: integer; { number of registered standard parameters }
    allreg:  regset;  { total register allocation mask }
    tgpreg:  regset;  { tagged pointer allocated registers }
    stdreg:  regset;  { standard allocated registers }

{ process bounds check on registered parameter }

procedure chkpar(pp:    typptr; { prototype specification of parameter }
                 bp:    typptr; { type specification of source expression }
                 r, rx: regt);  { register for parameter }

var tp: typptr; { type holder }

begin

   { see if we need to process range checks }
   if frngchk and ((pp^.t = tpar) or (pp^.t = twpar)) then begin

      tp := basest(pp); { get base type of parameter w/subs }
      { check is a boundable type }
      if tp^.t in [tenum, tenme, tsub, tcardinal, tinteger, tlcardinal,
                   tlinteger, tboolean] then
         genbndxfr(pp, bp, r, rx) { perform bounds check }

   end

end;

{ process real overflow parameters }

procedure relovf(ip: intptr); { list of stackable real parameters }

begin

   if ip <> nil then begin { there is a parameter }

      relovf(ip^.flow); { go to the depth of list first (right) }
      if realt(ip^.base) and (ip^.base^.t <> tvpar) then begin { found a real }

         if relcnt > maxfst then begin { in overflow counts }

            gennod(ip); { generate parameter to tos }
            if srealt(ip^.base) then begin { short real }

               { make space on stack }
               emitbyt($50+dreg(rgeax)); { push eax }
               { place top of FPU stack there }
               emitbyt($dd); { fstp [esp] }
               emitbyt($00+$03*8+$04);
               emitbyt($00+$04*8+$04)

            end else begin { real }

               genladr(ip^.t1reg, ip^.base2); { load address of temp to eax }
               { store real at address }
               emitbyt($dd); { fstp [eax] }
               emitbyt($00+$03*8+dreg(rgeax));
               { then save address on stack }
               emitbyt($50+dreg(rgeax)) { push eax }

            end;
            if ip^.base^.t <> tvpar then { not a var param }
               fpusct := fpusct-1 { remove the stack count }

         end;
         relcnt := relcnt-1 { count off reals }


      end

   end

end;

{ stack real parameters }

procedure relplc(ip: intptr); { list of stackable real parameters }

begin

   if ip <> nil then begin { there is a parameter }

      relplc(ip^.flow); { go to the depth of list first (right) }
      if realt(ip^.base) and (ip^.base^.t <> tvpar) then begin { its a real }

         if relcnt <= maxfst then { in register counts }
            gennod(ip); { generate parameter }
         relcnt := relcnt-1 { count off reals }

      end

   end

end;

{ process tagged pointer and procedure/function overflow parameters }

procedure tgpovf(ip: intptr); { list of  parameters }

begin

   if ip <> nil then begin { there is a parameter }

      tgpovf(ip^.flow); { go to the depth of list first (right) }
      if tgpt(ip^.base) or pfpt(ip^.base) then begin { its tagged }

         if tgpcnt > tgprtot then begin { in overflow counts }

            gennod(ip); { generate parameter }
            emitbyt($50+dreg(ip^.fregx)); { push r }
            emitbyt($50+dreg(ip^.freg)) { push r }

         end;
         tgpcnt := tgpcnt-1 { count off }

      end

   end

end;

{ stack tagged pointer and procedure/function parameters }

procedure tgpplc(ip: intptr); { list of  parameters }

var pc: integer; { tagged parameter number }

begin

   pc := 1; { set what unreal we are processing }
   while (ip <> nil) and (pc <= tgprtot) do begin

      { a parameter exists, and not out of registerable parameters }
      if tgpt(ip^.base) or pfpt(ip^.base) then begin { found }

         gennod(ip); { place parameter in its registers }
         pc := pc+1 { count }

      end;
      ip := ip^.flow { next parameter }

   end

end;

{ process standard overflow parameters }

procedure stdovf(ip: intptr); { list of parameters }

begin

   if ip <> nil then begin { there is a parameter }

      stdovf(ip^.flow); { go to the depth of list first (right) }
      if not (realt(ip^.base) and (ip^.base^.t <> tvpar)) and
         not tgpt(ip^.base) and
         not pfpt(ip^.base) then begin { is a standard type }

         if stdcnt > stdrtot then begin { in overflow counts }

            gennod(ip); { generate parameter }
            { perform parameter range check as required }
            chkpar(ip^.base, ip^.left^.base, ip^.freg, ip^.fregx);
            { check if the operand needs dword to qword extention }
            if (ip^.left^.rbase^.size <= regsiz) and
               (ip^.base^.size > regsiz) then
               genext(chksgn(ip^.base), ip^.freg, ip^.fregx);
            { check is quad word parameter }
            if (ip^.base^.size > regsiz) and intt(ip^.base) then
               emitbyt($50+dreg(ip^.fregx)); { push r }
            emitbyt($50+dreg(ip^.freg)) { push r }

         end;
         stdcnt := stdcnt-1 { count off }

      end

   end

end;

{ place standard parameters in registers }

procedure stdplc(ip: intptr); { list of  parameters }

var pc: integer; { tagged parameter number }

begin

   pc := 1; { set what unreal we are processing }
   while (ip <> nil) and (pc <= stdrtot) do begin

      { a parameter exists, and not out of registerable parameters }
      if not (realt(ip^.base) and (ip^.base^.t <> tvpar)) and
         not tgpt(ip^.base) and not pfpt(ip^.base) then begin { found }

         gennod(ip); { place parameter in its register }
         { perform parameter range check as required }
         chkpar(ip^.base, ip^.left^.base, ip^.freg, ip^.fregx);
         { check if the operand needs dword to qword extention }
         if (ip^.left^.rbase^.size <= regsiz) and
            (ip^.base^.size > regsiz) and intt(ip^.base) then
            genext(chksgn(ip^.base), ip^.freg, ip^.fregx);
         pc := pc+1 { count }

      end;
      ip := ip^.flow { next parameter }

   end

end;

begin

   { Save any current contents of the FPU. }
   if fpusct > 0 then begin { stack out FPU contents }

      { make space on stack }
      emitbyt($83); { sub esp,fpusct*relsiz }
      emitbyt($c0+$05*8+$04);
      emitbyt(fpusct*relsiz);
      for fstk := 1 to fpusct do begin { pop and place FPU stack contents }

         emitbyt($dd); { fstp (fstl-1)*relsiz[esp] }
         emitbyt($40+$03*8+$04);
         emitbyt($00+$04*8+$04);
         emitbyt((fstk-1)*relsiz)

      end

   end;
   fpuscts := fpusct; { save stacking count }
   fpusct := 0; { clear floating point stack }

   { Perform metering of all parameters. }

   case ip^.i of { index parameter list by type }

      tiprccal, tiprccalo:  plst := ip^.base^.prcp;
      tiprccali: plst := ip^.base^.pprp;
      tifnccal, tifnccalo:  plst := ip^.base^.fncp;
      tifnccali: plst := ip^.base^.pfnp

   end;
   regfit(plst, allptot, relptot, tgpptot, stdptot, tgprtot, stdrtot, allreg,
           tgpreg, stdreg);

{;writeln('allptot: ', allptot:1, ' relptot: ', relptot:1,
          ' tgpptot: ', tgpptot:1, ' stdptot: ', stdptot:1,
          ' tgprtot: ', tgprtot:1, ' stdrtot: ', stdrtot:1);}

   { stack overflow parameters }

   relcnt := relptot; { reset counter }
   relovf(ip^.flow2); { process real overflow parmeters to stack }
   tgpcnt := tgpptot; { reset counter }
   tgpovf(ip^.flow2); { process tagged pointer overflow parmeters to stack }
   stdcnt := stdptot; { reset counter }
   stdovf(ip^.flow2); { process standard overflow parmeters to stack }

   { Place parameters in registers }

   relcnt := relptot; { reset counter }
   relplc(ip^.flow2); { process real overflow parmeters to registers }
   tgpplc(ip^.flow2); { process tagged pointer overflow parmeters to registers }
   stdplc(ip^.flow2); { process standard overflow parmeters to registers }

   { Generate call to procedure/function }

   if chkrotext(ip^.base) then genunlock; { unlock if leaving module }
   if (ip^.i = tiprccali) or (ip^.i = tifnccali) then
      begin { call indirect }

      { verify base is correct }
      if (ip^.base^.t <> tpproc) and
         (ip^.base^.t <> tpfunc) then error(esysflt231);
      { We use an indirect call sequence that does not affect the registers,
        loaded with parameters. The intermediate code at the left to load the
        address is not used.

        We need to go to a routine addressed by the ebp, but with a new ebp. We
        save the old ebp, save the return address save the address to call, load
        the new ebp, then perform a return to the called routine. }
      gettyp(lab, tlab); { get jump over label }
      emitbyt($55); { push ebp }
      emitbyt($68); { push return }
      emitadr(lab, itadr); { place address dword }

      if ip^.base^.level <> blkcnt then begin

         { The procedure/function parameter is from an outter routine, we
           need to load another ebp to get at it. }
         emitbyt($8b); { mov x,[ebp-lvl] }
         { offset to proper display level }
         if sbyte(-((ip^.base^.level-1)*4)) then begin

            emitbyt($40+$05*8+$05);
            emitbyt(-((ip^.base^.level-1)*4))

         end else begin

            emitbyt($80+$05*8+$05);
            emitint(-((ip^.base^.level-1)*4))

         end;

      end;
      emitbyt($ff); { push off[ebp], address of procedure/function }
      emitbyt($80+$06*8+$05);
      emitadr(ip^.base, itadr); { place address dword }
      emitbyt($8b); { mov ebp,off[ebp+4] }
      emitbyt($80+$05*8+$05);
      { place address of frame pointer }
      emitadro(ip^.base, itadr, ptrsiz); { place address dword }
      { go routine }
      emitbyt($c3); { ret }
      lab^.addr := pgmcnt; { set return location }
      emitbyt($5d) { pop ebp }

   end else if (ip^.i = tiprccalo) or (ip^.i = tifnccalo) then begin

      { call inherited procedure/function }
      if (ip^.base^.t <> tproc) and (ip^.base^.t <> tfunc) then error(einvfmt);
      emitbyt($ff); { call [addr] }
      emitbyt($00+$02*8+$05);
      if ip^.base^.t = tproc then emitadr(ip^.base^.prcol^.prcvv, itadr)
      else emitadr(ip^.base^.fncol^.fncvv, itadr)

   end else begin { call direct }

      { call procedure/function }
      emitbyt($e8); { call addr }
      emitadr(ip^.base, itradr) { generate address }

   end;
   if chkrotext(ip^.base) then genlock; { relock if reentering module }

   { restore contents of FPU from stack }

   fpusct := fpuscts; { restore old stacking count }
   if fpusct > 0 then begin { restore FPU contents }

      for fstk := fpusct downto 1 do begin { restore FPU content }

         emitbyt($dd); { fld (fstl-1)*relsiz[esp] }
         emitbyt($40+$00*8+$04);
         emitbyt($00+$04*8+$04);
         emitbyt((fstk-1)*relsiz);
         { If there is a real result, must keep that on top. This can be
           improved by performing only at the end of all loads. }
         if (ip^.i = tifnccal) or (ip^.i = tifnccalo) then
            if realt(ip^.base^.fncr) then begin

            emitbyt($d9); { fxch }
            emitbyt($c9)

         end

      end;
      { remove space from stack }
      emitbyt($83); { add esp,fpusct*relsiz }
      emitbyt($c0+$00*8+$04);
      emitbyt(fpusct*relsiz);

   end;

   { check real result of function }

   if (ip^.i = tifnccal) or (ip^.i = tifnccalo) then
      if realt(ip^.base^.fncr) then begin

      { add return real to stack depth }
      fpusct := fpusct+1; { increase FPU stack depth }
      if fpusct > maxfst then error(efstkovf) { too many stack levels }

   end;

   setref(ip^.base) { register references for the call }

end;

{*******************************************************************************

Generate new/dispose

Accepts the operator node. The tag list, if any, is traversed and the complete
type size built. Then the allocate or deallocate is done. Although the tags are
accepted (and checked) on dispose, as the standard requires, they are unused
in IP.
You might note that we recheck the links that were checked at the top level.
Since the consequence of a missed check is space, this pays back for now.

*******************************************************************************}

procedure gennwdp(ip: intptr);

var tp:          typptr; { pointer to type }
    rsiz, rsiz1: integer; { record sizes }
    ip1:         intptr; { intermediate pointer }

begin

   tp := ip^.base; { get variable type }
   if tp^.t <> tptr then error(esysflt110); { must be pointer }
   tp := tp^.ptrt; { link base type }
   rsiz := tp^.size; { set whole size }
   ip1 := ip^.right; { read the next tag }
   if tp^.t = trecord then begin { it's a record, process tagging }

      rsiz1 := tp^.size; { clear tag size }
      tp := tp^.recf; { index field list }
      rsiz := 0; { clear total size }
      while ip1 <> nil do begin { get tags }

         if ip1^.i <> titag then error(esysflt234);
         if ip1^.base^.t <> ticst then error(esysflt235);
         { a more compact form was specified than the whole type,
           so we find the new minimum size by finding
           all the fixed elements, adding that to the total, and
           then finding a new minimum }
         while tp^.t = tfield do begin { add fixed fields }

            rsiz := rsiz+tp^.fldt^.size; { add in size }
            tp := tp^.next; { next entry }
            if tp = nil then error(esysflt111); { invalid format }

         end;
         { now we should be pointing at the tag }
         if tp^.t <> tftag then error(esysflt112); { invalid format }
         if tp^.ftge then { tag field exists }
            rsiz := rsiz+tp^.size; { add in tag size }
         tp := tp^.ftgc; { index case list }
         while ssgtn(tp^.fcss, ip1^.base^.ival) or
               ssltn(tp^.fcse, ip1^.base^.ival) do begin { find matching case }

            tp := tp^.fcsn;
            if tp = nil then error(esysflt113) { invalid format }

         end;
         rsiz1 := tp^.size; { find new minimum }
         tp := tp^.fcsf; { index that case list }
         ip1 := ip1^.flow { index next tag }

      end;
      rsiz := rsiz+rsiz1 { add any tag size }

   end;
   if ip1 <> nil then error(esysflt114); { should be terminated }
   if ip^.i = tinew then begin

      { Because the actual routine for new accepts a tagged pointer, we have to
        first allocate to a temp, then load the pointer from that. }
      genladr(ip^.t1reg, ip^.base2); { index temp to eax }
      { load size }
      emitbyt($c7); { mov ebx,imm32 }
      emitbyt($c0+$00*8+dreg(rgebx));
      emitint(rsiz);
      { generate routine call }
      genrotcal(syslib_getspace);
      genlodsor(ip^.t1reg, ip^.base2, regsiz, 0); { load address from that }
      gennod(ip^.left); { generate variable to allocate }
      { store to final }
      emitbyt($89); { movd [rd],rs }
      emitbyt($00+dreg(ip^.t1reg)*8+dreg(ip^.lreg))

   end else begin

      { Dispose is also a format change to tagged pointer, but its easier
        because we just add the length. }
      gennod(ip^.left); { generate pointer to eax }
      { load length in to ebx register }
      emitbyt($c7); { mov r,imm32 }
      emitbyt($c0+$00*8+dreg(rgebx));
      emitint(rsiz);
      { call routine }
      genrotcal(syslib_putspace)

   end

end;

{*******************************************************************************

Generate real compare

Compares the TOS with the SOS in the FPU, then moves the flags from the FPU to
the CPU flags. Also checks for FPU errors if the option is on.

*******************************************************************************}

procedure gencmprel(ip: intptr);

begin

   { we load the operands backwards to make the flags correct }
   gennod(ip^.right); { generate right to sos }
   gennod(ip^.left); { generate left to tos }
   { compare and remove both }
   emitbyt($de); { fcompp }
   emitbyt($d9);
   { transfer fpu flags to integer unit flags }
   emitbyt($df); { fnstsw ax }
   emitbyt($e0);
   if ffputrp then begin { perform FPU error check }

      { check any error bit is on }
      emitbyt($66); { test ax,fpuexe }
      emitbyt($a9);
      emitwrd(fpuexe);
      emitbyt($74); { jz over }
      emitbyt(5); { relative jump over error call }
      genrotcal(maclib_fpuerr) { call error }

   end;
   emitbyt($9e) { sahf }

end;

{*******************************************************************************

Generate flag to boolean convertion

Given the second instruction byte for a setcc instruction, a clear of the
given register, followed by a setcc into that register is generated.

*******************************************************************************}

procedure genflg2bol(ins: byte; { instruction code to generate }
                     r:   regt); { result register }

begin

   { place condition in low byte }
   emitbyt($0f); { setcc r }
   emitbyt(ins);
   emitbyt($c0+dreg(r));
   { extend to 32 bits }
   emitbyt($0f); { movzx r32,r8 }
   emitbyt($b6);
   emitbyt($c0+dreg(r)*8+dreg(r));


end;

{*******************************************************************************

Generate for loop

Generates for loops, both 'to' and 'downto'. The loop types are separated into
arbitrary lemgth loops and constant length loops. Constant length loops have
an optimized form that uses a fixed count, and a check at the bottom of the
loop. In addition, constant loops are unrolled by the user specified order if
they fit within the size limit.

*******************************************************************************}

procedure genfor(ip: intptr);

var lab1, lab2: typptr;  { jump labels }
    span:       ssint;   { constant loop span }
    rolspn:     integer; { span in unrolls }
    i:          integer;
    unrl:       integer; { for loop unroll count }
    iref:       boolean; { control variable is referenced in loop }
    r:          regt;    { register holder }
    s, e:       ssint;   { start and end values }
    quad:       boolean; { quad index variable }
    signed:     boolean; { signed index variable }
    ti:         ssint;

{ generate for body }

procedure body;

var mode: byte; { instruction mode }

begin

   genlst(ip^.flow2); { generate statement block }
   if iref then begin { standard model index handling }

      genladr(ip^.lreg, ip^.base); { load address of control variable }
      if (ip^.i = tifortint) or (ip^.i = tifortchr) or
         (ip^.i = tifortbol) then begin { to }

         { output increment }
         if ip^.base^.size = 1 then emitbyt($fe) { byte }
         else if ip^.base^.size = 2 then begin { word }

            emitbyt($66);
            emitbyt($ff)

         end else emitbyt($ff); { dword }
         emitbyt($00+$00*8+dreg(ip^.lreg))

      end else begin { downto }

         { output decrement }
         if ip^.base^.size = 1 then emitbyt($fe) { byte }
         else if ip^.base^.size = 2 then begin { word }

            emitbyt($66);
            emitbyt($ff)

         end else emitbyt($ff); { dword }
         emitbyt($00+$01*8+dreg(ip^.lreg))

      end

   end else begin { downcount model index handling }

      mode := $01; { set word mode }
      if ip^.base^.size = 1 then mode := $00; { set byte mode }
      { if 16 bits, output mode change }
      if ip^.base^.size = 2 then { 16 bits }
        gendir2r(ip^.base, ip^.lreg, $01, $66, $fe+mode, $0)
      else { 32 bits }
        gendir1r(ip^.base, ip^.lreg, $01, $fe+mode, $0)

   end

end;

begin

   quad := ip^.base^.size > regsiz; { set quad word index }
   signed := chksgn(ip^.base); { set signed index }
   { Check its a constant loop. Constant loops can be turned into bottom
     check loops, with a simple count variable. }
   if (ip^.left^.i = tilimint) and (ip^.right^.i = tilimint) then begin

      unrl := 1; { set default unroll count }
      { find length of loop }
      s.v := consti(ip^.left^.base); { get starting value }
      s.s := constis(ip^.left^.base);
      e.v := consti(ip^.right^.base); { get ending value }
      e.s := constis(ip^.right^.base);
      if (ip^.i = tifortint) or (ip^.i = tifortchr) or
         (ip^.i = tifortbol) then begin { to }

         ti.v := sssub(e, s);
         ti.s := sssubs(e, s);
         span.v := ssadd(ti, false, 1);
         span.s := ssadds(ti, false, 1)

      end else begin { downto }

         ti.v := sssub(s, e);
         ti.s := sssubs(s, e);
         span.v := ssadd(ti, false, 1);
         span.s := ssadds(ti, false, 1)

      end;
      if span.s then error(esysflt228); { should not be negative }
      { Determine if we can unroll it, and by how much. Note we need to
        check if the loop body contains goto labels or cases, and refuse if so.
        Also need to determine if a loop is too large to unroll. }
      if funrol then { enabled }
         if cntint(ip^.flow2) <= forlen then { within for loop length threshold }
            if not labeled(ip^.flow2) and not chkcas(ip^.flow2) then
               { does not contain a label or case statement }
               unrl := rolnum; { set unroll order }
      rolspn := span.v div unrl * unrl; { find span inside unrolls }
      { Check control variable is referenced within the loop, or there is a goto
        in the loop. This controls optimizations, because we can do more if the
        variable is not referenced, like downcount the loop. We do the goto
        check because it might jump out of the loop, which ISO 7185 requires to
        leave the variable set. }
      iref := chkvarref(ip^.flow2, ip^.base) or chkgto(ip^.flow2);
      { store start to index }
      if iref then begin { standard loop variable sets }

         ti.v := consti(ip^.left^.base);
         ti.s := constis(ip^.left^.base);
         genstoimmr(ip^.t1reg, ip^.base, ip^.base^.size, ti)

      end else begin { downcount loop variable sets }

         ti.v := span.v div unrl*unrl;
         ti.s := false;
         genstoimmr(ip^.t1reg, ip^.base, ip^.base^.size, ti);

      end;
      { check span is greater than the unroll plus the remainder }
      if span.v > unrl+(span.v mod unrl) then begin

         { generate looping section }
         gettypa(lab1, tlab); { get a loop label }
         lab1^.addr := pgmcnt; { set loop location }
         for i := 1 to unrl do body; { instantiate unrolled loops }
         if iref then begin { standard model index }

            { Note that the address of the control variable will still be in a
              register. Now compare that with the max unroll count. }
            if ip^.base^.size = 2 then emitbyt($66); { cmp m,imm }
            emitbyt($80+ord(ip^.base^.size > 1));
            emitbyt($00+$07*8+dreg(ip^.lreg));
            if (ip^.i = tifortint) or (ip^.i = tifortchr) or
               (ip^.i = tifortbol) then begin { to }

               ti.v := ssadd(s, false, rolspn);
               ti.s := ssadds(s, false, rolspn)

            end else begin { downto }

               ti.v := sssub(s, false, rolspn);
               ti.s := sssubs(s, false, rolspn)

            end;
            { emit constant by size }
            if ip^.base^.size = 1 then emitbyt(ti)
            else if ip^.base^.size = 2 then emitwrd(ti)
            else emitint(ti)

         end;
         { generate jump loop }
         if sbyte(lab1^.addr-(pgmcnt+2)) then
            begin { generate byte offset jump }

            emitbyt($75); { jnz loop }
            emitadr(lab1, itbradr) { output jump location }

         end else begin { generate dword offset jump }

            emitbyt($0f); { jnz loop }
            emitbyt($85);
            emitadr(lab1, itradr) { output jump location }

         end;
         { output fraction of span to make up loops missed above }
         for i := 1 to span.v mod unrl do body

      end else
      { if the unroll count is less than or equal to the span with remainder,
        we don't bother to generate a loop at all, just convert to repetition }
         for i := 1 to span.v do body

   end else begin { generate arbitrary loop }

      { check any side effects in start or end expressions }
      if not (chkfncexp(ip^.left) or chkfncexp(ip^.right)) then begin

         { no side effects in start and end expressions, reorder for best
           effect }
         gennod(ip^.right); { generate ending expression }
         { bounds check the store to index }
         genbndxfr(ip^.base, ip^.right^.rbase, ip^.rreg, ip^.rregx);
         { check and extend dword to quadword }
         if quad and (ip^.right^.rbase^.size <= regsiz) then
            genext(chksgn(ip^.right^.rbase), ip^.rreg, ip^.rregx);
         { store end expression to temp }
         if quad then begin { perform quadword store }

            genstosor(ip^.t1reg, dreg(ip^.rreg), ip^.base2, regsiz, 0);
            genstosor(ip^.t1reg, dreg(ip^.rregx), ip^.base2, regsiz, regsiz)

         end else { dword or smaller }
            genstosor(ip^.t1reg, dreg(ip^.rreg), ip^.base2, ip^.base2^.size, 0);
         gennod(ip^.left); { generate starting expression }
         { bounds check the store to index }
         genbndxfr(ip^.base, ip^.left^.rbase, ip^.lreg, ip^.lregx);
         { check and extend dword to quadword }
         if quad and (ip^.left^.rbase^.size <= regsiz) then
            genext(chksgn(ip^.left^.rbase), ip^.lreg, ip^.lregx)

      end else begin { strictly ordered startup for loop }

         gennod(ip^.left); { generate starting expression }
         { bounds check the store to index }
         genbndxfr(ip^.base, ip^.left^.rbase, ip^.lreg, ip^.lregx);
         { check and extend dword to quadword }
         if quad and (ip^.left^.rbase^.size <= regsiz) then
            genext(chksgn(ip^.left^.rbase), ip^.lreg, ip^.lregx);
         { store start end expression to temp }
         if quad then begin { perform quadword store }

            genstosor(ip^.t2reg, dreg(ip^.lreg), ip^.base3, regsiz, 0);
            genstosor(ip^.t2reg, dreg(ip^.lregx), ip^.base3, regsiz, regsiz)

         end else { dword or smaller }
            genstosor(ip^.t2reg, dreg(ip^.lreg), ip^.base3, ip^.base3^.size, 0);
         gennod(ip^.right); { generate ending expression }
         { bounds check the store to index }
         genbndxfr(ip^.base, ip^.right^.rbase, ip^.rreg, ip^.rregx);
         { check and extend dword to quadword }
         if quad and (ip^.right^.rbase^.size <= regsiz) then
            genext(chksgn(ip^.right^.rbase), ip^.rreg, ip^.rregx);
         { store end expression to temp }
         if quad then begin { perform quadword store }

            genstosor(ip^.t1reg, dreg(ip^.rreg), ip^.base2, regsiz, 0);
            genstosor(ip^.t1reg, dreg(ip^.rregx), ip^.base2, regsiz, regsiz)

         end else { dword or smaller }
            genstosor(ip^.t1reg, dreg(ip^.rreg), ip^.base2, ip^.base2^.size, 0);
         { load start expression from temp }
         genlodsor(ip^.lreg, ip^.base3, ip^.base3^.size, 0)

      end;
      { store start to control variable }
      r := ip^.lreg; { set default source register }
      { check byte or word store operation from non-byte storable register edi
        or esi }
      if (ip^.base^.size <> 4) and
         ((ip^.lreg = rgedi) or (ip^.lreg = rgesi)) then begin

         emitbyt($8b); { mov ra, rb }
         emitbyt($c0+dreg(ip^.t2reg)*8+dreg(ip^.lreg));
         r := ip^.t2reg { set source now in storable register }

      end;
      if quad then begin { perform quadword store }

         genstosor(ip^.t1reg, dreg(r), ip^.base, regsiz, 0);
         genstosor(ip^.t1reg, dreg(ip^.lregx), ip^.base, regsiz, regsiz)

      end else { dword or smaller }
         genstosor(ip^.t1reg, dreg(r), ip^.base, ip^.base^.size, 0);
      gettypa(lab1, tlab); { get a loop label }
      gettypa(lab2, tlab); { get an exit label }
      lab1^.addr := pgmcnt; { set loop location }
      { load control variable }
      if quad then begin { perform quadword load }

         genlodsor(ip^.lreg, ip^.base, regsiz, 0);
         genlodsor(ip^.lregx, ip^.base, regsiz, regsiz)

      end else { dword or smaller }
         genlodsor(ip^.lreg, ip^.base, ip^.base^.size, 0);
      { load end variable }
      if quad then begin { perform quadword load }

         genlodsor(ip^.rreg, ip^.base2, regsiz, 0);
         genlodsor(ip^.rregx, ip^.base2, regsiz, regsiz)

      end else { dword or smaller }
         genlodsor(ip^.rreg, ip^.base2, ip^.base2^.size, 0); { load end }
      if quad then begin { quadword compare }

         emitbyt($3b); { cmp rlx, rrx }
         emitbyt($c0+dreg(ip^.rregx)*8+dreg(ip^.lregx));
         if (ip^.i = tifortint) or (ip^.i = tifortchr) or
            (ip^.i = tifortbol) then begin { to }

            emitbyt($0f); { jl end }
            if signed then emitbyt($8c) else emitbyt($82);
            emitadr(lab2, itradr); { output jump location }
            emitbyt($75); { jnz over }
            emitbyt(8)

         end else begin { downto }

            emitbyt($0f); { jg end }
            if signed then emitbyt($8f) else emitbyt($87);
            emitadr(lab2, itradr); { output jump location }
            emitbyt($75); { jnz over }
            emitbyt(8)

         end

      end;
      emitbyt($3b); { cmp rl, rr }
      emitbyt($c0+dreg(ip^.rreg)*8+dreg(ip^.lreg));
      if (ip^.i = tifortint) or (ip^.i = tifortchr) or
         (ip^.i = tifortbol) then begin { to }

         emitbyt($0f); { jl end }
         if signed then emitbyt($8c) else emitbyt($82);
         emitadr(lab2, itradr) { output jump location }

      end else begin { downto }

         emitbyt($0f); { jg end }
         if signed then emitbyt($8f) else emitbyt($87);
         emitadr(lab2, itradr) { output jump location }

      end;
      genlst(ip^.flow2); { generate statement block }
      { load control variable }
      if quad then begin { perform quadword load }

         genlodsor(ip^.lreg, ip^.base, regsiz, 0);
         genlodsor(ip^.lregx, ip^.base, regsiz, regsiz);

      end else { dword or smaller }
         genlodsor(ip^.lreg, ip^.base, ip^.base^.size, 0);
      { load end }
      if quad then begin { perform quadword load }

         genlodsor(ip^.rreg, ip^.base2, regsiz, 0);
         genlodsor(ip^.rregx, ip^.base2, regsiz, regsiz);

      end else { dword or smaller }
         genlodsor(ip^.rreg, ip^.base2, ip^.base2^.size, 0);
      { check done }
      if quad then begin { perform high half comparision }

         emitbyt($3b); { cmp rl, rr }
         emitbyt($c0+dreg(ip^.rregx)*8+dreg(ip^.lregx));
         emitbyt($75); { jnz over }
         emitbyt(8)

      end;
      emitbyt($3b); { cmp rl, rr }
      emitbyt($c0+dreg(ip^.rreg)*8+dreg(ip^.lreg));
      emitbyt($0f); { je end }
      emitbyt($84);
      emitadr(lab2, itradr); { output jump location }
      genladr(ip^.lreg, ip^.base); { load address of control variable }
      if (ip^.i = tifortint) or (ip^.i = tifortchr) or
         (ip^.i = tifortbol) then begin { to }

         { output increment }
         if quad then begin { quadword increment }

            emitbyt($83); { add [i],1 }
            emitbyt($00+$00*8+dreg(ip^.lreg));
            emitbyt(1);
            emitbyt($83); { adc resgiz[i],0 }
            emitbyt($40+$02*8+dreg(ip^.lreg));
            emitbyt(regsiz);
            emitbyt(0)

         end else begin { dword or smaller increment }

            if ip^.base^.size = 1 then emitbyt($fe) { byte }
            else if ip^.base^.size = 2 then begin { word }

               emitbyt($66);
               emitbyt($ff)

            end else emitbyt($ff); { dword }
            emitbyt($00+$00*8+dreg(ip^.lreg))

         end

      end else begin { downto }

         { output decrement }
         if quad then begin { quadword decrement }

            emitbyt($83); { sub [i],1 }
            emitbyt($00+$05*8+dreg(ip^.lreg));
            emitbyt(1);
            emitbyt($83); { sbc regsiz[i],0 }
            emitbyt($40+$03*8+dreg(ip^.lreg));
            emitbyt(regsiz);
            emitbyt(0)

         end else begin { dword or smaller decrement }

            if ip^.base^.size = 1 then emitbyt($fe) { byte }
            else if ip^.base^.size = 2 then begin { word }

               emitbyt($66);
               emitbyt($ff)

            end else emitbyt($ff); { dword }
            emitbyt($00+$01*8+dreg(ip^.lreg))

         end

      end;
      emitbyt($e9); { jmp loop }
      emitadr(lab1, itradr); { output jump location }
      gendistrp; { generate disassembly trip }
      lab2^.addr := pgmcnt { set exit location }

   end;
   if fpusct <> 0 then error(esysflt219) { FPU stack should be empty }

end;

{*******************************************************************************

Place result in transfer register

Places the result from the given operator into its transfer register. Each
operator node has the register it calculates its result to, and the final
register the result is placed in. Normally these are the same, but they can be
set as different by the register allocator to allow for implict moves.

The move is optimized, and moves from flags to registers are implicitly
processed. Double operands are moved, and the case where the source and
destination pair of a doublet is handled as an exchange.

*******************************************************************************}

procedure restran(ip: intptr);

begin

   { If the result is not in the same register as the final register, we need
     to put it there now. There will be a hole in the push mask there so that
     it will be left for the operator above. Note that operators that don't
     have results will be all rgnull }
   if (ip^.freg <> ip^.rsreg) and (ip^.fregx <> ip^.rsregx) and
      ((ip^.freg = ip^.rsregx) or (ip^.fregx = ip^.rsreg)) then begin

      { We have two registers to move, and they are in conflict. This can
        we fixed by ordering the moves or performing an outright exchange.
        Note that byte registers or flags will never be involved, since double
        register operands are fat pointers or wide integers. }
      if (ip^.freg = ip^.rsregx) and (ip^.fregx = ip^.rsreg) then begin

         { exchange them }
         emitbyt($87); { xchg r,rx }
         emitbyt($c0+dreg(ip^.rsreg)*8+dreg(ip^.rsregx))

      end else if ip^.freg = ip^.rsregx then begin { order them }

         { move extended, then normal }
         emitbyt($8b); { mov frx,rsx }
         emitbyt($c0+dreg(ip^.fregx)*8+dreg(ip^.rsregx));
         emitbyt($8b); { mov fr,rs }
         emitbyt($c0+dreg(ip^.freg)*8+dreg(ip^.rsreg))

      end else begin

         { move normal, then extended }
         emitbyt($8b); { mov fr,rs }
         emitbyt($c0+dreg(ip^.freg)*8+dreg(ip^.rsreg));
         emitbyt($8b); { mov frx,rsx }
         emitbyt($c0+dreg(ip^.fregx)*8+dreg(ip^.rsregx))

      end

   end else begin { no conflict, or not double }

      if ip^.freg <> ip^.rsreg then begin { must move it }

         if ip^.rsreg = rgflg then begin { move flag to register }

            { check result in byte settable register }
            if not (ip^.freg in [rgeax, rgebx, rgecx, rgedx]) then begin

               { is not in byte settable register, must exchange with eax }
               emitbyt($90+dreg(ip^.freg)); { xchg eax,r }
               emitbyt($0f); { setcc rs }
               emitbyt($90+ccode(ip^.rsflg));
               emitbyt($c0+$00*8+dreg(rgeax));
               { extend to 32 bits }
               emitbyt($0f); { movzx r32,r8 }
               emitbyt($b6);
               emitbyt($c0+dreg(rgeax)*8+dreg(rgeax));
               emitbyt($90+dreg(ip^.freg)) { xchg eax,r }

            end else begin

               emitbyt($0f); { setcc rs }
               emitbyt($90+ccode(ip^.rsflg));
               emitbyt($c0+$00*8+dreg(ip^.freg));
               { extend to 32 bits }
               emitbyt($0f); { movzx r32,r8 }
               emitbyt($b6);
               emitbyt($c0+dreg(ip^.freg)*8+dreg(ip^.freg))

            end

         end else if ip^.freg = rgflg then begin { move register to flag }

            { when moving a register into the flags, its allways done with the
              zero flag }
            emitbyt($0b); { or rs,rs }
            emitbyt($c0+dreg(ip^.rsreg)*8+dreg(ip^.rsreg))

         end else begin { register to register }

            emitbyt($8b); { mov fr,rs }
            emitbyt($c0+dreg(ip^.freg)*8+dreg(ip^.rsreg))

         end

      end;
      { Check extended registers not equal, and the source is not null. Source
        null is a kludge to get around the fact that procedure and function
        parameters need a frame pointer which is derived on the call. }
      if (ip^.fregx <> ip^.rsregx) and (ip^.rsregx <> rgnull) then begin

         { move extended register }
         emitbyt($8b); { mov fr,rs }
         emitbyt($c0+dreg(ip^.fregx)*8+dreg(ip^.rsregx))

      end

   end

end;

{*******************************************************************************

Generate operand node

Given an intermediate operator, outputs code for that based on registers and
other context information. Decends the expression tree, and accomplishes a full
left hand walk and code output.

This routine is called during the generator intermediate tour for each
expression. The reason we go ahead and decend the tree, is that many of the
optimizations can look down in the tree and fold a branch into the instruction
to be generated, eliminating the need for that branch.

*******************************************************************************}

procedure gennod(ip: intptr);

var i:          integer; { immediate value }
    tp:         typptr;  { type pointer }
    rg:         regt;    { register }
    lab1, lab2,
    lab3, lab4: typptr;  { jump labels }
    ip1:        intptr;  { intermediate list pointer }
    prel:       boolean; { promote to full real }
    size:       integer; { size of operation }
    sgn:        boolean; { operand is signed }
    casels:     boolean; { case 'else' was encountered }
    ptrind:     boolean; { pointer is being indirected }
    tagp:       typptr;  { tag field pointer }
    casp:       typptr;  { case pointer }
    ti, ti2:    ssint;
    lb, ub:     ssint;
    ip2:        intptr;

begin

   { do any generation list }
   if flstgen then begin

      prthex(8, pgmcnt);
      write(' ', fpusct:1, ' ');
      if genind > 0 then write(' ':genind); { indent }
      write('+');
      prttic(ip^.i, 1); writeln;


   end;
   genind := genind+3; { indent nested lists }
   if frevengcm then begin { enable counter-measures }

      { if disassembly countermeasures are on, we generate a "skip trip" every
        so often, enough to seriously impact disassembly attempts, but not
        enough to make the program run slow. }
      if fdiscm then
         if rand mod 20 = 0 then gendisskp; { generate skip disassembly trip }

   end;
   { perform the push mask }
   if rgflg in ip^.push then emitbyt($9c); { pushfd }
   { do word pushes }
   for rg := rgeax to rgedi do if rg in ip^.push then
      { this register needs to be saved }
      emitbyt($50+dreg(rg)); { push r }
   if not ip^.skip then { entry not marked as skip }
      case ip^.i of { intermediate type }

      { *** Expression leaves ************************************************ }

      tilodadr: begin

         setref(ip^.base); { set that is referenced }
         genladr(ip^.rsreg, ip^.base); { load address }
         { check addressing a procedure or function }
         if (ip^.base^.t = tproc) or (ip^.base^.t = tfunc) then begin

            { if addressing a procedure or function, we need not only the
              address of the routine, but the current frame pointer. }
            emitbyt($8b); { mov rd,ebp }
            emitbyt($c0+dreg(ip^.rsregx)*8+$05)

         end

      end;
      tilodfadr: begin

         { Load address of function result, which is a local to this block. }
         emitbyt($8d); { lea r,off[ebp] }
         emitbyt($80+dreg(ip^.rsreg)*8+$5);
         emitint(ip^.base^.fncr^.addr)

      end;
      tiarrref: genarr(ip); { array reference }
      tiarfgar: gengar(ip); { general array reference }
      tirecoff: begin { record offset }

         gennod(ip^.left); { resolve left }
         { if its a direct loaded pointer, check for nil }
         if chkptl(ip^.left) then genpchk(ip^.lreg);
         if ftagchk then begin

            fndtag(ip^.base, tagp, casp); { find tag and case for entry }
            while tagp <> nil do begin { iterate the tags }

               { check if tag field exists }
               if tagp^.ftge then begin

                  { Make sure it's not a quad. This could never pratically
                    occur, since all constants of a tag must appear in the
                    source. }
                  if tagp^.size > regsiz then error(etagdbl);
                  { Now we have the tag field offset, and the case value to
                    compare it to. Copy the base pointer to temp. }
                  emitbyt($8b); { mov rt,rb }
                  emitbyt($c0+dreg(ip^.t1reg)*8+dreg(ip^.lreg));
                  { get record offset to tag }
                  ti.v := tagp^.addr;
                  ti.s := false;
                  { perform offset }
                  gendoiir(false, $00, $00, ip^.t1reg, rgnull, false, ti, false);
                  { get the tagfield to the same register }
                  genlodindr(ip^.t1reg, ip^.t1regx, ip^.t1reg, tagp^.size,
                             chksgn(tagp^.ftgt));
                  { generate a tag check series }
                  gentagchk(ip^.base, casp, ip^.t1reg)

               end;
               { Now find the tag for this tag, and so on until we run out
                 of tags. }
               fndtag(tagp, tagp, casp) { find tag and case for entry }

            end

         end;

         ti.v := ip^.base^.addr;
         ti.s := false;
         { perform offset }
         gendoiir(false, $00, $00, ip^.lreg, rgnull, false, ti, false)

      end;
      tilodrel, tilimrel: begin

         setref(ip^.base); { set that is referenced }
         genlodrel(ip^.t1reg, ip^.base); { load double real }
         fpusct := fpusct+1; { increase FPU stack depth }
         if fpusct > maxfst then error(efstkovf) { too many stack levels }

      end;
      tilodsrl: begin

         setref(ip^.base); { set that is referenced }
         genlodrel(ip^.t1reg, ip^.base); { load short real }
         fpusct := fpusct+1; { increase FPU stack depth }
         if fpusct > maxfst then error(efstkovf) { too many stack levels }

      end;
      tilodset: begin { load set direct }

         setref(ip^.base); { set that is referenced }
         { The register allocation pass has given us esi, edi, and ecx for
           the move. }
         genladr(rgesi, ip^.base); { get address in esi }
         genladr(rgedi, ip^.base2); { load address of temp to edi }
         emitbyt($c7); { mov ecx,setsiz div 4 }
         emitbyt($c1);
         emitint(setsiz div 4);
         { Save the set address, its cheaper than a reload }
         emitbyt($57); { push edi }
         { perform the move }
         emitbyt($f3); { rep }
         emitbyt($a5); { movsd }
         { restore set address to result register }
         emitbyt($58+dreg(ip^.rsreg)) { pop r }

      end;
      tilodsrc: begin { load structure direct }

         setref(ip^.base); { set that is referenced }
         { The register allocation pass has given us esi, edi, and ecx for
           the move. }
         genladr(rgesi, ip^.base); { get address in esi }
         genladr(rgedi, ip^.base2); { load address of temp to edi }
         emitbyt($c7); { mov ecx,size }
         emitbyt($c1);
         emitint(ip^.base2^.size);
         { Save the structure address, its cheaper than a reload }
         emitbyt($57); { push edi }
         { perform the move }
         emitbyt($f3); { rep }
         emitbyt($a4); { movsb }
         { restore set address to result register }
         emitbyt($58+dreg(ip^.rsreg)) { pop r }

      end;
      tilodint, tilodchr, tilodbol, tilodptr: begin

         setref(ip^.base); { set that is referenced }
         { set size and sign of operation }
         case ip^.i of { size }

            tilodint: begin size := ip^.base^.size; sgn := chksgn(ip^.base) end;
            tilodchr: begin size := chrsiz; sgn := false end;
            tilodbol: begin size := bolsiz; sgn := false end;
            tilodptr: begin size := ptrsiz; sgn := false end

         end;
         { check flag/value target }
         if ip^.rsreg = rgflg then begin

            if size = dwdsiz then { integer }
               { Generate scaled array reference. }
               gendir1r(ip^.base, ip^.t1reg, $07, $83, 0)
            else if size = wrdsiz then { word }
               gendir2r(ip^.base, ip^.t1reg, $07, $66, $83, 0)
            else if size = bytsiz then { byte }
               gendir1r(ip^.base, ip^.t1reg, $07, $80, 0)
            else error(einvfmt); { invalid format }
            emitbyt($00)

         end else begin { value }

            if size > regsiz then begin { its a double }

               genlodsor(ip^.rsreg, ip^.base, regsiz, 0); { gen load low }
               genlodsor(ip^.rsregx, ip^.base, regsiz, regsiz) { gen load high }

            end else { standard load }
               genlodsor(ip^.rsreg, ip^.base, ip^.base^.size, 0) { gen load }

         end

      end;
      tilodtgp: begin

         setref(ip^.base); { set that is referenced }
         { generate load tagged pointer direct }
         genlodtpr(ip^.rsreg, ip^.rsregx, ip^.base)

      end;
      tildiint, tildichr, tildibol, tildiptr: begin

         { set size and sign of operation }
         case ip^.i of { size }

            tildiint: begin size := ip^.base^.size; sgn := chksgn(ip^.base) end;
            tildichr: begin size := chrsiz; sgn := false end;
            tildibol: begin size := bolsiz; sgn := false end;
            tildiptr: begin size := ptrsiz; sgn := false end

         end;
         { check if a pointer is being indirected}
         ptrind := chkptl(ip^.left);
         { check flag/value target }
         if ip^.rsreg = rgflg then begin

            { The target is a flag. We can use cmp instructions for the operand
              to flag convertion. }
            if ip^.left^.rbase^.size > regsiz then
               { This routine is fairly generous about handling byte, word and
                 dword flags, but in reality there will never be other than a
                 byte flag for boolean. Supporting qword is a bit over the top,
                 so we just reject it here. }
               error(einvfmt);
            if (ip^.left^.i = tiarrref) and not ptrind then
               begin { its an array reference, and not checking pointer deref }

               { There are some limited array cases that can fit into the SIB
                 format. If array checks are off, and the base type size is 1,
                 2, 4 or 8, then we can do it. The base value is done by adding
                 it into the displacement. Globals or locals can be processed }
               if ip^.left^.base^.t <> tarray then error(einvfmt);
               i := ip^.left^.base^.arrt^.size; { get base type size }
               if i in [1, 2, 4, 8] then begin { proper base size }

                  if size = dwdsiz then { integer }
                     { Generate scaled array reference. }
                     gensar(ip^.left, ip^.rsreg, $07, 0, false, false,
                            $00, false, $83, $00, false, $00, i, 0, ti)
                  else if size = wrdsiz then { word }
                     gensar(ip^.left, ip^.rsreg, $07, 0, false, false, $66,
                            true, $83, $00, false, $00, i, 0, ti)
                  else if size = bytsiz then { byte }
                     gensar(ip^.left, ip^.rsreg, $07, 0, false, false, $00,
                            false, $80, $00, false, $00, i, 0, ti)
                  else error(einvfmt); { invalid format }
                  emitbyt($00)

               end else begin { process as normal }

                  gennod(ip^.left); { resolve address }
                  { perform indirect compare }
                  if size = 2 then emitbyt($66); { emit prefix for word }
                  emitbyt($80+3*ord(size <> 1)); { cmpb [rl],0 }
                  emitbyt($00+$07*8+dreg(ip^.lreg));
                  emitbyt($00)

               end

            end else begin { process as normal }

               gennod(ip^.left); { resolve address }
               genpchk(ip^.lreg); { perform zero pointer check }
               { perform indirect compare }
               if size = 2 then emitbyt($66); { emit prefix for word }
               emitbyt($80+3*ord(size <> 1)); { cmpb [rl],0 }
               emitbyt($00+$07*8+dreg(ip^.lreg));
               emitbyt($00)

            end

         end else begin { value form }

            if (ip^.left^.i = tiarrref) and not ptrind then
               begin { its an array reference, and not checking pointer deref }

               { There are some limited array cases that can fit into the SIB
                 format. If array checks are off, and the base type size is 1,
                 2, 4 or 8, then we can do it. The base value is done by adding
                 it into the displacement. Globals or locals can be processed }
               if ip^.left^.base^.t <> tarray then error(einvfmt);
               i := ip^.left^.base^.arrt^.size; { get base type size }
               if i in [1, 2, 4, 8] then begin { proper base size }

                  if size = dwdsiz then { integer }
                     { Generate scaled array reference. }
                     gensar(ip^.left, ip^.t1reg, dreg(ip^.rsreg), 0,
                            false, false, $00, false, $8b, $00, false, $00, i,
                            0, ti)
                  else if size = qwdsiz then { quad word }
                     { Generate double scaled array reference. }
                     gensar(ip^.left, ip^.t1reg, dreg(ip^.rsreg),
                            dreg(ip^.rsregx), true, true, $00, false, $8b,
                            $00, false, $8b, i, 0, ti)
                  else if size = wrdsiz then begin { word }

                     if sgn then { signed }
                        gensar(ip^.left, ip^.t1reg, dreg(ip^.rsreg), 0,
                               false, false, $0f, true, $bf, $00, false, $00, i,
                               0, ti)
                     else { unsigned }
                        gensar(ip^.left, ip^.t1reg, dreg(ip^.rsreg), 0,
                               false, false, $0f, true, $b7, $00, false, $00, i,
                               0, ti)

                  end else if size = bytsiz then begin { byte }

                     if sgn then { signed }
                        gensar(ip^.left, ip^.t1reg, dreg(ip^.rsreg), 0,
                               false, false, $0f, true, $be, $00, false, $00, i,
                               0, ti)
                     else { unsigned }
                        gensar(ip^.left, ip^.t1reg, dreg(ip^.rsreg), 0,
                               false, false, $0f, true, $b6, $00, false, $00, i,
                               0, ti)

                  end else error(einvfmt); { invalid format }

               end else begin { process as normal }

                  gennod(ip^.left); { resolve address }
                  { perform indirect fetch }
                  genlodindr(ip^.rsreg, ip^.rsreg, ip^.lreg, size, sgn)

               end

            end else begin { process as normal }

               gennod(ip^.left); { resolve address }
               if ptrind then begin { perform zero pointer check }

                  emitbyt($0b); { or r,r }
                  emitbyt($c0+dreg(ip^.lreg)*8+dreg(ip^.lreg));
                  genske($75, renpdref) { generate nil deref fault }

               end;
               { perform indirect fetch }
               genlodindr(ip^.rsreg, ip^.rsregx, ip^.lreg, size, sgn)

            end

         end

      end;
      tildisrl: begin

         gennod(ip^.left); { resolve operand }
         { We might be loading a parameter real. If its a parameter in a
           register, we need to force it to full real, instead of short,
           because it was automatically converted on load. }
         prel := false; { set no promotion }
         if ip^.left^.i = tilodadr then { its a load address entry }
            if (ip^.left^.base^.t = tpar) or (ip^.left^.base^.t = twpar) then
            { its a parameter }
            prel := relreg(ip^.left^.base); { set promote if registerable }
         if prel then emitbyt($dd) { fldd [r] }
         else emitbyt($d9); { flds [r] }
         emitbyt($00+$00*8+dreg(ip^.lreg));
         fpusct := fpusct+1; { increase FPU stack depth }
         if fpusct > maxfst then error(efstkovf) { too many stack levels }

      end;
      tildirel: begin

         gennod(ip^.left); { resolve operand }
         emitbyt($dd); { fldd [r] }
         emitbyt($00+$00*8+dreg(ip^.lreg));
         genfpuchk; { perform fpu check }
         fpusct := fpusct+1; { increase FPU stack depth }
         if fpusct > maxfst then error(efstkovf) { too many stack levels }

      end;
      tildiset: begin { load set indirect }

         { The register allocation pass has given us esi, edi, and ecx for
           the move. The temp is in the base. }
         gennod(ip^.left); { resolve operand to esi }
         genladr(rgedi, ip^.base2); { load address of temp to edi }
         emitbyt($c7); { mov ecx,size/4 }
         emitbyt($c1);
         emitint(setsiz div 4);
         { Save the set address, its cheaper than a reload }
         emitbyt($57); { push edi }
         { perform the move }
         emitbyt($f3); { rep }
         emitbyt($a5); { movsd }
         { restore set address to result register }
         emitbyt($58+dreg(ip^.rsreg)) { pop r }

      end;
      tildisrc: begin { load structure indirect }

         { The register allocation pass has given us esi, edi, and ecx for
           the move. The temp is in the base. }
         gennod(ip^.left); { resolve operand to esi }
         genladr(rgedi, ip^.base2); { load address of temp to edi }
         emitbyt($c7); { mov ecx,size }
         emitbyt($c1);
         emitint(ip^.base^.size);
         { Save the set address, its cheaper than a reload }
         emitbyt($57); { push edi }
         { perform the move }
         emitbyt($f3); { rep }
         emitbyt($a4); { movsd }
         { restore set address to result register }
         emitbyt($58+dreg(ip^.rsreg)) { pop r }

      end;
      tilditgp: begin { load tagged pointer indirect }

         { Load pointer section. Two double registers are reserved for this. }
         gennod(ip^.left); { generate subtree }
         emitbyt($8b); { mov rr,regsiz[rl] }
         emitbyt($40+dreg(ip^.rsregx)*8+dreg(ip^.lreg));
         emitbyt(regsiz);
         emitbyt($8b); { mov rr,[rl] }
         emitbyt($00+dreg(ip^.rsreg)*8+dreg(ip^.lreg))

      end;
      tilimint: begin { load immediate integer }

         { Right now, there is no way to represent a qword constant, but this
           will need to be supported when there is. }
         emitbyt($c7); { mov r,imm32 }
         emitbyt($c0+$00*8+dreg(ip^.rsreg));
         ti.v := consti(ip^.base);
         ti.s := constis(ip^.base);
         emitint(ti)

      end;
      tilimns: begin { load null set }

         { The register allocation pass has given us edi, eax, and ecx for
           the clear  }
         genladr(rgedi, ip^.base2); { load address of temp to edi }
         { note that stacked sets are allways even }
         emitbyt($c7); { mov ecx,size/4 }
         emitbyt($c1);
         emitint(setsiz div 4);
         { move into place, but retain the base address }
         emitbyt($33); { xor eax,eax }
         emitbyt($c0+dreg(rgeax)*8+dreg(rgeax));
         emitbyt($57); { push edi }
         emitbyt($f3); { rep }
         emitbyt($ab); { stosd }
         { restore set address to result register }
         emitbyt($58+dreg(ip^.rsreg)) { pop r }

      end;
      { Length of general array is simply the tagged pointer with the address
        part discarded. This is done in regblk. }
      tilodlen: gennod(ip^.left); { generate subtree }
      tinotint: begin { negate }

         gennod(ip^.left); { generate subtree }
         emitbyt($f7); { not r }
         emitbyt($c0+$02*8+dreg(ip^.rsreg));
         if ip^.left^.rbase^.size > regsiz then begin { qword }

            emitbyt($f7); { not r }
            emitbyt($c0+$02*8+dreg(ip^.rsregx));

         end

      end;
      tinotbol: begin { complement boolean }

         gennod(ip^.left); { generate subtree }
         { if the not is being done in flags, we do nothing, since it is
           simply a flag state invertion }
         if ip^.rsreg <> rgflg then begin

            emitbyt($0f); { btc r,0 }
            emitbyt($ba);
            emitbyt($c0+$07*8+dreg(ip^.rsreg));
            emitbyt($00)

         end

      end;
{ ?????? review limit }
      tisinset: begin { set single set element }

         gennod(ip^.left); { generate subtrees }
         gennod(ip^.right);
         lb.v := 0; { set bounds }
         lb.s := false;
         ub.v := 255;
         ub.s := false;
         { generate bounds check }
         genbndr(false, ip^.rreg, ip^.rregx, false, lb, ub);
         emitbyt($0f); { bts rl,rr }
         emitbyt($ab);
         emitbyt($00+dreg(ip^.rreg)*8+dreg(ip^.lreg))

      end;
      tirngset: begin { set range of set elements }

         gennod(ip^.left); { generate subtrees }
         gennod(ip^.right);
         gennod(ip^.xtra);
         { generate bounds check on elements }
         lb.v := 0; { set bounds }
         lb.s := false;
         ub.v := 255;
         ub.s := false;
         { generate bounds check }
         genbndr(false, ip^.rreg, ip^.rregx, false, lb, ub);
         { generate bounds check }
         genbndr(false, ip^.xreg, ip^.xregx, false, lb, ub);
         emitbyt($3b); { cmp rr,rx }
         emitbyt($c0+dreg(ip^.rreg)*8+dreg(ip^.xreg));
         emitbyt($77); { ja over }
         emitbyt(10);
         emitbyt($50+dreg(ip^.lreg)); { push rl }
         emitbyt($0f); { bts rl,rr }
         emitbyt($ab);
         emitbyt($00+dreg(ip^.rreg)*8+dreg(ip^.lreg));
         emitbyt($40+dreg(ip^.rreg)); { inc rr }
         emitbyt($3b); { cmp rr,rx }
         emitbyt($c0+dreg(ip^.rreg)*8+dreg(ip^.xreg));
         emitbyt($76); { jna loop }
         emitbyt(-8);
         emitbyt($58+dreg(ip^.lreg)) { pop rl }

      end;
      ticvtitr: begin { convert integer to real }

         gennod(ip^.left); { generate integer }
         { If not signed, generate sign check. }
         if not chksgn(ip^.left^.rbase) then gensgnchk(ip^.left^.freg);
         { we must address the integer to load it, so it is placed on stack and
           loaded from there. }
         emitbyt($50+dreg(ip^.lreg)); { push r }
         { get address of int on stack }
         emitbyt($8b); { mov r,esp }
         emitbyt($c0+dreg(ip^.lreg)*8+$04);
         { load and convert to real }
         emitbyt($db); { fildd [r] }
         emitbyt($00+$00*8+dreg(ip^.lreg));
         { now get rid of it }
         emitbyt($58+dreg(ip^.lreg)); { pop rl }
         fpusct := fpusct+1; { increase FPU stack depth }
         if fpusct > maxfst then error(efstkovf) { too many stack levels }

      end;
      ticvtgtf: begin { convert tagged pointer to fixed }

         gennod(ip^.left); { generate subtree }
         ti.v := ip^.base^.size;
         ti.s := false;
         gencmpi(ip^.lregx, ti); { generate compare }
         genske($74, relenmat) { generate skip error }

      end;
      ticvtftg: begin { convert fixed pointer to tagged }

         { all we need do is load the length into the choosen register }
         gennod(ip^.left); { generate subtree }
         emitbyt($b8+dreg(ip^.rsregx)); { mov len,size }
         { The two fixed array types that can be converted are arrays and
           strings. General arrays are tagged by the number of elements in the
           array, so the calculation must be done for non-string. }
         if ip^.base^.t = tarray then
            emitint(ip^.base^.size div ip^.base^.arrt^.size) { general array }
         else
            emitint(ip^.base^.size) { generate string size }

      end;
      ticvtntg: begin

         gennod(ip^.left); { generate subtree }
         { clear length register }
         emitbyt($33); { xor r,r }
         emitbyt($c0+dreg(ip^.rsregx)*8+dreg(ip^.rsregx))

      end;
      { Since all reals are converted to 64 bit for the stack, this operator
        is basically a no-op. }
      ticvtrtsr: gennod(ip^.left); { generate subtree }
      tiintset: begin

         { The register pass gives us a count register. }
         gennod(ip^.left); { generate left }
         gennod(ip^.right); { generate right }
         { save result address on stack }
         emitbyt($50+dreg(ip^.lreg)); { push rl }
         { set size of set in dwords }
         emitbyt($b8+dreg(ip^.t1reg)); { mov rt1,setsiz div 4 }
         emitint(setsiz div 4);
         gettypa(lab1, tlab); { get a loop label }
         lab1^.addr := pgmcnt; { set loop start }
         { 'and' two dwords of the set together }
         emitbyt($8b); { mov rt2,[rr] }
         emitbyt($00+dreg(ip^.t2reg)*8+dreg(ip^.rreg));
         emitbyt($21); { andd [rl],rt2 }
         emitbyt($00+dreg(ip^.t2reg)*8+dreg(ip^.lreg));
         emitbyt($83); { add rl,4 }
         emitbyt($c0+$00*8+dreg(ip^.lreg));
         emitbyt($04);
         emitbyt($83); { add rr,4 }
         emitbyt($c0+$00*8+dreg(ip^.rreg));
         emitbyt($04);
         emitbyt($48+dreg(ip^.t1reg)); { dec cnt }
         emitbyt($0f); { jnz loop }
         emitbyt($85);
         emitadr(lab1, itradr); { place loop jump address }
         { restore result }
         emitbyt($58+dreg(ip^.lreg)) { pop rl }

      end;
      timltrel: begin { multiply real }

         gennod(ip^.left); { generate left to sos }
         gennod(ip^.right); { generate right to tos }
         { multiply and pop top }
         emitbyt($de); { fmulp }
         emitbyt($c9);
         genfpuchk; { perform fpu check }
         fpusct := fpusct-1; { decrease FPU stack level }
         if fpusct < 0 then error(esysflt138) { underflow }

      end;
      timltint: gendoi(ip); { multiply integer }
      timltintimm: gendoiimm(ip); { multiply integer immediate }
      timltintlod: gendoilod(ip); { multiply integer direct }
      timltintldi: gendoildi(ip); { multiply integer indirect direct }
      tidivrel: begin { divide real }

         gennod(ip^.left); { generate left to sos }
         gennod(ip^.right); { generate right to tos }
         { divide and pop top }
         emitbyt($de); { fdivp }
         emitbyt($f9);
         genfpuchk; { perform fpu check }
         fpusct := fpusct-1; { decrease FPU stack level }
         if fpusct < 0 then error(esysflt139) { underflow }

      end;
      tidivint: gendiv(ip); { divide integer }
      timodint: genmod(ip); { modulo integer }
      tiandint: gendoi(ip); { generate "and" instruction }
      tiandintimm: gendoiimm(ip); { generate "and" immediate instruction }
      tiandintlod: gendoilod(ip); { generate "and" direct instruction }
      tiandintldi: gendoildi(ip); { generate "and" indirect instruction }
      tinegint: begin { negate integer }

         gennod(ip^.left); { resolve operand }
         emitbyt($f7); { neg r }
         emitbyt($c0+$03*8+dreg(ip^.lreg));
         genovf { generate overflow check }

      end;
      tinegrel: begin { negate real }

         gennod(ip^.left); { generate operand to tos }
         { change sign of tos }
         emitbyt($d9); { fchs }
         emitbyt($e0);
         genfpuchk; { perform fpu check }

      end;
      tiuniset: begin

         { The register pass gives us a count register. }
         gennod(ip^.left); { generate left }
         gennod(ip^.right); { generate right }
         { save result address on stack }
         emitbyt($50+dreg(ip^.lreg)); { push rl }
         { set size of set in dwords }
         emitbyt($b8+dreg(ip^.t1reg)); { mov rt1,setsiz div 4 }
         emitint(setsiz div 4);
         gettypa(lab1, tlab); { get a loop label }
         lab1^.addr := pgmcnt; { set loop start }
         { 'and' two dwords of the set together }
         emitbyt($8b); { mov rt2,[rr] }
         emitbyt($00+dreg(ip^.t2reg)*8+dreg(ip^.rreg));
         emitbyt($09); { ordd [rl],rt2 }
         emitbyt($00+dreg(ip^.t2reg)*8+dreg(ip^.lreg));
         emitbyt($83); { add rl,4 }
         emitbyt($c0+$00*8+dreg(ip^.lreg));
         emitbyt($04);
         emitbyt($83); { add rr,4 }
         emitbyt($c0+$00*8+dreg(ip^.rreg));
         emitbyt($04);
         emitbyt($48+dreg(ip^.t1reg)); { dec ecx }
         emitbyt($0f); { jnz loop }
         emitbyt($85);
         emitadr(lab1, itradr); { place loop jump address }
         { restore result }
         emitbyt($58+dreg(ip^.lreg)) { pop rl }

      end;
      tiaddrel: begin { add real }

         gennod(ip^.left); { generate left to sos }
         gennod(ip^.right); { generate right to tos }
         { add and pop top }
         emitbyt($de); { faddp }
         emitbyt($c1);
         genfpuchk; { perform fpu check }
         fpusct := fpusct-1; { decrease FPU stack level }
         if fpusct < 0 then error(esysflt140) { underflow }

      end;
      tiaddint: gendoi(ip); { generate add instruction }
      tiaddintimm: gendoiimm(ip); { generate add immediate instruction }
      tiaddintlod: gendoilod(ip); { generate add direct instruction }
      tiaddintldi: gendoildi(ip); { generate add indirect instruction }
      tidifset: begin

         { The register pass gives us a count register. }
         gennod(ip^.left); { generate left }
         gennod(ip^.right); { generate right }
         { save result address on stack }
         emitbyt($50+dreg(ip^.lreg)); { push rl }
         { set size of set in dwords }
         emitbyt($b8+dreg(ip^.t1reg)); { mov rt1,setsiz div 4 }
         emitint(setsiz div 4);
         gettypa(lab1, tlab); { get a loop label }
         lab1^.addr := pgmcnt; { set loop start }
         { 'and' two dwords of the set together }
         emitbyt($8b); { mov rt2,[rr] }
         emitbyt($00+dreg(ip^.t2reg)*8+dreg(ip^.rreg));
         emitbyt($33); { xord rt2,[rl] }
         emitbyt($00+dreg(ip^.t2reg)*8+dreg(ip^.lreg));
         emitbyt($21); { andd rt2,[rl] }
         emitbyt($00+dreg(ip^.t2reg)*8+dreg(ip^.lreg));
         emitbyt($83); { add rl,4 }
         emitbyt($c0+$00*8+dreg(ip^.lreg));
         emitbyt($04);
         emitbyt($83); { add rr,4 }
         emitbyt($c0+$00*8+dreg(ip^.rreg));
         emitbyt($04);
         emitbyt($48+dreg(ip^.t1reg)); { dec ecx }
         emitbyt($0f); { jnz loop }
         emitbyt($85);
         emitadr(lab1, itradr); { place loop jump address }
         { restore result }
         emitbyt($58+dreg(ip^.lreg)) { pop rl }

      end;
      tisubrel: begin { subtract real }

         gennod(ip^.left); { generate left to sos }
         gennod(ip^.right); { generate right to tos }
         { subtract and pop top }
         emitbyt($de); { fsubrp }
         emitbyt($e9);
         genfpuchk; { perform fpu check }
         fpusct := fpusct-1; { decrease FPU stack level }
         if fpusct < 0 then error(esysflt141) { underflow }

      end;
      tisubint: gendoi(ip); { generate subtract instruction }
      tisubintimm: gendoiimm(ip); { generate subtract immediate instruction }
      tisubintlod: gendoilod(ip); { generate subtract direct instruction }
      tisubintldi: gendoildi(ip); { generate subtract indirect instruction }
      tiorint:  gendoi(ip); { generate "or" instruction }
      tiorintimm: gendoiimm(ip); { generate "or" immediate instruction }
      tiorintlod: gendoilod(ip); { generate "or" direct instruction }
      tiorintldi: gendoildi(ip); { generate "or" indirect instruction }
      tixorint: gendoi(ip); { generate "xor" instruction }
      tixorintimm: gendoiimm(ip); { generate "xor" immediate instruction }
      tixorintlod: gendoilod(ip); { generate "xor" direct instruction }
      tixorintldi: gendoildi(ip); { generate "xor" indirect instruction }
      tiincset: begin { test set inclusion }

         gennod(ip^.left); { generate subtrees }
         gennod(ip^.right);

         ti.v := 256;
         ti.s := false;
         gencmpi(ip^.lreg, ti); { generate high bound check }
         { If carry is set, then the ordinal is in set bounds. If carry is not
           set, then its out of bounds. In this case, we jump over the test,
           since that would be "not in set" which is equivalent to carry off. }
         emitbyt($73); { jmp over }
         emitbyt(3); { relative jump over bit test }
         emitbyt($0f); { bt rl,rr }
         emitbyt($a3);
         emitbyt($00+dreg(ip^.lreg)*8+dreg(ip^.rreg))

      end;
      tiequset: begin

         { The register allocation pass has given us esi, edi, and ecx for
           the move. The temp is in the base. }
         gennod(ip^.left); { generate left to esi }
         gennod(ip^.right); { generate right to edi }
         emitbyt($c7); { mov ecx,size/4 }
         emitbyt($c1);
         emitint(setsiz div 4);
         { perform the compare }
         emitbyt($f3); { rep }
         emitbyt($a7) { cmpsd }

      end;
      tiequrel: begin { perform real compare }

         gencmprel(ip); { perform the compare to flags }
         fpusct := fpusct-2; { decrease FPU stack level }
         if fpusct < 0 then error(esysflt142) { underflow }

      end;
      tineqrel: begin { perform real compare }

         gencmprel(ip); { perform the compare to flags }
         fpusct := fpusct-2; { decrease FPU stack level }
         if fpusct < 0 then error(esysflt143) { underflow }

      end;
      tileqrel: begin { perform real compare }

         gencmprel(ip); { perform the compare to flags }
         fpusct := fpusct-2; { decrease FPU stack level }
         if fpusct < 0 then error(esysflt144) { underflow }

      end;
      tigeqrel: begin { perform real compare }

         gencmprel(ip); { perform the compare to flags }
         fpusct := fpusct-2; { decrease FPU stack level }
         if fpusct < 0 then error(esysflt145) { underflow }

      end;
      tiltnrel: begin { perform real compare }

         gencmprel(ip); { perform the compare to flags }
         fpusct := fpusct-2; { decrease FPU stack level }
         if fpusct < 0 then error(esysflt146) { underflow }

      end;
      tigtnrel: begin { perform real compare }

         gencmprel(ip); { perform the compare to flags }
         fpusct := fpusct-2; { decrease FPU stack level }
         if fpusct < 0 then error(esysflt147) { underflow }

      end;
      tiequstr: gencmps(ip); { generate string compare }
      tiequgst: gencmpg(ip); { generate general string compare }
      tiequint: gendoi(ip); { generate compare instruction }
      tiequintimm: gendoiimm(ip); { generate compare immediate instruction }
      tiequintlod: gendoilod(ip); { generate compare direct instruction }
      tiequintldi: gendoildi(ip); { generate compare indirect instruction }
      tiequtgp: gendoi(ip); { generate compare instruction }
      tiequtgpimm: gendoiimm(ip); { generate compare immediate instruction }
      tiequtgplod: gendoilod(ip); { generate compare direct instruction }
      tiequtgpldi: gendoildi(ip); { generate compare indirect instruction }
      tineqset: begin

         { The register allocation pass has given us esi, edi, and ecx for
           the move. The temp is in the base. }
         gennod(ip^.left); { generate left to esi }
         gennod(ip^.right); { generate right to edi }
         emitbyt($c7); { mov ecx,size/4 }
         emitbyt($c1);
         emitint(setsiz div 4);
         { perform the compare }
         emitbyt($f3); { rep }
         emitbyt($a7) { cmpsd }

      end;
      tineqstr: gencmps(ip); { generate string compare }
      tineqgst: gencmpg(ip); { generate general string compare }
      tineqint: gendoi(ip); { generate compare instruction }
      tineqintimm: gendoiimm(ip); { generate compare immediate instruction }
      tineqintlod: gendoilod(ip); { generate compare direct instruction }
      tineqintldi: gendoildi(ip); { generate compare indirect instruction }
      tineqtgp: gendoi(ip); { generate compare instruction }
      tineqtgpimm: gendoiimm(ip); { generate compare immediate instruction }
      tineqtgplod: gendoilod(ip); { generate compare direct instruction }
      tineqtgpldi: gendoildi(ip); { generate compare indirect instruction }
      tileqset: begin

         { The register pass gives us a count register. }
         gennod(ip^.left); { generate left }
         gennod(ip^.right); { generate right }
         { set size of set in dwords }
         emitbyt($b8+dreg(ip^.t1reg)); { mov rt1,setsiz div 4 }
         emitint(setsiz div 4);
         { clear accumulator }
         emitbyt($33); { xor rt3,rt3 }
         emitbyt($c0+dreg(ip^.t3reg)*8+dreg(ip^.t3reg));
         gettypa(lab1, tlab); { get a loop label }
         lab1^.addr := pgmcnt; { set loop start }
         { 'xor' two dwords of the set together }
         emitbyt($8b); { mov rt2,[rr] }
         emitbyt($00+dreg(ip^.t2reg)*8+dreg(ip^.rreg));
         emitbyt($23); { andd rt2,[rl] }
         emitbyt($00+dreg(ip^.t2reg)*8+dreg(ip^.lreg));
         emitbyt($33); { xord rt2,[rl] }
         emitbyt($00+dreg(ip^.t2reg)*8+dreg(ip^.lreg));
         emitbyt($0b); { or rt3,rt2 }
         emitbyt($c0+dreg(ip^.t3reg)*8+dreg(ip^.t2reg));
         emitbyt($83); { add rl,4 }
         emitbyt($c0+$00*8+dreg(ip^.lreg));
         emitbyt($04);
         emitbyt($83); { add rr,4 }
         emitbyt($c0+$00*8+dreg(ip^.rreg));
         emitbyt($04);
         emitbyt($48+dreg(ip^.t1reg)); { dec ecx }
         emitbyt($0f); { jnz loop }
         emitbyt($85);
         emitadr(lab1, itradr); { place loop jump address }
         { set flags from our accumulator }
         emitbyt($0b); { or rt3,rt3 }
         emitbyt($c0+dreg(ip^.t3reg)*8+dreg(ip^.t3reg))

      end;
      tileqstr: gencmps(ip); { generate string compare }
      tileqgst: gencmpg(ip); { generate general string compare }
      tileqint: gendoi(ip); { generate compare instruction }
      tileqintimm: gendoiimm(ip); { generate compare immediate instruction }
      tileqintlod: gendoilod(ip); { generate compare direct instruction }
      tileqintldi: gendoildi(ip); { generate compare indirect instruction }
      tigeqset: begin

         { The register pass gives us a count register. }
         gennod(ip^.left); { generate left }
         gennod(ip^.right); { generate right }
         { set size of set in dwords }
         emitbyt($b8+dreg(ip^.t1reg)); { mov rt1,setsiz div 4 }
         emitint(setsiz div 4);
         { clear accumulator }
         emitbyt($33); { xor rt3,rt3 }
         emitbyt($c0+dreg(ip^.t3reg)*8+dreg(ip^.t3reg));
         gettypa(lab1, tlab); { get a loop label }
         lab1^.addr := pgmcnt; { set loop start }
         { 'xor' two dwords of the set together }
         emitbyt($8b); { mov rt2,[rr] }
         emitbyt($00+dreg(ip^.t2reg)*8+dreg(ip^.rreg));
         emitbyt($23); { andd rt2,[rl] }
         emitbyt($00+dreg(ip^.t2reg)*8+dreg(ip^.lreg));
         emitbyt($33); { xord rt2,[rr] }
         emitbyt($00+dreg(ip^.t2reg)*8+dreg(ip^.rreg));
         emitbyt($0b); { or rt3,rt2 }
         emitbyt($c0+dreg(ip^.t3reg)*8+dreg(ip^.t2reg));
         emitbyt($83); { add rl,4 }
         emitbyt($c0+$00*8+dreg(ip^.lreg));
         emitbyt($04);
         emitbyt($83); { add rr,4 }
         emitbyt($c0+$00*8+dreg(ip^.rreg));
         emitbyt($04);
         emitbyt($48+dreg(ip^.t1reg)); { dec ecx }
         emitbyt($0f); { jnz loop }
         emitbyt($85);
         emitadr(lab1, itradr); { place loop jump address }
         { set flags from our accumulator }
         emitbyt($0b); { or rt3,rt3 }
         emitbyt($c0+dreg(ip^.t3reg)*8+dreg(ip^.t3reg))

      end;
      tigeqstr: gencmps(ip); { generate string compare }
      tigeqgst: gencmpg(ip); { generate general string compare }
      tigeqint: gendoi(ip); { generate compare instruction }
      tigeqintimm: gendoiimm(ip); { generate compare immediate instruction }
      tigeqintlod: gendoilod(ip); { generate compare direct instruction }
      tigeqintldi: gendoildi(ip); { generate compare indirect instruction }
      tiltnstr: gencmps(ip); { generate string compare }
      tiltngst: gencmpg(ip); { generate general string compare }
      tiltnint: gendoi(ip); { generate compare instruction }
      tiltnintimm: gendoiimm(ip); { generate compare immediate instruction }
      tiltnintlod: gendoilod(ip); { generate compare direct instruction }
      tiltnintldi: gendoildi(ip); { generate compare indirect instruction }
      tigtnstr: gencmps(ip); { generate string compare }
      tigtngst: gencmpg(ip); { generate general string compare }
      tigtnint: gendoi(ip); { generate compare instruction }
      tigtnintimm: gendoiimm(ip); { generate compare immediate instruction }
      tigtnintlod: gendoilod(ip); { generate compare direct instruction }
      tigtnintldi: gendoildi(ip); { generate compare indirect instruction }
      tifnccal, tifnccalo: genprc(ip); { generate function call }
      tifnccali: genprc(ip); { generate function call indirect }
      tiabsrel: begin { absolute valve value of real }

         gennod(ip^.left); { generate operand }
         emitbyt($d9); { fabs }
         emitbyt($e1);
         genfpuchk { perform fpu check }

      end;
      tiabsint: begin { absolute value }

         gennod(ip^.left); { generate operand }
         if chksgn(ip^.left^.rbase) then begin { signed }

            { check sign of operand }
            emitbyt($0b); { or r,r }
            emitbyt($c0+dreg(ip^.rsreg)*8+dreg(ip^.rsreg));
            { skip if not signed }
            emitbyt($79); { jns over }
            emitbyt(2);
            { negate }
            emitbyt($f7); { neg r }
            emitbyt($c0+$03*8+dreg(ip^.rsreg))

         end
         { If the operand is unsigned, its just a no-op, since unsigned will
           never change. }

      end;
      tisqrrel: begin { square of real }

         gennod(ip^.left); { generate operand }
         emitbyt($d8); { fmuld st,st }
         emitbyt($c8);
         genfpuchk { perform fpu check }

      end;
      tisqrint: begin { square integer }

         { This operation is pinned to the eax register, but there is no true
           need for this in the signed case. For the unsigned case there is. }
         gennod(ip^.left); { generate operand }
         { integer square is unique in that we can carry it out in any integer
           mode. It is essentially the same type as both sides of a multiply. }
         if chksgn(ip^.rbase) then begin { signed }

            { we just multiply the register by itself }
            emitbyt($f7); { imul eax,r }
            emitbyt($c0+$05*8+dreg(ip^.lreg));
            genovf { generate overflow check }

         end else begin

            { we just multiply the register by itself }
            emitbyt($f7); { imul eax,r }
            emitbyt($c0+$04*8+dreg(ip^.lreg));
            gencar { generate overflow check }

         end

      end;
      tiatnrel: begin { arctan of real }

         gennod(ip^.left); { generate operand }
         { load 1.0 }
         emitbyt($d9); { fld1 }
         emitbyt($e8);
         { find arctan }
         emitbyt($d9); { fpatan }
         emitbyt($f3);
         genfpuchk { perform fpu check }

      end;
      ticosrel: begin { cosine of real }

         gennod(ip^.left); { generate operand }
         { find cosine }
         emitbyt($d9); { fcos }
         emitbyt($ff);
         genfpuchk { perform fpu check }

      end;
      tiexprel: begin { exponent of real }

         { This algorithim does not yet work. }
         gennod(ip^.left); { generate operand }
         { First we must load a control word for round to zero. We coin this
           word into the constant area for efficientcy, and load it from
           there. }
         emitbyt($d9); { fldcw }
         emitbyt($00+$05*8+$05);
         emitadr(rndzero, itadr); { round to zero }
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
         genfpuchk { perform fpu check }

      end;
      tilgnrel: begin { ln of real }

         gennod(ip^.left); { generate operand }
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
         genfpuchk { perform fpu check }

      end;
      tisinrel: begin { sine of real }

         gennod(ip^.left); { generate operand }
         { find sine }
         emitbyt($d9); { fsin }
         emitbyt($fe);
         genfpuchk { perform fpu check }

      end;
      tisqtrel: begin { square root of real }

         gennod(ip^.left); { generate operand }
         { find sqrt }
         emitbyt($d9); { fsqrt }
         emitbyt($fa);
         genfpuchk { perform fpu check }

      end;
      tieolt: genrot(ip, paslib_chkeol, gbltext, nil, nil, nil); { check eoln }
      tieof: begin { check end of file }

         tp := baset(ip^.base); { find base type }
         if tp^.t = ttext then
            genrot(ip, paslib_eoftxt, ip^.base, nil, nil, nil) { eof text }
         else
            genrot(ip, paslib_eoffil, ip^.base, nil, nil, nil) { eof binary }

      end;
      tiodd: begin { find if integer is odd }

         gennod(ip^.left); { generate node }
         { Just mask off the lower bit. For use as a conditional, this is
           optimized out by a jump. }
         emitbyt($83); { and r,1 }
         emitbyt($c0+$04*8+dreg(ip^.lreg));
         emitbyt(1)

      end;
      tisucint: begin { find successor }

         gennod(ip^.left); { generate operand }
         emitbyt($40+dreg(ip^.rsreg)) { inc r }

      end;
      tiprdint: begin { find predecessor }

         gennod(ip^.left); { generate operand }
         emitbyt($48+dreg(ip^.rsreg)) { dec r }

      end;
      tirnd, titrc: begin { round real to integer }

         gennod(ip^.left); { generate operand }
         { First we must load a control word that specifies the rounding action.
           We coin this word into the constant area for efficientcy, and load it
           from there. }
         emitbyt($d9); { fldcw }
         emitbyt($00+$05*8+$05);
         if ip^.i = tirnd then emitadr(rndnear, itadr) { round to nearest }
         else emitadr(rndzero, itadr); { round to zero }
         { Since the FPU cannot store direct to a register, a temp  at base/reg
           must be used, then loaded from that. }
         genladr(ip^.rsreg, ip^.base2); { load address of temp }
         emitbyt($db); { fistp [r] }
         emitbyt($00+$03*8+dreg(ip^.rsreg));
         { load back to register }
         emitbyt($8b); { mov r,[r] }
         emitbyt($00+dreg(ip^.rsreg)*8+dreg(ip^.rsreg));
         fpusct := fpusct-1; { decrease FPU stack level }
         if fpusct < 0 then error(esysflt148) { underflow }

      end;
      { check file exists }
      tiexist: genrot(ip, syslib_exists, gblstr, nil, nil, nil);
      tilen: genrot(ip, paslib_fillen, nil, nil, nil, nil); { find file length }
      tiloc: genrot(ip, paslib_filloc, nil, nil, nil, nil); { find file location }
      tiget: genrot(ip, paslib_getfil, nil, nil, nil, nil); { get file }
      tigett: genrot(ip, paslib_gettxt, gbltext, nil, nil, nil); { text file get }
      tiput: genrot(ip, paslib_putfil, nil, nil, nil, nil); { put file }
      { get buffer address }
      tilodafbuf: genrot(ip, paslib_lbafil, nil, nil, nil, nil);
      { get buffer address text }
      tilodafbuft: genrot(ip, paslib_lbatxt, nil, nil, nil, nil);

      { *** Terminals (roots) ************************************************ }

      tiprccal, tiprccalo: begin

         genprc(ip); { generate procedure call }
         if fpusct <> 0 then error(esysflt158) { FPU stack should be empty }

      end;
      tiprccali: begin

         genprc(ip); { generate procedure call indirect }
         if fpusct <> 0 then error(esysflt159) { FPU stack should be empty }

      end;
      ticalpar: gennod(ip^.left); { this is just a linking entry }
      tiwrtsrc: begin

         { convert this operator to iwrtgstft type call }
         gennod(ip^.left); { generate file to ecx}
         gennod(ip^.right); { generate pointer eax }
         { load length in to ebx register }
         emitbyt($c7); { mov r,imm32 }
         emitbyt($c0+$00*8+dreg(rgebx));
         emitint(ip^.base^.size);
         { call routine }
         genrotcal(paslib_wrtfil);
         if fpusct <> 0 then error(esysflt160) { FPU stack should be empty }

      end;
      tiwrtintt: begin

         gennod(ip^.left); { generate file to eax}
         gennod(ip^.right); { generate integer to ecx }
         chkpar(gblint, ip^.right); { check range and sizing }
         { load field into ebx register }
         emitbyt($c7); { mov r,imm32 }
         emitbyt($c0+$00*8+dreg(rgebx));
         emitint(intfld);
         { call routine }
         genrotcal(paslib_wrtint);
         if fpusct <> 0 then error(esysflt161) { FPU stack should be empty }

      end;
      tiwrtchrt: begin

         gennod(ip^.left); { generate file to eax}
         gennod(ip^.right); { generate character to ecx }
         { load field into ebx register }
         emitbyt($c7); { mov r,imm32 }
         emitbyt($c0+$00*8+dreg(rgebx));
         emitint(chrfld);
         { call routine }
         genrotcal(paslib_wrtchr);
         if fpusct <> 0 then error(esysflt162) { FPU stack should be empty }

      end;
      { write boolean }
      tiwrtbolt: genrot(ip, paslib_wrtbol, gbltext, gblbool, nil, nil);
      tiwrtrelt: begin

         gennod(ip^.left); { generate file to eax }
         gennod(ip^.right); { generate real to tos }
         { load field into ebx register }
         emitbyt($c7); { mov r,imm32 }
         emitbyt($c0+$00*8+dreg(rgebx));
         emitint(relfld);
         { call routine }
         genrotcal(paslib_wrtreal);
         fpusct := fpusct-1; { decrease FPU stack level }
         if fpusct < 0 then error(esysflt175); { underflow }
         if fpusct <> 0 then error(esysflt163) { FPU stack should be empty }

      end;
      tiwrtstrt: begin

         { convert this operator to iwrtgstft type call }
         gennod(ip^.left); { generate file to ecx }
         gennod(ip^.right); { generate string pointer to eax }
         { load length in to ebx register }
         emitbyt($c7); { mov r,imm32 }
         emitbyt($c0+$00*8+dreg(rgebx));
         emitint(ip^.base^.size);
         { call routine }
         genrotcal(paslib_wrtstr);
         if fpusct <> 0 then error(esysflt164) { FPU stack should be empty }

      end;
      tiwrtgstt: begin

         { write general string to file }
         genrot(ip, paslib_wrtstr, gbltext, gblstr, nil, nil);
         if fpusct <> 0 then error(esysflt165) { FPU stack should be empty }

      end;
      tiwrtintft: begin

         { write integer to file with field }
         genrot(ip, paslib_wrtint, gbltext, gblint, gblint, nil);
         if fpusct <> 0 then error(esysflt166) { FPU stack should be empty }

      end;
      tiwrtchrft: begin

         { write character to file with field }
         genrot(ip, paslib_wrtchr, gbltext, gblchr, gblint, nil);
         if fpusct <> 0 then error(esysflt167) { FPU stack should be empty }

      end;
      tiwrtbolft: begin

         { write boolean to file with field }
         genrot(ip, paslib_wrtblf, gbltext, gblbool, gblint, nil);
         if fpusct <> 0 then error(esysflt168) { FPU stack should be empty }

      end;
      tiwrtrelft: begin

         { write real to text file }
         genrot(ip, paslib_wrtreal, gbltext, gblreal, gblint, nil);
         fpusct := fpusct-1; { decrease FPU stack level }
         if fpusct < 0 then error(esysflt225); { underflow }
         if fpusct <> 0 then error(esysflt169) { FPU stack should be empty }

      end;
      tiwrtstrft: begin

         { convert this operator to iwrtgstft type call }
         gennod(ip^.left); { generate file to ecx}
         gennod(ip^.right); { generate string eax }
         gennod(ip^.xtra); { generate field to edx }
         { If not signed, generate sign check. }
         if not chksgn(ip^.xtra^.rbase) then gensgnchk(ip^.xtra^.freg);
         { load length in to ebx register }
         emitbyt($c7); { mov r,imm32 }
         emitbyt($c0+$00*8+dreg(rgebx));
         emitint(ip^.base^.size);
         { call routine }
         genrotcal(paslib_wrtstrf);
         if fpusct <> 0 then error(esysflt176) { FPU stack should be empty }

      end;
      tiwrtgstft: begin

         { write general string to file fielded }
         genrot(ip, paslib_wrtstrf, gbltext, gblstr, gblint, nil);
         if fpusct <> 0 then error(esysflt177) { FPU stack should be empty }

      end;
      tiwrtrelfft: begin

         { write real fractional to text file }
         genrot(ip, paslib_wrtrlf, gbltext, gblreal, gblint, gblint);
         fpusct := fpusct-1; { decrease FPU stack level }
         if fpusct < 0 then error(esysflt226); { underflow }
         if fpusct <> 0 then error(esysflt178) { FPU stack should be empty }

      end;
      tiwrtsrl, tiwrtrel: begin { write real/short real to binary file }

         gennod(ip^.left); { place file in its register }
         if (ip^.right^.i = tilimrel) or (ip^.right^.i = tilodrel) then
            { The real is coming from a variable or constant. We can write it
              directly and avoid the FPU load and store. Note that the allocator
              must also realize this and place the proper address in this
              entry. }
            genladr(ip^.t1reg, ip^.right^.base)
         else begin { load via FPU }

            gennod(ip^.right); { place real on stack top }
            { Now we must place the real as short in memory, and address that.
              The upper pass has created a temp for us as the operator base and
              rreg. Its slightly cheating that this is a 64 bit temp, and we may
              be putting a 32 bit real there. }
            genladr(ip^.t1reg, ip^.base2); { load address of temp }
            { store to that }
            if ip^.i = tiwrtsrl then emitbyt($d9) { fsts [r] }
            else emitbyt($dd); { fstd [r] }
            emitbyt($00+$02*8+dreg(ip^.rsreg))

         end;
         { now load length }
         emitbyt($c7); { mov rgecx,imm32 }
         emitbyt($c0+$00*8+dreg(rgebx));
         if ip^.i = tiwrtsrl then emitint(srlsiz)
         else emitint(relsiz);
         { generate routine call }
         genrotcal(paslib_wrtfil);
         fpusct := fpusct-1; { decrease FPU stack level }
         if fpusct < 0 then error(esysflt149); { underflow }
         if fpusct <> 0 then error(esysflt179) { FPU stack should be empty }

      end;
      tiwrtset: begin

         gennod(ip^.left); { generate file to ecx }
         gennod(ip^.right); { generate pointer eax }
         { load length in to ebx register }
         emitbyt($c7); { mov r,imm32 }
         emitbyt($c0+$00*8+dreg(rgebx));
         emitint(setsiz);
         { call routine }
         genrotcal(paslib_wrtfil);
         if fpusct <> 0 then error(esysflt180) { FPU stack should be empty }

      end;
      tiwrtbol: begin

         gennod(ip^.left); { generate file to ecx }
         gennod(ip^.right); { generate boolean eax }
         emitbyt($50+dreg(rgeax)); { stack data }
         { address the stacked value }
         emitbyt($8b); { mov eax,esp }
         emitbyt($c0+dreg(rgeax)*8+$04);
         { load length in to ebx register }
         emitbyt($c7); { mov r,imm32 }
         emitbyt($c0+$00*8+dreg(rgebx));
         emitint(bolsiz);
         { call routine }
         genrotcal(paslib_wrtfil);
         emitbyt($58+dreg(rgeax)); { remove stacked data }
         if fpusct <> 0 then error(esysflt181) { FPU stack should be empty }

      end;
      tiwrtchr: begin

         gennod(ip^.left); { generate file to ecx }
         gennod(ip^.right); { generate character eax }
         emitbyt($50+dreg(rgeax)); { stack data }
         { address the stacked value }
         emitbyt($8b); { mov eax,esp }
         emitbyt($c0+dreg(rgeax)*8+$04);
         { load length in to ebx register }
         emitbyt($c7); { mov r,imm32 }
         emitbyt($c0+$00*8+dreg(rgebx));
         emitint(chrsiz);
         { call routine }
         genrotcal(paslib_wrtfil);
         emitbyt($58+dreg(rgeax)); { remove stacked data }
         if fpusct <> 0 then error(esysflt182) { FPU stack should be empty }

      end;
      tiwrtint: begin

         gennod(ip^.left); { generate file to ecx }
         gennod(ip^.right); { generate integer eax }
         emitbyt($50+dreg(rgeax)); { stack data }
         { address the stacked value }
         emitbyt($8b); { mov eax,esp }
         emitbyt($c0+dreg(rgeax)*8+$04);
         { load length in to ebx register }
         emitbyt($c7); { mov r,imm32 }
         emitbyt($c0+$00*8+dreg(rgebx));
         emitint(ip^.base^.size);
         { call routine }
         genrotcal(paslib_wrtfil);
         emitbyt($58+dreg(rgeax)); { remove stacked data }
         if fpusct <> 0 then error(esysflt183) { FPU stack should be empty }

      end;
      tiwrteolt:begin

         gennod(ip^.left); { generate file to eax }
         { call routine }
         genrotcal(paslib_wrteol);
         if fpusct <> 0 then error(esysflt184) { FPU stack should be empty }

      end;
      tiredsrc: begin

         gennod(ip^.left); { generate file to ecx }
         gennod(ip^.right); { generate pointer eax }
         { load length in to ebx register }
         emitbyt($c7); { mov r,imm32 }
         emitbyt($c0+$00*8+dreg(rgebx));
         emitint(ip^.base^.size);
         { call routine }
         genrotcal(paslib_rdfil);
         if fpusct <> 0 then error(esysflt185) { FPU stack should be empty }

      end;
      tiredintt: begin

         if ip^.base^.size = regsiz then begin

            { standard size read, use routine direct }
            gennod(ip^.left); { generate file }
            gennod(ip^.right); { generate integer address }
            { generate routine call }
            genrotcal(paslib_rdint)

         end else begin { use buffered version }

            gennod(ip^.left); { load file }
            genladr(rgebx, ip^.base2); { load temp address }
            { generate routine call }
            genrotcal(paslib_rdint);
            gennod(ip^.right); { generate integer address }
            genlodsor(rgebx, ip^.base2, ip^.base^.size, 0); { load contents }
            { perform bounds check }
            lb.v := lbound(ip^.base); { load the bounds }
            lb.s := lbounds(ip^.base);
            ub.v := ubound(ip^.base);
            ub.s := ubounds(ip^.base);
            genbndr(chksgn(ip^.base), rgebx, rgnull, false, lb, ub);
            genstoindr(rgebx, rgnull, ip^.rreg, ip^.base^.size)  { store }

         end;
         if fpusct <> 0 then error(esysflt186) { FPU stack should be empty }

      end;
      tiredchrt: begin

         genrot(ip, paslib_rdchr, gbltext, nil, nil, nil); { read character }
         if fpusct <> 0 then error(esysflt187) { FPU stack should be empty }

      end;
      tiredrelt: begin

         genrot(ip, paslib_rdreal, gbltext, nil, nil, nil); { read real }
         if fpusct <> 0 then error(esysflt188) { FPU stack should be empty }

      end;
      tiredsrlt:begin { read short real }

         { There is no routine for read short, so we load a full real to the
           temp given in the base/rreg, then transfer the result to the final
           variable. Unfortunately this means loading and unloading the real
           in the FPU again. }
         gennod(ip^.left); { load file }
         genladr(rgebx, ip^.base2); { load temp address }
         { generate routine call }
         genrotcal(paslib_rdreal);
         genladr(ip^.t1reg, ip^.base2); { load temp address }
         genlodrel(ip^.t1reg, ip^.base2); { load from result }
         gennod(ip^.right); { load address of short real }
         emitbyt($d9); { fstps [r] }
         emitbyt($00+$03*8+dreg(ip^.rreg));
         if fpusct <> 0 then error(esysflt189) { FPU stack should be empty }

      end;
      tiredeolt: begin

         genrot(ip, paslib_rdeol, gbltext, nil, nil, nil); { read eoln }
         if fpusct <> 0 then error(esysflt190) { FPU stack should be empty }

      end;
      tireset: begin { reset file }

         tp := baset(ip^.base); { find base type }
         if tp^.t = ttext then begin { text file }

            gennod(ip^.left); { generate file to eax }
            { set record length in ebx (1 for text) }
            emitbyt($33); { xor ebx,ebx }
            emitbyt($c0+dreg(rgebx)*8+dreg(rgebx));
            emitbyt($40+dreg(rgebx)); { inc ebx }
            { generate routine call }
            genrotcal(paslib_restxt)

         end else begin { standard file }

            gennod(ip^.left); { generate file to eax }
            { set record length in ebx }
            emitbyt($b8+dreg(rgebx)); { mov ebx,size }
            emitint(tp^.filt^.size);
            { generate routine call }
            genrotcal(paslib_resfil)

         end;
         if fpusct <> 0 then error(esysflt191) { FPU stack should be empty }

      end;
      tirewrite: begin { rewrite file }

         tp := baset(ip^.base); { find base type }
         if tp^.t = ttext then begin { text file }

            gennod(ip^.left); { generate file to eax }
            { set record length in ebx (1 for text) }
            emitbyt($33); { xor ebx,ebx }
            emitbyt($c0+dreg(rgebx)*8+dreg(rgebx));
            emitbyt($40+dreg(rgebx)); { inc ebx }
            { generate routine call }
            genrotcal(paslib_rwttxt)

         end else begin { standard file }

            gennod(ip^.left); { generate file to eax }
            { set record length in ebx }
            emitbyt($b8+dreg(rgebx)); { mov ebx,size }
            emitint(tp^.filt^.size);
            { generate routine call }
            genrotcal(paslib_rwtfil)

         end;
         if fpusct <> 0 then error(esysflt105) { FPU stack should be empty }

      end;
      tiupdate: begin { update file }

         tp := baset(ip^.base); { find base type }
         gennod(ip^.left); { generate file to eax }
         { set record length in ebx }
         emitbyt($b8+dreg(rgebx)); { mov ebx,size }
         emitint(tp^.filt^.size);
         { generate routine call }
         genrotcal(paslib_update);
         if fpusct <> 0 then error(esysflt192) { FPU stack should be empty }

      end;
      tiappend: begin { append file }

         tp := baset(ip^.base); { find base type }
         if tp^.t = ttext then begin { text file }

            gennod(ip^.left); { generate file to eax }
            { set record length in ebx (1 for text) }
            emitbyt($33); { xor ebx,ebx }
            emitbyt($c0+dreg(rgebx)*8+dreg(rgebx));
            emitbyt($40+dreg(rgebx)); { inc ebx }
            { generate routine call }
            genrotcal(paslib_apptxt);
            if fpusct <> 0 then error(esysflt192) { FPU stack should be empty }

         end else begin { standard file }

            gennod(ip^.left); { generate file to eax }
            { set record length in ebx }
            emitbyt($b8+dreg(rgebx)); { mov ebx,size }
            emitint(tp^.filt^.size);
            { generate routine call }
            genrotcal(paslib_appfil);
            if fpusct <> 0 then error(esysflt192) { FPU stack should be empty }

         end

      end;
      ticlose: genrot(ip, paslib_close, gbltext, nil, nil, nil); { close file }
      tipack: begin { pack array }

         { At this time, pack simply acts as an assign, because
           packing is unimplemented. Requires edi, esi, eax and ecx. }
         gennod(ip^.left); { get unpacked array pointer to esi }
         gennod(ip^.right); { get starting index to eax }
         gennod(ip^.xtra); { get packed array pointer to edi }
         { generate bounds check and adjust }
         genbndremchkr(ip^.rreg, ip^.rregx, ip^.right^.rbase^.size > regsiz,
                       ip^.base2^.arri, ip^.right^.rbase);
         { scale to base type }
         emitbyt($bb); { mov ebx,size }
         emitint(ip^.base2^.arrt^.size); { place base type size }
         emitbyt($f7); { mul eax,ebx }
         emitbyt($e3);
         { offset from base address }
         emitbyt($03); { add esi,eax }
         emitbyt($f0);
         { load packed array length as count }
         emitbyt($b9); { mov ecx,size }
         emitint(ip^.base^.size); { place packed array size }
         { move data into place }
         emitbyt($f3); { rep }
         emitbyt($a4); { movsb }
         if fpusct <> 0 then error(esysflt193) { FPU stack should be empty }

      end;
      tiunpack: begin

         { At this time, unpack simply acts as an assign, because
           packing is unimplemented. Requires edi, esi, eax and ecx. }
         gennod(ip^.left); { get packed array pointer in esi }
         gennod(ip^.right); { get unpacked array pointer in edi }
         gennod(ip^.xtra); { get starting index in eax }
         { generate bounds check and adjust }
         genbndremchkr(ip^.xreg, ip^.xregx, ip^.xtra^.rbase^.size > regsiz,
                       ip^.base^.arri, ip^.xtra^.rbase);
         { scale to base type }
         emitbyt($bb); { mov ebx,size }
         emitint(ip^.base^.arrt^.size); { place base type size }
         emitbyt($f7); { mul eax,ebx }
         emitbyt($e3);
         { offset from base address }
         emitbyt($03); { add edi,eax }
         emitbyt($f8);
         { load packed array length as count }
         emitbyt($b9); { mov ecx,size }
         emitint(ip^.base2^.size); { place packed array size }
         { move data into place }
         emitbyt($f3); { rep }
         emitbyt($a4); { movsb }
         if fpusct <> 0 then error(esysflt194) { FPU stack should be empty }

      end;
      tipaget: begin

         genrot(ip, paslib_pagtxt, gbltext, nil, nil, nil); { page file }
         if fpusct <> 0 then error(esysflt195) { FPU stack should be empty }

      end;
      tiassign: begin

         genrot(ip, paslib_assign, gbltext, gblstr, nil, nil); { assign file }
         if fpusct <> 0 then error(esysflt196) { FPU stack should be empty }

      end;
      tipos: begin

         genrot(ip, paslib_posfil, gbltext, gblint, nil, nil); { position file }
         if fpusct <> 0 then error(esysflt197) { FPU stack should be empty }

      end;
      tidel: begin

         genrot(ip, syslib_delete, gblstr, nil, nil, nil); { delete file }
         if fpusct <> 0 then error(esysflt198) { FPU stack should be empty }

      end;
      tichg: begin

         genrot(ip, syslib_change, gblstr, gblstr, nil, nil); { change file name }
         if fpusct <> 0 then error(esysflt199) { FPU stack should be empty }

      end;
      tistoint, tistochr, tistobol, tistofint, tistofchr,
      tistofbol: gensto(ip); { generate store direct }
      tistosrl, tistorel, tistofsrl, tistofrel: begin

         setref(ip^.base); { set that is referenced }
         gennod(ip^.left); { generate left }
         if ip^.base^.t = tfunc then { function result }
            genstorel(ip^.t1reg, ip^.base^.fncr) { store real }
         else { standard }
            genstorel(ip^.t1reg, ip^.base); { store real }
         fpusct := fpusct-1; { decrease FPU stack depth }
         if fpusct < 0 then error(efstkovf); { stack underflow }
         if fpusct <> 0 then error(esysflt201) { FPU stack should be empty }

      end;
      tistoset: begin

         setref(ip^.base); { set that is referenced }
         gennod(ip^.left); { generate left to esi }
         { The register allocation pass has given us esi, edi, and ecx for
           the move. }
         genladr(rgedi, ip^.base); { get address in edi }
         emitbyt($c7); { mov ecx,setsiz div 4 }
         emitbyt($c1);
         emitint(setsiz div 4);
         { perform the move }
         emitbyt($f3); { rep }
         emitbyt($a5); { movsd }
         if fpusct <> 0 then error(esysflt202) { FPU stack should be empty }

      end;
      tistosrc: begin

         setref(ip^.base); { set that is referenced }
         gennod(ip^.left); { generate left to esi }
         { The register allocation pass has given us esi, edi, and ecx for
           the move. }
         genladr(rgedi, ip^.base); { get address in edi }
         emitbyt($c7); { mov ecx,size }
         emitbyt($c1);
         emitint(ip^.base^.size);
         { perform the move }
         emitbyt($f3); { rep }
         emitbyt($a4); { movsb }
         if fpusct <> 0 then error(esysflt203) { FPU stack should be empty }

      end;
      tistogar: begin

         setref(ip^.base); { set that is referenced }
         { array pointer will go to esi, length to ecx }
         gennod(ip^.left); { generate left }
         { load the length of pointer to reserved register }
         genlodsor(ip^.t1reg, ip^.base, intsiz, ptrsiz);
         emitbyt($3b); { mov rl,rr }
         emitbyt($c0+dreg(ip^.lregx)*8+dreg(ip^.t1reg));
         genske($74, relenmat); { generate match error }
         genladr(rgedi, ip^.base); { get address to store in edi }
         { move array to destination }
         emitbyt($f3); { rep }
         emitbyt($a4); { movsb }
         if fpusct <> 0 then error(esysflt116) { FPU stack should be empty }

      end;
      tistotgp, tistoftgp: begin

         setref(ip^.base); { set that is referenced }
         gennod(ip^.left); { generate left }
         { generate store tagged pointer direct }
         if ip^.base^.t = tfunc then { function result }
            genstotpr(ip^.t1reg, ip^.lreg, ip^.lregx, ip^.base^.fncr)
         else
            genstotpr(ip^.t1reg, ip^.lreg, ip^.lregx, ip^.base);
         if fpusct <> 0 then error(esysflt204) { FPU stack should be empty }

      end;
      tistiint, tistichr, tistibol, tistifint, tistifchr,
      tistifbol: genstoind(ip); { generate indirect store }
      tistisrl, tistifsrl: begin

         gennod(ip^.left); { resolve address }
         gennod(ip^.right); { resolve operand }
         emitbyt($d9); { fstps [rl] }
         emitbyt($00+$03*8+dreg(ip^.lreg));
         fpusct := fpusct-1; { decrease FPU stack level }
         if fpusct < 0 then error(esysflt236); { underflow }
         if fpusct <> 0 then error(esysflt206) { FPU stack should be empty }

      end;
      tistirel, tistifrel: begin

         gennod(ip^.left); { resolve address }
         gennod(ip^.right); { resolve operand }
         emitbyt($dd); { fstpd [rl] }
         emitbyt($00+$03*8+dreg(ip^.lreg));
         genfpuchk; { perform fpu check }
         fpusct := fpusct-1; { decrease FPU stack level }
         if fpusct < 0 then error(esysflt174); { underflow }
         if fpusct <> 0 then error(esysflt207) { FPU stack should be empty }

      end;
      tistiset: begin

         { The register allocation pass has given us esi, edi, and ecx for the
           move. }
         gennod(ip^.left); { resolve desintation address to edi }
         gennod(ip^.right); { resolve source address to esi }
         emitbyt($c7); { mov ecx,size/4 }
         emitbyt($c1);
         emitint(setsiz div 4);
         { perform the move }
         emitbyt($f3); { rep }
         emitbyt($a5); { movsd }
         if fpusct <> 0 then error(esysflt208) { FPU stack should be empty }

      end;
      tistisrc: begin

         { The register allocation pass has given us esi, edi, and ecx for the
           move. }
         gennod(ip^.left); { resolve desintation address to edi }
         gennod(ip^.right); { resolve source address to esi }
         emitbyt($c7); { mov ecx,size }
         emitbyt($c1);
         emitint(ip^.base^.size);
         { perform the move }
         emitbyt($f3); { rep }
         emitbyt($a4); { movsb }
         if fpusct <> 0 then error(esysflt209) { FPU stack should be empty }

      end;
      tistigar: begin

         { The register allocation pass has given us esi, edi, and ecx for the
           move. }
         gennod(ip^.left); { resolve destination to edi/ecx }
         gennod(ip^.right); { resolve source address to esi }
         emitbyt($3b); { mov rl,rr }
         emitbyt($c0+dreg(ip^.lregx)*8+dreg(ip^.rregx));
         genske($74, relenmat); { generate match error }
         { move array to destination }
         emitbyt($f3); { rep }
         emitbyt($a4); { movsb }
         if fpusct <> 0 then error(esysflt210) { FPU stack should be empty }

      end;
      tistitgp, tistiftgp: begin

         gennod(ip^.left); { resolve address }
         gennod(ip^.right); { resolve operand }
         { store to destination }
         emitbyt($89); { movd [rd],rs }
         emitbyt($00+dreg(ip^.rreg)*8+dreg(ip^.lreg));
         emitbyt($89); { movd regsiz[rd],rsx }
         emitbyt($40+dreg(ip^.rregx)*8+dreg(ip^.lreg));
         emitbyt(regsiz);
         if fpusct <> 0 then error(esysflt211) { FPU stack should be empty }

      end;
      tirngchk: begin { range check }

         gennod(ip^.left); { generate operand }
         genbndxfr(ip^.rbase, ip^.left^.rbase, ip^.freg, ip^.fregx);
         if fpusct <> 0 then error(esysflt212) { FPU stack should be empty }

      end;
      tinew, tidisp: begin

         gennwdp(ip); { allocate/deallocate variable }
         if fpusct <> 0 then error(esysflt213) { FPU stack should be empty }

      end;
      titag: error(esysflt120); { should not occur }
      tinewgar: begin { allocate general array }

         { The allocation for a general array must be calculated by the number
           of elements. eax and edx must be used for the multiply. rreg of the
           operator node must have a holding register for the size. }
         gennod(ip^.right); { load length into ebx }
         { save the length for after allocation }
         emitbyt($50+dreg(rgebx)); { push ebx }
         emitbyt($c7); { mov eax,imm32 }
         emitbyt($c0+$00*8+dreg(rgeax));
         emitint(ip^.base^.gart^.size);
         emitbyt($f7); { mul eax,ebx }
         emitbyt($c0+$04*8+dreg(rgebx));
         emitbyt($8b); { mov ebx,eax }
         emitbyt($c0+dreg(rgebx)*8+dreg(rgeax));
         gennod(ip^.left); { load address of pointer to eax }
         { call new routine }
         genrotcal(syslib_getspace);
         { set length for number of elements instead of bytes }
         emitbyt($58+dreg(rgebx)); { pop ebx }
         emitbyt($89); { mov regsiz[eax],ebx }
         emitbyt($40+dreg(rgebx)*8+dreg(rgeax));
         emitbyt(regsiz);
         if fpusct <> 0 then error(esysflt214) { FPU stack should be empty }

      end;
      tidspgar: begin

         genrot(ip, syslib_putspace, nil, nil, nil, nil); { generate dispose call }
         if fpusct <> 0 then error(esysflt215) { FPU stack should be empty }

      end;
      tiifbgn: begin { if statement }

         gettypa(lab1, tlab); { get a else/end label }
         if ip^.left^.i = tinotbol then begin

            { we can fold a not into the conditional right here }
            gennod(ip^.left^.left); { generate the left conditional }
            emitbyt($0f); { jcc else/end }
            emitbyt($80+ccode(ip^.lflg));
            emitadr(lab1, itradr) { output jump location }

         end else begin

            gennod(ip^.left); { generate the left conditional }
            emitbyt($0f); { jcc else/end }
            emitbyt($80+ccode(flginv(ip^.lflg)));
            emitadr(lab1, itradr) { output jump location }

         end;
         genlst(ip^.flow2); { generate true flow }
         if ip^.flow3 <> nil then begin { there is a false list }

            gettypa(lab2, tlab); { get a end of all label }
            emitbyt($e9); { jmp end }
            emitadr(lab2, itradr); { output jump location }
            gendistrp; { generate disassembly trip }
            lab1^.addr := pgmcnt; { set jump else/end location }
            genlst(ip^.flow3); { generate false flow }
            lab2^.addr := pgmcnt { set end of all location }

         end else lab1^.addr := pgmcnt; { set jump else/end location }
         if fpusct <> 0 then error(esysflt216) { FPU stack should be empty }

      end;
      tiwhlbgn: begin { while statement }

         gettypa(lab1, tlab); { get a jump over label }
         gettypa(lab2, tlab); { get a loop label }
         lab2^.addr := pgmcnt; { set loop location }
         if ip^.left^.i = tinotbol then begin

            { we can fold a not into the conditional right here }
            gennod(ip^.left^.left); { generate the left conditional }
            emitbyt($0f); { jcc else/end }
            emitbyt($80+ccode(ip^.lflg));
            emitadr(lab1, itradr) { output jump location }

         end else begin

            gennod(ip^.left); { generate the left conditional }
            emitbyt($0f); { jcc end }
            emitbyt($80+ccode(flginv(ip^.lflg)));
            emitadr(lab1, itradr) { output jump location }

         end;
         genlst(ip^.flow2); { generate enclosed flow }
         emitbyt($e9); { jmp loop }
         emitadr(lab2, itradr); { output jump location }
         gendistrp; { generate disassembly trip }
         lab1^.addr := pgmcnt; { set jump over location }
         if fpusct <> 0 then error(esysflt217) { FPU stack should be empty }

      end;
      tirptbgn: begin { repeat statement }

         gettypa(lab1, tlab); { get a loop label }
         lab1^.addr := pgmcnt; { set loop location }
         genlst(ip^.flow2); { generate flow }
         if ip^.left^.i = tinotbol then begin

            gennod(ip^.left^.left); { generate the left conditional }
            emitbyt($0f); { jcc loop }
            emitbyt($80+ccode(ip^.lflg));
            emitadr(lab1, itradr) { output jump location }

         end else begin

            gennod(ip^.left); { generate the left conditional }
            emitbyt($0f); { jcc loop }
            emitbyt($80+ccode(flginv(ip^.lflg)));
            emitadr(lab1, itradr) { output loop location }

         end;
         if fpusct <> 0 then error(esysflt218) { FPU stack should be empty }

      end;
      tifortint, tifortchr, tifortbol, tifordint, tifordchr,
      tifordbol: genfor(ip);
      ticasbgn: begin { case statement }

         gettypa(lab3, tlab); { get error label }
         if ip^.base^.t = tcastbl then begin { case jump table }

            gennod(ip^.left); { generate selector expression }
            { remove lower bound of case range }
            gendoiir(false, $28, $00, ip^.lreg, rgnull, false, ip^.base^.ctl,
                     false);
            if fcaschk then begin { generate case check }

               { Removing the case check saves a small amount of time in a jump
                 table, so we have a separate flags for arrays and missed cases,
                 though equally serious. Check range of base adjusted
                 selector. }
               ti := ip^.base^.cth; { find span of select }
               ti2.v := sssub(ti, ip^.base^.ctl);
               ti2.s := sssubs(ti, ip^.base^.ctl);
               gencmpi(ip^.lreg, ti2);
               emitbyt($0f); { ja error }
               emitbyt($87);
               emitadr(lab3, itradr) { output jump location }

            end;
            emitbyt($ff); { jmp table[rs*4] }
            emitbyt($00+$04*8+$04);
            emitbyt($80+dreg(ip^.lreg)*8+$05);
            emitadr(ip^.base, itadr);
            gendistrp { generate disassembly trip }

         end else begin { hash jump table }

            { Its a good question whether a hash lookup is too expensive to do
              inline. For this version, we do it. Later we can change this to an
              external routine based on the speed/space option. The expression
              is generated, and must be in eax. A copy register is reserved in
              t1reg of the main entry, and a register to load the table length
              is in rreg. }
            gennod(ip^.left); { generate selector to eax }
            emitbyt($8b); { mov rt,r }
            emitbyt($c0+dreg(ip^.t1reg)*8+dreg(ip^.lreg));
            { Divide the case select by the case table length, then take the
              modulo from that. edx must be reserved for the modulo. The divisor
              register is contained in rreg. Divide is an expensive operation,
              but the case select needs no base adjustment. }
            emitbyt($c7); { mov r,imm32 }
            emitbyt($c0+$00*8+dreg(ip^.t2reg));
            emitint(ip^.base^.ctc);
            { clear upper part of 64 bit word }
            emitbyt($33); { xor r,r }
            emitbyt($c0+dreg(rgedx)*8+dreg(rgedx));
            { perform divide }
            emitbyt($f7); { div eax,r }
            emitbyt($c0+$06*8+dreg(ip^.t2reg));
            { Modulo is now in edx. Now we must loop searching for a matching
              entry. }
            gettypa(lab1, tlab); { get loop label }
            gettypa(lab2, tlab); { get found label }
            lab1^.addr := pgmcnt; { set loop location }
            emitbyt($3b); { cmp r,table[edx*4] }
            emitbyt($00+dreg(ip^.t1reg)*8+$04);
            emitbyt($80+dreg(rgedx)*8+$05);
            emitadr(ip^.base, itadr);
            emitbyt($0f); { jz found }
            emitbyt($84);
            emitadr(lab2, itradr); { output jump location }
            { miss, get next case link }
            emitbyt($8b); { mov edx,table+len*4[edx*4] }
            emitbyt($00+dreg(rgedx)*8+$04);
            emitbyt($80+dreg(rgedx)*8+$05);
            emitadro(ip^.base, itadr, ip^.base^.htc*4);
            { check no next link exists }

            ti.v := 1;
            ti.s := true;
            gencmpi(rgedx, ti);
            emitbyt($0f); { jnz loop }
            emitbyt($85);
            emitadr(lab1, itradr); { place loop jump address }
            { generate case miss error }
            emitbyt($e9); { jmp end }
            emitadr(lab3, itradr); { output jump location }
            gendistrp; { generate disassembly trip }
            { Generate execute to table address. Because the table is three
              entries, the select compare, the missed link, and the target
              address, we separate them into three separate dword tables. }
            lab2^.addr := pgmcnt; { set execute location }
            emitbyt($ff); { jmp table+len*8[edx*4] }
            emitbyt($00+$04*8+$04);
            emitbyt($80+dreg(rgedx)*8+$05);
            emitadro(ip^.base, itadr, ip^.base^.htc*8);
            gendistrp { generate disassembly trip }

         end;
         gettypa(lab1, tlab); { get an end label }
         { now process and set addresses for case statements }
         ip1 := ip^.flow2; { index statement list }
         casels := false; { set no case else entry encountered }
         while (ip1 <> nil) and not casels do begin

            casels := ip1^.i = ticasels; { set case else status }
            if not casels then begin { standard case }

               { not end of list, and not at a case else entry }
               if ip1^.i <> ticasstb then error(esysflt171); { should be case }
               tp := ip1^.base; { index 1st selector table entry }
               while tp <> nil do begin { equate all labels this statement }

                  if tp^.t <> tcassel then error(esysflt172);
                  tp^.addr := pgmcnt; { set case location }
                  tp := tp^.css { next case label }

               end;
               genlst(ip1^.flow2); { generate statement block }
               emitbyt($e9); { jmp end }
               emitadr(lab1, itradr); { output jump location }
               gendistrp; { generate disassembly trip }
               ip1 := ip1^.flow { next case }

            end

         end;
         { The missed case error gets tucked under the case statements, where
           can only be reached by a specific jump. If no case error is
           selected, it just falls through to the next location. If a case else
           was provided, then that is placed into this section. }
         lab3^.addr := pgmcnt; { set error location }
         tp := ip^.base; { index top of case selector list }
         if tp^.t = tcastbl then tp := tp^.ctn
         else if tp^.t = thshtbl then tp := tp^.htn
         else error(esysflt237); { bad entry }
         while tp <> nil do begin { traverse }

            if tp^.t <> tcassel then error(esysflt238); { wrong entry }
            if tp^.csp = true then tp^.addr := pgmcnt; { equate missed to here }
            tp := tp^.csn { link next entry }

         end;
         if casels then { there is an else, place that }
               genlst(ip1^.flow2) { generate statement block }
         else if fcaschk then { generate case check }
            generr(recasvnf); { generate error routine call }
         lab1^.addr := pgmcnt; { set end location }
         { because hashing is cpu specific, we finalize the hash table here }
         if ip^.base^.t = thshtbl then makhst(ip^.base); { make hash table }
         if fpusct <> 0 then error(esysflt220) { FPU stack should be empty }

      end;
      ticasstb, ticasels,
      tigoto, tigotot, tigotof: begin { goto label }

         if ip^.base^.level = blkcnt then begin

            { Jumps to the same level are simple because the stack is allways
              flat between expressions. }
            if ip^.i = tigoto then begin { unconditional jump }

               emitbyt($e9); { jmp l }
               emitadr(ip^.base, itradr);
               gendistrp { generate disassembly trip }

            end else begin { conditional jump }

               gennod(ip^.left); { generate conditional }
               emitbyt($0f); { jcc l }
               if ip^.i = tigotot then emitbyt($80+ccode(ip^.lflg))
               else emitbyt($80+ccode(flginv(ip^.lflg)));
               emitadr(ip^.base, itradr) { output jump location }

            end

         end else begin { jump to another block }

            if (ip^.i = tigotot) or (ip^.i = tigotof) then begin

               gettyp(lab1, tlab); { get jump over label }
               gennod(ip^.left); { generate conditional }
               emitbyt($0f); { jcc l }
               if ip^.i = tigotof then emitbyt($80+ccode(ip^.lflg))
               else emitbyt($80+ccode(flginv(ip^.lflg)));
               emitadr(lab1, itbradr) { output jump location }

            end;
            { load stack from target display }
            { get display for target level }
            if ip^.base^.lmrk^.t = tglbl then begin

               { on main blocks, we use the saved display, since there is no
                 way to find the original display for that block }
               emitbyt($8b); { mov r32,[dispsav] }
               emitbyt($00+dreg(ip^.t1reg)*8+$05);
               emitadr(ip^.base^.lmrk^.ds, itadr) { place display save address }

            end else begin { normal block }

               emitbyt($8b); { mov r32,[ebp-lvl] }
               emitbyt($80+dreg(ip^.t1reg)*8+$5);
               { offset to proper display level }
               emitint(-((ip^.base^.level-1)*4))

            end;
            { load target ebp from display }
            emitbyt($8b); { move ebp,r }
            emitbyt($c0+$5*8+dreg(ip^.t1reg));
            { offset by mark type }
            if ip^.base^.lmrk^.t = tglbl then i := -((ip^.base^.level-1)*4)
            else if ip^.base^.lmrk^.t = tproc then i := ip^.base^.lmrk^.prcg
            else if ip^.base^.lmrk^.t = tfunc then i := ip^.base^.lmrk^.fncg
            else error(esysflt128); { bad }
            { offset to local }
            emitbyt($81); { add r32,imm }
            emitbyt($c0+0*8+dreg(ip^.t1reg));
            { If its a global target, the goto offset from the display to stack
              is fixed, since global blocks have no stacked data. Otherwise, we
              need to output a fixup entry for this, since the offset may not
              be known at the time this jump is encoded. It could be forward. }
            if ip^.base^.lmrk^.t = tglbl then emitint(i) { global is fixed }
            else emitgto(ip^.base^.lmrk); { output fixer for goto offset }
            emitbyt($8b); { mov esp,r32 }
            emitbyt($c0+$4*8+dreg(ip^.t1reg));
            emitbyt($e9); { jmp label }
            emitadr(ip^.base, itradr); { generate code address }
            gendistrp; { generate disassembly trip }
            if (ip^.i = tigotot) or (ip^.i = tigotof) then
               lab1^.addr := pgmcnt { set jump over location }

         end;
         if fpusct <> 0 then error(esysflt221) { FPU stack should be empty }

      end;
      tiwthbgn: begin

         { store record base pointer direct }
         gennod(ip^.left); { generate left }
         { store integer }
         genstosor(ip^.t1reg, dreg(ip^.lreg), ip^.base2, ip^.base2^.size, 0);
         pshwth; { start new 'with' scoping level }
         wthstk^.rect := ip^.base; { place record type }
         wthstk^.vart := ip^.base2; { place holding variable }
         genlst(ip^.flow2); { generate 'with' statement block }
         popwth; { remove scoping level }
         if fpusct <> 0 then error(esysflt222) { FPU stack should be empty }

      end;
      tilabequ: begin

         ip^.base^.addr := pgmcnt; { set location }
         if fpusct <> 0 then error(esysflt223) { FPU stack should be empty }

      end;
      tihalt: begin

         { generate call to halt routine }
         genrot(ip, paslib_abort, nil, nil, nil, nil);
         if fpusct <> 0 then error(esysflt224) { FPU stack should be empty }

      end;
      tiassert: if fincast then begin { include asserts enabled }

         { Asserts are coded just like 'if's jumping over the error trap.
           We could ship the entire assert to the routine, but checking the
           condition in line is faster. }
         gettypa(lab1, tlab); { get a else/end label }
         if ip^.left^.i = tinotbol then begin

            { we can fold a not into the conditional right here }
            gennod(ip^.left^.left); { generate the conditional }
            emitbyt($0f); { jcc else/end }
            emitbyt($80+ccode(flginv(ip^.lflg)));
            emitadr(lab1, itradr) { output jump location }

         end else begin

            gennod(ip^.left); { generate the conditional }
            emitbyt($0f); { jcc else/end }
            emitbyt($80+ccode(ip^.lflg));
            emitadr(lab1, itradr) { output jump location }

         end;
         genrot(ip, paslib_assert, gblstr, nil, nil, nil); { process assert }
         { note that assert will never return }
         gendistrp; { generate disassembly trip }
         lab1^.addr := pgmcnt; { set jump over location }
         if fpusct <> 0 then error(esysflt216) { FPU stack should be empty }

      end;
      tisignal: begin

         genrot(ip, syslib_signal, gblnil, nil, nil, nil); { signal }
         if fpusct <> 0 then error(esysflt126) { FPU stack should be empty }

      end;
      tisignalone: begin

         genrot(ip, syslib_signalone, gblnil, nil, nil, nil); { signal }
         if fpusct <> 0 then error(esysflt127) { FPU stack should be empty }

      end;
      tiwait: begin

         { load lock id to eax }
         emitbyt($8b); { mov eax,[lockid] }
         emitbyt($00+dreg(rgeax)*8+$05);
         emitadr(lockid, itadr); { output location of lock id }
         genrot(ip, syslib_wait, gblnil, nil, nil, nil); { signal }
         if fpusct <> 0 then error(esysflt129) { FPU stack should be empty }

      end;

      titrybgn: begin { try statement }

         { not implemented, see file: trystat.pas }
         error(eunimp21)

      end;
      { these should not occur alone }
      titryexp, titryels: error(esysflt130);

   end;
   restran(ip); { transfer result to transfer register }
   { reverse the push mask }
   for rg := rgedi downto rgeax do if rg in ip^.push then
      { this register needs to be restored }
      emitbyt($58+dreg(rg)); { pop r }
   if rgflg in ip^.push then emitbyt($9d); { popfd }
   genind := genind-3; { remove generation list indent }

   { generate intermediate terminator listing }

   if flstgen then begin

      prthex(8, pgmcnt);
      write(' ', fpusct:1, ' ');
      if genind > 0 then write(' ':genind);
      write('-');
      prttic(ip^.i, 1); writeln

   end

end;

{*******************************************************************************

Generate list

Generates code for a flow list. Iterates through the standard flow list, and
genrates all operators.

*******************************************************************************}

procedure genlst(ip: intptr); { graph root to generate for }

begin

   while ip <> nil do begin { traverse this forward flow }

      gennod(ip); { generate single node }
      ip := ip^.flow { next in flow }

   end

end;

{*******************************************************************************

Create virtual vectors

Allocates virtual vectors for any virtual or override procedures or functions
that are in the current block and do not already have a virtual vector.
Virtual vectors are standard address pointers that are used both
to route callers into the procedure or function, and to store the overriden
vectors so that they can be called via inherited calls.

*******************************************************************************}

procedure makvv;

procedure makvve(tp: typptr); { make vv for entry }

var tp1: typptr; { type entry pointer }

begin

   if tp^.t = tproc then if (tp^.prcoh <> nil) and (tp^.prcvv = nil) then begin

      { override or virtual procedure, both need a virtual vector }
      gettypa(tp1, tvar); { get a virtual vector variable }
      tp1^.vart := gblnil; { set type }
      tp1^.vare := false; { set not external }
      tp1^.local := blkstk^.lvl >= 3; { set global/local status }
      tp^.prcvv := tp1 { set the virtual vector }

   end;
   if tp^.t = tfunc then if (tp^.fncoh <> nil) and (tp^.fncvv = nil) then begin

      { override or virtual procedure, both need a virtual vector }
      gettypa(tp1, tvar); { get a virtual vector variable }
      tp1^.vart := gblnil; { set type }
      tp1^.vare := false; { set not external }
      tp1^.local := blkstk^.lvl >= 3; { set global/local status }
      tp^.fncvv := tp1 { set the virtual vector }

   end

end;

procedure makvvlst(tp: typptr); { create vv for list entries }

begin

   while tp <> nil do begin { traverse }

      makvve(tp); { check and make vv for this entry }
      tp := tp^.next { next entry }

   end

end;

begin

   makvvlst(blkstk^.res); { process standard list }
   makvvlst(blkstk^.resa) { process alternate list }

end;

{*******************************************************************************

Generate block code entry

Generates an entry block. This routine generates the prolog and epilog
code, then calls the list handler to generate the contents of the
block, then generates the epilog code. There are several types of blocks:

1. Global entry blocks.
2. Function blocks.
3. Procedure blocks.

Each one has different types of prolog and epilog code for it. In addition, we
do a lot of customization depending on if locals appear, how many locals, if
they are to be cleared to zero, and if floating point function results appear.

Note: "lea" instructions are used to offset the stack. The reason for this is
that this uses offset address math to form the address, and that does not mess
with the flags.

*******************************************************************************}

procedure genblkent(blk: blkptr); { block pointer }

var locspc:  integer; { local space to allocate }
    parspc:  integer; { parameter space to allocate }
    pp:      typptr;  { parameter list pointer }
    fstk:    integer; { FPU stacking counter }
    { Registers that are in use, either in block or for parameters (only
      applies to procedures and functions) }
    usereg:  regset;
    regspc:  integer; { total space in register save area }
    relrtot: integer; { reals in registers }
    lab:     typptr;  { jump label }
    vv:      boolean; { needs a virtual vector }
    tp:      typptr;
    i:       integer;
    r:       regt;

    { Parameter information block. }

    allptot: integer; { number of total parameters }
    relptot: integer; { number of real parameters }
    tgpptot: integer; { number of tagged pointers }
    stdptot: integer; { number of standard parameters }
    tgprtot: integer; { number of registered tagged pointers }
    stdrtot: integer; { number of registered standard parameters }
    allreg:  regset;  { total register allocation mask }
    tgpreg:  regset;  { tagged pointer allocated registers }
    stdreg:  regset;  { standard allocated registers }

{ generate frame start with current level }

procedure genframe;

begin

   { place current frame on stack, and set new frame from esp }
   emitbyt($c8); { enter 0,level }
   emitbyt($00);
   emitbyt($00);
   emitbyt(blk^.lvl-1) { with current level }

end;

{ check procedure needs a monitor lock }

function monlock(tp: typptr): boolean;

var f: boolean;

begin

   f := false; { set not a locked routine }
   if blk^.mark^.blk^.mark^.t = tglbl then
      if blk^.mark^.blk^.mark^.mrkt = mtmonitor then begin

      { we are within a monitor }
      if tp^.t = tproc then f := tp^.prcx { its global }
      else if tp^.t = tfunc then f := tp^.prcx

   end;

   monlock := f { return result }

end;

begin

   locspc := 0; { set default locals space }
   parspc := 0; { set default overflow parameters space }
   if blk^.mark^.t = tproc then begin { set spaces for procedure }

      locspc := blk^.mark^.prcv; { set locals space }
      parspc := blk^.mark^.prca { set parameter space }

   end else if blk^.mark^.t = tfunc then begin { set spaces for function }

      locspc := blk^.mark^.fncv; { set locals space }
      parspc := blk^.mark^.fnca { set parameter space }

   end;

   { set registers in use }

   usereg := blk^.entreg; { set equal to entry block usage }

   { Meter our block parameters. }

   pp := nil; { set no parameter list }
   allreg := []; { clear parameter registers }
   if blk^.mark^.t = tproc then pp := blk^.mark^.prcp
   else if blk^.mark^.t = tfunc then pp := blk^.mark^.fncp;
   allreg := []; { clear parameter registers }
   if pp <> nil then begin { there is a parameter list }

      regfit(pp, allptot, relptot, tgpptot, stdptot, tgprtot, stdrtot, allreg,
              tgpreg, stdreg);
      relrtot := relptot; { set reals in registers }
      if relptot > maxfst then relrtot := maxfst { too many, limit }

   end;

   { Now set parameter registers as "in use". These are "in use" because
     their contents must be preserved by saving on stack }

   usereg := usereg+allreg;

   { if we do a clear of locals, that needs registers eax, ecx, and edi }

   if (locspc <> 0) and (fclrlcl or blk^.fvar) then
      usereg := usereg+[rgeax, rgecx, rgedi];

   { find space in registers }

   regspc := 0; { clear }
   for r := rgeax to rgedi do if r in usereg then regspc := regspc+regsiz;

   { start the block }

   blk^.mark^.addr := pgmcnt; { set address of code }
   { if this is the main block start, equate the initalize jump }
   if blk^.lvl = 2 then iniblk^.addr := pgmcnt;
   if (blk^.mark^.t = tproc) or (blk^.mark^.t = tfunc) then begin

      { its a procedure or function }
      if blk^.mark^.t = tproc then if blk^.mark^.prcvt then begin

{ note this method only works for global blocks. SHould work on locals }
         { process virtual procedure preamble }
         emitbyt($ff); { jmp [addr] }
         emitbyt($00+$04*8+$05);
         emitadr(blk^.mark^.prcvv, itadr) { generate address }

      end;
      if blk^.mark^.t = tfunc then if blk^.mark^.fncvt then begin

{ note this method only works for global blocks. SHould work on locals }
         { process virtual function preamble }
         emitbyt($ff); { jmp [addr] }
         emitbyt($00+$04*8+$05);
         emitadr(blk^.mark^.fncvv, itadr) { generate address }

      end;
      if locspc <> 0 then begin { there are locals }

         { place current frame on stack, and set new frame from esp }
         if blk^.mark^.prcv < 65535 then begin { let enter allocate locals }

            emitbyt($c8); { enter size,level }
            emitwrd(locspc);
            emitbyt(blk^.lvl-1) { with current level }

         end else begin

            genframe; { generate a frame }
            { allocate locals of any length. We use a "lea" to do this
              because we have not saved the flags, and an add would modify
              them, but lea does not }
            emitbyt($8d); { lea esp,offset[esp] }
            emitbyt($a4);
            emitbyt($24);
            emitint(-locspc)

         end;

      end else { perform no local entry }
         genframe; { generate a frame }
      if blk^.mark^.t = tfunc then begin { function }

         { place dummy function result }
         emitbyt($68); { push 0 }
         emitint(0);
         { check standard real (64 bit) result, or tgp }
         if (realt(blk^.mark^.fncr) and not srealt(blk^.mark^.fncr)) or
            tgpt(blk^.mark^.fncr^.fnrt) then begin

            { is a standard real, expand result to 64 bits }
            emitbyt($68); { push 0 }
            emitint(0);

         end

      end;
      { save flags }
      emitbyt($9c); { pushfd }
      { save registers according to "in use" mask }
      if rgedi in usereg then emitbyt($57); { push edi }
      if rgesi in usereg then emitbyt($56); { push esi }
      if rgedx in usereg then emitbyt($52); { push edx }
      if rgecx in usereg then emitbyt($51); { push ecx }
      if rgebx in usereg then emitbyt($53); { push ebx }
      if rgeax in usereg then emitbyt($50); { push eax }
      { Save any parameters in the FPU. }
      if relptot > 0 then begin { stack out FPU contents }

         { make space on stack }
         emitbyt($83); { sub esp,fpusct*relsiz }
         emitbyt($c0+$05*8+$04);
         emitbyt(relrtot*relsiz);
         for fstk := relrtot downto 1 do
            begin { pop and place FPU stack contents }

            emitbyt($dd); { fstp (fstl-1)*relsiz[esp] }
            emitbyt($40+$03*8+$04);
            emitbyt($00+$04*8+$04);
            emitbyt((fstk-1)*relsiz)

         end

      end;
      { Check there are locals, and either clear locals has been selected, or
        there is a file variable in the locals. Files must allways be
        cleared. }
      if (locspc <> 0) and (fclrlcl or blk^.fvar) then begin

         { Clear local area. This is mainly done to allow files
           to work in a local area, but also helps for other
           variables. Space is cleared with dwords, since stack
           are allways even. }
         emitbyt($8d); { lea edi,off[esp] }
         emitbyt($7c);
         emitbyt($24);
         { offset above FPU saves, register saves, and flags }
         i := relrtot*relsiz+regspc+regsiz;
         { check is a function }
         if blk^.mark^.t = tfunc then begin

            i := i+regsiz; { add function result }
            { if its a long real or tgp, add that }
            if (realt(blk^.mark^.fncr) and not srealt(blk^.mark^.fncr)) or
               tgpt(blk^.mark^.fncr^.fnrt) then
               i := i+regsiz

         end;

         emitbyt(i);
         emitbyt($33); { xor eax,eax }
         emitbyt($c0);
         emitbyt($b9); { mov ecx,size div 4 }
         emitint(locspc div 4);
         emitbyt($f2); { repnz }
         emitbyt($ab) { stosd }

      end;
      { check it is a lockable monitor routine }
      if monlock(blk^.mark) then begin

         { generate entry lock for a monitor routine }
         creatlock; { make sure monitor lock exists }
         emitbyt($8b); { mov eax,[lockid] }
         emitbyt($00+dreg(rgeax)*8+$05);
         emitadr(lockid, itadr); { output location of lock id }
         genrotcal(syslib_lock); { lock the variables }

      end

   end else begin

      if blk^.mark^.t <> tglbl then error(einvfmt); { should be global mark }
      { check block is a process }
      if blk^.mark^.mrkt = mtprocess then begin

         { In the case of process, we don't execute the startup block, but
           create a thread that executes the startup block. Then, we skip the
           main thread to the next block. }
         genframe; { generate a frame }
         gettypa(lab, tlab); { get an address label }
         gettypa(threadid, tvar); { get the type entry }
         threadid^.vart := gblint; { set integer }
         threadid^.vare := false; { set not external }
         threadid^.varr := true; { set referenced }
         threadid^.local := false; { set not local }
         threadid^.size := intsiz; { set size (sizing was already done) }
         emitbyt($c7); { mov eax,addr }
         emitbyt($c0+$00*8+dreg(rgeax));
         emitadr(lab, itadr); { output jump location }
         emitbyt($c7); { mov ebx,procid }
         emitbyt($c0+$00*8+dreg(rgebx));
         emitadr(threadid, itadr); { output location of thread id }
         genrotcal(syslib_newthread); { start new thread }
         { generate call to next module in series }
         genrotcal(modend);
         { on return, kill the thread }
         emitbyt($8b); { mov eax,[threadid] }
         emitbyt($00+dreg(rgeax)*8+$05);
         emitadr(threadid, itadr); { output location of thread id }
         genrotcal(syslib_killthread); { stop this thread }
         emitbyt($c3); { set return to caller }
         gendistrp; { generate disassembly trip }
         lab^.addr := pgmcnt; { set process entry location }
         genrotcal(wrplib_threadinit) { start new thread }

      end;
      genframe; { generate a frame }
      { Major modules are expected to run once to completion. Because
        nesting problems, we must save the display for each such
        to allow a goto a path back to that level. This does not need
        be reentrant, since major modules aren't }
      emitbyt($89); { mov [dispsav],ebp }
      emitbyt($2d);
      emitadr(blk^.mark^.ds, itadr); { place display save address }
      { check block is a monitor }
      if blk^.mark^.mrkt = mtmonitor then begin

         { and activate that }
         creatlock; { make sure monitor lock exists }
         emitbyt($c7); { mov eax,lockid }
         emitbyt($c0+$00*8+dreg(rgeax));
         emitadr(lockid, itadr); { output location of lock id }
         genrotcal(syslib_newlock); { create new lock }
         { lock the monitor variables during initialization }
         emitbyt($8b); { mov eax,[lockid] }
         emitbyt($00+dreg(rgeax)*8+$05);
         emitadr(lockid, itadr); { output location of lock id }
         genrotcal(syslib_lock) { lock the variables }

      end;
      { check any virtual vectors need to be initialzed }
      tp := blk^.typ; { index top of types list }
      while tp <> nil do begin { traverse }

         if tp^.t = tproc then if tp^.prcvt and not tp^.prce then begin

            { It is a virtual procedure in this module. Initialize the virtual
              vector. The virtual vector gets the address of the target routine,
              but offset past the jump indirect instruction that proceeds it. }
            emitbyt($c7); { mov [addr],addr }
            emitbyt($00+$00*8+$05);
            emitadr(tp^.prcvv, itadr); { output location of virtual vector }
            emitadro(tp, itadr, 6); { output location of routine+6 }

         end;
         if tp^.t = tfunc then if tp^.fncvt and not tp^.fnce then begin

            { It is a virtual function in this module. Initialize this virtual
              vector. The virtual vector gets the address of the target routine,
              but offset past the jump indirect instruction that proceeds it. }
            emitbyt($c7); { mov [addr],addr }
            emitbyt($00+$00*8+$05);
            emitadr(tp^.fncvv, itadr); { output location of virtual vector }
            emitadro(tp, itadr, 6); { output location of routine+6 }

         end;
         tp := tp^.next { next entry }

      end;
      { now check any overriders need to hook here }
      tp := blk^.typ; { index top of types list }
      while tp <> nil do begin { traverse }

         if tp^.t = tproc then if not tp^.prcvt and not tp^.prce and
            (tp^.prcoh <> nil) then begin { it's an override in this module }

            { Hook the virtual procedure. First the address of the virtual
              vector from the target is fetched. }
            emitbyt($8b); { mov eax,[addr+2] }
            emitbyt($00+dreg(rgeax)*8+$05);
            emitadro(tp^.prcoh, itadr, 2); { output location of routine+2 }
            { get the address at the virtual vector }
            emitbyt($8b); { mov ebx,[eax] }
            emitbyt($00+dreg(rgebx)*8+$00);
            { save that in our virtual vector for "inherited" calls }
            emitbyt($89); { mov [vv],eax }
            emitbyt($00+dreg(rgebx)*8+$05);
            emitadr(tp^.prcvv, itadr); { output location of vv }
            { now place our overrider address at the vv for the target }
            emitbyt($c7); { mov [eax],addr }
            emitbyt($00+$00*8+dreg(rgeax));
            emitadr(tp, itadr) { output address of overrider }

         end;
         if tp^.t = tfunc then if not tp^.fncvt and not tp^.fnce and
            (tp^.fncoh <> nil) then begin { it's an override in this module }

            { Hook the virtual procedure. First the address of the virtual
              vector from the target is fetched. }
            emitbyt($8b); { mov eax,[addr+2] }
            emitbyt($00+dreg(rgeax)*8+$05);
            emitadro(tp^.fncoh, itadr, 2); { output location of routine+2 }
            { get the address at the virtual vector }
            emitbyt($8b); { mov ebx,[eax] }
            emitbyt($00+dreg(rgebx)*8+$00);
            { save that in our virtual vector for "inherited" calls }
            emitbyt($89); { mov [vv],eax }
            emitbyt($00+dreg(rgebx)*8+$05);
            emitadr(tp^.fncvv, itadr); { output location of vv }
            { now place our overrider address at the vv for the target }
            emitbyt($c7); { mov [ebx],addr }
            emitbyt($00+$00*8+dreg(rgeax));
            emitadr(tp, itadr) { output address of overrider }

         end;
         tp := tp^.next { next entry }

      end;

   end;
   genlst(blk^.entry); { generate flow list }
   { if a procedure or function, it has locals, and so they must
     be deallocated }
   if (blk^.mark^.t = tproc) or (blk^.mark^.t = tfunc) then begin

      { check it is a lockable monitor routine }
      if monlock(blk^.mark) then begin

         creatlock; { make sure monitor lock exists }
         emitbyt($8b); { mov eax,[lockid] }
         emitbyt($00+dreg(rgeax)*8+$05);
         emitadr(lockid, itadr); { output location of lock id }
         genrotcal(syslib_unlock); { unlock the variables }

      end;
      { Remove any FPU parameter saves. }
      if relrtot > 0 then begin

         { make space on stack }
         emitbyt($83); { add esp,fpusct*relsiz }
         emitbyt($c0+$00*8+$04);
         emitbyt(relrtot*relsiz)

      end;
      { restore registers according to "in use" mask }
      if rgeax in usereg then emitbyt($58); { pop eax }
      if rgebx in usereg then emitbyt($5b); { pop ebx }
      if rgecx in usereg then emitbyt($59); { pop ecx }
      if rgedx in usereg then emitbyt($5a); { pop edx }
      if rgesi in usereg then emitbyt($5e); { pop esi }
      if rgedi in usereg then emitbyt($5f); { pop edi }
      { restore flags }
      emitbyt($9d); { popfd }
      if blk^.mark^.t = tfunc then begin

         if realt(blk^.mark^.fncr) then begin { floating point result }

            { Floating point results need to be loaded into the FPU stack.
              The encoding rules require that the FPU be clear at this
              point. Load from CPU stack to FPU stack. }
            if srealt(blk^.mark^.fncr) then emitbyt($d9) { flds [esp] }
            else emitbyt($dd); { fldd [esp] }
            emitbyt($04);
            emitbyt($24);
            { now adjust stack past that }
            emitbyt($83); { add esp,n }
            emitbyt($c4);
            if srealt(blk^.mark^.fncr) then emitbyt(srlsiz)
            else emitbyt(relsiz)

         end else begin { standard (32 bit) result }

            { replace eax with new function result }
            emitbyt($58); { pop eax }
            { if result is tgp, restore length to ebx }
            if tgpt(blk^.mark^.fncr^.fnrt) then
               emitbyt($58+dreg(rgebx)) { pop ebx }

         end

      end;
      { unlink frame }
      emitbyt($c9); { leave }
      {  check there is a parameter overflow region }
      if parspc <> 0 then begin { deallocate parameters }

         { get the return address }
         emitbyt($87); { xchg eax,[esp] }
         emitbyt($04);
         emitbyt($24);
         { place return under old stack }
         emitbyt($89); { mov offset-4[esp],eax }
         emitbyt($84);
         emitbyt($24);
         emitint(parspc);
         emitbyt($58); { pop eax }
         emitbyt($81); { add esp,offset-stack element }
         emitbyt($c4);
         emitint(parspc-stksiz)

      end;
      emitbyt($c3); { ret }
      gendistrp { generate disassemby trip }

   end else begin { main exit }

      if blk^.mark^.t <> tglbl then error(einvfmt); { should be global mark }
      { check block type }
      if blk^.mark^.mrkt <> mtprocess then
         begin { program, module, monitor or share }

         { check block is a monitor }
         if blk^.mark^.mrkt = mtmonitor then begin

            { unlock the monitor variables after initialization }
            creatlock; { make sure monitor lock exists }
            emitbyt($8b); { mov eax,[lockid] }
            emitbyt($00+dreg(rgeax)*8+$05);
            emitadr(lockid, itadr); { output location of lock id }
            genrotcal(syslib_unlock) { unlock the variables }

         end;
         { generate call to next module in series }
         emitbyt($e8); { call modend }
         emitadr(modend, itradr) { output address }

      end

   end

end;

{*******************************************************************************

Generate block code exit

Generates the exit block. The exit block simply needs to unlink the main frame,
and exit to the caller in module sequence.

*******************************************************************************}

procedure genblkext(blk: blkptr); { block pointer }

begin

   { check not procedure or function }
   if (blk^.mark^.t <> tproc) and (blk^.mark^.t <> tfunc) then begin

      if blk^.mark^.t <> tglbl then error(einvfmt); { should be global mark }
      if blk^.mark^.mrkt = mtprocess then begin

         emitbyt($8b); { mov eax,[threadid] }
         emitbyt($00+dreg(rgeax)*8+$05);
         emitadr(threadid, itadr); { output location of thread id }
         genrotcal(syslib_killthread); { stop this thread }
         { The killthread call should stop the thread, so soft halt if it should
           continue. }
         emitbyt($eb); { jmp _ }
         emitbyt(0)

      end else begin

         { not a process module }
         if blk^.mark^.mrkt = mtmonitor then begin

            { lock the monitor variables during finalization }
            creatlock; { make sure monitor lock exists }
            emitbyt($8b); { mov eax,[lockid] }
            emitbyt($00+dreg(rgeax)*8+$05);
            emitadr(lockid, itadr); { output location of lock id }
            genrotcal(syslib_lock) { lock the variables }

         end;
         genlst(blk^.exit); { generate flow list }
         if blk^.mark^.mrkt = mtmonitor then begin

            { unlock the monitor variables after finalization }
            creatlock; { make sure monitor lock exists }
            emitbyt($8b); { mov eax,[lockid] }
            emitbyt($00+dreg(rgeax)*8+$05);
            emitadr(lockid, itadr); { output location of lock id }
            genrotcal(syslib_unlock) { unlock the variables }

         end;
         emitbyt($c9); { leave }
         emitbyt($c3); { set return to caller }
         gendistrp { generate disassembly trip }

      end

   end

end;

{*******************************************************************************

Generate block code

Generates code for the given acyclic graph. The present traverse gives code that
appears similar to the source. For example, an if is traversed true condition
first, then the false. It may be more efficient to generate straight flows
first, then place exceptional flows after the whole routine. This is an area
for future research.
This routine generates the prolog and epilog code to blocks, then calls the
list handler to generate the contents of the block. There are several types
of blocks:

1. Global entry blocks.
2. Global exit blocks.
3. Function blocks.
4. Procedure blocks.

Each one has different types of prolog and epilog code for it. In addition, we
do a lot of customization depending on if locals appear, how many locals, if
they are to be cleared to zero, and if floating point function results appear.

Note: "lea" instructions are used to offset the stack. The reason for this is
that this uses offset address math to form the address, and that does not mess
with the flags.

*******************************************************************************}

procedure genblk;

begin

   { process entry block }
   breakdown(blkstk^.entry); { produce breakdown products }
   maktmp(blkstk^.entry); { allocate set temporaries }
   arrass(blkstk^.entry); { arrange associative operands }
   if flstreg then begin { will generate register list }

      writeln;
      write('Register allocation rules for block: [');
      blknam(blkstk); { output block name }
      writeln('] entry section');
      writeln

   end;
   regblk(blkstk^.entry, blkstk^.entreg); { perform register assignments }
   sizblk; { size any new entries }
   if blkstk^.lvl >= 3 then allloc; { allocate previous block locals }
   if flstgen then begin { will generate coding list }

      writeln;
      write('Intermediates for block: [');
      blknam(blkstk); { output block name }
      writeln('] entry section');
      writeln

   end;
   genblkent(blkstk); { generate block entry }
   if fpusct <> 0 then error(esysflt136); { FPU stack should be empty }

   { process exit block }
   breakdown(blkstk^.exit); { produce breakdown products }
   maktmp(blkstk^.exit); { allocate set temporaries }
   arrass(blkstk^.exit); { arrange associative operands }
   if flstreg then begin { will generate register list }

      writeln;
      write('Register allocation rules for block: [');
      blknam(blkstk); { output block name }
      writeln('] exit section');
      writeln

   end;
   regblk(blkstk^.exit, blkstk^.extreg); { perform register assignments }
   sizblk; { size any new entries }
   if blkstk^.lvl >= 3 then allloc; { allocate previous block locals }
   if flstgen then begin { will generate coding list }

      writeln;
      write('Intermediates for block: [');
      blknam(blkstk); { output block name }
      writeln('] exit section');
      writeln

   end;
   genblkext(blkstk); { generate block exit }
   if fpusct <> 0 then error(esysflt137) { FPU stack should be empty }

end;

{*******************************************************************************

Allocate system wide definitions

Called after the system block 0 is pushed, this routine gives the mac module
a chance to allocate global types into the system block.

*******************************************************************************}

procedure sysblk;

var tp, tp1: typptr;

begin

   gettypsys(tp1, tinteger); { get an integer to link to }

   { create round to zero constant }
   gettypsys(tp, ticst);
   tp^.ival.v := $00000f7f;
   tp^.ival.s := false;
   gettypsys(rndzero, tfix);
   rndzero^.fixt := tp1; { set base type }
   rndzero^.fixc := tp; { set constant fill }
   rndzero^.fixe := false; { set not external }
   rndzero^.fixr := true; { set fixed was referenced }

   { Create round to nearest constant }
   gettypsys(tp, ticst);
   tp^.ival.v := $0000037f;
   tp^.ival.s := false;
   gettypsys(rndnear, tfix);
   rndnear^.fixt := tp1; { set base type }
   rndnear^.fixc := tp; { set constant fill }
   rndnear^.fixe := false; { set not external }
   rndnear^.fixr := true; { set fixed was referenced }

   { create global tagged pointer }
   gettypsys(gbltgp, tptr); { get pointer }
   gettypsys(gbltgp^.ptrt, tgarry); { get general array base }
   { This leaves the definition only partially defined, but thats enough
     to size the pointer. }

end;

{*******************************************************************************

Module initialize

Performs initalizations specific to I80586.

*******************************************************************************}

begin

   {

   holding references: these symbols are held without error for various reasons

   }

   { diagnostic routines }

   refer(dmpcxt);

   { these routines are no longer used, but we are keeping them pending review }

   refer(conflg);
   refer(cpycxt);
   refer(genflg2bol);

   { sign on }

   writeln;
   write('I80386 Encoder vs. ', version_major:1, '.', version_minor:1);
   { see version.pas for explanations of the version and build numbers }
   if version_build > 0 then
      begin write('.'); writed(version_build, '0000') end;
   write(version_track xor $58748936);
   write(' Copyright (C) 2005 S. A. Moore');
   writeln;

   { initialize variables local to module }

   fcustrp := false; { don't use custom trap instructions }
   fpakvar := false; { don't pack variables }
   fm386   := true; { set to 386 by default }
   fm486   := false;
   fm586   := false;
   flibflt := false; { set to use hardware float by default }
   fspeed  := true; { set to prefer fastest code }
   frngchk := true; { set range checking on }
   farrchk := true; { set array bounds checking on }
   fovfchk := true; { set overflow checks on }
   fzdvchk := true; { set zero divide check on }
   fivochk := true; { set invalid operands check on }
   fcaschk := true; { check missing cases }
   fbndins := false; { do not use bounds instruction }
   fclrlcl := true; { clear locals that don't contain files }
   flstgen := false; { list generation intermediates }
   funrol  := true; { unroll for loops }
   fregcon := true; { reuse register contents }
   flstreg := false; { list register allocation rules }
   fdiscm  := false; { no disassembly counter measures }
   fnilptr := true; { check for nil pointer dereference }
   ffputrp := true; { trap FPU exceptions in code }
   ftagchk := true; { check tagged record field accesses }
   flstara := false; { do not list associative arrangement tracking }
   flsttmp := false; { do not list temp tracking }
   rolnum  := 4; { standard unroll count }
   forlen  := 25; { threshold of unroll for for loops, in intermediate count }
   wthvar  := nil; { set no 'with' var active }
   bndlst  := nil; { clear bounds descriptor list }
   bnddes  := nil; { clear the bounds base type }
   fpusct  := 0; { clear the FPU stacking depth }
   gbltgp  := nil; { clear global tagged pointer }
   genind  := 0; { clear generation list indent }
   curage  := 0; { clear context age }
   rndseq  := 314159; { set inital to mid sequence }
   threadid := nil;  { clear thread id variable }
   lockid   := nil; { clear monitor lock id variable pointer }

   for r := rgnull to rgflg do with regtrk[r] do begin

      con := nil; { clear contents for this register }
      age := 0 { clear age counter }

   end;

   { these are set up in the system block, but cleared here }
   rndnear := nil; { round to nearest control word constant }
   rndzero := nil; { round to zero control word constant }

end.
