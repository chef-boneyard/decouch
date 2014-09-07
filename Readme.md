
A tool to extract key/value pairs from couchdb. This code is directly
derived from couchdb's file reading code, simplified and pruned down a
bit to remove things I'm not using. I've removed gen_servers and
tweaked the code to speed things up a bit.

## License

All files in the repository are licensed under the Apache 2.0 license. If any
file is missing the License header it should assume the following is attached;

```
Copyright 2014 Chef Software Inc

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
```

# Notes on optimization:

Couchdb reads the last 4k of the file first, and generally tends to
move from the back to the front of the file. This can subvert the
readahead optimizations in the os; especially when you know you are
going to read the whole file. Prereading the file in advance can shave
a lot off of the walk of the btree, and the open code has been altered
to read the whole file in 1MB chunks before walking the btree.


