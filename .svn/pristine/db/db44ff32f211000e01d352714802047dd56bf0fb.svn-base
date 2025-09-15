{*******************************************************************************
*                                                                              *
*                  SYSTEM INTERFACE LIBRARY FOR WINDOWS                        *
*                                                                              *
*                           1995/9 S. A. Moore                                 *
*                                                                              *
* Translates from the system independent calls to direct system calls on       *
* windows 95. These calls interface indirectly via the windows module.         *
* Several services are performed here. First, filenames are checked against    *
* the system list, and if found, either a predefined handle is fetched to      *
* access that, or a special handle is given for the command line file (which   *
* has no Windows equivalent). If the file is not a special, it is assigned a   *
* local handle from the handles table, which maps directly to a system file    *
* handle. If the handle is a special, it will not need special processing      *
* after it is opened.                                                          *
*                                                                              *
* EOF checking is a special problem under WIN 95, or any system using the      *
* C/Unix low level interface conventions. The only way this interface can      *
* find if EOF has been encountered is to run into it during a read (since      *
* writes will automatically extend the EOF). So what we do is keep a single    *
* byte buffer. When EOF is checked, the buffer is read, and at the same time   *
* we know if EOF is true. You might think of that read call as "check eof",    *
* with the side effect of reading the next byte. Then, the other routines      *
* compensate for having a possible buffered byte.                              *
*                                                                              *
* At the present, no really extensive error information is received from the   *
* OS. The errors mostly tell what was being attempted when the error           *
* occurred. More comprehensive error reporting should be added as time         *
* permits.                                                                     *
*                                                                              *
* The list file is presently unimplemented.                                    *
*                                                                              *
* 2001/3 [sam] Converted to "override" use. Each entry is preceded with "_",   *
* then the real entry exists in the sysovr.asm module.                         *
* We override "circularly", that is, there are calls to routines in this       *
* module that could be themselves overriden. This allows, for example, the     *
* error printout function to be overriden, but is a very dangerous ability.    *
*                                                                              *
* 2001/3 [sam] Windows has problems with the console buffer in that if you     *
* don't read a complete line, you get the remaining input in another program   *
* (!). The fix is to allways read lines by buffering locally here. The         *
* buffering does not have to be intelligent, since windows does that.          *
*                                                                              *
* 2004/3 [sam] Added code to automatically delete temp files on close so they  *
* don't accumulate.                                                            *
*                                                                              *
* 2008/4 [sam] Added multithreading calls.                                     *
*                                                                              *
* 2008/6 [sam] Added sysfil call to support system file aliasing.              *
*                                                                              *
*******************************************************************************}

module syslib;

uses stddef,  { some standard defines }
     windows, { system calls wrappers }
     gettgp,  { converts fixed array to pointer }
     sysovr;  { our override module }

{ external interface }

{ Block 1: File I/O }

procedure ss__alias(fn, fa: ss_filhdl); forward;
procedure ss__resolve(view nm: string; var fs: pstring); forward;
function ss__sysfil(view nm: string): boolean; forward;
procedure ss__openread(var fn: ss_filhdl; view nm: string); forward;
procedure ss__openwrite(var fn: ss_filhdl; view nm: string); forward;
procedure ss__openupdate(var fn: ss_filhdl; view nm: string); forward;
procedure ss__close(fn: ss_filhdl); forward;
procedure ss__read(fn: ss_filhdl; var ba: bytarr); forward;
procedure ss__write(fn: ss_filhdl; view ba: bytarr); forward;
procedure ss__position(fn: ss_filhdl; p: integer); forward;
function ss__location(fn: ss_filhdl): integer; forward;
function ss__length(fn: ss_filhdl): integer; forward;
function ss__eof(fn: ss_filhdl): boolean; forward;
procedure ss__delete(view nm: string); forward;
procedure ss__change(view dn, sn: string); forward;
function ss__exists(view nm: string): boolean; forward;
function ss__alteol: boolean; forward;

{ Block 2: Storage management and general operations }

procedure ss__getspace(var bp: gbtptr; ln: integer); forward;
procedure ss__putspace(bp: gbtptr); forward;
procedure ss__wrterr(view es: string); forward;

{ Block 3: Multithreading }

procedure ss__newthread(addr: integer; var id: integer); forward;
procedure ss__killthread(id: integer); forward;
procedure ss__signal(var sid: integer); forward;
procedure ss__signalone(var sid: integer); forward;
procedure ss__wait(lid: integer; var sid: integer); forward;
procedure ss__newlock(var id: integer); forward;
procedure ss__displock(id: integer); forward;
procedure ss__lock(id: integer); forward;
procedure ss__unlock(id: integer); forward;

{ private section }

private

label 88, { abort module }
      99; { abort immediate }

const

   { standard file handles }
   inpfil = 1; { _input }
   outfil = 2; { _output }
   errfil = 3; { _error }
   lstfil = 4; { _list }
   cmdfil = 5; { _command }

   inplen = 200; { length of maximum input line }

type

   { file entry pointer }
   filptr = ^filrec;
   { file entry record }
   filrec = record

      hdl:  integer; { windows handle of file }
      buf:  byte;    { buffer for next byte in file }
      full: boolean; { buffer is full flag }
      tnam: pstring  { temp name (if file is temp) }

   end;
   { open mode }
   opnmod = (omopenread,    { open for read only }
             omopenwrite,   { open for write only }
             omopenupdate); { open for update }
   { lock entry pointer }
   lckptr = ^lckrec;
   lckrec = record

      free: boolean; { lock entry is free }
      lock: sc_critical_section { windows lock variable }

   end;
   { signal entry pointer }
   sigptr = ^sigrec;
   sigrec = record

      hdl: integer; { windows handle to signal (0 = not used) }
      req: integer { number of outstanding wait requests }

   end;
   { thread entry pointer }
   thdptr = ^thdrec;
   thdrec = record

      hdl:  integer; { windows handle to thread (0 = not used) }
      id:   integer  { windows thread id }

   end;
   { module errors }
   errcod = (eftbful,  { file table full }
             efnmtl,   { file name too long }
             eopnfil,  { file open fails }
             esize,    { file size fails }
             efilnop,  { file not open }
             eclsfil,  { file close fails }
             eread,    { file read fails }
             ewrite,   { file write fails }
             epos,     { file position fails }
             edel,     { file delete fails }
             echg,     { file name change fails }
             egetsp,   { dynamic space allocation fails }
             eputsp,   { dynamic space release fails }
             eneglen,  { cannot allocate negative length }
             efilopr,  { cannot perform operation on special file }
             ecmdltl,  { command line too long }
             eeof,     { read past eof }
             einvhdl,  { invalid handle }
             ezertrn,  { file transfer length is zero }
             esizpre,  { size is to large to return }
             efilzer,  { filename is empty }
             estdhdl,  { cannot open standard I/O file }
             etmpovf,  { temp files overflow }
             einvpos,  { invalid position }
             eipbovf,  { input buffer overflow }
             ethdful,  { thread table full }
             ethdstr,  { cannot start thread }
             einvthd,  { invalid thread handle }
             ethdstp,  { cannot stop thread }
             elckful,  { lock table full }
             einvlck,  { invalid lock handle }
             elckseq,  { lock sequence error }
             esigful,  { signal table full }
             enewsig,  { cannot create signal }
             einvsig,  { invalid signal handle }
             edelsig,  { cannot delete signal }
             esndsig,  { cannot send a signal }
             esigwat,  { error waiting for signal }
             esyserr); { system consistency error }

var

   opnfil: array [1..ss_maxhdl] of filptr; { open files table }
   erract: boolean; { error being processed }
   ofi:    1..ss_maxhdl; { index for files table }
   cmdptr: integer; { current command line position }
   cp:     pstring; { holds command line pointer }
   bytsav: gbtptr; { place to store single read byte }
   ccro:   boolean; { command line cr output }
   clfo:   boolean; { command line lf output }
   tmpcnt: integer; { temporary files counter }
   inpbuf: array [1..inplen] of byte; { standard input buffer }
   inpinx: 1..inplen; { index for that }
   inpend: 1..inplen; { end of it }
   inpful: boolean; { input buffer full flag }
   inpeof: boolean; { input file eof flag }
   trnchr: array [char] of byte; { character to ascii translation array }
   ti:     0..255; { translation table index }
   thdtab: array [1..ss_maxthd] of thdptr; { thread table }
   thi:    1..ss_maxthd; { index for thread table }
   lcktab: array [1..ss_maxlck] of lckptr; { lock table }
   lki:    1..ss_maxlck; { index for lock table }
   sigtab: array [1..ss_maxsig] of sigptr; { signal table }
   sgi:    1..ss_maxsig; { index for lock table }

{ ASCII value to internal character set convertion array }

fixed chrtrn: array [0..127] of char = array

   '\nul',  { 0   } '\soh',  { 1   } '\stx',  { 2   } '\etx',  { 3   }
   '\eot',  { 4   } '\enq',  { 5   } '\ack',  { 6   } '\bel',  { 7   }
   '\bs',   { 8   } '\ht',   { 9   } '\lf',   { 10  } '\vt',   { 11  }
   '\ff',   { 12  } '\cr',   { 13  } '\so',   { 14  } '\si',   { 15  }
   '\dle',  { 16  } '\dc1',  { 17  } '\dc2',  { 18  } '\dc3',  { 19  }
   '\dc4',  { 20  } '\nak',  { 21  } '\syn',  { 22  } '\etb',  { 23  }
   '\can',  { 24  } '\em',   { 25  } '\sub',  { 26  } '\esc',  { 27  }
   '\fs',   { 28  } '\gs',   { 29  } '\rs',   { 30  } '\us',   { 31  }
   ' ',     { 32  } '!',     { 33  } '"',     { 34  } '#',     { 35  }
   '$',     { 36  } '%',     { 37  } '&',     { 38  } '''',    { 39  }
   '(',     { 40  } ')',     { 41  } '*',     { 42  } '+',     { 43  }
   ',',     { 44  } '-',     { 45  } '.',     { 46  } '/',     { 47  }
   '0',     { 48  } '1',     { 49  } '2',     { 50  } '3',     { 51  }
   '4',     { 52  } '5',     { 53  } '6',     { 54  } '7',     { 55  }
   '8',     { 56  } '9',     { 57  } ':',     { 58  } ';',     { 59  }
   '<',     { 60  } '=',     { 61  } '>',     { 62  } '?',     { 63  }
   '@',     { 64  } 'A',     { 65  } 'B',     { 66  } 'C',     { 67  }
   'D',     { 68  } 'E',     { 69  } 'F',     { 70  } 'G',     { 71  }
   'H',     { 72  } 'I',     { 73  } 'J',     { 74  } 'K',     { 75  }
   'L',     { 76  } 'M',     { 77  } 'N',     { 78  } 'O',     { 79  }
   'P',     { 80  } 'Q',     { 81  } 'R',     { 82  } 'S',     { 83  }
   'T',     { 84  } 'U',     { 85  } 'V',     { 86  } 'W',     { 87  }
   'X',     { 88  } 'Y',     { 89  } 'Z',     { 90  } '[',     { 91  }
   '\\',    { 92  } ']',     { 93  } '^',     { 94  } '_',     { 95  }
   '`',     { 96  } 'a',     { 97  } 'b',     { 98  } 'c',     { 99  }
   'd',     { 100 } 'e',     { 101 } 'f',     { 102 } 'g',     { 103 }
   'h',     { 104 } 'i',     { 105 } 'j',     { 106 } 'k',     { 107 }
   'l',     { 108 } 'm',     { 109 } 'n',     { 110 } 'o',     { 111 }
   'p',     { 112 } 'q',     { 113 } 'r',     { 114 } 's',     { 115 }
   't',     { 116 } 'u',     { 117 } 'v',     { 118 } 'w',     { 119 }
   'x',     { 120 } 'y',     { 121 } 'z',     { 122 } '{',     { 123 }
   '|',     { 124 } '}',     { 125 } '~',     { 126 } '\del'   { 127 }

end;

{*******************************************************************************

Convert character to ASCII

Converts a character to an ASCII value. This is needed when the internal
characters are not ASCII. If the internal characters are ASCII, the translation
will be a no-op. Note that we don't handle ISO 646 or ISO 8859-1, which are the
ISO version of ASCII, and the Western European character sets (same as Windows)
respectively.

These kinds of convertions are required because the string fields in .sym files
are stored in ASCII.

Note that characters with values 128 or over are simply returned untranslated.

*******************************************************************************}

function chr2ascii(c: char): byte;

begin

   chr2ascii := trnchr[c] { return translated character }

end;

overload procedure chr2ascii(var s: string);

var i: integer;

begin

   for i := 1 to max(s) do s[i] := chr(chr2ascii(s[i]))

end;

{*******************************************************************************

Write error string

Gets a handle to the standard error output, and writes the given string to that
file. We assume that the output could be in the middle of a line, so a crlf
sequence is output both before and after the string.
If the standard error output handle is bad, then this probally means that we
are in graphical mode. In this case, the string is output to a dialog.
The message output should be complete, and the caller should not try to output
multiple lines of error messages.
This routine works as autonomusly as possible, because loops while trying
to process errors are bad. Higher level modules usually use this routine to
output errors for this reason.

*******************************************************************************}
 
procedure ss__wrterr(view es: string);

{ output the string to standard error }

procedure outstr(view es: string);

var r:   record { pointer type exchange }

            case boolean of

               false: (sp: pstring);
               true:  (bp: gbtptr)

            { end }

         end;
    fr:  integer; { function result }
    hdl: integer; { output file handle }

begin

   { get a handle to the standard error output }
   hdl := sc_getstdhandle(sc_std_error_handle);
   new(r.sp, max(es)); { get a string buffer }
   r.sp^ := es; { place string in it }
   chr2ascii(r.sp^); { translate to ASCII }
   { write the error string. it does not matter if an error occurs, we cannot
     do anything about it anyways }
   fr := sc__lwrite(hdl, r.bp^);
   dispose(r.sp) { release string }

end;

begin { ss_wrterr }

   outstr('\cr\lf*** Runtime error: ');
   outstr(es);
   outstr('\cr\lf')

end;

{*******************************************************************************

Print error

Prints the given error in ASCII text, then aborts the program.

*******************************************************************************}
 
procedure error(e: errcod);

procedure putstr(view s: string);

var i:     integer; { index for string }
    pream: packed array [1..8] of char; { preamble string }
    p:     pstring; { pointer to string }

begin

   pream := 'Syslib: '; { set preamble }
   new(p, max(s)+8); { get string to hold }
   for i := 1 to 8 do p^[i] := pream[i]; { copy preamble }
   for i := 1 to max(s) do p^[i+8] := s[i]; { copy string }
   ss_wrterr(p^); { output string }
   dispose(p) { release storage }

end;

begin

   { if error is already active, this is a double fault. we exit immediately }
   if erract then goto 99; { immediate exit }
   erract := true; { set error being processed }
   case e of { error }

      eftbful: putstr('File table full');
      efnmtl:  putstr('File name too long');
      eopnfil: putstr('File open fails');
      esize:   putstr('File size fails');
      efilnop: putstr('File not open');
      eclsfil: putstr('File close fails');
      eread:   putstr('File read fails');
      ewrite:  putstr('File write fails');
      epos:    putstr('File position fails');
      edel:    putstr('File delete fails');
      echg:    putstr('File name change fails');
      egetsp:  putstr('Dynamic space allocation fails');
      eputsp:  putstr('Dynamic space release fails');
      eneglen: putstr('Allocation length is negative');
      efilopr: putstr('Cannot perform operation on special file');
      ecmdltl: putstr('Command line too long');
      eeof:    putstr('Read past EOF');
      einvhdl: putstr('Invalid handle');
      efilzer: putstr('Filename is empty');
      ezertrn: putstr('File transfer length is zero');
      esizpre: putstr('File size is to large to return');
      estdhdl: putstr('cannot open standard I/O file');
      etmpovf: putstr('Too many temporary files');
      einvpos: putstr('Invalid position');
      eipbovf: putstr('Standard input buffer overflow');
      ethdful: putstr('Thread table full');
      ethdstr: putstr('Cannot start thread');
      einvthd: putstr('Invalid thread handle');
      ethdstp: putstr('Cannot stop thread');
      elckful: putstr('lock table full');
      einvlck: putstr('invalid lock handle');
      elckseq: putstr('Unbalanced lock/unlock sequence');
      esigful: putstr('Signal table full');
      enewsig: putstr('Cannot create signal');
      einvsig: putstr('Invalid signal handle');
      edelsig: putstr('Cannot delete signal');
      esndsig: putstr('Cannot send a signal');
      esigwat: putstr('Error waiting for signal');
      esyserr: putstr('System consistency error');

   end;
   goto 88 { abort module }

end;

{*******************************************************************************

Make file entry

Indexes a present file entry or creates a new one. If an entry exists in the
table, and is closed, we return that. Otherwise, we look for completely empty
slots, and if found, the slot is allocated, and that returned. If there are
no empty slots, the table is full. Returns the logical number of the file
entry.
Note that the "predefined" file slots are never allocated.

*******************************************************************************}

procedure makfil(var fn: ss_filhdl); { file handle }

var fi: 1..ss_maxhdl; { index for files table }
    ff: 0..ss_maxhdl; { found file entry }
    
begin

   { find idle file slot (file with closed file entry) }
   ff := 0; { clear found file }
   for fi := cmdfil+1 to ss_maxhdl do if opnfil[fi] <> nil then 
      if opnfil[fi]^.hdl = -1 then ff := fi;
   if ff = 0 then begin { no idle slots found }

      { find empty file slot }
      ff := 0; { clear found file }
      for fi := cmdfil+1 to ss_maxhdl do if opnfil[fi] = nil then ff := fi;
      if ff = 0 then error(eftbful); { file table full }
      new(opnfil[ff]); { create a new file entry }
      with opnfil[ff]^ do begin { initalize entry }

         hdl := -1; { set is closed }
         buf := 0; { clear buffer }
         full := false;
         tnam := nil { set no temp name }

      end

   end;
   fn := ff { set file id number }

end;

{*******************************************************************************

Check null string

Checks if the given string contains nothing or only spaces.

*******************************************************************************}

function chknul(view nm: string) { string to check }
                : boolean;       { null status }

var i: integer; { string indexes }
    n: boolean; { null string status }

begin

   n := true; { set string is null }
   { check any character is non-space }
   for i := 1 to max(nm) do if nm[i] <> ' ' then n := false; { not null }
   chknul := n { return status }

end;

{*******************************************************************************

Remove leading and trailing spaces

Given a string, removes any leading and trailing spaces in the string. The
result is allocated and returned as an indexed buffer.
The input string must not be null.

*******************************************************************************}

procedure remspc(view nm: string;   { string }
                 var  rs: pstring); { result string }

var i1, i2: integer; { string indexes }
    n:      boolean; { string is null }
    s, e:   integer; { string start and end }

begin

   { first check if the string is empty or null }
   n := true; { set empty }
   for i1 := 1 to max(nm) do if nm[i1] <> ' ' then
      n := false; { set not empty }
   if n then error(efilzer); { filename is empty }
   s := 1; { set start of string }
   while (s < max(nm)) and (nm[s] = ' ') do s := s+1;
   e := max(nm); { set end of string }
   while (e > 1) and (nm[e] = ' ') do e := e-1;
   new(rs, e-s+1); { allocate result string }
   i2 := 1; { set 1st character of destination }
   for i1 := s to e do begin { copy to result }

      rs^[i2] := nm[i1]; { copy to result }
      i2 := i2+1 { next character }

   end

end;

{*******************************************************************************

Check system special file

Checks for one of the special files, and returns the handle of the special
file if found, otherwise returns 0. Accepts a general string.

*******************************************************************************}

function chksys(var fn: string) { file to check }
                : ss_filhdl;    { special file handle }

var hdl: ss_filhdl; { handle holder }

{ match strings }

function chkstr(view s: string): boolean;

var m: boolean; { match status }
    i: integer; { index for string }

{ find lower case }

function lcase(c: char): char;

begin

   { find lower case equivalent }
   if c in ['A'..'Z'] then c := chr(ord(c) - ord('A') + ord('a'));
   lcase := c { return as result }

end;

begin

   m := false; { set no match }
   if max(s) = max(fn) then begin { lengths match }

      m := true; { set strings match }
      for i := 1 to max(s) do if lcase(fn[i]) <> lcase(s[i]) then m := false

   end;
   chkstr := m { return match status }

end;

begin

   hdl := 0; { set not a special file }
   if chkstr('_input') then hdl := inpfil { check standard input }
   else if chkstr('_output') then hdl := outfil { check standard output }
   else if chkstr('_error') then hdl := errfil { check standard error }
   else if chkstr('_list') then hdl := lstfil { check list file }
   else if chkstr('_command') then hdl := cmdfil; { check command file }
   chksys := hdl { return handle }

end;

{*******************************************************************************

Create temporary filename

"coins" a temporary file name. We use an incrementing counter to create temp
files. That count, up to 9999, is placed into the filename. If the temp files
are occupied, we just keep incrementing till we find a good one. Temp files
should be cleaned out of the directory on exit.
The format of a temp name is:

   sys_0001.tmp

*******************************************************************************}

procedure temp(var nm: pstring);

begin

   new(nm, 12); { create temp string }
   nm^ := 'sys_0000.tmp'; { set skeletal filename }
   repeat { until free temp found }

      nm^[5] := chr(tmpcnt div 1000+ord('0')); { place digits }
      nm^[6] := chr(tmpcnt div 100 mod 10+ord('0'));
      nm^[7] := chr(tmpcnt div 10 mod 10+ord('0'));
      nm^[8] := chr(tmpcnt mod 10+ord('0'));
      tmpcnt := tmpcnt+1; { next temp file number }
      if tmpcnt > 999 then error(etmpovf) { temps overflow }
   
   until not ss_exists(nm^)

end;

{*******************************************************************************

Check next command line character

Returns the next command line character, or space if past the end.

*******************************************************************************}

function chkcmd: char; { returns next character }

var c: char; { character holder }

begin

   { check past end of line }
   if cmdptr <= max(cp^) then c := cp^[cmdptr] { return next character }
   else c := ' '; { return space for eoln }
   chkcmd := c { return character }

end;

{*******************************************************************************

Create command parameter file

Creates a command parameter file by first skipping spaces in the command line,
then reading any non-space characters in the command line as the file
parameter. It is an error if there are no such characters. No attempt is made
to verify if the filename is correct.
The spaces after the parameter are also skipped to keep returns clean.

*******************************************************************************}

procedure cmdpar(var nm: pstring);

var cmdsav: integer; { current position save }
    i:      integer; { string index }

begin

   { skip spaces in command line }
   while (chkcmd = ' ') and (cmdptr <= max(cp^)) do cmdptr := cmdptr+1;
   cmdsav := cmdptr; { save position for 1st pass }
   { measure length first }
   i := 0; { clear length }
   while (chkcmd <> ' ') and (cmdptr <= max(cp^)) do begin

      i := i+1; { count characters }
      cmdptr := cmdptr+1 { next character }

   end;
   new(nm, i); { create string for that }
   cmdptr := cmdsav; { restore position }
   { transfer command parameter }
   i := 1; { set 1st character }
   while (chkcmd <> ' ') and (cmdptr <= max(cp^)) do begin

      nm^[i] := cp^[cmdptr]; { place character }
      i := i+1; { next character }
      cmdptr := cmdptr+1 { next character }

   end;
   { skip spaces in command line to clean up end }
   while (chkcmd = ' ') and (cmdptr <= max(cp^)) do cmdptr := cmdptr+1

end;

{*******************************************************************************

Load input file buffer

Loads the standard input file single byte buffer. If EOF is encountered, the
eof flag is set and the buffer is undefined.

*******************************************************************************}

procedure loadinp(var e: boolean);

var rc: integer; { return code }

begin

   with opnfil[inpfil]^ do begin { process file }

      if not full then begin { if there is not already buffer content }

         { read a character }
         rc := sc__lread(hdl, bytsav^); { get a single input character }
         if rc < 0 then error(eread); { file read error }
         if rc < 1 then e := true { EOF encountered }
         else begin

            buf := bytsav^[1]; { place } 
            full := true { flag buffer content }

         end
         
      end

   end

end;

{*******************************************************************************

Fill _input file buffer

If the input buffer is empty, and there is no EOF, a new buffer is loaded, and
the EOF flag set appropriately.

*******************************************************************************}

procedure fillinp;

var b: byte;    { byte buffer }
    e: boolean; { eof flag }

procedure plcchr(b: byte); { place character in buffer }

begin

   inpbuf[inpend] := b; { place character }
   inpend := inpend+1;
   if inpend = inplen then error(eipbovf) { line too long }
   
end;

begin

   if not inpeof and not inpful then begin { no eof, and buffer empty }

      with opnfil[inpfil]^ do begin { process file }

         inpend := 1; { set 1st character of buffer }
         repeat { load buffer characters }

            loadinp(e); { load up the next character }
            if not e then begin { place character }

               b := buf; { get character }
               plcchr(buf); { place } 
               full := false { remove buffer character }

            end

         { stop on either cr, lf or eof }
         until (b = ord('\lf')) or (b = ord('\cr')) or e;
         if e and (inpend = 1) then inpeof := true { empty line, set eof }
         { now we have either a partial crlf, or none because of EOF }
         else if e then begin { no crlf, make one }

            plcchr(ord('\lf'));
            plcchr(ord('\cr'))
            { note that EOF is not set until this buffer gets emptied }

         end else if b = ord('\lf') then begin

            plcchr(ord('\cr')); { place matching }
            loadinp(e); { load the next character }
            { if a matching cr is found, discard }
            if buf = ord('\cr') then full := false

         end else begin

            plcchr(ord('\lf')); { place matching }
            loadinp(e); { load the next character }
            { if a matching lf is found, discard }
            if buf = ord('\lf') then full := false

         end;
         inpinx := 1; { set 1st character of buffer }
         inpful := true { set buffer full }

      end

   end

end;

{*******************************************************************************

Read byte from _input file

Gets a single byte from the _input file via buffering. If the buffer is empty,
then it is filled with an entire line from the input. The read is then
satisfied by a single read from the buffer. The EOF flag is set if an EOF is
encountered during the read.

*******************************************************************************}

procedure readinp(var b: byte);

begin

   fillinp; { make sure that input buffer is full }
   if not inpeof then begin { get next next character }

      b := inpbuf[inpinx]; { get next bufer character }
      inpinx := inpinx+1; { next character }
      if inpinx = inpend then inpful := false { if end of line, reset buffer }

   end

end;

{*******************************************************************************

Alias file handle

Create an alias between an alias file handle, and a syslib level file handle.
This is a no-op in syslib. It solves the issue in overload stacks that we don't
know what top level file number corresponds with the low level I/O numbers
here in syslib, which you need to know if you are also going to accept top
level calls.

*******************************************************************************}

procedure ss__alias(fn, fa: ss_filhdl);

begin

   refer(fn, fa) { this is a no-op here }

end;

{*******************************************************************************

Resolve filename

Resolves parameter files.

Because the command parameter file naming system is order dependent, it can
be a problem to call opens in any order, since the caller might get the wrong
parameter. To fix this, this routine is called to replace the parameter name
with its resolved name from the command line, in order.

This routine could be used to resolve any other order dependencies. The temp
files are not resolved here because they are not order dependent.

*******************************************************************************}

procedure ss__resolve(view nm: string; var fs: pstring);

var fn: ss_filhdl; { file handle }

begin

   remspc(nm, fs); { remove leading and trailing spaces }
   fn := chksys(fs^); { check it's a system file }
   { if it's not a system file, but still has a "_" prepended, then it must
     be a command parameter file }
   if (fn = 0) and (fs^[1] = '_') then cmdpar(fs) { create parameter file }
   else begin { just copy filename to string }

      new(fs, max(nm)); { create filename string }
      fs^ := nm { place filename }

   end

end;

{*******************************************************************************

Check system file

Checks if the filename given belongs to the set of system, or device, files.
This is one of:

_input
_output
_error
_list
_command

The caller may need to know if it is accessing a system file. For example, the
system files are usually aliased to the same file tracking entry, so that the
state flags that control eof checking and other modes track across multiple
references to the device file.

*******************************************************************************}

function ss__sysfil(view nm: string): boolean;

var fs: pstring; { string holder }
    fn: ss_filhdl; { file handle }

begin

   remspc(nm, fs); { remove leading and trailing spaces }
   fn := chksys(fs^); { check it's a system file }
   dispose(fs); { release string }

   ss__sysfil := fn <> 0 { return found status }

end;

{*******************************************************************************

Open file for reading and writing

Opens the given file by name, types it as read/write, and returns the file
handle. If the file is a system special file, we simply return the predefined
handle to that, since the special files are already all set up, and remain
so for the duration of the program run.

Clears the file parameters.

*******************************************************************************}

procedure open(var  fn:   ss_filhdl; { file handle }
               view nm:   string;   { file string }
                    mode: opnmod); { open mode }

var fs, ts: pstring; { filename buffer pointer }

begin 

   ts := nil; { clear temp filename }
   if chknul(nm) then begin { temp file }

      temp(fs); { create temp file name }
      new(ts, max(fs^)); { create a copy of the temp }
      ts^ := fs^;
      fn := 0 { set formal file }

   end else begin { all others }

      remspc(nm, fs); { remove leading and trailing spaces }
      fn := chksys(fs^); { check it's a system file }
      { if it's not a system file, but still has a "_" prepended, then it must
        be a command parameter file }
      if (fn = 0) and (fs^[1] = '_') then cmdpar(fs) { create parameter file }

   end;
   if fn = 0 then begin { open formal file }

      makfil(fn); { create new file slot }
      with opnfil[fn]^ do begin { process file }

         { open file using mode }
         case mode of { open mode }

            omopenread:   hdl := sc__lopen(fs^, sc_of_read);
            omopenwrite:  hdl := sc__lcreat(fs^, 0);
            omopenupdate: hdl := sc__lopen(fs^, sc_of_write);
       
         end;
         dispose(fs); { release buffer }
         if hdl < 0 then error(eopnfil); { open did not work, process error }
         buf := 0; { clear buffer }
         full := false;
         tnam := ts { place any temp filename }

      end

   end else dispose(fs) { release buffer }

end;

{*******************************************************************************

Open file for reading

Opens the given file by name, types it as read only, and returns the file
handle. If the file is a system special file, we simply return the predefined
handle to that, since the special files are already all set up, and remain
so for the duration of the program run.
Clears the file parameters.

*******************************************************************************}

procedure ss__openread(var  fn: ss_filhdl; { file handle }
                      view nm: string);   { file string }

begin

   open(fn, nm, omopenread) { process open }

end;

{*******************************************************************************

Open file for writing

Opens the given file by name, types it as write only, and returns the file
handle. If the file is a system special file, we simply return the predefined
handle to that, since the special files are already all set up, and remain
so for the duration of the program run.
Clears the file parameters.

*******************************************************************************}

procedure ss__openwrite(var  fn: ss_filhdl; { file handle }
                       view nm: string);   { file string }

begin

   open(fn, nm, omopenwrite) { process open }

end;

{*******************************************************************************

Open file for update

Opens the given file by name, types it as write only, and returns the file
handle. If the file is a system special file, we simply return the predefined
handle to that, since the special files are already all set up, and remain
so for the duration of the program run.

Clears the file parameters.

*******************************************************************************}

procedure ss__openupdate(var  fn: ss_filhdl; { file handle }
                         view nm: string);   { file string }

begin

   open(fn, nm, omopenupdate) { process open }

end;

{*******************************************************************************

Close file

Closes the file. System special files are left alone, since they are open for
the duration of the program. Temp files are both closed and deleted.

*******************************************************************************}

procedure ss__close(fn: ss_filhdl); { file handle }

var r: boolean; { function result }
    e: integer; { extended error code }

begin

   if (fn < 1) or (fn > ss_maxhdl) then error(einvhdl); { invalid handle }
   if fn > cmdfil then begin { file is not a special file }

      if opnfil[fn] = nil then error(einvhdl); { invalid handle }
      with opnfil[fn]^ do begin { process file }

         if hdl = -1 then error(efilnop); { file not open }
         if fn > cmdfil then begin { not a special file }

            if sc__lclose(hdl) <> 0 then error(eclsfil); { bad file close }
            if tnam <> nil then begin { close temporary file }

               r := sc_deletefile(tnam^); { delete file }
               if not r then begin { error }
              
                  e := sc_getlasterror; { get the last error code }
                  if e <> sc_error_file_not_found then 
                     error(edel) { delete error }
              
               end;
               dispose(tnam) { release filename string }

            end

         end;
         hdl := -1 { set file closed }

      end

   end

end;

{*******************************************************************************

Read file

Transfers the specified number of bytes to the address.
If the file is the command file, then characters are read from the command
line, and the line pointer advanced. Note that no matter how many references
(open files) exist to the command file, they all use the same position pointer,
so the command line can only be read once.

Otherwise, a normal file read is processed. If the buffer is full, that is
transferred to the destination. Then, the remaining bytes are processed via
a system read call.

If the file is the standard input, then characters are read in terms of lines,
including the carriage return and line feed. Then, the read is parceled out
in terms of that.

*******************************************************************************}

procedure ss__read(    fn: ss_filhdl; { file handle }
                   var ba: bytarr);   { block to read to }

var i:  integer; { index for destination }
    l:  integer; { length left on destination }
    b:  byte;    { single byte buffer }
    rc: integer; { return code }
    r:  record { pointer fiddling }

           case boolean of

              false: (a: integer;  { address }
                      l: integer); { length }
              true:  (p: gbtptr)   { block pointer }

           { end }

        end;

begin

   if (fn < 1) or (fn > ss_maxhdl) then error(einvhdl); { invalid handle }
   i := 1; { set 1st byte of destination }
   l := max(ba); { set length of destination }
   if fn = cmdfil then begin { process command file read }

      { For encoded mode with the command file, we have to re-encode the
        characters before sending them on to the caller. The reason for this
        is that file I/O is expected to be unencoded, yet we got the command
        line already encoded. }
      while l > 0 do begin { read command bytes }

         if cmdptr > max(cp^) then begin { end of line }

            if ccro and clfo then error(eeof); { read past eof }
            if not ccro then begin { output cr }

               ba[i] := chr2ascii('\cr'); { place cr }
               i := i+1; { next byte }
               ccro := true { set cr output }

            end else begin { output lf }

               { place lf }
               ba[i] := chr2ascii('\lf'); { place lf }
               i := i+1; { next byte }
               clfo := true { set lf output }

            end

         end else begin

            ba[i] := chr2ascii(cp^[cmdptr]); { read and place byte }
            i := i+1; { next byte }
            cmdptr := cmdptr+1 { next character }

         end;
         l := l-1 { count }

      end
      
   end else if fn = inpfil then begin { standard input read }

      if opnfil[fn] = nil then error(einvhdl); { invalid handle }
      while l <> 0 do begin { until read length is satisfied }

         readinp(b); { get next buffered input char }
         if inpeof then error(eeof); { EOF encountered }
         ba[i] := b; { place }
         i := i+1; { next byte }
         l := l-1 { count }

      end

   end else begin { normal file }   

      if opnfil[fn] = nil then error(einvhdl); { invalid handle }
      with opnfil[fn]^ do begin { process file }

         if hdl = -1 then error(efilnop); { file not open }
         if l = 0 then error(ezertrn); { file read is zero }
         if full then begin { there is data in the buffer, transfer that }

            ba[i] := buf; { place buffer byte }
            i := i+1; { next byte }
            l := l-1; { count }
            full := false; { set buffer empty }
            { now, since we may have advanced in the buffer, we need to
              construct a new pointer from our index and length }
            r.p := rettgp(ba); { place block in "flex" record }
            r.a := r.a+i-1; { update index }
            r.l := l; { update length }
            if max(r.p^) <> 0 then begin { there are more bytes to transfer }

               rc := sc__lread(hdl, r.p^); { execute read }
               if rc < 0 then error(eread); { file read error }
               if rc < max(r.p^) then error(eeof) { EOF encountered }

            end

         end else { normal data read }
            if max(ba) <> 0 then begin { there are more bytes to transfer }

            { execute read }
            rc := sc__lread(hdl, ba); { file read error }
            if rc < 0 then error(eread); { file read error }
            if rc < max(ba) then error(eeof) { EOF encountered }

         end

      end

   end

end;

{*******************************************************************************

Write file

Transfers the specified number of bytes from the address. Refuses to write to
the command file.
If the buffer is full (from an EOF check), then we must back up the position
before the write takes place. This is a potential time hit, but note that
there is virtually no reason to perform reapeated EOF checks while writing
the file, since the EOF is immaterial to a write.

*******************************************************************************}

procedure ss__write(     fn: ss_filhdl; { file handle }
                   view ba: bytarr);   { address to write to }

begin

   if (fn < 1) or (fn > ss_maxhdl) then error(einvhdl); { invalid handle }
   if (fn = cmdfil) or (fn = inpfil) then
      error(efilopr); { cannot write to command or input file }
   if opnfil[fn] = nil then error(einvhdl); { invalid handle }
   with opnfil[fn]^ do begin { process file }

      if hdl = -1 then error(efilnop); { file not open }
      if max(ba) = 0 then error(ezertrn); { file write is zero }
      if full then begin

         { buffer is full, we must elimnate this condition by backing up }
         if sc__llseek(hdl, -1, 1) < 0 then
            error(epos); { file position error }
         full := false { clear buffer }

      end;
      { execute write }
      if sc__lwrite(hdl, ba) = -1 then error(ewrite) { file write error }

   end

end;

{*******************************************************************************

Position file

Moves the read/write position to the specified location. Having done this,
any buffered byte is simply discarded.

*******************************************************************************}

procedure ss__position(fn: ss_filhdl; { file handle }
                      p:  integer);  { position }

begin

   if (fn < 1) or (fn > ss_maxhdl) then error(einvhdl); { invalid handle }
   if (fn = cmdfil) or (fn = inpfil) then
      error(efilopr); { cannot position command or input file }
   if opnfil[fn] = nil then error(einvhdl); { invalid handle }
   if p < 1 then error(einvpos); { invalid position }
   with opnfil[fn]^ do begin { process file }

      if hdl = -1 then error(efilnop); { file not open }
      if fn = cmdfil then error(efilopr); { file operation }
      { position file }
      if sc__llseek(hdl, p-1, 0) = -1 then error(epos); { file position error }
      full := false { set no byte buffered }

   end
  
end;

{*******************************************************************************

Find location of file

Returns the current read/write location of the file. This is done by exploting
the fact that the seek call returns the resulting position. We perform a null
seek, and use the result. If the buffer is full, the location returned by
Win 95 must be adjusted.

*******************************************************************************}

function ss__location(fn: ss_filhdl) { file handle }
                     : integer;     { location return }

var loc: integer; { location holder }

begin

   if (fn < 1) or (fn > ss_maxhdl) then error(einvhdl); { invalid handle }
   if (fn = cmdfil) or (fn = inpfil) then
      error(efilopr); { cannot locate command or input file }
   if opnfil[fn] = nil then error(einvhdl); { invalid handle }
   with opnfil[fn]^ do begin { process file }

      if hdl = -1 then error(efilnop); { file not open }
      if fn <= cmdfil then error(efilopr); { file operation }
      loc := sc__llseek(hdl, 0, 1); { find file location }
      if loc < 0 then error(epos); { file position error }
      { if the buffer is full, then the position read will be one past the
        actual position }
      if full then loc := loc-1;
      ss__location := loc+1 { return file location }

   end

end;

{*******************************************************************************

Find length of file

Returns the current length of the file.

*******************************************************************************}

function ss__length(fn: ss_filhdl) { file handle }
                   : integer;     { location return }

var len:  integer; { file size holder }
    up32: integer; { upper 32 bits of length }

begin

   if (fn < 1) or (fn > ss_maxhdl) then error(einvhdl); { invalid handle }
   if (fn = cmdfil) or (fn = inpfil) then
      error(efilopr); { cannot size command or input file }
   if opnfil[fn] = nil then error(einvhdl); { invalid handle }
   with opnfil[fn]^ do begin { process file }

      if hdl = -1 then error(efilnop); { file not open }
      if fn <= cmdfil then error(efilopr); { file operation }
      len := sc_getfilesize(hdl, up32); { get length of file }
      if len < 0 then error(esize); { file size error }
      if up32 <> 0 then error(esizpre); { size is > 32 bits }
      ss__length := len { return file location }

   end

end;

{*******************************************************************************

Check file at EOF

Returns the EOF status of the file. If the file is the command file, we simply
look for the zero termination of that string. Otherwise, we read one byte
ahead and place that in the buffer. If the read did not work because of EOF
encounter, we return true and the buffer remains empty. The buffer full flag,
then, serves as a "not eof" flag for repeated eof status calls.

*******************************************************************************}

function ss__eof(fn: ss_filhdl) { file handle }
                : boolean;     { eof return }

var ef: boolean; { eof status }
    len: integer; { read length holder }
    

begin

   if (fn < 1) or (fn > ss_maxhdl) then error(einvhdl); { invalid handle }
   { set status in case of command line }
   if fn = cmdfil then ef := (cmdptr > max(cp^)) and ccro and clfo
   else if fn = inpfil then begin { standard input read }

      fillinp; { make sure input buffer is full }
      ef := inpeof { set eof status }

   end else begin { normal file }

      if opnfil[fn] = nil then error(einvhdl); { invalid handle }
      with opnfil[fn]^ do begin { process file }

         if hdl = -1 then error(efilnop); { file not open }
         if not full then begin { buffer is not already full }

            { read ahead one byte in file to determine eof status }
            len := sc__lread(hdl, bytsav^);
            if len < 0 then error(eread); { file read error }
            if len = 1 then begin { read worked }

               buf := bytsav^[1]; { place read byte in buffer }
               full := true { set buffer full }

            end

         end;
         ef := not full { if no byte in buffer, then eof is true }

      end

   end;
   ss__eof := ef { return status }

end;

{*******************************************************************************

Delete file

Deletes the given file by name.

*******************************************************************************}

procedure ss__delete(view nm: string); { file string }

var fs: pstring; { filename buffer pointer }
    r:  boolean; { function result }
    e:  integer; { extended error code }

begin

   remspc(nm, fs); { remove leading and trailing spaces }
   r := sc_deletefile(fs^); { process delete }
   dispose(fs); { release buffer }
   if not r then begin { error }

      e := sc_getlasterror; { get the last error code }
      if e <> sc_error_file_not_found then error(edel) { delete error }

   end

end;

{*******************************************************************************

Change filename

Changes the source filename to the destination filename. The destination
filename should not have a path specification on it.

*******************************************************************************}

procedure ss__change(view dn: string;  { destination filename }
                     view sn: string); { source filename }

var ds, ss: pstring; { filename buffer pointers }
    r:      boolean; { function result }

begin

   remspc(dn, ds); { remove leading spaces }
   remspc(sn, ss);
   r := sc_movefile(ss^, ds^); { process change }
   dispose(ds); { release buffers }
   dispose(ss);
   if not r then error(echg); { change error }

end;

{*******************************************************************************

Check file exists

Returns true if the given file exists. We cheat a little, and return exists
true if the file can be opened without error. This could deliver a negative
answer that is not because the file does not exist.

*******************************************************************************}

function ss__exists(view nm: string) { filename }
                   : boolean;       { exists status }

var fs: pstring; { filename buffer pointer }
    rv: integer; { return value }

begin

   remspc(nm, fs); { remove leading spaces }
   { open existing file in read mode }
   rv := sc__lopen(fs^, sc_of_read);
   dispose(fs); { release buffer }
   if rv >= 0 then { found it, close that file }
      if sc__lclose(rv) <> 0 then error(eclsfil); { bad file close }
   ss__exists := rv >= 0 { return exists status }

end;

{*******************************************************************************

Get heap space

Allocates the requested length block of storage, and returns the address.

Produces an error if the length is negative. Zero length is actually ok, its
possible to have a zero length item like a null length array.

*******************************************************************************}

procedure ss__getspace(var bp: gbtptr;   { block pointer }
                           ln: integer); { length of block }

begin

   if ln < 0 then error(eneglen); { negative length }
   { allocate memory from the global heap, in fixed block mode, cleared }
   bp := sc_globalalloc(sc_gmem_fixed or sc_gmem_zeroinit, ln);
   if bp = nil then error(egetsp) { getspace failed }

end;

{*******************************************************************************

Put heap space

Releases the indicated storage block to free space.

*******************************************************************************}

procedure ss__putspace(bp: gbtptr); { block address }

var hdl: integer; { handle }

begin

   hdl := sc_globalfree(bp); { process free }
   if hdl <> 0 then error(eputsp) { putspace failed }
 
end;

{*******************************************************************************

Check alternate EOL

Checks if the alternate end of line is in use, or \lf only (no \cr). Unix
uses alternate end of lines.

*******************************************************************************}

function ss__alteol: boolean;

begin

   ss__alteol := false { don't return alternate EOLs }

end;

{*******************************************************************************

Start new thread

Starts a new thread. The address the thread is to run at is specified, and the
location of an integer to place the thread id that is generated. The thread
is started, then the thread id is placed for the caller.

Note that the thread ids are numbered from 1 to N, and that thread 1 is always
reserved for the main thread.

*******************************************************************************}

procedure ss__newthread(addr: integer; var id: integer);

var i:  1..ss_maxthd; { index for thread table }
    fi: 0..ss_maxthd; { found entry index }

begin

   { find open entry in the thread table }
   fi := 0; { set no entry found }
   { first look for open but free entry }
   for i := ss_maxthd downto 1 do 
      if thdtab[i] <> nil then if thdtab[i]^.hdl = 0 then fi := i;
   if fi = 0 then
      { now look for totally free entry }
      for i := ss_maxthd downto 1 do 
         if thdtab[i] = nil then fi := i;
   if fi = 0 then error(ethdful); { thread table full }

   if thdtab[fi] = nil then new(thdtab[fi]); { create new entry as needed }
   { Create windows thread with default security descriptor, stack size,
     flags, and no startup parameter. }
   thdtab[fi]^.hdl := sc_createthread(0, addr, 0, thdtab[fi]^.id);
   if thdtab[fi]^.hdl = 0 then error(ethdstr); { cannot start thread }

   id := fi { return logical thread id }

end;

{*******************************************************************************

Kill thread

Kills and removes the indicated thread. It is possible to kill oneself, in which
case the routine may not return. However, there are a lot of different
interpretations of what that means, especially in the multiprocessor case. It is
certainly possible that the deleted thread will continue even for a time after
being killed because of interprocessor signal latency.

*******************************************************************************}

procedure ss__killthread(id: integer);

var r: boolean;

begin

   { validate thread id number }
   if (id < 1) or (id > ss_maxthd) then error(einvthd);
   { validate table entry is open }
   if thdtab[id] = nil then error(einvthd);
   if thdtab[id]^.hdl = 0 then error(einvthd);

   { Kill the thread by handle. The error code is meaningless, but we give it
     a standard fail code -1. }
   r := sc_terminatethread(thdtab[id]^.hdl, -1);
   if not r then error(ethdstp); { cannot stop the thread }
   thdtab[id]^.hdl := 0 { set thread entry now unoccupied }

end;

{*******************************************************************************

Validate signal id

Checks the signal id given is valid. If the signal is 0, it means it has never
been used, and a new logical signal entry is created and placed. Otherwise, the
signal id is just validated.

*******************************************************************************}

procedure sigval(var id: integer);

var i:  1..ss_maxsig; { index for signal table }
    fi: 0..ss_maxsig; { found entry index }

begin

   { check id has ever been used }
   if id = 0 then begin { create new signal }

      { find open entry in the signal table }
      fi := 0; { set no entry found }
      { first look for open but free entry }
      for i := ss_maxsig downto 1 do 
         if sigtab[i] <> nil then if sigtab[i]^.hdl = 0 then fi := i;
      if fi = 0 then
         { now look for totally free entry }
         for i := ss_maxsig downto 1 do 
            if sigtab[i] = nil then fi := i;
      if fi = 0 then error(esigful); { thread table full }
     
      if sigtab[fi] = nil then new(sigtab[fi]); { create new entry as needed }
      { create event with manual reset, false initial state }
      sigtab[fi]^.hdl := sc_createevent(true, false);
      if sigtab[fi]^.hdl = 0 then error(enewsig); { cannot create signal }
      sigtab[fi]^.req := 0; { clear outstanding wait requests }

      id := fi { return signal logical id }

   end else begin { validate existing signal }

      { validate signal id number }
      if (id < 1) or (id > ss_maxsig) then error(einvsig);
      { validate table entry is open }
      if sigtab[id] = nil then error(einvsig);
      if sigtab[id]^.hdl = 0 then error(einvsig)

   end

end;

{*******************************************************************************

Flag signal

Flags a signal to all threads. Accepts the signal id. All threads have a logical
"copy" of the signal status, either not flagged (false), or flagged (true). When
a signal occurs, all threads have the signal status set true. Each thread will
check the status of its copy of the signal separately, and set the flag to "off"
after having checked it. Multiple signals without having checked it have no
effect for those threads that have the signal flag already set.

Note: uses pulseevent, which the Windows documents state has issues. Further,
a setevent/resetevent has the same issue (see MSDN article 173260). The
alternative the Windows documents give is to use a construct exclusive to Vista,
which is not at present a workable alternative, since Windows XP must be
supported.

The issue boils down to request/acknowledge pairing, and the code here satisfies
that. We signal, give the other thread a chance to run, then loop until our
request counts clear. This means that we will retry continually a 
non-functioning signal.

*******************************************************************************}

procedure ss__signal(var sid: integer); { signal id variable }

var r: boolean;

begin

   sigval(sid); { validate signal variable }
   { check any requesters are active }
   while sigtab[sid]^.req > 0 do begin 

      { Signal until the requests clear. This works because even though we still
        may hold locks, we allow the waiters to proceed to remove the request
        count and reassert their locks. }
      sc_sleep(0); { release other threads (see MSDN 173260) }
      r := sc_pulseevent(sigtab[sid]^.hdl); { flag signal }
      if not r then error(esndsig) { cannot send the signal }

   end

end;

{*******************************************************************************

Flag "one only" signal

This is the same as "signal", except that only the thread that has been waiting
the longest for the signal is flagged for the signal. This can be more efficent
than signaling all threads when only one thread can actually use the signal.
For example, a buffer not empty signal needs only one thread.

If there are no threads awaiting the signal, then the implementation can either
just flag all threads as per the signal call, or may implement a conditional
flag that is only given to the first thread that looks at the signal.

Note that it is possible that an implementation can just implement signalone
as a call to signal.

Note: For the Windows NT/XP version, we pulse the event then see if it cleared
one, then try again, etc. This is how it has to work to get around Windows
problems. However, the documentation implies that more than one thread could
be released via this method. This fits within the definition of this function
that allows the release of from 1 to N threads, where N is all threads waiting.

*******************************************************************************}

procedure ss__signalone(var sid: integer); { signal id variable }

var creq: integer; { current request count holding }
    r:    boolean; { function result }

begin

   sigval(sid); { validate signal variable }
   { check one requester }
   creq := sigtab[sid]^.req; { save current request number }
   if creq > 0 then begin

      creq := creq-1; { set minus one count }
      { check any requesters are active }
      while sigtab[sid]^.req > creq do begin 
      
         { Signal until the requests clear. This works because even though we 
           still may hold locks, we allow the waiters to proceed to remove the
           request count and reassert their locks. }
         sc_sleep(0); { release other threads (see MSDN 173260) }
         r := sc_pulseevent(sigtab[sid]^.hdl); { flag signal }
         if not r then error(esndsig) { cannot send the signal }
      
      end

   end

end;

{*******************************************************************************

Wait signal

Awaits the indicated signal by id. If the signal has already happened, then
the call returns immediately. If not, the current thread is suspended until the
signal occurs. The signal is always cleared on exit. Each thread effectively
has its own copy of the signal, an a signal will remain true for each thread
until waited on.

In IP Pascal, signals are not "garanteed", that is, there is no indication that
another thread might not have serviced the event assocated with the signal. This
applies even to the "signalone" call. For this reason, the caller must be ready
to check if the event is still active, and if necessary, loop calling wait until
an unserviced signal is found.

In addition, signal queues can be implemented either as "fair" (first come,
first serve), or "unfair", in which case the thread flagged is a random one.

*******************************************************************************}

procedure ss__wait(    lid: integer; { monitor lock id }
                   var sid: integer); { signal id variable }

var r: integer; { return variable }

begin

   sigval(sid); { validate signal variable }
   sigtab[sid]^.req := sigtab[sid]^.req+1; { add to outstanding requests }
   ss_unlock(lid); { release the monitor lock so we can be signaled }
   { process signal wait }
   r := sc_waitforsingleobject(sigtab[sid]^.hdl, -1); { wait for next event }
   if r = -1 then error(esigwat); { signal waiting error }
   { Remove outstanding request. Do this as quickly as possible after the
     wait, since the signaler is awaiting this. }
   sigtab[sid]^.req := sigtab[sid]^.req-1; { remove outstanding request }
   ss_lock(lid) { reassert the lock }

end;

{*******************************************************************************

Create lock

Creates a new critical section lock, and returns the id for the lock. Logical
lock ids are numbers from 1-N. IP Pascal garantees that at least 10 locks will
be available, but 100 locks or more are common.

*******************************************************************************}

procedure ss__newlock(var id: integer);

var i:  1..ss_maxlck; { index for lock table }
    fi: 0..ss_maxlck; { found entry index }

begin

   { find open entry in the lock table }
   fi := 0; { set no entry found }
   { first look for open but free entry }
   for i := ss_maxlck downto 1 do 
      if lcktab[i] <> nil then if lcktab[i]^.free then fi := i;
   if fi = 0 then
      { now look for totally free entry }
      for i := ss_maxlck downto 1 do 
         if lcktab[i] = nil then fi := i;
   if fi = 0 then error(elckful); { thread table full }

   if lcktab[fi] = nil then new(lcktab[fi]); { create new entry as needed }
   { set lock entry now occupied }
   lcktab[fi]^.free := false;
   { initialize the sequencer lock }
   sc_initializecriticalsection(lcktab[fi]^.lock);

   id := fi { return lgical thread id }

end;

{*******************************************************************************

Remove lock

Removes a lock by logical id. If any thread is awaiting in a lock, then an error
results. Removing the lock frees up its logical id for reuse.

*******************************************************************************}

procedure ss__displock(id: integer); 

begin

   { validate lock id number }
   if (id < 1) or (id > ss_maxlck) then error(einvlck);
   { validate table entry is open }
   if lcktab[id] = nil then error(einvlck);
   if lcktab[id]^.free then error(einvlck);

   { remove any resources held by critical section }
   sc_deletecriticalsection(lcktab[id]^.lock);
   lcktab[id]^.free := true { set lock entry now unoccupied }

end;

{*******************************************************************************

Lock critical section

Activates a critical section by logical id. If the lock is not active, it is
flagged active, and the thread continues. If the lock is active, then the
calling thread is suspended until it is. Typically, lock queuing is "fair", in
that the first to come to the lock is the first, in order, receive it. However,
this behavior is not garanteed.

Critical section locks have a number of features designed to resist deadlock.
If the same thread performs the same lock more than once, the lock request is
simply counted on lock, and decremented on unlock. When the lock count equals
zero, the unlock operation actually occurs. This covers the case where a thread
recursively executes the same locking routine, either directly or indirectly.

In addition, waiting for a signal while holding a lock causes the lock to be
freed while waiting for the signal, then the lock is reasserted when the signal
flags and the thread continues. Callers must, therefore, treat a "wait" call
as the sequence:

unlock
wait
lock

And watch for data change after the wait for signal.

*******************************************************************************}

procedure ss__lock(id: integer);

begin

   { validate lock id number }
   if (id < 1) or (id > ss_maxlck) then error(einvlck);
   { validate table entry is open }
   if lcktab[id] = nil then error(einvlck);
   if lcktab[id]^.free then error(einvlck);

   { enter the lock }
   sc_entercriticalsection(lcktab[id]^.lock)

end;

{*******************************************************************************

Unlock critical section

Frees up the lock for a critical section by logical id. If other threads are
waiting on the lock, they are scheduled to run, but the exact order is system
defined. They may be run in fair order, and they may run immediately
(presumably interrupting the current thread), or may be scheduled for later.

*******************************************************************************}

procedure ss__unlock(id: integer);

begin

   { validate lock id number }
   if (id < 1) or (id > ss_maxlck) then error(einvlck);
   { validate table entry is open }
   if lcktab[id] = nil then error(einvlck);
   if lcktab[id]^.free then error(einvlck);

   { exit the lock }
   sc_leavecriticalsection(lcktab[id]^.lock)

end;

{*******************************************************************************

Initalize module

*******************************************************************************}

begin

   { Form character to ASCII value translation array from ASCII value to 
     character translation array. }
   for ti := 1 to 255 do trnchr[chr(ti)] := 0; { null out array }
   for ti := 1 to 127 do trnchr[chrtrn[ti]] := ti; { form translation }
   { clear files table }
   for ofi := 1 to ss_maxhdl do opnfil[ofi] := nil; { clear files table }
   { clear threads table }
   for thi := 1 to ss_maxthd do thdtab[thi] := nil; { clear threads table }
   { place main thread entry }
   new(thdtab[1]); { get a new entry }
   { clear locks table }
   for lki := 1 to ss_maxlck do lcktab[lki] := nil;
   { clear signals table }
   for sgi := 1 to ss_maxsig do sigtab[sgi] := nil;
   { Note that although we can get a windows "handle" for the current process,
     the windows documents imply that it is not a true handle. }
   thdtab[1]^.hdl := sc_getcurrentthread; { place main thread handle }
   thdtab[1]^.id := sc_getcurrentthreadid; { place main thread id }
   erract := false; { set no error being processed }
   { set "C" compatible standard handles }
   new(opnfil[inpfil]); { standard input }
   opnfil[inpfil]^.hdl := sc_getstdhandle(sc_std_input_handle);
   { if opnfil[inpfil]^.hdl = -1 then error(estdhdl); }
   new(opnfil[outfil]); { standard output }
   opnfil[outfil]^.hdl := sc_getstdhandle(sc_std_output_handle);
   { if opnfil[outfil]^.hdl = -1 then error(estdhdl); }
   new(opnfil[errfil]); { standard error }
   opnfil[errfil]^.hdl := sc_getstdhandle(sc_std_error_handle);
   { if opnfil[errfil]^.hdl = -1 then error(estdhdl); }
   { note that windows does not have a standard handle for "list", 
     so we just equate it to the standard output }
   new(opnfil[lstfil]); { standard list }
   opnfil[lstfil]^.hdl := sc_getstdhandle(sc_std_output_handle);
   { if opnfil[lstfil]^.hdl = -1 then error(estdhdl); }
   cp := sc_getcommandline; { get command line }
   cmdptr := 1; { set 1st command line position }
   { skip spaces in command line }
   while (chkcmd = ' ') and (cmdptr <= max(cp^)) do cmdptr := cmdptr+1;
   { skip program name in command line }
   while (chkcmd <> ' ') and (cmdptr <= max(cp^)) do cmdptr := cmdptr+1;
   { skip spaces in command line }
   while (chkcmd = ' ') and (cmdptr <= max(cp^)) do cmdptr := cmdptr+1;
   ccro := false; { set no cr output }
   clfo := false; { set no lf output }
   new(bytsav, 1); { establish our single byte buffer }
   tmpcnt := 1; { clear temporary files counter }
   inpful := false; { set no input buffer active }
   inpeof := false; { set no input eof }

end;

begin

   88: { terminate module }

   for ofi := 1 to ss_maxhdl do if opnfil[ofi] <> nil then begin

      { if the file is open, close it. Note we use the non-overridable
        form of close for error processing reasons }
      if opnfil[ofi]^.hdl <> -1 then ss__close(ofi);
      dispose(opnfil[ofi]) { release file record }

   end;
   dispose(bytsav); { release our single byte buffer }

   99: { terminate immediately }

end.
