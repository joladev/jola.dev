%{
  title: "Proposal for Tranquil PDS: Type-safe scopes",
  author: "Johanna Larsson",
  tags: ~w(atproto tranquil types oauth scope),
  description: "Tranquil is a popular AT protocol PDS implementation. This is a proposal to introduce a type-safe building block for representing scopes."
}
---

Note: this is a proposal I've written for Tranquil PDS, you can also read it in the issue I posted on the repo [here](https://tangled.org/tranquil.farm/tranquil-pds/issues/690). I thought it was an interesting deep dive into code design, so I'm publishing it here too for a wider audience.

_tl;dr let's replace the scope parsing logic, which lives across several files and different paths, with a type `Scope` that by construction can only be valid_

Atproto OAuth comes with a specification for scopes, and strict rules on what is valid and not, documented [here](https://atproto.com/specs/permission). Tranquil acts both as an OAuth client and as an authorization server. As an OAuth client Tranquil requests a set of scopes for the user's session when they log into the dashboard. As an authorization server, it validates the requested scopes and creates the OAuth session, handing over access token and refresh token.

Tranquil has a full implementation of both of these roles, but each one sprawls over multiple files, and the logic for validating and granting a set of scopes to a session follows many different paths and special cases. Currently there are no guarantees that a scope is valid at any point, and in some places we rely on that behavior.

The cost of the current implementation is a long series of scope related bugs, like [#677](https://tangled.org/tranquil.farm/tranquil-pds/pulls/677) and [#611](https://tangled.org/tranquil.farm/tranquil-pds/pulls/611) . Each fix adds more special cases and frequently results in secondary bugs (like 611).

## The current state

This section goes through what the code looks like today and gives practical examples of the problems of the current design, with the goal of setting the stage for why this change is important. If you already know how scope parsing has been implemented in Tranquil, feel free to jump ahead.

Today a scope is represented in the type system by the `ParsedScope` union which looks like this:

```rust
  pub enum ParsedScope {
      Atproto,
      TransitionGeneric,
      TransitionChat,
      TransitionEmail,
      Repo(RepoScope),
      Blob(BlobScope),
      Rpc(RpcScope),
      Account(AccountScope),
      Identity(IdentityScope),
      Include(IncludeScope),
      Unknown(String),
  }
```

A scope string like `atproto repo:*?action=create blob:*/*` is converted into a `Vec<ParsedScope>` by `parse_scope_string`, which splits the scope string and calls `parse_scope` on each component. `parse_scope` returns `ParsedScope`, not `Result<ParsedScope, _>`, and uses the `Unknown` type to represent invalid scopes.

Some scopes have special handling, like `include:`. It is parsed into `Include(IncludeScope)`, which is never used to do any checks. Instead `include:` scopes are separately handled by `expand_scopes`, which fetches the scope bundles (permission sets). Each scope bundle, which is returned as a list of JSON objects corresponding to scopes, is tested against a separate implementation of validation logic that is only used for this case. A subset of invalid scopes are dropped, but the rest are then converted to a string and returned together with the list of `ParsedScope`.

Once login is done, the `ParsedScope`s are converted back into strings, combined with the bundle scope strings, and stored in the access token created for the session. A slightly different set of scopes is also stored in the database. There are also some differences in behavior for how invalid permissions are displayed on the OAuth consent screen. Invalid `ParsedScope`s are not displayed on the screen, but scopes that were part of a bundle are always shown, even if they are invalid.

One thing to note here is the `Unknown` scope, which is there to handle the fact that parsing a scope string always results in a list of `ParsedScope`, parsing never returns an error. Another relevant input for a redesign is that although generally a set of scopes on a session is fixed, and will not change when refreshing, bundled scopes are allowed to change on session refreshes. The full set of scopes _may_ change on refresh according to the spec.

All `ParsedScope` type fields are public and can be constructed ad-hoc. An example of us creating a `RepoScope` outside of the main parse path can be found [here](https://tangled.org/tranquil.farm/tranquil-pds/blob/ff92d56e3e2d181370980e2f84428678b2f9f13e/crates/tranquil-oauth-server/src/endpoints/authorize/scope_resolution.rs#L85-88). Allowing access to the fields of the `ParsedScope` makes it trivial to accidentally introduce invalid data. This is exacerbated by the implicit behaviors that some values have. Taking `BlobScope` as an example, and its corresponding string representation. `blob:image/png` says permission to upload blobs of the mimetype `image/png`. The spec allows wildcards, so you can also express `blob:*/*`, but a bare `blob` is not a valid scope. The tranquil `BlobScope` is implemented as:

```rust
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct BlobScope {
    pub accept: HashSet<String>,
}
```

This means the hash set can contain a string like `image/png`, but it could also contain an invalid string like `potato`. The `*/*` wildcard is stored as a string, and respected as a wildcard, but an empty hash set is _also_ treated as a wildcard. It’s not that hard to see how the code ended up doing that, the empty set could be read as the _lack_ of stricter rules. Except, this makes it easy to accidentally turn an invalid scope into a wildcard scope, which happens today if you pass a scope like `blob`. The lack of an accept is represented as an empty hash set, same as the wildcard.

Finally, we have no consistent way of converting `ParsedScope` back to a scope string, and we instead use a mix of different string formatting approaches, which also means a scope can be formatted differently depending on whether it came from a scope bundle or the base scope string. [This issue has been reported in the past](https://tangled.org/tranquil.farm/tranquil-pds/issues/113). Considering that the string we construct and write into the access token is the source of truth for all permissions checks, it’s important that this is accurate.

The goal of this section was to give examples of how the current state makes it easy to have bugs, and to motivate a targeted rewrite. Hopefully it’s given some insight into the specifics of the issues we have today, to help contrast that against the proposal.

## Problem statement

To summarize the main issues with the current design:

* Parsing logic is spread across many different locations, and scopes moving through different paths are validated differently.
* A `ParsedScope` does not represent a valid scope, can be `Unknown`, and does not prevent you from introducing bad data.
* Scopes are represented inconsistently in the codebase, sometimes as strings, sometimes `ParsedScope`.
* We have no consistent serialization path for scopes, and scopes can be represented in different ways depending on what part of the code they come from.

And to summarize the proposal I’m making:

* Parsing logic should have a single entry point and live in one place.
* A scope should be valid by construction, it should not be possible to create an invalid scope.
* Scopes should always be represented by a proper type, outside of serialization.
* When serializing scopes, they must always be consistently written.

So let’s jump into what that looks like.

## Correct by construction

The first part of the proposal is to introduce a new type to represent scopes, called `Scope`. The name change is motivated by the change in relationship, from “a scope is a string that can be parsed” to “a scope is a type that can be represented as a string”. `Scope` will look very much like `ParsedScope`, except that it will not contain the `Unknown` type.

```rust
#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord, Hash)]
pub enum Scope {
    Atproto,
    Transition(Transition),
    Repo(RepoScope),
    Blob(BlobScope),
    Rpc(RpcScope),
    Account(AccountScope),
    Identity(IdentityScope),
    Include(IncludeScope),
}

```

Things change a bit more as we go a level deeper. The fields of each type are now private, and each one is intended to express valid states only. The previously mentioned `BlobScope` field for accepted mimetypes, `HashSet<String>`, becomes `NonEmptySet<Accept>` instead, where `Accept` is a newtype of `String`.

```rust
pub enum Transition { Generic, ChatBsky, Email }

pub struct RepoScope     { collections: NonEmptySet<Collection>, actions: NonEmptySet<RepoAction> }
pub struct BlobScope     { accept: NonEmptySet<Accept> }
pub struct RpcScope      { lxm: NonEmptySet<Lxm>, aud: Audience }
pub struct AccountScope  { attr: AccountAttr, actions: NonEmptySet<AccountAction> }
pub struct IdentityScope { attr: IdentityAttr }
pub struct IncludeScope  { nsid: Nsid, aud: Option<DidRef> }

pub enum Collection { Any, Nsid(Nsid) }
pub enum Lxm        { Any, Nsid(Nsid) }
pub enum Audience   { Any, Did(DidRef) }
pub struct Accept(String);
pub struct NonEmptySet<T>(BTreeSet<T>);
```

And the types that already exist that we can use as they are.

```rust
pub enum RepoAction {
    Create,
    Update,
    Delete,
}

pub enum AccountAttr {
    Email,
    Handle,
    Repo,
    Status,
    Wildcard,
}

pub enum IdentityAttr {
    Handle,
    Wildcard,
}

pub enum AccountAction {
    Read,
    Manage,
}
```

In practice we rarely work with individual scopes, and a scope string represents a list of scopes, rather than a single scope, so I’m introducing the corresponding `ScopeSet`:

```rust
pub struct ScopeSet(BTreeSet<Scope>);
```

## Entry point

The second part of the proposal is to introduce flexible and useful functions for creating scopes and scope sets. This means we get an authoritative implementation for parsing a scope, in a single place. Additionally, since we can no longer represent an invalid scope, parsing a scope string will now return the scopes and a list of errors.

```rust
impl ScopeSet {
    pub fn parse(s: &str) -> (ScopeSet, Vec<ScopeParseError>);
}

impl FromStr for Scope {
    type Err = ScopeParseError;
    fn from_str(s: &str) -> Result<Scope, ScopeParseError>;
}
```

Although you could theoretically treat a scope string that contains invalid scopes as wholly invalid, and reject the whole thing, the spec doesn’t disallow that. But the user experience would not be great if they can’t log into a client app because the scope string has a single invalid component. The current Tranquil behavior is a mix of behaviors, some scopes are dropped, some are displayed to the user as valid, but never actually apply. The goal behavior is to only display valid scopes and to consistently drop all invalid scopes. This is compliant with the spec, it explicitly calls out that a [client must be able to handle receiving fewer scopes than it requested](https://atproto.com/specs/oauth#summary-of-authorization-flow). By maintaining the list of scopes that failed to parse, Tranquil can also display the errors on the OAuth screen, to make it understandable and intuitive.

Bundled scopes, that are fetched separately, will be parsed using the same logic and added to the scope set, so we get a single consistent behavior.

## Serialization

Once we have proper types that we can trust to represent valid scopes, the next part is specifying how to serialize them for storage in the access token and database session. As mentioned earlier, Tranquil currently does not have a consistent way of serializing scopes to a scope string.

As with parsing, we implement serialization by implementing `Display` on `Scope` and `ScopeSet`. The order of items is consistent, relying on `BTreeSet` to provide ordering, and a scope is always serialized the same way. We will also be able have stable round-tripping, although only from `ScopeSet` -> `String` -> `ScopeSet`, since a third party could follow different encoding rules for a scope string.

Roughly encoding the formatting rules from the Bluesky reference PDS implementation:

* Defaults are left out, repo with all actions is `repo:x`, not `repo:x?action=create&action=update&action=delete`.
* Single value uses the positional slot (`repo:app.bsky.feed.post`), multiple go as named settings (`repo?collection=a.b.c&collection=d.e.f`).
* Repeated values are deduplicated and have a fixed order, sorting lexicographically by default, while repo actions are in the order of `create, update, delete`.
* Wildcards override redundant scopes, eg `image/png` is dropped if `image/*` is also included.
* Percent-encode only when required. `#` is written as `%23`, but `:` is not rewritten.
* Blob mime types are lower cased.

## Bundle resolution

The atproto OAuth spec also includes the concept of scope bundles, or permission sets, represented by `include:` in the scope string. These are references to bundles of scopes that should be resolved at the time of session creation, and make it easier for a service to present a group of related permisions. They are also more flexible, because a bundle can change over time, even over the lifetime of a session, since the spec allows re-resolving the bundle during session refresh.

This means that as is, the `ScopeSet` does not represent the final set of scopes. At the same time we can’t treat `ScopeSet` as just a transitionary state, the `include:` scopes must be maintained over the lifetime of a session to enable resolving them again on refresh. In other words, in some places we want a `ScopeSet` and in some places we want a _resolved_ `ScopeSet`. To tackle that, this proposal also introduces a newtype `ResolvedScopeSet`.

```rust
pub struct ResolvedScopeSet(ScopeSet);
```

There are currently three places where we have to ensure that the `ScopeSet` is resolved: creating access token during login, displaying the consent screen, and creating access token at refresh time. All of these locations will require `ResolvedScopeSet`.

The implementation of bundle resolution will continue to work the way it does today, although there’s work we can do there too to improve it. A bundle fetch may require a network request, and can fail, but is in most cases served from cache. Changes in bundles are discovered within 24 hours.

Next up, we’ll talk about the places where the proposal has to be pragmatic.

## The delegation special case

[@nel.pet](https://bsky.app/profile/nel.pet) introduced the [concept of delegated accounts](https://nelind.leaflet.pub/3mljaycxcqc2h) to Tranquil and the atproto community, and although it has not been written down in a specification, it is a fairly well-known concept in the atproto world and has been re-implemented in [other places](https://tangled.org/ngerakines.me/atproto-crates). A delegated account can’t be logged into directly, instead a controlling account can get a delegated OAuth session for it, which in turn allows it to auth against client apps as the delegated account.

Delegated accounts have two different sets of permissions that apply to them: the scopes that control what the controller is allowed to do with the delegated account, represented as roles in the dashboard from Viewer to Owner, and the scopes that a third party client requests of the delegated account. A controller can not accept scopes from a client app that are beyond the “ceiling” of permissions they are given on the delegated account. For example, if the controller role allows reading Bluesky DMs on the delegated account, the controller can create a delegated session with Bluesky and read the DMs for the delegated account. Under the hood, the ceiling of permissions granted to the controller are represented as atproto scopes.

It relates to this proposal in that the scopes required for delegation are not compatible with the atproto OAuth specification. The clearest example of this is `rpc:*`, or a wild-card permission to execute any method. Because a method is a loosely defined concept, and can cover anything from reading data to deleting it, the spec requires that it is always scoped either to audience (`aud`) or lexicon method (`lxm`). An example of an audience is `did:web:api.bsky.app%23bsky_appview` and a method `app.bsky.feed.getTimeline`. So for example, `rpc:app.bsky.feed.getTimeline?aud=did:web:api.bsky.app%23bsky_appview` is a valid scope because it contains the `lxm` (after `rpc:`) and the `aud` points at the Bluesky AppView.

But for delegation it would be infeasible to in advance grant every single possible variant of `rpc` scope, with every possible `aud` and `lxm`, anyone can add new ones and they constantly change. And so the delegated role instead specifies `rpc:*`, or _any_ method on _any_ service. This works well as a ceiling, and covers every future method and service, but as mentioned is not a valid scope.

To handle delegation specific exceptions, without compromising on the correctness of `Scope`, I propose we introduce `DelegationScope`, with a carve out for exceptions.

```rust
pub enum DelegationScope {
    Spec(Scope),
    RpcAnyAudience { lxm: NonEmptySet<Lxm> },
}
```

The exact list may change over time, but the mechanism can be re-used for additional exceptions to scopes. Because delegation scopes are only used when checking if a requested scope fits within the ceiling of the delegation scope, this can be kept clearly separate from the parsing of regular scopes. The delegation ceiling check will be applied at `ScopeSet` resolution, ensuring that all expanded scopes are checked against the ceiling, and that the final `ResolvedScopeSet` matches the actual scopes granted to the session.

## Tranquil dashboard

As mentioned Tranquil comes with its own public OAuth client, the account dashboard. This has a lot of neat properties, including giving users a clear opening to build their own dashboard, but it also brings less intuitive things with it, namely that any third party can also make a dashboard for _your_ Tranquil instance. Building a third party Tranquil dashboard management service is fully possible, where anyone can log in and manage their account. I can host a fully frontend browser side application that lets you log into your account and edit it, without a backend component.

That brings us to the awkward part: atproto OAuth scopes don’t have any concept of the kinds of permissions you’d expect from a dashboard, like updating your password, setting a passkey, removing a passkey, or enabling 2FA. The Bluesky reference PDS does not use OAuth for its dashboard, users log in using traditional session cookies.

Unfortunately this means we need to give up the notion of a completely pure and correct scope parser, to enable scopes for managing accounts. Currently, Tranquil uses the scope `account:*?action=manage`, which is not in the specification, to represent actions that you would traditionally associate with an account dashboard, such as setting passkeys or updating passwords.

Because the Tranquil client is just a regular client, with no special behaviors, we can’t use special case parsing like proposed for delegation scopes. Instead, `Scope` has to include the new account scopes. Rather than just keeping `*` as a special case, we can split it out into specific attributes, like `passkey`, `totp`, and `password`, and check each one on the appropriate endpoint. The session can continue requesting the wildcard. Here’s a draft list of attribute extensions.

```rust
pub enum AccountAttr {
    ...
    // Tranquil extensions
    Password,
    Passkey,
    Totp,
    AppPassword,
    Session,
    Delegation,
    Sso,
    NotificationPrefs,
    Deletion,
    Any,
}
```

This means we’ll enshrine this extension of the spec in Tranquil. We should also write about this more widely, and try to make the case that this should become a part of the official specification, so that other PDSs can also benefit from building on top of OAuth and the established patterns of atproto scopes, rather than having to build bespoke dashboard auth sessions.

## Moving into the new world

When the changes are rolled out it will affect two different sets of data that may contain scopes that were previously accepted and no longer are: the scope string in the access token, held by the client app, and the corresponding string in the Tranquil-side persisted session.

Because parsing drops invalid scopes and maintains all others, existing access tokens will continue to work. For the invalid scopes, the ones that were “inert” and ignored by Tranquil previously there will be no change, but for ones that were previously misinterpreted like the bare `blob`, those scopes will start being dropped rather than converted to `blob:*/*`. For those access tokens, it will be as if the permission was revoked. In practice this is unlikely, the Bluesky reference PDS implementation does not accept `blob`, apps would already have run into this.

The data will naturally self-repair. On refresh, Tranquil takes the stored scope string, parses it, and writes it back into the new access token. This means that after a refresh the string will be correct. The scope string stored in the database will unfortunately stay the way it is, but on each parse the invalid scopes will be dropped, so it will not do any harm, and eventually all sessions will age out.

## Next steps

Please let me know what you think! I don’t believe implementation will take much time, the hard part here is just clearly defining the path forward with an approach that we can build on, that lets us lean on the type system for correctness, and where our abstractions help us naturally do the right thing.

The current implementation of scopes in Tranquil has grown organically. The code is stable enough now, and we’ve seen enough of the different use cases that we want to support, that we’re in a good place to make these changes.
