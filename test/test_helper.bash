#!/usr/bin/env bash
# test_helper.bash — shared BATS setup for dockcode tests

SCRIPT_DIR="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." && pwd)"
export SCRIPT_DIR

# Source the dockcode script to load all function definitions.
# The command dispatch block is guarded and won't execute when sourced.
source "${SCRIPT_DIR}/dockcode"

setup() {
	TEST_TMPDIR="$(mktemp -d)"
	export TEST_TMPDIR

	# Override all config paths to use temp dir
	# These are set at source time, so must be re-assigned
	DOCKCODE_CONFIG_DIR="${TEST_TMPDIR}/config"
	CONFIG_FILE="${DOCKCODE_CONFIG_DIR}/config"
	DEFAULT_OPENCODE_CONFIG="${DOCKCODE_CONFIG_DIR}/opencode.json"
	DEFAULT_AUTH_CONFIG="${DOCKCODE_CONFIG_DIR}/auth.json"
	OPENCODE_CONFIG="${DOCKCODE_CONFIG_DIR}/opencode.json"
	AUTH_CONFIG="${DOCKCODE_CONFIG_DIR}/auth.json"

	export DOCKCODE_CONFIG_DIR CONFIG_FILE
	export DEFAULT_OPENCODE_CONFIG DEFAULT_AUTH_CONFIG
	export OPENCODE_CONFIG AUTH_CONFIG

	mkdir -p "${DOCKCODE_CONFIG_DIR}"

	# Mock infrastructure
	export MOCK_CALLS="${TEST_TMPDIR}/mock_calls"
	export MOCK_RESPONSES_DIR="${TEST_TMPDIR}/mock_responses"
	touch "${MOCK_CALLS}"
	mkdir -p "${MOCK_RESPONSES_DIR}"

	# Put mock_docker on PATH ahead of real docker
	export PATH="${SCRIPT_DIR}/test:${PATH}"
}

teardown() {
	rm -rf "${TEST_TMPDIR}"
}

# Helper to set a mock response
# Usage: set_mock_response "sandbox_ls" '{"vms":[]}'
set_mock_response() {
	local key="$1"
	shift
	mkdir -p "${MOCK_RESPONSES_DIR}"
	printf '%s\n' "$@" >"${MOCK_RESPONSES_DIR}/${key}"
}

# Helper to set a mock response with explicit exit code
# Usage: set_mock_response_exit "sandbox_ls" 1 'error output'
set_mock_response_exit() {
	local key="$1" exit_code="$2"
	shift 2
	mkdir -p "${MOCK_RESPONSES_DIR}"
	printf 'exit:%s\n' "${exit_code}" >"${MOCK_RESPONSES_DIR}/${key}"
	printf '%s\n' "$@" >>"${MOCK_RESPONSES_DIR}/${key}"
}

# Helper to get recorded mock calls
get_mock_calls() {
	cat "${MOCK_CALLS}" 2>/dev/null || true
}

# Assert a docker command was called with specific arguments
assert_docker_called_with() {
	local expected="$1"
	grep -qF "${expected}" "${MOCK_CALLS}" 2>/dev/null || {
		echo "Expected docker call containing: ${expected}"
		echo "Actual calls:"
		cat "${MOCK_CALLS}" 2>/dev/null || echo "(none)"
		return 1
	}
}

# Assert no docker calls were made
assert_no_docker_calls() {
	if [[ -s "${MOCK_CALLS}" ]]; then
		echo "Expected no docker calls but found:"
		cat "${MOCK_CALLS}"
		return 1
	fi
}

# Count docker calls matching a pattern
count_mock_calls() {
	local pattern="$1"
	grep -cF "${pattern}" "${MOCK_CALLS}" 2>/dev/null || echo 0
}
