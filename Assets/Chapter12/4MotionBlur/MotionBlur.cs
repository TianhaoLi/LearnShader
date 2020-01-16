using UnityEngine;
using System.Collections;

public class MotionBlur : PostEffectsBase {

	public Shader motionBlurShader;
	private Material motionBlurMaterial = null;

	public Material material {  
		get {
			motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
			return motionBlurMaterial;
		}  
	}

	[Range(0.0f, 0.9f)]//模糊参数  0.9是为了防止全是拖影
	public float blurAmount = 0.5f;
	
	private RenderTexture accumulationTexture;

	void OnDisable() {//脚本不运行 立即调用 销毁函数。确保下一次开始运动模糊重新叠加
		DestroyImmediate(accumulationTexture);
	}

	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {
            // Create the accumulation texture   重新创建一个新的accumulationTexture
            if (accumulationTexture == null || accumulationTexture.width != src.width || accumulationTexture.height != src.height) {
				DestroyImmediate(accumulationTexture);
				accumulationTexture = new RenderTexture(src.width, src.height, 0);
				accumulationTexture.hideFlags = HideFlags.HideAndDontSave;//不显示在Hierarchy 也不会保存到场景里
				Graphics.Blit(src, accumulationTexture);//使用当前帧初始化
			}

			// We are accumulating motion over frames without clear/discard
			// by design, so silence any performance warnings from Unity
			accumulationTexture.MarkRestoreExpected();

			material.SetFloat("_BlurAmount", 1.0f - blurAmount);

			Graphics.Blit (src, accumulationTexture, material);
			Graphics.Blit (accumulationTexture, dest);
		} else {
			Graphics.Blit(src, dest);
		}
	}
}
