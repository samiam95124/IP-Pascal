{******************************************************************************
*                                                                             *
*                         TEST SUITE FOR IP PASCAL                            *
*                                                                             *
*            Copyright (C) 2004 S. A. Moore - All rights reserved             *
*                                                                             *
* This program tests the extentions to ISO 7185 standard pascal that are used *
* in IP Pascal. This program attempts to use and display the results of each  *
* feature of IP Pascal. It is a "positive" test in that it should compile and *
* run error free, and thus does not check error conditions/detection.         *
*                                                                             *
* Each test is labeled and numbered, and the expected result also output, so  *
* that the output can be self evidently hand checked.                         *
*                                                                             *
* The output can be redirected to a printer or a file to facillitate such     *
* checking.                                                                   *
*                                                                             *
* The output can also be automatically checked by comparing a known good file *
* to the generated file. To this end, we have regularized the output,         *
* specifying all output field widths that are normally compiler dependent.    *
*                                                                             *
* Notes:                                                                      *
*                                                                             *
* 1. Cannot use set of integer format in fixed sets for set_exp1.             *
*                                                                             *
******************************************************************************}
        
program extended(output);

{ this will test for extended labeling }

var a_1: integer;
    c:   char;
    i, x, y:   integer;

{ this tests relaxed declarations }

const c_one = 1;

{ this tests alphabetical goto labels }

label skipover;

{ test constant expressions }

const not_exp = not 42;
      mlt_exp = 13*10;
      div_exp = 124 div 5;
      rdiv_exp = 1.234/543.22;
      mod_exp = 54 mod 13;
      and_exp = 76 and 12;
      neg_exp = -76;
      pos_exp = +54;
      add_exp = 74+23;
      sub_exp = 87-34;
      or_exp = 34 or 72;
      xor_exp = 31 xor 53;
      set_exp = ['a'..'d', 'z'];
      { set_exp1 = [1..5, 10+2]; }

type iarr   = array of integer;

fixed f_i: integer = 432;
      f_c: char = 'Q';
      f_r: real = 1.23456;
      f_s: packed array [1..8] of char = 'hi there';
      f_ai: packed array [1..5] of integer = array 1, 5, 3, 10, 92 end;
      f_ac: packed array [1..5] of char = array 'a', 'h', 'u', 'o', 'z' end;
      f_ar: packed array [1..5] of real = array 1.1, 1.2, 1.3, 1.4, 1.5 end;
      f_ma: packed array [1..3, 1..4] of integer = array

         array 1, 3, 64, 2 end,
         array 12, 31, 647, 21 end,
         array 190, 32, 641, 243 end

      end;
      f_rc: record i: integer; c: char; r: real end = record 42, 'a', 1.234 end;

type enum_a = (one, two, three);
     string = packed array of char;
     pstring = ^string;
     byte = 0..255;

var s: ^string;
    st: packed array [1..10] of char;
    ia: ^iarr;
    a, b: integer;
    ft: text;
    fb: file of byte;
    ba: byte;
    sp: pstring;

{ this tests duplication of parameter lists }

procedure prtstr(view s: string); forward;

procedure prtstr(view s: string);

begin

   write(s)

end;

function getstr: pstring;

var p: pstring;

begin

   new(p, 8);
   p^ := 'hi there';
   getstr := p

end;

begin

   write('****************************************************************');
   writeln('***************');
   writeln;
   writeln('                       TEST SUITE FOR IP PASCAL');
   writeln;
   write('                 Copyright (C) 2004 S. A. Moore - All rights ');
   writeln('reserved');
   writeln;
   write('****************************************************************');
   writeln('***************');
   writeln;

   writeln('ext1: ', $a5:1, ' s/b 165');
   writeln('ext2: ', &72:1, ' s/b 58');
   writeln('ext3: ', %011001:1, ' s/b ', 25:1);
   writeln('ext4: my\'self s/b my''self');
   writeln('ext5: this\\one s/b this<slash>one');
   writeln('ext6: \101 s/b e');
   writeln('ext7: \$6f s/b o');
   writeln('ext8: \&132 s/b Z');
   writeln('ext9: \%1001001 s/b I');
   writeln('ext10: ');
   write(ord('\nul'):1, ' ');
   write(ord('\soh'):1, ' ');
   write(ord('\stx'):1, ' ');
   write(ord('\etx'):1, ' ');
   write(ord('\eot'):1, ' ');
   write(ord('\enq'):1, ' ');
   write(ord('\ack'):1, ' ');
   write(ord('\bel'):1, ' ');
   write(ord('\bs'):1, ' ');
   write(ord('\ht'):1, ' ');
   write(ord('\lf'):1, ' ');
   write(ord('\vt'):1, ' ');
   write(ord('\ff'):1, ' ');
   write(ord('\cr'):1, ' ');
   write(ord('\so'):1, ' ');
   write(ord('\si'):1, ' ');
   write(ord('\dle'):1, ' ');
   write(ord('\dc1'):1, ' ');
   write(ord('\xon'):1, ' ');
   write(ord('\dc2'):1, ' ');
   write(ord('\dc3'):1, ' ');
   write(ord('\xoff'):1, ' ');
   write(ord('\dc4'):1, ' ');
   writeln;
   write(ord('\nak'):1, ' ');
   write(ord('\syn'):1, ' ');
   write(ord('\etb'):1, ' ');
   write(ord('\can'):1, ' ');
   write(ord('\em'):1, ' ');
   write(ord('\sub'):1, ' ');
   write(ord('\esc'):1, ' ');
   write(ord('\fs'):1, ' ');
   write(ord('\gs'):1, ' ');
   write(ord('\rs'):1, ' ');
   write(ord('\us'):1, ' ');
   writeln(ord('\del'):1, ' ');
   writeln('s/b 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 17 18 19 19 20');
   writeln('21 22 23 24 25 26 27 28 29 30 31 127');
   write('ext11: start ');
   goto skipover;
   write('!!! BAD !!!');
   skipover: writeln(' stop s/b start stop');
   writeln('ext12: ', not_exp:1,  ' s/b -43');
   writeln('ext13: ', mlt_exp:1,  ' s/b 130');
   writeln('ext14: ', div_exp:1,  ' s/b 24');
   writeln('ext15: ', rdiv_exp:1:4, ' s/b 0.0022');
   writeln('ext16: ', mod_exp:1,  ' s/b 2');
   writeln('ext17: ', and_exp:1,  ' s/b 12');
   writeln('ext18: ', neg_exp:1,  ' s/b -76');
   writeln('ext19: ', pos_exp:1,  ' s/b 54');
   writeln('ext20: ', add_exp:1,  ' s/b 97');
   writeln('ext21: ', sub_exp:1,  ' s/b 53');
   writeln('ext22: ', or_exp:1,   ' s/b 106');
   writeln('ext23: ', xor_exp:1,  ' s/b 42');
   write('ext24: ');
   for c := 'a' to 'z' do if c in set_exp then write(c);
   writeln(' s/b abcdz');
{   write('ext11: ');
   for i := 1 to 20 do if i in set_exp1 then write(i:1, ' ');
   writeln(' s/b 1 2 3 4 5 12');
}
   writeln('ext25: ', f_i:1, ' s/b 432');
   writeln('ext26: ', f_c, ' s/b Q');
   writeln('ext27: ', f_r, ' s/b 1.23456000e+000');
   writeln('ext28: ', f_s, ' s/b hi there');
   write('ext29: ');
   for i := 1 to 5 do write(f_ai[i]:1, ' ');
   writeln(' s/b 1 5 3 10 92');
   write('ext30: ');
   for i := 1 to 5 do write(f_ac[i]);
   writeln(' s/b ahuoz');
   write('ext31: ');
   for i := 1 to 5 do write(f_ar[i]:1:1, ' ');
   writeln(' s/b 1.1 1.2 1.3 1.4 1.5');
   write('ext32: ');
   for x := 1 to 3 do
      for y := 1 to 4 do write(f_ma[x, y]:1, ' ');
   writeln(' s/b 1 3 64 2 12 31 647 21 190 32 641 243');
   writeln('ext33: ', f_rc.i:1, f_rc.c, f_rc.r:1:4, ' s/b 42a1.2340');
   write('ext34: ');
   for i := 0 to 2 do case enum_a(i) of

      one: write('one ');
      two: write('two ');
      three: write('three ')

   end;
   writeln(' s/b one two three');
   write('ext35: ');
   new(s, 10);
   s^ := 'hi there ?';
   write(s^);
   writeln(' s/b hi there ?');
   write('ext36: ');
   new(s, 10);
   s^ := 'hi there ?';
   st := s^;
   write(st);
   writeln(' s/b hi there ?');
   write('ext37: ');
   new(s, 10);
   s^ := 'hi there ?';
   for i := 1 to 10 do write(s^[i]);
   writeln(' s/b hi there ?');
   write('ext38: ');
   new(ia, 10);
   ia^[1] := 143;
   ia^[2] := 276;
   ia^[3] := 388;
   ia^[4] := 412;
   ia^[5] := 574;
   ia^[6] := 622;
   ia^[7] := 74;
   ia^[8] := 83;
   ia^[9] := 99;
   ia^[10] := 1;
   for i := 1 to 10 do write(ia^[i]:1, ' ');
   writeln(' s/b 143 276 388 412 574 622 74 83 99 1');
   a := 56;
   b := 13;
   writeln('ext39: ', not a:1, ' s/b -57');
   writeln('ext40: ', a and b:1, ' s/b 8');
   writeln('ext41: ', a or b:1, ' s/b 61');
   writeln('ext42: ', a xor b:1, ' s/b 53');
   write('ext43: ');
   prtstr('hi george');
   writeln(' s/b hi george');
   write('ext44: ');
   if exists('ext0001.txt') then delete('ext0001.txt');
   if exists('ext0002.txt') then delete('ext0002.txt');
   assign(ft, 'ext0001.txt');
   rewrite(ft);
   writeln(ft, 'hi there, bob');
   reset(ft);
   while not eoln(ft) do begin

      read(ft, c);
      write(c);

   end;
   close(ft);
   writeln(' s/b hi there, bob');
   write('ext45: ');
   change('ext0002.txt', 'ext0001.txt');
   assign(ft, 'ext0002.txt');
   reset(ft);
   while not eoln(ft) do begin

      read(ft, c);
      write(c);

   end;
   close(ft);
   writeln(' s/b hi there, bob');
   writeln('ext46: ', exists('ext0001.txt'), ' s/b false');
   writeln('ext47: ', exists('ext0002.txt'), ' s/b true');
   delete('ext0002.txt');
   writeln('ext48: ', exists('ext0002.txt'), ' s/b false');
   write('ext37: ');
   assign(fb, 'ext0001.txt');
   rewrite(fb);
   for i := 1 to 10 do write(fb, i);
   reset(fb);
   for i := 10 downto 1 do begin read(fb, ba); write(ba:1, ' ') end;
   writeln(' s/b 1 2 3 4 5 6 7 8 9 10');
   writeln('ext49: ', length(fb):1, ' s/b 10');
   writeln('ext50: ', location(fb):1, ' s/b 10');
   write('ext51: ');
   position(fb, 5);
   read(fb, ba);
   writeln(ba:1, ' s/b 5');
   writeln('ext52: ', location(fb):1, ' s/b 6');
   write('ext53: ');
   sp := getstr;
   writeln(sp^, ' s/b hi there');
   writeln('The test should now halt');
   halt;
   writeln('!!! Bad !!! halt did not take effect')

end.
