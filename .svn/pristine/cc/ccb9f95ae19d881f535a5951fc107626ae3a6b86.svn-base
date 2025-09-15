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
ss_alias:       jmpl    [ss_ptr_alias]
ss_resolve:     jmpl    [ss_ptr_resolve]
ss_sysfil:      jmpl    [ss_ptr_sysfil]
ss_openread:    jmpl    [ss_ptr_openread]
ss_openwrite:   jmpl    [ss_ptr_openwrite]
ss_openupdate:  jmpl    [ss_ptr_openupdate]
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
ss_newthread:   jmpl    [ss_ptr_newthread]
ss_killthread:  jmpl    [ss_ptr_killthread]
ss_signal:      jmpl    [ss_ptr_signal]
ss_signalone:   jmpl    [ss_ptr_signalone]
ss_wait:        jmpl    [ss_ptr_wait]
ss_newlock:     jmpl    [ss_ptr_newlock]
ss_displock:    jmpl    [ss_ptr_displock]
ss_lock:        jmpl    [ss_ptr_lock]
ss_unlock:      jmpl    [ss_ptr_unlock]
!
! Hook each vector
!
! The format of each call is:
!
! override(proc newadr, storeold: ^^integer);
!
! Where proc newadr is passed in eax (address) and ebx (frame), and the storeold
! address in ecx.
!
! The old address in the vector is stored at the requested address, and the
! new address replaces the current vector.
!
ss_ovr_alias:
        push    ebx                     ! save
        mov     ebx,ss_ptr_alias        ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_resolve:
        push    ebx                     ! save
        mov     ebx,ss_ptr_resolve      ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_sysfil:
        push    ebx                     ! save
        mov     ebx,ss_ptr_sysfil       ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_openread:
        push    ebx                     ! save
        mov     ebx,ss_ptr_openread     ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_openwrite:
        push    ebx                     ! save
        mov     ebx,ss_ptr_openwrite    ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_openupdate:
        push    ebx                     ! save
        mov     ebx,ss_ptr_openupdate   ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_close:
        push    ebx                     ! save
        mov     ebx,ss_ptr_close        ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_read:
        push    ebx                     ! save
        mov     ebx,ss_ptr_read         ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_write:
        push    ebx                     ! save
        mov     ebx,ss_ptr_write        ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_position:
        push    ebx                     ! save
        mov     ebx,ss_ptr_position     ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_location:
        push    ebx                     ! save
        mov     ebx,ss_ptr_location     ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_length:
        push    ebx                     ! save
        mov     ebx,ss_ptr_length       ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_eof:
        push    ebx                     ! save
        mov     ebx,ss_ptr_eof          ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_delete:
        push    ebx                     ! save
        mov     ebx,ss_ptr_delete       ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_change:
        push    ebx                     ! save
        mov     ebx,ss_ptr_change       ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_exists:
        push    ebx                     ! save
        mov     ebx,ss_ptr_exists       ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_getspace:
        push    ebx                     ! save
        mov     ebx,ss_ptr_getspace     ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_putspace:
        push    ebx                     ! save
        mov     ebx,ss_ptr_putspace     ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_alteol:
        push    ebx                     ! save
        mov     ebx,ss_ptr_alteol       ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_wrterr:
        push    ebx                     ! save
        mov     ebx,ss_ptr_wrterr       ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_newthread:   
        push    ebx                     ! save
        mov     ebx,ss_ptr_newthread    ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_killthread:  
        push    ebx                     ! save
        mov     ebx,ss_ptr_killthread   ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_signal:      
        push    ebx                     ! save
        mov     ebx,ss_ptr_signal       ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_signalone:   
        push    ebx                     ! save
        mov     ebx,ss_ptr_signalone    ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_wait:        
        push    ebx                     ! save
        mov     ebx,ss_ptr_wait         ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_newlock:     
        push    ebx                     ! save
        mov     ebx,ss_ptr_newlock      ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_displock:    
        push    ebx                     ! save
        mov     ebx,ss_ptr_displock     ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_lock:        
        push    ebx                     ! save
        mov     ebx,ss_ptr_lock         ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_ovr_unlock:      
        push    ebx                     ! save
        mov     ebx,ss_ptr_unlock       ! place pointer to vector
        jmp     ss_overload             ! execute
!
ss_overload:
        push    edx                     ! save
        mov     edx,[ebx]               ! get current vector
        mov     [ecx],edx               ! store it
        mov     [ebx],eax               ! place new vector
        pop     edx                     ! restore used registers
        pop     ebx
        ret                             ! return to caller
!
! Call old vector
!
! Executes a call of the form:
!
! call(storeold: ^integer);
!
ss_old_alias: 
        jmp     ecx                     ! execute old routine
ss_old_resolve: 
        jmp     edx                     ! execute old routine
ss_old_sysfil: 
        jmp     ecx                     ! execute old routine
ss_old_openread: 
        jmp     edx                     ! execute old routine
ss_old_openwrite:
        jmp     edx                     ! execute old routine
ss_old_openupdate:
        jmp     edx                     ! execute old routine
ss_old_close:    
        jmp     ebx                     ! execute old routine
ss_old_read:     
        jmp     edx                     ! execute old routine
ss_old_write:    
        jmp     edx                     ! execute old routine
ss_old_position: 
        jmp     ecx                     ! execute old routine
ss_old_location: 
        jmp     ebx                     ! execute old routine
ss_old_length:   
        jmp     ebx                     ! execute old routine
ss_old_eof:      
        jmp     ebx                     ! execute old routine
ss_old_delete:   
        jmp     ecx                     ! execute old routine
ss_old_change:   
        jmp     esi                     ! execute old routine
ss_old_exists:   
        jmp     ecx                     ! execute old routine
ss_old_getspace: 
        jmp     edx                     ! execute old routine
ss_old_putspace: 
        jmp     ecx                     ! execute old routine
ss_old_alteol: 
        jmp     eax                     ! execute old routine
ss_old_wrterr:   
        jmp     ecx                     ! execute old routine
ss_old_newthread:   
        jmp     ecx                     ! execute old routine
ss_old_killthread:  
        jmp     ebx                     ! execute old routine
ss_old_signal:      
        jmp     ebx                     ! execute old routine
ss_old_signalone:   
        jmp     ebx                     ! execute old routine
ss_old_wait:        
        jmp     ecx                     ! execute old routine
ss_old_newlock:     
        jmp     ebx                     ! execute old routine
ss_old_displock:    
        jmp     ebx                     ! execute old routine
ss_old_lock:        
        jmp     ebx                     ! execute old routine
ss_old_unlock:      
        jmp     ebx                     ! execute old routine
!
! Initalize vectors
!
sysovr_init:
        mov     eax,ss__alias
        mov     [ss_ptr_alias],eax
        mov     eax,ss__resolve
        mov     [ss_ptr_resolve],eax
        mov     eax,ss__sysfil
        mov     [ss_ptr_sysfil],eax
        mov     eax,ss__openread
        mov     [ss_ptr_openread],eax
        mov     eax,ss__openwrite
        mov     [ss_ptr_openwrite],eax
        mov     eax,ss__openupdate
        mov     [ss_ptr_openupdate],eax
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
        mov     eax,ss__newthread
        mov     [ss_ptr_newthread],eax   
        mov     eax,ss__killthread
        mov     [ss_ptr_killthread],eax  
        mov     eax,ss__signal
        mov     [ss_ptr_signal],eax      
        mov     eax,ss__signalone
        mov     [ss_ptr_signalone],eax   
        mov     eax,ss__wait
        mov     [ss_ptr_wait],eax        
        mov     eax,ss__newlock
        mov     [ss_ptr_newlock],eax    
        mov     eax,ss__displock
        mov     [ss_ptr_displock],eax    
        mov     eax,ss__lock
        mov     [ss_ptr_lock],eax        
        mov     eax,ss__unlock
        mov     [ss_ptr_unlock],eax      
!
! End of override module
!
sysovr_end:
!
! Vectors
!
ss_ptr_alias:       defvs   4
ss_ptr_resolve:     defvs   4
ss_ptr_sysfil:      defvs   4
ss_ptr_openread:    defvs   4
ss_ptr_openwrite:   defvs   4
ss_ptr_openupdate:  defvs   4
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
ss_ptr_newthread:   defvs   4
ss_ptr_killthread:  defvs   4
ss_ptr_signal:      defvs   4
ss_ptr_signalone:   defvs   4
ss_ptr_wait:        defvs   4
ss_ptr_newlock:     defvs   4
ss_ptr_displock:    defvs   4
ss_ptr_lock:        defvs   4
ss_ptr_unlock:      defvs   4
