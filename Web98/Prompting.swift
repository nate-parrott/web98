import Foundation
import OpenAIStreamingCompletions

extension OpenAIAPI {
    static var shared: OpenAIAPI {
        OpenAIAPI(apiKey: UserDefaults.standard.string(forKey: "apiKey") ?? "", orgId: UserDefaults.standard.string(forKey: "orgId")?.nilIfEmptyOrJustWhitespace)
    }
}

let baseModel = "gpt-3.5-turbo"

let baseWorld = """
Pretend it is an alternate-reality version of 1996 where:
- Websites have fun, colorful retro designs, and project a warm and optimistic tone.
- Constantly refer to the internet as the 'information superhighway,' and use words like 'e-meet,' 'portal', and 'global village.'
- Are friendly, eager and happy to help.
"""

func genPrompt(url: URL, world: String) -> [OpenAIAPI.Message] {
    let isPost = url.queryParam(name: "method") == "POST"

    var m = [OpenAIAPI.Message]()
    let gifs = Gifs.shared.allShortURLs.joined(separator: ", ")
    m.append(.init(role: .system, content: """
You are a clever comedian and rich world-builder, acting as an imaginary web server from in an alternate reality.
First, you will be provided with a "world description" describing the imaginary world that the server should pretend to inhabit.
Then, when prompted with a URL, you are to output a valid HTML page that could plausibly represent the requested URL. Output the HTML and only the HTML.

HTML PAGES SHOULD:
- Use simple, concise HTML
- Contain links, tables, headers, hrs, divs, form, marquee, bold and i tags.
- ONLY use <img> tags to refer to GIFs in this list: \(gifs)
- Forms may be included if relevant. All forms should have a descriptive `action` parameter that ends in `.php`
- Be short (only a few paragraphs at most)
- Specify fun, relevant fonts and colors using inline HTML <font> tags and style elements. NO <style> tags in <head>.
  - Any font available on iOS may be used.
- <A> elements should link to websites (which do not need to be real) using descriptive, vivid text in their domains and paths.
- Have colors, fonts and styles which help to establish the world described in the description.

First, here is a description of the alternate universe that the server should pretend it exists within. This world description should dictate inform the content, tone and visual aesthetic of the output HTML.
World description:
"""))
    m.append(.init(role: .user, content: world))
    if isPost {
        m.append(.init(role: .system, content: "OK, now a URL will be provided. This URL is a POST request, meaning that the user triggered this request by submitting a form. Form inputs are provided as query parameters. This output page should reflect the server's (imagined) response to the user's form submission. The responses should provide feedback to the user immediately, rather than simply acknowledging submission. (For example, an imaginary college application form would immediately provide a decision.) Output the resulting HTML (and ONLY html, no commentary) for it."))
    } else {
        m.append(.init(role: .system, content: "OK, now a URL will be provided. Output the resulting HTML only (no commentary). Do not break character."))
    }
    m.append(.init(role: .user, content: url.absoluteString))
    return m
}

func genSearchSuggestionsPrompt(world: String) -> [OpenAIAPI.Message] {
    var m = [OpenAIAPI.Message]()
    m.append(.init(role: .system, content: """
You are a clever comedian and rich world-builder, acting as an imaginary web server from in an alternate reality.
First, you will be provided with a "world description" describing the imaginary world that the server should pretend to inhabit.

First, here is a description of the alternate universe that the server should pretend it exists within.
World description:
"""))
    m.append(.init(role: .user, content: world))
    m.append(.init(role: .system, content: """
Now, please invent and output eight "suggested links" that might exist, and be interesting, WITHIN the described world. Output them as a single JSON array, within a code block, with each on its own line. For example:
```[
"https://nytimes.com",
"https://en.wikipedia.org",
"https://youtube.com",
"https://twitter.com/new"
]``

Your suggested websites should highlight a diverse set of sites that are uniquely interesting in the world that was described. For example, if the world description indicated that we were in Ancient Rome, we might suggest websites relating to the Roman Senate, a Roman restaurant, a Roman 'forum' and a Yahoo Answers-style website for Romans. The suggestions should be generated while pretending you're inside the universe, and should not "break character." For example if the world was "The Harry Potter universe," suggestions would be for websites relevant to the world itself (e.g. 'ministryofmagic.gov.uk), NOT websites from the real world.)

Suggested websites from within this world:
"""))
    return m
}

class Cache {
    static let shared = Cache()
    var cache = [URL: String]()
}
