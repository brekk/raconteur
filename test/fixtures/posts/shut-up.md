{{{
    "title":"SHUT UP",
    "subtitle":"Man, shut the hell up",
    "slug":"test-silence",
    "tags": ["shut", "up"],
    "date":"04-11-2015",
    "preview":"Preview for other sheeview, shut up.",
    "image":""
}}}

Promised-IO is a cross-platform package for asynchronous promise-based IO. Promises provide a simple robust mechanism for asynchronicity with separation of concerns by encapsulating eventual completion of an operation with side effect free callback registration separate from call invocation. Promised-IO provides cross-platform file, HTTP, and system interaction with promises for asynchronous operations.

Promised-IO also utilizes "lazy arrays" for progressively completed actions or for streaming of data. Lazy arrays provide all the standard iterative Array methods for receiving callbacks as actions are completed. Lazy arrays are utilized for progressive loading of files and HTTP responses.

# Installation

Promised-IO can be installed via npm:

    npm install promised-io

## promise

The promise module provides the primary tools for creating new promises and interacting with promises. The promise API used by promised-io is the Promises/A proposal used by Dojo, jQuery, and other toolkits. Within promised-io, a promise is defined as any object that implements the Promises/A API, that is they provide a then() method that can take a callback. The then() methods definition is:

    promise.then(fulfilledHandler, errorHandler);

Promises can originate from a variety of sources, and promised-io provides a constructor, Deferred, to create promises.

## when

    when = require("promised-io/promise").when;
    when(promiseOrValue, fulfilledHandler, errorHandler);

You can pass a promise to the when() function and the fulfillment and error handlers will be registered for it's completion or you can pass a regular value, and the fulfillment handler will be immediately be called. The when function is a staple of working with promises because it allows you to write code that normalizes interaction with synchronous values and asynchronous promises. If you pass in a promise, a new promise for the result of execution of the callback handler will be returned. If you pass a normal value, the return value will be the value returned from the fulfilledHandler.