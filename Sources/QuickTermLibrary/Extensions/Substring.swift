extension Substring {
  offset(by offset: Int) -> Substring {
    return self[self.index(self.startIndex, offsetBy: offset)..<self.endIndex]
  }

  // TODO: actually consume the substring (change the index of text)
  consumeAll(of compare: (Character) -> Bool) -> Substring? {
    var length = 0
    // Consume all characters
    while let character = slice.first && compare(character) {
      length++
      slice = slice.offset(by: 1)
    }

    if length == 0 {
      return nil
    } else {
      return text[text.startIndex..<text.index(text.startIndex, offsetBy: length)]
    }
  }
}
