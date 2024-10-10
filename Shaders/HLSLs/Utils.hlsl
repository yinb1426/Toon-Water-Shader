#ifndef UTILS_HLSL
#define UTILS_HLSL

float Remap(float value, float2 inRange, float2 outRange)
{
    float ratio = (value - inRange.x) / (inRange.y - inRange.x);
    return ratio * (outRange.y - outRange.x) + outRange.x;
}

float FresnelEffect(float3 normal, float3 viewDir, float power)
{
    return pow((1.0 - saturate(dot(normalize(normal), normalize(viewDir)))), power);
}

#endif