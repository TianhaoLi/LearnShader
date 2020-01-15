using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]//编辑器下执行
[RequireComponent (typeof(Camera))]
public class PostEffectsBase : MonoBehaviour
{
    protected void CheckResources()
    {
        bool isSupported = CheckSupport();

        if(isSupported == false)
        {
            NotSupported();
        }
    }

    protected void NotSupported()
    {
        enabled = false;
    }

    protected bool CheckSupport()
    {
        if(SystemInfo.supportsImageEffects == false || SystemInfo.supportsRenderTextures == false)
        {
            Debug.LogWarning("this platform does not support image effects or render textures.");
            return false;
        }
        return true;
    }

    // Start is called before the first frame update
    protected void Start()
    {
        CheckResources();
    }

    protected Material CheckShaderAndCreateMaterial(Shader shader,Material material)
    {       //第一个制定特效需要要用的shader 第二个是用于后期处理的材质
        if(shader == null)
        {
            return null;
        }

        if (shader.isSupported && material && material.shader == shader)
            return material;

        if (!shader.isSupported)
        {
            return null;
        }
        else
        {
            material = new Material(shader);
            material.hideFlags = HideFlags.DontSave;
            if (material)
                return material;
            else
                return null;
        }
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
