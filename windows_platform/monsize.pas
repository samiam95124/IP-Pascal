program test(output);

uses wrapper;

var devcon: integer; { main window device context }
    shsize: integer; { display screen size x in millimeters }
    svsize: integer; { display screen size y in millimeters }
    shres:  integer; { display screen pixels in x }
    svres:  integer; { display screen pixels in y }
    sdpmx:  integer; { display screen find dots per meter x }
    sdpmy:  integer; { display screen find dots per meter y }
    winhan: integer; { main window id }

function str(view s: string): pstring;

var p: pstring;

begin

   new(p, max(s));
   p^ := s;
   str := p

end;
function wndproc(hwnd, msg, wparam, lparam: integer): integer;

begin

   wndproc := sc_defwindowproc(hwnd, msg, wparam, lparam)

end;

procedure dummy;

var msg: sc_msg;
    wc:  sc_wndclassa; { windows class structure }
    b:   boolean; { function return }
    r:   integer; { result holder }
    v:   integer;

begin

   { there are a few resources that can only be used by windowed programs, such
     as timers and joysticks. to enable these, we start a false windows
     procedure with a window that is never presented }
   v := $8000000;
   v := v*16;
   { set windows class to a normal window without scroll bars,
     with a windows procedure pointing to the message mirror.
     The message mirror reflects messages that should be handled
     by the program back into the queue, sending others on to
     the windows default handler }
   wc.style      := sc_cs_hredraw or sc_cs_vredraw or sc_cs_owndc;
   wc.wndproc    := sc_wndprocadr(wndproc);
   wc.clsextra   := 0;
   wc.wndextra   := 0;
   wc.instance   := sc_getmodulehandlea_n;
   wc.icon       := sc_loadicona_n(sc_idi_application);
   wc.cursor     := sc_loadcursora_n(sc_idc_arrow);
   wc.background := sc_getstockobject(sc_white_brush);
   wc.menuname   := nil;
   wc.classname  := str('stdwin');
   { register that class }
   b := sc_registerclassa(wc);
   { create the window }
   winhan := sc_createwindowexa_n(
                0, 'StdWin', 'Dummy', sc_ws_overlappedwindow,
                v{sc_cw_usedefault}, v{sc_cw_usedefault}, 
                v{sc_cw_usedefault}, v{sc_cw_usedefault},
                0, 0, sc_getmodulehandlea_n
         );
   devcon := sc_getdc(winhan); { get device context }

end;

begin

   dummy; { create dummy window }
   devcon := sc_getdc(winhan); { get device context }
   shsize := sc_getdevicecaps(devcon, sc_horzsize); { size x in millimeters }
   svsize := sc_getdevicecaps(devcon, sc_vertsize); { size y in millimeters }
   shres := sc_getdevicecaps(devcon, sc_horzres); { pixels in x }
   svres := sc_getdevicecaps(devcon, sc_vertres); { pixels in y }
   sdpmx := round(shres/shsize*1000); { find dots per meter x }
   sdpmy := round(svres/svsize*1000); { find dots per meter y }

   writeln('size x in millimeters: ', shsize);
   writeln('size y in millimeters: ', svsize);
   writeln('pixels in x: ', shres);
   writeln('pixels in y: ', svres);
   writeln('dots per meter x:', sdpmx);
   writeln('dots per meter y: ', sdpmy)

end.
