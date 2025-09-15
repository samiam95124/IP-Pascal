{*******************************************************************************
*                                                                              *
*                               MAIN MODULE                                    *
*                                                                              *
*                             9/89 S. A. Moore                                 *
*                                                                              *
* Main module for Pascal parser. Signs on, initalizes most variables, tables,  *
* and other global information in the parser. Parses the options from the      *
* command line, then forms a list of source files to process. The files in     *
* The list are then compiled, and we terminate.                                *
*                                                                              *
*******************************************************************************}

program parse(output);

uses strlib,   { string handling }
     extlib,   { os extentions }
     xltlib,   { transliteration }
     demo,     { demo setup }
     parsedef, { parser definitions }
     common,   { common variables }
     parsesvs, { support routines }
     scanner,  { scanner }
     symbol,   { symbols manager }
     parser;   { parser }

label 99; { abort parser }

var

   fn:           filnam;
   ci:           chrinx;
   li:           labinx;
   fi:           filinx;
   sp:           symptr; { pointer to symbol }
   bsp:          symptr; { pointer to system block label }
   btp:          typptr; { pointer to system block marker }
   ti:           types;  { index for types entry table }
   tp, tp1, tp2: typptr; { type entry pointer }
   ofn:          filnam; { output filename save }
   pi:           1..usemax; { index for uses path }
   sfc:          integer; { source file counter }
   tmpfil:       filnam; { filename holder }
   mp:           modptr; { module entry pointer }
   mlp:          mltptr; { module list entry pointer }
   i:            integer;
   ki:           tolken;
   ri, ri2, rf:  0..resmax; { indexs for reserved table }

{ abort compilation vector }

procedure abort; 

begin 

   goto 99 { terminate program } 

end;

begin

   writeln('Pascal parser vs. 1.14.0001 Copyright (C) 2005 S. A. Moore');

   { set expression begin tolkens }
   exprset := [cplus, cminus, cinteger, cidentifier, clparen, cnot, 
               clbrkt];
   { set statement begin tolkens }
   statset := [cidentifier, cbegin, cif, ccase, cwhile, crepeat, cfor,
               cwith, cgoto, cinteger]; 
   { just as statement, but less ambiguous. This is used for most likely
     set error recovery }
   statuset := [cbegin, cif, ccase, cwhile, crepeat, cfor,
               cwith, cgoto, ctry, cbcms { missing the head identifier}];
   { unambigous and complete constant begin tolkens }
   constset := [cplus, cminus, cidentifier, cinteger, creal, cstring];
   { unambigous and complete ordinal type tolkens }
   ordset := [cidentifier, clparen]+constset;
   { unambigous and complete type begin tolkens }
   typeset := [cpacked, carray, cfile, cset, crecord, creference, ccmf, 
               cidentifier]+ordset+constset;
   { unambigous and complete declaration begin tolkens }
   decset := [clabel, cconst, ctype, cvar, cprocedure, cfunction]; 
   { unambigous and complete block begin tolkens }
   blockset := [cbegin, cprivate]+decset;

   { set defaults for changeable flags }

   fverb   := true;  { default verbose }
   fansi   := false; { default to non-ansi }
   ftolken := false; { don't output tolkens }
   flist   := false; { don't output source lines }
   fparse  := false; { don't output parsing rules }
   ferrsup := false; { no parser error suppress in force }
   fsym    := false; { no print symbols }
   fref    := true;  { complain about never referenced symbols }
   ffncrs  := true;  { check functions are assigned results }
   ftype   := false; { no print types table }
   fnovf   := false; { don't bypass overflow checks }
   fllct   := true; { output line count }
   fllvl   := true; { output block level count }
   flslv   := true; { output statement level count }
   flsymt  := true; { output symbol entry telemetry }
   fltypt  := true; { output type entry telemetry }
   fltlk   := true; { output tolken count }
   fllst   := true; { output line status }
   frecir  := true; { enable used memory recirculation }
   fass    := true; { enable assignment checks }
   frange  := true; { enable range checks }
   fsyslab := false; { disable system identifiers (labels starting with "_") }

   { set unchangeable flags }

   fsupp   := true;  { supress output }
   ferrf   := false; { output error file }
   ferro   := false; { error output file open }
   fsrc    := false; { source line not present }
   fintopn := false; { output intermediate file not open }

   srcusd  := nil; { clear used open file entries list }
   fllfre  := nil; { clear free file lists entry list }
   fllstk  := nil; { clear file lists stack }
   symfre  := nil; { clear free symbols list }
   blkstk  := nil; { clear types list }
   blkfre  := nil; { clear free types list stack }
   casfre  := nil; { clear free case values }
   winfre  := nil; { clear free winnow list }
   gtofre  := nil; { clear free goto list }
   curprc  := nil; { set no procedure/function current }
   gblinp  := nil; { set no 'input' file }
   gblins  := nil;
   gblout  := nil; { set no 'output' file }
   gblots  := nil;
   modlst  := nil; { clear modules list }
   uselst  := nil; { clear uses list }
   joinlst := nil; { clear joins list }
   mltfre  := nil; { free module listing entries root }
   curcls  := nil; { current class type, if one exists }
   wthfre  := nil; { clear free 'with' entries }
   wthlst  := nil; { clear 'with' tracking list }
   gblestr := nil; { clear global empty string type (for asserts) }

   errcnt  := 0; { clear errors count }
   errlim  := maxint; { set maximum errors allowed }
   level   := 0; { clear scope nest count }
   sequen  := 0; { clear scope sequence count }
   curseq  := 0; { set current scope sequence }
   typlvl  := 0; { clear type nest count }
   stalvl  := 0; { clear statement nesting level }
   wthlvl  := 0; { clear 'with' statement nesting level }
   scncmt  := false; { scanner not in comment }
   scnskp  := false; { scanner not in skip }
   symact  := 0; { clear active symbols count }
   symfct  := 0; { clear free symbols count }
   symcct  := 0; { clear created symbols count }
   tlkcnt  := 0; { clear tolken count }
   typact  := 0; { clear active type entries count }
   typfct  := 0; { clear free type entries count }
   typcct  := 0; { clear types created count }
   casact  := 0; { clear active case value count }
   casfct  := 0; { clear free case value count }
   cascct  := 0; { clear created case value count }
   winact  := 0; { clear active winnow count }
   winfct  := 0; { clear free winnow count }
   wincct  := 0; { clear created winnow count }
   gtoact  := 0; { clear active goto count }
   gtofct  := 0; { clear free goto count }
   gtocct  := 0; { clear created goto count }
   export  := false; { set not in export zone }
   concon  := 0; { set not in constant conditional zone }
   uselvl  := 0; { set no uses active (level 0) }
   modhead := cundefined; { set module type }
   modcnt  := 0; { clear module ordinal }
   langmsg := lang_english; { set english messages }
   langkey := lang_english; { set english language keywords }
   privat  := false; { set in public declaration section }

   { Determine the number of bits and bytes in an integer, not including the
     sign }
   i := maxint; { set 1st bit }
   bits := 0;
   while i <> 0 do begin i := i div 2; bits := bits + 1 end;
   bytes := bits div 8; { set bytes in integer }
   if (bits mod 8) <> 0 then bytes := bytes + 1; { round up }
   digits := bytes*2; { set number of hex digits in integer }
   { precalculate the top byte power, or the maximum $01 byte that an
     integer can hold. Used for integer to byte output convertions,
     we save time by precalculating it }
   toppow := 1; { find top power }
   for i := 1 to bytes-1 do toppow := toppow * 256;
   { find top decimal power }
   i := 0; { clear digit count }
   decpow := maxint; { set maximum digit }
   while decpow > 0 do begin

      decpow := decpow div 10; { next digit }
      i := i+1

   end;
   { now reverse it }
   decpow := 1;
   while i > 1 do begin

      decpow := decpow*10;
      i := i-1

   end;

   { begin parser }
   
   filchr(valfch); { get the filename valid characters }
   valfch := valfch-['=']; { remove parsing characters }
   copy(tmpfil, usestr); { decode the uses path string }
   getenv(tmpfil, usepth); { load use path string }
   getfll; { get a new file list entry }
   getsrc; { get a new source file entry, as a dummy for a parsing 
             buffer }
   getcmd; { load command line }
   parcmd; { parse command line }
   putsrc; { release dummy buffer }

   { Initalize special character sequence table.
     The special character table is held in encoded format. }

   for ci := 1 to chrmax do 
     with spctbl[ci] do begin { initalize all table }
  
      lab := '  ';
      tolk := cundefined;
      chn := 0

   end;

   spctbl[  1].lab  := '[ ';
   spctbl[  1].tolk := clbrkt;
   spctbl[  2].lab  := '><';
   spctbl[  2].tolk := cnequa;
   spctbl[  3].lab  := '] ';
   spctbl[  3].tolk := crbrkt;
   spctbl[  4].lab  := '^ ';
   spctbl[  4].tolk := ccmf;
   spctbl[  5].lab  := ': ';
   spctbl[  5].tolk := ccln;
   spctbl[  6].lab  := '; ';
   spctbl[  6].tolk := cscn;
   spctbl[  7].lab  := '< ';
   spctbl[  7].tolk := cltn;
   spctbl[  8].lab  := '= ';
   spctbl[  8].tolk := cequ;
   spctbl[  9].lab  := '> ';
   spctbl[  9].tolk := cgtn;
   spctbl[ 10].lab  := '=<';
   spctbl[ 10].tolk := clequa;
   spctbl[ 11].lab  := '@ ';
   spctbl[ 11].tolk := ccmf;
   spctbl[ 12].lab  := '(*'; spctbl[ 12].chn :=  20;
   spctbl[ 12].tolk := clct;
   spctbl[ 13].lab  := '*)';
   spctbl[ 13].tolk := crct;
   spctbl[ 14].lab  := '<='; spctbl[ 14].chn :=  10;
   spctbl[ 14].tolk := clequ;
   spctbl[ 15].lab  := '<>'; spctbl[ 15].chn :=   2;
   spctbl[ 15].tolk := cnequ;
   spctbl[ 16].lab  := '>='; spctbl[ 16].chn :=  18;
   spctbl[ 16].tolk := cgequ;
   spctbl[ 17].lab  := '.)';
   spctbl[ 17].tolk := crbrkt;
   spctbl[ 18].lab  := '=>'; spctbl[ 18].chn :=  19;
   spctbl[ 18].tolk := cgequa;
   spctbl[ 19].lab  := '(.';
   spctbl[ 19].tolk := clbrkt;
   spctbl[ 20].lab  := ':=';
   spctbl[ 20].tolk := cbcms;
   spctbl[ 22].lab  := '..';
   spctbl[ 22].tolk := crange;
   spctbl[ 24].lab  := '( ';
   spctbl[ 24].tolk := clparen;
   spctbl[ 25].lab  := ') ';
   spctbl[ 25].tolk := crparen;
   spctbl[ 26].lab  := '* ';
   spctbl[ 26].tolk := ctimes;
   spctbl[ 27].lab  := '+ ';
   spctbl[ 27].tolk := cplus;
   spctbl[ 28].lab  := ', ';
   spctbl[ 28].tolk := ccma;
   spctbl[ 29].lab  := '- ';
   spctbl[ 29].tolk := cminus;
   spctbl[ 30].lab  := '. ';
   spctbl[ 30].tolk := cperiod;
   spctbl[ 31].lab  := '/ ';
   spctbl[ 31].tolk := crdiv;
   spctbl[ 33].lab  := '{ ';
   spctbl[ 33].tolk := clct;
   spctbl[ 35].lab  := '} ';
   spctbl[ 35].tolk := crct;

   { Initalize reserved word table. This table is automatically
     generated, see the "hashtab" program.
     The reserved word table is held in encoded format. }

{   for ri := 1 to resmax do }
{     with restbl[ri] do begin { initalize all table }
  
{      for li := 1 to labmax do lab[li] := ' ';}
{      tolk := cundefined;}
{      chn := 0}

{   end;}

   for ri := 1 to resmax do begin
  
      for li := 1 to labmax do restbl[ri].lab := nil;
      restbl[ri].tolk := cundefined;
      restbl[ri].chn := 0

   end;

   { Set keyword definitions table, used to convert keys to strings for 
     diagnostics. }

   deftbl[cplus]       := copy('+');
   deftbl[cminus]      := copy('-');
   deftbl[ctimes]      := copy('*');
   deftbl[crdiv]       := copy('/');
   deftbl[cequ]        := copy('=');
   deftbl[cnequ]       := copy('<>');
   deftbl[cnequa]      := copy('><');
   deftbl[cltn]        := copy('<');
   deftbl[cgtn]        := copy('>');
   deftbl[clequ]       := copy('<=');
   deftbl[clequa]      := copy('=<');
   deftbl[cgequ]       := copy('>=');
   deftbl[cgequa]      := copy('=>');
   deftbl[clparen]     := copy('(');
   deftbl[crparen]     := copy(')');
   deftbl[clbrkt]      := copy('[');
   deftbl[crbrkt]      := copy(']');
   deftbl[clct]        := copy('{');
   deftbl[crct]        := copy('}');
   deftbl[cbcms]       := copy(':=');
   deftbl[cperiod]     := copy('.');
   deftbl[ccma]        := copy(',');
   deftbl[cscn]        := copy(';');
   deftbl[ccln]        := copy(':');
   deftbl[ccmf]        := copy('^');
   deftbl[crange]      := copy('..');
   if langkey = lang_french then begin

      deftbl[cdiv]        := copy('div');
      deftbl[cmod]        := copy('mod');
      deftbl[cnil]        := copy('nul');
      deftbl[cin]         := copy('en');
      deftbl[cor]         := copy('ou');
      deftbl[cand]        := copy('et');
      deftbl[cxor]        := copy('xou');
      deftbl[cnot]        := copy('non');
      deftbl[cif]         := copy('si');
      deftbl[cthen]       := copy('alors');
      deftbl[celse]       := copy('sinon');
      deftbl[ccase]       := copy('cas');
      deftbl[cof]         := copy('de');
      deftbl[crepeat]     := copy('répéter');
      deftbl[cuntil]      := copy('jusquà');
      deftbl[cwhile]      := copy('pendant');
      deftbl[cdo]         := copy('faire');
      deftbl[cfor]        := copy('for');
      deftbl[cto]         := copy('hautà');
      deftbl[cdownto]     := copy('basà');
      deftbl[cbegin]      := copy('début');
      deftbl[cend]        := copy('fin');
      deftbl[cwith]       := copy('avec');
      deftbl[cgoto]       := copy('allerà');
      deftbl[cconst]      := copy('const');
      deftbl[cvar]        := copy('var');
      deftbl[ctype]       := copy('type');
      deftbl[carray]      := copy('tableau');
      deftbl[crecord]     := copy('fiche');
      deftbl[cset]        := copy('ensemble');
      deftbl[cfile]       := copy('fichier');
      deftbl[cfunction]   := copy('fonction');
      deftbl[cprocedure]  := copy('procédure');
      deftbl[clabel]      := copy('étiquette');
      deftbl[cpacked]     := copy('bondé');
      deftbl[cprogram]    := copy('programme');
      deftbl[cforward]    := copy('avancer');
      deftbl[cmodule]     := copy('module');
      deftbl[cuses]       := copy('emploi');
      deftbl[cprivate]    := copy('privé');
      deftbl[cexternal]   := copy('externe');
      deftbl[cview]       := copy('vue');
      deftbl[cfixed]      := copy('fixe');
      deftbl[cprocess]    := copy('procés');
      deftbl[cmonitor]    := copy('moniteur');
      deftbl[cshare]      := copy('partager');
      deftbl[cclass]      := copy('classe');
      deftbl[cis]         := copy('est');
      deftbl[catom]       := copy('atome');
      deftbl[coverload]   := copy('surcharger');
      deftbl[coverride]   := copy('remplacer');
      deftbl[creference]  := copy('référence');
      deftbl[cthread]     := copy('fil');
      deftbl[cjoins]      := copy('joindre');
      deftbl[cstatic]     := copy('statique');
      deftbl[cinherited]  := copy('herité');
      deftbl[cself]       := copy('cellci');
      deftbl[cvirtual]    := copy('virtuel');
      deftbl[ctry]        := copy('essai');
      deftbl[cexcept]     := copy('excepter');
      deftbl[cextends]    := copy('prolonger');
      deftbl[cresult]     := copy('résultat');
      deftbl[con]         := copy('sur');

   end else begin { english }

      deftbl[cdiv]        := copy('div');
      deftbl[cmod]        := copy('mod');
      deftbl[cnil]        := copy('nil');
      deftbl[cin]         := copy('in');
      deftbl[cor]         := copy('or');
      deftbl[cand]        := copy('and');
      deftbl[cxor]        := copy('xor');
      deftbl[cnot]        := copy('not');
      deftbl[cif]         := copy('if');
      deftbl[cthen]       := copy('then');
      deftbl[celse]       := copy('else');
      deftbl[ccase]       := copy('case');
      deftbl[cof]         := copy('of');
      deftbl[crepeat]     := copy('repeat');
      deftbl[cuntil]      := copy('until');
      deftbl[cwhile]      := copy('while');
      deftbl[cdo]         := copy('do');
      deftbl[cfor]        := copy('for');
      deftbl[cto]         := copy('to');
      deftbl[cdownto]     := copy('downto');
      deftbl[cbegin]      := copy('begin');
      deftbl[cend]        := copy('end');
      deftbl[cwith]       := copy('with');
      deftbl[cgoto]       := copy('goto');
      deftbl[cconst]      := copy('const');
      deftbl[cvar]        := copy('var');
      deftbl[ctype]       := copy('type');
      deftbl[carray]      := copy('array');
      deftbl[crecord]     := copy('record');
      deftbl[cset]        := copy('set');
      deftbl[cfile]       := copy('file');
      deftbl[cfunction]   := copy('function');
      deftbl[cprocedure]  := copy('procedure');
      deftbl[clabel]      := copy('label');
      deftbl[cpacked]     := copy('packed');
      deftbl[cprogram]    := copy('program');
      deftbl[cforward]    := copy('forward');
      deftbl[cmodule]     := copy('module');
      deftbl[cuses]       := copy('uses');
      deftbl[cprivate]    := copy('private');
      deftbl[cexternal]   := copy('external');
      deftbl[cview]       := copy('view');
      deftbl[cfixed]      := copy('fixed');
      deftbl[cprocess]    := copy('process');
      deftbl[cmonitor]    := copy('monitor');
      deftbl[cshare]      := copy('share');
      deftbl[cclass]      := copy('class');
      deftbl[cis]         := copy('is');
      deftbl[catom]       := copy('atom');
      deftbl[coverload]   := copy('overload');
      deftbl[coverride]   := copy('override');
      deftbl[creference]  := copy('reference');
      deftbl[cthread]     := copy('thread');
      deftbl[cjoins]      := copy('joins');
      deftbl[cstatic]     := copy('static');
      deftbl[cinherited]  := copy('inherited');
      deftbl[cself]       := copy('self');
      deftbl[cvirtual]    := copy('virtual');
      deftbl[ctry]        := copy('try');
      deftbl[cexcept]     := copy('except');
      deftbl[cextends]    := copy('extends');
      deftbl[cresult]     := copy('result');
      deftbl[con]         := copy('on');
     
   end;
   deftbl[cinteger]    := copy('');
   deftbl[cidentifier] := copy('');
   deftbl[cstring]     := copy('');
   deftbl[creal]       := copy('');
   deftbl[cundefined]  := copy('');
   deftbl[ceof]        := copy('');

   { enter prime entries to reserved word table }
   for ki := cdiv to con do begin

      { find initial hash function }
      ri := hash(deftbl[ki]^, hashoff, resmax);
      if restbl[ri].lab = nil then begin { key is empty, add here }

         restbl[ri].lab := copy(deftbl[ki]); { place label }
         restbl[ri].tolk := ki { place tolken }

      end

   end;

   { now enter non-prime }
   for ki := cdiv to con do begin

      { find initial hash function }
      ri := hash(deftbl[ki]^, hashoff, resmax);
      if not comp(restbl[ri].lab, deftbl[ki]) then begin { key is non-prime }

         { find last entry in chain }
         while restbl[ri].chn > 0 do ri := restbl[ri].chn;
         { find free entry to chain to }
         rf := 0;
         for ri2 := resmax downto 1 do if restbl[ri2].lab = nil then rf := ri2;
         if rf = 0 then error(esflt43, true); { should have found it }
         restbl[ri].chn := rf; { link last entry to this entry }
         restbl[rf].lab := copy(deftbl[ki]); { place label }
         restbl[rf].tolk := ki { place tolken }

      end

   end;

   for ti := tudf to tglbl do typfre[ti] := nil; { clear free type entry table }

   { create system module }
   getmod(mp);
   new(mp); { get a new module entry }
   mp^.next := modlst; { push to general list }
   modlst := mp;
   mp^.inx := modcnt; { set module index }
   mp^.modn := copy('_system'); { set system module name }
   mp^.modf := copy(''); { no filename }

   new(mlp); { get a new module list entry }
   mlp^.next := uselst; { push onto uses stack }
   uselst := mlp;
   mlp^.modp := mp; { index the system module }
   { save the system block entry for later use }
   sysmlt := uselst;

   { enter the predefined symbols }

   copy(nxtlab, '_system'); { place system label (block 0) }
   plcsym(nxtlab, bsp);

   { There must be a block on the stack to enter types to, but we need to supply
     a block mark type entry. So for the first block, we leave it undefined, 
     then fix it after the fact. }
   pshblk(bsp, nil); { enter new typing level }

   { place global 'tip' types. These types, since they are truly terminal,
     only need to be present once in the entire system, so we allocate them in
     advance and index them in a global variable }

   lsttyp(tp, tnil); { place the 'nil' type }
   gblnil := tp;
   lsttyp(tp, tudf); { place the 'skeletion key' type }
   gbludf := tp;
   lsttyp(tp, teset); { place the 'empty' set type }
   gbleset := tp;

   { Place predefined types and functions. Note that built in functions don't
     need return types, so we set them undefined.
     Items in the symbol table are not encoded, but could be with changes. }

   lsttyp(btp, tglbl); { place global block }
   btp^.mm := mmsystem; { set system type }
   bsp^.typ := btp; { link to type }
   blkstk^.mark := btp; { fix mark type }

   if langkey = lang_french then copy(nxtlab, 'booléen')
   else copy(nxtlab, 'boolean');
   plcsym(nxtlab, sp);
   lsttyp(tp, tboolean); { boolean }
   sp^.typ := tp; { link to symbol }
   gblbool := tp; { place global root }

   if langkey = lang_french then copy(nxtlab, 'faux')
   else copy(nxtlab, 'false');
   plcsym(nxtlab, sp);
   lsttyp(tp1, tenme); { false }
   sp^.typ := tp1; { link to symbol }
   gblfalse := tp1; { place global root }

   if langkey = lang_french then copy(nxtlab, 'vrai')
   else copy(nxtlab, 'true');
   plcsym(nxtlab, sp);
   lsttyp(tp2, tenme); { true }
   sp^.typ := tp2; { link to symbol }
   gbltrue := tp2; { place global root }
   tp^.bnc := tp1; { link to boolean }
   tp1^.enh := tp; { place head false }
   tp1^.env := 0; { place value false }
   tp1^.enx := tp2; { place next false }
   tp2^.enh := tp; { place head true }
   tp2^.env := 1; { place value true }
   tp2^.enx := nil; { place next true (end) }

   if langkey = lang_french then copy(nxtlab, 'entier')
   else copy(nxtlab, 'integer');
   plcsym(nxtlab, sp);
   lsttyp(tp, tinteger); { get type }
   sp^.typ := tp; { link to symbol }
   gblint := tp; { place global root }

   if langkey = lang_french then copy(nxtlab, 'lentier')
   else copy(nxtlab, 'linteger');
   plcsym(nxtlab, sp);
   lsttyp(tp, tlinteger); { get type }
   sp^.typ := tp; { link to symbol }
   gbllint := tp; { place global root }

   if langkey = lang_french then copy(nxtlab, 'cardinal')
   else copy(nxtlab, 'cardinal');
   plcsym(nxtlab, sp);
   lsttyp(tp, tcardinal); { get type }
   sp^.typ := tp; { link to symbol }
   gblcard := tp; { place global root }

   if langkey = lang_french then copy(nxtlab, 'lcardinal')
   else copy(nxtlab, 'lcardinal');
   plcsym(nxtlab, sp);
   lsttyp(tp, tlcardinal); { get type }
   sp^.typ := tp; { link to symbol }
   gbllcard := tp; { place global root }

   if langkey = lang_french then copy(nxtlab, 'carac')
   else copy(nxtlab, 'char');
   plcsym(nxtlab, sp);
   lsttyp(tp, tchar); { get type }
   sp^.typ := tp; { link to symbol }
   gblchr := tp; { place global root }

   if langkey = lang_french then copy(nxtlab, 'maxcar')
   else copy(nxtlab, 'maxchr');
   plcsym(nxtlab, sp);
   lsttyp(tp, ticst); { maxchr }
   tp^.ival.v := 255; { place value }
   tp^.ival.s := false;
   sp^.typ := tp; { link to symbol }

   if langkey = lang_french then copy(nxtlab, 'reel')
   else copy(nxtlab, 'real');
   plcsym(nxtlab, sp);
   lsttyp(tp, treal); { get type }
   sp^.typ := tp; { link to symbol }
   gblreal := tp; { place global root }

   if langkey = lang_french then copy(nxtlab, 'texte')
   else copy(nxtlab, 'text');
   plcsym(nxtlab, sp);
   lsttyp(tp, ttext); { get type }
   sp^.typ := tp; { link to symbol }
   gbltxt := tp; { place global root }

   if langkey = lang_french then copy(nxtlab, 'creal')
   else copy(nxtlab, 'sreal');
   plcsym(nxtlab, sp);
   lsttyp(tp, tsreal); { get type }
   sp^.typ := tp; { link to symbol }
   gblsrl := tp; { place global root }

   if langkey = lang_french then copy(nxtlab, 'maxent')
   else copy(nxtlab, 'maxint');
   plcsym(nxtlab, sp);
   lsttyp(tp, ticst); { maxint }
   tp^.ival.v := maxint; { place value }
   tp^.ival.s := false;
   sp^.typ := tp; { link to symbol }

   if langkey = lang_french then copy(nxtlab, 'maxlent')
   else copy(nxtlab, 'maxlint');
   plcsym(nxtlab, sp);
   lsttyp(tp, ticst); { maxlint }
   tp^.ival.v := maxint; { place value }
   tp^.ival.s := false;
   sp^.typ := tp; { link to symbol }

   if langkey = lang_french then copy(nxtlab, 'maxcrd')
   else copy(nxtlab, 'maxcrd');
   plcsym(nxtlab, sp);
   lsttyp(tp, ticst); { maxcard }
   tp^.ival.v := maxint; { place value }
   tp^.ival.s := false;
   sp^.typ := tp; { link to symbol }

   if langkey = lang_french then copy(nxtlab, 'maxlcrd')
   else copy(nxtlab, 'maxlcrd');
   plcsym(nxtlab, sp);
   lsttyp(tp, ticst); { maxlcard }
   tp^.ival.v := maxint; { place value }
   tp^.ival.s := false;
   sp^.typ := tp; { link to symbol }

   if langkey = lang_french then copy(nxtlab, 'semaphore')
   else copy(nxtlab, 'semaphore');
   plcsym(nxtlab, sp);
   lsttyp(tp, tsemaphore); { get type }
   sp^.typ := tp; { link to symbol }

   if langkey = lang_french then copy(nxtlab, 'exception')
   else copy(nxtlab, 'exception');
   plcsym(nxtlab, sp);
   lsttyp(tp, texception); { get type }
   sp^.typ := tp; { link to symbol }

   if langkey = lang_french then copy(nxtlab, 'abs')
   else copy(nxtlab, 'abs');
   plcsym(nxtlab, sp);
   lsttyp(tp, tfunc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.fncp := nil; { clear parameters }
   tp^.fncr := gbludf; { clear result }
   tp^.fncd := pfabs; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'arctan')
   else copy(nxtlab, 'arctan');
   plcsym(nxtlab, sp);
   lsttyp(tp, tfunc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.fncp := nil; { clear parameters }
   tp^.fncr := gbludf; { clear result }
   tp^.fncd := pfarctan; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'car')
   else copy(nxtlab, 'chr');
   plcsym(nxtlab, sp);
   lsttyp(tp, tfunc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.fncp := nil; { clear parameters }
   tp^.fncr := gbludf; { clear result }
   tp^.fncd := pfchr; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'cos')
   else copy(nxtlab, 'cos');
   plcsym(nxtlab, sp);
   lsttyp(tp, tfunc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.fncp := nil; { clear parameters }
   tp^.fncr := gbludf; { clear result }
   tp^.fncd := pfcos; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'fdf')
   else copy(nxtlab, 'eof');
   plcsym(nxtlab, sp);
   lsttyp(tp, tfunc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.fncp := nil; { clear parameters }
   tp^.fncr := gbludf; { clear result }
   tp^.fncd := pfeof; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'fdln')
   else copy(nxtlab, 'eoln');
   plcsym(nxtlab, sp);
   lsttyp(tp, tfunc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.fncp := nil; { clear parameters }
   tp^.fncr := gbludf; { clear result }
   tp^.fncd := pfeoln; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'exp')
   else copy(nxtlab, 'exp');
   plcsym(nxtlab, sp);
   lsttyp(tp, tfunc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.fncp := nil; { clear parameters }
   tp^.fncr := gbludf; { clear result }
   tp^.fncd := pfexp; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'ln')
   else copy(nxtlab, 'ln');
   plcsym(nxtlab, sp);
   lsttyp(tp, tfunc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.fncp := nil; { clear parameters }
   tp^.fncr := gbludf; { clear result }
   tp^.fncd := pfln; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'impair')
   else copy(nxtlab, 'odd');
   plcsym(nxtlab, sp);
   lsttyp(tp, tfunc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.fncp := nil; { clear parameters }
   tp^.fncr := gbludf; { clear result }
   tp^.fncd := pfodd; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'ord')
   else copy(nxtlab, 'ord');
   plcsym(nxtlab, sp);
   lsttyp(tp, tfunc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.fncp := nil; { clear parameters }
   tp^.fncr := gbludf; { clear result }
   tp^.fncd := pford; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'avant')
   else copy(nxtlab, 'pred');
   plcsym(nxtlab, sp);
   lsttyp(tp, tfunc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.fncp := nil; { clear parameters }
   tp^.fncr := gbludf; { clear result }
   tp^.fncd := pfpred; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'arrondi')
   else copy(nxtlab, 'round');
   plcsym(nxtlab, sp);
   lsttyp(tp, tfunc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.fncp := nil; { clear parameters }
   tp^.fncr := gbludf; { clear result }
   tp^.fncd := pfround; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'sin')
   else copy(nxtlab, 'sin');
   plcsym(nxtlab, sp);
   lsttyp(tp, tfunc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.fncp := nil; { clear parameters }
   tp^.fncr := gbludf; { clear result }
   tp^.fncd := pfsin; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'carré')
   else copy(nxtlab, 'sqr');
   plcsym(nxtlab, sp);
   lsttyp(tp, tfunc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.fncp := nil; { clear parameters }
   tp^.fncr := gbludf; { clear result }
   tp^.fncd := pfsqr; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'rcarré')
   else copy(nxtlab, 'sqrt');
   plcsym(nxtlab, sp);
   lsttyp(tp, tfunc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.fncp := nil; { clear parameters }
   tp^.fncr := gbludf; { clear result }
   tp^.fncd := pfsqrt; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'aprés')
   else copy(nxtlab, 'succ');
   plcsym(nxtlab, sp);
   lsttyp(tp, tfunc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.fncp := nil; { clear parameters }
   tp^.fncr := gbludf; { clear result }
   tp^.fncd := pfsucc; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'tronquer')
   else copy(nxtlab, 'trunc');
   plcsym(nxtlab, sp);
   lsttyp(tp, tfunc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.fncp := nil; { clear parameters }
   tp^.fncr := gbludf; { clear result }
   tp^.fncd := pftrunc; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'existant')
   else copy(nxtlab, 'exists');
   plcsym(nxtlab, sp);
   lsttyp(tp, tfunc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.fncp := nil; { clear parameters }
   tp^.fncr := gbludf; { clear result }
   tp^.fncd := pfexists; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'doù')
   else copy(nxtlab, 'location');
   plcsym(nxtlab, sp);
   lsttyp(tp, tfunc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.fncp := nil; { clear parameters }
   tp^.fncr := gbludf; { clear result }
   tp^.fncd := pflocation; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'longueur')
   else copy(nxtlab, 'length');
   plcsym(nxtlab, sp);
   lsttyp(tp, tfunc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.fncp := nil; { clear parameters }
   tp^.fncr := gbludf; { clear result }
   tp^.fncd := pflength; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'max')
   else copy(nxtlab, 'max');
   plcsym(nxtlab, sp);
   lsttyp(tp, tfunc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.fncp := nil; { clear parameters }
   tp^.fncr := gbludf; { clear result }
   tp^.fncd := pfmax; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'débarrasser')
   else copy(nxtlab, 'dispose');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfdispose; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'prendre')
   else copy(nxtlab, 'get');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfget; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'neuf')
   else copy(nxtlab, 'new');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfnew; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'compresser')
   else copy(nxtlab, 'pack');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfpack; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'page')
   else copy(nxtlab, 'page');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfpage; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'mettre')
   else copy(nxtlab, 'put');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfput; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'lire')
   else copy(nxtlab, 'read');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfread; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'lireln')
   else copy(nxtlab, 'readln');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfreadln; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'relire')
   else copy(nxtlab, 'reset');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfreset; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'réécrire')
   else copy(nxtlab, 'rewrite');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfrewrite; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'décompresser')
   else copy(nxtlab, 'unpack');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfunpack; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'écrire')
   else copy(nxtlab, 'write');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfwrite; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'écrireln')
   else copy(nxtlab, 'writeln');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfwriteln; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'fixer')
   else copy(nxtlab, 'assign');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfassign; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'firmer')
   else copy(nxtlab, 'close');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfclose; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'placer')
   else copy(nxtlab, 'position');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfposition; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'effacer')
   else copy(nxtlab, 'delete');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfdelete; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'changer')
   else copy(nxtlab, 'change');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfchange; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'arrêter')
   else copy(nxtlab, 'halt');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfhalt; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'impliquer')
   else copy(nxtlab, 'refer');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfrefer; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'revaloriser')
   else copy(nxtlab, 'update');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfupdate; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'ajouter')
   else copy(nxtlab, 'append');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfappend; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'signal')
   else copy(nxtlab, 'signal');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfsignal; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'signalun')
   else copy(nxtlab, 'signalone');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfsignalone; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'attendre')
   else copy(nxtlab, 'wait');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfwait; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'jeter')
   else copy(nxtlab, 'throw');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfthrow; { place dispatch code }

   if langkey = lang_french then copy(nxtlab, 'affirmer')
   else copy(nxtlab, 'assert');
   plcsym(nxtlab, sp);
   lsttyp(tp, tproc); { get type }
   sp^.typ := tp; { link to symbol }
   tp^.prcp := nil; { clear parameters }
   tp^.prcd := pfassert; { place dispatch code }

   { create 'self' error label }
   getsym(selflab);
   selflab^.lab := copy('self');

   if fverb and fansi then begin 

      if langmsg = lang_french then begin

         write('S. A. Moore Pascal se conformer à exigence de étage 0 ');
         writeln('ISO/IEC 7185')

      end else begin { english by default }

         write('S. A. Moore Pascal complies with the requirements of level 0 ');
         writeln('ISO/IEC 7185')

      end

   end;
   fllstk^.cur := fllstk^.fst; { index 1st file }
   if not fsupp then begin { first file is the output file }

      addext(fllstk^.cur^.nam, 'int', false); { add .int extention }
      if exists(fllstk^.cur^.nam) then { if the output file exists, delete it }
         delete(fllstk^.cur^.nam);
      fllstk^.cur := fllstk^.cur^.next; { skip to first source file }

   end;
   sfc := 0; { clear source file counter }
   while fllstk^.cur <> nil do begin { process source files }

      addext(fllstk^.cur^.nam, 'pas', false); { add .pas extention }
      { check file exists, err if not }
      errfn := fllstk^.cur^.nam; { place name for error processing }
      if not exists(fllstk^.cur^.nam) then 
         error(efnfn, true, errfn); { flag error }
      sfc := sfc+1; { count source files }
      fllstk^.cur := fllstk^.cur^.next { next sequential file }

   end;
   if demo_mode then begin { demo mode restriction }

      if sfc > 1 then error(edemmlf, true) { more than one source file }

   end;
   fllstk^.cur := fllstk^.fst; { index 1st file }
   if ferrf then begin { setup error file }

      addext(errnam, 'err', false); { add .err extend }
      if exists(errnam) then delete(errnam) { delete preexisting file }

   end;
   if not fsupp then begin { open output file }

      addext(fllstk^.cur^.nam, 'int', false); { add .int extention }
      ofn := fllstk^.cur^.nam; { save output filename }
      assign(intout, fllstk^.cur^.nam); { set filename }
      rewrite(intout); { read to write }
      fintopn := true; { set output file open }
      fllstk^.cur := fllstk^.cur^.next; { skip to first source file }
      wrtint(chr2ascii('S')); { output signature to file, 32 bits }
      wrtint(chr2ascii('P'));
      wrtint(chr2ascii('K'));
      wrtint(chr2ascii('A'))
      
   end;
   fsrc := true; { set source line parsing }
   { open first file (must be present) }
   if demo_mode then begin { in demo mode }

      opnsrc(fllstk^.cur^.nam, demo_chars, demo_lines)

   end else begin { normal mode }

      opnsrc(fllstk^.cur^.nam, maxint, maxint)

   end;
   fllstk^.cur := fllstk^.cur^.next; { skip }
   { start up main parse }
   getlin; { get 1st source line }
   { parse module/program }
   gettlk; { load first tolken }
   curprc := btp; { set system block head }
   wrtcod(ibgnlvl); { output start new level marker }
   wrtlnk(btp); { output address of mark }
   parmod([ceof]); { parse module }
   if nxttlk <> ceof then error(eeofexp, false); { should be eof }
   { the system section is output as a formal block, allowing system variables
     to be formed as required. It would even be possible to output code if
     such sequences were encoded internally }
   wrttyp; { output types section }
   wrtsyms; { output symbols section }
   wrtcod(iendlvl); { output end of level marker }
   wrtcod(iendfil); { output intermediate file end }
   listtyp; { output types listing }
   listsym(bsp); { output symbols listing and purge }
   poptyp; { remove typing level }
   { remove module from uses list }
   uselst := mlp^.next; { gap }
   putmlt(mlp); { release entry }

   99: { error abort point }

   while fllstk <> nil do putfll; { clean file lists stack }
   if ferro then close(errfil); { close errors file }
   if fintopn then close(intout); { close intermediate output file }
   if fverb then begin { print end message }

      if errcnt <> 0 then writeln('Errors this compilation: ', errcnt:1)
      else writeln('No errors detected');
      if fsupp or (errcnt <> 0) then writeln('No output file was generated')
      else writeln('Output file ', ofn:0, ' was generated');
      writeln('Function complete')

   end

end.
