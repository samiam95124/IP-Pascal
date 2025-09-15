{*******************************************************************************
*                                                                              *
*              ASSEMBLY LANGUAGE CHARACTER TRANSLATION ARRAY PROGRAM           *
*                                                                              *
*                        Copyright (C) 2005 Scott A. Moore                     *
*                                                                              *
* This program generates two assembly language tables, one to translate from   *
* ASCII characters to encoded values, and one to translate from encoded values *
* to ASCII characters. This information gets included in the Windows macro     *
* file, and is used to adapt encoded programs to Windows.                      *
*                                                                              *
* This program should match xltlib, which it was derived from.                 *
*                                                                              *
*******************************************************************************}

program test(output);

uses strlib;

const bytesperline = 16; { number of bytes to present on assembly line }
      outnam       = 'xlttbls.asm'; { name of result file }

var nrmtbl: packed array [byte] of char; { encoded to normal table }
    xlttbl: packed array [byte] of char; { normal to encoded table }
    ci:     byte;                        { index for transliteration array }
    outfil: text;                        { file to create }

begin

   writeln('Character translation table construction program vs. 0.1');
   { initalize encoded to normal translation array }
   for ci := 0 to 255 do nrmtbl[ci] := chr(ci);
   nrmtbl[ord('|')] := '!'; nrmtbl[ord('x')] := '"'; nrmtbl[ord('b')] := '#';
   nrmtbl[ord('}')] := '$'; nrmtbl[ord('X')] := '%'; nrmtbl[ord('v')] := '&';
   nrmtbl[ord('e')] := ''''; nrmtbl[ord('V')] := '('; nrmtbl[ord('`')] := ')';
   nrmtbl[ord('Y')] := '*'; nrmtbl[ord('_')] := '+'; nrmtbl[ord('y')] := ',';
   nrmtbl[ord('f')] := '-'; nrmtbl[ord('z')] := '.'; nrmtbl[ord('!')] := '/';
   nrmtbl[ord('j')] := '0'; nrmtbl[ord('k')] := '1'; nrmtbl[ord('l')] := '2';
   nrmtbl[ord('m')] := '3'; nrmtbl[ord('n')] := '4'; nrmtbl[ord('o')] := '5';
   nrmtbl[ord('p')] := '6'; nrmtbl[ord('q')] := '7'; nrmtbl[ord('r')] := '8';
   nrmtbl[ord('s')] := '9'; nrmtbl[ord('d')] := ':'; nrmtbl[ord('{')] := ';';
   nrmtbl[ord('W')] := '<'; nrmtbl[ord('\\')] := '='; nrmtbl[ord('g')] := '>';
   nrmtbl[ord('Z')] := '?'; nrmtbl[ord('a')] := '@'; nrmtbl[ord('"')] := 'A';
   nrmtbl[ord('#')] := 'B'; nrmtbl[ord('$')] := 'C'; nrmtbl[ord('%')] := 'D';
   nrmtbl[ord('&')] := 'E'; nrmtbl[ord('''')] := 'F'; nrmtbl[ord('(')] := 'G';
   nrmtbl[ord(')')] := 'H'; nrmtbl[ord('*')] := 'I'; nrmtbl[ord('+')] := 'J';
   nrmtbl[ord(',')] := 'K'; nrmtbl[ord('-')] := 'L'; nrmtbl[ord('.')] := 'M';
   nrmtbl[ord('/')] := 'N'; nrmtbl[ord('0')] := 'O'; nrmtbl[ord('1')] := 'P';
   nrmtbl[ord('2')] := 'Q'; nrmtbl[ord('3')] := 'R'; nrmtbl[ord('4')] := 'S';
   nrmtbl[ord('5')] := 'T'; nrmtbl[ord('6')] := 'U'; nrmtbl[ord('7')] := 'V';
   nrmtbl[ord('8')] := 'W'; nrmtbl[ord('9')] := 'X'; nrmtbl[ord(':')] := 'Y';
   nrmtbl[ord(';')] := 'Z'; nrmtbl[ord('w')] := '['; nrmtbl[ord('i')] := '\\';
   nrmtbl[ord('h')] := ']'; nrmtbl[ord('[')] := '^'; nrmtbl[ord('t')] := '_';
   nrmtbl[ord('~')] := '`'; nrmtbl[ord('<')] := 'a'; nrmtbl[ord('=')] := 'b';
   nrmtbl[ord('>')] := 'c'; nrmtbl[ord('?')] := 'd'; nrmtbl[ord('@')] := 'e';
   nrmtbl[ord('A')] := 'f'; nrmtbl[ord('B')] := 'g'; nrmtbl[ord('C')] := 'h';
   nrmtbl[ord('D')] := 'i'; nrmtbl[ord('E')] := 'j'; nrmtbl[ord('F')] := 'k';
   nrmtbl[ord('G')] := 'l'; nrmtbl[ord('H')] := 'm'; nrmtbl[ord('I')] := 'n';
   nrmtbl[ord('J')] := 'o'; nrmtbl[ord('K')] := 'p'; nrmtbl[ord('L')] := 'q';
   nrmtbl[ord('M')] := 'r'; nrmtbl[ord('N')] := 's'; nrmtbl[ord('O')] := 't';
   nrmtbl[ord('P')] := 'u'; nrmtbl[ord('Q')] := 'v'; nrmtbl[ord('R')] := 'w';
   nrmtbl[ord('S')] := 'x'; nrmtbl[ord('T')] := 'y'; nrmtbl[ord('U')] := 'z';
   nrmtbl[ord('u')] := '{'; nrmtbl[ord('^')] := '|'; nrmtbl[ord('c')] := '}';
   nrmtbl[ord(']')] := '~';
   { use that to form the normal to encoded array } 
   for ci := 0 to 255 do xlttbl[ord(nrmtbl[ci])] := chr(ci);
   { open output file }
   assign(outfil, outnam);
   rewrite(outfil);
   { output ascii to encoded array }
   writeln(outfil, '!');
   writeln(outfil, '! ASCII to encoded character translation array');
   writeln(outfil, '!');
   writeln(outfil, 'nrmtbl:');
   for ci := 0 to 255 do begin

      if ci mod bytesperline = 0 then write(outfil, '        defb    ')
      else write(outfil, ',');
      write(outfil, '$'); 
      writeh(outfil, ord(nrmtbl[ci]), '00');
      if (ci+1) mod bytesperline = 0 then writeln(outfil)

   end;
   { output encoded to ascii array }
   writeln(outfil, '!');
   writeln(outfil, '! Encoded to ASCII character translation array');
   writeln(outfil, '!');
   writeln(outfil, 'xlttbl:');
   for ci := 0 to 255 do begin

      if ci mod bytesperline = 0 then write(outfil, '        defb    ')
      else write(outfil, ',');
      write(outfil, '$'); 
      writeh(outfil, ord(xlttbl[ci]), '00');
      if (ci+1) mod bytesperline = 0 then writeln(outfil)

   end;
   close(outfil); { close output file }
   writeln;
   writeln('Convertion tables were placed in the file ''', outnam:0, '''');
   writeln;
   writeln('Function complete')

end.