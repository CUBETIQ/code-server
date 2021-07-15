#!/usr/bin/env bash
set -euo pipefail

main() {
  cd "$(dirname "$0")/../.."
  source ./ci/lib.sh

  download_artifact release-images ./release-images
  if [[ ${CI-} ]]; then
    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
  fi

  for img in ./release-images/*; do
    docker load -i "$img"
  done

  # We have to ensure the amd64 and arm64 images exist on the remote registry
  # in order to build the manifest.
  # We don't put the arch in the tag to avoid polluting the main repository.
  # These other repositories are private so they don't pollute our organization namespace.
  docker push "cubetiq/code-server-amd64:$VERSION"
  docker push "cubetiq/code-server-arm64:$VERSION"

  export DOCKER_CLI_EXPERIMENTAL=enabled

  docker manifest create "cubetiq/code-server:$VERSION" \
    "cubetiq/code-server-amd64:$VERSION" \
    "cubetiq/code-server-arm64:$VERSION"
  docker manifest push --purge "cubetiq/code-server:$VERSION"

  docker manifest create "cubetiq/code-server:latest" \
    "cubetiq/code-server-amd64:$VERSION" \
    "cubetiq/code-server-arm64:$VERSION"
  docker manifest push --purge "cubetiq/code-server:latest"
}

main "$@"
