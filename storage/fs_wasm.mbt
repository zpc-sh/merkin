///|
/// WASM fallback stubs for filesystem operations.
/// On WASM targets, filesystem operations fall back to in-memory maps.
/// This allows the full storage API to compile on all targets.

///|
/// In-memory filesystem simulation for WASM target.
let fs_memory : Map[String, Bytes] = {}

///|
fn fs_file_exists(path : String) -> Bool {
  fs_memory.contains(path)
}

///|
fn fs_read_file(path : String) -> Bytes? {
  fs_memory.get(path)
}

///|
fn fs_write_file(path : String, data : Bytes) -> Unit {
  fs_memory[path] = data
}

///|
fn fs_mkdir_p(_path : String) -> Unit {
  // No-op on WASM — directories are implicit in the path map
}
