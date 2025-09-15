!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
! Get tagged pointer to fixed object                                          !
!                                                                             !
! Returns the tagged pointer passed as a parameter. This is used to form a    !
! tagged pointer to a fixed object, which is normally impossible.             !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

        jmp     gettgp_end      ! skip over module
rettgp:
        pop     ecx             ! get return address
        pop     eax             ! get base address
        pop     ebx             ! get length
        pop     edx             ! dispose of dummy return
        pop     edx
        push    ebx             ! place length
        push    eax             ! place base address
        jmp     ecx             ! return to caller
!
gettgp_end:
