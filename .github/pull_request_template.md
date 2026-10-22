## Summary

<!-- What does this PR change, and why? -->

## Related issues

<!-- e.g. Fixes #123 -->

## Type of change

- [ ] Bug fix
- [ ] New architecture or kernel ABI support
- [ ] Public API change
- [ ] Documentation
- [ ] Build or CI change

## ABI and API impact

<!-- Describe any layout, syscall, or public API changes. -->

- [ ] No public API change
- [ ] Adds or changes a public API
- [ ] Adds or changes a kernel ABI layout
- [ ] 32-bit / Y2038 implications considered
- [ ] `statx` is still not required

## Testing

<!-- Paste relevant output, especially for new architectures. -->

- [ ] `zig fmt --check build.zig src tests`
- [ ] `zig build test --summary all`
- [ ] `zig build check --summary all`

```text
CI or local test output:
```

## Checklist

- [ ] Tests added or updated
- [ ] README updated when behavior or support changes
- [ ] No libc dependency introduced
- [ ] New targets added to the `zig build check` matrix
