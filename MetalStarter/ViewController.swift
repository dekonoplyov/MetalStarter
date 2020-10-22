import MetalKit
import Metal

import Cocoa

class ViewController: NSViewController {
  var mtkView: MTKView!
  var renderer: Renderer?
  
  override func viewDidLoad() {
    super.viewDidLoad()

    guard let mtkView = view as? MTKView else {
      fatalError("metal view not set up in storyboard")
    }
    
    guard let device = MTLCreateSystemDefaultDevice() else {
      fatalError("GPU not available")
    }
    mtkView.device = device
    mtkView.colorPixelFormat = .bgra8Unorm
    
    renderer = Renderer(view: mtkView, device: device)
    mtkView.delegate = renderer
  }

  override var representedObject: Any? {
    didSet {
    // Update the view, if already loaded.
    }
  }
}

