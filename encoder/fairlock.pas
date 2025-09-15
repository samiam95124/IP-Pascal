{*******************************************************************************

Classical second level locking semaphore

Implements a lock that can be used at a higher level.

*******************************************************************************}

monitor fairlock(output);

procedure getlock; forward;
procedure putlock; forward;

private

const maxque = 255; { maximum number of queued entries }

type queptr = 0..maxque;

var released:  semaphore;
    inp, outp: queptr;

procedure incptr(var p: queptr);

begin

   if p < maxque then p := p+1 else p := 0

end;

procedure getlock;

var inps: 0..maxque;

begin

   inps := inp; { save the current queue position }
   incptr(inp); { advance the input pointer }
   while inps <> outp do wait(released);

end;

procedure putlock;

begin

   incptr(outp); { advance the output pointer }
   signalone(released) { signal the release of the lock }

end;

begin

   inp := 0; { clear input and output pointers }
   outp := 0

end.