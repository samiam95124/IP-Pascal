!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
! Get tagged pointer to fixed object                                          !
!                                                                             !
! Returns the tagged pointer passed as a parameter. This is used to form a    !
! tagged pointer to a fixed object, which is normally impossible.             !
!                                                                             !
! function rettgp(var ba: bytarr): gbtptr;                                    !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

        jmp     gettgp_end      ! skip over module
rettgp:
!
! In register passing convention, eax/ebx in matches eax/ebx result
!
        ret                     ! exit to caller
!
gettgp_end:
