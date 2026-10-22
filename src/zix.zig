//! zix.stat - the Linux `stat` family for kernels older than statx(2).
//!
//! Zig 0.17 removed `std.posix.fstat`/`stat`/`fstatat` and the Linux
//! `struct stat` definitions. This package brings back the kernel ABI, without
//! linking libc, so programs can still query file metadata on old kernels,
//! in seccomp sandboxes that reject statx, and on systems where libc's
//! `struct stat` is not the kernel's `struct stat`.
//!
//! ```zig
//! const zix = @import("zix.stat");
//!
//! const st = try zix.fstat(fd);
//! if (zix.isDir(st)) {
//!     // ...
//! }
//! ```

const builtin = @import("builtin");
const std = @import("std");

pub const sys = @import("sys.zig");
pub const layout = @import("stat.zig");

pub const Stat = layout.Stat;
pub const Timespec = layout.Timespec;
pub const Kind = layout.Kind;
pub const kind = layout.kind;
pub const isDir = layout.isDir;
pub const isFile = layout.isFile;
pub const isSymLink = layout.isSymLink;
pub const isCharacterDevice = layout.isCharacterDevice;
pub const isBlockDevice = layout.isBlockDevice;
pub const isNamedPipe = layout.isNamedPipe;
pub const isSocket = layout.isSocket;
pub const isSetuid = layout.isSetuid;
pub const isSetgid = layout.isSetgid;
pub const isSticky = layout.isSticky;

pub const toTimestamp = layout.toTimestamp;
pub const atimeTimestamp = layout.atimeTimestamp;
pub const mtimeTimestamp = layout.mtimeTimestamp;
pub const ctimeTimestamp = layout.ctimeTimestamp;

pub const FStatError = sys.FStatError;
pub const FStatAtError = sys.FStatAtError;

pub const fstat = sys.fstat;
pub const fstatat = sys.fstatat;
pub const fstatatZ = sys.fstatatZ;
pub const stat = sys.stat;
pub const statZ = sys.statZ;
pub const lstat = sys.lstat;
pub const lstatZ = sys.lstatZ;
pub const isStatxSupported = sys.isStatxSupported;

/// Convenience wrapper for `std.Io.File`.
pub fn fstatFile(file: std.Io.File) FStatError!Stat {
    return fstat(file.handle);
}

pub const fstatRaw = sys.fstatRaw;
pub const fstatatRaw = sys.fstatatRaw;
pub const statRaw = sys.statRaw;
pub const lstatRaw = sys.lstatRaw;

pub const max_path_bytes = sys.max_path_bytes;
pub const AT = std.os.linux.AT;
pub const S = std.os.linux.S;

comptime {
    if (builtin.os.tag != .linux) {
        @compileError("zix.stat only supports Linux targets");
    }
}

test {
    _ = sys;
    _ = layout;
}
