#!/bin/bash
#
# backup-keys.sh - Backup SSB credentials from Docker volume to host
#
# USAGE:
#   ./client/scripts/backup-keys.sh [DESTINATION_FOLDER]
#
# EXAMPLES:
#   ./client/scripts/backup-keys.sh                     # Backup to ./backups/
#   ./client/scripts/backup-keys.sh /e/USB_BACKUP       # Backup to USB drive E:
#   ./client/scripts/backup-keys.sh ~/my-ssb-backup     # Backup to home folder
#
# FILES BACKED UP:
#   - secret       (CRITICAL - private key)
#   - config       (node configuration)
#   - gossip.json  (known peers - optional)
#
# WARNING: The secret file contains your SSB private key.
#          Anyone with this file can impersonate your identity.
#          Store backups securely (encrypted USB, password manager, etc.)
#

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default source and destination
SOURCE_DIR="./volumes-dev/ssb-data"
DEST_DIR="${1:-./backups}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="ssb-backup-${TIMESTAMP}"
BACKUP_PATH="${DEST_DIR}/${BACKUP_NAME}"

echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${YELLOW}║           SSB CREDENTIALS BACKUP SCRIPT                      ║${NC}"
echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check source exists
if [ ! -d "$SOURCE_DIR" ]; then
    echo -e "${RED}ERROR: Source directory not found: ${SOURCE_DIR}${NC}"
    echo "Make sure you're running this from the project root and the container has been started at least once."
    exit 1
fi

# Check secret file exists
if [ ! -f "${SOURCE_DIR}/secret" ]; then
    echo -e "${RED}ERROR: Secret file not found: ${SOURCE_DIR}/secret${NC}"
    echo "The SSB identity has not been generated yet. Start the container first."
    exit 1
fi

# Create destination directory
mkdir -p "$BACKUP_PATH"

echo -e "Source:      ${SOURCE_DIR}"
echo -e "Destination: ${BACKUP_PATH}"
echo ""

# Copy files
echo -e "${GREEN}[1/4]${NC} Copying secret (private key)..."
cp "${SOURCE_DIR}/secret" "${BACKUP_PATH}/"

echo -e "${GREEN}[2/4]${NC} Copying config..."
cp "${SOURCE_DIR}/config" "${BACKUP_PATH}/" 2>/dev/null || echo "  (config not found, skipping)"

echo -e "${GREEN}[3/4]${NC} Copying gossip.json..."
cp "${SOURCE_DIR}/gossip.json" "${BACKUP_PATH}/" 2>/dev/null || echo "  (gossip.json not found, skipping)"

# Verify integrity
echo -e "${GREEN}[4/4]${NC} Verifying backup integrity..."
ORIG_HASH=$(sha256sum "${SOURCE_DIR}/secret" | cut -d' ' -f1)
BACK_HASH=$(sha256sum "${BACKUP_PATH}/secret" | cut -d' ' -f1)

if [ "$ORIG_HASH" = "$BACK_HASH" ]; then
    echo -e "  ${GREEN}✓ SHA256 verification passed${NC}"
else
    echo -e "  ${RED}✗ SHA256 mismatch! Backup may be corrupted.${NC}"
    exit 1
fi

# Extract SSB ID from secret file
SSB_ID=$(grep -o '"public": "[^"]*"' "${BACKUP_PATH}/secret" | cut -d'"' -f4 2>/dev/null || echo "unknown")

# Create README in backup folder
cat > "${BACKUP_PATH}/README.txt" << EOF
╔══════════════════════════════════════════════════════════════════════════════╗
║                        SSB CREDENTIALS BACKUP                                ║
╠══════════════════════════════════════════════════════════════════════════════╣
║                                                                              ║
║  Created: $(date)
║  SSB ID:  @${SSB_ID}
║                                                                              ║
║  FILES:                                                                      ║
║  - secret       🔴 CRITICAL - Your private key (KEEP SECURE!)               ║
║  - config       🟡 Node configuration                                        ║
║  - gossip.json  🟢 Known peers list                                          ║
║                                                                              ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  TO RESTORE:                                                                 ║
║                                                                              ║
║  1. Stop the container:                                                      ║
║     docker compose down                                                      ║
║                                                                              ║
║  2. Copy files back:                                                         ║
║     cp ${BACKUP_NAME}/* ./volumes-dev/ssb-data/                              ║
║                                                                              ║
║  3. Start the container:                                                     ║
║     docker compose up -d                                                     ║
║                                                                              ║
╠══════════════════════════════════════════════════════════════════════════════╣
║  ⚠️  WARNING: Anyone with the 'secret' file can impersonate your identity.  ║
║               Store this backup in a secure location!                        ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    BACKUP COMPLETE ✓                         ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "Backup location: ${YELLOW}${BACKUP_PATH}${NC}"
echo -e "SSB Identity:    ${YELLOW}@${SSB_ID}${NC}"
echo -e "SHA256:          ${ORIG_HASH}"
echo ""
echo -e "${YELLOW}⚠️  IMPORTANT: Copy this backup to an external device (USB, cloud, etc.)${NC}"
echo -e "${YELLOW}    If stored on the same disk, it's NOT a real backup!${NC}"
echo ""

# List backup contents
ls -la "${BACKUP_PATH}/"
