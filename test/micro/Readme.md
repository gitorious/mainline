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
