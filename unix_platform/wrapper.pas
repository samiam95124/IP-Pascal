{******************************************************************************
*                                                                             *
*                       UNIX SYSTEM CALL WRAPPER DEFINE FILE                  *
*                                                                             *
*                              2002/5 S. A. Moore                             *
*                                                                             *
* Defines all of the system calls used, in Pascal format. The actual wrappers *
* are contained in "wrapper.asm". This module is simply used to provide       *
* source level definitions.                                                   *
* In adapting C type calls to pascal type calls, several adaptions occur:     *
*                                                                             *
* 1.Strings are converted from Pascal's format to the zero terminated format  *
* in C. This is pretty transparent to the user, but if a zero is passed in    *
* the string, this effectively terminates it.                                 *
*                                                                             *
* 2. Unix (and other C based call systems) treat some pointer passed          *
* structures is by allowing them to be passed nil if the parameter is         *
* "nonexistent". Since C typically passes VAR arguments that way, the result  *
* is not only unworkable but also very unsafe.                                *
* The answer way we do this is to create a different version of the full call *
* (the one that has the structure passed) that has the optional parameter     *
* zeroed out. This call will not have a parameter in that spot, and will have *
* the form:                                                                   *
*                                                                             *
* myfunc(x, y, z) - Normal call                                               *
* myfunc_n(x, y)  - Call with z NULL                                          *
* myfunc_n_n(x)   - Call with y and z NULL                                    *
*                                                                             *
* The problem is that the option parameters can be scattered around the calls *
* list. The only way to find out the position for sure is to look at the      *
* parameter names or look at wrapper.asm.                                     *
*                                                                             *
******************************************************************************}

module wrapper;

uses stddef; { some standard definitions }


const

sc_stdin  = 0;
sc_stdout = 1;
sc_stderr = 2;

sc_o_accmode   = &0003;
sc_o_rdonly    = &00;
sc_o_wronly    = &01;
sc_o_rdwr      = &02;
sc_o_creat     = &0100;
sc_o_excl      = &0200;
sc_o_noctty    = &0400;
sc_o_trunc     = &01000;
sc_o_append    = &02000;
sc_o_nonblock  = &04000;
sc_o_ndelay    = sc_o_nonblock;
sc_o_sync      = &010000;
sc_fasync      = &020000;
sc_o_direct    = &040000;
sc_o_largefile = &0100000;
sc_o_directory = &0200000;
sc_o_nofollow  = &0400000;

sc_s_isuid = &04000;
sc_s_isgid = &02000;
sc_s_isvtx = &01000; 
sc_s_irusr = &00400;
sc_s_iwusr = &00200;
sc_s_ixusr = &00100; 
sc_s_irgrp = &00040;
sc_s_iwgrp = &00020;
sc_s_ixgrp = &00010; 
sc_s_iroth = &00004;
sc_s_iwoth = &00002;
sc_s_ixoth = &00001; 

sc_dirlen = 256;

sc_s_ifmt    = $f000; 
sc_s_ifdir   = $4000; 
sc_s_ififo   = $1000; 
sc_s_ifchr   = $2000; 
sc_s_ifblk   = $3000; 
sc_s_ifreg   = $8000; 
sc_s_iread   = $0100; 
sc_s_iwrite  = $0080; 
sc_s_iexec   = $0040; 
sc_s_igread  = $0020; 
sc_s_igwrite = $0010; 
sc_s_igexec  = $0008; 
sc_s_ioread  = $0004; 
sc_s_iowrite = $0002; 
sc_s_ioexec  = $0001; 

type

sc_short = 0..65535;

sc_dirptr = ^sc_dirent;
sc_dirent = record

   d_ino:    integer;
   d_off:    integer;
   d_reclen: sc_short;
   d_name:   packed array [1..sc_dirlen] of char

end;
sc_dirarr = array of sc_dirent;

sc_sstat = record

   st_dev:     integer;
   st_ino:     integer;
   st_mode:    sc_short;
   st_nlink:   sc_short;
   st_uid:     sc_short;
   st_gid:     sc_short;
   st_rdev:    integer;
   st_size:    integer;
   st_blksize: integer;
   st_blocks:  integer;
   st_atime:   integer;
   st_atimep:  integer;
   st_mtime:   integer;
   st_mtimep:  integer;
   st_ctime:   integer;
   st_ctimep:  integer;
   st_pad1:    integer;
   st_pad2:    integer

end;

{ the docs for this are trashed, it needs to be hand verified }

sc_sstat64 = record

   st_dev:     integer;
   st_ino:     integer;
   st_mode:    sc_short;
   st_nlink:   sc_short;
   st_uid:     sc_short;
   st_gid:     sc_short;
   st_rdev:    integer;
   st_size:    integer;
   st_blksize: integer;
   st_blocks:  integer;
   st_atime:   integer;
   st_atimep:  integer;
   st_mtime:   integer;
   st_mtimep:  integer;
   st_ctime:   integer; 
   st_ctimep:  integer;
   st_pad1:    integer;
   st_pad2:    integer

end;

sc_timeval = record

   tv_sec:  integer; 
   tv_usec: integer

end;

sc_timezone = record

   tz_minuteswest: integer;
   tz_dsttime:     integer

end;

sc_utimbuf = record

   actime:  integer;
   modtime: integer

end;

sc_stab = array of pstring;
sc_stabptr = ^sc_stab;

sc_ppair = array [1..2] of integer;

sc_tms = record

   tms_utime:  integer;
   tms_stime:  integer;
   tms_cutime: integer;
   tms_cstime: integer

end;

sc_sflock = record

   l_type:   sc_short;
   l_whence: sc_short;
   l_start:  integer;
   l_len:    integer;
   l_pid:    integer

end;

sc_rlimit = record

   rlim_cur: integer;
   rlim_max: integer

end;

sc_rusage = record

   ru_utime:    sc_timeval;
   ru_stime:    sc_timeval;
   ru_maxrss:   integer;
   ru_ixrss:    integer;
   ru_idrss:    integer;
   ru_isrss:    integer;
   ru_minflt:   integer;
   ru_majflt:   integer;
   ru_nswap:    integer;
   ru_inblock:  integer;
   ru_oublock:  integer;
   ru_msgsnd:   integer;
   ru_msgrcv:   integer;
   ru_nsignals: integer;
   ru_nvcsw:    integer;
   ru_nivcsw:   integer

end;

sc_intlst = array of integer;

sc_sstatfs = record

   f_type:    integer;
   f_bsize:   integer;
   f_blocks:  integer;
   f_bfree:   integer;
   f_bavail:  integer;
   f_files:   integer;
   f_ffree:   integer;
   f_fsid:    integer;
   f_namelen: integer;
   f_spare:   array [1..6] of integer

end;

sc_itimerval = record

   it_interval: sc_timeval;
   it_value:    sc_timeval

end;

sc_vm86_regs = record

   ebx:        integer;
   ecx:        integer;
   edx:        integer;
   esi:        integer;
   edi:        integer;
   ebp:        integer;
   eax:        integer;
   __null_ds:  integer;
   __null_es:  integer;
   __null_fs:  integer;
   __null_gs:  integer;
   orig_eax:   integer;
   eip:        integer;
   cs, __csh:  sc_short;
   eflags:     integer;
   esp:        integer;
   ss, __ssh:  sc_short;
   es, __esh:  sc_short;   
   ds, __dsh:  sc_short;
   fs, __fsh:  sc_short;
   gs, __gsh:  sc_short

end;

sc_revectored_struct = record

   __map: array [1..8] of integer

end;

{ must specify this as critically packed }

{

sc_vm86plus_info_struct = record

   force_return_for_pic: 0..1;
   vm86dbg_active:       0..1;
   vm86dbg_tfpendig:     0..1;
   unused:               0..268435455;
   is_vm86plus:          0..1;
   vm86dbg_intxxtab:     array [1..32] of byte

end;

}

sc_vm86_struct = record

   regs:             sc_vm86_regs;
   flags:            integer;
   screen_bitmap:    integer;
   cpu_type:         integer;
   int_revectored:   sc_revectored_struct;
   int21_revectored: sc_revectored_struct

end;

{

sc_vm86plus_struct = record
   
   regs:             sc_vm86_regs;
   flags:            integer;
   screen_bitmap:    integer;
   cpu_type:         integer;
   int_revectored:   sc_revectored_struct;
   int21_revectored: sc_revectored_struct;
   vm86plus:         sc_vm86plus_info_struct

end;

}

sc_ssysinfo = record

   uptime:    integer;
   loads:     array [1..3] of integer;
   totalram:  integer;
   freeram:   integer;
   sharedram: integer;
   bufferram: integer;
   totalswap: integer;
   freeswap:  integer;
   procs:     sc_short;
   totalhigh: integer;
   mem_unit:  integer;
   _f:        array [1..20-2*4-4] of char

end;

sc_utsname = record

   sysname: pstring;
   nodename: pstring;
   release: pstring;
   version: pstring;
   machine: pstring;
   domainname: pstring

end;

sc_timex = record

   modes:     integer;
   offset:    integer;
   freq:      integer;
   maxerror:  integer;
   esterror:  integer;
   status:    integer;
   constant:  integer;
   precision: integer;
   tolerance: integer;
   time:      sc_timeval;
   tick:      integer

end;

sc_loff_t = array [1..2] of integer;

sc_iovec = array of bytptr;

{ this strikes me as unlikely to be complete }

sc_sched_param = record

   sched_priority: integer

end;

sc_timespec = record

   tv_sec:  integer;
   tv_nsec: integer

end;

sc_pollfd = record

   fd:      integer;
   events:  sc_short;
   revents: sc_short

end;

sc_pollfdarr = array of sc_pollfd;

sc_nfsctl_arg_vars = (sc_nfsctl_arg_vars_svc,
                      sc_nfsctl_arg_vars_client,
                      sc_nfsctl_arg_vars_export,
                      sc_nfsctl_arg_vars_map,
                      sc_nfsctl_arg_vars_getfh,
                      sc_nfsctl_arg_vars_debug);

{ need these substructure definitions }

{

sc_nfsctl_arg = record

   ca_version: integer;
   case sc_nfsctl_arg_vars of

      sc_nfsctl_arg_vars_svc:    (u_svc:    sc_nfsctl_svc);
      sc_nfsctl_arg_vars_client: (u_client: sc_nfsctl_client);
      sc_nfsctl_arg_vars_export: (u_export: sc_nfsctl_export);
      sc_nfsctl_arg_vars_map:    (u_umap:   sc_nfsctl_uidmap);
      sc_nfsctl_arg_vars_getfh:  (u_getfh:  sc_nfsctl_fhparm);
      sc_nfsctl_arg_vars_debug:  (u_debug:  integer)

end;

}

sc_nfsctl_res_vars = (sc_nfs_ctl_res_vars_getfh,
                      sc_nfs_ctl_res_vars_debug);

{ need these substructure definitions }

{

sc_nfsctl_res = record

   case sc_nfsctl_res_vars of

      sc_nfs_ctl_res_vars_getfh: (cr_getfh: sc_knfs_fh);
      sc_nfs_ctl_res_vars_debug: (cr_debug: integer)

end;

}

sc_cap_user_header_t = record

   version: integer;
   pid:     integer

end;

sc_cap_user_data_t = record

   effective:   integer;
   permitted:   integer;
   inheritable: integer

end;

var wrapper_exit_code: integer;

{ these are functions that are implemented locally }

procedure sc_malloc(var p: gbtptr; length: integer); external;
procedure sc_free(p: gbtptr); external;
procedure sc_getcmd(var cmd: pstring); external;
function sc_errno: integer; external;
function sc_allenv: sc_stabptr; external;

{ these are functions that generate system calls. Note that we cannot implement calls
  with void pointers, which means a completely typeless access. Obsolete and 
  unimplemented don't appear. placeholders (commented out routines) indicate
  some problem with implementation that will be commented }

{ untested } procedure sc_exit(ec: integer); external;
{ untested } function sc_fork: integer; external;  { this requires libray help for reg parameter }
function sc_read(fd: integer; var buf: bytarr): integer; external;
function sc_write(fd: integer; view buf: bytarr): integer; external;
function sc_open(view name: string; flags, perms: integer): integer; external;
function sc_close(fd: integer): integer; external;
{ untested } function sc_waitpid(pid: integer; var sts: integer; opt: integer): integer; external;
function sc_creat(view name: string; perms: integer): integer; external;
{ untested } function sc_link(view op, np: string): integer; external;
function sc_unlink(view name: string): integer; external;
{ untested } function sc_execve(view d: string; view av, ev: sc_stab): integer; external;
function sc_chdir(view np: string): integer; external;
{ untested } function sc_time(var t: integer): integer; external;
{ untested } function sc_mknod(view pn: string; md: integer; dev: integer): integer; external;
function sc_chmod(view d: string; mode: integer): integer; external;
{ untested } function sc_lchown(view pn: string; own, grp: integer): integer; external;
{ untested } function sc_break: integer; external;
{ untested } function sc_lseek(fd: integer; offset: integer; origin: integer): integer; external;
{ untested } function sc_getpid: integer; external;
{ mount is possible by breaking out into multiple calls the different type forms of "data"
  function sc_mount(view src, tar, typ: string; mf: integer; var data: void); external; }
{ untested } function sc_umount(view tar: string): integer; external;
{ untested } function sc_setuid(uid: integer): integer; external;
{ untested } function sc_getuid: integer; external;
{ untested } function sc_stime(var t: integer): integer; external;
{ ptrace is possible by breaking out into multiple calls the different type forms of "data"
  function sc_ptrace(req: integer; pid: integer; var addr: void; var data: void); external; }
{ untested } function sc_alarm(sec: integer): integer; external;
{ untested } function sc_pause: integer; external; 
{ untested } function sc_utime(view fn: string; var buf: sc_utimbuf): integer; external;
{ untested } function sc_access(view pn: string; md: integer): integer; external;
{ untested } function sc_nice(inc: integer): integer; external;
{ untested } procedure sc_sync; external;
{ untested } function sc_kill(pid: integer; sig: integer): integer; external;
{ untested } function sc_rename(view oldpath, newpath: string): integer; external;
function sc_mkdir(view d: string; mode: integer): integer; external;
function sc_rmdir(view d: string): integer; external;
{ untested } function sc_dup(fd: integer): integer; external;
{ untested } function sc_pipe(var pp: sc_ppair): integer; external;
{ untested } function sc_times(var tms: sc_tms): integer; external;
{ This function is managed by the wrapper, use of it would cause program failure
  function sc_brk(var addr: void): integer; external; }
{ untested } function sc_setgid(gid: integer): integer; external;
{ untested } function sc_getgid: integer; external;
{ signal can be implemented, but needs a stack based translator
  function sc_signal(sn: integer; procedure sig(signo: integer)); external; }
{ untested } function sc_geteuid: integer; external;
{ untested } function sc_getegid: integer; external;
{ untested } function sc_acct(view fn: string): integer; external;
{ untested } function sc_umount2(view sf: string; fl: integer): integer; external;
{ ioctl can be implemented by breaking out the argp types into multiple calls
  function sc_ioctl(d: integer; req: integer; argp: void): integer; external; }
{ untested } function sc_fcntl(fd: integer; cmd: integer; var lock: sc_sflock): integer; external;
{ untested } function sc_setpgid(pid: integer; pgid: integer): integer; external;
{ untested } function sc_umask(msk: integer): integer; external;
{ untested } function sc_chroot(view pn: string): integer; external;
{ untested } function sc_dup2(ofd: integer; nfd: integer): integer; external;
{ untested } function sc_getppid: integer; external;
{ untested } function sc_getpgrp: integer; external;
{ untested } function sc_setsid: integer; external;
{ sigaction needs callback translation 
  function sc_sigaction(sn: integer; var a, oa: sc_sigaction): integer; external; } 
{ sgetmask ? }
{ ssetmask ? }
{ untested } function sc_setreuid(ruid, euid: integer): integer; external;
{ untested } function sc_setregid(rgid, egid: integer): integer; external;
{ sigsuspend ? }
{ untested } function sc_sigpendng(var sset: integer): integer; external;
{ untested } function sc_sethostname(view hn: string): integer; external;
{ untested } function sc_setrlimit(res: integer; view rlim: sc_rlimit): integer; external;
{ untested } function sc_getrlimit(res: integer; var rlim: sc_rlimit): integer; external;
{ untested } function sc_getrusage(who: integer; var usage: sc_rusage): integer; external;
function sc_gettimeofday(var tv: sc_timeval; var tz: sc_timezone): integer; external;
{ untested } function sc_settimeofday(view tv: sc_timeval; view tz: sc_timezone): integer; external;
{ untested } function sc_getgroups(var list: sc_intlst): integer; external;
{ untested } function sc_setgroups(view list: sc_intlst): integer; external;
{ we need > 5 parameter macros to implement this
  function sc_select(var rfds, wfds, efds: sc_intlst; view to: sc_timeval): integer; external; }
{ untested } function sc_symlink(view opn, npn: string): integer; external;
{ untested } function sc_readlink(view pn: string; var sn: string): integer; external;
{ untested } function sc_uselib(view ln: string): integer; external;
{ untested } function sc_swapon(view pn: string; sf: integer): integer; external;
{ sc_reboot contains a void pointer, and no docs found for it
  function sc_reboot(m, m2, fl: integer; var arg: void): integer; external; }
function sc_readdir(fd: integer; var dir: sc_dirent; count: integer): integer; external;
{ untested } function sc_mmap(var mem: bytarr; prot, fl, fd, off: integer): integer; external;
{ untested } function sc_munmap(var mem: bytptr): integer; external;
{ untested } function sc_truncate(view fn: string; ln: integer): integer; external;
{ untested } function sc_ftruncate(fd: integer; ln: integer): integer; external;
{ untested } function sc_fchmod(fd: integer; md: integer): integer; external;
{ untested } function sc_fchown(fd: integer; own, grp: integer): integer; external;
{ untested } function sc_getpriority(which: integer; who: integer): integer; external;
{ untested } function sc_setpriority(which, who, prio: integer): integer; external;
{ untested } function sc_statfs(view pn: string; var buf: sc_sstatfs): integer; external;
{ untested } function sc_fstatfs(fd: integer; var buf: sc_sstatfs): integer; external;
{ untested } function sc_ioperm(frm, num, ton: integer): integer; external;
{ sc_socket call contains void pointer, needs to be broken out into call types
  function sc_socketcall(call: integer; var args: void): integer; external; }
{ untested } function sc_syslog(typ: integer; var buf: string): integer; external;
{ untested } function sc_setitimer(which: integer; view val, oval: sc_itimerval): integer; external;
{ untested } function sc_getitimer(which: integer; var val: sc_itimerval): integer; external;
function sc_stat(view name: string; var sr: sc_sstat): integer; external;
{ untested } function sc_lstat(view name: string; var sr: sc_sstat): integer; external;
{ untested } function sc_fstat(fd: integer; var sr: sc_sstat): integer; external;
{ untested } function sc_iopl(lev: integer): integer; external;
{ untested } function sc_vhangup: integer; external;
{ untested } function sc_idle: integer; external;
{ untested } function sc_vm86old(view info: sc_vm86_struct): integer; external;
{ untested } function sc_wait4(pid, sts, opt: integer; var rusage: sc_rusage): integer; external;
{ untested } function sc_swapoff(view pn: string): integer; external;
{ untested } function sc_sysinfo(var info: sc_ssysinfo): integer; external;
{ sc_ipc has void, needs typed versions
  function sc_ipc(call, fst, sec, thrd: integer; var ptr: void; fif: integer)
         : integer; external; }
{ untested } function sc_fsync(fd: integer): integer; external;
{ untested } function sc_sigreturn(__unused: integer): integer; external;
{ clone ? }
{ untested } function sc_setdomainname(view dn: string): integer; external;
{ untested } function sc_uname(var buf: sc_utsname): integer; external;
{ sc_modify_ldt, there is just no way }
{ untested } function sc_adjtimex(var buf: sc_timex): integer; external;
{ sc_mprotect would be pointless to implement
  function sc_mprotect(view ma: bytarr; prot: integer): integer; external; }
{ untested } function sc_sigprocmask(how: integer; var nset, oset: integer): integer; external; 
{ create_module ? }
{ init_module contains void pointers in structure parameter
  function sc_init_module(view n: string; var image: smodule); integer; external; }
{ untested } function sc_delete_module(view n: string): integer; external;
{ get_kernel_syms, a very unfriendly function, needs to be called twice, once to
  get the number of symbols, then again with an allocated structure. it could well
  be that this is inherently unsafe if kernel symbols can grow multitask.
  function sc_get_kernel_syms(var table: sc_kernel_sym): integer; external; }
{ sc_quotactl needs to be broken out by type
  function sc_quotactl(cmd: integeger; view sn: string; id: integer; addr: sc_caddr_t)
           : integer; external; }
{ untested } function sc_getpgid(pid: integer): integer; external;
{ untested } function sc_fchdir(fd: integer): integer; external;
{ sc_bdflush contains void pointers
  function sc_bdflush(func: integer; var adata: void): integer; external; }
{ sysfs ? }
{ untested } function sc_personality(persona: integer): integer; external;
{ untested } function sc_setfsuid(fsuid: integer): integer; external;
{ untested } function sc_setfsgid(fsgid: integer): integer; external;
{ untested } function sc__llseek(fd: integer; high, low: integer; var res: sc_loff_t;
                    whence: integer): integer; external;
{ untested } function sc_getdents(fd: integer; var dirp: sc_dirarr): integer; external;
{ we need > 5 parameter macros to implement this
  function sc_select(var rfds, wfds, efds: sc_intlst; view to: sc_timeval): integer; external; }
{ untested } function sc_flock(fd: integer; opr: integer): integer; external;
{ untested } function sc_msync(var mem: bytarr; flg: integer): integer; external;
{ untested } function sc_readv(fd: integer; var vec: sc_iovec): integer; external;
{ untested } function sc_writev(fd: integer; var vec: sc_iovec): integer; external;
{ untested } function sc_getsid(pid: integer): integer; external;
{ untested } function sc_fdatasync(fd: integer): integer; external;
{ _sysctl contains hard addresses
  function sc__sysctl(var args: __sysctl_args): integer; external; }
{ mlock contains hard addresses
  mlock(var addr: void; len: integer): integer; external; }
{ munlock contains hard addresses
  munlock(var addr: void; len: integer): integer; external; }
{ untested } function sc_mlockall(flg: integer): integer; external;
{ untested } function sc_munlockall: integer; external;
{ untested } function sc_sched_setparam(pid: integer; view p: sc_sched_param): integer; external;
{ untested } function sc_sched_getparam(pid: integer; var p: sc_sched_param): integer; external;
{ untested } function sc_sched_setscheduler(pid, policy: integer; view p: sc_sched_param): integer; external;
{ untested } function sc_sched_getscheduler(pid: integer): integer; external;
{ untested } function sc_sched_yield: integer; external;
{ untested } function sc_sched_get_priority_max(policy: integer): integer; external;
{ untested } function sc_sched_get_priority_min(policy: integer): integer; external;
{ untested } function sc_sched_rr_get_interval(pid: integer; var tp: sc_timespec): integer; external;
{ untested } function sc_nanosleep(view reg: sc_timespec; var rem: sc_timespec): integer; external;
{ untested } function sc_mremap(view old, new: bytarr; fl: integer): integer; external;
{ untested } function sc_setresuid(ruid, euid, suid: integer): integer; external;
{ untested } function sc_getresuid(var ruid, euid, suid: integer): integer; external;
{ removed for structure define problems above
  function sc_vm86(fn: integer; var v86: sc_vm86plus_struct): integer; external; }
{ sc_query_module must be broken out into cases
  sc_query_module(view name: string; which: integer; var buf: void; bufsize: integer;
                  var ret: integer): integer; external; }
{ untested } function sc_poll(var ufds: sc_pollfdarr; timeout: integer): integer; external;
{ removed for structure define problems above
  function sc_nfsservctl(cmd: integer; var argp: sc_nfsctl_arg;
                       resp: sc_nfsctl_res): integer; external; }
{ untested } function sc_setresgid(rgid, egid, sgid: integer): integer; external;
{ untested } function sc_getresgid(var rgid, egid, sgid: integer): integer; external;
{ untested } function sc_prctl(opt, arg2, arg3, arg4, arg5: integer): integer; external;
{ these are undocumented
  rt_sigreturn
  rt_sigaction
  rt_sigprocmask
  rt_sigpending
  rt_sigtimedwait
  rt_sigqueueinfo
  rt_sigsuspend }
{ untested } function sc_pread(fd: integer; var buf: bytarr; offset: integer): integer; external;
{ untested } function sc_pwrite(fd: integer; view buf: bytarr; offset: integer): integer; external;
{ untested } function sc_chown(view path: string; own, grp: integer): integer; external; 
function sc_getcwd(var buf: string): integer; external;
{ untested } function sc_capget(var header: sc_cap_user_header_t; var data: sc_cap_user_data_t)
                   : integer; external;
{ untested } function sc_capset(var header: sc_cap_user_header_t; view data: sc_cap_user_data_t)
                   : integer; external;
{ sigaltstack has void pointers in its structure }
{ untested } function sc_sendfile(ofd, ifd: integer; var off: integer; cnt: integer): integer; external;
{ untested } function sc_vfork: integer; external;
{ ugetrlimit ? }
{ mmap2 ? }
{ untested } function sc_truncate64(view path: string; lenl, lenh: integer): integer; external;
{ untested } function sc_ftruncate64(fd: integer; lenl, lenh: integer): integer; external;
{ untested } function sc_stat64(view name: string; var sr: sc_sstat64): integer; external;
{ untested } function sc_lstat64(view name: string; var sr: sc_sstat64): integer; external;
{ untested } function sc_fstat64(fd: integer; var sr: sc_sstat64): integer; external;
{ untested } function sc_lchown32(view pn: string; own, grp: integer): integer; external;
{ untested } function sc_getuid32: integer; external;
{ untested } function sc_getgid32: integer; external;
{ untested } function sc_geteuid32: integer; external;
{ untested } function sc_getegid32: integer; external;
{ untested } function sc_setreuid32(ruid, euid: integer): integer; external;
{ untested } function sc_setregid32(rgid, egid: integer): integer; external;
{ untested } function sc_getgroups32(var list: sc_intlst): integer; external;
{ untested } function sc_setgroups32(view list: sc_intlst): integer; external;
{ untested } function sc_fchown32(fd: integer; own, grp: integer): integer; external;
{ untested } function sc_setresuid32(ruid, euid, suid: integer): integer; external;
{ untested } function sc_getresuid32(var ruid, euid, suid: integer): integer; external;
{ untested } function sc_setresgid32(rgid, egid, sgid: integer): integer; external;
{ untested } function sc_getresgid32(var rgid, egid, sgid: integer): integer; external;
{ untested } function sc_chown32(view path: string; own, grp: integer): integer; external;
{ untested } function sc_setuid32(uid: integer): integer; external;
{ untested } function sc_setgid32(gid: integer): integer; external;
{ untested } function sc_setfsuid32(fsuid: integer): integer; external;
{ untested } function sc_setfsgid32(fsgid: integer): integer; external;
{ untested } function sc_pivot_root(view new, old: string): integer; external;
{ mincore contains hard addresses }
{ madvise contains hard addresses }
{ madvise1 contains hard addresses }
{ getdents64 need details on 64 bit dirent structure }
{ fctl64 needs to be broken out into different types by cmd }

begin
end.

