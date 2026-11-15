SECTIONS {
    . = 0x0;
    .text   : { *(.text.start) *(.text*) }
    .rodata : { *(.rodata*) *(.srodata*) }
    .data   : { *(.data*) *(.sdata*) }
    .bss    : { *(.bss*) *(.sbss*) *(COMMON) }

    . = ALIGN(16);
    . += 0x1000;            /* 4 KiB stack, directly after the program */
    _stack_top = .;

    /DISCARD/ : { *(.eh_frame*) *(.comment) }
}
