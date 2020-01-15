Shader "Custom/1_EdgeDetection"
{
    Properties
    {
        _MainTex ("Base(RGB)", 2D) = "white" {}
		_EdgesOnly("EdgesOnly",Float) = 1.0
		_EdgeColor("EdgeColor",COLOR) = (0,0,0,1)
		_BackgroundColor("BackgroundColor",COLOR) = (1,1,1,1)
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
			half4 _MainTex_TexelSize;//计算相邻区域的纹理坐标
			fixed _EdgesOnly;
			fixed4 _EdgeColor;
			fixed4 _BackgroundColor;

			struct v2f{
				float4 pos : SV_POSITION;
				half2 uv[9] : TEXCOORD0;
			};

			v2f vert(appdata_img v){
				v2f o;
				
				o.pos = UnityObjectToClipPos(v.vertex);

				half2 uv = v.texcoord;

				//Sobel算子采样 9个领域的纹理坐标
				o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1, -1);
				o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0, -1);
				o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1, -1);
				o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 0);
				o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0, 0);
				o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1, 0);
				o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1, 1);
				o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0, 1);
				o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1, 1);


				return o;
			}

			fixed luminance(fixed4 color){//计算亮度值
				return 0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
			}

			half Sobel(v2f i){

				//卷积核Gx
				const half Gx[9] = {-1,-2,-1,
									0, 0, 0,
									1, 2, 1};

				////卷积核Gy
				const half Gy[9] = {-1, 0, 1,
									-2, 0, 2,
									-1, 0, 1};

				half texColor;
				half edgeX = 0;
				half edgeY = 0;
				for (int it = 0; it < 9; it++){
					texColor = luminance(tex2D(_MainTex,i.uv[it]));//对9个像素采样得到亮度值； 再与卷积核对应的权重相乘 叠加到各自的梯度上
					edgeX += texColor * Gx[it];
					edgeY += texColor * Gy[it];
				}

				half edge = 1 - abs(edgeX) - abs(edgeY);// 1 - 水平方向 - 垂直方向 梯度值的绝对值 得到edge  || edge越小就是边缘

				return edge;
			}

			fixed4 frag(v2f i): SV_Target{
				
				half edge = Sobel(i); //使用sobel函数计算edge 利用该值计算背景为原图和纯色下的颜色值。利用_EdgeOnly 插值得到最终

				fixed4 withEdgeColor = lerp(_EdgeColor,tex2D(_MainTex,i.uv[4]), edge);//根绝edge 越小 越接近边缘颜色。越大越接近 原图颜色
				fixed4 onlyEdgeColor = lerp(_EdgeColor,_BackgroundColor,edge);//越小越接近 边缘，否则接近背景色纯色

				return lerp(withEdgeColor,onlyEdgeColor,_EdgesOnly);//根绝_EdgeOnly决定是显示边缘 还是显示纯色(即边缘叠加在原图 还是只显示纯色)
			}


			ENDCG
		}
    }
	FallBack Off
}
