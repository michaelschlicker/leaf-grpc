import Core
import Foundation
import XCTest
@testable import template

var workDir: String {
    let parent = #file.characters.split(separator: "/").map(String.init).dropLast().joined(separator: "/")
    let path = "/\(parent)/../../Resources/"
    return path
}

func loadTemplate(named: String) throws -> Template {
    let helloData = NSData(contentsOfFile: workDir + "\(named).vt")!
    var bytes = Bytes(repeating: 0, count: helloData.length)
    helloData.getBytes(&bytes, length: bytes.count)
    return try Template(raw: bytes.string)
}

/*
extension Template {
    init(raw: String, components: [Component]) {
        self.raw = raw
        self.components = components
    }
}
*/

class TemplateLoadingTests: XCTestCase {
    func testBasicRawOnly() throws {
        let template = try loadTemplate(named: "template-basic-raw")
        XCTAssert(template.components ==  [.raw("Hello, World!\n".bytes)])
    }

    func testBasicInstructions() throws {
        let template = try loadTemplate(named: "template-basic-instructions-no-body")
        // @custom(two, variables, "and one constant")
        let instruction = try Template.Component.Instruction(
            name: "custom",
            parameters: [.variable("two"), .variable("variables"), .constant("and one constant")],
            body: nil
        )

        let expectation: [Template.Component] = [
            .raw("Some raw text here. ".bytes),
            .instruction(instruction),
            .raw("\n".bytes)
        ]
        XCTAssert(template.components ==  expectation)
    }

    func testBasicNested() throws {
        /*
            Here's a basic template and, @command(parameter) {
                now we're in the body, which is ALSO a @template("constant") {
                    and a third sub template with a @(variable)
                }
            }

        */
        let template = try loadTemplate(named: "template-basic-nested")

        let command = try Template.Component.Instruction(
            name: "command",
            // TODO: `.variable(name: `
            parameters: [.variable("parameter")],
            body: "now we're in the body, which is ALSO a @template(\"constant\") {\n\tand a third sub template with a @(variable)\n\t}"
        )

        let expectation: [Template.Component] = [
            .raw("Here's a basic template and, ".bytes),
            .instruction(command),
            .raw("\n".bytes)
        ]
        XCTAssert(template.components ==  expectation)
    }
}

/*
class templateTests: XCTestCase {
    static let allTests = [
        ("testExample", testExample),
    ]

    func testExample() throws {
        let helloData = NSData(contentsOfFile: workDir + "hello-test.vt")!
        var bytes = Bytes(repeating: 0, count: helloData.length)
        helloData.getBytes(&bytes, length: bytes.count)
        let template = try Template(raw: bytes.string)
        print("GOT: \(template)")
        print("")
    }

    func testExtractName() throws {
        var nameBuffer = Buffer("@someName(variable, \"argument\")".bytes)
        let name = try nameBuffer.extractInstructionName()
        XCTAssert(name == "someName")

        let arguments = try nameBuffer.extractArguments()
        XCTAssert(arguments == [.key("variable"), .value("argument")])
    }

    func testExtractBody() throws {
        var bodyBuffer = Buffer("{ hello, body! { sub body } }".bytes)
        let body = try bodyBuffer.extractBody()
        XCTAssert(body == "hello, body! { sub body }")
        print("")
    }

    func testExtractInstruction() throws {
        var instructionBuffer = Buffer("@instruction(variable, \"argument\") { here's a body @(sub-var) }".bytes)
        let instruction = try instructionBuffer.extractInstruction()
        XCTAssert(instruction.name == "instruction")
        XCTAssert(instruction.arguments == [.key("variable"), .value("argument")])
        XCTAssert("\(instruction.body)" == "Optional(template.Template)")
    }

    func testComponents1() throws {
        let withCommand = "raw component followed by @command(self)"
        var withCommandBuffer = Buffer(withCommand.bytes)
        let comps = try withCommandBuffer.components()
        XCTAssert("\(comps[0])" == "raw(\"raw component followed by \")")
        XCTAssert("\(comps[1])" == "instruction(template.Instruction(name: \"command\", arguments: [template.InstructionArgument.key(\"self\")], body: nil))")
    }

    func testHelloTemplateComponents() throws {
        let helloData = NSData(contentsOfFile: workDir + "hello-test.vt")!
        var bytes = Bytes(repeating: 0, count: helloData.length)
        helloData.getBytes(&bytes, length: bytes.count)
        var template = Buffer(bytes)
        var comps = try template.components()
        print("Comps: \(comps)")
        print("")
    }

    func testBasicRender() throws {
        let templatecontents = "Hello, @(self)!"
        let template = try Template(raw: templatecontents)

        let contextTests = [
            "World",
            "@@",
            "!*7D0"
        ]

        try contextTests.forEach { ctxt in
            let rendered = try template.render(with: ctxt)
            XCTAssert(rendered.string == "Hello, \(ctxt)!")
        }
    }

    func testBasicKeyValueRender() throws {
        let templatecontents = "Hello, @(name)!"
        let template = try Template(raw: templatecontents)

        let contextTests: [[String: Any]] = [
            ["name": "World"],
            ["name": "@@"],
            ["name": "!*7D0"]
        ]

        try contextTests.forEach { ctxt in
            let rendered = try template.render(with: ctxt)
            let name = ctxt["name"] as? String ?? "[fail]"
            XCTAssert(rendered.string == "Hello, \(name)!")
        }
    }

    func testBasicBodyRender() throws {
        let bodyTest = loadResource(named: "body-test")
        let template = try Template(raw: bodyTest.string)

        let contextTests: [[String: Any]] = [
            ["name": "World"],
            ["name": "@@"],
            ["name": "!*7D0"]
        ]

        try contextTests.forEach { ctxt in
            let rendered = try template.render(with: ctxt)
            let name = ctxt["name"] as? String ?? "[fail]"
            XCTAssert(rendered.string == "Hello, \(name)!", "got: **\(rendered.string)** expected: **\("Hello, \(name)!")**")
        }
    }

    func testNestedBodyRender() throws {
        let bodyTest = loadResource(named: "nested-body")
        let template = try Template(raw: bodyTest.string)

        let contextTests: [[String: Any]] = [
            ["best-friend": ["name": "World"]],
            ["best-friend": ["name": "@@"]],
            ["best-friend": ["name": "!*7D0"]]
        ]

        do {
            try contextTests.forEach { ctxt in
                let rendered = try template.render(with: ctxt)
                let name = (ctxt["best-friend"] as! Dictionary<String, Any>)["name"] as? String ?? "[fail]"
                XCTAssert(rendered.string == "Hello, \(name)!", "got: **\(rendered.string)** expected: **\("Hello, \(name)!")**")
            }
        } catch {
            XCTFail("GOT ERROR: \(error)")
        }

        print("")
    }
}
 */
