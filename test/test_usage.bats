#!/usr/bin/env bats
# test_usage.bats — show_usage, --help, --version, invalid commands

load test_helper

@test "--help shows usage text" {
	run "${SCRIPT_DIR}/dockcode" --help
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"Usage: dockcode"* ]]
	[[ "${output}" == *"Commands:"* ]]
	[[ "${output}" == *"config show"* ]]
	[[ "${output}" == *"launch"* ]]
	[[ "${output}" == *"ls"* ]]
}

@test "-h shows usage text" {
	run "${SCRIPT_DIR}/dockcode" -h
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"Usage: dockcode"* ]]
}

@test "--version shows version" {
	run "${SCRIPT_DIR}/dockcode" --version
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"dockcode v"* ]]
}

@test "no args shows usage" {
	run "${SCRIPT_DIR}/dockcode"
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"Usage: dockcode"* ]]
}

@test "unknown command shows usage" {
	run "${SCRIPT_DIR}/dockcode" foobar
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"Usage: dockcode"* ]]
}

@test "config without subcommand shows usage" {
	run "${SCRIPT_DIR}/dockcode" config
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"Usage: dockcode"* ]]
}

@test "settings without subcommand shows usage" {
	run "${SCRIPT_DIR}/dockcode" settings
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"Usage: dockcode"* ]]
}

@test "config show routes to handle_config_show" {
	run "${SCRIPT_DIR}/dockcode" config show
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"opencode.json"* ]]
}

@test "config update routes to handle_config_update" {
	run "${SCRIPT_DIR}/dockcode" config update
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"Usage:"* ]]
}

@test "ls routes to handle_ls" {
	set_mock_response "sandbox_ls" '{"vms":[]}'
	run "${SCRIPT_DIR}/dockcode" ls
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"No sandboxes found"* ]]
}

@test "rm routes to handle_destroy" {
	set_mock_response "sandbox_ls" '{"vms":[]}'
	run "${SCRIPT_DIR}/dockcode" rm
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"No sandboxes to destroy"* ]]
}
