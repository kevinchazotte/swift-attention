//
//  Shaders.metal
//  Swift-Attention
//
//  Created by ec2-user on 31/07/2025.
//

#include <metal_stdlib>
using namespace metal;

[[stitchable]] half4 pixellate(float2 pos, sampler s, texture2d<half> src, float scale) {
    float2 newPos = floor(pos / scale) * scale;
    return src.sample(s, newPos);
}
