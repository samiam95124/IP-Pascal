@echo off
rem
rem Iterate through encoder options
rem
rem This test compiles the standard.pas test, with all of the individual options
rem set and reset, then runs the standard, then compares the output to a reference.
rem
call cmpcom v
call cmpcom ac
call cmpcom nac
call cmpcom t
call cmpcom nt
call cmpcom pv
call cmpcom npv
call cmpcom rc
call cmpcom nrc
call cmpcom oc
call cmpcom noc
call cmpcom cc
call cmpcom ncc
call cmpcom clcl
call cmpcom nclcl
call cmpcom cgbl
call cmpcom ncgbl
call cmpcom bi
call cmpcom nbi
call cmpcom sls
call cmpcom nsls
call cmpcom url
call cmpcom nurl
call cmpcom fco
call cmpcom nfco
call cmpcom cfc
call cmpcom ncfc
call cmpcom dce
call cmpcom ndce
call cmpcom b2j
call cmpcom nb2j
call cmpcom rur
call cmpcom nrur
call cmpcom npc
call cmpcom nnpc
