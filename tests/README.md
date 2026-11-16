# Headless tests

The test suite has no dependency on LOVE. Run it from the repository root with
plain Lua or LuaJIT:

```sh
lua tests/run.lua
```

The runner intentionally uses only `pcall`, `require`, and a small local
assertion helper. A future test framework may replace it without changing test
module boundaries: each test module returns one function and raises on failure.
