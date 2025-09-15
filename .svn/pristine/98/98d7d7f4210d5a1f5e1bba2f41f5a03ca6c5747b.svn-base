{*******************************************************************************
*                                                                              *
*                       UNIX EXTENDED FUNCTION LIBRARY                         *
*                                                                              *
*                           Copyright (C) 1996                                 *
*                                                                              *
*                               S. A. MOORE                                    *
*                                                                              *
* Contains various system oriented library functions, including files,         *
* directories, time, program execution, evironment, and random numbers.        *
* This implementation is specific to the Unix system, but extlib tends to      *
* have processing elements that are universal.                                 *
*                                                                              *
*******************************************************************************}

module extlib(output);

uses stddef,
     wrapper,
     syslib,
     unixsup,
     strlib;

type 

   { attributes }
   attribute = (atexec,  { is an executable file type }
                atarc,   { has been archived since last modification }
                atsys,   { is a system special file }
                atdir);  { is a directory special file }
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
   filrec = packed record

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
procedure timesp(var s: string; t: integer); forward;
procedure times(var s: pstring; t: integer); forward;
procedure datesp(var s: string; t: integer); forward;
procedure dates(var s: pstring; t: integer); forward;
procedure writetime(var f: text; t: integer); forward;
procedure writedate(var f: text; t: integer); forward;
function time: integer; forward;
function local(t: integer): integer; forward;
function clock: integer; forward;
function elapsed(r: integer): integer; forward;
function valid(view s: string): boolean; forward;
function validp(view s: string): boolean; forward;
function wild(view s: string): boolean; forward;
procedure getenvp(view ls: string; var ds: string); forward;
procedure getenv(view ls: string; var ds: pstring); forward;
procedure setenv(view sn, sd: string); forward;
procedure allenv(var el: envptr); forward;
procedure remenv(view sn: string); forward;
procedure exec(view cmd: string); forward;
procedure exece(view cmd: string; el: envptr); forward;
procedure execw(view cmd: string; var e: integer); forward;
procedure execew(view cmd: string; el: envptr; var e: integer); forward;
procedure setcur(view fn: string); forward;
procedure getcurp(var fn: string); forward;
procedure getcur(var fn: pstring); forward;
procedure brknamp(view fn: string; var p, n, e: string); forward;
procedure brknam(view fn: string; var p, n, e: pstring); forward;
procedure maknamp(var fn: string; view p, n, e: string); forward;
procedure maknam(var fn: pstring; view p, n, e: string); forward;
procedure fulnamp(var fn: string); forward;
procedure fulnam(view fn: string; var nn: pstring); forward;
procedure getpgmp(var p: string); forward;
procedure getpgm(var p: pstring); forward;
procedure getusrp(var fn: string); forward;
procedure getusr(var fn: pstring); forward;
procedure setatr(view fn: string; a: attrset); forward;
procedure resatr(view fn: string; a: attrset); forward;
procedure bakupd(view fn: string); forward;
procedure setuper(view fn: string; p: permset); forward;
procedure resuper(view fn: string; p: permset); forward;
procedure setgper(view fn: string; p: permset); forward;
procedure resgper(view fn: string; p: permset); forward;
procedure setoper(view fn: string; p: permset); forward;
procedure resoper(view fn: string; p: permset); forward;
procedure seterr(c: integer); forward;
procedure makpth(view fn: string); forward;
procedure rempth(view fn: string); forward;
procedure filchr(var fc: chrset); forward;
function optchr: char; forward;
function pthchr: char; forward;

private      

const

hoursec = 60*60;      { number of seconds in an hour }
daysec  = hoursec*24; { number of seconds in a day }
yearsec = daysec*365; { number of seconds in year }
unixadj = 30*yearsec+7*daysec; { Unix time adjustment for 1970 }

maxstr  = 500;        { maximum size of holding buffers (I had to make this
                        very large for large paths [sam]) }

type

bufstr  = packed array [1..maxstr] of char; { standard string buffer }

var

pthstr: bufstr;     { buffer for execution path }
ep:     sc_stabptr; { unix environment string table }
ei:     integer;    { index for string table }
si:     integer;    { index for strings }
envlst: envptr;     { our environment list }
p:      envptr;     { environment entry pointer }

{*******************************************************************************

Process string library error

Outputs an error message using the special syslib function, then halts.

*******************************************************************************}

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

{*******************************************************************************

Handle Unix error

Looks up the given error number to find a message, then prints the message
as an error.
Note that error numbers are usually passed back as negative numbers by Unix, so
they should be negated before calling this routine.

*******************************************************************************}

procedure unixerr;

var es, ts: pstring;

begin

   geterr(sc_errno, ts); { get the error message }
   cat(es, 'Unix: ', ts^); { form message }
   dispose(ts); { release temp }
   error(es^); { process error }
   dispose(es) { release message }

end;

{*******************************************************************************

Place character in string

Places the given character in the space padded string buffer, with full error
checking.

*******************************************************************************}

procedure plcstr(var s: string; var i: integer; c: char);

begin

   { check overflow }
   if i > max(s) then { overflow }
      error('Name too long for buffer');
   s[i] := c; { place character }
   i := i+1 { next }

end;

{*******************************************************************************

Create file list

Accepts a filename, that may include wildcards. All of the matching files are
found, and a list of file entries is returned. The file entries are in standard
directory format.
The entries are allocated from general storage, and both the entry and the
filename should be disposed of by the caller when they are no longer needed.
If no files are matched, the returned list is nil.

*******************************************************************************}

procedure list(view f: string;  { file to search for }
               var  l: filptr); { file list returned }

var dr:      sc_dirent; { Unix directory record }
    fd:      integer;   { directory file descriptor }
    r, rd:   integer;   { result code }
    sr:      sc_sstat;  { stat() record }
    fp:      filptr;    { file entry pointer }
    lp:      filptr;    { last entry pointer }
    i:       integer;   { name index }
    p, n, e: bufstr;    { filename components }
    fn:      bufstr;    { holder for directory name }
    dn:      bufstr;    { holder for directory entry }

{ match with wildcards at the given a and b positions. we use shortest string
  first matching }

function match(view a, b: string; ia, ib: integer): boolean;

var m: boolean;

begin

   m := true; { default to matches }
   while (ia < max(a)) and (ib < max(b)) and m do begin { match characters }

      if a[ia] = '*' then begin { multicharacter wildcard, go searching }

         { skip all wildcards in match expression name. For each '*' or
           '?', we skip one character in the matched name. The idea being
           that '*' means 1 or more matched characters }
         while (ia < max(a)) and ((a[ia] = '?') or (a[ia] = '*')) do begin

            ia := ia+1; { next character }
            ib := ib+1

         end;
         { recursively match to string until we find a match for the rest
           or run out of string }
         while (ib < max(b)) and not match(a, b, ia, ib) do ib := ib+1;
         if ib >= max(b) then m := false; { didn't match, set false }
         ib := max(b) { terminate }
         
      end else if (a[ia] <> b[ib]) and (a[ia] <> '?') then 
         m := false; { fail match }
      if m then begin

         ia := ia+1; { next character }
         ib := ib+1

      end

   end;
   match := m

end;
   
begin

   l := nil; { clear destination list }
   lp := nil; { clear last pointer }
   brknamp(f, p, n, e); { break up filename }
   { check wildcards in path }
   if (indexp(p, '*') <> 0) or (indexp(p, '?') <> 0) then
      error('Path cannot contain wildcards');
   { construct name of containing directory }
   maknamp(fn, p, '.', '');
   fd := sc_open(fn, sc_o_rdonly, 0); { open the directory }
   if fd < 0 then unixerr; { process unix open error }
   maknamp(fn, '', n, e); { reform name without path }
   repeat { read directory entries }

      rd := sc_readdir(fd, dr, 1);
      if (rd < 0) then unixerr; { process unix error }
      if rd = 1 then begin { valid next }

         { copy to standard string }
         clears(dn); { clear it }
         i := 1; { set 1st character }
         while (i < sc_dirlen) and (dr.d_name[i] <> chr(0)) do begin

            dn[i] := dr.d_name[i]; { copy character }
            i := i+1 { next }

         end;
         if match(fn, dn, 1, 1) then begin { matching filename, add to list }

            new(fp); { create a new file entry }
            r := sc_stat(dr.d_name, sr); { get stat structure on file }
            if r < 0 then unixerr; { process unix error }
            { file information in stat record, translate to our format }
            copysp(fp^.name, dn); { place filename }
            fp^.size := sr.st_size; { place size }
            { there is actually a real unix allocation, but I haven't figgured out
              how to calculate it from block/blocksize }
            fp^.alloc := sr.st_size; { place allocation }
            fp^.attr := []; { clear attributes }
            { clear permissions to all is allowed }
            fp^.user := [pmread, pmwrite, pmexec, pmdel, pmvis, pmcopy, pmren];
            fp^.other := [pmread, pmwrite, pmexec, pmdel, pmvis, pmcopy, pmren];
            fp^.group := [pmread, pmwrite, pmexec, pmdel, pmvis, pmcopy, pmren];
            { check and set directory attribute }
            if sr.st_mode and sc_s_ifdir <> 0 then fp^.attr := fp^.attr+[atdir];
            { check and set any system special file }
            if sr.st_mode and sc_s_ififo <> 0 then fp^.attr := fp^.attr+[atsys];
            if sr.st_mode and sc_s_ifchr <> 0 then fp^.attr := fp^.attr+[atsys];
            if sr.st_mode and sc_s_ifblk <> 0 then fp^.attr := fp^.attr+[atsys];
            { check hidden. in Unix, this is done with a leading '.'. We remove
              visiblity priveledges }
            if dr.d_name[1] = '.' then begin

               fp^.user := fp^.user-[pmvis];
               fp^.group := fp^.group-[pmvis];
               fp^.other := fp^.other-[pmvis];

            end;
            { check and set executable attribute. Unix has separate executable
              permissions for each permission type, we set executable if any of
              them are true }
            if sr.st_mode and sc_s_iexec <> 0 then
               fp^.attr := fp^.attr+[atexec];
            { set execute permissions to user }
            if sr.st_mode and sc_s_iexec = 0 then
               fp^.user := fp^.user-[pmexec];
            { set read permissions to user }
            if sr.st_mode and sc_s_iread = 0 then
               fp^.user := fp^.user-[pmread];
            { set write permissions to user }
            if sr.st_mode and sc_s_iwrite = 0 then
               fp^.user := fp^.user-[pmwrite];
            { set execute permissions to group }
            if sr.st_mode and sc_s_igexec = 0 then
               fp^.group := fp^.group-[pmexec];
            { set read permissions to group }
            if sr.st_mode and sc_s_igread = 0 then
               fp^.group := fp^.group-[pmread];
            { set write permissions to group }
            if sr.st_mode and sc_s_igwrite = 0 then
               fp^.group := fp^.group-[pmwrite];
            { set execute permissions to other }
            if sr.st_mode and sc_s_ioexec = 0 then
               fp^.other := fp^.group-[pmexec];
            { set read permissions to other }
            if sr.st_mode and sc_s_ioread = 0 then fp^.other := fp^.group-[pmread];
            { set write permissions to other }
            if sr.st_mode and sc_s_iowrite = 0 then fp^.other := fp^.group-[pmwrite];
            { set times }
            fp^.create := sr.st_ctime-unixadj;
            fp^.modify := sr.st_mtime-unixadj;
            fp^.access := sr.st_atime-unixadj;
            fp^.backup := -maxint; { no backup time for Unix }
            { insert entry to list }
            if l = nil then l := fp { insert new top }
            else lp^.next := fp; { insert next entry }
            lp := fp; { set new last }
            fp^.next := nil; { clear next }
      
         end

      end

   until rd <> 1;
   r := sc_close(fd);
   if (r < 0) then unixerr { process unix error }
          
end;

{*******************************************************************************

Get time string padded

Converts the given time into a padded string.

*******************************************************************************}

procedure timesp(var s: string;   { result string }
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
   for i := 1 to max(s) do s[i] := ' '; { clear result }
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

{*******************************************************************************

Get time string

Converts the given time into a time string.

*******************************************************************************}

procedure times(var s: pstring;  { result string }
                    t: integer); { time to convert }

var b: bufstr; { string buffer }

begin

   timesp(b, t); { find time string }
   copysp(s, b) { copy into result }

end;

{*******************************************************************************

Get date string padded

Converts the given date into a padded string.

*******************************************************************************}

procedure datesp(var  s: string;   { string to place date into }
                      t: integer); { time record to write from }

var y:    integer; { year holder }
    d:    1..31;   { day holder }
    m:    1..12;   { month holder }
    dm:   1..31;   { temp days of month holder }
    leap: 0..1;    { leap year adder }
    di:   1..13;   { day counter array index }
    yd:   1..366;  { years in day holder }
    done: boolean; { loop complete flag }
    i:    integer; { index for string }

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
   for i := 1 to max(s) do s[i] := ' '; { clear result }
   i := 1; { set 1st string place }
   if t < 0 then y := 1999 else y := 2000; { set initial year }
   done := false; { set no loop exit }
   t := abs(t); { find seconds magnitude }
   repeat

      yd := 365; { set days in this year }
      if leapyear(y) then yd := 366 { set leap year days }
      else yd := 365; { set normal year days }
      if t div daysec > yd then begin { remove another year }

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
   s[i] := '/';
   i := i+1;
   wrtzer(m); { place month }
   s[i] := '/';
   i := i+1;
   wrtzer(d) { place day }

end;

{*******************************************************************************

Get date string

Converts the given date into a string.

*******************************************************************************}

procedure dates(var s: pstring;  { string to place date into }
                    t: integer); { time record to write from }

var b: bufstr; { string buffer }

begin

   datesp(b, t); { find date string }
   copysp(s, b) { copy into result }

end;

{*******************************************************************************

Write time

Writes the time to a given file, from a time record.

*******************************************************************************}

procedure writetime(var f: text;     { file to write to }
                        t: integer); { time record to write from }

var s: packed array [1..11] of char;

begin

   timesp(s, t); { convert time to string form }
   write(f, s) { output }

end;

{*******************************************************************************

Write date

Writes the date to a given file, from a time record.
Note that this routine should check and obey the international format settings
used by windows.

*******************************************************************************}

procedure writedate(var f: text;     { file to write to }
                        t: integer); { time record to write from }

var s: packed array [1..8] of char;

begin

   datesp(s, t); { convert date to string form }
   write(f, s) { output }

end;

{*******************************************************************************

Find current time

Finds the current time as an S2000 integer.

*******************************************************************************}

function time: integer;

var tv: sc_timeval;  { record to get time }
    tz: sc_timezone; { record to get timezone }
    r:  integer;     { return value }

begin

   r := sc_gettimeofday(tv, tz); { get time info }
   if r < 0 then unixerr; { process unix error }
   time := tv.tv_sec-unixadj { return S2000 time }

end;

{*******************************************************************************

Convert to local time

Converts a GMT standard time to the local time.
Note: tried to use the system local time adjustment routine, it bombs.
Currently hard wired for PST.

*******************************************************************************}

function local(t: integer) { time to convert }
               : integer;  { localized time }

var tv: sc_timeval;  { record to get time }
    tz: sc_timezone; { record to get timezone }
    r:  integer;     { return value }

begin

   r := sc_gettimeofday(tv, tz); { get time info }
   if r < 0 then unixerr; { process unix error }
   local := t-tz.tz_minuteswest*60 { adjust for minutes west }

end;

{*******************************************************************************

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

*******************************************************************************}

function clock: integer;

var tv: sc_timeval;  { record to get time }
    tz: sc_timezone; { record to get timezone }
    r:  integer;     { return value }

begin

   r := sc_gettimeofday(tv, tz); { get time info }
   if r < 0 then unixerr; { process unix error }
   { for Unix, the time is kept in microseconds since the start of the last
     second. we find the number of 100usecs, then add 48 hours worth of
     seconds from standard time }
   clock := tv.tv_usec div 100+tv.tv_sec mod (2*daysec)*10000

end;

{*******************************************************************************

Find elapsed time

Finds the time elapsed since a reference time. The reference time should be
obtained from "clock". Rollover is properly handled, but the maximum elapsed
time that can be measured is 24 hours.

*******************************************************************************}

function elapsed(r: integer); { reference time }

var t: integer;

begin

   t := clock; { get the current time }
   if t >= r then t := t-r { time has not wrapped }
   else t := maxint-r+t; { time has wrapped }
   elapsed := t { return result }

end;

{*******************************************************************************

Validate filename

Finds if the given string contains a valid filename. Returns true if so,
otherwise false.
There is not much that is not valid in Unix. We only error on a filename that
is null or all blanks

*******************************************************************************}

function valid(view s: string) { string to validate }
               : boolean;      { valid/invalid status }

var r: boolean; { good/bad result }

begin

   r := true; { set result good by default }
   if lenp(s) = 0 then r := false; { no filename exists }
   valid := r { return error status }

end;

{*******************************************************************************

Validate pathname

Finds if the given string contains a valid pathname. Returns true if so,
otherwise false.
There is not much that is not valid in Unix. We only error on a filename that
is null or all blanks

*******************************************************************************}

function validp(view s: string) { string to validate }
               : boolean;      { valid/invalid status }

var r: boolean; { good/bad result }

begin

   r := true; { set result good by default }
   if lenp(s) = 0 then r := false; { no filename exists }
   validp := r { return error status }

end;

{*******************************************************************************

Check wildcarded filename

Checks if the given filename has a wildcard character, '*' or '?' imbedded.
Also checks if the filename ends in '/', which is an implied '*.*' wildcard
on that directory.

*******************************************************************************}

function wild(view s: string) { filename }
              : boolean;      { wildcard status }

var r:  boolean; { result flag }
    i:  integer; { index for string }
    ln: integer; { length of string }

begin

   ln := lenp(s); { find length }
   r := false; { set no wildcard found }
   if ln > 0 then begin { not null }

      { search and flag wildcard characters }
      for i := 1 to ln do if s[i] in ['?', '*'] then r := true;
      if s[ln] = '/' then r := true { last was '/', it's wild }

   end;
   wild := r

end;

{*******************************************************************************

Find environment string

Finds the environment string by name, and returns that. Returns nil if not
found.    

*******************************************************************************}

procedure fndenv(view esn: string;  { string name }
                  var  ep: envptr); { returns environment pointer }

var p: envptr; { pointer to environment entry }

begin

   p := envlst; { index top of environment list }
   ep := nil; { set no string found }
   while (p <> nil) and (ep = nil) do begin { traverse }

      if compp(esn, p^.name^) then ep := p { found }
      else p := p^.next { next string }

   end
   
end;

{*******************************************************************************
    
Get environment string padded

Returns an environment string by name.

*******************************************************************************}

procedure getenvp(view ls: string;  { string name }
                  var  ds: string); { string buffer }

var p: envptr; { pointer to environment entry }

begin

   clears(ds); { clear result }
   fndenv(ls, p); { find environment string }
   if p <> nil then copyp(ds, p^.data^) { place string }
   
end;

{*******************************************************************************
    
Get environment string

Returns an environment string by name.

*******************************************************************************}

procedure getenv(view ls: string;   { string name }
                 var  ds: pstring); { string buffer }

var b: bufstr; { string buffer }

begin

   getenvp(ls, b); { get environment string }
   copysp(ds, b) { copy into result }

end;

{*******************************************************************************
    
Set environment string

Sets an environment string by name.

*******************************************************************************}

procedure setenv(view sn: string;  { name of string }
                 view sd: string); { value of string }

var p: envptr; { pointer to environment entry }

begin

   fndenv(sn, p); { find environment string }
   if p <> nil then begin { found }

      dispose(p^.data); { release last contents }
      copysp(p^.data, sd) { create new data string }

   end else begin { create brand new entry }

      new(p); { get a new environment entry }
      p^.next := envlst; { push onto environment list }
      envlst := p;
      copysp(p^.name, sn); { set name }
      copysp(p^.data, sd) { place data }

   end

end;

{*******************************************************************************
    
Remove environment string

Removes an environment string by name.

*******************************************************************************}

procedure remenv(view sn: string); { name of string }

var p, l: envptr; { pointer to environment entry }

begin

   fndenv(sn, p); { find environment string }
   if p <> nil then begin { found }

      { remove entry from list }
      if envlst = p then envlst := p^.next { gap from list top }
      else begin { search }

         { find last entry that indexes this one }
         l := envlst; { index top of list }
         while (l^.next <> p) and (l <> nil) do l := l^.next; { search }
         if l = nil then error('System error: bad environment list');
         l^.next := p^.next { gap out of list }

      end;
      dispose(p^.name); { release name }
      dispose(p^.data); { release data }
      dispose(p) { release entry }

   end
         
end;

{*******************************************************************************
    
Get environment strings all

Returns a table with the entire environment string set in it.

*******************************************************************************}

procedure allenv(var el: envptr); { environment table }

var p, lp: envptr; { environment pointers }

begin

   { copy current environment list }
   lp := envlst; { index top of environment list }
   el := nil; { clear destination }
   while lp <> nil do begin { copy entries }

      new(p);{ create a new entry }
      p^.next := el; { push onto list }
      el := p;
      copy(p^.name, lp^.name^); { place name }
      copy(p^.data, lp^.data^); { place data }
      lp := lp^.next { next entry }

   end

end;

{*******************************************************************************

Execute program

Executes a program by name. Does not wait for the program to complete.    

*******************************************************************************}

procedure exec(view cmd: string); { program name to execute }

var r:       integer; { result code }
    pid:     integer; { task id for child process }
    cn:      bufstr;  { buffer for command filename }
    cmds:    bufstr;  { buffer for commands }
    wc:      integer; { word count in command }
    p, n, e: bufstr;  { filename components }
    pc:      bufstr;  { path copy }
    av, ev:  sc_stabptr;
    i:       integer;

begin

   wc := words(cmd); { find number of words in command }
   if wc = 0 then error('Command is empty');
   extwordsp(cn, cmd, 1, 1); { get the command verb }
   if not exists(cn) then begin { does not exist in current form }

      { perform pathing search }
      brknamp(cn, p, n, e); { break down the name }
      if (p[1] = ' ') and (pthstr[1] <> ' ') then begin

         copyp(pc, pthstr); { make a copy of the path }
         trimp(pc, pc); { make sure left aligned }
         while pc[1] <> ' ' do begin { match path components }

            i := indexp(pc, ':'); { find next path separator }
            if i = 0 then begin { none left, use entire remaining }

               copyp(p, pc); { none left, use entire remaining }
               clears(pc) { clear the rest }

            end else begin { copy partial }

               extractp(p, pc, 1, i-1); { get left side to path }
               extractp(pc, pc, i+1, lenp(pc)); { remove from path }
               trimp(pc, pc) { make sure left aligned }

            end;
            maknamp(cn, p, n, e); { create filename }
            if exists(cn) then clears(pc) { found, indicate stop }

         end;
         if not exists(cn) then error('Command does not exist')
            
      end else error('Command does not exist')

   end;
   { on fork, the child is going to see a zero return, and the parent will
     get the process id. Although this seems dangerous, forked processes
     are truly independent, and so don't care what language is running }
   pid := sc_fork; { start subprocess }
   if pid = 0 then begin { we are the child }

      r := sc_execve(cn, av^, ev^); { execute directory }
      if r < 0 then unixerr; { process unix error }
      error('Should not continue from execute')

   end

end;

{*******************************************************************************

Execute program with wait

Executes a program by name. Waits for the program to complete.    

*******************************************************************************}

procedure execw(view cmd: string; { program name to execute }
                var  e:   integer); { return error }

begin

end;

{*******************************************************************************

Execute program with environment

Executes a program by name. Does not wait for the program to complete. Supplies
the program environment.

*******************************************************************************}

procedure exece(view cmd: string;  { program name to execute }
                     el:  envptr); { environment }

begin

end;

{*******************************************************************************

Execute program with environment and wait

Executes a program by name. Waits for the program to complete. Supplies the
program environment.

*******************************************************************************}

procedure execew(view cmd: string;   { program name to execute }
                      el:  envptr;   { environment }
                 var  e:   integer); { return error }

begin

end;

{*******************************************************************************

Get current path padded

Returns the current path in the given padded string.

*******************************************************************************}

procedure getcurp(var fn: string); { buffer to get path }

var r: integer; { result code }

begin

   r := sc_getcwd(fn); { get the current path }
   if r < 0 then unixerr { process unix error }
   
end;

{*******************************************************************************

Get current path

Returns the current path in the given string.

*******************************************************************************}

procedure getcur(var fn: pstring); { buffer to get path }

var b: bufstr; { string buffer }

begin

   getcurp(b); { get current path }
   copysp(fn, b) { copy into result }

end;

{*******************************************************************************

Set current path

Sets the current path rom the given string.

*******************************************************************************}
   
procedure setcur(view fn: string);

var r: integer; { result code }
    s: pstring; { buffer for name }

begin

   r := sc_chdir(fn); { change current directory }
   if r < 0 then unixerr; { process unix error }
   dispose(s) { release string }

end;

{*******************************************************************************

Break file specification padded

Breaks a filespec down into its components, the path, name and extention.
Note that we don't validate file specifications here. Note that any part of
the file specification could be returned blank.

For Unix, we trim leading and trailing spaces, but leave any embedded spaces
or ".".

The path is straightforward, and consists of any number of /x sections. The
presense of a trailing "/" without a name means the entire thing gets parsed
as a path, including any embedded spaces or "." characters.

Unix allows any number of "." characters, so we consider the extention to be
only the last such section, which could be null. Unix does not technically
consider "." to be a special character, but if the brknam and maknam procedures
are properly paired, it will effectively be treated the same as if the "."
were a normal character.

*******************************************************************************}

procedure brknamp(view fn: string; { file specification }
                  var  p:  string; { path }
                  var  n:  string; { name }
                  var  e:  string); { extention }
                 
var i, s, f, ln, t: integer; { string indexes }

begin

   { clear all strings }
   clears(p);
   clears(n);
   clears(e);
   ln := lenp(fn); { find length of string }
   if ln = 0 then error('File specification is empty');
   s := 1; { set 1st character source }
   { skip spaces }
   while (fn[s] = ' ') and (s < ln) do s := s+1;
   { find last '/', that will mark the path end }
   f := 0;
   for i := 1 to ln do if fn[i] = '/' then f := i;
   if f <> 0 then begin { there is a path }

      extractp(p, fn, s, f); { place path }
      s := f+1 { reset next character }

   end;
   { skip any leading '.' in name }
   t := s;
   while (fn[t] = '.') and (t <= ln) do t := t+1;
   { find last '.', that will mark the extention }
   f := 0;
   for i := t to ln do if fn[i] = '.' then f := i;
   if f <> 0 then begin { there is an extention }

      extractp(n, fn, s, f-1); { place name }
      s := f+1; { reset to after "." }
      extractp(e, fn, s, ln) { get the rest as an extention }

   end else begin { no extention }

      { just place the rest as the name, and leave extention blank }
      if s <= ln then extractp(n, fn, s, ln)

   end

end;

{*******************************************************************************

Break file specification

Breaks a filespec down into its components, the path, name and extention.
Note that we don't validate file specifications here. Note that any part of
the file specification could be returned blank.

*******************************************************************************}

procedure brknam(view fn: string; { file specification }
                 var  p:  pstring; { path }
                 var  n:  pstring; { name }
                 var  e:  pstring); { extention }

var pb, nb, eb: bufstr; { string buffers }

begin

   brknamp(fn, pb, nb, eb); { break spec }
   copysp(p, pb); { place strings }
   copysp(n, nb);
   copysp(e, eb)

end;

{*******************************************************************************

Make specification padded

Creates a file specification from its components, the path, name and extention.
We make sure that the path is properly terminated with ':' or '\' before
concatenating.

*******************************************************************************}

procedure maknamp(var fn: string;  { file specification to build }
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

   ln := lenp(s); { find length }
   f := 0; { clear found }
   { find first non-space position }
   for i := 1 to ln do if (s[i] <> ' ') and (f = 0) then f := i;
   if f <> 0 then begin { found }

      { check to long for result }
      if ln-f+1+p > max(fn) then error('Name too long for buffer');
      extractp(buff, s, f, ln); { place contents }
      insertp(d, buff, p);
      p := p+lenp(buff) { advance position } 

   end
  
end;

begin

   clears(fn); { clear output string }
   fsi := 1; { set 1st output character }
   catnls(fn, p, fsi); { place path }
   { check path properly terminated }
   i := lenp(p); { find length }
   if i <> 0 then { not null }
      if p[i] <> '/' then catnls(fn, '/', fsi); { terminate path }
   catnls(fn, n, fsi); { place name }
   if lenp(e) > 0 then begin { there is an extention }

      catnls(fn, '.', fsi); { place '.' }
      catnls(fn, e, fsi) { place extention }

   end
         
end;

{*******************************************************************************

Make specification

Creates a file specification from its components, the path, name and extention.
We make sure that the path is properly terminated with '/' before
concatenating.

*******************************************************************************}

procedure maknam(var  fn: pstring; { file specification to build }
                 view p:  string;  { path }
                 view n:  string;  { name }
                 view e:  string); { extention }

var b: bufstr; { string buffer }

begin

   maknamp(b, p, n, e); { build file specification }
   copysp(fn, b) { copy into result }

end;

{*******************************************************************************

Make full file specification padded

If the given file specification has a default path (the current path), then
the current path is added to it. Essentially "normalizes" file specifications.
No validity check is done. Garbage in, garbage out.

*******************************************************************************}

procedure fulnamp(var fn: string); { file specification }

var p, n, e, ps: bufstr;  { filespec components }

begin       

   brknamp(fn, p, n, e); { break spec down }
   { if the path is blank, then default to current }
   if p[1] = ' ' then p[1] := '.';
   if (compp(n, '.') or compp(n, '..')) and (e[1] = ' ') then begin

      { its '.' or '..', find equivalent path }
      getcurp(ps); { save current path }
      setcur(fn); { set candidate path }
      getcurp(fn); { get washed path }
      setcur(ps) { reset old path }

   end else begin

      getcurp(ps); { save current path }
      setcur(p); { set candidate path }
      getcurp(p); { get washed path }
      setcur(ps); { reset old path }
      maknamp(fn, p, n, e) { reassemble }

   end

end;

{*******************************************************************************

Make full file specification

If the given file specification has a default path (the current path), then
the current path is added to it. Essentially "normalizes" file specifications.
No validity check is done. Garbage in, garbage out.

*******************************************************************************}

procedure fulnam(view fn: string;   { input file specification }
                 var  nn: pstring); { output file specification }

var b: bufstr; { string buffer }

begin

   copyp(b, fn); { copy spec }
   fulnamp(b); { convert }
   copysp(nn, b) { copy into result }

end;

{*******************************************************************************

Get program path padded

There is no direct call for program path. So we get the command line, and
extract the program path from that.

*******************************************************************************}

procedure getpgmp(var p: string);

var cp:   pstring; { store for command line }
    ci:   integer; { index for command line }
    pi:   integer; { index for path }
    pn:   bufstr;  { program name holder }
    n, e: bufstr;  { name component holders }

function chkcmd: char;

var c: char;

begin

   if ci <= max(cp^) then c := cp^[ci]
   else c := ' ';
   chkcmd := c

end;

begin

   clears(pn); { clear result }
   sc_getcmd(cp); { get commandline }
   ci := 1; { set 1st command line position }
   pi := 1; { set 1st path position }
   { skip spaces in command line }
   while (chkcmd = ' ') and (ci <= max(cp^)) do ci := ci+1;
   { place program name and path }
   while (chkcmd <> ' ') and (ci <= max(cp^)) do begin
      
      plcstr(pn, pi, chkcmd);
      ci := ci+1

   end;
   dispose(cp); { release command line }
   fulnamp(pn); { clean that }
   brknamp(pn, p, n, e) { extract path from that }

end;

{*******************************************************************************

Get program path

There is no direct call for program path. So we get the command line, and
extract the program path from that.

*******************************************************************************}

procedure getpgm(var p: pstring);

var b: bufstr; { string buffer }

begin

   getpgmp(b); { get program path }
   copysp(p, b) { copy into result }

end;

{*******************************************************************************

Get user path padded

There is no direct call for user path. We create it from the environment
variables as follows.

1. If there is a "home", "userhome" or "userdir" string, the path is taken from
that.

2. If there is a "user" or "username" string, the path becomes "/home/name"
(no drive).

3. If none of these environmental variables are found, the user path is
returned identical to the program path.

The caller should check if the path exists. If not, then the program path
should be used instead, or the current path as required. The filenames used
with program and user paths should be unique in case they end up in the same
directory.

*******************************************************************************}

procedure getusrp(var fn: string);

var b, b1: bufstr; { buffer for result }

begin

   getenvp('home', b);
   if b[1] = ' ' then begin { not found }

      getenvp('userhome', b);
      if b[1] = ' ' then begin { not found }

         getenvp('userdir', b);
         if b[1] = ' ' then begin { not found }

            getenvp('user', b);
            if b[1] <> ' ' then begin { path that }

               b1 := b; { copy }
               copyp(b, '/home/'); { set prefix }
               catp(b, b1) { combine }

            end else begin { not found }   

               getenvp('username', b);
               if b[1] <> ' ' then begin { path that }

                  b1 := b; { copy }
                  copyp(b, '/home/'); { set prefix }
                  catp(b, b1) { combine }

               end else getpgmp(b) { all fails, set to program path }

            end

         end

      end

   end;
   copyp(fn, b) { place result }

end;           

{*******************************************************************************

Get user path

As getuserp, but returns normal string.

*******************************************************************************}

procedure getusr(var fn: pstring);


var b: bufstr; { string buffer }

begin

   getusrp(b); { get path padded }
   copysp(fn, b) { copy into result }

end;

{*******************************************************************************

Set attributes on file

Sets any of several attributes on a file. Set directory attribute is not
possible. This is done with makpth.

*******************************************************************************}

procedure setatr(view fn: string;   { file to set attributes on }
                      a:  attrset); { attribute set }

begin

   { no unix attributes can be set }

end;

{*******************************************************************************

Reset attributes on file

Resets any of several attributes on a file. Reset directory attribute is not
possible.

*******************************************************************************}

procedure resatr(view fn: string;   { file to set attributes on }
                      a:  attrset); { attribute set }

begin

   { no unix attributes can be reset }

end;

{*******************************************************************************

Reset backup time

There is no backup time in Unix. Instead, we reset the archive bit,
which effectively means "back this file up now".

*******************************************************************************}

procedure bakupd(view fn: string);

begin

   setatr(fn, [atarc])

end;

{*******************************************************************************

Set user permissions

Sets user permisions

*******************************************************************************}

procedure setuper(view fn: string; p: permset);

var sr: sc_sstat; { stat() record }
    r:  integer;  { result code }

begin

   r := sc_stat(fn, sr); { get stat structure on file }
   if r < 0 then unixerr; { process unix error }
   sr.st_mode := sr.st_mode and &777; { mask permissions }
   if pmread in p then sr.st_mode := sr.st_mode or sc_s_iread; { set read }
   if pmwrite in p then sr.st_mode := sr.st_mode or sc_s_iwrite; { set write }
   if pmexec in p then sr.st_mode := sr.st_mode or sc_s_iexec; { set execute }
   r := sc_chmod(fn, sr.st_mode); { set mode }
   if r < 0 then unixerr { process unix error }

end;

{*******************************************************************************

Reset user permissions

Resets user permissions.

*******************************************************************************}

procedure resuper(view fn: string; p: permset);

var sr: sc_sstat; { stat() record }
    r:  integer;  { result code }

begin

   r := sc_stat(fn, sr); { get stat structure on file }
   if r < 0 then unixerr; { process unix error }
   sr.st_mode := sr.st_mode and &777; { mask permissions }
   if pmread in p then sr.st_mode := sr.st_mode and not sc_s_iread; { set read }
   if pmwrite in p then 
      sr.st_mode := sr.st_mode and not sc_s_iwrite; { set write }
   if pmexec in p then 
      sr.st_mode := sr.st_mode and not sc_s_iexec; { set execute }
   r := sc_chmod(fn, sr.st_mode); { set mode }
   if r < 0 then unixerr { process unix error }

end;

{*******************************************************************************

Set group permissions

Sets group permissions.

*******************************************************************************}

procedure setgper(view fn: string; p: permset);

var sr: sc_sstat; { stat() record }
    r:  integer;  { result code }

begin

   r := sc_stat(fn, sr); { get stat structure on file }
   if r < 0 then unixerr; { process unix error }
   sr.st_mode := sr.st_mode and &777; { mask permissions }
   if pmread in p then sr.st_mode := sr.st_mode or sc_s_igread; { set read }
   if pmwrite in p then sr.st_mode := sr.st_mode or sc_s_igwrite; { set write }
   if pmexec in p then sr.st_mode := sr.st_mode or sc_s_igexec; { set execute }
   r := sc_chmod(fn, sr.st_mode); { set mode }
   if r < 0 then unixerr { process unix error }

end;

{*******************************************************************************

Reset group permissions

Resets group permissions.

*******************************************************************************}

procedure resgper(view fn: string; p: permset);

var sr: sc_sstat; { stat() record }
    r:  integer;  { result code }

begin

   r := sc_stat(fn, sr); { get stat structure on file }
   if r < 0 then unixerr; { process unix error }
   sr.st_mode := sr.st_mode and &777; { mask permissions }
   if pmread in p then sr.st_mode := sr.st_mode and not sc_s_igread; { set read }
   if pmwrite in p then sr.st_mode := sr.st_mode and not sc_s_igwrite; { set write }
   if pmexec in p then sr.st_mode := sr.st_mode and not sc_s_igexec; { set execute }
   r := sc_chmod(fn, sr.st_mode); { set mode }
   if r < 0 then unixerr { process unix error }

end;

{*******************************************************************************

Set other (global) permissions

Sets other permissions.

*******************************************************************************}

procedure setoper(view fn: string; p: permset);

var sr: sc_sstat; { stat() record }
    r:  integer;  { result code }

begin

   r := sc_stat(fn, sr); { get stat structure on file }
   if r < 0 then unixerr; { process unix error }
   sr.st_mode := sr.st_mode and &777; { mask permissions }
   if pmread in p then sr.st_mode := sr.st_mode or sc_s_ioread; { set read }
   if pmwrite in p then sr.st_mode := sr.st_mode or sc_s_iowrite; { set write }
   if pmexec in p then sr.st_mode := sr.st_mode or sc_s_ioexec; { set execute }
   r := sc_chmod(fn, sr.st_mode); { set mode }
   if r < 0 then unixerr { process unix error }

end;

{*******************************************************************************

Reset other (global) permissions

Resets other permissions.

*******************************************************************************}

procedure resoper(view fn: string; p: permset);

var sr: sc_sstat; { stat() record }
    r:  integer;  { result code }

begin

   r := sc_stat(fn, sr); { get stat structure on file }
   if r < 0 then unixerr; { process unix error }
   sr.st_mode := sr.st_mode and &777; { mask permissions }
   if pmread in p then
      sr.st_mode := sr.st_mode and not sc_s_ioread; { set read }
   if pmwrite in p then
      sr.st_mode := sr.st_mode and not sc_s_iowrite; { set write }
   if pmexec in p then
      sr.st_mode := sr.st_mode and not sc_s_ioexec; { set execute }
   r := sc_chmod(fn, sr.st_mode); { set mode }
   if r < 0 then unixerr { process unix error }

end;

{*******************************************************************************

Set program error code

Sets the return error code for the entire program (main and threads). The
value of the code is not defined, other than:

0:    No error
<>0:  Error encountered

*******************************************************************************}

procedure seterr(c: integer);

begin

   wrapper_exit_code := c { place exit code }

end;

{*******************************************************************************

Make path

Create a new path. Only one new level at a time may be created.

*******************************************************************************}

procedure makpth(view fn: string);

var r: integer; { result code }

begin

   { make directory, give all permissions allowable }
   r := sc_mkdir(fn, sc_s_iread or sc_s_iwrite or sc_s_iexec or 
                     sc_s_igread or sc_s_igwrite or sc_s_igexec or
                     sc_s_ioread or sc_s_iowrite or sc_s_ioexec);
   if r < 0 then unixerr { process unix error }

end;

{*******************************************************************************

Remove path

Create a new path. Only one new level at a time may be deleted.

*******************************************************************************}

procedure rempth(view fn: string);

var r: integer; { result code }

begin

   r := sc_rmdir(fn); { remove directory }
   if r < 0 then unixerr { process unix error }

end;

{*******************************************************************************

Find valid filename characters

Returns the set of characters allowed in a filespecification. This allows a
specification to be gathered by the user.
Virtually anything can be stuffed into a Unix name. We don't diferentiate
shell special characters because names can be escaped (quoted), and shells
have different special characters anyway.
As a result, we only exclude the file characters that would cause problems
with common IP procedures:

1. Space, because most command line names are space delimited.

2. Non printing, so we don't create names that cannot be seen as well as
removed.

3. '-', because that is the Unix option character.

4. '#', because that is the IP universal option character.

Unfortunately, this can create the inability to access filenames with spaces.
For such reasons, the program will probally have to determine its own
specials in these cases.

*******************************************************************************}

procedure filchr(var fc: chrset);

begin

   fc := ['!'..'~']-['-', '#'];

end;

{*******************************************************************************

Find option character

Returns the character used to introduce a command line option.
In unix this is "-". Unix sometimes uses "+" for add/subtract option, but this
is overly cute and not common.

*******************************************************************************}

function optchr: char;

begin

   optchr := '-'

end;

{******************************************************************************

Find path separator character

Returns the character used to separate filename path sections.
In windows/dos this is "\".

******************************************************************************}

function pthchr: char;

begin

   pthchr := '\\'

end;

begin

   { Unix gives us a read only copy of the environment, so we copy to a string
     list and perform our own reads and writes on that }
   envlst := nil; { clear environment strings }
   ep := sc_allenv; { get unix environment pointers }
   for ei := 1 to max(ep^) do begin { copy environment strings }

      new(p); { get a new environment entry }
      p^.next := envlst; { push onto environment list }
      envlst := p;
      si := index(ep^[ei]^, '='); { find location of '=' }
      if si = 0 then error('Invalid environment string format');
      extract(p^.name, ep^[ei]^, 1, si-1); { get the name string }
      extract(p^.data, ep^[ei]^, si+1, max(ep^[ei]^)) { get the data string }

   end;
   dispose(ep); { release environment table }
   getenvp('path', pthstr); { load up the current path }
   trimp(pthstr, pthstr) { make sure left aligned }

end.
