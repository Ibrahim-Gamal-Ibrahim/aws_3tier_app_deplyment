import os
import json
import base64
import urllib.parse
import urllib.request


def lambda_handler(event, context):

    print("Received event:")
    print(json.dumps(event))

    instance_id = event["detail"]["EC2InstanceId"]

    jenkins_url = os.environ["JENKINS_URL"]
    job_name = os.environ["JENKINS_JOB"]
    username = os.environ["JENKINS_USER"]
    api_token = os.environ["JENKINS_API_TOKEN"]

    params = urllib.parse.urlencode({
        "INSTANCE_ID": instance_id
    })

    url = (
        f"{jenkins_url}/job/{job_name}/buildWithParameters"
        f"?{params}"
    )

    credentials = f"{username}:{api_token}"

    encoded_credentials = base64.b64encode(
        credentials.encode()
    ).decode()

    request = urllib.request.Request(
        url,
        method="POST"
    )

    request.add_header(
        "Authorization",
        f"Basic {encoded_credentials}"
    )

    print(f"Triggering Jenkins for instance {instance_id}")

    with urllib.request.urlopen(request, timeout=10) as response:

        print(f"Jenkins response: {response.status}")

        return {
            "statusCode": response.status,
            "instanceId": instance_id
        }