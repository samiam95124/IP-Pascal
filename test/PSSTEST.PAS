{ Parser scan test
  Instructions: arrange for the scanner symbols to be output,
  then compare back with this file. }

{ test of comments }

(* again *)

{ differing should not make a difference *)

(* again }

{ nested should make no difference {{{{{{{{{ }

{ special character symbols }

+ - * / <> >< < > <= =< >= => ( ) [ ] (. .)
} { this should show up as itself }
:= . , ; : ^ @ ..

{ word symbols }

div mod nil in or and not if then else case of repeat until
while do for to downto begin end with goto const var type array
record set file function procedure label packed program

{ identifiers }

one abcdefghijklmnopqrzwxyz a012345 ABCDEFGHIJKLMNOPQRSTUVWXYZ
external global absolute manual single container forward
module import export from

{ integers }

1 10 7845 0

{ reals }

0.0 1.0 4485.3939 1e10 1e+10 1e-10 1.1e9

{ strings }

'hi there' 'this here '' is a quote' 'here''s a backslash''\'''

{ special problems }

1..5 { should not get fooled to parse as a real }

{ error handling (will generate errors) }

{ error: line to long (truncated) }
                                                                                          this stuff should be ignored
{ errors: bad characters }
# ! $ % & _ ~ ` " ? | \
{ errors: invalid real format }
.1 2. 1e
{ error: unterminated string
'here it is
{ end of test }
