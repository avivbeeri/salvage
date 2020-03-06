// This implements the interface for some common data types

// A FIFO queue
class Queue {
  construct init() {
    _list = []
  }
  enqueue(item) { _list.add(item) }
  dequeue() { _list.removeAt(0) }
  peek() { _list[0] }

  empty { _list.count == 0 }
  count { _list.count }
}


class Heap {
  construct init() {
    _comparator = Fn.new {|a, b| a - b }
    _list = []
    _size = 0
  }
  construct init(comparator) {
    _comparator = comparator
    _list = []
    _size = 0
  }

  swap(i1, i2) {
    var temp = _list[i1]
    _list[i1] = _list[i2]
    _list[i2] = temp
  }

  compare(a, b) {
    return _comparator.call(a, b)
  }

  percolateUp(pos) {
    while (pos > 1) {
      var parent = (pos/2).floor
      if (compare(_list[pos], _list[parent]) >= 0) {
        break
      }
      swap(parent, pos)
      pos = parent
    }
  }

  insert(element) {
    _list.insert(0, element)
    percolateDown(0)
    // percolateUp(_list.count - 1)
  }

  del() {
    if (_list.count == 0) {
      return null
    }
    if (_list.count == 1) {
      return _list.removeAt(0)
    }
    var top = _list[0]
    var last = _list.count - 1
    swap(0, last)
    _list.removeAt(last)
    percolateUp(0)
    percolateDown(0)
    // percolate root down
    return top
  }

  percolateDown(pos) {
    var last = _list.count - 1
    while (true) {
      var min = pos
      var child = 2 * pos
      for (c in child .. child + 1) {
        if (c <= last && compare(_list[c], _list[min]) < 0) {
          min = c
        }
      }

      if (min == pos) {
        break
      }

      swap(pos, min)
      pos = min
    }
  }
}

class Hashable {
  hash() { this.toString }
}
class Set {
  construct init() {
    _map = {}
  }

  empty { _map.count == 0 }
  values { _map.values }

  has(value) {
    var hash = value
    if (value is Hashable) {
      hash = value.hash()
    }
    return _map.containsKey(hash)
  }

  remove(value) {
    var hash = value
    if (value is Hashable) {
      hash = value.hash()
    }
    return _map.remove(hash)
  }

  put(value) {
    var hash = value
    if (value is Hashable) {
      hash = value.hash()
    }
    _map[hash] = value
  }
}

