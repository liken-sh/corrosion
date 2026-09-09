# syntax=docker/dockerfile:1

# The image this fork publishes: the corrosion binary and nothing
# else. The libraries and clusters that run it layer their own
# configuration and schema on top, so this image knows nothing about
# what it will replicate. It builds from the checkout it sits in, so
# the image is exactly the commit that the tag names.
FROM rust:1.89-bookworm@sha256:948f9b08a66e7fe01b03a98ef1c7568292e07ec2e4fe90d88c07bb14563c84ff AS build

WORKDIR /usr/src/corrosion

# The base carries the toolchain rust-toolchain.toml names, so no
# toolchain installs at build time, and it carries the C toolchain.
# .cargo/config.toml links with clang and mold, so those two packages
# are the whole of what the build adds.
RUN apt-get update \
    && apt-get install -y --no-install-recommends clang mold \
    && rm -rf /var/lib/apt/lists/*

COPY . .

# The cache mounts keep the cargo registry and the git checkouts
# between builds, so only a change to the lock file downloads again.
#
# The release profile keeps debug information, which makes the binary
# 314 MiB. The environment variable overrides that one profile
# setting, so the image carries the stripped binary and Cargo.toml
# stays as upstream wrote it.
RUN --mount=type=cache,target=/usr/local/cargo/registry --mount=type=cache,target=/usr/local/cargo/git \
    CARGO_PROFILE_RELEASE_STRIP=true cargo build --release --locked --bin corrosion

FROM gcr.io/distroless/cc-debian12@sha256:e5d81ddde149641e2a9ba55be4545bc125c67de07508b03ba4c22e6eb0ded5aa

# The runtime is distroless: a libc and nothing else, no shell and no
# tools, because an agent holds a replicated database and answers on
# its pod's network.
COPY --from=build /usr/src/corrosion/target/release/corrosion /corrosion

# The entrypoint is the bare binary, so `corrosion agent`, `corrosion
# cluster members`, and the other commands all run from this image
# with their own arguments. There is no default command, because the
# image ships no configuration for one to name.
ENTRYPOINT ["/corrosion"]
