# compat/harness.mojo — Cross-implementation test harness
#
# Compares outputs between the Mojo port and TypeScript reference.

from std.collections import List, Dict


@fieldwise_init
struct TestCase(Copyable, Movable):
    """A parity test case with input and expected output."""
    var name: String
    var input_json: String
    var expected_output: String
    var subsystem: String  # "tools", "commands", "api", "runtime"


@fieldwise_init
struct TestResult(Copyable, Movable, Writable):
    """Result of a parity test."""
    var name: String
    var passed: Bool
    var actual_output: String
    var expected_output: String
    var diff: String

    def __str__(self) -> String:
        var status = "PASS" if self.passed else "FAIL"
        return "[" + status + "] " + self.name


struct CompatHarness:
    """Run parity tests between implementations."""
    var test_cases: List[TestCase]
    var results: List[TestResult]

    def __init__(out self):
        self.test_cases = List[TestCase]()
        self.results = List[TestResult]()

    def add_test(mut self, test: TestCase):
        """Add a test case."""
        self.test_cases.append(test)

    def run_all(mut self) -> List[TestResult]:
        """Run all test cases and return results."""
        self.results = List[TestResult]()
        for tc in self.test_cases:
            var result = self._run_test(tc[])
            self.results.append(result)
        return self.results

    def _run_test(self, tc: TestCase) -> TestResult:
        """Run a single test case."""
        # TODO: Execute the test through the appropriate subsystem
        return TestResult(
            name=tc.name,
            passed=False,
            actual_output="[not yet implemented]",
            expected_output=tc.expected_output,
            diff="",
        )

    def summary(self) -> String:
        """Return a summary of test results."""
        var passed = 0
        var failed = 0
        for r in self.results:
            if r[].passed:
                passed += 1
            else:
                failed += 1
        return (
            String(passed)
            + " passed, "
            + String(failed)
            + " failed, "
            + String(len(self.results))
            + " total"
        )
