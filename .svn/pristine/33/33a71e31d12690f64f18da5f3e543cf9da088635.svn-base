{*******************************************************************************
*                                                                              *
*                           GRAPHICAL CLOCK PROGRAM                            *
*                                                                              *
* Analog clock program in IP Pascal windowed graphical mode.                   *
* Presents an analog clock at any scale. Clicking the mouse anywhere within    *
* clock turns the move/size frame on and off. This allows the clock to be      *
* placed at a convient location and then have the frame removed.               *
*                                                                              *
*******************************************************************************}

program clockg(input, output);

uses gralib, { windowed graphical }
     extlib; { extentions }

var er:   evtrec;  { event record }
    frm:  boolean; { frame on/off }

{ draw polar coordinate line }

procedure pline(a:      integer;  { angle of hand }
                o:      integer;  { length of hand }
                i:      integer;  { distance from center }
                cx, cy: integer;  { center of circle in x and y }
                w:      integer); { width of hand }

var sx, sy, ex, ey: integer; { line start and end }

{ find rectangular coordinates from polar, relative to center of circle,
  with given diameter }

procedure rectcord(    a:    integer;  { angle, 0-359 }
                       d:    integer;  { diameter of circle }
                   var x, y: integer); { returns rectangular coordinate }

var angle: real; { angle in radian measure }

begin

   angle := a*0.01745329; { find radian measure }
   x := round(sin(angle)*(d/2)); { find distance x }
   y := round(cos(angle)*(d/2)) { find distance y }

end;

begin

   rectcord(a, i, sx, sy); { find startpoint of line }
   rectcord(a, o, ex, ey); { find endpoint of line }
   linewidth(output, w); { set width }
   line(output, cx+sx, cy-sy, cx+ex, cy-ey); { draw second hand }

end;

{ update time }

procedure update(cx, cy: integer;  { center of clock in x and y }
                 d:      integer); { diameter of clock face }

const hoursec = 60*60;      { number of seconds in an hour }
      daysec  = hoursec*24; { number of seconds in a day }

var t:    integer; { current time }
    s:    integer; { seconds }
    m:    integer; { minutes }
    h:    integer; { hours }
    x, y: integer; { coordinates }
    ds:   pstring; { storage for date }

begin

   { break down time to seconds, minutes, hours }
   t := local(time); { get local time }
   ds := dates(t); { get the date in ASCII from that }
   t := t mod daysec; { find number of seconds in day }
   { if before 2000, find from remaining seconds }
   if t < 0 then t := daysec+t;
   h := t div hoursec; { find hours }
   t := t mod hoursec; { subtract hours }
   m := t div 60; { find minutes }
   s := t mod 60; { find seconds }
   { display time on hands }
   pline(s*(360 div 60), d, 0, cx, cy, 1); { draw second hand }
   pline(m*(360 div 60), d, 0, cx, cy, 3); { draw minute hand }
   pline(h*(360 div 12)+m div 2, d div 2, 0, cx, cy, 3); { draw hour hand }
   { place date centered, 1/4 down from the clock center (1/8 radius) }
   cursorg(output, cx-strsiz(output, ds^) div 2, cy+d div 8);
   write(output, ds^:0); { write date to clock face }
   dispose(ds) { release date string }

end;

{ draw clock }

procedure drawclock;

var d:      integer; { circle diameter }
    cx, cy: integer; { center of circle }
    i:      integer; { index }
    t:      integer; { length of tick mark }

begin

   { erase background }
   fcolor(output, white);
   frect(output, 1, 1, maxxg(output), maxyg(output));
   fcolor(output, black);
   { find diameter of circle by shorter of two axies }
   if maxxg(output) > maxyg(output) then d := maxyg(output)-20
   else d := maxxg(output)-20;
   { find center of clock, in center of window }
   cx := maxxg(output) div 2;
   cy := maxyg(output) div 2;
   t := d div 20; { find tick mark length }
   { draw tick marks on clock }
   for i := 1 to 12 do 
      pline(360 div 12*i, d, d-(t+t*ord(i mod 3 = 0)), cx, cy, 3);
   update(cx, cy, d) { update face time }

end;

begin

   curvis(output, false); { turn off cursor }
   buffer(output, false); { turn off buffering }
   auto(output, false); { turn off wrap/scroll }
   binvis(output); { set no background overwrite on text }
   font(output, font_sign); { use proportional font }
   bold(output, true); { turn on bold }
   frm := true; { set frame on }
   timer(output, 1, 10000, true); { set second update timer }
   { loop for events }
   repeat

      event(input, er); { get next event }
      { if either a redraw or a timer tick, draw the clock }
      if (er.etype = etredraw) or (er.etype = ettim) then drawclock;
      { if the user clicks the mouse anywhere in the clock, flip the frame
        on and off }
      if er.etype = etmouba then begin 

         frm := not frm; { flip frame status }
         sizable(output, frm);
         sysbar(output, frm)

      end

   until er.etype = etterm

end.
