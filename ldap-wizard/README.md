# Gitorious LDAP configuration wizard

This is a basic Sinatra app which can be used to interactively set up
LDAP authentication for your Gitorious server. It loads the current
authentication configuration for your Gitorious server and lets you
try authenticating with a username and password.

You can gradually make changes to the configuration in the web wizard
until you've created a configuration which works for your setup. The
wizard also displays what your `authentication.yml` file should look
like to reproduce the configuration once it's working.

## Starting the configuration wizard

To start the wizard, open a terminal and enter the following

```
cd /var/www/gitorious/app/ldap-wizard
ruby wizard.rb
```

This will start a web server on port 1337 on your machine, and you
start out by visiting [this URL](http://localhost:1337/) in your
browser. If you haven't already done so, do it now, and you will find
this page in your browser.

Now, visit [the wizard form](/begin) to start working with the wizard.
Assuming you have an`config/authentication.yml` in your
Gitorious root directory, the form should be pre-populated for you. If
you run into any kind of errors, you will see this README with an
error message at the top of the page.

## Trying out your configuration

As mentioned above, this wizard will start off by loading the current
configuration from your Gitorious installation. Any changes you make
will be brought along to the next page, but you may restart at any
time by visiting [the /begin page](/begin). By doing so any changes
you made will be lost. **The wizard will not make any changes to your
authentication file, but it will let you copy a working configuration
for you to paste into the configuration file.**

Once you've succeeded in getting a working configuration, simply copy
the YAML shown on the page into your `config/authentication` file and
you're all set.

It will probably take a little fiddling to get your authentication
just right, but just keep trying until you succeed. LDAP is hard, and
everyone struggles a little with getting all the pieces right.

## Testing authentication using curl

For you die-hard CLI people out there, you can use curl to test your
configuration. This will use your configuration file only, and only
accepts a username and password as its parameters. To use it, type
something along these lines:

```
curl -X POST localhost:1337/check -d "username=john&password=sikret"
```

and the app will respond with a HTTP 200 if authentication succeeded,
otherwise a HTTP 403.

## What isn't supported yet

There are a few things planned for this wizard which aren't quite done
yet:

* Specifying mapping of attributes between LDAP and Gitorious
* Displaying the attributes for the authenticated user
