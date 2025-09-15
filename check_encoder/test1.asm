	pushd 	$00000f3f ! load truncate control code
	mov 	eax,esp   ! have to load via memory
	fldcw 	[eax] 
	pop 	eax 	  ! remove from stack

	mov 	eax,esp   ! get real from stack
	fldd 	[eax] 

        fldl2e
        fmulp             ! ex
        fld     st(0)     ! ex ex
        frndint           ! exI ex
        fsubr   st(1),st  ! exI exF exF -1..1
        fxch              ! exF exI
        f2xm1             ! 2^exF-1
        fld1
        faddp             ! 2^exF exI
        fscale            ! exp exI
        fxch
        fstp    st(0)                

	fstpd 	[eax] 	! store back to stack
	fwait 

