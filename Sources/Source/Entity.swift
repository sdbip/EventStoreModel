public protocol Entity {

    static var type: String { get }
    var version: EntityVersion { get }

    init(version: EntityVersion)

    func apply(_ event: PublishedEvent)

}
