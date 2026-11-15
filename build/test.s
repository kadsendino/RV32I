_start:
lui sp, 0x1
auipc ra, 0x0
jalr ra, 0x14(ra)
ebreak
add:
add a0, a1, a0
jalr zero, 0x0(ra)
main:
addi a0, zero, 0x5
jalr zero, 0x0(ra)
