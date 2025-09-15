program test1(output);

uses extlib;

var el: envptr;

begin

   allenv(el);
   writeln('Environment:');
   writeln;
   while el <> nil do begin

      writeln('Name: ', el^.name^, 'Value: ', el^.data^);
      el := el^.next

   end

end.