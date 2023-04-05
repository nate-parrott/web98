import Foundation

struct Gifs {
    var namesToURLs: [String: String]
    static let shared = Gifs(namesToURLs: [
        "Email3D": "https://web.archive.org/web/20090830063639/http://geocities.com/computerdivawv/3demail.gif",
        "SmashingComputer": "https://web.archive.org/web/20090829015037/http://www.geocities.com/nukinight2001/smashingcomputer.gif",
        "BirdL": "https://web.archive.org/web/20090831084926if_/http://geocities.com/coptics33/animate/birdl.gif",
        "InternetExplorer": "https://web.archive.org/web/20091024235337im_/http://geocities.com/powderplayers/images2/ie.gif",
        "AWishFor": "https://web.archive.org/web/20091025154931if_/http://www.geocities.com/madisonpaigetuzzio/AWishfor.gif",
        "Collectors": "https://web.archive.org/web/20090902115704if_/http://www.geocities.com/sjc_ollectors/0157.gif",
        "Belongs": "https://web.archive.org/web/20091027113454if_/http://www.geocities.com/melissafamily/belongs.gif",
        "Coffee3": "https://web.archive.org/web/20090729051521if_/http://www.geocities.com/regularguyswinery/coffee3.gif",
        "UnderConstruction": "https://web.archive.org/web/20091024235037if_/http://www.geocities.com/winnipegbluebombers2003/Undercomstruction.gif",
        "Mail03B": "https://web.archive.org/web/20090727105513if_/http://it.geocities.com/studiocasentini/mail03b.gif",
        "Keys": "https://web.archive.org/web/20090903044712if_/http://geocities.com/petsburgh/3739/races/keys.gif",
        "Key": "https://web.archive.org/web/20091026191655if_/http://geocities.com/nvrsurrender/key.gif",
        "ForkStabSpoon": "https://web.archive.org/web/20091022120522if_/http://www.geocities.com/mockswyrm/goth/forkstabspoon.gif",
        "ILoveYou": "https://web.archive.org/web/20090806132629if_/http://www.geocities.com/blueyegurlx101/i_loveyou_1_.gif",
        "New1": "https://web.archive.org/web/20090727081729if_/http://www.geocities.com/case_ross/new1.gif",
        "GuitarAnim": "https://web.archive.org/web/20091027131807if_/http://geocities.com/crimescenelive/page/guitaranim.gif",
        "Heart2": "https://web.archive.org/web/20090830131600if_/http://geocities.com/BourbonStreet/Delta/9353/heart2.gif"
    ])

    var ids: [String] {
        Array(namesToURLs.keys.sorted())
    }

    var allShortURLs: [String] {
        ids.map { shortURL(forName: $0) }
    }

    func shortURL(forName name: String) -> String {
        // Output a short url like "/gifs/Email3D"
        "/gifs/\(name).gif"
    }

    func replaceShortURLsWithLongURLs(inString string: String) -> String {
        // Replace "/gifs/Email3D" with "https://web.archive.org/web/20090830063639/http://geocities.com/computerdivawv/3demail.gif"
        let regex = try! NSRegularExpression(pattern: "/gifs/([a-zA-Z0-9]+).gif")
        let range = NSRange(location: 0, length: string.utf16.count)
        let matches = regex.matches(in: string, range: range)
        var result = string
        for match in matches.reversed() {
            let nameRange = match.range(at: 1)
            let name = (result as NSString).substring(with: nameRange)
            if let url = namesToURLs[name] {
                result = result.replacingOccurrences(of: "/gifs/\(name).gif", with: url)
            }
        }
        return result
    }
}
