package thx.promise;

using thx.promise.Promise;
import thx.core.Error;
import utest.Assert;
using thx.core.Arrays;
using thx.core.Tuple;

class TestPromise {
  public function new() {}

  public function testResolveBefore() {
    var done = Assert.createAsync();
    Promise.value(1)
      .success(function(v) {
        Assert.equals(1, v);
        done();
      });
  }

#if (js || swf || java)
  public function testResolveAfter() {
    var done = Assert.createAsync();
    Promise.value(1)
      .delay()
      .success(function(v) {
        Assert.equals(1, v);
        done();
      });
  }

  public function testRejectAfter() {
    var done = Assert.createAsync(),
        error = new Error("Nooooo!");

    Promise.error(error)
      .delay()
      .failure(function(e) {
        Assert.equals(error, e);
        done();
      });
  }

  public function testDelay() {
    var done = Assert.createAsync(),
        start = Date.now().getTime();
    Promise.value("a")
      .delay(50)
      .success(function(v) {
        Assert.equals("a", v);
        Assert.isTrue(Date.now().getTime() - start >= 50 * 0.8);
        done();
      })
      .failure(function(e) {
        Assert.fail(e.toString());
      });
  }
#end

  public function testRejectBefore() {
    var done = Assert.createAsync(),
        error = new Error("Nooooo!");

    Promise.error(error)
      .failure(function(e) {
        Assert.equals(error, e);
        done();
      });
  }

  public function testMapSuccessWithValue() {
    var done = Assert.createAsync();
    Promise.value(1).mapSuccessPromise(function(v) {
      return Promise.value(v * 2);
    }).success(function(v) {
      Assert.equals(2, v);
      done();
    });
  }

  public function testMapSuccessWithFailure() {
    var done = Assert.createAsync(),
        err = new Error("error");
    Promise.error(err).mapSuccessPromise(function(v) {
      Assert.fail("should never touch this");
      return Promise.value(v * 2);
    }).failure(function(e) {
      Assert.equals(err, e);
      done();
    });
  }

  public function testAllSuccess() {
    var done = Assert.createAsync();
    Promise.all([
      Promise.value(1),
      Promise.value(2)
    ]).success(function(arr) {
      Assert.equals(3, arr.reduce(function(acc, v) return acc + v, 0));
      done();
    });
  }

  public function testAllFailure() {
    var done = Assert.createAsync(),
        err  = new Error("error");
    Promise.all([
      Promise.value(1),
      Promise.error(err)
    ])
    .success(function(arr) {
      Assert.fail("should never happen");
    })
    .failure(function(e) {
      Assert.equals(err, e);
      done();
    });
  }

  public function testJoinSuccess() {
    var done = Assert.createAsync();
    Promise.value(1)
      .join(Promise.value(2))
      .success(function(t) {
        Assert.equals(1, t._0);
        Assert.equals(2, t._1);
        done();
      });
  }

  public function testJoinFailure() {
    var done = Assert.createAsync(),
        err  = new Error("error");
    Promise.value(1)
      .join(Promise.error(err))
      .failure(function(e) {
        Assert.equals(err, e);
        done();
      })
      .success(function(t) {
        Assert.fail("should never happen");
      });
  }

  public function testMapTupleSuccess() {
    var done = Assert.createAsync();
    Promise.value(new Tuple2(1, 2))
      .mapTuplePromise(function(a, b) {
        return Promise.value(a/b);
      })
      .success(function(v) {
        Assert.equals(0.5, v);
        done();
      });
  }

  public function testMapTupleFailure() {
    var done = Assert.createAsync(),
        err  = new Error("error");
    Promise.error(err)
      .mapTuplePromise(function(a, b) {
        return Promise.value(a/b);
      })
      .failure(function(e) {
        Assert.equals(err, e);
        done();
      });
  }

  public function testAllMapToTupleFailure() {
    var done = Assert.createAsync(),
        err  = new Error("error");
    Promise.all([
      Promise.error(err),
      Promise.error(err)
    ])
    .mapSuccessPromise(function(v) {
      Assert.fail("should never happen");
      return Promise.value(new Tuple2(1, 2));
    })
    .mapTuplePromise(function(a, b) {
      Assert.fail("should never happen");
      return Promise.value(a / b);
    })
    .failure(function(e) {
      Assert.equals(err, e);
      done();
    });
  }

  public function testTuple3() {
    var done = Assert.createAsync(),
        err  = new Error("error");
    Promise.value(new Tuple3(1,"a", 0.2))
    .tuple(function(a, b, c) {
      Assert.equals(1, a);
      Assert.equals("a", b);
      Assert.equals(0.2, c);
      done();
    });
  }
}