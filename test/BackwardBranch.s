#-----------------------
# BackwardBranch.s
#   Test case with a simple backward branch
# Arguments:
#   a0: a positive number
# Return Value:
#   a0: 1 if the number is a multiple of 6, 0 otherwise.
#-----------------------

BackwardBranch:
       	addi	t0, zero, 6
subLoop:
       	sub	a0, a0, t0 
       	addi	t1, zero, 1
       	bge	a0, t1, subLoop
       	beq	a0, zero, isMultiple
        addi	a0, zero, -1
isMultiple:
	addi 	a0, a0, 1		
