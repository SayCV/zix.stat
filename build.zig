const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // The public module. Consumers import it as `zix.stat`.
    const zix_stat = b.addModule("zix.stat", .{
        .root_source_file = b.path("src/zix.zig"),
        .target = target,
        .optimize = optimize,
    });

    // A static archive is convenient for build systems that are not using the
    // Zig package manager. The module above is the real interface.
    const lib = b.addLibrary(.{
        .name = "zix_stat",
        .root_module = zix_stat,
        .linkage = .static,
    });
    b.installArtifact(lib);

    const unit_tests = b.addTest(.{ .root_module = zix_stat });
    const run_unit_tests = b.addRunArtifact(unit_tests);

    const integration_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/integration.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "zix.stat", .module = zix_stat },
            },
        }),
    });
    const run_integration_tests = b.addRunArtifact(integration_tests);

    const test_step = b.step("test", "Run unit and integration tests (requires Linux)");
    test_step.dependOn(&run_unit_tests.step);
    test_step.dependOn(&run_integration_tests.step);

    // Cross-compile the layout assertions and the public API for every
    // supported ABI. This is useful from a non-Linux host, where the test
    // binaries cannot be executed.
    const check_step = b.step("check", "Compile-check every supported Linux ABI");
    const targets = [_][]const u8{
        "x86_64-linux-gnu",
        "x86_64-linux-musl",
        "x86_64-linux-gnux32",
        "x86_64-linux-muslx32",
        "x86-linux-gnu",
        "x86-linux-musl",
        "aarch64-linux-gnu",
        "aarch64-linux-musl",
        "aarch64_be-linux-gnu",
        "arm-linux-gnueabihf",
        "arm-linux-musleabihf",
        "armeb-linux-gnueabihf",
        "thumb-linux-gnueabihf",
        "thumbeb-linux-gnueabihf",
        "riscv64-linux-gnu",
        "riscv64-linux-musl",
        "loongarch64-linux-gnu",
        "loongarch64-linux-musl",
        "powerpc-linux-gnu",
        "powerpc-linux-musl",
        "powerpc64-linux-gnu",
        "powerpc64le-linux-gnu",
        "s390x-linux-gnu",
        "sparc64-linux-gnu",
        "m68k-linux-gnu",
        "hexagon-linux-musl",
        "mips-linux-gnu",
        "mipsel-linux-gnu",
        "mips64-linux-gnuabi64",
        "mips64el-linux-gnuabi64",
    };

    for (targets) |query| {
        const resolved = std.Target.Query.parse(.{ .arch_os_abi = query }) catch @panic("invalid check target");
        const check_target = b.resolveTargetQuery(resolved);
        const check_zix = b.createModule(.{
            .root_source_file = b.path("src/zix.zig"),
            .target = check_target,
            .optimize = .ReleaseSafe,
        });
        const check_module = b.createModule(.{
            .root_source_file = b.path("tests/layouts.zig"),
            .target = check_target,
            .optimize = .ReleaseSafe,
            .imports = &.{
                .{ .name = "zix.stat", .module = check_zix },
            },
        });
        const check_obj = b.addObject(.{
            .name = "zix_stat_layout_check",
            .root_module = check_module,
        });
        check_step.dependOn(&check_obj.step);

        // Compile (but do not execute) the unit tests for this target too, so
        // the test-only syscall paths and error mappings are type-checked.
        const check_unit_tests = b.addTest(.{
            .root_module = check_zix,
        });
        check_step.dependOn(&check_unit_tests.step);

        const check_integration_module = b.createModule(.{
            .root_source_file = b.path("tests/integration.zig"),
            .target = check_target,
            .optimize = .ReleaseSafe,
            .imports = &.{
                .{ .name = "zix.stat", .module = check_zix },
            },
        });
        const check_integration = b.addTest(.{
            .root_module = check_integration_module,
        });
        check_step.dependOn(&check_integration.step);
    }
}
