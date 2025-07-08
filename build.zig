const std = @import("std");
const elf2uf2 = @import("mz_tools_uf2");

const EXE_NAME = "gb-pico";

pub fn build(b: *std.Build) void {
    const optimise = b.standardOptimizeOption(.{});
    const target = b.resolveTargetQuery(.{
        .cpu_arch = .riscv32,
        .os_tag = .freestanding,
        .abi = .none,
    });

    const module = b.addModule(EXE_NAME, .{
        .optimize = optimise,
        .target = target,
    });

    const elf = b.addExecutable(.{
        .name = EXE_NAME,
        .optimize = optimise,
        .root_module = module,
    });

    elf.addAssemblyFile(b.path("src/start.s"));
    elf.setLinkerScript(b.path("linker.ld"));

    const artifact = b.addInstallArtifact(elf, .{});
    b.getInstallStep().dependOn(&artifact.step);

    // In order to work on a RP2350, the executable needs to be an
    // [UF2](https://github.com/microsoft/uf2) file.
    const uf2_dep = b.dependency("mz_tools_uf2", .{});

    const uf2_file = elf2uf2.from_elf(uf2_dep, elf, .{ .family_id = .RP2350_RISC_V });

    _ = b.addInstallFile(uf2_file, "bin/" ++ EXE_NAME ++ ".uf2");
}
