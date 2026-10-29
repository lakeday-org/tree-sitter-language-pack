#!/usr/bin/env bash
#MISE description="Move Java dependencies and plugin properties to newer stable releases"
#MISE hide=true
#MISE dir="{{config_root}}/packages/java"
#USAGE arg "<mode>" help="update stays within major versions; upgrade allows major bumps"
# shellcheck disable=SC2154 # usage_* are set by mise from the #USAGE lines
set -euo pipefail

rules=(-DallowSnapshots=false "-Dmaven.version.rules=file:///${PWD}/maven-version-rules.xml")
case "$usage_mode" in
update) majors=-DallowMajorUpdates=false goal=versions:use-next-versions ;;
upgrade) majors=-DallowMajorUpdates=true goal=versions:use-latest-releases ;;
*)
  echo "mode must be update or upgrade, got: $usage_mode" >&2
  exit 2
  ;;
esac

mvn "${rules[@]}" "$majors" "$goal" -DprocessDependencies=true -DprocessParent=false -DgenerateBackupPoms=false
mvn "${rules[@]}" "$majors" versions:update-properties -DgenerateBackupPoms=false || true
mvn "${rules[@]}" versions:display-dependency-updates
if [ "$usage_mode" = upgrade ]; then mvn "${rules[@]}" versions:display-plugin-updates; fi
