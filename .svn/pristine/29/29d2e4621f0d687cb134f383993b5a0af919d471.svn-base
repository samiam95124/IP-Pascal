{*******************************************************************************
*                                                                              *
*                                   TIME LOCK                                  *
*                                                                              *
* Determines if the software has exceeded a set expiration date. If so, the    *
* user is told to register the software. Uses extlib to get the time.          *
* This lock is used for beta or similar software that is meant to expire after *
* a given date.                                                                *
*                                                                              *
*******************************************************************************}

module timelock;

uses extlib;

fixed timcmp: integer = maxint; { set no time lock is set }

private

label 99;

procedure fail;

begin

   ss_wrterr('This software has passed its release limit date and time.');
   goto 99

end;

begin

   if time >= timcmp then fail { check past expiration, and fail if so }

end;

begin

   99: { abort program }

end.