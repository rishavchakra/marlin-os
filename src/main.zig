const console = @import("console.zig");

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

export fn kernel_main() void {
    console.init();
    console.putString("Hello Marlin!\n");
}
