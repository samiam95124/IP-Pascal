{*******************************************************************************
*                                                                              *
*                             C PARSER PROGRAM                                 *
*                                                                              *
*                        Copyright (C) 2003  S. A. Moore                       *
*                                                                              *
* Parses and validates a C program, building a type, symbol and macro table.   *
* Then the contents of these tables are used to output a header file in        *
* Pascal.                                                                      *
* This program originated with the C parser.                                   *
*                                                                              *
*******************************************************************************}

program ch2ph(output);

uses extlib,
     parlib, { command line parsing }
     macro,  { macro level }
     symbol, { symbol processing }
     parser; { C parser }

label terminate_program; { end program run }

procedure terminate; forward;

private

const filmax = 1000; { number of characters in a filename }
      labmax = 250;  { label maximum }
      cmdmax = 250;  { maximum length of command string for actions }
      eldmax = 16;   { maximum elide for any function }

type  filinx = 1..filmax; { index for filename }
      filnam = packed array [filinx] of char; { a filename }
      labinx = 1..labmax; { index for label }
      labl   = packed array [labinx] of char; { label }

var   srcnam:  filnam;  { filename holder }
      outnam:  filnam;  { module name holder }
      insnam:  filnam;  { instruction name holder }
      p, n, e: filnam;  { filename components }
      w:       labl;    { word to work with }
      cmdhan:  parhan;  { handle for command parsing }
      err:     boolean; { error holder }
      valfch:  chrset;  { valid file characters }
      hdrnam:  filnam;  { name of header file }
      hdrfil:  text;    { header output file }
      inst:    integer; { name table instance number, ignored }
      asmnam:  filnam;  { name of assembly file }
      asmfil:  text;    { assembly output file }

{*******************************************************************************

Terminate program

Halts program after error.             

*******************************************************************************}

procedure terminate;

begin

   goto terminate_program

end;

{*******************************************************************************
             
Parse options

Any number of <option> forms are parsed.

*******************************************************************************}

procedure paropt;

var err:    boolean; { error flag }
    optfnd: boolean; { option found }

{ set true/false flag }

procedure setflg(view a, n: string; var f: boolean);

var ts: packed array [1..40] of char; { string holder }

begin

   if compp(w, n) or compp(w, a) then begin

      f := true; { perform true }
      optfnd := true { set option found }

   end else begin { try false cases }

      copy(ts, 'n'); { form negative }
      cat(ts, n);
      if compp(w, ts) then begin

         f := false; { perform false }
         optfnd := true { set option found }

      end else begin

         copy(ts, 'n'); { form negative }
         cat(ts, a);
         if compp(w, ts) then begin

            f := false; { perform false }
            optfnd := true { set option found }

         end

      end

   end

end;
   
begin

   skpspc(cmdhan); { skip spaces }
   while chkchr(cmdhan) = optchr do begin { parse options }

      optfnd := false; { set no option found }
      getchr(cmdhan); { skip option character }
      parlab(cmdhan, w, err); { parse option label }
      if err then error(einvopt, ''); { invalid option }
      setflg('ls',  'listsymbols',       fsym); { list symbols }
      setflg('lt',  'listtypes',         ftype); { list types }
      setflg('ltk', 'listtolkens',       fprttlk); { list tolkens }
      setflg('lpr', 'listparserule',     fprtrle); { list parsing rules }
      setflg('ll',  'listline',          fprtlin); { list raw lines incoming }
      setflg('lme', 'listmacroexpand',   fprtexp); { list macro expansions }
      setflg('lm',  'listmacro',         fprtmac); { list macro expansions }
      setflg('ld',  'listdefines',       fprtdef); { list definition table }
      { list lines after macro process }
      setflg('lpl', 'listprocessedline', fprtpln);
      { allow non-standard unnamed struct/union element }
      setflg('use', 'unnamedstructelement', fuse);
      setflg('cpc', 'cppcomment',        fcppcmt); { allow C++ comments }
      setflg('msa', 'msasm',             fmsasm);  { allow ms asm constructs }
      setflg('ec',  'enumcomma',         fenecma); { allow extra enum comma }
      setflg('td',  'typeduplication',   fduptyp); { allow type duplication }
      setflg('pv',  'pointervar',   fptrvar); { convert anon pointers to var }
      { convert constant character pointers to string }
      setflg('cps', 'constcharptrtstring', fccpstr);
      { convert character pointers to string }
      setflg('cs', 'charptrtstring', fchpstr);
      if not optfnd then begin { option not found }

         if compp(w, 'outnam') or compp(w, 'on') then begin { module name set }

            skpspc(cmdhan); { skip spaces }
            if chkchr(cmdhan) <> '=' then error(easexp, ''); { '=' expected }
            getchr(cmdhan); { skip }
            parlab(cmdhan, outnam, err); { parse module name }
            if err then error(einvmod, '') { invalid module name }
            
         end else error(eoptnf, '') { option not found }

      end;
      skpspc(cmdhan) { skip spaces }

   end

end;

{*******************************************************************************

Parse and load instruction file

Parses and loads a list of instructions from the instruction file. The format
of the instruction file is:

! comment

command param param...param

The instruction file has two modes. It is run twice, once at the start of the
program, and another time after the complete C input is parsed. An input flag
sets which invocation is being executed. At the start of program invocation, 
only flag setting and other general actions are executed. In the second
invocation, all instructions are executed, including those which immediately
act on the gathered C program data.

Implemented instructions

pointervar           
==========

Turns pointer parameters to var parameters whenever possible.
It is based on the idea that the reference interpretation of pointers will be
true more often than not. Pointers to void, and pointers to functions are left
unchanged. Also, there must be a non-generated label for the subtype.

The reason that even const type parameters get a var type is that var is the
only way to force a reference parameter in Pascal. View is understood to be
optional as to how it gets passed.

Because pointervar touches every pointer parameter, it is overridden by  the
character pointer instructions.

constcharptrstring   
==================

Change constant character pointer parameters to view strings.

charptrstring
=============

Change character pointer parameters to var strings.

remove symbol
=============

Remove symbol from both .pas file and .asm file.

removestruct symbol
===================

Same, but for structures (because of different symbols space).

removeasm symbol
================

Remove symbol from .asm file only.

chparam symbol num pas asm
==========================

remove and replace function parameter by symbol. Num indicates parameter by
number, 1-n, pas gives string to replace .pas parameter, asm gives string
to replace .asm parameter with, both in quotes. If the string is empty, it
means to skip outputting that parameter to that file type. One or both
parameter file types can be omitted this way.

If the parameter number is zero, then the result is indicated.

clone symbol newsym
===================

Creates a new function (presently functions only) with a full separate parameter
list so that it can be marked and modified. Newsym contains the new name. Note
that it will appear in both .pas and .asm files unless otherwise specified.

chparamtyp symbol pas asm
=========================

Change parameter types. When any parameter of symbol type is found, it is
replaced by the strings indicated.

chrestyp symbol pas asm
=======================

As chparamtyp, but works on function results.

elideparam symbol num asm
=======================

Remove parameter as default. Causes another copy of the procedure or function to
be output as an overload, with the indicated parameter removed. The Pascal
source parameter is removed completely. The assembly file has the the given
string substituted. This is usually the code that will indicate the parameter is
missing, typically zer.

If more than one parameter is indicated in a procedure or function, then all the
combinations of missing parameters are iterated, which can result in a large
number of different function/procedure headers output. I.e., this is a dangerous
function.

The number of total copies is limited to 16

*******************************************************************************}

procedure parinst(view ifn: string; action: boolean);

label nextline; { go to next line }

var inshan:    parhan;  { handle for instruction parsing }
    cmd:       labl;    { command word }
    par, par1: labl;    { parameters }
    err:       boolean; { parsing error }
    sp, sp1:   symptr;  { symbol pointer }
    parn:      integer; { parameter number }
    pas:       labl;    { .pas parameter string }
    asm:       labl;    { .asm parameter string }
    ppas:      pstring; { storage pointers for those }
    pasm:      pstring;
    pp:        typptr;  { parameter pointer }

procedure inserr(view es: string);

begin

   prterr(inshan, output, es, true); { print error }
   getlin(inshan); { skip to new line }
   goto nextline

end;

{ skip rest of line }

procedure skplin;

begin

   while not endlin(inshan) do getchr(inshan)   

end;

begin

   writeln('Reading instruction file');
   openpar(inshan); { open parser }
   openfil(inshan, ifn, cmdmax); { open file to parse }

   nextline: { start new line }

   while not endfil(inshan) do begin { process instructions }
   
      skpspc(inshan); { skip leading spaces }
      if chkchr(inshan) = '!' then { skip comment line }
         while not endlin(inshan) do getchr(inshan)
      else if not endlin(inshan) then begin { command line }

         parlab(inshan, cmd, err); { get command word }
         if err then inserr('Invalid command');

         { check static flag set commands }

         { allow non-standard unnamed struct/union element }
         if compp(cmd, 'unnamedstructelement') then fuse := true
         { allow C++ comments }
         else if compp(cmd, 'cppcomment') then fcppcmt := true
         { allow ms asm constructs }
         else if compp(cmd, 'msasm') then fmsasm := true
         { allow extra enum comma }
         else if compp(cmd, 'enumcomma') then fenecma := true
         { allow type duplication }
         else if compp(cmd, 'typeduplication') then fduptyp := true
         { set anonymous pointer parameters become var parameters }
         else if compp(cmd, 'pointervar') then fptrvar := true
         { set constant character pointer parameters become view strings }
         else if compp(cmd, 'constcharptrstring') then fccpstr := true
         { set character pointer parameters become var strings }
         else if compp(cmd, 'charptrstring') then fchpstr := true
         else if compp(cmd, 'remove') then begin

            if action then begin { run command }

               parlab(inshan, par, err); { get parameter }
               if err then inserr('Invalid target symbol');
               sp := gblsym(par, false); { look up }
               if sp = nil then inserr('Symbol not found');
               sp^.rem := true; { set remove }
               if sp^.typ <> nil then sp^.typ^.rem := true

            end else skplin { skip rest of line }

         end else if compp(cmd, 'removestruct') then begin

            if action then begin { run command }

               parlab(inshan, par, err); { get parameter }
               if err then inserr('Invalid target symbol');
               sp := gblsym(par, true); { look up }
               if sp = nil then inserr('Symbol not found');
               sp^.rem := true; { set remove }
               if sp^.typ <> nil then sp^.typ^.rem := true

            end else skplin { skip rest of line }

         end else if compp(cmd, 'removeasm') then begin

            if action then begin { run command }

               parlab(inshan, par, err); { get parameter }
               if err then inserr('Invalid target symbol');
               sp := gblsym(par, false); { look up }
               if sp = nil then inserr('Symbol not found');
               sp^.rma := true; { set remove }
               if sp^.typ <> nil then sp^.typ^.rma := true

            end else skplin { skip rest of line }

         end else if compp(cmd, 'chparam') then begin

            if action then begin { run command }

               parlab(inshan, par, err); { get parameter }
               if err then inserr('Invalid target symbol');
               parnum(inshan, parn, 10, err); { get parameter number }
               if err then inserr('Invalid parameter number');
               parstr(inshan, pas, err); { get .pas side string }
               if err then inserr('Invalid .pas string');
               parstr(inshan, asm, err); { get .asm side string }
               if err then inserr('Invalid .asm string');
               sp := gblsym(par, false); { look up }
               if sp = nil then inserr('Symbol not found');
               if sp^.typ = nil then inserr('Symbol has no type');
               if sp^.typ^.t <> tfunc then inserr('Symbol must be function');
               if not (tfextern in sp^.typ^.tfs) then 
                  inserr('Function must be external');
               if parn = 0 then begin { replace result type }
             
                  copyp(sp^.typ^.fncrps, pas); { place strings }
                  copyp(sp^.typ^.fncras, asm)
             
               end else begin { replace parameter }
             
                  pp := sp^.typ^.fncp; { index parameter list }
                  { find parameter by number }
                  while (pp <> nil) and (parn > 1) do begin
             
                     pp := pp^.parn; { next parameter }
                     parn := parn-1
             
                  end;
                  if parn > 1 then inserr('No parameter by that number');
                  copyp(pp^.parps, pas); { place strings }
                  copyp(pp^.paras, asm)

               end

            end else skplin { skip rest of line }

         end else if compp(cmd, 'chparamtyp') then begin

            if action then begin { run command }

               parlab(inshan, par, err); { get symbol }
               if err then inserr('Invalid target symbol');
               parstr(inshan, pas, err); { get .pas side string }
               if err then inserr('Invalid .pas string');
               parstr(inshan, asm, err); { get .asm side string }
               if err then inserr('Invalid .asm string');
               sp := gblsym(par, false); { look up }
               if sp = nil then begin
             
                  sp := gblsym(par, true); { look up as structure }
                  if sp = nil then inserr('Symbol not found')
             
               end;
               if sp^.typ = nil then inserr('Symbol has no type');
               if not (sp^.typ^.t in [tvoid, tint, tfloat, tptr, tenum, tarray,
                                      tstruct, tunion, tfunc]) then
                  inserr('Symbol is not type');
               copyp(ppas, pas); { place strings }
               copyp(pasm, asm);
               setparrep(sp, ppas, pasm) { perform substitution }

            end else skplin { skip rest of line }

         end else if compp(cmd, 'chrestyp') then begin

            if action then begin { run command }

               parlab(inshan, par, err); { get symbol }
               if err then inserr('Invalid target symbol');
               parstr(inshan, pas, err); { get .pas side string }
               if err then inserr('Invalid .pas string');
               parstr(inshan, asm, err); { get .asm side string }
               if err then inserr('Invalid .asm string');
               sp := gblsym(par, false); { look up }
               if sp = nil then begin
             
                  sp := gblsym(par, true); { look up as structure }
                  if sp = nil then inserr('Symbol not found')
             
               end;
               if sp^.typ = nil then inserr('Symbol has no type');
               if not (sp^.typ^.t in [tvoid, tint, tfloat, tptr, tenum, tarray,
                                      tstruct, tunion, tfunc]) then
                  inserr('Symbol is not type');
               copyp(ppas, pas); { place strings }
               copyp(pasm, asm);
               setresrep(sp, ppas, pasm) { perform substitution }

            end else skplin { skip rest of line }

         end else if compp(cmd, 'clone') then begin

            if action then begin { run command }

               parlab(inshan, par, err); { get symbol }
               if err then inserr('Invalid source symbol');
               parlab(inshan, par1, err); { get symbol }
               if err then inserr('Invalid destination symbol');
               sp := gblsym(par, false); { look up }
               if sp = nil then inserr('Symbol not found');
               if sp^.typ = nil then inserr('Symbol has no type');
               if sp^.typ^.t <> tfunc then inserr('Symbol must be function');
               if not (tfextern in sp^.typ^.tfs) then 
                  inserr('Function must be external');
               sp1 := gblsym(par1, false); { look for duplicate }
               if sp1 <> nil then inserr('Destination already exists');
               getsym(sp1); { get a symbol entry }
               copyp(sp1^.lab, par1); { place symbol }
               newsym(sp1, false); { place in symbol table }
               clonefunc(sp^.typ, sp1) { perform function clone }

            end else skplin { skip rest of line }

         end else if compp(cmd, 'elideparam') then begin

            if action then begin { run command }

               parlab(inshan, par, err); { get parameter }
               if err then inserr('Invalid target symbol');
               parnum(inshan, parn, 10, err); { get parameter number }
               if err then inserr('Invalid parameter number');
               parstr(inshan, asm, err); { get .asm side string }
               if err then inserr('Invalid .asm string');
               sp := gblsym(par, false); { look up }
               if sp = nil then inserr('Symbol not found');
               if sp^.typ = nil then inserr('Symbol has no type');
               if sp^.typ^.t <> tfunc then inserr('Symbol must be function');
               if not (tfextern in sp^.typ^.tfs) then 
                  inserr('Function must be external');
               if eldcnt(sp^.typ) >= eldmax then inserr('Maximum elide count exceeded');
               pp := sp^.typ^.fncp; { index parameter list }
               { find parameter by number }
               while (pp <> nil) and (parn > 1) do begin
             
                  pp := pp^.parn; { next parameter }
                  parn := parn-1
             
               end;
               if parn > 1 then inserr('No parameter by that number');
               pp^.pareld := true; { set parameter can be elided }
               copyp(pp^.pareas, asm) { place string }

            end else skplin { skip rest of line }

         end else inserr('No such instruction');
         skpspc(inshan); { skip trailing spaces }
         if chkchr(inshan) = '!' then { skip comment line }
            while not endlin(inshan) do getchr(inshan);
         if not endlin(inshan) then inserr('Invalid command')
         
      end;
      getlin(inshan) { skip to new line }

   end

end;

{*******************************************************************************

Parse and load catalog file

Parses and loads the catalog file. The catalog file is allways "catalog", and
has the format:

WBTRV32 WBTRVINIT

The first line item is the module name, as in WBTRV32.dll. The second is the 
export name. The module gives the dll file that contains the export, and will
be used to coin the reference so that it can be attached to the correct
module.

Note: we pretty much expect the module names to appear in sequence. We keep
a module name in storage that is used to label all entries, and that is only
changed when the module name changes in the file. If the module names were
all mixed up, many duplicate module names would be created.

*******************************************************************************}

procedure parcat;

label nextline; { go to next line }

var cathan:    parhan;  { handle for instruction parsing }
    modl, exp: labl;    { labels to parse }
    err:       boolean; { parsing error }
    mn:        pstring; { running module name }
    dupcnt:    integer; { duplicate counter }
    cfn:       filnam;  { catalog file name }
    pth:       filnam;  { search path }

procedure caterr(view es: string);

begin

   prterr(cathan, output, es, true); { print error }
   getlin(cathan); { skip to new line }
   goto nextline

end;
   
begin

   mn := nil; { clear module name }
   dupcnt := 0; { clear duplicate count }
   copy(cfn, 'catalog'); { set catalog name }
   if not exists(cfn) then begin { search paths for it }
   
      getusr(pth); { get the user path }
      maknam(cfn, pth, 'catalog', ''); { create name }
      if not exists(cfn) then begin { search the program path }

         getpgm(pth); { get the program path }
         maknam(cfn, pth, 'catalog', ''); { create name }
         if not exists(cfn) then error(ecatnf, '');

      end

   end;
   writeln('Reading catalog file');
   openpar(cathan); { open parser }
   openfil(cathan, cfn, cmdmax); { open file to parse }

   nextline: { start new line }

   while not endfil(cathan) do begin { process instructions }
   
      skpspc(cathan); { skip leading spaces }
      if chkchr(cathan) = '!' then { skip comment line }
         while not endlin(cathan) do getchr(cathan)
      else if not endlin(cathan) then begin { command line }

         parfil(cathan, modl, true, err); { get module name }
         if err then caterr('Invalid catalog syntax');
         parlab(cathan, exp, err); { get export name }
         if err then caterr('Invalid catalog syntax');
         if mn = nil then copyp(mn, modl) { create a new module name }
         { also create one if the names don't match }
         else if not compp(mn^, modl) then copyp(mn, modl);
         newmod(exp, mn, dupcnt); { create new module name }
         skpspc(cathan); { skip trailing spaces }
         if chkchr(cathan) = '!' then { skip comment line }
            while not endlin(cathan) do getchr(cathan);
         if not endlin(cathan) then caterr('Invalid catalog symtax')
         
      end;
      getlin(cathan) { skip to new line }

   end;
   if dupcnt > 0 then
      writeln('Catalog file contains ', dupcnt:1, ' duplicate exports')

end;

begin

   writeln;
   writeln('C header to Pascal header converter vs. 0.1 Copyright (C) S. A. Moore');
   writeln;
   clears(outnam); { clear module name }
   openpar(cmdhan); { open parser }
   openfil(cmdhan, '_command', cmdmax); { open command line level }
   filchr(valfch); { get the filename valid characters }
   valfch := valfch-['=']; { remove parsing characters }
   setfch(cmdhan, valfch); { set that for active parsing }
   paropt; { parse command options }
   if endlin(cmdhan) then error(efilexp, ''); { no filename }
   parfil(cmdhan, srcnam, false, err); { parse filename }
   if err then error(einvfil, ''); { invalid filename }
   paropt; { parse command options }
   brknam(srcnam, p, n, e); { break down name }
   { if no module name is set, place name as that of source file primary }
   if len(outnam) = 0 then copy(outnam, n);
   { if there is no extention, place .c }
   if e[1] = ' ' then copy(e, 'c');
   maknam(srcnam, p, n, e); { recreate }
   if not exists(srcnam) then begin { try .h }

      copy(e, 'h');
      maknam(srcnam, p, n, e); { recreate }
      if not exists(srcnam) then error(efilnf, '') { no file }

   end;

   { read and process the instruction file if it exists }

   copy(e, 'ins'); { create instruction file name from source name }
   maknam(insnam, p, n, e);
   if exists(insnam) then parinst(insnam, false); { process the file }

   { parse C input files }

   write('Parsing file: ');
   write(output, srcnam:0);
   writeln;
   writeln;
   opnsrc(srcnam); { open source file }
   gettlk; { get 1st tolken }
   partrans; { parse C file }

   writeln('Preparing internal data');
   { enter Pascal tolkens as the primary instances in the caseless name table }
   newnam('div',       inst);
   newnam('mod',       inst);
   newnam('nil',       inst);
   newnam('in',        inst);
   newnam('or',        inst);
   newnam('and',       inst);
   newnam('xor',       inst);
   newnam('not',       inst);
   newnam('if',        inst);
   newnam('then',      inst);
   newnam('else',      inst);
   newnam('case',      inst);
   newnam('of',        inst);
   newnam('repeat',    inst);
   newnam('until',     inst);
   newnam('while',     inst);
   newnam('do',        inst);
   newnam('for',       inst);
   newnam('to',        inst);
   newnam('downto',    inst);
   newnam('begin',     inst);
   newnam('end',       inst);
   newnam('with',      inst);
   newnam('goto',      inst);
   newnam('const',     inst);
   newnam('var',       inst);
   newnam('type',      inst);
   newnam('array',     inst);
   newnam('record',    inst);
   newnam('set',       inst);
   newnam('file',      inst);
   newnam('function',  inst);
   newnam('procedure', inst);
   newnam('label',     inst);
   newnam('packed',    inst);
   newnam('program',   inst);
   newnam('forward',   inst);
   newnam('module',    inst);
   newnam('uses',      inst);
   newnam('private',   inst);
   newnam('external',  inst);
   newnam('view',      inst);
   newnam('fixed',     inst);
   newnam('process',   inst);
   newnam('monitor',   inst);
   newnam('share',     inst);
   newnam('class',     inst);
   newnam('construct', inst);
   newnam('destruct',  inst);
   newnam('is',        inst);
   newnam('atom',      inst);

   writeln('Finding macro equivalences');
   caldefs; { calculate macro equivalence values }
   writeln('Sorting defines');
   srtdef; { sort the defines }
   writeln('Finding aliases');
   macalias;
   writeln('Linking types to names');
   namtyp; { place symbol names on types }
   writeln('Registering defines');
   regdef; { register the defines }
   writeln('Outputing definitions table');
   prtdef; { print definitions table }
   writeln('Registering symbols');
   regsym; { register the symbols as caselsss/keywords }
   writeln('Performing incomplete types check');
   chktypes; { perform incomplete typing check }
   writeln('Coining anonymous types');
   cointypes; { perform coining on anonymous types }

   { read and process the instruction file if it exists }

   copy(e, 'ins'); { create instruction file name from source name }
   maknam(insnam, p, n, e);
   if exists(insnam) then parinst(insnam, true); { process the file }
  
   { read and process the catalog file }

   parcat; { process the file }

   { Alphabetize symbols for the output. Everything gets alphabetized, and
     is so output. The only exception is types, which are order dependent.
     These are output "alpha - order", that is, they are output in alpha
     ordering, but will have sections that are output out of order because
     of dependencies. }

   alphasym; { rip and form alpha list }

   { perform header output phase }

   copy(e, 'pas');
   maknam(hdrnam, p, outnam, e); { recreate }
   write('Generating file: ');
   write(output, hdrnam:0);
   writeln;
   if exists(hdrnam) then delete(hdrnam); { if already there, delete it }
   assign(hdrfil, hdrnam); { open that }
   rewrite(hdrfil);
   writeln(hdrfil, '{*****************************************************',
                   '**************************');
   writeln(hdrfil);
   write(hdrfil, 'IP Pascal header file translated from ');
   write(hdrfil, srcnam:0);
   writeln(hdrfil);
   writeln(hdrfil);
   writeln(hdrfil, '*** WARNING ***');
   writeln(hdrfil);
   writeln(hdrfil, 'This file is automatically generated by ch2ph. Do not ',
                   'edit this file');
   writeln(hdrfil);
   writeln(hdrfil, '******************************************************',
                   '*************************}');
   writeln(hdrfil);
   write(hdrfil, 'module ');
   write(hdrfil, outnam:0);
   writeln(hdrfil, ';');
   writeln(hdrfil);
   writeln(hdrfil, 'uses stddef,');
   writeln(hdrfil, '     spcdef;');
   writeln(hdrfil);
   hdrdef(hdrfil); { output }
   writeln('Outputting coined defines report');
   coindef(hdrfil); { output coined defines report }
   writeln('Outputting unresolvable defines report');
   outparmac(hdrfil); { output parametizable macros report }
   unrdef(hdrfil); { output unresolvable defines report }
   { write standard C type anchors }
   writeln(hdrfil, '{ Standard C type equivalences }');
   writeln(hdrfil);
   writeln(hdrfil, 'type');
   writeln(hdrfil);
   writeln(hdrfil, 'sc_c_lang_float = sreal;');
   writeln(hdrfil, 'sc_c_lang_double = real;');
   writeln(hdrfil, 'sc_c_lang_long_double = real;');
   writeln(hdrfil, 'sc_c_lang_char = char;');
   writeln(hdrfil, 'sc_c_lang_signed_char = char;');
   writeln(hdrfil, 'sc_c_lang_unsigned_char = 0..255;');
   writeln(hdrfil, 'sc_c_lang_int = integer;');
   writeln(hdrfil, 'sc_c_lang_signed_int = integer;');
   writeln(hdrfil, 'sc_c_lang_unsigned_int = integer;');
   writeln(hdrfil, 'sc_c_lang_short_int = -32768..32767;');
   writeln(hdrfil, 'sc_c_lang_long_int = integer;');
   writeln(hdrfil, 'sc_c_lang_signed_short_int = -32768..32767;');
   writeln(hdrfil, 'sc_c_lang_signed_long_int = integer;');
   writeln(hdrfil, 'sc_c_lang_unsigned_short_int = 0..65535;');
   writeln(hdrfil, 'sc_c_lang_unsigned_long_int = integer;');
   writeln(hdrfil);
   writeln(hdrfil, '{ The types function and void are both unrepresentable }');
   writeln(hdrfil, '{ in Pascal, so they become integers. The options are: }');
   writeln(hdrfil);
   writeln(hdrfil, '{ 1. Change them with a instruction file rule.         }');
   writeln(hdrfil, '{ 2. Use an assembly escape routine that can actually  }');
   writeln(hdrfil, '{ make them integers.                                  }');
   writeln(hdrfil, '{ 3. Find them and change them manually.               }');
   writeln(hdrfil);
   writeln(hdrfil, 'sc_c_lang_function = integer;');
   writeln(hdrfil, 'sc_c_lang_void = integer;');
   writeln(hdrfil);
   writeln('Outputting enums');
   outenums(hdrfil); { output enums }
   writeln('Outputting types');
   outtypes(hdrfil); { output types }
   writeln('Outputting function/procedure definitions');
   outfuncs(hdrfil); { output functions }
   writeln(hdrfil, 'begin');
   writeln(hdrfil, 'end.');
   writeln('Outputting symbol coining report');
   repcsym(hdrfil);
   close(hdrfil); { close output }

   { perform assembly output phase }

   copy(e, 'asm');
   maknam(asmnam, p, outnam, e); { recreate }
   write('Generating file: ');
   write(output, asmnam:0);
   writeln;
   if exists(asmnam) then delete(asmnam); { if already there, delete it }
   assign(asmfil, asmnam); { open that }
   rewrite(asmfil);
   writeln(asmfil, '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!',
                   '!!!!!!!!!!!!!!!!!!!!!!!!!!');
   writeln(asmfil, '!');
   write(asmfil, '! Assembler function/procedure macro file, translated from ');
   write(asmfil, srcnam:0);
   writeln(asmfil);
   writeln(asmfil, '!');
   writeln(asmfil, '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!',
                   '!!!!!!!!!!!!!!!!!!!!!!!!!!');
   writeln(asmfil);
   writeln(asmfil, outnam:0, '_start:');
   writeln(asmfil);
   writeln(asmfil);
   writeln(asmfil, '   include ptocmac');
   writeln(asmfil);
   outasms(asmfil); { output assmbly file }
   writeln('Outputting referenced duplicated export symbol report');
   repdexp(asmfil);
   writeln('Outputting undefined export symbol report');
   repuexp(asmfil);
   writeln(asmfil);
   writeln(asmfil, outnam:0, '_end:');
   close(asmfil); { close output }

   writeln;
   writeln('Function complete');

   terminate_program: { error bailout }

end.
