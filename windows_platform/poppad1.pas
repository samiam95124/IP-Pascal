program poppad1;

uses windows;

const id_edit = 1;
      szappname = 'PopPad1';

var hwnd:     integer;     { window handle }
    msg:      sc_msg;      { message holder }
    wndclass: sc_wndclass; { windows class structure }
    hwndedit: integer;     { handle to edit control }
    r:        integer;     { result holder }
    b:        boolean;     { boolean result holder }
    v:        integer;

{ function places a string in dynamic storage }

function str(view s: string): pstring;

var p: pstring;

begin

   new(p, max(s));
   p^ := s;
   str := p

end;

function hiword(i: integer): integer;

begin

   hiword := i div 65536 and $ffff

end;

function loword(i: integer): integer;

begin

   loword := i and $ffff

end;

function wndproc(hwnd, imsg, wparam, lparam: integer): integer;

var {b:        boolean;} { result holder }
    r:        integer; { result holder }
    creatconv: record

       case boolean of

          true: (i: integer);
          false: (cs: ^sc_createstruct);

    end;

begin

   if imsg = sc_wm_create then begin

      creatconv.i := lparam;
      hwndedit := sc_createwindow('edit', '', sc_ws_child or sc_ws_visible or
                    sc_ws_hscroll or sc_ws_vscroll or sc_ws_border or 
                    sc_es_left or sc_es_multiline or sc_es_autohscroll or
                    sc_es_autovscroll, 100{0}, 100{0}, 400{0}, 400{0}, hwnd, id_edit, 
                    0{creatconv.cs^.hinstance});
      r := 0

   end else if imsg = sc_wm_setfocus then begin

      {r := sc_setfocus(hwndedit);}
      r := 0

   end else if imsg = sc_wm_size then begin

      {b := sc_movewindow(hwndedit, 0, 0, loword(lparam), hiword(lparam), true);}
      r := 0

   end else if imsg = sc_wm_command then begin

      if loword(wparam) = id_edit then
         if (hiword(wparam) = sc_en_errspace) or 
            (hiword(wparam) = sc_en_maxtext) then
         r := sc_messagebox(hwnd, 'Edit control out of space.', 
                            szappname, sc_mb_ok or  sc_mb_iconstop);
      r := 0
         
   end else if imsg = sc_wm_destroy then begin

      sc_postquitmessage(0);
      r := 0

   end else { added erase background to stop flicker in this program }
      if imsg = sc_wm_erasebkgnd then r := 1
   else r := sc_defwindowproc(hwnd, imsg, wparam, lparam);

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
   wndclass.style      := sc_cs_hredraw or sc_cs_vredraw;
   wndclass.wndproc    := sc_wndprocadr(wndproc);
   wndclass.clsextra   := 0;
   wndclass.wndextra   := 0;
   wndclass.instance   := sc_getmodulehandle_n;
   wndclass.icon       := sc_loadicon_n(sc_idi_application);
   wndclass.cursor     := sc_loadcursor_n(sc_idc_arrow);
   wndclass.background := sc_getstockobject(sc_white_brush);
   wndclass.menuname   := nil;
   wndclass.classname  := str(szappname);
   { register that class }
   if not sc_registerclass(wndclass) then begin

      r := sc_messagebox(0, 'This program requires Windows NT!',
                         szappname, sc_mb_iconerror);
      halt

   end;
   { create the window }
   hwnd := sc_createwindow(szappname, szappname, 
                           sc_ws_overlappedwindow,
                           v{sc_cw_usedefault}, v{sc_cw_usedefault}, 
                           v{sc_cw_usedefault}, v{sc_cw_usedefault},
                           0, 0, sc_getmodulehandle_n);
   { present the window }
   b := sc_showwindow(hwnd, sc_sw_showdefault);
   { send first paint message }
   b := sc_updatewindow(hwnd);
   { message loop }
   while sc_getmessage(msg, 0, 0, 0) <> 0 do begin { not a quit message }

      b := sc_translatemessage(msg); { translate keyboard events }
      r := sc_dispatchmessage(msg);

   end                  

end. { main program }

   