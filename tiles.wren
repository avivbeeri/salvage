import "./map" for Tile
import "./action" for SelfDestructAction, Action, ExitShipAction

var SelfDestructMenu = [
  [ "initiate", SelfDestructAction.new() ],
  [ "restore", Action.none() ]
]

var AirlockMenu = [
  [ "leave", ExitShipAction.new() ],
  [ "cancel", Action.none() ]
]

class Tiles {
  static empty { Tile.new(-1, { "solid": true }) }
  static floor { Tile.new(".", {}) }
  static wall { Tile.new("#", { "solid": true, "obscure": true, "name": "wall" }) }
  static door { Tile.new("+", { "solid": false, "obscure": true, "hp": 2 }) }
  static lockedDoor { Tile.new("+", { "solid": true, "locked": true, "obscure": true}) }
  static sludge { Tile.new("~", { "cost": 3 }) }

  // Features
  static teleport { Tile.new("*", { "teleport": true }) }
  static console { Tile.new("^", { "solid": true, "menu": SelfDestructMenu }) }
  static consoleLeft { Tile.new("/", { "solid": true }) }
  static consoleRight { Tile.new("\\", { "solid": true }) }
  static airlock { Tile.new("x", { "solid": true, "menu": AirlockMenu  }) }
}

