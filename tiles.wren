import "./map" for Tile

class Tiles {
  static empty { Tile.new(-1, { "solid": true }) }
  static floor { Tile.new(".", {}) }
  static wall { Tile.new("#", { "solid": true, "obscure": true }) }
  static door { Tile.new("+", { "solid": false, "obscure": true }) }
  static lockedDoor { Tile.new("+", { "solid": true, "locked": true, "obscure": true}) }
  static sludge { Tile.new("~", { "cost": 3 }) }

  // Features
  static teleport { Tile.new("*", { "teleport": true }) }
  static console { Tile.new("$", { "solid": true }) }
}

