Shader "KeywordTest"
{
    Properties
    {
        _TestTex("TestTex",2D) = "white"{}
        _NormalTex("NormalTex",2D) = "white"{}
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" "IgnoreProjector" = "True" "RenderPipeline" = "UniversalPipeline" }
        Pass
        {
            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

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

            Texture2D _TestTex;
            SamplerComparisonState sampler_TestTex;            
            
            Texture2D _NormalTex;
            SamplerState sampler_NormalTex;
            half4 frag(Varyings input) : SV_Target
            {           
                return _TestTex.SampleCmpLevelZero(sampler_TestTex,float2(1,1),1)+ _NormalTex.Sample(sampler_NormalTex,float2(1,1),1);
            }
            ENDHLSL
        }

    }
}
