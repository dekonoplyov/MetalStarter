import MetalKit
import simd

class Camera {
  let perspectiveFov = Float.pi / 6
  let aspectRatio: Float
  let nearZ: Float = 0.1
  let farZ: Float = 100
  
  var position: float3 = [0, 0, 3]
  var front: float3 = [0, 0, 1]
  var up: float3 = [0, 1, 0]
  
  var viewMatrix: float4x4 {
    return float4x4(eye: position, center: position + front, up: up)
  }
  
  init(view: MTKView) {
    aspectRatio = Float(view.drawableSize.width / view.drawableSize.height)
  }
  
  
  var projectionMatrix: float4x4 {
    return float4x4(perspectiveProjectionFov: perspectiveFov,
                    aspectRatio: aspectRatio,
                    nearZ: nearZ,
                    farZ: farZ)
  }
  
}
