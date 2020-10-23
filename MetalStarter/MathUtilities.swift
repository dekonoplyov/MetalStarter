import simd

typealias float3 = SIMD3<Float>
typealias float4 = SIMD4<Float>

extension float4 {
    var xyz: float3 {
        return float3(x, y, z)
    }
}

extension float4x4 {
  init(scaleBy s: Float) {
      self.init(float4(s, 0, 0, 0),
                float4(0, s, 0, 0),
                float4(0, 0, s, 0),
                float4(0, 0, 0, 1))
  }
  
  init(rotationAbout axis: float3, by angleRadians: Float) {
      let a = normalize(axis)
      let x = a.x, y = a.y, z = a.z
      let c = cosf(angleRadians)
      let s = sinf(angleRadians)
      let t = 1 - c
      self.init(float4( t * x * x + c,     t * x * y + z * s, t * x * z - y * s, 0),
                float4( t * x * y - z * s, t * y * y + c,     t * y * z + x * s, 0),
                float4( t * x * z + y * s, t * y * z - x * s,     t * z * z + c, 0),
                float4(                 0,                 0,                 0, 1))
  }
  
  init(translationBy t: float3) {
      self.init(float4(   1,    0,    0, 0),
                float4(   0,    1,    0, 0),
                float4(   0,    0,    1, 0),
                float4(t[0], t[1], t[2], 1))
  }
  
  init(perspectiveProjectionFov fovRadians: Float, aspectRatio aspect: Float, nearZ: Float, farZ: Float) {
    let yScale = 1 / tan(fovRadians * 0.5)
    let xScale = yScale / aspect
    let zRange = farZ - nearZ
    let zScale = -(farZ + nearZ) / zRange
    let wzScale = -2 * farZ * nearZ / zRange
    
    let xx = xScale
    let yy = yScale
    let zz = zScale
    let zw = Float(-1)
    let wz = wzScale
    
    self.init(float4(xx,  0,  0,  0),
              float4( 0, yy,  0,  0),
              float4( 0,  0, zz, zw),
              float4( 0,  0, wz,  0))
  }
  
  var normalMatrix: float3x3 {
    return upperLeft.transpose.inverse
  }
  
  var upperLeft: float3x3 {
    return float3x3(self[0].xyz, self[1].xyz, self[2].xyz)
  }
  
  static func identity() -> float4x4 {
    return matrix_identity_float4x4
  }
  
  // left-handed LookAt
  init(eye: float3, center: float3, up: float3) {
    let z = normalize(center-eye)
    let x = normalize(cross(up, z))
    let y = cross(z, x)
    
    let X = float4(x.x, y.x, z.x, 0)
    let Y = float4(x.y, y.y, z.y, 0)
    let Z = float4(x.z, y.z, z.z, 0)
    let W = float4(-dot(x, eye), -dot(y, eye), -dot(z, eye), 1)
    
    self.init()
    columns = (X, Y, Z, W)
  }
}
