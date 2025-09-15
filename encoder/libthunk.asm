!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!                                                                              !
!                        Library back translator thunk                         !
!                                                                              !
! Translates new mode fully qualified library references to the old method.    !
! This is required until we recompile all of the libraries.                    !
!                                                                              !
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

!
! Startup
!
        jmp     libthunk_end            ! skip over module

! paslib routine calls

paslib.abort:          jmp     ps_abort
paslib.error:          jmp     ps_error
paslib.wrtfil:         jmp     ps_wrtfil
paslib.wrtint:         jmp     ps_wrtint
paslib.wrtchr:         jmp     ps_wrtchr
paslib.wrtbol:         jmp     ps_wrtbol
paslib.wrtblf:         jmp     ps_wrtblf
paslib.wrtreal:        jmp     ps_wrtreal
paslib.wrtrlf:         jmp     ps_wrtrlf
paslib.wrtstr:         jmp     ps_wrtstr
paslib.wrtstrf:        jmp     ps_wrtstrf
paslib.wrteol:         jmp     ps_wrteol
paslib.pagtxt:         jmp     ps_pagtxt
paslib.rdfil:          jmp     ps_rdfil
paslib.rdint:          jmp     ps_rdint
paslib.rdchr:          jmp     ps_rdchr 
paslib.rdreal:         jmp     ps_rdreal
paslib.rdeol:          jmp     ps_rdeol 
paslib.eoftxt:         jmp     ps_eoftxt
paslib.chkeol:         jmp     ps_chkeol
paslib.eoffil:         jmp     ps_eoffil
paslib.fillen:         jmp     ps_fillen
paslib.filloc:         jmp     ps_filloc
paslib.getfil:         jmp     ps_getfil
paslib.gettxt:         jmp     ps_gettxt
paslib.putfil:         jmp     ps_putfil
paslib.lbafil:         jmp     ps_lbafil
paslib.lbatxt:         jmp     ps_lbatxt
paslib.restxt:         jmp     ps_restxt
paslib.resfil:         jmp     ps_resfil
paslib.rwttxt:         jmp     ps_rwttxt
paslib.rwtfil:         jmp     ps_rwtfil
paslib.update:         jmp     ps_update
paslib.apptxt:         jmp     ps_apptxt
paslib.appfil:         jmp     ps_appfil
paslib.close:          jmp     ps_close 
paslib.assign:         jmp     ps_assign
paslib.posfil:         jmp     ps_posfil
paslib.assert:         jmp     ps_assert
  
! syslib routine calls

syslib.delete:         jmp     ss_delete
syslib.change:         jmp     ss_change    
syslib.exists:         jmp     ss_exists    
syslib.getspace:       jmp     ss_getspace  
syslib.putspace:       jmp     ss_putspace  
syslib.newthread:      jmp     ss_newthread 
syslib.killthread:     jmp     ss_killthread
syslib.newlock:        jmp     ss_newlock   
syslib.displock:       jmp     ss_displock  
syslib.lock:           jmp     ss_lock      
syslib.unlock:         jmp     ss_unlock    
syslib.signal:         jmp     ss_signal    
syslib.signalone:      jmp     ss_signalone    
syslib.wait:           jmp     ss_wait    

! maclib routine calls

maclib.multu64:        jmp     maclib_multu64
maclib.mults64:        jmp     maclib_mults64
maclib.divu64:         jmp     maclib_divu64 
maclib.divs64:         jmp     maclib_divs64 
maclib.modu64:         jmp     maclib_modu64 
maclib.mods64:         jmp     maclib_mods64 
maclib.fpuerr:         jmp     maclib_fpuerr 

! wrapper routine calls

wrapper.ip_threadinit: jmp     sc_ip_threadinit

!
libthunk_end:
