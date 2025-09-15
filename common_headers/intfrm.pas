{******************************************************************************
*                                                                             *
*                         INTERMEDIATE FORM DEFINITION                        *
*                                                                             *
*                       Copyright (C) 2015 S. A. Franco                       *
*                                                                             *
*                                                                             *
* Contains the intermediate code definitions. See users manual appendix for   *
* the meaning of these operands.                                              *
*                                                                             *
******************************************************************************}

module intfrm;

type

   {

   Intermediate operator codes. Contains all the codes for markers, types,
   symbols, operations and other intermediate codes.

   Note: The intermediates were reorganized for the Pascaline version, mainly
   to highlight functional catagories, Sept. 1, 2008.

   }
   intcod = (

      { structural }
      ibgnlvl,    { begin new block level }
      iendlvl,    { end current block level }
      iusefil,    { 'uses' file string }
      ibgnpgm,    { program/procedure/function section entry }
      iendpgm,    { program/procedure/function section end }
      ibgnext,    { program exit section entry }
      iendext,    { program exit section end }
      isetlin,    { set current line }
      isetsrc,    { set current source file }
      iextmod,    { define external module name }
      { types }
      inil,       { 'nil' universal pointer }
      ilab,       { 'goto' label }
      iicst,      { integer constant }
      iscst,      { string constant }
      iccst,      { character constant }
      ircst,      { real constant }
      istcst,     { set constant }
      istet,      { set constant entry }
      iarrcst,    { array constant entry }
      iarrcel,    { array constant element }
      ireccst,    { record constant entry }
      ireccel,    { record constant element }
      ienum,      { enumerated type }
      ienme,      { enumerated constant }
      isub,       { subrange type }
      iptr,       { pointer type }
      iarray,     { array type }
      igarry,     { general array type }
      ifile,      { file type }
      iset,       { set type }
      irecord,    { record type }
      ifield,     { record field }
      iftag,      { record tag field }
      ifcas,      { record case constant }
      ivar,       { variable }
      ifix,       { fixed }
      iproc,      { procedure }
      ifunc,      { function }
      ipar,       { parameter }
      ivpar,      { variable parameter }
      iwpar,      { view parameter }
      ipproc,     { procedure parameter }
      ipfunc,     { function parameter }
      iint,       { integer type }
      ilint,      { long integer type }
      icard,      { cardinal type }
      ilcard,     { long cardinal type }
      ichar,      { character type }
      iboolean,   { output marker }
      ireal,      { real type }
      isreal,     { short real type }
      itext,      { text file type }
      ieset,      { empty set type }
      iglbl,      { global mark type }
      isemaphore, { semaphore type }
      iclass,     { class }
      iatom,      { atom }
      ithread,    { thread }
      ireference, { reference }
      iexception, { exception type }
      inull,      { placeholder type entry }
      { symbols }
      isym,       { symbol entry }
      issym,      { simple symbol entry }
      { direct loads (address is part of instruction) }
      ilodadr,    { load address operator }
      ilodfadr,   { load address function result operator }
      ilodlen,    { load general array length }
      ilodlenl,   { load general array length at level n }
      ilodafbuf,  { load address of file buffer variable }
      ilodafbuft, { load address of text file buffer variable }
      ilodasr,    { load address of class self reference operator }
      ilodawc,    { load address of 'with' class offset }
      { stack address indirect loads }
      ildiint,    { load indirect integer operator }
      ildirel,    { load indirect real operator }
      ildisrl,    { load indirect short real operator }
      ildiset,    { load indirect set operator }
      ildichr,    { load indirect character operator }
      ildibol,    { load indirect boolean operator }
      ildisrc,    { load indirect structure operator }
      ildiptr,    { load indirect pointer }
      ilditgp,    { load indirect tagged pointer }
      ilimint,    { load immediate integer operator }
      ilimrel,    { load immediate real operator }
      ilimns,     { load immediate empty set operator }
      ildiref,    { load indirect reference }
      ildimgp,    { load indirect complex tagged pointer }
      { stack address indirect stores }
      istiint,    { store integer operator }
      istisrl,    { store short real operator }
      istirel,    { store real operator }
      istichr,    { store character operator }
      istibol,    { store boolean operator }
      istiset,    { store set operator }
      istisrc,    { store structured operator }
      istigar,    { store general array }
      istitgp,    { store tagged pointer }
      istifint,   { store function result integer operator }
      istiftgp,   { store function result tagged pointer operator }
      istifsrl,   { store function result short real operator }
      istifrel,   { store function result real operator }
      istifchr,   { store function result character operator }
      istifbol,   { store function result boolean operator }
      istiref,    { store immediate reference }
      { stack operators }
      inotint,    { integer 'not' operator }
      inotbol,    { boolean 'not' operator }
      isinset,    { set single element operator }
      irngset,    { set range of elements operator }
      iintset,    { set intersection operator }
      imltrel,    { multiply real operator }
      imltint,    { multiply integer operator }
      idivrel,    { divide real operator }
      idivint,    { divide integer operator }
      imodint,    { modulo integer operator }
      iandint,    { integer 'and' operator }
      inegint,    { negate integer operator }
      inegrel,    { negate real operator }
      iuniset,    { set union operator }
      iaddrel,    { add real operator }
      iaddint,    { add integer operator }
      idifset,    { set difference operator }
      isubrel,    { subtract real operator }
      isubint,    { subtract integer operator }
      iorint,     { 'or' integer operator }
      ixorint,    { 'xor' integer operator }
      iincset,    { set inclusion operator }
      iequset,    { set equal operator }
      iequrel,    { real equal operator }
      iequstr,    { string equal operator }
      iequgst,    { general string equal operator }
      iequint,    { integer equal operator }
      iequtgp,    { tagged pointer equal operator }
      iequref,    { reference equal }
      ineqset,    { set not equal operator }
      ineqrel,    { real not equal operator }
      ineqstr,    { string not equal operator }
      ineqgst,    { general string not equal operator }
      ineqint,    { integer not equal operator }
      ineqtgp,    { tagged pointer not equal operator }
      ineqref,    { reference not equal }
      ileqset,    { set less than or equal operator }
      ileqrel,    { real less than or equal operator }
      ileqstr,    { string less than or equal operator }
      ileqgst,    { general string less than or equal operator }
      ileqint,    { integer less than or equal operator }
      igeqset,    { set greater than or equal operator }
      igeqrel,    { real greater than or equal operator }
      igeqstr,    { string greater than or equal operator }
      igeqgst,    { general string greater than or equal operator }
      igeqint,    { integer greater than or equal operator }
      iltnrel,    { real less than operator }
      iltnstr,    { string less than operator }
      iltngst,    { general string less than operator }
      iltnint,    { integer less than operator }
      igtnrel,    { real greater than operator }
      igtnstr,    { string greater than operator }
      igtngst,    { general string greater than operator }
      igtnint,    { integer greater than operator }
      iabsrel,    { abs of real operator }
      iabsint,    { abs of integer operator }
      isqrrel,    { sqr of real operator }
      isqrint,    { sqr of integer operator }
      iatnrel,    { arctan of real operator }
      icosrel,    { cos of real operator }
      iexprel,    { exp of real operator }
      ilgnrel,    { ln of real operator }
      isinrel,    { sin of real operator }
      isqtrel,    { sqrt of real operator }
      icvtitr,    { convert integer to real operator }
      icvtgtf,    { convert general to fixed array }
      icvtftg,    { convert fixed array to general }
      icvtntg,    { convert nil to nil tagged }
      iswptop,    { swap top and second stack operator }
      ipoptop,    { remove top stack operator }
      ipack,      { pack operator }
      iunpack,    { unpack operator }
      iarrref,    { array reference operator }
      iarfgar,    { general array reference operator }
      iarfmar,    { complex general array reference operator }
      irecoff,    { record offset operator }
      iobjmem,    { object offset operator }
      inew,       { new operator }
      idisp,      { dispose operator }
      itag,       { tagfield constant operator }
      iendtag,    { end of tagfields operator }
      irngchk,    { range check }
      inewgar,    { allocate general array }
      idspgar,    { deallocate general array }
      inewobj,    { create new object }
      idspobj,    { dispose of object }
      ihalt,      { halt program }
      icvtrtsr,   { convert real to short real }
      icvtntr,    { convert nil to reference }
      icvtmtg,    { convert complex to simple tagged pointer }
      icvtftm,    { convert fixed array to complex general }
      icpymgp,    { make copy of complex general array }
      icpytgp,    { make copy of simple general array }
      isignal,    { signal procedure }
      isignalone, { signalone procedure }
      iwait,      { wait procedure }
      iassert,    { assert procedure }
      iis,        { is operator }
      ithrow,     { throw procedure }
      { file I/O operators }
      iwrtsrc,    { write file operator }
      iwrtintt,   { write integer operator, text }
      iwrtchrt,   { write character operator, text }
      iwrtbolt,   { write boolean operator, text }
      iwrtrelt,   { write real operator, text }
      iwrtstrt,   { write string operator, text }
      iwrtgstt,   { write general string operator, text }
      iwrtintft,  { write integer fielded operator, text }
      iwrtchrft,  { write character fielded operator, text }
      iwrtbolft,  { write boolean fielded operator, text }
      iwrtrelft,  { write real fielded operator, text }
      iwrtstrft,  { write string fielded operator, text }
      iwrtgstft,  { write general string fielded operator, text }
      iwrtrelfft, { write real fielded and fractioned operator, text }
      iwrtsrl,    { write file short real }
      iwrtrel,    { write file real }
      iwrtset,    { write file set }
      iwrtbol,    { write file boolean }
      iwrtchr,    { write file character }
      iwrtint,    { write file integer }
      iwrteolt,   { write file end of line, text }
      iredsrc,    { read file operator }
      iredintt,   { read integer operator, text }
      iredchrt,   { read character operator, text }
      iredrelt,   { read real operator, text }
      iredsrlt,   { read short real operator }
      iredeolt,   { read file end of line }
      ieolt,      { eoln of file operator, text }
      ieof,       { eof of file operator }
      iodd,       { odd of integer operator }
      isucint,    { succ of integer operator }
      iprdint,    { pred of integer operator }
      irnd,       { round operator }
      itrc,       { trunc operator }
      iexist,     { file exists operator }
      ilen,       { file length operator }
      iloc,       { file location operator }
      iget,       { file get operator }
      igett,      { file get operator, text }
      iput,       { file put operator }
      ireset,     { file reset operator }
      irewrite,   { file rewrite operator }
      iclose,     { file close operator }
      ipaget,     { page operator, text }
      iassign,    { name file operator }
      ipos,       { position file operator }
      idel,       { delete file operator }
      ichg,       { change file operator }
      iupdate,    { update file }
      iappend,    { append file }
      { code structures }
      ibgnblk,    { begin statement block operator }
      iendblk,    { end statement block operator }
      iifbgn,     { if begin operator }
      iifend,     { if end operator }
      ielse,      { else operator }
      icasbgn,    { case begin operator }
      icasend,    { case end operator }
      icassint,   { case select integer }
      icassrng,   { case select range }
      icasels,    { case else }
      icasstb,    { case statement begin }
      icasste,    { case statement end }
      iwhlexp,    { while expression marker }
      iwhlbgn,    { while begin operator }
      iwhlend,    { while end operator }
      irptbgn,    { repeat begin operator }
      irptend,    { repeat end operator }
      ifortint,   { for 'to' integer operator }
      ifortchr,   { for 'to' character operator }
      ifortbol,   { for 'to' boolean operator }
      ifordint,   { for 'downto' integer operator }
      ifordchr,   { for 'downto' character operator }
      ifordbol,   { for 'downto' boolean operator }
      iforend,    { for end operator }
      iwthbgn,    { with begin operator }
      iwthend,    { with end operator }
      igoto,      { goto operator }
      iprcbgn,    { procedure call parameter begin operator }
      iprccal,    { procedure call operator }
      iprccali,   { procedure call indirect operator }
      ifncbgn,    { function call parameter begin operator }
      ifnccal,    { function call operator }
      ifnccali,   { function call operator }
      iprccalo,   { call inherited procedure }
      ifnccalo,   { call inherited function }
      iprcmcal,   { call procedure method }
      ifncmcal,   { call function method }
      iprcmcalo,  { call inherited procedure method }
      ifncmcalo,  { call inherited function method }
      itrybgn,    { try statement start }
      itryexp,    { try exception statement }
      itryexpspc, { try exception specific statement }
      itryexpspcbgn, { try exception specific statement start }
      itryend,    { try statement end }
      ilabequ,    { 'goto' label equation point }
      { end of file tolken }
      iendfil,    { end of file }
      { This last code is just a sentinel for the end, and does not
        appear in the intermediate. }
      iendcod

   );

begin
end.
