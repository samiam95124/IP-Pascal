{******************************************************************************
*                                                                             *
*                          IP PASCAL PRETTY PRINTER                           *
*                                                                             *
*                       Copyright (C) 2001 S. A. Moore                        *
*                                                                             *
* Reformats the source file given. The source is completely deconstructed at  *
* the scan level, then reconstructed, so this is a fairly extreme             *
* prettyprinter. Uses the basic scheme of Ledgard and Hueras.                 *
* The scheme of using significant tolkens to keep track of code position has  *
* the advantage that the program need not be completely correct to be         *
* processed. It has the disadvantage that it may not be smart about where in  *
* program syntax it is.                                                       *
*                                                                             *
******************************************************************************}

program pretty(input, output);

uses stddef,  { standard definitions }
     strlib,  { string function }
     scanner; { scanner package }

const tabspc = 3; { tab every 3rd collumn }

type cmd = (cmnone,  { no command }
            cmsidn,  { add indentation (after tolken) }
            cmeidn,  { remove indentation (before tolken) }
            cmcrbf,  { add cr before }
            cmcraf); { add cr after }
     cmdset = set of cmd;

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

var linpos: integer; { position on output line }
    indent: integer; { current indentation }

{ write output character }

procedure outchr(c: char);

begin

   write(c); { output character }
   linpos := linpos+1 { count output }

end;

{ write string with tracking }

procedure wrtstr(view s: string);

var i: integer;

begin

   for i := 1 to lenp(s) do outchr(s[i]); { for length of string }
   outchr(' ')

end;

{ print string with formatting }

procedure prtstr;

begin

   outchr('''');
   wrtstr(nxtlab);
   outchr('''')

end;

{ output new line }

procedure newline;

var i: integer;

begin

   if linpos <> 1 then begin { not already on new line }

      writeln; { output new line }
      linpos := 1; { reset line count }
      for i := 1 to indent do outchr(' ') { process start of line indentation }

   end

end;

{ add indent }

procedure addidn;

begin

   indent := indent+tabspc { add in new indent }

end;

{ remove indent }

procedure rmvidn;

begin

   if linpos > (1+tabspc) then indent := indent-tabspc

end;
    
begin

   iniscn(input); { initalize the scanner }
   linpos := 1; { set on 1st char }
   indent := 0; { set no indent }
   repeat

      gettlk(input);
      
if cmcrbf in tlkcmd[nxttlk] then writeln('CR before');
if cmeidn in tlkcmd[nxttlk] then writeln('End indent');
if cmcraf in tlkcmd[nxttlk] then writeln('CR after');
if cmsidn in tlkcmd[nxttlk] then writeln('Start indent');
      { perform before commands }
  
      if cmcrbf in tlkcmd[nxttlk] then newline; { output new line }
      if cmeidn in tlkcmd[nxttlk] then rmvidn; { remove indent }

      if nxttlk = cstring then prtstr { print formatted string }
      else wrtstr(nxtlab); { output tolken }

      { perform after commands }

      if cmcraf in tlkcmd[nxttlk] then newline; { output new line }
      if cmsidn in tlkcmd[nxttlk] then addidn; { add indent }
      

   until nxttlk = ceof

end.

