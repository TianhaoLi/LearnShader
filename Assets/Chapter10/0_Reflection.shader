Shader "Custom/0_Reflection"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
		_ReflectColor ("Reflection Color", Color) = (1,1,1,1)
        _ReflectAmount ("ReflectAmount", Range(0,1)) = 1
        _CubeMap ("Reflection CubeMap", Cube) = "_SkyBox"{}
    }
    SubShader
    {
	   Tags { "RenderType"="Opaque" "Queue"="Geometry"}

       Pass{
	   
	   Tags { "LightMode"="ForwardBase" }

		CGPROGRAM

		#pragma multi_compile_fwdbase

		#pragma vertex vert
		#pragma fragment frag

		#include "Lighting.cginc"
		#include "AutoLight.cginc"

		fixed4 _Color;
		fixed4 _ReflectColor;
		fixed _ReflectAmount;
		samplerCUBE _CubeMap;

		struct a2v {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
		};

		struct v2f{
			float4 pos : SV_POSITION;
			float3 worldPos: TEXCOORD0;
			fixed3 worldNormal: TEXCOORD1;
			fixed3 worldViewDir: TEXCOORD2;
			fixed3 worldRefl: TEXCOORD3;
			SHADOW_COORDS(4)
		};

		v2f vert(a2v v){

			v2f o;

			o.pos = UnityObjectToClipPos(v.vertex);

			o.worldNormal = UnityObjectToWorldNormal(v.normal);

			o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;

			o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);

			//计算 世界空间下反射的方向
			o.worldRefl = reflect(-o.worldViewDir,o.worldNormal);

			TRANSFER_SHADOW(o);

			return o;
		}

		fixed4 frag(v2f i):SV_Target{
			fixed3 worldNormal = normalize(i.worldNormal);
			fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
			fixed3 worldVirwDir = normalize(i.worldViewDir);

			//环境光
			fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
			//漫反射
			fixed3 diffuse = _LightColor0.rgb * _Color.rgb * saturate(dot(worldNormal,worldLightDir));
			//反射(对立方体纹理采样)
			fixed3 refection = texCUBE(_CubeMap,i.worldRefl).rgb * _ReflectColor.rgb;

			//光照衰减
			UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);

			//在unity3D中经常用线性插值函数Lerp()来在两者之间插值，两者之间可以是两个材质之间、两个向量之间、两个浮点数之间、两个颜色之间
			fixed3 color = ambient + lerp(diffuse,refection,_ReflectAmount) * atten;

			return fixed4(color,1.0);
		}

		ENDCG
	   }
    }
    FallBack "Reflective/VertexLit"
}
