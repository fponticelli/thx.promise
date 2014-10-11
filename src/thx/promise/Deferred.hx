package thx.promise;

import haxe.PosInfos;
import thx.core.Error;
import thx.promise.Promise;
import thx.core.Either;

@:access(thx.promise.Promise)
class Deferred<T> {
  public var promise(default, null) : Promise<T>;
  public function new()
    promise = new Promise<T>();

  public function reject(error : Error)
    return fulfill(Left(error));

  public function rejectWith(error : Dynamic, ?pos : PosInfos)
    return fulfill(Left(Error.fromDynamic(error, pos)));

  public function resolve(value : T)
    return fulfill(Right(value));

  public function fulfill(result : PromiseValue<T>)
    return promise.setState(result);

  public function toString() return 'Deferred';
}