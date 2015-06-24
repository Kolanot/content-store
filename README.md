# The content store

The central storage of *published* content on GOV.UK.

The content store maps public-facing URLs to published items of content, represented
as JSON data. It will replace [content API](https://github.com/alphagov/govuk_content_api)
in time.

Publishing applications add content to the content store; public-facing
applications read content from the content store and render them on GOV.UK.

## Content items

`ContentItem` is the base unit of content in the content store. They have both a
private and public-facing JSON representation. More details on these
representations and the meanings of the individual fields can be found in
[doc/content_item_fields.md](doc/content_item_fields.md).

## Writing content items to the content store

Publishing applications will "publish" content on GOV.UK by sending them to
the content store. To add or update a piece of content in the content store, make a PUT
request:

``` sh
curl https://content-store.production.alphagov.co.uk/content<base_path> -X PUT \
    -H 'Content-type: application/json' \
    -d '<content_item_json>'
```

where `<base_path>` is the path on GOV.UK where the content lives (for example
`/vat-rates`) and `<content_item_json>` is the JSON for the content item as
outlined in [doc/input_examples](doc/input_examples).

There is currently an [API adapter](https://github.com/alphagov/gds-api-adapters/blob/master/lib/gds_api/publishing_api.rb)
in [gds-api-adapters](https://github.com/alphagov/gds-api-adapters) for writing
content to content-store, although it is likely that this will soon be extracted
to a separate gem.

## Reading content from the content store

To retrieve content from the content store, make a GET request:

``` sh
  curl https://content-store.production.alphagov.co.uk/content<base_path>
```

Examples of the JSON representation of content items can be found in [doc/output_examples](doc/output_examples).

## Access-limited content items

Retrieving an access-limited content item from the content store requires that
an additional authentication header be provided:

``` sh
  curl -header "X-Govuk-Authenticated-User: f17150b0-7540-0131-f036-0050560123202" \
    https://content-store.production.alphagov.co.uk/content<base_path>

```

If the supplied identifier is in the list of authorised users, the content item
will be returned. If not, a 403 (Forbidden) response will be returned. For more
details on how to create an access-limited content item, see
[doc/content_item_fields.md#access_limited](doc/content_item_fields.md#access_limited)

Note: the access-limiting behaviour should only be active on the draft stack.

## Post publishing/update notifications

After a content item is added or updated, a message is published to RabbitMQ.
It will be published to the `published_documents` topic exchange with the
routing_key `"#{item.format}.#{item.update_type}"`. Interested parties can
subscribe to this exchange to perform post-publishing actions. For example, a
search indexing service would be able to add/update the search index based on
these messages. Or an email notification service would be able to send email
updates.

The message body will be the private-facing JSON representation of the content,
generated by `PrivateContentItemPresenter`, including the `update_type` field
(NOTE: subject to change).

## Publish intents

In order to support the timely publishing of items scheduled for publication,
content-store allows publishing tools to register their intent to publish
something at a given time.  If a publish intent is present for a content item,
content-store will reduce the TTL in its cache headers as the publish time
approaches, allowing the new item to be fetched as soon as it's published.

See [doc/publish_intents.md](doc/publish_intents.md) for more details.

## Dependencies

Content store relies on RabbitMQ as its messaging bus. If you are using the
development VM, it will be installed for you and the required users and topic
exchanges will be set up. If not, you need to install RabbitMQ and add them
yourself. Once RabbitMQ is installed, visit http://localhost:15672 and:

1. add a `content_store` user (under "Admin") with the password `content_store`
2. add a `published_documents` and a `published_documents_test` topic exchange
   (under "Exchanges")
3. give the `content_store` user permissions for the new exchanges.

A more detailed specification of how to configure RabbitMQ can be found in the
[puppet manifest](https://github.gds/gds/puppet/blob/master/modules/govuk/manifests/apps/content_store/rabbitmq.pp)
for content store.

Publishing to the message queue can be disabled by setting the
`DISABLE_QUEUE_PUBLISHER` environment variable.

## Running draft-content-store in development

On a development VM you may want to run an instance of content-store
to accept draft content sent to publishing-api. You can:

```
  bowl draft-content-store
```

from the development directory to run the content-store application
at `draft-content-store.dev.gov.uk`. This instance stores data in a
separate database: 'draft_content_store_development', and logs to
the same rails log file as content-store, with a tag [DRAFT].
