/// <reference path="typings/tsd.d.ts" />
/// <reference path="../../dist/quick-check.d.ts" />

describe('quick_check examples', () => {
  it('should run tests with qc.forAll', () => {
    let {pass, message} = qc((x) => {
      return x + x === 2 * x;
    }, qc.natural);

    if (!pass) {
      throw new Error(message);
    }
  });
});
