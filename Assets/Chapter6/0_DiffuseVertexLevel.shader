// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Custom/Chapter6_DiffuseVertexLevel"
{
    Properties
    {
		_Diffuse ("DIFFUSE",COLOR) = (1, 1, 1, 1)
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

			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;//为了访问顶点的法线。并且把顶点的法线信息存入normal
			};

			struct v2f{
				float4 pos : SV_POSITION;
				fixed3 color : COLOR;//为了把顶点计算出的光照颜色传给fragment
			};

			//逐顶点光照

			v2f vert(a2v v){
				v2f o;
				//顶点着色器最主要的就是把模型空间转换到裁切空间
				o.pos = UnityObjectToClipPos(v.vertex);

				//得到环境光部分
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				/*  1.材质的漫反射颜色 _Diffuse 
					2.顶点的法线 v.normal
					3.光源的颜色
					4.光源的方向
				*/

				fixed3 worldNormal = normalize(mul(v.normal,(float3x3)unity_WorldToObject));
				//get the light direction in worldspace
				fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
				//_LightColor0 来访问该pass处理的光源的颜色和强度信息  _WorldSpaceLightPos0 获得光源方向(场景有多个光源则此函数不正确)
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLight));

				o.color = ambient + diffuse;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target{
				return fixed4(i.color, 1.0);
			}

			ENDCG
		}

    }
    FallBack "Diffuse"
}
