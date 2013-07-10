# What's "micro" tests?

Generally, "micro tests" is a term suggested as an alternative to
"unit tests" and "functional tests". Sometimes the difference is hard
to pinpoint, and of little value in itself. Thus, micro tests are just
that - small focused tests, that may or may not integrate with a few
close collaborators.

Specifically, in Gitorious, micro tests are here to preserve our
sanity. Any test that can be run without loading the Rails environment
(thus that uses Minitest directly, not any of Rails' test case
classes), is welcome here. These tests should be fast - TDD-able fast.

## Writing micro tests

Micro tests are simple: pop a new file in `test/micro`. It should
contain one class inheriting from `MiniTest::Spec`.

The test needs to `require "fast_test_helper"`. This file defines a
very minimal Rails shim, so you can still test stuff that depends on
`Rails.env` without loading the entire application. It also defines
very simple stubs for Gitorious' model classes. In addition to the
helper, you must require any module you intend to test, and use
throughout your test case. Micro tests live outside the world of
Rails, so there's no magic autoloading.

Be sure to only add fast tests to this group - if your test requires
either loading more of Rails, or the entire application - or, if it
contributes a noticeable performance hit - it should not be a micro
test. Use regular Rails "unit" and "functional" tests instead. With
that said, please strive to make new tests work as fast micro tests.
Most tests can, if the targeted API is designed properly.

### Example test case

The following is an example of the minimum of things required for a
micro test:

```ruby
require "fast_test_helper"
require "gitorious/some_thing"

class SomeThingTest < MiniTest::Spec
  describe "#winning" do
    it "is doing it" do
      assert_equal 42, Gitorious::SomeThing.new.winning
    end
  end
end
```

To run this test case, either run it directly:

    ruby -Ilib:test test/micro/gitorious/some_thing_test.rb

Or, run it as part of the micro test suite:

    bin/micro-tests
    # There's also a rake task, but it's slower
    rake test:micros

Micro tests will also run along with the entire Gitorious test suite:

    rake test
