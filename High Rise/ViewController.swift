/**
 * Copyright (c) 2017 Razeware LLC
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

import UIKit
import SceneKit
import SpriteKit

class ViewController: UIViewController {
  
  // MARK: - Properties
  
  // Block variables
  var direction = true    // Blocks position increasing or decreasing
  var height = 0          // Tracks position
  
  // Layer variables
  var previousSize = SCNVector3(1, 0.2, 1)
  var previousPosition = SCNVector3(0, 0.1, 0)
  var currentSize = SCNVector3(1, 0.2, 1)
  var currentPosition = SCNVector3Zero
  
  // For calculating size of new layer
  var offset = SCNVector3Zero
  var absoluteOffset = SCNVector3Zero
  var newSize = SCNVector3Zero
  
  // For tracking number of player perfect matches
  var perfectMatches = 0
  
  // Scene variable
  var scnScene: SCNScene!
  
  // MARK: - Outlets
  
  @IBOutlet weak var scnView: SCNView!
  @IBOutlet weak var scoreLabel: UILabel!
  
  // MARKL - Overrides
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    scnScene = SCNScene(named: "HighRise.scnassets/Scenes/GameScene.scn")
    scnView.scene = scnScene
    
    // Create a box
    let blockNode = SCNNode(geometry: SCNBox(width: 1, height: 0.2, length: 1, chamferRadius: 0))
    blockNode.position.z = -1.25
    blockNode.position.y = 0.1
    blockNode.name = "Block\(height)"
    
    // Set block's color based on height & add it to the scene
    blockNode.geometry?.firstMaterial?.diffuse.contents =
      UIColor(colorLiteralRed: 0.01 * Float(height), green: 0, blue: 1, alpha: 1)
    
    scnScene.rootNode.addChildNode(blockNode)
  }
  
  override var prefersStatusBarHidden: Bool {
    return true
  }
  
}
