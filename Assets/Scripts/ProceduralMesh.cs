using UnityEngine;
using System.Collections.Generic;

public class ProceduralMesh : MonoBehaviour
{
    [SerializeField] int width;
    [SerializeField] int height;
    [SerializeField] int resolution;
    [SerializeField] float frequency;
    [SerializeField] float amplitude;
    [SerializeField, Range(0.0f, 1.0f)] float steepness = 0.5f;
    [SerializeField] float heightFactor = 1.0f;
    [SerializeField] float speed;
    [SerializeField] int numWaves;
    [SerializeField] int seed = 0;
    [SerializeField] int seedOffset = 25;
    [SerializeField] Vector2 direction;
    [SerializeField] Color tint = Color.white;
    [SerializeField] Color specularTint = Color.white;
    void OnEnable()
    {
        var mesh = new Mesh
        {
            name = "Procedural Mesh"
        };

        List<Vector3> vertices = new List<Vector3>();
        List<Vector3> normals = new List<Vector3>();
        List<Vector4> tangents = new List<Vector4>();
        List<Vector2> uvs = new List<Vector2>();
        List<int> indices = new List<int>();

        float widthStep = (float)width / (float)resolution;
        float heightStep = (float)height / (float)resolution;

        for (float i = 0.0f; i <= height; i += heightStep)
        {
            for (float j = 0.0f; j <= width; j += widthStep)
            {
                vertices.Add(new Vector3(j, 0.0f, i));
                normals.Add(new Vector3(0.0f, 1.0f, 0.0f));
                tangents.Add(new Vector4(1f, 0f, 0f, -1f));
                uvs.Add(new Vector2(j / width, i / height));
            }
        }

        for (int i = 0; i < resolution; i++)
        {
            for (int j = 0; j < resolution; j++)
            {
                int index = j + ((resolution + 1) * i);

                indices.Add(index);
                indices.Add(index + (resolution + 1));
                indices.Add(index + 1);

                indices.Add(index + 1);
                indices.Add(index + (resolution + 1));
                indices.Add(index + (resolution + 1) + 1);
            }
        }

        mesh.vertices = vertices.ToArray();

        mesh.normals = normals.ToArray();

        mesh.tangents = tangents.ToArray();

        mesh.uv = uvs.ToArray();

        mesh.triangles = indices.ToArray();

        GetComponent<MeshFilter>().mesh = mesh;

        Material material = GetComponent<MeshRenderer>().material;
        material.SetFloat("_Frequency", frequency);
        material.SetFloat("_Amplitude", amplitude);
        material.SetFloat("_Speed", speed);
        material.SetFloat("_Steepness", steepness);
        material.SetFloat("_HeightFactor", heightFactor);
        material.SetInteger("_NumWaves", numWaves);
        material.SetInteger("_Seed", seed);
        material.SetInteger("_SeedOffset", seedOffset);
        material.SetVector("_Direction", new Vector4(direction.x, direction.y, 0.0f, 0.0f));
        material.SetColor("_Tint", tint);
        material.SetColor("_SpecularTint", specularTint);
	}
}
