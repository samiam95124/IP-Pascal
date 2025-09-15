{******************************************************************************
*                                                                             *
*                            MEMORY MANAGER                                   *
*                                                                             *
*                     COPYRIGHT (C) 2007 S. A. MOORE                          *
*                                                                             *
* Implements a dynamic space heap. The heap is presumed in this model to      *
* start at _vend and continue until the stack pointer. We preserve a pad of   *
* 4kb between the heap top and the stack bottom.                              *
*                                                                             *
******************************************************************************}

module memman;

uses stddef; { some standard defines }

procedure memman_getspace(var bp: gbtptr; ln: integer); external;
procedure memman_putspace(bp: gbtptr); external;

begin
end.