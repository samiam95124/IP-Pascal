program prtcpu(output);

uses cpuid,
     strlib;

var eax, ebx, ecx, edx: integer;
    ids: packed array [1..12] of char;
    f, m, s: integer; { family, model and stepping }
    

begin

   eax := 0; { set function 0, find cpu id string }
   cpuid(eax, ebx, ecx, edx);

   if (eax = 0) and (ebx = 0) and (ecx = 0) and (edx = 0) then
      writeln('*** This processor does not implement the CPUID instruction')
   else begin

;write('cmpstr1: '); writeh(ebx, '$00000000'); writeln;
;write('cmpstr2: '); writeh(edx, '$00000000'); writeln;
;write('cmpstr3: '); writeh(ecx, '$00000000'); writeln;
      { extract cpu id string from returned values }

      ids[1] := chr(ebx and $ff);
      ids[2] := chr(ebx div $100 and $ff);
      ids[3] := chr(ebx div $10000 and $ff);
      ids[4] := chr(ebx div $1000000 and $ff);
      ids[5] := chr(edx and $ff);
      ids[6] := chr(edx div $100 and $ff);
      ids[7] := chr(edx div $10000 and $ff);
      ids[8] := chr(edx div $1000000 and $ff);
      ids[9] := chr(ecx and $ff);
      ids[10] := chr(ecx div $100 and $ff);
      ids[11] := chr(ecx div $10000 and $ff);
      ids[12] := chr(ecx div $1000000 and $ff);

      writeln('CPU id string: ', ids);

      eax := 1; { set function 1, get cpu parameters }
      cpuid(eax, ebx, ecx, edx);

;write('cmpstr4: '); writeh(eax, '$00000000'); writeln;

      f := eax div $100 and $f; { get family }
      m := eax div $10 and $f; { get model }
      s := eax and $f; { get stepping }

      { check AMD, and adjust if so }

      if ids = 'AuthenticAMD' then begin

         if f = $f then begin { use extended versions }

            f := f+(eax div $100000 and $ff);
            m := m+((eax div $10000 and $ff)*$10)

         end

      end;

      writeln('Family: ', f:1, ' model: ', m:1, ' Stepping: ', s:1);

   end

end.