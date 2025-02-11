﻿// Crest Ocean System

// Copyright 2020 Wave Harmonic Ltd

// Draw cached depths into current frame ocean depth data.

// This is CG because its a PITA to render from my own camera transform in HDRP because:
// - Theres a whole bunch of per-view uniforms which have to be manually managed. buf.SetViewProjectionMatrices does NOT set them.
// - The shader param IDs are now internal to HDRP so they have to be redefined
// - I tried setting the values myself by copying some of the code out of UpdateViewConstants(). It almost worked, but fails due
//   to RWS in some way
// - I think the next step would be to look at how model matrices are set for each renderer which is probably in the HDRP layer? (for now?)

// Or simply retreat back to CG where SetViewProjectionMatrices() handles everything automatically.

Shader "Crest/Inputs/Depth/Cached Depths"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}

	SubShader
	{
		Pass
		{
			// Min blending to take the min of all depths. Similar in spirit to zbuffer'd visibility when viewing from top down.
			// To confuse matters further, ocean depth is now more like 'sea floor altitude' - a height above a deep water value,
			// so values are increasing in Y and we need to take the MAX of all depths.
			BlendOp Min
			ColorMask R

			CGPROGRAM
			#pragma vertex Vert
			#pragma fragment Frag
		
			#include "UnityCG.cginc"

			sampler2D _MainTex;

			CBUFFER_START(CrestPerOceanInput)
			float4 _MainTex_ST;
			CBUFFER_END

			struct Attributes
			{
				float3 positionOS : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct Varyings
			{
				float4 position : SV_POSITION;
				float2 uv : TEXCOORD0;
			};

			Varyings Vert(Attributes input)
			{
				Varyings output;
				output.position = UnityObjectToClipPos(input.positionOS);
				output.uv = TRANSFORM_TEX(input.uv, _MainTex);
				return output;
			}

			half4 Frag(Varyings input) : SV_Target
			{
				return half4(tex2D(_MainTex, input.uv).x, 0.0, 0.0, 0.0);
			}
			ENDCG
		}
	}
}
