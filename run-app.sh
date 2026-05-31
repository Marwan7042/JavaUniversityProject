#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/UniReg_Optimized_GoodGUI_Base" && pwd)"
exec mvn -f "${project_root}/pom.xml" -q -DskipTests org.openjfx:javafx-maven-plugin:0.0.8:run
