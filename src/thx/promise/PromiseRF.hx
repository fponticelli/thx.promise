package thx.promise;

import thx.Either;
import thx.Functions.identity;
import thx.Nil;
import thx.Semigroup;
import thx.Validation.*;
import thx.fp.Functions.const;
import thx.promise.Promise;
using thx.Eithers;
using thx.Functions;

/**
 * The ReaderT monad transformer specialized to Promise,
 * with the capability to capture custom errors.
 */
abstract PromiseRF<R, E, A>(PromiseR<R, Either<E, A>>) from PromiseR<R, Either<E, A>> {
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
    return PromiseR.ask().map(Right);
  }

  public static function value<E, A>(e: Either<E, A>) {
    return PromiseR.pure(e);
  }

  @:from
  public function new(f: R -> Promise<Either<E, A>>) {
    this = f;
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

  public function mapError<E0>(f: E -> E0): PromiseRF<R, E0, A> {
    return this.map(
      function(ea: Either<E, A>) return switch ea {
        case Left(e): Left(f(e));
        case Right(a): Right(a);
      }
    );
  }

  public function flatMapError<E0>(f: E -> PromiseRF<R, E0, A>) {
    return function(r: R) {
      return run(r).flatMap(
        function(ea: Either<E, A>) return switch ea {
          case Left(e):  f(e).run(r);
          case Right(a): Promise.value(Right(a));
        }
      );
    }
  }

  public function contramap<R0>(f: R0 -> R): PromiseRF<R0, E, A> {
    return this.run.compose(f);
  }

  public function local<R0>(f: R -> R0, p: PromiseRF<R0, E, A>): PromiseRF<R, E, A> {
    return function(r: R) return p.run(f(r));
  }

  public function nil(): PromiseRF<R, E, Nil> {
    return map(const(Nil.nil));
  }

  /**
   * Applicative composition with fail-on-first-error semantics
   */
  public static function liftA2<R, E, A, B, C>(f: A -> B -> C, pa: PromiseRF<R, E, A>, pb: PromiseRF<R, E, B>): PromiseRF<R, E, C> {
    return pa.map(f.curry()).flatMap(pb.map);
  }

  /**
   * Applicative composition with accumulate-errors semantics
   */
  public static function par2<R, E, A, B, C>(f: A -> B -> C, pa: PromiseRF<R, E, A>, pb: PromiseRF<R, E, B>, s: Semigroup<E>): PromiseRF<R, E, C> {
    return function(r: R) {
      return Promises.par(
        function(ea: Either<E, A>, eb: Either<E, B>): Either<E, C> {
          return val2(f, ea.toValidation(), eb.toValidation(), s).either;
        },
        pa.run(r), 
        pb.run(r)
      );
    }
  }

  public static function par3<R, E, A, B, C, D>(
      f: A -> B -> C -> D, p1 : PromiseRF<R, E, A>, p2 : PromiseRF<R, E, B>, p3 : PromiseRF<R, E, C>, s: Semigroup<E>) : PromiseRF<R, E, D>
    return par2(function(f, g) return f(g), par2(f.curry(), p1, p2, s), p3, s);

  public static function par4<R, E, A, B, C, D, F>(
      f: A -> B -> C -> D -> F, p1 : PromiseRF<R, E, A>, p2 : PromiseRF<R, E, B>, p3 : PromiseRF<R, E, C>, 
      p4 : PromiseRF<R, E, D>, s: Semigroup<E>) : PromiseRF<R, E, F>
    return par2(function(f, g) return f(g), par3(f.curry(), p1, p2, p3, s), p4, s);

  public static function par5<R, E, A, B, C, D, F, G>(
      f: A -> B -> C -> D -> F -> G, p1 : PromiseRF<R, E, A>, p2 : PromiseRF<R, E, B>, p3 : PromiseRF<R, E, C>, 
      p4 : PromiseRF<R, E, D>, p5: PromiseRF<R, E, F>, s: Semigroup<E>):PromiseRF<R, E, G>
    return par2(function(f, g) return f(g), par4(f.curry(), p1, p2, p3, p4, s), p5, s);

  public static function par6<R, E, A, B, C, D, F, G, H>(
      f: A -> B -> C -> D -> F -> G -> H, p1 : PromiseRF<R, E, A>, p2 : PromiseRF<R, E, B>, p3 : PromiseRF<R, E, C>, 
      p4 : PromiseRF<R, E, D>, p5: PromiseRF<R, E, F>, p6: PromiseRF<R, E, G>, s: Semigroup<E>): PromiseRF<R, E, H>
    return par2(function(f, g) return f(g), par5(f.curry(), p1, p2, p3, p4, p5, s), p6, s);

  public static function par7<R, E, A, B, C, D, F, G, H, I>(
      f: A -> B -> C -> D -> F -> G -> H -> I, p1 : PromiseRF<R, E, A>, p2 : PromiseRF<R, E, B>, p3 : PromiseRF<R, E, C>, 
      p4 : PromiseRF<R, E, D>, p5: PromiseRF<R, E, F>, p6: PromiseRF<R, E, G>, p7: PromiseRF<R, E, H>, s: Semigroup<E>): PromiseRF<R, E, I>
    return par2(function(f, g) return f(g), par6(f.curry(), p1, p2, p3, p4, p5, p6, s), p7, s);
}

