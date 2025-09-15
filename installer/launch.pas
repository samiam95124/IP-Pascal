{*******************************************************************************
*                                                                              *
*                         IP UNINSTALLER LAUNCHER PROGRAM                      *
*                                                                              *
*                             2006/02 S. A. Moore                              *
*                                                                              *
* The launcher moves the uninstaller for IP Pascal to the temp files area,     *
* along with its associated data files, then executes it. The reason this is   *
* is needed is that the uninstaller cannot delete either itself or the         *
* directory it lives in. This job can be done by a batch file, but that puts   *
* a command window up during the execution. Instead, this program copies the   *
* files, then executes uninstall without waiting.                              *
*                                                                              *
*******************************************************************************}

program launcher;

uses stddef,
     windows, 
     strlib,
     extlib;

label 99;

type tmpstr = packed array 500 of char; { temp string }

var ipppth:       tmpstr; { IP Pascal program path }
    tmppth:       tmpstr; { temp files path }
    sname, dname: tmpstr; { filename holder }

{*******************************************************************************

Get key value

Gets the given value under a key. The root key value is specified, along with
the subkey. The value is returned in the string.

*******************************************************************************}

procedure getkeyvalue(rk: integer; view sk, vn: string; var vs: string);

var r, k, v, l, t: integer;

begin

   v := $8000000;
   v := v*16;
   r := sc_regopenkey(rk or v, sk, k);
   if r <> 0 then goto 99; { error }
   l := max(vs); { set length of string }
   r := sc_regqueryvalueex(k, vn, t, vs, l);
   if r <> 0 then goto 99; { error }
   r := sc_regclosekey(k);
   if r <> 0 then goto 99 { error }

end;

{*******************************************************************************

Get program path

Gets the IP Pascal program path, by reading the uninstall key, value
"uninstalllocation". The path is placed in prgpth.

*******************************************************************************}

procedure getpath;

const

   { root key, and uninstall key }
   root = sc_hkey_local_machine;
   key = 'software\\microsoft\\windows\\currentversion\\uninstall\\IP Pascal';

begin

   getkeyvalue(root, key, 'installlocation', ipppth) { get program path }

end;

{*******************************************************************************

Get temp path

Gets the temp files path from the registry.

*******************************************************************************}

procedure gettemp;

begin

   getenv('temp', tmppth)

end;

{*******************************************************************************

Copy file

Copies a binary file from the source to the destination.

*******************************************************************************}

procedure copyfile(view des, src: string);

var df, sf: bytfil; { source and destination files }
    b:      byte;   { byte temp }

begin

   if not exists(src) then goto 99; { terminate if file does not exist }
   assign(sf, src); { open source }
   reset(sf);
   assign(df, des); { open destination }
   rewrite(df);
   while not eof(sf) do begin { copy }

      read(sf, b); { get a byte }
      write(df, b) { put a byte }

   end;
   close(sf); { close files }
   close(df)

end;

begin

   getpath; { get IP Pascal path }
   gettemp; { get the temp path }

   maknam(sname, ipppth, 'uninstall', 'exe'); { construct source name }
   maknam(dname, tmppth, 'uninstall', 'exe'); { construct destination name }
   copyfile(dname, sname); { copy }

   maknam(sname, ipppth, 'logo', 'bmp'); { construct source name }
   maknam(dname, tmppth, 'logo', 'bmp'); { construct destination name }
   copyfile(dname, sname); { copy }

   maknam(sname, ipppth, 'stop', 'bmp'); { construct source name }
   maknam(dname, tmppth, 'stop', 'bmp'); { construct destination name }
   copyfile(dname, sname); { copy }

   setcur(tmppth);
   exec('uninstall.exe');

   99:

end.
