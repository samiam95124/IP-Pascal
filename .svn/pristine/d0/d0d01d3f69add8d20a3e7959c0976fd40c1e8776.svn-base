{*******************************************************************************
*                                                                              *
*                      LOGICAL I/O DEFINITION MDA DRIVER MODULE                *
*                                                                              *
*                              COPYRIGHT (C) 2007                              *
*                                  S. A. MOORE                                 *
*                                                                              *
* Performs logical I/O to physical assignments, of the following files:        *
*                                                                              *
* _input   - Currently unassigned                                              *
* _output  - Assigned to the IBM-PC MDA text screen                            *
* _error   - Assigned to the IBM-PC MDA text screen                            *
* _list    - Assigned to the IBM-PC MDA text screen                            *
* _command - Assigned to this module, to a pseudo device that gives an empty   *
*            line only.                                                        *
*                                                                              *
* Since we don't yet have a file system, we just assign _command to an empty   *
* line. When we have a file system, we will assign the _command stream to a    *
* file.                                                                        *
*                                                                              *
* To do:                                                                       *
*                                                                              *
* 1. It does not really make a lot of sense to define "_x" format names at     *
* this level, since that is IP Pascals' way of specifying a file name that is  *
* to be treated specially, not a driver. It makes more sense to define logical *
* device names such as "input", "output", etc., and let syslib handle the      *
* special processing which connects "_input" to "input", etc.                  *
*                                                                              *
*******************************************************************************}

module devlog;

uses startup, { startup section }
     devcal,  { device call module }
     devreg;  { device registry module }

private

var dp:  drvptr;  { device entry pointer }
    mda: drvptr;  { pointer to MDA device }
    crs: boolean; { \cr was sent }
    lfs: boolean; { \lf was sent }

{*******************************************************************************

Read command device

Returns \cr\lf, then eof.

*******************************************************************************}

procedure command_read(var ba:  bytarr;  { array to read to }
                           pos: integer; { position to read at }
                       var err: deverr); { return error }

var i: integer;

begin

   refer(ba, pos);

   if pos <> 0 then err := de_istm { illegal for serial device }
   else { read }
      for i := 1 to max(ba) do begin { read into array }

      if not crs then begin { no \cr sent }

         ba[i] := ord('\cr'); { place cr }
         crs := true { flag }

      end else if not lfs then begin { no \lf sent }

         ba[i] := ord('\lf'); { place lf }
         lfs := true { flag }

      end else err := de_eof { flag an eof }

   end

end;

{*******************************************************************************

Write command device

Writes a given number of bytes to the command device.

*******************************************************************************}

procedure command_write(view ba:  bytarr;  { array to write from }
                             pos: integer; { position to write at }
                        var  err:  deverr); { return error }

begin

   refer(ba, pos);

   if pos <> 0 then err := de_istm { illegal for serial device }
   else err := de_wrt { cannot write device }

end;

{*******************************************************************************

Get command device length

This is an error on a serial device.

*******************************************************************************}

procedure command_length(var len: integer; { length of device returned }
                         var err: deverr); { return error }

begin

   refer(len);

   err := de_istm { illegal for serial device }

end;

{*******************************************************************************

Copy string to dynamic

Simply creates a new dynamic string and copies the given string into that.

*******************************************************************************}

procedure copy(var  p: pstring; { string to create }
               view s: string); { string to copy }

begin

   new(p, max(s)); { create new string }
   p^ := s { copy into that }

end;

{*******************************************************************************

Create device alias

Copies the information from an existing device entry to a new one, gives it a
new name, 
Copy string to dynamic

Simply creates a new dynamic string and copies the given string into that.

*******************************************************************************}

procedure aliasdev(     mdp: drvptr;  { device to copy }
                   view n:   string); { new name }

var dp: drvptr; { device driver pointer }

begin

   getdrv(dp); { get a device registry entry }
   dp^.typ := mdp^.typ; { type }
   copy(dp^.name, n); { place name }
   dp^.read := mdp^.read; { copy read vector }
   dp^.write := mdp^.write; { copy write vector }
   dp^.length := mdp^.length; { copy length vector }
   regdrv(dp) { register it }

end;

{*******************************************************************************

Initalize device

*******************************************************************************}

begin

   { clear _command character flags }
   crs := false; { \cr sent }
   lfs := false; { \lf sent }

   { find the MDA device }
   mda := fnddrv('mda');
   
   { not good, but if we can't find it, we soft halt here }
   while mda = nil do;

   aliasdev(mda, '_output'); { alias "_output" to MDA }
   aliasdev(mda, '_error'); { alias "_error" to MDA }
   aliasdev(mda, '_list'); { alias "_list" to MDA }
   
   { register the command as null device }

   getdrv(dp); { get a device registry entry }
   dp^.typ := dt_stream_read; { set read stream device }
   copy(dp^.name, '_command');

   { place driver calls }

   devcal_read_ptr(command_read, dp^.read);
   devcal_write_ptr(command_write, dp^.write);
   devcal_length_ptr(command_length, dp^.length);
   
   { register driver entry }

   regdrv(dp)

end.