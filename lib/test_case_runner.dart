part of testcase;

/// `@test` can be used as shortcut for `@Test()`.
const test = const Test();

class Test {
  /// The description will be added to the descriptions of any surrounding
  /// [group]s. If [testOn] is passed, it's parsed as a [platform selector][]; the
  /// test will only be run on matching platforms.
  final String testOn;

  /// If [timeout] is passed, it's used to modify or replace the default timeout
  /// of 30 seconds. Timeout modifications take precedence in suite-group-test
  /// order, so [timeout] will also modify any timeouts set on the suite, and will
  /// be modified by any timeouts set on individual tests.
  final Timeout timeout;

  /// If [skip] is a String or `true`, the test is skipped. If it's a String, it
  /// should explain why the test is skipped; this reason will be printed instead
  /// of running the test.
  final dynamic skip;

  /// [onPlatform] allows groups to be configured on a platform-by-platform
  /// basis. It's a map from strings that are parsed as [PlatformSelector]s to
  /// annotation classes: [Timeout], [Skip], or lists of those. These
  /// annotations apply only on the given platforms. For example:
  ///
  ///     group("potentially slow tests", () {
  ///       // ...
  ///     }, onPlatform: {
  ///       // These tests are especially slow on Windows.
  ///       "windows": new Timeout.factor(2),
  ///       "browser": [
  ///         new Skip("TODO: add browser support"),
  ///         // They'll be slow on browsers once it works on them.
  ///         new Timeout.factor(2)
  ///       ]
  ///     });
  ///
  /// If multiple platforms match, the annotations apply in order as through
  /// they were in nested groups.
  final Map<String, dynamic> onPlatform;

  /// If [parameters] is passed, the test can be run multiple times with
  /// different parameters. For example:
  ///
  ///     @Test(parameters: [
  ///       [1, 1], [2, 4], [3, 9], [4, 16], [5, 25], [6, 36]
  ///     ])
  ///     math_pow_squares_an_integer(int number, int squared) {
  ///       expect(math.pow(number, 2), squared);
  ///     }
  final List<List<dynamic>> parameters;

  const Test(
      {this.testOn, this.timeout, this.skip, this.onPlatform, this.parameters});
}

abstract class TestCaseRunner {
  factory TestCaseRunner(TestCase testCase) => new _TestCaseRunner(testCase);

  run();
}

class _TestCaseRunner implements TestCaseRunner {
  TestCase testCase;

  _TestCaseRunner(this.testCase);

  run() => group('${_unitName()}:', _declareTestGroup);

  String _unitName() => testCase.runtimeType
      .toString()
      .replaceFirst(new RegExp(r'test$', caseSensitive: false), '');

  _declareTestGroup() {
    setUp(testCase.setUp);
    tearDown(testCase.tearDown);
    reflectClass(testCase.runtimeType).declarations.forEach(_registerIfTest);
  }

  _registerIfTest(Symbol symbol, DeclarationMirror declaration) {
    if (_methodIsTest(declaration))
      _registerTest(symbol, declaration);
  }

  bool _methodIsTest(DeclarationMirror declaration) {
    return (declaration.metadata.any((meta) => meta.reflectee is Test));
  }

  Test _getTestMetaData(DeclarationMirror declaration) {
    return declaration.metadata
        .firstWhere((m) => m.reflectee is Test)
        .reflectee;
  }

  _registerTest(symbol, declaration) {
    Test testAnnotation = _getTestMetaData(declaration);
    dart_test.test(
        _describeTest(symbol), () => _runTest(symbol, testAnnotation),
        testOn: testAnnotation.testOn,
        timeout: testAnnotation.timeout,
        skip: testAnnotation.skip,
        onPlatform: testAnnotation.onPlatform);
  }

  _runTest(Symbol symbol, Test testAnnotation) {
    // if the test has a parameters field
    // run the test for each of the given parameters
    if (testAnnotation.parameters != null) {
      List<List<dynamic>> listOfParameters = testAnnotation.parameters;
      for (List<dynamic> parameters in listOfParameters) {
        reflect(testCase).invoke(symbol, parameters).reflectee;
      }
    } else {
      reflect(testCase).invoke(symbol, []).reflectee;
    }
  }

  String _describeTest(Symbol symbol) {
    return MirrorSystem.getName(symbol).replaceAll('_', ' ');
  }
}
