{*******************************************************************************
*                                                                              *
*                            IP UNINSTALLER PROGRAM                            *
*                                                                              *
*                             2006/02 S. A. Moore                              *
*                                                                              *
* Uninstalls IP Pascal by finding the "uninstall" key, then using that to      *
* erase all files in the installer directory. The uninstall keys themselves    *
* are then removed.                                                            *
*                                                                              *
*******************************************************************************}

program uninstall(input, output);

uses windows, 
     cpuid,
     gralib,
     strlib,
     extlib,
     dirlib;

label 99; { abort program }

const filmax     = 500;       { number of characters in a filename }
      bufmax     = 4096;      { size of compression sliding buffer }
      runmax     = 15;        { maximum size of run or match }
      { switches }
      diag    = false; { output diagnostics }
      clientx = 640; { size of client area }
      clienty = 375;
      lmargin = 120; { left margin (includes logo) }
      rmargin = 640-20; { right margin }
      fntsiz  = 20;  { size of font }
      buthgh  = 30;  { bottom button heights }
      butbmg  = 20;  { bottom button margin to edge }
      butbak  = 350; { placement x of back button }
      butnxt  = 450; { placement x of next button }
      butuns  = 450; { placement x of uninstall button }
      butcan  = 550; { placement x of cancel button }
      butext  = 550; { placement x of exit button }
      butwdt  = 70;  { width of buttons }
      etylin  = 270; { x of entry line or checkbox }
      { widget ids }
      bidbak = 1; { back }
      bidnxt = 2; { next }
      bidcan = 3; { cancel }
      bidext = 4; { exit }
      biduns = 5; { uninstall }
      widprg = 6; { progress bar }
      { pictures }
      piclog = 1; { logo }
      picstp = 2; { stop sign }

type  filinx = 1..filmax; { index for filename }
      filnam = packed array [filinx] of char; { a filename }
      { active button tracking }
      actbut = (acbbak,  { back }
                acbnxt,  { next }
                acbcan,  { cancel }
                acbext,  { exit }
                acbuns); { uninstall }
      actbuts = set of actbut;
      errcod = (ekey,    { registry key error }
                esys);   { system error }

var   errnam:          filnam;  { error filename }
      err:             boolean; { error return }
      tmpstr, tmpstr1: filnam;  { holding string }
      p, n, e:         filnam;  { filename components }
      runy:            integer; { runnning text placement }
      bakprs:          boolean; { back button pressed }
      buttrk:          actbuts; { onscreen button active tracking }
      diagout:         text;    { diagnostic output window }
      sx, sy:          integer; { size of screen }
      ipppth:          filnam;  { IP Pascal program path }
      schpth:          filnam;  { program search path }
      dirlst:          dirptr;  { release directory list }
      prgact:          boolean; { progress bar is active }
      stopload:        boolean; { stop sign bitmap is loaded }

{******************************************************************************

Clear message area

Clears the message area, the area at the top right used for explanitory text,
to the background color.

******************************************************************************}

procedure clrmsg;

begin

   fcolor(backcolor); { set erase color }
   frect(lmargin, 1, clientx, clienty-butbmg-buthgh-17-2); { clear it }
   fcolor(black); { restore color }

end;

{******************************************************************************

Display buttons

Displays a series of buttons in the button area. A set of buttons to be made
active is accepted, then that is compared with the button active set, and any
buttons not active are made active, and vice versa.

The button tracking keeps the buttons from being removed, and then immediately
replaced, which would potentially flash them.

******************************************************************************}

procedure butdis(view buttons: actbuts);

begin

   { process removals }
   if not (acbbak in buttons) and (acbbak in buttrk) then killwidget(bidbak);
   if not (acbnxt in buttons) and (acbnxt in buttrk) then killwidget(bidnxt);
   if not (acbcan in buttons) and (acbcan in buttrk) then killwidget(bidcan);
   if not (acbext in buttons) and (acbext in buttrk) then killwidget(bidext);
   if not (acbuns in buttons) and (acbuns in buttrk) then killwidget(biduns);

   if (acbbak in buttons) and not (acbbak in buttrk) then
      button(butbak, clienty-butbmg-buthgh, butbak+butwdt, clienty-butbmg, 
             'Back', bidbak);
   if (acbnxt in buttons) and not (acbnxt in buttrk) then
      button(butnxt, clienty-butbmg-buthgh, butnxt+butwdt, clienty-butbmg, 
             'Next', bidnxt);
   if (acbcan in buttons) and not (acbcan in buttrk) then
      button(butcan, clienty-butbmg-buthgh, butcan+butwdt, clienty-butbmg, 
             'Cancel', bidcan);
   if (acbext in buttons) and not (acbext in buttrk) then
      button(butext, clienty-butbmg-buthgh, butext+butwdt, clienty-butbmg, 
             'Exit', bidext);
   if (acbuns in buttons) and not (acbuns in buttrk) then
      button(butuns, clienty-butbmg-buthgh, butuns+butwdt, clienty-butbmg, 
             'Uninstall', biduns);

   buttrk := buttons { set new active mask }

end;

{******************************************************************************

Wait button

Waits for a back, next or cancel button press. If the cancel button is pressed,
the program ends. If the next button is pressed, a normal return is done. If
the back button is pressed, we return with the "back" flag set.

******************************************************************************}

procedure waitnext(var back: boolean);

var er: evtrec;

begin

   back := false; { set back not pressed }
   repeat

      event(er); { get the next event }
      if er.etype = etterm then goto 99 { terminate program }
      else if er.etype = etbutton then begin { its a button press }

         if er.butid = bidbak then back := true { signal back button }
         else if (er.butid = bidcan) or (er.butid = bidext) then 
            goto 99 { terminate }

      end

   until er.etype in [etbutton]

end;

{*******************************************************************************

Write text to location

Writes text to the given location in x, y.

*******************************************************************************}

procedure writerun(view s: string);

begin

   cursorg(lmargin, runy); { position }
   write(s:0); { write string }
   runy := runy+fntsiz { next position }

end;

overload procedure writerun;

begin

   writerun('')

end;

{*******************************************************************************

Process error

Prints out the given error and aborts the program.

*******************************************************************************}

procedure prcerr(e: errcod);

begin

   if prgact then killwidget(widprg); { remove progress bar }
   clrmsg; { clear message area }
   butdis([acbcan]); { activate cancel button }
   if stopload then begin

      picture(picstp, lmargin, 10, lmargin+64, 10+64); { draw stop sign }
      runy := 10+64+10 { start after that }

   end else runy := 10; { start at top }
   case e of { error }

      ekey: begin

         writerun('Cannot access registry data.');
         writerun;
         writerun('This program was unable to access the registry data for');
         writerun('IP Pascal. This could mean that the program has already');
         writerun('been removed, or that the registry is corrupted. If');
         writerun('IP Pascal still exists, and you want it removed, you can');
         writerun('remove it manually. See the file "readme.txt" on the');
         writerun('original IP Pascal install disk. For further problems,');
         writerun('please contact Moore/CAD customer support at');
         writerun('"support@moorecad.com".')

      end;

      esys: begin

         writerun('System error.');
         writerun;
         writerun('The installer has failed an internal consistency check.');
         writerun('This could mean that you have a corrupted copy of the');
         writerun('installer program. If the problem persists, please contact');
         writerun('Moore/CAD customer support at "support@moorecad.com".')

      end

   end;
   waitnext(bakprs); { wait for button }

   goto 99 { terminate }

end;

{*******************************************************************************

Get key value

Gets the given value under a key. The root key value is specified, along with
the subkey. The value is returned in the string.

*******************************************************************************}

procedure getkeyvalue(rk: integer; view sk, vn: string; var vs: string);

var r, k, v, l, t: integer;

begin

   v := $8000000;
   v := v*16;
   r := sc_regopenkey(rk or v, sk, k);
   if r <> 0 then prcerr(ekey); { error }
   l := max(vs); { set length of string }
   r := sc_regqueryvalueex(k, vn, t, vs, l);
   if r <> 0 then prcerr(ekey); { error }
   r := sc_regclosekey(k);
   if r <> 0 then prcerr(ekey) { error }

end;

{*******************************************************************************

Set key value

Sets the given value under a key. The root key value is specified, along with
the subkey, then the string value of the key.

*******************************************************************************}

procedure setkeyvalue(rk: integer; view sk, vn, vs: string);

var r, k, v: integer;

begin

   err := false; { set no error }
   v := $8000000;
   v := v*16;
   r := sc_regopenkey(rk or v, sk, k);
   if r <> 0 then prcerr(ekey); { error }
   r := sc_regsetvalueex(k, vn, 2, vs, len(vs)+1);
   if r <> 0 then prcerr(ekey); { error }
   r := sc_regclosekey(k);
   if r <> 0 then prcerr(ekey) { error }

end;

{*******************************************************************************

Get program path

Gets the IP Pascal program path, by reading the uninstall key, value
"uninstalllocation". The path is placed in prgpth.

*******************************************************************************}

procedure getpath;

const

   { root key, and uninstall key }
   root = sc_hkey_local_machine;
   key = 'software\\microsoft\\windows\\currentversion\\uninstall\\IP Pascal';

begin

   getkeyvalue(root, key, 'installlocation', ipppth) { get program path }

end;

{*******************************************************************************

Get program search path

Gets the .exe search path, by reading it from the registry.

*******************************************************************************}

procedure getschpath;

const

   { root key, and uninstall key }
   root = sc_hkey_local_machine;
   key = 'system\\controlset001\\control\\session manager\\environment';

begin

   getkeyvalue(root, key, 'path', schpth) { get program search path }

end;

{*******************************************************************************

Set program search path

Sets the .exe search path, by writing it to the registry.

*******************************************************************************}

procedure setschpath;

const

   { root key, and uninstall key }
   root = sc_hkey_local_machine;
   key = 'system\\controlset001\\control\\session manager\\environment';

begin

   setkeyvalue(root, key, 'path', schpth) { get program search path }

end;

{*******************************************************************************

Remove uninstall registry key set

Removes the complete key for the uninstall registry, including all values.

*******************************************************************************}

procedure remunskey;

const 

   { root key, and uninstall key }
   root = sc_hkey_local_machine;
   key = 'software\\microsoft\\windows\\currentversion\\uninstall\\IP Pascal';

var r, v: integer; { return value }

begin

   v := $8000000;
   v := v*16;
   r := sc_regdeletekey(root or v, key);
   if r <> 0 then prcerr(ekey)

end;

{*******************************************************************************

Delete files

Given a tree of files to process, deletes each file and directory under that
true.

*******************************************************************************}

procedure delfil(dirlst: dirptr);

var fp:      filptr;  { pointer for file entries }
    p, n, e: filnam;  { filename components }
    name:    filnam;  { filename buffer }
    dp:      dirptr;  { directory list pointer }
    root:    dirptr;  { temp root for directories }
    filtot:  integer; { file/directory total }
    filcnt:  integer; { file delete count }

begin

   { find file/directory count }
   dp := dirlst; { index top of list }
   filtot := 0; { clear file total }
   while dp <> nil do begin { traverse the list }

      filtot := filtot+dp^.cnt; { add in this directory count }
      dp := dp^.next { next directory }

   end;
   
   { remove files }
   filcnt := 0; { clear delete counter }
   dp := dirlst; { index top of list }
   while dp <> nil do begin

      if diag then writeln(diagout, 'Directory: ', dp^.name^:0);
      fp := dp^.files; { index top of files list }
      while fp <> nil do begin

         if not (atdir in fp^.attr) then begin

            brknam(fp^.name^, p, n, e); { break filename into components }
            maknam(name, dp^.name^, n, e); { construct full name }
            if diag then writeln(diagout, 'Will delete: ', name:0);
            if not exists(name) then prcerr(esys); { should exist }
            delete(name); { delete the file }
            filcnt := filcnt+1; { count this delete }
            progbarpos(widprg, trunc(filcnt*(maxint * 1.0)/filtot))

         end;
         fp := fp^.next

      end;
      dp := dp^.next { next directory }

   end;

   { Reverse directory list. Since the directories are listed root first,
     we reverse it to find depth first.
   root := nil; { clear root }
   while dirlst <> nil do begin { transfer entries }
    
      dp := dirlst; { index top entry }
      dirlst := dirlst^.next; { gap out }
      dp^.next := root; { push to root }
      root := dp

   end;
   dirlst := root; { place reordered list }

   { remove directories }
   dp := dirlst; { index top of list }
   while dp <> nil do begin { process files list }

      fp := dp^.files; { index top of files list }
      while fp <> nil do begin { erase files }

         if (atdir in fp^.attr) and not (atloop in fp^.attr) then begin

            brknam(fp^.name^, p, n, e); { break down filename }
            maknam(name, dp^.name^, n, e); { create with path }
            if diag then 
               writeln(diagout, 'Will delete directory: ', name:0);
            rempth(name); { remove it }
            filcnt := filcnt+1; { count this delete }
            progbarpos(widprg, trunc(filcnt*(maxint * 1.0)/filtot))

         end;
         fp := fp^.next { next entry }

      end;
      dp := dp^.next { next entry }

   end

end;

{*******************************************************************************

Check directory exists

Checks if the given path name exists, and corresponds to a directory. Returns
true if so.

*******************************************************************************}

function existsdir(view s: string): boolean;

var fp: filptr;  { file entry pointer }
    e:  boolean; { exists flag }

begin

   e := false; { default to does not exist }
   list(s, fp); { get list of files }
   if fp <> nil then begin { found one }

      if atdir in fp^.attr then e := true; { found a directory }
      dispose(fp) { release entry }

   end;

   existsdir := e { return result }

end;

{*******************************************************************************

Remove path section

Removes any sections from the path that match the program path.

*******************************************************************************}

procedure rempath;

var m:       boolean; { match flag }
    ts, ts1: filnam; { holding strings }
    newpath: filnam; { temp to build new path in }

begin

   clears(newpath); { clear path to build }
   copy(ts, schpth); { copy path to temp }
   while index(ts, ';') > 0 do begin { while path is divisible }

      extract(ts1, ts, 1, index(ts, ';')-1); { get left side }
      if indexp(ts1, ipppth) <> 1 then begin { no match }

         { add ';' to non-null path }
         if len(newpath) > 0 then cat(newpath, ';');
         cat(newpath, ts1) { add new section }

      end;
      extract(ts1, ts, index(ts, ';')+1, len(ts)); { get right side }
      copy(ts, ts1) { place as original }

   end;
   if len(ts) > 0 then begin { try last, whole path match }

      trim(ts1, ts); { trim off spaces }
      if indexp(ts1, ipppth) <> 1 then begin { no match }

         { add ';' to non-null path }
         if len(newpath) > 0 then cat(newpath, ';');
         cat(newpath, ts1) { add new section }

      end

   end;
   copy(schpth, newpath) { place new path }

end;

{*******************************************************************************

Main program

The program is divided into a series of "pages", each of which contains
information or action for the user. The left side of the window contains the
logo area, which contains our advertising logo. The right top area is reserved
for messages to the user, and we have a system that writes text, with next
line control, into that area. Below that is a single line reserved for special
messages, such as input dialogs or checkboxes. Finally, the bottom right of the
screen, divided by a line, a series of pushbuttons exist, such as BACK, NEXT
and CANCEL, that allow the user to control the behavior and navigation of the
program.

*******************************************************************************}

begin

   { If diagnostics are on, open a separate window for them. }
   if diag then begin

      openwin(input, diagout, 2); { open the window }
      writeln(diagout, 'Uninstall program diagnostics window is active');
      writeln(diagout)

   end;
   scnsizg(sx, sy); { find size of screen }
   setposg(sx div 2-clientx div 2, sy div 2-clienty div 2); { position to center }
   bcolor(backcolor); { set that }
   page; { clear to that }
   title('IP Pascal uninstaller');
   curvis(output, false); { remove drawing cursor }
   auto(output, false); { turn off scrolling }
   sizable(false); { turn off sizing }
   font(output, font_sign); { sign font }
   bold(true); { use bold font }
   fontsiz(fntsiz); { turn up size }
   binvis; { foreground overwrite }
   stopload := false; { set stop bitmap not loaded }
   autohold(false); { signal we will perform our own exits }
   clears(ipppth); { clear program path }
   { load our graphics. This procedure is complicated because uninstall can be
     executed from various places, and Windows does not provide a reliable path
     to it. }
   copy(tmpstr, 'logo.bmp'); { set logo name }
   { if not with program, get it from uninstall directory }
   if not exists(tmpstr) then begin

      getpath; { get IP Pascal installation path }
      maknam(tmpstr, ipppth, 'logo', '')

   end;
   loadpict(piclog, tmpstr); { get the Moore/CAD logo }
   copy(tmpstr, 'stop.bmp'); { set stop name }
   { if not with program, get it from uninstall directory }
   if not exists(tmpstr) then begin

      getpath; { get IP Pascal installation path }
      maknam(tmpstr, ipppth, 'stop', '')

   end;
   loadpict(picstp, tmpstr); { get the stop sign }
   picture(piclog, 1, 1, 100, clienty); { draw logo left }
   { draw bottom button dividing line }
   linewidth(3);
   fcolor(black);
   line(lmargin, clienty-butbmg-buthgh-17, rmargin, clienty-butbmg-buthgh-17);
   linewidth(1);
   buttrk := []; { set no buttons active }
   prgact := false; { set progress bar not active }
   getpath; { get IP Pascal installation path }

   { ************************* Present initial splash page ******************* }
   
   if diag then writeln(diagout, 'Presenting splash page');
   butdis([acbuns, acbcan]); { activate uninstall and cancel buttons }
   clrmsg; { clear message area }
   fontsiz(40); { set large font }
   cursorg(lmargin, 10); { position to banner }
   write('IP Pascal Uninstallation'); { present banner }
   fontsiz(fntsiz); { restore size }
   runy := 70; { position running text below banner }
   writerun('This program removes IP Pascal from your system. Before');
   writerun('running this program, MAKE SURE YOU HAVE NONE OF YOUR OWN FILES');
   writerun('IN THE IP PASCAL DIRECTORY. This program deletes all files in that');
   writerun('directory tree.');
   writerun;
   writerun('If you wish to completely uninstall IP Pascal from your system,');
   writerun('press the UNINSTALL button below.');
   waitnext(bakprs); { wait for button }

   { ********************* Present uninstall progress page ******************* }

   if diag then writeln(diagout, 'Presenting uninstall progress page');

   butdis([acbnxt]); { turn off buttons }
   clrmsg; { clear message area }
   runy := 10; { set the runner to the top }
   writerun('Removing files');
   cursorg(lmargin, etylin-20-5);
   write('%0');
   cursorg(clientx-70, etylin-20-5);
   write('%100');
   progbar(lmargin, etylin, clientx-20, etylin+20, widprg);
   prgact := true; { set progress bar is active }
   if existsdir(ipppth) then begin { there is a directory there }

      copy(tmpstr, ipppth); { copy program path }
      cat(tmpstr, '\\*'); { create file specification }

      { create a list of files to delete }
      treelist(tmpstr, maxint, 0, false, [], [], [], [], [], [], [], [], 
               dirlst);
      delfil(dirlst); { process delete on that }
      rempth(ipppth) { remove the program path }

   end;
   writerun('Removing IP Pascal from program search path');
   getschpath; { get program search path }
   rempath; { remove any IP Pascal path sections }
   setschpath; { set new search path }
   writerun('Removing uninstall registry key');
   remunskey; { remove uninstall key }
   progbarpos(widprg, maxint);
   butdis([acbext]); { activate exit button }
   writerun;
   writerun('IP Pascal removal complete.');
   waitnext(bakprs); { wait for button }
   killwidget(widprg); { remove progress bar }
   prgact := false; { set progress bar is inactive }

   99: { abort program }

end.
