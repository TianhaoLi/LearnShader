Shader "Unlit/1_ScrollingBackground"
{
    Properties
    {
        _MainTex ("Base Layer(RGB)", 2D) = "white" {}
		_DetailTex ("2nd Layer(RGB)", 2D) = "white" {}
		_ScrollX("Base layer Scroll Speed",Float) = 1.0
		_Scroll2X("2nd layer Scroll Speed",Float) = 1.0
		_Multiplier("Layer Mutiplier",Float) = 1 //控制整体亮度
    }
    SubShader
    {

        Pass
        {
			Tags{"LightMode"="ForwardBase"}

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

		    sampler2D _MainTex;
            float4 _MainTex_ST;
		    sampler2D _DetailTex;
            float4 _DetailTex_ST;
			float _Scroll2X;
			float _ScrollX;
			float _Multiplier;

            struct a2v
            {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
            };

            struct v2f
            {
			    float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0;
            };



            v2f vert (a2v v)
            {
			//基本顶点变换
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
				//计算两层的背景纹理坐标。   利用time.y在水平方向进行偏移(frac返回小数部分)
                o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex) + frac(float2(_ScrollX,0.0) * _Time.y);
				o.uv.zw = TRANSFORM_TEX(v.texcoord,_DetailTex) + frac(float2(_Scroll2X,0.0) * _Time.y);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				fixed4 firstLayer = tex2D(_MainTex,i.uv.xy);
				fixed4 secondLyaer = tex2D(_DetailTex,i.uv.zw);

				//fixed4 c = lerp(firstLayer,secondLyaer,secondLyaer.a);
				fixed4 c = lerp(firstLayer,secondLyaer,secondLyaer.a);
				//按照secondLayer.a 差值 firstLayer 到 scondLayer
				c.rgb *= _Multiplier; //控制亮度
				return c;
            }
            ENDCG
        }
		
    }
	FallBack "VertexLit"
}
