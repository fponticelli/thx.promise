package thx.promise;

import thx.core.Error;
import thx.promise.Promise;

@:access(thx.promise.Promise)
class Deferred<T>
{
	public static function create<T>(callback : (T -> Void) -> (Error -> Void) -> Void) : Promise<T> {
		var deferred = new Deferred<T>();
		callback(deferred.resolve, deferred.reject);
		return deferred.promise;
	}

	public var promise(default, null) : Promise<T>;
	public function new()
		promise = new Promise<T>();

	public function rejectWith(error : Dynamic)
		return fulfill(Failure(Error.fromDynamic(error)));
	public function reject(error : Error)
		return fulfill(Failure(error));
	public function resolve(value : T)
		return fulfill(Success(value));
	public function fulfill(result : PromiseState<T>)
		return promise.setStateDelayed(result);

	public function toString() return 'Deferred';
}