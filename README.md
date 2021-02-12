# distributed_media_converter

Free as in freedom, yet another distributed media converter

This is a simple system to queue in media conversion, e.g. video to mkv, in a network where neither server nor client are always online.
You just put in a task to convert and ask if the job is done.
At the beginning, we will juse php with the build in webserver and a basic framework.
We will put it to `/srv/webapps/net_bazzline/distributed_media_converter".

# Thoughts

## General

To get things moving, we won't use a database.
The broker just moves files into dedicated paths.
We also won't use a database, the broker is single threaded so it will use a basic json file to keep things up to date.
Server can also reject an item (disk full, not supported conversion)

## Client item database

```json
{
  [
    <string: file_path: {
      "server_id": <string>,
      "item_id": <string>,
      "created_at": <date>,
      "status": <string>,
      "last_checked_at": <date>,
      "version": int
    }
  ]
}
```

## Server response for a new item

```json
{
  "item_id": <string: uuid>,
  "created_at": <date>,
  "client_id": <string>,
  "file_name": <string>,
  "sha512_checksum": <string>
  "file_size": <string>,
  "status": <string>,
  "version": int
}
```

## Server response of status from one or multiple items

```json
{
  [
    <uuid: item_id>: {
      "client_id": <string>,
      "status": <string>
    }
  ]
}
```

## Broker index database

```json
{
  "to_do": [
    <uuid: item_id>: {
      "created_at": <date>,
      "client_id": <string>,
      "conversion_type": <string>,
      "original_file_name": <string>,
      "current_file_name": <string>,
      "sha512_checksum": <string>
      "file_size": <string>,
      "version": int
  },
  "in_progress": [
    <uuid: item_id>: {
      "created_at": <date>,
      "client_id": <string>,
      "conversion_type": <string>,
      "original_file_name": <string>,
      "current_file_name": <string>,
      "sha512_checksum": <string>
      "file_size": <string>,
      "version": int
  },
  "finished_successful": [
    <uuid: item_id>: {
      "created_at": <date>,
      "client_id": <string>,
      "original_file_name": <string>,
      "current_file_name": <string>,
      "sha512_checksum": <string>
      "file_size": <string>,
      "version": int
  },
  "finished_with_errors": [
    <uuid: item_id>: {
      "created_at": <date>,
      "client_id": <string>,
      "original_file_name": <string>,
      "sha512_checksum": <string>
      "file_size": <string>,
      "errors": [
        <string>
      ],
      "version": int
    },
  ]
}
```

## Broker thread index

```json
{
  <int: process_id>: {
    "pid": <int>,
    "started_at": <date>,
    "item_id": <string>,
    "version": int
  }
}
```

## Client Configuration File

```json
  "list_of_paths_to_observer": [
    "path_one": {
      "observed_media_types": [
        "audio",
        "image",
        "video"
      ]
    },
    "path_two": {
      "observed_file_types": [
        "audio",
        "image",
        "video"
      ]
    }
  ],
  "list_of_servers": [
    "hostname_or_ip_address": {
      "port": <int>,
      "list_of_supported_media_types": [
        "audio",
        "image",
        "video"
      ]
    }
  ]
```

## Server Configuration File

```json
"list_of_supported_media_types": [
  "audio",
  "image",
  "video"
],
"listen_on_port": <int>,
"number_of_conversion_threads": <int>
```

# Milestones

## 0.0.1

* basic server api with endpoints to
  * put a new item to the processing queue
  * get status of one item
  * get status of all items per client
  * fetch converted item
* basic cli client to interact with the api
  * upload new item
  * download converted item
  * fetch status of item

## 0.0.2

* implement server cli broker
  * handles status of each item
    * to do
    * in progress
    * finished successful
    * finished with error
  * commands
    * add to queue
    * list queue

## 0.0.3

* implement conversion thred observer
* implement one conversion thread

## 0.0.4

* implement real conversion logic with support for libx265 and libx264 videos

## 0.0.5

* implement gracefull shutdown of conversion threads
  * will stop at current position
  * will remove in progress file
* implement start up
  * check if there is stuff to clean up
  
## 0.0.6

* create systemd service
* create install and uninstall scripts for server and client side

## 0.0.7

* implement client to automatically check if server is available

## further

* add support for images [png|jpg] to webp
* implement multi threaded
* create interfaces to ease up change of broker or broker database
* add option to deal with multiple servers
* add option to organize server per task
* replace json "databases" with sqlite or more
* extend client code to observe file paths to automate requesting conversion
* add support for apache webserver instead of interla php server
* add authentication for client and server
* think about rewriting it in RUST
