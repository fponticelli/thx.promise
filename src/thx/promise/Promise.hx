package thx.promise;

import haxe.ds.Option;
import thx.core.Error;
import thx.core.Tuple;
import thx.core.Nil;
using thx.core.Options;
using thx.core.Arrays;

class Promise<T> {
  public static var nil(default, null) : Promise<Nil> = Promise.value(Nil.nil);

  public static function create<T>(callback : (T -> Void) -> (Error -> Void) -> Void) : Promise<T> {
    var deferred = new Deferred<T>();
    callback(deferred.resolve, deferred.reject);
    return deferred.promise;
  }

  public static function fulfilled<T>(callback : (PromiseValue<T> -> Void) -> Void) : Promise<T> {
    var deferred = new Deferred<T>();
    callback(deferred.fulfill);
    return deferred.promise;
  }

  public static function all<T>(arr : Array<Promise<T>>) : Promise<Array<T>>
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

  public static function value<T>(v : T) : Promise<T>
    return Promise.create(function(resolve, _) resolve(v));

  public static function error<T>(err : Error) : Promise<T>
    return Promise.create(function(_, reject) reject(err));

  var handlers : Array<PromiseValue<T> -> Void>;
  var state : Option<PromiseValue<T>>;
  private function new() {
    handlers = [];
    state = None;
  }

  public function then(handler : PromiseValue<T> -> Void) {
    handlers.push(handler);
    update();
    return this;
  }

  public function either(success : T -> Void, failure : Error -> Void) {
    then(function(r) switch r {
      case Success(value): success(value);
      case Failure(error): failure(error);
    });
    return this;
  }

  public function success(success : T -> Void)
    return either(success, function(_){});

  public function failure(failure : Error -> Void)
    return either(function(_){}, failure);

  public function throwFailure()
    return failure(function(err) {
      throw err;
    });

  public function map<TOut>(handler : PromiseValue<T> -> Promise<TOut>)
    return Promise.fulfilled(function(fulfill)
      then(function(result) handler(result).then(fulfill))
    );

  public function mapEither<TOut>(success : T -> Promise<TOut>, failure : Error -> Promise<TOut>)
    return map(function(result) return switch result {
        case Success(value): success(value);
        case Failure(error): failure(error);
      });

  public function mapSuccess<TOut>(success : T -> Promise<TOut>)
    return mapEither(success, function(err) return Promise.error(err));

  public function mapFailure(failure : Error -> Promise<T>)
    return mapEither(function(value : T) return Promise.value(value), failure);

  public function always(handler : Void -> Void)
    then(function(_) handler());

  public function mapAlways<TOut>(handler : Void -> Promise<TOut>)
    map(function(_) return handler());

  public function isResolved()
    return switch state {
      case None, Some(Failure(_)): false;
      case _: true;
    };

  public function isFailure()
    return switch state {
      case None, Some(Success(_)): false;
      case _: true;
    };

  public function isComplete()
    return switch state { case None: false; case Some(_): true; };

  public function toString() return 'Promise';

  function setState(newstate : PromiseValue<T>) {
    switch state {
      case None:
        state = Some(newstate);
      case Some(r):
        throw new Error('promise was already $r, can\'t apply new state $newstate');
    }
    update();
    return this;
  }

  function update()
    switch state {
      case None:
      case Some(result): {
        var handler;
        while(null != (handler = handlers.shift()))
          handler(result);
      }
    };
}

class Promises {
  public static function log<T>(promise : Promise<T>, ?prefix : String = '')
    return promise.either(
      function(r) trace('$prefix SUCCESS: $r'),
      function(e) trace('$prefix ERROR: ${e.toString()}')
    );

#if !macro
  public static function delay<T>(p : Promise<T>, ?interval : Int) : Promise<T>
    return p.map(
      function(r)
        return Promise.fulfilled(
          null == interval ?
            function(fulfill) thx.core.Timer.immediate(fulfill.bind(r)) :
            function(fulfill) thx.core.Timer.delay(fulfill.bind(r), interval)
        )
    );
#end
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
}

class PromiseTuple6 {
  public static function mapTuple<T1,T2,T3,T4,T5,T6,TOut>(promise : Promise<Tuple6<T1,T2,T3,T4,T5,T6>>, success : T1 -> T2 -> T3 -> T4 -> T5 -> T6 -> Promise<TOut>) : Promise<TOut>
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

  public static function mapTuple<T1,T2,T3,T4,T5,TOut>(promise : Promise<Tuple5<T1,T2,T3,T4,T5>>, success : T1 -> T2 -> T3 -> T4 -> T5 -> Promise<TOut>) : Promise<TOut>
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

  public static function mapTuple<T1,T2,T3,T4,TOut>(promise : Promise<Tuple4<T1,T2,T3,T4>>, success : T1 -> T2 -> T3 -> T4 -> Promise<TOut>) : Promise<TOut>
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

  public static function mapTuple<T1,T2,T3,TOut>(promise : Promise<Tuple3<T1,T2,T3>>, success : T1 -> T2 -> T3 -> Promise<TOut>) : Promise<TOut>
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

  public static function mapTuple<T1,T2,TOut>(promise : Promise<Tuple2<T1,T2>>, success : T1 -> T2 -> Promise<TOut>) : Promise<TOut>
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
}

// TODO: flatten
// TODOL flatMap