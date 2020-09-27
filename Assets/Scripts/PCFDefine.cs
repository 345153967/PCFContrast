using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public enum PCFType
{
    UnityNotMobilePCF,
    UnityMobileHardwarePCF,
    UE4Manual2x2PCF,
    UE4Manual3x3PCF_NoGather,
    UE4Manual3x3PCF_Gather
}

[ExecuteInEditMode]
public class PCFDefine : MonoBehaviour
{
    public PCFType pcftype;

    void Update()
    {
        Shader.DisableKeyword("_UnityMobileHardwarePCF");
        Shader.DisableKeyword("_UnityNotMobilePCF");

        switch (pcftype)
        {
            case PCFType.UnityNotMobilePCF:
                Shader.EnableKeyword("_UnityNotMobilePCF");
                break;
            case PCFType.UnityMobileHardwarePCF:
                Shader.EnableKeyword("_UnityMobileHardwarePCF");
                break;
            case PCFType.UE4Manual2x2PCF:
                Shader.EnableKeyword("_UE4Manual2x2PCF");
                break;
            case PCFType.UE4Manual3x3PCF_NoGather:
                Shader.EnableKeyword("_UE4Manual3x3PCF");
                break;
            case PCFType.UE4Manual3x3PCF_Gather:
                Shader.EnableKeyword("_UE4Manual3x3PCF");
                Shader.EnableKeyword("_UE4Manual3x3PCF_Gather");
                break;
        }
    }
}
