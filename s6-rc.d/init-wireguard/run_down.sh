#!/command/with-contenv bash
set -e
set -o pipefail

wg-quick down wg0
