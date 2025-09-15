{*******************************************************************************

IP Pascal header file translated from test1.c

*******************************************************************************}

module test1;

uses stddef;

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

sc_b = record
   a: sc_c_lang_int;
   c: sc_c_lang_char;
end;
sc_g = record
   d: sc_c_lang_char;
   rf_pad_2: sc_c_lang_unsigned_char;
   rf_pad_3: sc_c_lang_unsigned_char;
   rf_pad_4: sc_c_lang_unsigned_char;
   z: sc_b;
   rf_pad_6: sc_c_lang_unsigned_char;
   rf_pad_7: sc_c_lang_unsigned_char;
   rf_pad_8: sc_c_lang_unsigned_char;
   f: sc_c_lang_int;
end;

 { Function definitions }


begin
end.
