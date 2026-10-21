//! SPARC64 kernel `struct stat64`.
//!
//! The old, non-LFS `stat` on SPARC64 is a different, smaller layout. The
//! kernel exposes `stat64`/`fstat64`/`fstatat64` on this architecture and
//! that is what every modern user space uses, so this module models that
//! layout.
//!
//! Source: Linux `arch/sparc/include/uapi/asm/stat.h`.

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
    __pad0: u32,

    rdev: u64,
    size: i64,
    blksize: i64,
    blocks: i64,

    atim: Timespec,
    mtim: Timespec,
    ctim: Timespec,
    __unused: [3]i64,

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
    std.debug.assert(@offsetOf(Stat, "atim") == 72);
    std.debug.assert(@offsetOf(Stat, "__unused") == 120);
}
