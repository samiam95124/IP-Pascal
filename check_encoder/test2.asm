	pushd 	$00000f3f ! load truncate control code
	mov 	eax,esp   ! have to load via memory
	fldcw 	[eax] 
	pop 	eax 	  ! remove from stack

	mov 	eax,esp   ! get real from stack
	fldd 	[eax] 

        FLDL2E            ! PUSH LOG2E ONTO STACK
        FMUL              ! X*LOG2E IN ST
        FLD ST(0)         ! PUSH COPY INTO ST(1)
        FRNDINT           ! ROUND ST DOWN TO INTEGER (I.E. INTEGER PART)
        FST ST(2)         ! INTEGER PART INTO ST(2)
        FSUB ST(1),ST     ! D=X*LOG2E-[X*LOG2E] IN ST(1)
        FLD ST(1)         ! PUSH ST(1) INTO ST
        FLD1              ! PUSH 1 INTO ST
        FCHS              ! -1 IN ST
        FXCH              ! -1 IN ST(1), D IN ST
        FSCALE            ! W=D/2 IN ST
        F2XM1             ! 2**W-1 IN ST
        FLD1              ! PUSH 1 INTO ST
        FADD              ! V=2**W IN ST
        FMUL ST(0),ST(0)  ! V*V IN ST
        FLD ST(4)         ! PUSH [X*LOG2E] INTO ST
        FXCH              ! XCHANGE ST AND ST(1)
        FSCALE            ! 2**[X*LOG2E]*V*V

	fstpd 	[eax] 	! store back to stack
	fwait 

