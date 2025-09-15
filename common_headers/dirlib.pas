{*******************************************************************************
*                                                                              *
*                          Directory handling library                          *
*                                                                              *
*                              2002/08/25                                      *
*                                                                              *
* Implements several directory list management functions. dirlib models        *
* directories as tree structured data, so all of the functions here are about  *
* creating a directory tree from the supplied specification, and managing one  *
* or more directory trees.                                                     *
*                                                                              *
* order        Sorts a file list for the specified ordering function.          *
* orderdirs    Sorts a directory list for the specified ordering function.     *
* chkdir       Returns true if the indicated file is a directory.              *
* merge        Merges two directory lists into one using names as key.         *
* filelist     Extends "list" with attribute and permission matching.          *
* treelist     Forms a full tree structured directory/file listing with        *
*              attribute and permission matching.                              *
*                                                                              *
*******************************************************************************}

module dirlib(output);

uses strlib,
     extlib;

type  dirptr = ^dirent; { pointer to directory record }
      dirent = record { directory head chains }
      
         name:  pstring; { name of directory (path) }
         files: filptr;  { files in directory }
         cnt:   integer; { number of files in list }
         tsize: integer; { total size of contained files }
         nmax:  integer; { maximum length in names }
         drop:  filptr;  { file entry directory was dropped from }
         next:  dirptr   { next entry in list }

      end;
      dirord = (onone, oalpha, osize, otime); { ordering types }

procedure order(var l: filptr; ordtyp: dirord; rev: boolean); external;
procedure orderdirs(var l: dirptr; ordtyp: dirord; rev: boolean); external;
function chkdir(view n: string): boolean; external;
procedure merge(var dlst: dirptr; slst: dirptr); external;
procedure join(var dlst: dirptr; slst: dirptr); external;
procedure filelist(view n: string; atrmsk, atrcmp: attrset; usrmsk, usrcmp,
                   grpmsk, grpcmp, othmsk, othcmp: permset;
                   var fl: filptr); external;
procedure treelist(view fn: string; expand, recurse: integer; marker: boolean;
                   atrmsk, atrcmp: attrset; usrmsk, usrcmp, grpmsk, grpcmp,
                   othmsk, othcmp: permset; var tree: dirptr); external;

begin

end.
