{******************************************************************************
*                                                                             *
*                        Character Level Parsing Library                      *
*                                                                             *
*                             2002/8 S. A. Moore                              *
*                                                                             *
* Contains functions to parse at the character level. The user opens a        *
* parsing level that includes a file to read input from. Each parsing level   *
* has a line buffer associated with it, and parsing occurs indirectly from    *
* that buffer. The user can choose whether to parse a single line at a time,  *
* or multiple lines, or a mix of those two. It is possible to nest file       *
* levels, and there is a stacking system to hold the current parsing position *
* for backtracking. The backtrack system does not track further than the      *
* current line, but there is nothing to prevent adding that.                  *
*                                                                             *
* Parlib can be used in several common modes:                                 *
*                                                                             *
* - Place a string into the parser, and parse that.                           *
*                                                                             *
* - Open the "command" file as the source, read a single line from it, and    *
*   parse that.                                                               *
*                                                                             *
* - Parse full file.                                                          *
*                                                                             *
* - Parse multiple files, with nesting.                                       *
*                                                                             *
******************************************************************************}

module parlib { (output) };

uses strlib,
     extlib;

const maxpar = 100; { number of logical parse handles }

type 

   parhan = 1..maxpar; { logical parse handle }
      
{ functions }

procedure openpar(var ph: parhan); external;
procedure closepar(ph: parhan); external;
procedure openstr(ph: parhan; view s: string); external;
procedure openfil(ph: parhan; view fn: string; blen: integer); external;
procedure closefil(ph: parhan); external;
function endfil(ph: parhan): boolean; external;
function endlin(ph: parhan): boolean; external;
function chkchr(ph: parhan): char; external;
procedure getchr(ph: parhan); external;
procedure skpspc(ph: parhan); external;
procedure getchrl(ph: parhan); external;
procedure skpspcl(ph: parhan); external;
procedure getlin(ph: parhan); external;
procedure pushpos(ph: parhan); external;
procedure poppos(ph: parhan); external;
procedure dmppos(ph: parhan); external;
function chklab(ph: parhan): boolean; external;
procedure parlab(ph: parhan; var l: string; var err: boolean); external;
function chknum(ph: parhan; r: integer): boolean; external;
procedure parnum(ph: parhan; var i: integer; r: integer; var err: boolean);
   external;
function chkfil(ph: parhan): boolean; external;
procedure parfil(ph: parhan; var n: string; path: boolean; var err: boolean);
   external;
procedure parwrd(han: parhan; var w: string; var err: boolean); external;
procedure setfch(ph: parhan; view vc: chrset); external;
function chkstr(ph: parhan): boolean; external;
procedure parstr(ph: parhan; var s: string; var err: boolean); external;
procedure prterr(ph: parhan; var ef: text; view es: string; pl: boolean);
   external;
procedure trclin(ph: parhan; trc: boolean); external;

begin
end.
