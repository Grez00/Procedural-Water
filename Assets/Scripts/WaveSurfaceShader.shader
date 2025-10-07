Shader "Custom/WaveSurfaceShader"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _NormalMap ("Normal Map", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _Alpha ("Alpha", Range(0.0, 1.0)) = 1.0
        _WaterFogColour ("Water Fog Colour", Color) = (0, 0, 1, 1)
        _WaterFogDensity ("Water Fog Density", Range(0, 2)) = 0.1

        _Frequency ("Frequency", float) = 32.0
        _Steepness ("Steepness", Range(0, 1)) = 0.5
        _Direction ("Direction", Vector) = (1, 0, 0, 0)

        _Seed ("Seed", Integer) = 1
        _NumWaves ("Number of Waves", Integer) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" "Queue"="Transparent" }
        LOD 200

        GrabPass { "_WaterBackground" }

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard alpha finalcolor:ResetAlpha vertex:vert

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _NormalMap;

        struct Input
        {
            float2 uv_MainTex;
            float2 uv_Normal;
            float4 screenPos;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        float _Alpha;

        float3 _WaterFogColour;
        float _WaterFogDensity;

        sampler2D _CameraDepthTexture, _WaterBackground;
        float4 _CameraDepthTexture_TexelSize;

        float _Frequency;
        float _Steepness;
        float2 _Direction;

        int _Seed;
        int _NumWaves;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        float bbs(uint v) {
            v = v % 65521u;
            v = (v * v) % 65521u;
            v = (v * v) % 65521u;
            return frac((float) v / 10000.0);
        }

        float3 GerstnerWave(float4 wave, float3 p, inout float3 tangent, inout float3 binormal){
            float frequency = wave.x;
            float steepness = wave.y;
            float2 dir = normalize(float2(wave.z, wave.w));

            float speed = sqrt(9.8 / frequency);
            float amplitude = steepness / frequency;
            float phaseconstant = speed * frequency;

            float wf = _Time.y * phaseconstant + dot(dir, p.xz) * frequency;

            tangent += float3(
                -pow(dir.x, 2) * steepness * sin(wf),
                dir.x * steepness * cos(wf),
                -dir.x * dir.y * steepness * sin(wf)
            );
            binormal += float3(
                -dir.x * dir.y * steepness * sin(wf),
                dir.y * steepness * cos(wf),
                -pow(dir.y, 2) * steepness * sin(wf)
            );

            return float3(
                dir.x * cos(wf) * amplitude,
                sin(wf) * amplitude,
                dir.y * cos(wf) * amplitude
            );
        }

        void vert(inout appdata_full vertexData) {
            float3 vertex_pos = vertexData.vertex.xyz;
			float3 p = vertex_pos;

            float3 tangent = float3(1, 0, 0);
            float3 binormal = float3(0, 0, 1);

            for (int i = 0; i < _NumWaves; i++){
                int seed = (i + _Seed) * 100;

                float4 wave = float4(
                    _Frequency * bbs(seed),
                    _Steepness * bbs(seed * 2),
                    _Direction.x * bbs(seed * 4),
                    _Direction.y * bbs(seed * 8)
                );
                p += GerstnerWave(wave, vertex_pos, tangent, binormal);
            }

            float3 normal = normalize(cross(binormal, tangent));
            //normal += normalize();
            vertexData.normal = normalize(normal);
			vertexData.vertex.xyz = p;
        }

        float ColourBelowWater(float4 screenPos){
            float2 uv = screenPos.xy / screenPos.w;
            #if UNITY_UV_STARTS_AT_TOP
                if (_CameraDepthTexture_TexelSize.y < 0) {
                    uv.y = 1 - uv.y;
                }
            #endif

            float backgroundDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, uv));
            float surfaceDepth = UNITY_Z_0_FAR_FROM_CLIPSPACE(screenPos.z);
            float depthDifference = backgroundDepth - surfaceDepth;

            float3 backgroundColour = tex2D(_WaterBackground, uv).rgb;
            float fogFactor = exp2(-_WaterFogDensity * depthDifference);

            return lerp(_WaterFogColour, backgroundColour, fogFactor);
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            c.a = _Alpha;

            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;

            o.Emission = ColourBelowWater(IN.screenPos) * (1 - c.a);
        }

 		void ResetAlpha (Input IN, SurfaceOutputStandard o, inout fixed4 color) {
			color.a = 1;
		}

        ENDCG
    }
    FallBack "Diffuse"
}
