package thx.promise;

import thx.Either;
import thx.Functions.identity;
import thx.Nil;
import thx.fp.Functions.const;
import thx.promise.Promise;
using thx.Eithers;
using thx.Functions;

/**
 * The ReaderT monad transformer specialized to Promise,
 * with the capability to capture custom errors.
 */
abstract PromiseRF<R, E, A>(PromiseR<R, Either<E, A>>) from R -> Promise<Either<E, A>> {
  public static function pure<R, E, A>(a: A): PromiseRF<R, E, A> {
    return PromiseR.pure(Right(a)).run;
  }

  public static function fail<R, E, A>(e: E): PromiseRF<R, E, A> {
    return PromiseR.pure(Left(e)).run;
  }

  public static function die<R, E, A>(err : Error) : PromiseRF<R, E, A> {
    return PromiseR.error(err).run;
  }

  public static function ask<R, E>(): PromiseRF<R, E, R> {
    return function(x: R) return Promise.value(Right(x));
  }

  public inline function run(r: R): Promise<Either<E, A>> {
    return this.run(r);
  }

  public function map<B>(f: A -> B): PromiseRF<R, E, B> {
    return flatMap(pure.compose(f));
  }

  public function ap<B>(r: PromiseRF<R, E, A -> B>): PromiseRF<R, E, B> {
    return flatMap(function(a: A) return r.map.fn(_(a)));
  }

  public function flatMap<B>(f: A -> PromiseRF<R, E, B>): PromiseRF<R, E, B> {
    return function(r: R) {
      return run(r).flatMap(
        function(ea: Either<E, A>) return switch ea {
          case Left(e):  Promise.value(Left(e));
          case Right(a): f(a).run(r);
        }
      );
    }
  }

  @:op(P1 >> P2)
  public function then<B>(p: PromiseRF<R, E, B>): PromiseRF<R, E, B> {
    return flatMap(const(p));
  }

  public function bindPromise<B>(f: A -> Promise<B>): PromiseRF<R, E, B> {
    return flatMap(
      function(a: A): PromiseRF<R, E, B> {
        return const(f(a).map(Right));
      }
    );
  }

  public function successR(effect: A -> Void): PromiseRF<R, E, A> {
    return function(r: R) return run(r).success.fn(_.each(effect));
  }

  public function failureR(effect: Error -> Void): PromiseRF<R, E, A> {
    return function(r: R) return run(r).failure(effect);
  }

  public function recover(f: Error -> PromiseRF<R, E, A>): PromiseRF<R, E, A> {
    return function(r: R) return run(r).recover(
      function(err: Error) return f(err).run(r)
    );
  }

  public function contramap<R0>(f: R0 -> R): PromiseRF<R0, E, A> {
    return this.run.compose(f);
  }

  public function local<R0>(f: R -> R0, p: PromiseRF<R0, E, A>): PromiseRF<R, E, A> {
    return function(r: R) return p.run(f(r));
  }

  public function nil(): PromiseRF<R, E, Nil> {
    return flatMap(const(PromiseRF.pure(Nil.nil)));
  }
}

