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
        _Smoothness ("Smoothness", Range(0.0, 1.0)) = 0.8

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
            HLSLPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 normalWS : TEXTCOORD0;
                float3 positionWS : TEXTCOORD1;
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

                float4 _FresnelColor;
                float _FresnelPower;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                float3 position = IN.positionOS.xyz;

                float time = _Time.y;

                // Sinoidal function
                float wave1 = position.x * _Frequency + time * _Speed;
                float wave2 = position.z * _Frequency2 + time * _Speed2;

                // Surface deformation
                position.y += sin(wave1) * _Amplitude;
                position.y += sin(wave2) * _Amplitude2;

                // Derivative of the function
                // dy/dx = Amplitude * Frequency * cos(wave)
                float slopeX = _Amplitude * _Frequency * cos(wave1);
                float slopeZ = _Amplitude2 * _Frequency2 * cos(wave2);

                // Deformed surface normal
                float3 normalOS = normalize(float3(-slopeX, 1.0, -slopeZ));

                //position.y += sin(position.x) * _Amplitude;

                // Transformations
                OUT.positionHCS = TransformObjectToHClip(position);

                OUT.normalWS = TransformObjectToWorldNormal(normalOS);
                OUT.positionWS = TransformObjectToWorld(position);

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float3 normalWS = normalize(IN.normalWS);
                float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - IN.positionWS);

                Light mainLight = GetMainLight();

                float3 lightDirWS = normalize(mainLight.direction);

                float diffuse = saturate(dot(normalWS, mainLight.direction));

                float3 halfDir = normalize(lightDirWS + viewDirWS);

                float specular = pow(saturate(dot(normalWS, halfDir)), _Smoothness * 128.0);

                float fresnel = pow(1.0 - saturate(dot(normalWS, viewDirWS)), _FresnelPower);

                float3 fresnelLighting = fresnel * _FresnelColor.rgb;

                float3 lighting = diffuse * mainLight.color;

                float3 specularLighting = specular * _SpecularColor.rgb * mainLight.color;

                float3 finalColor = _BaseColor.rgb * lighting + specularLighting + fresnelLighting;

                return half4(finalColor, _BaseColor.a);
            }

            ENDHLSL
        }
    }
}
