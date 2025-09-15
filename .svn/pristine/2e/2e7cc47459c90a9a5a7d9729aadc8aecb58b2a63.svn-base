{*******************************************************************************
*                                                                              *
*                        Multithreading queue example                          *
*                                                                              *
* Implements a simple byte data input output queue for multiple threads. The   *
* calls to interface the queue are:                                            *                                                                              *
*                                                                              *
* procedure inqueue(b: byte);                                                  *
*                                                                              *
*    Places a byte of data into the queue. If the queue is full, it will not   *
*    not return until a location in the queue is free.                         *
*                                                                              *
* Procedure outqueue(var b: byte);                                             *
*                                                                              *
*    Gets a byte of data from the queue. If there is no data in the queue, it  *
*    will not return until there is at least one byte available.               *
*                                                                              *
* The queue is implemented with a simple array of bytes. There are two         *
* pointers, the inptr and outptr, that indicate where to place or get data     *
* from the queue. The pointers always increment, and are circular, that is,    *
* the top of the array leads to the bottom of the array.                       *
*                                                                              *
* When both pointers are equal, the queue is empty. When the next (circular)   *
* location for the in pointer is equal to the out pointer, the queue is full.  *
*                                                                              *
* There are two signals used to perform the queueing:                          *
*                                                                              *
* notempty                                                                     *
*                                                                              *
*    Indicates that the queue has received at least one byte.                  *
*                                                                              *
* notfull                                                                      *
*                                                                              *
*    Indicates that the queue has at least one byte available to place.        *
*                                                                              *
*******************************************************************************}

monitor queue;

type byte = 0..255; { data type for queue }

procedure inqueue(b: byte); forward;
procedure outqueue(var b: byte); forward;

private

const maxque = 100; { maximum length of queue }

type queinx = 1..maxque; { pointers for queue }

var fifo:     array [queinx] of byte; { fifo for queue }
    inptr:    queinx;    { in pointer }
    outptr:   queinx;    { out pointer }
    notempty: semaphore; { not empty signal }
    notfull:  semaphore; { not full signal }

{ queue pointer iterator }

function next(i: queinx): queinx;

begin

   if i = maxque then i := 1 { queue has wrapped }
   else i := i+1; { next location }

   next := i { return result }

end;

{ test queue is full }

function empty: boolean;

begin

   empty := inptr = outptr { pointers are equal }

end;

{ test queue is empty }

function full: boolean;

begin

   full := next(inptr) = outptr { next input location is out location }

end;

{ place byte in queue }

procedure inqueue(b: byte);

begin

   { if full, wait until a byte clears }
   while full do wait(notfull);

   { place input byte }
   fifo[inptr] := b;
   
   { set next input location }
   inptr := next(inptr);

   { signal queue is now not empty }
   signal(notempty)
   
end;

{ get byte from queue }

procedure outqueue(var b: byte);

begin

   { if empty, wait until a byte is available }
   while empty do wait(notempty);

   { get output byte }
   b := fifo[outptr];

   { set next output location }
   outptr := next(outptr);

   { signal queue is now not full }
   signal(notfull)

end;

begin { constructor }

   { set input = output, and queue is empty }
   inptr := 1;
   outptr := 1

end.
