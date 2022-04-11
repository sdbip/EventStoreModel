public protocol Entity {

    init()

    func apply(_ event: PublishedEvent)

}
