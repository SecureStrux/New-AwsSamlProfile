function New-AwsSamlProfile {

    <#
.SYNOPSIS
    Configures AWS CLI profiles by assuming roles using SAML assertions.
.DESCRIPTION
    This function configures AWS CLI profiles by assuming roles using SAML assertions.
.PARAMETER ProfileName
    Specifies the name of the AWS CLI profile to be configured.
.PARAMETER RoleArn
    Specifies the Amazon Resource Name (ARN) of the AWS Identity and Access Management (IAM) role to be assumed.
.PARAMETER PrincipalArn
    Specifies the Amazon Resource Name (ARN) of the SAML identity provider (IdP) that describes the federated user who is to assume the role.
.PARAMETER SamlAssertion
    Specifies the base64-encoded SAML assertion that is provided by the identity provider (IdP).
.PARAMETER Region
    Specifies the AWS region for the AWS CLI profile.
.PARAMETER DeleteExistingConfig
    Switch to delete existing AWS CLI credentials files before configuring the profile.
.EXAMPLE
    New-AwsSamlProfile -ProfileName "MyProfile" -RoleArn "arn:aws:iam::123456789012:role/MyRole" `
        -PrincipalArn "arn:aws:iam::123456789012:saml-provider/MySAMLProvider" -SamlAssertion "base64encodedSAMLAssertion" `
        -Region "us-west-2" -DeleteExistingConfig
.NOTES
    - This function assumes that the AWS CLI executable (aws.exe) is located at 'C:\Program Files\Amazon\AWSCLIV2\aws.exe'.
    - Ensure that the AWS CLI is installed and the necessary IAM roles and SAML configurations are set up.
#>

    param(
        [Parameter(Mandatory = $true)]
        [string]$ProfileName,
            
        [Parameter(Mandatory = $true)]
        [string]$RoleArn,
            
        [Parameter(Mandatory = $true)]
        [string]$PrincipalArn,
            
        [Parameter(Mandatory = $true)]
        [string]$SamlAssertion,
            
        [Parameter(Mandatory = $true)]
        [string]$Region,
            
        [switch]$DeleteExistingConfig
    )
    
    # Check if AWS credentials file exists and delete it if DeleteExistingConfig switch is provided
    if ($DeleteExistingConfig) {
    
        Remove-Item "$env:USERPROFILE\.aws\credentials" -Force
    
    }
    
    # Define a hashtable to store AWS profiles with their configurations
    $hashAwsProfiles = @{

        $ProfileName = @{
    
            roleArn      = $RoleArn
            principalArn = $PrincipalArn
            region       = $Region
    
        }
    
    }
    
    # Iterate through each AWS profile in the hashtable
    foreach ($profileEntry in $hashAwsProfiles.GetEnumerator()) {
    
        $ProfileName = $profileEntry.Key
        $profileConfig = $profileEntry.Value
    
        # Display a message indicating the configuration process for the current profile
        Write-Host "Configuring profile for $ProfileName account" -ForegroundColor Green
    
        # Set the AWS CLI region for the current profile
        & 'C:\Program Files\Amazon\AWSCLIV2\aws.exe' configure set region $profileConfig.Region --profile $ProfileName
    
        # Attempt to assume the AWS role using the provided SAML Assertion or standard role assumption
        try {
    
            $assumeRole = & 'C:\Program Files\Amazon\AWSCLIV2\aws.exe' sts assume-role-with-saml --role-arn $profileConfig.roleArn --principal-arn $profileConfig.principalArn --saml-assertion $SamlAssertion --profile $ProfileName 2>$null
                
            # Check if the assume-role operation was successful
            if ($LASTEXITCODE -ne 0) {
    
                throw "Failed to assume the role."
                
            }
    
            # Convert the JSON output to PowerShell object
            $convertRole = $assumeRole | ConvertFrom-Json
    
            # Set the AWS CLI configuration for access key ID, secret access key, and session token
            & 'C:\Program Files\Amazon\AWSCLIV2\aws.exe' configure set aws_access_key_id $convertRole.Credentials.AccessKeyId --profile $ProfileName
            & 'C:\Program Files\Amazon\AWSCLIV2\aws.exe' configure set aws_secret_access_key $convertRole.Credentials.SecretAccessKey --profile $ProfileName
            & 'C:\Program Files\Amazon\AWSCLIV2\aws.exe' configure set aws_session_token $convertRole.Credentials.SessionToken --profile $ProfileName
    
            # Display the AWS identity information for the current profile
            & 'C:\Program Files\Amazon\AWSCLIV2\aws.exe' sts get-caller-identity --profile $ProfileName
    
            # Display a completion message
            Write-Host "Complete!" -ForegroundColor Green
            Write-Host ""
    
        }
        catch {
    
            # Display an error message if assuming the role fails
            Write-Host "An error occurred while assuming the desired role: $_" -ForegroundColor Red
            Write-Host ""
    
        }
    
    }
        
}
    