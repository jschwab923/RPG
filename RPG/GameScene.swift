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

import SpriteKit

class GameScene: SKScene {
  var obstaclesTileMap: SKTileMapNode?
  var bugsprayTileMap: SKTileMapNode?
  var bugsNode = SKNode()
  var firebugCount:Int = 0
  
  var background: SKTileMapNode!
  
  var player = Player()

  var lastTouchLocation : CGPoint?
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    background =
      childNode(withName: "terrain") as! SKTileMapNode
  }

  override func didMove(to view: SKView) {
    addChild(player)
    
    setupCamera()
    setupWorldPhysics()
    
    setupObstaclePhysics()
  }
  
  override func touchesBegan(_ touches: Set<UITouch>,
                             with event: UIEvent?) {
    
    guard let touch = touches.first else { return }
    
    lastTouchLocation = touch.location(in: self)
    player.move(target: touch.location(in: self))
  
  }
  
  override func update(_ currentTime: TimeInterval) {
    if let lastTouch = lastTouchLocation {
      if player.position.distanceTo(lastTouch) < 1 {
        player.stop()
        lastTouchLocation = nil
      }
    }
  }
  
  func setupCamera() {
    guard let camera = camera, let view = view else { return }
    
    let zeroDistance = SKRange(constantValue: 0)
    let playerConstraint = SKConstraint.distance(zeroDistance,
                                                 to: player)
    // 1
    let xInset = min(view.bounds.width/2 * camera.xScale,
                     background.frame.width/2)
    let yInset = min(view.bounds.height/2 * camera.yScale,
                     background.frame.height/2)
    
    // 2
    let constraintRect = background.frame.insetBy(dx: xInset,
                                                  dy: yInset)
    // 3
    let xRange = SKRange(lowerLimit: constraintRect.minX,
                         upperLimit: constraintRect.maxX)
    let yRange = SKRange(lowerLimit: constraintRect.minY,
                         upperLimit: constraintRect.maxY)
    
    let edgeConstraint = SKConstraint.positionX(xRange, y: yRange)
    edgeConstraint.referenceNode = background
    // 4
    camera.constraints = [playerConstraint, edgeConstraint]
  }
  
  func setupWorldPhysics() {
    background.physicsBody =
      SKPhysicsBody(edgeLoopFrom: background.frame)
    background.physicsBody?.categoryBitMask = PhysicsCategory.Edge
    
    physicsWorld.contactDelegate = self

  }
  
  func setupObstaclePhysics() {
    guard let obstaclesTileMap = obstaclesTileMap else { return }
    // 1
    for row in 0..<obstaclesTileMap.numberOfRows {
      for column in 0..<obstaclesTileMap.numberOfColumns {
        // 2
        guard let tile = tile(in: obstaclesTileMap,
                              at: (column, row))
          else { continue }
        guard tile.userData?.object(forKey: "obstacle") != nil
          else { continue }
        // 3
        let node = SKNode()
        node.physicsBody = SKPhysicsBody(rectangleOf: tile.size)
        node.physicsBody?.isDynamic = false
        node.physicsBody?.friction = 0
        node.physicsBody?.categoryBitMask =
          PhysicsCategory.Breakable
        
        node.position = obstaclesTileMap.centerOfTile(
          atColumn: column, row: row)
        obstaclesTileMap.addChild(node)
      }
    }
  }

  func tile(in tileMap: SKTileMapNode,
            at coordinates: TileCoordinates)
    -> SKTileDefinition? {
      return tileMap.tileDefinition(atColumn: coordinates.column,
                                    row: coordinates.row)
  }

  func tileCoordinates(in tileMap: SKTileMapNode,
                       at position: CGPoint) -> TileCoordinates {
    let column = tileMap.tileColumnIndex(fromPosition: position)
    let row = tileMap.tileRowIndex(fromPosition: position)
    return (column, row)
  }

  func tileGroupForName(tileSet: SKTileSet, name: String)
    -> SKTileGroup? {
      let tileGroup = tileSet.tileGroups
        .filter { $0.name == name }.first
      return tileGroup
  }
}

extension GameScene : SKPhysicsContactDelegate {
  func didBegin(_ contact: SKPhysicsContact) {
    let other = contact.bodyA.categoryBitMask
      == PhysicsCategory.Player ?
        contact.bodyB : contact.bodyA
    
    if let physicsBody = player.physicsBody {
      if physicsBody.velocity.length() > 0 {
        player.checkDirection()
      }
    }
  }
}
