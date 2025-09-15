{*******************************************************************************
*                                                                              *
*                             IP PASCAL IDE                                    *
*                                                                              *
*                                VS. 0.1                                       *
*                                                                              *
*                           COPYRIGHT (C) 2006                                 *
*                                                                              *
*                             Scott A. MOORE                                   *
*                                                                              *
* A basic text edittor, built for MOORE/CAD Pascal with the Uniface library,   *
* text level.                                                                  *
*                                                                              *
* Implements simple editting on a single screen/single buffer system. All of   *
* the gralib standard controls work, and the following extra functions are     *
* implemented:                                                                 *
*                                                                              *
*    F1  - Save file under current name                                        *
*    F2  - Load file from status line specified name                           *
*    F3  - Search from status specified string                                 *
*    F4  - Search again                                                        *
*    F5  - Replace                                                             *
*    F6  - Replace again                                                       *
*    F7  - Record macro start/stop                                             *
*    F8  - Playback macro                                                      *
*    F9  - Last buffer to selected window                                      *
*    F10 - Next buffer to selected window                                      *
*    F11 - Split window in specified direction                                 *
*    F12 - Close splitter window in specified direction                        *
*                                                                              *
*******************************************************************************}

program ipide(input, output, error);

uses gralib, { graphics library }
     extlib, { external library }
     strlib, { string library }
     parlib; { text parser library }

label inputloop; { return to input mode }

const

   maxlin = 10000; { maximum entered line, must be greater than maxx }
   maxfil = 40;  { maximum length of filename }
   on     = true; { boolean on }
   off    = false; { boolean off }
   cmdmax  = 250; { maximum command line we can process }
   second = 10000; { one second time }
   splons = 2*second; { time to present splash screen }
   { child windows }
   txtwid = 2; { text plane }
   stswid = 3; { status plane }
   splwid = 4; { splash window }
   { widgets }
   vsclwig = 1; { vertical scrollbar }
   hsclwig = 2; { horizontal scrollbar }
   shmwig  = 3; { shim between scrollbars }
   ttabwig = 4; { top tabbar }
   rtabwig = 5; { right tabbar }
   { timers }
   spltim  = 1; { splash screen timer }
   hightim = 2; { highlight timer }
   { pictures }
   splpic  = 1; { splash picture }

type

   lininx  = 1..maxlin; { index for line buffer }
   linbuf  = packed array [lininx] of char; { line buffer }
   linptr  = ^linrec; { pointer to line entry }

   { the lines in the edit buffer are stored as a double linked list of
     dynamically allocated strings }

   linrec    = record { line store entry }

      next: linptr; { next line in store }
      last: linptr; { last line in store }
      line: integer; { line number }
      str:  pstring { string data }

   end;
   filinx = 1..maxfil; { index for filename }
   filnam = packed array [filinx] of char; { filename }
   crdptr = ^crdrec; { pointer to coordinate store }
   crdrec = record { cursor coordinate save }

      next: crdptr; { next entry }
      x, y: integer { cursor coordinates }

   end;
   coord = record x, y: integer end; { coordinate }
   rectl = record ul, lr: coord end; { rectangle }
   stsrec = record b, c: rectl end; { status rectangle }

   { Buffers describe the line oriented data within an edit buffer. A buffer is
     a doubly linked list of text lines. }

   bufptr = ^edtbuf; { pointer to edit buffer header }
   edtbuf = record { edit buffer }
   
      next:   bufptr; { next buffer in list }
      last:   bufptr; { last buffer in list }
      curfil: filnam; { filename for buffer }
      { Note that the strings in a buffer are a circular list, pinned at the
        first line. }
      linstr: linptr; { first line in buffer }
      { The current line can be buffered to keep from thrashing string 
        allocations. buflin indicates the line is buffered, and inpbuf is
        the fixed buffer containing the line. }
      buflin: boolean; { current line in buffer flag }
      inpbuf: linbuf;  { input line buffer }
      lincnt: integer; { number of lines in buffer }
      { The total characters in buffer is not currently updated or used. }
      chrcnt: integer; { number of characters in buffer }
      modify: boolean { buffer was modified }

   end;

   { Views give the edit position within a buffer, with such data as the top of
     screen position in the buffer, the screen offset, and cursor positioning. 
     the view indicates what buffer it is attached to.

   viewptr = ^viewrec; { pointer to view header }
   viewrec = record { view control header }

      next:   viewptr; { next view in list }
      last:   viewptr; { last view in list }
      buffer: bufptr;  { currently attached buffer }
      paglin: linptr;  { top of page line }
      curlin: linptr;  { current edit line }
      chroff: integer; { display left offset }
      linpos: integer; { current line }
      poschr: integer; { current character on line }
      curstk: crdptr   { cursor coordinate stack }

   end;

   { Windows control each text edit window that appears. It has a child window
     that contains the text window, the scroll bars, and the tabs. A series of
     views are attached to the window, one for each buffer that exists. }

   winptr = winrec; { pointer to window }
   winrec = record { window data }

      next: winptr; { next window in list }
      last: winptr; { last window in list }
      winfil: text; { file window is assigned to }
      viewlst: viewptr; { list of views in this window }
      viewcur: viewptr; { currently active view }

   end;

var

   er:       evtrec;  { next event record }
   mpx:      integer; { mouse coordinates x }
   mpy:      integer; { mouse coordinates y }
   insertc:  boolean; { insert/overwrite toggle }
   splwin:   text;    { splash window }
   txtwin:   text;    { text pane of main window }
   stswin:   text;    { status pane of main window }
   vsclon:   boolean; { vertical scrollbar placed }
   hsclon:   boolean; { horizontal scrollbar placed }
   shmon:    boolean; { shim between scrollbars placed }
   ttabon:   boolean; { top tabbar on }
   rtabon:   boolean; { bottom tabbar on }
   sm:       menuptr; { menu list }
   ttablst:  strptr;  { top tab list }
   ttabsel:  integer; { top tab current select }
   rtablst:  strptr;  { bottom tab list }
   f:        real;    { real holding }
   cmdhan:   parhan;  { handle for command parsing }
   err:      boolean; { error holder }
   valfch:   chrset;  { valid file characters }
   fverb:    boolean; { verbose flag }
   w, h:     integer; { widow width and height }
   dsw, dsh: integer; { desktop width and height }
   quit:     boolean; { quit editor flag }
   msgsts:   stsrec; { message/error status window }
   linsts:   stsrec; { line number status window }
   chrsts:   stsrec; { chacter number status window }
   inssts:   stsrec; { insert/overwrite status window }
   modsts:   stsrec; { modify status window }
   schstr:   pstring; { search string }
   schopts:  qfnopts; { search options }
   buflst:   bufptr;  { active edit buffers in system }
   viewlst:  viewptr; { active views in system }
   viewcur:  viewptr; { current view }
   editnam:  filnam;  { command line edit name }
   
procedure errormsg(view s: string); forward; 
procedure putbuf; forward;

{******************************************************************************

Get new buffer

Allocates a new buffer header, initalizes it, and inserts it to the end of the
buffer list.

******************************************************************************}

procedure getedit;

var bp: bufptr; { buffer pointer }

begin

   new(bp); { create new buffer }
   if buflst = nil then begin { this is the first buffer }

      bp^.next := bp; { self link the entry }
      bp^.last := bp;
      buflst := bp { and place root }

   end else begin { buffers exist }

      bp^.next := buflst; { link to next }
      bp^.last := buflst^.last; { link to last }
      bp^.next^.last := bp; { link next to this }
      bp^.last^.next := bp { link last to this }

   end;
   clears(bp^.curfil); { clear filename }
   bp^.linstr := nil; { set no line list }
   bp^.buflin := false; { set current line not buffered }
   bp^.lincnt := 0; { set no lines in buffer }
   bp^.chrcnt := 0; { set characters in buffer }
   bp^.modify := false { set buffer not modified }

end;

{******************************************************************************

Get new view

Allocates a new view header, initalizes it, and inserts it to the end of the
view list.

******************************************************************************}

procedure getview;

var vp: viewptr; { view pointer }

begin

   new(vp); { create new view }
   if viewlst = nil then begin { this is the first view }

      vp^.next := vp; { self link the entry }
      vp^.last := vp;
      viewlst := vp { and place root }

   end else begin { views exist }

      vp^.next := viewlst; { link to next }
      vp^.last := viewlst^.last; { link to last }
      vp^.next^.last := vp; { link next to this }
      vp^.last^.next := vp { link last to this }

   end;
   vp^.buffer := nil; { clear attached buffer }
   vp^.paglin := nil; { clear top of page line }
   vp^.curlin := nil; { clear current edit line }
   vp^.chroff := 0; { clear screen left offset }
   vp^.linpos := 1; { set 1st line }
   vp^.poschr := 1; { set 1st character }
   vp^.curstk := nil { clear cursor coordinate stack }

end;

{******************************************************************************

Dump the view list

Dumps all entries in the view list to the error out. A diagnostic.

******************************************************************************}

procedure dmpview;

var vp: viewptr; { view pointer }
    vc: integer; { view counter }

begin

   writeln(error, 'View list');
   writeln(error);
   vp := viewlst;
   vc := 1; { set 1st view }
   if vp = nil then writeln('View list is empty')
   else repeat { all view entries }

      with vp^ do begin

         writeln(error, 'View number ', vc:1);
         writeln(error);
         writeln(error, 'Buffer is nil: ', buffer = nil:0);
         writeln(error, 'Page line is nil: ', paglin = nil:0);
         writeln(error, 'Current line is nil: ', curlin = nil:0);
         writeln(error, 'Screen left character offset: ', chroff:1);
         writeln(error, 'Current line number: ', linpos:1);
         writeln(error, 'Current character number: ', poschr:1);
         writeln(error, 'Cursor coordinate stack is empty: ', curstk = nil:0);
         writeln(error)

      end;
      vc := vc+1; { count views }
      vp := vp^.next { next view entry }

   until vp = viewlst { until we wrap }

end;

{******************************************************************************

Check options

Checks if a sequence of options is present in the input, and if so, parses and
processes them. An option is a '#' (or '/'), followed by the option identifier.
The identifier must be one of the valid options. Further processing may occur,
on input after the option, depending on the option specified (see the
handlers). Consult the operator's manual for full option details.

******************************************************************************}

procedure paropt;

var w:      filnam; { word holder }
    err:    boolean; { error flag holding }
    optfnd: boolean; { option found }

{ set true/false flag }

procedure setflg(view a, n: string; var f: boolean);

var ts: packed array [1..40] of char; { string holder }

begin

   if compp(w, n) or compp(w, a) then begin

      f := true; { perform true }
      optfnd := true { set option found }

   end else begin { try false cases }

      copy(ts, 'n'); { form negative }
      cat(ts, n);
      if compp(w, ts) then begin

         f := false; { perform false }
         optfnd := true { set option found }

      end else begin

         copy(ts, 'n'); { form negative }
         cat(ts, a);
         if compp(w, ts) then begin

            f := false; { perform false }
            optfnd := true { set option found }

         end

      end

   end

end;

begin

   skpspc(cmdhan); { skip spaces }
   while chkchr(cmdhan) = optchr do begin { parse option }

      optfnd := false; { set no option found }
      getchr(cmdhan); { skip option marker }
      parlab(cmdhan, w, err); { parse option label }
      if err then errormsg('*** Invalid option');
      { there are no real options right now, this is a placeholder }
      setflg('v',  'verbose',  fverb); { verbose mode }
      if not optfnd then errormsg('*** No option found');
      skpspc(cmdhan) { skip spaces }

   end

end;

{*******************************************************************************

Push cursor coordinates

Saves the current cursor coordinates on the cursor coordinate stack.

*******************************************************************************}

procedure pshcur;

var p: crdptr; { coordinate entry pointer }

begin

   with viewcur^ do begin { open view context }

      new(p); { get a new stack entry }
      p^.next := curstk; { push onto stack }
      curstk := p;
      p^.x := curx(txtwin); { place save coordinates }
      p^.y := cury(txtwin)

   end

end;

{*******************************************************************************

Pop cursor coordinates

Restores the current cursor coordinates from the cursor coordinate stack.

*******************************************************************************}

procedure popcur;

var p: crdptr; { coordinate entry pointer }

begin

   with viewcur^ do begin { open view context }

      if curstk <> nil then begin { cursor stack is not empty }

         cursor(txtwin, curstk^.x, curstk^.y); { restore old cursor position }
         p := curstk; { remove from stack }
         curstk := curstk^.next;
         dispose(p) { release entry }

      end

   end

end;

{*******************************************************************************

Update line position

Redraws just the line position in the status line.

*******************************************************************************}

procedure statusl;

var linnum: packed array 7 of char;

begin

   with viewcur^ do begin { open view context }

      ints(linnum, linpos); { place line position in string }
      fcolor(stswin, backcolor); { fill space }
      frect(stswin, linsts.c.ul.x+strsiz(stswin, 'Line: '), linsts.c.ul.y, 
                    linsts.c.lr.x-strsizp(linnum), linsts.c.lr.y-1);
      fcolor(stswin, black);
      { position for justified right in rectangle }
      cursorg(stswin, linsts.c.lr.x-strsizp(linnum)+1, linsts.c.ul.y);
      write(stswin, linnum:0) { place line position }

   end

end;

{*******************************************************************************

Update character position

Redraws just the character position in the status line.

*******************************************************************************}

procedure statusc;

var chrnum: packed array 5 of char;

begin

   with viewcur^ do begin { open view context }

      ints(chrnum, poschr); { place character position in string }
      fcolor(stswin, backcolor); { fill space }
      frect(stswin, chrsts.c.ul.x+strsiz(stswin, 'Char: '), chrsts.c.ul.y, 
                    chrsts.c.lr.x-strsizp(chrnum), chrsts.c.lr.y-1);
      fcolor(stswin, black);
      { position for justified right in rectangle }
      cursorg(stswin, chrsts.c.lr.x-strsizp(chrnum)+1, chrsts.c.ul.y);
      write(stswin, chrnum:0) { place character position }

   end

end;

{*******************************************************************************

Update insert status

Redraws just the insert status in the status line.

*******************************************************************************}

procedure statusi;

begin

   with viewcur^ do begin { open view context }

      cursorg(stswin, inssts.c.ul.x, inssts.c.ul.y); { go to ins client }
      { write insert status }
      if insertc then write(stswin, 'Ins') else write(stswin, 'Ovr');
      fcolor(stswin, backcolor); { fill space }
      frect(stswin, curxg(stswin), inssts.c.ul.y, inssts.c.lr.x, inssts.c.lr.y-1);
      fcolor(stswin, black)

   end

end;

{*******************************************************************************

Update modify status

Redraws just the modify status in the status line.

*******************************************************************************}

procedure statusm;

begin

   with viewcur^, viewcur^.buffer^ do begin { open view and buffer context }

      cursorg(stswin, modsts.c.ul.x, modsts.c.ul.y); { go to ins client }
      { write insert status }
      if modify then write(stswin, 'Mod');
      fcolor(stswin, backcolor); { fill space }
      frect(stswin, curxg(stswin), modsts.c.ul.y, modsts.c.lr.x, modsts.c.lr.y-1);
      fcolor(stswin, black)

   end

end;

{*******************************************************************************

Place status 3d border

Places the 3d border on a status area. Actually, this could be a 3d shading
around any area.

*******************************************************************************}

procedure stsborder(view sr: stsrec);

begin

   fcolor(stswin, backcolor); { draw spacers }
   line(stswin, sr.b.ul.x, sr.b.ul.y, sr.b.lr.x, sr.b.ul.y); { top }
   line(stswin, sr.b.ul.x, sr.b.ul.y, sr.b.ul.x, sr.b.lr.y); { left }
   line(stswin, sr.b.lr.x, sr.b.ul.y, sr.b.lr.x, sr.b.lr.y); { right }
   line(stswin, sr.b.ul.x, sr.b.lr.y, sr.b.lr.x, sr.b.lr.y); { bottom }
   { left space to characters }
   line(stswin, sr.b.ul.x+2, sr.b.ul.y+2, sr.b.ul.x+2, sr.b.lr.y-2);
   fcolor(stswin, maxint div 2, maxint div 2, maxint div 2); { draw shadows }
   line(stswin, sr.b.ul.x+1, sr.b.ul.y+1, sr.b.lr.x-1, sr.b.ul.y+1); { top }
   line(stswin, sr.b.ul.x+1, sr.b.ul.y+1, sr.b.ul.x+1, sr.b.lr.y-2); { left }
   fcolor(stswin, white); { draw highlights }
   line(stswin, sr.b.ul.x+1, sr.b.lr.y-1, sr.b.lr.x-1, sr.b.lr.y-1); { bottom }
   line(stswin, sr.b.lr.x-1, sr.b.ul.y+2, sr.b.lr.x-1, sr.b.lr.y-1); { right }
   fcolor(stswin, black)
   
end;

{*******************************************************************************

Update status line

Draws the status line at screen bottom. The status line contains the name of
the current file, the line position, the character position, and the
insert/overwrite status.

The message area is multiple use, but gets the name of the current file in
edit by default.

To save on flashing, we draw the borders and other dressing only on redraws,
then each individual status area is drawn when changed. Also, the status
text is drawn progressive from left to right without clears.

*******************************************************************************}

procedure status;

begin

   line(stswin, 1, 1, maxxg(stswin), 1); { draw top divider line }

   { place 3d borders }

   stsborder(msgsts); { message area }
   stsborder(linsts); { line position }
   stsborder(chrsts); { character position }
   stsborder(inssts); { insert/overwrite }
   stsborder(modsts); { modify }

   { place file status in message position (the default) }

   cursorg(stswin, msgsts.c.ul.x, msgsts.c.ul.y); { position to message area }
   if len(viewcur^.buffer^.curfil) = 0 then begin

      fcolor(stswin, red);
      write(stswin, 'Buffer has no filename');
      fcolor(stswin, black)
   
   end else 
      { write filename into message area }
      write(stswin, 'File: ', viewcur^.buffer^.curfil:0);
   fcolor(stswin, backcolor); { fill space }
   frect(stswin, curxg(stswin), msgsts.c.ul.y, msgsts.c.lr.x, msgsts.c.lr.y-1);
   fcolor(stswin, black);

   { write the labels for line and character positions }

   cursorg(stswin, linsts.c.ul.x, linsts.c.ul.y); { position to line area }
   write(stswin, 'Line: ');
   cursorg(stswin, chrsts.c.ul.x, chrsts.c.ul.y); { position to character area }
   write(stswin, 'Char: ');

   { redraw individual status elements }

   statusl; { write line position }
   statusc; { write character position }
   statusi; { write insert/overwrite mode }
   statusm { write modify }

end;

{*******************************************************************************

Place information line on screen

Places the information line on screen. The specified string is placed on screen
at the status line position (bottom of screen), in the alert colors.
This will be overwritten by the next status change.

*******************************************************************************}

procedure info(view s: string);
 
begin

   cursorg(stswin, msgsts.c.ul.x, msgsts.c.ul.y); { position to message area }
   if max(s) <> 0 then write(stswin, s); { output string }
   fcolor(stswin, backcolor); { fill space }
   frect(stswin, curxg(stswin), msgsts.c.ul.y, msgsts.c.lr.x, msgsts.c.lr.y-1);
   fcolor(stswin, black)

end;

{*******************************************************************************

Process error

Places an information line in the status area, and aborts to input mode.

*******************************************************************************}

procedure errormsg(view s: string);
 
begin

   fcolor(stswin, red); { color error message red }
   cursorg(stswin, msgsts.c.ul.x, msgsts.c.ul.y); { position to message area }
   if max(s) <> 0 then write(stswin, s); { output string }
   fcolor(stswin, backcolor); { fill space }
   frect(stswin, curxg(stswin), msgsts.c.ul.y, msgsts.c.lr.x, msgsts.c.lr.y-1);
   fcolor(stswin, black);
   goto inputloop { back to input }

end;

{*******************************************************************************

Place line at buffer end

Places the given string at the end of the current editor buffer as a new line
entry.

*******************************************************************************}

procedure plclin(view s: string);

var lp: linptr; { pointer to line entry }
    i:  lininx; { index for line }

begin

   with viewcur^, viewcur^.buffer^ do begin { in view and buffer contexts }

      new(lp); { get a new line entry }
      new(lp^.str, len(s)); { get space for the true string length }
      { copy string into place without spaces }
      for i := 1 to max(lp^.str^) do lp^.str^[i] := s[i];
      { insert after line indexed as current }
      if linstr = nil then begin { this is the first line }

         lp^.next := lp; { self link the entry }
         lp^.last := lp;
         linstr := lp; { and place root }
         paglin := lp { place page pin }

      end else begin { store not empty }

         lp^.next := linstr; { link to next }
         lp^.last := linstr^.last; { link to last }
         lp^.next^.last := lp; { link next to this }
         lp^.last^.next := lp { link last to this }

      end;
      lincnt := lincnt+1 { count lines in buffer }

   end

end;

{*******************************************************************************

Write line to display

Outputs the given line, truncated to the screen width. The line is checked for
control characters, and if found, these are replaced by "\".

Does not clear the background.

*******************************************************************************}

procedure wrtlin(     y: integer; { position to place string }
                 view s: string); { string to place }

begin

   with viewcur^ do begin { in view and buffer contexts }

      cursor(txtwin, 1-chroff, y); { position to start of line }
      wrtstr(txtwin, s); { write string }
      { erase rest of line }
      fcolor(txtwin, white);
      frect(txtwin, curxg(txtwin), curyg(txtwin), 
                    maxxg(txtwin), curyg(txtwin)+chrsizy-1);
      fcolor(txtwin, black)

   end

end;

{*******************************************************************************

Update entire screen display

Repaints the entire screen, including body text and status line.

*******************************************************************************}

procedure update;

var lp: linptr;  { pointer to line entry }
    lc: integer; { line counter }

begin

   with viewcur^, viewcur^.buffer^ do begin { in view and buffer contexts }

      putbuf; { decache any buffered line }
      pshcur; { save cursor location }
      curvis(txtwin, false); { turn off cursor }
      lp := paglin; { index top of page line }
      { Update screen. We write one character beyond the bottom and right sides
        to account for partial characters. }
      for lc := 1 to maxy(txtwin)+1 do begin { write lines }

         if lp <> nil then begin { there is a line to write }

            wrtlin(lc, lp^.str^); { output line }
            lp := lp^.next; { next line }
            if lp = linstr then lp := nil { buffer wrapped around, signal end }

         end else wrtlin(lc, '') { blank out }

      end;
      curvis(txtwin, true); { turn on cursor }
      status; { replace status line }
      popcur { restore cursor location }

   end

end;

{*******************************************************************************

Adjust vertical scrollbar

Changes the vertical scrollbar position to reflect the current line, and the
size of the scrollbar to reflect the proportion of the buffer onscreen.

*******************************************************************************}

procedure posscl;

var f: real;

begin

   with viewcur^, viewcur^.buffer^ do begin { in view and buffer contexts }

      { find size of scrollbar }
      if lincnt = 0 then begin

         { buffer empty, set to defaults }
         scrollsiz(vsclwig, maxint div 10); { 1/10 bar }
         scrollpos(vsclwig, 0)

      end else begin

         f := maxy(txtwin); { get lines per screen in float }
         { set size }
         if maxy(txtwin) > lincnt then { clamp at max }
            scrollsiz(vsclwig, maxint)
         else { set proportional }
            scrollsiz(vsclwig, round(f*maxint/lincnt));
         f := linpos-1; { get current position }
         { Line count can exceed total lines, because we allow the cursor to go
           into "virtual space". We clamp the count at the maximum lines in
           buffer. }
         if linpos > lincnt then f := lincnt;
         { set position }
         if f*maxint/lincnt > maxint then { clamp }
            scrollpos(vsclwig, maxint)
         else { normal }
            scrollpos(vsclwig, round(f*maxint/lincnt))

      end

   end

end;

{*******************************************************************************

Form screen layout

Places or replaces the child windows forming the main window.

*******************************************************************************}

procedure layout;

var svw, svh: integer; { width and height of vertical scrollbar }
    shw, shh: integer; { width and height of vertical scrollbar }
    { top tabbar }
    ttabx, ttaby: integer; { origin }
    ttabw, ttabh: integer; { widget width and height }
    ttabcw, ttabch: integer; { client width and height }
    ttabox, ttaboy: integer; { offset to client area }
    { right tabbar }
    rtabx, rtaby: integer; { origin }
    rtabw, rtabh: integer; { widget width and height }
    rtabcw, rtabch: integer; { client width and height }
    rtabox, rtaboy: integer; { offset to right client area }

{ find new sizing on layout }

procedure sizlayout;

begin

   { perform scrollbar sizing }
   scrollvertsizg(svw, svh);
   scrollhorizsizg(shw, shh);
   { find sizes and offsets for tabbars }
   ttabx := 1;
   ttaby := 1;
   ttabw := maxxg;
   ttabh := maxyg-(chrsizy(stswin)+5); { all above status window }
   tabbarclientg(totop, maxxg, maxyg-(chrsizy(stswin)+5), ttabcw, ttabch, 
                 ttabox, ttaboy);
   if rtablst <> nil then begin { there is a right tabbar list }

      rtabx := 1;
      rtaby := 1;
      rtabw := maxxg;
      rtabh := maxyg-(chrsizy(stswin)+5); { all above status window }
      tabbarclientg(toright, maxxg, maxyg-(chrsizy(stswin)+5), rtabcw, rtabch,
                    rtabox, rtaboy);
      { now adjust the tabbar sizes for overlapping client areas }
      rtaby := rtaby+ttaboy-rtabox; { move right tab down to top client }
      rtabh := rtabh-rtaby+1; { adjust height to match }
      ttabw := ttabw-(ttabcw-rtabcw); { adjust top tab width }
      ttabcw := rtabcw;

   end;
   { adjust scrollbars to fit }
   svh := ttabch-shh;
   shw := ttabcw-svw

end;

{ layout status window }

procedure laysts;

var x: integer; { right hand bounding coordinates }

{ layout single status area indent from right }

procedure laystsind(var sr: stsrec;  { staus rectangle }
                        w:  integer); { width of text to accomodate in pixels }

begin

   { set total bounding rectangle }
   sr.b.ul.x := x-w-5; { set upper left }
   sr.b.ul.y := 2;
   sr.b.lr.x := x;
   sr.b.lr.y := maxyg(stswin);
   x := sr.b.ul.x-1; { set new right edge behind that }
   { now set the client area within that }
   sr.c.ul.x := sr.b.ul.x+3;
   sr.c.ul.y := sr.b.ul.y+2;
   sr.c.lr.x := sr.b.lr.x-2;
   sr.c.lr.y := sr.b.lr.y-1

end;

begin

   { set status window at bottom of main window }
   setsizg(stswin, maxxg, chrsizy(stswin)+5); { size to character with borders }
   setposg(stswin, 1, maxyg-(chrsizy(stswin)+5)+1); { place at end }
   { We layout the status area from right to left so that the status indicators
     hug the right side, and the message area fills the rest of the bar to the
     left. }
   x := maxxg(stswin); { start layout at right }
   laystsind(modsts, strsiz(stswin, 'Mod'));
   laystsind(inssts, strsiz(stswin, 'Ovr'));
   laystsind(chrsts, strsiz(stswin, 'Char: 99999'));
   laystsind(linsts, strsiz(stswin, 'line: 9999999'));

   { layout message area }

   { set total bounding rectangle }
   msgsts.b.ul.x := 1; { set upper left }
   msgsts.b.ul.y := 2;
   msgsts.b.lr.x := x;
   msgsts.b.lr.y := maxyg(stswin);
   { now set the client area within that }
   msgsts.c.ul.x := msgsts.b.ul.x+3;
   msgsts.c.ul.y := msgsts.b.ul.y+2;
   msgsts.c.lr.x := msgsts.b.lr.x-2;
   msgsts.c.lr.y := msgsts.b.lr.y-1

end;

begin

   sizlayout; { calculate sizing for layout }
   if ttabon then begin

      killwidget(ttabwig);
      ttabon := false

   end;
   if rtabon then begin

      killwidget(rtabwig);
      rtabon := false

   end;
   { place top tabbar }
   if ttabon then begin

      poswidgetg(ttabwig, ttabx, ttaby);
      sizwidgetg(ttabwig, ttabw, ttabh)

   end else begin

      tabbarg(ttabx, ttaby, ttabx+ttabw-1, ttaby+ttabh-1, ttablst, totop, 
              ttabwig);
      tabsel(ttabwig, ttabsel); { set current select }
      ttabon := true; { set top tabbar onscreen }

   end;
   if rtablst <> nil then begin { there is a right tabbar list }

      if rtabon then begin

         poswidgetg(rtabwig, rtabx, rtaby);
         sizwidgetg(rtabwig, rtabw, rtabh)

      end else begin

         tabbarg(rtabx, rtaby, rtabx+rtabw-1, rtaby+rtabh-1, rtablst, toright, 
                 rtabwig);
         rtabon := true

      end

   end;
   { set text window to all of client area above status line and bottom
     scrollbar, and to the left of the right scrollbar }
   setsizg(txtwin, ttabcw-svw, ttabch-shh); { size }
   setposg(txtwin, ttabx+ttabox, ttaby+ttaboy); { set to client area of tabbar }
   front(txtwin); { bring text pane above tabbar }
 
   laysts; { layout status bar }

   { place scrollbars at new locations }
   if vsclon then begin

      poswidgetg(vsclwig, ttabx+ttabox+ttabcw-1-svw+1, ttaby+ttaboy);
      sizwidgetg(vsclwig, svw, svh)

   end else
      scrollvertg(ttabx+ttabox+ttabcw-1-svw+1, ttaby+ttaboy, 
                  ttabx+ttabox+ttabcw-1, ttaby+ttaboy+svh-1, vsclwig);

   if hsclon then begin

      poswidgetg(hsclwig, ttabx+ttabox, ttaby+ttaboy+ttabch-1-shh+1);
      sizwidgetg(hsclwig, shw, shh)

   end else
      scrollhorizg(ttabx+ttabox, ttaby+ttaboy+ttabch-1-shh+1,
                   ttabx+ttabox+shw-1, ttaby+ttaboy+ttabch-1, hsclwig);
   vsclon := true; { set scrollbars onscreen }
   hsclon := true;
   { fill the hole at the upper right created by the tabbar overlap }
   if shmon then killwidget(shmwig); { kill previous background }
   backgroundg(ttabx+ttabw, ttaby, maxxg, rtaby-1, shmwig); { place new }
   shmon := true; { set placed }
   posscl { adjust scrollbars }
  
end;

{*******************************************************************************

Find current buffer line

Finds the current line in the buffer based on screen position, and returns
a line pointer to that entry.

*******************************************************************************}

function fndcur: linptr;

var lp: linptr;  { pointer to line }
    lc: integer; { line count }

begin

   with viewcur^, viewcur^.buffer^ do begin { in view and buffer contexts }

      lp := paglin; { index page pin }
      lc := cury(txtwin); { get current line position }
      while (lp <> nil) and (lc <> 1) do begin { walk down }

         lp := lp^.next; { next line }
         lc := lc-1; { count }
         { if we wrapped around to the starting line, that is the end }
         if lp = linstr then lp := nil

      end;
      fndcur := lp { return result }

   end

end;

{*******************************************************************************

Find line number for given line

Searches through the buffer to find the line number associated with the given
line, from 1 to n. If the line passed is nil, then it will be given a number of
1, on the idea that the buffer is empty.

This process is fairly inefficient, and we are moving to a system where the line
numbers are encoded with the line itself.

*******************************************************************************}

function fndnum(lp: linptr): integer;

var l: integer; { line number }
    p: linptr;  { line pointer }

begin

   l := 1; { set 1st line }
   if lp <> nil then begin { line to find isn't nil }

      p := viewcur^.buffer^.linstr; { index target buffer }
      while (p <> lp) and (p <> nil) do begin { traverse }

         p := p^.next; { next line }
         l := l+1; { count }
         { provide a safety for line not found }
         if p = viewcur^.buffer^.linstr then p := nil

      end

   end;

   fndnum := l { return result }

end;

{*******************************************************************************

Find ordinal number of view

Finds the ordinal number, 1-n, of a given view.

*******************************************************************************}

function viewnum(vp: viewptr): integer;

var vn: integer;
    p:  viewptr;

begin

   vn := 1; { set 1st view }
   p := viewlst; { index top of view list }
   while (p <> nil) and (p <> vp) do begin { search }

      p := p^.next; { next view }
      if p = viewlst then p := nil; { wrapped, signal complete to stop }
      vn := vn+1 { count views }

   end;

   viewnum := vn { return result }

end;

{*******************************************************************************

Set cursor to line/character position

Finds the cursor position based on the given line, character and screen 
offset, then sets that active. This routine is used to resync the cursor after
a wholesale movement.

*******************************************************************************}

procedure setcursor;

var x, y: integer;
    pl:   integer; { line number for page pin }

begin

   with viewcur^ do begin { in view and buffer contexts }

      x := poschr+chroff; { set current x position }
      pl := fndnum(paglin); { find the line number for the page }
      y := linpos-pl+1; { find the y offset to current line }
      cursor(txtwin, x, y) { set resulting cursor }

   end

end;

{*******************************************************************************

Pull current line to buffer

The current line is "pulled" to the input buffer. In order to keep from
generating a lot of fractional lines, we keep the current line in a fixed
length buffer during edit on that line. Pulling a line is done before any
within-line edit procedure is done.

*******************************************************************************}

procedure getbuf;

var lp: linptr;  { pointer to current line }
    i:  integer; { index for line }

begin

   with viewcur^.buffer^ do begin { in buffer context }

      if not buflin then begin { line not in buffer }

         clears(inpbuf); { clear input buffer }
         lp := fndcur; { find current line }
         if lp <> nil then { the line exists, copy into buffer }
            for i := 1 to max(lp^.str^) do inpbuf[i] := lp^.str^[i];
         buflin := true; { set line in buffer }
         modify := true; { set we have modified the file }
         statusm { set modified status }

      end

   end

end;

{*******************************************************************************

Put buffer to current line

If the current line is held in the input buffer, we put it back to the current
line position. This is done by disposing of the contents of the old string,
and allocating and filling a new string.

It is possible for the current line to be null, which means that the buffer
is in the "virtual" space below the bottom of the file. In this case, we must
allocate a series of blank lines until we reach the current line position.
Since any command that moves off the current line will run into problems with
the fiction that having the current line cached in the buffer causes, this
routine should be called before any such movement or operation.

*******************************************************************************}

procedure putbuf;

var lp: linptr;  { pointer to current line }
    i:  integer; { index for line }
    lc: integer; { line counter }
    l:  integer; { length of buffered line }

begin

   with viewcur^, viewcur^.buffer^ do begin { in view and buffer contexts }

      if buflin then begin { the line is in the buffer }

         lp := fndcur; { find the current line }
         if lp = nil then begin { beyond end, create lines }

            { find number of new lines needed }
            lp := paglin; { index page pin }
            lc := cury(txtwin); { get current line position }
            while lp <> nil do begin { walk down }

               lp := lp^.next; { next line }
               lc := lc-1; { count }
               { if we wrapped around to the starting line, that is the end }
               if lp = linstr then lp := nil

            end;
            { place blank lines to fill }
            while lc > 0 do begin plclin(''); lc := lc-1 end;
            lp := fndcur { now find that }

         end;
         { ok, there is a dirty (but workable) trick here. notice that if we
           have created blank lines below the buffer, we will be disposing of
           that newly created blank line. this does not waste storage, however,
           because zero length allocations don't actually exist }
         dispose(lp^.str); { remove old line }
         l := len(inpbuf); { find length of buffered line }
         new(lp^.str, l); { create a new string }
         for i := 1 to l do lp^.str^[i] := inpbuf[i]; { copy to string }
         buflin := false { set line not in buffer }

      end

   end

end;

{*******************************************************************************

Append to string list

Appends a new string to a string list.

*******************************************************************************}

procedure addstr(var sl: strptr; view s: string);

var p, lp: strptr;

begin

   { find end of list }
   lp := nil; { set no last }
   p := sl; { index top of list }
   while p <> nil do begin { traverse }

      lp := p; { set last }
      p := p^.next { index next }

   end;
   new(p); { get new string }
   p^.next := nil; { clear next }
   copy(p^.str, s); { place string }
   if lp= nil then sl := p { insert at list top }
   else lp^.next := p { insert at buttom }

end;

{*******************************************************************************

Read file into buffer

Creates a new buffer at the end of the buffers list, then loads the given file
to that buffer. This is then set into the current view.

*******************************************************************************}

procedure readfile(view fn: string); { file to read }

var f:       text;    { text file }
    ln:      linbuf;  { input line buffer }
    ovf:     boolean; { overflow error flag }
    p, n, e: filnam;  { path components }

begin

   brknam(fn, p, n, e); { break filename to components }
   if not exists(fn) then
      info('*** Edit file does not exist ***')
   else begin { file exists, read it }

      info('Reading file');
      getedit; { add new buffer }
      getview; { add a new view for that }
      addstr(ttablst, n); { add new filename to tab lst }
      viewcur := viewlst^.last; { index last in list for view }
      viewcur^.buffer := buflst^.last; { attach view to new buffer }
      ttabsel := viewnum(viewcur); { set top tab to that }
      with viewcur^, viewcur^.buffer^ do begin { open view and buffer contexts }

         copy(curfil, fn); { place filename }
         assign(f, fn); { open the input file }
         reset(f);
         while not eof(f) do begin { read lines }

            reads(f, ln, ovf); { get the next line }
            readln(f); { skip line }
            if ovf then errormsg('*** Line too long to edit');
            plclin(ln); { place in edit buffer }

         end;
         close(f); { close input file }
         paglin := linstr; { index top of buffer }
         curlin := linstr; { set current edit line }
         layout; { refresh tab arrangements }
         update; { display that }
         setcursor; { set cursor }
         posscl { update the scrollbar }

      end

   end

end;

{*******************************************************************************

Write file from buffer

The current buffer is saved to the named file.

*******************************************************************************}

procedure writefile(view fn: filnam); { file to write }

var p, n, e: filnam; { filename components }
    bcknam:  filnam; { name for backup file }
    f:       text;   { text file }
    lp:      linptr; { pointer for buffer lines }

begin

   with viewcur^, viewcur^.buffer^ do begin { open view and buffer contexts }

      putbuf; { decache any buffered line }
      if exists(fn) then begin { process backup }

         brknam(fn, p, n, e); { break down filename }
         maknam(bcknam, p, n, 'bak'); { make backup name }
         if exists(bcknam) then delete(bcknam); { delete if exists }
         change(bcknam, fn) { move old file to backup }

      end;
      assign(f, fn); { open new file }
      rewrite(f);
      if linstr <> nil then begin { the file is not empty }

         lp := linstr; { index top of buffer }
         repeat { save lines }

            writeln(f, lp^.str^); { write this line to file }
            lp := lp^.next { next line in buffer }

         until lp = linstr { buffer wrapped }
      
      end;
      close(f); { close the file }
      info('File saved');
      modify := false; { reset buffer modify flag }
      statusm { set modify status }

   end

end;

{*******************************************************************************

Move up one line

Moves the cursor position up one line. If the cursor is already at the top
of screen, then the screen is scrolled up to the next line (if it exists).

*******************************************************************************}

procedure movup;

begin

   with viewcur^, viewcur^.buffer^ do begin { open view and buffer contexts }

      putbuf; { decache any buffer }
      if linstr <> nil then begin { buffer not empty }

         if (paglin <> linstr) or (cury(txtwin) > 1) then begin

            { not at top of buffer, or not at top of displayed page }
            linpos := linpos-1; { adjust line count }
            { if we aren't already at the top of screen, we can just move up }
            if cury(txtwin) > 1 then begin

               up(txtwin); { move cursor up }
               statusl { update just line position field }

            end else begin { gotta scroll }

               curvis(txtwin, false); { turn off cursor }
               scroll(txtwin, 0, -1); { scroll the screen down }
               paglin := paglin^.last; { move page pin up }
               pshcur; { save cursor position }
               home(txtwin); { go to top line }
               wrtlin(1, paglin^.str^); { output that line }
               popcur; { restore cursor position }
               curvis(txtwin, true); { turn on cursor }
               posscl; { adjust scrollbars }
               status { update status line }

            end;

         end

      end

   end

end;

{*******************************************************************************

Move down one line

Moves the cursor position down one line. If the cursor is already at the bottom
of screen, then the screen is scrolled down to the next line (if it exists).
Note that we allow positioning past the end of the buffer by one screen minus
one lines worth of text, which would leave the last line at the top.

*******************************************************************************}

procedure movdwn;

var lc: integer; { line counter }
    lp: linptr;  { line pointer }

begin

   with viewcur^, viewcur^.buffer^ do begin { open view and buffer contexts }

      putbuf; { decache any buffer }
      if linstr <> nil then begin { buffer not empty }

         if (cury(txtwin) < maxy(txtwin)) or 
            (paglin^.next <> linstr) then begin { not at last line }

            { Not last line on screen, or more lines left in buffer. We are a
              "virtual space" editor, so we fake lines below the buffer end
              as being real }
            linpos := linpos+1; { adjust line count }
            { if we aren't already at the bottom of screen, we can just move
              down }
            if cury(txtwin) < maxy(txtwin) then begin

               down(txtwin); { move cursor down }
               statusl { update just line position field }

            end else begin { gotta scroll }

               curvis(txtwin, false); { turn off cursor }
               scroll(txtwin, 0, +1); { scroll the screen up }
               paglin := paglin^.next; { move page pin down }
               { see if a line exists to fill the new slot }
               lc := 1; { set 1st line }
               lp := paglin;
               { while not end of buffer, and on valid screen portion }
               while (lp <> linstr) and (lc < maxy(txtwin)) do begin

                  lp := lp^.next; { index next line }
                  lc := lc+1 { count }

               end;
               if (lp <> linstr) and (lc <= maxy(txtwin)) then begin

                  { new line exists }
                  pshcur; { save cursor position }
                  wrtlin(maxy(txtwin), lp^.str^); { output that line }
                  { write one line beyond the end to account for partial lines }
                  if lp^.next <> linstr then
                     wrtlin(maxy(txtwin)+1, lp^.next^.str^) { output that line }
                  else
                     wrtlin(maxy(txtwin)+1, ''); { blank out }
                  popcur { restore cursor position }

               end;
               curvis(txtwin, true); { turn on cursor }
               posscl; { adjust scrollbars }
               status; { repaint status line }

            end

         end

      end

   end

end;

{*******************************************************************************

Move left one character

If we are not already at the extreme left, moves the cursor one character to
the left.

*******************************************************************************}

procedure movlft;

begin

   with viewcur^ do begin { open view context }

      if curx(txtwin) > 1 then begin { not at extreme left }

         left(txtwin); { move cursor left }
         poschr := poschr-1; { track character position }
         statusc { update just character position field }

      end else if chroff > 0 then begin { go screen left }

         chroff := chroff-1; { screen left one character }
         poschr := poschr-1; { move position one character left }
         update { redraw display }
         
      end

   end

end;

{*******************************************************************************

Move right one character

If we are not already at the extreme right, moves the cursor one character to
the right.

*******************************************************************************}

procedure movrgt;

begin

   with viewcur^ do begin { open view context }

      if curx(txtwin) < maxx(txtwin) then begin { not at extreme right }

         right(txtwin); { move cursor right }
         poschr := poschr+1; { track character position }
         statusc { update just character position field }

      end else if chroff < maxint then begin { go screen right }

         chroff := chroff+1; { screen right one character }
         poschr := poschr+1; { move position one character right }
         update { redraw display }

      end

   end

end;

{*******************************************************************************

Move left one word

If we are not already at the extreme left, moves the cursor over any spaces to
the left, then over any non-space characters to the left.

*******************************************************************************}

procedure movlftw;

var lp:       linptr; { current edit line pointer }
    backsave: integer; { backup position save }

{ get character at current edit position }

function chkchr: char;

var c: char;

begin

   with viewcur^, viewcur^.buffer^ do begin { open view and buffer contexts }

      if buflin then begin { perform buffered version }

         if poschr > maxlin then c := ' ' { return space for off end right }
         else c := inpbuf[poschr]; { return actual character }

      end else begin { perform in place version }

         if poschr > max(lp^.str^) then 
            c := ' ' { return space for off end right }
         else c := lp^.str^[poschr]; { return actual character }

      end

   end;

   chkchr := c { return result }

end;

begin

   with viewcur^ do begin { open view context }

      lp := fndcur; { index current line }
      if lp <> nil then begin { there is a line }

         { back up before current word }
         if poschr > 1 then poschr := poschr-1;
         { back up over any spaces }
         while (poschr > 1) and (chkchr = ' ') do poschr := poschr-1;
         backsave := poschr; { save position }
         { back up over any non-spaces }
         while (poschr > 1) and (chkchr <> ' ') do begin

            backsave := poschr; { save last character }
            poschr := poschr-1;

         end;
         poschr := backsave; { now go back to word start }
         if (poschr-chroff >= 1) and (poschr-chroff <= maxx(txtwin)) then begin

            { position still on current screen, go to it }
            cursor(txtwin, poschr-chroff, cury(txtwin));
            statusc { update just character position field }

         end else begin { move screen left }

            chroff := poschr-1; { position screen so left is character }
            cursor(txtwin, 1, cury(txtwin)); { go to screen left }
            update { redraw screen }

         end

      end

   end

end;

{*******************************************************************************

Move right one word

If we are not already at the extreme right, moves the cursor over any spaces to
the right, then over any non-space characters to the right.

*******************************************************************************}

procedure movrgtw;

var lp: linptr; { current edit line pointer }

{ get character at current edit position }

function chkchr: char;

var c: char;

begin

   with viewcur^, viewcur^.buffer^ do begin { open view and buffer contexts }

      if buflin then begin { perform buffered version }

         if poschr > maxlin then c := ' ' { return space for off end right }
         else c := inpbuf[poschr]; { return actual character }

      end else begin { perform in place version }

         if poschr > max(lp^.str^) then 
            c := ' ' { return space for off end right }
         else c := lp^.str^[poschr]; { return actual character }

      end

   end;

   chkchr := c { return result }

end;

{ find maximum length of edit string }

function maxstr: integer;

var m: integer;

begin

   if viewcur^.buffer^.buflin then m := maxlin { set buffered length }
   else m := max(lp^.str^);

   maxstr := m { return result }

end;

begin

   with viewcur^ do begin { open view context }

      lp := fndcur; { index current line }
      if lp <> nil then begin { there is a line }

         { forward over any non-spaces }
         while (poschr <= maxstr) and (chkchr <> ' ') do poschr := poschr+1;
         { forward over any spaces }
         while (poschr <= maxstr) and (chkchr = ' ') do poschr := poschr+1;
         if (poschr-chroff >= 1) and (poschr-chroff <= maxx(txtwin)) then begin

            { position still on current screen, go to it }
            cursor(txtwin, poschr-chroff, cury(txtwin));
            statusc { update just character position field }

         end else begin { move screen right }

            { position screen so right is character }
            chroff := poschr-maxx(txtwin);
            cursor(txtwin, maxx(txtwin), cury(txtwin)); { go to screen left }
            update { redraw screen }

         end

      end

   end

end;

{*******************************************************************************

Go to top of document

Moves the cursor to the top of the document.

*******************************************************************************}

procedure movhom;

begin

   with viewcur^, viewcur^.buffer^ do begin { open view and buffer contexts }

      putbuf; { decache any buffer }
      if linstr <> nil then begin { buffer not empty }

         linpos := 1; { set 1st line }
         poschr := 1; { set 1st character }
         if paglin = linstr then begin

            { we are at top, just move the cursor there }
            home(txtwin); { move home }
            status { update status }

         end else begin { not at top, go there }

            paglin := linstr; { set page to home }
            posscl; { adjust scrollbars }
            update { redraw }

         end

      end

   end

end;

{*******************************************************************************

Go to bottom of document

Moves the cursor to the bottom of the document.

*******************************************************************************}

procedure movend;

var lp: linptr;  { line pointer }
    lc: integer; { line count }
    oc: integer; { offset count }

begin

   with viewcur^, viewcur^.buffer^ do begin { open view and buffer contexts }

      putbuf; { decache any buffer }
      if linstr <> nil then begin { buffer not empty }

         lc := lincnt; { set last line }
         lp := linstr^.last;
         { The "offset count" is the number of lines to back off from the true
           end of the file. This is choosen to be 1/2 screenfull }
         oc := (maxy(txtwin)-1) div 2;
         { now back up to the offset point, or the beginning of file }
         while (lp <> linstr) and (oc <> 0) do begin { back up }

            lp := lp^.last; { index last line }
            oc := oc-1; { count }
            lc := lc-1

         end;
         linpos := lincnt; { set new line position }
         poschr := len(linstr^.last^.str^)+1; { set new character position }
         if lp <> paglin then begin { we are not already there }

            paglin := lp; { set new position }
            posscl; { adjust scrollbars }
            update; { redraw }

         end;
         cursor(txtwin, poschr-chroff, (maxy(txtwin)-1) div 2+1)
                  

      end

   end

end;

{*******************************************************************************

Go to start of line

Moves the cursor to the start of the current line..

*******************************************************************************}

procedure movhoml;

begin

   with viewcur^ do begin { open view context }

      poschr := 1; { update position }
      cursor(txtwin, 1, cury(txtwin)); { move cursor }
      if chroff > 0 then begin { not at extreme left }

         chroff := 0; { clear offset }
         update { redo display }

      end else statusc { update status }

   end

end;

{*******************************************************************************

Go to end of line

Moves the cursor to the end of the current line..

*******************************************************************************}

procedure movendl;

var lp: linptr; { pointer to line }

begin

   with viewcur^, viewcur^.buffer^ do begin { open view and buffer contexts }

      if buflin then begin { line is in buffer }

         poschr := len(inpbuf)+1 { set new position }

      end else begin { line is in file }

         lp := fndcur; { find current line }
         if lp <> nil then poschr := len(lp^.str^)+1 { set new position }
         else poschr := 1 { no line, position to start for empty line }

      end;
      { If the new position is off the screen right, we will follow it in the
        display. }
      if poschr-chroff > maxx(txtwin) then begin

         chroff := poschr-maxx(txtwin); { position so that cursor is at right end }
         update

      end else statusc; { update status }
      cursor(txtwin, poschr-chroff, cury(txtwin)) { move cursor }

   end

end;

{*******************************************************************************

Go to top of screen

Moves the cursor to the top of the current screen.

*******************************************************************************}

procedure movhoms;

begin

   with viewcur^ do begin { open view contexts }

      putbuf; { decache any buffer }
      linpos := linpos-cury(txtwin)+1; { set new position }
      poschr := 1+chroff;
      home(txtwin); { position cursor }
      status { update status line }

   end

end;

{*******************************************************************************

Go to bottom of screen

Moves the cursor to the bottom of the current screen.

*******************************************************************************}

procedure movends;

var lp: linptr; { pointer to line }
    d:  integer; { line difference }

begin

   with viewcur^, viewcur^.buffer^ do begin { open view and buffer contexts }

      putbuf; { decache any buffer }
      d := maxy(txtwin)-cury(txtwin); { find line difference }
      linpos := linpos+d; { set new position }
      lp := fndcur; { find current line }
      while (d > 0) and (lp <> nil) do begin { move down in lines }

         lp := lp^.next; { move down in lines }
         d := d-1; { count }
         if lp = linstr then lp := nil { flag end of buffer }

      end;
      if lp <> linstr then poschr := len(lp^.str^)+1 { set new position }
      else poschr := 1+chroff; { no line, position to start for empty line }
      cursor(txtwin, poschr-chroff, maxy(txtwin)); { move cursor }
      statusc { update status }

   end

end;

{*******************************************************************************

Page up

Moves the position up by one screen minus one lines worth of text. One line
of overlap is allowed to give the user some context.
If there is not that much text above, we just position to the top of document.

*******************************************************************************}

procedure pagup;

var cnt: integer;

begin

   with viewcur^, viewcur^.buffer^ do begin { open view and buffer contexts }

      putbuf; { decache any buffer }
      if paglin <> nil then begin { buffer not empty }

         if paglin = linstr then begin { already at top, just home cursor }

            linpos := 1; { set new position }
            cursor(txtwin, poschr, 1); { set to top of screen }
            status { update status line }

         end else begin

            { find number of lines on a page, minus status and slop line }
            cnt := maxy(txtwin)-2;
            { move up to appropriate line }
            while (cnt > 0) and (paglin^.last <> nil) and (paglin <> linstr) do
               begin

               paglin := paglin^.last; { move up one line }
               cnt := cnt-1; { count lines }
               linpos := linpos-1

            end;
            pshcur; { push cursor coordinates }
            update; { redraw }
            popcur; { restore cursor coordinates }
            posscl { adjust scrollbars }

         end

      end

   end

end;

{*******************************************************************************

Page down

Moves the position down by one screen minus one lines worth of text. One line
of overlap is allowed to give the user some context.
We allow positioning beyond the end of document by one screen minus one line
of text. If there is not that many lines to the "virtual end point", we just
position to the virtual end point.

*******************************************************************************}

procedure pagdwn;

var cnt: integer;

begin

   with viewcur^, viewcur^.buffer^ do begin { open view and buffer contexts }

      putbuf; { decache any buffer }
      if paglin <> nil then begin { buffer not empty }

         if paglin^.next <> linstr then begin { not at end of buffer }

            { find number of lines on a page, minus status and slop line }
            cnt := maxy(txtwin)-2;
            { move down to appropriate line }
            while (cnt > 0) and (paglin^.next <> nil) and 
                  (paglin^.next <> linstr) do begin

               paglin := paglin^.next; { move down one line }
               cnt := cnt-1; { count lines }
               linpos := linpos+1

            end;
            pshcur; { push cursor coordinates }
            update; { redraw }
            popcur; { restore cursor coordinates }
            posscl { adjust scrollbars }

         end

      end

   end

end;

{*******************************************************************************

Goto line

Goto the given line.

*******************************************************************************}

procedure goline(l: integer);

begin

   with viewcur^, viewcur^.buffer^ do begin { open view and buffer contexts }

      putbuf; { decache any buffer }
      linpos := 1; { set 1st line }
      paglin := linstr;
      if paglin <> nil then begin { buffer not empty }

         while (linpos < l) and (paglin^.next <> linstr) do begin { next line }

            linpos := linpos+1; { next line }
            paglin := paglin^.next

         end;
         update; { redraw }
         posscl { adjust scrollbars }

      end

   end

end;

{*******************************************************************************

Scroll up one line

The screen is scrolled up by one line, revealing at new line at bottom.

*******************************************************************************}

procedure scrup;

begin

   with viewcur^, viewcur^.buffer^ do begin { open view and buffer contexts }

      putbuf; { decache any buffer }
      if paglin <> linstr then begin { not empty and not at buffer top }

         { not at top of buffer, or not at top of displayed page }
         linpos := linpos-1; { adjust line count }
         curvis(txtwin, false); { turn off cursor }
         scroll(txtwin, 0, -1); { scroll the screen down }
         paglin := paglin^.last; { move page pin up }
         pshcur; { save cursor position }
         home(txtwin); { go to top line }
         if max(paglin^.str^) <> 0 then 
            write(txtwin, paglin^.str^); { write revealed line over blanks }
         popcur; { restore cursor position }
         curvis(txtwin, true); { turn on cursor }
         posscl; { adjust scrollbars }
         status { update status line }

      end

   end

end;

{*******************************************************************************

Scroll down one line

The screen is scrolled down by one line, revealing at new line at top.

*******************************************************************************}

procedure scrdwn;

var lc: integer; { line counter }
    lp: linptr;  { line pointer }

begin

   with viewcur^, viewcur^.buffer^ do begin { open view and buffer contexts }

      putbuf; { decache any buffer }
      if linstr <> nil then begin { buffer not empty }

         if paglin^.next <> linstr then begin { not at last line }

            curvis(txtwin, off); { turn off cursor }
            linpos := linpos+1; { adjust line count }
            scroll(txtwin, 0, +1); { scroll the screen up }
            paglin := paglin^.next; { move page pin down }
            { see if a line exists to fill the new slot }
            lc := 1; { set 1st line }
            lp := paglin;
            { while not end of buffer, and on valid screen portion }
            while (lp <> linstr) and (lc < maxy(txtwin)) do begin

               lp := lp^.next; { index next line }
               lc := lc+1 { count }

            end;
            if (lp <> linstr) and (lc <= maxy(txtwin)) then begin

               { new line exists }
               pshcur; { save cursor position }
               wrtlin(maxy(txtwin), lp^.str^); { output that line }
               { write one line beyond the end to account for partial lines }
               if lp^.next <> linstr then
                  wrtlin(maxy(txtwin)+1, lp^.next^.str^) { output that line }
               else
                  wrtlin(maxy(txtwin)+1, ''); { blank out }
               popcur { restore cursor position }

            end;
            curvis(txtwin, on); { turn on cursor }
            posscl; { adjust scrollbars }
            status { repaint status line }

         end

      end

   end

end;

{*******************************************************************************

Scroll left one character

The screen is scrolled left by one character.

*******************************************************************************}

procedure scrlft;

begin

   with viewcur^ do begin { open view context }

      if chroff > 0 then begin { scroll left one character }

         chroff := chroff-1; { move character left }
         poschr := poschr-1;
         update { redraw }

      end

   end

end;

{*******************************************************************************

Scroll right one character

The screen is scrolled right one character.

*******************************************************************************}

procedure scrrgt;

begin

   with viewcur^ do begin { open view context }

      if chroff < maxint then begin { scroll right one character }

         chroff := chroff+1; { move character left }
         poschr := poschr+1;
         update { redraw }

      end

   end

end;

{*******************************************************************************

Track mouse movements

Updates the mouse location when it moves.

*******************************************************************************}

procedure moumov;

begin

   mpx := er.moupx; { save current mouse coordinates }
   mpy := er.moupy

end;

{*******************************************************************************

Handle mouse button assert

Performs the action for a mouse button assert. If the mouse position points
to the valid screen area (in the text pane and not the status line), then we
change the cursor location to equal that.

*******************************************************************************}

{ mouse button assert }

procedure mouass;

begin

   with viewcur^ do begin { open view context }

      if mpy <= maxy(txtwin) then begin

         { not on status line }
         linpos := linpos+(mpy-cury(txtwin)); { set new position }
         poschr := mpx;
         cursor(txtwin, mpx, mpy); { place cursor at new position }
         status { update status line }
         
      end

   end

end;

{*******************************************************************************

Toggle insert mode

Changes the insert/overwrite status to the opposite mode. Updates the display.

*******************************************************************************}

procedure togins;

begin

   insertc := not insertc; { insert toggle }
   statusi { update display }

end;

{*******************************************************************************

Enter character

Enters a single character to the current edit position. First, the line is
"pulled" to a buffer. Then, the character is inserted at the current character
position, and the line and status redrawn.

*******************************************************************************}

procedure entchr(c: char);

var i: integer; { index for line }
    y: integer; { cursor y save }
    l: integer; { length of current line }

begin

   with viewcur^, viewcur^.buffer^ do begin { open view and buffer contexts }

      if insertc then begin { process using insert mode }

         getbuf; { pull line to buffer }
         l := len(inpbuf); { find current length of line }
         if l < maxlin then begin { we have room to place }

            { move up buffer to make room }
            for i := l downto poschr do inpbuf[i+1] := inpbuf[i];
            inpbuf[poschr] := c; { place character }
            y := cury(txtwin); { save location y }
            curvis(txtwin, false); { turn off cursor }
            write(txtwin, c); { write new character }
            { output the rest of the line }
            for i := poschr+1 to l+1 do write(txtwin, inpbuf[i]);
            if poschr < maxlin then { not at end of buffer }
               poschr := poschr+1; { advance character position }
            { If the new position is off the screen right, we will follow it in the
              display. }
            if poschr-chroff > maxx(txtwin) then begin
            
               { position so that cursor is at right end }
               chroff := poschr-maxx(txtwin);
               update
            
            end else statusc; { update status }
            cursor(txtwin, poschr-chroff, y); { restore cursor to new position }
            curvis(txtwin, true) { turn one cursor }

         end;

      end else { process using overwrite mode }
         if poschr < maxlin then begin { we have room to place }

         getbuf; { pull line to buffer }
         y := cury(txtwin); { save location y }
         inpbuf[poschr] := c; { place character }
         write(txtwin, c); { place character on screen }
         if poschr < maxlin then { not at end of buffer }
            poschr := poschr+1; { advance character position }
         { If the new position is off the screen right, we will follow it in the
           display. }
         if poschr-chroff > maxx(txtwin) then begin
         
            { position so that cursor is at right end }
            chroff := poschr-maxx(txtwin);
            update
         
         end else statusc; { update status }
         cursor(txtwin, poschr-chroff, y) { restore cursor to new position }
         
      end

   end

end;

{*******************************************************************************

Delete back

The character to the left of the cursor is removed, and all the characters
to the right are moved left one character.

*******************************************************************************}

procedure delbwd;

var i: integer; { index for line }
    l: integer; { length of line }
    y: integer; { y position save }

begin

   with viewcur^, viewcur^.buffer^ do begin { open view and buffer contexts }

      if poschr > 1 then begin { not already at extreme left }

         getbuf; { pull line to buffer }
         y := cury(txtwin); { save location y }
         { gap character }
         for i := poschr to maxlin do inpbuf[i-1] := inpbuf[i];
         inpbuf[maxlin] := ' '; { fill last position }
         poschr := poschr-1; { set new character position }
         left(txtwin); { move cursor left }
         l := len(inpbuf); { find length of input buffer }
         curvis(txtwin, false); { turn off cursor }
         for i := poschr to l do write(txtwin, inpbuf[i]); { replace line }
         if l < maxx(txtwin) then write(txtwin, ' '); { blank out last position }
         cursor(txtwin, poschr-chroff, y); { restore position }
         curvis(txtwin, true); { turn on cursor }
         statusc { update character position field }
         
      end

   end

end;

{*******************************************************************************

Delete forward

The character at the cursor is removed,and all the characters to the right of
the cursor are moved left one character.

*******************************************************************************}

procedure delfwd;

var i: integer; { index for line }
    l: integer; { length of line }
    y: integer; { y position save }

begin

   with viewcur^, viewcur^.buffer^ do begin { open view and buffer contexts }

      if poschr < maxx(txtwin) then begin { not already at extreme right }

         getbuf; { pull line to buffer }
         y := cury(txtwin); { save location y }
         { gap character }
         for i := poschr to maxlin-1 do inpbuf[i] := inpbuf[i+1];
         inpbuf[maxlin] := ' '; { fill last position }
         l := len(inpbuf); { find length of input buffer }
         curvis(txtwin, false); { turn off cursor }
         for i := poschr to l do write(txtwin, inpbuf[i]); { replace line }
         if l < maxx(txtwin) then 
            write(txtwin, ' '); { blank out last position }
         cursor(txtwin, poschr-chroff, y); { restore position }
         curvis(txtwin, true); { turn on cursor }
         statusc { update character position field }
         
      end

   end

end;

{*******************************************************************************

Delete line

Deletes the line indicated by the pointer. The line is delinked from the edit
buffer, then both the string and the entry are disposed of.

*******************************************************************************}

procedure dellinptr(lp: linptr); { line to delete }

begin

   with viewcur^.buffer^ do begin { open buffer context }

      if lp^.next = lp then linstr := nil { last entry, clear out }
      else begin

         { crossover link the left and right entries }
         lp^.next^.last := lp^.last;
         lp^.last^.next := lp^.next;
         if lp = linstr then linstr := lp^.next { step off entry }

      end;
      dispose(lp^.str); { release attached string }
      dispose(lp) { release space from entry }

   end

end;

{*******************************************************************************

Delete line

The current line, if it exists, is deleted.

*******************************************************************************}

procedure dellin;

var lp: linptr; { line pointer }

begin

   with viewcur^ do begin { open view context }

      putbuf; { decache any buffered line }
      lp := fndcur; { find current line }
      if lp <> nil then begin { there is a line to delete }
         
         { If there is only one line in the buffer, the page pin gets nulled. }
         if lp^.next = lp then paglin := nil
         { if top of page line is deleted, move forward one line }
         else if paglin = lp then paglin := lp^.next;
         dellinptr(lp); { delete the line }
         update { redraw }

      end

   end

end;

{*******************************************************************************

Tab

In overwrite mode, we simply position to the next tab. In insert mode, we
insert enough spaces to reach the next tab.

*******************************************************************************}

procedure tab;

begin

   with viewcur^, viewcur^.buffer^ do begin { open view and buffer contexts }

      if poschr < maxlin then { not at extreme right }
         repeat { output spaces }

            entchr(' ') { place a single space }

         until (poschr >= maxlin) or ((poschr-1) mod 8 = 0) or 
               (len(inpbuf) >= maxlin)

   end

end;

{*******************************************************************************

Enter new line

Enters a new blank line after the current line, and positions to it.

*******************************************************************************}

procedure entlin;

var lp: linptr; { current line pointer }
    np: linptr; { new line pointer }
    sp: pstring; { string holder }

begin

   with viewcur^, viewcur^.buffer^ do begin { open view and buffer contexts }

      putbuf; { decache any edit line }
      lp := fndcur; { find current line }
      if lp <> nil then begin { line exists }

         if (poschr > len(lp^.str)) and (lp^.next = linstr) then begin

            { New line would be empty, and at the bottom of the buffer. Just 
              move down instead. }
            movdwn; { down to new line we created }
            movhoml { move home }

         end else begin { split or mid buffer line }

            new(np); { get a new line entry }
            np^.next := lp^.next; { link to next }
            np^.last := lp; { link to last }
            np^.next^.last := np; { link next to this }
            np^.last^.next := np; { link last to this }
            { now split the existing line }
            if poschr <= len(lp^.str^) then begin { within existing line }

               { form new line from remainder of old }
               np^.str := extract(lp^.str, poschr, len(lp^.str));
               sp := lp^.str; { save old line }
               { form old line from clipped }
               lp^.str := extract(lp^.str, 1, poschr-1);
               dispose(sp) { release old string }
   
            end else np^.str := copy(''); { create new blank string }
            movdwn; { down to new line we created }
            movhoml; { move home }
            modify := true; { set we have modified the file }
            update { redraw }

         end

      end else begin

         { Buffer empty, or off end of buffer. Newline becomes down then home. 
           We don't need to worry about line creation until the user actually
           types non-blank data. }
         movdwn; { down to new line we created }
         movhoml { move home }

      end

   end

end;

{*******************************************************************************

Ask user yes/no question on info line

Asks the user a yes/no question directly on the user line. The alternative to
this procedure is to open a dialog. The info line method takes less screen
space, and does not require the user to switch their focus. Returns with the
answer variable true if the user answered yes, otherwise false.

The user interface is run during this Q and A, but all user action is locked
out. The redraw and resize functions are maintained.

*******************************************************************************}

procedure yesno(view qs:  string;   { question string }
                var  ans: boolean); { answer from user }

var stop: boolean; { stop input flag }
    er:   evtrec;  { event record }

begin

   info(qs); { place question string }
   curvis(stswin, on); { turn cursor on }
   { wait for answer }
   stop := false; { set no stop }
   repeat

      event(er); { get next event }
      { do limited event handling to maintain window and get answer }
      case er.etype of

         etredraw:  update; { repaint screen }
         etresize:  layout; { resize }
         etchar:    if lcase(er.char) = 'n' then begin

            ans := false; { place answer }
            stop := true { halt input }

         end else if lcase(er.char) = 'y' then begin { yes }

            ans := true; { place answer }
            stop := true { halt input }

         end;
         else { ignore all else }

      end

   until stop; { until finished }
   curvis(stswin, off); { turn cursor off }
   status { restore status line }

end;

{*******************************************************************************

Clear edit buffer to new file

Opens a new, empty buffer.

*******************************************************************************}

procedure newedit;

begin

   getedit; { add new buffer }
   getview; { add a view for that }
   addstr(ttablst, '<untitled>');
   viewcur := viewlst^.last; { set current view is last view }
   viewcur^.buffer := buflst^.last; { attach view to new buffer }
   update { redraw screen }

end;

{*******************************************************************************

Search string

Executes a search for the given string, starting at the current edit position.
The resulting search leaves the edit position at the found string, or leaves 
the position unchanged if not found.

If the string is found on the same line, we go to that by simple positioning.
If the string is further into the buffer, we try to center it onscreen,
much like the rolling editor. The idea is that if the user is paying attention
to the current line, we stay there, otherwise we redirect attention to a
predictable place, screen center.

*******************************************************************************}

procedure search(view schstr: string; view schopts: qfnopts);

var i:  integer; { index for found string }
    lp: linptr;  { line pointer }
    lc: integer; { line counter }
    f:  boolean; { found flag }

{ highlight search string }

procedure highlight;

var i: integer; { index for string }

begin

   with viewcur^ do begin { open view context }

      standout(txtwin, on); { turn on standout mode }
      { write in highlight }
      for i := poschr to poschr+max(schstr)-1 do 
         write(txtwin, lp^.str^[i]);
      cursor(txtwin, poschr-chroff, cury(txtwin)); { restore cursor }
      standout(txtwin, off); { turn off standout }
      timer(hightim, 2*second, false) { set off highlight timer }

   end

end;

begin

   refer(schopts);

   with viewcur^, viewcur^.buffer^ do begin { open view and buffer contexts }

      f := false; { set not found }
      putbuf; { putback any buffer }
      lp := fndcur; { index current edit string }
      if lp <> nil then begin { not empty or off end of buffer }

         { search within current line so we can reject what's behind }
         i := index(lp^.str^, schstr); { search unbuffered line }
         if i > poschr then begin { found }

            f := true; { set found }
            poschr := i; { set position to found point }
            { redisplay to get new position }
            if (poschr-chroff >= 1) and 
               (poschr-chroff <= maxx(txtwin)) then begin

               { position still on current screen, go to it }
               cursor(txtwin, poschr-chroff, cury(txtwin));
               statusc { update just character position field }

            end else begin { move screen right }

               { position screen so right is character }
               chroff := poschr-maxx(txtwin);
               cursor(txtwin, maxx(txtwin), cury(txtwin)); { go to screen left }
               update { redraw screen }

            end;
            highlight { turn on highlight }

         end else begin { search lines past present }

            repeat { search lines }

               i := 0; { set not found }
               lp := lp^.next; { next line }
               if lp <> linstr then begin { not past end of buffer }
  
                  i := index(lp^.str^, schstr); { search unbuffered line }
                  if i > 0 then begin { found }

                     f := true; { set found }
                     poschr := i; { set position to found point }
                     paglin := linstr; { find current line }
                     linpos := 1;
                     while paglin <> lp do begin { count off }

                        paglin := paglin^.next; { next line in buffer }
                        linpos := linpos+1 { count }

                     end;
                     lc := maxy(txtwin) div 2; { set lines to middle }
                     { back page up to middle of screen, if possible }
                     while (paglin <> linstr) and (lc > 0) do begin

                        paglin := paglin^.last; { back up }
                        lc := lc-1 { count }

                     end;
                     update; { redraw }
                     posscl; { adjust scrollbars }
                     curlin := lp; { set current line pointer }
                     setcursor; { reset cursor to that position }
                     highlight { turn on highlight }

                  end

               end

            until (i > 0) or (lp = linstr) { until found or end of buffer }

         end

      end;
      if not f then errormsg('Search string not found')

   end

end;

{*******************************************************************************

Excecute menu functions

Executes any of the many menu functions. The menu function number is passed.

*******************************************************************************}

procedure menufunc(mf: integer);

var opnnam:  pstring; { open/save file name }

begin

   case mf of { menu activation }

      smnew: newedit; { clear to new edit buffer }
      smopen: begin { open file by dialog }

         copy(opnnam, '*'); { set no previous name }
         queryopen(opnnam); { query open name }
         if len(opnnam^) > 0 then readfile(opnnam^) { user didn't cancel, open }

      end;
      smclose: errormsg('Function not implemented');
      smsave: 
         writefile(viewcur^.buffer^.curfil); { save file under current name }
      smsaveas: begin { save file as name }

         copy(opnnam, '*'); { set no previous name }
         querysave(opnnam); { query save name }
         if len(opnnam^) > 0 then begin { user didn't cancel }

            copy(viewcur^.buffer^.curfil, opnnam^); { place name to open }
            writefile(viewcur^.buffer^.curfil)

         end

      end;
      smpageset:   errormsg('Function not implemented');
      smprint:     errormsg('Function not implemented'); 
      smexit: quit := true; { flag quit }
      smundo:      errormsg('Function not implemented'); 
      smcut:       errormsg('Function not implemented'); 
      smpaste:     errormsg('Function not implemented'); 
      smdelete:    errormsg('Function not implemented'); 
      smfind:      begin

         queryfind(schstr, schopts); { query find string }
         if len(schstr^) > 0 then { user didn't cancel }
            search(schstr^, schopts) { perform search }
         
      end;
      smfindnext:  errormsg('Function not implemented'); 
      smreplace:   errormsg('Function not implemented'); 
      smgoto:      errormsg('Function not implemented'); 
      smselectall: errormsg('Function not implemented'); 
      smnewwindow: errormsg('Function not implemented'); 
      smtilehoriz: errormsg('Function not implemented'); 
      smtilevert:  errormsg('Function not implemented'); 
      smcascade:   errormsg('Function not implemented'); 
      smcloseall:  errormsg('Function not implemented'); 
      smhelptopic: errormsg('Function not implemented'); 
      smabout:     errormsg('Function not implemented'); 
      else { ignore }

   end

end;

{*******************************************************************************

Excecute function key function

Executes any of the function key actions. The function key number is passed.

*******************************************************************************}

procedure funckey(fn: integer);

begin

   case fn of { function }

      1: writefile(viewcur^.buffer^.curfil); { save under current name }
      9: { switch to next buffer }
         if viewcur^.next <> viewcur then begin { not the only view }

         viewcur := viewcur^.next; { index next buffer }
         ttabsel := ttabsel+1; { next tab select }
         if viewcur = viewlst then ttabsel := 1; { view wrapped }
         tabsel(ttabwig, ttabsel); { set current select }
         if viewcur = viewlst then ttabsel := 1; { if we wrapped, reset select }
         update; { redraw to new buffer }
         setcursor { set cursor }
     
      end;
      else errormsg('Function not implemented')

   end

end;

{*******************************************************************************

Check any buffer is modified

Checks all of the buffers in the buffers list, and returns true if any are
modified. This check is used to verify exits.

*******************************************************************************}

function bufmod: boolean;

var m: boolean;
    bp: bufptr;

begin

   m := false; { set not modified }
   bp := buflst; { index top of buffer list }
   if bp <> nil then { there are buffers active }
      repeat { traverse buffers }

         if bp^.modify then m := true; { set modified }
         bp := bp^.next { next buffer }

      until bp = buflst; { until we wrap around }

   bufmod := m { return result }

end;

{*******************************************************************************

View select

Select a new view to display by ordinal number. The number of the view is
passed, and we match this to the view it selects. Then that view is set
as the active view for the current window.

*******************************************************************************}

procedure viewsel(vn: integer);

var vp: viewptr; { view header pointer }

begin

   ttabsel := vn; { set tab to view }
   vp := viewlst; { index top of view list }
   if vp <> nil then begin { there are views }

      while (vn <> 1) and (vp^.next <> viewlst) do begin { count off views }

         vp := vp^.next; { next view }
         vn := vn-1 { count }

      end;
      if vp <> viewcur then begin { not already the current view }

         viewcur := vp; { set new current view }
         update; { redraw to new buffer }
         setcursor { set cursor location }

      end;

   end
   
end;

begin

   refer(error); { keep error file }
   refer(dmpview); { dump view is a diagnostic }

   buflst := nil; { clear buffer list }
   viewlst := nil; { view list }
   viewcur := nil; { set current view }
   mpx := 0; { set mouse is nowhere }
   mpy := 0;
   insertc := true; { set insert mode on }
   vsclon := false; { set no scrollbars placed }
   hsclon := false;
   shmon := false;
   ttabon := false; { set tabbars not placed }
   rtabon := false;
   ttablst := nil; { clear tabbar string lists }
   ttabsel := 1; { clear tab select }
   rtablst := nil;
   fverb := true; { set verbose mode }
   schstr := copy(''); { clear search string }
   schopts := []; { clear search options }
   { We have to create a buffer and view before we are fully up, so that it
     can be displayed. This will become the default edit buffer if the user
     does not select one. }
   getedit; { add new buffer }
   getview; { get a view for that }
   addstr(ttablst, '<untitled>');
   viewcur := viewlst; { set view as current view }
   viewcur^.buffer := buflst; { attach view to new buffer }

   { throw the splash window whilst we load }
   openwin(input, splwin, splwid);
   frame(splwin, off); { turn off frame }
   loadpict(splwin, splpic, 'splash'); { load the splash image }
   { find required window for image (which should be unity) }
   winclientg(splwin, pictsizx(splwin, splpic), pictsizy(splwin, splpic), w, h,
              []);
   scnsizg(dsw, dsh); { get desktop width and height }
   setsizg(splwin, w, h); { set window size }
   { place splash screen center }
   setposg(splwin, dsw div 2-w div 2, dsh div 2-h div 2);
   curvis(splwin, off); { turn off cursor }
   picture(splwin, splpic, 1, 1, w, h); { place }
   timer(spltim, splons, false); { start splash timer }

   title('IP Pascal Integrated Development Environment');
   { create the menu }
   stdmenu([smnew, smopen, smclose, smsave, smsaveas, smpageset, smprint, 
            smexit, smundo, smcut, smpaste, smdelete, smfind, smfindnext,
            smreplace, smgoto, smselectall, smnewwindow, smtilehoriz,
            smtilevert, smcascade, smcloseall, smhelptopic, smabout], sm, nil);
   menu(sm);
   auto(output, false); { turn off scrolling }
   buffer(off); { turn off screen buffering }
   autohold(off); { turn off automatic hold }

   { create text area and status window }
   openwin(input, txtwin, output, txtwid); { create text pane }
   auto(txtwin, off); { turn off scrolling }
   buffer(txtwin, off); { turn off buffering }
   frame(txtwin, off); { turn off frame }
   openwin(input, stswin, output, stswid); { create status pane }
   auto(stswin, off); { turn off scrolling }
   buffer(stswin, off); { turn off buffering }
   frame(stswin, off); { turn off frame }
   bcolor(stswin, backcolor); { color the status window }
   curvis(stswin, off); { don't need cursor in the status window }
   font(stswin, font_sign); { set to sign font }
   bold(stswin, on); { set bold }
   front(splwin); { keep splash window ontop }
   layout; { layout child windows }
   update; { present blank screen }
   front(splwin); { keep splash window ontop }

   { process command line }
   openpar(cmdhan); { open parser }
   openfil(cmdhan, '_command', cmdmax); { open command line level }
   filchr(valfch); { get the filename valid characters }
   valfch := valfch-['=']; { remove parsing characters }
   setfch(cmdhan, valfch); { set that for active parsing }
   clears(editnam); { clear command line edit name }
   paropt; { parse command options }
   while not endlin(cmdhan) do begin { parse edit names }

      skpspc(cmdhan); { skip spaces }
      if chkchr(cmdhan) = '"' then { parse string }
         parstr(cmdhan, editnam, err) { get string parameter }
      else 
         parfil(cmdhan, editnam, false, err); { parse filename }
      if err then errormsg('*** Invalid filename');
      fulnam(editnam); { find full name }
      readfile(editnam); { read the file in }
      paropt; { parse command options }
      skpspc(cmdhan) { skip spaces }

   end;

   { This is the central return point for the input loop. It's where we come
     back after any errors. }

   inputloop: { return to input level }

   { The screen is initalized with the specified file. Now we enter the event
     loop }
   repeat { event loop }

      quit := false; { set no quit }
      event(input, er); { get the next event }
      case er.etype of { event }

         etchar:    entchr(er.char); { ASCII character returned }
         etup:      movup; { cursor up one line }
         etdown:    movdwn; { down one line }
         etleft:    movlft; { left one character }
         etright:   movrgt; { right one character }
         etleftw:   movlftw; { left one word }
         etrightw:  movrgtw; { right one word }
         ethome:    movhom; { home of document }
         ethomes:   movhoms; { home of screen }
         ethomel:   movhoml; { home of line }
         etend:     movend; { end of document }
         etends:    movends; { end of screen }
         etendl:    movendl; { end of line }
         etscrl:    scrlft; { scroll left one character }
         etscrr:    scrrgt; { scroll right one character }
         etscru:    scrup; { scroll up one line }
         etscrd:    scrdwn; { scroll down one line }
         etpagu:    pagup; { page up }
         etpagd:    pagdwn; { page down }
         ettab:     tab; { tab }
         etenter:   entlin; { enter line }
         etinsert:  ; { insert block }
         etinsertl: ; { insert line }
         etinsertt: togins; { insert toggle }
         etdel:     ; { delete block }
         etdell:    dellin; { delete line }
         etdelcf:   delfwd; { delete character forward }
         etdelcb:   delbwd; { delete character backward }
         etcopy:    ; { copy block }
         etcopyl:   ; { copy line }
         etcan:     ; { cancel current operation }
         etstop:    ; { stop current operation }
         etcont:    ; { continue current operation }
         etprint:   ; { print document }
         etprintb:  ; { print block }
         etprints:  ; { print screen }
         etfun:     funckey(er.fkey); { functions }
         etmouba:   mouass; { mouse button assertion }
         etmoubd:   ; { mouse button deassertion }
         etmoumov:  moumov; { mouse move }
         etredraw:  {if er.winid = txtwid then} update; { repaint screen }
         etresize:  {if er.winid = txtwid then} layout; { resize }
         etsclull:  begin if er.sclulid = vsclwig then scrup end;
         etscldrl:  begin if er.scldlid = vsclwig then scrdwn end;
         etsclulp:  begin if er.sclupid = vsclwig then pagup end;
         etscldrp:  begin if er.scldpid = vsclwig then pagdwn end;
         etsclpos:  if er.sclpid = vsclwig then begin 

            f := er.sclpos; 
            goline(round(f*viewcur^.buffer^.lincnt/maxint)+1) 

         end;
         ettim:     if er.timnum = spltim then 
                       close(splwin) { close splash screen }
                    { This is kinda blunt. We could refresh only the line we are
                      on. }
                    else if er.timnum = hightim then update; { remove highlight }
         etmenus:   menufunc(er.menuid); { menu activation }
         ettabbar:  if er.tabid = ttabwig then 
                       viewsel(er.tabsel); { view select }
         etterm:    quit := true; { register quit request }
         else       { all others, do nothing }

      end;
      if quit and bufmod then 
         { quiting with modified buffer, validate from user }
         yesno('Buffer(s) have been modified, really exit (y/n)? ', quit)

   until quit { until quit requested and validated }

end.
