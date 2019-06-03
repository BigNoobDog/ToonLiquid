using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Liquid : MonoBehaviour
{
    public Material LiquidMat;
    public float sinSpeed = 100;
    Vector3 lastPos;
    Vector3 lastA;
    float damping = 1;

    void Start()
    {
        lastPos = transform.position;
        lastA = Vector3.zero;
    }
    
    void Update()
    {
        Vector3 currentDir = transform.position - lastPos;
        if(currentDir.magnitude > (lastA.magnitude * damping))
        {
            lastA = currentDir;
            damping = 1;
        }

        damping *= 0.99f;

        Vector3 sinDir = Mathf.Sin(Time.time * sinSpeed) * lastA * damping;
        LiquidMat.SetVector("_ForceDir", sinDir);
        lastPos = transform.position;
    }
}
