import UIKit
import InjiVcRenderer

class ViewController: UIViewController {
    
    private var renderedSvg: String = ""
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        let renderer = InjiVcRenderer("sample-app")
        let insuranceVc = """
        {
            "credentialSubject": {
                "policyName": "Policy Name",
                "policyNumber": "123456",
                "fullName": "John Doe",
                "gender": "Male",
                "email": "john.doe@example.com",
                "mobile": "1234567890",
                "policyIssuedOn": "2024-07-01",
                "policyExpiresOn": "2024-12-31",
                "benefits": [
                    "Critical Surgery",
                    "Full body checkup"
                ]
            },
            "issuanceDate": "2024-05-09T09:10:05.450Z",
            "expirationDate": "2024-12-31T23:59:59.999Z",
        
             "renderMethod": [{
                  "id": "https://<host-url>/insurance_svg_template.svg",
                  "type": "SvgRenderingTemplate",
                  "name": "Portrait Mode",
                  "css3MediaQuery": "@media (orientation: portrait)",
                  "digestMultibase": "zQmAPdhyxzznFCwYxAp2dRerWC85Wg6wFl9G270iEu5h6JqW"
                }]
        }
        """
        
        let testVc = """
         {
                "@context": [
                    "https://credentials/v1",
                    "https:///.well-known/ida.json",
                    {
                        "sec": "https://security#"
                    }
                ],
                "credentialSubject": {
                    "benefits": ["item1 on the list", "item2 on the list", "item3 on the list"],
                    "face": "data:image/jpeg;base64,/9j/4",
                    "gender": [
                        {
                            "language": "eng",
                            "value": "MLE"
                        }
                    ],
                    "phone": "+++7765837077",
                    "city": [
                        {
                            "language": "eng",
                            "value": "TEST_CITYeng"
                        }
                    ],
                    "fullName": [
                        {
                            "language": "eng",
                            "value": "TEST_FULLNAMEeng"
                        }
                    ],
                    "addressLine1": [
                        {
                            "language": "eng",
                            "value": "TEST_ADDRESSLINE1eng"
                        }
                    ],
                    "dateOfBirth": "1992/04/15",
                    "id": "did:jwk:eyJrdHkiOiJSU0EiL",
                    "email": "mosipuser123@mailinator.com"
                },
                "id": "https://test.net/credentials/abcdefgh-a",
                "issuanceDate": "2024-09-02T17:36:13.644Z",
                "issuer": "https://test.netf/.well-known/controller.json",
                "proof": {
                    "created": "2024-09-02T17:36:13Z",
                    "jws": "eyJiNj"
                    "proofPurpose": "assertionMethod",
                    "type": "RsaSignature2018",
                    "verificationMethod": "https://test/.well-known/public-key.json"
                },
                "type": [
                    "VerifiableCredential",
                    "TestVerifiableCredential"
                ],
                "renderMethod": [
                    {
                        "id": "https://<svg-host-url>/assets/templates/national_id_template.svg",
                        "type": "SvgRenderingTemplate",
                        "name": "Portrait Mode"
                    }
                ]
            }
        """
        
        Task {
            let svg = await renderer.renderVC(vcJsonString: testVc)
            print("Rendered SVG: \(svg)")
        }
    }
}
