{******************************************************************************
*                                                                             *
*                           GRAPHICAL MODE LIBRARY                            *
*                                                                             *
*                       Copyright (C) 2006 Scott A. Moore                     *
*                                                                             *
*                              4/96 S. A. Moore                               *
*                                                                             *
******************************************************************************}

module gralib;

uses syslib; { system library }

const maxtim = 10; { maximum number of timers available }
      maxbuf = 10; { maximum number of buffers available }
      font_term = 1; { terminal font }
      font_book = 2; { book font }
      font_sign = 3; { sign font }
      font_tech = 4; { technical font (vector font) }
      iowin    = 1;  { logical window number of input/output pair }
      { standardized menu entries }
      smnew       = 1; { new file }
      smopen      = 2; { open file }
      smclose     = 3; { close file }
      smsave      = 4; { save file }
      smsaveas    = 5; { save file as name }
      smpageset   = 6; { page setup }
      smprint     = 7; { print }
      smexit      = 8; { exit program }
      smundo      = 9; { undo edit }
      smcut       = 10; { cut selection }
      smpaste     = 11; { paste selection }
      smdelete    = 12; { delete selection }
      smfind      = 13; { find text }
      smfindnext  = 14; { find next }
      smreplace   = 15; { replace text }
      smgoto      = 16; { goto line }
      smselectall = 17; { select all text }
      smnewwindow = 18; { new window }
      smtilehoriz = 19; { tile child windows horizontally }
      smtilevert  = 20; { tile child windows vertically }
      smcascade   = 21; { cascade windows }
      smcloseall  = 22; { close all windows }
      smhelptopic = 23; { help topics }
      smabout     = 24; { about this program }
      smmax       = 24; { maximum defined standard menu entries }

type { Colors displayable in text mode. Background is the color that will match
       widgets placed onto it. }
     color = (black, white, red, green, blue, cyan, yellow, magenta, backcolor);
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
     evtcod = (etchar,     { ANSI character returned }
               etup,       { cursor up one line }
               etdown,     { down one line }
               etleft,     { left one character }
               etright,    { right one character }
               etleftw,    { left one word }
               etrightw,   { right one word }
               ethome,     { home of document }
               ethomes,    { home of screen }
               ethomel,    { home of line }
               etend,      { end of document }
               etends,     { end of screen }
               etendl,     { end of line }
               etscrl,     { scroll left one character }
               etscrr,     { scroll right one character }
               etscru,     { scroll up one line }
               etscrd,     { scroll down one line }
               etpagd,     { page down }
               etpagu,     { page up }
               ettab,      { tab }
               etenter,    { enter line }
               etinsert,   { insert block }
               etinsertl,  { insert line }
               etinsertt,  { insert toggle }
               etdel,      { delete block }
               etdell,     { delete line }
               etdelcf,    { delete character forward }
               etdelcb,    { delete character backward }
               etcopy,     { copy block }
               etcopyl,    { copy line }
               etcan,      { cancel current operation }
               etstop,     { stop current operation }
               etcont,     { continue current operation }
               etprint,    { print document }
               etprintb,   { print block }
               etprints,   { print screen }
               etfun,      { function key }
               etmenu,     { display menu }
               etmouba,    { mouse button assertion }
               etmoubd,    { mouse button deassertion }
               etmoumov,   { mouse move }
               ettim,      { timer matures }
               etjoyba,    { joystick button assertion }
               etjoybd,    { joystick button deassertion }
               etjoymov,   { joystick move }
               etterm,     { terminate program }
               etmoumovg,  { mouse move graphical }
               etframe,    { frame sync }
               etresize,   { window was resized }
               etredraw,   { window redraw }
               etmin,      { window minimized }
               etmax,      { window maximized }
               etnorm,     { window normalized }
               etmenus,    { menu item selected }
               etbutton,   { button assert }
               etchkbox,   { checkbox click }
               etradbut,   { radio button click }
               etsclull,   { scroll up/left line }
               etscldrl,   { scroll down/right line }
               etsclulp,   { scroll up/left page }
               etscldrp,   { scroll down/right page }
               etsclpos,   { scroll bar position }
               etedtbox,   { edit box signals done }
               etnumbox,   { number select box signals done }
               etlstbox,   { list box selection }
               etdrpbox,   { drop box selection }
               etdrebox,   { drop edit box selection }
               etsldpos,   { slider position }
               ettabbar,   { tab bar select }
               { the following is for internal use only }
               et_fndtrm,  { find dialog has messaged }
               et_wigstr,  { widget started }
               et_winstr,  { window started }
               et_wincls,  { window closed }
               et_im);     { intratask message }
     { event record }
     evtrec = record

        winid: ss_filhdl; { identifier of window for event }
        case etype: evtcod of { event type }

           { ANSI character returned }
           etchar:   (char:                char);
           { timer handle that matured }
           ettim:     (timnum:              timhan);
           etmoumov:  (mmoun:               mouhan;   { mouse number }
                       moupx, moupy:        integer); { mouse movement }
           etmouba:   (amoun:               mouhan;   { mouse handle }
                       amoubn:              moubut);  { button number }
           etmoubd:   (dmoun:               mouhan;   { mouse handle }
                       dmoubn:              moubut);  { button number }
           etjoyba:   (ajoyn:               joyhan;   { joystick number }
                       ajoybn:              joybut);  { button number }
           etjoybd:   (djoyn:               joyhan;   { joystick number }
                       djoybn:              joybut);  { button number }
           etjoymov:  (mjoyn:               joyhan;   { joystick number }
                       joypx, joypy, joypz: integer); { joystick coordinates }
           etfun:     (fkey:                funky);   { function key }
           etmoumovg: (mmoung:              mouhan;   { mouse number }
                       moupxg, moupyg:      integer); { mouse movement }
           etredraw:  (rsx, rsy, rex, rey:  integer); { redraw screen }
           etmenus:   (menuid:              integer); { menu item selected }
           etbutton:  (butid:               integer); { button id }
           etchkbox:  (ckbxid:              integer); { checkbox }
           etradbut:  (radbid:              integer); { radio button }
           etsclull:  (sclulid:             integer); { scroll up/left line }
           etscldrl:  (scldlid:             integer); { scroll down/right line }
           etsclulp:  (sclupid:             integer); { scroll up/left page }
           etscldrp:  (scldpid:             integer); { scroll down/right page }
           etsclpos:  (sclpid:              integer;  { scroll bar }
                       sclpos:              integer); { scroll bar position }
           etedtbox:  (edtbid:              integer); { edit box complete }
           etnumbox:  (numbid:              integer;  { num sel box select }
                       numbsl:              integer); { num select value }
           etlstbox:  (lstbid:              integer;  { list box select }
                       lstbsl:              integer); { list box select number }
           etdrpbox:  (drpbid:              integer;  { drop box select }
                       drpbsl:              integer); { drop box select }
           etdrebox:  (drebid:              integer); { drop edit box select }
           etsldpos:  (sldpid:              integer;  { slider position }
                       sldpos:              integer); { slider position }
           ettabbar:  (tabid:               integer;  { tab bar }
                       tabsel:              integer); { tab select }
           et_im:     (imptr:               integer); { intertask message ptr }
           etup, etdown, etleft, etright, etleftw, etrightw, ethome, ethomes,
           ethomel, etend, etends, etendl, etscrl, etscrr, etscru, etscrd,    
           etpagd, etpagu, ettab, etenter, etinsert, etinsertl, etinsertt, 
           etdel, etdell, etdelcf, etdelcb, etcopy, etcopyl, etcan, etstop,    
           etcont, etprint, etprintb, etprints, etmenu, etterm, etframe, 
           etresize, etmin, etmax, etnorm, et_fndtrm, et_wigstr, 
           et_winstr, et_wincls: (); { normal events }

        { end }

     end;
     { menu }
     menuptr = ^menurec;
     menurec = record

        next:   menuptr; { next menu item in list }
        branch: menuptr; { menu branch }
        onoff:  boolean; { on/off highlight }
        oneof:  boolean; { "one of" highlight }
        bar:    boolean; { place bar under }
        id:     integer; { id of menu item }
        face:   pstring  { text to place on button }

     end;
     { standard menu selector }
     stdmenusel = set of smnew..smmax;
     { windows mode sets }
     winmod = (wmframe,   { frame on/off }
               wmsize,    { size bars on/off }
               wmsysbar); { system bar on/off }
     winmodset = set of winmod;
     { string set for list box }
     strptr = ^strrec;
     strrec = record

        next: strptr; { next entry in list }
        str:  pstring { string }

     end;
     { orientation for tab bars }
     tabori = (totop, toright, tobottom, toleft); 
     { settable items in find query }
     qfnopt = (qfncase, qfnup, qfnre);
     qfnopts = set of qfnopt;
     { settable items in replace query }
     qfropt = (qfrcase, qfrup, qfrre, qfrfind, qfrallfil, qfralllin);
     qfropts = set of qfropt;
     { effects in font query }
     qfteffect = (qfteblink, qftereverse, qfteunderline, qftesuperscript,
                  qftesubscript, qfteitalic, qftebold, qftestrikeout,
                  qftestandout, qftecondensed, qfteextended, qftexlight,
                  qftelight, qftexbold, qftehollow, qfteraised);
     qfteffects = set of qfteffect;

{ functions at this level }

{ text }

procedure cursor(var f: text; x, y: integer); external;
overload procedure cursor(x, y: integer); external;
function maxx(var f: text): integer; external;
overload function maxx: integer; external;
function maxy(var f: text): integer; external;
overload function maxy: integer; external;
procedure home(var f: text); external;
overload procedure home; external;
procedure del(var f: text); external;
overload procedure del; external;
procedure up(var f: text); external;
overload procedure up; external;
procedure down(var f: text); external;
overload procedure down; external;
procedure left(var f: text); external;
overload procedure left; external;
procedure right(var f: text); external;
overload procedure right; external;
procedure blink(var f: text; e: boolean); external;
overload procedure blink(e: boolean); external;
procedure reverse(var f: text; e: boolean); external;
overload procedure reverse(e: boolean); external;
procedure underline(var f: text; e: boolean); external;
overload procedure underline(e: boolean); external;
procedure superscript(var f: text; e: boolean); external;
overload procedure superscript(e: boolean); external;
procedure subscript(var f: text; e: boolean); external;
overload procedure subscript(e: boolean); external;
procedure italic(var f: text; e: boolean); external;
overload procedure italic(e: boolean); external;
procedure bold(var f: text; e: boolean); external;
overload procedure bold(e: boolean); external;
procedure strikeout(var f: text; e: boolean); external;
overload procedure strikeout(e: boolean); external;
procedure standout(var f: text; e: boolean); external;
overload procedure standout(e: boolean); external;
procedure fcolor(var f: text; c: color); external;
overload procedure fcolor(c: color); external;
procedure bcolor(var f: text; c: color); external;
overload procedure bcolor(c: color); external;
procedure auto(var f: text; e: boolean); external;
overload procedure auto(e: boolean); external;
procedure curvis(var f: text; e: boolean); external;
overload procedure curvis(e: boolean); external;
procedure scroll(var f: text; x, y: integer); external;
overload procedure scroll(x, y: integer); external;
function curx(var f: text): integer; external;
overload function curx: integer; external;
function cury(var f: text): integer; external;
overload function cury: integer; external;
function curbnd(var f: text): boolean; external;
overload function curbnd: boolean; external;
procedure select(var f: text; u, d: integer); external;
overload procedure select(u, d: integer); external;
overload procedure select(var f: text; d: integer); external;
overload procedure select(d: integer); external;
procedure event(var f: text; var er: evtrec); external;
overload procedure event(var er: evtrec); external;
procedure timer(var f: text; i: timhan; t: integer; r: boolean); external;
overload procedure timer(i: timhan; t: integer; r: boolean); external;
procedure killtimer(var f: text; i: timhan); external;
overload procedure killtimer(i: timhan); external;
function mouse(var f: text): mounum; external;
overload function mouse: mounum; external;
function mousebutton(var f: text; m: mouhan): moubut; external;
overload function mousebutton(m: mouhan): moubut; external;
function joystick(var f: text): joynum; external;
overload function joystick: joynum; external;
function joybutton(var f: text; j: joyhan): joybtn; external;
overload function joybutton(j: joyhan): joybtn; external;
function joyaxis(var f: text; j: joyhan): joyaxn; external;
overload function joyaxis(j: joyhan): joyaxn; external;
procedure settab(var f: text; t: integer); external;
overload procedure settab(t: integer); external;
procedure restab(var f: text; t: integer); external;
overload procedure restab(t: integer); external;
procedure clrtab(var f: text); external;
overload procedure clrtab; external;
function funkey(var f: text): funky; external;
overload function funkey: funky; external;
procedure frametimer(var f: text; e: boolean); external;
overload procedure frametimer(e: boolean); external;
procedure autohold(e: boolean); external;
{ experimental for text }
procedure wrtstr(var f: text; view s: string); external;
overload procedure wrtstr(view s: string); external;

{ graphical }

function maxxg(var f: text): integer; external;
overload function maxxg: integer; external;
function maxyg(var f: text): integer; external;
overload function maxyg: integer; external;
function curxg(var f: text): integer; external;
overload function curxg: integer; external;
function curyg(var f: text): integer; external;
overload function curyg: integer; external;
procedure line(var f: text; x1, y1, x2, y2: integer); external;
overload procedure line(x1, y1, x2, y2: integer); external;
overload procedure line(var f: text; x2, y2: integer); external;
overload procedure line(x2, y2: integer); external;
procedure linewidth(var f: text; w: integer); external;
overload procedure linewidth(w: integer); external;
procedure rect(var f: text; x1, y1, x2, y2: integer); external;
overload procedure rect(x1, y1, x2, y2: integer); external;
procedure frect(var f: text; x1, y1, x2, y2: integer); external;
overload procedure frect(x1, y1, x2, y2: integer); external;
procedure rrect(var f: text; x1, y1, x2, y2, xs, ys: integer); external;
overload procedure rrect(x1, y1, x2, y2, xs, ys: integer); external;
procedure frrect(var f: text; x1, y1, x2, y2, xs, ys: integer); external;
overload procedure frrect(x1, y1, x2, y2, xs, ys: integer); external;
procedure ellipse(var f: text; x1, y1, x2, y2: integer); external;
overload procedure ellipse(x1, y1, x2, y2: integer); external;
procedure fellipse(var f: text; x1, y1, x2, y2: integer); external;
overload procedure fellipse(x1, y1, x2, y2: integer); external;
procedure arc(var f: text; x1, y1, x2, y2, sa, ea: integer); external;
overload procedure arc(x1, y1, x2, y2, sa, ea: integer); external;
procedure farc(var f: text; x1, y1, x2, y2, sa, ea: integer); external;
overload procedure farc(x1, y1, x2, y2, sa, ea: integer); external;
procedure fchord(var f: text; x1, y1, x2, y2, sa, ea: integer); external;
overload procedure fchord(x1, y1, x2, y2, sa, ea: integer); external;
procedure ftriangle(var f: text; x1, y1, x2, y2, x3, y3: integer); external;
overload procedure ftriangle(x1, y1, x2, y2, x3, y3: integer); external;
overload procedure ftriangle(var f: text; x2, y2, x3, y3: integer); external;
overload procedure ftriangle(x2, y2, x3, y3: integer); external;
overload procedure ftriangle(var f: text; x3, y3: integer); external;
overload procedure ftriangle(x3, y3: integer); external;
procedure cursorg(var f: text; x, y: integer); external;
overload procedure cursorg(x, y: integer); external;
function baseline(var f: text): integer; external;
overload function baseline: integer; external;
procedure setpixel(var f: text; x, y: integer); external;
overload procedure setpixel(x, y: integer); external;
procedure fover(var f: text); external;
overload procedure fover; external;
procedure bover(var f: text); external;
overload procedure bover; external;
procedure finvis(var f: text); external;
overload procedure finvis; external;
procedure binvis(var f: text); external;
overload procedure binvis; external;
procedure fxor(var f: text); external;
overload procedure fxor; external;
procedure bxor(var f: text); external;
overload procedure bxor; external;
function chrsizx(var f: text): integer; external;
overload function chrsizx: integer; external;
function chrsizy(var f: text): integer; external;
overload function chrsizy: integer; external;
function fonts(var f: text): integer; external;
overload function fonts: integer; external;
procedure font(var f: text; fc: integer); external;
overload procedure font(fc: integer); external;
procedure fontnam(var f: text; fc: integer; var fns: string); external;
overload procedure fontnam(fc: integer; var fns: string); external;
procedure fontsiz(var f: text; s: integer); external;
overload procedure fontsiz(s: integer); external;
procedure chrspcy(var f: text; s: integer); external;
overload procedure chrspcy(s: integer); external;
procedure chrspcx(var f: text; s: integer); external;
overload procedure chrspcx(s: integer); external;
function dpmx(var f: text): integer; external;
overload function dpmx: integer; external;
function dpmy(var f: text): integer; external;
overload function dpmy: integer; external;
function strsiz(var f: text; view s: string): integer; external;
overload function strsiz(view s: string): integer; external;
function strsizp(var f: text; view s: string): integer; external;
overload function strsizp(view s: string): integer; external;
function chrpos(var f: text; view s: string; p: integer): integer; external;
overload function chrpos(view s: string; p: integer): integer; external;
procedure writejust(var f: text; view s: string; n: integer); external;
overload procedure writejust(view s: string; n: integer); external;
function justpos(var f: text; view s: string; p, n: integer): integer; external;
overload function justpos(view s: string; p, n: integer): integer; external;
procedure condensed(var f: text; e: boolean); external;
overload procedure condensed(e: boolean); external;
procedure extended(var f: text; e: boolean); external;
overload procedure extended(e: boolean); external;
procedure xlight(var f: text; e: boolean); external;
overload procedure xlight(e: boolean); external;
procedure light(var f: text; e: boolean); external;
overload procedure light(e: boolean); external;
procedure xbold(var f: text; e: boolean); external;
overload procedure xbold(e: boolean); external;
procedure hollow(var f: text; e: boolean); external;
overload procedure hollow(e: boolean); external;
procedure raised(var f: text; e: boolean); external;
overload procedure raised(e: boolean); external;
procedure settabg(var f: text; t: integer); external;
overload procedure settabg(t: integer); external;
procedure restabg(var f: text; t: integer); external;
overload procedure restabg(t: integer); external;
{ Note that we overload the graphical color sets into the old text color sets.
  However, we also provide the "g" postfixed versions for compatability for
  pre-overload code. }
procedure fcolorg(var f: text; r, g, b: integer); external;
overload procedure fcolor(var f: text; r, g, b: integer); external;
overload procedure fcolor(r, g, b: integer); external;
procedure bcolorg(var f: text; r, g, b: integer); external;
overload procedure bcolorg(r, g, b: integer); external;
overload procedure bcolor(var f: text; r, g, b: integer); external;
overload procedure bcolor(r, g, b: integer); external;
procedure loadpict(var f: text; p: integer; view fn: string); external;
overload procedure loadpict(p: integer; view fn: string); external;
function pictsizx(var f: text; p: integer): integer; external;
overload function pictsizx(p: integer): integer; external;
function pictsizy(var f: text; p: integer): integer; external;
overload function pictsizy(p: integer): integer; external;
procedure picture(var f: text; p: integer; x1, y1, x2, y2: integer); external;
overload procedure picture(p: integer; x1, y1, x2, y2: integer); external;
procedure delpict(var f: text; p: integer); external;
overload procedure delpict(p: integer); external;
procedure scrollg(var f: text; x, y: integer); external;
overload procedure scrollg(x, y: integer); external;
{ These are experimental, and are not part of the gralib standard }
procedure viewoffg(var f: text; x, y: integer); external;
overload procedure viewoffg(x, y: integer); external;
procedure viewscale(var f: text; x, y: real); external;
overload procedure viewscale(x, y: real); external;
overload procedure viewscale(var f: text; s: real); external;
overload procedure viewscale(s: real); external;

{ Window management functions }

procedure title(var f: text; view ts: string); external;
overload procedure title(view ts: string); external;
procedure openwin(var infile, outfile, parent: text; wid: ss_filhdl); external;
overload procedure openwin(var infile, outfile: text; wid: ss_filhdl); external;
procedure buffer(var f: text; e: boolean); external;
overload procedure buffer(e: boolean); external;
procedure sizbuf(var f: text; x, y: integer); external;
overload procedure sizbuf(x, y: integer); external;
procedure sizbufg(var f: text; x, y: integer); external;
overload procedure sizbufg(x, y: integer); external;
procedure getsiz(var f: text; var x, y: integer); external;
overload procedure getsiz(var x, y: integer); external;
procedure getsizg(var f: text; var x, y: integer); external;
overload procedure getsizg(var x, y: integer); external;
procedure setsiz(var f: text; x, y: integer); external;
overload procedure setsiz(x, y: integer); external;
procedure setsizg(var f: text; x, y: integer); external;
overload procedure setsizg(x, y: integer); external;
procedure setpos(var f: text; x, y: integer); external;
overload procedure setpos(x, y: integer); external;
procedure setposg(var f: text; x, y: integer); external;
overload procedure setposg(x, y: integer); external;
procedure scnsiz(var f: text; var x, y: integer); external;
overload procedure scnsiz(var x, y: integer); external;
procedure scnsizg(var f: text; var x, y: integer); external;
overload procedure scnsizg(var x, y: integer); external;
procedure winclient(var f: text; cx, cy: integer; var wx, wy: integer;
                    view ms: winmodset); external;
overload procedure winclient(cx, cy: integer; var wx, wy: integer; 
                             view ms: winmodset); external;
procedure winclientg(var f: text; cx, cy: integer; var wx, wy: integer;
                     view ms: winmodset); external;
overload procedure winclientg(cx, cy: integer; var wx, wy: integer;
                              view ms: winmodset); external;
procedure front(var f: text); external;
overload procedure front; external;
procedure back(var f: text); external;
overload procedure back; external;
procedure frame(var f: text; e: boolean); external;
overload procedure frame(e: boolean); external;
procedure sizable(var f: text; e: boolean); external;
overload procedure sizable(e: boolean); external;
procedure sysbar(var f: text; e: boolean); external;
overload procedure sysbar(e: boolean); external;
procedure menu(var f: text; m: menuptr); external;
overload procedure menu(m: menuptr); external;
procedure menuena(var f: text; id: integer; onoff: boolean); external;
overload procedure menuena(id: integer; onoff: boolean); external;
procedure menusel(var f: text; id: integer; select: boolean); external;
overload procedure menusel(id: integer; select: boolean); external;
procedure stdmenu(view sms: stdmenusel; var sm: menuptr; pm: menuptr); external;

{ widgets/controls }

procedure killwidget(var f: text; id: integer); external;
overload procedure killwidget(id: integer); external;
procedure selectwidget(var f: text; id: integer; e: boolean); external;
overload procedure selectwidget(id: integer; e: boolean); external;
procedure enablewidget(var f: text; id: integer; e: boolean); external;
overload procedure enablewidget(id: integer; e: boolean); external;
procedure getwidgettext(var f: text; id: integer; var s: pstring); external;
overload procedure getwidgettext(id: integer; var s: pstring); external;
procedure putwidgettext(var f: text; id: integer; view s: string); external;
overload procedure putwidgettext(id: integer; view s: string); external;
procedure sizwidgetg(var f: text; id: integer; x, y: integer); external;
overload procedure sizwidgetg(id: integer; x, y: integer); external;
procedure poswidgetg(var f: text; id: integer; x, y: integer); external;
overload procedure poswidgetg(id: integer; x, y: integer); external;
procedure buttonsiz(var f: text; view s: string; var w, h: integer); external;
overload procedure buttonsiz(view s: string; var w, h: integer); external;
procedure buttonsizg(var f: text; view s: string; var w, h: integer); external;
overload procedure buttonsizg(view s: string; var w, h: integer); external;
procedure button(var f: text; x1, y1, x2, y2: integer; view s: string; 
                 id: integer); external;
overload procedure button(x1, y1, x2, y2: integer; view s: string;
                          id: integer); external;
procedure buttong(var f: text; x1, y1, x2, y2: integer; view s: string; 
                 id: integer); external;
overload procedure buttong(x1, y1, x2, y2: integer; view s: string;
                          id: integer); external;
procedure checkboxsiz(var f: text; view s: string; var w, h: integer); external;
overload procedure checkboxsiz(view s: string; var w, h: integer); external;
procedure checkboxsizg(var f: text; view s: string; var w, h: integer); external;
overload procedure checkboxsizg(view s: string; var w, h: integer); external;
procedure checkbox(var f: text; x1, y1, x2, y2: integer; view s: string; 
                   id: integer); external;
overload procedure checkbox(x1, y1, x2, y2: integer; view s: string; 
                            id: integer); external;
procedure checkboxg(var f: text; x1, y1, x2, y2: integer; view s: string; 
                   id: integer); external;
overload procedure checkboxg(x1, y1, x2, y2: integer; view s: string; 
                            id: integer); external;
procedure radiobuttonsiz(var f: text; view s: string; var w, h: integer); external;
overload procedure radiobuttonsiz(view s: string; var w, h: integer); external;
procedure radiobuttonsizg(var f: text; view s: string; var w, h: integer); external;
overload procedure radiobuttonsizg(view s: string; var w, h: integer); external;
procedure radiobutton(var f: text; x1, y1, x2, y2: integer; view s: string; 
                      id: integer); external;
overload procedure radiobutton(x1, y1, x2, y2: integer; view s: string; 
                               id: integer); external;
procedure radiobuttong(var f: text; x1, y1, x2, y2: integer; view s: string; 
                      id: integer); external;
overload procedure radiobuttong(x1, y1, x2, y2: integer; view s: string; 
                               id: integer); external;
procedure groupsizg(var f: text; view s: string; cw, ch: integer;
                    var w, h, ox, oy: integer); external;
overload procedure groupsizg(view s: string; cw, ch: integer;
                             var w, h, ox, oy: integer); external;
procedure groupsiz(var f: text; view s: string; cw, ch: integer;
                   var w, h, ox, oy: integer); external;
overload procedure groupsiz(view s: string; cw, ch: integer;
                            var w, h, ox, oy: integer); external;
procedure group(var f: text; x1, y1, x2, y2: integer; view s: string; 
                id: integer); external;
overload procedure group(x1, y1, x2, y2: integer; view s: string; 
                         id: integer); external;
procedure groupg(var f: text; x1, y1, x2, y2: integer; view s: string; 
                id: integer); external;
overload procedure groupg(x1, y1, x2, y2: integer; view s: string; 
                         id: integer); external;
procedure background(var f: text; x1, y1, x2, y2: integer; id: integer); 
   external;
overload procedure background(x1, y1, x2, y2: integer; id: integer); external;
procedure backgroundg(var f: text; x1, y1, x2, y2: integer; id: integer); 
   external;
overload procedure backgroundg(x1, y1, x2, y2: integer; id: integer); external;
procedure scrollvertsizg(var f: text; var w, h: integer); external;
overload procedure scrollvertsizg(var w, h: integer); external;
procedure scrollvertsiz(var f: text; var w, h: integer); external;
overload procedure scrollvertsiz(var w, h: integer); external;
procedure scrollvert(var f: text; x1, y1, x2, y2: integer; id: integer);
          external;
overload procedure scrollvert(x1, y1, x2, y2: integer; id: integer);
          external;
procedure scrollvertg(var f: text; x1, y1, x2, y2: integer; id: integer);
          external;
overload procedure scrollvertg(x1, y1, x2, y2: integer; id: integer);
          external;
procedure scrollhorizsizg(var f: text; var w, h: integer); external;
overload procedure scrollhorizsizg(var w, h: integer); external;
procedure scrollhorizsiz(var f: text; var w, h: integer); external;
overload procedure scrollhorizsiz(var w, h: integer); external;
procedure scrollhoriz(var f: text; x1, y1, x2, y2: integer; id: integer);
          external;
overload procedure scrollhoriz(x1, y1, x2, y2: integer; id: integer);
          external;
procedure scrollhorizg(var f: text; x1, y1, x2, y2: integer; id: integer);
          external;
overload procedure scrollhorizg(x1, y1, x2, y2: integer; id: integer);
          external;
procedure scrollpos(var f: text; id: integer; r: integer); external;
overload procedure scrollpos(id: integer; r: integer); external;
procedure scrollsiz(var f: text; id: integer; r: integer); external;
overload procedure scrollsiz(id: integer; r: integer); external;
procedure numselboxsizg(var f: text; l, u: integer; var w, h: integer); external;
overload procedure numselboxsizg(l, u: integer; var w, h: integer); external;
procedure numselboxsiz(var f: text; l, u: integer; var w, h: integer); external;
overload procedure numselboxsiz(l, u: integer; var w, h: integer); external;
procedure numselbox(var f: text; x1, y1, x2, y2: integer; l, u: integer;
                    id: integer); external;
overload procedure numselbox(x1, y1, x2, y2: integer; l, u: integer;
                    id: integer); external;
procedure numselboxg(var f: text; x1, y1, x2, y2: integer; l, u: integer;
                    id: integer); external;
overload procedure numselboxg(x1, y1, x2, y2: integer; l, u: integer;
                    id: integer); external;
procedure editboxsizg(var f: text; view s: string; var w, h: integer); external;
overload procedure editboxsizg(view s: string; var w, h: integer); external;
procedure editboxsiz(var f: text; view s: string; var w, h: integer); external;
overload procedure editboxsiz(view s: string; var w, h: integer); external;
procedure editbox(var f: text; x1, y1, x2, y2: integer; id: integer);
          external;
overload procedure editbox(x1, y1, x2, y2: integer; id: integer);
          external;
procedure editboxg(var f: text; x1, y1, x2, y2: integer; id: integer);
          external;
overload procedure editboxg(x1, y1, x2, y2: integer; id: integer);
          external;
procedure progbarsizg(var f: text; var w, h: integer); external;
overload procedure progbarsizg(var w, h: integer); external;
procedure progbarsiz(var f: text; var w, h: integer); external;
overload procedure progbarsiz(var w, h: integer); external;
procedure progbar(var f: text; x1, y1, x2, y2: integer; id: integer); external;
overload procedure progbar(x1, y1, x2, y2: integer; id: integer); external;
procedure progbarg(var f: text; x1, y1, x2, y2: integer; id: integer); external;
overload procedure progbarg(x1, y1, x2, y2: integer; id: integer); external;
procedure progbarpos(var f: text; id: integer; pos: integer); external;
overload procedure progbarpos(id: integer; pos: integer); external;
procedure listboxsizg(var f: text; sp: strptr; var w, h: integer); external;
overload procedure listboxsizg(sp: strptr; var w, h: integer); external;
procedure listboxsiz(var f: text; sp: strptr; var w, h: integer); external;
overload procedure listboxsiz(sp: strptr; var w, h: integer); external;
procedure listbox(var f: text; x1, y1, x2, y2: integer; sp: strptr; 
                  id: integer); external;
overload procedure listbox(x1, y1, x2, y2: integer; sp: strptr; 
                  id: integer); external;
procedure listboxg(var f: text; x1, y1, x2, y2: integer; sp: strptr; 
                  id: integer); external;
overload procedure listboxg(x1, y1, x2, y2: integer; sp: strptr; 
                  id: integer); external;
procedure dropboxsizg(var f: text; sp: strptr; var cw, ch, ow, oh: integer);
   external;
overload procedure dropboxsizg(sp: strptr; var cw, ch, ow, oh: integer);
   external;
procedure dropboxsiz(var f: text; sp: strptr; var cw, ch, ow, oh: integer);
   external;
overload procedure dropboxsiz(sp: strptr; var cw, ch, ow, oh: integer);
   external;
procedure dropbox(var f: text; x1, y1, x2, y2: integer; sp: strptr; 
                  id: integer); external;
overload procedure dropbox(x1, y1, x2, y2: integer; sp: strptr; 
                  id: integer); external;
procedure dropboxg(var f: text; x1, y1, x2, y2: integer; sp: strptr; 
                  id: integer); external;
overload procedure dropboxg(x1, y1, x2, y2: integer; sp: strptr; 
                  id: integer); external;
procedure dropeditboxsizg(var f: text; sp: strptr; var cw, ch, ow, oh: integer);
   external;
overload procedure dropeditboxsizg(sp: strptr; var cw, ch, ow, oh: integer);
   external;
procedure dropeditboxsiz(var f: text; sp: strptr; var cw, ch, ow, oh: integer);
   external;
overload procedure dropeditboxsiz(sp: strptr; var cw, ch, ow, oh: integer); 
   external;
procedure dropeditbox(var f: text; x1, y1, x2, y2: integer; sp: strptr; 
                      id: integer); external;
overload procedure dropeditbox(x1, y1, x2, y2: integer; sp: strptr; 
                      id: integer); external;
procedure dropeditboxg(var f: text; x1, y1, x2, y2: integer; sp: strptr; 
                      id: integer); external;
overload procedure dropeditboxg(x1, y1, x2, y2: integer; sp: strptr; 
                      id: integer); external;
procedure slidehorizsizg(var f: text; var w, h: integer); external;
overload procedure slidehorizsizg(var w, h: integer); external;
procedure slidehorizsiz(var f: text; var w, h: integer); external;
overload procedure slidehorizsiz(var w, h: integer); external;
procedure slidehoriz(var f: text; x1, y1, x2, y2: integer; mark: integer;
                     id: integer); external;
overload procedure slidehoriz(x1, y1, x2, y2: integer; mark: integer;
                     id: integer); external;
procedure slidehorizg(var f: text; x1, y1, x2, y2: integer; mark: integer;
                     id: integer); external;
overload procedure slidehorizg(x1, y1, x2, y2: integer; mark: integer;
                     id: integer); external;
procedure slidevertsizg(var f: text; var w, h: integer); external;
overload procedure slidevertsizg(var w, h: integer); external;
procedure slidevertsiz(var f: text; var w, h: integer); external;
overload procedure slidevertsiz(var w, h: integer); external;
procedure slidevert(var f: text; x1, y1, x2, y2: integer; mark: integer;
                    id: integer); external;
overload procedure slidevert(x1, y1, x2, y2: integer; mark: integer;
                    id: integer); external;
procedure slidevertg(var f: text; x1, y1, x2, y2: integer; mark: integer;
                    id: integer); external;
overload procedure slidevertg(x1, y1, x2, y2: integer; mark: integer;
                    id: integer); external;
procedure tabbarsizg(var f: text; tor: tabori; cw, ch: integer; 
                     var w, h, ox, oy: integer); external;
overload procedure tabbarsizg(tor: tabori; cw, ch: integer; 
                              var w, h, ox, oy: integer); external;
procedure tabbarsiz(var f: text; tor: tabori; cw, ch: integer; 
                    var w, h, ox, oy: integer); external;
overload procedure tabbarsiz(tor: tabori; cw, ch: integer; 
                             var w, h, ox, oy: integer); external;
procedure tabbarclientg(var f: text; tor: tabori; w, h: integer; 
                     var cw, ch, ox, oy: integer); external;
overload procedure tabbarclientg(tor: tabori; w, h: integer; 
                                 var cw, ch, ox, oy: integer); external;
procedure tabbarclient(var f: text; tor: tabori; w, h: integer; 
                    var cw, ch, ox, oy: integer); external;
overload procedure tabbarclient(tor: tabori; w, h: integer; 
                                var cw, ch, ox, oy: integer); external;
procedure tabbar(var f: text; x1, y1, x2, y2: integer; sp: strptr; tor: tabori;
                 id: integer); external;
overload procedure tabbar(x1, y1, x2, y2: integer; sp: strptr; tor: tabori;
                 id: integer); external;
procedure tabbarg(var f: text; x1, y1, x2, y2: integer; sp: strptr; tor: tabori;
                 id: integer); external;
overload procedure tabbarg(x1, y1, x2, y2: integer; sp: strptr; tor: tabori;
                 id: integer); external;
procedure tabsel(var f: text; id: integer; tn: integer); external;
overload procedure tabsel(id: integer; tn: integer); external;
procedure alert(view title, message: string); external;
procedure querycolor(var r, g, b: integer); external;
procedure queryopen(var s: pstring); external;
procedure querysave(var s: pstring); external;
procedure queryfind(var s: pstring; var opt: qfnopts); external;
procedure queryfindrep(var s, r: pstring; var opt: qfropts); external;
procedure queryfont(var f: text; var fc, s, fr, fg, fb, br, bg, bb: integer;
                    var effect: qfteffects); external;
overload procedure queryfont(var f: text; var fc, s: integer; 
                             var fcl, bcl: color;
                             var effect: qfteffects); external;
overload procedure queryfont(var fc, s, fr, fg, fb, br, bg, bb: integer; 
                             var effect: qfteffects); external;
overload procedure queryfont(var fc, s: integer; var fcl, bcl: color;
                             var effect: qfteffects); external;

begin
end.
