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
FROM rust:1.99.1-trixie@sha256:09027f873d45b8ecd1dc86f1fa13b7a62b875c961f017a0e331267b350430137 AS chef

# The builder runs on the same Debian release as the runtime below,
# because the binary links against the builder's glibc and a newer
# glibc than the runtime's fails to load. The base includes the C
# toolchain. .cargo/config.toml links with clang and mold, so those
# two packages are the whole of what the build adds.
#
# The base's Rust is the version that liken's own crates build with.
# Upstream's rust-toolchain.toml names an older channel, and rustup
# would install that channel at build time. RUSTUP_TOOLCHAIN overrides
# the file, so the build uses the base's toolchain and installs none,
# and the file remains as upstream wrote it.
ENV RUSTUP_TOOLCHAIN=1.99.1
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

# The linker settings and the toolchain file come before the cook, so
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
FROM gcr.io/distroless/cc-debian13@sha256:d74d144baa124dd9defd01d71872bb56c49d4441dba6153ccf790364f97e64b1

COPY --from=build /usr/src/corrosion/target/release/corrosion /corrosion

# The entrypoint is the bare binary, so `corrosion agent`, `corrosion
# cluster members`, and the other commands all run from this image
# with their own arguments. There is no default command, because the
# image ships no configuration for one to name.
ENTRYPOINT ["/corrosion"]
