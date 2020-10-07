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
    private bool useFirst;

    public Vector3 Pos1;
    public Vector3 Rot1;

    public Vector3 Pos2;
    public Vector3 Rot2;

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
}