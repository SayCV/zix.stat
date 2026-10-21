//! Compile-time layout and API check.
//!
//! This file is built (not run) for every supported ABI by `zig build check`.
//! The per-architecture modules contain their own size and offset assertions;
//! the references here make sure the public module graph is instantiated too.

const std = @import("std");
const zix = @import("zix.stat");

comptime {
    _ = zix.Stat;
    _ = zix.Timespec;
    _ = zix.fstat;
    _ = zix.fstatat;
    _ = zix.fstatatZ;
    _ = zix.stat;
    _ = zix.lstat;
    _ = zix.fstatRaw;
    _ = zix.kind;
    _ = zix.isDir;
    _ = zix.AT;
    _ = zix.S;

    // A struct stat must always fit in a small stack object, and every
    // supported ABI has a non-zero, word-sized-aligned layout.
    std.debug.assert(@sizeOf(zix.Stat) > 0);
    std.debug.assert(@sizeOf(zix.Stat) <= 256);
}

// Force every syscall path in the public API to be analyzed for this target.
// `zig build check` runs with `-fno-emit-bin`, so this is a compile-only probe.
export fn zixStatCompileProbe(fd: i32) void {
    var st: zix.Stat = undefined;

    _ = zix.fstatRaw(fd, &st);
    _ = zix.fstatatRaw(fd, "/", &st, zix.AT.EMPTY_PATH);
    _ = zix.statRaw("/", &st);
    _ = zix.lstatRaw("/", &st);

    _ = zix.fstat(fd) catch {};
    _ = zix.fstatFile(.{ .handle = fd, .flags = .{ .nonblocking = false } }) catch {};
    _ = zix.fstatatZ(fd, "/", 0) catch {};
    _ = zix.fstatat(fd, "/", 0) catch {};
    _ = zix.stat("/") catch {};
    _ = zix.lstat("/") catch {};

    _ = zix.kind(st);
    _ = zix.isDir(st);
    _ = zix.toTimestamp(st.atime());
    _ = zix.atimeTimestamp(st);
    _ = zix.mtimeTimestamp(st);
    _ = zix.ctimeTimestamp(st);
}
