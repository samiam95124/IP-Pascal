{******************************************************************************
*                                                                             *
*                           STANDARD DEFINITIONS                              *
*                                                                             *
*                              95/9 S. A. Moore                               *
*                                                                             *
* Contains some standard definitions widely required in Pascal.               *
*                                                                             *
******************************************************************************}

module stddef;

type

   byte   = 0..255; { type of byte }
   bytptr = ^byte; { pointer to byte }
   bytarr = array of byte; { general byte array }
   gbtptr = ^bytarr; { pointer to general byte array }
   bytfil = file of byte; { file of bytes }
   string = packed array of char; { general string }
   pstring = ^string; { pointer to string }
   chrset = set of char; { character set }

begin
end.



