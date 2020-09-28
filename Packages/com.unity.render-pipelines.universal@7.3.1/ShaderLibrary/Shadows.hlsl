#ifndef UNIVERSAL_SHADOWS_INCLUDED
#define UNIVERSAL_SHADOWS_INCLUDED

#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Shadow/ShadowSamplingTent.hlsl"
#include "Core.hlsl"


//For PCF Functions Contrast
#if defined(_UE4Manual2x2PCF) || defined(_UE4Manual3x3PCF)
#define PCFSAMPLER(samplerName) SAMPLER(samplerName)
#else
#define PCFSAMPLER(samplerName) SAMPLER_CMP(samplerName)
#endif

//hacked TEXTURE2D_SHADOW_PARAM
#define TEXTURE2D_SHADOW_PARAM(textureName,samplerName) TEXTURE2D(textureName), PCFSAMPLER(samplerName)



#define SHADOWS_SCREEN 0
#define MAX_SHADOW_CASCADES 4

#if !defined(_RECEIVE_SHADOWS_OFF)
#if defined(_MAIN_LIGHT_SHADOWS)
#define MAIN_LIGHT_CALCULATE_SHADOWS

#if !defined(_MAIN_LIGHT_SHADOWS_CASCADE)
#define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
#endif
#endif

#if defined(_ADDITIONAL_LIGHT_SHADOWS)
#define ADDITIONAL_LIGHT_CALCULATE_SHADOWS
#endif
#endif

#if defined(_ADDITIONAL_LIGHTS) || defined(_MAIN_LIGHT_SHADOWS_CASCADE)
#define REQUIRES_WORLD_SPACE_POS_INTERPOLATOR
#endif

SCREENSPACE_TEXTURE(_ScreenSpaceShadowmapTexture);
SAMPLER(sampler_ScreenSpaceShadowmapTexture);

TEXTURE2D_SHADOW(_MainLightShadowmapTexture);
PCFSAMPLER(sampler_MainLightShadowmapTexture);

TEXTURE2D_SHADOW(_AdditionalLightsShadowmapTexture);
PCFSAMPLER(sampler_AdditionalLightsShadowmapTexture);

// Last cascade is initialized with a no-op matrix. It always transforms
// shadow coord to half3(0, 0, NEAR_PLANE). We use this trick to avoid
// branching since ComputeCascadeIndex can return cascade index = MAX_SHADOW_CASCADES
float4x4    _MainLightWorldToShadow[MAX_SHADOW_CASCADES + 1];
float4      _CascadeShadowSplitSpheres0;
float4      _CascadeShadowSplitSpheres1;
float4      _CascadeShadowSplitSpheres2;
float4      _CascadeShadowSplitSpheres3;
float4      _CascadeShadowSplitSphereRadii;
half4       _InvHalfShadowAtlasWidthHeight;
half4       _MainLightShadowParams;  // (x: shadowStrength, y: 1.0 if soft shadows, 0.0 otherwise)
float4      _MainLightShadowmapSize; // (xy: 1/width and 1/height, zw: width and height)

#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
StructuredBuffer<ShadowData> _AdditionalShadowsBuffer;
StructuredBuffer<int> _AdditionalShadowsIndices;
#else
float4x4    _AdditionalLightsWorldToShadow[MAX_VISIBLE_LIGHTS];
half4       _AdditionalShadowParams[MAX_VISIBLE_LIGHTS];
#endif
half4       _AdditionalShadowOffset0;
half4       _AdditionalShadowOffset1;
half4       _AdditionalShadowOffset2;
half4       _AdditionalShadowOffset3;
float4      _AdditionalShadowmapSize; // (xy: 1/width and 1/height, zw: width and height)

float4 _ShadowBias; // x: depth bias, y: normal bias

#define BEYOND_SHADOW_FAR(shadowCoord) shadowCoord.z <= 0.0 || shadowCoord.z >= 1.0

struct ShadowSamplingData
{
	half4 _InvHalfShadowAtlasWidthHeight;
	float4 shadowmapSize;
};

ShadowSamplingData GetMainLightShadowSamplingData()
{
	ShadowSamplingData shadowSamplingData;
	shadowSamplingData._InvHalfShadowAtlasWidthHeight = _InvHalfShadowAtlasWidthHeight;
	shadowSamplingData.shadowmapSize = _MainLightShadowmapSize;
	return shadowSamplingData;
}

ShadowSamplingData GetAdditionalLightShadowSamplingData()
{
	ShadowSamplingData shadowSamplingData;
	shadowSamplingData._InvHalfShadowAtlasWidthHeight = _InvHalfShadowAtlasWidthHeight;
	shadowSamplingData.shadowmapSize = _AdditionalShadowmapSize;
	return shadowSamplingData;
}

// ShadowParams
// x: ShadowStrength
// y: 1.0 if shadow is soft, 0.0 otherwise
half4 GetMainLightShadowParams()
{
	return _MainLightShadowParams;
}


// ShadowParams
// x: ShadowStrength
// y: 1.0 if shadow is soft, 0.0 otherwise
half4 GetAdditionalLightShadowParams(int lightIndex)
{
#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
	return _AdditionalShadowsBuffer[lightIndex].shadowParams;
#else
	return _AdditionalShadowParams[lightIndex];
#endif
}

half SampleScreenSpaceShadowmap(float4 shadowCoord)
{
	shadowCoord.xy /= shadowCoord.w;

	// The stereo transform has to happen after the manual perspective divide
	shadowCoord.xy = UnityStereoTransformScreenSpaceTex(shadowCoord.xy);

#if defined(UNITY_STEREO_INSTANCING_ENABLED) || defined(UNITY_STEREO_MULTIVIEW_ENABLED)
	half attenuation = SAMPLE_TEXTURE2D_ARRAY(_ScreenSpaceShadowmapTexture, sampler_ScreenSpaceShadowmapTexture, shadowCoord.xy, unity_StereoEyeIndex).x;
#else
	half attenuation = SAMPLE_TEXTURE2D(_ScreenSpaceShadowmapTexture, sampler_ScreenSpaceShadowmapTexture, shadowCoord.xy).x;
#endif

	return attenuation;
}






//pcf test codes insert as below
//unity非移动端PCF 9次SampleCmpLevelZero主动采样配合4次硬件pcf  结果为36个样本 
//#define SAMPLE_TEXTURE2D_SHADOW()  textureName.SampleCmpLevelZero(samplerName, (coord3).xy, (coord3).z)
real UnityNotMobilePCF(Texture2D ShadowMap, SamplerComparisonState sampler_ShadowMap, real4 shadowCoord, ShadowSamplingData samplingData) {
	real fetchesWeights[9];
	real2 fetchesUV[9];
	SampleShadow_ComputeSamples_Tent_5x5(samplingData.shadowmapSize, shadowCoord.xy, fetchesWeights, fetchesUV);
	real attenuation = fetchesWeights[0] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, real3(fetchesUV[0].xy, shadowCoord.z));
	attenuation += fetchesWeights[1] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, real3(fetchesUV[1].xy, shadowCoord.z));
	attenuation += fetchesWeights[2] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, real3(fetchesUV[2].xy, shadowCoord.z));
	attenuation += fetchesWeights[3] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, real3(fetchesUV[3].xy, shadowCoord.z));
	attenuation += fetchesWeights[4] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, real3(fetchesUV[4].xy, shadowCoord.z));
	attenuation += fetchesWeights[5] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, real3(fetchesUV[5].xy, shadowCoord.z));
	attenuation += fetchesWeights[6] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, real3(fetchesUV[6].xy, shadowCoord.z));
	attenuation += fetchesWeights[7] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, real3(fetchesUV[7].xy, shadowCoord.z));
	attenuation += fetchesWeights[8] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, real3(fetchesUV[8].xy, shadowCoord.z));
	return attenuation;
}

//unity移动端4次SampleCmpLevelZero主动采样配合硬件pcf  结果为16个样本
real4 UnityMobileHardwarePCF(Texture2D ShadowMap, SamplerComparisonState sampler_ShadowMap, real4 shadowCoord, ShadowSamplingData samplingData) {
	real4 attenuation4;
	attenuation4.x = ShadowMap.SampleCmpLevelZero(sampler_ShadowMap, shadowCoord.xy + samplingData._InvHalfShadowAtlasWidthHeight.xy * real2(-1, -1), shadowCoord.z);
	attenuation4.y = ShadowMap.SampleCmpLevelZero(sampler_ShadowMap, shadowCoord.xy + samplingData._InvHalfShadowAtlasWidthHeight.xy * real2(1, -1), shadowCoord.z);
	attenuation4.z = ShadowMap.SampleCmpLevelZero(sampler_ShadowMap, shadowCoord.xy + samplingData._InvHalfShadowAtlasWidthHeight.xy * real2(-1, 1), shadowCoord.z);
	attenuation4.w = ShadowMap.SampleCmpLevelZero(sampler_ShadowMap, shadowCoord.xy + samplingData._InvHalfShadowAtlasWidthHeight.xy * real2(1, 1), shadowCoord.z);

	return attenuation4;
}


real3 CalculateOcclusion(real3 ShadowmapDepth, real SceneDepth) {
	//the standard comparison is SceneDepth<ShadowmapDepth
	//using a soft transition based on depth difference
	//offsets shadows a bit but reduces self shadowing artifacts considerably
	float transitionScale = 4000;

	//unoptimized math:saturate(ShadowmapDepth- SceneDepth)*transitionScale+1);
	//rearranged the math so that per pixel constants can be optimized from per sample constants
	float constantFactor = SceneDepth * transitionScale - 1;
	float3 ShadowFactor = saturate(ShadowmapDepth * transitionScale - constantFactor);
	return ShadowFactor;
}

real4 CalculateOcclusion(real4 ShadowmapDepth, real SceneDepth) {
	real transitionScale = 4000;
	real constantFactor = SceneDepth * transitionScale - 1;
	real4 ShadowFactor = saturate(ShadowmapDepth * transitionScale - constantFactor);
	return ShadowFactor;
}

real3 FetchRowOfThree(Texture2D ShadowMap, SamplerState sampler_ShadowMap, real2 sampleCenter, real verticalOffset, ShadowSamplingData samplingData, real screenDepth)
{
	real3 Values;
	Values.x = ShadowMap.SampleLevel(sampler_ShadowMap, (sampleCenter + real2(0, verticalOffset)) * samplingData.shadowmapSize.xy, 0).r;
	Values.y = ShadowMap.SampleLevel(sampler_ShadowMap, (sampleCenter + real2(1, verticalOffset)) * samplingData.shadowmapSize.xy, 0).r;
	Values.z = ShadowMap.SampleLevel(sampler_ShadowMap, (sampleCenter + real2(2, verticalOffset)) * samplingData.shadowmapSize.xy, 0).r;
	return CalculateOcclusion(Values, screenDepth);
}

real4 FetchRowOfFour(Texture2D ShadowMap, SamplerState sampler_ShadowMap, real2 sampleCenter, real verticalOffset, ShadowSamplingData samplingData, real screenDepth)
{
	real4 Values;
	Values.x = ShadowMap.SampleLevel(sampler_ShadowMap, (sampleCenter + float2(0, verticalOffset)) * samplingData.shadowmapSize.xy, 0).r;
	Values.y = ShadowMap.SampleLevel(sampler_ShadowMap, (sampleCenter + float2(1, verticalOffset)) * samplingData.shadowmapSize.xy, 0).r;
	Values.z = ShadowMap.SampleLevel(sampler_ShadowMap, (sampleCenter + float2(2, verticalOffset)) * samplingData.shadowmapSize.xy, 0).r;
	Values.w = ShadowMap.SampleLevel(sampler_ShadowMap, (sampleCenter + float2(3, verticalOffset)) * samplingData.shadowmapSize.xy, 0).r;
	return CalculateOcclusion(Values, screenDepth);
}

//UE4 2x2PCF:9次SampleLevel主动采样无硬件pcf配合, 结果为9次样本
real UE4Manual2x2PCF(Texture2D ShadowMap, SamplerState sampler_ShadowMap, real4 shadowCoord, ShadowSamplingData samplingData) {
	real2 TexelPos = shadowCoord.xy * samplingData.shadowmapSize.zw;
	real2 Fraction = frac(TexelPos);
	real2 TexelCenter = floor(TexelPos) + 0.5f;
	real2 SampleCenter = TexelCenter - real2(1, 1);

	real3 SamplesValues0 = FetchRowOfThree(ShadowMap, sampler_ShadowMap, SampleCenter, 0, samplingData, shadowCoord.z);
	real3 SamplesValues1 = FetchRowOfThree(ShadowMap, sampler_ShadowMap, SampleCenter, 1, samplingData, shadowCoord.z);
	real3 SamplesValues2 = FetchRowOfThree(ShadowMap, sampler_ShadowMap, SampleCenter, 2, samplingData, shadowCoord.z);
 
	real3 results;
	results.x = SamplesValues0.x * (1 - Fraction.x) + SamplesValues0.y + SamplesValues1.z * Fraction.x;
	results.y = SamplesValues1.x * (1 - Fraction.x) + SamplesValues1.y + SamplesValues1.z * Fraction.x;
	results.z = SamplesValues1.x * (1 - Fraction.x) + SamplesValues1.y + SamplesValues1.z * Fraction.x;
	return 1 - saturate(0.25f * dot(results, real3(1.0f - Fraction.y, 1.0f, Fraction.y)));
}

//UE4 3x3PCF:分为gather与非gather两部分
//gather: 4次Gather主动采样配合4次硬件PCF, 结果为16次样本
//no gather: softPCF,主动采样16次, 结果为16次样本
real UE4Manual3x3PCF(Texture2D ShadowMap, SamplerState sampler_ShadowMap, real4 shadowCoord, ShadowSamplingData samplingData)
{
	real2 TexelPos = shadowCoord.xy * samplingData.shadowmapSize.zw - 0.5f;	// bias to be consistent with texture filtering hardware
	real2 Fraction = frac(TexelPos);
	real2 TexelCenter = floor(TexelPos) + 0.5f;	// bias to get reliable texel center content
	real2 SampleCenter = TexelCenter - real2(1, 1);

	real4 SampleValues0, SampleValues1, SampleValues2, SampleValues3;

#if defined(_FEATURE_GATHER4)
		real2 SamplePos = TexelCenter * samplingData.shadowmapSize.xy;	// bias to get reliable texel center content
		SampleValues0 = CalculateOcclusion(ShadowMap.Gather(sampler_ShadowMap, SamplePos, int2(-1, -1)), shadowCoord.z);
		SampleValues1 = CalculateOcclusion(ShadowMap.Gather(sampler_ShadowMap, SamplePos, int2(1, -1)), shadowCoord.z);
		SampleValues2 = CalculateOcclusion(ShadowMap.Gather(sampler_ShadowMap, SamplePos, int2(-1, 1)), shadowCoord.z);
		SampleValues3 = CalculateOcclusion(ShadowMap.Gather(sampler_ShadowMap, SamplePos, int2(1, 1)), shadowCoord.z);

		real4 results;
		results.x = SampleValues0.w * (1.0 - Fraction.x) + SampleValues0.z + SampleValues1.w + SampleValues1.z * Fraction.x;
		results.y = SampleValues0.x * (1.0 - Fraction.x) + SampleValues0.y + SampleValues1.x + SampleValues1.y * Fraction.x;
		results.z = SampleValues2.w * (1.0 - Fraction.x) + SampleValues2.z + SampleValues3.w + SampleValues3.z * Fraction.x;
		results.w = SampleValues2.x * (1.0 - Fraction.x) + SampleValues2.y + SampleValues3.x + SampleValues3.y * Fraction.x;
		return 1 - dot(results, real4(1.0 - Fraction.y, 1.0, 1.0, Fraction.y) * (1.0 / 9.0));
#else
		SampleValues0 = FetchRowOfFour(ShadowMap, sampler_ShadowMap, SampleCenter, 0, samplingData, shadowCoord.z);
		SampleValues1 = FetchRowOfFour(ShadowMap, sampler_ShadowMap, SampleCenter, 1, samplingData, shadowCoord.z);
		SampleValues2 = FetchRowOfFour(ShadowMap, sampler_ShadowMap, SampleCenter, 2, samplingData, shadowCoord.z);
		SampleValues3 = FetchRowOfFour(ShadowMap, sampler_ShadowMap, SampleCenter, 3, samplingData, shadowCoord.z);

		real4 results;
		results.x = SampleValues0.x * (1.0f - Fraction.x) + SampleValues0.y + SampleValues0.z + SampleValues0.w * Fraction.x;
		results.y = SampleValues1.x * (1.0f - Fraction.x) + SampleValues1.y + SampleValues1.z + SampleValues1.w * Fraction.x;
		results.z = SampleValues2.x * (1.0f - Fraction.x) + SampleValues2.y + SampleValues2.z + SampleValues2.w * Fraction.x;
		results.w = SampleValues3.x * (1.0f - Fraction.x) + SampleValues3.y + SampleValues3.z + SampleValues3.w * Fraction.x;
		return 1 - (saturate(dot(results, real4(1.0f - Fraction.y, 1.0f, 1.0f, Fraction.y))* (1.0f / 9.0f)));
#endif
}

real DoPCF(TEXTURE2D_SHADOW_PARAM(ShadowMap, sampler_ShadowMap), float4 shadowCoord, ShadowSamplingData samplingData) {
	real attenuation = 0;
	#if defined(_UnityNotMobilePCF)
		attenuation = UnityNotMobilePCF(ShadowMap, sampler_ShadowMap, shadowCoord, samplingData);
	#elif defined(_UnityMobileHardwarePCF)
		attenuation = dot(UnityMobileHardwarePCF(ShadowMap, sampler_ShadowMap, shadowCoord, samplingData), 0.25);
	#elif defined(_UE4Manual2x2PCF)
		attenuation = UE4Manual2x2PCF(ShadowMap, sampler_ShadowMap, shadowCoord, samplingData);
	#elif defined(_UE4Manual3x3PCF)
		attenuation = UE4Manual3x3PCF(ShadowMap, sampler_ShadowMap, shadowCoord, samplingData);
	#elif defined(_FUCK)
		attenuation = 0;
	#else
		attenuation = 10000;
	#endif
	return attenuation;
}
//pcf test end


















real SampleShadowmapFiltered(TEXTURE2D_SHADOW_PARAM(ShadowMap, sampler_ShadowMap), float4 shadowCoord, ShadowSamplingData samplingData)
{
	return DoPCF(TEXTURE2D_SHADOW_ARGS(ShadowMap, sampler_ShadowMap), shadowCoord, samplingData);

	//    real attenuation;
	//#if defined(SHADER_API_MOBILE) || defined(SHADER_API_SWITCH)
	//    // 4-tap hardware comparison
	//    real4 attenuation4;
	//    attenuation4.x = SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, shadowCoord.xyz + samplingData.shadowOffset0.xyz);
	//    attenuation4.y = SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, shadowCoord.xyz + samplingData.shadowOffset1.xyz);
	//    attenuation4.z = SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, shadowCoord.xyz + samplingData.shadowOffset2.xyz);
	//    attenuation4.w = SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, shadowCoord.xyz + samplingData.shadowOffset3.xyz);
	//    attenuation = dot(attenuation4, 0.25);
	//#else
	//    float fetchesWeights[9];
	//    float2 fetchesUV[9];
	//    SampleShadow_ComputeSamples_Tent_5x5(samplingData.shadowmapSize, shadowCoord.xy, fetchesWeights, fetchesUV);
	//
	//    attenuation = fetchesWeights[0] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[0].xy, shadowCoord.z));
	//    attenuation += fetchesWeights[1] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[1].xy, shadowCoord.z));
	//    attenuation += fetchesWeights[2] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[2].xy, shadowCoord.z));
	//    attenuation += fetchesWeights[3] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[3].xy, shadowCoord.z));
	//    attenuation += fetchesWeights[4] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[4].xy, shadowCoord.z));
	//    attenuation += fetchesWeights[5] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[5].xy, shadowCoord.z));
	//    attenuation += fetchesWeights[6] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[6].xy, shadowCoord.z));
	//    attenuation += fetchesWeights[7] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[7].xy, shadowCoord.z));
	//    attenuation += fetchesWeights[8] * SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, float3(fetchesUV[8].xy, shadowCoord.z));
	//#endif
	//
	//    return attenuation;
}

real SampleShadowmap(TEXTURE2D_SHADOW_PARAM(ShadowMap, sampler_ShadowMap), float4 shadowCoord, ShadowSamplingData samplingData, half4 shadowParams, bool isPerspectiveProjection = true)
{
	// Compiler will optimize this branch away as long as isPerspectiveProjection is known at compile time
	if (isPerspectiveProjection)
		shadowCoord.xyz /= shadowCoord.w;

	real attenuation=0;
	real shadowStrength = shadowParams.x;

	// TODO: We could branch on if this light has soft shadows (shadowParams.y) to save perf on some platforms.
#ifdef _SHADOWS_SOFT
	attenuation = SampleShadowmapFiltered(TEXTURE2D_SHADOW_ARGS(ShadowMap, sampler_ShadowMap), shadowCoord, samplingData);
//#else
//	// 1-tap hardware comparison
//	attenuation = SAMPLE_TEXTURE2D_SHADOW(ShadowMap, sampler_ShadowMap, shadowCoord.xyz);
#endif

	attenuation = LerpWhiteTo(attenuation, shadowStrength);

	// Shadow coords that fall out of the light frustum volume must always return attenuation 1.0
	// TODO: We could use branch here to save some perf on some platforms.
	return BEYOND_SHADOW_FAR(shadowCoord) ? 1.0 : attenuation;
}

half ComputeCascadeIndex(float3 positionWS)
{
	float3 fromCenter0 = positionWS - _CascadeShadowSplitSpheres0.xyz;
	float3 fromCenter1 = positionWS - _CascadeShadowSplitSpheres1.xyz;
	float3 fromCenter2 = positionWS - _CascadeShadowSplitSpheres2.xyz;
	float3 fromCenter3 = positionWS - _CascadeShadowSplitSpheres3.xyz;
	float4 distances2 = float4(dot(fromCenter0, fromCenter0), dot(fromCenter1, fromCenter1), dot(fromCenter2, fromCenter2), dot(fromCenter3, fromCenter3));

	half4 weights = half4(distances2 < _CascadeShadowSplitSphereRadii);
	weights.yzw = saturate(weights.yzw - weights.xyz);

	return 4 - dot(weights, half4(4, 3, 2, 1));
}

float4 TransformWorldToShadowCoord(float3 positionWS)
{
#ifdef _MAIN_LIGHT_SHADOWS_CASCADE
	half cascadeIndex = ComputeCascadeIndex(positionWS);
#else
	half cascadeIndex = 0;
#endif

	return mul(_MainLightWorldToShadow[cascadeIndex], float4(positionWS, 1.0));
}

half MainLightRealtimeShadow(float4 shadowCoord)
{
#if !defined(MAIN_LIGHT_CALCULATE_SHADOWS)
	return 1.0h;
#endif

	ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
	half4 shadowParams = GetMainLightShadowParams();
	return SampleShadowmap(TEXTURE2D_ARGS(_MainLightShadowmapTexture, sampler_MainLightShadowmapTexture), shadowCoord, shadowSamplingData, shadowParams, false);
}

half AdditionalLightRealtimeShadow(int lightIndex, float3 positionWS)
{
#if !defined(ADDITIONAL_LIGHT_CALCULATE_SHADOWS)
	return 1.0h;
#endif

	ShadowSamplingData shadowSamplingData = GetAdditionalLightShadowSamplingData();

#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
	lightIndex = _AdditionalShadowsIndices[lightIndex];

	// We have to branch here as otherwise we would sample buffer with lightIndex == -1.
	// However this should be ok for platforms that store light in SSBO.
	UNITY_BRANCH
		if (lightIndex < 0)
			return 1.0;

	float4 shadowCoord = mul(_AdditionalShadowsBuffer[lightIndex].worldToShadowMatrix, float4(positionWS, 1.0));
#else
	float4 shadowCoord = mul(_AdditionalLightsWorldToShadow[lightIndex], float4(positionWS, 1.0));
#endif

	half4 shadowParams = GetAdditionalLightShadowParams(lightIndex);
	return SampleShadowmap(TEXTURE2D_ARGS(_AdditionalLightsShadowmapTexture, sampler_AdditionalLightsShadowmapTexture), shadowCoord, shadowSamplingData, shadowParams, true);
}

float4 GetShadowCoord(VertexPositionInputs vertexInput)
{
	return TransformWorldToShadowCoord(vertexInput.positionWS);
}

float3 ApplyShadowBias(float3 positionWS, float3 normalWS, float3 lightDirection)
{
	float invNdotL = 1.0 - saturate(dot(lightDirection, normalWS));
	float scale = invNdotL * _ShadowBias.y;

	// normal bias is negative since we want to apply an inset normal offset
	positionWS = lightDirection * _ShadowBias.xxx + positionWS;
	positionWS = normalWS * scale.xxx + positionWS;
	return positionWS;
}

///////////////////////////////////////////////////////////////////////////////
// Deprecated                                                                 /
///////////////////////////////////////////////////////////////////////////////

// Renamed -> _MainLightShadowParams
#define _MainLightShadowData _MainLightShadowParams

// Deprecated: Use GetMainLightShadowParams instead.
half GetMainLightShadowStrength()
{
	return _MainLightShadowData.x;
}

// Deprecated: Use GetAdditionalLightShadowParams instead.
half GetAdditionalLightShadowStrenth(int lightIndex)
{
#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
	return _AdditionalShadowsBuffer[lightIndex].shadowParams.x;
#else
	return _AdditionalShadowParams[lightIndex].x;
#endif
}

// Deprecated: Use SampleShadowmap that takes shadowParams instead of strength.
real SampleShadowmap(float4 shadowCoord, TEXTURE2D_SHADOW_PARAM(ShadowMap, sampler_ShadowMap), ShadowSamplingData samplingData, half shadowStrength, bool isPerspectiveProjection = true)
{
	half4 shadowParams = half4(shadowStrength, 1.0, 0.0, 0.0);
	return SampleShadowmap(TEXTURE2D_SHADOW_ARGS(ShadowMap, sampler_ShadowMap), shadowCoord, samplingData, shadowParams, isPerspectiveProjection);
}

#endif
