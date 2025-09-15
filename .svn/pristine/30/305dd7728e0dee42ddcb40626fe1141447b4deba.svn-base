{******************************************************************************
*                                                                             *
*                        HELLO FOR WINDOWS 95                                 *
*                                                                             *
* This program displays a hello message centered in the middle of a window.   *
* It is a direct Pascal translation of the hellowin program given in          *
* "programming windows 95" by Charles Petzold.                                *
*                                                                             *
******************************************************************************}

program hellow;

uses windows{,
     strlib};

var wc:   sc_wndclassa; { windows class structure }
    wh:   integer;      { window handle }
    msg:  sc_msg;       { message holder }
    r:    integer;      { result holder }
    b:    boolean;      { boolean result holder }
    v:    integer;

{ function places a string in dynamic storage }

function str(view s: string): pstring;

var p: pstring;

begin

   new(p, max(s));
   p^ := s;
   str := p

end;

function wndproc(hwnd, imsg, wparam, lparam: integer): integer;

var hdc:  integer;  { handle to device context }
    ps:   sc_paint; { paint structure }
    rect: sc_rect;  { rectangle holder }
    b: boolean;     { result holder }
    r: integer;     { result holder }

begin

   if imsg = sc_wm_create then begin

      r := 0

   end else if imsg = sc_wm_paint then begin

      { perform paint cycle }
	   hdc := sc_BeginPaint(hwnd, ps);
      b := sc_GetClientRect(hwnd, rect);
      r := sc_DrawText(hdc, 'Hello from Pascal Windows !!', rect,
	                    sc_DT_SINGLELINE or sc_DT_CENTER or sc_DT_VCENTER);
	   b := sc_EndPaint(hwnd, ps);
      r := 0

   end else if imsg = sc_wm_destroy then begin

      sc_postquitmessage(0);
      r := 0

   end else r := sc_defwindowproc(hwnd, imsg, wparam, lparam);

   wndproc := r

end;

begin { main program }

   v := $8000000;
   v := v*16;
   { set windows class to a normal window without scroll bars,
     with a windows procedure pointing to the message mirror.
     The message mirror reflects messages that should be handled
     by the program back into the queue, sending others on to
     the windows default handler }
   wc.style      := sc_cs_hredraw or sc_cs_vredraw;
   wc.wndproc    := sc_wndprocadr(wndproc);
   wc.clsextra   := 0;
   wc.wndextra   := 0;
   wc.instance   := sc_getmodulehandle_n;
   wc.icon       := sc_loadicon_n(sc_idi_application);
   wc.cursor     := sc_loadcursor_n(sc_idc_arrow);
   wc.background := sc_getstockobject(sc_white_brush);
   wc.menuname   := nil;
   wc.classname  := str('stdwin');
   { register that class }
   b := sc_registerclass(wc);
   { create the window }
   wh := sc_createwindow(
            'stdwin', 'Hello', sc_ws_overlappedwindow,
            v{sc_cw_usedefault}, v{sc_cw_usedefault}, 
            v{sc_cw_usedefault}, v{sc_cw_usedefault},
            0, 0, sc_getmodulehandle_n
         );
   { present the window }
   b := sc_showwindow(wh, sc_sw_showdefault);
   { send first paint message }
   b := sc_updatewindow(wh);
   { message handling loop. Since messages are reflected, we do all
     message handling here instead of sending them on to the windows
     procedure as normal }
   while sc_getmessage(msg, 0, 0, 0) <> 0 do begin { not a quit message }

      b := sc_translatemessage(msg); { translate keyboard events }
      r := sc_dispatchmessage(msg);

   end                  

end. { main program }

   