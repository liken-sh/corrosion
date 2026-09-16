# The liken fork of Corrosion

This repository is [liken](https://liken.sh/)'s fork of
[superfly/corrosion](https://github.com/superfly/corrosion). The
liken operators run Corrosion agents as sidecars, and this fork
exists for two reasons:

1. To publish an image, `ghcr.io/liken-sh/corrosion`, that the
   operators build on. Upstream publishes binaries, not an image.
2. To run a small stack of changes in a cluster before upstream
   merges them.

It is a shallow fork, and it stays faithful to upstream. It carries
no feature or usability changes, and it never rearranges upstream's
code. Each change on the stack is one small, self-contained
performance commit. A change that anyone who runs Corrosion would
want goes upstream as a pull request; a change that serves only
liken's use stays on the stack. `AGENTS.md` states these rules.

## The branches

`main` is a mirror of upstream `main`. Nothing commits to it. A sync
is a fetch from upstream and a push:

    git fetch upstream main
    git push origin upstream/main:main

`liken` is the default branch. It is `main` plus a short stack of
commits, in this order:

1. The bottom commits add the fork's own files and nothing else:
   this directory, `AGENTS.md`, and `.github/workflows/liken.yaml`.
2. Each commit above them is one change to Corrosion. A universal
   change has a pull request against upstream, and the commit
   message names it. A liken-only change says so in its message.

Upstream's files are never edited on the bottom commits, so those
commits never conflict with a sync.

## The stack

This list is the whole state of the fork. Keep it current.

| commit | change | upstream |
|---|---|---|
| (bottom) | the fork's files: this directory, the workflow, `AGENTS.md` | never |
| 16ab652 | stream forwarders wait for events and disconnects instead of polling; adds `perf.stream_flush_timeout` | [superfly/corrosion#564](https://github.com/superfly/corrosion/pull/564) |
| de65c10 | how long a down member stays remembered and announced to becomes `gossip.remove_down_after_secs`, two days by default | [superfly/corrosion#573](https://github.com/superfly/corrosion/pull/573) |
| 8a1e823 | the buffered-change sweep clears every orphaned version at startup and on each tick, not one per five minutes | liken only |

The upstream column holds the pull request, or `liken only` for a
change that stays here.

## Adding a change

Cut the branch for the change from `main`, not from `liken`, so a
pull request carries nothing from this fork:

    git checkout -b <slug> main
    # make the change, run the tests
    git push origin <slug>

If the change is universal, open the pull request from that branch:

    gh pr create --repo superfly/corrosion --base main --head liken-sh:<slug>

Either way, put the same commit on the stack, list it in the table
above, and push:

    git checkout liken
    git cherry-pick <slug>
    git push origin liken

## Moving to a newer upstream

Sync `main`, then rebase the stack onto it. `make -C liken sync`
runs these four commands:

    git fetch upstream main
    git push origin upstream/main:main
    git rebase main liken
    git push --force-with-lease origin liken

A commit whose pull request upstream merged drops out of the stack
during the rebase. Remove its row from the table. A liken-only
commit stays until upstream makes it unnecessary.

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

`make -C liken release` picks today's next serial and runs those two
commands. `make -C liken image` builds the same image on a
workstation as `ghcr.io/liken-sh/corrosion:local`.

## The build

`liken/Dockerfile` builds in three stages with cargo-chef, so the
registry cache at `ghcr.io/liken-sh/corrosion:buildcache` keeps the
compiled dependencies between runs. A commit that touches only the
workspace's own crates compiles those crates and nothing else. A
change to `Cargo.lock` or a manifest compiles the dependencies once
more, and the next run keeps that too.

The image is distroless, not `scratch`. Corrosion embeds a prebuilt
cr-sqlite shared object and loads it at run time, and that object
needs glibc and libgcc. A static musl binary could not load it, so
the smallest base that runs it is `distroless/cc`.

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
