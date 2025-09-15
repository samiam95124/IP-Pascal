{*******************************************************************************
*                                                                              *
*                        CRLF TO LF LINE ENDING CONVERTER                      *
*                                                                              *
*                          Copyright (C) 2005 S. A. Moore                      *
*                                                                              *
* This program converts crlf line endings to lf endings.                       *
*                                                                              *
*******************************************************************************}

program cleanlf(infile, outfile);

var infile, outfile: file of char;
    lastcr, lastlf:  boolean;
    c:               char;

begin

   lastcr := false;
   lastlf := false;
   reset(infile);
   rewrite(outfile);
   while not eof(infile) do begin

      read(infile, c);
      if c = '\cr' then begin

         lastcr := false;
         if not lastlf then begin

            write(outfile, '\lf');
            lastcr := true;

         end;
         lastlf := false

      end else if c = '\lf' then begin

         lastlf := false;
         if not lastcr then begin

            write(outfile, '\lf');
            lastlf := true;

         end;
         lastcr := false

      end else begin
      
         write(outfile, c);
         lastcr := false;
         lastlf := false

      end

   end

end.

