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
	lui	a5,%hi(.LANCHOR0)
	addi	a5,a5,%lo(.LANCHOR0)
.L2:
	subw	a1,a1,a0
	srliw	a1,a1,2
	add	a5,a5,a1
	lbu	a0,0(a5)
	ret
.L3:
	lui	a5,%hi(.LANCHOR0+2000)
	addi	a5,a5,%lo(.LANCHOR0+2000)
	j	.L2
	.size	readTargetCount, .-readTargetCount
	.align	1
	.globl	incrTargetCount
	.type	incrTargetCount, @function
incrTargetCount:
	bne	a2,zero,.L6
	lui	a5,%hi(.LANCHOR0)
	addi	a5,a5,%lo(.LANCHOR0)
.L5:
	subw	a1,a1,a0
	srliw	a1,a1,2
	add	a5,a5,a1
	lbu	a4,0(a5)
	addiw	a4,a4,1
	sb	a4,0(a5)
	ret
.L6:
	lui	a5,%hi(.LANCHOR0+2000)
	addi	a5,a5,%lo(.LANCHOR0+2000)
	j	.L5
	.size	incrTargetCount, .-incrTargetCount
	.align	1
	.globl	generateTargetTable
	.type	generateTargetTable, @function
generateTargetTable:
	lw	a5,0(a0)
	li	a4,-1
	beq	a5,a4,.L17
	addi	sp,sp,-80
	sd	ra,72(sp)
	sd	s0,64(sp)
	sd	s1,56(sp)
	sd	s2,48(sp)
	sd	s3,40(sp)
	sd	s4,32(sp)
	sd	s5,24(sp)
	sd	s6,16(sp)
	sd	s7,8(sp)
	mv	s1,a0
	addi	s0,a0,4
	li	s3,99
	li	s4,1
	li	s7,-4096
	li	s6,0
	li	s5,4096
	addi	s5,s5,-2048
	li	s2,-1
	j	.L14
.L21:
	lw	a5,0(s0)
	j	.L10
.L11:
	srliw	a4,a5,25
	slliw	a4,a4,5
	andi	a4,a4,2016
	andi	a1,a1,-2018
	or	a1,a1,a4
	srliw	a5,a5,31
	beq	a5,s4,.L12
	sext.w	a5,a1
	mv	a2,s4
.L13:
	addiw	a1,s0,-4
	addw	a1,a1,a5
	mv	a0,s1
	call	incrTargetCount
	lw	a5,0(s0)
.L10:
	addi	s0,s0,4
	beq	a5,s2,.L20
.L14:
	andi	a4,a5,127
	bne	a4,s3,.L21
	srliw	a4,a5,7
	andi	a1,a4,31
	andi	a4,a4,1
	beq	a4,zero,.L11
	or	a1,a1,s5
	j	.L11
.L12:
	or	a1,a1,s7
	sext.w	a5,a1
	mv	a2,s6
	j	.L13
.L20:
	ld	ra,72(sp)
	ld	s0,64(sp)
	ld	s1,56(sp)
	ld	s2,48(sp)
	ld	s3,40(sp)
	ld	s4,32(sp)
	ld	s5,24(sp)
	ld	s6,16(sp)
	ld	s7,8(sp)
	addi	sp,sp,80
	jr	ra
.L17:
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
