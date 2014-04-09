# Gitorious.org

Gitorious is a web application for hosting, managing and contributing on Git
repositories.

# Contributing

Please see HACKING

# License

Please see the LICENSE file

# Performing tasks on the command line

Gitorious 3 ships with a set of high-level abstractions called use cases and
commands. These can be used to carry out many tasks e.g. from the command-line.
Using the use cases ensures that every step of a certain task is carried out,
and you don't end up with inconsistent data. See the app/use_cases directory
for further information.

# Installation

To install Gitorious locally visit [getgitorious.com](http://getgitorious.com).

# Messaging server

Many Gitorious operations are performed asynchronously to ensure good
performance. Examples of such tasks includes updating the database when pushing
to Gitorious, creating bare git repositories when creating repositories in the
web UI and more. To process these asynchronous actions, Gitorious uses a
messaging system where it sends messages to a queue, and a worker (i.e. another
process, usually some kind of daemon) fetches messages back for processing.

Gitorious provides several messaging implementations ("adapters"). The
alternatives along with how to install and run them are presented below. You
only need one of these alternatives.

## Sync adapter

Processes messages synchronously, which means that no extra process is
required. This is a very simple solution, but will yield poor performance. It's
intended use is for development, but may also fit small setups where performance
is not an issue (e.g. if resources are scarce). To use it, simply set
messaging_adapter in gitorious.yml to "sync":

  messaging_adapter: sync

## Resque adapter

Resque uses Redis as a backend for messaging. It comes with a nice
administration interface that allows for resending of messages, introspection
and general statistics about your queue. To use it, set messaging_adapter to
"resque" in gitorious.yml:

    messaging_adapter: resque

To use Resque, you need to install and run Redis. This is described in detail on
the official Resque page: https://github.com/resque/resque

To process messages from the queue with Resque, you need to run rake:

    RAILS_ENV=production QUEUE=* bin/rake resque:work

You can also run a worker for a single, or a handful of queues too. This allows
you to assign different priority to different queues. The list of queues in use
can be found in lib/gitorious/messaging/resque_adapter.rb.

Note that Gitorious generally uses JMS style queue names, e.g.
/queue/GitoriousPostReceiveWebHook. Because the Resque web frontend does not
handle queue names with slashes in them, we strip queue names such that the
aforementioned queue will be named GitoriousPostReceiveWebHook under Resque.


# More Help

* Consult the mailinglist (http://groups.google.com/group/gitorious) or drop
  by #gitorious on irc.freenode.net if you have questions.


# Gotchas

Gitorious will add a 'forced command' to your ~/.ssh/authorized_keys file for
the target host: if you start finding ssh oddities suspect this first. Don't
log out until you've ensured you can still log in remotely.
