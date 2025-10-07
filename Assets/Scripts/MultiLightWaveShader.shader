Shader "Custom/MultiLightWave"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Frequency ("Frequency", float) = 32.0
        _Amplitude ("Amplitude", float) = 0.25
        _Speed ("Speed", float) = 1.0
        _Steepness ("Steepness", Range(0.0, 1.0)) = 0.5
        _HeightFactor ("Height Factor", float) = 1.0
        _Direction ("Direction", vector) = (1.0, 0.0, 0.0, 0.0)
        _Seed ("Seed", Integer) = 0
        _SeedOffset ("Seed Offset", Integer) = 25
        _NumWaves ("Number of Waves", Integer) = 5
        _Tint ("Tint", Color) = (1, 1, 1, 1)
        _SpecularTint ("Specular Tint", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { 
            "RenderType"="Opaque"
        }
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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Tint;
            float4 _SpecularTint;

            float _Frequency;
            float _Amplitude;
            float _Speed;
            float _Steepness;
            float _HeightFactor;
            float4 _Direction;
            uint _NumWaves;

            uint _Seed;
            uint _SeedOffset;

            float bbs(uint v) {
                v = v % 65521u;
                v = (v * v) % 65521u;
                v = (v * v) % 65521u;
                return frac((float) v / 10000.0);
            }

            UnityLight CreateLight(v2f i){
                UnityLight light;

                UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);
                
                light.dir = _WorldSpaceLightPos0.xyz;
                light.color = _LightColor0.rgb * attenuation;
                light.ndotl = DotClamped(i.normal, light.dir);

                return light;
            }

            v2f vert (appdata v)
            {
                v2f o;
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.normal = float3(0.0, 0.0, 0.0);

                float frequencyToAmplitude = _Amplitude / _Frequency;

                for (uint i = 0; i < _NumWaves; i++){
                    int seed = (i + _Seed) * 100;

                    float speed = _Speed * bbs(seed);
                    float frequency = _Frequency * bbs(seed + _SeedOffset);
                    float amplitude = frequency * frequencyToAmplitude;
                    float2 direction = float2(_Direction.x * bbs(seed + (_SeedOffset * 3)), _Direction.y * bbs(seed + (_SeedOffset * 4)));
                    float phaseconstant = speed * frequency;

                    float steepness = _Steepness / (frequency * amplitude * _NumWaves);

                    worldPos.x += steepness * amplitude * direction.x * cos(_Time.y * phaseconstant + dot(direction.xy * frequency, v.uv));
                    worldPos.z += steepness * amplitude * direction.y * cos(_Time.y * phaseconstant + dot(direction.xy * frequency, v.uv));

                    worldPos.y += ((sin((_Time.y * phaseconstant + dot(direction.xy * frequency, v.uv))) + 1) / 2.0) * amplitude * 2.0;

                    float WA = frequency * amplitude;
                    float CO = cos(dot(frequency * direction, v.uv) + (_Time.y * phaseconstant));
                    float SO = sin(dot(frequency * direction, v.uv) + (_Time.y * phaseconstant));

                    o.normal.x += direction.x * WA * CO;
                    o.normal.z += direction.y * WA * CO;

                    o.normal.y += steepness * WA * SO;
                }
                (worldPos.y *= _HeightFactor) /= _NumWaves;
                o.worldPos = worldPos;

                o.normal.x = -o.normal.x;
                o.normal.y = 1 - o.normal.y;
                o.normal.z = -o.normal.z;

                o.vertex = mul(UNITY_MATRIX_VP, worldPos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                i.normal = normalize(i.normal);
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos.xyz);
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float3 halfVector = normalize(lightDir + viewDir);

                UnityLight light = CreateLight(i);

                // sample the texture
                float3 diffuse = tex2D(_MainTex, i.uv) * _Tint * light.color * DotClamped(lightDir, i.normal);
                float3 specular = tex2D(_MainTex, i.uv) * _SpecularTint * light.color * pow(DotClamped(halfVector, i.normal), 15);
                float3 ambient = tex2D(_MainTex, i.uv) * light.color * 0.05;

                float3 col = diffuse + specular + ambient;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                //return half4(i.normal.x, i.normal.y, i.normal.z, 1.0);
                return half4(col.xyz, 1.0);
            }
            ENDCG
        }

        Pass{
            Tags {
				"LightMode" = "ForwardAdd"
			}

            Blend One One
            ZWrite Off

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

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _Tint;
            float4 _SpecularTint;

            float _Frequency;
            float _Amplitude;
            float _Speed;
            float _Steepness;
            float _HeightFactor;
            float4 _Direction;
            uint _NumWaves;

            uint _Seed;
            uint _SeedOffset;

            float bbs(uint v) {
                v = v % 65521u;
                v = (v * v) % 65521u;
                v = (v * v) % 65521u;
                return frac((float) v / 1000.0);
            }

            UnityLight CreateLight(v2f i){
                UnityLight light;

                UNITY_LIGHT_ATTENUATION(attenuation, i, i.worldPos);
                
                light.dir = _WorldSpaceLightPos0.xyz;
                light.color = _LightColor0.rgb * attenuation;
                light.ndotl = DotClamped(i.normal, light.dir);

                return light;
            }

            v2f vert (appdata v)
            {
                v2f o;
                float4 worldPos = mul(unity_ObjectToWorld, v.vertex);
                o.normal = float3(0.0, 0.0, 0.0);

                float frequencyToAmplitude = _Amplitude / _Frequency;

                for (uint i = 0; i < _NumWaves; i++){
                    int seed = (i + _Seed) * 100;

                    float speed = _Speed * bbs(seed);
                    float frequency = _Frequency * bbs(seed + _SeedOffset);
                    float amplitude = frequency * frequencyToAmplitude;
                    float2 direction = float2(_Direction.x * bbs(seed + (_SeedOffset * 3)), _Direction.y * bbs(seed + (_SeedOffset * 4)));
                    float phaseconstant = speed * frequency;

                    float steepness = _Steepness / (frequency * amplitude * _NumWaves);

                    worldPos.x += steepness * amplitude * direction.x * cos(_Time.y * phaseconstant + dot(direction.xy * frequency, v.uv));
                    worldPos.z += steepness * amplitude * direction.y * cos(_Time.y * phaseconstant + dot(direction.xy * frequency, v.uv));

                    worldPos.y += ((sin((_Time.y * phaseconstant + dot(direction.xy * frequency, v.uv))) + 1) / 2.0) * amplitude * 2.0;

                    float WA = frequency * amplitude;
                    float CO = cos(dot(frequency * direction, v.uv) + (_Time.y * phaseconstant));
                    float SO = sin(dot(frequency * direction, v.uv) + (_Time.y * phaseconstant));

                    o.normal.x += direction.x * WA * CO;
                    o.normal.z += direction.y * WA * CO;

                    o.normal.y += steepness * WA * SO;
                }
                (worldPos.y *= _HeightFactor) /= _NumWaves;
                o.worldPos = worldPos;

                o.normal.x = -o.normal.x;
                o.normal.y = 1 - o.normal.y;
                o.normal.z = -o.normal.z;

                o.vertex = mul(UNITY_MATRIX_VP, worldPos);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                i.normal = normalize(i.normal);
                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos.xyz);
                float3 lightDir = _WorldSpaceLightPos0.xyz;
                float3 halfVector = normalize(lightDir + viewDir);

                UnityLight light = CreateLight(i);

                // sample the texture
                float3 diffuse = tex2D(_MainTex, i.uv) * _Tint * light.color * DotClamped(lightDir, i.normal);
                float3 specular = _SpecularTint * light.color * pow(DotClamped(halfVector, i.normal), 15);
                float3 ambient = light.color * 0.01;

                float3 col = diffuse + specular;

                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);

                //return half4(i.normal.x, i.normal.y, i.normal.z, 1.0);
                return half4(col.xyz, 1.0);
            }
            ENDCG
        }
    }
}
