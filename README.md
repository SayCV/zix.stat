# zix.stat

[![CI](https://github.com/SayCV/zix.stat/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/SayCV/zix.stat/actions/workflows/ci.yml)

`zix.stat` restores the Linux kernel `stat` family for Zig 0.17 and newer,
without linking libc and without requiring `statx(2)`.

Zig removed `std.posix.stat` / `fstat` / `fstatat` and the per-architecture
Linux `struct stat` types because maintaining every kernel ABI (plus libc
variants, padding, 32/64-bit time and large-file layouts) was too expensive.
Modern Zig uses `statx(2)` instead.

That is a problem when:

* the kernel is older than Linux 4.11 and has no `statx`,
* a seccomp policy or sandbox rejects `statx`, or
* a libc's `struct stat` is intentionally different from the kernel ABI.

This package keeps the kernel ABI layouts locally and calls
`stat`/`fstat`/`lstat`/`fstatat` directly with `std.os.linux.syscall*`.

## Features

* Pure direct syscalls: no libc, no `@cImport`, no FFI.
* Kernel UAPI layouts, not glibc/musl user-space layouts.
* 32-bit architectures use `stat64` / `fstat64` / `lstat64` / `fstatat64`.
* Arch-generic 64-bit targets fall back to `newfstatat` when the legacy
  `stat` entry point does not exist.
* Raw wrappers that return `std.os.linux.E` for callers that need the exact
  errno.
* Compile-time size and offset assertions for every supported ABI.
* A cross-compilation check matrix (`zig build check`) for 30 target triples.

## Importing

The Zig package name is `zix_stat`; the module name is `zix.stat`.

```zig
const dep = b.dependency("zix_stat", .{
    .target = target,
    .optimize = optimize,
});

exe.root_module.addImport("zix.stat", dep.module("zix.stat"));
```

Then:

```zig
const zix = @import("zix.stat");
```

## Usage

```zig
const std = @import("std");
const zix = @import("zix.stat");

pub fn main() !void {
    const file = std.Io.File.stdout(); // 0.17 API; any open File works
    const st = try zix.fstatFile(file);
    std.debug.print("size={} mode=0o{o} kind={}\\n", .{
        st.size,
        st.mode,
        zix.kind(st),
    });
}
```

Path-based calls:

```zig
const st = try zix.stat("/etc/passwd");       // follows symlinks
const link = try zix.lstat("/etc/passwd");    // does not follow symlinks
const rel = try zix.fstatat(dirfd, "child", 0);
const by_fd = try zix.fstatat(dirfd, "", zix.AT.EMPTY_PATH);

try std.testing.expect(zix.isFile(st));
try std.testing.expect(zix.isSymLink(link));
```

### Converting times

The embedded fields are kernel `timespec` values. Use the helpers to get a
`std.Io.Timestamp` (nanoseconds since the Unix epoch):

```zig
const atime: std.Io.Timestamp = zix.atimeTimestamp(st);
const mtime: std.Io.Timestamp = zix.mtimeTimestamp(st);
const ctime: std.Io.Timestamp = zix.ctimeTimestamp(st);

// Or convert a `Timespec` directly:
const ts = zix.toTimestamp(st.atime());
std.debug.print("mtime ns = {}\\n", .{ts.toNanoseconds()});
```

The conversion is `sec * std.time.ns_per_s + nsec`. It also handles
pre-epoch timestamps because the kernel keeps the sign in `sec` and a
non-negative `nsec`.

`stat`, `lstat`, and `fstatat` accept `[]const u8` paths. The
null-terminated variants are available as `statZ`, `lstatZ`, and
`fstatatZ` for callers that already own a C string.

Raw variants return the raw kernel errno rather than a Zig error:

```zig
var st: zix.Stat = undefined;
const errno = zix.fstatRaw(fd, &st);
if (errno == .SUCCESS) {
    // st is valid
}
```

For raw calls, the stat buffer is zeroed before the syscall, so padding bytes
are deterministic even when they are not written by the kernel.

## Error handling

High-level calls return `FStatError` or `FStatAtError`. Common mappings:

| errno | Zig error |
| --- | --- |
| `EBADF` | `error.BadFileDescriptor` |
| `EACCES` | `error.AccessDenied` |
| `EPERM` | `error.PermissionDenied` |
| `ENOENT` | `error.FileNotFound` |
| `ENOTDIR` | `error.NotDir` |
| `ENAMETOOLONG` | `error.NameTooLong` |
| `ELOOP` | `error.SymLinkLoop` |
| `ENOMEM` | `error.SystemResources` |
| `EFAULT` | `error.BadAddress` |
| `EINVAL` | `error.InvalidArgument` |
| `EOVERFLOW` | `error.Overflow` |
| other | `error.Unexpected` |

Use the `*Raw` functions if you need to distinguish an errno that is not
listed above.

## Supported ABIs

The selected layout matches the syscall that the package actually uses on that
target.

| Architecture | Syscalls used | Kernel layout | Size |
| --- | --- | --- | ---: |
| `x86_64` (including x32) | `stat`, `fstat`, `lstat`, `newfstatat` | `struct stat` | 144 |
| `x86` (i386) | `stat64`, `fstat64`, `lstat64`, `fstatat64` | `struct stat64` | 96 |
| `aarch64` / `aarch64_be` | `fstat`, `newfstatat` | asm-generic 64-bit `struct stat` | 128 |
| `arm` / `armeb` / thumb | `stat64`, `fstat64`, `lstat64`, `fstatat64` | `struct stat64` | 104 |
| `riscv64` | `fstat`, `newfstatat` | asm-generic 64-bit `struct stat` | 128 |
| `loongarch64` | `fstat`, `newfstatat` | asm-generic 64-bit `struct stat` | 128 |
| `powerpc` / `powerpcle` | `stat64`, `fstat64`, `lstat64`, `fstatat64` | `struct stat64` | 104 |
| `powerpc64` / `powerpc64le` | `stat`, `fstat`, `lstat`, `newfstatat` | `struct stat` | 144 |
| `s390x` | `stat`, `fstat`, `lstat`, `newfstatat` | `struct stat` | 144 |
| `sparc64` | `stat64`, `fstat64`, `lstat64`, `fstatat64` | `struct stat64` | 144 |
| `m68k` | `stat64`, `fstat64`, `lstat64`, `fstatat64` | `struct stat64` | 104 |
| `hexagon` | `fstat64`, `fstatat64` (path calls use `fstatat64`) | `struct stat64` | 104 |
| `mips` / `mipsel` (O32) | `stat64`, `fstat64`, `lstat64`, `fstatat64` | `struct stat64` | 104 |
| `mips64` / `mips64el` (N64) | `stat`, `fstat`, `lstat`, `newfstatat` | `struct stat` | 104 |

Unsupported ABIs fail to compile with an explicit message:

* MIPS n32 (`gnuabin32`, `muslabin32`, `abin32`),
* RISC-V 32-bit,
* other architectures not listed above.

If a target has a legacy layout that is not covered, add a module under
`src/linux/` and select it in `src/stat.zig`. Also add the target to the
`zig build check` matrix.

### Time fields

The embedded timestamp fields follow the kernel ABI. On 32-bit targets this
means the legacy 32-bit `time_t` layout used by `stat64`; those calls are not
Y2038-safe after 2038-01-19. The `atime()`, `mtime()`, and `ctime()` methods
return the same-width `Timespec` for the selected architecture.

### System call fallback

At compile time the package checks which syscall names exist for the target:

1. `fstat64` then `fstat`, otherwise an empty-path `fstatat`.
2. `newfstatat` then `fstatat64` then `fstatat`.
3. `stat64` then `stat`, otherwise `fstatat` with `AT.FDCWD`.
4. `lstat64` then `lstat`, otherwise `fstatat` with `AT.FDCWD` and
   `AT.SYMLINK_NOFOLLOW`.

This keeps the library usable on older kernels while still supporting modern
architectures that only implement `newfstatat`.

## Testing

On a Linux host:

```sh
zig build test
```

From Windows or macOS, cross-compile the library, test binaries, and layout
assertions without trying to execute them:

```sh
zig build check --summary all
```

`zig build check` compiles the library, the unit tests, the integration tests,
and the layout probe for:

`x86_64` (gnu, musl, gnux32, muslx32), `x86`, `aarch64` (including
`aarch64_be`), `arm` (including `armeb`, `thumb`, and `thumbeb`), `riscv64`,
`loongarch64`, `powerpc`, `powerpc64`, `powerpc64le`, `s390x`, `sparc64`,
`m68k`, `hexagon`, `mips`, `mipsel`, `mips64`, and `mips64el`.

## Non-goals

* Reproducing libc's `struct stat` / `stat64` wrappers. This library exposes
  the kernel ABI.
* `statx(2)`. Zig's standard library already provides the modern path; this
  package is for environments where that path is unavailable.
* Automatic Y2038 conversion on 32-bit targets.

## License

MIT. See `LICENSE`.
