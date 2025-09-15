/*******************************************************************************

Wrapper for windows.h

This wrapper creates some standard definitions for windows.h as parsed by
a ANSI standard compiler.

*******************************************************************************/

// MS defines

#define _MSC_VER     1300
#define _X86_        1
#define _M_IX86      300
#define _WIN32_WINNT 0x501
#define _WIN32       1
#define _CRTBLD      1

// MS special keys

#define __cdecl            /* conventions */
#define _cdecl
#define __stdcall
#define __fastcall
#define __declspec(exattr) /* note this goes nowhere */
#define __w64
#define __inline
#define _inline
#define __forceinline

// MS integer types

// typedef char  __int8;
// typedef short __int16;
// typedef int   __int32;
// typedef int   __int64; /* we don't really have one, so fake it */

#define __int8 char
#define __int16 short
#define __int32 int
#define __int64 int

// Make ups, these define missing features from windows.h

// Missing structure definitions, Mickeysoft VC++ does not require the structure
// definition to appear, so several appear to have just been forgotten.

// Thread environment block from winnt.h. Referenced several times there,
// there is no definition for this type.

struct _TEB { int a; };

// Again from winnt.h, referenced but not defined.

struct _EXCEPTION_REGISTRATION_RECORD { int; };

// From rpcndr.h, there is not much to explain these at all.

struct _NDR_ASYNC_MESSAGE { int a; };
struct _NDR_CORRELATION_INFO { int a; };
struct NDR_ALLOC_ALL_NODES_CONTEXT { int a; };
struct NDR_POINTER_QUEUE_STATE { int a; };
struct _NDR_PROC_CONTEXT { int a; };

// Referenced in several places, _PSP appears to be a true orphan.

struct _PSP { int a; };

// From msxml.h, may have something to do with pseudo objects in C.

struct DOMDocument { int a; };
struct DOMFreeThreadedDocument { int a; };
struct XMLHTTPRequest { int a; };
struct XMLDSOControl { int a; };
struct XMLDocument { int a; };

// From Excpt.h, the function _XcptFilter introduces _EXCEPTION_POINTERS in the
// header definition as an abstract structure, then defines it later in the
// global space, a clear violation of standard C. The fix is to predeclare it
// here.

struct _EXCEPTION_POINTERS;

// Several places in Windows.h return a record as the result of a function.
// The reason this works is VC++ compresses records into an integer.
// ch2ph coins a special "r_" version of this symbol when used as a function
// result, allowing us to provide our own definition for it.

typedef unsigned int r__COORD; /* x-y coordinate packed into word */
typedef unsigned int r__CLIENT_CALL_RETURN;
typedef unsigned int r__div_t; /* quotient-remainder from divide */
typedef unsigned int r__ldiv_t; /* quotient-remainder from divide */

#include "windows.h"
