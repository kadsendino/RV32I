    .section .text.start
    .globl _start
_start:
    lui  sp, 0x1          # sp = 0x1000 (top of 4 KiB RAM)
    call main
    ebreak
