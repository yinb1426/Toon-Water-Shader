using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.Universal;
using UnityEngine.SceneManagement;
using UnityEngine.UIElements;
using UnityEditor;

public class Reflection : MonoBehaviour
{
    [SerializeField]
    public Camera rawCamera = null;

    private RenderTexture reflectionRT = null;
    private Camera reflectionCamera = null;
    private Material material = null;

    void Start()
    {
        if (rawCamera == null)
            rawCamera = Camera.main;
        if (reflectionCamera == null)
        {
            var go = new GameObject("Reflection Camera");
            reflectionCamera = go.AddComponent<Camera>();
            reflectionCamera.CopyFrom(rawCamera);
        }
        if (reflectionRT == null)
        {
            reflectionRT = RenderTexture.GetTemporary(1024, 1024, 24);
        }
    }


    // Update is called once per frame
    void Update()
    {
        UpdateCameraParams(rawCamera, reflectionCamera);
        reflectionCamera.targetTexture = reflectionRT;
        reflectionCamera.enabled = false;

        var reflectM = CalculateReflectMatrix(transform.up, transform.position);
        reflectionCamera.worldToCameraMatrix = rawCamera.worldToCameraMatrix * reflectM;
        GL.invertCulling = true; //进行裁剪顺序的翻转

        //下面进行视锥体裁剪
        Vector4 viewPlane = new Vector4(transform.up.x, transform.up.y, transform.up.z, -Vector3.Dot(transform.position, transform.up));//用四维向量表示平面
        viewPlane = reflectionCamera.worldToCameraMatrix.inverse.transpose * viewPlane;//将世界空间中的平面表示转换成相机空间中的平面表示

        Matrix4x4 ClipMatrix = reflectionCamera.CalculateObliqueMatrix(viewPlane);//获取以反射平面为近平面的投影矩阵
        reflectionCamera.projectionMatrix = ClipMatrix;//获取新的投影矩阵

        reflectionCamera.Render();
        GL.invertCulling = false;

        if (material == null)
        {
            var renderer = GetComponent<Renderer>();
            material = renderer.sharedMaterial;
        }
        material.SetTexture("_ReflectionTex", reflectionRT);
    }

    Matrix4x4 CalculateReflectMatrix(Vector3 normal, Vector3 positionOnPlane)
    {
        var d = -Vector3.Dot(normal, positionOnPlane);
        var reflectM = new Matrix4x4();
        reflectM.m00 = 1 - 2 * normal.x * normal.x;
        reflectM.m01 = -2 * normal.x * normal.y;
        reflectM.m02 = -2 * normal.x * normal.z;
        reflectM.m03 = -2 * d * normal.x;

        reflectM.m10 = -2 * normal.x * normal.y;
        reflectM.m11 = 1 - 2 * normal.y * normal.y;
        reflectM.m12 = -2 * normal.y * normal.z;
        reflectM.m13 = -2 * d * normal.y;

        reflectM.m20 = -2 * normal.x * normal.z;
        reflectM.m21 = -2 * normal.y * normal.z;
        reflectM.m22 = 1 - 2 * normal.z * normal.z;
        reflectM.m23 = -2 * d * normal.z;

        reflectM.m30 = 0;
        reflectM.m31 = 0;
        reflectM.m32 = 0;
        reflectM.m33 = 1;
        return reflectM;
    }

    private void UpdateCameraParams(Camera srcCamera, Camera destCamera)
    {
        if (destCamera == null || srcCamera == null)
            return;

        destCamera.clearFlags = srcCamera.clearFlags;
        destCamera.backgroundColor = srcCamera.backgroundColor;
        destCamera.farClipPlane = srcCamera.farClipPlane;
        destCamera.nearClipPlane = srcCamera.nearClipPlane;
        destCamera.orthographic = srcCamera.orthographic;
        destCamera.fieldOfView = srcCamera.fieldOfView;
        destCamera.aspect = srcCamera.aspect;
        destCamera.orthographicSize = srcCamera.orthographicSize;
    }
}
