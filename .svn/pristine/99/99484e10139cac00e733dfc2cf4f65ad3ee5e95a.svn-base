{******************************************************************************
*                                                                             *
*                        DEVICE REGISTRATION MODULE                           *
*                                                                             *
*                      COPYRIGHT (C) 2007 S. A. MOORE                         *
*                                                                             *
* Defines the device registration entry, the global device list, and          *
* procedures to operate on it.                                                *
*                                                                             *
******************************************************************************}

module devreg;

uses stddef, { some standard defines }
     devcal; { device call module }

type

   { 

   Driver registry structure. Each of the functions registered is represented
   by a byte pointer address. This is replaced by an actual address in the 
   sysreg module, which is implemented in assembly. 

   There are two types of drivers, one of which is a superset of the other.
   These are the stream and volume drivers. A stream takes reads and writes, but
   cannot be positioned or have its current location queried. A volume can.

   Each driver has three calls:

      read(dr, ba, pos, len, err);

      With the drive registry entry dr, reads to the byte array ba from the 
      position on the volume pos, the number of bytes len, returning the error 
      err. The position is 1-n, and should be zero for a stream device,
      although that is probally not checked by the device.

      write(dr, ba, pos, len, err);

      With the drive registry entry dr, writes from the byte array ba to the 
      position on the volume pos, the number of bytes len, returning the error
      err. The position is 1-n, and should be zero for a stream device.

      length(dr, len, err);

      With the drive registry entry dr, returns the length of the device in 
      bytes, from 1-n. This call only works on a volume device.

   }

   drvptr = ^drvreg; { pointer to structure }

   { driver type }

   drvtyp = (dt_none,  
             dt_stream, 
             dt_stream_read, 
             dt_stream_write, 
             dt_volume);

   { driver entry }

   drvreg = record

      next:     drvptr;    { next entry }
      typ:      drvtyp;    { driver type }
      name:     pstring;   { name of driver }
      read:     devcal_pp; { read volume }
      write:    devcal_pp; { write volume }
      length:   devcal_pp; { find length (size of volume) }

   end;

procedure getdrv(var p: drvptr); forward;
procedure putdrv(p: drvptr); forward;
procedure regdrv(p: drvptr); forward;
function fnddrv(view fn: string): drvptr; forward;

private
             
var

   drvlst: drvptr; { active drivers list }

{*******************************************************************************

Get driver registration entry

Returns a new driver registration entry. The entry is initalized.

Note that the use of "new" is a upcall to syslib. This is ok because new does
not use local data, but this needs to be noted in case of changes.

*******************************************************************************}

procedure getdrv(var p: drvptr); { return drive registration entry }

begin

   new(p); { get a new drive registration entry }
   p^.next := nil; { clear next }
   p^.typ := dt_none; { set no device }
   p^.name := nil; { set no name }
   p^.read := nil; { clear read vector }
   p^.write := nil; { clear write vector }
   p^.length := nil; { clear length vector }

end;

{*******************************************************************************

Put driver registration entry

Frees the given driver registration entry.

Note that the use of "dispose" is a upcall to syslib. This is ok because dispose
does not use local data, but this needs to be noted in case of changes.

*******************************************************************************}

procedure putdrv(p: drvptr); { entry to free }

begin

   if p^.name <> nil then dispose(p^.name); { release name if it exists }
   dispose(p) { release entry }

end;

{*******************************************************************************

Place driver entry in list

Places the given driver registration entry in the drivers list. All of the
driver information should be filled out, and the vectors ready to be called,
since placement in the list means that it can be called.

*******************************************************************************}

procedure regdrv(p: drvptr); { entry to register }

begin

   p^.next := drvlst; { place in drivers list }
   drvlst := p

end;

{*******************************************************************************

Find driver by name

FInds a driver name. Looks for the given string in the driver list, and returns
the first matching driver. The name can have leading and trailing spaces. If
If found, returns the driver registry entry that matches, otherwise null.

*******************************************************************************}

function fnddrv(view fn: string) { name of device }
                : drvptr;        { return pointer for device } 

var fp: drvptr; { found driver registry pointer }
    dp: drvptr; { drive registry pointer }

{ match names }

function match(view s: string): boolean;

var m:    boolean; { match status }
    i, p: integer; { indexes for string }

{ find lower case }

function lcase(c: char): char;

begin

   { find lower case equivalent }
   if c in ['A'..'Z'] then c := chr(ord(c) - ord('A') + ord('a'));
   lcase := c { return as result }

end;

begin

   p := 1; { index 1st character of string }
   while (p < max(fn)) and (fn[p] = ' ') do p := p+1; { skip spaces }
   m := true; { set default matches }
   i := 1; { set index for match string }
   while (p < max(fn)) and (i < max(s)) and (lcase(fn[p]) = lcase(s[i])) do begin

      { match characters }
      p := p+1; { next substring }
      i := i+1 { next device string }

   end;
   { set match if last character matches, and end of device string }
   m := (lcase(fn[p]) = lcase(s[i])) and (i = max(s));
   { now set no match if any remaining character in substring is not space }
   for i := p+1 to max(fn) do if fn[p] <> ' ' then m := false;

   match := m { return match status }

end;

begin

   dp := drvlst; { index top of driver list }
   fp := nil; { set no driver found }
   while dp <> nil do begin { search drivers }

      if match(dp^.name^) then begin { found }

         fp := dp; { set found pointer }
         dp := nil { terminate search }

      end else dp := dp^.next { next driver }

   end;

   fnddrv := fp { return found pointer } 

end;

begin

   drvlst := nil; { clear drivers registration list }

end.