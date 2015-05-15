(function(){ 
 'use strict';
var makeHistogram, qc, stringify,
  __slice = [].slice;

qc = function() {
  var examples, generator, generators, hist, histString, i, num, prop, result, skipped, skippedString, _i;
  prop = arguments[0], generators = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
  num = 100;
  skipped = 0;
  hist = {};
  for (i = _i = 0; 0 <= num ? _i < num : _i > num; i = 0 <= num ? ++_i : --_i) {
    examples = (function() {
      var _j, _len, _results;
      _results = [];
      for (_j = 0, _len = generators.length; _j < _len; _j++) {
        generator = generators[_j];
        _results.push(generator(i));
      }
      return _results;
    })();
    result = prop.apply(null, examples);
    if (result === false) {
      skippedString = skipped > 0 ? " (" + skipped + " skipped)" : "";
      return {
        pass: false,
        examples: examples,
        message: "Falsified after " + i + " attempts" + skippedString + ". Counter-example: " + (stringify(examples, generators))
      };
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
    var _i, _len, _results;
    if (typeof example === 'function') {
      return example.toString();
    } else {
      _results = [];
      for (_i = 0, _len = examples.length; _i < _len; _i++) {
        example = examples[_i];
        _results.push(JSON.stringify(example));
      }
      return _results;
    }
  })()).join(', ');
};

makeHistogram = function(hist, total) {
  var count, label;
  hist = (function() {
    var _results;
    _results = [];
    for (label in hist) {
      count = hist[label];
      _results.push({
        label: label,
        count: count
      });
    }
    return _results;
  })();
  hist.sort(function(_arg, _arg1) {
    var a, b;
    a = _arg.count;
    b = _arg1.count;
    return a - b;
  });
  return "\n" + hist.map(function(_arg) {
    var count, label;
    label = _arg.label, count = _arg.count;
    return "" + (((count / total) * 100).toFixed(2)) + "% " + label;
  }).join("\n");
};

qc.forAll = function() {
  var examples, generator, generators, i, prop, _i, _j;
  generators = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), prop = arguments[_i++];
  for (i = _j = 0; _j < 100; i = ++_j) {
    examples = (function() {
      var _k, _len, _results;
      _results = [];
      for (_k = 0, _len = generators.length; _k < _len; _k++) {
        generator = generators[_k];
        _results.push(generator(i));
      }
      return _results;
    })();
    prop.apply(null, examples);
  }
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

var normalizeOptions;

normalizeOptions = function(options) {
  if (options == null) {
    options = {};
  }
  return {
    length: options.length != null ? typeof options.length === 'function' ? options.length : function() {
      return options.length;
    } : qc.intUpto
  };
};

qc.arrayOf = function(generator, options) {
  if (options == null) {
    options = {};
  }
  return function(size) {
    var i, _i, _ref, _results;
    _results = [];
    for (i = _i = 0, _ref = normalizeOptions(options).length(size); 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
      _results.push(generator(i));
    }
    return _results;
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
    options.length = qc.intUpto(array.length);
  }
  return function(size) {
    var copy, i, _i, _ref, _results;
    copy = array.slice();
    _results = [];
    for (i = _i = 0, _ref = normalizeOptions(options).length(size); 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
      _results.push(copy.splice(qc.intUpto(copy.length), 1)[0]);
    }
    return _results;
  };
};

var __slice = [].slice;

qc.bool = function(size) {
  return qc.choose(true, false);
};

qc.byte = function(size) {
  return Math.floor(qc.random() * 256);
};

qc.constructor = function() {
  var arggens, cons;
  cons = arguments[0], arggens = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
  return function(size) {
    var arggen, args;
    args = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = arggens.length; _i < _len; _i++) {
        arggen = arggens[_i];
        _results.push(arggen(size - 1));
      }
      return _results;
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
  fun = arguments[0], arggens = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
  return function(size) {
    var arggen, args;
    args = (function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = arggens.length; _i < _len; _i++) {
        arggen = arggens[_i];
        _results.push(arggen(size - 1));
      }
      return _results;
    })();
    return fun.apply(null, args);
  };
};

var __slice = [].slice;

qc.pick = function() {
  var range;
  range = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
  if (arguments.length === 1) {
    range = range[0];
  }
  return function() {
    return range[Math.floor(qc.random() * range.length)];
  };
};

qc.choose = function() {
  var range;
  range = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
  return qc.pick.apply(qc, range)();
};

qc.oneOf = function() {
  var generators;
  generators = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
  return function(size) {
    return qc.choose.apply(qc, generators)(size);
  };
};

qc.oneOfByPriority = function() {
  var generators;
  generators = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
  return function(size) {
    var gindex;
    gindex = Math.floor((1 - Math.sqrt(qc.random())) * generators.length);
    return generators[gindex](size);
  };
};

qc.except = function() {
  var anyMatches, generator, values;
  generator = arguments[0], values = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
  anyMatches = function(expect) {
    var v;
    return ((function() {
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = values.length; _i < _len; _i++) {
        v = values[_i];
        if (v === expect) {
          _results.push(true);
        }
      }
      return _results;
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
  __slice = [].slice,
  __hasProp = {}.hasOwnProperty;

qc["function"] = function() {
  var args, generator, returnGenerator, _i;
  args = 2 <= arguments.length ? __slice.call(arguments, 0, _i = arguments.length - 1) : (_i = 0, []), returnGenerator = arguments[_i++];
  generator = function(size) {
    var result;
    generator.calls = [];
    result = function() {
      var callArgs, someArgs, value, _j, _k, _len, _ref, _ref1;
      someArgs = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      _ref = generator.calls;
      for (_j = 0, _len = _ref.length; _j < _len; _j++) {
        _ref1 = _ref[_j], callArgs = 2 <= _ref1.length ? __slice.call(_ref1, 0, _k = _ref1.length - 1) : (_k = 0, []), value = _ref1[_k++];
        if (arraysEqual(callArgs, someArgs)) {
          return value;
        }
      }
      value = returnGenerator(size);
      generator.calls.push(__slice.call(someArgs).concat([value]));
      return value;
    };
    result.toString = function() {
      var arg, argNames, calls, clauses, condition, i, pos, value;
      calls = generator.calls;
      if (calls.length === 0) {
        return "function() { return " + (JSON.stringify(returnGenerator(10))) + "; }";
      }
      argNames = (function() {
        var _j, _ref, _results;
        _results = [];
        for (i = _j = 0, _ref = calls[0].length - 1; 0 <= _ref ? _j < _ref : _j > _ref; i = 0 <= _ref ? ++_j : --_j) {
          _results.push(String.fromCharCode(i + 97));
        }
        return _results;
      })();
      clauses = (function() {
        var _j, _k, _len, _ref, _results;
        _results = [];
        for (pos = _j = 0, _len = calls.length; _j < _len; pos = ++_j) {
          _ref = calls[pos], args = 2 <= _ref.length ? __slice.call(_ref, 0, _k = _ref.length - 1) : (_k = 0, []), value = _ref[_k++];
          condition = ((function() {
            var _l, _len1, _results1;
            _results1 = [];
            for (i = _l = 0, _len1 = args.length; _l < _len1; i = ++_l) {
              arg = args[i];
              _results1.push("" + argNames[i] + " === " + (JSON.stringify(arg)));
            }
            return _results1;
          })()).join(' && ');
          if (calls.length === 1) {
            _results.push("return " + (JSON.stringify(value)) + ";");
          } else if (pos === calls.length - 1) {
            _results.push("{\n    return " + (JSON.stringify(value)) + ";\n  }");
          } else {
            _results.push("if (" + condition + ") {\n    return " + (JSON.stringify(value)) + ";\n  }");
          }
        }
        return _results;
      })();
      return "\nfunction(" + (argNames.join(", ")) + ") {\n  " + (clauses.join(" else ")) + "\n}";
    };
    return result;
  };
  return generator;
};

arraysEqual = function(a1, a2) {
  var arg, i, _i, _len;
  if (a1.length !== a2.length) {
    return false;
  }
  for (i = _i = 0, _len = a1.length; _i < _len; i = ++_i) {
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
    var argName, args, _i, _len, _ref, _results;
    args = fn.toString().replace(STRIP_COMMENTS, '').match(FN_ARGS);
    if (args) {
      _ref = args[1].split(FN_ARG_SPLIT);
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        argName = _ref[_i];
        if (argName !== '') {
          _results.push(argName.match(FN_ARG)[1]);
        }
      }
      return _results;
    }
  };
  fnKeys = function(obj) {
    var key, val, _results;
    _results = [];
    for (key in obj) {
      val = obj[key];
      if (key !== '$final' && (typeof val === 'function' || typeof val === 'object' && val.length && typeof val[val.length - 1] === 'function')) {
        _results.push(key);
      }
    }
    return _results;
  };
  getGenerators = function(injector, obj, prefix) {
    var fn, key;
    for (key in obj) {
      if (!__hasProp.call(obj, key)) continue;
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
    var injector, invoke;
    injector = initializeInjector(injectorConfig);
    invoke = function(key, args) {
      var fn, gen, injectors, name;
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
            var _i, _len, _ref, _results;
            _ref = extractArgs(obj[key]);
            _results = [];
            for (_i = 0, _len = _ref.length; _i < _len; _i++) {
              name = _ref[_i];
              _results.push(injector[name.replace(/\d+$/, '')]);
            }
            return _results;
          })();
        }
      } else {
        fn = obj[key][obj[key].length - 1];
        injectors = obj[key].slice(0, -1);
      }
      return fn.apply(obj, (function() {
        var _i, _len, _results;
        _results = [];
        for (_i = 0, _len = injectors.length; _i < _len; _i++) {
          gen = injectors[_i];
          _results.push(gen(size));
        }
        return _results;
      })());
    };
    return function() {
      var args, execution, key, steps, _i, _len;
      args = 1 <= arguments.length ? __slice.call(arguments, 0) : [];
      obj = typeof obj === 'function' ? new obj(args) : obj;
      steps = fnKeys(obj);
      execution = qc.arrayOf(qc.pick(steps))(size);
      for (_i = 0, _len = execution.length; _i < _len; _i++) {
        key = execution[_i];
        invoke(key, args);
      }
      if (obj.$final) {
        return invoke('$final', args);
      } else {
        return void 0;
      }
    };
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
  return qc.choose(1, -1) * qc.intUpto(adjust(size));
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
            var _i, _results;
            _results = [];
            for (i = _i = 1; 1 <= num ? _i <= num : _i >= num; i = 1 <= num ? ++_i : --_i) {
              _results.push("Math.ceil(qc.random() * " + max + ")");
            }
            return _results;
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
    var i, result, _i, _ref;
    result = {};
    for (i = _i = 0, _ref = qc.intUpto(size); 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
      result[keygen(size)] = generator(i);
    }
    return result;
  };
};

qc.object = function(size) {
  return qc.objectOf(qc.any)(size);
};

var capture, generator, generatorForPattern, handleClass, makeComplimentaryRange, makeRange,
  __indexOf = [].indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

qc.char = function(size) {
  return String.fromCharCode(qc.byte());
};

qc.string = function(size) {
  var i, s, _i, _ref;
  s = "";
  for (i = _i = 0, _ref = qc.intUpto(size); 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
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
      var _i, _len, _results;
      _results = [];
      for (_i = 0, _len = gens.length; _i < _len; _i++) {
        gen = gens[_i];
        _results.push(gen(size));
      }
      return _results;
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
        var _i, _ref, _results;
        _results = [];
        for (i = _i = 0, _ref = qc.int.between(min, max)(size); 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
          _results.push(gen(size));
        }
        return _results;
      })()).join('');
    };
  }
};

makeRange = function(from, to, caseInsensitive) {
  var charCode, lowerCase, upperCase, _i, _ref, _ref1, _results;
  if (caseInsensitive) {
    lowerCase = (function() {
      var _i, _ref, _ref1, _results;
      _results = [];
      for (charCode = _i = _ref = from.toLowerCase().charCodeAt(0), _ref1 = to.toLowerCase().charCodeAt(0); _ref <= _ref1 ? _i <= _ref1 : _i >= _ref1; charCode = _ref <= _ref1 ? ++_i : --_i) {
        _results.push(String.fromCharCode(charCode));
      }
      return _results;
    })();
    upperCase = (function() {
      var _i, _ref, _ref1, _results;
      _results = [];
      for (charCode = _i = _ref = from.toUpperCase().charCodeAt(0), _ref1 = to.toUpperCase().charCodeAt(0); _ref <= _ref1 ? _i <= _ref1 : _i >= _ref1; charCode = _ref <= _ref1 ? ++_i : --_i) {
        _results.push(String.fromCharCode(charCode));
      }
      return _results;
    })();
    return lowerCase.concat(upperCase);
  } else {
    _results = [];
    for (charCode = _i = _ref = from.charCodeAt(0), _ref1 = to.charCodeAt(0); _ref <= _ref1 ? _i <= _ref1 : _i >= _ref1; charCode = _ref <= _ref1 ? ++_i : --_i) {
      _results.push(String.fromCharCode(charCode));
    }
    return _results;
  }
};

makeComplimentaryRange = function(range) {
  var char, _i, _ref, _results;
  _results = [];
  for (char = _i = 0; _i <= 256; char = ++_i) {
    if (!(_ref = String.fromCharCode(char), __indexOf.call(range, _ref) >= 0)) {
      _results.push(String.fromCharCode(char));
    }
  }
  return _results;
};

capture = function(gen, captures, captureLevel) {
  return function(size) {
    var value, _name;
    value = gen(size);
    if (captures[_name = captureLevel.toString()] == null) {
      captures[_name] = [];
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
          var level, offset, _i;
          offset = 0;
          for (level = _i = 0; _i <= 9; level = ++_i) {
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

if (typeof jasmine !== "undefined" && jasmine !== null) {
  beforeEach(function() {
    return jasmine.addMatchers({
      forAll: function() {
        return {
          compare: qc
        };
      }
    });
  });
}

var __slice = [].slice;

if (typeof QUnit !== "undefined" && QUnit !== null) {
  QUnit.assert.forEach = function() {
    var examples, generators, message, pass, property, _ref;
    property = arguments[0], generators = 2 <= arguments.length ? __slice.call(arguments, 1) : [];
    _ref = qc.apply(null, [property].concat(__slice.call(generators))), pass = _ref.pass, examples = _ref.examples, message = _ref.message;
    return QUnit.push(pass, property, examples, message);
  };
}
})();