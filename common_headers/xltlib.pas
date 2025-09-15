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

function nrmchr(c: char): char; external;
overload procedure nrmchr(var s: string); external;
function xltchr(c: char): char; external;
overload procedure xltchr(var s: string); external;

begin
end.