package utils

import "base:runtime"

SEED :: 123456789

hash :: proc(s: ^string) -> uintptr {
	return runtime.default_hasher_string(s, SEED)
}

map_hash_to_index :: proc(hash: uintptr, capacity: uintptr) -> uintptr {
	return uintptr(hash & uintptr(capacity - 1))
}
