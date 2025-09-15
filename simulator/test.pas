program test(output, command);

var c: char;

begin

   while not eoln(command) do begin

     read(command, c);
     write(c)

   end;
   writeln

end.
