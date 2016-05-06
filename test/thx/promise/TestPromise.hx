package thx.promise;

using thx.promise.Promise;
import thx.Error;
import utest.Assert;
using thx.Arrays;
using thx.Tuple;

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

#if (js || swf)
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
    Promise.value(1).flatMap(function(v) {
      return Promise.value(v * 2);
    }).success(function(v) {
      Assert.equals(2, v);
      done();
    });
  }

  public function testMapSuccessWithFailure() {
    var done = Assert.createAsync(),
        err = new Error("error");
    Promise.error(err).flatMap(function(v) {
      Assert.fail("should never touch this");
      return Promise.value(v * 2);
    }).failure(function(e) {
      Assert.equals(err, e);
      done();
    });
  }

  public function testAllSuccess() {
    var done = Assert.createAsync();
    Promise.sequence([
      Promise.value(1),
      Promise.value(2)
    ]).success(function(arr) {
      Assert.equals(3, arr.reduce(function(acc, v) return acc + v, 0));
      done();
    });
  }

  public function testAllFailure1() {
    var done = Assert.createAsync(),
        err  = new Error("error");
    Promise.sequence([
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

  public function testAllFailure2() {
    var done = Assert.createAsync();
    Promise.sequence([res(), res(), rej()])
    .success(function(arr) {
      Assert.fail("should never happen");
    })
    .failure(function(e) {
      Assert.pass();
      done();
    });
  }

  public function testAfterAllSuccess() {
    var done = Assert.createAsync();
    Promise.afterAll([Promise.value(1), Promise.value(2), Promise.value(3)])
      .success(function(n) {
        Assert.equals(Nil.nil, n);
        done();
      })
      .failure(function(err) {
        Assert.fail();
        done();
      });
  }

  public function testAfterAllFailure1() {
    var done = Assert.createAsync();
    Promise.afterAll([Promise.value(1), Promise.value(2), Promise.error(new Error('rejected'))])
      .success(function(n) {
        Assert.fail('should never happen');
        done();
      })
      .failure(function(err) {
        Assert.pass();
        done();
      });
  }

  // Failing afterAll test preserved for future reference - see deprecation warning in Promise.afterAll
  public function testAfterAllFailure2() {
    var done = Assert.createAsync();
    Promise.afterAll([res(), res(), rej()])
      .success(function(n) {
        Assert.fail('should never happen');
        done();
      })
      .failure(function(err) {
        Assert.pass();
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

  public function testJoin3Success() {
    var done = Assert.createAsync();
    Promises.join3(res('1'), res('2'), res('3'))
      .success(function(tuple) {
        Assert.same('1', tuple._0);
        Assert.same('2', tuple._1);
        Assert.same('3', tuple._2);
        done();
      })
      .failure(function(err) {
        Assert.fail();
      });
  }

  public function testJoin3Failure1() {
    var done = Assert.createAsync();
    Promises.join3(Promise.value('1'), Promise.value('2'), Promise.error(new Error('3')))
      .success(function(tuple) {
        Assert.fail();
        done();
      })
      .failure(function(err) {
        Assert.same('3', err.message);
        done();
      });
  }

  public function testJoin3Failure2() {
    var done = Assert.createAsync();
    Promises.join3(res(), res(), rej('3'))
      .success(function(tuple) {
        Assert.fail();
        done();
      })
      .failure(function(err) {
        Assert.same('3', err.message);
        done();
      });
  }

  public function testJoin4Success() {
    var done = Assert.createAsync();
    Promises.join4(res('1'), res('2'), res('3'), res('4'))
      .success(function(tuple) {
        Assert.same('1', tuple._0);
        Assert.same('2', tuple._1);
        Assert.same('3', tuple._2);
        Assert.same('4', tuple._3);
        done();
      })
      .failure(function(err) {
        Assert.fail();
      });
  }

  public function testJoin4Failure1() {
    var done = Assert.createAsync();
    Promises.join4(Promise.value('1'), Promise.value('2'), Promise.value('3'), Promise.error(new Error('4')))
      .success(function(tuple) {
        Assert.fail();
        done();
      })
      .failure(function(err) {
        Assert.same('4', err.message);
        done();
      });
  }

  public function testJoin4Failure2() {
    var done = Assert.createAsync();
    Promises.join4(res(), res(), res(), rej('4'))
      .success(function(tuple) {
        Assert.fail();
        done();
      })
      .failure(function(err) {
        Assert.same('4', err.message);
        done();
      });
  }

  public function testJoin5Success() {
    var done = Assert.createAsync();
    Promises.join5(res('1'), res('2'), res('3'), res('4'), res('5'))
      .success(function(tuple) {
        Assert.same('1', tuple._0);
        Assert.same('2', tuple._1);
        Assert.same('3', tuple._2);
        Assert.same('4', tuple._3);
        Assert.same('5', tuple._4);
        done();
      })
      .failure(function(err) {
        Assert.fail();
      });
  }

  public function testJoin5Failure1() {
    var done = Assert.createAsync();
    Promises.join5(Promise.value('1'), Promise.value('2'), Promise.value('3'), Promise.value('4'), Promise.error(new Error('5')))
      .success(function(tuple) {
        Assert.fail();
        done();
      })
      .failure(function(err) {
        Assert.same('5', err.message);
        done();
      });
  }

  public function testJoin5Failure2() {
    var done = Assert.createAsync();
    Promises.join5(res(), res(), res(), res(), rej('5'))
      .success(function(tuple) {
        Assert.fail();
        done();
      })
      .failure(function(err) {
        Assert.same('5', err.message);
        done();
      });
  }

  public function testJoin6Success() {
    var done = Assert.createAsync();
    Promises.join6(res('1'), res('2'), res('3'), res('4'), res('5'), res('6'))
      .success(function(tuple) {
        Assert.same('1', tuple._0);
        Assert.same('2', tuple._1);
        Assert.same('3', tuple._2);
        Assert.same('4', tuple._3);
        Assert.same('5', tuple._4);
        Assert.same('6', tuple._5);
        done();
      })
      .failure(function(err) {
        Assert.fail();
      });
  }

  public function testJoin6Failure1() {
    var done = Assert.createAsync();
    Promises.join6(Promise.value('1'), Promise.value('2'), Promise.value('3'), Promise.value('4'), Promise.value('5'), Promise.error(new Error('6')))
      .success(function(tuple) {
        Assert.fail();
        done();
      })
      .failure(function(err) {
        Assert.same('6', err.message);
        done();
      });
  }

  public function testJoin6Failure2() {
    var done = Assert.createAsync();
    Promises.join6(res(), res(), res(), res(), res(), rej('6'))
      .success(function(tuple) {
        Assert.fail();
        done();
      })
      .failure(function(err) {
        Assert.same('6', err.message);
        done();
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
    Promise.sequence([
      Promise.error(err),
      Promise.error(err)
    ])
    .flatMap(function(v) {
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

  public function testMapSuccessFailure() {
    var done = Assert.createAsync();
    Promise.nil
      .map(function(_) return throw "NOOO!")
      .success(function(_) Assert.fail("should never succeed"))
      .failure(function(e) Assert.stringContains("NOOO!", e.toString()))
      .always(done);
  }

  public function testTuple3() {
    var done = Assert.createAsync(),
        err  = new Error("error");
    Promise
      .value(new Tuple3(1, "a", 0.2))
      .tuple(function(a, b, c) {
        Assert.equals(1, a);
        Assert.equals("a", b);
        Assert.equals(0.2, c);
        done();
      });
  }

  function res(?val : String = "resolved") : Promise<String> {
    return Promise.value(val);
  }

  function rej(?msg : String = "rejected") : Promise<String> {
    return Promise.error(new Error(msg));
  }
}
