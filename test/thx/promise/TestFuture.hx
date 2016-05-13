package thx.promise;

using thx.Nil;
using thx.promise.Future;
import utest.Assert;
using thx.Tuple;

@:access(thx.promise.Future)
class TestFuture {
  public function new() {}

  public function testThenBefore() {
    Future.value(1).then(function(v) Assert.equals(1, v));
  }

#if (js || flash)
  public function testThenAfter() {
    var done = Assert.createAsync();
    Timer.delayValue("x", 10)
      .then(function(v) {
        Assert.equals("x", v);
        done();
      });
  }

  public function testImmediateThenAfter() {
    var done = Assert.createAsync();
    Timer.immediateValue("x")
      .then(function(v) {
        Assert.equals("x", v);
        done();
      });
  }

  public function testHasValue() {
    var done = Assert.createAsync(),
        future : Future<Nil> = null;
    future = Timer.delay(10)
      .then(function(_) {
        Assert.isTrue(future.hasValue());
        done();
      });
    Assert.isFalse(future.hasValue());
  }
#end

  public function testMap() {
    Future.value(1)
      .map(function(i) return '$i')
      .then(Assert.equals.bind('1'));
  }

  public function testMapAsync() {
    Future.value(1)
      .mapAsync(function(v, callback) callback('$v'))
      .then(Assert.equals.bind('1'));
  }

  public function testFlatten() {
    Future.value(Future.value(1))
      .flatten()
      .then(Assert.equals.bind(1));
  }

  public function testFlatMap() {
    Future.value(1)
      .flatMap(function(v) return Future.value('$v'))
      .then(Assert.equals.bind('1'));
  }

#if (js || flash)
  public function testSequence() {
    var done = Assert.createAsync();
    Future.sequence([
      Timer.delayValue(1, 10),
      Future.value(2)
    ]).then(function(values) {
        Assert.same([1,2], values);
        done();
      });
  }

  public function testJoin() {
    var done = Assert.createAsync();
    Timer
      .delayValue(1, 20).join(Timer.delayValue(2, 10))
      .then(function(p) {
        Assert.same({_0 : 1, _1 : 2}, p);
        done();
      });
  }
#end

  public function testTuple3() {
    var done = Assert.createAsync();
    Future
      .value(new Tuple3(1, "a", 0.2))
      .tuple(function(a, b, c) {
        Assert.equals(1, a);
        Assert.equals("a", b);
        Assert.equals(0.2, c);
        done();
      });
  }
}
