{******************************************************************************
*                                                                             *
*                           GRAPHICS TEST PROGRAM                             *
*                                                                             *
*                    Copyright (C) 2005 Scott A. Moore                        *
*                                                                             *
* Tests various single window, unmanaged graphics.                            *
*                                                                             *
* Benchmark results, Athlon 64 3200+, BFG 6800 overclock:                     *
*                                                                             *
* Type                        Seconds     Per fig                             *
* --------------------------------------------------                          *
* line width 1                     7.484    7.484e-5                          *
* line width 10                   10.906   .00010906                          *
* rectangle width 1                7.313    7.313e-5                          *
* rectangle width 10               8.219    8.219e-5                          *
* rounded rectangle width 1       12.781   .00012781                          *
* rounded rectangle width 10      15.953   .00015953                          *
* filled rectangle                15.516   1.5516e-5                          *
* filled rounded rectangle         8.906    8.906e-5                          *
* ellipse width 1                 17.437   .00017437                          *
* ellipse width 10                22.078   .00022078                          *
* filled ellipse                  13.297   .00013297                          *
* arc width 1                      9.719    9.719e-5                          *
* arc width 10                    12.125   .00012125                          *
* filled arc                      10.422   .00010422                          *
* filled chord                      8.89     8.89e-5                          *
* filled triangle                 19.172   1.9172e-5                          *
* text                            10.922   .00010922                          *
* background invisible text       10.703   .00010703                          *
*                                                                             *
******************************************************************************}

program gratst(input, output, error);

uses gralib, 
     extlib,
     strlib;

label 99; { terminate }

const s1 = 'Moving string';
      s2 = 'Variable size string';
      s3 = 'Sizing test string';
      s4 = 'Justify test string';
      s5 = 'Invisible body text';
      s6 = 'Example text';
      coldiv = 6; { number of color divisions }
      colsqr = 20; { size of color square }
      off = false;
      on = true;
      degree = maxint div 360;

type bench = (bnline1,     { line width 1 }
              bnline10,    { line width 10 }
              bnrect1,     { rectangle width 1 }
              bnrect10,    { rectangle width 10 }
              bnrrect1,    { rounded rectangle width 1 }
              bnrrect10,   { rounded rectangle width 10 }
              bnfrect,     { filled rectangle }
              bnfrrect,    { filled rounded rectangle }
              bnellipse1,  { ellipse width 1 }
              bnellipse10, { ellipse width 10 }
              bnfellipse,  { filled ellipse }
              bnarc1,      { arc width 1 }
              bnarc10,     { arc width 10 }
              bnfarc,      { filled arc }
              bnfchord,    { filled chord }
              bnftriangle, { filled triangle }
              bntext,      { text }
              bntextbi,    { background invisible text }
              bnpict,      { picture draw }
              bnpictns);   { no scale picture draw }

var fns:       packed array [1..100] of char;
    x, y:      integer;
    xs, ys:    integer;
    i:         integer;
    dx, dy:    integer;
    ln:        integer;
    term:      boolean;
    w:         integer;
    l:         integer;
    a:         integer;
    r, g, b:   integer;
    c, c1, c2: color;
    lx, ly:    integer;
    x1, y1, x2, y2, x3, y3: integer;
    h:         integer;
    cnt:       integer;
    er:        evtrec;
    fsiz:      integer;
    aa, ab:    integer;
    rndseq:    integer; { random sequence seed }
    s:         integer;
    benchtab:  array [bench] of record { benchmark stats records }

                  iter: integer; { number of iterations performed }
                  time:  integer  { time in 100us for test }

               end;
    bi:        bench;

function rand: integer;

const a = 16807;
      m = 2147483647;

var gamma: integer;

begin

   gamma := a*(rndseq mod (m div a))-(m mod a)*(rndseq div (m div a));
   if gamma > 0 then rndseq := gamma else rndseq := gamma+m;
   rand := rndseq

end;

{ wait time in 100 microseconds }

procedure wait(t: integer);

var er: evtrec;

begin

   timer(output, 1, t, false);
   repeat event(input, er) until (er.etype = ettim) or (er.etype = etterm);
   if er.etype = etterm then goto 99

end;

{ wait time in 100 microseconds, with space terminate }

procedure waitchar(t: integer; var st: boolean);

var er: evtrec;

begin
    
   st := false; { set no space terminate }
   timer(output, 1, t, false);
   repeat event(input, er) until (er.etype = ettim) or (er.etype = etterm) or 
                                 (er.etype = etchar) or (er.etype = etenter);
   if er.etype = etchar then if er.char = ' ' then st := true;
   if er.etype = etenter then st := true;
   if er.etype = etterm then goto 99

end;

{ wait return to be pressed, or handle terminate }

procedure waitnext;

var er: evtrec; { event record }

begin

   repeat event(input, er) until (er.etype = etenter) or (er.etype = etterm);
   if er.etype = etterm then goto 99

end;

{ print centered string }

procedure prtcen(y: integer; view s: string);

begin

   cursor(output, (maxx(output) div 2)-(max(s) div 2), y);
   write(s)

end;

{ print centered string graphical }

procedure prtceng(y: integer; view s: string);

begin

   cursorg(output, (maxxg(output) div 2)-(strsiz(s) div 2), y);
   write(s)

end;


{ print all printable characters }

procedure prtall;

var c: char;
    s: packed array 1 of char;

begin

   for c := ' ' to '}' do begin

      s[1] := 'c';
      if curxg+strsiz(s) > maxxg then cursorg(1, curyg+chrsizy);
      write(c)

   end;
   writeln

end;

{ draw a character grid }

procedure chrgrid;

var x, y: integer;

begin

   fcolor(yellow);
   y := 1;
   while y < maxyg do begin

      line(1, y, maxxg, y);
      y := y+chrsizy

   end;
   x := 1;
   while x < maxxg do begin

      line(x, 1, x, maxyg);
      x := x+chrsizx

   end;
   fcolor(black)

end;

{ draw polar coordinate line }

procedure pline(a:      integer;  { angle of line }
                o:      integer;  { length of line }
                cx, cy: integer;  { center of circle in x and y }
                w:      integer); { width of line }

var ex, ey: integer; { line start and end }

{ find rectangular coordinates from polar, relative to center of circle,
  with given diameter }

procedure rectcord(    a:    integer;  { angle, 0-359 }
                       r:    integer;  { radius of circle }
                   var x, y: integer); { returns rectangular coordinate }

var angle: real; { angle in radian measure }

begin

   angle := a*0.01745329; { find radian measure }
   x := round(sin(angle)*r); { find distance x }
   y := round(cos(angle)*r) { find distance y }

end;

begin

   rectcord(a, o, ex, ey); { find endpoint of line }
   linewidth(output, w); { set width }
   line(output, cx, cy, cx+ex, cy-ey); { draw line }

end;

{ draw centered justified text }

procedure justcenter(view s: string; l: integer);

var i, x: integer;

begin

   x := maxxg(output) div 2-l div 2;
   cursorg(x, curyg);
   writejust(s, l);
   writeln;
   rect(x, curyg, x+l-1, curyg+chrsizy-1);
   for i := 2 to len(s) do 
      line(x+justpos(s, i, l), curyg, x+justpos(s, i, l), curyg+chrsizy-1);
   writeln

end;

{ draw 10's grid }

procedure grid;

var x, y: integer;

begin

   linewidth(1);
   fcolor(cyan);
   x := 10;
   while x <= maxxg do begin

      line(x, 1, x, maxyg);
      x := x+10

   end;
   y := 10;
   while y <= maxyg do begin

      line(1, y, maxxg, y);
      y := y+10

   end;
   fcolor(black)
              
end;

{ This is the square2 program }

procedure squares;

const squaresize = 81;
      halfsquare = squaresize div 2;
      maxsquare = 10;
      reprate = 1; { number of moves per frame, should be low }

type balrec = record { square data record }

        x, y:   integer; { current position }
        lx, ly: integer; { last position }
        xd, yd: integer; { deltas }
        c:      color    { color }
   
     end;
     balinx = 1..maxsquare; { index for squares }
   
var cd:     boolean; { current display flip select }
    baltbl: array [1..maxsquare] of balrec; { square data table }
    i:      balinx; { index for table }
    nx, ny: integer; { temp coordinates holders }
    rc:     integer; { repetition counter }
    done:   boolean; { done flag }

procedure chkbrk;

var er: evtrec; { event record }

begin

   repeat event(input, er) until (er.etype = etframe) or (er.etype = etterm) or
                                 (er.etype = etchar) or (er.etype = etenter);
   if er.etype = etterm then goto 99;
   if (er.etype = etchar) or (er.etype = etenter) then 
      done := true { terminate }

end;

procedure drawsquare(c: color; x, y: integer);

begin

   fcolor(output, c); { set color }
   frect(output, x-halfsquare+1, y-halfsquare+1, x+halfsquare-1, y+halfsquare-1)

end;
   
procedure movesquare(s: balinx);

begin

   with baltbl[s] do begin

      nx := x+xd; { trial move square }
      ny := y+yd;
      { check out of bounds and reverse direction }
      if (nx < halfsquare) or (nx > maxxg(output)-halfsquare+1) then xd := -xd;
      if (ny < halfsquare) or (ny > maxyg(output)-halfsquare+1) then yd := -yd;
      x := x+xd; { move square }
      y := y+yd

   end

end;

begin

   { initalize square data }
   for i := 1 to maxsquare do with baltbl[i] do begin

      x := rand mod (maxxg(output)-squaresize)+halfsquare;
      y := rand mod (maxyg(output)-squaresize)+halfsquare;
      if rand mod 2 = 0 then xd := +1 else xd := -1;
      if rand mod 2 = 0 then yd := +1 else yd := -1;
      lx := x; { set last position to same }
      ly := y;
      c := color(rand mod 6+ord(red)) { set random color }

   end;
   curvis(output, false); { turn off cursor }
   cd := false; { set 1st display }
   { place squares on display }
   for i := 1 to maxsquare do drawsquare(baltbl[i].c, baltbl[i].x, baltbl[i].y);
   frametimer(output, true); { start frame timer }
   done := false; { set not done }
   while not done do begin

      { select display and update surfaces }
      select(output, ord(not cd)+1, ord(cd)+1);
      page;
      fover;
      fcolor(black);
      prtcen(maxy(output), 'Animation test');
      fxor;
      { save old positions }
      for i := 1 to maxsquare do with baltbl[i] do begin

         lx := x; { save last position }
         ly := y

      end;
      { move squares }
      for rc := 1 to reprate do { repeats per frame }
         for i := 1 to maxsquare do movesquare(i); { process squares }
      { draw squares }
      for i := 1 to maxsquare do with baltbl[i] do drawsquare(c, x, y);
      cd := not cd; { flip display and update surfaces }
      chkbrk { check complete }

   end;
   select(1, 1) { restore buffer surfaces }

end;

{ draw standard graphical test, which is all the figures possible
  arranged on the screen }

procedure graphtest(lw: integer); { line width }

var fsiz: integer;
    x, y: integer;

begin

   auto(off);
   font(font_sign);
   fsiz := chrsizy; { save character size to restore }
   fontsiz(30);
   bcolor(yellow);
   cursorg(maxxg(output) div 2-strsiz(s6) div 2, curyg);
   writeln(s6);
   writeln;
   fcolor(magenta);
   linewidth(lw);
   y := 70;
   x := 20;
   rect(x, y, x+100, y+100);
   fcolor(green);
   x := x+120;
   frect(x, y, x+100, y+100);
   fcolor(yellow);
   x := x+120;
   ftriangle(x, y+100, x+50, y, x+100, y+100);
   fcolor(red);
   x := x+120;
   rrect(x, y, x+100, y+100, 20, 20);
   fcolor(magenta);
   x := x+120;
   arc(x, y, x+100, y+100, 0, maxint div 4);
   fcolor(green);
   farc(x, y, x+100, y+100, maxint div 2, maxint div 2+maxint div 4);
   y := y+120;
   x := 20;
   fcolor(blue);
   frect(x, y, x+100, y+100);
   x := x+120;
   fcolor(magenta);
   frrect(x, y, x+100, y+100, 20, 20);
   x := x+120;
   fcolor(green);
   ellipse(x, y, x+100, y+100);
   x := x+120;
   fcolor(yellow);
   fellipse(x, y, x+100, y+100);
   x := x+120;
   fcolor(blue);
   fchord(x, y, x+100, y+100, 0, maxint div 2);
   y := y+120;
   fcolor(red);
   linewidth(1);
   line(20, y, maxxg-20, y);
   y := y+10;
   fcolor(green);
   linewidth(3);
   line(20, y, maxxg-20, y);
   y := y+10;
   fcolor(blue);
   linewidth(7);
   line(20, y, maxxg-20, y);
   y := y+20;
   fcolor(magenta);
   linewidth(15);
   line(20, y, maxxg-20, y);
   linewidth(1);
   fontsiz(fsiz); { restore font size }
   fcolor(black);
   bcolor(white);
   font(font_term)

end;

{ test line speed }

procedure linespeed(w: integer; t: integer; var s: integer);

var i: integer;
    c: integer;

begin

   auto(output, false);
   curvis(output, false);
   page;
   linewidth(output, w);
   c := clock;
   for i := 1 to t do begin

      fcolor(output, color(rand mod 6+ord(red)));
      line(output, rand mod maxxg(output)+1, rand mod maxyg(output)+1,
                   rand mod maxxg(output)+1, rand mod maxyg(output)+1);
 
   end;
   s := elapsed(c);
   fcolor(black)

end;

{ test rectangle speed }

procedure rectspeed(w: integer; t: integer; var s: integer);

var i: integer;
    c: integer;

begin

   auto(output, false);
   curvis(output, false);
   page;
   linewidth(output, w);
   c := clock;
   for i := 1 to t do begin

      fcolor(output, color(rand mod 6+ord(red)));
      rect(output, rand mod maxxg(output)+1, rand mod maxyg(output)+1,
                   rand mod maxxg(output)+1, rand mod maxyg(output)+1);
 
   end;
   s := elapsed(c);
   fcolor(black)

end;

{ test rounded rectangle speed }

procedure rrectspeed(w: integer; t: integer; var s: integer);

var i: integer;
    c: integer;

begin

   auto(output, false);
   curvis(output, false);
   page;
   linewidth(output, w);
   c := clock;
   for i := 1 to t do begin

      fcolor(output, color(rand mod 6+ord(red)));
      rrect(output, rand mod maxxg(output)+1, rand mod maxyg(output)+1,
                    rand mod maxxg(output)+1, rand mod maxyg(output)+1,
                    rand mod 100+1, rand mod 100+1);
 
   end;
   s := elapsed(c);
   fcolor(black)

end;

{ test filled rectangle speed }

procedure frectspeed(t: integer; var s: integer);

var i: integer;
    c: integer;

begin

   auto(output, false);
   curvis(output, false);
   page;
   c := clock;
   for i := 1 to t do begin

      fcolor(output, color(rand mod 6+ord(red)));
      frect(output, rand mod maxxg(output)+1, rand mod maxyg(output)+1,
                    rand mod maxxg(output)+1, rand mod maxyg(output)+1);
 
   end;
   s := elapsed(c);
   fcolor(black)

end;

{ test filled rounded rectangle speed }

procedure frrectspeed(t: integer; var s: integer);

var i: integer;
    c: integer;

begin

   auto(output, false);
   curvis(output, false);
   page;
   c := clock;
   for i := 1 to t do begin

      fcolor(output, color(rand mod 6+ord(red)));
      frrect(output, rand mod maxxg(output)+1, rand mod maxyg(output)+1,
                     rand mod maxxg(output)+1, rand mod maxyg(output)+1,
                     rand mod 100+1, rand mod 100+1);
 
   end;
   s := elapsed(c);
   fcolor(black)

end;

{ test ellipse speed }

procedure ellipsespeed(w: integer; t: integer; var s: integer);

var i: integer;
    c: integer;

begin

   auto(output, false);
   curvis(output, false);
   page;
   linewidth(output, w);
   c := clock;
   for i := 1 to t do begin

      fcolor(output, color(rand mod 6+ord(red)));
      ellipse(output, rand mod maxxg(output)+1, rand mod maxyg(output)+1,
                    rand mod maxxg(output)+1, rand mod maxyg(output)+1);
 
   end;
   s := elapsed(c);
   fcolor(black)

end;

{ test filled ellipse speed }

procedure fellipsespeed(t: integer; var s: integer);

var i: integer;
    c: integer;

begin

   auto(output, false);
   curvis(output, false);
   page;
   c := clock;
   for i := 1 to t do begin

      fcolor(output, color(rand mod 6+ord(red)));
      fellipse(output, rand mod maxxg(output)+1, rand mod maxyg(output)+1,
                    rand mod maxxg(output)+1, rand mod maxyg(output)+1);
 
   end;
   s := elapsed(c);
   fcolor(black)

end;

{ test arc speed }

procedure arcspeed(w: integer; t: integer; var s: integer);

var i:      integer;
    c:      integer;
    sa, ea: integer;

begin

   auto(output, false);
   curvis(output, false);
   page;
   linewidth(output, w);
   c := clock;
   for i := 1 to t do begin

      repeat

         sa := rand;
         ea := rand

      until ea > sa;
      fcolor(output, color(rand mod 6+ord(red)));
      arc(output, rand mod maxxg(output)+1, rand mod maxyg(output)+1,
                  rand mod maxxg(output)+1, rand mod maxyg(output)+1,
                  sa, ea)
 
   end;
   s := elapsed(c);
   fcolor(black)

end;
   
{ test filled arc speed }

procedure farcspeed(t: integer; var s: integer);

var i:      integer;
    c:      integer;
    sa, ea: integer;

begin

   auto(output, false);
   curvis(output, false);
   page;
   c := clock;
   for i := 1 to t do begin

      repeat

         sa := rand;
         ea := rand

      until ea > sa;
      fcolor(output, color(rand mod 6+ord(red)));
      farc(output, rand mod maxxg(output)+1, rand mod maxyg(output)+1,
                   rand mod maxxg(output)+1, rand mod maxyg(output)+1,
                   sa, ea)
 
   end;
   s := elapsed(c);
   fcolor(black)

end;

{ test filled chord speed }

procedure fchordspeed(t: integer; var s: integer);

var i:      integer;
    c:      integer;
    sa, ea: integer;

begin

   auto(output, false);
   curvis(output, false);
   page;
   c := clock;
   for i := 1 to t do begin

      repeat
     
         sa := rand;
         ea := rand
     
      until ea > sa;
      fcolor(output, color(rand mod 6+ord(red)));
      fchord(output, rand mod maxxg(output)+1, rand mod maxyg(output)+1,
                     rand mod maxxg(output)+1, rand mod maxyg(output)+1,
                     sa, ea)
 
   end;
   s := elapsed(c);
   fcolor(black)

end;

{ test filled triangle speed }

procedure ftrianglespeed(t: integer; var s: integer);

var i: integer;
    c: integer;

begin

   auto(output, false);
   curvis(output, false);
   page;
   c := clock;
   for i := 1 to t do begin

      fcolor(output, color(rand mod 6+ord(red)));
      ftriangle(output, rand mod maxxg(output)+1, rand mod maxyg(output)+1,
                        rand mod maxxg(output)+1, rand mod maxyg(output)+1,
                        rand mod maxxg(output)+1, rand mod maxyg(output)+1);
 
   end;
   s := elapsed(c);
   fcolor(black)

end;

{ test text speed }

procedure ftextspeed(t: integer; var s: integer);

var i: integer;
    c: integer;

begin

   auto(output, false);
   curvis(output, false);
   page;
   c := clock;
   for i := 1 to t do begin

      fcolor(output, color(rand mod 6+ord(red)));
      bcolor(output, color(rand mod 6+ord(red)));
      cursorg(rand mod maxxg(output)+1, rand mod maxyg(output)+1);
      write('Test text')
 
   end;
   s := elapsed(c);
   fcolor(black);
   bcolor(white)

end;

{ test picture draw speed }

procedure fpictspeed(t: integer; var s: integer);

var i: integer;
    c: integer;

begin

   auto(output, false);
   curvis(output, false);
   page;
   loadpict(1, 'mypic');
   c := clock;
   for i := 1 to t do begin

      picture(1, rand mod maxxg(output)+1, rand mod maxyg(output)+1,
                 rand mod maxxg(output)+1, rand mod maxyg(output)+1)
 
   end;
   s := elapsed(c);
   fcolor(black)

end;

{ test picture draw speed, no scaling }

procedure fpictnsspeed(t: integer; var s: integer);

var i:      integer;
    c:      integer;
    x, y:   integer;
    xs, ys: integer;

begin

   auto(output, false);
   curvis(output, false);
   page;
   loadpict(1, 'mypic');
   xs := pictsizx(1);
   ys := pictsizy(1);
   c := clock;
   for i := 1 to t do begin

      x := rand mod maxxg(output)+1;
      y := rand mod maxyg(output)+1;
      picture(1, x, y, x+xs-1, y+ys-1);
 
   end;
   s := elapsed(c);
   fcolor(black)

end;

begin

   rndseq := 1; { set random number generator inital to mid sequence }
   curvis(false);
   writeln('Graphics screen test vs. 0.1');
   writeln;
   writeln('Screen size in characters: x -> ', maxx:1, ' y -> ', maxy:1);
   writeln('            in pixels:     x -> ', maxxg:1, ' y -> ', maxyg:1);
   writeln('Size of character in default font: x -> ', chrsizx:1, ' y -> ', chrsizy:1); 
   writeln('Dots per meter: dpmx: ', dpmx:1, ' dpmy: ', dpmy:1);
   writeln('Aspect ratio: ', dpmx/dpmy:1:2);
   prtcen(maxy(output), 
          'Press return to start test (and to pass each pattern)');
   waitnext;

   { ************************ Graphical figures test ************************* }

   page;
   grid;
   writeln;
   bover;
   graphtest(1);
   binvis;
   prtcen(maxy(output), 'Graphical figures test, linewidth = 1');
   waitnext;

   page;
   grid;
   writeln;
   bover;
   graphtest(2);
   binvis;
   prtcen(maxy(output), 'Graphical figures test, linewidth = 2');
   waitnext;

   page;
   grid;
   writeln;
   bover;
   graphtest(3);
   binvis;
   prtcen(maxy(output), 'Graphical figures test, linewidth = 3');
   waitnext;

   page;
   grid;
   writeln;
   bover;
   graphtest(5);
   binvis;
   prtcen(maxy(output), 'Graphical figures test, linewidth = 5');
   waitnext;

   page;
   grid;
   writeln;
   bover;
   graphtest(11);
   binvis;
   prtcen(maxy(output), 'Graphical figures test, linewidth = 11');
   waitnext;

   { ***************************** Standard Fonts test *********************** }

   page;
   chrgrid;
   prtcen(maxy(output), 'Standard fonts test');
   auto(false);
   home;
   binvis;
   fontnam(font_term, fns);
   if len(fns) > 0 then begin
 
      font(font_term);
      writeln('This is the terminal font: System name: "', fns:0, 
              '" Size x -> ', chrsizx:1, ' y -> ', chrsizy:1); 
      prtall;
      writeln

   end else begin

      writeln('There is no terminal font');
      writeln

   end;
   fontnam(font_book, fns);
   if len(fns) > 0 then begin

      font(font_book);
      fontsiz(20);
      writeln('This is the book font: System name: "', fns:0, 
              '" Size x -> ', chrsizx:1, ' y -> ', chrsizy:1); 
      prtall;
      writeln

   end else begin

      writeln('There is no book font');
      writeln

   end;
   fontnam(font_sign, fns);
   if len(fns) > 0 then begin

      font(font_sign);
      fontsiz(20);
      writeln('This is the sign font: System name: "', fns:0, 
              '" Size x -> ', chrsizx:1, ' y -> ', chrsizy:1); 
      prtall;
      writeln

   end else begin

      writeln('There is no sign font');
      writeln

   end;
   fontnam(font_tech, fns);
   if len(fns) > 0 then begin

      font(font_tech);
      fontsiz(20);
      writeln('This is the technical font: System name: "', fns:0, 
              '" Size x -> ', chrsizx:1, ' y -> ', chrsizy:1); 
      prtall;
      writeln

   end else begin

      writeln('There is no technical font');
      writeln

   end;
   font(font_term);
   writeln('Complete');
   waitnext;

   { ********************** Graphical cursor movement test ******************* }

   page;
   prtcen(maxy(output), 'Graphical cursor movement test');
   x := 1;
   y := 1;
   i := 10000;
   dx := +1;
   dy := +1;
   ln := strsiz(s1);
   term := false;
   while not term do begin

      cursorg(x, y);
      write(s1);
      xs := x;
      ys := y;
      x := x+dx;
      y := y+dy;
      if (x < 1) or (x+ln-1 > maxxg) then begin

         x := xs;
         dx := -dx

      end;
      if (y < 1) or (y+chrsizy-1 > maxyg) then begin

         y := ys;
         dy := -dy

      end;
      waitchar(100, term);
      cursorg(xs, ys);
      fcolor(white);
      write(s1);
      fcolor(black)

   end;

   { *************************** Vertical lines test ************************* }

   page;
   grid;
   prtcen(maxy(output), 'Vertical lines test');
   y := 20;
   w := 1;
   while (y < maxyg-30) and (w < 15) do begin

      linewidth(w);
      line(20, y, maxxg-20, y);
      y := y+30;
      w := w+1

   end;
   linewidth(1);
   waitnext;

   { ************************* Horizontal lines test ************************* }

   page;
   grid;
   prtcen(maxy(output), 'Horizontal lines test');
   x := 20;
   w := 1;
   y := maxyg-20;
   y := y-y mod 10;
   while (x < maxxg-20) and (w < 30) do begin

      linewidth(w);
      line(x, 20, x, y);
      x := x+30;
      w := w+1

   end;
   linewidth(1);
   waitnext;

   { **************************** Polar lines test *************************** }

   page;
   grid;
   binvis;
   prtcen(maxy(output), 'Polar lines test');
   bover;
   x := maxxg div 2;
   x := x-(x mod 10);
   y := maxyg div 2;
   y := y-(y mod 10);
   if maxxg > maxyg then l := maxyg div 2-40
                    else l := maxxg div 2-40;
   l := l-(l mod 10);
   w := 1;
   fcolor(blue);
   ellipse(x-l, y-l, x+l, y+l);
   fcolor(black);
   while w < 10 do begin

      a := 0; { set angle }
      while a < 360 do begin

         pline(a, l, x, y, w);
         a := a+10;

      end;
      home;
      writeln('Line width: ', w:1);
      w := w+1;
      waitnext

   end;
   linewidth(1);

   { ************************* Progressive lines test ************************ }

   page;
   grid;
   line(10, 10, 100, 100);
   line(100, 10);
   line(200, 50);
   line(10, 100);
   line(50, 230);
   line(20, 130);
   line(250, 80);
   line(100, 40);
   line(160, 180);
   line(80, 160);
   line(120, 30);
   line(90, 90);
   line(20, 50);
   binvis;
   fcolor(black);
   prtcen(maxy(output), 'Progressive lines test');
   waitnext;

   { ******************************* Color test 1 ****************************** }

   page;
   y := 1; { set 1st row }
   r := 0; { set colors }
   g := 0;
   b := 0;
   while y < maxyg do begin

      x := 1;
      while x < maxxg do begin

         fcolor(r, g, b);
         frect(x, y, x+colsqr-1, y+colsqr-1);
         x := x+colsqr;
         if r <= maxint-maxint div coldiv then r := r+maxint div coldiv
         else begin

            r := 0;
            if g <= maxint-maxint div coldiv then g := g+maxint div coldiv
            else begin

               g := 0;
               if b <= maxint-maxint div coldiv then b := b+maxint div coldiv
               else b := 0

            end

         end

      end;
      y := y+colsqr

   end;
   fcolor(black);
   prtcen(maxy(output), 'Color test 1');
   waitnext;

   { ******************************* Color test 2 ****************************** }

   page;
   x := 1; { set 2st collumn }
   while x < maxxg do begin

      fcolor(maxint div maxxg*x, 0, 0);
      line(x, 1, x, maxyg);
      x := x+1

   end;
   binvis;
   fcolor(black);
   prtcen(maxy(output), 'Color test 2');
   waitnext;

   { ******************************* Color test 3 ****************************** }

   page;
   x := 1; { set 2st collumn }
   while x < maxxg do begin

      fcolor(0, maxint div maxxg*x, 0);
      line(x, 1, x, maxyg);
      x := x+1

   end;
   binvis;
   fcolor(black);
   prtcen(maxy(output), 'Color test 3');
   waitnext;

   { ******************************* Color test 4 ****************************** }

   page;
   x := 1; { set 2st collumn }
   while x < maxxg do begin

      fcolor(0, 0, maxint div maxxg*x);
      line(x, 1, x, maxyg);
      x := x+1

   end;
   binvis;
   fcolor(black);
   prtcen(maxy(output), 'Color test 4');
   waitnext;

   { ***************************** Rectangle test **************************** }

   page;
   grid;
   l := 10;
   x := maxxg div 2; { find center }
   y := maxyg div 2;
   x := x-x mod 10;
   y := y-y mod 10;
   w := 1;
   c := black;
   while (l < maxxg div 2) and (l < maxyg div 2) do begin

      fcolor(c);
      linewidth(w);
      rect(x-l, y-l, x+l, y+l);
      l := l+20;
      w := w+1;
      if c < magenta then c := succ(c)
      else c := black;
      if c = white then c := succ(c)

   end;
   linewidth(1);
   fcolor(black);
   binvis;
   prtcen(maxy(output), 'Rectangle test');
   waitnext;

   { ************************ Filled rectangle test 1 ************************ }

   page;
   grid;
   if maxxg > maxyg then l := maxyg div 2-10 else l := maxxg div 2-10;
   l := l-l mod 10;
   x := maxxg div 2; { find center }
   y := maxyg div 2;
   x := x-x mod 10;
   y := y-y mod 10;
   c := black;
   while (l >= 10) and (l < maxyg div 2) do begin

      fcolor(c);
      frect(x-l, y-l, x+l, y+l);
      l := l-20;
      if c < magenta then c := succ(c)
      else c := black;
      if c = white then c := succ(c)

   end;
   fcolor(black);
   binvis;
   prtcen(maxy(output), 'Filled rectangle test 1');
   waitnext;

   { ************************ Filled rectangle test 2 ************************ }

   page;
   grid;
   l := 10;
   x := 20;
   y := 20;
   c := black;
   while y+l*2 < maxyg-20 do begin

      while x+l*2 < maxxg-20 do begin

         fcolor(c);
         frect(x, y, x+l*2, y+l*2);
         x := x+l*2+20;
         l := l+5;
         if c < magenta then c := succ(c)
         else c := black;
         if c = white then c := succ(c)

      end;
      x := 10;
      y := y+l*2+10

   end;
   fcolor(black);
   binvis;
   prtcen(maxy(output), 'Filled rectangle test 2');
   waitnext;

   { ************************* Rounded rectangle test ************************ }
       
   binvis;
   r := 1;
   while r < 100 do begin

      page;
      grid;
      l := 10;
      x := maxxg div 2; { find center }
      y := maxyg div 2;
      x := x-x mod 10;
      y := y-y mod 10;
      w := 1;
      c := black;
      writeln('r: ', r:1);
      while (l < maxxg div 2) and (l < maxyg div 2) do begin
     
         fcolor(c);
         linewidth(w);
         rrect(x-l, y-l, x+l, y+l, r, r);
         l := l+20;
         w := w+1;
         if c < magenta then c := succ(c)
         else c := black;
         if c = white then c := succ(c)
     
      end;
      linewidth(1);
      fcolor(black);
      prtcen(maxy(output), 'Rounded rectangle test');
      waitnext;
      r := r+10

   end;

   { ******************** Filled rounded rectangle test 1 ******************** }

   binvis;
   r := 1;
   while r < 100 do begin

      page;
      grid;
      if maxxg > maxyg then l := maxyg div 2-10 else l := maxxg div 2-10;
      l := l-l mod 10;
      x := maxxg div 2; { find center }
      y := maxyg div 2;
      x := x-x mod 10;
      y := y-y mod 10;
      c := black;
      writeln('r: ', r:1);
      while (l >= 10) and (l < maxyg div 2) do begin
   
         fcolor(c);
         frrect(x-l, y-l, x+l, y+l, r, r);
         l := l-20;
         if c < magenta then c := succ(c)
         else c := black;
         if c = white then c := succ(c)
   
      end;
      fcolor(black);
      prtcen(maxy(output), 'Filled rounded rectangle test 1');
      waitnext;
      r := r+10

   end;

   { ******************** Filled rounded rectangle test 2 ******************** }

   binvis;
   r := 1;
   while r < 100 do begin

      page;
      grid;
      l := 10;
      x := 20;
      y := 20;
      c := black;
      writeln('r: ', r:1);
      while y+l*2 < maxyg-20 do begin

         while x+l*2 < maxxg-20 do begin

            fcolor(c);
            frrect(x, y, x+l*2, y+l*2, r, r);
            x := x+l*2+20;
            l := l+5;
            if c < magenta then c := succ(c)
            else c := black;
            if c = white then c := succ(c)

         end;
         x := 10;
         y := y+l*2+10

      end;
      fcolor(black);
      binvis;
      prtcen(maxy(output), 'Filled rounded rectangle test 2');
      waitnext;
      r := r+10

   end;

   { ****************************** Ellipse test ***************************** }

   binvis;
   w := 1;
   while w < 10 do begin

      page;
      grid;
      lx := maxxg div 2-10;
      lx := lx-lx mod 10;
      ly := maxyg div 2-10;
      ly := ly-ly mod 10;
      x := maxxg div 2; { find center }
      y := maxyg div 2;
      x := x-x mod 10;
      y := y-y mod 10;
      c := black;
      writeln('width: ', w:1);
      while (lx >= 10) and (ly >= 10) do begin

         fcolor(c);
         linewidth(w);
         ellipse(x-lx, y-ly, x+lx, y+ly);
         lx := lx-20;
         ly := ly-20;
         if c < magenta then c := succ(c)
         else c := black;
         if c = white then c := succ(c)

      end;
      fcolor(black);
      prtcen(maxy(output), 'Ellipse test');
      waitnext;
      w := w+1

   end;
   linewidth(1);

   { ************************** Filled ellipse test 1 ************************** }

   page;
   grid;
   lx := maxxg div 2-10;
   lx := lx-lx mod 10;
   ly := maxyg div 2-10;
   ly := ly-ly mod 10;
   x := maxxg div 2; { find center }
   y := maxyg div 2;
   x := x-x mod 10;
   y := y-y mod 10;
   c := black;
   while (lx >= 10) and (ly >= 10) do begin

      fcolor(c);
      fellipse(x-lx, y-ly, x+lx, y+ly);
      lx := lx-20;
      ly := ly-20;
      if c < magenta then c := succ(c)
      else c := black;
      if c = white then c := succ(c)

   end;
   fcolor(black);
   prtcen(maxy(output), 'Filled ellipse test 1');
   waitnext;

   { ************************ Filled ellipse test 2 ************************ }

   page;
   grid;
   l := 10;
   x := 20;
   y := 20;
   c := black;
   while y+l*2 < maxyg-20 do begin

      while x+l*2 < maxxg-20 do begin

         fcolor(c);
         fellipse(x, y, x+l*2, y+l*2);
         x := x+l*2+20;
         l := l+5;
         if c < magenta then c := succ(c)
         else c := black;
         if c = white then c := succ(c)

      end;
      x := 10;
      y := y+l*2+10

   end;
   fcolor(black);
   binvis;
   prtcen(maxy(output), 'Filled ellipse test 2');
   waitnext;

   { ******************************* Arc test 1 ******************************** }

   binvis;
   w := 1;
   while w < 10 do begin

      page;
      grid;
      a := 0;
      c := black;
      i := 10;
      write('Linewidth: ', w:1);
      while (i < maxxg div 2) and (i < maxyg div 2) do begin

         a := 0;
         while a <= maxint-maxint div 10 do begin
      
            fcolor(c);
            linewidth(w);
            arc(i, i, maxxg-i, maxyg-i, a, a+maxint div 10);
            a := a+maxint div 5;
            if c < magenta then c := succ(c)
            else c := black;
            if c = white then c := succ(c)
      
         end;
         i := i+20

      end;
      fcolor(black);
      prtcen(maxy(output), 'Arc test 1');
      waitnext;
      w := w+1

   end;

   { ************************ Arc test 2 ************************ }

   binvis;
   w := 1;
   while w < 10 do begin

      page;
      grid;
      l := 10;
      x := 20;
      y := 20;
      c := black;
      aa := 0;
      ab := maxint div 360*90;
      write('Linewidth: ', w:1);
      while y+l*2 < maxyg-20 do begin

         while x+l*2 < maxxg-20 do begin

            linewidth(w);
            arc(x, y, x+l*2, y+l*2, aa, ab);
            x := x+l*2+20;
            l := l+10;

         end;
         x := 10;
         y := y+l*2+10

      end;
      binvis;
      prtcen(maxy(output), 'Arc test 2');
      waitnext;
      w := w+1

   end;

   { ************************ Arc test 3 ************************ }

   binvis;
   w := 1;
   while w < 10 do begin

      page;
      grid;
      l := 30;
      x := 20;
      y := 20;
      c := black;
      aa := 0;
      ab := 10;
      write('Linewidth: ', w:1);
      while (y+l*2 < maxyg-20) and (ab <= 360) do begin

         while (x+l*2 < maxxg-20) and (ab <= 360) do begin

            linewidth(w);
            arc(x, y, x+l*2, y+l*2, aa*degree, ab*degree);
            x := x+l*2+20;
            ab := ab+10

         end;
         x := 10;
         y := y+l*2+20

      end;
      binvis;
      prtcen(maxy(output), 'Arc test 3');
      waitnext;
      w := w+1

   end;

   { ************************ Arc test 4 ************************ }

   binvis;
   w := 1;
   while w < 10 do begin

      page;
      grid;
      l := 30;
      x := 20;
      y := 20;
      c := black;
      aa := 0;
      ab := 360;
      write('Linewidth: ', w:1);
      while (y+l*2 < maxyg-20) and (ab <= 360) do begin

         while (x+l*2 < maxxg-20) and (ab <= 360) do begin

            linewidth(w);
            arc(x, y, x+l*2, y+l*2, aa*degree, ab*degree);
            x := x+l*2+20;
            aa := aa+10

         end;
         x := 10;
         y := y+l*2+20

      end;
      binvis;
      prtcen(maxy(output), 'Arc test 4');
      waitnext;
      w := w+1

   end;

   { **************************** Filled arc test 1 **************************** }

   page;
   grid;
   a := 0;
   c := black;
   a := 0;
   x := maxxg-10;
   x := x-x mod 10;
   y := maxyg-10;
   y := y-y mod 10;
   while a <= maxint-maxint div 10 do begin
   
      fcolor(c);
      farc(10, 10, x, y, a, a+maxint div 10);
      a := a+maxint div 5;
      if c < magenta then c := succ(c)
      else c := black;
      if c = white then c := succ(c)
   
   end;
   binvis;
   fcolor(black);
   prtcen(maxy(output), 'Filled arc test 1');
   waitnext;

   { ************************ filled arc test 2 ************************ }

   page;
   grid;
   l := 10;
   x := 20;
   y := 20;
   c := black;
   aa := 0;
   ab := maxint div 360*90;
   while y+l*2 < maxyg-20 do begin

      while x+l*2 < maxxg-20 do begin

         fcolor(c);
         farc(x, y, x+l*2, y+l*2, aa, ab);
         x := x+l*2+20;
         l := l+10;
         if c < magenta then c := succ(c)
         else c := black;
         if c = white then c := succ(c)

      end;
      x := 20;
      y := y+l*2+10

   end;
   binvis;
   fcolor(black);
   prtcen(maxy(output), 'Filled arc test 2');
   waitnext;

   { ************************ Filled arc test 3 ************************ }

   page;
   grid;
   l := 30;
   x := 20;
   y := 20;
   c := black;
   aa := 0;
   ab := 10;
   while (y+l*2 < maxyg-20) and (ab <= 360) do begin

      while (x+l*2 < maxxg-20) and (ab <= 360) do begin

         fcolor(c);
         farc(x, y, x+l*2, y+l*2, aa*degree, ab*degree);
         x := x+l*2+20;
         ab := ab+10;
         if c < magenta then c := succ(c)
         else c := black;
         if c = white then c := succ(c)

      end;
      x := 20;
      y := y+l*2+20

   end;
   binvis;
   fcolor(black);
   prtcen(maxy(output), 'Arc test 3');
   waitnext;

   { ************************ Filled arc test 4 ************************ }

   page;
   grid;
   l := 30;
   x := 20;
   y := 20;
   c := black;
   aa := 0;
   ab := 360;
   while (y+l*2 < maxyg-20) and (ab <= 360) do begin

      while (x+l*2 < maxxg-20) and (ab <= 360) do begin

         fcolor(c);
         farc(x, y, x+l*2, y+l*2, aa*degree, ab*degree);
         x := x+l*2+20;
         aa := aa+10;
         if c < magenta then c := succ(c)
         else c := black;
         if c = white then c := succ(c)

      end;
      x := 20;
      y := y+l*2+20

   end;
   binvis;
   fcolor(black);
   prtcen(maxy(output), 'Arc test 3');
   waitnext;

   { *************************** Filled chord test 1 *************************** }

   page;
   grid;
   a := 0;
   c := black;
   a := 0;
   i := 8;
   x := maxxg-10;
   x := x-x mod 10;
   y := maxyg-10;
   y := y-y mod 10;
   while a <= maxint-maxint div i do begin
   
      fcolor(c);
      fchord(10, 10, x, y, a, a+maxint div i);
      a := a+maxint div (i div 2);
      if c < magenta then c := succ(c)
      else c := black;
      if c = white then c := succ(c)
   
   end;
   fcolor(black);
   prtcen(maxy(output), 'Filled chord test 1');
   waitnext;

   { ************************ filled chord test 2 ************************ }

   page;
   grid;
   l := 10;
   x := 20;
   y := 20;
   c := black;
   aa := 0;
   ab := maxint div 360*90;
   while y+l*2 < maxyg-20 do begin

      while x+l*2 < maxxg-20 do begin

         fcolor(c);
         fchord(x, y, x+l*2, y+l*2, aa, ab);
         x := x+l*2+20;
         l := l+10;
         if c < magenta then c := succ(c)
         else c := black;
         if c = white then c := succ(c)

      end;
      x := 20;
      y := y+l*2+10

   end;
   binvis;
   fcolor(black);
   prtcen(maxy(output), 'Filled chord test 2');
   waitnext;

   { ************************ Filled chord test 3 ************************ }

   page;
   grid;
   l := 30;
   x := 20;
   y := 20;
   c := black;
   aa := 0;
   ab := 10;
   while (y+l*2 < maxyg-20) and (ab <= 360) do begin

      while (x+l*2 < maxxg-20) and (ab <= 360) do begin

         fcolor(c);
         fchord(x, y, x+l*2, y+l*2, aa*degree, ab*degree);
         x := x+l*2+20;
         ab := ab+10;
         if c < magenta then c := succ(c)
         else c := black;
         if c = white then c := succ(c)

      end;
      x := 20;
      y := y+l*2+20

   end;
   binvis;
   fcolor(black);
   prtcen(maxy(output), 'Filled chord test 3');
   waitnext;

   { ************************ Filled chord test 4 ************************ }

   page;
   grid;
   l := 30;
   x := 20;
   y := 20;
   c := black;
   aa := 0;
   ab := 360;
   while (y+l*2 < maxyg-20) and (ab <= 360) do begin

      while (x+l*2 < maxxg-20) and (ab <= 360) do begin

         fcolor(c);
         fchord(x, y, x+l*2, y+l*2, aa*degree, ab*degree);
         x := x+l*2+20;
         aa := aa+10;
         if c < magenta then c := succ(c)
         else c := black;
         if c = white then c := succ(c)

      end;
      x := 20;
      y := y+l*2+20

   end;
   binvis;
   fcolor(black);
   prtcen(maxy(output), 'Filled chord test 3');
   waitnext;

   { ************************** Filled triangle test 1 ************************* }

   page;
   grid;
   x1 := 10;
   y1 := maxyg-10;
   y1 := y1-y1 mod 10;
   x2 := maxxg div 2;
   y2 := 10;
   x3 := maxxg-10;
   x3 := x3-x3 mod 10;
   y3 := maxyg-10;
   y3 := y3-y3 mod 10;
   c := black;
   i := 40;
   while (x1 <= x3-10) and (y2 <= y3-10) do begin

      fcolor(c);
      ftriangle(x1, y1, x2, y2, x3, y3);
      x1 := x1+i;
      y1 := y1-i div 2;
      y2 := y2+i;
      x3 := x3-i;
      y3 := y3-i div 2;
      if c < magenta then c := succ(c)
      else c := black;
      if c = white then c := succ(c)

   end;
   fcolor(black);
   binvis;
   prtcen(maxy(output), 'Filled triangle test 1');
   waitnext;

   { ************************** Filled triangle test 2 ************************* }

   page;
   grid;
   x := 20;
   y := 20;
   l := 20;
   while y < maxyg-20-l do begin

      while (y < maxyg-20-l) and (x < maxxg-20-l) do begin

         fcolor(c);
         ftriangle(x, y+l, x+l div 2, y, x+l, y+l);
         x := x+l+20;
         l := l+10;
         if c < magenta then c := succ(c)
         else c := black;
         if c = white then c := succ(c)
          
      end;
      x := 20;
      y := y+l+20

   end;
   fcolor(black);
   binvis;
   prtcen(maxy(output), 'Filled triangle test 2');
   waitnext;

   { ************************** Filled triangle test 3 ************************* }

   page;
   grid;
   x := 20;
   y := 20;
   l := 20;
   while y < maxyg-20-l do begin

      while (y < maxyg-20-l) and (x < maxxg-20-l) do begin

         fcolor(c);
         ftriangle(x, y+l, x, y, x+l, y+l);
         x := x+l+20;
         l := l+10;
         if c < magenta then c := succ(c)
         else c := black;
         if c = white then c := succ(c)
          
      end;
      x := 20;
      y := y+l+20

   end;
   fcolor(black);
   binvis;
   prtcen(maxy(output), 'Filled triangle test 3');
   waitnext;

   { ************************** Filled triangle test 4 ************************* }

   page;
   grid;
   x := 20;
   y := 20;
   l := 20;
   while y < maxyg-20-l do begin

      while (y < maxyg-20-l) and (x < maxxg-20-l) do begin

         fcolor(c);
         ftriangle(x, y+l, x, y, x+l, y);
         x := x+l+20;
         l := l+10;
         if c < magenta then c := succ(c)
         else c := black;
         if c = white then c := succ(c)
          
      end;
      x := 20;
      y := y+l+20

   end;
   fcolor(black);
   binvis;
   prtcen(maxy(output), 'Filled triangle test 4');
   waitnext;

   { ************************** Filled triangle test 5 ************************* }

   page;
   grid;
   x := 20;
   y := 20;
   l := 20;
   while y < maxyg-20-l do begin

      while (y < maxyg-20-l) and (x < maxxg-20-l) do begin

         fcolor(c);
         ftriangle(x+l div 2, y+l, x, y, x+l, y);
         x := x+l+20;
         l := l+10;
         if c < magenta then c := succ(c)
         else c := black;
         if c = white then c := succ(c)
          
      end;
      x := 20;
      y := y+l+20

   end;
   fcolor(black);
   binvis;
   prtcen(maxy(output), 'Filled triangle test 5');
   waitnext;

   { ************************** Filled triangle test 6 ************************* }

   page;
   grid;
   x := 20;
   y := 20;
   l := 20;
   c := black;
   while y < maxyg-20-l do begin

      while (y < maxyg-20-l) and (x < maxxg-20-l) do begin

         fcolor(c);
         ftriangle(x+l, y+l, x, y, x+l, y);
         x := x+l+20;
         l := l+10;
         if c < magenta then c := succ(c)
         else c := black;
         if c = white then c := succ(c)
          
      end;
      x := 20;
      y := y+l+20

   end;
   fcolor(black);
   binvis;
   prtcen(maxy(output), 'Filled triangle test 6');
   waitnext;

   { ************************** Filled triangle test 7 ************************* }

   page;
   grid;
   c := black;
   fcolor(c);
   ftriangle(50, 50, 50, 100, 200, 50);
   if c < magenta then c := succ(c)
   else c := black;
   if c = white then c := succ(c);
   fcolor(c);
   ftriangle(50, 100, 300, 200, 200, 50);
   if c < magenta then c := succ(c)
   else c := black;
   if c = white then c := succ(c);
   fcolor(c);
   ftriangle(200, 50, 300, 200, 350, 100);
   if c < magenta then c := succ(c)
   else c := black;
   if c = white then c := succ(c);
   fcolor(c);
   ftriangle(350, 100, 400, 300, 300, 200);
   if c < magenta then c := succ(c)
   else c := black;
   if c = white then c := succ(c);
   binvis;
   fcolor(black);
   prtcen(maxy(output), 'Filled triangle test 7');
   waitnext;

   { ************************** Filled triangle test 8 ************************* }

   page;
   grid;
   fcolor(black);
   ftriangle(50, 50, 50, 100, 200, 50);
   ftriangle(50, 100, 300, 200, 200, 50);
   ftriangle(200, 50, 300, 200, 350, 100);
   ftriangle(350, 100, 400, 300, 300, 200);
   binvis;
   prtcen(maxy(output), 'Filled triangle test 8');
   waitnext;

   { ************************** Filled triangle test 9 ************************* }

   page;
   grid;
   fcolor(black);
   c := black;
   ftriangle(50, 50, 100, 50, 100, 100);
   if c < magenta then c := succ(c)
   else c := black;
   if c = white then c := succ(c);
   fcolor(c);
   ftriangle(200, 100, 200, 200);
   if c < magenta then c := succ(c)
   else c := black;
   if c = white then c := succ(c);
   fcolor(c);
   ftriangle(250, 100, 300, 200);
   if c < magenta then c := succ(c)
   else c := black;
   if c = white then c := succ(c);
   fcolor(c);
   ftriangle(200, 200, 250, 250);
   binvis;
   fcolor(black);
   prtcen(maxy(output), 'Filled triangle test 9, progressive singles');
   waitnext;

   { ************************** Filled triangle test 9 ************************* }

   page;
   grid;
   fcolor(black);
   c := black;
   ftriangle(50, 100, 50, 50, 100, 100);
   if c < magenta then c := succ(c)
   else c := black;
   if c = white then c := succ(c);
   fcolor(c);
   ftriangle(150, 50);
   if c < magenta then c := succ(c)
   else c := black;
   if c = white then c := succ(c);
   fcolor(c);
   ftriangle(200, 160);
   if c < magenta then c := succ(c)
   else c := black;
   if c = white then c := succ(c);
   fcolor(c);
   ftriangle(250, 100);
   if c < magenta then c := succ(c)
   else c := black;
   if c = white then c := succ(c);
   fcolor(c);
   ftriangle(300, 100);
   binvis;
   fcolor(black);
   prtcen(maxy(output), 'Filled triangle test 10, progressive strips');
   waitnext;

   { **************************** Font sizing test *************************** }

   page;
   grid;
   fsiz := chrsizy; { save character size to restore }
   h := 10;
   auto(off);
   font(font_sign);
   c1 := black;
   c2 := blue;
   bover;
   while curyg+chrsizy <= maxyg-20 do begin

      fcolor(c1);
      bcolor(c2);
      fontsiz(h);
      writeln(s2);
      h := h+5;
      if c1 < magenta then c1 := succ(c1)
      else c1 := black;
      if c1 = white then c1 := succ(c1);
      if c2 < magenta then c2 := succ(c2)
      else c2 := black;
      if c2 = white then c2 := succ(c2)

   end;
   fontsiz(fsiz); { restore font size }
   fcolor(black);
   bcolor(white);
   font(font_term);
   binvis;
   prtcen(maxy(output), 'Font sizing test');
   waitnext;

   { ***************************** Font list test **************************** }

   page;
   grid;
   writeln('Number of fonts: ', fonts);
   writeln;
   i := 1;
   cnt := fonts;
   while cnt > 0 do begin

      { find defined font code }
      repeat

         fontnam(i, fns);
         if len(fns) = 0 then i := i+1
 
      until len(fns) > 0;
      writeln(i:1, ': ', fns:0);
      if cury >= maxy then begin { screen overflows }

         write('Press return to continue');
         waitnext;
         page;
         grid

      end;
      i := i+1; { next font code }
      cnt := cnt-1 { count fonts }

   end;
   writeln;
   writeln('List complete');
   waitnext;

   { *************************** Font examples test ************************** }

   page;
   grid;
   auto(off);
   bcolor(cyan);
   bover;
   i := 1;
   cnt := fonts;
   while cnt > 0 do begin

      { find defined font code }
      repeat

         fontnam(i, fns);
         if len(fns) = 0 then i := i+1
 
      until len(fns) > 0;
      font(i);
      writeln(i:1, ': ', fns:0);
      if cury >= maxy then begin { screen overflows }

         font(font_term);
         write('Press return to continue');
         waitnext;
         bcolor(white);
         page;
         grid;
         bcolor(cyan)

      end;
      i := i+1; { next font code }
      cnt := cnt-1 { count fonts }

   end;
   bcolor(white);
   font(font_term);
   binvis;
   writeln;
   writeln('List complete');
   waitnext;

   { ************************** Extended effects test ************************ }

   page;
   grid;
   auto(off);
   font(font_sign);
   condensed(on);
   writeln('Condensed');
   extended(on);
   writeln('Extended');
   extended(off);
   xlight(on);
   writeln('Extra light');
   xlight(off);
   xbold(on);
   writeln('Extra bold');
   xbold(off);
   hollow(on);
   writeln('Hollow');
   hollow(off);
   raised(on);
   writeln('Raised');
   raised(off);
   font(font_term);
   prtcen(maxy(output), 'Extended effects test');
   waitnext;

   { ****************** Character sizes and positions test ******************* }

   page;
   grid;
   auto(off);
   fsiz := chrsizy; { save character size to restore }
   font(font_sign);
   fontsiz(30);
   writeln('Size of test string: ', strsiz(s3));
   writeln;
   x := (maxxg(output) div 2)-(strsiz(s3) div 2);
   cursorg(x, curyg); { go to centered }
   bcolor(cyan);
   bover;
   writeln(s3);
   rect(x, curyg, x+strsiz(s3)-1, curyg+chrsizy-1);
   for i := 2 to len(s3) do 
      line(x+chrpos(s3, i), curyg, x+chrpos(s3, i), curyg+chrsizy-1);
   writeln;

   l := strsiz(s4); { get minimum sizing for string }
   justcenter(s4, l);
   justcenter(s4, l+40);
   justcenter(s4, l+80);

   fontsiz(fsiz); { restore font size }
   font(font_term);
   binvis;
   prtcen(maxy(output), 'Character sizes and positions');
   waitnext;
   bcolor(white);

   { ************************* Graphical tabbing test ************************ }

   page;
   grid;
   auto(off);
   font(font_term);
   for i := 1 to 5 do begin

      for x := 1 to i do write('\ht');
      writeln('Terminal tab: ', i:1)

   end;
   clrtab;
   for i := 1 to 5 do settabg(i*43);
   for i := 1 to 5 do begin

      for x := 1 to i do write('\ht');
      writeln('Graphical tab number: ', i:1, ' position: ', i*43:1)

   end;
   restabg(2*43);
   restabg(4*43);
   writeln;
   writeln('After removing tabs ', 2*43, ' and ', 4*43);
   writeln;
   for i := 1 to 5 do begin

      for x := 1 to i do write('\ht');
      writeln('Graphical tab number: ', i:1)

   end;
   prtcen(maxy(output), 'Graphical tabbing test');
   waitnext;

   { ************************** Picture draw test **************************** }

   page;
   grid;
   loadpict(1, 'mypic');
   writeln('Picture size for 1: x: ', pictsizx(1):1, ' y: ', pictsizy(1):1);
   loadpict(2, 'mypic1.bmp');
   writeln('Picture size for 2: x: ', pictsizx(2):1, ' y: ', pictsizy(2):1);
   picture(1, 50, 50, 100, 100);
   picture(1, 100, 100, 200, 200);
   picture(1, 50, 200, 100, 350);
   picture(2, 200, 50, 250, 100);
   picture(2, 250, 100, 350, 200);
   picture(2, 250, 250, 450, 300);
   delpict(1);
   delpict(2);
   prtcen(maxy(output), 'Picture draw test');
   waitnext;

   { ********************** Invisible foreground test ************************ }

   page;
   grid;
   writeln;
   bover;
   finvis;
   graphtest(1);
   binvis;
   prtcen(maxy(output), 'Invisible foreground test');
   waitnext;
   fover;

   { ********************** Invisible background test ************************ }

   page;
   grid;
   writeln;
   binvis;
   fover;
   graphtest(1);
   binvis;
   prtcen(maxy(output), 'Invisible background test');
   waitnext;
   bover;

   { ************************** Xor foreground test ************************** }

   page;
   grid;
   writeln;
   bover;
   fxor;
   graphtest(1);
   binvis;
   prtcen(maxy(output), 'Xor foreground test');
   waitnext;
   fover;

   { ************************* Xor background test *************************** }

   page;
   grid;
   writeln;
   bxor;
   fover;
   graphtest(1);
   binvis;
   prtcen(maxy(output), 'Xor background test');
   waitnext;
   bover;

   { ************************** Graphical scrolling test **************************** }

   page;
   grid;
   binvis;
   prtcen(1, 'Use up, down, right and left keys to scroll by pixel');
   prtcen(2, 'Hit enter to continue');
   prtcen(3, 'Note that edges will clear to green as screen moves');
   prtcen(maxy(output), 'Graphical scrolling test');
   bcolor(green);
   repeat

      event(er);
      if er.etype = etup then scrollg(0, -1);
      if er.etype = etdown then scrollg(0, 1);
      if er.etype = etright then scrollg(1, 0);
      if er.etype = etleft then scrollg(-1, 0);
      if er.etype = etterm then goto 99

   until er.etype = etenter;
   bover;
   bcolor(white);

   { ************************** Graphical mouse movement test **************************** }

   page;
   prtcen(1, 'Move the mouse around');
   prtcen(3, 'Hit Enter to continue');
   prtcen(maxy(output), 'Graphical mouse movement test');
   x := -1;
   y := -1;
   repeat

      event(er);
      if er.etype = etmoumovg then begin

         if (x > 0) and (y > 0) then line(x, y, er.moupxg, er.moupyg);
         x := er.moupxg;
         y := er.moupyg

      end;
      if er.etype = etterm then goto 99

   until er.etype = etenter;

   { ************************** Animation test **************************** }

   squares;

   { ************************** View offset test **************************** }

if false then begin { view offsets are not completely working }
   page;
   auto(off);
   viewoffg(-(maxxg div 2), -(maxyg div 2));
   grid;
   fcolor(green);
   frect(0, 0, 100, 100);
   cursorg(1, -(maxyg div 2));
   fcolor(black);
   writeln('View offset test');
   writeln;
   writeln('The 1,1 origin is now at screen center');
   waitnext;
   viewoffg(0, 0);
end;

   { ************************** View scale test **************************** }

if false then begin { view scales are not completely working }
   page;
   auto(off);
   viewscale(0.5);
   grid;
   fcolor(green);
   frect(0, 0, 100, 100);
   prtcen(1, 'Logical coordinates are now 1/2 size');
   prtcen(maxy(output), 'View scale text');
   waitnext;
end;

   { ************************** Benchmarks **************************** }

   i := 100000;
   linespeed(1, i, s);
   with benchtab[bnline1] do begin { place stats }

      iter := i;
      time := s

   end;
   writeln('Line speed for width: 1, ', i:1, ' lines: ', s*0.0001, 
           ' seconds');
   writeln('Seconds per line', s*0.0001/i);
   waitnext;

   i := 100000;
   linespeed(10, i, s);
   with benchtab[bnline10] do begin { place stats }

      iter := i;
      time := s

   end;
   writeln('Line speed for width: 10, ', i:1, ' lines: ', s*0.0001, 
           ' seconds');
   writeln('Seconds per line', s*0.0001/i);
   waitnext;

   i := 100000;
   rectspeed(1, i, s);
   with benchtab[bnrect1] do begin { place stats }

      iter := i;
      time := s

   end;
   writeln('Rectangle speed for width: 1, ', i:1, ' lines: ', s*0.0001, 
           ' seconds');
   writeln('Seconds per rectangle', s*0.0001/i);
   waitnext;

   i := 100000;
   rectspeed(10, i, s);
   with benchtab[bnrect10] do begin { place stats }

      iter := i;
      time := s

   end;
   writeln('Rectangle speed for width: 10, ', i:1, ' lines: ', s*0.0001, 
           ' seconds');
   writeln('Seconds per rectangle', s*0.0001/i);
   waitnext;

   i := 100000;
   rrectspeed(1, i, s);
   with benchtab[bnrrect1] do begin { place stats }

      iter := i;
      time := s

   end;
   writeln('Rounded rectangle speed for width: 1, ', i:1, ' lines: ', s*0.0001, 
           ' seconds');
   writeln('Seconds per rounded rectangle', s*0.0001/i);
   waitnext;

   i := 100000;
   rrectspeed(10, i, s);
   with benchtab[bnrrect10] do begin { place stats }

      iter := i;
      time := s

   end;
   writeln('Rounded rectangle speed for width: 10, ', i:1, ' lines: ', s*0.0001,
           ' seconds');
   writeln('Seconds per rounded rectangle', s*0.0001/i);
   waitnext;

   i := 1000000;
   frectspeed(i, s);
   with benchtab[bnfrect] do begin { place stats }

      iter := i;
      time := s

   end;
   writeln('Filled rectangle speed, ', i:1, ' lines: ', s*0.0001, 
           ' seconds');
   writeln('Seconds per filled rectangle', s*0.0001/i);
   waitnext;

   i := 100000;
   frrectspeed(i, s);
   with benchtab[bnfrrect] do begin { place stats }

      iter := i;
      time := s

   end;
   writeln('Filled rounded rectangle speed, ', i:1, ' lines: ', s*0.0001, 
           ' seconds');
   writeln('Seconds per filled rounded rectangle', s*0.0001/i);
   waitnext;

   i := 100000;
   ellipsespeed(1, i, s);
   with benchtab[bnellipse1] do begin { place stats }

      iter := i;
      time := s

   end;
   writeln('Ellipse speed for width: 1, ', i:1, ' lines: ', s*0.0001, 
           ' seconds');
   writeln('Seconds per ellipse', s*0.0001/i);
   waitnext;

   i := 100000;
   ellipsespeed(10, i, s);
   with benchtab[bnellipse10] do begin { place stats }

      iter := i;
      time := s

   end;
   writeln('Ellipse speed for width: 10, ', i:1, ' lines: ', s*0.0001, 
           ' seconds');
   writeln('Seconds per ellipse', s*0.0001/i);
   waitnext;

   i := 100000;
   fellipsespeed(i, s);
   with benchtab[bnfellipse] do begin { place stats }

      iter := i;
      time := s

   end;
   writeln('Filled ellipse speed, ', i:1, ' lines: ', s*0.0001, 
           ' seconds');
   writeln('Seconds per filled ellipse', s*0.0001/i);
   waitnext;

   i := 100000;
   arcspeed(1, i, s);
   with benchtab[bnarc1] do begin { place stats }

      iter := i;
      time := s

   end;
   writeln('Arc speed for width: 1, ', i:1, ' lines: ', s*0.0001, 
           ' seconds');
   writeln('Seconds per arc', s*0.0001/i);
   waitnext;

   i := 100000;
   arcspeed(10, i, s);
   with benchtab[bnarc10] do begin { place stats }

      iter := i;
      time := s

   end;
   writeln('Arc speed for width: 10, ', i:1, ' lines: ', s*0.0001, 
           ' seconds');
   writeln('Seconds per arc', s*0.0001/i);
   waitnext;

   i := 100000;
   farcspeed(i, s);
   with benchtab[bnfarc] do begin { place stats }

      iter := i;
      time := s

   end;
   writeln('Filled arc speed, ', i:1, ' lines: ', s*0.0001, 
           ' seconds');
   writeln('Seconds per filled arc', s*0.0001/i);
   waitnext;

   i := 100000;
   fchordspeed(i, s);
   with benchtab[bnfchord] do begin { place stats }

      iter := i;
      time := s

   end;
   writeln('Filled chord speed, ', i:1, ' lines: ', s*0.0001, 
           ' seconds');
   writeln('Seconds per filled chord', s*0.0001/i);
   waitnext;

   i := 1000000;
   ftrianglespeed(i, s);
   with benchtab[bnftriangle] do begin { place stats }

      iter := i;
      time := s

   end;
   writeln('Filled triangle speed, ', i:1, ' lines: ', s*0.0001, 
           ' seconds');
   writeln('Seconds per filled triangle', s*0.0001/i);
   waitnext;

   bover;
   fover;
   i := 100000;
   ftextspeed(i, s);
   with benchtab[bntext] do begin { place stats }

      iter := i;
      time := s

   end;
   home;
   writeln('Text speed, with overwrite, ', i:1, ' lines: ', s*0.0001, 
           ' seconds');
   writeln('Seconds per write', s*0.0001/i);
   waitnext;

   binvis;
   fover;
   i := 100000;
   ftextspeed(i, s);
   with benchtab[bntextbi] do begin { place stats }

      iter := i;
      time := s

   end;
   home;
   bover;
   writeln('Text speed, invisible background, ', i:1, ' lines: ', s*0.0001, 
           ' seconds');
   writeln('Seconds per write', s*0.0001/i);
   waitnext;

   i := 1000;
   fpictspeed(i, s);
   with benchtab[bnpict] do begin { place stats }

      iter := i;
      time := s

   end;
   writeln('Picture draw speed, ', i:1, ' lines: ', s*0.0001, 
           ' seconds');
   writeln('Seconds per picture', s*0.0001/i);
   waitnext;

   i := 1000;
   fpictnsspeed(i, s);
   with benchtab[bnpictns] do begin { place stats }

      iter := i;
      time := s

   end;
   writeln('No scale picture draw speed, ', i:1, ' lines: ', s*0.0001, 
           ' seconds');
   writeln('Seconds per picture', s*0.0001/i);
   waitnext;

   { output table }

   writeln(error);
   writeln(error, 'Benchmark table');
   writeln(error);
   writeln(error, 'Type                        Seconds     Per fig');
   writeln(error, '--------------------------------------------------');
   for bi := bnline1 to bnpictns do with benchtab[bi] do begin

      case bi of { benchmark type }

         bnline1:     write(error, 'line width 1                ');
         bnline10:    write(error, 'line width 10               ');
         bnrect1:     write(error, 'rectangle width 1           ');
         bnrect10:    write(error, 'rectangle width 10          ');
         bnrrect1:    write(error, 'rounded rectangle width 1   ');
         bnrrect10:   write(error, 'rounded rectangle width 10  ');
         bnfrect:     write(error, 'filled rectangle            ');
         bnfrrect:    write(error, 'filled rounded rectangle    ');
         bnellipse1:  write(error, 'ellipse width 1             ');
         bnellipse10: write(error, 'ellipse width 10            ');
         bnfellipse:  write(error, 'filled ellipse              ');
         bnarc1:      write(error, 'arc width 1                 ');
         bnarc10:     write(error, 'arc width 10                ');
         bnfarc:      write(error, 'filled arc                  ');
         bnfchord:    write(error, 'filled chord                ');
         bnftriangle: write(error, 'filled triangle             ');
         bntext:      write(error, 'text                        ');
         bntextbi:    write(error, 'background invisible text   ');
         bnpict:      write(error, 'Picture draw                ');
         bnpictns:    write(error, 'No scaling picture draw     ');

      end;
      writere(error, time*0.0001, 10);
      write(error, '  ');
      writere(error, time*0.0001/iter, 10);
      writeln(error)
         
   end;

   99: { terminate }

   page;
   auto(off);
   font(font_sign);
   fontsiz(50);
   prtceng(maxy div 2, 'Test complete');

end.
