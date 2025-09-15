{*******************************************************************************
*                                                                              *
*                                REGISTRATION LOCK                             *
*                                                                              *
* This module verifies that the current software is registered correctly. To   *
* determine this, we use a combination of the following elements:              *
*                                                                              *
* 1. The cpu id.                                                               *
* 2. The MAC address(es) for the current network card(s).                      *
* 3. The windows version number and build.                                     *
*                                                                              *
* The lock attempts to be forgiving. For example, it will allow any one of the *
* elements to fail a match, and will only fail if two features don't match.    *
* If the lock fails, that is not fatal, it just means the user needs to        *
* register, which is typically handled automatically.                          *
*                                                                              *
* If any of 1 to 10 MAC addresses are recorded, and we accept a match with any *
* of them.                                                                     *
*                                                                              *
* If the cpuid instruction is not supported, then we will wave the cpuid       *
* match.                                                                       *
*                                                                              *
* The correct numbers are embedded into constant data here, which the          *
* registration program must know the location of to be able to change.         *
*                                                                              *
* At present, the parameters are setup to my main computer, saving the need    *
* to run a registration here. This has the side effect that any escaped        *
* versions from here will not work elsewhere.                                  *
*                                                                              *
*******************************************************************************}

module reglock;

uses windows,
     syslib,
     cpuid;

type macadr = array [1..6] of byte;

{ Key tables. These are here so they can be indicated by external data 
  structures. }
fixed cpustr:  integer = $68747541;
      cpustr2: integer = $69746e65;
      cpustr3: integer = $444d4163;
      cpustr4: integer = $00100f23;
fixed macarr: array [1..10] of macadr =
   array
      array $50, $50, $54, $50, $30, $30 end,
      array $33, $50, $6f, $45, $30, $30 end, 
      array $ee, $76, $20, $52, $41, $53 end, 
      array $20, $41, $53, $59, $4e, $ff end, 
      array $00, $22, $15, $86, $07, $1c end, 
      array $02, $00, $54, $55, $4e, $01 end, 
      array $00, $00, $00, $00, $00, $e0 end, 
      array $00, $00, $00, $00, $00, $00 end, 
      array $00, $00, $00, $00, $00, $00 end, 
      array $00, $00, $00, $00, $00, $00 end
   end;
fixed vercmp: integer = $17710006;

private

label 99;

var passcnt: integer; { passing tests count }

procedure fail;

begin

   ss_wrterr('Please re-register this software to continue');
   goto 99

end;

procedure vercpu;

var eax, ebx, ecx, edx: integer; { registers to the cpuid instruction }
    pass:               boolean; { passes test flag }

begin

   pass := true; { set passes by default }
   eax := 0; { set function 0, find cpu id string }
   cpuid(eax, ebx, ecx, edx);
   if (eax <> 0) or (ebx <> 0) or (ecx <> 0) or (edx <> 0) then begin

      { check cpu manufacturer string }
      if (cpustr <> ebx) or (cpustr2 <> edx) or (cpustr3 <> ecx) then
         pass := false;
      eax := 1; { set function 1, get cpu parameters }
      cpuid(eax, ebx, ecx, edx);
      { check family, model and stepping }
      if cpustr4 <> eax then pass := false

   end;
   if pass then passcnt := passcnt+1 { increment pass count if matches }

end;

procedure vermac;

var ifd:   sc_mib_ifrow; { interface info structure }
    ifn:   integer;      { interface number }
    iffnd: boolean;      { matching interface found }
    r:     integer;      { return value }

{ find matching if }

procedure findif;

var i: integer; { index for mac table }

procedure matchif(i: integer);

var m: boolean; { match variable }
    x: integer; { mac byte index }

begin

   m := true; { set match true }
   { check all bytes match }
   for x := 1 to 6 do if macarr[i, x] <> ifd.bphysaddr[x-1] then m := false;
   if m then iffnd := true { set match found }

end;

begin

   { check is ethernet address, and has 6 byte mac address }
   if (ifd.dwtype = sc_mib_if_type_ethernet) and (ifd.dwphysaddrlen = 6) then
      { try matching this }
      for i := 1 to 10 do matchif(i)

end;
   
begin

   iffnd := false; { set no matching if found }
   ifn := 1;
   repeat

      ifd.dwindex := ifn; { set interface number to look for }
      r := sc_getifentry(ifd); { get interface info }
      { if that call was good, look for a match }
      if r = 0 then findif;
      ifn := ifn+1 { next logical interface number }

   until r <> 0;
   { check any if found }
   if iffnd then passcnt := passcnt+1 { yes, increment passing count }

end;

procedure verver;


begin

   { check version, and increment pass count if matches }
   if vercmp = sc_getversion then passcnt := passcnt+1

end;

begin

   passcnt := 0; { clear passing count }
   vercpu; { verify cpu id }
   vermac; { verify mac address }
   verver; { verify version }
   if passcnt < 2 then fail { must match at least 2 items }

end;

begin

   99: { abort program }

end.