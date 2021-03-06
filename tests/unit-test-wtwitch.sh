#!/usr/bin/env sh
#
# Description: Multiple tests for wtwitch to ensure the script
#              is working as expected.
#
# Homepage: https://git.sr.ht/~krathalan/wtwitch
#
# Copyright (C) 2020 krathalan
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# -----------------------------------------
# -------------- Guidelines ---------------
# -----------------------------------------

# This script follows the Google Shell Style Guide:
# https://google.github.io/styleguide/shell.xml

# This script uses shellcheck: https://www.shellcheck.net/

# See https://vaneyckt.io/posts/safer_bash_scripts_with_set_euxo_pipefail/
set -eu # (Eo pipefail) is Bash only!

trap "clean_up" INT EXIT

# -----------------------------------------
# ----------- Program variables -----------
# -----------------------------------------

# Colors
readonly GREEN=$(tput bold && tput setaf 2)
readonly RED=$(tput bold && tput setaf 1)
readonly PURPLE=$(tput bold && tput setaf 5)
readonly NC=$(tput sgr0) # No color/turn off all tput attributes

# Other
readonly SCRIPT_NAME=$(basename "$0")
readonly TEST_STREAMER="loltyler1"
readonly CORRECT_OUTPUT_DIR="$(dirname "$0")/unit-test-output"
readonly DUMMY_DATA_DIR="$(dirname "$0")/dummy-data"
testName=""

# Temporary file to output to for comparison
readonly TMP_DIR="$(mktemp -d -t "${SCRIPT_NAME}_XXXXXXXX")"
readonly TMP_DIR_FILE="${TMP_DIR}/outputToTest"

# Step variables
stepCounter=1
stepWithColor="${PURPLE}${stepCounter}${NC}"

# -----------------------------------------
# --------------- Functions ---------------
# -----------------------------------------

clean_up()
{
  rm -rf "${TMP_DIR}"
}

#######################################
# Compares output for a specified test.
# Globals:
#   TMP_DIR_FILE
#   CORRECT_OUTPUT_DIR
# Arguments:
#   $1: file name of correct output
#   $2: name of test
# Returns:
#   none
#######################################
compare_output()
{
  if cmp --silent "${TMP_DIR_FILE}" "${CORRECT_OUTPUT_DIR}/$1"; then
    print_success "$2"
  else
    print_failure "$2"
    exit 1
  fi
}

#######################################
# Properly configures stepWithColor.
# Globals:
#   stepCounter, stepWithColor, PURPLE, NC
# Arguments:
#   none
# Returns:
#   none
#######################################
complete_step()
{
  stepCounter=$(( stepCounter + 1 ))
  stepWithColor="${PURPLE}${stepCounter}${NC}"
}

#######################################
# Prints passed error message before premature exit.
# Prints everything to >&2 (STDERR).
# Globals:
#   RED, NC
#   SCRIPT_NAME
# Arguments:
#   $1: error message to print
# Returns:
#   none
#######################################
exit_script_on_failure()
{
  printf "%sError%s: %s\n" "${RED}" "${NC}" "$1" >&2
  printf "Exiting %s Bash script.\n" "${SCRIPT_NAME}" >&2

  exit 1
}

print_success()
{
  printf "%s %spassed%s.\n" "$1" "${GREEN}" "${NC}"
}

print_failure()
{
  printf "%s %sfailed%s.\n" "$1" "${RED}" "${NC}"
}

# -----------------------------------------
# ---------------- Script -----------------
# -----------------------------------------

if [ "$(whoami)" = "root" ]; then
  exit_script_on_failure "This script should NOT be run as root (or sudo)!"
fi

printf "\n%s. Testing blocklist functionality...\n" "${stepWithColor}"

testName="Add to blocklist"
bash wtwitch b "${TEST_STREAMER}" 2>&1 | tee "${TMP_DIR_FILE}"
compare_output "blocklist_one" "${testName}"

testName="Remove from blocklist"
bash wtwitch b "${TEST_STREAMER}" 2>&1 | tee "${TMP_DIR_FILE}"
compare_output "blocklist_two" "${testName}"

complete_step

printf "\n%s. Testing subscribe functionality...\n" "${stepWithColor}"

testName="Subscribe to"
bash wtwitch s "${TEST_STREAMER}" 2>&1 | tee "${TMP_DIR_FILE}"
compare_output "subscribe_success" "${testName}"

testName="Subscribe to (already subscribed)"
bash wtwitch s "${TEST_STREAMER}" 2>&1 | tee "${TMP_DIR_FILE}"
compare_output "subscribe_failure" "${testName}"

complete_step

printf "\n%s. Testing unsubscribe functionality...\n" "${stepWithColor}"

testName="Unsubscribe from"
bash wtwitch u "${TEST_STREAMER}" 2>&1 | tee "${TMP_DIR_FILE}"
compare_output "unsubscribe_success" "${testName}"

testName="Unsubscribe from (not subscribed)"
bash wtwitch u "${TEST_STREAMER}" 2>&1 | tee "${TMP_DIR_FILE}"
compare_output "unsubscribe_failure" "${testName}"

complete_step

printf "\n%s. Testing change player functionality...\n" "${stepWithColor}"

testName="Change player"
bash wtwitch p mpv 2>&1 | tee "${TMP_DIR_FILE}"
compare_output "change_player_success" "${testName}"

testName="Change player (vlc not installed)"
bash wtwitch p vlc 2>&1 | tee "${TMP_DIR_FILE}"
compare_output "change_player_failure" "${testName}"

complete_step

printf "\n%s. Testing change quality functionality...\n" "${stepWithColor}"

testName="Change quality"
bash wtwitch q 1080p60,720p,best 2>&1 | tee "${TMP_DIR_FILE}"
compare_output "change_quality_success" "${testName}"

testName="Change quality (invalid quality)"
bash wtwitch q 1080p,490p 2>&1 | tee "${TMP_DIR_FILE}"
compare_output "change_quality_failure" "${testName}"

# Change back to my setting :)
bash wtwitch q best > /dev/null

complete_step

printf "\n%s. Testing check_twitch_streams with dummy data...\n" "${stepWithColor}"

testName="check_twitch_streams"
DUMMY_DATA="${DUMMY_DATA_DIR}/check_twitch_streams.json" bash wtwitch c 2>&1 | tee "${TMP_DIR_FILE}"
compare_output "check_twitch_streams" "${testName}"

complete_step

printf "\n%s. Testing list_streamers_of_game with dummy data...\n" "${stepWithColor}"

testName="list_streamers_of_game"
DUMMY_DATA="${DUMMY_DATA_DIR}/list_streamers_of_game.json" bash wtwitch g overwatch 2>&1 | tee "${TMP_DIR_FILE}"
compare_output "list_streamers_of_game" "${testName}"

complete_step

printf "\n%s. Testing search_categories with dummy data...\n" "${stepWithColor}"

testName="search_categories"
DUMMY_DATA="${DUMMY_DATA_DIR}/search_categories.json" bash wtwitch e w 2>&1 | tee "${TMP_DIR_FILE}"
compare_output "search_categories" "${testName}"

complete_step

printf "\n%s. Testing search_channels with dummy data...\n" "${stepWithColor}"

testName="search_channels"
DUMMY_DATA="${DUMMY_DATA_DIR}/search_channels.json" bash wtwitch n w 2>&1 | tee "${TMP_DIR_FILE}"
compare_output "search_channels" "${testName}"

complete_step
