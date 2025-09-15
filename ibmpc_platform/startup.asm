!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
!                            IP STANDALONE STARTUP                            !
!                                                                             !
! Performs a few startup functions, and exports the screen address for        !
! standard IBM-PC MDA text mode.                                              !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!
! Declare the MDA screen location
!
screen:	equ		$b8000

startup_start:
!
        cld                     ! clear direction flag
        fninit                  ! initalize FPU
        call    startup_end     ! execute next module
!
! if the program ever exits, just soft halt
!
        jmp		_
!
! End of startup module
!
startup_end:
