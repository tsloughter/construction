#!/usr/bin/env bash
set -euo pipefail
cd -- "$(dirname -- "${BASH_SOURCE[0]}")"

if command -v godot >/dev/null 2>&1; then
  engine=(godot)
elif command -v godot4 >/dev/null 2>&1; then
  engine=(godot4)
elif command -v flatpak >/dev/null 2>&1 && flatpak info org.godotengine.Godot >/dev/null 2>&1; then
  engine=(flatpak run org.godotengine.Godot)
else
  echo "Install Godot 4.4 or newer, then open project.godot or rerun this script." >&2
  exit 1
fi

case "${1:-play}" in
  edit|--editor)
    exec "${engine[@]}" --path "$PWD" --editor
    ;;
  test|--test)
    "${engine[@]}" --headless --path "$PWD" --editor --import
    for suite in --smoke-test --bulldozer-test --loader-test --menu-test; do
      "${engine[@]}" --headless --path "$PWD" --fixed-fps 60 -- "$suite"
    done
    ;;
  capture|--capture)
    "${engine[@]}" --headless --path "$PWD" --editor --import
    "${engine[@]}" --path "$PWD" --resolution 1440x900 -- --capture
    "${engine[@]}" --path "$PWD" --resolution 1440x900 -- --excavator --capture
    "${engine[@]}" --path "$PWD" --resolution 1440x900 -- --bulldozer --capture
    "${engine[@]}" --path "$PWD" --resolution 1440x900 -- --loader --capture
    ;;
  play)
    # Refresh cached GLBs after edits or a switch between main and expert.
    "${engine[@]}" --quiet --headless --path "$PWD" --editor --import
    exec "${engine[@]}" --path "$PWD"
    ;;
  *)
    echo "Usage: ./run.sh [play|edit|test|capture]" >&2
    exit 2
    ;;
esac
