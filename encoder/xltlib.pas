{*******************************************************************************
*                                                                              *
*                   CHARACTER TRANSLITERATION LIBRARY                          *
*                                                                              *
*                          2005/4 S. A. Moore                                  *
*                                                                              *
* The transliteration library backs up the #charactertransliterate mode of the *
* encoder. This option causes the encoder to use an external table to encode   *
* all multicharacter string constants in the object binary. Included here are  *
* functions to translate single characters and strings to and from the encoded *
* mode.                                                                        *
*                                                                              *
*******************************************************************************}

module xltlib;

uses stddef; { standard definitions }

function nrmchr(c: char): char; forward;
overload procedure nrmchr(var s: string); forward;
function xltchr(c: char): char; forward;
overload procedure xltchr(var s: string); forward;

private

var nrmtbl: packed array [byte] of char; { encoded to normal table }
    xlttbl: packed array [byte] of char; { normal to encoded table }
    ci:     byte;                        { index for transliteration array }

function nrmchr(c: char): char;

begin

    nrmchr := nrmtbl[ord(c)]

end;

overload procedure nrmchr(var s: string);

var i: integer;

begin

   for i := 1 to max(s) do s[i] := nrmchr(s[i])

end;

function xltchr(c: char): char;

begin

    xltchr := xlttbl[ord(c)]

end;

overload procedure xltchr(var s: string);

var i: integer;

begin

   for i := 1 to max(s) do s[i] := xltchr(s[i])

end;

begin

   { initalize encoded to normal translation array }
   for ci := 0 to 255 do nrmtbl[ci] := chr(ci);
   nrmtbl[ord('P')] := '!'; nrmtbl[ord('x')] := '"'; nrmtbl[ord('b')] := '#';
   nrmtbl[ord('C')] := '$'; nrmtbl[ord('q')] := '%'; nrmtbl[ord('H')] := '&';
   nrmtbl[ord('e')] := ''''; nrmtbl[ord('V')] := '('; nrmtbl[ord('`')] := ')';
   nrmtbl[ord('Y')] := '*'; nrmtbl[ord('U')] := '+'; nrmtbl[ord('y')] := ',';
   nrmtbl[ord('f')] := '-'; nrmtbl[ord('z')] := '.'; nrmtbl[ord('B')] := '/';
   nrmtbl[ord('j')] := '0'; nrmtbl[ord('=')] := '1'; nrmtbl[ord('M')] := '2';
   nrmtbl[ord(',')] := '3'; nrmtbl[ord('g')] := '4'; nrmtbl[ord('R')] := '5';
   nrmtbl[ord('{')] := '6'; nrmtbl[ord('X')] := '7'; nrmtbl[ord('@')] := '8';
   nrmtbl[ord('r')] := '9'; nrmtbl[ord('O')] := ':'; nrmtbl[ord('p')] := ';';
   nrmtbl[ord('L')] := '<'; nrmtbl[ord('\\')] := '='; nrmtbl[ord('S')] := '>';
   nrmtbl[ord('D')] := '?'; nrmtbl[ord('a')] := '@'; nrmtbl[ord('"')] := 'A';
   nrmtbl[ord('>')] := 'B'; nrmtbl[ord('w')] := 'C'; nrmtbl[ord('}')] := 'D';
   nrmtbl[ord('v')] := 'E'; nrmtbl[ord('t')] := 'F'; nrmtbl[ord('<')] := 'G';
   nrmtbl[ord('#')] := 'H'; nrmtbl[ord('s')] := 'I'; nrmtbl[ord('m')] := 'J';
   nrmtbl[ord('!')] := 'K'; nrmtbl[ord('7')] := 'L'; nrmtbl[ord('-')] := 'M';
   nrmtbl[ord('1')] := 'N'; nrmtbl[ord('o')] := 'O'; nrmtbl[ord('|')] := 'P';
   nrmtbl[ord('G')] := 'Q'; nrmtbl[ord('''')] := 'R'; nrmtbl[ord('d')] := 'S';
   nrmtbl[ord('5')] := 'T'; nrmtbl[ord(')')] := 'U'; nrmtbl[ord('c')] := 'V';
   nrmtbl[ord(':')] := 'W'; nrmtbl[ord('.')] := 'X'; nrmtbl[ord('l')] := 'Y';
   nrmtbl[ord('4')] := 'Z'; nrmtbl[ord('?')] := '['; nrmtbl[ord('i')] := '\\';
   nrmtbl[ord('F')] := ']'; nrmtbl[ord('I')] := '^'; nrmtbl[ord('J')] := '_';
   nrmtbl[ord('A')] := '`'; nrmtbl[ord('9')] := 'a'; nrmtbl[ord('/')] := 'b';
   nrmtbl[ord('Z')] := 'c'; nrmtbl[ord('$')] := 'd'; nrmtbl[ord('n')] := 'e';
   nrmtbl[ord('~')] := 'f'; nrmtbl[ord('N')] := 'g'; nrmtbl[ord('(')] := 'h';
   nrmtbl[ord('6')] := 'i'; nrmtbl[ord('2')] := 'j'; nrmtbl[ord('0')] := 'k';
   nrmtbl[ord('^')] := 'l'; nrmtbl[ord('&')] := 'm'; nrmtbl[ord('[')] := 'n';
   nrmtbl[ord('3')] := 'o'; nrmtbl[ord('%')] := 'p'; nrmtbl[ord('W')] := 'q';
   nrmtbl[ord('+')] := 'r'; nrmtbl[ord('8')] := 's'; nrmtbl[ord(';')] := 't';
   nrmtbl[ord('k')] := 'u'; nrmtbl[ord(']')] := 'v'; nrmtbl[ord('h')] := 'w';
   nrmtbl[ord('*')] := 'x'; nrmtbl[ord('_')] := 'y'; nrmtbl[ord('T')] := 'z';
   nrmtbl[ord('u')] := '{'; nrmtbl[ord('E')] := '|'; nrmtbl[ord('K')] := '}';
   nrmtbl[ord('Q')] := '~';
   { use that to form the normal to encoded array } 
   for ci := 0 to 255 do xlttbl[ord(nrmtbl[ci])] := chr(ci)

end.