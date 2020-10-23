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
    mtkView.colorPixelFormat = .bgra8Unorm_srgb
    mtkView.depthStencilPixelFormat = .depth32Float
    
    renderer = Renderer(view: mtkView, device: device)
    mtkView.delegate = renderer
    addGestureRecognizers(to: mtkView)
    NSEvent.addLocalMonitorForEvents(matching: .keyDown) {
      if self.myKeyDown(with: $0) {
          return nil
       } else {
          return $0
       }
    }
  }

  override var representedObject: Any? {
    didSet {
    // Update the view, if already loaded.
    }
  }
}

