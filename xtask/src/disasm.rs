//! RV32I disassembler. Prints real instructions only (no pseudo-instructions),
//! e.g. `jalr zero, 0x0(ra)` instead of `ret`.

const REG: [&str; 32] = [
    "zero", "ra", "sp", "gp", "tp", "t0", "t1", "t2", "s0", "s1", "a0", "a1", "a2", "a3", "a4",
    "a5", "a6", "a7", "s2", "s3", "s4", "s5", "s6", "s7", "s8", "s9", "s10", "s11", "t3", "t4",
    "t5", "t6",
];

/// Sign-extend the lowest `bits` bits of `v`.
fn sext(v: u32, bits: u32) -> i32 {
    let shift = 32 - bits;
    ((v << shift) as i32) >> shift
}

/// Signed hex the way llvm-objdump prints it: 0x10, -0x10.
fn hex(v: i32) -> String {
    if v < 0 {
        format!("-0x{:x}", (v as i64).unsigned_abs())
    } else {
        format!("0x{:x}", v)
    }
}

fn fence_set(bits: u32) -> String {
    let s: String = [(8, 'i'), (4, 'o'), (2, 'r'), (1, 'w')]
        .iter()
        .filter(|(m, _)| bits & m != 0)
        .map(|(_, c)| *c)
        .collect();
    if s.is_empty() { "0".into() } else { s }
}

/// Decode one 32-bit instruction located at address `pc`.
pub fn decode(w: u32, pc: u32) -> String {
    let opcode = w & 0x7F;
    let rd = REG[((w >> 7) & 0x1F) as usize];
    let rs1 = REG[((w >> 15) & 0x1F) as usize];
    let rs2 = REG[((w >> 20) & 0x1F) as usize];
    let funct3 = (w >> 12) & 0x7;
    let funct7 = w >> 25;

    let imm_i = sext(w >> 20, 12);
    let imm_s = sext(((w >> 25) << 5) | ((w >> 7) & 0x1F), 12);
    let imm_b = sext(
        ((w >> 31) << 12) | (((w >> 7) & 1) << 11) | (((w >> 25) & 0x3F) << 5) | (((w >> 8) & 0xF) << 1),
        13,
    );
    let imm_j = sext(
        ((w >> 31) << 20) | (((w >> 12) & 0xFF) << 12) | (((w >> 20) & 1) << 11) | (((w >> 21) & 0x3FF) << 1),
        21,
    );
    let imm_u = w >> 12;

    // Branch and jal offsets are printed relative to this instruction (like in
    // the source), so the output can be assembled again. Target = pc + offset.
    let target = |off: i32| hex(off);
    let _ = pc;

    let unknown = || "<unknown>".to_string();

    match opcode {
        0x37 => format!("lui {rd}, 0x{imm_u:x}"),
        0x17 => format!("auipc {rd}, 0x{imm_u:x}"),
        0x6F => format!("jal {rd}, {}", target(imm_j)),
        0x67 if funct3 == 0 => format!("jalr {rd}, {}({rs1})", hex(imm_i)),
        0x63 => {
            let m = match funct3 {
                0 => "beq",
                1 => "bne",
                4 => "blt",
                5 => "bge",
                6 => "bltu",
                7 => "bgeu",
                _ => return unknown(),
            };
            format!("{m} {rs1}, {rs2}, {}", target(imm_b))
        }
        0x03 => {
            let m = match funct3 {
                0 => "lb",
                1 => "lh",
                2 => "lw",
                4 => "lbu",
                5 => "lhu",
                _ => return unknown(),
            };
            format!("{m} {rd}, {}({rs1})", hex(imm_i))
        }
        0x23 => {
            let m = match funct3 {
                0 => "sb",
                1 => "sh",
                2 => "sw",
                _ => return unknown(),
            };
            format!("{m} {rs2}, {}({rs1})", hex(imm_s))
        }
        0x13 => {
            let shamt = (w >> 20) & 0x1F;
            match funct3 {
                0 => format!("addi {rd}, {rs1}, {}", hex(imm_i)),
                2 => format!("slti {rd}, {rs1}, {}", hex(imm_i)),
                3 => format!("sltiu {rd}, {rs1}, {}", hex(imm_i)),
                4 => format!("xori {rd}, {rs1}, {}", hex(imm_i)),
                6 => format!("ori {rd}, {rs1}, {}", hex(imm_i)),
                7 => format!("andi {rd}, {rs1}, {}", hex(imm_i)),
                1 if funct7 == 0x00 => format!("slli {rd}, {rs1}, 0x{shamt:x}"),
                5 if funct7 == 0x00 => format!("srli {rd}, {rs1}, 0x{shamt:x}"),
                5 if funct7 == 0x20 => format!("srai {rd}, {rs1}, 0x{shamt:x}"),
                _ => unknown(),
            }
        }
        0x33 => {
            let m = match (funct7, funct3) {
                (0x00, 0) => "add",
                (0x20, 0) => "sub",
                (0x00, 1) => "sll",
                (0x00, 2) => "slt",
                (0x00, 3) => "sltu",
                (0x00, 4) => "xor",
                (0x00, 5) => "srl",
                (0x20, 5) => "sra",
                (0x00, 6) => "or",
                (0x00, 7) => "and",
                _ => return unknown(),
            };
            format!("{m} {rd}, {rs1}, {rs2}")
        }
        0x0F if funct3 == 0 => {
            if w == 0x8330000F {
                "fence.tso".into()
            } else {
                format!("fence {}, {}", fence_set((w >> 24) & 0xF), fence_set((w >> 20) & 0xF))
            }
        }
        0x0F if funct3 == 1 => "fence.i".into(),
        0x73 if w == 0x0000_0073 => "ecall".into(),
        0x73 if w == 0x0010_0073 => "ebreak".into(),
        0x73 if w == 0xC000_1073 => "unimp".into(), // emitted by Rust after calls that never return

        _ => unknown(),
    }
}
