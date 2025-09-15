{******************************************************************************
*                                                                             *
*                         EXTENDED FUNCTION LIBRARY                           *
*                                                                             *
*                           Copyright (C) 1996                                *
*                                                                             *
*                               S. A. MOORE                                   *
*                                                                             *
* Contains various system oriented library functions, including files,        *
* directories, time, program execution, evironment, and random numbers.       *
* Most or all of these procedures are implemented in a manner specific to     *
* Windows 95/Windows NT 4.0 or later versions.                                *
*                                                                             *
******************************************************************************}

module extlib(output);

uses stddef,
     windows,
     syslib,
     winsup,
     cvttim,
     strlib;

type 

   { attributes }
   attribute = (atexec,  { is an executable file type }
                atarc,   { has been archived since last modification }
                atsys,   { is a system special file }
                atdir,   { is a directory special file }
                atloop); { contains heriarchy loop }
   attrset = set of attribute; { attributes in a set }
   { permissions }
   permission = (pmread,  { may be read }
                 pmwrite, { may be written }
                 pmexec,  { may be executed }
                 pmdel,   { may be deleted }
                 pmvis,   { may be seen in directory listings }
                 pmcopy,  { may be copied }
                 pmren);  { may be renamed/moved }
   permset = set of permission; { permissions in a set }
   { standard directory format }
   filptr = ^filrec; { pointer to file records }
   filrec = record

      name:   pstring; { name of file }
      size:   integer; { size of file }
      alloc:  integer; { allocation of file }
      attr:   attrset; { attributes }
      create: integer; { time of creation }
      modify: integer; { time of last modification }
      access: integer; { time of last access }
      backup: integer; { time of last backup }
      user:   permset; { user permissions }
      group:  permset; { group permissions }
      other:  permset; { other permissions }
      next:   filptr   { next entry in list }

   end;
   { environment strings }
   envptr = ^envrec; { pointer to environment record }
   envrec = packed record

      name: pstring; { name of string }
      data: pstring; { data in string }
      next: envptr { next entry in list }

   end;

procedure list(view f: string; var l: filptr); forward;
overload procedure list(view f: pstring; var  l: filptr); forward;
procedure times(var s: string; t: integer); forward;
overload function times(t: integer): pstring; forward;
procedure dates(var s: string; t: integer); forward;
overload function dates(t: integer): pstring; forward;
procedure writetime(var f: text; t: integer); forward;
overload procedure writetime(t: integer); forward;
procedure writedate(var f: text; t: integer); forward;
overload procedure writedate(t: integer); forward;
function time: integer; forward;
function local(t: integer): integer; forward;
function clock: integer; forward;
function elapsed(r: integer): integer; forward;
function validfile(view s: string): boolean; forward;
overload function validfile(view s: pstring): boolean; forward;
function validpath(view s: string): boolean; forward;
overload function validpath(view s: pstring): boolean; forward;
function wild(view s: string): boolean; forward;
overload function wild(view s: pstring): boolean; forward;
procedure getenv(view ls: string; var ds: string); forward;
overload function getenv(view ls: string): pstring; forward;
procedure setenv(view sn, sd: string); forward;
overload procedure setenv(sn: pstring; view sd: string); forward;
overload procedure setenv(view sn: string; sd: pstring); forward;
overload procedure setenv(sn, sd: pstring); forward;
procedure allenv(var el: envptr); forward;
procedure remenv(view sn: string); forward;
overload procedure remenv(view sn: pstring); forward;
procedure exec(view cmd: string); forward;
overload procedure exec(cmd: pstring); forward;
procedure exece(view cmd: string; el: envptr); forward;
overload procedure exece(cmd: pstring; el: envptr); forward;
procedure execw(view cmd: string; var e: integer); forward;
overload procedure execw(cmd: pstring; var e: integer); forward;
procedure execew(view cmd: string; el: envptr; var e: integer); forward;
overload procedure execew(cmd: pstring; el: envptr; var e: integer); forward;
procedure getcur(var fn: string); forward;
overload function getcur: pstring; forward;
procedure setcur(view fn: string); forward;
overload procedure setcur(fn: pstring); forward;
procedure brknam(view fn: string; var p, n, e: string); forward;
overload procedure brknam(view fn: string; var p, n, e: pstring); forward;
overload procedure brknam(fn: pstring; var p, n, e: pstring); forward;
procedure maknam(var fn: string; view p, n, e: string); forward;
overload function maknam(view p, n, e: string): pstring; forward;
overload function maknam(view p: string; view n: string; e: pstring): pstring; forward;
overload function maknam(view p: string; n: pstring; view e: string): pstring; forward;
overload function maknam(view p: string; n: pstring; e: pstring): pstring; forward;
overload function maknam(p: pstring; view n: string; view e: string): pstring; forward;
overload function maknam(p: pstring; view n: string; e: pstring): pstring; forward;
overload function maknam(p: pstring; n: pstring; view e: string): pstring; forward;
overload function maknam(p: pstring; n: pstring; e: pstring): pstring; forward;
procedure fulnam(var fn: string); forward;
overload function fulnam(view fn: string): pstring; forward;
procedure getpgm(var p: string); forward;
overload function getpgm: pstring; forward;
procedure getusr(var fn: string); forward;
overload function getusr: pstring; forward;
procedure setatr(view fn: string; a: attrset); forward;
overload procedure setatr(fn: pstring; a: attrset); forward;
procedure resatr(view fn: string; a: attrset); forward;
overload procedure resatr(fn: pstring; a: attrset); forward;
procedure bakupd(view fn: string); forward;
overload procedure bakupd(fn: pstring); forward;
procedure setuper(view fn: string; p: permset); forward;
overload procedure setuper(fn: pstring; p: permset); forward;
procedure resuper(view fn: string; p: permset); forward;
overload procedure resuper(fn: pstring; p: permset); forward;
procedure setgper(view fn: string; p: permset); forward;
overload procedure setgper(fn: pstring; p: permset); forward;
procedure resgper(view fn: string; p: permset); forward;
overload procedure resgper(fn: pstring; p: permset); forward;
procedure setoper(view fn: string; p: permset); forward;
overload procedure setoper(fn: pstring; p: permset); forward;
procedure resoper(view fn: string; p: permset); forward;
overload procedure resoper(fn: pstring; p: permset); forward;
procedure seterr(c: integer); forward;
procedure makpth(view fn: string); forward;
overload procedure makpth(fn: pstring); forward;
procedure rempth(view fn: string); forward;
overload procedure rempth(fn: pstring); forward;
procedure filchr(var fc: chrset); forward;
function optchr: char; forward;
function pthchr: char; forward;

private      

const

hoursec = 60*60;      { number of seconds in an hour }
daysec  = hoursec*24; { number of seconds in a day }

maxstr  = 500;        { maximum size of holding buffers (I had to make this
                        very large for large paths [sam]) }

type

bufstr  = packed array [1..maxstr] of char; { standard string buffer }

var

pthstr: bufstr; { buffer for execution path }

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

{******************************************************************************

Convert ASCII to character

Converts an ASCII 8 bit character to local character equivalents. This is
needed when the internal characters are not ASCII. If the internal characters
are ASCII, the translation will be a no-op. Note that we don't handle ISO 646
or ISO 8859-1, which are the ISO version of ASCII, and the Western European
character sets (same as Windows) respectively.

These kinds of convertions are required because the string fields in .sym files
are stored in ASCII.

Note that characters with values 128 or over are simply returned untranslated.

******************************************************************************}

function ascii2chr(b: byte): char;

var c: char; { character holder }

begin

   if b >= 128 then c := chr(b) { out of ASCII range, just return raw }
   else c := chrtrn[b]; { translate }

   ascii2chr := c { return result }

end;

{******************************************************************************

Process extended library error

Outputs an error message using the special syslib function, then halts.

******************************************************************************}

procedure error(view s: string);

var i:     integer; { index for string }
    pream: packed array [1..8] of char; { preamble string }
    p:     pstring; { pointer to string }

begin

   pream := 'Extlib: '; { set preamble }
   new(p, max(s)+8); { get string to hold }
   for i := 1 to 8 do p^[i] := pream[i]; { copy preamble }
   for i := 1 to max(s) do p^[i+8] := s[i]; { copy string }
   ss_wrterr(p^); { output string }
   dispose(p); { release storage }
   halt { end the run }

end;

{******************************************************************************

Handle windows error

Only called if the last error variable is set. The text string for the error
is output, and then the program halted.

******************************************************************************}

procedure winerr;

var e:      integer;
    es, ts: pstring;

begin

   e := sc_getlasterror;
   geterr(sc_getlasterror, ts); { get the error message }
   es := cat('*** Windows error: ', ts^); { form message }
   dispose(ts); { release temp }
   error(es^); { process error }
   dispose(es) { release message }

end;

{******************************************************************************

Place character in string

Places the given character in the space padded string buffer, with full error
checking.

******************************************************************************}

procedure plcstr(var s: string; var i: integer; c: char);

begin

   { check overflow }
   if i > max(s) then { overflow }
      error('Name too long for buffer');
   s[i] := c; { place character }
   i := i+1 { next }

end;

{******************************************************************************

Create file list

Accepts a filename, that may include wildcards. All of the matching files are
found, and a list of file entries is returned. The file entries are in standard
directory format.

The entries are allocated from general storage, and both the entry and the
filename should be disposed of by the caller when they are no longer needed.
If no files are matched, the returned list is nil.

******************************************************************************}

procedure list(view f: string;  { file to search for }
               var  l: filptr); { file list returned }

var fd:  sc_win32_find_dataa; { windows file information structure }
    i:   integer;
    hdl: integer; { handle of search }
    fp:  filptr;  { file entry pointer }
    r:   integer; { result holder }
    lp:  filptr;  { last entry pointer }
    ts:  pstring; { name holder }

begin

   l := nil; { clear destination list }
   lp := nil; { clear last pointer }
   copy(ts, f); { create a copy }
   hdl := sc_findfirstfile(ts^, fd); { find first file }
   while hdl <> -1 do begin { gather matching files }

      new(fp); { create a new file entry }
      { find the size of the filename }
      i := 1; { set 1st character }
      while fd.filename[i] <> chr(0) do i := i+1; { find last character }
      new(fp^.name, i-1); { allocate filename }
      { move filename into that }
      for i := 1 to i-1 do fp^.name^[i] := ascii2chr(ord(fd.filename[i]));
      { get file size. we are limited to about 2gb in a single file }
      if (fd.filesizehigh <> 0) or (fd.filesizelow < 0) then
         error('*** File size too large');
      fp^.size := fd.filesizelow; { set size }
      fp^.alloc := fd.filesizelow;
      fp^.attr := []; { clear attributes }
      { clear permissions to everything allowed }
      fp^.user := [pmread, pmwrite, pmdel, pmvis, pmcopy, pmren, pmexec];
      fp^.other := [pmread, pmwrite, pmdel, pmvis, pmcopy, pmren, pmexec];
      fp^.group := [pmread, pmwrite, pmdel, pmvis, pmcopy, pmren, pmexec];
      { check and set archive attribute }
      if fd.fileattributes and sc_file_attribute_archive <> 0 then
         fp^.attr := fp^.attr+[atarc];
      { check and set system attribute }
      if fd.fileattributes and sc_file_attribute_system <> 0 then
         fp^.attr := fp^.attr+[atsys];
      { check and set directory attribute }
      if fd.fileattributes and sc_file_attribute_directory <> 0 then
         fp^.attr := fp^.attr+[atdir];
      { in windows, the permissions are part of the attributes, and there are
        no permission classes. so we distribute the permission bits to all
        classes }
      { check and set writeable }
      if fd.fileattributes and sc_file_attribute_readonly <> 0 then begin

         { read only removes write, delete privledges }
         fp^.user := fp^.user-[pmwrite, pmdel];
         fp^.other := fp^.other-[pmwrite, pmdel];
         fp^.group := fp^.group-[pmwrite, pmdel]

      end;
      { check and set visable }
      if fd.fileattributes and sc_file_attribute_system = 0 then begin

         { system removes write and delete priveledges }
         fp^.user := fp^.user+[pmvis, pmdel];
         fp^.other := fp^.other+[pmvis, pmdel];
         fp^.group := fp^.group+[pmvis, pmdel]

      end;
      if fd.fileattributes and sc_file_attribute_hidden <> 0 then begin

         { hidden removes visiblity, delete, rename and copy privledges }
         fp^.user := fp^.user-[pmvis, pmdel, pmren, pmcopy];
         fp^.other := fp^.other-[pmvis, pmdel, pmren, pmcopy];
         fp^.group := fp^.group-[pmvis, pmdel, pmren, pmcopy]

      end;
      { find and flag heriarchy loops '.' and '..' }
      if compp(fp^.name^, '.') or compp(fp^.name^, '..') then
         fp^.attr := fp^.attr+[atloop];
      { convert 64 bit times to 32 bit S2000 times }
      filetimetoseconds(fd.creationtime, fp^.create);
      filetimetoseconds(fd.lastaccesstime, fp^.access);
      filetimetoseconds(fd.lastwritetime, fp^.modify);
      { clear backup, which is not available }
      fp^.backup := -maxint; 
      { insert entry to list }
      if l = nil then l := fp { insert new top }
      else lp^.next := fp; { insert next entry }
      lp := fp; { set new last }
      fp^.next := nil; { clear next }
      r := sc_findnextfile(hdl, fd); { find the next file entry }
      if r <> 1 then begin { not successful }

         r := sc_findclose(hdl); { close search handle }
         hdl := -1 { terminate search }

      end

   end;
   dispose(ts) { release string }

end;

overload procedure list(view f: pstring;  { file to search for }
                        var  l: filptr); { file list returned }

begin

   if f = nil then error('String is nil');
   list(f^, l) { perform }

end;

{******************************************************************************

Get time string padded

Converts the given time into a padded string.

******************************************************************************}

procedure times(var s: string;   { result string }
                    t: integer); { time to convert }

var h:   0..23;   { hour }
    m:   0..59;   { minute }
    sec: 0..59;   { second }
    i:   integer; { index for string }
    pm:  boolean; { am/pm flag }

procedure wrtzer(v: integer);

begin

   s[i] := chr(v div 10+ord('0'));
   i := i+1;
   s[i] := chr(v mod 10+ord('0'));
   i := i+1

end;

begin

   if max(s) < 11 then { string to small to hold result }
      error('*** String to small to hold time');
   clears(s); { clear result }
   i := 1; { set 1st string place }
   { because leap adjustments are made in terms of days, we just remove
     the days to find the time of day in seconds. this is completely
     independent of leap adjustments }
   t := t mod daysec; { find number of seconds in day }
   { if before 2000, find from remaining seconds }
   if t < 0 then t := daysec+t;
   h := t div hoursec; { find hours }
   t := t mod hoursec; { subtract hours }
   m := t div 60; { find minutes }
   sec := t mod 60; { find seconds }
   pm := false; { set am }
   if h = 0 then h := 12 { hour zero }
   else if h > 12 then begin h := h-12; pm := true end; { 1 pm to 11 pm }
   wrtzer(h); { place hour }
   if s[1] = '0' then s[1] := ' '; { clear leading zero }
   s[i] := ':';
   i := i+1;
   wrtzer(m);
   s[i] := ':';
   i := i+1;
   wrtzer(sec);
   i := i+1;
   if pm then begin

      s[i] := 'p';
      i := i+1;
      s[i] := 'm';
      i := i+1

   end else begin

      s[i] := 'a';
      i := i+1;
      s[i] := 'm';
      i := i+1

   end

end;

{******************************************************************************

Get time string

Converts the given time into a time string.

******************************************************************************}

overload function times(t: integer) { time to convert }
                        : pstring; { result }

var b: bufstr; { string buffer }
    s: pstring; { result }

begin

   times(b, t); { find time string }
   copy(s, b); { copy into result }

   times := s { return result }

end;

{******************************************************************************

Get date string padded

Converts the given date into a padded string. The current output format is
ISO 8601, or year-month-day. However, this routine should convert the date
according to the standard system settings.

******************************************************************************}

procedure dates(var  s: string;   { string to place date into }
                     t: integer); { time record to write from }

var y:     integer; { year holder }
    d:     1..31;   { day holder }
    m:     1..12;   { month holder }
    dm:    1..31;   { temp days of month holder }
    leap:  0..1;    { leap year adder }
    di:    1..13;   { day counter array index }
    yd:    1..366;  { years in day holder }
    done:  boolean; { loop complete flag }
    i, fi: integer; { index for string }

fixed 

    { compiler bug: this declaration should have worked }
    days: array [1..12] of {1..31} integer = array { days in months }

             31, { january }
             28, { february-leap day }
             31, { march }
             30, { april }
             31, { may }
             30, { june }
             31, { july }
             31, { august }
             30, { september }
             31, { october }
             30, { november }
             31  { december }

          end;
    
procedure wrtzer(v: integer);

begin

   s[i] := chr(v div 10 mod 10+ord('0'));
   i := i+1;
   s[i] := chr(v mod 10+ord('0'));
   i := i+1

end;

function leapyear(y: integer): boolean;

begin

   leapyear := (y mod 4 = 0) and (y mod 100 <> 0) or (y mod 400 = 0)

end;

begin

   if max(s) < 8 then { string to small to hold result }
      error('*** String to small to hold time');
   for fi := 1 to max(s) do s[fi] := ' '; { clear result }
   i := 1; { set 1st string place }
   if t < 0 then y := 1999 else y := 2000; { set initial year }
   done := false; { set no loop exit }
   t := abs(t); { find seconds magnitude }
   repeat

      yd := 365; { set days in this year }
      if leapyear(y) then yd := 366 { set leap year days }
      else yd := 365; { set normal year days }
      if t div daysec >= yd then begin { remove another year }

         if y >= 2000 then y := y+1 else y := y-1; { find next year }
         t := t-yd*daysec; { remove that many seconds }

      end else done := true

   until done; { until year found }
   leap := 0; { set no leap day }
   { check leap year, and set leap day accordingly }
   if leapyear(y) then leap := 1;
   t := t div daysec+1; { find days into year }
   if y < 2000 then t := 365+leap-t+1; { adjust for negative years }
   di := 1; { set 1st month }
   while di <= 12 do begin { fit months }

      dm := days[di]; { get the days of month }
      if di = 2 then dm := dm+leap; { february, add leap day }
      { check remaining day falls within month }
      if dm >= t then begin m := di; d := t; di := 13 end
      else begin t := t-dm; di := di+1 end

   end;
   wrtzer(y); { place year }
   s[i] := '-';
   i := i+1;
   wrtzer(m); { place month }
   s[i] := '-';
   i := i+1;
   wrtzer(d) { place day }

end;

{******************************************************************************

Get date string

Converts the given date into a string.

******************************************************************************}

overload function dates(t: integer) { time record to write from }
                        : pstring;  { result }

var b: bufstr; { string buffer }
    s: pstring; { result }

begin

   dates(b, t); { find date string }
   copy(s, b); { copy into result }

   dates := s { return result }

end;

{******************************************************************************

Write time

Writes the time to a given file, from a time record.

******************************************************************************}

procedure writetime(var f: text;     { file to write to }
                        t: integer); { time record to write from }

var s: packed array [1..11] of char;

begin

   times(s, t); { convert time to string form }
   write(f, s) { output }

end;

overload procedure writetime(t: integer); { time record to write from }

begin

   writetime(output, t) { perform }

end;

{******************************************************************************

Write date

Writes the date to a given file, from a time record.
Note that this routine should check and obey the international format settings
used by windows.

******************************************************************************}

procedure writedate(var f: text;     { file to write to }
                        t: integer); { time record to write from }

var s: packed array [1..8] of char;

begin

   dates(s, t); { convert date to string form }
   write(f, s) { output }

end;

overload procedure writedate(t: integer); { time record to write from }

begin

   writedate(output, t) { perform }

end;

{******************************************************************************

Find current time

Returns the current time in a standard time record.
Note that this routine should check and obey the international format settings
used by windows.

******************************************************************************}

function time: integer;

var st: sc_systemtime; { windows system format time }
    t:  integer;       { S2000 time }
    r:  integer;       { result buffer }
    ft: sc_filetime;   { 64 bit file time }

begin

   sc_getsystemtime(st); { get windows time }
   r := sc_systemtimetofiletime(st, ft); { convert to 64 bit time }
   filetimetoseconds(ft, t); { and that to 32 bit time }
   time := t { return time }

end;

{******************************************************************************

Convert to local time

Converts a GMT standard time to the local time.

******************************************************************************}

function local(t: integer) { time to convert }
               : integer;  { localized time }

var tz: sc_time_zone_information; { time zone information }
    r:  integer;                  { result buffer }
    nt: integer;                  { new time }

begin

   r := sc_gettimezoneinformation(tz); { get adjustment information }
   if r = 2 then { convert acording to daylight savings time }
      nt := t-(tz.bias+tz.daylightbias)*60
   else { convert standard time }
      nt := t-tz.bias*60;

   local := nt { return result }

end;

{******************************************************************************

Find clock tick

Finds the time in terms of "ticks". Ticks are defined to occur at 0.1ms, or
100us intervals. The rules for this counter are:

   1. The counter will rollover as much as, but not more than, each 24 hours.
   2. The counter has no specific zero point (and cannot, for example, be used
      to determine the exact time of day).

The base time of 100us is designed specifically to fit these rules. The count
will rollover each 59 hours using 31 bits of precision (the sign bit is
unused).
Note that the rules are upward compatible such that at the 64 bit precision
level, the clock actually represents a real universal time, because it then
has more than enough precision to count from 0 AD to present.
In windows, the timer is defined to be 1ms, so convertion occurs. Note that
windows itself does a convertion from a "real" tick value, so the coarseness
of the actual timer is undefined.
To perform our scaling, we discard the upper two bits of the 1ms windows
time. This is nessary to keep precision in times 10 form. This reduces the
rollover to 27.7 hours, which still fits the 24 hour requirement.

******************************************************************************}

function clock: integer;

begin

   clock := sc_gettickcount mod 100000000*10 { find tick count }

end;

{******************************************************************************

Find elapsed time

Finds the time elapsed since a reference time. The reference time should be
obtained from "clock". Rollover is properly handled, but the maximum elapsed
time that can be measured is 24 hours.

******************************************************************************}

function elapsed(r: integer); { reference time }

var t: integer;

begin

   t := clock; { get the current time }
   if t >= r then t := t-r { time has not wrapped }
   else t := maxint-r+t; { time has wrapped }
   elapsed := t { return result }

end;

{******************************************************************************

Check filename valid

Parses a MSDOS format filename from the given line. We only allow a proper
subset of Windows names, with alphabetical, digit, and '_' characters. The
primary must begin with a alphabetical character.
If the "path" flag is set, then a path is allowed for the filename. This is
identical to filename, but can tolerate a null name or last section.

******************************************************************************}

function chkfil(view s: string; path: boolean): boolean; 

label fail;

const

   { valid Windows filename characters }
   valid = ['A'..'Z', 'a'..'z', '0'..'9', '_', '?', '*'];
   leading = ['A'..'Z', 'a'..'z', '0'..'9', '_', '?', '*'];

var si:     integer; { index for filename }
    dp:     boolean; { drive parsed flag }
    ext:    boolean; { name has extention }
    nam:    boolean; { filename was parsed }
    len:    integer; { length of name }
    valfil: boolean; { filename valid }

{ process error }

procedure error;

begin

   valfil := false; { set filename not valid }
   goto fail { exit }

end;

{ check end of string }

function endstr: boolean; begin endstr := si > max(s) end;

{ check next character in string }

function chkchr: char; 

begin if endstr then chkchr := ' ' else chkchr := s[si] end;

{ get next character in string }

procedure getchr; begin if not endstr then si := si+1 end;

{ skip spaces }

procedure skpspc; begin while (chkchr = ' ') and not endstr do getchr end;

{ parse section }

procedure parsec;

{ parse character sequence }

procedure parseq;

begin

   len := 0; { set no characters processed }
   while chkchr in valid do begin { place valid character }

      getchr; { next character }
      len := len+1 { count }

   end

end;
   
begin

   { check valid leading character }
   if not (chkchr in leading) and not path then error;
   parseq; { parse primary }
   nam := true; { set name was processed }
   if chkchr = '.' then begin { extention exists }

      getchr; { next }
      parseq; { parse extention }
      ext := true { set extention found }

   end else if chkchr = ':' then begin { was drive spec }

      if dp then error; { flag invalid drive position }
      if len > 1 then error; { drive too long }
      getchr; { next }

   end

end;

begin

   valfil := true; { set filename valid }
   si := 1; { index 1st file character }
   dp := false; { set no drive parsed }
   ext := false; { set no extention processed }
   skpspc; { skip spaces }
   { check leading '.' (present directory) or '..' (parent directory) }
   if chkchr = '.' then begin

      { process special symbols, '.' or '..' }
      getchr; { skip }
      if chkchr = '.' then getchr; { skip }
      dp := true { set no drive spec allowed }

   end;
   while (chkchr in valid+['\\']) and not ext do begin

      { evaluate sections }
      nam := false; { set no name parsed }
      if chkchr = '\\' then begin { section mark }

         getchr; { next }
         dp := true { set drive spec not allowed }

      end;
      parsec; { parse filename section }
      dp := true; { set no more drive parse }
      { check null section between '\' marks }
      if (chkchr = '\\') and (len = 0) then error

   end;
   if (si = 1) or (not nam and not path) then
      error; { no characters processed }

   fail:

   chkfil := valfil { return error status }

end;

{******************************************************************************

Validate filename

Finds if the given string contains a valid filename. Returns true if so,
otherwise false.

******************************************************************************}

function validfile(view s: string) { string to validate }
                   : boolean;      { valid/invalid status }

begin

   validfile := chkfil(s, false) { return error status }

end;

overload function validfile(view s: pstring) { string to validate }
                            : boolean;      { valid/invalid status }

begin

   if s = nil then error('String is nil');
   validfile := chkfil(s^, false) { return error status }

end;

{******************************************************************************

Validate pathname

Finds if the given string contains a valid pathname. Returns true if so,
otherwise false.

******************************************************************************}

function validpath(view s: string) { string to validate }
                   : boolean;      { valid/invalid status }

begin

   validpath := chkfil(s, true) { return error status }

end;

overload function validpath(view s: pstring) { string to validate }
                            : boolean;      { valid/invalid status }

begin

   if s = nil then error('String is nil');
   validpath := chkfil(s^, true) { return error status }

end;

{******************************************************************************

Check wildcarded filename

Checks if the given filename has a wildcard character, '*' or '?' imbedded.
Also checks if the filename ends in '\', which is an implied '*.*' wildcard
on that directory.

******************************************************************************}

function wild(view s: string) { filename }
              : boolean;      { wildcard status }

var r: boolean; { result flag }
    i: integer; { index for string }

begin

   r := false; { set no wildcard found }
   if max(s) > 0 then begin { not null }

      { search and flag wildcard characters }
      for i := 1 to max(s) do if s[i] in ['?', '*'] then r := true;
      { find last non-space character }
      i := max(s);
      while (i > 1) and (s[i] = ' ') do i := i-1;
      if s[i] = '\\' then r := true { last was '\', it's wild }

   end;
   wild := r

end;

overload function wild(view s: pstring) { filename }
                       : boolean;      { wildcard status }

begin

   if s = nil then error('String is nil');
   wild := wild(s^) { return status }

end;

{******************************************************************************
    
Get environment string padded

Returns an environment string by name.

******************************************************************************}

procedure getenv(view ls: string;  { string name }
                  var  ds: string); { string buffer }

var len: integer;
    i:   integer;

begin

   { getenvironmentvariable returns zero on error, but that could also be a
     null string, so its ambiguous. }
   len := sc_getenvironmentvariable(ls, ds);
   if len > max(ds) then
      error('*** Environment string too large for buffer');
   for i := len+1 to max(ds) do ds[i] := ' ' { convert to padded string }
   
end;

overload function getenv(view ls: string) { string name }
                         : pstring;       { result }

var b: bufstr; { string buffer }
    s: pstring; { result string }

begin

   getenv(ls, b); { get environment string }
   copy(s, b); { copy into result }

   getenv := s { return result }

end;

{******************************************************************************
    
Set environment string

Sets an environment string by name.

******************************************************************************}

procedure setenv(view sn: string;  { name of string }
                 view sd: string); { value of string }

var r: boolean;

begin

   r := sc_setenvironmentvariable(sn, sd);
   if not r then winerr { process windows error }

end;

overload procedure setenv(     sn: pstring; { name of string }
                          view sd: string); { value of string }

begin

   if sn = nil then error('String is nil');
   setenv(sn^, sd)

end;

overload procedure setenv(view sn: string; { name of string }
                               sd: pstring); { value of string }

begin

   if sd = nil then error('String is nil');
   setenv(sn, sd^)

end;

overload procedure setenv(sn: pstring; { name of string }
                          sd: pstring); { value of string }

begin

   if (sn = nil) or (sd = nil) then error('String is nil');
   setenv(sn^, sd^)

end;

{******************************************************************************
    
Remove environment string

Removes an environment string by name.

******************************************************************************}

procedure remenv(view sn: string); { name of string }

var r: boolean;

begin

   r := sc_setenvironmentvariable_n(sn);
   if not r then winerr { process windows error }

end;

overload procedure remenv(view sn: pstring); { name of string }

begin

   if sn = nil then error('String is nil');
   remenv(sn^)

end;

{******************************************************************************
    
Get environment strings all

Returns a table with the entire environment string set in it.

******************************************************************************}

procedure allenv(var el: envptr); { environment table }

var evstbl: sc_evsptr; { system formatted environment string table }
    evssav: sc_evsptr; { save }
    p:      envptr;    { current env record }
    l:      envptr;    { last record }
    i1, i2: integer;   { string indexes }
    c:      integer;   { count }
    equals: boolean;   { name starts with '=' }
    
begin

   evstbl := sc_getenvironmentstrings;
   el := nil; { clear root }
   l := nil; { clear last }
   while evstbl <> nil do begin { process strings }

      new(p); { get a new env record }
      { Check name starts with '='. Some environment names have the quirk that
        they start with '=', which is not part of the name }
      equals := false; { set not '=' }
      { set '=' start status }
      if max(evstbl^.str^) > 0 then equals := evstbl^.str^[1] = '=';
      { count name string characters }
      i1 := 1+ord(equals); { start at left, or after '=' starting name }
      while (i1 < max(evstbl^.str^)) and (evstbl^.str^[i1] <> '=') do 
         i1 := i1+1;
      new(p^.name, i1-1-ord(equals)); { get a string }
      if equals then { copy without '=' at start }
         for i2 := 1 to i1-2 do p^.name^[i2] := evstbl^.str^[i2+1]
      else
         for i2 := 1 to i1-1 do p^.name^[i2] := evstbl^.str^[i2];
      i1 := i1+1; { skip '=' }
      c := max(evstbl^.str^)-i1+1; { set data string length }
      new(p^.data, c); { allocate data string }
      for i2 := 1 to c do p^.data^[i2] := evstbl^.str^[i1+i2-1]; { copy }
      p^.next := nil; { clear next }
      if el = nil then el := p; { set root }
      if l <> nil then l^.next := p; { set last link }
      l := p; { set new last }
      evssav := evstbl; { save entry }
      evstbl := evstbl^.next; { link next }
      dispose(evssav^.str); { dispose of string }
      dispose(evssav) { dispose of entry }

   end

end;

{******************************************************************************

Extract 1st word

Gets the first space terminated word from the given string. If it is quoted,
it will get all of the contents within the quotes, including spaces.

******************************************************************************}

procedure fstwrd(view s: string; { string containing word }
                 var  d: string); { word }

var i, x: integer; { string indexes }

begin

   for i := 1 to max(d) do d[i] := ' '; { clear destination }
   i := 1; { index 1st character of destination }
   x := 1; { index 1st character of source }
   while (x < max(s)) and (s[x] = ' ') do x := x+1; { skip leading spaces }
   if s[x] = '"' then begin { quoted string }

      x := x+1; { skip leading quote }
      if x <= max(s) then begin { still in valid string }

         while (x < max(s)) and (s[x] <> '"') do begin { transfer non-quote }

            plcstr(d, i, s[x]); { place character }
            x := x+1 { next }

         end;
         if s[x] <> '"' then plcstr(d, i, s[x]) { place last (missing quote) }

      end
  
   end else begin { use space delimited method }

      while (x < max(s)) and (s[x] <> ' ') do begin { transfer non-space }

         plcstr(d, i, s[x]); { place character }
         x := x+1 { next }

      end;
      if s[x] <> ' ' then plcstr(d, i, s[x]) { place last }

   end

end;

{******************************************************************************

Execute program with Windows environment

Base function for exec calls. Takes a windows format environment list.
The Windows CreateProcess does not appear to match its documentation well. To
make it work, we take the command line, separate off the command, and then
pass that as a separate parameter. We also add the .exe, which also appears
to be required.
The "working directory" is set as the current directory.

The pathing is broken, we need to add this manually.

******************************************************************************}

procedure execwin(view cmd:  string;    { command to execute }
                       el:   sc_evsptr; { environment list }
                       wait: boolean;   { wait for completion }
                  var  ec:   integer);  { return error }

var pi:      sc_process_information; { process information }
    si:      sc_startupinfoa; { startup information }
    ri:      integer; { result }
    fn:      pstring; { filespec string }
    fnb:     bufstr;  { filename working }
    p, n, e: bufstr;  { filespec components }
    cp:      pstring; { current path }
    rb:      boolean; { result }
    i:       integer;
    ps:      bufstr;  { path save }
    m:       boolean; { file found flag }
    es, ts:  pstring; { buffer for error message }
    ns:      pstring; { buffer for filename }
    cmdb:    pstring; { buffer for command line }

begin

   if len(cmd) = 0 then { null string }
      error('Command string null');
   copy(cmdb, cmd); { copy to buffer }
   pi.hprocess := 0;
   pi.hthread := 0;
   pi.dwprocessid := 0;
   pi.dwthreadid := 0;
   si.cb := 68;
   si.lpReserved := nil;
   si.lpDesktop := nil;
   si.lpTitle := nil;
   si.dwX := 0;
   si.dwY := 0;
   si.dwXSize := 0;
   si.dwYSize := 0;
   si.dwXCountChars := 0;
   si.dwYCountChars := 0;
   si.dwFillAttribute := 0;
   si.dwFlags := sc_startf_useshowwindow;
   si.wShowWindow := sc_sw_shownormal;
   si.cbReserved2 := 0;
   si.lpReserved2 := nil;
   si.hStdInput := 0;
   si.hStdOutput := 0;
   si.hStdError := 0;
   fstwrd(cmd, fnb); { get filespec from command line }
   brknam(fnb, p, n, e); { break down filespec }
   if e[1] = ' ' then copy(e, 'exe'); { add back missing command extention }
   maknam(fnb, p, n, e); { reconstruct }
   if len(p) = 0 then begin { no path provided }

      if not exists(fnb) then begin { its not the present directory }

         copy(ps, pthstr); { make a copy of the path }
         m := false; { set no match }
         while (len(ps) > 0) and not m do begin { try path components }

            i := indexp(ps, ';'); { find position of ';' in path }
            if i = 0 then begin

               copy(p, ps); { just use whole path }
               clears(ps); { remove rest of path }
               maknam(fnb, p, n, e) { create pathed name }

            end else begin { use first of path }

               extract(p, ps, 1, i-1); { get path portion }
               extract(ps, ps, i+1, len(ps)); { and remove from path }
               maknam(fnb, p, n, e) { create pathed name }

            end;
            if exists(fnb) then m := true { set found }
            
         end;
         if not m then begin

            ns := copy(n); { place name in general }
            ts := cat('File to execute ''', ns^); { form error }
            es := cat(ts^, ''' not found');
            dispose(ts); { remove temp }
            error(es^); { process error }
            dispose(es) { remove error string }

         end

      end

   end;
   fn := copy(fnb); { place filename in compatible string }
   cp := getcur; { get current path }
   if not sc_createprocess_nn(fn^, cmdb^, false, 0, el, cp^, si, pi) then
      winerr; { process extended error }
   { wait for the process to complete }
   if wait then begin { perform process wait and error check }

      ri := sc_waitforsingleobject(pi.hprocess, -1); 
      if ri = sc_WAIT_FAILED then winerr; { process error }
      rb := sc_GetExitCodeProcess(pi.hprocess, ec); { get exit code }
      if not rb then winerr { process error }

   end else ec := 0; { clear error return }
   if not sc_closehandle(pi.hthread) then winerr;
   if not sc_closehandle(pi.hprocess) then winerr;
   dispose(fn); { release command string }
   dispose(cp); { release current path string }
   dispose(cmdb) { release command buffer }

end;

{******************************************************************************

Execute program

Executes a program by name. Does not wait for the program to complete.    

******************************************************************************}

procedure exec(view cmd: string); { program name to execute }

var e: integer; { return error }

begin

   execwin(cmd, nil, false, e) { execute with no environment }

end;

overload procedure exec(cmd: pstring); { program name to execute }

var e: integer; { return error }

begin

   if cmd = nil then error('String is nil');
   execwin(cmd^, nil, false, e) { execute with no environment }

end;

{******************************************************************************

Execute program with wait

Executes a program by name. Waits for the program to complete.    

******************************************************************************}

procedure execw(view cmd: string; { program name to execute }
                var  e:   integer); { return error }

begin

   execwin(cmd, nil, true, e) { execute with no environment and wait }

end;

overload procedure execw(     cmd: pstring; { program name to execute }
                         var  e:   integer); { return error }

begin

   execwin(cmd^, nil, true, e) { execute with no environment and wait }

end;

{******************************************************************************

Translate environment

Translates the environment from IP format to Windows format.

******************************************************************************}

procedure trnenv(    el: envptr;     { IP format environment }
                 var we: sc_evsptr); { windows mode environment }

var evstbl: sc_evsptr;
    p, l:   sc_evsptr;
    i1, i2: integer;

begin

   we := nil; { clear table root }
   l := nil; { set no last }
   while el <> nil do begin { copy entries to windows format }

      new(p); { get a new string record }
      new(p^.str, max(el^.name^)+max(el^.data^)+1); { get a string }
      i1 := 1; { set output index }
      for i2 := 1 to max(el^.name^) do begin { copy name }

         p^.str^[i1] := el^.name^[i2]; { copy }
         i1 := i1+1 { next }

      end;
      p^.str^[i1] := '='; { place '=' }
      i1 := i1+1; { next }
      for i2 := 1 to max(el^.data^) do begin { copy data }

         p^.str^[i1] := el^.data^[i2]; { copy }
         i1 := i1+1 { next }

      end;
      p^.next := nil; { clear next }
      if we = nil then we := p; { set table root }
      if l <> nil then l^.next := p; { link last to next }
      l := p; { set last }
      el := el^.next { next entry }

   end

end;

{******************************************************************************

Free windows environment

Frees up a windows environment list.

******************************************************************************}

procedure frewen(we: sc_evsptr); { list to free }

var p: sc_evsptr;

begin

   { tear down list }
   while we <> nil do begin

      dispose(we^.str); { dispose of string }
      p := we; { save top entry }
      we := we^.next; { link next }
      dispose(p) { dispose top entry }

   end

end;

{******************************************************************************

Execute program with environment

Executes a program by name. Does not wait for the program to complete. Supplies
the program environment.

******************************************************************************}

procedure exece(view cmd: string;  { program name to execute }
                     el:  envptr); { environment }

var evstbl: sc_evsptr; { windows format environment table }
    e:      integer;   { return error, not used }

begin

   trnenv(el, evstbl); { translate environment }
   execwin(cmd, evstbl, false, e); { execute }
   frewen(evstbl) { now tear it back down }

end;

overload procedure exece(cmd: pstring;  { program name to execute }
                         el:  envptr); { environment }

begin

   if cmd = nil then error('String is nil');
   exece(cmd^, el)

end;

{******************************************************************************

Execute program with environment and wait

Executes a program by name. Waits for the program to complete. Supplies the
program environment.

******************************************************************************}

procedure execew(view cmd: string;   { program name to execute }
                      el:  envptr;   { environment }
                 var  e:   integer); { return error }

var evstbl: sc_evsptr;

begin

   trnenv(el, evstbl); { translate environment }
   execwin(cmd, evstbl, true, e); { execute }
   frewen(evstbl) { now tear it back down }

end;

overload procedure execew(     cmd: pstring;  { program name to execute }
                               el:  envptr;   { environment }
                          var  e:   integer); { return error }

begin

   if cmd = nil then error('String is nil');
   execew(cmd^, el, e)

end;

{******************************************************************************

Get current path

Returns the current path.

******************************************************************************}

procedure getcur(var fn: string); { buffer to get path }

var r: integer;
    i: integer;

begin

   r := sc_getcurrentdirectory(fn);
   { getcurrentdirectory returns 0 for error, which could be ambiguous. However,
     we ignore that, since having a zero length current directory should be
     impossible. }
   if r = 0 then winerr; { process windows error }
   if r > max(fn) then
      error('Current directory too long for buffer');
   for i := r+1 to max(fn) do fn[i] := ' ' { pad string }

end;

overload function getcur: pstring; { result }

var b: bufstr; { string buffer }
    s: pstring; { result }

begin

   getcur(b); { get current path }
   copy(s, b); { copy into result }

   getcur := s { return result }

end;

{******************************************************************************

Set current path

Sets the current path rom the given string.

******************************************************************************}
   
procedure setcur(view fn: string);

var b: boolean;
    ts: pstring; 

begin

   copy(ts, fn); { place filename in compatible string }
   b := sc_setcurrentdirectory(ts^);
   if not b then winerr; { process windows error }
   dispose(ts)

end;

overload procedure setcur(fn: pstring);

begin

   if fn = nil then error('String is nil');
   setcur(fn^)

end;

{******************************************************************************

Break file specification padded

Breaks a filespec down into its components, the path, name and extention.
Note that we don't validate file specifications here. Note that any part of
the file specification could be returned blank.

******************************************************************************}

procedure brknam(view fn: string; { file specification }
                 var  p:  string; { path }
                 var  n:  string; { name }
                 var  e:  string); { extention }
                 
var i, s, f, ln: integer; { string indexes }

begin

   { clear all strings }
   clears(p);
   clears(n);
   clears(e);
   ln := len(fn); { find length of string }
   if ln = 0 then error('File specification is empty');
   s := 1; { set 1st character source }
   { skip spaces }
   while (fn[s] = ' ') and (s < ln) do s := s+1;
   { find last '\' or ':', that will mark the path end }
   f := 0;
   for i := 1 to ln do if (fn[i] = '\\') or (fn[i] = ':') then f := i;
   if f <> 0 then begin { there is a path }

      { If the path ends in '\', then remove it. This will normalize path
        specifications. }
      if fn[f] = '\\' then extract(p, fn, s, f-1) { place path }
      else extract(p, fn, s, f);
      s := f+1 { reset next character }

   end;
   { extract '.' and '..' as special cases }
   if (ln = s) and (fn[s] = '.') then copy(n, '.') { '.' }
   else begin

      if (ln = s+1) and (fn[s] = '.') and (fn[s+1] = '.') then
         copy(n, '..') { '..' }
      else begin

         { find last '.', that will mark the extention }
         f := 0;
         for i := s to ln do if fn[i] = '.' then f := i;
         if f <> 0 then begin { there is an extention }

            extract(n, fn, s, f-1); { place name }
            s := f+1; { reset to after "." }
            extract(e, fn, s, ln) { get the rest as an extention }

         end else begin { no extention }

            { just place the rest as the name, and leave extention blank }
            if s <= ln then extract(n, fn, s, ln)

         end

      end

   end

end;

overload procedure brknam(view fn: string;   { file specification }
                          var  p:  pstring;  { path }
                          var  n:  pstring;  { name }
                          var  e:  pstring); { extention }

var pb, nb, eb: bufstr; { string buffers }

begin

   brknam(fn, pb, nb, eb); { break spec }
   copy(p, pb); { place strings }
   copy(n, nb);
   copy(e, eb)

end;

overload procedure brknam(     fn: pstring;  { file specification }
                          var  p:  pstring;  { path }
                          var  n:  pstring;  { name }
                          var  e:  pstring); { extention }

begin

   if fn = nil then error('String is nil');
   brknam(fn^, p, n, e)

end;

{******************************************************************************

Make specification padded

Creates a file specification from its components, the path, name and extention.
We make sure that the path is properly terminated with ':' or '\' before
concatenating.

******************************************************************************}

procedure maknam(var fn: string;  { file specification to build }
                 view p: string;  { path }
                 view n: string;  { name }
                 view e: string); { extention }

var i:   integer; { index for string }
    fsi: integer; { index for output filename }

{ concatenate without leading space }

procedure catnls(var d: string; view s: string; var p: integer);

var i, f, ln: integer;
    buff: bufstr;

begin

   ln := len(s); { find length }
   f := 0; { clear found }
   { find first non-space position }
   for i := 1 to ln do if (s[i] <> ' ') and (f = 0) then f := i;
   if f <> 0 then begin { found }

      { check to long for result }
      if ln-f+1+p > max(fn) then error('Name too long for buffer');
      extract(buff, s, f, ln); { place contents }
      insert(d, buff, p);
      p := p+len(buff) { advance position } 

   end
  
end;

begin

   clears(fn); { clear output string }
   fsi := 1; { set 1st output character }
   catnls(fn, p, fsi); { place path }
   { check path properly terminated }
   i := len(p); { find length }
   if i <> 0 then { not null }
      if p[i] <> '\\' then catnls(fn, '\\', fsi); { terminate path }
   catnls(fn, n, fsi); { place name }
   if len(e) > 0 then begin { there is an extention }

      catnls(fn, '.', fsi); { place '.' }
      catnls(fn, e, fsi) { place extention }

   end
         
end;

overload function maknam(view p:  string; { path }
                         view n:  string; { name }
                         view e:  string) { extention }
                         : pstring;       { result }

var b: bufstr; { string buffer }
    s: pstring; { result }

begin

   maknam(b, p, n, e); { build file specification }
   copy(s, b); { copy into result }

   maknam := s { return result }

end;

overload function maknam(view p:  string; { path }
                         view n:  string; { name }
                              e:  pstring) { extention }
                         : pstring;       { result }

begin

   if e = nil then error('String is nil');
   maknam := maknam(p, n, e^)

end;

overload function maknam(view p:  string; { path }
                              n:  pstring; { name }
                         view e:  string) { extention }
                         : pstring;       { result }

begin

   if n = nil then error('String is nil');
   maknam := maknam(p, n^, e)

end;

overload function maknam(view p:  string; { path }
                              n:  pstring; { name }
                              e:  pstring) { extention }
                         : pstring;       { result }

begin

   if (n = nil) or (e = nil) then error('String is nil');
   maknam := maknam(p, n^, e^)

end;

overload function maknam(     p:  pstring; { path }
                         view n:  string; { name }
                         view e:  string) { extention }
                         : pstring;       { result }

begin

   if p = nil then error('String is nil');
   maknam := maknam(p^, n, e)

end;

overload function maknam(     p:  pstring; { path }
                         view n:  string;  { name }
                              e:  pstring) { extention }
                         : pstring;       { result }

begin

   if (p = nil) or (e = nil) then error('String is nil');
   maknam := maknam(p^, n, e^)

end;

overload function maknam(     p:  pstring; { path }
                              n:  pstring;  { name }
                         view e:  string) { extention }
                         : pstring;       { result }

begin

   if (p = nil) or (n = nil) then error('String is nil');
   maknam := maknam(p^, n^, e)

end;

overload function maknam(p: pstring; { path }
                         n: pstring; { name }
                         e: pstring) { extention }
                         : pstring;  { result }

begin

   if (p = nil) or (n = nil) or (e = nil) then error('String is nil');
   maknam := maknam(p^, n^, e^)

end;

{******************************************************************************

Make full file specification padded

If the given file specification has a default path (the current path), then
the current path is added to it. Essentially "normalizes" file specifications.
No validity check is done. Garbage in, garbage out.

******************************************************************************}

procedure fulnam(var fn: string); { file specification }

var p, n, e, ps: bufstr;  { filespec components }
    l:           integer; { length }
    i:           integer; { index }

begin       

   brknam(fn, p, n, e); { break spec down }
   { if filename is a special file '.' or '..', wash as a directory }
   if (compp(n, '.') or compp(n, '..')) and (e[1] = ' ') then begin

      { its '.' or '..', find equivalent path }
      getcur(ps); { save current path }
      setcur(fn); { set candidate path }
      getcur(fn); { get washed path }
      setcur(ps) { reset old path }

   end else begin { find equivalent path }

      { If the leading character of the path was '\' and the path is empty,
        then its a \file form, which is a file or directory in the root.
        These references are ambiguous. We look for this situation, and
        replace the leading '\' here. }
      i := 1; { find the first non-space character }
      while (fn[i] = ' ') and (i < max(fn)) do i := i+1;
      if (fn[i] = '\\') and (len(p) = 0) then copy(p, '\\'); 
      { check path is blank }
      l := len(p); { get path length }
      { if the path is blank, then default to current }
      if l = 0 then getcur(p) { just get current path }
      else begin { wash path }

         { If the path was just a drive letter, selecting it will not move
           the current path at all, because in Windows/DOS a drive letter does
           not affect the current location on that drive. We defeat this by
           adding a path marker to the drive spec. }
         if p[l] = ':' then p[l+1] := '\\';
         getcur(ps); { save current path }
         setcur(p); { set candidate path }
         getcur(p); { get washed path }
         setcur(ps) { reset old path }

      end;
      maknam(fn, p, n, e) { reassemble }

   end

end;

{******************************************************************************

Make full file specification

If the given file specification has a default path (the current path), then
the current path is added to it. Essentially "normalizes" file specifications.
No validity check is done. Garbage in, garbage out.

******************************************************************************}

overload function fulnam(view fn: string) { input file specification }
                         : pstring;       { result }

var b: bufstr; { string buffer }
    s: pstring; { result }

begin

   copy(b, fn); { copy spec }
   fulnam(b); { convert }
   copy(s, b); { copy into result }

   fulnam := s { return result }

end;

{******************************************************************************

Get program path padded

There is no direct call for program path. So we get the command line, and
extract the program path from that.

******************************************************************************}

procedure getpgm(var p: string);

var cp:   pstring; { command line holder }
    cb:   bufstr;  { command buffer }
    n, e: bufstr;  { path components }
    path: bufstr;  { execution path }
    i:    integer; { index for path }
    f:    boolean; { path found }

begin

   cp := sc_getcommandline; { get the command line }
   fstwrd(cp^, cb); { get command }
   brknam(cb, p, n, e); { break off the path }
   if len(p) = 0 then begin { no path provided, we must search for it }

      { try current directory }
      getcur(p); { get current path }
      maknam(cb, p, n, 'exe'); { construct name with that path }
      if not exists(cb) then begin { try search path }

         getenv('path', path);
         f := false; { set path not found }
         while (len(path) > 0) and not f do begin { search path }

            i := indexp(path, ';'); { find next path separator }
            if i = 0 then begin { none, the rest is the path }

               copy(p, path); { place all in path }
               clears(path) { clear the path }

            end else begin { break off next segment }

               extract(p, path, 1, i-1); { place path }
               extract(path, path, i+1, len(path)) { extract the rest as remainer }

            end;
            maknam(cb, p, n, 'exe'); { construct name with that path }
            f := exists(cb) { check that exists }

         end;
         if not f then error('Cannot determine program path')

      end

   end

end;

overload function getpgm: pstring;

var b: bufstr; { string buffer }
    s: pstring; { result }

begin

   getpgm(b); { get program path }
   copy(s, b); { copy into result }

   getpgm := s { return result }

end;

{******************************************************************************

Get user path padded

There is no direct call for user path. We create it from the environment
variables as follows.

1. If there is a "home", "userhome" or "userdir" string, the path is taken from
that.

2. If there is a "user" or "username" string, the path becomes "\user\name"
(no drive).

3. If none of these environmental variables are found, the user path is
returned identical to the program path.

The caller should check if the path exists. If not, then the program path
should be used instead, or the current path as required. The filenames used
with program and user paths should be unique in case they end up in the same
directory.

Note: Windows XP standard is to consider the user path to be:

\documents and settings\<username>\Application data\<program name>

******************************************************************************}

procedure getusr(var fn: string);

var b, b1: bufstr; { buffer for result }

begin

   getenv('home', b);
   if b[1] = ' ' then begin { not found }

      getenv('userhome', b);
      if b[1] = ' ' then begin { not found }

         getenv('userdir', b);
         if b[1] = ' ' then begin { not found }

            getenv('user', b);
            if b[1] <> ' ' then begin { path that }

               b1 := b; { copy }
               copy(b, '\\user\\'); { set prefix }
               cat(b, b1) { combine }

            end else begin { not found }   

               getenv('username', b);
               if b[1] <> ' ' then begin { path that }

                  b1 := b; { copy }
                  copy(b, '\\user\\'); { set prefix }
                  cat(b, b1) { combine }

               end else getpgm(b) { all fails, set to program path }

            end

         end

      end

   end;
   copy(fn, b) { place result }

end;           

overload function getusr: pstring;

var b: bufstr; { string buffer }
    s: pstring; { result }

begin

   getusr(b); { get path padded }
   copy(s, b); { copy into result }

   getusr := s { result }

end;

{******************************************************************************

Set attributes on file

Sets any of several attributes on a file. Set directory attribute is not
possible. This is done with makpth.

******************************************************************************}

procedure setatr(view fn: string;   { file to set attributes on }
                      a:  attrset); { attribute set }

var fa: integer; { attribute words }
    r:  boolean; { result holder }

begin

   fa := sc_getfileattributes(fn); { get existing attributes on file }
   if fa < 0 then winerr; { error, process }
   { built attributes equivalent word }
   fa := 0;
   if atarc in a then fa := fa or sc_FILE_ATTRIBUTE_ARCHIVE;
   if atsys in a then fa := fa or sc_FILE_ATTRIBUTE_SYSTEM;
   r := sc_setfileattributes(fn, fa); { set attributes }
   if not r then winerr { error, process }

end;

overload procedure setatr(fn: pstring;   { file to set attributes on }
                          a:  attrset); { attribute set }

begin

   if fn = nil then error('String is nil');
   setatr(fn^, a)

end;

{******************************************************************************

Reset attributes on file

Resets any of several attributes on a file. Reset directory attribute is not
possible.

******************************************************************************}

procedure resatr(view fn: string;   { file to set attributes on }
                      a:  attrset); { attribute set }

var fa: integer; { attribute words }
    r:  boolean; { result holder }

begin

   fa := sc_getfileattributes(fn); { get existing attributes on file }
   if fa < 0 then winerr; { error, process }
   { built attributes equivalent word }
   fa := 0;
   if atarc in a then fa := fa and not sc_FILE_ATTRIBUTE_ARCHIVE;
   if atsys in a then fa := fa and not sc_FILE_ATTRIBUTE_SYSTEM;
   r := sc_setfileattributes(fn, fa); { set attributes }
   if not r then winerr { error, process }

end;

overload procedure resatr(fn: pstring;  { file to set attributes on }
                          a:  attrset); { attribute set }

begin

   if fn = nil then error('String is nil');
   resatr(fn^, a)

end;

{******************************************************************************

Reset backup time

There is no backup time in DOS/Windows. Instead, we reset the archive bit,
which effectively means "back this file up now".

******************************************************************************}

procedure bakupd(view fn: string);

begin

   setatr(fn, [atarc])

end;

overload procedure bakupd(fn: pstring);

begin

   if fn = nil then error('String is nil');
   setatr(fn^, [atarc])

end;

{******************************************************************************

Set user permissions

In DOS/Windows, there is only one set of permissions, which are actually
considered to be attributes (what you can do to the file is considered the
same as an attrbute of the file). User permissions are paramount, and other
permissions are inoperative.

******************************************************************************}

procedure setuper(view fn: string; p: permset);

var fa: integer; { attribute words }
    r:  boolean; { result holder }

begin

   fa := sc_getfileattributes(fn); { get existing attributes on file }
   if fa < 0 then winerr; { error, process }
   { built attributes equivalent word }
   fa := 0;
   if pmwrite in p then fa := fa and not sc_FILE_ATTRIBUTE_READONLY;
   if pmvis in p then begin

      { remove hidden and system bits, if set }
      if fa and sc_FILE_ATTRIBUTE_HIDDEN <> 0 then 
         fa := fa-sc_FILE_ATTRIBUTE_HIDDEN;
      if fa and sc_FILE_ATTRIBUTE_SYSTEM <> 0 then 
         fa := fa-sc_FILE_ATTRIBUTE_SYSTEM

   end;
   r := sc_setfileattributes(fn, fa); { set attributes }
   if not r then winerr { error, process }

end;

overload procedure setuper(fn: pstring; p: permset);

begin

   if fn = nil then error('String is nil');
   setuper(fn^, p)

end;

{******************************************************************************

Reset user permissions

Resets user permissions.

******************************************************************************}

procedure resuper(view fn: string; p: permset);

var fa: integer; { attribute words }
    r:  boolean; { result holder }

begin

   fa := sc_getfileattributes(fn); { get existing attributes on file }
   if fa < 0 then winerr; { error, process }
   { built attributes equivalent word }
   fa := 0;
   if pmwrite in p then fa := fa or sc_FILE_ATTRIBUTE_READONLY;
   if pmvis in p then fa := fa or sc_FILE_ATTRIBUTE_HIDDEN;
   r := sc_setfileattributes(fn, fa); { set attributes }
   if not r then winerr { error, process }

end;

overload procedure resuper(fn: pstring; p: permset);

begin

   if fn = nil then error('String is nil');
   resuper(fn^, p)

end;

{******************************************************************************

Set group permissions

There are no group permissions. This is a no-op.

******************************************************************************}

procedure setgper(view fn: string; p: permset);

var c:  char; { dummies }
    ps: permset;

begin

   c := fn[1]; { shut up compiler errors }
   ps := p

end;

overload procedure setgper(fn: pstring; p: permset);

var c:  char; { dummies }
    ps: permset;

begin

   if fn = nil then error('String is nil');
   c := fn^[1]; { shut up compiler errors }
   ps := p

end;

{******************************************************************************

Reset group permissions

There are no group permissions. This is a no-op.

******************************************************************************}

procedure resgper(view fn: string; p: permset);

var c:  char; { dummies }
    ps: permset;

begin

   c := fn[1]; { shut up compiler errors }
   ps := p

end;

overload procedure resgper(fn: pstring; p: permset);

var c:  char; { dummies }
    ps: permset;

begin

   if fn = nil then error('String is nil');
   c := fn^[1]; { shut up compiler errors }
   ps := p

end;

{******************************************************************************

Set other (global) permissions

There are no other permissions. This is a no-op.

******************************************************************************}

procedure setoper(view fn: string; p: permset);

var c:  char; { dummies }
    ps: permset;

begin

   c := fn[1]; { shut up compiler errors }
   ps := p

end;

overload procedure setoper(fn: pstring; p: permset);

var c:  char; { dummies }
    ps: permset;

begin

   if fn = nil then error('String is nil');
   c := fn^[1]; { shut up compiler errors }
   ps := p

end;

{******************************************************************************

Reset other (global) permissions

There are no other permissions. This is a no-op.

******************************************************************************}

procedure resoper(view fn: string; p: permset);

var c:  char; { dummies }
    ps: permset;

begin

   c := fn[1]; { shut up compiler errors }
   ps := p

end;

overload procedure resoper(fn: pstring; p: permset);

var c:  char; { dummies }
    ps: permset;

begin

   if fn = nil then error('String is nil');
   c := fn^[1]; { shut up compiler errors }
   ps := p

end;

{******************************************************************************

Set program error code

Sets the return error code for the entire program (main and threads). The
value of the code is not defined, other than:

0:    No error
<>0:  Error encountered

******************************************************************************}

procedure seterr(c: integer);

begin

   windows_exit_code := c { place exit code }

end;

{******************************************************************************

Make path

Create a new path. Only one new level at a time may be created.

******************************************************************************}

procedure makpth(view fn: string);

var r: boolean; { result }
    ts: pstring; 

begin

   copy(ts, fn); { place filename in compatible string }
   r := sc_CreateDirectory_n(ts^); { create the directory }
   if not r then winerr; { process error }
   dispose(ts)

end;

overload procedure makpth(fn: pstring);

begin

   if fn = nil then error('String is nil');
   makpth(fn^)

end;

{******************************************************************************

Remove path

Removes a path. Only one new level at a time may be deleted. The path must be
empty.

******************************************************************************}

procedure rempth(view fn: string);

var r:  boolean; { result }
    ts: pstring; 

begin

   copy(ts, fn); { place filename in compatible string }
   r := sc_RemoveDirectory(ts^); { create the directory }
   if not r then winerr; { process error }
   dispose(ts)

end;

overload procedure rempth(fn: pstring);

begin

   if fn = nil then error('String is nil');
   rempth(fn^)

end;

{******************************************************************************

Find valid filename characters

Returns the set of characters allowed in a filespecification. This allows a
specification to be gathered by the user.

******************************************************************************}

procedure filchr(var fc: chrset);

var b: byte;

begin

   fc := []; { start with a null set }
   { add everything in ascii from space to '~' }
   for b := 33 to 126 do fc := fc+[ascii2chr(b)];
   fc := fc-['"', '/'] { remove quotes, option character }

end;

{******************************************************************************

Find option character

Returns the character used to introduce a command line option.
In windows/dos this is "/".

******************************************************************************}

function optchr: char;

begin

   optchr := '/'

end;

{******************************************************************************

Find path separator character

Returns the character used to separate path components.
In windows/dos this is "\".

******************************************************************************}

function pthchr: char;

begin

   pthchr := '\\'

end;

begin

   getenv('path', pthstr) { load up the current path }

end.
