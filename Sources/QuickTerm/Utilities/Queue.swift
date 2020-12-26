/*
 First-in first-out queue (FIFO)
 New elements are added to the end of the queue. Dequeuing pulls elements from
 the front of the queue.
 Enqueuing and dequeuing are O(1) operations.
 */
public struct Queue<T> {
  private var array = [T?]()
  private var head = 0

  public var isEmpty: Bool {
    (self.array.count - self.head) == 0
  }

  public var count: Int {
    self.array.count - self.head
  }

  public mutating func enqueue(_ element: T) {
    self.array.append(element)
  }

  public mutating func dequeue() -> T? {
    guard let element = array[guarded: head] else { return nil }

    self.array[self.head] = nil
    self.head += 1

    let percentage = Double(head) / Double(self.array.count)
    if self.array.count > 50, percentage > 0.25 {
      self.array.removeFirst(self.head)
      self.head = 0
    }

    return element
  }

  public var front: T? {
    if self.isEmpty {
      return nil
    } else {
      return self.array[self.head]
    }
  }
}

extension Array {
  subscript(guarded idx: Int) -> Element? {
    guard (startIndex ..< endIndex).contains(idx) else {
      return nil
    }
    return self[idx]
  }
}
