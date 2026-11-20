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

#[inline(never)]
fn bubble_sort(a: &mut [u32; 8]) {
    for i in 0..a.len() {
        for j in 0..a.len() - 1 - i {
            if a[j] > a[j + 1] {
                a.swap(j, j + 1);
            }
        }
    }
}

fn fib(x: u32) -> u32 {
    let mut a: u32 = 0;
    let mut b: u32 = 1;
    for _ in 1..x {
        let c = a;
        a = b;
        b += c;
    }
    b
}

#[unsafe(no_mangle)]
pub extern "C" fn main() -> u32 {
    let mut arr = black_box([42, 7, 19, 3, 88, 1, 56, 23]);
    bubble_sort(&mut arr);
    let x: u32 = black_box(42);
    fib(x)
}

#[panic_handler]
fn panic(_: &PanicInfo) -> ! {
    unsafe { core::arch::asm!("ebreak") };
    loop {}
}
