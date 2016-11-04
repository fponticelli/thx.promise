package thx.promise;

import utest.Assert;

using thx.Arrays;
import thx.Error;
using thx.Functions;
using thx.Tuple;

class TestPromiseR {
  public function new() {}

  public function testMap_Success() {
    var done = Assert.createAsync();
    return PromiseR.pure(2)
      .map.fn(_ * 4)
      .run("hi")
      .success(function(v) {
        Assert.same(8, v);
        done();
      });
  }

  public function testMap_Failure() {
    var done = Assert.createAsync();
    return PromiseR.error(new Error('die'))
      .map.fn(_ * 4)
      .run("hi")
      .failure(function(e) {
        Assert.same("die", e.message);
        done();
      });
  }

  public function testFlatMap() {
    var done = Assert.createAsync();
    var action: PromiseR<Int, Int> = PromiseR.pure(2).flatMap(
      function(v) return PromiseR.ask().flatMap(
        function(r) return PromiseR.pure(r * v * 2)
      )
    );

    action.run(2).success(function(v) {
      Assert.equals(8, v);
      done();
    });
  }


  public function testNil_Success() {
    var done = Assert.createAsync();
    PromiseR.pure(1)
      .nil()
      .run("hi")
      .success(function(v : Nil) {
        Assert.same(Nil.nil, v);
        done();
      });
  }

  public function testNil_Failure() {
    var done = Assert.createAsync();
    PromiseR.ask().bindPromise(function(v : String) {
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
