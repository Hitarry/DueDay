#!/bin/bash
cd "$(dirname "$0")"
export DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer

echo "=== 生成 Xcode 项目 ==="
rm -rf "DueDay.xcodeproj"
xcodegen generate

echo ""
echo "=== 编译 ==="
xcodebuild -project "DueDay.xcodeproj" -scheme "DueDay" -configuration Debug build

if [ $? -eq 0 ]; then
    echo ""
    echo "=== 编译成功 ==="
    BUILD_DIR=$(xcodebuild -project "DueDay.xcodeproj" -scheme "DueDay" -configuration Debug -showBuildSettings 2>/dev/null | grep "BUILT_PRODUCTS_DIR" | head -1 | awk '{print $NF}')

    echo "=== 生成 DMG ==="
    rm -rf /tmp/dday_dmg "DueDay.dmg"
    mkdir -p /tmp/dday_dmg
    cp -R "$BUILD_DIR/DueDay.app" /tmp/dday_dmg/
    ln -s /Applications /tmp/dday_dmg/Applications
    hdiutil create -volname "DueDay" -srcfolder /tmp/dday_dmg -ov -format UDZO -imagekey zlib-level=9 "DueDay.dmg"
    rm -rf /tmp/dday_dmg

    echo ""
    echo "=== 完成: DueDay.dmg ==="
else
    echo "=== 编译失败 ==="
fi
