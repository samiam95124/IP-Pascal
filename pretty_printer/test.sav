program pretty(output);

const tabspc = 3; { tab every 3rd collumn }

type cmd = (cmnone,  { no command }
            cmsidn,  { add indentation (after tolken) }
            cmeidn,  { remove indentation (before tolken) }
            cmcrbf,  { add cr before }
            cmcraf); { add cr after }
     cmdset = set of cmd;

tolken = (cundefined,  { undefined (must be first tolken) }
          cplus,       { + }
          cminus,      { - }
          ctimes,      { * }
          crdiv,       { / }
          cequ,        { = }
          cnequ,       { <> }
          cnequa,      { >< }
          cltn,        { < }
          cgtn,        { > }
          clequ,       { <= }
          clequa,      { =< }
          cgequ,       { >= }
          cgequa,      { => }
          clparen,     { ( }
          crparen,     { ) }
          clbrkt,      { [ }
          crbrkt,      { ] }
          clct,        { left comment }
          crct,        { right comment }
          cbcms,       { := }
          cperiod,     { . }
          ccma,        { , }
          cscn,        { ; }
          ccln,        { : }
          ccmf,        { ^ }
          crange,      { .. }
          cdiv,        { div }
          cmod,        { mod }
          cnil,        { nil }
          cin,         { in }
          cor,         { or }
          cand,        { and }
          cxor,        { xor }
          cnot,        { not }
          cif,         { if }
          cthen,       { then }
          celse,       { else }
          ccase,       { case }
          cof,         { of }
          crepeat,     { repeat }
          cuntil,      { until }
          cwhile,      { while }
          cdo,         { do }
          cfor,        { for }
          cto,         { to }
          cdownto,     { downto }
          cbegin,      { begin }
          cend,        { end }
          cwith,       { with }
          cgoto,       { goto }
          cconst,      { const }
          cvar,        { var }
          ctype,       { type }
          carray,      { array }
          crecord,     { record }
          cset,        { set }
          cfile,       { file }
          cfunction,   { function }
          cprocedure,  { procedure }
          clabel,      { label }
          cpacked,     { packed }
          cprogram,    { program }
          cforward,    { forward }
          cmodule,     { module }
          cuses,       { uses }
          cprivate,    { private }
          cexternal,   { external }
          cview,       { view }
          cfixed,      { fixed }
          cprocess,    { process }
          cmonitor,    { monitor }
          cshare,      { share }
          cclass,      { class }
          cconstruct,  { construct }
          cdestruct,   { destruct }
          cis,         { is }
          catom,       { atom }
          cinteger,    { unsigned integer constant }
          cidentifier, { identifier }
          cstring,     { string constant }
          creal,       { real constant }
          ceof);       { end of file (must be last tolken) }

fixed tlkcmd: array [tolken] of cmdset = array

   { cundefined  } [], 
   { cplus       } [], 
   { cminus      } [], 
   { ctimes      } [], 
   { crdiv       } [], 
   { cequ        } [], 
   { cnequ       } [], 
   { cnequa      } [], 
   { cltn        } [], 
   { cgtn        } [], 
   { clequ       } [], 
   { clequa      } [], 
   { cgequ       } [], 
   { cgequa      } [], 
   { clparen     } [], 
   { crparen     } [], 
   { clbrkt      } [], 
   { crbrkt      } [], 
   { clct        } [], 
   { crct        } [], 
   { cbcms       } [], 
   { cperiod     } [], 
   { ccma        } [], 
   { cscn        } [cmcraf], 
   { ccln        } [], 
   { ccmf        } [], 
   { crange      } [], 
   { cdiv        } [], 
   { cmod        } [], 
   { cnil        } [], 
   { cin         } [], 
   { cor         } [], 
   { cand        } [], 
   { cxor        } [], 
   { cnot        } [], 
   { cif         } [], 
   { cthen       } [], 
   { celse       } [], 
   { ccase       } [], 
   { cof         } [], 
   { crepeat     } [cmcrbf, cmsidn], 
   { cuntil      } [cmeidn, cmcraf], 
   { cwhile      } [], 
   { cdo         } [], 
   { cfor        } [], 
   { cto         } [], 
   { cdownto     } [], 
   { cbegin      } [cmsidn], 
   { cend        } [cmeidn], 
   { cwith       } [], 
   { cgoto       } [], 
   { cconst      } [], 
   { cvar        } [cmcrbf, cmcraf], 
   { ctype       } [], 
   { carray      } [], 
   { crecord     } [], 
   { cset        } [], 
   { cfile       } [], 
   { cfunction   } [], 
   { cprocedure  } [], 
   { clabel      } [], 
   { cpacked     } [], 
   { cprogram    } [], 
   { cforward    } [], 
   { cmodule     } [], 
   { cuses       } [], 
   { cprivate    } [], 
   { cexternal   } [], 
   { cview       } [], 
   { cfixed      } [], 
   { cprocess    } [], 
   { cmonitor    } [], 
   { cshare      } [], 
   { cclass      } [], 
   { cconstruct  } [], 
   { cdestruct   } [], 
   { cis         } [], 
   { catom       } [], 
   { cinteger    } [], 
   { cidentifier } [], 
   { cstring     } [], 
   { creal       } [], 
   { ceof        } []

end;

begin

if cmcrbf in tlkcmd[cequ] then writeln('CR before');
if cmeidn in tlkcmd[cequ] then writeln('End indent');
if cmcraf in tlkcmd[cequ] then writeln('CR after');
if cmsidn in tlkcmd[cequ] then writeln('Start indent');

end.

