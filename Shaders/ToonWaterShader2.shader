Shader "Unlit/ToonWaterShader"
{
    Properties
    {
        [Header(General)]
        [MainTexture] _BaseMap ("Base Map", 2D) = "white" {}
        [Toggle(_USE_ALPHA)] _UseAlpha("Use Alpha", Float) = 1.0
        [Toggle(_USE_BLINN_PHONG_MODEL)] _UseBlinnPhongModel("Use Blinn Phong Model", Float) = 1.0
        [Toggle(_USE_BLINN_PHONG_SPECULAR)] _UseBlinnPhongSpecular("Use Blinn Phong Specular", Float) = 1.0
        _SpecularColor ("Specular Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _SpecularPower ("Specular Power", Float) = 8.0

        [Header(Controllers)]
        _WaterDepthController ("Water Depth Controller", Float) = 1.0
        _DistanceController ("Far Water Color Distance Controller", Float) = 0.1
        _WaterFadeController ("Water Fade Controller", Float) = 0.2
        _WaterMixController ("Water Mix Controller", Range(0, 1)) = 0.3
        [Toggle(_USE_REFRACTED_DEPTH_CONTROLLER)] _UseRefractedDepthController("Use Refracted Depth Controller", Float) = 1.0
        _RefractedDepthController ("Refracted Depth Controller", Range(0.0001, 3)) = 0.2

        [Header(Water Color)]
        [Toggle(_USE_SHALLOW_COLOR)] _UseShallowColor ("Use Shallow Color", Float) = 1.0
        [HDR] _ShallowColor ("Shallow Color", Color) = (1.0, 1.0, 1.0, 1.0)
        [HDR] _DeepColor ("Deep Color", Color) = (1.0, 1.0, 1.0, 1.0)
        [Toggle(_USE_FAR_COLOR)] _UseFarColor ("Use Far Color", Float) = 1.0
        [HDR] _FarColor ("Far Color", Color) = (1.0, 1.0, 1.0, 1.0)
        [Toggle(_USE_DEEP_WATER_OPAQUE)] _UseDeepWaterOpaque ("Use Deep Water Opaque", Float) = 0.0
        _OpaqueDepthMinEdge ("Opaque Depth Min Edge", Float) = 3.5
        _OpaqueDepthRange ("Opaque Depth Range", Float) = 3.5

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

            #include "Utils.hlsl"
            #include "UnityNoise.hlsl"

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DeclareDepthTexture.hlsl"

            #pragma shader_feature_local_fragment _USE_ALPHA
            #pragma shader_feature_local_fragment _USE_SHALLOW_COLOR
            #pragma shader_feature_local_fragment _USE_DEEP_WATER_OPAQUE
            #pragma shader_feature_local_fragment _USE_FAR_COLOR
            #pragma shader_feature_local_fragment _USE_REFRACTED_DEPTH_CONTROLLER
            #pragma shader_feature_local_fragment _USE_BLINN_PHONG_MODEL
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
                float _WaterMixController;
                float _RefractedDepthController;
                float _OpaqueDepthMinEdge;
                float _OpaqueDepthRange;

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
            
            float3 ScenePosition(float3 positionWS, float4 screenPos, float2 uv)
            {
                float3 viewVector = positionWS - _WorldSpaceCameraPos.xyz;
                float screenPositionDepth = screenPos.w; // 未做透视除法的w即为顶点的深度
                float samplerDepth = LinearEyeDepth(SampleSceneDepth(uv), _ZBufferParams); // 使用做了透视除法的屏幕坐标采样深度纹理
                viewVector = viewVector / screenPositionDepth * samplerDepth;
                float3 scenePosition = viewVector + _WorldSpaceCameraPos.xyz;
                return scenePosition;
            }

            float2 RefractedUV(float2 uv, float4 screenPos, float3 worldPos, float time, float scale, float speed, float strength)
            {
                uv = uv * rcp(scale) + speed * time;
                float noise = 0.0;
                GradientNoise(uv, 10, noise);
                noise = Remap(noise, float2(0, 1), float2(-1, 1)) * strength;
                float2 outUV = screenPos.xy / screenPos.w + noise;
                // 消除当物体露出水面时的扭曲错误
                float3 scenePos = ScenePosition(worldPos, screenPos, outUV);
                float deltaY = (worldPos - scenePos).g;
                if(deltaY <= 0.001)
                    outUV = screenPos.xy / screenPos.w;
                return outUV;
            }

            float4 frag(Varyings input) : SV_Target
            {
                float2 screenUV = input.screenPos.xy / input.screenPos.w;
                #ifdef _USE_REFRACTION// 如果开启折射效果，则uv进行折射扭曲
                    screenUV = RefractedUV(input.uv, input.screenPos, input.positionWS, _Time.y, _RefractedScale, _RefractedSpeed, _RefractedStrength);
                #endif

                // 获取水底深度，使用扭曲后的screenUV，采样场景位置，可以避免因未扭曲深度而导致的渲染错误问题
                float3 waterBedPosition = ScenePosition(input.positionWS, input.screenPos, screenUV);

                // 获取水深
                // 直接除以一个系数获取深度
                // float waterDepth = (input.positionWS - waterBedPosition).y;
                // float waterDepth01 = saturate(waterDepth / _WaterDepthController);
                // waterDepth01 = smoothstep(0.1, 1.0, waterDepth01);
                // 使用自然对数获取深度
                float waterDepth = (input.positionWS - waterBedPosition).y;
                float waterDepthExponential = exp((-waterDepth) / _WaterDepthController);
                float waterDepth01 = 1.0 - saturate(waterDepthExponential);
                
                float3 waterColor = _DeepColor;
                #ifdef _USE_SHALLOW_COLOR
                    waterColor = lerp(_ShallowColor, _DeepColor, waterDepth01);
                #endif
                #ifdef _USE_COSINE_GRADIENT
                    waterColor = GetWaterColorByCosineGradient(saturate(_WaterColorController - waterDepth01));
                #endif

                #ifdef _USE_REFRACTED_DEPTH_CONTROLLER
                    float refractedDepth = smoothstep(0.0, _RefractedDepthController, waterDepth01);
                    screenUV = lerp(input.screenPos.xy / input.screenPos.w, screenUV, refractedDepth);
                #endif

                // 折射效果
                float3 surfaceColor = SAMPLE_TEXTURE2D(_CameraOpaqueTexture, sampler_CameraOpaqueTexture, screenUV); // 浅层水颜色，不乘上水体蓝色，为透明色
                float3 surfaceWaterColor = waterColor * surfaceColor; // 深层水颜色，乘上水体蓝色
                #ifdef _USE_DEEP_WATER_OPAQUE // 很深的水不显示水底画面，只显示水体颜色
                    float opaqueDepthController = Remap(waterDepth, float2(_OpaqueDepthMinEdge, _OpaqueDepthMinEdge + _OpaqueDepthRange), float2(0.0, 1.0));;
                    waterColor = lerp(surfaceWaterColor, waterColor, opaqueDepthController); // 折射部分的颜色需要混合水体颜色
                #else
                    waterColor = surfaceWaterColor;
                #endif

                // 平面反射(Planar Reflection)
                float3 viewVector = input.positionWS - _WorldSpaceCameraPos.xyz;
                #ifdef _USE_PLANAR_REFLECTION
                    float fresnel = clamp(FresnelEffect(input.normalWS, normalize(-viewVector), _FresnelPower), 0.0, _FresnelEdge);
                    if(waterDepth < _WaterFadeController) // 水深低于阈值，则菲涅尔效果减弱，显示折射原色(未混合水体颜色)
                        fresnel *= waterDepth / _WaterFadeController;
                    float3 reflectionColor = SAMPLE_TEXTURE2D(_ReflectionTex, sampler_ReflectionTex, screenUV);
                    // surfaceColor = lerp(surfaceColor, reflectionColor, fresnel); // 最终的浅层水颜色(不融合水体颜色)
                    // 反射部分的颜色需要按比例混合水体颜色
                    float3 reflectionWaterColor = lerp(reflectionColor, waterColor, _WaterMixController);
                    surfaceColor = lerp(surfaceColor, reflectionWaterColor, fresnel); // 最终的浅层水颜色(融合水体颜色)
                    waterColor = lerp(waterColor, reflectionWaterColor, fresnel); // 最终的深层水颜色
                #endif
                
                waterColor = lerp(surfaceColor, waterColor, waterDepth01); // 按深度混合，获得最终的水体颜色
                
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

                float3 finalColor = waterColor;

                Light mainLight = GetMainLight();
                float3 lightDirWS = normalize(mainLight.direction);
                float3 lightColor = mainLight.color;
                float3 viewDirWS = normalize(-viewVector);
                #ifdef _USE_BLINN_PHONG_MODEL
                    // Blinn-Phong光照
                    float NdotL = dot(normalWS, lightDirWS);
                    float halfLambert = 0.5 * NdotL + 0.5;
                    float3 diffuseColor = waterColor * lightColor * halfLambert;
                    finalColor = diffuseColor;
                #endif
                #ifdef _USE_BLINN_PHONG_SPECULAR
                    float3 halfwayDirWS = normalize(lightDirWS + viewDirWS);
                    float NdotH = saturate(dot(normalWS, halfwayDirWS));
                    float3 specularColor = _SpecularColor.rgb * lightColor * pow(NdotH, _SpecularPower);
                    finalColor += specularColor;
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
                #ifdef _USE_FAR_COLOR
                    float farWaterDistance = length(input.positionWS - _WorldSpaceCameraPos.xyz);
                    farWaterDistance *= -_DistanceController;
                    farWaterDistance = saturate(exp(farWaterDistance));
                    finalColor = lerp(_FarColor, finalColor, farWaterDistance);
                #endif

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