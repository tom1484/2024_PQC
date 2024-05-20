	.arch armv8-a
	.text

# Macro add32_o
    .macro add32_o, dst, dst_offset, src1, src1_offset, src2, src2_offset
    ldr w12, [\src1, \src1_offset]
    ldr w13, [\src2, \src2_offset]
    adcs w14, w12, w13
    str w14, [\dst, \dst_offset]
    .endm
# End of Macro add32_o

# Macro add64_o
    .macro add64_o, dst, dst_offset, src1, src1_offset, src2, src2_offset
    add32_o \dst, \dst_offset, \src1, \src1_offset, \src2, \src2_offset
    add32_o \dst, \dst_offset + 4, \src1, \src1_offset + 4, \src2, \src2_offset + 4
    .endm
# End of Macro add64_o

# Macro add64
    .macro add64, dst, src1, src2
    add64_o \dst, 0, \src1, 0, \src2, 0
    .endm
# End of Macro add64

# Macro add128_o
    .macro add128_o, dst, dst_offset, src1, src1_offset, src2, src2_offset
    add64_o \dst, \dst_offset, \src1, \src1_offset, \src2, \src2_offset
    add64_o \dst, \dst_offset + 8, \src1, \src1_offset + 8, \src2, \src2_offset + 8
    .endm
# End of Macro add128_o

# Macro add128
    .macro add128, dst, src1, src2
    add128_o \dst, 0, \src1, 0, \src2, 0
    .endm
# End of Macro add128

# Macro add256_o
    .macro add256_o, dst, dst_offset, src1, src1_offset, src2, src2_offset
    add128_o \dst, \dst_offset, \src1, \src1_offset, \src2, \src2_offset
    add128_o \dst, \dst_offset + 16, \src1, \src1_offset + 16, \src2, \src2_offset + 16
    .endm
# End of Macro add256_o

# Macro add256
    .macro add256, dst, src1, src2
    add256_o \dst, 0, \src1, 0, \src2, 0
    .endm
# End of Macro add256

# Macro cpw
    .macro cpw, dst, dst_offset, src, src_offset
    ldr    w12, [\src, \src_offset]
    str    w12, [\dst, \dst_offset]
    .endm
# End of Macro memcpy

# Macro reserve_stack_pre
    .macro reserve_stack_pre, size
    sub    sp, sp, (32 + \size)
    stp    x29, x30, [sp, (16 + \size)]
    .endm
# End of Macro reserve_stack_pre

# Macro reserve_stack_post
    .macro reserve_stack_post, size
    ldp    x29, x30, [sp, (16 + \size)]
    add    sp, sp, (32 + \size)
    .endm
# End of Macro reserve_stack_post

# Macro push_reg
    .macro push_reg
    str x0, [sp, (8 * 0)]
    str x1, [sp, (8 * 1)]
    str x2, [sp, (8 * 2)]
    str x3, [sp, (8 * 3)]
    str x4, [sp, (8 * 4)]
    str x5, [sp, (8 * 5)]
    str x6, [sp, (8 * 6)]
    str x7, [sp, (8 * 7)]
    str x8, [sp, (8 * 8)]
    str x9, [sp, (8 * 9)]
    str x10, [sp, (8 * 10)]
    str x11, [sp, (8 * 11)]
    .endm
# End of Macro push_reg

# Macro pop_reg
    .macro pop_reg
    ldr x0, [sp, (8 * 0)]
    ldr x1, [sp, (8 * 1)]
    ldr x2, [sp, (8 * 2)]
    ldr x3, [sp, (8 * 3)]
    ldr x4, [sp, (8 * 4)]
    ldr x5, [sp, (8 * 5)]
    ldr x6, [sp, (8 * 6)]
    ldr x7, [sp, (8 * 7)]
    ldr x8, [sp, (8 * 8)]
    ldr x9, [sp, (8 * 9)]
    ldr x10, [sp, (8 * 10)]
    ldr x11, [sp, (8 * 11)]
    .endm
# End of Macro pop_reg

# Function _mult256
    .align	2
	.global	mult256
	.type	mult256, %function
mult256:
    #  input 0: _r0
    #  input 1: _r1
    # output 0: _r2 (low bits)
    # output 1: _r3 (high bits)

    #  x0:    a = [a0, a1]
    #  x1:    b = [b0, b1]
    #  x2:    c = [c0, c1]
    #  x3:    d = [d0, d1]

    #  x4:  i00 = a0 * b0
    #  x5:  i01 = a0 * b1
    #  x6:  i10 = a1 * b0
    #  x7:  i11 = a1 * b1

    #  x8: i010 = i01 * H
    #  x9: i011 = i01 / H
    # x10: i100 = i10 * H
    # x11: i101 = i10 / H

    # [c, d] =           (a1 * a1) * W
    #        + (a0 * b1 + a1 * b0) * H
    #        +           (a0 * b0) * 1

    # c = i00 + i010 + i100
    # d = i11 + i011 + i101

    .cfi_startproc
    reserve_stack_pre (8 * 12)

    # virtual zero
    adrp x15, _zero
    add x15, x15, :lo12:_zero

    adrp x14, tmp256
    add x14, x14, :lo12:tmp256

    # initialize registers
    add x4, x14, (32 * 0)
    add x5, x14, (32 * 1)
    add x6, x14, (32 * 2)
    add x7, x14, (32 * 3)
    add x8, x14, (32 * 4)
    add x9, x14, (32 * 5)
    add x10, x14, (32 * 6)
    add x11, x14, (32 * 7)

    # zerofill
    str xzr, [x14, (8 * 0)]
    str xzr, [x14, (8 * 1)]
    str xzr, [x14, (8 * 2)]
    str xzr, [x14, (8 * 3)]
    str xzr, [x14, (8 * 4)]
    str xzr, [x14, (8 * 5)]
    str xzr, [x14, (8 * 6)]
    str xzr, [x14, (8 * 7)]
    str xzr, [x14, (8 * 8)]
    str xzr, [x14, (8 * 9)]
    str xzr, [x14, (8 * 10)]
    str xzr, [x14, (8 * 11)]
    str xzr, [x14, (8 * 12)]
    str xzr, [x14, (8 * 13)]
    str xzr, [x14, (8 * 14)]
    str xzr, [x14, (8 * 15)]
    str xzr, [x14, (8 * 16)]
    str xzr, [x14, (8 * 17)]
    str xzr, [x14, (8 * 18)]
    str xzr, [x14, (8 * 19)]
    str xzr, [x14, (8 * 20)]
    str xzr, [x14, (8 * 21)]
    str xzr, [x14, (8 * 22)]
    str xzr, [x14, (8 * 23)]
    str xzr, [x14, (8 * 24)]
    str xzr, [x14, (8 * 25)]
    str xzr, [x14, (8 * 26)]
    str xzr, [x14, (8 * 27)]
    str xzr, [x14, (8 * 28)]
    str xzr, [x14, (8 * 29)]
    str xzr, [x14, (8 * 30)]
    str xzr, [x14, (8 * 31)]

    # calculate i00 = a0 * b0
    push_reg
    add x0, x0, 0
    add x1, x1, 0
    add x2, x4, 0
    add x3, x4, 16
    bl mult128
    pop_reg

    # calculate i01 = a0 * b1
    push_reg
    add x0, x0, 0
    add x1, x1, 16
    add x2, x5, 0
    add x3, x5, 16
    bl mult128
    pop_reg

    # calculate i10 = a1 * b0
    push_reg
    add x0, x0, 16
    add x1, x1, 0
    add x2, x6, 0
    add x3, x6, 16
    bl mult128
    pop_reg

    # calculate i11 = a1 * b1
    push_reg
    add x0, x0, 16
    add x1, x1, 16
    add x2, x7, 0
    add x3, x7, 16
    bl mult128
    pop_reg

    # calculate i010 = i01 * H
    cpw x8, 16, x5, 0
    cpw x8, 20, x5, 4
    cpw x8, 24, x5, 8
    cpw x8, 28, x5, 12

    # calculate i011 = i01 / H
    cpw x9, 0, x5, 16
    cpw x9, 4, x5, 20
    cpw x9, 8, x5, 24
    cpw x9, 12, x5, 28

    # calculate i100 = i10 * H
    cpw x10, 16, x6, 0
    cpw x10, 20, x6, 4
    cpw x10, 24, x6, 8
    cpw x10, 28, x6, 12

    # calculate i101 = i10 / H
    cpw x11, 0, x6, 16
    cpw x11, 4, x6, 20
    cpw x11, 8, x6, 24
    cpw x11, 12, x6, 28

    # clear carry flag
    adcs xzr, xzr, xzr

    # calculate d = i11 + i011 + i101
    add256 x3, x7, x9
    add256 x3, x3, x11

    # calculate c = i00 + i010 + i100
    add256 x2, x4, x8
    b.CC .+4
        add256 x3, x3, x15
    add256 x2, x2, x10
    b.CC .+4
        add256 x3, x3, x15

    reserve_stack_post (8 * 12)
    ret
    .cfi_endproc
    .size	mult256, .-mult256
# End of Function mult256

# Function mult128
    .align	2
	.global	mult128
	.type	mult128, %function
mult128:
    .cfi_startproc
    reserve_stack_pre (8 * 12)

    adrp x14, tmp128
    add x14, x14, :lo12:tmp128

    # initialize registers
    add x4, x14, (16 * 0)
    add x5, x14, (16 * 1)
    add x6, x14, (16 * 2)
    add x7, x14, (16 * 3)
    add x8, x14, (16 * 4)
    add x9, x14, (16 * 5)
    add x10, x14, (16 * 6)
    add x11, x14, (16 * 7)

    # zerofill
    str xzr, [x14, (8 * 0)]
    str xzr, [x14, (8 * 1)]
    str xzr, [x14, (8 * 2)]
    str xzr, [x14, (8 * 3)]
    str xzr, [x14, (8 * 4)]
    str xzr, [x14, (8 * 5)]
    str xzr, [x14, (8 * 6)]
    str xzr, [x14, (8 * 7)]
    str xzr, [x14, (8 * 8)]
    str xzr, [x14, (8 * 9)]
    str xzr, [x14, (8 * 10)]
    str xzr, [x14, (8 * 11)]
    str xzr, [x14, (8 * 12)]
    str xzr, [x14, (8 * 13)]
    str xzr, [x14, (8 * 14)]
    str xzr, [x14, (8 * 15)]

    # calculate i00 = a0 * b0
    push_reg
    add x0, x0, 0
    add x1, x1, 0
    add x2, x4, 0
    add x3, x4, 8
    bl mult64
    pop_reg

    # calculate i01 = a0 * b1
    push_reg
    add x0, x0, 0
    add x1, x1, 8
    add x2, x5, 0
    add x3, x5, 8
    bl mult64
    pop_reg

    # calculate i10 = a1 * b0
    push_reg
    add x0, x0, 8
    add x1, x1, 0
    add x2, x6, 0
    add x3, x6, 8
    bl mult64
    pop_reg

    # calculate i11 = a1 * b1
    push_reg
    add x0, x0, 8
    add x1, x1, 8
    add x2, x7, 0
    add x3, x7, 8
    bl mult64
    pop_reg

    # calculate i010 = i01 * H
    cpw x8, 8, x5, 0
    cpw x8, 12, x5, 4

    # calculate i011 = i01 / H
    cpw x9, 0, x5, 8
    cpw x9, 4, x5, 12

    # calculate i100 = i10 * H
    cpw x10, 8, x6, 0
    cpw x10, 12, x6, 4

    # calculate i101 = i10 / H
    cpw x11, 0, x6, 8
    cpw x11, 4, x6, 12

    # clear carry flag
    adcs xzr, xzr, xzr

    # calculate d = i11 + i011 + i101
    add128 x3, x7, x9
    add128 x3, x3, x11

    # calculate c = i00 + i010 + i100
    add128 x2, x4, x8
    b.CC .+4
        add128 x3, x3, x15
    add128 x2, x2, x10
    b.CC .+4
        add128 x3, x3, x15

    reserve_stack_post (8 * 12)
    ret
    .cfi_endproc
    .size	mult128, .-mult128
# End of Function mult128

# Function mult64
    .align	2
	.global	mult64
	.type	mult64, %function
mult64:
    .cfi_startproc
    reserve_stack_pre (8 * 12)

    adrp x14, tmp64
    add x14, x14, :lo12:tmp64

    # initialize registers
    add x4, x14, (8 * 0)
    add x5, x14, (8 * 1)
    add x6, x14, (8 * 2)
    add x7, x14, (8 * 3)
    add x8, x14, (8 * 4)
    add x9, x14, (8 * 5)
    add x10, x14, (8 * 6)
    add x11, x14, (8 * 7)

    # zerofill
    str xzr, [x14, (8 * 0)]
    str xzr, [x14, (8 * 1)]
    str xzr, [x14, (8 * 2)]
    str xzr, [x14, (8 * 3)]
    str xzr, [x14, (8 * 4)]
    str xzr, [x14, (8 * 5)]
    str xzr, [x14, (8 * 6)]
    str xzr, [x14, (8 * 7)]

    # calculate i00 = a0 * b0
    push_reg
    add x0, x0, 0
    add x1, x1, 0
    add x2, x4, 0
    add x3, x4, 4
    bl mult32
    pop_reg

    # calculate i01 = a0 * b1
    push_reg
    add x0, x0, 0
    add x1, x1, 4
    add x2, x5, 0
    add x3, x5, 4
    bl mult32
    pop_reg

    # calculate i10 = a1 * b0
    push_reg
    add x0, x0, 4
    add x1, x1, 0
    add x2, x6, 0
    add x3, x6, 4
    bl mult32
    pop_reg

    # calculate i11 = a1 * b1
    push_reg
    add x0, x0, 4
    add x1, x1, 4
    add x2, x7, 0
    add x3, x7, 4
    bl mult32
    pop_reg

    # calculate i010 = i01 * H
    cpw x8, 4, x5, 0

    # calculate i011 = i01 / H
    cpw x9, 0, x5, 4

    # calculate i100 = i10 * H
    cpw x10, 4, x6, 0

    # calculate i101 = i10 / H
    cpw x11, 0, x6, 4

    # clear carry flag
    adcs xzr, xzr, xzr

    # calculate d = i11 + i011 + i101
    add64 x3, x7, x9
    add64 x3, x3, x11

    # calculate c = i00 + i010 + i100
    add64 x2, x4, x8
    b.CC .+4
        add64 x3, x3, x15
    add64 x2, x2, x10
    b.CC .+4
        add64 x3, x3, x15

    reserve_stack_post (8 * 12)
    ret
    .cfi_endproc
    .size	mult64, .-mult64
# End of Function mult64

# Function mult32
    .align	2
	.global	mult32
	.type	mult32, %function
mult32:
    .cfi_startproc

    ldr w4, [x0]
    ldr w5, [x1]
    # This is equivalent to using two 32-bit multiplication
    # I don't find proper instructions of aarch64 to replace
    umull x6, w4, w5
    lsr x7, x6, 32
    str w6, [x2]
    str w7, [x3]

    ret
    .cfi_endproc
    .size	mult32, .-mult32
# End of Function mult32

    .bss
	.align	3
	.type	_zero, %object
	.size	_zero, 256
_zero:
	.zero	256

	.align	3
	.type	tmp64, %object
	.size	tmp64, 64
tmp64:
	.zero	64

	.align	3
	.type	tmp128, %object
	.size	tmp128, 128
tmp128:
	.zero	128

	.align	3
	.type	tmp256, %object
	.size	tmp256, 256
tmp256:
	.zero	256
