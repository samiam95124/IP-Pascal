{******************************************************************************
*                                                                             *
*                            DISPLAY MESSAGES                                 *
*                                                                             *
* This program displays all of the messages it receives, up to 50             *
* (a screenfull). It is used to investigate what startup messages Windows is  *
* sending us.                                                                 *
*                                                                             *
******************************************************************************}

program dispmsg(input, output);

uses windows,
     strlib;

const maxmsg = 50; { number of messages we can hold }
      msgnum = 152; { number of messages in table }

var hwnd:      integer;      { window handle }
    msg:       sc_msg;       { message holder }
    wndclass:  sc_wndclassa; { windows class structure }
    r:         integer;      { result holder }
    b:         boolean;      { boolean result holder }
    v:         integer;
    screen:    packed array [1..maxmsg, 1..100] of char;
    msginx:    1..maxmsg;    { index for message array }
    err:       boolean;

{ function places a string in dynamic storage }

function str(view s: string): pstring;

var p: pstring;

begin

   new(p, max(s));
   p^ := s;
   str := p

end;

function wndproc(hwnd, imsg, wparam, lparam: integer): integer;

var ps:   sc_paint; { paint structure }
    hdc:  integer;  { handle to device context }
    b:    boolean;  { result holder }
    r:    integer;  { result holder }
    i:    integer;  { index for buffer }

begin

   if imsg = sc_wm_create then begin

      r := 0

   end else if imsg = sc_wm_paint then begin

      { perform paint cycle }
	   hdc := sc_BeginPaint(hwnd, ps);
      for i := 1 to maxmsg do b := sc_textout(hdc, 0, i*15,  screen[i]);
	   b := sc_EndPaint(hwnd, ps);
      r := 0

   end else if imsg = sc_wm_destroy then begin

      sc_postquitmessage(0);
      r := 0

   end else r := sc_defwindowproc(hwnd, imsg, wparam, lparam);

   wndproc := r

end;

begin

   for msginx := 1 to maxmsg do clears(screen[msginx]);
   msginx := 1;
   while not eof(input) and (msginx < maxmsg) do begin

      readsp(input, screen[msginx], err);
      readln;
      msginx := msginx+1

   end;
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
            0, 'stdwin', 'Disp', sc_ws_overlappedwindow,
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

   