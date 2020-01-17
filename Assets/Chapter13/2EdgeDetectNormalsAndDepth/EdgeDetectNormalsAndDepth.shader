Shader "Custom/FogWithDepthTexture"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_EdgeOnly("Edge only", Float) = 1.0
		_EdgeColor("Edge COLOR", COLOR) = (1,1,1,1)
		_BackgroundColor("Background COLOR", COLOR) = (1,1,1,1)
		_SampleDistance("Sample Distance", Float) = 1.0
		_Sensitivity("Sensitivity", Vector) = (1,1,1,1)

		//
    }
    SubShader
    {
      CGINCLUDE

		float4x4 _FrustumCornersRay;

		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		fixed _EdgeOnly;
		fixed4 _EdgeColor;
		fixed4 _BackgroundColor;
		float _SampleDistance;
		half4 _Sensitivity;
		sampler2D _CameraDepthNormalsTexture;//深度+法线纹理

		#include "UnityCG.cginc"

		struct v2f{
			float4 pos : SV_POSITION;
			half2 uv[5] : TEXCOORD0;
		};

		v2f vert(appdata_img v){
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);

			half2 uv = v.texcoord;
			o.uv[0] = uv;

			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				uv.y = 1 - uv.y;
			#endif

			//存储了 Roberts算子需要的采样的纹理坐标 减少运算
			o.uv[1] = uv + _MainTex_TexelSize.xy * half2(1,1) * _SampleDistance;
			o.uv[2] = uv + _MainTex_TexelSize.xy * half2(-1,-1) * _SampleDistance;
			o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1,1) * _SampleDistance;
			o.uv[4] = uv + _MainTex_TexelSize.xy * half2(1,-1) * _SampleDistance;

			return o;
		}

		half CheckSame(half4 center,half4 sample){
		//得到两个采样点的法线和深度值（并未解码出真正的法线值，只需要比较两个采样值的差异度
			half2 centerNormal = center.xy;
			float centerDepth = DecodeFloatRG(center.zw);
			half2 sampleNormal = sample.xy;
			float sampleDepth = DecodeFloatRG(sample.zw);

			half2 diffNormal = abs(centerNormal - sampleNormal) * _Sensitivity.x;//_Sensitivity灵敏度

			int isSampleNormal = (diffNormal.x + diffNormal.y) < 0.1;//把差异值每一个分量相加 在和 一个阈值比较。 和小于阈值 认为不明显。佛则认为是个边

			float diffDepth = abs(centerDepth - sampleDepth) * _Sensitivity.y;

			int isSameDepth = diffDepth < 0.1 * centerDepth;


			return isSampleNormal * isSameDepth ? 1.0 : 0.0;
		}

		fixed4 fragRobertsCrossDepthAndNormal(v2f i) :SV_Target{

			half4 sample1 = tex2D(_CameraDepthNormalsTexture,i.uv[1]);
			half4 sample2 = tex2D(_CameraDepthNormalsTexture,i.uv[2]);
			half4 sample3 = tex2D(_CameraDepthNormalsTexture,i.uv[3]);
			half4 sample4 = tex2D(_CameraDepthNormalsTexture,i.uv[4]);//纹理坐标对 深度+法线纹理进行采样

			

			half edge = 1.0;

			//调用checkSame函数计算对角线上两个纹理的差值  返回0表面存在边界
			edge *= CheckSame(sample1,sample2);
			edge *= CheckSame(sample3,sample4);

			fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex,i.uv[0]),edge);
			fixed4 OnlyEdgeColor = lerp(_EdgeColor,_BackgroundColor,edge);

			return lerp(withEdgeColor,OnlyEdgeColor,_EdgeOnly);
		}	

		


	  ENDCG

	  ZTest Always Cull Off ZWrite Off

	  Pass{
		Blend SrcAlpha OneMinusSrcAlpha

		CGPROGRAM

		#pragma vertex vert
		#pragma fragment fragRobertsCrossDepthAndNormal

		ENDCG
	  }
    }
    FallBack Off
}
