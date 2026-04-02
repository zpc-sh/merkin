///|
fn parse_u32_opt(raw : String?) -> UInt? {
  match raw {
    Some(text) => {
      if text.length() == 0 {
        return None
      }
      let bytes = text.to_bytes()
      let mut out : UInt = 0U
      let mut i : Int = 0
      while i < bytes.length() {
        let b = bytes[i].to_int()
        if b < 48 || b > 57 {
          return None
        }
        out = out * 10U + (b.to_uint() - 48U)
        i = i + 1
      }
      Some(out)
    }
    None => None
  }
}
