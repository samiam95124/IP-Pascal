!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
! GDB entry point delcaration                                                 !
!                                                                             !
! This file declares the "_main" entry point for the benifit of GDB.          !
! This module should be placed in the link sequence just before               !
! where you need the default debug location to be. GDB will both              !
! display the code around this location, and place a breakpoint               !
! at the "nop" instruction.                                                   !
! GDB tries to "find" the main procedure, and will typically fail             !
! on IP Pascal programs. The "nop" instruction prevents this from happening,  !
! and GDB will both start code display at the nop instruction, and set its    !
! first breakpoint there.                                                     !
! The "main" module can be placed just before whatever module in the link     !
! sequence that you want to debug.                                            !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

_main:
        nop
