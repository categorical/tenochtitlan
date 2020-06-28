#!/bin/sh

hostname='y'
sudo sh -c "scutil --set LocalHostName $hostname && hostname $hostname"


cat <<'EOF'
xcode-select --install
EOF
