package thx.promise;

import haxe.ds.Option;

import thx.Either;
import thx.Error;
import thx.Nil;
import thx.Result;
import thx.Tuple;
import thx.fp.Functions.const;

using thx.Arrays;
using thx.Functions;
using thx.Options;

typedef PromiseValue<T> = Result<T, Error>;

@:forward(hasValue, mapAsync, state, then)
abstract Promise<T>(Future<Result<T, Error>>) to Future<Result<T, Error>> {
  inline private function new(future: Future<Result<T, Error>>)
    this = future;

  public static function fromFuture<T>(future : Future<T>) : Promise<T>
    return new Promise(future.map(function(v) return (Right(v) : PromiseValue<T>)));

  public static var nil(default, null) : Promise<Nil> = Promise.value(Nil.nil);

  @:deprecated("Use Promise.sequence instead; since Promise construction is eager there is no difference between the two.")
  public static function all<T>(arr : Array<Promise<T>>) : Promise<Array<T>> {
    return if (arr.length == 0) Promise.value([])
    else Promise.create(
      function(resolve, reject) {
        var results  = [],
            counter  = 0,
            hasError = false;

        // For each element of the array, mutate the results completion. When
        // all results have been included, or an error is encountered, resolve
        // the resulting promise.
        for (i in 0...arr.length) {
          arr[i].either(
            function(v) {
              if (!hasError) {
                results[i] = v;
                counter++;

                if(counter == arr.length) resolve(results);
              }
            },
            function(err) {
              if (!hasError) {
                hasError = true;
                reject(err);
              }
            }
          );
        }
      }
    );
  }

  public static function afterAll(arr : Array<Promise<Dynamic>>) : Promise<Nil>
    return sequence(arr).map(const(Nil.nil));

  public static function sequence<T>(arr : Array<Promise<T>>) : Promise<Array<T>> {
    return arr.reduce(
      function(acc: Promise<Array<T>>, p: Promise<T>) return acc.flatMap(
        function(arr: Array<T>) return p.map(function(t) return arr.concat([t]))
      ),
      Promise.value([])
    );
  }

  @:deprecated("Use Promise.sequence instead.")
  public static function allSequence<T>(arr : Array<Promise<T>>) : Promise<Array<T>>
    return sequence(arr);

  public static function create<T>(callback : (T -> Void) -> (Error -> Void) -> Void) : Promise<T>
    return new Promise(
      Future.create(function(cb : PromiseValue<T> -> Void) {
        try {
          callback(
            function(v : T)     cb((Right(v) : PromiseValue<T>)),
            function(e : Error) cb((Left(e) : PromiseValue<T>))
          );
        } catch(e : Dynamic) {
          cb((Left(Error.fromDynamic(e)) : PromiseValue<T>));
        }
      })
    );

  public static function createUnsafe<T>(callback : (T -> Void) -> (Error -> Void) -> Void) : Promise<T>
    return new Promise(
      Future.create(function(cb : PromiseValue<T> -> Void) {
        callback(
          function(v : T)     cb((Right(v) : PromiseValue<T>)),
          function(e : Error) cb((Left(e) : PromiseValue<T>))
        );
      })
    );

  public static function createFulfill<T>(callback : (PromiseValue<T> -> Void) -> Void) : Promise<T>
    return new Promise(Future.create(function(cb) {
      try callback(cb) catch(e : Dynamic) cb(Left(Error.fromDynamic(e)));
    }));

  public static function fail<T>(message : String, ?pos : haxe.PosInfos) : Promise<T>
    return error(new thx.Error(message, pos));

  public static function error<T>(err : Error) : Promise<T>
    return Promise.create(function(_, reject) reject(err));

  public static function value<T>(v : T) : Promise<T>
    return Promise.create(function(resolve, _) resolve(v));

  public function always(handler : Void -> Void) : Promise<T>
    return new Promise(
      Future.create(function(cb : PromiseValue<T> -> Void) {
        this.then(function(v) {
          try {
            handler();
            cb(v);
          } catch(e : Dynamic) {
            cb(Left(Error.fromDynamic(e)));
          }
        });
      })
    );

  public function either(success : T -> Void, failure : Error -> Void) : Promise<T>
    return Promise.createUnsafe(function(resolve : T -> Void, reject : Error -> Void) {
      this.then(function(r) {
        try {
          switch r {
            case Right(v):
              success(v);
              resolve(v);
            case Left(e):
              failure(e);
              reject(e);
          }
        } catch(e : Dynamic) {
          reject(Error.fromDynamic(e));
        }
      });
    });

#if (js || flash)
  public function delay(?delayms : Int) : Promise<T>
    return new Promise(this.delay(delayms));
#end

  public function isFailure() : Bool
    return switch this.state {
      case None, Some(Right(_)): false;
      case _: true;
    };

  public function isResolved() : Bool
    return switch this.state {
      case None, Some(Left(_)): false;
      case _: true;
    };

  public function failure(failure : Error -> Void) : Promise<T>
    return either(function(_){}, failure);

  inline public function mapAlways<TOut>(handler : Void -> TOut) : Promise<TOut>
    return map(function(_) return handler());

  inline public function mapAlwaysAsyncFuture<TOut>(handler : (TOut -> Void) -> Void) : Future<TOut>
    return this.mapAsync(function(_, cb) return handler(cb));

  inline public function mapAlwaysFuture<TOut>(handler : Void -> Future<TOut>) : Future<TOut>
    return this.flatMap(function(_) return handler());

  public function mapEither<TOut>(success : T -> TOut, failure : Error -> TOut) : Promise<TOut>
    return flatMapEither(
      function(v) return Promise.value(success(v)),
      function(e) return Promise.value(failure(e))
    );

  public function mapEitherFuture<TOut>(success : T -> TOut, failure : Error -> TOut) : Future<TOut>
    return flatMapEitherFuture(
      function(v) return Future.value(success(v)),
      function(e) return Future.value(failure(e))
    );

  public function flatMapEitherFuture<TOut>(success : T -> Future<TOut>, failure : Error -> Future<TOut>) : Future<TOut>
    return this.flatMap(function(result : Result<T, Error>)
      return switch result {
        case Right(v): success(v);
        case Left(e):  failure(e);
      });

  public function flatMapEither<TOut>(success : T -> Promise<TOut>, failure : Error -> Promise<TOut>) : Promise<TOut> {
    return Promise.createUnsafe(function(resolve : TOut -> Void, reject : Error -> Void) {
      this.then(function(result : Result<T, Error>) : Void {
        switch result {
          case Right(v): try success(v).either(resolve, reject) catch(e : Dynamic) reject(Error.fromDynamic(e));
          case Left(e):  try failure(e).either(resolve, reject) catch(e : Dynamic) reject(Error.fromDynamic(e));
        }
      });
    });
  }

  @:deprecated("Promise.mapFailure is deprecated, use Promise.recoverAsFuture instead")
  public function mapFailure(failure : Error -> T) : Future<T>
    return mapEitherFuture(function(v : T) return v, failure);

  @:deprecated("Promise.mapFailureFuture is deprecated, use Promise.recover instead")
  public function mapFailureFuture(failure : Error -> Future<T>) : Future<T>
    return flatMapEitherFuture(function(v : T) return Future.value(v), failure);

  @:deprecated("Promise.mapFailurePromise is deprecated, use Promise.recover instead")
  public function mapFailurePromise(failure : Error -> Promise<T>) : Promise<T>
    return recover(failure);

  public function recover(failure : Error -> Promise<T>) : Promise<T>
    return flatMapEither(function(v) return Promise.value(v), failure);

  public function recoverAsFuture(failure : Error -> T) : Future<T>
    return mapEitherFuture(function(v : T) return v, failure);

  public function map<U>(success : T -> U) : Promise<U>
    return flatMap(function(v) return Promise.value(success(v)));

  public function ap<U>(pf: Promise<T -> U>): Promise<U>
    return flatMap(function(t) return pf.map.fn(_(t)));

  @:deprecated("mapSuccess is deprecated. Use map instead")
  inline public function mapSuccess<TOut>(success : T -> TOut) : Promise<TOut>
    return map(success);

  inline public function flatMap<TOut>(success : T -> Promise<TOut>) : Promise<TOut>
    return flatMapEither(success, function(err) return Promise.error(err));

  inline public function append<TOut>(success : Void -> Promise<TOut>) : Promise<TOut>
    return flatMap(function(_) return success());

  @:op(A >> B)
  inline public function andThen<B>(next: Void -> Promise<B>): Promise<B>
    return flatMap(function(_) return next());

  /**
   * Performs an additional effect with the result of this promise, and
   * when it completes ignore the resulting value and instead return
   * the result of this promise. This is similar to success(...)
   * except that the additional side effect expressed in the result of `f`
   * must complete before computation can proceed.
   */
  inline public function foreachM<U>(f: T -> Promise<U>): Promise<T>
    return flatMap(function(t) return f(t).map(const(t)));

  @:deprecated("Promise.mapSuccessPromise is deprecated. Use Promise.flatMap instead")
  public function mapSuccessPromise<TOut>(success : T -> Promise<TOut>) : Promise<TOut>
    return flatMap(success);

  @:deprecated("Promise.mapNull is deprecated. Use Promise.recoverNull instead")
  public function mapNull(handler : Void -> Promise<Null<T>>) : Promise<T>
    return recoverNull(handler);

  public function recoverNull(handler : Void -> Promise<Null<T>>) : Promise<T>
    return flatMap(function(v : Null<T>) {
      if(null == v)
        return handler();
      else
        return Promise.value(v);
    });

  public function success(success : T -> Void) : Promise<T>
    return either(success, function(_){});

  public function throwFailure() : Promise<T>
    return new Promise(this.then(function(r) switch r {
      case Left(err): throw err;
      case _: // do nothing
    }));

  public function toString() return 'Promise';

  inline public function toFuture() : Future<PromiseValue<T>> return this;
}

class Promises {
  public static function par<T1,T2,T3>(f: T1 -> T2 -> T3, p1 : Promise<T1>, p2 : Promise<T2>) : Promise<T3> {
    return Promise.create(function(resolve, reject) {
      var hasError = false,
          counter = 0,
          v1 : Null<T1> = null,
          v2 : Null<T2> = null;

      function complete() {
        if(counter < 2)
          return;
        resolve(f(v1, v2));
      }

      function handleError(error) {
        if(hasError) return;
        hasError = true;
        reject(error);
      }

      p1.either(function(v) {
        if(hasError) return;
        counter++;
        v1 = v;
        complete();
      }, handleError);

      p2.either(function(v) {
        if(hasError) return;
        counter++;
        v2 = v;
        complete();
      }, handleError);
    });
  }

  public static function par3<T1, T2, T3, T4>(f: T1 -> T2 -> T3 -> T4, p1 : Promise<T1>, p2 : Promise<T2>, p3 : Promise<T3>) : Promise<T4>
    return par(function(f, g) return f(g), par(f.curry(), p1, p2), p3);

  public static function par4<T1, T2, T3, T4, T5>(f: T1 -> T2 -> T3 -> T4 -> T5, p1 : Promise<T1>, p2 : Promise<T2>, p3 : Promise<T3>, p4 : Promise<T4>) : Promise<T5>
    return par(function(f, g) return f(g), par3(f.curry(), p1, p2, p3), p4);

  public static function par5<T1, T2, T3, T4, T5, T6>(f: T1 -> T2 -> T3 -> T4 -> T5 -> T6, p1 : Promise<T1>, p2 : Promise<T2>, p3 : Promise<T3>, p4 : Promise<T4>, p5: Promise<T5>):Promise<T6>
    return par(function(f, g) return f(g), par4(f.curry(), p1, p2, p3, p4), p5);

  public static function par6<T1, T2, T3, T4, T5, T6, T7>(f: T1 -> T2 -> T3 -> T4 -> T5 -> T6 -> T7, p1 : Promise<T1>, p2 : Promise<T2>, p3 : Promise<T3>, p4 : Promise<T4>, p5: Promise<T5>, p6: Promise<T6>): Promise<T7>
    return par(function(f, g) return f(g), par5(f.curry(), p1, p2, p3, p4, p5), p6);

  inline public static function join<T1,T2>(p1 : Promise<T1>, p2 : Promise<T2>) : Promise<Tuple2<T1,T2>>
    return par(Tuple.of, p1, p2);

  // alias for join
  inline public static function join2<T1,T2>(p1 : Promise<T1>, p2 : Promise<T2>) : Promise<Tuple2<T1,T2>>
    return join(p1, p2);

  public static function join3<T1, T2, T3>(p1 : Promise<T1>, p2 : Promise<T2>, p3 : Promise<T3>) : Promise<Tuple3<T1, T2, T3>>
    return par3(Tuple3.of, p1, p2, p3);

  public static function join4<T1, T2, T3, T4>(p1 : Promise<T1>, p2 : Promise<T2>, p3 : Promise<T3>, p4 : Promise<T4>) : Promise<Tuple4<T1, T2, T3, T4>>
    return par4(Tuple4.of, p1, p2, p3, p4);

  public static function join5<T1, T2, T3, T4, T5>(p1 : Promise<T1>, p2 : Promise<T2>, p3 : Promise<T3>, p4 : Promise<T4>, p5 : Promise<T5>) : Promise<Tuple5<T1, T2, T3, T4, T5>>
    return par5(Tuple5.of, p1, p2, p3, p4, p5);

  public static function join6<T1, T2, T3, T4, T5, T6>(p1 : Promise<T1>, p2 : Promise<T2>, p3 : Promise<T3>, p4 : Promise<T4>, p5 : Promise<T5>, p6 : Promise<T6>) : Promise<Tuple6<T1, T2, T3, T4, T5, T6>>
    return par6(Tuple6.of, p1, p2, p3, p4, p5, p6);

  public static function log<T>(promise : Promise<T>, ?prefix : String = '')
    return promise.either(
      function(r) trace('$prefix SUCCESS: $r'),
      function(e) trace('$prefix ERROR: ${e.toString()}')
    );
}

class PromiseTuple6 {
  public static function mapTuplePromise<T1,T2,T3,T4,T5,T6,TOut>(promise : Promise<Tuple6<T1,T2,T3,T4,T5,T6>>, success : T1 -> T2 -> T3 -> T4 -> T5 -> T6 -> Promise<TOut>) : Promise<TOut>
    return promise.flatMap(function(t)
      return success(t._0, t._1, t._2, t._3, t._4, t._5)
    );

  public static function mapTuple<T1,T2,T3,T4,T5,T6,TOut>(promise : Promise<Tuple6<T1,T2,T3,T4,T5,T6>>, success : T1 -> T2 -> T3 -> T4 -> T5 -> T6 -> TOut) : Promise<TOut>
    return promise.map(function(t)
      return success(t._0, t._1, t._2, t._3, t._4, t._5)
    );

  public static function tuple<T1,T2,T3,T4,T5,T6>(promise : Promise<Tuple6<T1,T2,T3,T4,T5,T6>>, success : T1 -> T2 -> T3 -> T4 -> T5 -> T6 -> Void, ?failure : Error -> Void)
    return promise.either(
      function(t) success(t._0, t._1, t._2, t._3, t._4, t._5),
      null == failure ? function(_) {} : failure
    );
}

class PromiseTuple5 {
  public static function join<T1,T2,T3,T4,T5,T6>(p1 : Promise<Tuple5<T1,T2,T3,T4,T5>>, p2 : Promise<T6>) : Promise<Tuple6<T1,T2,T3,T4,T5,T6>>
    return Promises.par(function(f: Tuple5<T1,T2,T3,T4,T5>, g: T6) return f.with(g), p1, p2);

  public static function mapTuplePromise<T1,T2,T3,T4,T5,TOut>(promise : Promise<Tuple5<T1,T2,T3,T4,T5>>, success : T1 -> T2 -> T3 -> T4 -> T5 -> Promise<TOut>) : Promise<TOut>
    return promise.flatMap(function(t)
      return success(t._0, t._1, t._2, t._3, t._4)
    );

  public static function mapTuple<T1,T2,T3,T4,T5,TOut>(promise : Promise<Tuple5<T1,T2,T3,T4,T5>>, success : T1 -> T2 -> T3 -> T4 -> T5 -> TOut) : Promise<TOut>
    return promise.map(function(t)
      return success(t._0, t._1, t._2, t._3, t._4)
    );

  public static function tuple<T1,T2,T3,T4,T5>(promise : Promise<Tuple5<T1,T2,T3,T4,T5>>, success : T1 -> T2 -> T3 -> T4 -> T5 -> Void, ?failure : Error -> Void)
    return promise.either(
      function(t) success(t._0, t._1, t._2, t._3, t._4),
      null == failure ? function(_) {} : failure
    );
}

class PromiseTuple4 {
  public static function join<T1,T2,T3,T4,T5>(p1 : Promise<Tuple4<T1,T2,T3,T4>>, p2 : Promise<T5>) : Promise<Tuple5<T1,T2,T3,T4,T5>>
    return Promises.par(function(f: Tuple4<T1,T2,T3,T4>, g: T5) return f.with(g), p1, p2);

  public static function mapTuplePromise<T1,T2,T3,T4,TOut>(promise : Promise<Tuple4<T1,T2,T3,T4>>, success : T1 -> T2 -> T3 -> T4 -> Promise<TOut>) : Promise<TOut>
    return promise.flatMap(function(t)
      return success(t._0, t._1, t._2, t._3)
    );

  public static function mapTuple<T1,T2,T3,T4,TOut>(promise : Promise<Tuple4<T1,T2,T3,T4>>, success : T1 -> T2 -> T3 -> T4 -> TOut) : Promise<TOut>
    return promise.map(function(t)
      return success(t._0, t._1, t._2, t._3)
    );

  public static function tuple<T1,T2,T3,T4>(promise : Promise<Tuple4<T1,T2,T3,T4>>, success : T1 -> T2 -> T3 -> T4 -> Void, ?failure : Error -> Void)
    return promise.either(
      function(t) success(t._0, t._1, t._2, t._3),
      null == failure ? function(_) {} : failure
    );
}

class PromiseTuple3 {
  public static function join<T1,T2,T3,T4>(p1 : Promise<Tuple3<T1,T2,T3>>, p2 : Promise<T4>) : Promise<Tuple4<T1,T2,T3,T4>>
    return Promises.par(function(f: Tuple3<T1, T2, T3>, g: T4) return f.with(g), p1, p2);

  public static function mapTuplePromise<T1,T2,T3,TOut>(promise : Promise<Tuple3<T1,T2,T3>>, success : T1 -> T2 -> T3 -> Promise<TOut>) : Promise<TOut>
    return promise.flatMap(function(t)
      return success(t._0, t._1, t._2)
    );

  public static function mapTuple<T1,T2,T3,TOut>(promise : Promise<Tuple3<T1,T2,T3>>, success : T1 -> T2 -> T3 -> TOut) : Promise<TOut>
    return promise.map(function(t)
      return success(t._0, t._1, t._2)
    );

  public static function tuple<T1,T2,T3>(promise : Promise<Tuple3<T1,T2,T3>>, success : T1 -> T2 -> T3 -> Void, ?failure : Error -> Void)
    return promise.either(
      function(t) success(t._0, t._1, t._2),
      null == failure ? function(_) {} : failure
    );
}

class PromiseTuple2 {
  public static function join<T1,T2,T3>(p1 : Promise<Tuple2<T1,T2>>, p2 : Promise<T3>) : Promise<Tuple3<T1,T2,T3>>
    return Promises.par(function(f: Tuple2<T1, T2>, g: T3) return f.with(g), p1, p2);

  public static function mapTuplePromise<T1,T2,TOut>(promise : Promise<Tuple2<T1,T2>>, success : T1 -> T2 -> Promise<TOut>) : Promise<TOut>
    return promise.flatMap(function(t)
      return success(t._0, t._1)
    );

  public static function mapTuple<T1,T2,TOut>(promise : Promise<Tuple2<T1,T2>>, success : T1 -> T2 -> TOut) : Promise<TOut>
    return promise.map(function(t)
      return success(t._0, t._1)
    );

  public static function tuple<T1,T2>(promise : Promise<Tuple2<T1,T2>>, success : T1 -> T2 -> Void, ?failure : Error -> Void)
    return promise.either(
      function(t) success(t._0, t._1),
      null == failure ? function(_) {} : failure
    );
}

class PromiseNil {
  public static function join<T2>(p1 : Promise<Nil>, p2 : Promise<T2>) : Promise<T2>
    return Promises.par(function(_, g) return g, p1, p2);

  public static function nil<A>(p : Promise<A>) : Promise<Nil>
    return p.map(const(Nil.nil));
}

#if js
class PromiseAPlus {
  public static function promise<T>(p : js.Promise<T>, ?pos : haxe.PosInfos) : Promise<T>
    return Promise.create(function(resolve, reject) {
      p.then(resolve, function(e) reject(Error.fromDynamic(e, pos)));
    });

  public static function aPlus<T>(p : Promise<T>) : js.Promise<T>
    return new js.Promise(function(resolve, reject) {
        p.success(resolve).failure(reject);
      });
}

class PromiseAPlusVoid {
  public static function promise(p : js.Promise<Void>, ?pos : haxe.PosInfos) : Promise<Nil>
    return Promise.create(function(resolve, reject) {
      p.then(cast function() resolve(nil), function(e) reject(Error.fromDynamic(e, pos)));
    });

  public static function aPlus(p : Promise<Void>) : js.Promise<Nil>
    return new js.Promise(function(resolve, reject) {
        p.success(cast function() resolve(nil)).failure(reject);
      });
}
#end
