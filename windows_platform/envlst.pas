program envlst(output);

uses windows;

var evstbl: sc_evsptr;

begin

   writeln('Environment strings:');
   evstbl := sc_getenvironmentstrings;
   while evstbl <> nil do begin

      writeln(evstbl^.str^);
      evstbl := evstbl^.next

   end

end.

