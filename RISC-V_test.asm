# Final test for all 40 RV32I instructions:
#   lui auipc jal jalr beq bne blt bge bltu bgeu lb lh lw lbu lhu sb sh sw
#   addi slti sltiu xori ori andi slli srli srai add sub sll slt sltu xor srl sra or and
#   fence ecall ebreak
#
# Load at address 0. Needs at least 8 KiB of memory (data at 0x1000-0x1007).
# Plain instructions only: no labels, no directives.
#
# The program checks itself. Each test computes a value, compares it with the
# expected one (bne), and jumps to the fail code at 0x3F0 if it differs.
#
#   PASS: a0 = 0 at the end (ebreak at 0x3EC)
#   FAIL: a0 = gp = number of the first failed test (ebreak at 0x3FC)
#
# At the end it calls ecall with a7 = 93 (exit, Linux convention, a0 = exit code).
# If your simulator does not handle ecall, it just continues to the ebreak.

    # setup: operands and data address
    lui   s1, 0x12345       # 0x000: s1 = 0x12345000
    addi  s1, s1, 0x678     # 0x004: s1 = 0x12345678
    lui   s2, 0x8899B       # 0x008: s2 = 0x8899B000
    addi  s2, s2, -0x545    # 0x00C: s2 = 0x8899AABB
    addi  s3, zero, -1      # 0x010: s3 = 0xFFFFFFFF
    addi  s4, zero, 5       # 0x014: s4 = 0x00000005
    lui   s5, 0x80000       # 0x018: s5 = 0x80000000
    lui   s0, 0x1           # 0x01C: s0 = 0x00001000   data address

    # test 1: lui
    addi  gp, zero, 1       # 0x020: gp = 1   (current test number)
    lui   t0, 0xABCDE       # 0x024: t0 = 0xABCDE000
    lui   t1, 0xABCDE       # 0x028: t1 = 0xABCDE000
    bne   t0, t1, 964       # 0x02C: t0 must be 0xABCDE000, else fail (jump to 0x000003F0)

    # test 2: auipc
    addi  gp, zero, 2       # 0x030: gp = 2   (current test number)
    auipc t0, 0x1           # 0x034: t0 = 0x00000034 + 0x1000 = 0x00001034
    lui   t1, 0x1           # 0x038: t1 = 0x00001000
    addi  t1, t1, 0x34      # 0x03C: t1 = 0x00001034   expected
    bne   t0, t1, 944       # 0x040: t0 must be 0x00001034, else fail (jump to 0x000003F0)

    # test 3: addi
    addi  gp, zero, 3       # 0x044: gp = 3   (current test number)
    addi  t0, s4, -7        # 0x048: t0 = 5 - 7
    addi  t1, zero, -0x2    # 0x04C: t1 = 0xFFFFFFFE   expected
    bne   t0, t1, 928       # 0x050: t0 must be 0xFFFFFFFE, else fail (jump to 0x000003F0)

    # test 4: slti
    addi  gp, zero, 4       # 0x054: gp = 4   (current test number)
    slti  t0, s3, 0         # 0x058: t0 = (-1 < 0) signed
    addi  t1, zero, 0x1     # 0x05C: t1 = 0x00000001   expected
    bne   t0, t1, 912       # 0x060: t0 must be 0x00000001, else fail (jump to 0x000003F0)

    # test 5: sltiu
    addi  gp, zero, 5       # 0x064: gp = 5   (current test number)
    sltiu t0, s5, -1        # 0x068: t0 = (0x80000000 < 0xFFFFFFFF) unsigned, imm sign-extended
    addi  t1, zero, 0x1     # 0x06C: t1 = 0x00000001   expected
    bne   t0, t1, 896       # 0x070: t0 must be 0x00000001, else fail (jump to 0x000003F0)

    # test 6: xori
    addi  gp, zero, 6       # 0x074: gp = 6   (current test number)
    xori  t0, s1, -1        # 0x078: t0 = ~s1
    lui   t1, 0xEDCBB       # 0x07C: t1 = 0xEDCBB000
    addi  t1, t1, -0x679    # 0x080: t1 = 0xEDCBA987   expected
    bne   t0, t1, 876       # 0x084: t0 must be 0xEDCBA987, else fail (jump to 0x000003F0)

    # test 7: ori
    addi  gp, zero, 7       # 0x088: gp = 7   (current test number)
    ori   t0, s4, 0x7F0     # 0x08C: t0 = 5 | 0x7F0
    addi  t1, zero, 0x7F5   # 0x090: t1 = 0x000007F5   expected
    bne   t0, t1, 860       # 0x094: t0 must be 0x000007F5, else fail (jump to 0x000003F0)

    # test 8: andi
    addi  gp, zero, 8       # 0x098: gp = 8   (current test number)
    andi  t0, s2, 0xFF      # 0x09C: t0 = s2 & 0xFF
    addi  t1, zero, 0xBB    # 0x0A0: t1 = 0x000000BB   expected
    bne   t0, t1, 844       # 0x0A4: t0 must be 0x000000BB, else fail (jump to 0x000003F0)

    # test 9: slli
    addi  gp, zero, 9       # 0x0A8: gp = 9   (current test number)
    slli  t0, s1, 4         # 0x0AC: t0 = s1 << 4
    lui   t1, 0x23456       # 0x0B0: t1 = 0x23456000
    addi  t1, t1, 0x780     # 0x0B4: t1 = 0x23456780   expected
    bne   t0, t1, 824       # 0x0B8: t0 must be 0x23456780, else fail (jump to 0x000003F0)

    # test 10: srli
    addi  gp, zero, 10      # 0x0BC: gp = 10   (current test number)
    srli  t0, s5, 4         # 0x0C0: t0 = s5 >> 4, zero shifted in
    lui   t1, 0x8000        # 0x0C4: t1 = 0x08000000
    bne   t0, t1, 808       # 0x0C8: t0 must be 0x08000000, else fail (jump to 0x000003F0)

    # test 11: srai
    addi  gp, zero, 11      # 0x0CC: gp = 11   (current test number)
    srai  t0, s5, 4         # 0x0D0: t0 = s5 >> 4, sign copied in
    lui   t1, 0xF8000       # 0x0D4: t1 = 0xF8000000
    bne   t0, t1, 792       # 0x0D8: t0 must be 0xF8000000, else fail (jump to 0x000003F0)

    # test 12: add
    addi  gp, zero, 12      # 0x0DC: gp = 12   (current test number)
    add   t0, s1, s2        # 0x0E0: t0 = s1 + s2
    lui   t1, 0x9ACE0       # 0x0E4: t1 = 0x9ACE0000
    addi  t1, t1, 0x133     # 0x0E8: t1 = 0x9ACE0133   expected
    bne   t0, t1, 772       # 0x0EC: t0 must be 0x9ACE0133, else fail (jump to 0x000003F0)

    # test 13: sub
    addi  gp, zero, 13      # 0x0F0: gp = 13   (current test number)
    sub   t0, s4, s1        # 0x0F4: t0 = 5 - s1
    lui   t1, 0xEDCBB       # 0x0F8: t1 = 0xEDCBB000
    addi  t1, t1, -0x673    # 0x0FC: t1 = 0xEDCBA98D   expected
    bne   t0, t1, 752       # 0x100: t0 must be 0xEDCBA98D, else fail (jump to 0x000003F0)

    # test 14: sll
    addi  gp, zero, 14      # 0x104: gp = 14   (current test number)
    sll   t0, s4, s4        # 0x108: t0 = 5 << 5
    addi  t1, zero, 0xA0    # 0x10C: t1 = 0x000000A0   expected
    bne   t0, t1, 736       # 0x110: t0 must be 0x000000A0, else fail (jump to 0x000003F0)

    # test 15: slt
    addi  gp, zero, 15      # 0x114: gp = 15   (current test number)
    slt   t0, s5, s3        # 0x118: t0 = (0x80000000 < -1) signed
    addi  t1, zero, 0x1     # 0x11C: t1 = 0x00000001   expected
    bne   t0, t1, 720       # 0x120: t0 must be 0x00000001, else fail (jump to 0x000003F0)

    # test 16: sltu
    addi  gp, zero, 16      # 0x124: gp = 16   (current test number)
    sltu  t0, s3, s4        # 0x128: t0 = (0xFFFFFFFF < 5) unsigned
    addi  t1, zero, 0x0     # 0x12C: t1 = 0x00000000   expected
    bne   t0, t1, 704       # 0x130: t0 must be 0x00000000, else fail (jump to 0x000003F0)

    # test 17: xor
    addi  gp, zero, 17      # 0x134: gp = 17   (current test number)
    xor   t0, s1, s2        # 0x138: t0 = s1 ^ s2
    lui   t1, 0x9AAE0       # 0x13C: t1 = 0x9AAE0000
    addi  t1, t1, -0x33D    # 0x140: t1 = 0x9AADFCC3   expected
    bne   t0, t1, 684       # 0x144: t0 must be 0x9AADFCC3, else fail (jump to 0x000003F0)

    # test 18: srl
    addi  gp, zero, 18      # 0x148: gp = 18   (current test number)
    srl   t0, s2, s4        # 0x14C: t0 = s2 >> 5, zero shifted in
    lui   t1, 0x444D        # 0x150: t1 = 0x0444D000
    addi  t1, t1, -0x2AB    # 0x154: t1 = 0x0444CD55   expected
    bne   t0, t1, 664       # 0x158: t0 must be 0x0444CD55, else fail (jump to 0x000003F0)

    # test 19: sra
    addi  gp, zero, 19      # 0x15C: gp = 19   (current test number)
    sra   t0, s2, s4        # 0x160: t0 = s2 >> 5, sign copied in
    lui   t1, 0xFC44D       # 0x164: t1 = 0xFC44D000
    addi  t1, t1, -0x2AB    # 0x168: t1 = 0xFC44CD55   expected
    bne   t0, t1, 644       # 0x16C: t0 must be 0xFC44CD55, else fail (jump to 0x000003F0)

    # test 20: or
    addi  gp, zero, 20      # 0x170: gp = 20   (current test number)
    or    t0, s1, s2        # 0x174: t0 = s1 | s2
    lui   t1, 0x9ABE0       # 0x178: t1 = 0x9ABE0000
    addi  t1, t1, -0x105    # 0x17C: t1 = 0x9ABDFEFB   expected
    bne   t0, t1, 624       # 0x180: t0 must be 0x9ABDFEFB, else fail (jump to 0x000003F0)

    # test 21: and
    addi  gp, zero, 21      # 0x184: gp = 21   (current test number)
    and   t0, s1, s2        # 0x188: t0 = s1 & s2
    lui   t1, 0x100         # 0x18C: t1 = 0x00100000
    addi  t1, t1, 0x238     # 0x190: t1 = 0x00100238   expected
    bne   t0, t1, 604       # 0x194: t0 must be 0x00100238, else fail (jump to 0x000003F0)

    # test 22: sw, lw
    addi  gp, zero, 22      # 0x198: gp = 22   (current test number)
    sw    s2, 0(s0)         # 0x19C: mem[0x1000] = 0x8899AABB  (bytes BB AA 99 88)
    lw    t0, 0(s0)         # 0x1A0: t0 = 0x8899AABB
    lui   t1, 0x8899B       # 0x1A4: t1 = 0x8899B000
    addi  t1, t1, -0x545    # 0x1A8: t1 = 0x8899AABB   expected
    bne   t0, t1, 580       # 0x1AC: t0 must be 0x8899AABB, else fail (jump to 0x000003F0)

    # test 23: lb
    addi  gp, zero, 23      # 0x1B0: gp = 23   (current test number)
    lb    t0, 0(s0)         # 0x1B4: t0 = byte 0xBB, sign-extended
    addi  t1, zero, -0x45   # 0x1B8: t1 = 0xFFFFFFBB   expected
    bne   t0, t1, 564       # 0x1BC: t0 must be 0xFFFFFFBB, else fail (jump to 0x000003F0)

    # test 24: lbu
    addi  gp, zero, 24      # 0x1C0: gp = 24   (current test number)
    lbu   t0, 0(s0)         # 0x1C4: t0 = byte 0xBB, zero-extended
    addi  t1, zero, 0xBB    # 0x1C8: t1 = 0x000000BB   expected
    bne   t0, t1, 548       # 0x1CC: t0 must be 0x000000BB, else fail (jump to 0x000003F0)

    # test 25: lh
    addi  gp, zero, 25      # 0x1D0: gp = 25   (current test number)
    lh    t0, 2(s0)         # 0x1D4: t0 = half 0x8899, sign-extended
    lui   t1, 0xFFFF9       # 0x1D8: t1 = 0xFFFF9000
    addi  t1, t1, -0x767    # 0x1DC: t1 = 0xFFFF8899   expected
    bne   t0, t1, 528       # 0x1E0: t0 must be 0xFFFF8899, else fail (jump to 0x000003F0)

    # test 26: lhu
    addi  gp, zero, 26      # 0x1E4: gp = 26   (current test number)
    lhu   t0, 2(s0)         # 0x1E8: t0 = half 0x8899, zero-extended
    lui   t1, 0x9           # 0x1EC: t1 = 0x00009000
    addi  t1, t1, -0x767    # 0x1F0: t1 = 0x00008899   expected
    bne   t0, t1, 508       # 0x1F4: t0 must be 0x00008899, else fail (jump to 0x000003F0)

    # test 27: sb
    addi  gp, zero, 27      # 0x1F8: gp = 27   (current test number)
    sw    zero, 4(s0)       # 0x1FC: mem[0x1004] = 0x00000000
    sb    s1, 5(s0)         # 0x200: mem[0x1004] = 0x00007800   one byte only
    lw    t0, 4(s0)         # 0x204: t0 = 0x00007800
    lui   t1, 0x8           # 0x208: t1 = 0x00008000
    addi  t1, t1, -0x800    # 0x20C: t1 = 0x00007800   expected
    bne   t0, t1, 480       # 0x210: t0 must be 0x00007800, else fail (jump to 0x000003F0)

    # test 28: sh
    addi  gp, zero, 28      # 0x214: gp = 28   (current test number)
    sh    s1, 6(s0)         # 0x218: mem[0x1004] = 0x56787800   two bytes only
    lw    t0, 4(s0)         # 0x21C: t0 = 0x56787800
    lui   t1, 0x56788       # 0x220: t1 = 0x56788000
    addi  t1, t1, -0x800    # 0x224: t1 = 0x56787800   expected
    bne   t0, t1, 456       # 0x228: t0 must be 0x56787800, else fail (jump to 0x000003F0)

    # test 29: beq taken
    addi  gp, zero, 29      # 0x22C: gp = 29   (current test number)
    addi  t0, zero, 0       # 0x230: t0 = 0
    beq   s4, s4, 8         # 0x234: 5 == 5: taken
    addi  t0, zero, 1       # 0x238: skipped
    addi  t1, zero, 0x0     # 0x23C: t1 = 0x00000000   expected
    bne   t0, t1, 432       # 0x240: t0 must be 0x00000000, else fail (jump to 0x000003F0)

    # test 30: beq not taken
    addi  gp, zero, 30      # 0x244: gp = 30   (current test number)
    addi  t0, zero, 0       # 0x248: t0 = 0
    beq   s4, s3, 8         # 0x24C: 5 == -1: not taken
    addi  t0, zero, 1       # 0x250: t0 = 1   must run
    addi  t1, zero, 0x1     # 0x254: t1 = 0x00000001   expected
    bne   t0, t1, 408       # 0x258: t0 must be 0x00000001, else fail (jump to 0x000003F0)

    # test 31: bne taken
    addi  gp, zero, 31      # 0x25C: gp = 31   (current test number)
    addi  t0, zero, 0       # 0x260: t0 = 0
    bne   s4, s3, 8         # 0x264: 5 != -1: taken
    addi  t0, zero, 1       # 0x268: skipped
    addi  t1, zero, 0x0     # 0x26C: t1 = 0x00000000   expected
    bne   t0, t1, 384       # 0x270: t0 must be 0x00000000, else fail (jump to 0x000003F0)

    # test 32: bne not taken
    addi  gp, zero, 32      # 0x274: gp = 32   (current test number)
    addi  t0, zero, 0       # 0x278: t0 = 0
    bne   s4, s4, 8         # 0x27C: 5 != 5: not taken
    addi  t0, zero, 1       # 0x280: t0 = 1   must run
    addi  t1, zero, 0x1     # 0x284: t1 = 0x00000001   expected
    bne   t0, t1, 360       # 0x288: t0 must be 0x00000001, else fail (jump to 0x000003F0)

    # test 33: blt taken
    addi  gp, zero, 33      # 0x28C: gp = 33   (current test number)
    addi  t0, zero, 0       # 0x290: t0 = 0
    blt   s5, s4, 8         # 0x294: 0x80000000 < 5 signed: taken
    addi  t0, zero, 1       # 0x298: skipped
    addi  t1, zero, 0x0     # 0x29C: t1 = 0x00000000   expected
    bne   t0, t1, 336       # 0x2A0: t0 must be 0x00000000, else fail (jump to 0x000003F0)

    # test 34: blt not taken
    addi  gp, zero, 34      # 0x2A4: gp = 34   (current test number)
    addi  t0, zero, 0       # 0x2A8: t0 = 0
    blt   s4, s5, 8         # 0x2AC: 5 < 0x80000000 signed: not taken
    addi  t0, zero, 1       # 0x2B0: t0 = 1   must run
    addi  t1, zero, 0x1     # 0x2B4: t1 = 0x00000001   expected
    bne   t0, t1, 312       # 0x2B8: t0 must be 0x00000001, else fail (jump to 0x000003F0)

    # test 35: bge taken
    addi  gp, zero, 35      # 0x2BC: gp = 35   (current test number)
    addi  t0, zero, 0       # 0x2C0: t0 = 0
    bge   s4, s4, 8         # 0x2C4: 5 >= 5: taken
    addi  t0, zero, 1       # 0x2C8: skipped
    addi  t1, zero, 0x0     # 0x2CC: t1 = 0x00000000   expected
    bne   t0, t1, 288       # 0x2D0: t0 must be 0x00000000, else fail (jump to 0x000003F0)

    # test 36: bge not taken
    addi  gp, zero, 36      # 0x2D4: gp = 36   (current test number)
    addi  t0, zero, 0       # 0x2D8: t0 = 0
    bge   s5, s4, 8         # 0x2DC: 0x80000000 >= 5 signed: not taken
    addi  t0, zero, 1       # 0x2E0: t0 = 1   must run
    addi  t1, zero, 0x1     # 0x2E4: t1 = 0x00000001   expected
    bne   t0, t1, 264       # 0x2E8: t0 must be 0x00000001, else fail (jump to 0x000003F0)

    # test 37: bltu taken
    addi  gp, zero, 37      # 0x2EC: gp = 37   (current test number)
    addi  t0, zero, 0       # 0x2F0: t0 = 0
    bltu  s4, s5, 8         # 0x2F4: 5 < 0x80000000 unsigned: taken
    addi  t0, zero, 1       # 0x2F8: skipped
    addi  t1, zero, 0x0     # 0x2FC: t1 = 0x00000000   expected
    bne   t0, t1, 240       # 0x300: t0 must be 0x00000000, else fail (jump to 0x000003F0)

    # test 38: bltu not taken
    addi  gp, zero, 38      # 0x304: gp = 38   (current test number)
    addi  t0, zero, 0       # 0x308: t0 = 0
    bltu  s3, s4, 8         # 0x30C: 0xFFFFFFFF < 5 unsigned: not taken
    addi  t0, zero, 1       # 0x310: t0 = 1   must run
    addi  t1, zero, 0x1     # 0x314: t1 = 0x00000001   expected
    bne   t0, t1, 216       # 0x318: t0 must be 0x00000001, else fail (jump to 0x000003F0)

    # test 39: bgeu taken
    addi  gp, zero, 39      # 0x31C: gp = 39   (current test number)
    addi  t0, zero, 0       # 0x320: t0 = 0
    bgeu  s3, s4, 8         # 0x324: 0xFFFFFFFF >= 5 unsigned: taken
    addi  t0, zero, 1       # 0x328: skipped
    addi  t1, zero, 0x0     # 0x32C: t1 = 0x00000000   expected
    bne   t0, t1, 192       # 0x330: t0 must be 0x00000000, else fail (jump to 0x000003F0)

    # test 40: bgeu not taken
    addi  gp, zero, 40      # 0x334: gp = 40   (current test number)
    addi  t0, zero, 0       # 0x338: t0 = 0
    bgeu  s4, s3, 8         # 0x33C: 5 >= 0xFFFFFFFF unsigned: not taken
    addi  t0, zero, 1       # 0x340: t0 = 1   must run
    addi  t1, zero, 0x1     # 0x344: t1 = 0x00000001   expected
    bne   t0, t1, 168       # 0x348: t0 must be 0x00000001, else fail (jump to 0x000003F0)

    # test 41: backward branch (loop runs 3 times)
    addi  gp, zero, 41      # 0x34C: gp = 41   (current test number)
    addi  t0, zero, 0       # 0x350: t0 = 0   loop count
    addi  t2, zero, 3       # 0x354: t2 = 3
    addi  t0, t0, 1         # 0x358: loop: t0 = t0 + 1
    addi  t2, t2, -1        # 0x35C: t2 = t2 - 1
    bne   t2, zero, -8      # 0x360: back to loop while t2 != 0
    addi  t1, zero, 0x3     # 0x364: t1 = 0x00000003   expected
    bne   t0, t1, 136       # 0x368: t0 must be 0x00000003, else fail (jump to 0x000003F0)

    # test 42: jal
    addi  gp, zero, 42      # 0x36C: gp = 42   (current test number)
    addi  t0, zero, 0       # 0x370: t0 = 0
    jal   ra, 8             # 0x374: ra = 0x00000378, jump to 0x0000037C
    addi  t0, zero, 1       # 0x378: skipped
    addi  t1, zero, 0x0     # 0x37C: t1 = 0x00000000   expected
    bne   t0, t1, 112       # 0x380: t0 must be 0x00000000, else fail (jump to 0x000003F0)
    lui   t1, 0x0           # 0x384: t1 = 0x00000000
    addi  t1, t1, 0x378     # 0x388: t1 = 0x00000378   expected
    bne   ra, t1, 100       # 0x38C: ra (jal address + 4) must be 0x00000378, else fail (jump to 0x000003F0)

    # test 43: jalr
    addi  gp, zero, 43      # 0x390: gp = 43   (current test number)
    addi  t0, zero, 0       # 0x394: t0 = 0
    auipc t2, 0             # 0x398: t2 = 0x00000398
    jalr  ra, 13(t2)        # 0x39C: jump to t2 + 13 with bit 0 cleared = t2 + 12
    addi  t0, zero, 1       # 0x3A0: skipped
    addi  t1, zero, 0x0     # 0x3A4: t1 = 0x00000000   expected
    bne   t0, t1, 72        # 0x3A8: t0 must be 0x00000000, else fail (jump to 0x000003F0)
    lui   t1, 0x0           # 0x3AC: t1 = 0x00000000
    addi  t1, t1, 0x3A0     # 0x3B0: t1 = 0x000003A0   expected
    bne   ra, t1, 60        # 0x3B4: ra (jalr address + 4) must be 0x000003A0, else fail (jump to 0x000003F0)

    # test 44: fence (does nothing on one core)
    addi  gp, zero, 44      # 0x3B8: gp = 44   (current test number)
    addi  t0, zero, 7       # 0x3BC: t0 = 7
    fence rw, rw            # 0x3C0: no effect
    addi  t1, zero, 0x7     # 0x3C4: t1 = 0x00000007   expected
    bne   t0, t1, 40        # 0x3C8: t0 must be 0x00000007, else fail (jump to 0x000003F0)

    # test 45: x0 stays zero
    addi  gp, zero, 45      # 0x3CC: gp = 45   (current test number)
    addi  zero, zero, 5     # 0x3D0: write to x0 ignored
    add   t0, zero, zero    # 0x3D4: t0 = x0 + x0
    addi  t1, zero, 0x0     # 0x3D8: t1 = 0x00000000   expected
    bne   t0, t1, 20        # 0x3DC: t0 must be 0x00000000, else fail (jump to 0x000003F0)

    # all tests passed
    addi  a0, zero, 0       # 0x3E0: a0 = 0   PASS
    addi  a7, zero, 93      # 0x3E4: a7 = 93   exit (Linux convention)
    ecall                   # 0x3E8: exit(0) if your simulator handles ecall, else continue
    ebreak                  # 0x3EC: halt: PASS

    # a test failed: a0 = number of the failed test
    addi  a0, gp, 0         # 0x3F0: a0 = number of the failed test
    addi  a7, zero, 93      # 0x3F4: a7 = 93   exit (Linux convention)
    ecall                   # 0x3F8: exit(test number)
    ebreak                  # 0x3FC: halt: FAIL
