# [fit] quick_check.js

---

# Problems with unit testing

- Doesn't help discover bugs
- If you can predict edge cases for a test, so can you predict them for the implementation

---

# Proof

- Too difficult
- JS has no automated tools, manual proof unreliable (and slow)
- Can prove properties of functions, rarely can prove 'it works'

---

# Enter QuickCheck

QuickCheck is a testing tool that attempts to falsify a property by generating random data and executing the property.


~~~javascript
function odd(num) {
  return num % 2 == 1;
}

it('#odd returns true for odd numbers', function() {
  expect(function(i) {
    return odd(2 * i + 1);
  }).forAll(qc.int)
});
~~~


---

# Example

~~~javascript
function odd(num) {
  return num % 2 == 1;
}

it('#odd returns true for odd numbers', function() {
  expect(function(i) {
    return odd(2 * i + 1);
  }).forAll(qc.int)
});
~~~

~~~
PhantomJS 1.9.7 (Mac OS X) #odd returns true for odd numbers FAILED
	Falsified after 3 attempts. Counter-example: -4
~~~

Turns out JS modulus operator is broken.

---

# What if our input is wrong?

~~~javascript
it('#odd returns true for odd numbers', function() {
  expect(function(i) {
    if (!even(i))
      return odd(i);
  }).forAll(qc.int)
});
~~~

~~~
#odd returns true for odd numbers FAILED
	Falsified after 5 attempts (4 skipped). Counter-example: -3
~~~

We can skip input that doesn't match what we want for our test.

---

# How does it work?

~~~coffeescript
# Main function
qc = (property, generators...) ->
  for i in [0...100]
    examples = (generator(i) for generator in generators)
    return false unless prop(examples...)
  return true

# Utilities
qc.choose = (range...) -> range[Math.floor(Math.random() * range.length)]

# Generators
qc.int = (size) ->
  sign = qc.choose(1, -1)
  return sign * Math.floor(Math.random() * size * size)
~~~
---

# Testing higher order functions

What if we need to test our implementation of `filter(list, f)`?

~~~javascript
it('#filter will always return a smaller list', function() {
  expect(function(list, f) {
    return filter(list, f).length < list.length;
  }).forAll(qc.arrayOf(qc.int), qc.function(qc.int, qc.bool));
});
~~~
~~~
#filter will always return a smaller list FAILED
  Falsified after 1 attempts. Counter-example: [0],
  function(a) {
    return true;
  }
~~~
---

# How does this work?

Pure functions map some arguments to a return value. This is literally all they do from a black box perspective.

However, they map the same arguments to the same values.

Therefore we can express any function that will be called a finite amount of times as a table.

And we can generate a table randomly.

---

# What's next

Available soon in a PR near you.

1. Shrinking
2. `qc.string.withPattern`
3. Nice docs
4. Open source it!

---

# Function generation example

~~~
Input        Output

(int, int)  -> int
------------|--------
(7, 3)      |

~~~

---

# Function generation example

~~~
Input        Output

(int, int)  -> int
------------|--------
(7, 3)      | 2

~~~

---

# Function generation example

~~~
Input        Output

(int, int)  -> int
------------|--------
(7, 3)      | 2
(7, 5)

~~~

---

# Function generation example

~~~
Input        Output

(int, int)  -> int
------------|--------
(7, 3)      | 2
(7, 5)      | 4

~~~

---

# Function 'Purification'

We can see

~~~javascript
spyOn(CustomReportsService, 'update').and.return({id: 45});

expect(CustomReportController.foo(bar)).toEqual(fooBuz);
expect(CustomReportsService.update).toHaveBeenCalledWith(fizBuz);
~~~

as

~~~
expect(CustomReportController.foo(bar, {id: 45}))
  .toEqual([fooBuz, fizBuz]);
~~~
