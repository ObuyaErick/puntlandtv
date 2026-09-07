# syntax=docker/dockerfile:1.7
#
# One image recipe, two apps. `TARGET` picks the entrypoint — lib/main.dart for
# the reader app, lib/main_console.dart for the console — and everything else is
# identical, so both containers share the SDK and dependency layers and only the
# final compile differs. docker-compose.yml passes the arg.
#
# Build one by hand with:
#   docker build --build-arg TARGET=lib/main_console.dart -t puntland-console .

# The version in .fvmrc. cirruslabs publishes no 3.47.x tag, so the SDK comes
# from the official archive — which is what FVM downloads too, so the container
# and a local `fvm flutter build web` compile with the same toolchain.
ARG FLUTTER_VERSION=3.47.1
ARG NGINX_VERSION=1.29-alpine


# ---- SDK ---------------------------------------------------------------------
FROM debian:bookworm-slim AS flutter-sdk

ARG FLUTTER_VERSION

# git is not optional: the flutter tool reads its own revision out of the
# checkout that ships inside the tarball and refuses to run without it.
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        git \
        unzip \
        xz-utils \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL -o /tmp/flutter.tar.xz \
        "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    && tar -xJf /tmp/flutter.tar.xz -C /opt \
    && rm /tmp/flutter.tar.xz

ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}" \
    PUB_CACHE="/opt/pub-cache" \
    # No TTY here, and no consent prompt to answer on a build machine.
    CI="true" \
    FLUTTER_SUPPRESS_ANALYTICS="true"

# The SDK is unpacked by root but git refuses to read a repo it does not own,
# which is what happens the moment a non-root user builds.
RUN git config --global --add safe.directory /opt/flutter \
    && flutter precache --web \
    && flutter --version


# ---- Dependencies ------------------------------------------------------------
# Its own stage so editing a widget does not re-resolve the pub graph: this
# layer is only rebuilt when pubspec.yaml or pubspec.lock changes.
FROM flutter-sdk AS deps

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get


# ---- Build -------------------------------------------------------------------
FROM deps AS build

# Which app to compile.
ARG TARGET=lib/main.dart

# `API_BASE_URL` is a `String.fromEnvironment` — see core/api/api_providers.dart
# — so it is baked in at compile time, not read at container start. Changing it
# means rebuilding the image, and an empty value makes the app serve its bundled
# fixtures instead of calling a backend.
ARG API_BASE_URL=""
ARG USE_FIXTURES="false"

# Only needed if the app is ever served from a sub-path instead of a port.
ARG BASE_HREF="/"

# Escape hatch for anything else, e.g. --build-arg EXTRA_BUILD_ARGS=--source-maps
ARG EXTRA_BUILD_ARGS=""

COPY . .

# `--no-web-resources-cdn` copies CanvasKit into the image instead of fetching it
# from gstatic.com at runtime. This is an internal deployment behind a port, so
# the app must not depend on Google's CDN being reachable from the browser.
RUN flutter pub get \
    && flutter build web \
        --release \
        --target="${TARGET}" \
        --base-href="${BASE_HREF}" \
        --no-web-resources-cdn \
        --dart-define=API_BASE_URL="${API_BASE_URL}" \
        --dart-define=USE_FIXTURES="${USE_FIXTURES}" \
        ${EXTRA_BUILD_ARGS}


# ---- Runtime -----------------------------------------------------------------
FROM nginx:${NGINX_VERSION} AS runtime

COPY docker/nginx.conf /etc/nginx/conf.d/default.conf
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://127.0.0.1:8080/health || exit 1
