#!/bin/zsh

set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
product_name="ccusage-bar"
app_name="ccusage Bar.app"
dmg_path="$repo_root/ccusage-Bar.dmg"
app_version="${CCUSAGE_BAR_VERSION:-1.0.0}"
bundle_version="$(git -C "$repo_root" rev-list --count HEAD)"
package_tmp="$(mktemp -d /tmp/ccusage-bar-dmg.XXXXXX)"

cleanup() {
    if [[ "$package_tmp" == /tmp/ccusage-bar-dmg.* ]]; then
        rm -rf "$package_tmp"
    fi
}
trap cleanup EXIT

cd "$repo_root"

swift build -c release --arch arm64
swift build -c release --arch x86_64

arm64_dir="$repo_root/.build/arm64-apple-macosx/release"
x86_64_dir="$repo_root/.build/x86_64-apple-macosx/release"
volume_dir="$package_tmp/volume"
app_path="$volume_dir/$app_name"
contents_dir="$app_path/Contents"

mkdir -p "$contents_dir/MacOS" "$contents_dir/Resources"

lipo -create \
    "$arm64_dir/$product_name" \
    "$x86_64_dir/$product_name" \
    -output "$contents_dir/MacOS/$product_name"

cp Sources/ccusageBarApp/Resources/Info.plist "$contents_dir/Info.plist"

/usr/libexec/PlistBuddy -c "Add :CFBundleExecutable string $product_name" "$contents_dir/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundlePackageType string APPL" "$contents_dir/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleShortVersionString string $app_version" "$contents_dir/Info.plist"
/usr/libexec/PlistBuddy -c "Add :CFBundleVersion string $bundle_version" "$contents_dir/Info.plist"
/usr/libexec/PlistBuddy -c "Add :LSMinimumSystemVersion string 14.0" "$contents_dir/Info.plist"

icon_source="$package_tmp/AppIcon.png"
iconset_dir="$package_tmp/AppIcon.iconset"
mkdir -p "$iconset_dir"
sips -s format png -z 1024 1024 Sources/ccusageBarApp/Resources/AppIcon.svg --out "$icon_source" >/dev/null

for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$icon_source" --out "$iconset_dir/icon_${size}x${size}.png" >/dev/null
    double_size=$((size * 2))
    sips -z "$double_size" "$double_size" "$icon_source" --out "$iconset_dir/icon_${size}x${size}@2x.png" >/dev/null
done

iconutil -c icns "$iconset_dir" -o "$contents_dir/Resources/AppIcon.icns"
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string AppIcon.icns" "$contents_dir/Info.plist"

ln -s /Applications "$volume_dir/Applications"

codesign --force --deep --sign - "$app_path"
codesign --verify --deep --strict --verbose=2 "$app_path"

temporary_dmg="$package_tmp/ccusage-Bar.dmg"
hdiutil create \
    -volname "ccusage Bar" \
    -srcfolder "$volume_dir" \
    -format UDZO \
    -ov \
    "$temporary_dmg"
hdiutil verify "$temporary_dmg"

mv -f "$temporary_dmg" "$dmg_path"
echo "Created $dmg_path"
