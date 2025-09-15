!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                              !
!                           PRIME IN I80386 ASSEMBLY                           !
!                                                                              !
!                         Copyright (C) 2004 S. A. Moore                       !
!                                                                              !
! The prime number program is a classical benchmark. This coding in assembly   !
! serves to indicate what the ultimate speed of the benchmark can be, and      !
! suggest or even test out various optimizations for the compiler back end.    !
!                                                                              !
! This version tests if clearing without the rep instruction is different.     !
!                                                                              !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!
! ecx -> i
! ebx -> k
! edx -> prime
! esi -> count
! edi -> iter
!
count:  equ     100000          ! number of iterations to perform
size:   equ     8190            ! size of sieve
!
prime_start:
        movb    [outfil],0      ! clear output file
!
! Open output file
!
        mov     ecx,outfil      ! index file
        mov     eax,outstr      ! index filename
        mov     ebx,outlen      ! set length
        call    tr_ps_assign    ! set filename
        mov     eax,ecx         ! index file in eax
        mov     ebx,1           ! set file buffer length
        call    tr_ps_rwttxt    ! rewrite file
!
! Output signon
!
        mov     ebx,1           ! set field
        mov     ecx,count       ! print size
        call    tr_ps_wrtint
        mov     ecx,eax         ! index file in ecx
        mov     eax,sgnstr      ! index signon message
        mov     ebx,sgnlen      ! set length
        call    tr_ps_wrtstr    ! output
        mov     eax,ecx         ! index file in eax
        call    tr_ps_wrteol    ! terminate line
!
! Prime iteration loop
!
	mov	edi,count  	! set loop count
for1:
	xor	esi,esi	   	! clear prime count
!
! Clear flag array
!
        mov     ecx,size+1      ! set length in words
        xor     eax,eax         ! set true
        dec     eax
        push    edi             ! save iter
        mov     edi,flags       ! index flag array
clear:
        mov     [edi],al
        inc     edi
        dec     ecx
        jnz     clear
        pop     edi             ! restore iter
!
! find primes
!
        mov     ecx,0           ! set i := 0
for2:
        movb    al,flags[ecx]   ! check flags[i]
        or      al,al
        jz      for2end         ! not true, skip
        mov     edx,ecx         ! prime := i+i+3
        add     edx,ecx
        add     edx,3
        mov     ebx,ecx         ! k := i+prime
        add     ebx,edx
while:
        cmp     ebx,size        ! check k <= size
        ja      whlend          ! no, skip
        movb    flags[ebx],0    ! flags[k] := false
        add     ebx,edx         ! k := k+prime
        jmp     while           ! loop
whlend:
        inc     esi             ! count := count+1
for2end:
        inc     ecx             ! i := i+1
        cmp     ecx,size        ! check done
        jl      for2            ! next
!
        dec     edi             ! iter := iter-1
        jnz     for1            ! loop not zero     
!
! Output epilog
!
        mov     eax,outfil      ! index file
        mov     ebx,1           ! set field
        mov     ecx,esi         ! print primes
        call    tr_ps_wrtint
        mov     ecx,eax         ! index file in ecx
        mov     eax,prmstr      ! index primes message
        mov     ebx,prmlen      ! set length
        call    tr_ps_wrtstr    ! output
        mov     eax,ecx         ! index file in eax
        call    tr_ps_wrteol    ! terminate line
        call    prime_end       ! execute next module in series
        ret
!
! Data
!
outstr: defb    '_output'       ! output filename
outlen: equ     8               ! length
sgnstr: defb    ' iterations'   ! signon string
sgnlen: equ     11              ! length
prmstr: defb    ' primes'       ! prime count string
prmlen: equ     7               ! length
!
! Variables
!
flags:  defvs   size+1          ! space for flag array
outfil: defvs   1               ! output file
!
! End of file
!
prime_end:
