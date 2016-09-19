import utest.Runner;
import utest.ui.Report;
import utest.Assert;

class TestAll {
  public static function main() {
    var runner = new Runner();
    runner.addCase(new thx.promise.TestFuture());
    runner.addCase(new thx.promise.TestPromise());
    runner.addCase(new thx.promise.TestPromiseR());
    runner.addCase(new thx.promise.TestPromiseExtensions());
    runner.addCase(new thx.promise.TestTryPromise());
    Report.create(runner);
    runner.run();
  }
}
