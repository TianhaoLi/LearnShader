Shader "Custom/0_BrightnessSaturationAndContrast"
{
    Properties
    {
        _MainTex ("Base(RGB)", 2D) = "white" {}
		_Brightness("Brightness",Float) = 1
		_Saturation("Saturation",Float) = 1
		_Contrast("Contrast",Float) = 1
    }
    SubShader
    {
        Pass{
			//关闭深度写入 放置后处理 挡住后面的物体
			ZTest Always Cull Off ZWrite Off

			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"


			sampler2D _MainTex;
			half _Brightness;
			half _Saturation;
			half _Contrast;

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

			fixed4 frag(v2f i): SV_Target{
				fixed4 renderTex = tex2D(_MainTex,i.uv);

				fixed3 finalColor = renderTex.rgb * _Brightness;//调整亮度


				//饱和度( 原颜色乘以亮度系数得到 像素亮度值 luminance)
					///使用该亮度值 创建一个 饱和度为0的颜色值
						//使用_Saturation 来插值饱和度为0到 finalColor；
				fixed luminance = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;
				fixed3 luminanceColor = fixed3(luminance,luminance,luminance);
				finalColor = lerp(luminanceColor,finalColor,_Saturation);

				//对比度（先创建一个对比度为0的颜色值，各分量均为0.5) 再使用_Conrast  用对比度0的 与上一步的颜色插值
				fixed3 avgColor = fixed3(0.5, 0.5, 0.5);
				finalColor = lerp(avgColor,finalColor,_Contrast);

				return fixed4(finalColor,renderTex.a);
			}


			ENDCG
		}
    }
	FallBack Off
}
