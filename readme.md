quick_check.js
==============

quick_check.js is an implementation of QuickCheck in JavaScript. (Actually the
implementation is written in CoffeeScript, but that doesn't matter much).

Currently it exists as a Jasmine plugin. Expectations are written like this:

~~~javascript
// implementation
function odd(n) {
  return n % 2 === 1;
}
// tests
it('#odd returns true for odd numbers', function() {
  expect(function(i) {
    return odd(2 * i + 1);
  }).forAll(qc.int)
});
~~~

Notice the `forAll(qc.int)`. This indicates that our function (called property)
should return true for all integers passed to it. This code in fact contains a bug
which quick_check.js will helpfully find for you:

~~~
PhantomJS 1.9.7 (Mac OS X) #odd returns true for odd numbers FAILED
  Falsified after 3 attempts. Counter-example: -4
~~~

This means that quick_check.js generated 3 random integers and one of them failed
the test (in this case -4). (Why? Because modulus operator in JavaScript is botched).

QuickCheck will stop after 100 generated test cases and assume that your code works.

For more information [check out my talk](https://vimeo.com/98737599) or read the
[annotated source code](http://code.gampleman.eu/quick_check.js/) or the
[introductory blog post](http://eng.rightscale.com/2014/07/18/quick-check-js.html).

# Installing

Karma + Jasmine combo should be supported easily. Simply `npm install quick-check --save-dev`,
then add `'node_modules/quick_check/dist/quick-check.js'` to your `files` config.

QUnit should also work, but isn't being currently tested.

# Generators

quick_check.js comes with batteries included. There are plenty of generators included
plus it is very easy to write your own. I recommend checking out the source, but here is a quick rundown:


## Basic generators

### `qc.bool`
Generates a random boolean.

### `qc.byte`
Generates a random integer between 0 and 255.

### `qc.constructor`
Generates random objects by calling the constructor with random arguments.

### `qc.fromFunction`
Generates a random value by calling a function with random arguments.

## Number generators

### `qc.intUpto`
Almost all number generators have a large variant for generating larger numbers,
as the standard generators tend not to generate numbers bigger than 10,000. The
generators prefixed with `u` generate only positive numbers.

### `qc.range`
Range generators will generate an array of two numbers where the second is
guaranteed to be larger than the first. i.e.

~~~coffeescript
expect(([min, max]) -> min < max).forAll(qc.range())
expect(([min, max]) -> min <= max).forAll(qc.range.inclusive(qc.real))
expect(([min, max]) -> 0 <= min < max).forAll(qc.range(qc.ureal))
expect(([min, max]) -> 0 < min < max).forAll(qc.range(qc.natural))
~~~

### `qc.dice`
The dice generator takes a D&D style dice string and transforms it into a random
number generator. This can serve as a very quick method how to quickly approximate
distributions.

~~~coffeescript
qc.dice('d3') == -> Math.ceil(qc.random() * 3)
qc.dice('d2 + d4 + 3') == ->
  Math.ceil(qc.random() * 2) + Math.ceil(qc.random() * 4) + 3
qc.dice('2d6') == ->
  Math.ceil(qc.random() * 6) + Math.ceil(qc.random() * 6)
~~~

## String generators

### `qc.char`
`qc.char` will return a random string with a single chararcter.

### `qc.string`
`qc.string` will generate a string of random charachters.

### `qc.string.ascii`
`qc.string.ascii` will generate a string of random ascii charachters.

### `qc.string.concat`
`qc.string.concat` is a generator combinator (see below) that will generate all
the generators passed to it and then concatenate them into a single string.

### `qc.string.matching`
This will generate a string matching the regexp passed to it.

## Array generators

### `qc.arrayOf`
`qc.arrayOf(generator, options = {})` will return a random generator, which will generate
an array from that generator. You can specify a genertor or a constant value for the
length property in `options`, the generated array will then have that length.

### `qc.array`
`qc.array` will generate a random array of any type.

### `qc.array.subsetOf`
`qc.array.subsetOf(array, options)` will return a random generator that will generate
a subset of an array.

For example `qc.array.subsetOf([1,2,3,4])(size)` could yield `[3, 1]`.

## Object generators

### `qc.objectLike`
`qc.objectLike` accepts a template of an object with random generators as values,
and returns a generator of that form of object.

~~~javascript
qc.objectLike({
  hello: "world",
  name: qc.string.matching(/^m(r|s)\. [A-Z][a-z]{3,9}$/)
})(size) // generates:
{
  hello: "world",
  name: "mr. Dasde"
}
~~~

### `qc.objectOf`
`qc.objectOf` generates an object containing the passed type as its values. Optionally
a second argument can be a generator for the key (defaults to `qc.string`).

### `qc.object`
`qc.object` generates an object containing random types

## Function generators

### `qc.function`
Generates a pure function that will have the return value of the passed generator.

### `qc.procedure`
A procedure is a function composed of discrete operations that has side effects.
This function accepts an object or a class and it will randomly call its methods.

## Misc generators

### `qc.date`
qc.date will generate a random date

### `qc.any`
qc.any will generate a value of any type. For performance reasons there is a bias
towards simpler types with the following approx. distribution:

Probability | Type
----------|-----------
4% | `object`
8% | `array`
13% | `string`
14% | `function`
16% | `real`
20% | `integer`
25% | `boolean`

### `qc.any.simple`
qc.any.simple will only generate simple types, i.e. booleans, numbers, strings and null.

### `qc.any.datatype`
qc.any.datatype will only generate types that are data, not code, i.e. booleans, numbers, strings, null, arrays and objects.

### `qc.color`
Color is a utility for making web colors, i.e. will return a CSS compatible string (#fff).

### `qc.location`
Location calculates a random lat, long pair on the surface of the Earth.

## Generator combinators
These combinator functions are meant to create new generators out of other generators.

### `qc.pick`
Return a function that randomly chooses one of the arguments passed to `qc.pick`.

### `qc.oneOf`
`qc.oneOf` will choose between all the generators passed to it (accepts also an array of generators)
and generate a value from it. For example:

~~~coffeescript
stringOrNumber = qc.oneOf(qc.string, qc.real)
stringOrNumber(size) # "frqw"
stringOrNumber(size) # 5.54
~~~

### `qc.oneOfByPriority`
`qc.oneOfByPriority` will choose a generator based on a distribution. This is
used for optimizing cases for simpler generators. See `qc.any` for an example.

### `qc.except`
`qc.except` will run the generator passed to it as normal, but when it generates
one of the `values` passed to it, it will try the generator again to guarantee that
the generator will generate a value other then any of the values. So `qc.except(qc.uint, 0)(size)`
will generate a natural number, since `qc.uint` it will generate a random positive integer,
and if it generates 0, it will try again.

This is quite a naive implementation as it will simply try again if the generator
does generate one of the values. If the probability of generating one of these
values is high, this can really kill performace, so for those cases a custom
implementation might be better (e.g. the string generator does this).

Maintained By
-------------
[Jakub Hampl](https://github.com/gampleman) - http://gampleman.eu

# License

The MIT License (MIT)

Copyright (c) 2014 RightScale

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
