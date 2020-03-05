import "graphics" for Canvas, Color

class ColorBlindFilter {
  static apply(pal) {
    if (pal != 0) {
      var mat = [
        [[ 1, 0, 0], [ 0, 1, 0], [ 0, 0, 1]],
        [[0.567, 0.433, 0.0]  ,  [0.558, 0.442, 0.0 ] ,  [0.0  , 0.242, 0.758]],
        [[0.817, 0.183, 0.0  ], [ 0.333, 0.667, 0.0  ],  [0.0  , 0.125 ,0.875]], // protanomaly
        [[0.625, 0.375, 0.0  ], [ 0.7  , 0.3  , 0.0  ],  [0.0  , 0.3   ,0.7  ]], // deuteranopia
        [[0.8  , 0.2  , 0.0  ], [ 0.258, 0.742, 0.0  ],  [0.0  , 0.142 ,0.858]], // deuteranomaly
        [[0.95 , 0.05 , 0.0  ], [ 0.0  , 0.433, 0.567],  [0.0  , 0.475 ,0.525]], // tritanopia
        [[0.967, 0.033, 0.0  ], [ 0.0  , 0.733, 0.267],  [0.0  , 0.183 ,0.817]], // tritanomaly
        [[0.299, 0.587, 0.114], [ 0.299, 0.587, 0.114],  [0.299, 0.587 ,0.114]], // achromatopsia
        [[0.618, 0.320, 0.062], [ 0.163, 0.775, 0.062],  [0.163, 0.320 ,0.516]]  // achromatomaly
      ]
      pal = pal % mat.count
      for (y in 0...Canvas.height) {
        for (x in 0...Canvas.width) {
          var c = Canvas.pget(x, y)
          var r = mat[pal][0][0] * c.r + mat[pal][0][1] * c.g + mat[pal][0][2] * c.b
          var g = mat[pal][1][0] * c.r + mat[pal][1][1] * c.g + mat[pal][1][2] * c.b
          var b = mat[pal][2][0] * c.r + mat[pal][2][1] * c.g + mat[pal][2][2] * c.b

          Canvas.pset(x, y, Color.rgb(r, g, b))
        }
      }
    }

  }

}
