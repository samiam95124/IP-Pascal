{*******************************************************************************
*                                                                              *
*                              TEXT EDITTOR                                    *
*                                                                              *
*                                VS. 0.1                                       *
*                                                                              *
*                           COPYRIGHT (C) 1996                                 *
*                                                                              *
*                              S. A. MOORE                                     *
*                                                                              *
* A basic text edittor, built for MOORE/CAD Pascal with the Uniface library,   *
* text level.                                                                  *
* Implements simple editting on a single screen/single buffer system. All of   *
* the Uniface standard controls work, and the following extra functions are    *
* implemented:                                                                 *
*                                                                              *
*    F1 - Search                                                               *
*    F2 - Search again                                                         *
*    F3 - Replace                                                              *
*    F4 - Replace again                                                        *
*    F5 - Record macro start/stop                                              *
*    F6 - Playback macro                                                       *
*                                                                              *
*******************************************************************************}

program editor(command, input, output);

uses trmlib, { uniface text level }
     strlib;

label inputloop, { return to input mode }
      stopprog; { terminate program }

const

   maxlin = 250; { maximum entered line, must be greater than maxx }
   maxfil = 40;  { maximum length of filename }

type

   lininx  = 1..maxlin; { index for line buffer }
   linbuf  = packed array [lininx] of char; { line buffer }
   linptr  = ^line; { pointer to line entry }
   { the lines in the edit buffer are stored as a double linked list of
     dynamically allocated strings }
   line    = record { line store entry }

      next: linptr; { next line in store }
      last: linptr; { last line in store }
      str:  ^string { string data }

   end;
   filinx = 1..maxfil; { index for filename }
   filbuf = packed array [filinx] of char; { filename }
   crdptr = ^crdrec; { pointer to coordinate store }
   crdrec = record { cursor coordinate save }

      next: crdptr; { next entry }
      x, y: integer { cursor coordinates }

   end;

var

   inpbuf:  linbuf;  { input line buffer }
   buflin:  boolean; { current line in buffer flag }
   linstr:  linptr;  { edit lines storage }
   paglin:  linptr;  { top of page line }
   lincnt:  integer; { number of lines in buffer }
   chrcnt:  integer; { number of characters in buffer }
   linpos:  integer; { current line }
   poschr:  integer; { current character on line }
   curfil:  filbuf;  { current file to edit }
   er:      evtrec;  { next event record }
   curstk:  crdptr;  { cursor coordinate stack }
   mpx:     integer; { mouse coordinates x }
   mpy:     integer; { mouse coordinates y }
   insertc: boolean; { insert/overwrite toggle }
   cmdlin:  linbuf;  { command line }
   cmdptr:  lininx;  { command line pointer }

procedure errormsg(view s: string); forward; 

{*******************************************************************************

Get command line

The command line is loaded to the given buffer.

*******************************************************************************}

procedure getcmd(var lin: string);

var i: integer;  { command line index }

begin

   for i := 1 to max(lin) do lin[i] := ' '; { clear input line }
   i := 1; { set 1st line position }
   while not eoln(command) do begin { load command line }

     read(command, lin[i]); { get next character }
     { check line overflow }
     if i = maxlin then errormsg('*** Command input line overflow ***');
     i := i+1 { next character position }

   end

end;

{*******************************************************************************

Check end of line

Checks whether the input line position is at the end. This is indicated by 
cmdptr being at the extreme end of the input line.
Note that in order to ensure that this is true, a skip space to line end
should be done.

*******************************************************************************}

function endlin: boolean;

begin

   endlin := cmdptr = maxlin { true if at line maximum }

end;

{*******************************************************************************

Check next input character

The next character in the input buffer is returned. No advance
is made from the current position (succesive calls to this
procedure will yeild the same character).

*******************************************************************************}

function chkchr: char; { current input character }

var c: char; { result }

begin

   if endlin then c := ' ' { buffer end, just simulate spaces }
   else c := cmdlin[cmdptr]; { not at buffer end, return character }
   chkchr := c { return result }

end;

{*******************************************************************************

Skip input character

Causes the current input character to be skipped, so that the next chkchr call
will return the next character. If endlin is true, no action will take place
(will not advance beyond end of line).

*******************************************************************************}

procedure getchr;

begin

   if not endlin then { process advance }
      cmdptr := cmdptr+1 { advance one character }

end;

{*******************************************************************************

Skip input spaces or controls

Skips the input position past any spaces or controls. Will skip the end of 
line, loading the next line from the input. The view of the input is for each 
line to be terminated by an infinite series of blanks, which only this routine
will cross.

*******************************************************************************}

procedure skpspc;

begin

   { skip any spaces }
   while (chkchr = ' ') and not endlin do getchr

end;

{*******************************************************************************

Parse file name

Parses a filename in the format:

     <filename> ::= [<letter>:]<letter>[<letter>/<digit>/'.']...
     <letter>   ::= 'a'..'z'/'A'..'Z'
     <digit>    ::= '0'..'9'

Obviously, this routine is MS-DOS dependent. If more than 10 total characters
are used (d:ffffffff.eee), an error is generated. The file string so parsed is
returned in place, and an error 'mode' parameter indicates whether or not a file
name parsing error would be fatal to the assembly.

*******************************************************************************}

procedure parnam(var fn: filbuf); { file name return }

var i: filinx; { file name index }
    p: 0..8;   { primary length }

procedure getncr; { get name character }

begin

   if i > maxfil then errormsg('*** Filename too long');
   fn[i] := chkchr; { place file character }
   getchr; { skip that }
   i := i + 1 { next }

end;

procedure getseq(max: filinx); { read name sequence }

var l : 0..maxfil; { length of filename }

begin

   l := 0; { initalize count }
   while chkchr in ['_', 'a'..'z', 'A'..'Z', '0'..'9'] do begin

      { filename }
      getncr; { get character }
      l := l + 1 { count }

   end;
   if l > max then errormsg('*** Filename too long');

end;

begin

   skpspc; { skip spaces }
   clears(fn); { clear filename }
   i := 1; { initalize index }
   p := 1; { initalize primary count for first character }
   if not (chkchr in ['_', 'a'..'z', 'A'..'Z']) then
      errormsg('*** Invalid filename');
   getncr; { get character }
   if chkchr = ':' then begin { process drive specification }

      getncr; { get character }
      if not (chkchr in ['_', 'a'..'z', 'A'..'Z']) then
         errormsg('*** Invalid filename');
      p := 0 { re - initalize primary }

   end;
   getseq(8 - p); { get rest of primary }
   if chkchr = '.' then begin { secondary }

      getncr; { get character }
      if not (chkchr in ['_', 'a'..'z', 'A'..'Z', '0'..'9']) then
         errormsg('*** Invalid filename');
      getseq(3) { get secondary }

   end

end;

{*******************************************************************************

Parse command line

The structure of a command line is:

     file

The file is parsed into intnam.

*******************************************************************************}

procedure parcmd;

begin

   cmdptr := 1; { set 1st character in command line }
   parnam(curfil); { parse file }
   skpspc; { skip to line end }
   { check we are at line end }
   if not endlin then writeln('*** Invalid command syntax')

end;

{*******************************************************************************

Assign string

Copies the contents of one general string to another.

*******************************************************************************}

procedure strass(var ds: string;   { string to assign to }
                 view ss: string); { string to assign from }

var i: integer; { index for strings }

begin

   if max(ss) > max(ds) then begin { string too large }

      page; { clear screen }
      { output error }
      writeln('*** String to large for destination');
      halt { exit }

   end;
   { copy characters from source to destination }
   for i := 1 to max(ss) do ds[i] := ss[i];
   { clear the remaining space in destination }
   for i := max(ss)+1 to max(ds) do ds[i] := ' '

end;

{*******************************************************************************

Push cursor coordinates

Saves the current cursor coordinates on the cursor coordinate stack.

*******************************************************************************}

procedure pshcur;

var p: crdptr; { coordinate entry pointer }

begin

   new(p); { get a new stack entry }
   p^.next := curstk; { push onto stack }
   curstk := p;
   p^.x := curx(output); { place save coordinates }
   p^.y := cury(output)

end;

{*******************************************************************************

Pop cursor coordinates

Restores the current cursor coordinates from the cursor coordinate stack.

*******************************************************************************}

procedure popcur;

var p: crdptr; { coordinate entry pointer }

begin

   if curstk <> nil then begin { cursor stack is not empty }

      cursor(output, curstk^.x, curstk^.y); { restore old cursor position }
      p := curstk; { remove from stack }
      curstk := curstk^.next;
      dispose(p) { release entry }

   end

end;

{*******************************************************************************

Update status line

Draws the status line at screen bottom. The status line contains the name of
the current file, the line position, the character position, and the
insert/overwrite status.

*******************************************************************************}

procedure status;
 
begin

   curvis(output, false); { turn off cursor }
   pshcur; { save cursor position }
   standout(output, true); { turn on standout }
   bcolor(output, cyan); { a nice (light) blue, if you please }
   cursor(output, 1, maxy(output)); { position to end line on screen }
   write('File: ', curfil, ' Line: ', linpos:6, ' Char: ', poschr:3);
   if insertc then write(' Ins') else write(' Ovr'); { write insert status }
   while curx(output) < maxx(output) do write(' '); { blank out the rest }
   write(' ');
   bcolor(output, white); { back to white }
   standout(output, false); { turn off standout }
   popcur; { restore cursor position }
   curvis(output, true) { turn on cursor }

end;

{*******************************************************************************

Update line position

Redraws just the line position in the status line.

*******************************************************************************}

procedure statusl;

begin

   curvis(output, false); { turn off cursor }
   pshcur; { save cursor position }
   bcolor(output, cyan); { a nice (light) blue, if you please }
   standout(output, true); { enable standout }
   cursor(output, 54, maxy(output)); { go to line position field }
   write(linpos:6); { update cursor position }
   bcolor(output, white); { reset color }
   standout(output, false); { disable standout }
   popcur; { restore cursor position }
   curvis(output, true) { turn on cursor }

end;

{*******************************************************************************

Update character position

Redraws just the character position in the status line.

*******************************************************************************}

procedure statusc;

begin

   curvis(output, false); { turn off cursor }
   pshcur; { save cursor position }
   bcolor(output, cyan); { a nice (light) blue, if you please }
   standout(output, true); { enable standout }
   cursor(output, 67, maxy(output)); { go to character position field }
   write(poschr:3); { update cursor position }
   bcolor(output, white); { reset color }
   standout(output, false); { disable standout }
   popcur; { restore cursor position }
   curvis(output, true) { turn on cursor }

end;

{*******************************************************************************

Update insert status

Redraws just the insert status in the status line.

*******************************************************************************}

procedure statusi;

begin

   curvis(output, false); { turn off cursor }
   pshcur; { save cursor position }
   bcolor(output, cyan); { a nice (light) blue, if you please }
   standout(output, true); { enable standout }
   cursor(output, 71, maxy(output)); { go to character position field }
   if insertc then write('Ins') else write('Ovr'); { write insert status }
   bcolor(output, white); { reset color }
   standout(output, false); { disable standout }
   popcur; { restore cursor position }
   curvis(output, true) { turn on cursor }

end;

{*******************************************************************************

Place information line on screen

Places the information line on screen. The specified string is placed on screen
at the status line position (bottom of screen), in the alert colors.
This will be overwritten by the next status change.

*******************************************************************************}

procedure info(view s: string);
 
begin

   curvis(output, false); { turn off cursor }
   pshcur; { save cursor position }
   standout(output, true); { turn on standout }
   bcolor(output, yellow); { place alert color }
   cursor(output, 1, maxy(output)); { position to end line on screen }
   if max(s) <> 0 then write(s); { output string }
   while curx(output) < maxx(output) do write(' '); { blank out the rest }
   write(' ');
   bcolor(output, white); { back to white }
   standout(output, false); { turn off standout }
   popcur; { restore cursor position }
   curvis(output, true) { turn on cursor }

end;

{*******************************************************************************

Process error

Places an information line in the status area, and aborts to input mode.

*******************************************************************************}

procedure errormsg(view s: string);
 
begin

   info(s); { place error message }
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

   new(lp); { get a new line entry }
   new(lp^.str, len(s)); { get space for the true string length }
   { copy string into place without spaces }
   for i := 1 to max(lp^.str^) do lp^.str^[i] := s[i];
   { insert after line indexed as current }
   if linstr = nil then begin { this is the first line }

      lp^.next := lp; { self link the entry }
      lp^.last := lp;
      linstr := lp { and place root }

   end else begin { store not empty }

      lp^.next := linstr; { link to next }
      lp^.last := linstr^.last; { link to last }
      lp^.next^.last := lp; { link next to this }
      lp^.last^.next := lp { link last to this }

   end;
   lincnt := lincnt+1 { count lines in buffer }

end;

{*******************************************************************************

Write line to display

Outputs the given line, truncated to the screen width. The line is checked for
control characters, and if found, these are replaced by "\".

*******************************************************************************}

procedure wrtlin(     y: integer; { position to place string }
                 view s: string); { string to place }

var i: integer; { string index }

begin

   cursor(output, 1, y); { position to start of line }
   for i := 1 to maxx(output) do begin { write characters }

      if i > max(s) then write(' ') { pad end with blanks }
      else if s[i] >= ' ' then write(s[i]) { output as is }
      else begin { is a control character }

         fcolor(output, red); { place in red }
         bcolor(output, yellow);
         write(chr(ord(s[i])+ord('@'))); { output as control sequence }
         fcolor(output, black); { back to normal }
         bcolor(output, white)

      end

   end

end;

{*******************************************************************************

Update entire screen display

Repaints the entire screen, including body text and status line.

*******************************************************************************}

procedure update;

var lp: linptr;  { pointer to line entry }
    lc: integer; { line counter }
    y:  integer; { y position holder }

begin

   curvis(output, false); { turn off cursor }
   page; { clear screen and home cursor }
   lp := paglin; { index top of page line }
   lc := maxy(output)-1; { set number of lines to output }
   y := 1; { set 1st line }
   if lp <> nil then repeat { write lines }

      wrtlin(y, lp^.str^); { output line }
      lp := lp^.next; { next line }
      y := y+1;
      lc := lc-1 { count available lines on screen }

   until (lp = linstr) or (lc = 0); { until we wrap around, or screen full }
   curvis(output, true); { turn on cursor }
   status; { replace status line }
   home(output); { place cursor at home }

end;

{*******************************************************************************

Read text line

Reads a line from the given text file into a string buffer.
This routine should check for overflow.

*******************************************************************************}

procedure getlin(var f: text;    { file to read }
                 var s: string); { string to read to }

var i: integer; { index for string }

begin

   for i := 1 to max(s) do s[i] := ' '; { clear destination line }
   i := 1; { set 1st character position }
   while not eoln(f) do begin { read line characters }

      { should check for line overflow }
      read(f, s[i]); { get the next character }
      i := i+1

   end;
   readln(f) { skip line end }

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

   lp := paglin; { index page pin }
   lc := cury(output); { get current line position }
   while (lp <> nil) and (lc <> 1) do begin { walk down }

      lp := lp^.next; { next line }
      lc := lc-1; { count }
      { if we wrapped around to the starting line, that is the end }
      if lp = linstr then lp := nil

   end;
   fndcur := lp { return result }

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

   if not buflin then begin { line not in buffer }

      for i := 1 to maxlin do inpbuf[i] := ' '; { clear input buffer }
      lp := fndcur; { find current line }
      if lp <> nil then { the line exists, copy into buffer }
         for i := 1 to max(lp^.str^) do inpbuf[i] := lp^.str^[i];
      buflin := true { set line in buffer }

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

   if buflin then begin { the line is in the buffer }

      lp := fndcur; { find the current line }
      if lp = nil then begin { beyond end, create lines }

         { find number of new lines needed }
         lp := paglin; { index page pin }
         lc := cury(output); { get current line position }
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
      { ok, there is a dirty (but workable) trick here. notice that if we have
        created blank lines below the buffer, we will be disposing of that
        newly created blank line. this does not waste storage, however, because
        zero length allocations don't actually exist }
      dispose(lp^.str); { remove old line }
      l := len(inpbuf); { find length of buffered line }
      new(lp^.str, l); { create a new string }
      for i := 1 to l do lp^.str^[i] := inpbuf[i]; { copy to string }
      buflin := false { set line not in buffer }

   end

end;

{*******************************************************************************

Read file into buffer

The current buffer is cleared, and the given file is read in as a new buffer
contents.

*******************************************************************************}

procedure readfile(view fn: filbuf); { file to read }

var f:  text;   { text file }
    ln: linbuf; { input line buffer }

begin

   putbuf; { decache any buffer }
   if not exists(fn) then
      info('*** Edit file does not exist ***')
   else begin { file exists, read it }

      info('Reading file');
      { we should dispose of existing lines before this operation }
      linstr := nil; { clear lines buffer }
      lincnt := 0; { clear total lines }
      chrcnt := 0; { clear total characters }
      linpos := 1; { set 1st line }
      poschr := 1; { set 1st character }
      assign(f, fn); { open the input file }
      reset(f);
      while not eof(f) do begin { read lines }

         getlin(f, ln); { get the next line }
         plclin(ln); { place in edit buffer }

      end;
      close(f); { close input file }
      paglin := linstr; { index top of buffer }
      update { display that }

   end

end;

{*******************************************************************************

Move up one line

Moves the cursor position up one line. If the cursor is already at the top
of screen, then the screen is scrolled up to the next line (if it exists).

*******************************************************************************}

procedure movup;

begin

   putbuf; { decache any buffer }
   if linstr <> nil then begin { buffer not empty }

      if (paglin <> linstr) or (cury(output) > 1) then begin

         { not at top of buffer, or not at top of displayed page }
         linpos := linpos-1; { adjust line count }
         { if we aren't already at the top of screen, we can just move up }
         if cury(output) > 1 then begin

            up(output); { move cursor up }
            statusl { update just line position field }

         end else begin { gotta scroll }

            curvis(output, false); { turn off cursor }
            scroll(output, 0, -1); { scroll the screen down }
            paglin := paglin^.last; { move page pin up }
            pshcur; { save cursor position }
            home(output); { go to top line }
            wrtlin(1, paglin^.str^); { output that line }
            popcur; { restore cursor position }
            curvis(output, true); { turn on cursor }
            status { update status line }

         end;

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

   putbuf; { decache any buffer }
   if linstr <> nil then begin { buffer not empty }

      if (cury(output) < maxy(output)-1) or 
         (paglin^.next <> linstr) then begin { not at last line }

         { Not last line on screen, or more lines left in buffer. We are a
           "virtual space" editor, so we fake lines below the buffer end
           as being real }
         linpos := linpos+1; { adjust line count }
         { if we aren't already at the bottom of screen, we can just move
           down }
         if cury(output) < maxy(output)-1 then begin

            down(output); { move cursor down }
            statusl { update just line position field }

         end else begin { gotta scroll }

            { clear last line }
            curvis(output, false); { turn off cursor }
            pshcur; { save current position }
            cursor(output, 1, maxy(output));
            while curx(output) < maxx(output) do write(' ');
            write(' ');
            popcur; { restore cursor position }
            scroll(output, 0, +1); { scroll the screen up }
            paglin := paglin^.next; { move page pin down }
            { see if a line exists to fill the new slot }
            lc := 1; { set 1st line }
            lp := paglin;
            { while not end of buffer, and on valid screen portion }
            while (lp <> linstr) and (lc < maxy(output)-1) do begin

               lp := lp^.next; { index next line }
               lc := lc+1 { count }

            end;
            if (lp <> linstr) and (lc < maxy(output)) then begin

               { new line exists }
               pshcur; { save cursor position }
               wrtlin(maxy(output)-1, lp^.str^); { output that line }
               popcur { restore cursor position }

            end;
            curvis(output, true); { turn on cursor }
            status { repaint status line }

         end;

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

   if curx(output) > 1 then begin { not at extreme left }

      left(output); { move cursor left }
      poschr := poschr-1; { track character position }
      statusc { update just character position field }

   end

end;

{*******************************************************************************

Move right one character

If we are not already at the extreme right, moves the cursor one character to
the right.

*******************************************************************************}

procedure movrgt;

begin

   if curx(output) < maxx(output) then begin { not at extreme right }

      right(output); { move cursor right }
      poschr := poschr+1; { track character position }
      statusc { update just character position field }

   end

end;

{*******************************************************************************

Go to top of document

Moves the cursor to the top of the document.

*******************************************************************************}

procedure movhom;

begin

   putbuf; { decache any buffer }
   if linstr <> nil then begin { buffer not empty }

      linpos := 1; { set 1st line }
      poschr := 1; { set 1st character }
      if paglin = linstr then begin

         { we are at top, just move the cursor there }
         home(output); { move home }
         status { update status }

      end else begin { not at top, go there }

         paglin := linstr; { set page to home }
         update { redraw }

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

   putbuf; { decache any buffer }
   if linstr <> nil then begin { buffer not empty }

      lc := lincnt; { set last line }
      lp := linstr^.last;
      { The "offset count" is the number of lines to back off from the true
        end of the file. This is choosen to be 1/2 screenfull }
      oc := (maxy(output)-1) div 2;
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
         update; { redraw }

      end;
      cursor(output, poschr, (maxy(output)-1) div 2+1)
               

   end

end;

{*******************************************************************************

Go to start of line

Moves the cursor to the start of the current line..

*******************************************************************************}

procedure movhoml;

begin

   poschr := 1; { update position }
   cursor(output, 1, cury(output)); { move cursor }
   statusc { update status }

end;

{*******************************************************************************

Go to end of line

Moves the cursor to the end of the current line..

*******************************************************************************}

procedure movendl;

var lp: linptr; { pointer to line }

begin

   if buflin then begin { line is in buffer }

      poschr := len(inpbuf)+1 { set new position }

   end else begin { line is in file }

      lp := fndcur; { find current line }
      if lp <> nil then poschr := len(lp^.str^)+1 { set new position }
      else poschr := 1 { no line, position to start for empty line }

   end;
   { if the line was full, we cannot position past it }
   if poschr > maxx(output) then poschr := maxx(output);
   cursor(output, poschr, cury(output)); { move cursor }
   statusc { update status }

end;

{*******************************************************************************

Go to top of screen

Moves the cursor to the top of the current screen.

*******************************************************************************}

procedure movhoms;

begin

   putbuf; { decache any buffer }
   linpos := linpos-cury(output)+1; { set new position }
   poschr := 1;
   home(output); { position cursor }
   status { update status line }

end;

{*******************************************************************************

Go to bottom of screen

Moves the cursor to the bottom of the current screen.

*******************************************************************************}

procedure movends;

var lp: linptr; { pointer to line }

begin

   putbuf; { decache any buffer }
   linpos := linpos+maxy(output)-cury(output); { set new position }
   lp := fndcur; { find current line }
   if lp <> nil then poschr := len(lp^.str^)+1 { set new position }
   else poschr := 1; { no line, position to start for empty line }
   cursor(output, poschr, maxy(output)-1); { move cursor }
   statusc { update status }

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

   putbuf; { decache any buffer }
   if paglin <> nil then begin { buffer not empty }

      if paglin = linstr then begin { already at top, just home cursor }

         linpos := 1; { set new position }
         cursor(output, poschr, 1); { set to top of screen }
         status { update status line }

      end else begin

         { find number of lines on a page, minus status and slop line }
         cnt := maxy(output)-2;
         { move up to appropriate line }
         while (cnt > 0) and (paglin^.last <> nil) and (paglin <> linstr) do
            begin

            paglin := paglin^.last; { move up one line }
            cnt := cnt-1; { count lines }
            linpos := linpos-1

         end;
         pshcur; { push cursor coordinates }
         update; { redraw }
         popcur { restore cursor coordinates }

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

   putbuf; { decache any buffer }
   if paglin <> nil then begin { buffer not empty }

      if paglin^.next <> linstr then begin { not at end of buffer }

         { find number of lines on a page, minus status and slop line }
         cnt := maxy(output)-2;
         { move down to appropriate line }
         while (cnt > 0) and (paglin^.next <> nil) and (paglin^.next <> linstr) do
            begin

            paglin := paglin^.next; { move down one line }
            cnt := cnt-1; { count lines }
            linpos := linpos+1

         end;
         pshcur; { push cursor coordinates }
         update; { redraw }
         popcur { restore cursor coordinates }

      end

   end

end;

{*******************************************************************************

Scroll up one line

The screen is scrolled up by one line, revealing at new line at bottom.

*******************************************************************************}

procedure scrup;

begin

   putbuf; { decache any buffer }
   if paglin <> linstr then begin { not empty and not at buffer top }

      { not at top of buffer, or not at top of displayed page }
      linpos := linpos-1; { adjust line count }
      curvis(output, false); { turn off cursor }
      scroll(output, 0, -1); { scroll the screen down }
      paglin := paglin^.last; { move page pin up }
      pshcur; { save cursor position }
      home(output); { go to top line }
      if max(paglin^.str^) <> 0 then 
         write(paglin^.str^); { write revealed line over blanks }
      popcur; { restore cursor position }
      curvis(output, true); { turn on cursor }
      status { update status line }

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

   putbuf; { decache any buffer }
   if linstr <> nil then begin { buffer not empty }

      if paglin^.next <> linstr then begin { not at last line }

         linpos := linpos+1; { adjust line count }
         { clear last line }
         curvis(output, false); { turn off cursor }
         pshcur; { save current position }
         cursor(output, 1, maxy(output));
         while curx(output) < maxx(output) do write(' ');
         write(' ');
         popcur; { restore cursor position }
         scroll(output, 0, +1); { scroll the screen up }
         paglin := paglin^.next; { move page pin down }
         { see if a line exists to fill the new slot }
         lc := 1; { set 1st line }
         lp := paglin;
         { while not end of buffer, and on valid screen portion }
         while (lp <> linstr) and (lc < maxy(output)-1) do begin

            lp := lp^.next; { index next line }
            lc := lc+1 { count }

         end;
         if (lp <> linstr) and (lc < maxy(output)) then begin

            { new line exists }
            pshcur; { save cursor position }
            cursor(output, 1, maxy(output)-1); { go to last line }
            if max(lp^.str^) <> 0 then write(lp^.str^); { output that line }
            popcur { restore cursor position }

         end;
         curvis(output, true); { turn on cursor }
         status { repaint status line }

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

   if mpy < maxy(output) then begin

      { not on status line }
      linpos := linpos+(mpy-cury(output)); { set new position }
      poschr := mpx;
      cursor(output, mpx, mpy); { place cursor at new position }
      status { update status line }
      
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

   if insertc then begin { process using insert mode }

      getbuf; { pull line to buffer }
      l := len(inpbuf); { find current length of line }
      if l < maxx(output) then begin { we have room to place }

         { move up buffer to make room }
         for i := l downto poschr do inpbuf[i+1] := inpbuf[i];
         inpbuf[poschr] := c; { place character }
         y := cury(output); { save location y }
         curvis(output, false); { turn off cursor }
         for i := poschr to l+1 do write(inpbuf[i]); { output the line }
         if poschr < maxx(output) then 
            poschr := poschr+1; { advance character position }
         cursor(output, poschr, y); { restore cursor to new position }
         curvis(output, true); { turn one cursor }
         statusc { update character position field }

      end;

   end else { process using overwrite mode }
      if poschr <= maxx(output) then begin { we have room to place }

      getbuf; { pull line to buffer }
      y := cury(output); { save location y }
      inpbuf[poschr] := c; { place character }
      write(c); { place character on screen }
      if poschr < maxx(output) then { not at extreme right }
         poschr := poschr+1; { advance character position }
      cursor(output, poschr, y); { restore cursor to new position }
      statusc { update character position field }
      
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

   if poschr > 1 then begin { not already at extreme left }

      getbuf; { pull line to buffer }
      y := cury(output); { save location y }
      { gap character }
      for i := poschr to maxlin do inpbuf[i-1] := inpbuf[i];
      inpbuf[maxlin] := ' '; { fill last position }
      poschr := poschr-1; { set new character position }
      left(output); { move cursor left }
      l := len(inpbuf); { find length of input buffer }
      curvis(output, false); { turn off cursor }
      for i := poschr to l do write(inpbuf[i]); { replace line }
      if l < maxx(output) then write(' '); { blank out last position }
      cursor(output, poschr, y); { restore position }
      curvis(output, true); { turn on cursor }
      statusc { update character position field }
      
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

   if poschr < maxx(output) then begin { not already at extreme right }

      getbuf; { pull line to buffer }
      y := cury(output); { save location y }
      { gap character }
      for i := poschr to maxlin-1 do inpbuf[i] := inpbuf[i+1];
      inpbuf[maxlin] := ' '; { fill last position }
      l := len(inpbuf); { find length of input buffer }
      curvis(output, false); { turn off cursor }
      for i := poschr to l do write(inpbuf[i]); { replace line }
      if l < maxx(output) then write(' '); { blank out last position }
      cursor(output, poschr, y); { restore position }
      curvis(output, true); { turn on cursor }
      statusc { update character position field }
      
   end

end;

{*******************************************************************************

Tab

In overwrite mode, we simply position to the next tab. In insert mode, we
insert enough spaces to reach the next tab.

*******************************************************************************}

procedure tab;

begin

   if poschr < maxx(output) then { not at extreme right }
      repeat { output spaces }

         entchr(' ') { place a single space }

      until (poschr = maxx(output)) or ((poschr-1) mod 8 = 0)

end;

begin

   linstr := nil; { clear lines buffer }
   paglin := nil; { clear top of page line }
   curstk := nil; { clear coordinate stack }
   lincnt := 0; { clear total lines }
   chrcnt := 0; { clear total characters }
   linpos := 1; { set 1st line }
   poschr := 1; { set 1st character }
   mpx := 0; { set mouse is nowhere }
   mpy := 0;
   buflin := false; { set no line in buffer }
   insertc := true; { set insert mode on }
   { check screen size is less than our minimum }
   if (maxx(output) < 70) or (maxy(output) < 2) then begin

      { we take a special short exit because the display is not workable.
        This only works for in-line display, separate windows just exit
        because it happens too fast }
      writeln('*** Window too small');
      goto stopprog

   end;
   select(output, 2, 2); { flip to private screen }
   auto(output, false); { turn off scrolling }
   update; { present blank screen }

   getcmd(cmdlin); { get command line }
   parcmd; { parse command line }
   readfile(curfil); { read the file in }

   inputloop: { return to input level }

   { The screen is initalized with the specified file. Now we enter the event
     loop }
   repeat { event loop }

      event(input, er); { get the next event }
      if er.etype in [etchar, etup, etdown, etleft, etright, etleftw, etrightw,
                      ethome, ethomes, ethomel, etend, etends, etendl, etscrl,
                      etscrr, etscru, etscrd, etpagd, etpagu, ettab, etenter,   
                      etinsert, etinsertl, etinsertt, etdel, etdell, etdelcf,   
                      etdelcb, etcopy, etcopyl, etcan, etstop, etcont, etprint,
                      etprintb, etprints, etfun, etmouba, etmoubd, etmoumov,
                      etterm] then case er.etype of { event }

         etchar:    entchr(er.char); { ASCII character returned }
         etup:      movup; { cursor up one line }
         etdown:    movdwn; { down one line }
         etleft:    movlft; { left one character }
         etright:   movrgt; { right one character }
         etleftw:   ; { left one word }
         etrightw:  ; { right one word }
         ethome:    movhom; { home of document }
         ethomes:   movhoms; { home of screen }
         ethomel:   movhoml; { home of line }
         etend:     movend; { end of document }
         etends:    movends; { end of screen }
         etendl:    movendl; { end of line }
         etscrl:    ; { scroll left one character }
         etscrr:    ; { scroll right one character }
         etscru:    scrup; { scroll up one line }
         etscrd:    scrdwn; { scroll down one line }
         etpagu:    pagup; { page up }
         etpagd:    pagdwn; { page down }
         ettab:     tab; { tab }
         etenter:   ; { enter line }
         etinsert:  ; { insert block }
         etinsertl: ; { insert line }
         etinsertt: togins; { insert toggle }
         etdel:     ; { delete block }
         etdell:    ; { delete line }
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
         etfun:     ; { functions }
         etmouba:   mouass; { mouse button 1 assertion }
         etmoumov:  moumov; { mouse move }
         etterm:    ; { terminate program }

      end

   until er.etype = etterm; { until terminal event }
   auto(output, true); { turn on scrolling }
   select(output, 1, 1); { return to normal screen }

   stopprog: { exit program }

end.
