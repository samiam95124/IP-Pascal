{******************************************************************************
*                                                                             *
*                      TRANSPARENT SCREEN CONTROL MODULE                      *
*                     FOR ANSI COMPLIANT TERMINALS (IBMPC)                    *
*                                                                             *
*                              4/96 S. A. Moore                               *
*                                                                             *
* This module implements the level 1 section of the standard terminal calls   *
* for an ANSI compliant terminal running under windows 95. Although this is   *
* dependent on Windows 95, theoretically, it should run via a serial console  *
* port. Mouse control is enabled, but this is very unlikely to be able to run *
* in such a configuration. It will work in a local window, however. I don't   *
* know what Windows does if the console is serial.                            *
* Note: This package won't work if the actual screen size does not match the  *
* set screen size, because we rely on the ANSI downward scroll.               *
*                                                                             *
* Things to do:                                                               *
*                                                                             *
* 1. Right now, the input and output files as passed to the screen control    *
* routines are ignored. Instead, they should be checked to actually contain   *
* those files.                                                                *
*                                                                             *
* 2. Ansilib should parse command line parameters. These will appear right    *
* after the command so that the program itself does not need to know about    *
* them:                                                                       *
*                                                                             *
*    comm #opt [other program options and files]                              *
*                                                                             *
* The options are:                                                            *
*                                                                             *
*    #bc=c or #backcolor=c - Set inital background color.                     *
*    #fc=c or #forecolor=c - Set inital foreground color.                     *
*    #at=a or #attribute=a - Set inital drawing attribute.                    *
*    #xs=x or #xsize=x     - Set size of x demension.                         *
*    #ys=y or #ysize=y     - Set size of y demension.                         *
*    #sw   or #smallwindow - Assume not using all of terminal.                *
*                                                                             *
******************************************************************************}

module ansilib;

uses wrapper, { uses windows 95 system call wrapper }
     syslib;  { system library }

const maxtim = 10; { maximum number of timers available }

type { colors displayable in text mode }
     color = (black, white, red, green, blue, cyan, yellow, magenta);
     joyhan = 1..4; { joystick handles }
     joynum = 0..4; { number of joysticks }
     joybut = 1..4; { joystick buttons }
     joybtn = 0..4; { joystick number of buttons }
     joyaxn = 0..3; { joystick axies }
     timhan = 1..maxtim; { timer handle }
     { events }
     evtcod = (etchar, { ANSI character returned }
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
               etf1,      { function key 1 }
               etf2,      { function key 2 }
               etf3,      { function key 3 }
               etf4,      { function key 4 }
               etf5,      { function key 5 }
               etf6,      { function key 6 }
               etf7,      { function key 7 }
               etf8,      { function key 8 }
               etf9,      { function key 9 }
               etf10,     { function key 10 }
               etmenu,    { display menu }
               etmoub1a,  { mouse button 1 assertion }
               etmoub2a,  { mouse button 2 assertion }
               etmoub3a,  { mouse button 3 assertion }
               etmoub4a,  { mouse button 4 assertion }
               etmoub1d,  { mouse button 1 deassertion }
               etmoub2d,  { mouse button 2 deassertion }
               etmoub3d,  { mouse button 3 deassertion }
               etmoub4d,  { mouse button 4 deassertion }
               etmoumov,  { mouse move }
               ettim,     { timer matures }
               etjoyba,   { joystick button assertion }
               etjoybd,   { joystick button deassertion }
               etjoymov,  { joystick move }
               etterm);   { terminate program }
     { event record }
     evtrec = record

        case etype: evtcod of { event type }

           { ANSI character returned }
           etchar:   (char:                char);
           { timer handle that matured }
           ettim:    (timnum:              timhan);
           etmoumov: (moupx, moupy:        integer); { mouse movement }
           etjoyba:  (ajoyn:               joyhan;   { joystick number }
                      ajoybn:              joybut);  { button number }
           etjoybd:  (djoyn:               joyhan;   { joystick number }
                      djoybn:              joybut);  { button number }
           etjoymov: (mjoyn:               joyhan;   { joystick number }
                      joypx, joypy, joypz: integer); { joystick coordinates }
           etup, etdown, etleft, etright, etleftw, etrightw, ethome, ethomes,
           ethomel, etend, etends, etendl, etscrl, etscrr, etscru, etscrd,    
           etpagd, etpagu, ettab, etenter, etinsert, etinsertl, etinsertt, 
           etdel, etdell, etdelcf, etdelcb, etcopy, etcopyl, etcan, etstop,    
           etcont, etprint, etprintb, etprints, etf1, etf2, etf3, etf4, etf5,
           etf6, etf7, etf8, etf9, etf10, etmenu, etterm, etmoub1a, etmoub2a,
           etmoub3a, etmoub4a, etmoub1d, etmoub2d, etmoub3d, 
           etmoub4d: (); { normal events }    

        { end }

     end;

{ lower level interdiction funtions }

procedure ts_openread(var fn: ss_filhdl; view nm: string); forward;
procedure ts_openwrite(var fn: ss_filhdl; view nm: string); forward;
procedure ts_close(fn: ss_filhdl); forward;
procedure ts_read(fn: ss_filhdl; var ba: bytarr); forward;
procedure ts_write(fn: ss_filhdl; view ba: bytarr); forward;
procedure ts_position(fn: ss_filhdl; p: integer); forward;
function ts_location(fn: ss_filhdl): integer; forward;
function ts_length(fn: ss_filhdl): integer; forward;
function ts_eof(fn: ss_filhdl): boolean; forward;

{ functions at this level }

procedure cursor(var f: text; x, y: integer); forward;
function maxx(var f: text): integer; forward;
function maxy(var f: text): integer; forward;
procedure home(var f: text); forward;
procedure del(var f: text); forward;
procedure up(var f: text); forward;
procedure down(var f: text); forward;
procedure left(var f: text); forward;
procedure right(var f: text); forward;
procedure blink(var f: text; e: boolean); forward;
procedure reverse(var f: text; e: boolean); forward;
procedure underline(var f: text; e: boolean); forward;
procedure superscript(var f: text; e: boolean); forward;
procedure subscript(var f: text; e: boolean); forward;
procedure italic(var f: text; e: boolean); forward;
procedure bold(var f: text; e: boolean); forward;
procedure standout(var f: text; e: boolean); forward;
procedure fcolor(var f: text; c: color); forward;
procedure bcolor(var f: text; c: color); forward;
procedure ascroll(var f: text; e: boolean); forward;
procedure curvis(var f: text; e: boolean); forward;
procedure scroll(var f: text; x, y: integer); forward;
function curx(var f: text): integer; forward;
function cury(var f: text): integer; forward;
procedure select(var f: text; s: integer); forward;
procedure event(var f: text; var er: evtrec); forward;
procedure timer(var f: text; i: timhan; t: integer; r: boolean); forward;
procedure killtimer(var f: text; i: timhan); forward;
function mouse(var f: text): boolean; forward;
function joystick(var f: text): joynum; forward;
function joybutton(var f: text; j: joyhan): joybtn; forward;
function joyaxis(var f: text; j: joyhan): joyaxn; forward;

private

label 88; { abort label }

const 

   maxxd  = 80;  { standard terminal, 80x50 }
   maxyd  = 50;
   { standard file handles }
   inpfil = 1;   { _input }
   outfil = 2;   { _output }
   maxlin = 250; { maximum length of input bufferred line }
   maxcon = 10;  { number of screen contexts }

type

   { screen attribute }
   scnatt = (sanone,  { no attribute }
             sablink, { blinking text (foreground) }
             sarev,   { reverse video }
             saundl,  { underline }
             sasuper, { superscript }
             sasubs,  { subscripting }
             saital,  { italic text }
             sabold); { bold text }
   { single character on screen container. note that not all the attributes
     that appear here can be changed }
   scnrec = record

      ch:    char;    { character at location }
      forec: color;   { foreground color at location }
      backc: color;   { background color at location }
      attr:  scnatt   { active attribute at location }

   end;
   scnbuf = array [1..maxyd, 1..maxxd] of scnrec;
   scncon = record { screen context }

      buf:    scnbuf;  { screen buffer }
      curx:   integer; { current cursor location x }
      cury:   integer; { current cursor location y }
      forec:  color;   { current writing foreground color }
      backc:  color;   { current writing background color }
      attr:   scnatt;  { current writing attribute }
      scroll: boolean  { current status of scroll }

   end;
   scnptr = ^scncon; { pointer to screen context block }
   errcod = (eftbful,  { file table full }
             ejoyacc,  { joystick access }
             etimacc,  { timer access }
             efilopr,  { cannot perform operation on special file }
             einvpos,  { invalid screen position }
             efilzer,  { filename is empty }
             einvscn,  { invalid screen number }
             einvhan); { invalid handle }

var

    inphdl:     integer; { "input" file handle }
    mb1:        boolean; { mouse assert status button 1 }
    mb2:        boolean; { mouse assert status button 2 }
    mb3:        boolean; { mouse assert status button 3 }
    mb4:        boolean; { mouse assert status button 4 }
    mpx, mpy:   integer; { mouse current position }
    nmb1:       boolean; { new mouse assert status button 1 }
    nmb2:       boolean; { new mouse assert status button 2 }
    nmb3:       boolean; { new mouse assert status button 3 }
    nmb4:       boolean; { new mouse assert status button 4 }
    nmpx, nmpy: integer; { new mouse current position }
    opnfil:     array [1..ss_maxhdl] of ss_filhdl; { open files table }
    fi:         1..ss_maxhdl; { index for files table }
    { we must open and process the _output file on our own, else we would
      recurse }
    trmfil:     ss_filhdl; { output file }
    chrbuf:     array [1..1] of byte; { single character output buffer }
    inpbuf:     packed array [1..maxlin] of char; { input line buffer }
    inpptr:     0..maxlin; { input line index }
    screens:    array [1..maxcon] of scnptr; { screen contexts array }
    curscn:     1..maxcon; { index for current screen }

{******************************************************************************

Print error

Prints the given error in ASCII text, then aborts the program.

******************************************************************************}
 
procedure error(e: errcod);

procedure putstr(view s: string);

var i:     integer; { index for string }
    pream: packed array [1..9] of char; { preamble string }
    p:     pstring; { pointer to string }

begin

   pream := 'Ansilib: '; { set preamble }
   new(p, max(s)+9); { get string to hold }
   for i := 1 to 9 do p^[i] := pream[i]; { copy preamble }
   for i := 1 to max(s) do p^[i+9] := s[i]; { copy string }
   ss_wrterr(p^); { output string }
   dispose(p) { release storage }

end;

begin

   case e of { error }

      eftbful: putstr('Too many files');
      ejoyacc: putstr('No joystick access available');
      etimacc: putstr('No timer access available');
      einvhan: putstr('Invalid handle');
      efilopr: putstr('Cannot perform operation on special file');
      einvpos: putstr('Invalid screen position');
      efilzer: putstr('Filename is empty');
      einvscn: putstr('Invalid screen number');
      einvhan: putstr('Invalid file handle');

   end;
   goto 88 { abort module }

end;

{******************************************************************************

Make file entry

Indexes a present file entry or creates a new one. Looks for a free entry
in the files table, indicated by 0. If found, that is returned, otherwise
the file table is full.
Note that the "predefined" file slots are never allocated.

******************************************************************************}

procedure makfil(var fn: ss_filhdl); { file handle }

var fi: 1..ss_maxhdl; { index for files table }
    ff: 0..ss_maxhdl; { found file entry }
    
begin

   { find idle file slot (file with closed file entry) }
   ff := 0; { clear found file }
   for fi := outfil+1 to ss_maxhdl do { search all file entries }
      if opnfil[fi] = 0 then ff := fi; { found a slot }
   if ff = 0 then error(einvhan); { no empty file positions found }
   fn := ff { set file id number }

end;

{******************************************************************************

Remove leading and trailing spaces

Given a string, removes any leading and trailing spaces in the string. The
result is allocated and returned as an indexed buffer.
The input string must not be null.

******************************************************************************}

procedure remspc(view nm: string;   { string }
                 var  rs: pstring); { result string }

var i1, i2: integer; { string indexes }
    n:      boolean; { string is null }
    s, e:   integer; { string start and end }

begin

   { first check if the string is empty or null }
   n := true; { set empty }
   for i1 := 1 to max(nm) do if nm[i1] <> ' ' then
      n := false; { set not empty }
   if n then error(efilzer); { filename is empty }
   s := 1; { set start of string }
   while (s < max(nm)) and (nm[s] = ' ') do s := s+1;
   e := max(nm); { set end of string }
   while (e > 1) and (nm[e] = ' ') do e := e-1;
   new(rs, e-s+1); { allocate result string }
   i2 := 1; { set 1st character of destination }
   for i1 := s to e do begin { copy to result }

      rs^[i2] := nm[i1]; { copy to result }
      i2 := i2+1 { next character }

   end

end;

{******************************************************************************

Check system special file

Checks for one of the special files, and returns the handle of the special
file if found. Accepts a general string.

******************************************************************************}

function chksys(var fn: string) { file to check }
                : ss_filhdl;    { special file handle }

var hdl: ss_filhdl; { handle holder }

{ match strings }

function chkstr(view s: string): boolean;

var m: boolean; { match status }
    i: integer; { index for string }

{ find lower case }

function lcase(c: char): char;

begin

   { find lower case equivalent }
   if c in ['A'..'Z'] then c := chr(ord(c) - ord('A') + ord('a'));
   lcase := c { return as result }

end;

begin

   m := false; { set no match }
   if max(s) = max(fn) then begin { lengths match }

      m := true; { set strings match }
      for i := 1 to max(s) do if lcase(fn[i]) <> lcase(s[i]) then m := false

   end;
   chkstr := m { return match status }

end;

begin

   hdl := 0; { set not a special file }
   if chkstr('_input') then hdl := inpfil { check standard input }
   else if chkstr('_output') then hdl := outfil; { check standard output }
   chksys := hdl { return handle }

end;

{******************************************************************************

Write character to output file

Writes a single character to the output file. Used to write to the output file
directly, instead of via the paslib functions.

******************************************************************************}

procedure wrtchr(c: char);

begin

   chrbuf[1] := ord(c); { place character in buffer }
   ss_write(trmfil, chrbuf) { output character }

end;

{******************************************************************************

Write string to output file

Writes a string to the output file.

******************************************************************************}

procedure wrtstr(view s: string);

var i: integer; { index for string }

begin

   for i := 1 to max(s) do wrtchr(s[i]) { output characters }

end;

{******************************************************************************

Write integer to output file

Writes a simple unsigned integer to the output file.

******************************************************************************}

procedure wrtint(i: integer);

const maxpwr = 1000000000; { maximum power that fits in integer }

var p:       integer; { power holder }
    digit:   char;    { digit holder }
    leading: boolean; { leading digit flag }

begin

   p := maxpwr; { set power }
   leading := false; { set no leading digit encountered }
   while p <> 0 do begin { output digits }

      digit := chr(i div p mod 10+ord('0')); { get next digit }
      p := p div 10; { next digit }
      if (digit <> '0') or (p = 0) then { leading digit or end of number }
         leading := true; { set leading digit found }
      if leading then wrtchr(digit) { output digit }

   end

end;

{******************************************************************************

Translate colors code

Translates an idependent to a terminal specific primary color code for an
ANSI compliant terminal..

******************************************************************************}

function colnum(c: color): integer;

var n: integer;

begin

   { translate color number }
   case c of { color }

      black:   n := 0;
      white:   n := 7;
      red:     n := 1;
      green:   n := 2;
      blue:    n := 4;
      cyan:    n := 6;
      yellow:  n := 3;
      magenta: n := 5

   end;
   colnum := n { return number }

end;

{******************************************************************************

Basic terminal controls

These routines control the basic terminal functions. They exist just to
ecapsulate this information. All of these functions are specific to ANSI
compliant terminals.
ANSI is able to set more than one attribute at a time, but under windows 95
there are no two attributes that you can detect together ! This is because
win95 modifies the attributes quite a bit (there is no blink). This capability
can be replaced later if needed.
Other notes: underline only works on monocrome terminals. On color, it makes
the text turn blue.

******************************************************************************}

{ clear screen and home cursor }

procedure trm_clear; begin wrtstr('\esc[2J') end;

{ home cursor }

procedure trm_home; begin wrtstr('\esc[H') end;

{ move cursor up }

procedure trm_up; begin wrtstr('\esc[A') end;

{ move cursor down }

procedure trm_down; begin wrtstr('\esc[B') end;

{ move cursor left }

procedure trm_left; begin wrtstr('\esc[D') end;

{ move cursor right }

procedure trm_right; begin wrtstr('\esc[C') end;

{ turn on blink attribute }

procedure trm_blink; begin wrtstr('\esc[5m') end;

{ turn on reverse video }

procedure trm_rev; begin wrtstr('\esc[7m') end;

{ turn on underline }

procedure trm_undl; begin wrtstr('\esc[4m') end;

{ turn on bold attribute }

procedure trm_bold; begin wrtstr('\esc[1m') end;

{ turn off all attributes }

procedure trm_attroff; begin wrtstr('\esc[0m') end;

{ turn on cursor wrap }

procedure trm_wrapon; begin wrtstr('\esc[=7h') end;

{ turn off cursor wrap }

procedure trm_wrapoff; begin wrtstr('\esc[=7l') end;

{ position cursor }

procedure trm_cursor(x, y: integer);

begin

   wrtstr('\esc['); 
   wrtint(y); 
   wrtstr(';');
   wrtint(x);
   wrtstr('H')

end;

{ set foreground color }

procedure trm_fcolor(c: color);
begin wrtstr('\esc['); wrtint(30+colnum(c)); wrtstr('m') end;

{ set background color }

procedure trm_bcolor(c: color);
begin wrtstr('\esc['); wrtint(40+colnum(c)); wrtstr('m') end;

{******************************************************************************

Set attribute from attribute code

Accepts a "universal" attribute code, and executes the attribute set required
to make that happen onscreen.

******************************************************************************}

procedure setattr(a: scnatt);

begin

   case a of { attribute }

      sanone:  trm_attroff; { no attribute }
      sablink: trm_blink;   { blinking text (foreground) }
      sarev:   trm_rev;     { reverse video }
      saundl:  trm_undl;    { underline }
      sasuper: ;            { superscript }
      sasubs:  ;            { subscripting }
      saital:  ;            { italic text }
      sabold:  trm_bold     { bold text }

   end

end;

{******************************************************************************

Clear screen buffer

Clears the entire screen buffer to spaces with the current colors and
attributes.

******************************************************************************}

procedure clrbuf;

var x, y: integer; { screen indexes }

begin

   { clear the screen buffer }
   for y := 1 to maxyd do
      for x := 1 to maxxd do with screens[curscn]^.buf[y, x] do begin

      ch := ' '; { clear to spaces }
      forec := screens[curscn]^.forec;
      backc := screens[curscn]^.backc;
      attr := screens[curscn]^.attr

   end

end;

{******************************************************************************

Initalize screen

Clears all the parameters in the present screen context, and updates the
display to match.

******************************************************************************}

procedure iniscn;

begin

   screens[curscn]^.cury := 1; { set cursor at home }
   screens[curscn]^.curx := 1;
   { these attributes and colors are pretty much windows 95 specific. The
     bazzare setting of "blink" actually allows access to bright white }
   screens[curscn]^.forec := black; { set colors and attributes }
   screens[curscn]^.backc := white;
   screens[curscn]^.attr := sablink;
   screens[curscn]^.scroll := true; { turn on autoscroll }
   clrbuf; { clear screen buffer with that }
   setattr(screens[curscn]^.attr); { set current attribute }
   trm_fcolor(screens[curscn]^.forec); { set current colors }
   trm_bcolor(screens[curscn]^.backc);
   trm_clear { clear screen, home cursor }

end;

{******************************************************************************

Restore screen

Updates all the buffer and screen parameters to the terminal.

******************************************************************************}

procedure restore;

var xi, yi: integer; { screen indexes }
    fs, bs: color;   { color saves }
    as:     scnatt;  { attribute saves }

begin

   trm_home; { restore cursor to upper left to start }
   { set colors and attributes }
   trm_fcolor(screens[curscn]^.forec); { restore colors }
   trm_bcolor(screens[curscn]^.backc);
   setattr(screens[curscn]^.attr); { restore attributes }
   fs := screens[curscn]^.forec; { save current colors and attributes }
   bs := screens[curscn]^.backc;
   as := screens[curscn]^.attr;
   { copy buffer to screen }
   for yi := 1 to maxyd do begin { lines }

      for xi := 1 to maxxd do { characters }
         with screens[curscn]^.buf[yi, xi] do begin

         { for each new character, we compare the attributes and colors
           with what is set. if a new color or attribute is called for,
           we set that, and update the saves. this technique cuts down on
           the amount of output characters }
         if forec <> fs then begin { new foreground color }

            trm_fcolor(forec); { set the new color }
            fs := forec { set save }
   
         end;
         if backc <> bs then begin { new foreground color }
   
            trm_bcolor(backc); { set the new color }
            bs := backc { set save }
   
         end;
         if attr <> as then begin { new attribute }
   
            setattr(attr); { set the new attribute }
            as := attr { set save }
   
         end;
         wrtchr(ch) { now output the actual character }

      end;
      if yi < maxyd then
         { output next line sequence on all lines but the last. this is
           because the last one would cause us to scroll }
         wrtstr('\cr\lf')
      
   end;
   { restore cursor positition }
   trm_cursor(screens[curscn]^.curx, screens[curscn]^.cury);
   trm_fcolor(screens[curscn]^.forec); { restore colors }
   trm_bcolor(screens[curscn]^.backc);
   setattr(screens[curscn]^.attr) { restore attributes }

end;

{******************************************************************************

Scroll screen

Scrolls the ANSI terminal screen by deltas in any given direction. For an ANSI
terminal, we special case any scroll that is downward only, without any
movement in x. These are then done by an arbitrary number of line feeds
executed at the bottom of the screen.
For all other scrolls, we do this by completely refreshing the contents of the
screen, including blank lines or collumns for the "scrolled in" areas. The
blank areas are all given the current attributes and colors.
The cursor allways remains in place for these scrolls, even though the text
is moving under it.

******************************************************************************}

procedure scrolls(x, y: integer);

var xi, yi: integer; { screen counters }
    fs, bs: color;   { color saves }
    as:     scnatt;  { attribute saves }
    scnsav: scnbuf;  { full screen buffer save }
    lx:     integer; { last unmatching character index }
    m:      boolean; { match flag }

begin

   if (y > 0) and (x = 0) then begin

      { downward straight scroll, we can do this with native scrolling }
      trm_cursor(1, maxyd); { position to bottom of screen }
      { use linefeed to scroll. linefeeds work no matter the state of
        wrap, and use whatever the current background color is }
      yi := y; { set line count }
      while yi > 0 do begin { scroll down requested lines }

         wrtchr('\lf'); { scroll down }
         yi := yi-1 { count lines }

      end;
      { restore cursor positition }
      trm_cursor(screens[curscn]^.curx, screens[curscn]^.cury);
      { now, adjust the buffer to be the same }
      for yi := 1 to maxyd-1 do { move any lines up }
         if yi+y <= maxyd then { still within buffer }
            { move lines up }
            screens[curscn]^.buf[yi] := screens[curscn]^.buf[yi+y];
      for yi := maxyd-y+1 to maxyd do { clear blank lines at end }
         for xi := 1 to maxxd do with screens[curscn]^.buf[yi, xi] do begin

         ch := ' '; { clear to blanks at colors and attributes }
         forec := screens[curscn]^.forec;
         backc := screens[curscn]^.backc;
         attr := screens[curscn]^.attr

      end

   end else begin { odd direction scroll }

      { when the scroll is arbitrary, we do it by completely refreshing the
        contents of the screen from the buffer }
      if (x <= -maxxd) or (x >= maxxd) or 
         (y <= -maxyd) or (y >= maxyd) then begin

         { scroll would result in complete clear, do it }
         trm_clear; { scroll would result in complete clear, do it }
         clrbuf; { clear the screen buffer }
         { restore cursor positition }
         trm_cursor(screens[curscn]^.curx, screens[curscn]^.cury)

      end else begin { scroll }

         { true scroll is done in two steps. first, the contents of the buffer
           are adjusted to read as after the scroll. then, the contents of the
           buffer are output to the terminal. before the buffer is changed,
           we perform a full save of it, which then represents the "current"
           state of the real terminal. then, the new buffer contents are
           compared to that while being output. this saves work when most of
           the screen is spaces anyways }
         scnsav := screens[curscn]^.buf; { save the entire buffer }
         if y > 0 then begin { move text up }

            for yi := 1 to maxyd-1 do { move any lines up }
               if yi+y <= maxyd then { still within buffer }
                  { move lines up }
                  screens[curscn]^.buf[yi] := screens[curscn]^.buf[yi+y];
            for yi := maxyd-y+1 to maxyd do { clear blank lines at end }
               for xi := 1 to maxxd do with screens[curscn]^.buf[yi, xi] do
                  begin

               ch := ' '; { clear to blanks at colors and attributes }
               forec := screens[curscn]^.forec;
               backc := screens[curscn]^.backc;
               attr := screens[curscn]^.attr

            end

         end else if y < 0 then begin { move text down }

            for yi := maxyd downto 2 do { move any lines up }
               if yi+y >= 1 then { still within buffer }
                  { move lines up }
                  screens[curscn]^.buf[yi] := screens[curscn]^.buf[yi+y];
            for yi := 1 to abs(y) do { clear blank lines at start }
               for xi := 1 to maxxd do with screens[curscn]^.buf[yi, xi] do
                  begin

               ch := ' '; { clear to blanks at colors and attributes }
               forec := screens[curscn]^.forec;
               backc := screens[curscn]^.backc;
               attr := screens[curscn]^.attr

            end

         end;
         if x > 0 then begin { move text left }

            for yi := 1 to maxyd do begin { move text left }

               for xi := 1 to maxxd-1 do { move left }
                  if xi+x <= maxxd then { still within buffer }
                     { move characters left }
                     screens[curscn]^.buf[yi, xi] :=
                        screens[curscn]^.buf[yi, xi+x];
               { clear blank spaces at right }
               for xi := maxxd-x+1 to maxxd do
                  with screens[curscn]^.buf[yi, xi] do begin
               
                  ch := ' '; { clear to blanks at colors and attributes }
                  forec := screens[curscn]^.forec;
                  backc := screens[curscn]^.backc;
                  attr := screens[curscn]^.attr

               end

            end

         end else if x < 0 then begin { move text right }

            for yi := 1 to maxyd do begin { move text right }

               for xi := maxxd downto 2 do { move right }
                  if xi+x >= 1 then { still within buffer }
                     { move characters left }
                     screens[curscn]^.buf[yi, xi] :=
                        screens[curscn]^.buf[yi, xi+x];
               { clear blank spaces at left }
               for xi := 1 to abs(x) do with screens[curscn]^.buf[yi, xi] do
                  begin
               
                  ch := ' '; { clear to blanks at colors and attributes }
                  forec := screens[curscn]^.forec;
                  backc := screens[curscn]^.backc;
                  attr := screens[curscn]^.attr

               end

            end

         end;
         { the buffer is adjusted. now just copy the complete buffer to the
           screen }
         trm_home; { restore cursor to upper left to start }
         fs := screens[curscn]^.forec; { save current colors and attributes }
         bs := screens[curscn]^.backc;
         as := screens[curscn]^.attr;
         for yi := 1 to maxyd do begin { lines }

            { find the last unmatching character between real and new buffers.
              Then, we only need output the leftmost non-matching characters
              on the line. note that it does not really help us that characters
              WITHIN the line match, because a character output is as or more
              efficient as a cursor movement. if, however, you want to get
              SERIOUSLY complex, we could check runs of matching characters,
              then check if performing a direct cursor position is less output
              characters than just outputing data :) }
            lx := maxxd; { set to end }
            repeat { check matches }

               m := true; { set match }
               { check all elements match }
               if screens[curscn]^.buf[yi, lx].ch <> scnsav[yi, lx].ch then
                  m := false;
               if screens[curscn]^.buf[yi, lx].forec <>
                  scnsav[yi, lx].forec then m := false;
               if screens[curscn]^.buf[yi, lx].backc <>
                  scnsav[yi, lx].backc then m := false;
               if screens[curscn]^.buf[yi, lx].attr <> scnsav[yi, lx].attr then
                  m := false;
               if m then lx := lx-1 { next character }

            until not m or (lx = 0); { until match or no more }
            for xi := 1 to lx do { characters }
               with screens[curscn]^.buf[yi, xi] do begin

               { for each new character, we compare the attributes and colors
                 with what is set. if a new color or attribute is called for,
                 we set that, and update the saves. this technique cuts down on
                 the amount of output characters }
               if forec <> fs then begin { new foreground color }

                  trm_fcolor(forec); { set the new color }
                  fs := forec { set save }
       
               end;
               if backc <> bs then begin { new foreground color }
       
                  trm_bcolor(forec); { set the new color }
                  bs := backc { set save }
       
               end;
               if attr <> as then begin { new attribute }
       
                  setattr(attr); { set the new attribute }
                  as := attr { set save }
       
               end;
               wrtchr(ch) { now output the actual character }

            end;
            if yi < maxyd then
               { output next line sequence on all lines but the last. this is
                 because the last one would cause us to scroll }
               wrtstr('\cr\lf')
            
         end;
         { restore cursor positition }
         trm_cursor(screens[curscn]^.curx, screens[curscn]^.cury);
         trm_fcolor(screens[curscn]^.forec); { restore colors }
         trm_bcolor(screens[curscn]^.backc);
         setattr(screens[curscn]^.attr) { restore attributes }
            
      end

   end

end;

{******************************************************************************

Clear screen

Clears the screen and homes the cursor. This effectively occurs by writing all
characters on the screen to spaces with the current colors and attributes.

******************************************************************************}

procedure iclear;

begin

   trm_clear; { erase screen }
   clrbuf; { clear the screen buffer }
   screens[curscn]^.cury := 1; { set cursor at home }
   screens[curscn]^.curx := 1

end;

{******************************************************************************

Position cursor

Moves the cursor to the specified x and y location.

******************************************************************************}

procedure icursor(x, y: integer);

begin

   if (x >= 1) and (x <= maxxd) and (y >= 1) and (y <= maxyd) then begin

      with screens[curscn]^ do { with current buffer }
         if (x <> curx) or (y <> cury) then begin

         trm_cursor(x, y); { position cursor }
         cury := y; { set new position }
         curx := x

      end

   end else error(einvpos) { invalid position }

end;

{******************************************************************************

Position cursor

This is the external interface to cursor.

******************************************************************************}

procedure cursor(var f: text; x, y: integer);

begin

   icursor(x, y) { position cursor }

end;

{******************************************************************************

Return maximum x demension

Returns the maximum x demension, also equal to the number of collumns in the
display. Because ANSI has no information return capability, this is preset.

******************************************************************************}

function maxx(var f: text): integer;

begin

   maxx := maxxd { set maximum x }

end;

{******************************************************************************

Return maximum y demension

Returns the maximum y demension, also equal to the number of collumns in the
display. Because ANSI has no information return capability, this is preset.

******************************************************************************}
   
function maxy(var f: text): integer;

begin

   maxy := maxyd { set maximum y }

end;

{******************************************************************************

Home cursor

Moves the cursor to the home position at (1, 1), the upper right hand corner.

******************************************************************************}

procedure home(var f: text);

begin

   trm_home; { home cursor }
   screens[curscn]^.cury := 1; { set cursor at home }
   screens[curscn]^.curx := 1

end;

{******************************************************************************

Move cursor up internal

Moves the cursor position up one line.

******************************************************************************}

procedure iup;

begin

   if screens[curscn]^.cury > 1 then begin { not at top of screen }

      trm_up; { move up }
      screens[curscn]^.cury := screens[curscn]^.cury-1 { update position }

   end else if screens[curscn]^.scroll then { scroll enabled }
      scrolls(0, -1) { at top already, scroll up }
   else begin { wrap cursor around to screen bottom }

      screens[curscn]^.cury := maxyd; { set new position }
      { update on screen }
      trm_cursor(screens[curscn]^.curx, screens[curscn]^.cury)

   end

end;

{******************************************************************************

Move cursor up

This is the external interface to up.

******************************************************************************}

procedure up(var f: text);

begin

   iup { move up }

end;

{******************************************************************************

Move cursor down internal

Moves the cursor position down one line.

******************************************************************************}

procedure idown;

begin

   if screens[curscn]^.cury < maxyd then begin { not at bottom of screen }

      trm_down; { move down }
      screens[curscn]^.cury := screens[curscn]^.cury+1 { update position }

   end else if screens[curscn]^.scroll then { wrap enabled }
      scrolls(0, +1) { already at bottom, scroll down }
   else begin { wrap cursor around to screen top }

      screens[curscn]^.cury := 1; { set new position }
      { update on screen }
      trm_cursor(screens[curscn]^.curx, screens[curscn]^.cury)

   end

end;

{******************************************************************************

Move cursor down

This is the external interface to down.

******************************************************************************}

procedure down(var f: text);

begin

   idown { move cursor down }

end;

{******************************************************************************

Move cursor left internal

Moves the cursor one character left.

******************************************************************************}

procedure ileft;

begin

   if screens[curscn]^.curx > 1 then begin { not at extreme left }

      trm_left; { move left }
      screens[curscn]^.curx := screens[curscn]^.curx-1 { update position }

   end else begin { wrap cursor motion }

      iup; { move cursor up one line }
      screens[curscn]^.curx := maxxd; { set cursor to extreme right }
      { position on screen }
      trm_cursor(screens[curscn]^.curx, screens[curscn]^.cury)

   end

end;

{******************************************************************************

Move cursor left

This is the external interface to left.

******************************************************************************}

procedure left(var f: text);

begin

   ileft { move cursor left }

end;

{******************************************************************************

Move cursor right internal

Moves the cursor one character right.

******************************************************************************}

procedure iright;

begin

   if screens[curscn]^.curx < maxxd then begin { not at extreme right }

      trm_right; { move right }
      screens[curscn]^.curx := screens[curscn]^.curx+1 { update position }

   end else begin { wrap cursor motion }

      idown; { move cursor up one line }
      screens[curscn]^.curx := 1; { set cursor to extreme left }
      wrtchr('\cr') { position on screen }

   end

end;

{******************************************************************************

Move cursor right

This is the external interface to right.

******************************************************************************}

procedure right(var f: text);

begin

   iright { move cursor right }

end;

{******************************************************************************

Turn on blink attribute

Turns on/off the blink attribute. Note that under windows 95 in a shell window,
blink does not mean blink, but instead "bright". We leave this alone because
we are supposed to also work over a com interface.
Note that the attributes can only be set singly.
Basically, the only way that I have found to reliably change attributes
on a PC is to turn it all off, then reset everything, including the
colors, which an ATTRIBUTE command seems to mess with !

******************************************************************************}

procedure blink(var f: text; e: boolean);

begin

   trm_attroff; { turn off attributes }
   { either on or off leads to blink, so we just do that }
   screens[curscn]^.attr := sablink; { set attribute active }
   setattr(screens[curscn]^.attr); { set current attribute }
   trm_fcolor(screens[curscn]^.forec); { set current colors }
   trm_bcolor(screens[curscn]^.backc)

end;

{******************************************************************************

Turn on reverse attribute

Turns on/off the reverse attribute.
Note that the attributes can only be set singly.
Basically, the only way that I have found to reliably change attributes
on a PC is to turn it all off, then reset everything, including the
colors, which an ATTRIBUTE command seems to mess with !

******************************************************************************}

procedure reverse(var f: text; e: boolean);

begin

   trm_attroff; { turn off attributes }
   if e then begin { reverse on }

      screens[curscn]^.attr := sarev; { set attribute active }
      setattr(screens[curscn]^.attr); { set current attribute }
      trm_fcolor(screens[curscn]^.forec); { set current colors }
      trm_bcolor(screens[curscn]^.backc)

   end else begin { turn it off }

      screens[curscn]^.attr := sablink; { set attribute active }
      setattr(screens[curscn]^.attr); { set current attribute }
      trm_fcolor(screens[curscn]^.forec); { set current colors }
      trm_bcolor(screens[curscn]^.backc)

   end

end;

{******************************************************************************

Turn on underline attribute

Turns on/off the underline attribute.
Note that the attributes can only be set singly.
Basically, the only way that I have found to reliably change attributes
on a PC is to turn it all off, then reset everything, including the
colors, which an ATTRIBUTE command seems to mess with !

******************************************************************************}

procedure underline(var f: text; e: boolean);

begin

   trm_attroff; { turn off attributes }
   if e then begin { underline on }

      screens[curscn]^.attr := saundl; { set attribute active }
      setattr(screens[curscn]^.attr); { set current attribute }
      trm_fcolor(screens[curscn]^.forec); { set current colors }
      trm_bcolor(screens[curscn]^.backc)

   end else begin { turn it off }

      screens[curscn]^.attr := sablink; { set attribute active }
      setattr(screens[curscn]^.attr); { set current attribute }
      trm_fcolor(screens[curscn]^.forec); { set current colors }
      trm_bcolor(screens[curscn]^.backc)

   end

end;

{******************************************************************************

Turn on superscript attribute

Turns on/off the superscript attribute.
Note that the attributes can only be set singly.

******************************************************************************}

procedure superscript(var f: text; e: boolean);

begin

   { no capability }

end;

{******************************************************************************

Turn on subscript attribute

Turns on/off the subscript attribute.
Note that the attributes can only be set singly.

******************************************************************************}

procedure subscript(var f: text; e: boolean);

begin

   { no capability }

end;

{******************************************************************************

Turn on italic attribute

Turns on/off the italic attribute.
Note that the attributes can only be set singly.

******************************************************************************}

procedure italic(var f: text; e: boolean);

begin

   { no capability }

end;

{******************************************************************************

Turn on bold attribute

Turns on/off the bold attribute.
Note that the attributes can only be set singly.
Basically, the only way that I have found to reliably change attributes
on a PC is to turn it all off, then reset everything, including the
colors, which an ATTRIBUTE command seems to mess with !

******************************************************************************}

procedure bold(var f: text; e: boolean);

begin

   trm_attroff; { turn off attributes }
   if e then begin { bold on }

      screens[curscn]^.attr := sabold; { set attribute active }
      setattr(screens[curscn]^.attr); { set current attribute }
      trm_fcolor(screens[curscn]^.forec); { set current colors }
      trm_bcolor(screens[curscn]^.backc)

   end else begin { turn it off }

      screens[curscn]^.attr := sablink; { set attribute active }
      setattr(screens[curscn]^.attr); { set current attribute }
      trm_fcolor(screens[curscn]^.forec); { set current colors }
      trm_bcolor(screens[curscn]^.backc)

   end

end;

{******************************************************************************

Turn on standout attribute

Turns on/off the standout attribute. Standout is implemented as reverse video.
Note that the attributes can only be set singly.

******************************************************************************}

procedure standout(var f: text; e: boolean);

begin

   reverse(f, e) { implement as reverse }

end;

{******************************************************************************

Set foreground color

Sets the foreground (text) color from the universal primary code.

******************************************************************************}

procedure fcolor(var f: text; c: color);

begin

   trm_fcolor(c); { set color }
   screens[curscn]^.forec := c

end;

{******************************************************************************

Set background color

Sets the background color from the universal primary code.

******************************************************************************}

procedure bcolor(var f: text; c: color);

begin

   trm_bcolor(c); { set color }
   screens[curscn]^.backc := c

end;

{******************************************************************************

Enable/disable automatic scroll

Enables or disables automatic screen scroll. With automatic scroll on, moving
off the screen at the top or bottom will scroll up or down, respectively.

******************************************************************************}

procedure ascroll(var f: text; e: boolean);

begin

   screens[curscn]^.scroll := e { set line wrap status }

end;

{******************************************************************************

Enable/disable cursor visibility

Enable or disable cursor visibility. We don't have a capability for this.

******************************************************************************}

procedure curvis(var f: text; e: boolean);

begin

   { no capability }

end;

{******************************************************************************

Scroll screen

Process full delta scroll on screen. This is the external interface to this
function.

******************************************************************************}

procedure scroll(var f: text; x, y: integer);

begin

   scrolls(x, y) { process scroll }

end;

{******************************************************************************

Get location of cursor in x

Returns the current location of the cursor in x.

******************************************************************************}

function curx(var f: text): integer;

begin

   curx := screens[curscn]^.curx { return current location x }

end;

{******************************************************************************

Get location of cursor in y

Returns the current location of the cursor in y.

******************************************************************************}

function cury(var f: text): integer;

begin

   cury := screens[curscn]^.cury { return current location y }

end;

{******************************************************************************

Select current screen

Selects one of the screens to set active. If the screen has never been used,
then a new screen is allocated and cleared.
The most common use of the screen selection system is to be able to save the
initial screen to be restored on exit. This is a moot point in this
application, since we cannot save the entry screen in any case.
We allow the screen that is currently active to be reselected. This effectively
forces a screen refresh, which can be important when working on terminals.

******************************************************************************}

procedure select(var f: text; s: integer);

begin

   if (s < 1) or (s > maxcon) then error(einvscn); { invalid screen number }
   curscn := s; { set the current screen }
   if screens[curscn] <> nil then restore { restore current screen }
   else begin { no current screen, create a new one }

      new(screens[curscn]); { get a new screen context }
      iniscn { initalize that }
   
   end

end;

{******************************************************************************

Place next terminal character

Places the given character to the current cursor position using the current
colors and attribute.

******************************************************************************}

procedure plcchr(c: char);

begin

   { handle special character cases first }
   if c = '\cr' then { carriage return, position to extreme left }
      icursor(1, screens[curscn]^.cury)
   else if c = '\lf' then idown { line feed, move down }
   else if c = '\bs' then ileft { back space, move left }
   else if c = '\ff' then iclear { clear screen }
   else if (c >= ' ') and (c <> chr($7f)) then begin

      { normal character case, not control character }
      wrtchr(c); { output character to terminal }
      with screens[curscn]^.buf[screens[curscn]^.cury, 
                                screens[curscn]^.curx] do begin { update buffer }

         ch := c; { place character }
         forec := screens[curscn]^.forec; { place colors }
         backc := screens[curscn]^.backc;
         attr := screens[curscn]^.attr { place attribute }

      end;
      { finish cursor right processing }
      if screens[curscn]^.curx < maxxd then { not at extreme right }
         screens[curscn]^.curx := screens[curscn]^.curx+1 { update position }
      else
         { Wrap being off, ANSI left the cursor at the extreme right. So now
           we can process our own version of move right }
         iright

   end
   
end;

{******************************************************************************

Delete last character

Deletes the character to the left of the cursor, and moves the cursor one
position left.

******************************************************************************}

procedure del(var f: text);

begin

   left(f); { back up cursor }
   plcchr(' '); { blank out }
   left(f) { back up again }

end;

{******************************************************************************

Aquire next input event

Waits for and returns the next event. For now, the input file is ignored, and
the standard input handle allways used.

******************************************************************************}

procedure ievent(var er: evtrec);

var keep: boolean;         { event keep flag }
    r:    integer;         { function return value }
    ser:  sc_input_record; { windows event record }

{

Process keyboard event.
The events are mapped from IBM-PC keyboard keys as follows:

etup      up arrow            cursor up one line 
etdown    down arrow          down one line 
etleft    left arrow          left one character 
etright   right arrow         right one character 
etleftw   shift-left arrow    left one word 
etrightw  shift-right arrow   right one word 
ethome    cntrl-home          home of document 
ethomes   shift-home          home of screen 
ethomel   home                home of line 
etend     cntrl-end           end of document 
etends    shift-end           end of screen 
etendl    end                 end of line 
etscrl    cntrl-left arrow    scroll left one character 
etscrr    cntrl-right arrow   scroll right one character 
etscru    cntrl-up arrow      scroll up one line 
etscrd    cntrl-down arrow    scroll down one line 
etpagd    page down           page down 
etpagu    page up             page up 
ettab     tab                 tab 
etenter   enter               enter line 
etinsert  cntrl-insert        insert block 
etinsertl shift-insert        insert line 
etinsertt insert              insert toggle 
etdel     cntrl-del           delete block 
etdell    shift-del           delete line 
etdelcf   del                 delete character forward 
etdelcb   backspace           delete character backward 
etcopy    cntrl-f1            copy block 
etcopyl   shift-f1            copy line 
etcan     esc                 cancel current operation 
etstop    cntrl-s             stop current operation 
etcont    cntrl-q             continue current operation 
etprint   shift-f2            print document
etprintb  cntrl-f2            print block
etprints  cntrl-f3            print screen 
etf1      f1                  function key 1 
etf2      f2                  function key 2 
etf3      f3                  function key 3 
etf4      f4                  function key 4 
etf5      f5                  function key 5 
etf6      f6                  function key 6 
etf7      f7                  function key 7 
etf8      f8                  function key 8 
etf9      f9                  function key 9 
etf10     f10                 function key 10 
etmenu    alt                 display menu 
etend     cntrl-c             terminate program 

}

procedure keyevent;

{ check control key pressed }

function cntrl: boolean;

begin

   cntrl := ser.keyevent.controlkeystate and 
            (sc_right_ctrl_pressed or sc_left_ctrl_pressed) <> 0

end;

{ check shift key pressed }

function shift: boolean;

begin

   shift := ser.keyevent.controlkeystate and sc_shift_pressed <> 0

end;

begin

   { we only take key down (pressed) events }
   if ser.keyevent.keydown <> 0 then begin

      { Check character is non-zero. The zero character occurs
        whenever a control feature is hit. }
      if ord(ser.keyevent.char.asciichar) <> 0 then begin

         if ser.keyevent.char.asciichar = '\cr' then
            er.etype := etenter { set enter line }
         else if ser.keyevent.char.asciichar = '\bs' then
            er.etype := etdelcb { set delete character backwards }
         else if ser.keyevent.char.asciichar = '\ht' then
            er.etype := ettab { set tab }
         else if ser.keyevent.char.asciichar = chr(ord('C')-64) then
            er.etype := etterm { set end program }
         else if ser.keyevent.char.asciichar = chr(ord('S')-64) then
            er.etype := etstop { set stop program }
         else if ser.keyevent.char.asciichar = chr(ord('Q')-64) then
            er.etype := etcont { set continue program }
         else begin { normal character }

            er.etype := etchar; { set character event }
            er.char := ser.keyevent.char.asciichar

         end;
         keep := true { set keep event }

      end else if ser.keyevent.virtualkeycode <= $ff then
         { limited to codes we can put in a set }
         if ser.keyevent.virtualkeycode in 
            [sc_vk_home, sc_vk_end, sc_vk_left, sc_vk_right,
             sc_vk_up, sc_vk_down, sc_vk_insert, sc_vk_delete,
             sc_vk_prior, sc_vk_next, sc_vk_f1..sc_vk_f10,
             sc_vk_menu, sc_vk_cancel] then begin

         { this key is one we process }
         case ser.keyevent.virtualkeycode of { key }

            sc_vk_home: begin { home }
             
               if cntrl then er.etype := ethome { home document }
               else if shift then er.etype := ethomes { home screen }
               else er.etype := ethomel { home line }

            end;
            sc_vk_end: begin { end }

               if cntrl then er.etype := etend { end document }
               else if shift then er.etype := etends { end screen }
               else er.etype := etendl { end line }

            end;
            sc_vk_up: begin { up }

               if cntrl then er.etype := etscru { scroll up }
               else er.etype := etup { up line }

            end;
            sc_vk_down: begin { down }

               if cntrl then er.etype := etscrd { scroll down }
               else er.etype := etdown { up line }

            end;
            sc_vk_left: begin { left }

               if cntrl then er.etype := etscrl { scroll left one character }
               else if shift then er.etype := etleftw { left one word }
               else er.etype := etleft { left one character }

            end;
            sc_vk_right: begin { right }

               if cntrl then er.etype := etscrr { scroll right one character }
               else if shift then er.etype := etrightw { right one word }
               else er.etype := etright { left one character }

            end;
            sc_vk_right: begin { right }

               if cntrl then er.etype := etscrr { scroll right one character }
               else if shift then er.etype := etrightw { right one word }
               else er.etype := etright { left one character }

            end;
            sc_vk_insert: begin { insert }

               if cntrl then er.etype := etinsert { insert block }
               else if shift then er.etype := etinsertl { insert line }
               else er.etype := etinsertt { insert toggle }

            end;
            sc_vk_delete: begin { delete }

               if cntrl then er.etype := etdel { delete block }
               else if shift then er.etype := etdell { delete line }
               else er.etype := etdelcf { insert toggle }

            end;
            sc_vk_prior: er.etype := etpagu; { page up }
            sc_vk_next: er.etype := etpagd; { page down }
            sc_vk_f1: begin { f1 }

               if cntrl then er.etype := etcopy { copy block }
               else if shift then er.etype := etcopyl { copy line }
               else er.etype := etf1 { f1 }

            end;
            sc_vk_f2: begin { f2 }

               if cntrl then er.etype := etprintb { print block }
               else if shift then er.etype := etprint { print document }
               else er.etype := etf2 { f2 }

            end;
            sc_vk_f3: begin { f3 }

               if cntrl then er.etype := etprints { print screen }
               else er.etype := etf3 { f3 }

            end;
            sc_vk_f4: er.etype := etf4; { f4 }
            sc_vk_f5: er.etype := etf5; { f5 }
            sc_vk_f6: er.etype := etf6; { f6 }
            sc_vk_f7: er.etype := etf7; { f7 }
            sc_vk_f8: er.etype := etf8; { f8 }
            sc_vk_f9: er.etype := etf9; { f9 }
            sc_vk_f10: er.etype := etf10; { f10 }
            sc_vk_menu: er.etype := etmenu; { alt }
            sc_vk_cancel: er.etype := etterm; { ctl-brk }

         end;
         keep := true { set keep event }

      end

   end

end;

{

Process mouse event.
Buttons are assigned to Win 95 as follows:

button 1: Windows left button
button 2: Windows right button
button 3: Windows 2nd from left button
button 4: Windows 3rd from left button

The Windows 4th from left button is unused. The double click events will
end up, as, well, two clicks of a single button, displaying my utter
contempt for the whole double click concept.

}

{ update mouse parameters }

procedure mouseupdate;

begin

   { we prioritize events by: movements 1st, button clicks 2nd }
   if (nmpx <> mpx) or (nmpy <> mpy) then begin { create movement event }

      er.etype := etmoumov; { set movement event }
      er.moupx := nmpx; { set new mouse position }
      er.moupy := nmpy;
      mpx := nmpx; { save new position }
      mpy := nmpy;
      keep := true { set to keep }

   end else if nmb1 > mb1 then begin

      er.etype := etmoub1a; { button 1 assert }
      mb1 := nmb1; { update status }
      keep := true { set to keep }

   end else if nmb2 > mb2 then begin

      er.etype := etmoub2a; { button 2 assert }
      mb2 := nmb2; { update status }
      keep := true { set to keep }

   end else if nmb3 > mb3 then begin

      er.etype := etmoub3a; { button 3 assert }
      mb3 := nmb3; { update status }
      keep := true { set to keep }

   end else if nmb4 > mb4 then begin

      er.etype := etmoub4a; { button 4 assert }
      mb4 := nmb4; { update status }
      keep := true { set to keep }

   end else if nmb1 < mb1 then begin

      er.etype := etmoub1d; { button 1 deassert }
      mb1 := nmb1; { update status }
      keep := true { set to keep }

   end else if nmb2 < mb2 then begin

      er.etype := etmoub2d; { button 2 deassert }
      mb2 := nmb2; { update status }
      keep := true { set to keep }

   end else if nmb3 < mb3 then begin

      er.etype := etmoub3d; { button 3 deassert }
      mb3 := nmb3; { update status }
      keep := true { set to keep }

   end else if nmb4 < mb4 then begin

      er.etype := etmoub4d; { button 4 deassert }
      mb4 := nmb4; { update status }
      keep := true { set to keep }

   end

end;

{ register mouse status }

procedure mouseevent;

begin

   { gather a new mouse status }
   nmpx := ser.mouseevent.mouseposition.x+1; { get mouse position }
   nmpy := ser.mouseevent.mouseposition.y+1;
   nmb1 := ser.mouseevent.buttonstate and sc_from_left_1st_button_pressed <> 0;
   nmb2 := ser.mouseevent.buttonstate and sc_rightmost_button_pressed <> 0;
   nmb3 := ser.mouseevent.buttonstate and sc_from_left_2nd_button_pressed <> 0;
   nmb4 := ser.mouseevent.buttonstate and sc_from_left_3rd_button_pressed <> 0

end;

begin { event }

   repeat

      keep := false; { set don't keep by default }
      mouseupdate; { check any mouse details need processing }
      if not keep then begin { no, go ahead with event read }

         r := sc_readconsoleinputa(inphdl, ser); { get the next event }
         if r = 1 then begin { process valid event }

            { decode by event }
            if ser.eventtype = sc_key_event then keyevent { key event }
            else if ser.eventtype = sc_mouse_event then 
               mouseevent { mouse event }
            { ansi mode has no window size, menu or focus events }

         end

      end

   until keep { until an event we want occurs }

end; { event }

{ external event interface }

procedure event(var f: text; var er: evtrec);

begin

   ievent(er) { process event }

end;

{******************************************************************************

Set timer

Sets an elapsed timer to run, as identified by a timer handle. From 1 to 10
timers can be used. The elapsed time is 32 bit signed, in tenth milliseconds. 
This means that a bit more than 24 hours can be measured without using the
sign.
Timers can be set to repeat, in which case the timer will automatically repeat
after completion. When the timer matures, it sends a timer mature event to
the associated input file.
Note that it is an error to set a timer without repeat, then kill that same
timer. This is because the kill call could reference an event that has expired.
Note: timers are not implemented. I tried this under win95, it was
uncooperative.

******************************************************************************}

procedure timer(var f: text;     { file to send event to }
                    i: timhan;   { timer handle }
                    t: integer;  { number of milliseconds to run }
                    r: boolean); { timer is to rerun after completion }

begin

   error(etimacc) { no timers available }

end;

{******************************************************************************

Kill timer

Kills a given timer, by it's id number. Only repeating timers should be killed.
Note: timers are not implemented. I tried this under win95, it was
uncooperative.

******************************************************************************}

procedure killtimer(var f: text;    { file to kill timer on }
                        i: timhan); { handle of timer }

begin

   error(etimacc) { no timers available }

end;

{******************************************************************************

Return mouse existance

Returns true if a mouse is implemented, which it is. 

******************************************************************************}

function mouse(var f: text): boolean;

begin

   mouse := true { set mouse exists }

end;

{******************************************************************************

Return number of joysticks

Return number of joysticks attached.
Note that Windows 95 has no joystick capability.

******************************************************************************}

function joystick(var f: text): joynum;

begin

   joystick := 0 { none }

end;

{******************************************************************************

Return number of buttons on a joystick

Returns the number of buttons on a given joystick.
Note that Windows 95 has no joystick capability.

******************************************************************************}

function joybutton(var f: text; j: joyhan): joybtn;

begin

   error(ejoyacc); { there are no joysticks }
   joybutton := 0 { shut up compiler }

end;

{******************************************************************************

Return number of axies on a joystick

Returns the number of axies implemented on a joystick, which can be 1 to 3.
The axies order of implementation is x, y, then z. Typically, a monodementional
joystick can be considered a slider without positional meaning.
Note that Windows 95 has no joystick capability.

******************************************************************************}

function joyaxis(var f: text; j: joyhan): joyaxn;

begin

   error(ejoyacc); { there are no joysticks }
   joyaxis := 0 { shut up compiler }

end;

{******************************************************************************

Process input line

Reads an input line with full echo and editting. The line is placed into the
input line buffer.
The upgrade for this is to implement a full set of editting features.

******************************************************************************}

procedure readline;

var er: evtrec; { event record } 

begin

   inpptr := 1; { set 1st character position }
   repeat { get line characters }

      { get events until an "interesting" event occurs }
      repeat ievent(er) until er.etype in [etchar, etenter, etterm, etdelcb];
      { if the event is line enter, place carriage return code, 
        otherwise place real character. note that we emulate a
        terminal and return cr only, which is handled as appropriate
        by a higher level. if the event is program terminate, then we
        execute an organized halt }
      case er.etype of { event }

         etterm:  halt; { halt program }
         etenter: begin { line terminate }

            inpbuf[inpptr] := '\cr'; { return cr }
            plcchr('\cr'); { output newline sequence }
            plcchr('\lf')

         end;
         etchar: begin { character }

            if inpptr < maxlin then begin

               inpbuf[inpptr] := er.char; { place real character }
               plcchr(er.char) { echo the character }

            end;
            if inpptr < maxlin then inpptr := inpptr+1 { next character }

         end;
         etdelcb: begin { delete character backwards }

            if inpptr > 1 then begin { not at extreme left }

               plcchr('\bs'); { backspace, spaceout then backspace again }
               plcchr(' ');
               plcchr('\bs');
               inpptr := inpptr-1 { back up pointer }

            end

         end

      end

   until er.etype = etenter; { until line terminate }
   inpptr := 1 { set 1st position on active line }

end;

{******************************************************************************

Open file for read

Opens the file by name, and returns the file handle. If the file is the
"_input" file, then we give it our special handle. Otherwise, the entire
processing of the file is passed onto the system level.
We handle the entire processing of the input file here, by processing the
event queue.

******************************************************************************}

procedure ts_openread(var fn: ss_filhdl; view nm: string);

var fs: pstring; { filename buffer pointer }

begin

   remspc(nm, fs); { remove leading and trailing spaces }
   fn := chksys(fs^); { check it's a system file }
   if fn <> inpfil then begin { not "_input", process pass-on }

      makfil(fn); { create new file slot }
      ss_openread(opnfil[fn], fs^) { pass to lower level }

   end;
   dispose(fs) { release temp string }

end;

{******************************************************************************

Open file for write

Opens the file by name, and returns the file handle. If the file is the
"_output" file, then we give it our special handle. Otherwise, the file entire
processing of the file is passed onto the system level.

******************************************************************************}

procedure ts_openwrite(var fn: ss_filhdl; view nm: string);

var fs: pstring; { filename buffer pointer }

begin

   remspc(nm, fs); { remove leading and trailing spaces }
   fn := chksys(fs^); { check it's a system file }
   if fn <> outfil then begin { not "_output", process pass-on }

      makfil(fn); { create new file slot }
      ss_openwrite(opnfil[fn], fs^) { open at lower level }

   end;
   dispose(fs) { release temp string }

end;

{******************************************************************************

Close file

Closes the file. The file is closed at the system level, then we remove the
table entry for the file.

******************************************************************************}

procedure ts_close(fn: ss_filhdl);

begin

   if fn > outfil then begin { transparent file }

      if opnfil[fn] = 0 then error(einvhan); { invalid handle }
      ss_close(opnfil[fn]); { close at lower level }
      opnfil[fn] := 0 { clear out file table entry }

   end

end;

{******************************************************************************

Read file

If the file is the input file, we process that by reading from the event queue
and returning any characters found. Any events besides character events are
discarded, which is why reading from the "input" file is a downward compatible
operation.
All other files are passed on to the system level.

******************************************************************************}

procedure ts_read(fn: ss_filhdl; var ba: bytarr);

var i: integer; { index for destination }
    l: integer; { length left on destination }

begin

   if fn > outfil then { transparent file }
      if opnfil[fn] = 0 then error(einvhan); { invalid handle }
   if fn = inpfil then begin { process input file }

      i := 1; { set 1st byte of destination }
      l := max(ba); { set length of destination }
      while l > 0 do begin { read input bytes }

         { if there is no line in the input buffer, get one }
         if inpptr = 0 then readline;
         ba[i] := ord(inpbuf[inpptr]); { get and place next character }
         if inpptr < maxlin then inpptr := inpptr+1; { next }
         { if we have just read the last of that line, then flag buffer empty }
         if ba[i] = ord('\cr') then inpptr := 0;
         i := i+1; { next character }
         l := l-1 { count characters }

      end
      
   end else ss_read(opnfil[fn], ba) { pass to lower level }

end;

{******************************************************************************

Write file

Outputs to the given file. If the file is the "output" file, then we process
it specially.

******************************************************************************}

procedure ts_write(fn: ss_filhdl; view ba: bytarr);

var i: integer; { index for destination }
    l: integer; { length left on destination }

begin

   if fn > outfil then { transparent file }
      if opnfil[fn] = 0 then error(einvhan); { invalid handle }
   if fn = outfil then begin { process output file }

      i := 1; { set 1st byte of source }
      l := max(ba); { set length of source }
      while l > 0 do begin { write output bytes }

         plcchr(chr(ba[i])); { send character to terminal emulator }
         i := i+1; { next character }
         l := l-1 { count characters }

      end
      
   end else ss_write(opnfil[fn], ba) { pass to lower level }

end;

{******************************************************************************

Position file

Positions the given file. If the file is one of "input" or "output", we fail
call, as positioning is not valid on a special file.

******************************************************************************}

procedure ts_position(fn: ss_filhdl; p: integer);

begin

   if fn > outfil then { transparent file }
      if opnfil[fn] = 0 then error(einvhan); { invalid handle }
   { check operation performed on special file }
   if (fn = inpfil) or (fn = outfil) then error(efilopr);
   ss_position(opnfil[fn], p) { pass to lower level }

end;

{******************************************************************************

Find location of file

Find the location of the given file. If the file is one of "input" or "output",
we fail the call, as this is not valid on a special file.

******************************************************************************}

function ts_location(fn: ss_filhdl): integer;

begin

   if fn > outfil then { transparent file }
      if opnfil[fn] = 0 then error(einvhan); { invalid handle }
   { check operation performed on special file }
   if (fn = inpfil) or (fn = outfil) then error(efilopr);
   ts_location := ss_location(opnfil[fn]) { pass to lower level }

end;

{******************************************************************************

Find length of file

Find the length of the given file. If the file is one of "input" or "output",
we fail the call, as this is not valid on a special file.

******************************************************************************}

function ts_length(fn: ss_filhdl): integer;

begin

   if fn > outfil then { transparent file }
      if opnfil[fn] = 0 then error(einvhan); { invalid handle }
   { check operation performed on special file }
   if (fn = inpfil) or (fn = outfil) then error(efilopr);
   ts_length := ss_length(opnfil[fn]) { pass to lower level }

end;

{******************************************************************************

Check eof of file

Checks if a given file is at eof. On our special files "input" and "output",
the eof is allways false. On "input", there is no idea of eof on a keyboard
input file. On "output", eof is allways false on a write only file.

******************************************************************************}

function ts_eof(fn: ss_filhdl): boolean;

begin

   if fn > outfil then { transparent file }
      if opnfil[fn] = 0 then error(einvhan); { invalid handle }
   { check operation performed on special file }
   if (fn = inpfil) or (fn = outfil) then ts_eof := false { yes, allways true }
   else ts_eof := ss_eof(opnfil[fn]) { pass to lower level }

end;

begin

   inphdl := sc_getstdhandle(sc_std_input_handle);
   mb1 := false; { set mouse as assumed no buttons down, at origin }
   mb2 := false;
   mb3 := false;
   mb4 := false;
   mpx := 1;
   mpy := 1;
   nmb1 := false;
   nmb2 := false;
   nmb3 := false;
   nmb4 := false;
   nmpx := 1;
   nmpy := 1;
   inpptr := 0; { set no input line active }
   { clear open files table }
   for fi := 1 to ss_maxhdl do opnfil[fi] := 0; { set unoccupied }
   ss_openwrite(trmfil, '_output'); { open the output file }
   { because this is an "open ended" (no feedback) emulation, we must bring
     the terminal to a known state }
   { clear active screens }
   for curscn := 1 to maxcon do screens[curscn] := nil;
   new(screens[1]); { get the default screen }
   curscn := 1; { set current screen }
   trm_wrapoff; { wrap is allways off }
   iniscn { initalize screen }

end;

begin

   88: { abort module }
   { close all open files }
   for fi := 1 to ss_maxhdl do ss_close(opnfil[fi]);
   ss_close(trmfil) { close the output file }

end.
