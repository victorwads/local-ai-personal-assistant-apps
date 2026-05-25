import Foundation

protocol ChatListParser: CrawlingParser where Output == [CrawledChat] {}
