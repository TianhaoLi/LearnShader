// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'


Shader "Custom/2_NormalMapWorldSpace"
{
    Properties
    {
		_Color ("Color Tint",COLOR) = (1,1,1,1)
		_MainTex("Main Tex",2D) = "white"{}
		_BumpMap ("Normal Map",2D) = "Bump"{}
		_BumpScale("Bump Scale",Float) = 1.0
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
			sampler2D _BumpMap;
			float4 _BumpMap_ST;

			float _BumpScale;
			fixed4 _Specular;
			float _Gloss;

			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;//为了访问顶点的法线。并且把顶点的法线信息存入normal
				float4 tangent : TANGENT;//切线方向填充到tangent   (tangent.w来存储副切线)
				float4 texcoord : TEXCOORD0;
			};

			struct v2f{
				float4 pos : SV_POSITION;
				float4 uv : TEXCOORD0;//uv
				float4 TtoW0 : TEXCOORD1;//一个插值寄存器最多存一个float4 所以矩阵拆成多个变量
				float4 TtoW1 : TEXCOORD2;//虽然我们只需要3*3矩阵对方向矢量变换。但是我们可以把世界空间下的顶点位置存在w分量里
				float4 TtoW2 : TEXCOORD3;
			};

			//逐顶点光照

			v2f vert(a2v v){
				v2f o;
				//顶点着色器 
				o.pos = UnityObjectToClipPos(v.vertex);

				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
				
				float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent =UnityObjectToWorldDir(v.tangent.xyz);
				//副切线(副法线)  = 通过法线和切线 的叉积得到
				fixed3 worldBinormal = cross(worldNormal,worldTangent);

				//按列摆放得到从切线空间到世界空间的变换矩阵。每一行分别存储
				o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
				o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
				o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target{

				float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);

				//得到世界空间下 光照和 视角方向
				fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
				fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

				
				fixed3 bump = UnpackNormal(tex2D(_BumpMap,i.uv.zw));//采样和解码
				bump.xy *= _BumpScale;//缩放
				bump.z = sqrt(1.0 - saturate(dot(bump.xy,bump.xy)));//单位矢量 法线z可以通过xy得到

				//通过点乘 每一行和法线相乘  把法线变换到世界空间下
				bump = normalize(half3(dot(i.TtoW0.xyz,bump), dot(i.TtoW1.xyz,bump), dot(i.TtoW2.xyz,bump)));

				//计算纹素值
				fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;

				//环境光
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
				//漫反射
				fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(bump,lightDir)); 

				//blinnPhong
				fixed3 halfDir = normalize(lightDir + viewDir);
				//Cspecular = C(Clight · Mspecular) Max(0,v · r)^mgloss
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(bump,halfDir)),_Gloss);

				return fixed4(ambient + diffuse + specular,1.0);
			}

			ENDCG
		}

    }
    FallBack "Specular"
}
