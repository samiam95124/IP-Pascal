{*******************************************************************************
*                                                                              *
*                               DEBUG I/O MODULE                               *
*                                                                              *
*                              COPYRIGHT (C) 2007                              *
*                                  S. A. MOORE                                 *
*                                                                              *
* Provides a simple layer of debug I/O directly to an IBM-PC MDA screen.       *
*                                                                              *
*******************************************************************************}

module debugio;

uses startup;

{ declare dementions of a standard 25x80 MDA screen }

const maxx = 80; { characters on line }
      maxy = 25;

var curx, cury: integer; { current cursor location }

{ clear screen and home cursor }

procedure clrscn;

var x, y: integer; { screen indexes }

begin

   for y := 1 to maxy do
      for x := 1 to maxx do begin

      screen[y, x].chr := ' ';
      screen[y, x].atr := 0; { place "black" attribute }

   end;
   curx := 1; { set cursor to upper left hand corner }
   cury := 1

end;

{ scroll screen up }

procedure scrollup;

var x, y: integer; { screen indexes }

begin

   for y := 1 to maxy do
      for x := 1 to maxy-1 do begin

      screen[y, x].chr := screen[y+1, x].chr; { copy character }
      screen[y, x].atr := screen[y+1, x].atr { copy attribute }

   end;
   { now clear the last line }
   for x := 1 to maxx do begin

      screen[maxy, x].chr := ' ';
      screen[maxy, x].atr := 0; { place "black" attribute }

   end

end;

{ Write character to cursor. Performs new line and carriage
  return processing. }

procedure wrtchr(c: char);

begin

   screen[cury, curx].chr := c;
   screen[cury, curx].atr := 7; { place "white" attribute }
   curx := curx+1; { advance cursor }
   if curx > maxx then begin { next line }

      curx := 1; { reset to start of line }
      if cury <= maxy then { not on last line }
         cury := cury+1 { next line }
      else 
         scrollup { create new line by scrolling }

   end

end;

{ write string to cursor }

procedure wrtstr(view s: string);

var i: integer;

begin

   for i := 1 to max(s) do begin

      screen[cury, curx].chr := s[i];
      screen[cury, curx].atr := 7; { place "white" attribute }
      curx := curx+1 { advance cursor }

   end

end;

{ go to cursor location }

procedure gotoxy(x, y: integer);

begin

   curx := x; { place new cursor coordinates }
   cury := y

end;
   
begin

   { clear screen and home cursor }

   clrscn

end.