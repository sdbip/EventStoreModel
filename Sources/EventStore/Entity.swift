public protocol Entity {

    var version: Int32 { get }

    init(version: Int32)

    func apply(_ event: PublishedEvent)

}
