const std = @import("std");
const expect = std.testing.expect;

////////////////////////////////
// Type definitions
////////////////////////////////

/// An entry in the Global Descriptor Table (GDT)
const GDTEntry = packed struct {
    limit_low: u16,
    base_low: u16,
    base_middle: u8,
    access: GDTAccess,
    limit_high: u4,
    flags: GDTFlags,
    base_high: u8,
};

const GDTAccess = packed struct {
    present: u1,
    ring: u2,
    desc_type: u1,
    executable: u1,
    direction_conform: u1,
    read_write: u1,
    accessed: u1,
};

const GDTFlags = packed struct {
    granularity: u1,
    operand_size: u1,
    long_mode: u1,
    reserved: u1,
};

const GDTPtr = packed struct {
    limit: u16,
    base: u32,
};

////////////////////////////////
// Member variables
////////////////////////////////

var gdt = [_]GDTEntry{
    // The first entry of the GDT is null
    @bitCast(0),
    // Code segment
    GDTEntry{ .base_low = 0, .base_middle = 0, .base_high = 0, .limit_low = 0xFFFF, .limit_high = 0xF, .access = GDTAccess{
        .present = 1,
        .ring = 0,
        .desc_type = 1,
        .executable = 1,
        .direction_conform = 0,
        .read_write = 1,
        .accessed = 0,
    }, .flags = GDTFlags{
        .granularity = 1,
        .operand_size = 1,
        .long_mode = 0,
    } },
    // Data segment
    GDTEntry{ .base_low = 0, .base_middle = 0, .base_high = 0, .limit_low = 0xFFFF, .limit_high = 0xF, .access = GDTAccess{
        .present = 1,
        .ring = 0,
        .desc_type = 1,
        .executable = 0,
        .direction_conform = 0,
        .read_write = 1,
        .accessed = 0,
    }, .flags = GDTFlags{
        .granularity = 1,
        .operand_size = 1,
        .long_mode = 0,
    } },
};
var gdt_ptr = GDTPtr{
    .limit = @sizeOf(GDTEntry) * gdt.len - 1,
    .base = &gdt,
};

////////////////////////////////
// Functions
////////////////////////////////

////////////////////////////////
// Testing
////////////////////////////////

test "GDT entry sizes" {
    try expect(@bitSizeOf(GDTEntry) == 64);
    try expect(@bitSizeOf(GDTAccess) == 8);
    try expect(@bitSizeOf(GDTFlags) == 4);
}
