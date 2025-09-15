program prtver(output);

uses windows,
     strlib;

var ver:   integer; { raw version number }
    maj:   integer; { major number }
    min:   integer; { minor number }
    build: integer; { build number }

begin

   writeln('Windows version test');
   
   ver := sc_getversion;

;writeh(ver, '$00000000'); writeln;

   maj := ver and $ff;
   min := ver div $100 and $ff;
   build := ver div $10000 and $7fff;

   if ver < 0 then build := 0;

   writeln('Version ', maj:1, '.', min:1, '.', build:1);

end.