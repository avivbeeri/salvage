import "graphics" for Canvas
import "dome" for Window, Process
import "input" for Keyboard
import "./map" for TileMap, Tile
import "./actor" for Player
import "./model" for GameModel
import "./view" for GameView

class Game {

  static init() {
    var scale = 3
    Canvas.resize(128, 128)
    Window.resize(scale * 128, scale * 128)
    var map = TileMap.init(16, 14)
    map.set(3, 0, Tile.new(2, { "teleport": true }))
    var entities = [
      Player.new(1, 6)
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

