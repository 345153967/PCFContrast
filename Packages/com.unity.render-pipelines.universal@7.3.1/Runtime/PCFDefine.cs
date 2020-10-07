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
    public static PCFDefine Instance;
    public PCFType pt;
    public Dropdown dd;
    public float offset=0;
    public bool forcePoint=false;

    public UnityEngine.Rendering.Universal.UniversalRenderPipelineAsset urpSetting;
    public Slider distanceSlider;
    public Slider biasSlider;
    public Text disSliderTxt;
    public Text biasSliderTxt;
    public Toggle shadowResolutionToggle;


    private void Awake()
    {
        Instance = this;
        List<string> pcfList = new List<string>();
        foreach (PCFType t in Enum.GetValues(typeof(PCFType)))
            pcfList.Add(t.ToString());
        dd.AddOptions(pcfList);
        dd.onValueChanged.AddListener(delegate
        {
            SwitchType((PCFType)dd.value);
        });

        distanceSlider.onValueChanged.AddListener(delegate
        {
            disSliderTxt.text = Mathf.Floor(distanceSlider.value).ToString();
            urpSetting.shadowDistance = distanceSlider.value;
        });
        shadowResolutionToggle.onValueChanged.AddListener(delegate
        {
            if (shadowResolutionToggle.isOn) urpSetting.mainLightShadowmapResolution = 4096;
            else urpSetting.mainLightShadowmapResolution = 2048;
        });

        biasSlider.onValueChanged.AddListener(delegate
        {
            biasSliderTxt.text = biasSlider.value.ToString().Substring(0, 4);
            urpSetting.shadowDepthBias = biasSlider.value;
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
        this.pt = pt;
    }
    private void OnDestroy()
    {
        urpSetting.shadowDistance = 50;
        urpSetting.shadowDepthBias = 1;
        SwitchType(PCFType.UnityNotMobilePCF);
    }
}
