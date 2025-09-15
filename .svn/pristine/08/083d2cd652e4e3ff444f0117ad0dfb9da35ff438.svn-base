{******************************************************************************
*                                                                             *
*                    SYSTEM INTERFACE LIBRARY FOR UNIX                        *
*                                                                             *
*                            95/9 S. A. Moore                                 *
*                                                                             *
* Translates from the system independent calls to direct system calls on      *
* windows Unix. These calls interface indirectly via the Unix wrapper module. *
* Several services are performed here. First, filenames are checked against   *
* the system list, and if found, either a predefined handle is fetched to     *
* access that, or a special handle is given for the command line file (which  *
* has no Unix equivalent). If the file is not a special, it is assigned a     *
* local handle from the handles table, which maps directly to a system file   *
* handle. If the handle is a special, it will not need special processing     *
* after it is opened.                                                         *
* EOF checking is a special problem under Unix, or any system using the       *
* C/Unix low level interface conventions. The only way this interface can     *
* find if EOF has been encountered is to run into it during a read (since     *
* writes will automatically extend the EOF). So what we do is keep a single   *
* byte buffer. When EOF is checked, the buffer is read, and at the same time  *
* we know if EOF is true. You might think of that read call as "check eof",   *
* with the side effect of reading the next byte. Then, the other routines     *
* compensate for having a possible buffered byte.                             *
* At the present, no really extensive error information is received from the  *
* OS. The errors mostly tell what was being attempted when the error          *
* occurred. More comprehensive error reporting should be added as time        *
* permits.                                                                    *
* The list file is presently unimplemented.                                   *
* 3/2001 [sam] Converted to "override" use. Each entry is preceded with "_",  *
* then the real entry exists in the sysovr.asm module.                        *
* We override "circularly", that is, there are calls to routines in this      *
* module that could be themselves overriden. This allows, for example, the    *
* error printout function to be overriden, but is a very dangerous ability.   *
*                                                                             *
******************************************************************************}

module syslib;

uses stddef,  { some standard defines }
     wrapper, { system calls wrappers }
     gettgp,  { converts fixed array to pointer }
     sysovr,  { our override module }
     unixsup; { Unix support routines module }

{ external interface }

procedure ss__openread(var fn: ss_filhdl; view nm: string); forward;
procedure ss__openwrite(var fn: ss_filhdl; view nm: string); forward;
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
procedure ss__getspace(var bp: gbtptr; ln: integer); forward;
procedure ss__putspace(bp: gbtptr); forward;
function ss__alteol: boolean; forward;
procedure ss__wrterr(view es: string); forward;

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

type

   { file entry pointer }
   filptr = ^filrec;
   { file entry record }
   filrec = record

      hdl:  integer; { win95 handle of file }
      buf:  byte;    { buffer for next byte in file }
      full: boolean  { buffer is full flag }

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
             eipbovf); { input buffer overflow }

var

   opnfil: array [0..ss_maxhdl] of filptr; { open files table }
   erract: boolean; { error being processed }
   ofi:    1..ss_maxhdl; { index for files table }
   cmdptr: integer; { current command line position }
   cp:     pstring; { holds command line pointer }
   bytsav: gbtptr; { place to store single read byte }
   ccro:   boolean; { command line cr output }
   clfo:   boolean; { command line lf output }
   tmpcnt: integer; { temporary files counter }

{******************************************************************************

Write error string

Writes the given string to the standard error output.
We assume that the output could be in the middle of a line, so an eoln
sequence is output both before and after the string.
If the standard error output handle is bad, then this probally means that we
are in graphical mode. In this case, the string is output to a dialog.
The message output should be complete, and the caller should not try to output
multiple lines of error messages.
This routine works as autonomusly as possible, because loops while trying
to process errors are bad. Higher level modules usually use this routine to
output errors for this reason.

******************************************************************************}
 
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

begin

   new(r.sp, max(es)); { get a string buffer }
   r.sp^ := es; { place string in it }
   { write the error string. it does not matter if an error occurs, we cannot
     do anything about it anyways }
   fr := sc_write(sc_stderr, r.bp^);
   dispose(r.sp) { release string }

end;

begin { ss_wrterr }

   outstr('\lf*** Runtime error: ');
   outstr(es);
   outstr('\lf')

end;

{******************************************************************************

Print error string

Outputs an error string with 'Syslib: preamble'.

******************************************************************************}
 
procedure errstr(view s: string);

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

{*******************************************************************************

Handle Unix error

Looks up the errno error number to find a message, then prints the message
as an error.

*******************************************************************************}

procedure unixerr;

var es, ts: pstring;

procedure cat(var d: pstring; { destination }
              view sa, sb: string); { sources }

var i: integer; { index for string }

begin

   new(d, max(sa)+max(sb)); { create destination }
   for i := 1 to max(sa) do d^[i] := sa[i]; { copy left string }
   for i := 1 to max(sb) do d^[max(sa)+i] := sb[i] { copy right string }

end;

begin

   geterr(sc_errno, ts); { get the error message }
   cat(es, 'Unix: ', ts^); { form message }
   dispose(ts); { release temp }
   errstr(es^); { process error }
   dispose(es); { release message }
   goto 88 { abort module }

end;

{******************************************************************************

Print error

Prints the given error in ASCII text, then aborts the program.

******************************************************************************}
 
procedure error(e: errcod);

begin

   { if error is already active, this is a double fault. we exit immediately }
   if erract then goto 99; { immediate exit }
   erract := true; { set error being processed }
   case e of { error }

      eftbful: errstr('File table full');
      efnmtl:  errstr('File name too long');
      eopnfil: errstr('File open fails');
      esize:   errstr('File size fails');
      efilnop: errstr('File not open');
      eclsfil: errstr('File close fails');
      eread:   errstr('File read fails');
      ewrite:  errstr('File write fails');
      epos:    errstr('File position fails');
      edel:    errstr('File delete fails');
      echg:    errstr('File name change fails');
      egetsp:  errstr('Dynamic space allocation fails');
      eputsp:  errstr('Dynamic space release fails');
      efilopr: errstr('Cannot perform operation on special file');
      ecmdltl: errstr('Command line too long');
      eeof:    errstr('Read past EOF');
      einvhdl: errstr('Invalid handle');
      efilzer: errstr('Filename is empty');
      ezertrn: errstr('File transfer length is zero');
      esizpre: errstr('File size is to large to return');
      estdhdl: errstr('cannot open standard I/O file');
      etmpovf: errstr('Too many temporary files');
      einvpos: errstr('Invalid position');
      eipbovf: errstr('Standard input buffer overflow');

   end;
   goto 88 { abort module }

end;

{******************************************************************************

Make file entry

Indexes a present file entry or creates a new one. If an entry exists in the
table, and is closed, we return that. Otherwise, we look for completely empty
slots, and if found, the slot is allocated, and that returned. If there are
no empty slots, the table is full. Returns the logical number of the file
entry.
Note that the "predefined" file slots are never allocated.

******************************************************************************}

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
         full := false

      end

   end;
   fn := ff { set file id number }

end;

{******************************************************************************

Check null string

Checks if the given string contains nothing or only spaces.

******************************************************************************}

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

{******************************************************************************

Remove leading and trailing spaces

Given a string, removes any leading and trailing spaces in the string. The
result is allocated and returned as an indexed buffer.
The input string must not be null.

******************************************************************************}

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

{******************************************************************************

Check system special file

Checks for one of the special files, and returns the handle of the special
file if found. Accepts a general string.

******************************************************************************}

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

{******************************************************************************

Create temporary filename

"coins" a temporary file name. We use an incrementing counter to create temp
files. That count, up to 9999, is placed into the filename. If the temp files
are occupied, we just keep incrementing till we find a good one. Temp files
should be cleaned out of the directory on exit.
The format of a temp name is:

   sys_0001.tmp

******************************************************************************}

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

{******************************************************************************

Check next command line character

Returns the next command line character, or space if past the end.

******************************************************************************}

function chkcmd: char; { returns next character }

var c: char; { character holder }

begin

   { check past end of line }
   if cmdptr <= max(cp^) then c := cp^[cmdptr] { return next character }
   else c := ' '; { return space for eoln }
   chkcmd := c { return character }

end;

{******************************************************************************

Create command parameter file

Creates a command parameter file by first skipping spaces in the command line,
then reading any non-space characters in the command line as the file
parameter. It is an error if there are no such characters. No attempt is made
to verify if the filename is correct.
The spaces after the parameter are also skipped to keep returns clean.

******************************************************************************}

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

{******************************************************************************

Open file for reading

Opens the given file by name, types it as read only, and returns the file
handle. If the file is a system special file, we simply return the predefined
handle to that, since the special files are already all set up, and remain
so for the duration of the program run.
Clears the file parameters.

******************************************************************************}

procedure ss__openread(var  fn: ss_filhdl; { file handle }
                      view nm: string);   { file string }

var fs: pstring; { filename buffer pointer }

begin 

   if chknul(nm) then begin { temp file }

      temp(fs); { create temp file name }
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
     
         { open existing file in read mode }
         hdl := sc_open(fs^, sc_o_rdonly, 0);
         if hdl < 0 then unixerr; { open did not work, process error }
         dispose(fs); { release buffer }
         buf := 0; { clear buffer }
         full := false

      end

   end else dispose(fs) { release buffer }

end;

{******************************************************************************

Open file for writing

Opens the given file by name, types it as write only, and returns the file
handle. If the file is a system special file, we simply return the predefined
handle to that, since the special files are already all set up, and remain
so for the duration of the program run.
Clears the file parameters.

******************************************************************************}

procedure ss__openwrite(var  fn: ss_filhdl; { file handle }
                       view nm: string);   { file string }

var fs: pstring; { filename buffer pointer }

begin 

   if chknul(nm) then begin { temp file }

      temp(fs); { create temp file name }
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

         { open new file with permissions for owner, group and others }
         hdl := sc_creat(fs^, &666); { open new file }
         if hdl < 0 then unixerr; { open did not work, process error }
         dispose(fs); { release buffer }
         buf := 0; { clear buffer }
         full := false

      end

   end else dispose(fs) { release buffer }

end;

{******************************************************************************

Close file

Closes the file. System special files are left alone, since they are open for
the duration of the program.

******************************************************************************}

procedure ss__close(fn: ss_filhdl); { file handle }

var r: integer;

begin

   if fn > cmdfil then begin { file is not a special file }

      if opnfil[fn] = nil then error(einvhdl); { invalid handle }
      with opnfil[fn]^ do begin { process file }

         if hdl = -1 then error(efilnop); { file not open }
         if fn > cmdfil then begin { not a special file }

            r := sc_close(hdl); { close file }
            if (r < 0) then unixerr; { process unix error }

         end;
         hdl := -1 { set file closed }

      end

   end

end;

{******************************************************************************

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

******************************************************************************}

procedure ss__read(    fn: ss_filhdl; { file handle }
                  var ba: bytarr);   { block to read to }

var i:  integer; { index for destination }
    l:  integer; { length left on destination }
    rc: integer; { return code }
    r:  record { pointer fiddling }

           case boolean of

              false: (a: integer;  { address }
                      l: integer); { length }
              true:  (p: gbtptr)   { block pointer }

           { end }

        end;

begin

   i := 1; { set 1st byte of destination }
   l := max(ba); { set length of destination }
   if fn = cmdfil then begin { process command file read }

      while l > 0 do begin { read command bytes }

         if cmdptr > max(cp^) then begin { end of line }

            if ccro and clfo then error(eeof); { read past eof }
            if not ccro then begin { output cr }

               ba[i] := ord('\cr'); { place cr }
               i := i+1; { next byte }
               ccro := true { set cr output }

            end else begin { output lf }

               ba[i] := ord('\lf'); { place lf }
               i := i+1; { next byte }
               clfo := true { set lf output }

            end

         end else begin

            ba[i] := ord(cp^[cmdptr]); { read and place byte }
            i := i+1; { next byte }
            cmdptr := cmdptr+1 { next character }

         end;
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

               rc := sc_read(hdl, r.p^); { execute read }
               if rc < 0 then unixerr; { file read error }
               if rc < max(r.p^) then error(eeof) { EOF encountered }

            end

         end else { normal data read }
            if max(ba) <> 0 then begin { there are more bytes to transfer }

            { execute read }
            rc := sc_read(hdl, ba); { file read error }
            if rc < 0 then unixerr; { file read error }
            if rc < max(ba) then error(eeof) { EOF encountered }

         end

      end

   end

end;

{******************************************************************************

Write file

Transfers the specified number of bytes from the address. Refuses to write to
the command file.
If the buffer is full (from an EOF check), then we must back up the position
before the write takes place. This is a potential time hit, but note that
there is virtually no reason to perform reapeated EOF checks while writing
the file, since the EOF is immaterial to a write.

******************************************************************************}

procedure ss__write(     fn: ss_filhdl; { file handle }
                   view ba: bytarr);   { address to write to }

var r: integer;

begin

   if (fn = cmdfil) or (fn = inpfil) then
      error(efilopr); { cannot write to command or input file }
   if opnfil[fn] = nil then error(einvhdl); { invalid handle }
   with opnfil[fn]^ do begin { process file }

      if hdl = -1 then error(efilnop); { file not open }
      if max(ba) = 0 then error(ezertrn); { file write is zero }
      if full then begin

         { buffer is full, we must eliminate this condition by backing up }
         r := sc_lseek(hdl, -1, 1); { seek the file }
         if (r < 0) then unixerr; { process unix error }
         full := false { clear buffer }

      end;
      { execute write }
      r := sc_write(hdl, ba);
      if (r < 0) then unixerr { process unix error }

   end

end;

{******************************************************************************

Position file

Moves the read/write position to the specified location. Having done this,
any buffered byte is simply discarded.

******************************************************************************}

procedure ss__position(fn: ss_filhdl; { file handle }
                      p:  integer);  { position }

var r: integer;

begin

   if (fn = cmdfil) or (fn = inpfil) then
      error(efilopr); { cannot position command or input file }
   if opnfil[fn] = nil then error(einvhdl); { invalid handle }
   if p < 1 then error(einvpos); { invalid position }
   with opnfil[fn]^ do begin { process file }

      if hdl = -1 then error(efilnop); { file not open }
      if fn = cmdfil then error(efilopr); { file operation }
      { position file }
      r := sc_lseek(hdl, p-1, 0);
      if (r < 0) then unixerr; { process unix error }
      full := false { set no byte buffered }

   end
  
end;

{******************************************************************************

Find location of file

Returns the current read/write location of the file. This is done by exploting
the fact that the seek call returns the resulting position. We perform a null
seek, and use the result. If the buffer is full, the location returned by
Win 95 must be adjusted.

******************************************************************************}

function ss__location(fn: ss_filhdl) { file handle }
                     : integer;     { location return }

var loc: integer; { location holder }

begin

   if (fn = cmdfil) or (fn = inpfil) then
      error(efilopr); { cannot locate command or input file }
   if opnfil[fn] = nil then error(einvhdl); { invalid handle }
   with opnfil[fn]^ do begin { process file }

      if hdl = -1 then error(efilnop); { file not open }
      if fn <= cmdfil then error(efilopr); { file operation }
      loc := sc_lseek(hdl, 0, 1); { find file location }
      if loc < 0 then unixerr; { file position error }
      { if the buffer is full, then the position read will be one past the
        actual position }
      if full then loc := loc-1;
      ss__location := loc+1 { return file location }

   end

end;

{******************************************************************************

Find length of file

Returns the current length of the file.

******************************************************************************}

function ss__length(fn: ss_filhdl) { file handle }
                   : integer;     { location return }

var len: integer; { file size holder }
    cur: integer; { current file position }

begin

   if (fn = cmdfil) or (fn = inpfil) then
      error(efilopr); { cannot size command or input file }
   if opnfil[fn] = nil then error(einvhdl); { invalid handle }
   with opnfil[fn]^ do begin { process file }

      if hdl = -1 then error(efilnop); { file not open }
      if fn <= cmdfil then error(efilopr); { file operation }
      cur := sc_lseek(hdl, 0, 1); { find current position in file }
      if cur < 0 then unixerr; { file size error }
      len := sc_lseek(hdl, 0, 2); { get length of file }
      if len < 0 then unixerr; { file size error }
      cur := sc_lseek(hdl, cur, 0); { go back to position }
      if cur < 0 then unixerr; { file size error }
      ss__length := len { return file location }

   end

end;

{******************************************************************************

Check file at EOF

Returns the EOF status of the file. If the file is the command file, we simply
look for the zero termination of that string. Otherwise, we read one byte
ahead and place that in the buffer. If the read did not work because of EOF
encounter, we return true and the buffer remains empty. The buffer full flag,
then, serves as a "not eof" flag for repeated eof status calls.

******************************************************************************}

function ss__eof(fn: ss_filhdl) { file handle }
                : boolean;     { eof return }

var ef: boolean; { eof status }
    len: integer; { read length holder }
    

begin

   { set status in case of command line }
   if fn = cmdfil then ef := (cmdptr > max(cp^)) and ccro and clfo
   else begin { normal file }

      if opnfil[fn] = nil then error(einvhdl); { invalid handle }
      with opnfil[fn]^ do begin { process file }

         if hdl = -1 then error(efilnop); { file not open }
         if not full then begin { buffer is not already full }

            { read ahead one byte in file to determine eof status }
            len := sc_read(hdl, bytsav^);
            if len < 0 then unixerr; { file read error }
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

{******************************************************************************

Delete file

Deletes the given file by name.

******************************************************************************}

procedure ss__delete(view nm: string); { file string }

var fs: pstring; { filename buffer pointer }
    r:  integer; { function result }

begin

   remspc(nm, fs); { remove leading and trailing spaces }
   r := sc_unlink(fs^); { process delete }
   if r < 0 then unixerr; { delete error }
   dispose(fs) { release buffer }

end;

{******************************************************************************

Change filename

Changes the source filename to the destination filename. The destination
filename should not have a path specification on it.

******************************************************************************}

procedure ss__change(view dn: string;  { destination filename }
                    view sn: string); { source filename }

var ds, ss: pstring; { filename buffer pointers }
    r:      integer; { function result }

begin

   if exists(dn) then error(echg); { destination exists }
   remspc(dn, ds); { remove leading spaces }
   remspc(sn, ss);
   r := sc_rename(ss^, ds^); { process change }
   if r < 0 then unixerr; { change error }
   dispose(ds); { release buffers }
   dispose(ss)

end;

{******************************************************************************

Check file exists

Returns true if the given file exists. We cheat a little, and return exists
true if the file can be opened without error. This could deliver a negative
answer that is not because the file does not exist.

******************************************************************************}

function ss__exists(view nm: string) { filename }
                   : boolean;       { exists status }

var fs: pstring; { filename buffer pointer }
    r:  integer; { return value }

begin

   remspc(nm, fs); { remove leading spaces }
   { open existing file in read mode }
   r := sc_open(fs^, sc_o_rdonly, 0);
   dispose(fs); { release buffer }
   if r >= 0 then begin { found it, close that file }

      r := sc_close(r);
      if r < 0 then unixerr { process unix error }

   end;
   ss__exists := r >= 0 { return exists status }

end;

{******************************************************************************

Get heap space

Allocates the requested length block of storage, and returns the address.

******************************************************************************}

procedure ss__getspace(var bp: gbtptr;   { block pointer }
                          ln: integer); { length of block }

begin

   sc_malloc(bp, ln); { allocate block }
   if bp = nil then error(egetsp) { failed, error }

end;

{******************************************************************************

Put heap space

Releases the indicated storage block to free space.

******************************************************************************}

procedure ss__putspace(bp: gbtptr); { block address }

begin

   sc_free(bp) { free block }

end;

{******************************************************************************

Check alternate EOL

Checks if the alternate end of line is in use, or \lf only (no \cr). Unix
uses alternate end of lines.

******************************************************************************}

function ss__alteol: boolean;

begin

   ss__alteol := true { return alternate EOLs }

end;

{******************************************************************************

Initalize module

******************************************************************************}

begin

   { clear files table }
   for ofi := 0 to ss_maxhdl do opnfil[ofi] := nil; { clear files table }
   erract := false; { set no error being processed }
   { set "C" compatible standard handles }
   new(opnfil[inpfil]); { standard input }
   opnfil[inpfil]^.hdl := sc_stdin;
   new(opnfil[outfil]); { standard output }
   opnfil[outfil]^.hdl := sc_stdout;
   new(opnfil[errfil]); { standard error }
   opnfil[errfil]^.hdl := sc_stderr;
   { note that Unix does not have a standard handle for "list", 
     so we just equate it to the standard output }
   new(opnfil[lstfil]); { standard list }
   opnfil[lstfil]^.hdl := sc_stdout;
   sc_getcmd(cp); { get command line }
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

end;

begin

   88: { terminate module }

   for ofi := 1 to ss_maxhdl do if opnfil[ofi] <> nil then begin

      { if the file is open, close it }
      if opnfil[ofi]^.hdl <> -1 then ss_close(ofi);
      dispose(opnfil[ofi]) { release file record }

   end;
   dispose(bytsav); { release our single byte buffer }

   99: { terminate immediately }

end.
