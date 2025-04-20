## Signing the Connector
1. Follow instructions here https://docs.microsoft.com/en-us/power-query/handlingconnectorsigning
2. You may need to create your own test-certificate for getting a fingerprint (HOWTO is mentioned in the document above)
3. Provide the customer with the fingerprint. https://docs.microsoft.com/en-us/power-bi/connect-data/desktop-trusted-third-party-connectors

## Step by step guide
1. Evaluete mz file with Power Query SDK extention
2. Create self signed certificate:
```powershell
$params = @{
    DnsName = 'www.anodot.com'
    CertStoreLocation = 'Cert:\LocalMachine\My'
}
New-SelfSignedCertificate @params
```

Copy thumbprint from previous step:
```powershell
$mypwd = "<PASSWORD>"
$enc_pwd = ConvertTo-SecureString -String $mypwd -Force -AsPlainText

Get-ChildItem -Path Cert:\LocalMachine\My\<THUMBPINT> |
    Export-PfxCertificate -FilePath .\Anodot.pfx -Password $enc_pwd
```

pack into pqx file:
```powershell
.\tools\MakePQX\MakePQX.exe pack -mz .\bin\AnyCPU\Debug\anodot-powerbi.mez -c .\Anodot.pfx -p $mypwd
```

sign pqx file with a certificate
```powershell
.\tools\MakePQX\MakePQX.exe sign .\anodot-powerbi.pqx -c .\Anodot.pfx -p $mypwd
```

Verify:
```powershell
.\tools\MakePQX\MakePQX.exe verify .\anodot-powerbi.pqx 
```
Should be output:
```json
{
  "SignatureStatus": "Success",
  "CertificateStatus": [
    {
      "Issuer": "CN=www.anodot.com",
      "Thumbprint": "1234******",
      "Subject": "CN=www.anodot.com",
      "NotBefore": "2022-04-20T00:11:09+03:00",
      "NotAfter": "2023-04-20T00:31:09+03:00",
      "Valid": false,
      "Parent": null,
      "Status": "UntrustedRoot"
    }
  ]
}
```

## Useful links:
- Walkthrough: https://docs.microsoft.com/en-us/power-query/samples/trippin/readme
- Samples: https://docs.microsoft.com/en-us/power-query/samplesdirectory
- Video: https://www.youtube.com/watch?v=srQ-DLqhoxM
