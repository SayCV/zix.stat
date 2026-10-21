//! i386 kernel `struct stat64`.
//!
//! i386 has two ABI layouts: the original `stat` (small, 16-bit ids and
//! 32-bit file sizes) and `stat64`, which is what every 2.6+ kernel and every
//! current libc uses with `fstat64`/`fstatat64`. This module describes the
//! latter; the old `stat` layout is deliberately not exposed.
//!
//! Source: Linux `arch/x86/include/uapi/asm/stat.h`.

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
    std.debug.assert(@sizeOf(Stat) == 96);
    std.debug.assert(@offsetOf(Stat, "mode") == 16);
    std.debug.assert(@offsetOf(Stat, "rdev") == 32);
    std.debug.assert(@offsetOf(Stat, "size") == 44);
    std.debug.assert(@offsetOf(Stat, "blocks") == 56);
    std.debug.assert(@offsetOf(Stat, "atim") == 64);
    std.debug.assert(@offsetOf(Stat, "ino") == 88);
}
