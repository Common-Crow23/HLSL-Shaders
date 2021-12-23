struct PS_OUTPUT
{
    float4 Color[4] : COLOR0;
    float Depth : DEPTH;
};

PS_OUTPUT main(void)
{
    PS_OUTPUT out;
    
    // Shader statements
    ...
    
    // Write up to four pixel shader output colors
    out.Color[0] = ...
    out.Color[1] = ...
    out.Color[2] = ...
    out.Color[3] = ...
    
    // Write pixel depth
    out.Depth = ...
      
      return out;
}
// This is just an example
