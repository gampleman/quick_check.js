# quick_check.js

quick_check.js is an implementation of QuickCheck in JavaScript. (Actually the
implementation is written in CoffeeScript, but that doesn't matter much).

**Note:** I would now recommend new users to look into [fast-check](https://github.com/dubzzz/fast-check) which is a more modern alternative to this project.

It works by integrating with existing test libraries. For example Jasmine
expectations are written like this:

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

For more information [read the docs](https://quickcheckjs.readme.io/), [check out my talk](https://vimeo.com/98737599) or read the
[annotated source code](http://code.gampleman.eu/quick_check.js/) or the
[introductory blog post](http://eng.rightscale.com/2014/07/18/quick-check-js.html).

# [Installing](https://quickcheckjs.readme.io/docs/getting-started)

Karma + Jasmine combo should be supported easily. Simply `npm install quick_check --save-dev`,
then add `'node_modules/quick_check/dist/quick-check.js'` to your `files` config.

[See more integrations](https://quickcheckjs.readme.io/docs/getting-started)

# Generators

quick_check.js comes with batteries included. There are plenty of generators included
plus it is very easy to write your own. I recommend checking out the docs, but here is a quick rundown:


## [Basic generators](https://quickcheckjs.readme.io/docs/basic-generators)

- `qc.bool`
- `qc.byte`
- `qc.constructor(cons)`
- `qc.fromFunction(fn)`

## [Number generators](https://quickcheckjs.readme.io/docs/number-generators)

Almost all number generators have a large variant for generating larger numbers,
as the standard generators tend not to generate numbers bigger than 10,000. The
generators prefixed with `u` generate only positive numbers.

- `qc.ureal` and `qc.ureal.large`
- `qc.real` and `qc.real.large`
- `qc.uint` and `qc.uint.large`
- `qc.int` and `qc.int.large`
- `qc.int.between(min, max)`
- `qc.natural` and `qc.natural.large`
- `qc.range([gen])`
- `qc.range.inclusive([gen])`
- `qc.dice(diceDSL)`

## [String generators](https://quickcheckjs.readme.io/docs/string-generators)

- `qc.char`
- `qc.string`
- `qc.string.ascii`
- `qc.string.concat`
- `qc.string.matching`

## [Array generators](https://quickcheckjs.readme.io/docs/array-generators)

- `qc.arrayOf(generator[, options])`
- `qc.array`
- `qc.array.subsetOf(array[, options])`

## [Object generators](https://quickcheckjs.readme.io/docs/object-generators)

- `qc.object`
- `qc.objectLike(template)`
- `qc.objectOf(valGen[, keyGen])`

## [Function generators](https://quickcheckjs.readme.io/docs/function-generators)

- `qc.function`
- `qc.procedure`

## [Misc generators](https://quickcheckjs.readme.io/docs/miscalaneous-generators)

- `qc.date`
- `qc.any`
- `qc.any.simple`
- `qc.any.datatype`
- `qc.color`
- `qc.location`

## [Generator combinators](https://quickcheckjs.readme.io/docs/generator-combinators)
These combinator functions are meant to create new generators out of other generators.

- `qc.oneOf`
- `qc.oneOfByPriority`
- `qc.except`

# Maintained By

[Jakub Hampl](https://github.com/gampleman) - http://gampleman.eu

# License

The MIT License (MIT)

Copyright (c) 2014 RightScale

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
