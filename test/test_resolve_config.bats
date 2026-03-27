#!/usr/bin/env bats
# test_resolve_config.bats — resolve_config (all 4 choices + error paths)

load test_helper

@test "resolve_config: returns early when target already exists" {
	local target="${TEST_TMPDIR}/existing.json"
	echo '{"test":true}' >"${target}"
	local default="${TEST_TMPDIR}/default.json"
	echo '{"default":true}' >"${default}"

	run resolve_config "${target}" "${default}" "opencode.json" "opencode.json" "/tmp/host.json"
	[[ "${status}" -eq 0 ]]
	grep -q '"test":true' "${target}"
}

@test "resolve_config: choice 1 copies project default" {
	local target="${TEST_TMPDIR}/new.json"
	local default="${TEST_TMPDIR}/default.json"
	echo '{"default":true}' >"${default}"

	# "1\n" for prompt_choice, then "x" for read -n 1 press-any-key
	run bash -c '
		source "'"${SCRIPT_DIR}"'/dockcode"
		export DOCKCODE_CONFIG_DIR="'"${DOCKCODE_CONFIG_DIR}"'"
		export CONFIG_FILE="'"${CONFIG_FILE}"'"
		printf "1\nx" | resolve_config "'"${target}"'" "'"${default}"'" "opencode.json" "opencode.json" "/tmp/host.json"
	'
	[[ "${status}" -eq 0 ]]
	[[ -f "${target}" ]]
	grep -q '"default":true' "${target}"
}

@test "resolve_config: choice 1 error when default not found" {
	local target="${TEST_TMPDIR}/new.json"
	local default="${TEST_TMPDIR}/nonexistent.json"
	local host_file="${TEST_TMPDIR}/host.json"
	echo '{"host":true}' >"${host_file}"

	# "1\n" fails (default missing), then "3\n" copies host
	run bash -c '
		source "'"${SCRIPT_DIR}"'/dockcode"
		export DOCKCODE_CONFIG_DIR="'"${DOCKCODE_CONFIG_DIR}"'"
		export CONFIG_FILE="'"${CONFIG_FILE}"'"
		printf "1\n3" | resolve_config "'"${target}"'" "'"${default}"'" "opencode.json" "opencode.json" "'"${host_file}"'"
	'
	[[ "${output}" == *"Project default not found"* ]]
	[[ -f "${target}" ]]
}

@test "resolve_config: choice 3 copies host config to target" {
	local target="${TEST_TMPDIR}/subdir/new.json"
	local default="${TEST_TMPDIR}/default.json"
	echo '{"default":true}' >"${default}"
	local host_file="${TEST_TMPDIR}/host.json"
	echo '{"host":true}' >"${host_file}"

	run bash -c '
		source "'"${SCRIPT_DIR}"'/dockcode"
		export DOCKCODE_CONFIG_DIR="'"${DOCKCODE_CONFIG_DIR}"'"
		export CONFIG_FILE="'"${CONFIG_FILE}"'"
		printf "3" | resolve_config "'"${target}"'" "'"${default}"'" "opencode.json" "opencode.json" "'"${host_file}"'"
	'
	[[ "${status}" -eq 0 ]]
	[[ -f "${target}" ]]
	grep -q '"host":true' "${target}"
}

@test "resolve_config: choice 4 with custom path" {
	local target="${TEST_TMPDIR}/new.json"
	local default="${TEST_TMPDIR}/default.json"
	echo '{"default":true}' >"${default}"
	local custom_file="${TEST_TMPDIR}/custom.json"
	echo '{"custom":true}' >"${custom_file}"

	# Choice 4 updates config to point to custom path, doesn't copy file
	run bash -c '
		source "'"${SCRIPT_DIR}"'/dockcode"
		export DOCKCODE_CONFIG_DIR="'"${DOCKCODE_CONFIG_DIR}"'"
		export CONFIG_FILE="'"${CONFIG_FILE}"'"
		printf "4\n'"${custom_file}"'\n" | resolve_config "'"${target}"'" "'"${default}"'" "opencode.json" "opencode.json" "/tmp/host.json"
	'
	[[ "${status}" -eq 0 ]]
	[[ "${output}" == *"Copied opencode.json"* ]]
}

@test "resolve_config: choice 4 error when custom path not found" {
	local target="${TEST_TMPDIR}/new.json"
	local default="${TEST_TMPDIR}/default.json"
	echo '{"default":true}' >"${default}"

	# "4\n/nonexistent\n" fails, then "3\n" copies default as host
	run bash -c '
		source "'"${SCRIPT_DIR}"'/dockcode"
		export DOCKCODE_CONFIG_DIR="'"${DOCKCODE_CONFIG_DIR}"'"
		export CONFIG_FILE="'"${CONFIG_FILE}"'"
		printf "4\n/nonexistent/path.json\n3" | resolve_config "'"${target}"'" "'"${default}"'" "opencode.json" "opencode.json" "'"${default}"'"
	'
	[[ "${output}" == *"File not found"* ]]
}

@test "resolve_config: creates parent directory for target" {
	local target="${TEST_TMPDIR}/deep/nested/dir/config.json"
	local default="${TEST_TMPDIR}/default.json"
	echo '{"default":true}' >"${default}"
	local host_file="${TEST_TMPDIR}/host.json"
	echo '{"host":true}' >"${host_file}"

	run bash -c '
		source "'"${SCRIPT_DIR}"'/dockcode"
		export DOCKCODE_CONFIG_DIR="'"${DOCKCODE_CONFIG_DIR}"'"
		export CONFIG_FILE="'"${CONFIG_FILE}"'"
		printf "3\n" | resolve_config "'"${target}"'" "'"${default}"'" "opencode.json" "opencode.json" "'"${host_file}"'"
	'
	[[ "${status}" -eq 0 ]]
	[[ -d "$(dirname "${target}")" ]]
}
