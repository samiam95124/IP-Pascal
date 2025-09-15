!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
!                            DEVICE CALL MODULE                               !
!                                                                             !
!                        COPYRIGHT (C) 2007 S. A. MOORE                       !
!                                                                             !
! Gives the ability to turn procedures in a driver into pointers, and the     !
! ability to then call those pointers.                                        !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

        jmp     devcal_end      ! skip module
!
! Get pointer to device call as vector
!
! The format of each call is:
!
! override(proc newadr, storeold: ^^integer);
!
! Where proc newadr is passed in eax (address) and ebx (frame), and the address
! to store the vector in ecx. We discard the frame pointer based on the idea
! that this routine is only called with top level procedures. There is no
! enforcement for this rule.
!
! procedure devcal_read_ptr(procedure device_read(var ba: bytarr; pos: integer; 
!                                                 var err: deverr);
!                           var pp: devcal_pp);
! procedure devcal_write_ptr(procedure device_write(view ba: bytarr; pos: integer; 
!                                                 var err: deverr);
!                           var pp: devcal_pp);
! procedure devcal_length_ptr(procedure device_length(var pos: integer; 
!                                                     var err: deverr);
!                           var pp: devcal_pp);
!
devcal_read_ptr:
devcal_write_ptr:
devcal_length_ptr:
        mov     [ecx],eax       ! place vector address
        ret                     ! exit
!
! Call device vector
!
! Each call has the vector address as the end parameter. This allows us to
! avoid reshuffling the parameters, we just jump to the vector.
!
! procedure devcal_read(var ba: bytarr; pos: integer; var err: deverr; 
!                       pp: devcal_pp); external;
!
devcal_read:   
        jmp     esi             ! go vector
!
! procedure devcal_write(view ba: bytarr; pos: integer; var err: deverr; 
!                        pp: devcal_pp); external;
!
devcal_write:   
        jmp     esi             ! go vector
!
! procedure devcal_length(var pos: integer; var err: deverr; 
!                         pp: devcal_pp); external;
!
devcal_length:   
        jmp     ecx             ! go vector
!
! End of device call module
!
devcal_end:
