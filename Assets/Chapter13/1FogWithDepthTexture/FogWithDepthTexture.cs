using UnityEngine;
using System.Collections;

public class FogWithDepthTexture : PostEffectsBase {

	public Shader fogShader;
	private Material fogMaterial = null;

	public Material material {  
		get {
            fogMaterial = CheckShaderAndCreateMaterial(fogShader, fogMaterial);
			return fogMaterial;
		}  
	}

    private Camera myCamera;
    public Camera camera
    {
        get
        {
            if(myCamera == null)
            {
                myCamera = GetComponent<Camera>();
            }
            return myCamera;
        }
    }

    private Transform myCameraTransform;
    public Transform cameraTransform
    {
        get
        {
            if(myCameraTransform == null)
            {
                myCameraTransform = camera.transform;
            }

            return myCameraTransform;
        }
    }

    [Range(0.0f, 3.0f)]
    public float fogDensity = 1.0f;//控制雾的浓度

    public Color fogColor = Color.white;

    public float fogStart = 0.0f;

    public float fogEnd = 2.0f;

    //为了获取摄像机纹理  设置摄像机状态
    void OnEnable()
    {
        camera.depthTextureMode |= DepthTextureMode.Depth;
    }

	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {
            //首先计算 近剪裁面的四个角向量，并存储在一个矩阵中 frustumCorners

            Matrix4x4 frustumCorners = Matrix4x4.identity;

            float fov = camera.fieldOfView;
            float near = camera.nearClipPlane;
            float far = camera.farClipPlane;
            float aspect = camera.aspect;//长宽比

            float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);//Mathf.Deg2Rad 角度转弧度
            Vector3 toRight = cameraTransform.right * halfHeight * aspect;
            Vector3 toTop = cameraTransform.up * halfHeight;

                //TL
                Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;
                float scale = topLeft.magnitude / near;

                topLeft.Normalize();
                topLeft *= scale;

                //TR
                Vector3 topRight = cameraTransform.forward * near + toTop + toRight;
                topRight.Normalize();
                topRight *= scale;

                //BL
                Vector3 bottomLeft = cameraTransform.forward * near - toTop - toRight;
                bottomLeft.Normalize();
                bottomLeft *= scale;

                //BR
                Vector3 bottomRight = cameraTransform.forward * near - toTop + toRight;
                bottomRight.Normalize();
                bottomRight *= scale;

            frustumCorners.SetRow(0, bottomLeft);
            frustumCorners.SetRow(1, bottomRight);
            frustumCorners.SetRow(2, topRight);
            frustumCorners.SetRow(3, topLeft);

            //把结果和其他参数传递给材质 并调用渲染
            material.SetMatrix("_FrustumCornersRay", frustumCorners);
            material.SetMatrix("_ViewProjectionInverseMatrix", (camera.projectionMatrix * camera.worldToCameraMatrix).inverse);

            material.SetFloat("_FogDensity",fogDensity);
            material.SetColor("_FogColor", fogColor);
            material.SetFloat("_FogStart",fogStart);
            material.SetFloat("_FogEnd",fogEnd);

            Graphics.Blit(src, dest, material);

        } else {
			Graphics.Blit(src, dest);
		}
	}
}
