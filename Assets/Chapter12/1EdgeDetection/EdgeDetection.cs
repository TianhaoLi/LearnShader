using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EdgeDetection : PostEffectsBase
{
    public Shader edgeDetectShader;
    private Material edgeDetecMaterial;
    public Material material
    {
        get
        {
            edgeDetecMaterial = CheckShaderAndCreateMaterial(edgeDetectShader, edgeDetecMaterial);
            return edgeDetecMaterial;
        }
    }
    [Range(0.0f, 1.0f)]
    public float edgesOnly = 0.0f; // 边缘检测

    public Color edgeColor = Color.black;

    public Color backgroundColor = Color.white;

    //真正的特殊处理
    void OnRenderImage(RenderTexture src,RenderTexture dest)
    {
        if (material != null)
        {
            material.SetFloat("_EdgesOnly", edgesOnly);
            material.SetColor("_EdgeColor", edgeColor);
            material.SetColor("_BackgroundColor", backgroundColor);

            Graphics.Blit(src, dest, material);
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}
