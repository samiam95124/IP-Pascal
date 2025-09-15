{******************************************************************************
*                                                                             *
*                             TIME/DATE PROGRAM                               *
*                                                                             *
*                       Copyright 1996 S. A. Moore                            *
*                                                                             *
* Example program to print current time and date using extlib functions.      *
*                                                                             *
******************************************************************************}

program tim(output);

uses extlib;

var t: integer; { time holder }

begin

   t := time; { get the current time }
   writedate(output, t); { print date }
   write(' ');
   writetime(output, t) { print time }

end.
