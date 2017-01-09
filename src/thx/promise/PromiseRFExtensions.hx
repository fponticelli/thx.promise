package thx.promise;

import thx.Either;
import thx.Functions.identity;
import thx.Semigroup;
import thx.Validation;
import thx.Validation.*;
using thx.Eithers;
using thx.Functions;
using thx.Arrays;

import thx.promise.Promise;
using thx.promise.PromiseExtensions;

class PromiseRFExtensions {
  public static inline function liftRF<R, E, A>(p: Promise<A>): PromiseRF<R, E, A> {
    return (function(r: R) return p.map(Right));
  }

  public static function zipWith<R, E, A, B, C>(pa: PromiseRF<R, E, A>, pb: PromiseRF<R, E, B>, f: A -> B -> C, s: Semigroup<E>): PromiseRF<R, E, C> {
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
}

class PromiseRFArrayExtensions {
  public static function traverse<R, E, A, B>(arr : ReadonlyArray<A>, f: A -> PromiseRF<R, E, B>): PromiseRF<R, E, Array<B>> {
    return PromiseRF.ask().flatMap(
      function(r: R): PromiseRF<R, E, Array<B>> {
        return function(r: R): Promise<Either<E, Array<B>>> {
          var promiseEithers: Promise<Array<Either<E, B>>> = arr.traverse(function(a: A) return f(a).run(r));
          return promiseEithers.map(
            function(xs: Array<Either<E, B>>): Either<E, Array<B>> return xs.traverseEither(identity)
          );
        }
      }
    );
  }
}
