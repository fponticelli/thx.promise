package thx.promise;

import haxe.ds.Option;
using thx.core.Arrays;
import thx.core.Error;
using thx.core.Options;

class Future<T> {
  public static function all<T>(arr : Array<Future<T>>) : Future<Array<T>>
    return Future.create(function(callback) {
      var results = [],
          counter = 0;
      arr.mapi(function(p, i) {
        p.then(function(value) {
          results[i] = value;
          counter++;
          if(counter == arr.length)
            callback(results);
        });
      });
    });

  public static function create<T>(handler : (T -> Void) -> Void) {
    var future = new Future<T>();
    handler(future.setState);
    return future;
  }

  public static function value<T>(v : T)
    return create(function(callback) callback(v));

  public static function flatMap<T>(future : Future<Future<T>>) : Future<T> {
    var nfuture = new Future<T>();
    future.then(function(f) f.then(nfuture.setState));
    return nfuture;
  }

  var handlers : Array<T -> Void>;
  public var state(default, null) : Option<T>;
  private function new() {
    handlers = [];
    state = None;
  }

  inline public function hasValue()
    return state.toBool();

  public function map<TOut>(handler : T -> TOut) : Future<TOut>
    return Future.create(function(callback)
      then(function(value)
        callback(handler(value))));

  public function mapAsync<TOut>(handler : T -> (TOut -> Void) -> Void) : Future<TOut> {
    var future = new Future<TOut>();
    then(function(result : T) handler(result, future.setState));
    return future;
  }

  inline public function mapFuture<TOut>(handler : T -> Future<TOut>) : Future<TOut>
    return flatMap(map(handler));

  public function then(handler : T -> Void) {
    handlers.push(handler);
    update();
    return this;
  }

  public function toString() return 'Future';

  function setState(newstate : T) {
    switch state {
      case None:
        state = Some(newstate);
      case Some(r):
        throw new Error('future was already "$r", can\'t apply the new state "$newstate"');
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