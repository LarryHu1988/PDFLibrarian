#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
TEAM_ID="${1:-${TEAM_ID:-}}"
PROJECT_YML="$ROOT_DIR/project.yml"
PBXPROJ="$ROOT_DIR/PDFLibrarian.xcodeproj/project.pbxproj"

if [[ -z "$TEAM_ID" ]]; then
  echo "Usage:"
  echo "  TEAM_ID=ABCDE12345 ./scripts/set_development_team.sh"
  echo "  ./scripts/set_development_team.sh ABCDE12345"
  exit 1
fi

if [[ ! "$TEAM_ID" =~ ^[A-Z0-9]{10}$ ]]; then
  echo "TEAM_ID should usually be a 10-character Apple Developer Team ID."
  echo "Received: $TEAM_ID"
  exit 1
fi

ruby - "$PROJECT_YML" "$PBXPROJ" "$TEAM_ID" <<'RUBY'
project_yml, pbxproj, team_id = ARGV

project_text = File.read(project_yml)
if project_text.match?(/^(\s*)DEVELOPMENT_TEAM:\s*\S+/)
  project_text.gsub!(/^(\s*)DEVELOPMENT_TEAM:\s*\S+/, "\\1DEVELOPMENT_TEAM: #{team_id}")
else
  project_text.sub!(/^(\s*)CODE_SIGN_STYLE:\s*Automatic\s*$/, "\\0\n\\1DEVELOPMENT_TEAM: #{team_id}")
end
File.write(project_yml, project_text)

pbxproj_text = File.read(pbxproj)
if pbxproj_text.match?(/DevelopmentTeam = [A-Z0-9]{10};/)
  pbxproj_text.gsub!(/DevelopmentTeam = [A-Z0-9]{10};/, "DevelopmentTeam = #{team_id};")
else
  pbxproj_text.sub!(/(ProvisioningStyle = Automatic;\n)/, "DevelopmentTeam = #{team_id};\n\\1")
end

if pbxproj_text.match?(/DEVELOPMENT_TEAM = [A-Z0-9]{10};/)
  pbxproj_text.gsub!(/DEVELOPMENT_TEAM = [A-Z0-9]{10};/, "DEVELOPMENT_TEAM = #{team_id};")
else
  pbxproj_text.gsub!(/(CODE_SIGN_STYLE = Automatic;\n)/, "\\1\t\t\t\tDEVELOPMENT_TEAM = #{team_id};\n")
end

File.write(pbxproj, pbxproj_text)
RUBY

echo "Updated signing team to: $TEAM_ID"
echo "Files updated:"
echo "  $PROJECT_YML"
echo "  $PBXPROJ"
echo
echo "Next steps:"
echo "  1. Open PDFLibrarian.xcodeproj in Xcode"
echo "  2. Confirm Signing & Capabilities shows team $TEAM_ID"
echo "  3. Re-archive and upload again"
