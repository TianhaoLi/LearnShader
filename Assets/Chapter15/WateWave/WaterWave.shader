// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unlit/WaterWave"
{
    Properties
    {
		_Color ("Main Color",COLOR) = (0, 0.15, 0.115, 1) //控制水面颜色
        _MainTex ("Texture", 2D) = "white" {} //水面波纹的材质
		_WaveMap("Wave map",2D) = "bump"{} //噪声纹理生成的法线纹理
		_CubeMap("Enviroment CubeMap",Cube) = "_Skybox" {} //模拟反射的立方体纹理
		_WaveXSpeed ("Wave Horizontal Speed", Range(-0.1, 0.1)) = 0.01 
		_WaveYSpeed ("Wave Vertical Speed", Range(-0.1,0.1)) = 0.01
		_Distortion("Distortion",Range(0,100)) = 10 //控制模拟折射的扭曲程度
    }
    SubShader
    {
	//使用 GrabPass 获取屏幕图像
        Tags{ "Queue"="Transparent" "RenderType"="Opaque"}//保证不透明物体已经被渲染到屏幕上

		GrabPass{"_RefractionTex"}

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct v2f
            {
				float4 pos : SV_POSITION;
				float4 srcPos : TEXCOORD0;
				float4 uv : TEXCOORD1;
                float4 TtoW0 : TEXCOORD2;
				float4 TtoW1 : TEXCOORD3;
				float4 TtoW2 : TEXCOORD4;
               
            };

            fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _WaveMap;
			float4 _WaveMap_ST;
			samplerCUBE _CubeMap;
			fixed _WaveXSpeed;
			fixed _WaveYSpeed;
			float _Distortion;
			sampler2D _RefractionTex;//GrabPass 得到的纹理名字
			float4 _RefractionTex_TexelSize; //纹理的纹素大小

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT; 
				float4 texcoord : TEXCOORD0;
			};

            v2f vert (a2v v)
            {
                v2f o;

				o.pos = UnityObjectToClipPos(v.vertex);

				o.srcPos = ComputeGrabScreenPos(o.pos);//得到 被抓取的屏幕图像的采样坐标

				o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);//计算纹理采样坐标 存储到uv的 xy和zw中
				o.uv.zw = TRANSFORM_TEX(v.texcoord,_WaveMap);

				//因为需要在片元着色器中把法线方向从切线空间 变换到 世界空间 以便对cubemap采样

				///计算  该顶点对应的从 切线空间到世界空间变换矩阵、
					//方法 得到 切线空间下的3个坐标轴在世界空间下的表示（切线，副切线，法线） 最后利用w分量 保存worldPos

				float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;
				
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
			 float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
			 fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
			 float2 Speed = _Time.y * float2(_WaveXSpeed, _WaveYSpeed);//计算当前偏移量

			 //利用该值两次采样
			 fixed3 bump1 = UnpackNormal(tex2D(_WaveMap, i.uv.zw + Speed)).rgb;
			 fixed3 bump2 = UnpackNormal(tex2D(_WaveMap, i.uv.zw - Speed)).rgb; //(模拟两层交叉的水面波动)
			 fixed3 bump = normalize(bump1 + bump2); //结果归一化后得到 切线空间下的法线方向

			 float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy; //利用distortion和RefractionTex_Texelsize对采样坐标进行偏移，模拟折射
			 i.srcPos.xy = offset * i.srcPos.z + i.srcPos.xy;//偏移与深度z相乘 是为了模拟深度越大 折射程度越大


			 //对srcpos透视除法。在使用抓取到的屏幕图像采样得到模拟折射的颜色
			fixed3 refrCol = tex2D(_RefractionTex, i.srcPos.xy/ i.srcPos.w).rgb;

			//转换normal到worldSpace
			bump = normalize(half3(dot(i.TtoW0.xyz,bump), dot(i.TtoW1.xyz,bump),dot(i.TtoW2.xyz, bump)));

			fixed4 texColor = tex2D(_MainTex, i.uv.xy + Speed);
			fixed3 reflDir = reflect(-viewDir, bump);
			fixed3 reflCol = texCUBE(_CubeMap,reflDir).rgb * texColor.rgb * _Color.rgb;

			fixed fresnel = pow(1 - saturate(dot(viewDir, bump)),4);//计算菲涅尔系数
			fixed3 finalColor = reflCol * fresnel + refrCol * (1 - fresnel);

			return fixed4(finalColor,1);

            }
            ENDCG
        }
    }
	FallBack Off
}
