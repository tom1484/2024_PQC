    .section    __TEXT,__text,regular,pure_instructions
    .build_version macos, 14, 0    sdk_version 14, 4

; Macro add32_o
    .macro add32_o, dst, dst_offset, src1, src1_offset, src2, src2_offset
    ldr w12, [\src1, \src1_offset]
    ldr w13, [\src2, \src2_offset]
    adcs w14, w12, w13
    str w14, [\dst, \dst_offset]
    .endm
; End of Macro add32_o

; Macro add64_o
    .macro add64_o, dst, dst_offset, src1, src1_offset, src2, src2_offset
    add32_o \dst, \dst_offset, \src1, \src1_offset, \src2, \src2_offset
    add32_o \dst, \dst_offset + 4, \src1, \src1_offset + 4, \src2, \src2_offset + 4
    .endm
; End of Macro add64_o

; Macro add64
    .macro add64, dst, src1, src2
    add64_o \dst, #0, \src1, #0, \src2, #0
    .endm
; End of Macro add64

; Macro add128_o
    .macro add128_o, dst, dst_offset, src1, src1_offset, src2, src2_offset
    add64_o \dst, \dst_offset, \src1, \src1_offset, \src2, \src2_offset
    add64_o \dst, \dst_offset + 8, \src1, \src1_offset + 8, \src2, \src2_offset + 8
    .endm
; End of Macro add128_o

; Macro add128
    .macro add128, dst, src1, src2
    add128_o \dst, #0, \src1, #0, \src2, #0
    .endm
; End of Macro add128

; Macro add256_o
    .macro add256_o, dst, dst_offset, src1, src1_offset, src2, src2_offset
    add128_o \dst, \dst_offset, \src1, \src1_offset, \src2, \src2_offset
    add128_o \dst, \dst_offset + 16, \src1, \src1_offset + 16, \src2, \src2_offset + 16
    .endm
; End of Macro add256_o

; Macro add256
    .macro add256, dst, src1, src2
    add256_o \dst, #0, \src1, #0, \src2, #0
    .endm
; End of Macro add256

; Macro cpw
    .macro cpw, dst, dst_offset, src, src_offset
    ldr    w12, [\src, \src_offset]
    str    w12, [\dst, \dst_offset]
    .endm
; End of Macro memcpy

; Macro reserve_stack_pre
    .macro reserve_stack_pre, size
    sub    sp, sp, #(32 + \size)
    stp    x29, x30, [sp, #(16 + \size)]             ; 16-byte Folded Spill
    .endm
; End of Macro reserve_stack_pre

; Macro reserve_stack_post
    .macro reserve_stack_post, size
    ldp    x29, x30, [sp, #(16 + \size)]             ; 16-byte Folded Reload
    add    sp, sp, #(32 + \size)
    .endm
; End of Macro reserve_stack_post

; Macro push_reg
    .macro push_reg, data_size
    str x0, [sp, #(\data_size + 8 * 0)]
    str x1, [sp, #(\data_size + 8 * 1)]
    str x2, [sp, #(\data_size + 8 * 2)]
    str x3, [sp, #(\data_size + 8 * 3)]
    str x4, [sp, #(\data_size + 8 * 4)]
    str x5, [sp, #(\data_size + 8 * 5)]
    str x6, [sp, #(\data_size + 8 * 6)]
    str x7, [sp, #(\data_size + 8 * 7)]
    str x8, [sp, #(\data_size + 8 * 8)]
    str x9, [sp, #(\data_size + 8 * 9)]
    str x10, [sp, #(\data_size + 8 * 10)]
    str x11, [sp, #(\data_size + 8 * 11)]
    .endm
; End of Macro push_reg

; Macro pop_reg
    .macro pop_reg, data_size
    ldr x0, [sp, #(\data_size + 8 * 0)]
    ldr x1, [sp, #(\data_size + 8 * 1)]
    ldr x2, [sp, #(\data_size + 8 * 2)]
    ldr x3, [sp, #(\data_size + 8 * 3)]
    ldr x4, [sp, #(\data_size + 8 * 4)]
    ldr x5, [sp, #(\data_size + 8 * 5)]
    ldr x6, [sp, #(\data_size + 8 * 6)]
    ldr x7, [sp, #(\data_size + 8 * 7)]
    ldr x8, [sp, #(\data_size + 8 * 8)]
    ldr x9, [sp, #(\data_size + 8 * 9)]
    ldr x10, [sp, #(\data_size + 8 * 10)]
    ldr x11, [sp, #(\data_size + 8 * 11)]
    .endm
; End of Macro pop_reg

; Function _mult256
    .globl    _mult256
    .p2align    2
_mult256:
    ;  input 0: _r0
    ;  input 1: _r1
    ; output 0: _r2 (low bits)
    ; output 1: _r3 (high bits)

    ;  x0:    a = [a0, a1]
    ;  x1:    b = [b0, b1]
    ;  x2:    c = [c0, c1]
    ;  x3:    d = [d0, d1]

    ;  x4:  i00 = a0 * b0
    ;  x5:  i01 = a0 * b1
    ;  x6:  i10 = a1 * b0
    ;  x7:  i11 = a1 * b1

    ;  x8: i010 = i01 * H
    ;  x9: i011 = i01 / H
    ; x10: i100 = i10 * H
    ; x11: i101 = i10 / H

    ; [c, d] =           (a1 * a1) * W
    ;        + (a0 * b1 + a1 * b0) * H
    ;        +           (a0 * b0) * 1

    ; c = i00 + i010 + i100
    ; d = i11 + i011 + i101

    .cfi_startproc
    reserve_stack_pre (8 * 12 + 32 * 8)

    ; virtual zero
    adrp x15, _zero@PAGE
    add x15, x15, _zero@PAGEOFF

    ; initialize registers
    add x4, sp, #(32 * 0)
    add x5, sp, #(32 * 1)
    add x6, sp, #(32 * 2)
    add x7, sp, #(32 * 3)
    add x8, sp, #(32 * 4)
    add x9, sp, #(32 * 5)
    add x10, sp, #(32 * 6)
    add x11, sp, #(32 * 7)

    ; zerofill
    str xzr, [sp, #(8 * 0)]
    str xzr, [sp, #(8 * 1)]
    str xzr, [sp, #(8 * 2)]
    str xzr, [sp, #(8 * 3)]
    str xzr, [sp, #(8 * 4)]
    str xzr, [sp, #(8 * 5)]
    str xzr, [sp, #(8 * 6)]
    str xzr, [sp, #(8 * 7)]
    str xzr, [sp, #(8 * 8)]
    str xzr, [sp, #(8 * 9)]
    str xzr, [sp, #(8 * 10)]
    str xzr, [sp, #(8 * 11)]
    str xzr, [sp, #(8 * 12)]
    str xzr, [sp, #(8 * 13)]
    str xzr, [sp, #(8 * 14)]
    str xzr, [sp, #(8 * 15)]
    str xzr, [sp, #(8 * 16)]
    str xzr, [sp, #(8 * 17)]
    str xzr, [sp, #(8 * 18)]
    str xzr, [sp, #(8 * 19)]
    str xzr, [sp, #(8 * 20)]
    str xzr, [sp, #(8 * 21)]
    str xzr, [sp, #(8 * 22)]
    str xzr, [sp, #(8 * 23)]
    str xzr, [sp, #(8 * 24)]
    str xzr, [sp, #(8 * 25)]
    str xzr, [sp, #(8 * 26)]
    str xzr, [sp, #(8 * 27)]
    str xzr, [sp, #(8 * 28)]
    str xzr, [sp, #(8 * 29)]
    str xzr, [sp, #(8 * 30)]
    str xzr, [sp, #(8 * 31)]

    ; calculate i00 = a0 * b0
    push_reg (32 * 8)
    add x0, x0, #0
    add x1, x1, #0
    add x2, x4, #0
    add x3, x4, #16
    bl _mult128
    pop_reg (32 * 8)

    ; calculate i01 = a0 * b1
    push_reg (32 * 8)
    add x0, x0, #0
    add x1, x1, #16
    add x2, x5, #0
    add x3, x5, #16
    bl _mult128
    pop_reg (32 * 8)

    ; calculate i10 = a1 * b0
    push_reg (32 * 8)
    add x0, x0, #16
    add x1, x1, #0
    add x2, x6, #0
    add x3, x6, #16
    bl _mult128
    pop_reg (32 * 8)

    ; calculate i11 = a1 * b1
    push_reg (32 * 8)
    add x0, x0, #16
    add x1, x1, #16
    add x2, x7, #0
    add x3, x7, #16
    bl _mult128
    pop_reg (32 * 8)

    ; calculate i010 = i01 * H
    cpw x8, #16, x5, #0
    cpw x8, #20, x5, #4
    cpw x8, #24, x5, #8
    cpw x8, #28, x5, #12

    ; calculate i011 = i01 / H
    cpw x9, #0, x5, #16
    cpw x9, #4, x5, #20
    cpw x9, #8, x5, #24
    cpw x9, #12, x5, #28

    ; calculate i100 = i10 * H
    cpw x10, #16, x6, #0
    cpw x10, #20, x6, #4
    cpw x10, #24, x6, #8
    cpw x10, #28, x6, #12

    ; calculate i101 = i10 / H
    cpw x11, #0, x6, #16
    cpw x11, #4, x6, #20
    cpw x11, #8, x6, #24
    cpw x11, #12, x6, #28

    ; clear carry flag
    adcs xzr, xzr, xzr

    ; calculate d = i11 + i011 + i101
    add256 x3, x7, x9    ; d = i11 + i011
    add256 x3, x3, x11   ; d += i101

    ; calculate c = i00 + i010 + i100
    add256 x2, x4, x8    ; c = i00 + i010
    b.CC .+4
        add256 x3, x3, x15   ; d += 1 if carry
    add256 x2, x2, x10   ; c += i100
    b.CC .+4
        add256 x3, x3, x15   ; d += 1 if carry

    reserve_stack_post (8 * 12 + 32 * 8)
    ret
    .cfi_endproc
; End of Function _mult256

; Function _mult128
_mult128:
    .cfi_startproc
    reserve_stack_pre (8 * 12 + 16 * 8)

    ; initialize registers
    add x4, sp, #(16 * 0)
    add x5, sp, #(16 * 1)
    add x6, sp, #(16 * 2)
    add x7, sp, #(16 * 3)
    add x8, sp, #(16 * 4)
    add x9, sp, #(16 * 5)
    add x10, sp, #(16 * 6)
    add x11, sp, #(16 * 7)

    ; zerofill
    str xzr, [sp, #(8 * 0)]
    str xzr, [sp, #(8 * 1)]
    str xzr, [sp, #(8 * 2)]
    str xzr, [sp, #(8 * 3)]
    str xzr, [sp, #(8 * 4)]
    str xzr, [sp, #(8 * 5)]
    str xzr, [sp, #(8 * 6)]
    str xzr, [sp, #(8 * 7)]
    str xzr, [sp, #(8 * 8)]
    str xzr, [sp, #(8 * 9)]
    str xzr, [sp, #(8 * 10)]
    str xzr, [sp, #(8 * 11)]
    str xzr, [sp, #(8 * 12)]
    str xzr, [sp, #(8 * 13)]
    str xzr, [sp, #(8 * 14)]
    str xzr, [sp, #(8 * 15)]

    ; calculate i00 = a0 * b0
    push_reg (16 * 8)
    add x0, x0, #0
    add x1, x1, #0
    add x2, x4, #0
    add x3, x4, #8
    bl _mult64
    pop_reg (16 * 8)

    ; calculate i01 = a0 * b1
    push_reg (16 * 8)
    add x0, x0, #0
    add x1, x1, #8
    add x2, x5, #0
    add x3, x5, #8
    bl _mult64
    pop_reg (16 * 8)

    ; calculate i10 = a1 * b0
    push_reg (16 * 8)
    add x0, x0, #8
    add x1, x1, #0
    add x2, x6, #0
    add x3, x6, #8
    bl _mult64
    pop_reg (16 * 8)

    ; calculate i11 = a1 * b1
    push_reg (16 * 8)
    add x0, x0, #8
    add x1, x1, #8
    add x2, x7, #0
    add x3, x7, #8
    bl _mult64
    pop_reg (16 * 8)

    ; calculate i010 = i01 * H
    cpw x8, #8, x5, #0
    cpw x8, #12, x5, #4

    ; calculate i011 = i01 / H
    cpw x9, #0, x5, #8
    cpw x9, #4, x5, #12

    ; calculate i100 = i10 * H
    cpw x10, #8, x6, #0
    cpw x10, #12, x6, #4

    ; calculate i101 = i10 / H
    cpw x11, #0, x6, #8
    cpw x11, #4, x6, #12

    ; clear carry flag
    adcs xzr, xzr, xzr

    ; calculate d = i11 + i011 + i101
    add128 x3, x7, x9    ; d = i11 + i011
    add128 x3, x3, x11   ; d += i101

    ; calculate c = i00 + i010 + i100
    add128 x2, x4, x8    ; c = i00 + i010
    b.CC .+4
        add128 x3, x3, x15   ; d += 1 if carry
    add128 x2, x2, x10   ; c += i100
    b.CC .+4
        add128 x3, x3, x15   ; d += 1 if carry

    ; test
    ; ldr x4, [x15, #0]
    ; str x4, [x2]

    reserve_stack_post (8 * 12 + 16 * 8)
    ret
    .cfi_endproc
; End of Function _mult256

; Function _mult64
_mult64:
    .cfi_startproc
    reserve_stack_pre (8 * 12 + 8 * 8)

    ; initialize registers
    add x4, sp, #(8 * 0)
    add x5, sp, #(8 * 1)
    add x6, sp, #(8 * 2)
    add x7, sp, #(8 * 3)
    add x8, sp, #(8 * 4)
    add x9, sp, #(8 * 5)
    add x10, sp, #(8 * 6)
    add x11, sp, #(8 * 7)

    ; zerofill
    str xzr, [sp, #(8 * 0)]
    str xzr, [sp, #(8 * 1)]
    str xzr, [sp, #(8 * 2)]
    str xzr, [sp, #(8 * 3)]
    str xzr, [sp, #(8 * 4)]
    str xzr, [sp, #(8 * 5)]
    str xzr, [sp, #(8 * 6)]
    str xzr, [sp, #(8 * 7)]

    ; calculate i00 = a0 * b0
    push_reg (8 * 8)
    add x0, x0, #0
    add x1, x1, #0
    add x2, x4, #0
    add x3, x4, #4
    bl _mult32
    pop_reg (8 * 8)

    ; calculate i01 = a0 * b1
    push_reg (8 * 8)
    add x0, x0, #0
    add x1, x1, #4
    add x2, x5, #0
    add x3, x5, #4
    bl _mult32
    pop_reg (8 * 8)

    ; calculate i10 = a1 * b0
    push_reg (8 * 8)
    add x0, x0, #4
    add x1, x1, #0
    add x2, x6, #0
    add x3, x6, #4
    bl _mult32
    pop_reg (8 * 8)

    ; calculate i11 = a1 * b1
    push_reg (8 * 8)
    add x0, x0, #4
    add x1, x1, #4
    add x2, x7, #0
    add x3, x7, #4
    bl _mult32
    pop_reg (8 * 8)

    ; calculate i010 = i01 * H
    cpw x8, #4, x5, #0

    ; calculate i011 = i01 / H
    cpw x9, #0, x5, #4

    ; calculate i100 = i10 * H
    cpw x10, #4, x6, #0

    ; calculate i101 = i10 / H
    cpw x11, #0, x6, #4

    ; clear carry flag
    adcs xzr, xzr, xzr

    ; calculate d = i11 + i011 + i101
    add64 x3, x7, x9    ; d = i11 + i011
    add64 x3, x3, x11   ; d += i101

    ; calculate c = i00 + i010 + i100
    add64 x2, x4, x8    ; c = i00 + i010
    b.CC .+4
        add64 x3, x3, x15   ; d += 1 if carry
    add64 x2, x2, x10   ; c += i100
    b.CC .+4
        add64 x3, x3, x15   ; d += 1 if carry

    reserve_stack_post (8 * 12 + 8 * 8)
    ret
    .cfi_endproc
; End of Function _mult256

; Function _mult32
_mult32:
    .cfi_startproc

    ldr w4, [x0]
    ldr w5, [x1]
    umull x6, w4, w5
    lsr x7, x6, #32
    str w6, [x2]
    str w7, [x3]

    ret
    .cfi_endproc
; End of Function _mult32

    .section    __DATA, __data
    .p2align    2, 0x0
.zerofill __DATA, __common, _zero, (256), 2

    .section    __TEXT,__cstring,cstring_literals
l_.str:                                 ; @.str
    .asciz    "%x\n"

.subsections_via_symbols
