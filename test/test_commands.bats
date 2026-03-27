#!/usr/bin/env bats
# test_commands.bats — handle_config_show, handle_config_update, handle_ls, handle_destroy

load test_helper

# ─── handle_config_show ─────────────────────────────────────────────────────

@test "handle_config_show: prints correct paths" {
	run handle_config_show
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"opencode.json"* ]]
	[[ "${output}" == *"auth.json"* ]]
	[[ "${output}" == *"${OPENCODE_CONFIG}"* ]]
	[[ "${output}" == *"${AUTH_CONFIG}"* ]]
}

# ─── handle_config_update ───────────────────────────────────────────────────

@test "handle_config_update: updates opencode.json key" {
	mkdir -p "${TEST_TMPDIR}"
	echo '{}' >"${TEST_TMPDIR}/my-opencode.json"
	run handle_config_update "opencode.json" "${TEST_TMPDIR}/my-opencode.json"
	[[ "${status}" -eq 0 ]]
	result="$(get_config OPENCODE_CONFIG)"
	[[ "${result}" == "${TEST_TMPDIR}/my-opencode.json" ]]
}

@test "handle_config_update: updates auth.json key" {
	mkdir -p "${TEST_TMPDIR}"
	echo '{}' >"${TEST_TMPDIR}/my-auth.json"
	run handle_config_update "auth.json" "${TEST_TMPDIR}/my-auth.json"
	[[ "${status}" -eq 0 ]]
	result="$(get_config AUTH_CONFIG)"
	[[ "${result}" == "${TEST_TMPDIR}/my-auth.json" ]]
}

@test "handle_config_update: errors on unknown key" {
	run handle_config_update "unknown.json" "/tmp/value"
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"Unknown key"* ]]
}

@test "handle_config_update: errors on missing args" {
	run handle_config_update
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"Usage:"* ]]
}

@test "handle_config_update: errors on missing value" {
	run handle_config_update "opencode.json"
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"Usage:"* ]]
}

@test "handle_config_update: expands tilde in value" {
	run handle_config_update "opencode.json" "~/test.json"
	[[ "${status}" -eq 0 ]]
	result="$(get_config OPENCODE_CONFIG)"
	[[ "${result}" == "${HOME}/test.json" ]]
}

# ─── handle_ls ──────────────────────────────────────────────────────────────

@test "handle_ls: --json returns raw output" {
	set_mock_response "sandbox_ls" '{"vms":[{"name":"test"}]}'
	run handle_ls --json
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == '{"vms":[{"name":"test"}]}' ]]
}

@test "handle_ls: empty shows no sandboxes message" {
	set_mock_response "sandbox_ls" '{"vms":[]}'
	run handle_ls
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"No sandboxes found"* ]]
}

@test "handle_ls: populated shows numbered list" {
	set_mock_response "sandbox_ls" '{"vms":[{"name":"proj-a"},{"name":"proj-b"}]}'
	run handle_ls
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"1) proj-a"* ]]
	[[ "${output}" == *"2) proj-b"* ]]
	[[ "${output}" == *"Total: 2"* ]]
}

# ─── handle_destroy ─────────────────────────────────────────────────────────

@test "handle_destroy: -n flag with confirmation destroys sandbox" {
	set_mock_response "sandbox_rm" ""
	run bash -c '
		source "'"${SCRIPT_DIR}"'/dockcode"
		export DOCKCODE_CONFIG_DIR="'"${DOCKCODE_CONFIG_DIR}"'"
		export CONFIG_FILE="'"${CONFIG_FILE}"'"
		export MOCK_CALLS="'"${MOCK_CALLS}"'"
		export MOCK_RESPONSES_DIR="'"${MOCK_RESPONSES_DIR}"'"
		handle_destroy -n test-sandbox <<< "y"
	'
	[[ "${status}" -eq 0 ]]
	assert_docker_called_with "sandbox rm test-sandbox"
	[[ "${output}" == *"destroyed"* ]]
}

@test "handle_destroy: abort on non-affirmative confirmation" {
	set_mock_response "sandbox_rm" ""
	run bash -c '
		source "'"${SCRIPT_DIR}"'/dockcode"
		export DOCKCODE_CONFIG_DIR="'"${DOCKCODE_CONFIG_DIR}"'"
		export CONFIG_FILE="'"${CONFIG_FILE}"'"
		export MOCK_CALLS="'"${MOCK_CALLS}"'"
		export MOCK_RESPONSES_DIR="'"${MOCK_RESPONSES_DIR}"'"
		handle_destroy -n test-sandbox <<< "n"
	'
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Aborted"* ]]
}

@test "handle_destroy: errors on unknown flag" {
	run handle_destroy --unknown
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"Unknown flag"* ]]
}

@test "handle_destroy: errors when -n has no value" {
	run handle_destroy -n
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"requires a value"* ]]
}

@test "handle_destroy: interactive mode with no sandboxes" {
	set_mock_response "sandbox_ls" '{"vms":[]}'
	run handle_destroy
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"No sandboxes to destroy"* ]]
}

@test "handle_destroy: interactive mode with sandboxes" {
	set_mock_response "sandbox_ls" '{"vms":[{"name":"sb1"}]}'
	set_mock_response "sandbox_rm" ""
	run bash -c '
		source "'"${SCRIPT_DIR}"'/dockcode"
		export DOCKCODE_CONFIG_DIR="'"${DOCKCODE_CONFIG_DIR}"'"
		export CONFIG_FILE="'"${CONFIG_FILE}"'"
		export MOCK_CALLS="'"${MOCK_CALLS}"'"
		export MOCK_RESPONSES_DIR="'"${MOCK_RESPONSES_DIR}"'"
		printf "1\ny\n" | handle_destroy
	'
	[[ "${status}" -eq 0 ]]
	assert_docker_called_with "sandbox rm sb1"
}
