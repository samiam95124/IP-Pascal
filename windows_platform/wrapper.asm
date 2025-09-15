!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
!                     WINDOWS 32 BIT SYSTEM CALL WRAPPERS                     !
!                                                                             !
!                             2004/03 S. A. Moore                             !
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

sc_WM_NULL:                     equ $0000
sc_WM_CREATE:                   equ $0001
sc_WM_DESTROY:                  equ $0002
sc_WM_MOVE:                     equ $0003
sc_WM_SIZE:                     equ $0005
sc_WM_ACTIVATE:                 equ $0006
sc_WM_SETFOCUS:                 equ $0007
sc_WM_KILLFOCUS:                equ $0008
sc_WM_ENABLE:                   equ $000A
sc_WM_SETREDRAW:                equ $000B
sc_WM_SETTEXT:                  equ $000C
sc_WM_GETTEXT:                  equ $000D
sc_WM_GETTEXTLENGTH:            equ $000E
sc_WM_PAINT:                    equ $000F
sc_WM_CLOSE:                    equ $0010
sc_WM_QUERYENDSESSION:          equ $0011
sc_WM_QUIT:                     equ $0012
sc_WM_QUERYOPEN:                equ $0013
sc_WM_ERASEBKGND:               equ $0014
sc_WM_SYSCOLORCHANGE:           equ $0015
sc_WM_ENDSESSION:               equ $0016
sc_WM_SHOWWINDOW:               equ $0018
sc_WM_WININICHANGE:             equ $001A
sc_WM_DEVMODECHANGE:            equ $001B
sc_WM_ACTIVATEAPP:              equ $001C
sc_WM_FONTCHANGE:               equ $001D
sc_WM_TIMECHANGE:               equ $001E
sc_WM_CANCELMODE:               equ $001F
sc_WM_SETCURSOR:                equ $0020
sc_WM_MOUSEACTIVATE:            equ $0021
sc_WM_CHILDACTIVATE:            equ $0022
sc_WM_QUEUESYNC:                equ $0023
sc_WM_GETMINMAXINFO:            equ $0024
sc_WM_PAINTICON:                equ $0026
sc_WM_ICONERASEBKGND:           equ $0027
sc_WM_NEXTDLGCTL:               equ $0028
sc_WM_SPOOLERSTATUS:            equ $002A
sc_WM_DRAWITEM:                 equ $002B
sc_WM_MEASUREITEM:              equ $002C
sc_WM_DELETEITEM:               equ $002D
sc_WM_VKEYTOITEM:               equ $002E
sc_WM_CHARTOITEM:               equ $002F
sc_WM_SETFONT:                  equ $0030
sc_WM_GETFONT:                  equ $0031
sc_WM_SETHOTKEY:                equ $0032
sc_WM_GETHOTKEY:                equ $0033
sc_WM_QUERYDRAGICON:            equ $0037
sc_WM_COMPAREITEM:              equ $0039
sc_WM_COMPACTING:               equ $0041
sc_WM_OTHERWINDOWCREATED:       equ $0042  ! no longer suported
sc_WM_OTHERWINDOWDESTROYED:     equ $0043  ! no longer suported
sc_WM_COMMNOTIFY:               equ $0044  ! no longer suported
sc_WM_HOTKEYEVENT:              equ $0045
sc_WM_WINDOWPOSCHANGING:        equ $0046
sc_WM_WINDOWPOSCHANGED:         equ $0047
sc_WM_POWER:                    equ $0048
sc_WM_COPYDATA:                 equ $004A
sc_WM_CANCELJOURNAL:            equ $004B
sc_WM_NCCREATE:                 equ $0081
sc_WM_NCDESTROY:                equ $0082
sc_WM_NCCALCSIZE:               equ $0083
sc_WM_NCHITTEST:                equ $0084
sc_WM_NCPAINT:                  equ $0085
sc_WM_NCACTIVATE:               equ $0086
sc_WM_GETDLGCODE:               equ $0087
sc_WM_NCMOUSEMOVE:              equ $00A0
sc_WM_NCLBUTTONDOWN:            equ $00A1
sc_WM_NCLBUTTONUP:              equ $00A2
sc_WM_NCLBUTTONDBLCLK:          equ $00A3
sc_WM_NCRBUTTONDOWN:            equ $00A4
sc_WM_NCRBUTTONUP:              equ $00A5
sc_WM_NCRBUTTONDBLCLK:          equ $00A6
sc_WM_NCMBUTTONDOWN:            equ $00A7
sc_WM_NCMBUTTONUP:              equ $00A8
sc_WM_NCMBUTTONDBLCLK:          equ $00A9
sc_WM_KEYFIRST:                 equ $0100
sc_WM_KEYDOWN:                  equ $0100
sc_WM_KEYUP:                    equ $0101
sc_WM_CHAR:                     equ $0102
sc_WM_DEADCHAR:                 equ $0103
sc_WM_SYSKEYDOWN:               equ $0104
sc_WM_SYSKEYUP:                 equ $0105
sc_WM_SYSCHAR:                  equ $0106
sc_WM_SYSDEADCHAR:              equ $0107
sc_WM_KEYLAST:                  equ $0108
sc_WM_INITDIALOG:               equ $0110
sc_WM_COMMAND:                  equ $0111
sc_WM_SYSCOMMAND:               equ $0112
sc_WM_TIMER:                    equ $0113
sc_WM_HSCROLL:                  equ $0114
sc_WM_VSCROLL:                  equ $0115
sc_WM_INITMENU:                 equ $0116
sc_WM_INITMENUPOPUP:            equ $0117
sc_WM_MENUSELECT:               equ $011F
sc_WM_MENUCHAR:                 equ $0120
sc_WM_ENTERIDLE:                equ $0121
sc_WM_CTLCOLORMSGBOX:           equ $0132
sc_WM_CTLCOLOREDIT:             equ $0133
sc_WM_CTLCOLORLISTBOX:          equ $0134
sc_WM_CTLCOLORBTN:              equ $0135
sc_WM_CTLCOLORDLG:              equ $0136
sc_WM_CTLCOLORSCROLLBAR:        equ $0137
sc_WM_CTLCOLORSTATIC:           equ $0138
sc_WM_MOUSEFIRST:               equ $0200
sc_WM_MOUSEMOVE:                equ $0200
sc_WM_LBUTTONDOWN:              equ $0201
sc_WM_LBUTTONUP:                equ $0202
sc_WM_LBUTTONDBLCLK:            equ $0203
sc_WM_RBUTTONDOWN:              equ $0204
sc_WM_RBUTTONUP:                equ $0205
sc_WM_RBUTTONDBLCLK:            equ $0206
sc_WM_MBUTTONDOWN:              equ $0207
sc_WM_MBUTTONUP:                equ $0208
sc_WM_MBUTTONDBLCLK:            equ $0209
sc_WM_MOUSELAST:                equ $0209
sc_WM_PARENTNOTIFY:             equ $0210
sc_WM_ENTERMENULOOP:            equ $0211
sc_WM_EXITMENULOOP:             equ $0212
sc_WM_MDICREATE:                equ $0220
sc_WM_MDIDESTROY:               equ $0221
sc_WM_MDIACTIVATE:              equ $0222
sc_WM_MDIRESTORE:               equ $0223
sc_WM_MDINEXT:                  equ $0224
sc_WM_MDIMAXIMIZE:              equ $0225
sc_WM_MDITILE:                  equ $0226
sc_WM_MDICASCADE:               equ $0227
sc_WM_MDIICONARRANGE:           equ $0228
sc_WM_MDIGETACTIVE:             equ $0229
sc_WM_MDISETMENU:               equ $0230
sc_WM_DROPFILES:                equ $0233
sc_WM_MDIREFRESHMENU:           equ $0234
sc_WM_CUT:                      equ $0300
sc_WM_COPY:                     equ $0301
sc_WM_PASTE:                    equ $0302
sc_WM_CLEAR:                    equ $0303
sc_WM_UNDO:                     equ $0304
sc_WM_RENDERFORMAT:             equ $0305
sc_WM_RENDERALLFORMATS:         equ $0306
sc_WM_DESTROYCLIPBOARD:         equ $0307
sc_WM_DRAWCLIPBOARD:            equ $0308
sc_WM_PAINTCLIPBOARD:           equ $0309
sc_WM_VSCROLLCLIPBOARD:         equ $030A
sc_WM_SIZECLIPBOARD:            equ $030B
sc_WM_ASKCBFORMATNAME:          equ $030C
sc_WM_CHANGECBCHAIN:            equ $030D
sc_WM_HSCROLLCLIPBOARD:         equ $030E
sc_WM_QUERYNEWPALETTE:          equ $030F
sc_WM_PALETTEISCHANGING:        equ $0310
sc_WM_PALETTECHANGED:           equ $0311
sc_WM_HOTKEY:                   equ $0312
sc_WM_PENWINFIRST:              equ $0380
sc_WM_PENWINLAST:               equ $038F
!
! NOTE: All Message Numbers below 0x0400 are RESERVED. 
!
!  Private Window Messages Start Here:
!
sc_WM_USER:                     equ $0400

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
true:   equ     -1
false:  equ     0

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
        call    sc_strzer       ! place menu string
        mov     sc_wndclass_menuname[ebx],edi ! place string address
        mov     edi,offset[eax] ! get base of class record
        mov     esi,sc_wndclass_classname_p[edi] ! get class string address
        mov     ecx,sc_wndclass_classname_p+4[edi] ! get length
        call    sc_strzer       ! place class string
        mov     sc_wndclass_classname[ebx],edi ! place string address
        mov     offset[edx],ebx ! replace old with new class record

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

   elseif 'param' eq 'wclsptr' ! its a windows class pointer

      wccvt offset ! convert to windows class

   elseif 'param' eq 'evl' ! its an environment stringset

      mov     ebx,offset[eax] ! index 1st string entry
      or      ebx,ebx         ! check none
      jz      icvtpar____     ! skip if so
      call    sc_cntenv       ! count environment strings space
      and     ecx,$fffffffc   ! even to dword for stack align
      add     ecx,4
      sub     esp,ecx         ! allocate space for that
      mov     edi,esp         ! index buffer
      call    sc_movenv       ! move the environment there
      mov     offset[eax],esp ! replace parameter pointer
      icvtpar____:            ! here to skip

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

        if      'param' eq 'strlz' ! is it return string process

        ! convert length string zero termined in buffer to padded

        mov     esi,offset[edx] ! get window name string address
        mov     ecx,offset+4[edx] ! get string length
        call    sc_zstrpad      ! place that on stack

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
           ('param' eq 'strlz') or ('param' eq 'pstrl')

      ! if it is a length string
      pushd  offset+4[eax] ! place length
      pushd  offset[eax]   ! place address

   elseif  'param' eq 'lstr' ! if it is a length string prefix

      pushd offset[eax]   ! place address
      pushd offset+4[eax] ! place length

   elseif  ('param' eq 'byte') or ('param' eq 'bool') ! if it is an unsigned byte

      movzxb ebx,offset[eax] ! get and extend byte
      push ebx ! save

   elseif  'param' eq 'sbyte' ! if it is a signed byte

      movsxb ebx,offset[eax] ! get and extend byte
      push ebx ! save

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
      ('par' eq 'lstr') or ('par' eq 'strlz') or ('par' eq 'pstr') or \
      ('par' eq 'pstrl')

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
! Macro: find if parameter is byte, and if fits in register. Allocate if 
! so. Expects the lbyte variable to exist to keep track of the lower/upper
! byte register placement.
!
plcbyt: macro alc, addr, par

   if ('par' eq 'byte') or ('par' eq 'sbyte') or ('par' eq 'bool')

      ! Its a byte (8 bit) parameter
      if regnum lt reg_edi

         ! Registers are not full
         if regnum ge reg_esi ! register is esi or edi

            ! Allocate whole register for this, since esi and edi don't
            ! have byte modes.

            addr:   setequ stkoff ! allocate on register offset
            stkoff: setequ stkoff+4 ! next allocation
            regnum: setequ regnum+1 ! next register
            alc: setequ true ! set allocated

         elseif lbyte ! process low byte placement

            addr:   setequ stkoff ! allocate on register offset
            lbyte:  setequ not lbyte ! flip byte packing status
            alc: setequ true ! set allocated
            
         else ! process high byte placement
   
            addr:   setequ stkoff+1 ! allocate on register offset
            stkoff: setequ stkoff+4 ! next allocation
            regnum: setequ regnum+1 ! next register
            lbyte:  setequ not lbyte ! flip byte packing status
            alc: setequ true ! set allocated
           
         endif

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
      ('par' eq 'lstr')

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
! Macro: find if parameter is byte, and if fits in register. Allocate if 
! so. Expects the lbyte variable to exist to keep track of the lower/upper
! byte register placement.
!
ovfbyt: macro alc, addr, par

   if ('par' eq 'byte') or ('par' eq 'sbyte') or ('par' eq 'bool')

      ! Its a byte (8 bit) parameter
      if not alc

         ! Not in register
         if regnum ge reg_esi ! register is esi or edi

            ! Allocate whole register for this, since esi and edi don't
            ! have byte modes.

            addr:   setequ stkoff ! allocate on register offset
            stkoff: setequ stkoff+4 ! next allocation
            ovfsiz: setequ ovfsiz+4 ! add to overflow space
            alc: setequ true ! set allocated

         elseif lbyte ! process low byte placement

            addr:   setequ stkoff ! allocate on register offset
            lbyte:  setequ not lbyte ! flip byte packing status
            alc: setequ true ! set allocated
            
         else ! process high byte placement
   
            addr:   setequ stkoff+1 ! allocate on register offset
            stkoff: setequ stkoff+4 ! next allocation
            ovfsiz: setequ ovfsiz+4 ! add to overflow space
            lbyte:  setequ not lbyte ! flip byte packing status
            alc: setequ true ! set allocated

         endif

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
!    byte    - Integer operands, 8 bit, unsigned.
!    sbyte   - Integer operands, 8 bit, signed.
!    ptr     - Pointer to object.
!    ptrl    - Fat pointer with length following.
!    str     - String, this is converted to zero terminated.
!    strl    - String, unterminated with length following (Pascal style).
!    lstr    - String, unterminated with length preceeding.
!    strlz   - String with length following, converted from zero terminated on
!              return to padded.
!    pstr    - String, converted to zero terminated with right padding removed.
!    pstrl   - String, converted to zero terminated with right padding removed
!              and length following. If string equals length, zero is dropped.
!              Uses the original allocation, because this is var passed.
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
ptocf: macro name, function, pret, p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, \
                                  p11, p12, p13, p14

! print 'Function: name'
   sc_name:
   !
   ! Register allocation pass
   !
   ! Each of the tagged, standard, and byte parameters are placed in registers.
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
   ! Byte
   !
   lbyte: setequ  true ! set on low byte placement        
   plcbyt al1, a1, p1 ! place byte parameters as available
   plcbyt al2, a2, p2
   plcbyt al3, a3, p3
   plcbyt al4, a4, p4
   plcbyt al5, a5, p5
   plcbyt al6, a6, p6
   plcbyt al7, a7, p7
   plcbyt al8, a8, p8
   plcbyt al9, a9, p9
   plcbyt al10, a10, p10
   plcbyt al11, a11, p11
   plcbyt al12, a12, p12
   plcbyt al13, a13, p13
   plcbyt al14, a14, p14
   if not lbyte ! finish remainder

      stkoff: setequ stkoff+4 ! next allocation
      regnum: setequ regnum+1 ! next register

   endif
   !
   ! Overflow allocation pass
   !
   ! Each of the tagged, standard and byte parameters that were not placed in
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
   ! Byte
   !
   lbyte: setequ true ! set on low byte placement        
   ovfbyt al1, a1, p1 ! place byte parameters as available
   ovfbyt al2, a2, p2
   ovfbyt al3, a3, p3
   ovfbyt al4, a4, p4
   ovfbyt al5, a5, p5
   ovfbyt al6, a6, p6
   ovfbyt al7, a7, p7
   ovfbyt al8, a8, p8
   ovfbyt al9, a9, p9
   ovfbyt al10, a10, p10
   ovfbyt al11, a11, p11
   ovfbyt al12, a12, p12
   ovfbyt al13, a13, p13
   ovfbyt al14, a14, p14
   if not lbyte

      stkoff: setequ stkoff+4 ! next allocation
      ovfsiz: setequ ovfsiz+4 ! add to overflow space

   endif
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

wrapper_start:
        cld                     ! clear direction flag
        fninit                  ! initalize FPU
        mov     eax,0           ! clear return code
        mov     [wrapper_exit_code],eax
        call    wrapper_end     ! execute next module
        mov     eax,[wrapper_exit_code] ! load the exit code
        push    eax             ! place as parameter
        calll   [kernel32_exitprocess] ! perform exit
! should not execute past this point
        ret                     ! exit to windows

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
! Start of wrapper definitions                                                !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

        ptocf   _lread, kernel32__lread, int, int, ptrl
        ptocf   _lwrite, kernel32__lwrite, int, int, ptrl
        ptocf   getstdhandle, kernel32_getstdhandle, int, int
	ptocf	_lopen, kernel32__lopen, int, pstr, int
	ptocf	_lcreat, kernel32__lcreat, int, pstr, int
        ptocf   _lclose, kernel32__lclose, int, int
        ptocf 	_llseek, kernel32__llseek, int, int, int, int
        ptocf   getfilesize, kernel32_getfilesize, int, int, int
	ptocf	deletefilea, kernel32_deletefilea, bool, pstr
	ptocf	movefilea, kernel32_movefilea, bool, pstr, pstr
	ptocf	findfirstfilea, kernel32_findfirstfilea, int, pstr, ptr
        ptocf   findnextfilea, kernel32_findnextfilea, int, int, ptr
        ptocf   findclose, kernel32_findclose, int, int
        ptocf   filetimetosystemtime, kernel32_filetimetosystemtime, int, ptr, ptr
        ptocf   systemtimetofiletime, kernel32_systemtimetofiletime, int, ptr, ptr
        ptocf   filetimetodosdatetime, kernel32_filetimetodosdatetime, bool, ptr, ptr, ptr
	ptocf	getsystemtime, kernel32_getsystemtime, void, ptr
	ptocf	getlocaltime, kernel32_getlocaltime, void, ptr
        ptocf   gettimezoneinformation, kernel32_gettimezoneinformation, int, ptr            
        ptocf   createwindowexa_n, user32_createwindowexa, int, int, pstr, pstr,\
                   int, int, int, int, int, int, int, int, zer
        ptocf   destroywindow, user32_destroywindow, bool, int
        ptocf   showwindow, user32_showwindow, bool, int, int
        ptocf   registerclassa, user32_registerclassa, bool, wclsptr
        ptocf   updatewindow, user32_updatewindow, bool, int
        ptocf   getmodulehandlea_n, kernel32_getmodulehandlea, int, zer
        ptocf   loadicona_n, user32_loadicona, int, zer, int
        ptocf   loadcursora_n, user32_loadcursora, int, zer, int
        ptocf   getstockobject, gdi32_getstockobject, int, int
        ptocf   selectobject, gdi32_selectobject, int, int, int
        ptocf   messageboxa, user32_messageboxa, int, int, str, str, int
        ptocf   getmessagea, user32_getmessagea, bool, ptr, int, int, int
        ptocf   peekmessage, user32_peekmessagea, bool, ptr, int, int, int, int
        ptocf   translatemessage, user32_translatemessage, bool, ptr
        ptocf   dispatchmessage, user32_dispatchmessagea, int, ptr
        ptocf   postquitmessage, user32_postquitmessage, void, int
        ptocf   postmessage, user32_postmessagea, bool, int, int, int, int 
        ptocf   defwindowproc, user32_defwindowproca, int, int, int, int, int
        ptocf   beginpaint, user32_beginpaint, int, int, ptr
        ptocf   endpaint, user32_endpaint, bool, int, ptr
        ptocf   getclientrect, user32_getclientrect, bool, int, ptr
        ptocf   drawtexta, user32_drawtexta, int, int, strl, ptr, int 
        ptocf   textouta, gdi32_textouta, bool, int, int, int, strl
        ptocf   getdc, user32_getdc, int, int
        ptocf   releasedc, user32_releasedc, bool, int, int
        ptocf   gettextmetrics, gdi32_gettextmetricsa, bool, int, ptr
        ptocf   validatergn_n, user32_validatergn, bool, int, zer
        ptocf   showcursor, user32_showcursor, int, bool
        ptocf   createcaret, user32_createcaret, bool, int, int, int, int
        ptocf   destroycaret, user32_destroycaret, bool
        ptocf   showcaret, user32_showcaret, bool, int
        ptocf   hidecaret, user32_hidecaret, bool, int
        ptocf   setcaretpos, user32_setcaretpos, bool, int, int
        ptocf   settextcolor, gdi32_settextcolor, int, int, int
        ptocf   setbkcolor, gdi32_setbkcolor, int, int, int
        ptocf   rectangle, gdi32_rectangle, bool, int, int, int, int, int
        ptocf   roundrect, gdi32_roundrect, bool, int, int, int, int, int, int, int
        ptocf   setbkmode, gdi32_setbkmode, int, int, int
        ptocf   settimer, user32_settimer, int, int, int, int, ptr
        ptocf   settimer_n, user32_settimer, int, int, int, int, zer
        ptocf   killtimer, user32_killtimer, bool, int, int
        ptocf   setwindowtexta, user32_setwindowtexta, bool, int, str
        ptocf   setwindowpos, user32_setwindowpos, bool, int, int, int, int, int, int, int
        ptocf   adjustwindowrectex, user32_adjustwindowrectex, bool, ptr, int, bool, int
	ptocf	getenvironmentvariablea, kernel32_getenvironmentvariablea, int, pstr, strl
	ptocf	setenvironmentvariablea, kernel32_setenvironmentvariablea, bool, pstr, str
	ptocf	setenvironmentvariablea_n, kernel32_setenvironmentvariablea, bool, pstr, zer
	ptocf	createprocessa_nn, kernel32_createprocessa, bool, pstr, str,\
                zer, zer, bool, int, evl, pstr, ptr, ptr
        ptocf   getcurrentdirectorya, kernel32_getcurrentdirectorya, int, lstr
        ptocf   setcurrentdirectorya, kernel32_setcurrentdirectorya, bool, pstr
        ptocf   waitforsingleobject, kernel32_waitforsingleobject, int, int, int
        ptocf   closehandle, kernel32_closehandle, bool, int
        ptocf   setfileattributesa, kernel32_setfileattributesa, bool, pstr, int
        ptocf   getfileattributesa, kernel32_getfileattributesa, int, pstr
        ptocf   getexitcodeprocess, kernel32_getexitcodeprocess, bool, int, ptr
        ptocf   createdirectorya_n, kernel32_createdirectorya, bool, pstr, zer
        ptocf   removedirectorya, kernel32_removedirectorya, bool, pstr
        ptocf   getdiskfreespacea, kernel32_getdiskfreespacea, bool, pstr, ptr, ptr, ptr, ptr
        ptocf   exitprocess, kernel32_exitprocess, void, int
        ptocf   beep, kernel32_beep, bool, int, int
        ptocf   createsolidbrush, gdi32_createsolidbrush, int, int
        ptocf   fillrect, user32_fillrect, bool, int, ptr, int
        ptocf   createcompatibledc, gdi32_createcompatibledc, int, int
        ptocf   deleteobject, gdi32_deleteobject, bool, int
        ptocf   createcompatiblebitmap, gdi32_createcompatiblebitmap, int, int, int, int
        ptocf   bitblt, gdi32_bitblt, bool, int, int, int, int, int, int, int, int, int
        ptocf   stretchblt, gdi32_stretchblt, bool, int, int, int, int, int, int, int, int, int, int, int
        ptocf   movetoex_n, gdi32_movetoex, bool, int, int, int, zer
        ptocf   lineto, gdi32_lineto, bool, int, int, int
        ptocf   createpen, gdi32_createpen, int, int, int, int
        ptocf   extcreatepen_nn, gdi32_extcreatepen, int, int, int, ptr, zer, zer
        ptocf   ellipse, gdi32_ellipse, bool, int, int, int, int, int
        ptocf   setpixel, gdi32_setpixel, int, int, int, int, int
        ptocf   setrop2, gdi32_setrop2, int, int, int
        ptocf   createfont, gdi32_createfonta, int, int, int, int, int, int,\
                   bool, bool, bool, int, int, int, int, int, pstr
        ptocf   getoutlinetextmetrics, gdi32_getoutlinetextmetricsa, bool, int, int, ptr        
        ptocf   getcharabcwidths, gdi32_getcharabcwidthsa, bool, int, int, int, ptr
        ptocf   getglyphoutline_metrics, gdi32_getglyphoutline, int, int, int, \
                   zer, ptr, zer, zer, ptr
        ptocf   gettextextentpoint32, gdi32_gettextextentpoint32a, bool, int, strl, ptr
        ptocf   getdevicecaps, gdi32_getdevicecaps, int, int, int
        ptocf   initializecriticalsection, kernel32_initializecriticalsection, void, ptr
        ptocf   entercriticalsection, kernel32_entercriticalsection, void, ptr
        ptocf   leavecriticalsection, kernel32_leavecriticalsection, void, ptr
        ptocf   deletecriticalsection, kernel32_deletecriticalsection, void, ptr
        ptocf   loadimage, user32_loadimagea, int, int, pstr, int, int, int, int
        ptocf   getbitmapdimensionex, gdi32_getbitmapdimensionex, bool, int, ptr
        ptocf   getobject_bitmap, gdi32_getobjecta, int, int, int, ptr
        ptocf   setstretchbltmode, gdi32_setstretchbltmode, int, int, int
        ptocf   deletedc, gdi32_deletedc, bool, int
        ptocf   setviewportorgex_n, gdi32_setwindoworgex, bool, int, int, int, zer
        ptocf   getviewportextex, gdi32_getviewportextex, bool, int, ptr
        ptocf   setviewportextex, gdi32_setviewportextex, bool, int, int, int, ptr
        ptocf   setwindowextex, gdi32_setwindowextex, bool, int, int, int, ptr
        ptocf   scaleviewportextex, gdi32_scaleviewportextex, bool, int, int, \
                   int, int, int, ptr
        ptocf   setmapmode, gdi32_setmapmode, int, int, int
        ptocf   lptodp_o, gdi32_lptodp, bool, int, ptr, one
        ptocf   settextjustification, gdi32_settextjustification, bool, int, int, int
        ptocf   getcharacterplacement, gdi32_getcharacterplacementa, int, \
                   int, strl, int, ptr, int
        ptocf   exttextout_n, gdi32_exttextouta, bool, int, int, int, int, \
                   zer, strl, ptr
        ptocf   polygon, gdi32_polygon, bool, int, ptrl
        ptocf   arc, gdi32_arc, bool, int, int, int, int, int, int, int, int, \
                   int
        ptocf   pie, gdi32_pie, bool, int, int, int, int, int, int, int, int, \
                   int
        ptocf   chord, gdi32_chord, bool, int, int, int, int, int, int, int, \
                   int, int
!
! Wincon
!
        ptocf   peekconsoleinput, kernel32_peekconsoleinputa, bool, int, ptrl, ptr
        ptocf   readconsoleinput, kernel32_readconsoleinputa, bool, int, ptrl, ptr
        ptocf   writeconsoleinput, kernel32_writeconsoleinputa, bool, int, ptrl, ptr
! readconsoleoutput
! writeconsoleoutput
        ptocf   readconsoleoutputcharacter, kernel32_readconsoleoutputcharactera, bool, int, strl, int, ptr
        ptocf   readconsoleoutputattribute, kernel32_readconsoleoutputattribute, bool, int, ptrl, int, ptr
        ptocf   writeconsoleoutputcharacter, kernel32_writeconsoleoutputcharactera, bool, int, strl, int, ptr
        ptocf   writeconsoleoutputattribute, kernel32_writeconsoleoutputattribute, bool, int, ptrl, int, ptr
        ptocf   fillconsoleoutputcharacter, kernel32_fillconsoleoutputcharactera, bool, int, int, int, ptr
        ptocf   fillconsoleoutputattribute, kernel32_fillconsoleoutputattribute, bool, int, int, int, ptr
        ptocf   getconsolemode, kernel32_getconsolemode, bool, int, ptr
        ptocf   getnumberofconsoleinputevents, kernel32_getnumberofconsoleinputevents, bool, int, ptr
        ptocf   getconsolescreenbufferinfo, kernel32_getconsolescreenbufferinfo, bool, int, ptr
        ptocf   getlargestconsolewindowsize, kernel32_getlargestconsolewindowsize, int, int
        ptocf   getconsolecursorinfo, kernel32_getconsolecursorinfo, bool, int, ptr
        ptocf   getnumberofconsolemousebuttons, kernel32_getnumberofconsolemousebuttons, bool, ptr
        ptocf   setconsolemode, kernel32_setconsolemode, bool, int, int
        ptocf   setconsoleactivescreenbuffer, kernel32_setconsoleactivescreenbuffer, bool, int
        ptocf   flushconsoleinputbufer, kernel32_flushconsoleinputbuffer, bool, int
        ptocf   setconsolescreenbuffersize, kernel32_setconsolescreenbuffersize, bool, int, int
        ptocf   setconsolecursorposition, kernel32_setconsolecursorposition, bool, int, int
        ptocf   setconsolecursorinfo, kernel32_setconsolecursorinfo, bool, int, ptr
        ptocf   scrollconsolescreenbuffer, kernel32_scrollconsolescreenbuffera, bool, int, ptr, ptr, int, ptr
        ptocf   scrollconsolescreenbuffer_n, kernel32_scrollconsolescreenbuffera, bool, int, ptr, zer, int, ptr
        ptocf   setconsolewindowinfo, kernel32_setconsolewindowinfo, bool, int, int, ptr
        ptocf   setconsoletextattribute, kernel32_setconsoletextattribute, bool, int, int
! setconsolectrlhandler
        ptocf   generateconsolectrlevent, kernel32_generateconsolectrlevent, bool, int, int
        ptocf   allocconsole, kernel32_allocconsole, bool
        ptocf   freeconsole, kernel32_freeconsole, bool
        ptocf   getconsoletitle, kernel32_getconsoletitlea, int, strl
        ptocf   setconsoletitle, kernel32_setconsoletitlea, bool, strl
! readconsole
! writeconsole
        ptocf   createconsolescreenbuffer_nn, kernel32_createconsolescreenbuffer, int, int, int, zer, int, zer
! getconsolecp
! setconsolecp
! getconsoleoutcp
! setconsoleoutputcp
!
! MMSystem
!
        ptocf   joysetcapture, winmm_joysetcapture, int, int, int, int, bool
        ptocf   joyreleasecapture, winmm_joyreleasecapture, int, int
        ptocf   joygetnumdevs, winmm_joygetnumdevs, int
        ptocf   midioutgetnumdevs, winmm_midioutgetnumdevs, int
        ptocf   midioutopen_nnn, winmm_midioutopen, int, ptr, int, zer, zer, zer
        ptocf   midioutclose, winmm_midioutclose, int, int
        ptocf   midioutshortmsg, winmm_midioutshortmsg, int, int, int
        ptocf   playsound, winmm_playsound, bool, pstr, int, int
        ptocf   mcisendstring_nnn, winmm_mcisendstringa, int, str, zer, zer, zer
        ptocf   timegettime, winmm_timegettime, int
        ptocf   timekillevent, winmm_timekillevent, int, int

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
! Special implementations                                                     !
!                                                                             !
! The following are system calls which have special implementation not        !
! covered by the macro system.                                                !
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
sc_getcommandlinea:
        savall                  ! save registers and flags
        calll   [kernel32_getcommandlinea] ! call function
        mov     edi,eax         ! place string address
        xor     eax,eax         ! search for zero
        mov     ebx,edi         ! save start
        xor     ecx,ecx         ! search forever
        dec     ecx
        repne                   ! search for the first zero
        scasb
        dec     edi             ! index zero termination
        sub     edi,ebx         ! find length        
        mov     eax,ebx         ! place address
        mov     ebx,edi         ! place length
        rstptr                  ! restore all but eax/ebx
        ret                     ! exit
                

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!
! function sc_getenvironmentstringsa: sc_evsptr;
!
! We translate each string to a pair of dymamic entries and form a list,
! so the table is fully buffered.
!
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
        rep                     ! move string to buffer
        movsb
        pushd   eax             ! save string address
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
        pop     edi             ! get return address
        pop     eax             ! get hwnd
        pop     ebx             ! get imsg
        pop     ecx             ! get wparam
        pop     edx             ! get lparam
        push    edi             ! replace return address
        enter   0,1             ! create the main frame
sc_wndproct01:
        calll   0               ! call the function
sc_wndproct02:
        leave                   ! remove dummy frame
        ret                     ! exit
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
        push    edx             ! place thread id
        push    ecx             ! place creation flags
        pushd   0               ! no parameter pointer
        push    eax             ! save stack size
        push    ebx             ! save procedure pointer
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
        push    ebx             ! save flag
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
        push    esi             ! save flag
        push    edx             ! save lparam
        push    ebx             ! save font info pointer
        push    eax             ! save handle to device context
        push    ecx             ! save handler function address
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
        push    esi             ! save flags
        push    edx             ! save user data
        push    ebx             ! save resolution
        push    eax             ! save delay
        push    ecx             ! save handler function address
        mov     eax,sc_gmem_fixed or sc_gmem_zeroinit ! place mode flags
        mov     ebx,sc_timrpt03-sc_timrpt ! place length of thunk
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
sc_timrpt03:

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
        rep                     ! move it
        movsb
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
sc_crkmsg:
        pop     ebx             ! get return address
        pop     ecx             ! get address l
        pop     edx             ! get address h
        pop     eax             ! get message
        mov     esi,eax         ! save copy
        and     eax,$ffff       ! mask
        mov     [ecx],eax       ! place that
        mov     eax,esi         ! restore message
        ror     eax,16          ! place high half in low
        and     eax,$ffff       ! mask
        mov     [edx],eax       ! place that
        jmp     ebx             ! return to caller


!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                             !
! Data                                                                        !
!                                                                             !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

wrapper_exit_code: defvs   4    ! exit code holder
!
wrapper_end:
