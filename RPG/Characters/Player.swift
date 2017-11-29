/**
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import Foundation
import SpriteKit

enum PlayerSettings {
  static let playerSpeed: CGFloat = 150.0
}

class Player: SKSpriteNode {
  
  var animations: [SKAction] = []
  var hasBugspray: Bool = false {
    didSet {
      blink(color: .green, on: hasBugspray)
    }
  }

  required init?(coder aDecoder: NSCoder) {
    fatalError("Use init()")
  }
  
  init() {
    let texture = SKTexture(pixelImageNamed: "hero_down_stand")
    super.init(texture: texture, color: .white,
               size: texture.size())
    name = "hero"
    zPosition = 50
    
    physicsBody = SKPhysicsBody(circleOfRadius: size.width/2)
    physicsBody?.restitution = 1.0
    physicsBody?.linearDamping = 0.2
    physicsBody?.allowsRotation = false
    physicsBody?.categoryBitMask = PhysicsCategory.Player
    physicsBody?.contactTestBitMask = PhysicsCategory.All

    createAnimations(character: "hero")
  }
  
  func move(target: CGPoint) {
    guard let physicsBody = physicsBody else { return }
    
    let newVelocity = (target - position).normalized()
      * PlayerSettings.playerSpeed
    physicsBody.velocity = CGVector(point: newVelocity)
    
    checkDirection()
  }
  
  func stop() {
    self.physicsBody?.velocity = CGVector.zero;
    self.removeAllActions()
  }
  
  func checkDirection() {
    guard let physicsBody = physicsBody else { return }
    let direction =
      animationDirection(for: physicsBody.velocity)

    run(animations[direction.rawValue], withKey: "animation")
  }

  func blink(color: SKColor, on: Bool) {
    let blinkOff = SKAction.colorize(withColorBlendFactor: 0.0,
                                     duration: 0.2)
    if on {
      let blinkOn = SKAction.colorize(with: color,
                                      colorBlendFactor: 1.0,
                                      duration: 0.2)
      let blink = SKAction.repeatForever(SKAction.sequence(
        [blinkOn, blinkOff]))
      xScale = xScale < 0 ? -1.5 : 1.5
      yScale = 1.5
      run(blink, withKey: "blink")
    } else {
      xScale = xScale < 0 ? -1.0 : 1.0
      yScale = 1.0
      removeAction(forKey: "blink")
      run(blinkOff)
    }
  }

}

extension Player : Animatable {}
