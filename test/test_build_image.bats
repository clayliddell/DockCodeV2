#!/usr/bin/env bats
# test_build_image.bats — build_image

load test_helper

@test "build_image: copies opencode.json and Dockerfile to temp dir" {
	echo '{"model":"test"}' >"${OPENCODE_CONFIG}"
	set_mock_response "build" ""

	run build_image
	[[ "${status}" -eq 0 ]]
	assert_docker_called_with "docker build"
}

@test "build_image: calls docker build with correct template tag" {
	echo '{"model":"test"}' >"${OPENCODE_CONFIG}"
	set_mock_response "build" ""

	run build_image
	[[ "${status}" -eq 0 ]]
	assert_docker_called_with "opencode-openrouter:v1"
}

@test "build_image: outputs building info message" {
	echo '{"model":"test"}' >"${OPENCODE_CONFIG}"
	set_mock_response "build" ""

	run build_image
	[[ "${output}" == *"Building custom sandbox image"* ]]
}
