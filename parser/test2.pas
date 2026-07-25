process test2(output);

uses test1;

begin

   waitsig;
   writeln('task 2: got the signal')

end.
