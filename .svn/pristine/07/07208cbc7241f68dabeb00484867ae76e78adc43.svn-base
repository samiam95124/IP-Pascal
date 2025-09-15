{*******************************************************************************
*                                                                              *
*                                STARTUP INTERFACE                             *
*                      														                *
*                              COPYRIGHT (C) 2007                              *
*                                  S. A. MOORE                                 *
*                                                                              *
* This module only serves the purpose of declaring the screen array for I/O.   *
*                                                                              *
*******************************************************************************}

module startup;

uses stddef;

{ each character }

type scnchr = record

                 chr: char; { character at location }
			     atr: byte { attribute }

              end;

{ screen }

var screen: array [1..25, 1..80] of scnchr;

begin
end.

                 
