using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class GaussianBlur : PostEffectsBase
{
    public Shader gaussianBlurShader;
    private Material gaussianBlurMaterial;
    public Material material
    {
        get
        {
            gaussianBlurMaterial = CheckShaderAndCreateMaterial(gaussianBlurShader, gaussianBlurMaterial);
            return gaussianBlurMaterial;
        }
    }
    [Range(0, 4)]
    public int iterations = 3; //高斯迭代次数

    [Range(0.2f, 3.0f)]//模糊范围
    public float blurSpread = 0.6f;//过大_BlurSize会造成虚影

    [Range(1, 8)]//缩放系数
    public int downSample = 2; //值越大 需要处理的像素越少，也会提高模糊程度； 过大的缩放系数会导致图像像素画

    //真正的特殊处理
    void OnRenderImage(RenderTexture src,RenderTexture dest)
    {
        // version 1.0 基础
        /*
        if (material != null)
        {
            int rtW = src.width;
            int rtH = src.height;
            RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);//分配一块屏幕相当的图像缓冲区 来存储PASS1 模糊后的模糊效果

            Graphics.Blit(src, buffer, material, 0);

            Graphics.Blit(buffer, dest, material, 1);

            RenderTexture.ReleaseTemporary(buffer);//释放分配的缓存
        }
        */


        //version 2.0 利用缩放对图像降采样 减少需要处理的像素个数
        /*
        if (material != null)
        {
            int rtW = src.width / downSample;
            int rtH = src.height / downSample;
            RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);//分配一块屏幕相当的图像缓冲区 来存储PASS1 模糊后的模糊效果
            buffer.filterMode = FilterMode.Bilinear;//临时渲染纹理的滤波设置为双线性。

            Graphics.Blit(src, buffer, material, 0);

            Graphics.Blit(buffer, dest, material, 1);

            RenderTexture.ReleaseTemporary(buffer);//释放分配的缓存
        }
        */

        //version 3.0 考虑了高斯模糊的迭代次数
        if (material != null)
        {
            int rtW = src.width / downSample;
            int rtH = src.height / downSample;
            RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);//分配一块屏幕相当的图像缓冲区 来存储PASS1 模糊后的模糊效果
            buffer0.filterMode = FilterMode.Bilinear;//临时渲染纹理的滤波设置为双线性。

            Graphics.Blit(src, buffer0);

            for(int i = 0; i < iterations; i++)//
            {
                material.SetFloat("_BlurSize", 1.0f + i * blurSpread);

                RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                Graphics.Blit(buffer0, buffer1, material, 0); //PASS0 垂直模糊

                RenderTexture.ReleaseTemporary(buffer0);

                //轮换
                buffer0 = buffer1;
                buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

                Graphics.Blit(buffer0, buffer1, material, 1);//PASS1 水平模糊

                RenderTexture.ReleaseTemporary(buffer0);
                buffer0 = buffer1;//把渲染好的重新赋值给buffer0 作为src
            }
            //循环结束 buffer0存放的就是dest
            Graphics.Blit(buffer0, dest);
            RenderTexture.ReleaseTemporary(buffer0);//释放分配的缓存
        }
        else
        {
            Graphics.Blit(src, dest);
        }
    }
}
