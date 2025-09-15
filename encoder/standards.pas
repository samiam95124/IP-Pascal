(******************************************************************************
*                                                                             *
*                  TEST SUITE FOR ISO 7185 PASCAL/Pascals subset              *
*                                                                             *
*            Copyright (C) 1994 S. A. Moore - All rights reserved             *
*                                                                             *
* This is the standard.pas suite cut down to fit within the Pascal-s          *
* language subset. See standard.pas for more details.                         *
*                                                                             *
******************************************************************************)

program standards(output);

const tcnst = 768;
      tsncst = -52;
      ccst = 'v';
      rcnst = 43.33;
      rscst = -84.22;

type
     arri  = array [1..10] of integer;
     recs  = record

               a: integer;
               b: char

            end;
     arrim = array [1..2, 1..2] of array [1..2, 1..2, 1..2, 1..2] of integer;
     rec = record

              i:   integer;
              b:   boolean;
              c:   char;
              r:   real;
              a:   arri;
              rc:  recs

           end;

var i, x, y, z, q, n, t : integer;
    as, bs, cs, ds, es: integer;
    ca, cb, cc: char;
    car:  array ['a'..'z'] of integer;
    r : record

           rx: integer;
           rc: char;
           ry: integer;
           rb: boolean;
           rs: array [1..10] of char

        end;
    ba, bb, bc : boolean;
    ra, rb, rc, rd, re: real;
    avi: arri;
    avi2: arri;
    avb: array [1..10] of boolean;
    avr: array [1..10] of real;
    avc: array [1..10] of char;
    avrc: array [1..10] of recs;
    ai: arri;
    da: array [1..10, 1..10] of integer;
    mdar: arrim;
    mdar2: arrim;
    arec: rec;
    nvr:   record

              i: integer;
              r: record

                 i: integer;
                 r: record

                    i: integer;
                    r: record

                       i: integer;
                       r: record

                          i: integer;
                          r: record

                             i: integer;
                             r: record

                                i: integer;
                                r: record

                                   i: integer;
                                   r: record

                                      i: integer;
                                      r: record

                                         i: integer

                                      end

                                   end

                                end

                             end

                          end

                       end

                    end

                 end

              end

           end;

procedure junk1(z, q : integer);
 
begin

   write(z:1, ' ', q:1);

end;
 
procedure junk2(var z : integer);
 
begin

   z := z + 1

end;
 
function junk5(x : integer) : integer;
 
begin

   junk5 := x + 1

end;

function junk7(a, b, c: integer): integer;

var x, y, z: integer;

begin

   x := 1;
   y := 2;
   z := 3;
   write(a:1, ' ', b:1, ' ', c:1, ' ');
   a := 4;
   b := 5;
   c := 6;
   write(c:1, ' ', b:1, ' ', a:1, ' ', z:1, ' ', y:1, ' ', x:1);
   junk7 := 78

end;

procedure junk8(a: integer; b: boolean; c: char; r: real; ar: arri; rc: rec);

var i:  integer;
    ci: char;

begin

   writeln(a:1, ' ', b:5, ' ', c:1, ' ', r:15);
   for i := 1 to 10 do write(ar[i]:1, ' '); writeln;
   writeln(rc.i:1, ' ', rc.b:5, ' ', rc.c:1, ' ', rc.r:15, ' ');
   for i := 1 to 10 do write(rc.a[i]:1, ' '); writeln;
   writeln(rc.rc.a:1, ' ', rc.rc.b:1)

end;

procedure junk14;

var i, x: integer;

procedure junk15;

begin

   write(i:1, ' ', x:1)

end;

begin

   i := 62;
   x := 76;
   junk15

end;

begin

   write('****************************************************************');
   writeln('***************');
   writeln;
   writeln('                 TEST SUITE FOR PASCAL-S PASCAL');
   writeln;
   write('                 Copyright (C) 1995 S. A. Moore - All rights ');
   writeln('reserved');
   writeln;
   write('****************************************************************');
   writeln('***************');
   writeln;

(******************************************************************************

                           Control structures

******************************************************************************)

   writeln;
   writeln('******************* Control structures tests *******************');
   writeln;
   write('Control1: ');
   for i := 1 to 10 do write(i:1, ' ');
   writeln('s/b 1 2 3 4 5 6 7 8 9 10');
   write('Control2: ');
   for i := 10 downto 1 do write(i:1, ' ');
   writeln('s/b 10 9 8 7 6 5 4 3 2 1');
   write('Control3: ');
   i := 1;
   while i <=10 do begin write(i:1, ' '); i := i + 1 end;
   writeln('s/b 1 2 3 4 5 6 7 8 9 10');
   write('Control4: ');
   i := 1; repeat write(i:1, ' '); i := i + 1 until i > 10;
   writeln('s/b 1 2 3 4 5 6 7 8 9 10');
   write('Control6: ');
   if true then write('yes') else write('no');
   writeln(' s/b yes');
   write('Control7: ');
   if false then write('no') else write('yes');
   writeln(' s/b yes');
   write('Control8: ');
   if true then write('yes '); write('stop');
   writeln(' s/b yes stop');
   write('Control9: ');
   if false then write('no '); write('stop');
   writeln(' s/b stop');
   write('Control10: ');
   for i := 1 to 10 do
      case i of
         1:     write('one ');
         2:     write('two ');
         3:     write('three ');
         4:     write('four ');
         5:     write('five ');
         6:     write('six ');
         7:     write('seven ');
         8:     write('eight ');
         9, 10: write('nine-ten ')

      end;
   writeln;
   write('Control10: s/b ');
   write('one two three four five ');
   writeln('six seven eight nine-ten nine-ten');

(******************************************************************************

                            Integers

******************************************************************************)

   writeln;
   writeln('******************* Integers *******************');
   writeln;

   (* integer variables *)
   x := 43; y := 78; z := y;
   writeln('Integer1:   ', x + y:1, ' s/b 121');
   writeln('Integer2:   ', y - x:1, ' s/b 35');
   writeln('Integer3:   ', x * y:1, ' s/b 3354');
   writeln('Integer4:   ', y div x:1, ' s/b 1');
   writeln('Integer5:   ', y mod x:1, ' s/b 35');
   writeln('Integer8:   ', chr(y), ' s/b N');
   writeln('Integer9:   ', ord(chr(x)):1, ' s/b 43');
   writeln('Integer10:  ', odd(x):5, ' s/b true');
   writeln('Integer11:  ', odd(y):5, ' s/b false');
   writeln('Integer12:  ', z = y:5, ' s/b true');
   writeln('Integer13:  ', x = y:5, ' s/b false');
   writeln('Integer14:  ', x < y:5, ' s/b true');
   writeln('Integer15:  ', y < x:5, ' s/b false');
   writeln('Integer16:  ', y > x:5, ' s/b true');
   writeln('Integer17:  ', x > y:5, ' s/b false');
   writeln('Integer18:  ', x <> y:5, ' s/b true');
   writeln('Integer19:  ', y <> z:5, ' s/b false');
   writeln('Integer20:  ', x <= y:5, ' s/b true');
   writeln('Integer21:  ', z <= y:5, ' s/b true');
   writeln('Integer22:  ', y <= x:5, ' s/b false');
   writeln('Integer23:  ', y >= x:5, ' s/b true');
   writeln('Integer24:  ', y >= z:5, ' s/b true');
   writeln('Integer25:  ', x >= y:5, ' s/b false');
 
   (* unsigned integer constants *)
   write('Integer31:  '); i := 546; writeln(i:1, ' s/b 546');
   writeln('Integer32:  ', 56 + 34:1, ' s/b 90');
   writeln('Integer33:  ', 56 - 34:1, ' s/b 22');
   writeln('Integer34:  ', 56 * 34:1, ' s/b 1904');
   writeln('Integer35:  ', 56 div 34:1, ' s/b 1');
   writeln('Integer36:  ', 56 mod 34:1, ' s/b 22');
   writeln('Integer39:  ', chr(65), ' s/b A');
   writeln('Integer40:  ', ord(chr(65)):1, ' s/b 65');
   writeln('Integer41:  ', tcnst:1, ' s/b 768');
   writeln('Integer42:  ', odd(5):5, ' s/b true');
   writeln('Integer43:  ', odd(8):5, ' s/b false');
   writeln('Integer44:  ', 56 = 56:5, ' s/b true');
   writeln('Integer45:  ', 56 = 57:5, ' s/b false');
   writeln('Integer46:  ', 56 < 57:5, ' s/b true');
   writeln('Integer47:  ', 57 < 56:5, ' s/b false');
   writeln('Integer48:  ', 57 > 56:5, ' s/b true');
   writeln('Integer49:  ', 56 > 57:5, ' s/b false');
   writeln('Integer50:  ', 56 <> 57:5, ' s/b true');
   writeln('Integer51:  ', 56 <> 56:5, ' s/b false');
   writeln('Integer52:  ', 55 <= 500:5, ' s/b true');
   writeln('Integer53:  ', 67 <= 67:5, ' s/b true');
   writeln('Integer54:  ', 56 <= 33:5, ' s/b false');
   writeln('Integer55:  ', 645 >= 4:5, ' s/b true');
   writeln('Integer56:  ', 23 >= 23:5, ' s/b true');
   writeln('Integer57:  ', 45 >= 123:5, ' s/b false');

   (* signed integer variables *)
   as := -14;
   bs := -32;
   cs := -14;
   ds := 20;
   es := -15;
   writeln('Integer58:  ', as + ds:1, ' s/b 6');
   writeln('Integer59:  ', ds + as:1, ' s/b 6');
   writeln('Integer60:  ', bs + ds:1, ' s/b -12');
   writeln('Integer61:  ', as + bs:1, ' s/b -46');
   writeln('Integer62:  ', ds - as:1, ' s/b 34');
   writeln('Integer63:  ', bs - ds:1, ' s/b -52');
   writeln('Integer64:  ', bs - as:1, ' s/b -18');
   writeln('Integer65:  ', ds * as:1, ' s/b -280');
   writeln('Integer66:  ', as * ds:1, ' s/b -280');
   writeln('Integer67:  ', as * bs:1, ' s/b 448');
   writeln('Integer68:  ', ds div as:1, ' s/b -1');
   writeln('Integer69:  ', bs div ds:1, ' s/b -1');
   writeln('Integer70:  ', bs div as:1, ' s/b 2');
   writeln('Integer73:  ', odd(as):5, ' s/b false');
   writeln('Integer74:  ', odd(es):5, ' s/b true');
   writeln('Integer75:  ', as = cs:5, ' s/b true');
   writeln('Integer76:  ', as = bs:5, ' s/b false');
   writeln('Integer77:  ', as <> bs:5, ' s/b true');
   writeln('Integer78:  ', as <> cs:5, ' s/b false');
   writeln('Integer79:  ', as < ds:5, ' s/b true');
   writeln('Integer80:  ', bs < as:5, ' s/b true');
   writeln('Integer81:  ', ds < as:5, ' s/b false');
   writeln('Integer82:  ', as < bs:5, ' s/b false');
   writeln('Integer83:  ', ds > as:5, ' s/b true');
   writeln('Integer84:  ', as > bs:5, ' s/b true');
   writeln('Integer85:  ', as > ds:5, ' s/b false');
   writeln('Integer86:  ', bs > as:5, ' s/b false');
   writeln('Integer87:  ', as <= ds:5, ' s/b true');
   writeln('Integer88:  ', bs <= as:5, ' s/b true');
   writeln('Integer89:  ', as <= cs:5, ' s/b true');
   writeln('Integer90:  ', ds <= as:5, ' s/b false');
   writeln('Integer91:  ', as <= bs:5, ' s/b false');
   writeln('Integer92:  ', ds >= as:5, ' s/b true');
   writeln('Integer93:  ', as >= bs:5, ' s/b true');
   writeln('Integer94:  ', as >= cs:5, ' s/b true');
   writeln('Integer95:  ', as >= ds:5, ' s/b false');
   writeln('Integer96:  ', bs >= as:5, ' s/b false');
   writeln('Integer97:  ', abs(as):1, ' s/b 14');

   (* signed integer constants *)
   writeln('Integer98:  ', 45 + (-30):1, ' s/b 15');
   writeln('Integer99:  ', -25 + 70:1, ' s/b 45');
   writeln('Integer100: ', -62 + 23:1, ' s/b -39');
   writeln('Integer101: ', -20 + (-15):1, ' s/b -35');
   writeln('Integer102: ', 20 - (-14):1, ' s/b 34');
   writeln('Integer103: ', -34 - 14:1, ' s/b -48');
   writeln('Integer104: ', -56 - (-12):1, ' s/b -44');
   writeln('Integer105: ', 5 * (-4):1, ' s/b -20');
   writeln('Integer106: ', (-18) * 7:1, ' s/b -126');
   writeln('Integer107: ', (-40) * (-13):1, ' s/b 520');
   writeln('Integer108: ', 30 div (-5):1, ' s/b -6');
   writeln('Integer109: ', (-50) div 2:1, ' s/b -25');
   writeln('Integer110: ', (-20) div (-4):1, ' s/b 5');
   writeln('Integer115: ', odd(-20):5, ' s/b false');
   writeln('Integer116: ', odd(-15):5, ' s/b true');
   writeln('Integer117: ', -5 = -5:5, ' s/b true');
   writeln('Integer118: ', -5 = 5:5, ' s/b false');
   writeln('Integer119: ', -21 <> -40:5, ' s/b true');
   writeln('Integer120: ', -21 <> -21:5, ' s/b false');
   writeln('Integer121: ', -3 < 5:5, ' s/b true');
   writeln('Integer122: ', -32 < -20:5, ' s/b true');
   writeln('Integer123: ', 20 < -20:5, ' s/b false');
   writeln('Integer124: ', -15 < -40:5, ' s/b false');
   writeln('Integer125: ', 70 > -4:5, ' s/b true');
   writeln('Integer126: ', -23 > -34:5, ' s/b true');
   writeln('Integer127: ', -5 > 5:5, ' s/b false');
   writeln('Integer128: ', -60 > -59:5, ' s/b false');
   writeln('Integer129: ', -12 <= 4:5, ' s/b true');
   writeln('Integer130: ', -14 <= -5:5, ' s/b true');
   writeln('Integer131: ', -7 <= -7:5, ' s/b true');
   writeln('Integer132: ', 5 <= -5:5, ' s/b false');
   writeln('Integer133: ', -10 <= -20:5, ' s/b false');
   writeln('Integer134: ', 9 >= -3:5, ' s/b true');
   writeln('Integer135: ', -4 >= -10:5, ' s/b true');
   writeln('Integer136: ', -13 >= -13:5, ' s/b true');
   writeln('Integer137: ', -6 >= 6:5, ' s/b false');
   writeln('Integer138: ', -20 >= -10:5, ' s/b false');
   writeln('Integer139: ', abs(-6):1, ' s/b 6');
   writeln('Integer140: ', tsncst:1, ' s/b -52');

(******************************************************************************

                         Characters

******************************************************************************)
 
   writeln;
   writeln('******************* Characters*******************');
   writeln;

   (* character variables *)
   ca := 'g'; cb := 'g'; cc := 'u';
   writeln('Character1:   ', ca, ' ', cb, ' ', cc, ' s/b g g u');
   writeln('Character2:   ', succ(ca), ' s/b h');
   writeln('Character3:   ', pred(cb), ' s/b f');
   writeln('Character4:   ', ord(ca):1, ' s/b 103');
   writeln('Character5:   ', chr(ord(cc)), ' s/b u');
   writeln('Character6:   ', ca = cb:5, ' s/b true');
   writeln('Character7:   ', ca = cc:5, ' s/b false');
   writeln('Character8:   ', ca < cc:5, ' s/b true');
   writeln('Character9:   ', cc < ca:5, ' s/b false');
   writeln('Character10:  ', cc > ca:5, ' s/b true');
   writeln('Character11:  ', ca > cc:5, ' s/b false');
   writeln('Character12:  ', ca <> cc:5, ' s/b true');
   writeln('Character13:  ', ca <> cb:5, ' s/b false');
   writeln('Character14:  ', ca <= cc:5, ' s/b true');
   writeln('Character15:  ', ca <= cb:5, ' s/b true');
   writeln('Character16:  ', cc <= ca:5, ' s/b false');
   writeln('Character17:  ', cc >= cb:5, ' s/b true');
   writeln('Character18:  ', cb >= ca:5, ' s/b true');
   writeln('Character19:  ', cb >= cc:5, ' s/b false');
   write('Character44:  ');
   for ca := 'a' to 'z' do write(ca);
   writeln(' s/b abcdefghijklmnopqrstuvwxyz');
   write('Character45:  ');
   for ca := 'z' downto 'a' do write(ca);
   writeln(' s/b zyxwvutsrqponmlkjihgfedcba');
   write('Character46:  ');
   x := 0;
   for ca := 'a' to 'z' do begin car[ca] := x; x := x + 1 end;
   for ca := 'z' downto 'a' do write(car[ca]:1, ' ');
   writeln;
   writeln('Character46: s/b 25 24 23 22 21 20 19 18 17 16 15',
      ' 14 13 12 11 10 9 8 7 6 5 4 3 2 1 0');
   r.rc := 'n'; writeln('Character47: ', r.rc, ' s/b n');
   writeln('Character50:  ');
   for ca := '0' to '9' do
   begin
     case ca of
       '5': write('five ');
       '3': write('three ');
       '6': write('six ');
       '8': write('eight ');
       '0': write('zero ');
       '9': write('nine ');
       '7': write('seven ');
       '4': write('four ');
       '1': write('one ');
       '2': write('two ');
     end
   end;
   writeln;
   writeln(' s/b zero one two three four five six ',
           'seven eight nine');

   (* character constants *)
   writeln('Character51:  ', 'a', ' s/b a');
   writeln('Character52:  ', succ('a'), ' s/b b');
   writeln('Character53:  ', pred('z'), ' s/b y');
   writeln('Character54:  ', ord('c'):1, ' s/b 99');
   writeln('Character55:  ', chr(ord('g')), ' s/b g');
   writeln('Character56:  ', 'q' = 'q':5, ' s/b true');
   writeln('Character57:  ', 'r' = 'q':5, ' s/b false');
   writeln('Character58:  ', 'b' < 't':5, ' s/b true');
   writeln('Character59:  ', 'g' < 'c':5, ' s/b false');
   writeln('Character50:  ', 'f' > 'e':5, ' s/b true');
   writeln('Character61:  ', 'f' > 'g':5, ' s/b false');
   writeln('Character62:  ', 'h' <> 'l':5, ' s/b true');
   writeln('Character63:  ', 'i' <> 'i':5, ' s/b false');
   writeln('Character64:  ', 'v' <= 'y':5, ' s/b true');
   writeln('Character65:  ', 'y' <= 'y':5, ' s/b true');
   writeln('Character66:  ', 'z' <= 'y':5, ' s/b false');
   writeln('Character67:  ', 'l' >= 'b':5, ' s/b true');
   writeln('Character68:  ', 'l' >= 'l':5, ' s/b true');
   writeln('Character69:  ', 'l' >= 'm':5, ' s/b false');
   writeln('Character85:  ', ccst, ' s/b v');

(******************************************************************************

                            Booleans

******************************************************************************)
 
   writeln;
   writeln('******************* Booleans *******************');
   writeln;

   (* boolean variables *)
   ba := true; bb := false; bc := true;
   writeln('Boolean1:   ', ba:5, ' ', bb:5, ' s/b true false');
   writeln('Boolean4:   ', ord(bb):1, ' s/b 0');
   writeln('Boolean5:   ', ord(ba):1, ' s/b 1');
   writeln('Boolean6:   ', ba = bc:5, ' s/b true');
   writeln('Boolean7:   ', bb = bb:5, ' s/b true');
   writeln('Boolean8:   ', ba = bb:5, ' s/b false');
   writeln('Boolean9:   ', bb < ba:5, ' s/b true');
   writeln('Boolean10:  ', ba < bb:5, ' s/b false');
   writeln('Boolean11:  ', ba > bb:5, ' s/b true');
   writeln('Boolean12:  ', bb > ba:5, ' s/b false');
   writeln('Boolean13:  ', ba <> bb:5, ' s/b true');
   writeln('Boolean14:  ', ba <> bc:5, ' s/b false');
   writeln('Boolean15:  ', bb <= ba:5, ' s/b true');
   writeln('Boolean16:  ', ba <= bc:5, ' s/b true');
   writeln('Boolean17:  ', ba <= bb:5, ' s/b false');
   writeln('Boolean18:  ', ba >= bb:5, ' s/b true');
   writeln('Boolean19:  ', bb >= bb:5, ' s/b true');
   writeln('Boolean20:  ', bb >= ba:5, ' s/b false');
   write('Boolean21:  ');
   for ba := false to true do write(ba:5, ' ');
   writeln('s/b false true');
   write('Boolean22:  ');
   for bb := true downto false do write(bb:5, ' ');
   writeln('s/b true false');
   write('Boolean23:  ');
   ba := 1 > 0; writeln(ba:5, ' s/b true');
   write('Boolean24:  ');
   ba := 1 < 0; writeln(ba:5, ' s/b false');
 
   (* boolean constants *)
   writeln('Boolean25:  ', true:5, ' ', false:5, ' s/b true false');
   writeln('Boolean28:  ', ord(false):1, ' s/b 0');
   writeln('Boolean29:  ', ord(true):1, ' s/b 1');
   writeln('Boolean30:  ', true = true:5, ' s/b true');
   writeln('Boolean31:  ', false = false:5, ' s/b true');
   writeln('Boolean32:  ', true = false:5, ' s/b false');
   writeln('Boolean33:  ', false < true:5, ' s/b true');
   writeln('Boolean34:  ', true < false:5, ' s/b false');
   writeln('Boolean35:  ', true > false:5, ' s/b true');
   writeln('Boolean36:  ', false > true:5, ' s/b false');
   writeln('Boolean37:  ', true <> false:5, ' s/b true');
   writeln('Boolean38:  ', true <> true:5, ' s/b false');
   writeln('Boolean39:  ', false <= true:5, ' s/b true');
   writeln('Boolean40:  ', true <= true:5, ' s/b true');
   writeln('Boolean41:  ', true <= false:5, ' s/b false');
   writeln('Boolean42:  ', true >= false:5, ' s/b true');
   writeln('Boolean43:  ', false >= false:5, ' s/b true');
   writeln('Boolean44:  ', false >= true:5, ' s/b false');
   writeln('Boolean45:');
   for i := 10 downto 1 do writeln(false:i);
   writeln('Boolean46: s/b:');
   writeln('     false');
   writeln('    false');
   writeln('   false');
   writeln('  false');
   writeln(' false');
   writeln('false');
   writeln('fals');
   writeln('fal');
   writeln('fa');
   writeln('f');
   writeln('Boolean47:');
   for i := 10 downto 1 do writeln(true:i);
   writeln('Boolean48: s/b:');
   writeln('      true');
   writeln('     true');
   writeln('    true');
   writeln('   true');
   writeln('  true');
   writeln(' true');
   writeln('true');
   writeln('tru');
   writeln('tr');
   writeln('t');

(******************************************************************************

                            Reals

******************************************************************************)

   writeln;
   writeln('******************* Reals ******************************');
   writeln;

   (* formats, input (compiler) and output *)
   writeln('Real1:   ', 1.554:15, ' s/b  1.554000e+00');
   writeln('Real2:   ', 0.00334:15, ' s/b  3.340000e-03');
   writeln('Real3:   ', 0.00334e-21:15, ' s/b  3.34000e-24');
   writeln('Real4:   ', 4e-45:15, ' s/b  4.000000e-45');
   writeln('Real5:   ', -5.565:15, ' s/b -5.565000e+03');
   writeln('Real6:   ', -0.00944:15, ' s/b -9.440000e-03');
   writeln('Real7:   ', -0.006364e+32:15, ' s/b -6.364000e+29');
   writeln('Real8:   ', -2e-14:15, ' s/b -2.000000e-14');
   writeln('Real9:');
   writeln('         11111111112222222222333333333344444444445');
   writeln('12345678901234567890123456789012345678901234567890');
   for i := 1 to 20 do writeln(1.23456789012345678901234567890:i);
   writeln('s/b (note precision dropoff at right):');
   writeln(' 1.2e+000');
   writeln(' 1.2e+000');
   writeln(' 1.2e+000');
   writeln(' 1.2e+000');
   writeln(' 1.2e+000');
   writeln(' 1.2e+000');
   writeln(' 1.2e+000');
   writeln(' 1.2e+000');
   writeln(' 1.2e+000');
   writeln(' 1.23e+000');
   writeln(' 1.234e+000');
   writeln(' 1.2345e+000');
   writeln(' 1.23456e+000');
   writeln(' 1.234567e+000');
   writeln(' 1.2345678e+000');
   writeln(' 1.23456789e+000');
   writeln(' 1.234567890e+000');
   writeln(' 1.2345678901e+000');
   writeln(' 1.23456789012e+000');
   writeln(' 1.234567890123e+000');
   writeln('Real10:');
   writeln('         11111111112222222222333333333344444444445');
   writeln('12345678901234567890123456789012345678901234567890');
   for i := 1 to 20 do writeln(i+0.23456789012345678901234567890:1:i);
   writeln('s/b (note precision dropoff at right):');
   writeln('1.2');
   writeln('2.23');
   writeln('3.234');
   writeln('4.2345');
   writeln('5.23456');
   writeln('6.234567');
   writeln('7.2345678');
   writeln('8.23456789');
   writeln('9.234567890');
   writeln('10.2345678901');
   writeln('11.23456789012');
   writeln('12.234567890123');
   writeln('13.2345678901234');
   writeln('14.23456789012345');
   writeln('15.234567890123456');
   writeln('16.2345678901234567');
   writeln('17.23456789012345678');
   writeln('18.234567890123456789');
   writeln('19.2345678901234567890');
   writeln('20.23456789012345678901');

   (* unsigned variables *)
   ra := 435.23; 
   rb := 983.67; 
   rc := rb;
   rd := 0.3443;
   writeln('Real11:  ', ra + rb:15, ' s/b  1.418900e+03');
   writeln('Rea112:  ', rb - ra:15, ' s/b  5.484399e+02');
   writeln('Real13:  ', ra * rb:15, ' s/b  4.281227e+05');
   writeln('Real14:  ', rb / ra:15, ' s/b  2.260115e+00');
   writeln('Real15:  ', rc = rb:5, ' s/b true');
   writeln('Real16:  ', ra = rb:5, ' s/b false');
   writeln('Real17:  ', ra < rb:5, ' s/b true');
   writeln('Real18:  ', rb < ra:5, ' s/b false');
   writeln('Real19:  ', rb > ra:5, ' s/b true');
   writeln('Real20:  ', ra > rb:5, ' s/b false');
   writeln('Real21:  ', ra <> rb:5, ' s/b true');
   writeln('Real22:  ', rb <> rc:5, ' s/b false');
   writeln('Real23:  ', ra <= rb:5, ' s/b true');
   writeln('Real24:  ', rc <= rb:5, ' s/b true');
   writeln('Real25:  ', rb <= ra:5, ' s/b false');
   writeln('Real26:  ', rb >= ra:5, ' s/b true');
   writeln('Real27:  ', rb >= rc:5, ' s/b true');
   writeln('Real28:  ', ra >= rb:5, ' s/b false');
   writeln('Real29:  ', abs(ra):15, ' s/b  4.35230e+02');
   writeln('Real30:  ', sqr(ra):15, ' s/b  1.89425e+05');
   writeln('Real31:  ', sqrt(rb):15, ' s/b  3.13635e+01');
   writeln('Real32:  ', sin(rb):15, ' s/b -3.44290e-01');
   writeln('Real33:  ', arctan(ra):15, ' s/b  1.56850e+00');
   writeln('Real34:  ', exp(rd):15, ' s/b  1.41100e+00');
   writeln('Real35:  ', ln(ra):15, ' s/b  6.07587e+00');
   writeln('Real36:  ', trunc(ra):1, ' s/b 435');
   writeln('Real37:  ', round(rb):1, ' s/b 984');
   writeln('Real38:  ', round(ra):1, ' s/b 435');

   (* unsigned constants *)
   writeln('Real39:  ', 344.939 + 933.113:15, ' s/b  1.278052e+03');
   writeln('Real40:  ', 883.885 - 644.939:15, ' s/b  2.389460e+02');
   writeln('Real41:  ', 754.74 * 138.75:15, ' s/b  1.047202e+05');
   writeln('Real42:  ', 634.3 / 87373.99:15, ' s/b  7.259598e-03');
   writeln('Real43:  ', 77.44 = 77.44:5, ' s/b true');
   writeln('Real44:  ', 733.9 = 959.2:5, ' s/b false');
   writeln('Real45:  ', 883.22 < 8383.33:5, ' s/b true');
   writeln('Real46:  ', 475.322 < 234.93:5, ' s/b false');
   writeln('Real47:  ', 7374.3 > 6442.34:5, ' s/b true');
   writeln('Real48:  ', 985.562 > 1001.95:5, ' s/b false');
   writeln('Real49:  ', 030.11 <> 0938.44:5, ' s/b true');
   writeln('Real50:  ', 1.233 <> 1.233:5, ' s/b false');
   writeln('Real51:  ', 8484.002 <= 9344.003:5, ' s/b true');
   writeln('Real52:  ', 9.11 <= 9.11:5, ' s/b true');
   writeln('Real53:  ', 93.323 <= 90.323:5, ' s/b false');
   writeln('Real54:  ', 6543.44 >= 5883.33:5, ' s/b true');
   writeln('Real55:  ', 3247.03 >= 3247.03:5, ' s/b true');
   writeln('Real56:  ', 28343.22 >= 30044.45:5, ' s/b false');
   writeln('Real57:  ', abs(34.93):15, ' s/b  3.493000e+01');
   writeln('Real58:  ', sqr(2.34):15, ' s/b  5.475600e+00');
   writeln('Real59:  ', sqrt(9454.32):15, ' s/b  9.723333e+01');
   writeln('Real60:  ', sin(34.22):15, ' s/b  3.311461e-01');
   writeln('Real61:  ', arctan(343.2):15, ' s/b  1.567883e+00');
   writeln('Real62:  ', exp(0.332):15, ' s/b  1.393753e+00');
   writeln('Real63:  ', ln(83.22):15, ' s/b  4.421488e+00');
   writeln('Real64:  ', trunc(24.344):1, ' s/b 24');
   writeln('Real65:  ', round(74.56):1, ' s/b 75');
   writeln('Real66:  ', round(83.24):1, ' s/b 83');
   writeln('Real67:  ', rcnst:15, ' s/b  4.333000e+01');

   (* signed variables *)
   ra := -734.2;
   rb := -7634.52;
   rc := ra;
   rd := 1034.54;
   re := -0.38483;
   writeln('Real68:  ', ra + rd:15, ' s/b  3.003400e+02');
   writeln('Real69:  ', rd + ra:15, ' s/b  3.003400e+02');
   writeln('Real70:  ', rb + rd:15, ' s/b -6.599980e+03');
   writeln('Real71:  ', ra + rb:15, ' s/b -8.368720e+03');
   writeln('Real72:  ', rd - ra:15, ' s/b  1.768740e+03');
   writeln('Real73:  ', rb - rd:15, ' s/b -8.669061e+03');
   writeln('Real74:  ', rb - ra:15, ' s/b -6.900320e+03');
   writeln('Real75:  ', rd * ra:15, ' s/b -7.595593e+05');
   writeln('Real76:  ', ra * rd:15, ' s/b -7.595593e+05');
   writeln('Real77:  ', ra * rb:15, ' s/b  5.605265e+06');
   writeln('Real78:  ', rd / ra:15, ' s/b -1.409071e+00');
   writeln('Real79:  ', rb / rd:15, ' s/b -7.379627e+00');
   writeln('Real80:  ', rb / ra:15, ' s/b  1.039842e+01');
   writeln('Real81:  ', ra = rc:5, ' s/b true');
   writeln('Real82:  ', ra = rb:5, ' s/b false');
   writeln('Real83:  ', ra <> rb:5, ' s/b true');
   writeln('Real84:  ', ra <> rc:5, ' s/b false');
   writeln('Real85:  ', ra < rd:5, ' s/b true');
   writeln('Real86:  ', rb < ra:5, ' s/b true');
   writeln('Real87:  ', rd < ra:5, ' s/b false');
   writeln('Real88:  ', ra < rb:5, ' s/b false');
   writeln('Real89:  ', rd > ra:5, ' s/b true');
   writeln('Real90:  ', ra > rb:5, ' s/b true');
   writeln('Real91:  ', ra > rd:5, ' s/b false');
   writeln('Real92:  ', rb > ra:5, ' s/b false');
   writeln('Real93:  ', ra <= rd:5, ' s/b true');
   writeln('Real94:  ', rb <= ra:5, ' s/b true');
   writeln('Real95:  ', ra <= rc:5, ' s/b true');
   writeln('Real96:  ', rd <= ra:5, ' s/b false');
   writeln('Real97:  ', ra <= rb:5, ' s/b false');
   writeln('Real98:  ', rd >= ra:5, ' s/b true');
   writeln('Real99:  ', ra >= rb:5, ' s/b true');
   writeln('Real100: ', ra >= rc:5, ' s/b true');
   writeln('Real101: ', ra >= rd:5, ' s/b false');
   writeln('Real102: ', rb >= ra:5, ' s/b false');
   writeln('Real103: ', abs(ra):15, ' s/b  7.34200e+02');
   writeln('Real104: ', sqr(ra):15, ' s/b  5.39050e+05');
   writeln('Real105: ', sin(rb):15, ' s/b -4.34850e-01');
   writeln('Real106: ', arctan(ra):15, ' s/b -1.56943e+00');
   writeln('Real107: ', exp(re):15, ' s/b  6.80566e-01');
   writeln('Real108: ', trunc(ra):15, ' s/b -734');
   writeln('Real109: ', round(rb):15, ' s/b -7635');
   writeln('Real110: ', round(ra):15, ' s/b -734');

   (* signed constants *)
   writeln('Real111: ', 45.934 + (-30.834):15, ' s/b  1.510000e+01');
   writeln('Real112: ', -25.737 + 70.87:15, ' s/b  4.513300e+01');
   writeln('Real113: ', -62.63 + 23.99:15, ' s/b -3.864000e+01');
   writeln('Real114: ', -20.733 + (-15.848):15, ' s/b -3.658100e+01');
   writeln('Real115: ', 20.774 - (-14.774):15, ' s/b  3.554800e+01');
   writeln('Real116: ', -34.523 - 14.8754:15, ' s/b -4.939840e+01');
   writeln('Real117: ', -56.664 - (-12.663):15, ' s/b -4.400100e+01');
   writeln('Real118: ', 5.663 * (-4.664):15, ' s/b -2.641223e+01');
   writeln('Real119: ', (-18.62) * 7.997:15, ' s/b -1.489041e+02');
   writeln('Real120: ', (-40.552) * (-13.774):15, ' s/b  5.585632e+02');
   writeln('Real121: ', 30.6632 / (-5.874):15, ' s/b -5.220157e+00');
   writeln('Real122: ', (-50.636) / 2.8573:15, ' s/b -1.772163e+01');
   writeln('Real123: ', (-20.7631) / (-4.85734):15, ' s/b  4.274582e+00');
   writeln('Real124: ', -5.775 = -5.775:5, ' s/b true');
   writeln('Real125: ', -5.6364 = 5.8575:5, ' s/b false');
   writeln('Real126: ', -21.6385 <> -40.764:5, ' s/b true');
   writeln('Real127: ', -21.772 <> -21.772:5, ' s/b false');
   writeln('Real128: ', -3.512 < 5.8467:5, ' s/b true');
   writeln('Real129: ', -32.644 < -20.9074:5, ' s/b true');
   writeln('Real130: ', 20.763 < -20.743:5, ' s/b false');
   writeln('Real131: ', -15.663 < -40.784:5, ' s/b false');
   writeln('Real132: ', 70.766 > -4.974:5, ' s/b true');
   writeln('Real133: ', -23.6532 > -34.774:5, ' s/b true');
   writeln('Real134: ', -5.773 > 5.9874:5, ' s/b false');
   writeln('Real135: ', -60.663 > -59.78:5, ' s/b false');
   writeln('Real136: ', -12.542 <= 4.0848:5, ' s/b true');
   writeln('Real137: ', -14.8763 <= -5.0847:5, ' s/b true');
   writeln('Real138: ', -7.8373 <= -7.8373:5, ' s/b true');
   writeln('Real139: ', 5.4564 <= -5.4564:5, ' s/b false');
   writeln('Real140: ', -10.72633 <= -20.984:5, ' s/b false');
   writeln('Real141: ', 9.834 >= -3.9383:5, ' s/b true');
   writeln('Real142: ', -4.562 >= -10.74:5, ' s/b true');
   writeln('Real143: ', -13.63 >= -13.63:5, ' s/b true');
   writeln('Real144: ', -6.74 >= 6.74:5, ' s/b false');
   writeln('Real145: ', -20.7623 >= -10.574:5, ' s/b false');
   writeln('Real146: ', abs(-6.823):15, ' s/b  6.823000e+00');
   writeln('Real147  ', sqr(-348.22):15, ' s/b  1.212572e+05');
   writeln('Real148: ', sin(-733.22):15, ' s/b  9.421146e-01');
   writeln('Real149: ', arctan(-8387.22):15, ' s/b -1.570677e+00');
   writeln('Real150: ', exp(-0.8743):15, ' s/b  4.171539e-01');
   writeln('Real151: ', trunc(-33.422):1, ' s/b -33');
   writeln('Real152: ', round(-843.22):1, ' s/b -843');
   writeln('Real153: ', round(-6243.76):1, ' s/b -6244');
   writeln('Real154: ', rscst:15, ' s/b -8.422000e+01');

(******************************************************************************

                            Arrays

******************************************************************************)

   writeln;
   writeln('******************* arrays ******************************');
   writeln;
  
   (* single demension, integer index *)
   write('Array1:   ');
   for i := 1 to 10 do avi[i] := i+10;
   for i := 10 downto 1 do write(avi[i]:1, ' ');
   writeln(' s/b 20 19 18 17 16 15 14 13 12 11');
   write('Array5:   ');
   for i := 1 to 10 do avb[i] := odd(i);
   for i := 10 downto 1 do write(avb[i]:5, ' ');
   writeln;
   writeln('    s/b:   false  true false  true false  true false  true false',
           '  true');
   write('Array7:   ');
   for i := 1 to 10 do avr[i] := i+10+0.12;
   for i := 10 downto 1 do write(avr[i]:1:2, ' ');
   writeln;
   writeln('    s/b:   20.12 19.12 18.12 17.12 16.12 15.12 14.12 ',
           '13.12 12.12 11.12');
   write('Array9:   ');
   for i := 1 to 10 do avc[i] := chr(i+ord('a'));
   for i := 10 downto 1 do write(avc[i]:1, ' ');
   writeln('s/b k j i h g f e d c b');
   write('Array19:  ');
   for i := 1 to 10 do 
      begin avrc[i].a := i+10; avrc[i].b := chr(i+ord('a')) end;
   for i := 10 downto 1 do write(avrc[i].a:1, ' ', avrc[i].b, ' ');
   writeln;
   writeln('     s/b:  20 k 19 j 18 i 17 h 16 g 15 f 14 e 13 d 12 c 11 b');
   write('Array20:  ');

   (* multidementional arrays *)
   writeln('Array35:');
   z := 0;
   for x := 1 to 10 do
      for y := 1 to 10 do begin da[y, x] := z; z := z + 1 end;
   for x := 1 to 10 do
   begin
      for y := 1 to 10 do write(da[x][y]:2, ' ');
      writeln;
   end;
   writeln('s/b');
   writeln('0 10 20 30 40 50 60 70 80 90');
   writeln('1 11 21 31 41 51 61 71 81 91'); 
   writeln('2 12 22 32 42 52 62 72 82 92'); 
   writeln('3 13 23 33 43 53 63 73 83 93'); 
   writeln('4 14 24 34 44 54 64 74 84 94'); 
   writeln('5 15 25 35 45 55 65 75 85 95'); 
   writeln('6 16 26 36 46 56 66 76 86 96'); 
   writeln('7 17 27 37 47 57 67 77 87 97'); 
   writeln('8 18 28 38 48 58 68 78 88 98'); 
   writeln('9 19 29 39 49 59 69 79 89 99'); 
   writeln('Array36: ');
   t := 0;
   for i := 1 to 2 do
      for x := 1 to 2 do
         for y := 1 to 2 do
            for z := 1 to 2 do
               for q := 1 to 2 do
                  for n := 1 to 2 do 
                     begin mdar[i][x, y, z][q][n] := t; t := t+1 end;
   for i := 2 downto 1 do
      for x := 2 downto 1 do
         for y := 2 downto 1 do begin

            for z := 2 downto 1 do
               for q := 2 downto 1 do
                  for n := 2 downto 1 do write(mdar[i, x][y, z][q][n]:2, ' ');
            writeln;

         end;
   writeln('s/b:');
   writeln('63 62 61 60 59 58 57 56');
   writeln('55 54 53 52 51 50 49 48');
   writeln('47 46 45 44 43 42 41 40');
   writeln('39 38 37 36 35 34 33 32');
   writeln('31 30 29 28 27 26 25 24');
   writeln('23 22 21 20 19 18 17 16');
   writeln('15 14 13 12 11 10  9  8');
   writeln(' 7  6  5  4  3  2  1  0');

   (* assignments *)
   writeln('Array38: ');
   for i := 1 to 10 do avi[i] := i+10;
   avi2 := avi;
   for i := 10 downto 1 do write(avi2[i]:1, ' ');
   writeln('s/b 20 19 18 17 16 15 14 13 12 11');
   writeln('Array39: ');
   t := 0;
   for i := 1 to 2 do
      for x := 1 to 2 do
         for y := 1 to 2 do
            for z := 1 to 2 do
               for q := 1 to 2 do
                  for n := 1 to 2 do 
                     begin mdar[i][x, y, z][q][n] := t; t := t+1 end;
   mdar2 := mdar;
   for i := 2 downto 1 do
      for x := 2 downto 1 do
         for y := 2 downto 1 do begin

            for z := 2 downto 1 do
               for q := 2 downto 1 do
                  for n := 2 downto 1 do write(mdar2[i, x][y, z][q][n]:2, ' ');
            writeln;

         end;
   writeln('s/b:');
   writeln('63 62 61 60 59 58 57 56');
   writeln('55 54 53 52 51 50 49 48');
   writeln('47 46 45 44 43 42 41 40');
   writeln('39 38 37 36 35 34 33 32');
   writeln('31 30 29 28 27 26 25 24');
   writeln('23 22 21 20 19 18 17 16');
   writeln('15 14 13 12 11 10  9  8');
   writeln(' 7  6  5  4  3  2  1  0');

(******************************************************************************

                            Records

******************************************************************************)

   writeln;
   writeln('******************* records ******************************');
   writeln;

   (* types in records *)
   writeln('Record1:   ');
   arec.i := 64;
   arec.b := false;
   arec.c := 'j';
   arec.r := 4545.12e-32;
   for i := 1 to 10 do arec.a[i] := i+20;
   arec.rc.a := 2324;
   arec.rc.b := 'y';
   writeln(arec.i:1, ' ', arec.b:5, ' ', arec.c:1, ' ',
           ' ', arec.r:15);
   for i := 1 to 10 do write(arec.a[i]:1, ' '); writeln;
   writeln(arec.rc.a:1, ' ', arec.rc.b:1);
   writeln('s/b:');
   writeln('64 false j 4.54512000e-29'); 
   writeln('21 22 23 24 25 26 27 28 29 30');
   writeln('2324 y');

   (* nested records *)
   write('Record23:  ');
   nvr.i := 1;
   nvr.r.i := 2;
   nvr.r.r.i := 3;
   nvr.r.r.r.i := 4;
   nvr.r.r.r.r.i := 5;
   nvr.r.r.r.r.r.i := 6;
   nvr.r.r.r.r.r.r.i := 7;
   nvr.r.r.r.r.r.r.r.i := 8;
   nvr.r.r.r.r.r.r.r.r.i := 9;
   nvr.r.r.r.r.r.r.r.r.r.i := 10;
   writeln(nvr.i:1, ' ', 
           nvr.r.i:1, ' ', 
           nvr.r.r.i:1, ' ',
           nvr.r.r.r.i:1, ' ', 
           nvr.r.r.r.r.i:1, ' ',
           nvr.r.r.r.r.r.i:1, ' ', 
           nvr.r.r.r.r.r.r.i:1, ' ',
           nvr.r.r.r.r.r.r.r.i:1, ' ',
           nvr.r.r.r.r.r.r.r.r.i:1, ' ',
           nvr.r.r.r.r.r.r.r.r.r.i:1, ' ',
           's/b 1 2 3 4 5 6 7 8 9 10');

(******************************************************************************

                         Procedures and functions

******************************************************************************)
 
   writeln;
   writeln('************ Procedures and functions ******************');
   writeln;
   write('ProcedureFunction1:   ');
   x := 45; y := 89;
   junk1(x, y);
   writeln(' s/b 45 89');
   write('ProcedureFunction2:   ');
   x := 45; junk2(x);
   writeln(x:1, ' s/b 46');
   write('ProcedureFunction5:   ');
   writeln(junk5(34):1, ' s/b 35');
   write('ProcedureFunction6:   ');
   i := junk7(10, 9, 8);
   writeln(' ', i:1);
   writeln('s/b:   10 9 8 6 5 4 3 2 1 78');
   writeln('ProcedureFunction7:');
   for i := 1 to 10 do ai[i] := i+10;
   arec.i := 64;
   arec.b := false;
   arec.c := 'j';
   arec.r := 4545.12e-32;
   for i := 1 to 10 do arec.a[i] := i+20;
   arec.rc.a := 2324;
   arec.rc.b := 'y';
   junk8(93, true, 'k', 3.1414, ai, arec); 
   writeln('s/b:');
   writeln('93  true k 3.14140000e+00');
   writeln('11 12 13 14 15 16 17 18 19 20');
   writeln('64 false j 4.54500000e-29'); 
   writeln('21 22 23 24 25 26 27 28 29 30');
   writeln('2324 y');
   write('ProcedureFunction10:   ');
   junk14;
   writeln(' s/b 62 76');

(******************************************************************************

                                 Metering

******************************************************************************)

   writeln;
   writeln('The following are implementation defined characteristics');
   writeln;
   writeln('Integer default output field');
   writeln('         1111111111222222222233333333334');
   writeln('1234567890123456789012345678901234567890');
   writeln(1);
   writeln('Real default output field');
   writeln('         1111111111222222222233333333334');
   writeln('1234567890123456789012345678901234567890');
   writeln(1.2);
   writeln('Boolean default output field');
   writeln('         1111111111222222222233333333334');
   writeln('1234567890123456789012345678901234567890');
   writeln(false);
   writeln(true);
   writeln('Char default output field');
   writeln('         1111111111222222222233333333334');
   writeln('1234567890123456789012345678901234567890');
   writeln('a');
   if (ord('a') = 97) and (ord('(') = 40) and (ord('^') = 94) then
      writeln('Appears to be ASCII')
   else
      writeln('Appears to not be ASCII')

end.