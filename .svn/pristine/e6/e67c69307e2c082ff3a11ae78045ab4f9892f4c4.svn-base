{*******************************************************************************

Windows.pas special definition file

Contains special definitions used in the windows.pas file.

*******************************************************************************}

module spcdef;

uses stddef,
     windows;

type

sc_spcdef_evsptr = ^sc_spcdef_evsrec;
sc_spcdef_evsrec = record

   str: pstring;
   next: sc_spcdef_evsptr

end;
sc_spcdef_intarr = array of integer;

{ windows class record }

sc_spcdef_wndclassa = record

   style:         integer;
   lpfnWndProc:   integer; { routine pointer }
   cbClsExtra:    integer;
   cbWndExtra:    integer;
   hInstance:     { sc_hinstance } integer;
   hIcon:         integer;
   hCursor:       integer;
   hbrBackground: integer;
   lpszMenuName:  pstring;
   lpszClassName: pstring

end;

procedure sc_crkmsg(m: integer; var h, l: integer); begin end;
function sc_wndprocadr(function wndproc(hwnd, imsg, wparam, lparam: integer)
   : integer): integer {sc_wndproc}; begin end;

begin
end.