using Unity.Collections.LowLevel.Unsafe;
using UnityEngine;
using UnityEngine.UI;

public class DrawMeshInstance : MonoBehaviour
{
    [SerializeField] ParticleSystem ps;
    [SerializeField] ParticleSystem.Particle[] particles;
    //Draw Mesh
    public int population;
    [Range(0, 1000f)] [SerializeField] private float pointDepth;
    [Range(0, 1f)] [SerializeField] private float depthSelector;
    public Material material;

    private ComputeBuffer meshPropertiesBuffer;
    private ComputeBuffer argsBuffer;

    [SerializeField] private Mesh mesh;
    private Vector3 scale;
    [Range(0, 10f)] [SerializeField] private float scaleController;

    private Bounds bounds;
    MeshProperties[] properties;

    [SerializeField] DepthVideo videoTexture;
    // Mesh Properties struct to be read from the GPU.
    // Size() is a convenience funciton which returns the stride of the struct.
    private struct MeshProperties
    {
        public Matrix4x4 mat;
        public Vector4 color;

        public static int Size()
        {
            return
                sizeof(float) * 4 * 4 + // matrix;
                sizeof(float) * 4;      // color;
        }
    }

    private void Setup()
    {
        var main = ps.main;
        main.maxParticles = videoTexture.resolution;
        var emission = ps.emission;
        emission.rateOverTime = videoTexture.resolution;
        
        //setup resolution
        population = videoTexture.resolution;
        // Boundary surrounding the meshes we will be drawing.  Used for occlusion.
        bounds = new Bounds(transform.position, Vector3.one * (pointDepth + 1));

        InitializeBuffers();
    }

    private void InitializeBuffers()
    {
        // Argument buffer used by DrawMeshInstancedIndirect.
        uint[] args = new uint[5] { 0, 0, 0, 0, 0 };
        // Arguments for drawing mesh.
        // 0 == number of triangle indices, 1 == population, others are only relevant if drawing submeshes.
        args[0] = (uint)mesh.GetIndexCount(0);
        args[1] = (uint)population;
        args[2] = (uint)mesh.GetIndexStart(0);
        args[3] = (uint)mesh.GetBaseVertex(0);
        argsBuffer = new ComputeBuffer(1, args.Length * sizeof(uint), ComputeBufferType.IndirectArguments);
        argsBuffer.SetData(args);

        // Initialize buffer with the given population.
        properties = new MeshProperties[population];
        

        meshPropertiesBuffer = new ComputeBuffer(population, MeshProperties.Size());
        
    }

    

    private void Start()
    {
        Setup();

        particles = new ParticleSystem.Particle[videoTexture.resolution];
        ps.Emit(videoTexture.resolution);
        ps.GetParticles(particles);

    }

    private void Update()
    {
        
        for (int index_dst = 0, depth_y = 0; depth_y < videoTexture.height_depth; depth_y++)
        {
            for (int depth_x = 0; depth_x < videoTexture.width_depth; depth_x++, index_dst++)
            {



                
                //Mesh
                float depth = videoTexture.colorPixels[index_dst].g * pointDepth;
                particles[index_dst].position = new Vector3(depth_x, depth_y, depth);
                
                particles[index_dst].startColor = videoTexture.colorPixels[index_dst];
                


                MeshProperties props = new MeshProperties();
                Vector3 position = new Vector3(depth_x, depth_y, depth);
                Quaternion rotation = Quaternion.Euler(0, 0, 90);
                

                

                if(videoTexture.colorPixels[index_dst].g > depthSelector)
                {
                    
                    scale = new Vector3(scaleController, scaleController, scaleController);
                    props.mat = Matrix4x4.TRS(position + transform.position, rotation , scale);
                    props.color = videoTexture.colorPixels[index_dst];

                    
                }

                else
                {   
                    
                    particles[index_dst].startColor = new Color(videoTexture.colorPixels[index_dst].r, videoTexture.colorPixels[index_dst].g, videoTexture.colorPixels[index_dst].b, 0);
                }
                
                

                properties[index_dst] = props;

                
            }
        }
        meshPropertiesBuffer.SetData(properties);
        material.SetBuffer("_Properties", meshPropertiesBuffer);
        //Graphics.DrawMeshInstancedIndirect(mesh, 0, material, bounds, argsBuffer);
        //Graphics.DrawMeshInstancedIndirect(mesh, 0, material, bounds, argsBuffer);
        //Graphics.DrawMeshInstancedIndirect(mesh, 0, material, bounds, argsBuffer);
        ps.SetParticles(particles, videoTexture.resolution);
        //var shape = ps.shape;
        //shape.texture = videoTexture.m_DepthTexture_Float;
    }

    private void OnDisable()
    {
        // Release gracefully.
        if (meshPropertiesBuffer != null)
        {
            meshPropertiesBuffer.Release();
        }
        meshPropertiesBuffer = null;

        if (argsBuffer != null)
        {
            argsBuffer.Release();
        }
        argsBuffer = null;
    }




}