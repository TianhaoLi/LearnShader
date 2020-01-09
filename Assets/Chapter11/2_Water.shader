Shader "Unlit/2_Water"
{
    Properties
    {
        _MainTex ("Base Layer(RGB)", 2D) = "white" {}
		_Color("Color Tint",COLOR) = (1,1,1,1) //控制整体颜色
		_Magnitude("Distortion Magenitude",Float) = 1.0 //控制水流波动幅度
		_Frequency("Distortion Frequency",Float) = 1.0//控制波动频率
		_InvWaveLength("Distortion Inverse Wave Length",Float) = 10//控制波长的倒数
		_Speed("Speed",Float) = 0.5 //控制整体亮度
    }
    SubShader
    {
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
		//"DisableBatching  批处理合并相关模型，模型各自的空间会丢失 所以取消批处理操作

        Pass
        {
			Tags{"LightMode"="ForwardBase"}

			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off//关闭裁切 让水流每个面都能显示

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

		    sampler2D _MainTex;
            float4 _MainTex_ST;
			float4 _Color;
			float _Magnitude;
			float _Frequency;
			float _InvWaveLength;
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

				float4 offset;
				offset.yzw = float3(0.0,0.0,0.0);
				offset.x = sin(_Frequency * _Time.y + v.vertex.x * _InvWaveLength + v.vertex.y * _InvWaveLength + v.vertex.z * _InvWaveLength)
				* _Magnitude;//只希望对顶点的X方向唯一。yzw 被设置为0 .利用——Frequency来控制正弦函数频率。为了每个位置有不同的位移，分别加上了模型空间的顶点位置分量
				// 最后结果 * _Magnitude 来控制幅度


                o.pos = UnityObjectToClipPos(v.vertex + offset);//位移量添加到顶点

                o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
				o.uv += float2(0.0, _Time.y * _Speed);//纹理动画控制水平方向纹理动画
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				fixed4 c =tex2D(_MainTex,i.uv);
				c.rgb *= _Color.rgb;
				return c;
            }
            ENDCG
        }
		
    }
	FallBack "Transparent/VertexLit"
}
