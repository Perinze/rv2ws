#-------------------------------
# common.s
# Author:
# Date: July 14 2017
# 
# RISC-V Modification
# Author: 
# Date: 
#
# Module preamble and section info provided - necessary to create valid wasm module
# Note that modules are created as 'version 1', as WASM progresses in the future this
# may need to be updated
# The generated module always has 1 return value, translate from risv-v to wasm accordingly
#
# module notation:
# ***** - to be calculated for each particular module generated
#-------------------------------

    .data

    .align 2
binary: #space for the representation of the RISC-V input program
    .space 2052

modulePreamble:
    .byte 0x00, 0x61, 0x73, 0x6d, 0x01, 0x00, 0x00, 0x00 #8 bytes- preamble: '\0asm' magic number and version 1
typeSection:
    #sectionID
    .byte 0x01,
typeSectionSize:
    #sectionSize, numTypes, type - func
    .byte 0x09, 0x01, 0x60
typeSectionNumParams:
    #num params - allocate 4 up front
    .byte 0x04, 0x7f, 0x7f, 0x7f, 0x7f
typeSectionNumResults:
    #num results, returnType:i32
    .byte 0x01, 0x7f
functionSection:
    #sectionID, sectionSize, numFunctions, function 0 signature index
    .byte 0x03, 0x02, 0x01, 0x00
exportSection:
    #sectionID, sectionSize, numExports, stringLen, exportName (always 'main'), export kind, exportFunc index
    .byte 0x07, 0x08, 0x01, 0x04, 0x6d, 0x61, 0x69, 0x6e, 0x00, 0x00
codeSectionID:
    #sectionID
    .byte 0x0a
codeSectionSize:
    #sectionSize****(=funcBody size +6)
    .byte 0x7f, 0x80, 0x80, 0x80, 0x00
codeSectionFunNum:
    #numFunctions
    .byte 0x01
codeSectionFunSize:
    #funcBody size****
    .byte 0x7f, 0x80, 0x80, 0x80, 0x00
codeSectionVars:
    #local declaration count, local type count, local types
    .byte 0x01, 0x1b, 0x7f
codeSection:    #space where the representation of the generated WASM program is to be placed
    .space 2048

noFileStr:
    .asciz "Couldn't open specified file.\n"
createFileStr:
    .asciz "Couldn't create specified file.\n"
format:
    .asciz "\n"
outfile:        #all generated output files are named 'main.wasm'
    .asciz "main.wasm"

    .text
main:

    lw      a0, 0(a1)	        # Put the filename pointer into a0
    li      a1, 0		        # Read Only
    li      a7, 1024		    # Open File
    ecall
    bltz	a0, main_err	    # Negative means open failed

    la      a1, binary	        # write into my binary space
    li      a2, 2048	        # read a file of at max 2kb
    li      a7, 63		        # Read File System call
    ecall
    la      t0, binary
    add     t0, t0, a0	        #point to end of binary space

    li      t1, 0xFFFFFFFF	    #Place ending sentinel
    sw      t1, 0(t0)

    la      a0, binary
    la      a1, codeSection
    jal     ra, RISCVtoWASM
    mv      s0, a0              #number of bytes generated
    jal     ra, calcLengths
    mv      a0, s0
    jal     ra, writeFile

    jal     zero, main_done

main_err:
    la      a0, noFileStr
    li      a7, 4
    ecall

main_done:
    li      a7, 10
    ecall


#-------------------------------------------------------------------------------
# calcLengths 
# stores the length of the code Section size and the function 
# body size based on number of bytes student generates
#
# functional .wasm modules require that all sections within the module
# contain their size (in bytes) within their header.
# In this lab assignment the function and code section sizes
# are dependent on the size of the RISC-V program that was the
# translation source. These sizes are expected to be in LEB128 format (NOT DECIMAL).
#
# input:
#       a0: number of bytes student generated
#-------------------------------------------------------------------------------
calcLengths:
    addi    sp, sp, -20
    sw      ra, 0(sp)
    sw      s0, 4(sp)
    sw      s1, 8(sp)
    sw      s2, 12(sp)
    sw      s3, 16(sp)          #place to save a0

    mv      s3, a0
    li      s2, 4               #use this counter as a backup in case a1 is an invalid value, max store 4 bytes
    la      s0, codeSectionFunSize  #load first place where we need to store some module section size values
    addi    s3, s3, 3           #for the 3 bytes for local decl count, local type count, local types
    mv      a0, s3
    jal     ra, encodeLEB128    #call student function to translate the size of the function section
storeFunSection:
    andi    s1, a0, 0xff        #get the first byte in the result
    ori     s1, s1, 0x80        #always set the 'next' indicator in the LEB128 rep just so will be 4 bytes
    srli    a0, a0, 8           #prep the result to fetch next byte
    sb      s1, 0(s0)           #store one byte at a time in the module section that denotes the function size
    addi    s0, s0, 1
    addi    s2, s2, -1          #decrement the safety value
    addi    a1, a1, -1
    beq     s2, zero, doneStoreFunSection
    bne     a1, zero, storeFunSection   #use a1 as indication of how many relevant bytes to place

doneStoreFunSection:
    addi    s3, s3, 6           #6 guaranteed bytes specifying the function size - must incl in code section size
    mv      a0, s3
    jal     ra, encodeLEB128    #call student function to translate the size of the code section
    la      s0, codeSectionSize #load second place where we need to store some module section size values
    li      s2, 4               #reinitialize the safety value

storeCodeSection:
    andi    s1, a0, 0xff        #get the first byte in the result (for now)
    ori     s1, s1, 0x80        #always set the 'next' indicator in the LEB128 rep just so will be 4 bytes
    srli    a0, a0, 8
    sb      s1, 0(s0)           #store one byte at a time in the module section that denotes the code section size
    addi    s0, s0, 1
    addi    s2, s2, -1          #decrement the safety value
    addi    a1, a1, -1
    beq     s2, zero, doneStoreCodeSection
    bne     a1, zero, storeCodeSection  #use a1 as indication of how many relevant bytes to place

doneStoreCodeSection:
    lw      ra, 0(sp)
    lw      s0, 4(sp)
    lw      s1, 8(sp)
    lw      s2, 12(sp)
    lw      s3, 16(sp)
    addi    sp, sp, 20
    jalr    zero, ra, 0
#-------------------------------------------------------------------------------
# writeFile
# opens file and writes bytes from module preamble to 
# (number of bytes returned by students + number of bytes in the module preamble)
# 
# input:
#       a0: number of bytes total for the translation result, value provided by the student
#-------------------------------------------------------------------------------
writeFile:
    addi    sp, sp -8
    sw      s0, 0(sp)
    sw      s1, 4(sp)

    la      s0, codeSection
    la      s1, modulePreamble
    sub     s1, s0, s1          #calculate number of static provided bytes
    add     s1, s1, a0          #add in the number of bytes generated by student, as provided by student

    #open file
    la      a0, outfile         # filename for writing to
    li      a1, 1   		    # Write flag
    li      a7, 1024            # Open File
    ecall
    bltz	a0, writeOpenErr	# Negative means open failed
    mv      s0, a0
    #write to file
    mv      a0, s0
    la      a1, modulePreamble  # address of buffer from which to start the write from
    mv      a2, s1              # buffer length, as calculated previously
    li      a7, 64              # system call for write to file
    ecall                       # write to file
    #close file
    mv      a0, s0              # file descriptor to close
    li      a7, 57              # system call for close file
    ecall                       # close file
    jal     zero, writeFileDone

writeOpenErr:
    la      a0, createFileStr
    li      a7, 4
    ecall

writeFileDone:
    lw      s0, 0(sp)
    lw      s1, 4(sp)
    addi    sp, sp 8
    jalr    zero, ra, 0
#-------------------------------------end common--------------------------------------------