# syntax=docker/dockerfile:1

# The image this fork publishes: the corrosion binary and nothing
# else. The libraries and clusters that run it layer their own
# configuration and schema on top, so this image knows nothing about
# what it will replicate. The checkout is the build context, so the
# image is exactly the commit that the tag names.
#
# The build is in three stages so that the image cache keeps the
# dependencies. A planner stage reduces the tree to a recipe of its
# manifests; a build stage compiles every dependency from that
# recipe, then copies the source in and compiles the workspace. The
# recipe changes only when a manifest or the lock file changes, so a
# commit to the workspace's own crates reuses the dependency layer
# from the registry cache and compiles only those crates.
FROM rust:1.89-bookworm@sha256:948f9b08a66e7fe01b03a98ef1c7568292e07ec2e4fe90d88c07bb14563c84ff AS chef

# The base includes the toolchain rust-toolchain.toml names, so no
# toolchain installs at build time, and it includes the C toolchain.
# .cargo/config.toml links with clang and mold, so those two packages
# are the whole of what the build adds.
RUN apt-get update \
    && apt-get install -y --no-install-recommends clang mold \
    && rm -rf /var/lib/apt/lists/*

# The cache mounts preserve the crate registry and the git checkouts
# between builds on a workstation. A runner starts empty, and the
# registry cache of the image layers is what preserves the work there.
RUN --mount=type=cache,target=/usr/local/cargo/registry --mount=type=cache,target=/usr/local/cargo/git \
    cargo install cargo-chef --locked --version 0.1.78

WORKDIR /usr/src/corrosion

FROM chef AS planner
COPY . .
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS build

# The linker settings and the toolchain pin come before the cook, so
# the dependencies compile with the flags the final build uses. A
# dependency built with other flags would compile a second time.
COPY .cargo .cargo
COPY rust-toolchain.toml .
COPY --from=planner /usr/src/corrosion/recipe.json recipe.json

# Upstream's release profile keeps debug information, which makes the
# binary 314 MiB. The environment variable overrides that one profile
# setting in both cargo runs, so the image contains the stripped binary
# and Cargo.toml remains as upstream wrote it.
RUN --mount=type=cache,target=/usr/local/cargo/registry --mount=type=cache,target=/usr/local/cargo/git \
    CARGO_PROFILE_RELEASE_STRIP=true cargo chef cook --release --locked --bin corrosion --recipe-path recipe.json

COPY . .
RUN --mount=type=cache,target=/usr/local/cargo/registry --mount=type=cache,target=/usr/local/cargo/git \
    CARGO_PROFILE_RELEASE_STRIP=true cargo build --release --locked --bin corrosion

# The runtime is distroless: a libc, libgcc, and nothing else, no
# shell and no tools, because an agent stores a replicated database
# and serves requests over its pod's network. It is not `scratch`,
# because the binary contains a prebuilt cr-sqlite shared object and
# loads it at run time, and that object links against
# glibc and libgcc. A static musl binary could not load it.
FROM gcr.io/distroless/cc-debian12@sha256:e5d81ddde149641e2a9ba55be4545bc125c67de07508b03ba4c22e6eb0ded5aa

COPY --from=build /usr/src/corrosion/target/release/corrosion /corrosion

# The entrypoint is the bare binary, so `corrosion agent`, `corrosion
# cluster members`, and the other commands all run from this image
# with their own arguments. There is no default command, because the
# image ships no configuration for one to name.
ENTRYPOINT ["/corrosion"]
