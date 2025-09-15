{******************************************************************************
*                                                                             *
*                           SCREEN TEST PROGRAM                               *
*                                                                             *
*                    Copyright (C) 1997 Scott A. Moore                        *
*                                                                             *
* This program performs a reasonably complete test of common features in the  *
* terminal level standard.                                                    *
*                                                                             *
* Tests performed:                                                            *
*                                                                             *
* 1. Row id - number each row with a digit in turn. This test uncovers        *
* positioning errors.                                                         *
* 2. Collumn id - Same for collums.                                           *
* 3. Fill test - fills the screen with the printable ascii characters, and    *
* "elided" control characters. Tests ability to print standard ASCII set.     *
* 4. Sidewinder - Fills the screen starting from the edges in. Tests          *
* positioning.                                                                *
* 5. Bounce - A ball bounces off the walls for a while. Tests positioning.    *
* 6. Scroll - A pattern that is recognizable if shifted is written, then the  *
* display successively scrolled until blank, in each of four directions.      *
* Tests the scrolling ability.                                                *
*                                                                             *
* Tests to be added:                                                          *
*                                                                             *
* 1. Cursor visibility.                                                       *
* 2. Border crossing motions.                                                 *
* 3. Automatic scroll, on and off.                                            *
* 4. Screen buffer selection and display.                                     *
*                                                                             *
******************************************************************************}

program scntst(input, output);

uses trmlib;

var x, y, lx, ly, tx, ty: integer;
    dx, dy: integer;
    c: char;
    top, bottom, lside, rside: integer; { borders }
    direction: (dup, ddown, dleft, dright); { writting direction }
    count, t1, t2: integer;
    delay: integer;
    minlen: integer; { minimum direction, x or y }
    i: integer;

begin

   { set black on white text }
   fcolor(output, black);
   bcolor(output, white);
   page; { clear screen }
   ascroll(output, false); { disable automatic screen scroll }
   write('Screen size: x -> ', maxx(output):1, ' y -> ', maxy(output):1);
   cursor(output, 1, 3);
   write('Press return to start test (and to pass each pattern):');
   readln;
   page;
   curvis(output, false); { remove cursor }
   { perform row id test }
   c := '1';
   for y := 1 to maxy(output) do begin

      cursor(output, 1, y); { index start of line }
      for x := 1 to maxx(output) do write(c); { output characters }
      if c <> '9' then c := succ(c) { next character }
      else c := '0' { start over }

   end;
   readln;
   page;
   { perform collumn id test }
   c := '1';
   for y := 1 to maxy(output) do begin

      cursor(output, 1, y); { index start of line }
      for x := 1 to maxx(output) do begin

         write(c); { output characters }
         if c <> '9' then c := succ(c) { next character }
         else c := '0' { start over }

      end

   end;
   readln;
   page;
   { perform fill test }
   c := chr(0); { initalize character value }
   for y := 1 to maxy(output) do begin

      cursor(output, 1, y); { index start of line }
      for x := 1 to maxx(output) do begin

         if (c >= ' ') and (c <> chr($7f)) then write(c)
         else write('\\');
         if c <> chr($7f) then c := succ(c) { next character }
         else c := chr(0) { start over }

      end

   end;
   readln;
   page;
   { perform sidewinder }
   x := 1; { set origin }
   y := 1;
   top := 1; { set borders }
   bottom := maxy(output);
   lside := 2;
   rside := maxx(output);
   direction := ddown; { start down }
   t1 := maxx(output);
   t2 := maxy(output);
   for count := 1 to t1 * t2 do begin { for all screen characters }

      cursor(output, x, y); { place character }
      write('*');
      case direction of

         ddown:  begin

                   y := y + 1; { next }
                   if y = bottom then begin { change }

                      direction := dright;
                      bottom := bottom - 1

                   end

                end;

         dright: begin

                   x := x + 1; { next }
                   if x = rside then begin

                      direction := dup;
                      rside := rside - 1

                   end

                end;

         dup:    begin

                   y := y - 1;
                   if y = top then begin

                      direction := dleft;
                      top := top + 1

                   end

                end;

         dleft:  begin

                   x := x - 1;
                   if x = lside then begin

                      direction := ddown;
                      lside := lside + 1

                   end

                end

      end

   end;
   readln;
   page;
   { perform bouncing ball }
   x := 10; { set origin }
   y := 20;
   lx := 10; { set last }
   ly := 20;
   dx := -1; { set initial directions }
   dy := -1;
   for count := 1 to 1000 do begin

      cursor(output, x, y); { place character }
      write('*');
      cursor(output, lx, ly); { place character }
      write(' ');
      lx := x; { set last }
      ly := y;
      x := x + dx; { find next x }
      y := y + dy; { find next y }
      tx := x;
      ty := y;
      if (x = 1) or (tx = maxx(output)) then dx := -dx; { find new dir x }
      if (y = 1) or (ty = maxy(output)) then dy := -dy; { find new dir y }
      for delay := 1 to 100000 do; { slow this down }

   end;
   readln;
   page;
   { attributes test }
   if maxy(output) < 20 then write('Not enough lines for attributes test')
   else begin

      blink(output, true);
      writeln('Blinking text');
      blink(output, false);
      reverse(output, true);
      writeln('Reversed text');
      reverse(output, false);
      underline(output, true);
      writeln('Underlined text');
      underline(output, false);
      writeln;
      write('Superscript ');
      superscript(output, true);
      writeln('text');
      superscript(output, false);
      writeln;
      write('Subscript ');
      subscript(output, true);
      writeln('text');
      subscript(output, false);
      writeln;
      italic(output, true);
      writeln('Italic text');
      italic(output, false);
      bold(output, true);
      writeln('Bold text');
      bold(output, false);
      standout(output, true);
      writeln('Standout text');
      standout(output, false);
      fcolor(output, red);
      writeln('Red text');
      fcolor(output, green);
      writeln('Green text');
      fcolor(output, blue);
      writeln('Blue text');
      fcolor(output, cyan);
      writeln('Cyan text');
      fcolor(output, yellow);
      writeln('Yellow text');
      fcolor(output, magenta);
      writeln('Magenta text');
      fcolor(output, black);
      bcolor(output, red);
      writeln('Red background text');
      bcolor(output, green);
      writeln('Green background text');
      bcolor(output, blue);
      writeln('Blue background text');
      bcolor(output, cyan);
      writeln('Cyan background text');
      bcolor(output, yellow);
      writeln('Yellow background text');
      bcolor(output, magenta);
      writeln('Magenta background text');
      bcolor(output, white)

   end;
   readln;
   page;
   { scrolling tests }

   { fill screen with row order data }
   c := '1';
   for y := 1 to maxy(output) do begin

      cursor(output, 1, y); { index start of line }
      for x := 1 to maxx(output) do write(c); { output characters }
      if c <> '9' then c := succ(c) { next character }
      else c := '0' { start over }

   end;
   for y := 1 to maxy(output) do scroll(output, 0, 1);
   readln;
   page;
   { fill screen with row order data }
   c := '1';
   for y := 1 to maxy(output) do begin

      cursor(output, 1, y); { index start of line }
      for x := 1 to maxx(output) do write(c); { output characters }
      if c <> '9' then c := succ(c) { next character }
      else c := '0' { start over }

   end;
   for y := 1 to maxy(output) do scroll(output, 0, -1);
   readln;
   page;
   { fill screen with collumn order data }
   c := '1';
   for y := 1 to maxy(output) do begin

      cursor(output, 1, y); { index start of line }
      for x := 1 to maxx(output) do begin

         write(c); { output characters }
         if c <> '9' then c := succ(c) { next character }
         else c := '0' { start over }

      end

   end;
   for x := 1 to maxx(output) do scroll(output, 1, 0);
   readln;
   page;
   { fill screen with collumn order data }
   c := '1';
   for y := 1 to maxy(output) do begin

      cursor(output, 1, y); { index start of line }
      for x := 1 to maxx(output) do begin

         write(c); { output characters }
         if c <> '9' then c := succ(c) { next character }
         else c := '0' { start over }

      end

   end;
   for x := 1 to maxx(output) do scroll(output, -1, 0);
   { find minimum direction, x or y }
   if x < y then minlen := x else minlen := y;
   readln;
   page;
   { fill screen with uni data }
   c := '1';
   for y := 1 to maxy(output) do begin

      cursor(output, 1, y); { index start of line }
      for x := 1 to maxx(output) do begin

         write(c); { output characters }
         if c <> '9' then c := succ(c) { next character }
         else c := '0' { start over }

      end

   end;
   for i := 1 to minlen do scroll(output, 1, 1);
   readln;
   page;
   { fill screen with uni data }
   c := '1';
   for y := 1 to maxy(output) do begin

      cursor(output, 1, y); { index start of line }
      for x := 1 to maxx(output) do begin

         write(c); { output characters }
         if c <> '9' then c := succ(c) { next character }
         else c := '0' { start over }

      end

   end;
   for i := 1 to minlen do scroll(output, 1, -1);
   readln;
   page;
   { fill screen with uni data }
   c := '1';
   for y := 1 to maxy(output) do begin

      cursor(output, 1, y); { index start of line }
      for x := 1 to maxx(output) do begin

         write(c); { output characters }
         if c <> '9' then c := succ(c) { next character }
         else c := '0' { start over }

      end

   end;
   for i := 1 to minlen do scroll(output, -1, 1);
   readln;
   page;
   { fill screen with uni data }
   c := '1';
   for y := 1 to maxy(output) do begin

      cursor(output, 1, y); { index start of line }
      for x := 1 to maxx(output) do begin

         write(c); { output characters }
         if c <> '9' then c := succ(c) { next character }
         else c := '0' { start over }

      end

   end;
   for i := 1 to minlen do scroll(output, -1, -1);
   readln;
   { test complete }
   curvis(output, true); { restore cursor }
   ascroll(output, true); { enable automatic screen wrap }
   page;
   writeln('Test complete');
   readln

end.
