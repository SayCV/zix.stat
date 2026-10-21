//! Hexagon kernel `struct stat64`, selected by `fstat64`/`fstatat64`.
//!
//! Source: Linux `include/uapi/asm-generic/stat.h` (Hexagon uses the generic
//! 32-bit stat64 layout).

const std = @import("std");

pub const Timespec = extern struct {
    sec: i32,
    nsec: i32,
};

pub const Stat = extern struct {
    dev: u64,
    ino: u64,
    mode: u32,
    nlink: u32,
    uid: u32,
    gid: u32,
    rdev: u64,
    __pad: u32,
    size: i64,
    blksize: i32,
    __pad2: i32,
    blocks: i64,
    atim: Timespec,
    mtim: Timespec,
    ctim: Timespec,
    __unused: [2]u32,

    pub fn atime(self: @This()) Timespec {
        return self.atim;
    }

    pub fn mtime(self: @This()) Timespec {
        return self.mtim;
    }

    pub fn ctime(self: @This()) Timespec {
        return self.ctim;
    }
};

comptime {
    std.debug.assert(@sizeOf(Timespec) == 8);
    std.debug.assert(@sizeOf(Stat) == 104);
    std.debug.assert(@offsetOf(Stat, "mode") == 16);
    std.debug.assert(@offsetOf(Stat, "rdev") == 32);
    std.debug.assert(@offsetOf(Stat, "size") == 48);
    std.debug.assert(@offsetOf(Stat, "atim") == 72);
}
