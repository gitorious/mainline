# Use cases

This directory contains implementations of certain workflows in Gitorious that
encapsulate more than a single object update. They are implemented using the
[Use Case gem](https://github.com/cjohansen/use_case).

Use cases typically consolidates several discrete updates/tasks into coherent
workflows that emplys pre-conditions and validation to ensure data consistency.
Using e.g. Gitorious model objects directly is generally not recommended,
especially not when the task to be completed has a corresponding use case
implementation.

For some tasks, Gitorious administrators can use command objects directly.
Commands are the executive part of use cases, and offer more fine-grained
control than executing full use cases.

All use cases return an "outcome" object. It has an API for determining
success/failure and helpers to base your program flow on the result. See more
about these objects at the [Use case gem](http://github.com/cjohansen/use_case).
Command objects typically return model objects, not outcomes.

## Create user

Create a new user as if registered through the site. The new user will receive
an email, and has to follow the link inside to activate before logging in.

```rb
outcome = CreateUser.new.execute({
  :login => "cjohansen",
  :fullname => "Christian Johansen",
  :email => "christian@cjohansen.no",
  :password => "correct battery staple",
  :password_confirmation => "correct battery staple",
  :terms_of_use => true
})
```

### Parameters

* `login` - Required.
* `email` - Required.
* `password` - Required.
* `password_confirmation` - Required, must match `password`.
* `terms_of_use` - Should be `true`.
* `fullname` - Optional.

## Create activated user

Creates a user that has accepted the terms of use and is activated. The new user
will not receive an email, and will be able to log in immediately. A password is
automatically generated if one is not provided.

```rb
outcome = CreateActivatedUser.new.execute({
  :login => "cjohansen",
  :fullname => "Christian Johansen",
  :email => "christian@cjohansen.no"
})

# Make a note of the password - it is only availble now. Once the object is
# re-fetched from the database, you will only see the hashed password.
outcome.result.password
```

The user can be made a Gitorious site administrator by setting the `is_admin`
parameter to `true`.

## Create OpenID user

Creates a user that logs in with OpenID. Such a user does not require a
password.

```rb
outcome = CreateOpenIdUser.new.execute({
  :login => "cjohansen",
  :email => "christian@gitorious.com",
  :fullname => "Christian Johansen",
  :identity_url => "http://my.identi.ty",
  :terms_of_use => true
})
```

## Activate user

Activate a user with an activation code:

```rb
outcome = ActivateUser.new.execute(:code => "activation code")
outcome.success? # true/false
outcome.result # User object
```

If you have a user object (as opposed to an activation code/string) that you
want to activate, you can use the underlying command directly:

```rb
user = ActivateUserCommand.new.execute(user)
```

## Update a user

```rb
```

## Add SSH key

Adds an SSH key to the datbase, and posts a message to the task queue to update
the authorized_keys file.

```rb
user = User.find_by_login("cjohansen")
outcome = CreateSshKey.new(Gitorious::App, user).execute({
  :key => "ssh-rsa bXljYWtkZHlpe..."
})
```

## Remove SSH key

Removes the SSH key and posts a message to the task queue to update the
authorized_keys file.

```rb
user = User.find_by_login("cjohansen")
outcome = DestroySshKey.new(Gitorious::App, user).execute({
  :id => user.ssh_keys.last.id
})
```

## Generate a password reset token

Generate a token for a user to reset her password, and email a reset password
link.

```rb
user = User.find_by_login("cjohansen")
outcome = GeneratePasswordResetToken.new(user).execute
```

## Reset password

Reset a user's password.

```rb
user = User.find_by_login("cjohansen")

outcome = ResetPassword.new(user).execute({
  :password => "correct battery staple",
  :password_confirmation => "correct battery staple"
})
```

## Change password

User passwords can either be set directly on the user objects, or through a use
case, which will make some additional checks:

```rb
user = User.find_by_login("dude")
user.password = user.password_confirmation = "passw0rd!!"
user.save

# ...or:

outcome = ChangePassword.new(user).execute({
  :current_password => "password",
  :password => "battery horse staple",
  :password_confirmation => "battery horse staple"
})
```

## Create project

Create a new project. Adds the project to the database, sets up merge request
statuses, and adds a project wiki.

```rb
user = User.find_by_login("cjohansen")
outcome = CreateProject.new(Gitorious::App, user).execute({
  :title => "My project",
  :slug => "my-project",
  :description => "An awesome project",
  :license => "MIT"
})
```

### Parameters

* `title` - Project name. Required.
* `slug` - Slug/URL name. Required.
* `license` - The project license, as a string. Required.
* `description` - Project description. Optional.
* `default_merge_request_status_id` - Optional.
* `owner_type` - Set to "Group" if project should be owned by a group. Optional.
* `owner_id` - Id of group to own project. Required if `owner_type` is "Group".
* `private` - Set to `true` to make project private (i.e. only readable by its
  owner(s)). Only works if private projects/repositories is enabled on this
  Gitorious instance.
* `home_url` - Project website. Optional.
* `mailinglist_url` - Project mailing list. Optional.
* `bugtracker_url` - Project bug tracker. Optional.
* `tag_list` - A space-separated list of tags. Optional.
* `wiki_enabled` - Set to `false` if a project wiki is not desired. The
  repository will be created anyway, but not made available through the website.
* `site_id` - If this project belongs to a specific site, specify the id here.
  Optional.

## Create project repository

Create a new repository. Adds the repository to the database, and schedules the
creation of the repository on disk via the task queue.

```rb
project = Project.find_by_slug("gitorious")
user = User.find_by_login("cjohansen")

outcome = CreateProjectRepository.new(Gitorious::App, project, user).execute({
  :name => "gitorious"
})
```

### Parameters

* `name` - Repository name. Required.
* `description` - Repository description. Markdown supported. Optional.
* `merge_requests_enabled` - Set to `false` to disable merge requests. Optional,
  defaults to `true`.
* `private` - Set to `true` to make repository private, i.e. readable only by
  its owner(s). Only works when Gitorious private repositories are enabled.
  Optional, defaults to the corresponding property of the parent project.

### Prepare creating a project repository

The controller action that allows users to create a new repository uses the
`PrepareProjectRepository` use case to "dry run" a repository creation, so every
default etc are the same for the "new" form as well as when creating.

## Reposting the repo creation message

Occasionally, repositories will "get stuck" - i.e. the repository is created in
the database, and the creation message is put on the queue. However, it is not
successfully processed, and the repository remains unavailable on disk. When
this happens, you can use the `CreateRepositoryCommand` to republish the task to
the queue:

```rb
repo = Repository.find_by_name("gitorious")
CreateRepositoryCommand.new.schedule_creation(repo)
```

## Clone repository

Create a clone/fork of a repository for a specific user or group.

```rb
repository_to_clone = Repository.find_by_name("gitorious")
uc = CloneRepository.new(Gitorious::App, repository_to_clone, user)

# Creating a user clone
user = User.find_by_login("cjohansen")
outcome = uc.execute({ :name => "my_gitorious_clone" })

# Creating a group clone
group = Group.find_by_name("a_team")
outcome = uc.execute({
  :owner_type => "Group",
  :owner_id => group.id
})
```

### Parameters:

* `login` - if provided, name will default to "#{login}'s-#{repo_name}". Optional.
* `owner_type` - set to "Group" if owner is a group. Optional.
* `owner_id` - group id if `owner_type` is "Group". Optional.
* Repository params (see "create project repository" below)

### Preparing a repository clone

The controller action that displays the form to create a new repository clone
uses this use case, which does everything the clone repository use case does,
except for saving to the database.

```rb
uc = PrepareRepositoryClone.new(Gitorious::App, repository, user)
uc.result #=> Repository object, built like it would be built by CloneRepository
```

## Add user to group (create membership)

Makes a user member of a group with a specific role.

```rb
group = Group.find_by_name("gitorians")
outcome = CreateMembership.new(Gitorious::App, group, group.owner).execute({
  :login => "cjohansen",
  :role_name => Role::ADMIN
})
```

### Parameters:

* `login` - Login of the user to add as a member. Optional.
* `user_id` - Id of user to add as a member. Optional.
* `role` - Id of role to add member with. Optional.
* `role_name` - Name of role to add member with. Optional.

Either `login` or `user_id` is required. Either `role` or `role_name` is
required.


## List committers

Get a list of all committers on a repository, filtered for a user.

```rb
repository = Repository.find_by_name("gitorious")
user = User.find_by_login("cjohansen")
outcome = ListCommitters.new(Gitorious::App, repository, user).execute
committers = outcome.result
```

## List mainlines

List all "mainlines" (repositories that are not clones) in a project that a user
has access to. If private repositories is not enabled, this will be all the
repository mainlines.

```rb
project = Project.find_by_title("gitorious")
user = User.find_by_login("cjohansen")
outcome = ListMainlines.new(Gitorious::App, project, user).execute
repositories = outcome.result
```

## Determine if repository is writable be user

```rb
repository = Repository.find_by_name("gitorious")
outcome = RepositoryWritableBy.new(Gitorious::App, repository).execute({
  :login => "cjohansen"
})
can_write = outcome.result #=> true/false
```

## Search repository clones

Search for repository clones, and return only clones that the user has access
to. If private repositories are disabled, then this will be every clone that
matches the criteria.

```rb
user = User.find_by_login("cjohansen")
repository = Repository.find_by_name("gitorious")
outcome = SearchClonesCommand.new(Gitorious::App, repository, user).execute({
  :filter => "something"
})
clones = outcome.result
```

## Create web hook

Create a web hook either for a specific repository or globally for the whole
site. Only site admins are allowed to create site-wide global hooks.

```rb
user = User.find_by_login("cjohansen")
repository = Repository.find_by_name("gitorious")
CreateWebHook.new(Gitorious::App, repository, user).execute({
  :url => "http://somewhere.com"
  # :site_wide => true #=> In this case, the repository connection is ignored
})
```
