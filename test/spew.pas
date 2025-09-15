{*******************************************************************************
*                                                                              *
*                                   SPEW TEST                                  *
*                                                                              *
*                         Copyright (C) 2005 S. A. Moore                       *
*                                                                              *
* Takes a file parameter. We walk though the given file, one character at a    *
* time, one line at a time, and knock out each character in the file with an   *
* alternate character, then parse that, placing the errors into a temp file.   *
* the error file is then inspected for error numbers and types, and the        *
* results tabulated, then output at the end of the program.                    *
*                                                                              *
* If parse returns "operator attention", then we abort, and print the line and *
* character which caused the error. The file "spewtest.pas" will have the      *
* file that caused the error. An operator attention error is either a problem  *
* with files, access or other run problem, or a system fault. All of these     *
* should be corrected immediately, so we stop.                                 *
*                                                                              *
* If the run completes, the top 10 errors are presented, with the highest      *
* count first to lowest last. These are the number of errors caused by just    *
* a one character source change, so its directly indicative of the quality of  *
* the parser's error recovery.                                                 *
*                                                                              *
* The top error entry is replaced back into the spewtest.pas file, this is     *
* for the convienence of being able to immediately test for the highest        *
* error count case.                                                            *
*                                                                              *
*******************************************************************************}

program spew(output, command);

uses strlib, { string library }
     extlib; { extentions library }

const namlen = 100; { maximum length of source file name }
      altchr = '!'; { alternate test character }
      errno  = 10;  { number of top count errors to log (must be even) }

type filnam = packed array namlen of char; { filename }
     { error log entry }
     errrec = record

        errcnt: integer; { number of errors }
        errlin: integer; { line it occurred on }
        errchr: integer  { character it occurred on }

     end;

var srcnam:  filnam;
    i:       integer;
    lincnt:  integer; { line we are testing on }
    chrcnt:  integer; { character of testing line }
    p, n, e: filnam;  { filename components }
    srcfil:  text;    { source file }
    tmpfil:  text;    { temp file }
    done:    boolean; { done with testing flag }
    { top error log }
    errlog:  array errno of errrec;
    ei:      1..errno;  { index for that }   

{*******************************************************************************

Parse command line

Parses the single source file name off the input command line.

*******************************************************************************}

procedure parcmd;

begin

   clears(srcnam); { clear source name }
   { get the source name }
   while (command^ = ' ') and not eoln(command) do get(command); { skip blanks }
   i := 1; { set 1st character }
   while (command^ <> ' ') and not eoln(command) do begin { get charaters }

      if i > namlen then begin

         writeln('*** Source file name too long');
         halt

      end;
      srcnam[i] := command^; { place character }
      get(command); { get next character }
      i := i+1 { next }

   end;
   if srcnam[1] = ' ' then begin { no source name }

      writeln('*** Invalid source file name');
      halt

   end;
   while (command^ = ' ') and not eoln(command) do get(command); { skip blanks }
   if not eoln(command) then begin { garbage after name }

      writeln('*** Invalid source file name');
      halt

   end

end;

{*******************************************************************************

Create temp file

Copies the source file to a temp file. When the line and character counts match
the one we are testing, we output the alternate character to the file, then
continue copying until we reach the end of the file. If we reach the end of the
file, and the error point is not encountered, then the done flag is set.

*******************************************************************************}

procedure createtemp(ac: char); { alternate character }

var c:     char;    { character buffer }
    lc:    integer; { line counter }
    cc:    integer; { character counter }
    found: boolean; { found replacement position }
    fcc:   integer; { found line length }

begin

   done := false; { set not done }
   found := false; { set not done }
   assign(srcfil, srcnam); { assign to source file }
   reset(srcfil); { reset to start of source }
   assign(tmpfil, 'spewtest.pas'); { assign testfile name }
   rewrite(tmpfil); { rewrite the output file }
   lc := 1; { set line and character counters }
   cc := 1;
   fcc := 0; { clear found line count }
   { copy source file to temp file }
   while not eof(srcfil) do begin { until end of source }

      while not eoln(srcfil) do begin { read source line }

         read(srcfil, c); { get next source file character }
         { if we are at the test location, replace the character with the
           alternate }
         if (lc = lincnt) and (cc = chrcnt) then begin

            c := ac; { replace character }
            found := true { flag replacement occurred }

         end;
         write(tmpfil, c); { output to temp file }
         cc := cc+1 { count characters }

      end;
      { if we found a line, then put the length of that line here }
      if (fcc = 0) and found then fcc := cc;
      readln(srcfil); { next line }
      writeln(tmpfil);
      lc := lc+1; { count lines }
      cc := 1 { reset characters }

   end;
   close(srcfil); { close files }
   close(tmpfil);
   { advance character count }
   chrcnt := chrcnt+1;
   if chrcnt >= fcc then begin { off end of line, go next line }

      lincnt := lincnt+1; { count off lines }
      chrcnt := 1 { reset character count }

   end;
   { check test counter off end of file }
   done := lincnt >= lc

end;

{*******************************************************************************

Place error in error log

Finds the minimum count entry in the error log, and replaces that. If the new
error is not above that, it is discarded.

*******************************************************************************}

procedure logerr(err, lin, chr: integer); { error parameters }

var ei:  1..errno; { error log index }
    min: integer;  { minimum error count }
    mi:  0..errno; { index for minimum entry }

begin

   min := maxint; { set no minimum }
   mi := 0;
   { find minimum entry }
   for ei := 1 to errno do with errlog[ei] do begin

      if errcnt < min then begin { found an entry smaller than last, use it }

         min := errcnt; { save error count }
         mi := ei { save index }

      end

   end;
   if mi = 0 then mi := 1 { no entries, just place at 1st log position }
   else if min > err then mi := 0; { min is greater than new, discard new }
   if mi > 0 then with errlog[mi] do begin { replace minimum entry }

      errcnt := err; { set error count }
      errlin := lin; { set line }
      errchr := chr  { set character }

   end

end;

{*******************************************************************************

Sort the error log

Just bubble sorts the error log. Speed is not a big issue here.

*******************************************************************************}

procedure srterr;

var errsav: errrec;   { save for error log entry }
    swap:   boolean;  { swap flag }
    ei:     1..errno; { index for that }   

begin

   repeat { sort table }

      swap := false; { set no swap happened }
      ei := 1; { set 1st entry }
      while ei < errno do begin { traverse the log }

         if errlog[ei].errcnt < errlog[ei+1].errcnt then begin { swap }

            errsav := errlog[ei]; { save this entry }
            errlog[ei] := errlog[ei+1]; { copy next to this }
            errlog[ei+1] := errsav; { place this to next }
            swap := true { set swap occurred }

         end;
         ei := ei+1 { skip to next pair }

      end

   until not swap { until no swap occurred }

end;

{*******************************************************************************

Analize error file

Reads the error output file, and analizes the errors it contains. The errors
are counted, and the string "System fault" is searched for in error lines.
If a system fault is found, then we exit immediately and print the offending
line, which will contain the system fault number.

Otherwise, just returns the error count.

*******************************************************************************}

procedure anaerr;

var errfil: text;                          { error file }
    linbuf: packed array [1..200] of char; { line buffer }
    ec:     integer;                       { error count }

begin

   if exists('spewtest.err') then begin

      ec := 0; { clear error count }
      assign(errfil, 'spewtest.err'); { open the error file }
      reset(errfil);
      while not eof(errfil) do begin { read lines }

         reads(errfil, linbuf); { read line to buffer }
         if linbuf[1] = '*' then begin { its an error line }

            ec := ec+1; { count errors }
            { check and set system fault }
            if index(linbuf, 'System fault') > 0 then begin

               writeln;
               writeln('System fault found:');
               writeln;
               writeln(linbuf:0);
               halt

            end

         end;
         readln(errfil) { next line }

      end;
      close(errfil)

   end;
   logerr(ec, lincnt, chrcnt) { log the error stats }

end;
   
{*******************************************************************************

Run test parse

We copy the source file to a temp file with the inserted error, then run a parse
on the temp file, and collect and tabulate the errors.

*******************************************************************************}

procedure testparse(ac: char);

var err: integer;

begin

   createtemp(ac); { create temp file }
   if not done then begin { not end of file }

      execw('parse spewtest/e=spewtest/nv/s', err);
      if err > 1 then begin { error was operator attention, halt }

         writeln;
         writeln('*** Operator attention error');
         writeln;
         writeln('Line: ', lincnt:1);
         writeln('Char: ', chrcnt:1);
         writeln;
         halt

      end;
      anaerr { do error analisys }

   end

end;

begin

   writeln;
   writeln('Spew test vs. 1.0');
   { clear error logging array }
   for ei := 1 to errno do with errlog[ei] do begin

      errcnt := 0; { clear error count }
      errlin := 0; { clear line number }
      errchr := 0  { clear character number }

   end;
   parcmd; { parse source file }
   brknam(srcnam, p, n, e);  { break down filename }
   if e[1] = ' ' then copy(e, 'pas'); { place extention if not set }
   maknam(srcnam, p, n, e); { create final source name }
   if not exists(srcnam) then begin

      writeln('*** Source file does not exist');
      halt

   end;
   writeln('Testing with: ', srcnam:0);
   lincnt := 1; { set 1st line and character }
   chrcnt := 1;
   repeat { run test }

      writeln('Testing: Line: ', lincnt:1, ' Char: ', chrcnt:1);
      testparse(altchr) { with alternate character }

   until done; { until end of source file reached }

   srterr; { sort the error log }
   { print out error log }
   writeln;
   writeln('Error log (maximum first to minimum last)');
   writeln;
   for ei := 1 to errno do with errlog[ei] do if errcnt > 0 then
      writeln('Count: ', errcnt:1, ' line: ', errlin:1, ' char: ', errchr:1);
   writeln;
   { reproduce the top error count for testing convience }
   if errlog[1].errcnt > 0 then begin

      lincnt := errlog[1].errlin; { set line }
      chrcnt := errlog[1].errchr; { set character }
      createtemp(altchr); { reproduce the file }
      writeln('The maximum error case has been reproduced in spewtest.pas');
      writeln

   end;

   writeln('Function complete')

end.
