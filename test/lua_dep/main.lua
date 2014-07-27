for k, v in pairs(package.loaded) do print(k, v) end

foo = require "foo"

foo.foo()