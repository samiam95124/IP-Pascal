!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
!                           GET CPU ID INFORMATION                            !
!                                                                             !
!                             2006/1 S. A. Moore                              !
!                                                                             !
! Recovers the cpu id information for a 32 bit processor (or a 64 bit         !
! processor in 32 bit mode). Recovers the stepping id, model, family and      !
! vendor id string.                                                           !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

        jmp     cpuid_end      ! exit module
!
! procedure cpuid(var eax, ebx, ecx, edx: integer);
!
! The function number in eax will be loaded into eax, the cpuid instruction
! is executed, and then the eax, ebx, ecx and edx registers are returned to
! the caller.
!
! If the cpu does not support the cpuid instruction, then all registers are
! returned as zero. The caller can detect if the cpuid instruction is not
! implemented by executing function 0 or "retrive cpu id string", and checking
! that zeros are returned in the cpu id string.
!
! The parameters are passed in registers as follows:
!
! eax -> Contains a pointer to the eax parameter
! ebx -> Contains a pointer to the ebx parameter
! ecx -> Contains a pointer to the ecx parameter
! edx -> Contains a pointer to the edx parameter
!
! All input registers are preserved as per the I80386 calling convention.
! 
cpuid:
        pushfd                  ! save registers used
        push    eax
        push    ebx
        push    ecx
        push    edx
        push    edi
        push    esi
        mov     edi,[eax]       ! save function
        movd    [eax],0         ! clear all fields
        movd    [ebx],0
        movd    [ecx],0
        movd    [edx],0
!
! Check CPUID is implemented
!
        push    eax             ! save registers
        push    ebx
        pushfd                  ! get eflags
        pop     eax
        mov     ebx,eax         ! save that
        xor     eax,$200000     ! toggle bit 21
        push    eax             ! place that in flags
        popfd
        pushfd                  ! get flags back
        pop     eax             
        cmp     eax,ebx         ! check bit 21 change suceeded
        pop     ebx             ! restore registers
        pop     eax
        jz      nocpuid         ! cpuid not implemented, exit with zeros all
!
! Execute cpuid instruction
!
        push    eax             ! save all our pointers
        push    ebx
        push    ecx
        push    edx
        mov     eax,edi         ! get function
        cpuid
        pop     edi             ! get edx location
        mov     [edi],edx       ! place
        pop     edi             ! get ecx location
        mov     [edi],ecx       ! place
        pop     edi             ! get ebx location
        mov     [edi],ebx       ! place
        pop     edi             ! get eax location
        mov     [edi],eax       ! place
nocpuid:
        pop     esi             ! restore registers
        pop     edi
        pop     edx
        pop     ecx
        pop     ebx
        pop     eax
        popfd
        ret                     ! done, exit
!
cpuid_end:
