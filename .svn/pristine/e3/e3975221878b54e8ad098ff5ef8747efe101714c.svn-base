!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
!                 WINDOWS 32 BIT I80386 SYSTEM CALL WRAPPER MACROS            !
!                                                                             !
!                       Copyright (C) 2006 Scott A. Moore                     !
!                                                                             !
! Defines the basic wrappers for entering Windows 32 bit system calls. These  !
! wrappers are dependent on both the I80686 calling convention and Windows,   !
! but this module should be all that is changed when a new calling convention !
! is used.                                                                    !
!                                                                             !
! A general macro system is used to make the wrapper for each function. The   !
! parameters are stored on the stack, then any Pascal->C convertion of        !
! parameters is done, then the system function called, any C->Pascal          !
! convertions done, and clean up and return.                                  !
!                                                                             !
! The system used is flexible. Either the general macro can be used, or the   !
! function can be directly encoded by hand, or any mix of the two.            !
!                                                                             !
! The wrapper conventions are described further in the file "ptocmac.txt"     !
!                                                                             !
! Notes:                                                                      !
!                                                                             !
! 1. Right now, we save and restore all flags and registers. This may not     !
! be absolutely required, since the _stdcall convention is supposed to save   !
! certain registers, supposedly the ebx, esi, edi and ebp registers.          !
! This behavior is centralized in the rstall/savall macros, but each custom   !
! wrapper may have to be checked to see if it modifies other registers.       !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!
! Enable or disable character translation mode
!
        include xltmod
!
! Equations
!
!
! Layout of windows class record
!
sc_wndclass_style:              equ     0
sc_wndclass_wndproc:            equ     4
sc_wndclass_clsextra:           equ     8
sc_wndclass_wndextra:           equ     12
sc_wndclass_instance:           equ     16
sc_wndclass_icon:               equ     20
sc_wndclass_cursor:             equ     24
sc_wndclass_background:         equ     28
sc_wndclass_menuname:           equ     32
sc_wndclass_classname:          equ     36
sc_wndclass_classname_p:        equ     40      ! same thing in Pascal mode

!
! Global allocation flags
!
sc_GMEM_FIXED:                  equ $0000
sc_GMEM_MOVEABLE:               equ $0002
sc_GMEM_NOCOMPACT:              equ $0010
sc_GMEM_NODISCARD:              equ $0020
sc_GMEM_ZEROINIT:               equ $0040
sc_GMEM_MODIFY:                 equ $0080
sc_GMEM_DISCARDABLE:            equ $0100
sc_GMEM_NOT_BANKED:             equ $1000
sc_GMEM_SHARE:                  equ $2000
sc_GMEM_DDESHARE:               equ $2000
sc_GMEM_NOTIFY:                 equ $4000
sc_GMEM_LOWER:                  equ sc_GMEM_NOT_BANKED
sc_GMEM_VALID_FLAGS:            equ $7F72
sc_GMEM_INVALID_HANDLE:         equ $8000

!
! Register code equivalences
!
reg_nul: equ    0
reg_eax: equ    1
reg_ebx: equ    2
reg_ecx: equ    3
reg_edx: equ    4
reg_esi: equ    5
reg_edi: equ    6

!
! Others
!
true:          equ     -1
false:         equ     0
!
! Some of the callbacks don't work unless the stack is isolated. This is
! likely because the stack depth for the calls made in the handler is to
! deep for the (unspecified) depth of the stack Windows uses during the
! callback. This parameter sets the isolation stack depth, which should be
! enough to allow reasonable nesting, while not wasting memory.
!
stackthunklen: equ     1024*100  ! length of stack for callback thunk

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
! Macro definitions                                                           !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Macro: convert windows class Pascal version to C version. The windows
! class is different because the menu and class names are strings
! must be converted.
!
wccvt: macro offset

        sub     esp,10*4        ! allocate new class record
        mov     esi,offset[eax] ! get base of class record
        mov     edi,esp         ! index class record
        mov     ecx,8           ! set length without strings
        rep                     ! move that portion of record
        movsd                   
        mov     ebx,esp         ! index new class record
        mov     edi,offset[eax] ! get base of class record
        mov     esi,sc_wndclass_menuname[edi] ! get menu string address
        mov     ecx,sc_wndclass_menuname+4[edi] ! get length
        or      esi,esi         ! check null string
        mov     edi,esi         ! move to destination
        jz      wccvt______01   ! yes, skip
        call    sc_pstrzer       ! place menu string
wccvt______01:
        mov     sc_wndclass_menuname[ebx],edi ! place string address
        mov     edi,offset[eax] ! get base of class record
        mov     esi,sc_wndclass_classname_p[edi] ! get class string address
        mov     ecx,sc_wndclass_classname_p+4[edi] ! get length
        or      esi,esi         ! check null string
        mov     edi,esi         ! move to destination
        jz      wccvt______02   ! yes, skip
        call    sc_pstrzer       ! place class string
wccvt______02:
        mov     sc_wndclass_classname[ebx],edi ! place string address
        mov     offset[eax],ebx ! replace old with new class record

endmac

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Macro: Perform convertions required on parameter.
!
! The parameter gallery, indexed at the return, is assumed to be in
! eax. The offset specifies the location of the (address,length)
! pair for the string.
!
icvtpar: macro param, offset

   if 'param' eq 'str' ! if it is a string

      ! convert length string to zero terminated string on stack
      mov     esi,offset[eax] ! get window name string address
      mov     ecx,offset+4[eax] ! get string length
      call    sc_strzer       ! place that on stack
      mov     offset[eax],edi ! replace address

   elseif  'param' eq 'pstrz'

      ! convert length and right padded string to zero terminated
      ! string on stack
      mov     esi,offset[eax] ! get window name string address
      mov     ecx,offset+4[eax] ! get string length
      call    sc_pstrzer      ! place that on stack
      mov     offset[eax],edi ! replace address

   elseif  ('param' eq 'strl') or ('param' eq 'lstr')

      if      xltmod          ! if encoding is enabled

      ! Convert length and right padded string to zero terminated
      ! string on stack. This is just to get the string encoded.
      ! The zero termination is not used.
      mov     esi,offset[eax] ! get window name string address
      mov     ecx,offset+4[eax] ! get string length
      call    sc_strzer       ! place that on stack
      mov     offset[eax],edi ! replace address

      endif

   elseif 'param' eq 'wclsptr' ! its a windows class pointer

      wccvt offset ! convert to windows class

   elseif 'param' eq 'evl' ! its an environment stringset

      mov     ebx,offset[eax] ! index 1st string entry
      or      ebx,ebx         ! check none
      jz      icvtpar______   ! skip if so
      call    sc_cntenv       ! count environment strings space
      and     ecx,$fffffffc   ! even to dword for stack align
      add     ecx,4
      sub     esp,ecx         ! allocate space for that
      mov     edi,esp         ! index buffer
      call    sc_movenv       ! move the environment there
      mov     offset[eax],esp ! replace parameter pointer
      icvtpar______:          ! here to skip

   endif

endmac

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Macro: Perform convertions required on parameter after call is made
!
! The parameter gallery, indexed at the return, is assumed to be in
! edx. The offset specifies the location of the (address,length)
! pair for the string.
!
ocvtpar: macro  param, offset

        ! is it return string process
        if      ('param' eq 'zstrp') or ('param' eq 'zstrpd') or \
                ('param' eq 'lzstrp')

        ! convert length string zero termined in buffer to padded

        mov     esi,offset[edx] ! get window name string address
        mov     ecx,offset+4[edx] ! get string length
        call    sc_zstrpad      ! place that on stack

        elseif  ('param' eq 'strlo')

        if      xltmod          ! encoding is enabled

        ! convert length string to encoded

        mov     esi,offset[edx] ! get window name string address
        mov     ecx,offset+4[edx] ! get string length
        call    sc_strenc       ! place that on stack

        endif

        endif

        endmac

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Macro: push parameter on stack. If it is a zero parameter, we
! push zero instead. If it is a null parameter, we do nothing.
!
lodpar: macro param, offset

   !
   ! Process parameter
   !
   if 'param' eq 'zer' ! if it is a zero

      pushd 0  ! just push a zero

   elseif 'param' eq 'one' ! if it is a one

      pushd   1 ! just push a one

   elseif  ('param' eq 'strl') or ('param' eq 'ptrl') or \
           ('param' eq 'zstrp') or ('param' eq 'strlo')

      ! address/length pair
      pushd  offset+4[eax] ! place length
      pushd  offset[eax]   ! place address

   elseif  ('param' eq 'lstr') or ('param' eq 'lzstrp')

      ! length/address pair
      pushd offset[eax]   ! place address
      pushd offset+4[eax] ! place length

   elseif  'param' ne '' ! if it is not null

      pushd offset[eax] ! place parameter on stack

   endif

endmac

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Macro: find if parameter is tgp, and if fits in register. Allocate if so.
!
plctgp: macro alc, addr, par

   if ('par' eq 'str') or ('par' eq 'strl') or ('par' eq 'ptrl') or \
      ('par' eq 'lstr') or ('par' eq 'zstrp') or ('par' eq 'zstrpd') or \
      ('par' eq 'lzstrp') or ('par' eq 'pstrz') or ('par' eq 'ptrd') or \
      ('par' eq 'strlo')

      ! Its a tagged pointer

      if regnum lt reg_esi

         ! Registers are not full

         addr: setequ stkoff ! allocate par
         stkoff: setequ stkoff+8 ! next allocation
         regnum: setequ regnum+2 ! next register
         alc: setequ true ! set allocated

      endif

   endif

endmac

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Macro: find if parameter is standard, and if fits in register. Allocate if 
! so.
!
plcstd: macro alc, addr, par

   if ('par' eq 'int') or ('par' eq 'ptr') or ('par' eq 'bool') or \
      ('par' eq 'wclsptr') or ('par' eq 'evl')

      ! Its a standard (32 bit) parameter
      if regnum lt reg_edi

         ! Registers are not full
         addr: setequ stkoff ! allocate on register offset
         stkoff: setequ stkoff+4 ! next allocation
         regnum: setequ regnum+1 ! next register
         alc: setequ true ! set allocated

      endif

   endif

endmac

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Macro: find if parameter is tgp, and has not been given a register.
! It is placed in the overflow area if so.
!
ovftgp: macro alc, addr, par

   if ('par' eq 'str') or ('par' eq 'strl') or ('par' eq 'ptrl') or \
      ('par' eq 'lstr') or ('par' eq 'zstrp') or ('par' eq 'zstrpd') or \
      ('par' eq 'lzstrp') or ('par' eq 'pstrz') or ('par' eq 'ptrd') or \
      ('par' eq 'strlo')

      ! Its a tagged pointer

      if not alc

         ! Not in a register
         addr: setequ stkoff ! allocate par1
         stkoff: setequ stkoff+8 ! next allocation
         ovfsiz: setequ ovfsiz+8 ! add to overflow space
         alc: setequ true ! set allocated

      endif

   endif

endmac

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Macro: find if parameter is standard, and has not been given a register.
! It is placed in the overflow area if so.
!
ovfstd: macro alc, addr, par

   if ('par' eq 'int') or ('par' eq 'ptr') or ('par' eq 'bool') or \
      ('par' eq 'wclsptr') or ('par' eq 'evl')

      ! Its a standard (32 bit) parameter
      if not alc

         ! not in register
         addr: setequ stkoff ! allocate on register offset
         stkoff: setequ stkoff+4 ! next allocation
         ovfsiz: setequ ovfsiz+4 ! add to overflow space
         alc: setequ true ! set allocated

      endif

   endif

endmac

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Macro: Save all registers and flags
!
savall: macro

   pushfd
   pushad

endmac

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Macro: Restore all registers and flags
!
rstall: macro

   popad
   popfd

endmac

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Macro: Restore all registers and flags except for eax. Used to preserve
! function results.
!
rstfnc: macro

   pop edi ! restore registers and flags
   pop esi
   pop ebp
   add esp,4 ! pass esp
   pop ebx
   pop edx
   pop ecx
   add esp,4 ! pass eax
   popfd

endmac

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Macro: Restore all registers and flags except for eax and ebx. Used to 
! preserve function results for tagged pointer results.
!
rstptr: macro

   pop edi ! restore registers and flags
   pop esi
   pop ebp
   add esp,8 ! pass esp and ebx
   pop edx
   pop ecx
   add esp,4 ! pass eax
   popfd

endmac

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Macro to define regular function
!
! The macro is of the form:
!
!    ptocf entryname, functionname, param1, param2, ..., param14
!
! Each parameter indicates the type of the operand:
!
!    int     - Integer operands, 32 bit, signed.
!    ptr     - Pointer to object.
!    ptrl    - Fat pointer with length following.
!    ptrd    - Pointer with length dropped.
!    str     - String, this is converted to zero terminated.
!    strl    - String, unterminated with length following (Pascal style).
!    lstr    - String, unterminated with length preceeding.
!    zstrp   - String with length following, converted from zero terminated on
!              return to padded.
!    lzstrp  - String with length following, converted from zero terminated on
!              return to padded. As zstrp, but the C call is length/address.
!    zstrpd  - String with length following, converted from zero terminated on
!              return to padded. The C call has the length dropped.
!    strlo   - String with length following, used as an output buffer. This
!              code is identical to strl on unencoded applications, but with
!              encoded applications, it converts the output.
!    pstrz   - String, converted to zero terminated with right padding removed.
!    zer     - Zero, allways pushes a zero.
!    one     - One, allways pushes a one.
!    bool    - Boolean.
!    wclsptr - Windows class record pointer. This whole record is converted
!              from Pascal to C style.
!    evl     - Environment stringset.
!
! The following return parameters are recognized:
!
!    void    - None. Its a procedure.
!    int     - Integer.
!    bool    - Boolean, these are "cleaned" so that r <> 0 -> 1, r = 0 -> 0.
!    ptr     - Pointer, treated as integer.
!
! Note: This wrapper does not handle reals or sreals. Also, C (normal C) does
! not have call by value parameters larger than int, so we don't have to
! implement special handling for extended parameter pointers.
!
! Note: I think we need a new convention that makes it clear when convertsions
! are applied. For example, 'i' appended for input convertions, 'o' for output.
!
ptocf: macro name, function, pret, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, \
                                  p11, p12, p13, p14

! print 'Function: name'
! print 'Equ Function: function'
! print 'P1: p1'
! print 'P2: p2'
! print 'P3: p3'
   sc_name:
   !
   ! Register allocation pass
   !
   ! Each of the tagged or standard parameters are placed in registers.
   !
   regnum: setequ  reg_nul ! set the number of registers allocated
   stkoff: setequ  0 ! set stack offset
   al1: setequ false ! set parameters not allocated
   al2: setequ false
   al3: setequ false
   al4: setequ false
   al5: setequ false
   al6: setequ false
   al7: setequ false
   al8: setequ false
   al9: setequ false
   al10: setequ false
   al11: setequ false
   al12: setequ false
   al13: setequ false
   al14: setequ false
   a1: setequ 0
   a2: setequ 0
   a3: setequ 0
   a4: setequ 0
   a5: setequ 0
   a6: setequ 0
   a7: setequ 0
   a8: setequ 0
   a9: setequ 0
   a10: setequ 0
   a11: setequ 0
   a12: setequ 0
   a13: setequ 0
   a14: setequ 0
   !
   ! Tagged
   !
   plctgp al1, a1, p1 ! place tagged parameters as available
   plctgp al2, a2, p2
   plctgp al3, a3, p3
   plctgp al4, a4, p4
   plctgp al5, a5, p5
   plctgp al6, a6, p6
   plctgp al7, a7, p7
   plctgp al8, a8, p8
   plctgp al9, a9, p9
   plctgp al10, a10, p10
   plctgp al11, a11, p11
   plctgp al12, a12, p12
   plctgp al13, a13, p13
   plctgp al14, a14, p14
   !
   ! Standard
   !
   plcstd al1, a1, p1 ! place standard parameters as available
   plcstd al2, a2, p2
   plcstd al3, a3, p3
   plcstd al4, a4, p4
   plcstd al5, a5, p5
   plcstd al6, a6, p6
   plcstd al7, a7, p7
   plcstd al8, a8, p8
   plcstd al9, a9, p9
   plcstd al10, a10, p10
   plcstd al11, a11, p11
   plcstd al12, a12, p12
   plcstd al13, a13, p13
   plcstd al14, a14, p14
   !
   ! Overflow allocation pass
   !
   ! Each of the tagged or standard parameters that were not placed in
   ! registers in the last pass are allocated into the overflow area.
   !
   stkoff: setequ stkoff+4+4+8*4 ! skip over return address and saves to overflow
                                 ! area
   ovfsiz: setequ 0 ! clear overflow space
   !
   ! Tagged
   !
   ovftgp al1, a1, p1 ! place tagged parameters as available
   ovftgp al2, a2, p2
   ovftgp al3, a3, p3
   ovftgp al4, a4, p4
   ovftgp al5, a5, p5
   ovftgp al6, a6, p6
   ovftgp al7, a7, p7
   ovftgp al8, a8, p8
   ovftgp al9, a9, p9
   ovftgp al10, a10, p10
   ovftgp al11, a11, p11
   ovftgp al12, a12, p12
   ovftgp al13, a13, p13
   ovftgp al14, a14, p14
   !
   ! Standard
   !
   ovfstd al1, a1, p1 ! place standard parameters as available
   ovfstd al2, a2, p2
   ovfstd al3, a3, p3
   ovfstd al4, a4, p4
   ovfstd al5, a5, p5
   ovfstd al6, a6, p6
   ovfstd al7, a7, p7
   ovfstd al8, a8, p8
   ovfstd al9, a9, p9
   ovfstd al10, a10, p10
   ovfstd al11, a11, p11
   ovfstd al12, a12, p12
   ovfstd al13, a13, p13
   ovfstd al14, a14, p14
   !
   ! Save the registers so they are protected
   !
   savall
   !
   ! Save register parameters onto stack. These will join the right to left
   ! ordering of parameters so that lowest on stack is first parameter, and
   ! highest on stack is last parameter.
   !
   if regnum ge reg_edi; push edi; endif
   if regnum ge reg_esi; push esi; endif
   if regnum ge reg_edx; push edx; endif
   if regnum ge reg_ecx; push ecx; endif
   if regnum ge reg_ebx; push ebx; endif
   if regnum ge reg_eax; push eax; endif
   !
   ! Now perform frame build
   !
   mov eax,esp ! index stack in eax, because that is the result reg
   !
   ! Perform parameter conversions. Converted items can be buffered onto the
   ! stack, and the addresses are replaced back into the original parameter.
   !
   icvtpar p1, a1 ! process convertions
   icvtpar p2, a2
   icvtpar p3, a3
   icvtpar p4, a4
   icvtpar p5, a5
   icvtpar p6, a6
   icvtpar p7, a7
   icvtpar p8, a8
   icvtpar p9, a9
   icvtpar p10, a10
   icvtpar p11, a11
   icvtpar p12, a12
   icvtpar p13, a13
   icvtpar p14, a14
   !
   ! Construct calling frame, from right to left (C style)
   !
   push eax ! save old stack top
   lodpar p14,a14 ! process pushes
   lodpar p13,a13
   lodpar p12,a12
   lodpar p11,a11
   lodpar p10,a10
   lodpar p9,a9
   lodpar p8,a8
   lodpar p7,a7
   lodpar p6,a6
   lodpar p5,a5
   lodpar p4,a4
   lodpar p3,a3
   lodpar p2,a2
   lodpar p1,a1
   !
   ! Call function and clean up
   !
   calll [function] ! execute function
   pop edx        ! restore old stack pointer
   !
   ! Perform postcall convertions. Converted items are usually left in place
   ! in user buffers.
   !
   ocvtpar p1, a1 ! process convertions
   ocvtpar p2, a2
   ocvtpar p3, a3
   ocvtpar p4, a4
   ocvtpar p5, a5
   ocvtpar p6, a6
   ocvtpar p7, a7
   ocvtpar p8, a8
   ocvtpar p9, a9
   ocvtpar p10, a10
   ocvtpar p11, a11
   ocvtpar p12, a12
   ocvtpar p13, a13
   ocvtpar p14, a14
   !
   ! Continue postcall process
   !
   mov esp,edx    ! remove stack buffers
   add esp,regnum*4 ! remove parameters
   if 'pret' eq 'bool' ! filter boolean

      or eax,eax   ! check zero
      setnz al     ! set zero status
      movzx eax,al ! extend to 32 bits

   endif
   if 'pret' ne 'void'; rstfnc ! its a function, restore all but eax
   else; rstall ! its a procedure, restore flags and registers
   endif
   if ovfsiz gt 0 ! not a null parameter overflow block

      xchg eax,[esp] ! trade for return address
      mov ovfsiz[esp],eax ! save return address ontop overflow area
      mov eax,[esp] ! get eax
      lea esp,ovfsiz[esp] ! remove parameters without changing flags
      ret ! exit

   else

      ret ! exit

   endif

endmac

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
! Module startup                                                              !
!                                                                             !
! Module start clears the return code, then calls the next module in line.    ! 
! The return code is kept in a ram location, and the program can modify that. !
! This is how exit with return value is done.                                 !
! On exit, we fetch the return value and execute a formal exit. The reason    !
! for the formal exit call is I have seen various tasks/processes "stuck"     !
! (zombie process) after a normal return, so the formal process end provides  !
! better clean up.                                                            !                   
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

        cld                     ! clear direction flag
        fninit                  ! initalize FPU
        fldcw   [sc_fpuctl]     ! load FPU control word
        mov     eax,0           ! clear return code
        mov     [windows_exit_code],eax
        call    windows_end     ! execute next module
        mov     eax,[windows_exit_code] ! load the exit code
        push    eax             ! place as parameter
        calll   [kernel32_exitprocess] ! perform exit
! should not execute past this point
        ret                     ! exit to windows

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
! Special implementations                                                     !
!                                                                             !
! The following are system calls which have special implementation not        !
! covered by the macro system.                                                !
!                                                                             !
! Many, or perhaps all, of these functions should be moved to macro           !
! implementations so that they are not dependent on calling conventions.      !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! function sc_globalalloc(flg: integer; len: integer): gbtptr;
!
sc_globalalloc:
        savall                  ! save registers and flags
        or      ebx,ebx         ! check zero length
        jne     sc_globalalloc01 ! no, skip
!
! If the length of the block is 0, then we cannot and should not pass this on
! to the OS. But a block of 0 length is not the same as a nil pointer. So we
! must point somewhere. We use location $00000001, which will not equal nil,
! but causes a fault if accessed.
!
        mov     eax,$00000001   ! place address
        mov     ebx,0           ! place length
        jmp     sc_globalalloc02 ! exit
!        
sc_globalalloc01:
        push    ebx             ! save length
        push    ebx             ! place length
        push    eax             ! place mode flags
        calll   [kernel32_globalalloc]  ! call function
        pop     ebx             ! restore length
sc_globalalloc02:
        rstptr                  ! restore all but eax/ebx
        ret                     ! exit

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! function sc_globalfree(bp: gbtptr): integer;
!
sc_globalfree:
        savall                  ! save registers and flags
!
! Check for the special $00000001 address, which is used for 0 length
! allocations. We don't return this to the OS.
!               
        cmp     eax,$00000001   ! check special address
        jnz     sc_globalfree01 ! no, skip
        mov     eax,0           ! set ok status
        jmp     sc_globalfree02 ! exit
!
sc_globalfree01:
        push    eax             ! place handle
        calll   [kernel32_globalfree] ! call function
sc_globalfree02:
        rstfnc                  ! restore all but eax
        ret                     ! exit

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! function sc_getcommandlinea: pstring; { command string pointer }
!
! The command line is received and copied to a dynamic string, then that is
! returned. The caller is responsible for disposing of the string.
!

!### Checked for non-encode case, encode case

sc_getcommandline:
sc_getcommandlinea:
        savall                  ! save registers and flags
        calll   [kernel32_getcommandlinea] ! call function
!
! Find the length of the string
!
        mov     edi,eax         ! get string address
        xor     ecx,ecx         ! clear count
sc_getcommandline01:
        cmpb    [edi],0         ! check zero
        je      sc_getcommandline010 ! yes, skip
        inc     edi             ! next
        inc     ecx             ! count
        jmp     sc_getcommandline01 ! loop
sc_getcommandline010:
!
! Get a buffer to place string in
!
        push    eax             ! save source string address
        push    ecx             ! save length
        push    ecx             ! place length on stack
        pushd   sc_gmem_fixed   ! place flags
        calll   [kernel32_globalalloc] ! allocate buffer
        or      eax,eax         ! check no space
        mov     ebx,eax         ! zero length as well
        jz      sc_getcommandline03 ! yes, exit with nil return
!
! Move to buffer
!
        pop     ecx             ! restore length
        pop     esi             ! restore source string address
        mov     edi,eax         ! place destination
        mov     ebx,ecx         ! save length
sc_getcommandline02:
        or      ecx,ecx         ! check done
        jz      sc_getcommandline03 ! yes, skip
        movzxb  edx,[esi]       ! get a character zero extended
        if      xltmod          ! translation enabled
        movb    dl,xlttbl[edx]  ! translate character
        endif
        movb    [edi],dl        ! place
        inc     esi             ! next
        inc     edi
        dec     ecx             ! count
        jmp     sc_getcommandline02 ! loop
sc_getcommandline03:
        rstptr                  ! restore all but eax/ebx
        ret                     ! exit
                

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! function sc_getenvironmentstringsa: sc_evsptr;
!
! We translate each string to a pair of dymamic entries and form a list,
! so the table is fully buffered.
!

!### Checked for non-encode case, encode case

sc_getenvironmentstrings:
sc_getenvironmentstringsa:
        savall                  ! save registers and flags
        calll   [kernel32_getenvironmentstringsa] ! call function
        ord     eax,eax         ! check null result
        jz      sc_getenvironmentstringsa07 ! yes, skip
!
! Keep beginning of list on stack, last entry above that
!
        pushd   0               ! set list root null
        pushd   0               ! set last entry null
sc_getenvironmentstringsa01:
        movzxb  ebx,[eax]       ! check for end of table
        ord     ebx,ebx
        jz      sc_getenvironmentstringsa06 ! yes, terminate
        movd    edx,eax         ! save start of string
        movd    ecx,0           ! clear string count
sc_getenvironmentstringsa02:
        movzxb  ebx,[eax]       ! check end
        incd    eax             ! next
        incd    ecx             ! count
        ord     ebx,ebx
        jnz     sc_getenvironmentstringsa02 ! loop for string 
        decd    ecx             ! back out 0 
        pushd   eax             ! save table address
        pushd   edx             ! save start of string
        pushd   ecx             ! save string length
        pushd   ecx             ! place length on stack
        pushd   sc_gmem_fixed   ! place flags
        calll   [kernel32_globalalloc]   ! allocate
        ord     eax,eax         ! check bad
        jz      sc_getenvironmentstringsa05 ! yes, dump and return zero
        pop     ecx             ! restore string count
        pop     esi             ! get the string address
        push    ecx             ! save string count
        mov     edi,eax         ! place destination
        pushd   eax             ! save string address
sc_getenvironmentstringsa020:
        movzxb  eax,[esi]       ! get character
        if      xltmod          ! if translation enabled
        movb    al,xlttbl[eax]  ! translate character
        endif
        mov     [edi],al        ! place
        inc     esi             ! next
        inc     edi
        dec     ecx             ! count
        jnz     sc_getenvironmentstringsa020 ! loop
        pushd   4*3             ! allocate link record
        pushd   sc_gmem_fixed   ! place flags
        calll   [kernel32_globalalloc]   ! allocate
        ord     eax,eax         ! check bad
        jz      sc_getenvironmentstringsa05 ! yes, dump and return zero
        popd    ebx             ! restore string address
        popd    ecx             ! restore string length
        pushd   eax             ! save start
        movd    [eax],ebx       ! place string address in rec
        addd    eax,4           ! index next
        movd    [eax],ecx       ! place string length
        addd    eax,4           ! index next
        movd    [eax],0         ! clear last link
        popd    eax             ! restore start
        popd    edx             ! restore table pointer
        popd    ebx             ! restore last entry
        popd    ecx             ! restore list start
        ord     ebx,ebx         ! check there was a last entry
        jz      sc_getenvironmentstringsa03 ! no
        addd    ebx,8           ! offset to next link
        mov     [ebx],eax       ! place link
sc_getenvironmentstringsa03:
        ord     ecx,ecx         ! check list start is established
        jnz     sc_getenvironmentstringsa04 ! yes
        movd    ecx,eax         ! no, set it
sc_getenvironmentstringsa04:
        pushd   ecx             ! place list start
        pushd   eax             ! place new last
        movd    eax,edx         ! replace table pointer
        jmp     sc_getenvironmentstringsa01 ! loop next entry
sc_getenvironmentstringsa05:
        popd    eax             ! dump the table constructed and error
        popd    eax
        movd    eax,0
        jmp     sc_getenvironmentstringsa07
sc_getenvironmentstringsa06:
        popd    eax             ! dump last entry
        popd    eax             ! recover table start
sc_getenvironmentstringsa07:
        rstfnc                  ! restore all but eax
        ret                     ! exit

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! function sc_gettickcount: integer;
!
sc_gettickcount:
        savall                  ! save registers and flags
        calll   [kernel32_gettickcount]  ! call function
!
! To return the unsigned count as a signed integer, we must mask off the
! sign bit. This reduces the system time rollover to 49/2 days.
!
        and     eax,$7fffffff   ! remove high bit
        rstfnc                  ! restore all but eax
        ret

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! function sc_getlasterror: integer;
!
sc_getlasterror:
        savall                  ! save registers and flags
        calll   [kernel32_getlasterror] ! call function
!
! Only the lower 16 bits actually contain the error code
!
        and     eax,$0000ffff   ! remove high bits
        rstfnc                  ! restore all but eax
        ret

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Get address of windows procedure thunk
!
! function sc_wndprocadr(function wndproc(hwnd, imsg, wparam, lparam: integer)
!    : integer): integer; begin end;
!
! Gives a function to obtain the address of the windows callback procedure.
! this address will be a translator, that creates a dummy frame, translates
! parameters, and performs the callback, then undoes the frame and returns to
! windows. Since windows calls us with no knowledge of block structure, this
! method is required.
!
! The "thunk" is placed into a dynamically allocated block, then that is
! code modified to point to the passed class function. Then, the address of
! the thunk is returned. This is how we can allow for any class routine to be
! adapted as a callback, and even have multiple class procedures.
!
! This function is dangerous when passed with a nested class function. For
! future improvement, we can have the main procedure save its stack level and
! check if we are called at that to verify non-nested class functions.
!
! 2005/12/09 [sam] modified the thunk to save all registers modified but
! the function return eax. I noticed that a couple of the common control
! callbacks were picky about their register preservations, so this should
! make the routine more generally applicable.
!
sc_wndprocadr:
!
! Allocate a code block to hold the thunk
!
        savall                  ! save registers and flags
        push    eax             ! save class function address
        mov     eax,sc_gmem_fixed or sc_gmem_zeroinit ! place mode flags
        mov     ebx,sc_wndproct03-sc_wndproct ! place length of thunk
        call    sc_globalalloc  ! allocate that
        mov     edi,eax         ! place address
        mov     ecx,ebx         ! place length
        mov     esi,sc_wndproct ! index thunk
        mov     ebx,edi         ! save base location
        rep                     ! move the thunk
        movsb
        mov     eax,sc_wndproct01-sc_wndproct+1 ! find offset of call address
        add     eax,ebx
        pop     edx             ! restore class function address
! find net offset address class function
        mov     ecx,sc_wndproct02-sc_wndproct
        add     ecx,ebx
        sub     edx,ecx
        mov     [eax],edx       ! place class function address
        mov     eax,ebx         ! place address of thunk for return
        rstfnc                  ! restore all but eax
        ret                     ! exit
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
sc_wndproct:     
!
! Get parameters in registers, and save current contents
!
        mov     eax,4[esp]     ! get hwnd
        xchg    ebx,8[esp]     ! get imsg
        xchg    ecx,12[esp]    ! get wparam
        xchg    edx,16[esp]    ! get lparam
!
! Create new frame and call IP function
!
        enter   0,1            ! create the main frame
sc_wndproct01:
        calll   0              ! call the function
sc_wndproct02:
        leave                  ! remove dummy frame
!
! Restore registers
!
        mov     ebx,8[esp]     ! get imsg
        mov     ecx,12[esp]    ! get wparam
        mov     edx,16[esp]    ! get lparam
        ret     16             ! exit and remove parameters
sc_wndproct03:

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Create thread
!
! function sc_createthread_nn(ss: integer; procedure thread; f: integer;
!    var ti: integer): integer; begin end;
!
! Calls the thread thread with null for thread attributes and parameter pointer.
! creates a procedure translator for the thread procedure.
!
sc_createthread_nn:
        savall                  ! save registers and flags
        push    esi             ! place thread id
        push    edx             ! place creation flags
        pushd   0               ! no parameter pointer
        push    ecx             ! save stack size
        push    eax             ! save procedure pointer
!
! Allocate a code block to hold the thunk
!
        mov     eax,sc_gmem_fixed or sc_gmem_zeroinit ! place mode flags
        mov     ebx,sc_thproct03-sc_thproct ! place length of thunk
        call    sc_globalalloc  ! allocate that
        mov     edi,eax         ! place address
        mov     ecx,ebx         ! place length
        mov     esi,sc_thproct  ! index thunk
        mov     ebx,edi         ! save base location
        rep                     ! move the thunk
        movsb
        mov     eax,sc_thproct01-sc_thproct+1 ! find offset of call address
        add     eax,ebx
        pop     edx             ! restore procedure pointer
! find net offset address thread procedure
        mov     ecx,sc_thproct02-sc_thproct
        add     ecx,ebx
        sub     edx,ecx
        mov     [eax],edx       ! place class function address
        pop     esi             ! get stack size
        push    ebx             ! place thunk address
        push    esi             ! replace stack size
        pushd   0               ! no thread attribute structure
        calll   [kernel32_createthread] ! execute thread create
        rstfnc                  ! restore all but eax
        ret                     ! exit
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
sc_thproct:     
        enter   0,1             ! create the main frame
sc_thproct01:
        calll   0               ! call the function
sc_thproct02:
        leave                   ! remove dummy frame
        ret                     ! exit
sc_thproct03:

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Setconsolectrlhandler
!
! function sc_setconsolectrlhandler(function ctlhan(ct: sc_dword): boolean; 
!    a: boolean): boolean;
!
! Sets up a console control handler thunk.
!
sc_setconsolectrlhandler:
        savall                  ! save registers and flags
!
! Allocate a code block to hold the thunk
!
        push    ecx             ! save flag
        push    eax             ! save handler function address
        mov     eax,sc_gmem_fixed or sc_gmem_zeroinit ! place mode flags
        mov     ebx,sc_conhant03-sc_conhant ! place length of thunk
        call    sc_globalalloc  ! allocate that
        mov     edi,eax         ! place address
        mov     ecx,ebx         ! place length
        mov     esi,sc_conhant  ! index thunk
        mov     ebx,edi         ! save base location
        rep                     ! move the thunk
        movsb
        mov     eax,sc_conhant01-sc_conhant+1 ! find offset of call address
        add     eax,ebx
        pop     edx             ! restore handler function address
! Find net offset address class function
        mov     ecx,sc_conhant02-sc_conhant
        add     ecx,ebx
        sub     edx,ecx
        mov     [eax],edx       ! place handler function address
        push    ebx             ! place address of thunk
        calll   [kernel32_setconsolectrlhandler] ! set the handler
! Rationalize boolean result
        or eax,eax              ! check zero
        setnz al                ! set zero status
        movzx eax,al            ! extend to 32 bits
        rstfnc                  ! restore all but eax
        ret                     ! exit
!
! Windows procedure translator
!
! This function is called directly by windows (as a callback), and
! we create a dummy stack frame, then call the control handler
! procedure. Because windows does not know about framing, we have
! to do this.
!
! This code is just the prototype for the function. We place it in a
! dynamic block, and customize the called function address.
!
sc_conhant:     
        pop     edi             ! get return address
        pop     eax             ! get ctrl type
        push    edi             ! replace return address
        enter   0,1             ! create the main frame
sc_conhant01:
        calll   0               ! call the function
sc_conhant02:
        leave                   ! remove dummy frame
        ret                     ! exit
sc_conhant03:

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Enumfontfamiliesex
!
! function sc_enumfontfamiliesex(h: sc_hdc; var lf: sc_logfont;
!   function ef(var lfd: sc_enumlogfontex; var pfd: sc_newtextmetricex;
!   ft: sc_dword; ad: sc_lparam): boolean; lp: sc_lparam; f: sc_dword): integer;
!
! Registers a callback for font emuneration, then the OS calls that several
! times and returns to the caller.
!
sc_enumfontfamiliesex:
        savall                  ! save registers and flags
!
! Allocate a code block to hold the thunk
!
        push    edi             ! save flag
        push    esi             ! save lparam
        push    edx             ! save font info pointer
        push    ecx             ! save handle to device context
        push    eax             ! save handler function address
        mov     eax,sc_gmem_fixed or sc_gmem_zeroinit ! place mode flags
        mov     ebx,sc_fenumpt03-sc_fenumpt ! place length of thunk
        call    sc_globalalloc  ! allocate that
        mov     edi,eax         ! place address
        mov     ecx,ebx         ! place length
        mov     esi,sc_fenumpt  ! index thunk
        mov     ebx,edi         ! save base location
        rep                     ! move the thunk
        movsb
        mov     eax,sc_fenumpt01-sc_fenumpt+1 ! find offset of call address
        add     eax,ebx
        pop     edx             ! restore handler function address
! find net offset address class function
        mov     ecx,sc_fenumpt02-sc_fenumpt
        add     ecx,ebx
        sub     edx,ecx
        mov     [eax],edx       ! place handler function address
        pop     eax             ! get handle to device context
        pop     ecx             ! get font info pointer
        push    ebx             ! place address of thunk
        push    ecx             ! place font info pointer
        push    eax             ! place handle to device context
        calll   [gdi32_enumfontfamiliesexa] ! execute function
        rstfnc                  ! restore all but eax
        ret                     ! exit
!
! Windows procedure translator
!
! This function is called directly by windows (as a callback), and
! we create a dummy stack frame, then call the control handler
! procedure. Because windows does not know about framing, we have
! to do this.
!
! This code is just the prototype for the function. We place it in a
! dynamic block, and customize the called function address.
!
sc_fenumpt:     
        pop     edi             ! get return address
        pop     eax             ! get logical font
        pop     ebx             ! get physical font data
        pop     ecx             ! get type of font
        pop     edx             ! get applications data
        push    edi             ! replace return address
        enter   0,1             ! create the main frame
sc_fenumpt01:
        calll   0               ! call the function
sc_fenumpt02:
        leave                   ! remove dummy frame
        ret                     ! exit
sc_fenumpt03:

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! timesetevent
!
! function sc_timesetevent(d, r: sc_uint;
!    procedure tp(id, m: sc_uint; u, dw1, dw2: sc_dword); u: sc_dword;
!    f: sc_uint): sc_mmresult;
!
! Registers a callback for a multimedia timer.
!
sc_timesetevent:
        savall                  ! save registers and flags
!
! Allocate a code block to hold the thunk
!
        push    edi             ! save flags
        push    esi             ! save user data
        push    edx             ! save resolution
        push    ecx             ! save delay
        push    eax             ! save handler function address
        mov     eax,sc_gmem_fixed or sc_gmem_zeroinit ! place mode flags
! place length of thunk+stack save+stack
        mov     ebx,sc_timrpt06-sc_timrpt
        call    sc_globalalloc  ! allocate that
        mov     edi,eax         ! place address
        mov     ecx,ebx         ! place length
        mov     esi,sc_timrpt   ! index thunk
        mov     ebx,edi         ! save base location
        rep                     ! move the thunk
        movsb
        mov     eax,sc_timrpt01-sc_timrpt+1 ! find offset of call address
        add     eax,ebx
        pop     edx             ! restore handler function address
! find net offset address class function
        mov     ecx,sc_timrpt02-sc_timrpt
        add     ecx,ebx
        sub     edx,ecx
        mov     [eax],edx       ! place handler function address
! set parameters for OS call
        pop     eax             ! get delay
        pop     ecx             ! get resolution
        push    ebx             ! place address of thunk
        push    ecx             ! place resolution
        push    eax             ! place delay
        calll   [winmm_timesetevent] ! execute function
        rstfnc                  ! restore all but eax
        ret                     ! exit
!
! Windows procedure translator
!
! This function is called directly by windows (as a callback), and
! we create a dummy stack frame, then call the control handler
! procedure. Because windows does not know about framing, we have
! to do this.
!
! This code is just the prototype for the function. We place it in a
! dynamic block, and customize the called function address.
!
sc_timrpt:     
        pop     edi             ! get return address
        pop     eax             ! get id
        pop     ebx             ! get msg
        pop     ecx             ! get user data
        pop     edx             ! get dw1
        pop     esi             ! get dw2
        push    edi             ! replace return address
        enter   0,1             ! create the main frame
sc_timrpt01:
        calll   0               ! call the procedure
sc_timrpt02:
        leave                   ! remove dummy frame
        ret                     ! exit
sc_timrpt06:

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
! preserves eax and ebx.
!

!### Checked for non-encode case

sc_strzer:
        pop     edi             ! get return address
        mov     edx,ecx         ! get the length
        inc     edx             ! add one for zero termination
        and     edx,$fffffffc   ! even to dword to maintain stack align
        add     edx,4           ! account for partial word
        sub     esp,edx         ! allocate string buffer on stack
        mov     edx,esp         ! and save starting address
        push    edi             ! place return on stack
        mov     edi,edx         ! index string in edi
        push    edx             ! save string address
        or      ecx,ecx         ! check null string
        jz      sc_strzer02     ! yes, skip
sc_strzer01:
        movzxb  edx,[esi]       ! get byte as zero extended dword
        if      xltmod          ! if translation enabled
        movb    dl,nrmtbl[edx]  ! translate character
        endif
        mov     [edi],dl        ! place
        inc     edi             ! next addresses
        inc     esi
        dec     ecx
        jnz     sc_strzer01     ! loop
sc_strzer02:
        movb    [edi],0         ! zero terminate buffer
        pop     edi             ! place new string address
        ret                     ! return to caller

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Allocate padded string on stack, move and zero terminate
!
! Expects the string address in esi, and the length in ecx.
! Returns the address of the zero terminated string in edi.
! The new string is allocated on the stack, evened up to the
! next word. The caller is responsible for storing the previous
! stack value, and restoring that.
!
! The zero termination is adjusted so that any right side padding is removed,
! but the full allocation is left at the stack address.
!
! Preserves eax, ebx.
!

!### Checked for non-encode case, encode case

sc_pstrzer:
        pop     edi             ! get return address
        mov     edx,ecx         ! get the length
        inc     edx             ! add one for zero termination
        and     edx,$fffffffc   ! even to dword to maintain stack align
        add     edx,4           ! account for partial word
        sub     esp,edx         ! allocate string buffer on stack
        mov     edx,esp         ! get starting address
        push    edi             ! place return on stack
        mov     edi,edx         ! index string
        push    ebx             ! save ebx
        or      ecx,ecx         ! check null string
        jz      sc_pstrzer02    ! yes, skip
sc_pstrzer01:
        movzxb  ebx,[esi]       ! get byte as zero extended dword
        if      xltmod          ! if translation enabled
        movb    bl,nrmtbl[ebx]  ! translate character
        endif
        mov     [edi],bl        ! place
        inc     edi             ! next addresses
        inc     esi
        dec     ecx
        jnz     sc_pstrzer01    ! loop
sc_pstrzer02:
        movb    [edi],0         ! zero terminate buffer
        cmp     edx,edi         ! check zero length case
        je      sc_pstrzer05    ! yes, skip
!
! Now back up over any right side blanks
!
sc_pstrzer03:
        dec     edi             ! back up
        cmp     edx,edi         ! check at start
        je      sc_pstrzer04    ! yes, skip
        cmpb    [edi],' '       ! check blank
        je      sc_pstrzer03    ! yes, loop
sc_pstrzer04:
        cmpb    [edi],' '       ! check zero length case
        jz      sc_pstrzer05    ! yes, skip
        inc     edi             ! index last blank seen
sc_pstrzer05:
        movb    [edi],0         ! zero terminate buffer
        mov     edi,edx         ! place new string address
        pop     ebx             ! restore ebx
        ret                     ! return to caller

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Process buffer string to padded
!
! Given a buffer padded string in esi with length ecx, finds the zero
! terminating it, and pads to the end of the string. If there is no zero, it
! means the string occupies the entire buffer, so we leave it alone.
!

!### Checked for non-encode case, encode case

sc_zstrpad:
        or      ecx,ecx         ! check end of string
        jz      sc_zstrpad02    ! yes, exit
        movzxb  ebx,[esi]       ! get byte as zero extended dword
        or      ebx,ebx         !  check zero termination
        jz      sc_zstrpad01    ! found
        if      xltmod          ! if translation enabled
        movb    bl,xlttbl[ebx]  ! translate character
        movb    [esi],bl        ! replace
        endif
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
!
! Process buffer string to encoded
!
! Given a buffer padded string in esi with length ecx, encodes the string.
! Zeros are NOT obeyed to terminate the string.
! This is used to encode strings inbound from the os, in encoded mode.
!

!### Not checked

sc_strenc:
        or      ecx,ecx         ! check end of string
        jz      sc_zstrpad02    ! yes, exit
        movzxb  ebx,[esi]       ! get byte as zero extended dword
! This 'if' is to prevent xlttbl from being referenced in normal code
        if      xltmod          ! if encode mode
        movb    bl,xlttbl[ebx]  ! translate character
        endif
        movb    [esi],bl        ! replace
        inc     esi             ! next
        dec     ecx
        jmp     sc_strenc       ! loop
        ret                     ! exit

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Find length of environment string set
!
! First string record in ebx. Returns total length in ecx.
! Each string has a terminator added, and one extra is added for the whole
! table.
!
sc_cntenv:
        push    ebx             ! save first string record
        mov     ecx,1           ! clear count to table terminator
sc_cntenv01:
        or      ebx,ebx         ! check done
        jz      sc_cntenv02     ! yes, terminate
        add     ebx,4           ! offset to length
        addd    ecx,[ebx]       ! add length of string
        inc     ecx             ! and add one for terminator
        add     ebx,4           ! offset to next
        movd    ebx,[ebx]       ! link that
        jmp     sc_cntenv01     ! loop
sc_cntenv02:
        pop     ebx             ! restore first string record
        ret                     ! exit

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Move environment string set to buffer
!
! Expects the first string record in ebx. Moves the list string set
! to the buffer in edi. Each string gets a zero termination, and
! the entire table gets a zero termination.
!

!### Checked for non-encode case, encode case

sc_movenv:
        push    ebx
        push    edi
        push    esi
        push    ecx
sc_movenv01:
        or      ebx,ebx         ! check done
        jz      sc_movenv02     ! yes
        mov     esi,[ebx]       ! get address of string
        add     ebx,4           ! offset to length
        mov     ecx,[ebx]       ! get length
        or      ecx,ecx         ! check null string
        jz      sc_movenv011    ! yes, skip
sc_movenv010:
        movzxb  edx,[esi]       ! get source character
        if      xltmod          ! if translation enabled
        movb    dl,nrmtbl[edx]  ! translate character
        endif
        movb    [edi],dl        ! place
        inc     esi             ! next
        inc     edi
        dec     ecx             ! count
        jnz     sc_movenv010    ! loop
sc_movenv011:
        movb    [edi],0         ! terminate it
        inc     edi             ! next
        add     ebx,4           ! index next
        mov     ebx,[ebx]       ! link that
        jmp     sc_movenv01     ! loop
sc_movenv02:
        movb    [edi],0         ! terminate table
        pop     ecx             ! clean up and return
        pop     esi
        pop     edi
        pop     ebx
        ret

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
! Start of support routines                                                   !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Message "cracker"
!
! This routine takes two signed numbers, each in a different half of
! the 32 bit integer we are passed, and "cracks" them into two integers.
!
! procedure crkmsg(m: integer; var h, l: integer);
!
!      m -> eax
! addr h -> ebx
! addr l -> ecx
!
! Note: This can be done in HLL, and should be done, and removed from here.
!
sc_crkmsg:
        push    eax             ! save used registers
        push    edx
        mov     edx,eax         ! save copy
        and     eax,$ffff       ! mask message
        mov     [ecx],eax       ! place that
        mov     eax,edx         ! restore message
        ror     eax,16          ! place high half in low
        and     eax,$ffff       ! mask
        mov     [ebx],eax       ! place that
        pop     edx             ! restore used registers
        pop     eax
        ret                     ! return to caller

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Start thread
!
! Performs the startup of a thread, in terms of what windows specific 
! initialzation is needed for the subthread (the windows call to activate the
! thread is a syslib matter).
!
! Note that this routine bears a prefix specific to ip, since it is not a
! Windows call.
!
! No parameters
!
sc_ip_threadinit:
        cld                     ! clear direction flag
        fninit                  ! initalize FPU
        fldcw   [sc_fpuctl]     ! load FPU control word
        ret                     ! exit

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
! Data                                                                        !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

windows_exit_code: defvs   4    ! exit code holder
!
! Contents of FPU control register
!
! Sets for:
!
! Rounding  => Round to nearest or even
! Precision => 64 bits
! Masks     => all exceptions masked
!
! This can be set to $037f to turn all of the FPU error exceptions off,
! $0300 to set all FPU error exceptions on. Windows doesn't do much of use
! with exceptions, so usually they are turned off and left to the code
! to process.
!
! sc_fpuctl: defw   $0300
sc_fpuctl: defw   $037f
!
! Include character translation tables
!
        if      xltmod  ! if translation enabled
        include xlttbls ! include the translation tables
        endif

