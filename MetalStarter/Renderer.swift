
import Foundation
import MetalKit
import simd

struct VertexUniforms {
  var viewProjectionMatrix: float4x4
  var modelMatrix: float4x4
  var normalMatrix: float3x3
}

struct FragmentUniforms {
  var cameraWorldPosition = float3(0, 0, 0)
  var ambientLightColor = float3(0, 0, 0)
  var specularColor = float3(1, 1, 1)
  var specularPower = Float(1)
  var light0 = Light()
  var light1 = Light()
  var light2 = Light()
  var tiling: UInt32 = 1
}

class Renderer: NSObject, MTKViewDelegate {
  let device: MTLDevice
  let commandQueue: MTLCommandQueue
  var renderPipeline: MTLRenderPipelineState
  let depthStencilState: MTLDepthStencilState
  let samplerState: MTLSamplerState
  let vertexDescriptor: MDLVertexDescriptor
  let scene: Scene
  
  var time: Float = 0
  let camera: Camera
  
  static let fishCount = 12

  init(view: MTKView, device: MTLDevice) {
    self.device = device
    commandQueue = device.makeCommandQueue()!
    vertexDescriptor = Renderer.buildVertexDescriptor()
    renderPipeline = Renderer.buildPipeline(device: device, view: view, vertexDescriptor: vertexDescriptor)
    samplerState = Renderer.buildSamplerState(device: device)
    depthStencilState = Renderer.buildDepthStencilState(device: device)
    scene = Renderer.buildScene(device: device, vertexDescriptor: vertexDescriptor)
  
    camera = Camera(view: view)
    
    super.init()
  }
  
  static func buildScene(device: MTLDevice, vertexDescriptor: MDLVertexDescriptor) -> Scene {
    let bufferAllocator = MTKMeshBufferAllocator(device: device)
    let textureLoader = MTKTextureLoader(device: device)
    let options: [MTKTextureLoader.Option : Any] = [.generateMipmaps : true, .SRGB : true]
    
    let scene = Scene()
    
    scene.ambientLightColor = float3(0.1, 0.1, 0.1)
    let light0 = Light(worldPosition: float3( 5,  5, 0), color: float3(1, 0, 0))
    let light1 = Light(worldPosition: float3(-5,  5, 0), color: float3(0, 1, 0))
    let light2 = Light(worldPosition: float3( 0, -5, 0), color: float3(0, 0, 1))
    scene.lights = [ light0, light1, light2 ]

    let ground = Node(name: "Ground")
    let groundMaterial = Material()
    let groundBaseColorTexture = try! textureLoader.newTexture(name: "ground",
                                                              scaleFactor: 1.0,
                                                              bundle: nil,
                                                              options: options)
    groundMaterial.baseColorTexture = groundBaseColorTexture
    groundMaterial.specularPower = 40
    groundMaterial.specularColor = float3(0.8, 0.8, 0.8)
    ground.material = groundMaterial
    ground.tiling = 16
    
    let groundURL = Bundle.main.url(forResource: "plane", withExtension: "obj")!
    let groundAsset = MDLAsset(url: groundURL, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
    ground.mesh = try! MTKMesh.newMeshes(asset: groundAsset, device: device).metalKitMeshes.first!

    scene.rootNode.children.append(ground)
    
    let bob = Node(name: "Bob")
    let bobMaterial = Material()
    let bobBaseColorTexture = try? textureLoader.newTexture(name: "bob_baseColor",
                                                            scaleFactor: 1.0,
                                                            bundle: nil,
                                                            options: options)
    bobMaterial.baseColorTexture = bobBaseColorTexture
    bobMaterial.specularPower = 100
    bobMaterial.specularColor = float3(0.8, 0.8, 0.8)
    bob.material = bobMaterial

    let bobURL = Bundle.main.url(forResource: "bob", withExtension: "obj")!
    let bobAsset = MDLAsset(url: bobURL, vertexDescriptor: vertexDescriptor, bufferAllocator: bufferAllocator)
    bob.mesh = try! MTKMesh.newMeshes(asset: bobAsset, device: device).metalKitMeshes.first!

    scene.rootNode.children.append(bob)
    
    return scene
  }
  
  static func buildVertexDescriptor() -> MDLVertexDescriptor {
    let vertexDescriptor = MDLVertexDescriptor()
    vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition,
                                                        format: .float3,
                                                        offset: 0,
                                                        bufferIndex: 0)
    vertexDescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal,
                                                        format: .float3,
                                                        offset: MemoryLayout<Float>.size * 3,
                                                        bufferIndex: 0)
    vertexDescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate,
                                                        format: .float2,
                                                        offset: MemoryLayout<Float>.size * 6,
                                                        bufferIndex: 0)
    vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: MemoryLayout<Float>.size * 8)
    return vertexDescriptor
  }
  
  static func buildSamplerState(device: MTLDevice) -> MTLSamplerState {
    let samplerDescriptor = MTLSamplerDescriptor()
    samplerDescriptor.normalizedCoordinates = true
    samplerDescriptor.minFilter = .linear
    samplerDescriptor.magFilter = .linear
    samplerDescriptor.mipFilter = .linear
    samplerDescriptor.sAddressMode = .repeat
    samplerDescriptor.tAddressMode = .repeat
    return device.makeSamplerState(descriptor: samplerDescriptor)!
  }
  
  static func buildDepthStencilState(device: MTLDevice) -> MTLDepthStencilState {
    let depthStencilDescriptor = MTLDepthStencilDescriptor()
    depthStencilDescriptor.depthCompareFunction = .less
    depthStencilDescriptor.isDepthWriteEnabled = true
    return device.makeDepthStencilState(descriptor: depthStencilDescriptor)!
  }
  
  static func buildPipeline(device: MTLDevice, view: MTKView, vertexDescriptor: MDLVertexDescriptor) -> MTLRenderPipelineState {
    guard let library = device.makeDefaultLibrary() else {
      fatalError("Could not load default library from main bundle")
    }
    
    let vertexFunction = library.makeFunction(name: "vertex_main")
    let fragmentFunction = library.makeFunction(name: "fragment_main")
    
    let pipelineDescriptor = MTLRenderPipelineDescriptor()
    pipelineDescriptor.vertexFunction = vertexFunction
    pipelineDescriptor.fragmentFunction = fragmentFunction
    
    pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
    pipelineDescriptor.depthAttachmentPixelFormat = view.depthStencilPixelFormat

    let mtlVertexDescriptor = MTKMetalVertexDescriptorFromModelIO(vertexDescriptor)
    pipelineDescriptor.vertexDescriptor = mtlVertexDescriptor
    
    do {
        return try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    } catch {
        fatalError("Could not create render pipeline state object: \(error)")
    }
  }
  
  
  func update(_ view: MTKView) {
    time += 1 / Float(view.preferredFramesPerSecond)
    
    let angle = time
    scene.rootNode.modelMatrix = float4x4(rotationAbout: float3(0, 1, 0), by: angle / 2)
    
    if let bob = scene.nodeNamed("Bob") {
      bob.modelMatrix = float4x4(translationBy: float3(0, 0.1 + 0.015 * sin(time * 5), 0))
    }
    
    if let ground = scene.nodeNamed("Ground") {
      ground.modelMatrix = float4x4(scaleBy: 16)
    }
  }
  
  func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    // TODO
    //self.camera.aspectRatio = Float(view.bounds.width)/Float(view.bounds.height)
  }
  
  func draw(in view: MTKView) {
    update(view)
    
    let commandBuffer = commandQueue.makeCommandBuffer()!
    if let renderPassDescriptor = view.currentRenderPassDescriptor,
       let drawable = view.currentDrawable {
      renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.63, 0.81, 1.0, 1.0)
      let commandEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
      commandEncoder.setFrontFacing(.counterClockwise)
      commandEncoder.setCullMode(.back)
      commandEncoder.setDepthStencilState(depthStencilState)
      commandEncoder.setRenderPipelineState(renderPipeline)
      commandEncoder.setFragmentSamplerState(samplerState, index: 0)
      drawNodeRecursive(scene.rootNode, parentTransform: matrix_identity_float4x4, commandEncoder: commandEncoder)
      commandEncoder.endEncoding()
      commandBuffer.present(drawable)
      commandBuffer.commit()
    }
  }
  
  func drawNodeRecursive(_ node: Node, parentTransform: float4x4, commandEncoder: MTLRenderCommandEncoder) {
    let modelMatrix = parentTransform * node.modelMatrix
    
    if let mesh = node.mesh,
       let baseColorTexture = node.material.baseColorTexture {
      
//      camera.distance = -20 * abs(sin(time / 20))
//      camera.rotation = float3(0, sin(time), 0)
      let viewProjectionMatrix = camera.projectionMatrix * camera.viewMatrix
      var vertexUniforms = VertexUniforms(viewProjectionMatrix: viewProjectionMatrix,
                                          modelMatrix: modelMatrix,
                                          normalMatrix: modelMatrix.normalMatrix)
      commandEncoder.setVertexBytes(&vertexUniforms, length: MemoryLayout<VertexUniforms>.stride, index: 1)
      
      var fragmentUniforms = FragmentUniforms(cameraWorldPosition: camera.position,
                                              ambientLightColor: scene.ambientLightColor,
                                              specularColor: node.material.specularColor,
                                              specularPower: node.material.specularPower,
                                              light0: scene.lights[0],
                                              light1: scene.lights[1],
                                              light2: scene.lights[2],
                                              tiling: node.tiling)
      commandEncoder.setFragmentBytes(&fragmentUniforms, length: MemoryLayout<FragmentUniforms>.stride, index: 0)

      commandEncoder.setFragmentTexture(baseColorTexture, index: 0)

      let vertexBuffer = mesh.vertexBuffers.first!
      commandEncoder.setVertexBuffer(vertexBuffer.buffer, offset: vertexBuffer.offset, index: 0)
      
      for submesh in mesh.submeshes {
        let indexBuffer = submesh.indexBuffer
        commandEncoder.drawIndexedPrimitives(type: submesh.primitiveType,
                                             indexCount: submesh.indexCount,
                                             indexType: submesh.indexType,
                                             indexBuffer: indexBuffer.buffer,
                                             indexBufferOffset: indexBuffer.offset)
      }
    }
    
    for child in node.children {
      drawNodeRecursive(child, parentTransform: modelMatrix, commandEncoder: commandEncoder)
    }
  }
  
  
}
