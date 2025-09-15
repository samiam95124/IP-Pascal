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

{*******************************************************************************

nrmchr

For character parameter:

Transliterate encoded character to normal. Accepts an encoded character, and
returns a normal, ASCII character.

For string parameter:

Transliterates an entire string.

*******************************************************************************}

function nrmchr(c: char): char;

begin

    nrmchr := nrmtbl[ord(c)]

end;

overload procedure nrmchr(var s: string);

var i: integer;

begin

   for i := 1 to max(s) do s[i] := nrmchr(s[i])

end;

{*******************************************************************************

xltchr

For character parameter:

Transliterate normal character to encoded. Accepts a normal ASCII character, and
returns an encoded character.

For string parameter:

Transliterates an entire string.

*******************************************************************************}

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
   for ci := 0 to 255 do xlttbl[ord(nrmtbl[ci])] := chr(ci)

end.