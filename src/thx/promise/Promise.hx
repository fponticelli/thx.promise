package thx.promise;

import haxe.ds.Option;
import thx.core.Error;
import thx.core.Tuple;
using thx.core.Options;
using thx.core.Arrays;

class Promise<T> {
	public static function all<T>(arr : Array<Promise<T>>) : Promise<Array<T>>
		return Deferred.create(function(resolve, reject) {
			var results  = [],
				counter  = 0,
				hasError = false;
			arr.mapi(function(p, i) {
				p.thenEither(function(value) {
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
		return Deferred.create(function(resolve, _) resolve(v));

	public static function reject<T>(err : Error) : Promise<T>
		return Deferred.create(function(_, reject) reject(err));

	var handlers : Array<PromiseState<T> -> Void>;
	var state : Option<PromiseState<T>>;
	private function new() {
		handlers = [];
		state = None;
	}

	public function then(handler : PromiseState<T> -> Void) {
		handlers.push(handler);
		update();
		return this;
	}

	public function thenEither(success : T -> Void, failure : Error -> Void) {
		then(function(r) switch r {
			case Success(value): success(value);
			case Failure(error): failure(error);
		});
		return this;
	}

	public function success(success : T -> Void)
		return thenEither(success, function(_){});

	public function failure(failure : Error -> Void)
		return thenEither(function(_){}, failure);

	public function map<TOut>(handler : PromiseState<T> -> Promise<TOut>)
		return Deferred.createFulfill(function(fulfill)
			then(function(result) handler(result).then(fulfill))
		);

	public function mapEither<TOut>(success : T -> Promise<TOut>, failure : Error -> Promise<TOut>)
		return map(function(result) return switch result {
				case Success(value): success(value);
				case Failure(error): failure(error);
			});

	public function mapSuccess<TOut>(success : T -> Promise<TOut>)
		return mapEither(success, function(err) return Promise.reject(err));

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

	function setState(newstate : PromiseState<T>) {
		switch state {
			case None:
				state = Some(newstate);
			case Some(r):
				throw new Error('promise was already $r, can\'t apply new state $newstate');
		}
		update();
		return this;
	}

	function setStateDelayed(newstate : PromiseState<T>) {
#if (neko || php || cpp)
		return setState(newstate);
/*
#elseif nodejs
		js.Node.setTimeout(function() {
			setState(newstate);
		}, 0);
		return this;
*/
#else
		// TODO optimize
		haxe.Timer.delay(function() {
			setState(newstate);
		}, 0);
		return this;
#end
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
		return promise.thenEither(
			function(r) trace('$prefix SUCCESS: $r'),
			function(e) trace('$prefix ERROR: ${e.toString()}')
		);
}

class Promise2 {
	public static function join<T1,T2>(p1 : Promise<T1>, p2 : Promise<T2>) : Promise<Tuple2<T1,T2>> {
		return Deferred.create(function(resolve, reject) {
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

			p1.thenEither(function(v) {
				if(hasError) return;
				counter++;
				v1 = v;
				complete();
			}, handleError);

			p2.thenEither(function(v) {
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

	public static function thenTuple<T1,T2,T3,T4,T5,T6>(promise : Promise<Tuple6<T1,T2,T3,T4,T5,T6>>, success : T1 -> T2 -> T3 -> T4 -> T5 -> T6 -> Void, ?failure : Error -> Void) : Void
		promise.thenEither(
			function(t) success(t._0, t._1, t._2, t._3, t._4, t._5),
			null == failure ? function(_) {} : failure
		);
}

class PromiseTuple5 {
	public static function join<T1,T2,T3,T4,T5,T6>(p1 : Promise<Tuple5<T1,T2,T3,T4,T5>>, p2 : Promise<T6>) : Promise<Tuple6<T1,T2,T3,T4,T5,T6>> {
		return Deferred.create(function(resolve, reject) {
			Promise2.join(p1, p2)
				.thenEither(
					function(t) resolve(t._0.toTuple6(t._1)),
					function(e) reject(e));
		});
	}

	public static function mapTuple<T1,T2,T3,T4,T5,TOut>(promise : Promise<Tuple5<T1,T2,T3,T4,T5>>, success : T1 -> T2 -> T3 -> T4 -> T5 -> Promise<TOut>) : Promise<TOut>
		return promise.mapSuccess(function(t)
			return success(t._0, t._1, t._2, t._3, t._4)
		);

	public static function thenTuple<T1,T2,T3,T4,T5>(promise : Promise<Tuple5<T1,T2,T3,T4,T5>>, success : T1 -> T2 -> T3 -> T4 -> T5 -> Void, ?failure : Error -> Void) : Void
		promise.thenEither(
			function(t) success(t._0, t._1, t._2, t._3, t._4),
			null == failure ? function(_) {} : failure
		);
}

class PromiseTuple4 {
	public static function join<T1,T2,T3,T4,T5>(p1 : Promise<Tuple4<T1,T2,T3,T4>>, p2 : Promise<T5>) : Promise<Tuple5<T1,T2,T3,T4,T5>> {
		return Deferred.create(function(resolve, reject) {
			Promise2.join(p1, p2)
				.thenEither(
					function(t) resolve(t._0.toTuple5(t._1)),
					function(e) reject(e));
		});
	}

	public static function mapTuple<T1,T2,T3,T4,TOut>(promise : Promise<Tuple4<T1,T2,T3,T4>>, success : T1 -> T2 -> T3 -> T4 -> Promise<TOut>) : Promise<TOut>
		return promise.mapSuccess(function(t)
			return success(t._0, t._1, t._2, t._3)
		);

	public static function thenTuple<T1,T2,T3,T4>(promise : Promise<Tuple4<T1,T2,T3,T4>>, success : T1 -> T2 -> T3 -> T4 -> Void, ?failure : Error -> Void) : Void
		promise.thenEither(
			function(t) success(t._0, t._1, t._2, t._3),
			null == failure ? function(_) {} : failure
		);
}

class PromiseTuple3 {
	public static function join<T1,T2,T3,T4>(p1 : Promise<Tuple3<T1,T2,T3>>, p2 : Promise<T4>) : Promise<Tuple4<T1,T2,T3,T4>> {
		return Deferred.create(function(resolve, reject) {
			Promise2.join(p1, p2)
				.thenEither(
					function(t) resolve(t._0.toTuple4(t._1)),
					function(e) reject(e));
		});
	}

	public static function mapTuple<T1,T2,T3,TOut>(promise : Promise<Tuple3<T1,T2,T3>>, success : T1 -> T2 -> T3 -> Promise<TOut>) : Promise<TOut>
		return promise.mapSuccess(function(t)
			return success(t._0, t._1, t._2)
		);

	public static function thenTuple<T1,T2,T3>(promise : Promise<Tuple3<T1,T2,T3>>, success : T1 -> T2 -> T3 -> Void, ?failure : Error -> Void) : Void
		promise.thenEither(
			function(t) success(t._0, t._1, t._2),
			null == failure ? function(_) {} : failure
		);
}

class PromiseTuple2 {
	public static function join<T1,T2,T3>(p1 : Promise<Tuple2<T1,T2>>, p2 : Promise<T3>) : Promise<Tuple3<T1,T2,T3>> {
		return Deferred.create(function(resolve, reject) {
			Promise2.join(p1, p2)
				.thenEither(
					function(t) resolve(t._0.toTuple3(t._1)),
					function(e) reject(e));
		});
	}

	public static function mapTuple<T1,T2,TOut>(promise : Promise<Tuple2<T1,T2>>, success : T1 -> T2 -> Promise<TOut>) : Promise<TOut>
		return promise.mapSuccess(function(t)
			return success(t._0, t._1)
		);

	public static function thenTuple<T1,T2>(promise : Promise<Tuple2<T1,T2>>, success : T1 -> T2 -> Void, ?failure : Error -> Void) : Void
		promise.thenEither(
			function(t) success(t._0, t._1),
			null == failure ? function(_) {} : failure
		);
}

enum PromiseState<T> {
	Failure(err : Error);
	Success(value : T);
}