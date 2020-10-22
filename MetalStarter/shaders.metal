#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float3 position  [[attribute(0)]];
    float3 normal    [[attribute(1)]];
    float2 texCoords [[attribute(2)]];
};
 
struct VertexOut {
    float4 position [[position]];
    float4 eyeNormal;
    float4 eyePosition;
    float2 texCoords;
};

struct Uniforms {
    float4x4 modelViewMatrix;
    float4x4 projectionMatrix;
};

vertex VertexOut vertex_main(VertexIn vIn [[stage_in]],
                             constant Uniforms& uniforms [[buffer(1)]]) {
  VertexOut vOut;
  vOut.position = uniforms.projectionMatrix * uniforms.modelViewMatrix * float4(vIn.position, 1);
  vOut.eyeNormal = uniforms.modelViewMatrix * float4(vIn.normal, 0);
  vOut.eyePosition = uniforms.modelViewMatrix * float4(vIn.position, 1);
  vOut.texCoords = vIn.texCoords;
  return vOut;
}

fragment float4 fragment_main(VertexOut fragmentIn [[stage_in]]) {
    return float4(1, 0, 0, 1);
}
