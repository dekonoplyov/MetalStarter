import MetalKit
import Metal

import Cocoa

class ViewController: NSViewController {
  var mtkView: MTKView!
  
  override func viewDidLoad() {
    super.viewDidLoad()

    guard let metalView = view as? MTKView else {
     fatalError("metal view not set up in storyboard")
   }
  }

  override var representedObject: Any? {
    didSet {
    // Update the view, if already loaded.
    }
  }
}

