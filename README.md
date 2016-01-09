# TCNetwork 2.0

## What

**TCNetwork 2.0** is a high level http request capsule based on [AFNetworking 3.0][AFNetworking]. 
Thanks to [YTKNetwork][YTKNetwork].

Still using AFNetworking 2.x ? see [TCNetwork 1.0](https://github.com/dake/TCNetwork/tree/v1.0)

## Features

- All requests are NSURLSession based
- Response can be cached offline by expiration time
- Persistent (optional) resuming download with [NSURLSession+TCResumeDownload](https://github.com/dake/NSURLSessionTask-TCResumeDownload)
- `block` and `delegate` callback
- Batch requests (see `TCHTTPBatchRequest`)
- URL filter, replace part of URL, or append common parameter 

## TODO

- NSURLRequest cachePolicy extension to implenment cache request.

- NSURLSession category extension without extra class, instead of TCNetwork classes.

- TCHTTPRequest as proxy only, cache logic extract to  NSURLRequestCachePolicy impl.

## Contributors

- [dake][dakeGithub]

## License

TCNetwork is available under the MIT license. See the LICENSE file for more info.

<!-- external links -->

[dakeGithub]:https://github.com/dake
[YTKNetwork]:https://github.com/yuantiku/YTKNetwork
[AFNetworking]:https://github.com/AFNetworking/AFNetworking
