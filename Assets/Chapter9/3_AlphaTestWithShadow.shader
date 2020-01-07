// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

//用纹理代替漫反射颜色

Shader "Custom/3_AlphaTestWithShadow"
{
    Properties
    {
		_Color ("Color Tint",COLOR) = (1,1,1,1)
		_MainTex("Main Tex",2D) = "white"{}
		_Cutoff ("Alpha Cutoff",Range(0,1)) = 0.5 //保持和"Transparent/Cutout/VertexLit" 中Cutoff一致才能正确阴影
    }
    SubShader
    {
	//RenderType  指明该shader是一个使用了深度测试的shader；IgnoreProjector 表明该shader不受投影器影响
		Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}

        Pass{
			Tags {"LightMode" = "ForwardBase"}

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed _Cutoff;

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
				SHADOW_COORDS(3)
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
				
				TRANSFER_SHADOW(o);
				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
				
				fixed3 worldNormal = normalize(i.worldNormal);
				//使用unity内置函数改写
				//fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				//计算纹素值
				fixed4 texColor = tex2D(_MainTex,i.uv);


				//AlphaTest
				clip(texColor.a - _Cutoff);

				//equal to
				// if((texColor.a - _Cutoff) < 0.0){
					//discard
				//}

				fixed3 albedo = texColor.rgb * _Color.rgb;

				//环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				//漫反射
				fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(worldNormal,worldLightDir)); 

				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

				return fixed4(ambient + diffuse * atten,1.0);
			}

			ENDCG
		}

    }
    FallBack "Transparent/Cutout/VertexLit"
}
