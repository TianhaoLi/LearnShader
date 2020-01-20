// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/Dissolve"
{
    Properties
    {
        _BurnAmount ("Burn Amount",Range(0.0, 1.0)) = 0.0//消融程度
		_LineWidth("Burn Line Width", Range(0.0, 0.2)) = 0.1//烧焦得线宽
		_MainTex("Base RGB",2D) = "white"{}//漫反射纹理
		_BumpMap("Normal map",2D) = "bump"{}//法线纹理
		_BurnFirstColor("Burn First Color",COLOR) = (1, 0, 0, 1)//火焰
		_BurnSecondColor("Burn Second Color",COLOR) = (1, 0, 0, 1)//火焰边缘颜色
		_BurnMap("Burn map",2D)  = "white"{}//噪声纹理
    }
    SubShader
    {
		Tags { "RenderType"="Opaque" "Queue"="Geometry"}       

        Pass
        {
		 Tags { "LightMoe" = "ForwardBase"}

		 Cull Off  //关闭得面片剔除  因为消融会漏出内部构造

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_fwdbase
			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
            #include "UnityCG.cginc"

			fixed _BurnAmount;
			fixed _LineWidth;
			sampler2D _MainTex;
			sampler2D _BumpMap;
			fixed4 _BurnFirstColor;
			fixed4 _BurnSecondColor;
			sampler2D _BurnMap;

			float4 _MainTex_ST;
			float4 _BumpMap_ST;
			float4 _BurnMap_ST;

			struct a2v{
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float4 texcoord : TEXCOORD0;
			};

            struct v2f
            {
				float4 pos : SV_POSITION;
                float2 uvMainTex : TEXCOORD0;
				float2 uvBumpMap : TEXCOORD1;
				float2 uvBurnMap : TEXCOORD2;
				float3 lightDir : TEXCOORD3;
				float3 worldPos : TEXCOORD4;
                SHADOW_COORDS(5)
                
            };


            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                
				o.uvMainTex = TRANSFORM_TEX(v.texcoord,_MainTex);//计算三张纹理贴图得坐标
				o.uvBumpMap = TRANSFORM_TEX(v.texcoord,_BumpMap);
				o.uvBurnMap = TRANSFORM_TEX(v.texcoord,_BurnMap);

				TANGENT_SPACE_ROTATION;

				o.lightDir = mul(rotation,ObjSpaceLightDir(v.vertex)).xyz;//光源方向 从 模型空间 到 切线空间

				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz; //世界空间下顶点位置

				TRANSFER_SHADOW(o);//阴影纹理采样

                return o;
            }

			//模拟消融
            fixed4 frag (v2f i) : SV_Target
            {
				fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;//噪声纹理采样

				clip(burn.r - _BurnAmount);	//采样结果与消融程度相减。传递给clip . < 0 得被剔除

				float3 tangentLightDir = normalize(i.lightDir);

				fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uvBumpMap));

				fixed3 albedo = tex2D(_MainTex, i.uvMainTex).rgb;//漫反射纹理得到材质反射率

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo; //环境光

				fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal,tangentLightDir));//计算漫反射光照

				//smoothstep  平滑函数。 前两个时范围。  后面是
				/*
				edge0 代表样条插值函数的下界；
				edge1 代表样条插值函数的上界；
				x 代表用于插值的源输入
				*/
				fixed t = 1 - smoothstep(0.0, _LineWidth, burn.r - _BurnAmount); //计算烧焦颜色burnColor.  在宽度为_LineWidth 范围内模拟一个烧焦得颜色变化
				//当 t = 1 表明像素在消融得边界处。 t= 0 为正常颜色。  中间插值表示需要模拟一个消融效果

				fixed3 burnColor = lerp(_BurnFirstColor,_BurnSecondColor,t); //首先用t去混合两种火焰得颜色 
				burnColor = pow(burnColor,5);
				//为了更逼真得火焰效果 用pow


				UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
				fixed3 finalColor = lerp(ambient + diffuse * atten , burnColor, t * step(0.0001,_BurnAmount));//再次用t混合 光照颜色和烧焦颜色。 用step保证0的时候不显示消融

               
                return fixed4(finalColor,1);
            }
            ENDCG
        }

		//投射阴影处理
		Pass{
			Tags{ "LightMode" = "ShadowCaster"}

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#pragma multi_compile_shadowcaster

			#include "UnityCG.cginc"
			
			fixed _BurnAmount;
			sampler2D _BurnMap;
			float4 _BurnMap_ST;

			struct v2f{
				V2F_SHADOW_CASTER;
				float2 uvBurnMap : TEXCOORD1;
			};

			v2f vert(appdata_base v){
				v2f o;

				TRANSFER_SHADOW_CASTER_NORMALOFFSET(o);

				o.uvBurnMap = TRANSFORM_TEX(v.texcoord, _BurnMap);

				return o;
			}

			fixed4 frag(v2f i):SV_Target{
				fixed3 burn = tex2D(_BurnMap, i.uvBurnMap).rgb;

				clip(burn.r - _BurnAmount);

				SHADOW_CASTER_FRAGMENT(i);
			}

			ENDCG
		}
    }
}
