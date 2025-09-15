{******************************************************************************
*                                                                             *
*                           PASCAL SUPPORT LIBRARY                            *
*                                                                             *
*                             1995/9 S. A. Moore                              *
*                                                                             *
* Provides the support functions for Pascal I/O functions.                    *
* Paslib is implemented entirely in valid IP pascal, and calls Syslib system  *
* independent calls. It should never need change based on the type of system  *
* we are running on.                                                          *
*                                                                             *
* Notes:                                                                      *
*                                                                             *
* 1. The real output routine should use a faster exponent extraction method.  *
*                                                                             *
* Change log:                                                                 *
*                                                                             *
* 3/2004 [sam] Rewrite was not clearing the file to zero length. Changed      *
* sequence to close and reopen the file, with a delete if the file had a      *
* name.                                                                       *
*                                                                             *
* 3/2004 [sam] Fixed problem where eoln was being indicated twice because     *
* ps_lbatxt was recursing to find next character after eoln, and encountering *
* the eof, which caused a "pseudo-eoln" to be generated.                      *
*                                                                             *
* 2007/12/29 [sam] ps_rdreal use of rdint to get both the mantissa and the    *
* sign was resulting in inaccurate reals as read with a negative. Apparently  *
* negating, then using that in the fraction calculation was affecting the     *
* the result. The solution was to have ps_rdreal parse its own sign, and      *
* apply that at the end of the routine.                                       *
*                                                                             *
* 2008/06/16 [sam] Added aliasing for system file references. This solves     *
* the issue of having two different modules accessing the same file, but      *
* getting different flags.                                                    *
*                                                                             *
******************************************************************************}

module paslib;

uses syslib; { window interface calls }

{ external access section }

const ps_maxopn = 100; { maximum number of open files }

type 

   ps_filnum = 0..ps_maxopn; { file access number }
   { error codes, starting with runtime errors }
   ps_errcod = (ps_ecnull,   { no error }
                ps_ecrngchk, { range check }
                ps_eclenmat, { array length match }
                ps_eccasvnf, { case value not found }
                ps_ezdiv,    { zero divide }
                ps_eivop,    { invalid operands }
                ps_enpdref,  { nil pointer dereference }
                ps_erelovf,  { real overflow }
                ps_erelunf,  { real underflow }
                ps_erelflt,  { other real processing fault }
                ps_etagact,  { tag value for enclosing variant not active }
                { internal errors to this module }
                ps_ecftbful, { file table full }
                ps_ecfilopn, { file is open }
                ps_ecfilass, { file already has name }
                ps_ecfilnop, { file not open }
                ps_ecfilmod, { file not in correct mode }
                ps_ecinvfld, { invalid field specification }
                ps_ecinvrl,  { invalid real number }
                ps_ecinvfrc, { invalid fraction specification }
                ps_ecintfmt, { invalid integer format }
                ps_ecinttl,  { integer value overflow }
                ps_ecrlfmt,  { invalid real format }
                ps_eceof,    { end of file }
                ps_ecpos,    { invalid file position }
                ps_ecfault); { system fault }

procedure ps_abort; forward;
procedure ps_error(e: ps_errcod); forward;
procedure ps_assign(var fn: ps_filnum; view nm: string); forward;
procedure ps_resfil(var fn: ps_filnum; bs: integer); forward;
procedure ps_restxt(var fn: ps_filnum; bs: integer); forward;
procedure ps_rwtfil(var fn: ps_filnum; bs: integer); forward;
procedure ps_rwttxt(var fn: ps_filnum; bs: integer); forward;
procedure ps_update(var fn: ps_filnum; bs: integer); forward;
procedure ps_appfil(var fn: ps_filnum; bs: integer); forward;
procedure ps_apptxt(var fn: ps_filnum; bs: integer); forward;
procedure ps_close(var fn: ps_filnum); forward;
procedure ps_putfil(var fn: ps_filnum); forward;
function ps_lbafil(var fn: ps_filnum): gbtptr; forward;
procedure ps_getfil(var fn: ps_filnum); forward;
procedure ps_wrtfil(var fn: ps_filnum; view ba: bytarr); forward;
procedure ps_rdfil(var fn: ps_filnum; var ba: bytarr); forward;
function ps_eoffil(var fn: ps_filnum): boolean; forward;
function ps_fillen(var fn: ps_filnum): integer; forward;
function ps_filloc(var fn: ps_filnum): integer; forward;
procedure ps_posfil(var fn: ps_filnum; p: integer); forward;
function ps_lbatxt(var fn: ps_filnum): gbtptr; forward;
procedure ps_gettxt(var fn: ps_filnum); forward;
function ps_eoftxt(var fn: ps_filnum): boolean; forward;
function ps_chkeol(var fn: ps_filnum): boolean; forward;
procedure ps_rdeol(var tf: text); forward;
procedure ps_wrtchr(var tf: text; f: integer; c:  char); forward;
procedure ps_wrteol(var tf: text); forward;
procedure ps_pagtxt(var tf: text); forward;
procedure ps_rdchr(var tf: text; var c: char); forward;
procedure ps_wrtstr(var tf: text; view s: string); forward;
procedure ps_wrtstrf(var tf: text; f: integer; view s:  string); forward;
procedure ps_wrtbol(var tf: text; b: boolean); forward;
procedure ps_wrtblf(var tf: text; f: integer; b: boolean); forward;
procedure ps_wrtint(var tf: text; f: integer; i: integer); forward;
procedure ps_wrtreal(var tf: text; f:  integer; r:  real); forward;
procedure ps_wrtrlf(var tf: text; fl: integer; fr: integer; r:  real); forward;
procedure ps_rdint(var tf: text; var i:  integer); forward;
procedure ps_rdreal(var tf: text; var r:  real); forward;
procedure ps_setstd; forward;
procedure ps_assert(view msg: string); forward;

{ private section }

private

label 88, { module terminate }
      99; { final exit }

const maxpwr = 1000000000; { maximum power of 10 that fits into integer }

type 

   filptr = ^filrec; { pointer to file record }
   filrec = record

      mode: (fmund, fmread, fmwrite); { file open mode }
      nam:  pstring;   { name of file }
      full: boolean;   { buffer full flag }
      buf:  gbtptr;    { location of file buffer }
      { file type }
      typ:  (ftbin,    { binary }
             fttxt);   { text }
      hdl:  ss_filhdl; { file handle }
      bgn:  boolean;   { beginning of file }
      eol:  boolean;   { currently in eoln sequence }
      bcr:  boolean;   { buffer character is cr }
      blf:  boolean;   { buffer character is lf }
      leol: boolean;   { last sequence was eoln }
      lcr:  boolean;   { last character was cr }
      llf:  boolean;   { last character was lf }
      als:  ps_filnum; { aliased to another file }

   end;

var

   opnfil: array [1..ps_maxopn] of filptr; { open files table }
   erract: boolean; { error being processed }
   tmpcnt: integer; { temporary files counter }
   ofi:    1..ps_maxopn; { index for files table }
   stdflg: boolean; { standard behavior flag }
   nfmptr: gbtptr; { null file marker pointer }
   trnchr: array [char] of byte; { character to ascii translation array }
   ti:     0..255; { translation table index }

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

Convert character to ASCII

Converts a character to an ASCII value. This is needed when the internal
characters are not ASCII. If the internal characters are ASCII, the translation
will be a no-op. Note that we don't handle ISO 646 or ISO 8859-1, which are the
ISO version of ASCII, and the Western European character sets (same as Windows)
respectively.

These kinds of convertions are required because the string fields in .sym files
are stored in ASCII.

Note that characters with values 128 or over are simply returned untranslated.

******************************************************************************}

function chr2ascii(c: char): byte;

begin

   chr2ascii := trnchr[c] { return translated character }

end;

{******************************************************************************

Output error string with preamble

Outputs an error string with the preamble 'Paslib: '. This is used for errors
from this module, as well as asserts. The purpose of using a preamble is to
identify where the message comes from. The print is routed through the system
error string procedure to allow the error to be presented in a system specific
way. For example, it could simply go to the console, or end up in a dialog on
a graphical system.

******************************************************************************}

procedure putstr(view s: string);

var i:     integer; { index for string }
    pream: packed array [1..8] of char; { preamble string }
    p:     pstring; { pointer to string }

begin

   pream := 'Paslib: '; { set preamble }
   new(p, max(s)+8); { get string to hold }
   for i := 1 to 8 do p^[i] := pream[i]; { copy preamble }
   for i := 1 to max(s) do p^[i+8] := s[i]; { copy string }
   ss_wrterr(p^); { output string }
   dispose(p) { release storage }

end;

{******************************************************************************

Abort program

Exits the program, and takes care of any cleanup required.

******************************************************************************}

procedure ps_abort;

begin

   goto 88 { go to module abort }

end;

{******************************************************************************

Set standard/nonstandard behavior

Sets the standard behavior action flag. We allow several extentions to ISO 7185
standard output behaviors. The mode flag normally comes up in extended mode.
This routine flips the standard mode behavior on. There is no way to set it
back to extended mode, and its intended that any one of multiple modules
should be able to demand standard treatment.

******************************************************************************}

procedure ps_setstd;

begin

   stdflg := true { set standard behavior }

end;

{******************************************************************************

Process assert

Accepts a string and processes an assert failed event. The condition associated
with an assert is compiled for speed reasons. This routine is only called when
the assert fails. An assert message is printed, and we halt the program. If
the provided assert message is not empty, we print that as part of the assert
message. The assert message is routed through the system error write handler.

******************************************************************************}

procedure ps_assert(view msg: string);

var i:      integer; { index for string }
    astbuf: packed array [1..15] of char;
    p:      pstring; { pointer to string }

begin

   if max(msg) = 0 then putstr('Assert failed') { just print our message }
   else begin { concatenate user string and our message }

      new(p, max(msg)+15); { get a string to hold it all }
      astbuf := 'Assert failed: '; { place our message in buffer }
      for i := 1 to 15 do p^[i] := astbuf[i];
      { copy user messsage into place }
      for i := 1 to max(msg) do p^[i+15] := msg[i];
      putstr(p^) { print it }

   end
   
end;

{******************************************************************************

Print error

Prints the given error in ASCII text, then aborts the program.

******************************************************************************}
 
procedure ps_error(e: ps_errcod);

begin

   { check error is already active. if so, this is a double fault, and
     we exit as soon as possible }
   if erract then goto 99; { goto the final exit }
   { check error is null. null errors can be returned to bypass any error
     message output. the net effect is identical to ps_abort }
   if e <> ps_ecnull then begin { not a null error }

      erract := true; { set error being processed }
      case e of { error }

         ps_ecnull:   ; { will not occur }
         ps_ecrngchk: putstr('Value out of range');
         ps_eclenmat: putstr('Array lengths do not match');
         ps_eccasvnf: putstr('Case value not found');
         ps_ezdiv:    putstr('Zero divide');
         ps_eivop:    putstr('Invalid operand(s)');
         ps_enpdref:  putstr('Nil pointer dereference');
         ps_erelovf:  putstr('Real overflow');
         ps_erelunf:  putstr('Real underflow');
         ps_erelflt:  putstr('Real processing fault');
         ps_etagact:  putstr('Tag value for enclosing variant not active');
         { start of internal errors }
         ps_ecftbful: putstr('File table full');
         ps_ecfilopn: putstr('File is open');
         ps_ecfilass: putstr('File already has name');
         ps_ecfilnop: putstr('File not open');
         ps_ecfilmod: putstr('File not in correct mode');
         ps_ecinvfld: putstr('Invalid field specification');
         ps_ecinvrl:  putstr('Invalid real number');
         ps_ecinvfrc: putstr('Invalid fraction specification');
         ps_ecintfmt: putstr('Invalid integer format');
         ps_ecinttl:  putstr('Integer value overflow');
         ps_ecrlfmt:  putstr('Invalid real format');
         ps_eceof:    putstr('End of file');
         ps_ecpos:    putstr('Invalid file position specification');
         ps_ecfault:  putstr('Library fault')

      end

   end;
   goto 88 { abort module }

end;

{******************************************************************************

Make file entry

Indexes a present file entry or creates a new one. If the file number passed
is 0, then a new file entry is created, and the parameters cleared. Otherwise,
the matching entry for the file is returned, and the file number set to the
associated logical file number.

******************************************************************************}

procedure makfil(var fp: filptr;     { file entry }
                 var fn: ps_filnum); { memory pointer to file }

var fi: 1..ps_maxopn; { index for files table }
    ff: 0..ps_maxopn; { found file entry }
    
begin

   if fn = 0 then begin { there is no file, make one }

      { find empty file slot }
      ff := 0; { clear found file }
      for fi := 1 to ps_maxopn do if opnfil[fi] = nil then ff := fi;
      if ff = 0 then ps_error(ps_ecftbful); { file table full }
      new(opnfil[ff]); { create a new file entry }
      { note that file entries are never removed in this version }
      fp := opnfil[ff]; { index that }
      { clear the entries }
      with fp^ do begin

         mode := fmund; { set undefined }
         nam  := nil;   { set no filename defined }
         full := false; { set nothing in buffer }
         buf  := nil;   { set no file buffer defined }
         typ  := ftbin; { we don't know, just set }
         bgn  := false; { set not beginning of file }
         eol  := false; { set not in eoln }
         leol := false; { set not last was eoln }
         bcr  := false; { set buffer is not cr }
         blf  := false; { set buffer is not lf }
         leol := false; { set last was not eoln }
         lcr  := false; { set last was not cr }
         llf  := false; { set last was not lf
         als  := 0      { set there is no alias }


      end;
      fn := ff { set file id number }

   end else fp := opnfil[fn] { return existing file record }

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

Compare filenames

Checks if the two filenames are equal, regardless of case or leading/trailing
spaces. Returns true if so.

******************************************************************************}

function cmpfil(view a, b: string): boolean;

var m:    boolean; { match status }
    i, x: integer; { index for string }

{ find lower case }

function lcase(c: char): char;

begin

   { find lower case equivalent }
   if c in ['A'..'Z'] then c := chr(ord(c) - ord('A') + ord('a'));
   lcase := c { return as result }

end;

{ find next character in string }

function next(i: integer; view s: string): char;

begin

   if i > max(s) then next := ' ' { set space }
   else next := lcase(s[i]) { set next character }

end;

begin

   m := true; { set match }
   i := 1; { index start of both strings }
   x := 1;
   { skip leading spaces on both names }
   while (next(i, a) = ' ') and (i <= max(a)) do i := i+1;
   while (next(x, b) = ' ') and (x <= max(b)) do x := x+1;
   while (i <= max(a)) and (x <= max(b)) and (next(i, a) = next(x, b)) do begin

      i := i+1; { advance }
      x := x+1

   end;
   { skip trailing spaces on both names }
   while (next(i, a) = ' ') and (i <= max(a)) do i := i+1;
   while (next(x, b) = ' ') and (x <= max(b)) do x := x+1;

   cmpfil := (i > max(a)) and (x > max(b))  { return match status }

end;

{******************************************************************************

Find alias for filename

Searches open file entries, and finds an alias for the given filename. If
found, returns a pointer to that entry, otherwise returns nil.

******************************************************************************}

function fndals(view n: string): ps_filnum;

var ff: ps_filnum;    { found file number, or 0 }
    fi: 1..ps_maxopn; { index for files table }

begin

   ff := 0; { clear file number found }
   for fi := 1 to ps_maxopn do if opnfil[fi] <> nil then { entry is occupied }
      if opnfil[fi]^.mode <> fmund then { file is open }
         if cmpfil(opnfil[fi]^.nam^, n) then ff := fi; { matches }

   fndals := ff { return found entry }

end;

{******************************************************************************

Assign filename

Assigns a filename to the given file.

******************************************************************************}

procedure ps_assign(var  fn: ps_filnum; { logical number of file }
                    view nm: string);   { name of file }

var fp: filptr; { file record pointer }

begin

   makfil(fp, fn); { make a file pointer }
   if fp^.als <> 0 then fp := opnfil[fp^.als]; { cross to alias if exists }
   if fp^.mode <> fmund then ps_error(ps_ecfilopn); { file is currently open }
   if fp^.nam <> nil then ps_error(ps_ecfilass); { file has already been named }
   ss_resolve(nm, fp^.nam) { resolve name and place }

end;

{******************************************************************************

Reset file

Performs common processing for text and binary reset. For system files, we
process possible aliasing. This means that when multiple instances of the 
system file appear, we alias all of these entries to the same file table
entry. This is necessary because all modules expect system files file to be the
same, and give the same input, including things like the buffer and various
flags.

******************************************************************************}

procedure resetf(fp: filptr;    { file record pointer }
                 fn: ps_filnum; { logical file number }
                 bs: integer);  { buffer length }

begin

   if fp^.mode <> fmund then begin { file is already open, just reset }

      ss_position(fp^.hdl, 1); { position to first element }
      fp^.mode := fmread { place in read mode }

   end else begin { file not open }

      { check no filename assigned }
      if fp^.nam = nil then new(fp^.nam, 0) { set name is temp }
      else if ss_sysfil(fp^.nam^) then begin { its a system file }

         fp^.als := fndals(fp^.nam^); { find possible alias for that }
         if fp^.als <> 0 then begin { cross to alias }

            fn := fp^.als; { set alias logical number }
            fp := opnfil[fn] { set file entry }

         end

      end;
      if fp^.mode = fmund then begin { original or alias is undefined }

         ss_openread(fp^.hdl, fp^.nam^); { open file for reading }
         ss_alias(fp^.hdl, fn); { alias to top level }
         fp^.mode := fmread; { set in read mode }
         if fp^.buf = nil then new(fp^.buf, bs) { allocate buffer }

      end

   end;
   fp^.full := false; { set no data in buffer }
   fp^.bgn := true; { set beginning of file }
   fp^.eol := false; { set not in eoln }
   fp^.bcr := false; { set buffer is not cr }
   fp^.blf := false { set buffer is not lf }

end;

{******************************************************************************

Reset file binary

Resets a standard binary file, with the given buffer length. 

******************************************************************************}

procedure ps_resfil(var fn: ps_filnum; { logical number of file }
                        bs: integer);  { buffer length }

var fp: filptr; { file record pointer }

begin

   makfil(fp, fn); { make a file pointer }
   if fp^.als <> 0 then fp := opnfil[fp^.als]; { cross to alias if exists }
   resetf(fp, fn, bs); { process reset }
   fp^.typ := ftbin { set file is binary }

end;

{******************************************************************************

Reset file text

Resets a standard text file, with the given buffer length. 

******************************************************************************}

procedure ps_restxt(var fn: ps_filnum; { logical number of file }
                        bs: integer);  { buffer length }

var fp: filptr; { file record pointer }

begin

   makfil(fp, fn); { make a file pointer }
   if fp^.als <> 0 then fp := opnfil[fp^.als]; { cross to alias if exists }
   resetf(fp, fn, bs); { process reset }
   fp^.typ := fttxt { set file is text }

end;

{******************************************************************************

Rewrite file

Performs rewrite processing common to the text and binary files. For system
files, we process possible aliasing. This means that when multiple instances of
the system file appear, we alias all of these entries to the same file table
entry. This is necessary because all modules expect system files file to be the
same, and give the same input, including things like the buffer and various
flags.

******************************************************************************}

procedure rewritef(fp: filptr;    { pointer to file record }
                   fn: ps_filnum; { logical file number }
                   bs: integer);  { buffer length }

begin

   if fp^.mode <> fmund then begin { file is already open, just rewrite }

      ss_close(fp^.hdl); { close file }
      { If file has a name, delete it and reopen it. If it is a temp, it
        will delete itself on close. }
      if not chknul(fp^.nam^) then ss_delete(fp^.nam^);
      ss_openwrite(fp^.hdl, fp^.nam^); { open file for writing }
      ss_alias(fp^.hdl, fn); { alias to top level }
      fp^.mode := fmwrite { place in write mode }

   end else begin { file not open }

      { check no filename assigned }
      if fp^.nam = nil then new(fp^.nam, 0) { set name is temp }
      else if ss_sysfil(fp^.nam^) then begin { its a system file }

         fp^.als := fndals(fp^.nam^); { find possible alias for that }
         if fp^.als <> 0 then begin { cross to alias }

            fn := fp^.als; { set alias logical number }
            fp := opnfil[fn] { set file entry }

         end

      end;
      if fp^.mode = fmund then begin { its not an alias, open it }

         ss_openwrite(fp^.hdl, fp^.nam^); { open file for writing }
         ss_alias(fp^.hdl, fn); { alias to top level }
         fp^.mode := fmwrite; { set in write mode }
         if fp^.buf = nil then new(fp^.buf, bs); { allocate buffer }

      end

   end;
   fp^.full := false { set no data in buffer }

end;

{******************************************************************************

Rewrite file binary

Resets a standard binary file, with the given buffer length. 

******************************************************************************}

procedure ps_rwtfil(var fn: ps_filnum; { logical number of file }
                        bs: integer);  { buffer length }

var fp: filptr; { file record pointer }

begin

   makfil(fp, fn); { make a file pointer }
   if fp^.als <> 0 then fp := opnfil[fp^.als]; { cross to alias if exists }
   rewritef(fp, fn, bs); { process rewrite }
   fp^.typ := ftbin { set file is binary }

end;

{******************************************************************************

Rewrite file text

Rewrites a standard text file, with the given buffer length. 

******************************************************************************}

procedure ps_rwttxt(var fn: ps_filnum; { logical number of file }
                        bs: integer);  { buffer length }

var fp: filptr; { file record pointer }

begin

   makfil(fp, fn); { make a file pointer }
   if fp^.als <> 0 then fp := opnfil[fp^.als]; { cross to alias if exists }
   rewritef(fp, fn, bs); { process rewrite }
   fp^.typ := fttxt { set file is text }

end;

{******************************************************************************

Update file

Opens the file if not currently open, resets the file position to 1, and
sets the mode to write. This is used to selectively update the file. It is
only applicable to non-text file.

******************************************************************************}

procedure ps_update(var fn: ps_filnum; { logical number of file }
                        bs: integer);  { buffer length }

var fp: filptr; { file record pointer }

begin

   makfil(fp, fn); { make a file pointer }
   if fp^.als <> 0 then fp := opnfil[fp^.als]; { cross to alias if exists }
   if fp^.mode <> fmund then begin { file is already open, just rewrite }

      ss_position(fp^.hdl, 1); { position to first element }
      fp^.mode := fmwrite { place in write mode }

   end else begin { file not open }

      { check no filename assigned }
      if fp^.nam = nil then new(fp^.nam, 0) { set name is temp }
      else if ss_sysfil(fp^.nam^) then begin { its a system file }

         fp^.als := fndals(fp^.nam^); { find possible alias for that }
         if fp^.als <> 0 then begin { cross to alias }

            fn := fp^.als; { set alias logical number }
            fp := opnfil[fn] { set file entry }

         end

      end;
      if fp^.mode = fmund then begin { original or alias is undefined }

         ss_openupdate(fp^.hdl, fp^.nam^); { open file for writing }
         ss_alias(fp^.hdl, fn); { alias to top level }
         fp^.mode := fmwrite; { set in write mode }
         if fp^.buf = nil then new(fp^.buf, bs); { allocate buffer }

      end

   end;
   fp^.full := false; { set no data in buffer }
   fp^.typ := ftbin { set file is binary }

end;

{******************************************************************************

Append file

Opens the file if not currently open, sets the file position to its length+1, 
and sets the mode to write. This is used to append new data to the end of a 
files, and is equivalent to "update(f); position(length(f)+1)". The advantage
of this call over update is that it can work on text files as well as binary.

******************************************************************************}

procedure append(fp: filptr; { pointer to file record }
                 fn: ps_filnum; { logical number of file }
                 bs: integer);  { buffer length }

begin

   if fp^.mode <> fmund then begin { file is already open, just rewrite }

      ss_position(fp^.hdl, ss_length(fp^.hdl)+1); { position to end }
      fp^.mode := fmwrite { place in write mode }

   end else begin { file not open }

      { check no filename assigned }
      if fp^.nam = nil then new(fp^.nam, 0) { set name is temp }
      else if ss_sysfil(fp^.nam^) then begin { its a system file }

         fp^.als := fndals(fp^.nam^); { find possible alias for that }
         if fp^.als <> 0 then begin { cross to alias }

            fn := fp^.als; { set alias logical number }
            fp := opnfil[fn] { set file entry }

         end

      end;
      if fp^.mode = fmund then begin { original or alias is undefined }

         ss_openupdate(fp^.hdl, fp^.nam^); { open file for writing }
         ss_alias(fp^.hdl, fn); { alias to top level }
         fp^.mode := fmwrite; { set in write mode }
         if fp^.buf = nil then new(fp^.buf, bs); { allocate buffer }
         ss_position(fp^.hdl, ss_length(fp^.hdl)+1) { position to end }

      end

   end;
   fp^.full := false { set no data in buffer }

end;

{******************************************************************************

Append file binary

Appends to a binary file, with the given buffer length..

******************************************************************************}

procedure ps_appfil(var fn: ps_filnum; { logical number of file }
                        bs: integer);  { buffer length }

var fp: filptr; { file record pointer }

begin

   makfil(fp, fn); { make a file pointer }
   if fp^.als <> 0 then fp := opnfil[fp^.als]; { cross to alias if exists }
   append(fp, fn, bs); { process append }
   fp^.typ := ftbin { set file is binary }

end;

{******************************************************************************

Append file text

Appends to a text file, with the given buffer length..

******************************************************************************}

procedure ps_apptxt(var fn: ps_filnum; { logical number of file }
                        bs: integer);  { buffer length }

var fp: filptr; { file record pointer }

begin

   makfil(fp, fn); { make a file pointer }
   if fp^.als <> 0 then fp := opnfil[fp^.als]; { cross to alias if exists }
   append(fp, fn, bs); { process append }
   fp^.typ := fttxt { set file is text }

end;

{******************************************************************************

Close file

Ends processing on file. This also clears the filename, allowing a whole new
file to be processed. Close can either mark the entry as undefined, or remove
the entry entirely. We choose to remove the entry, based on the idea that
keeping it around is unnecessary.

******************************************************************************}

procedure ps_close(var fn: ps_filnum); { logical number of file }

var fp: filptr; { file record pointer }

{ clear aliases }

procedure clrals(fn: ps_filnum);

var fi: 1..ps_maxopn; { index for files table }

begin

   for fi := 1 to ps_maxopn do if opnfil[fi] <> nil then 
      if opnfil[fi]^.als = fn then opnfil[fi]^.als := 0

end;

begin

   makfil(fp, fn); { make a file pointer }
   if fp^.als <> 0 then fp := opnfil[fp^.als]; { cross to alias if exists }
   if fp^.mode = fmund then ps_error(ps_ecfilnop); { file not open }
   ss_close(fp^.hdl); { close the file }
   if fp^.als <> 0 then clrals(fp^.als); { clear any aliases }
   if fp^.nam <> nil then dispose(fp^.nam); { dispose of used filename }
   fp^.nam := nil; { clear it }
   fp^.mode := fmund; { set file mode undefined }
   { Clear the original entry from the table. The alias, if it exists, is left
     for other references. }
   fp := opnfil[fn]; { index file record }
   if fp^.nam <> nil then dispose(fp^.nam); { dispose of used filename }
   dispose(fp); { dispose of file entry }
   opnfil[fn] := nil; { clear file slot }
   fn := 0 { set file not open }

end;

{******************************************************************************

Put file buffer

Writes the buffer out to the given file.

If the buffer is null, then the file is a "null element file", or a file with
zero length records. This is pretty much a testing oddity. Since we can't
write nothing, we write a marker byte instead, which is zero just for neatness.
This placeholds for the record in the file, and allows counts and eofs to be
correct.

******************************************************************************}

procedure ps_putfil(var fn: ps_filnum); { logical number of file }
                        
var fp: filptr; { file record pointer }

begin

   makfil(fp, fn); { make a file pointer }
   if fp^.als <> 0 then fp := opnfil[fp^.als]; { cross to alias if exists }
   if fp^.mode <> fmwrite then 
      ps_error(ps_ecfilmod); { file not in correct mode }
   if max(fp^.buf^) > 0 then begin { buffer has length }

      { The output buffer is only used for output, so we use it to hold
        the translated character as well. }
      if (fp^.typ = fttxt) and (max(fp^.buf^) = 1) then
         { it's a text file, and it has a single character buffer 
           (of course) }
         fp^.buf^[1] := chr2ascii(chr(fp^.buf^[1])); { translate to normal }
      ss_write(fp^.hdl, fp^.buf^) { write contents of buffer }

   end else begin { write null file marker pointer }

      nfmptr^[1] := 0; { set to write zero for neatness }
      ss_write(fp^.hdl, nfmptr^) { write }

   end
      

end;

{******************************************************************************

Load buffer address binary

Returns the address of the buffer variable for the file. If the file mode is
read, this will also cause the buffer to be read from the file if it is
empty. This fufills the "lazy I/O" algorithim.

******************************************************************************}

function ps_lbafil(var fn: ps_filnum) { logical number of file }
                   : gbtptr;          { buffer return }
                        
var fp: filptr; { file record pointer }

begin

   makfil(fp, fn); { make a file pointer }
   if fp^.als <> 0 then fp := opnfil[fp^.als]; { cross to alias if exists }
   { check file is open }
   if fp^.mode = fmund then ps_error(ps_ecfilnop);
   if (fp^.mode = fmread) and not fp^.full then begin

      { read mode, and buffer empty }
      if max(fp^.buf^) > 0 then { buffer has length }
         ss_read(fp^.hdl, fp^.buf^) { read into buffer }
      else ss_read(fp^.hdl, nfmptr^); { read to marker buffer }
      fp^.full := true { set buffer full }

   end;
   ps_lbafil := fp^.buf { return buffer }

end;

{******************************************************************************

Get file buffer binary

Advances the buffer file position. If there is currently an element in the
file buffer, then it is simply discarded. Otherwise, we must skip forward
in the file, discarding the data.

If the buffer is null, then the file is a "null element file", or a file with
zero length records. This is pretty much a testing oddity. Since we can't
read nothing, we read a marker byte instead, which can be any value. This
placeholds for the record in the file, and allows counts and eofs to be
correct.

******************************************************************************}

procedure ps_getfil(var fn: ps_filnum); { logical number of file }
                        
var fp: filptr; { file record pointer }

begin

   makfil(fp, fn); { make a file pointer }
   if fp^.als <> 0 then fp := opnfil[fp^.als]; { cross to alias if exists }
   if fp^.mode <> fmread then 
      ps_error(ps_ecfilmod); { file must be in read mode }
   if not fp^.full then begin { no buffer to discard, skip in file }

      if max(fp^.buf^) > 0 then { buffer has length }
         ss_read(fp^.hdl, fp^.buf^) { read into buffer (and discard }
      else ss_read(fp^.hdl, nfmptr^) { read to marker buffer }

   end;
   fp^.full := false { set buffer is empty }

end;

{******************************************************************************

Write file

If the data is null, then the file is a "null element file", or a file with
zero length records. This is pretty much a testing oddity. Since we can't
write nothing, we write a marker byte instead, which is zero just for neatness.
This placeholds for the record in the file, and allows counts and eofs to be
correct.

******************************************************************************}

procedure ps_wrtfil(var  fn: ps_filnum; { logical number of file }
                    view ba: bytarr);   { data in memory to write }

var fp: filptr; { open file pointer }

begin

   makfil(fp, fn); { make a file pointer }
   if fp^.als <> 0 then fp := opnfil[fp^.als]; { cross to alias if exists }
   if fp^.mode <> fmwrite then 
      ps_error(ps_ecfilmod); { file must be in write mode }
   if max(ba) > 0 then { data has length }
      ss_write(fp^.hdl, ba) { write data to file }
   else begin { write null file marker pointer }

      nfmptr^[1] := 0; { set to write zero for neatness }
      ss_write(fp^.hdl, nfmptr^) { write }

   end

end;   

{******************************************************************************

Read file

******************************************************************************}

procedure ps_rdfil(var fn: ps_filnum; { logical number of file }
                   var ba: bytarr);   { data in memory to read }

var fp: filptr; { open file pointer }

begin

   makfil(fp, fn); { make a file pointer }
   if fp^.als <> 0 then fp := opnfil[fp^.als]; { cross to alias if exists }
   if fp^.mode <> fmread then 
      ps_error(ps_ecfilmod); { file must be in read mode }
   if fp^.full then begin { there is data in the buffer }

      ba := fp^.buf^; { place buffered data in memory }
      fp^.full := false { set no data in buffer }

   end else ss_read(fp^.hdl, ba) { else process normal read }

end;   

{******************************************************************************

Check file eof

Checks if the file has reached eof. This is true if the base file shows eof,
and either the buffer is not full, or the file is in write mode.

******************************************************************************}

function ps_eoffil(var fn: ps_filnum) { logical number of file }
                   : boolean;         { eof status }

var fp: filptr; { file record pointer }
    ef: boolean; { eof status holder }

begin

   makfil(fp, fn); { make a file pointer }
   if fp^.als <> 0 then fp := opnfil[fp^.als]; { cross to alias if exists }
   if fp^.mode = fmund then ps_error(ps_ecfilnop); { file not open }
   { check file in read mode, and buffer is full }
   if (fp^.mode = fmread) and fp^.full then ef := false
   else ef := ss_eof(fp^.hdl); { else get status from file }
   ps_eoffil := ef { return status }

end;

{******************************************************************************

Find file length

Returns the length of the given file.

******************************************************************************}

function ps_fillen(var fn: ps_filnum) { logical number of file }
                   : integer;         { length of file }

var fp: filptr; { file record pointer }

begin

   makfil(fp, fn); { make a file pointer }
   if fp^.als <> 0 then fp := opnfil[fp^.als]; { cross to alias if exists }
   if fp^.mode = fmund then ps_error(ps_ecfilnop); { file not open }
   ps_fillen := ss_length(fp^.hdl) div max(fp^.buf^) { return file length }

end;

{******************************************************************************

Find file location

Returns the location of the given file.

******************************************************************************}

function ps_filloc(var fn: ps_filnum) { logical number of file }
                   : integer;         { location in file }

var fp: filptr; { file record pointer }

begin

   makfil(fp, fn); { make a file pointer }
   if fp^.als <> 0 then fp := opnfil[fp^.als]; { cross to alias if exists }
   if fp^.mode = fmund then ps_error(ps_ecfilnop); { file not open }
   ps_filloc := ss_location(fp^.hdl) div max(fp^.buf^) { return file location }

end;

{******************************************************************************

Set file position

Sets the current position on the given file.

******************************************************************************}

procedure ps_posfil(var fn: ps_filnum; { logical number of file }
                        p:  integer);  { position in file }

var fp: filptr; { file record pointer }

begin

   if p < 1 then ps_error(ps_ecpos); { flag bad position request }
   makfil(fp, fn); { make a file pointer }
   if fp^.als <> 0 then fp := opnfil[fp^.als]; { cross to alias if exists }
   if fp^.mode = fmund then ps_error(ps_ecfilnop); { file not open }
   ss_position(fp^.hdl, (p-1)*max(fp^.buf^)+1) { set file position }

end;

{******************************************************************************

Load buffer address of text file

Returns the address of the file buffer. If the buffer is not already full,
then the next character from the file is read into the buffer.
If the character is an eoln, then a space replaces the contents of the buffer.
If eof is true, and the last sequence is not eoln or beginning of file, an eoln
is automatically generated. The eolns accepted are ASCII cr, lf, cr followed by
lf, and lf followed by cr. 

Note: This code needed rework for Unix. It has to be assumed that ss_eof might
read ahead to establish eof status. The result is that you can only check eof
if you are ready to read a character anyways, otherwise it can read ahead
during an eoln condition an ruin the interactivity of console connected files.

******************************************************************************}

function ps_lbatxt(var fn: ps_filnum) { logical number of file }
                   : gbtptr;          { return buffer }

var fp: filptr; { file record pointer }
    bp: gbtptr; { dummy return value }

begin

   makfil(fp, fn); { make a file pointer }
   if fp^.als <> 0 then fp := opnfil[fp^.als]; { cross to alias if exists }
   { check file is open }
   if fp^.mode = fmund then ps_error(ps_ecfilnop);
   if (fp^.mode = fmread) and not fp^.full then begin

      if ss_eof(fp^.hdl) and not fp^.leol and not fp^.bgn then begin

         { we are at the file end, and the last sequence was not an eoln. and 
           we are not at the start of the file (file empty). we must add an
           artificial eoln }
         fp^.buf^[1] := ord(' '); { clear buffer }
         fp^.eol := true;
         fp^.bcr := false; { set "typeless" eoln }
         fp^.blf := false;
         fp^.full := true { set buffer full }

      end else if not ss_eof(fp^.hdl) then begin { normal read }

         { read mode, and buffer empty }
         fp^.eol := false; { set not eoln }
         fp^.bgn := false; { set not file beginning }
         fp^.bcr := false; { clear eoln type status }
         fp^.blf := false;
         ss_read(fp^.hdl, fp^.buf^); { read into buffer }
         { translate to encoded }
         fp^.buf^[1] := ord(ascii2chr(fp^.buf^[1]));
         fp^.full := true; { set buffer full }
         fp^.bcr := fp^.buf^[1] = ord('\cr'); { set buffer cr status }
         fp^.blf := fp^.buf^[1] = ord('\lf'); { set buffer lf status }
         if fp^.bcr or fp^.blf then begin { eoln }

            fp^.eol := true; { set eoln true for file }
            fp^.buf^[1] := ord(' '); { replace with space }
            { check eoln already parsed, and this is a continuation of it }
            if fp^.lcr and fp^.blf or fp^.llf and fp^.bcr then begin

               { it's an eoln sequence. we have already passed an eoln, so we
                 skip the second part }
               fp^.full := false; { set no character in buffer }
               fp^.lcr := false; { clear last eoln status }
               fp^.llf := false;
               { now the current is a "black hole", so we have to replace it
                 with valid contents. rerun the load sequence. we won't
                 recurse because the last eoln status is cleared }
               if not ss_eof(fp^.hdl) then { not last character }
                  bp := ps_lbatxt(fn) { load the file buffer }

            end
           
         end

      end

   end;
   ps_lbatxt := fp^.buf { return buffer }

end;

{******************************************************************************

Get next character in text file

Loads the buffer with the next character in the next file.

******************************************************************************}

procedure ps_gettxt(var fn: ps_filnum); { logical number of file }

var fp: filptr; { file record pointer }
    bp: gbtptr; { dummy return value }

begin

   bp := ps_lbatxt(fn); { insure that the buffer is full }
   makfil(fp, fn); { make a file pointer }
   if fp^.als <> 0 then fp := opnfil[fp^.als]; { cross to alias if exists }
   if fp^.mode <> fmread then 
      ps_error(ps_ecfilmod); { file must be in read mode }
   if fp^.full then with fp^ do begin { dispose of character }

      leol := eol; { save character parameters as last }
      lcr := bcr;
      llf := blf;
      full := false { clear active character }

   end else if ss_eof(fp^.hdl) then ps_error(ps_eceof) { eof }

end;

{******************************************************************************

Check end of file text

Checks if the text file is at EOF. We have to do the eof check using lookahead
because we could be in the middle of a multicharacter eoln followed by an eof.
So we lookahead to discard the tail of that.

******************************************************************************}

function ps_eoftxt(var fn: ps_filnum) { logical number of file }
                   : boolean;         { eof status }

var fp: filptr; { file record pointer }
    bp: gbtptr; { dummy return value }

begin

   bp := ps_lbatxt(fn); { insure that the buffer is full, or are at eof }
   makfil(fp, fn); { make a file pointer }
   if fp^.als <> 0 then fp := opnfil[fp^.als]; { cross to alias if exists }
   { note that the only reason that the buffer would not be full is because
     an eof is encountered }
   ps_eoftxt := not fp^.full { return eof status }

end;

{******************************************************************************

Check end of line text

Checks if the text file is at eoln.

******************************************************************************}

function ps_chkeol(var fn: ps_filnum) { logical number of file }
                   : boolean;         { eoln status }

var fp: filptr; { file record pointer }
    bp: gbtptr; { dummy return value }

begin

   bp := ps_lbatxt(fn); { insure that the buffer is full }
   makfil(fp, fn); { make a file pointer }
   if fp^.als <> 0 then fp := opnfil[fp^.als]; { cross to alias if exists }
   ps_chkeol := fp^.eol { return eoln status }

end;

{******************************************************************************

Write character to text file with field

Processes the full fielded text file character write.

******************************************************************************}

procedure ps_wrtchr(var tf: text;    { logical number of file }
                        f:  integer; { field }
                        c:  char);   { character to write }

var i: integer;

begin

   if f < 1 then ps_error(ps_ecinvfld); { invalid field specification }
   for i := 2 to f do begin

      tf^ := ' '; { place a space in the buffer }
      put(tf) { output spaces }

   end;
   tf^ := c; { write character }
   put(tf)

end;

{******************************************************************************

Write eoln to text file

Writes a cr/lf sequence to the file.

******************************************************************************}

procedure ps_wrteol(var tf: text); { file to write }

begin

   if not ss_alteol then { not unix style lines }
      write(tf, '\cr'); { write eoln }
   write(tf, '\lf')

end;

{******************************************************************************

Read eoln

Skips to the next eoln in the file, then skips the eoln.

******************************************************************************}

procedure ps_rdeol(var tf: text); { file to read }

begin

   while not eoln(tf) do get(tf); { advance until eoln }
   get(tf) { skip eoln }

end;

{******************************************************************************

Write next page to text file

Writes a form-feed sequence to the file.

******************************************************************************}

procedure ps_pagtxt(var tf: text); { file to write }

begin

   write(tf, '\ff') { write form-feed }

end;

{******************************************************************************

Read next character in text file

Reads and returns the next character in the text file.

******************************************************************************}

procedure ps_rdchr(var tf: text;  { file to read }
                   var c:  char); { character to read }

begin

   c := tf^; { place character }
   get(tf) { get next character }

end;

{******************************************************************************

Write string

Writes the given string out to the text file. 

******************************************************************************}

procedure ps_wrtstr(var  tf: text;    { file to write }
                    view s:  string); { string to output }

var i: integer; { index for string }

begin

   for i := 1 to max(s) do write(tf, s[i]) { write string characters }

end;

{******************************************************************************

Write string fielded

Writes the given string out to the text file with the field. Accepts the
following extended field actions:

0     Print padded string. Finds the space padded length of the string, and
      prints that.

< 0   Prints left justified with abs(field).

******************************************************************************}

procedure ps_wrtstrf(var  tf: text;    { file to write }
                          f:  integer; { field }
                     view s:  string); { string to output }

var i:  integer; { index for string }
    ep: integer; { end padding }

begin

   if (f < 1) and stdflg then { field invalid, and standard mode }
      ps_error(ps_ecinvfld); { invalid field specification }
   if f = 0 then begin { print padded string }

      i := max(s); { find last non-space character }
      if i > 0 then begin { not null }

         while (s[i] = ' ') and (i > 1) do i := i-1;
         { If found, set padded length. Otherwise, the string is null }
         if s[i] <> ' ' then f := i

      end

   end;
   if f > max(s) then begin { write leading spaces }

      for i := 1 to f-max(s) do write(tf, ' '); { pad with spaces }
      f := max(s) { set field to string }

   end;
   ep := 0; { set no end padding }
   if f < 0 then begin { handle left justification preparation }

      f := abs(f); { find length }
      if f > max(s) then begin

         ep := f - max(s); { find end padding }
         f := max(s) { set field to string }

      end

   end;
   for i := 1 to f do write(tf, s[i]); { write string characters }
   for i := 1 to ep do write(tf, ' ') { write end padding }

end;

{******************************************************************************

Write boolean

Writes a boolean to the given text file. Since we decided that ISO 7185
specifies a default field for booleans, this routine has no real purpose over
ps_wrtblf. It remains for historical/compatibility reasons.

******************************************************************************}

procedure ps_wrtbol(var tf: text;     { file to write }
                        b:  boolean); { boolean to write }

begin

   if b then write(tf, ' true') { write value of true }
   else write(tf, 'false') { write value of false }

end;

{******************************************************************************

Write boolean with field

Writes a boolean to the given text file, using a field. Accepts the same
field extentions as strings.

******************************************************************************}

procedure ps_wrtblf(var tf: text;     { file to write }
                        f:  integer;  { field }
                        b:  boolean); { boolean to write }

begin

   if (f < 1) and stdflg then { field invalid, and standard mode }
      ps_error(ps_ecinvfld); { invalid field specification }
   if b then write(tf, 'true':f) { write value of true }
   else write(tf, 'false':f) { write value of false }

end;

{******************************************************************************

Write integer

Writes an integer using a field. Extended fields are accepted, with -field
being left justify. Field = zero is an error and has no meaning.

******************************************************************************}

procedure ps_wrtint(var tf: text;     { text file to output to }
                        f:  integer;  { field }
                        i:  integer); { integer to write }

var p:       integer; { power holder }
    leading: boolean; { leading zero output }
    buffer:  packed array [1..11] of char; { save for output characters }
    ccnt:    0..11; { output characters counter }
    c:       integer; { counter }

begin

   if ((f < 1) and stdflg) or (f = 0) then { field invalid, and standard mode }
      ps_error(ps_ecinvfld); { invalid field specification }
   p := maxpwr; { set maximum power }
   ccnt := 0; { clear character count }
   if i < 0 then begin

      ccnt := ccnt+1; { count characters }
      buffer[ccnt] := '-' { place sign }

   end;
   i := abs(i); { find signless value }
   leading := false; { set no leading digit output }
   while p <> 0 do begin { fit powers }

      if ((i div p) <> 0) or leading or (p = 1) then begin

         { non-zero, or leading already output, or last digit }
         ccnt := ccnt+1; { count characters }
         buffer[ccnt] := chr(i div p+ord('0')); { save digit }
         leading := true { set leading digit output }

      end;
      i := i mod p; { remove from value }
      p := p div 10 { find next power }

   end;
   for c := 1 to f-ccnt do write(tf, ' '); { output leading spaces }
   for c := 1 to ccnt do write(tf, buffer[c]); { output digits }
   if f < 0 then { left justified }
      for c := 1 to abs(f)-ccnt do write(tf, ' ') { output trailing spaces }

end;

{******************************************************************************

Write real in floating point notation

Writes a real using floating point notation. Accepts a field. Since the format
fills its field (no space padding), there is no meaning to extended fields
here.

******************************************************************************}

procedure ps_wrtreal(var tf: text;    { text file }
                         f:  integer; { field }
                         r:  real);   { real to write }

var e: integer; { exponent holder }
    i: integer; { mantissa buffer }
    p: integer; { power holder }

begin

   if f < 1 then ps_error(ps_ecinvfld); { invalid field }
   f := f-9; { find field remaining after essential places }
   if r = 0.0 then begin

      write(tf, ' 0.0'); { it's zero, output that }
      { pad with trailing zeros as required }
      while f > 0 do begin write(tf, '0'); f := f-1 end;
      write(tf, 'e+000') { output exponent }

   end else begin { nonzero }

      e := 0; { clear exponent }
      { place number so that it is just < 10 }
      while (abs(r) < 10.0) and (e >= -308) do begin r := r*10.0; e := e-1 end;
      while (abs(r) >= 10.0) and (e <= 308) do begin r := r/10.0; e := e+1 end;
      { check invalid exponent }
      if abs(e) > 308 then ps_error(ps_ecinvrl); { invalid real number }
      if r < 0 then write(tf, '-') else write(tf, ' '); { output sign }
      { move to maximum representable digit in integer }
      p := maxpwr div 10; { set maximum power (that fits in integer) }
      i := round(abs(r)*p); { find number as scaled integer }
      { the first digit, followed by the decimal point, is allways output }
      write(tf, chr(i div p+ord('0'))); { output digit }
      i := i mod p; { remove from value }
      p := p div 10; { find next power }
      write(tf, '.'); { output decimal point }
      { the first fraction digit is mandatory }
      write(tf, chr(i div p+ord('0'))); { output digit }
      i := i mod p; { remove from value }
      p := p div 10; { find next power }
      while (p <> 0) and (f > 0) do begin { fit powers }

         write(tf, chr(i div p+ord('0'))); { output digit }
         i := i mod p; { remove from value }
         p := p div 10; { find next power }
         f := f-1 { count spaces }

      end;
      { pad with trailing zeros as required }
      while f > 0 do begin write(tf, '0'); f := f-1 end;
      write(tf, 'e'); { output exponent mark }
      if e < 0 then write(tf, '-') else write(tf, '+'); { output sign }
      e := abs(e); { remove exponent sign }
      p := 100; { set maximum exponent power }
      while p <> 0 do begin { fit powers }

         write(tf, chr(e div p+ord('0'))); { output digit }
         e := e mod p; { remove from value }
         p := p div 10 { find next power }

      end
     
   end

end;

{******************************************************************************

Write real in fixed point notation

Writes a real using fixed point notation. Accepts a field and fraction. Accepts
extended fields, with negative being left justification. Field = 0 is an
error, and has no meaning.

******************************************************************************}

procedure ps_wrtrlf(var tf: text;    { text file }
                        fl: integer; { field }
                        fr: integer; { fraction }
                        r:  real);   { real to write }

var i:      integer; { integer portion of number }
    p:      integer; { power holder }
    ps:     integer; { power save }
    digits: integer; { count of representable digits }
    sp:     integer; { space counter }
    fc:     integer; { fraction counter }

begin

   if ((fl < 1) and stdflg) or (fl = 0) then 
      { field invalid, and standard mode }
      ps_error(ps_ecinvfld); { invalid field specification }
   if fr < 1 then ps_error(ps_ecinvfrc); { invalid fraction }
   i := trunc(r); { find "whole" part of real }
   { find number of digits in whole part }
   p := maxpwr; { set maximium power in integer }
   while p <> 0 do { find the top digit }
      if i div p <> 0 then begin ps := p; p := 0 end  { found digit, terminate }
      else p := p div 10; { set next digit }
   digits := 0; { clear digit count }
   { count significant digits }
   while ps <> 0 do begin ps := ps div 10; digits := digits+1 end;
   if digits = 0 then digits := 1; { must be at least one digit (zero case) }
   if r < 0 then digits := digits+1; { count sign place }
   { now we know the minimum length of the number, digits+decimal+fraction.
     output leading spaces based on that }
   for sp := 1 to fl-(digits+1+fr) do write(tf, ' '); { output padding } 
   write(tf, i:1, '.'); { and output that, followed by decimal point }
   r := abs(r-i); { find fraction without sign }
   i := round(r*maxpwr); { move to maximum representable digit in integer }
   p := maxpwr div 10; { set maximum power (that fits in integer) }
   fc := fr; { set fraction counter }
   while (p <> 0) and (fc > 0) do begin { fit powers }

      write(tf, chr(i div p+ord('0'))); { output digit }
      i := i mod p; { remove from value }
      p := p div 10; { find next power }
      fc := fc-1 { count fractional digits }

   end;
   { now pad out the rest of the specified fraction with zeros }
   while fc <> 0 do begin write(tf, '0'); fc := fc-1 end;
   if fl < 0 then { left justified }
      for sp := 1 to abs(fl)-(digits+1+fr) do 
         write(tf, ' ') { output trailing spaces }

end;

{******************************************************************************

Read integer

Reads an integer from the text file.

******************************************************************************}

procedure ps_rdint(var tf: text;     { file to read }
                   var i:  integer); { integer to read }

var sgn: integer; { sign of result }
    v:   integer; { incoming digit value }

begin

   sgn := 1; { set sign is positive }
   if eof(tf) then ps_error(ps_eceof); { eof encountered }
   while tf^ = ' ' do begin

      get(tf); { skip leading spaces }
      if eof(tf) then ps_error(ps_eceof) { eof encountered }

   end;
   { spaces or eoln skipped, now the line must be terminated, so further
     eof checks not required }
   if tf^ = '+' then get(tf) { skip '+' }
   else if tf^ = '-' then begin { negative }

      get(tf); { skip '-' }
      sgn := -1 { set sign negative }

   end;
   if not (tf^ in ['0'..'9']) then ps_error(ps_ecintfmt); { invalid integer }
   i := 0; { clear result }
   while tf^ in ['0'..'9'] do begin { read digits }

      v := ord(tf^)-ord('0'); { find the value of the new digit }
      { check for overflow }
      if (i > maxint div 10) or 
         ((i = maxint div 10) and (v > maxint mod 10)) then
            ps_error(ps_ecinttl); { integer too large }
      i := i*10+v; { add in next value }
      get(tf) { next digit }

   end;
   i := i*sgn { set sign of result }

end;

{******************************************************************************

Read real

Reads a real from the text file.

******************************************************************************}

procedure ps_rdreal(var tf: text;  { file to read }
                    var r:  real); { real to read }

var sgn: integer; { sign of result }
    i:   integer; { integer portion }
    p:   real;    { power }


{ find power of ten effciently }

function pwrten(e: integer): real;

var t: real; { accumulator }
    p: real; { current power }

begin

   p := 1.0e+1; { set 1st power }
   t := 1.0; { initalize result }
   repeat 

      if odd(e) then t := t*p; { if bit set, add this power }
      e := e div 2; { index next bit }
      p := sqr(p) { find next power }

   until e = 0;
   pwrten := t

end;

begin

   sgn := 1; { set sign is positive }
   if eof(tf) then ps_error(ps_eceof); { eof encountered }
   while tf^ = ' ' do begin

      get(tf); { skip leading spaces }
      if eof(tf) then ps_error(ps_eceof) { eof encountered }

   end;
   { spaces or eoln skipped, now the line must be terminated, so further
     eof checks not required }
   if tf^ = '+' then get(tf) { skip '+' }
   else if tf^ = '-' then begin { negative }

      get(tf); { skip '-' }
      sgn := -1 { set sign negative }

   end;
   read(tf, i); { read unsigned integer portion }
   r := i; { convert integer to real }
   if tf^ in ['.', 'e', 'E'] then begin { it's a real }

      if tf^ = '.' then begin { decimal point }

         get(tf); { skip '.' }
         if not (tf^ in ['0'..'9']) then ps_error(ps_ecrlfmt); { invalid real format }
         p := 1.0; { initalize power }
         while tf^ in ['0'..'9'] do begin { parse digits }

            p := p/10.0; { find next scale }
            { add and scale new digit }
            r := r+(p * (ord(tf^) - ord('0')));
            get(tf) { next }

         end

      end;
      if tf^ in ['e', 'E'] then begin { exponent }

         get(tf); { skip 'e' }
         if not (tf^ in ['0'..'9', '+', '-']) then
            ps_error(ps_ecrlfmt); { invalid real format }
         read(tf, i); { get exponent }
         { find with exponent }
         if i < 0 then r := r/pwrten(i) else r := r*pwrten(i)

      end

   end;
   r := r*sgn { apply sign }

end;

{******************************************************************************

Initalize module

******************************************************************************}

begin

   { clear files table }
   for ofi := 1 to ps_maxopn do opnfil[ofi] := nil;
   tmpcnt := 1; { clear temporary files counter }
   erract := false; { set no error being processed }
   stdflg := false; { set standard behavior off, for extended actions }
   new(nfmptr, 1); { get null file marker pointer }
   { Form character to ASCII value translation array from ASCII value to 
     character translation array. }
   for ti := 0 to 255 do trnchr[chr(ti)] := ti; { null out array }
   for ti := 1 to 127 do trnchr[chrtrn[ti]] := ti { form translation }

end;

{******************************************************************************

Finalize module

******************************************************************************}

begin

   88: { terminate module }

   { close any open files and release space }
   for ofi := 1 to ps_maxopn do if opnfil[ofi] <> nil then begin { file exists }

      if opnfil[ofi]^.mode <> fmund then
         ss_close(opnfil[ofi]^.hdl); { close open file }
      dispose(opnfil[ofi]) { release space }

   end;
   dispose(nfmptr); { dispose of null file marker pointer }

   99: { final exit }

end.

