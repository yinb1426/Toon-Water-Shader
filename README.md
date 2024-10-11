# 卡通(非真实感)水体Shader
## 概述
卡通水体Shader基于NPR，实现水体的光影、折射、反射以及动态变化等效果。
## 特性
* 基于NPR方案实现水体渲染
* 使用Blinn-Phong模型实现光照效果
* 实现浅水、深水、远水颜色混合，并提供Cosine Gradient颜色混合选项
* 可以使用多张法线贴图混合实现水体动态波动效果
* 提供折射扭曲、平面反射选项
* 实现基于正弦波的边缘泡沫效果(仿原神效果)
## 参数
**常规配置项**：
| 参数 | 类型 | <center> 说明 | 建议参考值 |
| :------: | :------: | :------ | :------: |
| BaseMap | 2D | 用于在VS中获取UV值，无特殊用处| 置空 |
| UseAlpha| Toggle | 是否开启水体的透明度，不开启则Alpha=1.0 | √ |
| UseBlinnPhongSpecular | Toggle | 是否使用Blinn-Phong高光项 | √ |
| SpecularColor | Color | Blinn-Phong高光颜色 | (1.0, 1.0, 1.0, 1.0)|
| SpecularPower | Float | Blinn-Phong高光项指数项 | 128.0 |

**控制器**：
| 参数 | 类型 | <center> 说明 | 建议参考值 |
| :------: | :------: | :------ | :------: |
| WaterDepthController | Float | 用于控制水深的系数 | 3.5 |
| DistanceController | Float | 用于控制远水颜色混合距离的系数 | 0.01 |
| WaterFadeController | Range(0, 1) | 用于控制近岸水透明度显示的系数 | 0.7 |

**水体颜色**：
| 参数 | 类型 | <center> 说明 | 建议参考值 |
| :------: | :------: | :------ | :------: |
| ShallowColor | Color[HDR] | 浅水颜色 | (0.0, 1.976675, 1.683646, 1.0, 1.4) |
| DeepColor |  Color[HDR] | 深水颜色 | (0.0, 0.229934, 0.8039216, 1.0, 0.0) / (0.0, 0.1321121, 0.8039216, 1.0, 0.0) |
| FarColor | Color[HDR] | 远水颜色 | (0.0, 0.4542139, 0.8196079, 1.0, 0.0) |

**Cosine Gradient水体颜色(可选)**：
| 参数 | 类型 | <center> 说明 | 建议参考值 |
| :------: | :------: | :------ | :------: |
| UseCosineGradient | Toggle | 是否使用Cosine Gradient显示水体颜色，如果使用距离混合，则关闭该选项 | × |
| WaterColorController | Float | 用于控制CosineGradient颜色的系数 | 1.5 |

**法线贴图**：
| 参数 | 类型 | <center> 说明 | 建议参考值 |
| :------: | :------: | :------ | :------: |
| UseNormalMap| Toggle | 是否使用法线贴图 | √ |
| FirstNormalMap | 2D | 第一法线贴图 | Tiling = 12X12 |
| FirstNormalSpeedInverse | Float | 第一法线贴图移动速度系数的倒数 | 80 |
| SecondNormalMap | 2D | 第二法线贴图 | Tiling = 15X15 |
| SecondNormalSpeedInverse | Float | 第二法线贴图移动速度系数的倒数 | -60 |

**正弦波(可选)**：
| 参数 | 类型 | <center> 说明 | 建议参考值 |
| :------: | :------: | :------ | :------: |
| UseSineWave | Toggle | 是否添加近岸正弦波泡沫效果 | √ |
| SinePeriod | Float | 控制正弦波周期的系数 | 25 |
| SineSpeed | Float | 控制正弦波的移动系数 |1 |
| SineAmplitude | Float | 控制正弦波的振幅 | 1 |
| SineMaskThreshold | Range(0, 1) | 控制正弦波的显示范围的系数 | 0.8 |
| SineStrength | Float | 控制正弦波的强度 | 4.0 |

**正弦波—噪声控制器**：
| 参数 | 类型 | <center> 说明 | 建议参考值 |
| :------: | :------: | :------ | :------: |
| NoiseSpeed | Float | 控制噪声移动的速度 | 0.02 |
| NoiseSize | Float | SimpleNoise中控制噪声大小的参数 | 60 |
| NoiseMinEdge | Float | 用于截取噪声的下边界 | 1.3 |
| NoiseMaxEdge | Float | 用于截取噪声的上边界 | 1.8 |
> 噪声使用的为Unity Shader Graph的Simple Noise节点，参考：https://docs.unity3d.com/cn/Packages/com.unity.shadergraph@10.5/manual/Simple-Noise-Node.html

**折射**：
| 参数 | 类型 | <center> 说明 | 建议参考值 |
| :------: | :------: | :------ | :------: |
| UseRefraction | Toggle | 是否添加折射效果 | √ |
| RefractedScale | Range(0.0, 0.1) | 控制折射扭曲的细碎程度 | 0.0438 |
| RefractedSpeed | Range(0.0, 0.2) | 控制折射扭曲的速度 | 0.079 |
| RefractedStrength | Range(0.0, 0.1) | 控制折射扭曲的强度 | 0.03 |

**平面反射**：
| 参数 | 类型 | <center> 说明 | 建议参考值 |
| :------: | :------: | :------ | :------: |
| UsePlanarReflection | Toggle | 是否添加平面效果 | √ |
| ReflectionTex | 2D | 反射贴图，需要使用Reflection.cs脚本提供，不能自行设置 | |
| FresnelPower | Range(0.01, 64.0) | 控制菲涅尔效果的指数项 | 0.6 |
| FresnelEdge | Range(0.0, 1.0) | 控制菲涅尔效果的范围 | 0.6 |
## 实现效果
![Lighthouse](https://github.com/yinb1426/Toon-Water-Shader/edit/main/Pictures/Lighthouse.png)
## 使用说明
1. 提供多个开关选项，可根据需要开启或关闭部分功能
    * 水体透明度
    * 使用Blinn-Phong模型高光项
    * 使用Cosine Gradient颜色混合
    * 使用法线贴图
    * 添加正弦波
    * 添加折射扭曲效果
    * 添加平面反射效果
2. 如果需要添加平面反射效果，由于使用反射相机方法实现反射，需要再水面GO中添加Reflection.cs脚本，rawCamera设置为场景的主相机。此时运行后可以在Game模式中实现平面反射效果。
3. 在Scenes文件夹中提供测试场景DemoScene，可在其中测试实现效果
## TODO
* SSPR
* ......
