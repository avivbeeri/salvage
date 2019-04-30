import "graphics" for Canvas, Color, ImageData
import "input" for Keyboard

var Keys = [
  "left", "right", "up", "down"
]

class Game {

  static init() {
    __previous = {
      "left": false,
      "right": false,
      "up": false,
      "down": false
    }
    var map = [
      0,0,0,2,0,0,0,
      0,0,0,0,0,0,0,
      0,0,0,0,0,0,0,
      0,1,0,1,0,1,0,
      0,0,0,0,0,0,0,
      0,0,0,0,0,0,0,
      0,0,0,0,0,0,0
    ]
    __events = []
    var entities = [
      Player.new(3,2),
      Enemy.new("enemy", 2,1)
    ]

    __model = GameModel.level(map, entities)
    __tiles = ImageData.loadFromFile("res/tilemap.png")
    __playerSprite = ImageData.loadFromFile("res/robot.png")
    __enemySprite = ImageData.loadFromFile("res/enemy.png")
    __ready = true

    var receive = Fn.new {|event|
      __ready = true
    }
    __model.registerListener(Game)

    __currentMap = __model.map.toList
    __sprites = __model.entities.map {|entity|
      if (entity.type == "player") {
        return PlayerSprite.new(entity)
      } else {
        return Sprite.new(entity)

      }
    }
  }

  static draw(dt) {
    Canvas.cls()
    Canvas.print("Energy: %(__model.energy)", 0, 0, Color.white)
    var map = __currentMap
    for (y in 0...7) {
      for (x in 0...7) {
        var index = y * 7 + x
        var tile = map[index]
        __tiles.drawArea(16 * tile, 0, 16, 16, 8 + x * 16, 8 + y * 16)
      }
    }
    Canvas.rect(7, 7, 16*7+2, 16*7+2, Color.blue)

    __sprites.each {|sprite| sprite.draw() }
    __model.entities.each {|entity|
      if (entity.type == "enemy") {
        Canvas.draw(__enemySprite, entity.x*16+8, entity.y*16+8)
        if (entity.state == "charging") {
          Canvas.circlefill(entity.x*16+15, entity.y*16+24, 3, Color.yellow)

        }


      }


    }
  }


  static update() {
    var previous = __previous
    for (key in Keys) {
      var current = Keyboard.isKeyDown(key)
      if (__ready) {
        if (current && !previous[key]) {
          __ready = false
          System.print("action %(key)")
          __model.player.action = MoveAction.new(key)
        }
        previous[key] = current
      }
    }
    __ready = !__model.process()
    if (__ready) {
      // TODO: Initiate animations and state transitions here

      __currentMap = __model.map.toList
      __ready = true
    }

  }
  static receive (event) {
    __events.add(event)
  }
}

class Sprite {
  construct new(entity) {
    _entity = entity
    _x = entity.x * 16 + 8
    _y = entity.y * 16 + 8
  }
  x { _x }
  y { _y }
  x=(v) { _x = v }
  y=(v) { _y = v }
  entity { _entity }
  image {}
  draw() {
    Canvas.draw(image, x, y)
  }
}

class PlayerSprite is Sprite {
  construct new(entity) {
    super(entity)
    _image = ImageData.loadFromFile("res/robot.png")

  }
  image { _image }
}

import "./action" for MoveAction
import "./actor" for Enemy, Player
import "./game" for GameModel
