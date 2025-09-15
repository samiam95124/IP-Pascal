!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                              !
! Module to equivalence new to old library entries                             !
!                                                                              !
! Equates new dotted format identifiers to old library names. This gets us     !
! the ability to use the new mode compiler output, which uses dotted format    !
! to separate parts of module scoped qualidents, with the old libraries.       !
!                                                                              !
! This module will be discarded when all libraries can be recompiled.          !
!                                                                              !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!
! Module skip jump
!
        jmp     paslib_equ_end     ! exit module
!
! link to equivalent routine
!
paslib.abort:   jmp    ps_abort
paslib.error:   jmp    ps_error
paslib.assign:  jmp    ps_assign
paslib.resfil:  jmp    ps_resfil
paslib.restxt:  jmp    ps_restxt
paslib.rwtfil:  jmp    ps_rwtfil
paslib.rwttxt:  jmp    ps_rwttxt
paslib.update:  jmp    ps_update
paslib.appfil:  jmp    ps_appfil
paslib.apptxt:  jmp    ps_apptxt
paslib.close:   jmp    ps_close
paslib.putfil:  jmp    ps_putfil
paslib.lbafil:  jmp    ps_lbafil
paslib.getfil:  jmp    ps_getfil
paslib.wrtfil:  jmp    ps_wrtfil
paslib.rdfil:   jmp    ps_rdfil
paslib.eoffil:  jmp    ps_eoffil
paslib.fillen:  jmp    ps_fillen
paslib.filloc:  jmp    ps_filloc
paslib.posfil:  jmp    ps_posfil
paslib.lbatxt:  jmp    ps_lbatxt
paslib.gettxt:  jmp    ps_gettxt
paslib.eoftxt:  jmp    ps_eoftxt
paslib.chkeol:  jmp    ps_chkeol
paslib.rdeol:   jmp    ps_rdeol
paslib.wrtchr:  jmp    ps_wrtchr
paslib.wrteol:  jmp    ps_wrteol
paslib.pagtxt:  jmp    ps_pagtxt
paslib.rdchr:   jmp    ps_rdchr
paslib.wrtstr:  jmp    ps_wrtstr
paslib.wrtstrf: jmp    ps_wrtstrf
paslib.wrtbol:  jmp    ps_wrtbol
paslib.wrtblf:  jmp    ps_wrtblf
paslib.wrtint:  jmp    ps_wrtint
paslib.wrtreal: jmp    ps_wrtreal
paslib.wrtrlf:  jmp    ps_wrtrlf
paslib.rdint:   jmp    ps_rdint
paslib.rdreal:  jmp    ps_rdreal
paslib.setstd:  jmp    ps_setstd
!
! Need to create assert handler
!
!paslib.assert:  jmp    ps_assert
!
syslib.alias:         jmp    ss_alias
syslib.resolve:       jmp    ss_resolve
! this does not exist yet
!syslib.sysfil:        jmp    ss_sysfil
syslib.openread:      jmp    ss_openread
syslib.openwrite:     jmp    ss_openwrite
syslib.openupdate:    jmp    ss_openupdate
syslib.close:         jmp    ss_close
syslib.read:          jmp    ss_read
syslib.write:         jmp    ss_write
syslib.position:      jmp    ss_position
syslib.location:      jmp    ss_location
syslib.length:        jmp    ss_length
syslib.eof:           jmp    ss_eof
syslib.delete:        jmp    ss_delete
syslib.change:        jmp    ss_change
syslib.exists:        jmp    ss_exists
syslib.getspace:      jmp    ss_getspace
syslib.putspace:      jmp    ss_putspace
syslib.alteol:        jmp    ss_alteol
syslib.wrterr:        jmp    ss_wrterr
!
maclib.multu64:       jmp    maclib_multu64
maclib.mults64:       jmp    maclib_mults64
maclib.divu64_i:      jmp    maclib_divu64_i
maclib.divu64:        jmp    maclib_divu64
maclib.modu64:        jmp    maclib_modu64
maclib.divs64:        jmp    maclib_divs64
maclib.mods64:        jmp    maclib_mods64
maclib.overflow:      jmp    maclib_overflow
maclib.fpuerr:        jmp    maclib_fpuerr
!
paslib_equ_end:
