{******************************************************************************
*                                                                             *
*                            DISPLAY MESSAGES                                 *
*                                                                             *
* This program displays all of the messages it receives, up to 50             *
* (a screenfull). It is used to investigate what startup messages Windows is  *
* sending us.                                                                 *
*                                                                             *
******************************************************************************}

program dispmsg;

uses windows,
     strlib;

const maxmsg = 50; { number of messages we can hold }
      msgnum = 152; { number of messages in table }

type msgrec = record

        msg:    integer; { message number }
        wparam: integer; { parameters }
        lparam: integer;
        seq:    integer; { sequence number }

     end;

fixed msgtab: array [1..152] of record

         name: packed array [1..23] of char; 
         val:  integer

      end = array

         record 'WM_NULL                ', $0000 end,
         record 'WM_CREATE              ', $0001 end,
         record 'WM_DESTROY             ', $0002 end,
         record 'WM_MOVE                ', $0003 end,
         record 'WM_SIZE                ', $0005 end,
         record 'WM_ACTIVATE            ', $0006 end,
         record 'WM_SETFOCUS            ', $0007 end,
         record 'WM_KILLFOCUS           ', $0008 end,
         record 'WM_ENABLE              ', $000A end,
         record 'WM_SETREDRAW           ', $000B end,
         record 'WM_SETTEXT             ', $000C end,
         record 'WM_GETTEXT             ', $000D end,
         record 'WM_GETTEXTLENGTH       ', $000E end,
         record 'WM_PAINT               ', $000F end,
         record 'WM_CLOSE               ', $0010 end,
         record 'WM_QUERYENDSESSION     ', $0011 end,
         record 'WM_QUIT                ', $0012 end,
         record 'WM_QUERYOPEN           ', $0013 end,
         record 'WM_ERASEBKGND          ', $0014 end,
         record 'WM_SYSCOLORCHANGE      ', $0015 end,
         record 'WM_ENDSESSION          ', $0016 end,
         record 'WM_SHOWWINDOW          ', $0018 end,
         record 'WM_WININICHANGE        ', $001A end,
         record 'WM_DEVMODECHANGE       ', $001B end,
         record 'WM_ACTIVATEAPP         ', $001C end,
         record 'WM_FONTCHANGE          ', $001D end,
         record 'WM_TIMECHANGE          ', $001E end,
         record 'WM_CANCELMODE          ', $001F end,
         record 'WM_SETCURSOR           ', $0020 end,
         record 'WM_MOUSEACTIVATE       ', $0021 end,
         record 'WM_CHILDACTIVATE       ', $0022 end,
         record 'WM_QUEUESYNC           ', $0023 end,
         record 'WM_GETMINMAXINFO       ', $0024 end,
         record 'WM_PAINTICON           ', $0026 end,
         record 'WM_ICONERASEBKGND      ', $0027 end,
         record 'WM_NEXTDLGCTL          ', $0028 end,
         record 'WM_SPOOLERSTATUS       ', $002A end,
         record 'WM_DRAWITEM            ', $002B end,
         record 'WM_MEASUREITEM         ', $002C end,
         record 'WM_DELETEITEM          ', $002D end,
         record 'WM_VKEYTOITEM          ', $002E end,
         record 'WM_CHARTOITEM          ', $002F end,
         record 'WM_SETFONT             ', $0030 end,
         record 'WM_GETFONT             ', $0031 end,
         record 'WM_SETHOTKEY           ', $0032 end,
         record 'WM_GETHOTKEY           ', $0033 end,
         record 'WM_QUERYDRAGICON       ', $0037 end,
         record 'WM_COMPAREITEM         ', $0039 end,
         record 'WM_COMPACTING          ', $0041 end,
         record 'WM_OTHERWINDOWCREATED  ', $0042 end,
         record 'WM_OTHERWINDOWDESTROYED', $0043 end,
         record 'WM_COMMNOTIFY          ', $0044 end,
         record 'WM_HOTKEYEVENT         ', $0045 end,
         record 'WM_WINDOWPOSCHANGING   ', $0046 end,
         record 'WM_WINDOWPOSCHANGED    ', $0047 end,
         record 'WM_POWER               ', $0048 end,
         record 'WM_COPYDATA            ', $004A end,
         record 'WM_CANCELJOURNAL       ', $004B end,
         record 'WM_NCCREATE            ', $0081 end,
         record 'WM_NCDESTROY           ', $0082 end,
         record 'WM_NCCALCSIZE          ', $0083 end,
         record 'WM_NCHITTEST           ', $0084 end,
         record 'WM_NCPAINT             ', $0085 end,
         record 'WM_NCACTIVATE          ', $0086 end,
         record 'WM_GETDLGCODE          ', $0087 end,
         record 'WM_NCMOUSEMOVE         ', $00A0 end,
         record 'WM_NCLBUTTONDOWN       ', $00A1 end,
         record 'WM_NCLBUTTONUP         ', $00A2 end,
         record 'WM_NCLBUTTONDBLCLK     ', $00A3 end,
         record 'WM_NCRBUTTONDOWN       ', $00A4 end,
         record 'WM_NCRBUTTONUP         ', $00A5 end,
         record 'WM_NCRBUTTONDBLCLK     ', $00A6 end,
         record 'WM_NCMBUTTONDOWN       ', $00A7 end,
         record 'WM_NCMBUTTONUP         ', $00A8 end,
         record 'WM_NCMBUTTONDBLCLK     ', $00A9 end,
         record 'WM_KEYFIRST            ', $0100 end,
         record 'WM_KEYDOWN             ', $0100 end,
         record 'WM_KEYUP               ', $0101 end,
         record 'WM_CHAR                ', $0102 end,
         record 'WM_DEADCHAR            ', $0103 end,
         record 'WM_SYSKEYDOWN          ', $0104 end,
         record 'WM_SYSKEYUP            ', $0105 end,
         record 'WM_SYSCHAR             ', $0106 end,
         record 'WM_SYSDEADCHAR         ', $0107 end,
         record 'WM_KEYLAST             ', $0108 end,
         record 'WM_INITDIALOG          ', $0110 end,
         record 'WM_COMMAND             ', $0111 end,
         record 'WM_SYSCOMMAND          ', $0112 end,
         record 'WM_TIMER               ', $0113 end,
         record 'WM_HSCROLL             ', $0114 end,
         record 'WM_VSCROLL             ', $0115 end,
         record 'WM_INITMENU            ', $0116 end,
         record 'WM_INITMENUPOPUP       ', $0117 end,
         record 'WM_MENUSELECT          ', $011F end,
         record 'WM_MENUCHAR            ', $0120 end,
         record 'WM_ENTERIDLE           ', $0121 end,
         record 'WM_CTLCOLORMSGBOX      ', $0132 end,
         record 'WM_CTLCOLOREDIT        ', $0133 end,
         record 'WM_CTLCOLORLISTBOX     ', $0134 end,
         record 'WM_CTLCOLORBTN         ', $0135 end,
         record 'WM_CTLCOLORDLG         ', $0136 end,
         record 'WM_CTLCOLORSCROLLBAR   ', $0137 end,
         record 'WM_CTLCOLORSTATIC      ', $0138 end,
         record 'WM_MOUSEFIRST          ', $0200 end,
         record 'WM_MOUSEMOVE           ', $0200 end,
         record 'WM_LBUTTONDOWN         ', $0201 end,
         record 'WM_LBUTTONUP           ', $0202 end,
         record 'WM_LBUTTONDBLCLK       ', $0203 end,
         record 'WM_RBUTTONDOWN         ', $0204 end,
         record 'WM_RBUTTONUP           ', $0205 end,
         record 'WM_RBUTTONDBLCLK       ', $0206 end,
         record 'WM_MBUTTONDOWN         ', $0207 end,
         record 'WM_MBUTTONUP           ', $0208 end,
         record 'WM_MBUTTONDBLCLK       ', $0209 end,
         record 'WM_MOUSELAST           ', $0209 end,
         record 'WM_PARENTNOTIFY        ', $0210 end,
         record 'WM_ENTERMENULOOP       ', $0211 end,
         record 'WM_EXITMENULOOP        ', $0212 end,
         record 'WM_MDICREATE           ', $0220 end,
         record 'WM_MDIDESTROY          ', $0221 end,
         record 'WM_MDIACTIVATE         ', $0222 end,
         record 'WM_MDIRESTORE          ', $0223 end,
         record 'WM_MDINEXT             ', $0224 end,
         record 'WM_MDIMAXIMIZE         ', $0225 end,
         record 'WM_MDITILE             ', $0226 end,
         record 'WM_MDICASCADE          ', $0227 end,
         record 'WM_MDIICONARRANGE      ', $0228 end,
         record 'WM_MDIGETACTIVE        ', $0229 end,
         record 'WM_MDISETMENU          ', $0230 end,
         record 'WM_DROPFILES           ', $0233 end,
         record 'WM_MDIREFRESHMENU      ', $0234 end,
         record 'WM_CUT                 ', $0300 end,
         record 'WM_COPY                ', $0301 end,
         record 'WM_PASTE               ', $0302 end,
         record 'WM_CLEAR               ', $0303 end,
         record 'WM_UNDO                ', $0304 end,
         record 'WM_RENDERFORMAT        ', $0305 end,
         record 'WM_RENDERALLFORMATS    ', $0306 end,
         record 'WM_DESTROYCLIPBOARD    ', $0307 end,
         record 'WM_DRAWCLIPBOARD       ', $0308 end,
         record 'WM_PAINTCLIPBOARD      ', $0309 end,
         record 'WM_VSCROLLCLIPBOARD    ', $030A end,
         record 'WM_SIZECLIPBOARD       ', $030B end,
         record 'WM_ASKCBFORMATNAME     ', $030C end,
         record 'WM_CHANGECBCHAIN       ', $030D end,
         record 'WM_HSCROLLCLIPBOARD    ', $030E end,
         record 'WM_QUERYNEWPALETTE     ', $030F end,
         record 'WM_PALETTEISCHANGING   ', $0310 end,
         record 'WM_PALETTECHANGED      ', $0311 end,
         record 'WM_HOTKEY              ', $0312 end,
         record 'WM_PENWINFIRST         ', $0380 end,
         record 'WM_PENWINLAST          ', $038F end

      end;

var hwnd:      integer;      { window handle }
    msg:       sc_msg;       { message holder }
    wndclass:  sc_wndclassa; { windows class structure }
    r:         integer;      { result holder }
    b:         boolean;      { boolean result holder }
    v:         integer;
    msgsav:    array [1..maxmsg] of msgrec; { save for messages }
    msginx:    integer; { index for message array }
    msgcnt:    integer; { sequence number for messages }

{ function places a string in dynamic storage }

function str(view s: string): pstring;

var p: pstring;

begin

   new(p, max(s));
   p^ := s;
   str := p

end;

{ replacing this with hexsfp causes crash, suspect stack problems
  with direct class calls }

procedure hexstr(var s: string; f: byte; w: integer);
 
var i, j: integer;
    v:    integer;
    p:    integer;
    t:    integer;

procedure putstr(c: char);

begin

   s[p] := c;
   p := p+1

end;

procedure putval(v: integer);

begin

   if v >= 10 then v := v + (ord('A') - 10)
   else v := v + ord('0');
   putstr(chr(v))

end;
 
begin

   clears(s);
   p := 1;
   { set sign of number and convert }
   if w < 0 then begin

      w := w+1+maxint; { convert number to 31 bit unsigned }
      t := w div $10000000 + 8; { extract high digit }
      putval(t); { ouput that }
	   w := w mod $10000000; { remove that digit }
      f := 7 { force field to full }     

   end;
   for i := 1 to f do begin { output digits }

      v := w; { save word }
      for j := 1 to f - i do v := v div 16; { extract digit }
      v := v mod 16; { mask }
      putval(v)

   end

end;

procedure writemsg(hdc, msg, wparam, lparam, seq, y: integer);

var b:      boolean;
    s:      packed array [1..20] of char;
    ti: 1..msgnum; { index for message table }
    fi: 0..msgnum; { index for message table }

begin

   fi := 0; { set no message found }
   for ti := 1 to msgnum do if msgtab[ti].val = msg then fi := ti;
   intsp(s, seq);
   b := sc_textout(hdc, 0, y, s);
   hexstr(s, 8, msg);
   b := sc_textout(hdc, 100, y, s);
   if fi > 0 then b := sc_textout(hdc, 200, y, msgtab[fi].name)
   else b := sc_textout(hdc, 200, y, '                       ');
   hexstr(s, 8, wparam);
   b := sc_textout(hdc, 500, y, s);
   hexstr(s, 8, lparam);
   b := sc_textout(hdc, 600, y, s);

end;

function wndproc(hwnd, imsg, wparam, lparam: integer): integer;

var ps:   sc_paint; { paint structure }
    hdc:  integer;  { handle to device context }
    b:    boolean;  { result holder }
    r:    integer;  { result holder }
    i:    integer;  { index for buffer }

begin

   msgsav[msginx].msg := imsg; { place new message }
   msgsav[msginx].wparam := wparam;
   msgsav[msginx].lparam := lparam;
   msgsav[msginx].seq := msgcnt;
   msgcnt := msgcnt+1; { count messages }
   if msginx < maxmsg then msginx := msginx+1 { next message }
   { if message save is full, move all down one to make room }
   else for i := 1 to msginx-1 do msgsav[i] := msgsav[i+1];
   if imsg = sc_wm_create then begin

      r := 0

   end else if imsg = sc_wm_paint then begin

      { perform paint cycle }
	   hdc := sc_BeginPaint(hwnd, ps);
      b := sc_textout(hdc, 0, 0,  'Seq');
      b := sc_textout(hdc, 100, 0,  'Msg');
      b := sc_textout(hdc, 200, 0,  'Name');
      b := sc_textout(hdc, 500, 0,  'Wparam');
      b := sc_textout(hdc, 600, 0,  'Lparam');
      b := sc_textout(hdc, 0, 15,
      '=====================================================================================');
      for i := 1 to msginx-1 do
         writemsg(hdc, msgsav[i].msg, msgsav[i].wparam, msgsav[i].lparam,
                  msgsav[i].seq, i*15+20);
	   b := sc_EndPaint(hwnd, ps);
      r := 0

   end else if imsg = sc_wm_destroy then begin

      sc_postquitmessage(0);
      r := 0

   end else r := sc_defwindowproc(hwnd, imsg, wparam, lparam);

   wndproc := r

end;

begin

   msginx := 1; { set 1st message }
   msgcnt := 1;
   v := $8000000;
   v := v*16;
   { set windows class to a normal window without scroll bars,
     with a windows procedure pointing to the message mirror.
     The message mirror reflects messages that should be handled
     by the program back into the queue, sending others on to
     the windows default handler }
   wndclass.style      := sc_cs_hredraw or sc_cs_vredraw;
   wndclass.wndproc    := sc_wndprocadr(wndproc);
   wndclass.clsextra   := 0;
   wndclass.wndextra   := 0;
   wndclass.instance   := sc_getmodulehandle_n;
   wndclass.icon       := sc_loadicon_n(sc_idi_application);
   wndclass.cursor     := sc_loadcursor_n(sc_idc_arrow);
   wndclass.background := sc_getstockobject(sc_white_brush);
   wndclass.menuname   := nil;
   wndclass.classname  := str('stdwin');
   { register that class }
   b := sc_registerclass(wndclass);
   { create the window }
   hwnd := sc_createwindowex_n(
            0, 'stdwin', 'Dispmsg', sc_ws_overlappedwindow,
            v{sc_cw_usedefault}, v{sc_cw_usedefault}, 
            v{sc_cw_usedefault}, v{sc_cw_usedefault},
            0, 0, sc_getmodulehandle_n
         );
   { present the window }
   b := sc_showwindow(hwnd, sc_sw_showdefault);
   { send first paint message }
   b := sc_updatewindow(hwnd);
   { message handling loop. Since messages are reflected, we do all
     message handling here instead of sending them on to the windows
     procedure as normal }
   while sc_getmessage(msg, 0, 0, 0) do begin { not a quit message }

      b := sc_translatemessage(msg); { translate keyboard events }
      r := sc_dispatchmessage(msg); { send to windows procedure }

   end

end.

   