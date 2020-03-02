import "./map" for Tile

class Tiles {
  static empty { Tile.new(-1, { "solid": true, "light": 0 }) }
  static floor { Tile.new(".", { "light": 0 }) }
  static wall { Tile.new("#", { "solid": true, "light": 0, "obscure": true }) }
  static door { Tile.new("+", { "solid": false, "light": 0, "obscure": true }) }
  static lockedDoor { Tile.new("+", { "solid": true, "light": 0, "locked": true, "obscure": true}) }
  static teleport { Tile.new("*", { "teleport": true, "light": 0 }) }
  static sludge { Tile.new("~", { "cost": 3, "light": 0 }) }
}

