#!/usr/bin/env bash

set -euo pipefail

show_help() {
  cat <<'EOF'
Usage: ./tools/build_macos_installer.sh [options]

Build the macOS Flutter app and package it as a DMG.

Options:
  --flutter-bin PATH            Path to the flutter executable.
  --release-tag TAG            Release tag used in the output file name.
  --output-base-filename NAME  DMG file name (with or without .dmg).
  --output-dir DIR             Output directory. Defaults to dist/macos-installer.
  --app-path PATH              Existing .app bundle to package.
  --skip-build                 Skip flutter build and package an existing .app.
  -h, --help                   Show this help message.
EOF
}

flutter_bin="${FLUTTER_BIN:-flutter}"
release_tag=""
output_base_filename=""
output_dir=""
app_path=""
skip_build=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --flutter-bin)
      flutter_bin="$2"
      shift 2
      ;;
    --release-tag)
      release_tag="$2"
      shift 2
      ;;
    --output-base-filename)
      output_base_filename="$2"
      shift 2
      ;;
    --output-dir)
      output_dir="$2"
      shift 2
      ;;
    --app-path)
      app_path="$2"
      shift 2
      ;;
    --skip-build)
      skip_build=true
      shift
      ;;
    -h|--help)
      show_help
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      show_help >&2
      exit 1
      ;;
  esac
done

resolve_flutter_bin() {
  local preferred="$1"

  if [[ -n "${preferred}" && "${preferred}" != "flutter" ]]; then
    if [[ -x "${preferred}" || -f "${preferred}" ]]; then
      printf '%s\n' "${preferred}"
      return
    fi

    echo "Flutter executable not found: ${preferred}" >&2
    exit 1
  fi

  if command -v flutter >/dev/null 2>&1; then
    command -v flutter
    return
  fi

  local candidate
  for candidate in \
    "${HOME}/fvm/default/bin/flutter" \
    "${HOME}/flutter/bin/flutter" \
    "/opt/homebrew/bin/flutter" \
    "/usr/local/bin/flutter"; do
    if [[ -x "${candidate}" ]]; then
      printf '%s\n' "${candidate}"
      return
    fi
  done

  echo "Flutter executable not found. Provide --flutter-bin or add flutter to PATH." >&2
  exit 1
}

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd -- "${script_dir}/.." && pwd)"
pubspec_path="${repo_root}/pubspec.yaml"
build_products_dir="${repo_root}/build/macos/Build/Products/Release"
ephemeral_app_name_file="${repo_root}/macos/Flutter/ephemeral/.app_filename"
resolved_output_dir="${output_dir:-${repo_root}/dist/macos-installer}"
flutter_bin="$(resolve_flutter_bin "${flutter_bin}")"

if [[ ! -f "${pubspec_path}" ]]; then
  echo "pubspec.yaml not found: ${pubspec_path}" >&2
  exit 1
fi

if [[ -z "${release_tag}" ]]; then
  if git -C "${repo_root}" describe --tags --abbrev=0 >/dev/null 2>&1; then
    release_tag="$(git -C "${repo_root}" describe --tags --abbrev=0 | tr -d '\r')"
  fi
fi

pubspec_version="$(sed -nE 's/^version:[[:space:]]*([^+[:space:]]+).*/\1/p' "${pubspec_path}" | head -n 1)"
if [[ -z "${pubspec_version}" ]]; then
  echo "Unable to read version from pubspec.yaml." >&2
  exit 1
fi

installer_version="${release_tag#v}"
if [[ -z "${installer_version}" ]]; then
  installer_version="${pubspec_version}"
fi

if [[ -z "${output_base_filename}" ]]; then
  if [[ -n "${release_tag}" ]]; then
    output_base_filename="Diary-macOS-${release_tag}"
  else
    output_base_filename="Diary-macOS-v${pubspec_version}"
  fi
fi

if [[ "${output_base_filename}" != *.dmg ]]; then
  output_base_filename="${output_base_filename}.dmg"
fi

resolve_app_path() {
  local preferred="$1"

  if [[ -n "${preferred}" ]]; then
    if [[ -d "${preferred}" ]]; then
      printf '%s\n' "${preferred}"
      return
    fi

    echo "App bundle not found: ${preferred}" >&2
    exit 1
  fi

  if [[ -f "${ephemeral_app_name_file}" ]]; then
    local app_name
    app_name="$(tr -d '\r' < "${ephemeral_app_name_file}" | sed 's/[[:space:]]*$//')"
    if [[ -n "${app_name}" && -d "${build_products_dir}/${app_name}" ]]; then
      printf '%s\n' "${build_products_dir}/${app_name}"
      return
    fi
  fi

  local app_candidate
  app_candidate="$(find "${build_products_dir}" -maxdepth 1 -type d -name '*.app' -print | head -n 1 || true)"
  if [[ -n "${app_candidate}" ]]; then
    printf '%s\n' "${app_candidate}"
    return
  fi

  echo "No macOS .app bundle found in ${build_products_dir}. Run without --skip-build or provide --app-path." >&2
  exit 1
}

cleanup() {
  if [[ -n "${staging_dir:-}" && -d "${staging_dir}" ]]; then
    rm -rf "${staging_dir}"
  fi
}

trap cleanup EXIT

cd "${repo_root}"

if [[ "${skip_build}" != true ]]; then
  "${flutter_bin}" config --enable-macos-desktop >/dev/null
  "${flutter_bin}" build macos
fi

resolved_app_path="$(resolve_app_path "${app_path}")"
app_bundle_name="$(basename "${resolved_app_path}")"
final_dmg_path="${resolved_output_dir}/${output_base_filename}"
staging_dir="$(mktemp -d "${TMPDIR:-/tmp}/diary-macos-installer.XXXXXX")"
volume_dir="${staging_dir}/Diary Installer"

mkdir -p "${resolved_output_dir}"
mkdir -p "${volume_dir}"

cp -R "${resolved_app_path}" "${volume_dir}/"
ln -s /Applications "${volume_dir}/Applications"

hdiutil create \
  -quiet \
  -volname "Diary Installer" \
  -srcfolder "${volume_dir}" \
  -ov \
  -format UDZO \
  "${final_dmg_path}"

echo
echo "Installer created successfully:"
echo "${final_dmg_path}"
echo "Packaged app bundle:"
echo "${app_bundle_name}"
echo "Installer version:"
echo "${installer_version}"
