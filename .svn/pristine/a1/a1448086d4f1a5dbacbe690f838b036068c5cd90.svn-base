!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
!                     I80386 INSTRUCTION DEFINITION FILE                      !
!                                                                             !
!                       Copyright (C) 2001 S. A. Moore                        !
!                                                                             !
! Contains assembly language sections for each of the operations in the IP    !
! Pascal intermediate, in I80386 instructions.                                !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
         { *** OBJECT CODE SECTION *** }

         ibgnpgm:  begin { main section start }

            if stack <> maxint then error(esysflt); { check stack at 0 }
            resblk; { resolve forward references }
            sizblk; { size entries in block }
            typstk^.res := nil; { clear resolvables }
            typstk^.resa := nil;
            if not typstk^.loc and (typstk^.lvl >= 3) then begin

               { locals not allocated }
               adjpar; { adjust parameter levels }
               allloc; { allocate any previous block locals }
               typstk^.loc := true { set locals resolved }

            end;
            typstk^.mark^.addr := pgmcnt; { set address of code }
            { if this is the main block start, equate the initalize jump }
            if blkcnt = 2 then iniblk^.addr := pgmcnt;
            { place current frame on stack, and set new frame from esp }
            emitbyt($c8); { link 0,0 }
            emitbyt($00);
            emitbyt($00);
            emitbyt(blkcnt-1); { with current level }
            { if a procedure or function, it has locals, and so they must
              be allocated. We use a general allocation because link only
              does 64kb }
            if typstk^.mark^.t = tproc then begin

               { we are activating a procedure }
               if typstk^.mark^.prcv <> 0 then begin { there are locals }

                  emitbyt($81); { add esp,offset }
                  emitbyt($c4);
                  emitint(-typstk^.mark^.prcv); { to allocate variables }
                  { clear local area. this is mainly done to allow files
                    to work in a local area, but also helps for other
                    variables }
                  emitbyt($8b); { mov edi,esp }
                  emitbyt($fc);
                  emitbyt($8b); { mov esi,edi }
                  emitbyt($f7);
                  emitbyt($47); { inc edi }
                  emitbyt($c6); { movb [esi],0 }
                  emitbyt($06);
                  emitbyt($00);
                  emitbyt($b9); { mov ecx,size }
                  emitint(typstk^.mark^.prcv-1);
                  emitbyt($f2); { repnz }
                  emitbyt($a4) { movsb }

               end

            end else if typstk^.mark^.t = tfunc then begin

               { we are activating a function }
               if typstk^.mark^.fncv <> 0 then begin { there are locals }

                  emitbyt($81); { add esp,offset }
                  emitbyt($c4);
                  emitint(-typstk^.mark^.fncv); { to allocate variables }
                  { clear local area. this is mainly done to allow files
                    to work in a local area, but also helps for other
                    variables }
                  emitbyt($8b); { mov edi,esp }
                  emitbyt($fc);
                  emitbyt($8b); { mov esi,edi }
                  emitbyt($f7);
                  emitbyt($47); { inc edi }
                  emitbyt($c6); { movb [esi],0 }
                  emitbyt($06);
                  emitbyt($00);
                  emitbyt($b9); { mov ecx,size }
                  emitint(typstk^.mark^.fncv-1);
                  emitbyt($f2); { repnz }
                  emitbyt($a4) { movsb }

               end

            end else begin

               { Major modules are expected to run once to completion. Because
                 nesting problems, we must save the display for each such
                 to allow a goto a path back to that level. This does not need
                 be reentrant, since major modules aren't }
               emitbyt($89); { mov [dispsav],ebp }
               emitbyt($2d);
               emitadr(typstk^.mark^.ds, itadr) { place display save address }

            end
            
         end;
         iendpgm:  begin { main section end }

            { if a procedure or function, it has locals, and so they must
              be deallocated }
            if typstk^.mark^.t = tproc then begin

               { we are deactivating a procedure }
               emitbyt($c9); { leave }
               if typstk^.mark^.prca <> 0 then begin { deallocate parameters }

                  emitbyt($58); { pop eax }
                  emitbyt($81); { add esp,offset }
                  emitbyt($c4);
                  emitint(typstk^.mark^.prca);
                  emitbyt($ff); { jmp eax }
                  emitbyt($e0)

               end else emitbyt($c3) { ret }

            end else if typstk^.mark^.t = tfunc then begin

               { we are deactivating a function }
               emitbyt($c9); { leave }
               if typstk^.mark^.fnca <> 0 then begin { deallocate parameters }

                  emitbyt($58); { pop eax }
                  emitbyt($81); { add esp,offset }
                  emitbyt($c4);
                  emitint(typstk^.mark^.fnca);
                  emitbyt($ff); { jmp eax }
                  emitbyt($e0)

               end else emitbyt($c3) { ret }

            end else begin { main exit }

               { generate call to next module in series }
               emitbyt($e8); { call modend }
               emitadr(modend, itradr) { output address }

            end;
            if stack <> maxint then error(esysflt) { check stack at 0 }

         end;
         ibgnext:  if stack <> maxint then error(esysflt); { check stack at 0 }
         iendext:  begin { end finalizer section }

            emitbyt($c9); { leave }
            emitbyt($c3); { set return to caller }
            if stack <> maxint then error(esysflt); { check stack at 0 }
            final := true { set finalization block has appeared }

         end;
         ilodadr:   begin { load address }

            getlnk(tp); { link object to load }
            { process reference on object }
            if tp^.t = tvar then tp^.varr := true
            else if tp^.t = tfix then tp^.fixr := true
            else if tp^.t = tproc then tp^.prcr := true
            else if tp^.t = tfunc then tp^.fnct := true;
            if (tp^.t = tfield) or (tp^.t = tftag) then begin

               { access is to a 'with' field, must lookup reference in with
                 stacked structures }
               sp := srtstk; { index 1st on stack }
               sp1 := nil; { set no entry found }
               while sp <> nil do begin { search for 'with' match }

                  if sp^.withm then begin { is 'with' entry, check for match }

                     { check field exists in scope }
                     if inscope(sp^.lab^.recf, tp) then begin { found }

                        sp1 := sp; { set location }
                        sp := nil { flag search complete }

                     end

                  end;
                  if sp <> nil then sp := sp^.next { index next entry }

               end;
               if sp1 = nil then error(einvfmt); { set invalid intermediate }
               { load local address current block }
               emitbyt($8b); { mov eax,esp }
               emitbyt($c4);
               emitbyt($8b); { move eax,off[eax] }
               emitbyt($80);
               emitint(sp1^.off-stack); { generate offset }
               { now we have pulled the address to tos. we can now process just
                 as a record offset }
               emitbyt($05); { add eax,off }
               emitadr(tp, itadr);
               emitbyt($50) { push eax }
            
            end else begin

               if tp^.local then begin { local address }

                  { get display for target level }
                  emitbyt($8b); { mov eax,[ebp-lvl] }
                  emitbyt($85);
                  emitint(-((tp^.level-1)*4)); { offset to proper display level }
                  { offset to local }
                  emitbyt($05); { add eax,imm }
                  emitint(tp^.addr); { place offset address }
                  { place on stack }
                  emitbyt($50) { push eax }

               end else begin

                  { load global address }
                  emitbyt($68); { push imm }
                  emitadr(tp, itadr) { place address }

               end

            end;
            stack := stack-stksiz { adds one }

         end;
!
! lodadrf: Load function result address
!
oplodadrf_par:
        defw    ??              ! net stack offset
        defb    pcaddr          ! place address
        defw    oplodadrf-4

oplodadrf_cod:
        mov     eax,ebp         ! get the display
        add     eax,imm32       ! offset to local
oplodadrf_cod_01:
        push    eax             ! place on stack
!
! arrref: Array reference
!
oparrref_par:
        defw    stksiz          ! net stack offset

        pop     eax             ! load index
        cmp     eax,imm32       ! check low bound
        jl      oparref_cod_01  ! out of bounds
        cmp     eax,imm32       ! check high bound
        jle                     ! in bounds
oparrref_cod_01:
        push    rerngchk        ! process range error
        call    error
        sub     eax,imm32       ! adjust index for lower bound
        mov     ebx,imm32       ! scale
        mul     eax,ebx
        pop     ebx             ! load array base
        add     eax,ebx         ! add processed index to that
        push    eax             ! place on stack
        


         iarrref:  begin { array reference }

            getlnk(tp); { get array type }
            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump to error label }
            gettypa(srtstk^.lab1, tlab); { set jump over error label }
            { load index }
            emitbyt($58); { pop eax }
            { generate range check }
            emitbyt($3d); { cmp eax,imm }
            emitint(lbound(tp^.arri)); { place low bound }
            emitbyt($0f); { jl goerror }
            emitbyt($8c);
            emitadr(srtstk^.lab, itradr); { place error jump address }
            emitbyt($3d); { cmp eax,imm }
            emitint(ubound(tp^.arri)); { place upper bound }
            emitbyt($0f); { jle noerror }
            emitbyt($8e);
            emitadr(srtstk^.lab1, itradr); { place no error address }
            { generate error routine call }
            srtstk^.lab^.addr := pgmcnt; { set jump to error location }
            emitbyt($68); { push rerngchk }
            emitint(ord(rerngchk)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab1^.addr := pgmcnt; { set jump over error location }
            { adjust index for lower bound }
            emitbyt($2d); { sub eax,lbound }
            emitint(lbound(tp^.arri)); { place lower bound }
            emitbyt($bb); { mov ebx,size }
            emitint(tp^.arrt^.size); { place base type size }
            emitbyt($f7); { mul eax,ebx }
            emitbyt($e3);
            { load array base }
            emitbyt($5b); { pop ebx }
            { add processed index to that }
            emitbyt($03); { add eax,ebx }
            emitbyt($c3);
            emitbyt($50); { push eax }
            popsrt; { remove structure level }
            stack := stack+stksiz { net is less one }

         end;
         iarfgar:  begin { general array reference }

            getlnk(tp); { get array type }
            if tp^.t <> tgarry then error(einvfmt); { bad format }
            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            { load index }
            emitbyt($58); { pop eax }
            { load tagged pointer }
            emitbyt($5b); { pop ebx }
            emitbyt($59); { pop ecx }
            { zero adjust }
            emitbyt($48); { dec eax }
            { generate range check }
            emitbyt($3b); { cmp eax,ecx }
            emitbyt($c1);
            emitbyt($0f); { jb over }
            emitbyt($82);
            emitadr(srtstk^.lab, itradr); { place no error address }
            { generate error routine call }
            emitbyt($68); { push rerngchk }
            emitint(ord(rerngchk)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab^.addr := pgmcnt; { set jump over error location }
            emitbyt($b9); { mov ecx,size }
            emitint(tp^.gart^.size); { output size of base element }
            emitbyt($f7); { mul eax,ecx }
            emitbyt($e1);
            { add processed index to array base }
            emitbyt($03); { add eax,ebx }
            emitbyt($c3);
            emitbyt($50); { push eax }
            popsrt; { remove structure level }
            stack := stack+intsiz+tgpsiz-intsiz { adjust stack }

         end;
         irecoff:     begin { record element reference }

            getlnk(tp); { get record field type }
            { get base address }
            emitbyt($58); { pop eax }
            emitbyt($05); { add eax,imm }
            emitadr(tp, itadr); { place record offset }
            emitbyt($50) { push eax }

         end;
         ildiint:  begin { load indirect integer }

            getlnk(tp); { variable type }
            { get address }
            emitbyt($58); { pop eax }
            { load operand }
            if tp^.size = 4 then begin { integer }

               emitbyt($8b); { mov eax,[eax] }
               emitbyt($00)

            end else if tp^.size = 2 then begin { word }

               if chksgn(tp) then begin { signed }

                  emitbyt($0f); { movsxw eax,[eax] }
                  emitbyt($bf);
                  emitbyt($00)

               end else begin { unsigned }

                  emitbyt($0f); { movzxw eax,[eax] }
                  emitbyt($b7);
                  emitbyt($00)

               end

            end else if tp^.size = 1 then begin { byte }

               if chksgn(tp) then begin { signed }

                  emitbyt($0f); { movsxb eax,[eax] }
                  emitbyt($be);
                  emitbyt($00)

               end else begin { unsigned }

                  emitbyt($0f); { movzxb eax,[eax] }
                  emitbyt($b6);
                  emitbyt($00)

               end

            end else error(einvfmt); { invalid format }
            { place on stack }
            emitbyt($50) { push eax }

         end;
         ildirel:   begin { load indirect real }

            { get address }
            emitbyt($5e); { pop si }
            { load real }
            emitbyt($ad); { lodsd }
            emitbyt($8b); { mov ebx,eax }
            emitbyt($d8);
            emitbyt($ad); { lodsd }
            emitbyt($50); { push eax }
            emitbyt($53); { push ebx }
            stack := stack+stksiz-rlsiz { adjust stack }
            
         end;
         ildisrl:  begin { load indirect short real }

            { get address }
            emitbyt($58); { pop eax }
            { load to fpu }
            emitbyt($d9); { fld [eax] }
            emitbyt($00);
            { create stack space }
            emitbyt($50); { push eax }
            emitbyt($50); { push eax }
            { place fpu result }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            emitbyt($dd); { fstp [eax] }
            emitbyt($18);
            { sync stored operand }
            emitbyt($9b); { fwait }
            stack := stack+stksiz-rlsiz { adjust stack }

         end;
         ildiset:  begin { load indirect set }

            { get address }
            emitbyt($5e); { pop si }
            { create space on stack }
            emitbyt($81); { add esp,offset }
            emitbyt($c4);
            emitint(-setsiz);
            { place destination address }
            emitbyt($8b); { mov edi,esp }
            emitbyt($fc);
            { place size }
            emitbyt($c7); { mov ecx,setsiz }
            emitbyt($c1);
            emitint(setsiz div 4);
            { place operand }
            emitbyt($f3); { rep }
            emitbyt($a5); { movsd }
            stack := stack+stksiz-setsiz { adjust stack }

         end;
         ildichr, 
         ildibol:  begin { load indirect character }

            { get address }
            emitbyt($58); { pop eax }
            { load operand }
            emitbyt($0f); { movzxb eax,[eax] }
            emitbyt($b6);
            emitbyt($00);
            { place on stack }
            emitbyt($50) { push eax }
            
         end;
         ildisrc:  begin { load indirect structure }

            getlnk(tp); { get structure type }
            { get address }
            emitbyt($5e); { pop si }
            { create space on stack }
            emitbyt($81); { add esp,offset }
            emitbyt($c4);
            emitint(-wrdsiz(tp^.size));
            { place destination address }
            emitbyt($8b); { mov edi,esp }
            emitbyt($fc);
            { place size }
            emitbyt($c7); { mov ecx,setsiz }
            emitbyt($c1);
            emitint(tp^.size);
            { place operand }
            emitbyt($f3); { rep }
            emitbyt($a4); { movsb }
            stack := stack+stksiz-wrdsiz(tp^.size) { adjust stack }

         end;
         ildiptr:  begin { load indirect pointer }

            { get address }
            emitbyt($58); { pop eax }
            { load operand }
            emitbyt($8b); { mov eax,[eax] }
            emitbyt($00);
            { replace on stack }
            emitbyt($50) { push eax }

         end;
         ilditgp:   begin

            { get address }
            emitbyt($5e); { pop si }
            { load real }
            emitbyt($ad); { lodsd }
            emitbyt($8b); { mov ebx,eax }
            emitbyt($d8);
            emitbyt($ad); { lodsd }
            emitbyt($50); { push eax }
            emitbyt($53); { push ebx }
            stack := stack+stksiz-tgpsiz { adjust stack }

         end;
         ilimint: begin
 
            rdnum(v); { get integer parameter }
            emitbyt($b8); { mov eax,imm }
            emitint(v); { output value in line }
            { place on stack }
            emitbyt($50); { push eax }
            stack := stack-intsiz { adjust stack }

         end;
         ilimrel:  begin

            rdreal(r); { get real parameter }
            { the I80386 has no real immediate instructions. we load the real
              into a constant entry, then that will be placed in the constants
              area }
            gettypa(tp, trcst); { get constant entry }
            tp^.rval := r; { place constant }
            { load constant }
            emitbyt($dd); { fld [rconst] }
            emitbyt($05);
            emitadr(tp, itadr); { place address }
            { create stack space }
            emitbyt($50); { push eax }
            emitbyt($50); { push eax }
            { place fpu result }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            emitbyt($dd); { fstp [eax] }
            emitbyt($18);
            { sync stored operand }
            emitbyt($9b); { fwait }
            stack := stack-rlsiz { adust stack }

         end;
         ilimns:  begin

            { create space on stack }
            emitbyt($81); { add esp,offset }
            emitbyt($c4);
            emitint(-setsiz);
            emitbyt($8b); { mov esi,esp }
            emitbyt($f4);
            emitbyt($8b); { mov edi,esi }
            emitbyt($fe);
            emitbyt($47); { inc edi }
            emitbyt($c6); { movb [esi],0 }
            emitbyt($06);
            emitbyt($00);
            emitbyt($c7); { mov ecx,setsiz-1 }
            emitbyt($c1);
            emitint(setsiz-1);
            emitbyt($f3); { rep }
            emitbyt($a4); { movsb }
            stack := stack-setsiz { adds a set }

         end;
         ilodlen:  begin

            getlnk(tp); { get array type }
            if tp^.t <> tgarry then error(einvfmt); { bad format }
            { discard pointer }
            emitbyt($58); { pop eax }
            { get length of string }
            emitbyt($58); { pop eax }
            { load base object size }
            emitbyt($b9); { mov ecx,size }
            emitint(tp^.gart^.size); { output base element size }
            { divide to find number of elements }
            emitbyt($33); { xor edx,edx }
            emitbyt($d2);
            emitbyt($f7); { div eax,ecx }
            emitbyt($f1);
            { place on stack }
            emitbyt($50); { push eax }
            stack := stack+4 { removes the pointer portion }

         end;
         inotint:  begin

            { get operand }
            emitbyt($58); { pop eax }
            { 'not' the bits }
            emitbyt($f7); { not eax }
            emitbyt($d0);
            { replace }
            emitbyt($50) { push eax }

         end;
         inotbol:  begin

            { get operand }
            emitbyt($58); { pop eax }
            { flip the first bit }
            emitbyt($35); { xor eax,1 }
            emitint(1);
            { replace }
            emitbyt($50) { push eax }

         end;
         isinset:  begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            { get operand }
            emitbyt($58); { pop eax }
            { check < 256 }
            emitbyt($3d); { cmp eax,256 }
            emitint(256);
            emitbyt($0f); { jb noerror }
            emitbyt($82);
            emitadr(srtstk^.lab, itradr); { place no error address }
            { generate error routine call }
            emitbyt($68); { push rerngchk }
            emitint(ord(rerngchk)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab^.addr := pgmcnt; { set jump over error location }
            { find set dword address }
            emitbyt($8b); { mov ebx,esp }
            emitbyt($dc);
            { set element }
            emitbyt($0f); { bts [ebx],eax }
            emitbyt($ab);
            emitbyt($03);
            popsrt; { remove structure level }
            stack := stack+stksiz { net is less one }

         end;
         irngset:  begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            gettypa(srtstk^.lab1, tlab); { set jump to error label }
            { get operands }
            emitbyt($59); { pop ecx }
            emitbyt($58); { pop eax }
            { check < 256 }
            emitbyt($3d); { cmp eax,256 }
            emitint(256);
            emitbyt($0f); { jae error }
            emitbyt($83);
            emitadr(srtstk^.lab1, itradr); { place error address }
            emitbyt($81); { cmp ecx,256 }
            emitbyt($f9);
            emitint(256);
            emitbyt($0f); { jb no error }
            emitbyt($82);
            emitadr(srtstk^.lab, itradr); { place no error address }
            { generate error routine call }
            srtstk^.lab1^.addr := pgmcnt; { set jump to error location }
            emitbyt($68); { push rerngchk }
            emitint(ord(rerngchk)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab^.addr := pgmcnt; { set jump over error location }
            { find bit set length }
            emitbyt($2b); { sub ecx,eax }
            emitbyt($c8);
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            { check 1st lower than 2nd, in which case the range is null }
            emitbyt($0f); { js over }
            emitbyt($88);
            emitadr(srtstk^.lab, itradr); { place jump over address }
            { adjust count }
            emitbyt($41); { inc ecx }
            { save starting bit }
            emitbyt($8b); { mov ebx,eax }
            emitbyt($d8);
            gettypa(srtstk^.lab1, tlab); { get loop label }
            srtstk^.lab1^.addr := pgmcnt; { set loop location }
            { find set dword address }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { set element }
            emitbyt($0f); { bts [eax],ebx }
            emitbyt($ab);
            emitbyt($18);
            { increment bit number }
            emitbyt($43); { inc ebx }
            { count off bits }
            emitbyt($49); { dec ecx }
            { loop next bit }
            emitbyt($0f); { jnz loop }
            emitbyt($85);
            emitadr(srtstk^.lab1, itradr); { place loop address }
            srtstk^.lab^.addr := pgmcnt; { set jump over location }
            popsrt; { remove structure level }
            stack := stack+(2*stksiz) { net is less two }

         end;
         icvtitr:  begin { convert integer to real }

            { get address of int on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load and convert to real }
            emitbyt($db); { fildd [eax] }
            emitbyt($00);
            { add space for real }
            emitbyt($83); { add esp,-4 }
            emitbyt($c4);
            emitbyt($ff-4+1);
            { index that }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { store real }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync the fpu store }
            emitbyt($9b); { fwait }
            stack := stack+intsiz-rlsiz { adjust stack }

         end; 
         icvtrtsr: begin { convert real to short real }

            { get address of real on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load to fpu }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { adjust back to short real }
            emitbyt($83); { add esp,4 }
            emitbyt($c4);
            emitbyt(4);
            { index that }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { store to destination short }
            emitbyt($d9); { fstps [eax] }
            emitbyt($18);
            { sync the fpu store }
            emitbyt($9b); { fwait }
            stack := stack+rlsiz-srlsiz { adjust stack }

         end; 
         icvtgtf:  begin

            getlnk(tp); { get fixed type }
            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            { get address }
            emitbyt($5b); { pop ebx }
            { get length }
            emitbyt($58); { pop eax }
            emitbyt($3d); { cmp eax,size }
            emitint(tp^.size); { generate string size }
            emitbyt($0f); { je over }
            emitbyt($84);
            emitadr(srtstk^.lab, itradr); { place jump over address }
            { generate error routine call }
            emitbyt($68); { push relenmat }
            emitint(ord(relenmat)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab^.addr := pgmcnt; { set jump over error location }
            emitbyt($53); { push ebx }
            popsrt; { remove structure level }
            stack := stack+4 { pointer becomes simple }
            
         end;
         icvtftg:  begin

            getlnk(tp); { get fixed type }
            { get address }
            emitbyt($58); { pop eax }
            { place length on stack }
            emitbyt($68); { push size }
            emitint(tp^.size); { generate string size }
            { replace address on stack }
            emitbyt($50); { push eax }
            stack := stack-4 { pointer becomes complex }
            
         end;
         icvtntg:  begin

            { just expand the nil to tagged pointer size }
            emitbyt($68); { push 0 }
            emitint(0);
            stack := stack-4 { pointer becomes complex }

         end;
         iswptop:  begin

            getlnk(tp); { get source }
            getlnk(tp1); { get destination }
            { swap is a problem, because one or both of the operands could be
              real, which are allways double length on the stack (even shorts).
              It could also be a tagged pointer over a normal pointer (a 
              special case of write). so we check and generate one of five swap
              types }
            if realt(tp) and realt(tp1) then begin { real with real }

               { get both operands }
               emitbyt($58); { pop eax }
               emitbyt($5b); { pop ebx }
               emitbyt($59); { pop ecx }
               emitbyt($5a); { pop edx }
               { push back in opposite order }
               emitbyt($53); { push ebx }
               emitbyt($50); { push eax }
               emitbyt($52); { push edx }
               emitbyt($51) { push ecx }

            end else if realt(tp) then begin { real with integer }

               { get both operands }
               emitbyt($58); { pop eax }
               emitbyt($5b); { pop ebx }
               emitbyt($59); { pop ecx }
               { push back in opposite order }
               emitbyt($50); { push eax }
               emitbyt($51); { push ecx }
               emitbyt($53) { push ebx }

            end else if realt(tp1) then begin { integer with real }

               { get both operands }
               emitbyt($58); { pop eax }
               emitbyt($5b); { pop ebx }
               emitbyt($59); { pop ecx }
               { push back in opposite order }
               emitbyt($53); { push ebx }
               emitbyt($50); { push eax }
               emitbyt($51) { push ecx }

            end else if tp^.t = tgarry then begin { tagged with integer }

               { get both operands }
               emitbyt($58); { pop eax }
               emitbyt($5b); { pop ebx }
               emitbyt($59); { pop ecx }
               { push back in opposite order }
               emitbyt($50); { push eax }
               emitbyt($51); { push ecx }
               emitbyt($53) { push ebx }

            end else begin

               { get both operands }
               emitbyt($58); { pop eax }
               emitbyt($5b); { pop ebx }
               { push back in opposite order }
               emitbyt($50); { push eax }
               emitbyt($53) { push ebx }

            end
            
         end;
         iintset:  begin { find set intersection }

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set loop label }
            { load 1st set address }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load 2nd set address }
            emitbyt($8b); { move ebx,esp }
            emitbyt($dc);
            emitbyt($83); { add ebx,setsiz }
            emitbyt($c3);
            emitbyt(setsiz);
            { set size of set in dwords }
            emitbyt($b9); { mov ecx,setsiz div 4 }
            emitint(setsiz div 4);
            srtstk^.lab^.addr := pgmcnt; { set loop location }
            { 'and' two dwords of the set together }
            emitbyt($8b); { mov edx,[eax] }
            emitbyt($10);
            emitbyt($21); { andd [ebx],edx }
            emitbyt($13);
            emitbyt($83); { add eax,4 }
            emitbyt($c0);
            emitbyt($04);
            emitbyt($83); { add ebx,4 }
            emitbyt($c3);
            emitbyt($04);
            emitbyt($49); { dec ecx }
            emitbyt($0f); { jnz loop }
            emitbyt($85);
            emitadr(srtstk^.lab, itradr); { place loop jump address }
            { remove tos from stack }
            emitbyt($83); { add esp,setsiz }
            emitbyt($c4);
            emitbyt(setsiz);
            popsrt; { remove structure level }
            stack := stack+setsiz { net less one set }

         end;
         imltrel:   begin

            { get address tos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load to fpu }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { get address sos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { multiply }
            emitbyt($dc); { fmuld [eax] }
            emitbyt($08);
            { store result }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync fpu }
            emitbyt($9b); { fwait }
            stack := stack+rlsiz { net is less one }

         end;
         imltint:  begin

            { load operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { multiply }
            emitbyt($f7); { imul ebx }
            emitbyt($eb);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+intsiz { net is less one }

         end;
         idivrel:   begin

            { get address tos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load to fpu }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { get address sos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { divide }
            emitbyt($dc); { fdivrd [eax] }
            emitbyt($38);
            { store result }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync fpu }
            emitbyt($9b); { fwait }
            stack := stack+rlsiz { net is less one }

         end;
         idivint:  begin

            { load operands }
            emitbyt($5b); { pop ebx }
            emitbyt($58); { pop eax }
            { extend divident to 64 bits }
            emitbyt($99); { cdq }
            { divide }
            emitbyt($f7); { idiv eax,ebx }
            emitbyt($fb);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+intsiz { net is less one }
      
         end;
         imodint:  begin

            { load operands }
            emitbyt($5b); { pop ebx }
            emitbyt($58); { pop eax }
            { extend divident to 64 bits }
            emitbyt($99); { cdq }
            { divide }
            emitbyt($f7); { idiv eax,ebx }
            emitbyt($fb);
            { place result }
            emitbyt($52); { push edx }
            stack := stack+intsiz { net is less one }

         end;
         iandint:  begin

            { load operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { and }
            emitbyt($23); { and eax,ebx }
            emitbyt($c3);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+intsiz { net is less one }

         end;
         inegint:  begin { Negate integer }

            { load operand }
            emitbyt($58); { pop eax }
            { negate }
            emitbyt($f7); { neg eax }
            emitbyt($d8);
            { place result }
            emitbyt($50) { push eax }
               
         end;
         inegrel:   begin { Negate real }

            { get address tos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load to fpu }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { negate }
            emitbyt($d9); { fchs }
            emitbyt($e0);
            { store result }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync fpu }
            emitbyt($9b) { fwait }

         end;
         iuniset:  begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set loop label }
            { load 1st set address }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load 2nd set address }
            emitbyt($8b); { move ebx,esp }
            emitbyt($dc);
            emitbyt($83); { add ebx,setsiz }
            emitbyt($c3);
            emitbyt(setsiz);
            { set size of set in dwords }
            emitbyt($b9); { mov ecx,setsiz div 4 }
            emitint(setsiz div 4);
            srtstk^.lab^.addr := pgmcnt; { set loop location }
            { 'or' two dwords of the set together }
            emitbyt($8b); { mov edx,[eax] }
            emitbyt($10);
            emitbyt($09); { ord [ebx],edx }
            emitbyt($13);
            emitbyt($83); { add eax,4 }
            emitbyt($c0);
            emitbyt($04);
            emitbyt($83); { add ebx,4 }
            emitbyt($c3);
            emitbyt($04);
            emitbyt($49); { dec ecx }
            emitbyt($0f); { jnz loop }
            emitbyt($85);
            emitadr(srtstk^.lab, itradr); { place loop jump address }
            { remove tos from stack }
            emitbyt($83); { add esp,setsiz }
            emitbyt($c4);
            emitbyt(setsiz);
            popsrt; { remove structure level }
            stack := stack+setsiz { net less one set }

         end;
         iaddrel:   begin { add real }

            { get address tos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load to fpu }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { get address sos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { add }
            emitbyt($dc); { faddd [eax] }
            emitbyt($00);
            { store result }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync fpu }
            emitbyt($9b); { fwait }
            stack := stack+rlsiz { net is less one }

         end;
         iaddint:  begin

            { load operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { multiply }
            emitbyt($03); { add eax,ebx }
            emitbyt($c3);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+intsiz { net is less one }

         end;
         idifset:  begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set loop label }
            { load 1st set address }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load 2nd set address }
            emitbyt($8b); { move ebx,esp }
            emitbyt($dc);
            emitbyt($83); { add ebx,setsiz }
            emitbyt($c3);
            emitbyt(setsiz);
            { set size of set in dwords }
            emitbyt($b9); { mov ecx,setsiz div 4 }
            emitint(setsiz div 4);
            srtstk^.lab^.addr := pgmcnt; { set loop location }
            { 'xor' two dwords of the set together }
            emitbyt($8b); { mov edx,[eax] }
            emitbyt($10);
            emitbyt($33); { xord edx,[ebx] }
            emitbyt($13);
            emitbyt($21); { andd [ebx],edx }
            emitbyt($13);
            emitbyt($83); { add eax,4 }
            emitbyt($c0);
            emitbyt($04);
            emitbyt($83); { add ebx,4 }
            emitbyt($c3);
            emitbyt($04);
            emitbyt($49); { dec ecx }
            emitbyt($0f); { jnz loop }
            emitbyt($85);
            emitadr(srtstk^.lab, itradr); { place loop jump address }
            { remove tos from stack }
            emitbyt($83); { add esp,setsiz }
            emitbyt($c4);
            emitbyt(setsiz);
            popsrt; { remove structure level }
            stack := stack+setsiz { net less one set }

         end;
         isubrel:   begin

            { get address tos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load to fpu }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { get address sos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { subtract }
            emitbyt($dc); { fsubrd [eax] }
            emitbyt($28);
            { store result }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync fpu }
            emitbyt($9b); { fwait }
            stack := stack+rlsiz { net is less one }

         end;
         isubint:  begin

            { load operands }
            emitbyt($5b); { pop ebx }
            emitbyt($58); { pop eax }
            { subtract }
            emitbyt($2b); { sub eax,ebx }
            emitbyt($c3);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+intsiz { net is less one }

         end;
         iorint:   begin

            { load operands }
            emitbyt($5b); { pop ebx }
            emitbyt($58); { pop eax }
            { 'or' }
            emitbyt($0b); { or eax,ebx }
            emitbyt($c3);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+intsiz { net is less one }

         end;
         ixorint:  begin

            { load operands }
            emitbyt($5b); { pop ebx }
            emitbyt($58); { pop eax }
            { 'xor' }
            emitbyt($33); { xor eax,ebx }
            emitbyt($c3);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+intsiz { net is less one }

         end;
         iincset:   begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            gettypa(srtstk^.lab1, tlab); { set exit label }
            { get operand from over set }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            emitbyt($83); { add eax,setsiz }
            emitbyt($c0);
            emitbyt(setsiz);
            emitbyt($8b); { mov eax,[eax] }
            emitbyt($00);
            { check < 256 }
            emitbyt($3d); { cmp eax,256 }
            emitint(256);
            emitbyt($0f); { jb noerror }
            emitbyt($82);
            emitadr(srtstk^.lab, itradr); { place no error address }
            { set false for out of range }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($e9); { jmp addr }
            emitadr(srtstk^.lab1, itradr);
            srtstk^.lab^.addr := pgmcnt; { set jump over error location }
            { find set dword address }
            emitbyt($8b); { mov ebx,esp }
            emitbyt($dc);
            { test element }
            emitbyt($0f); { bt [ebx],eax }
            emitbyt($a3);
            emitbyt($03);
            { convert carry flag to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setc al }
            emitbyt($92);
            emitbyt($c0);
            srtstk^.lab1^.addr := pgmcnt; { set jump over error location }
            { remove tos from stack }
            emitbyt($83); { add esp,setsiz+intsiz }
            emitbyt($c4);
            emitbyt(setsiz+intsiz);
            { place result }
            emitbyt($50); { push eax }
            popsrt; { remove structure level }
            stack := stack+setsiz { net is less one }

         end;
         iequset:  begin

            { load 1st set address }
            emitbyt($8b); { move edi,esp }
            emitbyt($fc);
            { load 2nd set address }
            emitbyt($8b); { move esi,esp }
            emitbyt($f4);
            emitbyt($83); { add esi,setsiz }
            emitbyt($c6);
            emitbyt(setsiz);
            { get size of set }
            emitbyt($b9); { mov ecx,setsiz }
            emitint(setsiz);
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { sete al }
            emitbyt($94);
            emitbyt($c0);
            { remove both from stack }
            emitbyt($83); { add esp,setsiz*2 }
            emitbyt($c4);
            emitbyt(setsiz*2);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+(2*setsiz)-bolsiz { adjust stack }

         end;
         iequrel:   begin

            { get address tos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load to fpu }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { get address sos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { compare }
            emitbyt($dc); { fcompd [eax] }
            emitbyt($18);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { transfer fpu flags to integer unit flags }
            emitbyt($df); { fnstsw ax }
            emitbyt($e0);
            emitbyt($9e); { sahf }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { sete al }
            emitbyt($94);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+(2*rlsiz)-bolsiz { net is less one }

         end;
         iequstr:  begin

            getlnk(tp); { get string type }
            { load operands }
            emitbyt($5f); { pop edi }
            emitbyt($5e); { pop esi }
            emitbyt($b9); { mov ecx,size }
            emitint(tp^.size); { generate string size }
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { sete al }
            emitbyt($94);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+stksiz { net is less one }

         end;
         iequgst:  begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            { load both operands }
            emitbyt($5f); { pop edi }
            emitbyt($58); { pop eax }
            emitbyt($5e); { pop esi }
            emitbyt($59); { pop ecx }
            { check lengths equal }
            emitbyt($3b); { cmp eax,ecx }
            emitbyt($c1);
            emitbyt($0f); { je noerror }
            emitbyt($84);
            emitadr(srtstk^.lab, itradr); { place no error address }
            { generate error routine call }
            emitbyt($68); { push rerngchk }
            emitint(ord(relenmat)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab^.addr := pgmcnt; { set jump over error location }
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { sete al }
            emitbyt($94);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            popsrt; { remove structure level }
            { set two tagged pointers replaced by boolean }
            stack := stack+tgpsiz+tgpsiz-bolsiz

         end;
         iequint:  begin

            { load operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { compare }
            emitbyt($3b); { cmp eax,ebx }
            emitbyt($c3);
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { sete al }
            emitbyt($94);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+stksiz { net is less one }

         end;
         iequtgp:  begin

            { load operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            emitbyt($59); { pop ecx }
            emitbyt($5a); { pop edx }
            { compare }
            emitbyt($3b); { cmp eax,ecx }
            emitbyt($c1);
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { sete al }
            emitbyt($94);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+(2*tgpsiz)-bolsiz { adjust stack }

         end;
         ineqset:  begin

            { load 1st set address }
            emitbyt($8b); { move edi,esp }
            emitbyt($fc);
            { load 2nd set address }
            emitbyt($8b); { move esi,esp }
            emitbyt($f4);
            emitbyt($83); { add esi,setsiz }
            emitbyt($c6);
            emitbyt(setsiz);
            { get size of set }
            emitbyt($b9); { mov ecx,setsiz }
            emitint(setsiz);
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setne al }
            emitbyt($95);
            emitbyt($c0);
            { remove both from stack }
            emitbyt($83); { add esp,setsiz*2 }
            emitbyt($c4);
            emitbyt(setsiz*2);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+(2*setsiz)-bolsiz { adjust stack }

         end;
         ineqrel:   begin

            { get address tos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load to fpu }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { get address sos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { compare }
            emitbyt($dc); { fcompd [eax] }
            emitbyt($18);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { transfer fpu flags to integer unit flags }
            emitbyt($df); { fnstsw ax }
            emitbyt($e0);
            emitbyt($9e); { sahf }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setne al }
            emitbyt($95);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+(2*rlsiz)-bolsiz { net is less one }

         end;
         ineqstr:  begin

            getlnk(tp); { get string type }
            { load operands }
            emitbyt($5f); { pop edi }
            emitbyt($5e); { pop esi }
            emitbyt($b9); { mov ecx,size }
            emitint(tp^.size); { generate string size }
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setne al }
            emitbyt($95);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+stksiz { net is less one }

         end;
         ineqgst:  begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            { load both operands }
            emitbyt($5f); { pop edi }
            emitbyt($58); { pop eax }
            emitbyt($5e); { pop esi }
            emitbyt($59); { pop ecx }
            { check lengths equal }
            emitbyt($3b); { cmp eax,ecx }
            emitbyt($c1);
            emitbyt($0f); { je noerror }
            emitbyt($84);
            emitadr(srtstk^.lab, itradr); { place no error address }
            { generate error routine call }
            emitbyt($68); { push rerngchk }
            emitint(ord(relenmat)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab^.addr := pgmcnt; { set jump over error location }
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setne al }
            emitbyt($95);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            popsrt; { remove structure level }
            { set two tagged pointers replaced by boolean }
            stack := stack+tgpsiz+tgpsiz-bolsiz

         end;
         ineqint:  begin

            { load operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { compare }
            emitbyt($3b); { cmp eax,ebx }
            emitbyt($c3);
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setne al }
            emitbyt($95);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+stksiz { net is less one }

         end;
         ineqtgp:  begin

            { load operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            emitbyt($59); { pop ecx }
            emitbyt($5a); { pop edx }
            { compare }
            emitbyt($3b); { cmp eax,ecx }
            emitbyt($c1);
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setne al }
            emitbyt($95);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+(2*tgpsiz)-bolsiz { adjust stack }

         end;
         ileqset:  begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set loop label }
            { load 1st set address }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load 2nd set address }
            emitbyt($8b); { move ebx,esp }
            emitbyt($dc);
            emitbyt($83); { add ebx,setsiz }
            emitbyt($c3);
            emitbyt(setsiz);
            { set size of set in dwords }
            emitbyt($b9); { mov ecx,setsiz div 4 }
            emitint(setsiz div 4);
            { clear flag }
            emitbyt($33); { xor edi,edi } 
            emitbyt($ff);
            srtstk^.lab^.addr := pgmcnt; { set loop location }
            { 'xor' two dwords of the set together }
            emitbyt($8b); { mov edx,[eax] }
            emitbyt($10);
            emitbyt($23); { and edx,[ebx] }
            emitbyt($13);
            emitbyt($33); { xor edx,[ebx] }
            emitbyt($13);
            emitbyt($0b); { or edi,edx }
            emitbyt($fa);
            emitbyt($83); { add eax,4 }
            emitbyt($c0);
            emitbyt($04);
            emitbyt($83); { add ebx,4 }
            emitbyt($c3);
            emitbyt($04);
            emitbyt($49); { dec ecx }
            emitbyt($0f); { jnz loop }
            emitbyt($85);
            emitadr(srtstk^.lab, itradr); { place loop jump address }
            { remove both from stack }
            emitbyt($83); { add esp,setsiz*2 }
            emitbyt($c4);
            emitbyt(setsiz*2);
            { test result }
            emitbyt($0b); { or edi,edi }
            emitbyt($ff);
            { convert status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { sete al }
            emitbyt($94);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            popsrt; { remove structure level }
            stack := stack+(2*setsiz)-stksiz { lost two sets, add boolean }

         end;
         ileqrel:   begin

            { get address tos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load to fpu }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { get address sos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { compare }
            emitbyt($dc); { fcompd [eax] }
            emitbyt($18);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { transfer fpu flags to integer unit flags }
            emitbyt($df); { fnstsw ax }
            emitbyt($e0);
            emitbyt($9e); { sahf }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setnb al }
            emitbyt($93);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+(2*rlsiz)-bolsiz { net is less one }

         end;
         ileqstr:  begin

            getlnk(tp); { get string type }
            { load operands }
            emitbyt($5f); { pop edi }
            emitbyt($5e); { pop esi }
            emitbyt($b9); { mov ecx,size }
            emitint(tp^.size); { generate string size }
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setbe al }
            emitbyt($96);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+stksiz { net is less one }

         end;
         ileqgst:  begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            { load both operands }
            emitbyt($5f); { pop edi }
            emitbyt($58); { pop eax }
            emitbyt($5e); { pop esi }
            emitbyt($59); { pop ecx }
            { check lengths equal }
            emitbyt($3b); { cmp eax,ecx }
            emitbyt($c1);
            emitbyt($0f); { je noerror }
            emitbyt($84);
            emitadr(srtstk^.lab, itradr); { place no error address }
            { generate error routine call }
            emitbyt($68); { push rerngchk }
            emitint(ord(relenmat)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab^.addr := pgmcnt; { set jump over error location }
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setbe al }
            emitbyt($96);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            popsrt; { remove structure level }
            { set two tagged pointers replaced by boolean }
            stack := stack+tgpsiz+tgpsiz-bolsiz

         end;
         ileqint:  begin

            { load operands }
            emitbyt($5b); { pop ebx }
            emitbyt($58); { pop eax }
            { compare }
            emitbyt($3b); { cmp eax,ebx }
            emitbyt($c3);
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setle al }
            emitbyt($9e);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+stksiz { net is less one }

         end;
         igeqset:  begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set loop label }
            { load 1st set address }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load 2nd set address }
            emitbyt($8b); { move ebx,esp }
            emitbyt($dc);
            emitbyt($83); { add ebx,setsiz }
            emitbyt($c3);
            emitbyt(setsiz);
            { set size of set in dwords }
            emitbyt($b9); { mov ecx,setsiz div 4 }
            emitint(setsiz div 4);
            { clear flag }
            emitbyt($33); { xor edi,edi } 
            emitbyt($ff);
            srtstk^.lab^.addr := pgmcnt; { set loop location }
            { 'xor' two dwords of the set together }
            emitbyt($8b); { mov edx,[eax] }
            emitbyt($10);
            emitbyt($23); { and edx,[ebx] }
            emitbyt($13);
            emitbyt($33); { xor edx,[eax] }
            emitbyt($10);
            emitbyt($0b); { or edi,edx }
            emitbyt($fa);
            emitbyt($83); { add eax,4 }
            emitbyt($c0);
            emitbyt($04);
            emitbyt($83); { add ebx,4 }
            emitbyt($c3);
            emitbyt($04);
            emitbyt($49); { dec ecx }
            emitbyt($0f); { jnz loop }
            emitbyt($85);
            emitadr(srtstk^.lab, itradr); { place loop jump address }
            { remove both from stack }
            emitbyt($83); { add esp,setsiz*2 }
            emitbyt($c4);
            emitbyt(setsiz*2);
            { test result }
            emitbyt($0b); { or edi,edi }
            emitbyt($ff);
            { convert status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { sete al }
            emitbyt($94);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            popsrt; { remove structure level }
            stack := stack+(2*setsiz)-stksiz { lost two sets, add boolean }

         end;
         igeqrel:   begin

            { get address tos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load to fpu }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { get address sos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { compare }
            emitbyt($dc); { fcompd [eax] }
            emitbyt($18);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { transfer fpu flags to integer unit flags }
            emitbyt($df); { fnstsw ax }
            emitbyt($e0);
            emitbyt($9e); { sahf }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setna al }
            emitbyt($96);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+(2*rlsiz)-bolsiz { net is less one }

         end;
         igeqstr:  begin

            getlnk(tp); { get string type }
            { load operands }
            emitbyt($5f); { pop edi }
            emitbyt($5e); { pop esi }
            emitbyt($b9); { mov ecx,size }
            emitint(tp^.size); { generate string size }
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setae al }
            emitbyt($93);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+stksiz { net is less one }

         end;
         igeqgst:  begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            { load both operands }
            emitbyt($5f); { pop edi }
            emitbyt($58); { pop eax }
            emitbyt($5e); { pop esi }
            emitbyt($59); { pop ecx }
            { check lengths equal }
            emitbyt($3b); { cmp eax,ecx }
            emitbyt($c1);
            emitbyt($0f); { je noerror }
            emitbyt($84);
            emitadr(srtstk^.lab, itradr); { place no error address }
            { generate error routine call }
            emitbyt($68); { push rerngchk }
            emitint(ord(relenmat)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab^.addr := pgmcnt; { set jump over error location }
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setae al }
            emitbyt($93);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            popsrt; { remove structure level }
            { set two tagged pointers replaced by boolean }
            stack := stack+tgpsiz+tgpsiz-bolsiz

         end;
         igeqint:  begin

            { load operands }
            emitbyt($5b); { pop ebx }
            emitbyt($58); { pop eax }
            { compare }
            emitbyt($3b); { cmp eax,ebx }
            emitbyt($c3);
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setle al }
            emitbyt($9d);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+stksiz { net is less one }

         end;
         iltnrel:   begin

            { get address tos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load to fpu }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { get address sos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { compare }
            emitbyt($dc); { fcompd [eax] }
            emitbyt($18);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { transfer fpu flags to integer unit flags }
            emitbyt($df); { fnstsw ax }
            emitbyt($e0);
            emitbyt($9e); { sahf }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { seta al }
            emitbyt($97);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+(2*rlsiz)-bolsiz { net is less one }

         end;
         iltnstr:  begin

            getlnk(tp); { get string type }
            { load operands }
            emitbyt($5f); { pop edi }
            emitbyt($5e); { pop esi }
            emitbyt($b9); { mov ecx,size }
            emitint(tp^.size); { generate string size }
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setb al }
            emitbyt($92);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+stksiz { net is less one }

         end;
         iltngst:  begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            { load both operands }
            emitbyt($5f); { pop edi }
            emitbyt($58); { pop eax }
            emitbyt($5e); { pop esi }
            emitbyt($59); { pop ecx }
            { check lengths equal }
            emitbyt($3b); { cmp eax,ecx }
            emitbyt($c1);
            emitbyt($0f); { je noerror }
            emitbyt($84);
            emitadr(srtstk^.lab, itradr); { place no error address }
            { generate error routine call }
            emitbyt($68); { push rerngchk }
            emitint(ord(relenmat)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab^.addr := pgmcnt; { set jump over error location }
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setb al }
            emitbyt($92);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            popsrt; { remove structure level }
            { set two tagged pointers replaced by boolean }
            stack := stack+tgpsiz+tgpsiz-bolsiz

         end;
         iltnint:  begin

            { load operands }
            emitbyt($5b); { pop ebx }
            emitbyt($58); { pop eax }
            { compare }
            emitbyt($3b); { cmp eax,ebx }
            emitbyt($c3);
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setl al }
            emitbyt($9c);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+stksiz { net is less one }

         end;
         igtnrel:   begin

            { get address tos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { load to fpu }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { get address sos }
            emitbyt($8b); { move eax,esp }
            emitbyt($c4);
            { compare }
            emitbyt($dc); { fcompd [eax] }
            emitbyt($18);
            { remove from stack }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { transfer fpu flags to integer unit flags }
            emitbyt($df); { fnstsw ax }
            emitbyt($e0);
            emitbyt($9e); { sahf }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setb al }
            emitbyt($92);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+(2*rlsiz)-bolsiz { net is less one }

         end;
         igtnstr:  begin

            getlnk(tp); { get string type }
            { load operands }
            emitbyt($5f); { pop edi }
            emitbyt($5e); { pop esi }
            emitbyt($b9); { mov ecx,size }
            emitint(tp^.size); { generate string size }
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { seta al }
            emitbyt($97);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+stksiz { net is less one }

         end;
         igtngst:  begin

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            { load both operands }
            emitbyt($5f); { pop edi }
            emitbyt($58); { pop eax }
            emitbyt($5e); { pop esi }
            emitbyt($59); { pop ecx }
            { check lengths equal }
            emitbyt($3b); { cmp eax,ecx }
            emitbyt($c1);
            emitbyt($0f); { je noerror }
            emitbyt($84);
            emitadr(srtstk^.lab, itradr); { place no error address }
            { generate error routine call }
            emitbyt($68); { push rerngchk }
            emitint(ord(relenmat)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab^.addr := pgmcnt; { set jump over error location }
            { search first non-matching byte }
            emitbyt($f3); { repe }
            emitbyt($a6); { cmpsb }
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setb al }
            emitbyt($97);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            popsrt; { remove structure level }
            { set two tagged pointers replaced by boolean }
            stack := stack+tgpsiz+tgpsiz-bolsiz

         end;
         igtnint:  begin

            { load operands }
            emitbyt($5b); { pop ebx }
            emitbyt($58); { pop eax }
            { compare }
            emitbyt($3b); { cmp eax,ebx }
            emitbyt($c3);
            { convert equal status to truth value }
            emitbyt($b8); { mov eax,0 }
            emitint(0);
            emitbyt($0f); { setg al }
            emitbyt($9f);
            emitbyt($c0);
            { place result }
            emitbyt($50); { push eax }
            stack := stack+stksiz { net is less one }

         end;
         ibgnblk:  ; { begin statement block. not used }
         iendblk:  ; { end statement block. not used }
         iifbgn:   begin { if }

            { 'if' is converted to jumps }
            pushsrt; { add new structure level }
            gettypa(srtstk^.lab, tlab); { get a label type for false destination }
            { load boolean }
            emitbyt($58); { pop eax }
            { place in flags }
            emitbyt($0b); { or eax,eax }
            emitbyt($c0);
            { jump false }
            emitbyt($0f); { jz addr }
            emitbyt($84);
            emitadr(srtstk^.lab, itradr); { place address }
            stack := stack+stksiz { net is less one }

         end;
         ielse:    begin

            tp := srtstk^.lab; { save false destination }
            gettypa(srtstk^.lab, tlab); { get a label type for true destination }
            { output jump over for 'if' first part }
            emitbyt($e9); { jmp addr }
            emitadr(srtstk^.lab, itradr);
            tp^.addr := pgmcnt { place address of 'if' skip }

         end;
         iifend:   begin

            srtstk^.lab^.addr := pgmcnt; { place address of 'if' or 'else' skip }
            popsrt { remove structure level }

         end;
         icasbgn:  begin { case begin }

            { 'case' is converted to jumps }
            pushsrt; { add new structure level }
            gettypa(srtstk^.lab, tlab); { get a label for exit }
            srtstk^.lab1 := nil { clear skip label }
            
         end;
         icassint:  begin { case select integer }

            rdnum(v); { get case selector constant }
            { load selector, but leave on stack }
            emitbyt($58); { pop eax }
            emitbyt($50); { push eax }
            { compare to case label }
            emitbyt($3d); { cmp eax,imm }
            emitint(v); { place value }
            if srtstk^.lab1 = nil then { skip label is not already defined }
               gettypa(srtstk^.lab1, tlab); { get a label for skip }
            { jump to statement if equal }
            emitbyt($0f); { je addr }
            emitbyt($84);
            emitadr(srtstk^.lab1, itradr)

         end;
         icasstb:  begin { case statement begin }

            gettypa(srtstk^.lab2, tlab); { get a jump over }
            { jump to next case }
            emitbyt($e9); { jmp addr }
            emitadr(srtstk^.lab2, itradr); { generate address }
            srtstk^.lab1^.addr := pgmcnt; { set location of jump to statment }
            srtstk^.lab1 := nil { release skip label }

         end;
         icasste:  begin { case statement end }

            { jump to exit }
            emitbyt($e9); { jmp addr }
            emitadr(srtstk^.lab, itradr); { generate address }
            srtstk^.lab2^.addr := pgmcnt { set location of jump over }

         end;
         icasend:  begin { case end }

            { generate error routine call for missed case }
            emitbyt($68); { push rerngchk }
            emitint(ord(recasvnf)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab^.addr := pgmcnt; { place address of case exit }
            { generate pop of case selector }
            emitbyt($58); { pop eax }
            popsrt; { remove structure level }
            stack := stack+stksiz { net is less one }

         end;
         iwhlexp:  begin { While expression marker }

            pushsrt; { start new structure level }
            gettypa(srtstk^.lab, tlab); { get label for loop jump }
            srtstk^.lab^.addr := pgmcnt; { set location }
            gettypa(srtstk^.lab1, tlab) { get label for skip }

         end;
         iwhlbgn:  begin { While begin }

            { while is converted to jumps }
            emitbyt($58); { pop eax }
            { jump if false }
            emitbyt($0b); { or eax,eax }
            emitbyt($c0);
            emitbyt($0f); { jz addr }
            emitbyt($84);
            emitadr(srtstk^.lab1, itradr); { to skip label }
            stack := stack+stksiz { net is less one }

         end;
         iwhlend:  begin { While end }

            { jump to loop label }
            emitbyt($e9); { jmp addr }
            emitadr(srtstk^.lab, itradr); { generate address }
            srtstk^.lab1^.addr := pgmcnt; { place address of skip }
            popsrt { remove structure level }

         end;
         irptbgn:  begin { Repeat begin }

            { repeat is converted to jumps }
            pushsrt; { add new structure level }
            gettypa(srtstk^.lab, tlab); { get label for loop jump }
            srtstk^.lab^.addr := pgmcnt { set location }

         end;            
         irptend:  begin { Repeat end }

            emitbyt($58); { pop eax }
            { jump to loop label if false }
            emitbyt($0b); { or eax,eax }
            emitbyt($c0);
            emitbyt($0f); { jz addr }
            emitbyt($84);
            emitadr(srtstk^.lab, itradr); { generate address }
            popsrt; { remove structure level }
            stack := stack+stksiz { net is less one }

         end;
         ifortint, ifortchr, ifortbol, ifordint, ifordchr,
         ifordbol:  begin { for loop }

            pushsrt; { start new structure level } 
            srtstk^.ic := ic; { save head type }
            getlnk(tp); { get variable }
            { get start and end }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { save end on stack }
            emitbyt($50); { push eax }
            { load address of variable }
            if tp^.local then begin { local address }

               { get the display }
               emitbyt($8b); { mov ecx,ebp }
               emitbyt($cd);
               { offset to local }
               emitbyt($81); { add ecx,imm }
               emitbyt($c1);
               emitint(tp^.addr) { place offset address }

            end else begin { load global address }

               { load global address }
               emitbyt($b9); { mov ecx,imm }
               emitadr(tp, itadr) { place address }

            end;
            { store integer to control variable }
            if tp^.size = 4 then begin { full integer }

               emitbyt($89); { mov [ecx],ebx }
               emitbyt($19)

            end else if tp^.size = 2 then begin

               emitbyt($66); { mov [ecx],bx }
               emitbyt($89);
               emitbyt($19)

            end else if tp^.size = 1 then begin

               emitbyt($88); { mov [ecx],al }
               emitbyt($19)

            end else error(einvfmt); { bad size }
            gettypa(srtstk^.lab1, tlab); { get label for skip }
            { compare to end value }
            emitbyt($3b); { cmp eax,ebx }
            emitbyt($c3);
            if ic in [ifortint, ifortchr, ifortbol] then begin { to }

               emitbyt($0f); { jl end }
               emitbyt($8c)
            
            end else begin { downto }

               emitbyt($0f); { jg end }
               emitbyt($8f)

            end;
            emitadr(srtstk^.lab1, itradr); { to skip label }
            srtstk^.lab2 := tp; { save variable }
            gettypa(srtstk^.lab, tlab); { get label for loop jump }
            srtstk^.lab^.addr := pgmcnt; { set location }
            stack := stack+stksiz { net is less one }

         end;
         iforend:  begin { For end }

            tp := srtstk^.lab2; { get control variable }
            { get end value and leave on stack }
            emitbyt($5b); { pop ebx }
            emitbyt($53); { push ebx }
            { load address of variable }
            if tp^.local then begin { local address }

               { get the display }
               emitbyt($8b); { mov ecx,ebp }
               emitbyt($cd);
               { offset to local }
               emitbyt($81); { add ecx,imm }
               emitbyt($c1);
               emitint(tp^.addr) { place offset address }

            end else begin { load global address }

               { load global address }
               emitbyt($b9); { mov ecx,imm }
               emitadr(tp, itadr) { place address }

            end;
            { load variable value }
            if tp^.size = 4 then begin { integer }

               emitbyt($8b); { mov eax,[ecx] }
               emitbyt($01)

            end else if tp^.size = 2 then begin { word }

               if chksgn(tp) then begin { signed }

                  emitbyt($0f); { movsxw eax,[ecx] }
                  emitbyt($bf);
                  emitbyt($01)

               end else begin { unsigned }

                  emitbyt($0f); { movzxw eax,[ecx] }
                  emitbyt($b7);
                  emitbyt($01)

               end

            end else if tp^.size = 1 then begin { byte }

               if chksgn(tp) then begin { signed }

                  emitbyt($0f); { movsxb eax,[ecx] }
                  emitbyt($be);
                  emitbyt($01)

               end else begin { unsigned }

                  emitbyt($0f); { movzxb eax,[ecx] }
                  emitbyt($b6);
                  emitbyt($01)

               end

            end else error(einvfmt); { invalid format }
            { compare to end value }
            emitbyt($3b); { cmp eax,ebx }
            emitbyt($c3);
            if srtstk^.ic in [ifortint, ifortchr, ifortbol] then begin { to }

               emitbyt($0f); { jnl end }
               emitbyt($8d)
            
            end else begin { downto }

               emitbyt($0f); { jng end }
               emitbyt($8e)

            end;
            emitadr(srtstk^.lab1, itradr); { to skip label }
            { find next value }
            if tp^.size = 4 then begin { integer }

               if srtstk^.ic in [ifortint, ifortchr, ifortbol] then begin

                  { to }
                  emitbyt($ff); { incd [ecx] }
                  emitbyt($01)

               end else begin { downto }

                  emitbyt($ff); { decd [ecx] }
                  emitbyt($09)

               end

            end else if tp^.size = 2 then begin { word }

               if srtstk^.ic in [ifortint, ifortchr, ifortbol] then begin

                  { to }
                  emitbyt($66); { incw [ecx] }
                  emitbyt($ff);
                  emitbyt($01)

               end else begin { downto }

                  emitbyt($66); { decw [ecx] }
                  emitbyt($ff);
                  emitbyt($09)

               end

            end else if tp^.size = 1 then begin { byte }

               if srtstk^.ic in [ifortint, ifortchr, ifortbol] then begin

                  { to }
                  emitbyt($fe); { incb [ecx] }
                  emitbyt($01)

               end else begin { downto }

                  emitbyt($fe); { decb [ecx] }
                  emitbyt($09)

               end

            end else error(einvfmt); { bad size }
            { jump to loop label }
            emitbyt($e9); { jmp loop }
            emitadr(srtstk^.lab, itradr);
            srtstk^.lab1^.addr := pgmcnt; { place address of skip }
            { purge end value }
            emitbyt($58); { pop eax }
            popsrt; { remove structure level }
            stack := stack+stksiz { net is less one }

         end;
         iwthbgn:  begin { 'with' begin }

            getlnk(tp); { get record type }
            pushsrt; { add new structure level }
            srtstk^.lab := tp; { set record type }
            srtstk^.withm := true; { set marks a 'with' }
            srtstk^.off := stack { place stack offset to access base }

         end;
         iwthend:  begin { 'with' end }
            
            { remove base address }
            emitbyt($58); { pop eax }
            popsrt; { remove structure level }
            stack := stack+stksiz { adjust stack }

         end;
         igoto:    begin { goto }

            getlnk(tp); { get label to jump to }
            { load stack from target display }
            { get display for target level }
            if tp^.lmrk^.t = tglbl then begin

               { on main blocks, we use the saved display, since there is no
                 way to find the original display for that block }
               emitbyt($8b); { mov eax,[dispsav] }
               emitbyt($05);
               emitadr(tp^.lmrk^.ds, itadr) { place display save address }

            end else begin { normal block }

               emitbyt($8b); { mov eax,[ebp-lvl] }
               emitbyt($85);
               emitint(-((tp^.level-1)*4)); { offset to proper display level }

            end;
            { load target ebp from display }
            emitbyt($8b); { move ebp,eax }
            emitbyt($e8);
            { offset to local }
            emitbyt($05); { add eax,imm }
            { offset by mark type }
            if tp^.lmrk^.t = tglbl then emitint(-((tp^.level-1)*4))
            else if tp^.lmrk^.t = tproc then emitint(-((tp^.level-1)*4+tp^.lmrk^.prcv))
            else if tp^.lmrk^.t = tfunc then emitint(-((tp^.level-1)*4+tp^.lmrk^.fncv))
            else error(esysflt); { bad }
            emitbyt($8b); { mov esp,eax }
            emitbyt($e0);
            emitbyt($e9); { jmp label }
            emitadr(tp, itradr) { generate code address }

         end;
         iprcbgn:   getlnk(tp); { get and discard procedure entry }
         iprccal:   begin

            getlnk(tp); { get procedure entry }
            if tp^.t <> tproc then error(einvfmt); { bad format }
            tp^.prcr := true; { set referenced }
            { call procedure }
            emitbyt($e8); { call addr }
            emitadr(tp, itradr); { generate address }
            stack := stack+tp^.prca { remove parameters from stack }

         end;
         iprccali:  begin

            getlnk(tp); { get procedure entry }
            if tp^.t <> tpproc then error(einvfmt); { bad format }
            { call procedure indirect }
            emitbyt($58); { pop eax }
            emitbyt($ff); { call eax }
            emitbyt($d0);
            stack := stack+tp^.ppra+stksiz { remove parameters from stack }

         end;
         ifncbgn:   begin

            getlnk(tp); { get function entry }
            { link function result }
            if tp^.t = tfunc then tp := tp^.fncr
            else if tp^.t = tpfunc then tp := tp^.pfnr
            else error(einvfmt); { bad entry type }
            { place dummy function result }
            emitbyt($68); { push 0 }
            emitint(0);
            stack := stack-stksiz; { add result to stack }
            if tp^.size > stksiz then begin { real or complex pointer }

               emitbyt($68); { push 0 }
               emitint(0);
               stack := stack-stksiz { add result to stack }

            end;

         end;
         ifnccal:   begin

            getlnk(tp); { get function entry }
            if tp^.t <> tfunc then error(einvfmt); { bad format }
            tp^.fnct := true; { set referenced }
            { call function }
            emitbyt($e8); { call addr }
            emitadr(tp, itradr); { generate address }
            stack := stack+tp^.fnca { remove parameters from stack }

         end;
         ifnccali:  begin

            getlnk(tp); { get function entry }
            if tp^.t <> tpfunc then error(einvfmt); { bad format }
            { call function indirect }
            emitbyt($58); { pop eax }
            emitbyt($ff); { call eax }
            emitbyt($d0);
            stack := stack+tp^.pfna+stksiz { remove parameters from stack }

         end;
         iwrtsrc:   begin

            getlnk(tp); { get variable type }
            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { place copy of the file on stack }
            emitbyt($53); { push ebx }
            { place file }
            emitbyt($53); { push ebx }
            { place length on stack }
            emitbyt($68); { push size }
            emitint(tp^.size);
            { place address }
            emitbyt($50); { push eax }
            { call file write routine }
            emitbyt($e8); { call ps_wrtfil }
            emitadr(pswrtfil, itradr); { output routine address }
            pswrtfil^.rotr := true; { set referenced }
            stack := stack+stksiz { net is less one }

         end;
         iwrtintt:   begin

            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { place copy of the file on stack }
            emitbyt($53); { push ebx }
            { replace operands }
            emitbyt($53); { push ebx }
            { place standard integer field }
            emitbyt($68); { push intfld }
            emitint(intfld);
            emitbyt($50); { push eax }
            { call integer write routine }
            emitbyt($e8); { call ps_wrtint }
            emitadr(pswrtint, itradr); { output routine address }
            pswrtint^.rotr := true; { set referenced }
            stack := stack+stksiz { net is less one }

         end;
         iwrtchrt:   begin

            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { place copy of the file on stack }
            emitbyt($53); { push ebx }
            { replace operands }
            emitbyt($53); { push ebx }
            { place standard character field }
            emitbyt($68); { push chrfld }
            emitint(chrfld);
            emitbyt($50); { push eax }
            { call character write routine }
            emitbyt($e8); { call ps_wrtchr }
            emitadr(pswrtchr, itradr); { output routine address }
            pswrtchr^.rotr := true; { set referenced }
            stack := stack+stksiz { net is less one }

         end;
         iwrtbolt:   begin

            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { place copy of the file on stack }
            emitbyt($53); { push ebx }
            { replace operands }
            emitbyt($53); { push ebx }
            emitbyt($50); { push eax }
            { call boolean write routine }
            emitbyt($e8); { call ps_wrtbol }
            emitadr(pswrtbol, itradr); { output routine address }
            pswrtbol^.rotr := true; { set referenced }
            stack := stack+stksiz { net is less one }

         end;
         iwrtrelt:    begin

            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            emitbyt($59); { pop ecx }
            { place copy of the file on stack }
            emitbyt($51); { push ecx }
            { replace operands }
            emitbyt($51); { push ecx }
            { place standard real field }
            emitbyt($68); { push rlfld }
            emitint(rlfld);
            emitbyt($53); { push ebx }
            emitbyt($50); { push eax }
            { call real write routine }
            emitbyt($e8); { call ps_wrtreal }
            emitadr(pswrtreal, itradr); { output routine address }
            pswrtreal^.rotr := true; { set referenced }
            stack := stack+rlsiz { net is less one }

         end;
         iwrtstrt:   begin { write string }

            getlnk(tp); { get string type }
            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { place copy of the file on stack }
            emitbyt($53); { push ebx }
            { replace operands }
            emitbyt($53); { push ebx }
            { place length of string as tag length }
            emitbyt($68); { push len }
            emitint(tp^.size);
            emitbyt($50); { push eax }
            { call string write routine }
            emitbyt($e8); { call ps_wrtstr }
            emitadr(pswrtstr, itradr); { output routine address }
            pswrtstr^.rotr := true; { set referenced }
            stack := stack+stksiz { net is less one }

         end;
         iwrtgstt:   begin { write string }

            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            emitbyt($59); { pop ecx }
            { place copy of the file on stack }
            emitbyt($51); { push ecx }
            { replace operands }
            emitbyt($51); { push ecx } 
            emitbyt($53); { push ebx }
            emitbyt($50); { push eax }
            { call string write routine }
            emitbyt($e8); { call ps_wrtstr }
            emitadr(pswrtstr, itradr); { output routine address }
            pswrtstr^.rotr := true; { set referenced }
            stack := stack+tgpsiz { net is less one }

         end;
         iwrtintft:  begin

            { load operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            emitbyt($59); { pop ecx }
            { place copy of the file on stack }
            emitbyt($51); { push ecx }
            { replace operands, reversing field and integer }
            emitbyt($51); { push ecx }
            emitbyt($50); { push eax }
            emitbyt($53); { push ebx }
            { call integer write routine }
            emitbyt($e8); { call ps_wrtreal }
            emitadr(pswrtint, itradr); { output routine address }
            pswrtint^.rotr := true; { set referenced }
            stack := stack+(2*stksiz) { net is less two }

         end;
         iwrtchrft:  begin

            { load operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            emitbyt($59); { pop ecx }
            { place copy of the file on stack }
            emitbyt($51); { push ecx }
            { replace operands, reversing field and character }
            emitbyt($51); { push ecx }
            emitbyt($50); { push eax }
            emitbyt($53); { push ebx }
            { call character write routine }
            emitbyt($e8); { call ps_wrtchr }
            emitadr(pswrtchr, itradr); { output routine address }
            pswrtchr^.rotr := true; { set referenced }
            stack := stack+(2*stksiz) { net is less two }

         end;
         iwrtbolft:  begin

            { load operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            emitbyt($59); { pop ecx }
            { place copy of the file on stack }
            emitbyt($51); { push ecx }
            { replace operands, reversing field and boolean }
            emitbyt($51); { push ecx }
            emitbyt($50); { push eax }
            emitbyt($53); { push ebx }
            { call boolean write fielded routine }
            emitbyt($e8); { call ps_wrtbol }
            emitadr(pswrtblf, itradr); { output routine address }
            pswrtblf^.rotr := true; { set referenced }
            stack := stack+(2*stksiz) { net is less two }

         end;
         iwrtrelft:   begin

            { load operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            emitbyt($59); { pop ecx }
            emitbyt($5a); { pop edx }
            { place copy of the file on stack }
            emitbyt($52); { push edx }
            { replace operands, reversing field and real }
            emitbyt($52); { push edx }
            emitbyt($50); { push eax }
            emitbyt($51); { push ecx }
            emitbyt($53); { push ebx }
            { call real write routine }
            emitbyt($e8); { call ps_wrtreal }
            emitadr(pswrtreal, itradr); { output routine address }
            pswrtreal^.rotr := true; { set referenced }
            stack := stack+stksiz+rlsiz { net is less two }

         end;
         iwrtstrft:  begin { write string fielded }

            getlnk(tp); { get string type }
            { get field }
            emitbyt($58); { pop eax }
            { get string }
            emitbyt($5b); { pop ebx }
            { get file }
            emitbyt($59); { pop ecx }
            { place copy of the file on stack }
            emitbyt($51); { push ecx }
            { place file }
            emitbyt($51); { push ecx }
            { place field }
            emitbyt($50); { push eax }
            { place length of string as tag length }
            emitbyt($68); { push len }
            emitint(tp^.size);
            { place string }
            emitbyt($53); { push ebx }
            { call string write routine }
            emitbyt($e8); { call ps_wrtstr }
            emitadr(pswrtstrf, itradr); { output routine address }
            pswrtstrf^.rotr := true; { set referenced }
            stack := stack+(2*stksiz) { net is less two }

         end;
         iwrtgstft:  begin { write general string fielded }

            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            emitbyt($59); { pop ecx }
            emitbyt($5a); { pop edx }
            { place copy of the file on stack }
            emitbyt($52); { push edx }
            { replace operands }
            emitbyt($52); { push edx }
            emitbyt($51); { push ecx }
            emitbyt($53); { push ebx }
            emitbyt($50); { push eax }
            { call string write routine }
            emitbyt($e8); { call ps_wrtstr }
            emitadr(pswrtstrf, itradr); { output routine address }
            pswrtstrf^.rotr := true; { set referenced }
            stack := stack+intsiz+tgpsiz { net is less two }

         end;
         iwrtrelfft:  begin

            { load operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            emitbyt($59); { pop ecx }
            emitbyt($5a); { pop edx }
            emitbyt($5f); { pop edi }
            { place copy of the file on stack }
            emitbyt($57); { push edi }
            { replace operands, reversing field/fraction and real }
            emitbyt($57); { push edi }
            emitbyt($53); { push ebx }
            emitbyt($50); { push eax }
            emitbyt($52); { push edx }
            emitbyt($51); { push ecx }
            { call real write fixed routine }
            emitbyt($e8); { call ps_wrtrlf }
            emitadr(pswrtrlf, itradr); { output routine address }
            pswrtrlf^.rotr := true; { set referenced }
            stack := stack+(2*stksiz)+rlsiz { net is less three }

         end;
         iwrtsrl:  begin

            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { place copy of the file on stack }
            emitbyt($53); { push ebx }
            { place real on stack }
            emitbyt($50); { push eax }
            { index that }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { place file on stack }
            emitbyt($53); { push ebx }
            { place length on stack }
            emitbyt($6a); { push size }
            emitbyt(srlsiz);
            { place pointer to real on stack }
            emitbyt($50); { push eax }
            { call file write routine }
            emitbyt($e8); { call ps_wrtfil }
            emitadr(pswrtfil, itradr); { output routine address }
            pswrtfil^.rotr := true; { set referenced }
            { remove stacked real }
            emitbyt($58); { pop eax }
            stack := stack+stksiz { net is less one }

         end;
         iwrtrel:   begin

            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            emitbyt($59); { pop ecx }
            { place copy of the file on stack }
            emitbyt($51); { push ecx }
            { place real on stack }
            emitbyt($53); { push ebx }
            emitbyt($50); { push eax }
            { index that }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { place file on stack }
            emitbyt($51); { push ecx }
            { place length on stack }
            emitbyt($6a); { push size }
            emitbyt(rlsiz);
            { place pointer to real on stack }
            emitbyt($50); { push eax }
            { call file write routine }
            emitbyt($e8); { call ps_wrtfil }
            emitadr(pswrtfil, itradr); { output routine address }
            pswrtfil^.rotr := true; { set referenced }
            { remove stacked real }
            emitbyt($58); { pop eax }
            emitbyt($58); { pop eax }
            stack := stack+rlsiz { net is less one }

         end;
         iwrtset:  begin

            { we cannot "pop" a set, so we must get the file pointer we need
              from under the set }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            emitbyt($83); { add eax,setsiz }
            emitbyt($c0);
            { get the file pointer }
            emitbyt($8b); { mov ebx,[eax] }
            emitbyt($18);
            { index the set }
            emitbyt($83); { add eax,setsiz }
            emitbyt($c0);
            emitbyt(setsiz);
            { place file }
            emitbyt($53); { push ebx }
            { place length on stack }
            emitbyt($6a); { push size }
            emitbyt(setsiz);
            { place set address }
            emitbyt($50); { push eax }
            { call file write routine }
            emitbyt($e8); { call ps_wrtfil }
            emitadr(pswrtfil, itradr); { output routine address }
            pswrtfil^.rotr := true; { set referenced }
            { remove set from stack }
            emitbyt($83); { add esp,setsiz }
            emitbyt($c4);
            emitbyt(setsiz);
            stack := stack+setsiz { net less one set }

         end;
         iwrtchr, iwrtbol:  begin

            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { place copy of the file on stack }
            emitbyt($53); { push ebx }
            { place character/boolean on stack }
            emitbyt($50); { push eax }
            { index that }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { place file on stack }
            emitbyt($53); { push ebx }
            { place length on stack }
            emitbyt($6a); { push size }
            emitbyt(1);
            { place pointer to character/boolean on stack }
            emitbyt($50); { push eax }
            { call file write routine }
            emitbyt($e8); { call ps_wrtfil }
            emitadr(pswrtfil, itradr); { output routine address }
            pswrtfil^.rotr := true; { set referenced }
            { remove stacked character/boolean }
            emitbyt($58); { pop eax }
            stack := stack+stksiz { net is less one }
            
         end;
         iwrtint:  begin

            getlnk(tp); { get type }
            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { place copy of the file on stack }
            emitbyt($53); { push ebx }
            { place integer on stack }
            emitbyt($50); { push eax }
            { index that }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { place file on stack }
            emitbyt($53); { push ebx }
            { place length on stack }
            emitbyt($6a); { push size }
            emitbyt(tp^.size);
            { place pointer to integer on stack }
            emitbyt($50); { push eax }
            { call file write routine }
            emitbyt($e8); { call ps_wrtfil }
            emitadr(pswrtfil, itradr); { output routine address }
            pswrtfil^.rotr := true; { set referenced }
            { remove stacked integer }
            emitbyt($58); { pop eax }
            stack := stack+stksiz { net is less one }

         end;
         iwrteolt:  begin { write file end of line }

            { duplicate the file }
            emitbyt($58); { pop eax }
            emitbyt($50); { push eax }
            emitbyt($50); { push eax }
            { call file write eoln routine }
            emitbyt($e8); { call ps_wrteol }
            emitadr(pswrteol, itradr); { output routine address }
            pswrteol^.rotr := true { set referenced }

         end;
         iredsrc:    begin { read file }

            getlnk(tp); { get variable type }
            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { place copy of the file on stack }
            emitbyt($53); { push ebx }
            { place file }
            emitbyt($53); { push ebx }
            { place length on stack }
            emitbyt($68); { push size }
            emitint(tp^.size);
            { place variable address }
            emitbyt($50); { push eax }
            { call file read routine }
            emitbyt($e8); { call ps_rdfil }
            emitadr(psrdfil, itradr); { output routine address }
            psrdfil^.rotr := true; { set referenced }
            stack := stack+stksiz { net is less one }

         end;
         iredintt:    begin

            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { place copy of the file on stack }
            emitbyt($53); { push ebx }
            { place file }
            emitbyt($53); { push ebx }
            { place variable address }
            emitbyt($50); { push eax }
            { call integer read routine }
            emitbyt($e8); { call ps_rdint }
            emitadr(psrdint, itradr); { output routine address }
            psrdint^.rotr := true; { set referenced }
            stack := stack+stksiz { net is less one }
            
         end;
         iredchrt:    begin

            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { place copy of the file on stack }
            emitbyt($53); { push ebx }
            { place file }
            emitbyt($53); { push ebx }
            { place variable address }
            emitbyt($50); { push eax }
            { call character read routine }
            emitbyt($e8); { call ps_rdchr }
            emitadr(psrdchr, itradr); { output routine address }
            psrdchr^.rotr := true; { set referenced }
            stack := stack+stksiz { net is less one }

         end;
         iredrelt:     begin

            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { place copy of the file on stack }
            emitbyt($53); { push ebx }
            { place file }
            emitbyt($53); { push ebx }
            { place variable address }
            emitbyt($50); { push eax }
            { call real read routine }
            emitbyt($e8); { call ps_rdreal }
            emitadr(psrdreal, itradr); { output routine address }
            psrdreal^.rotr := true; { set referenced }
            stack := stack+stksiz { net is less one }

         end;
         iredsrlt:    begin

            { load both operands }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { place copy of the file on stack }
            emitbyt($53); { push ebx }
            { save destination }
            emitbyt($50); { push eax }
            { place file }
            emitbyt($53); { push ebx }
            { establish buffer on stack }
            emitbyt($83); { add esp,-rlsiz }
            emitbyt($c4);
            emitbyt(256-rlsiz);
            { index that }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { call real read routine }
            emitbyt($e8); { call ps_rdreal }
            emitadr(psrdreal, itradr); { output routine address }
            psrdreal^.rotr := true; { set referenced }
            { index result }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load real }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { remove real buffer }
            emitbyt($83); { add esp,rlsiz }
            emitbyt($c4);
            emitbyt(rlsiz);
            { get destination address }
            emitbyt($58); { pop eax }
            { store short real }
            emitbyt($d9); { fstps [eax] }
            emitbyt($18);
            { sync store }
            emitbyt($9b); { fwait }
            stack := stack+stksiz { net is less one }

         end;
         iredeolt:   begin { read file end of line }

            { duplicate file parameter }
            emitbyt($58); { pop eax }
            emitbyt($50); { push eax }
            emitbyt($50); { push eax }
            { call real eoln routine }
            emitbyt($e8); { call ps_rdeol }
            emitadr(psrdeol, itradr); { output routine address }
            psrdeol^.rotr := true { set referenced }

         end;
         iabsrel:    begin { Abs of real }

            { index real on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load real }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { find abs }
            emitbyt($d9); { fabs }
            emitbyt($e1);
            { store real }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync store }
            emitbyt($9b) { fwait }

         end;
         iabsint:   begin { Abs of integer }

            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set skip label }
            { get operand }
            emitbyt($58); { pop eax }
            { find sign }
            emitbyt($0b); { or eax,eax }
            emitbyt($c0);
            { skip not signed }
            emitbyt($0f); { jns over }
            emitbyt($89);
            emitadr(srtstk^.lab, itradr); { place skip address }
            { remove sign }
            emitbyt($f7); { neg eax }
            emitbyt($d8);
            srtstk^.lab^.addr := pgmcnt; { set skip location }
            { replace on stack }
            emitbyt($50); { push eax }
            popsrt; { remove structure level }
            
         end;
         isqrrel:    begin { Sqr of real }

            { index real on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load real }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { multiply by itself for sqr }
            emitbyt($d8); { fmul st,st }
            emitbyt($c8);
            { store short real }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync store }
            emitbyt($9b) { fwait }

         end;
         isqrint:   begin { Sqr of integer }

            { load operand }
            emitbyt($58); { pop eax }
            { mutiply by itself to find sqr }
            emitbyt($f7); { imul eax }
            emitbyt($e8);
            { replace on stack }
            emitbyt($50); { push eax }
            
         end;
         iatnrel:    begin { Arctan of real }

            { index real on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load real }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { load 1.0 }
            emitbyt($d9); { fld1 }
            emitbyt($e8);
            { find arctan }
            emitbyt($d9); { fpatan }
            emitbyt($f3);
            { store real }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync store }
            emitbyt($9b) { fwait }
            
         end;
         icosrel:    begin { Cos of real }

            { index real on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load real }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { find cosine }
            emitbyt($d9); { fcos }
            emitbyt($ff);
            { store real }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync store }
            emitbyt($9b) { fwait }
            
         end;
         iexprel:    begin { Exp of real }

            { beats me: this will leave it alone on stack }

         end;
         ilgnrel:     begin { ln of real }

            { load log2e }
            emitbyt($d9); { fldl2e }
            emitbyt($ea);
            { index real on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load real }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { find natural log }
            emitbyt($d9); { fyl2x }
            emitbyt($f1);
            { store real }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync store }
            emitbyt($9b) { fwait }

         end;
         isinrel:    begin { Sin of real }

            { index real on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load real }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { find sine }
            emitbyt($d9); { fsin }
            emitbyt($fe);
            { store real }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync store }
            emitbyt($9b) { fwait }
            
         end;
         isqtrel:    begin { Sqrt of real }

            { index real on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load real }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { find sqrt }
            emitbyt($d9); { fsqrt }
            emitbyt($fa);
            { store real }
            emitbyt($dd); { fstpd [eax] }
            emitbyt($18);
            { sync store }
            emitbyt($9b) { fwait }

         end;
         ieolt:     begin { Eoln of file }

            { get file }
            emitbyt($58); { pop eax }
            { allocate return value }
            emitbyt($50); { push eax }
            { place file on stack }
            emitbyt($50); { push eax }
            { call eoln check routine }
            emitbyt($e8); { call ps_chkeol }
            emitadr(pschkeol, itradr); { output routine address }
            pschkeol^.rotr := true { set referenced }

         end;
         ieof:      begin { Eof of file }

            getlnk(tp); { get file type }
            tp1 := baset(tp); { find base type }
            { get file }
            emitbyt($58); { pop eax }
            { allocate return value }
            emitbyt($50); { push eax }
            { place file on stack }
            emitbyt($50); { push eax }
            { call eof check routine }
            emitbyt($e8); { call routine }
            if tp1^.t = ttext then begin

               emitadr(pseoftxt, itradr); { output routine address }
               pseoftxt^.rotr := true { set referenced }

            end else begin

               emitadr(pseoffil, itradr); { output routine address }
               pseoffil^.rotr := true { set referenced }

            end
         
         end;
         iodd:      begin { Odd of integer }

            { get integer }
            emitbyt($58); { pop eax }
            { mask all but 1st bit }
            emitbyt($83); { and eax,1 }
            emitbyt($e0);
            emitbyt(1);
            { replace on stack }
            emitbyt($50) { push eax }

         end;
         isucint:   begin { Succ of integer }

            { get integer }
            emitbyt($58); { pop eax }
            { increment }
            emitbyt($40); { inc eax }
            { replace on stack }
            emitbyt($50) { push eax }

         end;
         iprdint:   begin { Pred of integer }

            { get integer }
            emitbyt($58); { pop eax }
            { decrement }
            emitbyt($48); { dec eax }
            { replace on stack }
            emitbyt($50) { push eax }

         end;
         irnd:      begin { Round }

            { load round to nearest control word }
            emitbyt($68); { push $0000037f }
            emitint($0000037f);
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            emitbyt($d9); { fldcw [eax] }
            emitbyt($28);
            emitbyt($58); { pop eax }
            { index real on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load real }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { adjust stack space }
            emitbyt($5b); { pop ebx }
            { index destination on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { store integer with rounding }
            emitbyt($db); { fistpd [eax] }
            emitbyt($18);
            { sync store }
            emitbyt($9b); { fwait }
            stack := stack+intsiz { change from 64 bits to 32 bits }

         end;
         itrc:      begin { Trunc }

            { load round to 0 control word }
            emitbyt($68); { push $00000f7f }
            emitint($00000f7f);
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            emitbyt($d9); { fldcw [eax] }
            emitbyt($28);
            emitbyt($58); { pop eax }
            { index real on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load real }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { adjust stack space }
            emitbyt($5b); { pop ebx }
            { index destination on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { store integer with rounding }
            emitbyt($db); { fistpd [eax] }
            emitbyt($18);
            { sync store }
            emitbyt($9b); { fwait }
            stack := stack+intsiz { change from 64 bits to 32 bits }

         end;
         iexist:    begin

            { get address }
            emitbyt($58); { pop eax }
            { get length }
            emitbyt($5b); { pop ebx }
            { allocate return value }
            emitbyt($50); { push eax }
            { replace length }
            emitbyt($53); { push ebx }
            { replace address }
            emitbyt($50); { push eax }
            { call exists check routine }
            emitbyt($e8); { call ss_exists }
            emitadr(ssexists, itradr); { output routine address }
            ssexists^.rotr := true; { set referenced }
            stack := stack+tgpsiz-bolsiz { adjust stack }

         end;
         ilen:      begin { find file length }

            { get file }
            emitbyt($58); { pop eax }
            { allocate return value }
            emitbyt($50); { push eax }
            { place file }
            emitbyt($50); { push eax }
            { call file length routine }
            emitbyt($e8); { call ps_fillen }
            emitadr(psfillen, itradr); { output routine address }
            psfillen^.rotr := true { set referenced }
            
         end;
         iloc:      begin { File location }

            { get file }
            emitbyt($58); { pop eax }
            { allocate return value }
            emitbyt($50); { push eax }
            { place file }
            emitbyt($50); { push eax }
            { call file location routine }
            emitbyt($e8); { call ps_filloc }
            emitadr(psfilloc, itradr); { output routine address }
            psfilloc^.rotr := true { set referenced }

         end;
         iget:      begin { File get }

            { call file get routine }
            emitbyt($e8); { call ps_getfil }
            emitadr(psgetfil, itradr); { output routine address }
            psgetfil^.rotr := true; { set referenced }
            stack := stack+stksiz { removes the file }

         end;
         igett:     begin { Text file get }

            { call text file get routine }
            emitbyt($e8); { call ps_gettxt }
            emitadr(psgettxt, itradr); { output routine address }
            psgettxt^.rotr := true; { set referenced }
            stack := stack+stksiz { removes the file }

         end;
         iput:      begin

            { call file put routine }
            emitbyt($e8); { call ps_putfil }
            emitadr(psputfil, itradr); { output routine address }
            psputfil^.rotr := true; { set referenced }
            stack := stack+stksiz { removes the file }

         end;
         ilodafbuf: begin { load address of file buffer }

            { get file }
            emitbyt($58); { pop eax }
            { allocate return value }
            emitbyt($50); { push eax }
            emitbyt($50); { push eax }
            { place file on stack }
            emitbyt($50); { push eax }
            { call buffer address routine }
            emitbyt($e8); { call ps_lbafil }
            emitadr(pslbafil, itradr); { output routine address }
            { get buffer address }
            emitbyt($58); { pop eax }
            { dispose of buffer length }
            emitbyt($5b); { pop ebx }
            { replace buffer address }
            emitbyt($50); { push eax }
            pslbafil^.rotr := true { set referenced }

         end;
         ilodafbuft: begin { load address of text file buffer }

            { get file }
            emitbyt($58); { pop eax }
            { allocate return value }
            emitbyt($50); { push eax }
            emitbyt($50); { push eax }
            { place file on stack }
            emitbyt($50); { push eax }
            { call text buffer address routine }
            emitbyt($e8); { call ps_lbatxt }
            emitadr(pslbatxt, itradr); { output routine address }
            { get buffer address }
            emitbyt($58); { pop eax }
            { dispose of buffer length }
            emitbyt($5b); { pop ebx }
            { replace buffer address }
            emitbyt($50); { push eax }
            pslbatxt^.rotr := true { set referenced }

         end;
         ireset:    begin

            getlnk(tp); { get file type }
            tp1 := baset(tp); { find base type }
            if tp1^.t = ttext then begin

               { place file buffer length }
               emitbyt($6a); { push size }
               emitbyt(1); { place file record length }
               { call text file reset routine }
               emitbyt($e8); { call ps_restxt }
               emitadr(psrestxt, itradr); { output routine address }
               psrestxt^.rotr := true { set referenced }

            end else if tp1^.t = tfile then begin

               { place file buffer length }
               emitbyt($68); { push size }
               emitint(tp1^.filt^.size); { place file record length }
               { call file reset routine }
               emitbyt($e8); { call ps_resfil }
               emitadr(psresfil, itradr); { output routine address }
               psresfil^.rotr := true { set referenced }

            end else error(einvfmt); { invalid format }
            stack := stack+stksiz { net is less one }

         end;
         irewrite:  begin

            getlnk(tp); { get file type }
            tp1 := baset(tp); { find base type }
            if tp1^.t = ttext then begin

               { place file buffer length }
               emitbyt($6a); { push size }
               emitbyt(1); { place file record length }
               { call text file rewrite routine }
               emitbyt($e8); { call ps_rwttxt }
               emitadr(psrwttxt, itradr); { output routine address }
               psrwttxt^.rotr := true { set referenced }

            end else if tp1^.t = tfile then begin

               { place file buffer length }
               emitbyt($68); { push size }
               emitint(tp1^.filt^.size); { place file record length }
               { call file rewrite routine }
               emitbyt($e8); { call ps_rwtfil }
               emitadr(psrwtfil, itradr); { output routine address }
               psrwtfil^.rotr := true { set referenced }

            end else error(einvfmt); { invalid format }
            stack := stack+stksiz { net is less one }

         end;
         iclose:    begin

            { call close file routine }
            emitbyt($e8); { call ps_close }
            emitadr(psclose, itradr); { output routine address }
            psclose^.rotr := true; { set referenced }
            stack := stack+stksiz { net is less one }

         end;
         ipack:     begin { pack }

            { at this time, pack simply acts as an assign, because
              packing is unimplemented }
            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump to error label }
            gettypa(srtstk^.lab1, tlab); { set jump over error label }
            getlnk(tp); { get packed type }
            getlnk(tp1); { get unpacked type }
            { get packed array pointer }
            emitbyt($5f); { pop edi }
            { get starting index }
            emitbyt($58); { pop eax }
            { get unpacked array pointer }
            emitbyt($5e); { pop esi }
            { generate range check }
            emitbyt($3d); { cmp eax,imm }
            emitint(lbound(tp1^.arri)); { place low bound }
            emitbyt($0f); { jl goerror }
            emitbyt($8c);
            emitadr(srtstk^.lab, itradr); { place error jump address }
            emitbyt($3d); { cmp eax,imm }
            emitint(ubound(tp1^.arri)); { place upper bound }
            emitbyt($0f); { jle noerror }
            emitbyt($8e);
            emitadr(srtstk^.lab1, itradr); { place no error address }
            { generate error routine call }
            srtstk^.lab^.addr := pgmcnt; { set jump to error location }
            emitbyt($68); { push rerngchk }
            emitint(ord(rerngchk)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab1^.addr := pgmcnt; { set jump over error location }
            { adjust index for lower bound }
            emitbyt($2d); { sub eax,lbound }
            emitint(lbound(tp1^.arri)); { place lower bound }
            { scale to base type }
            emitbyt($bb); { mov ebx,size }
            emitint(tp1^.arrt^.size); { place base type size }
            emitbyt($f7); { mul eax,ebx }
            emitbyt($e3);
            { offset from base address }
            emitbyt($03); { add esi,eax }
            emitbyt($f0);
            { load packed array length as count }
            emitbyt($b9); { mov ecx,size }
            emitint(tp^.size); { place packed array size }
            { move data into place }
            emitbyt($f3); { rep }
            emitbyt($a4); { movsb }
            popsrt; { remove structure level }
            stack := stack+(3*stksiz) { net is less three }

         end;
         iunpack:   begin { unpack }

            { at this time, unpack simply acts as an assign, because
              packing is unimplemented }
            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump to error label }
            gettypa(srtstk^.lab1, tlab); { set jump over error label }
            getlnk(tp); { get unpacked type }
            getlnk(tp1);  { get packed type }
            { get starting index }
            emitbyt($58); { pop eax }
            { get unpacked array pointer }
            emitbyt($5f); { pop edi }
            { get packed array pointer }
            emitbyt($5e); { pop esi }
            { generate range check }
            emitbyt($3d); { cmp eax,imm }
            emitint(lbound(tp^.arri)); { place low bound }
            emitbyt($0f); { jl goerror }
            emitbyt($8c);
            emitadr(srtstk^.lab, itradr); { place error jump address }
            emitbyt($3d); { cmp eax,imm }
            emitint(ubound(tp^.arri)); { place upper bound }
            emitbyt($0f); { jle noerror }
            emitbyt($8e);
            emitadr(srtstk^.lab1, itradr); { place no error address }
            { generate error routine call }
            srtstk^.lab^.addr := pgmcnt; { set jump to error location }
            emitbyt($68); { push rerngchk }
            emitint(ord(rerngchk)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab1^.addr := pgmcnt; { set jump over error location }
            { adjust index for lower bound }
            emitbyt($2d); { sub eax,lbound }
            emitint(lbound(tp^.arri)); { place lower bound }
            { scale to base type }
            emitbyt($bb); { mov ebx,size }
            emitint(tp^.arrt^.size); { place base type size }
            emitbyt($f7); { mul eax,ebx }
            emitbyt($e3);
            { offset from base address }
            emitbyt($03); { add edi,eax }
            emitbyt($f8);
            { load packed array length as count }
            emitbyt($b9); { mov ecx,size }
            emitint(tp1^.size); { place packed array size }
            { move data into place }
            emitbyt($f3); { rep }
            emitbyt($a4); { movsb }
            popsrt; { remove structure level }
            stack := stack+(3*stksiz) { net is less three }

         end;
         ipage:     begin

            { call text file page routine }
            emitbyt($e8); { call ps_pagtxt }
            emitadr(pspagtxt, itradr); { output routine address }
            pspagtxt^.rotr := true; { set referenced }
            stack := stack+stksiz { net is less one }

         end;
         iassign:     begin { assign file name }

            { call file assign routine }
            emitbyt($e8); { call ps_assign }
            emitadr(psassign, itradr); { output routine address }
            psassign^.rotr := true; { set referenced }
            stack := stack+tgpsiz+stksiz { net is less two }

         end;
         ipos:      begin { set file position }

            { call file position routine }
            emitbyt($e8); { call ps_posfil }
            emitadr(psposfil, itradr); { output routine address }
            psposfil^.rotr := true; { set referenced }
            stack := stack+(2*stksiz) { net is less two }

         end;
         idel:      begin

            { call file delete routine }
            emitbyt($e8); { call ss_delete }
            emitadr(ssdelete, itradr); { output routine address }
            ssdelete^.rotr := true; { set referenced }
            stack := stack+tgpsiz { net is less one }

         end;
         ichg:      begin

            { call file change routine }
            emitbyt($e8); { call ss_change }
            emitadr(sschange, itradr); { output routine address }
            sschange^.rotr := true; { set referenced }
            stack := stack+(2*tgpsiz) { net is less two }

         end;
         istisrl:   begin { store short real variable }

            getlnk(tp); { get variable (unused) }
            { index real on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load long real }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { dispose of stack real }
            emitbyt($58); { pop eax }
            emitbyt($58); { pop eax }
            { get destination address }
            emitbyt($58); { pop eax }
            { store to destination short }
            emitbyt($d9); { fstps [eax] }
            emitbyt($18);
            { sync store }
            emitbyt($9b); { fwait }
            stack := stack+rlsiz+stksiz { net is less two }

         end;
         istirel:    begin { store real variable }

            getlnk(tp); { get variable (unused) }
            { get real }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { index destination }
            emitbyt($5f); { pop edi }
            { transfer }
            emitbyt($ab); { stosd }
            emitbyt($8b); { mov eax,ebx }
            emitbyt($c3);
            emitbyt($ab); { stosd }
            stack := stack+stksiz+rlsiz { net is less two }
               
         end;
         istiint, istichr, istibol:   begin

            getlnk(tp); { get variable type }
            { get operand }
            emitbyt($58); { pop eax }
            { get destination address }
            emitbyt($5b); { pop ebx }
            { if the destination is a true integer, don't range check, since
              the destination can contain any result. Also don't check
              pointers. also obey range check flag }
            if not intt(tp) and (tp^.t <> tptr) and (tp^.t <> tnil) and
               fbnd then begin 

               { process range check }
               pushsrt; { establish label for jumps }
               gettypa(srtstk^.lab, tlab); { set jump to error label }
               gettypa(srtstk^.lab1, tlab); { set jump over error label }
               { generate range check }
               emitbyt($3d); { cmp eax,imm }
               emitint(lbound(tp)); { place low bound }
               emitbyt($0f); { jl goerror }
               emitbyt($8c);
               emitadr(srtstk^.lab, itradr); { place error jump address }
               emitbyt($3d); { cmp eax,imm }
               emitint(ubound(tp)); { place upper bound }
               emitbyt($0f); { jle noerror }
               emitbyt($8e);
               emitadr(srtstk^.lab1, itradr); { place no error address }
               { generate error routine call }
               srtstk^.lab^.addr := pgmcnt; { set jump to error location }
               emitbyt($68); { push rerngchk }
               emitint(ord(rerngchk)); { place error code }
               emitbyt($e8); { call error }
               emitadr(pserror, itradr); { output error routine address }
               pserror^.rotr := true; { set referenced }
               srtstk^.lab1^.addr := pgmcnt; { set jump over error location }
               popsrt; { remove structure level }

            end;
            { process by size of destination }
            if tp^.size = 4 then begin { full integer }

               emitbyt($89); { mov [ebx],eax }
               emitbyt($03)

            end else if tp^.size = 2 then begin

               emitbyt($66); { mov [ebx],ax }
               emitbyt($89);
               emitbyt($03)

            end else if tp^.size = 1 then begin

               emitbyt($88); { mov [ebx],al }
               emitbyt($03)

            end else error(einvfmt); { bad size }
            stack := stack+(2*stksiz) { net is less two }

         end;
         istiset:   begin

            getlnk(tp); { get variable (unused) }
            { get the destination address above the set }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            emitbyt($83); { add eax,setsiz }
            emitbyt($c0);
            emitbyt(setsiz);
            emitbyt($8b); { mov edi,[eax] }
            emitbyt($38);
            { index source on stack }
            emitbyt($8b); { mov esi,esp }
            emitbyt($f4);
            { load count }
            emitbyt($b9); { mov ecx,setsiz div 4 }
            emitint(setsiz div 4);
            { store data to destination }
            emitbyt($f3); { rep }
            emitbyt($a5); { movsd } 
            { remove operands from stack }
            emitbyt($83); { add esp,setsiz+stksiz }
            emitbyt($c4);
            emitbyt(setsiz+stksiz);
            stack := stack+setsiz+stksiz { net is less two }

         end;
         istisrc:      begin { store structured }

            getlnk(tp); { get object type }
            { get struture address }
            emitbyt($5e); { pop esi }
            { get destination address }
            emitbyt($5f); { pop edi }
            { set size }
            emitbyt($b9); { mov ecx,size }
            emitint(tp^.size); { place object size }
            { store structure }
            emitbyt($f3); { rep }
            emitbyt($a4); { movsb } 
            stack := stack+(2*stksiz) { net is less two }

         end;
         istigar:   begin { store general array }

            getlnk(tp); { get object type }
            if tp^.t <> tgarry then error(einvfmt); { bad format }
            pushsrt; { establish label for jumps }
            gettypa(srtstk^.lab, tlab); { set jump over error label }
            { get source address }
            emitbyt($5e); { pop esi }
            { get source length }
            emitbyt($58); { pop eax }
            { get destination address }
            emitbyt($5f); { pop edi }
            { get destination length }
            emitbyt($59); { pop ecx }
            { check lengths equal }
            emitbyt($3b); { cmp eax,ecx }
            emitbyt($c1);
            { skip error if so }
            emitbyt($0f); { je over }
            emitbyt($84);
            emitadr(srtstk^.lab, itradr); { place error jump over address }
            { generate error routine call }
            emitbyt($68); { push rlenmat }
            emitint(ord(relenmat)); { place error code }
            emitbyt($e8); { call error }
            emitadr(pserror, itradr); { output error routine address }
            pserror^.rotr := true; { set referenced }
            srtstk^.lab^.addr := pgmcnt; { set jump over error location }
            { move data to destination }
            emitbyt($f3); { rep }
            emitbyt($a4); { movsb } 
            popsrt; { remove structure level }
            stack := stack+(2*tgpsiz) { net is less two }

         end;
         istitgp:   begin

            getlnk(tp); { get variable (unused) }
            { get tagged pointer }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { index destination }
            emitbyt($5f); { pop edi }
            { transfer }
            emitbyt($ab); { stosd }
            emitbyt($8b); { mov eax,ebx }
            emitbyt($c3);
            emitbyt($ab); { stosd }
            stack := stack+tgpsiz+stksiz { adjust stack }

         end;
         istifsrl:  begin { store function short real }

            getlnk(tp); { get variable (unused) }
            { index real on stack }
            emitbyt($8b); { mov eax,esp }
            emitbyt($c4);
            { load long real }
            emitbyt($dd); { fldd [eax] }
            emitbyt($00);
            { dispose of stack real }
            emitbyt($58); { pop eax }
            emitbyt($58); { pop eax }
            { get destination address }
            emitbyt($58); { pop eax }
            { store to destination short }
            emitbyt($d9); { fstps [eax] }
            emitbyt($18);
            { sync store }
            emitbyt($9b); { fwait }
            stack := stack+(2*stksiz) { net is less two }

         end;
         istifrel:   begin { store function real }

            getlnk(tp); { get variable (unused) }
            { get real }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { index destination }
            emitbyt($5f); { pop edi }
            { transfer }
            emitbyt($ab); { stosd }
            emitbyt($8b); { mov eax,ebx }
            emitbyt($c3);
            emitbyt($ab); { stosd }
            stack := stack+stksiz+rlsiz { net is less two }

         end;
         istiftgp:  begin { store function tagged pointer }

            getlnk(tp); { get variable (unused) }
            { get tagged pointer }
            emitbyt($58); { pop eax }
            emitbyt($5b); { pop ebx }
            { index destination }
            emitbyt($5f); { pop edi }
            { transfer }
            emitbyt($ab); { stosd }
            emitbyt($8b); { mov eax,ebx }
            emitbyt($c3);
            emitbyt($ab); { stosd }
            stack := stack+stksiz+tgpsiz { net is less two }

         end;
         istifint, istifchr, istifbol:  begin 

            { store function integer, character, boolean }
            getlnk(tp); { get function type }
            tp1 := tp^.fncr; { index function result }
            tp := baset(tp^.fncr); { index function variable }
            { get operand }
            emitbyt($58); { pop eax }
            { get destination address }
            emitbyt($5b); { pop ebx }
            { if the destination is a true integer, don't range check, since
              the destination can contain any result. Also don't check
              pointers }
            if not intt(tp) and (tp^.t <> tptr) and (tp^.t <> tnil) then begin 

               { process range check }
               pushsrt; { establish label for jumps }
               gettypa(srtstk^.lab, tlab); { set jump to error label }
               gettypa(srtstk^.lab1, tlab); { set jump over error label }
               { generate range check }
               emitbyt($3d); { cmp eax,imm }
               emitint(lbound(tp)); { place low bound }
               emitbyt($0f); { jl goerror }
               emitbyt($8c);
               emitadr(srtstk^.lab, itradr); { place error jump address }
               emitbyt($3d); { cmp eax,imm }
               emitint(ubound(tp)); { place upper bound }
               emitbyt($0f); { jle noerror }
               emitbyt($8e);
               emitadr(srtstk^.lab1, itradr); { place no error address }
               { generate error routine call }
               srtstk^.lab^.addr := pgmcnt; { set jump to error location }
               emitbyt($68); { push rerngchk }
               emitint(ord(rerngchk)); { place error code }
               emitbyt($e8); { call error }
               emitadr(pserror, itradr); { output error routine address }
               pserror^.rotr := true; { set referneced }
               srtstk^.lab1^.addr := pgmcnt; { set jump over error location }
               popsrt; { remove structure level }

            end;
            { process by size of destination }
            if tp1^.size = 4 then begin { full integer }

               emitbyt($89); { mov [ebx],eax }
               emitbyt($03)

            end else if tp1^.size = 2 then begin

               emitbyt($66); { mov [ebx],ax }
               emitbyt($89);
               emitbyt($03)

            end else if tp1^.size = 1 then begin

               emitbyt($88); { mov [ebx],al }
               emitbyt($03)

            end else error(einvfmt); { bad size }
            stack := stack+(2*stksiz) { net is less two }

         end;
         inew, idisp:     begin { new, dispose }

            ic1 := ic; { save type }
            getlnk(tp); { get variable type }
            if tp^.t <> tptr then error(einvfmt); { must be pointer }
            tp := tp^.ptrt; { link base type }
            rsiz := tp^.size; { set whole size }
            getcod(ic); { read the next tag }
            if tp^.t = trecord then begin { it's a record, process tagging }

               rsiz1 := tp^.size; { clear tag size }
               tp := tp^.recf; { index field list }
               rsiz := 0; { clear total size }
               while ic = itag do begin { read tags }

                  { a more compact form was specified than the whole type,
                    so we find the new minimum size by finding
                    all the fixed elements, adding that to the total, and
                    then finding a new minimum }
                  rdnum(v); { get case constant }
                  while tp^.t = tfield do begin { add fixed fields }

                     rsiz := rsiz+tp^.fldt^.size; { add in size }
                     tp := tp^.next; { next entry }
                     if tp = nil then error(einvfmt); { invalid format }

                  end;
                  { now we should be pointing at the tag }
                  if tp^.t <> tftag then error(einvfmt); { invalid format }
                  if tp^.ftge then { tag field exists }
                     rsiz := rsiz+tp^.size; { add in tag size }
                  tp := tp^.ftgc; { index case list }
                  while tp^.fcsc <> v do begin { find matching case }

                     tp := tp^.fcsn;
                     if tp = nil then error(einvfmt) { invalid format }

                  end;
                  rsiz1 := tp^.size; { find new minimum }
                  tp := tp^.fcsf; { index that case list }
                  getcod(ic) { read the next tag }

               end;
               rsiz := rsiz+rsiz1 { add any tag size }

            end;
            if ic <> iendtag then error(einvfmt); { should be terminated }
            if ic1 = inew then begin

               { place dummy tagged pointer on stack }
               emitbyt($50); { push eax }
               emitbyt($50); { push eax }
               { index that }
               emitbyt($8b); { mov eax,esp }
               emitbyt($c4);
               { place address on stack }
               emitbyt($50); { push eax }
               { place size on stack }
               emitbyt($68); { push size }
               emitint(rsiz); { place size }
               { call new routine }
               emitbyt($e8);
               emitadr(ssgetspace, itradr);
               { get address of allocation }
               emitbyt($58); { pop eax }
               { dispose of length }
               emitbyt($5b); { pop ebx }
               { get address of pointer }
               emitbyt($5b); { pop ebx }
               { place address }
               emitbyt($89); { mov [ebx],eax }
               emitbyt($03);
               ssgetspace^.rotr := true { set referenced }

            end else begin
                              
               { get address of pointer }
               emitbyt($58); { pop eax }
               { place size on stack }
               emitbyt($68); { push size }
               emitint(rsiz); { place size }
               { place variable address }
               emitbyt($50); { push eax }
               { call dispose routine }
               emitbyt($e8);
               { output routine address }
               emitadr(ssputspace, itradr);
               ssputspace^.rotr := true { set referenced }

            end;
            stack := stack+stksiz { net is less one }

         end;
         itag:      error(einvfmt); { should not occur alone }
         iendtag:   error(einvfmt); { should not occur alone }
         ipoptop:   begin

            getlnk(tp); { get operand type }
            { remove top of stack }
            emitbyt($58); { pop eax }
            stack := stack+stksiz { net is less one }

         end;
         ilabequ:   begin

            getlnk(tp); { get label type }
            tp^.addr := pgmcnt { set location }

         end;
         irngchk:   begin

            getlnk(tp); { get check type }
            if fbnd then begin { process range check if allowed }

               pushsrt; { establish label for jumps }
               gettypa(srtstk^.lab, tlab); { set jump to error label }
               gettypa(srtstk^.lab1, tlab); { set jump over error label }
               { get ordinal to check }
               emitbyt($58); { pop eax }
               { replace on stack }
               emitbyt($50); { push eax }
               { generate range check }
               emitbyt($3d); { cmp eax,imm }
               emitint(lbound(tp)); { place low bound }
               emitbyt($0f); { jl goerror }
               emitbyt($8c);
               emitadr(srtstk^.lab, itradr); { place error jump address }
               emitbyt($3d); { cmp eax,imm }
               emitint(ubound(tp)); { place upper bound }
               emitbyt($0f); { jle noerror }
               emitbyt($8e);
               emitadr(srtstk^.lab1, itradr); { place no error address }
               { generate error routine call }
               srtstk^.lab^.addr := pgmcnt; { set jump to error location }
               emitbyt($68); { push rerngchk }
               emitint(ord(rerngchk)); { place error code }
               emitbyt($e8); { call error }
               emitadr(pserror, itradr); { output error routine address }
               pserror^.rotr := true; { set referenced }
               srtstk^.lab1^.addr := pgmcnt; { set jump over error location }
               popsrt { remove structure level }

            end

         end;
         inewgar:   begin

            getlnk(tp); { get array type }
            if tp^.t <> tgarry then error(einvfmt); { bad format }
            { get length of string }
            emitbyt($58); { pop eax }
            { load base object size }
            emitbyt($b9); { mov ecx,size }
            emitint(tp^.gart^.size); { output base element size }
            { multiply to find total allocation }
            emitbyt($f7); { mul eax,ecx }
            emitbyt($e1);
            { place on stack }
            emitbyt($50); { push eax }
            { call new routine }
            emitbyt($e8); { call ss_getspace }
            emitadr(ssgetspace, itradr); { output routine address }
            ssgetspace^.rotr := true; { set referenced }
            stack := stack+intsiz+stksiz { adjust stack }

         end;
         idspgar:   begin

            getlnk(tp); { get array type }
            if tp^.t <> tgarry then error(einvfmt); { bad format }
            { call dispose routine }
            emitbyt($e8); { call ss_putspace }
            emitadr(ssputspace, itradr); { output routine address }
            ssputspace^.rotr := true; { set referenced }
            stack := stack+tgpsiz { adjust stack }

         end;
         ihalt:     begin

            emitbyt($e8); { call abort }
            emitadr(psabort, itradr); { output abort routine address }
            psabort^.rotr := true { set referenced }

         end;
