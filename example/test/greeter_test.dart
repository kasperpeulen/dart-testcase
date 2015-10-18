import 'package:testcase/testcase.dart';
export 'package:testcase/init.dart';
import '../lib/greeter.dart';

class GreeterTest implements TestCase {

  Greeter greeter;

  setUp() {
    greeter = new Greeter();
  }

  tearDown() {}

  @test
  it_works() {
    expect(greeter.sayHelloTo('Emil'), equals('Hello, Emil'));
  }

  @Test(skip: 'Oh noes, it fails')
  it_does_not_work() {
    expect(greeter.sayHelloTo('Kasper'), equals('Hello, Emil'));
  }

  @Test(parameters: const [
    const ['David', 'Hello, David'],
    const ['Kasper', 'Hello, Kasper'],
    const ['World', 'Hello, World'],
  ])
  it_works_for_different_cases(String name, String greet) {
    expect(greeter.sayHelloTo(name), equals(greet));
  }
}
