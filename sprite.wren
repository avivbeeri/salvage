import "graphics" for Canvas, ImageData, Color
import "./main" for BulletAnimation

class Sprite {
  construct new(imagePath, x, y) {
    _x = x
    _y = y
    _image = ImageData.loadFromFile(imagePath)
  }

  draw() {
    Canvas.draw(_image, _x*16+8, _y*16+8)
  }

  x { _x }
  y { _y }

  x=(value) { _x = value }
  y=(value) { _y = value }

}

class Enemy is Sprite {

  construct new(imagePath, x, y) {
    super(imagePath, x, y)
    _fireState = 0
  }

  draw() {
    super.draw()
    if (_fireState == 1) {
      Canvas.circlefill(x*16+15, y*16+24, 3, Color.yellow)
    }
  }

  fireState=(value) { _fireState = value }

  fire(target) {
    if (_fireState == 0) {
      _fireState = 1
    } else if (_fireState == 1) {
      _fireState = 0
      return BulletAnimation.new(this, target)
    }
  }


}
