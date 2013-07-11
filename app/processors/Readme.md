# Asynchronous task processors

Gitorious performs some heavy lifting by posting a message to a task queue, and
have them processed asynchronously by worker processes. Gitorious supports
several backends, which are configured through `lib/gitorious/messaging.rb`

The sync and resque adapters both load the classes in this directory to perform
the actual work.

## DestroySshKeyProcessor

When a user deletes an SSH key, this processor will eventually make sure that
the authorized_keys file is updated accordingly.

## MergeRequestGitBackendProcessor

When merge requests are deleted, this processor is invoked to actually delete
the tracking repository from the file system.

## MergeRequestProcessor

When creating merge requests, this processor is invoked to create the tracking
repository on disk and push the initial version to it.

## MergeRequestVersionProcessor

When a specific merge request version is deleted, this processor is invoked to
remove the belonging branch from the tracking repositories.

## MessageForwardingProcessor

Sends various email notifications to users.

## NewSshKeyProcessor

When a user uploads a new SSH key, this processor is invoked to update the
`authorized_keys` file accordingly.

## ProjectRepositoryCreationProcessor

When a new project repository is created, this processor is invoked to actually
create and initialize the git repository on disk.

## PushProcessor

When the Gitorious server receives a push, this processor is invoked to create
corresponding events in the database, like "John Doe pushed 4 commits to
repo:master".

## RepositoryCloningProcessor

When a repository is cloned on Gitorious (e.g. "forked"/copied, not `git
clone`), this processor is in charge of using `git` to create the clone on disk.
The clone uses hardlinks to improve disk usage.

## RepositoryDeletionProcessor

When a repository is deleted, this processor removes the files on disk.

## TrackingRepositoryCreationProcessor

When someone creates a merge request, this processor creates a "tracking
repository" on disk. The tracking repository is basically a clone of the target
repository that keeps the merge request in a branch so Gitorious can use git to
find diffs etc.

## WebHookProcessor

Publish a change-set to all web hooks registered both site-wide and for the
individual repository being pushed to.

## WikiRepositoryCreationProcessor

Create wiki repository on disk. Triggered whenever projects are created.
