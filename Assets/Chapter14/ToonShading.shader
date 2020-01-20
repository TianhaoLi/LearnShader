// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unlit/ToonShading"
{
    Properties
    {
        _Color ("Color Tint",Color) = (1, 1, 1, 1)
		_MainTex("Main Tex 2D",2D) = "white" {}
		_Ramp ("Ramp Texture",2D) = "white" {}//漫反射渐变纹理
		_OutLine("OutLine",Range(0,1)) = 0.1//控制轮廓线
		_OutLineColor("OutLineColor",Color) = (0, 0, 0, 1)//轮廓线颜色
		_Specular("SPECULAR",Color) = (1, 1, 1, 1)//高光反射颜色
		_SpecularScale("Specular Scale", Range(0, 0.1)) = 0.01//控制高光反射的阈值

    }
    SubShader
    {
        
		Tags { "RenderType" = "Opaque"  "Queue"="Geometry"}

		//pass1 只渲染背面的三角面片
        Pass{
			NAME "OUTLINE"

			Cull Front  //剔除正面三角面

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			float _OutLine;
			fixed4 _OutLineColor;

			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};

			struct v2f{
				float4 pos : SV_POSITION;
			};

			v2f vert(a2v v){
				v2f o;

				//顶点和法线变换到视角空间下
				float4 pos = mul(UNITY_MATRIX_MV,v.vertex);
				float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);

				normal.z = - 0.5;//归一化后向顶点沿伸 扩展。避免背面扩张后顶点挡住正面面片
				pos = pos + float4(normalize(normal), 0) * _OutLine;
				o.pos = mul(UNITY_MATRIX_P,pos); //顶点从视角空间到 剪裁空间

				return o;
			}

			float4 frag(v2f i):SV_Target{
				return float4(_OutLineColor.rgb, 1);
			}


			ENDCG
		}

		Pass{
			Tags{ "LightMode" = "ForwardBase"}

			Cull Back

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_fwdbase

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "UnityShaderVariables.cginc"

			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _Ramp;
			fixed4 _Specular;
			fixed _SpecularScale;
		
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
				float4 tangent : TANGENT;
			}; 

				struct v2f{
					float4 pos : POSITION;
					float2 uv : TEXCOORD0;
					float3 worldNormal :TEXCOORD1;
					float3 worldPos :TEXCOORD2;
					SHADOW_COORDS(3)
				};

				v2f vert(a2v v){
					v2f o;

					o.pos = UnityObjectToClipPos(v.vertex);
					o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
					o.worldNormal = mul(v.normal,(float3x3)unity_WorldToObject);//世界空间法线方向
					o.worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;//世界空间顶点位置

					TRANSFER_SHADOW(o);

					return o;
				}


				float4 frag(v2f i): SV_TARGET{
					fixed3 worldNormal = normalize(i.worldNormal);
					fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
					fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
					fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);

					fixed4 c = tex2D(_MainTex, i.uv);
					fixed3 albedo = c.rgb * _Color.rgb;//材质反射率 

					fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;//环境光

					UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);//计算当前坐标系下的阴影值；

					fixed diff = dot(worldNormal, worldLightDir);//半兰伯特模型 反射系数
					diff = (diff * 0.5 + 0.5) * atten;//和阴影相乘 得到最终的漫反射系数


					fixed3 diffuse = _LightColor0.rgb * albedo * tex2D(_Ramp,float2(diff,diff)).rgb;

					fixed spec = dot(worldNormal,worldHalfDir);
					fixed w = fwidth(spec) * 2.0;//fwidth  高光边缘抗锯齿
					fixed3 specular = _Specular.rgb * lerp(0,1, smoothstep(-w,w,spec+_SpecularScale -1)) * step(0.0001, _SpecularScale);//0.0001是为了 _Specular.rgb = 0时完全消除高光

					return fixed4(ambient + diffuse + specular, 1.0);


				}

			ENDCG
		}
    }
	FallBack "Diffuse"
}
