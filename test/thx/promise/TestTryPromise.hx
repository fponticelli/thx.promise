package thx.promise;

using thx.promise.Promise;
import utest.Assert;
import haxe.ds.Either;
import thx.Result;

class TestTryPromise {
  public function new() {}

  public function testTryCreate() {
    Promise.create(function(resolve, reject) throw 'oh boy')
      .success(function(_) Assert.fail("exception triggered resolve"))
      .failure(function(_) Assert.pass())
      .always(Assert.createAsync());
  }

  public function testTryEitherSuccess() {
    var done = Assert.createAsync();
    Promise.nil
      .either(
        function(_) throw 'nops',
        function(_) Assert.fail('no reason to get here')
      )
      .then(function(r) {
        switch r {
          case Left(e): Assert.pass();
          case Right(r): Assert.fail("not good");
        }
        done();
      });
  }

  public function testTryEitherFailure() {
    var done = Assert.createAsync();
    Promise.fail("no go")
      .either(
        function(_) Assert.fail('no reason to get here'),
        function(_) throw 'nops'
      )
      .then(function(r) {
        switch r {
          case Left(e): Assert.pass();
          case Right(r): Assert.fail("not good");
        }
        done();
      });
  }

  public function testTrySuccess() {
    Promise.nil
      .success(function(_) throw 'nops')
      .success(function(_) Assert.fail("not piped to a failing promise"))
      .failure(function(_) Assert.pass())
      .always(Assert.createAsync());
  }

  public function testTryReject() {
    Promise.fail('nops')
      .failure(function(_) throw 'niet')
      .success(function(_) Assert.fail("not piped to a failing promise"))
      .failure(function(e) Assert.stringContains('niet', e.message))
      .always(Assert.createAsync());
  }

  public function testTryAlways() {
    Promise.nil
      .always(function() throw 'bad')
      .failure(function(e) Assert.stringContains('bad', e.message))
      .always(Assert.createAsync());
  }

  public function testTryThrowFailure() {
    Assert.raises(Promise.fail("meh").throwFailure, thx.Error);
  }

  public function testTryMap() {
    Promise.nil
      .map(function(_) return throw "meh")
      .failure(function(e) Assert.stringContains('meh', e.message))
      .always(Assert.createAsync());
  }

  public function testTryFlatMap() {
    Promise.nil
      .flatMap(function(_) return throw "meh")
      .failure(function(e) Assert.stringContains('meh', e.message))
      .always(Assert.createAsync());
  }

  public function testTryFlatMapEitherSuccess() {
    Promise.nil
      .flatMapEither(
        function(_) return throw "meh",
        function(e) return throw "mah"
      )
      .failure(function(e) Assert.stringContains('meh', e.message))
      .always(Assert.createAsync());
  }

  public function testTryFlatMapEitherFailure() {
    Promise.fail("bah")
      .flatMapEither(
        function(_) return throw "meh",
        function(e) return throw "mah"
      )
      .failure(function(e) Assert.stringContains('mah', e.message))
      .always(Assert.createAsync());
  }

  public function testTryRecoverNull() {
    Promise.value(null)
      .recoverNull(function() : Promise<String> return throw "meh")
      .failure(function(e) Assert.stringContains('meh', e.message))
      .always(Assert.createAsync());
  }
}
