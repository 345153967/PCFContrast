Shader "KeywordTest"
{
    Properties
    {

    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" }
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            //#pragma multi_compile _InnerMacro1 _InnerMacro2 _InnerMacro3
            ////#pragma multi_compile _A _B 
            //#pragma multi_compile _ _A
            //#pragma multi_compile _ _B
            #pragma multi_compile _UnityMobileHardwarePCF _UnityNotMobilePCF _UE4Manual2x2PCF _UE4Manual3x3PCF _FUCK

            #include "UnlitInput.hlsl"
            struct Attributes
            {
                float4 positionOS       : POSITION;
            };
            struct Varyings
            {
                float4 vertex : SV_POSITION;
            };
            Varyings vert(Attributes input)
            {
                Varyings output = (Varyings)0;
                VertexPositionInputs vertexInput = GetVertexPositionInputs(input.positionOS.xyz);
                output.vertex = vertexInput.positionCS;
                return output;
            }
            half4 frag(Varyings input) : SV_Target
            {
                #if defined(_UnityMobileHardwarePCF)               
                    return half4(1,1,1,1);
                #elif defined(_UnityNotMobilePCF)
                    return half4(1,0,0, 1);
                #elif defined(_UE4Manual2x2PCF)
                    return half4(0,1,0, 1);
                #elif defined(_UE4Manual3x3PCF)
                    return half4(0,0,1, 1);
                #elif defined(_FUCK)
                    return half4(0,0,0, 1);
                #else 
                    return half4(0,0,0,1);
                #endif
            }
            ENDHLSL
        }

    }
}
