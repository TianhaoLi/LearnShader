Shader "Unlit/3_BillBoard"
{
    Properties
    {
        _MainTex ("Base Layer(RGB)", 2D) = "white" {}
		_Color("Color Tint",COLOR) = (1,1,1,1) //控制整体颜色
		_VerticalBillBoarding("Vertical Restraints",Range(0,1)) = 1//调整固定法线 还是固定指向上的方向（约束垂直方向的程度）
    }
    SubShader
    {
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}
		//"DisableBatching  批处理合并相关模型，模型各自的空间会丢失 所以取消批处理操作

        Pass
        {
			Tags{"LightMode"="ForwardBase"}

			ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off//关闭裁切 让水流每个面都能显示

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
			#include "Lighting.cginc"

		    sampler2D _MainTex;
            float4 _MainTex_ST;
			float4 _Color;
			float _VerticalBillBoarding;

            struct a2v
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
			    float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };



            v2f vert (a2v v)
            {
				v2f o;
				//核心部分

				//1.选择模型空间的原点作为锚点 并获得模型空间下的视角位置
				float3 center = float3(0,0,0);
				float3 viewer = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos,1));//世界空间下摄像机位置 转换到模型空间

				//2.计算3个正交矢量。首先根据观察位置和锚点计算目标法线方向。并根据_VerticalBillBoarding属性控制垂直方向的约束
				float3 normalDir = viewer - center;
				normalDir.y = normalDir.y * _VerticalBillBoarding;//_VerticalBillBoarding = 1.法线固定为视角方向； = 0 向上方向固定为 0,1,0
				normalDir = normalize(normalDir);//得到的法线归一化单位矢量

				//防止 法线与向上方向平行
				float3 upDir = abs(normalDir.y) > 0.999 ? float3(0,0,1) : float3(0,1,0);

				float3 rightDir = normalize(cross(upDir,normalDir));
				upDir = normalize(cross(normalDir,rightDir));


				//根据原始位置相对于锚点的偏移 以及三个正交基 得到新的顶点位置
				float3 centerOffset = v.vertex.xyz - center;
				float3 localPos = center + rightDir* centerOffset.x + upDir * centerOffset.y + normalDir * centerOffset.z;

                o.pos = UnityObjectToClipPos(float4(localPos,1));//位移量添加到顶点
				
				o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
           

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
				fixed4 c =tex2D(_MainTex,i.uv);
				c.rgb *= _Color.rgb;
				return c;
            }
            ENDCG
        }
		
    }
	FallBack "Transparent/VertexLit"
}
