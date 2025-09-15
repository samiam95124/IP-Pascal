!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
! Interface windows procedure callback                                        !
!                                                                             !
! Gives a function to obtain the address of the windows callback procedure.   !
! this address will be a translator, that creates a dummy frame, translates   !
! parameters, and performs the callback, then undoes the frame and returns to !
! windows. Since windows calls us with no knowledge of block structure, this  !
! method is required.                                                         !
!                                                                             !
! The "thunk" is placed into a dynamically allocated block, then that is      !
! code modified to point to the passed class function. Then, the address of   !
! the thunk is returned. This is how we can allow for any class routine to be !
! adapted as a callback, and even have multiple class procedures.             !
!                                                                             !
! This function is dangerous when passed with a nested class function. For    !
! future improvement, we can have the main procedure save its stack level and !
! check if we are called at that to verify non-nested class functions.        !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!
! Startup
!
        jmp     winhan_end      ! skip over module

!
! Get address of windows procedure thunk
!

wndprocadr:
        pop     ebx             ! remove return address
        pop     edx             ! get address of class function
        pop     eax             ! dump dummy function return
        push    ebx             ! replace return address
!
! Allocate a code block to hold the thunk
!
        push    edx             ! save class function address
        xor     eax,eax         ! clear
        push    eax             ! place dummy fat pointer function return
        push    eax
        pushd   sc_gmem_fixed or sc_gmem_zeroinit ! place mode flags
        pushd   wndproct03-wndproct ! place length of thunk
        call    sc_globalalloc  ! allocate that
        pop     edi             ! get address
        pop     ecx             ! get length
        mov     esi,wndproct    ! index thunk
        mov     ebx,edi         ! save base location
        rep                     ! move the thunk
        movsb
        mov     eax,wndproct01-wndproct+1 ! find offset of call address
        add     eax,ebx
        pop     edx             ! restore class function address
! find net offset address class function
        mov     ecx,wndproct02-wndproct
        add     ecx,ebx
        sub     edx,ecx
        mov     [eax],edx       ! place class function address
        pop     eax             ! get return address
        push    ebx             ! place address of thunk
        jmpl    eax             ! return to caller
!
! Windows procedure translator
!
! This function is called directly by windows (as a callback), and
! we create a dummy stack frame, then call the windows handler
! procedure. Because windows does not know about framing, we have
! to do this.
!
! This code is just the prototype for the function. We place it in a
! dynamic block, and customize the called function address.
!
wndproct:     
        pop     eax             ! get return address
        pop     ebx             ! get wh
        pop     ecx             ! get imsg
        pop     edx             ! get wparam
        pop     esi             ! get lparam
        push    eax             ! replace return address
        enter   0,1             ! create the main frame
        pushd   0               ! place dummy return
        push    ebx             ! put wh
        push    ecx             ! put imsg
        push    edx             ! put wparam
        push    esi             ! put lparam
wndproct01:
        calll   0               ! call the function
wndproct02:
        pop     eax             ! get result
        leave                   ! remove dummy frame
        ret                     ! exit
wndproct03:
!
winhan_end:
