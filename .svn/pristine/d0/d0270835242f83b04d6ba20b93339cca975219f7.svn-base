program testw;

uses windows;

var wc:         sc_wndclassa; { windows class structure }
    winhan:     integer;      { window handle }
    grphan:     integer;
    msg:        sc_msg;       { message holder }
    r:          integer;      { result holder }
    b:          boolean;      { boolean result holder }
    v:          integer;

{******************************************************************************

Function places a string in dynamic storage

******************************************************************************}

function str(view s: string): pstring;

var p: pstring;

begin

   new(p, max(s));
   p^ := s;
   str := p

end;

{******************************************************************************

Print string to output

******************************************************************************}

procedure prtstr(view s: string);

var hdl: integer; { output file handle }
    gp:  gbtptr; { string to output }
    fr:  integer; { function result }
    i:   integer;

begin

   hdl := sc_getstdhandle(sc_std_error_handle);
   new(gp, max(s));
   for i := 1 to max(s) do gp^[i] := ord(s[i]);
   fr := sc__lwrite(hdl, gp^);
   dispose(gp)

end;

{******************************************************************************

Print single character to output

Writes a character directly to the serial output file. This is useful for
diagnostics, since it will work under any thread or callback.

******************************************************************************}

procedure prtchr(c: char);

var hdl: integer; { output file handle }
    gp:  gbtptr; { string to output }
    fr:  integer; { function result }

begin

   hdl := sc_getstdhandle(sc_std_error_handle);
   new(gp, 1);
   gp^[1] := ord(c);
   fr := sc__lwrite(hdl, gp^);
   dispose(gp)

end;

{******************************************************************************

Print hex number

Prints a hex number, with the given field. Used for diagnostics, and can be
commented out.

******************************************************************************}

procedure prthex(w:  integer;  { value to print }
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
      prtchr(chr(v)) { output }

   end

end;

{******************************************************************************

Print message string

This routine is for diagnostic use. Comment it out on production builds.

******************************************************************************}

procedure prtmsgstr(mn: integer);

begin

   prthex(mn, 4);
   prtstr(': ');
   if (mn >= $800) and (mn <= $bfff) then prtstr('User message')
   else if (mn >= $c000) and (mn <= $ffff) then prtstr('Registered message')
   else case mn of

      $0000: prtstr('WM_NULL');                 
      $0001: prtstr('WM_CREATE');               
      $0002: prtstr('WM_DESTROY');              
      $0003: prtstr('WM_MOVE');                 
      $0005: prtstr('WM_SIZE');                 
      $0006: prtstr('WM_ACTIVATE');             
      $0007: prtstr('WM_SETFOCUS');             
      $0008: prtstr('WM_KILLFOCUS');            
      $000A: prtstr('WM_ENABLE');               
      $000B: prtstr('WM_SETREDRAW');            
      $000C: prtstr('WM_SETTEXT');              
      $000D: prtstr('WM_GETTEXT');              
      $000E: prtstr('WM_GETTEXTLENGTH');        
      $000F: prtstr('WM_PAINT');                
      $0010: prtstr('WM_CLOSE');                
      $0011: prtstr('WM_QUERYENDSESSION');      
      $0012: prtstr('WM_QUIT');                 
      $0013: prtstr('WM_QUERYOPEN');            
      $0014: prtstr('WM_ERASEBKGND');           
      $0015: prtstr('WM_SYSCOLORCHANGE');       
      $0016: prtstr('WM_ENDSESSION');           
      $0018: prtstr('WM_SHOWWINDOW');           
      $001A: prtstr('WM_WININICHANGE');         
      $001B: prtstr('WM_DEVMODECHANGE');        
      $001C: prtstr('WM_ACTIVATEAPP');          
      $001D: prtstr('WM_FONTCHANGE');           
      $001E: prtstr('WM_TIMECHANGE');           
      $001F: prtstr('WM_CANCELMODE');           
      $0020: prtstr('WM_SETCURSOR');            
      $0021: prtstr('WM_MOUSEACTIVATE');        
      $0022: prtstr('WM_CHILDACTIVATE');        
      $0023: prtstr('WM_QUEUESYNC');            
      $0024: prtstr('WM_GETMINMAXINFO');        
      $0026: prtstr('WM_PAINTICON');            
      $0027: prtstr('WM_ICONERASEBKGND');       
      $0028: prtstr('WM_NEXTDLGCTL');           
      $002A: prtstr('WM_SPOOLERSTATUS');        
      $002B: prtstr('WM_DRAWITEM');             
      $002C: prtstr('WM_MEASUREITEM');          
      $002D: prtstr('WM_DELETEITEM');           
      $002E: prtstr('WM_VKEYTOITEM');           
      $002F: prtstr('WM_CHARTOITEM');           
      $0030: prtstr('WM_SETFONT');              
      $0031: prtstr('WM_GETFONT');              
      $0032: prtstr('WM_SETHOTKEY');            
      $0033: prtstr('WM_GETHOTKEY');            
      $0037: prtstr('WM_QUERYDRAGICON');        
      $0039: prtstr('WM_COMPAREITEM');          
      $0041: prtstr('WM_COMPACTING');           
      $0042: prtstr('WM_OTHERWINDOWCREATED');   
      $0043: prtstr('WM_OTHERWINDOWDESTROYED'); 
      $0044: prtstr('WM_COMMNOTIFY');           
      $0045: prtstr('WM_HOTKEYEVENT');          
      $0046: prtstr('WM_WINDOWPOSCHANGING');    
      $0047: prtstr('WM_WINDOWPOSCHANGED');     
      $0048: prtstr('WM_POWER');                
      $004A: prtstr('WM_COPYDATA');             
      $004B: prtstr('WM_CANCELJOURNAL');        
      $0081: prtstr('WM_NCCREATE');             
      $0082: prtstr('WM_NCDESTROY');            
      $0083: prtstr('WM_NCCALCSIZE');           
      $0084: prtstr('WM_NCHITTEST');            
      $0085: prtstr('WM_NCPAINT');              
      $0086: prtstr('WM_NCACTIVATE');           
      $0087: prtstr('WM_GETDLGCODE');           
      $00A0: prtstr('WM_NCMOUSEMOVE');          
      $00A1: prtstr('WM_NCLBUTTONDOWN');        
      $00A2: prtstr('WM_NCLBUTTONUP');          
      $00A3: prtstr('WM_NCLBUTTONDBLCLK');      
      $00A4: prtstr('WM_NCRBUTTONDOWN');        
      $00A5: prtstr('WM_NCRBUTTONUP');          
      $00A6: prtstr('WM_NCRBUTTONDBLCLK');      
      $00A7: prtstr('WM_NCMBUTTONDOWN');        
      $00A8: prtstr('WM_NCMBUTTONUP');          
      $00A9: prtstr('WM_NCMBUTTONDBLCLK');      
      {$0100: prtstr('WM_KEYFIRST');}             
      $0100: prtstr('WM_KEYDOWN');
      $0101: prtstr('WM_KEYUP');                
      $0102: prtstr('WM_CHAR');                 
      $0103: prtstr('WM_DEADCHAR');             
      $0104: prtstr('WM_SYSKEYDOWN');           
      $0105: prtstr('WM_SYSKEYUP');             
      $0106: prtstr('WM_SYSCHAR');              
      $0107: prtstr('WM_SYSDEADCHAR');          
      $0108: prtstr('WM_KEYLAST');              
      $0110: prtstr('WM_INITDIALOG');           
      $0111: prtstr('WM_COMMAND');              
      $0112: prtstr('WM_SYSCOMMAND');           
      $0113: prtstr('WM_TIMER');                
      $0114: prtstr('WM_HSCROLL');              
      $0115: prtstr('WM_VSCROLL');              
      $0116: prtstr('WM_INITMENU');             
      $0117: prtstr('WM_INITMENUPOPUP');        
      $011F: prtstr('WM_MENUSELECT');           
      $0120: prtstr('WM_MENUCHAR');             
      $0121: prtstr('WM_ENTERIDLE');            
      $0132: prtstr('WM_CTLCOLORMSGBOX');       
      $0133: prtstr('WM_CTLCOLOREDIT');         
      $0134: prtstr('WM_CTLCOLORLISTBOX');      
      $0135: prtstr('WM_CTLCOLORBTN');          
      $0136: prtstr('WM_CTLCOLORDLG');          
      $0137: prtstr('WM_CTLCOLORSCROLLBAR');    
      $0138: prtstr('WM_CTLCOLORSTATIC');       
      $0200: prtstr('WM_MOUSEFIRST');           
      { $0200: prtstr('WM_MOUSEMOVE'); }
      $0201: prtstr('WM_LBUTTONDOWN');          
      $0202: prtstr('WM_LBUTTONUP');            
      $0203: prtstr('WM_LBUTTONDBLCLK');        
      $0204: prtstr('WM_RBUTTONDOWN');          
      $0205: prtstr('WM_RBUTTONUP');            
      $0206: prtstr('WM_RBUTTONDBLCLK');        
      $0207: prtstr('WM_MBUTTONDOWN');          
      $0208: prtstr('WM_MBUTTONUP');            
      $0209: prtstr('WM_MBUTTONDBLCLK');        
      { $0209: prtstr('WM_MOUSELAST'); }           
      $0210: prtstr('WM_PARENTNOTIFY');         
      $0211: prtstr('WM_ENTERMENULOOP');        
      $0212: prtstr('WM_EXITMENULOOP');         
      $0220: prtstr('WM_MDICREATE');            
      $0221: prtstr('WM_MDIDESTROY');           
      $0222: prtstr('WM_MDIACTIVATE');          
      $0223: prtstr('WM_MDIRESTORE');           
      $0224: prtstr('WM_MDINEXT');              
      $0225: prtstr('WM_MDIMAXIMIZE');          
      $0226: prtstr('WM_MDITILE');              
      $0227: prtstr('WM_MDICASCADE');           
      $0228: prtstr('WM_MDIICONARRANGE');       
      $0229: prtstr('WM_MDIGETACTIVE');         
      $0230: prtstr('WM_MDISETMENU');           
      $0231: prtstr('WM_ENTERSIZEMOVE');           
      $0232: prtstr('WM_EXITSIZEMOVE');           
      $0233: prtstr('WM_DROPFILES');            
      $0234: prtstr('WM_MDIREFRESHMENU');       
      $0300: prtstr('WM_CUT');                  
      $0301: prtstr('WM_COPY');                 
      $0302: prtstr('WM_PASTE');                
      $0303: prtstr('WM_CLEAR');                
      $0304: prtstr('WM_UNDO');                 
      $0305: prtstr('WM_RENDERFORMAT');         
      $0306: prtstr('WM_RENDERALLFORMATS');     
      $0307: prtstr('WM_DESTROYCLIPBOARD');     
      $0308: prtstr('WM_DRAWCLIPBOARD');        
      $0309: prtstr('WM_PAINTCLIPBOARD');       
      $030A: prtstr('WM_VSCROLLCLIPBOARD');     
      $030B: prtstr('WM_SIZECLIPBOARD');        
      $030C: prtstr('WM_ASKCBFORMATNAME');      
      $030D: prtstr('WM_CHANGECBCHAIN');        
      $030E: prtstr('WM_HSCROLLCLIPBOARD');     
      $030F: prtstr('WM_QUERYNEWPALETTE');      
      $0310: prtstr('WM_PALETTEISCHANGING');    
      $0311: prtstr('WM_PALETTECHANGED');       
      $0312: prtstr('WM_HOTKEY');               
      $0380: prtstr('WM_PENWINFIRST');          
      $038F: prtstr('WM_PENWINLAST');           
      $03A0: prtstr('MM_JOY1MOVE');
      $03A1: prtstr('MM_JOY2MOVE');
      $03A2: prtstr('MM_JOY1ZMOVE');
      $03A3: prtstr('MM_JOY2ZMOVE');
      $03B5: prtstr('MM_JOY1BUTTONDOWN');
      $03B6: prtstr('MM_JOY2BUTTONDOWN');
      $03B7: prtstr('MM_JOY1BUTTONUP');
      $03B8: prtstr('MM_JOY2BUTTONUP');
      else prtstr('???')

   end

end;

{******************************************************************************

Print unpacked message diagnostic

This routine is for diagnostic use. Comment it out on production builds.

******************************************************************************}

procedure prtmsgu(hwnd, imsg, wparam, lparam: integer);

begin

   prtstr('handle: ');
   prthex(hwnd, 8); 
   prtstr(' message: '); 
   prtmsgstr(imsg); 
   prtstr(' wparam: '); 
   prthex(wparam, 8); 
   prtstr(' lparam: ');
   prthex(lparam, 8);
   prtstr('\cr\lf')

end;

{******************************************************************************

Window procedure for thread

******************************************************************************}

function wndproc(hwnd, imsg, wparam, lparam: integer): integer;

var hdc:  integer;  { handle to device context }
    ps:   sc_paint; { paint structure }
    rect: sc_rect;  { rectangle holder }
    b:    boolean;  { result holder }
    r:    integer;  { result holder }

begin

{;prtmsgu(hwnd, imsg, wparam, lparam);}
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
   winhan := sc_createwindow(
            'stdwin', 'Hello', sc_ws_overlappedwindow or sc_ws_clipchildren,
            400, 400, 
            400, 400,
            0, 0, sc_getmodulehandle_n
         );
   { present the window }
   b := sc_showwindow(winhan, sc_sw_showdefault);
   { send first paint message }
   b := sc_updatewindow(winhan);

   { create group box }
   grphan := sc_createwindow(
            'button', 'This is a group box', 
            sc_ws_child or sc_ws_visible or sc_bs_groupbox,
            100, 100, 
            100, 100,
            winhan, 1, sc_getmodulehandle_n
         );
          
   { message handling loop }
   while sc_getmessage(msg, 0, 0, 0) <> 0 do begin { not a quit message }

      b := sc_translatemessage(msg); { translate keyboard events }
      r := sc_dispatchmessage(msg)

   end

end. { main program }

   