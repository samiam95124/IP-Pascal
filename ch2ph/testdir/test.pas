{*******************************************************************************

IP Pascal header file translated from test.c

*******************************************************************************}

module test;

uses stddef,
     spcdef;

{ Standard C type equivalences }

type

sc_c_lang_float = sreal;
sc_c_lang_double = real;
sc_c_lang_long_double = real;
sc_c_lang_char = char;
sc_c_lang_signed_char = char;
sc_c_lang_unsigned_char = 0..255;
sc_c_lang_int = integer;
sc_c_lang_signed_int = integer;
sc_c_lang_unsigned_int = integer;
sc_c_lang_short_int = -32768..32767;
sc_c_lang_long_int = integer;
sc_c_lang_signed_short_int = -32768..32767;
sc_c_lang_signed_long_int = integer;
sc_c_lang_unsigned_short_int = 0..65535;
sc_c_lang_unsigned_long_int = integer;

{ The types function and void are both unrepresentable }
{ in Pascal, so they become integers. The options are: }

{ 1. Change them with a instruction file rule.         }
{ 2. Use an assembly escape routine that can actually  }
{ make them integers.                                  }
{ 3. Find them and change them manually.               }

sc_c_lang_function = integer;
sc_c_lang_void = integer;

type


 { Function definitions }

procedure sc_myfunca(i: sc_c_lang_int; j: sc_c_lang_int; k: sc_c_lang_int); 
   begin end;
procedure sc_myfunc(i: sc_c_lang_int; j: sc_c_lang_int; k: sc_c_lang_int); 
   begin end;
procedure sc_myfunc_biteme(i: char; j: sc_c_lang_int; k: sc_c_lang_int); 
   begin end;

{ 3 function definitions output }

begin
end.
