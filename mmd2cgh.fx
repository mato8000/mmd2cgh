#define DEBUG

const float Pi = 3.14159265358979;
const float DotPitch = 8e-6;
const float3 WaveLength = {650e-9, 532e-9, 488e-9};
const float WorldScale = 1.f / 1500;

float Script : STANDARDSGLOBAL <
    string ScriptOutput = "color";
    string ScriptClass = "scene";
    string ScriptOrder = "postprocess";
> = 0.8;

texture PosRT: OFFSCREENRENDERTARGET <
	string Description = "OffScreen RenderTarget for mmd2cgh_pos.fx";
    float4 ClearColor = { 0, 0, 0, 1 };
    string Format="A16B16G16R16F";
    float ClearDepth = 1.0;
    bool AntiAlias = true;
    int Miplevels = 1;
	string DefaultEffect =
        "self = hide;"
        "* = mmd2cgh_pos.fx;";
>;
sampler PosSampler = sampler_state
{
   Texture = (PosRT);
   ADDRESSU = CLAMP;
   ADDRESSV = CLAMP;
   FILTER = NONE;
};

texture ColRT: OFFSCREENRENDERTARGET <
	string Description = "OffScreen RenderTarget for default color";
    float4 ClearColor = { 0, 0, 0, 1 };
    //string Format="A16B16G16R16F";
    float ClearDepth = 1.0;
    bool AntiAlias = true;
    int Miplevels = 1;
	string DefaultEffect =
        "self = hide;"
        "* = none";
>;
sampler ColSampler = sampler_state
{
   Texture = (ColRT);
   ADDRESSU = CLAMP;
   ADDRESSV = CLAMP;
   FILTER = NONE;
};

float2 ViewportSize : VIEWPORTPIXELSIZE;

static float2 ViewportOffset = (float2(0.5,0.5)/ViewportSize);

struct VS_OUTPUT {
    float4 Pos      : POSITION;
    float2 Tex      : TEXCOORD0;
};

VS_OUTPUT VS(float4 Pos : POSITION, float2 Tex : TEXCOORD0){
	VS_OUTPUT Out;

	Out.Pos = Pos;
	Out.Tex = Tex + ViewportOffset;
	return Out;
}

float4 PS(VS_OUTPUT IN, float2 Tex: TEXCOORD0, float2 vpos: VPOS ) : COLOR{
#ifdef DEBUG
    if( vpos.x % (1920/160) == 0 && vpos.y % (1080/90) == 0 ){
        float4 color = tex2D( ColSampler, Tex );
        return color;
    // if( vpos.x > 1920*1/4 && vpos.x <= 1920*3/4 && vpos.x % (1920/120) == 0 && vpos.y % (1080/135) == 0 ){
    //     float4 Depth = tex2D( ColSampler, Tex );
    //     return Depth;
    // if( vpos.x > 1920*3/8 && vpos.x <= 1920*5/8 && vpos.y < 1080/2 && vpos.x % (1920/120/2) == 0 && vpos.y % (1080/135/2) == 0 ){
    //     float4 Depth = tex2D( ColSampler, Tex );
    //     return Depth;
    } else {
        return float4(0, 0, 0, 1);
    }
#else
    float3 Re = 0;
    float3 Im = 0;
    for ( int i = 0; i < 160; ++i ){
        for ( int j = 0; j < 90; ++j ){
            float2 uv = float2((float)i/160, (float)j/90);
            //float2 uv = float2(1.0/4 + 1.0/2 * (float)i/120, (float)j/135);
            //float2 uv = float2(3.0/8 + 0.25 * (float)i/120, 0.5 * (float)j/135);
            float4 texPos = tex2D( PosSampler, uv);
            float4 texCol = tex2D( ColSampler, uv);
            if ( texPos.x == 0 && texPos.y == 0 && texPos.z == 0 ) continue;
            texPos *= WorldScale;
            float2 dist = pow( texPos.xy - (vpos.xy - float2(960, 540) ) * DotPitch, 2);
            float theta_ = Pi * ( dist.x + dist.y ) / texPos.z;
            float3 theta = theta_ / WaveLength;

            //I
            float3 intense = texCol * float3(0.299, 0.587, 0.114);
            Re += (intense.r + intense.g + intense.b) * cos( theta );
            Im += (intense.r + intense.g + intense.b) * sin( theta );
            //RGB
            // Re += texCol.rgb * cos( theta );
            // Im += texCol.rgb * sin( theta );
        }
    }
    float3 arg = atan( Im / Re ) / Pi + 0.5;
    //I
    return float4(arg.y, arg.y, arg.y, 1);
    //RGB
    // return float4( arg, 1);
#endif
}

////////////////////////////////////////////////////////////////////////////////////////////////
float4 ClearColor = {0, 0, 0, 0};
float ClearDepth  = 0;

technique PostEffectTec <
	string Script =
        "ClearSetColor=ClearColor;"
        "ClearSetDepth=ClearDepth;"
        "Clear=Color;"
        "Clear=Depth;"
        "ScriptExternal=Color;"
        "RenderColorTarget0=;"
        "RenderDepthStencilTarget=;"
        "Pass=Draw;"
	;
>{
	pass Draw < string Script = "Draw=Buffer;"; >{
		AlphaBlendEnable = false;
		VertexShader = compile vs_3_0 VS();
		PixelShader  = compile ps_3_0 PS();
	}
};

