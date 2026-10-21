//! RISC-V 64 kernel `struct stat`, the asm-generic 64-bit layout.
//!
//! Source: Linux `include/uapi/asm-generic/stat.h`.

const std = @import("std");

pub const Timespec = extern struct {
    sec: i64,
    nsec: i64,
};

pub const Stat = extern struct {
    dev: u64,
    ino: u64,
    mode: u32,
    nlink: u32,
    uid: u32,
    gid: u32,
    rdev: u64,
    __pad: u64,
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
    std.debug.assert(@sizeOf(Timespec) == 16);
    std.debug.assert(@sizeOf(Stat) == 128);
    std.debug.assert(@offsetOf(Stat, "mode") == 16);
    std.debug.assert(@offsetOf(Stat, "rdev") == 32);
    std.debug.assert(@offsetOf(Stat, "size") == 48);
    std.debug.assert(@offsetOf(Stat, "atim") == 72);
}
