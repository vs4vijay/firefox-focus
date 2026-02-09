#!/usr/bin/env bash

set -euo pipefail

source "$(dirname $0)/versions.sh"

download() {
    local url="$1"
    local filepath="$2"

    if [[ "$url" == "" ]]; then
        echo "URL is required (file: '$filepath')"
        exit 1
    fi

    if [ -f "$filepath" ]; then
        echo "$filepath already exists."
        read -p "Do you want to re-download? [y/N] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "Removing $filepath..."
            rm -f "$filepath"
        else
            return 0
        fi
    fi

    mkdir -p "$(dirname "$filepath")"

    echo "Downloading $url"
    wget "$url" -O "$filepath"
}

# Extract tar.xz removing top level directory
extract_rmtoplevel() {
    local archive_path="$1"
    local to_name="$2"
    local extract_to="${ROOTDIR}/$to_name"

    if ! [[ -f "$archive_path" ]]; then
        echo "Archive '$archive_path' does not exist!"
        exit 1
    fi

    # Create temporary directory for extraction
    local temp_dir=$(mktemp -d)

    # Extract based on file extension
    case "$archive_path" in
        *.tar.xz)
            tar xJf "$archive_path" -C "$temp_dir"
            ;;
        *.tar.gz)
            tar xzf "$archive_path" -C "$temp_dir"
            ;;
        *.zip)
            unzip -q "$archive_path" -d "$temp_dir"
            ;;
        *)
            echo "Unsupported archive format: $archive_path"
            rm -rf "$temp_dir"
            exit 1
            ;;
    esac

    local top_dir=$(ls "$temp_dir")
    local to_parent=$(dirname "$extract_to")

    rm -rf "$extract_to"
    mkdir -p "$to_parent"
    mv "$temp_dir/$top_dir" "$to_parent/$to_name"

    rm -rf "$temp_dir"
}

download_and_extract() {
    local repo_name="$1"
    local url="$2"

    local extension=".tar.xz"
    local repo_archive="${BUILDDIR}/${repo_name}${extension}"

    download "$url" "$repo_archive"

    if [ ! -f "$repo_archive" ]; then
        echo "Source archive for $repo_name does not exist."
        exit 1
    fi

    echo "Extracting $repo_archive"
    extract_rmtoplevel "$repo_archive" "$repo_name"
    echo
}

mkdir -p "$BUILDDIR"

# Download bundletool if not present
if ! [[ -f "$BUILDDIR/bundletool.jar" ]]; then
    echo "Downloading bundletool..."
    wget https://github.com/google/bundletool/releases/download/${BUNDLETOOL_TAG}/bundletool-all-${BUNDLETOOL_TAG}.jar \
        -O "$BUILDDIR/bundletool.jar"
fi

if ! [[ -f "$BUILDDIR/bundletool" ]]; then
    echo "Creating bundletool script..."
    {
        echo '#!/bin/bash'
        echo "exec java -jar ${BUILDDIR}/bundletool.jar \"\$@\""
    } > "$BUILDDIR/bundletool"
    chmod +x "$BUILDDIR/bundletool"
fi

echo "'bundletool' is set up at $BUILDDIR/bundletool"

# Download Firefox Source
echo "Downloading Firefox ${FIREFOX_TAG} source..."
download_and_extract "gecko" "https://archive.mozilla.org/pub/firefox/${FIREFOX_RELEASE_PATH}/source/firefox-${FIREFOX_TAG}.source.tar.xz"

# Write env_local.sh
echo "Writing ${ENV_SH}..."
cat > "$ENV_SH" << EOF
export rootdir=${ROOTDIR}
export builddir="${BUILDDIR}"
export android_components=${ANDROID_COMPONENTS}
export mozilla_release=${GECKODIR}
export drft=${FOCUS}

source "\$rootdir/scripts/env_common.sh"
EOF

echo ""
echo "Sources downloaded successfully!"
echo "Next steps:"
echo "  1. source scripts/env_local.sh"
echo "  2. ./scripts/prebuild.sh <version-name> <version-code>"
echo "  3. ./scripts/build.sh apk"
