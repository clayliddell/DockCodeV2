#!/usr/bin/env bats
# test_config.bats — Config I/O: get_config, set_config, init_config

load test_helper

@test "get_config: returns value when key exists" {
	set_config "FOO" "bar"
	result="$(get_config FOO)"
	[[ "${result}" == "bar" ]]
}

@test "get_config: returns default when key is missing" {
	result="$(get_config MISSING "default_val")"
	[[ "${result}" == "default_val" ]]
}

@test "get_config: returns default when config file is missing" {
	rm -f "${CONFIG_FILE}"
	result="$(get_config FOO "fallback")"
	[[ "${result}" == "fallback" ]]
}

@test "get_config: returns first match when key appears multiple times" {
	mkdir -p "$(dirname "${CONFIG_FILE}")"
	printf 'FOO=first\nFOO=second\n' >"${CONFIG_FILE}"
	result="$(get_config FOO)"
	[[ "${result}" == "first" ]]
}

@test "set_config: updates existing key in place" {
	set_config "FOO" "original"
	set_config "FOO" "updated"
	result="$(get_config FOO)"
	[[ "${result}" == "updated" ]]
	# Ensure only one line for this key
	count=$(grep -c "^FOO=" "${CONFIG_FILE}")
	[[ "${count}" -eq 1 ]]
}

@test "set_config: appends when key does not exist" {
	set_config "NEW_KEY" "new_value"
	result="$(get_config NEW_KEY)"
	[[ "${result}" == "new_value" ]]
}

@test "set_config: creates config directory if missing" {
	rm -rf "${DOCKCODE_CONFIG_DIR}"
	set_config "FOO" "bar"
	[[ -d "${DOCKCODE_CONFIG_DIR}" ]]
	[[ -f "${CONFIG_FILE}" ]]
}

@test "init_config: creates config file with defaults when missing" {
	rm -f "${CONFIG_FILE}"
	init_config
	[[ -f "${CONFIG_FILE}" ]]
	grep -q "OPENCODE_CONFIG=" "${CONFIG_FILE}"
	grep -q "AUTH_CONFIG=" "${CONFIG_FILE}"
}

@test "init_config: does not overwrite existing config" {
	mkdir -p "$(dirname "${CONFIG_FILE}")"
	echo "CUSTOM=1" >"${CONFIG_FILE}"
	init_config
	grep -q "CUSTOM=1" "${CONFIG_FILE}"
	! grep -q "OPENCODE_CONFIG=" "${CONFIG_FILE}" || false
}
