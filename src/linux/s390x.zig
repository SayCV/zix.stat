//! s390x kernel `struct stat`.
//!
//! Source: Linux `arch/s390/include/uapi/asm/stat.h`.

const std = @import("std");

pub const Timespec = extern struct {
    sec: i64,
    nsec: i64,
};

pub const Stat = extern struct {
    dev: u64,
    ino: u64,
    nlink: u64,
    mode: u32,
    uid: u32,
    gid: u32,
    __pad1: u32,
    rdev: u64,
    size: i64,
    atim: Timespec,
    mtim: Timespec,
    ctim: Timespec,
    blksize: i64,
    blocks: i64,
    __unused: [3]u64,

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
    std.debug.assert(@sizeOf(Stat) == 144);
    std.debug.assert(@offsetOf(Stat, "mode") == 24);
    std.debug.assert(@offsetOf(Stat, "rdev") == 40);
    std.debug.assert(@offsetOf(Stat, "size") == 48);
    std.debug.assert(@offsetOf(Stat, "atim") == 56);
    std.debug.assert(@offsetOf(Stat, "blksize") == 104);
    std.debug.assert(@offsetOf(Stat, "__unused") == 120);
}
