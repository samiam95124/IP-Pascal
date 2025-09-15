{******************************************************************************
*                                                                             *
*                               SOUND LIBRARY                                 *
*                                                                             *
*                              11/02 S. A. Moore                              *
*                                                                             *
* Sndlib is a combination of wave file and midi output and control functions. *
*                                                                             *
******************************************************************************}

module sndlib;

uses stddef,
     extlib;

const

chan_drum = 10; { the GM drum channel }

synth_out = 1; { the default output synth for host }
synth_ext = 2; { the default output to external synth }

{ the notes in the lowest octave }

note_c       = 1;
note_c_sharp = 2;
note_d_flat  = 2;
note_d       = 3;
note_d_sharp = 4;
note_e_flat  = 4;
note_e       = 5;
note_f       = 6;
note_f_sharp = 7;
note_g_flat  = 7;
note_g       = 8;
note_g_sharp = 9;
note_a_flat  = 9;
note_a       = 10;
note_a_sharp = 11;
note_b_flat  = 11;
note_b       = 12;

{ the octaves of midi, add to note to place in that octave }

octave_1  = 0;   
octave_2  = 12;  
octave_3  = 24;  
octave_4  = 36;  
octave_5  = 48;  
octave_6  = 60;  
octave_7  = 72;  
octave_8  = 84;  
octave_9  = 96;  
octave_10 = 108; 
octave_11 = 120;

{ Standard GM instruments }

{ Piano }

inst_acoustic_grand        = 1;
inst_bright_acoustic       = 2;
inst_electric_grand        = 3;
inst_honky_tonk            = 4;
inst_electric_piano_1      = 5;
inst_electric_piano_2      = 6;
inst_harpsichord           = 7;
inst_clavinet              = 8;

{ Chromatic percussion }

inst_celesta               = 9;
inst_glockenspiel          = 10;
inst_music_box             = 11;
inst_vibraphone            = 12;
inst_marimba               = 13;
inst_xylophone             = 14;
inst_tubular_bells         = 15;
inst_dulcimer              = 16;

{ Organ }
                         
inst_drawbar_organ         = 17;
inst_percussive_organ      = 18;
inst_rock_organ            = 19;
inst_church_organ          = 20;
inst_reed_organ            = 21;
inst_accoridan             = 22;
inst_harmonica             = 23;
inst_tango_accordian       = 24;

{ Guitar }

inst_nylon_string_guitar   = 25;
inst_steel_string_guitar   = 26;
inst_electric_jazz_guitar  = 27;
inst_electric_clean_guitar = 28;
inst_electric_muted_guitar = 29;
inst_overdriven_guitar     = 30;
inst_distortion_guitar     = 31;
inst_guitar_harmonics      = 32;

{ Bass }

inst_acoustic_bass         = 33;
inst_electric_bass_finger  = 34;
inst_electric_bass_pick    = 35;
inst_fretless_bass         = 36;
inst_slap_bass_1           = 37;
inst_slap_bass_2           = 38;
inst_synth_bass_1          = 39;
inst_synth_bass_2          = 40;

{ Solo strings }

inst_violin                = 41;
inst_viola                 = 42;
inst_cello                 = 43;
inst_contrabass            = 44;
inst_tremolo_strings       = 45;
inst_pizzicato_strings     = 46;
inst_orchestral_strings    = 47;
inst_timpani               = 48;

{ Ensemble }

inst_string_ensemble_1     = 49;
inst_string_ensemble_2     = 50;
inst_synthstrings_1        = 51;
inst_synthstrings_2        = 52;
inst_choir_aahs            = 53;
inst_voice_oohs            = 54;
inst_synth_voice           = 55;
inst_orchestra_hit         = 56;

{ Brass }

inst_trumpet               = 57;
inst_trombone              = 58;
inst_tuba                  = 59;
inst_muted_trumpet         = 60;
inst_french_horn           = 61;
inst_brass_section         = 62;
inst_synthbrass_1          = 63;
inst_synthbrass_2          = 64;

{ Reed }
                        
inst_soprano_sax           = 65;
inst_alto_sax              = 66;
inst_tenor_sax             = 67;
inst_baritone_sax          = 68;
inst_oboe                  = 69;
inst_english_horn          = 70;
inst_bassoon               = 71;
inst_clarinet              = 72;

{ Pipe }

inst_piccolo               = 73;
inst_flute                 = 74;
inst_recorder              = 75;
inst_pan_flute             = 76;
inst_blown_bottle          = 77;
inst_skakuhachi            = 78;
inst_whistle               = 79;
inst_ocarina               = 80;

{ Synth lead }
                   
inst_lead_1_square         = 81;
inst_lead_2_sawtooth       = 82;
inst_lead_3_calliope       = 83;
inst_lead_4_chiff          = 84;
inst_lead_5_charang        = 85;
inst_lead_6_voice          = 86;
inst_lead_7_fifths         = 87;
inst_lead_8_bass_lead      = 88;

{ Synth pad }

inst_pad_1_new_age         = 89;
inst_pad_2_warm            = 90;
inst_pad_3_polysynth       = 91;
inst_pad_4_choir           = 92;
inst_pad_5_bowed           = 93;
inst_pad_6_metallic        = 94;
inst_pad_7_halo            = 95;
inst_pad_8_sweep           = 96;

{ Synth effects }

inst_fx_1_rain             = 97;
inst_fx_2_soundtrack       = 98;
inst_fx_3_crystal          = 99;
inst_fx_4_atmosphere       = 100;
inst_fx_5_brightness       = 101;
inst_fx_6_goblins          = 102;
inst_fx_7_echoes           = 103;
inst_fx_8_sci_fi           = 104;

{ Ethnic }

inst_sitar                 = 105;
inst_banjo                 = 106;
inst_shamisen              = 107;
inst_koto                  = 108;
inst_kalimba               = 109;
inst_bagpipe               = 110;
inst_fiddle                = 111;
inst_shanai                = 112;

{ Percussive }

inst_tinkle_bell           = 113;
inst_agogo                 = 114;
inst_steel_drums           = 115;
inst_woodblock             = 116;
inst_taiko_drum            = 117;
inst_melodic_tom           = 118;
inst_synth_drum            = 119;
inst_reverse_cymbal        = 120;

{ Sound effects }

inst_guitar_fret_noise     = 121;
inst_breath_noise          = 122;
inst_seashore              = 123;
inst_bird_tweet            = 124;
inst_telephone_ring        = 125;
inst_helicopter            = 126;
inst_applause              = 127;
inst_gunshot               = 128;

{ Drum sounds, activated as notes to drum instruments }

note_acoustic_bass_drum = 35;      
note_bass_drum_1        = 36;     
note_side_stick         = 37;      
note_acoustic_snare     = 38;      
note_hand_clap          = 39;     
note_electric_snare     = 40;      
note_low_floor_tom      = 41;     
note_closed_hi_hat      = 42;     
note_high_floor_tom     = 43;     
note_pedal_hi_hat       = 44;     
note_low_tom            = 45;     
note_open_hi_hat        = 46;     
note_low_mid_tom        = 47;     
note_hi_mid_tom         = 48;     
note_crash_cymbal_1     = 49;     
note_high_tom           = 50;     
note_ride_cymbal_1      = 51;     
note_chinese_cymbal     = 52;     
note_ride_bell          = 53;     
note_tambourine         = 54;     
note_splash_cymbal      = 55;     
note_cowbell            = 56;     
note_crash_cymbal_2     = 57;     
note_vibraslap          = 58;   
note_ride_cymbal_2      = 59;   
note_hi_bongo           = 60;   
note_low_bongo          = 61;   
note_mute_hi_conga      = 62;   
note_open_hi_conga      = 63;   
note_low_conga          = 64;   
note_high_timbale       = 65;   
note_low_timbale        = 66;   
note_high_agogo         = 67;   
note_low_agogo          = 68;   
note_cabasa             = 69;   
note_maracas            = 70;   
note_short_whistle      = 71;   
note_long_whistle       = 72;   
note_short_guiro        = 73;   
note_long_guiro         = 74;   
note_claves             = 75;   
note_hi_wood_block      = 76;   
note_low_wood_block     = 77;   
note_mute_cuica         = 78;   
note_open_cuica         = 79;   
note_mute_triangle      = 80;   
note_open_triangle      = 81;   

type

note       = 0..127; { note number for midi }
channel    = 1..16;  { channel number }
instrument = 1..128; { instrument number }

{ functions at this level }

procedure starttime; external;
procedure stoptime; external;
function curtime: integer; external;
function synthout: integer; external;
procedure opensynthout(p: integer); external;
procedure closesynthout(p: integer); external;
procedure noteon(p, t: integer; c: channel; n: note; v: integer); external;
procedure noteoff(p, t: integer; c: channel; n: note; v: integer); external;
procedure instchange(p, t: integer; c: channel; i: instrument); external;
procedure attack(p, t: integer; c: channel; at: integer); external;
procedure release(p, t: integer; c: channel; rt: integer); external;
procedure legato(p, t: integer; c: channel; b: boolean); external;
procedure portamento(p, t: integer; c: channel; b: boolean); external;
procedure vibrato(p, t: integer; c: channel; v: integer); external;
procedure volsynthchan(p, t: integer; c: channel; v: integer); external;
procedure porttime(p, t: integer; c: channel; v: integer); external;
procedure balance(p, t: integer; c: channel; b: integer); external;
procedure pan(p, t: integer; c: channel; b: integer); external;
procedure timbre(p, t: integer; c: channel; tb: integer); external;
procedure brightness(p, t: integer; c: channel; b: integer); external;
procedure reverb(p, t: integer; c: channel; r: integer); external;
procedure tremulo(p, t: integer; c: channel; tr: integer); external;
procedure chorus(p, t: integer; c: channel; cr: integer); external;
procedure celeste(p, t: integer; c: channel; ce: integer); external;
procedure phaser(p, t: integer; c: channel; ph: integer); external;
procedure aftertouch(p, t: integer; c: channel; n: note; at: integer); external;
procedure pressure(p, t: integer; c: channel; n: note; pr: integer); external;
procedure pitch(p, t: integer; c: channel; pt: integer); external;
procedure pitchrange(p, t: integer; c: channel; v: integer); external;
procedure mono(p, t: integer; c: channel; ch: integer); external;
procedure poly(p, t: integer; c: channel); external;
procedure playsynth(p, t: integer; view sf: string); external;
function waveout: integer; external;
procedure openwaveout(p: integer); external;
procedure closewaveout(p: integer); external;
procedure playwave(p, t: integer; view sf: string); external;
procedure volwave(p, t, v: integer); external;

begin
end.
