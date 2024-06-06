const std = @import("std");
const assert = std.debug.assert;
const expect = std.testing.expect;
const expectEqual = std.testing.expectEqual;

////////////////////////////////
// Type definitions
////////////////////////////////

const GDTEntry = packed struct {
    limit_low: u16,
    base_low: u16,
    base_middle: u8,
    access: GDTAccess,
    flags: GDTFlags,
    limit_high: u4,
    base_high: u8,

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

const GDTAccess = packed struct {
    accessed: u1,
    read_write: u1,
    direction_conform: u1,
    executable: u1,
    desc_type: u1,
    ring: u2,
    present: u1,
};

const GDTFlags = packed struct {
    reserved: u1 = 0,
    long_mode: u1,
    operand_size: u1,
    granularity: u1,
};

const GDTPtr = packed struct {
    limit: u16,
    base: u32,
};

////////////////////////////////
// Member variables
////////////////////////////////

var gdt_32 = [_]GDTEntry{
    GDTEntry.init(0, 0, 0, 0),
    GDTEntry.init(0, 0xFFFFF, 0x9A, 0xC),
    GDTEntry.init(0, 0xFFFFF, 0x92, 0xC),
    GDTEntry.init(0, 0xFFFFF, 0xFA, 0xC),
    GDTEntry.init(0, 0xFFFFF, 0xF2, 0xC),
    GDTEntry.init(0, 0, 0, 0),
};

var gdt_64 = [_]GDTEntry{
    GDTEntry.init(0, 0, 0, 0),
    GDTEntry.init(0, 0xFFFFF, 0x9A, 0xA),
    GDTEntry.init(0, 0xFFFFF, 0x92, 0xC),
    GDTEntry.init(0, 0xFFFFF, 0xFA, 0xA),
    GDTEntry.init(0, 0xFFFFF, 0xF2, 0xC),
    GDTEntry.init(0, 0, 0, 0),
};

////////////////////////////////
// Functions
////////////////////////////////

pub fn init() void {
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
