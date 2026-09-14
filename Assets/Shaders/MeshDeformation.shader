Shader "Custom/TestShader"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (0.121, 0.654, 0.721, 1.0)

        _Amplitude ("Amplitude", Float) = 1.0
        _Frequency ("Frequency", Float) = 1.0
        _Speed ("Speed", Float) = 1.0
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
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float _Amplitude;
                float _Frequency;
                float _Speed;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                float3 position = IN.positionOS.xyz;

                float time = _Time.y;

                // Sinoidal function
                float wave = position.x * _Frequency + time * _Speed;

                // Surface deformation
                position.y += sin(wave) * _Amplitude;

                // Derivative of the function
                // dy/dx = Amplitude * Frequency * cos(wave)
                float slope = _Amplitude * _Frequency * cos(wave);

                // Deformed surface normal
                float3 normalOS = normalize(float3(-slope, 1.0, 0.0));

                //position.y += sin(position.x) * _Amplitude;

                // Transformations
                OUT.positionHCS = TransformObjectToHClip(position);

                OUT.normalWS = TransformObjectToWorldNormal(normalOS);

                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float3 normalWS = normalize(IN.normalWS);

                Light mainLight = GetMainLight();

                float diffuse = saturate(dot(normalWS, mainLight.direction));

                float3 lighting = diffuse * mainLight.color;

                float3 finalColor = _BaseColor.rgb * lighting;

                return half4(finalColor, _BaseColor.a);
            }

            ENDHLSL
        }
    }
}
