# ROSAM v0.6.1 Stability Notes

## Stable demonstrated subset

The repository's `README.md` and `API_STATUS.md` identify the following Win64 subset as the currently demonstrated application surface used by `fin.asm`:

- strings
- string copying/equality
- buffers
- integer declarations
- fixed i32 arrays
- console input/output
- i32/i64 arithmetic
- value and variable integer comparison
- increment/decrement
- runtime-indexed array access
- functions
- returns
- labels and goto
- error state
- process exit

## Broader core API

The `core/*.inc` layer declares substantially more functionality:

- memory
- string processing
- text/UTF-8
- integer math
- floating-point math
- bit manipulation
- arrays/containers
- algorithms
- random generation
- formatting
- error handling

That broader list is an API contract. A declaration in `core/` does not, by itself, prove complete feature parity on every backend.

## Design rule

Backend claims should be made from the implementation actually present for the requested target.

This distinction keeps the documentation truthful:

```text
API contract != universal backend parity
```

---

# Versioning

When adding a feature:

1. Define the general API contract.
2. Add/update the macro interface when appropriate.
3. Implement it in each supported backend.
4. Add tests.
5. Update the documentation.
6. Add an example that consumes the public API.

Do not add a private primitive only because one example program needs it.

---

# Why this matters

ROSAM is trying to become a language, not a collection of example-specific assembly macros.

The language must therefore remain independent of individual demo programs.
