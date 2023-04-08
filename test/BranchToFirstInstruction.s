#-----------------------
# BranchFirstInstruction.s
#   Test case with branch to the first instruction in the program
# Arguments:
#   a0: a number x 
# Return Value:
#   a0: 6 if x >= 7, otherwise x - 1
#-----------------------


BranchFirstInstruction:
	addi	a0, a0, -1
	addi	t0, zero, 7
	bge	a0, t0, BranchFirstInstruction
	sub	a0, a0, zero
