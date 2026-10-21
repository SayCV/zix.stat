//! Kernel ABI selection for `struct stat`.
//!
//! Zig 0.17 removed the Linux `struct stat` family from the standard library
//! because each architecture (and, historically, each libc) ships a slightly
//! different layout. This module keeps those layouts locally, matching the
//! kernel UAPI headers and not any particular libc.
//!
//! The selected layout is always the one written by the syscall this package
//! uses:
//!
//! * 32-bit architectures use the `stat64` layout through `fstat64` /
//!   `fstatat64`.
//! * 64-bit architectures use the native `struct stat`.
//! * SPARC64 is special: its `fstat64`/`fstatat64` write the `stat64` layout,
//!   so that is the layout exposed here.

const std = @import("std");
const builtin = @import("builtin");
const linux = std.os.linux;

pub const Arch = switch (builtin.cpu.arch) {
    .x86_64 => @import("linux/x86_64.zig"),
    .x86 => @import("linux/x86.zig"),
    .aarch64, .aarch64_be => @import("linux/aarch64.zig"),
    .arm, .armeb, .thumb, .thumbeb => @import("linux/arm.zig"),
    .riscv64 => @import("linux/riscv64.zig"),
    .loongarch64 => @import("linux/loongarch64.zig"),
    .powerpc, .powerpcle => @import("linux/powerpc.zig"),
    .powerpc64, .powerpc64le => @import("linux/powerpc64.zig"),
    .s390x => @import("linux/s390x.zig"),
    .sparc64 => @import("linux/sparc64.zig"),
    .m68k => @import("linux/m68k.zig"),
    .hexagon => @import("linux/hexagon.zig"),
    .mips, .mipsel => @import("linux/mips.zig"),
    .mips64, .mips64el => switch (builtin.abi) {
        .gnuabin32, .muslabin32, .abin32 => @compileError(
            "zix.stat: MIPS n32 is not supported yet; use statx on this ABI",
        ),
        else => @import("linux/mips64.zig"),
    },
    else => @compileError(
        "zix.stat: this Linux architecture has no maintained struct stat layout; " ++
            "use std.os.linux.statx or add src/linux/<arch>.zig",
    ),
};

pub const Stat = Arch.Stat;
pub const Timespec = Arch.Timespec;

pub const Kind = enum {
    block_device,
    character_device,
    directory,
    named_pipe,
    sym_link,
    file,
    unix_domain_socket,
    unknown,
};

/// Classify a `st_mode` value. The kernel only defines the low four bits of
/// the file type, so unknown types are reported rather than panicking.
pub fn kind(st: Stat) Kind {
    return switch (st.mode & linux.S.IFMT) {
        linux.S.IFBLK => .block_device,
        linux.S.IFCHR => .character_device,
        linux.S.IFDIR => .directory,
        linux.S.IFIFO => .named_pipe,
        linux.S.IFLNK => .sym_link,
        linux.S.IFREG => .file,
        linux.S.IFSOCK => .unix_domain_socket,
        else => .unknown,
    };
}

pub fn isDir(st: Stat) bool {
    return kind(st) == .directory;
}

pub fn isFile(st: Stat) bool {
    return kind(st) == .file;
}

pub fn isSymLink(st: Stat) bool {
    return kind(st) == .sym_link;
}

pub fn isCharacterDevice(st: Stat) bool {
    return kind(st) == .character_device;
}

pub fn isBlockDevice(st: Stat) bool {
    return kind(st) == .block_device;
}

pub fn isNamedPipe(st: Stat) bool {
    return kind(st) == .named_pipe;
}

pub fn isSocket(st: Stat) bool {
    return kind(st) == .unix_domain_socket;
}

pub fn isSetuid(st: Stat) bool {
    return (st.mode & linux.S.ISUID) != 0;
}

pub fn isSetgid(st: Stat) bool {
    return (st.mode & linux.S.ISGID) != 0;
}

pub fn isSticky(st: Stat) bool {
    return (st.mode & linux.S.ISVTX) != 0;
}

/// Convert a kernel `timespec` (seconds plus nanoseconds) to the
/// nanosecond-based timestamp used by `std.Io`.
///
/// The calculation is `sec * 1_000_000_000 + nsec`. This also works for
/// pre-epoch values because the kernel keeps `nsec` in [0, 1e9) while `sec`
/// carries the sign.
pub fn toTimestamp(ts: Timespec) std.Io.Timestamp {
    return std.Io.Timestamp.fromNanoseconds(
        @as(i96, ts.sec) * std.time.ns_per_s + @as(i96, ts.nsec),
    );
}

pub fn atimeTimestamp(st: Stat) std.Io.Timestamp {
    return toTimestamp(st.atime());
}

pub fn mtimeTimestamp(st: Stat) std.Io.Timestamp {
    return toTimestamp(st.mtime());
}

pub fn ctimeTimestamp(st: Stat) std.Io.Timestamp {
    return toTimestamp(st.ctime());
}

test "Timespec converts to std.Io.Timestamp" {
    const ts: Timespec = .{ .sec = 1_700_000_000, .nsec = 123_456_789 };
    const timestamp = toTimestamp(ts);
    try std.testing.expectEqual(
        @as(i96, 1_700_000_000_123_456_789),
        timestamp.toNanoseconds(),
    );

    const before_epoch: Timespec = .{ .sec = -1, .nsec = 500_000_000 };
    try std.testing.expectEqual(
        @as(i96, -500_000_000),
        toTimestamp(before_epoch).toNanoseconds(),
    );
}
