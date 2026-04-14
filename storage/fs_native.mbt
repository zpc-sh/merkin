///|
/// POSIX filesystem FFI for native target.
/// Provides read/write/mkdir/exists operations via libc calls.

///|
#borrow(path)
extern "c" fn c_open(path : Bytes, flags : Int, mode : Int) -> Int = "open"

///|
#borrow(buf)
extern "c" fn c_read(fd : Int, buf : Bytes, count : Int) -> Int = "read"

///|
#borrow(buf)
extern "c" fn c_write(fd : Int, buf : Bytes, count : Int) -> Int = "write"

///|
extern "c" fn c_close(fd : Int) -> Int = "close"

///|
#borrow(path)
extern "c" fn c_mkdir(path : Bytes, mode : Int) -> Int = "mkdir"

///|
#borrow(path)
extern "c" fn c_access(path : Bytes, mode : Int) -> Int = "access"

///|
#borrow(old_path, new_path)
extern "c" fn c_rename(old_path : Bytes, new_path : Bytes) -> Int = "rename"

// POSIX constants

///|
fn o_rdonly() -> Int {
  0
}

///|
fn o_wronly() -> Int {
  1
}

///|
fn o_creat() -> Int {
  0x40
}

///|
fn o_trunc() -> Int {
  0x200
}

///|
fn f_ok() -> Int {
  0
}

///|
fn default_file_mode() -> Int {
  0o644
}

///|
fn default_dir_mode() -> Int {
  0o755
}

///|
fn str_to_cstr(s : String) -> Bytes {
  let chars : Array[Byte] = []
  for ch in s {
    let c = ch.to_uint()
    if c < 0x80U {
      chars.push(c.to_byte())
    } else if c < 0x800U {
      chars.push((0xC0U | (c >> 6)).to_byte())
      chars.push((0x80U | (c & 0x3FU)).to_byte())
    } else if c < 0x10000U {
      chars.push((0xE0U | (c >> 12)).to_byte())
      chars.push((0x80U | ((c >> 6) & 0x3FU)).to_byte())
      chars.push((0x80U | (c & 0x3FU)).to_byte())
    } else {
      chars.push((0xF0U | (c >> 18)).to_byte())
      chars.push((0x80U | ((c >> 12) & 0x3FU)).to_byte())
      chars.push((0x80U | ((c >> 6) & 0x3FU)).to_byte())
      chars.push((0x80U | (c & 0x3FU)).to_byte())
    }
  }
  chars.push(b'\x00') // null terminator
  Bytes::from_array(chars)
}

///|
/// Check if a file exists.
fn fs_file_exists(path : String) -> Bool {
  let cpath = str_to_cstr(path)
  c_access(cpath, f_ok()) == 0
}

///|
/// Read an entire file as Bytes. Returns None if file doesn't exist or can't be read.
fn fs_read_file(path : String) -> Bytes? {
  let cpath = str_to_cstr(path)
  let fd = c_open(cpath, o_rdonly(), 0)
  if fd < 0 {
    return None
  }
  // Read in chunks
  let chunk_size = 4096
  let chunks : Array[Bytes] = []
  let mut total = 0
  let buf = Bytes::new(chunk_size)
  while true {
    let n = c_read(fd, buf, chunk_size)
    if n <= 0 {
      break
    }
    // Copy the read bytes
    let chunk_buf = FixedArray::make(n, b'\x00')
    for i = 0; i < n; i = i + 1 {
      chunk_buf[i] = buf[i]
    }
    chunks.push(Bytes::from_array(chunk_buf))
    total = total + n
  }
  ignore(c_close(fd))
  if total == 0 {
    return Some(Bytes::new(0))
  }
  // Concatenate chunks
  let result_buf = FixedArray::make(total, b'\x00')
  let mut offset = 0
  for chunk in chunks {
    for i = 0; i < chunk.length(); i = i + 1 {
      result_buf[offset] = chunk[i]
      offset = offset + 1
    }
  }
  Some(Bytes::from_array(result_buf))
}

///|
/// Write bytes to a file. Creates or overwrites.
fn fs_write_file(path : String, data : Bytes) -> Unit {
  let cpath = str_to_cstr(path)
  let fd = c_open(
    cpath,
    o_wronly() | o_creat() | o_trunc(),
    default_file_mode(),
  )
  if fd < 0 {
    return
  }
  let mut written = 0
  while written < data.length() {
    let remaining = data.length() - written
    // Create a slice view — write from offset
    let n = c_write(fd, data, remaining)
    if n <= 0 {
      break
    }
    written = written + n
  }
  ignore(c_close(fd))
}

///|
/// mkdir -p: create directory and all parents.
fn fs_mkdir_p(path : String) -> Unit {
  let parts = split_path(path)
  let b = StringBuilder::new(size_hint=256)
  let mut first = true
  for part in parts {
    if !first {
      b.write_char('/')
    }
    b.write_string(part)
    first = false
    let current = b.to_string()
    let cpath = str_to_cstr(current)
    if c_access(cpath, f_ok()) != 0 {
      ignore(c_mkdir(cpath, default_dir_mode()))
    }
  }
}

///|
fn split_path(path : String) -> Array[String] {
  let parts : Array[String] = []
  let cur = StringBuilder::new(size_hint=64)
  for ch in path {
    if ch == '/' {
      let s = cur.to_string()
      if s != "" {
        parts.push(s)
      }
      cur.reset()
    } else {
      cur.write_char(ch)
    }
  }
  let last = cur.to_string()
  if last != "" {
    parts.push(last)
  }
  parts
}
