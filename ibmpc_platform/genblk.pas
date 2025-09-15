{*******************************************************************************
*                                                                              *
*                   GENBLOCK - Generate a series of test blocks                *
*                                                                              *
*                        COPYRIGHT (C) 2007 S. A. Moore                        *
*                                                                              *
* Just generates a series of numbered disk blocks, presently fixed at 500      *
* 512 byte blocks. It is used to generate test boot images.                    *
*                                                                              *
*******************************************************************************}

program genblk(command, output);

uses stddef;

var outfil: bytfil;
    x, y:   integer;
    blkcnt: integer;
    blksiz: integer;

begin

   while (command^ = ' ') and not eoln(command) do get(command); { skip blanks }
   if eoln(command) then begin

      writeln('Expected number of blocks');
      halt

   end;
   read(command, blkcnt);
   while (command^ = ' ') and not eoln(command) do get(command); { skip blanks }
   if eoln(command) then begin

      writeln('Expected size of blocks');
      halt

   end;
   read(command, blksiz);
   writeln('Generating block file at block.img with ', blkcnt:1, ' blocks of ', 
           blksiz:1, ' each');
   assign(outfil, 'block.img');
   rewrite(outfil);
   for x := 1 to blkcnt do begin

      write(outfil, x div 256);
      write(outfil, x mod 256);
      for y := 1 to blksiz-2 do write(outfil, 0)

   end;
   close(outfil)

end.