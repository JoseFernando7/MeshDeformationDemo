using UnityEngine;

[RequireComponent(typeof(MeshFilter))]
public class DeformableGrid : MonoBehaviour
{
  [SerializeField] private int width = 50;
  [SerializeField] private int height = 50;
  [SerializeField] private float size = 10f;

  private void Awake()
  {
    GenerateGrid();
  }

  private void GenerateGrid()
  {
    Mesh mesh = new Mesh();
    mesh.name = "Deformable Grid";

    int vertexCount = (width + 1) * (height + 1);

    Vector3[] vertices = new Vector3[vertexCount];
    Vector2[] uv = new Vector2[vertexCount];
    int[] triangles = new int[width * height * 6];

    // Create vertices
    for (int z = 0; z <= height; z++)
    {
      for (int x = 0; x <= width; x++)
      {
        int index = z * (width + 1) + x;

        float xPosition = ((float)x / width - 0.5f) * size;
        float zPosition = ((float)z / height - 0.5f) * size;

        vertices[index] = new Vector3(
            xPosition, 0f, zPosition
        );

        uv[index] = new Vector2(
            (float)x / width,
            (float)z / height
        );
      }
    }

    // Create Triangles
    int triangleIndex = 0;

    for (int z = 0; z < height; z++)
    {
      for (int x = 0; x < width; x++)
      {
        int current = z * (width + 1) + x;
        int next = current + width + 1;

        triangles[triangleIndex++] = current;
        triangles[triangleIndex++] = next;
        triangles[triangleIndex++] = current + 1;

        triangles[triangleIndex++] = current + 1;
        triangles[triangleIndex++] = next;
        triangles[triangleIndex++] = next + 1;
      }
    }

    mesh.vertices = vertices;
    mesh.uv = uv;
    mesh.triangles = triangles;

    mesh.RecalculateNormals();

    GetComponent<MeshFilter>().mesh = mesh;
  }
}
