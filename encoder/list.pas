!*******************************************************************************
!
! List class 
!
! Defines a simple list class and several operations on it.
!
!*******************************************************************************

program p;

! General purpose list class

class list;

type ref = reference to list; ! reference to type

var next: ref; ! next item link in list

! Insert node to list at head

procedure insert(var root: ref);

begin

   next := root; ! link this to next
   root := self ! link root to this

end;

! Index next entry in list

procedure iterate;

begin

   self := next ! go next entry

end;

! Remove node

procedure remove(var root: ref);

var lp: ref;

begin

   if self = root then root := root.next ! gap from top
   else begin

      lp := root; ! index top of list
      while lp.next <> self do lp.iterate; ! find last entry
      lp.next := next ! gap from list

   end;
   next := nil ! clear link

end;
   
begin ! constructor

   next := nil ! clear next link

end.

! list of integer data values 

class dlist;

extends list; ! based on list class

type ref = reference to dlist; ! reference to type

var data: integer; ! data value

! Find a list entry by value

function find(value: integer): ref;

var lp: ref;

begin

   lp := self; ! index here to search forward
   if lp <> nil do begin ! the whole list is not nil

      while (lp.data <> value) and (lp.next <> nil) do lp.iterate;
      if lp.data <> value then lp := nil ! not found

   end;

   result lp ! resulting in found value or nil

end;

begin ! constructor

   data := 0 ! clear data value

end.

var mylist, lp: dlist.ref; ! our data list

procedure newvalue(value: integer);

begin

   new(lp);
   data := value;
   lp.insert(mylist)

end;

begin

   ! place some test values in a list

   newvalue(123);
   newvalue(42);
   newvalue(1);

   ! Find an entry

   lp := mylist.find(42);

   ! And remove it

   lp.remove(root);
   dispose(lp);

   ! print remaining list entries

   writeln('The list contains:');
   lp := mylist;
   while not (lp = nil) do begin

      writeln('Value: ', lp.data);
      lp.iterate

   end

end.
      
