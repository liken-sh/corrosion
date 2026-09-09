# Working in the liken fork of Corrosion

This is a shallow fork of superfly/corrosion. `liken/README.md`
explains the branches, the stack, and the release. Read it before
you change anything, and keep its stack table current.

## What the fork is for

The fork exists to control the image build and to carry performance
improvements. That is all. Do not make feature or usability changes
here. When a change is not about the build or about performance, it
does not belong on the stack, whatever its merit.

Stay faithful to upstream. Do not move, rename, or restructure
upstream's code. Every commit on the stack has to rebase cleanly
onto the next upstream main, and a rearranged tree never does.

Land each performance change as one small, self-contained commit
that a maintainer could read and merge on its own. No sprawl across
crates, no drive-by cleanups in the same commit.

Send a change upstream only when it is universal: valuable to anyone
who runs Corrosion, not only to liken. A change that serves liken's
sidecar shape alone stays on the stack as a liken-only commit. Do
not send maintainers work that only we want.

## The rules

- `main` mirrors upstream. Never commit to it.
- A change to Corrosion starts as a branch from `main`. If it is
  universal, open a pull request to superfly/corrosion from that
  branch. Either way it joins the `liken` stack by cherry-pick, and
  its row in the README's stack table says which.
- The bottom commits of the stack are the only commits that touch
  fork-only files, and they touch nothing of upstream's. Do not edit
  upstream's README, workflows, or Cargo profiles there.
- Do not merge `main` into `liken`. Rebase.
- Do not tag from any branch except `liken`.
- Run the crate's own tests for the code you touched before it joins
  the stack. Upstream's CI runs the full suite on a pull request; a
  liken-only commit has no CI but yours.

## Prose

Anything you write in the fork's own files, and every commit
message, follows liken's writing rules: plain, direct, expert.
Active voice, simple tenses, one topic per sentence, short words
with one meaning each. A comment says what the code does now and
why, not how it got there. A commit message is one line on what
changed, a blank line, then a short paragraph on why, with a link
to the upstream pull request.

Code that goes upstream follows upstream's conventions, not these.
