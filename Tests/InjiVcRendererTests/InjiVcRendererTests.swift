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
}
