# Micro SimpleCov

Marks lines that do not have code coverage in the micro editor for Ruby projects
using SimpleCov.

This plugin uses the "Gutter Message" feature in micro. Lines without coverage
will have a red `>>` to the left of the line numbers after save.

Files that aren't listed in SimpleCov's coverage file will be ignored, so you
won't see files that don't require test coverage marked up.

## Installation

`plugin install micro_simplecov`

## Caveat - Only works for projects in git repositories

SimpleCov stores coverage results from the last test run in a file located at
`/coverage/.resultset.json`, relative to the root of your project directory.

I couldn't think of a good way to find the project directory outside of git
(using `git rev-parse`), so unfortunately this project only works in directories
that fall within a git repo. Suggestions or pull requests with alternative
solutions are very welcome!