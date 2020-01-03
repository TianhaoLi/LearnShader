

Shader "Custom/Chapter5-SimpleShader"
{
	Properties{
		_Color ("Color Tnit",Color) = (1.0, 1.0, 1.0, 1.0)
	}

    SubShader
    {
       Pass{
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag

		fixed4 _Color;

		//使用一个结构体来定义顶点着色器的输入
		struct a2v
		{
			//POSITION 语义告诉unity  用模型空间的顶点坐标填充vertex变量
			float4 vertex : POSITION;
			//NORMAL 语义告诉unity 用模型空间的法线填充normal变量
			float3 normal : NORMAL;
			//TEXCOORD0 语义告诉unity 用模型的第一套纹理 填充texcoord变量
			float4 texcoord : TEXCOORD0;
		};

		//使用一个结构体定义顶点着色器的输出
		struct v2f
		{
			//SV_POSITION语义告诉unity pos 里面包含了顶点在裁切空间的位置信息
			float4 pos : SV_POSITION;
			//COLOR0 语义可以存储颜色信息
			fixed3 color : COLOR0;
		};

		v2f vert(a2v v)
		{
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);
			o.color = v.normal * 0.5 + fixed3(0.5, 0.5, 0.5);
			return o;
        }

		fixed4 frag(v2f i) : SV_Target
		{

			//return fixed4(i.color,1.0);

			fixed3 c = i.color;
			c *= _Color.rgb;
			return fixed4(c,1.0);
		}

        ENDCG
		}
	}
}
