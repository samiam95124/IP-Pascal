{******************************************************************************
*                                                                             *
*                               TEXT CHESS                                    *
*                                                                             *
*                         Jan 1994, S. A. Moore                               *
*                                                                             *
******************************************************************************}

program chess(output);

const depthmax = 4; { maximum search depth }

type { chess piece }
     piece    = (empty, pawn, knight, bishop, rook, queen, king);
     side     = (black, white); { playing side }
     square   = record { chess square }

                  what: piece; { what piece occupys the square }
                  which: side  { which side belongs to }

               end;
     sqrinx   = 1..8; { index for board demension }
     brdinx   = record { stored chess x-y index }

                   row:     sqrinx; { row index }
                   collumn: sqrinx; { collumn index }

                end;
     board    = array [sqrinx, sqrinx] of square; { chess board }
     move     = record { move attributes record }

                   { source and destination coordinates }
                   srow,  scollumn, drow, dcollumn: sqrinx;
                   score: integer { move score }

                end;

var  pb:           packed array [sqrinx, 1..24] of char; { board initalizer }
     playboard:    board; { chess board }
     whose:        side; { whose move it is }
     row, collumn: sqrinx; { indexes for board }
     maxmove:      move; { maximum score move }
     moveno:       integer;

{ print complete board }

procedure showboard(var b: board);

var row, collumn: sqrinx; { indexes for board }
    i: sqrinx; { index }

begin

   { output fencing }
   write(' '); for i := 1 to 8 do write('---'); writeln('-');
   for row := 8 downto 1 do begin { print from top down }

      write(row:1, '|'); { separate }
      for collumn := 1 to 8 do begin { left to right }

         { output square status }
         if b[row, collumn].what = empty then write(' ') { empty square }
         else if b[row, collumn].which = white then write('W') { white }
         else write('B'); { black }
         case b[row, collumn].what of { piece }

            empty:  write(' ');
            pawn:   write('P');
            knight: write('k');
            bishop: write('B');
            rook:   write('R');
            queen:  write('Q');
            king:   write('K')

         end;
         write('|') { separate }

      end;
      writeln;
      { output fencing }
      write(' '); for i := 1 to 8 do write('---'); writeln('-')

   end;
   writeln('  A  B  C  D  E  F  G  H')

end;

{ print x-y format location }

procedure prtloc(row, collumn: sqrinx);

begin

   write(chr(ord('A')+collumn-1));
   write(row:1)

end;

{!generate all possible moves for all pieces of given color }

procedure genmovs(var playboard: board;    { board to generate moves }
                  var maxmove:   move;     { where to put maximum point move }
                      whose:     side;     { whose move to process }
                      kwatch:    boolean;  { watch for king removal }
                      depth:     integer); { depth of move search }

var row, collumn: sqrinx; { indexes for board }

{ generate all posible moves for given piece }

procedure genmov(row, collumn: sqrinx); { piece position to generate for }

{ check board square contains opposing piece }

function oppose(row, collumn: sqrinx): boolean;

begin

   oppose := (playboard[row, collumn].what <> empty) and
             (playboard[row, collumn].which <> whose)

end; { oppose }

{ check board square contains friendly piece }

function friend(row, collumn: sqrinx): boolean;

begin

   friend := (playboard[row, collumn].what <> empty) and
             (playboard[row, collumn].which = whose)

end; { friend } 

{ generate single move }

procedure domove(srow, scollumn, drow, dcollumn: sqrinx);

var newboard: board;   { trial move board }
    newmax:   move;    { trial max }
    newwhose: side;    { trial side }
    valid:    boolean; { valid mode flag }
    score:    integer; { move score }

begin

   if not friend(drow, dcollumn) then begin

      { set score for this move. Simplistically, this is just the value of any
        piece captured }
      score := ord(playboard[drow, dcollumn].what);
      { square not already occupied by a piece }
      if kwatch or (depth < depthmax) then begin 

         { check countermoves }
         newboard := playboard; { make a test board }
         { place new position }
         newboard[drow, dcollumn] := newboard[srow, scollumn]; 
         { clear old position }
         newboard[srow, scollumn].what := empty; 
         { find the opposite side }
         if whose = white then newwhose := black else newwhose := white;
         { find countermove }
         genmovs(newboard, newmax, newwhose, false, depth);
         { adjust score by the opponent's reaction. If, say, we take a piece
           and the opponent takes a piece of equal value, the net score is
           zero. Its possible to have very negative scores. }
         if depth < depthmax then score := score - newmax.score

      end;
      valid := true; { set move valid }
      { if king was watched, check was removed }
      if kwatch then if newmax.score = ord(king) then valid := false;
      if valid then begin 

         { the king didn't get captured, so move is valid }
         if score > maxmove.score then begin

            { move is better than stored "max", set as new top move }
            maxmove.srow := srow; { place starting row }
            maxmove.scollumn := scollumn; { place starting collumn }
            maxmove.drow := drow; { place ending row }
            maxmove.dcollumn := dcollumn; { place ending collumn }
            maxmove.score := score
 
         end

      end

   end

end; { domove }

{ validate knight moves }

procedure kmove(ro, co: integer);

begin

   if (row+ro >= 1) and (row+ro <= 8) and 
      (collumn+co >= 1) and (collumn+co <= 8) then { valid }
      domove(row, collumn, row+ro, collumn+co)

end; { kmove }

{ generate slide moves for bishop, rook, queen and king }

procedure smove(rd, cd: integer; { row and collumn move directions }
                single: boolean); { single move flag (for king) }

var e: boolean; { search terminate flag }
    tr, tc: integer; { search coordinates }

begin

   tr := row; { set beginning coordinates }
   tc := collumn;
   e := false; { set search }
   repeat

      tr := tr+rd; { move }
      tc := tc+cd;
      if (tr >= 1) and (tr <= 8) and
         (tc >= 1) and (tc <= 8) then begin { still on board }

         if (playboard[tr, tc].what = empty) or
            (playboard[tr, tc].which <> whose) then 
            { position empty, or occupied by other side } 
            domove(row, collumn, tr, tc); { generate move }
         { if anyone is on square, terminate }
         e := playboard[tr, tc].what <> empty 

      end else e := true { terminate off board }

   until e or single { end or single move only }

end; { smove }

{ generate pawn moves }

procedure pmove(dir: integer; { movement direction }
                home: sqrinx); { home square }

begin

   { generate single forward move }

   if ((row+dir) >= 1) and ((row+dir) <= 8) then 
      { generate advance by one move }
      if playboard[row+dir, collumn].what = empty then  { not occupied }
         domove(row, collumn, row+dir, collumn);

   { generate advance by two move }

   if (row = home) and { on first pawn row }
      (playboard[row+dir, collumn].what = empty) and
      (playboard[row+dir*2, collumn].what = empty) then { next two rows empty }
      domove(row, collumn, row+dir*2, collumn);

   { generate take left move }

   if collumn > 1 then { not flush left }
      if oppose(row+dir, collumn-1) then 
         { there is an opposing piece at the "take" slot }
         domove(row, collumn, row+dir, collumn-1);

   { generate take right move }

   if collumn < 8 then { not flush right }
      if oppose(row+dir, collumn+1) then
         { there is an opposing piece at the "take" slot }
         domove(row, collumn, row+dir, collumn+1)

end; { pmove }

begin { genmov }

   if (playboard[row, collumn].what <> empty) and { target square has a piece }
      (playboard[row, collumn].which = whose) then begin { right side }

      case playboard[row, collumn].what of { piece }

         pawn: { moves for pawn }
            if whose = white then pmove(+1, 2) { white moves }
            else pmove(-1, 7); { black moves }

         knight: begin { moves for knight }

            kmove(-2, -1); { generate all moves }
            kmove(-2, +1);
            kmove(-1, -2);
            kmove(-1, +2);
            kmove(+1, -2);
            kmove(+1, +2);
            kmove(+2, -1);
            kmove(+2, +1)

         end;

         bishop: begin { moves for bishop }

            smove(-1, -1, false); { generate all moves }
            smove(-1, +1, false);
            smove(+1, -1, false);
            smove(+1, +1, false)

         end;

         rook: begin { moves for rook }

            smove(-1, 0, false); { generate all moves }
            smove(+1, 0, false);
            smove(0, -1, false);
            smove(0, +1, false)

         end;

         queen: begin { moves for queen }

            smove(-1, -1, false); { generate all moves }
            smove(-1, +1, false);
            smove(+1, -1, false);
            smove(+1, +1, false);
            smove(-1, 0, false);
            smove(+1, 0, false);
            smove(0, -1, false);
            smove(0, +1, false)

         end;

         king: begin { moves for king }

            smove(-1, -1, true); { generate all moves }
            smove(-1, +1, true);
            smove(+1, -1, true);
            smove(+1, +1, true);
            smove(-1, 0, true);
            smove(+1, 0, true);
            smove(0, -1, true);
            smove(0, +1, true)

         end

      end

   end

end; { genmov }

begin { genmovs }

   depth := depth + 1; { increase the search depth }
   maxmove.score := -maxint; { set max move null }
   { generate all moves for current side }
   for row := 1 to 8 do { traverse the board }
      for collumn := 1 to 8 do { generate all moves }
         genmov(row, collumn)

end; { genmovs }

{ print side }

procedure prtwho;

begin

   if whose = white then write('White') else write('Black')

end;

begin

   write('Pascal chess vs. 0.1 Copyright (C) 1994 S. A. Moore ');
   writeln('ALL RIGHTS RESERVED');
   writeln;

   { initalize the playing board for standard setup. This is encoded and
     decoded from ascii form to make it easy to set up analisis positions. }

   pb[8] := 'BR Bk BB BQ BK BB Bk BR ';
   pb[7] := '            BP BP BP BP ';
   pb[6] := '                        '; 
   pb[5] := '      WP                '; 
   pb[4] := 'BP    BP BP             '; 
   pb[3] := '                        '; 
   pb[2] := 'WP    WP WP WP WP WP WP '; 
   pb[1] := 'WR    WB WQ WK WB Wk WR '; 

   { read ascii board just created }

   for row := 1 to 8 do { rows }
      for collumn := 1 to 8 do begin { collumns }

         if pb[row][(collumn-1)*3+1] = 'W' then { white piece }
            playboard[row, collumn].which := white
         else
            playboard[row, collumn].which := black;
         case pb[row][(collumn-1)*3+1+1] of { piece }

            ' ': playboard[row, collumn].what := empty;
            'P': playboard[row, collumn].what := pawn;
            'k': playboard[row, collumn].what := knight;
            'B': playboard[row, collumn].what := bishop;
            'R': playboard[row, collumn].what := rook;
            'Q': playboard[row, collumn].what := queen;
            'K': playboard[row, collumn].what := king

         end

      end;
;showboard(playboard);

   { start play }

   whose := black; { set whose move }
   moveno := 1; { set 1st move }
   repeat { move pieces }

      { generate all moves for current side }
      genmovs(playboard, maxmove, whose, true, 0);
      if maxmove.score = -maxint then begin

         write(moveno:1, ': ');
         prtwho;
         writeln(' cannot move')

      end else begin { process move }

         { announce move }
         write(moveno:1, ': ');
         prtwho; { say whose move }
         write(' moves ');
         prtloc(maxmove.srow, maxmove.scollumn);
         write(' to ');
         prtloc(maxmove.drow, maxmove.dcollumn);
         writeln(':');
         writeln;
;writeln('score: ', maxmove.score);
         { place new position }
         playboard[maxmove.drow, maxmove.dcollumn] := 
            playboard[maxmove.srow, maxmove.scollumn]; 
         { clear old position }
         playboard[maxmove.srow, maxmove.scollumn].what := empty; 
         showboard(playboard); { display new board }
         writeln; { space off }
         moveno := moveno+1 { next move }

      end;
      { flip move side }
      if whose = white then whose := black else whose := white

{;readln;}

   until true{maxmove.score = -maxint} { until no move possible }

end.
