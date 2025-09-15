{******************************************************************************
*                                                                             *
* TPC SYSTEM UNIT EMULATOR                                                    *
*                                                                             *
* Implements the following functions:                                         *
*                                                                             *
* procedure append(var f: text);                                              *
* procedure concat(var d: gstring; view sa, sb: gstring);                     *
* procedure copy(var d: gstring; view s: gstring; i, c: integer);             *
* procedure dec(var x: integer);                                              *
* procedure deletes(var s: gstring; i, c: integer);                           *
* procedure fillchar(var x: gstring; c: word; v: char);                       *
* procedure flush(var f: text);                                               *
* function frac(x: real): real;                                               *
* procedure fsearch(view p, d: gstring; var r: gstring);                      *
* procedure fsplit(view p: gstring; var d, n, e: gstring);                    *
* procedure getdate(var y, m, d, w: word);                                    *
* procedure getdir(d: byte; var s: gstring );                                 *
* procedure gettime(var h, m, s, s100: word);                                 *
* function hi(x: integer): byte;                                              *
* procedure inc(var x: integer);                                              *
* procedure insert(view s: gstring; var d: string; i: integer);               *
* function int(x: real): real;                                                *
* function ioresult: word;                                                    *
* function lengths(s: gstring): byte;                                         *
* function lo(x): byte;                                                       *
* function maxavail: longint;                                                 *
* function memavail: longint;                                                 *
* procedure mkdir(view s: gstring);                                           *
* procedure packtime(view dt: datetime; var t: longint);                       *
* function paramcount: word;                                                  *
* procedure paramstr(i: word; var s: gstring);                                *
* function pi: real;                                                          *
* function pos(view ss, s: gstring ): byte;                                   *
* function rand: real;                                                        *
* function random(max: integer): integer;                                     *
* procedure randomize;                                                        *
* procedure rmdir(view s: string);                                            *
* procedure runerror(e: byte );                                               *
* function seekeof(var f: text );                                             *
* function seekeoln(var f: text);                                             *
* procedure settime(h, m, s, s100: word);                                     *
* procedure stri(x, w: integer; var s: gstring);                              *
* procedure strr(x: real; w, d: integer; var s: gstring);                     *
* function swap(x: integer): integer;                                         *
* procedure unpacktime(t: longint; var dt: datetime);                         *
* function upcase(ch: char): char;                                            *
* procedure vali(view s: gstring; var v: integer; var c: integer);            *
* procedure valr(view s: gstring; var v: real; var c: integer);               *
* procedure writestr(var f: text; s: gstring);                                *
* procedure strcpy(var d: gstring; view s: gstring);                          *
* procedure strccpy(var d: gstring; view s: gstring);                         *
* procedure readlnstr(var f: text; var s: gstring);                           *
*                                                                             *
* The type "string" is declared, but declarations such as string[n] should be *
* changed to "packed array [0..n] of char". TPC strings are different than    *
* normal strings in that the have a zero'th element, which keeps the string   *
* length.                                                                     *
* Strings cannot be written, read, or concatenated in instructions. However,  *
* A function exists for each of these operations.                             *
* String concatenation is done via a procedure, not an operator. The concat   *
* procedure concatenates to its first string, and multiple concatenations     *
* must be separated out.                                                      *
*                                                                             *
******************************************************************************}

module system(output);

uses trmlib;

type

   byte = 0..255; { byte }
   word = 0..65535; { "word", as in 16 bits for the original DOS compiler }
   longint = integer; { alias longs to integer }
   string = packed array [0..255] of char; { tpc string }
   gstring = packed array of char; { general handling string }
   datetime = record { date/time record }

      month: 1..12;
      day:   1..31;
      year:  integer;
      hour:  0..23;
      min:   0..59;
      sec:   0..59

   end;

procedure append(var f: text); begin end;
procedure concat(var d: gstring; view sa, sb: gstring); begin end;
procedure copy(var d: gstring; view s: gstring; i, c: integer); begin end;
procedure dec(var x: integer); begin end;
procedure deletes(var s: gstring; i, c: integer); begin end;
procedure fillchar(var x: gstring; c: word; v: char); begin end;
procedure flush(var f: text); begin end;
function frac(x: real): real; begin end;
procedure fsearch(view p, d: gstring; var r: gstring); begin end;
procedure fsplit(view p: gstring; var d, n, e: gstring); begin end;
procedure getdate(var y, m, d, w: word); begin end;
procedure getdir(d: byte; var s: gstring ); begin end;
procedure gettime(var h, m, s, s100: word); begin end;
function hi(x: integer): byte; begin end;
procedure inc(var x: integer); begin end;
procedure insert(view s: gstring; var d: string; i: integer); begin end;
function int(x: real): real; begin end;
function ioresult: word; begin end;
function lengths(view s: gstring): byte; begin end;
function lo(x: integer): byte; begin end;
function maxavail: longint; begin end;
function memavail: longint; begin end;
procedure mkdir(view s: gstring); begin end;
procedure packtime(view dt: datetime; var t: longint); begin end;
function paramcount: word; begin end;
procedure paramstr(i: word; var s: gstring); begin end;
function pi: real; begin end;
function pos(view ss, s: gstring ): byte; begin end;
function rand: real; begin end;
function random(max: integer): integer; begin end;
procedure randomize; begin end;
procedure rmdir(view s: string); begin end;
procedure runerror(e: byte ); begin end;
function seekeof(var f: text ): boolean; begin end;
function seekeoln(var f: text): boolean; begin end;
procedure settime(h, m, s, s100: word); begin end;
procedure stri(x, w: integer; var s: gstring); begin end;
procedure strr(x: real; w, d: integer; var s: gstring); begin end;
function swap(x: integer): integer; begin end;
procedure unpacktime(t: longint; var dt: datetime); begin end;
function upcase(c: char): char; begin end;
procedure vali(view s: gstring; var v: integer; var c: integer); begin end;
procedure valr(view s: gstring; var v: real; var c: integer); begin end;
procedure writestr(var f: text; view s: gstring); begin end;
procedure strcpy(var d: gstring; view s: gstring); begin end;
procedure strccpy(var d: gstring; view s: gstring); begin end;
procedure readlnstr(var f: text; var s: gstring); begin end;

begin
end.
