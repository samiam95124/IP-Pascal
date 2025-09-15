{******************************************************************************
*                                                                             *
*                           UNIX SUPPORT ROUTINES                             *
*                                                                             *
*                        Copyright (C) 2001 S. A. Moore                       *
*                                                                             *
******************************************************************************}

module unixsup;

uses stddef;

{ get unix error string }

procedure geterr(e: integer; var p: pstring);

{ copy string }

procedure copy(var  d: pstring; view s: string);

begin

   new(d, max(s)); { create destination }
   d^ := s { copy string }

end;

begin

   if e > 124 then copy(p, '*** Error not defined ***')
   else case e of { error }

      1:   copy(p, 'Operation not permitted');
      2:   copy(p, 'No such file or directory');
      3:   copy(p, 'No such process');
      4:   copy(p, 'Interrupted system call');
      5:   copy(p, 'I/O error');
      6:   copy(p, 'No such device or address');
      7:   copy(p, 'Arg list too long');
      8:   copy(p, 'Exec format error');
      9:   copy(p, 'Bad file number');
      10:  copy(p, 'No child processes');
      11:  copy(p, 'Try again');
      12:  copy(p, 'Out of memory');
      13:  copy(p, 'Permission denied');
      14:  copy(p, 'Bad address');
      15:  copy(p, 'Block device required');
      16:  copy(p, 'Device or resource busy');
      17:  copy(p, 'File exists');
      18:  copy(p, 'Cross-device link');
      19:  copy(p, 'No such device');
      20:  copy(p, 'Not a directory');
      21:  copy(p, 'Is a directory');
      22:  copy(p, 'Invalid argument');
      23:  copy(p, 'File table overflow');
      24:  copy(p, 'Too many open files');
      25:  copy(p, 'Not a typewriter');
      26:  copy(p, 'Text file busy');
      27:  copy(p, 'File too large');
      28:  copy(p, 'No space left on device');
      29:  copy(p, 'Illegal seek');
      30:  copy(p, 'Read-only file system');
      31:  copy(p, 'Too many links');
      32:  copy(p, 'Broken pipe');
      33:  copy(p, 'Math argument out of domain of func');
      34:  copy(p, 'Math result not representable');
      35:  copy(p, 'Resource deadlock would occur');
      36:  copy(p, 'File name too long');
      37:  copy(p, 'No record locks available');
      38:  copy(p, 'Function not implemented');
      39:  copy(p, 'Directory not empty');
      40:  copy(p, 'Too many symbolic links encountered');
      41:  copy(p, '*** Error not defined ***');
      42:  copy(p, 'No message of desired type');
      43:  copy(p, 'Identifier removed');
      44:  copy(p, 'Channel number out of range');
      45:  copy(p, 'Level 2 not synchronized');
      46:  copy(p, 'Level 3 halted');
      47:  copy(p, 'Level 3 reset');
      48:  copy(p, 'Link number out of range');
      49:  copy(p, 'Protocol driver not attached');
      50:  copy(p, 'No CSI structure available');
      51:  copy(p, 'Level 2 halted');
      52:  copy(p, 'Invalid exchange');
      53:  copy(p, 'Invalid request descriptor');
      54:  copy(p, 'Exchange full');
      55:  copy(p, 'No anode');
      56:  copy(p, 'Invalid request code');
      57:  copy(p, 'Invalid slot');
      58:  copy(p, '*** Error not defined ***');
      59:  copy(p, 'Bad font file format');
      60:  copy(p, 'Device not a stream');
      61:  copy(p, 'No data available');
      62:  copy(p, 'Timer expired');
      63:  copy(p, 'Out of streams resources');
      64:  copy(p, 'Machine is not on the network');
      65:  copy(p, 'Package not installed');
      66:  copy(p, 'Object is remote');
      67:  copy(p, 'Link has been severed');
      68:  copy(p, 'Advertise error');
      69:  copy(p, 'Srmount error');
      70:  copy(p, 'Communication error on send');
      71:  copy(p, 'Protocol error');
      72:  copy(p, 'Multihop attempted');
      73:  copy(p, 'RFS specific error');
      74:  copy(p, 'Not a data message');
      75:  copy(p, 'Value too large for defined data type');
      76:  copy(p, 'Name not unique on network');
      77:  copy(p, 'File descriptor in bad state');
      78:  copy(p, 'Remote address changed');
      79:  copy(p, 'Can not access a needed shared library');
      80:  copy(p, 'Accessing a corrupted shared library');
      81:  copy(p, '.lib section in a.out corrupted');
      82:  copy(p, 'Attempting to link in too many shared libraries');
      83:  copy(p, 'Cannot exec a shared library directly');
      84:  copy(p, 'Illegal byte sequence');
      85:  copy(p, 'Interrupted system call should be restarted');
      86:  copy(p, 'Streams pipe error');
      87:  copy(p, 'Too many users');
      88:  copy(p, 'Socket operation on non-socket');
      89:  copy(p, 'Destination address required');
      90:  copy(p, 'Message too long');
      91:  copy(p, 'Protocol wrong type for socket');
      92:  copy(p, 'Protocol not available');
      93:  copy(p, 'Protocol not supported');
      94:  copy(p, 'Socket type not supported');
      95:  copy(p, 'Operation not supported on transport endpoint');
      96:  copy(p, 'Protocol family not supported');
      97:  copy(p, 'Address family not supported by protocol');
      98:  copy(p, 'Address already in use');
      99:  copy(p, 'Cannot assign requested address');
      100: copy(p, 'Network is down');
      101: copy(p, 'Network is unreachable');
      102: copy(p, 'Network dropped connection because of reset');
      103: copy(p, 'Software caused connection abort');
      104: copy(p, 'Connection reset by peer');
      105: copy(p, 'No buffer space available');
      106: copy(p, 'Transport endpoint is already connected');
      107: copy(p, 'Transport endpoint is not connected');
      108: copy(p, 'Cannot send after transport endpoint shutdown');
      109: copy(p, 'Too many references: cannot splice');
      110: copy(p, 'Connection timed out');
      111: copy(p, 'Connection refused');
      112: copy(p, 'Host is down');
      113: copy(p, 'No route to host');
      114: copy(p, 'Operation already in progress');
      115: copy(p, 'Operation now in progress');
      116: copy(p, 'Stale NFS file handle');
      117: copy(p, 'Structure needs cleaning');
      118: copy(p, 'Not a XENIX named type file');
      119: copy(p, 'No XENIX semaphores available');
      120: copy(p, 'Is a named type file');
      121: copy(p, 'Remote I/O error');
      122: copy(p, 'Quota exceeded');
      123: copy(p, 'No medium found');
      124: copy(p, 'Wrong medium type');
                   
   end             
                   
end;               

{ write unix error }

procedure writerr(var f: text; e: integer);

var p: pstring;

begin

   geterr(e, p); { get the corresponding error string }
   write(f, p^); { write that }
   dispose(p) { release it }
                   
end;               
                   
begin              
end.               
