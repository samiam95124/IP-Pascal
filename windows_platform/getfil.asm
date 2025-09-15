!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
! Convert file pointer to byte pointer                                        !
!                                                                             !
! Returns a byte pointer from a file pointer. Returns the logical file number !
! at the pointer. Used to get the logical file number equivalent from a file. !
!                                                                             !
! function retfil(var ba: text): ss_filhdl;                                   !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

        jmp     getfil_end      ! skip over module
getlfn:
!
! In register passing convention, eax/ebx in matches eax/ebx result
!
        movzxb  eax,[eax]       ! get logical file number
        ret                     ! exit to caller
!
getfil_end:
