# EventStore

A description of this package.

## Entities

The state of a domain-driven application is compartmentalised into small units called entities. An `Entity` is any thing that we want to track over time. That “thing” might be physical (eg a person, a vehicle, a device, etc) or it might be non-physical (like a project, a document, a game character...). Each entity should be the smallest unit possible without sacrificing its ability to be reasoned about as a standalone “thing.”

To track this “thing,” we need to be able to identify which one we are actually referring to. That's what the `id` property is for. The `id` should be globally unique (or at least unique in the current event store). No two entities can have the same `id` (even if they are of different types).

Next, we should ensure that the entity we have identified is of the expected type. We wouldn't want to load the state of a `Project` and then perform `Device`-related operations on it. The state of any entity is stored the same regardless of type, so there is no way to distinguish between a `Project` and a `Device` other than examining the actual content of the state information (which is complicated, cumbersome, and error prone). Instead we have added a `type` property that should be unique among the set of entity types in the application. When reconstituting an entity, we verify that the `type` of the stored entity matches the reconstituted type. If the types don't match, we throw an error.

## Events

This library employs event sourcing, which means that we define state of each entity by listing the changes that have happened to it since it was first added to the system/application. These changes are commonly referred to as `Events`. Events can be published or unpublished. `UnpublishedEvents` represent the changes caused by a user request that is still being processed. When/if that request is accepted, those changes are published, which makes them part of the official state.

`PublishedEvents` are forever part of the state (or rather: its history). They are never changed or removed. The history up to the point of any published event will never change. Any new events will always be appended to the end of the history. This is a tremendous power. This user made a bad change that could have serious consequences; how can we educate them so that they don't make that mistake again? (Or can we add a rule to our logic that makes that mistake impossible?) We know the exact state of the system when this other user attempted an operation that failed; we could restore that exact state to reproduce the error exactly, which might be helpful int finding and fixing the implementation of that operation!

An action that changes the state of the system (typically) needs to first reconstitute one or more entities from their already published events. This is done by repeatedly calling the `apply(:)` method, for each `PublishedEvent`, in the order they were added. When this method is called, your entity can choose to ignore it or use it to gather information about its current state. (It will only need to maintain enough state information to determine how to perform supported actions; any other state information can be ignored.)

When the action performs the actual change, the entity should add events to its `unpublishedEvents` property. These events (appended to the sequence of already published events) will define its new official state when they are published. If they are never successfully published, they will be discarded.

## Optimistic locking

Concurrent modification of shared state is a big problem when things can happen in parallel. If two users happen to change the same entity at the same time, luck may cause both to read the same initial state, and then make conflicting changes that cannot be reconciled. This library employs “optimistic locking” to avoid such a scenario. Every entity has a `version` that is read when it is reconstituted, and again before publishing changes. Only if the values are the same is publishing allowed.

If the stored state is the same, the published state of the entity is assumed to be unchanged between reconstituting and the attempt to publish the new events. If no one has yet published new changes, there is no conflict, and publishing the current changes will be allowed. At that time, the version is also incremented to indicate to any other active process that the state has now changed.

If the stored version number is different from what was read at reconstitution, the state has changed during the execution of this action. Since a different state can potentially affect the outcome of this action, all the current changes are to be considered invalid and publishing them is not allowed. Our only choices are to either abort the operation entirely or perform the action again. If we choose to repeat the action, we must discard the current, invalid state information and reconstitute the entity from its new state. Then we will have to perform the action on this state, and try to publish those changes.
