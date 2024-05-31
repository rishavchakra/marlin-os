    global      _start:function (_start.end - _start)
    extern      kernel_main:function

    section     .bss            align=16
stack_bottom:
    resb        16384 ; 16 KiB
stack_top:

    section     .text
_start:
    mov         esp, stack_top ; Set kernel stack to defined buffer
    ; TODO: Set up GDT and Paging here
    call        kernel_main

    ; Kernel catch: infinite loop
    cli
    hlt
    jmp         1b

    ; size        _start, . - _start
.end:

