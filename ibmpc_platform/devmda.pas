{*******************************************************************************
*                                                                              *
*                               MDA DRIVER MODULE                              *
*                                                                              *
*                              COPYRIGHT (C) 2007                              *
*                                  S. A. MOORE                                 *
*                                                                              *
* Gives a driver for an IBM-PC MDA screen, 80x25 characters.                   *
*                                                                              *
* To do:                                                                       *
*                                                                              *
* 1. Should be able to perform ANSI screen controls.                           *
*                                                                              *
*******************************************************************************}

module devmda;

uses startup, { startup section }
     devcal,  { device call module }
     devreg;  { device registry module }

private

{ declare dementions of a standard 25x80 MDA screen }

const maxx = 80; { characters on line }
      maxy = 25;

var curx, cury: integer; { current cursor location }
    dp:         drvptr; { device entry pointer }

{*******************************************************************************

Clear screen and home cursor

*******************************************************************************}

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

{*******************************************************************************

Scroll screen up

*******************************************************************************}

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

{*******************************************************************************

Write character to cursor

Writes a single character to the current cursor position. Performs new line and
carriage return processing.

*******************************************************************************}

procedure wrtchr(c: char);

begin

   if c = '\cr' then curx := 1 { carriage return, return to start of line }
   else if c = '\lf' then begin { process line feed }

      if cury <= maxy then { not on last line }
         cury := cury+1 { next line }
      else 
         scrollup { create new line by scrolling }

   end else begin { place character onscreen }

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

   end

end;

{*******************************************************************************

Write string to cursor

Write a string of characters to the console.

*******************************************************************************}

procedure wrtstr(view s: string);

var i: integer;

begin

   for i := 1 to max(s) do begin

      screen[cury, curx].chr := s[i];
      screen[cury, curx].atr := 7; { place "white" attribute }
      curx := curx+1 { advance cursor }

   end

end;

{*******************************************************************************

Go to cursor location

Locates the cursor at the given x and y position.

*******************************************************************************}

procedure gotoxy(x, y: integer);

begin

   curx := x; { place new cursor coordinates }
   cury := y

end;

{*******************************************************************************

Read mda device

Read is illegal, so we just return an error.

*******************************************************************************}

procedure read(var ba:  bytarr;  { array to read to }
                   pos: integer; { position to read at }
               var err: deverr); { return error }

begin

   refer(ba, pos);

   if pos <> 0 then err := de_istm { illegal for serial device }
   else err := de_red { cannot read device }

end;

{*******************************************************************************

Write MDA device

Writes a given number of bytes to the mda device.

*******************************************************************************}

procedure write(view ba:  bytarr;  { array to write from }
                     pos: integer; { position to write at }
                var err:  deverr); { return error }

var i: integer;

begin

   if pos <> 0 then err := de_istm { illegal for serial device }
   else begin

      for i := 1 to max(ba) do wrtchr(chr(ba[i])); { perform write }
      err := de_none { set no error }

   end

end;

{*******************************************************************************

Get MDA device length

This is an error on a serial device.

*******************************************************************************}

procedure length(var len: integer; { length of device returned }
                 var err: deverr); { return error }

begin

   refer(len);

   err := de_istm { illegal for serial device }

end;

{*******************************************************************************

Initalize device

*******************************************************************************}

begin

   refer(gotoxy, wrtstr);

   { register this device }

   getdrv(dp); { get a device registry entry }
   dp^.typ := dt_stream_write; { set write stream device }
   new(dp^.name, 3); { place device name }
   dp^.name^ := 'mda';

   { place driver calls }

   devcal_read_ptr(read, dp^.read);
   devcal_write_ptr(write, dp^.write);
   devcal_length_ptr(length, dp^.length);
   
   { register driver entry }

   regdrv(dp);

   { clear screen and home cursor }

   clrscn;

end.