!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
!                           CONVERT FILE TIME                                 !
!                                                                             !
!                             96/9 S. A. Moore                                !
!                                                                             !
! Converts the windows 64 bit time format to an integer seconds format. This  !
! routine is in assembly because we don't have 64 bit capability in our       !
! Pascal.                                                                     !
!                                                                             !
! The seconds time format is a count, in seconds, of the current time from or !
! to the beginning of the year 2000. As this program is written, that is a    !
! negative number which is counting up to 0. After the year 2000, it will be  !
! counting up.                                                                !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

        jmp     cvttim_end      ! exit module
!
! procedure filetimetoseconds(view ft: sc_filetime; { file time to convert }
!                             var  t:  integer);    { resulting seconds time }
! 
filetimetoseconds:
        pushfd
        pushad
        mov     edi,ebx         ! place result address
        mov     ebx,eax         ! place file time address
        mov     eax,[ebx]       ! get low file time
        add     ebx,4           ! next
        mov     edx,[ebx]       ! get high file time
        mov     ecx,eax         ! check 0 time (undefined)
        or      ecx,edx
        jnz     filetimetoseconds01 ! no, skip
!
! if the time passed is undefined (0), we convert it to the equivalent
! S2000 undefined time, -maxint
!
        mov     eax,-2147483648 ! load -maxint
        jmp     filetimetoseconds02 ! go
filetimetoseconds01:
        sub     eax,$256d4000   ! find time-year 2000 (precomputed}
        sbb     edx,$01bf53eb
        mov     ebx,10000000    ! find number of seconds
        idiv    eax,ebx
filetimetoseconds02:
        mov     [edi],eax       ! place as result
        popad                   ! clean up and return
        popfd
        ret
!
cvttim_end:
