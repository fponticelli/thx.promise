package thx.promise;

import utest.Assert;

import thx.Either;
import thx.Error;
using thx.Arrays;
using thx.Functions;
using thx.Tuple;

class TestPromiseRF {
  public function new() {}

  public function testMap_Success() {
    var done = Assert.createAsync();
    return PromiseRF.pure(2)
      .map.fn(_ * 4)
      .run("hi")
      .success(function(v) {
        Assert.same(Right(8), v);
        done();
      });
  }

  public function testMap_Failure() {
    var done = Assert.createAsync();
    return PromiseRF.die(new Error('die'))
      .map.fn(_ * 4)
      .run("hi")
      .failure(function(e) {
        Assert.same("die", e.message);
        done();
      });
  }

  public function testFlatMap() {
    var done = Assert.createAsync();
    var action: PromiseRF<Int, Nil, Int> = PromiseRF.pure(2).flatMap(
      function(v) return PromiseRF.ask().flatMap(
        function(r) return PromiseRF.pure(r * v * 2)
      )
    );

    action.run(2).success(function(v) {
      Assert.same(Right(8), v);
      done();
    });
  }


  public function testNil_Success() {
    var done = Assert.createAsync();
    PromiseRF.pure(1)
      .nil()
      .run("hi")
      .success(function(v : Either<Nil, Nil>) {
        Assert.same(Right(Nil.nil), v);
        done();
      });
  }

  public function testNil_Failure() {
    var done = Assert.createAsync();
    PromiseRF.ask().bindPromise(function(v : String) {
      return Promise.fail('$v guy');
    })
    .nil()
    .run("hi")
    .failure(function(e) {
      Assert.same("hi guy", e.message);
      done();
    });
  }
}

