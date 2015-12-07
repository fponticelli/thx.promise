package thx.promise;

import haxe.ds.Option;
import thx.Error;
import thx.Tuple;
import thx.Nil;
using thx.Options;
using thx.Arrays;
import thx.Result;
import thx.Either;

typedef PromiseValue<T> = Result<T, Error>;

@:forward(hasValue, map, mapAsync, mapFuture, state, then)
abstract Promise<T>(Future<Result<T, Error>>) from Future<Result<T, Error>> to Future<Result<T, Error>> {
  @:from public static function futureToPromise<T>(future : Future<T>) : Promise<T>
    return future.map(function(v) return (Right(v) : PromiseValue<T>));

  public static var nil(default, null) : Promise<Nil> = Promise.value(Nil.nil);

  public static function sequence(arr : Array<Promise<Dynamic>>) : Promise<Nil>
    return Promise.create(function(resolve : Dynamic -> Void, reject) {
        arr = arr.copy();
        function poll(_ : Dynamic) {
          if(arr.isEmpty()) {
            resolve(nil);
          } else {
            arr.shift()
              .mapSuccess(poll)
              .mapFailure(reject);
          }
        }
        poll(null);
      });

  public static function afterAll(arr : Array<Promise<Dynamic>>) : Promise<Nil>
    return Promise.create(function(resolve, reject) {
      all(arr).either(
        function(_) resolve(Nil.nil),
        reject
      );
    });

  public static function all<T>(arr : Array<Promise<T>>) : Promise<Array<T>> {
    if(arr.length == 0)
      return Promise.value([]);
    return Promise.create(function(resolve, reject) {
      var results  = [],
          counter  = 0,
          hasError = false;
      arr.mapi(function(p, i) {
        p.either(function(value) {
          if(hasError) return;
          results[i] = value;
          counter++;
          if(counter == arr.length)
            resolve(results);
        }, function(err) {
          if(hasError) return;
          hasError = true;
          reject(err);
        });
      });
    });
  }

  public static function allSequence<T>(arr : Array<Promise<T>>) : Promise<Array<T>> {
    return Promise.create(function(resolve, reject) {
      var results = [],
          counter = 0;

      function poll() {
        if(counter == arr.length)
          return resolve(results);
        arr[counter++]
          .either(
            function(value) {
              results.push(value);
              poll();
            },
            function(err) {
              reject(err);
            }
          );
      }

      poll();
    });
  }

  public static function create<T>(callback : (T -> Void) -> (Error -> Void) -> Void) : Promise<T>
    return Future.create(function(cb : PromiseValue<T> -> Void) {
      callback(
        function(value : T) cb((Right(value) : Result<T, Error>)),
        // cast required by C#
        function(error : Error) cb((Left(error) : Result<T, Error>))
      );
    });

  public static function createFulfill<T>(callback : (PromiseValue<T> -> Void) -> Void) : Promise<T>
    return Future.create(callback);

  public static function fail<T>(message : String, ?pos : haxe.PosInfos) : Promise<T>
    return error(new thx.Error(message, pos));

  public static function error<T>(err : Error) : Promise<T>
    return Promise.create(function(_, reject) reject(err));

  public static function value<T>(v : T) : Promise<T>
    return Promise.create(function(resolve, _) resolve(v));

  public function always(handler : Void -> Void) : Promise<T>
    return this.then(function(_) handler());

  public function either(success : T -> Void, failure : Error -> Void) : Promise<T>
    return this.then(function(r) switch r {
      case Right(value): success(value);
      case Left(error): failure(error);
    });

#if (js || flash || java)
  public function delay(?delayms : Int) : Promise<T>
    return this.delay(delayms);
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

  inline public function mapAlways<TOut>(handler : Void -> TOut) : Future<TOut>
    return this.map(function(_) return handler());

  inline public function mapAlwaysAsync<TOut>(handler : (TOut -> Void) -> Void) : Future<TOut>
    return this.mapAsync(function(_, cb) return handler(cb));

  inline public function mapAlwaysFuture<TOut>(handler : Void -> Future<TOut>) : Future<TOut>
    return this.mapFuture(function(_) return handler());

  public function mapEither<TOut>(success : T -> TOut, failure : Error -> TOut) : Future<TOut>
    return this.map(function(result)
      return switch result {
        case Right(value): success(value);
        case Left(error):  failure(error);
      });

  public function mapEitherFuture<TOut>(success : T -> Future<TOut>, failure : Error -> Future<TOut>) : Future<TOut>
    return this.mapFuture(function(result)
      return switch result {
        case Right(value): success(value);
        case Left(error):  failure(error);
      });

  public function mapFailure(failure : Error -> T) : Future<T>
    return mapEither(function(value : T) return value, failure);

  public function mapFailureFuture(failure : Error -> Future<T>) : Future<T>
    return mapEitherFuture(function(value : T) return Future.value(value), failure);

  public function mapFailurePromise(failure : Error -> Promise<T>) : Promise<T>
    return mapEitherFuture(function(value) return Promise.value(value), failure);

  public function mapSuccess<TOut>(success : T -> TOut) : Promise<TOut>
    return mapEitherFuture(
      function(v)   return
        try Promise.value(success(v))
        catch(e : Dynamic) Promise.error(Error.fromDynamic(e)),
      function(err) return Promise.error(err));

  public function mapSuccessPromise<TOut>(success : T -> Promise<TOut>) : Promise<TOut>
    return mapEitherFuture(success, function(err) return Promise.error(err));

  public function mapNull(handler : Void -> Promise<Null<T>>) : Promise<T>
    return mapSuccessPromise(function(v : Null<T>) {
      if(null == v)
        return handler();
      else
        return Promise.value(v);
    });

  public function success(success : T -> Void) : Promise<T>
    return either(success, function(_){});

  public function throwFailure() : Promise<T>
    return failure(function(err) throw err);

  public function toString() return 'Promise';
}

class Promises {
  public static function join<T1,T2>(p1 : Promise<T1>, p2 : Promise<T2>) : Promise<Tuple2<T1,T2>> {
    return Promise.create(function(resolve, reject) {
      var hasError = false,
          counter = 0,
          v1 : Null<T1> = null,
          v2 : Null<T2> = null;

      function complete() {
        if(counter < 2)
          return;
        resolve(new Tuple2(v1, v2));
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

  public static function log<T>(promise : Promise<T>, ?prefix : String = '')
    return promise.either(
      function(r) trace('$prefix SUCCESS: $r'),
      function(e) trace('$prefix ERROR: ${e.toString()}')
    );
}

class PromiseTuple6 {
  public static function mapTuplePromise<T1,T2,T3,T4,T5,T6,TOut>(promise : Promise<Tuple6<T1,T2,T3,T4,T5,T6>>, success : T1 -> T2 -> T3 -> T4 -> T5 -> T6 -> Promise<TOut>) : Promise<TOut>
    return promise.mapSuccessPromise(function(t)
      return success(t._0, t._1, t._2, t._3, t._4, t._5)
    );

  public static function mapTuple<T1,T2,T3,T4,T5,T6,TOut>(promise : Promise<Tuple6<T1,T2,T3,T4,T5,T6>>, success : T1 -> T2 -> T3 -> T4 -> T5 -> T6 -> TOut) : Promise<TOut>
    return promise.mapSuccess(function(t)
      return success(t._0, t._1, t._2, t._3, t._4, t._5)
    );

  public static function tuple<T1,T2,T3,T4,T5,T6>(promise : Promise<Tuple6<T1,T2,T3,T4,T5,T6>>, success : T1 -> T2 -> T3 -> T4 -> T5 -> T6 -> Void, ?failure : Error -> Void)
    return promise.either(
      function(t) success(t._0, t._1, t._2, t._3, t._4, t._5),
      null == failure ? function(_) {} : failure
    );
}

class PromiseTuple5 {
  public static function join<T1,T2,T3,T4,T5,T6>(p1 : Promise<Tuple5<T1,T2,T3,T4,T5>>, p2 : Promise<T6>) : Promise<Tuple6<T1,T2,T3,T4,T5,T6>> {
    return Promise.create(function(resolve, reject) {
      Promises.join(p1, p2)
        .either(
          function(t) resolve(t._0.with(t._1)),
          function(e) reject(e));
    });
  }

  public static function mapTuplePromise<T1,T2,T3,T4,T5,TOut>(promise : Promise<Tuple5<T1,T2,T3,T4,T5>>, success : T1 -> T2 -> T3 -> T4 -> T5 -> Promise<TOut>) : Promise<TOut>
    return promise.mapSuccessPromise(function(t)
      return success(t._0, t._1, t._2, t._3, t._4)
    );

  public static function mapTuple<T1,T2,T3,T4,T5,TOut>(promise : Promise<Tuple5<T1,T2,T3,T4,T5>>, success : T1 -> T2 -> T3 -> T4 -> T5 -> TOut) : Promise<TOut>
    return promise.mapSuccess(function(t)
      return success(t._0, t._1, t._2, t._3, t._4)
    );

  public static function tuple<T1,T2,T3,T4,T5>(promise : Promise<Tuple5<T1,T2,T3,T4,T5>>, success : T1 -> T2 -> T3 -> T4 -> T5 -> Void, ?failure : Error -> Void)
    return promise.either(
      function(t) success(t._0, t._1, t._2, t._3, t._4),
      null == failure ? function(_) {} : failure
    );
}

class PromiseTuple4 {
  public static function join<T1,T2,T3,T4,T5>(p1 : Promise<Tuple4<T1,T2,T3,T4>>, p2 : Promise<T5>) : Promise<Tuple5<T1,T2,T3,T4,T5>> {
    return Promise.create(function(resolve, reject) {
      Promises.join(p1, p2)
        .either(
          function(t) resolve(t._0.with(t._1)),
          function(e) reject(e));
    });
  }

  public static function mapTuplePromise<T1,T2,T3,T4,TOut>(promise : Promise<Tuple4<T1,T2,T3,T4>>, success : T1 -> T2 -> T3 -> T4 -> Promise<TOut>) : Promise<TOut>
    return promise.mapSuccessPromise(function(t)
      return success(t._0, t._1, t._2, t._3)
    );

  public static function mapTuple<T1,T2,T3,T4,TOut>(promise : Promise<Tuple4<T1,T2,T3,T4>>, success : T1 -> T2 -> T3 -> T4 -> TOut) : Promise<TOut>
    return promise.mapSuccess(function(t)
      return success(t._0, t._1, t._2, t._3)
    );

  public static function tuple<T1,T2,T3,T4>(promise : Promise<Tuple4<T1,T2,T3,T4>>, success : T1 -> T2 -> T3 -> T4 -> Void, ?failure : Error -> Void)
    return promise.either(
      function(t) success(t._0, t._1, t._2, t._3),
      null == failure ? function(_) {} : failure
    );
}

class PromiseTuple3 {
  public static function join<T1,T2,T3,T4>(p1 : Promise<Tuple3<T1,T2,T3>>, p2 : Promise<T4>) : Promise<Tuple4<T1,T2,T3,T4>> {
    return Promise.create(function(resolve, reject) {
      Promises.join(p1, p2)
        .either(
          function(t) resolve(t._0.with(t._1)),
          function(e) reject(e));
    });
  }

  public static function mapTuplePromise<T1,T2,T3,TOut>(promise : Promise<Tuple3<T1,T2,T3>>, success : T1 -> T2 -> T3 -> Promise<TOut>) : Promise<TOut>
    return promise.mapSuccessPromise(function(t)
      return success(t._0, t._1, t._2)
    );

  public static function mapTuple<T1,T2,T3,TOut>(promise : Promise<Tuple3<T1,T2,T3>>, success : T1 -> T2 -> T3 -> TOut) : Promise<TOut>
    return promise.mapSuccess(function(t)
      return success(t._0, t._1, t._2)
    );

  public static function tuple<T1,T2,T3>(promise : Promise<Tuple3<T1,T2,T3>>, success : T1 -> T2 -> T3 -> Void, ?failure : Error -> Void)
    return promise.either(
      function(t) success(t._0, t._1, t._2),
      null == failure ? function(_) {} : failure
    );
}

class PromiseTuple2 {
  public static function join<T1,T2,T3>(p1 : Promise<Tuple2<T1,T2>>, p2 : Promise<T3>) : Promise<Tuple3<T1,T2,T3>> {
    return Promise.create(function(resolve, reject) {
      Promises.join(p1, p2)
        .either(
          function(t) resolve(t._0.with(t._1)),
          function(e) reject(e));
    });
  }

  public static function mapTuplePromise<T1,T2,TOut>(promise : Promise<Tuple2<T1,T2>>, success : T1 -> T2 -> Promise<TOut>) : Promise<TOut>
    return promise.mapSuccessPromise(function(t)
      return success(t._0, t._1)
    );

  public static function mapTuple<T1,T2,TOut>(promise : Promise<Tuple2<T1,T2>>, success : T1 -> T2 -> TOut) : Promise<TOut>
    return promise.mapSuccess(function(t)
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
    return Promise.create(function(resolve, reject) {
      Promises.join(p1, p2)
        .either(
          function(t) resolve(t._1),
          function(e) reject(e));
    });

  public static function nil(p : Promise<Dynamic>) : Promise<Nil>
    return Promise.create(function(resolve : Nil -> Void, reject)
      p.success(function(_) resolve(Nil.nil))
       .failure(reject));
}

#if js
class PromiseAPlus {
  public static function promise<T>(p : js.Promise<T>) : Promise<T>
    return Promise.create(function(resolve, reject) {
      p.then(resolve, function(e) reject(Error.fromDynamic(e)));
    });

  public static function aPlus<T>(p : Promise<T>) : js.Promise<T>
    return new js.Promise(function(resolve, reject) {
        p.success(resolve).failure(reject);
      });
}

class PromiseAPlusVoid {
  public static function promise(p : js.Promise<Void>) : Promise<Nil>
    return Promise.create(function(resolve, reject) {
      p.then(cast function() resolve(nil), function(e) reject(Error.fromDynamic(e)));
    });

  public static function aPlus(p : Promise<Void>) : js.Promise<Nil>
    return new js.Promise(function(resolve, reject) {
        p.success(cast function() resolve(nil)).failure(reject);
      });
}
#end
