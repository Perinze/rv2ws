	.file	"table.c"
	.option nopic
	.attribute arch, "rv64i2p1_m2p0_a2p1_f2p2_d2p2_c2p0_zicsr2p0_zifencei2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	1
	.globl	readTargetCount
	.type	readTargetCount, @function
readTargetCount:
	bne	a2,zero,.L3
	subw	a1,a1,a0
	lui	a5,%hi(.LANCHOR0)
	srliw	a1,a1,2
	addi	a5,a5,%lo(.LANCHOR0)
	add	a5,a5,a1
	lbu	a0,0(a5)
	ret
.L3:
	subw	a1,a1,a0
	lui	a5,%hi(.LANCHOR0+2000)
	srliw	a1,a1,2
	addi	a5,a5,%lo(.LANCHOR0+2000)
	add	a5,a5,a1
	lbu	a0,0(a5)
	ret
	.size	readTargetCount, .-readTargetCount
	.align	1
	.globl	incrTargetCount
	.type	incrTargetCount, @function
incrTargetCount:
	bne	a2,zero,.L7
	lui	a5,%hi(.LANCHOR0)
	subw	a1,a1,a0
	addi	a5,a5,%lo(.LANCHOR0)
	srliw	a1,a1,2
	add	a5,a5,a1
	lbu	a4,0(a5)
	addiw	a4,a4,1
	sb	a4,0(a5)
	ret
.L7:
	lui	a5,%hi(.LANCHOR0+2000)
	subw	a1,a1,a0
	addi	a5,a5,%lo(.LANCHOR0+2000)
	srliw	a1,a1,2
	add	a5,a5,a1
	lbu	a4,0(a5)
	addiw	a4,a4,1
	sb	a4,0(a5)
	ret
	.size	incrTargetCount, .-incrTargetCount
	.align	1
	.globl	generateTargetTable
	.type	generateTargetTable, @function
generateTargetTable:
	lw	a5,0(a0)
	li	a4,-1
	mv	a1,a0
	beq	a5,a4,.L8
	lui	t3,%hi(.LANCHOR0)
	addi	t3,t3,%lo(.LANCHOR0)
	li	t4,4096
	li	a7,99
	li	t1,1
	li	t6,-4096
	addi	t5,t3,2000
	addi	t4,t4,-2048
	li	a6,-1
	j	.L15
.L23:
	addw	a5,a2,a4
	mv	a4,t5
.L14:
	subw	a5,a5,a0
	srliw	a5,a5,2
	add	a5,a4,a5
	lbu	a4,0(a5)
	addiw	a4,a4,1
	sb	a4,0(a5)
.L22:
	lw	a5,4(a1)
	addi	a1,a1,4
	beq	a5,a6,.L8
.L15:
	srliw	a3,a5,25
	srliw	a4,a5,7
	slliw	a3,a3,5
	andi	a2,a5,127
	andi	a3,a3,2016
	srliw	a5,a5,31
	andi	t0,a4,1
	bne	a2,a7,.L22
	andi	a4,a4,31
	beq	t0,zero,.L12
	or	a4,a4,t4
.L12:
	andi	a4,a4,-2018
	sext.w	a2,a1
	or	a4,a4,a3
	bne	a5,t1,.L23
	or	a4,a4,t6
	addw	a5,a4,a2
	mv	a4,t3
	j	.L14
.L8:
	ret
	.size	generateTargetTable, .-generateTargetTable
	.globl	backward_count
	.globl	forward_count
	.bss
	.align	3
	.set	.LANCHOR0,. + 0
	.type	backward_count, @object
	.size	backward_count, 2000
backward_count:
	.zero	2000
	.type	forward_count, @object
	.size	forward_count, 2000
forward_count:
	.zero	2000
	.ident	"GCC: (Arch Linux Repositories) 12.2.0"
