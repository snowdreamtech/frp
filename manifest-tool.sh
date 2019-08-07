#!/bin/bash
# https://github.com/estesp/manifest-tool

# frpc
manifest-tool push from-spec frpc.yaml
manifest-tool push from-spec frpc-latest.yaml

# frps
manifest-tool push from-spec frps.yaml
manifest-tool push from-spec frps-latest.yaml