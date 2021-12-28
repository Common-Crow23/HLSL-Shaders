//-----------------------------------------------------------------------------
// File: Textures.cpp
// About "Using Pixel Shader"   
//-----------------------------------------------------------------------------
#include <Windows.h>
#include <mmsystem.h>
#include <d3dx9.h>
#include <strsafe.h>
 
//-----------------------------------------------------------------------------
// Global variables
//-----------------------------------------------------------------------------
LPDIRECT3D9             g_pD3D       = NULL; // Used to create the D3DDevice
LPDIRECT3DDEVICE9       g_pd3dDevice = NULL; // Our rendering device
LPDIRECT3DVERTEXBUFFER9 g_pVB        = NULL; // Buffer to hold vertices
LPDIRECT3DTEXTURE9      g_pTexture   = NULL; // Our Texture
 
IDirect3DPixelShader9* TexPS = 0;            // Interface to encapsulate the functionality of a pixel shader
ID3DXConstantTable* TextCT = 0;              // Used to access the constant table
 
D3DXHANDLE BaseTexHandle = 0;
D3DXCONSTANT_DESC BaseTexDesc;               // A description of a constant in a constant table
 
// A structure for out custom vertex type. And We added texture coordinates
struct CUSTOMVERTEX
{
    float x, y, z;
    unsigned long color;
    FLOAT       tu, tv;   //  texture coordinates
};
 
// Compare to "Triangle" Example, Here add D3DFVF_TEX1
#define D3DFVF_CUSTOMVERTEX (D3DFVF_XYZ|D3DFVF_DIFFUSE|D3DFVF_TEX1)
 
//-----------------------------------------------------------------------------
// Name: InitD3D()
// Desc: Initializes Direct3D
//-----------------------------------------------------------------------------
HRESULT InitD3D( HWND hWnd )
{
    // Create the D3D object
    if( NULL == ( g_pD3D = Direct3DCreate9( D3D_SDK_VERSION ) ) )
        return E_FAIL;
 
    // Set up the structure used to create the D3DDevice. Since we are now
    // using more complex geomitry, we will create a device with a zbuffer.
    D3DPRESENT_PARAMETERS d3dpp;
    ZeroMemory( &d3dpp, sizeof(d3dpp) );
    d3dpp.Windowed = TRUE;
    d3dpp.SwapEffect = D3DSWAPEFFECT_DISCARD;
    d3dpp.BackBufferFormat = D3DFMT_UNKNOWN;
    d3dpp.EnableAutoDepthStencil = TRUE;
    d3dpp.AutoDepthStencilFormat = D3DFMT_D16;
 
    // Create the D3DDevice
    if( FAILED( g_pD3D->CreateDevice( D3DADAPTER_DEFAULT, D3DDEVTYPE_HAL, hWnd,
                                      D3DCREATE_SOFTWARE_VERTEXPROCESSING,
                                      &d3dpp, &g_pd3dDevice ) ) )
    {
        return E_FAIL;
    }
 
    // Turn off culling
    g_pd3dDevice->SetRenderState( D3DRS_CULLMODE, D3DCULL_NONE );
 
    // Turn off D3D lighting
    g_pd3dDevice->SetRenderState( D3DRS_LIGHTING, FALSE );
 
    // Turn on the zbuffer
    g_pd3dDevice->SetRenderState( D3DRS_ZENABLE, TRUE );
 
    HRESULT hr = 0;
 
    ID3DXBuffer* shader = 0;
    ID3DXBuffer* errorBuffer = 0;
 
    // Compile shader from a file
    hr = D3DXCompileShaderFromFile("hlslTexture.txt",
        0,
        0,
        "Main",             // entry point function name
        "ps_1_1",           // HLSL shader name 
        D3DXSHADER_DEBUG,
        &shader,            // containing the created shader
        &errorBuffer,       // containing a listing of errors and warnings
        &TextCT);           // used to access shader constants
    if(errorBuffer)
    {
        ::MessageBox(0,(char*)errorBuffer->GetBufferPointer(), 0, 0);
        errorBuffer->Release();
    }
    if(FAILED(hr))
    {
        ::MessageBox(0,"D3DXCompileShaderFromFile() - FAILED", 0, 0);
        return false;
    }
    // creates a pixel shader
    hr = g_pd3dDevice->CreatePixelShader((DWORD*)shader->GetBufferPointer(),&TexPS);
    if(FAILED(hr))
    {
        ::MessageBox(0,"CreateVertexShader - FAILED", 0, 0);
        return false;
    }
    shader->Release();
 
    // gets a constant 
    BaseTexHandle = TextCT->GetConstantByName(0, "BaseTex");
 
    // set constant descriptions
 
    UINT count;
 
    TextCT->GetConstantDesc(BaseTexHandle, &BaseTexDesc, &count);
    return S_OK;
}
 
//-----------------------------------------------------------------------------
// Name: InitGeometry()
// Desc: Create the Textures and vertex buffers
//-----------------------------------------------------------------------------
HRESULT InitGeometry()
{
    HRESULT hr = 0;
    // create texture
    hr = D3DXCreateTextureFromFile( g_pd3dDevice, "objective-c.png", &g_pTexture );
    if(FAILED(hr))
    {
           MessageBox(NULL, "Could not find objective-c.png", "Textures.exe", MB_OK);
           return E_FAIL;   
    }
 
    // Initialize the vertices including texture coordinate 
    CUSTOMVERTEX Vertices[] =
    {
           { -1.0f, -1.0f, 0.0f, D3DCOLOR_XRGB(255,255,255),0,1 }, // x, y, z, rhw, color,tu,tv
           { -1.0f, 1.0f, 0.0f, D3DCOLOR_XRGB(255,255,255), 0,0},
           { 1.0f, -1.0f, 0.0f, D3DCOLOR_XRGB(255,255,255), 1,1},
           { 1.0f, 1.0f, 0.0f, D3DCOLOR_XRGB(255,255,255), 1,0},
    };
    // Create the vertex buffer
    hr = g_pd3dDevice->CreateVertexBuffer(sizeof(Vertices),
                                          D3DUSAGE_WRITEONLY,D3DFVF_CUSTOMVERTEX,
                                          D3DPOOL_MANAGED,&g_pVB,0);
    if(hr)
    {
        return E_FAIL;
    }
 
    // Filled with data from the custom vertices
 
    VOID* pVertices;
    if( FAILED( g_pVB->Lock( 0, sizeof(Vertices), (void**)&pVertices, 0 ) ) )
        return E_FAIL;
    memcpy( pVertices, Vertices, sizeof(Vertices) );
 
    g_pVB->Unlock();
 
    return S_OK;
}
 
//-----------------------------------------------------------------------------
// Name: Cleanup()
// Desc: Released all previously initialized objects
//-----------------------------------------------------------------------------
VOID Cleanup()
{
    if( g_pTexture != NULL )
        g_pTexture->Release();
 
    if( g_pVB != NULL )
        g_pVB->Release();
 
    if( g_pd3dDevice != NULL )
        g_pd3dDevice->Release();
 
    if( g_pD3D != NULL )
        g_pD3D->Release();
 
    if(TexPS != NULL )
        TexPS->Release();
 
    if(TextCT != NULL)
        TextCT->Release();
}
 
//-----------------------------------------------------------------------------
// Name: SetupMatrices()
// Desc: Sets up the world, view, and projection transform matrices.
//-----------------------------------------------------------------------------
VOID SetupMatrices()
{
    // Rotate by the Y axis
    D3DXMATRIXA16 matWorld;
    D3DXMatrixIdentity( &matWorld );
    //remove the comments below to rotate the picture
    //D3DXMatrixRotationY( &matWorld, timeGetTime()/1000.0f );
    g_pd3dDevice->SetTransform( D3DTS_WORLD, &matWorld );
 
    // Set View Transformation Matrix. Including some carame information
    D3DXVECTOR3 vEyePt( 0.0f, 0.0f,-2.5f );
    D3DXVECTOR3 vLookatPt( 0.0f, 0.0f, 0.0f );
    D3DXVECTOR3 vUpVec( 0.0f, 1.0f, 0.0f );
    D3DXMATRIXA16 matView;
    D3DXMatrixLookAtLH( &matView, &vEyePt, &vLookatPt, &vUpVec );
    g_pd3dDevice->SetTransform( D3DTS_VIEW, &matView );
 
    // Set Transformation Matrix
    D3DXMATRIXA16 matProj;
    D3DXMatrixPerspectiveFovLH( &matProj, D3DX_PI/4, 1.0f, 1.0f, 100.0f );
    g_pd3dDevice->SetTransform( D3DTS_PROJECTION, &matProj );
 
}
 
//-----------------------------------------------------------------------------
// Name: Render()
// Desc: Draws the scene
//-----------------------------------------------------------------------------
VOID Render()
{
    // Clear the backbuffer and the zbuffer, Set color to blue
    g_pd3dDevice->Clear( 0, NULL, D3DCLEAR_TARGET|D3DCLEAR_ZBUFFER,
                         D3DCOLOR_XRGB(0,0,255), 1.0f, 0 );
 
    // Begin the scene
    if( SUCCEEDED( g_pd3dDevice->BeginScene() ) )
    {
        // Setup the world, view, and projection matrices
        SetupMatrices();
 
        g_pd3dDevice->SetPixelShader(TexPS);
 
        // Setting the texture to use
        g_pd3dDevice->SetTexture(BaseTexDesc.RegisterIndex, g_pTexture);
        g_pd3dDevice->SetSamplerState(BaseTexDesc.RegisterIndex, D3DSAMP_MAGFILTER, D3DTEXF_LINEAR);
        g_pd3dDevice->SetSamplerState(BaseTexDesc.RegisterIndex, D3DSAMP_MINFILTER, D3DTEXF_LINEAR);
        g_pd3dDevice->SetSamplerState(BaseTexDesc.RegisterIndex, D3DSAMP_MIPFILTER, D3DTEXF_LINEAR);
 
        // Render the vertex buffer contents
        g_pd3dDevice->SetStreamSource( 0, g_pVB, 0, sizeof(CUSTOMVERTEX) );
        g_pd3dDevice->SetFVF( D3DFVF_CUSTOMVERTEX );
 
        // A rectangle made of two triangles
        g_pd3dDevice->DrawPrimitive( D3DPT_TRIANGLESTRIP, 0, 2);
 
        // End the scene
        g_pd3dDevice->EndScene();
    }
 
    // Present the backbuffer contents to the dispaly
    g_pd3dDevice->Present( NULL, NULL, NULL, NULL );
}
 
//-----------------------------------------------------------------------------
// Name: MsgProc()
// Desc: The window's message handler
//-----------------------------------------------------------------------------
LRESULT WINAPI MsgProc( HWND hWnd, UINT msg, WPARAM wParam, LPARAM lParam )
{
    switch( msg )
    {
        case WM_DESTROY:
            Cleanup();
            PostQuitMessage( 0 );
            return 0;
    }
 
    return DefWindowProc( hWnd, msg, wParam, lParam );
}
 
//-----------------------------------------------------------------------------
// Name: WinMain()
// Desc: The application's entry point
//-----------------------------------------------------------------------------
INT WINAPI WinMain( HINSTANCE hInst, HINSTANCE, LPSTR, INT )
{
    // Register the window class
    WNDCLASSEX wc = { sizeof(WNDCLASSEX), CS_CLASSDC, MsgProc, 0L, 0L,
                      GetModuleHandle(NULL), NULL, NULL, NULL, NULL,
                      "D3D Tutorial", NULL };
    RegisterClassEx( &wc );
 
    // Create the application's window
    HWND hWnd = CreateWindow( "D3D Tutorial", "D3D Tutorial 05: Textures",
                              WS_OVERLAPPEDWINDOW, 100, 100, 300, 300,
                              GetDesktopWindow(), NULL, wc.hInstance, NULL );
 
    // Initialize Direct3D
    if( SUCCEEDED( InitD3D( hWnd ) ) )
    {
        // Create the scene geometry
        if( SUCCEEDED( InitGeometry() ) )
        {
            // Show the window
            ShowWindow( hWnd, SW_SHOWDEFAULT );
            UpdateWindow( hWnd );
 
            // Enter the message loop
            MSG msg;
            ZeroMemory( &msg, sizeof(msg) );
            while( msg.message!=WM_QUIT )
            {
                if( PeekMessage( &msg, NULL, 0U, 0U, PM_REMOVE ) )
                {
                    TranslateMessage( &msg );
                    DispatchMessage( &msg );
                }
                else
                    Render();
            }
        }
    }
 
    UnregisterClass( "D3D Tutorial", wc.hInstance );
    return 0;
}
