program test(output);

const a = 16807;
      m = 2147483647;

var gamma, rndseq, low, hi, rn: integer;

begin

  low := 1;
  hi := 100;
  gamma := a*(1 mod (m div a))-(m mod a)*(1 div (m div a));
  if gamma > 0 then rndseq := gamma else rndseq := gamma+m;
  rn := rndseq div (maxint div (hi-low+1))+low

end.
