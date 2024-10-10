#ifndef REFRACTED_UV_HLSL
#define REFRACTED_UV_HLSL

#include "UnityNoise.hlsl"
#include "Utils.hlsl"

float2 RefractedUV(float2 uv, float2 screenPos, float time, float scale, float speed, float strength)
{
    uv = uv * rcp(scale) + speed * time;
    float noise = 0.0;
    GradientNoise(uv, 10, noise);
    noise = Remap(noise, float2(0, 1), float2(-1, 1)) * strength;
    float2 outUV = screenPos + noise;
    return outUV;
}

#endif