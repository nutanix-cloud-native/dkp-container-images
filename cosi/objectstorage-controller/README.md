# objectstorage-controller

COSI `objectstorage-controller` image published as
`ghcr.io/nutanix-cloud-native/dkp-container-images/objectstorage-controller:<tag>`.

## Build from the internal Nutanix fork

Production builds of Nutanix-forked COSI should use **Actions → Build image from a Nutanix fork**:

- **preset:** `cosi-controller`
- **source-version:** a git ref in [`nutanix-cloud-native/container-object-storage-interface`](https://github.com/nutanix-cloud-native/container-object-storage-interface) that **contains `nutanix`** (e.g. `v0.2.2-nutanix.1`). Refs without `nutanix` are rejected so this workflow cannot overwrite upstream-versioned tags.
- **platforms:** default `linux/amd64`
- **push:** set to `true` to publish to GHCR

The workflow checks out the private fork with a GitHub App token, then builds `controller/Dockerfile` with context at the fork repo root.

Target image: `ghcr.io/nutanix-cloud-native/dkp-container-images/objectstorage-controller:<source-version>`

## Legacy: re-wrap an upstream image

A custom build of `gcr.io/k8s-staging-sig-storage/objectstorage-controller` (that registry is being shut down: https://console.cloud.google.com/gcr/images/k8s-staging-sig-storage/global/objectstorage-controller).

The Dockerfile is based on the upstream project https://github.com/kubernetes-sigs/container-object-storage-interface/blob/main/controller/Dockerfile.

Local rebuild of the re-wrap:

```shell
make docker-build
```

This path is not used by **Build image from a Nutanix fork**. To rebuild a re-wrapped image via CI, use **Actions → Rebuild image** with directory `cosi/objectstorage-controller`.
