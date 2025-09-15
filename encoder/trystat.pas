This code clipped from gennod().

{

****** to do for try/except:

3. The "gblexc" entries are wrong, they are not texception variables,
   they are the hidden vector hooking entries. texception variables need
   only be a single byte, since they are only used to compare addressed.
   the single byte is used to prevent aliasing.

The model of a try is:

try
   <protected stuff>
on exception except <handler>
on exception except <handler>
except <catch all handler>
else <else action>

The implication of the try statement is that unhandled exceptions are rethrown
to the next nested try statement, and that something MUST be done with an
exception, even if that something is an empty statement.

}

      titrybgn: begin { try statement }

         gettypa(lab1, tlab); { get exception resume label }
         gettypa(lab2, tlab); { get jump over exception list }
         gettypa(lab3, tlab); { get jump to end of try statement }

{

***
         <hook global exception vector>
}

         genlst(ip^.flow2); { generate protected block }
         { jump over exception handler list }
         emitbyt($e9); { jmp }
         emitadr(lab2, itradr); { output jump location }
         { When an exception occurs, it reenters here with eax set to the
           exception variable address that was thrown. We just compare this
           to each address in turn. }
         lab1^.addr := pgmcnt; { set top of exception list }
         ip1 := ip^.flow3; { index top of exception list }
         ip2 := nil; { clear else handler }
         while ip1 <> nil do begin { traverse the exception list }

            if ip1^.t = titryexp then begin { construct exception handler }

               gettypa(lab4, tlab); { get jump to next exception }
               { evaluate exception variable, which could be complex }
               gennod(ip^.left);
               { Compare with exception actually thrown, and jump to next
                 exception if not equal. }
               emitbyt($3b); { cmp eax,r32 }
               emitbyt($c0+$04*8+dreg(ip^.lreg));
               emitbyt($0f); { jne next }
               emitbyt($80+ccode(fne));
               emitadr(lab4, itradr); { output jump location }
               genlst(ip1^.flow2); { generate exception handling block }
               { jump to end of try statement }
               emitbyt($e9); { jmp }
               emitadr(lab3, itradr); { output jump location }
               lab4^.addr := pgmcnt { set next exception jump }

            else if ip1^.t = titryels then begin { at else handler }

               if ip1^.flow <> nil then error(esysflt); { s/b be last in list }
               ip2 := ip1; { save else handler }
               ip1 := nil { terminate }

            end else error(esysflt) { garbage on list }

         end;
         { No exception clause matched, this means we need to pass the
           exception up to the next nested try statement. }

         <rethrow unhandled exception>

         { set label for exception not taken }
         lab2^.addr := pgmcnt; { set top of exception list }
         if ip2 <> nil then
            { there is an else clause }
            genlst(ip2^.flow2); { generate else block }
         lab3^.addr := pgmcnt; { set end of try statement }

      end;