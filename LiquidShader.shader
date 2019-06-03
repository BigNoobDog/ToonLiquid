Shader "Unlit/LiquidShader"
{
    Properties
	{
		_MainTex ("Texture", 2D) = "white" {}

		//液体部分
		_Height("h",float)=0.5
		_SectionColor ("Section Color", Color) = (1,1,1,0)
		_WaterColor ("Water Color", Color) = (1,1,1,0)
		_FoamColor("FoamColor", Color) = (1,1,1,0)
		_LiquidHeight("LiquidHeight",float) = 0.1

        _LiquidRimColor ("Liquid Rim Color",Color) = (1,1,1,1)
        _LiquidRimRange ("Liquid Rim Range", float) = 0.1
        _LiquidCameraOffset ("Liquid CameraOffset", Vector) = (0.2, 0,0,0)
        _LiquidRimScale ("Liquid RimScale", float) = 0.2
		//玻璃部分
		_Color("Glass Color",Color) = (0.6,0.6,0.6,1)
        _AlphaRange("Alpha Range",Range(-1,1)) = 0
        _RimColor("Rim Color",Color) = (1,1,1,1)
        _RimRange("Rim Range", float) = 0.1
        _Raduis("Raduis", float) = 0.1
        _CameraOffset("CameraOffset", Vector) = (0.2, 0,0,0)

        _ForceDir("ForceDir", Vector) = (0,0,0,0)
        _WaveHeight("WaveHeight", float) = 1
	}
	SubShader
	{
		
		Pass
		{	
			Tags { "RenderType"="Opaque" }
			LOD 100
			cull off
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
				float3 normal:NORMAL;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
				float3 worldPos:TEXCOORD2;
             	float3 viewDir:TEXCOORD3;
             	float3 worldNormal:TEXCOORD4;
			};

			sampler2D _MainTex;
			float4 _MainTex_ST;

			float _Height;
			float _LiquidHeight;
			float4  _SectionColor;
			float4 _WaterColor;
			float4 _FoamColor;
			float4 _ForceDir;
			float _WaveHeight;
			float4 _LiquidRimColor;
            float _LiquidRimRange;
            float4 _LiquidCameraOffset;
            float _LiquidRimScale;

			float _TargetHeight;

			float GetWaveHeight(float3 worldPos){
				float3 disVector = float3(worldPos.x, _Height, worldPos.z) - float3(0, _Height, 0);
				float dis = length(disVector);
				float d = dot(disVector, _ForceDir.xyz);
				return _Height + dis * d * 0.01 * _WaveHeight;
			}

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o,o.vertex);
				o.worldPos=mul((float3x3)unity_ObjectToWorld,v.vertex);
				o.viewDir=WorldSpaceViewDir(v.vertex);
                o.worldNormal=UnityObjectToWorldNormal(v.normal);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				fixed4 col;
				_TargetHeight = GetWaveHeight(i.worldPos);
				if(i.worldPos.y - _TargetHeight >  0.001)
				{
				  	discard;
				}

				float fd = dot( i.viewDir, i.worldNormal);

				if (fd.x < 0)
                {
                  col = _SectionColor;
                  return col;
                }
                else if(i.worldPos.y > (_TargetHeight - _LiquidHeight)){
					col.rgb = _FoamColor;
					return  col;
                }
                
                float3 normal = normalize(i.worldNormal);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                float NdotV = saturate(dot(normal,viewDir + _LiquidCameraOffset.xyz));
                float alpha = _LiquidRimScale * pow(1 -  NdotV, _LiquidRimRange);
                fixed3 rim = smoothstep(float3(0,0,0), _LiquidRimColor, alpha);// _LiquidRimColor * alpha;  
                col.rgb =_WaterColor + rim;
                UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}
			ENDCG
		}

		Pass
		{	
			Tags{"RenderType"="Transparent" "Queue"="Transparent" }
			LOD 100
			Cull back
            Blend SrcAlpha OneMinusSrcAlpha 
            ZWrite OFF
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float3 normal:NORMAL;
			};

			struct v2f
			{
				float3 normalDir:TEXCOORD0;
				float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
			};

			fixed4 _Color;
            float _AlphaRange;
            fixed4 _RimColor;
            float _RimRange;
            float _Raduis;
            float4 _CameraOffset;

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				float3 vnormal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);
				float2 offset = TransformViewToProjection(vnormal.xy);
				o.vertex.xy += offset * _Raduis;//在视图空间便宜不会出现近大远小
				o.normalDir = normalize(mul((float3x3)unity_ObjectToWorld, v.normal));
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
                float3 normal = normalize(i.normalDir);
                float3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                float NdotV = saturate(dot(normal,viewDir + _CameraOffset.xyz));//视线方向做了偏移，调整fresnel效果，使效果更风格化
                fixed3 diffuse = NdotV *_Color;
                float alpha =  pow(1 -  NdotV, _RimRange);
                fixed3 rim =  _RimColor * alpha;//smoothstep(float3(0,0,0), _RimColor, alpha);  
                return fixed4(diffuse + rim ,alpha * _AlphaRange);
			}
			ENDCG
		}
	}
}
