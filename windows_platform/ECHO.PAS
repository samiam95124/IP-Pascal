{**************************************************************

Echo system utility

10/84 S. A. Moore

Prints the command line after 'echo', minus the leading spaces.
Used for printout in 'submit' files.

**************************************************************}

program echo(command, { command line to echo }
             output); { output for print }

var c : char; { holding character }

begin { echo }

   c := ' '; { initalize buffer }
   { skip any leading spaces }
   while not eoln(command) and (c = ' ') do read(command, c);
   if c <> ' ' then write(c); { output leading character }
   while not eoln(command) do begin

      read(command, c); { get command character }
      write(c) { output }

   end;
   writeln { terminate line }

end. { echo }
