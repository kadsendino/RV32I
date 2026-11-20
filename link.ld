/* Memory layout for a CPU with 32 KiB of RAM at address 0.
 *
 *   0x0000  +----------------------+
 *           | code (.text)         |  _start first
 *           | constants (.rodata)  |
 *           | variables (.data)    |
 *           | zeroed vars (.bss)   |
 *   _end    +----------------------+
 *           | free                 |
 *           |          ^           |
 *           | stack (grows down)   |
 *   0x8000  +----------------------+  _stack_top = end of RAM
 */

MEMORY
{
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 32K
}

SECTIONS
{
    .text   : { *(.text.start) *(.text*) }            > RAM
    .rodata : { *(.rodata*) *(.srodata*) }            > RAM
    .data   : { *(.data*) *(.sdata*) }                > RAM
    .bss    : { *(.bss*) *(.sbss*) *(COMMON) }        > RAM

    . = ALIGN(16);
    _end = .;                                   /* first free address after the program */
    _stack_top = ORIGIN(RAM) + LENGTH(RAM);     /* 0x8000: stack starts at the end of RAM */

    /* Stop the build if less than 4 KiB are left for the stack. */
    ASSERT(_stack_top - _end >= 4K, "program too big: less than 4 KiB left for the stack in 32 KiB RAM")

    /DISCARD/ : { *(.eh_frame*) *(.comment) }
}
