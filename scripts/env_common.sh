#!/bin/bash

# Common environment configuration for Firefox Focus builds

export ARTIFACTS="$rootdir/artifacts"
export APK_ARTIFACTS=$ARTIFACTS/apk
export AAR_ARTIFACTS=$ARTIFACTS/aar

mkdir -p "$APK_ARTIFACTS"
mkdir -p "$AAR_ARTIFACTS"

export env_source="true"

if [[ -z ${CARGO_HOME+x} ]]; then
    export CARGO_HOME=$HOME/.cargo
fi

if [[ -z ${GRADLE_USER_HOME+x} ]]; then
    export GRADLE_USER_HOME=$HOME/.gradle
fi

# Disable Gradle daemon and configuration cache for reproducible builds
mkdir -p "$GRADLE_USER_HOME"
echo "org.gradle.daemon=false" >> "$GRADLE_USER_HOME/gradle.properties"
echo "org.gradle.configuration-cache=false" >> "$GRADLE_USER_HOME/gradle.properties"
