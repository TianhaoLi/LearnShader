Pass{
	for(each primitive in this model){
		for(each fragment covered by this primitive){
			if (failed in depth test)
			{
				//没有通过深度测试 说明不可见
				discard;
			}else{
				//如果片元可见
				//光照计算
				float4 color = Shading(materialInfo,pos,normal,lightDir,viewDir);
				//更新缓冲区
				writeFrameBuffer(fragment,color);
			}
		}
	}
}