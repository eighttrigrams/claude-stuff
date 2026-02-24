---
name: writing-tests
description: General guidance on writing tests
---

# Patterns

## Architecture-Testability duality

If something is hard to test, this points at architecture flaws, i.e. violation of high-cohesion/low-coupling.

## Private functions

Don't test private functions. Such functionality should be implicit in the tests of the next higher up public function. 
If you feel tempted to test private functions, you are either overeager, or something which is private *should* actually
be public.

## Red-Green-Refactor

Always do Red-Green-Refactor, i.e. verify that the test actually tests *the thing*.
That is, changing the thing expected to be under test **actually** makes the test fail.

## Before-after-comparison of side-effects

In test expectations, Roughly:
- Test the value before <-- don't forget this here  
- Do the side effect which is part of the test
- Test the value after
