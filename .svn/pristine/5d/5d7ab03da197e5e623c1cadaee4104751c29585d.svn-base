{******************************************************************************
*                                                                             *
*                           DEVICE CALL MODULE                                *
*                                                                             *
*                     COPYRIGHT (C) 2007 S. A. MOORE                          *
*                                                                             *
* Gives the ability to turn procedures in a driver into pointers, and the     *
* ability to then call those pointers.                                        *
*                                                                             *
* This is the header file for this module. The code is in the assembly file   *
* devcal.asm.                                                                 *
*                                                                             *
******************************************************************************}

module devcal;

uses stddef; { some standard defines }

type

   devcal_pp = ^integer; { pointer used to keep procedure address }

   { device errors }

   deverr = (de_none, { no error }
             de_nrdy, { device not ready (no media in device) }
             de_eof,  { end of device encountered }
             de_istm, { specified operation is illegal on stream device }
             de_prm,  { device encountered unclearable fault }
             de_wrt,  { cannot write this device }
             de_red); { cannot read this device }
                 
{ Procedures to get address of device procedure.
  These MUST be top level procedures! }

procedure devcal_read_ptr(procedure device_read(var ba: bytarr; pos: integer; 
                                                var err: deverr);
                          var pp: devcal_pp); external;
procedure devcal_write_ptr(procedure device_write(view ba: bytarr; pos: integer; 
                                                var err: deverr);
                          var pp: devcal_pp); external;
procedure devcal_length_ptr(procedure device_length(var pos: integer; 
                                                    var err: deverr);
                          var pp: devcal_pp); external;

{ procedures to call device procedures }

procedure devcal_read(var ba: bytarr; pos: integer; var err: deverr; 
                      pp: devcal_pp); external;
procedure devcal_write(view ba: bytarr; pos: integer; var err: deverr; 
                       pp: devcal_pp); external;
procedure devcal_length(var pos: integer; var err: deverr; 
                        pp: devcal_pp); external;

begin
end.