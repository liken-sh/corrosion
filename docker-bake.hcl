# The OCI keys of every image this repository publishes. CI fills the
# variables from the commit it builds, and `docker buildx bake --push`
# writes each key as a config label and as an annotation on the image
# index and each image manifest. The keys live here and not in the
# Dockerfile, so a change to a key invalidates no layer cache, and a
# fork that builds the Dockerfile on its own does not claim to be this
# repository's image.

# SOURCE is the repository's URL, REVISION the commit, VERSION the
# release or development version, and CREATED the commit's committer
# time in RFC 3339. A local build leaves them empty, and an empty key
# is left out.
variable "SOURCE" { default = "" }
variable "REVISION" { default = "" }
variable "VERSION" { default = "" }
variable "CREATED" { default = "" }

# The keys that are the same for every image of the repository.
variable "URL" { default = "https://liken.sh" }
variable "LICENSES" { default = "Apache-2.0" }
variable "VENDOR" { default = "liken" }

# oci returns the keys of one image: the commit's keys, the
# repository's keys, and the image's own keys, with the image's keys
# last so that they win. A commit key that is empty is left out, so a
# local build writes no source, revision, version, or created. Any
# other key that is "" is written as "", which replaces a label of the
# same key that the base image set.
function "oci" {
  params = [image]
  result = { for key, value in merge(
    { for key, value in {
      source   = SOURCE
      revision = REVISION
      version  = VERSION
      created  = CREATED
    } : key => value if value != "" },
    {
      url      = URL
      licenses = LICENSES
      vendor   = VENDOR
    },
    image,
  ) : "org.opencontainers.image.${key}" => value }
}

# oci_labels and oci_annotations write the keys of oci at the two
# places that readers look: the config, which docker inspect, syft,
# and Trivy read, and the index and manifests, which ghcr.io reads for
# a multi-platform image. A label passes into every image built FROM
# this one and an annotation does not, so a downstream image keeps
# none of these annotations.
function "oci_labels" {
  params = [image]
  result = oci(image)
}

# A local build with --load exports no image index, and BuildKit refuses
# an index annotation there, so only a CI build, which sets REVISION,
# writes annotations.
function "oci_annotations" {
  params = [image]
  result = REVISION == "" ? [] : [for key, value in oci(image) : "index,manifest:${key}=${value}"]
}

# The syft scanner image that buildx runs to write the SBOM, pinned by
# digest at the same version and digest as the pin in the liken
# repository's toolchains/images.toml. Follow that pin. Without it,
# buildx pulls its default scanner by a moving tag, and the program
# that writes the SBOM would change with no change to this tree.
variable "SYFT_SCANNER" {
  default = "docker/buildkit-syft-scanner:1.12.1@sha256:873a7458c3c8ac8e32c7b796c10e1600b07b963d2aa000a72a2d97aaaa2d6315"
}

# LATEST is "true" when the build is a release, which moves the
# :latest tag. A development build pushes only its own version, so
# :latest always names a release.
variable "LATEST" { default = "false" }

variable "corrosion" {
  default = {
    title         = "corrosion"
    description   = "Corrosion, the gossip-based replicated SQLite database, built from liken's fork for the operators that run it as a sidecar"
    documentation = "https://github.com/liken-sh/corrosion/blob/liken/liken/README.md"
  }
}

# The context is the whole checkout, because the Dockerfile compiles
# the tree it sits in. A local build is for one platform and tags
# :local. A CI build, which sets REVISION, also writes the cache,
# the SBOM, and the provenance. Docker's image store keeps no
# attestations, so a build that loads the image into Docker writes
# none, and the workflow loads one build to prove the image and then
# pushes another. The push reuses every layer of the first build, so
# nothing compiles twice. The SBOM comes from the crates that
# `cargo auditable` records in the binary and from the base's
# packages, and the provenance in max mode records the Dockerfile,
# the context's commit, and the digest of each base image.
target "corrosion" {
  context    = "."
  dockerfile = "liken/Dockerfile"
  platforms  = ["linux/amd64"]
  tags = compact([
    "ghcr.io/liken-sh/corrosion:${VERSION == "" ? "local" : VERSION}",
    LATEST == "true" ? "ghcr.io/liken-sh/corrosion:latest" : "",
  ])
  labels      = oci_labels(corrosion)
  annotations = oci_annotations(corrosion)
  cache-from  = ["type=registry,ref=ghcr.io/liken-sh/corrosion:buildcache"]
  cache-to    = REVISION == "" ? [] : ["type=registry,ref=ghcr.io/liken-sh/corrosion:buildcache,mode=max"]
  attest = REVISION == "" ? [] : [
    "type=sbom,generator=${SYFT_SCANNER}",
    "type=provenance,mode=max",
  ]
}
