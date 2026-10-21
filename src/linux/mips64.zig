//! MIPS N64 kernel `struct stat`.
//!
//! The N64 layout is the "same memory layout as stat64 of the 32-bit kernel"
//! according to the kernel headers, but with native 64-bit `ino`, `size` and
//! `blocks` fields and 32-bit timestamps.
//!
//! Source: Linux `arch/mips/include/uapi/asm/stat.h`.

const std = @import("std");

pub const Timespec = extern struct {
    sec: i32,
    nsec: i32,
};

pub const Stat = extern struct {
    dev: u32,
    __pad0: [3]u32,
    ino: u64,
    mode: u32,
    nlink: u32,
    uid: u32,
    gid: u32,
    rdev: u32,
    __pad1: [3]u32,
    size: i64,
    atim: i32,
    atim_nsec: u32,
    mtim: i32,
    mtim_nsec: u32,
    ctim: i32,
    ctim_nsec: u32,
    blksize: u32,
    __pad3: u32,
    blocks: u64,

    pub fn atime(self: @This()) Timespec {
        return .{ .sec = self.atim, .nsec = @bitCast(self.atim_nsec) };
    }

    pub fn mtime(self: @This()) Timespec {
        return .{ .sec = self.mtim, .nsec = @bitCast(self.mtim_nsec) };
    }

    pub fn ctime(self: @This()) Timespec {
        return .{ .sec = self.ctim, .nsec = @bitCast(self.ctim_nsec) };
    }
};

comptime {
    std.debug.assert(@sizeOf(Timespec) == 8);
    std.debug.assert(@sizeOf(Stat) == 104);
    std.debug.assert(@offsetOf(Stat, "ino") == 16);
    std.debug.assert(@offsetOf(Stat, "mode") == 24);
    std.debug.assert(@offsetOf(Stat, "rdev") == 40);
    std.debug.assert(@offsetOf(Stat, "size") == 56);
    std.debug.assert(@offsetOf(Stat, "blksize") == 88);
    std.debug.assert(@offsetOf(Stat, "blocks") == 96);
}
