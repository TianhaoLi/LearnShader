Shader "Unlit/0_ImageSequenceAnimation"
{
    Properties
    {
		_Color("Color Tint",Color) = (1, 1, 1, 1)
        _MainTex ("Texture", 2D) = "white" {}
		_HorizontalAmount("Horizontal Amount",Float) = 4//水平垂直序列帧个数
		_VerticalAmount("Vertical Amount",Float) = 4
		_Speed("Speed",Range(1,100)) = 30
    }
    SubShader
    {
        Tags { "Opaque"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }

        Pass
        {
			Tags{"LightMode"="ForwardBase"}

			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

			fixed4 _Color;
		    sampler2D _MainTex;
            float4 _MainTex_ST;
			float _HorizontalAmount;
			float _VerticalAmount;
			float _Speed;

            struct a2v
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
			    float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };



            v2f vert (a2v v)
            {
			//基本顶点变换
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				//计算行列数(关键帧在文理的位置)
				float time = floor(_Time.y * _Speed);//_Time.y 场景加载后经过的时间   *速度得到模拟时间
				float row = floor(time / _HorizontalAmount); //商是行索引。余数是列索引
				float colum = time - row * _HorizontalAmount;

				//构建真正的采样范围。 即平分关键帧的坐标范围。 先把i.uv按行列等分，然后基于每个图像偏移。
					//警告:对数值方向偏移使用减法 ，因为unity竖方向从下到上增大和帧纹理相反

				//half2 uv = float2(i.uv.x / _HorizontalAmount, i.uv.y / _VerticalAmount);
				//uv.x += column / _HorizontalAmount;
				//uv.y -= row / _VerticalAmount;
				//优化后

				half2 uv = i.uv + half2(colum,-row);
				uv.x /= _HorizontalAmount;
				uv.y /= _VerticalAmount;

				fixed4 c = tex2D(_MainTex,uv);
				c.rgb *= _Color;

				return c;
            }
            ENDCG
        }
		
    }
	FallBack "Transparent/VertexLit"
}
