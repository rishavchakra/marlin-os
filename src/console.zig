////////////////////////////////
// Constants
////////////////////////////////

const VGA_WIDTH = 80;
const VGA_HEIGHT = 25;
const VGA_SIZE = VGA_WIDTH * VGA_HEIGHT;

////////////////////////////////
// Type definitions
////////////////////////////////

pub const ConsoleColor = enum(u8) {
    Black,
    Blue,
    Green,
    Cyan,
    Red,
    Magenta,
    Brown,
    LightGray,
    DarkGray,
    LightBlue,
    LightGreen,
    LightCyan,
    LightRed,
    LightMagenta,
    LightBrown,
    White,
};
pub const VgaColor = u8;
pub const VgaChar = u16;

////////////////////////////////
// Member variables
////////////////////////////////

var cursor_row: usize = 0;
var cursor_col: usize = 0;
var cursor_color: u8 = initVgaColor(.White, .Black);
var console_buffer = @as([*]volatile u16, @ptrFromInt(0xB8000));

////////////////////////////////
// Private functions
////////////////////////////////

fn initVgaColor(fg: ConsoleColor, bg: ConsoleColor) VgaColor {
    return @intFromEnum(fg) | (@intFromEnum(bg) << 4);
}

fn initVgaCharacter(char: u8, color: VgaColor) VgaChar {
    return char | (@as(u16, color) << 8);
}

////////////////////////////////
// Public functions
////////////////////////////////

pub fn init() void {
    clear();
}

pub fn clear() void {
    @memset(console_buffer[0..VGA_SIZE], initVgaCharacter(' ', cursor_color));
}

pub fn setColor(color: VgaColor) void {
    cursor_color = color;
}

pub fn putCharAt(char: u8, color: VgaColor, x: usize, y: usize) void {
    const index = x + (y * VGA_WIDTH);
    const vga_entry = initVgaCharacter(char, color);
    console_buffer[index] = vga_entry;
}

pub fn putChar(char: u8) void {
    switch (char) {
        '\n' => {
            cursor_col = 0;
            cursor_row += 1;
        },
        else => {
            putCharAt(char, cursor_color, cursor_col, cursor_row);
            cursor_col += 1;
        },
    }

    if (cursor_col == VGA_WIDTH) {
        // Reach the end of console row
        cursor_col = 0;
        cursor_row += 1;
    }
    if (cursor_row == VGA_HEIGHT) {
        // Reached end of last console row
        for (0..VGA_SIZE - VGA_WIDTH) |i| {
            console_buffer[i] = console_buffer[i + VGA_WIDTH];
        }
        @memset(console_buffer[VGA_SIZE - VGA_WIDTH..VGA_SIZE], initVgaCharacter(' ', cursor_color));
        cursor_row = VGA_HEIGHT - 1;
    }
}

pub fn putString(string: []const u8) void {
    for (string) |char| {
        putChar(char);
    }
}
