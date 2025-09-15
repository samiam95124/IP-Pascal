{******************************************************************************
*                                                                             *
* CRT UNIT EMULATION LIBRARY                                                  *
*                                                                             *
* Emulates the CRT unit of TPC.                                               *
*                                                                             *
* Implements the following functions:                                         *
* procedure AssignCrt(var F: Text);                                           *
* procedure ClrEol;                                                           *
* procedure ClrScr;                                                           *
* procedure Delay(MS: Word);                                                  *
* procedure DelLine;                                                          *
* procedure GotoXY(X,Y: Byte);                                                *
* procedure HighVideo;                                                        *
* procedure InsLine;                                                          *
* function  KeyPressed: Boolean;                                              *
* procedure LowVideo;                                                         *
* procedure NormVideo;                                                        *
* procedure NoSound;                                                          *
* function  ReadKey: Char;                                                    *
* procedure Sound(Hz: Word);                                                  *
* procedure TextBackground(Color: Byte);                                      *
* procedure TextColor(Color: Byte);                                           *
* procedure TextMode(Mode: Integer);                                          *
* function  WhereX: Byte;                                                     *
* function  WhereY: Byte;                                                     *
* procedure Window(X1,Y1,X2,Y2: Byte);                                        *
* var       Checkbreak: boolean;                                              *
* var       CheckSnow: boolean;                                               *
* var       directvideo: boolean;                                             *
*                                                                             *
* We implement the basics. For many of the features, an overload mode must be *
* implemented.                                                                *
*                                                                             *
******************************************************************************}

module crt(input, output);

uses trmlib;

const

   crt_Black        = 0;
   crt_Blue         = 1;
   crt_Green        = 2;
   crt_Cyan         = 3;
   crt_Red          = 4;
   crt_Magenta      = 5;
   crt_Brown        = 6;
   crt_LightGray    = 7;
   crt_DarkGray     = 8;
   crt_LightBlue    = 9;
   crt_LightGreen   = 10;
   crt_LightCyan    = 11;
   crt_LightRed     = 12;
   crt_LightMagenta = 13;
   crt_Yellow       = 14;
   crt_White        = 15;

var windmin: integer; { restricted window minimum in packed format }
    windmax: integer; { restricted window maximum in packed format }

procedure assigncrt(var f: text); begin end;
procedure clreol; begin end;
procedure clrscr; begin end;
procedure delay(t: integer); begin end;
procedure delline; begin end;
procedure gotoxy(x, y: integer); begin end;
procedure highvideo; begin end;
procedure insline; begin end;
function keypressed: boolean; begin end;
procedure lowvideo; begin end;
procedure normvideo; begin end;
procedure nosound; begin end;
function readkey: char; begin end;
procedure sound(s: integer); begin end;
procedure textbackground(c: integer); begin end;
procedure textcolor(c: integer); begin end;
procedure textmode(m: integer); begin end;
function wherex: integer; begin end;
function wherey: integer; begin end;
procedure window(x1, y1, x2, y2: integer); begin end;

begin
end.

