package thx.promise;

import thx.Nil;
import thx.Functions.identity;
import thx.fp.Functions.const;
import thx.promise.Promise;
using thx.Functions;

/**
 * The ReaderT monad transformer specialized to Promise.
 */
abstract PromiseR<R, A>(R -> Promise<A>) from R -> Promise<A> {
  public static function pure<R, A>(a: A): PromiseR<R, A> {
    return function(_: R) return Promise.value(a);
  }

  public static function error<R, A>(err : Error) : PromiseR<R, A> {
    return function(_: R) return Promise.error(err);
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

  @:op(P1 >> P2)
  public function then<B>(p: PromiseR<R, B>): PromiseR<R, B> {
    return flatMap(const(p));
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

  public function recover(f: Error -> PromiseR<R, A>): PromiseR<R, A> {
    return function(r: R) return run(r).recover(
      function(err: Error) return f(err).run(r)
    );
  }

  public function contramap<R0>(f: R0 -> R): PromiseR<R0, A> {
    return this.compose(f);
  }

  public function local<R0>(f: R -> R0, p: PromiseR<R0, A>): PromiseR<R, A> {
    return function(r: R) return p.run(f(r));
  }

  public function nil(): PromiseR<R, Nil> {
    return function(r: R) return Promise.value(Nil.nil);
  }
}
