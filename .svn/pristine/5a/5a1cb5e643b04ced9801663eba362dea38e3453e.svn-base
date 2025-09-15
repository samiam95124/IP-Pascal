{*******************************************************************************
*                                                                              *
*                             C PARSER PROGRAM                                 *
*                                                                              *
*                        Copyright (C) 2003  S. A. Moore                       *
*                                                                              *
* Parses and validates a C program, building a type and symbol table. This is  *
* the top half of a compiler, but at present there is no plan to create a C    *
* front end for IP. It is meant to be a building block for various programs    *
* such as header translators.                                                  *
* The syntax and reference used was the ansi whitebook and the ANSI C          *
* standard. See also syntax.dwp for a diagram that was constructed to explain  *
* the syntax.                                                                  *
* C is abbreviated to the point of being loaded with ambiguities that must be  *
* worked out by context. Because of this, the parse is fairly difficult to     *
* work out, and there are several comments to the effect of how special        *
* problems were handled.                                                       *
*                                                                              *
*******************************************************************************}

program cparse(output);

uses extlib,
     parlib, { command line parsing }
     macro,  { macro level }
     symbol, { symbol processing }
     parser; { C parser }

label terminate_program; { end program run }

procedure terminate; forward;

private

const filmax = 1000; { number of characters in a filename }
      labmax = 10;   { label maximum }
      cmdmax = 250; { maximum length of command string for actions }

type  filinx = 1..filmax; { index for filename }
      filnam = packed array [filinx] of char; { a filename }
      labinx = 1..labmax; { index for label }
      labl   = packed array [labinx] of char; { label }

var   srcnam:  filnam;  { filename holder }
      p, n, e: filnam;  { filename components }
      w:       labl;    { word to work with }
      cmdhan:  parhan;  { handle for command parsing }
      err:     boolean; { error holder }
      valfch:  chrset;  { valid file characters }

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

      copyp(ts, 'n'); { form negative }
      catp(ts, n);
      if compp(w, ts) then begin

         f := false; { perform false }
         optfnd := true { set option found }

      end else begin

         copyp(ts, 'n'); { form negative }
         catp(ts, a);
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
      if err then error(einvopt); { invalid option }
      setflg('ls',  'listsymbols',       fsym); { list symbols }
      setflg('lt',  'listtypes',         ftype); { list types }
      setflg('ltk', 'listtolkens',       fprttlk); { list tolkens }
      setflg('lpr', 'listparserule',     fprtrle); { list parsing rules }
      setflg('ll',  'listline',          fprtlin); { list raw lines incoming }
      setflg('lme', 'listmacroexpand',   fprtexp); { list macro expansions }
      setflg('lm',  'listmacro',         fprtmac); { list macro expansions }
      setflg('ld',  'listdefines',       fprtdef); { list definition table }
      setflg('lpl', 'listprocessedline', fprtpln); { list definition table }
      { allow non-standard unnamed struct/union element }
      setflg('use', 'unnamedstructelement', fuse);
      setflg('cpc', 'cppcomment',        fcppcmt); { allow C++ comments }
      setflg('msa', 'msasm',             fmsasm);  { allow ms asm constructs }
      setflg('ec',  'enumcomma',         fenecma); { allow extra enum comma }
      setflg('td',  'typeduplication',   fduptyp); { allow type duplication }
      if not optfnd then error(eoptnf); { option not found }
      skpspc(cmdhan) { skip spaces }

   end

end;

begin

   writeln;
   writeln('C Parser vs. 0.1 Copyright (C) S. A. Moore');
   writeln;
   openpar(cmdhan); { open parser }
   openfil(cmdhan, '_command', cmdmax); { open command line level }
   filchr(valfch); { get the filename valid characters }
   valfch := valfch-['=']; { remove parsing characters }
   setfch(cmdhan, valfch); { set that for active parsing }
   paropt; { parse command options }
   if endlin(cmdhan) then error(efilexp); { no filename }
   parfil(cmdhan, srcnam, false, err); { parse filename }
   if err then error(einvfil); { invalid filename }
   paropt; { parse command options }
   brknamp(srcnam, p, n, e); { break down name }
   { if there is no extention, place .c }
   if e[1] = ' ' then copyp(e, 'c');
   maknamp(srcnam, p, n, e); { recreate }
   if not exists(srcnam) then error(efilnf); { no file }
   write('Parsing file: ');
   writesp(output, srcnam);
   writeln;
   writeln;
   opnsrc(srcnam); { open source file }
   gettlk; { get 1st tolken }
   partrans; { parse C file }
   prtdef; { print definitions table }
   writeln;
   writeln('Function complete');

   terminate_program: { error bailout }

end.
