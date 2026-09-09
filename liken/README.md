# The liken fork of Corrosion

This repository is [liken](https://liken.sh/)'s fork of
[superfly/corrosion](https://github.com/superfly/corrosion). The
liken operators run Corrosion agents as sidecars, and this fork
exists for two reasons:

1. To publish an image, `ghcr.io/liken-sh/corrosion`, that the
   operators build on. Upstream publishes binaries, not an image.
2. To run a small stack of changes in a cluster before upstream
   merges them.

It is a shallow fork. Every change on it is on its way upstream, and
the fork carries nothing that upstream would refuse.

## The branches

`main` is a mirror of upstream `main`. Nothing commits to it. A sync
is a fetch from upstream and a push:

    git fetch upstream main
    git push origin upstream/main:main

`liken` is the default branch. It is `main` plus a short stack of
commits, in this order:

1. The bottom commit adds the fork's own files and nothing else:
   this directory, `AGENTS.md`, and `.github/workflows/liken.yaml`.
2. Each commit above it is one change to Corrosion, and each one has
   an open pull request against upstream. The commit message names
   the pull request.

Upstream's files are never edited on the bottom commit, so that
commit never conflicts with a sync.

## The stack

This list is the whole state of the fork. Keep it current.

| commit | change | upstream |
|---|---|---|
| (bottom) | the fork's files | never |

## Adding a change

Cut the branch for the change from `main`, not from `liken`, so the
pull request carries nothing from this fork:

    git checkout -b <slug> main
    # make the change, run the tests
    git push origin <slug>
    gh pr create --repo superfly/corrosion --base main --head liken-sh:<slug>

Then put the same commit on the stack, list it in the table above,
and push:

    git checkout liken
    git cherry-pick <slug>
    git push origin liken

## Moving to a newer upstream

Sync `main`, then rebase the stack onto it:

    git fetch upstream main
    git push origin upstream/main:main
    git rebase main liken
    git push --force-with-lease origin liken

A commit whose pull request upstream merged drops out of the stack
during the rebase. Remove its row from the table.

The `liken` branch is the one branch in the liken organization that
rewrites its history, because a stack has to move. The clusters pin
images by digest, so a rewrite moves nothing that runs.

## Releasing

A pushed tag is a release. The tag names a version in liken's
calendar scheme, `2026.09.09-001`, and the workflow builds
`liken/Dockerfile` and pushes the image under that tag and
`:latest`. A push to `liken` builds a development image,
`2026.09.09-001-dev-002-abcdef01`, and pushes only that version.

    git tag 2026.09.09-001
    git push origin 2026.09.09-001

A consumer pins the image by digest, and the digest moves only when
the consumer chooses to move it. So a Corrosion change reaches a
cluster in two releases: one here, then one in the operator that
carries the new digest.

## Upstream's workflows

Upstream's workflows stay in the tree so that a sync never
conflicts, and they are disabled in this repository's Actions
settings. `liken.yaml` is the only workflow that runs here. A sync
that brings a new upstream workflow needs one more `gh workflow
disable`.

## Dropping back to upstream

Every consumer can point at an image built from `main`, which is
upstream with no stack, with one edit to its Dockerfile. Do that
first when a bug looks like it could be ours.
