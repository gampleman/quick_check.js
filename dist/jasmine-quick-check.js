(function(){ 
 'use strict';
/**
 * Copyright (c) 2014, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * https://raw.github.com/facebook/regenerator/master/LICENSE file. An
 * additional grant of patent rights can be found in the PATENTS file in
 * the same directory.
 */

!(function(global) {
  "use strict";

  var hasOwn = Object.prototype.hasOwnProperty;
  var undefined; // More compressible than void 0.
  var $Symbol = typeof Symbol === "function" ? Symbol : {};
  var iteratorSymbol = $Symbol.iterator || "@@iterator";
  var toStringTagSymbol = $Symbol.toStringTag || "@@toStringTag";

  var inModule = typeof module === "object";
  var runtime = global.regeneratorRuntime;
  if (runtime) {
    if (inModule) {
      // If regeneratorRuntime is defined globally and we're in a module,
      // make the exports object identical to regeneratorRuntime.
      module.exports = runtime;
    }
    // Don't bother evaluating the rest of this file if the runtime was
    // already defined globally.
    return;
  }

  // Define the runtime globally (as expected by generated code) as either
  // module.exports (if we're in a module) or a new, empty object.
  runtime = global.regeneratorRuntime = inModule ? module.exports : {};

  function wrap(innerFn, outerFn, self, tryLocsList) {
    // If outerFn provided, then outerFn.prototype instanceof Generator.
    var generator = Object.create((outerFn || Generator).prototype);
    var context = new Context(tryLocsList || []);

    // The ._invoke method unifies the implementations of the .next,
    // .throw, and .return methods.
    generator._invoke = makeInvokeMethod(innerFn, self, context);

    return generator;
  }
  runtime.wrap = wrap;

  // Try/catch helper to minimize deoptimizations. Returns a completion
  // record like context.tryEntries[i].completion. This interface could
  // have been (and was previously) designed to take a closure to be
  // invoked without arguments, but in all the cases we care about we
  // already have an existing method we want to call, so there's no need
  // to create a new function object. We can even get away with assuming
  // the method takes exactly one argument, since that happens to be true
  // in every case, so we don't have to touch the arguments object. The
  // only additional allocation required is the completion record, which
  // has a stable shape and so hopefully should be cheap to allocate.
  function tryCatch(fn, obj, arg) {
    try {
      return { type: "normal", arg: fn.call(obj, arg) };
    } catch (err) {
      return { type: "throw", arg: err };
    }
  }

  var GenStateSuspendedStart = "suspendedStart";
  var GenStateSuspendedYield = "suspendedYield";
  var GenStateExecuting = "executing";
  var GenStateCompleted = "completed";

  // Returning this object from the innerFn has the same effect as
  // breaking out of the dispatch switch statement.
  var ContinueSentinel = {};

  // Dummy constructor functions that we use as the .constructor and
  // .constructor.prototype properties for functions that return Generator
  // objects. For full spec compliance, you may wish to configure your
  // minifier not to mangle the names of these two functions.
  function Generator() {}
  function GeneratorFunction() {}
  function GeneratorFunctionPrototype() {}

  var Gp = GeneratorFunctionPrototype.prototype = Generator.prototype;
  GeneratorFunction.prototype = Gp.constructor = GeneratorFunctionPrototype;
  GeneratorFunctionPrototype.constructor = GeneratorFunction;
  GeneratorFunctionPrototype[toStringTagSymbol] = GeneratorFunction.displayName = "GeneratorFunction";

  // Helper for defining the .next, .throw, and .return methods of the
  // Iterator interface in terms of a single ._invoke method.
  function defineIteratorMethods(prototype) {
    ["next", "throw", "return"].forEach(function(method) {
      prototype[method] = function(arg) {
        return this._invoke(method, arg);
      };
    });
  }

  runtime.isGeneratorFunction = function(genFun) {
    var ctor = typeof genFun === "function" && genFun.constructor;
    return ctor
      ? ctor === GeneratorFunction ||
        // For the native GeneratorFunction constructor, the best we can
        // do is to check its .name property.
        (ctor.displayName || ctor.name) === "GeneratorFunction"
      : false;
  };

  runtime.mark = function(genFun) {
    if (Object.setPrototypeOf) {
      Object.setPrototypeOf(genFun, GeneratorFunctionPrototype);
    } else {
      genFun.__proto__ = GeneratorFunctionPrototype;
      if (!(toStringTagSymbol in genFun)) {
        genFun[toStringTagSymbol] = "GeneratorFunction";
      }
    }
    genFun.prototype = Object.create(Gp);
    return genFun;
  };

  // Within the body of any async function, `await x` is transformed to
  // `yield regeneratorRuntime.awrap(x)`, so that the runtime can test
  // `value instanceof AwaitArgument` to determine if the yielded value is
  // meant to be awaited. Some may consider the name of this method too
  // cutesy, but they are curmudgeons.
  runtime.awrap = function(arg) {
    return new AwaitArgument(arg);
  };

  function AwaitArgument(arg) {
    this.arg = arg;
  }

  function AsyncIterator(generator) {
    function invoke(method, arg, resolve, reject) {
      var record = tryCatch(generator[method], generator, arg);
      if (record.type === "throw") {
        reject(record.arg);
      } else {
        var result = record.arg;
        var value = result.value;
        if (value instanceof AwaitArgument) {
          return Promise.resolve(value.arg).then(function(value) {
            invoke("next", value, resolve, reject);
          }, function(err) {
            invoke("throw", err, resolve, reject);
          });
        }

        return Promise.resolve(value).then(function(unwrapped) {
          // When a yielded Promise is resolved, its final value becomes
          // the .value of the Promise<{value,done}> result for the
          // current iteration. If the Promise is rejected, however, the
          // result for this iteration will be rejected with the same
          // reason. Note that rejections of yielded Promises are not
          // thrown back into the generator function, as is the case
          // when an awaited Promise is rejected. This difference in
          // behavior between yield and await is important, because it
          // allows the consumer to decide what to do with the yielded
          // rejection (swallow it and continue, manually .throw it back
          // into the generator, abandon iteration, whatever). With
          // await, by contrast, there is no opportunity to examine the
          // rejection reason outside the generator function, so the
          // only option is to throw it from the await expression, and
          // let the generator function handle the exception.
          result.value = unwrapped;
          resolve(result);
        }, reject);
      }
    }

    if (typeof process === "object" && process.domain) {
      invoke = process.domain.bind(invoke);
    }

    var previousPromise;

    function enqueue(method, arg) {
      function callInvokeWithMethodAndArg() {
        return new Promise(function(resolve, reject) {
          invoke(method, arg, resolve, reject);
        });
      }

      return previousPromise =
        // If enqueue has been called before, then we want to wait until
        // all previous Promises have been resolved before calling invoke,
        // so that results are always delivered in the correct order. If
        // enqueue has not been called before, then it is important to
        // call invoke immediately, without waiting on a callback to fire,
        // so that the async generator function has the opportunity to do
        // any necessary setup in a predictable way. This predictability
        // is why the Promise constructor synchronously invokes its
        // executor callback, and why async functions synchronously
        // execute code before the first await. Since we implement simple
        // async functions in terms of async generators, it is especially
        // important to get this right, even though it requires care.
        previousPromise ? previousPromise.then(
          callInvokeWithMethodAndArg,
          // Avoid propagating failures to Promises returned by later
          // invocations of the iterator.
          callInvokeWithMethodAndArg
        ) : callInvokeWithMethodAndArg();
    }

    // Define the unified helper method that is used to implement .next,
    // .throw, and .return (see defineIteratorMethods).
    this._invoke = enqueue;
  }

  defineIteratorMethods(AsyncIterator.prototype);

  // Note that simple async functions are implemented on top of
  // AsyncIterator objects; they just return a Promise for the value of
  // the final result produced by the iterator.
  runtime.async = function(innerFn, outerFn, self, tryLocsList) {
    var iter = new AsyncIterator(
      wrap(innerFn, outerFn, self, tryLocsList)
    );

    return runtime.isGeneratorFunction(outerFn)
      ? iter // If outerFn is a generator, return the full iterator.
      : iter.next().then(function(result) {
          return result.done ? result.value : iter.next();
        });
  };

  function makeInvokeMethod(innerFn, self, context) {
    var state = GenStateSuspendedStart;

    return function invoke(method, arg) {
      if (state === GenStateExecuting) {
        throw new Error("Generator is already running");
      }

      if (state === GenStateCompleted) {
        if (method === "throw") {
          throw arg;
        }

        // Be forgiving, per 25.3.3.3.3 of the spec:
        // https://people.mozilla.org/~jorendorff/es6-draft.html#sec-generatorresume
        return doneResult();
      }

      while (true) {
        var delegate = context.delegate;
        if (delegate) {
          if (method === "return" ||
              (method === "throw" && delegate.iterator[method] === undefined)) {
            // A return or throw (when the delegate iterator has no throw
            // method) always terminates the yield* loop.
            context.delegate = null;

            // If the delegate iterator has a return method, give it a
            // chance to clean up.
            var returnMethod = delegate.iterator["return"];
            if (returnMethod) {
              var record = tryCatch(returnMethod, delegate.iterator, arg);
              if (record.type === "throw") {
                // If the return method threw an exception, let that
                // exception prevail over the original return or throw.
                method = "throw";
                arg = record.arg;
                continue;
              }
            }

            if (method === "return") {
              // Continue with the outer return, now that the delegate
              // iterator has been terminated.
              continue;
            }
          }

          var record = tryCatch(
            delegate.iterator[method],
            delegate.iterator,
            arg
          );

          if (record.type === "throw") {
            context.delegate = null;

            // Like returning generator.throw(uncaught), but without the
            // overhead of an extra function call.
            method = "throw";
            arg = record.arg;
            continue;
          }

          // Delegate generator ran and handled its own exceptions so
          // regardless of what the method was, we continue as if it is
          // "next" with an undefined arg.
          method = "next";
          arg = undefined;

          var info = record.arg;
          if (info.done) {
            context[delegate.resultName] = info.value;
            context.next = delegate.nextLoc;
          } else {
            state = GenStateSuspendedYield;
            return info;
          }

          context.delegate = null;
        }

        if (method === "next") {
          if (state === GenStateSuspendedYield) {
            context.sent = arg;
          } else {
            context.sent = undefined;
          }

        } else if (method === "throw") {
          if (state === GenStateSuspendedStart) {
            state = GenStateCompleted;
            throw arg;
          }

          if (context.dispatchException(arg)) {
            // If the dispatched exception was caught by a catch block,
            // then let that catch block handle the exception normally.
            method = "next";
            arg = undefined;
          }

        } else if (method === "return") {
          context.abrupt("return", arg);
        }

        state = GenStateExecuting;

        var record = tryCatch(innerFn, self, context);
        if (record.type === "normal") {
          // If an exception is thrown from innerFn, we leave state ===
          // GenStateExecuting and loop back for another invocation.
          state = context.done
            ? GenStateCompleted
            : GenStateSuspendedYield;

          var info = {
            value: record.arg,
            done: context.done
          };

          if (record.arg === ContinueSentinel) {
            if (context.delegate && method === "next") {
              // Deliberately forget the last sent value so that we don't
              // accidentally pass it on to the delegate.
              arg = undefined;
            }
          } else {
            return info;
          }

        } else if (record.type === "throw") {
          state = GenStateCompleted;
          // Dispatch the exception by looping back around to the
          // context.dispatchException(arg) call above.
          method = "throw";
          arg = record.arg;
        }
      }
    };
  }

  // Define Generator.prototype.{next,throw,return} in terms of the
  // unified ._invoke helper method.
  defineIteratorMethods(Gp);

  Gp[iteratorSymbol] = function() {
    return this;
  };

  Gp[toStringTagSymbol] = "Generator";

  Gp.toString = function() {
    return "[object Generator]";
  };

  function pushTryEntry(locs) {
    var entry = { tryLoc: locs[0] };

    if (1 in locs) {
      entry.catchLoc = locs[1];
    }

    if (2 in locs) {
      entry.finallyLoc = locs[2];
      entry.afterLoc = locs[3];
    }

    this.tryEntries.push(entry);
  }

  function resetTryEntry(entry) {
    var record = entry.completion || {};
    record.type = "normal";
    delete record.arg;
    entry.completion = record;
  }

  function Context(tryLocsList) {
    // The root entry object (effectively a try statement without a catch
    // or a finally block) gives us a place to store values thrown from
    // locations where there is no enclosing try statement.
    this.tryEntries = [{ tryLoc: "root" }];
    tryLocsList.forEach(pushTryEntry, this);
    this.reset(true);
  }

  runtime.keys = function(object) {
    var keys = [];
    for (var key in object) {
      keys.push(key);
    }
    keys.reverse();

    // Rather than returning an object with a next method, we keep
    // things simple and return the next function itself.
    return function next() {
      while (keys.length) {
        var key = keys.pop();
        if (key in object) {
          next.value = key;
          next.done = false;
          return next;
        }
      }

      // To avoid creating an additional object, we just hang the .value
      // and .done properties off the next function object itself. This
      // also ensures that the minifier will not anonymize the function.
      next.done = true;
      return next;
    };
  };

  function values(iterable) {
    if (iterable) {
      var iteratorMethod = iterable[iteratorSymbol];
      if (iteratorMethod) {
        return iteratorMethod.call(iterable);
      }

      if (typeof iterable.next === "function") {
        return iterable;
      }

      if (!isNaN(iterable.length)) {
        var i = -1, next = function next() {
          while (++i < iterable.length) {
            if (hasOwn.call(iterable, i)) {
              next.value = iterable[i];
              next.done = false;
              return next;
            }
          }

          next.value = undefined;
          next.done = true;

          return next;
        };

        return next.next = next;
      }
    }

    // Return an iterator with no values.
    return { next: doneResult };
  }
  runtime.values = values;

  function doneResult() {
    return { value: undefined, done: true };
  }

  Context.prototype = {
    constructor: Context,

    reset: function(skipTempReset) {
      this.prev = 0;
      this.next = 0;
      this.sent = undefined;
      this.done = false;
      this.delegate = null;

      this.tryEntries.forEach(resetTryEntry);

      if (!skipTempReset) {
        for (var name in this) {
          // Not sure about the optimal order of these conditions:
          if (name.charAt(0) === "t" &&
              hasOwn.call(this, name) &&
              !isNaN(+name.slice(1))) {
            this[name] = undefined;
          }
        }
      }
    },

    stop: function() {
      this.done = true;

      var rootEntry = this.tryEntries[0];
      var rootRecord = rootEntry.completion;
      if (rootRecord.type === "throw") {
        throw rootRecord.arg;
      }

      return this.rval;
    },

    dispatchException: function(exception) {
      if (this.done) {
        throw exception;
      }

      var context = this;
      function handle(loc, caught) {
        record.type = "throw";
        record.arg = exception;
        context.next = loc;
        return !!caught;
      }

      for (var i = this.tryEntries.length - 1; i >= 0; --i) {
        var entry = this.tryEntries[i];
        var record = entry.completion;

        if (entry.tryLoc === "root") {
          // Exception thrown outside of any try block that could handle
          // it, so set the completion value of the entire function to
          // throw the exception.
          return handle("end");
        }

        if (entry.tryLoc <= this.prev) {
          var hasCatch = hasOwn.call(entry, "catchLoc");
          var hasFinally = hasOwn.call(entry, "finallyLoc");

          if (hasCatch && hasFinally) {
            if (this.prev < entry.catchLoc) {
              return handle(entry.catchLoc, true);
            } else if (this.prev < entry.finallyLoc) {
              return handle(entry.finallyLoc);
            }

          } else if (hasCatch) {
            if (this.prev < entry.catchLoc) {
              return handle(entry.catchLoc, true);
            }

          } else if (hasFinally) {
            if (this.prev < entry.finallyLoc) {
              return handle(entry.finallyLoc);
            }

          } else {
            throw new Error("try statement without catch or finally");
          }
        }
      }
    },

    abrupt: function(type, arg) {
      for (var i = this.tryEntries.length - 1; i >= 0; --i) {
        var entry = this.tryEntries[i];
        if (entry.tryLoc <= this.prev &&
            hasOwn.call(entry, "finallyLoc") &&
            this.prev < entry.finallyLoc) {
          var finallyEntry = entry;
          break;
        }
      }

      if (finallyEntry &&
          (type === "break" ||
           type === "continue") &&
          finallyEntry.tryLoc <= arg &&
          arg <= finallyEntry.finallyLoc) {
        // Ignore the finally entry if control is not jumping to a
        // location outside the try/catch block.
        finallyEntry = null;
      }

      var record = finallyEntry ? finallyEntry.completion : {};
      record.type = type;
      record.arg = arg;

      if (finallyEntry) {
        this.next = finallyEntry.finallyLoc;
      } else {
        this.complete(record);
      }

      return ContinueSentinel;
    },

    complete: function(record, afterLoc) {
      if (record.type === "throw") {
        throw record.arg;
      }

      if (record.type === "break" ||
          record.type === "continue") {
        this.next = record.arg;
      } else if (record.type === "return") {
        this.rval = record.arg;
        this.next = "end";
      } else if (record.type === "normal" && afterLoc) {
        this.next = afterLoc;
      }
    },

    finish: function(finallyLoc) {
      for (var i = this.tryEntries.length - 1; i >= 0; --i) {
        var entry = this.tryEntries[i];
        if (entry.finallyLoc === finallyLoc) {
          this.complete(entry.completion, entry.afterLoc);
          resetTryEntry(entry);
          return ContinueSentinel;
        }
      }
    },

    "catch": function(tryLoc) {
      for (var i = this.tryEntries.length - 1; i >= 0; --i) {
        var entry = this.tryEntries[i];
        if (entry.tryLoc === tryLoc) {
          var record = entry.completion;
          if (record.type === "throw") {
            var thrown = record.arg;
            resetTryEntry(entry);
          }
          return thrown;
        }
      }

      // The context.catch method must only be called with a location
      // argument that corresponds to a known catch block.
      throw new Error("illegal catch attempt");
    },

    delegateYield: function(iterable, resultName, nextLoc) {
      this.delegate = {
        iterator: values(iterable),
        resultName: resultName,
        nextLoc: nextLoc
      };

      return ContinueSentinel;
    }
  };
})(
  // Among the various tricks for obtaining a reference to the global
  // object, this seems to be the most reliable technique that does not
  // use indirect eval (which violates Content Security Policy).
  typeof global === "object" ? global :
  typeof window === "object" ? window :
  typeof self === "object" ? self : this
);
var makeHistogram, qc, stringify,
  slice = [].slice;

qc = function() {
  var examples, generator, generators, hist, histString, i, j, minimal, num, prop, ref, result, skipped, skippedString;
  prop = arguments[0], generators = 2 <= arguments.length ? slice.call(arguments, 1) : [];
  num = 100;
  skipped = 0;
  hist = {};
  for (i = j = 0, ref = num; 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
    examples = (function() {
      var k, len, results;
      results = [];
      for (k = 0, len = generators.length; k < len; k++) {
        generator = generators[k];
        results.push(generator(i));
      }
      return results;
    })();
    result = prop.apply(null, examples);
    if (result === false) {
      if (qc._performShrinks) {
        minimal = findMinimalExample(prop, examples, generators);
        skippedString = skipped > 0 ? " (" + skipped + " skipped)" : "";
        return {
          pass: false,
          examples: examples,
          minimalExamples: minimal.examples,
          message: "Falsified after " + (i + 1) + " attempt" + (i === 0 ? '' : 's') + skippedString + ". Counter-example (after " + minimal.shrinkCount + " shrinks): " + (stringify(minimal.examples, generators)) + "\n\nNon-shrunk counter-example: " + (stringify(examples, generators))
        };
      } else {
        skippedString = skipped > 0 ? " (" + skipped + " skipped)" : "";
        return {
          pass: false,
          examples: examples,
          message: "Falsified after " + (i + 1) + " attempt" + (i === 0 ? '' : 's') + skippedString + ". Counter-example: " + (stringify(examples, generators))
        };
      }
    }
    if (result === void 0) {
      num++;
      skipped++;
      if (skipped > 200) {
        return {
          pass: false,
          examples: examples,
          message: "Gave up after " + i + " (" + skipped + " skipped) attempts."
        };
      }
    }
    if (typeof result === 'string') {
      hist[result] = hist[result] != null ? hist[result] + 1 : 1;
    }
  }
  skippedString = skipped > 0 ? " (" + skipped + " skipped)" : "";
  histString = makeHistogram(hist, num);
  return {
    pass: true,
    examples: examples,
    message: "Passed " + num + " tests" + skippedString + "." + histString
  };
};

stringify = function(examples) {
  var example;
  return ((function() {
    var j, len, results;
    if (typeof example === 'function') {
      return example.toString();
    } else {
      results = [];
      for (j = 0, len = examples.length; j < len; j++) {
        example = examples[j];
        results.push(JSON.stringify(example));
      }
      return results;
    }
  })()).join(', ');
};

makeHistogram = function(hist, total) {
  var count, label;
  hist = (function() {
    var results;
    results = [];
    for (label in hist) {
      count = hist[label];
      results.push({
        label: label,
        count: count
      });
    }
    return results;
  })();
  hist.sort(function(arg, arg1) {
    var a, b;
    a = arg.count;
    b = arg1.count;
    return a - b;
  });
  return "\n" + hist.map(function(arg) {
    var count, label;
    label = arg.label, count = arg.count;
    return (((count / total) * 100).toFixed(2)) + "% " + label;
  }).join("\n");
};

qc.forAll = function() {
  var examples, generator, generators, i, j, k, prop, results;
  generators = 2 <= arguments.length ? slice.call(arguments, 0, j = arguments.length - 1) : (j = 0, []), prop = arguments[j++];
  results = [];
  for (i = k = 0; k < 100; i = ++k) {
    examples = (function() {
      var l, len, results1;
      results1 = [];
      for (l = 0, len = generators.length; l < len; l++) {
        generator = generators[l];
        results1.push(generator(i));
      }
      return results1;
    })();
    results.push(prop.apply(null, examples));
  }
  return results;
};

qc.random = Math.random;

if (typeof this !== "undefined" && this !== null) {
  this.qc = qc;
} else if (typeof window !== "undefined" && window !== null) {
  window.qc = qc;
}

if (typeof module !== "undefined" && module !== null) {
  module.exports = qc;
}

var map;

qc.of = function(value) {
  return function(size) {
    return value;
  };
};

map = function(fun, gen) {
  return function(size) {
    return fun(gen(size));
  };
};

qc.map = function(fun, gen) {
  if (arguments.length === 1) {
    return function(gen) {
      return map(fun, gen);
    };
  } else {
    return map(fun, gen);
  }
};

qc.join = function(gen) {
  return function(size) {
    return gen(size)(size);
  };
};

var emptyIterator, findMinimalExample, floatShrinker, intShrinker, iterateGenArray, registry;

qc._performShrinks = true;

registry = [];

emptyIterator = {
  next: function() {
    return {
      value: void 0,
      done: true
    };
  }
};

qc.addShrinker = function(valid, shrinker) {
  if (typeof valid === 'string') {
    valid = function(val) {
      return val.constructor.name === valid;
    };
  }
  shrinker = {
    valid: valid,
    shrinker: shrinker
  };
  registry.push(shrinker);
  return shrinker;
};

qc.shrink = function(value, hint, shrinkers) {
  var j, len, ref, shrinker, valid;
  if (shrinkers == null) {
    shrinkers = registry;
  }
  if (hint != null ? typeof hint.valid === "function" ? hint.valid(value) : void 0 : void 0) {
    return hint.shrinker(value);
  } else {
    for (j = 0, len = shrinkers.length; j < len; j++) {
      ref = shrinkers[j], valid = ref.valid, shrinker = ref.shrinker;
      if (valid(value)) {
        return shrinker(value);
      }
    }
  }
  return emptyIterator;
};

findMinimalExample = function(prop, examples, generators, limit) {
  var iterations, last, shrunk;
  if (limit == null) {
    limit = 1000;
  }
  iterations = 0;
  last = examples;
  while (iterations < limit) {
    shrunk = false;
    iterateGenArray(last.map(function(example) {
      return qc.shrink(example);
    }), function(vals) {
      if (!prop.apply(null, vals)) {
        last = vals;
        shrunk = true;
        return false;
      }
      return true;
    });
    if (!shrunk) {
      break;
    }
    iterations += 1;
  }
  return {
    shrinkCount: iterations,
    examples: last
  };
};

iterateGenArray = function(arr, fn) {
  var atLeastOneValueAssigned, dones, gen, i, j, len, next, res, stop;
  dones = (function() {
    var j, len, results;
    results = [];
    for (j = 0, len = arr.length; j < len; j++) {
      gen = arr[j];
      results.push(false);
    }
    return results;
  })();
  res = [];
  atLeastOneValueAssigned = dones.slice();
  while (dones.some(function(a) {
      return !a;
    })) {
    for (i = j = 0, len = arr.length; j < len; i = ++j) {
      gen = arr[i];
      next = gen.next();
      dones[i] = next.done;
      if (!next.done) {
        res[i] = next.value;
        atLeastOneValueAssigned[i] = true;
      }
    }
    if (atLeastOneValueAssigned.every(function(a) {
      return a;
    })) {
      stop = fn(res);
    }
    if (stop === false) {
      return;
    }
  }
};

intShrinker = qc.addShrinker(function(val) {
  return typeof val === 'number' && Math.round(val) === val;
}, regeneratorRuntime.mark(function callee$0$0(value) {
  var diff, next, positives, results, results1;

  return regeneratorRuntime.wrap(function callee$0$0$(context$1$0) {
    while (1) switch (context$1$0.prev = context$1$0.next) {
    case 0:
      if (!(value < 0)) {
        context$1$0.next = 16;
        break;
      }

      context$1$0.next = 3;
      return -value;
    case 3:
      positives = qc.shrink(-value, intShrinker);
      results = [];
    case 5:
      if ((next = positives.next()).done) {
        context$1$0.next = 13;
        break;
      }

      context$1$0.t0 = results;
      context$1$0.next = 9;
      return -next.value;
    case 9:
      context$1$0.t1 = context$1$0.sent;
      context$1$0.t0.push.call(context$1$0.t0, context$1$0.t1);
      context$1$0.next = 5;
      break;
    case 13:
      return context$1$0.abrupt("return", results);
    case 16:
      diff = value;
      results1 = [];
    case 18:
      if (!(diff > 0)) {
        context$1$0.next = 24;
        break;
      }

      context$1$0.next = 21;
      return value - diff;
    case 21:
      results1.push(diff = Math.floor(diff / 2));
      context$1$0.next = 18;
      break;
    case 24:
      return context$1$0.abrupt("return", results1);
    case 25:
    case "end":
      return context$1$0.stop();
    }
  }, callee$0$0, this);
}));

floatShrinker = qc.addShrinker(function(val) {
  return typeof val === 'number' && Math.round(val) !== val;
}, regeneratorRuntime.mark(function callee$0$1(value) {
  var diff, next, positives, results, results1;

  return regeneratorRuntime.wrap(function callee$0$1$(context$1$0) {
    while (1) switch (context$1$0.prev = context$1$0.next) {
    case 0:
      if (!(value < 0)) {
        context$1$0.next = 17;
        break;
      }

      context$1$0.next = 3;
      return -value;
    case 3:
      positives = qc.shrink(-value, floatShrinker);
      next = void 0;
      results = [];
    case 6:
      if ((next = positives.next()).done) {
        context$1$0.next = 14;
        break;
      }

      context$1$0.t0 = results;
      context$1$0.next = 10;
      return -next.value;
    case 10:
      context$1$0.t1 = context$1$0.sent;
      context$1$0.t0.push.call(context$1$0.t0, context$1$0.t1);
      context$1$0.next = 6;
      break;
    case 14:
      return context$1$0.abrupt("return", results);
    case 17:
      diff = value;
      results1 = [];
    case 19:
      if (!(value - diff < value)) {
        context$1$0.next = 25;
        break;
      }

      context$1$0.next = 22;
      return value - diff;
    case 22:
      results1.push(diff = diff / 2);
      context$1$0.next = 19;
      break;
    case 25:
      return context$1$0.abrupt("return", results1);
    case 26:
    case "end":
      return context$1$0.stop();
    }
  }, callee$0$1, this);
}));

qc.addShrinker(function(val) {
  return Object.prototype.toString.call(val) === '[object Array]';
}, regeneratorRuntime.mark(function callee$0$2(value) {
  var elem, i, j, len, next, offset, results, smaller, toRemove;

  return regeneratorRuntime.wrap(function callee$0$2$(context$1$0) {
    while (1) switch (context$1$0.prev = context$1$0.next) {
    case 0:
      if (!(value.length === 0)) {
        context$1$0.next = 2;
        break;
      }

      return context$1$0.abrupt("return");
    case 2:
      context$1$0.next = 4;
      return [];
    case 4:
      toRemove = Math.floor(value.length / 2);
    case 5:
      if (!(toRemove > 0)) {
        context$1$0.next = 16;
        break;
      }

      offset = 0;
    case 7:
      if (!(offset + toRemove <= value.length)) {
        context$1$0.next = 13;
        break;
      }

      context$1$0.next = 10;
      return value.slice(0, offset).concat(value.slice(offset + toRemove));
    case 10:
      offset += 1;
      context$1$0.next = 7;
      break;
    case 13:
      toRemove = Math.floor(toRemove / 2);
      context$1$0.next = 5;
      break;
    case 16:
      results = [];
      i = j = 0, len = value.length;
    case 18:
      if (!(j < len)) {
        context$1$0.next = 28;
        break;
      }

      elem = value[i];
      smaller = qc.shrink(elem);
      context$1$0.t0 = results;

      return context$1$0.delegateYield((regeneratorRuntime.mark(function callee$1$0() {
        var results1;

        return regeneratorRuntime.wrap(function callee$1$0$(context$2$0) {
          while (1) switch (context$2$0.prev = context$2$0.next) {
          case 0:
            results1 = [];
          case 1:
            if ((next = smaller.next()).done) {
              context$2$0.next = 9;
              break;
            }

            context$2$0.t0 = results1;
            context$2$0.next = 5;
            return value.slice(0, i).concat([next.value], value.slice(i + 1));
          case 5:
            context$2$0.t1 = context$2$0.sent;
            context$2$0.t0.push.call(context$2$0.t0, context$2$0.t1);
            context$2$0.next = 1;
            break;
          case 9:
            return context$2$0.abrupt("return", results1);
          case 10:
          case "end":
            return context$2$0.stop();
          }
        }, callee$1$0, this);
      }))(), "t1", 23);
    case 23:
      context$1$0.t2 = context$1$0.t1;
      context$1$0.t0.push.call(context$1$0.t0, context$1$0.t2);
    case 25:
      i = ++j;
      context$1$0.next = 18;
      break;
    case 28:
      return context$1$0.abrupt("return", results);
    case 29:
    case "end":
      return context$1$0.stop();
    }
  }, callee$0$2, this);
}));

qc.addShrinker(function(val) {
  return typeof val === 'string';
}, regeneratorRuntime.mark(function callee$0$3(value) {
  var offset, results, toRemove;

  return regeneratorRuntime.wrap(function callee$0$3$(context$1$0) {
    while (1) switch (context$1$0.prev = context$1$0.next) {
    case 0:
      if (!(value.length === 0)) {
        context$1$0.next = 2;
        break;
      }

      return context$1$0.abrupt("return");
    case 2:
      context$1$0.next = 4;
      return '';
    case 4:
      toRemove = Math.floor(value.length / 2);
      results = [];
    case 6:
      if (!(toRemove > 0)) {
        context$1$0.next = 17;
        break;
      }

      offset = 0;
    case 8:
      if (!(offset + toRemove <= value.length)) {
        context$1$0.next = 14;
        break;
      }

      context$1$0.next = 11;
      return value.slice(0, offset).concat(value.slice(offset + toRemove));
    case 11:
      offset += 1;
      context$1$0.next = 8;
      break;
    case 14:
      results.push(toRemove = Math.floor(toRemove / 2));
      context$1$0.next = 6;
      break;
    case 17:
      return context$1$0.abrupt("return", results);
    case 18:
    case "end":
      return context$1$0.stop();
    }
  }, callee$0$3, this);
}));

var normalizeOptions, sparsify;

normalizeOptions = function(options) {
  var ref;
  if (options == null) {
    options = {};
  }
  return {
    length: options.length != null ? typeof options.length === 'function' ? options.length : function() {
      return options.length;
    } : qc.intUpto,
    sparse: (ref = options.sparse) != null ? ref : false
  };
};

sparsify = function(arr, arg) {
  var el, i, j, len, sparse;
  sparse = arg.sparse;
  if (sparse) {
    arr = arr.slice();
    for (i = j = 0, len = arr.length; j < len; i = ++j) {
      el = arr[i];
      if (qc.random() > 0.6) {
        delete arr[i];
      }
    }
    return arr;
  } else {
    return arr;
  }
};

qc.arrayOf = function(generator, options) {
  if (options == null) {
    options = {};
  }
  options = normalizeOptions(options);
  return function(size) {
    var i;
    return sparsify((function() {
      var j, ref, results;
      results = [];
      for (i = j = 0, ref = options.length(size); 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
        results.push(generator(i));
      }
      return results;
    })(), options);
  };
};

qc.array = function(size) {
  return qc.arrayOf(qc.any)(size > 1 ? size - 1 : 0);
};

qc.array.subsetOf = function(array, options) {
  if (options == null) {
    options = {};
  }
  if (options.length == null) {
    options.length = qc.intUpto(array.length + 1);
  }
  options = normalizeOptions(options);
  return function(size) {
    var copy, i;
    copy = array.slice();
    return sparsify((function() {
      var j, ref, results;
      results = [];
      for (i = j = 0, ref = options.length(size); 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
        results.push(copy.splice(qc.intUpto(copy.length), 1)[0]);
      }
      return results;
    })(), options);
  };
};

var slice = [].slice;

qc.bool = function(size) {
  return qc.choose(true, false);
};

qc.byte = function(size) {
  return Math.floor(qc.random() * 256);
};

qc.constructor = function() {
  var arggens, cons;
  cons = arguments[0], arggens = 2 <= arguments.length ? slice.call(arguments, 1) : [];
  return function(size) {
    var arggen, args;
    args = (function() {
      var i, len, results;
      results = [];
      for (i = 0, len = arggens.length; i < len; i++) {
        arggen = arggens[i];
        results.push(arggen(size - 1));
      }
      return results;
    })();
    return (function(func, args, ctor) {
      ctor.prototype = func.prototype;
      var child = new ctor, result = func.apply(child, args);
      return Object(result) === result ? result : child;
    })(cons, args, function(){});
  };
};

qc.fromFunction = function() {
  var arggens, fun;
  fun = arguments[0], arggens = 2 <= arguments.length ? slice.call(arguments, 1) : [];
  return function(size) {
    var arggen, args;
    args = (function() {
      var i, len, results;
      results = [];
      for (i = 0, len = arggens.length; i < len; i++) {
        arggen = arggens[i];
        results.push(arggen(size - 1));
      }
      return results;
    })();
    return fun.apply(null, args);
  };
};

var slice = [].slice;

qc.pick = function() {
  var range;
  range = 1 <= arguments.length ? slice.call(arguments, 0) : [];
  if (arguments.length === 1) {
    range = range[0];
  }
  return function() {
    return range[Math.floor(qc.random() * range.length)];
  };
};

qc.choose = function() {
  var range;
  range = 1 <= arguments.length ? slice.call(arguments, 0) : [];
  return qc.pick.apply(qc, range)();
};

qc.oneOf = function() {
  var generators;
  generators = 1 <= arguments.length ? slice.call(arguments, 0) : [];
  return function(size) {
    return qc.choose.apply(qc, generators)(size);
  };
};

qc.oneOfByPriority = function() {
  var generators;
  generators = 1 <= arguments.length ? slice.call(arguments, 0) : [];
  return function(size) {
    var gindex;
    gindex = Math.floor((1 - Math.sqrt(qc.random())) * generators.length);
    return generators[gindex](size);
  };
};

qc.except = function() {
  var anyMatches, generator, values;
  generator = arguments[0], values = 2 <= arguments.length ? slice.call(arguments, 1) : [];
  anyMatches = function(expect) {
    var v;
    return ((function() {
      var i, len, results;
      results = [];
      for (i = 0, len = values.length; i < len; i++) {
        v = values[i];
        if (v === expect) {
          results.push(true);
        }
      }
      return results;
    })()).length > 0;
  };
  return function(size) {
    var value;
    while (true) {
      value = generator(size);
      if (!anyMatches(value)) {
        return value;
      }
    }
  };
};

var arraysEqual,
  slice = [].slice,
  hasProp = {}.hasOwnProperty;

qc["function"] = function() {
  var args, generator, j, returnGenerator;
  args = 2 <= arguments.length ? slice.call(arguments, 0, j = arguments.length - 1) : (j = 0, []), returnGenerator = arguments[j++];
  generator = function(size) {
    var result;
    generator.calls = [];
    result = function() {
      var callArgs, k, l, len, ref, ref1, someArgs, value;
      someArgs = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      ref = generator.calls;
      for (k = 0, len = ref.length; k < len; k++) {
        ref1 = ref[k], callArgs = 2 <= ref1.length ? slice.call(ref1, 0, l = ref1.length - 1) : (l = 0, []), value = ref1[l++];
        if (arraysEqual(callArgs, someArgs)) {
          return value;
        }
      }
      value = returnGenerator(size);
      generator.calls.push(slice.call(someArgs).concat([value]));
      return value;
    };
    result.toString = function() {
      var arg, argNames, calls, clauses, condition, i, pos, value;
      calls = generator.calls;
      if (calls.length === 0) {
        return "function() { return " + (JSON.stringify(returnGenerator(10))) + "; }";
      }
      argNames = (function() {
        var k, ref, results;
        results = [];
        for (i = k = 0, ref = calls[0].length - 1; 0 <= ref ? k < ref : k > ref; i = 0 <= ref ? ++k : --k) {
          results.push(String.fromCharCode(i + 97));
        }
        return results;
      })();
      clauses = (function() {
        var k, l, len, ref, results;
        results = [];
        for (pos = k = 0, len = calls.length; k < len; pos = ++k) {
          ref = calls[pos], args = 2 <= ref.length ? slice.call(ref, 0, l = ref.length - 1) : (l = 0, []), value = ref[l++];
          condition = ((function() {
            var len1, m, results1;
            results1 = [];
            for (i = m = 0, len1 = args.length; m < len1; i = ++m) {
              arg = args[i];
              results1.push(argNames[i] + " === " + (JSON.stringify(arg)));
            }
            return results1;
          })()).join(' && ');
          if (calls.length === 1) {
            results.push("return " + (JSON.stringify(value)) + ";");
          } else if (pos === calls.length - 1) {
            results.push("{\n    return " + (JSON.stringify(value)) + ";\n  }");
          } else {
            results.push("if (" + condition + ") {\n    return " + (JSON.stringify(value)) + ";\n  }");
          }
        }
        return results;
      })();
      return "\nfunction(" + (argNames.join(", ")) + ") {\n  " + (clauses.join(" else ")) + "\n}";
    };
    return result;
  };
  return generator;
};

qc.pureFunction = qc["function"];

arraysEqual = function(a1, a2) {
  var arg, i, j, len;
  if (a1.length !== a2.length) {
    return false;
  }
  for (i = j = 0, len = a1.length; j < len; i = ++j) {
    arg = a1[i];
    if (arg !== a2[i]) {
      return false;
    }
    return true;
  }
};

qc.procedure = function(obj, injectorConfig) {
  var FN_ARG, FN_ARGS, FN_ARG_SPLIT, STRIP_COMMENTS, extractArgs, fnKeys, getGenerators, initializeInjector;
  if (injectorConfig == null) {
    injectorConfig = {};
  }
  FN_ARGS = /^function\s*[^\(]*\(\s*([^\)]*)\)/m;
  FN_ARG_SPLIT = /,/;
  FN_ARG = /^\s*(\S+?)\s*$/;
  STRIP_COMMENTS = /((\/\/.*$)|(\/\*[\s\S]*?\*\/))/mg;
  extractArgs = function(fn) {
    var argName, args, j, len, ref, results;
    args = fn.toString().replace(STRIP_COMMENTS, '').match(FN_ARGS);
    if (args) {
      ref = args[1].split(FN_ARG_SPLIT);
      results = [];
      for (j = 0, len = ref.length; j < len; j++) {
        argName = ref[j];
        if (argName !== '') {
          results.push(argName.match(FN_ARG)[1]);
        }
      }
      return results;
    }
  };
  fnKeys = function(obj) {
    var key, results, val;
    results = [];
    for (key in obj) {
      val = obj[key];
      if (key !== '$final' && (typeof val === 'function' || typeof val === 'object' && val.length && typeof val[val.length - 1] === 'function')) {
        results.push(key);
      }
    }
    return results;
  };
  getGenerators = function(injector, obj, prefix) {
    var fn, key;
    for (key in obj) {
      if (!hasProp.call(obj, key)) continue;
      fn = obj[key];
      if (typeof fn === 'function' && fn.length === 1 && extractArgs(fn)[0] === 'size') {
        injector[prefix + key] = fn;
      }
      getGenerators(injector, fn, prefix + key + '_');
    }
  };
  initializeInjector = function(injectorConfig) {
    var injector, key, val;
    injector = {};
    getGenerators(injector, qc, '');
    for (key in injectorConfig) {
      val = injectorConfig[key];
      injector[key] = val;
    }
    return injector;
  };
  return function(size) {
    var injector, invoke, result;
    injector = initializeInjector(injectorConfig);
    invoke = function(key, args, obj, result) {
      var fn, fnarguments, gen, injectors, name;
      injectors = [];
      injector.$args = function() {
        return args;
      };
      fn = function() {};
      if (typeof obj[key] === 'function') {
        fn = obj[key];
        if (obj[key].$inject != null) {
          injectors = obj[key].$inject != null;
        } else {
          injectors = (function() {
            var j, len, ref, results;
            ref = extractArgs(obj[key]);
            results = [];
            for (j = 0, len = ref.length; j < len; j++) {
              name = ref[j];
              results.push(injector[name.replace(/\d+$/, '')]);
            }
            return results;
          })();
        }
      } else {
        fn = obj[key][obj[key].length - 1];
        injectors = obj[key].slice(0, -1);
      }
      fnarguments = (function() {
        var j, len, results;
        results = [];
        for (j = 0, len = injectors.length; j < len; j++) {
          gen = injectors[j];
          results.push(gen(size));
        }
        return results;
      })();
      result.trace.push({
        key: key,
        args: fnarguments
      });
      return fn.apply(obj, fnarguments);
    };
    result = function() {
      var args, callee, execution, j, key, len, steps;
      args = 1 <= arguments.length ? slice.call(arguments, 0) : [];
      result.trace = [];
      result.classMode = typeof obj === 'function';
      callee = typeof obj === 'function' ? new obj(args) : obj;
      steps = fnKeys(callee);
      execution = qc.arrayOf(qc.pick(steps))(size);
      for (j = 0, len = execution.length; j < len; j++) {
        key = execution[j];
        invoke(key, args, callee, result);
      }
      if (callee.$final) {
        return invoke('$final', args, callee, result);
      } else {
        return void 0;
      }
    };
    result.toString = function() {
      var arg, args, code, j, key, len, name, ref, ref1, ret;
      code = [];
      name = obj.name || injector.name || 'Api';
      if (result.classMode) {
        code.push("var obj = new " + name + "(arguments);");
        name = 'obj';
      }
      ref = result.trace;
      for (j = 0, len = ref.length; j < len; j++) {
        ref1 = ref[j], key = ref1.key, args = ref1.args;
        ret = key === '$final' ? 'return ' : '';
        code.push("" + ret + name + "." + key + "(" + (((function() {
          var k, len1, results;
          results = [];
          for (k = 0, len1 = args.length; k < len1; k++) {
            arg = args[k];
            results.push(JSON.stringify(arg));
          }
          return results;
        })()).join(', ')) + ");");
      }
      return "function() {\n  " + (code.join('\n  ')) + "\n}";
    };
    return result;
  };
};

var adjust;

adjust = function(size) {
  if (size < 1) {
    return Math.abs(size) + 1;
  } else {
    return size;
  }
};

qc.intUpto = function(size) {
  return Math.floor(qc.random() * adjust(size));
};

qc.ureal = function(size) {
  return qc.random() * adjust(size * size);
};

qc.ureal.large = function(size) {
  return qc.random() * Number.MAX_VALUE;
};

qc.real = function(size) {
  return qc.choose(1, -1) * qc.ureal(size);
};

qc.real.large = function(size) {
  return qc.choose(1, -1) * qc.ureal.large();
};

qc.uint = function(size) {
  return qc.intUpto(adjust(size * size));
};

qc.uint.large = function(size) {
  return Math.floor(qc.random() * Number.MAX_VALUE);
};

qc.int = function(size) {
  return qc.choose(1, -1) * qc.intUpto(adjust(size * size));
};

qc.int.large = function(size) {
  return qc.choose(1, -1) * qc.uint.large();
};

qc.int.between = function(min, max) {
  return function(size) {
    return min + qc.intUpto(Math.min(max + 1 - min, adjust(size)));
  };
};

qc.natural = function(size) {
  return qc.intUpto(adjust(size * size)) + 1;
};

qc.natural.large = function(size) {
  return Math.ceil(qc.random() * Number.MAX_VALUE);
};

qc.range = function(gen) {
  if (gen == null) {
    gen = qc.real;
  }
  return function(size) {
    var end, start;
    start = gen(size);
    end = start + Math.abs(gen(size));
    if (start === end) {
      end += 1;
    }
    return [start, end];
  };
};

qc.range.inclusive = function(gen) {
  if (gen == null) {
    gen = qc.real;
  }
  return function(size) {
    var start;
    start = gen(size);
    return [start, start + Math.abs(gen(size))];
  };
};

qc.dice = function(config) {
  var code, consume, declaration, i, isConditional, match, max, num, token, toks;
  toks = config.trim();
  code = '';
  isConditional = false;
  declaration = false;
  consume = function(n) {
    return toks = toks.substring(n);
  };
  while (toks.length > 0) {
    token = toks[0];
    switch (false) {
      case token !== '+':
        code += ' + ';
        break;
      case token !== '-':
        code += ' - ';
        break;
      case token !== '*':
        code += ' * ';
        break;
      case token !== '/':
        throw new Error('Division is currently not supported');
        break;
      case token !== ' ':
        code;
        break;
      case token !== '(':
        code += '(';
        break;
      case token !== ')':
        code += ')';
        break;
      case token !== '?':
        isConditional = true;
        code += ' > 0 ? ';
        break;
      case !(token === ':' && isConditional):
        isConditional = false;
        code += ' : ';
        break;
      case !(match = toks.match(/^(\d*)d(\d+)/)):
        num = parseInt(match[1], 10) || 1;
        max = parseInt(match[2], 10);
        consume(match[0].length - 1);
        if (num < 5) {
          code += '(' + ((function() {
            var j, ref, results;
            results = [];
            for (i = j = 1, ref = num; 1 <= ref ? j <= ref : j >= ref; i = 1 <= ref ? ++j : --j) {
              results.push("Math.ceil(qc.random() * " + max + ")");
            }
            return results;
          })()).join(' + ') + ')';
        } else {
          declaration = true;
          code += "d(" + num + ", " + max + ")";
        }
        break;
      case !(match = toks.match(/^(\d*)F/)):
        num = parseInt(match[1], 10) || 1;
        consume(match[0].length - 1);
        code += "(qc.random() <= " + (Math.pow(0.5, num)) + " ? 1 : 0)";
        break;
      case !(match = toks.match(/^\d+/)):
        num = parseInt(match[0], 10);
        consume(match[0].length - 1);
        code += num;
        break;
      default:
        throw new Error("Unexpected token '" + token + "'.");
    }
    consume(1);
  }
  if (declaration) {
    return new Function("function d(num, max) {\n  var sum = 0;\n  for (var i = 0; i < num; i++) {\n    sum += Math.ceil(qc.random() * max);\n  }\n  return sum;\n}\n\nreturn " + code + ";");
  } else {
    return new Function("return " + code + ";");
  }
};

qc.objectLike = function(template) {
  return function(size) {
    var key, result, value;
    result = {};
    for (key in template) {
      value = template[key];
      if (typeof value === 'function') {
        result[key] = value(size);
      } else {
        result[key] = value;
      }
    }
    return result;
  };
};

qc.objectOf = function(generator, keygen) {
  if (keygen == null) {
    keygen = qc.string;
  }
  return function(size) {
    var i, j, ref, result;
    result = {};
    for (i = j = 0, ref = qc.intUpto(size); 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
      result[keygen(size)] = generator(i);
    }
    return result;
  };
};

qc.object = function(size) {
  return qc.objectOf(qc.any)(size);
};

var capture, generator, generatorForPattern, handleClass, makeComplimentaryRange, makeRange,
  indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

qc.char = function(size) {
  return String.fromCharCode(qc.byte());
};

qc.string = function(size) {
  var i, j, ref, s;
  s = "";
  for (i = j = 0, ref = qc.intUpto(size); 0 <= ref ? j <= ref : j >= ref; i = 0 <= ref ? ++j : --j) {
    s += qc.char();
  }
  return s;
};

qc.string.ascii = function(size) {
  var gen;
  gen = qc.pick(makeRange('a', 'z', true).concat(makeRange('0', '9')).concat(['_', ' ', '\n']));
  return qc.arrayOf(gen)(size).join('');
};

qc.string.concat = function(gens) {
  return function(size) {
    var gen;
    return ((function() {
      var j, len, results;
      results = [];
      for (j = 0, len = gens.length; j < len; j++) {
        gen = gens[j];
        results.push(gen(size));
      }
      return results;
    })()).join('');
  };
};

generator = {
  literal: function(lit, caseInsensitive) {
    if (caseInsensitive) {
      return function() {
        return qc.choose(lit.toLowerCase(), lit.toUpperCase());
      };
    } else {
      return function() {
        return lit;
      };
    }
  },
  dot: qc.except(qc.char, '\n'),
  repeat: function(gen, min, max) {
    return function(size) {
      var i;
      return ((function() {
        var j, ref, results;
        results = [];
        for (i = j = 0, ref = qc.int.between(min, max)(size); 0 <= ref ? j < ref : j > ref; i = 0 <= ref ? ++j : --j) {
          results.push(gen(size));
        }
        return results;
      })()).join('');
    };
  }
};

makeRange = function(from, to, caseInsensitive) {
  var charCode, j, lowerCase, ref, ref1, results, upperCase;
  if (caseInsensitive) {
    lowerCase = (function() {
      var j, ref, ref1, results;
      results = [];
      for (charCode = j = ref = from.toLowerCase().charCodeAt(0), ref1 = to.toLowerCase().charCodeAt(0); ref <= ref1 ? j <= ref1 : j >= ref1; charCode = ref <= ref1 ? ++j : --j) {
        results.push(String.fromCharCode(charCode));
      }
      return results;
    })();
    upperCase = (function() {
      var j, ref, ref1, results;
      results = [];
      for (charCode = j = ref = from.toUpperCase().charCodeAt(0), ref1 = to.toUpperCase().charCodeAt(0); ref <= ref1 ? j <= ref1 : j >= ref1; charCode = ref <= ref1 ? ++j : --j) {
        results.push(String.fromCharCode(charCode));
      }
      return results;
    })();
    return lowerCase.concat(upperCase);
  } else {
    results = [];
    for (charCode = j = ref = from.charCodeAt(0), ref1 = to.charCodeAt(0); ref <= ref1 ? j <= ref1 : j >= ref1; charCode = ref <= ref1 ? ++j : --j) {
      results.push(String.fromCharCode(charCode));
    }
    return results;
  }
};

makeComplimentaryRange = function(range) {
  var char, j, ref, results;
  results = [];
  for (char = j = 0; j <= 256; char = ++j) {
    if (!(ref = String.fromCharCode(char), indexOf.call(range, ref) >= 0)) {
      results.push(String.fromCharCode(char));
    }
  }
  return results;
};

capture = function(gen, captures, captureLevel) {
  return function(size) {
    var name, value;
    value = gen(size);
    if (captures[name = captureLevel.toString()] == null) {
      captures[name] = [];
    }
    captures[captureLevel.toString()].push(value);
    return value;
  };
};

handleClass = function(token, captures, captureLevel) {
  var index;
  switch (token) {
    case 'w':
      return makeRange('a', 'z', true).concat(makeRange('0', '9')).concat(['_']);
    case 'W':
      return makeComplimentaryRange(makeRange('a', 'z', true).concat(makeRange('0', '9')).concat(['_']));
    case 'd':
      return makeRange('0', '9');
    case 'D':
      return makeComplimentaryRange(makeRange('0', '9'));
    case 's':
      return [' ', '\f', '\n', '\r', '\t', '\v'];
    case 'S':
      return makeComplimentaryRange([' ', '\f', '\n', '\r', '\t', '\v']);
    case 'n':
      return ["\n"];
    case 't':
      return ["\t"];
    case 'v':
      return ["\v"];
    case 'b':
      return ['\b'];
    case 'f':
      return ['\f'];
    case 'r':
      return ['\r'];
    case 'c':
      throw 'Control sequences not supported';
      break;
    case '1':
    case '2':
    case '3':
    case '4':
    case '5':
    case '6':
    case '7':
    case '8':
    case '9':
      if (captures) {
        index = parseInt(token, 10);
        return function() {
          var j, level, offset;
          offset = 0;
          for (level = j = 0; j <= 9; level = ++j) {
            if (captures[level.toString()] != null) {
              if (index - offset < captures[level.toString()].length) {
                return captures[level.toString()][index - offset];
              } else {
                offset += captures[level.toString()].length;
              }
            } else {
              offset += 1;
            }
          }
        };
      }
      break;
    default:
      return [token];
  }
};

generatorForPattern = function(toks, caseInsensitive, captures, captureLevel) {
  var char, charachters, chars, from, gens, negative, str, subtoken, to, token;
  gens = [];
  while (toks.length > 0) {
    token = toks.shift();
    if (token.match(/[\w\s=]/i)) {
      gens.push(generator.literal(token, caseInsensitive));
    } else if (token === '^') {
      captures.isHookedFromStart = true;
    } else if (token === '$') {
      captures.isHookedFromEnd = true;
    } else if (token === '.') {
      gens.push(generator.dot);
    } else if (token === '*') {
      if (toks[0] === '?') {
        console.log("Lazy repeaters may provide incorrect results");
        toks.shift();
        gens.push(generator.repeat(gens.pop(), 0, 10));
      } else {
        gens.push(generator.repeat(gens.pop(), 0, 100));
      }
    } else if (token === '?') {
      gens.push(generator.repeat(gens.pop(), 0, 1));
    } else if (token === '+') {
      if (toks[0] === '?') {
        console.log("Lazy repeaters may provide incorrect results");
        toks.shift();
        gens.push(generator.repeat(gens.pop(), 1, 10));
      } else {
        gens.push(generator.repeat(gens.pop(), 1, 100));
      }
    } else if (token === '|') {
      return qc.oneOf(qc.string.concat(gens), generatorForPattern(toks));
    } else if (token === '[') {
      charachters = [];
      negative = false;
      while (true) {
        char = toks.shift();
        if (char === ']') {
          break;
        } else if (char === '^') {
          negative = true;
        } else if (char === '\\') {
          charachters = charachters.concat(handleClass(toks.shift()));
        } else if (char === '-') {
          charachters = charachters.concat(makeRange(charachters.pop(), toks.shift(), caseInsensitive));
        } else {
          charachters.push(char);
        }
      }
      if (negative) {
        gens.push(qc.pick(makeComplimentaryRange(charachters)));
      } else {
        gens.push(qc.pick(charachters));
      }
    } else if (token === ')') {
      break;
    } else if (token === '\\') {
      chars = handleClass(toks.shift(), captures, captureLevel);
      if (typeof chars === 'function') {
        gens.push(chars);
      } else {
        gens.push(qc.pick(chars));
      }
    } else if (token === '{') {
      subtoken = toks.shift();
      str = '';
      while (!(subtoken === ',' || subtoken === '}')) {
        str += subtoken;
        subtoken = toks.shift();
      }
      from = parseInt(str, 10);
      if (subtoken === '}') {
        to = from;
      } else {
        str = '';
        subtoken = toks.shift();
        if (subtoken === '}') {
          to = 100;
        } else {
          while (subtoken !== '}') {
            str += subtoken;
            subtoken = toks.shift();
          }
          to = parseInt(str, 10);
        }
      }
      gens.push(generator.repeat(gens.pop(), from, to));
    } else if (token === '(') {
      if (toks[0] === '?' && (toks[1] === ':' || toks[1] === '=')) {
        toks.shift();
        toks.shift();
        gens.push(generatorForPattern(toks, caseInsensitive, captures, captureLevel));
      } else if (toks[0] === '?' && toks[1] === '!') {
        toks.shift();
        toks.shift();
        throw "Negative lookahead is not supported.";
      } else {
        gens.push(capture(generatorForPattern(toks, caseInsensitive, captures, captureLevel + 1), captures, captureLevel));
      }
    } else {
      gens.push(function() {
        return token;
      });
    }
  }
  return qc.string.concat(gens);
};

qc.string.matching = function(pattern) {
  var captures, patternGenerator, toks;
  toks = pattern.source.split('');
  captures = {};
  patternGenerator = capture(generatorForPattern(toks, pattern.ignoreCase, captures, 1), captures, 0);
  if (pattern.global && !captures.isHookedFromStart && !captures.isHookedFromEnd) {
    return generator.repeat(qc.oneOf(patternGenerator, qc.string), 1, 10);
  } else if (!captures.isHookedFromStart && !captures.isHookedFromEnd) {
    return qc.string.concat([qc.string, patternGenerator, qc.string]);
  } else if (!captures.isHookedFromStart && captures.isHookedFromEnd) {
    return qc.string.concat([qc.string, patternGenerator]);
  } else if (captures.isHookedFromStart && !captures.isHookedFromEnd) {
    return qc.string.concat([patternGenerator, qc.string]);
  } else {
    return patternGenerator;
  }
};

qc.date = function(size) {
  var d, hh, m, mm, ms, ss, y;
  y = qc.intUpto(3000);
  m = qc.intUpto(12);
  d = qc.intUpto(m === 0 || m === 2 || m === 4 || m === 6 || m === 7 || m === 9 || m === 11 ? 31 : m === 3 || m === 5 || m === 8 || m === 10 ? 30 : 28);
  hh = qc.intUpto(24);
  mm = qc.intUpto(60);
  ss = qc.intUpto(60);
  ms = qc.intUpto(1000);
  return new Date(y, m, d, hh, mm, ss, ms);
};

qc.any = qc.oneOfByPriority(qc.bool, qc.int, qc.real, (function() {
  return function() {};
}), (function() {
  return void 0;
}), qc.string, qc.array, qc.object);

qc.any.simple = qc.oneOf(qc.bool, qc.int, qc.real, qc.string, qc.pick(void 0, null));

qc.any.datatype = qc.oneOf(qc.bool, qc.int, qc.real, qc.string, qc.pick(void 0, null), qc.array, qc.object);

qc.color = qc.string.matching(/^\#([A-F\d]{6}|[A-F\d]{3})$/i);

qc.location = function(size) {
  var rad2deg, x, y;
  rad2deg = function(n) {
    return 360 * n / (2 * Math.PI);
  };
  x = qc.random() * 2 * Math.PI - Math.PI;
  y = Math.PI / 2 - Math.acos(qc.random() * 2 - 1);
  return [rad2deg(y), rad2deg(x)];
};

var slice = [].slice;

if (typeof jasmine !== "undefined" && jasmine !== null) {
  beforeEach(function() {
    return jasmine.addMatchers({
      forAll: function() {
        return {
          compare: qc,
          negativeCompare: function() {
            var examples, gens, message, orig, pass, prop, ref;
            prop = arguments[0], gens = 2 <= arguments.length ? slice.call(arguments, 1) : [];
            orig = qc._performShrinks;
            qc._performShrinks = false;
            ref = qc.apply(null, [prop].concat(slice.call(gens))), pass = ref.pass, examples = ref.examples, message = ref.message;
            qc._performShrinks = orig;
            return {
              examples: examples,
              message: message,
              pass: !pass
            };
          }
        };
      }
    });
  });
}

var slice = [].slice;

if (typeof QUnit !== "undefined" && QUnit !== null) {
  QUnit.assert.forAll = function() {
    var examples, generators, message, pass, property, ref;
    property = arguments[0], generators = 2 <= arguments.length ? slice.call(arguments, 1) : [];
    ref = qc.apply(null, [property].concat(slice.call(generators))), pass = ref.pass, examples = ref.examples, message = ref.message;
    return this.push(pass, property, examples, message);
  };
}
})();