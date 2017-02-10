package thx.promise;

class Deferred<T> {
  public var promise(default, null): Promise<T>;
  var _resolve: T -> Void;
  var _reject: thx.Error -> Void;

  public function new() {
    promise = Promise.create(function (resolve, reject) {
      _resolve = resolve;
      _reject = reject;
    });
  }

  public function resolve(val: T) {
    _resolve(val);
  }

  public function reject(err: thx.Error) {
    _reject(err);
  }
}
