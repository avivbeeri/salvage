import "./map" for Tile

class Tiles {
  static floor { Tile.new(".", { "dark": false }) }
  static wall { Tile.new("#", { "solid": true, "dark": false }) }
  static teleport { Tile.new("*", { "teleport": true }) }
  static sludge { Tile.new("~", { "cost": 3, "dark": false }) }
}

