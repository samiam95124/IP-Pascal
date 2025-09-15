	pushd 	$00000f3f ! load truncate control code
	mov 	eax,esp   ! have to load via memory
	fldcw 	[eax] 
	pop 	eax 	  ! remove from stack

	mov 	eax,esp   ! get real from stack
	fldd 	[eax] 

	fldl2e 	          ! put ln(10) on stack
	fmulp 		  ! find x*ln(10)

	fld 	st(0) 	  ! duplicate tos twice
	fld 	st(0)
	frndint 	  ! compute integer portion
	fxch		  ! swap whole and int values
	fsubp 		  ! compute fractional part
	f2xm1             ! compute 2**frac(x)-1
	fld1
	faddp 		  ! compute 2**frac(x)
	fxch 		  ! get integer portion
	fld1
	fscale 
	fstp 	st(1) 	  ! remove st(1) (which is 1).
	fmulp 			  ! compute 2**int(x)
	fstpd 	[eax] 	  ! store back to stack
	fwait 
