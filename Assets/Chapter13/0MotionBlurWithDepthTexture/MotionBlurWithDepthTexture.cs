using UnityEngine;
using System.Collections;

public class MotionBlurWithDepthTexture : PostEffectsBase {

	public Shader motionBlurShader;
	private Material motionBlurMaterial = null;

	public Material material {  
		get {
			motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
			return motionBlurMaterial;
		}  
	}

    [Range(0.0f, 1.0f)] //模糊图像的大小
    public float blurSize = 0.5f;

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

    //保存上一帧的视角*投影的矩阵
    private Matrix4x4 previousViewProjectionMatrix;

    //为了获取摄像机纹理  设置摄像机状态
    void OnEnable()
    {
        camera.depthTextureMode |= DepthTextureMode.Depth;

        previousViewProjectionMatrix = camera.projectionMatrix * camera.worldToCameraMatrix;
    }

	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {
            material.SetFloat("_BlurSize", blurSize);

            material.SetMatrix("_PreViousViewProjectionMatrix", previousViewProjectionMatrix);
            Matrix4x4 currentViewProjectionMatrix = camera.projectionMatrix * camera.worldToCameraMatrix;//摄像机 投影矩阵 * 摄像机视角矩阵
            Matrix4x4 currentViewProjectionInverseMatrix = currentViewProjectionMatrix.inverse; // 相乘后 取 逆矩阵
            material.SetMatrix("_CurrentViewProjectionInverseMatrix", currentViewProjectionInverseMatrix);// 把逆矩阵存储在参数 _CurrentViewProjectionInverseMatrix 以便下一帧传递给_PreViousViewProjectionMatrix
            previousViewProjectionMatrix = currentViewProjectionMatrix;//把当前帧作为下一帧的上一帧

            Graphics.Blit(src, dest, material);//把逆矩阵传递给材质

		} else {
			Graphics.Blit(src, dest);
		}
	}
}
