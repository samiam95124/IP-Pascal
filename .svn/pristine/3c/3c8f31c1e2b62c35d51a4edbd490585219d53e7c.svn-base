program test(output);

label 99;

type string = packed array of char;

var s: packed array [1..40] of char;

{ assign string to fixed string with space padding }

procedure astr(var ds: string; view ss: string);

var i: integer;

begin

   if max(ss) > max(ds) then begin

        writeln('*** String overflow');
        goto 99

   end;
   for i := 1 to max(ss) do ds[i] := ss[i]; { copy to result }
   for i := max(ss)+1 to max(ds) do ds[i] := ' ' { place padding }

end;

{ find length of padded string }

function len(view s: string): integer;

var i: integer;

begin

   i := max(s); { index end of string }
   while (i > 1) and (s[i] = ' ') do i := i-1; { find last character }
   if s[i] = ' ' then i := 0; { must be empty }
   len := i { return length }

end;

{  concatenate padded strings }

procedure concat(var ds: string; view ss: string);

var dl, sl: integer; { string lengths }
    i:      integer; { string index }

begin

   dl := len(ds); { find string lengths, once only }
   sl := len(ss);
   if dl+sl > max(ds) then begin

        writeln('*** String overflow');
        goto 99

   end;
   for i := 1 to sl do ds[dl+i] := ss[i] {append string }

end;

{ extract string }

procedure extstr(var ds: string; view ss: string; si, ei: integer);

var i: integer;

begin

   if ei-si+1 > max(ds) then begin

        writeln('*** String overflow');
        goto 99

   end;
   for i := 1 to ei-si do ds[i] := ss[si+i-1]; { transfer section }
   for i := ei-si+1 to max(ds) do ds[i] := ' ' { pad destination }

end;

{ write padded string }

procedure wrtstr(view s: string);

var i: integer;

begin

   for i := 1 to len(s) do write(s[i])

end;

begin

   astr(s, 'hello, world');
   concat(s, '(and happyness reigns)');
   write('"');
   wrtstr(s);
   writeln('"');

   99:

end.
   


