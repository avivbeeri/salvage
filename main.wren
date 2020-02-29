import "graphics" for Canvas
import "dome" for Process
import "input" for Keyboard
import "./map" for TileMap, Tile
import "./actor" for Player, Blob
import "./model" for GameModel
import "./view" for GameView

class Game {

  static init() {
    var map = TileMap.init(128, 128)
    map.set(3, 0, Tile.new(2, { "teleport": true }))
    for (x in 0...7) {
      map.set(x, 4, Tile.new(1, { "solid": true, "dark": false }))
    }
    var entities = [
      Player.new(14, 6),
      Blob.new(14, 5),
      Blob.new(5, 3)
    ]
    __view = GameView.init(GameModel.level(map, entities))
  }

  static update() {
    if (Keyboard.isKeyDown("escape")) {
      Process.exit()
    }
    __view.update()
  }

  static draw(dt) {
    __view.draw()
  }

}

