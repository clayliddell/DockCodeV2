#!/usr/bin/env bats
# test_sandbox_list.bats — get_sandbox_names (jq path + fallback path)

load test_helper

@test "get_sandbox_names: jq available with vms present returns names" {
	set_mock_response "sandbox_ls" '{"vms":[{"name":"proj-a"},{"name":"proj-b"}]}'
	run get_sandbox_names
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"proj-a"* ]]
	[[ "${output}" == *"proj-b"* ]]
}

@test "get_sandbox_names: jq available with empty vms returns nothing" {
	set_mock_response "sandbox_ls" '{"vms":[]}'
	run get_sandbox_names
	[[ "${status}" -eq 0 ]]
	[[ -z "${output}" ]]
}

@test "get_sandbox_names: falls back when docker sandbox ls fails" {
	set_mock_response_exit "sandbox_ls" 1 ""
	run get_sandbox_names
	[[ "${status}" -eq 0 ]]
	[[ -z "${output}" ]]
}

@test "get_sandbox_names: fallback parsing with names when jq unavailable" {
	# Create a fake PATH without jq
	local fake_bin="${TEST_TMPDIR}/fakebin"
	mkdir -p "${fake_bin}"
	for cmd in docker bash cat grep sed tr echo; do
		local real_path
		real_path="$(command -v "${cmd}" 2>/dev/null || true)"
		[[ -n "${real_path}" ]] && ln -sf "${real_path}" "${fake_bin}/${cmd}"
	done
	set_mock_response "sandbox_ls" '{"vms":[{"name":"test-sandbox"}]}'

	run env PATH="${SCRIPT_DIR}/test:${fake_bin}" bash -c '
		source "'"${SCRIPT_DIR}"'/dockcode"
		export MOCK_CALLS="'"${MOCK_CALLS}"'"
		export MOCK_RESPONSES_DIR="'"${MOCK_RESPONSES_DIR}"'"
		get_sandbox_names
	'
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"test-sandbox"* ]]
}
