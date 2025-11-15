# New-AwsSamlProfile

`New-AwsSamlProfile` is a PowerShell function that configures AWS CLI profiles by [assuming IAM roles using SAML assertions](https://repost.aws/knowledge-center/aws-cli-call-store-saml-credentials). This enables automated configuration of AWS profiles in SSO/federated authentication environments.

---

## Prerequisites

Before using this function, ensure the following:

- **[AWS CLI v2](https://aws.amazon.com/cli/)** is installed  
  - Default installation path:  
    `C:\Program Files\Amazon\AWSCLIV2\aws.exe`
- IAM roles and SAML identity providers (IdPs) are properly configured in AWS
- You have the correct **Role ARN** and **Identity Provider ARN**
- You have a valid **[Base64-encoded SAML Assertion](https://docs.aws.amazon.com/IAM/latest/UserGuide/troubleshoot_saml_view-saml-response.html)**

---

## Installation

Save the function to a `.ps1` file and import it into your PowerShell session:

```powershell
. .\New-AwsSamlProfile.ps1
```

---

## Parameters

| Parameter | Required | Description |
|----------|----------|-------------|
| **ProfileName** | Yes | Name of the AWS CLI profile to configure |
| **RoleArn** | Yes | ARN of the IAM role to assume |
| **PrincipalArn** | Yes | ARN of the identity provider |
| **SamlAssertion** | Yes | Base64-encoded SAML assertion |
| **Region** | Yes | AWS region for the profile |
| **DeleteExistingConfig** | No | Deletes `~/.aws/credentials` before configuration |

---

## Usage

**Important:**  
The SAML assertion is a *sensitive security token* that grants temporary AWS access. It **should never be typed directly into the command line**, because anything entered there is stored in PowerShell history and may be recoverable. Always use a secure input method.

---

### Secure Use with `Get-Clipboard`

### Step 1 — Copy Your SAML Assertion

1. Obtain your Base64-encoded SAML assertion from your identity provider.
2. Highlight the assertion and copy it to your clipboard.

The assertion now resides only in memory.

---

### Step 2 — Pass the Assertion to the Script Using `Get-Clipboard`

```powershell
$saml = Get-Clipboard

New-AwsSamlProfile `
    -ProfileName "MyProfile" `
    -RoleArn "arn:aws:iam::123456789012:role/MyRole" `
    -PrincipalArn "arn:aws:iam::123456789012:saml-provider/MySAMLProvider" `
    -SamlAssertion $saml `
    -Region "us-west-2"
```

(Optional) Clear the clipboard after use:

```powershell
Set-Clipboard ""
```

---

## Function Behavior

`New-AwsSamlProfile` performs the following steps:

1. Deletes existing AWS credentials (if `-DeleteExistingConfig` is used).
2. Creates or updates the specified AWS CLI profile and sets the region.
3. Calls `sts assume-role-with-saml` using the provided Role ARN, Principal ARN, and SAML Assertion.
4. Retrieves and configures temporary AWS credentials:
   - `aws_access_key_id`
   - `aws_secret_access_key`
   - `aws_session_token`
5. Displays the caller identity using `sts get-caller-identity` for validation.
6. Writes status messages to the console for visibility and troubleshooting.

---
