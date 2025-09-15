{******************************************************************************
*                                                                             *
*                           CONVERT WINDOWS TIME                              *
*                                                                             *
*                            Copyright (C) 1996                               *
*                                                                             *
*                               S. A. MOORE                                   *
*                                                                             *
* Converts the windows 64 bit time format to an integer seconds format. This  *
* routine is in assembly because we don't have 64 bit capability in our       *
* Pascal.                                                                     *
* The seconds time format is a count, in seconds, of the current time from or *
* to the beginning of the year 2000. As this program is written, that is a    *
* negative number which is counting up to 0. After the year 2000, it will be  *
* counting up.                                                                *
*                                                                             *
******************************************************************************}

module cvttim;

uses windows;

procedure filetimetoseconds(view ft: sc_filetime; { file time to convert }
                            var  t:  integer);    { resulting seconds time }
          external;

begin
end.
