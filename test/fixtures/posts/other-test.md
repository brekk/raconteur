{{{
    "title":"Other Test 2",
    "subtitle":"Other test of some test",
    "slug":"test-othar",
    "tags": ["tag", "other"],
    "date":"04-11-2015",
    "preview":"Preview for other sheeview.",
    "image":""
}}}

Checks if predicate returns truthy for any element of collection. The function returns as soon as it finds a passing value and does not iterate over the entire collection. The predicate is bound to thisArg and invoked with three arguments: (value, index|key, collection). 

If a property name is provided for predicate the created _.property style callback returns the property value of the given element. 

If a value is also provided for thisArg the created _.matchesProperty style callback returns true for elements that have a matching property value, else false. 

If an object is provided for predicate the created _.matches style callback returns true for elements that have the properties of the given object, else false.