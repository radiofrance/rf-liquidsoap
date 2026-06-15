PR Pre-release workflow — quick usage

What this does
- Builds artifacts for a PR using `make artifact VERSION=...` and creates/updates a draft prerelease attached to the PR.

How to trigger
- Automatic: the workflow triggers on `pull_request` (opened, reopened, synchronize).
- Manual: from the Actions UI choose "PR Pre-release" and use `workflow_dispatch` inputs:
  - `pr_number` (required): target PR number
  - `force_version` (optional): override the computed version, e.g. `v1.2.3`

Outputs and usage
- The workflow attaches a zip and an md5 into a draft prerelease (GitHub Releases).
- A comment is posted to the PR with the release link and an example snippet to use in `docker-compose`:

  LIQUIDSOAP_REF=<release-tag>

Local testing
- To produce the artifact locally run from repo root:

```bash
make artifact VERSION=v0.0.0-test
ls -la dist/
```
