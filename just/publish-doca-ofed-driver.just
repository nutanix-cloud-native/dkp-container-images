# Steps: create a dir -> download the dockerfiles -> create driver container image -> tag the image for registry upload -> push the image
# reference: https://docs.nvidia.com/networking/display/kubernetes25100/advanced/doca-drivers.html#precompiled-container-build-instructions-for-nvidia-doca-ofed-driver-container

# Config
# From DOCA 3.6 the public driver sources are published as
# DOCA_BASE_SRC-debian-<doca>-<build>.tar.gz instead of
# MLNX_OFED_SRC-debian-<ofed>.tgz. For 3.6.0 / 26.10-070000 that archive is
# https://linux.mellanox.com/public/repo/doca/3.6.0/SOURCES/mlnx_ofed/DOCA_BASE_SRC-debian-3.6.0-070000.tar.gz
# This commit constructs that URL (and still uses the legacy name for DOCA <= 3.5).
# The Dockerfile also vendors install.pl and builds the entrypoint, so the whole tree is required.
DOCA_BUILD_REPO   := "Mellanox/doca-driver-build"
DOCA_BUILD_COMMIT := "3bd13302cf9b48dbc8cfe7a2c55483423e2ef5d1"
DOCABUILDER_DIR   := "doca-builder"

# Create a clean doca-builder directory
_ensure-dir:
    @rm -rf "{{ DOCABUILDER_DIR }}"
    @mkdir -p "{{ DOCABUILDER_DIR }}"

# Download the DOCA driver build sources into doca-builder/
download-doca-artifacts: _ensure-dir
    @echo "Downloading DOCA build sources @ {{ DOCA_BUILD_COMMIT }}..."
    @wget -q --show-progress \
      "https://github.com/{{ DOCA_BUILD_REPO }}/archive/{{ DOCA_BUILD_COMMIT }}.tar.gz" \
      -O "{{ DOCABUILDER_DIR }}/doca-driver-build.tar.gz"
    @tar -xzf "{{ DOCABUILDER_DIR }}/doca-driver-build.tar.gz" -C "{{ DOCABUILDER_DIR }}" --strip-components=1
    @rm -f "{{ DOCABUILDER_DIR }}/doca-driver-build.tar.gz"
    @chmod +x \
      "{{ DOCABUILDER_DIR }}/entrypoint.sh" \
      "{{ DOCABUILDER_DIR }}/loader.sh" \
      "{{ DOCABUILDER_DIR }}/dtk_nic_driver_build.sh" \
      "{{ DOCABUILDER_DIR }}/stig-fixer.sh" \
      "{{ DOCABUILDER_DIR }}/vendor/mlnx_ofed/stage_src_tree.sh"
    @echo "Download complete."

# Map Linux distribution to Dockerfile name
_dockerfile-for distro:
    @case "{{ distro }}" in \
        ubuntu22.04|ubuntu24.04) echo "Ubuntu_Dockerfile" ;; \
        *) echo "ERROR: Unsupported Linux distribution: {{ distro }}" >&2; exit 1 ;; \
    esac

# Normalize architecture name (x86_64 -> amd64, aarch64 -> arm64)
_normalize-arch arch:
    @case "{{ arch }}" in \
        x86_64) echo "amd64" ;; \
        aarch64) echo "arm64" ;; \
        *) echo "{{ arch }}" ;; \
    esac

# Generate image tag
_image-tag doca_version ofed_version kernel_version linux_distro arch:
    @echo "doca{{ doca_version }}-{{ ofed_version }}-0-{{ kernel_version }}-{{ linux_distro }}-$(just _normalize-arch '{{ arch }}')"

# Build DOCA-OFED Docker image (downloads artifacts first)
build-doca-image registry linux_distro arch base_image kernel_version doca_version ofed_version: download-doca-artifacts
    @echo "Building DOCA-OFED Docker image..."
    @echo "  Registry:      {{ registry }}"
    @echo "  Image tag:     $(just _image-tag '{{ doca_version }}' '{{ ofed_version }}' '{{ kernel_version }}' '{{ linux_distro }}' '{{ arch }}')"
    @echo "  Dockerfile:    $(just _dockerfile-for '{{ linux_distro }}')"
    @echo "  Linux distro:  {{ linux_distro }}"
    @echo "  Arch:          {{ arch }}"
    @echo "  Base image:    {{ base_image }}"
    @echo "  Kernel:        {{ kernel_version }}"
    @echo "  DOCA version:  {{ doca_version }}"
    @echo "  OFED version:  {{ ofed_version }}"
    @echo ""
    @cd "{{ DOCABUILDER_DIR }}" && \
      docker build \
        --build-arg D_OS="{{ linux_distro }}" \
        --build-arg D_ARCH="{{ arch }}" \
        --build-arg D_BASE_IMAGE="{{ base_image }}" \
        --build-arg D_KERNEL_VER="{{ kernel_version }}" \
        --build-arg D_DOCA_VERSION="{{ doca_version }}" \
        --build-arg D_OFED_VERSION="{{ ofed_version }}" \
        --tag "doca-driver:$(just _image-tag '{{ doca_version }}' '{{ ofed_version }}' '{{ kernel_version }}' '{{ linux_distro }}' '{{ arch }}')" \
        -f "$(just _dockerfile-for '{{ linux_distro }}')" \
        --target precompiled \
        .
    @echo "Docker build completed successfully."
    @echo "Built image: doca-driver:$(just _image-tag '{{ doca_version }}' '{{ ofed_version }}' '{{ kernel_version }}' '{{ linux_distro }}' '{{ arch }}')"

# Build and publish DOCA-OFED Docker image to registry
publish-doca-ofed-driver registry linux_distro arch base_image kernel_version doca_version ofed_version: (build-doca-image registry linux_distro arch base_image kernel_version doca_version ofed_version)
    @echo "Tagging driver image for registry..."
    @docker tag \
        "doca-driver:$(just _image-tag '{{ doca_version }}' '{{ ofed_version }}' '{{ kernel_version }}' '{{ linux_distro }}' '{{ arch }}')" \
        "{{ registry }}/doca-driver:$(just _image-tag '{{ doca_version }}' '{{ ofed_version }}' '{{ kernel_version }}' '{{ linux_distro }}' '{{ arch }}')"
    @echo "Complete! Tagged: {{ registry }}/doca-driver:$(just _image-tag '{{ doca_version }}' '{{ ofed_version }}' '{{ kernel_version }}' '{{ linux_distro }}' '{{ arch }}')"

    @echo "Pusing driver image to registry..."
    @docker push "{{ registry }}/doca-driver:$(just _image-tag '{{ doca_version }}' '{{ ofed_version }}' '{{ kernel_version }}' '{{ linux_distro }}' '{{ arch }}')"
    @echo "Driver created and publishedl successfully"
