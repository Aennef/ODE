// Original reference: https://www.shadertoy.com/view/MdlBDn

Shader "Basic Feedback"
{

    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Border("BorderSetting",Range(0,1000)) = 100
        _KeyColor("Key Color", Color) = (0,1,0)
        _Near("Near", Range(0, 2)) = 0.01
    }


    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100
        Cull off

//-------------------------------------------------------------------------------------------

	    Pass
		{
	

            CGINCLUDE

		    #pragma vertex VSMain
		    #pragma fragment PSMain

		    sampler2D _BufferA, _Video;	

		    float4 VSMain (in float4 vertex:POSITION, inout float2 uv:TEXCOORD0) : SV_POSITION
		    {
			    return UnityObjectToClipPos(vertex);
		    }

		    ENDCG
        }
//-------------------------------------------------------------------------------------------
		
		Pass
		{

			CGPROGRAM
			
			void PSMain (float4 vertex:SV_POSITION, float2 uv:TEXCOORD0, out float4 fragColor:SV_TARGET)
			{
				float2 tc = uv;
				float2 uv0 = tc;  
				uv0 *= 0.999;   
				float4 sum = tex2D(_BufferA, uv0);
				float4 src = tex2D(_Video, tc); 
				sum.rgb = lerp(sum.rbg, src.rgb, 0.03);
				fragColor = sum;
				//return sum;
				
			}
			
			ENDCG

		}



//-------------------------------------------------------------------------------------------


		Pass
		{


			CGPROGRAM

			void PSMain (float4 vertex:SV_POSITION, float2 uv:TEXCOORD0, out float4 fragColor:SV_TARGET)
			{

				fragColor = tex2D(_BufferA, uv);
				
			}
			
			ENDCG
        }

//-------------------------------------------------------------------------------------------
        

        Pass
        {
            CGPROGRAM
            //#pragma vertex VSMain
            //#pragma fragment PSMain
            // make fog work
            #pragma multi_compile_fog
            
            #include "UnityCG.cginc"
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };
            sampler2D _MainTex;
            float4 _MainTex_ST;
            half _Border;
            fixed4 _KeyColor;
            half _Near;
            fixed2 bound(fixed2 st, float i)
            {
                fixed2 p = floor(st) + i;
                return p;
            }
                        
            v2f VSMain (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }
            
            fixed4 PSMain (v2f i) : SV_Target
            {
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // Chroma Key
                fixed4 c1 = tex2D (_MainTex, bound(i.uv * _Border, 1)/_Border);
                clip(distance(_KeyColor, c1) - _Near);
                fixed4 c2 = tex2D (_MainTex, bound(i.uv * _Border, 0)/_Border);
                clip(distance(_KeyColor, c2) - _Near);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }

            ENDCG


		}
	}
}