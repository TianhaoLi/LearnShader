Shader "Custom/MotionBlurWithDepthTexture"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_BlurSize("Blur Size",FLOAT) = 1.0//模糊图像使用的参数

		//
    }
    SubShader
    {
      CGINCLUDE
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		sampler2D _CameraDepthTexture;//unity传递的深度纹理
		float4x4 _CurrentViewProjectionInverseMatrix;//脚本传递的矩阵
		float4x4 _PreViousViewProjectionMatrix;//脚本传递的矩阵
		half _BlurSize;

		#include "UnityCG.cginc"

		struct v2f{
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			half2 uv_depth : TEXCOORD1;
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

			return o;
		}

		fixed4 frag(v2f i) :SV_Target{
		
		//利用深度纹理 和当前帧的 视角*投影矩阵的逆矩阵 球世界空间下坐标
			float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);//SAMPLE_DEPTH_TEXTURE 和 纹理坐标 对深度纹理进行采样 得到d深度值

			float4 H = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, d * 2 - 1, 1);//映射回NDC 原映射的反函数

			float4 D = mul(_CurrentViewProjectionInverseMatrix	, H);//使用 当前帧视角*投影矩阵的逆矩阵 结果除以w分量得到世界空间下的坐标wordpos

			float4 worldPos = D / D.w;

		//得到像素速度
			//使用前一帧视角*投影矩阵对它进行变换得到前一帧在NDC的previousPOS.然后计算 当前帧和前一帧位置差算速度
			float4 currentPos = H;
			float4 previousPos = mul(_PreViousViewProjectionMatrix, worldPos);
			previousPos /= previousPos.w;

			float2 velocity = (currentPos.xy - previousPos.xy) / 2.0f;

		//得到速度后 使用该速度进行领域采样  相加后平均得到模糊。
			float2 uv = i.uv;
			float4 c = tex2D(_MainTex, uv);
			uv += velocity * _BlurSize;
			for(int it = 1; it < 3; it++, uv += velocity * _BlurSize){
				float4 currentColor = tex2D(_MainTex, uv);
				c += currentColor;
			}

			c /= 3;

			return fixed4(c.rgb, 1.0);
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
