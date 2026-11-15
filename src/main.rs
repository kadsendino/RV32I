#![no_std]
#![no_main]

use core::hint::black_box;
use core::panic::PanicInfo;

// Startup code: runs first at address 0, sets the stack, calls main, halts.
core::arch::global_asm!(
    ".section .text.start",
    ".globl _start",
    "_start:",
    "la sp, _stack_top",
    "call main",
    "ebreak",
);

fn add(a: u32, b: u32) -> u32 {
    a+b
}

#[unsafe(no_mangle)]
pub extern "C" fn main() -> u32 {
    let x: u32 = black_box(5);
    let y: u32 = black_box(5);
    add(add(x, 6), add(y, 8))
}

#[panic_handler]
fn panic(_: &PanicInfo) -> ! {
    unsafe { core::arch::asm!("ebreak") };
    loop {}
}
