const std = @import("std");
const assert = std.debug.assert;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

////////////////////////////////
// Type definitions
////////////////////////////////

/// An entry in the Global Descriptor Table (GDT)
const GDTEntry = packed struct {
    /// Limit (20 bits): the size of the segment
    limit_low: u16,
    /// Base (32 bits): the base address of the segment
    base_low: u16,
    base_middle: u8,
    /// Access flags for the segment
    access: GDTAccess,
    /// Other flags for the segment
    flags: GDTFlags,
    limit_high: u4,
    base_high: u8,

    /// Initialize a GDT entry with given fields
    fn init(base: u32, limit: u20, access: u8, flags: u4) GDTEntry {
        return GDTEntry{
            .limit_low = @truncate(limit & 0xFFFF),
            .limit_high = @truncate((limit >> 16) & 0x0F),

            .base_low = @truncate(base & 0xFFFF),
            .base_middle = @truncate((base >> 16) & 0xFF),
            .base_high = @truncate((base >> 24) & 0xFF),

            .access = @bitCast(access),
            .flags = @bitCast(flags),
        };
    }
};

/// Segment Access flags
const GDTAccess = packed struct {
    /// Segment accessed marker
    /// CPU sets this when the segment is accessed
    accessed: u1,

    /// Readable/Writable bit
    /// 0 (code segment): segment not readable or writable
    /// 1 (code segment): segment readable, not writable
    /// 0 (data segment): segment not readable or writable
    /// 1 (data segment): segment writable, not readable
    read_write: u1,

    /// Direction bit (data segment) or conform bit (code segment)
    /// 0 (code segment): only executable from specified ring
    /// 1 (code segment): executable from >= specified ring
    /// 0 (data segment): segment grows up
    /// 1 (data segment): segment grows down
    direction_conform: u1,

    /// Segment executable
    /// 0: data segment
    /// 1: code segment
    executable: u1,

    /// Segment type
    /// 0: system segment
    /// 1: code or data segment
    desc_type: u1,

    /// Security level of segment
    /// 0: lowest level (kernel)
    /// 3: highest level (user)
    ring: u2,

    /// Segment valid
    /// 0: invalid
    /// 1: valid
    present: u1,
};

/// Segment flags
const GDTFlags = packed struct {
    /// System reserved
    reserved: u1 = 0,

    /// Long mode enabled
    /// 0: Protected mode (16/32 bit)
    /// 1: Long mode (64 bit), operand_size should be 0
    long_mode: u1,

    /// Size of opcodes
    /// 0: 16 bits
    /// 1: 32 bits
    operand_size: u1,

    /// Granularity of the segment
    /// 0: 1 byte
    /// 1: 4KiB
    granularity: u1,
};

/// Pointer to the Global Descriptor Table
/// and its size
const GDTPtr = packed struct {
    limit: u16,
    base: u32,
};

////////////////////////////////
// Member variables
////////////////////////////////

var gdt_32 = [_]GDTEntry{
    // The first entry of the GDT is null
    GDTEntry.init(0, 0, 0, 0),
    // Kernel Code segment
    GDTEntry.init(0, 0xFFFFF, 0x9A, 0xC),
    // Kernel Data segment
    GDTEntry.init(0, 0xFFFFF, 0x92, 0xC),
    // User Code segment
    GDTEntry.init(0, 0xFFFFF, 0xFA, 0xC),
    // User Data segment
    GDTEntry.init(0, 0xFFFFF, 0xF2, 0xC),
    // Task State segment (initialized later)
    GDTEntry.init(0, 0, 0, 0),
};

var gdt_64 = [_]GDTEntry{
    // The first entry of the GDT is null
    GDTEntry.init(0, 0, 0, 0),
    // Kernel Code segment
    GDTEntry.init(0, 0xFFFFF, 0x9A, 0xA),
    // Kernel Data segment
    GDTEntry.init(0, 0xFFFFF, 0x92, 0xC),
    // User Code segment
    GDTEntry.init(0, 0xFFFFF, 0xFA, 0xA),
    // User Data segment
    GDTEntry.init(0, 0xFFFFF, 0xF2, 0xC),
    // Task State segment (initialized later)
    GDTEntry.init(0, 0, 0, 0),
};

////////////////////////////////
// Functions
////////////////////////////////

pub fn init() void {
    // Initialize the Task State segments
    // zig fmt: off
    gdt_32[5] = GDTEntry.init(
        @intFromPtr(&gdt_32[5]),
        @sizeOf(GDTEntry) - 1,
        0x89,
        0
    );
    // zig fmt: off
    gdt_64[5] = GDTEntry.init(
        @intFromPtr(&gdt_64[5]),
        @sizeOf(GDTEntry) - 1,
        0x89,
        0
    );

    setGDT32(@sizeOf(GDTEntry) * gdt_32.len - 1, @intFromPtr(&gdt_32));
}

extern fn setGDT32(limit: u16, base: u32) void;

////////////////////////////////
// Testing
////////////////////////////////

test "GDT entry sizes" {
    try expect(@bitSizeOf(GDTEntry) == 64);
    try expect(@bitSizeOf(GDTAccess) == 8);
    try expect(@bitSizeOf(GDTFlags) == 4);
}

test "GDT layout" {
    const test_gdt = GDTEntry.init(0x01234567, 0x12345, 0xBA, 0xC);
    // zig fmt: off
    const manual_gdt = GDTEntry{
        .base_low = 0x4567,
        .base_middle = 0x23,
        .base_high = 0x01,
        .limit_low = 0x2345,
        .limit_high = 0x1,
        .access = GDTAccess{
            .accessed = 0,
            .read_write = 1,
            .direction_conform = 0,
            .executable = 1,
            .desc_type = 1,
            .ring = 1,
            .present = 1,
        },
        .flags = GDTFlags{
            .granularity = 1,
            .operand_size = 1,
            .long_mode = 0,
        }
    };

    const test_access_byte: u8 = @bitCast(test_gdt.access);
    const manual_access_byte: u8 = @bitCast(manual_gdt.access);
    const test_flags: u4 = @bitCast(test_gdt.flags);
    const manual_flags: u4 = @bitCast(manual_gdt.flags);

    try expectEqual(test_gdt.base_low, manual_gdt.base_low);
    try expectEqual(test_gdt.base_middle, manual_gdt.base_middle);
    try expectEqual(test_gdt.base_high, manual_gdt.base_high);
    try expectEqual(test_gdt.limit_low, manual_gdt.limit_low);
    try expectEqual(test_gdt.limit_high, manual_gdt.limit_high);
    try expectEqual(test_access_byte, manual_access_byte);
    try expectEqual(test_flags, manual_flags);
}
