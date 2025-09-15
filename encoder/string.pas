!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

String class

Defines a string class, or full dynamic string capability.

!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

program p;

class stringc(clen: integer);

type sdata:   packed array of char;
     stringp: ^sdata;
     ref:     reference to stringc;

var data: stringp; ! data in string
    len:  integer; ! length of string

! assign string object to another

operator procedure := (d, s: ref);

var i: integer;

begin

   d.len := s.len
   if max(d.data) < max(s.data) then

      ! String length exceeds buffer
      dispose(d.data); ! dispose of old buffer
      new(d.data, len) ! allocate new buffer

   end;
   for i := 1 to d.len do d.data[i] := s.data[i] ! copy string data

end;

! assign legacy pascal string to string object

operator procedure := (d: ref; view s: sdata);

var i: integer;

begin

   if max(d.data) < max(s.data) then

      ! String length exceeds buffer
      dispose(d.data); ! dispose of old buffer
      new(d.data, len) ! allocate new buffer

   end;
   d.len := max(s); ! set length
   for i := 1 to d.len do d.data[i] := s[i] ! copy string data

end;

begin  ! constructor

   len := clen; ! place length
   new(data, len) ! allocate string buffer

end;
