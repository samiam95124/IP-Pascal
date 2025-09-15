{******************************************************************************

TERMINAL EMULATOR

This is a simple program writen to the trmlib standard that just allows the
user to scribble text on the screen. Implements the basic positioning keys,
etc.

******************************************************************************}

program terminal(input, output);

uses trmlib; { terminal level functions }

var er:        evtrec;  { record for returned events }
    autostate: boolean; { state of automatic wrap and scroll }
    buf:       integer; { current terminal buffer }
    fbold:     boolean; { bold active flag }
    fundl:     boolean; { underline active flag }
    fstko:     boolean; { strikeout active flag }
    fital:     boolean; { italic active flag }
    fsubs:     boolean; { subscript active flag }
    fsups:     boolean; { superscript active flag }

begin

   buf := 1; { set normal buffer }
   fbold := false; { set bold off }
   fundl := false; { set underline off }
   fstko := false; { set strikeout off }
   fital := false; { set italic off }
   fsubs := false; { set subscript off }
   fsups := false; { set superscript off }
   autostate := true; { set auto on }
   repeat { event loop }

      event(input, er); { get the next event }
      { filter events we handle }
      if er.etype in [etchar, etup, etdown, etleft, etright, ethomes, ethomel,
                      etends, etendl, etscrl, etscrr, etscru, etscrd, etdelcb,
                      etenter, ettab, etfun,
                      etinsertt] then case er.etype of { event }

         etchar:  write(er.char); { pass character to output }
         { enter line }
         etenter: begin cursor(output, 1, cury(output)); down(output) end;
         etup:    up(output);     { up one line }
         etdown:  down(output);   { down one line }
         etleft:  left(output);   { left one character }
         etright: right(output);  { right one character }
         ethomes: home(output);   { home screen }
         ethomel: cursor(output, 1, cury(output)); { home line }
         etends:  cursor(output, maxx(output), maxy(output)); { end screen }
         etendl:  cursor(output, maxx(output), cury(output)); { end line }
         etscrl:  scroll(output, -1, 0); { scroll left }
         etscrr:  scroll(output, +1, 0); { scroll right }
         etscru:  scroll(output, 0, -1); { scroll up }
         etscrd:  scroll(output, 0, +1); { scroll down }
         etdelcb: del(output);    { delete left character }
         ettab:   write('\ht');   { tab }
         etinsertt: begin

            autostate := not autostate;
            auto(output, autostate)

         end;
         etfun:   begin { function key }

            if er.fkey = 1 then begin { function 1: swap screens }

               if buf = 10 then buf := 1 { wrap buffer back to zero }
               else buf := buf+1; { next buffer }
               select(output, buf, buf)

            end else if er.fkey = 2 then begin { function 2: bold toggle }

               fbold := not fbold; { toggle }
               bold(output, fbold) { apply }

            end else if er.fkey = 3 then begin { function 3: underline toggle }

               fundl := not fundl; { toggle }
               underline(output, fundl) { apply }

            end else if er.fkey = 4 then begin { function 4: strikeout toggle }

               fstko := not fstko; { toggle }
               strikeout(output, fstko) { apply }

            end else if er.fkey = 5 then begin { function 5: italic toggle }

               fital := not fital; { toggle }
               italic(output, fital) { apply }

            end else if er.fkey = 6 then begin { function 6: subscript toggle }

               fsubs := not fsubs; { toggle }
               subscript(output, fsubs) { apply }

            end else if er.fkey = 7 then begin { function 7: superscript toggle }

               fsups := not fsups; { toggle }
               superscript(output, fsups) { apply }

            end else if er.fkey = 8 then bcolor(output, cyan)

         end

      end

   until er.etype = etterm { until termination signal }

end.
                      


