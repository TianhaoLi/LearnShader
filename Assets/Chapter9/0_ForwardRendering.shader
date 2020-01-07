
Shader "Custom/0_ForwardRendering"
{
    Properties
    {
		_Diffuse ("DIFFUSE",COLOR) = (1, 1, 1, 1)
		_Specular("Specular",COLOR) = (1, 1, 1, 1)
		_Gloss("Gloss",Range(8.0,256)) = 20
    }
    SubShader
    {
		Tags { "RenderType"="Opaque" }
	//Base Pass
        Pass{
			Tags {"LightMode" = "ForwardBase"}

			CGPROGRAM
			//光照衰减
			#pragma multi_compile_fwdbase
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

				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target{

				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

				//环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				//漫反射
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLightDir));

				//视角方向  : 世界空间的摄像机位置  - 世界坐标系下的顶点位置(把模型空间的顶点位置变换到世界坐标系) 用世界坐标系右乘
				//使用unity内置函数改写
				//fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

				//blinnPhong
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				//Cspecular = C(Clight · Mspecular) Max(0,v · r)^mgloss
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal,halfDir)),_Gloss);

				//衰减值
				fixed atten = 1.0;

				return fixed4(ambient + (diffuse + specular)* atten,1.0);
			}

			ENDCG
		}

		Pass{
			Tags {"LightMode" = "ForwardAdd"}


			//叠加之前的颜色缓冲区而非覆盖
			Blend One One
			
			CGPROGRAM

			//保证 在addtional pass中访问到正确的光照变量
			#pragma multi_compile_fwdadd

			//剩下的基本和第一个pass一样，但是去掉了环境光 自发光 逐顶点光照 SH光照。并添加对其他光源的支持
			#pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

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

				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
				
				#ifdef USING_DIRECTIONAL_LIGHT
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);//平行光
				#else
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);//点光源聚光灯。（世界空间光源位置-世界空间下的位置)
				#endif

				fixed3 worldNormal = normalize(i.worldNormal);

				//漫反射
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLightDir)); 

				//视角方向  : 世界空间的摄像机位置  - 世界坐标系下的顶点位置(把模型空间的顶点位置变换到世界坐标系) 用世界坐标系右乘
				//使用unity内置函数改写
				//fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

				//blinnPhong
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				//Cspecular = C(Clight · Mspecular) Max(0,v · r)^mgloss
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal,halfDir)),_Gloss);



				//处理衰减值
				#ifdef USING_DIRECTIONAL_LIGHT
					fixed3 atten = 1.0;
				#else
					fixed3 lightCoord = mul(unity_WorldToLight,float4(i.worldPos,1)).xyz;//用纹理作为查找表 得到光源的衰减
					fixed atten = tex2D(_LightTexture0,dot(lightCoord,lightCoord).rr).UNITY_ATTEN_CHANNEL;
				#endif

				return fixed4((diffuse + specular)* atten,1.0);
			}

			ENDCG
		}

    }
    FallBack "Specular"
}
