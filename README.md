









[![License](https://img.shields.io/badge/license-MIT-green.svg)](https://github.com/denistreshchev/takes/CodeLonia/master/LICENSE.txt)


CodeLonia is an open source incubator. We want to build
a community of developers to simplify the workflow and select the most
interesting _emerging_ open source projects. According to
the selection made by the community we want to donate
our funds to the most promising teams and projects.






    









## How to contribute



your pull request. You will need to have [Ruby](https://www.ruby-lang.org/en/) 2.3+,
Java 8+, Maven 3.2+, PostgreSQL 10+, and
[Bundler](https://bundler.io/) installed. Then:

```bash
$ bundle update
$ bundle exec rake
```

If it's clean and you don't see any error messages, submit your pull request.

To run a single unit test you should first do this:

```bash
$ bundle exec rake run
```

And then, in another terminal (for example):

```bash
$ ruby test/test_risks.rb -n test_adds_and_fetches
```

If you want to test it in your browser, open `http://localhost:9292`. If you
want to login as a test user, just open this: `http://localhost:9292?glogin=test`.

Should work.
