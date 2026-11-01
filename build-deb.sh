#!/bin/bash
set -e

PACKAGE=mt7663-router-webui
VERSION=${1:-1.0.3}
TARGET_DEB="${PACKAGE}_${VERSION}_all.deb"
BUILD_DIR=/tmp/${PACKAGE}_build

echo "Building Debian package for ${PACKAGE} v${VERSION} (${TARGET_DEB})..."

rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR}/DEBIAN

# 1. Copy all system files
cp -a system/* ${BUILD_DIR}/
find ${BUILD_DIR} -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
find ${BUILD_DIR} -name "*.pyc" -delete 2>/dev/null || true

chmod 755 "${BUILD_DIR}/usr/sbin/mt7663-hotspot"
chmod 755 "${BUILD_DIR}/usr/lib/mt7663-webui/server.py"
chmod 755 "${BUILD_DIR}/etc/NetworkManager/dispatcher.d/90-wlan0-routing.sh"
chmod 755 "${BUILD_DIR}/etc/update-motd.d/15-ap-info"

# 2. Copy control scripts
cp -a debian/* ${BUILD_DIR}/DEBIAN/
sed -i "s/^Version:.*/Version: ${VERSION}/" ${BUILD_DIR}/DEBIAN/control
chmod 755 ${BUILD_DIR}/DEBIAN
chmod 755 ${BUILD_DIR}/DEBIAN/postinst ${BUILD_DIR}/DEBIAN/prerm ${BUILD_DIR}/DEBIAN/postrm

dpkg-deb --build ${BUILD_DIR} ${TARGET_DEB}
rm -rf ${BUILD_DIR}

echo "Package created successfully: ${TARGET_DEB}"
