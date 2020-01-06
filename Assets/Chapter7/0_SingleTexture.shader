// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

//用纹理代替漫反射颜色

Shader "Custom/0_SingleTexture"
{
    Properties
    {
		_Color ("Color Tint",COLOR) = (1,1,1,1)
		_MainTex("Main Tex",2D) = "white"{}
		_Specular("Specular",COLOR) = (1, 1, 1, 1)
		_Gloss("Gloss",Range(8.0,256)) = 20
    }
    SubShader
    {
        Pass{
			Tags {"LightMode" = "ForwardBase"}

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Specular;
			float _Gloss;

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

				o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				//o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
				

				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
				
				fixed3 worldNormal = normalize(i.worldNormal);
				//使用unity内置函数改写
				//fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				//计算纹素值
				fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;

				//环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				//漫反射
				fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(worldNormal,worldLightDir)); 

				//视角方向  : 世界空间的摄像机位置  - 世界坐标系下的顶点位置(把模型空间的顶点位置变换到世界坐标系) 用世界坐标系右乘
				//使用unity内置函数改写
				//fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

				//blinnPhong
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				//Cspecular = C(Clight · Mspecular) Max(0,v · r)^mgloss
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal,halfDir)),_Gloss);

				return fixed4(ambient + diffuse + specular,1.0);
			}

			ENDCG
		}

    }
    FallBack "Specular"
}
