float4x4 WorldView : WORLDVIEW;
float4x4 Proj: PROJECTION;
float4x4 World :WORLD;

struct VS_OUTPUT{
	float4 Pos : POSITION;
	float4 Pos0 : TEXCOORD0;
};

VS_OUTPUT VS( float4 Pos : POSITION ){
	VS_OUTPUT Out = (VS_OUTPUT)0;
	Out.Pos = mul( Pos, mul(WorldView, Proj) );
	Out.Pos0 = mul( Pos, World);
	return Out;
}

float4 PS( VS_OUTPUT In ) : COLOR0 {
	float4 Color = 0;
	Color.rgb = In.Pos0.xyz;
	Color.a = 1;
	return Color;
}

technique Tech{
	pass P{
		VertexShader = compile vs_2_0 VS();
		PixelShader = compile ps_2_0 PS();
	}
}

