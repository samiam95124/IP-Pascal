program test(input, output);

uses stddef,
     windows,
     strlib,
     extlib;

var pi: sc_process_information; { process information }
    si: sc_startupinfoa; { startup information }
    el: sc_evsptr; { environment list }
    p:  sc_evsptr;
    cp: pstring; { current path }
    r:  boolean;

begin

   pi.hprocess := 0;
   pi.hthread := 0;
   pi.dwprocessid := 0;
   pi.dwthreadid := 0;
   si.cb := 68;
   si.lpReserved := nil;
   si.lpDesktop := nil;
   si.lpTitle := nil;
   si.dwX := 0;
   si.dwY := 0;
   si.dwXSize := 0;
   si.dwYSize := 0;
   si.dwXCountChars := 0;
   si.dwYCountChars := 0;
   si.dwFillAttribute := 0;
   si.dwFlags := sc_startf_useshowwindow;
   si.wShowWindow := sc_sw_shownormal;
   si.cbReserved2 := 0;
   si.lpReserved2 := nil;
   si.hStdInput := 0;
   si.hStdOutput := 0;
   si.hStdError := 0;
   writeln('Branching to subprocess');
   cp := getcur; { get current path }
   el := nil;
   new(p);
   copy(p^.str, 'bark=sniff');
   p^.next := el;
   el := p;
   new(p);
   copy(p^.str, 'yip=yap');
   p^.next := el;
   el := p;
   r := sc_createprocess_nn('test1.exe', '', false, 0, el, cp^, si, pi);
   writeln('r: ', r:0);
   writeln('process branched, hit return to continue');
   readln

end.