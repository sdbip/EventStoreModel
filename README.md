# EventStore

A description of this package.

## Entities

An entity is a thing that we want to track over time. That “thing” might be physical (eg a person, a vehicle, a device, etc) or it might be non-physical (like a project, a document, a business...). To track this thing, first of all we need to be able to identify which one we are referring to. That's what the id property is for. The id should be globally unique (or at least unique in the current event store).

Next, we should ensure that we are reconstituting an entity of the correct type. We wouldn't want to save the state of a project and then accidentally use that as the state of a device. When reconstituting an entity, we verify that the type of the stored entity matches the expectation. If the types don't match, we throw an error.

## Events

This library employs event sourcing, which means that we define the state of an entity by listing the changes that has happened to it since it was first added to the system/application. These changes are commonly referred to as “events.” The state of the entity hasn't officially changed until the events are published. When they have been published, they are forever a part of the entity's history. They are never changed or removed. The history up to that point will never change. Any new events will always be appended to the end of the history.

An action that changes the state of an entity (typically) needs to first reconstitute the entity from its already published events. This is done by repeatedly calling the `apply(:)` method with the events in the order they were added. When this method is called, your entity should remember the information it needs in order to determine how its current state affects the result of the action (and any other supported action).

When the action performs the actual change, the entity should add events to its `unpublishedEvents` property. These events (appended to the sequence of already published events) define its new state. This state is not official until the new events have been published.

## Optimistic locking

Concurrent modification of shared state can be a big problem. If two users happen to change the same entity at the same time, there's a risk that they both read the same initial state, and then make conflicting changes that cannot be reconciled. This library employs “optimistic locking” to avoid such a scenario. Every entity has a `version` that is read when it is reconstituted, and again before publishing changes. Only if the version is the same at both instants is publishing allowed.

If the stored state is the same, it is assumed that no other process has changed the staete in the intervening time. If no one has yet published new changes, there is no possibility of a conflict, and publishing the current changes will be allowed. At that time, the version is also incremented to indicate to any other active process that the state has now changed.

If the stored version number is different from what was read at reconstitution, the state has changed during the execution of this action. Since a different state can potentially affect the outcome of this action, all the current changes are to be considered invalid and publishing them is not allowed. Our only choices are to either abort the operation entirely or perform the action again. If we choose to repeat the action, we must discard the current, invalid state information, and reconstitute the entity from its new state. Then we can perform the action on this state, and try to publish those changes.
