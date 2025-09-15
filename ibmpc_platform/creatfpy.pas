{*******************************************************************************
*                                                                              *
*                               BOOT SECTOR CREATOR                            *
*                                                                              *
*                         COPYRIGHT (C) 2007 S. A. MOORE                       *
*                                                                              *
* A simple program, it takes an input file that has some number of bytes from  *
* 0 to 510, pads that with zeros to make it 510 bytes, then adds $55 and $aa   *
* to the end. This essentially creates a bootable floppy disk sector. This     *
* is needed because AS cannot pad fixed space (program space) to an aribitrary *
* number.                                                                      *
*******************************************************************************}

program createfpy(infile, outfile, output);

type byte = 0..255;
     bytfil = file of byte;

var infile, outfile: bytfil;  { input and output files }
    l:               integer; { length of input file }
	b:               byte;    { byte holding }
	i:               integer;

begin

   reset(infile); { prepare input and output files }
   rewrite(outfile);
   l := length(infile); { get length of input file }
   writeln('Length of input file: ', l);
   if (l > 510) then begin

      writeln('*** Input file is > 510');
	  halt

   end;
   while not eof(infile) do begin { copy input file to output file }

      read(infile, b); { get byte }
	  write(outfile, b); { write to destination }
	  
   end;
   for i := 1 to 510-l do write(outfile, 0); { pad to end of sector }
   write(outfile, $55); { place sector boot signature }
   write(outfile, $aa);
   close(infile); { close files }
   close(outfile);
   writeln('Function complete')

end.