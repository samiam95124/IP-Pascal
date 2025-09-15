program test(input, output);

uses trmlib;

var er: evtrec; { event record }

begin

   timer(input, 1, 100000, false);
   repeat

      event(input, er);
	  if er.etype = ettim then writeln('it happened');
	  write('.')

   until false

end.
