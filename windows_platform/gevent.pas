{******************************************************************************
*                                                                             *
*                            EVENT DIAGNOSTIC                                 *
*                                                                             *
*                            10/02 S. A. Moore                                *
*                                                                             *
* Prints graphic level events.                                                *
*                                                                             *
******************************************************************************}

program test(input, output);

uses gralib;

var er: evtrec;

begin

   repeat

      event(input, er);
      write(ord(er.etype):2, ':');
      case er.etype of 

         etchar:    begin

            if er.char < ' ' then er.char := '.';
            writeln('ASCII character returned ''', er.char, '''')

         end;
         etup:      writeln('cursor up one line');
         etdown:    writeln('down one line');
         etleft:    writeln('left one character');
         etright:   writeln('right one character');
         etleftw:   writeln('left one word');
         etrightw:  writeln('right one word');
         ethome:    writeln('home of document');
         ethomes:   writeln('home of screen');
         ethomel:   writeln('home of line');
         etend:     writeln('end of document');
         etends:    writeln('end of screen');
         etendl:    writeln('end of line');
         etscrl:    writeln('scroll left one character');
         etscrr:    writeln('scroll right one character');
         etscru:    writeln('scroll up one line');
         etscrd:    writeln('scroll down one line');
         etpagd:    writeln('page down');
         etpagu:    writeln('page up');
         ettab:     writeln('tab');
         etenter:   writeln('enter line');
         etinsert:  writeln('insert block');
         etinsertl: writeln('insert line');
         etinsertt: writeln('insert toggle');
         etdel:     writeln('delete block');
         etdell:    writeln('delete line');
         etdelcf:   writeln('delete character forward');
         etdelcb:   writeln('delete character backward');
         etcopy:    writeln('copy block');
         etcopyl:   writeln('copy line');
         etcan:     writeln('cancel current operation');
         etstop:    writeln('stop current operation');
         etcont:    writeln('continue current operation');
         etprint:   writeln('print document');
         etprintb:  writeln('print block');
         etprints:  writeln('print screen');
         etfun:     writeln('Function key, number: ', er.fkey:1);
         etmenu:    writeln('display menu');
         etmouba:   writeln('mouse button assertion, mouse: ', er.amoun:1,
                            ' button: ', er.amoubn:1);
         etmoubd:   writeln('mouse button deassertion, mouse: ', er.dmoun:1,
                            ' button: ', er.dmoubn:1);
         etmoumov:  writeln('mouse move, mouse: ', er.mmoun:1,
                            ' x: ', er.moupx:1, ' y: ', er.moupy:1);
         ettim:     writeln('timer matures, timer: ', er.timnum:1);
         etjoyba:   writeln('joystick button assertion, stick: ', er.ajoyn:1,
                            ' button: ', er.ajoybn:1);
         etjoybd:   writeln('joystick button deassertion, stick: ',
                            er.djoyn:1, ' button: ', er.djoybn:1);
         etjoymov:  writeln('joystick move, stick: ', er.mjoyn:1,
                            ' x: ', er.joypx:1, ' y: ', er.joypy:1, 
                            ' z: ', er.joypz:1);
         etterm:    writeln('terminate program');
         etmoumovg: writeln('mouse move graphical, mouse: ', er.mmoung:1,
                            ' x: ', er.moupxg:1, ' y: ', er.moupyg:1);
         etframe:   writeln('Frame sync');

      end

   until er.etype = etterm

end.
