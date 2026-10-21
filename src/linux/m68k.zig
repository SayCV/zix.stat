//! Motorola 68000 kernel `struct stat64`.
//!
//! The m68k C ABI only requires 2-byte alignment for 64-bit integers; the
//! compiler handles that automatically for this extern struct.
//!
//! Source: Linux `arch/m68k/include/uapi/asm/stat.h`.

const std = @import("std");

pub const Timespec = extern struct {
    sec: i32,
    nsec: i32,
};

pub const Stat = extern struct {
    dev: u64,
    __pad: i16,
    __ino_truncated: i32,
    mode: u32,
    nlink: u32,
    uid: u32,
    gid: u32,
    rdev: u64,
    __pad2: i16,
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
    std.debug.assert(@offsetOf(Stat, "__ino_truncated") == 12);
    std.debug.assert(@offsetOf(Stat, "mode") == 16);
    std.debug.assert(@offsetOf(Stat, "size") == 48);
    std.debug.assert(@offsetOf(Stat, "atim") == 72);
    std.debug.assert(@offsetOf(Stat, "ino") == 96);
}
