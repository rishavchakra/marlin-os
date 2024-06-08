const console = @import("console.zig");
const gdt = @import("global_descriptor_table.zig");
const idt = @import("interrupt_descriptor_table.zig");

const ALIGN = 1 << 0;
const MEMINFO = 1 << 1;
const MAGIC = 0x1BADB002;
const FLAGS = ALIGN | MEMINFO;

const MultibootHeader = extern struct {
    magic: i32 = MAGIC,
    flags: i32,
    checksum: i32,
};

export var multiboot align(4) linksection(".multiboot") = MultibootHeader{
    .flags = FLAGS,
    .checksum = -(MAGIC + FLAGS),
};

export var stack: [16 * 1024]u8 align(16) linksection(".bss") = undefined;
const stack_slice = stack[0..];

export fn _start() callconv(.Naked) noreturn {
    asm volatile (
        \\ movl %[stk], %esp
        \\ movl %esp, %ebp
        \\ call kernel_main
        :
        : [stk] "{ecx}" (@intFromPtr(&stack_slice) + @sizeOf(@TypeOf(stack_slice))),
    );

    asm volatile (
        \\ cli
        \\ hlt
    );

    while (true) {}
}

export fn kernel_main() void {
    console.init();
    console.putString("Hello Marlin!\n");
    gdt.init();
    console.putString("GDT Initialized\n");
    idt.init();
    console.putString("IDT Initialized\n");
}
