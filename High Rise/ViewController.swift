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
  
  // MARK: - Overrides
  
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
    
    // Get blocks moving
    scnView.isPlaying = true
    scnView.delegate = self
  }
  
  override var prefersStatusBarHidden: Bool {
    return true
  }
  
}

// Make view controller the scene renderer delegate

extension ViewController: SCNSceneRendererDelegate {
  func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    
    // Look for the block created earlier (by name)
    if let currentNode = scnScene.rootNode.childNode(withName: "Block\(height)", recursively: false) {
      
      // Blocks on even layers move on the z-axis
      if height % 2 == 0 {
        
        // Direction detection & change (z-axis)
        if currentNode.position.z >= 1.25 {
          direction = false
        } else if currentNode.position.z <= -1.25 {
          direction = true
        }
        
        // Move box on z-axis
        switch direction {
        case true:
          currentNode.position.z += 0.03
        case false:
          currentNode.position.z -= 0.03
        }
        
        // Blocks on the odd layers move on the x-axis
      } else {
        
        // Direction detection & change (x-axis)
        if currentNode.position.x >= 1.25 {
          direction = false
        } else if currentNode.position.x <= -1.25 {
          direction = true
        }
        
        // Move on x-axis
        switch direction {
        case true:
          currentNode.position.x += 0.03
        case false:
          currentNode.position.x -= 0.03
        }
      }
    }
    
  }
}
