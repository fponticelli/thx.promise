#if js
abstract Promise<T>(thx.promise.aplus.PromiseA<T>) from thx.promise.aplus.PromiseA<T> {
  @:to inline public function toPromise() : thx.promise.Promise<T> {
    return thx.promise.Promise.create(function(resolve, reject) {
      untyped this.then(resolve, reject);
    });
  }
}
#end