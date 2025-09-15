!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
!                         LINUX 80386 SYSTEM CALL WRAPPERS                    !
!                                                                             !
!                             2002/05 S. A. Moore                             !
!                                                                             !
! Defines the basic calls to Linux. The basic format of a Linux system call   !
! is as follows:                                                              !
!                                                                             !
! eax   Contains the sytem call number.                                       !
! ebx   Contains parameter 1 in left to right ordering.                       !
! ecx   Contains parameter 2 in left to right ordering.                       !
! edx   Contains parameter 3 in left to right ordering.                       !
! esi   Contains parameter 4 in left to right ordering.                       !
! edi   Contains parameter 5 in left to right ordering.                       !
!                                                                             !
! Then, an int $80 instruction is executed. After the call, any function      !
! result is found in eax.                                                     !
! Other than placing stack parameters into this format, what the wrapper does !
! is things such as translating Pascal mode strings to C zero terminated      !
! strings.                                                                    !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!
! Equations
!

wrapper_pagsiz: equ     $1000   ! 4kb 386 page

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
! Macro definitions                                                           !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!
! Macro: Perform convertions required on parameter before call is made
!
! The parameter gallery, indexed at the return, is assumed to be in
! eax. The offset specifies the location of the (address,length)
! pair for the string.
!
icvtpar: macro  param, offset

        if      'param' eq 'str' ! if it is a string

        ! convert length string to zero terminated string on stack

        mov     esi,offset[eax] ! get window name string address
        mov     ecx,offset+4[eax] ! get string length
        call    sc_strzer       ! place that on stack
        mov     offset[eax],edi ! replace address

        elseif  'param' eq 'pstr'

        ! convert length and right padded string to zero terminated
        ! string on stack

        mov     esi,offset[eax] ! get window name string address
        mov     ecx,offset+4[eax] ! get string length
        call    sc_pstrzer      ! place that on stack
        mov     offset[eax],edi ! replace address

        elseif  'param' eq 'pstrl'

        mov     esi,offset[eax] ! get window name string address
        mov     ecx,offset+4[eax] ! get string length
        call    sc_pstrzerl     ! process in place

        endif

        endmac
!
! Macro: Perform convertions required on parameter after call is made
!
! The parameter gallery, indexed at the return, is assumed to be in
! edx. The offset specifies the location of the (address,length)
! pair for the string.
!
ocvtpar: macro  param, offset

        if      'param' eq 'strlz' ! is it return string process

        ! convert length string zero termined in buffer to padded

        mov     esi,offset[edx] ! get window name string address
        mov     ecx,offset+4[edx] ! get string length
        call    sc_zstrpad      ! place that on stack

        endif

        endmac
!
! Macro: choose next register
!
! Changes "alcreg" to the next register in the sequence ebx, ecx, edx, esi,
! edi.
!
nxtreg: macro

        if      alcreg eq 'ebx'

alcreg: setequ  'ecx'

        elseif  alcreg eq 'ecx'

alcreg: setequ  'edx'

        elseif  alcreg eq 'edx'

alcreg: setequ  'esi'

        elseif  alcreg eq 'esi'

alcreg: setequ  'edi'

        endif

        endmac
!
! Macro: load  parameter to register. If it is a zero parameter, we
! load zero instead. If it is a null parameter, we do nothing.
! If its a string or fat pointer, we load it in the requested order.
!
lodpar: macro   param, offset

!
! Process parameter
!
        if      'param' eq 'zer'               ! if it is a zero

        assm    'mov ' cat alcreg cat ', 0'    ! load a zero
        nxtreg                                 ! next register

        elseif  ('param' eq 'strl') or ('param' eq 'ptrl') or \
                ('param' eq 'pstrl') or ('param' eq 'strlz')

        ! if it is a length string or length pointer

        assm    'mov ' cat alcreg cat ', offset[eax]' ! place address
        nxtreg                                 ! next register
        assm    'mov ' cat alcreg cat ', offset+4[eax]' ! place length
        nxtreg                                 ! next register

        elseif  ('param' eq 'lstr') or ('param' eq 'lptr')

        ! if it is a length string prefix or length pointer prefix

        assm    'mov ' cat alcreg cat ', offset+4[eax]' ! place length
        nxtreg                                 ! next register
        assm    'mov ' cat alcreg cat ', offset[eax]' ! place address
        nxtreg                                 ! next register

        elseif  'param' ne ''                  ! if it is not null

        assm    'mov ' cat alcreg cat ', offset[eax]'   ! place parameter in register
        nxtreg                                 ! next register

        endif

        endmac
!
! Macro: find length of single parameter, and add to total
!
lenpar: macro   lname, par

        if      ('par' eq 'str') or ('par' eq 'strl') or ('par' eq 'lstr') or \
                ('par' eq 'ptrl') or ('par' eq 'lptr') or  \
                ('par' eq 'strlz') or ('par' eq 'stab') or \
                ('par' eq 'pstr') or ('par' eq 'pstrl') 

! Double wide pointers

lname:  setequ  4+4

        elseif  ('par' eq 'int') or ('par' eq 'ptr') or ('par' eq 'bool') or \
                ('par' eq 'rtab') or ('par' eq 'unam')

! Single wide

lname:  setequ  4

        else

! Pseudo parameters (instructions without length)

lname:  setequ  0

        endif

        endmac
!
! Macro to define function
!
! The macro is of the form:
!
!    syscal sysint, name, ret, param1, param2, ..., param5
!
! The sysint number is the system call number to process via a int $80
! instruction.
!
! The name is the name of the function in this wrapper, and is coined
! with sc_ to form the address to call here.
!
! The ret indicates special handling given the function return.
!
! Each parameter indicates the type of the operand:
!
!    int     - Integer operands.
!    ptr     - Pointer to object. Treated as integer, but indicates type
!              better.
!    ptrl    - Fat pointer with length following.
!    lptr    - Fat pointer with length before.
!    str     - String, this is converted to zero terminated.
!    strl    - String, unterminated with length following (Pascal style).
!              Function same as ptrl, but indicates type better.
!    lstr    - String, unterminated with length preceeding.
!              Function same as lptr, but indicates type better.
!    strlz   - String with length following, converted from zero terminated on
!              return to padded.
!    pstr    - String, converted to zero terminated with right padding removed.
!    pstrl   - String, converted to zero terminated with right padding removed
!              and length following. If string equals length, zero is dropped.
!              Uses the original allocation, because this is var passed.
!    zer     - Zero, always pushes a zero.
!    bool    - Boolean.
!    stab    - String table, pointer to array of pstring to become char **
!    rtab    - Registers table, pointer to table of registers used in fork.
!    unam    - Translate uname structure on return.
!
! The following function return parameters are recognized:
!
!    void    - None. Its a procedure.
!    int     - Integer.
!    bool    - Boolean, these are "cleaned" so that r <> 0 -> 1, r = 0 -> 0.
!    ptr     - Pointer, treated as integer.
!    err     - Error code. If the return is negative, it is negated and placed
!              in sc_errno_sav, which is returned in errno.
!              The code is then replaced by -1. If there is no error, errno
!              gets cleared to zero.
!
! The 5 parameters recognised refer to the 5 parameters that fit into the
! system call registers ebx..edi. If calls need more parameters than that,
! we will have to add the ability to stack some of them.
! Needs > 5 parameter calls, there are some in list.
! wrapper_errno is cleared on every call.
!
syscal:  macro   sysint, name, ret, p1, p2, p3, p4, p5

sc_name:
!
! Calculate lengths and offsets of parameters
!
! This macro is a good case for repeat blocks and 'set' variables.
!
! Find the lengths of all parameters
!
        lenpar  l1, p1
        lenpar  l2, p2
        lenpar  l3, p3
        lenpar  l4, p4
        lenpar  l5, p5
!
! Find the total parameters length
!
parlen: setequ  l1+l2+l3+l4+l5
!
! Find the parameter addresses
!        
a1:     setequ  parlen+4-l1
a2:     setequ  a1-l2
a3:     setequ  a2-l3
a4:     setequ  a3-l4
a5:     setequ  a4-l5
!
! Now perform frame build
!
        mov     eax,esp         ! index stack
!
! Perform parameter conversions. Converted items can be buffered onto the
! stack, and the addresses are replaced back into the original parameter.
!
        icvtpar p1, a1          ! process input convertions
        icvtpar p2, a2
        icvtpar p3, a3
        icvtpar p4, a4
        icvtpar p5, a5
!
! Load parameters to their system call registers
!
        push    eax             ! save old stack top
alcreg: setequ  'ebx'           ! set ebx starting register
        lodpar  p1, a1
        lodpar  p2, a2
        lodpar  p3, a3
        lodpar  p4, a4
        lodpar  p5, a5
!
! Call function and clean up
!
	movd	[wrapper_errno],0 ! clear errno
        mov     eax,sysint      ! set system call number
        int     $80             ! execute system call
        pop     edx             ! restore old stack pointer
!
! Perform postcall convertions. Converted items are usually left in place
! in user buffers.
!
        ocvtpar p1, a1          ! process output convertions
        ocvtpar p2, a2
        ocvtpar p3, a3
        ocvtpar p4, a4
        ocvtpar p5, a5
!
! Continue postcall process
!
        mov     esp,edx         ! remove stack buffers
        pop     ebx             ! save return address
        add     esp,parlen      ! remove parameters

        if      'ret' eq 'err'  ! filter error

        or      eax,eax         ! check negative
        jns     syscal____01	! no, skip
        neg	eax		! form positive error code
	mov	[wrapper_errno],eax ! place that
	mov	eax,-1		! replace with standard error return
syscal____01:

        elseif  'ret' eq 'bool' ! filter boolean

        or      eax,eax
        setnz   al
        movzx   eax,al

        endif
        if  'ret' ne 'void' ! its a function

        pop     ecx             ! remove dummy return
        push    eax             ! replace actual return

        endif

        jmpl    ebx             ! return to caller

        endmac

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
! Module startup                                                              !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

        nop                     ! this gives braindamaged GDB the ability to
                                ! break on entry
        mov     [wrapper_argloc],esp ! save location of argc/argv array
        mov     eax,0           ! clear return code
        mov     [wrapper_exit_code],eax
        mov     eax,_vend       ! index the end of variable space
        mov     [wrapper_heap],eax ! place as heap top
        mov     [wrapper_limit],eax ! place as limit
!
! We are having an odd problem with Linux where it "forgets" our .bss
! allocation unless it is specifically set with brk(). So we set the _vend
! mark with brk().
!
        mov     ebx,eax         ! place limit
        mov     eax,45          ! set system call "brk"
        int     $80             ! execute system call
        call    wrapper_end     ! execute next module
        mov     ebx,[wrapper_exit_code] ! load the exit code
        mov     eax,1           ! set "exit" system call
        int     $80             ! execute system call
        jmpl    _               ! should not come back

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
! Parameter process routines                                                  !
!                                                                             !
! These routines provide backup to the system call macros. They are routines  !
! that take a few register based parameters, preserve no registers, and       !
! typically allocate items on the stack.                                      !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Allocate string on stack, move and zero terminate
!
! Expects the string address in esi, and the length in ecx.
! Returns the address of the zero terminated string in edi.
! The new string is allocated on the stack, evened up to the
! next word. The caller is responsible for storing the previous
! stack value, and restoring that.
!
sc_strzer:
        pop     ebx             ! get return address
        mov     edx,ecx         ! get the length
        inc     edx             ! add one for zero termination
        and     edx,$fffffffc   ! even to dword to maintain stack align
        add     edx,4           ! account for partial word
        sub     esp,edx         ! allocate string buffer on stack
        mov     edi,esp         ! index that
        mov     edx,esp         ! and save starting address
        rep                     ! move string to buffer
        movsb
        movb    [edi],0         ! zero terminate buffer
        mov     edi,edx         ! place new string address
        jmp     ebx             ! return to caller

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Allocate padded string on stack, move and zero terminate
!
! Expects the string address in esi, and the length in ecx.
! Returns the address of the zero terminated string in edi.
! The new string is allocated on the stack, evened up to the
! next word. The caller is responsible for storing the previous
! stack value, and restoring that.
! The zero termination is adjusted so that any right side padding is removed,
! but the full allocation is left at the 
!
sc_pstrzer:
        pop     ebx             ! get return address
        mov     edx,ecx         ! get the length
        inc     edx             ! add one for zero termination
        and     edx,$fffffffc   ! even to dword to maintain stack align
        add     edx,4           ! account for partial word
        sub     esp,edx         ! allocate string buffer on stack
        mov     edi,esp         ! index that
        mov     edx,esp         ! and save starting address
        rep                     ! move string to buffer
        movsb
        movb    [edi],0         ! zero terminate buffer
!
! Now back up over any right side blanks
!
sc_pstrzer01:
        dec     edi             ! back up
        cmp     edx,edi         ! check at start
        je      sc_pstrzer02    ! yes, skip
        cmpb    [edi],' '       ! check blank
        je      sc_pstrzer01    ! yes, loop
sc_pstrzer02:
        cmpb    [edi],' '       ! check zero length case
        jz      sc_pstrzer03    ! yes, skip
        inc     edi             ! index last blank seen
sc_pstrzer03:
        movb    [edi],0         ! zero terminate buffer
        mov     edi,edx         ! place new string address
        jmp     ebx             ! return to caller

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Process buffer string
!
! Given a buffer padded string in esi with length ecx, finds the leftmost
! of any right space padding and places a zero there, which effectively
! converts it to zero terminated.
! If there is no right padding, the string is left as is.
!
sc_pstrzerl:
        cmp     ecx,0           ! check zero
        jz      sc_pstrzerl03   ! exit if so
        mov     edi,esi         ! copy start
        add     edx,ecx         ! index end
        dec     edi
        cmpb    [edi],' '       ! check blank
        jne     sc_pstrzerl03   ! no, exit
sc_pstrzerl01:
        dec     edi             ! back up
        cmp     esi,edi         ! check at start
        je      sc_pstrzerl02   ! yes, skip
        cmpb    [edi],' '       ! check blank
        je      sc_pstrzerl01   ! yes, loop
sc_pstrzerl02:
        inc     edi             ! index last space
        movb    [edi],0         ! terminate
sc_pstrzerl03:
        ret                     ! exit

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Process buffer string to padded
!
! Given a buffer padded string in esi with length ecx, finds the zero
! terminating it, and pads to the end of the string. If there is no zero, it
! means the string occupies the entire buffer, so we leave it alone.
!
sc_zstrpad:
        or      ecx,ecx         ! check end of string
        jz      sc_zstrpad02    ! yes, exit
        mov     al,[esi]        ! find terminating zero
        or      al,al
        jz      sc_zstrpad01    ! found
        inc     esi             ! next
        dec     ecx
        jmp     sc_zstrpad      ! loop
sc_zstrpad01:
        movb    [esi],' '       ! place padding
        inc     esi             ! advance
        dec     ecx
        or      ecx,ecx         ! check done
        jnz     sc_zstrpad01    ! no, loop
sc_zstrpad02:
        ret                     ! exit

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
! Start of support routines                                                   !
!                                                                             !
! These routines are necessary system functions that are provided in the      !
! wrapper itself. They may or may not make system calls.                      !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! sc_alloc
!
! This is the internal interface to malloc. The length of the buffer requested
! is passed in eax, and the resulting allocation is returned in eax. If the
! heap overflows, then zero will be returned. Preserves all registers
! except eax.
!
! This routine correctly handles the case where a zero length block is passed
! by returning a non-zero pointer for that.
!
! Memory is allocated from Unix in page size chunks, which for the 386
! is 4kb pages. The heap increases in arbitrary values, but when the current
! 4kb allocation fails, we extend it by another 4kb. This presumably keeps
! down the number of OS calls. Note that if a huge allocation is requested,
! the entire number of pages is allocated in a single Unix call.
!
! This is the bringup allocator, and does not yet have arena headers and
! free() behavior.
!
! In parameters: eax = length of requested block.
!
! Out parameters: eax = address of block or zero if fault.
!

sc_alloc:
        push    ebx
        mov     ebx,[wrapper_heap] ! get the current heap top
        add     eax,ebx         ! find the new heap top
        mov     [wrapper_heap],eax ! place that
        cmp     eax,[wrapper_limit] ! check past the block limit
        jl      sc_alloc01      ! no, skip
!
! Heap has passed the block limit, allocate new block
!
        push    ebx             ! save the base pointer
        mov     ebx,[wrapper_heap] ! get the new heap
        add     ebx,wrapper_pagsiz ! add a page to it
        mov     [wrapper_limit],ebx ! replace
        mov     eax,45          ! set system call "brk"
        int     $80             ! execute system call
        pop     ebx             ! restore base pointer
!
! brk() could have returned an error, but we ignore it here. The practical
! result of overruning the heap is to cause a page fault. We may improve
! this error reporting later.
!
sc_alloc01:               
        mov     eax,ebx         ! place base pointer
        pop     ebx
        ret

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! sc_malloc
!
! procedure sc_malloc(var p: gbtptr; length: integer);
!
! Malloc is implemented here. We allocate storage starting at _vend, the 
! variables end location. We have to detect if we are crossing 4kb pages,
! and issue a brk call if so to get the next page.
!
sc_malloc:
        pop     edi             ! get return address
        pop     ecx             ! get length requested
        pop     edx             ! get address of pointer
        push    edi             ! replace return address
        mov     eax,ecx         ! place length
        call    sc_alloc        ! get the block
        mov     [edx],eax       ! place address to pointer
        add     edx,4           ! index length
        mov     [edx],ecx       ! place length
        ret                     ! done

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! sc_free
!
! procedure sc_free(p: gbtptr);
!
! This is a dummy procedure for the bringup.
!
sc_free:
        pop     ebx             ! get return address
        pop     eax             ! dump address
        pop     eax             ! dump length
        jmpl    ebx             ! return to caller

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! procedure sc_getcmd(var cmd: pstring);
!
! Allocates a new string on heap and loads the command line, including the
! program name, to the given string buffer. The pointer is nulled if heap
! overflows.
!
sc_getcmd:
        pop     eax             ! get return address
        pop     edi             ! get pstring address
        push    eax             ! replace return address
        mov     ecx,0           ! clear string length
        mov     edx,[wrapper_argloc] ! get argc/argv pointer
        add     edx,4           ! skip argc, we don't need it
        mov     ebx,edx         ! save start of array
!
! First pass over argvs counts the total length, with blanks between args.
!
sc_getcmd01:
        mov     esi,[edx]       ! get next string pointer
        add     edx,4           ! index next
        or      esi,esi         ! check end of array
        jz      sc_getcmd04     ! yes, terminate
sc_getcmd02:
        movb    al,[esi]        ! get a character
        or      al,al           ! check end
        jz      sc_getcmd03     ! yes, next string
        inc     ecx             ! count character
        inc     esi             ! next character
        jmp     sc_getcmd02     ! loop next character
sc_getcmd03:
        mov     esi,[edx]       ! check next string exists
        or      esi,esi
        jz      sc_getcmd04     ! no, just terminate
        inc     ecx             ! count space between argvs
        jmp     sc_getcmd01     ! loop next argv
sc_getcmd04:
!
! Allocate final string.
!
        mov     edx,ebx         ! restore argv address
        mov     eax,ecx         ! get length of command line
        call    sc_alloc        ! allocate it
        mov     [edi],eax       ! place address of that
        add     edi,4           ! index length
        mov     [edi],ecx       ! place length
        or      eax,eax         ! check zero address (fault)
        jnz     sc_getcmd05     ! no, skip
        mov     [edi],eax       ! clear length as well
        jmp     sc_getcmd09     ! and exit
sc_getcmd05:
        mov     edi,eax         ! place address of array
!
! Rerun data pass, placing data this time.
!
sc_getcmd06:
        mov     esi,[edx]       ! get next string pointer
        add     edx,4           ! index next
        or      esi,esi         ! check end of array
        jz      sc_getcmd09     ! yes, terminate
sc_getcmd07:
        movb    al,[esi]        ! get a character
        or      al,al           ! check end
        jz      sc_getcmd08     ! yes, next string
        movb    [edi],al        ! place character
        inc     edi
        inc     esi             ! next character
        jmp     sc_getcmd07     ! loop next character
sc_getcmd08:
        mov     esi,[edx]       ! check next string exists
        or      esi,esi
        jz      sc_getcmd09     ! no, just terminate
        movb    [edi],' '       ! place separator space
        inc     edi
        jmp     sc_getcmd06     ! loop next argv
sc_getcmd09:
        ret                     ! complete

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Find length of zero terminated string
!
! In parameters: eax = zero terminated string address.
!
! Out parameters: eax = length of string.
!
sc_lenstr:
        push    esi
        push    ecx
        mov     esi,eax         ! place string address
        mov     ecx,0           ! clear length
sc_lenstr01:
        mov     al,[esi]        ! get character
        or      al,al           ! check zero
        jz      sc_lenstr02     ! yes, exit
        inc     esi             ! next
        inc     ecx
        jmp     sc_lenstr01     ! loop next
sc_lenstr02:
        mov     eax,ecx         ! get length
        pop     ecx             ! restore and return
        pop     esi
        ret

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! get Unix environment
!
! function sc_allenv: sc_envptr;
!
sc_allenv:
        pop     edi             ! get return address
        pop     eax             ! remove dumy return
        pop     eax
        push    edi             ! replace return address
        mov     esi,[wrapper_argloc] ! get the start of the argloc array
        mov     eax,[esi]       ! get argc
        add     esi,4+4         ! skip argc and termination zero word
        add     esi,eax         ! add argc*4 to skip argv array
        add     esi,eax
        add     esi,eax
        add     esi,eax
        push    esi             ! save base address
        mov     ecx,0           ! clear environment string count
sc_allenv01:
        mov     eax,[esi]       ! get the next pointer
        add     esi,4           ! index next
        inc     ecx
        or      eax,eax         ! find end of argv array
        jnz     sc_allenv01     ! loop
        pop     esi             ! restore base address
        dec     ecx             ! back out last count
!
! Allocate a block for fat pointers the same length as environments
!
        mov     eax,ecx         ! get count
        add     eax,eax         ! find * 8 for fat pointers
        add     eax,eax         ! * 4
        add     eax,eax         ! * 8
        mov     ebx,eax         ! save total block length
        call    sc_alloc        ! gets the pointer array block
        or      eax,eax         ! check allocation failed
        jz      sc_allenv03     ! yes, go error
        mov     edi,eax         ! place base
        mov     edx,eax         ! save base of block
!
! Now we have simple pointers in esi, complex in edi, translate
!
sc_allenv02:
        mov     eax,[esi]       ! get string address
        call    sc_lenstr       ! find length of source string
        movsd                   ! move the base address
        stosd                   ! place the length
        loop    sc_allenv02     ! repeat for all pointers
        jmp     sc_allenv04     ! exit
!
! Clear result for error
!
sc_allenv03:
        mov     ebx,0           ! clear length
        mov     edx,0           ! clear address
!
! Done, return address of pstring block
!
sc_allenv04:
        pop     eax             ! save return address
        push    ebx             ! save length of table
        push    edx             ! save base
        jmpl    eax             ! return to caller

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! get Unix error code
!
! function sc_errno: integer;
!
! Returns the errno variable, which was set by the last routine that caused an
! error. Its a function to upper callers for maximum flexability.
!
sc_errno:
        pop     ebx             ! get return address
        pop     eax             ! dispose of dummy return
        pushd   [wrapper_errno] ! push the error code
        jmpl    ebx             ! return to caller

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
! Start of wrapper definitions                                                !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

        syscal  1, exit, void, int
        syscal  2, fork, err, rtab
        syscal  3, read, err, int, ptrl 
        syscal  4, write, err, int, ptrl
        syscal  5, open, err, pstr, int, int
        syscal  6, close, err, int
        syscal  7, waitpid, err, int, int, int
        syscal  8, creat, err, pstr, int
        syscal  9, link, err, pstr, pstr
        syscal  10, unlink, err, pstr
        syscal  11, execve, err, pstr, stab, stab
        syscal  12, chdir, err, pstr
        syscal  13, time, err, ptr
        syscal  14, mknod, err, pstr, int, int
        syscal  15, chmod, err, pstr, int
        syscal  16, lchown, err, pstr, int, int
        syscal  17, break, err ! not implemented
        syscal  18, oldstat, err ! obsolete
        syscal  19, lseek, err, int, int, int
        syscal  20, getpid, err
        syscal  21, mount, err, pstr, pstr, pstr, int, zer ! no data area pass
        syscal  22, umount, err, pstr
        syscal  23, setuid, err, int
        syscal  24, getuid, err
        syscal  25, stime, err, ptr
        syscal  26, ptrace, err, int, int, ptr, ptr ! contains void pointers
        syscal  27, alarm, int, int
        syscal  28, oldfstat, err ! obsolete
        syscal  29, pause, err
        syscal  30, utime, err, pstr, ptr
        syscal  31, stty, err ! not implemented
        syscal  32, gtty, err ! not implemented
        syscal  33, access, err, pstr, int
        syscal  34, nice, err, int
        syscal  35, ftime, err ! not implemented
        syscal  36, sync, void
        syscal  37, kill, err, int, int
        syscal  38, rename, err, pstr, pstr
        syscal  39, mkdir, err, pstr, int
        syscal  40, rmdir, err, pstr
        syscal  41, dup, err, int
        syscal  42, pipe, err, ptr
        syscal  43, times, err, ptr
        syscal  44, prof, err ! not implemented
        syscal  45, brk, err, int
        syscal  46, setgid, err, int
        syscal  47, getgid, err
        syscal  48, signal, err ! requires callback translator
        syscal  49, geteuid, err
        syscal  50, getegid, err
        syscal  51, acct, err, pstr
        syscal  52, umount2, int, pstr, int
        syscal  53, lock, err ! ? need information
        syscal  54, ioctl, err, int, int, ptr ! need to study this
        syscal  55, fcntl, err, int, int, ptr
        syscal  56, mpx, err ! ? Need information
        syscal  57, setpgid, err, int, int
        syscal  58, ulimit, err, int ! ? Docs say this is not a system call
        syscal  59, oldolduname, err ! ? Docs says removed
        syscal  60, umask, int, int
        syscal  61, chroot, err, pstr
        syscal  62, ustat, err ! ? Docs say this is not a system call
        syscal  63, dup2, err, int, int
        syscal  64, getppid, int
        syscal  65, getpgrp, err
        syscal  66, setsid, err
        syscal  67, sigaction, err, int, ptr, ptr ! needs callback translation
        syscal  68, sgetmask, err ! ? need info
        syscal  69, ssetmask, err ! ? need info
        syscal  70, setreuid, err, int, int
        syscal  71, setregid, err, int, int
        syscal  72, sigsuspend, err ! ? need info
        syscal  73, sigpending, err ! ? need info
        syscal  74, sethostname, err, pstrl
        syscal  75, setrlimit, err, int, ptr
        syscal  76, getrlimit, err, int, ptr
        syscal  77, getrusage, err, int, ptr
        syscal  78, gettimeofday, err, ptr, ptr
        syscal  79, settimeofday, err, ptr, ptr
        syscal  80, getgroups, err, lptr
        syscal  81, setgroups, err, lptr
        syscal  82, select, err, lptr, ptr int ! ? needs help
        syscal  83, symlink, err, pstr, pstr
        syscal  84, oldlstat, err ! ? Docs say removed
        syscal  85, readlink, err, pstr, strlz
        syscal  86, uselib, err, pstr
        syscal  87, swapon, err
        syscal  88, reboot, err, int, int, int, ptr ! ? need info on last argument
        syscal  89, readdir, err, int, ptr, int
        syscal  90, mmap, err, ptrl, int, int, int, int, int ! too many registers ?
        syscal  91, munmap, err, ptrl
        syscal  92, truncate, err, pstr, int
        syscal  93, ftruncate, err, int, int
        syscal  94, fchmod, err, int, int
        syscal  95, fchown, err, int, int, int
        syscal  96, getpriority, err, int, int
        syscal  97, setpriority, err, int, int, int
        syscal  98, profil, err, ptrl, int, int ! Docs say removed
        syscal  99, statfs, err, pstr, ptr
        syscal  100, fstatfs, err, int, ptr
        syscal  101, ioperm, err, int, int, int
        syscal  102, socketcall, err, int, ptr ! ? more information needed on 2nd arg
        syscal  103, syslog, err, int, int, ptrl
        syscal  104, setitimer, err, int, ptr, ptr
        syscal  105, getitimer, err, int, ptr
        syscal  106, stat, err, pstr, ptr
        syscal  107, lstat, err, pstr, ptr
        syscal  108, fstat, err, int, ptr
        syscal  109, olduname, err ! docs say removed
        syscal  110, iopl, err, int
        syscal  111, vhangup, err
        syscal  112, idle, void
        syscal  113, vm86old, err, ptr
        syscal  114, wait4, err, int, int, int, ptr
        syscal  115, swapoff, err, pstr
        syscal  116, sysinfo, err, ptr
!        syscal  117, ipc, err, int, int, int, int, ptr, int ! need more information
        syscal  118, fsync, err, int
        syscal  119, sigreturn, err, int
!        syscal  120, clone, err, int, ptr ! docs disagree on format of this
        syscal  121, setdomainname, err, pstr
        syscal  122, uname, err, unam
!        syscal  123, modify_ldt, err, int, ptrl ! void pointer
        syscal  124, adjtimex, err, ptr
        syscal  125, mprotect, err, ptrl, int
        syscal  126, sigprocmask, err, int, ptr, ptr
        syscal  127, create_module, err, pstr, int
        syscal  128, init_module, err, str, ptr
        syscal  129, delete_module, err, pstr
        syscal  130, get_kernel_syms, err, ptr
        syscal  131, quotactl, err, int, pstr, int, ptr
        syscal  132, getpgid, err, int
        syscal  133, fchdir, err, int
        syscal  134, bdflush, err, int, ptr
        syscal  135, sysfs, err ! ? need more info
        syscal  136, personality, err, int
        syscal  137, afs_syscall, err ! Docs say not implemented
        syscal  138, setfsuid, int, int
        syscal  139, setfsgid, int, int
        syscal  140, _llseek, err, int, int, int, ptr, int
        syscal  141, getdents, err, int, ptrl
        syscal  142, _newselect, err, int, ptr, ptr, ptr, ptr ! don't know how to represent this
        syscal  143, flock, err, int, int
        syscal  144, msync, err, ptrl, int ! contains hard addresses
        syscal  145, readv, err, int, ptrl
        syscal  146, writev, err, ptrl
        syscal  147, getsid, err, int
        syscal  148, fdatasync, err, int
        syscal  149, _sysctl, err, ptr ! contains hard addresses in structure
        syscal  150, mlock, err, ptr, int ! contains hard addresses
        syscal  151, munlock, err, ptr, int ! contains hard addresses
        syscal  152, mlockall, err, int
        syscal  153, munlockall, err
        syscal  154, sched_setparam, err, int, ptr
        syscal  155, sched_getparam, err, int, ptr
        syscal  156, sched_setscheduler, err, int, int, ptr
        syscal  157, sched_getscheduler, err, int
        syscal  158, sched_yield, err
        syscal  159, sched_get_priority_max, err, int
        syscal  160, sched_get_priority_min, err, int
        syscal  161, sched_rr_get_interval, err, int, ptr
        syscal  162, nanosleep, err, ptr, ptr
        syscal  163, mremap, err, ptrl, ptrl, int
        syscal  164, setresuid, err, int, int, int
        syscal  165, getresuid, err, ptr, ptr, ptr
        syscal  166, vm86, err, int, ptr
        syscal  167, query_module, err, pstr, int, ptrl, ptr
        syscal  168, poll, err, ptrl, int
        syscal  169, nfsservctl, err, int, ptr, ptr
        syscal  170, setresgid, err, int, int, int
        syscal  171, getresgid, err, ptr, ptr, ptr
        syscal  172, prctl, err, int, int, int, int, int
        syscal  173, rt_sigreturn, err ! need information
        syscal  174, rt_sigaction, err, int, ptr, ptr ! need information
        syscal  175, rt_sigprocmask, err ! need information
        syscal  176, rt_sigpending, err ! need information
        syscal  177, rt_sigtimedwait, err ! need information
        syscal  178, rt_sigqueueinfo, err, int, int, ptr ! need information
        syscal  179, rt_sigsuspend, err ! need information
        syscal  180, pread, err, int, ptrl, int
        syscal  181, pwrite, err, int, ptrl, int
        syscal  182, chown, err, pstr, int, int
        syscal  183, getcwd, err, strlz
        syscal  184, capget, err, ptr, ptr
        syscal  185, capset, err, ptr, ptr
        syscal  186, sigaltstack, err, ptr, ptr, int
        syscal  187, sendfile, err, int, int, ptr, int
        syscal  188, getpmsg, err ! not implemented
        syscal  189, putpmsg, err ! not implemented
        syscal  190, vfork, err
        syscal  191, ugetrlimit, err
        syscal  192, mmap2, err, ptr, int, int, int, int ! contains hard addresses
        syscal  193, truncate64, err, pstr, int, int
        syscal  194, ftruncate64, err, int, int, int
        syscal  195, stat64, err, pstr, ptr, int
        syscal  196, lstat64, err, pstr, ptr, int
        syscal  197, fstat64, err, int, ptr, int
        syscal  198, lchown32, err, pstr, int, int
        syscal  199, getuid32, err
        syscal  200, getgid32, err
        syscal  201, geteuid32, err
        syscal  202, getegid32, err
        syscal  203, setreuid32, err, int, int
        syscal  204, setregid32, err, int, int
        syscal  205, getgroups32, err, lptr
        syscal  206, setgroups32, err, lptr
        syscal  207, fchown32, err, int, int, int
        syscal  208, setresuid32, err, int, int, int
        syscal  209, getresuid32, err, ptr, ptr, ptr
        syscal  210, setresgid32, err, int, int, int
        syscal  211, getresgid32, err, ptr, ptr, ptr
        syscal  212, chown32, err, pstr, int, int
        syscal  213, setuid32, err, int
        syscal  214, setgid32, err, int
        syscal  215, setfsuid32, err, int
        syscal  216, setfsgid32, err, int
        syscal  217, pivot_root, err, pstr, pstr
        syscal  218, mincore, err, ptr, int, ptr ! contains hard addresses
        syscal  219, madvise, err, ptr, int, int ! contains hard addresses
        syscal  219, madvise1, err, ptr, int, int ! contains hard addresses
        syscal  220, getdents64, err, int, ptr, int
        syscal  221, fcntl64, err, int, int, int

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
! Data                                                                        !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

wrapper_exit_code: defvs   4    ! exit code holder
wrapper_argloc:    defvs   4    ! location of argc/argv array
wrapper_heap:      defvs   4    ! current heap top
wrapper_limit:     defvs   4    ! current heap block limit in 4k pages
wrapper_errno:     defvs   4    ! errno code store
!
wrapper_end:
