Read this when a migrated unit moves, borrows or shares values, returns Result or Option, propagates errors, panics, or relies on drop order.

# Ownership and errors (Rust 1.99.1 stable)

## Ownership and moves

- Each value has one owner. Assigning a value that is not `Copy` moves it. After `let s2 = s1;` the name `s1` is invalid, and using it is a compile error (Book, chapter 4.1).
- Parity: when the source lets two names share one object, a move is not the same thing. Choose a shared owner (`Rc<T>` in one thread, `Arc<T>` across threads) or a copy, based on what the source does. Test that both names see the same state after a change.
- `clone()` makes an independent copy. Use it only when the source copies. A clone that the source does not make changes behavior.

## Borrowing

- At any time a value has either one mutable reference or any number of immutable references (Book, chapter 4.2).
- Express the source's aliasing through the owner or an index into a `Vec`, or through shared-state types when the source mutates shared state. Do not work around the checker by cloning the whole structure.
- A reference lasts until its last use. Reordering statements can change which borrows compile, so keep the source's order of writes.

## Result and the ? operator

- `Result<T, E>` is `Ok(T)` or `Err(E)`. `?` returns the `Err` early from the function. When the error types differ, `?` calls `From::from` to convert the error (Book, chapter 9.2).
- `unwrap()` on a `Result` returns the `Ok` value. On `Err` it calls `panic!` (Book, chapter 9.2).
- Use `Result` for failures that input can cause. Panic only for a broken internal invariant. A panic on bad input changes the source's error response.
- Map each source error to one enum variant. Keep the source's code and message text where the source has stable ones.

```rust
#[derive(Debug, PartialEq)]
pub enum UnitError {
    Empty,
    TooLarge { limit: u32 },
}

pub fn check_len(s: &str, limit: u32) -> Result<usize, UnitError> {
    if s.is_empty() {
        return Err(UnitError::Empty);
    }
    if s.len() > limit as usize {
        return Err(UnitError::TooLarge { limit });
    }
    Ok(s.len())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn empty_input_maps_to_empty_error() {
        assert_eq!(check_len("", 3), Err(UnitError::Empty));
    }
}
```

The snippet shows one error enum, one check and one test. The variant names and the rule order are examples; take them from the source.

## Panics

- By default a panic unwinds the stack, and the values on it are dropped on the way out (Book, chapter 9.1).
- Unwinding can be switched to abort (Book, chapter 9.1). A build that aborts does not run destructors on the way out. Check the profile the source ships with before you rely on either behavior.
- A source exception that the caller handles must become an `Err` in the port, not a panic. A panic returns no `Result`, so the caller has no value to branch on.
- A `main` that returns `Err` exits with a nonzero status (Book, chapter 9.2).

## Option

- `Option<T>` is `Some(T)` or `None`. Rust has no `null` (Book, chapter 6.1).
- Match on it, or use `if let` on it.
- `unwrap_or(default)` supplies a default. The default must come from the source. Do not pick one because it looks reasonable.

## Drop order and early release

- Values drop at scope end in reverse order of declaration (Book, chapter 15.3).
- Fields of a struct drop in declaration order (Reference, destructors).
- A value can be dropped early with `std::mem::drop` (Book, chapter 15.3). Use it only where the source releases a resource at a point in the code.
- A `Drop` impl that writes or closes a resource runs during panic unwinding too (Book, chapter 9.1). `std::process::exit` skips it (std, `process::exit`).

## Shared state across threads

- `Mutex::lock` returns a `Result`. After a panic in another thread the mutex is poisoned, and `lock` returns an error (std, `sync::Mutex`, "Poisoning").
- `lock().unwrap()` panics on a poisoned mutex. Port the source's behavior: panic, or map the error, as the source does.
- A value that moves to another thread must implement `Send`, and `Rc<T>` is one of the types that does not (Book, chapter 16.4). Let the compiler check it. Do not add `unsafe` to get past it.

## Tests for ownership and errors

- One test per error path, asserting the variant, not only `is_err()`.
- One test for the order of effects when a `Drop` writes something, using a recording fake in place of the real resource.
- One test that a clone and a shared owner behave as the source does after a change through one name.
