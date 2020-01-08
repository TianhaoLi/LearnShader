Shader "Custom/4_GlassRefraction"
{
    Properties
    {

		_MainTex("Main Tex",2D) = "white"{}//材质纹理
		_BumpMap("Normal Map",2D) = "bump"{}//玻璃法线纹理
		_CubeMap("Enviroment Cubemap",Cube) = "_SkyBox"{}//模拟反射的环境纹理
		_Distortion("Distortion",Range(0,100))= 10//控制折射图像扭曲度
		_RefractionAmount("Refract Amount",Range(0.0,1.0)) = 1.0//控制折射程度 （0只包含反射 ， 1 只包含折射）
    }
    SubShader
    {
	   Tags { "Queue"="Transparent" "RenderType"="Opaque" }
	   // 1."Queue"="Transparent" 确保该物体渲染时确保所有不透明物体都已被渲染到屏幕上
	   //2. RenderType 为了使用着色器替换时，该物体在被需要时正确渲染（需要摄像机深度和法线纹理时，13章）

	   GrabPass{ "_RefractionTex"}

       Pass{
	   
	   Tags { "LightMode"="ForwardBase" }

		CGPROGRAM

		#pragma vertex vert
		#pragma fragment frag

		#include "UnityCG.cginc"

		sampler2D _MainTex;
		float4 _MainTex_ST;
		sampler2D _BumpMap;
		float4 _BumpMap_ST;
		samplerCUBE _CubeMap;
		float _Distortion;
		fixed _RefractionAmount;
		sampler2D _RefractionTex;
		float4 _RefractionTex_TexelSize;//得到纹理素的大小。  256*512 则 纹理素 1/256,1/512  需要对屏幕图像的采样坐标进行偏移时使用该变量

		struct a2v {
			float4 vertex : POSITION;
			float3 normal : NORMAL;
			float4 tangent : TANGENT;
			float2 texcoord :TEXCOORD0;
		};

		struct v2f{
			float4 pos : SV_POSITION;
			float4 srcPos: TEXCOORD0;
			float4 uv : TEXCOORD1;
			float4 TtoW0 :TEXCOORD2;
			float4 TtoW1 :TEXCOORD3;
			float4 TtoW2:TEXCOORD4;
		};

		v2f vert(a2v v){

			v2f o;

			o.pos = UnityObjectToClipPos(v.vertex);

			o.srcPos = ComputeGrabScreenPos(o.pos);//得到被抓取的采样坐标

			o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);//计算maintex和Bumpmap的采样坐标
			o.uv.zw = TRANSFORM_TEX(v.texcoord,_BumpMap);

			float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;//世界坐标系的顶点
			fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);//世界坐标系下的法线
			fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);//世界坐标系下的切线
			fixed3 worldBinormal =cross(worldNormal,worldTangent);//叉乘得到副切线

			//计算顶点从切线空间到世界空间的变换矩阵
			o.TtoW0 = float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
			o.TtoW1 = float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
			o.TtoW2 = float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);

			return o;
		}

		fixed4 frag(v2f i):SV_Target{
			float3 worldPos = float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
			fixed3 worldVirwDir = normalize(UnityWorldSpaceViewDir(worldPos));

			fixed3 bump = UnpackNormal(tex2D(_BumpMap,i.uv.zw));//得到切线空间下的法线方向

			float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;//屏幕图像偏移 模拟折射(选择切线空间下的法线偏移 是因为该空间法线能反映顶点局部空间下法线方向)

			//对srcPos透视触发得到真正的屏幕坐标 再使用——RefractionTex进行采样 得到模拟的折射颜色
			i.srcPos.xy = offset + i.srcPos.xy;
			fixed3 refrCol = tex2D(_RefractionTex,i.srcPos.xy/i.srcPos.w).rgb;

			bump = normalize(half3(dot(i.TtoW0.xyz,bump),dot(i.TtoW1.xyz,bump),dot(i.TtoW2.xyz,bump)));
			//把 法线方向 从切线空间变换到世界空间（TtoW0 分别于法线方向点乘）

			fixed3 reflDir = reflect(-worldVirwDir,bump);//得到反射方向
			fixed4 texColor = tex2D(_MainTex,i.uv.xy);//主纹理
			fixed3 reflCol = texCUBE(_CubeMap,reflDir).rgb * texColor.rgb;//使用反射方向 对cubemap进行采样  并且与主纹理相乘得到反射颜色

			fixed3 finalColor = reflCol * (1 - _RefractionAmount) + refrCol * _RefractionAmount;//用 _RefractionAmount 进行混合


			return fixed4(finalColor,1);
		}

		ENDCG
	   }
    }
    FallBack "Reflective/VertexLit"
}
