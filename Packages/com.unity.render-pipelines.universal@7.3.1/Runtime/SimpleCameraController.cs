#if ENABLE_INPUT_SYSTEM && ENABLE_INPUT_SYSTEM_PACKAGE
#define USE_INPUT_SYSTEM
    using UnityEngine.InputSystem;
    using UnityEngine.InputSystem.Controls;
#endif

using System.Reflection.Emit;
using UnityEngine;
using UnityEngine.Rendering.LWRP;
using UnityEngine.UI;

public class SimpleCameraController : MonoBehaviour
{
    public UnityEngine.Rendering.Universal.UniversalRenderPipelineAsset urpSetting;
    public Slider slider;
    public Text sliderTxt;
    public Toggle shadowResolutionToggle;

    public Vector3 Pos1;
    public Vector3 Rot1;

    public Vector3 Pos2;
    public Vector3 Rot2;

    private bool useFirst;

    private void Awake()
    {
        slider.onValueChanged.AddListener(delegate
        {
            sliderTxt.text = Mathf.Floor(slider.value).ToString();
            urpSetting.shadowDistance = slider.value;
        });
        shadowResolutionToggle.onValueChanged.AddListener(delegate
        {
            if (shadowResolutionToggle.isOn) urpSetting.mainLightShadowmapResolution = 4096;
            else urpSetting.mainLightShadowmapResolution = 2048;
        });

    }

    public void ChangeTrans()
    {
        if (useFirst)
        {
            transform.localPosition = Pos1;
            transform.localEulerAngles = Rot1;
        }
        else
        {
            transform.localPosition = Pos2;
            transform.localEulerAngles = Rot2;
        }
        useFirst = !useFirst;
    }
    private void OnDestroy()
    {
        urpSetting.shadowDistance = 50;
    }
}