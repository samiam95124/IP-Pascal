!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                              !
!                           DYNAMIC MEMORY ALLOCATOR                           !
!                                                                              !
!                        COPYRIGHT (C) 2007 S. A. MOORE                        !
!                                                                              !
! Defines the functions to allocate dynamic memory.                            !
!                                                                              !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

        mov     eax,_vend       ! index the end of variable space
        mov     [heaptop],eax   ! place as current top of heap
        jmp     memman_end      ! skip module
!
! procedure memman_getspace(var bp: gbtptr; ln: integer); external;
!
! Allocate dynamic memory
!
! Allocates the given length of dynamic memory, and returns that to the caller.
! In this test version, we simply allocate memory without providing for it
! to be recycled.
!
memman_getspace:
        push    eax             ! save registers
        push    ecx
        mov     ecx,[heaptop]   ! get top of heap
        mov     [eax],ecx       ! place address
        add     eax,4           ! offset to length
        mov     [eax],ebx       ! set length
        add     ecx,ebx         ! offset heap top by length
        mov     [heaptop],ecx   ! place new heap top
        pop     ecx             ! clean up and return
        pop     eax
        ret
!
! procedure memman_putspace(bp: gbtptr); external;
!
! Free dynamic memory
!
! Presently a no-op.
!
memman_putspace:
        ret
!
! Data
!
heaptop: defvs  4               ! top of heap pointer
!
! End of device call module
!
memman_end:
