# distributed_media_converter

Free as in freedom, yet another distributed media converter

This is a simple system to queue in media conversion, e.g. video to mkv, in a network where neither server nor client are always online.
You just put in a task to convert and ask if the job is done.
At the beginning, we will juse php with the build in webserver and a basic framework.
We will put it to `/srv/webapps/net_bazzline/distributed_media_converter".

# Thoughts

## General

It looks like it is not possible to [resume](https://video.stackexchange.com/questions/32342/how-can-one-resume-an-interrupted-ffmpeg-job-or-pause-by-design-and-save-some-ki) an interrupted ffmpeg-job. We could run the stuff in a vm and pause the vm or [split](https://filme.imyfone.com/video-editing-tips/splitting-video-with-ffmpeg/#1.6) a video into segments and [glue](https://stackoverflow.com/questions/5651654/ffmpeg-how-to-split-video-efficiently) the converted segments together.
To get things moving, we won't use a database.
The broker just moves files into dedicated paths.
We also won't use a database, the broker is single threaded so it will use a basic json file to keep things up to date.
Server can also reject an item (disk full, not supported conversion)

### Database

#### items

| uuid | file_name | file_path | file_size_in_kb | sha512_checksum | created_at | updated_at |
| --- | --- | --- |-----------------|-----------------| --- | --- |
| aklsjdksad-asd223-... | my_movie.mkv | media/video | 229703750 | d6998200... | 1643645789 | 1643745789 |

#### to_do

| uuid | items_uudi | client_id | conversion_type | created_at | updated_at |
| --- | --- | --- | --- | --- | --- |
| 39aisd-... | aklsjdksad-... | 1 | x256 | 1643645989 | |

What about using [rqlite](https://www.phoronix.com/scan.php?page=news_item&px=Rqlite-7.0-Released) as database?

## Client item database

```json
{
  [
    <string: file_path: {
      "server_id": <string>,
      "item_id": <string>,
      "created_at": <date>,
      "status": <string>,
      "last_checked_at": <date>
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
  "status": <string>
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
      "file_size": <string>
  },
  "in_progress": [
    <uuid: item_id>: {
      "created_at": <date>,
      "client_id": <string>,
      "conversion_type": <string>,
      "original_file_name": <string>,
      "current_file_name": <string>,
      "sha512_checksum": <string>
      "file_size": <string>
  },
  "finished_successful": [
    <uuid: item_id>: {
      "created_at": <date>,
      "client_id": <string>,
      "original_file_name": <string>,
      "current_file_name": <string>,
      "sha512_checksum": <string>
      "file_size": <string>
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
      ]
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
    "item_id": <string>
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

## Server Endpoints

```
#return all existing entries per client id
GET /api/v1/item/{client_id}

#return existing entry status
GET /api/v1/item/{client_id}/{item_id}

#create new entry
POST /api/v1/item

#delete existing entry
DELETE /api/v1/item/{client_id}/{item_id}
```

# Milestones

## 0.0.0

* create some basic examples

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

# Deck

## Open

* Should we use [Symfony 5](https://symfony.com/5)?
    * [Rest API init](https://nafaa-azaiez.medium.com/symfony-5-rest-api-init-f2a24add17e1)?
    * [Documentation](https://symfony.com/doc/current/index.html)
# Can we use [stratigility](https://github.com/laminas/laminas-stratigility)?

## Closed

# link

* [Build a Simple REST API in PHP ](https://developer.okta.com/blog/2019/03/08/simple-rest-api-php) - 20190308
* [How To Create A Simple REST API in PHP? Step By Step Guide!](https://codeofaninja.com/2017/02/create-simple-rest-api-in-php.html) - 20200629
