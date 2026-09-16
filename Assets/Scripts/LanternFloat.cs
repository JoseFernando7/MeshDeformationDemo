using UnityEngine;

public class LanternFloat : MonoBehaviour
{
    [Header("Movement")]
    [SerializeField] private float verticalMovement = 1.0f;

    [SerializeField] private float speed = 1.0f;

    private Vector3 startPosition;

    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        startPosition = transform.position;
    }

    // Update is called once per frame
    void Update()
    {
        float offset = Mathf.Sin(Time.time * speed) * verticalMovement;

        transform.position = startPosition + Vector3.up * offset;
    }
}
