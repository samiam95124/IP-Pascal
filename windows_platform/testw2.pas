program testw(output);

uses windows;

var wc:         sc_wndclassa; { windows class structure }
    winhan:     integer;      { window handle }
    msg:        sc_msg;       { message holder }
    r:          integer;      { result holder }
    b:          boolean;      { boolean result holder }
    v:          integer;
    fndrepmsg:  integer; { message assignment for find/replace }
    fr:         sc_findreplace;         { string select structure }
    fs:         sc_findreplace_str_ptr; { pointer to finder string }
    threadstart: boolean; { thread starts }
    threadid:   integer; { dummy thread id (unused) }

{******************************************************************************

Print hex number

Prints a hex number, with the given field. Used for diagnostics, and can be
commented out.

******************************************************************************}

procedure prthex(var f:  text;     { file to output to }
                     w:  integer;  { value to print }
                     fd: integer); { field width }

var i, j: integer;
    v:    integer;

begin

   for i := 1 to fd do begin { output digits }

      v := w; { save word }
      for j := 1 to fd - i do v := v div 16; { extract digit }
      v := v mod 16; { mask }
      { convert ascii }
      if v >= 10 then v := v + (ord('A') - 10)
      else v := v + ord('0');
      write(f, chr(v)) { output }

   end

end;

{******************************************************************************

Print message string

This routine is for diagnostic use. Comment it out on production builds.

******************************************************************************}

procedure prtmsgstr(var f: text; mn: integer);

begin

   prthex(f, mn, 4);
   write(f, ': ');
   if ((mn >= $4c) and (mn <= $80)) or
      ((mn >= $88) and (mn <= $9f)) or
      ((mn >= $aa) and (mn <= $ff)) or
      ((mn >= $118) and (mn <= $11e)) or
      ((mn >= $139) and (mn <= $1ff)) or
      ((mn >= $213) and (mn <= $219)) or
      ((mn >= $231) and (mn <= $232)) or
      ((mn >= $235) and (mn <= $2ff)) or
      ((mn >= $313) and (mn <= $37f)) or
      ((mn >= $381) and (mn <= $38e)) or
      ((mn >= $390) and (mn <= $3ff)) then write(f, '???')
   else if (mn >= $400) and (mn <= $bfff) then write(f, 'User message')
   else if (mn >= $c000) and (mn <= $ffff) then write(f, 'Registered message')
   else case mn of

      $0000: write(f, 'WM_NULL');                 
      $0001: write(f, 'WM_CREATE');               
      $0002: write(f, 'WM_DESTROY');              
      $0003: write(f, 'WM_MOVE');                 
      $0005: write(f, 'WM_SIZE');                 
      $0006: write(f, 'WM_ACTIVATE');             
      $0007: write(f, 'WM_SETFOCUS');             
      $0008: write(f, 'WM_KILLFOCUS');            
      $000A: write(f, 'WM_ENABLE');               
      $000B: write(f, 'WM_SETREDRAW');            
      $000C: write(f, 'WM_SETTEXT');              
      $000D: write(f, 'WM_GETTEXT');              
      $000E: write(f, 'WM_GETTEXTLENGTH');        
      $000F: write(f, 'WM_PAINT');                
      $0010: write(f, 'WM_CLOSE');                
      $0011: write(f, 'WM_QUERYENDSESSION');      
      $0012: write(f, 'WM_QUIT');                 
      $0013: write(f, 'WM_QUERYOPEN');            
      $0014: write(f, 'WM_ERASEBKGND');           
      $0015: write(f, 'WM_SYSCOLORCHANGE');       
      $0016: write(f, 'WM_ENDSESSION');           
      $0018: write(f, 'WM_SHOWWINDOW');           
      $001A: write(f, 'WM_WININICHANGE');         
      $001B: write(f, 'WM_DEVMODECHANGE');        
      $001C: write(f, 'WM_ACTIVATEAPP');          
      $001D: write(f, 'WM_FONTCHANGE');           
      $001E: write(f, 'WM_TIMECHANGE');           
      $001F: write(f, 'WM_CANCELMODE');           
      $0020: write(f, 'WM_SETCURSOR');            
      $0021: write(f, 'WM_MOUSEACTIVATE');        
      $0022: write(f, 'WM_CHILDACTIVATE');        
      $0023: write(f, 'WM_QUEUESYNC');            
      $0024: write(f, 'WM_GETMINMAXINFO');        
      $0026: write(f, 'WM_PAINTICON');            
      $0027: write(f, 'WM_ICONERASEBKGND');       
      $0028: write(f, 'WM_NEXTDLGCTL');           
      $002A: write(f, 'WM_SPOOLERSTATUS');        
      $002B: write(f, 'WM_DRAWITEM');             
      $002C: write(f, 'WM_MEASUREITEM');          
      $002D: write(f, 'WM_DELETEITEM');           
      $002E: write(f, 'WM_VKEYTOITEM');           
      $002F: write(f, 'WM_CHARTOITEM');           
      $0030: write(f, 'WM_SETFONT');              
      $0031: write(f, 'WM_GETFONT');              
      $0032: write(f, 'WM_SETHOTKEY');            
      $0033: write(f, 'WM_GETHOTKEY');            
      $0037: write(f, 'WM_QUERYDRAGICON');        
      $0039: write(f, 'WM_COMPAREITEM');          
      $0041: write(f, 'WM_COMPACTING');           
      $0042: write(f, 'WM_OTHERWINDOWCREATED');   
      $0043: write(f, 'WM_OTHERWINDOWDESTROYED'); 
      $0044: write(f, 'WM_COMMNOTIFY');           
      $0045: write(f, 'WM_HOTKEYEVENT');          
      $0046: write(f, 'WM_WINDOWPOSCHANGING');    
      $0047: write(f, 'WM_WINDOWPOSCHANGED');     
      $0048: write(f, 'WM_POWER');                
      $004A: write(f, 'WM_COPYDATA');             
      $004B: write(f, 'WM_CANCELJOURNAL');        
      $0081: write(f, 'WM_NCCREATE');             
      $0082: write(f, 'WM_NCDESTROY');            
      $0083: write(f, 'WM_NCCALCSIZE');           
      $0084: write(f, 'WM_NCHITTEST');            
      $0085: write(f, 'WM_NCPAINT');              
      $0086: write(f, 'WM_NCACTIVATE');           
      $0087: write(f, 'WM_GETDLGCODE');           
      $00A0: write(f, 'WM_NCMOUSEMOVE');          
      $00A1: write(f, 'WM_NCLBUTTONDOWN');        
      $00A2: write(f, 'WM_NCLBUTTONUP');          
      $00A3: write(f, 'WM_NCLBUTTONDBLCLK');      
      $00A4: write(f, 'WM_NCRBUTTONDOWN');        
      $00A5: write(f, 'WM_NCRBUTTONUP');          
      $00A6: write(f, 'WM_NCRBUTTONDBLCLK');      
      $00A7: write(f, 'WM_NCMBUTTONDOWN');        
      $00A8: write(f, 'WM_NCMBUTTONUP');          
      $00A9: write(f, 'WM_NCMBUTTONDBLCLK');      
      $0100: write(f, 'WM_KEYFIRST');             
      { $0100: write(f, 'WM_KEYDOWN'); }
      $0101: write(f, 'WM_KEYUP');                
      $0102: write(f, 'WM_CHAR');                 
      $0103: write(f, 'WM_DEADCHAR');             
      $0104: write(f, 'WM_SYSKEYDOWN');           
      $0105: write(f, 'WM_SYSKEYUP');             
      $0106: write(f, 'WM_SYSCHAR');              
      $0107: write(f, 'WM_SYSDEADCHAR');          
      $0108: write(f, 'WM_KEYLAST');              
      $0110: write(f, 'WM_INITDIALOG');           
      $0111: write(f, 'WM_COMMAND');              
      $0112: write(f, 'WM_SYSCOMMAND');           
      $0113: write(f, 'WM_TIMER');                
      $0114: write(f, 'WM_HSCROLL');              
      $0115: write(f, 'WM_VSCROLL');              
      $0116: write(f, 'WM_INITMENU');             
      $0117: write(f, 'WM_INITMENUPOPUP');        
      $011F: write(f, 'WM_MENUSELECT');           
      $0120: write(f, 'WM_MENUCHAR');             
      $0121: write(f, 'WM_ENTERIDLE');            
      $0132: write(f, 'WM_CTLCOLORMSGBOX');       
      $0133: write(f, 'WM_CTLCOLOREDIT');         
      $0134: write(f, 'WM_CTLCOLORLISTBOX');      
      $0135: write(f, 'WM_CTLCOLORBTN');          
      $0136: write(f, 'WM_CTLCOLORDLG');          
      $0137: write(f, 'WM_CTLCOLORSCROLLBAR');    
      $0138: write(f, 'WM_CTLCOLORSTATIC');       
      $0200: write(f, 'WM_MOUSEFIRST');           
      { $0200: write(f, 'WM_MOUSEMOVE'); }
      $0201: write(f, 'WM_LBUTTONDOWN');          
      $0202: write(f, 'WM_LBUTTONUP');            
      $0203: write(f, 'WM_LBUTTONDBLCLK');        
      $0204: write(f, 'WM_RBUTTONDOWN');          
      $0205: write(f, 'WM_RBUTTONUP');            
      $0206: write(f, 'WM_RBUTTONDBLCLK');        
      $0207: write(f, 'WM_MBUTTONDOWN');          
      $0208: write(f, 'WM_MBUTTONUP');            
      $0209: write(f, 'WM_MBUTTONDBLCLK');        
      { $0209: write(f, 'WM_MOUSELAST'); }           
      $0210: write(f, 'WM_PARENTNOTIFY');         
      $0211: write(f, 'WM_ENTERMENULOOP');        
      $0212: write(f, 'WM_EXITMENULOOP');         
      $0220: write(f, 'WM_MDICREATE');            
      $0221: write(f, 'WM_MDIDESTROY');           
      $0222: write(f, 'WM_MDIACTIVATE');          
      $0223: write(f, 'WM_MDIRESTORE');           
      $0224: write(f, 'WM_MDINEXT');              
      $0225: write(f, 'WM_MDIMAXIMIZE');          
      $0226: write(f, 'WM_MDITILE');              
      $0227: write(f, 'WM_MDICASCADE');           
      $0228: write(f, 'WM_MDIICONARRANGE');       
      $0229: write(f, 'WM_MDIGETACTIVE');         
      $0230: write(f, 'WM_MDISETMENU');           
      $0233: write(f, 'WM_DROPFILES');            
      $0234: write(f, 'WM_MDIREFRESHMENU');       
      $0300: write(f, 'WM_CUT');                  
      $0301: write(f, 'WM_COPY');                 
      $0302: write(f, 'WM_PASTE');                
      $0303: write(f, 'WM_CLEAR');                
      $0304: write(f, 'WM_UNDO');                 
      $0305: write(f, 'WM_RENDERFORMAT');         
      $0306: write(f, 'WM_RENDERALLFORMATS');     
      $0307: write(f, 'WM_DESTROYCLIPBOARD');     
      $0308: write(f, 'WM_DRAWCLIPBOARD');        
      $0309: write(f, 'WM_PAINTCLIPBOARD');       
      $030A: write(f, 'WM_VSCROLLCLIPBOARD');     
      $030B: write(f, 'WM_SIZECLIPBOARD');        
      $030C: write(f, 'WM_ASKCBFORMATNAME');      
      $030D: write(f, 'WM_CHANGECBCHAIN');        
      $030E: write(f, 'WM_HSCROLLCLIPBOARD');     
      $030F: write(f, 'WM_QUERYNEWPALETTE');      
      $0310: write(f, 'WM_PALETTEISCHANGING');    
      $0311: write(f, 'WM_PALETTECHANGED');       
      $0312: write(f, 'WM_HOTKEY');               
      $0380: write(f, 'WM_PENWINFIRST');          
      $038F: write(f, 'WM_PENWINLAST');           

   end

end;

{ function places a string in dynamic storage }

function str(view s: string): pstring;

var p: pstring;

begin

   new(p, max(s));
   p^ := s;
   str := p

end;

{******************************************************************************

Create find dialog

******************************************************************************}

procedure finddialog(hwnd: sc_hwnd);

var r: integer; { result }

begin

   new(fs); { get a new finder string }
   fr.lstructsize := sc_findreplace_len; { set size }
   fr.hwndowner := hwnd; { set owner }
   fr.hinstance := 0; { no instance }
   { set flags }
   fr.flags := sc_fr_hideupdown or sc_fr_hidematchcase or sc_fr_hidewholeword;
   fr.lpstrfindwhat := fs; { place finder string }
   fr.lpstrreplacewith := nil; { set no replacement string }
   fr.wfindwhatlen := sc_findreplace_str_len; { set length }
   fr.wreplacewithlen := 0; { set null replacement string }
   fr.lcustdata := 0; { clear these }
   fr.lpfnhook := nil;
   fr.lptemplatename := nil;
   fndrepmsg := sc_registerwindowmessage('commdlg_FindReplace');
   r := sc_findtext(fr) { perform dialog }

end;

{******************************************************************************

Window procedure

******************************************************************************}

function wndproc(hwnd, imsg, wparam, lparam: integer): integer;

var hdc:  integer;  { handle to device context }
    ps:   sc_paint; { paint structure }
    rect: sc_rect;  { rectangle holder }
    b:    boolean;     { result holder }
    r:    integer;     { result holder }

begin

   write('handle: ');
   prthex(output, hwnd, 8); 
   write(' message: '); 
   prtmsgstr(output, imsg); 
   write(' wparam: '); 
   prthex(output, wparam, 8); 
   write(' lparam: ');
   prthex(output, lparam, 8);
   writeln;
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

   end else if imsg = $400 then begin

;writeln('Wndproc: received find message');

   end else r := sc_defwindowproc(hwnd, imsg, wparam, lparam);

   wndproc := r

end;

{******************************************************************************

Window procedure for thread

******************************************************************************}

function wndprocthread(hwnd, imsg, wparam, lparam: integer): integer;

var r: integer; { result holder }
    b: boolean;

begin

   if imsg = sc_wm_create then begin

      r := 0

   end else if imsg = sc_wm_destroy then begin

      sc_postquitmessage(0);
      r := 0

   end else if imsg = fndrepmsg then begin

      b := sc_postmessage(winhan, $400, 0, 0);
      r := 0

   end else r := sc_defwindowproc(hwnd, imsg, wparam, lparam);

   wndprocthread := r

end;

{******************************************************************************

Window passthrough handler task

Executed as another task, all of the windows funnel their input queues through
here.

******************************************************************************}

procedure passthrough;

var msg: sc_msg;
    wc:  sc_wndclassa; { windows class structure }
    b:   boolean; { function return }
    r:   integer; { result holder }
    v:   integer;
    passwin: integer;

begin

   { create dummy class for message handling }
   wc.style      := 0;
   wc.wndproc    := sc_wndprocadr(wndprocthread);
   wc.clsextra   := 0;
   wc.wndextra   := 0;
   wc.instance   := sc_getmodulehandle_n;
   wc.icon       := 0;
   wc.cursor     := 0;
   wc.background := 0;
   wc.menuname   := nil;
   wc.classname  := str('passthrough');
   { register that class }
   b := sc_registerclass(wc);
   { create the window }
   v := 2; { construct sc_hwnd_message, $fffffffd }
   v := not v;
   passwin := sc_createwindow('passthrough', '', 0, 0, 0, 0, 0,
                              v {sc_hwnd_message}, 0, sc_getmodulehandle_n);
   { flag subthread has started up }
   threadstart := true; { set we started }
   finddialog(passwin);
   { message handling loop }
   while sc_getmessage(msg, 0, 0, 0) <> 0 do begin { not a quit message }

      b := sc_translatemessage(msg); { translate keyboard events }
      r := sc_dispatchmessage(msg)

   end

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
   winhan := sc_createwindow(
            'stdwin', 'Hello', sc_ws_overlappedwindow,
            v{sc_cw_usedefault}, v{sc_cw_usedefault}, 
            v{sc_cw_usedefault}, v{sc_cw_usedefault},
            0, 0, sc_getmodulehandle_n
         );
;writeln('main: winhan: ', winhan:1);
   { present the window }
   b := sc_showwindow(winhan, sc_sw_showdefault);
   { send first paint message }
   b := sc_updatewindow(winhan);
   { interlock to make sure that thread starts before we continue }
   threadstart := false;
   r := sc_createthread_nn(0, passthrough, 0, threadid);
;writeln('createthread returns: ', r:1);
   { message handling loop. Since messages are reflected, we do all
     message handling here instead of sending them on to the windows
     procedure as normal }
   while sc_getmessage(msg, 0, 0, 0) <> 0 do begin { not a quit message }

      b := sc_translatemessage(msg); { translate keyboard events }
      r := sc_dispatchmessage(msg);

   end                  

end. { main program }

   