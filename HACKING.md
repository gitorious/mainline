## Guide to Hacking Gitorious

To get started you need a working Gitorious setup. Gitorious ships
with two scripts that gets most enough services up and running to work
on it. See doc/setup-dev-env-centos.sh or doc/setup-dev-env-ubuntu.sh.
These scripts are executable annotated walkthroughs for getting
Gitorious up and running. If you're on e.g. Debian, the Ubuntu script
should work, but you will likely need to go through it manually.

On a box that has no existing Ruby development environment running
either of the two aforementioned scripts will take about 10-15
minutes.

Alternatively, if you're OK with working through a virtual machine,
you can grab the fully automated installer or one of the pre-built VMs
from http://getgitorious.org.

### Coding style

* Two spaces, no tabs, for indention
* Don't use and and or for boolean tests, instead always use && and ||
* MyClass.my_method(my_arg) -- not my_method( my_arg ) or my_method my_arg
* Unless precedence is an issue; do .. end for multi-line blocks, braces for single line blocks
* Follow the conventions you see used in the source already

(copied mostly verbatim from dev.rubyonrails.org)

### Branching model

Gitorious uses
[the git-flow branching model](http://nvie.com/posts/a-successful-git-branching-model/)
for branching. This means that the master branch is stable, and is
only merged to once a feature has been completed.

New features are created in feature branches (named `feature/$name`)
and then merged into the `next` branch once finished. Such features
arrive in `master` as new releases.

When contributing new features into Gitorious as merge requests, these
should be started the `next` branch, and marked as such when proposed.

The exception to this is hotfixes, which may be started from and
proposed merged into `master`. Please note that hotfixes should not
implement new functionality.
