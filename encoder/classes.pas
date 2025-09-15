program classes;

class list;

type listref = reference class; { reference to this class }

var root: listref; { root for class list }
	next: listref; { next list entry }

begin

   root := nil { clear class list }

end;