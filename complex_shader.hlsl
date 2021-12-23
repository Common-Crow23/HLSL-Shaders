#if OPENGL
#define SV_POSITION POSITION
#define VS_SHADERMODEL vs_3_0
#define PS_SHADERMODEL ps_3_0
#else
#define VS_SHADERMODEL vs_4_0_level_9_1
#define PS_SHADERMODEL ps_4_0_level_9_1
#endif

float4x4 wvp;

float4 ColorAndAlpha = float4(1,1,1,1);
float2 SourcePos = float2(0,0);
float2 SourceSize = float2(1,1); 

texture ColorMap;
sampler ColorMapSampler = sampler_state 
{
    texture = <ColorMap>;    
};

struct VS_IN
{
    float4 Position : SV_POSITION;
    float2 TexCoord : TEXCOORD0;
    float3 Normal : NORMAL;
    float3 Tangent : TANGENT;
};
struct VS_OUT
{
    float4 Position : SV_POSITION;
    float2 TexCoord : TEXCOORD0;
    float3 Normal : TEXCOORD1;
};

VS_OUT VS_Flat(VS_IN input)
{
    VS_OUT output = (VS_OUT)0;
    output.Position = mul(input.Position,wvp);
    output.TexCoord = input.TexCoord;
    return output;
}

VS_OUT VS_FixedLight(VS_IN input)
{
    VS_OUT output = (VS_OUT)0;
    output.Position = mul(input.Position,wvp);
    output.Normal = input.Normal;
    output.TexCoord = input.TexCoord;

    return output;
}

float4 PS_Flat(VS_OUT input) : COLOR0
{
    float4 texCol = tex2D(ColorMapSampler, (input.TexCoord * SourceSize + SourcePos));
    float4 output = texCol * ColorAndAlpha;

    output.rgb *= ColorAndAlpha.a;
    clip(texCol.a - 0.01);

    return output;
}

float4 PS_FixedLight(VS_OUT input) : COLOR0
{   
    float2 textureCoord = input.TexCoord * SourceSize + SourcePos;
    float4 texCol = tex2D(ColorMapSampler, textureCoord);

    float3 normalNormal = normalize(input.Normal);
    float3 lightDir = normalize(float3(1,1,1));
    float lightReflect = dot(normalNormal, lightDir) * 0.3;

     float4 output = (texCol * 0.7 + texCol * lightReflect) * ColorAndAlpha;

    output.a = texCol.a * ColorAndAlpha.a;
    output.rgb *= output.a;
    clip(texCol.a - 0.01);

    return output;
}

technique Flat //Renders a 3d model with no light effect
{
    pass Pass0
    {
        VertexShader = compile VS_SHADERMODEL VS_Flat();
        PixelShader = compile PS_SHADERMODEL PS_Flat();
    }
}

technique FixedLight //Renders a 3d model with a static ligtht gradient (Lambert)
{
    pass Pass0
    {
        VertexShader = compile VS_SHADERMODEL VS_FixedLight();
        PixelShader  = compile PS_SHADERMODEL PS_FixedLight();
    }
}
