Shader "Custom/SimpleWaveShader"
{
    Properties
    {
        _Frequency ("Frequency", float) = 32.0
        _Amplitude ("Amplitude", float) = 0.25
        _Speed ("Speed", float) = 1.0
        _Tint ("Tint", Color) = (1, 1, 1, 1)
        _SpecularTint ("Specular Tint", Color) = (1, 1, 1, 1)
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags {
                "LightMode" = "ForwardBase"
            }

            CGPROGRAM

            #pragma target 3.0

            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityStandardBRDF.cginc"
            #include "UnityPBSLighting.cginc"
            #include "AutoLight.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
                float3 normal : TEXCOORD1;
                float4 worldPos : TEXCOORD2;
            };

            float4 _Tint;
            float4 _SpecularTint;
            float _Smoothness;

            float _Frequency;
            float _Amplitude;
            float _Speed;

            v2f vert (appdata v)
            {
                v2f o;
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);

                o.worldPos = worldPos;

                float speed = _Speed;
                float frequency = _Frequency;
                float amplitude = _Amplitude;
                float phaseconstant = speed * frequency;

                worldPos.y = sin(_Time.y * phaseconstant + v.uv.x * frequency) * amplitude;

                float3 tangent = float3(1.0, frequency * amplitude * cos(_Time.y * phaseconstant + v.uv.x * frequency), 0.0);
                float3 binormal = float3(0.0, 0.0, 1.0);

                o.normal = normalize(cross(binormal, tangent));

                o.vertex = mul(UNITY_MATRIX_VP, worldPos);
                o.uv = v.uv;
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                i.normal = normalize(i.normal);

                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float3 lightColor = _LightColor0.rgb;
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos.xyz);
                float3 halfVector = normalize(lightDir + viewDir);

                float3 albedo = _Tint.xyz;
                albedo *= (1 - _SpecularTint.xyz);
				
                float3 diffuse = lightColor * albedo * DotClamped(lightDir, i.normal);
                float3 specular = lightColor * _SpecularTint.xyz * pow(DotClamped(halfVector, i.normal), _Smoothness * 100);
                float3 ambient = lightColor * albedo * 0.1;

                float3 col = diffuse + specular + ambient;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                return half4(col.xyz, 1.0);
            }
            ENDCG
        }
    }
}
