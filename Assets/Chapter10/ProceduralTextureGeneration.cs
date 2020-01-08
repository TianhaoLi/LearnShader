using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

[ExecuteInEditMode]//允许在编辑器下运行
public class ProceduralTextureGeneration : MonoBehaviour
{
    public Material material = null;

    //声明程序纹理需要的参数region仅仅为了组织代码   依次是 纹理大小,纹理的背景颜色，圆点的颜色，模糊因子(模糊圆形边界)
    #region Material properties
    [SerializeField, SetProperty("textureWidth")]
    private int m_textureWidth = 512;
    public int textureWidth
    {
        get
        {
            return m_textureWidth;
        }
        set
        {
            m_textureWidth = value;
            _UpdateMaterial();
        }
    }

    [SerializeField, SetProperty("backgroundColor")]
    private Color m_backgroundColor = Color.white;
    private Color backgroundColor
    {
        get
        {
            return m_backgroundColor;
        }
        set
        {
            m_backgroundColor = value;
            _UpdateMaterial();
        }
    }

    [SerializeField, SetProperty("circleColor")]
    private Color m_circleColor = Color.yellow;
    public Color circleColor
    {
        get
        {
            return m_circleColor;
        }
        set
        {
            m_circleColor = value;
            _UpdateMaterial();
        }
    }

    [SerializeField, SetProperty("blurFactor")]
    private float m_blurFactorr = 2.0f;
    public float blurFactor
    {
        get
        {
            return m_blurFactorr;
        }
        set
        {
            m_blurFactorr = value;
            _UpdateMaterial();
        }
    }
    #endregion

    private Texture2D m_generatedTexture = null;//保存程序纹理

    // Start is called before the first frame update
    void Start()
    {//检查如果为空 就尝试从该脚本所在的物体上得到相应的材质 完成后调用_UpdateMaterial函数生成纹理
        if (material == null)
        {
            Renderer renderer = gameObject.GetComponent<Renderer>();
            if(renderer == null)
            {
                Debug.LogWarning("Cannot find a renderer");
                return;
            }
            material = renderer.sharedMaterial;
        }

        _UpdateMaterial();
    }

    private void _UpdateMaterial()
    {
       if(material != null)
        {
            
            m_generatedTexture = _GenerateProceduralTexture();
            material.SetTexture("_MainTex", m_generatedTexture);
        }
    }

    private Texture2D _GenerateProceduralTexture()
    {
        Texture2D proceduralTexture = new Texture2D(textureWidth, textureWidth);

        //定义圆与圆的距离
        float circleInterval = textureWidth / 4.0f;
        //定义圆的半径
        float radius = textureWidth / 10.0f;
        //模糊系数
        float edgeBlur = 1.0f / blurFactor;

        for(int w = 0; w < textureWidth; w++)
        {
            for(int h = 0; h < textureWidth; h++)
            {
                //背景颜色初始化
                Color pixel = backgroundColor;
                //依次画九个圆
                for(int i = 0; i< 3; i++)
                {
                    for (int j = 0; j < 3; j++)
                    {
                        //计算绘制的圆心的位置
                        Vector2 circleCenter = new Vector2(circleInterval * (i + 1), circleInterval * (j + 1));

                        //计算当前像素与圆心的距离
                        float dist = Vector2.Distance(new Vector2(w, h), circleCenter) - radius;


                        //模糊圆的边界
                        Color color = _MixColor(circleColor, new Color(pixel.r, pixel.g, pixel.b, 0.0f), Mathf.SmoothStep(0f, 1.0f, dist * edgeBlur));

                        //与之前的颜色混合
                        pixel = _MixColor(pixel, color, color.a);
                    }
                }


                proceduralTexture.SetPixel(w, h, pixel);
            }
        }

        proceduralTexture.Apply();
        return proceduralTexture;
    }

    private Color _MixColor(Color color0, Color color1, float mixFactor)
    {
        Color mixColor = Color.white;
        mixColor.r = Mathf.Lerp(color0.r, color1.r, mixFactor);
        mixColor.g = Mathf.Lerp(color0.g, color1.g, mixFactor);
        mixColor.b = Mathf.Lerp(color0.b, color1.b, mixFactor);
        mixColor.a = Mathf.Lerp(color0.a, color1.a, mixFactor);
        return mixColor;
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
