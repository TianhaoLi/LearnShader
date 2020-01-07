// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

//用纹理代替漫反射颜色

Shader "Custom/2_AlphaBlendZwrite"
{
    Properties
    {
		_Color ("Color Tint",COLOR) = (1,1,1,1)
		_MainTex("Main Tex",2D) = "white"{}
		_AlphaScale ("Alpha Scale",Range(0,1)) = 1
    }
    SubShader
    {
	//RenderType  指明该shader是一个使用了深度测试的shader；IgnoreProjector 表明该shader不受投影器影响
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}

		Pass{
			ZWrite On
			ColorMask 0
		}

        Pass{
			Tags {"LightMode" = "ForwardBase"}

			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			//SrcAlpha  源；   OneMinusSrcAlpha  半透明目标


			/*混合效果
			//正常透明度混合
			Blend SrcAlpha OneMinusSrcAlpha
				
			//柔和相加
			Blend OneMinusDstColor One

			//正片叠底
			Blend DstColor Zero

			//两倍相乘
			Blend DstColor SrcColor

			//变暗
			BlendOp Min
			Blend One One

			//变亮
			BlendOP Max
			Blend One One

			//滤色
			Blend OneMinusDstColor
			//等同于
			Blend One OneMinusSrcColor

			//线性减淡
			Blend One One
			*/

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _AlphaScale;

			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;//为了访问顶点的法线。并且把顶点的法线信息存入normal
				float4 texcoord : TEXCOORD0;
			};

			struct v2f{
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;//法线
				float3 worldPos : TEXCOORD1;//顶点坐标
				float2 uv : TEXCOORD2;
			};

			//逐顶点光照

			v2f vert(a2v v){
				v2f o;
				//顶点着色器 
				o.pos = UnityObjectToClipPos(v.vertex);
				

				//使用unity内置函数改写
				//o.worldNormal = mul(v.normal,(float3x3)unity_WorldToObject);
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;

				//o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
				

				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
				
				fixed3 worldNormal = normalize(i.worldNormal);
				//使用unity内置函数改写
				//fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				//计算纹素值
				fixed4 texColor = tex2D(_MainTex,i.uv);

				fixed3 albedo = texColor.rgb * _Color.rgb;

				//环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				//漫反射
				fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(worldNormal,worldLightDir)); 

				return fixed4(ambient + diffuse,texColor.a * _AlphaScale);
			}

			ENDCG
		}

    }
    FallBack "Transparent/VertexLit"
}
