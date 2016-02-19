/**
 * A function that should generate a random value of a particular type.
 * @param size This is used to generate "larger" values.
 */
declare interface QCGenerator<T> {
  (size: number) : T;
}

/**
 * An object that indicates the result of a quick_check test.
 */
interface QCResult {
  /** Indicates whether the assertion passed all the generated examples */
  pass: boolean;
  /** The (non-shrunk) examples that failed the test (or the last generated examples in case of success). */
  examples: any[];
  /** The minimal (i.e. shrunk) examples that failed the test. */
  minimalExamples?: any[];
  /** A message indicating the status of the test run. This is suitable for printing to the user. */
  message: string
}

/**
 * The behavior of quick check is based on the return type:
 * - `true` means a pass
 * - `false` means failure
 * - a string means a pass with the examples falling into a particular category
 * - `void` means this set of examples should be skipped
 */
declare type QCAssertionResult = boolean | string | void;

/**
 * This function executes a check of the function `prop` using `generators`
 * @param prop The property you wish to execute.
 * @param generators The generators that supply values to the property.
 */
declare function qc<T>(prop: (arg: T) => QCAssertionResult, generator : QCGenerator<T>) : QCResult;
declare function qc<T, U>(prop: (arg1: T, arg2: U) => QCAssertionResult, generator1 : QCGenerator<T>, generator2 : QCGenerator<U>) : QCResult;
declare function qc<T, U, V>(prop: (arg1: T, arg2: U, arg3: V) => QCAssertionResult, generator1 : QCGenerator<T>, generator2 : QCGenerator<U>, generator3 : QCGenerator<V>) : QCResult;
declare function qc(prop: (...values: any[]) => QCAssertionResult, ...generators : QCGenerator<any>[]) : QCResult;

declare module qc {
  /**
   * This function executes a check of the function `prop` using `generators`, but ignores the result.
   * @param prop The property you wish to execute.
   * @param generators The generators that supply values to the property.
   */
  function forAll<T, U>(prop: (arg: T) => U, generator : QCGenerator<T>): [U];
  function forAll<T, U, V>(prop: (arg1: T, arg2: U) => V, generator1 : QCGenerator<T>, generator2 : QCGenerator<U>): [V];
  function forAll<T, U, V, W>(prop: (arg1: T, arg2: U, arg3: V) => W, generator1 : QCGenerator<T>, generator2 : QCGenerator<U>, generator3 : QCGenerator<V>): [W];
  function forAll<T>(prop: (...values: any[]) => T, ...generators: QCGenerator<any>[]): [T];
  /**
   * Generates a random value between 0 and 1.
   */
  function random(): number;
  /**
   * Generates either `true` or `false`.
   */
  var bool : QCGenerator<boolean>;
  /**
   * Generates an integer between 0 and 255.
   */
  var byte : QCGenerator<number>;
  /**
   * Generates a new value from a constructor function (or a class).
   * @param cons A constructor function or a class.
   * @param generators quick_check.js generators that supply arguments to cons.
   * @return An instance of cons.
   */
  function constructor<T, U>(cons: {new(arg: U): T;}, generator: QCGenerator<U>) : QCGenerator<T>;
  function constructor<T, U, V>(cons: {new(arg1: U, arg2: V): T;}, generator1: QCGenerator<U>, generator2: QCGenerator<V>) : QCGenerator<T>;
  function constructor<T, U, V, W>(cons: {new(arg1: U, arg2: V, arg3: W): T;}, generator1: QCGenerator<U>, generator2: QCGenerator<V>, generator3: QCGenerator<W>) : QCGenerator<T>;
  function constructor<T>(cons: {new(...args: any[]): T;}, ...generators: QCGenerator<any>[]) : QCGenerator<T>;
  /**
   * Generates a new value using a custom function.
   * @param fun A function that generates the value
   * @param generators quick_check.js generators that supply arguments to `fun`.
   */
  function fromFunction<T, U>(fun: (arg: U) => T, generator: QCGenerator<U>) : QCGenerator<T>;
  function fromFunction<T, U, V>(fun: (arg1: U, arg2: V) => T, generator1: QCGenerator<U>, generator2: QCGenerator<V>) : QCGenerator<T>;
  function fromFunction<T, U, V, W>(fun: (arg1: U, arg2: V, arg3: W) => T, generator1: QCGenerator<U>, generator2: QCGenerator<V>, generator3: QCGenerator<W>) : QCGenerator<T>;
  function fromFunction<T>(fun: (...args: any[]) => T, ...generators: QCGenerator<any>[]) : QCGenerator<T>;

  interface ArrayOptions {
    /** How many elements the array should have. */
    length?: number | QCGenerator<number>;
    /** Whether the array should be sparse, i.e. include elements that are void. */
    sparse?: boolean;
  }
  /**
   * Generates an array of values provided by the generator passed in.
   * @param generator A generator that provides the values in the resulting array.
   */
  function arrayOf<T>(generator: QCGenerator<T>, options?: ArrayOptions) : QCGenerator<T[]>;
  interface ArrayGenerator extends QCGenerator<any[]> {
    /**
     * Generates a random subset of an array.
     * @param array The array that the elements will be drawn from.
     */
    subsetOf<T>(array: T[], options? : ArrayOptions) : QCGenerator<T>[];
  }
  /**
   * Generates a random array.
   */
  var array : ArrayGenerator;

  function pick(...args: any[]) : QCGenerator<any>;
  function oneOf<T,U>(generator1: QCGenerator<T>, generator2: QCGenerator<U>) : QCGenerator<T|U>;
  function oneOf<T,U,V>(generator1: QCGenerator<T>, generator2: QCGenerator<U>, generator3: QCGenerator<V>) : QCGenerator<T|U|V>;
  function oneOf(...generators: QCGenerator<any>[]) : QCGenerator<any>;
  /**
   * Ensures that the generator passed in will not return any of the values passed.
   * Note that the performance of this method is inversely proportional to the probability
   * of the excluded values (i.e. if the probability of the values is 1, then the function
   * will never terminate).
   */
  function except<T>(generator: QCGenerator<T>, ...values: T[]) : QCGenerator<T>;

  /**
   * Generates a pure function that returns a random value of the `returnType`.
   * It has the property of returning the same value given the same arguments.
   */
  function pureFunction<T>(returnType: QCGenerator<T>) : QCGenerator<(...args: any[]) => T>;
  /**
   * Allows to execute random side effects :)
   * @param obj An object or Class whose methods wiil be injected with random values and then called.
   * @param injectorConfig Allows injecting arbitrary values.
   * @return A generator for a value produced by the `$final method` of `obj`.
   */
  function procedure(obj: any, injectorConfig?: Object) : QCGenerator<any>;

  interface NumberGenerator extends QCGenerator<number> {
    /**
     * Generates a larger version of the number. This can have a performance impact on your tests.
     */
    large: QCGenerator<number>;
  }
  interface IntGenerator extends NumberGenerator {
    /**
     * Generates an integer between `min` and `max`.
     */
    between(min: number, max: number) : QCGenerator<number>;
  }

  /**
   * Returns a number between zero and size.
   */
  var intUpto : QCGenerator<number>;
  /**
   * Generates a possitive real number.
   */
  var ureal : NumberGenerator;
  /**
   * Generates a real number.
   */
  var real : NumberGenerator;
  /**
   * Generates a positive integer.
   */
  var uint : NumberGenerator;
  /**
   * Generates an integer.
   */
  var int : IntGenerator;
  /**
   * Generates a natural number (like uint, but excluding zero).
   */
  var natural: NumberGenerator;

  interface RangeGenerator {
    (generator?: QCGenerator<number>) : QCGenerator<[number, number]>;
    /**
     * Generates an array of two numbers where the second is guaranteed to be greater or equal than the first.
     */
    inclusive(generator?: QCGenerator<number>) : QCGenerator<[number, number]>;
  }
  /**
   * Generates an array of two numbers where the second is guaranteed to be greater than the first.
   * By default the numbers are supplied by qc.real, but you can customize the generator.
   */
  var range: RangeGenerator;
  /**
   * Generates a random number based on a D&D style dice string.
   * @param config A string that represents dics, i.e. `3d6`.
   */
  function dice(config: string): QCGenerator<number>;

  /**
   * Generates a random object based on a template object, where functions get
   * called with a size param to generate a random value.
   * @param template Any values will be copied verbatim, functions will get called.
   */
  function objectLike(template: Object) : QCGenerator<Object>;
  /**
   * Generates an object where the values are produced by a suplied generator.
   * @param generator This generator will be called to produce the values.
   * @param keyGenerator This generator will be called to produce the keys.
   *     By default this will be `qc.string`.
   *     Remember that Objects have to have string keys.
   */
  function objectOf<T>(generator: QCGenerator<T>, keyGenerator?: QCGenerator<string>) : QCGenerator<Object>;
  /**
   * Generates a random object.
   */
  var object : QCGenerator<Object>;

  /**
   * Generates a string of length 1.
   */
  var char : QCGenerator<string>;
  interface StringGenerator extends QCGenerator<string> {
    /**
     * Generates a string containing only ascii characters.
     */
    ascii: QCGenerator<string>;
    /**
     * Generates a string by concatenating the results of all the generators passed in.
     * @param generators An array of generators that produce strings.
     */
    concat(generators: QCGenerator<string>[]) : QCGenerator<string>;
    /**
     * Generates a string that matches a supplied regular expression.
     * @param pattern The pattern that will be used to produce the target string.
     */
    matching(pattern: RegExp) : QCGenerator<string>;
  }
  /**
   * Generates a completely random string.
   */
  var string : StringGenerator;

  /**
   * Generates a random, but valid, date.
   */
  var date : QCGenerator<Date>;
  interface AnyGenerator extends QCGenerator<any> {
    /**
     * Generates a 'simple' value which could be a boolean, number, string, null or undefined.
     */
    simple: QCGenerator<boolean|number|string|void>;
    /**
     * Generates a random value, that will however not contain any functions.
     */
    datatype: QCGenerator<any>;
  }
  /**
   * Generates a completely random value. No assumptions about the type of the return value should be made.
   * However the current implementation only actually returns limited built-in types.
   */
  var any : AnyGenerator;
  /**
   * Generates a valid web color string.
   */
  var color: QCGenerator<string>;
  /**
   * Generates a pair of lat, long coordinates.
   */
  var location: QCGenerator<[number, number]>;

  /**
   * An ES6 compatible iterator structure.
   */
  interface Iterator<T> {
    next() : {
      value? : T,
      done: boolean
    }
  }
  /**
   * A shrinker is an object responsible for reducing data of a particular data type.
   */
  interface Shrinker {
    /**
     * Returns whether the passed in value is applicable to the current shrinker.
     * Typically this will be a typecheck of some sort.
     */
    valid(value: any) : boolean;
    /**
     * Should (preferably lazily) compute smaller versions of the value passed in.
     * To avoid non-termination, a smaller value shrunk should never produce the original value.
     */
    shrinker<T>(value: T) : Iterator<T>;
  }
  /**
   * Reduces an arbitrary value to a smaller value.
   * @param value The value to shrink.
   * @param hint This can be a shrinker if you believe that this shrinker is applicable to the value in question.
   *     This is a performance optimization.
   * @param registry By default the global registry of shrinkers will be used to perform shrinking.
   *     This value allows you to override this.
   */
  function shrink<T>(value: T, hint?: Shrinker, registry?: Shrinker[]): Shrinker;
  /**
   * Constructs a shrinker and adds it to the global repository.
   * @param valid Returns whether the passed in value is applicable to the current shrinker.
   *       Typically this will be a typecheck of some sort.
   * @param shrinker Should (preferably lazily) compute smaller versions of the value passed in.
   *       To avoid non-termination, a smaller value shrunk should never produce the original value.
   */
  function addShrinker<T>(valid: (value: any) => boolean, shrinker: (value : T) => Iterator<T>) : Shrinker;

  /**
   * Wraps a value in a generator.
   */
  function of<T>(value: T) : QCGenerator<T>;
  /**
   * Applies a function to a generator producing a new generator.
   * Curried.
   * @param f A function that transforms a value into another value.
   * @param generator A generator that produces the initial value of f.
   */
  function map<T, U>(f: (arg: T) => U, generator: QCGenerator<T>) : QCGenerator<U>;
  function map<T, U>(f: (arg: T) => U) : (generator: QCGenerator<T>) => QCGenerator<U>;
  /**
   * Unwraps generators of generators into generators.
   */
  function join<T>(generator: QCGenerator<QCGenerator<T>>) : QCGenerator<T>;
}

declare module jasmine {
  interface Matchers {
    forAll(...generators : QCGenerator<any>[]) : boolean;
  }
}

interface QUnitAssert {
  forAll(prop: (...values: any[]) => QCAssertionResult, ...generators : QCGenerator<any>[]) : any;
}
