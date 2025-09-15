{******************************************************************************
*                                                                             *
*                   TERMINAL MANAGEMENT INTERFACE LIBRARY                     *
*                                                                             *
*                            96/6 S. A. Moore                                 *
*                                                                             *
* This module is the stub for the terminal management layer. All calls are    *
* routed to the system level interface.                                       *
*                                                                             *
******************************************************************************}

module trmlib;

uses syslib;

const maxtim = 10; { maximum number of timers available }

type { colors displayable in text mode }
     color = (black, white, red, green, blue, cyan, yellow, magenta);
     joyhan = 1..4; { joystick handles }
     joynum = 0..4; { number of joysticks }
     joybut = 1..4; { joystick buttons }
     joybtn = 0..4; { joystick number of buttons }
     joyaxn = 0..3; { joystick axies }
     mounum = 0..4; { number of mice }
     mouhan = 1..4; { mouse handles }
     moubut = 1..4;  { mouse buttons }
     timhan = 1..maxtim; { timer handle }
     funky  = 1..100; { function keys }
     { events }
     evtcod = (etchar,    { ANSI character returned }
               etup,      { cursor up one line }
               etdown,    { down one line }
               etleft,    { left one character }
               etright,   { right one character }
               etleftw,   { left one word }
               etrightw,  { right one word }
               ethome,    { home of document }
               ethomes,   { home of screen }
               ethomel,   { home of line }
               etend,     { end of document }
               etends,    { end of screen }
               etendl,    { end of line }
               etscrl,    { scroll left one character }
               etscrr,    { scroll right one character }
               etscru,    { scroll up one line }
               etscrd,    { scroll down one line }
               etpagd,    { page down }
               etpagu,    { page up }
               ettab,     { tab }
               etenter,   { enter line }
               etinsert,  { insert block }
               etinsertl, { insert line }
               etinsertt, { insert toggle }
               etdel,     { delete block }
               etdell,    { delete line }
               etdelcf,   { delete character forward }
               etdelcb,   { delete character backward }
               etcopy,    { copy block }
               etcopyl,   { copy line }
               etcan,     { cancel current operation }
               etstop,    { stop current operation }
               etcont,    { continue current operation }
               etprint,   { print document }
               etprintb,  { print block }
               etprints,  { print screen }
               etfun,     { function key }
               etmenu,    { display menu }
               etmouba,   { mouse button assertion }
               etmoubd,   { mouse button deassertion }
               etmoumov,  { mouse move }
               ettim,     { timer matures }
               etjoyba,   { joystick button assertion }
               etjoybd,   { joystick button deassertion }
               etjoymov,  { joystick move }
               etterm);   { terminate program }
     { event record }
     evtrec = record

        { identifier of window for event, unused in terminal level }
        winid: ss_filhdl; { identifier of window for event }
        case etype: evtcod of { event type }

           { ANSI character returned }
           etchar:   (char:                char);
           { timer handle that matured }
           ettim:    (timnum:              timhan);
           etmoumov: (mmoun:               mouhan;   { mouse number }
                      moupx, moupy:        integer); { mouse movement }
           etmouba:  (amoun:               mouhan;   { mouse handle }
                      amoubn:              moubut);  { button number }
           etmoubd:  (dmoun:               mouhan;   { mouse handle }
                      dmoubn:              moubut);  { button number }
           etjoyba:  (ajoyn:               joyhan;   { joystick number }
                      ajoybn:              joybut);  { button number }
           etjoybd:  (djoyn:               joyhan;   { joystick number }
                      djoybn:              joybut);  { button number }
           etjoymov: (mjoyn:               joyhan;   { joystick number }
                      joypx, joypy, joypz: integer); { joystick coordinates }
           etfun:    (fkey:                funky);   { function key }
           etup, etdown, etleft, etright, etleftw, etrightw, ethome, ethomes,
           ethomel, etend, etends, etendl, etscrl, etscrr, etscru, etscrd,    
           etpagd, etpagu, ettab, etenter, etinsert, etinsertl, etinsertt, 
           etdel, etdell, etdelcf, etdelcb, etcopy, etcopyl, etcan, etstop,    
           etcont, etprint, etprintb, etprints, etmenu,
           etterm: (); { normal events }

        { end }

     end;

{ functions at this level }

procedure cursor(var f: text; x, y: integer); external;
function maxx(var f: text): integer; external;
function maxy(var f: text): integer; external;
procedure home(var f: text); external;
procedure del(var f: text); external;
procedure up(var f: text); external;
procedure down(var f: text); external;
procedure left(var f: text); external;
procedure right(var f: text); external;
procedure blink(var f: text; e: boolean); external;
procedure reverse(var f: text; e: boolean); external;
procedure underline(var f: text; e: boolean); external;
procedure superscript(var f: text; e: boolean); external;
procedure subscript(var f: text; e: boolean); external;
procedure italic(var f: text; e: boolean); external;
procedure bold(var f: text; e: boolean); external;
procedure strikeout(var f: text; e: boolean); external;
procedure standout(var f: text; e: boolean); external;
procedure fcolor(var f: text; c: color); external;
procedure bcolor(var f: text; c: color); external;
procedure auto(var f: text; e: boolean); external;
procedure curvis(var f: text; e: boolean); external;
procedure scroll(var f: text; x, y: integer); external;
function curx(var f: text): integer; external;
function cury(var f: text): integer; external;
function curbnd(var f: text): boolean; external;
procedure select(var f: text; u, d: integer); external;
procedure event(var f: text; var er: evtrec); external;
procedure timer(var f: text; i: timhan; t: integer; r: boolean); external;
procedure killtimer(var f: text; i: timhan); external;
function mouse(var f: text): mounum; external;
function mousebutton(var f: text; m: mouhan): moubut; external;
function joystick(var f: text): joynum; external;
function joybutton(var f: text; j: joyhan): joybtn; external;
function joyaxis(var f: text; j: joyhan): joyaxn; external;
procedure settab(var f: text; t: integer); external;
procedure restab(var f: text; t: integer); external;
procedure clrtab(var f: text); external;
function funkey(var f: text): funky; external;

begin
end.