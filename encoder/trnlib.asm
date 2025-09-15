!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                              !
!                 I80386 FULL ENCODER TO CHECK ENCODER TRANSLATOR              !
!                                                                              !
!                             04/01 S. A. Moore                                !
!                                                                              !
! To allow extensive testing of the full encoder without needing to            !
! self-encode the libraries, we use this library to translate to and from the  !
! paslib and syslib modules compiled with the check encoder. This module will  !
! be discarded when the full encoder is capable of compiling its own           !
! libraries.                                                                   !
!                                                                              !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

trn_start:
        call    trn_end     ! execute next module
        ret                 ! exit to caller

tr_ps_abort:
        pushad
        pushfd
        call    ps_abort    ! execute
        popfd
        popad
        ret

tr_ps_error:
        pushad
        pushfd
        push    eax         ! place error on stack
        call    ps_error    ! execute
        popfd
        popad
        ret

tr_ps_wrtfil:
        pushad
        pushfd
        push    ecx         ! place file address on stack
        push    ebx         ! place byte array length on stack
        push    eax         ! place byte array address on stack
        call    ps_wrtfil   ! execute
        popfd
        popad
        ret

tr_ps_wrtint:
        pushad
        pushfd
        push    eax         ! place file address on stack
        push    ebx         ! place field on stack
        push    ecx         ! place integer on stack
        call    ps_wrtint   ! execute
        popfd
        popad
        ret

tr_ps_wrtchr:
        pushad
        pushfd
        push    eax         ! place file address on stack
        push    ebx         ! place field on stack
        push    ecx         ! place character on stack
        call    ps_wrtchr   ! execute
        popfd
        popad
        ret

tr_ps_wrtbol:
        pushad
        pushfd
        push    eax         ! place file address on stack
        push    ebx         ! place boolean on stack
        call    ps_wrtbol   ! execute
        popfd
        popad
        ret

tr_ps_wrtblf:
        pushad
        pushfd
        push    eax         ! place file address on stack
        push    ebx         ! place field on stack
        push    ecx         ! place boolean on stack
        call    ps_wrtblf   ! execute
        popfd
        popad
        ret

tr_ps_wrtreal:
        pushad
        pushfd
        push    eax         ! place file address on stack
        push    ebx         ! place field on stack
        pushd   0           ! place space for real on stack
        pushd   0
        fstpd   [esp]       ! place the real there
        call    ps_wrtreal  ! execute
        popfd
        popad
        ret

tr_ps_wrtrlf:
        pushad
        pushfd
        push    eax         ! place file address on stack
        push    ebx         ! place field on stack
        push    ecx         ! place fraction on stack
        pushd   0           ! place space for real on stack
        pushd   0
        fstpd   [esp]       ! place the real there
        call    ps_wrtrlf   ! execute
        popfd
        popad
        ret

tr_ps_wrtstr:
        pushad
        pushfd
        push    ecx         ! place file address on stack
        push    ebx         ! place string length on stack
        push    eax         ! place string address on stack
        call    ps_wrtstr   ! execute
        popfd
        popad
        ret

tr_ps_wrtstrf:
        pushad
        pushfd
        push    ecx         ! place file address on stack
        push    edx         ! place field on stack
        push    ebx         ! place string length on stack
        push    eax         ! place string address on stack
        call    ps_wrtstrf  ! execute
        popfd
        popad
        ret

tr_ps_wrteol:
        pushad
        pushfd
        push    eax         ! place file address on stack
        call    ps_wrteol   ! execute
        popfd
        popad
        ret

tr_ps_pagtxt:
        pushad
        pushfd
        push    eax         ! place file address on stack
        call    ps_pagtxt   ! execute
        popfd
        popad
        ret

tr_ps_rdfil:
        pushad
        pushfd
        push    ecx         ! place file address on stack
        push    ebx         ! place byte array length on stack
        push    eax         ! place byte array address on stack
        call    ps_rdfil    ! execute
        popfd
        popad
        ret

tr_ps_rdint:
        pushad
        pushfd
        push    eax         ! place file address on stack
        push    ebx         ! place integer address on stack
        call    ps_rdint    ! execute
        popfd
        popad
        ret

tr_ps_rdchr:
        pushad
        pushfd
        push    eax         ! place file address on stack
        push    ebx         ! place char address on stack
        call    ps_rdchr    ! execute
        popfd
        popad
        ret

tr_ps_rdreal:
        pushad
        pushfd
        push    eax         ! place file address on stack
        push    ebx         ! place real address on stack
        call    ps_rdreal   ! execute
        popfd
        popad
        ret

tr_ps_rdeol:
        pushad
        pushfd
        push    eax         ! place file address on stack
        call    ps_rdeol    ! execute
        popfd
        popad
        ret

tr_ps_eoftxt:
        pushad
        pushfd
        pushd   0           ! place stack return dummy
        push    eax         ! place file address on stack
        call    ps_eoftxt   ! execute
        pop     eax         ! get return
        popfd
        pop     edi
        pop     esi
        pop     ebp
        add     esp,4
        pop     ebx
        pop     edx
        pop     ecx
        add     esp,4       ! dump eax
        ret

tr_ps_chkeol:
        pushad
        pushfd
        pushd   0           ! place stack return dummy
        push    eax         ! place file address on stack
        call    ps_chkeol   ! execute
        pop     eax         ! get return
        popfd
        pop     edi
        pop     esi
        pop     ebp
        add     esp,4
        pop     ebx
        pop     edx
        pop     ecx
        add     esp,4       ! dump eax
        ret

tr_ps_eoffil:
        pushad
        pushfd
        pushd   0           ! place stack return dummy
        push    eax         ! place file address on stack
        call    ps_eoffil   ! execute
        pop     eax         ! get return
        popfd
        pop     edi
        pop     esi
        pop     ebp
        add     esp,4
        pop     ebx
        pop     edx
        pop     ecx
        add     esp,4       ! dump eax
        ret

tr_ps_fillen:
        pushad
        pushfd
        pushd   0           ! place stack return dummy
        push    eax         ! place file address on stack
        call    ps_fillen   ! execute
        pop     eax         ! get return
        popfd
        pop     edi
        pop     esi
        pop     ebp
        add     esp,4
        pop     ebx
        pop     edx
        pop     ecx
        add     esp,4       ! dump eax
        ret

tr_ps_filloc:
        pushad
        pushfd
        pushd   0           ! place stack return dummy
        push    eax         ! place file address on stack
        call    ps_filloc   ! execute
        pop     eax         ! get return
        popfd
        pop     edi
        pop     esi
        pop     ebp
        add     esp,4
        pop     ebx
        pop     edx
        pop     ecx
        add     esp,4       ! dump eax
        ret

tr_ps_getfil:
        pushad
        pushfd
        push    eax         ! place file address on stack
        call    ps_getfil   ! execute
        popfd
        popad
        ret

tr_ps_gettxt:
        pushad
        pushfd
        push    eax         ! place file address on stack
        call    ps_gettxt   ! execute
        popfd
        popad
        ret

tr_ps_putfil:
        pushad
        pushfd
        push    eax         ! place file address on stack
        call    ps_putfil   ! execute
        popfd
        popad
        ret

tr_ps_lbafil:
        pushad
        pushfd
        pushd   0           ! place stack return dummy length
        pushd   0           ! place stack return dummy address
        push    eax         ! place file address on stack
        call    ps_lbafil   ! execute
        pop     eax         ! get return address
        pop     ebx         ! get return length
        popfd
        pop     edi
        pop     esi
        pop     ebp
        add     esp,4
        add     esp,4       ! dump ebx
        pop     edx
        pop     ecx
        add     esp,4       ! dump eax
        ret

tr_ps_lbatxt:
        pushad
        pushfd
        pushd   0           ! place stack return dummy length
        pushd   0           ! place stack return dummy address
        push    eax         ! place file address on stack
        call    ps_lbatxt   ! execute
        pop     eax         ! get return address
        pop     ebx         ! get return length
        popfd
        pop     edi
        pop     esi
        pop     ebp
        add     esp,4
        add     esp,4       ! dump ebx
        pop     edx
        pop     ecx
        add     esp,4       ! dump eax
        ret

tr_ps_restxt:
        pushad
        pushfd
        push    eax         ! place file address on stack
        push    ebx         ! place buffer length on stack
        call    ps_restxt   ! execute
        popfd
        popad
        ret

tr_ps_resfil:
        pushad
        pushfd
        push    eax         ! place file address on stack
        push    ebx         ! place buffer length on stack
        call    ps_resfil   ! execute
        popfd
        popad
        ret

tr_ps_rwttxt:
        pushad
        pushfd
        push    eax         ! place file address on stack
        push    ebx         ! place buffer length on stack
        call    ps_rwttxt   ! execute
        popfd
        popad
        ret

tr_ps_rwtfil:
        pushad
        pushfd
        push    eax         ! place file address on stack
        push    ebx         ! place buffer length on stack
        call    ps_rwtfil   ! execute
        popfd
        popad
        ret

tr_ps_close:
        pushad
        pushfd
        push    eax         ! place file address on stack
        call    ps_close    ! execute
        popfd
        popad
        ret

tr_ps_assign:
        pushad
        pushfd
        push    ecx         ! place file address on stack
        push    ebx         ! place string length on stack
        push    eax         ! place string address on stack
        call    ps_assign   ! execute
        popfd
        popad
        ret

tr_ps_posfil:
        pushad
        pushfd
        push    eax         ! place file address on stack
        push    ebx         ! place file position on stack
        call    ps_posfil   ! execute
        popfd
        popad
        ret

tr_ss_delete:
        pushad
        pushfd
        push    ebx         ! place string length on stack
        push    eax         ! place string address on stack
        call    ss_delete   ! execute
        popfd
        popad
        ret

tr_ss_change:
        pushad
        pushfd
        push    ebx         ! place destination string length on stack
        push    eax         ! place destination string address on stack
        push    edx         ! place source string length on stack
        push    ecx         ! place source string address on stack
        call    ss_change   ! execute
        popfd
        popad
        ret

tr_ss_exists:
        pushad
        pushfd
        pushd   0           ! place stack return dummy
        push    ebx         ! place string length
        push    eax         ! place string address
        call    ss_exists   ! execute
        pop     eax         ! get return
        popfd
        pop     edi
        pop     esi
        pop     ebp
        add     esp,4
        pop     ebx
        pop     edx
        pop     ecx
        add     esp,4       ! dump eax
        ret

tr_ss_getspace:
        pushad
        pushfd
        push    eax         ! place byte array pointer address
        push    ebx         ! place length
        call    ss_getspace ! execute
        popfd
        popad
        ret

tr_ss_putspace:
        pushad
        pushfd
        push    ebx         ! place byte array length
        push    eax         ! place byte array address
        call    ss_putspace ! execute
        popfd
        popad
        ret

!
! End of module
!
trn_end:
