# Working in the liken fork of Corrosion

This is a shallow fork of superfly/corrosion. `liken/README.md`
explains the branches, the stack, and the release. Read it before
you change anything, and keep its stack table current.

## The rules

- `main` mirrors upstream. Never commit to it.
- Every change to Corrosion starts as a branch from `main` and a
  pull request to superfly/corrosion. Only then does it join the
  `liken` stack, by cherry-pick.
- The bottom commit of the stack is the only commit that touches
  fork-only files, and it touches nothing of upstream's. Do not edit
  upstream's README, workflows, or Cargo profiles there.
- Do not merge `main` into `liken`. Rebase.
- Do not tag from any branch except `liken`.
- Upstream's tests run in upstream's CI on each pull request. Before
  you open one, run the crate's own tests for the code you touched.

## Prose

Anything you write in the fork's own files, and every commit
message, follows liken's writing rules: plain, direct, expert.
Active voice, simple tenses, one topic per sentence, short words
with one meaning each. A comment says what the code does now and
why, not how it got there. A commit message is one line on what
changed, a blank line, then a short paragraph on why, with a link
to the upstream pull request.

Code that goes upstream follows upstream's conventions, not these.
