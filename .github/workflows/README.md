# GitHub workflows

## Pre-release workflow

This workflow can be triggered manually on a branch or tag using the `workflow_dispatch` event.
It builds artifacts for the branch or tag using the `make artifact` command and creates/updates a draft pre-release, attaching the built artifacts to it.

## Release workflow

This workflow uses [Release Please](https://github.com/googleapis/release-please) to automate CHANGELOG generation, GitHub releases, and version bumps.

### How it works

Release Please monitors the git history for [Conventional Commit](https://www.conventionalcommits.org/) messages and maintains **Release PRs** that track changes since the last release.

Rather than continuously releasing what's landed to the master branch,
release-please maintains release PRs:

These Release PRs are kept up-to-date as additional work is merged. When we're
ready to tag a release, we can simply merge the release PR. Both squash-merge and
merge commits work with Release PRs.

When the Release PR is merged, release-please takes the following steps:

1. Updates the `CHANGELOG.md` and `package.json` files.
2. Tags the commit with the version number
3. Creates a GitHub Release based on the tag
4. Uploads the built artifacts to the GitHub Release

### Release PR lifecycle

We can tell where the Release PR is in its lifecycle by the status label on the PR itself:

- `autorelease: pending` is the initial state of the Release PR before it is merged
- `autorelease: tagged` means that the Release PR has been merged and the release has been tagged in GitHub
- `autorelease: snapshot` is a special state for snapshot version bumps
- `autorelease: published` means that a GitHub release has been published based on the Release PR (_release-please does not automatically add this tag, but we recommend it as a convention for publication tooling_).

### How should we write our commits?

Release Please assumes we are using [Conventional Commit messages](https://www.conventionalcommits.org/).

The most important prefixes we should have in mind are:

- `fix:` which represents bug fixes, and correlates to a [SemVer](https://semver.org/)
  patch.
- `feat:` which represents a new feature, and correlates to a SemVer minor.
- `feat!:`, or `fix!:`, `refactor!:`, etc., which represent a breaking change
  (indicated by the `!`) and will result in a SemVer major.
