using UnityEngine;

public class FloatBoat : MonoBehaviour
{
    [Header("Water")]
    [SerializeField] private float amplitude1 = 0.15f;
    [SerializeField] private float frequency1 = 1.0f;
    [SerializeField] private float speed1 = 0.5f;

    [SerializeField] private float amplitude2 = 0.08f;
    [SerializeField] private float frequency2 = 1.7f;
    [SerializeField] private float speed2 = 0.3f;

    [Header("Float Points")]
    [SerializeField] private Transform frontLeft;
    [SerializeField] private Transform frontRight;
    [SerializeField] private Transform backLeft;
    [SerializeField] private Transform backRight;

    [Header("Buoyancy")]
    [SerializeField] private float buoyancyForce = 10f;
    [SerializeField] private float damping = 1f;

    [SerializeField] private Transform water;

    private Rigidbody rb;

    private void Awake()
    {
        rb = GetComponent<Rigidbody>();
    }

    private void FixedUpdate()
    {
        ApplyBuoyancy(frontLeft);
        ApplyBuoyancy(frontRight);
        ApplyBuoyancy(backLeft);
        ApplyBuoyancy(backRight);
    }

    private void ApplyBuoyancy(Transform floatPoint)
    {
        float waterHeight = GetWaterHeight(floatPoint.position);

        float depth = waterHeight - floatPoint.position.y;

        if (depth > 0f)
        {
            Vector3 velocity = rb.GetPointVelocity(floatPoint.position);

            float verticalVelocity = Vector3.Dot(velocity, Vector3.up);

            float dampingForce = -verticalVelocity * damping;

            float force = depth * buoyancyForce + dampingForce;

            rb.AddForceAtPosition(Vector3.up * force, floatPoint.position, ForceMode.Force);
        }
    }

    private float GetWaterHeight(Vector3 worldPosition)
    {
        Vector3 localPosition = water.InverseTransformPoint(worldPosition);

        float time = Time.time;

        float wave1 = localPosition.x * frequency1 + time * speed1;

        float wave2 = localPosition.z * frequency2 + time * speed2;

        float localHeight = Mathf.Sin(wave1) * amplitude1 + Mathf.Sin(wave2) * amplitude2;

        Vector3 waterPoint = water.TransformPoint(
            new Vector3(localPosition.x, localHeight, localPosition.z)
        );

        return waterPoint.y;
    }
}
