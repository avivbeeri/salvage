import "math" for Vec, M

class Elegant {
  static pair(vec) { pair(vec.x, vec.y) }
  static pair(x, y) {
    if (x >= y) {
      return x * x + x + y
    } else {
      return y * y + x
    }
  }

  static unpair(z) {
    var sqrtz = M.floor(z.sqrt)
    var sqz = sqrtz * sqrtz
    if ((z - sqz) > sqrtz) {
      return Vec.new(sqrtz, z - sqz - sqrtz)
    } else {
      return Vec.new(z- sqz, sqrtz)
    }
  }
}

class Tile {
  construct new() {
    init_(0, {})
  }
  construct new(type) {
    init_(type, {})
  }
  construct new(type, data) {
    init_(type, data)
  }

  copy {
    var data = {}
    for (key in _data.keys) {
      data[key] = _data[key]
    }
    return Tile.new(_type, data)
  }

  init_(type, data) {
    _type = type
    _data = data
  }

  type { _type }

  data { _data }
  [index] { _data[index] }
  [index]=(v) { _data[index] = v }
}

var EMPTY_TILE = Tile.new(0, { "dark": false })

class TileMap {
  construct init(width, height, tile) {
    _width = width
    _height = height
    _tiles = List.filled(_width * _height, tile.copy)
  }
  construct init(width, height) {
    _width = width
    _height = height
    _tiles = List.filled(_width * _height, EMPTY_TILE)
  }

  clear(vec) { clear(vec.x, vec.y) }
  clear(x, y) {
    set(x, y, EMPTY_TILE)
  }
  get(vec) { get(vec.x, vec.y) }
  get(x, y) {
    if (x < 0 || x >= width || y < 0 || y >= height) {
      return Tile.new(-1, { "solid": true })
    }
    return _tiles[_width * y + x]
  }

  set(vec, tile) { setTile(vec.x, vec.y, tile) }
  set(x, y, tile) {
    if (x < 0 || x >= width || y < 0 || y >= height) {
      Fiber.abort("Tile index out of bounds (%(x),%(y))")
    }
    if (!tile is Tile) {
      Fiber.abort("Only instances of Tile can be added to the tilemap")
    }
    _tiles[_width * y + x] = tile
  }

  width { _width }
  height { _height }
}

