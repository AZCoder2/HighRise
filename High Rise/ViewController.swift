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
  
  // For sound
  var sounds = [String: SCNAudioSource]()
  
  // MARK: - Outlets
  
  @IBOutlet weak var scnView: SCNView!
  @IBOutlet weak var scoreLabel: UILabel!
  @IBOutlet weak var playButton: UIButton!
  
  // MARK: - Overrides
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    scnScene = SCNScene(named: "HighRise.scnassets/Scenes/GameScene.scn")
    scnView.scene = scnScene
    
    // Load sounds
    loadSound(name: "GameOver", path: "HighRise.scnassets/Audio/GameOver.wav")
    loadSound(name: "PerfectFit", path: "HighRise.scnassets/Audio/PerfectFit.wav")
    loadSound(name: "SliceBlock", path: "HighRise.scnassets/Audio/SliceBlock.wav")
    
    //         Create a box
    //        let blockNode = SCNNode(geometry: SCNBox(width: 1, height: 0.2, length: 1, chamferRadius: 0))
    //        blockNode.position.z = -1.25
    //        blockNode.position.y = 0.1
    //        blockNode.name = "Block\(height)"
    //
    //        // Set block's color based on height & add it to the scene
    //        blockNode.geometry?.firstMaterial?.diffuse.contents =
    //            UIColor(colorLiteralRed: 0.01 * Float(height), green: 0, blue: 1, alpha: 1)
    //
    //        scnScene.rootNode.addChildNode(blockNode)
    
    // Get blocks moving
    scnView.isPlaying = true
    scnView.delegate = self
  }
  
  // Load sound
  func loadSound(name: String, path: String) {
    if let sound = SCNAudioSource(fileNamed: path) {
      sound.isPositional = false
      sound.volume = 1
      sound.load()
      sounds[name] = sound
    } else {
      print("Sound did not load")
    }
  }
  
  // Play sound
  func playSound(sound: String, node: SCNNode) {
    node.runAction(SCNAction.playAudio(sounds[sound]!, waitForCompletion: false))
  }
  
  override var prefersStatusBarHidden: Bool {
    return true
  }
  
  // MARK: - IB Actions
  
  @IBAction func handleTap(_ sender: Any) {
    
    if let currentBoxNode = scnScene.rootNode.childNode(
      withName: "Block\(height)", recursively: false) {
      
      // Calculate current size from current location
      currentPosition = currentBoxNode.presentation.position
      let boundsMin = currentBoxNode.boundingBox.min
      let boundsMax = currentBoxNode.boundingBox.max
      currentSize = boundsMax - boundsMin
      
      // Calculate new size
      offset = previousPosition - currentPosition
      absoluteOffset = offset.absoluteValue()
      newSize = currentSize - absoluteOffset
      
      // Give box a static physics body
      currentBoxNode.geometry = SCNBox(width: CGFloat(newSize.x), height: 0.2,
                                       length: CGFloat(newSize.z), chamferRadius: 0)
      
      currentBoxNode.position = SCNVector3Make(currentPosition.x + (offset.x/2),
                                               currentPosition.y, currentPosition.z + (offset.z/2))
      
      currentBoxNode.physicsBody = SCNPhysicsBody(type: .static,
                                                  shape: SCNPhysicsShape(geometry: currentBoxNode.geometry!, options: nil))
      
      addNewBlock(currentBoxNode)
      playSound(sound: "SliceBlock", node: currentBoxNode)
      
      addBrokenBlock(currentBoxNode)
      
      // If tower height is greater than or equal to 5, move camera up
      if height >= 5 {
        let moveUpAction = SCNAction.move(by: SCNVector3Make(0.0, 0.2, 0.0), duration: 0.2)
        let mainCamera = scnScene.rootNode.childNode(withName: "Main Camera", recursively: false)!
        
        mainCamera.runAction(moveUpAction)
      }
      
      // Update score label
      scoreLabel.text = "\(height+1)"
      
      // Adjust sizes
      previousSize = SCNVector3Make(newSize.x, 0.2, newSize.z)
      previousPosition = currentBoxNode.position
      height += 1
      
      // Missed?
      if height % 2 == 0 && newSize.z <= 0 {
        height += 1
        currentBoxNode.physicsBody = SCNPhysicsBody(type: .dynamic,
                                                    shape: SCNPhysicsShape(geometry: currentBoxNode.geometry!, options: nil))
        playSound(sound: "GameOver", node: currentBoxNode)
        gameOver()
        return
        
      } else if height % 2 != 0 && newSize.x <= 0 {
        height += 1
        currentBoxNode.physicsBody = SCNPhysicsBody(type: .dynamic,
                                                    shape: SCNPhysicsShape(geometry: currentBoxNode.geometry!, options: nil))
        
        playSound(sound: "GameOver", node: currentBoxNode)
        gameOver()
        return
      }
      
      // Perfect match processing
      checkPerfectMatch(currentBoxNode)
    }
  }
  
  @IBAction func playGame(_ sender: UIButton) {
    
    playButton.isHidden = true
    
    let gameScene = SCNScene(named: "HighRise.scnassets/Scenes/GameScene.scn")!
    let transition = SKTransition.fade(withDuration: 1.0)
    scnScene = gameScene
    let mainCamera = scnScene.rootNode.childNode(withName: "Main Camera", recursively: false)!
    scnView.present(scnScene, with: transition, incomingPointOfView: mainCamera, completionHandler: nil)
    
    height = 0
    scoreLabel.text = "\(height)"
    
    direction = true
    perfectMatches = 0
    
    previousSize = SCNVector3(1, 0.2, 1)
    previousPosition = SCNVector3(0, 0.1, 0)
    
    currentSize = SCNVector3(1, 0.2, 1)
    currentPosition = SCNVector3Zero
    
    let boxNode = SCNNode(geometry: SCNBox(width: 1, height: 0.2, length: 1, chamferRadius: 0))
    boxNode.position.z = -1.25
    boxNode.position.y = 0.1
    boxNode.name = "Block\(height)"
    boxNode.geometry?.firstMaterial?.diffuse.contents = UIColor(colorLiteralRed: 0.01 * Float(height),
                                                                green: 0, blue: 1, alpha: 1)
    scnScene.rootNode.addChildNode(boxNode)
  }
  
  
  
  // Method to next block in tower
  func addNewBlock(_ currentBoxNode: SCNNode) {
    
    let newBoxNode = SCNNode(geometry: currentBoxNode.geometry)
    
    newBoxNode.position = SCNVector3Make(currentBoxNode.position.x,
                                         currentPosition.y + 0.2, currentBoxNode.position.z)
    newBoxNode.name = "Block\(height+1)"
    newBoxNode.geometry?.firstMaterial?.diffuse.contents = UIColor(
      colorLiteralRed: 0.01 * Float(height), green: 0, blue: 1, alpha: 1)
    
    if height % 2 == 0 {
      newBoxNode.position.x = -1.25
    } else {
      newBoxNode.position.z = -1.25
    }
    
    scnScene.rootNode.addChildNode(newBoxNode)
  }
  
  // Make chopped block fall down
  func addBrokenBlock(_ currentBoxNode: SCNNode) {
    
    let brokenBoxNode = SCNNode()
    brokenBoxNode.name = "Broken \(height)"
    
    if height % 2 == 0 && absoluteOffset.z > 0 {    // z-axis
      
      // Get geometry of broken block
      brokenBoxNode.geometry = SCNBox(width: CGFloat(currentSize.x),
                                      height: 0.2, length: CGFloat(absoluteOffset.z), chamferRadius: 0)
      
      // Change position of broken block
      if offset.z > 0 {
        brokenBoxNode.position.z = currentBoxNode.position.z -
          (offset.z/2) - ((currentSize - offset).z/2)
      } else {
        brokenBoxNode.position.z = currentBoxNode.position.z -
          (offset.z/2) + ((currentSize + offset).z/2)
      }
      brokenBoxNode.position.x = currentBoxNode.position.x
      brokenBoxNode.position.y = currentPosition.y
      
      // Add physics to broken body so it will fall
      brokenBoxNode.physicsBody = SCNPhysicsBody(type: .dynamic,
                                                 shape: SCNPhysicsShape(geometry: brokenBoxNode.geometry!, options: nil))
      
      brokenBoxNode.geometry?.firstMaterial?.diffuse.contents = UIColor(colorLiteralRed: 0.01 *
        Float(height), green: 0, blue: 1, alpha: 1)
      
      scnScene.rootNode.addChildNode(brokenBoxNode)
      
      // Do the same for the x-axis
    } else if height % 2 != 0 && absoluteOffset.x > 0 {
      brokenBoxNode.geometry = SCNBox(width: CGFloat(absoluteOffset.x), height: 0.2,
                                      length: CGFloat(currentSize.z), chamferRadius: 0)
      
      if offset.x > 0 {
        brokenBoxNode.position.x = currentBoxNode.position.x - (offset.x/2) -
          ((currentSize - offset).x/2)
      } else {
        brokenBoxNode.position.x = currentBoxNode.position.x - (offset.x/2) +
          ((currentSize + offset).x/2)
      }
      brokenBoxNode.position.y = currentPosition.y
      brokenBoxNode.position.z = currentBoxNode.position.z
      
      brokenBoxNode.physicsBody = SCNPhysicsBody(type: .dynamic,
                                                 shape: SCNPhysicsShape(geometry: brokenBoxNode.geometry!, options: nil))
      brokenBoxNode.geometry?.firstMaterial?.diffuse.contents = UIColor(
        colorLiteralRed: 0.01 * Float(height), green: 0, blue: 1, alpha: 1)
      scnScene.rootNode.addChildNode(brokenBoxNode)
    }
  }
  
  func checkPerfectMatch(_ currentBoxNode: SCNNode) {
    
    if height % 2 == 0 && absoluteOffset.z <= 0.03 {
      currentBoxNode.position.z = previousPosition.z
      currentPosition.z = previousPosition.z
      perfectMatches += 1
      if perfectMatches >= 7 && currentSize.z < 1 {
        newSize.z += 0.05
      }
      
      offset = previousPosition - currentPosition
      absoluteOffset = offset.absoluteValue()
      newSize = currentSize - absoluteOffset
      
      playSound(sound: "PerfectFit", node: currentBoxNode)
      
    } else if height % 2 != 0 && absoluteOffset.x <= 0.03 {
      currentBoxNode.position.x = previousPosition.x
      currentPosition.x = previousPosition.x
      perfectMatches += 1
      if perfectMatches >= 7 && currentSize.x < 1 {
        newSize.x += 0.05
      }
      
      offset = previousPosition - currentPosition
      absoluteOffset = offset.absoluteValue()
      newSize = currentSize - absoluteOffset
      
      playSound(sound: "PerfectFit", node: currentBoxNode)
      
    } else {
      perfectMatches = 0
    }
  }
  
  func gameOver() {
    let mainCamera = scnScene.rootNode.childNode(
      withName: "Main Camera", recursively: false)!
    
    let fullAction = SCNAction.customAction(duration: 0.3) { _,_ in
      let moveAction = SCNAction.move(to: SCNVector3Make(mainCamera.position.x,
                                                         mainCamera.position.y * (3/4), mainCamera.position.z), duration: 0.3)
      mainCamera.runAction(moveAction)
      if self.height <= 15 {
        mainCamera.camera?.orthographicScale = 1
      } else {
        mainCamera.camera?.orthographicScale = Double(Float(self.height/2) /
          mainCamera.position.y)
      }
    }
    
    mainCamera.runAction(fullAction)
    playButton.isHidden = false
  }
}


// Make view controller the scene renderer delegate

extension ViewController: SCNSceneRendererDelegate {
  func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
    
    // Process broken blocks so they disappear after they fall out of view
    for node in scnScene.rootNode.childNodes {
      if node.presentation.position.y <= -20 {
        node.removeFromParentNode()
      }
    }
    
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
