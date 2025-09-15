{******************************************************************************
*                                                                             *
*                         DIRECT NETWORK ACCESS EXAMPLE                       *
*                                                                             *
*                              May 2006 S. A. Moore                           *
*                                                                             *
* A simple example of direct access to tcp/ip networking via Winsock. Calls   *
* up a fixed location email pop server, and prints a header list of all       *
* emails pending read.                                                        *
*                                                                             *
******************************************************************************}

program dirnet(output);

uses windows,
     stddef,
     strlib;

const user = 'yourusername';
      pass = 'yourpassword';

var r: integer;
    wsd: sc_wsadata;
    sd: integer;
    sa: sc_sockaddr;
    bap: gbtptr;
    c: char;
    endfil: boolean;
    s: packed array 200 of char;

procedure getchr(var c: char);

var r: integer;

begin

   r := sc_recv(sd, bap^, 0);
   if (r <> 1) and (r <> 0) then begin
 
      writeln('*** Recv error');
      halt

   end;
   if r = 0 then begin { end of file }

      endfil := true;
      c := ' '

   end;

   c := chr(bap^[1])

end;

procedure putchr(c: char);

var r: integer;

begin

   bap^[1] := ord(c);
   r := sc_send(sd, bap^, 0);
   if r <> 1 then begin
 
      writeln('*** Send error');
      halt

   end

end;

procedure getlin(var s: string);

var c: char;
    i: integer;

begin

   i := 1;
   repeat 

      getchr(c); 
      write(c) ;
      if c >= ' ' then begin

         s[i] := c;
         i := i+1

      end

   until c = '\lf'

end;

procedure getrsp;

var s: packed array 200 of char;
    i: integer;

begin

   repeat

      clears(s);
      getlin(s)
      
   until compp(s, '.')

end;

procedure putstr(view s: string);

var i: integer;

begin

   for i := 1 to max(s) do begin write(s[i]); putchr(s[i]) end

end;

procedure putlin(view s: string);

var i: integer;

begin

   putstr(s);
putchr('\cr');
   putchr('\lf'); { note pop clients speak Unix line endings }
   writeln

end;

procedure putcom(view s: string);

var t: packed array 200 of char;

begin

   putlin(s); { output command }
   getlin(t); { get response }
   if t[1] <> '+' then begin

      writeln('*** Error: protocol error');
      halt

   end

end;
   
begin

   writeln('Direct network example');

   new(bap, 1);
   endfil := false;
   r := sc_wsastartup($0002, wsd);
   if r <> 0 then begin

      writeln('*** Error: Winsock fails to start');
      halt

   end;
   sd := sc_socket(sc_af_inet, sc_sock_stream, 0);
   if sd < 0 then begin

      writeln('*** Error: Cannot get socket');
      halt

   end;
   sa.sin_family := sc_pf_inet;
   { note, parameters specified in big endian }
   sa.sin_port := 110*$100;
   sa.sin_addr[0] := 204;
   sa.sin_addr[1] := 127;
   sa.sin_addr[2] := 202;
   sa.sin_addr[3] := 10;
   r := sc_connect(sd, sa, sc_sockaddr_len);
   if r < 0 then begin

      writeln('*** Error: Cannot connect socket');
      halt

   end;
   getlin(s); { discard signing line }
   { sign on }
   putstr('user ');
   putcom(user);
   putstr('pass ');
   putcom(pass);
   putcom('list');
   getrsp;
   writeln('Connection closed');

end.