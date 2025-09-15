{******************************************************************************
*                                                                             *
*                   WINDOWS 95 SYSTEM CALL WRAPPER DEFINE FILE                *
*                                                                             *
*                              95/9 S. A. Moore                               *
*                                                                             *
* Defines all of the system calls used, in Pascal format. The actual wrappers *
* are contained in "windows.asm". This module is simply used to provide       *
* source level definitions.                                                   *
*                                                                             *
* This is the old, manual version of the file. See the new version, generated *
* by ch2ph. This file is maintained as a backup to that, and for compilation  *
* speed reasons.                                                              *
*                                                                             *
* In adapting C type calls to pascal type calls, several adaptions occur:     *
*                                                                             *
* 1.Strings are converted from Pascal's format to the zero terminated format  *
* in C. This is pretty transparent to the user, but if a zero is passed in    *
* the string, this effectively terminates it.                                 *
*                                                                             *
* 2. Windows (and other C based call systems) treat some pointer passed       *
* structures is by allowing them to be passed nil if the parameter is         *
* "nonexistent". Since C typically passes VAR arguments that way, the result  *
* is not only unworkable but also very unsafe.                                *
* The answer way we do this is to create a different version of the full call *
* (the one that has the structure passed) that has the optional parameter     *
* zeroed out. This call will not have a parameter in that spot, and will have *
* the form:                                                                   *
*                                                                             *
* myfunc(x, y, z) - Normal call                                               *
* myfunc_n(x, y)  - Call with z zeroed out                                    *
* myfunc_nn(x)    - Call with y and z zeroed out                              *
*                                                                             *
* The problem is that the option parameters can be scattered around the calls *
* list. The only way to find out the position for sure is to look at the      *
* parameter names or look at wrapper.asm.                                     *
*                                                                             *
* 3. Windows has parameters that change type depending on the mode of the     *
* call. For example, loadicon either accepts a string or a code number in the *
* second parameter according to the state of the first parameter.             *
* These kinds of general type changes are handled by also adding a "_x" value *
* to the end of the name.                                                     *
*                                                                             *
******************************************************************************}

module windows;

uses stddef; { some standard definitions }

{ Standard C type equivalences }

type

sc_c_lang_float = sreal;
sc_c_lang_double = real;
sc_c_lang_long_double = real;
sc_c_lang_char = char;
sc_c_lang_signed_char = char;
sc_c_lang_unsigned_char = 0..255;
sc_c_lang_int = integer;
sc_c_lang_signed_int = integer;
sc_c_lang_unsigned_int = integer;
sc_c_lang_short_int = -32768..32767;
sc_c_lang_long_int = integer;
sc_c_lang_signed_short_int = -32768..32767;
sc_c_lang_signed_long_int = integer;
sc_c_lang_unsigned_short_int = 0..65535;
sc_c_lang_unsigned_long_int = integer;

{ The types function and void are both unrepresentable }
{ in Pascal, so they become integers. The options are: }

{ 1. Change them with a instruction file rule.         }
{ 2. Use an assembly escape routine that can actually  }
{ make them integers.                                  }
{ 3. Find them and change them manually.               }

sc_c_lang_function = integer;
sc_c_lang_void = integer;

const {************************************************************************}

{ get standard handle }

sc_STD_INPUT_HANDLE  = -10;
sc_STD_OUTPUT_HANDLE = -11;
sc_STD_ERROR_HANDLE  = -12;

sc_invalid_handle_value = -1;

{ These are the generic rights. }

{   sc_GENERIC_READ    = $80000000; }
sc_GENERIC_WRITE   = $40000000;
sc_GENERIC_EXECUTE = $20000000;
sc_GENERIC_ALL     = $10000000;

{ rops }

sc_SRCCOPY     = $00CC0020;
sc_SRCPAINT    = $00EE0086;
sc_SRCAND      = $008800C6;
sc_SRCINVERT   = $00660046;
sc_SRCERASE    = $00440328;
sc_NOTSRCCOPY  = $00330008;
sc_NOTSRCERASE = $001100A6;
sc_MERGECOPY   = $00C000CA;
sc_MERGEPAINT  = $00BB0226;
sc_PATCOPY     = $00F00021;
sc_PATPAINT    = $00FB0A09;
sc_PATINVERT   = $005A0049;
sc_DSTINVERT   = $00550009;
sc_BLACKNESS   = $00000042;
sc_WHITENESS   = $00FF0062;

{ pen styles }

sc_PS_SOLID            = $0;
sc_PS_DASH             = $1;
sc_PS_DOT              = $2;
sc_PS_DASHDOT          = $3;
sc_PS_DASHDOTDOT       = $4;
sc_PS_NULL             = $5;
sc_PS_INSIDEFRAME      = $6;
sc_PS_USERSTYLE        = $7;
sc_PS_ALTERNATE        = $8;
sc_PS_STYLE_MASK       = $0000000F;
sc_PS_ENDCAP_ROUND     = $00000000;
sc_PS_ENDCAP_SQUARE    = $00000100;
sc_PS_ENDCAP_FLAT      = $00000200;
sc_PS_ENDCAP_MASK      = $00000F00;
sc_PS_JOIN_ROUND       = $00000000;
sc_PS_JOIN_BEVEL       = $00001000;
sc_PS_JOIN_MITER       = $00002000;
sc_PS_JOIN_MASK        = $0000F000;
sc_PS_COSMETIC         = $00000000;
sc_PS_GEOMETRIC        = $00010000;
sc_PS_TYPE_MASK        = $000F0000;

{ Brush Styles }

sc_BS_SOLID            = 0;
sc_BS_NULL             = 1;
sc_BS_HOLLOW           = sc_BS_NULL;
sc_BS_HATCHED          = 2;
sc_BS_PATTERN          = 3;
sc_BS_INDEXED          = 4;
sc_BS_DIBPATTERN       = 5;
sc_BS_DIBPATTERNPT     = 6;
sc_BS_PATTERN8X8       = 7;

{ Binary raster ops }

sc_R2_BLACK            = 1; 
sc_R2_NOTMERGEPEN      = 2; 
sc_R2_MASKNOTPEN       = 3; 
sc_R2_NOTCOPYPEN       = 4; 
sc_R2_MASKPENNOT       = 5; 
sc_R2_NOT              = 6; 
sc_R2_XORPEN           = 7; 
sc_R2_NOTMASKPEN       = 8; 
sc_R2_MASKPEN          = 9; 
sc_R2_NOTXORPEN        = 10;
sc_R2_NOP              = 11;
sc_R2_MERGENOTPEN      = 12;
sc_R2_COPYPEN          = 13;
sc_R2_MERGEPENNOT      = 14;
sc_R2_MERGEPEN         = 15;
sc_R2_WHITE            = 16;
sc_R2_LAST             = 16;

{ file open mode flags }

sc_OF_READ             = $00000000;
sc_OF_WRITE            = $00000001;
sc_OF_READWRITE        = $00000002;
sc_OF_SHARE_COMPAT     = $00000000;
sc_OF_SHARE_EXCLUSIVE  = $00000010;
sc_OF_SHARE_DENY_WRITE = $00000020;
sc_OF_SHARE_DENY_READ  = $00000030;
sc_OF_SHARE_DENY_NONE  = $00000040;
sc_OF_PARSE            = $00000100;
sc_OF_DELETE           = $00000200;
sc_OF_VERIFY           = $00000400;
sc_OF_CANCEL           = $00000800;
sc_OF_CREATE           = $00001000;
sc_OF_PROMPT           = $00002000;
sc_OF_EXIST            = $00004000;
sc_OF_REOPEN           = $00008000;

sc_GMEM_FIXED          = $0000;
sc_GMEM_MOVEABLE       = $0002;
sc_GMEM_NOCOMPACT      = $0010;
sc_GMEM_NODISCARD      = $0020;
sc_GMEM_ZEROINIT       = $0040;
sc_GMEM_MODIFY         = $0080;
sc_GMEM_DISCARDABLE    = $0100;
sc_GMEM_NOT_BANKED     = $1000;
sc_GMEM_SHARE          = $2000;
sc_GMEM_DDESHARE       = $2000;
sc_GMEM_NOTIFY         = $4000;
sc_GMEM_LOWER          = sc_GMEM_NOT_BANKED;
sc_GMEM_VALID_FLAGS    = $7F72;
sc_GMEM_INVALID_HANDLE = $8000;

{ Virtual Keys, Standard Set }

sc_VK_LBUTTON   = $01;
sc_VK_RBUTTON   = $02;
sc_VK_CANCEL    = $03;
sc_VK_MBUTTON   = $04;    { NOT contiguous with L & RBUTTON }

sc_VK_BACK      = $08;
sc_VK_TAB       = $09;

sc_VK_CLEAR     = $0C;
sc_VK_RETURN    = $0D;

sc_VK_SHIFT     = $10;
sc_VK_CONTROL   = $11;
sc_VK_MENU      = $12;
sc_VK_PAUSE     = $13;
sc_VK_CAPITAL   = $14;

sc_VK_ESCAPE    = $1B;
             
sc_VK_SPACE     = $20;
sc_VK_PRIOR     = $21;
sc_VK_NEXT      = $22;
sc_VK_END       = $23;
sc_VK_HOME      = $24;
sc_VK_LEFT      = $25;
sc_VK_UP        = $26;
sc_VK_RIGHT     = $27;
sc_VK_DOWN      = $28;
sc_VK_SELECT    = $29;
sc_VK_PRINT     = $2A;
sc_VK_EXECUTE   = $2B;
sc_VK_SNAPSHOT  = $2C;
sc_VK_INSERT    = $2D;
sc_VK_DELETE    = $2E;
sc_VK_HELP      = $2F;

{ VK_0 thru VK_9 are the same as ASCII '0' thru '9' ($30 - $39) }
{ VK_A thru VK_Z are the same as ASCII 'A' thru 'Z' ($41 - $5A) }
             
sc_VK_NUMPAD0   = $60;
sc_VK_NUMPAD1   = $61;
sc_VK_NUMPAD2   = $62;
sc_VK_NUMPAD3   = $63;
sc_VK_NUMPAD4   = $64;
sc_VK_NUMPAD5   = $65;
sc_VK_NUMPAD6   = $66;
sc_VK_NUMPAD7   = $67;
sc_VK_NUMPAD8   = $68;
sc_VK_NUMPAD9   = $69;
sc_VK_MULTIPLY  = $6A;
sc_VK_ADD       = $6B;
sc_VK_SEPARATOR = $6C;
sc_VK_SUBTRACT  = $6D;
sc_VK_DECIMAL   = $6E;
sc_VK_DIVIDE    = $6F;
sc_VK_F1        = $70;
sc_VK_F2        = $71;
sc_VK_F3        = $72;
sc_VK_F4        = $73;
sc_VK_F5        = $74;
sc_VK_F6        = $75;
sc_VK_F7        = $76;
sc_VK_F8        = $77;
sc_VK_F9        = $78;
sc_VK_F10       = $79;
sc_VK_F11       = $7A;
sc_VK_F12       = $7B;
sc_VK_F13       = $7C;
sc_VK_F14       = $7D;
sc_VK_F15       = $7E;
sc_VK_F16       = $7F;
sc_VK_F17       = $80;
sc_VK_F18       = $81;
sc_VK_F19       = $82;
sc_VK_F20       = $83;
sc_VK_F21       = $84;
sc_VK_F22       = $85;
sc_VK_F23       = $86;
sc_VK_F24       = $87;

sc_VK_NUMLOCK   = $90;
sc_VK_SCROLL    = $91;

{

VK_L* & VK_R* - left and right Alt, Ctrl and Shift virtual keys.
Used only as parameters to GetAsyncKeyState() and GetKeyState().
No other API or message will distinguish left and right keys in this way.

}   

sc_VK_LSHIFT    = $A0;
sc_VK_RSHIFT    = $A1;
sc_VK_LCONTROL  = $A2;
sc_VK_RCONTROL  = $A3;
sc_VK_LMENU     = $A4;
sc_VK_RMENU     = $A5;

sc_VK_ATTN      = $F6;
sc_VK_CRSEL     = $F7;
sc_VK_EXSEL     = $F8;
sc_VK_EREOF     = $F9;
sc_VK_PLAY      = $FA;
sc_VK_ZOOM      = $FB;
sc_VK_NONAME    = $FC;
sc_VK_PA1       = $FD;
sc_VK_OEM_CLEAR = $FE;

sc_max_path = 260; { maximum length of full pathname }
{ file attributes }
sc_FILE_SHARE_READ              = $00000001;  
sc_FILE_SHARE_WRITE             = $00000002;  
sc_FILE_ATTRIBUTE_READONLY      = $00000001;
sc_FILE_ATTRIBUTE_HIDDEN        = $00000002;
sc_FILE_ATTRIBUTE_SYSTEM        = $00000004;
sc_FILE_ATTRIBUTE_DIRECTORY     = $00000010;
sc_FILE_ATTRIBUTE_ARCHIVE       = $00000020;
sc_FILE_ATTRIBUTE_NORMAL        = $00000080;
sc_FILE_ATTRIBUTE_TEMPORARY     = $00000100;
sc_FILE_ATTRIBUTE_ATOMIC_WRITE  = $00000200;
sc_FILE_ATTRIBUTE_XACTION_WRITE = $00000400;

{ time zone call status codes }

time_zone_id_unknown = 0;
time_zone_id_standard = 1;
time_zone_id_daylight = 2;

{ system errors }

sc_NO_ERROR                         = 0;
sc_ERROR_SUCCESS                    = 0;
sc_ERROR_INVALID_FUNCTION           = 1;
sc_ERROR_FILE_NOT_FOUND             = 2;
sc_ERROR_PATH_NOT_FOUND             = 3;
sc_ERROR_TOO_MANY_OPEN_FILES        = 4;
sc_ERROR_ACCESS_DENIED              = 5;
sc_ERROR_INVALID_HANDLE             = 6;
sc_ERROR_ARENA_TRASHED              = 7;
sc_ERROR_NOT_ENOUGH_MEMORY          = 8;
sc_ERROR_INVALID_BLOCK              = 9;
sc_ERROR_BAD_ENVIRONMENT            = 10;
sc_ERROR_BAD_FORMAT                 = 11;
sc_ERROR_INVALID_ACCESS             = 12;
sc_ERROR_INVALID_DATA               = 13;
sc_ERROR_OUTOFMEMORY                = 14;
sc_ERROR_INVALID_DRIVE              = 15;
sc_ERROR_CURRENT_DIRECTORY          = 16;
sc_ERROR_NOT_SAME_DEVICE            = 17;
sc_ERROR_NO_MORE_FILES              = 18;
sc_ERROR_WRITE_PROTECT              = 19;
sc_ERROR_BAD_UNIT                   = 20;
sc_ERROR_NOT_READY                  = 21;
sc_ERROR_BAD_COMMAND                = 22;
sc_ERROR_CRC                        = 23;
sc_ERROR_BAD_LENGTH                 = 24;
sc_ERROR_SEEK                       = 25;
sc_ERROR_NOT_DOS_DISK               = 26;
sc_ERROR_SECTOR_NOT_FOUND           = 27;
sc_ERROR_OUT_OF_PAPER               = 28;
sc_ERROR_WRITE_FAULT                = 29;
sc_ERROR_READ_FAULT                 = 30;
sc_ERROR_GEN_FAILURE                = 31;
sc_ERROR_SHARING_VIOLATION          = 32;
sc_ERROR_LOCK_VIOLATION             = 33;
sc_ERROR_WRONG_DISK                 = 34;
sc_ERROR_SHARING_BUFFER_EXCEEDED    = 36;
sc_ERROR_HANDLE_EOF                 = 38;
sc_ERROR_HANDLE_DISK_FULL           = 39;
sc_ERROR_NOT_SUPPORTED              = 50;
sc_ERROR_REM_NOT_LIST               = 51;
sc_ERROR_DUP_NAME                   = 52;
sc_ERROR_BAD_NETPATH                = 53;
sc_ERROR_NETWORK_BUSY               = 54;
sc_ERROR_DEV_NOT_EXIST              = 55;
sc_ERROR_TOO_MANY_CMDS              = 56;
sc_ERROR_ADAP_HDW_ERR               = 57;
sc_ERROR_BAD_NET_RESP               = 58;
sc_ERROR_UNEXP_NET_ERR              = 59;
sc_ERROR_BAD_REM_ADAP               = 60;
sc_ERROR_PRINTQ_FULL                = 61;
sc_ERROR_NO_SPOOL_SPACE             = 62;
sc_ERROR_PRINT_CANCELLED            = 63;
sc_ERROR_NETNAME_DELETED            = 64;
sc_ERROR_NETWORK_ACCESS_DENIED      = 65;
sc_ERROR_BAD_DEV_TYPE               = 66;
sc_ERROR_BAD_NET_NAME               = 67;
sc_ERROR_TOO_MANY_NAMES             = 68;
sc_ERROR_TOO_MANY_SESS              = 69;
sc_ERROR_SHARING_PAUSED             = 70;
sc_ERROR_REQ_NOT_ACCEP              = 71;
sc_ERROR_REDIR_PAUSED               = 72;
sc_ERROR_FILE_EXISTS                = 80;
sc_ERROR_CANNOT_MAKE                = 82;
sc_ERROR_FAIL_I24                   = 83;
sc_ERROR_OUT_OF_STRUCTURES          = 84;
sc_ERROR_ALREADY_ASSIGNED           = 85;
sc_ERROR_INVALID_PASSWORD           = 86;
sc_ERROR_INVALID_PARAMETER          = 87;
sc_ERROR_NET_WRITE_FAULT            = 88;
sc_ERROR_NO_PROC_SLOTS              = 89;
sc_ERROR_TOO_MANY_SEMAPHORES        = 100;
sc_ERROR_EXCL_SEM_ALREADY_OWNED     = 101;
sc_ERROR_SEM_IS_SET                 = 102;
sc_ERROR_TOO_MANY_SEM_REQUESTS      = 103;
sc_ERROR_INVALID_AT_INTERRUPT_TIME  = 104;
sc_ERROR_SEM_OWNER_DIED             = 105;
sc_ERROR_SEM_USER_LIMIT             = 106;
sc_ERROR_DISK_CHANGE                = 107;
sc_ERROR_DRIVE_LOCKED               = 108;
sc_ERROR_BROKEN_PIPE                = 109;
sc_ERROR_OPEN_FAILED                = 110;
sc_ERROR_BUFFER_OVERFLOW            = 111;
sc_ERROR_DISK_FULL                  = 112;
sc_ERROR_NO_MORE_SEARCH_HANDLES     = 113;
sc_ERROR_INVALID_TARGET_HANDLE      = 114;
sc_ERROR_INVALID_CATEGORY           = 117;
sc_ERROR_INVALID_VERIFY_SWITCH      = 118;
sc_ERROR_BAD_DRIVER_LEVEL           = 119;
sc_ERROR_CALL_NOT_IMPLEMENTED       = 120;
sc_ERROR_SEM_TIMEOUT                = 121;
sc_ERROR_INSUFFICIENT_BUFFER        = 122;
sc_ERROR_INVALID_NAME               = 123;
sc_ERROR_INVALID_LEVEL              = 124;
sc_ERROR_NO_VOLUME_LABEL            = 125;
sc_ERROR_MOD_NOT_FOUND              = 126;
sc_ERROR_PROC_NOT_FOUND             = 127;
sc_ERROR_WAIT_NO_CHILDREN           = 128;
sc_ERROR_CHILD_NOT_COMPLETE         = 129;
sc_ERROR_DIRECT_ACCESS_HANDLE       = 130;
sc_ERROR_NEGATIVE_SEEK              = 131;
sc_ERROR_SEEK_ON_DEVICE             = 132;
sc_ERROR_IS_JOIN_TARGET             = 133;
sc_ERROR_IS_JOINED                  = 134;
sc_ERROR_IS_SUBSTED                 = 135;
sc_ERROR_NOT_JOINED                 = 136;
sc_ERROR_NOT_SUBSTED                = 137;
sc_ERROR_JOIN_TO_JOIN               = 138;
sc_ERROR_SUBST_TO_SUBST             = 139;
sc_ERROR_JOIN_TO_SUBST              = 140;
sc_ERROR_SUBST_TO_JOIN              = 141;
sc_ERROR_BUSY_DRIVE                 = 142;
sc_ERROR_SAME_DRIVE                 = 143;
sc_ERROR_DIR_NOT_ROOT               = 144;
sc_ERROR_DIR_NOT_EMPTY              = 145;
sc_ERROR_IS_SUBST_PATH              = 146;
sc_ERROR_IS_JOIN_PATH               = 147;
sc_ERROR_PATH_BUSY                  = 148;
sc_ERROR_IS_SUBST_TARGET            = 149;
sc_ERROR_SYSTEM_TRACE               = 150;
sc_ERROR_INVALID_EVENT_COUNT        = 151;
sc_ERROR_TOO_MANY_MUXWAITERS        = 152;
sc_ERROR_INVALID_LIST_FORMAT        = 153;
sc_ERROR_LABEL_TOO_LONG             = 154;
sc_ERROR_TOO_MANY_TCBS              = 155;
sc_ERROR_SIGNAL_REFUSED             = 156;
sc_ERROR_DISCARDED                  = 157;
sc_ERROR_NOT_LOCKED                 = 158;
sc_ERROR_BAD_THREADID_ADDR          = 159;
sc_ERROR_BAD_ARGUMENTS              = 160;
sc_ERROR_BAD_PATHNAME               = 161;
sc_ERROR_SIGNAL_PENDING             = 162;
sc_ERROR_MAX_THRDS_REACHED          = 164;
sc_ERROR_LOCK_FAILED                = 167;
sc_ERROR_BUSY                       = 170;
sc_ERROR_CANCEL_VIOLATION           = 173;
sc_ERROR_ATOMIC_LOCKS_NOT_SUPPORTED = 174;
sc_ERROR_INVALID_SEGMENT_NUMBER     = 180;
sc_ERROR_INVALID_ORDINAL            = 182;
sc_ERROR_ALREADY_EXISTS             = 183;
sc_ERROR_INVALID_FLAG_NUMBER        = 186;
sc_ERROR_SEM_NOT_FOUND              = 187;
sc_ERROR_INVALID_STARTING_CODESEG   = 188;
sc_ERROR_INVALID_STACKSEG           = 189;
sc_ERROR_INVALID_MODULETYPE         = 190;
sc_ERROR_INVALID_EXE_SIGNATURE      = 191;
sc_ERROR_EXE_MARKED_INVALID         = 192;
sc_ERROR_BAD_EXE_FORMAT             = 193;
sc_ERROR_ITERATED_DATA_EXCEEDS_64k  = 194;
sc_ERROR_INVALID_MINALLOCSIZE       = 195;
sc_ERROR_DYNLINK_FROM_INVALID_RING  = 196;
sc_ERROR_IOPL_NOT_ENABLED           = 197;
sc_ERROR_INVALID_SEGDPL             = 198;
sc_ERROR_AUTODATASEG_EXCEEDS_64k    = 199;
sc_ERROR_RING2SEG_MUST_BE_MOVABLE   = 200;
sc_ERROR_RELOC_CHAIN_XEEDS_SEGLIM   = 201;
sc_ERROR_INFLOOP_IN_RELOC_CHAIN     = 202;
sc_ERROR_ENVVAR_NOT_FOUND           = 203;
sc_ERROR_NO_SIGNAL_SENT             = 205;
sc_ERROR_FILENAME_EXCED_RANGE       = 206;
sc_ERROR_RING2_STACK_IN_USE         = 207;
sc_ERROR_META_EXPANSION_TOO_LONG    = 208;
sc_ERROR_INVALID_SIGNAL_NUMBER      = 209;
sc_ERROR_THREAD_1_INACTIVE          = 210;
sc_ERROR_LOCKED                     = 212;
sc_ERROR_TOO_MANY_MODULES           = 214;
sc_ERROR_NESTING_NOT_ALLOWED        = 215;
sc_ERROR_BAD_PIPE                   = 230;
sc_ERROR_PIPE_BUSY                  = 231;
sc_ERROR_NO_DATA                    = 232;
sc_ERROR_PIPE_NOT_CONNECTED         = 233;
sc_ERROR_MORE_DATA                  = 234;
sc_ERROR_VC_DISCONNECTED            = 240;
sc_ERROR_INVALID_EA_NAME            = 254;
sc_ERROR_EA_LIST_INCONSISTENT       = 255;
sc_ERROR_NO_MORE_ITEMS              = 259;
sc_ERROR_CANNOT_COPY                = 266;
sc_ERROR_DIRECTORY                  = 267;
sc_ERROR_EAS_DIDNT_FIT              = 275;
sc_ERROR_EA_FILE_CORRUPT            = 276;
sc_ERROR_EA_TABLE_FULL              = 277;
sc_ERROR_INVALID_EA_HANDLE          = 278;
sc_ERROR_EAS_NOT_SUPPORTED          = 282;
sc_ERROR_NOT_OWNER                  = 288;
sc_ERROR_TOO_MANY_POSTS             = 298;
sc_ERROR_MR_MID_NOT_FOUND           = 317;
sc_ERROR_INVALID_ADDRESS            = 487;
sc_ERROR_ARITHMETIC_OVERFLOW        = 534;
sc_ERROR_PIPE_CONNECTED             = 535;
sc_ERROR_PIPE_LISTENING             = 536;
sc_ERROR_EA_ACCESS_DENIED           = 994;
sc_ERROR_OPERATION_ABORTED          = 995;
sc_ERROR_IO_INCOMPLETE              = 996;
sc_ERROR_IO_PENDING                 = 997;
sc_ERROR_NOACCESS                   = 998;
sc_ERROR_SWAPERROR                  = 999;
sc_ERROR_STACK_OVERFLOW             = 1001;
sc_ERROR_INVALID_MESSAGE            = 1002;
sc_ERROR_CAN_NOT_COMPLETE           = 1003;
sc_ERROR_INVALID_FLAGS              = 1004;
sc_ERROR_UNRECOGNIZED_VOLUME        = 1005;
sc_ERROR_FILE_INVALID               = 1006;
sc_ERROR_FULLSCREEN_MODE            = 1007;
sc_ERROR_NO_TOKEN                   = 1008;
sc_ERROR_BADDB                      = 1009;
sc_ERROR_BADKEY                     = 1010;
sc_ERROR_CANTOPEN                   = 1011;
sc_ERROR_CANTREAD                   = 1012;
sc_ERROR_CANTWRITE                  = 1013;
sc_ERROR_REGISTRY_RECOVERED         = 1014;
sc_ERROR_REGISTRY_CORRUPT           = 1015;
sc_ERROR_REGISTRY_IO_FAILED         = 1016;
sc_ERROR_NOT_REGISTRY_FILE          = 1017;
sc_ERROR_KEY_DELETED                = 1018;
sc_ERROR_NO_LOG_SPACE               = 1019;
sc_ERROR_KEY_HAS_CHILDREN           = 1020;
sc_ERROR_CHILD_MUST_BE_VOLATILE     = 1021;
sc_ERROR_NOTIFY_ENUM_DIR            = 1022;
sc_ERROR_DEPENDENT_SERVICES_RUNNING = 1051;
sc_ERROR_INVALID_SERVICE_CONTROL    = 1052;
sc_ERROR_SERVICE_REQUEST_TIMEOUT    = 1053;
sc_ERROR_SERVICE_NO_THREAD          = 1054;
sc_ERROR_SERVICE_DATABASE_LOCKED    = 1055;
sc_ERROR_SERVICE_ALREADY_RUNNING    = 1056;
sc_ERROR_INVALID_SERVICE_ACCOUNT    = 1057;
sc_ERROR_SERVICE_DISABLED           = 1058;
sc_ERROR_CIRCULAR_DEPENDENCY        = 1059;
sc_ERROR_SERVICE_DOES_NOT_EXIST     = 1060;
sc_ERROR_SERVICE_CANNOT_ACCEPT_CTRL = 1061;
sc_ERROR_SERVICE_NOT_ACTIVE         = 1062;
sc_ERROR_FAILED_SERVICE_CONTROLLER_CONNECT = 1063;
sc_ERROR_EXCEPTION_IN_SERVICE       = 1064;
sc_ERROR_DATABASE_DOES_NOT_EXIST    = 1065;
sc_ERROR_SERVICE_SPECIFIC_ERROR     = 1066;
sc_ERROR_PROCESS_ABORTED            = 1067;
sc_ERROR_SERVICE_DEPENDENCY_FAIL    = 1068;
sc_ERROR_SERVICE_LOGON_FAILED       = 1069;
sc_ERROR_SERVICE_START_HANG         = 1070;
sc_ERROR_INVALID_SERVICE_LOCK       = 1071;
sc_ERROR_SERVICE_MARKED_FOR_DELETE  = 1072;
sc_ERROR_SERVICE_EXISTS             = 1073;
sc_ERROR_ALREADY_RUNNING_LKG        = 1074;
sc_ERROR_SERVICE_DEPENDENCY_DELETED = 1075;
sc_ERROR_BOOT_ALREADY_ACCEPTED      = 1076;
sc_ERROR_SERVICE_NEVER_STARTED      = 1077;
sc_ERROR_DUPLICATE_SERVICE_NAME     = 1078;
sc_ERROR_END_OF_MEDIA               = 1100;
sc_ERROR_FILEMARK_DETECTED          = 1101;
sc_ERROR_BEGINNING_OF_MEDIA         = 1102;
sc_ERROR_SETMARK_DETECTED           = 1103;
sc_ERROR_NO_DATA_DETECTED           = 1104;
sc_ERROR_PARTITION_FAILURE          = 1105;
sc_ERROR_INVALID_BLOCK_LENGTH       = 1106;
sc_ERROR_DEVICE_NOT_PARTITIONED     = 1107;
sc_ERROR_UNABLE_TO_LOCK_MEDIA       = 1108;
sc_ERROR_UNABLE_TO_UNLOAD_MEDIA     = 1109;
sc_ERROR_MEDIA_CHANGED              = 1110;
sc_ERROR_BUS_RESET                  = 1111;
sc_ERROR_NO_MEDIA_IN_DRIVE          = 1112;
sc_ERROR_NO_UNICODE_TRANSLATION     = 1113;
sc_ERROR_DLL_INIT_FAILED            = 1114;
sc_ERROR_SHUTDOWN_IN_PROGRESS       = 1115;
sc_ERROR_NO_SHUTDOWN_IN_PROGRESS    = 1116;
sc_ERROR_IO_DEVICE                  = 1117;
sc_ERROR_SERIAL_NO_DEVICE           = 1118;
sc_ERROR_IRQ_BUSY                   = 1119;
sc_ERROR_MORE_WRITES                = 1120;
sc_ERROR_COUNTER_TIMEOUT            = 1121;
sc_ERROR_FLOPPY_ID_MARK_NOT_FOUND   = 1122;
sc_ERROR_FLOPPY_WRONG_CYLINDER      = 1123;
sc_ERROR_FLOPPY_UNKNOWN_ERROR       = 1124;
sc_ERROR_FLOPPY_BAD_REGISTERS       = 1125;
sc_ERROR_DISK_RECALIBRATE_FAILED    = 1126;
sc_ERROR_DISK_OPERATION_FAILED      = 1127;
sc_ERROR_DISK_RESET_FAILED          = 1128;
sc_ERROR_EOM_OVERFLOW               = 1129;
sc_ERROR_NOT_ENOUGH_SERVER_MEMORY   = 1130;
sc_ERROR_POSSIBLE_DEADLOCK          = 1131;
sc_ERROR_MAPPED_ALIGNMENT           = 1132;
sc_ERROR_BAD_USERNAME               = 2202;
sc_ERROR_NOT_CONNECTED              = 2250;
sc_ERROR_OPEN_FILES                 = 2401;
sc_ERROR_DEVICE_IN_USE              = 2404;
sc_ERROR_BAD_DEVICE                 = 1200;
sc_ERROR_CONNECTION_UNAVAIL         = 1201;
sc_ERROR_DEVICE_ALREADY_REMEMBERED  = 1202;
sc_ERROR_NO_NET_OR_BAD_PATH         = 1203;
sc_ERROR_BAD_PROVIDER               = 1204;
sc_ERROR_CANNOT_OPEN_PROFILE        = 1205;
sc_ERROR_BAD_PROFILE                = 1206;
sc_ERROR_NOT_CONTAINER              = 1207;
sc_ERROR_EXTENDED_ERROR             = 1208;
sc_ERROR_INVALID_GROUPNAME          = 1209;
sc_ERROR_INVALID_COMPUTERNAME       = 1210;
sc_ERROR_INVALID_EVENTNAME          = 1211;
sc_ERROR_INVALID_DOMAINNAME         = 1212;
sc_ERROR_INVALID_SERVICENAME        = 1213;
sc_ERROR_INVALID_NETNAME            = 1214;
sc_ERROR_INVALID_SHARENAME          = 1215;
sc_ERROR_INVALID_PASSWORDNAME       = 1216;
sc_ERROR_INVALID_MESSAGENAME        = 1217;
sc_ERROR_INVALID_MESSAGEDEST        = 1218;
sc_ERROR_SESSION_CREDENTIAL_CONFLICT = 1219;
sc_ERROR_REMOTE_SESSION_LIMIT_EXCEEDED = 1220;
sc_ERROR_DUP_DOMAINNAME             = 1221;
sc_ERROR_NO_NETWORK                 = 1222;
sc_ERROR_NOT_ALL_ASSIGNED           = 1300;
sc_ERROR_SOME_NOT_MAPPED            = 1301;
sc_ERROR_NO_QUOTAS_FOR_ACCOUNT      = 1302;
sc_ERROR_LOCAL_USER_SESSION_KEY     = 1303;
sc_ERROR_NULL_LM_PASSWORD           = 1304;
sc_ERROR_UNKNOWN_REVISION           = 1305;
sc_ERROR_REVISION_MISMATCH          = 1306;
sc_ERROR_INVALID_OWNER              = 1307;
sc_ERROR_INVALID_PRIMARY_GROUP      = 1308;
sc_ERROR_NO_IMPERSONATION_TOKEN     = 1309;
sc_ERROR_CANT_DISABLE_MANDATORY     = 1310;
sc_ERROR_NO_LOGON_SERVERS           = 1311;
sc_ERROR_NO_SUCH_LOGON_SESSION      = 1312;
sc_ERROR_NO_SUCH_PRIVILEGE          = 1313;
sc_ERROR_PRIVILEGE_NOT_HELD         = 1314;
sc_ERROR_INVALID_ACCOUNT_NAME       = 1315;
sc_ERROR_USER_EXISTS                = 1316;
sc_ERROR_NO_SUCH_USER               = 1317;
sc_ERROR_GROUP_EXISTS               = 1318;
sc_ERROR_NO_SUCH_GROUP              = 1319;
sc_ERROR_MEMBER_IN_GROUP            = 1320;
sc_ERROR_MEMBER_NOT_IN_GROUP        = 1321;
sc_ERROR_LAST_ADMIN                 = 1322;
sc_ERROR_WRONG_PASSWORD             = 1323;
sc_ERROR_ILL_FORMED_PASSWORD        = 1324;
sc_ERROR_PASSWORD_RESTRICTION       = 1325;
sc_ERROR_LOGON_FAILURE              = 1326;
sc_ERROR_ACCOUNT_RESTRICTION        = 1327;
sc_ERROR_INVALID_LOGON_HOURS        = 1328;
sc_ERROR_INVALID_WORKSTATION        = 1329;
sc_ERROR_PASSWORD_EXPIRED           = 1330;
sc_ERROR_ACCOUNT_DISABLED           = 1331;
sc_ERROR_NONE_MAPPED                = 1332;
sc_ERROR_TOO_MANY_LUIDS_REQUESTED   = 1333;
sc_ERROR_LUIDS_EXHAUSTED            = 1334;
sc_ERROR_INVALID_SUB_AUTHORITY      = 1335;
sc_ERROR_INVALID_ACL                = 1336;
sc_ERROR_INVALID_SID                = 1337;
sc_ERROR_INVALID_SECURITY_DESCR     = 1338;
sc_ERROR_BAD_INHERITANCE_ACL        = 1340;
sc_ERROR_SERVER_DISABLED            = 1341;
sc_ERROR_SERVER_NOT_DISABLED        = 1342;
sc_ERROR_INVALID_ID_AUTHORITY       = 1343;
sc_ERROR_ALLOTTED_SPACE_EXCEEDED    = 1344;
sc_ERROR_INVALID_GROUP_ATTRIBUTES   = 1345;
sc_ERROR_BAD_IMPERSONATION_LEVEL    = 1346;
sc_ERROR_CANT_OPEN_ANONYMOUS        = 1347;
sc_ERROR_BAD_VALIDATION_CLASS       = 1348;
sc_ERROR_BAD_TOKEN_TYPE             = 1349;
sc_ERROR_NO_SECURITY_ON_OBJECT      = 1350;
sc_ERROR_CANT_ACCESS_DOMAIN_INFO    = 1351;
sc_ERROR_INVALID_SERVER_STATE       = 1352;
sc_ERROR_INVALID_DOMAIN_STATE       = 1353;
sc_ERROR_INVALID_DOMAIN_ROLE        = 1354;
sc_ERROR_NO_SUCH_DOMAIN             = 1355;
sc_ERROR_DOMAIN_EXISTS              = 1356;
sc_ERROR_DOMAIN_LIMIT_EXCEEDED      = 1357;
sc_ERROR_INTERNAL_DB_CORRUPTION     = 1358;
sc_ERROR_INTERNAL_ERROR             = 1359;
sc_ERROR_GENERIC_NOT_MAPPED         = 1360;
sc_ERROR_BAD_DESCRIPTOR_FORMAT      = 1361;
sc_ERROR_NOT_LOGON_PROCESS          = 1362;
sc_ERROR_LOGON_SESSION_EXISTS       = 1363;
sc_ERROR_NO_SUCH_PACKAGE            = 1364;
sc_ERROR_BAD_LOGON_SESSION_STATE    = 1365;
sc_ERROR_LOGON_SESSION_COLLISION    = 1366;
sc_ERROR_INVALID_LOGON_TYPE         = 1367;
sc_ERROR_CANNOT_IMPERSONATE         = 1368;
sc_ERROR_RXACT_INVALID_STATE        = 1369;
sc_ERROR_RXACT_COMMIT_FAILURE       = 1370;
sc_ERROR_SPECIAL_ACCOUNT            = 1371;
sc_ERROR_SPECIAL_GROUP              = 1372;
sc_ERROR_SPECIAL_USER               = 1373;
sc_ERROR_MEMBERS_PRIMARY_GROUP      = 1374;
sc_ERROR_TOKEN_ALREADY_IN_USE       = 1375;
sc_ERROR_NO_SUCH_ALIAS              = 1376;
sc_ERROR_MEMBER_NOT_IN_ALIAS        = 1377;
sc_ERROR_MEMBER_IN_ALIAS            = 1378;
sc_ERROR_ALIAS_EXISTS               = 1379;
sc_ERROR_LOGON_NOT_GRANTED          = 1380;
sc_ERROR_TOO_MANY_SECRETS           = 1381;
sc_ERROR_SECRET_TOO_LONG            = 1382;
sc_ERROR_INTERNAL_DB_ERROR          = 1383;
sc_ERROR_TOO_MANY_CONTEXT_IDS       = 1384;
sc_ERROR_LOGON_TYPE_NOT_GRANTED     = 1385;
sc_ERROR_NT_CROSS_ENCRYPTION_REQUIRED = 1386;
sc_ERROR_NO_SUCH_MEMBER             = 1387;
sc_ERROR_INVALID_MEMBER             = 1388;
sc_ERROR_TOO_MANY_SIDS              = 1389;
sc_ERROR_LM_CROSS_ENCRYPTION_REQUIRED = 1390;
sc_ERROR_NO_INHERITANCE             = 1391;
sc_ERROR_FILE_CORRUPT               = 1392;
sc_ERROR_DISK_CORRUPT               = 1393;
sc_ERROR_NO_USER_SESSION_KEY        = 1394;
sc_ERROR_INVALID_WINDOW_HANDLE      = 1400;
sc_ERROR_INVALID_MENU_HANDLE        = 1401;
sc_ERROR_INVALID_CURSOR_HANDLE      = 1402;
sc_ERROR_INVALID_ACCEL_HANDLE       = 1403;
sc_ERROR_INVALID_HOOK_HANDLE        = 1404;
sc_ERROR_INVALID_DWP_HANDLE         = 1405;
sc_ERROR_TLW_WITH_WSCHILD           = 1406;
sc_ERROR_CANNOT_FIND_WND_CLASS      = 1407;
sc_ERROR_WINDOW_OF_OTHER_THREAD     = 1408;
sc_ERROR_HOTKEY_ALREADY_REGISTERED  = 1409;
sc_ERROR_CLASS_ALREADY_EXISTS       = 1410;
sc_ERROR_CLASS_DOES_NOT_EXIST       = 1411;
sc_ERROR_CLASS_HAS_WINDOWS          = 1412;
sc_ERROR_INVALID_INDEX              = 1413;
sc_ERROR_INVALID_ICON_HANDLE        = 1414;
sc_ERROR_PRIVATE_DIALOG_INDEX       = 1415;
sc_ERROR_LISTBOX_ID_NOT_FOUND       = 1416;
sc_ERROR_NO_WILDCARD_CHARACTERS     = 1417;
sc_ERROR_CLIPBOARD_NOT_OPEN         = 1418;
sc_ERROR_HOTKEY_NOT_REGISTERED      = 1419;
sc_ERROR_WINDOW_NOT_DIALOG          = 1420;
sc_ERROR_CONTROL_ID_NOT_FOUND       = 1421;
sc_ERROR_INVALID_COMBOBOX_MESSAGE   = 1422;
sc_ERROR_WINDOW_NOT_COMBOBOX        = 1423;
sc_ERROR_INVALID_EDIT_HEIGHT        = 1424;
sc_ERROR_DC_NOT_FOUND               = 1425;
sc_ERROR_INVALID_HOOK_FILTER        = 1426;
sc_ERROR_INVALID_FILTER_PROC        = 1427;
sc_ERROR_HOOK_NEEDS_HMOD            = 1428;
sc_ERROR_GLOBAL_ONLY_HOOK           = 1429;
sc_ERROR_JOURNAL_HOOK_SET           = 1430;
sc_ERROR_HOOK_NOT_INSTALLED         = 1431;
sc_ERROR_INVALID_LB_MESSAGE         = 1432;
sc_ERROR_SETCOUNT_ON_BAD_LB         = 1433;
sc_ERROR_LB_WITHOUT_TABSTOPS        = 1434;
sc_ERROR_DESTROY_OBJECT_OF_OTHER_THREAD = 1435;
sc_ERROR_CHILD_WINDOW_MENU          = 1436;
sc_ERROR_NO_SYSTEM_MENU             = 1437;
sc_ERROR_INVALID_MSGBOX_STYLE       = 1438;
sc_ERROR_INVALID_SPI_VALUE          = 1439;
sc_ERROR_SCREEN_ALREADY_LOCKED      = 1440;
sc_ERROR_HWNDS_HAVE_DIFF_PARENT     = 1441;
sc_ERROR_NOT_CHILD_WINDOW           = 1442;
sc_ERROR_INVALID_GW_COMMAND         = 1443;
sc_ERROR_INVALID_THREAD_ID          = 1444;
sc_ERROR_NON_MDICHILD_WINDOW        = 1445;
sc_ERROR_POPUP_ALREADY_ACTIVE       = 1446;
sc_ERROR_NO_SCROLLBARS              = 1447;
sc_ERROR_INVALID_SCROLLBAR_RANGE    = 1448;
sc_ERROR_INVALID_SHOWWIN_COMMAND    = 1449;
sc_ERROR_EVENTLOG_FILE_CORRUPT      = 1500;
sc_ERROR_EVENTLOG_CANT_START        = 1501;
sc_ERROR_LOG_FILE_FULL              = 1502;
sc_ERROR_EVENTLOG_FILE_CHANGED      = 1503;
sc_RPC_S_INVALID_STRING_BINDING     = 1700;
sc_RPC_S_WRONG_KIND_OF_BINDING      = 1701;
sc_RPC_S_INVALID_BINDING            = 1702;
sc_RPC_S_PROTSEQ_NOT_SUPPORTED      = 1703;
sc_RPC_S_INVALID_RPC_PROTSEQ        = 1704;
sc_RPC_S_INVALID_STRING_UUID        = 1705;
sc_RPC_S_INVALID_ENDPOINT_FORMAT    = 1706;
sc_RPC_S_INVALID_NET_ADDR           = 1707;
sc_RPC_S_NO_ENDPOINT_FOUND          = 1708;
sc_RPC_S_INVALID_TIMEOUT            = 1709;
sc_RPC_S_OBJECT_NOT_FOUND           = 1710;
sc_RPC_S_ALREADY_REGISTERED         = 1711;
sc_RPC_S_TYPE_ALREADY_REGISTERED    = 1712;
sc_RPC_S_ALREADY_LISTENING          = 1713;
sc_RPC_S_NO_PROTSEQS_REGISTERED     = 1714;
sc_RPC_S_NOT_LISTENING              = 1715;
sc_RPC_S_UNKNOWN_MGR_TYPE           = 1716;
sc_RPC_S_UNKNOWN_IF                 = 1717;
sc_RPC_S_NO_BINDINGS                = 1718;
sc_RPC_S_NO_PROTSEQS                = 1719;
sc_RPC_S_CANT_CREATE_ENDPOINT       = 1720;
sc_RPC_S_OUT_OF_RESOURCES           = 1721;
sc_RPC_S_SERVER_UNAVAILABLE         = 1722;
sc_RPC_S_SERVER_TOO_BUSY            = 1723;
sc_RPC_S_INVALID_NETWORK_OPTIONS    = 1724;
sc_RPC_S_NO_CALL_ACTIVE             = 1725;
sc_RPC_S_CALL_FAILED                = 1726;
sc_RPC_S_CALL_FAILED_DNE            = 1727;
sc_RPC_S_PROTOCOL_ERROR             = 1728;
sc_RPC_S_UNSUPPORTED_TRANS_SYN      = 1730;
sc_RPC_S_UNSUPPORTED_TYPE           = 1732;
sc_RPC_S_INVALID_TAG                = 1733;
sc_RPC_S_INVALID_BOUND              = 1734;
sc_RPC_S_NO_ENTRY_NAME              = 1735;
sc_RPC_S_INVALID_NAME_SYNTAX        = 1736;
sc_RPC_S_UNSUPPORTED_NAME_SYNTAX    = 1737;
sc_RPC_S_UUID_NO_ADDRESS            = 1739;
sc_RPC_S_DUPLICATE_ENDPOINT         = 1740;
sc_RPC_S_UNKNOWN_AUTHN_TYPE         = 1741;
sc_RPC_S_MAX_CALLS_TOO_SMALL        = 1742;
sc_RPC_S_STRING_TOO_LONG            = 1743;
sc_RPC_S_PROTSEQ_NOT_FOUND          = 1744;
sc_RPC_S_PROCNUM_OUT_OF_RANGE       = 1745;
sc_RPC_S_BINDING_HAS_NO_AUTH        = 1746;
sc_RPC_S_UNKNOWN_AUTHN_SERVICE      = 1747;
sc_RPC_S_UNKNOWN_AUTHN_LEVEL        = 1748;
sc_RPC_S_INVALID_AUTH_IDENTITY      = 1749;
sc_RPC_S_UNKNOWN_AUTHZ_SERVICE      = 1750;
sc_EPT_S_INVALID_ENTRY              = 1751;
sc_EPT_S_CANT_PERFORM_OP            = 1752;
sc_EPT_S_NOT_REGISTERED             = 1753;
sc_RPC_S_NOTHING_TO_EXPORT          = 1754;
sc_RPC_S_INCOMPLETE_NAME            = 1755;
sc_RPC_S_INVALID_VERS_OPTION        = 1756;
sc_RPC_S_NO_MORE_MEMBERS            = 1757;
sc_RPC_S_NOT_ALL_OBJS_UNEXPORTED    = 1758;
sc_RPC_S_INTERFACE_NOT_FOUND        = 1759;
sc_RPC_S_ENTRY_ALREADY_EXISTS       = 1760;
sc_RPC_S_ENTRY_NOT_FOUND            = 1761;
sc_RPC_S_NAME_SERVICE_UNAVAILABLE   = 1762;
sc_RPC_S_INVALID_NAF_ID             = 1763;
sc_RPC_S_CANNOT_SUPPORT             = 1764;
sc_RPC_S_NO_CONTEXT_AVAILABLE       = 1765;
sc_RPC_S_INTERNAL_ERROR             = 1766;
sc_RPC_S_ZERO_DIVIDE                = 1767;
sc_RPC_S_ADDRESS_ERROR              = 1768;
sc_RPC_S_FP_DIV_ZERO                = 1769;
sc_RPC_S_FP_UNDERFLOW               = 1770;
sc_RPC_S_FP_OVERFLOW                = 1771;
sc_RPC_X_NO_MORE_ENTRIES            = 1772;
sc_RPC_X_SS_CHAR_TRANS_OPEN_FAIL    = 1773;
sc_RPC_X_SS_CHAR_TRANS_SHORT_FILE   = 1774;
sc_RPC_X_SS_IN_NULL_CONTEXT         = 1775;
sc_RPC_X_SS_CONTEXT_DAMAGED         = 1777;
sc_RPC_X_SS_HANDLES_MISMATCH        = 1778;
sc_RPC_X_SS_CANNOT_GET_CALL_HANDLE  = 1779;
sc_RPC_X_NULL_REF_POINTER           = 1780;
sc_RPC_X_ENUM_VALUE_OUT_OF_RANGE    = 1781;
sc_RPC_X_BYTE_COUNT_TOO_SMALL       = 1782;
sc_RPC_X_BAD_STUB_DATA              = 1783;
sc_ERROR_INVALID_USER_BUFFER        = 1784;
sc_ERROR_UNRECOGNIZED_MEDIA         = 1785;
sc_ERROR_NO_TRUST_LSA_SECRET        = 1786;
sc_ERROR_NO_TRUST_SAM_ACCOUNT       = 1787;
sc_ERROR_TRUSTED_DOMAIN_FAILURE     = 1788;
sc_ERROR_TRUSTED_RELATIONSHIP_FAILURE = 1789;
sc_ERROR_TRUST_FAILURE              = 1790;
sc_RPC_S_CALL_IN_PROGRESS           = 1791;
sc_ERROR_NETLOGON_NOT_STARTED       = 1792;
sc_ERROR_ACCOUNT_EXPIRED            = 1793;
sc_ERROR_REDIRECTOR_HAS_OPEN_HANDLES = 1794;
sc_ERROR_PRINTER_DRIVER_ALREADY_INSTALLED = 1795;
sc_ERROR_UNKNOWN_PORT               = 1796;
sc_ERROR_UNKNOWN_PRINTER_DRIVER     = 1797;
sc_ERROR_UNKNOWN_PRINTPROCESSOR     = 1798;
sc_ERROR_INVALID_SEPARATOR_FILE     = 1799;
sc_ERROR_INVALID_PRIORITY           = 1800;
sc_ERROR_INVALID_PRINTER_NAME       = 1801;
sc_ERROR_PRINTER_ALREADY_EXISTS     = 1802;
sc_ERROR_INVALID_PRINTER_COMMAND    = 1803;
sc_ERROR_INVALID_DATATYPE           = 1804;
sc_ERROR_INVALID_ENVIRONMENT        = 1805;
sc_RPC_S_NO_MORE_BINDINGS           = 1806;
sc_ERROR_NOLOGON_INTERDOMAIN_TRUST_ACCOUNT = 1807;
sc_ERROR_NOLOGON_WORKSTATION_TRUST_ACCOUNT = 1808;
sc_ERROR_NOLOGON_SERVER_TRUST_ACCOUNT = 1809;
sc_ERROR_DOMAIN_TRUST_INCONSISTENT  = 1810;
sc_ERROR_SERVER_HAS_OPEN_HANDLES    = 1811;
sc_ERROR_RESOURCE_DATA_NOT_FOUND    = 1812;
sc_ERROR_RESOURCE_TYPE_NOT_FOUND    = 1813;
sc_ERROR_RESOURCE_NAME_NOT_FOUND    = 1814;
sc_ERROR_RESOURCE_LANG_NOT_FOUND    = 1815;
sc_ERROR_NOT_ENOUGH_QUOTA           = 1816;
sc_RPC_S_GROUP_MEMBER_NOT_FOUND     = 1898;
sc_EPT_S_CANT_CREATE                = 1899;
sc_RPC_S_INVALID_OBJECT             = 1900;
sc_ERROR_INVALID_TIME               = 1901;
sc_ERROR_INVALID_FORM_NAME          = 1902;
sc_ERROR_INVALID_FORM_SIZE          = 1903;
sc_ERROR_ALREADY_WAITING            = 1904;
sc_ERROR_PRINTER_DELETED            = 1905;
sc_ERROR_INVALID_PRINTER_STATE      = 1906;
sc_ERROR_NO_BROWSER_SERVERS_FOUND   = 6118;

{ window styles }

sc_WS_OVERLAPPED        = $00000000;
sc_WS_POPUP             = not $7fffffff {$80000000};
sc_WS_CHILD             = $40000000;
sc_WS_MINIMIZE          = $20000000;
sc_WS_VISIBLE           = $10000000;
sc_WS_DISABLED          = $08000000;
sc_WS_CLIPSIBLINGS      = $04000000;
sc_WS_CLIPCHILDREN      = $02000000;
sc_WS_MAXIMIZE          = $01000000;
sc_WS_CAPTION           = $00C00000;
sc_WS_BORDER            = $00800000;
sc_WS_DLGFRAME          = $00400000;
sc_WS_VSCROLL           = $00200000;
sc_WS_HSCROLL           = $00100000;
sc_WS_SYSMENU           = $00080000;
sc_WS_THICKFRAME        = $00040000;
sc_WS_GROUP             = $00020000;
sc_WS_TABSTOP           = $00010000;
sc_WS_MINIMIZEBOX       = $00020000;
sc_WS_MAXIMIZEBOX       = $00010000;
sc_WS_TILED             = sc_WS_OVERLAPPED;
sc_WS_ICONIC            = sc_WS_MINIMIZE;
sc_WS_SIZEBOX           = sc_WS_THICKFRAME;
sc_WS_OVERLAPPEDWINDOW  = sc_WS_OVERLAPPED+
                          sc_WS_CAPTION+
                          sc_WS_SYSMENU+
                          sc_WS_THICKFRAME+
                          sc_WS_MINIMIZEBOX+
                          sc_WS_MAXIMIZEBOX;
sc_WS_TILEDWINDOW       = sc_WS_OVERLAPPEDWINDOW;
sc_WS_POPUPWINDOW       = sc_WS_POPUP+
                          sc_WS_BORDER+
                          sc_WS_SYSMENU;
sc_WS_CHILDWINDOW       = sc_WS_CHILD;
sc_WS_EX_DLGMODALFRAME  = $00000001;
sc_WS_EX_NOPARENTNOTIFY = $00000004;
sc_WS_EX_TOPMOST        = $00000008;
sc_WS_EX_ACCEPTFILES    = $00000010;
sc_WS_EX_TRANSPARENT    = $00000020;

sc_CW_USEDEFAULT        = 1 {$80000000};

{ class styles }

sc_CS_VREDRAW         = $0001;
sc_CS_HREDRAW         = $0002;
sc_CS_KEYCVTWINDOW    = $0004;
sc_CS_DBLCLKS         = $0008;
sc_CS_OWNDC           = $0020;
sc_CS_CLASSDC         = $0040;
sc_CS_PARENTDC        = $0080;
sc_CS_NOKEYCVT        = $0100;
sc_CS_NOCLOSE         = $0200;
sc_CS_SAVEBITS        = $0800;
sc_CS_BYTEALIGNCLIENT = $1000;
sc_CS_BYTEALIGNWINDOW = $2000;
sc_CS_GLOBALCLASS     = $4000;

{ showwindow commands }

sc_SW_HIDE            = 0;
sc_SW_SHOWNORMAL      = 1;
sc_SW_NORMAL          = 1;
sc_SW_SHOWMINIMIZED   = 2;
sc_SW_SHOWMAXIMIZED   = 3;
sc_SW_MAXIMIZE        = 3;
sc_SW_SHOWNOACTIVATE  = 4;
sc_SW_SHOW            = 5;
sc_SW_MINIMIZE        = 6;
sc_SW_SHOWMINNOACTIVE = 7;
sc_SW_SHOWNA          = 8;
sc_SW_RESTORE         = 9;
sc_SW_SHOWDEFAULT     = 10;
sc_SW_MAX             = 10;

{ standard Icon IDs }

sc_IDI_APPLICATION   = 32512;
sc_IDI_HAND          = 32513;
sc_IDI_QUESTION      = 32514;
sc_IDI_EXCLAMATION   = 32515;
sc_IDI_ASTERISK      = 32516;

{ standard cursor ids }

sc_IDC_ARROW       = 32512;
sc_IDC_IBEAM       = 32513;
sc_IDC_WAIT        = 32514;
sc_IDC_CROSS       = 32515;
sc_IDC_UPARROW     = 32516;
sc_IDC_SIZE        = 32640;
sc_IDC_ICON        = 32641;
sc_IDC_SIZENWSE    = 32642;
sc_IDC_SIZENESW    = 32643;
sc_IDC_SIZEWE      = 32644;
sc_IDC_SIZENS      = 32645;
sc_IDC_SIZEALL     = 32646;
sc_IDC_NO          = 32648;
sc_IDC_APPSTARTING = 32650;

{ Stock Logical Objects }

sc_WHITE_BRUSH         = 0;
sc_LTGRAY_BRUSH        = 1;
sc_GRAY_BRUSH          = 2;
sc_DKGRAY_BRUSH        = 3;
sc_BLACK_BRUSH         = 4;
sc_NULL_BRUSH          = 5;
sc_HOLLOW_BRUSH        = sc_NULL_BRUSH;
sc_WHITE_PEN           = 6;
sc_BLACK_PEN           = 7;
sc_NULL_PEN            = 8;
sc_OEM_FIXED_FONT      = 10;
sc_ANSI_FIXED_FONT     = 11;
sc_ANSI_VAR_FONT       = 12;
sc_SYSTEM_FONT         = 13;
sc_DEVICE_DEFAULT_FONT = 14;
sc_DEFAULT_PALETTE     = 15;
sc_SYSTEM_FIXED_FONT   = 16;
sc_STOCK_LAST          = 16;

{ message box flags }

sc_MB_ABORTRETRYIGNORE = $2;
sc_MB_APPLMODAL = $0;
sc_MB_CANCELTRYCONTINUE = $6;
sc_MB_COMPOSITE = $2;
sc_MB_DEFAULT_DESKTOP_ONLY = $20000;
sc_MB_DEFBUTTON1 = $0;
sc_MB_DEFBUTTON2 = $100;
sc_MB_DEFBUTTON3 = $200;
sc_MB_DEFBUTTON4 = $300;
sc_MB_DEFMASK = $F00;
sc_MB_ERR_INVALID_CHARS = $8;
sc_MB_HELP = $4000;
sc_MB_ICONASTERISK = $40;
sc_MB_ICONERROR = $10;
sc_MB_ICONEXCLAMATION = $30;
sc_MB_ICONHAND = $10;
sc_MB_ICONINFORMATION = $40;
sc_MB_ICONMASK = $F0;
sc_MB_ICONQUESTION = $20;
sc_MB_ICONSTOP = $10;
sc_MB_ICONWARNING = $30;
sc_MB_MISCMASK = $C000;
sc_MB_MODEMASK = $3000;
sc_MB_NOFOCUS = $8000;
sc_MB_OK = $0;
sc_MB_OKCANCEL = $1;
sc_MB_PRECOMPOSED = $1;
sc_MB_RETRYCANCEL = $5;
sc_MB_RIGHT = $80000;
sc_MB_RTLREADING = $100000;
sc_MB_SERVICE_NOTIFICATION = $200000;
sc_MB_SERVICE_NOTIFICATION_NT3X = $40000;
sc_MB_SETFOREGROUND = $10000;
sc_MB_SYSTEMMODAL = $1000;
sc_MB_TASKMODAL = $2000;
sc_MB_TOPMOST = $40000;
sc_MB_TYPEMASK = $F;
sc_MB_USEGLYPHCHARS = $4;
sc_MB_USERICON = $80;
sc_MB_YESNO = $4;
sc_MB_YESNOCANCEL = $3;

{ Dialog Box Command IDs }

sc_IDOK                = 1;
sc_IDCANCEL            = 2;
sc_IDABORT             = 3;
sc_IDRETRY             = 4;
sc_IDIGNORE            = 5;
sc_IDYES               = 6;
sc_IDNO                = 7;

{ windows messages }

sc_WM_NULL                 = $0000;
sc_WM_CREATE               = $0001;
sc_WM_DESTROY              = $0002;
sc_WM_MOVE                 = $0003;
sc_WM_SIZE                 = $0005;
sc_WM_ACTIVATE             = $0006;
sc_WM_SETFOCUS             = $0007;
sc_WM_KILLFOCUS            = $0008;
sc_WM_ENABLE               = $000A;
sc_WM_SETREDRAW            = $000B;
sc_WM_SETTEXT              = $000C;
sc_WM_GETTEXT              = $000D;
sc_WM_GETTEXTLENGTH        = $000E;
sc_WM_PAINT                = $000F;
sc_WM_CLOSE                = $0010;
sc_WM_QUERYENDSESSION      = $0011;
sc_WM_QUIT                 = $0012;
sc_WM_QUERYOPEN            = $0013;
sc_WM_ERASEBKGND           = $0014;
sc_WM_SYSCOLORCHANGE       = $0015;
sc_WM_ENDSESSION           = $0016;
sc_WM_SHOWWINDOW           = $0018;
sc_WM_WININICHANGE         = $001A;
sc_WM_DEVMODECHANGE        = $001B;
sc_WM_ACTIVATEAPP          = $001C;
sc_WM_FONTCHANGE           = $001D;
sc_WM_TIMECHANGE           = $001E;
sc_WM_CANCELMODE           = $001F;
sc_WM_SETCURSOR            = $0020;
sc_WM_MOUSEACTIVATE        = $0021;
sc_WM_CHILDACTIVATE        = $0022;
sc_WM_QUEUESYNC            = $0023;
sc_WM_GETMINMAXINFO        = $0024;
sc_WM_PAINTICON            = $0026;
sc_WM_ICONERASEBKGND       = $0027;
sc_WM_NEXTDLGCTL           = $0028;
sc_WM_SPOOLERSTATUS        = $002A;
sc_WM_DRAWITEM             = $002B;
sc_WM_MEASUREITEM          = $002C;
sc_WM_DELETEITEM           = $002D;
sc_WM_VKEYTOITEM           = $002E;
sc_WM_CHARTOITEM           = $002F;
sc_WM_SETFONT              = $0030;
sc_WM_GETFONT              = $0031;
sc_WM_SETHOTKEY            = $0032;
sc_WM_GETHOTKEY            = $0033;
sc_WM_QUERYDRAGICON        = $0037;
sc_WM_COMPAREITEM          = $0039;
sc_WM_COMPACTING           = $0041;
sc_WM_OTHERWINDOWCREATED   = $0042; { no longer suported }
sc_WM_OTHERWINDOWDESTROYED = $0043; { no longer suported }
sc_WM_COMMNOTIFY           = $0044; { no longer suported }
sc_WM_HOTKEYEVENT          = $0045;
sc_WM_WINDOWPOSCHANGING    = $0046;
sc_WM_WINDOWPOSCHANGED     = $0047;
sc_WM_POWER                = $0048;
sc_WM_COPYDATA             = $004A;
sc_WM_CANCELJOURNAL        = $004B;
sc_WM_NOTIFY               = $004E;
sc_WM_NCCREATE             = $0081;
sc_WM_NCDESTROY            = $0082;
sc_WM_NCCALCSIZE           = $0083;
sc_WM_NCHITTEST            = $0084;
sc_WM_NCPAINT              = $0085;
sc_WM_NCACTIVATE           = $0086;
sc_WM_GETDLGCODE           = $0087;
sc_WM_NCMOUSEMOVE          = $00A0;
sc_WM_NCLBUTTONDOWN        = $00A1;
sc_WM_NCLBUTTONUP          = $00A2;
sc_WM_NCLBUTTONDBLCLK      = $00A3;
sc_WM_NCRBUTTONDOWN        = $00A4;
sc_WM_NCRBUTTONUP          = $00A5;
sc_WM_NCRBUTTONDBLCLK      = $00A6;
sc_WM_NCMBUTTONDOWN        = $00A7;
sc_WM_NCMBUTTONUP          = $00A8;
sc_WM_NCMBUTTONDBLCLK      = $00A9;
sc_WM_KEYFIRST             = $0100;
sc_WM_KEYDOWN              = $0100;
sc_WM_KEYUP                = $0101;
sc_WM_CHAR                 = $0102;
sc_WM_DEADCHAR             = $0103;
sc_WM_SYSKEYDOWN           = $0104;
sc_WM_SYSKEYUP             = $0105;
sc_WM_SYSCHAR              = $0106;
sc_WM_SYSDEADCHAR          = $0107;
sc_WM_KEYLAST              = $0108;
sc_WM_INITDIALOG           = $0110;
sc_WM_COMMAND              = $0111;
sc_WM_SYSCOMMAND           = $0112;
sc_WM_TIMER                = $0113;
sc_WM_HSCROLL              = $0114;
sc_WM_VSCROLL              = $0115;
sc_WM_INITMENU             = $0116;
sc_WM_INITMENUPOPUP        = $0117;
sc_WM_MENUSELECT           = $011F;
sc_WM_MENUCHAR             = $0120;
sc_WM_ENTERIDLE            = $0121;
sc_WM_MENUCOMMAND          = $0126;
sc_WM_CTLCOLORMSGBOX       = $0132;
sc_WM_CTLCOLOREDIT         = $0133;
sc_WM_CTLCOLORLISTBOX      = $0134;
sc_WM_CTLCOLORBTN          = $0135;
sc_WM_CTLCOLORDLG          = $0136;
sc_WM_CTLCOLORSCROLLBAR    = $0137;
sc_WM_CTLCOLORSTATIC       = $0138;
sc_WM_MOUSEFIRST           = $0200;
sc_WM_MOUSEMOVE            = $0200;
sc_WM_LBUTTONDOWN          = $0201;
sc_WM_LBUTTONUP            = $0202;
sc_WM_LBUTTONDBLCLK        = $0203;
sc_WM_RBUTTONDOWN          = $0204;
sc_WM_RBUTTONUP            = $0205;
sc_WM_RBUTTONDBLCLK        = $0206;
sc_WM_MBUTTONDOWN          = $0207;
sc_WM_MBUTTONUP            = $0208;
sc_WM_MBUTTONDBLCLK        = $0209;
sc_WM_MOUSELAST            = $0209;
sc_WM_PARENTNOTIFY         = $0210;
sc_WM_ENTERMENULOOP        = $0211;
sc_WM_EXITMENULOOP         = $0212;
sc_WM_MDICREATE            = $0220;
sc_WM_MDIDESTROY           = $0221;
sc_WM_MDIACTIVATE          = $0222;
sc_WM_MDIRESTORE           = $0223;
sc_WM_MDINEXT              = $0224;
sc_WM_MDIMAXIMIZE          = $0225;
sc_WM_MDITILE              = $0226;
sc_WM_MDICASCADE           = $0227;
sc_WM_MDIICONARRANGE       = $0228;
sc_WM_MDIGETACTIVE         = $0229;
sc_WM_MDISETMENU           = $0230;
sc_WM_DROPFILES            = $0233;
sc_WM_MDIREFRESHMENU       = $0234;
sc_WM_CUT                  = $0300;
sc_WM_COPY                 = $0301;
sc_WM_PASTE                = $0302;
sc_WM_CLEAR                = $0303;
sc_WM_UNDO                 = $0304;
sc_WM_RENDERFORMAT         = $0305;
sc_WM_RENDERALLFORMATS     = $0306;
sc_WM_DESTROYCLIPBOARD     = $0307;
sc_WM_DRAWCLIPBOARD        = $0308;
sc_WM_PAINTCLIPBOARD       = $0309;
sc_WM_VSCROLLCLIPBOARD     = $030A;
sc_WM_SIZECLIPBOARD        = $030B;
sc_WM_ASKCBFORMATNAME      = $030C;
sc_WM_CHANGECBCHAIN        = $030D;
sc_WM_HSCROLLCLIPBOARD     = $030E;
sc_WM_QUERYNEWPALETTE      = $030F;
sc_WM_PALETTEISCHANGING    = $0310;
sc_WM_PALETTECHANGED       = $0311;
sc_WM_HOTKEY               = $0312;
sc_WM_PENWINFIRST          = $0380;
sc_WM_PENWINLAST           = $038F;

{ NOTE: All Message Numbers below 0x0400 are RESERVED. 

  Private Window Messages Start Here:
}

sc_WM_USER                 = $0400;

{ PeekMessage() Options }

sc_PM_NOREMOVE = $0000;
sc_PM_REMOVE   = $0001;
sc_PM_NOYIELD  = $0002;

{ DrawText() Format Flags }

sc_DT_TOP              = $0000;
sc_DT_LEFT             = $0000;
sc_DT_CENTER           = $0001;
sc_DT_RIGHT            = $0002;
sc_DT_VCENTER          = $0004;
sc_DT_BOTTOM           = $0008;
sc_DT_WORDBREAK        = $0010;
sc_DT_SINGLELINE       = $0020;
sc_DT_EXPANDTABS       = $0040;
sc_DT_TABSTOP          = $0080;
sc_DT_NOCLIP           = $0100;
sc_DT_EXTERNALLEADING  = $0200;
sc_DT_CALCRECT         = $0400;
sc_DT_NOPREFIX         = $0800;
sc_DT_INTERNAL         = $1000;

{ Background Modes }

sc_TRANSPARENT = 1;
sc_OPAQUE      = 2;
sc_BKMODE_LAST = 2;
                       
{ joystick ID constants }

sc_JOYSTICKID1 = 0;
sc_JOYSTICKID2 = 1;

{ general multimedia errors }

sc_MMSYSERR_BASE         = 0;

sc_MMSYSERR_NOERROR      = 0;                     { no error }
sc_MMSYSERR_ERROR        = sc_MMSYSERR_BASE + 1;  { unspecified error }
sc_MMSYSERR_BADDEVICEID  = sc_MMSYSERR_BASE + 2;  { device ID out of range }
sc_MMSYSERR_NOTENABLED   = sc_MMSYSERR_BASE + 3;  { driver failed enable }
sc_MMSYSERR_ALLOCATED    = sc_MMSYSERR_BASE + 4;  { device already allocated }
sc_MMSYSERR_INVALHANDLE  = sc_MMSYSERR_BASE + 5;  { device handle is invalid }
sc_MMSYSERR_NODRIVER     = sc_MMSYSERR_BASE + 6;  { no device driver present }
sc_MMSYSERR_NOMEM        = sc_MMSYSERR_BASE + 7;  { memory allocation error }
sc_MMSYSERR_NOTSUPPORTED = sc_MMSYSERR_BASE + 8;  { function isn't supported }
sc_MMSYSERR_BADERRNUM    = sc_MMSYSERR_BASE + 9;  { error value out of range }
sc_MMSYSERR_INVALFLAG    = sc_MMSYSERR_BASE + 10; { invalid flag passed }
sc_MMSYSERR_INVALPARAM   = sc_MMSYSERR_BASE + 11; { invalid parameter passed }
sc_MMSYSERR_HANDLEBUSY   = sc_MMSYSERR_BASE + 12; { handle being used
                                                    simultaneously on another
                                                    thread (eg callback) }
sc_MMSYSERR_INVALIDALIAS = sc_MMSYSERR_BASE + 13; { Specified alias not found in WIN.INI }
sc_MMSYSERR_LASTERROR    = sc_MMSYSERR_BASE + 13; { last error in range }

{ joystick errors }

sc_JOYERR_BASE      = 160;

sc_JOYERR_NOERROR   = 0;                { no error }
sc_JOYERR_PARMS     = sc_JOYERR_BASE+5; { bad parameters }
sc_JOYERR_NOCANDO   = sc_JOYERR_BASE+6; { request not completed }
sc_JOYERR_UNPLUGGED = sc_JOYERR_BASE+7; { joystick is unplugged }

{ joystick messages }

sc_MM_JOY1MOVE       = $3A0;
sc_MM_JOY2MOVE       = $3A1;
sc_MM_JOY1ZMOVE      = $3A2;
sc_MM_JOY2ZMOVE      = $3A3;
sc_MM_JOY1BUTTONDOWN = $3B5;
sc_MM_JOY2BUTTONDOWN = $3B6;
sc_MM_JOY1BUTTONUP   = $3B7;
sc_MM_JOY2BUTTONUP   = $3B8;

{ joystick button flags }

sc_JOY_BUTTON1    = $0001;
sc_JOY_BUTTON2    = $0002;
sc_JOY_BUTTON3    = $0004;
sc_JOY_BUTTON4    = $0008;
sc_JOY_BUTTON1CHG = $0100;
sc_JOY_BUTTON2CHG = $0200;
sc_JOY_BUTTON3CHG = $0400;
sc_JOY_BUTTON4CHG = $0800;

{ setwindowpos flags }

sc_SWP_NOSIZE        = $0001;
sc_SWP_NOMOVE        = $0002;
sc_SWP_NOZORDER      = $0004;
sc_SWP_NOREDRAW      = $0008;
sc_SWP_NOACTIVATE    = $0010;
sc_SWP_FRAMECHANGED  = $0020; { The frame changed: send WM_NCCALCSIZE }
sc_SWP_SHOWWINDOW    = $0040;
sc_SWP_HIDEWINDOW    = $0080;
sc_SWP_NOCOPYBITS    = $0100;
sc_SWP_NOOWNERZORDER = $0200; { Don't do owner Z ordering }

sc_HWND_BOTTOM = $1;
sc_HWND_BROADCAST = $FFFF;
sc_HWND_DESKTOP = $0;
sc_HWND_MESSAGE = 1 {$FFFFFFFD};
sc_HWND_NOTOPMOST = 1 {$FFFFFFFE};
sc_HWND_TOP = $0;
sc_HWND_TOPMOST = 1 {$FFFFFFFF};

{ ShowWindow() Commands }

sc_STARTF_USESHOWWINDOW    = $00000001;
sc_STARTF_USESIZE          = $00000002;
sc_STARTF_USEPOSITION      = $00000004;
sc_STARTF_USECOUNTCHARS    = $00000008;
sc_STARTF_USEFILLATTRIBUTE = $00000010;
sc_STARTF_RUNFULLSCREEN    = $00000020;  { ignored for non-x86 platforms }
sc_STARTF_FORCEONFEEDBACK  = $00000040;
sc_STARTF_FORCEOFFFEEDBACK = $00000080;
sc_STARTF_USESTDHANDLES    = $00000100;

{ wait return codes }

sc_WAIT_OBJECT_0      = $0;
sc_WAIT_ABANDONED_0   = $128;
sc_WAIT_TIMEOUT       = $102;
sc_WAIT_IO_COMPLETION = $C0;
sc_WAIT_ABANDONED     = $128;
sc_WAIT_FAILED        = -1 {$FFFFFFFF};

sc_LF_FACESIZE        = 32;

sc_LF_FULLFACESIZE    = 64;

{ Font Weights }

sc_FW_DONTCARE        = 0;
sc_FW_THIN            = 100;
sc_FW_EXTRALIGHT      = 200;
sc_FW_LIGHT           = 300;
sc_FW_NORMAL          = 400;
sc_FW_MEDIUM          = 500;
sc_FW_SEMIBOLD        = 600;
sc_FW_BOLD            = 700;
sc_FW_EXTRABOLD       = 800;
sc_FW_HEAVY           = 900;

sc_FW_ULTRALIGHT      = sc_FW_EXTRALIGHT;
sc_FW_REGULAR         = sc_FW_NORMAL;
sc_FW_DEMIBOLD        = sc_FW_SEMIBOLD;
sc_FW_ULTRABOLD       = sc_FW_EXTRABOLD;
sc_FW_BLACK           = sc_FW_HEAVY;

sc_ANSI_CHARSET        = 0;
sc_DEFAULT_CHARSET     = 1;
sc_SYMBOL_CHARSET      = 2;
sc_SHIFTJIS_CHARSET    = 128;
sc_HANGEUL_CHARSET     = 129;
sc_HANGUL_CHARSET      = 129;
sc_GB2312_CHARSET      = 134;
sc_CHINESEBIG5_CHARSET = 136;
sc_OEM_CHARSET         = 255;
sc_JOHAB_CHARSET       = 130;
sc_HEBREW_CHARSET      = 177;
sc_ARABIC_CHARSET      = 178;
sc_GREEK_CHARSET       = 161;
sc_TURKISH_CHARSET     = 162;
sc_VIETNAMESE_CHARSET  = 163;
sc_THAI_CHARSET        = 222;
sc_EASTEUROPE_CHARSET  = 238;
sc_RUSSIAN_CHARSET     = 204;

sc_MAC_CHARSET         = 77;
sc_BALTIC_CHARSET      = 186;

sc_OUT_DEFAULT_PRECIS        =  0;
sc_OUT_STRING_PRECIS         =  1;
sc_OUT_CHARACTER_PRECIS      =  2;
sc_OUT_STROKE_PRECIS         =  3;
sc_OUT_TT_PRECIS             =  4;
sc_OUT_DEVICE_PRECIS         =  5;
sc_OUT_RASTER_PRECIS         =  6;
sc_OUT_TT_ONLY_PRECIS        =  7;
sc_OUT_OUTLINE_PRECIS        =  8;
sc_OUT_SCREEN_OUTLINE_PRECIS =  9;
sc_OUT_PS_ONLY_PRECIS        = 10;

sc_CLIP_DEFAULT_PRECIS    = 0;
sc_CLIP_CHARACTER_PRECIS  = 1;
sc_CLIP_STROKE_PRECIS     = 2;
sc_CLIP_MASK              = $f;
sc_CLIP_LH_ANGLES         = 1*16;
sc_CLIP_TT_ALWAYS         = 2*16;
sc_CLIP_EMBEDDED          = 8*16;

sc_DEFAULT_QUALITY           = 0;
sc_DRAFT_QUALITY             = 1;
sc_PROOF_QUALITY             = 2;
sc_NONANTIALIASED_QUALITY    = 3;
sc_ANTIALIASED_QUALITY       = 4;
sc_CLEARTYPE_QUALITY         = 5;
sc_CLEARTYPE_NATURAL_QUALITY = 6;

{ EnumFonts Masks }

sc_RASTER_FONTTYPE    = $0001;
sc_DEVICE_FONTTYPE    = $002;
sc_TRUETYPE_FONTTYPE  = $004;

{ Font Families }

sc_FF_DONTCARE        = 0*16;
sc_FF_ROMAN           = 1*16;
sc_FF_SWISS           = 2*16;
sc_FF_MODERN          = 3*16;
sc_FF_SCRIPT          = 4*16;
sc_FF_DECORATIVE      = 5*16;

sc_DEFAULT_PITCH      = 0;
sc_FIXED_PITCH        = 1;
sc_VARIABLE_PITCH     = 2;

{ Device Parameters for GetDeviceCaps() }

sc_DRIVERVERSION   =  0;     
sc_TECHNOLOGY      =  2;     
sc_HORZSIZE        =  4;     
sc_VERTSIZE        =  6;     
sc_HORZRES         =  8;     
sc_VERTRES         =  10;    
sc_BITSPIXEL       =  12;    
sc_PLANES          =  14;    
sc_NUMBRUSHES      =  16;    
sc_NUMPENS         =  18;    
sc_NUMMARKERS      =  20;    
sc_NUMFONTS        =  22;    
sc_NUMCOLORS       =  24;    
sc_PDEVICESIZE     =  26;    
sc_CURVECAPS       =  28;    
sc_LINECAPS        =  30;    
sc_POLYGONALCAPS   =  32;    
sc_TEXTCAPS        =  34;    
sc_CLIPCAPS        =  36;    
sc_RASTERCAPS      =  38;    
sc_ASPECTX         =  40;    
sc_ASPECTY         =  42;    
sc_ASPECTXY        =  44;    
sc_LOGPIXELSX      =  88;    
sc_LOGPIXELSY      =  90;    
sc_SIZEPALETTE     = 104;    
sc_NUMRESERVED     = 106;    
sc_COLORRES        = 108;    
sc_PHYSICALWIDTH   = 110; 
sc_PHYSICALHEIGHT  = 111; 
sc_PHYSICALOFFSETX = 112; 
sc_PHYSICALOFFSETY = 113; 
sc_SCALINGFACTORX  = 114; 
sc_SCALINGFACTORY  = 115; 
sc_VREFRESH        = 116; 
sc_DESKTOPVERTRES  = 117; 
sc_DESKTOPHORZRES  = 118; 
sc_BLTALIGNMENT    = 119; 
sc_SHADEBLENDCAPS  = 120; 
sc_COLORMGMTCAPS   = 121; 

sc_IMAGE_BITMAP        = 0;
sc_IMAGE_ICON          = 1;
sc_IMAGE_CURSOR        = 2;
sc_IMAGE_ENHMETAFILE   = 3;
                       
sc_LR_DEFAULTCOLOR     = $0000;
sc_LR_MONOCHROME       = $0001;
sc_LR_COLOR            = $0002;
sc_LR_COPYRETURNORG    = $0004;
sc_LR_COPYDELETEORG    = $0008;
sc_LR_LOADFROMFILE     = $0010;
sc_LR_LOADTRANSPARENT  = $0020;
sc_LR_DEFAULTSIZE      = $0040;
sc_LR_VGACOLOR         = $0080;
sc_LR_LOADMAP3DCOLORS  = $1000;
sc_LR_CREATEDIBSECTION = $2000;
sc_LR_COPYFROMRESOURCE = $4000;
sc_LR_SHARED           = $8000;

sc_BLACKONWHITE        = 1;
sc_WHITEONBLACK        = 2;
sc_COLORONCOLOR        = 3;
sc_HALFTONE            = 4;
sc_MAXSTRETCHBLTMODE   = 4;
sc_STRETCH_ANDSCANS    = sc_BLACKONWHITE;
sc_STRETCH_ORSCANS     = sc_WHITEONBLACK;
sc_STRETCH_DELETESCANS = sc_COLORONCOLOR;
sc_STRETCH_HALFTONE    = sc_HALFTONE;

{ Mapping Modes }

sc_MM_TEXT             = 1;
sc_MM_LOMETRIC         = 2;
sc_MM_HIMETRIC         = 3;
sc_MM_LOENGLISH        = 4;
sc_MM_HIENGLISH        = 5;
sc_MM_TWIPS            = 6;
sc_MM_ISOTROPIC        = 7;
sc_MM_ANISOTROPIC      = 8;
sc_MM_MIN              = sc_MM_TEXT;
sc_MM_MAX              = sc_MM_ANISOTROPIC;
sc_MM_MAX_FIXEDSCALE   = sc_MM_TWIPS;

sc_GCP_DBCS            = $0001;
sc_GCP_REORDER         = $0002;
sc_GCP_USEKERNING      = $0008;
sc_GCP_GLYPHSHAPE      = $0010;
sc_GCP_LIGATE          = $0020;
sc_GCP_DIACRITIC       = $0100;
sc_GCP_KASHIDA         = $0400;
sc_GCP_ERROR           = $8000;
sc_GCP_JUSTIFY         = $00010000;
sc_GCP_CLASSIN         = $00080000;
sc_GCP_MAXEXTENT       = $00100000;
sc_GCP_JUSTIFYIN       = $00200000;
sc_GCP_DISPLAYZWG      = $00400000;
sc_GCP_SYMSWAPOFF      = $00800000;
sc_GCP_NUMERICOVERRIDE = $01000000;
sc_GCP_NEUTRALOVERRIDE = $02000000;
sc_GCP_NUMERICSLATIN   = $04000000;
sc_GCP_NUMERICSLOCAL   = $08000000;

sc_MF_APPEND = $100;
sc_MF_BITMAP = $4;
sc_MF_BYCOMMAND = $0;
sc_MF_BYPOSITION = $400;
sc_MF_CALLBACKS = $8000000;
sc_MF_CHANGE = $80;
sc_MF_CHECKED = $8;
sc_MF_CONV = $40000000;
sc_MF_DEFAULT = $1000;
sc_MF_DELETE = $200;
sc_MF_DISABLED = $2;
sc_MF_ENABLED = $0;
sc_MF_END = $80;
sc_MF_ERRORS = $10000000;
sc_MF_GRAYED = $1;
sc_MF_HELP = $4000;
sc_MF_HILITE = $80;
sc_MF_HSZ_INFO = $1000000;
sc_MF_INSERT = $0;
sc_MF_LINKS = $20000000;
sc_MF_MASK = 0 {$FF000000};
sc_MF_MENUBARBREAK = $20;
sc_MF_MENUBREAK = $40;
sc_MF_MOUSESELECT = $8000;
sc_MF_OWNERDRAW = $100;
sc_MF_POPUP = $10;
sc_MF_POSTMSGS = $4000000;
sc_MF_REMOVE = $1000;
sc_MF_RIGHTJUSTIFY = $4000;
sc_MF_SENDMSGS = $2000000;
sc_MF_SEPARATOR = $800;
sc_MF_STRING = $0;
sc_MF_SYSMENU = $2000;
sc_MF_UNCHECKED = $0;
sc_MF_UNHILITE = $0;
sc_MF_USECHECKBITMAPS = $200;

sc_BS_3STATE = $5;
sc_BS_AUTO3STATE = $6;
sc_BS_AUTOCHECKBOX = $3;
sc_BS_AUTORADIOBUTTON = $9;
sc_BS_BITMAP = $80;
sc_BS_BOTTOM = $800;
sc_BS_CENTER = $300;
sc_BS_CHECKBOX = $2;
sc_BS_DEFPUSHBUTTON = $1;
sc_BS_FLAT = $8000;
sc_BS_GROUPBOX = $7;
sc_BS_ICON = $40;
sc_BS_LEFT = $100;
sc_BS_LEFTTEXT = $20;
sc_BS_MONOPATTERN = $9;
sc_BS_MULTILINE = $2000;
sc_BS_NOTIFY = $4000;
sc_BS_OWNERDRAW = $B;
sc_BS_PUSHBOX = $A;
sc_BS_PUSHBUTTON = $0;
sc_BS_PUSHLIKE = $1000;
sc_BS_RADIOBUTTON = $4;
sc_BS_RIGHT = $200;
sc_BS_RIGHTBUTTON = $20;
sc_BS_TEXT = $0;
sc_BS_TOP = $400;
sc_BS_TYPEMASK = $F;
sc_BS_USERBUTTON = $8;
sc_BS_VCENTER = $C00;

sc_BM_CLICK = $F5;
sc_BM_GETCHECK = $F0;
sc_BM_GETIMAGE = $F6;
sc_BM_GETSTATE = $F2;
sc_BM_SETCHECK = $F1;
sc_BM_SETIMAGE = $F7;
sc_BM_SETSTATE = $F3;
sc_BM_SETSTYLE = $F4;
sc_BN_CLICKED = $0;
sc_BN_DBLCLK = $5;
sc_BN_DISABLE = $4;
sc_BN_DOUBLECLICKED = $5;
sc_BN_HILITE = $2;
sc_BN_KILLFOCUS = $7;
sc_BN_PAINT = $1;
sc_BN_PUSHED = $2;
sc_BN_SETFOCUS = $6;
sc_BN_UNHILITE = $3;
sc_BN_UNPUSHED = $3;

sc_SS_BITMAP = $E;
sc_SS_BLACKFRAME = $7;
sc_SS_BLACKRECT = $4;
sc_SS_CENTER = $1;
sc_SS_CENTERIMAGE = $200;
sc_SS_EDITCONTROL = $2000;
sc_SS_ELLIPSISMASK = $C000;
sc_SS_ENDELLIPSIS = $4000;
sc_SS_ENHMETAFILE = $F;
sc_SS_ETCHEDFRAME = $12;
sc_SS_ETCHEDHORZ = $10;
sc_SS_ETCHEDVERT = $11;
sc_SS_GRAYFRAME = $8;
sc_SS_GRAYRECT = $5;
sc_SS_ICON = $3;
sc_SS_LEFT = $0;
sc_SS_LEFTNOWORDWRAP = $C;
sc_SS_NOPREFIX = $80;
sc_SS_NOTIFY = $100;
sc_SS_OWNERDRAW = $D;
sc_SS_PATHELLIPSIS = $8000;
sc_SS_REALSIZECONTROL = $40;
sc_SS_REALSIZEIMAGE = $800;
sc_SS_RIGHT = $2;
sc_SS_RIGHTJUST = $400;
sc_SS_SIMPLE = $B;
sc_SS_SUNKEN = $1000;
sc_SS_TYPEMASK = $1F;
sc_SS_USERITEM = $A;
sc_SS_WHITEFRAME = $9;
sc_SS_WHITERECT = $6;
sc_SS_WORDELLIPSIS = $C000;

sc_SBS_BOTTOMALIGN = $4;
sc_SBS_HORZ = $0;
sc_SBS_LEFTALIGN = $2;
sc_SBS_RIGHTALIGN = $4;
sc_SBS_SIZEBOX = $8;
sc_SBS_SIZEBOXBOTTOMRIGHTALIGN = $4;
sc_SBS_SIZEBOXTOPLEFTALIGN = $2;
sc_SBS_SIZEGRIP = $10;
sc_SBS_TOPALIGN = $2;
sc_SBS_VERT = $1;

sc_SB_BOTH = $3;
sc_SB_BOTTOM = $7;
sc_SB_CONST_ALPHA = $1;
sc_SB_CTL = $2;
sc_SB_ENDSCROLL = $8;
sc_SB_GRAD_RECT = $10;
sc_SB_GRAD_TRI = $20;
sc_SB_HORZ = $0;
sc_SB_LEFT = $6;
sc_SB_LINEDOWN = $1;
sc_SB_LINELEFT = $0;
sc_SB_LINERIGHT = $1;
sc_SB_LINEUP = $0;
sc_SB_NONE = $0;
sc_SB_PAGEDOWN = $3;
sc_SB_PAGELEFT = $2;
sc_SB_PAGERIGHT = $3;
sc_SB_PAGEUP = $2;
sc_SB_PIXEL_ALPHA = $2;
sc_SB_PREMULT_ALPHA = $4;
sc_SB_RIGHT = $7;
sc_SB_THUMBPOSITION = $4;
sc_SB_THUMBTRACK = $5;
sc_SB_TOP = $6;
sc_SB_VERT = $1;

sc_THREAD_PRIORITY_ABOVE_NORMAL = $1;
sc_THREAD_PRIORITY_BELOW_NORMAL = 1{$FFFFFFFF};
sc_THREAD_PRIORITY_ERROR_RETURN = $7FFFFFFF;
sc_THREAD_PRIORITY_HIGHEST = $2;
sc_THREAD_PRIORITY_IDLE = 1{$FFFFFFF1};
sc_THREAD_PRIORITY_LOWEST = 1{$FFFFFFFE};
sc_THREAD_PRIORITY_NORMAL = $0;
sc_THREAD_PRIORITY_TIME_CRITICAL = $F;

sc_SIF_ALL = $17;
sc_SIF_DISABLENOSCROLL = $8;
sc_SIF_PAGE = $2;
sc_SIF_POS = $4;
sc_SIF_RANGE = $1;
sc_SIF_TRACKPOS = $10;

sc_ES_AUTOHSCROLL = $80;
sc_ES_AUTOVSCROLL = $40;
sc_ES_CENTER = $1;
sc_ES_CONTINUOUS = 1{$80000000};
sc_ES_DISPLAY_REQUIRED = $2;
sc_ES_LEFT = $0;
sc_ES_LOWERCASE = $10;
sc_ES_MULTILINE = $4;
sc_ES_NOHIDESEL = $100;
sc_ES_NUMBER = $2000;
sc_ES_OEMCONVERT = $400;
sc_ES_PASSWORD = $20;
sc_ES_READONLY = $800;
sc_ES_RIGHT = $2;
sc_ES_SYSTEM_REQUIRED = $1;
sc_ES_UPPERCASE = $8;
sc_ES_USER_PRESENT = $4;
sc_ES_WANTRETURN = $1000;

sc_EN_ALIGN_LTR_EC = $700;
sc_EN_ALIGN_RTL_EC = $701;
sc_EN_CHANGE = $300;
sc_EN_ERRSPACE = $500;
sc_EN_HSCROLL = $601;
sc_EN_KILLFOCUS = $200;
sc_EN_MAXTEXT = $501;
sc_EN_SETFOCUS = $100;
sc_EN_UPDATE = $400;
sc_EN_VSCROLL = $602;

sc_PBM_SETRANGE    = sc_WM_USER+1;
sc_PBM_SETPOS      = sc_WM_USER+2;
sc_PBM_DELTAPOS    = sc_WM_USER+3;
sc_PBM_SETSTEP     = sc_WM_USER+4;
sc_PBM_STEPIT      = sc_WM_USER+5;
sc_PBM_SETRANGE32  = sc_WM_USER+6;
sc_PBM_GETRANGE    = sc_WM_USER+7;
sc_PBM_GETPOS      = sc_WM_USER+8;
sc_PBM_SETBARCOLOR = sc_WM_USER+9;

sc_LBS_COMBOBOX = $8000;
sc_LBS_DISABLENOSCROLL = $1000;
sc_LBS_EXTENDEDSEL = $800;
sc_LBS_HASSTRINGS = $40;
sc_LBS_MULTICOLUMN = $200;
sc_LBS_MULTIPLESEL = $8;
sc_LBS_NODATA = $2000;
sc_LBS_NOINTEGRALHEIGHT = $100;
sc_LBS_NOREDRAW = $4;
sc_LBS_NOSEL = $4000;
sc_LBS_NOTIFY = $1;
sc_LBS_OWNERDRAWFIXED = $10;
sc_LBS_OWNERDRAWVARIABLE = $20;
sc_LBS_SORT = $2;
sc_LBS_STANDARD = $A00003;
sc_LBS_USETABSTOPS = $80;
sc_LBS_WANTKEYBOARDINPUT = $400;

sc_LB_ADDFILE = $196;
sc_LB_ADDSTRING = $180;
sc_LB_CTLCODE = $0;
sc_LB_DELETESTRING = $182;
sc_LB_DIR = $18D;
sc_LB_ERR = 1 {$FFFFFFFF};
sc_LB_ERRSPACE = 1 {$FFFFFFFE};
sc_LB_FINDSTRING = $18F;
sc_LB_FINDSTRINGEXACT = $1A2;
sc_LB_GETANCHORINDEX = $19D;
sc_LB_GETCARETINDEX = $19F;
sc_LB_GETCOUNT = $18B;
sc_LB_GETCURSEL = $188;
sc_LB_GETHORIZONTALEXTENT = $193;
sc_LB_GETITEMDATA = $199;
sc_LB_GETITEMHEIGHT = $1A1;
sc_LB_GETITEMRECT = $198;
sc_LB_GETLISTBOXINFO = $1B2;
sc_LB_GETLOCALE = $1A6;
sc_LB_GETSEL = $187;
sc_LB_GETSELCOUNT = $190;
sc_LB_GETSELITEMS = $191;
sc_LB_GETTEXT = $189;
sc_LB_GETTEXTLEN = $18A;
sc_LB_GETTOPINDEX = $18E;
sc_LB_INITSTORAGE = $1A8;
sc_LB_INSERTSTRING = $181;
sc_LB_ITEMFROMPOINT = $1A9;
sc_LB_MSGMAX = $1B3;
sc_LB_OKAY = $0;
sc_LB_RESETCONTENT = $184;
sc_LB_SELECTSTRING = $18C;
sc_LB_SELITEMRANGE = $19B;
sc_LB_SELITEMRANGEEX = $183;
sc_LB_SETANCHORINDEX = $19C;
sc_LB_SETCARETINDEX = $19E;
sc_LB_SETCOLUMNWIDTH = $195;
sc_LB_SETCOUNT = $1A7;
sc_LB_SETCURSEL = $186;
sc_LB_SETHORIZONTALEXTENT = $194;
sc_LB_SETITEMDATA = $19A;
sc_LB_SETITEMHEIGHT = $1A0;
sc_LB_SETLOCALE = $1A5;
sc_LB_SETSEL = $185;
sc_LB_SETTABSTOPS = $192;
sc_LB_SETTOPINDEX = $197;

sc_LBN_DBLCLK = $2;
sc_LBN_ERRSPACE = 1 {$FFFFFFFE};
sc_LBN_KILLFOCUS = $5;
sc_LBN_SELCANCEL = $3;
sc_LBN_SELCHANGE = $1;
sc_LBN_SETFOCUS = $4;

sc_CBN_CLOSEUP = $8;
sc_CBN_DBLCLK = $2;
sc_CBN_DROPDOWN = $7;
sc_CBN_EDITCHANGE = $5;
sc_CBN_EDITUPDATE = $6;
sc_CBN_ERRSPACE = 1{$FFFFFFFF};
sc_CBN_KILLFOCUS = $4;
sc_CBN_SELCHANGE = $1;
sc_CBN_SELENDCANCEL = $A;
sc_CBN_SELENDOK = $9;
sc_CBN_SETFOCUS = $3;

sc_CBS_AUTOHSCROLL = $40;
sc_CBS_DISABLENOSCROLL = $800;
sc_CBS_DROPDOWN = $2;
sc_CBS_DROPDOWNLIST = $3;
sc_CBS_HASSTRINGS = $200;
sc_CBS_LOWERCASE = $4000;
sc_CBS_NOINTEGRALHEIGHT = $400;
sc_CBS_OEMCONVERT = $80;
sc_CBS_OWNERDRAWFIXED = $10;
sc_CBS_OWNERDRAWVARIABLE = $20;
sc_CBS_SIMPLE = $1;
sc_CBS_SORT = $100;
sc_CBS_UPPERCASE = $2000;

sc_CB_ADDSTRING = $143;
sc_CB_DELETESTRING = $144;
sc_CB_DIR = $145;
sc_CB_ERR = 1{$FFFFFFFF};
sc_CB_ERRSPACE = 1{$FFFFFFFE};
sc_CB_FINDSTRING = $14C;
sc_CB_FINDSTRINGEXACT = $158;
sc_CB_GETCOMBOBOXINFO = $164;
sc_CB_GETCOUNT = $146;
sc_CB_GETCURSEL = $147;
sc_CB_GETDROPPEDCONTROLRECT = $152;
sc_CB_GETDROPPEDSTATE = $157;
sc_CB_GETDROPPEDWIDTH = $15F;
sc_CB_GETEDITSEL = $140;
sc_CB_GETEXTENDEDUI = $156;
sc_CB_GETHORIZONTALEXTENT = $15D;
sc_CB_GETITEMDATA = $150;
sc_CB_GETITEMHEIGHT = $154;
sc_CB_GETLBTEXT = $148;
sc_CB_GETLBTEXTLEN = $149;
sc_CB_GETLOCALE = $15A;
sc_CB_GETTOPINDEX = $15B;
sc_CB_INITSTORAGE = $161;
sc_CB_INSERTSTRING = $14A;
sc_CB_LIMITTEXT = $141;
sc_CB_MSGMAX = $165;
sc_CB_OKAY = $0;
sc_CB_RESETCONTENT = $14B;
sc_CB_SELECTSTRING = $14D;
sc_CB_SETCURSEL = $14E;
sc_CB_SETDROPPEDWIDTH = $160;
sc_CB_SETEDITSEL = $142;
sc_CB_SETEXTENDEDUI = $155;
sc_CB_SETHORIZONTALEXTENT = $15E;
sc_CB_SETITEMDATA = $151;
sc_CB_SETITEMHEIGHT = $153;
sc_CB_SETLOCALE = $159;
sc_CB_SETTOPINDEX = $15C;
sc_CB_SHOWDROPDOWN = $14F;

sc_TBS_AUTOTICKS      = $0001;
sc_TBS_VERT           = $0002;
sc_TBS_HORZ           = $0000;
sc_TBS_TOP            = $0004;
sc_TBS_BOTTOM         = $0000;
sc_TBS_LEFT           = $0004;
sc_TBS_RIGHT          = $0000;
sc_TBS_BOTH           = $0008;
sc_TBS_NOTICKS        = $0010;
sc_TBS_ENABLESELRANGE = $0020;
sc_TBS_FIXEDLENGTH    = $0040;
sc_TBS_NOTHUMB        = $0080;
sc_TBS_TOOLTIPS       = $0100;
sc_TBS_REVERSED       = $0200;
sc_TBS_DOWNISLEFT     = $0400;

sc_TBM_GETPOS         = sc_WM_USER;
sc_TBM_GETRANGEMIN    = sc_WM_USER+1;
sc_TBM_GETRANGEMAX    = sc_WM_USER+2;
sc_TBM_GETTIC         = sc_WM_USER+3;
sc_TBM_SETTIC         = sc_WM_USER+4;
sc_TBM_SETPOS         = sc_WM_USER+5;
sc_TBM_SETRANGE       = sc_WM_USER+6;
sc_TBM_SETRANGEMIN    = sc_WM_USER+7;
sc_TBM_SETRANGEMAX    = sc_WM_USER+8;
sc_TBM_CLEARTICS      = sc_WM_USER+9;
sc_TBM_SETSEL         = sc_WM_USER+10;
sc_TBM_SETSELSTART    = sc_WM_USER+11;
sc_TBM_SETSELEND      = sc_WM_USER+12;
sc_TBM_GETPTICS       = sc_WM_USER+14;
sc_TBM_GETTICPOS      = sc_WM_USER+15;
sc_TBM_GETNUMTICS     = sc_WM_USER+16;
sc_TBM_GETSELSTART    = sc_WM_USER+17;
sc_TBM_GETSELEND      = sc_WM_USER+18;
sc_TBM_CLEARSEL       = sc_WM_USER+19;
sc_TBM_SETTICFREQ     = sc_WM_USER+20;
sc_TBM_SETPAGESIZE    = sc_WM_USER+21;
sc_TBM_GETPAGESIZE    = sc_WM_USER+22;
sc_TBM_SETLINESIZE    = sc_WM_USER+23;
sc_TBM_GETLINESIZE    = sc_WM_USER+24;
sc_TBM_GETTHUMBRECT   = sc_WM_USER+25;
sc_TBM_GETCHANNELRECT = sc_WM_USER+26;
sc_TBM_SETTHUMBLENGTH = sc_WM_USER+27;
sc_TBM_GETTHUMBLENGTH = sc_WM_USER+28;
sc_TBM_SETTOOLTIPS    = sc_WM_USER+29;
sc_TBM_GETTOOLTIPS    = sc_WM_USER+30;
sc_TBM_SETTIPSIDE     = sc_WM_USER+31;

sc_TCIF_TEXT       = $0001;
sc_TCIF_IMAGE      = $0002;
sc_TCIF_RTLREADING = $0004;
sc_TCIF_PARAM      = $0008;
sc_TCIF_STATE      = $0010;

sc_TCM_FIRST       = $1300;
sc_TCM_INSERTITEM  = sc_TCM_FIRST+7;
sc_TCM_GETCURSEL   = sc_TCM_FIRST+11;

sc_TCN_FIRST = 0-550;

sc_TCN_SELCHANGE   = sc_TCN_FIRST-1;
sc_TCN_SELCHANGING = sc_TCN_FIRST-2;
sc_TCN_GETOBJECT   = sc_TCN_FIRST-3;
sc_TCN_FOCUSCHANGE = sc_TCN_FIRST-4;

sc_CC_RGBINIT              = $00000001;
sc_CC_FULLOPEN             = $00000002;
sc_CC_PREVENTFULLOPEN      = $00000004;
sc_CC_SHOWHELP             = $00000008;
sc_CC_ENABLEHOOK           = $00000010;
sc_CC_ENABLETEMPLATE       = $00000020;
sc_CC_ENABLETEMPLATEHANDLE = $00000040;
sc_CC_SOLIDCOLOR           = $00000080;
sc_CC_ANYCOLOR             = $00000100;

sc_CDERR_DIALOGFAILURE   = $FFFF;
sc_CDERR_GENERALCODES    = $0000;
sc_CDERR_STRUCTSIZE      = $0001;
sc_CDERR_INITIALIZATION  = $0002;
sc_CDERR_NOTEMPLATE      = $0003;
sc_CDERR_NOHINSTANCE     = $0004;
sc_CDERR_LOADSTRFAILURE  = $0005;
sc_CDERR_FINDRESFAILURE  = $0006;
sc_CDERR_LOADRESFAILURE  = $0007;
sc_CDERR_LOCKRESFAILURE  = $0008;
sc_CDERR_MEMALLOCFAILURE = $0009;
sc_CDERR_MEMLOCKFAILURE  = $000A;
sc_CDERR_NOHOOK          = $000B;
sc_CDERR_REGISTERMSGFAIL = $000C;

sc_OFN_READONLY             = 00000001;
sc_OFN_OVERWRITEPROMPT      = 00000002;
sc_OFN_HIDEREADONLY         = 00000004;
sc_OFN_NOCHANGEDIR          = 00000008;
sc_OFN_SHOWHELP             = 00000010;
sc_OFN_ENABLEHOOK           = 00000020;
sc_OFN_ENABLETEMPLATE       = 00000040;
sc_OFN_ENABLETEMPLATEHANDLE = 00000080;
sc_OFN_NOVALIDATE           = 00000100;
sc_OFN_ALLOWMULTISELECT     = 00000200;
sc_OFN_EXTENSIONDIFFERENT   = 00000400;
sc_OFN_PATHMUSTEXIST        = 00000800;
sc_OFN_FILEMUSTEXIST        = 00001000;
sc_OFN_CREATEPROMPT         = 00002000;
sc_OFN_SHAREAWARE           = 00004000;
sc_OFN_NOREADONLYRETURN     = 00008000;
sc_OFN_NOTESTFILECREATE     = 00010000;
sc_OFN_NONETWORKBUTTON      = 00020000;
sc_OFN_NOLONGNAMES          = 00040000;
sc_OFN_EXPLORER             = 00080000;
sc_OFN_NODEREFERENCELINKS   = 00100000;
sc_OFN_LONGNAMES            = 00200000;
sc_OFN_ENABLEINCLUDENOTIFY  = 00400000;
sc_OFN_ENABLESIZING         = 00800000;
sc_OFN_DONTADDTORECENT      = 02000000;
sc_OFN_FORCESHOWHIDDEN      = 10000000;

sc_FR_DIALOGTERM = $40;
sc_FR_DOWN = $1;
sc_FR_ENABLEHOOK = $100;
sc_FR_ENABLETEMPLATE = $200;
sc_FR_ENABLETEMPLATEHANDLE = $2000;
sc_FR_FINDNEXT = $8;
sc_FR_HIDEMATCHCASE = $8000;
sc_FR_HIDEUPDOWN = $4000;
sc_FR_HIDEWHOLEWORD = $10000;
sc_FR_MATCHALEFHAMZA = 1 {$80000000};
sc_FR_MATCHCASE = $4;
sc_FR_MATCHDIAC = $20000000;
sc_FR_MATCHKASHIDA = $40000000;
sc_FR_NOMATCHCASE = $800;
sc_FR_NOT_ENUM = $20;
sc_FR_NOUPDOWN = $400;
sc_FR_NOWHOLEWORD = $1000;
sc_FR_PRIVATE = $10;
sc_FR_RAW = $20000;
sc_FR_REPLACE = $10;
sc_FR_REPLACEALL = $20;
sc_FR_SHOWHELP = $80;
sc_FR_WHOLEWORD = $2;

sc_CF_SCREENFONTS          = $00000001;
sc_CF_PRINTERFONTS         = $00000002;
sc_CF_BOTH                 = sc_CF_SCREENFONTS or sc_CF_PRINTERFONTS;
sc_CF_SHOWHELP             = $00000004;
sc_CF_ENABLEHOOK           = $00000008;
sc_CF_ENABLETEMPLATE       = $00000010;
sc_CF_ENABLETEMPLATEHANDLE = $00000020;
sc_CF_INITTOLOGFONTSTRUCT  = $00000040;
sc_CF_USESTYLE             = $00000080;
sc_CF_EFFECTS              = $00000100;
sc_CF_APPLY                = $00000200;
sc_CF_ANSIONLY             = $00000400;
sc_CF_SCRIPTSONLY          = sc_CF_ANSIONLY;
sc_CF_NOVECTORFONTS        = $00000800;
sc_CF_NOOEMFONTS           = sc_CF_NOVECTORFONTS;
sc_CF_NOSIMULATIONS        = $00001000;
sc_CF_LIMITSIZE            = $00002000;
sc_CF_FIXEDPITCHONLY       = $00004000;
sc_CF_WYSIWYG              = $00008000;
sc_CF_FORCEFONTEXIST       = $00010000;
sc_CF_SCALABLEONLY         = $00020000;
sc_CF_TTONLY               = $00040000;
sc_CF_NOFACESEL            = $00080000;
sc_CF_NOSTYLESEL           = $00100000;
sc_CF_NOSIZESEL            = $00200000;
sc_CF_SELECTSCRIPT         = $00400000;
sc_CF_NOSCRIPTSEL          = $00800000;
sc_CF_NOVERTFONTS          = $01000000;

sc_SIMULATED_FONTTYPE = $8000;
sc_PRINTER_FONTTYPE   = $4000;
sc_SCREEN_FONTTYPE    = $2000;
sc_BOLD_FONTTYPE      = $0100;
sc_ITALIC_FONTTYPE    = $0200;
sc_REGULAR_FONTTYPE   = $0400;

type {*************************************************************************}

sc_WORD      = 0..65535;         { windows word }
sc_BOOL      = integer;          { windows boolean }
sc_DWORD     = integer;          { windows double word }
sc_WCHAR     = 0..65535;         { windows unicode character }
sc_CHAR      = char;             { windows ascii character }
sc_SHORT     = -32767..32767;    { windows short }
sc_long      = integer;          { windows long }
sc_int       = integer;          { windows int }
sc_UINT      = integer;          { windows unsigned integer }
sc_INT_PTR   = integer;          { windows integer/pointer }
sc_HANDLE    = integer;          { windows file handle }
sc_LPSTR     = ^char;            { character pointer }
sc_LPCSTR    = ^char;            { character pointer }
sc_BYTE      = byte;             { byte }
sc_LPBYTE    = bytptr;           { pointer to byte }
sc_intarr    = array of integer; { general integer array }
sc_hbitmap   = integer;          { handle to bitmap }
sc_hdc       = integer;          { handke to device context }    
sc_hgdiobj   = integer;          { handle to gdi object }
sc_hbrush    = integer;          { handle to brush }
sc_colorref  = integer;          { color number }
sc_hpen      = integer;          { handle to pen }
sc_hwnd      = integer;          { handle to window }
sc_lparam    = integer;          { void pointer }
sc_hfont     = integer;          { handle to font }
sc_ulong_ptr = sc_dword;         { unsigned long that can also be pointer }
sc_hinstance = integer;          { handle to instance }
sc_hmenu     = integer;          { handle for menu }
sc_lpvoid    = integer;
sc_LPTSTR    = sc_LPSTR;
sc_lpctstr   = sc_lpstr;
sc_lpfrhookproc = ^sc_c_lang_function;
sc_lpcfhookproc = ^sc_c_lang_function;
sc_tchar     = char;

sc_filetime = record

   lowdatetime:  integer; { low date/time }
   highdatetime: integer; { high date/time }

end;

sc_win32_find_dataa = record

   fileattributes:    integer;     { attrbutes on file }
   creationtime:      sc_filetime; { creation time of file }
   lastaccesstime:    sc_filetime; { last access time }
   lastwritetime:     sc_filetime; { last write time }
   filesizehigh:      integer;     { file size high }
   filesizelow:       integer;     { file size low }
   reserved0:         integer;     { reserved for undocumented features }
   reserved1:         integer;
   filename:          packed array [1..sc_max_path] of char; { filename }
   alternatefilename: packed array [1..14] of char; { alternate filename }

end;

sc_systemtime = packed record

   year:         sc_word; { year }
   month:        sc_word; { month (1..12) }
   dayofweek:    sc_word; { day of week (0..6, sun = 0) }
   day:          sc_word; { day of month (1..31) }
   hour:         sc_word; { hour (0..23) }
   minute:       sc_word; { minute (0..59) }
   second:       sc_word; { second (0..59) }
   milliseconds: sc_word  { milliseconds }

end;

{ time zone information record }

sc_time_zone_information = record

   bias:         integer; { adjustment to UTC in minutes }
   standardname: packed array [1..32] of char; { name of standard time zone }
   standarddate: sc_systemtime; { time of daylight to standard time change }
   standardbias: integer; { standard adjustment to bias in minutes }
   daylightname: packed array [1..32] of char; { name of daylight time zone }
   daylightdate: sc_systemtime; { time of standard to daylight time change }
   daylightbias: integer { daylight adjustment to bias in minutes }

end;

{ windows class record }

sc_wndclassa = record

   style:      integer;
   WndProc:    integer; { routine pointer }
   ClsExtra:   integer;
   WndExtra:   integer;
   Instance:   integer;
   Icon:       integer;
   Cursor:     integer;
   Background: integer;
   MenuName:   pstring;
   ClassName:  pstring

end;
sc_wndclass = sc_wndclassa;

{ point structure }

sc_point = record

   x: integer;
   y: integer

end;

sc_point_arr = array of sc_point;

{ Message structure }

sc_msg = record

   hwnd:    integer;
   message: integer;
   wParam:  integer;
   lParam:  integer;
   time:    integer;
   pt:      sc_point

end;

{ rectangle }

sc_rect = record

   left:   integer;
   top:    integer;
   right:  integer;
   bottom: integer

end;


{ paint structure }

sc_paint = record

   hdc:       integer; { device context handle }
   erase:     integer; { 32 bit boolean }
   paint:     sc_rect;
   restore:   integer; { 32 bit boolean }
   incupdate: integer; { 32 bit boolean }
   reserved:  array [1..32] of byte

end;

{  Logical Brush (or Pattern) }

sc_logbrush = record

    lbStyle: sc_uint;
    lbColor: sc_colorref;
    lbHatch: sc_long
              
end;

{ text metrics record }

sc_textmetric = record

   tmHeight:           integer;
   tmAscent:           integer;
   tmDescent:          integer;
   tmInternalLeading:  integer;
   tmExternalLeading:  integer;
   tmAveCharWidth:     integer;
   tmMaxCharWidth:     integer;
   tmWeight:           integer;
   tmOverhang:         integer;
   tmDigitizedAspectX: integer;
   tmDigitizedAspectY: integer;
   tmFirstChar:        byte;
   tmLastChar:         byte;
   tmDefaultChar:      byte;
   tmBreakChar:        byte;
   tmItalic:           byte;
   tmUnderlined:       byte;
   tmStruckOut:        byte;
   tmPitchAndFamily:   byte;
   tmCharSet:          byte

end;

sc_panose = record

   bFamilyType: sc_BYTE;
   bSerifStyle: sc_BYTE;
   bWeight: sc_BYTE;
   bProportion: sc_BYTE;
   bContrast: sc_BYTE;
   bStrokeVariation: sc_BYTE;
   bArmStyle: sc_BYTE;
   bLetterform: sc_BYTE;
   bMidline: sc_BYTE;
   bXHeight: sc_BYTE;

end;

sc_outlinetextmetric = record

   otmSize: sc_UINT;
   otmTextMetrics: sc_TEXTMETRIC;
   otmFiller: sc_BYTE;
   otmPanoseNumber: sc_PANOSE;
   otmfsSelection: sc_UINT;
   otmfsType: sc_UINT;
   otmsCharSlopeRise: sc_c_lang_int;
   otmsCharSlopeRun: sc_c_lang_int;
   otmItalicAngle: sc_c_lang_int;
   otmEMSquare: sc_UINT;
   otmAscent: sc_c_lang_int;
   otmDescent: sc_c_lang_int;
   otmLineGap: sc_UINT;
   otmsCapEmHeight: sc_UINT;
   otmsXHeight: sc_UINT;
   otmrcFontBox: sc_RECT;
   otmMacAscent: sc_c_lang_int;
   otmMacDescent: sc_c_lang_int;
   otmMacLineGap: sc_UINT;
   otmusMinimumPPEM: sc_UINT;
   otmptSubscriptSize: sc_POINT;
   otmptSubscriptOffset: sc_POINT;
   otmptSuperscriptSize: sc_POINT;
   otmptSuperscriptOffset: sc_POINT;
   otmsStrikeoutSize: sc_UINT;
   otmsStrikeoutPosition: sc_c_lang_int;
   otmsUnderscoreSize: sc_c_lang_int;
   otmsUnderscorePosition: sc_c_lang_int;
   otmpFamilyName: integer;
   otmpFaceName: integer;
   otmpStyleName: integer;
   otmpFullName: integer;
   { a trick is done with this structure, the strings above are placed after the
     structure according to a passed length. so we provide a padding area for
     those strings to retrive them in type safety }
   name: packed array [1..256] of char

end;

const sc_outlinetextmetric_len = 145+10+53+256;

type

sc_logfont = record

    lfHeight: sc_long;
    lfWidth: sc_long;
    lfEscapement: sc_long;
    lfOrientation: sc_long;
    lfWeight: sc_long;
    lfItalic: sc_byte;
    lfUnderline: sc_byte;
    lfStrikeOut: sc_byte;
    lfCharSet: sc_byte;
    lfOutPrecision: sc_byte;
    lfClipPrecision: sc_byte;
    lfQuality: sc_byte;
    lfPitchAndFamily: sc_byte;
    lfFaceName: packed array [1..sc_LF_FACESIZE] of char;

end;

sc_lplogfont = ^sc_logfont;

sc_evsptr = ^sc_evsrec;
sc_evsrec = record

   str: pstring;
   next: sc_evsptr

end;

{ startup info record }

sc_STARTUPINFOA = record

    cb:              sc_DWORD;
    lpReserved:      sc_LPSTR;
    lpDesktop:       sc_LPSTR;
    lpTitle:         sc_LPSTR;
    dwX:             sc_DWORD;
    dwY:             sc_DWORD;
    dwXSize:         sc_DWORD;
    dwYSize:         sc_DWORD;
    dwXCountChars:   sc_DWORD;
    dwYCountChars:   sc_DWORD;
    dwFillAttribute: sc_DWORD;
    dwFlags:         sc_DWORD;
    wShowWindow:     sc_WORD;
    cbReserved2:     sc_WORD;
    lpReserved2:     sc_LPBYTE;
    hStdInput:       sc_HANDLE;
    hStdOutput:      sc_HANDLE;
    hStdError:       sc_HANDLE;

end;

sc_LPSTARTUPINFOA = ^sc_STARTUPINFOA;

sc_PROCESS_INFORMATION = record

    hProcess:    sc_HANDLE;
    hThread:     sc_HANDLE;
    dwProcessId: sc_DWORD;
    dwThreadId:  sc_DWORD;

end;

sc_PPROCESS_INFORMATION = ^sc_PROCESS_INFORMATION;
sc_LPPROCESS_INFORMATION = ^sc_PROCESS_INFORMATION;

sc_enumlogfontex = record

    elfLogFont: sc_logfont;
    elfFullName: packed array [1..sc_LF_FULLFACESIZE] of char;
    elfStyle: packed array [1..sc_LF_FACESIZE] of char;
    elfScript: packed array [1..sc_LF_FACESIZE] of char;

end;

sc_newtextmetric = record

    tmHeight: sc_long;
    tmAscent: sc_long;
    tmDescent: sc_long;
    tmInternalLeading: sc_long;
    tmExternalLeading: sc_long;
    tmAveCharWidth: sc_long;
    tmMaxCharWidth: sc_long;
    tmWeight: sc_long;
    tmOverhang: sc_long;
    tmDigitizedAspectX: sc_long;
    tmDigitizedAspectY: sc_long;
    tmFirstChar: sc_byte;
    tmLastChar: sc_byte;
    tmDefaultChar: sc_byte;
    tmBreakChar: sc_byte;
    tmItalic: sc_byte;
    tmUnderlined: sc_byte;
    tmStruckOut: sc_byte;
    tmPitchAndFamily: sc_byte;
    tmCharSet: sc_byte;
    ntmFlags: sc_dword;
    ntmSizeEM: sc_uint;
    ntmCellHeight: sc_uint;
    ntmAvgWidth: sc_uint;

end;

sc_fontsignature = record

    fsUsb: array [0..4-1] of sc_dword;
    fsCsb: array [0..2-1] of sc_dword

end;

sc_newtextmetricex = record

    ntmTm: sc_newtextmetric;
    ntmFontSig: sc_fontsignature

end;

sc_abc = record

   abca: sc_c_lang_int;
   abcb: sc_uint;
   abcc: sc_c_lang_int

end;

sc_abcs = array [0..255] of sc_abc;

sc_glyphmetrics = record

   gmBlackBoxX: sc_uint;
   gmBlackBoxY: sc_uint;
   gmptGlyphOrigin: sc_point;
   gmCellIncX: sc_short;
   gmCellIncY: sc_short

end;

sc_fixed = record

   fract: sc_word;
   value: sc_short;

end;

sc_mat2 = record

   eM11: sc_fixed;
   eM12: sc_fixed;
   eM21: sc_fixed;
   eM22: sc_fixed

end;

sc_size = record

   cx: sc_long;
   cy: sc_long

end;

sc_list_entry = record

    flink: ^sc_list_entry;
    blink: ^sc_list_entry

end;

sc_critical_section_debug = record

    Typeof: sc_word;
    CreatorBackTraceIndex: sc_word;
    CriticalSection: ^sc_critical_section;
    ProcessLocksList: sc_list_entry;
    EntryCount: sc_dword;
    ContentionCount: sc_dword;
    Spare: array [0..1] of sc_dword

end;

sc_critical_section = record

    DebugInfo: sc_critical_section_debug;
    LockCount: sc_long;
    RecursionCount: sc_long;
    OwningThread: sc_handle;
    LockSemaphore: sc_handle;
    SpinCount: sc_ulong_ptr

end;

const sc_bitmap_len = 4+4+4+4+2+2+4;

type

sc_bitmap = record

    bmType: sc_long;
    bmWidth: sc_long;
    bmHeight: sc_long;
    bmWidthBytes: sc_long;
    bmPlanes: sc_word;
    bmBitsPixel: sc_word;
    bmBits: sc_long

end;

const sc_gcp_results_len = 9*4;

type 

sc_intarr250 = array [1..250] of sc_c_lang_int;
sc_intarr250_ptr = ^sc_intarr250;
sc_chrarr250 = array [1..250] of char;
sc_wcharr250 = array [1..250] of sc_wchar;

sc_gcp_results = record

    lStructSize: sc_dword;
    lpOutString: ^sc_chrarr250;
    lpOrder: sc_intarr250_ptr;
    lpDx: sc_intarr250_ptr;
    lpCaretPos: sc_intarr250_ptr;
    lpClass: sc_lpstr;
    lpGlyphs: sc_intarr250_ptr;
    nGlyphs: sc_uint;
    nMaxFit: sc_c_lang_int

end;

sc_SCROLLINFO = record
   cbSize: sc_UINT;
   fMask: sc_UINT;
   nMin: sc_INT_PTR;
   nMax: sc_INT_PTR;
   nPage: sc_UINT;
   nPos: sc_INT_PTR;
   nTrackPos: sc_INT_PTR;
end;

sc_CREATESTRUCTA = record
   lpCreateParams: sc_LPVOID;
   hInstance: sc_HINSTANCE;
   hMenu: sc_HMENU;
   hwndParent: sc_HWND;
   cy: sc_INT_PTR;
   cx: sc_INT_PTR;
   y: sc_INT_PTR;
   x: sc_INT_PTR;
   style: sc_LONG;
   lpszName: sc_LPCSTR;
   lpszClass: sc_LPCSTR;
   dwExStyle: sc_DWORD;
end;
sc_CREATESTRUCT = sc_CREATESTRUCTA;

sc_tcitem = record

   mask: sc_uint;
   dwstate: sc_dword;
   dwstatemask: sc_dword;
   psztext: pstring;
   iimage: sc_c_lang_int;
   lparam: sc_lparam

end;

sc_nmhdr = record

   hwndfrom: sc_hwnd;
   idfrom: sc_uint;
   code: sc_uint

end;

sc_colorref_table = array [1..16] of sc_colorref;
sc_colorref_table_ptr = ^sc_colorref_table;
sc_choosecolor_rec = record

    lStructSize: sc_dword;
    hwndOwner: sc_hwnd;
    hInstance: sc_hwnd;
    rgbResult: sc_colorref;
    lpCustColors: sc_colorref_table_ptr;
    Flags: sc_dword;
    lCustData: integer;
    lpfnHook: integer;
    lpTemplateName: sc_lpctstr;

end;

sc_openfilename = record

  lStructSize:       sc_dword; 
  hwndOwner:         sc_hwnd; 
  hInstance:         sc_hinstance; 
  lpstrFilter:       sc_lpctstr; 
  lpstrCustomFilter: pstring; 
  nFilterIndex:      sc_dword; 
  lpstrFile:         pstring;
  lpstrFileTitle:    pstring;
  lpstrInitialDir:   sc_lpctstr;
  lpstrTitle:        sc_lpctstr;
  Flags:             sc_dword;
  nFileOffset:       sc_word;
  nFileExtension:    sc_word;
  lpstrDefExt:       sc_lpctstr;
  lCustData:         sc_lparam;
  lpfnHook:          sc_dword;
  lpTemplateName:    sc_lpctstr;
  pvReserved:        sc_dword;
  dwReserved:        sc_dword;
  FlagsEx:           sc_dword;

end;

const sc_findreplace_str_len = 100;

type

sc_findreplace_str = packed array [1..sc_findreplace_str_len] of char;
sc_findreplace_str_ptr = ^sc_findreplace_str;
sc_findreplace = record

    lStructSize:      sc_dword;
    hwndOwner:        sc_hwnd;
    hInstance:        sc_hinstance;
    Flags:            sc_dword;
    lpstrFindWhat:    sc_findreplace_str_ptr;
    lpstrReplaceWith: sc_findreplace_str_ptr;
    wFindWhatLen:     sc_word;
    wReplaceWithLen:  sc_word;
    lCustData:        sc_lparam;
    lpfnHook:         sc_lpfrhookproc;
    lpTemplateName:   sc_lpctstr;

end;
const sc_findreplace_len = 9*4+2*2;

type

sc_choosefont_rec = record

    lStructSize:    sc_dword;
    hwndOwner:      sc_hwnd;
    hDC:            sc_hdc;
    lpLogFont:      sc_lplogfont;
    iPointSize:     sc_int;
    Flags:          sc_dword;
    rgbColors:      sc_colorref;
    lCustData:      sc_lparam;
    lpfnHook:       sc_lpcfhookproc;
    lpTemplateName: sc_lpctstr;
    hInstance:      sc_hinstance;
    lpszStyle:      sc_lptstr;
    nFontType:      sc_word;
    pad1:           sc_word;
    nSizeMin:       sc_int;
    nSizeMax:       sc_int;

end;
const sc_choosefont_len = 14*4+2*2;

var {**************************************************************************}

{ exit code for program }

windows_exit_code: integer;

{****************************** Functions *************************************}

function sc_getstdhandle(hdlrc: integer): integer; external;
function sc__lopen(view name: string; mode: integer): integer; external;
function sc__lcreat(view name: string; mode: integer): integer; external;
function sc__lclose(hdl: integer): integer; external;
function sc__lread(hdl: integer; var ba:  bytarr): integer; external;
function sc__lwrite(     hdl: integer; view ba:  bytarr): integer; external;
function sc__llseek(hdl: integer; off: integer; org: integer): integer;
   external;
function sc_getfilesize(hdl: integer; var ups: integer): integer;
   external;
function sc_deletefile(view name: string): boolean; external;
function sc_movefile(view sn: string; view dn: string): boolean; external;
function sc_globalalloc(flg: integer; len: integer): gbtptr; external;
function sc_globalfree(view bp: gbtptr): integer; external;
function sc_getcommandline: pstring; external;
function sc_findfirstfile(view name: string; var  data: sc_win32_find_dataa)
   : integer; external;
function sc_findnextfile(hdl: integer; var data: sc_win32_find_dataa)
   : integer; external;
function sc_findclose(hdl: integer): integer; external;
function sc_filetimetosystemtime(view ft: sc_filetime; var  st: sc_systemtime)
   : integer; external;      
function sc_systemtimetofiletime(view st: sc_systemtime; var  ft: sc_filetime)
   : integer; external;
function sc_filetimetodosdatetime(view ft: sc_filetime; var  date: sc_word;
   var  time: sc_word): boolean; external;
procedure sc_getsystemtime(var st: sc_systemtime); external;
function sc_gettickcount: integer; external;
procedure sc_getlocaltime(var st: sc_systemtime); external;
function sc_gettimezoneinformation(var tz: sc_time_zone_information): integer;
   external;
function sc_getlasterror: integer; external;
function sc_CreateWindow(view lpClassName: string; view lpWindowName: string;
   dwStyle: sc_dword; x: sc_c_lang_int; y: sc_c_lang_int; nWidth: sc_c_lang_int; nHeight: sc_c_lang_int; 
   hWndParent: sc_hwnd; hMenu: sc_hmenu; hInstance: sc_hinstance; 
   var lpParam: sc_createstruct): sc_hwnd; external;
overload function sc_CreateWindow(view lpClassName: string; view lpWindowName:
   string; dwStyle: sc_dword; x: sc_c_lang_int; y: sc_c_lang_int; nWidth: sc_c_lang_int;
   nHeight: sc_c_lang_int; hWndParent: sc_hwnd; hMenu: sc_hmenu; hInstance: sc_hinstance)
   : sc_hwnd; external;
function sc_CreateWindowEx(dwExStyle: sc_dword; view lpClassName: string; 
   view lpWindowName: string; dwStyle: sc_dword; x: sc_c_lang_int; y: sc_c_lang_int; nWidth: sc_c_lang_int; 
   nHeight: sc_c_lang_int; hWndParent: sc_hwnd; hMenu: sc_hmenu; hInstance: sc_hinstance;
   var lpParam: sc_createstruct): sc_hwnd; external;
overload function sc_CreateWindowEx(dwExStyle: sc_dword; view lpClassName: string; 
   view lpWindowName: string; dwStyle: sc_dword; x: sc_c_lang_int; y: sc_c_lang_int; nWidth: sc_c_lang_int; 
   nHeight: sc_c_lang_int; hWndParent: sc_hwnd; hMenu: sc_hmenu; hInstance: sc_hinstance)
   : sc_hwnd; external;
function sc_destroywindow(h: sc_hwnd): boolean; external;
function sc_showwindow(hdl: integer; cmd: integer): boolean; external;
function sc_registerclass(var wc: sc_wndclassa): boolean; external;
function sc_updatewindow(hdl: integer): boolean; external;
function sc_msgmirroraddr: integer; external;
function sc_wndprocadr(function wndproc(hwnd, imsg, wparam, lparam: integer)
   : integer): integer; external;
function sc_getmodulehandle_n: integer; external;
function sc_loadicon_n(it: integer): integer; external;
function sc_loadcursor_n(ct: integer): integer; external;
function sc_getstockobject(index: integer): integer; external; 
function sc_selectobject(h: integer; o: integer): integer; external;
function sc_messagebox(hdl:  integer; view text: string; view capt: string;
   typ:  integer): integer;external;
function sc_getmessage(var m: sc_msg; h:  integer; mn: integer; mx: integer)
   : integer; external;
function sc_peekmessage(var m: sc_msg; h: integer; mn: integer; mx: integer;
   rf: integer): boolean; external;
function sc_translatemessage(var m: sc_msg): boolean; external;
function sc_postmessage(h, m, w, l: integer): boolean; external;
procedure sc_postquitmessage(ec: integer); external;
function sc_defwindowproc(hw, um, wp, lp: integer): integer; external;
function sc_dispatchmessage(var m: sc_msg): integer; external;
function sc_beginpaint(h: integer; var p: sc_paint): integer; external;
function sc_endpaint(h: integer; var p: sc_paint): boolean; external;
function sc_getclientrect(h: integer; var r: sc_rect): boolean; external;
function sc_getwindowrect(h: integer; var r: sc_rect): boolean; external;
function sc_drawtext(h: integer; view s: string; view r: sc_rect; f: integer)
   : integer; external;
function sc_textout(h: integer; x, y: integer; view s: string): boolean;
   external;
function sc_getdc(h: integer): integer; external;
function sc_releasedc(wh: integer; dh: integer): boolean; external;
function sc_gettextmetrics(h: integer; var tm: sc_textmetric): boolean;
   external;
function sc_validatergn_n(h: integer): boolean; external;
function sc_showcursor(b: boolean): integer; external;
function sc_createcaret(w: integer; b: integer; x: integer; y: integer)
   : boolean; external;
function sc_destroycaret: boolean; external;
function sc_showcaret(w: integer): boolean; external;
function sc_hidecaret(w: integer): boolean; external;
function sc_setcaretpos(x, y: integer): boolean; external;
function sc_settextcolor(dc: integer; c:  integer): integer; external;
function sc_setbkcolor(dc: integer; c: integer): integer; external;
function sc_rectangle(dc: integer; x1, y1: integer; x2, y2: integer): boolean;
   external;
function sc_roundrect(dc: integer; x1, y1, x2, y2, xs, ys: integer): boolean;
   external;
function sc_setbkmode(dc: integer; bm: integer): integer; external;
function sc_settimer(wh: integer; ti: integer; t: integer; procedure timcal)
   : integer; external;
function sc_settimer_n(wh: integer; ti: integer; t: integer): integer;
   external;
function sc_killtimer(wh: integer; ti: integer): boolean; external;
function sc_setwindowtext(wh: integer; view s: string): boolean; external;
procedure sc_crkmsg(m: integer; var h, l: integer); external;
function sc_setwindowpos(wh: integer; ins: integer; x, y: integer;
   w, h: integer; f: integer): boolean; external;
function sc_adjustwindowrectex(var r: sc_rect; s: sc_dword; m: boolean;
   es: sc_dword): boolean; external;
function sc_getenvironmentvariable(view n: string; var v: string): integer;
   external;
function sc_setenvironmentvariable(view n: string; view v: string): boolean;
   external;
function sc_setenvironmentvariable_n(view n: string): boolean; external;
function sc_getenvironmentstrings: sc_evsptr; external;
function sc_CreateProcess_nn(view lpApplicationName: string;
   view lpCommandLine: string; bInheritHandles: boolean;
   dwCreationFlags: sc_DWORD; lpEnvironment: sc_evsptr;
   view lpCurrentDirectory: string; var lpStartupInfo: sc_STARTUPINFOA;
   var lpProcessInformation: sc_PROCESS_INFORMATION): boolean; external;
function sc_createthread_nn(ss: integer; procedure thread; f: integer;
    var ti: integer): integer; external;
function sc_setthreadpriority(h, p: integer): boolean; external;
function sc_WaitForSingleObject(hHandle: sc_HANDLE; dwMilliseconds: sc_DWORD)
   : sc_DWORD; external;
function sc_CloseHandle(hObject: sc_HANDLE): boolean; external;
function sc_GetCurrentDirectory(var p: string): integer; external;
function sc_SetCurrentDirectory(view p: string): boolean; external;
function sc_SetFileAttributes(view lpFileName: string;
   dwFileAttributes: sc_DWORD): boolean; external;
function sc_GetFileAttributes(view lpFileName: string): sc_DWORD; external;
function sc_GetExitCodeProcess(hProcess: sc_HANDLE; var lpExitCode: integer)
   : boolean; external;
function sc_CreateDirectory_n(view lpPathName: string): boolean; external;
function sc_RemoveDirectory(view lpPathName: string): boolean; external;
function sc_GetDiskFreeSpace(view lpRootPathName: string;
   var lpSectorsPerCluster: sc_DWORD; var lpBytesPerSector: sc_DWORD;
   var lpNumberOfFreeClusters: sc_DWORD; var lpTotalNumberOfClusters: sc_DWORD)
   : boolean; external;
procedure sc_exitprocess(ec: integer); external;
function sc_beep(f, d: integer): boolean; external;
function sc_createsolidbrush(c: sc_colorref): sc_hbrush; external;
function sc_fillrect(h: sc_hdc; var r: sc_rect; b: sc_hbrush): boolean;
   external;
function sc_deleteobject(o: sc_hgdiobj): boolean; external;
function sc_bitblt(d: sc_hdc; dx, dy, w, h: integer; s: sc_hdc; sx, sy: integer;
   rop: sc_dword): boolean; external; 
function sc_stretchblt(d: sc_hdc; dx, dy, dw, dh: integer; s: sc_hdc;
   sx, sy, sw, sh: integer; rop: sc_dword): boolean; external; 
function sc_createcompatibledc(h: sc_hdc): sc_hdc; external;
function sc_createcompatiblebitmap(hdl: sc_hdc; w, h: integer): sc_hbitmap;
   external;
function sc_movetoex_n(h: sc_hdc; x, y: integer): boolean; external;
function sc_lineto(h: sc_hdc; x, y: integer): boolean; external;
function sc_createpen(ps, w, c: integer): sc_hpen; external;
function sc_extcreatepen_nn(ps, w: integer; view lb: sc_logbrush): sc_hpen;
   external;
function sc_ellipse(h: sc_hdc; x1, y1, x2, y2: integer): boolean; external;
function sc_setpixel(h: sc_hdc; x, y: integer; c: sc_colorref): sc_colorref;
   external;
function sc_setrop2(h: sc_hdc; m: integer): integer; external;
function sc_enumfontfamiliesex(h: sc_hdc; var lf: sc_logfont;
   function ef(var lfd: sc_enumlogfontex; var pfd: sc_newtextmetricex;
   ft: sc_dword; ad: sc_lparam): boolean; lp: sc_lparam; f: sc_dword): integer;
   external;
function sc_createfont(h, w, e, o, wt: integer; i, u, s: boolean;
   cs, op, cp, q, pf: sc_dword; view fn: string): sc_hfont; external;
function sc_getoutlinetextmetrics(h: sc_hdc; l: integer; 
   var tm: sc_outlinetextmetric): boolean; external;
function sc_getcharabcwidths(h: sc_hdc; fc, lc: sc_uint; var wa: sc_abcs)
   : boolean; external;
function sc_getglyphoutline_metrics(h: sc_hdc; c: char;
   var m: sc_glyphmetrics; var t: sc_mat2): sc_dword; external;
function sc_gettextextentpoint32(h: sc_hdc; view s: string; var sz: sc_size)
   : boolean; external;
function sc_getdevicecaps(h: sc_hdc; i: integer): integer; external;
procedure sc_initializecriticalsection(var l: sc_critical_section); external;
procedure sc_entercriticalsection(var l: sc_critical_section); external;
procedure sc_leavecriticalsection(var l: sc_critical_section); external;
procedure sc_deletecriticalsection(var l: sc_critical_section); external;
function sc_loadimage(h: sc_hinstance; view s: string; t: sc_uint;
   cx, cy: sc_c_lang_int; f: sc_uint): sc_handle; external;
function sc_getbitmapdimensionex(h: sc_hbitmap; var s: sc_size): boolean;
   external;
function sc_getobject_bitmap(h: sc_hgdiobj; l: sc_c_lang_int; var bm: sc_bitmap): sc_c_lang_int;
   external;
function sc_setstretchbltmode(h: sc_hdc; m: sc_c_lang_int): sc_c_lang_int; external;
function sc_deletedc(h: sc_hdc): boolean; external;
function sc_setviewportorgex_n(h: sc_hdc; x, y: sc_c_lang_int): boolean; external;
function sc_getviewportextex(h: sc_hdc; var s: sc_size): boolean; external;
function sc_setviewportextex(h: sc_hdc; x, y: sc_c_lang_int; var s: sc_size): boolean;
   external;
function sc_setwindowextex(h: sc_hdc; x, y: sc_c_lang_int; var s: sc_size): boolean;
   external;
function sc_scaleviewportextex(h: sc_hdc; xm, xd, ym, yd: sc_c_lang_int;
   var s: sc_size): boolean; external;
function sc_setmapmode(h: sc_hdc; mm: sc_c_lang_int): sc_c_lang_int; external;
function sc_lptodp_o(h: sc_hdc; var p: sc_point): boolean; external;
function sc_settextjustification(h: sc_hdc; be, bc: sc_c_lang_int): boolean; external;
function sc_getcharacterplacement(h: sc_hdc; view s: string; me: sc_c_lang_int;
   var r: sc_gcp_results; f: sc_dword): sc_dword; external;
function sc_exttextout_n(h: sc_hdc; x, y: sc_c_lang_int; f: sc_uint; view s: string;
   sp: sc_intarr250_ptr): boolean; external;
function sc_polygon(h: sc_hdc; var pa: sc_point_arr): boolean; external;
function sc_arc(h: sc_hdc; x1, y1, x2, y2, sx, sy, ex, ey: sc_c_lang_int): boolean;
   external;
function sc_pie(h: sc_hdc; x1, y1, x2, y2, sx, sy, ex, ey: sc_c_lang_int): boolean;
   external;
function sc_chord(h: sc_hdc; x1, y1, x2, y2, sx, sy, ex, ey: sc_c_lang_int): boolean;
   external;
function sc_CreateMenu: sc_HMENU; external;
function sc_DestroyMenu(hMenu: sc_HMENU): boolean; external;
function sc_AppendMenu(hMenu: sc_HMENU; uFlags: sc_UINT; uIDNewItem: sc_UINT; 
   view lpNewItem: string): boolean; external;
function sc_DrawMenuBar(hWnd: integer): boolean; external;
function sc_setmenu(hwnd: integer; hmenu: integer): boolean; external;
function sc_enablemenuitem(hmenu: integer; enableitem: integer; enable: integer):
   integer; external;
function sc_checkmenuitem(hmenu: integer; enableitem: integer; enable: integer):
   integer; external;
function sc_getdesktopwindow: integer; external;
function sc_setwindowlong(h, i, v: integer): integer; external;

function sc_SendMessage(hWnd, msg, wparam, lparam: integer): integer; 
   external;
overload function sc_SendMessage(hWnd, msg: integer; view lparam: string): 
   integer; external;

overload function sc_SendMessage(hWnd, msg, wparam: integer; 
   var lparam: sc_tcitem): integer; external;

function sc_SetScrollRange(hWnd, nbar, nminpos, nmaxpos: integer; 
   bredraw: boolean): boolean; external;
function sc_SetScrollPos(hWnd, nbar, npos: integer; bRedraw: boolean): 
   integer; external;
function sc_setscrollinfo(hwnd, fnbar: integer; var lpsi: sc_scrollinfo;
   fredraw: boolean): integer; external;
function sc_createupdowncontrol(dwstyle, x, y, cx, cy, hparent, nid, hinst, 
   hbuddy, nupper, nlower, npos: integer): integer; external;
function sc_setfocus(hwnd: integer): integer; external;
function sc_movewindow(hwnd, x, y, nwidth, nheight: integer; brepaint: boolean):
   boolean; external;
function sc_getwindowtext(hwnd: integer; var lpstring: string): integer; 
   external;
function sc_getwindowtextlength(hwnd: integer): integer; external;
function sc_choosecolor(var lpcc: sc_choosecolor_rec): boolean; external;
function sc_getopenfilename(var lpofn: sc_openfilename): boolean; external;
function sc_getsavefilename(var lpofn: sc_openfilename): boolean; external;
function sc_commdlgextendederror: sc_dword; external;
function sc_findtext(var lpfr: sc_findreplace): sc_hwnd; external;
function sc_replacetext(var lpfr: sc_findreplace): sc_hwnd; external;
function sc_registerwindowmessage(view lpstring: string): sc_uint; external;
function sc_choosefont(var lpcf: sc_choosefont_rec): boolean; external;
function sc_createevent(r, s: boolean): integer; external;
function sc_setevent(h: integer): boolean; external;
function sc_resetevent(h: integer): boolean; external;
function sc_getdialogbaseunits: integer; external;

{***************************** WINCON.H ***************************************}

const

sc_RIGHT_ALT_PRESSED  = $0001; 
sc_LEFT_ALT_PRESSED   = $0002; 
sc_RIGHT_CTRL_PRESSED = $0004; 
sc_LEFT_CTRL_PRESSED  = $0008; 
sc_SHIFT_PRESSED      = $0010; 
sc_NUMLOCK_ON         = $0020; 
sc_SCROLLLOCK_ON      = $0040; 
sc_CAPSLOCK_ON        = $0080; 
sc_ENHANCED_KEY       = $0100; 

sc_FROM_LEFT_1ST_BUTTON_PRESSED = $0001;
sc_RIGHTMOST_BUTTON_PRESSED     = $0002;
sc_FROM_LEFT_2ND_BUTTON_PRESSED = $0004;
sc_FROM_LEFT_3RD_BUTTON_PRESSED = $0008;
sc_FROM_LEFT_4TH_BUTTON_PRESSED = $0010;

sc_MOUSE_MOVED  = $0001;
sc_DOUBLE_CLICK = $0002;

sc_KEY_EVENT             = $0001;
sc_MOUSE_EVENT           = $0002;
sc_WINDOW_BUFFER_S_EVENT = $0004;
sc_MENU_EVENT            = $0008;
sc_FOCUS_EVENT           = $0010;

sc_FOREGROUND_BLUE      = $0001;
sc_FOREGROUND_GREEN     = $0002;
sc_FOREGROUND_RED       = $0004;
sc_FOREGROUND_INTENSITY = $0008;
sc_BACKGROUND_BLUE      = $0010;
sc_BACKGROUND_GREEN     = $0020;
sc_BACKGROUND_RED       = $0040;
sc_BACKGROUND_INTENSITY = $0080;

sc_CTRL_C_EVENT        = 0;
sc_CTRL_BREAK_EVENT    = 1;
sc_CTRL_CLOSE_EVENT    = 2;
sc_CTRL_LOGOFF_EVENT   = 5;
sc_CTRL_SHUTDOWN_EVENT = 6;

sc_ENABLE_PROCESSED_INPUT = $0001;
sc_ENABLE_LINE_INPUT      = $0002;
sc_ENABLE_ECHO_INPUT      = $0004;
sc_ENABLE_WINDOW_INPUT    = $0008;
sc_ENABLE_MOUSE_INPUT     = $0010;

sc_ENABLE_PROCESSED_OUTPUT   = $0001;
sc_ENABLE_WRAP_AT_EOL_OUTPUT = $0002;

sc_CONSOLE_TEXTMODE_BUFFER = 1;

type 

sc_COORD = record

   x: sc_SHORT;
   y: sc_SHORT;

end;
sc_pcoord = integer; { packed COORD }

sc_small_rect = record

   left:   sc_short;
   top:    sc_short;
   right:  sc_short;
   bottom: sc_short

end;

sc_chrtyp = (sc_unichr, sc_ascchr); 
sc_sinchr = record

   case sc_chrtyp of

      sc_unichr: (UnicodeChar: sc_WCHAR);
      sc_ascchr: (AsciiChar:   sc_CHAR);

end;
sc_KEY_EVENT_RECORD = record

   space1:            sc_WORD; { spacer }
   bKeyDown:          sc_BOOL;
   wRepeatCount:      sc_WORD;
   wVirtualKeyCode:   sc_WORD;
   wVirtualScanCode:  sc_WORD;
   uChar:             sc_sinchr;
   dwControlKeyState: sc_DWORD;
   
end;

sc_MOUSE_EVENT_RECORD = record

   space1:            sc_WORD; { spacer }
   dwMousePosition:   sc_COORD;
   dwButtonState:     sc_DWORD;
   dwControlKeyState: sc_DWORD;
   dwEventFlags:      sc_DWORD;

end;

sc_WINDOW_BUFFER_SIZE_RECORD = record

   Size: sc_COORD;

end;

sc_MENU_EVENT_RECORD = record

   CommandId: sc_UINT;

end;

sc_FOCUS_EVENT_RECORD = record

   SetFocus: sc_BOOL;

end;

sc_irtype = (sc_irtkey, sc_irtmou, sc_irtwbs, sc_irtmen, sc_irtfou);
sc_INPUT_RECORD = record

   EventType: sc_WORD;
   case sc_irtype of

      sc_irtkey: (KeyEvent:              sc_KEY_EVENT_RECORD);
      sc_irtmou: (MouseEvent:            sc_MOUSE_EVENT_RECORD);
      sc_irtwbs: (WindowBufferSizeEvent: sc_WINDOW_BUFFER_SIZE_RECORD);
      sc_irtmen: (MenuEvent:             sc_MENU_EVENT_RECORD);
      sc_irtfou: (FocusEvent:            sc_FOCUS_EVENT_RECORD);

   { end }

end;
sc_input_record_arr = array of sc_input_record;

sc_char_info = record

   asciichar: sc_char;
   pad: byte;
   attributes: sc_word

end;

sc_console_screen_buffer_info = record

   dwsize:             sc_coord;
   dwcursorposition:   sc_coord;
   wattributes:        sc_word;
   srwindow:           sc_small_rect;
   dwmaximmwindowsize: sc_coord

end;

sc_console_cursor_info = record

   dwsize: sc_dword;
   bvisible: sc_bool

end;

function sc_peekconsoleinput(h: sc_handle; var ers: sc_INPUT_RECORD_arr;
   var n: sc_dword): boolean; external;
function sc_readconsoleinput(h: sc_handle; var ers: sc_INPUT_RECORD_arr;
   var n: sc_dword): boolean; external;
function sc_writeconsoleinput(h: sc_handle; view ir: sc_input_record_arr;
   var n: sc_dword): boolean; external;
{ readconsoleoutput needs two dementional variable arrays }
{*}{function sc_readconsoleoutput(h: sc_handle; var ci: sc_char_info;
   s, c: sc_pcoord; var r: sc_small_rect): boolean;}
{ writeconsoleoutput needs two dementional variable arrays }
{*}{function sc_writeconsoleoutput(h: sc_handle;
   view ci: sc_char_info; s, c: sc_pcoord; view r: sc_small_rect): boolean;}
{*}function sc_readconsoleoutputcharacter(h: sc_handle;
   view s: string; c: sc_pcoord; var n: sc_dword): boolean; external;
{*}function sc_readconsoleoutputattribute(h: sc_handle; var a: sc_intarr; c: sc_pcoord;
   var n: sc_dword): boolean; external;
function sc_writeconsoleoutputcharacter(h: sc_handle; view s: string;
   xy: sc_pcoord; var l: sc_dword): boolean; external;    
function sc_writeconsoleoutputattribute(h: sc_handle; view s: sc_intarr;
   xy: integer; var l: sc_dword): boolean; external;  
{*}function sc_fillconsoleoutputcharacter(h: sc_handle; c: char; n: sc_dword;
   xy: sc_pcoord; var l: sc_dword): boolean; external;    
{*}function sc_fillconsoleoutputattribute(h: sc_handle; w: sc_word; n: sc_dword;
   xy: sc_pcoord; var l: sc_dword): boolean; external;
{*}function sc_getconsolemode(h: sc_handle; var m: sc_dword): boolean; external;
{*}function sc_getnumberofconsoleinputevents(h: sc_handle; var n: sc_dword)
   : boolean; external;
function sc_getconsolescreenbufferinfo(h: sc_handle;
    var bi: sc_console_screen_buffer_info): boolean; external;
{*}function sc_getlargestconsolewindowsize(h: sc_handle): sc_pcoord; external;
function sc_getconsolecursorinfo(h: sc_handle; var ci: sc_console_cursor_info)
   : boolean; external;
{*}function sc_getnumberofconsolemousebuttons(var n: sc_dword): boolean; external;
{*}function sc_setconsolemode(h: sc_handle; m: sc_dword): boolean; external;
{*}function sc_setconsoleactivescreenbuffer(h: sc_handle): boolean; external;
{*}function sc_flushconsoleinputbuffer(h: sc_handle): boolean; external;
{*}function sc_setconsolescreenbuffersize(h: sc_handle; s: sc_pcoord): boolean; external;
function sc_setconsolecursorposition(h: sc_handle; xy: integer): boolean;
   external;
function sc_setconsolecursorinfo(h: sc_handle; var ci: sc_console_cursor_info)
   : boolean; external;
{*}function sc_scrollconsolescreenbuffer(h: sc_handle; view sr, cr: sc_small_rect;
   d: sc_pcoord; view f: sc_char_info): boolean; external;
function sc_scrollconsolescreenbuffer_n(h: sc_handle; view sr: sc_small_rect;
    d: sc_pcoord; view f: sc_char_info): boolean; external;
{*}function sc_setconsolewindowinfo(h: sc_handle; a: sc_bool; view cw: sc_small_rect)
   : boolean; external;
{*}function sc_setconsoletextattribute(h: sc_handle; a: sc_word): boolean; external;
{*}function sc_setconsolectrlhandler(function ctlhan(ct: sc_dword): boolean; a: boolean): boolean;
   external;
{*}function sc_generateconsolectrlevent(ce: sc_dword; gid: sc_dword): boolean;
   external;
{*}function sc_allocconsole: boolean; external;
{*}function sc_freeconsole: boolean; external;
{*}function sc_getconsoletitle(var s: string): sc_dword; external;
{*}function sc_setconsoletitle(view s: string): boolean; external;
{*}function sc_readconsole(h: sc_handle; var s: string; var cr: sc_dword): boolean;
   external;
{*}{function sc_writeconsole(h: sc_handle; ??; nc: sc_dword; var cw: sc_dword): boolean;
   external; }
{*}function sc_createconsolescreenbuffer_nn(a, s: sc_dword; f: sc_dword)
   : sc_handle; external;
{*}function sc_getconsolecp: sc_uint; external;
{*}function sc_setconsolecp(ci: sc_uint): boolean; external;
{*}function sc_getconsoleoutputcp: sc_uint; external;
{*}function sc_setconsoleoutputcp(cp: sc_uint): boolean; external;

{***************************** MMSYSTEM.H ***************************************}

const

sc_SND_SYNC         = $00000000;  
sc_SND_ASYNC        = $00000001;  
sc_SND_NODEFAULT    = $00000002;  
sc_SND_MEMORY       = $00000004;  
sc_SND_LOOP         = $00000008;  
sc_SND_NOSTOP       = $00000010;  
sc_SND_NOWAIT       = $00002000; 
sc_SND_ALIAS        = $00010000; 
sc_SND_ALIAS_ID     = $00110000; 
sc_SND_FILENAME     = $00020000; 
sc_SND_RESOURCE     = $00040004; 
sc_SND_PURGE        = $00000040;  
sc_SND_APPLICATION  = $00000080;  

sc_TIME_ONESHOT              = $0000;
sc_TIME_PERIODIC             = $0001;
sc_TIME_CALLBACK_FUNCTION    = $0000;
sc_TIME_CALLBACK_EVENT_SET   = $0010;
sc_TIME_CALLBACK_EVENT_PULSE = $0020;
sc_TIME_KILL_SYNCHRONOUS     = $0100;

type

sc_mmresult = sc_uint; { mm function result }
sc_hmidiout = integer; { handle to midi output }
sc_hmodule = integer; { handle to executable file }
sc_mcierror = integer; { error from mci function }

function sc_joysetcapture(wh: integer; di: integer; pt: integer; c: boolean)
   : integer; external;
function sc_joyreleasecapture(di: integer): integer; external;
function sc_joygetnumdevs: integer; external;
function sc_midioutgetnumdevs: sc_uint; external;
function sc_midioutopen_nnn(var h: sc_hmidiout; id: integer): sc_mmresult;
   external;
function sc_midioutclose(h: sc_hmidiout): sc_mmresult; external;
function sc_midioutshortmsg(h: sc_hmidiout; msg: sc_dword): sc_mmresult;
   external;
function sc_playsound(view s: string; h: sc_hmodule; f: sc_dword): boolean;
   external;
function sc_mcisendstring_nnn(view s: string): sc_mcierror; external;
function sc_timegettime: sc_dword; external;
function sc_timekillevent(tid: sc_uint): sc_mmresult; external;
function sc_timesetevent(d, r: sc_uint;
   procedure tp(id, m: sc_uint; u, dw1, dw2: sc_dword); u: sc_dword;
   f: sc_uint): sc_mmresult; external;

begin
end.
