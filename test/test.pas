program test(output);

var li: linteger;
    x:  integer;

begin

   li := maxlint;
   x := 0;
   while li > 0 do begin 
   
;writeln('li: ', li:1);
      li := li div 2;  
      x := x+1 
      
   end;
   writeln('Bit length of long integer without sign appears to be: ', x:1)
   
end.
