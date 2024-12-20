Shader "Unlit/ToonWaterShader"
{
    Properties
    {
        [Header(General)]
        [MainTexture] _BaseMap ("Base Map", 2D) = "white" {}
        [Toggle(_USE_ALPHA)] _UseAlpha("Use Alpha", Float) = 1.0
        [Toggle(_USE_BLINN_PHONG_SPECULAR)] _UseBlinnPhongSpecular("Use Blinn Phong Specular", Float) = 1.0
        _SpecularColor ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _SpecularPower ("Specular Power", Float) = 8.0

        [Header(Controllers)]
        _WaterDepthController ("Water Depth Controller", Float) = 1.0
        _DistanceController ("Far Water Color Distance Controller", Float) = 0.1
        _WaterFadeController ("Water Fade Controller", Range(0, 1)) = 0.7

        [Header(Water Color)]
        [HDR] _ShallowColor ("Shallow Color", Color) = (1.0, 1.0, 1.0, 1.0)
        [HDR] _DeepColor ("Deep Color", Color) = (1.0, 1.0, 1.0, 1.0)
        [HDR] _FarColor ("Far Color", Color) = (1.0, 1.0, 1.0, 1.0)

        [Header(Water Color Cosine Gradient)]
        [Toggle(_USE_COSINE_GRADIENT)] _UseCosineGradient("Use Cosine Gradient", Float) = 1.0
        _WaterColorController ("Water Color Controller", Float) = 1.5

        [Header(Normal Map)]
        [Toggle(_USE_NORMAL_MAP)] _UseNormalMap ("Use Normal Map", Float) = 1.0
        _FirstNormalMap("NormalMap 1", 2D) = "white" {}
        _FirstNormalSpeedInverse("NormalSpeedInverse 1", Float) = 20
        _SecondNormalMap("NormalMap 2", 2D) = "white" {}
        _SecondNormalSpeedInverse("NormalSpeedInverse 2", Float) = -15

        [Header(Sine Wave)]
        [Toggle(_USE_SINE_WAVE)] _UseSineWave ("Use Sine Wave", Float) = 1.0
        _SinePeriod ("Sine Period", Float) = 20
        _SineSpeed ("Sine Speed", Float) = 1
        _SineAmplitude ("Sine Amplitude", Float) = 0.7 
        _SineMaskThreshold ("Sine Mask Threshold", Range(0, 1)) = 0.65
        _SineStrength ("Sine Strength", Float) = 1.0

        [Header(Sine Wave Noise Controller)]
        _NoiseSpeed ("Noise Speed", Float) = 0.05
        _NoiseSize ("Noise Size", Float) = 50
        _NoiseMinEdge ("Noise Min Edge", Float) = 1.25
        _NoiseMaxEdge ("Noise Max Edge", Float) = 1.8

        [Header(Refraction)]
        [Toggle(_USE_REFRACTION)] _UseRefraction ("Use Refraction", Float) = 1.0
        _RefractedScale ("Refracted Scale", Range(0.0, 0.1)) = 0.05
        _RefractedSpeed ("Refracted Speed", Range(0.0, 0.2)) = 0.1
        _RefractedStrength ("Refracted Strength", Range(0.0, 0.1)) = 0.03

        [Header(Planar Reflection)]
        [Toggle(_USE_PLANAR_REFLECTION)] _UsePlanarReflection ("Use Planar Reflection", Float) = 1.0
        _ReflectionTex ("Reflection Texture", 2D) = "white" {}
        _FresnelPower ("Fresnel Power", Range(0.01, 64.0)) = 5.0
        _FresnelEdge ("Fresnel Edge", Range(0.0, 1.0)) = 0.7

    }   
    SubShader
    {
        Tags {
            "Queue"="Transparent"
            "RenderType"="Transparent"
            "RenderPipeline"="UniversalPipeline"
        }
        LOD 200
        Blend SrcAlpha OneMinusSrcAlpha

        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "HLSLs/Utils.hlsl"
            #include "HLSLs/UnityNoise.hlsl"
            #include "HLSLs/RefractedUV.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            #pragma shader_feature_local_fragment _USE_ALPHA
            #pragma shader_feature_local_fragment _USE_BLINN_PHONG_SPECULAR
            #pragma shader_feature_local_fragment _USE_COSINE_GRADIENT
            #pragma shader_feature_local_fragment _USE_NORMAL_MAP
            #pragma shader_feature_local_fragment _USE_SINE_WAVE
            #pragma shader_feature_local_fragment _USE_PLANAR_REFLECTION
            #pragma shader_feature_local_fragment _USE_REFRACTION

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv : TEXCOORD0;
                float3 normalOS : NORMAL;
                float4 tangentOS : TANGENT;
            };

            struct Varyings
            {
                float2 uv : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
                float3 tangentWS : TEXCOORD3;
                float3 bitangentWS : TEXCOORD4;
                float4 screenPos : TEXCOORD5;
                float4 positionCS : SV_POSITION;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _SpecularColor;
                float _SpecularPower;

                float _WaterDepthController;
                float _WaterColorController;
                float _DistanceController;
                float _WaterFadeController;

                float4 _ShallowColor;
                float4 _DeepColor;
                float4 _FarColor;

                float4 _FirstNormalMap_ST;
                float4 _SecondNormalMap_ST;
                float _FirstNormalSpeedInverse;
                float _SecondNormalSpeedInverse;

                float _SinePeriod;
                float _SineSpeed;
                float _SineAmplitude;
                float _SineMaskThreshold;
                float _SineStrength;

                float _NoiseSpeed;
                float _NoiseSize;
                float _NoiseMinEdge;
                float _NoiseMaxEdge;

                float _FresnelPower;
                float _FresnelEdge;

                float _RefractedScale;
                float _RefractedSpeed;
                float _RefractedStrength;
            CBUFFER_END

            TEXTURE2D(_BaseMap);                SAMPLER(sampler_BaseMap);
            TEXTURE2D(_FirstNormalMap);         SAMPLER(sampler_FirstNormalMap);
            TEXTURE2D(_SecondNormalMap);        SAMPLER(sampler_SecondNormalMap);
            TEXTURE2D(_ReflectionTex);          SAMPLER(sampler_ReflectionTex);
            TEXTURE2D(_CameraOpaqueTexture);    SAMPLER(sampler_CameraOpaqueTexture);

            Varyings vert (Attributes input)
            {
                Varyings output = (Varyings)0;

                VertexPositionInputs positionInputs = GetVertexPositionInputs(input.positionOS);
                VertexNormalInputs normalInputs = GetVertexNormalInputs(input.normalOS, input.tangentOS);

                output.uv = TRANSFORM_TEX(input.uv, _BaseMap);
                output.positionWS = positionInputs.positionWS;
                output.normalWS = normalize(normalInputs.normalWS);          // TransformObjectToWorldNormal(input.normalOS);
                output.tangentWS = normalize(normalInputs.tangentWS);        // TransformObjectToWorldDir(input.tangentOS);
                output.bitangentWS = normalize(normalInputs.bitangentWS);    // cross(output.normalWS, output.tangentWS) * input.tangentOS.w;
                output.screenPos = ComputeScreenPos(positionInputs.positionCS); // 获取顶点的屏幕坐标(未做透视除法)
                output.positionCS = positionInputs.positionCS;

                return output;
            }

            float3 GetWaterColorByCosineGradient(float depth)
            {
                float4 phase = float4(0.28, 0.44, 0.00, 0.);
				float4 amplitude = float4(3.27, 0.14, 0.39, 0.);
				float4 frequency = float4(0.00, 0.67, 0.28, 0.);
				float4 offset = float4(0.04, 0.14, 0.14, 0.);

				float TAU = 2 * 3.14159265;
				phase *= TAU;
				depth *= TAU;
				float4 waterColor = float4(
					offset.r + amplitude.r * 0.5 * cos(depth * frequency.r + phase.r) + 0.5,
					offset.g + amplitude.g * 0.5 * cos(depth * frequency.g + phase.g) + 0.5,
					offset.b + amplitude.b * 0.5 * cos(depth * frequency.b + phase.b) + 0.5,
					offset.a + amplitude.a * 0.5 * cos(depth * frequency.a + phase.a) + 0.5
				);
                return waterColor.rgb;
            }
            
            float4 frag(Varyings input) : SV_Target
            {
                // 获取水底深度
                float3 viewVector = input.positionWS - _WorldSpaceCameraPos.xyz;
                float screenPositionDepth = input.screenPos.w; // 未做透视除法的w即为顶点的深度
                float samplerDepth = LinearEyeDepth(SampleSceneDepth(input.screenPos.xy / input.screenPos.w), _ZBufferParams); // 使用做了透视除法的屏幕坐标采样深度纹理
                viewVector = viewVector / screenPositionDepth * samplerDepth;
                float3 waterBedPosition = viewVector + _WorldSpaceCameraPos.xyz;

                // 获取水深
                float waterDepth = (input.positionWS - waterBedPosition).y;
                waterDepth /= _WaterDepthController;
                float waterDepth01 = saturate(waterDepth);

                float3 shallowColor = _ShallowColor;
                #ifdef _USE_REFRACTION
                    float2 refractedUV = RefractedUV(input.uv, input.screenPos.xy / input.screenPos.w, _Time.y, _RefractedScale, _RefractedSpeed, _RefractedStrength);
                    shallowColor *= SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, refractedUV);
                #endif 

                float3 waterColor = lerp(shallowColor, _DeepColor, waterDepth01);
                #ifdef _USE_COSINE_GRADIENT
                    waterColor = GetWaterColorByCosineGradient(saturate(_WaterColorController - waterDepth01));
                #endif
                
                // 法线            
                float3 normalWS = input.normalWS;
                #ifdef _USE_NORMAL_MAP
                    // TBN矩阵
                    float3x3 tbnMatrix = float3x3(input.tangentWS, input.bitangentWS, input.normalWS);
                    // 法线采样，并转世界空间
                    float3 firstNormalTS = UnpackNormal(SAMPLE_TEXTURE2D(_FirstNormalMap, sampler_FirstNormalMap, input.uv * _FirstNormalMap_ST.xy + _Time.y / _FirstNormalSpeedInverse));
                    float3 secondNormalTS = UnpackNormal(SAMPLE_TEXTURE2D(_SecondNormalMap, sampler_SecondNormalMap, input.uv * _SecondNormalMap_ST.xy + _Time.y / _SecondNormalSpeedInverse));
                    float3 normalTS = normalize(firstNormalTS + secondNormalTS);
                    normalWS = mul(normalTS, tbnMatrix);
                #endif

                // Blinn-Phong光照
                Light mainLight = GetMainLight();
                float3 lightDirWS = normalize(mainLight.direction);
                float3 lightColor = mainLight.color;
                float3 viewDirWS = normalize(-viewVector);
                
                float NdotL = dot(normalWS, lightDirWS);
                float halfLambert = 0.5 * NdotL + 0.5;
                float3 diffuseColor = waterColor * lightColor * halfLambert;

                float3 finalColor = diffuseColor;

                #ifdef _USE_BLINN_PHONG_SPECULAR
                    float3 halfwayDirWS = normalize(lightDirWS + viewDirWS);
                    float NdotH = saturate(dot(normalWS, halfwayDirWS));
                    float3 specularColor = _SpecularColor.rgb * lightColor * pow(NdotH, _SpecularPower);
                    finalColor += specularColor;
                #endif

                #ifdef _USE_PLANAR_REFLECTION
                    // Planar Reflection
                    float fresnel = clamp(FresnelEffect(input.normalWS, viewDirWS, _FresnelPower), 0.0, _FresnelEdge);
                    #ifndef _USE_REFRACTION
                        float2 refractedUV = RefractedUV(input.uv, input.screenPos.xy / input.screenPos.w, _Time.y, _RefractedScale, _RefractedSpeed, _RefractedStrength);
                    #endif
                    float3 reflectionColor = SAMPLE_TEXTURE2D(_ReflectionTex, sampler_ReflectionTex, refractedUV) * waterColor;
                    finalColor = lerp(finalColor, reflectionColor, fresnel);
                #endif

                #ifdef _USE_SINE_WAVE
                    // SineWave
                    float sineWave = saturate(_SineAmplitude * sin(_SinePeriod * PI * waterDepth + _Time.y * _SineSpeed));
                    float waterDepthMask = 1.0 - step(1.0 - waterDepth01, _SineMaskThreshold);

                    // 采样噪声纹理
                    float noiseValue = 0.0;
                    float2 noiseUV = float2((input.uv * 10.0).r, _Time.y * _NoiseSpeed);
                    // SimpleNoise为Shader Graph的Simple Noise节点的代码实现
                    // 参考：https://docs.unity3d.com/cn/Packages/com.unity.shadergraph@10.5/manual/Simple-Noise-Node.html
                    SimpleNoise(noiseUV, _NoiseSize, noiseValue); 

                    // sineWave叠加噪声值，并截取
                    sineWave += noiseValue;
                    sineWave = smoothstep(_NoiseMinEdge, _NoiseMaxEdge, sineWave);

                    // 从遮罩边缘往岸边，透明度增高
                    sineWave *= waterDepthMask;
                    sineWave *= Remap(clamp(1.0 - waterDepth01, _SineMaskThreshold, 1.0), float2(_SineMaskThreshold, 1.0), float2(0.0, 1.0));
                    sineWave *= _SineStrength;

                    // 越往岸边，透明度降低
                    // 最终从遮罩边缘往岸边，透明度呈现先高后低的趋势
                    // 岸边浪花处的透明度等于sineWave值
                    float edgeMask = 1.0 - Remap(clamp(1.0 - waterDepth01, _SineMaskThreshold, 1.0), float2(_SineMaskThreshold, 1.0), float2(0.0, 1.0));
                    waterDepth01 = (waterDepth01 + sineWave) * edgeMask;
                    finalColor += sineWave;
                #endif

                // 远水颜色
                float farWaterDistance = length(input.positionWS - _WorldSpaceCameraPos.xyz);
                farWaterDistance *= -_DistanceController;
                farWaterDistance = saturate(exp(farWaterDistance));
                finalColor = lerp(_FarColor, finalColor, farWaterDistance);

                float waterAlpha = 1.0;
                #ifdef _USE_ALPHA
                    waterAlpha = Remap(waterDepth01, float2(0, _WaterFadeController), float2(0, 1.0));
                #endif
                return float4(finalColor, waterAlpha);
            }
            ENDHLSL
        }
    }
}
