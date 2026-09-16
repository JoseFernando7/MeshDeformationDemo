Shader "Custom/TestShader"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (0.121, 0.654, 0.721, 1.0)

        _Amplitude ("Wave 1 Amplitude", Float) = 0.15
        _Frequency ("Wave 1 Frequency", Float) = 1.0
        _Speed ("Wave 1 Speed", Float) = 0.5

        _Amplitude2 ("Wave 2 Amplitude", Float) = 0.08
        _Frequency2 ("Wave 2 Frequency", Float) = 1.7
        _Speed2 ("Wave 2 Speed", Float) = 0.3

        _SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
        _Smoothness ("Smoothness", Range(0.0, 1.0)) = 0.9

        _ReflectionStrength ("Reflection Strength", Range(0.0, 2.0)) = 1.0

        _FresnelColor ("Fresnel Color", Color) = (0.2, 0.5, 1.0, 1)
        _FresnelPower ("Fresnel Power", Range(1.0, 8.0)) = 4.0
    }

    SubShader
    {
        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType" = "Opaque"
        }

        Pass
        {
            Name "ForwardLit"

            Tags
            {
                "LightMode" = "UniversalForward"
            }

            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile _ _ADDITIONAL_LIGHTS
            #pragma multi_compile _ _FORWARD_PLUS

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/GlobalIllumination.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
            };

            CBUFFER_START(UnityPerMaterial)

                float4 _BaseColor;

                float _Amplitude;
                float _Frequency;
                float _Speed;

                float _Amplitude2;
                float _Frequency2;
                float _Speed2;

                float4 _SpecularColor;
                float _Smoothness;

                float _ReflectionStrength;

                float4 _FresnelColor;
                float _FresnelPower;

            CBUFFER_END


            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                float3 position = IN.positionOS.xyz;

                float time = _Time.y;


                // ========================================================
                // WAVE 1
                // ========================================================

                float wave1 =
                    position.x * _Frequency
                    + time * _Speed;


                // ========================================================
                // WAVE 2
                // ========================================================

                float wave2 =
                    position.z * _Frequency2
                    + time * _Speed2;


                // ========================================================
                // SURFACE DEFORMATION
                // ========================================================

                position.y +=
                    sin(wave1) * _Amplitude;

                position.y +=
                    sin(wave2) * _Amplitude2;


                // ========================================================
                // DERIVATIVES
                // ========================================================

                float slopeX =
                    _Amplitude
                    * _Frequency
                    * cos(wave1);

                float slopeZ =
                    _Amplitude2
                    * _Frequency2
                    * cos(wave2);


                // ========================================================
                // DEFORMED SURFACE NORMAL
                // ========================================================

                float3 normalOS =
                    normalize(
                        float3(
                            -slopeX,
                            1.0,
                            -slopeZ
                        )
                    );


                // ========================================================
                // TRANSFORMATIONS
                // ========================================================

                OUT.positionHCS =
                    TransformObjectToHClip(position);

                OUT.normalWS =
                    TransformObjectToWorldNormal(normalOS);

                OUT.positionWS =
                    TransformObjectToWorld(position);

                return OUT;
            }


            // ============================================================
            // DIRECT LIGHTING
            // ============================================================

            float3 CalculateLight(
                float3 normalWS,
                float3 viewDirWS,
                Light light
            )
            {
                float3 lightDirWS =
                    normalize(light.direction);


                // --------------------------------------------------------
                // Diffuse
                // --------------------------------------------------------

                float diffuse =
                    saturate(
                        dot(
                            normalWS,
                            lightDirWS
                        )
                    );


                // --------------------------------------------------------
                // Specular
                // --------------------------------------------------------

                float3 halfDir =
                    normalize(
                        lightDirWS
                        + viewDirWS
                    );

                float specular =
                    pow(
                        saturate(
                            dot(
                                normalWS,
                                halfDir
                            )
                        ),
                        _Smoothness * 128.0
                    );


                // --------------------------------------------------------
                // Attenuation
                // --------------------------------------------------------

                float attenuation =
                    light.distanceAttenuation
                    * light.shadowAttenuation;


                // --------------------------------------------------------
                // Lighting
                // --------------------------------------------------------

                float3 diffuseLighting =
                    diffuse
                    * light.color
                    * attenuation;

                float3 specularLighting =
                    specular
                    * _SpecularColor.rgb
                    * light.color
                    * attenuation;


                return diffuseLighting
                    + specularLighting;
            }


            half4 frag(Varyings IN) : SV_Target
            {
                // ========================================================
                // SURFACE DATA
                // ========================================================

                float3 normalWS =
                    normalize(IN.normalWS);

                float3 viewDirWS =
                    normalize(
                        _WorldSpaceCameraPos.xyz
                        - IN.positionWS
                    );


                // ========================================================
                // INPUT DATA
                // ========================================================

                InputData inputData =
                    (InputData)0;

                inputData.positionWS =
                    IN.positionWS;

                inputData.normalWS =
                    normalWS;

                inputData.viewDirectionWS =
                    viewDirWS;

                inputData.normalizedScreenSpaceUV =
                    GetNormalizedScreenSpaceUV(
                        IN.positionHCS
                    );


                // ========================================================
                // MAIN LIGHT — MOON
                // ========================================================

                Light mainLight =
                    GetMainLight();

                float3 lighting =
                    CalculateLight(
                        normalWS,
                        viewDirWS,
                        mainLight
                    );


                // ========================================================
                // ADDITIONAL LIGHTS — LANTERNS
                // ========================================================

                #if defined(_ADDITIONAL_LIGHTS)

                    // ----------------------------------------------------
                    // Forward+
                    // ----------------------------------------------------

                    #if USE_FORWARD_PLUS

                        UNITY_LOOP

                        for (
                            uint lightIndex = 0;
                            lightIndex < min(
                                URP_FP_DIRECTIONAL_LIGHTS_COUNT,
                                MAX_VISIBLE_LIGHTS
                            );
                            lightIndex++
                        )
                        {
                            Light additionalLight =
                                GetAdditionalLight(
                                    lightIndex,
                                    inputData.positionWS,
                                    half4(1, 1, 1, 1)
                                );

                            lighting +=
                                CalculateLight(
                                    normalWS,
                                    viewDirWS,
                                    additionalLight
                                );
                        }

                    #endif


                    // ----------------------------------------------------
                    // Forward
                    // ----------------------------------------------------

                    uint pixelLightCount =
                        GetAdditionalLightsCount();

                    LIGHT_LOOP_BEGIN(pixelLightCount)

                        Light additionalLight =
                            GetAdditionalLight(
                                lightIndex,
                                inputData.positionWS,
                                half4(1, 1, 1, 1)
                            );

                        lighting +=
                            CalculateLight(
                                normalWS,
                                viewDirWS,
                                additionalLight
                            );

                    LIGHT_LOOP_END

                #endif


                // ========================================================
                // FRESNEL
                // ========================================================

                float fresnel =
                    pow(
                        1.0
                        - saturate(
                            dot(
                                normalWS,
                                viewDirWS
                            )
                        ),
                        _FresnelPower
                    );


                // ========================================================
                // ENVIRONMENT REFLECTION
                // ========================================================

                float3 reflectionVector =
                    reflect(
                        -viewDirWS,
                        normalWS
                    );


                // Smoothness -> Perceptual Roughness
                //
                // Smoothness 1.0 = sharp reflection
                // Smoothness 0.0 = very blurry reflection

                float perceptualRoughness =
                    1.0 - _Smoothness;


                float3 environmentReflection =
                    GlossyEnvironmentReflection(
                        reflectionVector,
                        IN.positionWS,
                        perceptualRoughness,
                        1.0,
                        inputData.normalizedScreenSpaceUV
                    );


                // Fresnel makes the reflection stronger
                // at grazing angles.

                float3 reflectionLighting =
                    environmentReflection
                    * _ReflectionStrength
                    * fresnel;


                // ========================================================
                // FRESNEL COLOR
                // ========================================================

                float3 fresnelLighting =
                    fresnel
                    * _FresnelColor.rgb;


                // ========================================================
                // FINAL COLOR
                // ========================================================

                float3 finalColor =
                    _BaseColor.rgb
                    * lighting
                    + reflectionLighting
                    + fresnelLighting;


                return half4(
                    finalColor,
                    _BaseColor.a
                );
            }

            ENDHLSL
        }
    }
}
