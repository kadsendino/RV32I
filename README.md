# RV32I

Toolchain and test programs for my RISC-V RV32I computer built in [Turing Complete](https://turingcomplete.game).

Programs are written in Rust, compiled for the `riscv32i-unknown-none-elf` target, and turned into a raw
binary that the computer runs from address 0. The repository also contains the instruction set definition
for the game's assembler and a self-checking test that covers all 40 RV32I instructions.

## Repository layout

| Path | Content |
|---|---|
| `src/main.rs` | The program that runs on the computer (startup code, `main`, panic handler) |
| `link.ld` | Memory layout: 32 KiB of RAM, code at 0, stack at the end of RAM |
| `build.rs` | Lets the linker find `link.ld` |
| `.cargo/config.toml` | Sets the RISC-V target and defines the `cargo bin` / `cargo asm` commands |
| `xtask/` | Helper tool that runs on your PC: writes the `.bin` and the clean assembly listing |
| `ISA.toml` | Instruction set definition for the assembler in Turing Complete |
| `RISC-V_test.asm` | Self-checking test for all 40 RV32I instructions |
| `c/` | Earlier C version of the toolchain (Makefile, `start.s`, linker script) |

## Requirements

- Rust (a 2025 release or newer, since the aliases use `--target host-tuple`)
- The RISC-V target:

  ```sh
  rustup target add riscv32i-unknown-none-elf
  ```

The first `cargo bin` / `cargo asm` downloads one small crate (`rustc-demangle`) for the helper tool.

## Usage

| Command | Output |
|---|---|
| `cargo build --release` | ELF file: `target/riscv32i-unknown-none-elf/release/rvtest` |
| `cargo bin` | Raw machine code: `target/rvtest.bin` |
| `cargo asm` | Assembly of the linked program: `target/rvtest.s` |
| `cargo bin --opt 0` / `cargo asm --opt 0` | Same, with another optimisation level (`0`, `1`, `2`, `3`, `s`, `z`) |
| `cargo clean` | Removes all build output |

`target/rvtest.bin` is what the computer runs: load it into memory at address 0 and start at PC 0.
The default optimisation level is 1 (set in `Cargo.toml`).

`cargo asm` prints real instructions only (no pseudo-instructions, e.g. `jalr zero, 0x0(ra)` instead
of `ret`), with branch and `jal` offsets relative to the instruction and labels like `rvtest__bubble_sort`.
It shows code only: constant data such as lookup tables is in the `.bin` but not in the listing.

## Memory layout

The computer has 32 KiB of RAM at address 0. The program starts at 0, the stack starts at the end of RAM
and grows down:

```
0x0000  +----------------------+
        | code (.text)         |  _start first
        | constants (.rodata)  |
        | variables (.data)    |
        | zeroed vars (.bss)   |
_end    +----------------------+
        | free                 |
        | stack (grows down)   |
0x8000  +----------------------+  _stack_top = end of RAM
```

The build fails if the program leaves less than 4 KiB for the stack. With 32 KiB, use optimisation level
1 or higher: at level 0 most programs are too big.

## Writing programs

`src/main.rs` contains everything a program needs:

- **Startup code** (`global_asm!`): sets `sp` to `_stack_top`, calls `main`, then halts with `ebreak`.
  The return value of `main` ends up in `a0`.
- **`#![no_std]` / `#![no_main]`**: no operating system, only Rust's `core` library.
- **Panic handler**: executes `ebreak`. If the computer stops at an `ebreak` other than the one in
  `_start`, the program panicked (for example an index out of bounds).

Tips:

- Use `core::hint::black_box(x)` for input values, otherwise the compiler calculates the result at
  compile time and the program shrinks to a single `addi a0, zero, ...`.
- RV32I has no multiply or divide instructions. `*`, `/` and `%` still work: Rust links helper functions
  like `__mulsi3` and `__udivsi3` automatically, and only the ones that are used.
- Use `wrapping_add` / `wrapping_mul` when overflow is intended.
- `f32` / `f64` work in software but make programs large.

The current `src/main.rs` sorts an array with bubble sort and then returns `fib(42)`:
`a0 = 267914296` at the end.

## Instruction set

The computer implements the full RV32I base instruction set (40 instructions):

| Group | Instructions |
|---|---|
| Upper immediate | `lui` `auipc` |
| Jumps | `jal` `jalr` |
| Branches | `beq` `bne` `blt` `bge` `bltu` `bgeu` |
| Loads | `lb` `lh` `lw` `lbu` `lhu` |
| Stores | `sb` `sh` `sw` |
| Immediate arithmetic | `addi` `slti` `sltiu` `xori` `ori` `andi` `slli` `srli` `srai` |
| Register arithmetic | `add` `sub` `sll` `slt` `sltu` `xor` `srl` `sra` `or` `and` |
| System | `fence` `ecall` `ebreak` |

- Memory is little-endian.
- `ebreak` halts the computer.
- `fence` does nothing (single core, no caches).
- `ecall` uses the Linux convention where implemented: `a7 = 93` is exit with code `a0`.

`ISA.toml` describes these instructions for the assembler in Turing Complete (register names `x0`-`x31`
and ABI names like `a0`, `sp`, fence sets `iorw`).

## Testing

`RISC-V_test.asm` tests all 40 instructions and checks its own results:

- **Pass:** `a0 = 0` at the end.
- **Fail:** `a0` = number of the first test that failed (1-45; the numbers are listed in the file).

It needs at least 8 KiB of memory and must be loaded at address 0. Every line has its address and expected
value in a comment, so a failing test can be followed step by step.

## C toolchain

`c/` contains the earlier C version (Clang + LLD, built with `make`, `make bin`, `make asm`). The Rust
version replaces it; see `c/Makefile` for details.

## License

GNU Affero General Public License v3.0, see [`c/LICENSE`](c/LICENSE).
