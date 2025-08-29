import XCTest

@testable import InjiVcRenderer

final class InjiVcRendererTests: XCTestCase {

    var renderer: InjiVcRenderer!

    

    override func setUp() {
        super.setUp()
        renderer = InjiVcRenderer()
    }

    override func tearDown() {
        renderer = nil
        super.tearDown()
    }
    
    
    

    func testRenderSvgForMissingRenderMethod() {
        let vcJson = """
            { 
                "someField": "someValue" 
            }
        """

        let result = renderer.renderSvg(vcJsonString: vcJson)

        XCTAssertEqual(result, [])
    }
    
    func testRenderSvgForInvalidRenderMethod() {
        let vcJson = """
        {
            "credentialSubject": {
                "addressLine1": "test"
            },
            "renderMethod": [ "invalid" ]
        }
        """

        let result = renderer.renderSvg(vcJsonString: vcJson)

        XCTAssertEqual(result, [])
    }
    
    func testRenderSvgForRenderMethodAsEmptyObject() {
        let vcJson = """
        {
            "credentialSubject": {
                "addressLine1": "test"
            },
            "renderMethod": {}
        }
        """

        let result = renderer.renderSvg(vcJsonString: vcJson)

        XCTAssertEqual(result, [])
    }
    
    func testRenderSvgForRenderMethodAsEmptyArray() {
        let vcJson = """
        {
            "credentialSubject": {
                "addressLine1": "test"
            },
            "renderMethod": []
        }
        """

        let result = renderer.renderSvg(vcJsonString: vcJson)

        XCTAssertEqual(result, [])
    }
    
    func testRenderSvgForRenderMethodArrayWithInvalidRenderSuite() {
        let vcJson = """
              {
                "renderMethod": [
                   { "type": "TemplateRenderMethod", "renderSuite": "invalid-suite" }
                ]
            }
        """

        let result = renderer.renderSvg(vcJsonString: vcJson)

        XCTAssertEqual(result, [])
    }
    
    func testRenderSvgForRenderMethodArrayWithType() {
        let vcJson = """
        {
           "renderMethod": [
              { "type": "invalid", "renderSuite": "svg-mustache" }
           ]
        }
        """

        let result = renderer.renderSvg(vcJsonString: vcJson)

        XCTAssertEqual(result, [])
    }
    
    func testRenderSvgForRenderMethodObjectWithInvalidRenderSuite() {
        let vcJson = """
              {
                "renderMethod": { "type": "TemplateRenderMethod", "renderSuite": "invalid-suite" }
            }
        """

        let result = renderer.renderSvg(vcJsonString: vcJson)

        XCTAssertEqual(result, [])
    }
    
    func testRenderSvgForRenderMethodObjectWithType() {
        let vcJson = """
        {
           "renderMethod": { "type": "invalid", "renderSuite": "svg-mustache" }
        }
        """

        let result = renderer.renderSvg(vcJsonString: vcJson)

        XCTAssertEqual(result, [])
    }
    
    func testRenderSvgForRenderMethodObject_EmbeddedSingleVc() {
        //Embedded SVG Template is<svg>Full Name - {{/credentialSubject/fullName}}</svg>
        let vcJson = """
         { 
                "credentialSubject": {
                    "fullName": "John Doe"
                },
                "renderMethod": {
                    "type": "TemplateRenderMethod",
                    "renderSuite": "svg-mustache",
                    "template": "data:image/svg+xml;base64,PHN2Zz5GdWxsIE5hbWUgLSB7ey9jcmVkZW50aWFsU3ViamVjdC9mdWxsTmFtZX19PC9zdmc+"
                  }
              }
        """

        let result = renderer.renderSvg(vcJsonString: vcJson)

        XCTAssertEqual(result, ["<svg>Full Name - John Doe</svg>"])
    }
    
    
    
    func testRenderSvgForRenderMethodArray_EmbeddedMultipleRenderMethod() {
        //Embedded SVG Template is <svg>Full Name - {{/credentialSubject/fullName}}</svg>, <svg>Email - {{/credentialSubject/email}}</svg>
        let vcJson = """
            { 
                "credentialSubject": {
                    "fullName": "John Doe",
                    "email": "test@gmail.com"
                },
                "renderMethod": [
                  {
                    "type": "TemplateRenderMethod",
                    "renderSuite": "svg-mustache",
                    "template": "data:image/svg+xml;base64,PHN2Zz5GdWxsIE5hbWUgLSB7ey9jcmVkZW50aWFsU3ViamVjdC9mdWxsTmFtZX19PC9zdmc+"
                  },
                  {
                    "type": "TemplateRenderMethod",
                    "renderSuite": "svg-mustache",
                    "template": "data:image/svg+xml;base64,PHN2Zz5FbWFpbCAtIHt7L2NyZWRlbnRpYWxTdWJqZWN0L2VtYWlsfX08L3N2Zz4="
                  }
              ]
              }
        """

        let result = renderer.renderSvg(vcJsonString: vcJson)

        XCTAssertEqual(result, ["<svg>Full Name - John Doe</svg>", "<svg>Email - test@gmail.com</svg>"])
    }
    
    func testRenderSvgForRenderMethodArray_EmbeddedMultipleRenderMethodWithOneInvalidType() {
        //Embedded SVG Template is <svg>Email - {{/credentialSubject/email}}</svg>
        let vcJson = """
             { 
                "credentialSubject": {
                    "fullName": "John Doe",
                    "email": "test@gmail.com"
                },
                "renderMethod": [
                  {
                    "type": "invalid",
                    "renderSuite": "svg-mustache",
                    "template": "data:image/svg+xml;base64,PHN2Zz48dGV4dD5Gcm9udCBOYW1lIC0ge3tjcmVkZW50aWFsU3ViamVjdC9mdWxsTmFtZX19PC90ZXh0Pjwvc3ZnPg=="
                  },
                  {
                    "type": "TemplateRenderMethod",
                    "renderSuite": "svg-mustache",
                    "template": "data:image/svg+xml;base64,PHN2Zz5FbWFpbCAtIHt7L2NyZWRlbnRpYWxTdWJqZWN0L2VtYWlsfX08L3N2Zz4="
                  }
              ]
              }
        """

        let result = renderer.renderSvg(vcJsonString: vcJson)

        XCTAssertEqual(result, ["<svg>Email - test@gmail.com</svg>"])
    }
    
    func testRenderSvgForRenderMethodArray_EmbeddedMultipleRenderMethodWithOneInvalidUri() {
        //Embedded SVG Template is <svg>Email - {{/credentialSubject/email}}</svg>
        let vcJson = """
              { 
                "credentialSubject": {
                    "fullName": "John Doe",
                    "email": "test@gmail.com"
                },
                "renderMethod": [
                  {
                    "type": "TemplateRenderMethod",
                    "renderSuite": "svg-mustache",
                    "template": "data:image/svg+xml;base64,@@@INVALIDBASE64###!!!"
                  },
                  {
                    "type": "TemplateRenderMethod",
                    "renderSuite": "svg-mustache",
                    "template": "data:image/svg+xml;base64,PHN2Zz5FbWFpbCAtIHt7L2NyZWRlbnRpYWxTdWJqZWN0L2VtYWlsfX08L3N2Zz4="
                  }
              ]
              }
        """

        let result = renderer.renderSvg(vcJsonString: vcJson)

        XCTAssertEqual(result, ["<svg>Email - test@gmail.com</svg>"])
    }
    
    func testRenderSvgForRenderMethodArray_EmbeddedMultipleRenderMethodWithAllInvalidUri() {
        let vcJson = """
         { 
                "credentialSubject": {
                    "fullName": "John Doe",
                    "email": "test@gmail.com"
                },
                "renderMethod": [
                  {
                    "type": "TemplateRenderMethod",
                    "renderSuite": "svg-mustache",
                    "template": "data:image/svg+xml;base64,@@@INVALIDBASE64###!!!"
                  },
                  {
                    "type": "TemplateRenderMethod",
                    "renderSuite": "svg-mustache",
                    "template": "data:image/svg+xml;base64,@@@INVALIDBASE64###!!!"
                  }
              ]
              }
        """

        let result = renderer.renderSvg(vcJsonString: vcJson)

        XCTAssertEqual(result, [])
    }
    
    
    
    func testRenderSvgForRenderMethodObject_PlaceholderNotInVC() {
        //Embedded SVG Template is <svg>Full Name - {{/credentialSubject/fullName}}</svg>
        let vcJson = """
              { 
                "credentialSubject": {
                    "middleName": "John Doe"
                },
                "renderMethod": {
                    "type": "TemplateRenderMethod",
                    "renderSuite": "svg-mustache",
                    "template": "data:image/svg+xml;base64,PHN2Zz5GdWxsIE5hbWUgLSB7ey9jcmVkZW50aWFsU3ViamVjdC9mdWxsTmFtZX19PC9zdmc+"
                  }
              }
        """

        let result = renderer.renderSvg(vcJsonString: vcJson)

        XCTAssertEqual(result, ["<svg>Full Name - -</svg>"])
    }
    
    func testRenderSvgForRenderMethodObjectWithQrPlaceholder() {
        //Embedded SVG Template is <svg>{{/qrCodeImage}}</svg>
        let vcJson = """
              { 
                "credentialSubject": {
                    "middleName": "John Doe"
                },
                "renderMethod": {
                    "type": "TemplateRenderMethod",
                    "renderSuite": "svg-mustache",
                    "template": "data:image/svg+xml;base64,PHN2Zz57ey9xckNvZGVJbWFnZX19PC9zdmc+"
                  }
              }
        """

        let result = renderer.renderSvg(vcJsonString: vcJson)

        XCTAssertEqual(result, ["<svg>data:image/png;base64,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</svg>"])
    }
    
    
}
