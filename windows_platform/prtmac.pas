program test(output);

uses windows,
     strlib;

var ifd: sc_mib_ifrow;
    r:   integer;
    i:   integer;
    ifn: integer;

begin

   writeln('MAC address retrive test');
   
   ifn := 1;
   repeat

      ifd.dwindex := ifn;
      r := sc_getifentry(ifd);
      if r = 0 then begin

         write('Interface number: ', ifn:1);
         write(' Type: ');
         case ifd.dwtype of

            sc_MIB_IF_TYPE_OTHER:     write('OTHER');
            sc_MIB_IF_TYPE_ETHERNET:  write('ETHERNET');  
            sc_MIB_IF_TYPE_TOKENRING: write('TOKENRING');
            sc_MIB_IF_TYPE_FDDI:      write('FDDI');
            sc_MIB_IF_TYPE_PPP:       write('PPP');
            sc_MIB_IF_TYPE_LOOPBACK:  write('LOOPBACK');
            sc_MIB_IF_TYPE_SLIP:      write('SLIP');
            else write('???')
         
         end;
         write(' Mac address: ');
         for i := 0 to ifd.dwphysaddrlen-1 do writeh(ifd.bphysaddr[i], '00');
         writeln

      end;
      ifn := ifn+1

   until r <> 0

end.