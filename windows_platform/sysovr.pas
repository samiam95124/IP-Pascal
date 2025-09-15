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
     windows, { system calls wrappers }
     gettgp;  { converts fixed array to pointer }

const ss_maxhdl = 100; { maximum number of file handles }
      ss_maxthd = 100; { maximum number of active threads }
      ss_maxlck = 100; { maximum number of thread locks }
      ss_maxsig = 100; { maximum number of signals }

type

   ss_pp = ^integer; { generic pointer }
   ss_filhdl = 0..ss_maxhdl; { file handle number }

{ base calls }

procedure ss_alias(fn, fa: ss_filhdl); external;
procedure ss_resolve(view nm: string; var fs: pstring); external;
function  ss_sysfil(view nm: string): boolean; external;
procedure ss_openread(var fn: ss_filhdl; view nm: string); external;
procedure ss_openwrite(var fn: ss_filhdl; view nm: string); external;
procedure ss_openupdate(var fn: ss_filhdl; view nm: string); external;
procedure ss_close(fn: ss_filhdl); external;
procedure ss_read(fn: ss_filhdl; var ba: bytarr); external;
procedure ss_write(fn: ss_filhdl; view ba: bytarr); external;
procedure ss_position(fn: ss_filhdl; p: integer); external;
function  ss_location(fn: ss_filhdl): integer; external;
function  ss_length(fn: ss_filhdl): integer; external;
function  ss_eof(fn: ss_filhdl): boolean; external;
procedure ss_delete(view nm: string); external;
procedure ss_change(view dn, sn: string); external;
function  ss_exists(view nm: string): boolean; external;
procedure ss_getspace(var bp: gbtptr; ln: integer); external;
procedure ss_putspace(bp: gbtptr); external;
function  ss_alteol: boolean; external;
procedure ss_wrterr(view es: string); external;
procedure ss_newthread(addr: integer; var threadid: integer); external;
procedure ss_killthread(threadid: integer); external;
procedure ss_signal(var sid: integer); external;
procedure ss_signalone(var sid: integer); external;
procedure ss_wait(lid: integer; var sid: integer); external;
procedure ss_newlock(var id: integer); external;
procedure ss_displock(id: integer); external;
procedure ss_lock(id: integer); external;
procedure ss_unlock(id: integer); external;

{ override calls }

procedure ss_ovr_alias(procedure bp(fn, fa: ss_filhdl); var st: ss_pp); external;
procedure ss_ovr_resolve(procedure bp(view nm: string; var fs: pstring); var st: ss_pp); external;
procedure ss_ovr_sysfil(function bp(view nm: string): boolean; var st: ss_pp); external;
procedure ss_ovr_openread(procedure bp(var fn: ss_filhdl; view nm: string); var st: ss_pp); external;
procedure ss_ovr_openwrite(procedure bp(var fn: ss_filhdl; view nm: string); var st: ss_pp); external;
procedure ss_ovr_openupdate(procedure bp(var fn: ss_filhdl; view nm: string); var st: ss_pp); external;
procedure ss_ovr_close(procedure bp(fn: ss_filhdl); var st: ss_pp); external;
procedure ss_ovr_read(procedure bp(fn: ss_filhdl; var ba: bytarr); var st: ss_pp); external;
procedure ss_ovr_write(procedure bp(fn: ss_filhdl; view ba: bytarr); var st: ss_pp); external;
procedure ss_ovr_position(procedure bp(fn: ss_filhdl; p: integer); var st: ss_pp); external;
procedure ss_ovr_location(function bp(fn: ss_filhdl): integer; var st: ss_pp); external;
procedure ss_ovr_length(function bp(fn: ss_filhdl): integer; var st: ss_pp); external;
procedure ss_ovr_eof(function bp(fn: ss_filhdl): boolean; var st: ss_pp); external;
procedure ss_ovr_delete(procedure bp(view nm: string); var st: ss_pp); external;
procedure ss_ovr_change(procedure bp(view dn, sn: string); var st: ss_pp); external;
procedure ss_ovr_exists(function bp(view nm: string): boolean; var st: ss_pp); external;
procedure ss_ovr_getspace(procedure bp(var bp: gbtptr; ln: integer); var st: ss_pp); external;
procedure ss_ovr_putspace(procedure bp(bp: gbtptr); var st: ss_pp); external;
procedure ss_ovr_alteol(function bp: boolean; var st: ss_pp); external;
procedure ss_ovr_wrterr(procedure bp(view es: string); var st: ss_pp); external;
procedure ss_ovr_newthread(procedure bp(addr: integer; var threadid: integer); var st: ss_pp); external;
procedure ss_ovr_killthread(procedure bp(threadid: integer); var st: ss_pp); external;
procedure ss_ovr_signal(procedure bp(sid: integer); var st: ss_pp); external;
procedure ss_ovr_signalone(procedure bp(sid: integer); var st: ss_pp); external;
procedure ss_ovr_wait(procedure bp(lid: integer; sid: integer); var st: ss_pp); external;
procedure ss_ovr_newlock(procedure bp(var id: integer); var st: ss_pp); external;
procedure ss_ovr_displock(procedure bp(id: integer); var st: ss_pp); external;
procedure ss_ovr_lock(procedure bp(id: integer); var st: ss_pp); external;
procedure ss_ovr_unlock(procedure bp(id: integer); var st: ss_pp); external;

{ passdown calls }

procedure ss_old_alias(fn, fa: ss_filhdl; st: ss_pp); external;
procedure ss_old_resolve(view nm: string; var fs: pstring; st: ss_pp); external;
function  ss_old_sysfil(view nm: string; st: ss_pp): boolean; external;
procedure ss_old_openread(var fn: ss_filhdl; view nm: string; st: ss_pp); external;
procedure ss_old_openwrite(var fn: ss_filhdl; view nm: string; st: ss_pp); external;
procedure ss_old_openupdate(var fn: ss_filhdl; view nm: string; st: ss_pp); external;
procedure ss_old_close(fn: ss_filhdl; st: ss_pp); external;
procedure ss_old_read(fn: ss_filhdl; var ba: bytarr; st: ss_pp); external;
procedure ss_old_write(fn: ss_filhdl; view ba: bytarr; st: ss_pp); external;
procedure ss_old_position(fn: ss_filhdl; p: integer; st: ss_pp); external;
function  ss_old_location(fn: ss_filhdl; st: ss_pp): integer; external;
function  ss_old_length(fn: ss_filhdl; st: ss_pp): integer; external;
function  ss_old_eof(fn: ss_filhdl; st: ss_pp): boolean; external;
procedure ss_old_delete(view nm: string; st: ss_pp); external;
procedure ss_old_change(view dn, sn: string; st: ss_pp); external;
function  ss_old_exists(view nm: string; st: ss_pp): boolean; external;
procedure ss_old_getspace(var bp: gbtptr; ln: integer; st: ss_pp); external;
procedure ss_old_putspace(bp: gbtptr; st: ss_pp); external;
function  ss_old_alteol(st: ss_pp): boolean; external;
procedure ss_old_wrterr(view es: string; st: ss_pp); external;
procedure ss_old_newthread(addr: integer; var threadid: integer; st: ss_pp); external;
procedure ss_old_killthread(threadid: integer; st: ss_pp); external;
procedure ss_old_signal(sid: integer; st: ss_pp); external;
procedure ss_old_signalone(sid: integer; st: ss_pp); external;
procedure ss_old_wait(lid: integer; sid: integer; st: ss_pp); external;
procedure ss_old_newlock(var id: integer; st: ss_pp); external;
procedure ss_old_displock(id: integer; st: ss_pp); external;
procedure ss_old_lock(id: integer; st: ss_pp); external;
procedure ss_old_unlock(id: integer; st: ss_pp); external;

begin
end.
