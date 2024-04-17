# EventStore

A package for using event-sourcing in applications. It is particularly useful when using the CQRS architecture style. The Command side would employ the `Source` target, and the Query side would use the `Projection` target.

# the Source Target

The idea of event sourcing is to not simply store the current *state* of the application, but instead store each historical *change* to the state. We call such changes *events*.

There are some benefits to using this idea; the most obvious ones are perhaps immutability and auditing. When an event has been recorded, that information will itself never change. It makes referring to the data much simpler, and you need never worry about concurrent updates. Every event also records a timestamp and a username. This can be very useful metadata for auditing and where to invest in more education.

Event sourcing also allows creating independent *projections* of the state. You can replay all the changes at any time, and maintain a different storage location with an alternate view into the data. For example you can gather all the current state for easy indexing and quick access. You can ignore a lot of the information, and focus on generating the data structure that makes your particular use case simple and performant.

Event Sourcing is a product of Domain-Driven Design (DDD). In DDD, we have two carriers of state: the value object and the entity.

## Value Objects

Value objects in general are not modeled here, but it is still important to understand them. A value object is (as the term implies) an object that represents a specific value. Values cannot be modified, only replaced. Value objects should therefore always be immutable.

In Swift, however, value objects can be defined through value-semantics (`struct`). Thanks to copy-on-write, Swift has much less need for enforced immutability. In rare cases, you might decide that it is okay to make value objects mutable. You should still be very restricted with *how* they may be changed, though.

Value objects are also encapsulated. They have an internal representation of data and an external interface. Users of the value object may only couple to the interface, not to the data representation.

## Entities

Not everything can be made immutable. If it were, we would have little (if any) use of software. We need to gather new data, and update existing data. We need to support business processes and user tasks, both of which heavily rely on *changing* the data stored in the system. Domain-driven design (DDD) was formulated in part to focus on these processes, rather than the data they manipulate.

In DDD we do not focus on the data as such, but on what the data *represents*. An *entity* is an object that has state. State is information (data) about the current reality of a particular thing. That “thing” is the entity. It might be a physical “thing” (eg. a person, a vehicle, a device, etc) or it might be non-physical (like a project, a document, a department of our company...).

## Events

By focusing on how the state *changes*, we can better understand how our domain works.

This library employs event sourcing, which means that we define the state of an entity by listing the changes that has happened to it since it was first added to the system/application. These changes are commonly referred to as *events*. The state of the entity hasn't officially changed until the events are published. When they have been published, they are forever a part of the entity's history. They are never changed or removed. The history up to that point will never change. Any new events will always be appended to the end of the history.

An action that changes the state of an entity (typically) needs to first reconstitute the entity from its already published events. This is done by repeatedly calling the `apply(:)` method with the events in the order they were added. When this method is called, your entity should remember the information it needs in order to determine how its current state affects the result of the action (and any other supported action).

When the action performs the actual change, the entity should add events to its `unpublishedEvents` property. These events (appended to the sequence of already published events) define its new state. This state is not official until the new events have been published.

# the Projection Target

The idea of the `Projection` target is to *project* the state onto a read model. It is possible to have multiple read models synchronised with the same `Source`. It is also possible to have any single read model projecting data from multiple sources. Or even (but perhaps not recommended) to project the data from one `Source` into another. If that is done, projections should never be performed in the reverse direction.

## Event

In a projection, the rules that give rise to state changes are unimportant. The only concern is that events have been logged. These events define the state of the `Entities` that collected together define the entire application state.

Events should be read from the source database at appropriate intervals. They could be read by polling or they could be read immediately as they are logged. It is not recommended to project events before they are written; writing events to disk can fail for multiple reasons.

An `Entity` on the projection side is essentially only an identifier with a type code. Apart from the entity, the `Event` contains information about the state change and the `position` in the stream that the change applies to.

The event `position` is a simple counter that is meant to aid the projection in remaining consistent and synchronised. If all events at `position` *n* have been processed when the projection machine is shut down, restarted or crashes, it can simply continue at the next `position` and the state will not be corrupted. Without the `position`, the projector would have to replay all events from the beginning of time and it might take minutes (or days depending on the size of the source data) to be in sync again.

## Why is `position` of type `Int64` and not `Int`?

There is theoretically possible to track up to 2^32 unique entity ids. Each `Entity` can theoretically log 2^32 events. Multiply those two numbers for a theoretical max of 2^64 events all in all. Even if no `Entity` ever logs the maximum number of events, and even if not every `Event` increments the `position` in the stream, there is a strong probability that the number 2^32 will be exceeded for at least some databases. Hence the need for a datatype that holds more than 32 bits.
