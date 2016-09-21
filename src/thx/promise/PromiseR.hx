package thx.promise;

import thx.promise.Promise;
import thx.Functions.identity;
using thx.Functions;

/**
 * The ReaderT monad transformer specialized to Promise.
 */
abstract PromiseR<R, A>(R -> Promise<A>) from R -> Promise<A> {
  public static function pure<R, A>(a: A): PromiseR<R, A> {
    return function(_: R) return Promise.value(a);
  }

  public static function ask<R>(): PromiseR<R, R> {
    return function(x: R) return Promise.value(x);
  }

  public inline function run(r: R): Promise<A> {
    return this(r);
  }

  public function map<B>(f: A -> B): PromiseR<R, B> {
    return flatMap(pure.compose(f));
  }

  public function ap<B>(r: PromiseR<R, A -> B>): PromiseR<R, B> {
    return flatMap(function(a: A) return r.map.fn(_(a)));
  }

  public function flatMap<B>(f: A -> PromiseR<R, B>): PromiseR<R, B> {
    return function(r: R) {
      return run(r).flatMap(function(a: A) return f(a).run(r));
    }
  }

  public function bindPromise<B>(f: A -> Promise<B>): PromiseR<R, B> {
    return flatMap(
      function(a: A) {
        return ((function(r: R) return f(a)) : PromiseR<R, B>);
      }
    );
  }

  public function parWith<B, C>(that: PromiseR<R, B>, f: A -> B -> C): PromiseR<R, C> {
    return function(r: R) return Promises.par(f, run(r), that.run(r));
  }

  public function success(effect: A -> Void): PromiseR<R, A> {
    return function(r: R) return run(r).success(effect);
  }

  public function failure(effect: Error -> Void): PromiseR<R, A> {
    return function(r: R) return run(r).failure(effect);
  }
}
