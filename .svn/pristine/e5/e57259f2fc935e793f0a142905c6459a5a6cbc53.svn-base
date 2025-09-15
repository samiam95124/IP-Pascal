{*******************************************************************************
*                                                                              *
*                            LIST HANDLING CLASS                               *
*                                                                              *
* Demonstrates handling of a list in IP Pascal classes.                        *
*                                                                              *
*******************************************************************************}

module listclass;

{ class for list elements }

class listelm;

{ reference to list class }

type listelmref = reference to listelm;

var next: listelmref; { next item in list }

{ add to top of list (stack) }

procedure push(var stack: listelmref);

begin

   self.next := stack; { push onto stack }
   stack := self

end;

{ remove from top of list }

procedure pop(var stack);

begin

   if stack <> nil then stack := stack.next { gap top }

end;

{ add to end of list }

procedure add(var stack: listelmref);

var p: listelmref;

begin

   { if list is empty, just add to top }
   if stack = nil then push(stack)
   else begin { add to end }

      { find last entry }
      p := stack;
      while p.next <> nil do p := p.next;
	  p.next := self; { add to end }
	  self.next := nil { clear next }

   end

end;

{ find precident entry in list }

procedure findlast(var stack, last: listelmref);

var p: listelmref;

begin

   last := nil; { clear found entry }
   if stack <> nil do begin { list not empty }

      p := stack; { index top entry }
	  while (p.next <> self) and (p <> nil) do p := p.next;
	  last := p { return that, or nil if not found }

   end

end;
    
{ delete from list }
  
procedure del(var stack: listelmref);

begin

   p := findlast(stack); { find this entry in stack }
   if p <> nil do begin { its in the list }

      p.next := self.next { gap over entry }
	  self.next := nil { set no next for this entry }

   end

end;

{ insert to list after entry }

{ insert to list before entry }

{ split lists }

{ join lists }
  
begin { listelm constructor }

   self.next := nil { clear next }

end.

{ class for entire lists }

class list;

var root: listelmref; { list active list }
    free: listelmref; { closed recycling list }

procedure push(elm: listelmref);

begin

   elm.push(root) { push element to our root }
   
end;

procedure pop(elm: listelmref);

begin

   elm.pop(root); { remove from root }
   elm.push(free) { place on free list }

end;
   
private

var p: listelmref; { pointer for list entries }

begin { list constructor }

   root := nil; { clear active list }
   free := nil { clear free list }

end;

begin { list destructor }

   while free <> nil do begin

      p := free; { index top of list }
	  free := free.next; { gap list }
	  dispose(p) { release that element }

   end

end;

begin.

begin { module listclass }
end.
