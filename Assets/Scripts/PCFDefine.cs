using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

public enum PCFType
{
    UnityNotMobilePCF,
    UnityMobileHardwarePCF,
    UE4Manual2x2PCF,
    UE4Manual3x3PCF_NoGather,
    UE4Manual3x3PCF_Gather,
}

//[ExecuteInEditMode]
public class PCFDefine : MonoBehaviour
{
    private Dropdown dd;
    private void Awake()
    {
        dd = GetComponent<Dropdown>();
        List<string> pcfList = new List<string>();
        foreach (PCFType t in Enum.GetValues(typeof(PCFType)))
            pcfList.Add(t.ToString());
        dd.AddOptions(pcfList);
        dd.onValueChanged.AddListener(delegate
        {
            SwitchType((PCFType)dd.value);
        });
    }
    void SwitchType(PCFType pt)
    {
        Shader.DisableKeyword("_UnityMobileHardwarePCF");
        Shader.DisableKeyword("_UnityNotMobilePCF");
        Shader.DisableKeyword("_UE4Manual2x2PCF");
        Shader.DisableKeyword("_UE4Manual3x3PCF");
        Shader.DisableKeyword("_FEATURE_GATHER4");

        switch (pt)
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
                Shader.EnableKeyword("_FEATURE_GATHER4");
                break;
        }
    }
}
