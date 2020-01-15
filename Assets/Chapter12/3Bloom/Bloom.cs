using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Bloom : PostEffectsBase
{
    public Shader bloomShader;
    private Material bloomMaterial;
    public Material material
    {
        get
        {
            bloomMaterial = CheckShaderAndCreateMaterial(bloomShader, bloomMaterial);
            return bloomMaterial;
        }
    }
    [Range(0, 4)]
    public int iterations = 3; //高斯迭代次数

    [Range(0.2f, 3.0f)]//模糊范围
    public float blurSpread = 0.6f;//过大_BlurSize会造成虚影

    [Range(1, 8)]//缩放系数
    public int downSample = 2; //值越大 需要处理的像素越少，也会提高模糊程度； 过大的缩放系数会导致图像像素画

    [Range(0.0f, 4.0f)]
    public float luminanceThreshold = 0.6f;//控制提取较亮区域使用的阈值

    //真正的特殊处理
    void OnRenderImage(RenderTexture src,RenderTexture dest)
    {
        if (material != null)
        {
            material.SetFloat("_LuminanceThreshold", luminanceThreshold);

            int rtW = src.width / downSample;
            int rtH = src.height / downSample;
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);//分配一块屏幕相当的图像缓冲区 来存储PASS1 模糊后的模糊效果
            buffer0.filterMode = FilterMode.Bilinear;//临时渲染纹理的滤波设置为双线性。

            Graphics.Blit(src, buffer0,material,0);//使用第一个pass来提取较量的区域 存储在buffer0中

            for(int i = 0; i < iterations; i++)//
            {
                material.SetFloat("_BlurSize", 1.0f + i * blurSpread);

                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                Graphics.Blit(buffer0, buffer1, material, 1); //PASS0 垂直模糊

                RenderTexture.ReleaseTemporary(buffer0);

                //轮换
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                Graphics.Blit(buffer0, buffer1, material,2);//PASS1 水平模糊

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;//把渲染好的重新赋值给buffer0 作为src
            }

            //把模糊后的较亮区域buffer0存入bloom纹理
            material.SetTexture("_Bloom", buffer0);

            //调用 使用pass3 去混合原图像 使用该materials 存储到dest输出
            Graphics.Blit(src,dest, material,3);
            RenderTexture.ReleaseTemporary(buffer0);//释放分配的缓存
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}
