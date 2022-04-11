public protocol Entity {

    static var type: String { get }
    var version: Int32 { get }

    init(version: Int32)

    func apply(_ event: PublishedEvent)

}
