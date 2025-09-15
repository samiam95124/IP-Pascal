{******************************************************************************
*                                                                             *
*                      GET TAGGED POINTER TO FIXED ARRAY                      *
*                                                                             *
*                            95/9 S. A. Moore                                 *
*                                                                             *
* This module exists only to isolate a questionable routine that forms a      *
* pointer to a fixed array of bytes.                                          *
* Actually, pointers to fixed objects are not completely evil, but there is   *
* a reason that capability is not in the language. It is allways possible for *
* the fixed object to go out of scope with a pointer still held.              *
*                                                                             *
******************************************************************************}

module gettgp;

uses stddef;  { some standard defines }

{ return tagged pointer }

function rettgp(var ba: bytarr) { fixed storage array }
                : gbtptr;       { tagged pointer to same } 
         external;

begin
end.
