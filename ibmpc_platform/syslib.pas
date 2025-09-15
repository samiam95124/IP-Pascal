{*******************************************************************************
*                                                                              *
*                 SYSTEM INTERFACE LIBRARY FOR IBM-PC DIRECT                   *
*                                                                              *
*                            95/9 S. A. Moore                                  *
*                                                                              *
* Implements syslib direct to IBM-PC hardware.                                 *
*                                                                              *
* The direct to hardware implementation is actually more of a general purpose  *
* I/O multiplexer, and could be moved to a general embedded system. We         *
* establish a method for registering drivers with a series of vectors for      *
* needed functions such as the classic read, write, position, location, etc.   *
* This module goes first in the stacking order, and implements no real         *
* I/O on its own. Each individual hardware driver is then executed later in    *
* the stacking order, and calls this module to register itself as a driver.    *
* After all of the drivers have so initialized, the system is ready to run     *
* higher level protocols and an application.                                   *
*                                                                              *
* At present, only the devices are implemented, and no file operations are     *
* performed. The next step is to also implement a file managers registry,      *
* to allow multiple file management modules to exist.                          *
*                                                                              *
*******************************************************************************}

module syslib;

uses stddef, { some standard defines }
     memman, { memory manager }
     devcal, { device vector call }
     devreg; { device registry }

const ss_maxhdl = 100; { maximum number of file handles }

type  ss_filhdl = 0..ss_maxhdl; { file handle number }

{ calls this module }

procedure ss_alias(fn, fa: ss_filhdl); forward;
procedure ss_resolve(view nm: string; var fs: pstring); forward;
procedure ss_openread(var fn: ss_filhdl; view nm: string); forward;
procedure ss_openwrite(var fn: ss_filhdl; view nm: string); forward;
procedure ss_openupdate(var fn: ss_filhdl; view nm: string); forward;
procedure ss_close(fn: ss_filhdl); forward;
procedure ss_read(fn: ss_filhdl; var ba: bytarr); forward;
procedure ss_write(fn: ss_filhdl; view ba: bytarr); forward;
procedure ss_position(fn: ss_filhdl; p: integer); forward;
function ss_location(fn: ss_filhdl): integer; forward;
function ss_length(fn: ss_filhdl): integer; forward;
function ss_eof(fn: ss_filhdl): boolean; forward;
procedure ss_delete(view nm: string); forward;
procedure ss_change(view dn, sn: string); forward;
function ss_exists(view nm: string): boolean; forward;
procedure ss_getspace(var bp: gbtptr; ln: integer); forward;
procedure ss_putspace(bp: gbtptr); forward;
function ss_alteol: boolean; forward;
procedure ss_wrterr(view es: string); forward;

{ private section }

private

label 88, { abort module }
      99; { abort immediate }

type

   { file entry pointer }
   filptr = ^filrec;

   { file entry record }
   filrec = record

      hdl: drvptr;  { pointer to driver structure for this file }
      pos: integer; { current position for this file }
      len: integer  { length (size of driver volume) for this file } 

   end;

   { open mode }
   opnmod = (omopenread,    { open for read only }
             omopenwrite,   { open for write only }
             omopenupdate); { open for update }

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
             eexstf);  { file exists fails }

var

   opnfil: array [1..ss_maxhdl] of filptr; { open files table }
   ofi:    1..ss_maxhdl; { index for files table }
   erract: boolean; { error being processed }

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
 
procedure ss_wrterr(view es: string);

{ output the string to standard error }

procedure outstr(view es: string);

var dp:     drvptr; { pointer to device entry }
    bytsav: gbtptr; { place to store byte string }
    err:    deverr; { driver error code }
    i:      integer;
    

begin

   dp := fnddrv('_error'); { find the logical error device }
   if dp <> nil then begin { we found it }

      new(bytsav, max(es)); { allocate a byte buffer for string }
      for i := 1 to max(es) do bytsav^[i] := ord(es[i]); { copy }
      devcal_write(bytsav^, 0, err, dp^.write); { write error message }
      { we ignore the error, we can't do anything with it in any case }
      dispose(bytsav) { release buffer }

   end

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
   for fi := 1 to ss_maxhdl do if opnfil[fi] <> nil then 
      if opnfil[fi]^.hdl = nil then ff := fi;
   if ff = 0 then begin { no idle slots found }

      { find empty file slot }
      ff := 0; { clear found file }
      for fi := 1 to ss_maxhdl do if opnfil[fi] = nil then ff := fi;
      if ff = 0 then error(eftbful); { file table full }
      new(opnfil[ff]); { create a new file entry }
      with opnfil[ff]^ do begin { initalize entry }

         hdl := nil; { set is closed }
         pos := 0; { clear current position to invalid }
         len := 0 { clear current length }

      end

   end;
   fn := ff { set file id number }

end;

{*******************************************************************************

Alias file handle

Create an alias between an alias file handle, and a syslib level file handle.
This is a no-op in syslib. It solves the issue in overload stacks that we don't
know what top level file number corresponds with the low level I/O numbers
here in syslib, which you need to know if you are also going to accept top
level calls.

*******************************************************************************}

procedure ss_alias(fn, fa: ss_filhdl);

begin

   refer(fn, fa) { this is a no-op here }

end;

{******************************************************************************

Resolve filename

Resolves parameter files.

Because the command parameter file naming system is order dependent, it can
be a problem to call opens in any order, since the caller might get the wrong
parameter. To fix this, this routine is called to replace the parameter name
with its resolved name from the command line, in order.

This routine could be used to resolve any other order dependencies. The temp
files are not resolved here because they are not order dependent.

******************************************************************************}

procedure ss_resolve(view nm: string; var fs: pstring);

begin

   { just copy filename to string }
   new(fs, max(nm)); { create filename string }
   fs^ := nm { place filename }

end;

{*******************************************************************************

Open file for reading and writing

Finds a device with the requested name, then creates a file entry for the
file instance and initializes that. If the driver is a volume device, we get
the length (size) and initialze the position to the start of the device, 1.
This allows us to check for end of volume without constantly asking for the
length of the volume.

*******************************************************************************}

procedure open(var  fn:   ss_filhdl; { file handle }
               view nm:   string;    { file string }
                    mode: opnmod);   { open mode }

var dp:  drvptr; { pointer to device registry entry }
    err: deverr; { driver error code }

begin 

   refer(mode); { we don't use the mode }

   dp := fnddrv(nm); { find matching device }
   if dp = nil then error(eopnfil); { cannot find device by name }
   makfil(fn); { create new file slot }
   with opnfil[fn]^ do begin { process file }

      hdl := dp; { set driver handle for file }
      if dp^.typ = dt_volume then begin { is a volume device }

         pos := 1; { set initial position }
         devcal_length(len, err, dp^.length) { find length for volume }

      end else begin { is a stream device }

         pos := 0; { set initial position }
         len := 0 { set length }

      end

   end

end;

{*******************************************************************************

Open file for reading

Opens the given file by name, types it as read only, and returns the file
handle. If the file is a system special file, we simply return the predefined
handle to that, since the special files are already all set up, and remain
so for the duration of the program run.
Clears the file parameters.

*******************************************************************************}

procedure ss_openread(var  fn: ss_filhdl; { file handle }
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

procedure ss_openwrite(var  fn: ss_filhdl; { file handle }
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

procedure ss_openupdate(var  fn: ss_filhdl; { file handle }
                         view nm: string);   { file string }

begin

   open(fn, nm, omopenupdate) { process open }

end;

{*******************************************************************************

Close file

Closes the file. There really is nothing to do here, since devices don't need
to be closed. We just flag the file entry as closed.

*******************************************************************************}

procedure ss_close(fn: ss_filhdl); { file handle }

begin

   if (fn < 1) or (fn > ss_maxhdl) then error(einvhdl); { invalid handle }
   if opnfil[fn] = nil then error(einvhdl); { invalid handle }
   opnfil[fn]^.hdl := nil { set file closed }

end;

{*******************************************************************************

Read file

Read from the device to the given address. Checks that a valid, open device
file was passed, then processes the read using the indicated device. We process
eof errors and general read errors. The byte array as passed gives both the
address and the length of the transfer.

*******************************************************************************}

procedure ss_read(    fn: ss_filhdl; { file handle }
                  var ba: bytarr);   { block to read to }

var err: deverr; { driver error code }

begin

   if (fn < 1) or (fn > ss_maxhdl) then error(einvhdl); { invalid handle }
   if opnfil[fn] = nil then error(einvhdl); { invalid handle }
   with opnfil[fn]^ do begin { process file }

      if hdl = nil then error(efilnop); { file not open }
      devcal_read(ba, pos, err, hdl^.read); { perform device read }
      if err = de_eof then error(eeof); { process read past end of device }
      if err <> de_none then error(eread); { process read error }
      if hdl^.typ = dt_volume then pos := pos+max(ba) { advance position }

   end

end;

{*******************************************************************************

Write file

Write to the device from the given address. Checks that a valid, open device
file was passed, then processes the write using the indicated device. We process
eof errors and general read errors. The byte array as passed gives both the
address and the length of the transfer.

*******************************************************************************}

procedure ss_write(     fn: ss_filhdl; { file handle }
                   view ba: bytarr);   { address to write to }

var err: deverr; { driver error code }

begin

   if (fn < 1) or (fn > ss_maxhdl) then error(einvhdl); { invalid handle }
   if opnfil[fn] = nil then error(einvhdl); { invalid handle }
   with opnfil[fn]^ do begin { process file }

      if hdl = nil then error(efilnop); { file not open }
      devcal_write(ba, pos, err, hdl^.write); { perform device write }
      if err = de_eof then error(eeof); { process write past end of device }
      if err <> de_none then error(ewrite); { process write error }
      if hdl^.typ = dt_volume then pos := pos+max(ba) { advance position }

   end

end;

{*******************************************************************************

Position file

Moves the read/write position to the specified location. The new position is
simply stored in the device desriptor for the next operation, since devices
don't keep state.

*******************************************************************************}

procedure ss_position(fn: ss_filhdl; { file handle }
                      p:  integer);  { position }

begin

   if (fn < 1) or (fn > ss_maxhdl) then error(einvhdl); { invalid handle }
   if opnfil[fn] = nil then error(einvhdl); { invalid handle }
   if p < 1 then error(einvpos); { invalid position }
   with opnfil[fn]^ do begin { process file }

      if hdl = nil then error(efilnop); { file not open }
      if hdl^.typ <> dt_volume then error(epos); { must be a volume device }
      if p > len then error(eeof); { seek past end of file }
      pos := p { set new position for file }

   end
  
end;

{*******************************************************************************

Find location of file

Returns the current read/write location of the file. This is simply the position
we currently keep track of in the device entry.

*******************************************************************************}

function ss_location(fn: ss_filhdl) { file handle }
                     : integer;     { location return }

begin

   if (fn < 1) or (fn > ss_maxhdl) then error(einvhdl); { invalid handle }
   if opnfil[fn] = nil then error(einvhdl); { invalid handle }
   with opnfil[fn]^ do begin { process file }

      if hdl = nil then error(efilnop); { file not open }
      if hdl^.typ <> dt_volume then error(epos); { must be a volume file }
      ss_location := pos { return the current position }

   end

end;

{*******************************************************************************

Find length of file

Returns the current length of the file. Since device lengths don't change, this
is the same as the device length we stored when the device reference was
opened.

*******************************************************************************}

function ss_length(fn: ss_filhdl) { file handle }
                   : integer;     { location return }

begin

   if (fn < 1) or (fn > ss_maxhdl) then error(einvhdl); { invalid handle }
   if opnfil[fn] = nil then error(einvhdl); { invalid handle }
   with opnfil[fn]^ do begin { process file }

      if hdl = nil then error(efilnop); { file not open }
      if hdl^.typ <> dt_volume then error(epos); { must be a volume file }
      ss_length := len { return file length }

   end

end;

{*******************************************************************************

Check file at EOF

Returns the EOF status of the file. If the device is stream, we never indicate
EOF for it, it streams forever in our model. For volume devices, we simply
check if the current position is past the end. The position is allowed to be
one byte past the end of the device. We keep the current position and the
length for the device so that we can perform this check.

*******************************************************************************}

function ss_eof(fn: ss_filhdl) { file handle }
               : boolean;     { eof return }

var ef: boolean; { eof status }

begin

   if (fn < 1) or (fn > ss_maxhdl) then error(einvhdl); { invalid handle }
   if opnfil[fn] = nil then error(einvhdl); { invalid handle }
   with opnfil[fn]^ do begin { process file }

      if hdl = nil then error(efilnop); { file not open }
      if hdl^.typ <> dt_volume then ef := false { always false unless a volume }
      else ef := pos > len { otherwise it is the position past the end }

   end;
   ss_eof := ef { return status }

end;

{*******************************************************************************

Delete file

Deletes the given file by name. Since there is no filesystem as yet, this is
always an error.

*******************************************************************************}

procedure ss_delete(view nm: string); { file string }

begin

   refer(nm);

   error(edel) { flag delete error }

end;

{*******************************************************************************

Change filename

Changes the source filename to the destination filename. The destination
filename should not have a path specification on it. Since there is no
filesystem as yet, this is always an error.

*******************************************************************************}

procedure ss_change(view dn: string;  { destination filename }
                    view sn: string); { source filename }

begin

   refer(dn, sn);

   error(echg) { change error }

end;

{*******************************************************************************

Check file exists

Returns true if the given file exists. We cheat a little, and return exists
true if the file can be opened without error. This could deliver a negative
answer that is not because the file does not exist. Since there is no
filesystem as yet, this is always an error.

*******************************************************************************}

function ss_exists(view nm: string) { filename }
                   : boolean;       { exists status }

begin

   refer(nm);

   error(eexstf); { exists error }

   ss_exists := false

end;

{*******************************************************************************

Get heap space

Allocates the requested length block of storage, and returns the address.

Produces an error if the length is negative. Zero length is actually ok, its
possible to have a zero length item like a null length array.

*******************************************************************************}

procedure ss_getspace(var bp: gbtptr;   { block pointer }
                           ln: integer); { length of block }

begin

   if ln < 0 then error(eneglen); { negative length }
   memman_getspace(bp, ln) { get block from memory manager }

end;

{*******************************************************************************

Put heap space

Releases the indicated storage block to free space.

*******************************************************************************}

procedure ss_putspace(bp: gbtptr); { block address }

begin

   memman_putspace(bp) { put block to memory manager }
 
end;

{*******************************************************************************

Check alternate EOL

Checks if the alternate end of line is in use, or \lf only (no \cr). Unix
uses alternate end of lines.

*******************************************************************************}

function ss_alteol: boolean;

begin

   ss_alteol := false { don't return alternate EOLs }

end;

{*******************************************************************************

Initalize module

*******************************************************************************}

begin

   erract := false; { set no error being processed }

   { clear files table }
   for ofi := 1 to ss_maxhdl do opnfil[ofi] := nil; { clear files table }

end;

begin

   88: { terminate module }

   for ofi := 1 to ss_maxhdl do if opnfil[ofi] <> nil then begin

      dispose(opnfil[ofi]) { release file record }

   end;

   99: { terminate immediately }

end.
