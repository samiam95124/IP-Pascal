{*******************************************************************************
*                                                                              *
*                       "LOOM OF LANGUAGE" LIST MAKER                          *
*                                                                              *
*******************************************************************************}

program loomlist(output);

uses stddef,
     windows,
     strlib,
     extlib;

const maxwrd = 50;
      maxlin = 250;

type

   wrdlab = packed array [1..maxwrd] of char; { label }
   line = packed array [1..maxlin] of char; { input line }
   wrdptr = ^wrdety; { pointer to word entry }
   wrdety = record { single word }

      next: wrdptr; { pointer to next entry }
      word: wrdlab; { label }

   end;

var

   { individual language word lists }
   english, french, italian, spanish, portuguese: wrdptr;
   { section word counts }
   englishc, frenchc, italianc, spanishc, portuguesec: integer;
   wordfile: text; { word file }
   outfile:  bytfil {text}; { output file }
   word:     wrdlab; { word to read }
   inplin:   line; { line of text }
   state:    (stnone, stsection);
   section:  (snone, senglish, sfrench, sitalian, sspanish, sportuguese);
   linec:    integer; { line count }
   i:        integer;

{ execute process }

procedure excprc(view fn: string);

var

   pi:   sc_process_information; { process information }
   si:   sc_startupinfoa; { startup information }
   fnh:  pstring; { filename holder }
   cmdb: pstring; { buffer for command line }
   el:   sc_evsptr; { environment list }
   cp:   pstring; { current path }

begin

   pi.hprocess := 0;
   pi.hthread := 0;
   pi.dwprocessid := 0;
   pi.dwthreadid := 0;
   si.cb := 68;
   si.lpReserved := nil;
   si.lpDesktop := nil;
   si.lpTitle := nil;
   si.dwX := 0;
   si.dwY := 0;
   si.dwXSize := 0;
   si.dwYSize := 0;
   si.dwXCountChars := 0;
   si.dwYCountChars := 0;
   si.dwFillAttribute := 0;
   si.dwFlags := sc_startf_useshowwindow;
   si.wShowWindow := sc_sw_shownormal;
   si.cbReserved2 := 0;
   si.lpReserved2 := nil;
   si.hStdInput := 0;
   si.hStdOutput := 0;
   si.hStdError := 0;
   fnh := copy(fn); { copy filename to pointer }
   cmdb := copy(''); { set no command line }
   el := nil; { set no environment }
   cp := getcur; { get current path }
   if not sc_createprocess_nn(fnh^, cmdb^, false, 0, el, cp^, si, pi) then begin

      writeln('*** Cannot create process ', fn:0);
      halt

   end;

end;

{ place word in word list }

procedure plcwrd(var list: wrdptr; view word: string);

var p:    wrdptr; { pointer for word entry }
    l:    wrdptr; { list pointer }
    last: wrdptr; { last entry pointer }

begin

   if len(word) > maxwrd then begin { too long }

      writeln('*** String "', word:0, '" is too long');
      halt

   end;
   new(p); { get new entry for the word }
   copy(p^.word, word); { place word }
   p^.next := nil; { terminate }
   if list = nil then list := p { if list is empty, place 1st word }
   else begin { place mid/last }

      l := list; { index top of list }
      while l <> nil do begin

         last := l; { set new last }
         l := l^.next { go next }

      end;
      last^.next := p; { enter as next }

   end

end;

{ Write label to output file.
  the standard output mechanisim appears to be clipping out extended 
  ISO characters (those > 127), so we treat the output file as
  literal binary }

procedure wrtwrd(var f: bytfil; view w: string; l: integer);

var i: integer;

begin
   
   if l < len(w) then l := len(w);
   if l >= 0 then begin { left justify }

      for i := 1 to l-len(w) do write(f, ord(' '));
      for i := 1 to l do write(f, ord(w[i]))

   end else begin { right justify }

      l := abs(l);
      for i := 1 to l do write(f, ord(w[i]));
      for i := 1 to l-len(w) do write(f, ord(' '));

   end

end;

{ print list }

procedure prtlst(var f: bytfil; list: wrdptr);

begin

   while list <> nil do begin

      wrtwrd(f, list^.word, 0);
      wrtwrd(outfile, '\cr\lf', 0);
      list := list^.next

   end

end;

begin

   writeln('Loom of latin word list maker');
   writeln;

   { clear all lists }
   english    := nil;
   french     := nil;
   italian    := nil;
   spanish    := nil;
   portuguese := nil;

   { clear counts }
   englishc    := 0;
   frenchc     := 0;
   italianc    := 0;
   spanishc    := 0;
   portuguesec := 0;

   { set state }
   state := stnone;

   { set section }
   section := snone;

   linec := 0; { clear line counter }

   { read in the word lists }
   assign(wordfile, 'loomlatin.txt');
   reset(wordfile);

   { open output file }
   assign(outfile, 'newlist.txt');
   rewrite(outfile);

   while not eof(wordfile) do begin

      reads(wordfile, inplin);
      readln(wordfile);
      linec := linec+1; { count line }
      if (inplin[1] <> ' ') and (inplin[1] <> '-') then begin

         { this is an active line }
         if state = stnone then begin { section definition state }

            { set section type or error }
            if compp(inplin, 'english') then begin 

               { english marks a new page }
               section := senglish;
               if (englishc <> frenchc) or
                  (englishc <> italianc) or
                  (englishc <> spanishc) or
                  (englishc <> portuguesec) then begin { count mismatch }

                  writeln('Word count mismatch in line: ', linec:1);
                  writeln('Total word counts: ');
                  writeln;
                  writeln('English     French      Spanish     Portuguese  Italian');
                  writeln('==========================================================');
                  writeln(englishc:-12, frenchc:-12, spanishc:-12, portuguesec:-12, italianc:-12);
                  halt

               end

            end else if compp(inplin, 'french') then section := sfrench
            else if compp(inplin, 'italian') then section := sitalian
            else if compp(inplin, 'spanish') then section := sspanish
            else if compp(inplin, 'portuguese') then section := sportuguese
            else begin { error }

               writeln('*** Bad section id: ', inplin:0);
               halt

            end;
            state := stsection { set in a section }

         end else begin { in section }

            if inplin[1] <> '=' then begin { process word }

               case section of

                  senglish: begin

                     plcwrd(english, inplin); { place in list }
                     englishc := englishc+1 { count }

                  end;
                  sfrench: begin

                     plcwrd(french, inplin); { place in list }
                     frenchc := frenchc+1;

                  end;
                  sitalian: begin
   
                     plcwrd(italian, inplin); { place in list }
                     italianc := italianc+1;

                  end;
                  sspanish: begin

                     plcwrd(spanish, inplin); { place in list }
                     spanishc := spanishc+1;

                  end;
                  sportuguese: begin

                     plcwrd(portuguese, inplin); { place in list }
                     portuguesec := portuguesec+1

                  end

               end

            end

         end

      end else state := stnone { reset back to between sections state }

   end;
   
   writeln('Total word count: ', englishc:1);

   { wrtwrd(outfile, 'English list:\cr\lf', 0); }
   wrtwrd(outfile, '\cr\lf', 0);
   prtlst(outfile, french);
   wrtwrd(outfile, '\cr\lf', 0);

   close(wordfile);
   close(outfile);

end.
