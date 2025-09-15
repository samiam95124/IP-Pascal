{*******************************************************************************
*                                                                              *
*                              WINDOWS VERSION LOCK                            *
*                                                                              *
* This module verifies that the windows version is for NT or better.           *
*                                                                              *
*******************************************************************************}

module verlock;

uses windows,
     syslib;

label 99;

private

procedure fail;

begin

   ss_wrterr('This software requires Windows NT or better');
   goto 99

end;

procedure verver;

var ver: integer;

begin

   ver := sc_getversion; { get the windows version }
   if ver < 0 then fail { anything not NT has bit set }

end;

begin

   verver { verify version }

end;

begin

   99: { abort program }

end.