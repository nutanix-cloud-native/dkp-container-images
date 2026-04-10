# NKP image promotion

This directory contains build contexts used by the `Promote internal image`
workflow to promote internal images to public GHCR images while injecting a
component-specific notices file into `/NOTICES/` in the target image.

## Components

- `cloud-provider-nutanix` (CCM)
- `cluster-api-provider-nutanix` (CAPX)
- `cluster-api-runtime-extensions-nutanix` (CAREN controller)
- `cluster-api-runtime-extensions-helm-chart-bundle-initializer` (CAREN initializer)

Each component must contain exactly one non-hidden file in its `NOTICES/`
directory at workflow runtime.

## Operating model

1. Create/update a branch and add the component notice file under:
   - `nkp/<component>/NOTICES/<notice-file>`
2. Ensure that the component's `NOTICES/` directory has exactly one non-hidden
   file (dotfiles such as `.gitkeep` are ignored by the workflow check).
3. Trigger GitHub Actions workflow `Promote internal image` with:
   - `component`: one of CCM/CAPX/CAREN component values
   - `version`: image version/tag only
4. Verify the promoted image contains `/NOTICES/<notice-file>`.

The workflow uses fixed Harbor sources and fixed GHCR target image names:

- `cloud-provider-nutanix`:
  - source: `harbor.eng.nutanix.com/ncn-prerelease/internal-cloud-provider-nutanix/controller:<version>`
  - target: `ghcr.io/<owner>/dkp-container-images/nkp-cloud-provider-nutanix:<version>`
- `cluster-api-provider-nutanix`:
  - source: `harbor.eng.nutanix.com/ncn-prerelease/internal-cluster-api-provider-nutanix:<version>`
  - target: `ghcr.io/<owner>/dkp-container-images/nkp-cluster-api-provider-nutanix:<version>`
- `cluster-api-runtime-extensions-nutanix`:
  - source: `harbor.eng.nutanix.com/ncn-prerelease/internal-cluster-api-runtime-extensions-nutanix:<version>`
  - target: `ghcr.io/<owner>/dkp-container-images/nkp-cluster-api-runtime-extensions-nutanix:<version>`
- `cluster-api-runtime-extensions-helm-chart-bundle-initializer`:
  - source: `harbor.eng.nutanix.com/ncn-prerelease/internal-cluster-api-runtime-extensions-helm-chart-bundle-initializer:<version>`
  - target: `ghcr.io/<owner>/dkp-container-images/nkp-cluster-api-runtime-extensions-helm-chart-bundle-initializer:<version>`

## Suggested validation per component

Run one workflow dispatch for each component independently:

- CCM: `component=cloud-provider-nutanix`
- CAPX: `component=cluster-api-provider-nutanix`
- CAREN controller: `component=cluster-api-runtime-extensions-nutanix`
- CAREN initializer: `component=cluster-api-runtime-extensions-helm-chart-bundle-initializer`

After each run:

1. Pull the target image.
2. Start a shell in the image and confirm files under `/NOTICES/`.
