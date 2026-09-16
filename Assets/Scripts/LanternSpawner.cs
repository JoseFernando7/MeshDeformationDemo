using UnityEngine;

public class LanternSpawner : MonoBehaviour
{
    [Header("Lantern")]
    [SerializeField] private GameObject lanternPrefab;
    [SerializeField] private int lanternCount = 10;

    [Header("Spawn Area")]
    [SerializeField] private Vector2 xRange = new Vector2(-9f, 11f);
    [SerializeField] private Vector2 yRange = new Vector2(-1.4f, 2.3f);
    [SerializeField] private Vector2 zRange = new Vector2(-4.7f, 12f);

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        SpawnLanterns();
    }

    private void SpawnLanterns()
    {
        for (int i = 0; i < lanternCount; i++)
        {
            Vector3 spawnPosition = new Vector3(
                Random.Range(xRange.x, xRange.y),
                Random.Range(yRange.x, yRange.y),
                Random.Range(zRange.x, zRange.y)
            );

            Instantiate(lanternPrefab, spawnPosition, Quaternion.identity, transform);
        }
    }
}
