# OpenCost UI Container Image

Builds the OpenCost UI container image from upstream source with DKP-specific configurations.

## Overview

This image builds from the upstream `opencost/opencost-ui` source code using their existing Dockerfile with custom build arguments. The main customization is setting the `ui_path` for NKP routing patterns. See details: https://github.com/opencost/opencost-ui/pull/106

## Build Arguments

- `ui_path`: UI path configuration for the OpenCost frontend (default: `/dkp/opencost/frontend`)

## Usage

### Using the Build from Source Workflow

This image should be built using the `build-from-source.yaml` workflow:

1. Navigate to Actions → "Build image from source"
2. Run workflow with parameters:
   - **source-repo**: `opencost/opencost-ui`
   - **source-version**: Version tag (e.g., `1.119.2`)
   - **platforms**: `linux/amd64,linux/arm64` (workflow default; required for arm64 workload clusters)
   - **push**: Enable to push to registry

Build arguments are automatically extracted from the Makefile. The image tag is derived from `source-version` (leading `v` stripped), e.g. `ghcr.io/nutanix-cloud-native/dkp-container-images/opencost/opencost-ui:1.119.2`.

### Local Testing

```bash
# Clone upstream repository
git clone https://github.com/opencost/opencost-ui.git
cd opencost-ui

# Build with DKP configuration
docker build --build-arg ui_path=/dkp/opencost/frontend -t opencost-ui:test .
```

## Target Image

`ghcr.io/nutanix-cloud-native/dkp-container-images/opencost/opencost-ui:<version>`
