//! Direct Linux syscall wrappers for the `stat` family.
//!
//! Everything here is implemented with `std.os.linux.syscall*`; libc is never
//! linked or called. On architectures where the legacy `stat` entry point
//! does not exist, the equivalent `fstatat`/`newfstatat` call is used, which
//! still works on kernels that predate `statx`.

const std = @import("std");
const builtin = @import("builtin");
const linux = std.os.linux;
const Stat = @import("stat.zig").Stat;

comptime {
    if (builtin.os.tag != .linux) {
        @compileError("zix.stat only supports Linux targets");
    }
}

pub const FStatError = error{
    BadFileDescriptor,
    BadAddress,
    InvalidArgument,
    SystemResources,
    AccessDenied,
    PermissionDenied,
    Unexpected,
};

pub const FStatAtError = FStatError || error{
    FileNotFound,
    NotDir,
    NameTooLong,
    SymLinkLoop,
    Overflow,
};

/// The largest path (in bytes, excluding the terminating NUL) accepted by the
/// non-Z convenience wrappers. This mirrors the kernel's `PATH_MAX` on Linux.
pub const max_path_bytes = std.Io.Dir.max_path_bytes;

fn fdArg(fd: linux.fd_t) usize {
    // Syscall arguments are machine words. Sign extend negative values such as
    // AT.FDCWD before bit-casting them.
    return @as(usize, @bitCast(@as(isize, fd)));
}

fn flagsArg(flags: u32) usize {
    return @as(usize, flags);
}

fn hasFstatAt() bool {
    return @hasField(linux.SYS, "newfstatat") or
        @hasField(linux.SYS, "fstatat64") or
        @hasField(linux.SYS, "fstatat");
}

fn rawFstat(fd: linux.fd_t, st: *Stat) usize {
    if (comptime @hasField(linux.SYS, "fstat64")) {
        return linux.syscall2(.fstat64, fdArg(fd), @intFromPtr(st));
    } else if (comptime @hasField(linux.SYS, "fstat")) {
        return linux.syscall2(.fstat, fdArg(fd), @intFromPtr(st));
    } else if (comptime hasFstatAt()) {
        // riscv and loongarch kernels do not implement fstat, but their
        // newfstatat does implement the empty-path form.
        return rawFstatat(fd, "", st, linux.AT.EMPTY_PATH);
    } else {
        @compileError("zix.stat: this architecture has no fstat or fstatat syscall");
    }
}

fn rawFstatat(
    dirfd: linux.fd_t,
    path: [*:0]const u8,
    st: *Stat,
    flags: u32,
) usize {
    if (comptime @hasField(linux.SYS, "newfstatat")) {
        return linux.syscall4(
            .newfstatat,
            fdArg(dirfd),
            @intFromPtr(path),
            @intFromPtr(st),
            flagsArg(flags),
        );
    } else if (comptime @hasField(linux.SYS, "fstatat64")) {
        return linux.syscall4(
            .fstatat64,
            fdArg(dirfd),
            @intFromPtr(path),
            @intFromPtr(st),
            flagsArg(flags),
        );
    } else if (comptime @hasField(linux.SYS, "fstatat")) {
        return linux.syscall4(
            .fstatat,
            fdArg(dirfd),
            @intFromPtr(path),
            @intFromPtr(st),
            flagsArg(flags),
        );
    } else {
        @compileError("zix.stat: this architecture has no fstatat syscall");
    }
}

fn rawStat(path: [*:0]const u8, st: *Stat) usize {
    if (comptime @hasField(linux.SYS, "stat64")) {
        return linux.syscall2(.stat64, @intFromPtr(path), @intFromPtr(st));
    } else if (comptime @hasField(linux.SYS, "stat")) {
        return linux.syscall2(.stat, @intFromPtr(path), @intFromPtr(st));
    } else if (comptime hasFstatAt()) {
        return rawFstatat(linux.AT.FDCWD, path, st, 0);
    } else {
        @compileError("zix.stat: this architecture has no stat or fstatat syscall");
    }
}

fn rawLstat(path: [*:0]const u8, st: *Stat) usize {
    if (comptime @hasField(linux.SYS, "lstat64")) {
        return linux.syscall2(.lstat64, @intFromPtr(path), @intFromPtr(st));
    } else if (comptime @hasField(linux.SYS, "lstat")) {
        return linux.syscall2(.lstat, @intFromPtr(path), @intFromPtr(st));
    } else if (comptime hasFstatAt()) {
        return rawFstatat(linux.AT.FDCWD, path, st, linux.AT.SYMLINK_NOFOLLOW);
    } else {
        @compileError("zix.stat: this architecture has no lstat or fstatat syscall");
    }
}

/// Lower-level form of `fstat`: returns the raw Linux errno.
///
/// `st` is zeroed before the call so padding bytes never leak uninitialized
/// data when the value is hashed, serialized or compared.
pub fn fstatRaw(fd: linux.fd_t, st: *Stat) linux.E {
    st.* = std.mem.zeroes(Stat);
    return linux.errno(rawFstat(fd, st));
}

/// Lower-level form of `fstatatZ`: returns the raw Linux errno.
pub fn fstatatRaw(dirfd: linux.fd_t, path: [*:0]const u8, st: *Stat, flags: u32) linux.E {
    st.* = std.mem.zeroes(Stat);
    return linux.errno(rawFstatat(dirfd, path, st, flags));
}

/// Lower-level form of `statZ`: returns the raw Linux errno.
pub fn statRaw(path: [*:0]const u8, st: *Stat) linux.E {
    st.* = std.mem.zeroes(Stat);
    return linux.errno(rawStat(path, st));
}

/// Lower-level form of `lstatZ`: returns the raw Linux errno.
pub fn lstatRaw(path: [*:0]const u8, st: *Stat) linux.E {
    st.* = std.mem.zeroes(Stat);
    return linux.errno(rawLstat(path, st));
}

fn mapFstat(err: linux.E) FStatError {
    return switch (err) {
        .SUCCESS => unreachable,
        .BADF => error.BadFileDescriptor,
        .FAULT => error.BadAddress,
        .INVAL => error.InvalidArgument,
        .NOMEM => error.SystemResources,
        .ACCES => error.AccessDenied,
        .PERM => error.PermissionDenied,
        else => error.Unexpected,
    };
}

fn mapFstatAt(err: linux.E) FStatAtError {
    return switch (err) {
        .SUCCESS => unreachable,
        .BADF => error.BadFileDescriptor,
        .FAULT => error.BadAddress,
        .INVAL => error.InvalidArgument,
        .NOMEM => error.SystemResources,
        .ACCES => error.AccessDenied,
        .PERM => error.PermissionDenied,
        .NOENT => error.FileNotFound,
        .NOTDIR => error.NotDir,
        .NAMETOOLONG => error.NameTooLong,
        .LOOP => error.SymLinkLoop,
        .OVERFLOW => error.Overflow,
        else => error.Unexpected,
    };
}

/// Return metadata for an open file descriptor.
///
/// Uses `fstat`/`fstat64` directly. On architectures that do not implement
/// those entry points, the empty-path `fstatat` form is used instead.
pub fn fstat(fd: linux.fd_t) FStatError!Stat {
    var st: Stat = undefined;
    const err = fstatRaw(fd, &st);
    if (err == .SUCCESS) return st;
    return mapFstat(err);
}

/// `fstatat(2)` with a NUL-terminated path.
///
/// `flags` accepts `AT.SYMLINK_NOFOLLOW`, `AT.EMPTY_PATH`, and the other flags
/// understood by the kernel's `fstatat64`/`newfstatat` implementation.
pub fn fstatatZ(dirfd: linux.fd_t, path: [*:0]const u8, flags: u32) FStatAtError!Stat {
    var st: Stat = undefined;
    const err = fstatatRaw(dirfd, path, &st, flags);
    if (err == .SUCCESS) return st;
    return mapFstatAt(err);
}

/// `fstatat(2)` with a Zig slice.
pub fn fstatat(dirfd: linux.fd_t, pathname: []const u8, flags: u32) FStatAtError!Stat {
    var buf: [max_path_bytes]u8 = undefined;
    const path = try toPosixPath(&buf, pathname);
    return fstatatZ(dirfd, path, flags);
}

/// `stat(2)` with a NUL-terminated path.
pub fn statZ(path: [*:0]const u8) FStatAtError!Stat {
    var st: Stat = undefined;
    const err = statRaw(path, &st);
    if (err == .SUCCESS) return st;
    return mapFstatAt(err);
}

/// `stat(2)` with a Zig slice.
pub fn stat(pathname: []const u8) FStatAtError!Stat {
    var buf: [max_path_bytes]u8 = undefined;
    const path = try toPosixPath(&buf, pathname);
    return statZ(path);
}

/// `lstat(2)` with a NUL-terminated path.
pub fn lstatZ(path: [*:0]const u8) FStatAtError!Stat {
    var st: Stat = undefined;
    const err = lstatRaw(path, &st);
    if (err == .SUCCESS) return st;
    return mapFstatAt(err);
}

/// `lstat(2)` with a Zig slice.
pub fn lstat(pathname: []const u8) FStatAtError!Stat {
    var buf: [max_path_bytes]u8 = undefined;
    const path = try toPosixPath(&buf, pathname);
    return lstatZ(path);
}

fn toPosixPath(buf: *[max_path_bytes]u8, pathname: []const u8) FStatAtError![*:0]const u8 {
    if (pathname.len >= max_path_bytes) return error.NameTooLong;
    if (std.mem.indexOfScalar(u8, pathname, 0) != null) return error.InvalidArgument;
    @memcpy(buf[0..pathname.len], pathname);
    buf[pathname.len] = 0;
    return @ptrCast(buf);
}

test "fstat of a pipe reports a FIFO" {
    if (builtin.os.tag != .linux) return error.SkipZigTest;

    var fds: [2]linux.fd_t = undefined;
    const rc = linux.pipe2(&fds, .{});
    try std.testing.expectEqual(linux.E.SUCCESS, linux.errno(rc));
    defer _ = linux.close(fds[0]);
    defer _ = linux.close(fds[1]);

    const st = try fstat(fds[0]);
    try std.testing.expect(isNamedPipeForTest(st));
    try std.testing.expectEqual(@as(i64, 0), st.size);
}

fn isNamedPipeForTest(st: Stat) bool {
    return st.mode & linux.S.IFMT == linux.S.IFIFO;
}

test "stat and lstat agree for a regular file" {
    if (builtin.os.tag != .linux) return error.SkipZigTest;

    const path = "/proc/self/exe";
    const via_stat = try stat(path);
    const via_lstat = try lstat(path);
    try std.testing.expectEqual(via_stat.ino, via_lstat.ino);
    try std.testing.expect(via_stat.mode & linux.S.IFMT == linux.S.IFREG);
}

test "embedded NUL is rejected before the syscall" {
    if (builtin.os.tag != .linux) return error.SkipZigTest;
    try std.testing.expectError(error.InvalidArgument, stat("a\x00b"));
}
