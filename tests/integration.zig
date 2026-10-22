const std = @import("std");
const zix = @import("zix.stat");

test "fstat sees standard output" {
    const st = try zix.fstat(1);
    try std.testing.expect(st.mode != 0);
    try std.testing.expect(st.blksize >= 0);
}

test "stat and lstat on a known readable path" {
    const a = try zix.stat("/proc/self/exe");
    const b = try zix.stat("/proc/self/exe");
    try std.testing.expectEqual(a.ino, b.ino);
    try std.testing.expect((a.mode & zix.S.IFMT) == zix.S.IFREG);
    try std.testing.expect(zix.isFile(a));
    try std.testing.expect(!zix.isDir(a));

    // /proc/self/exe is normally a symlink, so lstat must not follow it.
    const link = try zix.lstat("/proc/self/exe");
    try std.testing.expect((link.mode & zix.S.IFMT) == zix.S.IFLNK);
    try std.testing.expect(zix.isSymLink(link));
}

test "fstatat with AT.EMPTY_PATH matches fstat" {
    const direct = try zix.fstat(1);
    const via_at = try zix.fstatat(1, "", zix.AT.EMPTY_PATH);
    try std.testing.expectEqual(direct.ino, via_at.ino);
    try std.testing.expectEqual(direct.mode, via_at.mode);
}

test "raw wrappers expose errno without throwing" {
    var st: zix.Stat = undefined;
    try std.testing.expectEqual(
        @import("std").os.linux.E.BADF,
        zix.fstatRaw(-1, &st),
    );
}

test "stat rejects an embedded NUL" {
    try std.testing.expectError(error.InvalidArgument, zix.stat("a\x00b"));
}

test "missing path is reported as FileNotFound" {
    try std.testing.expectError(
        error.FileNotFound,
        zix.stat("/this/path/should/not/exist/zix.stat"),
    );
}
