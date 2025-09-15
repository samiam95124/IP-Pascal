!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
!                     SYSTEM LIBRARY OVERRIDE MODULE                          !
!                                                                             !
!                             01/2 S. A. Moore                                !
!                                                                             !
! Handles "overriding" for the system function library. All calls to the      !
! system module go through a hook vector, which are initalized here to point  !
! to the base functions. Calls are then implemented to hook these vectors     !
! to new procedures, and to allow access to the old call.                     !
! There is no limit on hooking depth.                                         !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

        jmp     sysovr_init     ! go to initalization
!
! Entry calls
!
ss_openread:    jmpl    [ss_ptr_openread]
ss_openwrite:   jmpl    [ss_ptr_openwrite]
ss_close:       jmpl    [ss_ptr_close]
ss_read:        jmpl    [ss_ptr_read]
ss_write:       jmpl    [ss_ptr_write]
ss_position:    jmpl    [ss_ptr_position]
ss_location:    jmpl    [ss_ptr_location]
ss_length:      jmpl    [ss_ptr_length]
ss_eof:         jmpl    [ss_ptr_eof]
ss_delete:      jmpl    [ss_ptr_delete]
ss_change:      jmpl    [ss_ptr_change]
ss_exists:      jmpl    [ss_ptr_exists]
ss_getspace:    jmpl    [ss_ptr_getspace]
ss_putspace:    jmpl    [ss_ptr_putspace]
ss_alteol:      jmpl    [ss_ptr_alteol]
ss_wrterr:      jmpl    [ss_ptr_wrterr]
!
! Hook each vector
!
! The format of each call is:
!
! override(proc newadr, storeold: ^^integer);
!
! The old address in the vector is stored at the requested address, and the
! new address replaces the current vector.
!
ss_ovr_openread:
        mov     eax,ss_ptr_openread     ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_openwrite:
        mov     eax,ss_ptr_openwrite    ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_close:
        mov     eax,ss_ptr_close        ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_read:
        mov     eax,ss_ptr_read         ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_write:
        mov     eax,ss_ptr_write        ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_position:
        mov     eax,ss_ptr_position     ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_location:
        mov     eax,ss_ptr_location     ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_length:
        mov     eax,ss_ptr_length       ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_eof:
        mov     eax,ss_ptr_eof          ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_delete:
        mov     eax,ss_ptr_delete       ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_change:
        mov     eax,ss_ptr_change       ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_exists:
        mov     eax,ss_ptr_exists       ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_getspace:
        mov     eax,ss_ptr_getspace     ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_putspace:
        mov     eax,ss_ptr_putspace     ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_alteol:
        mov     eax,ss_ptr_alteol       ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_wrterr:
        mov     eax,ss_ptr_wrterr       ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_overload:
        pop     ebx                     ! save return address
        pop     ecx                     ! get address of store
        mov     edx,[eax]               ! get current vector
        mov     [ecx],edx               ! store it
        pop     ecx                     ! get new vector
        mov     [eax],ecx               ! place
        jmp     ebx                     ! return to caller
!
! Call old vector
!
! Executes a call of the form:
!
! call(storeold: ^integer);
!
ss_old_openread: 
ss_old_openwrite:
ss_old_close:    
ss_old_read:     
ss_old_write:    
ss_old_position: 
ss_old_location: 
ss_old_length:   
ss_old_eof:      
ss_old_delete:   
ss_old_change:   
ss_old_exists:   
ss_old_getspace: 
ss_old_putspace: 
ss_old_alteol: 
ss_old_wrterr:   
!
        pop     eax                     ! get return
        pop     ebx                     ! get vector
        push    eax                     ! replace return
        jmp     ebx                     ! go vector
!
! Initalize vectors
!
sysovr_init:
        mov     eax,ss__openread
        mov     [ss_ptr_openread],eax
        mov     eax,ss__openwrite
        mov     [ss_ptr_openwrite],eax
        mov     eax,ss__close
        mov     [ss_ptr_close],eax
        mov     eax,ss__read
        mov     [ss_ptr_read],eax
        mov     eax,ss__write
        mov     [ss_ptr_write],eax
        mov     eax,ss__position
        mov     [ss_ptr_position],eax
        mov     eax,ss__location
        mov     [ss_ptr_location],eax
        mov     eax,ss__length
        mov     [ss_ptr_length],eax
        mov     eax,ss__eof
        mov     [ss_ptr_eof],eax
        mov     eax,ss__delete
        mov     [ss_ptr_delete],eax
        mov     eax,ss__change
        mov     [ss_ptr_change],eax
        mov     eax,ss__exists
        mov     [ss_ptr_exists],eax
        mov     eax,ss__getspace
        mov     [ss_ptr_getspace],eax
        mov     eax,ss__putspace
        mov     [ss_ptr_putspace],eax
        mov     eax,ss__alteol
        mov     [ss_ptr_alteol],eax
        mov     eax,ss__wrterr
        mov     [ss_ptr_wrterr],eax
!
! End of override module
!
sysovr_end:
!
! Vectors
!
ss_ptr_openread:    defvs   4
ss_ptr_openwrite:   defvs   4
ss_ptr_close:       defvs   4
ss_ptr_read:        defvs   4
ss_ptr_write:       defvs   4
ss_ptr_position:    defvs   4
ss_ptr_location:    defvs   4
ss_ptr_length:      defvs   4
ss_ptr_eof:         defvs   4
ss_ptr_delete:      defvs   4
ss_ptr_change:      defvs   4
ss_ptr_exists:      defvs   4
ss_ptr_getspace:    defvs   4
ss_ptr_putspace:    defvs   4
ss_ptr_alteol:      defvs   4
ss_ptr_wrterr:      defvs   4
