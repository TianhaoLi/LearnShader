using UnityEngine;
using System.Collections;

public class EdgeDetectNormalsAndDepth : PostEffectsBase {

	public Shader edgeDetectShader;
	private Material fedgeDetectMaterial = null;

	public Material material {  
		get {
            fedgeDetectMaterial = CheckShaderAndCreateMaterial(edgeDetectShader, fedgeDetectMaterial);
			return fedgeDetectMaterial;
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

    //提供了 调整边缘强度的描边颜色以及背景颜色的参数；  控制采样距离以及对深度和法线进行边缘检测的林敏度参数
    [Range(0.0f, 1.0f)]
    public float edgesOnly = 0.0f;

    public Color edgeColor = Color.black;

    public Color backGroundColor = Color.white;

    public float sampleDistance = 1.0f;

    public float sensitivityDepth = 1.0f;

    public float sensitivityNormals = 1.0f;


    //为了获取摄像机纹理  设置摄像机状态
    void OnEnable()
    {
        GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;
    }

    [ImageEffectOpaque]//只对不透明进行处理
	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {

            material.SetFloat("_EdgeOnly", edgesOnly);
            material.SetColor("_EdgeColor", edgeColor);
            material.SetColor("_BackgroundColor", backGroundColor);
            material.SetFloat("_SampleDistance", sampleDistance);
            material.SetVector("_Sentivity", new Vector4(sensitivityNormals,sensitivityDepth,0.0f,0.0f));

            Graphics.Blit(src, dest, material);

        } else {
			Graphics.Blit(src, dest);
		}
	}
}
