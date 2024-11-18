#ifndef UTILS_HLSL
#define UTILS_HLSL

float Remap(float value, float2 inRange, float2 outRange)
{
    float ratio = (value - inRange.x) / (inRange.y - inRange.x);
    float result = ratio * (outRange.y - outRange.x) + outRange.x;
    if(result > outRange.y) return outRange.y;
    else if(result < outRange.x) return outRange.x;
    else return result;
}

float FresnelEffect(float3 normal, float3 viewDir, float power)
{
    return pow((1.0 - saturate(dot(normalize(normal), normalize(viewDir)))), power);
}

#endif