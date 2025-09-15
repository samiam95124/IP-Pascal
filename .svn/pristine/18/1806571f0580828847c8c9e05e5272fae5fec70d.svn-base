{******************************************************************************
*                                                                             *
*                         DIRECTORY LIST PROGRAM                              *
*                                                                             *
*                       Copyright 1996 S. A. Moore                            *
*                                                                             *
* An example directory listing program using the extlib functions. Lists all  *
* the files in the current directory. Should be extended to accept a          *
* directory path, and options about what to list.                             *
*                                                                             *
******************************************************************************}

program ls(output);

uses extlib;

var fp: filptr;  { file entry pointer }
    fl: filptr;  { file entry list }
    ml: integer; { maximum length of filenames }
    i:  integer; { index for filename }

procedure permis(pm: permset);

begin

   if pmread in pm then write('r') else write('-');
   if pmwrite in pm then write('w') else write('-');
   if pmexec in pm then write('e') else write('-');
   if pmdel in pm then write('d') else write('-');
   if pmvis in pm then write('v') else write('-');
   if pmcopy in pm then write('c') else write('-');
   if pmren in pm then write('r') else write('-');
   write(' ')
   
end;

procedure tim(t: integer);

begin

   if t <> -maxint then begin { time is valid }

      writedate(output, t); { write creation date }
      write(' ');
      writetime(output, t); { write creation time }
      write(' ')

   end

end;
   
begin

   { get list of files }
   list('*.*', fl);
   { find maximum length of filenames }
   fp := fl; { index top of list }
   ml := 0; { clear maximum }
   while fp <> nil do begin

      { check new max found, and register if so }
      if max(fp^.name^) > ml then ml := max(fp^.name^);
      fp := fp^.next { link next entry }

   end;
   { list all files }
   fp := fl; { index top of list }
   while fp <> nil do begin

      write(fp^.name^);
      { pad out to maximum filename }
      for i := 1 to ml-max(fp^.name^) do write(' ');
      write(' ', fp^.size, ' ');
      if fp^.alloc <> fp^.size then begin

         { allocation not redundant with size }
         write(fp^.alloc);
         write(' ')

      end;
      if atexec in fp^.attr then write('e') else write('-');
      if atarc in fp^.attr then write('a') else write('-');
      if atsys in fp^.attr then write('s') else write('-');
      if atdir in fp^.attr then write('d') else write('-');
      write(' ');
      tim(fp^.create); { write creation time }
      tim(fp^.modify); { write modify date }
      tim(fp^.access); { write access date }
      tim(fp^.backup); { write backup date }
      permis(fp^.user); { write user permissions }
      permis(fp^.group); { write group permissions }
      permis(fp^.other); { write global permissions }
      writeln;
      fp := fp^.next { next entry }

   end

end.
