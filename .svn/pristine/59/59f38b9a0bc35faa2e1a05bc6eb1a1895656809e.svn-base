!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
!                            BLOTTER DATA MODULE                              !
!                                                                             !
!                             2006/1 S. A. Moore                              !
!                                                                             !
! The "blotter" is a data structure that looks like a module. It contains a   !
! series of pointers to registration data, currently held in reglock.pas.     !
! The blotter is distinctive, and has a data string at the front that can be  !
! found by the release creator. It passes the necessary pointers to the       !
! release creator/installer so that it can modify the data for each computer. !
! When the release creator is finished with that, it wipes the blotter data   !
! area clean ("blots it out"). So effectively, the blotter just carries the   !
! data from the linker to the release creator, then is eliminated.            !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!
! Blotter data types
!
bdt_end:    equ 0 ! end of blotter data
bdt_macadr: equ 1 ! table of 10 mac addresses
bdt_cpustr: equ 2 ! table of 4 32 bit cpuid return words
bdt_winver: equ 3 ! 32 bit windows version number
bdt_timlim: equ 4 ! release time/date limit
!
! Module skip jump
!
        jmp     blotter_end     ! exit module
!
! Blotter id
!
        defb    'blotter!'      ! 8 byte id string
!
! Blotter data length
!
        defdw   blotter_end-_   ! set length of blotter data
!
! Blotter data
!
        defb    bdt_cpustr      ! cpuid string
        defdw   cpustr
!
        defb    bdt_macadr      ! mac address table
        defdw   macarr
!
        defb    bdt_winver      ! windows version
        defdw   vercmp        
!
        defb    bdt_timlim      ! release time limit
        defdw   timcmp
!
        defb    bdt_end         ! end of table
!
blotter_end:
