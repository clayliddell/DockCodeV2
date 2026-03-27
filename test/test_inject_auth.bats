#!/usr/bin/env bats
# test_inject_auth.bats — inject_auth

load test_helper

@test "inject_auth: creates remote directory" {
	echo '{"key":"test"}' >"${AUTH_CONFIG}"
	set_mock_response "sandbox_exec" ""

	run inject_auth "${AUTH_CONFIG}" "test-sandbox"
	[[ "${status}" -eq 0 ]]
	assert_docker_called_with "mkdir -p"
}

@test "inject_auth: cats auth file via stdin" {
	echo '{"key":"test"}' >"${AUTH_CONFIG}"
	set_mock_response "sandbox_exec" ""

	run inject_auth "${AUTH_CONFIG}" "test-sandbox"
	[[ "${status}" -eq 0 ]]
	assert_docker_called_with "cat >"
}

@test "inject_auth: sets chmod 600 on auth file" {
	echo '{"key":"test"}' >"${AUTH_CONFIG}"
	set_mock_response "sandbox_exec" ""

	run inject_auth "${AUTH_CONFIG}" "test-sandbox"
	[[ "${status}" -eq 0 ]]
	assert_docker_called_with "chmod 600"
}

@test "inject_auth: uses correct remote path" {
	echo '{"key":"test"}' >"${AUTH_CONFIG}"
	set_mock_response "sandbox_exec" ""

	run inject_auth "${AUTH_CONFIG}" "test-sandbox"
	[[ "${status}" -eq 0 ]]
	assert_docker_called_with ".local/share/opencode"
}
