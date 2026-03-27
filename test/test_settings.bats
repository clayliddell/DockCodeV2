#!/usr/bin/env bats
# test_settings.bats — resolve_sandbox_name, handle_settings_print, handle_settings_update

load test_helper

@test "resolve_sandbox_name: returns name when provided" {
	run resolve_sandbox_name "my-sandbox"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == "my-sandbox" ]]
}

@test "resolve_sandbox_name: interactive selection when name empty and sandboxes exist" {
	set_mock_response "sandbox_ls" '{"vms":[{"name":"sb1"},{"name":"sb2"}]}'

	run bash -c '
		source "'"${SCRIPT_DIR}"'/dockcode"
		export DOCKCODE_CONFIG_DIR="'"${DOCKCODE_CONFIG_DIR}"'"
		export CONFIG_FILE="'"${CONFIG_FILE}"'"
		export MOCK_CALLS="'"${MOCK_CALLS}"'"
		export MOCK_RESPONSES_DIR="'"${MOCK_RESPONSES_DIR}"'"
		resolve_sandbox_name "" <<< "1"
	'
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"sb1"* ]]
}

@test "resolve_sandbox_name: returns 1 when no sandboxes exist" {
	set_mock_response "sandbox_ls" '{"vms":[]}'

	run resolve_sandbox_name ""
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"No sandboxes found"* ]]
}

@test "handle_settings_print: prints sandbox config with -n flag" {
	set_mock_response "sandbox_exec" '{"model":"test"}'

	run handle_settings_print -n "test-sandbox"
	[[ "${status}" -eq 0 ]]
	assert_docker_called_with "sandbox exec"
	assert_docker_called_with "opencode.json"
}

@test "handle_settings_print: errors on unknown flag" {
	run handle_settings_print --unknown
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"Unknown flag"* ]]
}

@test "handle_settings_print: errors when -n has no value" {
	run handle_settings_print -n
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"requires a value"* ]]
}

@test "handle_settings_update: choice 2 re-imports from host" {
	echo '{"model":"updated"}' >"${OPENCODE_CONFIG}"
	set_mock_response "sandbox_ls" '{"vms":[{"name":"test-sandbox"}]}'
	set_mock_response "sandbox_exec" ""

	run bash -c '
		source "'"${SCRIPT_DIR}"'/dockcode"
		export DOCKCODE_CONFIG_DIR="'"${DOCKCODE_CONFIG_DIR}"'"
		export CONFIG_FILE="'"${CONFIG_FILE}"'"
		export OPENCODE_CONFIG="'"${OPENCODE_CONFIG}"'"
		export AUTH_CONFIG="'"${AUTH_CONFIG}"'"
		export MOCK_CALLS="'"${MOCK_CALLS}"'"
		export MOCK_RESPONSES_DIR="'"${MOCK_RESPONSES_DIR}"'"
		handle_settings_update -n test-sandbox <<< "2"
	'
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Config updated from"* ]]
}

@test "handle_settings_update: errors on unknown flag" {
	run handle_settings_update --unknown
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"Unknown flag"* ]]
}

@test "handle_settings_update: errors when -n has no value" {
	run handle_settings_update -n
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"requires a value"* ]]
}
