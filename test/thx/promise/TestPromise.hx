package thx.promise;

import thx.promise.Deferred;
import thx.promise.Promise;
import thx.core.Error;
import utest.Assert;

class TestPromise {
	public function new() {}

	public function testResolveBefore() {
		var close = Assert.createAsync(),
			deferred = new Deferred();
		deferred.resolve(1);
		deferred.promise.succeed(function(v) {
			Assert.equals(1, v);
			close();
		});
	}

	public function testResolveAfter() {
		var close = Assert.createAsync(),
			deferred = new Deferred();
		deferred.promise.succeed(function(v) {
			Assert.equals(1, v);
			close();
		});
		deferred.resolve(1);
	}

	public function testRejectBefore() {
		var close = Assert.createAsync(),
			deferred = new Deferred(),
			error = new Error("Nooooo!");
		deferred.reject(error);
		deferred.promise.fail(function(e) {
			Assert.equals(error, e);
			close();
		});
	}

	public function testRejectAfter() {
		var close = Assert.createAsync(),
			deferred = new Deferred(),
			error = new Error("Nooooo!");
		deferred.promise.fail(function(e) {
			Assert.equals(error, e);
			close();
		});
		deferred.reject(error);
	}
}