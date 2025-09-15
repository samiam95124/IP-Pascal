{*******************************************************************************
*                                                                              *
*                                CPU LOCK                                      *
*                                                                              *
* This module just verifies that the current CPU is a I80586 or better. This   *
* is done by simply verifying that it executes a CPUID instruction, which      *
* didn't exist before the I80586.                                              *
*                                                                              *
*******************************************************************************}

module cpulock;

uses windows,
     syslib,
     cpuid;

label 99;

private

procedure fail;

begin

   ss_wrterr('This software needs a I80586 or better CPU to execute');
   goto 99

end;

procedure vercpu;

var eax, ebx, ecx, edx: integer; { registers to the cpuid instruction }

begin

   eax := 0; { set function 0, find cpu id string }
   cpuid(eax, ebx, ecx, edx);
   if (eax = 0) and (ebx = 0) and (ecx = 0) and (edx = 0) then fail

end;

begin

   vercpu { verify cpu >= 586 }

end;

begin

   99: { abort program }

end.