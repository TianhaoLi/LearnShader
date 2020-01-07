Pass 1{
	// pass1 不进行真正的光照计算，只把光照需要的存入Gbuffer
	for(each primitive in this model){
		for(each fragment covered by this primitive){
			if (failed in depth test)
			{
				//没有通过深度测试 说明不可见
				discard;
			}else{
				//如果片元可见
				//需要的信息存入G-buffer
				writeGbuffer(materialInfo,pos,normal)
			}
		}
	}
}


Pass 2{
	for(each pixel in the screen){
		if(the pixel is valid){
			//该像素是有效地
			//读取他对应的Gbuffer缓冲信息
			readGBuffer(pixel,materialInfo,pos,normal);

			//根绝读取到的信息进行光照计算
			float4 color = Shading(materialInfo,pos,normal,lightDir,viewDir);
			//更新帧缓冲
			writeFrameBuffer(pixel,color);
		}
	}
}
