// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'


Shader "Custom/4_Mask Texture"
{
    Properties
    {
		_Color ("Color Tint",COLOR) = (1,1,1,1)
		_MainTex("Main Tex",2D) = "white"{}
		_BumpMap ("Normal Map",2D) = "Bump"{}
		_BumpScale("Bump Scale",Float) = 1.0
		_SpecularMask("Specular Mask",2D) = "white"{}
		_SpecularScale("Specular Scale",Float) = 1.0
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
			sampler2D _MainTex;//主纹理
			float4 _MainTex_ST;//主纹理属性变量
			sampler2D _BumpMap;//法线纹理
			float _BumpScale;
			sampler2D _SpecularMask;//遮罩纹理
			float _SpecularScale;
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
				float2 uv : TEXCOORD0;//uv
				float3 lightDir : TEXCOORD1;
				float3 viewDir : TEXCOORD2;
			};

			//逐顶点光照

			v2f vert(a2v v) {
				
				v2f o;
				//顶点着色器 
				o.pos = UnityObjectToClipPos(v.vertex);

				o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
				
				TANGENT_SPACE_ROTATION;

				o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;
				o.viewDir = mul(rotation,ObjSpaceViewDir(v.vertex)).xyz;

				return o;
			}

			fixed4 frag(v2f i) : SV_Target{

				fixed3 tangentLightDir = normalize(i.lightDir);
				fixed3 tangentViewDir = normalize(i.viewDir);

				fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap,i.uv));
				tangentNormal.xy *= _BumpScale;
				tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy,tangentNormal.xy)));

				fixed3 albedo = tex2D(_MainTex,i.uv).rgb * _Color.rgb;

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT * albedo;

				fixed3 diffuse = _LightColor0.rgb * albedo * saturate(dot(tangentNormal,tangentLightDir));

				fixed3 halfDir = normalize(tangentLightDir + tangentViewDir);

				fixed specularMask = tex2D(_SpecularMask,i.uv).r * _SpecularScale;

				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(tangentNormal,halfDir)),_Gloss) * specularMask;

				return fixed4(ambient + diffuse + specular, 1.0);
			}

			ENDCG
		}

    }
    FallBack "Specular"
}
