import Cocoa
import Carbon.HIToolbox

extension ViewController {
  
  func addGestureRecognizers(to view: NSView) {
    let pan = NSPanGestureRecognizer(target: self, action: #selector(handlePan(gesture:)))
    view.addGestureRecognizer(pan)
  }
  
  @objc func handlePan(gesture: NSPanGestureRecognizer) {
    NSLog("23423\n")
  }
  
  override func scrollWheel(with event: NSEvent) {
    let cameraSpeed: Float = 0.05
    renderer?.camera.position += cameraSpeed * Float(event.deltaY) * float3(0, 0, 1)
  }
  
  
  override func mouseMoved(with event: NSEvent) {
    NSLog("X: %d\n", event.absoluteX)
    NSLog("Y: %d\n", event.absoluteY)
  }
  
  func myKeyDown(with event: NSEvent) -> Bool {
    let cameraSpeed: Float = 0.05
    if (event.keyCode == kVK_ANSI_W) {
      renderer?.camera.position -= cameraSpeed * float3(0, 0, 1)
    } else if (event.keyCode == kVK_ANSI_S) {
      renderer?.camera.position += cameraSpeed * float3(0, 0, 1)
    } else if (event.keyCode == kVK_ANSI_A) {
      renderer?.camera.position -= cameraSpeed * float3(1, 0, 0)
    } else if (event.keyCode == kVK_ANSI_D) {
      renderer?.camera.position += cameraSpeed * float3(1, 0, 0)
    } else {
      return false
    }
    
    return true
    
  }
}
