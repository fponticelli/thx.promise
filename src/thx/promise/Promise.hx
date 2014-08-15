// TODO
// p.await(other)  : Promise<Tuple2<T1, T2>>
// p.await2(other) : Promise<Tuple3<T1, T2, T3>>
// p.await3(other) : Promise<Tuple4<T1, T2, T3, T4>>
package thx.promise;

import haxe.ds.Option;
import thx.core.Error;
import thx.core.Tuple.Tuple2;
using thx.core.Options;

class Promise<T> {
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

	public function succeed(success : T -> Void)
		return thenEither(success, function(_){});

	public function fail(failure : Error -> Void)
		return thenEither(function(_){}, failure);

	public function map<TOut>(handler : PromiseState<T> -> Promise<TOut>) {
		var deferred = new Deferred<TOut>();
		then(function(r) {
			handler(r).then(deferred.fulfill);
		});
		return deferred.promise;
	}

	public function mapEither<TOut>(success : T -> Promise<TOut>, failure : Error -> Promise<TOut>) {
		var deferred = new Deferred<TOut>();
		then(function(r) switch r {
			case Success(value): success(value).then(deferred.fulfill);
			case Failure(error): failure(error).then(deferred.fulfill);
		});
		return deferred.promise;
	}

	public function mapSuccess<TOut>(success : T -> Promise<TOut>)
		return mapEither(success, function(_) return new Promise());

	public function mapFailure<TOut>(failure : Error -> Promise<TOut>)
		return mapEither(function(_) return new Promise(), failure);

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

enum PromiseState<T> {
	Failure(err : Error);
	Success(value : T);
}