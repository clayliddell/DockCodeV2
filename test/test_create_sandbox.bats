#!/usr/bin/env bats
# test_create_sandbox.bats — create_sandbox

load test_helper

@test "create_sandbox: exits when docker context fails" {
	set_mock_response_exit "context_use" 1 "context not found"
	echo '{"model":"test"}' >"${OPENCODE_CONFIG}"

	run create_sandbox "test-sandbox" "/tmp/workspace"
	[[ "${status}" -eq 1 ]]
	[[ "${output}" == *"Docker Desktop context"* ]]
}

@test "create_sandbox: removes existing sandbox before creating" {
	set_mock_response "context_use" ""
	set_mock_response "build" ""
	set_mock_response "sandbox_rm" ""
	set_mock_response "sandbox_create" ""
	set_mock_response "sandbox_network" ""
	set_mock_response "sandbox_exec" ""
	echo '{"model":"test"}' >"${OPENCODE_CONFIG}"
	echo '{"openrouter":{"type":"api","key":"sk-or-v1-test"}}' >"${AUTH_CONFIG}"

	run create_sandbox "test-sandbox" "/tmp/workspace"
	[[ "${status}" -eq 0 ]]
	assert_docker_called_with "sandbox rm test-sandbox"
}

@test "create_sandbox: creates sandbox with correct args" {
	set_mock_response "context_use" ""
	set_mock_response "build" ""
	set_mock_response "sandbox_rm" ""
	set_mock_response "sandbox_create" ""
	set_mock_response "sandbox_network" ""
	set_mock_response "sandbox_exec" ""
	echo '{"model":"test"}' >"${OPENCODE_CONFIG}"
	echo '{"openrouter":{"type":"api","key":"sk-or-v1-test"}}' >"${AUTH_CONFIG}"

	run create_sandbox "my-sandbox" "/home/user/project"
	[[ "${status}" -eq 0 ]]
	assert_docker_called_with "sandbox create"
	assert_docker_called_with "my-sandbox"
}

@test "create_sandbox: configures network proxy bypass" {
	set_mock_response "context_use" ""
	set_mock_response "build" ""
	set_mock_response "sandbox_rm" ""
	set_mock_response "sandbox_create" ""
	set_mock_response "sandbox_network" ""
	set_mock_response "sandbox_exec" ""
	echo '{"model":"test"}' >"${OPENCODE_CONFIG}"
	echo '{"openrouter":{"type":"api","key":"sk-or-v1-test"}}' >"${AUTH_CONFIG}"

	run create_sandbox "test-sandbox" "/tmp/workspace"
	[[ "${status}" -eq 0 ]]
	assert_docker_called_with "bypass-host"
	assert_docker_called_with "api.openrouter.ai"
	assert_docker_called_with "openrouter.ai"
}

@test "create_sandbox: warns on placeholder API key" {
	set_mock_response "context_use" ""
	set_mock_response "build" ""
	set_mock_response "sandbox_rm" ""
	set_mock_response "sandbox_create" ""
	set_mock_response "sandbox_network" ""
	set_mock_response "sandbox_exec" ""
	echo '{"model":"test"}' >"${OPENCODE_CONFIG}"
	echo '{"openrouter":{"type":"api","key":"sk-or-v1-CHANGE-ME"}}' >"${AUTH_CONFIG}"

	run create_sandbox "test-sandbox" "/tmp/workspace"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"placeholder API key"* ]]
}

@test "create_sandbox: does not warn on valid API key" {
	set_mock_response "context_use" ""
	set_mock_response "build" ""
	set_mock_response "sandbox_rm" ""
	set_mock_response "sandbox_create" ""
	set_mock_response "sandbox_network" ""
	set_mock_response "sandbox_exec" ""
	echo '{"model":"test"}' >"${OPENCODE_CONFIG}"
	echo '{"openrouter":{"type":"api","key":"sk-or-v1-real-key-12345"}}' >"${AUTH_CONFIG}"

	run create_sandbox "test-sandbox" "/tmp/workspace"
	[[ "${status}" -eq 0 ]]
	[[ "${output}" != *"placeholder"* ]]
}
