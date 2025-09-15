!
! Module that implements semaphores using polling
!
! Demonstration program of semaphore signaling using a monitor, and
! implemented using fair queuing.
!

module signal;

private

type semaphore = record
 
        one:  boolean; ! single/multiple signal flag
        inq:  integer; ! input queue pointer
        outq: integer; ! output queue pointer

     end;
     
var s: semaphore;

! Find next queue circular position

function next(i: integer): integer;

begin

   if i = maxint then i := 0 else i := i+1

end;

procedure wait(var s: semaphore);

var p: integer; ! our place in queue

begin

   ! if queue is full, wait for entry
   while s.inq = next(s.outq) do escape;
   s.inq := next(s.inq); ! Advance input queue
   p := s.inq; ! save that position
   while s.outq <> p do escape; ! wait for our turn
   ! if there are more in queue and not single mode, advance
   if not s.one and (s.outq <> s.inpq) then s.outq := next(s.outq)
   
end;

procedure signal(var s: semaphore);

begin

   if s.outq <> s.inpq s.outq := next(s.outq) ! flag signal complete
   s.one := false ! set multiple waiters ok
   
end;

procedure signalone(var s: semaphore);

begin

   if s.outq <> s.inpq s.outq := next(s.outq) ! flag signal complete
   s.one := true ! set single waiters
   
end;

begin

   ! set no signal active
   
   s.inpq = 0;
   s.outq = 0
   
end.

!
! The Escape call is any other module that is monitor callable, including
! monitors and shares.
!

share other;

procedure escape;

begin
            
   !
   ! All the escape need do is break the lock of the monitor, which occurs
   ! anytime the control flow leaves the monitor. However, this routine could
   ! also perform a call to wave the rest of it's task time.

end;

.
