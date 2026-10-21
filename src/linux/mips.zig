//! MIPS O32 kernel `struct stat64`.
//!
//! MIPS O32 has a `stat64` syscall even though it is a 32-bit ABI. Its
//! timestamps are still 32-bit `long` values (the "insane padding" layout
//! inherited from glibc 2.1).
//!
//! Source: Linux `arch/mips/include/uapi/asm/stat.h`.

const std = @import("std");

pub const Timespec = extern struct {
    sec: i32,
    nsec: i32,
};

pub const Stat = extern struct {
    dev: u32,
    __pad0: [3]u32, // The kernel uses 32-bit dev + three padding words.
    ino: u64,
    mode: u32,
    nlink: u32,
    uid: u32,
    gid: u32,
    rdev: u32,
    __pad1: [3]u32,
    size: i64,
    atim: i32,
    atim_nsec: i32,
    mtim: i32,
    mtim_nsec: i32,
    ctim: i32,
    ctim_nsec: i32,
    blksize: u32,
    __pad3: u32,
    blocks: u64,

    pub fn atime(self: @This()) Timespec {
        return .{ .sec = self.atim, .nsec = self.atim_nsec };
    }

    pub fn mtime(self: @This()) Timespec {
        return .{ .sec = self.mtim, .nsec = self.mtim_nsec };
    }

    pub fn ctime(self: @This()) Timespec {
        return .{ .sec = self.ctim, .nsec = self.ctim_nsec };
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
