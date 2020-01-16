Shader "Custom/4_MotionBlurShader"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_BlurAmount("Blur Amount",FLOAT) = 1.0
    }
    SubShader
    {
      CGINCLUDE
		sampler2D _MainTex;
		fixed _BlurAmount;

		#include "UnityCG.cginc"

		struct v2f{
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
		};

		v2f vert(appdata_img v){
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);

			o.uv = v.texcoord;

			return o;
		}

		fixed4 fragRGB(v2f i) :SV_Target{//对当前通道采样 A通道 改为BlurAmount 方便后面的混合
			return fixed4(tex2D(_MainTex, i.uv).rgb, _BlurAmount);
		}	

		half4 fragA (v2f i): SV_Target{
			return tex2D(_MainTex, i.uv);
			//直接返回采样结果
		}

	  ENDCG

	  ZTest Always Cull Off ZWrite Off

	  Pass{
		Blend SrcAlpha OneMinusSrcAlpha

		ColorMask RGB

		CGPROGRAM

		#pragma vertex vert
		#pragma fragment fragRGB

		ENDCG
	  }

	  Pass{
		Blend One Zero
		ColorMask A

		CGPROGRAM

		#pragma vertex vert
		#pragma fragment fragA

		ENDCG
	  }
    }
    FallBack Off
}
