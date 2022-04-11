public protocol Entity {

    static var type: String { get }
    var version: EntityVersion { get }
    var unpublishedEvents: [UnpublishedEvent] { get }

    init(version: EntityVersion)

    func apply(_ event: PublishedEvent)

}
