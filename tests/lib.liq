# Minimal test helpers: run a test script with liquidsoap, it exits 1 if any
# assertion failed.

test_failures = ref(0)

def assert_equal(name, expected, actual) =
  if
    expected == actual
  then
    print(
      "PASS #{name}"
    )
  else
    test_failures := test_failures() + 1
    print(
      "FAIL #{name}: expected #{expected}, got #{actual}"
    )
  end
end

def test_done() =
  if
    test_failures() > 0
  then
    print(
      "#{test_failures()} test(s) failed"
    )
    exit(1)
  else
    print(
      "All tests passed"
    )
    exit(0)
  end
end
