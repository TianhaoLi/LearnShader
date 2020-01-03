// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/4_SpcularPixelLevel"
{
    Properties
    {
		_Diffuse ("DIFFUSE",COLOR) = (1, 1, 1, 1)
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

			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;

			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;//为了访问顶点的法线。并且把顶点的法线信息存入normal
			};

			struct v2f{
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;//法线
				float3 worldPos : TEXCOORD1;//顶点坐标
			};

			//逐顶点光照

			v2f vert(a2v v){
				v2f o;
				//顶点着色器 
				o.pos = UnityObjectToClipPos(v.vertex);
				o.worldNormal = mul(v.normal,(float3x3)unity_WorldToObject);
				o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;

				

				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
				
				//环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

				//漫反射
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLightDir)); 

				//反射方向  refelct(i,n)
				fixed3 reflectDir = normalize(reflect(-worldLightDir,worldNormal));

				//视角方向  : 世界空间的摄像机位置  - 世界坐标系下的顶点位置(把模型空间的顶点位置变换到世界坐标系) 用世界坐标系右乘
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);

				//Cspecular = C(Clight · Mspecular) Max(0,v · r)^mgloss
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir,viewDir)),_Gloss);

				return fixed4(ambient + diffuse + specular,1.0);
			}

			ENDCG
		}

    }
    FallBack "Specular"
}
