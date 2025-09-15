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
forward external global absolute manual single container
module import export from

{ identifiers }

one abcdefghijklmnopqrzwxyz a012345 ABCDEFGHIJKLMNOPQRSTUVWXYZ
_hi this_is_an_id

{ integers }

1 10 7845 0
$a %1101 &15

{ reals }

0.0 1.0 4485.3939 1e10 1e+10 1e-10 1.1e9

{ strings }

'hi there' 'this here '' is a quote'
'heres a backslash ''\\''' 'heres a quote \''
'heres an a ''\65''' 'a b ''\$42''' 'a c ''\&103'''

'\nul  null'
'\soh  soh'
'\stx  stx'
'\etx  etx'
'\eot  eot'
'\enq  enq'
'\ack  ack'
'\bel  bel'
'\bs   bs'
'\ht   ht'
'\lf   lf'
'\vt   vt'
'\ff   ff'
'\cr   cr'
'\so   so'
'\si   si'
'\dle  dle'
'\dc1  dc1'
'\xon  xon'
'\dc2  dc2'
'\dc3  dc3'
'\xoff xoff'
'\dc4  dc4'
'\nak  nak'
'\syn  syn'
'\etb  etb'
'\can  can'
'\em   em'
'\sub  sub'
'\esc  esc'
'\fs   fs'
'\gs   gs'
'\rs   rs'
'\us   us'
'\del  del'

{ special problems }

1..5 { should not try to parse as real }

{ check include works }

#i psnststx
#include psnststx
#I psnststx.pas
#INCLUDE psnststx.pas
#i psnststx.pcl
{ see if it also works within a comment, and with an alternate ending
#i psnststx.pcl
}

{ error handling (will generate errors) }

{ error: line to long (truncated) }
                                                                                          this stuff should be ignored
{ errors: bad characters }
! # ~ ` " ? | \
{ errors: invalid integer format }
$ % %
{ errors: invalid real format }
.1 2. 1e
{ error: unterminated string
'here it is
{ error: invalid integer format in string }
'this here \$ junk' 'abc\%def' 'adf\&dfd'
{ check bad include }
#i psnststx garbage
{ check other options (all of them wrong) }
# #xyz #v #verbose #nv #noverbose #e #error #s #standard
#ns #nostandard
{ end of test }
