!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
! I80386 Compiler Support Routines                                            !
!                                                                             !
! Contains a series of 80386 compiler support routines. These are routines    !
! that the encoder ships out to external routines instead of encoding         !
! in-line. This usually includes routines that are too complex to handle      !
! as in-lines.                                                                !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!
! Runtime error equates
!
renull:         equ     0               ! no error
rerngchk:       equ     1               ! range check
relenmat:       equ     2               ! array sizes don't match
recasvnf:       equ     3               ! case value not found
rezdiv:         equ     4               ! zero divide
reivop:         equ     5               ! invalid operands
renpdref:       equ     6               ! nil pointer dereference
rerelovf:       equ     7               ! real overflow
rerelunf:       equ     8               ! real underflow
rerelflt:       equ     9               ! real processing fault
!
! Startup
!
        jmp     maclib_end            ! skip over module

!
! Multiply 64 bit unsigned
!
! Mutliplies two 64 bit unsigned numbers to form a 64 bit result. Overflows
! cause an error.
!
! In parameters: Operand A - eax:ebx (low/high)
!                Operand B - ecx:edx (low/high)
!
! Out parameters: Result - eax:ebx (low/high)
!
! Preserves all registers but eax:ebx. This matches the IP Pascal calling
! convention.
!
maclib_multu64:
        pushf                           ! save registers
        push    ecx
        push    edx
        push    esi
        push    edi
        mov     esi,eax                 ! save al
        mov     edi,edx                 ! save bh
!
! Form partial products and stack
!
        mul     eax,ecx                 ! find al*bl
        push    eax                     ! save al*bl product
        push    edx
        mov     eax,esi                 ! find ah*bl
        mul     eax,ecx
        jc      maclib_overflow         ! process overflow
        push    eax                     ! save ah*bl product low 32
        mov     eax,edi                 ! find bh*al
        mul     eax,esi                 
        jc      maclib_overflow         ! skip on overflow
!
! Any result in the high order 32 bits is an overflow, so it is an error if one
! or both of ah or bh is not zero.
!
        or      ebx,ebx                 ! check ah = 0
        jz      maclib_multu64_01       ! skip
        or      edi,edi                 ! check bh = 0
        jnz     maclib_overflow         ! process overflow
maclib_multu64_01:
!
! Add up partial products, the bh*al is in eax
!
        pop     ebx                     ! get ah*bl low 32
        add     eax,ebx                 ! add bh*al to ah*bl
        jc      maclib_overflow         ! process overflow
        pop     ebx                     ! get al*bl full 64 bit product high
        pop     ecx                     ! "" low
        add     ebx,eax                 ! add hb*al+ah*bl to al*bl high
        mov     eax,ecx                 ! place low result
        pop     edi                     ! restore registers
        pop     esi
        pop     edx
        pop     ecx 
        popf    
        ret                             ! exit
!
! Multiply 64 bit signed
!
! Mutliplies two 64 bit signed numbers to form a 64 bit result. Overflows
! cause an error.
!
! In parameters: Operand A - eax:ebx (low/high)
!                Operand B - ecx:edx (low/high)
!
! Out parameters: Result - eax:ebx (low/high)
! Preserves all registers but eax:ebx. This matches the IP Pascal calling
! convention.
!
maclib_mults64:
        pushf                           ! save registers
        push    ecx
        push    edx
        push    esi
        mov     esi,ebx                 ! save sign of result
        xor     esi,edx
        or      ebx,ebx                 ! find abs(a)
        jns     maclib_mults64_01
        neg     ebx                     ! negate 64 bits
        neg     eax
        sbb     ebx,0
maclib_mults64_01:
        or      edx,edx                 ! find abs(b)
        jns     maclib_mults64_02
        neg     edx                     ! negate 64 bits
        neg     ecx
        sbb     edx,0
maclib_mults64_02:
        call    maclib_multu64          ! perform unsigned 64 bit multiply
        or      ebx,ebx                 ! check overflow on result
        js      maclib_overflow         ! yes, process
        or      esi,esi                 ! check result is signed
        jns     maclib_mults64_03       ! no, leave unsigned
        neg     ebx                     ! negate 64 bits
        neg     eax
        sbb     ebx,0
maclib_mults64_03:
        pop     esi                     ! restore registers
        pop     edx
        pop     ecx
        popf
        ret                             ! exit
!
! Divide 64 bit unsigned base routine
!
! Divides a 64 bit unsigned dividend by a 64 bit unsigned divisor to form a 64
! bit result quotient and 64 bit remainder.
!
! In parameters: Divisor  A - eax:ebx (low/high)
!                Dividend B - ecx:edx (low/high)
!
! Out parameters: Quotient  - eax:ebx (low/high)
!                 Remainder - ecx:edx (low/high)
!
! Preserves all registers but eax:ebx and ecx:edx. This does NOT match the IP
! Pascal calling convention.
!
maclib_divu64_i:
        pushf                           ! save registers
        push    esi
        push    edi
        push    ebp
        mov     ebp,32                  ! set bit count
        xor     esi,esi                 ! set remainder to zero low
        mov     edi,esi                 ! high
maclib_divu64_i_01:
        shl     eax,1                   ! shift 64 bit
        rcl     ebx,1
        rcl     esi,1
        rcl     edi,1
        cmp     edi,edx                 ! compare b and remainder
        ja      maclib_divu64_i_02      ! b goes into remainder
        jb      maclib_divu64_i_03      ! skip
        cmp     esi,ecx
        jb      maclib_divu64_i_03      ! skip
maclib_divu64_i_02:
        sub     esi,ecx                 ! find remainder - divisor
        sbb     edi,edx
        inc     eax                     ! set bit 0 of result
maclib_divu64_i_03:
        dec     ebp                     ! count off
        jne     maclib_divu64_i_01
        mov     ecx,esi                 ! move remainder to ecx:edx
        mov     edx,edi
        pop     ebp                     ! restore registers
        pop     edi
        pop     esi
        popf
        ret
!
! Divide 64 bit unsigned
!
! Divides a 64 bit unsigned dividend by a 64 bit unsigned divisor to form a 64
! bit result quotient.
!
! In parameters: Divisor  A - eax:ebx (low/high)
!                Dividend B - ecx:edx (low/high)
!
! Out parameters: Quotient  - eax:ebx (low/high)
!
! Preserves all registers but eax:ebx. This matches the IP Pascal calling
! convention.
!
maclib_divu64:
        push    ecx                     ! save registers
        push    edx
        call    maclib_divu64_i         ! perform basic division
        pop     edx                     ! restore registers
        pop     ecx
        ret                             ! exit
!
! Modulo 64 bit unsigned
!
! Divides a 64 bit unsigned dividend by a 64 bit unsigned divisor to form a 64
! bit remainder.
!
! In parameters: Divisor  A - eax:ebx (low/high)
!                Dividend B - ecx:edx (low/high)
!
! Out parameters: Remainder  - eax:ebx (low/high)
!
! Preserves all registers but eax:ebx. This matches the IP Pascal calling
! convention.
!
maclib_modu64:
        push    ecx                     ! save registers
        push    edx
        call    maclib_divu64_i         ! perform basic division
        mov     eax,ecx                 ! move remainder into result
        mov     ebx,edx
        pop     edx                     ! restore registers
        pop     ecx
        ret                             ! exit
!
! Divide 64 bit signed
!
! Divides a 64 bit unsigned dividend by a 64 bit unsigned divisor to form a 64
! bit result quotient.
!
! In parameters: Divisor  A - eax:ebx (low/high)
!                Dividend B - ecx:edx (low/high)
!
! Out parameters: Quotient  - eax:ebx (low/high)
!
! Preserves all registers but eax:ebx. This matches the IP Pascal calling
! convention.
!
maclib_divs64:
        pushf                           ! save registers
        push    ecx
        push    edx
        push    esi
        mov     esi,ebx                 ! save sign of result
        xor     esi,edx
        or      ebx,ebx                 ! find abs(a)
        jns     maclib_divs64_01
        neg     ebx                     ! negate 64 bits
        neg     eax
        sbb     ebx,0
maclib_divs64_01:
        or      edx,edx                 ! find abs(b)
        jns     maclib_divs64_02
        neg     edx                     ! negate 64 bits
        neg     ecx
        sbb     edx,0
maclib_divs64_02:
        call    maclib_divu64_i         ! perform unsigned 64 bit multiply
        or      ebx,ebx                 ! check overflow on result
        js      maclib_overflow         ! yes, process
        or      esi,esi                 ! check result is signed
        jns     maclib_divs64_03        ! no, leave unsigned
        neg     ebx                     ! negate 64 bits
        neg     eax
        sbb     ebx,0
maclib_divs64_03:
        pop     esi                     ! restore registers
        pop     edx
        pop     ecx
        popf
        ret                             ! exit
!
! Modulo 64 bit signed
!
! Divides a 64 bit unsigned dividend by a 64 bit unsigned divisor to form a 64
! bit remainder.
!
! In parameters: Divisor  A - eax:ebx (low/high)
!                Dividend B - ecx:edx (low/high)
!
! Out parameters: Remainder - eax:ebx (low/high)
!
! Preserves all registers but eax:ebx. This matches the IP Pascal calling
! convention.
!
maclib_mods64:
        pushf                           ! save registers
        push    ecx
        push    edx
        push    esi
        mov     esi,ebx                 ! save sign of result
        xor     esi,edx
        or      ebx,ebx                 ! find abs(a)
        jns     maclib_mods64_01
        neg     ebx                     ! negate 64 bits
        neg     eax
        sbb     ebx,0
maclib_mods64_01:
        or      edx,edx                 ! find abs(b)
        jns     maclib_mods64_02
        neg     edx                     ! negate 64 bits
        neg     ecx
        sbb     edx,0
maclib_mods64_02:
        call    maclib_divu64_i         ! perform unsigned 64 bit divide
        or      ebx,ebx                 ! check overflow on result
        js      maclib_overflow         ! yes, process
        or      esi,esi                 ! check result is signed
        jns     maclib_mods64_03        ! no, leave unsigned
        neg     ebx                     ! negate 64 bits
        neg     eax
        sbb     ebx,0
maclib_mods64_03:
        pop     esi                     ! restore registers
        pop     edx
        pop     ecx
        popf
        ret                             ! exit
!
! Flag overflow error
!
! Flag range check (overflow) error. Does not return
!
! In parameters: None
!
! Out parameters: None
!
maclib_overflow:
        mov     eax,rerngchk            ! set range check error
        call    ps_error                ! process error
        jmp     _                       ! should not return
!
! Process FPU exception
!
! Given the FPU status word, finds and processes the correct runtime error 
! according to priority. Does not return.
!
! In parameters: FPU status word - eax
!
! Out parameters: None
!
maclib_fpuerr:
        mov     ebx,eax                 ! save FPU status word
        mov     eax,rezdiv              ! check zero divide
        test    ebx,$0004
        jnz     maclib_fpuerr_01        ! yes, skip
        mov     eax,rerelovf            ! check overflow
        test    ebx,$0008
        jnz     maclib_fpuerr_01        ! yes, skip
        mov     eax,rerelovf            ! check underflow
        test    ebx,$0010
        jnz     maclib_fpuerr_01        ! yes, skip
        mov     eax,rerelflt            ! otherwise just set general fault
maclib_fpuerr_01:
        call    ps_error                ! process error
        jmp     _                       ! should not return
!
maclib_end:
