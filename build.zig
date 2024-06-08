const std = @import("std");
const log = std.log.scoped(.build);

pub fn build(b: *std.Build) void {
    const target = b.resolveTargetQuery(.{
        // .cpu_arch = .x86_64,
        .cpu_arch = .x86,
        .os_tag = .freestanding,
    });
    const optimize = b.standardOptimizeOption(.{});

    const kernel_main_path = b.path("src/main.zig");
    const linker_script_path = b.path("linker.ld");
    const gdt_script_path = b.path("src/gdt.asm");
    const gdt_obj_path = b.path("build/gdt.o");
    const idt_script_path = b.path("src/idt.asm");
    const idt_obj_path = b.path("build/idt.o");

    const gdt_script_cmd = b.addSystemCommand(&.{
        "nasm",
        gdt_script_path.src_path.sub_path,
        "-felf",
        "-o build/gdt.o",
    });
    b.default_step.dependOn(&gdt_script_cmd.step);
    log.info("src/gdt.asm -> build/gdt.o", .{});

    const idt_script_cmd = b.addSystemCommand(&.{
        "nasm",
        idt_script_path.src_path.sub_path,
        "-felf",
        "-o build/idt.o",
    });
    b.default_step.dependOn(&idt_script_cmd.step);
    log.info("src/idt.asm -> build/idt.o", .{});

    // zig fmt: off
    const kernel = b.addExecutable(.{
        .name = "marlin-os.elf",
        .root_source_file = kernel_main_path,
        .optimize = optimize,
        .target = target
    });
    kernel.setLinkerScript(linker_script_path);
    kernel.addObjectFile(gdt_obj_path);
    kernel.addObjectFile(idt_obj_path);

    b.installArtifact(kernel);

    log.info("src/main.zig -> zig-out/bin/marlin-os.elf", .{});

    // zig fmt: off
    const run_cmd = b.addSystemCommand(&.{
        "qemu-system-x86_64",
        "-kernel",
        "zig-out/bin/marlin-os.elf",
        "-debugcon",
        "stdio",
        "-vga",
        "virtio",
        "-m",
        "4G",
        "-machine",
        "q35,accel=kvm:whpx:tcg",
        "-no-reboot",
        "-no-shutdown"
    });
    const run_step = b.step("run", "Run the OS Kernel");
    run_step.dependOn(&run_cmd.step);
}
