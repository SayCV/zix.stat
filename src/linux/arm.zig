//! 32-bit ARM kernel `struct stat64`, selected by `fstat64`/`fstatat64`.
//!
//! Source: Linux `arch/arm/include/uapi/asm/stat.h`.

const std = @import("std");

pub const Timespec = extern struct {
    sec: i32,
    nsec: i32,
};

pub const Stat = extern struct {
    dev: u64,
    __dev_padding: u32,
    __ino_truncated: u32,
    mode: u32,
    nlink: u32,
    uid: u32,
    gid: u32,
    rdev: u64,
    __rdev_padding: u32,
    size: i64,
    blksize: i32,
    blocks: i64,
    atim: Timespec,
    mtim: Timespec,
    ctim: Timespec,
    ino: u64,

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
    std.debug.assert(@offsetOf(Stat, "size") == 48);
    std.debug.assert(@offsetOf(Stat, "ino") == 96);
}
