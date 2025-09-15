!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                              !
!                       VO PRIMARY BOOTSTRAP FOR FLOPPY DISK                   !
!                                                                              !
!                             2007/08/29 S. A. Moore                           !
!                                                                              !
! This is a "one-step" image for booting off a floppy disk. "one-step" means   !
! that it includes the preamble needed to be an image for a bootable floppy    !
! disk in IBM-PC format. It only needs to be converted to a direct binary      !
! image and placed on a floppy or loaded into a simulator such as Bochs.       !
!                                                                              !
! The VO blocks that are to be loaded into the "prime clutch", which is a      !
! series of VO blocks sufficient to bring the system up. These blocks all      !
! appear after the bootstrap resident portion (the part of this bootstrap that !
! gets copied into main memory), each with a signature block, and followed by  !
! a cap cell.                                                                  !
!                                                                              !
! The bootstrap loads as a normal 16 bit image, then transitions to 32 bit     !
! protected mode, then starts up the primary block in the clutch.              !
! This is about all that will fit into a 512 byte boot block, and if a 64 bit  !
! boot is desired, the most likely expedient is to place that mode change at   !
! the front of the loaded program.                                             !
!                                                                              !
! This bootstrap boots from a VO progressive image format disk. This format    !
! allows any size or scatter of file to be directly loaded off the disk. This  !
! file occupies the first position in the prime block of the root directory,   !
! as allowed by the VO format. Although the boot file can be any size, this    !
! program will only load into the 640kb parition between $09000 and $a0000.    !
! This is because, since the BIOS can only load sectors into this space, we    !
! would have to copy all sectors up to the high addresses. Instead, we leave   !
! it up to the target program to establish a 3rd level loader if that is       !
! required. This leaves enough space to establish a full driver that does not  !
! have memory limits.                                                          !
!                                                                              !
! Typically all of the 640kb space cannot be used, because some variable space !
! must be left after the program.                                              !
!                                                                              !
! The memory layout during bootstrap is as follows:                            !
!                                                                              !
! $00000000-$000005ff Reserved for BIOS                                        !
! $00000600-$000007ff Relocated boot sector                                    !
! $00000800-$00000fff Room for 4 block buffers of 512 bytes, or 4 levels,      !
!                     minus stack                                              !
! $00001000           Bootstrap stack set                                      !
! $00001000-$0009ffff Load area for the boot program                           !
! $000a0000           Stack set for program                                    !
!                                                                              !
! The boot block is read by BIOS to $00007c00, but we relocate it down to      !
! $00000600, just above the BIOS/Vector data area. The reason for the          !
! $00007c00 is lost in history, and systems from DOS onwards use the $600      !
! address scheme.                                                              !
!                                                                              !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!
! Equates
!
programloc: equ $1000           ! location to load program
bufferloc:  equ $800            ! location to use for block buffers
blocksize:  equ 512             ! size of volume block
blocksego:  equ blocksize/16    ! amount to offset segment for block
indexblock: equ 256             ! number of indexes per block
smallstack: equ programloc      ! 16 bit mode stack, under the program load
                                ! area, and over the index buffers
bigstack:   equ $a0000          ! 32 bit mode stack, at the top of 640kb
bootloc:    equ $7c00           ! location of initial boot block load
bootrel:    equ $600            ! location of boot block after move

prtpass:    equ 0               ! print/don't print load pass message

!
! Enable for 16 bit 8086/88 mode for primary boot phase
!
        m86                     ! set machine to 8086/88
!
! lay out the boot record for a floppy
!
start:
        jmp     primeboot
!
! System name
!
        defb    'VO      '
!
! Bios parameter block
!
! Much of this is unused, since we don't have a FAT format on this disk. 
! However, various systems such as DOS/Windows and utilities get upset if they
! see a disc that does not look like the FAT formatted disc they expect.
!
        defw    $200            ! bytes per sector
        defb    $02             ! number of sectors per cluster     
        defw    $0001           ! number of reserved sectors
        defb    $02             ! number of FATs
        defw    $0070           ! maximum number of root directory entries
        defw    $02d0           ! total number of sectors
        defb    $fd             ! media descriptor
        defw    $0002           ! number of sectors per FAT
        defw    $0009           ! number of sectors per track
        defw    $0002           ! number of heads
        defdw   $00000000       ! number of hidden sectors
        defdw   $00000000       ! extended sectors count
        defb    $00             ! physical drive number
        defb    $00             ! reserved
        defb    $29             ! signature byte for extended boot record
        defdw   $203d10cc       ! volume serial number
        defb    'VO         '   ! volume label
        defps   8               ! reserved
!
! Bootstrap code at $7c00
!
primeboot:
        cli                     ! clear interrupts
        mov     ax,$0000        ! set up segmentation to match flat addressing
        mov     ds,ax
        mov     es,ax
        mov     fs,ax
        mov     gs,ax
        mov     ss,ax
        mov     ax,smallstack   ! set stack to $10000
        mov     sp,ax
!
! Move boot block into low area
!
        mov     si,bootloc      ! index source
        mov     di,bootrel      ! index destination
        mov     cx,512
        rep                     ! repeat for cx
        movsb                   ! move into place
        jmpf    $0000,reloc     ! go to relocated address
reloc:
!
! Load bootstrap off disk
!
        xor     dx,dx           ! clear high order index
        mov     ax,1            ! index block 1, the root directory prime
        mov     bx,bufferloc    ! index buffer location
        call    readblock       ! read prime root directory block in
        jc      bootfail        ! bad read, go halt
        mov     ah,[bx]         ! get the bootstrap index (big endian)
        inc     bx
        mov     al,[bx]
        inc     bx
        or      ax,ax           ! check 0 block
        jz      bootfail        ! there is no bootstrap on this disk
        mov     cl,[bx]         ! get file indexing level
        inc     bx              ! offset past that
        xor     dx,dx           ! clear upper bits
        mov     [progseg],dx    ! clear program address segment
        mov     [buffseg],dx    ! clear buffer address segment
        mov     dx,programloc   ! set up program location
        mov     [progadr],dx  ! place as offset
        mov     dx,bufferloc    ! set up first buffer location
        mov     [buffadr],dx  ! place as offset
        xor     dx,dx           ! clear upper bits
        call    loadblock       ! load boot program
        jnc     bootpass        ! go change protected mode
!
! Load fail, output message
!
bootfail:
        mov     si,loaderrmsg   ! index load error message
        call    prtmsg          ! print
!
! Soft halt here after load error
!
        jmp     _               ! halt

!
! Load succeeds
!
bootpass:
        if      prtpass
        mov     si,loadsucmsg   ! index load pass message
        call    prtmsg
        endif
!
! Goto 32 bit protected mode
!
        m386                    ! now we need 386 instructions
        small                   ! but keep in 16 bit

        lgdtd   [gdtr]          ! load gdt pointer
        mov     eax,cr0         ! turn on protected mode bit
        or      al,1
        mov     cr0,eax
        jmpf    codsel,go32bit
!
! Now go to 32 bit code generation mode
!
        m386

go32bit:
        mov     ax,datsel       ! Update the segment registers
        mov     ds,ax           ! To complete the transfer to
        mov     es,ax           ! 32-bit mode
        mov     ss,ax
        mov     fs,ax
        mov     gs,ax
!
! Reset stack to top of 640kb
!
        mov     esp,bigstack
!
! Execute the client program
!
goclient:
        call     programloc      ! go to program startup
!
! If the program returns, we just halt
!
        jmp     _

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! 16 bit routines
!
        m86

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                              !
! loadblock                                                                    !
!                                                                              !
! Load next block of program. Either reads the next index or program block,    !
! depending on the level. If an index block is read, then it is read to a      !
! buffer, then each of the indexs is called to read its contents recursively.  !
! If a program block is read, then it is read directly to the destination.     !
! Accepts the current indexing level and the logial address of the program or  !
! index block on the boot volume. The address for program blocks is taken from !
! progsad, and for each block read it is offset by a block's worth. The buffer !
! address for indexes is taken from buffsad, and it acts like an upward        !
! growing stack. Each time we advance a level (towards 0), it is offset a      !
! block's worth. Each time we back up a level (away from 0), it is returned    !
! to the old address.                                                          !
!                                                                              !
! In parameters:                                                               !
!                                                                              !
!    dx:ax -> Index of block to load                                           !
!    cl    -> Current indexing level                                           !
!                                                                              !
! Out parameters:                                                              !
!                                                                              !
!    al    -> Error code from BIOS (0=No error, >0=error with carry set)       !
!                                                                              !
! Distroys:                                                                    !
!                                                                              !
!    ah                                                                        !
!                                                                              !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

loadblock:
        push    bx              ! save registers used
        push    cx
        push    dx
        push    si
        mov     bx,ax           ! check block is 0
        or      bx,dx
        jz      loadblock04     ! yes, do nothing
        or      cl,cl           ! check level 0
        jnz     loadblock01     ! no, skip
!
! Read a program block
!
        les     bx,[progadr]    ! get current program address segmented
        call    readblock       ! read that into memory
        jc      loadblock04     ! error, exit
        mov     ax,es           ! offset segment to next block
        add     ax,blocksego
        mov     [progseg],ax    ! update program address segment only
        jmp     loadblock04     ! exit
!
! Read an index block
!
! We count on having 256 indexes per block, and that the size of an
! index is a 16 bit word.
!
loadblock01:
        les     bx,[buffadr]    ! get current buffer address
        call    readblock       ! get an index block
        jc      loadblock04     ! error, exit
        xor     ch,ch           ! clear index counter
        mov     si,bx           ! copy pointer to current index
        xor     dx,dx           ! clear high order index
        add     bx,blocksize    ! offset buffer address to next block
        mov     [buffadr],bx    ! update offset only
        dec     cl              ! find next level
loadblock02:
        mov     ah,[si]         ! get an index (big endian)
        inc     si
        mov     al,[si]
        inc     si
        call    loadblock       ! load that block
        jc      loadblock04     ! error, exit
        dec     ch              ! count 256 indexes
        jnz     loadblock02     ! loop for all indexes
loadblock03:
        sub     bx,blocksize    ! restore old buffer address
        mov     [buffadr],bx
!
! Done, clean up and exit
!
loadblock04:
        pop     si              ! restore registers
        pop     dx
        pop     cx
        pop     bx
        ret                     ! exit

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                              !
! readblock                                                                    !
!                                                                              !
! Read a block from the floppy drive. Expects the LBA aadress to read, and     !
! the address to read the sector to. Returns carry set if an error occurs.     !
!                                                                              !
! In parameters:                                                               !
!                                                                              !
!    dx:ax -> 32 bit LBA address, 0-n                                          !
!    es    -> segment for destination address                                  !
!    bx    -> offset for destination address                                   !
!                                                                              !
! Out parameters:                                                              !
!                                                                              !
!    al    -> Error code from BIOS (0=No error, >0=error with carry set)       !
!                                                                              !
! Distroys:                                                                    !
!                                                                              !
!    ah                                                                        !
!                                                                              !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

readblock:
        push    cx              ! save registers used
        push    dx
        push    bx              ! save destination offset
        mov     bx,18           ! divide by 18 sectors per track
        div     bx
        inc     dx              ! adjust sector number for 1-n
        mov     cl,dl           ! cl=sector number
        xor     dx,dx           ! clear high order
        mov     bx,2            ! divide by sides
        div     bx
        mov     dh,dl           ! place head
        mov     ch,al           ! set cylinder
        xor     dl,dl           ! set drive A:
        pop     bx              ! restore destination offset
        mov     al,1            ! set read 1 sector
        mov     ah,2            ! func=2=Read diskette sectors
        int     $13             ! go BIOS
        mov     al,ah           ! move error code to al
        pop     dx              ! clean up and return
        pop     cx
        ret

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                              !
! prtmsg                                                                       !
!                                                                              !
! Print a message on the console. Prints a zero terminated string via BIOS.    !
!                                                                              !
! In parameters:                                                               !
!                                                                              !
!    si -> Address of message                                                  !
!                                                                              !
! Out parameters:                                                              !
!                                                                              !
!    None                                                                      !
!                                                                              !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

prtmsg: 
        push    ax              ! save registers
        push    bx
        push    si
prtmsg01:
        lodsb                   ! get character
        or      al,al           ! check end of string
        jzm     prtmsg02        ! done, exit
        mov     ah,$0e          ! set BIOS teletype call
        mov     bh,$00          ! set display page 0
        mov     bl,$07          ! set text attribute
        int     $10             ! execute BIOS call
        jmpm    prtmsg01        ! loop
prtmsg02:
        pop     si              ! clean up and return
        pop     bx
        pop     ax
        ret

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Data area
!

!
! Messages
!
loaderrmsg:
        defb    '*** Boot program load fails ***', $0d, $0a, 0
        if      prtpass
loadsucmsg:
        defb    'Load succeeds', $0d, $0a, 0
        endif
!
! global descriptor table
!
gdtr:
        defw    gdt_end-gdt-1   ! GDT limit
        defdw   gdt             ! GDT base
!
! Global descriptor entries
!
gdt:
        defps   8               ! allocate NULL descriptor
!
! Code selector
!
codsel: equ     _-gdt

        defw    $FFFF           ! limit 15:0
        defw    0               ! base 15:0
        defb    0               ! base 23:16
        defb    $9A             ! type = present, ring 0, code, non-conforming, 
                                ! readable
        defb    $CF             ! page granular, 32-bit
        defb    0               ! base 31:24

datsel: equ     _-gdt
        defw    $FFFF           ! limit 15:0
        defw    0               ! base 15:0
        defb    0               ! base 23:16
        defb    $92             ! type = present, ring 0, data, expand-up, writable
        defb    $CF             ! page granular, 32-bit
        defb    0               ! base 31:24
gdt_end:

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! Variables
!
progadr: defw   0               ! address to load program, segmented
progseg: defw   0
buffadr: defw   0               ! buffer address, segmented
buffseg: defw   0
