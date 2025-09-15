{******************************************************************************
*                                                                             *
*                          SYSLIB OVERRIDE HEADER                             *
*                                                                             *
*                            2001/3 S. A. Moore                               *
*                                                                             *
* Provides headers for the syslib override services. There are three types    *
* of calls in the override module. The base call executes the top hook        *
* handler of the override module, which by default is initalized to the       *
* actual base call. The override call hooks the base call, saving the current *
* call to a user supplied variable, and then replacing the vector with a      *
* passed call. The old call is used to call the previous base call, as saved. *
*                                                                             *
******************************************************************************}

module sysovr;

uses stddef,  { some standard defines }
     wrapper, { system calls wrappers }
     gettgp;  { converts fixed array to pointer }

const ss_maxhdl = 100; { maximum number of file handles }

type

   ss_pp = ^integer; { generic pointer }
   ss_filhdl = 0..ss_maxhdl; { file handle number }

{ base calls }

procedure ss_openread(var fn: ss_filhdl; view nm: string); begin end;
procedure ss_openwrite(var fn: ss_filhdl; view nm: string); begin end;
procedure ss_close(fn: ss_filhdl); begin end;
procedure ss_read(fn: ss_filhdl; var ba: bytarr); begin end;
procedure ss_write(fn: ss_filhdl; view ba: bytarr); begin end;
procedure ss_position(fn: ss_filhdl; p: integer); begin end;
function ss_location(fn: ss_filhdl): integer; begin end;
function ss_length(fn: ss_filhdl): integer; begin end;
function ss_eof(fn: ss_filhdl): boolean; begin end;
procedure ss_delete(view nm: string); begin end;
procedure ss_change(view dn, sn: string); begin end;
function ss_exists(view nm: string): boolean; begin end;
procedure ss_getspace(var bp: gbtptr; ln: integer); begin end;
procedure ss_putspace(bp: gbtptr); begin end;
function ss_alteol: boolean; begin end;
procedure ss_wrterr(view es: string); begin end;

{ override calls }

procedure ss_ovr_openread(procedure bp(var fn: ss_filhdl; view nm: string); var st: ss_pp); begin end;
procedure ss_ovr_openwrite(procedure bp(var fn: ss_filhdl; view nm: string); var st: ss_pp); begin end;
procedure ss_ovr_close(procedure bp(fn: ss_filhdl); var st: ss_pp); begin end;
procedure ss_ovr_read(procedure bp(fn: ss_filhdl; var ba: bytarr); var st: ss_pp); begin end;
procedure ss_ovr_write(procedure bp(fn: ss_filhdl; view ba: bytarr); var st: ss_pp); begin end;
procedure ss_ovr_position(procedure bp(fn: ss_filhdl; p: integer); var st: ss_pp); begin end;
procedure ss_ovr_location(function bp(fn: ss_filhdl): integer; var st: ss_pp); begin end;
procedure ss_ovr_length(function bp(fn: ss_filhdl): integer; var st: ss_pp); begin end;
procedure ss_ovr_eof(function bp(fn: ss_filhdl): boolean; var st: ss_pp); begin end;
procedure ss_ovr_delete(procedure bp(view nm: string); var st: ss_pp); begin end;
procedure ss_ovr_change(procedure bp(view dn, sn: string); var st: ss_pp); begin end;
procedure ss_ovr_exists(function bp(view nm: string): boolean; var st: ss_pp); begin end;
procedure ss_ovr_getspace(procedure bp(var bp: gbtptr; ln: integer); var st: ss_pp); begin end;
procedure ss_ovr_putspace(procedure bp(bp: gbtptr); var st: ss_pp); begin end;
procedure ss_ovr_alteol(function bp: boolean; var st: ss_pp); begin end;
procedure ss_ovr_wrterr(procedure bp(view es: string); var st: ss_pp); begin end;

{ passdown calls }

procedure ss_old_openread(var fn: ss_filhdl; view nm: string; st: ss_pp); begin end;
procedure ss_old_openwrite(var fn: ss_filhdl; view nm: string; st: ss_pp); begin end;
procedure ss_old_close(fn: ss_filhdl; st: ss_pp); begin end;
procedure ss_old_read(fn: ss_filhdl; var ba: bytarr; st: ss_pp); begin end;
procedure ss_old_write(fn: ss_filhdl; view ba: bytarr; st: ss_pp); begin end;
procedure ss_old_position(fn: ss_filhdl; p: integer; st: ss_pp); begin end;
function ss_old_location(fn: ss_filhdl; st: ss_pp): integer; begin end;
function ss_old_length(fn: ss_filhdl; st: ss_pp): integer; begin end;
function ss_old_eof(fn: ss_filhdl; st: ss_pp): boolean; begin end;
procedure ss_old_delete(view nm: string; st: ss_pp); begin end;
procedure ss_old_change(view dn, sn: string; st: ss_pp); begin end;
function ss_old_exists(view nm: string; st: ss_pp): boolean; begin end;
procedure ss_old_getspace(var bp: gbtptr; ln: integer; st: ss_pp); begin end;
procedure ss_old_putspace(bp: gbtptr; st: ss_pp); begin end;
function ss_old_alteol(st: ss_pp): boolean; begin end;
procedure ss_old_wrterr(view es: string; st: ss_pp); begin end;

begin
end.
