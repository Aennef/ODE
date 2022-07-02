Shader "Custom/InstancedIndirectColor" {

    Properties {
	_MainTex("MainTex",2D) = "white"{} 
    _SecondTex("SecondTex",2D) = "white"{} 

	}
    

    SubShader {

        
        Pass {

            Name "INSTANCEfirstpass"
            Tags { "Queue"="Transparent" "RenderType" = "Opaque" }
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            

            #include "UnityCG.cginc"

            struct appdata_t {
                float4 vertex   : POSITION;
                float4 color    : COLOR;
            };

            struct v2f {
                float4 vertex   : SV_POSITION;
                fixed4 color    : COLOR;
            }; 

            struct MeshProperties {
                float4x4 mat;
                float4 color;
            };

            StructuredBuffer<MeshProperties> _Properties;

            v2f vert(appdata_t i, uint instanceID: SV_InstanceID) {
                v2f o;

                float4 pos = mul(_Properties[instanceID].mat, i.vertex);
                o.vertex = UnityObjectToClipPos(pos);
                o.color = _Properties[instanceID].color;
                
                return o;
            }

            fixed4 frag(v2f i) : SV_Target {
                return i.color;
            }

             ENDCG


        }


	     Pass {                

              Name "FEEDBACKsecondpass"
              Tags { "Queue"="Transparent" "RenderType" = "Opaque" }

              // ShaderLab commands to set the render state go here

               //HLSLPROGRAM

                ZWrite Off
	            Blend SrcAlpha OneMinusSrcAlpha

               CGPROGRAM

	            #pragma vertex vert
	            #pragma fragment frag

	            #include "UnityCG.cginc"
			
    

                float4 vec4(float x,float y,float z,float w){return float4(x,y,z,w);}
                float4 vec4(float x){return float4(x,x,x,x);}
                float4 vec4(float2 x,float2 y){return float4(float2(x.x,x.y),float2(y.x,y.y));}
                float4 vec4(float3 x,float y){return float4(float3(x.x,x.y,x.z),y);}


                float3 vec3(float x,float y,float z){return float3(x,y,z);}
                float3 vec3(float x){return float3(x,x,x);}
                float3 vec3(float2 x,float y){return float3(float2(x.x,x.y),y);}

                float2 vec2(float x,float y){return float2(x,y);}
                float2 vec2(float x){return float2(x,x);}

                float vec(float x){return float(x);}
    
    

	            struct VertexInput {
                float4 vertex : POSITION;
	            float2 uv:TEXCOORD0;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
	            //VertexInput
	            };
	            struct VertexOutput {
	            float4 pos : SV_POSITION;
	            float2 uv:TEXCOORD0;
	            //VertexOutput
	            };
	            sampler2D _MainTex; 
                sampler2D _SecondTex; 

	
	            VertexOutput vert (VertexInput v)
	            {
	            VertexOutput o;
	            o.pos = UnityObjectToClipPos (v.vertex);
	            o.uv = v.uv;
	            //VertexFactory
	            return o;
	            }
    
    
    
	            fixed4 frag(VertexOutput vertex_output) : SV_Target
	            {
	
                float2 res = 1;
                float2 tc = vertex_output.uv / res;
                float2 uv = tc;
    
                uv *= 0.998;
    
                float4 sum = tex2D(_SecondTex, uv);
                float4 src = tex2D(_MainTex, tc);
    
                sum.rgb = lerp(sum.rbg, src.rgb, 0.01);
                return sum;
                }

                //void mainImage( out float4 fragColor, in float2 vertex_output.uv )
                //{
	            //float2 uv = vertex_output.uv / 1;
	            //return tex2D(_MainTex, uv);

	            //}

	            ENDCG

	            }

        }
    }