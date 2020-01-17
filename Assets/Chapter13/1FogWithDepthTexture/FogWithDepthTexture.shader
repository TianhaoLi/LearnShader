Shader "Custom/FogWithDepthTexture"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_FogDensity("Fog Density", Float) = 1.0
		_FogColor("Fog COLOR", COLOR) = (1,1,1,1)
		_FogStart("Fog Start", Float) = 1.0
		_FogEnd("Fog End", Float) = 1.0

		//
    }
    SubShader
    {
      CGINCLUDE

		float4x4 _FrustumCornersRay;

		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		sampler2D _CameraDepthTexture;//unity传递的深度纹理
		half _FogDensity;
		fixed4 _FogColor;
		float _FogStart;
		float _FogEnd;

		#include "UnityCG.cginc"

		struct v2f{
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			half2 uv_depth : TEXCOORD1;
			float4 interpolatedRay : TEXCOORD2;//插值后的像素向量
		};

		v2f vert(appdata_img v){
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);

			o.uv = v.texcoord;
			o.uv_depth = v.texcoord;

			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				o.uv_depth.y = 1 - o.uv_depth.y;
			#endif

			int index = 0; //顶点索引 划分到四个区域
			if(v.texcoord.x < 0.5 && v.texcoord.y < 0.5){
				index = 0;
			}else if(v.texcoord.x > 0.5 && v.texcoord.y < 0.5){
				index = 1;
			}else if(v.texcoord.x > 0.5 && v.texcoord.y > 0.5){
				index = 2;
			}else {
				index = 3;
			}

			//不同平台的差异
			#if UNITY_UV_STARTS_AT_TOP
			if(_MainTex_TexelSize.y < 0)
				index  = 3 -index;
			#endif

			o.interpolatedRay = _FrustumCornersRay[index];

			return o;
		}

		fixed4 frag(v2f i) :SV_Target{

		
		//深度纹理采样 得到视角空间下的线性插值
			float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));
		//得到世界坐标下真实的位置
			float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;


			float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart);//雾效系数 f
			fogDensity = saturate(fogDensity * _FogDensity);// 截取到【0,1】范围

			fixed4 finalColor = tex2D(_MainTex, i.uv);
			finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb, fogDensity);//混合 雾的颜色

			return finalColor;
		}	


	  ENDCG

	  ZTest Always Cull Off ZWrite Off

	  Pass{
		Blend SrcAlpha OneMinusSrcAlpha

		CGPROGRAM

		#pragma vertex vert
		#pragma fragment frag

		ENDCG
	  }
    }
    FallBack Off
}
